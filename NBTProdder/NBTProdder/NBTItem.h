//
//  NBTItem.h
//  NBTProdder
//
//  Created by Jens Ayton on 2011-10-28.
//  Copyright (c) 2011 Jens Ayton. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JANBTTagType.h"


@interface NBTItem: NSObject

- (id) initWithPropertyListRepresentation:(id)plist name:(NSString *)name;

- (id) propertyListRepresentation;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, readonly, getter=isNameEditable) BOOL nameEditable;

@property (nonatomic) JANBTTagType type;
@property (nonatomic, readonly, getter=isTypeEditable) BOOL typeEditable;
@property (nonatomic) JANBTTagType elementType;	// Only applies to lists.

@property (nonatomic, strong) id value;
@property (nonatomic, strong) id displayValue;
@property (nonatomic, readonly, getter=isValueEditable) BOOL valueEditable;

@property (nonatomic, weak) NBTItem *parent;
@property (nonatomic, strong) NSMutableArray *children;
@property (nonatomic, readonly, getter=isLeafNode) BOOL leafNode;

@end
