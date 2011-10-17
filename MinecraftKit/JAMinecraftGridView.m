/*
	JAMinecraftGridView.m
	
	
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

#import "JAMinecraftGridView.h"
#import "JAMinecraftBlockStore.h"
#import "JAMinecraftSchematic.h"
#import "JAMinecraftMergedBlockStore.h"
#import "IsKeyDown.h"
#import "JAMinecraftKitLionInterfaces.h"


#define kSelectionRefreshInterval	0.1	// Selection animation interval in seconds
#define kSelectionDashLength		8.0
#define kSelectionDashSpeed			(2.0 * kSelectionDashLength)

#define DEBUG_DRAWING				0

// USE_BACKGROUND_CACHE: use pattern colours to draw out-of-bounds cells rather than calling the render callback.
#define USE_BACKGROUND_CACHE		1


NSString * const kJAMinecraftGridViewWillFreezeSelectionNotification = @"se.ayton.jens JAMinecraftGridView will freeze selection";
NSString * const kJAMinecraftGridViewWillDiscardSelectionNotification = @"se.ayton.jens JAMinecraftGridView will discard selection";


@interface JAMinecraftGridView ()

// Drawing
- (void) drawBasicsAndClipToDirtyRect:(NSRect)dirtyRect;
- (void) drawCellsInRect:(NSRect)rect;
- (void) drawSelectionInDirtyRect:(NSRect)dirtyRect;
#if DEBUG_DRAWING
- (void) drawDebugStuffInDirtyRect:(NSRect)dirtyRect;
#endif

@property (readonly, nonatomic) NSColor *emptyOutsidePattern;

- (void) setNeedsDisplayInExtents:(MCGridExtents)extents;

// Selection
- (BOOL) hasVisibleSelection;
- (BOOL) isFocusedForSelection;
- (void) setNeedsDisplayInSelectionRect;	// Full selection area
- (void) setNeedsDisplayInSelectionFrame;	// Outline only
- (void) updateSelectionForPoint:(NSPoint)pointInWindow;

@property (readonly, nonatomic) NSRect selectionBounds;

- (void) updateSelectionTimer;

// Scrolling
- (void) updateScrollers;

- (void) scrollContentOriginTo:(NSPoint)point;

- (IBAction) horizontalScrollAction:(id)sender;
- (IBAction) verticalScrollAction:(id)sender;

- (void)scrollPageLeft:(id)sender;
- (void)scrollPageRight:(id)sender;
- (void)scrollColumnLeft:(id)sender;
- (void)scrollColumnRight:(id)sender;

// Zooming
- (void) performSwitchZoomLevel;


/*	Update ongoing drag action, optionally using a mouse event for location
	information. For example, this is called when changing display layer.
*/
- (void) updateDrag:(NSEvent *)event;

@end


@interface JAMinecraftGridView (Geometry)

@property (readonly, nonatomic) NSRect horizontalScrollerFrame;
@property (readonly, nonatomic) NSRect verticalScrollerFrame;
@property (readonly, nonatomic) NSRect scrollerCornerFrame;
@property (readonly, nonatomic) NSRect innerFrame;
@property (readonly, nonatomic) NSRect nonEmptyContentFrame;
@property (readonly, nonatomic) NSRect virtualBounds;

// 3D cell location with proper rounding of grid lines.
- (MCGridCoordinates) cellLocationForPointInWindow:(NSPoint)pointInWindow;

@end


@implementation JAMinecraftGridView
{
	JAMutableMinecraftBlockStore <NSCopying>	*_store;
	
	NSScroller						*_horizontalScroller;
	NSScroller						*_verticalScroller;
	
	NSPoint							_scrollCenter;
	NSInteger						_currentLayer;
	
	JAMCGridViewRenderCB			_renderCallback;
	
	uint8_t							_dragAction;
	
	MCGridCoordinates				_selectionAnchor;
	MCGridExtents					_selection;
	NSTimer							*_selectionUpdateTimer;
	
	NSUInteger						_zoomLevel;
	NSInteger						_cellSize;
	NSInteger						_gridWidth;
	
	JAMinecraftSchematic			*_floatContent;
	MCGridCoordinates				_floatOffset;
	MCGridExtents					_floatExtents;
	BOOL							_floatIsSelection;
	
	NSColor							*_emptyOutsidePattern;
}

- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		_horizontalScroller = [[NSScroller alloc] initWithFrame:self.horizontalScrollerFrame];
		_horizontalScroller.action = @selector(horizontalScrollAction:);
		_horizontalScroller.target = self;
		[self addSubview:_horizontalScroller];
		
		_verticalScroller = [[NSScroller alloc] initWithFrame:self.verticalScrollerFrame];
		_verticalScroller.action = @selector(verticalScrollAction:);
		_verticalScroller.target = self;
		[self addSubview:_verticalScroller];
		
		_selection = kMCEmptyExtents;
		
		_zoomLevel = self.defaultZoomLevel;
		[self performSwitchZoomLevel];
		
		// Set trivial basic render callback.
		self.renderCallback = ^(JAMinecraftBlockStore *store, MCCell cell, NSDictionary *tileEntity, MCGridCoordinates location, NSRect drawingRect)
		{
			if (cell.blockID == kMCBlockAir)  [[NSColor whiteColor] set];
			else  [[NSColor blueColor] set];
			[NSBezierPath fillRect:drawingRect];
		};
	}
	
	return self;
}


+ (BOOL) accessInstanceVariablesDirectly
{
	return NO;
}


#pragma mark Basic property accessors

- (NSInteger) currentLayer
{
	return _currentLayer;
}


- (void) setCurrentLayer:(NSInteger)value
{
	if (_currentLayer != value)
	{
		_currentLayer = value;
		[self invalidateDrawingCaches];
		
		[self setNeedsDisplay:YES];
		
		[self updateDrag:nil];
	}
}


- (JAMutableMinecraftBlockStore *) store
{
	return _store;
}


- (void) setStore:(JAMutableMinecraftBlockStore <NSCopying> *)store
{
	if (store != _store)
	{
		NSNotificationCenter *nctr = [NSNotificationCenter defaultCenter];
		[nctr removeObserver:self name:nil object:_store];
		[_store removeObserver:self forKeyPath:@"groundLevel"];
		[_store removeObserver:self forKeyPath:@"extents"];
		
		[nctr addObserver:self selector:@selector(blockStoreChanged:) name:kJAMinecraftBlockStoreChangedNotification object:store];
		[store addObserver:self forKeyPath:@"groundLevel" options:0 context:NULL];
		[store addObserver:self forKeyPath:@"extents" options:0 context:NULL];
		
		_store = store;
		
		[self setNeedsDisplay:YES];
	}
}


- (JAMinecraftBlockStore *) drawingStore
{
	if (_floatContent == nil)  return _store;
	else return [[JAMinecraftMergedBlockStore alloc] initWithMainStore:_store overlay:_floatContent offset:_floatOffset];
}


+ (NSSet *) keyPathsForValuesAffectingDrawingStore
{
	return [NSSet setWithObjects:@"store", @"hasFloatingContent", @"floatingContentOffset", nil];
}


- (void) blockStoreChanged:(NSNotification *)notification
{
	NSValue *extentsVal = [notification.userInfo objectForKey:kJAMinecraftBlockStoreChangedExtents];
	MCGridExtents extents;
	[extentsVal getValue:&extents];
	
	[self setNeedsDisplayInRect:[self rectFromExtents:extents]];
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == _store)
	{
		if ([keyPath isEqualToString:@"groundLevel"])  [self invalidateDrawingCaches];
		[self setNeedsDisplay:YES];
	}
}


- (NSPoint) scrollCenter
{
	return _scrollCenter;
}


- (void) setScrollCenter:(NSPoint)value
{
	if (!NSEqualPoints(_scrollCenter, value))
	{
		_scrollCenter = value;
		[self setNeedsDisplay:YES];
		[self updateScrollers];
	}
}


- (MCGridCoordinates) scrollCenterCoordinates
{
	return (MCGridCoordinates){ round(_scrollCenter.y), _currentLayer, round(_scrollCenter.x) };
}


- (void) setScrollCenterCoordinates:(MCGridCoordinates)value
{
	self.scrollCenter = (NSPoint){ value.z, value.x };
	self.currentLayer = value.y;
}


+ (NSSet *) keyPathsForValuesAffectingScrollCenterCoordinates
{
	return [NSSet setWithObjects:@"scrollCenter", @"currentLayer", nil];
}


- (MCGridExtents) selection
{
	return _selection;
}


- (void) setSelection:(MCGridExtents)value
{
	if (!MCGridExtentsEqual(value, _selection))
	{
		if (_floatContent != nil)
		{
			[self freezeFloatingContent]; 
		}
		
		_selection = value;
		[self updateSelectionTimer];
		[self setNeedsDisplay:YES];
	}
}


- (JAMCGridViewRenderCB) renderCallback
{
	return _renderCallback;
}


- (void) setRenderCallback:(JAMCGridViewRenderCB)value
{
	if (value != _renderCallback)
	{
		_renderCallback = [value copy];
		[self performSwitchZoomLevel];
	}
}


- (NSColor *) gridColorInDefinedArea
{
	return [NSColor darkGrayColor];
}


- (NSColor *) gridColorOutsideDefinedArea
{
	return [NSColor lightGrayColor];
}


- (void) drawFillPatternForCellType:(MCCell)cell inRect:(NSRect)rect
{
	_renderCallback(self.store, cell, nil, (MCGridCoordinates){ NSIntegerMin, NSIntegerMin, NSIntegerMin }, rect);
}


- (NSColor *) defaultFillColorForCellType:(MCCell)cell
{
	NSRect patternRect = (NSRect){{ 0, 0 }, { _cellSize, _cellSize }};
	NSImage *patternImage = [[NSImage alloc] initWithSize:patternRect.size];
	
	[patternImage lockFocus];
	[self drawFillPatternForCellType:cell inRect:patternRect];
	[patternImage unlockFocus];
	
	return [NSColor colorWithPatternImage:patternImage];
}


- (NSColor *) airFillColorOutsideDefinedArea
{
	return [self defaultFillColorForCellType:kMCAirCell];
}


- (NSColor *) groundFillColorOutsideDefinedArea
{
	return [self defaultFillColorForCellType:kMCStoneCell];
}


- (BOOL) infiniteCanvas
{
	return YES;
}


#pragma mark Floating content

- (BOOL) hasFloatingContent
{
	return _floatContent != nil;
}


- (BOOL) hasFloatingSelection
{
	return self.hasFloatingContent && !MCGridExtentsEmpty(self.selection);
}


- (MCGridCoordinates) floatingContentOffset
{
	if (self.hasFloatingContent)
	{
		return _floatOffset;
	}
	else
	{
		return kMCZeroCoordinates;
	}
}


- (void) setFloatingContentOffset:(MCGridCoordinates)value
{
	if (self.hasFloatingContent && !MCGridCoordinatesEqual(value, _floatOffset))
	{
		MCGridExtents oldFloatExtents = _floatExtents;
		MCGridExtents newFloatExtents = MCGridExtentsOffset(_floatContent.extents, value.x, value.y, value.z);
		MCGridExtents totalExtentsBefore = MCGridExtentsUnion(self.store.extents, oldFloatExtents);
		MCGridExtents totalExtentsAfter = MCGridExtentsUnion(self.store.extents, newFloatExtents);
		BOOL willChangeExtents = !MCGridExtentsEqual(totalExtentsBefore, totalExtentsAfter);
		
		if (willChangeExtents)  [self willChangeValueForKey:@"extents"];
		[self willChangeValueForKey:@"floatingContentOffset"];
		
		_floatOffset = value;
		_floatExtents = newFloatExtents;
		
		if (_floatIsSelection)
		{
			// Direct access to avoid dropping floater.
			[self willChangeValueForKey:@"selection"];
			_selection = newFloatExtents;
			[self didChangeValueForKey:@"selection"];
		}
		
		[self didChangeValueForKey:@"floatingContentOffset"];
		if (willChangeExtents)
		{
			[self didChangeValueForKey:@"extents"];
			[self setNeedsDisplay:YES];
		}
		else
		{
			[self setNeedsDisplayInExtents:oldFloatExtents];
			[self setNeedsDisplayInExtents:newFloatExtents];
		}
	}
}

- (MCGridExtents) floatingContentExtents
{
	if (self.hasFloatingContent)
	{
		return _floatExtents;
	}
	else
	{
		return kMCEmptyExtents;
	}
}


+ (NSSet *) keyPathsForValuesAffectingFloatingContentExtents
{
	return [NSSet setWithObject:@"floatingContentOffset"];
}


- (void) setFloatingContent:(JAMinecraftSchematic *)floater
				 withOffset:(MCGridCoordinates)offset
				asSelection:(BOOL)asSelection
{
	if (floater == nil)  return;
	
	if (_floatContent != nil) [self freezeFloatingContent];
	if (!asSelection)  self.selection = kMCEmptyExtents;
	
	[self willChangeValueForKey:@"hasFloatingContent"];
	
	_floatContent = floater;
	_floatIsSelection = asSelection;
	self.floatingContentOffset = offset;
	
	[self didChangeValueForKey:@"hasFloatingContent"];
}

- (void) setFloatingContent:(JAMinecraftSchematic *)floater
				 centeredAt:(MCGridCoordinates)center
				asSelection:(BOOL)asSelection
{
	MCGridExtents floaterExtents = (floater != nil) ? floater.extents : kMCZeroExtents;
	if (MCGridExtentsEmpty(floaterExtents))  floaterExtents = kMCZeroExtents;
	
	center.x -= MCGridExtentsWidth(floaterExtents);
	center.y -= MCGridExtentsHeight(floaterExtents);
	center.z -= MCGridExtentsLength(floaterExtents);
	
	[self setFloatingContent:floater withOffset:center asSelection:asSelection];
}


- (void) makeSelectionFloat
{
	MCGridExtents selection = self.selection;
	if (MCGridExtentsEmpty(selection) || _floatContent != nil /* already have floating selection */)  return;
	
	JAMinecraftSchematic *floater = [[JAMinecraftSchematic alloc] initWithRegion:selection ofStore:self.store];
	[self.store fillRegion:selection withCell:kMCAirCell];
	
	[self setFloatingContent:floater withOffset:kMCZeroCoordinates asSelection:YES];
}


- (void) priv_dropFloatingContent
{
	[self willChangeValueForKey:@"hasFloatingContent"];
	[self willChangeValueForKey:@"hasFloatingSelection"];
	[self willChangeValueForKey:@"floatingContentOffset"];
	
	_floatContent = nil;
	[self setNeedsDisplayInExtents:_floatExtents];
	
	[self didChangeValueForKey:@"floatingContentOffset"];
	[self didChangeValueForKey:@"hasFloatingSelection"];
	[self didChangeValueForKey:@"hasFloatingContent"];
}


- (void) freezeFloatingContent
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kJAMinecraftGridViewWillFreezeSelectionNotification object:self];
	
	MCGridExtents region = _floatContent.extents;
	MCGridCoordinates target = _floatOffset;
	target.x += region.minX;
	target.y += region.minY;
	target.z += region.minZ;
	[self.store copyRegion:region from:_floatContent at:target];
	
	[self priv_dropFloatingContent];
}


- (void) discardFloatingContent
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kJAMinecraftGridViewWillDiscardSelectionNotification object:self];
	[self priv_dropFloatingContent];
}


#pragma mark Drawing

- (BOOL) isOpaque
{
	return YES;
}


- (void) drawRect:(NSRect)dirtyRect
{
#if DEBUG_DRAWING
	NSRect originalDirtyRect = dirtyRect;
#endif
	[self drawBasicsAndClipToDirtyRect:dirtyRect];
	
	/*
		Draw cells in updated region only.
		This could potentially lead to overdrawing, but saves a lot of drawing
		when updating selection feedback. Using an appropriate set
		representation of updated cells (e.g., a bitmap) would be better, but
		simple approaches like an NSSet of NSValues containing cell locations
		turns out to be much slower.
	*/
	const NSRect *drawingRects;
	NSInteger i, count;
	[self getRectsBeingDrawn:&drawingRects count:&count];
	for (i = 0; i < count; i++)
	{
		[self drawCellsInRect:drawingRects[i]];
	}
	
	// Draw selection if relevant.
	[self drawSelectionInDirtyRect:dirtyRect];
	
#if DEBUG_DRAWING
	[self drawDebugStuffInDirtyRect:originalDirtyRect];
#endif
}


- (NSColor *) buildCellPatternWithFillColor:(NSColor *)fillColor gridColor:(NSColor *)gridColor
{
	NSSize patternSize = { _cellSize + _gridWidth, _cellSize + _gridWidth };
	
	NSImage *patternImage = [[NSImage alloc] initWithSize:patternSize];
	[patternImage lockFocus];
	
	[gridColor set];
	NSRect fullRect = (NSRect){{ 0, 0 }, patternSize };
	[NSBezierPath fillRect:fullRect];
	
	[fillColor set];
	NSRect innerRect = (NSRect){{ 0, 0 }, { _cellSize, _cellSize }};
	[NSBezierPath fillRect:innerRect];
	
	[patternImage unlockFocus];
	return [NSColor colorWithPatternImage:patternImage];
}


- (NSColor *) emptyOutsidePattern
{
	if (_emptyOutsidePattern == nil)
	{
		NSColor *fillColor = nil;
		if (self.currentLayer >= self.store.groundLevel)  fillColor = self.airFillColorOutsideDefinedArea;
		else  fillColor = self.groundFillColorOutsideDefinedArea;
		
		_emptyOutsidePattern = [self buildCellPatternWithFillColor:fillColor gridColor:self.gridColorOutsideDefinedArea];
	}
	
	return _emptyOutsidePattern;
}


- (void) drawBasicsAndClipToDirtyRect:(NSRect)dirtyRect
{
	/*	Fill background with grid colour; we will then overdraw this with cells.
		This also fills the area behind the scroll bars, fulfilling our claim
		to be opaque without relying on the NSScrollers being opaque.
	*/
	
#if USE_BACKGROUND_CACHE
	[self.emptyOutsidePattern set];
	NSPoint phase = [self rectFromCellLocation:kMCZeroCoordinates].origin;
	phase.x += self.frame.origin.x;
	phase.y += self.frame.origin.y;
	
	[NSGraphicsContext currentContext].patternPhase = phase;
#else
	[self.gridColorOutsideDefinedArea set];
#endif
	
	[NSBezierPath fillRect:dirtyRect];
	
	// Fill in corner between scroll bars.
	NSRect cornerFrame = self.scrollerCornerFrame;
	if (NSIntersectsRect(dirtyRect, cornerFrame))
	{
		[[NSColor whiteColor] set];
		[NSBezierPath fillRect:cornerFrame];
	}
	
	// Exclude scroll bar area from consideration.
	dirtyRect = NSIntersectionRect(dirtyRect, self.innerFrame);
	[NSBezierPath clipRect:dirtyRect];
	
	// Draw inner grid (i.e., grid for area that has non-empty blocks).
	NSRect nonEmptyFrame = self.nonEmptyContentFrame;
	if (NSIntersectsRect(dirtyRect, nonEmptyFrame))
	{
		[self.gridColorInDefinedArea set];
		[NSBezierPath fillRect:nonEmptyFrame];
	}
}


- (void) drawCellsInRect:(NSRect)rect
{
	if (JA_EXPECT_NOT(_renderCallback == NULL))  return;
	
	JAMinecraftBlockStore *store = self.drawingStore;
	MCGridExtents targetExtents = [self extentsFromRect:rect];
#if USE_BACKGROUND_CACHE
	targetExtents = MCGridExtentsIntersection(targetExtents, store.extents);
#endif
	
	MCGridCoordinates coords = { .y = self.currentLayer };
	NSGraphicsContext *gCtxt = [NSGraphicsContext currentContext];
	
	// Iterate over the cells.
	for (coords.z = targetExtents.minZ; coords.z <= targetExtents.maxZ; coords.z++)
	{
		for (coords.x = targetExtents.minX; coords.x <= targetExtents.maxX; coords.x++)
		{
			NSRect cellRect = [self rectFromCellLocation:coords];
			NSDictionary *tileEntity = nil;
			MCCell cell = [store cellAt:coords gettingTileEntity:&tileEntity];
			
			[gCtxt saveGraphicsState];
			[NSBezierPath clipRect:cellRect];
			_renderCallback(store, cell, tileEntity, coords, cellRect);
			[gCtxt restoreGraphicsState];
		}
	}
}


- (void) drawSelectionInDirtyRect:(NSRect)dirtyRect
{
	if ([self hasVisibleSelection])
	{
		NSRect selectionBounds = self.selectionBounds;
		if (NSIntersectsRect(dirtyRect, selectionBounds))
		{
			NSBezierPath *selectionPath = [NSBezierPath bezierPath];
			selectionPath.lineWidth = _gridWidth;
			[selectionPath appendBezierPathWithRect:NSInsetRect(selectionBounds, -0.5 * _gridWidth, -0.5 * _gridWidth)];
			NSColor *selectionColor = nil;
			if ([self isFocusedForSelection])
			{
				selectionColor = [NSColor selectedTextBackgroundColor];
				CGFloat pattern[2] = { kSelectionDashLength, kSelectionDashLength };
				CGFloat phase = fmod([NSDate timeIntervalSinceReferenceDate] * kSelectionDashSpeed, kSelectionDashLength * 2.0);
				[selectionPath setLineDash:pattern count:2 phase:phase];
			}
			else selectionColor = [NSColor lightGrayColor];
			
			[[selectionColor colorWithAlphaComponent:0.25] set];
			[NSBezierPath fillRect:selectionBounds];
			[[selectionColor colorWithAlphaComponent:0.8] set];
			[selectionPath stroke];
		}
	}
}


#if DEBUG_DRAWING
- (void) drawDebugStuffInDirtyRect:(NSRect)dirtyRect
{
	// Draw blue cross at origin. The offset is to get on the top side of the cell.
	NSPoint pt = [self rectFromCellLocation:kMCZeroCoordinates].origin;
	pt.x += (_cellSize + _gridWidth) - 0.5 * _gridWidth;
	pt.y += (_cellSize + _gridWidth) - 0.5 * _gridWidth;
	NSBezierPath *path = [NSBezierPath new];
	path.lineWidth = 3;
	[[NSColor blueColor] set];
	[path moveToPoint:(NSPoint){ pt.x - 10, pt.y }];
	[path lineToPoint:(NSPoint){ pt.x + 10, pt.y }];
	[path moveToPoint:(NSPoint){ pt.x, pt.y - 10 }];
	[path lineToPoint:(NSPoint){ pt.x, pt.y + 10 }];
	[path stroke];
	
	// Draw green cross at scrollCenter.
	pt = [self projectFromFlattenedCellSpace:self.scrollCenter];
	pt.x -= 0.5 * _gridWidth;
	pt.y += (_cellSize + _gridWidth) - 0.5 * _gridWidth;
	[path removeAllPoints];
	[[NSColor greenColor] set];
	[path moveToPoint:(NSPoint){ pt.x - 8, pt.y }];
	[path lineToPoint:(NSPoint){ pt.x + 8, pt.y }];
	[path moveToPoint:(NSPoint){ pt.x, pt.y - 8 }];
	[path lineToPoint:(NSPoint){ pt.x, pt.y + 8 }];
	[path stroke];
	
	// Frame individual dirty rects in yellow.
	[[NSColor orangeColor] set];
	const NSRect *drawingRects;
	NSInteger i, count;
	[self getRectsBeingDrawn:&drawingRects count:&count];
	for (i = 0; i < count; i++)
	{
		[NSBezierPath strokeRect:drawingRects[i]];
	}
	
	// Frame dirty area in red.
	[[NSColor redColor] set];
	[NSBezierPath strokeRect:dirtyRect];
}
#endif


- (void) setNeedsDisplayInExtents:(MCGridExtents)extents
{
	[self setNeedsDisplayInRect:NSInsetRect([self rectFromExtents:extents], -_gridWidth, -_gridWidth)];
}


#pragma mark NSResponder

- (BOOL)acceptsFirstResponder
{
	return YES;
}


- (BOOL) becomeFirstResponder
{
	[self setNeedsDisplayInSelectionRect];
	[self updateSelectionTimer];
	return YES;
}


- (BOOL) resignFirstResponder
{
	[self setNeedsDisplayInSelectionRect];
	[self updateSelectionTimer];
	return YES;
}


// FIXME: let subclass influence click/drag behaviour.
- (void) mouseDown:(NSEvent *)event
{
	NSUInteger modifiers = event.modifierFlags & NSDeviceIndependentModifierFlagsMask;
	
	if (modifiers & NSControlKeyMask)
	{
		[super mouseDown:event];	// Pass through for contextual menu handling
		return;
	}
	
	if (IsKeyDown(kVK_Space))
	{
		// Regardless of tool (FIXME: implement tools), space-dragging pans the view.
		_dragAction = kDragPan;
		[[NSCursor closedHandCursor] push];
	}
	else if ((modifiers & NSDeviceIndependentModifierFlagsMask) == 0)
	{
		_dragAction = kDragSelect;
		_selectionAnchor = [self cellLocationForPointInWindow:event.locationInWindow];
		if (self.hasFloatingSelection)  [self freezeFloatingContent];
		self.selection = kMCEmptyExtents;
		[self updateSelectionTimer];
	}
	else
	{
		// Default behaviour: nothing.
		_dragAction = kDragNoAction;
	}
}


- (void) mouseUp:(NSEvent *)event
{
	switch (_dragAction)
	{
		case kDragPan:
			[NSCursor pop];
			break;
	}
	
	_dragAction = kDragNoAction;
}


- (void) updateDrag:(NSEvent *)event
{
	NSPoint location;
	if (event != nil)  location = event.locationInWindow;
	else  location = [self.window convertScreenToBase:[NSEvent mouseLocation]];
	
	switch (_dragAction)
	{
		case kDragSelect:
			[self updateSelectionForPoint:location];
			break;
	}
}


- (void) mouseDragged:(NSEvent *)event
{
	switch (_dragAction)
	{
		case kDragPan:
		{
			NSRect contentFrame = self.innerFrame;
			contentFrame.origin.x -= event.deltaX;
			contentFrame.origin.y += event.deltaY;
			[self scrollContentOriginTo:contentFrame.origin];
			break;
		}
	}
	[self updateDrag:event];
}


- (void) keyDown:(NSEvent *)event
{
	switch (event.keyCode)
	{
		case kVK_Space:
			// Squelch to avoid beeping, as we use the space bar as a modifier.
			// FIXME: should show open hand cursor.
			break;
			
		case kVK_PageUp:
			self.currentLayer++;
			break;
			
		case kVK_PageDown:
			self.currentLayer--;
			break;
			
		case kVK_Home:
			[self scrollToCenter:nil];
			break;
			
		case kVK_LeftArrow:
			[self scrollColumnLeft:nil];
			break;
			
		case kVK_RightArrow:
			[self scrollColumnRight:nil];
			break;
			
		case kVK_UpArrow:
			[self scrollLineUp:nil];
			break;
			
		case kVK_DownArrow:
			[self scrollLineDown:nil];
			break;
			
		default:
			[super keyDown:event];
	}
}


#pragma mark Misc view logic stuff

- (void) viewWillMoveToWindow:(NSWindow *)newWindow
{
	if (newWindow == nil)
	{
		/*	AppKit calls -viewWillMoveToWindow:nil after the view has been
			finalized. Attempting to clean up notifications will lead to a
			ressurection warning in the run log.
			rdar://8658769
			
			I believe the only downside to ignoring this will be unnecessary
			redrawing if the view is removed from its window, then inserted
			in a different window, and used while the original window is still
			around. -- Ahruman 2010-11-11
		*/
		return;
	}
	
	NSNotificationCenter *nctr = [NSNotificationCenter defaultCenter];
	[nctr removeObserver:self name:nil object:self.window];
	
	[nctr addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:newWindow];
	[nctr addObserver:self selector:@selector(windowDidResignKey:) name:NSWindowDidResignKeyNotification object:newWindow];
}


- (void) windowDidBecomeKey:(NSNotification *)notification
{
	[self setNeedsDisplayInSelectionRect];
	[self updateSelectionTimer];
}


- (void) windowDidResignKey:(NSNotification *)notification
{
	[self setNeedsDisplayInSelectionRect];
	[self updateSelectionTimer];
}


- (void) resizeSubviewsWithOldSize:(NSSize)oldSize
{
	[self updateScrollers];
	[super resizeSubviewsWithOldSize:oldSize];
}


#pragma mark Selection

- (void) updateSelectionForPoint:(NSPoint)pointInWindow
{
	MCGridCoordinates loc = [self cellLocationForPointInWindow:pointInWindow];
	
	MCGridExtents newSelection =
	{
		MIN(loc.x, _selectionAnchor.x), MAX(loc.x, _selectionAnchor.x),
		MIN(loc.y, _selectionAnchor.y), MAX(loc.y, _selectionAnchor.y),
		MIN(loc.z, _selectionAnchor.z), MAX(loc.z, _selectionAnchor.z),
	};
	
	self.selection = newSelection;
	[self updateSelectionTimer];
}


- (BOOL) hasVisibleSelection
{
	MCGridExtents selection = self.selection;
	NSInteger currentLayer = self.currentLayer;
	
	return !MCGridExtentsEmpty(selection) && selection.minY <= currentLayer && currentLayer <= selection.maxY;
}


- (BOOL) isFocusedForSelection
{
	return self.window.firstResponder == self && self.window.isKeyWindow;
}


- (NSRect) selectionBounds
{
	return [self rectFromExtents:self.selection];
}


- (void) setNeedsDisplayInSelectionRect
{
	if ([self hasVisibleSelection])
	{
		NSRect selectionBounds = [self selectionBounds];
		selectionBounds = NSInsetRect(selectionBounds, -0.5 * _gridWidth, -0.5 * _gridWidth);
		selectionBounds = NSOffsetRect(selectionBounds, -0.5 * _gridWidth, -0.5 * _gridWidth);
		[self setNeedsDisplayInRect:selectionBounds];
	}
}


- (void) setNeedsDisplayInSelectionFrame
{
	if ([self hasVisibleSelection])
	{
		NSRect innerFrame = self.innerFrame;
		NSRect selectionBounds = [self selectionBounds];
		selectionBounds = NSInsetRect(selectionBounds, -_gridWidth, -_gridWidth);
		
		NSRect partial = { selectionBounds.origin, { _gridWidth, selectionBounds.size.height }};
		[self setNeedsDisplayInRect:NSIntersectionRect(partial, innerFrame)];
		partial.origin.x += selectionBounds.size.width - _gridWidth;
		[self setNeedsDisplayInRect:NSIntersectionRect(partial, innerFrame)];
		
		partial = (NSRect){ selectionBounds.origin, { selectionBounds.size.width, _gridWidth }};
		[self setNeedsDisplayInRect:NSIntersectionRect(partial, innerFrame)];
		partial.origin.y += selectionBounds.size.height - _gridWidth;
		[self setNeedsDisplayInRect:NSIntersectionRect(partial, innerFrame)];
	}
}


- (void) updateSelectionTimer
{
	if ([self hasVisibleSelection] && [self isFocusedForSelection])
	{
		if (_selectionUpdateTimer == nil)
		{
			_selectionUpdateTimer = [NSTimer timerWithTimeInterval:kSelectionRefreshInterval
															target:self
														  selector:@selector(setNeedsDisplayInSelectionFrame)
														  userInfo:nil
														   repeats:YES];
			[[NSRunLoop currentRunLoop] addTimer:_selectionUpdateTimer forMode:NSRunLoopCommonModes];
			
			/*
				NOTE: the timer is invalidated when the window is closed, in
				response to the window resigning key status.
			*/
		}
	}
	else
	{
		if (_selectionUpdateTimer != nil)
		{
			[_selectionUpdateTimer invalidate];
			_selectionUpdateTimer = nil;
		}
	}
}


#pragma mark Scrolling

- (IBAction) scrollToCenter:(id)sender
{
	MCGridExtents extents = self.store.extents;
	if (!MCGridExtentsEmpty(extents))
	{
		self.scrollCenter = (NSPoint)
		{
			extents.minZ + (extents.maxZ - extents.minZ - 1) * 0.5,
			extents.minX + (extents.maxX - extents.minX + 1) * 0.5
		};
	}
	else
	{
		self.scrollCenter = NSZeroPoint;
	}
	[self updateScrollers];
}


- (void) scrollContentOriginTo:(NSPoint)point
{
	// Convert scroll position from content frame origin change to scroll center change.
	
	NSRect contentFrame = self.innerFrame;
	NSRect virtualBounds = self.virtualBounds;
	NSPoint scrollCenter = self.scrollCenter;
	
	point.x = MAX(point.x, virtualBounds.origin.x);
	point.y = MAX(point.y, virtualBounds.origin.y);
	
	point.x = MIN(point.x, NSMaxX(virtualBounds) - contentFrame.size.width);
	point.y = MIN(point.y, NSMaxY(virtualBounds) - contentFrame.size.height);
	
	CGFloat deltaX = contentFrame.origin.x - point.x;
	CGFloat deltaY = contentFrame.origin.y - point.y;
	
	scrollCenter.x += deltaX / (_cellSize + _gridWidth);
	scrollCenter.y += deltaY / (_cellSize + _gridWidth);
	
	self.scrollCenter = scrollCenter;
}


- (void) updateScrollers
{
	_horizontalScroller.frame = self.horizontalScrollerFrame;
	_verticalScroller.frame = self.verticalScrollerFrame;
	
	NSRect contentFrame = self.innerFrame;
	NSRect virtualBounds = self.virtualBounds;
	
	BOOL enabled = !MCGridExtentsEmpty(self.store.extents);
	if (enabled)
	{
		[_horizontalScroller setEnabled:contentFrame.size.width < virtualBounds.size.width];
		_horizontalScroller.doubleValue = (contentFrame.origin.x - virtualBounds.origin.x) / (virtualBounds.size.width - contentFrame.size.width);
		_horizontalScroller.knobProportion = contentFrame.size.width / virtualBounds.size.width;
		
		[_verticalScroller setEnabled:contentFrame.size.height < virtualBounds.size.height];
		_verticalScroller.doubleValue = 1.0 - (contentFrame.origin.y - virtualBounds.origin.y) / (virtualBounds.size.height - contentFrame.size.height);
		_verticalScroller.knobProportion = contentFrame.size.height / virtualBounds.size.height;
	}
	else
	{
		[_horizontalScroller setEnabled:NO];
		[_verticalScroller setEnabled:NO];
	}

	
	[self updateSelectionTimer];
}


- (IBAction) horizontalScrollAction:(id)sender
{
	switch ([sender hitPart])
	{
		case NSScrollerDecrementPage:
			[self scrollPageLeft:sender];
			break;
			
		case NSScrollerIncrementPage:
			[self scrollPageRight:sender];
			break;
			
		case NSScrollerDecrementLine:
			[self scrollColumnLeft:sender];
			break;
			
		case NSScrollerIncrementLine:
			[self scrollColumnRight:sender];
			break;
			
		case NSScrollerKnob:
		case NSScrollerKnobSlot:
		{
			NSRect contentFrame = self.innerFrame;
			CGFloat proportion = [sender doubleValue];
			NSRect virtualBounds = self.virtualBounds;
			
			contentFrame.origin.x = proportion * (virtualBounds.size.width - contentFrame.size.width) + virtualBounds.origin.x;
			[self scrollContentOriginTo:contentFrame.origin];
			break;
		}
	}
}


- (IBAction) verticalScrollAction:(id)sender
{
	switch ([sender hitPart])
	{
		case NSScrollerDecrementPage:
			[self scrollPageUp:sender];
			break;
			
		case NSScrollerIncrementPage:
			[self scrollPageDown:sender];
			break;
			
		case NSScrollerDecrementLine:
			[self scrollLineUp:sender];
			break;
			
		case NSScrollerIncrementLine:
			[self scrollLineDown:sender];
			break;
			
		case NSScrollerKnob:
		case NSScrollerKnobSlot:
		{
			NSRect contentFrame = self.innerFrame;
			CGFloat proportion = 1.0 - [sender doubleValue];
			NSRect virtualBounds = self.virtualBounds;
			
			contentFrame.origin.y = proportion * (virtualBounds.size.height - contentFrame.size.height) + virtualBounds.origin.y;
			[self scrollContentOriginTo:contentFrame.origin];
			break;
		}
	}
}


- (void)scrollPageUp:(id)sender
{
	NSRect contentFrame = self.innerFrame;
	contentFrame.origin.y += contentFrame.size.height - 2 * (_cellSize + _gridWidth);
	[self scrollContentOriginTo:contentFrame.origin];
}


- (void)scrollPageDown:(id)sender
{
	NSRect contentFrame = self.innerFrame;
	contentFrame.origin.y -= contentFrame.size.height - 2 * (_cellSize + _gridWidth);
	[self scrollContentOriginTo:contentFrame.origin];
}


- (void)scrollLineUp:(id)sender
{
	NSRect contentFrame = self.innerFrame;
	contentFrame.origin.y += (_cellSize + _gridWidth);
	[self scrollContentOriginTo:contentFrame.origin];
}


- (void)scrollLineDown:(id)sender
{
	NSRect contentFrame = self.innerFrame;
	contentFrame.origin.y -= (_cellSize + _gridWidth);
	[self scrollContentOriginTo:contentFrame.origin];
}


- (void)scrollPageLeft:(id)sender
{
	NSRect contentFrame = self.innerFrame;
	contentFrame.origin.x -= contentFrame.size.width - 2 * (_cellSize + _gridWidth);
	[self scrollContentOriginTo:contentFrame.origin];
}


- (void)scrollPageRight:(id)sender
{
	NSRect contentFrame = self.innerFrame;
	contentFrame.origin.x += contentFrame.size.width - 2 * (_cellSize + _gridWidth);
	[self scrollContentOriginTo:contentFrame.origin];
}


- (void)scrollColumnLeft:(id)sender
{
	NSRect contentFrame = self.innerFrame;
	contentFrame.origin.x -= (_cellSize + _gridWidth);
	[self scrollContentOriginTo:contentFrame.origin];
}


- (void)scrollColumnRight:(id)sender
{
	NSRect contentFrame = self.innerFrame;
	contentFrame.origin.x += (_cellSize + _gridWidth);
	[self scrollContentOriginTo:contentFrame.origin];
}


- (void)scrollToBeginningOfDocument:(id)sender
{
	NSRect contentFrame = self.innerFrame;
	contentFrame.origin.y -= contentFrame.size.height - contentFrame.origin.y;
	[self scrollContentOriginTo:contentFrame.origin];
}


- (void)scrollToEndOfDocument:(id)sender
{
	NSRect contentFrame = self.innerFrame;
	contentFrame.origin.y = 0;
	[self scrollContentOriginTo:contentFrame.origin];
}


- (void) scrollWheel:(NSEvent *)event
{
	NSRect contentFrame = self.innerFrame;
	CGFloat deltaX, deltaY;
	
	if ([event respondsToSelector:@selector(hasPreciseScrollingDeltas)] && [event hasPreciseScrollingDeltas])
	{
		// FIXME: should let sub-point values accumulate and clean up when drawing. More importantly, this doesn’t quite work; we sometimes get misaligned tiles.
		deltaX = round(event.scrollingDeltaX);
		deltaY = round(event.scrollingDeltaY);
	}
	else
	{
		deltaX = event.deltaX * (_cellSize + _gridWidth);
		deltaY = event.deltaY * (_cellSize + _gridWidth);
	}
	
	contentFrame.origin.x -= deltaX;
	contentFrame.origin.y += deltaY;
	[self scrollContentOriginTo:contentFrame.origin];
}


#pragma mark Zooming

- (NSUInteger) zoomLevel
{
	return _zoomLevel;
}


- (void) setZoomLevel:(NSUInteger)value
{
	value = MIN(value, self.maximumZoomLevel);
	if (value != _zoomLevel)
	{
		_zoomLevel = value;
		[self performSwitchZoomLevel];
	}
}


-(BOOL) validateZoomLevel:(id *)ioValue error:(NSError **)outError
{
	NSUInteger value = [*ioValue unsignedIntegerValue];
	NSUInteger newValue = value;
	
	newValue = MAX(newValue, 0U);
	newValue = MIN(newValue, self.maximumZoomLevel);
	
	if (newValue != value)
	{
		*ioValue = [NSNumber numberWithInteger:newValue];
	}
	return YES;
}


- (void) invalidateDrawingCaches
{
	_cellSize = [self cellSizeForZoomLevel:_zoomLevel];
	_gridWidth = [self gridWidthForZoomLevel:_zoomLevel];
	_emptyOutsidePattern = nil;
}


- (void) performSwitchZoomLevel
{
	[self switchToZoomLevel:_zoomLevel];
	
	[self invalidateDrawingCaches];
	[self updateScrollers];
	[self setNeedsDisplay:YES];
}


- (void) switchToZoomLevel:(NSUInteger)zoomLevel
{
	// Subclass hook.
}


- (NSUInteger) maximumZoomLevel
{
	return 0;
}


- (NSUInteger) defaultZoomLevel
{
	return 0;
}


- (NSUInteger) cellSizeForZoomLevel:(NSUInteger)zoomLevel
{
	return 22;
}


- (NSUInteger) gridWidthForZoomLevel:(NSUInteger)zoomLevel
{
	return 2;
}


#pragma mark Geometry

- (NSRect) horizontalScrollerFrame
{
	NSSize size = self.frame.size;
	CGFloat scrollerWidth = [NSScroller scrollerWidth];
	
	return (NSRect){ NSZeroPoint, { size.width - scrollerWidth, scrollerWidth }};
}


- (NSRect) verticalScrollerFrame
{
	NSSize size = self.frame.size;
	CGFloat scrollerWidth = [NSScroller scrollerWidth];
	
	return (NSRect){{ size.width - scrollerWidth, scrollerWidth }, { scrollerWidth, size.height - scrollerWidth }};
}


- (NSRect) scrollerCornerFrame
{
	NSSize size = self.frame.size;
	CGFloat scrollerWidth = [NSScroller scrollerWidth];
	
	return (NSRect) {{ size.width - scrollerWidth, 0 }, { scrollerWidth, scrollerWidth }};
}


- (NSRect) innerFrame
{
	NSSize frameSize = self.frame.size;
	CGFloat scrollerWidth = [NSScroller scrollerWidth];
	return (NSRect){ { 0, scrollerWidth }, { frameSize.width - scrollerWidth, frameSize.height - scrollerWidth }};
}


- (NSRect) nonEmptyContentFrame
{
	MCGridExtents extents = self.store.extents;
	
	if (!MCGridExtentsEmpty(extents))
	{
		NSRect rect = [self rectFromExtents:extents];
		rect = NSInsetRect(rect, -_gridWidth, -_gridWidth);
		return rect;
	}
	else
	{
		NSRect rect = [self rectFromCellLocation:kMCZeroCoordinates];
		rect.size = NSZeroSize;
		return rect;
	}
}


- (NSRect) virtualBounds
{
	NSRect virtualBounds = self.nonEmptyContentFrame;
	NSRect contentFrame = self.innerFrame;
	
	if (self.infiniteCanvas)
	{
		// Padding is one screenful, minus two cells, rounded down to a multiple of cell size.
		CGFloat xPadding = (floor(contentFrame.size.width / (_cellSize + _gridWidth)) - 2.0) * (_cellSize + _gridWidth);
		CGFloat yPadding = (floor(contentFrame.size.height / (_cellSize + _gridWidth)) - 2.0) * (_cellSize + _gridWidth);
		
		virtualBounds = NSInsetRect(virtualBounds, -xPadding, -yPadding);
	}
	else
	{
		virtualBounds = NSUnionRect(virtualBounds, contentFrame);
	}

	
	return virtualBounds;
}


#pragma mark Coordinate projections

- (NSPoint) projectToFlattenedCellSpace:(NSPoint)point
{
	CGFloat x = point.x, y = point.y;
	NSRect innerFrame = self.innerFrame;
	
	x = innerFrame.size.width - x - innerFrame.origin.x;
	y = innerFrame.size.height - y - innerFrame.origin.y;
	
	x -= innerFrame.size.width * 0.5;
	y -= innerFrame.size.height * 0.5;
	
	x *= 1.0 / (_cellSize + _gridWidth);
	y *= 1.0 / (_cellSize + _gridWidth);
	
	x += _scrollCenter.x;
	y += _scrollCenter.y;
	
	return (NSPoint) { x, y };
}


- (MCGridCoordinates) cellLocationFromPoint:(NSPoint)point
{
	NSPoint projected = [self projectToFlattenedCellSpace:point];
	return (MCGridCoordinates){ ceil(projected.y), self.currentLayer, ceil(projected.x) };
}


- (MCGridExtents) extentsFromRect:(NSRect)rect
{
	// Note that min and max are swapped, because the coordinate schemes run in opposite directions.
	MCGridCoordinates minl = [self cellLocationFromPoint:(NSPoint){ NSMaxX(rect), NSMaxY(rect) }];
	MCGridCoordinates maxl = [self cellLocationFromPoint:(NSPoint){ NSMinX(rect), NSMinY(rect) }];
	
	return (MCGridExtents)
	{
		minl.x, maxl.x,
		minl.y, maxl.y,
		minl.z, maxl.z
	};
}


- (NSPoint) projectFromFlattenedCellSpace:(NSPoint)point
{
	NSRect innerFrame = self.innerFrame;
	
	CGFloat x = point.x - _scrollCenter.x;
	CGFloat y = point.y - _scrollCenter.y;
	
	x *= (_cellSize + _gridWidth);
	y *= (_cellSize + _gridWidth);
	
	x += innerFrame.size.width * 0.5;
	y += innerFrame.size.height * 0.5;
	
	x = innerFrame.size.width - x - innerFrame.origin.x;
	y = innerFrame.size.height - y - innerFrame.origin.y;
	
	return (NSPoint){ x, y };
}


- (NSRect) rectFromCellLocation:(MCGridCoordinates)location
{
	NSPoint origin = [self projectFromFlattenedCellSpace:(NSPoint){ location.z, location.x }];
	origin = [self convertPointToBase:origin];
	origin.x = round(origin.x);
	origin.y = round(origin.y);
	origin = [self convertPointFromBase:origin];
	return (NSRect)
	{
		origin,
		{ _cellSize, _cellSize }
	};
}


- (NSRect) rectFromExtents:(MCGridExtents)extents
{
	if (MCGridExtentsEmpty(extents))  return NSZeroRect;
	
	NSRect rect = [self rectFromCellLocation:MCGridExtentsMaximum(extents)];
	
	rect.size.width = MCGridExtentsLength(extents) * (_cellSize + _gridWidth) - _gridWidth;
	rect.size.height = MCGridExtentsWidth(extents) * (_cellSize + _gridWidth) - _gridWidth;
	
	return rect;
}


- (MCGridCoordinates) cellLocationForPointInWindow:(NSPoint)pointInWindow
{
	NSPoint pointInView = [self convertPoint:pointInWindow fromView:nil];
	MCGridCoordinates loc = [self cellLocationFromPoint:pointInView];
	return loc;
}

@end
