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
#import "JAValueToString.h"


#define LOGGING		(0 && !defined(NDEBUG))

#if LOGGING
#define LOG NSLog
#else
#define LOG(...)  do {} while (0)
#endif


enum
{
	kJAMinecraftSchematicChunkSize		= 8,
	kJAMinecraftSchematicCellsPerChunk	= kJAMinecraftSchematicChunkSize * kJAMinecraftSchematicChunkSize * kJAMinecraftSchematicChunkSize
};


NSString * const kJAMinecraftSchematicErrorDomain			= @"se.ayton.jens JAMinecraftSchematic ErrorDomain";


typedef struct
{
	NSUInteger						innerNodeCount;
	NSUInteger						leafNodeCount;
	NSUInteger						deepestLevel;
} DumpStatistics;


#if OLD_CHUNKS
typedef BOOL (^JAMinecraftSchematicChunkIterator)(JAMinecraftSchematicChunk *chunk, MCGridCoordinates base);


/*
	The schematic is organized as an octree _rootLevel levels deep. Completely
	empty areas are represented as nil children. Leaf nodes are
	JAMinecraftSchematicChunks; inner nodes are JAMinecraftSchematicInnerNodes.
	
	JAMinecraftSchematicInnerNode is essentially a struct, but implemented as a
	class for uniformity and garabage collection.
*/
@interface JAMinecraftSchematicInnerNode: NSObject
{
@public
	__strong id						children[8];
}

#if LOGGING
- (void) dumpStructureWithLevel:(NSUInteger)level
					 statistics:(DumpStatistics *)stats
						   base:(MCGridCoordinates)base
						   size:(NSUInteger)size;
#endif

- (BOOL) forEachChunkWithBase:(MCGridCoordinates)base size:(NSInteger)size perform:(JAMinecraftSchematicChunkIterator)iterator bounds:(MCGridExtents)bounds;

@end
#else
typedef struct InnerNode InnerNode;
typedef struct Chunk Chunk;
struct InnerNode
{
	NSUInteger					refCount;
#ifndef NDEBUG
	NSUInteger					level;	// For sanity checking.
#endif
	
	union
	{
		InnerNode				*inner[8];
		Chunk					*leaves[8];
	}							children;
};

struct Chunk
{
	uint16_t					refCount;
	
	BOOL						extentsAreAccurate;
	MCGridExtents				extents;
	MCCell						cells[kJAMinecraftSchematicCellsPerChunk];
};


static inline InnerNode *AllocInnerNode(NSUInteger level);
static inline Chunk *AllocChunk(void);

// Copy-on-write.
static InnerNode *COWInnerNode(InnerNode *node, NSUInteger level);
static Chunk *COWChunk(Chunk *chunk);

// Immediate copy, COWing children as necessary.
static InnerNode *CopyInnerNode(InnerNode *node, NSUInteger level);
static Chunk *CopyChunk(Chunk *chunk);

static void ReleaseInnerNode(InnerNode *node, NSUInteger level);
static void ReleaseChunk(Chunk *chunk);

static MCGridExtents ChunkGetExtents(Chunk *chunk);
static MCCell ChunkGetCell(Chunk *chunk, NSInteger x, NSInteger y, NSInteger z);
static BOOL ChunkSetCell(Chunk *chunk, NSInteger x, NSInteger y, NSInteger z, MCCell cell);	// Returns true if cell is changed.


typedef BOOL (^JAMinecraftSchematicChunkIterator)(Chunk *chunk, MCGridCoordinates base);
#endif


@interface JAMinecraftSchematic ()
{
@private
	MCGridExtents					_extents;
#if OLD_CHUNKS
	JAMinecraftSchematicInnerNode	*_root;
#else
	InnerNode						*_root;
#endif
	BOOL							_extentsAreAccurate;
	uint8_t							_rootLevel;
}

//	Space spanned by octree, regardless of "fullness" of cells.
@property (readonly) MCGridExtents totalExtents;

/*	Find appropriate chunk for "location" in octree.
	"base" is set to coordinates of chunk's 0, 0, 0 if a chunk is returned,
	otherwise untouched.
	If "createIfNeeded" is YES, the chunk and any intermediate nodes will be
	created if they aren't there already.
*/
#if OLD_CHUNKS
- (JAMinecraftSchematicChunk *) resolveChunkAt:(MCGridCoordinates)location
							   baseCoordinates:(MCGridCoordinates *)base
								createIfNeeded:(BOOL)createIfNeeded;
#else
- (Chunk *) resolveChunkAt:(MCGridCoordinates)location
		   baseCoordinates:(MCGridCoordinates *)base
			createIfNeeded:(BOOL)createIfNeeded
			 makeWriteable:(BOOL)makeWriteable;
#endif

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
		_rootLevel = 1;
#if OLD_CHUNKS
		_root = [JAMinecraftSchematicInnerNode new];
#else
		_root = AllocInnerNode(_rootLevel);
#endif
		LOG(@"Creating root inner node %p", _root);
		
		_extents = kMCEmptyExtents;
		_extentsAreAccurate = YES;
		
#if LOGGING
		[self dumpStructure];
#endif
	}
	
	return self;
}


#if !OLD_CHUNKS
- (void) finalize
{
	InnerNode *root = _root;
	NSUInteger level = _rootLevel;
	dispatch_async(dispatch_get_main_queue(), ^{ ReleaseInnerNode(root, level); });
}
#endif


- (id) copyWithZone:(NSZone *)zone
{
	JAMinecraftSchematic *copy = [[[self class] alloc] init];
	if (copy != nil)
	{
		ReleaseInnerNode(copy->_root, copy->_rootLevel);
		
		// For simplicity, root node is always unique.
		copy->_root = CopyInnerNode(_root, _rootLevel);
		copy->_rootLevel = _rootLevel;
		
		copy->_extents = _extents;
		copy->_extentsAreAccurate = _extentsAreAccurate;
	}
	
	return copy;
}


- (MCCell) cellAt:(MCGridCoordinates)location
{
#if OLD_CHUNKS
	MCGridCoordinates base;
	JAMinecraftSchematicChunk *chunk = [self resolveChunkAt:location
											baseCoordinates:&base
											 createIfNeeded:NO];
	
	if (chunk == nil)  return kJAEmptyCell;
	
	return [chunk chunkCellAtX:location.x - base.x y:location.y - base.y z:location.z - base.z];
#else
	MCGridCoordinates base;
	Chunk *chunk = [self resolveChunkAt:location
						baseCoordinates:&base
						 createIfNeeded:NO
						  makeWriteable:NO];
	if (chunk == NULL)  return kJAEmptyCell;
	
	return ChunkGetCell(chunk, location.x - base.x, location.y - base.y, location.z - base.z);
#endif
}


- (void) setCell:(MCCell)cell at:(MCGridCoordinates)location
{
#if OLD_CHUNKS
	MCGridCoordinates base;
	JAMinecraftSchematicChunk *chunk = [self resolveChunkAt:location
											baseCoordinates:&base
											 createIfNeeded:!MCCellIsAir(cell)];
	
	if (chunk != nil)
	{
		BOOL changeAffectsExtents = YES;
		if (changeAffectsExtents)  [self willChangeValueForKey:@"extents"];
		
		[chunk setChunkCell:cell atX:location.x - base.x y:location.y - base.y z:location.z - base.z];
		
		if (changeAffectsExtents)
		{
			_extentsAreAccurate = NO;
			[self didChangeValueForKey:@"extents"];
		}
		
		[self noteChangeInLocation:location];
	}
#else
	MCGridCoordinates base;
	Chunk *chunk = [self resolveChunkAt:location
						baseCoordinates:&base
						 createIfNeeded:!MCCellIsAir(cell)
						  makeWriteable:YES];
	
	BOOL changed = NO;
	if (chunk != nil)
	{
		BOOL changeAffectsExtents = YES;	// FIXME: smartness
		
		changed = ChunkSetCell(chunk, location.x - base.x, location.y - base.y, location.z - base.z, cell);
		
		if (changeAffectsExtents && changed)
		{
			[self willChangeValueForKey:@"extents"];
			_extentsAreAccurate = NO;
			[self didChangeValueForKey:@"extents"];
		}
	}
	[self noteChangeInLocation:location];
#endif
}


- (void) copyRegion:(MCGridExtents)region from:(JAMinecraftSchematic *)sourceCircuit at:(MCGridCoordinates)location
{
#if OLD_CHUNKS
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
#else
	[NSException raise:NSGenericException format:@"Need to reimplement %s", __FUNCTION__];
#endif
}


- (MCGridExtents) extents
{
	if (!_extentsAreAccurate)
	{
		__block MCGridExtents result = kMCEmptyExtents;
		
#if OLD_CHUNKS
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
#else
		[self forEachChunkDo:^(Chunk *chunk, MCGridCoordinates base) {
			MCGridExtents chunkExtents = ChunkGetExtents(chunk);
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
#endif
		
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
	NSInteger distance = (1 << (_rootLevel - 1)) * kJAMinecraftSchematicChunkSize;
	NSInteger max = distance - 1;
	NSInteger min = -distance;
	
	return (MCGridExtents) { min, max, min, max, min, max };
}


#if OLD_CHUNKS
- (JAMinecraftSchematicChunk *) resolveChunkAt:(MCGridCoordinates)location
							   baseCoordinates:(MCGridCoordinates *)base
								createIfNeeded:(BOOL)createIfNeeded
{
	NSUInteger maxDistance = MAX(ABS(location.x), MAX(ABS(location.y), ABS(location.z)));
	
//	LOG(@"Resolving %@", JA_ENCODE(location));
	
	NSUInteger repDistance = RepresentedDistance(_rootLevel);
	if (repDistance <= maxDistance)
	{
		if (!createIfNeeded)  return nil;
		
		do
		{
			[self growOctree];
			repDistance = RepresentedDistance(_rootLevel);
		} while (repDistance <= maxDistance);
	}
	
	NSInteger baseX = -repDistance, baseY = -repDistance, baseZ = -repDistance;
	NSUInteger size = repDistance * 2;
	
	JAMinecraftSchematicInnerNode *node = _root;
	NSUInteger levels = _rootLevel;
	
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
#else
- (Chunk *) resolveChunkAt:(MCGridCoordinates)location
		   baseCoordinates:(MCGridCoordinates *)base
			createIfNeeded:(BOOL)createIfNeeded
			 makeWriteable:(BOOL)makeWriteable
{
	// maxDistance: how far out we are from the origin along the longest axis.
	NSUInteger maxDistance = MAX(ABS(location.x), MAX(ABS(location.y), ABS(location.z)));
	
	// repDistance: how far out we can represent with the current octree shape.
	NSUInteger repDistance = RepresentedDistance(_rootLevel);
	
	// If block is out of range, we need to grow until it isn’t.
	if (repDistance <= maxDistance)
	{
		if (!createIfNeeded)  return nil;
		
		do
		{
			[self growOctree];
			repDistance = RepresentedDistance(_rootLevel);
		} while (repDistance <= maxDistance);
	}
	
	// Base[XYZ] and size define the coordinate range represented by the node under consideration.
	NSInteger baseX = -repDistance, baseY = -repDistance, baseZ = -repDistance;
	NSUInteger size = repDistance * 2;
	
	InnerNode *node = _root;
	NSUInteger level = _rootLevel;
	
	unsigned nextIndex;
	
	// Descend the subtree until we reach a chunk, or (if !createIfNeeded) we reach NULL, representing empty space.
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
		
		if (--level == 0)
		{
			NSAssert1(size == kJAMinecraftSchematicChunkSize, @"Subdivision logic failure: size is %lu", size);
			break;
		}
		
		InnerNode *child = node->children.inner[nextIndex];
		if (child == NULL)
		{
			if (!createIfNeeded)  return NULL;
			child = AllocInnerNode(level);
			LOG(@"Creating inner node %p at (%li, %li, %li)", child, baseX, baseY, baseZ);
			if (child == nil)  [NSException raise:NSMallocException format:@"Out of memory"];
			node->children.inner[nextIndex] = child;
		}
		if (makeWriteable && child->refCount > 1)
		{
			InnerNode *newChild = CopyInnerNode(child, level);
			LOG(@"Copying inner node %p to %p at (%li, %li, %li)", child, newChild, baseX, baseY, baseZ);
			ReleaseInnerNode(child, level);
			child = newChild;
			node->children.inner[nextIndex] = child;
		}
		node = child;
	}
	
	Chunk *chunk = node->children.leaves[nextIndex];
	if (chunk == NULL)
	{
		if (!createIfNeeded)  return NULL;
		chunk = AllocChunk();
		LOG(@"Creating chunk %p at (%li, %li, %li)", chunk, baseX, baseY, baseZ);
		
		if (chunk == nil)  [NSException raise:NSMallocException format:@"Out of memory"];
		node->children.leaves[nextIndex] = chunk;
	}
	else if (makeWriteable && chunk->refCount > 1)
	{
		Chunk *newChunk = CopyChunk(chunk);
		LOG(@"Copying chunk %p to %p at (%li, %li, %li)", chunk, newChunk, baseX, baseY, baseZ);
		ReleaseChunk(chunk);
		chunk = newChunk;
		node->children.leaves[nextIndex] = chunk;
	}
	
	if (base != NULL)
	{
		base->x = baseX;
		base->y = baseY;
		base->z = baseZ;
	}
	return chunk;
}
#endif


- (void) growOctree
{
	[self willChangeValueForKey:@"totalExtents"];
	
#if OLD_CHUNKS
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
	_rootLevel++;
#else
	LOG(@"Growing octree from level %u to level %u", _rootLevel, _rootLevel + 1);
	
	InnerNode *newRoot = AllocInnerNode(_rootLevel + 1);
	if (newRoot == NULL)  [NSException raise:NSMallocException format:@"Out of memory"];
	LOG(@"Creating root inner node %p [level %lu]", newRoot, newRoot->level);
	
	InnerNode *oldRoot = _root;
	
	for (unsigned i = 0; i < 8; i++)
	{
		if (oldRoot->children.inner[i] != nil)
		{
			InnerNode *intermediate = AllocInnerNode(_rootLevel);
			LOG(@"Creating intermediate inner node %p [level %lu]", intermediate, intermediate->level);
			if (intermediate == NULL)  [NSException raise:NSMallocException format:@"Out of memory"];
			
			if (_rootLevel > 1)  intermediate->children.inner[i ^ 7] = COWInnerNode(_root->children.inner[i], _rootLevel - 1);
			else  intermediate->children.leaves[i ^ 7] = COWChunk(_root->children.leaves[i]);
			
			newRoot->children.inner[i] = intermediate;
		}
	}
	ReleaseInnerNode(_root, _rootLevel);
	_root = newRoot;
	_rootLevel++;
#endif
	
	[self didChangeValueForKey:@"totalExtents"];
	
#if LOGGING
	MCGridExtents totalExtents = [self totalExtents];
	LOG(@"Grew octree to level %u, encompassing %@", _rootLevel, JA_ENCODE(totalExtents));
	[self dumpStructure];
#endif
}


#if LOGGING
- (void) dumpStructure
{
#if OLD_CHUNKS
	DumpStatistics stats = {0};
	MCGridExtents totalExtents = self.totalExtents;
	MCGridCoordinates base = { totalExtents.minX, totalExtents.minY, totalExtents.minZ };
	NSUInteger size = totalExtents.maxX - totalExtents.minX + 1;
	
	LOG(@"{");
	[_root dumpStructureWithLevel:0 statistics:&stats base:base size:size];
	
	NSUInteger maxInnerNodes = 0;
	NSUInteger maxLeafNodes = 1;
	for (NSUInteger i = 0; i < _rootLevel; i++)
	{
		maxInnerNodes += maxLeafNodes;
		maxLeafNodes *= 8;
	}
	
	LOG(@"Levels: %u. Inner nodes: %lu of %lu (%.2f %%). Leaf nodes: %lu of %lu (%.2f %%).", _rootLevel, stats.innerNodeCount, maxInnerNodes, (float)stats.innerNodeCount / maxInnerNodes * 100.0f, stats.leafNodeCount, maxLeafNodes, (float)stats.leafNodeCount / maxLeafNodes* 100.0f);
#endif
}
#endif


#if OLD_CHUNKS
#else
static BOOL ForEachChunk(InnerNode *node, MCGridCoordinates base, NSUInteger size, NSUInteger level, MCGridExtents bounds, JAMinecraftSchematicChunkIterator iterator, BOOL makeWriteable)
{
	NSCParameterAssert(node != NULL);
	
	if (level == 0)
	{
		Chunk *chunk = (Chunk *)node;
		return iterator(chunk, base);
	}
	
	NSInteger halfSize = size >> 1;
	
	for (NSUInteger i = 0; i < 8; i++)
	{
		InnerNode *child = node->children.inner[i];
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
				if (makeWriteable && child->refCount > 1)
				{
					if (level > 1)
					{
						InnerNode *newChild = CopyInnerNode(child, level);
						ReleaseInnerNode(child, level);
						child = newChild;
					}
					else
					{
						Chunk *newChunk = CopyChunk((Chunk *)child);
						ReleaseChunk((Chunk *)child);
						child = (InnerNode *)newChunk;
					}
					
					node->children.inner[i] = child;
				}
				
				BOOL result = ForEachChunk(child, subBase, halfSize, level - 1, bounds, iterator, makeWriteable);
				if (!result)  return NO;
			}
		}
	}
	
	return YES;
}
#endif


- (BOOL) forEachChunkInRegion:(MCGridExtents)bounds do:(JAMinecraftSchematicChunkIterator)iterator
{
	MCGridExtents totalExtents = self.totalExtents;
	MCGridCoordinates base = { totalExtents.minX, totalExtents.minY, totalExtents.minZ };
	NSUInteger size = totalExtents.maxX - totalExtents.minX + 1;
	
#if OLD_CHUNKS
	return [_root forEachChunkWithBase:base size:size perform:iterator bounds:bounds];
#else
	return ForEachChunk(_root, base, size, _rootLevel, bounds, iterator, NO);
#endif
}


- (BOOL) forEachChunkDo:(JAMinecraftSchematicChunkIterator)iterator
{
	return [self forEachChunkInRegion:kMCInfiniteExtents do:iterator];
}

@end


#if OLD_CHUNKS
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
#endif


static inline InnerNode *AllocInnerNode(NSUInteger level)
{
	InnerNode *result = calloc(sizeof(InnerNode), 1);
	result->refCount = 1;
#ifndef NDEBUG
	result->level = level;
#endif
	return result;
}


static inline Chunk *AllocChunk(void)
{
	Chunk *result = calloc(sizeof(Chunk), 1);
	result->refCount = 1;
	result->extents = kMCEmptyExtents;
	result->extentsAreAccurate = YES;
	return result;
}


static inline void FreeInnerNode(InnerNode *node, NSUInteger level)
{
	NSCParameterAssert(node != NULL && node->level == level);
	LOG(@"Freeing inner node %p [level %lu]", node, node->level);
	
	for (unsigned i = 0; i < 8; i++)
	{
		if (node->children.inner[i] != NULL)
		{
			if (level > 1)  ReleaseInnerNode(node->children.inner[i], level - 1);
			else  ReleaseChunk(node->children.leaves[i]);
		}
	}
	free(node);
}


static inline void FreeChunk(Chunk *chunk)
{
	LOG(@"Freeing chunk %p", chunk);
	free(chunk);
}


static InnerNode *COWInnerNode(InnerNode *node, NSUInteger level)
{
	NSCParameterAssert(node != NULL && level == node->level);
	node->refCount++;
	return node;
}


static Chunk *COWChunk(Chunk *chunk)
{
	NSCParameterAssert(chunk != NULL);
	if (JA_EXPECT(chunk->refCount < (INT16_MAX - 1)))
	{
		chunk->refCount++;
		return chunk;
	}
	else
	{
		return CopyChunk(chunk);
	}
}


static InnerNode *CopyInnerNode(InnerNode *node, NSUInteger level)
{
	NSCParameterAssert(node != NULL && level == node->level);
	
	InnerNode *result = AllocInnerNode(level);
	if (JA_EXPECT_NOT(result == NULL))  return NULL;
	
	result->refCount = 1;
#ifndef NDEBUG
	result->level = node->level;
#endif
	
	for (unsigned i = 0; i < 8; i++)
	{
		if (node->children.inner[i] != NULL)
		{
			if (level > 1)  result->children.inner[i] = COWInnerNode(node->children.inner[i], level - 1);
			else  result->children.leaves[i] = COWChunk(node->children.leaves[i]);
		}
	}
	
	return result;
}


static Chunk *CopyChunk(Chunk *chunk)
{
	NSCParameterAssert(chunk != NULL);
	
	Chunk *result = AllocChunk();
	if (JA_EXPECT_NOT(result == NULL))  return NULL;
	
	bcopy(chunk, result, sizeof *result);
	result->refCount = 1;
	return result;
}


static void ReleaseInnerNode(InnerNode *node, NSUInteger level)
{
	NSCParameterAssert(node != NULL);
	if (--node->refCount == 0)
	{
		FreeInnerNode(node, level);
	}
}


static void ReleaseChunk(Chunk *chunk)
{
	NSCParameterAssert(chunk != NULL);
	if (--chunk->refCount == 0)
	{
		FreeChunk(chunk);
	}
}


static inline unsigned Offset(unsigned x, unsigned y, unsigned z)  __attribute__((const, always_inline));
static inline unsigned Offset(unsigned x, unsigned y, unsigned z)
{
	return (z * kJAMinecraftSchematicChunkSize + y) * kJAMinecraftSchematicChunkSize + x;
}


static MCGridExtents ChunkGetExtents(Chunk *chunk)
{
	NSCParameterAssert(chunk != NULL);
	
	if (!chunk->extentsAreAccurate)
	{
		// Examine blocks to find extents.
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
					if (!MCCellIsAir(chunk->cells[Offset(x, y, z)]))
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
		
		if (minX != UINT_MAX)  chunk->extents = (MCGridExtents){ minX, maxX, minY, maxY, minZ, maxZ };
		else  chunk->extents = kMCEmptyExtents;
		chunk->extentsAreAccurate = YES;
	}
	
	return chunk->extents;
}


static MCCell ChunkGetCell(Chunk *chunk, NSInteger x, NSInteger y, NSInteger z)
{
	NSCParameterAssert(chunk != NULL &&
					   0 <= x && x < kJAMinecraftSchematicChunkSize &&
					   0 <= y && y < kJAMinecraftSchematicChunkSize &&
					   0 <= z && z < kJAMinecraftSchematicChunkSize);
	
	return chunk->cells[Offset(x, y, z)];
}


static BOOL ChunkSetCell(Chunk *chunk, NSInteger x, NSInteger y, NSInteger z, MCCell cell)
{
	NSCParameterAssert(chunk != NULL &&
					   0 <= x && x < kJAMinecraftSchematicChunkSize &&
					   0 <= y && y < kJAMinecraftSchematicChunkSize &&
					   0 <= z && z < kJAMinecraftSchematicChunkSize);
	
	unsigned offset = Offset(x, y, z);
	if (MCCellsEqual(chunk->cells[offset], cell))  return NO;
	
	chunk->cells[offset] = cell;
	chunk->extentsAreAccurate = NO;
	return YES;
}
