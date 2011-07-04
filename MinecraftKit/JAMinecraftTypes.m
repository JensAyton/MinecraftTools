/*
	JAMinecraftTypes.m
	
	
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

#include "JAMinecraftTypes.h"


const MCCell kMCAirCell = { .blockID = kMCBlockAir, .blockData = 0 };
const MCCell kMCHoleCell = { .blockID = kMCBlockAir, .blockData = kMCInfoAirIsHoleMask };
const MCCell kMCStoneCell = { .blockID = kMCBlockSmoothStone, .blockData = 0 };
const MCGridCoordinates kMCZeroCoordinates = { 0, 0, 0 };
const MCGridExtents kMCEmptyExtents = { NSIntegerMax, NSIntegerMin, NSIntegerMax, NSIntegerMin, NSIntegerMax, NSIntegerMin };
const MCGridExtents kMCZeroExtents = { 0, 0, 0, 0, 0, 0 };
const MCGridExtents kMCInfiniteExtents = { NSIntegerMin, NSIntegerMax, NSIntegerMin, NSIntegerMax, NSIntegerMin, NSIntegerMax };


BOOL MCGridExtentsAreWithinExtents(MCGridExtents inner_, MCGridExtents outer_)
{
	MCGridExtents inner = inner_, outer = outer_;
	
	return	!MCGridExtentsEmpty(inner) &&
			MCGridCoordinatesAreWithinExtents(MCGridExtentsMinimum(inner), outer) &&
			MCGridCoordinatesAreWithinExtents(MCGridExtentsMaximum(inner), outer);
}


MCGridExtents MCGridExtentsUnion(MCGridExtents a, MCGridExtents b)
{
	if (MCGridExtentsEmpty(a))  return b;
	if (MCGridExtentsEmpty(b))  return a;
	
	return (MCGridExtents)
	{
		MIN(a.minX, b.minX), MAX(a.maxX, b.maxX),
		MIN(a.minY, b.minY), MAX(a.maxY, b.maxY),
		MIN(a.minZ, b.minZ), MAX(a.maxZ, b.maxZ)
	};
}


MCGridExtents MCGridExtentsUnionWithCoordinates(MCGridExtents extents, MCGridCoordinates location)
{
	return MCGridExtentsUnion(extents, MCGridExtentsWithCoordinates(location));
}


MCGridExtents MCGridExtentsIntersection(MCGridExtents a, MCGridExtents b)
{
	return (MCGridExtents)
	{
		MAX(a.minX, b.minX), MIN(a.maxX, b.maxX),
		MAX(a.minY, b.minY), MIN(a.maxY, b.maxY),
		MAX(a.minZ, b.minZ), MIN(a.maxZ, b.maxZ)
	};
}


BOOL MCGridExtentsIntersect(MCGridExtents a_, MCGridExtents b_)
{
	MCGridExtents a = a_, b = b_;
	
	if (MCGridExtentsEmpty(a) || MCGridExtentsEmpty(b))  return NO;
	
#if 0
	return	a.minX <= b.maxX && b.minX <= a.maxX &&
			a.minY <= b.maxY && b.minY <= a.maxY &&
			a.minZ <= b.maxZ && b.minZ <= a.maxZ;
#else
	if (!(a.minX <= b.maxX && b.minX <= a.maxX))  return NO;
	if (!(a.minY <= b.maxY && b.minY <= a.maxY))  return NO;
	if (!(a.minZ <= b.maxZ && b.minZ <= a.maxZ))  return NO;
	return YES;
#endif
}


MCGridCoordinates MCStepCoordinatesFunc(MCGridCoordinates location, MCDirection direction)
{
	NSCParameterAssert(direction <= kMCDirectionDown);
	return MCStepCoordinatesBody(location, direction);
}


MCDirection MCDirectionFlipFunc(MCDirection direction)
{
	NSCParameterAssert(direction <= kMCDirectionUnknown);
	return MCDirectionFlipBody(direction);
}


MCDirection MCDirectionFlipNorthSouthFunc(MCDirection direction)
{
	NSCParameterAssert(direction <= kMCDirectionUnknown);
	return MCDirectionFlipNorthSouthBody(direction);
}


MCDirection MCDirectionFlipEastWestFunc(MCDirection direction)
{
	NSCParameterAssert(direction <= kMCDirectionUnknown);
	return MCDirectionFlipEastWestBody(direction);
}


MCDirection MCDirectionFlipUpDownFunc(MCDirection direction)
{
	NSCParameterAssert(direction <= kMCDirectionUnknown);
	return MCDirectionFlipUpDownBody(direction);
}


MCDirection MCRotateClockwiseFunc(MCDirection direction)
{
	NSCParameterAssert(direction <= kMCDirectionUnknown);
	return MCRotateClockwiseBody(direction);
}


MCDirection MCRotateAntiClockwiseFunc(MCDirection direction)
{
	NSCParameterAssert(direction <= kMCDirectionUnknown);
	return MCRotateClockwiseBody(MCDirectionFlipBody(direction));
}


MCDirection MCCellGetOrientation(MCCell cell)
{
	uint8_t blockData = cell.blockData;
	switch (cell.blockID)
	{
		case kMCBlockTorch:
		case kMCBlockRedstoneTorchOff:
		case kMCBlockRedstoneTorchOn:
		case kMCBlockLever:
		case kMCBlockStoneButton:
			switch (blockData & kMCInfoMiscOrientationMask)
			{
				case kMCInfoMiscOrientationWest:
					return kMCDirectionWest;
					
				case kMCInfoMiscOrientationEast:
					return kMCDirectionEast;
					
				case kMCInfoMiscOrientationNorth:
					return kMCDirectionNorth;
					
				case kMCInfoMiscOrientationSouth:
					return kMCDirectionSouth;
					
					// 5 and 6 are different orientations for ground levers, with different effects on wires. Needs special handling.
				case kMCInfoMiscOrientationFloor:
				case kMCInfoLeverOrientationFloorNS:
					return kMCDirectionDown;
					
				default:
					return kMCDirectionUnknown;
			}
			
		case kMCBlockWoodenDoor:
		case kMCBlockIronDoor:
			switch (blockData & kMCInfoDoorOrientationMask)
			{
				case kMCInfoDoorOrientationEast:
					return kMCDirectionEast;
					
				case kMCInfoDoorOrientationNorth:
					return kMCDirectionNorth;
					
				case kMCInfoDoorOrientationWest:
					return kMCDirectionWest;
					
				case kMCInfoDoorOrientationSouth:
					return kMCDirectionSouth;
			}
			__builtin_unreachable();
			
		case kMCBlockWoodenStairs:
		case kMCBlockCobblestoneStairs:
			switch (blockData & kMCInfoStairOrientationMask)
			{
				case kMCInfoStairOrientationSouth:
					return kMCDirectionSouth;
					
				case kMCInfoStairOrientationNorth:
					return kMCDirectionNorth;
					
				case kMCInfoStairOrientationWest:
					return kMCDirectionWest;
					
				case kMCInfoStairOrientationEast:
					return kMCDirectionEast;
					
				default:
					return kMCDirectionUnknown;
			}
			
		case kMCBlockLadder:
		case kMCBlockWallSign:
		case kMCBlockFurnace:
		case kMCBlockBurningFurnace:
		case kMCBlockDispenser:
			switch (blockData & kMCInfoMisc2OrientationMask)
			{
				case kMCInfoMisc2OrientationEast:
					return kMCDirectionEast;
					
				case kMCInfoMisc2OrientationWest:
					return kMCDirectionWest;
					
				case kMCInfoMisc2OrientationNorth:
					return kMCDirectionNorth;
					
				case kMCInfoMisc2OrientationSouth:
					return kMCDirectionSouth;
					
				default:
					return kMCDirectionUnknown;
			}
			
		case kMCBlockBed:
		case kMCBlockPumpkin:
		case kMCBlockJackOLantern:
			switch (blockData & kMCInfoMisc3OrientationMask)
			{
				case kMCInfoMisc3OrientationEast:
					return kMCDirectionEast;
					
				case kMCInfoMisc3OrientationSouth:
					return kMCDirectionSouth;
					
				case kMCInfoMisc3OrientationWest:
					return kMCDirectionWest;
					
				case kMCInfoMisc3OrientationNorth:
					return kMCDirectionNorth;
					
				default:
					return kMCDirectionUnknown;
			}
			
		case kMCBlockPiston:
		case kMCBlockStickyPiston:
		case kMCBlockPistonHead:
			switch (blockData & kMCInfoPistonOrientationMask)
			{
				case kMCInfoPistonOrientationUp:
					return kMCDirectionUp;
					
				case kMCInfoPistonOrientationEast:
					return kMCDirectionEast;
					
				case kMCInfoPistonOrientationWest:
					return kMCDirectionWest;
					
				case kMCInfoPistonOrientationNorth:
					return kMCDirectionNorth;
					
				case kMCInfoPistonOrientationSouth:
					return kMCDirectionSouth;
					
				default:
					return kMCDirectionUnknown;
			}
			
		case kMCBlockTrapdoor:
			switch (blockData & kMCInfoTrapdoorOrientationMask)
			{
				case kMCInfoTrapdoorOrientationEast:
					return kMCDirectionEast;
					
				case kMCInfoTrapdoorOrientationWest:
					return kMCDirectionWest;
					
				case kMCInfoTrapdoorOrientationNorth:
					return kMCDirectionNorth;
					
				case kMCInfoTrapdoorOrientationSouth:
					return kMCDirectionSouth;
			}
			
		default:
			return kMCDirectionUnknown;
	}
}


void MCCellSetOrientation(MCCell *cell, MCDirection orientation)
{
	NSCParameterAssert(cell != NULL);
	
	uint8_t value = 0;
	uint8_t mask = 0;	// Bits that should affected.
	
	switch (cell->blockID)
	{
		case kMCBlockTorch:
		case kMCBlockRedstoneTorchOff:
		case kMCBlockRedstoneTorchOn:
		case kMCBlockLever:
		case kMCBlockStoneButton:
			mask = kMCInfoMiscOrientationMask;
			switch (orientation)
			{
				case kMCDirectionNorth:
					value = kMCInfoMiscOrientationNorth;
					break;
					
				case kMCDirectionSouth:
					value = kMCInfoMiscOrientationSouth;
					break;
					
				case kMCDirectionEast:
					value = kMCInfoMiscOrientationEast;
					break;
				
				case kMCDirectionWest:
					value = kMCInfoMiscOrientationWest;
					break;
					
				case kMCDirectionDown:
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
				case kMCDirectionSouth:
					value = kMCInfoDoorOrientationSouth;
					break;
					
				case kMCDirectionEast:
					value = kMCInfoDoorOrientationEast;
					break;
					
				case kMCDirectionWest:
					value = kMCInfoDoorOrientationWest;
					break;
					
				case kMCDirectionNorth:
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
				case kMCDirectionSouth:
					value = kMCInfoStairOrientationSouth;
					break;
					
				case kMCDirectionEast:
					value = kMCInfoStairOrientationEast;
					break;
					
				case kMCDirectionWest:
					value = kMCInfoStairOrientationWest;
					break;
					
				case kMCDirectionNorth:
				default:
					value = kMCInfoStairOrientationNorth;
					break;
			}
			break;
			
		case kMCBlockLadder:
		case kMCBlockWallSign:
		case kMCBlockFurnace:
		case kMCBlockBurningFurnace:
		case kMCBlockDispenser:
			mask = kMCInfoMisc2OrientationMask;
			switch (orientation)
			{
				case kMCDirectionSouth:
					value = kMCInfoMisc2OrientationSouth;
					break;
					
				case kMCDirectionEast:
					value = kMCInfoMisc2OrientationEast;
					break;
					
				case kMCDirectionWest:
					value = kMCInfoMisc2OrientationWest;
					break;
					
				case kMCDirectionNorth:
				default:
					value = kMCInfoMisc2OrientationNorth;
					break;
			}
			break;
			
		case kMCBlockBed:
		case kMCBlockPumpkin:
		case kMCBlockJackOLantern:
			mask = kMCInfoMisc3OrientationMask;
			switch (orientation)
			{
				case kMCDirectionSouth:
					value = kMCInfoMisc3OrientationSouth;
					break;
					
				case kMCDirectionEast:
					value = kMCInfoMisc3OrientationEast;
					break;
					
				case kMCDirectionWest:
					value = kMCInfoMisc3OrientationWest;
					break;
					
				case kMCDirectionNorth:
				default:
					value = kMCInfoMisc3OrientationNorth;
					break;
			}
			break;
			
		case kMCBlockPiston:
		case kMCBlockStickyPiston:
		case kMCBlockPistonHead:
			mask = kMCInfoPistonOrientationMask;
			switch (orientation)
			{
				case kMCDirectionUp:
					value = kMCInfoPistonOrientationUp;
					break;
					
				case kMCDirectionEast:
					value = kMCInfoPistonOrientationEast;
					break;
					
				case kMCDirectionWest:
					value = kMCInfoPistonOrientationWest;
					break;
					
				case kMCDirectionNorth:
					value = kMCInfoPistonOrientationNorth;
					break;
					
				case kMCDirectionSouth:
				default:
					value = kMCInfoPistonOrientationSouth;
					break;
			}
			break;
			
		case kMCBlockTrapdoor:
			mask = kMCInfoTrapdoorOrientationMask;
			switch (orientation)
		{
			case kMCDirectionEast:
				value = kMCInfoTrapdoorOrientationEast;
				break;
				
			case kMCDirectionWest:
				value = kMCInfoTrapdoorOrientationWest;
				break;
				
			case kMCDirectionNorth:
				value = kMCInfoTrapdoorOrientationNorth;
				break;
				
			case kMCDirectionSouth:
			default:
				value = kMCInfoTrapdoorOrientationSouth;
				break;
			}
			break;

	}
	
	cell->blockData = cell->blockData & ~mask | value;
}
