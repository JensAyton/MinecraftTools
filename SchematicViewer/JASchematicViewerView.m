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
	// Load colour table.
	NSURL *url = [[NSBundle mainBundle] URLForResource:@"ColorTable" withExtension:@"plist"];
	NSArray *colorPList = [NSPropertyListSerialization propertyListFromData:[NSData dataWithContentsOfURL:url]
														   mutabilityOption:NSPropertyListImmutable
																	 format:NULL
														   errorDescription:NULL];
	if (![colorPList isKindOfClass:[NSArray class]])  colorPList = nil;
	
	NSMutableArray *colors = [NSMutableArray arrayWithCapacity:256];
	NSColor *white = [NSColor whiteColor];
	
	NSUInteger i, count = colorPList.count;
	for (i = 0; i < count; i++)
	{
		NSArray *colorDef = [colorPList objectAtIndex:i];
		NSColor *color;
		if ([colorDef isKindOfClass:[NSArray class]] && colorDef.count >= 3)
		{
			color = [NSColor colorWithCalibratedRed:[[colorDef objectAtIndex:0] doubleValue] / 255.0
											  green:[[colorDef objectAtIndex:1] doubleValue] / 255.0
											   blue:[[colorDef objectAtIndex:2] doubleValue] / 255.0
											  alpha:1.0];
		}
		else
		{
			color = white;
		}
		[colors addObject:color];
	}
	
	// Ensure entire array is set.
	NSColor *red = [NSColor redColor];
	for (; i < 256; i++)
	{
		[colors addObject:red];
	}
	
	self.renderCallback = ^(JAMinecraftBlockStore *schematic, MCCell cell, MCGridCoordinates location, NSRect cellRect)
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
			cellRect = NSInsetRect(cellRect, width / 2, width / 2);
			[NSBezierPath setDefaultLineWidth:width];
			[NSBezierPath strokeRect:cellRect];
		}
		else if (MCCellIsItem(cell))
		{
			[blockColor set];
			cellRect = NSInsetRect(cellRect, cellRect.size.width / 4, cellRect.size.width / 4);
			[NSBezierPath fillRect:cellRect];
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
