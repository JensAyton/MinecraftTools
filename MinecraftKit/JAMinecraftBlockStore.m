/*
	JAMinecraftBlockStore.m
	
	
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
#import "JAMinecraftBlock.h"


NSString * const kJAMinecraftBlockStoreChangedNotification	= @"se.ayton.jens JAMinecraftBlockStore Changed";
NSString * const kJAMinecraftBlockStoreChangedExtents		= @"kJAMinecraftBlockStoreChangedExtents";

NSString * const kJAMinecraftBlockStoreErrorDomain			= @"se.ayton.jens JAMinecraftBlockStore ErrorDomain";


@interface JAMutableMinecraftBlockStore ()

- (void) postChangeNotification:(MCGridExtents)changedExtents;

@end


static void ThrowSubclassResponsibility(const char *func) __attribute__((noreturn));


@implementation JAMinecraftBlockStore

- (NSInteger) groundLevel
{
	return 0;
}


+ (BOOL) accessInstanceVariablesDirectly
{
	return NO;
}


#pragma mark Subclass responsibilities

- (MCGridExtents) extents
{
	ThrowSubclassResponsibility(__FUNCTION__);
}


- (MCCell) cellAt:(MCGridCoordinates)location gettingTileEntity:(NSDictionary **)outTileEntity
{
	ThrowSubclassResponsibility(__FUNCTION__);
}


- (NSInteger) minimumLayer
{
	ThrowSubclassResponsibility(__FUNCTION__);
}


- (NSInteger) maximumLayer
{
	ThrowSubclassResponsibility(__FUNCTION__);
}

@end


@implementation JAMutableMinecraftBlockStore
{
	NSUInteger						_bulkLevel;
	MCGridExtents					_dirtyExtents;
}

- (id) init
{
	if ((self = [super init]))
	{
		_dirtyExtents = kMCEmptyExtents;
	}
	
	return self;
}


- (void) setCell:(MCCell)cell andTileEntity:(NSDictionary *)tileEntity at:(MCGridCoordinates)location
{
	ThrowSubclassResponsibility(__FUNCTION__);
}

#pragma mark Update tracking

- (void) beginBulkUpdate
{
	_bulkLevel++;
}


- (void) endBulkUpdate
{
	NSAssert1(_bulkLevel != 0, @"%s called when no bulk updates are in progress. Ensure calls are balanced.", __FUNCTION__);
	
	if (--_bulkLevel == 0)
	{
		[self postChangeNotification:_dirtyExtents];
		_dirtyExtents = kMCEmptyExtents;
		
#if LOGGING
		[self dumpStructure];
#endif
	}
}


- (BOOL) bulkUpdateInProgress
{
	return _bulkLevel != 0;
}


#ifndef NDEBUG
- (NSUInteger) bulkUpdateNestingLevel
{
	return _bulkLevel;
}
#endif


- (void) postChangeNotification:(MCGridExtents)changedExtents
{
	if (!MCGridExtentsEmpty(changedExtents))
	{
		NSValue *extentsObj = [NSValue value:&changedExtents withObjCType:@encode(MCGridExtents)];
		[[NSNotificationCenter defaultCenter] postNotificationName:kJAMinecraftBlockStoreChangedNotification
															object:self
														  userInfo:[NSDictionary dictionaryWithObject:extentsObj
																							   forKey:kJAMinecraftBlockStoreChangedExtents]];
	}
}


- (void) noteChangeInExtents:(MCGridExtents)changedExtents
{
	if (_bulkLevel != 0)
	{
		_dirtyExtents = MCGridExtentsUnion(_dirtyExtents, changedExtents);
	}
	else
	{
		[self postChangeNotification:changedExtents];
	}
}


- (void) noteChangeInLocation:(MCGridCoordinates)changedLocation
{
	if (_bulkLevel != 0)
	{
		_dirtyExtents = MCGridExtentsUnionWithCoordinates(_dirtyExtents, changedLocation);
	}
	else
	{
		[self postChangeNotification:MCGridExtentsWithCoordinates(changedLocation)];
	}
}


#pragma mark Edit actions

- (void) fillRegion:(MCGridExtents)region withCell:(MCCell)cell
{
	if (MCGridExtentsEmpty(region))  return;
	
	[self beginBulkUpdate];
	
	MCGridCoordinates location;
	for (location.z = region.minZ; location.z <= region.maxZ; location.z++)
	{
		for (location.y = region.minY; location.y <= region.maxY; location.y++)
		{
			for (location.x = region.minX; location.x <= region.maxX; location.x++)
			{
				[self setCell:cell at:location];
			}
		}	
	}
	
	[self endBulkUpdate];
}


- (void) copyRegion:(MCGridExtents)region from:(JAMinecraftBlockStore *)source at:(MCGridCoordinates)target
{
	if (MCGridExtentsEmpty(region) || source == nil)  return;
	
	MCGridCoordinates offset = { target.x - region.minX, target.y - region.minY, target.z - region.minZ };
	
	[self beginBulkUpdate];
	
	MCGridCoordinates location;
	for (location.z = region.minZ; location.z <= region.maxZ; location.z++)
	{
		for (location.y = region.minY; location.y <= region.maxY; location.y++)
		{
			for (location.x = region.minX; location.x <= region.maxX; location.x++)
			{
				NSDictionary *tileEntity = nil;
				MCCell cell = [source cellAt:location gettingTileEntity:&tileEntity];
				if (!MCCellIsAir(cell))  [self setCell:cell andTileEntity:tileEntity atX:location.x - offset.x y:location.y - offset.y z:location.z - offset.z];
			}
		}	
	}
	
	[self endBulkUpdate];
}

@end


@implementation JAMinecraftBlockStore (Conveniences)

- (NSUInteger) width
{
	return MCGridExtentsWidth(self.extents);
}


+ (NSSet *) keyPathsForValuesAffectingWidth
{
	return [NSSet setWithObject:@"extents"];
}


- (NSUInteger) length
{
	return MCGridExtentsLength(self.extents);
}


+ (NSSet *) keyPathsForValuesAffectingLengh
{
	return [NSSet setWithObject:@"extents"];
}


- (NSUInteger) height
{
	return MCGridExtentsHeight(self.extents);
}


+ (NSSet *) keyPathsForValuesAffectingHeight
{
	return [NSSet setWithObject:@"extents"];
}


- (JAMinecraftBlock *) blockAt:(MCGridCoordinates)location
{
	__autoreleasing NSDictionary *tileEntity = nil;
	MCCell cell = [self cellAt:location gettingTileEntity:&tileEntity];
	return [JAMinecraftBlock blockWithCell:cell tileEntity:tileEntity];
}


- (MCCell) cellAt:(MCGridCoordinates)location
{
	return [self cellAt:location gettingTileEntity:NULL];
}


- (NSDictionary *) tileEntityAt:(MCGridCoordinates)location
{
	NSDictionary *result = nil;
	[self cellAt:location gettingTileEntity:&result];
	return result;
}


- (MCCell) cellAtX:(NSInteger)x y:(NSInteger)y z:(NSInteger)z gettingTileEntity:(NSDictionary **)outTileEntity
{
	return [self cellAt:(MCGridCoordinates){ x, y, z } gettingTileEntity:outTileEntity];
}


- (MCCell) cellAtX:(NSInteger)x y:(NSInteger)y z:(NSInteger)z
{
	return [self cellAt:(MCGridCoordinates){ x, y, z } gettingTileEntity:NULL];
}


- (NSDictionary *) tileEntityAtX:(NSInteger)x y:(NSInteger)y z:(NSInteger)z
{
	NSDictionary *result = nil;
	[self cellAt:(MCGridCoordinates){ x, y, z } gettingTileEntity:&result];
	return result;	
}

@end


@implementation JAMutableMinecraftBlockStore (Conveniences)

- (void) setBlock:(JAMinecraftBlock *)block at:(MCGridCoordinates)location
{
	[self setCell:block.cell andTileEntity:block.tileEntity at:location];
}


- (void) setCell:(MCCell)cell at:(MCGridCoordinates)location
{
	NSDictionary *tileEntity = [self tileEntityAt:location];
	if (tileEntity != nil && !MCTileEntityIsCompatibleWithCell(tileEntity, cell))  tileEntity = nil;
	
	[self setCell:cell andTileEntity:tileEntity at:(MCGridCoordinates)location];
}


- (void) setTileEntity:(NSDictionary *)tileEntity at:(MCGridCoordinates)location
{
	MCCell cell = [self cellAt:location];
	[self setCell:cell andTileEntity:tileEntity at:location];
}


- (void) setCell:(MCCell)cell atX:(NSInteger)x y:(NSInteger)y z:(NSInteger)z
{
	[self setCell:cell at:(MCGridCoordinates){ x, y, z }];
}


- (void) setTileEntity:(NSDictionary *)tileEntity atX:(NSInteger)x y:(NSInteger)y z:(NSInteger)z
{
	[self setTileEntity:tileEntity at:(MCGridCoordinates){ x, y, z, }];
}


- (void) setCell:(MCCell)cell andTileEntity:(NSDictionary *)tileEntity atX:(NSInteger)x y:(NSInteger)y z:(NSInteger)z
{
	[self setCell:cell andTileEntity:tileEntity at:(MCGridCoordinates){ x, y, z }];
}

@end


static void ThrowSubclassResponsibility(const char *func)
{
	[NSException raise:NSInternalInconsistencyException format:@"%s is a subclass responsibility.", func];
	__builtin_unreachable();
}
