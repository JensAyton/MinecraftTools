/*
	JAMinecraftSchematic.h
	
	The JAMinecraftSchematic class represents an infiniteish three-dimensional
	matrix of cells containing Minecraft blocks. Data is stored in a sparse
	structure where large areas of empty space take no memory.
	
	“Empty space” is defined as air from ground level up, and smooth stone
	below ground level.
	
	The extents, width, height and depth properties represent the axis-aligned
	bounding box of all non-empty blocks.
	
	Performance characteristics:
	• Reads are worst-case O(log n), where n is the size on the longest side.
	  Sequential reads in any direction are faster on average.
	• Writes are generally also O(log n).
	• Copying is O(1) (in both time and memory), with O(n) deferred costs
	  amortized across writes. (In other words, it’s hierarchically copy-on-
	  write). For example, it is cheap to make a copy of the schematic and
	  make a single-block edit, and this is the recommended way of implementing
	  undoable editing.
	
	
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

#import "JAMinecraftBlockStore.h"

@class JAMinecraftSchematicInnerNode;


@interface JAMinecraftSchematic: JAMutableMinecraftBlockStore <NSCopying>

- (id) initWithGroundLevel:(NSInteger)groundLevel;

- (id) initWithRegion:(MCGridExtents)region ofStore:(JAMinecraftBlockStore *)store;

- (NSInteger) findNaturalGroundLevel;

#ifndef NDEBUG
- (NSString *) debugGraphViz;
- (void) writeDebugGraphVizToURL:(NSURL *)url;
#endif

@end
