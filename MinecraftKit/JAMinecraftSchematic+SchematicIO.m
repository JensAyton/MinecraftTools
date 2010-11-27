/*
	JAMinecraftSchematic+SchematicIO.m
	
	
	Copyright © 2010 Jens Ayton
	
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


NSString * const kJAMinecraftSchematicUTI = @"com.davidvierra.mcedit.schematic";


static NSString * const kSchematicKey	= @"Schematic";
static NSString * const kMaterialsKey	= @"Materials";
static NSString * const kMaterialsAlpha	= @"Alpha";
static NSString * const kWidthKey		= @"Width";
static NSString * const kLengthKey		= @"Length";
static NSString * const kHeightKey		= @"Height";
static NSString * const kBlocksKey		= @"Blocks";
static NSString * const kDataKey		= @"Data";
static NSString * const kGroundLevelKey	= @"se.jens.ayton GroundLevel";


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
				
				[self setCell:cell
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
	
	uint8_t *blockBytes = blockIDs.mutableBytes;
	uint8_t *metaBytes = blockData.mutableBytes;
	
	MCGridCoordinates location;
	for (location.y = region.minY; location.y <= region.maxY; location.y++)
	{
		for (location.z = region.minZ; location.z <= region.maxZ; location.z++)
		{
			for (location.x = region.minX; location.x <= region.maxX; location.x++)
			{
				MCCell cell = [self cellAt:location];
				*blockBytes++ = cell.blockID;
				*metaBytes++ = cell.blockData & 0x0F;
			}
		}
	}
	
	[root ja_setNBTByteArray:blockIDs forKey:kBlocksKey];
	[root ja_setNBTByteArray:blockData forKey:kDataKey];
	
	JANBTTag *nbtRoot = [root ja_asNBTTagWithName:kSchematicKey];
	return [JANBTEncoder encodeTag:nbtRoot];
}

@end
