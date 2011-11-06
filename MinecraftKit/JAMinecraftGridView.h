/*
	JAMinecraftGridView.h
	
	Abstract overhead grid view for Minecraft map data.
	
	
	Copyright © 2010–2011 Jens Ayton
	
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

#import <Cocoa/Cocoa.h>
#import "JAMinecraftTypes.h"

@class JAMinecraftBlock, JAMinecraftBlockStore, JAMutableMinecraftBlockStore, JAMinecraftSchematic;

typedef void (^JAMCGridViewRenderCB)(JAMinecraftBlockStore *store, MCCell cell, NSDictionary *tileEntity, MCGridCoordinates location, NSRect drawingRect);


// FIXME: do something sane about this.
enum
{
	kDragNoAction,
	kDragPan,
	kDragSelect
};


@interface JAMinecraftGridView: NSView

@property (nonatomic, assign) JAMutableMinecraftBlockStore <NSCopying> *store;

/*	drawingStore: presents a unified view of the main store and any floating
	content. This may be a JAMinecraftMergedBlockStore, whose contents cannot
	be written.
*/
@property (nonatomic, readonly) JAMinecraftBlockStore *drawingStore;

@property (nonatomic) MCGridExtents selection;

@property (nonatomic) NSInteger currentLayer;
@property (nonatomic) NSUInteger zoomLevel;
@property (nonatomic, readonly) NSUInteger maximumZoomLevel;

/*
	Floating content:
	The floating content is a schematic that is overlaid over the main content.
	It can be used in two ways:
	• Floating selection: in this mode, the selection is synchronized to the
	  extents of the floater. The floating selection can then be moved around
	  without destroying the underlying content.
	• Overlay: in this mode, the float is drawn in preference to the underlying
	  content, with no highlight. This can be used to implement temporary
	  changes such as uncommitted drawing tool feedback.
	
	It is not possible to have a selection and an overlay at the same time. If
	both exist, floating selection mode is in effect.
*/

@property (nonatomic, readonly) BOOL hasFloatingContent;
@property (nonatomic, readonly) BOOL hasFloatingSelection;
@property (nonatomic) MCGridCoordinates floatingContentOffset;
@property (nonatomic, readonly) MCGridExtents floatingContentExtents;

- (void) setFloatingContent:(JAMinecraftSchematic *)floater
				 withOffset:(MCGridCoordinates)offset
				asSelection:(BOOL)asSelection;

- (void) setFloatingContent:(JAMinecraftSchematic *)floater
				 centeredAt:(MCGridCoordinates)center
				asSelection:(BOOL)asSelection;

- (void) makeSelectionFloat;

- (void) freezeFloatingContent;
- (void) discardFloatingContent;


/*
	Convert between grid coordinates and drawing coordinates. When converting
	to drawing space, the y coordinate is ignored (i.e., everything is
	projected onto the drawing plane).
*/
- (MCGridCoordinates) cellLocationFromPoint:(NSPoint)point;
- (MCGridExtents) extentsFromRect:(NSRect)rect;
- (NSRect) rectFromCellLocation:(MCGridCoordinates)location;
- (NSRect) rectFromExtents:(MCGridExtents)extents;	// Returns NSZeroRect for empty extents.

// Projection primitives supporting fractional cell-space coordinates.
- (NSPoint) projectToFlattenedCellSpace:(NSPoint)point;
- (NSPoint) projectFromFlattenedCellSpace:(NSPoint)point;


/***** Subclass interface *****/

/*
	Rendering: the render callback is a block called for each cell that needs
	rendering. It may be swapped out at any time.
	
	Note that the store parameter is the grid view’s “drawing store” (read
	above), which is immutable.
*/
@property (nonatomic, copy) JAMCGridViewRenderCB renderCallback;

/*
	Zooming: zoomable views should override maximumZoomLevel as well as these.
	Subclasses should override -switchToZoomLevel: rather than -setZoomLevel:.
*/
- (void) switchToZoomLevel:(NSUInteger)zoomLevel;
@property (nonatomic, readonly) NSUInteger defaultZoomLevel;

// These metrics are updated when changing zoom level or render callback.
- (NSUInteger) cellSizeForZoomLevel:(NSUInteger)zoomLevel;
- (NSUInteger) gridWidthForZoomLevel:(NSUInteger)zoomLevel;

/*
	There are two grid colours, one for cells inside the store’s extents
	and one for the outside area.
*/
@property (nonatomic, readonly) NSColor *gridColorInDefinedArea;
@property (nonatomic, readonly) NSColor *gridColorOutsideDefinedArea;

/*
	airFillColorOutsideDefinedArea and groundFillColorOutsideDefinedArea are
	used to quickly fill cells outside the store’s extents (above and below
	ground level, respectively).
	
	The default implementations return pattern colors generated by calling
	-drawFillPatternForCellType:inRect: with the appropriate cell type (air
	or smooth stone).
	
	The default implementation of -drawFillPatternForCellType:inRect: in turn
	calls the render callback, with the prototype cell and the coordinates
	{ NSIntegerMin, NSIntegerMin,NSIntegerMin }.
	
	The default behaviour will do the Right Thing if air and stone cells are
	drawn in a location-independent way. If you need to override this behaviour,
	override either the -*FillColor… methods or -drawFillPattern….
*/
@property (nonatomic, readonly) NSColor *airFillColorOutsideDefinedArea;
@property (nonatomic, readonly) NSColor *groundFillColorOutsideDefinedArea;

- (void) drawFillPatternForCellType:(MCCell)cell inRect:(NSRect)rect;

/*
	Force an update of various cached drawing state. Currently, this means the
	cell and grid metrics and the fill colours defined above.
	
	This is implicitly called when changing the zoom level, visible layer or
	render callback.
*/
- (void) invalidateDrawingCaches;

/*
	Infinite canvas (default: yes) allows scrolling outside the store’s
	extents. Non-infinite mode isn’t fully implemented yet; in particular,
	when the view is resized from larger than the content to smaller, the
	content should be scrolled so no outside area is shown.
*/
@property (nonatomic, readonly) BOOL infiniteCanvas;

/*
	Cell tool tips: if hasCellToolTips (default: false), the MincraftGridView
	registers for dynamic tool tips and abstracts request locations into cells.
*/
@property (nonatomic, readonly) BOOL hasCellToolTips;

- (NSString *) stringForToolTipForBlock:(JAMinecraftBlock *)block
									 at:(MCGridCoordinates)location;

@end


extern NSString * const kJAMinecraftGridViewWillFreezeSelectionNotification;
extern NSString * const kJAMinecraftGridViewWillDiscardSelectionNotification;
