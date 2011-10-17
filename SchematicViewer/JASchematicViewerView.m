/*
	JASchematicViewerView.m
	
	
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

#import "JASchematicViewerView.h"
#import <JAMinecraftKit/JAMinecraftSchematic.h>


typedef struct
{
	NSUInteger		cellSize;
	NSUInteger		gridWidth;
} ZoomLevel;

static const ZoomLevel kZoomLevels[] =
{
	{ 4, 1 },
	{ 8, 1 },
	{ 14, 1 },
	{ 22, 2 },
	{ 30, 2 }
};

static const NSUInteger kZoomLevelCount = sizeof kZoomLevels / sizeof *kZoomLevels;
static const NSUInteger kDefaultZoomLevel = 3;


static NSArray *LoadColorTable(void);


@interface JASchematicViewerView ()

- (void) setRenderCallback;

@end


@implementation JASchematicViewerView

- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		[self setRenderCallback];
	}
	
	return self;
}


- (void) setRenderCallback
{
	NSArray *colors = LoadColorTable();
	NSColor *white = [NSColor whiteColor];
	
	self.renderCallback = ^(JAMinecraftBlockStore *schematic, MCCell cell, NSDictionary *tileEntity, MCGridCoordinates location, NSRect cellRect)
	{
		NSColor *blockColor = [colors objectAtIndex:cell.blockID];
		if (MCCellIsFullySolid(cell) || MCCellIsLiquid(cell) || MCCellIsAir(cell))
		{
			// Solid colour.
			[blockColor set];
		}
		else
		{
			// Clear background.
			[white set];
		}
		[NSBezierPath fillRect:cellRect];
		
		if (MCCellIsQuasiSolid(cell))
		{
			[blockColor set];
			CGFloat width = 2.0;
			NSRect contentRect = NSInsetRect(cellRect, width / 2, width / 2);
			[NSBezierPath setDefaultLineWidth:width];
			[NSBezierPath strokeRect:contentRect];
		}
		else if (MCCellIsItem(cell))
		{
			[blockColor set];
			NSRect contentRect = NSInsetRect(cellRect, cellRect.size.width / 4, cellRect.size.width / 4);
			[NSBezierPath fillRect:contentRect];
		}
		
		if (tileEntity != nil)
		{
			// Draw dotted orange outline around blocks with tile entities.
			[[NSColor orangeColor] set];
			NSBezierPath *path = [NSBezierPath bezierPathWithRect:NSInsetRect(cellRect, 1, 1)];
			[path setLineDash:(CGFloat []){2, 2} count:2 phase:0];
			path.lineWidth = 2;
			[path stroke];
		}
	};
}


#pragma mark Zooming

- (NSUInteger) maximumZoomLevel
{
	return kZoomLevelCount - 1;
}


- (NSUInteger) defaultZoomLevel
{
	return kDefaultZoomLevel;
}


- (NSUInteger) cellSizeForZoomLevel:(NSUInteger)zoomLevel
{
	return kZoomLevels[zoomLevel].cellSize;
}


- (NSUInteger) gridWidthForZoomLevel:(NSUInteger)zoomLevel
{
	return kZoomLevels[zoomLevel].gridWidth;
}

@end


static NSArray *LoadColorTable(void)
{
	NSURL *url = [[NSBundle mainBundle] URLForResource:@"ColorTable" withExtension:@"plist"];
	NSArray *colorPList = [NSArray arrayWithContentsOfURL:url];
	
	NSMutableArray *colors = [NSMutableArray arrayWithCapacity:256];
	NSColor *white = [NSColor whiteColor];
	
	for (NSArray *colorDef in colorPList)
	{
		NSColor *color = white;
		if ([colorDef isKindOfClass:[NSArray class]] && colorDef.count >= 3)
		{
			color = [NSColor colorWithCalibratedRed:[[colorDef objectAtIndex:0] doubleValue] / 255.0
											  green:[[colorDef objectAtIndex:1] doubleValue] / 255.0
											   blue:[[colorDef objectAtIndex:2] doubleValue] / 255.0
											  alpha:1.0];
		}
		[colors addObject:color];
	}
	
	// Ensure entire array is set.
	NSColor *red = [NSColor redColor];
	for (NSUInteger i = colors.count; i < 256; i++)
	{
		[colors addObject:red];
	}
	
	return [colors copy];
}
