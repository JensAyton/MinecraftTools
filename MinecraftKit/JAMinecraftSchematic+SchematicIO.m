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


@implementation JAMinecraftSchematic (SchematicIO)

- (id) initWithSchematicData:(NSData *)data error:(NSError **)outError
{
	if (outError != NULL)  *outError = nil;
	
	if (data == nil)
	{
		if (outError != nil)  *outError = [NSError errorWithDomain:kJAMinecraftSchematicErrorDomain
															  code:kJACircuitErrorNilData
														  userInfo:nil];
		return nil;
	}
	
	JANBTTag *root = [JANBTParser parseData:data];
	
	if (root.type != kJANBTTagCompound || ![root.name isEqualToString:@"Schematic"])
	{
		if (outError != nil)  *outError = [NSError errorWithDomain:kJAMinecraftSchematicErrorDomain
															  code:kJACircuitErrorWrongFileFormat
														  userInfo:nil];
		return nil;
	}
	
	NSDictionary *dict = root.objectValue;
	
	NSUInteger width = [[dict objectForKey:@"Width"] integerValue];
	NSUInteger length = [[dict objectForKey:@"Length"] integerValue];
	NSUInteger height = [[dict objectForKey:@"Height"] integerValue];
	
	NSUInteger planeSize = width * length * height;
	
	NSData *blockIDs = [[dict objectForKey:@"Blocks"] objectValue];
	NSData *blockData = [[dict objectForKey:@"Data"] objectValue];
	if (![blockIDs isKindOfClass:[NSData class]] || ![blockData isKindOfClass:[NSData class]] || blockIDs.length < planeSize || blockData.length < planeSize)
	{
		if (outError != nil)  *outError = [NSError errorWithDomain:kJAMinecraftSchematicErrorDomain
															  code:kJACircuitErrorTruncatedData
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
	
	[root ja_setNBTInteger:width type:kJANBTTagShort forKey:@"Width"];
	[root ja_setNBTInteger:length type:kJANBTTagShort forKey:@"Length"];
	[root ja_setNBTInteger:height type:kJANBTTagShort forKey:@"Height"];
	
	[root ja_setNBTString:@"Alpha" forKey:@"Materials"];
	
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
				*metaBytes++ = cell.blockData;
			}
		}
	}
	
	[root ja_setNBTByteArray:blockIDs forKey:@"Blocks"];
	[root ja_setNBTByteArray:blockData forKey:@"Data"];
	
	JANBTTag *nbtRoot = [root ja_asNBTTagWithName:@"Schematic"];
	return [JANBTEncoder encodeTag:nbtRoot];
}

@end
