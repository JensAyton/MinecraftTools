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


@implementation MyDocument

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
	
	[self.schematicView bind:@"schematic"
					toObject:self withKeyPath:@"schematic"
					 options:nil];
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
	return [NSSet setWithObject:@"schematicView.visibleLayer"];
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
	else if (action == @selector(copy:) || action == @selector(cut:))
	{
		enabled = !JACircuitExtentsEmpty(self.schematicView.selection);
	}
	else if (action == @selector(paste:))
	{
		enabled = [[NSPasteboard generalPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:kJAMinecraftSchematicUTI, kJAMinecraftRedstoneSimulatorUTI, nil]] != nil;
	}
	else
	{
		if ([super respondsToSelector:@selector(validateMenuItem:)])  enabled = [super validateMenuItem:menuItem];
	}
	
	return enabled;
}


- (IBAction) copy:(id)sender
{
	JACircuitExtents selection = self.schematicView.selection;
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
	// FIXME: clear selected area with undo.
	NSLog(@"Pretend selected area was just cleared!");
	self.schematicView.selection = kJAEmptyExtents;
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

@end
