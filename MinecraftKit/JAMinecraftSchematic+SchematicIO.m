/*
	JAMinecraftSchematic+SchematicIO.m
	
	
	Copyright © 2010–2011 Jens Ayton
	
	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the “Software”),
	to deal in the Software without restriction, including without limitation
	the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
	THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.
*/

#import "JAMinecraftSchematic+SchematicIO.h"
#import "JANBTParser.h"
#import "JACollectionHelpers.h"
#import "JAPropertyListAccessors.h"
#import "MYCollectionUtilities.h"


NSString * const kJAMinecraftSchematicUTI = @"com.davidvierra.mcedit.schematic";


static NSString * const kSchematicKey		= @"Schematic";
static NSString * const kMaterialsKey		= @"Materials";
static NSString * const kMaterialsAlpha		= @"Alpha";
static NSString * const kWidthKey			= @"Width";
static NSString * const kLengthKey			= @"Length";
static NSString * const kHeightKey			= @"Height";
static NSString * const kBlocksKey			= @"Blocks";
static NSString * const kDataKey			= @"Data";
static NSString * const kEntitiesKey		= @"TileEntities";
static NSString * const kTileEntitiesKey	= @"TileEntities";
static NSString * const kGroundLevelKey		= @"se.jens.ayton GroundLevel";


static id KeyForCoords(NSInteger x, NSInteger y, NSInteger z)
{
	MCGridCoordinates value = { x, y, z };
	return [NSValue valueWithBytes:&value objCType:@encode(typeof(value))];
}


@implementation JAMinecraftSchematic (SchematicIO)

- (id) initWithSchematicData:(NSData *)data error:(NSError **)outError
{
	if (outError != NULL)  *outError = nil;
	
	if (data == nil)
	{
		if (outError != nil)  *outError = [NSError errorWithDomain:kJAMinecraftBlockStoreErrorDomain
															  code:kJABlockStoreErrorNilData
														  userInfo:nil];
		return nil;
	}
	
	JANBTTag *root = [JANBTParser parseData:data];
	
	if (root.type != kJANBTTagCompound || ![root.name isEqualToString:kSchematicKey])
	{
		if (outError != nil)  *outError = [NSError errorWithDomain:kJAMinecraftBlockStoreErrorDomain
															  code:kJABlockStoreErrorWrongFileFormat
														  userInfo:nil];
		return nil;
	}
	
	NSDictionary *dict = root.objectValue;
	
	NSUInteger width = [[dict objectForKey:kWidthKey] integerValue];
	NSUInteger length = [[dict objectForKey:kLengthKey] integerValue];
	NSUInteger height = [[dict objectForKey:kHeightKey] integerValue];
	
	NSUInteger planeSize = width * length * height;
	
	NSData *blockIDs = [[dict objectForKey:kBlocksKey] objectValue];
	NSData *blockData = [[dict objectForKey:kDataKey] objectValue];
	if (![blockIDs isKindOfClass:[NSData class]] || ![blockData isKindOfClass:[NSData class]] || blockIDs.length < planeSize || blockData.length < planeSize)
	{
		if (outError != nil)  *outError = [NSError errorWithDomain:kJAMinecraftBlockStoreErrorDomain
															  code:kJABlockStoreErrorTruncatedData
														  userInfo:nil];
		return nil;
	}
	
	NSMutableDictionary *tileEntities = nil;
	NSArray *serializedEntities = [[dict objectForKey:kTileEntitiesKey] objectValue];
	if ([serializedEntities isKindOfClass:[NSArray class]])
	{
		tileEntities = [NSMutableDictionary dictionaryWithCapacity:serializedEntities.count];
		
		[serializedEntities enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
		{
			NSDictionary *entityDef = [obj propertyListRepresentation];
			NSUInteger x = [entityDef ja_integerForKey:@"x"];
			NSUInteger y = [entityDef ja_integerForKey:@"y"];
			NSUInteger z = [entityDef ja_integerForKey:@"z"];
			entityDef = [entityDef ja_dictionaryByRemovingObjectsForKeys:$set(@"x", @"y", @"z")];
			
			[tileEntities setObject:entityDef forKey:KeyForCoords(x, y, z)];
		}];
	}
	
	const uint8_t *blockBytes = blockIDs.bytes;
	const uint8_t *metaBytes = blockData.bytes;
	
	self = [self init];
	if (self == nil)
	{
		if (outError != nil)  *outError = [NSError errorWithDomain:NSOSStatusErrorDomain
															  code:memFullErr
														  userInfo:nil];
		return nil;
	}
	
	[self beginBulkUpdate];
	
	NSUInteger x, y, z;
	for (y = 0; y < height; y++)
	{
		for (z = 0; z < length; z++)
		{
			for (x = 0; x < width; x++)
			{
				uint8_t blockID = *blockBytes++;
				uint8_t meta = *metaBytes++;
				
				MCCell cell = { .blockID = blockID, .blockData = meta };
				
				NSDictionary *entity = [tileEntities objectForKey:KeyForCoords(x, y, z)];
				
				[self setCell:cell
				andTileEntity:entity
						   at:(MCGridCoordinates){x, y, z}];
			}
		}
	}
	
	[self endBulkUpdate];
	
	NSInteger groundLevel;
	JANBTTag *groundLevelTag = [dict objectForKey:kGroundLevelKey];
	if (groundLevelTag.integerType)  groundLevel = groundLevelTag.integerValue;
	else  groundLevel = [self findNaturalGroundLevel];
	
	if (groundLevel != 0)
	{
		JAMinecraftSchematic *leveled = [[[self class] alloc] initWithGroundLevel:groundLevel];
		MCGridExtents extents = self.extents;
		[leveled beginBulkUpdate];
		[leveled fillRegion:extents withCell:kMCAirCell];
		[leveled copyRegion:extents from:self at:MCGridExtentsMinimum(extents)];
		[leveled endBulkUpdate];
		return leveled;
	}
	
	return self;
}


- (NSData *) schematicDataWithError:(NSError **)outError
{
	return [self schematicDataForRegion:self.extents withError:outError];
}


static JANBTTag *MakeTileEntityNBT(NSDictionary *entityDict, MCGridCoordinates location)
{
	NSMutableDictionary *mutableEntityDict = [entityDict mutableCopy];
	[mutableEntityDict ja_setInteger:location.x forKey:@"x"];
	[mutableEntityDict ja_setInteger:location.y forKey:@"y"];
	[mutableEntityDict ja_setInteger:location.z forKey:@"z"];
	
	JANBTTag *result = [JANBTTag tagWithName:nil propertyListRepresentation:mutableEntityDict];
	[mutableEntityDict release];
	return result;
}


- (NSData *) schematicDataForRegion:(MCGridExtents)region withError:(NSError **)outError
{
	NSMutableDictionary *root = [NSMutableDictionary dictionary];
	
	// Note that the concept of width and height differs.
	NSUInteger width = MCGridExtentsWidth(region);
	NSUInteger length = MCGridExtentsLength(region);
	NSUInteger height = MCGridExtentsHeight(region);
	
	[root ja_setNBTInteger:width type:kJANBTTagShort forKey:kWidthKey];
	[root ja_setNBTInteger:length type:kJANBTTagShort forKey:kLengthKey];
	[root ja_setNBTInteger:height type:kJANBTTagShort forKey:kHeightKey];
	
	[root ja_setNBTInteger:self.groundLevel forKey:kGroundLevelKey];
	[root ja_setNBTString:kMaterialsAlpha forKey:kMaterialsKey];
	
	NSUInteger planeSize = width * length * height;
	NSMutableData *blockIDs = [NSMutableData dataWithLength:planeSize];
	NSMutableData *blockData = [NSMutableData dataWithLength:planeSize];
	if (blockIDs == nil || blockData == nil)
	{
		if (outError != nil)  *outError = [NSError errorWithDomain:NSOSStatusErrorDomain
															  code:memFullErr
														  userInfo:nil];
		return nil;
	}
	
	NSMutableArray *tileEntities = [NSMutableArray array];
	
	uint8_t *blockBytes = blockIDs.mutableBytes;
	uint8_t *metaBytes = blockData.mutableBytes;
	
	MCGridCoordinates location;
	for (location.y = region.minY; location.y <= region.maxY; location.y++)
	{
		for (location.z = region.minZ; location.z <= region.maxZ; location.z++)
		{
			for (location.x = region.minX; location.x <= region.maxX; location.x++)
			{
				NSDictionary *tileEntity = nil;
				MCCell cell = [self cellAt:location gettingTileEntity:&tileEntity];
				*blockBytes++ = cell.blockID;
				*metaBytes++ = cell.blockData & 0x0F;
				
				if (tileEntity != nil)
				{
					[tileEntities addObject:MakeTileEntityNBT(tileEntity, location)];
				}
			}
		}
	}
	
	[root ja_setNBTByteArray:blockIDs forKey:kBlocksKey];
	[root ja_setNBTByteArray:blockData forKey:kDataKey];
	[root ja_setNBTList:tileEntities forKey:kTileEntitiesKey];
	
	JANBTTag *nbtRoot = [root ja_asNBTTagWithName:kSchematicKey];
	return [JANBTEncoder encodeTag:nbtRoot];
}

@end
