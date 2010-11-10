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


/*
	BlockData bit masks. The meaning of bits depends on the block ID.
*/
enum
{
	kMCBlockInfoDoorOpen		= 0x04
};


typedef struct JAMinecraftCell
{
	/*	Block IDs and block data straight from Minecraft.
		See JAMinecraftBlockIDs.h and http://www.minecraftwiki.net/wiki/Data_values
	*/
	uint8_t					blockID;
	uint8_t					blockData;
} JAMinecraftCell;


extern const JAMinecraftCell kJAEmptyCell;

/*
	Convenience predicates and info extractors.
*/
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


// Power level (0-15) for wires only - 0 for power sources.
static inline uint8_t MCWirePowerLevel(JAMinecraftCell cell)
{
	return (cell.blockID == kMCBlockRedstoneWire) ? (cell.blockData & kMCInfoRedstoneWireSignalStrengthMask) : 0;
}


/*
	Coordinate system:
	+y is north, -y is south.
	+x is east, -x is west.
	+z is up, -z is down (in layers; “up” and “down” might be used for y coords
	somewhere if I haven’t been pating attention).
	“Width” refers to an x range, “height” a y range and “depth” a z range.
	
	IMPORTANT: this is not the same as Minecraft’s coordinate system. Instead,
	it’s adapted for top-down interfaces.
	
	Minecraft coordinates are:
	+X is south, -X is north – corresponds to -y.
	+Y is up, -Y is down – corresponds to z.
	+Z is west, -Z is east — corresponds to -x.
*/
typedef struct
{
	NSInteger				x, y, z;
} JACellLocation;


static inline BOOL JACellLocationEqual(JACellLocation a, JACellLocation b)
{
	return a.x == b.x && a.y == b.y && a.z == b.z;
}


typedef struct
{
	NSInteger				minX, maxX,
							minY, maxY,
							minZ, maxZ;
} JACircuitExtents;


/*
	An extents struct is considered empty if any of its max values is less than
	the corresponding min value.
	
	kJAEmptyExtents is the extreme case, with all minima being NSIntegerMax
	and all maxima being NSIntegerMin.
*/
extern const JACircuitExtents kJAEmptyExtents;
BOOL JACircuitExtentsEmpty(JACircuitExtents extents) JA_CONST_FUNC;

extern const JACircuitExtents kJAInfiniteExtents;

BOOL JACircuitExtentsEqual(JACircuitExtents a, JACircuitExtents b) JA_CONST_FUNC;


static NSUInteger JACircuitExtentsWidth(JACircuitExtents extents)
{
	if (!JACircuitExtentsEmpty(extents))  return extents.maxX - extents.minX + 1;
	else return 0;
}


static NSUInteger JACircuitExtentsHeight(JACircuitExtents extents)
{
	if (!JACircuitExtentsEmpty(extents))  return extents.maxY - extents.minY + 1;
	else return 0;
}


static NSUInteger JACircuitExtentsDepth(JACircuitExtents extents)
{
	if (!JACircuitExtentsEmpty(extents))  return extents.maxZ - extents.minZ + 1;
	else return 0;
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


BOOL JACellLocationWithinExtents(JACellLocation location, JACircuitExtents extents) JA_CONST_FUNC;


JACircuitExtents JAExtentsUnion(JACircuitExtents a, JACircuitExtents b) JA_CONST_FUNC;
JACircuitExtents JAExtentsUnionLocation(JACircuitExtents extents, JACellLocation location) JA_CONST_FUNC;

JACircuitExtents JAExtentsIntersection(JACircuitExtents a, JACircuitExtents b) JA_CONST_FUNC;


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

static inline JACellLocation JAStepCellLocationBody(JACellLocation location, JADirection direction)
{
	switch (direction)
	{
		case kJADirectionNorth:
			location.y -= 1;
			break;
			
		case kJADirectionSouth:
			location.y += 1;
			break;
			
		case kJADirectionEast:
			location.x += 1;
			break;
			
		case kJADirectionWest:
			location.x -= 1;
			break;
			
		case kJADirectionUp:
			location.z += 1;
			break;
			
		case kJADirectionDown:
			location.z -= 1;
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
