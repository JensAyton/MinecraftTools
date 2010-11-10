/*
	JAMinecraftTypes.m
	
	
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

#include "JAMinecraftTypes.h"


const JAMinecraftCell kJAEmptyCell = { .blockID = kMCBlockAir };
const JACircuitExtents kJAEmptyExtents = { NSIntegerMax, NSIntegerMin, NSIntegerMax, NSIntegerMin, NSIntegerMax, NSIntegerMin };
const JACircuitExtents kJAInfiniteExtents = { NSIntegerMin, NSIntegerMax, NSIntegerMin, NSIntegerMax, NSIntegerMin, NSIntegerMax };


BOOL JACircuitExtentsEmpty(JACircuitExtents extents)
{
	return	extents.maxX < extents.minX ||
	extents.maxY < extents.minY ||
	extents.maxZ < extents.minZ;
}


BOOL JACircuitExtentsEqual(JACircuitExtents a, JACircuitExtents b)
{
	return a.minX == b.minX &&
		   a.maxX == b.maxX &&
		   a.minY == b.minY &&
		   a.maxY == b.maxY &&
		   a.minZ == b.minZ &&
		   a.maxZ == b.maxZ;
}


BOOL JACellLocationWithinExtents(JACellLocation location, JACircuitExtents extents)
{
	return	extents.minX <= location.x && location.x <= extents.maxX &&
			extents.minY <= location.y && location.y <= extents.maxY &&
			extents.minZ <= location.z && location.z <= extents.maxZ;
}


JACircuitExtents JAExtentsUnion(JACircuitExtents a, JACircuitExtents b)
{
	return (JACircuitExtents)
	{
		MIN(a.minX, b.minX), MAX(a.maxX, b.maxX),
		MIN(a.minY, b.minY), MAX(a.maxY, b.maxY),
		MIN(a.minZ, b.minZ), MAX(a.maxZ, b.maxZ)
	};
}


JACircuitExtents JAExtentsUnionLocation(JACircuitExtents extents, JACellLocation location)
{
	return JAExtentsUnion(extents, JACircuitExtentsWithLocation(location));
}


JACircuitExtents JAExtentsIntersection(JACircuitExtents a, JACircuitExtents b)
{
	return (JACircuitExtents)
	{
		MAX(a.minX, b.minX), MIN(a.maxX, b.maxX),
		MAX(a.minY, b.minY), MIN(a.maxY, b.maxY),
		MAX(a.minZ, b.minZ), MIN(a.maxZ, b.maxZ)
	};
}


JACellLocation JAStepCellLocationFunc(JACellLocation location, JADirection direction)
{
	NSCParameterAssert(direction <= kJADirectionDown);
	return JAStepCellLocationBody(location, direction);
}


JADirection JAFlipDirectionFunc(JADirection direction)
{
	NSCParameterAssert(direction <= kJADirectionUnknown);
	return JAFlipDirectionBody(direction);
}


JADirection JADirectionFlipNorthSouthFunc(JADirection direction)
{
	NSCParameterAssert(direction <= kJADirectionUnknown);
	return JADirectionFlipNorthSouthBody(direction);
}


JADirection JADirectionFlipEastWestFunc(JADirection direction)
{
	NSCParameterAssert(direction <= kJADirectionUnknown);
	return JADirectionFlipEastWestBody(direction);
}


JADirection JADirectionFlipUpDownFunc(JADirection direction)
{
	NSCParameterAssert(direction <= kJADirectionUnknown);
	return JADirectionFlipUpDownBody(direction);
}


JADirection JARotateClockwiseFunc(JADirection direction)
{
	NSCParameterAssert(direction <= kJADirectionUnknown);
	return JARotateClockwiseBody(direction);
}


JADirection JARotateAntiClockwiseFunc(JADirection direction)
{
	NSCParameterAssert(direction <= kJADirectionUnknown);
	return JARotateClockwiseBody(JAFlipDirectionBody(direction));
}


JADirection MCCellGetOrientation(JAMinecraftCell cell)
{
	uint8_t blockData = cell.blockData;
	switch (cell.blockID)
	{
		case kMCBlockLantern:
		case kMCBlockRedstoneTorchOff:
		case kMCBlockRedstoneTorchOn:
		case kMCBlockLever:
		case kMCBlockStoneButton:
			switch (blockData & kMCInfoMiscOrientationMask)
			{
				case kMCInfoMiscOrientationWest:
					return kJADirectionWest;
					
				case kMCInfoMiscOrientationEast:
					return kJADirectionEast;
					
				case kMCInfoMiscOrientationNorth:
					return kJADirectionNorth;
					
				case kMCInfoMiscOrientationSouth:
					return kJADirectionSouth;
					
					// 5 and 6 are different orientations for ground levers, with different effects on wires. Needs special handling.
				case kMCInfoMiscOrientationFloor:
				case kMCInfoLeverOrientationFloorNS:
					return kJADirectionDown;
					
				default:
					return kJADirectionUnknown;
			}
			
		case kMCBlockWoodenDoor:
		case kMCBlockIronDoor:
			switch (blockData & kMCInfoDoorOrientationMask)
			{
				case kMCInfoDoorOrientationEast:
					return kJADirectionEast;
					
				case kMCInfoDoorOrientationNorth:
					return kJADirectionNorth;
					
				case kMCInfoDoorOrientationWest:
					return kJADirectionWest;
					
				case kMCInfoDoorOrientationSouth:
					return kJADirectionSouth;
			}
			__builtin_unreachable();
			
		case kMCBlockWoodenStairs:
		case kMCBlockCobblestoneStairs:
			switch (blockData & kMCInfoStairOrientationMask)
			{
				case kMCInfoStairOrientationSouth:
					return kJADirectionSouth;
					
				case kMCInfoStairOrientationNorth:
					return kJADirectionNorth;
					
				case kMCInfoStairOrientationWest:
					return kJADirectionWest;
					
				case kMCInfoStairOrientationEast:
					return kJADirectionEast;
					
				default:
					return kJADirectionUnknown;
			}
			
		case kMCBlockLadder:
		case kMCBlockWallSign:
			switch (blockData & kMCInfoLadderOrientationMask)
			{
				case kMCInfoLadderOrientationEast:
					return kJADirectionEast;
					
				case kMCInfoLadderOrientationWest:
					return kJADirectionWest;
					
				case kMCInfoLadderOrientationNorth:
					return kJADirectionNorth;
					
				case kMCInfoLadderOrientationSouth:
					return kJADirectionSouth;
					
				default:
					return kJADirectionUnknown;
			}
			
		default:
			return kJADirectionUnknown;
	}
}


void MCCellSetOrientation(JAMinecraftCell *cell, JADirection orientation)
{
	NSCParameterAssert(cell != NULL);
	
	uint8_t value = 0;
	uint8_t mask = 0;	// Bits that should affected.
	
	switch (cell->blockID)
	{
		case kMCBlockLantern:
		case kMCBlockRedstoneTorchOff:
		case kMCBlockRedstoneTorchOn:
		case kMCBlockLever:
		case kMCBlockStoneButton:
			mask = kMCInfoMiscOrientationMask;
			switch (orientation)
			{
				case kJADirectionNorth:
					value = kMCInfoMiscOrientationNorth;
					break;
					
				case kJADirectionSouth:
					value = kMCInfoMiscOrientationSouth;
					break;
					
				case kJADirectionEast:
					value = kMCInfoMiscOrientationEast;
					break;
				
				case kJADirectionWest:
					value = kMCInfoMiscOrientationWest;
					break;
					
				case kJADirectionDown:
				default:
					if (cell->blockID == kMCBlockLever)
					{
						// Special case: levers have two down orientations, and we want to preserve where relevant.
						value = cell->blockData & kMCInfoMiscOrientationMask;
						if (value != kMCInfoLeverOrientationFloorNS && value != kMCInfoLeverOrientationFloorEW)
						{
							value = kMCInfoLeverOrientationFloorNS;
						}
					}
					else if (cell->blockID == kMCBlockStoneButton)
					{
						// For stone buttons, down is meaningless.
						value = kMCInfoMiscOrientationNorth;
					}
					else
					{
						value = kMCInfoMiscOrientationFloor;
					}
					break;
			}
			break;
			
		case kMCBlockWoodenDoor:
		case kMCBlockIronDoor:
			mask = kMCInfoDoorOrientationMask;
			switch (orientation)
			{
				case kJADirectionSouth:
					value = kMCInfoDoorOrientationSouth;
					break;
					
				case kJADirectionEast:
					value = kMCInfoDoorOrientationEast;
					break;
					
				case kJADirectionWest:
					value = kMCInfoDoorOrientationWest;
					break;
					
				case kJADirectionNorth:
				default:
					value = kMCInfoDoorOrientationNorth;
					break;
			}
			break;
			
		case kMCBlockWoodenStairs:
		case kMCBlockCobblestoneStairs:
			mask = kMCInfoStairOrientationMask;
				switch (orientation)
			{
				case kJADirectionSouth:
					value = kMCInfoStairOrientationSouth;
					break;
					
				case kJADirectionEast:
					value = kMCInfoStairOrientationEast;
					break;
					
				case kJADirectionWest:
					value = kMCInfoStairOrientationWest;
					break;
					
				case kJADirectionNorth:
				default:
					value = kMCInfoStairOrientationNorth;
					break;
			}
			break;
			
		case kMCBlockLadder:
		case kMCBlockWallSign:
			mask = kMCInfoLadderOrientationMask;
			switch (orientation)
			{
				case kJADirectionSouth:
					value = kMCInfoLadderOrientationSouth;
					break;
					
				case kJADirectionEast:
					value = kMCInfoLadderOrientationEast;
					break;
					
				case kJADirectionWest:
					value = kMCInfoLadderOrientationWest;
					break;
					
				case kJADirectionNorth:
				default:
					value = kMCInfoLadderOrientationNorth;
					break;
			}
			break;
	}
	
	cell->blockData = cell->blockData & ~mask | value;
}
