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
#import "JAPropertyListAccessors.h"
#import "MYCollectionUtilities.h"


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


#pragma mark Tool tips

- (BOOL) hasCellToolTips
{
	return YES;
}


// SUPER MEGA AWESOME template engine.
#define TEMPLATE(string, NAME)			[string stringByReplacingOccurrencesOfString:(@"<$"#NAME"$>") withString:NAME]
#define TEMPLATE_KEY(dict, key, NAME)	({ NSString *template = [dict ja_stringForKey:key]; TEMPLATE(template, NAME); })

#define TEMPLATE2(string, NAME1, NAME2)					TEMPLATE(TEMPLATE(string, NAME1), NAME2)
#define TEMPLATE3(string, NAME1, NAME2, NAME3)			TEMPLATE(TEMPLATE2(string, NAME1, NAME2), NAME3)

#define TEMPLATE_KEY2(dict, key, NAME1, NAME2)			TEMPLATE(TEMPLATE_KEY(dict, key, NAME1), NAME2)
#define TEMPLATE_KEY3(dict, key, NAME1, NAME2, NAME3)	TEMPLATE(TEMPLATE_KEY2(dict, key, NAME1, NAME2), NAME3)


- (NSString *) stringForToolTipForLocation:(MCGridCoordinates)location
									  cell:(MCCell)cell
								tileEntity:(NSDictionary *)tileEntity
{
	if (_toolTipExtraStrings == nil)
	{
		_toolTipExtraStrings = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"CellToolTips" withExtension:@"plist"]];
		_toolTipStrings = [_toolTipExtraStrings objectForKey:@"by ID"];
		if (![_toolTipStrings isKindOfClass:[NSArray class]])  _toolTipStrings = nil;
	}
	
	NSString *base = nil;
	NSString *extra = nil;
	
	if (cell.blockID < _toolTipStrings.count)
	{
		base = [_toolTipStrings objectAtIndex:cell.blockID];
	}
	
	switch (cell.blockID)
	{
		case kMCBlockCloth:
		{
			NSArray *types = [_toolTipExtraStrings objectForKey:@"Wool"];
			if ([types isKindOfClass:[NSArray class]] && cell.blockData < types.count)
			{
				extra = [types objectAtIndex:cell.blockData];
			}
			break;
		}
			
		case kMCBlockRedstoneWire:
			if (cell.blockData == 0)
			{
				extra = [_toolTipExtraStrings objectForKey:@"Redstone0"];
			}
			else
			{
				NSString *level = [NSString stringWithFormat:@"%u", cell.blockData];
				extra = TEMPLATE_KEY(_toolTipExtraStrings, @"Redstone", level);
			}
			break;
			
		case kMCBlockStoneWithSilverfish:
		{
			NSArray *types = [_toolTipExtraStrings objectForKey:@"Silverfish"];
			if ([types isKindOfClass:[NSArray class]] && cell.blockData < types.count)
			{
				extra = [types objectAtIndex:cell.blockData];
			}
			break;
		}
			
		case kMCBlockSignPost:
		case kMCBlockWallSign:
		{
			NSMutableArray *lines = [NSMutableArray arrayWithCapacity:4];
			for (NSUInteger i = 1; i <= 4; i++)
			{
				NSString *text = [tileEntity ja_stringForKey:$sprintf(@"Text%u", i)];
				if (text.length > 0)  [lines addObject:text];
			}
			
			if (lines.count > 0)
			{
				NSString *text = [lines componentsJoinedByString:@" / "];
				extra = TEMPLATE_KEY(_toolTipExtraStrings, @"Quote", text);
			}
			else
			{
				extra = [_toolTipExtraStrings ja_stringForKey:@"Sign-empty"];
			}
			break;
		}
			
		case kMCBlockWoodenDoor:
		case kMCBlockIronDoor:
		case kMCBlockTrapdoor:
		case kMCBlockGate:
			extra = [_toolTipExtraStrings ja_stringForKey:(cell.blockData & kMCInfoDoorOpen) ? @"Door-open" : @"Door-closed"];
			break;
			
		case kMCBlockLever:
		case kMCBlockStoneButton:
			extra = [_toolTipExtraStrings ja_stringForKey:(cell.blockData & kMCInfoLeverOn) ? @"Switch-on" : @"Switch-off"];
			break;
			
		case kMCBlockBed:
			extra = [_toolTipExtraStrings ja_stringForKey:(cell.blockData & kInfoBedIsHead) ? @"Bed-head" : @"Bed-foot"];
			break;
	}
	
	if (base != nil)
	{
		if (extra != nil)
		{
			return TEMPLATE_KEY2(_toolTipExtraStrings, @"Parens", base, extra);
		}
		else
		{
			return base;
		}
	}
	else
	{
		NSString *blockID = [NSString stringWithFormat:@"%u", cell.blockID];
		return TEMPLATE_KEY(_toolTipExtraStrings, @"UnknownID", blockID);
	}
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
