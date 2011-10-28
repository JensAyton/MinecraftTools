/*
	NBTDocument.m
	
	
	Copyright © 2011 Jens Ayton
	
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

#import "NBTDocument.h"
#import "NBTItem.h"
#import <JAMinecraftKit/JANBTSerialization.h>


@interface NBTDocument ()

@property (strong) NBTItem *root;

@property (weak) IBOutlet NSOutlineView *outlineView;
@property (strong) IBOutlet NSTreeController *treeController;

- (IBAction) addItem:(id)sender;
- (IBAction) removeItem:(id)sender;

@end


@implementation NBTDocument

@synthesize outlineView = _outlineView;
@synthesize treeController = _treeController;
@synthesize root = _root;


- (NSString *) windowNibName
{
	return @"NBTDocument";
}


- (void) windowControllerDidLoadNib:(NSWindowController *)controller
{
	[super windowControllerDidLoadNib:controller];
	[controller.window setContentBorderThickness:self.outlineView.enclosingScrollView.frame.origin.y forEdge:NSMinYEdge];
	self.treeController.content = self.root;
}


- (NSData *) dataOfType:(NSString *)typeName error:(NSError **)outError
{
	id plist = [self.root propertyListRepresentation];
	if (plist == nil)  return nil;
	
	NSLog(@"%@", plist);
	
	return [JANBTSerialization dataWithNBTObject:plist rootName:self.root.name options:0 schema:nil error:outError];
}


- (BOOL) readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	NSString *rootName;
	id root = [JANBTSerialization NBTObjectWithData:data
										   rootName:&rootName options:kJANBTReadingMutableLeaves | kJANBTReadingMutableContainers | kJANBTReadingAllowFragments
											 schema:nil
											  error:outError];
	
	NBTItem *rootItem = [[NBTItem alloc] initWithPropertyListRepresentation:root name:rootName];
	self.root = rootItem;
	
	return rootItem != nil;
}


+ (BOOL) autosavesInPlace
{
	return YES;
}


- (BOOL) canAddItem
{
	NSArray *selected = self.treeController.selectedObjects;
	if (selected.count != 1)  return NO;
	
	NBTItem *selItem = [selected objectAtIndex:0];
	if (selItem.parent == nil)
	{
		// Item is root; only allow adding if collection.
		JANBTTagType type = selItem.type;
		return type == kJANBTTagCompound || type == kJANBTTagList;
	}
	
	return YES;
}


- (IBAction) addItem:(id)sender
{
	if (!self.canAddItem)  return;
	
	NBTItem *selected = [self.treeController.selectedObjects objectAtIndex:0];
	NSIndexPath *selPath = self.treeController.selectionIndexPath;
	
	NBTItem *new = [NBTItem new];
	new.name = NSLocalizedString(@"new", @"New compound member name.");
	
	JANBTTagType type = selected.type;
	
	if (type == kJANBTTagList)
	{
		// Insert at end of list.
		new.type = selected.elementType;
		selPath = [selPath indexPathByAddingIndex:selected.children.count];
	}
	else if (type == kJANBTTagCompound)
	{
		// Insert at end of compound.
		new.type = kJANBTTagInt;
		selPath = [selPath indexPathByAddingIndex:selected.children.count];
	}
	else
	{
		new.type = type;
	}
	[self.treeController insertObject:new atArrangedObjectIndexPath:selPath];
}


- (BOOL) canRemoveItem
{
	NSArray *selected = self.treeController.selectedObjects;
	if (selected.count != 1)  return NO;
	
	NBTItem *selItem = [selected objectAtIndex:0];
	return selItem.parent != nil;
}


- (IBAction) removeItem:(id)sender
{
	if (!self.canRemoveItem)  return;
	[self.treeController removeObjectAtArrangedObjectIndexPath:self.treeController.selectionIndexPath];
}


- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item
{
	SEL action = item.action;
	if (action == @selector(addItem:))
	{
		return self.canAddItem;
	}
	else if (action == @selector(addItem:))
	{
		return self.canRemoveItem;
	}
	return YES;
}

@end
