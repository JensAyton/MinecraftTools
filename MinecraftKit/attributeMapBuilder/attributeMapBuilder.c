/*
	attributeMapBuilder.c
	
	This tool generates the kMCBlockTypeClassifications lookup table for
	MinecraftKit. Below this here comment you will find a list of blocks for
	each of the defined attributes. These are then packed into bitfields of
	attributes for each block type. Yawn.
	
	When JAMinecraftBlockIDs.h is updated with new block types, the attributes
	need to be updated and a new JAMinecraftBlockIDs.c generated.
	
	
	Copyright © 2010–2012 Jens Ayton
	
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


#include "JAMinecraftBlockIDs.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>


static const uint8_t kOpaqueIDs[] =
{
	kMCBlockSmoothStone,
	kMCBlockGrass,
	kMCBlockDirt,
	kMCBlockCobblestone,
	kMCBlockWoodPlanks,
	kMCBlockBedrock,
	kMCBlockSand,
	kMCBlockGravel,
	kMCBlockGoldOre,
	kMCBlockIronOre,
	kMCBlockCoalOre,
	kMCBlockLog,
	kMCBlockSponge,
	kMCBlockLapisLazuliOre,
	kMCBlockLapisLazuliBlock,
	kMCBlockDispenser,
	kMCBlockSandstone,
	kMCBlockNoteBlock,
	kMCBlockCloth,
	kMCBlockGoldBlock,
	kMCBlockIronBlock,
	kMCBlockDoubleSlab,
	kMCBlockBrick,
	kMCBlockTNT,
	kMCBlockBookshelf,
	kMCBlockMossyCobblestone,
	kMCBlockObsidian,
	kMCBlockDiamondOre,
	kMCBlockDiamondBlock,
	kMCBlockWorkbench,
	kMCBlockFurnace,
	kMCBlockBurningFurnace,
	kMCBlockRedstoneOre,
	kMCBlockGlowingRedstoneOre,
	kMCBlockSnowBlock,
	kMCBlockClay,
	kMCBlockJukebox,
	kMCBlockPumpkin,
	kMCBlockNetherrack,
	kMCBlockSoulSand,
	kMCBlockJackOLantern,
	kMCBlockLockedChest,
	kMCBlockStoneWithSilverfish,
	kMCBlockStoneBrick,
	kMCBlockHugeBrownMushroom,
	kMCBlockHugeRedMushroom,
	kMCBlockWatermelon,
	kMCBlockMycelium,
	kMCBlockNetherBrick,
	kMCBlockEndStone,
	kMCBlockRedstoneLampOff,
	kMCBlockRedstoneLampOn,
	kMCBlockWoodenDoubleSlab,
	kMCBlockEmeraldOre,
	kMCBlockEmeraldBlock,
	kMCBlockCommandBlock,
	kMCBlockRedstoneBlock,
	kMCBlockNetherQuartzOre,
	kMCBlockQuartzBlock,
	kMCBlockDropper,
	kMCBlockStainedClay,
	kMCBlockHayBlock,
	kMCBlockHardenedClay,
	kMCBlockCoalBlock,
};


static const uint8_t kTransparentIDs[] =
{
	kMCBlockAir,
	kMCBlockLeaves,
	kMCBlockGlass,
	kMCBlockStickyPiston,
	kMCBlockPiston,
	kMCBlockSingleSlab,
	kMCBlockMobSpawner,
	kMCBlockWoodenStairs,
	kMCBlockSoil,
	kMCBlockCobblestoneStairs,
	kMCBlockGlowstone,
	kMCBlockBrickStairs,
	kMCBlockStoneBrickStairs,
	kMCBlockNetherBrickStairs,
	kMCBlockEndPortalFrame,
	kMCBlockDragonEgg,
	kMCBlockWoodenSingleSlab,
	kMCBlockSandstoneStairs,
	kMCBlockSpruceWoodStairs,
	kMCBlockBirchWoodStairs,
	kMCBlockJungleWoodStairs,
	kMCBlockBeacon,
	kMCBlockQuartzStairs,
};


static const uint8_t kLiquidIDs[] =
{
	kMCBlockWater,
	kMCBlockStationaryWater,
	kMCBlockLava,
	kMCBlockStationaryLava
};


static const uint8_t kItemIDs[] =
{
	kMCBlockSapling,
	kMCBlockBed,
	kMCBlockPoweredRail,
	kMCBlockDetectorRail,
	kMCBlockCobweb,
	kMCBlockTallGrass,
	kMCBlockDeadShrubs,
	kMCBlockPistonHead,
	kMCBlockMovingPiston,
	kMCBlockYellowFlower,
	kMCBlockRedFlower,
	kMCBlockBrownMushroom,
	kMCBlockRedMushroom,
	kMCBlockTorch,
	kMCBlockFire,
	kMCBlockChest,
	kMCBlockRedstoneWire,
	kMCBlockCrops,
	kMCBlockSignPost,
	kMCBlockWoodenDoor,
	kMCBlockLadder,
	kMCBlockRail,
	kMCBlockWallSign,
	kMCBlockLever,
	kMCBlockStonePressurePlate,
	kMCBlockIronDoor,
	kMCBlockWoodenPressurePlate,
	kMCBlockRedstoneTorchOff,
	kMCBlockRedstoneTorchOn,
	kMCBlockStoneButton,
	kMCBlockSnow,
	kMCBlockIce,
	kMCBlockCactus,
	kMCBlockReed,
	kMCBlockFence,
	kMCBlockNetherBrickFence,
	kMCBlockPortal,
	kMCBlockCake,
	kMCBlockRedstoneRepeaterOff,
	kMCBlockRedstoneRepeaterOn,
	kMCBlockTrapdoor,
	kMCBlockIronBars,
	kMCBlockGlassPane,
	kMCBlockVines,
	kMCBlockGate,
	kMCBlockPumpkinStem,
	kMCBlockMelonStem,
	kMCBlockLilyPad,
	kMCBlockNetherWart,
	kMCBlockEnchantmentTable,
	kMCBlockBrewingStand,
	kMCBlockCauldron,
	kMCBlockEndPortal,
	kMCBlockCocoaPod,
	KMCBlockEnderChest,
	kMCBlockTripwireHook,
	kMCBlockTripwire,
	kMCBlockCobblestoneWall,
	kMCBlockFlowerPot,
	kMCBlockCarrots,
	kMCBlockPotatoes,
	kMCBlockWoodenButton,
	kMCBlockHead,
	kMCBlockAnvil,
	kMCBlockTrappedChest,
	kMCBlockGoldPressurePlate,
	kMCBlockIronPressurePlate,
	kMCBlockRedstoneComparatorOff,
	kMCBlockRedstoneComparatorOn,
	kMCBlockDaylightSensor,
	kMCBlockHopper,
	kMCBlockActivatorRail,
	kMCBlockCarpet,
};


static const uint8_t kUnusedIDs[] =
{
	160, 161, 162, 163, 164, 165, 166, 167, 168, 169,
};


static const uint8_t kTileEntityIDs[] =
{
	/*
		NOTE: these must have a corresponding entry in
		MCExpectedTileEntityTypeForBlockID() in JAMinecraftTypes.m.
	*/
	kMCBlockDispenser,
	kMCBlockMovingPiston,
	kMCBlockNoteBlock,
	kMCBlockMobSpawner,
	kMCBlockChest,
	kMCBlockFurnace,
	kMCBlockBurningFurnace,
	kMCBlockSignPost,
	kMCBlockWallSign,
	kMCBlockJukebox,
	kMCBlockEnchantmentTable,
	kMCBlockBrewingStand,
	kMCBlockEndPortal,
	KMCBlockEnderChest,
	kMCBlockCommandBlock,
	kMCBlockBeacon,
	kMCBlockHead,
	kMCBlockTrappedChest,
	kMCBlockRedstoneComparatorOff,
	kMCBlockRedstoneComparatorOn,
	kMCBlockDaylightSensor,
	kMCBlockHopper,
	kMCBlockDropper,
};


static const uint8_t kPowerSourceIDs[] =
{
	kMCBlockDetectorRail,
	kMCBlockLever,
	kMCBlockStonePressurePlate,
	kMCBlockWoodenPressurePlate,
	kMCBlockRedstoneTorchOff,
	kMCBlockRedstoneTorchOn,
	kMCBlockStoneButton,
	kMCBlockWoodenButton,
	kMCBlockTripwireHook,
	kMCBlockChest,
	kMCBlockFurnace,
	kMCBlockTrappedChest,
	kMCBlockGoldPressurePlate,
	kMCBlockIronPressurePlate,
	kMCBlockRedstoneComparatorOff,
	kMCBlockRedstoneComparatorOn,
	kMCBlockDaylightSensor,
	kMCBlockRedstoneBlock,
	kMCBlockHopper,
	kMCBlockDropper,
};


static const uint8_t kPowerSinkIDs[] =
{
	kMCBlockPoweredRail,
	kMCBlockRedstoneWire,
	kMCBlockTNT,
	kMCBlockWoodenDoor,
	kMCBlockRail,
	kMCBlockIronDoor,
	kMCBlockRedstoneTorchOff,
	kMCBlockRedstoneTorchOn,
	kMCBlockDispenser,
	kMCBlockNoteBlock,
	kMCBlockGate,
	kMCBlockRedstoneLampOff,
	kMCBlockRedstoneLampOn,
	kMCBlockCommandBlock,
	kMCBlockRedstoneComparatorOff,
	kMCBlockRedstoneComparatorOn,
	kMCBlockHopper,
	kMCBlockActivatorRail,
	kMCBlockDropper,
};


static const uint8_t kVegetableIDs[] =
{
	kMCBlockTallGrass,
	kMCBlockDeadShrubs,
	kMCBlockSapling,
	kMCBlockYellowFlower,
	kMCBlockRedFlower,
	kMCBlockBrownMushroom,
	kMCBlockRedMushroom,
	kMCBlockCrops,
	kMCBlockCactus,
	kMCBlockReed,
	kMCBlockLog,
	kMCBlockLeaves,
	kMCBlockPumpkin,
	kMCBlockWatermelon,
	kMCBlockVines,
	kMCBlockHugeBrownMushroom,
	kMCBlockHugeRedMushroom,
	kMCBlockPumpkinStem,
	kMCBlockMelonStem,
	kMCBlockLilyPad,
	kMCBlockNetherWart,
	kMCBlockCocoaPod,
	kMCBlockCarrots,
	kMCBlockPotatoes,
};


static const uint8_t kOreIDs[] =
{
	kMCBlockGoldOre,
	kMCBlockIronOre,
	kMCBlockCoalOre,
	kMCBlockDiamondOre,
	kMCBlockRedstoneOre,
	kMCBlockGlowingRedstoneOre,
	kMCBlockLapisLazuliOre,
	kMCBlockEmeraldOre,
	kMCBlockNetherQuartzOre,
};


static const uint8_t kRailIDs[] =
{
	kMCBlockRail,
	kMCBlockPoweredRail,
	kMCBlockDetectorRail,
	kMCBlockActivatorRail,
};


static const uint8_t kPistonIDs[] =
{
	kMCBlockPiston,
	kMCBlockStickyPiston,
	kMCBlockPistonHead,
};


static const uint8_t kStairIDs[] =
{
	kMCBlockWoodenStairs,
	kMCBlockCobblestoneStairs,
	kMCBlockBrickStairs,
	kMCBlockStoneBrickStairs,
	kMCBlockNetherBrickStairs,
	kMCBlockSandstoneStairs,
	kMCBlockSpruceWoodStairs,
	kMCBlockBirchWoodStairs,
	kMCBlockJungleWoodStairs,
	kMCBlockQuartzStairs,
};


static void ApplyAttribute(const uint8_t *idList, size_t idCount, JAMCBlockIDMetadata flag, JAMCBlockIDMetadata attributeMap[256]);

#define APPLY_ATTRIBUTE(idList, flag)  ApplyAttribute(idList, sizeof idList / sizeof *idList, flag, attributeMap)

static bool IsUnusedID(uint8_t blockID);


int main (int argc, const char * argv[])
{
	JAMCBlockIDMetadata attributeMap[256];
	memset(attributeMap, 0, sizeof attributeMap);
	
	APPLY_ATTRIBUTE(kOpaqueIDs, kMCBlockIsOpaque);
	APPLY_ATTRIBUTE(kTransparentIDs, kMCBlockIsTransparent);
	APPLY_ATTRIBUTE(kLiquidIDs, kMCBlockIsLiquid);
	APPLY_ATTRIBUTE(kItemIDs, kMCBlockIsItem);
	
	/*
		Sanity check: ensure all known block IDs have a
		classification, and all unknown block IDs don’t.
	*/
	unsigned i;
	for (i = 0; i <= kMCLastBlockID; i++)
	{
		if (IsUnusedID(i))  continue;
		
		JAMCBlockIDMetadata attr = attributeMap[i] & 0x0F;
		if (attr == 0)
		{
			fprintf(stderr, "error: block ID %u has no basic category.\n", i);
			exit(EXIT_FAILURE);
		}
		if (attr != kMCBlockIsOpaque && attr != kMCBlockIsTransparent && attr != kMCBlockIsLiquid && attr != kMCBlockIsItem)
		{
			fprintf(stderr, "error: block ID %u has more than one basic category (0x%X).\n", i, attr);
			exit(EXIT_FAILURE);
		}
	}
	for (; i < 256; i++)
	{
		JAMCBlockIDMetadata attr = attributeMap[i];
		if (attr != 0)
		{
			fprintf(stderr, "error: block ID %u is beyond kMCLastBlockID, but has attributes set (0x%X).\n", i, attr);
			exit(EXIT_FAILURE);
		}
	}
	for (i = 0; i < sizeof kUnusedIDs / sizeof *kUnusedIDs; i++)
	{
		JAMCBlockIDMetadata attr = attributeMap[kUnusedIDs[i]];
		if (attr != 0)
		{
			fprintf(stderr, "error: block ID %u is beyond kMCLastBlockID, but has attributes set (0x%X).\n", i, attr);
			exit(EXIT_FAILURE);
		}
	}
	
	APPLY_ATTRIBUTE(kTileEntityIDs, kMCBlockHasTileEntity);
	APPLY_ATTRIBUTE(kRailIDs, kMCBlockIsRail);
	APPLY_ATTRIBUTE(kPistonIDs, kMCBlockIsPiston);
	APPLY_ATTRIBUTE(kPowerSourceIDs, kMCBlockIsPowerSource);
	APPLY_ATTRIBUTE(kPowerSinkIDs, kMCBlockIsPowerSink);
	APPLY_ATTRIBUTE(kVegetableIDs, kMCBlockIsVegetable);
	APPLY_ATTRIBUTE(kOreIDs, kMCBlockIsOre);
	APPLY_ATTRIBUTE(kStairIDs, kMCBlockIsStairs);
	
	printf("/*\n\tJAMinecraftBlockIDs.c\n\t\n\tThis file is automatically generated by the attributeMapBuilder tool.\n\tDo not edit.\n*/\n\n#include \"JAMinecraftBlockIDs.h\"\n\nconst JAMCBlockIDMetadata kMCBlockTypeClassifications[256] =\n{\n");
	
	for (i = 0; i < 256; i++)
	{
		printf("\t0x%.4X%s\n", attributeMap[i], (i < 255) ? "," : "");
	}
	printf("};\n");
	return EXIT_SUCCESS;
}


static void ApplyAttribute(const uint8_t *idList, size_t idCount, JAMCBlockIDMetadata flag, JAMCBlockIDMetadata attributeMap[256])
{
	for (size_t i = 0; i < idCount; i++)
	{
		uint8_t blockID = idList[i];
		attributeMap[blockID] |= flag;
	}
}


static bool IsUnusedID(uint8_t blockID)
{
	if (blockID > kMCLastBlockID)  return true;
	for (unsigned i = 0; i < sizeof kUnusedIDs / sizeof *kUnusedIDs; i++)
	{
		if (blockID == kUnusedIDs[i])  return true;
	}
	
	return false;
}
