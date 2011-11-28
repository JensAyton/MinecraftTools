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
#import "JANBTSerialization.h"
#import "JACollectionHelpers.h"
#import "JAPropertyListAccessors.h"
#import "MYCollectionUtilities.h"
#import "MCKitSchema.h"


NSString * const kJAMinecraftSchematicUTI = @"com.davidvierra.mcedit.schematic";


static NSString * const kSchematicKey		= @"Schematic";
static NSString * const kMaterialsKey		= @"Materials";
static NSString * const kMaterialsAlpha		= @"Alpha";
static NSString * const kWidthKey			= @"Width";
static NSString * const kLengthKey			= @"Length";
static NSString * const kHeightKey			= @"Height";
static NSString * const kBlocksKey			= @"Blocks";
static NSString * const kDataKey			= @"Data";
static NSString * const kEntitiesKey		= @"Entities";
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
	
	NSDictionary *schema = GetSchematicSchema();
	NSString *rootName = kSchematicKey;
	
	NSDictionary *dict = [JANBTSerialization NBTObjectWithData:data rootName:&rootName options:0 schema:schema error:outError];
	if (dict == nil)
	{
		if (outError != NULL)  *outError = [NSError errorWithDomain:kJAMinecraftBlockStoreErrorDomain
															   code:kJABlockStoreErrorWrongFileFormat
														   userInfo:$dict(NSUnderlyingErrorKey, *outError)];
		return nil;
	}
	
	NSUInteger width = [dict ja_integerForKey:kWidthKey];
	NSUInteger length = [dict ja_integerForKey:kLengthKey];
	NSUInteger height = [dict ja_integerForKey:kHeightKey];
	
	NSUInteger planeSize = width * length * height;
	
	NSData *blockIDs = [dict objectForKey:kBlocksKey];
	NSData *blockData = [dict objectForKey:kDataKey];
	if (blockIDs.length < planeSize || blockData.length < planeSize)
	{
		if (outError != nil)  *outError = [NSError errorWithDomain:kJAMinecraftBlockStoreErrorDomain
															  code:kJABlockStoreErrorTruncatedData
														  userInfo:nil];
		return nil;
	}
	
	NSMutableDictionary *tileEntities;
	NSArray *serializedEntities = [dict objectForKey:kTileEntitiesKey];
	tileEntities = [NSMutableDictionary dictionaryWithCapacity:serializedEntities.count];
	
	NSSet *coordKeys = $set(@"x", @"y", @"z");
	[serializedEntities enumerateObjectsUsingBlock:^(id entityDef, NSUInteger idx, BOOL *stop)
	{
		NSUInteger x = [entityDef ja_integerForKey:@"x"];
		NSUInteger y = [entityDef ja_integerForKey:@"y"];
		NSUInteger z = [entityDef ja_integerForKey:@"z"];
		entityDef = [entityDef ja_dictionaryByRemovingObjectsForKeys:coordKeys];
		
		[tileEntities setObject:entityDef forKey:KeyForCoords(x, y, z)];
	}];
	
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
		@autoreleasepool
		{
			for (z = 0; z < length; z++)
			{
				for (x = 0; x < width; x++)
				{
					uint8_t blockID = *blockBytes++;
					uint8_t meta = *metaBytes++;
					
					MCCell cell = { .blockID = blockID, .blockData = meta & kMCInfoStandardBitsMask };
					
					NSDictionary *entity = [tileEntities objectForKey:KeyForCoords(x, y, z)];
					
					[self setCell:cell
					andTileEntity:entity
							   at:(MCGridCoordinates){x, y, z}];
				}
			}
		}
	}
	
	[self endBulkUpdate];
	
	NSInteger groundLevel = [dict ja_integerForKey:kGroundLevelKey defaultValue:NSNotFound];
	if (groundLevel == NSNotFound)  groundLevel = [self findNaturalGroundLevel];
	
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


- (NSData *) schematicDataForRegion:(MCGridExtents)region withError:(NSError **)outError
{
	NSMutableDictionary *root = [NSMutableDictionary dictionary];
	
	NSUInteger width = MCGridExtentsWidth(region);
	NSUInteger length = MCGridExtentsLength(region);
	NSUInteger height = MCGridExtentsHeight(region);
	
	[root ja_setInteger:width forKey:kWidthKey];
	[root ja_setInteger:length forKey:kLengthKey];
	[root ja_setInteger:height forKey:kHeightKey];
	
	[root ja_setInteger:self.groundLevel forKey:kGroundLevelKey];
	[root setObject:kMaterialsAlpha forKey:kMaterialsKey];
	
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
				__autoreleasing NSDictionary *tileEntity;
				MCCell cell = [self cellAt:location gettingTileEntity:&tileEntity];
				*blockBytes++ = cell.blockID;
				*metaBytes++ = cell.blockData & kMCInfoStandardBitsMask;
				
				if (tileEntity != nil)
				{
					@autoreleasepool
					{
						NSMutableDictionary *mutableEntity = [tileEntity mutableCopy];
						[mutableEntity ja_setInteger:location.x forKey:@"x"];
						[mutableEntity ja_setInteger:location.y forKey:@"y"];
						[mutableEntity ja_setInteger:location.z forKey:@"z"];
						
						[tileEntities addObject:mutableEntity];
					}
				}
			}
		}
	}
	
	[root setObject:blockIDs forKey:kBlocksKey];
	[root setObject:blockData forKey:kDataKey];
	[root setObject:tileEntities forKey:kTileEntitiesKey];
	[root setObject:[NSArray array] forKey:kEntitiesKey];
	
	NSDictionary *schema = GetSchematicSchema();
	
	return [JANBTSerialization dataWithNBTObject:root
										rootName:kSchematicKey
										 options:0
										  schema:schema
										   error:outError];
}

@end
