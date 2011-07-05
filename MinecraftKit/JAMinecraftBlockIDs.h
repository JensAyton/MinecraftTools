/*
	BlockID values.
	
	Source: http://www.minecraftwiki.net/wiki/Data_values
*/


#if __cplusplus
#ifndef JA_INLINE
#define JA_INLINE inline
#endif
#if __cplusplus
#define JA_EXTERN extern "C"
#endif

#include <cstdint>
#else
#ifndef JA_EXTERN
#define JA_EXTERN extern
#endif
#ifndef JA_INLINE
#define JA_INLINE static inline
#endif

#include <stdint.h>
#include <stdbool.h>
#endif


enum
{
	kMCBlockAir								= 0,
	kMCBlockSmoothStone						= 1,
	kMCBlockGrass							= 2,
	kMCBlockDirt							= 3,
	kMCBlockCobblestone						= 4,
	kMCBlockWood							= 5,
	kMCBlockSapling							= 6,	// Data: kMCInfoWoodTypeMask and kMCInfoSaplingAge
	kMCBlockBedrock							= 7,	// “Adminium”
	kMCBlockWater							= 8,	// Data: kMCInfoLiquidEmptinessMask and kMCInfoLiquidFlowing
	kMCBlockStationaryWater					= 9,	// Data: wiki links to same data as for flowing water. Only kMCInfoLiquidFlowing relevant? Unconfirmed.
	kMCBlockLava							= 10,	// Like kMCBlockWater
	kMCBlockStationaryLava					= 11,	// Like kMCBlockStationaryWater
	kMCBlockSand							= 12,
	kMCBlockGravel							= 13,
	kMCBlockGoldOre							= 14,
	kMCBlockIronOre							= 15,
	kMCBlockCoalOre							= 16,	// “Coal ore”? Meh. You get the point.
	kMCBlockLog								= 17,	// Data: kMCInfoWoodType
	kMCBlockLeaves							= 18,	// Data: kMCInfoLeafUpdatePendingMask and kMCInfoWoodType
	kMCBlockSponge							= 19,
	kMCBlockGlass							= 20,
	kMCBlockLapisLazuliOre					= 21,
	kMCBlockLapisLazuliBlock				= 22,
	kMCBlockDispenser						= 23,	// Data: kMCInfoMisc2Orientation
	kMCBlockSandstone						= 24,
	kMCBlockNoteBlock						= 25,	// No blockData; information is stored in a tile entity. (Unconfirmed)
	kMCBlockBed								= 26,	// Data: kMCInfoMisc3OrientationMask (direction of foot of bed) and kInfoBedIsHead.
	kMCBlockPoweredRail						= 27,	// Data: kMCInfoPoweredRailOrientationMask and kMCInfoPoweredRailIsPowered.
	kMCBlockDetectorRail					= 28,	// Data: kMCInfoPoweredRailOrientationMask
	kMCBlockStickyPiston					= 29,	// Data: kMCInfoPistonOrientationMask
	kMCBlockCobweb							= 30,
	kMCBlockTallGrass						= 31,	// Data: kMCInfoTallGrassTypeMask
	kMCBlockDeadShrubs						= 32,
	kMCBlockPiston							= 33,	// Data: kMCInfoPistonOrientationMask
	kMCBlockPistonHead						= 34,	// Data: kMCInfoPistonOrientationMask and kMCInfoPistonHeadIsSticky
	kMCBlockCloth							= 35,	// Data: kMCInfoWoolColor
	// 36 currently unused in Beta
	kMCBlockYellowFlower					= 37,
	kMCBlockRedFlower						= 38,
	kMCBlockBrownMushroom					= 39,
	kMCBlockRedMushroom						= 40,
	kMCBlockGoldBlock						= 41,
	kMCBlockIronBlock						= 42,
	kMCBlockDoubleSlab						= 43,	// Two half-steps on top of each other. Data: kMCInfoSlabTypeMask
	kMCBlockSingleSlab						= 44,	// A single half-step. Data: kMCInfoSlabTypeMask
	kMCBlockBrick							= 45,
	kMCBlockTNT								= 46,
	kMCBlockBookshelf						= 47,
	kMCBlockMossyCobblestone				= 48,
	kMCBlockObsidian						= 49,
	kMCBlockTorch							= 50,	// Data: kMCInfoMiscOrientation.
	kMCBlockFire							= 51,	// Data: kMCBlockFireGenerationMask
	kMCBlockMobSpawner						= 52,	// No blockData; information is stored in a tile entity.
	kMCBlockWoodenStairs					= 53,	// Data: kMCInfoStairOrientationMask
	kMCBlockChest							= 54,	// No blockData; information is stored in a tile entity.
	kMCBlockRedstoneWire					= 55,
	kMCBlockDiamondOre						= 56,
	kMCBlockDiamondBlock					= 57,
	kMCBlockWorkbench						= 58,
	kMCBlockCrops							= 59,
	kMCBlockSoil							= 60,
	kMCBlockFurnace							= 61,	// Data: kMCInfoMisc2Orientation; other information is stored in a tile entity.
	kMCBlockBurningFurnace					= 62,	// As normal furnace.
	kMCBlockSignPost						= 63,	// Sign on ground. Data: kMCInfoSignPostOrientation; has tile entity.
	kMCBlockWoodenDoor						= 64,
	kMCBlockLadder							= 65,
	kMCBlockRail							= 66,
	kMCBlockCobblestoneStairs				= 67,	// Data: kMCInfoStairOrientation
	kMCBlockWallSign						= 68,	// Sign on wall. Data: kMCInfoMisc2Orientation; has tile entity.
	kMCBlockLever							= 69,
	kMCBlockStonePressurePlate				= 70,
	kMCBlockIronDoor						= 71,
	kMCBlockWoodenPressurePlate				= 72,
	kMCBlockRedstoneOre						= 73,
	kMCBlockGlowingRedstoneOre				= 74,
	kMCBlockRedstoneTorchOff				= 75,	// Data: kMCInfoMiscOrientation.
	kMCBlockRedstoneTorchOn					= 76,	// Data: kMCInfoMiscOrientation.
	kMCBlockStoneButton						= 77,	// Data: kMCInfoMiscOrientation.
	kMCBlockSnow							= 78,
	kMCBlockIce								= 79,
	kMCBlockSnowBlock						= 80,
	kMCBlockCactus							= 81,	// Data: kMCInfoCactusAge
	kMCBlockClay							= 82,
	kMCBlockReed							= 83,
	kMCBlockJukebox							= 84,
	kMCBlockFence							= 85,
	kMCBlockPumpkin							= 86,	// Data: kMCInfoMisc3Orientation.
	kMCBlockNetherstone						= 87,	// Hellstone/red nether stuff
	kMCBlockSlowSand						= 88,	// Mud/brown nether stuff
	kMCBlockLightstone						= 89,	// Shiny yellow nether stuff
	kMCBlockPortal							= 90,
	kMCBlockJackOLantern					= 91,	// Data: kMCInfoMisc3Orientation.
	kMCBlockCake							= 92,	// Data: kMCInfoCakeSliceCountMask
	kMCBlockRedstoneRepeaterOff				= 93,	// Data: kMCInfoMisc3OrientationMask and kMCInfoRedstoneRepeaterDelayMask
	kMCBlockRedstoneRepeaterOn				= 94,	// Data: kMCInfoMisc3OrientationMask and kMCInfoRedstoneRepeaterDelayMask	
	kMCBlockLockedChest						= 95,	// April 1 2011 easter egg item, currently deteriorates like leaves.
	kMCBlockTrapdoor						= 96,	// FIXME: data
};


#define kMCLastBlockID kMCBlockTrapdoor


/*
	BlockData bit masks. The meaning of bits depends on the block ID.
	Names ending with “Mask” are multi-bit values.
	
	Note that additional information is stored in the TileEntities structure
	for the following block types: Furnace, Sign, MobSpawner, Chest. Signs
	have both block data and tile entity data.
	
	In actual map data, the high nybble of the data byte is used for lighting.
	In schematics, it’s unused.
*/
enum
{
	/*	Air: MCKit-internal “hole” flag indicates a block that shouldn’t
		overwrite other blocks and should be transparent in renderings
		(corresponding to “shadow” blocks in Redstone Simulator).
	*/
	kMCInfoAirIsHoleMask					= 0x10,
	
	/*	Sapling: low 2 bits are kMCInfoWoodTypeMask. The next two bits –
		kMCInfoSaplingAge – are “age”. This value is incremented randomly until
		it’s incremented beyond 3, when the sapling is replaced with a tree.
		
		NOTE: prior to Beta 1.5, a 4-bit age value was used. 1.5 appears to
		ignore the difference when opening old files, so wild saplings (and
		leaf blocks) were quasi-randomly assigned species.
	*/
	kMCInfoSaplingAge						= 0x0C,
	
	/*	Water: emptiness ranges from 0 (full) to 7 (nearly empty).
		Falling is set for vertically flowing water/lava.
		In the overworld, lava only uses the even-valued emptinesses. It looks
		like the full range is used in the nether, but I haven’t confirmed this
		on data.
	*/
	kMCInfoLiquidEmptinessMask				= 0x07,
	kMCInfoLiquidFlowing					= 0x80,
	
	/*	Wood: type/species.
		Affects texture only.
	*/
	kMCInfoWoodTypeMask						= 0x03,
	kMCInfoWoodTypeDefault					= 0x00,
	kMCInfoWoodTypeConifer					= 0x01,
	kMCInfoWoodTypeBirch					= 0x02,
	
	/*
		Leaves: if this flag is set, the leaf block will be checked for random
		decay. If it’s clear, the block won’t decay (but the flag is set again
		if any adjacent block changes).
		
		Advice: if adding leaf blocks, set the flag and let Minecraft clear it
		when valid.
	*/
	kMCInfoLeafUpdatePendingMask			= 0x04,
	
	/*	Wool: colour.
		This is represented by different block IDs in Creative.
	*/
	kMCInfoWoolColorMask					= 0x0F,
	kMCInfoWoolColorWhite					= 0x00,
	kMCInfoWoolColorOrange					= 0x01,
	kMCInfoWoolColorMagenta					= 0x02,
	kMCInfoWoolColorLightBlue				= 0x03,
	kMCInfoWoolColorYellow					= 0x04,
	kMCInfoWoolColorLightGreen				= 0x05,
	kMCInfoWoolColorPink					= 0x06,
	kMCInfoWoolColorGray					= 0x07,
	kMCInfoWoolColorLightGray				= 0x08,
	kMCInfoWoolColorCyan					= 0x09,
	kMCInfoWoolColorPurple					= 0x0A,
	kMCInfoWoolColorBlue					= 0x0B,
	kMCInfoWoolColorBrown					= 0x0C,
	kMCInfoWoolColorDarkGreen				= 0x0D,
	kMCInfoWoolColorRed						= 0x0E,
	kMCInfoWoolColorBlack					= 0x0F,
	
	/*	Several block types use these orientation flags, but some oriented
		block types do not. Use MCCellGet/SetOrientation() for generic access.
		Block types using MiscOrientation:
			Torch/lantern
			Redstone torch (off and on)
			Lever (special case for two on-floor versions, see below)
			Stone button
	*/
	kMCInfoMiscOrientationMask				= 0x07,
	kMCInfoMiscOrientationSouth				= 0x01,
	kMCInfoMiscOrientationNorth				= 0x02,
	kMCInfoMiscOrientationWest				= 0x03,
	kMCInfoMiscOrientationEast				= 0x04,
	kMCInfoMiscOrientationFloor				= 0x05,	// See also: kMCInfoLeverOrientationFloorEW and kMCInfoLeverOrientationFloorNS
	
	/*	Bed flag: set for head block, clear for foot block.
	*/
	kInfoBedIsHead							= 0x08,
	
	/*	Stair orientations, for wooden and stone stairs.
		The labels are intended to refer to the _ascending_ direction.
	*/
	kMCInfoStairOrientationMask				= 0x03,
	kMCInfoStairOrientationSouth			= 0x00,
	kMCInfoStairOrientationNorth			= 0x01,
	kMCInfoStairOrientationWest				= 0x02,
	kMCInfoStairOrientationEast				= 0x03,
	
	/*	Redstone signal strength varies from 0 to 15.
	*/
	kMCInfoRedstoneWireSignalStrengthMask	= 0x0F,
	
	/*	Age of crops varies from 0 to 7. 0 is newly planted, 7 is ready wheat.
	*/
	kMCInfoCropsAgeMask						= 0x07,
	
	/*	According to the wiki, soil wetness varies from 0 (dry) to 8, which is a bit odd.
	*/
	kMCInfoSoilWetnessMask					= 0x0F,
	
	/*	Signpost orientation ranges from 0 (west) to 15, clockwise.
	*/
	kMCInfoSignPostOrientationMask			= 0x0F,
	
	/*	Door orientations are facing directions of closed doors. Open doors
		swing anti-clockwise.
	 */
	kMCInfoDoorOrientationMask				= 0x03,
	kMCInfoDoorOrientationEast				= 0x00,
	kMCInfoDoorOrientationNorth				= 0x01,
	kMCInfoDoorOrientationWest				= 0x02,
	kMCInfoDoorOrientationSouth				= 0x03,
	kMCInfoInfoDoorOpen						= 0x04,
	kMCInfoInfoDoorTopHalf					= 0x08,
	
	/*	kInfoMisc2Orientation
		Another common set of orientation flags, used for:
		* Ladders
		* Wall signs
		* Furnaces
		* Dispensers
	*/
	kMCInfoMisc2OrientationMask				= 0x07,
	kMCInfoMisc2OrientationEast				= 0x02,
	kMCInfoMisc2OrientationWest				= 0x03,
	kMCInfoMisc2OrientationNorth			= 0x04,
	kMCInfoMisc2OrientationSouth			= 0x05,
	
	/*	Minecart track orientations. Note that these don’t map to the same
		set of orientations as most of the other “orientation” value sets.
		
		kMCInfoRailOrientationMask represents the orientations available to
		regular tracks. kMCInfoPoweredRailOrientationMask represents the
		orientations available to powered rails and detector rails.
	 */
	kMCInfoRailOrientationMask				= 0x0F,
	kMCInfoPoweredRailOrientationMask		= 0x07,
	// Straight sections.
	kMCInfoRailOrientationNorthSouth		= 0x00,
	kMCInfoRailOrientationEastWest			= 0x01,
	// Hill sections.
	kMCInfoRailOrientationRisingSouth		= 0x02,
	kMCInfoRailOrientationRisingNorth		= 0x03,
	kMCInfoRailOrientationRisingEast		= 0x04,
	kMCInfoRailOrientationRisingWest		= 0x05,
	// Curve sections, with endpoint (outward) directions in clockwise order.
	kMCInfoRailOrientationWestSouth			= 0x06,	// ◝
	kMCInfoRailOrientationNorthWest			= 0x07,	// ◞
	kMCInfoRailOrientationEastNorth			= 0x08,	// ◟
	kMCInfoRailOrientationSouthEast			= 0x09,	// ◜
	
	kMCInfoPoweredRailIsPowered				= 0x08,
	
	/*	Levers use a variant of the misc orientation flags with two distinct
		floor orientations. They also have an on/off flag.
	*/
	kMCInfoLeverOrientationFloorEW			= 0x05,
	kMCInfoLeverOrientationFloorNS			= 0x06,
	kMCInfoLeverOn							= 0x08,
	
	kMCInfoButtonOn							= kMCInfoLeverOn,
	
	/*	Pressure plates: they can be on, or not on.
	*/
	kMCInfoPressurePlateOn					= 0x01,
	
	/*	Cactus: low 4 bits are “age”. This value is incremented randomly
		until the cactus is old enough to spawn another block on top of it,
		unless there are two cactus blocks below it.
	*/
	kMCInfoCactusAgeMask					= 0x0F,
	
	/*	Pumpkin/Jack-o-lanternU/bed orientation.
	*/
	kMCInfoMisc3OrientationMask				= 0x03,
	kMCInfoMisc3OrientationEast				= 0x00,
	kMCInfoMisc3OrientationSouth			= 0x01,
	kMCInfoMisc3OrientationWest				= 0x02,
	kMCInfoMisc3OrientationNorth			= 0x03,
	
	/*	Orientation values for pistons and piston heads. These represent the
		facing of the piston head surface.
	*/
	kMCInfoPistonOrientationMask			= 0x07,
	kMCInfoPistonOrientationDown			= 0x00,
	kMCInfoPistonOrientationUp				= 0x01,
	kMCInfoPistonOrientationEast			= 0x02,
	kMCInfoPistonOrientationWest			= 0x03,
	kMCInfoPistonOrientationNorth			= 0x04,
	kMCInfoPistonOrientationSouth			= 0x05,
	
	/*	Sticky and non-sticky piston bases are distinguished by type, but heads
		use a flag. Oh, that wacky Jeb.
	*/
	kMCInfoPistonHeadIsSticky				= 0x08,
	
	/*	Types of “tall grass” (or, more generally, ground cover).
		Note that “dead shrubs” can be represented as their own block type or as a
		tall grass object (which apparently yields seeds).
	*/
	kMCInfoTallGrassTypeMask				= 0x03,
	kMCInfoTallGrassTypeDeadShrub			= 0x00,
	kMCInfoTallGrassTypeTallGrass			= 0x01,
	kMCInfoTallGrassTypeFern				= 0x02,
	
	/*	Types of slab/half-step.
	*/
	kMCInfoSlabTypeMask						= 0x03,
	kMCInfoSlabTypeStone					= 0x00,
	kMCInfoSlabTypeSandstone				= 0x01,
	kMCInfoSlabTypeWood						= 0x02,
	kMCInfoSlabTypeCobblestone				= 0x03,
	
	/*	Fire generation: as I understand it, the source of a fire is generation
		0, and each time fire spreads the new block has a higher generation.
		Fire of generation 15 doesn’t spread.
	*/
	kMCBlockFireGenerationMask				= 0x0F,
	
	/*	How eaten a cake is, ranging from 0 (whole) to 5 (almost gone).
	*/
	kMCInfoCakeSliceCountMask				= 0x07,
	
	/*	Redstone repeater delay setting, in redstone update ticks. (Equivalent
		to shifting right by two and adding one.)
	*/
	kMCInfoRedstoneRepeaterDelayMask		= 0x0C,
	kMCInfoRedstoneRepeaterDelay1			= 0x00,
	kMCInfoRedstoneRepeaterDelay2			= 0x04,
	kMCInfoRedstoneRepeaterDelay3			= 0x08,
	kMCInfoRedstoneRepeaterDelay4			= 0x0C,
	
	/*	Trapdoor orientation. Will probably end up being kMCInfoMisc4OrientationMask
		at some point in the future…
		
		The orientation of a trapdoor is the side away from the hinge (the opposite of
		the usage on the wiki, which is silly).
	*/
	kMCInfoTrapdoorOrientationMask			= 0x03,
	kMCInfoTrapdoorOrientationEast			= 0x00,
	kMCInfoTrapdoorOrientationWest			= 0x01,
	kMCInfoTrapdoorOrientationNorth			= 0x02,
	kMCInfoTrapdoorOrientationSouth			= 0x03,
	
	kMCInfoTrapdoorIsOpen					= 0x04
};


/*
	Block type classifications.
	
	Every known block type is classified in exactly one of four categories:
	fully-solid, quasi-solid, liquid, or item.
	* Quasi-solids look like solid objects, but don’t block redstone: glass,
	  leaves, single steps, stairs, mob spawners.
	* Fully-solid blocks fill their cell and block redstone. This includes
	  all normal building blocks, as well as workbenches, furnaces, chests,
	  jukeboxes, TNT, pumpkins and jack-o-lanterns.
	* Liquids are moving and stationary water and lava.
	* Items are everything else.
	
	The classifications are somewhat arbitrary. For example, cactus could be
	considered a solid or quasi-solid block (I haven’t tested which applies),
	but is classified as an item because of its placing restrictions. On the
	other hand, pumpkins are considered solid blocks despite being a vegetable,
	and sand is considered a solid block despite having placement restrictions.
	
	There are also some non-exclusive metadata flags.
*/


enum
{
	// Primary attributes. Every known block type except air is exactly one of these.
	kMCBlockIsFullySolid			= 0x0001,
	kMCBlockIsQuasiSolid			= 0x0002,
	kMCBlockIsLiquid				= 0x0004,
	kMCBlockIsItem					= 0x0008,
	
	kMCBlockIsSolid					= kMCBlockIsFullySolid | kMCBlockIsQuasiSolid,
	
	/*	Secondary attributes.
		
		NOTE: “off” redstone torches are considered sources for consistency,
		since it’s generally easier to think of redstone torches as one type
		and state as metadata even though they aren’t encoded that way.
	*/
	kMCBlockIsPowerSource			= 0x0010,
	kMCBlockIsPowerSink				= 0x0020,
	kMCBlockIsPowerActive			= kMCBlockIsPowerSource | kMCBlockIsPowerSink,
	
	/*
		Logs (but not planks and other crafted wood), leaves, flowers, cactus,
		reeds, pumpkins (but not jack-o-lanterns), mushrooms (eat it,
		biologists), long grass and shrubs. Not grass blocks.
	*/
	kMCBlockIsVegetable				= 0x0040,
	
	/*
		Coal, iron, redstone, diamond or lapis ore blocks. Eat it, geologists.
	*/
	kMCBlockIsOre					= 0x0080,
	
	/*
		Rail, powered rail or detector rail.
	*/
	kMCBlockIsRail					= 0x0100,
	
	/*
		Piston, sticky piston or piston head.
	*/
	kMCBlockIsPiston				= 0x0200
};


typedef uint16_t JAMCBlockIDMetadata;


JA_EXTERN const JAMCBlockIDMetadata kMCBlockTypeClassifications[256];


JA_INLINE bool MCBlockIDIsFullySolid(uint8_t blockID)
{
	return kMCBlockTypeClassifications[blockID] & kMCBlockIsFullySolid;
}


JA_INLINE bool MCBlockIDIsQuasiSolid(uint8_t blockID)
{
	return kMCBlockTypeClassifications[blockID] & kMCBlockIsQuasiSolid;
}


JA_INLINE bool MCBlockIDIsSolid(uint8_t blockID)
{
	return kMCBlockTypeClassifications[blockID] & kMCBlockIsSolid;
}


JA_INLINE bool MCBlockIDIsLiquid(uint8_t blockID)
{
	return kMCBlockTypeClassifications[blockID] & kMCBlockIsLiquid;
}


JA_INLINE bool MCBlockIDIsItem(uint8_t blockID)
{
	return kMCBlockTypeClassifications[blockID] & kMCBlockIsItem;
}


JA_INLINE bool MCBlockIDIsAir(uint8_t blockID)
{
	return blockID == kMCBlockAir;
}


JA_INLINE bool MCBlockIDIsPowerSource(uint8_t blockID)
{
	return kMCBlockTypeClassifications[blockID] & kMCBlockIsPowerSource;
}


JA_INLINE bool MCBlockIDIsPowerSink(uint8_t blockID)
{
	return kMCBlockTypeClassifications[blockID] & kMCBlockIsPowerSink;
}


JA_INLINE bool MCBlockIDIsPowerActive(uint8_t blockID)
{
	return kMCBlockTypeClassifications[blockID] & kMCBlockIsPowerActive;
}


JA_INLINE bool MCBlockIDIsVegetable(uint8_t blockID)
{
	return kMCBlockTypeClassifications[blockID] & kMCBlockIsVegetable;
}


JA_INLINE bool MCBlockIDIsOre(uint8_t blockID)
{
	return kMCBlockTypeClassifications[blockID] & kMCBlockIsOre;
}


JA_INLINE bool MCBlockIDIsRail(uint8_t blockID)
{
	return kMCBlockTypeClassifications[blockID] & kMCBlockIsRail;
}


JA_INLINE bool MCBlockIDIsPiston(uint8_t blockID)
{
	return kMCBlockTypeClassifications[blockID] & kMCBlockIsPiston;
}


JA_INLINE bool MCBlockIDIsRedstoneTorch(uint8_t blockID)
{
	return blockID == kMCBlockRedstoneTorchOn || blockID == kMCBlockRedstoneTorchOff;
}
