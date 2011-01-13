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
	kMCBlockNoteBlock,	// FIXME: test.
	26, 27, 28, 29, 30, 31, 32, 33, 34, 36,	// Classic-only cloth blocks
	kMCBlockWhiteCloth,
	kMCBlockGoldBlock,
	kMCBlockIronBlock,
	kMCBlockDoubleStep,
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
	kMCBlockJackOLantern
};


// Blocks which appear as solid but act as air for redstone.
static const uint8_t kQuasiSolidIDs[] =
{
	kMCBlockLeaves,
	kMCBlockGlass,
	kMCBlockSingleStep,
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
	kMCBlockYellowFlower,
	kMCBlockRedFlower,
	kMCBlockBrownMushroom,
	kMCBlockRedMushroom,
	kMCBlockLantern,
	kMCBlockFire,
	kMCBlockRedstoneWire,
	kMCBlockCrops,
	kMCBlockSignPost,
	kMCBlockWoodenDoor,
	kMCBlockLadder,
	kMCBlockMinecartTrack,
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
	kMCBlockPortal
};


static const uint8_t kPowerSourceIDs[] =
{
	kMCBlockLever,
	kMCBlockStonePressurePlate,
	kMCBlockWoodenPressurePlate,
	kMCBlockRedstoneTorchOff,
	kMCBlockRedstoneTorchOn,
	kMCBlockStoneButton
};


static const uint8_t kPowerSinkIDs[] =
{
	kMCBlockRedstoneWire,
	kMCBlockTNT,
	kMCBlockWoodenDoor,
	kMCBlockMinecartTrack,
	kMCBlockIronDoor,
	kMCBlockRedstoneTorchOff,
	kMCBlockRedstoneTorchOn,
	kMCBlockNoteBlock
};


static const uint8_t kVegetableIDs[] =
{
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
	kMCBlockDiamondOre,
	kMCBlockRedstoneOre,
	kMCBlockGlowingRedstoneOre,
	kMCBlockLapisLazuliOre
};


static void ApplyAttribute(const uint8_t *idList, size_t idCount, JAMCBlockIDMetadata flag, uint8_t attributeMap[256]);

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
	
	APPLY_ATTRIBUTE(kPowerSourceIDs, kMCBlockIsPowerSource);
	APPLY_ATTRIBUTE(kPowerSinkIDs, kMCBlockIsPowerSink);
	APPLY_ATTRIBUTE(kVegetableIDs, kMCBlockIsVegetable);
	APPLY_ATTRIBUTE(kOreIDs, kMCBlockIsOre);
	
	printf("/*\n\tJAMinecraftBlockIDs.c\n\t\n\tThis file is automatically generated by the attributeMapBuilder tool.\n\tDo not edit.\n*/\n\n#include \"JAMinecraftBlockIDs.h\"\n\nconst JAMCBlockIDMetadata kMCBlockTypeClassifications[256] =\n{\n");
	
	for (i = 0; i < 256; i++)
	{
		printf("\t0x%X%s\n", attributeMap[i], (i < 255) ? "," : "");
	}
	printf("};\n");
	return EXIT_SUCCESS;
}


static void ApplyAttribute(const uint8_t *idList, size_t idCount, JAMCBlockIDMetadata flag, uint8_t attributeMap[256])
{
	for (size_t i = 0; i < idCount; i++)
	{
		uint8_t blockID = idList[i];
		attributeMap[blockID] |= flag;
	}
}
