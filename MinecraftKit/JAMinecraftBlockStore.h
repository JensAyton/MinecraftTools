/*
	JAMinecraftBlockStore.h
	
	Abstract block store.
	
	
	Copyright © 2010–2013 Jens Ayton
	
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

@class JAMinecraftBlock;


enum
{
	kMCBlockStoreMaximumPermittedHeight = 128
};


@interface JAMinecraftBlockStore: NSObject

@property (readonly) MCGridExtents extents;

/*
	Minimum and maximum layer: highest and lowest y coordinates in which
	blocks may be added without going over 128 blocks high.
*/
@property (readonly) NSInteger minimumLayer;
@property (readonly) NSInteger maximumLayer;

/*
	Lowest Y coordinate where undefined space is assumed to be air; below this,
	it’s assumed to be smooth stone.
*/
@property (readonly) NSInteger groundLevel;

/*
	Access primitive: retrieves cell data and tile entity. outTileEntity may
	be NULL. See Conveniences category below for alternative forms.
	
	The caller is responsible for ensuring that the cell and tile entity are
	compatible (as per MCTileEntityIsCompatibleWithCell()). If they are not,
	NSInvalidArgumentException will be thrown.
*/
- (MCCell) cellAt:(MCGridCoordinates)location gettingTileEntity:(NSDictionary **)outTileEntity;

@end


@interface JAMutableMinecraftBlockStore: JAMinecraftBlockStore

- (void) setCell:(MCCell)cell andTileEntity:(NSDictionary *)tileEntity at:(MCGridCoordinates)location;

/*
	Bulk updates: while a bulk update is in progress, changes are coalesced into
	a dirty region, which is then posted as a singe notification when bulk
	updating ends.
	Bulk updates can be nested, in which case the notification will be sent
	when the outermost bulk update ends.
*/
- (void) beginBulkUpdate;
- (void) endBulkUpdate;

@property (readonly) BOOL bulkUpdateInProgress;

#ifndef NDEBUG
@property (readonly) NSUInteger bulkUpdateNestingLevel;
#endif

/*	
	Fill the specified region with a uniform block type.
*/
- (void) fillRegion:(MCGridExtents)region withCell:(MCCell)cell;

/*
	Copy blocks from another schematic.
	IMPORTANT: air blocks are ignored, not copied. Erase the target region
	first if you want that behaviour.
*/
- (void) copyRegion:(MCGridExtents)region from:(JAMinecraftBlockStore *)source at:(MCGridCoordinates)target;


/***** Subclass interface *****/
- (void) noteChangeInExtents:(MCGridExtents)changedExtents;
- (void) noteChangeInLocation:(MCGridCoordinates)changedLocation;

@end


@interface JAMinecraftBlockStore (Conveniences)

@property (readonly) NSUInteger width;
@property (readonly) NSUInteger length;
@property (readonly) NSUInteger height;

- (JAMinecraftBlock *) blockAt:(MCGridCoordinates)location;

- (MCCell) cellAt:(MCGridCoordinates)location;
- (NSDictionary *) tileEntityAt:(MCGridCoordinates)location;

- (MCCell) cellAtX:(NSInteger)x y:(NSInteger)y z:(NSInteger)z gettingTileEntity:(NSDictionary **)outTileEntity;
- (MCCell) cellAtX:(NSInteger)x y:(NSInteger)y z:(NSInteger)z;
- (NSDictionary *) tileEntityAtX:(NSInteger)x y:(NSInteger)y z:(NSInteger)z;

@end


@interface JAMutableMinecraftBlockStore (Conveniences)

- (void) setBlock:(JAMinecraftBlock *)block at:(MCGridCoordinates)location;

/*
	NOTE: setting cell and tile entity separately is discouraged as it involves
	extra work to ensure consistency with the existing tile entity/cell.
	
	If setCell: changes the cell type, any existing tile entity will be removed.
*/
- (void) setCell:(MCCell)cell at:(MCGridCoordinates)location;
- (void) setTileEntity:(NSDictionary *)tileEntity at:(MCGridCoordinates)location;

- (void) setCell:(MCCell)cell atX:(NSInteger)x y:(NSInteger)y z:(NSInteger)z;
- (void) setTileEntity:(NSDictionary *)tileEntity atX:(NSInteger)x y:(NSInteger)y z:(NSInteger)z;
- (void) setCell:(MCCell)cell andTileEntity:(NSDictionary *)tileEntity atX:(NSInteger)x y:(NSInteger)y z:(NSInteger)z;

@end



extern NSString * const kJAMinecraftBlockStoreChangedNotification;
extern NSString * const kJAMinecraftBlockStoreChangedExtents;	// userInfo dictionary key whose value is an NSValue containing a MCGridExtents object.


extern NSString * const kJAMinecraftBlockStoreErrorDomain;

enum
{
	kJABlockStoreErrorNoError,
	kJABlockStoreErrorNilData,
	kJABlockStoreErrorWrongFileFormat,
	kJABlockStoreErrorUnknownFormatVersion,
	kJABlockStoreErrorTruncatedData,
	kJABlockStoreErrorEmptyDocument,
	kJABlockStoreErrorDocumentTooLarge,
	kJABlockStoreErrorExtendedBlockIDsNotSupported
};
