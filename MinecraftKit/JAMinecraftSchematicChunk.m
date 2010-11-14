/*
	JAMinecraftSchematicChunk.m
	
	
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

#import "JAMinecraftSchematicChunk.h"


@implementation JAMinecraftSchematicChunk

// no initializer required; zeroed memory has invalid extents and empty cells.


static inline unsigned Offset(unsigned x, unsigned y, unsigned z)  __attribute__((const, always_inline));
static inline unsigned Offset(unsigned x, unsigned y, unsigned z)
{
	return (z * kJAMinecraftSchematicChunkSize + y) * kJAMinecraftSchematicChunkSize + x;
}


- (MCCell) chunkCellAtX:(NSInteger)x y:(NSInteger)y z:(NSInteger)z
{
	NSParameterAssert(0 <= x && x < kJAMinecraftSchematicChunkSize &&
					  0 <= y && y < kJAMinecraftSchematicChunkSize &&
					  0 <= z && z < kJAMinecraftSchematicChunkSize);
	
	return _cells[Offset(x, y, z)];
}


- (void) setChunkCell:(MCCell)cell atX:(NSInteger)x y:(NSInteger)y z:(NSInteger)z
{
	NSParameterAssert(0 <= x && x < kJAMinecraftSchematicChunkSize &&
					  0 <= y && y < kJAMinecraftSchematicChunkSize &&
					  0 <= z && z < kJAMinecraftSchematicChunkSize);
	
	_cells[Offset(x, y, z)] = cell;
	_extentsAreAccurate = NO;
	
	// FIXME: it would be more efficient to update extents here if placing a non-empty cell.
}


- (MCGridExtents) extents
{
	if (_extentsAreAccurate)  return _extents;
	
	unsigned maxX = 0, minX = UINT_MAX;
	unsigned maxY = 0, minY = UINT_MAX;
	unsigned maxZ = 0, minZ = UINT_MAX;
	
	unsigned x, y, z;
	for (z = 0; z < kJAMinecraftSchematicChunkSize; z++)
	{
		for (y = 0; y < kJAMinecraftSchematicChunkSize; y++)
		{
			for (x = 0; x < kJAMinecraftSchematicChunkSize; x++)
			{
				if (!MCCellIsAir(_cells[Offset(x, y, z)]))
				{
					minX = MIN(minX, x);
					maxX = MAX(maxX, x);
					minY = MIN(minY, y);
					maxY = MAX(maxY, y);
					minZ = MIN(minZ, z);
					maxZ = MAX(maxZ, z);
				}
			}	
		}
	}
	
	MCGridExtents result;
	if (minX != UINT_MAX)  result = (MCGridExtents){ minX, maxX, minY, maxY, minZ, maxZ };
	else  result = kMCEmptyExtents;
	
	_extents = result;
	_extentsAreAccurate = YES;
	return result;
}


#ifndef NDEBUG

- (NSString *) description
{
	return [NSString stringWithFormat:@"<%@ %p>{%@}", self.class, self, self.label];
}

#endif

@end
