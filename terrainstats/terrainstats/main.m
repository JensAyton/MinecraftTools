#import <Foundation/Foundation.h>
#import "JAPrintf.h"
#import <JAMinecraftKit/JAMinecraftRegionReader.h>
#import <JAMinecraftKit/JAMinecraftSchematic+ChunkIO.h>
#import <JAMinecraftKit/JAMinecraftChunkBlockStore.h>
#import <JAMinecraftKit/JAPropertyListAccessors.h>
#import <JAMinecraftKit/MYCollectionUtilities.h>
#import <JAMinecraftKit/JANBTSerialization.h>
#import "JATerrainStatistics.h"


#define ONE_REGION_ONLY		0	// For quick tests, only analyze the first region encountered.


static void PrintHelpAndExit(void) __attribute__((noreturn));

static void AnalyzeRegionsInDirectory(NSString *directory);
static JATerrainStatistics *AnalyzeRegion(NSURL *path);
static void AnalyzeChunk(JAMinecraftBlockStore *schematic, NSDictionary *metaData, JATerrainStatistics *regionStatistics);

static void Finish(JATerrainStatistics *statistics);

static NSString *BlockName(uint8_t blockType);
static bool HasAdjacentBlock(JAMinecraftBlockStore *schematic, MCGridCoordinates coords, uint8_t targetType);


static dispatch_queue_t sReduceQueue;
static dispatch_group_t sCompletionGroup;
static JATerrainStatistics *sTotalStatistics;

static NSUInteger sTotalRegions, sCompletedRegions;
static bool sAllQueued;


int main (int argc, const char * argv[])
{
	@autoreleasepool
	{
		if (argc < 2 || strcasecmp(argv[1], "--help") == 0 || strcmp(argv[1], "-?") == 0)
		{
			PrintHelpAndExit();
		}
		
		
		sReduceQueue = dispatch_queue_create("se.ayton.jens.statistics-reduce", DISPATCH_QUEUE_SERIAL);
		sCompletionGroup = dispatch_group_create();
		sTotalStatistics = [JATerrainStatistics new];
		
		for (int i = 1; i < argc; i++)
		{
			NSString *inputPath = RealPathFromCString(argv[i]);
			if (inputPath == nil)
			{
				EPrint(@"Failed to resolve input path \"%s\".\n", argv[i]);
				return EXIT_FAILURE;
			}
			
			AnalyzeRegionsInDirectory(inputPath);
		}
		
		Print(@"%lu regions queued.\n", sTotalRegions);
		sAllQueued = true;
		
		dispatch_group_wait(sCompletionGroup, DISPATCH_TIME_FOREVER);
		Finish(sTotalStatistics);
	}
	return EXIT_SUCCESS;
}


static void AnalyzeRegionsInDirectory(NSString *directory)
{
	dispatch_queue_t workQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtURL:[NSURL fileURLWithPath:directory]
														  includingPropertiesForKeys:[NSArray array]
																			 options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
																		errorHandler:^BOOL(NSURL *url, NSError *error)
																					 {
																						 Fatal(@"%@\n", error);
																					 }];
	
	if (dirEnum == nil)  Fatal(@"%@ is not a directory.", directory);
	
	
	NSString *name = directory.lastPathComponent;
	if ([name isEqualToString:@"region"])  name = directory.stringByDeletingLastPathComponent.lastPathComponent;
	Print(@"Queueing regions in %@.\n", name);
	
	for (NSURL *url in dirEnum)
	{
		if ([url.pathExtension caseInsensitiveCompare:@"mcr"] != NSOrderedSame)
		{
			continue;
		}
		
		sTotalRegions++;
		
		dispatch_group_async(sCompletionGroup, workQueue, ^
		{
			JATerrainStatistics *regionStatistics = AnalyzeRegion(url);
			
			dispatch_group_async(sCompletionGroup, sReduceQueue, ^
			{
				[sTotalStatistics addValuesFromStatistics:regionStatistics];
				
				sCompletedRegions++;
				if (sAllQueued)
				{
					Print(@"%u regions remaining.\n", sTotalRegions - sCompletedRegions);
				}
			});
		});
		
#if ONE_REGION_ONLY
		break;
#endif
	}
}


static JATerrainStatistics *AnalyzeRegion(NSURL *regionURL)
{
	JAMinecraftRegionReader *region = [JAMinecraftRegionReader regionReaderWithURL:regionURL];
	if (region == nil)
	{
		Fatal(@"Could not read region file %@.", regionURL.lastPathComponent);
	}
	
	JATerrainStatistics *regionStatistics = [JATerrainStatistics new];
	[regionStatistics incrementRegionCount];
	
	for (uint8_t x = 0; x < 32; x++)
	{
		for (uint8_t z = 0; z < 32; z++)
		{
			@autoreleasepool
			{
				NSData *data = [region chunkDataAtLocalX:x localZ:z];
				if (data != NULL)
				{
					NSError *error;
					JAMinecraftChunkBlockStore *chunk = [[JAMinecraftChunkBlockStore alloc] initWithData:data error:&error];
					
					if (chunk == nil)
					{
						Fatal(@"Failed to read a chunk. %@\n", error);
					}
					
					if ([chunk.metadata ja_boolForKey:@"TerrainPopulated"])
					{
						[regionStatistics incrementChunkCount];
						AnalyzeChunk(chunk, chunk.metadata, regionStatistics);
					}
					else
					{
						[regionStatistics incrementRejectedChunkCount];
					}
				}
			}
		}
	}
	
	return regionStatistics;
}


static void AnalyzeChunk(JAMinecraftBlockStore *chunk, NSDictionary *metaData, JATerrainStatistics *regionStatistics)
{
	JATerrainTypeByLayerHistorgram *countsByLayer = regionStatistics.countsByLayer;
	JATerrainTypeHistorgram *totalCounts = regionStatistics.totalCounts;
	JATerrainTypeHistorgram *adjacentToAirBelow60Counts = regionStatistics.adjacentToAirBelow60Counts;
	JATerrainTypeHistorgram *nonadjacentToAirBelow60Counts = regionStatistics.nonadjacentToAirBelow60Counts;
	JATerrainTypeHistorgram *topmostCounts = regionStatistics.topmostCounts;
	
	MCGridCoordinates coords;
	for (coords.x = 0; coords.x < 16; coords.x++)
	{
		for (coords.z = 0; coords.z < 16; coords.z++)
		{
			for (coords.y = 0; coords.y < 128; coords.y++)
			{
				MCCell cell = [chunk cellAt:coords gettingTileEntity:NULL];
				[countsByLayer incrementValueForBlockType:cell.blockID onLayer:coords.y];
				[totalCounts incrementValueForBlockType:cell.blockID];
				
				/*
					For blocks below level 60, separately count exposed-to-air
					and enclosed blocks. Blocks on chunk borders are ignored
					since we’d need to look at adjacent chunks to get good
					data for those.
				*/
				if (coords.y < 60 &&
					0 < coords.x && coords.x < 15 &&
					0 < coords.z && coords.z < 15)
				{
					if (HasAdjacentBlock(chunk, coords, kMCBlockAir))
					{
						[adjacentToAirBelow60Counts incrementValueForBlockType:cell.blockID];
					}
					else
					{
						[nonadjacentToAirBelow60Counts incrementValueForBlockType:cell.blockID];
					}
				}
			}
		}
	}
	
	// Find the topmost non-air block at each x,z coordinate.
	
	for (coords.x = 0; coords.x < 16; coords.x++)
	{
		for (coords.z = 0; coords.z < 16; coords.z++)
		{
			for (coords.y = 127; coords.y >= 0; coords.y--)
			{
				MCCell cell = [chunk cellAt:coords gettingTileEntity:NULL];
				
				if (cell.blockID != kMCBlockAir)
				{
					[topmostCounts incrementValueForBlockType:cell.blockID];
					break;
				}
			}
		}
	}
}


static void Finish(JATerrainStatistics *statistics)
{
	Print(@"Done; processed %lu chunks and rejected %lu chunks in %lu regions.\n", statistics.chunkCount, statistics.rejectedChunkCount, statistics.regionCount);
	
	JATerrainTypeByLayerHistorgram *countsByLayer = statistics.countsByLayer;
	JATerrainTypeHistorgram *totalCounts = statistics.totalCounts;
	JATerrainTypeHistorgram *adjacentToAirBelow60Counts = statistics.adjacentToAirBelow60Counts;
	JATerrainTypeHistorgram *nonadjacentToAirBelow60Counts = statistics.nonadjacentToAirBelow60Counts;
	JATerrainTypeHistorgram *topmostCounts = statistics.topmostCounts;
	
	NSUInteger highestType = 0;
	
	// Write total counts (and find highest extant type).
	FILE *file = fopen("total_counts.csv", "w");
	for (NSUInteger type = 0; type < 256; type++)
	{
		NSUInteger count = [totalCounts valueForBlockType:type];
		FPrint(file, @"%u,%@,%u\n", type, BlockName(type), count);
		if (count != 0)  highestType = type;
	}
	fclose(file);
	
	// Write below-60-adjacent-to-air counts.
	file = fopen("below_60_adjacent_to_air.csv", "w");
	for (NSUInteger type = 0; type < 256; type++)
	{
		NSUInteger count = [adjacentToAirBelow60Counts valueForBlockType:type];
		FPrint(file, @"%u,%@,%u\n", type, BlockName(type), count);
	}
	fclose(file);
	
	// Write below-60-nonadjacent-to-air counts.
	file = fopen("below_60_not_adjacent_to_air.csv", "w");
	for (NSUInteger type = 0; type < 256; type++)
	{
		NSUInteger count = [nonadjacentToAirBelow60Counts valueForBlockType:type];
		FPrint(file, @"%u,%@,%u\n", type, BlockName(type), count);
	}
	fclose(file);
	
	// Write topmost counts.
	file = fopen("topmost_counts.csv", "w");
	for (NSUInteger type = 0; type < 256; type++)
	{
		NSUInteger count = [topmostCounts valueForBlockType:type];
		FPrint(file, @"%u,%@,%u\n", type, BlockName(type), count);
	}
	fclose(file);
	
	// Write counts by layer.
	file = fopen("counts_by_layer.csv", "w");
	FPrint(file, @"Layer");
	for (NSUInteger type = 0; type <= highestType; type++)
	{
		FPrint(file, @",%@", BlockName(type));
	}
	FPrint(file, @"\n");
	for (NSUInteger y = 0; y < 128; y++)
	{
		FPrint(file, @"%u", y);
		for (NSUInteger type = 0; type <= highestType; type++)
		{
			FPrint(file, @",%u", [countsByLayer valueForBlockType:type onLayer:y]);
		}
		FPrint(file, @"\n");
	}
	fclose(file);
	
	// Write summary.
	file = fopen("summary.txt", "w");
	NSNumberFormatter *formatter = [NSNumberFormatter new];
	formatter.numberStyle = kCFNumberFormatterDecimalStyle;
	
	FPrint(file, @"Summary\n=======\n");
	FPrint(file, @"Date: %@\n", [NSDate date]);
	FPrint(file, @"Regions: %@\n", [formatter stringFromNumber:[NSNumber numberWithUnsignedInteger:statistics.regionCount]]);
	FPrint(file, @"Chunks: %@\n", [formatter stringFromNumber:[NSNumber numberWithUnsignedInteger:statistics.chunkCount]]);
	FPrint(file, @"Rejected chunks (TerrainPopulated flag not set): %@\n", [formatter stringFromNumber:[NSNumber numberWithUnsignedInteger:statistics.rejectedChunkCount]]);
	FPrint(file, @"Blocks counted: %@\n", [formatter stringFromNumber:[NSNumber numberWithUnsignedInteger:statistics.chunkCount * 16 * 16 * 128]]);
	fclose(file);
}


static NSString *BlockName(uint8_t blockType)
{
	static NSString * const names[] =
	{
		@"Air",
		@"Stone",
		@"Grass",
		@"Dirt",
		@"Cobblestone",
		@"Wood",
		@"Sapling",
		@"Bedrock",
		@"Water",
		@"Stationary water",
		@"Lava",
		@"Stationary lava",
		@"Sand",
		@"Gravel",
		@"Gold ore",
		@"Iron ore",
		@"Coal",
		@"Log",
		@"Leaves",
		@"Sponge",
		@"Glass",
		@"Lapis lazuli",
		@"Block of lapis lazuli",
		@"Dispenser",
		@"Sandstone",
		@"Note block",
		@"Bed",
		@"Powered rail",
		@"Detector rail",
		@"Sticky piston",
		@"Cobweb",
		@"Tall grass",
		@"Dead shrubs",
		@"Piston",
		@"Piston head",
		@"Wool",
		@"Moving piston head",
		@"Yellow flower",
		@"Rose",
		@"Brown mushroom",
		@"Red mushroom",
		@"Block of gold",
		@"Block of iron",
		@"Double slab",
		@"Slab",
		@"Bricks",
		@"TNT",
		@"Bookshelf",
		@"Moss stone",
		@"Obsidian",
		@"Torch",
		@"Fire",
		@"Mob spawner",
		@"Wooden stairs",
		@"Chest",
		@"Redstone wire",
		@"Diamond",
		@"Block of diamond",
		@"Workbench",
		@"Crops",
		@"Soil",
		@"Furnace (cold)",
		@"Furnace (burning)",
		@"Sign post",
		@"Wooden door",
		@"Ladder",
		@"Rail",
		@"Stone stairs",
		@"Wall sign",
		@"Lever",
		@"Stone pressure plate",
		@"Iron door",
		@"Wooden pressure plate",
		@"Redstone ore",
		@"Redstone ore (glowing)",
		@"Redstone torch (off)",
		@"Redstone torch (on)",
		@"Button",
		@"Snow",
		@"Ice",
		@"Block of snow",
		@"Cactus",
		@"Clay",
		@"Sugar cane",
		@"Jukebox",
		@"Fence",
		@"Pumpkin",
		@"Netherrack",
		@"Sould sand",
		@"Glowstone",
		@"Portal",
		@"Jack-o-lantern",
		@"Cake",
		@"Redstone repeater",	// off
		@"Redstone repeater",	// on
		@"Locked chest",
		@"Trapdoor",
		@"Hidden silverfish",
		@"Stone brick",
		@"Huge brown mushroom",
		@"Huge red mushroom",
		@"Iron bars",
		@"Glass pane",
		@"Watermelon",
		@"Pumpkin stem",
		@"Melon stem",
		@"Vines",
		@"Gate",
		@"Brick stairs",
		@"Stone brick stairs",
		@"Mycelium",
		@"Lily pad",
		@"Nether brick",
		@"Nether brick fence",
		@"Nether brick stairs",
		@"Nether wart",
		@"Enchantment table",
		@"Brewing stand",
		@"Cauldron",
		@"End portal",
		@"End portal frame",
		@"End stone",
		@"Dragon egg"
	};
	const unsigned count = sizeof names / sizeof names[0];
	
	if (blockType < count)  return names[blockType];
	return $sprintf(@"unknown-%u", blockType);
}


static bool HasAdjacentBlock(JAMinecraftBlockStore *schematic, MCGridCoordinates coords, uint8_t targetType)
{
	if ([schematic cellAt:MCCoordinatesNorthOf(coords) gettingTileEntity:NULL].blockID == targetType)  return true;
	if ([schematic cellAt:MCCoordinatesSouthOf(coords) gettingTileEntity:NULL].blockID == targetType)  return true;
	if ([schematic cellAt:MCCoordinatesEastOf(coords) gettingTileEntity:NULL].blockID == targetType)  return true;
	if ([schematic cellAt:MCCoordinatesWestOf(coords) gettingTileEntity:NULL].blockID == targetType)  return true;
	if ([schematic cellAt:MCCoordinatesAbove(coords) gettingTileEntity:NULL].blockID == targetType)  return true;
	if (coords.y > 0 && [schematic cellAt:MCCoordinatesBelow(coords) gettingTileEntity:NULL].blockID == targetType)  return true;
	
	return NO;
}


static void PrintHelpAndExit(void)
{
	Print(@"Usage: terrainstats <path-to-region-directory>\n");
	exit(EXIT_SUCCESS);
}
