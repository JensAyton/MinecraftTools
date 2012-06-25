/*
	BlockID values.
	
	Source: http://www.minecraftwiki.net/wiki/Data_values
*/


#if __cplusplus
#ifndef JA_INLINE
#define JA_INLINE inline
#endif
#if __cplusplus
#ifndef JA_EXTERN
#define JA_EXTERN extern "C"
#endif
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
	kMCBlockLeaves							= 18,	// Data: kMCInfoLeafUpdatePending, kMCInfoLeafPermanent and kMCInfoWoodTypeMask
	kMCBlockSponge							= 19,
	kMCBlockGlass							= 20,
	kMCBlockLapisLazuliOre					= 21,
	kMCBlockLapisLazuliBlock				= 22,
	kMCBlockDispenser						= 23,	// Data: kMCInfoMisc2Orientation; tile entity: Trap.
	kMCBlockSandstone						= 24,	// Data: kMCInfoSandstoneAppearance
	kMCBlockNoteBlock						= 25,	// Tile entity: Music
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
	kMCBlockMovingPiston					= 36,	// Used for piston animations. Tile entity: Piston.
	kMCBlockYellowFlower					= 37,
	kMCBlockRedFlower						= 38,
	kMCBlockBrownMushroom					= 39,
	kMCBlockRedMushroom						= 40,
	kMCBlockGoldBlock						= 41,
	kMCBlockIronBlock						= 42,
	kMCBlockDoubleSlab						= 43,	// Two half-steps on top of each other. Data: kMCInfoSlabTypeMask, kMCInfoSlabUpsideDown
	kMCBlockSingleSlab						= 44,	// A single half-step. Data: kMCInfoSlabTypeMask, kMCInfoSlabUpsideDown
	kMCBlockBrick							= 45,
	kMCBlockTNT								= 46,
	kMCBlockBookshelf						= 47,
	kMCBlockMossyCobblestone				= 48,
	kMCBlockObsidian						= 49,
	kMCBlockTorch							= 50,	// Data: kMCInfoMiscOrientation
	kMCBlockFire							= 51,	// Data: kMCBlockFireGenerationMask
	kMCBlockMobSpawner						= 52,	// Tile entity: MobSpawner
	kMCBlockWoodenStairs					= 53,	// Data: kMCInfoStairOrientationMask
	kMCBlockChest							= 54,	// Data: kInfoMisc2Orientation. tile entity: Chest
	kMCBlockRedstoneWire					= 55,
	kMCBlockDiamondOre						= 56,
	kMCBlockDiamondBlock					= 57,
	kMCBlockWorkbench						= 58,
	kMCBlockCrops							= 59,	// Data: kMCInfoCropsAge
	kMCBlockSoil							= 60,	// Data: kMCInfoSoilWetness
	kMCBlockFurnace							= 61,	// Data: kMCInfoMisc2Orientation; tile entity: Furnace.
	kMCBlockBurningFurnace					= 62,	// As normal furnace.
	kMCBlockSignPost						= 63,	// Sign on ground. Data: kMCInfoSignPostOrientation; tile entity: Sign.
	kMCBlockWoodenDoor						= 64,	// Data: kMCInfoDoorOrientationMask, kMCInfoDoorOpen and kMCInfoDoorTopHalf.
	kMCBlockLadder							= 65,
	kMCBlockRail							= 66,
	kMCBlockCobblestoneStairs				= 67,	// Data: kMCInfoStairOrientation
	kMCBlockWallSign						= 68,	// Sign on wall. Data: kMCInfoMisc2Orientation; tile entity: Sign.
	kMCBlockLever							= 69,
	kMCBlockStonePressurePlate				= 70,	// Data: kMCInfoPressurePlateOn, kMCInfoLeverOn.
	kMCBlockIronDoor						= 71,	// Data: kMCInfoDoorOrientationMask, kMCInfoDoorOpen and kMCInfoDoorTopHalf.
	kMCBlockWoodenPressurePlate				= 72,	// Data: kMCInfoPressurePlateOn
	kMCBlockRedstoneOre						= 73,
	kMCBlockGlowingRedstoneOre				= 74,
	kMCBlockRedstoneTorchOff				= 75,	// Data: kMCInfoMiscOrientation.
	kMCBlockRedstoneTorchOn					= 76,	// Data: kMCInfoMiscOrientation.
	kMCBlockStoneButton						= 77,	// Data: kMCInfoMiscOrientation, kMCInfoButtonOn.
	kMCBlockSnow							= 78,
	kMCBlockIce								= 79,
	kMCBlockSnowBlock						= 80,
	kMCBlockCactus							= 81,	// Data: kMCInfoCactusAge
	kMCBlockClay							= 82,
	kMCBlockReed							= 83,
	kMCBlockJukebox							= 84,	// Tile entity: RecordPlayer
	kMCBlockFence							= 85,
	kMCBlockPumpkin							= 86,	// Data: kMCInfoPumpkinOrientation.
	kMCBlockNetherrack						= 87,
	kMCBlockSoulSand						= 88,
	kMCBlockGlowstone						= 89,
	kMCBlockPortal							= 90,
	kMCBlockJackOLantern					= 91,	// Data: kMCInfoPumpkinOrientation
	kMCBlockCake							= 92,	// Data: kMCInfoCakeSliceCountMask
	kMCBlockRedstoneRepeaterOff				= 93,	// Data: kMCInfoMisc3OrientationMask and kMCInfoRedstoneRepeaterDelayMask
	kMCBlockRedstoneRepeaterOn				= 94,	// Data: kMCInfoMisc3OrientationMask and kMCInfoRedstoneRepeaterDelayMask	
	kMCBlockLockedChest						= 95,	// April 1 2011 easter egg item, currently deteriorates like leaves.
	kMCBlockTrapdoor						= 96,	// Data: kMCInfoTrapdoorOrientationMask and kMCInfoDoorOpen
	kMCBlockStoneWithSilverfish				= 97,	// Data: kMCInfoSilverfishAppearanceMask
	kMCBlockStoneBrick						= 98,	// Data: kMCInfoStoneBrickAppearanceMask
	kMCBlockHugeBrownMushroom				= 99,	// Data: kMCInfoMushroomAppearanceMask
	kMCBlockHugeRedMushroom					= 100,	// Data: kMCInfoMushroomAppearanceMask
	kMCBlockIronBars						= 101,
	kMCBlockGlassPane						= 102,
	kMCBlockWatermelon						= 103,
	kMCBlockPumpkinStem						= 104,	// Data: kMCInfoGourdStemAge
	kMCBlockMelonStem						= 105,	// Data: kMCInfoGourdStemAge
	kMCBlockVines							= 106,	// Data: kMCInfoVineAttachmentMask
	kMCBlockGate							= 107,	// Data: kMCInfoDoorOrientationMask and kMCInfoDoorOpen.
	kMCBlockBrickStairs						= 108,	// Data: kMCInfoStairOrientationMask
	kMCBlockStoneBrickStairs				= 109,	// Data: kMCInfoStairOrientationMask
	kMCBlockMycelium						= 110,
	kMCBlockLilyPad							= 111,
	kMCBlockNetherBrick						= 112,
	kMCBlockNetherBrickFence				= 113,
	kMCBlockNetherBrickStairs				= 114,	// Data: kMCInfoStairOrientation
	kMCBlockNetherWart						= 115,	// Data: kMCInfoNetherWartAge
	kMCBlockEnchantmentTable				= 116,	// Tile entity: EnchantTable
	kMCBlockBrewingStand					= 117,	// Data: kMCInfoBrewingStandBottleSlotX; tile entity: Cauldron
	kMCBlockCauldron						= 118,	// Data: kMCInfoCauldronFillLevel
	kMCBlockEndPortal						= 119,	// Tile entity: Airportal
	kMCBlockEndPortalFrame					= 120,	// Data: FIXME: orientation convention?, kMCInfoAirPortalFrameHasEye
	kMCBlockEndStone						= 121,
	kMCBlockDragonEgg						= 122,
	kMCBlockRedstoneLampOff					= 123,
	kMCBlockRedstoneLampOn					= 124,
	kMCBlockWoodenDoubleSlab				= 125,	// Data: kMCInfoWoodTypeMask, kMCInfoSlabUpsideDown
	kMCBlockWoodenSingleSlab				= 126,	// Data: kMCInfoWoodTypeMask, kMCInfoSlabUpsideDown
	kMCBlockCocoaPod						= 127,	// Data: FIXME: orientation, three growth stages?
	kMCBlockSandstoneStairs					= 128,	// Data: kMCInfoStairOrientation
	kMCBlockEmeraldOre						= 129,
	KMCBlockEnderChest						= 130,	// Data: kInfoMisc2Orientation, Tile entity: FIXME
	kMCBlockTripwireHook					= 131,	// Data: FIXME
	kMCBlockTripwire						= 132,	// Data: FIXME
	kMCBlockEmeraldBlock					= 133,
	kMCBlockSpruceWoodStairs				= 134,	// Data: kMCInfoStairOrientation
	kMCBlockBirchWoodStairs					= 135,	// Data: kMCInfoStairOrientation
	kMCBlockJungleWoodStairs				= 136,	// Data: kMCInfoStairOrientation
};


#define kMCLastBlockID kMCBlockJungleWoodStairs


enum
{
	/*
		Info - block data in Minecraft terminology, called info here to avoid
		confusion.
		Minecraft stores four bits of data for each block. In schematic files,
		eight bits per block are stored, but the top four bits are always
		clear. The meaning of bits depends on the block ID. Names ending with
		“Mask” are multi-bit values.
		MinecraftKit stores eight info bits per block in memory. The bottom
		four bits are Minecraft flags, and the top four are MinecraftKit-
		internal.
		
		Directions use the astronomical convention, a.k.a. “normal English”:
		east means the direction of sunrise.
	*/
	
	kMCInfoStandardBitsMask					= 0x0F,
	
	/*
		Any block type: a flag indicating that a block is powered. This is
		used for non-special blocks that transmit power. For instance, if a
		redstone wire leads into any opaque block, the block is powered, and
		can turn off torches attached to it (among other things).
	*/
	kMCInfoBlockIsPowered					= 0x80,
	
	/*	Air: MCKit-internal “hole” flag indicates a block that shouldn’t
		overwrite other blocks and should be transparent in renderings
		(corresponding to “shadow” blocks in Redstone Simulator).
	*/
	kMCInfoAirIsHole						= 0x10,
	
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
	kMCInfoWoodTypeOak						= 0x00,
	kMCInfoWoodTypeDefault					= kMCInfoWoodTypeOak,	// Old name
	kMCInfoWoodTypeSpruce					= 0x01,
	kMCInfoWoodTypeBirch					= 0x02,
	kMCInfoWoodTypeJungle					= 0x03,
	
	/*
		Leaves: if the pending flag is set, the leaf block will be checked for
		random decay. If it’s clear, the block won’t decay (but the flag is
		set again if any adjacent block changes).
		
		Advice: if adding leaf blocks, set the pending flag and let Minecraft
		clear it when valid.
	 */
	kMCInfoLeafUpdatePending				= 0x04,
	kMCInfoLeafPermanent					= 0x08,
	
	/*	Sandstone block: appearance of sides.
	*/
	kMCInfoSandstoneAppearanceMask			= 0x02,
	kMCInfoSandstoneAppearanceDefault		= 0x00,
	kMCInfoSandstoneAppearanceChiseled		= 0x01,
	kMCInfoSandstoneAppearanceSmooth		= 0x02,
	
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
	kMCInfoMiscOrientationEast				= 0x01,
	kMCInfoMiscOrientationWest				= 0x02,
	kMCInfoMiscOrientationSouth				= 0x03,
	kMCInfoMiscOrientationNorth				= 0x04,
	kMCInfoMiscOrientationFloor				= 0x05,	// See also: kMCInfoLeverOrientationFloorEW and kMCInfoLeverOrientationFloorNS
	
	/*	Bed flag: set for head block, clear for foot block.
	*/
	kInfoBedIsHead							= 0x08,
	
	/*	Stair orientations.
		The labels are intended to refer to the _ascending_ direction.
	*/
	kMCInfoStairOrientationMask				= 0x07,
	kMCInfoStairOrientationEast				= 0x00,
	kMCInfoStairOrientationWest				= 0x01,
	kMCInfoStairOrientationSouth			= 0x02,
	kMCInfoStairOrientationNorth			= 0x03,
	kMCInfoStairUpsideDown					= 0x04,
	
	/*	Redstone signal strength varies from 0 to 15.
	*/
	kMCInfoRedstoneWireSignalStrengthMask	= 0x0F,
	
	/*	Age of crops varies from 0 to 7. 0 is newly planted, 7 is ready wheat.
	*/
	kMCInfoCropsAge							= 0x07,
	
	/*	According to the wiki, soil wetness varies from 0 (dry) to 8, which is a bit odd.
	*/
	kMCInfoSoilWetness						= 0x0F,
	
	/*	Signpost orientation ranges from 0 (west) to 15, clockwise.
	*/
	kMCInfoSignPostOrientationMask			= 0x0F,
	
	/*	Door orientations are facing directions of closed doors. Open doors
		swing anti-clockwise.
	 */
	kMCInfoDoorOrientationMask				= 0x03,
	kMCInfoDoorOrientationWest				= 0x00,
	kMCInfoDoorOrientationSouth				= 0x01,
	kMCInfoDoorOrientationEast				= 0x02,
	kMCInfoDoorOrientationNorth				= 0x03,
	kMCInfoDoorOpen							= 0x04,
	kMCInfoDoorTopHalf						= 0x08,
	
	/*	kInfoMisc2Orientation
		Another common set of orientation flags, used for:
		* Ladders
		* Chests
		* Wall signs
		* Furnaces
		* Dispensers
	*/
	kMCInfoMisc2OrientationMask				= 0x07,
	kMCInfoMisc2OrientationNorth			= 0x02,
	kMCInfoMisc2OrientationSouth			= 0x03,
	kMCInfoMisc2OrientationWest				= 0x04,
	kMCInfoMisc2OrientationEast				= 0x05,
	
	/*	Minecart track orientations. Note that these don’t map to the same
		set of orientations as most of the other “orientation” value sets.
		
		kMCInfoRailOrientationMask represents the orientations available to
		regular tracks. kMCInfoPoweredRailOrientationMask represents the
		orientations available to powered rails and detector rails.
	 */
	kMCInfoRailOrientationMask				= 0x0F,
	kMCInfoPoweredRailOrientationMask		= 0x07,
	// Straight sections.
	kMCInfoRailOrientationWestEast			= 0x00,
	kMCInfoRailOrientationNorthSouth		= 0x01,
	// Hill sections.
	kMCInfoRailOrientationRisingEast		= 0x02,
	kMCInfoRailOrientationRisingWest		= 0x03,
	kMCInfoRailOrientationRisingNorth		= 0x04,
	kMCInfoRailOrientationRisingSouth		= 0x05,
	// Curve sections, with endpoint (outward) directions in clockwise order.
	kMCInfoRailOrientationSouthEast			= 0x06,	// ◜
	kMCInfoRailOrientationWestSouth			= 0x07,	// ◝
	kMCInfoRailOrientationNorthWest			= 0x08,	// ◞
	kMCInfoRailOrientationEastNorth			= 0x09,	// ◟
	
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
	
	/*	Pumpkin/Jack-o-lanternU orientation.
	*/
	kMCInfoPumpkinOrientationMask			= 0x03,
	kMCInfoPumpkinOrientationSouth			= 0x00,
	kMCInfoPumpkinOrientationEast			= 0x01,
	kMCInfoPumpkinOrientationNorth			= 0x02,
	kMCInfoPumpkinOrientationWest			= 0x03,
	
	/*	Bed/redstone repeater orientation.
	*/
	kMCInfoMisc3OrientationMask				= 0x03,
	kMCInfoMisc3OrientationNorth			= 0x00,
	kMCInfoMisc3OrientationEast				= 0x01,
	kMCInfoMisc3OrientationSouth			= 0x02,
	kMCInfoMisc3OrientationWest				= 0x03,
	
	/*	Orientation values for pistons and piston heads. These represent the
		facing of the piston head surface.
	*/
	kMCInfoPistonOrientationMask			= 0x07,
	kMCInfoPistonOrientationDown			= 0x00,
	kMCInfoPistonOrientationUp				= 0x01,
	kMCInfoPistonOrientationNorth			= 0x02,
	kMCInfoPistonOrientationSouth			= 0x03,
	kMCInfoPistonOrientationWest			= 0x04,
	kMCInfoPistonOrientationEast			= 0x05,
	
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
	
	/*	Types of slab.
	*/
	kMCInfoSlabTypeMask						= 0x07,
	kMCInfoSlabTypeStone					= 0x00,
	kMCInfoSlabTypeSandstone				= 0x01,
	kMCInfoSlabTypeWood						= 0x02,	// Pre-1.3 oak-looking wooden slab
	kMCInfoSlabTypeCobblestone				= 0x03,
	kMCInfoSlabTypeBrick					= 0x04,
	kMCInfoSlabTypeStoneBrick				= 0x05,
	
	kMCInfoSlabUpsideDown					= 0x08,
	
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
	kMCInfoTrapdoorOrientationNorth			= 0x00,
	kMCInfoTrapdoorOrientationSouth			= 0x01,
	kMCInfoTrapdoorOrientationWest			= 0x02,
	kMCInfoTrapdoorOrientationEast			= 0x03,
	
	kMCInfoSilverfishAppearanceMask			= 0x03,
	kMCInfoSilverfishAppearanceSmoothStone	= 0x00,
	kMCInfoSilverfishAppearanceCobblestone	= 0x01,
	kMCInfoSilverfishAppearanceStoneBrick	= 0x02,
	
	kMCInfoStoneBrickAppearanceMask			= 0x03,
	kMCInfoStoneBrickAppearanceNormal		= 0x00,
	kMCInfoStoneBrickAppearanceMossy		= 0x01,
	kMCInfoStoneBrickAppearanceCracked		= 0x02,
	kMCInfoStoneBrickAppearanceChiseled		= 0x03,
	
	kMCInfoMushroomAppearanceMask			= 0x0F,
	kMCInfoMushroomAppearanceFlesh			= 0x00,	// Pores on all sides.
	kMCInfoMushroomAppearanceCapSE			= 0x01,	// Cap texture on top, south and east sides.
	kMCInfoMushroomAppearanceCapE			= 0x02,	// Cap texture on top and east sides.
	kMCInfoMushroomAppearanceCapNE			= 0x03,	// Cap texture on top, north and east sides.
	kMCInfoMushroomAppearanceCapS			= 0x04,	// Cap texture on top, north and east sides.
	kMCInfoMushroomAppearanceCapMid			= 0x05,	// Cap texture on top side.
	kMCInfoMushroomAppearanceCapN			= 0x06,	// Cap texture on top and north sides.
	kMCInfoMushroomAppearanceCapSW			= 0x07,	// Cap texture on top, south and west sides.
	kMCInfoMushroomAppearanceCapW			= 0x09,	// Cap texture on top and west sides.
	kMCInfoMushroomAppearanceCapNW			= 0x0A,	// Cap texture on top, north and west sides.
	kMCInfoMushroomAppearanceCapStem		= 0x0B,	// Stem texture on north, south, east and west sides; pores on top and bottom.
	
	/*
		Gourd stem age: age of pumpkin and melon stems, ranging from 0 to 7.
	*/
	kMCInfoGourdStemAge						= 0x07,
	
	/*
		Vine attachment is a bit mask rather than an enumeration – vines may
		be attached to multiple sides at once.
	*/
	kMCInfoVineAttachmentMask				= 0x0F,
	kMCInfoVineAttachmentSouth				= 0x01,
	kMCInfoVineAttachmentWest				= 0x02,
	kMCInfoVineAttachmentNorth				= 0x04,
	kMCInfoVineAttachmentEast				= 0x08,
	
	/*
		Nether Wart age ranges from 0 to 3, with 1 and 2 looking the same.
	*/
	kMCInfoNetherWartAge					= 0x03,
	
	/*
		Flags indicating which of a brewing stand’s three slots are occupied
		by bottles. Note that actual information about bottles is in tile
		entity.
	*/
	kMCInfoBrewingStandBottleSlotEast		= 0x01,
	kMCInfoBrewingStandBottleSlotSouthWest	= 0x02,
	kMCInfoBrewingStandBottleSlotNorthWest	= 0x04,
	
	/*
		Cauldron fill level ranges from 0 to 3.
	*/
	kMCInfoCauldronFillLevel				= 0x03,
	
	kMCInfoAirPortalFrameHasEye				= 0x04
};


/*
	Block type classifications.
	
	Every known block type is classified in exactly one of four
	categories: opaque, transparent, liquid, or item.
	* Transparent blocks can’t have most items attached to them and don’t block
	  redstone diagonally. This includes air, glass, leaves, stairs, and slabs.
	  Glowstone is also “transparent” (since 1.9pre6, for technical reasons
	  involving lighting).
	* Opaque blocks completely fill their cell and block redstone. This includes
	  all normal building blocks, as well as workbenches, furnaces, jukeboxes,
 	  TNT, pumpkins, jack-o-lanterns and melons.
	* Liquids are moving and stationary water and lava.
	* Items are similar to transparent blocks, but don’t look like blocks –
	  flowers, torches, doors, rails etc.
	
	The distinction between transparent blocks and items is somewhat arbitrary.
	As far as I’m aware, there is no corresponding distinction within Minecraft.
	
	There are also some non-exclusive metadata flags, desribed below.
*/


enum
{
	// Primary attributes. Every known block type is exactly one of these.
	kMCBlockIsOpaque						= 0x0001,
	kMCBlockIsTransparent					= 0x0002,
	kMCBlockIsLiquid						= 0x0004,
	kMCBlockIsItem							= 0x0008,
	
	/*
		Storage type attribute: identifies blocks with special storage requirements.
	*/
	kMCBlockHasTileEntity					= 0x8000,
	
	/*	Secondary attributes.
		
		NOTE: “off” redstone torches are considered sources for consistency,
		since it’s generally easier to think of redstone torches as one type
		and state as metadata even though they aren’t encoded that way.
	*/
	kMCBlockIsPowerSource					= 0x0010,
	kMCBlockIsPowerSink						= 0x0020,
	kMCBlockIsPowerActive					= kMCBlockIsPowerSource | kMCBlockIsPowerSink,
	
	/*
		Logs (but not planks and other crafted wood), leaves, flowers, cactus,
		reeds, pumpkins (but not jack-o-lanterns), mushrooms (eat it,
		biologists), long grass and shrubs. Not grass blocks.
	*/
	kMCBlockIsVegetable						= 0x0040,
	
	/*
		Coal, iron, redstone, diamond or lapis ore blocks. Eat it, geologists.
	*/
	kMCBlockIsOre							= 0x0080,
	
	/*
		Rail, powered rail or detector rail.
	*/
	kMCBlockIsRail							= 0x0100,
	
	/*
		Piston, sticky piston or piston head.
	*/
	kMCBlockIsPiston						= 0x0200,
	
	/*
		Any type of staircase.
	*/
	kMCBlockIsStairs						= 0x0400
};


typedef uint16_t JAMCBlockIDMetadata;


JA_EXTERN const JAMCBlockIDMetadata kMCBlockTypeClassifications[256];


JA_INLINE bool MCBlockIDIsFullySolid(uint8_t blockID)
{
	return kMCBlockTypeClassifications[blockID] & kMCBlockIsOpaque;
}


JA_INLINE bool MCBlockIDIsQuasiSolid(uint8_t blockID)
{
	return kMCBlockTypeClassifications[blockID] & kMCBlockIsTransparent;
}


JA_INLINE bool MCBlockIDIsSolid(uint8_t blockID)
{
	return (kMCBlockTypeClassifications[blockID] & (kMCBlockIsOpaque | kMCBlockIsTransparent)) && (blockID != kMCBlockAir);
}


JA_INLINE bool MCBlockIDIsLiquid(uint8_t blockID)
{
	return kMCBlockTypeClassifications[blockID] & kMCBlockIsLiquid;
}


JA_INLINE bool MCBlockIDIsItem(uint8_t blockID)
{
	return kMCBlockTypeClassifications[blockID] & kMCBlockIsItem;
}


JA_INLINE bool MCBlockIDHasTileEntity(uint8_t blockID)
{
	return kMCBlockTypeClassifications[blockID] & kMCBlockHasTileEntity;
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
