/*
	JAMinecraftChunkBlockStore.m
	
	
	Copyright © 2013 Jens Ayton
	
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

#import "JAMinecraftAnvilChunkBlockStore.h"
#import <JANBTSerialization/JANBTSerialization.h>
#import "MCKitSchema.h"
#import "JACollectionHelpers.h"
#import "JAPropertyListAccessors.h"


enum
{
	kWidth					= 16,	// x
	kLength					= 16,	// z
	kSectionHeight			= 16,	// y per section
	kNominalHeight			= 256,
	
	kGroundLevel			= 63,
	
	kSectionBlockIDsSize	= kWidth * kSectionHeight * kLength,
	kSectionBlockDataSize	= kSectionBlockIDsSize / 2
};


static __attribute__((pure)) off_t IndexFromCoordinates(MCGridCoordinates coords)
{
	return (coords.y * kLength + coords.z) * kWidth + coords.x;
}


static id KeyForCoords(NSInteger x, NSInteger y, NSInteger z)
{
	off_t idx = IndexFromCoordinates((MCGridCoordinates){ x, y, z });
	return @(idx);
}


/** Store for blocks in a 16×16×16 section.
 *
 * Not a subclass of BlockStore because it doesn't have all the metadata and
 * entities.
 */
@interface JAMinecraftAnvilSection: NSObject

- (MCCell) cellAt:(MCGridCoordinates)location;
- (void) setCell:(MCCell)cell at:(MCGridCoordinates)location;
- (BOOL) loadFromInfo:(NSDictionary *)info error:(NSError **)error;

@property (nonatomic, readonly, getter=isEmpty) bool empty;

@end


@implementation JAMinecraftAnvilChunkBlockStore
{
	NSMutableArray			*_sections;
	NSMutableDictionary		*_tileEntities;
}


- (id) initWithData:(NSData *)data error:(NSError **)error
{
	if (error != NULL)  *error = nil;
	
	if (data == nil)
	{
		if (error != nil)  *error = [NSError errorWithDomain:kJAMinecraftBlockStoreErrorDomain
														code:kJABlockStoreErrorNilData
													userInfo:nil];
		return nil;
	}
	
	NSDictionary *schema = GetAnvilChunkSchema();
	NSString *rootName = @"";	// For some reason, chunks have an empty root name and contain a single compound named "Level".
	
	NSDictionary *dict = [JANBTSerialization NBTObjectWithData:data rootName:&rootName options:0 schema:schema error:error];
	dict = dict[@"Level"];
	if (dict == nil)
	{
		if (error != NULL)  *error = [NSError errorWithDomain:kJAMinecraftBlockStoreErrorDomain
														 code:kJABlockStoreErrorWrongFileFormat
													 userInfo:@{ NSUnderlyingErrorKey: *error }];
		return nil;
	}
	
	[self beginBulkUpdate];
	
	// Load sections.
	NSArray *sections = dict[@"Sections"];
	for (NSDictionary *sectionInfo in sections)
	{
		NSUInteger yIndex = [sectionInfo[@"Y"] intValue];
		if (![[self sectionAtIndex:yIndex] loadFromInfo:sectionInfo error:error])
		{
			return nil;
		}
	}
	
	// Load tile entities.
	NSArray *serializedEntities = dict[@"TileEntities"];
	_tileEntities = [NSMutableDictionary dictionaryWithCapacity:serializedEntities.count];
	
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
	
	self.metadata = [dict ja_dictionaryByRemovingObjectsForKeys:[NSSet setWithObjects:@"Sections", @"TileEntities", @"HeightMap", nil]];
	
	[self endBulkUpdate];
	[self noteChangeInExtents:self.extents];
	
	return self;
}


- (NSInteger) minimumLayer
{
	return 0;
}


- (NSInteger) maximumLayer
{
	return kNominalHeight - 1;
}


- (MCGridExtents) extents
{
	return (MCGridExtents){ 0, kWidth, 0, _sections.count * kSectionHeight - 1, 0, kLength };
}


- (NSInteger) groundLevel
{
	// FIXME: zero because we treat all-air sections as "empty" regardless of level.
	return 0;//kGroundLevel;
}



- (MCCell) cellAt:(MCGridCoordinates)location gettingTileEntity:(NSDictionary **)outTileEntity
{
	if (outTileEntity != NULL)
	{
		*outTileEntity = [_tileEntities objectForKey:KeyForCoords(location.x, location.y, location.z)];
	}
	
	JAMinecraftAnvilSection *section = [self sectionAtIndex:location.y / kSectionHeight];
	location.y %= kSectionHeight;
	
	return [section cellAt:location];
}


- (void) setCell:(MCCell)cell andTileEntity:(NSDictionary *)tileEntity at:(MCGridCoordinates)location
{
	// Any non-negative y is acceptable.
	if (location.y < 0)  return;
	MCGridExtents extents = { 0, kWidth, 0, location.y, 0, kLength };
	if (!MCGridCoordinatesAreWithinExtents(location, extents))  return;
	
	if (tileEntity != nil)
	{
		[_tileEntities setObject:tileEntity forKey:KeyForCoords(location.x, location.y, location.z)];
	}
	else
	{
		[_tileEntities removeObjectForKey:KeyForCoords(location.x, location.y, location.z)];
	}
	
	JAMinecraftAnvilSection *section = [self sectionAtIndex:location.y / kSectionHeight];
	location.y %= kSectionHeight;
	
	[section setCell:cell at:location];
}


- (BOOL) iterateOverRegionsOverlappingExtents:(MCGridExtents)clipExtents
									withBlock:(JAMinecraftRegionIteratorBlock)block
{
	if (block == nil)  return NO;
	
	BOOL stop = NO;
	for (NSUInteger i = 0; i < _sections.count; i++)
	{
		JAMinecraftAnvilSection *section = _sections[i];
		if (section.empty)  continue;
		
		MCGridExtents sectionExtents =
		{
			.minX = 0, .maxX = kWidth - 1,
			.minZ = 0, .maxZ = kLength - 1,
			.minY = i * kSectionHeight,
			.maxY = (i + 1) * kSectionHeight - 1
		};
		if (!MCGridExtentsIntersect(sectionExtents, clipExtents))  continue;
		
		block(sectionExtents, &stop);
		if (stop)  return NO;
	}
	return YES;
}


// Retrieve an indexed section, creating it (and intermediate sections) if necessary.
- (JAMinecraftAnvilSection *) sectionAtIndex:(NSUInteger)index
{
	if (_sections == nil)  _sections = [NSMutableArray new];
	
	while (_sections.count <= index)
	{
		[_sections addObject:[JAMinecraftAnvilSection new]];
	}
	
	return _sections[index];
}

@end


@implementation JAMinecraftAnvilSection
{
	MCCell				*_storage;
}

- (void) dealloc
{
	free(_storage);
}


- (MCCell) cellAt:(MCGridCoordinates)location
{
	if (_storage == nil)  [self createStorage];
	return _storage[IndexFromCoordinates(location)];
}


- (void) setCell:(MCCell)cell at:(MCGridCoordinates)location
{
	if (_storage == nil)  [self createStorage];
	_storage[IndexFromCoordinates(location)] = cell;
}


- (bool) isEmpty
{
	// FIXME: "empty" here means all air, which doesn't suit our ground-level-dependent definition.
	return _storage == nil;
}


- (BOOL) loadFromInfo:(NSDictionary *)info error:(NSError **)error
{
	if (_storage == nil)  [self createStorage];
	
	if (info[@"Add"] != nil)
	{
		// Extended block IDs are not supported (by Minecraft either, at the time of writing).
		if (error != NULL)  *error = [NSError errorWithDomain:kJAMinecraftBlockStoreErrorDomain
														 code:kJABlockStoreErrorExtendedBlockIDsNotSupported
													 userInfo:nil];
		return NO;
	}
	
	NSData *blockIDs = info[@"Blocks"];
	NSData *blockData = info[@"Data"];
	if (blockIDs.length != kSectionBlockIDsSize || blockData.length != kSectionBlockDataSize)
	{
		if (error != NULL)  *error = [NSError errorWithDomain:kJAMinecraftBlockStoreErrorDomain
														 code:kJABlockStoreErrorTruncatedData
													 userInfo:nil];
		return NO;
	}
	
	const unsigned char *blockIDBytes = blockIDs.bytes;
	const unsigned char *blockDataBytes = blockData.bytes;
	for (NSUInteger i = 0; i < kSectionBlockIDsSize; i += 2)
	{
		unsigned char data = blockDataBytes[i / 2];
		_storage[i].blockID = blockIDBytes[i];
		_storage[i].blockData = data >> 4;
		_storage[i + 1].blockID = blockIDBytes[i + 1];
		_storage[i + 1].blockData = data * 0x0F;
	}
	
	return YES;
}


- (void) createStorage
{
	// Note: all zeroes == kMCAirCell
	_storage = calloc(sizeof (MCCell), kWidth * kSectionHeight * kLength);
}

@end
