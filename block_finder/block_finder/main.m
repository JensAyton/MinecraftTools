#import <Foundation/Foundation.h>
#import "JAPrintf.h"
#import <JAMinecraftKit/JAMinecraftAnvilRegionReader.h>
#import <JAMinecraftKit/JAMinecraftAnvilChunkBlockStore.h>
#import <JAMinecraftKit/JAMinecraftChunkBlockStore.h>
#import <JAMinecraftKit/JAPropertyListAccessors.h>
#import <JAMinecraftKit/MYCollectionUtilities.h>
#import <JAMinecraftKit/JANBTSerialization.h>


#define ONE_REGION_ONLY		0	// For quick tests, only analyze the first region encountered.

static NSUInteger sQueueCount, sNextQueue;
static dispatch_queue_t *sQueues;
enum
{
	kQueuesPerCore = 2
};


static void PrintHelpAndExit(void) __attribute__((noreturn));

static void AnalyzeRegionsInDirectory(NSString *directory);
static void AnalyzeRegion(NSURL *path);
static void AnalyzeChunk(JAMinecraftAnvilChunkBlockStore *blockStore, NSDictionary *metaData);

static void AnalyzeCommandBlock(JAMinecraftAnvilChunkBlockStore *blockStore, MCGridCoordinates coords);

static void Finish(void);


static dispatch_queue_t sReduceQueue;
static dispatch_group_t sCompletionGroup;

static NSUInteger sTotalRegions;
static bool sAllQueued;


int main (int argc, const char * argv[])
{
	@autoreleasepool
	{
		if (argc < 2 || strcasecmp(argv[1], "--help") == 0 || strcmp(argv[1], "-?") == 0)
		{
			PrintHelpAndExit();
		}
		
		
		sReduceQueue = dispatch_queue_create("se.ayton.jens.block-counter-reduce", DISPATCH_QUEUE_SERIAL);
		sCompletionGroup = dispatch_group_create();
		
		sQueueCount = kQueuesPerCore * [[NSProcessInfo processInfo] processorCount];
		sQueues = calloc(sizeof *sQueues, sQueueCount);
		for (NSUInteger queueIter = 0; queueIter < sQueueCount; queueIter++)
		{
			sQueues[queueIter] = dispatch_queue_create("se.ayton.jens.block-counter-map", DISPATCH_QUEUE_SERIAL);
		}
		
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
		Finish();
	}
	return EXIT_SUCCESS;
}


static void AnalyzeRegionsInDirectory(NSString *directory)
{
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
		if ([url.pathExtension caseInsensitiveCompare:@"mca"] != NSOrderedSame)
		{
			continue;
		}
		
		sTotalRegions++;
		
		dispatch_group_async(sCompletionGroup, sQueues[sNextQueue], ^
		{
			@autoreleasepool
			{
				AnalyzeRegion(url);
			}
		});
		
		sNextQueue = (sNextQueue + 1) % sQueueCount;
		
#if ONE_REGION_ONLY
		break;
#endif
	}
}


static void AnalyzeRegion(NSURL *regionURL)
{
	JAMinecraftAnvilRegionReader *region = [JAMinecraftAnvilRegionReader regionReaderWithURL:regionURL];
	if (region == nil)
	{
		Fatal(@"Could not read region file %@.", regionURL.lastPathComponent);
	}
	
	for (uint8_t x = 0; x < 32; x++)
	{
		for (uint8_t z = 0; z < 32; z++)
		{
			@autoreleasepool
			{
				if (![region hasChunkAtLocalX:x localZ:z])  continue;
				
				NSError *error;
				JAMinecraftAnvilChunkBlockStore *chunk = [region chunkAtLocalX:x localZ:z error:&error];
				if (chunk == nil)
				{
					Fatal(@"Failed to read a chunk. %@\n", error);
				}
				
				if ([chunk.metadata ja_boolForKey:@"TerrainPopulated"])
				{
					AnalyzeChunk(chunk, chunk.metadata);
				}
			}
		}
	}
}


static void AnalyzeChunk(JAMinecraftAnvilChunkBlockStore *chunk, NSDictionary *metaData)
{
	[chunk iterateOverRegionsWithBlock:^(MCGridExtents region, BOOL *stop) {
		MCGridCoordinates coords;
		for (coords.x = region.minX; coords.x < region.maxX; coords.x++)
		{
			for (coords.z = region.minZ; coords.z < region.maxZ; coords.z++)
			{
				for (coords.y = region.minY; coords.y < region.maxY; coords.y++)
				{
					MCCell cell = [chunk cellAt:coords gettingTileEntity:NULL];
					
					switch (cell.blockID)
					{
						case kMCBlockCommandBlock:
							AnalyzeCommandBlock(chunk, coords);
					}
				}
			}
		}
	}];
}


static void AnalyzeCommandBlock(JAMinecraftAnvilChunkBlockStore *blockStore, MCGridCoordinates coords)
{
	NSDictionary *tileEntity;
	(void)[blockStore cellAt:coords gettingTileEntity:&tileEntity];
	
	MCGridCoordinates trueCoords = coords;
	trueCoords.x += [blockStore.metadata[@"xPos"] integerValue] * 16;
	trueCoords.z += [blockStore.metadata[@"zPos"] integerValue] * 16;
	
	Print(@"[%li, %li, %li]: command block \"%@\": %@\n", trueCoords.x, trueCoords.y, trueCoords.z, tileEntity[@"CustomName"], tileEntity[@"Command"]);
}


static void Finish(void)
{
	Print(@"Done.\n");
}


static void PrintHelpAndExit(void)
{
	Print(@"Usage: block_finder <path-to-region-directory>\n");
	exit(EXIT_SUCCESS);
}
