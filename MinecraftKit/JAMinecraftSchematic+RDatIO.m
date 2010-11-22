/*
	JAMinecraftSchematic+RDatIO.m
	
	Nasty, horrible code. The format is pretty simple, though.
	
	
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

#import "JAMinecraftSchematic+RDatIO.h"


NSString * const kJAMinecraftRedstoneSimulatorUTI = @"com.carneiro.mcredsim.rdat";


enum
{
	kRDATCellAir					= 0,
	kRDATCellFilled					= 1,
	kRDATCellWire					= 2,
	kRDATCellTorch					= 3,
	kRDATCellLever					= 4,
	kRDATCellButton					= 5,
	kRDATCellDoorBottom				= 6,
	kRDATCellDoorTop				= 7,
	kRDATCellPressurePlate			= 8,
	
	kRDATCellHole					= 11	// "shadow block"
};


enum
{
	kRDATCellInfoNone				= 0,
	
	kRDATCellInfoBlockClearAbove	= 0x10,	// ?? Appears on blocks if space above is clear?
	
	kRDATCellInfoTorchLive			= 0x10,
	kRDATCellInfoSwitchLive			= 0x10,
	kRDATCellInfoDoorLive			= 0x10,
	kRDATCellInfoPressurePlateLive	= 0x01,
	
	kRDATCellInfoOrientationNorth	= 0x20,
	kRDATCellInfoOrientationSouth	= 0x40,
	kRDATCellInfoOrientationWest	= 0x60,
	kRDATCellInfoOrientationEast	= 0x80,
	kRDATCellInfoOrientationMask	= 0xE0,
	
	// Low nybble is signal strength for wires.
	kRDATCellInfoWireStrengthMask	= 0x0F
};


static MCCell CellFromRDATData(uint8_t type, uint8_t info);
void RDATDataFromCell(MCCell cell, uint8_t *type, uint8_t *info);

static uint8_t OrientationFromRDATInfo(uint8_t info);
static uint8_t CellInfoOrientationFromMeta(uint8_t meta);
static uint8_t CellInfoOrientationFromDoorMeta(uint8_t meta);


@implementation JAMinecraftSchematic (RDatIO)

- (id) initWithRDatData:(NSData *)data error:(NSError **)outError
{
	if (outError != NULL)  *outError = nil;
	
	if (data == nil)
	{
		if (outError != nil)  *outError = [NSError errorWithDomain:kJAMinecraftBlockStoreErrorDomain
															  code:kJABlockStoreErrorNilData
														  userInfo:nil];
		return nil;
	}
	const uint8_t *bytes = [data bytes];
	NSUInteger remaining = [data length];
	
	BOOL headerOK = YES;
	// Header is 11 bytes.
	if (remaining < 11)  headerOK = NO;
	else
	{
		// Scan signature bytes and version.
		if (*bytes++ != 'R')  headerOK = NO;
		if (*bytes++ != 'e')  headerOK = NO;
		if (*bytes++ != 'd')  headerOK = NO;
		if (*bytes++ != 'S')  headerOK = NO;
	}
	
	if (!headerOK)
	{
		if (outError != nil)  *outError = [NSError errorWithDomain:kJAMinecraftBlockStoreErrorDomain
															  code:kJABlockStoreErrorWrongFileFormat
														  userInfo:nil];
		return nil;
	}
	
	if (*bytes++ != 1)
	{
		if (outError != nil)  *outError = [NSError errorWithDomain:kJAMinecraftBlockStoreErrorDomain
															  code:kJABlockStoreErrorUnknownFormatVersion
														  userInfo:nil];
		return nil;
	}
	
	// Read dimensions.
	NSInteger length, width, height;
	height = (*bytes++ << 8) + *bytes++;
	width = (*bytes++ << 8) + *bytes++;
	length = (*bytes++ << 8) + *bytes++;
	remaining -= 11;
	
	NSUInteger planeSize = length * width * height;
	if (planeSize == 0)
	{
		if (outError != nil)  *outError = [NSError errorWithDomain:kJAMinecraftBlockStoreErrorDomain
															  code:kJABlockStoreErrorEmptyDocument
														  userInfo:nil];
		return nil;
	}
	if (remaining < planeSize * 2)
	{
		if (outError != nil)  *outError = [NSError errorWithDomain:kJAMinecraftBlockStoreErrorDomain
															  code:kJABlockStoreErrorTruncatedData
														  userInfo:nil];
		return nil;
	}
	
	self = [self init];
	if (self == nil)
	{
		if (outError != nil)  *outError = [NSError errorWithDomain:NSOSStatusErrorDomain
															  code:memFullErr
														  userInfo:nil];
		return nil;
	}
	
	[self beginBulkUpdate];
	
	const uint8_t *infoBytes = bytes + planeSize;
	MCGridCoordinates location;
	for (location.y = 0; location.y < height; location.y++)
	{
		for (location.x = 0; location.x < width; location.x++)
		{
			for (location.z = length; location.z > 0; location.z--)
			{
				[self setCell:CellFromRDATData(*bytes++, *infoBytes++)
						   at:location];
			}
		}
	}
	
	[self endBulkUpdate];
	
	return self;
}


- (NSData *) rDatDataWithError:(NSError **)outError
{
	return [self rDatDataForRegion:self.extents withError:outError];
}


- (NSData *) rDatDataForRegion:(MCGridExtents)region withError:(NSError **)outError
{
	if (outError != NULL)  *outError = nil;
	
	NSUInteger width = MCGridExtentsWidth(region);
	NSUInteger length = MCGridExtentsLength(region);
	NSUInteger height = MCGridExtentsHeight(region);
	
	if (width > 65535 || length > 65535 || height > 65535)
	{
		if (outError != NULL) *outError = [NSError errorWithDomain:kJAMinecraftBlockStoreErrorDomain
															  code:kJABlockStoreErrorDocumentTooLarge
														  userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"This document is too large to be stored in RDAT format. RDAT format is limited to 65535 blocks in each dimension.", NULL) forKey:NSLocalizedFailureReasonErrorKey]];
		return nil;
	}
	
	NSUInteger planeSize = width * length * height;
	size_t bufferSize = 11 + planeSize * 2;
	
	uint8_t *buffer = malloc(bufferSize);
	if (buffer == NULL)
	{
		if (outError != nil)  *outError = [NSError errorWithDomain:NSOSStatusErrorDomain
															  code:memFullErr
														  userInfo:nil];
		return nil;
	}
	
	uint8_t *bytes = buffer;
	*bytes++ = 'R';
	*bytes++ = 'e';
	*bytes++ = 'd';
	*bytes++ = 'S';
	*bytes++ = 1;
	*bytes++ = height >> 8;
	*bytes++ = height & 0xFF;
	*bytes++ = width >> 8;
	*bytes++ = width & 0xFF;
	*bytes++ = length >> 8;
	*bytes++ = length & 0xFF;
	
	uint8_t *infoBytes = bytes + planeSize;
	MCGridCoordinates location;
	for (location.y = region.minY; location.y <= region.maxY; location.y++)
	{
		for (location.x = region.minX; location.x <= region.maxX; location.x++)
		{
			for (location.z = region.maxZ; location.z >= region.minZ; location.z--)
			{
				MCCell cell = [self cellAt:location];
				RDATDataFromCell(cell, bytes, infoBytes);
				
				bytes++;
				infoBytes++;
			}
		}
	}
	
	return [NSData dataWithBytesNoCopy:buffer length:bufferSize freeWhenDone:YES];
}

@end


static MCCell CellFromRDATData(uint8_t type, uint8_t info)
{
	uint8_t blockID = 0;
	uint8_t blockData = 0;
	
	switch (type)
	{
		case kRDATCellAir:
		case kRDATCellHole:	// FIXME: handle holes (extra bit?)
			blockID = kMCBlockAir;
			break;
			
		case kRDATCellFilled:
			blockID = kMCBlockCobblestone;
			break;
			
		case kRDATCellDoorTop:
		case kRDATCellDoorBottom:
			blockID = kMCBlockIronDoor;
			if (type == kRDATCellDoorTop)  blockData = 8;	// Top half
			if (info & kRDATCellInfoDoorLive)  blockData |= 4;	// open
			switch (info & kRDATCellInfoOrientationMask)
			{
				case kRDATCellInfoOrientationWest:
					blockData |= kMCInfoDoorOrientationEast;
					break;
					
				case kRDATCellInfoOrientationSouth:
					blockData |= kMCInfoDoorOrientationNorth;
					break;
					
				case kRDATCellInfoOrientationEast:
					blockData |= kMCInfoDoorOrientationWest;
					break;
					
				case kRDATCellInfoOrientationNorth:
					blockData |= kMCInfoDoorOrientationSouth;
					break;
			}
			break;
			
		case kRDATCellWire:
			blockID = kMCBlockRedstoneWire;
			blockData = info & kRDATCellInfoWireStrengthMask;
			break;
			
		case kRDATCellTorch:
			if (info & kRDATCellInfoTorchLive)  blockID = kMCBlockRedstoneTorchOn;
			else  blockID = kMCBlockRedstoneTorchOff;
			blockData = OrientationFromRDATInfo(info);
			break;
			
		case kRDATCellButton:
			blockID = kMCBlockStoneButton;
			blockData = OrientationFromRDATInfo(info);
			if (info & kRDATCellInfoSwitchLive)  blockData |= 8;
			break;
			
		case kRDATCellLever:
			blockID = kMCBlockLever;
			blockData = OrientationFromRDATInfo(info);
			if (info & kRDATCellInfoSwitchLive)  blockData |= 8;
			break;
			
		case kRDATCellPressurePlate:
			blockID = kMCBlockWoodenPressurePlate;
			if (info & kRDATCellInfoPressurePlateLive)  blockData = 1;
			break;
	}
	
	return (MCCell){ .blockID = blockID, .blockData = blockData };
}


static uint8_t OrientationFromRDATInfo(uint8_t info)
{
	switch (info & kRDATCellInfoOrientationMask)
	{
		case kRDATCellInfoOrientationEast:
			return kMCInfoMiscOrientationEast;
			
		case kRDATCellInfoOrientationWest:
			return kMCInfoMiscOrientationWest;
			
		case kRDATCellInfoOrientationSouth:
			return kMCInfoMiscOrientationSouth;
			
		case kRDATCellInfoOrientationNorth:
			return kMCInfoMiscOrientationNorth;
			
		default:
			return kMCInfoMiscOrientationFloor;
	}
}


void RDATDataFromCell(MCCell cell, uint8_t *outType, uint8_t *outInfo)
{
	NSCParameterAssert(outType != NULL && outInfo != NULL);
	
	uint8_t type = 0;
	uint8_t info = 0;
	uint8_t data = cell.blockData;
	
	switch (cell.blockID)
	{
		case kMCBlockWoodenDoor:
		case kMCBlockIronDoor:
			if (data & kMCInfoInfoDoorTopHalf)  type = kRDATCellDoorTop;
			else  type = kRDATCellDoorBottom;
			if (data & kMCInfoInfoDoorOpen)  info |= kRDATCellInfoDoorLive;
			info |= CellInfoOrientationFromDoorMeta(data);
			break;
			
		case kMCBlockRedstoneWire:
			type = kRDATCellWire;
			info = data & kMCInfoRedstoneWireSignalStrengthMask;
			break;
			
		case kMCBlockRedstoneTorchOn:
		case kMCBlockRedstoneTorchOff:
			type = kRDATCellTorch;
			if (cell.blockID == kMCBlockRedstoneTorchOn)  info |= kRDATCellInfoTorchLive;
			info |= CellInfoOrientationFromMeta(data);
			break;
			
		case kMCBlockLever:
			type = kRDATCellLever;
			if (data & kMCInfoLeverOn)  info |= kRDATCellInfoSwitchLive;
			info |= CellInfoOrientationFromMeta(data);
			break;
			
		case kMCBlockStoneButton:
			type = kRDATCellButton;
			if (data & kMCInfoButtonOn)  info |= kRDATCellInfoSwitchLive;
			info |= CellInfoOrientationFromMeta(data);
			break;
			
		case kMCBlockWoodenPressurePlate:
		case kMCBlockStonePressurePlate:
			type = kRDATCellPressurePlate;
			if (data & kMCInfoPressurePlateOn)  info |= kRDATCellInfoPressurePlateLive;
			break;
			
		default:
			if (MCCellIsFullySolid(cell))
			{
				type = kRDATCellFilled;
			}
			else
			{
				type = kRDATCellAir;
			}
	}
	
	*outType = type;
	*outInfo = info;
}


static uint8_t CellInfoOrientationFromMeta(uint8_t meta)
{
	switch (meta & kMCInfoMiscOrientationMask)
	{
		case kMCInfoMiscOrientationSouth:
			return kRDATCellInfoOrientationSouth;
			
		case kMCInfoMiscOrientationNorth:
			return kRDATCellInfoOrientationNorth;
			
		case kMCInfoMiscOrientationWest:
			return kRDATCellInfoOrientationWest;
			
		case kMCInfoMiscOrientationEast:
			return kRDATCellInfoOrientationEast;
			
			// 5 and 6 are different orientations for ground levers, not reflected in rdat.
		case kMCInfoMiscOrientationFloor:
		case kMCInfoLeverOrientationFloorNS:
			return 0;
			
		default:
			return kRDATCellInfoOrientationMask;	// Results in error display.
	}
}


static uint8_t CellInfoOrientationFromDoorMeta(uint8_t meta)
{
	switch (meta & kMCInfoDoorOrientationMask)
	{
		case kMCInfoDoorOrientationEast:
			return kRDATCellInfoOrientationWest;
			
		case kMCInfoDoorOrientationNorth:
			return kRDATCellInfoOrientationSouth;
			
		case kMCInfoDoorOrientationWest:
			return kRDATCellInfoOrientationEast;
			
		case kMCInfoDoorOrientationSouth:
			return kRDATCellInfoOrientationNorth;
	}
	
	__builtin_unreachable();
}
