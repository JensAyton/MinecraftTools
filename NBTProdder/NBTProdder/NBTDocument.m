//
//  JADocument.m
//  NBTProdder
//
//  Created by Jens Ayton on 2011-10-27.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NBTDocument.h"
#import "NBTItem.h"
#import <JAMinecraftKit/JANBTSerialization.h>


@interface NBTDocument ()

@property (strong) NBTItem *root;

@property (weak) IBOutlet NSOutlineView *outlineView;
@property (strong) IBOutlet NSTreeController *treeController;

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

@end
