/*
	JAMinecraftBlock.m
	
	
	Copyright © 2011 Jens Ayton
	
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

#import "JAMinecraftBlock.h"
#import "MYCollectionUtilities.h"
#import "JAPropertyListAccessors.h"
#import <objc/runtime.h>

@interface JAMinecraftBlock (Internal)

- (id) init_internalDesignatedInit;

@end


@interface JAConcreteMinecraftBlock: JAMutableMincraftBlock
{
@private
	uint8_t				_blockID;
	uint8_t				_blockData;
	uint8_t				_mutable;
	NSDictionary		*_tileEntity;
}

- (id) initWithID:(uint8_t)blockID data:(uint8_t)blockData tileEntity:(NSDictionary *)tileEntity mutable:(BOOL)mutable;

@end


static inline void ThrowSubclassResponsibility(const char *name) __attribute((noreturn));
#define SUBCLASS_RESPONSIBILITY() ThrowSubclassResponsibility(__func__)

static inline void ThrowImmutable(const char *name) __attribute((noreturn));
#define IMMUTABLE() ThrowImmutable(__func__)


@implementation JAMinecraftBlock

- (id)init
{
	return [[self class] blockWithID:kMCBlockAir data:0 tileEntity:nil];
}


- (id) init_internalDesignatedInit
{
	return [super init];
}


- (NSUInteger) hash
{
	return self.blockID | (self.blockData << 8) | (self.tileEntity.hash << 16);
}


- (NSString *) description
{
	return $sprintf(@"<%@ %p>{ ID: %u, data: 0x%X }", self.class, self, self.blockID, self.blockData);
}


static inline BOOL BlocksEqual(JAMinecraftBlock *a, JAMinecraftBlock *b) __attribute__((nonnull));
static inline BOOL BlocksEqual(JAMinecraftBlock *a, JAMinecraftBlock *b)
{
	return a.blockID == b.blockID && a.blockData == b.blockData && $equal(a.tileEntity, b.tileEntity);
}


- (BOOL) isEqual:(id)other
{
	return [other isKindOfClass:[JAMinecraftBlock class]] && BlocksEqual(self, other);
}


- (BOOL) isEqualToBlock:(JAMinecraftBlock *)other
{
	return BlocksEqual(self, other);
}


- (id) copyWithZone:(NSZone *)zone { SUBCLASS_RESPONSIBILITY(); }
- (id) mutableCopyWithZone:(NSZone *)zone { SUBCLASS_RESPONSIBILITY(); }


- (NSString *) shortBlockDescription
{
	return MCShortDescriptionForBlockID(self.blockID);
}


- (NSString *) longBlockDescription
{
	return MCCellLongDescription((MCCell){ self.blockID, self.blockData }, self.tileEntity);
}

@dynamic blockID, blockData, tileEntity;

@end


/*
	Cache of immutable blocks with zero data and default tile entity.
	We also cache the hole block as a special case.
	
	Alternative caching scheme: use a weak map of existing immutable blocks
	with no tile entity. There can be at most USHRT_MAX of them. NSNumber
	keys are near-free in Lion.
*/
static JAMinecraftBlock *sZeroDataBlockCache[kMCLastBlockID + 1];
static JAMinecraftBlock *sHoleBlock;


static inline BOOL IsEligibleForCache(uint8_t blockID, uint8_t blockData, NSDictionary *tileEntity)
{
	return blockData == 0 && tileEntity == nil && blockID <= kMCLastBlockID;
}


@implementation JAMinecraftBlock (Creation)

+ (void) initialize
{
	if (self == [JAMinecraftBlock class])
	{
		for (unsigned blockID = 0; blockID <= kMCLastBlockID; blockID++)
		{
			NSAssert(IsEligibleForCache(blockID, 0, nil), @"Cache eligibilty definition is inconsistent.");
					 sZeroDataBlockCache[blockID] = [[JAConcreteMinecraftBlock alloc] initWithID:blockID
																							data:0
																					  tileEntity:nil
																						 mutable:NO];
		}
		
		sHoleBlock = [self blockWithID:kMCBlockAir data:kMCInfoAirIsHole tileEntity:nil];
	}
}


+ (id) blockWithID:(uint8_t)blockID data:(uint8_t)blockData tileEntity:(NSDictionary *)tileEntity
{
	if (IsEligibleForCache(blockID, blockData, tileEntity))
	{
		NSCAssert(sZeroDataBlockCache[blockID] != nil, @"Expected block cache to contain all eligible blocks.");
		return sZeroDataBlockCache[blockID];
	}
	else if (blockID == kMCBlockAir && blockData == kMCInfoAirIsHole)
	{
		return sHoleBlock;
	}
	else
	{
		return [[JAConcreteMinecraftBlock alloc] initWithID:blockID data:blockData tileEntity:tileEntity mutable:NO];
	}
}


+ (id) blockWithCell:(MCCell)cell tileEntity:(NSDictionary *)tileEntity
{
	return [self blockWithID:cell.blockID data:cell.blockData tileEntity:tileEntity];
}


+ (JAMinecraftBlock *) airBlock
{
//	return [self blockWithID:kMCBlockAir data:0 tileEntity:nil];
	return sZeroDataBlockCache[kMCBlockAir];
}


+ (JAMinecraftBlock *) holeBlock
{
	return sHoleBlock;
}


+ (JAMinecraftBlock *) stoneBlock
{
//	return [self blockWithID:kMCBlockSmoothStone data:0 tileEntity:nil];
	return sZeroDataBlockCache[kMCBlockSmoothStone];
}

@end


@implementation JAMinecraftBlock (Conveniences)

- (MCCell) cell
{
	return (MCCell){ self.blockID, self.blockData };
}

@end


@implementation JAMutableMincraftBlock


+ (id) blockWithID:(uint8_t)blockID data:(uint8_t)blockData tileEntity:(NSDictionary *)tileEntity
{
	return [[JAConcreteMinecraftBlock alloc] initWithID:blockID data:blockData tileEntity:tileEntity mutable:YES];
}

@dynamic blockID, blockData, tileEntity;

@end


@implementation JAConcreteMinecraftBlock

- (id) initWithID:(uint8_t)blockID data:(uint8_t)blockData tileEntity:(NSDictionary *)tileEntity mutable:(BOOL)mutable
{
	if (self = [super init_internalDesignatedInit])
	{
		_blockID = blockID;
		_blockData = blockData;
		_tileEntity = [tileEntity copy];	// FIXME: validate
		_mutable = mutable;
	}
	
	return self;
}


- (id) copyWithZone:(NSZone *)zone
{
	if (!_mutable)  return self;
	
	// Round-trip through JAMinecraftBlock to get caching behaviour.
	return [JAMinecraftBlock blockWithID:_blockID data:_blockID tileEntity:_tileEntity];
}


- (id) mutableCopyWithZone:(NSZone *)zone
{
	return [[JAConcreteMinecraftBlock alloc] initWithID:_blockID
												   data:_blockData
											 tileEntity:_tileEntity
												mutable:YES];
}


- (uint8_t) blockID
{
	return _blockID;
}


- (void) setBlockID:(uint8_t)value
{
	// FIXME: handle tile entity
	if (_mutable)  _blockID = value;
	else  IMMUTABLE();
}


- (uint8_t) blockData
{
	return _blockData;
}


- (void) setBlockData:(uint8_t)value
{
	if (_mutable)  _blockData = value;
	else  IMMUTABLE();
}


- (NSDictionary *) tileEntity
{
	return _tileEntity;
}


- (void) setTileEntity:(NSDictionary *)value
{
	if (_mutable)
	{
		if (value == nil)
		{
			_tileEntity = MCStandardTileEntityForBlockID(_blockID);
		}
		else
		{
			MCRequireTileEntityIsCompatibleWithCell(value, self.cell);
			_tileEntity = [value copy];
		}
	}
	else  IMMUTABLE();
}

@end


static inline void ThrowSubclassResponsibility(const char *name)
{
	[NSException raise:NSGenericException format:@"%s is a subclass responsibility.", name];
	__builtin_unreachable();
}


static inline void ThrowImmutable(const char *name)
{
	[NSException raise:NSGenericException format:@"%s: attempt to mutate an immutable JAMincraftBlock.", name];
	__builtin_unreachable();
}
