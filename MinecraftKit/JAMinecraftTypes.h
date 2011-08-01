/*
	JAMinecraftTypes.h
	
	Basic types for dealing with Minecraft data, biased towards redstone stuff.
	
	
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

#import <Foundation/Foundation.h>

#include "JAMinecraftBlockIDs.h"

#ifndef JA_CONST_FUNC
#define JA_CONST_FUNC __attribute__((const))
#endif

#ifndef JA_EXPECT
#define JA_EXPECT(x) __builtin_expect((x), 1)
#endif

#ifndef JA_EXPECT_NOT
#define JA_EXPECT_NOT(x) __builtin_expect((x), 0)
#endif


#pragma mark MCCell
/***** MCCell *****
 *	A single cell of a map or schematic.
 *	Conceptually, a cell is a location which contains a block. Alternatively,
 *	you can think of “cell” as a pointless and redundant synonym of “block”
 *	if you prefer.
 *	
 *	A more heavyweight MCBlock class with both “cell” data and tile entity (if
 *	relevant) may be added at a later date. Adding tile entities to MCCell
 *	would be bad because object references in structs aren’t/won’t be supported
 *	in ARC.
 */

typedef struct MCCell
{
	/*	Block IDs and block data straight from Minecraft.
		See JAMinecraftBlockIDs.h and http://www.minecraftwiki.net/wiki/Data_values
	*/
	uint8_t					blockID;
	uint8_t					blockData;
} MCCell;


extern const MCCell kMCAirCell;
extern const MCCell kMCHoleCell;	// Air cell with kMCInfoAirIsHoleMask flag set.
extern const MCCell kMCStoneCell;

static inline BOOL MCCellsEqual(MCCell a, MCCell b) JA_CONST_FUNC;


/*
	Determine the expected tile entity type ID for a given block ID.
	Returns "?" for unknown block types, nil for non-tileentity types.
*/
NSString *MCExpectedTileEntityTypeForBlockID(uint8_t blockID) JA_CONST_FUNC;

// Test whether a given tile entity and cell are of compatible types.
BOOL MCTileEntityIsCompatibleWithCell(NSDictionary *tileEntity, MCCell cell) JA_CONST_FUNC;

// As above, but throws NSInvalidArgumentException if not compatible.
void MCRequireTileEntityIsCompatibleWithCell(NSDictionary *tileEntity, MCCell cell) JA_CONST_FUNC;


//	Convenience predicates and info extractors.
static inline BOOL MCCellIsFullySolid(MCCell cell) JA_CONST_FUNC;
static inline BOOL MCCellIsQuasiSolid(MCCell cell) JA_CONST_FUNC;
static inline BOOL MCCellIsSolid(MCCell cell) JA_CONST_FUNC;
static inline BOOL MCCellIsLiquid(MCCell cell) JA_CONST_FUNC;
static inline BOOL MCCellIsItem(MCCell cell) JA_CONST_FUNC;
static inline BOOL MCCellIsAir(MCCell cell) JA_CONST_FUNC;
static inline BOOL MCCellIsHole(MCCell cell) JA_CONST_FUNC;
static inline BOOL MCCellIsPowerSource(MCCell cell) JA_CONST_FUNC;
static inline BOOL MCCellIsPowerSink(MCCell cell) JA_CONST_FUNC;
static inline BOOL MCCellIsPowerActive(MCCell cell) JA_CONST_FUNC;
static inline BOOL MCCellIsVegetable(MCCell cell) JA_CONST_FUNC;
static inline BOOL MCCellIsRedstoneTorch(MCCell cell) JA_CONST_FUNC;

// Power level (0-15) for wires only - 0 for power sources.
static inline uint8_t MCWirePowerLevel(MCCell cell) JA_CONST_FUNC;


#pragma mark MCGridCoordinates
/***** MCGridCoordinates *****
 *	A grid location.
 *
 *	The Minecraft coordinate system is right-handed and based on the
 *	perspective of a character looking due east:
 *	
 *	+x is south, -x is north.
 *	+y is up, -y is down.
 *	+z is west, -z is east.
 */

typedef struct
{
	NSInteger				x, y, z;
} MCGridCoordinates;


extern const MCGridCoordinates kMCZeroCoordinates;

static inline BOOL MCGridCoordinatesEqual(MCGridCoordinates a, MCGridCoordinates b) JA_CONST_FUNC;


#pragma mark MCGridExtents
/***** MCGridExtents *****
 *	A three-dimensional range of cell coordinates, describing a cuboid.
 *	
 *	If any max value is less than its corresponding min value, the extents are
 *	considered empty. The constant kMCEmptyExtents describes the extreme case:
 *	all min values are NSIntegerMax and all max values are NSIntegerMin.
 *	
 *	kMCInfiniteExtents is the inverse: all min values are MSIntegerMin and all
 *	max values are NSIntegerMax.
 *	
 *	“Width” refers to an x range, “length” a z range and “height” a y range.
 */

typedef struct
{
	NSInteger				minX, maxX,
							minY, maxY,
							minZ, maxZ;
} MCGridExtents;


extern const MCGridExtents kMCEmptyExtents;
extern const MCGridExtents kMCZeroExtents;
extern const MCGridExtents kMCInfiniteExtents;


static BOOL MCGridExtentsEmpty(MCGridExtents extents) JA_CONST_FUNC;

static BOOL MCGridExtentsEqual(MCGridExtents a, MCGridExtents b) JA_CONST_FUNC;

static NSUInteger MCGridExtentsWidth(MCGridExtents extents) JA_CONST_FUNC;
static NSUInteger MCGridExtentsLength(MCGridExtents extents) JA_CONST_FUNC;
static NSUInteger MCGridExtentsHeight(MCGridExtents extents) JA_CONST_FUNC;


/*
	MCGridExtentsMinimum() and MCGridExtentsMaximum()
	Return minimum and maximum points of a MCGridExtents.
	These do not attempt to handle empty extents, where the concepts of
	minimum and maximum points are meaningless.
*/
static inline MCGridCoordinates MCGridExtentsMinimum(MCGridExtents extents) JA_CONST_FUNC;
static inline MCGridCoordinates MCGridExtentsMaximum(MCGridExtents extents) JA_CONST_FUNC;

/*
	MCGridExtentsWithCoordinates(MCGridCoordinates coords)
	Returns an extents struct encompassing a single cell at the specified
	coordinates.
 */
static MCGridExtents MCGridExtentsWithCoordinates(MCGridCoordinates coords) JA_CONST_FUNC;
static MCGridExtents MCGridExtentsWithCoordinatesAndSize(MCGridCoordinates coords, NSUInteger sizeX, NSUInteger sizeY, NSUInteger sizeZ) JA_CONST_FUNC;

static BOOL MCGridCoordinatesAreWithinExtents(MCGridCoordinates coords, MCGridExtents extents) JA_CONST_FUNC;
BOOL MCGridExtentsAreWithinExtents(MCGridExtents inner, MCGridExtents outer) JA_CONST_FUNC;

/*
	MCGridExtentsUnion(MCGridExtents a, MCGridExtents b)
	Returns an extents containing all coordinates described by either a or b,
	as well as any additional coordinates required to produce a cuboid.
	
	MCGridExtentsUnionWithCoordinates(MCGridExtents extents, MCGridCoordinates coords)
	Equivalent to MCGridExtentsUnion(extents, MCGridExtentsWithCoordinates(coords)).
*/
MCGridExtents MCGridExtentsUnion(MCGridExtents a, MCGridExtents b) JA_CONST_FUNC;
MCGridExtents MCGridExtentsUnionWithCoordinates(MCGridExtents extents, MCGridCoordinates coords) JA_CONST_FUNC;

/*
	MCGridExtentsIntersect(MCGridExtents a, MCGridExtents b)
	YES if a and b overlap.
*/
BOOL MCGridExtentsIntersect(MCGridExtents a, MCGridExtents b) JA_CONST_FUNC;

/*
	MCGridExtentsIntersection(MCGridExtents a, MCGridExtents b)
	Returns the extents contained by both a and b.
*/
MCGridExtents MCGridExtentsIntersection(MCGridExtents a, MCGridExtents b) JA_CONST_FUNC;


#pragma mark MCDirection
/***** MCDirection *****
 *	A cardinal direction.
 */
typedef enum
{
	kMCDirectionNorth,
	kMCDirectionSouth,
	kMCDirectionEast,
	kMCDirectionWest,
	kMCDirectionUp,
	kMCDirectionDown,
	
	kMCDirectionUnknown
} MCDirection;


/*
	Generalized handling of orientable cells. These functions encode and
	decode the various orientation representations used by different block types.
	Caveats:
	* For levers, there are two possible floor orientations, which are both
	  reported as kMCDirectionDown. MCCellSetOrientation() will preserve the
	  distinction. The MCRotateCell[Anti]Clockwise() functions will rotate
	  floor levers as a special case.
	  NOTE: prior to beta 1.6, the two floor lever orientations worked
	  differently, but this has been fixed.
	* Minecart tracks aren’t handled, since their orientation concepts are
	  special.
	
	MCCellSetOrientation() has no effect on non-orientable blocks. Invalid
	values will be mapped to down or north.
*/
MCDirection MCCellGetOrientation(MCCell cell) JA_CONST_FUNC;
void MCCellSetOrientation(MCCell *cell, MCDirection orientation);


/*
	The following utility functions are inlined (in release builds) if the
	JACellDirection parameter is known at compile time, otherwise out of line.
	Only use the commented forms directly.
*/


#if NDEBUG
#define INLINEABLE_DIRECTION(d)  (__builtin_constant_p(d) && d <= kMCDirectionUnknown)
#else
#define INLINEABLE_DIRECTION(d)  0
#endif


/*
	MCStepCoordinates(MCGridCoordinates coords, MCDirection direction)
	Increment the coordinates one step in the specified direction.
*/
#define MCStepCoordinates(loc, dir)  (INLINEABLE_DIRECTION(dir) ? MCStepCoordinatesBody(loc, dir) : MCStepCoordinatesFunc(loc, dir))
static inline MCGridCoordinates MCStepCoordinatesBody(MCGridCoordinates coords, MCDirection direction) JA_CONST_FUNC;
MCGridCoordinates MCStepCoordinatesFunc(MCGridCoordinates coords, MCDirection direction) JA_CONST_FUNC;


/*
	MCCoordinatesNorthOf(MCGridCoordinates coords)
	MCCoordinatesSouthOf(MCGridCoordinates coords)
	MCCoordinatesEastOf(MCGridCoordinates coords)
	MCCoordinatesWestOf(MCGridCoordinates coords)
	MCCoordinatesAbove(MCGridCoordinates coords)
	MCCoordinatesBelow(MCGridCoordinates coords)
	
	Constant steps in each of the six cardinal directions.
*/
static inline MCGridCoordinates MCCoordinatesNorthOf(MCGridCoordinates coords) JA_CONST_FUNC;
static inline MCGridCoordinates MCCoordinatesSouthOf(MCGridCoordinates coords) JA_CONST_FUNC;
static inline MCGridCoordinates MCCoordinatesEastOf(MCGridCoordinates coords) JA_CONST_FUNC;
static inline MCGridCoordinates MCCoordinatesWestOf(MCGridCoordinates coords) JA_CONST_FUNC;
static inline MCGridCoordinates MCCoordinatesAbove(MCGridCoordinates coords) JA_CONST_FUNC;
static inline MCGridCoordinates MCCoordinatesBelow(MCGridCoordinates coords) JA_CONST_FUNC;


/*
	MCDirection MCDirectionFlip(MCDirection direction)
	Reverse a direction.
*/
#define MCDirectionFlip(dir)  (INLINEABLE_DIRECTION(dir) ? MCDirectionFlipBody(dir) : MCDirectionFlipFunc(dir))
static inline MCDirection MCDirectionFlipBody(MCDirection direction) JA_CONST_FUNC;
MCDirection MCDirectionFlipFunc(MCDirection direction) JA_CONST_FUNC;


/*
	MCDirection MCDirectionFlipNorthSouth(MCDirection direction)
	Reverse a direction if it is north or south.
*/
#define MCDirectionFlipNorthSouth(dir)  (INLINEABLE_DIRECTION(dir) ? MCDirectionFlipNorthSouthBody(dir) : MCDirectionFlipNorthSouthFunc(dir))
static inline MCDirection MCDirectionFlipNorthSouthBody(MCDirection direction) JA_CONST_FUNC;
MCDirection MCDirectionFlipNorthSouthFunc(MCDirection direction) JA_CONST_FUNC;


/*
	MCDirection MCDirectionFlipEastWest(MCDirection direction)
	Reverse a direction if it is east or west.
*/
#define MCDirectionFlipEastWest(dir)  (INLINEABLE_DIRECTION(dir) ? MCDirectionFlipEastWestBody(dir) : MCDirectionFlipEastWestFunc(dir))
static inline MCDirection MCDirectionFlipEastWestBody(MCDirection direction) JA_CONST_FUNC;
MCDirection MCDirectionFlipEastWestFunc(MCDirection direction) JA_CONST_FUNC;


/*
	MCDirection MCDirectionFlipUpDown(MCDirection direction)
	Reverse a direction if it is up or down.
*/
#define MCDirectionFlipUpDown(dir)  (INLINEABLE_DIRECTION(dir) ? MCDirectionFlipUpDownBody(dir) : MCDirectionFlipUpDownFunc(dir))
static inline MCDirection MCDirectionFlipUpDownBody(MCDirection direction) JA_CONST_FUNC;
MCDirection MCDirectionFlipUpDownFunc(MCDirection direction) JA_CONST_FUNC;

/*
	MCDirection MCRotateClockwise(MCDirection direction)
	Rotates a direction 90° clockwise. Has no effect on up or down directions.
*/
#define MCRotateClockwise(dir)  (INLINEABLE_DIRECTION(dir) ? MCRotateClockwiseBody(dir) : MCRotateClockwiseFunc(dir))
static inline MCDirection MCRotateClockwiseBody(MCDirection direction) JA_CONST_FUNC;
MCDirection MCRotateClockwiseFunc(MCDirection direction) JA_CONST_FUNC;

/*
	MCDirection MCRotateAntiClockwise(MCDirection direction)
	Rotates a direction 90° anticlockwise. Has no effect on up or down directions.
*/
#define MCRotateAntiClockwise(dir)  (INLINEABLE_DIRECTION(dir) ? MCRotateClockwiseBody(MCDirectionFlipBody(dir)) : MCRotateAntiClockwiseFunc(dir))
MCDirection MCRotateAntiClockwiseFunc(MCDirection direction) JA_CONST_FUNC;



/*
	Rotation functions for rails.
	
	Rail orientations work too differently from other orientations to be
	usefully expressed as MCDirections. These functions deal with them.
	They requre their input to be a blockData value for a rail block, masked
	with kMCInfoRailOrientationMask or kMCInfoPoweredRailOrientationMask as
	appropriate.
	
	uint8_t MCRotateRailDataClockwise(uint8_t railBlockData)
	Rotate the blockData for a rail segment 90° clockwise.
	
	uint8_t MCFlipRailDataHorizontal(uint8_t railBlockData)
	Flip a rail’s orientation from east to west.
*/

uint8_t MCRotateRailDataClockwise(uint8_t railBlockData);
uint8_t MCFlipRailEastWest(uint8_t railBlockData);


/*
	General cell rotation and flipping.
	
	These functions work for both MCDirection-compliant types and rails. For
	cells with no orientation, they do nothing.
 */
MCCell MCRotateCellClockwise(MCCell cell);
MCCell MCRotateCellAntiClockwise(MCCell cell);
MCCell MCRotateCell180Degrees(MCCell cell);
MCCell MCFlipCellEastWest(MCCell cell);
MCCell MCFlipCellNorthSouth(MCCell cell);


/****** Inline function bodies only beyond this point. ******/

static inline BOOL MCCellsEqual(MCCell a, MCCell b)
{
	return a.blockID == b.blockID && a.blockData == b.blockData;
}


static inline BOOL MCCellIsFullySolid(MCCell cell)
{
	return MCBlockIDIsFullySolid(cell.blockID);
}


static inline BOOL MCCellIsQuasiSolid(MCCell cell)
{
	return MCBlockIDIsQuasiSolid(cell.blockID);
}


static inline BOOL MCCellIsSolid(MCCell cell)
{
	return MCBlockIDIsSolid(cell.blockID);
}


static inline BOOL MCCellIsLiquid(MCCell cell)
{
	return MCBlockIDIsLiquid(cell.blockID);
}


static inline BOOL MCCellIsItem(MCCell cell)
{
	return MCBlockIDIsItem(cell.blockID);
}


static inline BOOL MCCellIsAir(MCCell cell)
{
	return MCBlockIDIsAir(cell.blockID);
}


static inline BOOL MCCellIsHole(MCCell cell)
{
	return MCBlockIDIsAir(cell.blockID) && cell.blockData & kMCInfoAirIsHoleMask;
}


static inline BOOL MCCellIsPowerSource(MCCell cell)
{
	return MCBlockIDIsPowerSource(cell.blockID);
}


static inline BOOL MCCellIsPowerSink(MCCell cell)
{
	return MCBlockIDIsPowerSink(cell.blockID);
}


static inline BOOL MCCellIsPowerActive(MCCell cell)
{
	return MCBlockIDIsPowerActive(cell.blockID);
}


static inline BOOL MCCellIsVegetable(MCCell cell)
{
	return MCBlockIDIsVegetable(cell.blockID);
}


static inline BOOL MCCellIsRedstoneTorch(MCCell cell)
{
	return MCBlockIDIsRedstoneTorch(cell.blockID);
}


static inline uint8_t MCWirePowerLevel(MCCell cell)
{
	return (cell.blockID == kMCBlockRedstoneWire) ? (cell.blockData & kMCInfoRedstoneWireSignalStrengthMask) : 0;
}


static inline BOOL MCGridCoordinatesEqual(MCGridCoordinates a, MCGridCoordinates b)
{
	return a.x == b.x && a.y == b.y && a.z == b.z;
}


static NSUInteger MCGridExtentsWidth(MCGridExtents extents)
{
	if (!MCGridExtentsEmpty(extents))  return extents.maxX - extents.minX + 1;
	else return 0;
}


static NSUInteger MCGridExtentsLength(MCGridExtents extents)
{
	if (!MCGridExtentsEmpty(extents))  return extents.maxZ - extents.minZ + 1;
	else return 0;
}


static NSUInteger MCGridExtentsHeight(MCGridExtents extents)
{
	if (!MCGridExtentsEmpty(extents))  return extents.maxY - extents.minY + 1;
	else return 0;
}


static MCGridExtents MCGridExtentsOffset(MCGridExtents extents, NSInteger dx, NSInteger dy, NSInteger dz)
{
	extents.minX += dx;
	extents.maxX += dx;
	extents.minY += dy;
	extents.maxY += dy;
	extents.minZ += dz;
	extents.maxZ += dz;
	return extents;
}


static BOOL MCGridExtentsEmpty(MCGridExtents extents)
{
	return	extents.maxX < extents.minX ||
	extents.maxY < extents.minY ||
	extents.maxZ < extents.minZ;
}


static BOOL MCGridExtentsEqual(MCGridExtents a, MCGridExtents b)
{
	return a.minX == b.minX &&
	a.maxX == b.maxX &&
	a.minY == b.minY &&
	a.maxY == b.maxY &&
	a.minZ == b.minZ &&
	a.maxZ == b.maxZ;
}


static inline MCGridCoordinates MCGridExtentsMinimum(MCGridExtents extents)
{
	return (MCGridCoordinates){ extents.minX, extents.minY, extents.minZ };
}


static inline MCGridCoordinates MCGridExtentsMaximum(MCGridExtents extents)
{
	return (MCGridCoordinates){ extents.maxX, extents.maxY, extents.maxZ };
}


static MCGridExtents MCGridExtentsWithCoordinates(MCGridCoordinates coords)
{
	return (MCGridExtents)
	{
		coords.x, coords.x,
		coords.y, coords.y,
		coords.z, coords.z
	};
}


static MCGridExtents MCGridExtentsWithCoordinatesAndSize(MCGridCoordinates coords, NSUInteger sizeX, NSUInteger sizeY, NSUInteger sizeZ)
{
	return (MCGridExtents)
	{
		coords.x, coords.x + sizeX - 1,
		coords.y, coords.y + sizeY - 1,
		coords.z, coords.z + sizeZ - 1
	};
}


static BOOL MCGridCoordinatesAreWithinExtents(MCGridCoordinates location, MCGridExtents extents)
{
	return	extents.minX <= location.x && location.x <= extents.maxX &&
	extents.minY <= location.y && location.y <= extents.maxY &&
	extents.minZ <= location.z && location.z <= extents.maxZ;
}


static inline MCGridCoordinates MCStepCoordinatesBody(MCGridCoordinates coords, MCDirection direction)
{
	switch (direction)
	{
		case kMCDirectionNorth:
			coords.x -= 1;
			break;
			
		case kMCDirectionSouth:
			coords.x += 1;
			break;
			
		case kMCDirectionEast:
			coords.z -= 1;
			break;
			
		case kMCDirectionWest:
			coords.z += 1;
			break;
			
		case kMCDirectionUp:
			coords.y += 1;
			break;
			
		case kMCDirectionDown:
			coords.y -= 1;
			break;
			
		case kMCDirectionUnknown:
			break;
	}
	
	return coords;
}


static inline MCGridCoordinates MCCoordinatesNorthOf(MCGridCoordinates coords)
{
	return MCStepCoordinatesBody(coords, kMCDirectionNorth);
}


static inline MCGridCoordinates MCCoordinatesSouthOf(MCGridCoordinates coords)
{
	return MCStepCoordinatesBody(coords, kMCDirectionSouth);
}


static inline MCGridCoordinates MCCoordinatesEastOf(MCGridCoordinates coords)
{
	return MCStepCoordinatesBody(coords, kMCDirectionEast);
}


static inline MCGridCoordinates MCCoordinatesWestOf(MCGridCoordinates coords)
{
	return MCStepCoordinatesBody(coords, kMCDirectionWest);
}


static inline MCGridCoordinates MCCoordinatesAbove(MCGridCoordinates coords)
{
	return MCStepCoordinatesBody(coords, kMCDirectionUp);
}


static inline MCGridCoordinates MCCoordinatesBelow(MCGridCoordinates coords)
{
	return MCStepCoordinatesBody(coords, kMCDirectionDown);
}


static inline MCDirection MCDirectionFlipBody(MCDirection direction)
{
	switch (direction)
	{
		case kMCDirectionNorth:
			return kMCDirectionSouth;
			
		case kMCDirectionSouth:
			return kMCDirectionNorth;
			
		case kMCDirectionEast:
			return kMCDirectionWest;
			
		case kMCDirectionWest:
			return kMCDirectionEast;
			
		case kMCDirectionUp:
			return kMCDirectionDown;
			
		case kMCDirectionDown:
			return kMCDirectionUp;
			
		case kMCDirectionUnknown:
			break;
	}
	return kMCDirectionUnknown;
}


static inline MCDirection MCDirectionFlipNorthSouthBody(MCDirection direction)
{
	switch (direction)
	{
		case kMCDirectionNorth:
			return kMCDirectionSouth;
			
		case kMCDirectionSouth:
			return kMCDirectionNorth;
			
		default:
			return direction;
	}
}


static inline MCDirection MCDirectionFlipEastWestBody(MCDirection direction)
{
	switch (direction)
	{
		case kMCDirectionEast:
			return kMCDirectionWest;
			
		case kMCDirectionWest:
			return kMCDirectionEast;
			
		default:
			return direction;
	}
}


static inline MCDirection MCDirectionFlipUpDownBody(MCDirection direction)
{
	switch (direction)
	{
		case kMCDirectionUp:
			return kMCDirectionDown;
			
		case kMCDirectionDown:
			return kMCDirectionUp;
			
		default:
			return direction;
	}
}


static inline MCDirection MCRotateClockwiseBody(MCDirection direction)
{
	switch (direction)
	{
		case kMCDirectionNorth:
			return kMCDirectionEast;
			
		case kMCDirectionSouth:
			return kMCDirectionWest;
			
		case kMCDirectionEast:
			return kMCDirectionSouth;
			
		case kMCDirectionWest:
			return kMCDirectionNorth;
			
		case kMCDirectionUp:
		case kMCDirectionDown:
		case kMCDirectionUnknown:
			break;
	}
	
	return kMCDirectionUnknown;
}
