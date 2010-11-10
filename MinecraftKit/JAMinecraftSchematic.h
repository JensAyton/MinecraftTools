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
	JACircuitExtents				_extents;
	JAMinecraftSchematicInnerNode	*_root;
	JACircuitExtents				_dirtyExtents;
	uint32_t						_bulkLevel;
	BOOL							_extentsAreAccurate;
	uint8_t							_levels;
}

@property (readonly) JACircuitExtents extents;
@property (readonly) uint16_t width;
@property (readonly) uint16_t height;
@property (readonly) uint16_t depth;

- (JAMinecraftCell) cellAt:(JACellLocation)location;
- (void) setCell:(JAMinecraftCell)cell at:(JACellLocation)location;

- (JAMinecraftCell) cellAtX:(NSInteger)x y:(NSInteger)y z:(NSInteger)z;
- (void) setCell:(JAMinecraftCell)cell atX:(NSInteger)x y:(NSInteger)y z:(NSInteger)z;

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
	TODO: implement an -eraseRegion:(JACircuitExtents)region; which empties a
	region, removing nodes where possible.
*/

/*
	Copy blocks from another circuit.
	IMPORTANT: air blocks are ignored, not copied. Erase the target region
	first if you want that behaviour.
*/
- (void) copyRegion:(JACircuitExtents)region from:(JAMinecraftSchematic *)sourceCircuit at:(JACellLocation)location;

@end


extern NSString * const kJAMinecraftSchematicChangedNotification;
extern NSString * const kJAMinecraftSchematicChangedExtents;	// userInfo dictionary key whose value is an NSValue containing a JACircuitExtents object.


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
