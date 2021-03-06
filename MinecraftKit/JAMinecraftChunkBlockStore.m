/*
	JAMinecraftChunkBlockStore.m
	
	
	Copyright © 2011-13 Jens Ayton
	
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

#import "JAMinecraftChunkBlockStore.h"
#import <JANBTSerialization/JANBTSerialization.h>
#import "MCKitSchema.h"
#import "JACollectionHelpers.h"
#import "JAPropertyListAccessors.h"


static NSString * const kLevelKey			= @"Level";
static NSString * const kBlocksKey			= @"Blocks";
static NSString * const kDataKey			= @"Data";
static NSString * const kTileEntitiesKey	= @"TileEntities";
static NSString * const kSkyLightKey		= @"SkyLight";
static NSString * const kBlockLightKey		= @"BlockLight";
static NSString * const kHeightMapKey		= @"HeightMap";


enum
{
	kWidth			= 16,	// x
	kHeight			= 128,	// y
	kLength			= 16,	// z
	
	kGroundLevel	= 63,
	
	kPlaneSize		= kWidth * kHeight * kLength,
	kBlocksSize		= kPlaneSize,
	kDataSize		= kPlaneSize / 2
};


static const MCGridExtents kChunkExtents =
{
	0, kWidth,
	0, kHeight,
	0, kLength
};


static __attribute__((pure)) off_t IndexFromCoords(NSInteger x, NSInteger y, NSInteger z)
{
	return y + kHeight * (z + kLength * x);
}


static id KeyForCoords(NSInteger x, NSInteger y, NSInteger z)
{
	off_t idx = IndexFromCoords(x, y, z);
	return @(idx);
}


@implementation JAMinecraftChunkBlockStore
{
	MCCell				_cells[kWidth * kLength * kHeight];
	NSMutableDictionary	*_tileEntities;
}

@synthesize metadata = _metadata;


- (id) init
{
	if ((self = [super init]))
	{
		_tileEntities = [NSMutableDictionary dictionary];
	}
	
	return self;
}


- (id) initWithData:(NSData *)data error:(NSError **)outError
{
	if (outError != NULL)  *outError = nil;
	
	if (data == nil)
	{
		if (outError != nil)  *outError = [NSError errorWithDomain:kJAMinecraftBlockStoreErrorDomain
															  code:kJABlockStoreErrorNilData
														  userInfo:nil];
		return nil;
	}
	
	NSDictionary *schema = GetChunkSchema();
	NSString *rootName = @"";	// For some reason, chunks have an empty root name and contain a single compound named "Level".
	
	NSDictionary *dict = [JANBTSerialization NBTObjectWithData:data rootName:&rootName options:0 schema:schema error:outError];
	dict = [dict objectForKey:kLevelKey];
	if (dict == nil)
	{
		if (outError != NULL)  *outError = [NSError errorWithDomain:kJAMinecraftBlockStoreErrorDomain
															   code:kJABlockStoreErrorWrongFileFormat
														   userInfo:@{ NSUnderlyingErrorKey: *outError }];
		return nil;
	}
	
	NSData *blockIDs = [dict objectForKey:kBlocksKey];
	NSData *blockData = [dict objectForKey:kDataKey];
	if (blockIDs.length < kBlocksSize || blockData.length < kDataSize)
	{
		if (outError != nil)  *outError = [NSError errorWithDomain:kJAMinecraftBlockStoreErrorDomain
															  code:kJABlockStoreErrorTruncatedData
														  userInfo:nil];
		return nil;
	}
	
	self = [self init];
	if (self == nil)
	{
		if (outError != nil)  *outError = [NSError errorWithDomain:NSOSStatusErrorDomain
															  code:memFullErr
														  userInfo:nil];
		return nil;
	}
	
	[self beginBulkUpdate];
	
	// Load blocks.
	const uint8_t *blockBytes = blockIDs.bytes;
	const uint8_t *metaBytes = blockData.bytes;
	
	NSUInteger x, y, z;
	for (x = 0; x < kWidth; x++)
	{
		for (z = 0; z < kLength; z++)
		{
			uint8_t meta = 0;
			for (y = 0; y < kHeight; y++)
			{
				uint8_t blockID = *blockBytes++;
				if ((x & 1) == 0)
				{
					meta = *metaBytes++;
				}
				else
				{
					meta >>= 4;
				}
				
				MCCell cell = { .blockID = blockID, .blockData = meta & kMCInfoStandardBitsMask };
				_cells[IndexFromCoords(x, y, z)] = cell;
			}
		}
	}
	
	// Load tile entities.
	NSArray *serializedEntities = [dict objectForKey:kTileEntitiesKey];
	
	NSInteger baseX = [dict ja_integerForKey:@"xPos"] * 16;
	NSInteger baseZ = [dict ja_integerForKey:@"zPos"] * 16;
	
	NSSet *coordKeys = [NSSet setWithObjects:@"x", @"y", @"z", nil];
	[serializedEntities enumerateObjectsUsingBlock:^(id entityDef, NSUInteger idx, BOOL *stop)
	{
		NSInteger x = [entityDef ja_integerForKey:@"x"] - baseX;
		NSInteger y = [entityDef ja_integerForKey:@"y"];
		NSInteger z = [entityDef ja_integerForKey:@"z"] - baseZ;
		entityDef = [entityDef ja_dictionaryByRemovingObjectsForKeys:coordKeys];
		
		[_tileEntities setObject:entityDef forKey:KeyForCoords(x, y, z)];
	}];
	
	self.metadata = [dict ja_dictionaryByRemovingObjectsForKeys:[NSSet setWithObjects:kBlocksKey, kDataKey, kTileEntitiesKey, kSkyLightKey, kBlockLightKey, kHeightMapKey, nil]];
	
	[self endBulkUpdate];
	[self noteChangeInExtents:kChunkExtents];
	
	return self;
}


- (NSInteger) minimumLayer
{
	return 0;
}


- (NSInteger) maximumLayer
{
	return kHeight - 1;
}


- (MCGridExtents) extents
{
	return kChunkExtents;
}


- (NSInteger) groundLevel
{
	return kGroundLevel;
}


- (MCCell) cellAt:(MCGridCoordinates)location gettingTileEntity:(NSDictionary **)outTileEntity
{
	if (MCGridCoordinatesAreWithinExtents(location, kChunkExtents))
	{
		if (outTileEntity != NULL)
		{
			*outTileEntity = [_tileEntities objectForKey:KeyForCoords(location.x, location.y, location.z)];
		}
		return _cells[IndexFromCoords(location.x, location.y, location.z)];
	}
	return kMCHoleCell;
}


- (void) setCell:(MCCell)cell andTileEntity:(NSDictionary *)tileEntity at:(MCGridCoordinates)location
{
	if (MCGridCoordinatesAreWithinExtents(location, kChunkExtents))
	{
		if (tileEntity != nil)
		{
			[_tileEntities setObject:tileEntity forKey:KeyForCoords(location.x, location.y, location.z)];
		}
		else
		{
			[_tileEntities removeObjectForKey:KeyForCoords(location.x, location.y, location.z)];
		}
		_cells[IndexFromCoords(location.x, location.y, location.z)] = cell;
		[self noteChangeInLocation:location];
	}
}

@end
