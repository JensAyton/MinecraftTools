/*
	JAMinecraftLegacyRegionReader.h
	
	Read-only extractor for pre-1.2 Minecraft region files.
	
	
	Copyright © 2011–2016 Jens Ayton
	
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

#import <Foundation/Foundation.h>
#import "JAMinecraftRegionReader.h"

@class JAMinecraftChunkBlockStore;


@interface JAMinecraftLegacyRegionReader: NSObject <JAMinecraftRegionReader>

+ (id) regionReaderWithData:(NSData *)regionData;
+ (id) regionReaderWithURL:(NSURL *)regionFileURL;

// Chunk coordinates range from 0 to 32 in region-local space.
- (BOOL) hasChunkAtLocalX:(uint8_t)x localZ:(uint8_t)z;

// Retrieve chunk.
- (JAMinecraftChunkBlockStore *) chunkAtLocalX:(uint8_t)x localZ:(uint8_t)z;
- (JAMinecraftChunkBlockStore *) chunkAtLocalX:(uint8_t)x localZ:(uint8_t)z error:(NSError **)error;

@end
