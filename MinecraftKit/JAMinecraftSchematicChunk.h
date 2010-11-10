/*
	JAMinecraftSchematicChunk.h
	RDatViewer
	
	A fixed-size cubic chunk of a schematic. Intended for internal use by
	JAMinecraftSchematic. It is likely to be changed or replaced with a struct
	in future.
	
	
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

#import "JAMinecraftTypes.h"


enum
{
	kJAMinecraftSchematicChunkSize		= 8,
	kJAMinecraftSchematicCellsPerChunk	= kJAMinecraftSchematicChunkSize * kJAMinecraftSchematicChunkSize * kJAMinecraftSchematicChunkSize
};


@interface JAMinecraftSchematicChunk: NSObject
{
@private
	JACircuitExtents			_extents;
	BOOL						_extentsAreAccurate;
	
	JAMinecraftCell				_cells[kJAMinecraftSchematicCellsPerChunk];
}

/*	Extents of non-empty space within chunk.
	If the entire chunk is empty, kJAEmptyExtents.
*/
@property (readonly, nonatomic) JACircuitExtents extents;

#ifndef NDEBUG
@property (copy) NSString *label;
#endif

/*	Unlike the JAMinecraftSchematic equivalents, these will cause an assertion/
	undefined behaviour for out-of-bounds indices.
*/
- (JAMinecraftCell) chunkCellAtX:(NSInteger)x y:(NSInteger)y z:(NSInteger)z;
- (void) setChunkCell:(JAMinecraftCell)cell atX:(NSInteger)x y:(NSInteger)y z:(NSInteger)z;

@end
