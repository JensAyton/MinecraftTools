/*
	JAMinecraftSchematic.m
	
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

#import "JAMinecraftSchematic.h"
#import "JAValueToString.h"
#import "JACollectionHelpers.h"
#import "JAPropertyListAccessors.h"
#import "MYCollectionUtilities.h"


// Base debug features: validate node types and levels. Required for logging and instance tracking.
#ifndef DEBUG_MCSCHEMATIC
#define DEBUG_MCSCHEMATIC		!defined(NDEBUG)
#endif

// Verbose logging of internal structure changes and reference counting.
#define LOGGING					(0 && DEBUG_MCSCHEMATIC)
#define LOG_STRUCTURE			(0 && LOGGING)

// Tracking of node instances; dump from debugger by calling p JAMCSchematicDump().
#define TRACK_NODE_INSTANCES	(1 && DEBUG_MCSCHEMATIC)

// Logging of access cache hit rate.
#define PROFILE_CACHE			0


#if LOGGING || TRACK_NODE_INSTANCES
static void DoLog(NSString *format, ...);
static void DoLogIndent(void);
static void DoLogOutdent(void);
#endif

#if LOGGING
#define Log DoLog
#define LogIndent DoLogIndent
#define LogOutdent DoLogOutdent
#else
#define Log(...)  do {} while (0)
#define LogIndent()  do {} while (0)
#define LogOutdent()  do {} while (0)
#endif


enum
{
	kChunkSize		= 4,
	kJAMinecraftSchematicCellsPerChunk	= kChunkSize * kChunkSize * kChunkSize
};


#if LOGGING

typedef struct
{
	NSUInteger						innerNodeCount;
	NSUInteger						leafNodeCount;
} DumpStatistics;

#endif


typedef struct InnerNode InnerNode;
typedef struct Chunk Chunk;
struct InnerNode
{
#if DEBUG_MCSCHEMATIC
	uint32_t					tag;
	NSUInteger					level;	// For sanity checking.
#endif
	NSUInteger					refCountMinusOne;
	
	union
	{
		InnerNode				*inner[8];
		Chunk					*leaves[8];
	}							children;
};

struct Chunk
{
#if DEBUG_MCSCHEMATIC
	uint32_t					tag;
#endif
	uint32_t					refCountMinusOne;
	BOOL						extentsAreAccurate;
	MCGridExtents				extents;
	MCCell						cells[kJAMinecraftSchematicCellsPerChunk];
};


#if DEBUG_MCSCHEMATIC
enum
{
	kTagInnerNode				= 'node',
	kTagChunk					= 'chnk',
	kTagDeadInnerNode			= 'xnod',
	kTagDeadChunk				= 'xchk'
};
#endif


static id TileEntityKeyForCoords(MCGridCoordinates coords);


static inline InnerNode *AllocInnerNode(NSUInteger level);
static Chunk *AllocChunk(void);
static Chunk *MakeChunk(NSInteger baseY, NSInteger groundLevel);	// Create a chunk and fill it with stone or air as appropriate depending on ground level.

// Copy-on-write.
static InnerNode *COWInnerNode(InnerNode *node, NSUInteger level);
static Chunk *COWChunk(Chunk *chunk);

// Immediate copy, COWing children as necessary.
static InnerNode *CopyInnerNode(InnerNode *node, NSUInteger level);
static Chunk *CopyChunk(Chunk *chunk);

static inline NSUInteger GetInnerNodeRefCount(InnerNode *node, NSUInteger level);
static inline NSUInteger GetChunkRefCount(Chunk *chunk);

// Equivlant to Get[InnerNode/Chunk]RefCount(...) > 1
static inline BOOL InnerNodeIsShared(InnerNode *node, NSUInteger level);
static inline BOOL ChunkIsShared(Chunk *chunk);

static void ReleaseInnerNode(InnerNode *node, NSUInteger level);
static void ReleaseChunk(Chunk *chunk);

static MCGridExtents ChunkGetExtents(Chunk *chunk, NSInteger baseY, NSInteger groundLevel);
static inline MCCell ChunkGetCell(Chunk *chunk, NSInteger x, NSInteger y, NSInteger z);
static BOOL ChunkSetCell(Chunk *chunk, NSInteger x, NSInteger y, NSInteger z, MCCell cell);	// Returns true if cell is changed.

// Recursively test if node’s children are all null. Does not test effective emptiness of chunks.
static BOOL NodeIsEmpty(InnerNode *node, unsigned level);

// Slightly higher-level interfaces which infer type from level.
static void *COWNode(void *node, unsigned level);
static void ReleaseNode(void *node, unsigned level);
static NSUInteger GetNodeRefCount(void *node, unsigned level);

static void FillCompleteChunk(Chunk *chunk, MCCell cell);
static void FillPartialChunk(Chunk *chunk, MCCell cell, MCGridExtents extents);


typedef BOOL (^JAMinecraftSchematicChunkIterator)(Chunk *chunk, MCGridCoordinates base);


@interface JAMinecraftSchematic ()

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
- (void) growOctreeToCoverDistance:(NSUInteger)distance;
- (void) growOctreeToCoverExtents:(MCGridExtents)extents;

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

/*	Structural optimization: find empty space areas and ensure they’re null
	blocks, and shrink the tree if possible.
	
	The “deferred” option will cause an optimization pass to happen at the end
	of any ongoing bulk update; if none is going on the optimization will
	happen immediately. -optimizeWholeTree always uses deferred mode.
	
	Future possibility: find non-empty-space homogeneous chunks too.
*/
- (void) optimizeStructureInRegion:(MCGridExtents)region deferred:(BOOL)deferred;
- (void) optimizeWholeTree;

/*	-reifyStructureInRegion: is semantically the opposite of
	-optimizeStructureInRegion:; it replaces all empty-space chunks in a
	region with explicit ones. I refrained from calling it
	-pessimizeStructureInRegion: since it reuses chunks and inner nodes to
	reduce cost.
*/
- (void) reifyStructureInRegion:(MCGridExtents)region;

@end


static inline NSUInteger RepresentedDistance(levels)
{
	return (1 << (levels - 1)) * kChunkSize;
}


@implementation JAMinecraftSchematic
{
	struct InnerNode				*_root;
	MCGridExtents					_extents;
	NSInteger						_groundLevel;
	
	NSMutableDictionary				*_tileEntities;
	
	BOOL							_extentsAreAccurate;
	uint8_t							_rootLevel;
	
	/*
		Access cache for quicker sequential reads.
		TODO: keep track of path through tree to cached chunk. This will allow
		fast access to adjacent chunks, and use of cache on write (by checking
		for COWed ancestor nodes).
	*/
	BOOL							_cacheIsValid;
	struct Chunk					*_cachedChunk;
	MCGridCoordinates				_cacheBase;
	
	MCGridExtents					_deferredOptimizationRegion;
}

@synthesize groundLevel = _groundLevel;


- (id) init
{
	return [self initWithGroundLevel:0];
}


- (id) initWithGroundLevel:(NSInteger)groundLevel
{
	if ((self = [super init]))
	{
		// One level, initially with nil children.
		_rootLevel = 1;
		_root = AllocInnerNode(_rootLevel);
		Log(@"Creating root inner node %p", _root);
		
		_extents = kMCEmptyExtents;
		_extentsAreAccurate = YES;
		_groundLevel = groundLevel;
	}
	
	return self;
}


- (id) initWithRegion:(MCGridExtents)region ofStore:(JAMinecraftBlockStore *)store
{
	if (store == nil)  return nil;
	
	if ((self = [self initWithGroundLevel:store.groundLevel]))
	{
		if (!MCGridExtentsEmpty(region))
		{
			[self copyRegion:region from:store at:MCGridExtentsMinimum(region)];
		}
	}
	
	return self;
}


- (void) finalize
{
	//	The tree is not thread-safe, so we need to release it on the main thread.
	
	InnerNode *root = _root;
	if (root != NULL)
	{
		NSUInteger level = _rootLevel;
		[[NSOperationQueue mainQueue] addOperationWithBlock: ^{ ReleaseInnerNode(root, level); }];
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
		
		copy->_tileEntities = [_tileEntities mutableCopy];
	}
	
	return copy;
}


- (MCCell) cellAt:(MCGridCoordinates)location gettingTileEntity:(NSDictionary **)outTileEntity
{
	MCGridCoordinates base;
	Chunk *chunk = [self resolveChunkAt:location
						baseCoordinates:&base
						 createIfNeeded:NO
						  makeWriteable:NO];
	
	if (chunk == NULL)
	{
		if (location.y >= self.groundLevel)  return kMCAirCell;
		else  return kMCStoneCell;
	}
	
	if (outTileEntity != NULL)
	{
		*outTileEntity = [_tileEntities objectForKey:TileEntityKeyForCoords(location)];
	}
	
	return ChunkGetCell(chunk, location.x - base.x, location.y - base.y, location.z - base.z);
}


- (void) setCell:(MCCell)cell andTileEntity:(NSDictionary *)tileEntity at:(MCGridCoordinates)location
{
	MCRequireTileEntityIsCompatibleWithCell(tileEntity, cell);
	
	BOOL isEmptyCell = MCCellsEqual(cell, (location.y < _groundLevel) ? kMCStoneCell : kMCAirCell );
	
	MCGridCoordinates base;
	Chunk *chunk = [self resolveChunkAt:location
						baseCoordinates:&base
						 createIfNeeded:!isEmptyCell
						  makeWriteable:YES];
	
	BOOL changed = NO;
	if (chunk != nil)
	{
		NSAssert(chunk->refCountMinusOne == 0, @"resolveChunkAt:... returned a shared chunk for setCell:at:");
		
		BOOL changeAffectsExtents = YES;	// FIXME: smartness
		
		changed = ChunkSetCell(chunk, location.x - base.x, location.y - base.y, location.z - base.z, cell);
		
		id key = TileEntityKeyForCoords(location);
		if (!changed)  changed = !$equal([_tileEntities objectForKey:key], tileEntity);
		
		if (tileEntity != nil)
		{
			if (_tileEntities == nil)  _tileEntities = [NSMutableDictionary new];
			NSDictionary *cleaned = [tileEntity ja_dictionaryByRemovingObjectsForKeys:$set(@"x", @"y", @"z")];
			[_tileEntities setObject:cleaned forKey:key];
		}
		
		if (changeAffectsExtents && changed)
		{
			[self willChangeValueForKey:@"extents"];
			_extentsAreAccurate = NO;
			[self didChangeValueForKey:@"extents"];
		}
		[self noteChangeInLocation:location];
	}
}


/*
	Given a cache array for PerformFill() and a level, return the fully-filled
	node for that level.
	The caller need _not_ copy or COW the result.
*/
static void *GetTemplateNode(void **filledNodeCache, unsigned level, MCCell cell)
{
	if (filledNodeCache[level] != NULL)
	{
		return COWNode(filledNodeCache[level], level);

	}
	else if (level == 0)
	{
		Chunk *level0 = AllocChunk();
		Log(@"Reifing cache level %u as %p", level, level0);
		FillCompleteChunk(level0, cell);
		filledNodeCache[0] = level0;
		return level0;
	}
	else
	{
		InnerNode *result = AllocInnerNode(level);
		Log(@"Reifing cache level %u as %p", level, result);
		for (unsigned i = 0; i < 8; i++)
		{
			result->children.inner[i] = GetTemplateNode(filledNodeCache, level - 1, cell);
		}
		
		filledNodeCache[level] = result;
		return result;
	}
}


static void PerformFill(InnerNode *node, unsigned level, MCGridExtents fillRegion, MCCell cell, void **filledNodeCache, MCGridCoordinates base, NSUInteger size, NSInteger groundLevel, BOOL isAir, BOOL isStone)
{
	NSUInteger halfSize = size / 2;
	unsigned subLevel = level - 1;
	
	Log(@"Filling node %p [level %u]", node, level);
	LogIndent();
	
	for (unsigned i = 0; i < 8; i++)
	{
		// Find extents of ith child.
		MCGridCoordinates subBase = base;
		if (i & 1) subBase.x += halfSize;
		if (i & 2) subBase.y += halfSize;
		if (i & 4) subBase.z += halfSize;
		
		//	Determine whether this child is entirely within the fill region.
		BOOL completelyEnclosed = NO;
		if (MCGridCoordinatesAreWithinExtents(subBase, fillRegion))
		{
			MCGridCoordinates max = { subBase.x + halfSize - 1, subBase.y + halfSize - 1, subBase.z + halfSize - 1 };
			completelyEnclosed = MCGridCoordinatesAreWithinExtents(max, fillRegion);
		}
		
		// If the child is completely enclosed, we want to replace it.
		if (completelyEnclosed)
		{
			BOOL emptySpace = (isAir && subBase.y >= groundLevel) || (isStone && (NSInteger)(subBase.y + halfSize - 1) < groundLevel);
			
			void *templateNode;
			if (emptySpace)
			{
				// Empty space - use a null node.
				templateNode = NULL;
			}
			else
			{
				// Use template node.
				templateNode = GetTemplateNode(filledNodeCache, subLevel, cell);
			}
			
			if (node->children.inner[i] != NULL)
			{
				ReleaseNode(node->children.inner[i], subLevel);
			}
			
			if (level > 1)
			{
				Log(@"Replacing inner node %p [level %u] with %p [refcount %u]", node->children.inner[i], subLevel, templateNode, GetNodeRefCount(templateNode, subLevel));
				node->children.inner[i] = templateNode;
			}
			else
			{
				Log(@"Replacing chunk %p with %p [refcount %u]", node->children.leaves[i], templateNode, GetNodeRefCount(templateNode, subLevel));
				node->children.leaves[i] = templateNode;
			}
		}
		else
		{
			MCGridExtents subExtents = MCGridExtentsWithCoordinatesAndSize(subBase, halfSize, halfSize, halfSize);
			if (MCGridExtentsIntersect(subExtents, fillRegion))
			{
				// Region boundary intersects child.
				if (level > 1)
				{
					// Descend.
					if (node->children.inner[i] == NULL)
					{
						node->children.inner[i] = AllocInnerNode(subLevel);
						Log(@"Made inner node %p [level %u]", node->children.inner[i], subLevel);
					}
					else if (InnerNodeIsShared(node->children.inner[i], subLevel))
					{
						InnerNode *old = node->children.inner[i];
						node->children.inner[i] = CopyInnerNode(old, subLevel);
						Log(@"Copied inner node %p to %p [level %u]", old, node->children.inner[i], subLevel);
						ReleaseInnerNode(old, subLevel);
					}
					PerformFill(node->children.inner[i], subLevel, fillRegion, cell, filledNodeCache, subBase, halfSize, groundLevel, isAir, isStone);
				}
				else
				{
					// Fill part of chunk.
					if (node->children.leaves[i] == NULL)
					{
						node->children.leaves[i] = MakeChunk(subBase.y, groundLevel);
						Log(@"Made chunk %p", node->children.leaves[i]);
					}
					else if (ChunkIsShared(node->children.leaves[i]))
					{
						Chunk *old = node->children.leaves[i];
						node->children.leaves[i] = CopyChunk(old);
						Log(@"Copied chunk %p to %p", old, node->children.leaves[i]);
						ReleaseChunk(old);
					}
					
					MCGridExtents fillExtents = MCGridExtentsIntersection(subExtents, fillRegion);
					fillExtents = MCGridExtentsOffset(fillExtents, -subBase.x, -subBase.y, -subBase.z);
					Log(@"Filling chunk %p in extents %@", node->children.leaves[i], JA_ENCODE(fillExtents));
					FillPartialChunk(node->children.leaves[i], cell, fillExtents);
				}
			}
		}
	}
	
	LogOutdent();
}


- (void) fillRegion:(MCGridExtents)region withCell:(MCCell)cell
{
	BOOL isAir = (cell.blockID == kMCBlockAir && cell.blockData == 0);
	BOOL isStone = (cell.blockID == kMCBlockSmoothStone && cell.blockData == 0);
	
	[self growOctreeToCoverExtents:region];
	
	/*
		For efficiency, we want to replace large areas with shared chunks/nodes.
		The filledNodeCache array contains these shared nodes:
		filledNodeCache[0] will be a chunk filled entirely with the target cell
		type, and filledNodeCache[n] will be an inner node whose children are
		filledNodes[n - 1].
	*/
	void *filledNodeCache[_rootLevel];
	memset(filledNodeCache, 0, sizeof(void *) * _rootLevel);
	
	NSInteger repDistance = RepresentedDistance(_rootLevel);
	MCGridCoordinates base = { -repDistance, -repDistance, -repDistance };
	NSUInteger size = repDistance * 2;
	
	Log(@"Filling region %@ of %@ with cell %@", JA_ENCODE(region), self, JA_ENCODE(cell));
	LogIndent();
	
	PerformFill(_root, _rootLevel, region, cell, filledNodeCache, base, size, self.groundLevel, isAir, isStone);
	
	LogOutdent();
	
	[self willChangeValueForKey:@"extents"];
	_extentsAreAccurate = NO;
	[self didChangeValueForKey:@"extents"];
	[self noteChangeInExtents:region];
	
	if (isAir || isStone)  [self optimizeStructureInRegion:region deferred:YES];
	
#if LOG_STRUCTURE
	[self dumpStructure];
#endif
}


- (void) copyRegion:(MCGridExtents)region from:(JAMinecraftBlockStore *)source at:(MCGridCoordinates)location
{
	// FIXME: should optimize for schematics and copy-on-write chunks when appropriately aligned.
	[self beginBulkUpdate];
	
	[super copyRegion:region from:source at:location];
	[self optimizeWholeTree];
	
	[self endBulkUpdate];
}


- (MCGridExtents) extents
{
	if (!_extentsAreAccurate)
	{
		__block MCGridExtents result = kMCEmptyExtents;
		const NSInteger groundLevel = self.groundLevel;
		
		[self forEachChunkDo:^(Chunk *chunk, MCGridCoordinates base) {
			MCGridExtents chunkExtents = ChunkGetExtents(chunk, base.y, groundLevel);
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


/*
	Assign a weight to each block type. Positive weights are “ground-like”,
	and negative weights are “above-ground-like”. Needs testing with a
	greater variety of circuits to tweak weights. These are pretty
	arbitrary.

	The general idea is that the floor level of a house or cave should be
	considered ground level, even if there’s another floor/rock layer
	above.

	Reference weights:
	-8: air, vegetation (logs are weaker since they’re also building
	    materials), most non-block items (which appear as “things in air”
	-4: blocky objects (workbenches etc.)
	-2: building materials
	 6: typical ground blocks
	 8: ore blocks
 */
const int8_t kGroundLevelWeights[256] =
{
	-8,		// Air
	4,		// Smooth stone
	6,		// Grass
	6,		// Dirt
	-2,		// Cobblestone
	-2,		// Wood (planks)
	-8,		// Sapling
	8,		// Bedrock
	1,		// Water
	2,		// Stationary water
	
	2,		// Lava
	4,		// Stationary lava
	6,		// Sand
	6,		// Gravel
	8,		// Gold ore
	8,		// Iron ore
	8,		// Coal “ore”
	-6,		// Log
	-8,		// Leaves
	0,		// Sponge
	
	-2,		// Glass
	8,		// Lapis lazuli “ore”
	-2,		// Lapis lazuli block
	-4,		// Dispenser
	-2,		// Sandstone
	-4,		// Note block
	-8,		// Bed
	-8,		// Powered rail
	-8,		// Detector rail
	-4,		// Sticky piston
	
	0,		// Cobweb (doesn’t occur naturally at time of writing)
	-8,		// Tall grass
	-8,		// Dead shrubs
	-4,		// Piston
	-4,		// Piston head
	-2,		// Cloth
	-4,		// Piston animation
	-8,		// Yellow flower
	-8,		// Red flower
	1,		// Brown mushroom
	
	1,		// Red mushroom
	-2,		// Gold block
	-2,		// Iron block
	2,		// Double step
	0,		// Single step
	-2,		// Brick
	-2,		// TNT
	-4,		// Bookshelf
	0,		// Mossy cobblestone
	0,		// Obsidian
	
	-8,		// Torch
	-8,		// Fire
	-4,		// Mob spawner
	-2,		// Wooden stairs
	-4,		// Chest
	-8,		// Redstone wire
	8,		// Diamond “ore”
	-2,		// Diamond block
	-4,		// Workbench
	-8,		// Crops
	
	6,		// Soil
	-4,		// Furnace
	-4,		// Burning furnace
	-8,		// Signpost
	-8,		// Wooden door
	-8,		// Ladder
	-8,		// Minecraft track
	-2,		// Wooden stairs
	-8,		// Wall sign
	-8,		// Lever
	
	-8,		// Stone pressure plate
	-8,		// Iron door
	-8,		// Woodne pressure plate
	8,		// Redstone ore
	8,		// Glowing redstone ore
	-8,		// Redstone torch (off)
	-8,		// Redstone torch (on)
	-8,		// Stone button
	-8,		// Snow
	-8,		// Ice
	
	-2,		// Snow block
	-8,		// Cactus
	2,		// Clay
	-8,		// Reed
	-4,		// Jukebox
	-8,		// Fence
	-4,		// Pumpkin
	6,		// Netherstone
	6,		// Slow sand
	-1,		// Lightstone - technically a “ground” block, but generally over empty space
	
	-4,		// Portal
	-4,		// Jack-o-lantern
	-8,		// Cake
	-8,		// Redstone repeater (off)
	-8,		// Redstone repeater (on)
	-8,		// Locked chest
	-8,		// Trapdoor
	8,		// Stone with silverfish
	-2,		// Stone brick
	-8,		// Giant mushroom part
	
	-8,		// Giant mushroom part
	-4,		// Iron bars
	-4,		// Glass pane
	-4,		// Watermelon
	-8,		// Pumpkin stem
	-8,		// Watermelon stem
	-8,		// Vines
	-8,		// Gate
	-2,		// Brick stairs
	-2,		// Stone brick stairs
	
	6,		// Mycelium
	-8,		// Lily pad
	-2,		// Nether brick
	-8,		// Nether brick fence
	-2,		// Nether brick stairs
	-8,		// Nether wart
	-8,		// Enchantment table
	-8,		// Brewing stand
	-8,		// Cauldron
	-8,		// Air portal
	
	-6,		// Air portal frame
	
	0
};

enum
{
	kLastWeight = kMCBlockAirPortalFrame
};


static char If_you_get_an_error_here_the_ground_level_weight_table_above_needs_to_be_updated[kLastWeight == kMCLastBlockID ? 1 : -1] __attribute__((unused));


- (NSInteger) findNaturalGroundLevel
{
	MCGridExtents extents = self.extents;
	if (MCGridExtentsEmpty(extents))  return 0;
	
	// Round minY and maxY outward to chunk boundaries.
	NSInteger minY = extents.minY / kChunkSize * kChunkSize;
	NSInteger maxY = (extents.maxY + kChunkSize) / kChunkSize * kChunkSize;
	NSUInteger levelCount = maxY - minY;
	
	NSInteger weightArray[levelCount];
	memset(weightArray, 0, sizeof weightArray);
	NSInteger *weights = weightArray;	// Can’t refer to array from inside block.
	
	MCGridCoordinates coords;
	for (coords.y = extents.minY; coords.y <= extents.maxY; coords.y++)
	{
		NSInteger weight = 0;
		
		for (coords.z = extents.minZ; coords.z <= extents.maxZ; coords.z++)
		{
			for (coords.x = extents.minX; coords.x <= extents.maxX; coords.x++)
			{
				MCCell cell = [self cellAt:coords];
				weight += kGroundLevelWeights[cell.blockID];
			}
		}
		
		off_t yIndex = coords.y - extents.minY;
		NSAssert(yIndex < (off_t)levelCount, @"Level range logic error");
		weights[yIndex] += weight;
	}
	
#if 0 && DEBUG_MCSCHEMATIC
	for (NSUInteger i = 0; i < levelCount; i++)
	{
		NSLog(@"weights[%lu] (level %li): %li (avg: %g)", i, i + minY, weights[i], (float)weights[i] / (MCGridExtentsWidth(extents) * MCGridExtentsLength(extents)));
	}
#endif
	
	// Find first negative weight.
	NSUInteger groundIndex;
	for (groundIndex = 0; groundIndex < levelCount; groundIndex++)
	{
		if (weights[groundIndex] < 0)  break;
	}
	
	// Work backwards past any zeros, which are equally groundy and ungroundy
	while (groundIndex > 1 && weights[groundIndex - 1] < 1)
	{
		groundIndex--;
	}
	
	return minY + groundIndex;
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
		[self growOctreeToCoverDistance:maxDistance];
		repDistance = RepresentedDistance(_rootLevel);
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
			node->children.inner[nextIndex] = child;
		}
		if (makeWriteable && InnerNodeIsShared(child, level))
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
		
		node->children.leaves[nextIndex] = chunk;
	}
	else if (makeWriteable && ChunkIsShared(chunk))
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
	Log(@"Creating root inner node %p [level %lu]", newRoot, newRoot->level);
	
	InnerNode *oldRoot = _root;
	
	for (unsigned i = 0; i < 8; i++)
	{
		if (oldRoot->children.inner[i] != nil)
		{
			InnerNode *intermediate = AllocInnerNode(_rootLevel);
			Log(@"Creating intermediate inner node %p [level %lu]", intermediate, intermediate->level);
			
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


- (void) growOctreeToCoverDistance:(NSUInteger)distance
{
	NSUInteger repDistance = RepresentedDistance(_rootLevel);
	
	// If block is out of range, we need to grow until it isn’t.
	while (repDistance <= distance)
	{
		[self growOctree];
		repDistance = RepresentedDistance(_rootLevel);
	}
}


- (void) growOctreeToCoverExtents:(MCGridExtents)extents
{
	NSInteger maxDistance = 0;
	maxDistance = MAX(maxDistance, extents.maxX);
	maxDistance = MAX(maxDistance, -extents.minX);
	maxDistance = MAX(maxDistance, extents.maxY);
	maxDistance = MAX(maxDistance, -extents.minY);
	maxDistance = MAX(maxDistance, extents.maxZ);
	maxDistance = MAX(maxDistance, -extents.minZ);
	
	[self growOctreeToCoverDistance:maxDistance];
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
	
	// Calculate maximum inner node and leaf count for this level of octree.
	NSUInteger maxInnerNodes = 0;
	NSUInteger maxLeafNodes = 1;
	for (NSUInteger i = 0; i < _rootLevel; i++)
	{
		maxInnerNodes += maxLeafNodes;
		maxLeafNodes *= 8;
	}
	
	NSLog(@"Levels: %u. Inner nodes: %lu of %lu (%.2f %%). Leaf nodes: %lu of %lu (%.2f %%).", _rootLevel, stats.innerNodeCount, maxInnerNodes, (float)stats.innerNodeCount / maxInnerNodes * 100.0f, stats.leafNodeCount, maxLeafNodes, (float)stats.leafNodeCount / maxLeafNodes* 100.0f);
}
#endif


- (void) endBulkUpdate
{
	[super endBulkUpdate];
	if (!self.bulkUpdateInProgress)
	{
		if (!MCGridExtentsEmpty(_deferredOptimizationRegion))
		{
			[self optimizeStructureInRegion:_deferredOptimizationRegion deferred:NO];
			_deferredOptimizationRegion = kMCEmptyExtents;
		}
#if LOG_STRUCTURE
		[self dumpStructure];
#endif
	}
}


static BOOL ForEachChunk(InnerNode *node, MCGridCoordinates base, NSUInteger size, NSUInteger level, MCGridExtents bounds, JAMinecraftSchematicChunkIterator iterator, BOOL makeWriteable)
{
	NSCParameterAssert(node != NULL && node->tag == ((level == 0) ? kTagChunk : kTagInnerNode));
	
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
				if (makeWriteable && InnerNodeIsShared(child, level))
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


static BOOL ChunkIsEmpty(Chunk *chunk, NSInteger baseY, NSInteger groundLevel)
{
	for (unsigned y = 0; y < kChunkSize; y++)
	{
		uint8_t emptyType = (baseY + y >= groundLevel) ? kMCBlockAir : kMCBlockSmoothStone;
		
		for (unsigned z = 0; z < kChunkSize; z++)
		{
			for (unsigned x = 0; x < kChunkSize; x++)
			{
				MCCell cell = ChunkGetCell(chunk, x, y, z);
				if (cell.blockID != emptyType || cell.blockData != 0)  return NO;
			}
		}
	}
	
	return YES;
}


static void OptimizeStructure(InnerNode **nodePtr, unsigned level, MCGridExtents region_, MCGridCoordinates base, NSUInteger size, NSInteger groundLevel)
{
	NSCParameterAssert(nodePtr != NULL && *nodePtr != NULL);
	
	InnerNode *node = *nodePtr;
	MCGridExtents region = region_;
	NSUInteger halfSize = size / 2;
	unsigned subLevel = level - 1;
	BOOL remainingChildren = NO;
	
	Log(@"Optimizing node %p [level %u]", node, level);
	LogIndent();
	
	for (unsigned i = 0; i < 8; i++)
	{
		if (node->children.inner[i] != NULL)
		{
			// Find extents of ith child.
			MCGridCoordinates subBase = base;
			if (i & 1) subBase.x += halfSize;
			if (i & 2) subBase.y += halfSize;
			if (i & 4) subBase.z += halfSize;
			
			MCGridExtents subExtents = MCGridExtentsWithCoordinatesAndSize(subBase, halfSize, halfSize, halfSize);
			if (MCGridExtentsIntersect(subExtents, region))
			{
				if (subLevel > 0)
				{
					OptimizeStructure(&node->children.inner[i], subLevel, region, subBase, halfSize, groundLevel);
				}
				else
				{
					if (ChunkIsEmpty(node->children.leaves[i], base.y, groundLevel))
					{
						ReleaseChunk(node->children.leaves[i]);
						node->children.leaves[i] = NULL;
					}
				}
			}
		}
		
		if (node->children.inner[i] != NULL)  remainingChildren = YES;
	}
	
	if (!remainingChildren)
	{
		ReleaseInnerNode(node, level);
		*nodePtr = NULL;
	}
	
	LogOutdent();
}


- (void) optimizeStructureInRegion:(MCGridExtents)region deferred:(BOOL)deferred
{
	return;
	
	if (MCGridExtentsEmpty(region))  return;
	
	if (deferred && self.bulkUpdateInProgress)
	{
		_deferredOptimizationRegion = MCGridExtentsUnion(_deferredOptimizationRegion, region);
		return;
	}
	
	Log(@"Optimizing %@", self);
	LogIndent();
	
	NSInteger repDistance = RepresentedDistance(_rootLevel);
	MCGridCoordinates base = { -repDistance, -repDistance, -repDistance };
	NSUInteger size = repDistance * 2;
	
	OptimizeStructure(&_root, _rootLevel, region, base, size, self.groundLevel);
	
	if (_root == NULL)
	{
		Log(@"Optimized tree is empty.");
		// We’re empty, but the root is required to exist for simplicity elsewhere.
		_rootLevel = 1;
		_root = AllocInnerNode(_rootLevel);
	}
	else
	{
		// FIXME: shrink tree if appropriate.
	}
	
	LogOutdent();
}


- (void) optimizeWholeTree
{
	[self optimizeStructureInRegion:kMCInfiniteExtents deferred:YES];
}


static void ReifyStructure(InnerNode *node, unsigned level, MCGridExtents region_, void **airNodeCache, void **stoneNodeCache, Chunk *interfaceChunk, MCGridCoordinates base, NSUInteger size, NSInteger groundLevel)
{
	NSCParameterAssert(node != NULL);
	
	MCGridExtents region = region_;
	NSUInteger halfSize = size / 2;
	unsigned subLevel = level - 1;
	
	Log(@"Reifying node %p [level %u]", node, level);
	LogIndent();
	
	for (unsigned i = 0; i < 8; i++)
	{
		// Find extents of ith child.
		MCGridCoordinates subBase = base;
		if (i & 1) subBase.x += halfSize;
		if (i & 2) subBase.y += halfSize;
		if (i & 4) subBase.z += halfSize;
		
		MCGridExtents subExtents = MCGridExtentsWithCoordinatesAndSize(subBase, halfSize, halfSize, halfSize);
		if (MCGridExtentsIntersect(subExtents, region))
		{
			if (subLevel > 0)
			{
				if (node->children.inner[i] == NULL)
				{
					void *appropriateCache = NULL;
					MCCell templateCell;
					
					/*	If this child is completely under/over ground and
						completely within the fill region, we can insert an
						entire subtree.
					*/
					if (MCGridExtentsAreWithinExtents(subExtents, region))
					{
						if (subBase.y >= groundLevel)
						{
							appropriateCache = airNodeCache;
							templateCell = kMCAirCell;
						}
						else if ((NSInteger)(subBase.y + halfSize) <= groundLevel)
						{
							appropriateCache = stoneNodeCache;
							templateCell = kMCStoneCell;
						}
					}
					
					if (appropriateCache != NULL)
					{
						InnerNode *node = GetTemplateNode(appropriateCache, subLevel, templateCell);
						Log(@"Inserting subtree %p [level %u, refcount %lu]", node, subLevel, node->refCount);
						node->children.inner[i] = node;
					}
					else
					{
						// Otherwise, allocate node and iterate into it.
						node->children.inner[i] = AllocInnerNode(subLevel);
						ReifyStructure(node->children.inner[i], subLevel, region, airNodeCache, stoneNodeCache, interfaceChunk, subBase, halfSize, groundLevel);
					}
				}
			}
			else
			{
				// Chunk level.
				if (node->children.leaves[i] == NULL)
				{
					Chunk *chunk = NULL;
					if (subBase.y >= groundLevel)
					{
						chunk = GetTemplateNode(airNodeCache, 0, kMCAirCell);
					}
					else if ((NSInteger)(subBase.y + halfSize) <= groundLevel)
					{
						chunk = GetTemplateNode(stoneNodeCache, 0, kMCStoneCell);
					}
					else
					{
						chunk = COWChunk(interfaceChunk);
					}
					
					Log(@"Inserting chunk %p [refcount %u]", chunk, chunk->refCount);
					node->children.leaves[i] = chunk;
				}
			}
		}
	}
	
	LogOutdent();
}


- (void) reifyStructureInRegion:(MCGridExtents)region
{
	/*
		Two caches similar to the one in -fillRegion:withCell: – one for air,
		the other for stone.
	*/
	void *airNodeCache[_rootLevel * 2];
	memset(airNodeCache, 0, sizeof(void *) * _rootLevel * 2);
	void *stoneNodeCache = airNodeCache + _rootLevel;
	
	NSInteger repDistance = RepresentedDistance(_rootLevel);
	MCGridCoordinates base = { -repDistance, -repDistance, -repDistance };
	NSUInteger size = repDistance * 2;
	
	NSInteger groundLevel = self.groundLevel;
	
	/*
		Interface chunk cache: a chunk for the level intersected by the ground
		level.
	*/
	MCGridExtents interfaceFillExtents = MCGridExtentsWithCoordinatesAndSize(kMCZeroCoordinates, kChunkSize, groundLevel % kChunkSize, kChunkSize);
	Chunk *interfaceChunk = AllocChunk();
	if (!MCGridExtentsEmpty(interfaceFillExtents))
	{
		FillPartialChunk(interfaceChunk, kMCStoneCell, interfaceFillExtents);
	}
	
	Log(@"Reifing region %@ of %@", JA_ENCODE(region), self);
	LogIndent();
	
	ReifyStructure(_root, _rootLevel, region, airNodeCache, stoneNodeCache, interfaceChunk, base, size, self.groundLevel);
	
	ReleaseChunk(interfaceChunk);
	
	LogOutdent();
}


#ifndef NDEBUG
static NSString *BuildGraphViz(void *node, unsigned level, MCGridCoordinates base, NSUInteger size, NSMutableString *graphViz, NSMutableSet *seen)
{
	if (node == NULL)  return nil;
	NSString *thisName = [NSString stringWithFormat:@"n%p", node];
	
	if (![seen member:thisName])
	{
		[seen addObject:thisName];
		
		if (level > 0)
		{
			InnerNode *innerNode = node;
			
			NSString *label = [ NSString stringWithFormat:@"%p level %u, size %lu", innerNode, level, size];
			if (InnerNodeIsShared(innerNode, level))
			{
				label = [label stringByAppendingFormat:@" [rc %lu]", GetInnerNodeRefCount(innerNode, level)];
			}
			[graphViz appendFormat:@"\t%@ [label=\"%@\"]\n", thisName, label];
			
			NSUInteger halfSize = size / 2;
			
			for (unsigned i = 0; i < 8; i++)
			{
				if (innerNode->children.inner[i] != NULL)
				{
					// Find extents of ith child.
					MCGridCoordinates subBase = base;
					if (i & 1) subBase.x += halfSize;
					if (i & 2) subBase.y += halfSize;
					if (i & 4) subBase.z += halfSize;
					
					NSString *subName = BuildGraphViz(innerNode->children.inner[i], level - 1, subBase, halfSize, graphViz, seen);
					
					[graphViz appendFormat:@"\t%@ -> %@\n", thisName, subName];
				}
			}
		}
		else
		{
			Chunk *chunk = node;
			NSString *label =[ NSString stringWithFormat:@"Node %p", chunk];
			if (ChunkIsShared(chunk))
			{
				label = [label stringByAppendingFormat:@" [rc %lu]", GetChunkRefCount(chunk)];
			}
			
			[graphViz appendFormat:@"\t%@ [shape=box label=\"%@\"]\n", thisName, label];
		}
	}
	
	return thisName;
}


- (NSString *) debugGraphViz
{
	NSMutableString *graphViz = [NSMutableString stringWithString:@"digraph schematic\n{\n\tnode [shape=ellipse]\n"];
	NSMutableSet *seen = [NSMutableSet set];
	
	NSInteger repDistance = RepresentedDistance(_rootLevel);
	MCGridCoordinates base = { -repDistance, -repDistance, -repDistance };
	NSUInteger size = repDistance * 2;
	
	BuildGraphViz(_root, _rootLevel, base, size, graphViz, seen);
	
	[graphViz appendString:@"}\n"];
	return graphViz;
}


- (void) writeDebugGraphVizToURL:(NSURL *)url
{
	[[self debugGraphViz] writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

#endif

@end


#if LOGGING
static NSUInteger sLiveInnerNodeCount = 0;
static NSUInteger sLiveChunkCount = 0;
#endif

#if TRACK_NODE_INSTANCES
static NSHashTable *sLiveInnerNodes = NULL;
static NSHashTable *sLiveChunks = NULL;
#endif


static id TileEntityKeyForCoords(MCGridCoordinates coords)
{
	return [NSString stringWithFormat:@"%lli,%lli,%lli", coords.x, coords.y, coords.z];
}


static inline off_t Offset(unsigned x, unsigned y, unsigned z)  __attribute__((const, always_inline));
static inline off_t Offset(unsigned x, unsigned y, unsigned z)
{
	return (y * kChunkSize + z) * kChunkSize + x;
}


static void ThrowMallocException(void) __attribute__((noreturn));
static void ThrowMallocException(void)
{
	[NSException raise:NSMallocException format:@"Out of memory"];
	__builtin_unreachable();
}


static void *AllocClearOrThrow(size_t size)
{
	void *result = calloc(size, 1);
	if (JA_EXPECT_NOT(result == NULL))  ThrowMallocException();
	return result;
}


static inline InnerNode *AllocInnerNode(NSUInteger level)
{
	InnerNode *result = AllocClearOrThrow(sizeof(InnerNode));
	
#if DEBUG_MCSCHEMATIC
	result-> tag = kTagInnerNode;
	result->level = level;
#endif
	
#if LOGGING
	sLiveInnerNodeCount++;
#endif
#if TRACK_NODE_INSTANCES
	if (sLiveInnerNodes == NULL)  sLiveInnerNodes = NSCreateHashTable(NSNonOwnedPointerHashCallBacks, 0);
	NSHashInsertKnownAbsent(sLiveInnerNodes, result);
#endif
	
	return result;
}


static Chunk *AllocChunk(void)
{
	Chunk *result = AllocClearOrThrow(sizeof(Chunk));
	
#if DEBUG_MCSCHEMATIC
	result-> tag = kTagChunk;
#endif
	
#if LOGGING
	sLiveChunkCount++;
#endif
#if TRACK_NODE_INSTANCES
	if (sLiveChunks == NULL)  sLiveChunks = NSCreateHashTable(NSNonOwnedPointerHashCallBacks, 0);
	NSHashInsertKnownAbsent(sLiveChunks, result);
#endif
	
	return result;
}


static Chunk *MakeChunk(NSInteger baseY, NSInteger groundLevel)
{
	Chunk *result = AllocChunk();
	
	if (baseY < groundLevel)
	{
		MCCell stoneCell = { kMCBlockSmoothStone, 0 };
		if (baseY + kChunkSize <= groundLevel)
		{
			FillCompleteChunk(result, stoneCell);
		}
		else
		{
			FillPartialChunk(result, stoneCell, (MCGridExtents){ 0, kChunkSize - 1, 0, groundLevel - baseY - 1, 0, kChunkSize - 1 });
		}
	}
	
	return result;
}


static inline void FreeInnerNode(InnerNode *node, NSUInteger level)
{
	NSCParameterAssert(node != NULL && node->tag == kTagInnerNode && node->level == level);
	
	Log(@"Freeing inner node %p [level %lu, live count -> %lu]", node, node->level, --sLiveInnerNodeCount);
	LogIndent();
	
#if TRACK_NODE_INSTANCES
	NSCAssert1(NSHashGet(sLiveInnerNodes, node) != NULL, @"Attempt to remove unknown inner node %p.", node);
	NSHashRemove(sLiveInnerNodes, node);
#endif
	
	for (unsigned i = 0; i < 8; i++)
	{
		if (node->children.inner[i] != NULL)
		{
			if (level == 1)  ReleaseChunk(node->children.leaves[i]);
			else  ReleaseInnerNode(node->children.inner[i], level - 1);
		}
	}
	
#if DEBUG_MCSCHEMATIC
	node->tag = kTagDeadInnerNode;
#endif
	
	free(node);
	
	LogOutdent();
}


static inline void FreeChunk(Chunk *chunk)
{
	NSCParameterAssert(chunk != NULL && chunk->tag == kTagChunk);
	
#if TRACK_NODE_INSTANCES
	NSCAssert1(NSHashGet(sLiveChunks, chunk) != NULL, @"Attempt to remove unknown chunk %p.", chunk);
	NSHashRemove(sLiveChunks, chunk);
#endif
	
	Log(@"Freeing chunk %p [live count -> %lu]", chunk, --sLiveChunkCount);
	
#if DEBUG_MCSCHEMATIC
	chunk->tag = kTagDeadChunk;
#endif
	
	free(chunk);
}


static InnerNode *COWInnerNode(InnerNode *node, NSUInteger level)
{
	NSCParameterAssert(node != NULL && node->tag == kTagInnerNode && level == node->level);
	node->refCountMinusOne++;
	return node;
}


static Chunk *COWChunk(Chunk *chunk)
{
	NSCParameterAssert(chunk != NULL && chunk->tag == kTagChunk);
	chunk->refCountMinusOne++;
	return chunk;
}


static InnerNode *CopyInnerNode(InnerNode *node, NSUInteger level)
{
	NSCParameterAssert(node != NULL && node->tag == kTagInnerNode && level == node->level);
	
	InnerNode *result = AllocInnerNode(level);
	if (JA_EXPECT_NOT(result == NULL))  return NULL;
	
	result->refCountMinusOne = 0;
#if DEBUG_MCSCHEMATIC
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
	NSCParameterAssert(chunk != NULL && chunk->tag == kTagChunk);
	
	Chunk *result = AllocChunk();
	if (JA_EXPECT_NOT(result == NULL))  return NULL;
	
	bcopy(chunk, result, sizeof *result);
	result->refCountMinusOne = 0;
	return result;
}


static inline NSUInteger GetInnerNodeRefCount(InnerNode *node, NSUInteger level)
{
	NSCParameterAssert(node != NULL && node->tag == kTagInnerNode && level == node->level);
	
	return node->refCountMinusOne + 1;
}


static inline NSUInteger GetChunkRefCount(Chunk *chunk)
{
	NSCParameterAssert(chunk != NULL && chunk->tag == kTagChunk);
	
	return chunk->refCountMinusOne + 1;
}


static inline BOOL InnerNodeIsShared(InnerNode *node, NSUInteger level)
{
	NSCParameterAssert(node != NULL && node->tag == kTagInnerNode && level == node->level);
	
	return node->refCountMinusOne > 0;
}


static inline BOOL ChunkIsShared(Chunk *chunk)
{
	NSCParameterAssert(chunk != NULL && chunk->tag == kTagChunk);
	
	return chunk->refCountMinusOne > 0;
}


static void ReleaseInnerNode(InnerNode *node, NSUInteger level)
{
	NSCParameterAssert(node != NULL && node->tag == kTagInnerNode && level == node->level);
	
	Log(@"Releasing inner node %p [refcount %lu->%lu, level %lu]", node, node->refCount, node->refCount - 1, node->level);
	LogIndent();
	
	if (node->refCountMinusOne-- == 0)
	{
		FreeInnerNode(node, level);
	}
	
	LogOutdent();
}


static void ReleaseChunk(Chunk *chunk)
{
	NSCParameterAssert(chunk != NULL && chunk->tag == kTagChunk);
	
	Log(@"Releasing chunk %p [refcount %u->%u]", chunk, chunk->refCount, chunk->refCount - 1);
	LogIndent();
	
	if (chunk->refCountMinusOne-- == 0)
	{
		FreeChunk(chunk);
	}
	
	LogOutdent();
}


static MCGridExtents ChunkGetExtents(Chunk *chunk, NSInteger baseY, NSInteger groundLevel)
{
	NSCParameterAssert(chunk != NULL && chunk->tag == kTagChunk);
	
	if (!chunk->extentsAreAccurate)
	{
		// Examine blocks to find extents.
		unsigned maxX = 0, minX = UINT_MAX;
		unsigned maxY = 0, minY = UINT_MAX;
		unsigned maxZ = 0, minZ = UINT_MAX;
		
		for (unsigned y = 0; y < kChunkSize; y++)
		{
			uint8_t emptyType = (baseY + y >= groundLevel) ? kMCBlockAir : kMCBlockSmoothStone;
			
			for (unsigned z = 0; z < kChunkSize; z++)
			{
				for (unsigned x = 0; x < kChunkSize; x++)
				{
					MCCell cell = chunk->cells[Offset(x, y, z)];
					if (cell.blockID != emptyType || cell.blockData != 0)
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


static inline MCCell ChunkGetCell(Chunk *chunk, NSInteger x, NSInteger y, NSInteger z)
{
	NSCParameterAssert(chunk != NULL && chunk->tag == kTagChunk &&
					   0 <= x && x < kChunkSize &&
					   0 <= y && y < kChunkSize &&
					   0 <= z && z < kChunkSize);
	
	return chunk->cells[Offset(x, y, z)];
}


static BOOL ChunkSetCell(Chunk *chunk, NSInteger x, NSInteger y, NSInteger z, MCCell cell)
{
	NSCParameterAssert(chunk != NULL && chunk->tag == kTagChunk && chunk->refCountMinusOne == 0 &&
					   0 <= x && x < kChunkSize &&
					   0 <= y && y < kChunkSize &&
					   0 <= z && z < kChunkSize);
	
	unsigned offset = Offset(x, y, z);
	if (MCCellsEqual(chunk->cells[offset], cell))  return NO;
	
	chunk->cells[offset] = cell;
	chunk->extentsAreAccurate = NO;
	return YES;
}


static void FillCompleteChunk(Chunk *chunk, MCCell cell)
{
	NSCParameterAssert(chunk != NULL && chunk->tag == kTagChunk && chunk->refCountMinusOne == 0);
	
	MCCell pattern[8] = { cell, cell, cell, cell, cell, cell, cell, cell };
	memset_pattern16(chunk->cells, &pattern, sizeof chunk->cells);
	
	chunk->extentsAreAccurate = NO;
}


static void FillPartialChunk(Chunk *chunk, MCCell cell, MCGridExtents extents)
{
	NSCParameterAssert(chunk != NULL && chunk->tag == kTagChunk && chunk->refCountMinusOne == 0);
	NSCParameterAssert(MCGridExtentsAreWithinExtents(extents, MCGridExtentsWithCoordinatesAndSize(kMCZeroCoordinates, kChunkSize, kChunkSize, kChunkSize)));
	
	for (unsigned y = extents.minY; y <= extents.maxY; y++)
	{
		for (unsigned z = extents.minZ; z <= extents.maxZ; z++)
		{
			for (unsigned x = extents.minX; x <= extents.maxX; x++)
			{
				chunk->cells[Offset(x, y, z)] = cell;
			}
		}
	}
	
	chunk->extentsAreAccurate = NO;
}


static void *COWNode(void *node, unsigned level)
{
	if (level == 0)  return COWChunk(node);
	else  return COWInnerNode(node, level);
}


static void ReleaseNode(void *node, unsigned level)
{
	if (level == 0)  ReleaseChunk(node);
	else  ReleaseInnerNode(node, level);
}


static NSUInteger GetNodeRefCount(void *node, unsigned level)
{
	if (node == NULL)  return 0;
	else if (level == 0)
	{
		return GetChunkRefCount(node);
	}
	else
	{
		return GetInnerNodeRefCount(node, level);
	}
}


#if TRACK_NODE_INSTANCES
#import "JAHashEnumeration.h"


extern void JAMCSchematicDump(void);
extern void JAMCSchematicDump(void)
{
	DoLog(@"JAMinecraftSchematic debug dump:");
	DoLogIndent();
	NSUInteger count = (sLiveInnerNodes != NULL) ? NSCountHashTable(sLiveInnerNodes) : 0;
	__block NSUInteger i = 0;
	
#if LOGGING
	if (count == sLiveInnerNodeCount)
	{
		DoLog(@"Inner nodes: %lu live.", count);
	}
	else
	{
		DoLog(@"***** INCONSISTENCY: %lu inner nodes in live nodes hash, %lu counted. *****", count, sLiveInnerNodeCount);
	}
#else
	DoLog(@"Inner nodes: %lu live.", count);
#endif
	
	if (sLiveInnerNodes != NULL)
	{
		DoLogIndent();
		JAHashTableEnumerate(sLiveInnerNodes, ^(void *item) {
			InnerNode *node = item;
			if (node->tag == kTagInnerNode)
			{
				DoLog(@"Inner node %lu: %p [level = %u, refcount = %u]", i++, node, node->level, GetInnerNodeRefCount(node, node->level));
			}
			else
			{
				NSString *desc;
				if (node->tag == kTagDeadInnerNode)  desc = @"released";
				else if (node->tag == kTagChunk)  desc = @"chunk";
				else if (node->tag == kTagDeadChunk)  desc = @"released chunk";
				else  desc = @"unknown reference";
				DoLog(@"Inner node %lu: %p - ***** INVALID - %@", i++, node, desc);
			}
		});
		DoLogOutdent();
	}
	
	i = 0;
	count = (sLiveChunks != NULL) ? NSCountHashTable(sLiveChunks) : 0;
	
#if LOGGING
	if (count == sLiveChunkCount)
	{
		DoLog(@"Chunks: %lu live.", count);
	}
	else
	{
		DoLog(@"***** INCONSISTENCY: %lu chunks in live chunks hash, %lu counted. *****", count, sLiveChunkCount);
	}
#else
	DoLog(@"Chunks: %lu live.", count);
#endif
	
	if (sLiveChunks != NULL)
	{
		DoLogIndent();
		JAHashTableEnumerate(sLiveChunks, ^(void *item) {
			Chunk *chunk = item;
			if (chunk->tag == kTagChunk)
			{
				DoLog(@"Chunk %lu: %p [refcount = %u]", i++, chunk, GetChunkRefCount(chunk));
			}
			else
			{
				NSString *desc;
				if (chunk->tag == kTagDeadChunk)  desc = @"released";
				else if (chunk->tag == kTagInnerNode)  desc = @"inner node";
				else if (chunk->tag == kTagDeadInnerNode)  desc = @"released inner node";
				else  desc = @"unknown reference";
				DoLog(@"Chunk %lu: %p - ***** INVALID - %@", i++, chunk, desc);
			}
		});
		DoLogOutdent();
	}
	
	DoLogOutdent();
}
#endif


#if LOGGING || TRACK_NODE_INSTANCES
static NSString *sLogIndentation = @"";


static void DoLog(NSString *format, ...)
{
	va_list args;
	va_start(args, format);
	NSString *message = [sLogIndentation stringByAppendingString:[[NSString alloc] initWithFormat:format arguments:args]];
	va_end(args);
	
	printf("%s\n", [message UTF8String]);
}


static void DoLogIndent(void)
{
	sLogIndentation = [sLogIndentation stringByAppendingString:@"  "];
}


static void DoLogOutdent(void)
{
	if (sLogIndentation.length > 1)  sLogIndentation = [sLogIndentation substringFromIndex:2];
}
#endif
