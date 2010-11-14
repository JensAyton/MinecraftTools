/*
	JAMinecraftSchematic.m
	
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

#import "JAMinecraftSchematic.h"
#import	"JAMinecraftSchematicChunk.h"
#import "JAValueToString.h"


#define LOGGING 0

#if LOGGING
#define LOG NSLog
#else
#define LOG(...)  do {} while (0)
#endif


NSString * const kJAMinecraftSchematicErrorDomain			= @"se.ayton.jens JAMinecraftSchematic ErrorDomain";


typedef struct
{
	NSUInteger				innerNodeCount;
	NSUInteger				leafNodeCount;
	NSUInteger				deepestLevel;
} DumpStatistics;


typedef BOOL (^JAMinecraftSchematicChunkIterator)(JAMinecraftSchematicChunk *chunk, MCGridCoordinates base);


/*
	The schematic is organized as an octree _levels levels deep. Completely
	empty areas are represented as nil children. Leaf nodes are
	JAMinecraftSchematicChunks; inner nodes are JAMinecraftSchematicInnerNodes.
	
	JAMinecraftSchematicInnerNode is essentially a struct, but implemented as a
	class for uniformity and garabage collection.
*/
@interface JAMinecraftSchematicInnerNode: NSObject
{
@public
	__strong id					children[8];
}

#if LOGGING
- (void) dumpStructureWithLevel:(NSUInteger)level
					 statistics:(DumpStatistics *)stats
						   base:(MCGridCoordinates)base
						   size:(NSUInteger)size;
#endif

- (BOOL) forEachChunkWithBase:(MCGridCoordinates)base size:(NSInteger)size perform:(JAMinecraftSchematicChunkIterator)iterator bounds:(MCGridExtents)bounds;

@end


@interface JAMinecraftSchematic ()
{
@private
	MCGridExtents					_extents;
	JAMinecraftSchematicInnerNode	*_root;
	BOOL							_extentsAreAccurate;
	uint8_t							_levels;
}

//	Space spanned by octree, regardless of "fullness" of cells.
@property (readonly) MCGridExtents totalExtents;

/*	Find appropriate chunk for "location" in octree.
	"base" is set to coordinates of chunk's 0, 0, 0 if a chunk is returned,
	otherwise untouched.
	If "createIfNeeded" is YES, the chunk and any intermediate nodes will be
	created if they aren't there already.
*/
- (JAMinecraftSchematicChunk *) resolveChunkAt:(MCGridCoordinates)location
							   baseCoordinates:(MCGridCoordinates *)base
								createIfNeeded:(BOOL)createIfNeeded;

- (void) growOctree;

#if LOGGING
- (void) dumpStructure;
#endif

/*	Call the specified block for each non-empty chunk.
	To abort iteration, return NO. To continue, return YES.
	The return value of the last invocation is returned.
	The order of iteration is not specified.
 */
- (BOOL) forEachChunkInRegion:(MCGridExtents)bounds do:(JAMinecraftSchematicChunkIterator)iterator;
- (BOOL) forEachChunkDo:(JAMinecraftSchematicChunkIterator)iterator;

@end


static inline NSUInteger RepresentedDistance(levels)
{
	return (1 << (levels - 1)) * kJAMinecraftSchematicChunkSize;
}


@implementation JAMinecraftSchematic

- (id) init
{
	if ((self = [super init]))
	{
		// One level, initially with nil children.
		_root = [JAMinecraftSchematicInnerNode new];
		LOG(@"Creating root inner node %p", _root);
		_levels = 1;
		
		_extents = kMCEmptyExtents;
		_extentsAreAccurate = YES;
		
#if LOGGING
		[self dumpStructure];
#endif
	}
	
	return self;
}


- (MCCell) cellAt:(MCGridCoordinates)location
{
	MCGridCoordinates base;
	JAMinecraftSchematicChunk *chunk = [self resolveChunkAt:location
											baseCoordinates:&base
											 createIfNeeded:NO];
	
	if (chunk == nil)  return kJAEmptyCell;
	
	return [chunk chunkCellAtX:location.x - base.x y:location.y - base.y z:location.z - base.z];
}


- (void) setCell:(MCCell)cell at:(MCGridCoordinates)location
{
	MCGridCoordinates base;
	JAMinecraftSchematicChunk *chunk = [self resolveChunkAt:location
											baseCoordinates:&base
											 createIfNeeded:!MCCellIsAir(cell)];
	
	if (chunk != nil)
	{
		BOOL changeInExtents = MCGridLocationIsWithinExtents(location, _extents);
		BOOL changeAffectsExtents = (MCCellIsAir(cell) == changeInExtents) || !_extentsAreAccurate;
		
		changeAffectsExtents = YES;
		
		if (changeAffectsExtents)  [self willChangeValueForKey:@"extents"];
		
		[chunk setChunkCell:cell atX:location.x - base.x y:location.y - base.y z:location.z - base.z];
		
		if (changeAffectsExtents)
		{
			_extentsAreAccurate = NO;
			[self didChangeValueForKey:@"extents"];
		}
		
		[self noteChangeInLocation:location];
	}
}


- (void) copyRegion:(MCGridExtents)region from:(JAMinecraftSchematic *)sourceCircuit at:(MCGridCoordinates)location
{
	if (MCGridExtentsEmpty(region))  return;
	
	MCGridCoordinates offset = { location.x - region.minX, location.y - region.minY, location.z - region.minZ };
	
	[sourceCircuit forEachChunkInRegion:region do:^(JAMinecraftSchematicChunk *chunk, MCGridCoordinates base)
	{
		NSUInteger bx, by, bz;
		MCGridCoordinates loc;
		
		for (bz = 0; bz < kJAMinecraftSchematicChunkSize; bz++)
		{
			loc.z = base.z + bz;
			for (by = 0; by < kJAMinecraftSchematicChunkSize; by++)
			{
				loc.y = base.y + by;
				for (bx = 0; bx < kJAMinecraftSchematicChunkSize; bx++)
				{
					loc.x = base.x + bx;
					
					if (MCGridLocationIsWithinExtents(loc, region))
					{
						MCCell cell = [sourceCircuit cellAt:loc];
						if (cell.blockID != kMCBlockAir)
						{
							MCGridCoordinates dstloc = { loc.x + offset.x, loc.y + offset.y, loc.z + offset.z };
							[self setCell:cell at:dstloc];
						}
					}
				}
			}
		}
		
		return YES;
	}];
}


- (MCGridExtents) extents
{
	if (!_extentsAreAccurate)
	{
		__block MCGridExtents result = kMCEmptyExtents;
		
		[self forEachChunkDo:^(JAMinecraftSchematicChunk *chunk, MCGridCoordinates base) {
			MCGridExtents chunkExtents = chunk.extents;
			if (!MCGridExtentsEmpty(chunkExtents))
			{
				result.minX = MIN(result.minX, chunkExtents.minX + base.x);
				result.maxX = MAX(result.maxX, chunkExtents.maxX + base.x);
				result.minY = MIN(result.minY, chunkExtents.minY + base.y);
				result.maxY = MAX(result.maxY, chunkExtents.maxY + base.y);
				result.minZ = MIN(result.minZ, chunkExtents.minZ + base.z);
				result.maxZ = MAX(result.maxZ, chunkExtents.maxZ + base.z);
			}
			
			return YES;
		}];
		
		_extents = result;
		_extentsAreAccurate = YES;
	}
	
	return _extents;
}


- (NSInteger) minimumLayer
{
	MCGridExtents extents = self.extents;
	if (MCGridExtentsEmpty(extents))  return NSIntegerMin;
	if (self.extents.maxY < NSIntegerMin + kMCBlockStoreMaximumPermittedHeight)  return NSIntegerMin;
	return self.extents.maxY - kMCBlockStoreMaximumPermittedHeight + 1;
}


+ (NSSet *) keyPathsForValuesAffectingMinimumLayer
{
	return [NSSet setWithObject:@"extents"];
}


- (NSInteger) maximumLayer
{
	MCGridExtents extents = self.extents;
	if (MCGridExtentsEmpty(extents))  return NSIntegerMax;
	if (self.extents.minY > NSIntegerMax - kMCBlockStoreMaximumPermittedHeight)  return NSIntegerMax;
	return self.extents.minY + kMCBlockStoreMaximumPermittedHeight - 1;
}


+ (NSSet *) keyPathsForValuesAffectingMaximumLayer
{
	return [NSSet setWithObject:@"extents"];
}


- (MCGridExtents) totalExtents
{
	NSInteger distance = (1 << (_levels - 1)) * kJAMinecraftSchematicChunkSize;
	NSInteger max = distance - 1;
	NSInteger min = -distance;
	
	return (MCGridExtents) { min, max, min, max, min, max };
}


- (JAMinecraftSchematicChunk *) resolveChunkAt:(MCGridCoordinates)location
							   baseCoordinates:(MCGridCoordinates *)base
								createIfNeeded:(BOOL)createIfNeeded
{
	NSUInteger maxDistance = MAX(ABS(location.x), MAX(ABS(location.y), ABS(location.z)));
	
//	LOG(@"Resolving %@", JA_ENCODE(location));
	
	NSUInteger repDistance = RepresentedDistance(_levels);
	if (repDistance <= maxDistance)
	{
		if (!createIfNeeded)  return nil;
		
		do
		{
			[self growOctree];
			repDistance = RepresentedDistance(_levels);
		} while (repDistance <= maxDistance);
	}
	
	NSInteger baseX = -repDistance, baseY = -repDistance, baseZ = -repDistance;
	NSUInteger size = repDistance * 2;
	
	JAMinecraftSchematicInnerNode *node = _root;
	NSUInteger levels = _levels;
	
	unsigned nextIndex;
	
	for (;;)
	{
		nextIndex = 0;
		NSInteger halfSize = size >> 1;
		
		if (location.x >= baseX + halfSize)
		{
			baseX += halfSize;
			nextIndex |= 1;
		}
		if (location.y >= baseY + halfSize)
		{
			baseY += halfSize;
			nextIndex |= 2;
		}
		if (location.z >= baseZ + halfSize)
		{
			baseZ += halfSize;
			nextIndex |= 4;
		}
		
		size = halfSize;
		
		if (--levels == 0)
		{
			NSAssert1(size == kJAMinecraftSchematicChunkSize, @"Subdivision logic failure: size is %lu", size);
			break;
		}
		
		JAMinecraftSchematicInnerNode *child = node->children[nextIndex];
		if (child == nil)
		{
			if (!createIfNeeded)  return nil;
			child = [JAMinecraftSchematicInnerNode new];
			LOG(@"Creating inner node %p at (%li, %li, %li)", child, baseX, baseY, baseZ);
			if (child == nil)  [NSException raise:NSMallocException format:@"Out of memory"];
			node->children[nextIndex] = child;
		}
		node = child;
	}
	
	JAMinecraftSchematicChunk *chunk = node->children[nextIndex];
	if (chunk == nil)
	{
		if (!createIfNeeded)  return nil;
		chunk = [JAMinecraftSchematicChunk new];
#if LOGGING
#ifndef NDEBUG
		chunk.label = [NSString stringWithFormat:@"(%li, %li, %li)", baseX, baseY, baseZ];
#endif
		LOG(@"Creating chunk %p at (%li, %li, %li)", chunk, baseX, baseY, baseZ);
#endif
		if (chunk == nil)  [NSException raise:NSMallocException format:@"Out of memory"];
		node->children[nextIndex] = chunk;
#if LOGGING
		[self dumpStructure];
#endif
	}
	else
	{
	//	LOG(@"Resolved chunk %p at (%li, %li, %li)", chunk, baseX, baseY, baseZ);
	}

	
	if (base != nil)
	{
		base->x = baseX;
		base->y = baseY;
		base->z = baseZ;
	}
	return chunk;
}


- (void) growOctree
{
	[self willChangeValueForKey:@"totalExtents"];
	
	JAMinecraftSchematicInnerNode *newRoot = [JAMinecraftSchematicInnerNode new];
	if (newRoot == nil)  [NSException raise:NSMallocException format:@"Out of memory"];
	LOG(@"Creating root inner node %p", _root);
	
	for (unsigned i = 0; i < 8; i++)
	{
		if (_root->children[i] != nil)
		{
			JAMinecraftSchematicInnerNode *intermediate = [JAMinecraftSchematicInnerNode new];
			LOG(@"Creating intermediate inner node %p", intermediate);
			if (intermediate == nil)  [NSException raise:NSMallocException format:@"Out of memory"];
			intermediate->children[i ^ 7] = _root->children[i];
			newRoot->children[i] = intermediate;
		}
	}
	
	_root = newRoot;
	_levels++;
	
	[self didChangeValueForKey:@"totalExtents"];
	
#if LOGGING
	MCGridExtents totalExtents = [self totalExtents];
	LOG(@"Growing octree to level %u, encompassing %@", _levels, JA_ENCODE(totalExtents));
	[self dumpStructure];
#endif
}


#if LOGGING
- (void) dumpStructure
{
//	return;
	DumpStatistics stats = {0};
	MCGridExtents totalExtents = self.totalExtents;
	MCGridCoordinates base = { totalExtents.minX, totalExtents.minY, totalExtents.minZ };
	NSUInteger size = totalExtents.maxX - totalExtents.minX + 1;
	
	LOG(@"{");
	[_root dumpStructureWithLevel:0 statistics:&stats base:base size:size];
	
	NSUInteger maxInnerNodes = 0;
	NSUInteger maxLeafNodes = 1;
	for (NSUInteger i = 0; i < _levels; i++)
	{
		maxInnerNodes += maxLeafNodes;
		maxLeafNodes *= 8;
	}
	
	LOG(@"Levels: %u. Inner nodes: %lu of %lu (%.2f %%). Leaf nodes: %lu of %lu (%.2f %%).", _levels, stats.innerNodeCount, maxInnerNodes, (float)stats.innerNodeCount / maxInnerNodes * 100.0f, stats.leafNodeCount, maxLeafNodes, (float)stats.leafNodeCount / maxLeafNodes* 100.0f);
}
#endif


- (BOOL) forEachChunkInRegion:(MCGridExtents)bounds do:(JAMinecraftSchematicChunkIterator)iterator
{
	MCGridExtents totalExtents = self.totalExtents;
	MCGridCoordinates base = { totalExtents.minX, totalExtents.minY, totalExtents.minZ };
	NSUInteger size = totalExtents.maxX - totalExtents.minX + 1;
	
	return [_root forEachChunkWithBase:base size:size perform:iterator bounds:bounds];
}


- (BOOL) forEachChunkDo:(JAMinecraftSchematicChunkIterator)iterator
{
	return [self forEachChunkInRegion:kMCInfiniteExtents do:iterator];
}

@end


@implementation JAMinecraftSchematicInnerNode

- (BOOL) forEachChunkWithBase:(MCGridCoordinates)base size:(NSInteger)size perform:(JAMinecraftSchematicChunkIterator)iterator bounds:(MCGridExtents)bounds_
{
	MCGridExtents bounds = bounds_;
	NSInteger halfSize = size >> 1;
	BOOL result = YES;
	
	for (NSUInteger i = 0; i < 8; i++)
	{
		id child = children[i];
		if (child != nil)
		{
			MCGridCoordinates subBase = base;
			if (i & 1) subBase.x += halfSize;
			if (i & 2) subBase.y += halfSize;
			if (i & 4) subBase.z += halfSize;
			
			if (subBase.x <= bounds.maxX && bounds.minX <= (subBase.x + halfSize) &&
				subBase.y <= bounds.maxY && bounds.minY <= (subBase.y + halfSize) &&
				subBase.z <= bounds.maxZ && bounds.minZ <= (subBase.z + halfSize))
			{
				result = [child forEachChunkWithBase:subBase size:halfSize perform:iterator bounds:bounds];
				if (!result)  return NO;
			}
		}
	}
	
	return result;
}


#if LOGGING
- (void) dumpStructureWithLevel:(NSUInteger)level
					 statistics:(DumpStatistics *)stats
						   base:(MCGridCoordinates)base
						   size:(NSUInteger)size
{
	stats->innerNodeCount++;
	stats->deepestLevel = MAX(stats->deepestLevel, level);
	
	NSMutableString *indent = [NSMutableString string];
	for (NSUInteger i = 0; i < level; i++)
	{
		[indent appendString:@"  "];
	}
	
	NSUInteger halfSize = size >> 1;
	
	for (NSUInteger i = 0; i < 8; i++)
	{
		MCGridCoordinates subBase = base;
		if (i & 1) subBase.x += halfSize;
		if (i & 2) subBase.y += halfSize;
		if (i & 4) subBase.z += halfSize;
		
		NSString *prefix = [NSString stringWithFormat:@"%@  %lu %@: ", indent, i, JA_ENCODE(subBase)];
		
		id child = children[i];
		if (child == nil)  LOG(@"%@nil", prefix);
		else if ([child isKindOfClass:[JAMinecraftSchematicInnerNode class]])
		{
			LOG(@"%@{", prefix);
			[child dumpStructureWithLevel:level + 1 statistics:stats base:subBase size:halfSize];
		}
		else
		{
			stats->leafNodeCount++;
			LOG(@"%@%@", prefix, child);
		}
	}
	
	LOG(@"%@}", indent);
}
#endif

@end


@implementation JAMinecraftSchematicChunk (JAMinecraftSchematicExtensions)

- (BOOL) forEachChunkWithBase:(MCGridCoordinates)base size:(NSInteger)size perform:(JAMinecraftSchematicChunkIterator)iterator bounds:(MCGridExtents)bounds
{
	// Caller is responsible for applying bounds.
	return iterator(self, base);
}

@end
