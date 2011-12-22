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

#import "JAMinecraftTypes.h"
#import "JAPropertyListAccessors.h"
#import "MCKitSchema.h"
#import "JABozoStringTemplate.h"
#import "JAPropertyListAccessors.h"
#import "MYCollectionUtilities.h"


const MCCell kMCAirCell = { .blockID = kMCBlockAir, .blockData = 0 };
const MCCell kMCHoleCell = { .blockID = kMCBlockAir, .blockData = kMCInfoAirIsHole };
const MCCell kMCStoneCell = { .blockID = kMCBlockSmoothStone, .blockData = 0 };
const MCGridCoordinates kMCZeroCoordinates = { 0, 0, 0 };
const MCGridExtents kMCEmptyExtents = { NSIntegerMax, NSIntegerMin, NSIntegerMax, NSIntegerMin, NSIntegerMax, NSIntegerMin };
const MCGridExtents kMCZeroExtents = { 0, 0, 0, 0, 0, 0 };
const MCGridExtents kMCInfiniteExtents = { NSIntegerMin, NSIntegerMax, NSIntegerMin, NSIntegerMax, NSIntegerMin, NSIntegerMax };


NSString * const kMCTileEntityKeyID = @"id";


NSString *MCExpectedTileEntityTypeForBlockID(uint8_t blockID)
{
	switch (blockID)
	{
		case kMCBlockDispenser:			return @"Trap";
		case kMCBlockMovingPiston:		return @"Piston";
		case kMCBlockNoteBlock:			return @"Music";
		case kMCBlockMobSpawner:		return @"Monster Spawner";
		case kMCBlockChest:				return @"Chest";
		case kMCBlockFurnace:
		case kMCBlockBurningFurnace:	return @"Furnace";
		case kMCBlockSignPost:
		case kMCBlockWallSign:			return @"Sign";
		case kMCBlockJukebox:			return @"RecordPlayer";
		case kMCBlockEnchantmentTable:	return @"EnchantTable";
		case kMCBlockBrewingStand:		return @"Cauldron";
		case kMCBlockEndPortal:			return @"Airportal";
			
		default:
			if (!MCBlockIDHasTileEntity(blockID))  return nil;
			
			NSLog(@"Internal error: block ID %u expects a tile entity, but the tile entity ID is unknown.", blockID);
			return @"?";
	}
}


BOOL MCTileEntityIsCompatibleWithCell(NSDictionary *tileEntity, MCCell cell)
{
	if (tileEntity == nil)  return YES;		// Even blocks that should have tile entities can have none, for robustness. TODO: test what Minecraft does.
	
	NSString *type = [tileEntity ja_stringForKey:kMCTileEntityKeyID];
	if (type == nil)  return NO;
	NSString *expectedType = MCExpectedTileEntityTypeForBlockID(cell.blockID);
	
	if ([type isEqualToString:expectedType])  return YES;
	else if ([expectedType isEqualToString:@"?"])  return YES;
	
	return NO;
}


void MCRequireTileEntityIsCompatibleWithCell(NSDictionary *tileEntity, MCCell cell)
{
	if (!MCTileEntityIsCompatibleWithCell(tileEntity, cell))
	{
		[NSException raise:NSInvalidArgumentException format:@"Tile entity of type \"%@\" cannot be used with block ID %u.", [tileEntity ja_stringForKey:kMCTileEntityKeyID], cell.blockID];
	}
}


NSDictionary *MCStandardTileEntityForBlockID(uint8_t blockID)
{
#if 0
	// FIXME
	NSString *tileEntityID = MCExpectedTileEntityTypeForBlockID(blockID);
	if (tileEntityID == nil || [tileEntityID isEqualToString:@"?"])  return nil;
	
	switch (blockID)
	{
		case kMCBlockDispenser:			return @"Trap";
		case kMCBlockMovingPiston:		return @"Piston";
		case kMCBlockNoteBlock:			return @"Music";
		case kMCBlockMobSpawner:		return @"Monster Spawner";
		case kMCBlockChest:				return @"Chest";
		case kMCBlockFurnace:
		case kMCBlockBurningFurnace:	return @"Furnace";
		case kMCBlockSignPost:
		case kMCBlockWallSign:			return @"Sign";
		case kMCBlockJukebox:			return @"RecordPlayer";
		case kMCBlockEnchantmentTable:	return @"EnchantTable";
		case kMCBlockBrewingStand:		return @"Cauldron";
		case kMCBlockAirPortal:			return @"Airportal";
	}
#endif
	
	return nil;
}


static NSDictionary *sBlockDescriptionsDict;
static NSArray *sBlockNames;


NSString *MCShortDescriptionForBlockID(uint8_t blockID)
{
	if (sBlockNames == nil)
	{
		sBlockDescriptionsDict = GetBlockDescriptions();
		sBlockNames = [sBlockDescriptionsDict ja_arrayForKey:@"by ID"];
	}
	
	if (blockID < sBlockNames.count)
	{
		return [sBlockNames objectAtIndex:blockID];
	}
	else
	{
		return nil;
	}
}


NSString *MCCellShortDescription(MCCell cell)
{
	return MCShortDescriptionForBlockID(cell.blockID);
}


NSString *MCCellLongDescription(MCCell cell, NSDictionary *tileEntity)
{
	BOOL handleOrientationGenerically = YES;
	NSString *base = MCCellShortDescription(cell);
	NSString *extra;
	
	switch (cell.blockID)
	{
		case kMCBlockWater:
		case kMCBlockLava:
		{
			NSNumber *level = [NSNumber numberWithInteger:8 - (kMCInfoLiquidEmptinessMask & cell.blockData)];
			extra = TEMPLATE_KEY(sBlockDescriptionsDict, @"Fluid level", level);
			break;
		}
			
		case kMCBlockLog:
		case kMCBlockLeaves:
		{
			NSArray *types = [sBlockDescriptionsDict ja_arrayForKey:@"Wood types"];
			NSUInteger woodType = cell.blockData & kMCInfoWoodTypeMask;
			if (woodType < types.count)
			{
				extra = [types objectAtIndex:woodType];
			}
			if (cell.blockID == kMCBlockLeaves && (cell.blockData & kMCInfoLeafPermanent))
			{
				NSString *type = extra;
				extra = TEMPLATE_KEY(sBlockDescriptionsDict, @"Leaf permanent", type);
			}
			break;
		}
			
		case kMCBlockNoteBlock:
		{
			NSNumber *pitch = [tileEntity ja_objectOfClass:[NSNumber class] forKey:@"note"];
			if (pitch != nil)
			{
				extra = TEMPLATE_KEY(sBlockDescriptionsDict, @"Note block pitch", pitch);
			}
			break;
		}
		
		case kMCBlockBed:
		{
			NSArray *parts = [sBlockDescriptionsDict ja_arrayForKey:@"Bed parts"];
			NSUInteger idx = 0;
			if (cell.blockData & kInfoBedIsHead)  idx = 1;
			extra = [parts objectAtIndex:idx];
			break;
		}
			
		case kMCBlockPoweredRail:
		{
			if (cell.blockData & kMCInfoPoweredRailIsPowered)
			{
				extra = [sBlockDescriptionsDict ja_stringForKey:@"Powered rail powered"];
			}
			break;
		}
			
		case kMCBlockTallGrass:
		{
			NSArray *types = [sBlockDescriptionsDict ja_arrayForKey:@"Tall grass types"];
			if (cell.blockData < types.count)
			{
				extra = [types objectAtIndex:cell.blockData];
			}
			break;
		}
			
		case kMCBlockPistonHead:
			extra = [sBlockDescriptionsDict ja_stringForKey:@"Piston head sticky"];
			break;
			
		case kMCBlockCloth:
		{
			NSArray *types = [sBlockDescriptionsDict ja_arrayForKey:@"Wool"];
			if (cell.blockData < types.count)
			{
				extra = [types objectAtIndex:cell.blockData];
			}
			break;
		}
			
		case kMCBlockDoubleSlab:
		case kMCBlockSingleSlab:
		{
			NSArray *types = [sBlockDescriptionsDict ja_arrayForKey:@"Slab types"];
			if (cell.blockData < types.count)
			{
				extra = [types objectAtIndex:cell.blockData];
			}
			break;
		}
			
		case kMCBlockMobSpawner:
		{
			NSString *entityID = [tileEntity ja_stringForKey:@"EntityId"];
			NSDictionary *names = [sBlockDescriptionsDict ja_dictionaryForKey:@"Mob entity IDs"];
			NSString *friendlyID = [names ja_stringForKey:entityID];
			if (friendlyID != nil)  entityID = friendlyID;
			
			extra = entityID;
			break;
		}
			
		case kMCBlockSoil:
		{
			NSInteger wetness = cell.blockData & kMCInfoSoilWetness;
			if (wetness == 0)
			{
				extra = [sBlockDescriptionsDict ja_stringForKey:@"Soil dry"];
			}
			else
			{
				NSNumber *level = [NSNumber numberWithInteger:wetness];
				extra = TEMPLATE_KEY(sBlockDescriptionsDict, @"Soil wetness", level);
			}
			break;
		}	
			
		case kMCBlockRedstoneWire:
			if (cell.blockData == 0)
			{
				extra = [sBlockDescriptionsDict ja_stringForKey:@"Redstone off"];
			}
			else
			{
				NSNumber *level = [NSNumber numberWithInteger:cell.blockData];
				extra = TEMPLATE_KEY(sBlockDescriptionsDict, @"Redstone power level", level);
			}
			break;
			
		case kMCBlockBurningFurnace:
			extra = [sBlockDescriptionsDict ja_stringForKey:@"Furnace burning"];
			break;
			
		case kMCBlockSignPost:
		case kMCBlockWallSign:
		{
			NSMutableArray *lines = [NSMutableArray arrayWithCapacity:4];
			for (NSUInteger i = 1; i <= 4; i++)
			{
				NSString *text = [tileEntity ja_stringForKey:$sprintf(@"Text%lu", i)];
				if (text.length > 0)  [lines addObject:text];
			}
			
			if (lines.count > 0)
			{
				NSString *text = [lines componentsJoinedByString:@" / "];
				extra = TEMPLATE_KEY(sBlockDescriptionsDict, @"Quote", text);
			}
			else
			{
				extra = [sBlockDescriptionsDict ja_stringForKey:@"Sign empty"];
			}
			break;
		}
			
		case kMCBlockWoodenDoor:
		case kMCBlockIronDoor:
		{
			NSString *topOrBottom = [sBlockDescriptionsDict ja_stringForKey:(cell.blockData & kMCInfoDoorTopHalf) ? @"Door top" : @"Door bottom"];
			NSString *openOrClosed = [sBlockDescriptionsDict ja_stringForKey:(cell.blockData & kMCInfoDoorOpen) ? @"Door open" : @"Door closed"];
			extra = TEMPLATE_KEY2(sBlockDescriptionsDict, @"Door state", topOrBottom, openOrClosed);
			break;
		}
			
		case kMCBlockLever:
		case kMCBlockStoneButton:
			extra = [sBlockDescriptionsDict ja_stringForKey:(cell.blockData & kMCInfoLeverOn) ? @"Switch on" : @"Switch off"];
			break;
			
		case kMCBlockStonePressurePlate:
		case kMCBlockWoodenPressurePlate:
			extra = [sBlockDescriptionsDict ja_stringForKey:(cell.blockData & kMCInfoPressurePlateOn) ? @"Switch on" : @"Switch off"];
			break;
			
		case kMCBlockGlowingRedstoneOre:
			extra = [sBlockDescriptionsDict ja_stringForKey:@"Redstone ore glowing"];
			break;
			
		case kMCBlockRedstoneTorchOff:
		case kMCBlockRedstoneTorchOn:
			extra = [sBlockDescriptionsDict ja_stringForKey:(cell.blockID == kMCBlockRedstoneTorchOn) ? @"Redstone on" : @"Redstone off"];
			
			if ((cell.blockData & kMCInfoMiscOrientationMask) == kMCInfoMiscOrientationFloor)
			{
				handleOrientationGenerically = NO;
				NSString *state = extra;
				extra = TEMPLATE_KEY(sBlockDescriptionsDict, @"Redstone torch on floor", state);
			}
			break;
			
		case kMCBlockJukebox:
		{
			NSInteger record = [tileEntity ja_integerForKey:@"Record"];
			if (record != 0)
			{
				NSNumber *recordNumber = [NSNumber numberWithInteger:record];
				extra = TEMPLATE_KEY(sBlockDescriptionsDict, @"Jukebox record", recordNumber);
			}
			break;
		}
			
		case kMCBlockCake:
		{
			NSNumber *sliceCount = [NSNumber numberWithInteger:6 - cell.blockData & kMCInfoCakeSliceCountMask];
			extra = TEMPLATE_KEY(sBlockDescriptionsDict, @"Cake slices", sliceCount);
			break;
		}
			
		case kMCBlockRedstoneRepeaterOn:
		case kMCBlockRedstoneRepeaterOff:
		{
			NSString *delay = $sprintf(@"%u", ((cell.blockData & kMCInfoRedstoneRepeaterDelayMask) >> 2) + 1);
			NSString *state = [sBlockDescriptionsDict ja_stringForKey:(cell.blockID == kMCBlockRedstoneRepeaterOn) ? @"Redstone on" : @"Redstone off"];
			extra = TEMPLATE_KEY2(sBlockDescriptionsDict, @"Repeater", delay, state);
			break;
		}
			
		case kMCBlockTrapdoor:
		case kMCBlockGate:
			extra = [sBlockDescriptionsDict ja_stringForKey:(cell.blockData & kMCInfoDoorOpen) ? @"Door open" : @"Door closed"];
			break;
			
		case kMCBlockStoneWithSilverfish:
		{
			NSArray *types = [sBlockDescriptionsDict ja_arrayForKey:@"Silverfish block type"];
			if (cell.blockData < types.count)
			{
				extra = [types objectAtIndex:cell.blockData];
			}
			break;
		}
	}
	
	if (handleOrientationGenerically)
	{
		unsigned orientationVal = MCCellGetOrientation(cell);
		if (orientationVal < kMCDirectionUnknown)
		{
			NSArray *orientationStrings = [sBlockDescriptionsDict ja_arrayForKey:@"Orientation"];
			if (orientationVal < orientationStrings.count)
			{
				NSString *orientation = [orientationStrings ja_stringAtIndex:orientationVal];
				if (extra == nil)  extra = TEMPLATE_KEY(sBlockDescriptionsDict, @"Orientation alone", orientation);
				else  extra = TEMPLATE_KEY2(sBlockDescriptionsDict, @"Orientation append", extra, orientation);
			}
		}
	}
	
	if (base != nil)
	{
		if (extra != nil)
		{
			return TEMPLATE_KEY2(sBlockDescriptionsDict, @"Parens", base, extra);
		}
		else
		{
			return base;
		}
	}
	else
	{
		NSString *blockID = [NSString stringWithFormat:@"%u", cell.blockID];
		return TEMPLATE_KEY(sBlockDescriptionsDict, @"UnknownID", blockID);
	}
}


BOOL MCGridExtentsAreWithinExtents(MCGridExtents inner, MCGridExtents outer)
{
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


uint8_t MCRotateRailDataClockwise(uint8_t railBlockData)
{
	switch (railBlockData)
	{
		case kMCInfoRailOrientationWestEast:
			return kMCInfoRailOrientationNorthSouth;
			
		case kMCInfoRailOrientationNorthSouth:
			return kMCInfoRailOrientationWestEast;
			
		case kMCInfoRailOrientationRisingEast:
			return kMCInfoRailOrientationRisingSouth;
			
		case kMCInfoRailOrientationRisingWest:
			return kMCInfoRailOrientationRisingNorth;
			
		case kMCInfoRailOrientationRisingNorth:
			return kMCInfoRailOrientationRisingEast;
			
		case kMCInfoRailOrientationRisingSouth:
			return kMCInfoRailOrientationRisingWest;
			
		case kMCInfoRailOrientationSouthEast:
			return kMCInfoRailOrientationWestSouth;
			
		case kMCInfoRailOrientationWestSouth:
			return kMCInfoRailOrientationNorthWest;
			
		case kMCInfoRailOrientationNorthWest:
			return kMCInfoRailOrientationEastNorth;
			
		case kMCInfoRailOrientationEastNorth:
			return kMCInfoRailOrientationSouthEast;
			
		default:
			return railBlockData;
	}
}


uint8_t MCFlipRailEastWest(uint8_t railBlockData)
{
	switch (railBlockData)
	{
		case kMCInfoRailOrientationRisingNorth:
			return kMCInfoRailOrientationRisingSouth;
			
		case kMCInfoRailOrientationRisingSouth:
			return kMCInfoRailOrientationRisingNorth;
			
		case kMCInfoRailOrientationSouthEast:
			return kMCInfoRailOrientationEastNorth;
			
		case kMCInfoRailOrientationWestSouth:
			return kMCInfoRailOrientationNorthWest;
			
		case kMCInfoRailOrientationNorthWest:
			return kMCInfoRailOrientationWestSouth;
			
		case kMCInfoRailOrientationEastNorth:
			return kMCInfoRailOrientationSouthEast;
			
		case kMCInfoRailOrientationWestEast:
		case kMCInfoRailOrientationNorthSouth:
		case kMCInfoRailOrientationRisingWest:
		case kMCInfoRailOrientationRisingEast:
		default:
			return railBlockData;
	}
}


MCCell MCRotateCellClockwise(MCCell cell)
{
	if (!MCBlockIDIsRail(cell.blockID))
	{
		MCDirection direction = MCCellGetOrientation(cell);
		
		if (cell.blockID != kMCBlockSignPost)
		{
			if (cell.blockID != kMCBlockLever || direction != kMCDirectionDown)
			{
				direction = MCRotateClockwise(direction);
				MCCellSetOrientation(&cell, direction);
			}
			else
			{
				// Special case: handle two orientations of floor levers.
				uint8_t orientation = cell.blockData & kMCInfoMiscOrientationMask;
				if (orientation == kMCInfoLeverOrientationFloorEW)
				{
					orientation = kMCInfoLeverOrientationFloorNS;
				}
				else
				{
					orientation = kMCInfoLeverOrientationFloorEW;
				}
				cell.blockData = (cell.blockData & ~kMCInfoMiscOrientationMask) | orientation;
			}
		}
		else
		{
			// Special case: signposts.
			uint8_t orientation = cell.blockData & kMCInfoSignPostOrientationMask;
			orientation = (orientation + 4) & kMCInfoSignPostOrientationMask;
			cell.blockData = (cell.blockData & ~kMCInfoSignPostOrientationMask) | orientation;
		}
	}
	else
	{
		// Special case: rail.
		uint8_t mask = (cell.blockID == kMCBlockRail) ? kMCInfoRailOrientationMask : kMCInfoPoweredRailOrientationMask;
		uint8_t maskedData = cell.blockData & mask;
		maskedData = MCRotateRailDataClockwise(maskedData);
		cell.blockData = (cell.blockData & ~mask) | maskedData;
	}
	
	return cell;
}


MCCell MCRotateCellAntiClockwise(MCCell cell)
{
	if (!MCBlockIDIsRail(cell.blockID))
	{
		MCDirection direction = MCCellGetOrientation(cell);
		
		if (cell.blockID != kMCBlockSignPost)
		{
			if (cell.blockID != kMCBlockLever || direction != kMCDirectionDown)
			{
				direction = MCRotateAntiClockwise(direction);
				MCCellSetOrientation(&cell, direction);
			}
			else
			{
				// Special case: handle two orientations of floor levers.
				uint8_t orientation = cell.blockData & kMCInfoMiscOrientationMask;
				if (orientation == kMCInfoLeverOrientationFloorEW)
				{
					orientation = kMCInfoLeverOrientationFloorNS;
				}
				else
				{
					orientation = kMCInfoLeverOrientationFloorEW;
				}
				cell.blockData = (cell.blockData & ~kMCInfoMiscOrientationMask) | orientation;
			}
		}
		else
		{
			// Special case: signposts.
			uint8_t orientation = cell.blockData & kMCInfoSignPostOrientationMask;
			orientation = (orientation + 12) & kMCInfoSignPostOrientationMask;
			cell.blockData = (cell.blockData & ~kMCInfoSignPostOrientationMask) | orientation;	
		}
	}
	else
	{
		// Special case: rail.
		uint8_t mask = (cell.blockID == kMCBlockRail) ? kMCInfoRailOrientationMask : kMCInfoPoweredRailOrientationMask;
		uint8_t maskedData = cell.blockData & mask;
		// Rotate three times for 270°.
		maskedData = MCRotateRailDataClockwise(maskedData);
		maskedData = MCRotateRailDataClockwise(maskedData);
		maskedData = MCRotateRailDataClockwise(maskedData);
		cell.blockData = (cell.blockData & ~mask) | maskedData;
	}
	
	return cell;
}


MCCell MCRotateCell180Degrees(MCCell cell)
{
	if (!MCBlockIDIsRail(cell.blockID))
	{
		if (cell.blockID != kMCBlockSignPost)
		{
			MCDirection direction = MCCellGetOrientation(cell);
			
			// Flip on two axes 180°. (Flips are simpler than rotates.)
			direction = MCDirectionFlipNorthSouth(direction);
			direction = MCDirectionFlipEastWest(direction);
			MCCellSetOrientation(&cell, direction);
			
			// No special case for floor levers is needed; they’ll end up unchanged.
		}
		else
		{
			// Special case: signposts.
			uint8_t orientation = cell.blockData & kMCInfoSignPostOrientationMask;
			orientation = (orientation + 8) & kMCInfoSignPostOrientationMask;
			cell.blockData = (cell.blockData & ~kMCInfoSignPostOrientationMask) | orientation;	
		}
	}
	else
	{
		// Special case: rail.
		uint8_t mask = (cell.blockID == kMCBlockRail) ? kMCInfoRailOrientationMask : kMCInfoPoweredRailOrientationMask;
		uint8_t maskedData = cell.blockData & mask;
		// Rotate twice for 180°.
		maskedData = MCRotateRailDataClockwise(maskedData);
		maskedData = MCRotateRailDataClockwise(maskedData);
		cell.blockData = (cell.blockData & ~mask) | maskedData;
	}
	
	return cell;
}


MCCell MCFlipCellEastWest(MCCell cell)
{
	if (!MCBlockIDIsRail(cell.blockID))
	{
		MCDirection direction = MCCellGetOrientation(cell);
		
		direction = MCDirectionFlipEastWest(direction);
		MCCellSetOrientation(&cell, direction);
	}
	else
	{
		// Special case: rail.
		uint8_t mask = (cell.blockID == kMCBlockRail) ? kMCInfoRailOrientationMask : kMCInfoPoweredRailOrientationMask;
		uint8_t maskedData = cell.blockData & mask;
		maskedData = MCFlipRailEastWest(maskedData);
		cell.blockData = (cell.blockData & ~mask) | maskedData;
	}
	
	return cell;
}


MCCell MCFlipCellNorthSouth(MCCell cell)
{
	if (!MCBlockIDIsRail(cell.blockID))
	{
		MCDirection direction = MCCellGetOrientation(cell);
		
		direction = MCDirectionFlipNorthSouth(direction);
		MCCellSetOrientation(&cell, direction);
	}
	else
	{
		// Special case: rail.
		uint8_t mask = (cell.blockID == kMCBlockRail) ? kMCInfoRailOrientationMask : kMCInfoPoweredRailOrientationMask;
		uint8_t maskedData = cell.blockData & mask;
		// Composition fun time!
		/*
			NOTE: this should be inlineable to the eqivalent of a single
			switch. Apple-clang 1.7 inlines the five functions, but doesn’t
			merge the switches. I’ll try to remember to revisit this later as
			tool updates are pending at the time of writing.
		*/
		maskedData = MCRotateRailDataClockwise(maskedData);
		maskedData = MCFlipRailEastWest(maskedData);
		maskedData = MCRotateRailDataClockwise(maskedData);
		maskedData = MCRotateRailDataClockwise(maskedData);
		maskedData = MCRotateRailDataClockwise(maskedData);
		cell.blockData = (cell.blockData & ~mask) | maskedData;
	}
	
	return cell;
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
				case kMCInfoMiscOrientationSouth:
					return kMCDirectionSouth;
					
				case kMCInfoMiscOrientationNorth:
					return kMCDirectionNorth;
					
				case kMCInfoMiscOrientationWest:
					return kMCDirectionWest;
					
				case kMCInfoMiscOrientationEast:
					return kMCDirectionEast;
					
					// 5 and 6 are different orientations for ground levers, with different effects on wires. Needs special handling.
				case kMCInfoMiscOrientationFloor:
				case kMCInfoLeverOrientationFloorNS:
					return kMCDirectionDown;
					
				default:
					return kMCDirectionUnknown;
			}
			
		case kMCBlockWoodenDoor:
		case kMCBlockIronDoor:
		case kMCBlockGate:
			switch (blockData & kMCInfoDoorOrientationMask)
			{
				case kMCInfoDoorOrientationNorth:
					return kMCDirectionNorth;
					
				case kMCInfoDoorOrientationWest:
					return kMCDirectionWest;
					
				case kMCInfoDoorOrientationSouth:
					return kMCDirectionSouth;
					
				case kMCInfoDoorOrientationEast:
					return kMCDirectionEast;
			}
			__builtin_unreachable();
			
		case kMCBlockWoodenStairs:
		case kMCBlockCobblestoneStairs:
		case kMCBlockBrickStairs:
		case kMCBlockStoneBrickStairs:
		case kMCBlockNetherBrickStairs:
			switch (blockData & kMCInfoStairOrientationMask)
			{
				case kMCInfoStairOrientationEast:
					return kMCDirectionEast;
					
				case kMCInfoStairOrientationWest:
					return kMCDirectionWest;
					
				case kMCInfoStairOrientationSouth:
					return kMCDirectionSouth;
					
				case kMCInfoStairOrientationNorth:
					return kMCDirectionNorth;
					
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
				case kMCInfoMisc2OrientationNorth:
					return kMCDirectionNorth;
					
				case kMCInfoMisc2OrientationSouth:
					return kMCDirectionSouth;
					
				case kMCInfoMisc2OrientationWest:
					return kMCDirectionWest;
					
				case kMCInfoMisc2OrientationEast:
					return kMCDirectionEast;
					
				default:
					return kMCDirectionUnknown;
			}
			
		case kMCBlockPumpkin:
		case kMCBlockJackOLantern:
			switch (blockData & kMCInfoPumpkinOrientationMask)
			{
				case kMCInfoPumpkinOrientationSouth:
					return kMCDirectionSouth;
					
				case kMCInfoPumpkinOrientationEast:
					return kMCDirectionEast;
					
				case kMCInfoPumpkinOrientationNorth:
					return kMCDirectionNorth;
					
				case kMCInfoPumpkinOrientationWest:
					return kMCDirectionWest;
					
				default:
					return kMCDirectionUnknown;
			}
			
		case kMCBlockBed:
		case kMCBlockRedstoneRepeaterOn:
		case kMCBlockRedstoneRepeaterOff:
			switch (blockData & kMCInfoMisc3OrientationMask)
			{
				case kMCInfoMisc3OrientationNorth:
					return kMCDirectionNorth;
					
				case kMCInfoMisc3OrientationEast:
					return kMCDirectionEast;
					
				case kMCInfoMisc3OrientationSouth:
					return kMCDirectionSouth;
					
				case kMCInfoMisc3OrientationWest:
					return kMCDirectionWest;
					
				default:
					return kMCDirectionUnknown;
			}
			
		case kMCBlockPiston:
		case kMCBlockStickyPiston:
		case kMCBlockPistonHead:
			switch (blockData & kMCInfoPistonOrientationMask)
			{
				case kMCInfoPistonOrientationDown:
					return kMCDirectionDown;
					
				case kMCInfoPistonOrientationUp:
					return kMCDirectionUp;
					
				case kMCInfoPistonOrientationNorth:
					return kMCDirectionNorth;
					
				case kMCInfoPistonOrientationSouth:
					return kMCDirectionSouth;
					
				case kMCInfoPistonOrientationWest:
					return kMCDirectionWest;
					
				case kMCInfoPistonOrientationEast:
					return kMCDirectionEast;
					
				default:
					return kMCDirectionUnknown;
			}
			
		case kMCBlockTrapdoor:
			switch (blockData & kMCInfoTrapdoorOrientationMask)
			{
				case kMCInfoTrapdoorOrientationNorth:
					return kMCDirectionNorth;
					
				case kMCInfoTrapdoorOrientationSouth:
					return kMCDirectionSouth;
					
				case kMCInfoTrapdoorOrientationWest:
					return kMCDirectionWest;
					
				case kMCInfoTrapdoorOrientationEast:
					return kMCDirectionEast;
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
						value = kMCInfoMiscOrientationWest;
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
		case kMCBlockGate:
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
		case kMCBlockBrickStairs:
		case kMCBlockStoneBrickStairs:
		case kMCBlockNetherBrickStairs:
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
			
		case kMCBlockPumpkin:
		case kMCBlockJackOLantern:
			mask = kMCInfoPumpkinOrientationMask;
			switch (orientation)
			{
				case kMCDirectionSouth:
					value = kMCInfoPumpkinOrientationSouth;
					break;
					
				case kMCDirectionEast:
					value = kMCInfoPumpkinOrientationEast;
					break;
					
				case kMCDirectionWest:
					value = kMCInfoPumpkinOrientationWest;
					break;
					
				case kMCDirectionNorth:
				default:
					value = kMCInfoPumpkinOrientationNorth;
					break;
			}
			break;
			
		case kMCBlockBed:
		case kMCBlockRedstoneRepeaterOn:
		case kMCBlockRedstoneRepeaterOff:
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
				case kMCDirectionDown:
					value = kMCInfoPistonOrientationDown;
					break;
				
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
	
	cell->blockData = (cell->blockData & ~mask) | value;
}
