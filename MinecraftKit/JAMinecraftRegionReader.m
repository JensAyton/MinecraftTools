/*
	JAMinecraftRegionReader.m
	
	
	Copyright © 2011 Jens Ayton
	
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

#import "JAMinecraftRegionReader.h"
#import "JAMinecraftChunkBlockStore.h"


enum
{
	kChunksPerRegionSide			= 32,
	kChunksPerRegion				= kChunksPerRegionSide * kChunksPerRegionSide,
	kHeaderBytesPerChunk			= 8,
	kHeaderSize						= kHeaderBytesPerChunk * kChunksPerRegion,
	kSectorSize						= 4096,
	kChunkHeaderSize				= 5
};


enum
{
	kChunkCompressionModeGZip		= 1,
	kChunkCompressionModeZLib		= 2
};


static inline uint16_t ChunkIndexFromLocalCoords(uint16_t x, uint16_t z)
{
	return z * kChunksPerRegionSide + x;
}


@interface JAMinecraftRegionReader ()

- (BOOL) parseHeader;

@end


@implementation JAMinecraftRegionReader
{
	NSData					*_regionData;
	uint32_t				_offsets[kChunksPerRegion];
}


- (id) initWithData:(NSData *)data
{
	if (data.length < kHeaderSize)
	{
		return nil;
	}
	
	if ((self = [super init]))
	{
		_regionData = data;
		if (![self parseHeader])  return nil;
	}
	
	return self;
}


+ (id) regionReaderWithData:(NSData *)regionData
{
	return [[self alloc] initWithData:regionData];
}


+ (id) regionReaderWithURL:(NSURL *)regionFileURL
{
	NSData *data = [NSData dataWithContentsOfURL:regionFileURL options:NSDataReadingMappedIfSafe error:NULL];
	if (data == nil)  return nil;
	return [self regionReaderWithData:data];
}



- (BOOL) parseHeader
{
	/*
		The header consists of two arrays of kChunksPerRegion entries each.
		Entries in the first array are consist of a big-endian 24-bit offset
		and 8-bit size, measured in 4 KiB sectors. The second array contains
		big-endian 32-bit time stamps, which we currently don’t care about.
	*/
	
	const uint32_t *header = (const uint32_t *)_regionData.bytes;
	for (NSUInteger idx = 0; idx < kChunksPerRegion; idx++)
	{
		uint32_t offset = *header++;
		offset = ntohl(offset) >> 8;
		
		_offsets[idx] = offset;
	}
	
	return YES;
}


- (BOOL) hasChunkAtLocalX:(uint8_t)x localZ:(uint8_t)z
{
	NSParameterAssert(x < kChunksPerRegionSide && z < kChunksPerRegionSide);
	return _offsets[ChunkIndexFromLocalCoords(x, z)] != 0;
}


- (JAMinecraftChunkBlockStore *) chunkAtLocalX:(uint8_t)x localZ:(uint8_t)z
{
	return [[JAMinecraftChunkBlockStore alloc] initWithData:[self chunkDataAtLocalX:x localZ:z] error:NULL];
}


- (NSData *) chunkDataAtLocalX:(uint8_t)x localZ:(uint8_t)z
{
	NSParameterAssert(x < kChunksPerRegionSide && z < kChunksPerRegionSide);
	NSUInteger offset = _offsets[ChunkIndexFromLocalCoords(x, z)];
	if (offset == 0)  return nil;	// Chunk not present.
	
	offset *= kSectorSize;
	NSUInteger totalSize = _regionData.length;
	if (offset + kChunkHeaderSize >= totalSize)  return nil;	// Corrupt region file; chunk is out of bounds.
	
	const uint8_t *bytes = _regionData.bytes + offset;
	NSUInteger length = htonl(*(uint32_t *)bytes);
	if (offset + kChunkHeaderSize + length >= totalSize)  return nil;	// Corrupt region file; chunk is out of bounds.
	
	// JAZLibCompressionMode compressionMode;
	switch (bytes[4])
	{
		case kChunkCompressionModeGZip:
			//	compressionMode = kJAZLibCompressionGZip;
			break;
			
		case kChunkCompressionModeZLib:
			//	compressionMode = kJAZLibCompressionZLib;
			break;
			
		default:
			return nil;		// Unknown compression type.
	}
	
	// The compression mode is unused; the compression type is detected automatically when parsing NBTs.
	
	return [_regionData subdataWithRange:(NSRange){ offset + kChunkHeaderSize, length }];
}

@end
