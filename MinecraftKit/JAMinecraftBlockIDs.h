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
	kMCBlockSapling							= 6,
	kMCBlockBedrock							= 7,	// “Adminium”
	kMCBlockWater							= 8,
	kMCBlockStationaryWater					= 9,
	kMCBlockLava							= 10,
	kMCBlockStationaryLava					= 11,
	kMCBlockSand							= 12,
	kMCBlockGravel							= 13,
	kMCBlockGoldOre							= 14,
	kMCBlockIronOre							= 15,
	kMCBlockCoalOre							= 16,	// “Coal ore”? Meh. You get the point.
	kMCBlockLog								= 17,
	kMCBlockLeaves							= 18,
	kMCBlockSponge							= 19,
	kMCBlockGlass							= 20,
	kMCBlockLapisLazuliOre					= 21,
	kMCBlockLapisLazuliBlock				= 22,
	kMCBlockDispenser						= 23,	// Data: FIXME (expect tile entity)
	kMCBlockSandstone						= 24,
	kMCBlockNoteBlock						= 25,	// Data: FIXME
	// 26-34 currently unused in Beta
	kMCBlockWhiteCloth						= 35,
	// 36 currently unused in Beta
	kMCBlockYellowFlower					= 37,
	kMCBlockRedFlower						= 38,
	kMCBlockBrownMushroom					= 39,
	kMCBlockRedMushroom						= 40,
	kMCBlockGoldBlock						= 41,
	kMCBlockIronBlock						= 42,
	kMCBlockDoubleStep						= 43,	// Two half-steps on top of each other.
	kMCBlockSingleStep						= 44,	// A single half-step.
	kMCBlockBrick							= 45,
	kMCBlockTNT								= 46,
	kMCBlockBookshelf						= 47,
	kMCBlockMossyCobblestone				= 48,
	kMCBlockObsidian						= 49,
	kMCBlockTorch							= 50,	// Data: kMCInfoMiscOrientationMask.
	kMCBlockFire							= 51,
	kMCBlockMobSpawner						= 52,	// No blockData; information is stored in a tile entity.
	kMCBlockWoodenStairs					= 53,
	kMCBlockChest							= 54,	// No blockData; information is stored in a tile entity.
	kMCBlockRedstoneWire					= 55,
	kMCBlockDiamondOre						= 56,
	kMCBlockDiamondBlock					= 57,
	kMCBlockWorkbench						= 58,
	kMCBlockCrops							= 59,
	kMCBlockSoil							= 60,
	kMCBlockFurnace							= 61,	// No blockData; information is stored in a tile entity.
	kMCBlockBurningFurnace					= 62,	// Presumably same entity data as above.
	kMCBlockSignPost						= 63,	// Sign on ground. Has blockdata and tile entity.
	kMCBlockWoodenDoor						= 64,
	kMCBlockLadder							= 65,
	kMCBlockMinecartTrack					= 66,
	kMCBlockCobblestoneStairs				= 67,
	kMCBlockWallSign						= 68,	// Sign on wall. Has blockdata and tile entity.
	kMCBlockLever							= 69,
	kMCBlockStonePressurePlate				= 70,
	kMCBlockIronDoor						= 71,
	kMCBlockWoodenPressurePlate				= 72,
	kMCBlockRedstoneOre						= 73,
	kMCBlockGlowingRedstoneOre				= 74,
	kMCBlockRedstoneTorchOff				= 75,	// Data: kMCInfoMiscOrientationMask.
	kMCBlockRedstoneTorchOn					= 76,	// Data: kMCInfoMiscOrientationMask.
	kMCBlockStoneButton						= 77,	// Data: kMCInfoMiscOrientationMask.
	kMCBlockSnow							= 78,
	kMCBlockIce								= 79,
	kMCBlockSnowBlock						= 80,
	kMCBlockCactus							= 81,
	kMCBlockClay							= 82,
	kMCBlockReed							= 83,
	kMCBlockJukebox							= 84,
	kMCBlockFence							= 85,
	kMCBlockPumpkin							= 86,	// Data: kMCInfoPumpkinOrientationMask.
	kMCBlockNetherstone						= 87,	// Hellstone/red nether stuff
	kMCBlockSlowSand						= 88,	// Mud/brown nether stuff
	kMCBlockLightstone						= 89,	// Shiny yellow nether stuff
	kMCBlockPortal							= 90,
	kMCBlockJackOLantern					= 91,	// Data: kMCInfoPumpkinOrientationMask.
	kMCBlockCake							= 92,	// FIXME: data? I’d expect a slice count. -- Ahruman 2011-01-13
	
	kMCBlockLantern					= kMCBlockTorch,	// Expected future renaming.
};


#define kMCLastBlockID kMCBlockCake


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
	
	/*	Sapling: low 4 bits are “age”. This value is incremented randomly
		until the sapling grows “old enough” to be replaced with a tree.
	*/
	kMCInfoSaplingAgeMask					= 0x0F,
	
	/*	Water: emptiness ranges from 0 (full) to 7 (nearly empty).
		Falling is set for vertically flowing water.
	*/
	kMCInfoWaterEmptinessMask				= 0x07,
	kMCInfoWaterFlowing						= 0x80,
	
	/*	Lava: emptiness ranges from 0 (full) to 3 (nearly empty).
		Falling is set for vertically flowing water.
		Increased range in nether – details unknown at time of writing,
		I’m guessing same as water.
	*/
	kMCInfoLavaEmptinessMask				= 0x03,
	kMCInfoLavaFlowing						= kMCInfoWaterFlowing,
	
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
	
	/*	Ladder orientations refer to the facing direction of the ladder.
	*/
	kMCInfoLadderOrientationMask			= 0x07,
	kMCInfoLadderOrientationEast			= 0x02,
	kMCInfoLadderOrientationWest			= 0x03,
	kMCInfoLadderOrientationNorth			= 0x04,
	kMCInfoLadderOrientationSouth			= 0x05,
	
	/*	Minecart track orientations. Note that these don’t map to the same
		set of orientations as most of the other “orientation” value sets.
	*/
	kMCInfoTrackOrientationMask				= 0x0F,
	// Straight sections.
	kMCInfoTrackOrientationNorthSouth		= 0x00,
	kMCInfoTrackOrientationEastWest			= 0x01,
	// Hill sections.
	kMCInfoTrackOrientationRisingSouth		= 0x02,
	kMCInfoTrackOrientationRisingNorth		= 0x03,
	kMCInfoTrackOrientationRisingEast		= 0x04,
	kMCInfoTrackOrientationRisingWest		= 0x05,
	// Curve sections, with endpoint (outward) directions in clockwise order.
	kMCInfoTrackOrientationWestSouth		= 0x06,	// ◝
	kMCInfoTrackOrientationNorthWest		= 0x07,	// ◞
	kMCInfoTrackOrientationEastNorth		= 0x08,	// ◟
	kMCInfoTrackOrientationSouthEast		= 0x09,	// ◜
	
	/*	Wall signs use the same scheme as ladders.
	 */
	kMCInfoWallSignOrientationMask			= kMCInfoLadderOrientationMask,
	kMCInfoWallSignOrientationEast			= kMCInfoLadderOrientationEast,
	kMCInfoWallSignOrientationWest			= kMCInfoLadderOrientationWest,
	kMCInfoWallSignOrientationNorth			= kMCInfoLadderOrientationNorth,
	kMCInfoWallSignOrientationSouth			= kMCInfoLadderOrientationSouth,
	
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
	
	/*	Pumpkin/Jack-o-lantern orientation.
	*/
	kMCInfoPumpkinOrientationMask			= 0x03,
	kMCInfoPumpkinOrientationEast			= 0x00,
	kMCInfoPumpkinOrientationSouth			= 0x01,
	kMCInfoPumpkinOrientationWest			= 0x02,
	kMCInfoPumpkinOrientationNorth			= 0x03
};


/*
	Block type classifications.
	
	Every known block type is classified in exactly one of four categories:
	fully-solid, quasi-solid, liquid, or item.
	* Quasi-solids look like solid objects, but don’t block redstone: glass,
	  leaves, single steps, stairs, mob spawners. Glass also interacts with
	  water differently than full solids; I haven’t tested the others.
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
		reeds, pumpkins (but not jack-o-lanterns), mushrooms
		(eat it, biologists). Not grass.
	*/
	kMCBlockIsVegetable				= 0x0040,
	
	/*
		Coal, iron, redstone or diamond ore blocks. Eat it, geologists.
	*/
	kMCBlockIsOre					= 0x0080
};


typedef uint8_t JAMCBlockIDMetadata;


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


JA_INLINE bool MCBlockIDIsRedstoneTorch(uint8_t blockID)
{
	return blockID == kMCBlockRedstoneTorchOn || blockID == kMCBlockRedstoneTorchOff;
}
