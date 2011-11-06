/*
	JAMinecraftMergedBlockStore.m
	
	
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

#import "JAMinecraftMergedBlockStore.h"
#import "JAMinecraftSchematic.h"


@implementation JAMinecraftMergedBlockStore
{
	JAMinecraftBlockStore		*_mainStore;
	JAMinecraftSchematic		*_overlay;
	MCGridCoordinates			_overlayOffset;
	MCGridExtents				_overlayExtents;
}

- (id) initWithMainStore:(JAMinecraftBlockStore *)mainStore
				 overlay:(JAMinecraftSchematic *)overlay
				  offset:(MCGridCoordinates)offset
{
	if ((self = [super init]))
	{
		_mainStore = [mainStore copy];
		_overlay = [overlay copy];
		_overlayOffset = offset;
		_overlayExtents = MCGridExtentsOffset(overlay.extents, offset.x, offset.y, offset.z);
	}
	return self;
}


- (BOOL) isMergedBlockStore
{
	return YES;
}


- (MCGridExtents) extents
{
	return MCGridExtentsUnion(_mainStore.extents, _overlayExtents);
}


- (MCCell) cellAt:(MCGridCoordinates)location gettingTileEntity:(NSDictionary **)outTileEntity
{
	if (MCGridCoordinatesAreWithinExtents(location, _overlayExtents))
	{
		location.x -= _overlayOffset.x;
		location.y -= _overlayOffset.y;
		location.z -= _overlayOffset.z;
		
		MCCell cell = [_overlay cellAt:location gettingTileEntity:outTileEntity];
		if (!MCCellIsHole(cell))  return cell;
		
		if (outTileEntity != NULL)  *outTileEntity = nil;
	}
	
	return [_mainStore cellAt:location gettingTileEntity:outTileEntity];
}


- (NSInteger) minimumLayer
{
	return _mainStore.minimumLayer;
}


- (NSInteger) maximumLayer
{
	return _mainStore.maximumLayer;
}


- (NSInteger) groundLevel
{
	return _mainStore.groundLevel;
}

@end


@implementation JAMinecraftBlockStore (JAMinecraftMergedBlockStore)

- (BOOL) isMergedBlockStore
{
	return NO;
}

@end
