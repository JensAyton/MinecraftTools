/*
	JAMinecraftMergedBlockStore.h
	
	A pseudo-store which presents a read-only merged view of two different
	block stores. This will throw an exception if you try to write to it.
	
	
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

@class JAMinecraftSchematic;


@interface JAMinecraftMergedBlockStore: JAMinecraftBlockStore
{
@private
	JAMinecraftBlockStore		*_mainStore;
	JAMinecraftSchematic		*_overlay;
	MCGridCoordinates			_overlayOffset;
	MCGridExtents				_overlayExtents;
}

- (id) initWithMainStore:(JAMinecraftBlockStore <NSCopying> *)mainStore
				 overlay:(JAMinecraftSchematic *)overlay
				  offset:(MCGridCoordinates)offset;

@end


@interface JAMinecraftBlockStore (JAMinecraftMergedBlockStore)

@property (readonly) BOOL isMergedBlockStore;

@end

