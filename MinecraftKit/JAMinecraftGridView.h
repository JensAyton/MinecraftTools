/*
	JAMinecraftGridView.h
	
	Abstract overhead grid view for Minecraft schematic data.
	
	
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

#import <Cocoa/Cocoa.h>
#import "JAMinecraftTypes.h"

@class JAMinecraftSchematic;

typedef void (^JAMCSchematicRenderCB)(JAMinecraftSchematic *schematic, JACellLocation location, NSRect drawingRect);


// FIXME: do something sane about this.
enum
{
	kDragNoAction,
	kDragPan,
	kDragSelect
};


@interface JAMinecraftGridView: NSView
{
@private
	JAMinecraftSchematic	*_schematic;
	
	NSScroller				*_horizontalScroller;
	NSScroller				*_verticalScroller;
	
	NSPoint					_scrollCenter;
	NSUInteger				_currentLayer;
	
	JAMCSchematicRenderCB	_renderCallback;
	
	uint8_t					_dragAction;
	
	JACellLocation			_selectionAnchor;
	JACircuitExtents		_selection;
	NSTimer					*_selectionUpdateTimer;
	
	NSUInteger				_zoomLevel;
	NSInteger				_cellSize;
	NSInteger				_gridWidth;
}

@property (nonatomic) JAMinecraftSchematic *schematic;

// Scroll location, in floating-point cell coordinates.
@property (nonatomic) NSPoint scrollCenter;
@property (nonatomic) NSUInteger currentLayer;

@property (nonatomic) JACircuitExtents selection;

@property (nonatomic) NSUInteger zoomLevel;
@property (nonatomic, readonly) NSUInteger maximumZoomLevel;

// Recentre on middle of document.
- (IBAction) scrollToCenter:(id)sender;


/*
	Convert between grid coordinates and drawing coordinates. When converting
	to drawing space, the y coordinate is ignored (i.e., everything is
	projected onto the drawing plane).
*/
- (JACellLocation) cellLocationFromPoint:(NSPoint)point;
- (JACircuitExtents) extentsFromRect:(NSRect)rect;
- (NSRect) rectFromCellLocation:(JACellLocation)location;
- (NSRect) rectFromExtents:(JACircuitExtents)extents;	// Returns NSZeroRect for empty extents.

// Projection primitives supporting fractional cell-space coordinates.
- (NSPoint) projectToFlattenedCellSpace:(NSPoint)point;
- (NSPoint) projectFromFlattenedCellSpace:(NSPoint)point;


/***** Subclass interface *****/

/*
	Rendering: the render callback is a block called for each cell that needs
	rendering. It may be swapped out at any time.
*/
@property (nonatomic, copy) JAMCSchematicRenderCB renderCallback;

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
	There are two grid colours, one for cells inside the circuit’s extents and
	one for the outside area.
*/
@property (nonatomic, readonly) NSColor *gridColorInDefinedArea;
@property (nonatomic, readonly) NSColor *gridColorOutsideDefinedArea;

/*
	Infinite canvas (default: yes) allows scrolling outside the circuit’s
	extents. Non-infinite mode isn’t fully implemented yet; in particular,
	when the view is resized from larger than the content to smaller, the
	content should be scrolled so no outside area is shown.
*/
@property (nonatomic, readonly) BOOL infiniteCanvas;

@end
