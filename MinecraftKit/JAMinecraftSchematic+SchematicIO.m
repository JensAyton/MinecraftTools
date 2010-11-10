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
	
	NSDictionary *dict = [root dictionaryRepresentation];
	
	NSUInteger width = [[dict objectForKey:@"Width"] integerValue];
	NSUInteger height = [[dict objectForKey:@"Length"] integerValue];
	NSUInteger depth = [[dict objectForKey:@"Height"] integerValue];
	
	NSUInteger planeSize = width * height * depth;
	
	NSData *blockData = [[dict objectForKey:@"Blocks"] objectValue];
	NSData *metaData = [[dict objectForKey:@"Data"] objectValue];
	if (![blockData isKindOfClass:[NSData class]] || ![metaData isKindOfClass:[NSData class]] || blockData.length < planeSize || metaData.length < planeSize)
	{
		if (outError != nil)  *outError = [NSError errorWithDomain:kJAMinecraftSchematicErrorDomain
															  code:kJACircuitErrorTruncatedData
														  userInfo:nil];
		return nil;
	}
	
	const uint8_t *blockBytes = blockData.bytes;
	const uint8_t *metaBytes = metaData.bytes;
	
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
	for (z = 0; z < depth; z++)
	{
		for (y = 0; y < height; y++)
		{
			for (x = 0; x < width; x++)
			{
				uint8_t blockID = *blockBytes++;
				uint8_t meta = *metaBytes++;
				
				JAMinecraftCell cell = { .blockID = blockID, .blockData = meta };
				[self setCell:cell
						   at:(JACellLocation){width - y, x, z}];	// Coordinate weirdness inherited from MCEdit, which got it from Minecraft.
			}
		}
	}
	
	[self endBulkUpdate];
	
	return self;
}

@end
