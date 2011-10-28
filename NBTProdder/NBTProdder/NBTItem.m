/*
	NBTItem.m
	
	
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

#import "NBTItem.h"
#import "JANBTTypedNumbers.h"

@implementation NBTItem

@synthesize name = _name;
@synthesize type = _type;
@synthesize children = _children;
@synthesize parent = _parent;
@synthesize value = _value;
@synthesize elementType = _elementType;


- (id) initWithPropertyListRepresentation:(id)plist name:(NSString *)name
{
	if ((self = [super init]))
	{
		JANBTTagType type = [plist ja_NBTType];
		if (type == kJANBTTagUnknown)  return nil;
		
		self.type = type;
		self.elementType = kJANBTTagInt;	// Because it has to be something.
		self.name = name;
		
		if (type == kJANBTTagList)
		{
			NSMutableArray *children = [NSMutableArray arrayWithCapacity:[plist count]];
			for (id sub in plist)
			{
				id subItem = [[NBTItem alloc] initWithPropertyListRepresentation:sub name:nil];
				if (subItem == nil)  return nil;
				[children addObject:subItem];
			}
			self.elementType = [plist ja_NBTListElementType];
			self.children = children;
		}
		else if (type == kJANBTTagCompound)
		{
			NSMutableArray *children = [NSMutableArray arrayWithCapacity:[plist count]];
			for (NSString *key in [[plist allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)])
			{
				id sub = [plist objectForKey:key];
				id subItem = [[NBTItem alloc] initWithPropertyListRepresentation:sub name:key];
				if (subItem == nil)  return nil;
				[children addObject:subItem];
			}
			self.children = children;
		}
		else
		{
			self.value = plist;
		}
	}
	
	return self;
}


- (id) propertyListRepresentation
{
	JANBTTagType type = self.type;
	id displayValue = self.displayValue;
	
	switch (type)
	{
		case kJANBTTagByte:
		case kJANBTTagShort:
		case kJANBTTagInt:
		case kJANBTTagLong:
			return [[JANBTInteger alloc] initWithValue:[displayValue integerValue] type:type];
			
		case kJANBTTagFloat:
			return [[JANBTFloat alloc] initWithValue:[displayValue floatValue]];
			
		case kJANBTTagDouble:
			return [[JANBTDouble alloc] initWithValue:[displayValue doubleValue]];
			
		case kJANBTTagByteArray:
			if ([displayValue isKindOfClass:[NSData class]])  return displayValue;
			else  return [NSData data];
			
		case kJANBTTagString:
			if (displayValue == nil)  return @"";
			else return [displayValue description];
			
		case kJANBTTagList:
		{
			NSArray *children = self.children;
			NSMutableArray *result = [NSMutableArray arrayWithCapacity:children.count];
			for (NBTItem *item in children)
			{
				id plist = [item propertyListRepresentation];
				if (plist == nil)  return nil;
				[result addObject:plist];
			}
			result.ja_NBTListElementType = self.elementType;
			return result;
		}
			
		case kJANBTTagCompound:
		{
			NSArray *children = self.children;
			NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:children.count];
			for (NBTItem *item in children)
			{
				id plist = [item propertyListRepresentation];
				if (plist == nil)  return nil;
				[result setObject:plist forKey:item.name];
			}
			return result;
		}
			
			
		case kJANBTTagEnd:
		case kJANBTTagAny:
		case kJANBTTagUnknown:
			;
	}
	return nil;
}


- (NSString *) displayName
{
	NBTItem *parent = self.parent;
	if (parent.type == kJANBTTagList)
	{
		return [NSString stringWithFormat:@"%lu", [parent.children indexOfObject:self]];
	}
	
	return self.name;
}


- (void) setDisplayName:(NSString *)displayName
{
	if (self.nameEditable)
	{
		self.name = displayName;
	}
}


+ (NSSet *) keyPathsForValuesAffectingDisplayName
{
	return [NSSet setWithObjects:@"name", @"parent.type", @"parent.children", nil];
}


- (BOOL) isNameEditable
{
	return self.parent.type != kJANBTTagList;
}


+ (NSSet *) keyPathsForValuesAffectingNameEditable
{
	return [NSSet setWithObject:@"parent.type"];
}


- (id) displayValue
{
	id value = self.value;
	switch (self.type)
	{
		case kJANBTTagByte:
		case kJANBTTagShort:
		case kJANBTTagInt:
		case kJANBTTagLong:
			if ([value respondsToSelector:@selector(integerValue)])
			{
				return [NSNumber numberWithInteger:[value integerValue]];
			}
			return nil;
			
		case kJANBTTagFloat:
			if ([value respondsToSelector:@selector(floatValue)])
			{
				return [NSNumber numberWithInteger:[value floatValue]];
			}
			// Fall through.
			
		case kJANBTTagDouble:
			if ([value respondsToSelector:@selector(doubleValue)])
			{
				return [NSNumber numberWithInteger:[value doubleValue]];
			}
			return nil;
			
		case kJANBTTagByteArray:
			if ([value isKindOfClass:[NSData class]])  return value;
			else if ([value isKindOfClass:[NSString class]])  return [value dataUsingEncoding:NSUTF8StringEncoding];
			else  return nil;
			
		case kJANBTTagString:
			if (value == nil)  return @"";
			else return [value description];
			
		case kJANBTTagList:
		case kJANBTTagCompound:
		case kJANBTTagEnd:
		case kJANBTTagAny:
		case kJANBTTagUnknown:
			;
	}
	
	if (self.isValueEditable)  return self.value;
	return nil;
}


- (JANBTTagType) type
{
	if (self.parent.type == kJANBTTagList)  return self.parent.elementType;
	return _type;
}


- (void) setType:(JANBTTagType)type
{
	if (self.parent.type == kJANBTTagList && self.parent.children.count == 1)
	{
		self.parent.elementType = type;
	}
	_type = type;
}


- (BOOL )isTypeEditable
{
	return self.parent.type != kJANBTTagList;
}


+ (NSSet *) keyPathsForValuesAffectingTypeEditable
{
	return [NSSet setWithObjects:@"parent.type", @"parent.children.count", nil];
}


- (void) setDisplayValue:(id)displayValue
{
	self.value = displayValue;
}


+ (NSSet *) keyPathsForValuesAffectingDisplayValue
{
	return [NSSet setWithObjects:@"value", @"valueEditable", nil];
}


- (BOOL) isValueEditable
{
	JANBTTagType type = self.type;
	return type != kJANBTTagList && type != kJANBTTagCompound;
}


+ (NSSet *) keyPathsForValuesAffectingValueEditable
{
	return [NSSet setWithObject:@"parent.type"];
}


- (NSMutableArray *) children
{
	JANBTTagType type = self.type;
	if (type == kJANBTTagList || type == kJANBTTagCompound)
	{
		if (_children == nil)  _children = [NSMutableArray array];
		return _children;
	}
	return nil;
}


- (void) setChildren:(NSMutableArray *)children
{
	if (children != _children)
	{
		[_children enumerateObjectsUsingBlock:^(NBTItem *object, NSUInteger index, BOOL *stop) { object.parent = nil; }];
		[children enumerateObjectsUsingBlock:^(NBTItem *object, NSUInteger index, BOOL *stop) { object.parent = self; }];
		
		if (self.type == kJANBTTagList)
		{
			// Ensure lists are homogeneous.
			BOOL wasEmpty = _children.count == 0;
			if (wasEmpty && children.count != 0)
			{
				self.elementType = [(NBTItem *)[children objectAtIndex:0] type];
			}
			JANBTTagType elemType = self.elementType;
			[children enumerateObjectsUsingBlock:^(NBTItem *object, NSUInteger index, BOOL *stop)
			{
				if (object.type != elemType)
				{
					object.parent = nil;
					object.type = elemType;
					object.parent = self;
				}
			}];
		}
		
		_children = children;
	}
}


- (BOOL) isLeafNode
{
	JANBTTagType type = self.type;
	return type != kJANBTTagList && type != kJANBTTagCompound;
}


+ (NSSet *) keyPathsForValuesAffectingLeafNode
{
	return [NSSet setWithObject:@"type"];
}

@end
