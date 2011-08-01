/*
	attributeMapBuilder.c
	
	This tool generates the kMCBlockTypeClassifications lookup table for
	MinecraftKit. Below this here comment you will find a list of blocks for
	each of the defined attributes. These are then packed into bitfields of
	attributes for each block type. Yawn.
	
	When JAMinecraftBlockIDs.h is updated with new block types, the attributes
	need to be updated and a new JAMinecraftBlockIDs.c generated.
	
	
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


#include "JAMinecraftBlockIDs.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>


static const uint8_t kFullySolidIDs[] =
{
	kMCBlockSmoothStone,
	kMCBlockGrass,
	kMCBlockDirt,
	kMCBlockCobblestone,
	kMCBlockWood,
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
	kMCBlockNoteBlock,		// FIXME: test.
	kMCBlockStickyPiston,	// FIXME: test.
	kMCBlockPiston,			// FIXME: test.
	kMCBlockCloth,
	kMCBlockGoldBlock,
	kMCBlockIronBlock,
	kMCBlockDoubleSlab,
	kMCBlockBrick,
	kMCBlockTNT,
	kMCBlockBookshelf,
	kMCBlockMossyCobblestone,
	kMCBlockObsidian,
	kMCBlockChest,
	kMCBlockDiamondOre,
	kMCBlockDiamondBlock,
	kMCBlockWorkbench,
	kMCBlockSoil,
	kMCBlockFurnace,
	kMCBlockBurningFurnace,
	kMCBlockRedstoneOre,
	kMCBlockGlowingRedstoneOre,
	kMCBlockSnowBlock,
	kMCBlockClay,
	kMCBlockJukebox,
	kMCBlockPumpkin,
	kMCBlockNetherstone,
	kMCBlockSlowSand,
	kMCBlockLightstone,
	kMCBlockJackOLantern,
	kMCBlockLockedChest
};


// Blocks which appear as solid but act as air for redstone.
static const uint8_t kQuasiSolidIDs[] =
{
	kMCBlockLeaves,
	kMCBlockGlass,
	kMCBlockSingleSlab,
	kMCBlockMobSpawner,
	kMCBlockWoodenStairs,
	kMCBlockCobblestoneStairs
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
	kMCBlock36,
	kMCBlockYellowFlower,
	kMCBlockRedFlower,
	kMCBlockBrownMushroom,
	kMCBlockRedMushroom,
	kMCBlockTorch,
	kMCBlockFire,
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
	kMCBlockPortal,
	kMCBlockCake,
	kMCBlockRedstoneRepeaterOff,
	kMCBlockRedstoneRepeaterOn,
	kMCBlockTrapdoor
};


static const uint8_t kTileEntityIDs[] =
{
	/*
		NOTE: these must have a corresponding entry in
		MCExpectedTileEntityTypeForBlockID() in JAMinecraftTypes.m.
	*/
	kMCBlockDispenser,
	kMCBlock36,
	kMCBlockNoteBlock,
	kMCBlockMobSpawner,
	kMCBlockChest,
	kMCBlockFurnace,
	kMCBlockBurningFurnace,
	kMCBlockSignPost,
	kMCBlockWallSign,
	kMCBlockJukebox
};


static const uint8_t kPowerSourceIDs[] =
{
	kMCBlockDetectorRail,
	kMCBlockLever,
	kMCBlockStonePressurePlate,
	kMCBlockWoodenPressurePlate,
	kMCBlockRedstoneTorchOff,
	kMCBlockRedstoneTorchOn,
	kMCBlockStoneButton
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
	kMCBlockNoteBlock
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
};


static const uint8_t kOreIDs[] =
{
	kMCBlockGoldOre,
	kMCBlockIronOre,
	kMCBlockCoalOre,
	kMCBlockLapisLazuliOre,
	kMCBlockDiamondOre,
	kMCBlockRedstoneOre,
	kMCBlockGlowingRedstoneOre,
	kMCBlockLapisLazuliOre
};


static const uint8_t kRailIDs[] =
{
	kMCBlockRail,
	kMCBlockPoweredRail,
	kMCBlockDetectorRail
};


static const uint8_t kPistonIDs[] =
{
	kMCBlockPiston,
	kMCBlockStickyPiston,
	kMCBlockPistonHead
};


static void ApplyAttribute(const uint8_t *idList, size_t idCount, JAMCBlockIDMetadata flag, JAMCBlockIDMetadata attributeMap[256]);

#define APPLY_ATTRIBUTE(idList, flag)  ApplyAttribute(idList, sizeof idList / sizeof *idList, flag, attributeMap)


int main (int argc, const char * argv[])
{
	JAMCBlockIDMetadata attributeMap[256];
	memset(attributeMap, 0, sizeof attributeMap);
	
	APPLY_ATTRIBUTE(kFullySolidIDs, kMCBlockIsFullySolid);
	APPLY_ATTRIBUTE(kQuasiSolidIDs, kMCBlockIsQuasiSolid);
	APPLY_ATTRIBUTE(kLiquidIDs, kMCBlockIsLiquid);
	APPLY_ATTRIBUTE(kItemIDs, kMCBlockIsItem);
	
	/*
		Sanity check: ensure all known block IDs except air have a
		classification, and all unknown block IDs don’t.
	*/
	unsigned i;
	for (i = 1; i < kMCLastBlockID; i++)
	{
		JAMCBlockIDMetadata attr = attributeMap[i] & 0x0F;
		if (attr == 0)
		{
			fprintf(stderr, "Error: block ID %u has no basic category.\n", i);
			exit(EXIT_FAILURE);
		}
		if (attr != kMCBlockIsFullySolid && attr != kMCBlockIsQuasiSolid && attr != kMCBlockIsLiquid && attr != kMCBlockIsItem)
		{
			fprintf(stderr, "Error: block ID %u has more than one basic category (0x%X).\n", i, attr);
			exit(EXIT_FAILURE);
		}
	}
	for (; i < 256; i++)
	{
		JAMCBlockIDMetadata attr = attributeMap[i];
		if (attr < 0)
		{
			fprintf(stderr, "Error: block ID %u is beyond kMCLastBlockID, but has attributes set (0x%X).\n", i, attr);
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
