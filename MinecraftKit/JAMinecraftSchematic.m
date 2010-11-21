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


// Verbose logging of internal structure changes and reference counting.
#define LOGGING			(0 && !defined(NDEBUG))

// Logging of access cache hit rate.
#define PROFILE_CACHE	0


#if LOGGING
static void Log(NSString *format, ...);
static void LogIndent(void);
static void LogOutdent(void);
#else
#define Log(...)  do {} while (0)
#define LogIndent()  do {} while (0)
#define LogOutdent()  do {} while (0)
#endif


enum
{
	kChunkSize		= 8,
	kJAMinecraftSchematicCellsPerChunk	= kChunkSize * kChunkSize * kChunkSize
};


typedef struct
{
	NSUInteger						innerNodeCount;
	NSUInteger						leafNodeCount;
} DumpStatistics;


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
static Chunk *AllocChunk(void);
static Chunk *MakeChunk(NSInteger baseY, NSInteger groundLevel);	// Create a chunk and fill it with stone or air as appropriate depending on ground level.

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

// Fill a complete cell.
static void FillChunk(Chunk *chunk, MCCell cell);


typedef BOOL (^JAMinecraftSchematicChunkIterator)(Chunk *chunk, MCGridCoordinates base);


@interface JAMinecraftSchematic ()
{
@private
	InnerNode						*_root;
	MCGridExtents					_extents;
	NSInteger						_groundLevel;
	
	BOOL							_extentsAreAccurate;
	uint8_t							_rootLevel;
	
	/*
		Access cache for quicker sequential reads.
		TODO: keep track of path through tree to cached chunk. This will allow
		fast access to adjacent chunks, and use of cache on write (by checking
		for COWed ancestor nodes).
	*/
	BOOL							_cacheIsValid;
	Chunk							*_cachedChunk;
	MCGridCoordinates				_cacheBase;
}

//	Space spanned by octree, regardless of "fullness” of cells.
@property (readonly) MCGridExtents totalExtents;

/*	Find appropriate chunk for “location” in octree.
	“base” is set to coordinates of chunk's 0, 0, 0 if a chunk is returned,
	otherwise untouched.
	If “createIfNeeded” is YES, the chunk and any intermediate nodes will be
	created if they aren't there already.
	If “makeWriteable” is YES, the chunk and all intermediate nodes will be
	copied if they have multiple references, making it safe to write.
*/
- (Chunk *) resolveChunkAt:(MCGridCoordinates)location
		   baseCoordinates:(MCGridCoordinates *)base
			createIfNeeded:(BOOL)createIfNeeded
			 makeWriteable:(BOOL)makeWriteable;

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
	return (1 << (levels - 1)) * kChunkSize;
}


@implementation JAMinecraftSchematic

- (id) init
{
	if ((self = [super init]))
	{
		// One level, initially with nil children.
		_rootLevel = 1;
		_root = AllocInnerNode(_rootLevel);
		Log(@"Creating root inner node %p", _root);
		
		_extents = kMCEmptyExtents;
		_extentsAreAccurate = YES;
	}
	
	return self;
}


- (void) finalize
{
	InnerNode *root = _root;
	if (root != NULL)
	{
		NSUInteger level = _rootLevel;
		dispatch_async(dispatch_get_main_queue(), ^{ ReleaseInnerNode(root, level); });
	}
	
	[super finalize];
}


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
	MCGridCoordinates base;
	Chunk *chunk = [self resolveChunkAt:location
						baseCoordinates:&base
						 createIfNeeded:NO
						  makeWriteable:NO];
	
	if (chunk == NULL)
	{
		if (location.y >= self.groundLevel)  return (MCCell){ kMCBlockAir, 0 };
		else  return (MCCell){ kMCBlockSmoothStone, 0 };
	}
	
	return ChunkGetCell(chunk, location.x - base.x, location.y - base.y, location.z - base.z);
}


- (void) setCell:(MCCell)cell at:(MCGridCoordinates)location
{
	MCGridCoordinates base;
	Chunk *chunk = [self resolveChunkAt:location
						baseCoordinates:&base
						 createIfNeeded:!MCCellIsAir(cell)
						  makeWriteable:YES];
	
	BOOL changed = NO;
	if (chunk != nil)
	{
		NSAssert(chunk->refCount == 1, @"resolveChunkAt:... returned a shared chunk for setCell:at:");
		
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
}


#if 0
/*	FIXME: optimize for filling with air by removing blocks.
	Optimize for other cases by reusing a chunk of completely-filled data to
	replace any nil leaves, and trees of nodes leading to said chunk for
	larger areas.
*/
- (void) fillRegion:(MCGridExtents)region withCell:(MCCell)cell
{
	[super fillRegion:region withCell:cell];
}
#endif


#if 0
- (void) copyRegion:(MCGridExtents)region from:(JAMinecraftBlockStore *)source at:(MCGridCoordinates)location
{
	if (MCGridExtentsEmpty(region))  return;
	
	if ([source isKindOfClass:[JAMinecraftSchematic class]])
	{
		MCGridCoordinates offset = { location.x - region.minX, location.y - region.minY, location.z - region.minZ };
		
		// FIXME: should COW chunks/subtrees if appropriately aligned.
		[source forEachChunkInRegion:region do:^(Chunk *chunk, MCGridCoordinates base)
		{
			NSUInteger bx, by, bz;
			MCGridCoordinates loc;
			
			for (bz = 0; bz < kChunkSize; bz++)
			{
				loc.z = base.z + bz;
				for (by = 0; by < kChunkSize; by++)
				{
					loc.y = base.y + by;
					for (bx = 0; bx < kChunkSize; bx++)
					{
						loc.x = base.x + bx;
						
						if (MCGridCoordinatesAreWithinExtents(loc, region))
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
	else
	{
		[super copyRegion:region from:source at:location];
	}
}
#endif


- (MCGridExtents) extents
{
	if (!_extentsAreAccurate)
	{
		__block MCGridExtents result = kMCEmptyExtents;
		
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


- (NSInteger) groundLevel
{
	return _groundLevel;
}


- (void) setGroundLevel:(NSInteger)value
{
	if (value != _groundLevel)
	{
		MCGridExtents changedRegion =
		{
			NSIntegerMin, NSIntegerMax,
			MIN(value, _groundLevel), MAX(value, _groundLevel),
			NSIntegerMin, NSIntegerMax
		};
		
		_groundLevel = value;
		[self noteChangeInExtents:changedRegion];
	}
}


- (MCGridExtents) totalExtents
{
	NSInteger distance = (1 << (_rootLevel - 1)) * kChunkSize;
	NSInteger max = distance - 1;
	NSInteger min = -distance;
	
	return (MCGridExtents) { min, max, min, max, min, max };
}


- (Chunk *) resolveChunkAt:(MCGridCoordinates)location
		   baseCoordinates:(MCGridCoordinates *)outBase
			createIfNeeded:(BOOL)createIfNeeded
			 makeWriteable:(BOOL)makeWriteable
{
	// Use cache if possible.
	if (!makeWriteable && _cacheIsValid)
	{
		MCGridExtents cacheExtents = (MCGridExtents)
		{
			_cacheBase.x, _cacheBase.x + kChunkSize - 1,
			_cacheBase.y, _cacheBase.y + kChunkSize - 1,
			_cacheBase.z, _cacheBase.z + kChunkSize - 1
		};
		BOOL hit = MCGridCoordinatesAreWithinExtents(location, cacheExtents);
		
#if PROFILE_CACHE
		static NSUInteger cacheAttempts = 0, cacheHits = 0;
		if (hit)  cacheHits++;
		if ((cacheAttempts++ % 100) == 0)
		{
			printf("Cache hits: %lu of %lu (%g %%)\n", cacheHits, cacheAttempts, (float)cacheHits / cacheAttempts * 100.0);
		}
#endif
		
		if (hit)
		{
			if (outBase != NULL)  *outBase = _cacheBase;
			return _cachedChunk;
		}
	}
	
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
			NSAssert1(size == kChunkSize, @"Subdivision logic failure: size is %lu", size);
			break;
		}
		
		InnerNode *child = node->children.inner[nextIndex];
		if (child == NULL)
		{
			if (!createIfNeeded)  return NULL;
			child = AllocInnerNode(level);
			Log(@"Creating inner node %p at (%li, %li, %li)", child, baseX, baseY, baseZ);
			if (child == nil)  [NSException raise:NSMallocException format:@"Out of memory"];
			node->children.inner[nextIndex] = child;
		}
		if (makeWriteable && child->refCount > 1)
		{
			InnerNode *newChild = CopyInnerNode(child, level);
			Log(@"Copying inner node %p to %p at (%li, %li, %li)", child, newChild, baseX, baseY, baseZ);
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
		chunk = MakeChunk(baseY, _groundLevel);
		Log(@"Creating chunk %p at (%li, %li, %li)", chunk, baseX, baseY, baseZ);
		
		if (chunk == nil)  [NSException raise:NSMallocException format:@"Out of memory"];
		node->children.leaves[nextIndex] = chunk;
	}
	else if (makeWriteable && chunk->refCount > 1)
	{
		Chunk *newChunk = CopyChunk(chunk);
		Log(@"Copying chunk %p to %p at (%li, %li, %li)", chunk, newChunk, baseX, baseY, baseZ);
		ReleaseChunk(chunk);
		chunk = newChunk;
		node->children.leaves[nextIndex] = chunk;
	}
	
	MCGridCoordinates base = { baseX, baseY, baseZ };
	
	if (outBase != NULL)
	{
		*outBase = base;
	}
	
	_cacheIsValid = YES;
	_cachedChunk = chunk;
	_cacheBase = base;
	
	return chunk;
}


- (void) growOctree
{
	[self willChangeValueForKey:@"totalExtents"];
	
	Log(@"Growing octree from level %u to level %u", _rootLevel, _rootLevel + 1);
	LogIndent();
	
	InnerNode *newRoot = AllocInnerNode(_rootLevel + 1);
	if (newRoot == NULL)  [NSException raise:NSMallocException format:@"Out of memory"];
	Log(@"Creating root inner node %p [level %lu]", newRoot, newRoot->level);
	
	InnerNode *oldRoot = _root;
	
	for (unsigned i = 0; i < 8; i++)
	{
		if (oldRoot->children.inner[i] != nil)
		{
			InnerNode *intermediate = AllocInnerNode(_rootLevel);
			Log(@"Creating intermediate inner node %p [level %lu]", intermediate, intermediate->level);
			if (intermediate == NULL)  [NSException raise:NSMallocException format:@"Out of memory"];
			
			if (_rootLevel > 1)  intermediate->children.inner[i ^ 7] = COWInnerNode(_root->children.inner[i], _rootLevel - 1);
			else  intermediate->children.leaves[i ^ 7] = COWChunk(_root->children.leaves[i]);
			
			newRoot->children.inner[i] = intermediate;
		}
	}
	ReleaseInnerNode(_root, _rootLevel);
	_root = newRoot;
	_rootLevel++;
	
	[self didChangeValueForKey:@"totalExtents"];
	
#if LOGGING
	MCGridExtents totalExtents = [self totalExtents];
	Log(@"Grew octree to level %u, encompassing %@", _rootLevel, JA_ENCODE(totalExtents));
#endif
	
	LogOutdent();
}


#if LOGGING

static void DumpNodeStructure(InnerNode *node, NSUInteger level, DumpStatistics *stats, MCGridCoordinates base, NSUInteger size)
{
	stats->innerNodeCount++;
	LogIndent();
	
	NSUInteger halfSize = size >> 1;
	if (node->refCount != 1)  Log(@"Node %p [refcount: %lu]", node, node->refCount);
	else  Log(@"Node %p", node);
	
	for (NSUInteger i = 0; i < 8; i++)
	{
		MCGridCoordinates subBase = base;
		if (i & 1) subBase.x += halfSize;
		if (i & 2) subBase.y += halfSize;
		if (i & 4) subBase.z += halfSize;
		
		NSString *prefix = [NSString stringWithFormat:@"%lu %@: ", i, JA_ENCODE(subBase)];
		
		void *child = node->children.inner[i];
		if (child == NULL)  Log(@"%@null", prefix);
		else if (level > 1)
		{
			Log(@"%@{", prefix);
			DumpNodeStructure(child, level - 1, stats, subBase, halfSize);
		}
		else
		{
			stats->leafNodeCount++;
			Chunk *chunk = child;
			if (chunk->refCount == 1)  Log(@"%@Chunk %p", prefix, chunk);
			else  Log(@"%@Chunk %p [refcount: %u]", prefix, chunk, chunk->refCount);
		}
	}
	
	LogOutdent();
	Log(@"}");
}


- (void) dumpStructure
{
	DumpStatistics stats = {0};
	MCGridExtents totalExtents = self.totalExtents;
	MCGridCoordinates base = MCGridExtentsMinimum(totalExtents);
	NSUInteger size = MCGridExtentsWidth(totalExtents);
	
	Log(@"{");
	
	DumpNodeStructure(_root, _rootLevel, &stats, base, size);
	
	// Calculate Maximum inner node and leaf count for this level of octree.
	NSUInteger maxInnerNodes = 0;
	NSUInteger maxLeafNodes = 1;
	for (NSUInteger i = 0; i < _rootLevel; i++)
	{
		maxInnerNodes += maxLeafNodes;
		maxLeafNodes *= 8;
	}
	
	NSLog(@"Levels: %u. Inner nodes: %lu of %lu (%.2f %%). Leaf nodes: %lu of %lu (%.2f %%).", _rootLevel, stats.innerNodeCount, maxInnerNodes, (float)stats.innerNodeCount / maxInnerNodes * 100.0f, stats.leafNodeCount, maxLeafNodes, (float)stats.leafNodeCount / maxLeafNodes* 100.0f);
}


- (void) endBulkUpdate
{
	[super endBulkUpdate];
	if (!self.bulkUpdateInProgress)
	{
		[self dumpStructure];
	}
}

#endif


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


- (BOOL) forEachChunkInRegion:(MCGridExtents)bounds do:(JAMinecraftSchematicChunkIterator)iterator
{
	MCGridExtents totalExtents = self.totalExtents;
	MCGridCoordinates base = { totalExtents.minX, totalExtents.minY, totalExtents.minZ };
	NSUInteger size = totalExtents.maxX - totalExtents.minX + 1;
	
	return ForEachChunk(_root, base, size, _rootLevel, bounds, iterator, NO);
}


- (BOOL) forEachChunkDo:(JAMinecraftSchematicChunkIterator)iterator
{
	return [self forEachChunkInRegion:kMCInfiniteExtents do:iterator];
}

@end


#if LOGGING
static NSUInteger sLiveInnerNodes = 0;
static NSUInteger sLiveChunks = 0;
#endif


static inline off_t Offset(unsigned x, unsigned y, unsigned z)  __attribute__((const, always_inline));
static inline off_t Offset(unsigned x, unsigned y, unsigned z)
{
	return (z * kChunkSize + y) * kChunkSize + x;
}


static inline InnerNode *AllocInnerNode(NSUInteger level)
{
	InnerNode *result = calloc(sizeof(InnerNode), 1);
	if (result == NULL)  [NSException raise:NSMallocException format:@"Out of memory"];
	
	result->refCount = 1;
#ifndef NDEBUG
	result->level = level;
#endif
#if LOGGING
	sLiveInnerNodes++;
#endif
	
	return result;
}


static Chunk *AllocChunk(void)
{
	Chunk *result = calloc(sizeof(Chunk), 1);
	if (result == NULL)  [NSException raise:NSMallocException format:@"Out of memory"];
	
	result->refCount = 1;
	result->extents = kMCEmptyExtents;
	result->extentsAreAccurate = YES;
	
#if LOGGING
	sLiveChunks++;
#endif
	
	return result;
}


static Chunk *MakeChunk(NSInteger baseY, NSInteger groundLevel)
{
	Chunk *result = AllocChunk();
	
	if (baseY < groundLevel)
	{
		MCCell stoneCell = { kMCBlockSmoothStone, 0 };
		if (baseY + kChunkSize < groundLevel)
		{
			FillChunk(result, stoneCell);
		}
		else
		{
			unsigned maxY = groundLevel - baseY;
			for (unsigned z = 0; z < kChunkSize; z++)
			{
				for (unsigned y = 0; y < maxY; y++)
				{
					unsigned offset = Offset(0, y, z);
					for (unsigned x = 0; x < kChunkSize; x++)
					{
						result->cells[offset++] = stoneCell;
					}
				}
			}
		}
	}
	
	return result;
}


static inline void FreeInnerNode(InnerNode *node, NSUInteger level)
{
	NSCParameterAssert(node != NULL && node->level == level);
	
	Log(@"Freeing inner node %p [level %lu, live count -> %lu]", node, node->level, --sLiveInnerNodes);
	LogIndent();
	
	for (unsigned i = 0; i < 8; i++)
	{
		if (node->children.inner[i] != NULL)
		{
			if (level == 1)  ReleaseChunk(node->children.leaves[i]);
			else  ReleaseInnerNode(node->children.inner[i], level - 1);
		}
	}
	free(node);
	
	LogOutdent();
}


static inline void FreeChunk(Chunk *chunk)
{
	Log(@"Freeing chunk %p [live count -> %lu]", chunk, --sLiveChunks);
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
	NSCParameterAssert(node != NULL && level == node->level);
	
	Log(@"Releasing inner node %p [refcount %lu->%lu, level %lu]", node, node->refCount, node->refCount - 1, node->level);
	LogIndent();
	
	if (--node->refCount == 0)
	{
		FreeInnerNode(node, level);
	}
	
	LogOutdent();
}


static void ReleaseChunk(Chunk *chunk)
{
	NSCParameterAssert(chunk != NULL);
	
	Log(@"Releasing chunk %p [refcount %u->%u]", chunk, chunk->refCount, chunk->refCount - 1);
	LogIndent();
	
	if (--chunk->refCount == 0)
	{
		FreeChunk(chunk);
	}
	
	LogOutdent();
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
		for (z = 0; z < kChunkSize; z++)
		{
			for (y = 0; y < kChunkSize; y++)
			{
				for (x = 0; x < kChunkSize; x++)
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
					   0 <= x && x < kChunkSize &&
					   0 <= y && y < kChunkSize &&
					   0 <= z && z < kChunkSize);
	
	return chunk->cells[Offset(x, y, z)];
}


static BOOL ChunkSetCell(Chunk *chunk, NSInteger x, NSInteger y, NSInteger z, MCCell cell)
{
	NSCParameterAssert(chunk != NULL &&
					   0 <= x && x < kChunkSize &&
					   0 <= y && y < kChunkSize &&
					   0 <= z && z < kChunkSize);
	
	unsigned offset = Offset(x, y, z);
	if (MCCellsEqual(chunk->cells[offset], cell))  return NO;
	
	chunk->cells[offset] = cell;
	chunk->extentsAreAccurate = NO;
	return YES;
}


static void FillChunk(Chunk *chunk, MCCell cell)
{
	NSCParameterAssert(chunk != NULL);
	
	MCCell pattern[8] = { cell, cell, cell, cell, cell, cell, cell, cell };
	memset_pattern16(chunk->cells, &pattern, sizeof chunk->cells / 16);
}


#if LOGGING
static NSString *sLogIndentation = @"";


static void Log(NSString *format, ...)
{
	va_list args;
	va_start(args, format);
	NSString *message = [sLogIndentation stringByAppendingString:[[NSString alloc] initWithFormat:format arguments:args]];
	va_end(args);
	
	printf("%s\n", [message UTF8String]);
}


static void LogIndent(void)
{
	sLogIndentation = [sLogIndentation stringByAppendingString:@"  "];
}


static void LogOutdent(void)
{
	if (sLogIndentation.length > 1)  sLogIndentation = [sLogIndentation substringFromIndex:2];
}
#endif
