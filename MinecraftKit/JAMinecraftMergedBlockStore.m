//
//  JAMinecraftMergedBlockStore.m
//  RDatViewer
//
//  Created by Jens Ayton on 2010-11-27.
//  Copyright 2010 Jens Ayton. All rights reserved.
//

#import "JAMinecraftMergedBlockStore.h"
#import "JAMinecraftSchematic.h"


@implementation JAMinecraftMergedBlockStore

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


- (MCCell) cellAt:(MCGridCoordinates)coordinates
{
	MCCell cell;
	
	if (MCGridCoordinatesAreWithinExtents(coordinates, _overlayExtents))
	{
		cell = [_overlay cellAtX:coordinates.x - _overlayOffset.x
							   y:coordinates.y - _overlayOffset.y
							   z:coordinates.z - _overlayOffset.z];
		
		if (!MCCellIsHole(cell))  return cell;
	}
	
	return [_mainStore cellAt:coordinates];
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
