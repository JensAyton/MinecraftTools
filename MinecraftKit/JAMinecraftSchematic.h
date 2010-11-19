/*
	JAMinecraftSchematic.h
	
	The JAMinecraftSchematic class represents an infiniteish three-dimensional
	matrix of cells containing Minecraft blocks. Data is stored in a sparse
	structure where large areas of air take no memory. The extents, width,
	height and depth properties represent the axis-aligned bounding box of all
	non-air blocks.
	
	Performance characteristics:
	• Reads are O(log n), where n is the size on the longest side.
	• Writes are generally also O(log n).
	• Copying is O(1) (in both time and memory), with O(n) deferred costs
	  amortized across writes. (In other words, it’s hierarchically copy-on-
	  write). For example, it is cheap to make a copy of the schematic and
	  make a single-block edit, and this is the recommended way of implementing
	  undoable editing.
	
	
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

#import "JAMinecraftBlockStore.h"

@class JAMinecraftSchematicInnerNode;


@interface JAMinecraftSchematic: JAMinecraftBlockStore <NSCopying>

/*
	For schematics, any y range may be used, so the minimum layer is 127
	layers below the highest used y coordinate, and the maximum layer is 127
	layers below the lowest used y coordinate.
	
	For empty schematics, these are NSIntegerMin and NSIntegerMax!
*/
@property (readonly) NSInteger minimumLayer;
@property (readonly) NSInteger maximumLayer;

@end
