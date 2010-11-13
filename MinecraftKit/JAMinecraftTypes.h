/*
	JAMinecraftTypes.h
	
	Basic types for dealing with Minecraft data, biased towards redstone stuff.
	
	
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

#import <Foundation/Foundation.h>

#include "JAMinecraftBlockIDs.h"

#ifndef JA_CONST_FUNC
#define JA_CONST_FUNC __attribute__((const))
#endif


#pragma mark JAMinecraftCell
/***** JAMinecraftCell *****
 *	A single cell of a map or schematic.
 *	Conceptually, a cell is a location which contains a block. Alternatively,
 *	you can think of “cell” as a pointless and redundant synonym of “block”
 *	if you prefer.
 */

typedef struct JAMinecraftCell
{
	/*	Block IDs and block data straight from Minecraft.
		See JAMinecraftBlockIDs.h and http://www.minecraftwiki.net/wiki/Data_values
	*/
	uint8_t					blockID;
	uint8_t					blockData;
} JAMinecraftCell;


extern const JAMinecraftCell kJAEmptyCell;

//	Convenience predicates and info extractors.
static inline BOOL MCCellIsFullySolid(JAMinecraftCell cell) JA_CONST_FUNC;
static inline BOOL MCCellIsQuasiSolid(JAMinecraftCell cell) JA_CONST_FUNC;
static inline BOOL MCCellIsSolid(JAMinecraftCell cell) JA_CONST_FUNC;
static inline BOOL MCCellIsLiquid(JAMinecraftCell cell) JA_CONST_FUNC;
static inline BOOL MCCellIsItem(JAMinecraftCell cell) JA_CONST_FUNC;
static inline BOOL MCCellIsAir(JAMinecraftCell cell) JA_CONST_FUNC;
static inline BOOL MCCellIsPowerSource(JAMinecraftCell cell) JA_CONST_FUNC;
static inline BOOL MCCellIsPowerSink(JAMinecraftCell cell) JA_CONST_FUNC;
static inline BOOL MCCellIsPowerActive(JAMinecraftCell cell) JA_CONST_FUNC;
static inline BOOL MCCellIsVegetable(JAMinecraftCell cell) JA_CONST_FUNC;
static inline BOOL MCCellIsRedstoneTorch(JAMinecraftCell cell) JA_CONST_FUNC;

// Power level (0-15) for wires only - 0 for power sources.
static inline uint8_t MCWirePowerLevel(JAMinecraftCell cell) JA_CONST_FUNC;


#pragma mark JACellLocation
/***** JACellLocation *****
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
} JACellLocation;


extern const JACellLocation kJAZeroLocation;

static inline BOOL JACellLocationEqual(JACellLocation a, JACellLocation b) JA_CONST_FUNC;


#pragma mark JACircuitExtents
/***** JACircuitExtents *****
 *	A three-dimensional range of cell locations, describing a cuboid.
 *	
 *	If any max value is less than its corresponding min value, the extents are
 *	considered empty. The constant kJAEmptyExtents describes the extreme case:
 *	all min values are NSIntegerMax and all max values are NSIntegerMin.
 *	
 *	kJAInfiniteExtents is the inverse: all min values are MSIntegerMin and all
 *	max values are NSIntegerMax.
 *	
 *	“Width” refers to an x range, “length” a z range and “height” a y range.
 */

typedef struct
{
	NSInteger				minX, maxX,
							minY, maxY,
							minZ, maxZ;
} JACircuitExtents;


extern const JACircuitExtents kJAEmptyExtents;
extern const JACircuitExtents kJAZeroExtents;
extern const JACircuitExtents kJAInfiniteExtents;


BOOL JACircuitExtentsEmpty(JACircuitExtents extents) JA_CONST_FUNC;

BOOL JACircuitExtentsEqual(JACircuitExtents a, JACircuitExtents b) JA_CONST_FUNC;

static NSUInteger JACircuitExtentsWidth(JACircuitExtents extents) JA_CONST_FUNC;
static NSUInteger JACircuitExtentsLength(JACircuitExtents extents) JA_CONST_FUNC;
static NSUInteger JACircuitExtentsHeight(JACircuitExtents extents) JA_CONST_FUNC;


/*
	JACircuitExtentsMin() and JACircuitExtentsMax()
	Return minimum and maximum points of a JACircuitExtents.
	These do not attempt to handle empty extents, where the concepts of
	minimum and maximum points are meaningless.
*/
static inline JACellLocation JACircuitExtentsMin(JACircuitExtents extents) JA_CONST_FUNC;
static inline JACellLocation JACircuitExtentsMax(JACircuitExtents extents) JA_CONST_FUNC;

/*
	JACircuitExtentsWithLocation(JACellLocation location)
	Returns an extents containing a single location.
*/
static JACircuitExtents JACircuitExtentsWithLocation(JACellLocation location) JA_CONST_FUNC;

BOOL JACellLocationWithinExtents(JACellLocation location, JACircuitExtents extents) JA_CONST_FUNC;

/*
	JAExtentsUnion(JACircuitExtents a, JACircuitExtents b)
	Returns an extents containing all locations described by either a or b,
	as well as any additional locations required to produce a cuboid.
	
	JAExtentsUnionLocation(JACircuitExtents extents, JACellLocation location)
	Equivalent to JAExtentsUnion(extents, JACircuitExtentsWithLocation(location)).
*/
JACircuitExtents JAExtentsUnion(JACircuitExtents a, JACircuitExtents b) JA_CONST_FUNC;
JACircuitExtents JAExtentsUnionLocation(JACircuitExtents extents, JACellLocation location) JA_CONST_FUNC;

/*
	JAExtentsIntersection(JACircuitExtents a, JACircuitExtents b)
	Returns the extents contained by both a and b.
*/
JACircuitExtents JAExtentsIntersection(JACircuitExtents a, JACircuitExtents b) JA_CONST_FUNC;


#pragma mark JADirection
/***** JADirection *****
 *	A cardinal direction.
 */
typedef enum
{
	kJADirectionNorth,
	kJADirectionSouth,
	kJADirectionEast,
	kJADirectionWest,
	kJADirectionUp,
	kJADirectionDown,
	
	kJADirectionUnknown
} JADirection;


/*
	Generalized handling of orientable cells. These functions encode and
	decode the various orientation representations used by different block types.
	Caveats:
	* For levers, there are two possible floor orientations, which are both
	  reported as kJADirectionDown. East/west levers and north/south levers
	  provide power in different ways. Code dealing with power propagation
	  will need to examine the block data directly.
	  MCCellSetOrientation() will preserve the distinction.
	* Minecart tracks aren’t handled, since their orientation concepts are
	  special.
	
	MCCellSetOrientation() has no effect on non-orientable blocks. Invalid
	values will be mapped to down or north.
*/
JADirection MCCellGetOrientation(JAMinecraftCell cell) JA_CONST_FUNC;
void MCCellSetOrientation(JAMinecraftCell *cell, JADirection orientation);


/*
	The following utility functions are inlined (in release builds) if the
	JACellDirection parameter is known at compile time, otherwise out of line.
	Only use the commented forms directly.
*/


#if NDEBUG
#define INLINEABLE_DIRECTION(d)  (__builtin_constant_p(d) && d <= kJADirectionUnknown)
#else
#define INLINEABLE_DIRECTION(d)  0
#endif


/*
	JAStepCellLocation(JACellLocation location, JADirection direction)
	Move the location one step in the specified direction.
*/
#define JAStepCellLocation(loc, dir)  (INLINEABLE_DIRECTION(dir) ? JAStepCellLocationBody(loc, dir) : JAStepCellLocationFunc(loc, dir))
static inline JACellLocation JAStepCellLocationBody(JACellLocation location, JADirection direction) JA_CONST_FUNC;
JACellLocation JAStepCellLocationFunc(JACellLocation location, JADirection direction) JA_CONST_FUNC;


/*
	JACellNorth(JACellLocation location)
	JACellSouth(JACellLocation location)
	JACellEast(JACellLocation location)
	JACellWest(JACellLocation location)
	JACellAbove(JACellLocation location)
	JACellBelow(JACellLocation location)
	
	Constant steps in each of the six cardinal directions.
*/
static inline JACellLocation JACellNorth(JACellLocation location) JA_CONST_FUNC;
static inline JACellLocation JACellSouth(JACellLocation location) JA_CONST_FUNC;
static inline JACellLocation JACellEast(JACellLocation location) JA_CONST_FUNC;
static inline JACellLocation JACellWest(JACellLocation location) JA_CONST_FUNC;
static inline JACellLocation JACellAbove(JACellLocation location) JA_CONST_FUNC;
static inline JACellLocation JACellBelow(JACellLocation location) JA_CONST_FUNC;


/*
	JADirection JAFlipDirection(JADirection direction)
	Reverse a direction.
*/
#define JAFlipDirection(dir)  (INLINEABLE_DIRECTION(dir) ? JAFlipDirectionBody(dir) : JAFlipDirectionFunc(dir))
static inline JADirection JAFlipDirectionBody(JADirection direction) JA_CONST_FUNC;
JADirection JAFlipDirectionFunc(JADirection direction) JA_CONST_FUNC;


/*
	JADirection JADirectionFlipNorthSouth(JADirection direction)
	Reverse a direction if it is north or south.
*/
#define JADirectionFlipNorthSouth(dir)  (INLINEABLE_DIRECTION(dir) ? JADirectionFlipNorthSouthBody(dir) : JADirectionFlipNorthSouthFunc(dir))
static inline JADirection JADirectionFlipNorthSouthBody(JADirection direction) JA_CONST_FUNC;
JADirection JADirectionFlipNorthSouthFunc(JADirection direction) JA_CONST_FUNC;


/*
	JADirection JADirectionFlipEastWest(JADirection direction)
	Reverse a direction if it is east or west.
*/
#define JADirectionFlipEastWest(dir)  (INLINEABLE_DIRECTION(dir) ? JADirectionFlipEastWestBody(dir) : JADirectionFlipEastWestFunc(dir))
static inline JADirection JADirectionFlipEastWestBody(JADirection direction) JA_CONST_FUNC;
JADirection JADirectionFlipEastWestFunc(JADirection direction) JA_CONST_FUNC;


/*
	JADirection JADirectionFlipUpDown(JADirection direction)
	Reverse a direction if it is up or don.
*/
#define JADirectionFlipUpDown(dir)  (INLINEABLE_DIRECTION(dir) ? JADirectionFlipUpDownBody(dir) : JADirectionFlipUpDownFunc(dir))
static inline JADirection JADirectionFlipUpDownBody(JADirection direction) JA_CONST_FUNC;
JADirection JADirectionFlipUpDownFunc(JADirection direction) JA_CONST_FUNC;

/*
	JADirection JARotateClockwise(JADirection direction)
	Rotates a direction 90° clockwise. Has no effect on up or down directions.
*/
#define JARotateClockwise(dir)  (INLINEABLE_DIRECTION(dir) ? JARotateClockwiseBody(dir) : JARotateClockwiseFunc(dir))
static inline JADirection JARotateClockwiseBody(JADirection direction) JA_CONST_FUNC;
JADirection JARotateClockwiseFunc(JADirection direction) JA_CONST_FUNC;

/*
	JADirection JARotateAntiClockwise(JADirection direction)
	Rotates a direction 90° anticlockwise. Has no effect on up or down directions.
*/
#define JARotateAntiClockwise(dir)  (INLINEABLE_DIRECTION(dir) ? JARotateClockwiseBody(JAFlipDirectionBody(dir)) : JARotateAntiClockwiseFunc(dir))
JADirection JARotateAntiClockwiseFunc(JADirection direction) JA_CONST_FUNC;


/****** Inline function bodies only beyond this point. ******/

static inline BOOL MCCellIsFullySolid(JAMinecraftCell cell)
{
	return MCBlockIDIsFullySolid(cell.blockID);
}


static inline BOOL MCCellIsQuasiSolid(JAMinecraftCell cell)
{
	return MCBlockIDIsQuasiSolid(cell.blockID);
}


static inline BOOL MCCellIsSolid(JAMinecraftCell cell)
{
	return MCBlockIDIsSolid(cell.blockID);
}


static inline BOOL MCCellIsLiquid(JAMinecraftCell cell)
{
	return MCBlockIDIsLiquid(cell.blockID);
}


static inline BOOL MCCellIsItem(JAMinecraftCell cell)
{
	return MCBlockIDIsItem(cell.blockID);
}


static inline BOOL MCCellIsAir(JAMinecraftCell cell)
{
	return MCBlockIDIsAir(cell.blockID);
}


static inline BOOL MCCellIsPowerSource(JAMinecraftCell cell)
{
	return MCBlockIDIsPowerSource(cell.blockID);
}


static inline BOOL MCCellIsPowerSink(JAMinecraftCell cell)
{
	return MCBlockIDIsPowerSink(cell.blockID);
}


static inline BOOL MCCellIsPowerActive(JAMinecraftCell cell)
{
	return MCBlockIDIsPowerActive(cell.blockID);
}


static inline BOOL MCCellIsVegetable(JAMinecraftCell cell)
{
	return MCBlockIDIsVegetable(cell.blockID);
}


static inline BOOL MCCellIsRedstoneTorch(JAMinecraftCell cell)
{
	return MCBlockIDIsRedstoneTorch(cell.blockID);
}


static inline uint8_t MCWirePowerLevel(JAMinecraftCell cell)
{
	return (cell.blockID == kMCBlockRedstoneWire) ? (cell.blockData & kMCInfoRedstoneWireSignalStrengthMask) : 0;
}


static inline BOOL JACellLocationEqual(JACellLocation a, JACellLocation b)
{
	return a.x == b.x && a.y == b.y && a.z == b.z;
}


static NSUInteger JACircuitExtentsWidth(JACircuitExtents extents)
{
	if (!JACircuitExtentsEmpty(extents))  return extents.maxX - extents.minX + 1;
	else return 0;
}


static NSUInteger JACircuitExtentsLength(JACircuitExtents extents)
{
	if (!JACircuitExtentsEmpty(extents))  return extents.maxZ - extents.minZ + 1;
	else return 0;
}


static NSUInteger JACircuitExtentsHeight(JACircuitExtents extents)
{
	if (!JACircuitExtentsEmpty(extents))  return extents.maxY - extents.minY + 1;
	else return 0;
}


static inline JACellLocation JACircuitExtentsMin(JACircuitExtents extents)
{
	return (JACellLocation){ extents.minX, extents.minY, extents.minZ };
}


static inline JACellLocation JACircuitExtentsMax(JACircuitExtents extents)
{
	return (JACellLocation){ extents.maxX, extents.maxY, extents.maxZ };
}


static JACircuitExtents JACircuitExtentsWithLocation(JACellLocation location)
{
	return (JACircuitExtents)
	{
		location.x, location.x,
		location.y, location.y,
		location.z, location.z
	};
}


static inline JACellLocation JAStepCellLocationBody(JACellLocation location, JADirection direction)
{
	switch (direction)
	{
		case kJADirectionNorth:
			location.x -= 1;
			break;
			
		case kJADirectionSouth:
			location.x += 1;
			break;
			
		case kJADirectionEast:
			location.z -= 1;
			break;
			
		case kJADirectionWest:
			location.z += 1;
			break;
			
		case kJADirectionUp:
			location.y += 1;
			break;
			
		case kJADirectionDown:
			location.y -= 1;
			break;
			
		case kJADirectionUnknown:
			break;
	}
	
	return location;
}


static inline JACellLocation JACellNorth(JACellLocation location)
{
	return JAStepCellLocationBody(location, kJADirectionNorth);
}


static inline JACellLocation JACellSouth(JACellLocation location)
{
	return JAStepCellLocationBody(location, kJADirectionSouth);
}


static inline JACellLocation JACellEast(JACellLocation location)
{
	return JAStepCellLocationBody(location, kJADirectionEast);
}


static inline JACellLocation JACellWest(JACellLocation location)
{
	return JAStepCellLocationBody(location, kJADirectionWest);
}


static inline JACellLocation JACellAbove(JACellLocation location)
{
	return JAStepCellLocationBody(location, kJADirectionUp);
}


static inline JACellLocation JACellBelow(JACellLocation location)
{
	return JAStepCellLocationBody(location, kJADirectionDown);
}


static inline JADirection JAFlipDirectionBody(JADirection direction)
{
	switch (direction)
	{
		case kJADirectionNorth:
			return kJADirectionSouth;
			
		case kJADirectionSouth:
			return kJADirectionNorth;
			
		case kJADirectionEast:
			return kJADirectionWest;
			
		case kJADirectionWest:
			return kJADirectionEast;
			
		case kJADirectionUp:
			return kJADirectionDown;
			
		case kJADirectionDown:
			return kJADirectionUp;
			
		case kJADirectionUnknown:
			break;
	}
	return kJADirectionUnknown;
}


static inline JADirection JADirectionFlipNorthSouthBody(JADirection direction)
{
	switch (direction)
	{
		case kJADirectionNorth:
			return kJADirectionSouth;
			
		case kJADirectionSouth:
			return kJADirectionNorth;
			
		default:
			return direction;
	}
}


static inline JADirection JADirectionFlipEastWestBody(JADirection direction)
{
	switch (direction)
	{
		case kJADirectionEast:
			return kJADirectionWest;
			
		case kJADirectionWest:
			return kJADirectionEast;
			
		default:
			return direction;
	}
}


static inline JADirection JADirectionFlipUpDownBody(JADirection direction)
{
	switch (direction)
	{
		case kJADirectionUp:
			return kJADirectionDown;
			
		case kJADirectionDown:
			return kJADirectionUp;
			
		default:
			return direction;
	}
}


static inline JADirection JARotateClockwiseBody(JADirection direction)
{
	switch (direction)
	{
		case kJADirectionNorth:
			return kJADirectionEast;
			
		case kJADirectionSouth:
			return kJADirectionWest;
			
		case kJADirectionEast:
			return kJADirectionSouth;
			
		case kJADirectionWest:
			return kJADirectionNorth;
			
		case kJADirectionUp:
		case kJADirectionDown:
		case kJADirectionUnknown:
			break;
	}
	
	return kJADirectionUnknown;
}
