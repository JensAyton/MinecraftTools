/*
	JAMinecraftSchematic.h
	
	The JAMinecraftSchematic class represents an infiniteish three-dimensional
	matrix of cells containing Minecraft blocks. Data is stored in a sparse
	structure where large areas of air take no memory. The extents, width,
	height and depth properties represent the axis-aligned bounding box of all
	non-air blocks.
	
	
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

#import "JAMinecraftTypes.h"

@class JAMinecraftSchematicInnerNode;


@interface JAMinecraftSchematic: NSObject
{
@private
	MCGridExtents					_extents;
	JAMinecraftSchematicInnerNode	*_root;
	MCGridExtents					_dirtyExtents;
	uint32_t						_bulkLevel;
	BOOL							_extentsAreAccurate;
	uint8_t							_levels;
}

@property (readonly) MCGridExtents extents;
@property (readonly) NSUInteger width;
@property (readonly) NSUInteger length;
@property (readonly) NSUInteger height;

/*
	Minimum and maximum layer: highest and lowest y coordinates in which
	blocks may be added without going over 128 blocks high. The schematic may
	use any 128-block high subrange. For an empty schematic, these are
	NSIntegerMin and NSIntegerMax!
*/
@property (readonly) NSInteger minimumLayer;
@property (readonly) NSInteger maximumLayer;

- (MCCell) cellAt:(MCGridCoordinates)location;
- (void) setCell:(MCCell)cell at:(MCGridCoordinates)location;

- (MCCell) cellAtX:(NSInteger)x y:(NSInteger)y z:(NSInteger)z;
- (void) setCell:(MCCell)cell atX:(NSInteger)x y:(NSInteger)y z:(NSInteger)z;

/*
	Bulk updates: while a bulk update is in progress, changes are coalesced into
	a dirty region, which is then posted as a singe notification when bulk
	updating ends.
	Bulk updates can be nested, in which case the notification will be sent
	when the outermost bulk update ends.
*/
- (void) beginBulkUpdate;
- (void) endBulkUpdate;

- (BOOL) bulkUpdateInProgress;

#ifndef NDEBUG
- (NSUInteger) bulkUpdateNestingLevel;
#endif

/*
	TODO: implement an -eraseRegion:(MCGridExtents)region; which empties a
	region, removing nodes where possible.
*/

/*
	Copy blocks from another schematic.
	IMPORTANT: air blocks are ignored, not copied. Erase the target region
	first if you want that behaviour.
*/
- (void) copyRegion:(MCGridExtents)region from:(JAMinecraftSchematic *)sourceCircuit at:(MCGridCoordinates)location;

@end


extern NSString * const kJAMinecraftSchematicChangedNotification;
extern NSString * const kJAMinecraftSchematicChangedExtents;	// userInfo dictionary key whose value is an NSValue containing a MCGridExtents object.


extern NSString * const kJAMinecraftSchematicErrorDomain;

enum
{
	kJACircuitErrorNoError,
	kJACircuitErrorNilData,
	kJACircuitErrorWrongFileFormat,
	kJACircuitErrorUnknownFormatVersion,
	kJACircuitErrorTruncatedData,
	kJACircuitErrorEmptyDocument,
	kJACircuitErrorDocumentTooLarge
};
