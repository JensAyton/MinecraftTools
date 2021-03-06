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
#ifndef JA_INLINE
#define JA_INLINE static inline
#endif
#ifndef JA_EXTERN
#define JA_EXTERN extern
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
	kMCBlockWoodPlanks						= 5,	// Data: kMCInfoWoodType
	kMCBlockSapling							= 6,	// Data: kMCInfoWoodType and kMCInfoSaplingAge
	kMCBlockBedrock							= 7,
	kMCBlockWater							= 8,	// Data: kMCInfoLiquidEmptiness and kMCInfoLiquidFlowing
	kMCBlockStationaryWater					= 9,	// Data: wiki links to same data as for flowing water. Only kMCInfoLiquidFlowing relevant? Unconfirmed.
	kMCBlockLava							= 10,	// Like kMCBlockWater
	kMCBlockStationaryLava					= 11,	// Like kMCBlockStationaryWater
	kMCBlockSand							= 12,
	kMCBlockGravel							= 13,
	kMCBlockGoldOre							= 14,
	kMCBlockIronOre							= 15,
	kMCBlockCoalOre							= 16,
	kMCBlockLog								= 17,	// Data: kMCInfoWoodType, kMCInfoLogOrientation
	kMCBlockLeaves							= 18,	// Data: kMCInfoLeafUpdatePending, kMCInfoLeafPermanent and kMCInfoWoodType
	kMCBlockSponge							= 19,
	kMCBlockGlass							= 20,
	kMCBlockLapisLazuliOre					= 21,
	kMCBlockLapisLazuliBlock				= 22,
	kMCBlockDispenser						= 23,	// Data: kMCInfoMisc2Orientation; tile entity: Trap.
	kMCBlockSandstone						= 24,	// Data: kMCInfoSandstoneAppearance
	kMCBlockNoteBlock						= 25,	// Tile entity: Music
	kMCBlockBed								= 26,	// Data: kMCInfoMisc3Orientation (direction of foot of bed) and kMCInfoBedIsHead.
	kMCBlockPoweredRail						= 27,	// Data: kMCInfoPoweredRailOrientation and kMCInfoPoweredRailIsPowered.
	kMCBlockDetectorRail					= 28,	// Data: kMCInfoPoweredRailOrientation
	kMCBlockStickyPiston					= 29,	// Data: kMCInfoPistonOrientation
	kMCBlockCobweb							= 30,
	kMCBlockTallGrass						= 31,	// Data: kMCInfoTallGrassType
	kMCBlockDeadShrubs						= 32,
	kMCBlockPiston							= 33,	// Data: kMCInfoPistonOrientation
	kMCBlockPistonHead						= 34,	// Data: kMCInfoPistonOrientation and kMCInfoPistonHeadIsSticky
	kMCBlockCloth							= 35,	// Data: kMCInfoWoolColor
	kMCBlockMovingPiston					= 36,	// Used for piston animations. Tile entity: Piston.
	kMCBlockYellowFlower					= 37,
	kMCBlockFlower							= 38,	// Data: kMCInfoFlowerType (always 0 in MC 1.6.x and earlier)
	kMCBlockBrownMushroom					= 39,
	kMCBlockRedMushroom						= 40,
	kMCBlockGoldBlock						= 41,
	kMCBlockIronBlock						= 42,
	kMCBlockDoubleSlab						= 43,	// Two slabs on top of each other. Data: kMCInfoSlabType, kMCInfoSlabUpsideDown
	kMCBlockSingleSlab						= 44,	// A single slab. Data: kMCInfoSlabType, kMCInfoSlabUpsideDown
	kMCBlockBrick							= 45,
	kMCBlockTNT								= 46,
	kMCBlockBookshelf						= 47,
	kMCBlockMossyCobblestone				= 48,
	kMCBlockObsidian						= 49,
	kMCBlockTorch							= 50,	// Data: kMCInfoMiscOrientation
	kMCBlockFire							= 51,	// Data: kMCBlockFireGeneration
	kMCBlockMobSpawner						= 52,	// Tile entity: MobSpawner
	kMCBlockWoodenStairs					= 53,	// Data: kMCInfoStairOrientation, kMCInfoStairUpsideDown
	kMCBlockChest							= 54,	// Data: kMCInfoMisc2Orientation. tile entity: Chest
	kMCBlockRedstoneWire					= 55,
	kMCBlockDiamondOre						= 56,
	kMCBlockDiamondBlock					= 57,
	kMCBlockWorkbench						= 58,
	kMCBlockCrops							= 59,	// Data: kMCInfoCropsAge
	kMCBlockSoil							= 60,	// Data: kMCInfoSoilWetness
	kMCBlockFurnace							= 61,	// Data: kMCInfoMisc2Orientation; tile entity: Furnace.
	kMCBlockBurningFurnace					= 62,	// As normal furnace.
	kMCBlockSignPost						= 63,	// Sign on ground. Data: kMCInfoSignPostOrientation; tile entity: Sign.
	kMCBlockWoodenDoor						= 64,	// Data: kMCInfoDoorOrientation, kMCInfoDoorOpen and kMCInfoDoorTopHalf.
	kMCBlockLadder							= 65,
	kMCBlockRail							= 66,
	kMCBlockCobblestoneStairs				= 67,	// Data: kMCInfoStairOrientation, kMCInfoStairUpsideDown
	kMCBlockWallSign						= 68,	// Sign on wall. Data: kMCInfoMisc2Orientation; tile entity: Sign.
	kMCBlockLever							= 69,
	kMCBlockStonePressurePlate				= 70,	// Data: kMCInfoPressurePlateOn, kMCInfoLeverOn.
	kMCBlockIronDoor						= 71,	// Data: kMCInfoDoorOrientation, kMCInfoDoorOpen and kMCInfoDoorTopHalf.
	kMCBlockWoodenPressurePlate				= 72,	// Data: kMCInfoPressurePlateOn
	kMCBlockRedstoneOre						= 73,
	kMCBlockGlowingRedstoneOre				= 74,
	kMCBlockRedstoneTorchOff				= 75,	// Data: kMCInfoMiscOrientation
	kMCBlockRedstoneTorchOn					= 76,	// Data: kMCInfoMiscOrientation
	kMCBlockStoneButton						= 77,	// Data: kMCInfoMiscOrientation, kMCInfoButtonOn
	kMCBlockSnow							= 78,
	kMCBlockIce								= 79,
	kMCBlockSnowBlock						= 80,
	kMCBlockCactus							= 81,	// Data: kMCInfoCactusAge
	kMCBlockClay							= 82,
	kMCBlockReed							= 83,
	kMCBlockJukebox							= 84,	// Tile entity: RecordPlayer
	kMCBlockFence							= 85,
	kMCBlockPumpkin							= 86,	// Data: kMCInfoPumpkinOrientation
	kMCBlockNetherrack						= 87,
	kMCBlockSoulSand						= 88,
	kMCBlockGlowstone						= 89,
	kMCBlockPortal							= 90,
	kMCBlockJackOLantern					= 91,	// Data: kMCInfoPumpkinOrientation
	kMCBlockCake							= 92,	// Data: kMCInfoCakeSliceCount
	kMCBlockRedstoneRepeaterOff				= 93,	// Data: kMCInfoMisc3Orientation and kMCInfoRedstoneRepeaterDelay
	kMCBlockRedstoneRepeaterOn				= 94,	// Data: kMCInfoMisc3Orientation and kMCInfoRedstoneRepeaterDelay
	kMCBlockStainedGlass					= 95,	// Data: FIXME (kMCInfoWoolColor?)
//	kMCBlockLockedChest						= 95,	// April 1 2011 easter egg item; note: replaced by stained glass.
	kMCBlockTrapdoor						= 96,	// Data: kMCInfoTrapdoorOrientation and kMCInfoDoorOpen
	kMCBlockStoneWithSilverfish				= 97,	// Data: kMCInfoSilverfishAppearance
	kMCBlockStoneBrick						= 98,	// Data: kMCInfoStoneBrickAppearance
	kMCBlockHugeBrownMushroom				= 99,	// Data: kMCInfoMushroomAppearance
	kMCBlockHugeRedMushroom					= 100,	// Data: kMCInfoMushroomAppearance
	kMCBlockIronBars						= 101,
	kMCBlockGlassPane						= 102,
	kMCBlockWatermelon						= 103,
	kMCBlockPumpkinStem						= 104,	// Data: kMCInfoGourdStemAge
	kMCBlockMelonStem						= 105,	// Data: kMCInfoGourdStemAge
	kMCBlockVines							= 106,	// Data: kMCInfoVineAttachment
	kMCBlockGate							= 107,	// Data: kMCInfoDoorOrientation and kMCInfoDoorOpen.
	kMCBlockBrickStairs						= 108,	// Data: kMCInfoStairOrientation, kMCInfoStairUpsideDown
	kMCBlockStoneBrickStairs				= 109,	// Data: kMCInfoStairOrientation, kMCInfoStairUpsideDown
	kMCBlockMycelium						= 110,
	kMCBlockLilyPad							= 111,
	kMCBlockNetherBrick						= 112,
	kMCBlockNetherBrickFence				= 113,
	kMCBlockNetherBrickStairs				= 114,	// Data: kMCInfoStairOrientation, kMCInfoStairUpsideDown
	kMCBlockNetherWart						= 115,	// Data: kMCInfoNetherWartAge
	kMCBlockEnchantmentTable				= 116,	// Tile entity: EnchantTable
	kMCBlockBrewingStand					= 117,	// Data: kMCInfoBrewingStandBottleSlotX; tile entity: Cauldron
	kMCBlockCauldron						= 118,	// Data: kMCInfoCauldronFillLevel
	kMCBlockEndPortal						= 119,	// Tile entity: Airportal
	kMCBlockEndPortalFrame					= 120,	// Data: kMCInfoMisc3Orientation (representing outside edge), kMCInfoEndPortalFrameHasEye
	kMCBlockEndStone						= 121,
	kMCBlockDragonEgg						= 122,
	kMCBlockRedstoneLampOff					= 123,
	kMCBlockRedstoneLampOn					= 124,
	kMCBlockWoodenDoubleSlab				= 125,	// Data: kMCInfoWoodType, kMCInfoSlabUpsideDown
	kMCBlockWoodenSingleSlab				= 126,	// Data: kMCInfoWoodType, kMCInfoSlabUpsideDown
	kMCBlockCocoaPod						= 127,	// Data: kMCInfoMisc3Orientation, kMCInfoCocoaPodAge
	kMCBlockSandstoneStairs					= 128,	// Data: kMCInfoStairOrientation, kMCInfoStairUpsideDown
	kMCBlockEmeraldOre						= 129,
	KMCBlockEnderChest						= 130,	// Data: kMCInfoMisc2Orientation; tile entity: EnderChest
	kMCBlockTripwireHook					= 131,	// Data: kMCInfoTripwireHookOrientation, kMCInfoTripwireHookConnected, kMCInfoTripWireHookActive
	kMCBlockTripwire						= 132,	// Data: kMCInfoTripwirePieceActive, kMCInfoTripwireWireActive
	kMCBlockEmeraldBlock					= 133,
	kMCBlockSpruceWoodStairs				= 134,	// Data: kMCInfoStairOrientation, kMCInfoStairUpsideDown
	kMCBlockBirchWoodStairs					= 135,	// Data: kMCInfoStairOrientation, kMCInfoStairUpsideDown
	kMCBlockJungleWoodStairs				= 136,	// Data: kMCInfoStairOrientation, kMCInfoStairUpsideDown
	kMCBlockCommandBlock					= 137,	// Tile entity: Control
	kMCBlockBeacon							= 138,	// Tile entity: Beacon
	kMCBlockCobblestoneWall					= 139,	// Data: kMCInfoCobblestoneWallType
	kMCBlockFlowerPot						= 140,	// Data: kMCInfoFlowerPotType
	kMCBlockCarrots							= 141,	// Data: FIXME (growth stages)
	kMCBlockPotatoes						= 142,	// Data: FIXME (growth stages)
	kMCBlockWoodenButton					= 143,	// Data: kMCInfoMiscOrientation, kMCInfoButtonOn
	kMCBlockHead							= 144,	// Data: kMCInfoMisc2Orientation; tile entity: Skull
	kMCBlockAnvil							= 145,	// Data: kMCInfoAnvilOrientation, kMCInfoAnvilDamageLevel
	kMCBlockTrappedChest					= 146,	// Data: kMCInfoMisc2Orientation. tile entity: Chest
	kMCBlockGoldPressurePlate				= 147,	// Data: kMCInfoPressurePlateOn
	kMCBlockIronPressurePlate				= 148,	// Data: kMCInfoPressurePlateOn
	kMCBlockRedstoneComparatorOff			= 149,	// FIXME: orientation and mode in data. Tile entity: Comparator
	kMCBlockRedstoneComparatorOn			= 150,	// As above
	kMCBlockDaylightSensor					= 151,
	kMCBlockRedstoneBlock					= 152,
	kMCBlockNetherQuartzOre					= 153,
	kMCBlockHopper							= 154,	// Data: kMCInfoMisc2Orientation; tile entity: Hopper
	kMCBlockQuartzBlock						= 155,
	kMCBlockQuartzStairs					= 156,
	kMCBlockActivatorRail					= 157,	// FIXME: data. Presumably one bit for active.
	kMCBlockDropper							= 158,	// Data: kMCInfoMisc2Orientation; tile entity: Dropper
	kMCBlockStainedClay						= 159,	// Data: kMCInfoWoolColor
	kMCBlockStainedGlassPane				= 160,	// Data: FIXME (kMCInfoWoolColor?)
	// 161-169: unused
	kMCBlockHayBlock						= 170,	// FIXME: data. Hopefully kMCInfoLogOrientation?
	kMCBlockCarpet							= 171,	// Data: kMCInfoWoolColor
	kMCBlockHardenedClay					= 172,
	kMCBlockCoalBlock						= 173,
	kMCBlockPackedIce						= 174,
	kMCBlockDoublePlant						= 175,	// Data: kMCInfoDoublePlantType
};


#define kMCLastBlockID kMCBlockDoublePlant


enum
{
	/*	Info - block data in Minecraft terminology, called info here to avoid
		confusion.
		Minecraft stores four bits of data for each block. In schematic files,
		eight bits per block are stored, but the top four bits are always
		clear. The meaning of bits depends on the block ID. Names ending with
		“Mask” are multi-bit values.
		MinecraftKit stores eight info bits per block in memory. The bottom
		four bits are Minecraft flags, and the top four are MinecraftKit-
		internal.
	*/
	
	kMCInfoStandardBitsMask					= 0x0F,
	
	/*	Any block type: a flag indicating that a block is powered. This is
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
	kMCInfoWoodTypeSpruce					= 0x01,
	kMCInfoWoodTypeBirch					= 0x02,
	kMCInfoWoodTypeJungle					= 0x03,
	
	/*	Logs: orientation. There are only three valid orientations because of
		the symmetry of logs (and only having two bits). The invalid combination
		0x0C produces a block with bark on all sides.
	*/
	kMCInfoLogOrientationMask				= 0x0C,
	kMCInfoLogOrientationVertical			= 0x00,
	kMCInfoLogOrientationEastWest			= 0x04,
	kMCInfoLogOrientationNorthSouth			= 0x08,
	kMCInfoLogOrientationNone				= 0x0C,
	
	/*	Leaves: if the pending flag is set, the leaf block will be checked for
		random decay. If it’s clear, the block won’t decay (but the flag is
		set again if any adjacent block changes).
		
		Advice: if adding leaf blocks, set the pending flag and let Minecraft
		clear it when valid.
	 */
	kMCInfoLeafUpdatePending				= 0x04,
	kMCInfoLeafPermanent					= 0x08,
	
	/*	Sandstone block: appearance of sides.
	*/
	kMCInfoSandstoneAppearanceMask			= 0x03,
	kMCInfoSandstoneAppearanceDefault		= 0x00,
	kMCInfoSandstoneAppearanceChiseled		= 0x01,
	kMCInfoSandstoneAppearanceSmooth		= 0x02,
	
	/*	Wool: colour.
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
			Torch
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
	kMCInfoBedIsHead						= 0x08,
	
	/*	Stair orientations.
		The labels are intended to refer to the _ascending_ direction.
	*/
	kMCInfoStairOrientationMask				= 0x03,
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
	
	/*	kMCInfoMisc2Orientation
		Another common set of orientation flags, used for:
		* Ladders
		* Chests
		* Wall signs
		* Furnaces
		* Dispensers
	    * Heads
	*/
	kMCInfoMisc2OrientationMask				= 0x07,
	kMCInfoMisc2OrientationFloor			= 0x01,	// Heads only
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
	
	/*	Pumpkin/Jack-o-lantern orientation.
	*/
	kMCInfoPumpkinOrientationMask			= 0x03,
	kMCInfoPumpkinOrientationSouth			= 0x00,
	kMCInfoPumpkinOrientationEast			= 0x01,
	kMCInfoPumpkinOrientationNorth			= 0x02,
	kMCInfoPumpkinOrientationWest			= 0x03,
	
	/*	Bed/redstone repeater/cocoa orientation.
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
	
	/*	Sticky and non-sticky piston bases are distinguished by type, but
		heads use a flag.
	*/
	kMCInfoPistonHeadIsSticky				= 0x08,
	
	/*	Types of “tall grass” (or, more generally, ground cover).
		Note that “dead shrubs” can be represented as their own block type or
		as a tall grass object.
	*/
	kMCInfoTallGrassTypeMask				= 0x03,
	kMCInfoTallGrassTypeDeadShrub			= 0x00,
	kMCInfoTallGrassTypeTallGrass			= 0x01,
	kMCInfoTallGrassTypeFern				= 0x02,
	
	/*	Types of slab. Values above 7 are only used for double slabs.
	*/
	kMCInfoSlabTypeMask						= 0x07,
	kMCInfoDoubleSlabTypeMask				= 0x07,
	kMCInfoSlabTypeStone					= 0x00,
	kMCInfoSlabTypeSandstone				= 0x01,
	kMCInfoSlabTypeWood						= 0x02,	// Pre-1.3 oak-looking wooden slab
	kMCInfoSlabTypeCobblestone				= 0x03,
	kMCInfoSlabTypeBrick					= 0x04,
	kMCInfoSlabTypeStoneBrick				= 0x05,
	kMCInfoSlabTypeNetherBrick				= 0x06,
	kMCInfoSlabTypeQuartz					= 0x07,
	kMCInfoSlabSmoothStoneUndivided			= 0x08,
	kMCInfoSlabSmoothSandstone				= 0x09,
	kMCInfoSlabTileQuartz					= 0x0F,
	
	kMCInfoSlabUpsideDown					= 0x08,
	
	/*	Types of flower (not counting yellow flowers, which have their own
		block ID for historical reasons, and "double plants".
	*/
	kMCInfoFlowerTypePoppy					= 0x00,
	kMCInfoFlowerTypeBlueOrchid				= 0x01,
	kMCInfoFlowerTypeAllium					= 0x02,
	kMCInfoFlowerTypeAzureBluet				= 0x03,
	kMCInfoFlowerTypeRedTulip				= 0x04,
	kMCInfoFlowerTypeOrangeTulip			= 0x05,
	kMCInfoFlowerTypeWhiteTulip				= 0x06,
	kMCInfoFlowerTypePinkTulip				= 0x07,
	kMCInfoFlowerTypeOxeyeDaisy				= 0x08,
	
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
		
		The orientation of a trapdoor is the side away from the hinge (the
		opposite of the usage on the wiki, which is silly).
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
	
	/*	Gourd stem age: age of pumpkin and melon stems, ranging from 0 to 7.
	*/
	kMCInfoGourdStemAge						= 0x07,
	
	/*	Vine attachment is a bit mask rather than an enumeration – vines may
		be attached to multiple sides at once.
	*/
	kMCInfoVineAttachmentMask				= 0x0F,
	kMCInfoVineAttachmentSouth				= 0x01,
	kMCInfoVineAttachmentWest				= 0x02,
	kMCInfoVineAttachmentNorth				= 0x04,
	kMCInfoVineAttachmentEast				= 0x08,
	
	/*	Nether Wart age ranges from 0 to 3, with 1 and 2 looking the same.
	*/
	kMCInfoNetherWartAge					= 0x03,
	
	/*	Flags indicating which of a brewing stand’s three slots are occupied
		by bottles. Note that actual information about bottles is in tile
		entity.
	*/
	kMCInfoBrewingStandBottleSlotEast		= 0x01,
	kMCInfoBrewingStandBottleSlotSouthWest	= 0x02,
	kMCInfoBrewingStandBottleSlotNorthWest	= 0x04,
	
	/*	Cauldron fill level ranges from 0 to 3.
	*/
	kMCInfoCauldronFillLevelMask			= 0x03,
	
	/*	kMCInfoEndPortalFrameHasEye: whether an end portal frame block has an
		Eye of Ender in it.
	*/
	kMCInfoEndPortalFrameHasEye				= 0x04,
	
	/*	kMCInfoCocoaPodAge: growth stages of a cocoa pod.
	*/
	kMCInfoCocoaPodAgeMask					= 0x0C,
	kMCInfoCocoaPodAgeSmall					= 0x00,
	kMCInfoCocoaPodAgeMedum					= 0x04,
	kMCInfoCocoaPodAgeLarge					= 0x08,
	
	/*	kMCInfoTripwireHookOrientation: because what we really need is another
		orientation enumeration.
	*/
	kMCInfoTripwireHookOrientationMask		= 0x03,
	kMCInfoTripwireHookOrientationSouth		= 0x00,
	kMCInfoTripwireHookOrientationWest		= 0x01,
	kMCInfoTripwireHookOrientationNorth		= 0x02,
	kMCInfoTripwireHookOrientationEast		= 0x03,
	
	/*	kMCInfoTripwireHookConnected: true if this hook is connected by a
		complete wire to another hook.
		kMCInfoTripWireHookActive: true if the wire this hook is connected to
		is activated.
	*/
	kMCInfoTripwireHookConnected			= 0x04,
	kMCInfoTripWireHookActive				= 0x08,
	
	/*	kMCInfoTripwirePieceActive: true if this particular piece of string is
		activated.
		kMCInfoTripwireWireActive: true if this block is part of an activated
		wire.
	*/
	kMCInfoTripwirePieceActive				= 0x01,
	kMCInfoTripwireWireActive				= 0x04,
	
	/*	Cobblestone wall variants.
	*/
	kMCInfoCobblestoneWallTypeMask			= 0x01,
	kMCInfoCobblestoneWallTypePlain			= 0x00,
	kMCInfoCobblestoneWallTypeMossy			= 0x01,
	
	/*	Flower pot contents.
	*/
	kMCInfoFlowerPotTypeMask				= 0x0F,
	kMCInfoFlowerPotTypeEmpty				= 0x00,
	kMCInfoFlowerPotTypeRedFlower			= 0x01,
	kMCInfoFlowerPotTypeYellowFlower		= 0x02,
	kMCInfoFlowerPotTypeOakSapling			= 0x03,
	kMCInfoFlowerPotTypeSpruceSapling		= 0x04,
	kMCInfoFlowerPotTypeBirchSapling		= 0x05,
	kMCInfoFlowerPotTypeJungleSapling		= 0x06,
	kMCInfoFlowerPotTypeRedMushroom			= 0x07,
	kMCInfoFlowerPotTypeBrownMushroom		= 0x08,
	kMCInfoFlowerPotTypeCactus				= 0x09,
	kMCInfoFlowerPotTypeDeadShrub			= 0x0A,
	kMCInfoFlowerPotTypeFern				= 0x0B,
	
	/*	Anvil orientations.
	*/
	kMCInfoAnvilOrientationMask				= 0x01,
	kMCInfoAnvilOrientationNorthSouth		= 0x00,
	kMCInfoAnvilOrientationEastWest			= 0x01,
	
	/*	Anvil damage levels. Medium is "Slighty Damaged Anvil", high is "Very
		Damaged Anvil".
	*/
	kMCInfoAnvilOrientationDamageLevelMask	= 0x0C,
	kMCInfoAnvilOrientationDamageLow		= 0x00,
	kMCInfoAnvilOrientationDamageMedium		= 0x04,
	kMCInfoAnvilOrientationDamageHigh		= 0x08,
	
	/*	Types of "double plant" block.
		A double plant consists of two blocks stacked vertically. The bottom
		one defines the species, and the top one is always
		kMCInfoDoublePlantTypeTopHalf.
	*/
	kMCInfoDoublePlantTypeSunflower			= 0x00,
	kMCInfoDoublePlantTypeLilac				= 0x01,
	kMCInfoDoublePlantTypeDoubleTallGrass	= 0x02,
	kMCInfoDoublePlantTypeLargeFern			= 0x03,
	kMCInfoDoublePlantRoseBush				= 0x04,
	kMCInfoDoublePlantPeony					= 0x05,
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
	kMCBlockPrimaryTypeMask					= 0x000F,
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
		Coal, iron, gold, redstone, diamond, emerald, lapis or quartz ore
		blocks. Eat it, geologists.
	*/
	kMCBlockIsOre							= 0x0080,
	
	/*
		Rail, powered rail, detector rail or activator rail.
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
	return kMCBlockTypeClassifications[blockID] & kMCBlockIsPowerActive || blockID == kMCBlockRedstoneWire;
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
