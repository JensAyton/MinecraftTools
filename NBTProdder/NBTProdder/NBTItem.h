/*
	NBTItem.h
	
	Model object representing an NBT element, designed to be more tree controller
	friendly than raw plist objects. As a side effect, it allows a suprising
	degree of flexibility in changing types without losing information.
	
	
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
