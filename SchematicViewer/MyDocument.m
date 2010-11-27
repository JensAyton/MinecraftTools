/*
	MyDocument.m
	
	
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

#import "MyDocument.h"
#import "JAMinecraftSchematic.h"
#import "JAMinecraftSchematic+SchematicIO.h"
#import "JAMinecraftSchematic+RDatIO.h"
#import "JASchematicViewerView.h"


@interface MyDocument ()

// General, reversible undo mechanism.
- (void) saveSchematicForUndoWithName:(NSString *)undoActionName;
- (void) undoSchematicChangeWithOldSchematic:(JAMinecraftSchematic *)oldSchematic selection:(MCGridExtents)oldSelection;

@end


@implementation MyDocument

@synthesize schematic = _schematic;
@synthesize schematicView = _schematicView;


- (id) init
{
	if ((self = [super init]))
	{
		self.schematic = [[JAMinecraftSchematic alloc] init];
	}
	
	return self;
}


- (NSString *) windowNibName
{
    return @"MyDocument";
}


- (void) windowControllerDidLoadNib:(NSWindowController *)controller
{
	[super windowControllerDidLoadNib:controller];
	
	[controller.window setContentBorderThickness:34 forEdge:NSMinYEdge];
	
	[self.schematicView bind:@"store"
					toObject:self withKeyPath:@"schematic"
					 options:nil];
	[self.schematicView scrollToCenter:nil];
}


- (NSData *) dataOfType:(NSString *)typeName error:(NSError **)outError
{
	if ([typeName isEqualToString:kJAMinecraftRedstoneSimulatorUTI])
	{
		return [self.schematic rDatDataWithError:outError];
	}
	else if ([typeName isEqualToString:kJAMinecraftSchematicUTI])
	{
		return [self.schematic schematicDataWithError:outError];
	}
	return nil;
}


- (BOOL) readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	if ([typeName isEqualToString:kJAMinecraftRedstoneSimulatorUTI])
	{
		self.schematic = [[JAMinecraftSchematic alloc] initWithRDatData:data error:outError];
	}
	else if ([typeName isEqualToString:kJAMinecraftSchematicUTI])
	{
		self.schematic = [[JAMinecraftSchematic alloc] initWithSchematicData:data error:outError];
	}
	else
	{
		NSLog(@"Unknown type %@", typeName);
		return NO;
	}
	
	return self.schematic != nil;
}


- (NSUInteger) currentLayer
{
	return self.schematicView.currentLayer;
}


- (void) setCurrentLayer:(NSUInteger)value
{
	self.schematicView.currentLayer = value;
}


+ (NSSet *) keyPathsForValuesAffectingCurrentLayer
{
	return [NSSet setWithObject:@"schematicView.currentLayer"];
}


-(BOOL) validateCurrentLayer:(id *)ioValue error:(NSError **)outError
{
	NSInteger value = [*ioValue integerValue];
	NSInteger newValue = value;
	
	newValue = MAX(newValue, self.schematic.minimumLayer);
	newValue = MIN(newValue, self.schematic.maximumLayer);
	
	if (newValue != value)
	{
		*ioValue = [NSNumber numberWithInteger:newValue];
	}
	return YES;
}


- (IBAction) incrementCurrentLayer:(id)sender
{
	self.currentLayer++;
}


- (IBAction) decrementCurrentLayer:(id)sender
{
	self.currentLayer--;
}


- (IBAction) zoomIn:(id)sender
{
	self.schematicView.zoomLevel++;
}


- (IBAction) zoomOut:(id)sender
{
	self.schematicView.zoomLevel--;
}


- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
	SEL action = menuItem.action;
	BOOL enabled = YES;
	
	if (action == @selector(zoomIn:))
	{
		enabled = self.schematicView.zoomLevel < self.schematicView.maximumZoomLevel;
	}
	else if (action == @selector(zoomOut:))
	{
		enabled = 0 < self.schematicView.zoomLevel;
	}
	else if (action == @selector(copy:) || action == @selector(cut:) || action == @selector(delete:))
	{
		enabled = !MCGridExtentsEmpty(self.schematicView.selection);
	}
	else if (action == @selector(paste:))
	{
		enabled = [[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:kJAMinecraftSchematicUTI, kJAMinecraftRedstoneSimulatorUTI, nil]] != nil;
	}
#if NDEBUG
	else if (action == @selector(saveGraphViz:))
	{
		enabled = NO;
	}
#endif
	else
	{
		if ([super respondsToSelector:@selector(validateMenuItem:)])  enabled = [super validateMenuItem:menuItem];
	}
	
	return enabled;
}


- (IBAction) copy:(id)sender
{
	MCGridExtents selection = self.schematicView.selection;
	NSData *data = [self.schematic schematicDataForRegion:selection withError:NULL];
	if (data == nil)
	{
		NSBeep();
		return;
	}
	
	NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	[pboard clearContents];
	[pboard setData:data forType:kJAMinecraftSchematicUTI];
}


- (IBAction) cut:(id)sender
{
	[self copy:sender];
	[self saveSchematicForUndoWithName:NSLocalizedString(@"Cut", @"Cut user interface action.")];
	[self.schematic fillRegion:self.schematicView.selection withCell:(MCCell){ kMCBlockAir, 0 }];
	self.schematicView.selection = kMCEmptyExtents;
}


- (IBAction) paste:(id)sender
{
	NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	JAMinecraftSchematic *pasted = nil;
	NSData *data = [pboard dataForType:kJAMinecraftSchematicUTI];
	if (data != nil)  pasted = [[JAMinecraftSchematic alloc] initWithSchematicData:data error:nil];
	
	if (pasted == nil)
	{
		data = [pboard dataForType:kJAMinecraftRedstoneSimulatorUTI];
		if (data != nil)  pasted = [[JAMinecraftSchematic alloc] initWithRDatData:data error:nil];
	}
	
	if (data == nil)
	{
		NSBeep();
		return;
	}
	
	// FIXME: floating selections, undo, actual pasting.
	NSLog(@"Pretend something was just pasted!");
}


- (IBAction) delete:(id)sender
{
	[self saveSchematicForUndoWithName:NSLocalizedString(@"Delete", @"Delete user interface action.")];
	[self.schematic fillRegion:self.schematicView.selection withCell:(MCCell){ kMCBlockAir, 0 }];
}


- (IBAction) selectAll:(id)sender
{
	// FIXME: do we need to explicitly drop here?
	self.schematicView.selection = self.schematic.extents;
}


- (IBAction) selectNone:(id)sender
{
	// FIXME: do we need to explicitly drop here?
	self.schematicView.selection = kMCEmptyExtents;
}


- (IBAction) saveGraphViz:(id)sender
{
#ifndef NDEBUG
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	savePanel.allowedFileTypes = [NSArray arrayWithObject:@"dot"];
	savePanel.nameFieldStringValue = [self.displayName stringByAppendingPathExtension:@"dot"];
	[savePanel setExtensionHidden:NO];
	
	[savePanel beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSInteger result){
		if (result)
		{
			[self.schematic writeDebugGraphVizToURL:savePanel.URL];
		}
	}];
#endif
}


- (void) saveSchematicForUndoWithName:(NSString *)undoActionName
{
	NSUndoManager *undoMgr = self.undoManager;
	[undoMgr setActionName:undoActionName];
	[[undoMgr prepareWithInvocationTarget:self] undoSchematicChangeWithOldSchematic:[self.schematic copy] selection:self.schematicView.selection];
}


- (void) undoSchematicChangeWithOldSchematic:(JAMinecraftSchematic *)oldSchematic selection:(MCGridExtents)oldSelection
{
	JAMinecraftSchematic *currentSchematic = self.schematic;
	MCGridExtents currentSelection = self.schematicView.selection;
	
	self.schematic = oldSchematic;
	self.schematicView.selection = oldSelection;
	
	[[self.undoManager prepareWithInvocationTarget:self] undoSchematicChangeWithOldSchematic:currentSchematic selection:currentSelection];
}


- (IBAction) scribble:(id)sender
{
	//	Modify blocks randomly to test copy-on-write and undo.
	
	[self saveSchematicForUndoWithName:NSLocalizedString(@"Scribble", @"Scribble user interface action.")];
	JAMinecraftSchematic *schematic = self.schematic;
	
	MCGridExtents extents = self.schematicView.selection;
	if (MCGridExtentsEmpty(extents))  extents = schematic.extents;
	if (MCGridExtentsEmpty(extents))
	{
		// Reasonable fallback.
		extents = (MCGridExtents){ -10, 10, -10, 10, -10, 10 };
	}
	
	srandomdev();
	NSUInteger scribbleCount = MCGridExtentsLength(extents) * MCGridExtentsWidth(extents) * MCGridExtentsHeight(extents) / 50;
	if (scribbleCount < 5)  scribbleCount = 5;
	
	[schematic beginBulkUpdate];
	while (scribbleCount--)
	{
		MCGridCoordinates coords =
		{
			random() % MCGridExtentsWidth(extents) + extents.minX,
			random() % MCGridExtentsHeight(extents) + extents.minY,
			random() % MCGridExtentsLength(extents) + extents.minZ
		};
		
		MCCell cell = { random() % (kMCLastBlockID + 1), 0 };
		
		[schematic setCell:cell at:coords];
	}
	[schematic endBulkUpdate];
}

@end
