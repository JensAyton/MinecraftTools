/*
	JANBTTagType.m
	
	
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

#import "JANBTTagType.h"
#import <objc/runtime.h>

static const void *kNBTListElementTypeStorageKey = &kNBTListElementTypeStorageKey;


@implementation NSObject (JANBTInternal)

- (JANBTTagType) ja_NBTType
{
	return kJANBTTagUnknown;
}


- (JANBTTagType) ja_NBTSchemaType
{
	return kJANBTTagUnknown;
}

@end


@implementation NSArray (JANBTInternal)

- (JANBTTagType) ja_NBTType
{
	return kJANBTTagList;
}


- (JANBTTagType) ja_NBTSchemaType
{
	return kJANBTTagList;
}


- (JANBTTagType) ja_NBTListElementType
{
	NSNumber *tag = objc_getAssociatedObject(self, kNBTListElementTypeStorageKey);
	if (tag != nil)  return tag.charValue;
	
	if (self.count != 0)  return [[self objectAtIndex:0] ja_NBTType];
	
	return kJANBTTagUnknown;
}


- (void) ja_setNBTListElementType:(JANBTTagType)type
{
	objc_setAssociatedObject(self, kNBTListElementTypeStorageKey, [NSNumber numberWithChar:type], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@implementation NSDictionary (JANBTInternal)

- (JANBTTagType) ja_NBTType
{
	return kJANBTTagCompound;
}


- (JANBTTagType) ja_NBTSchemaType
{
	return kJANBTTagCompound;
}

@end


@implementation NSString (JANBTInternal)

- (JANBTTagType) ja_NBTType
{
	return kJANBTTagString;
}


- (JANBTTagType) ja_NBTSchemaType
{
	if ([self isEqualToString:@"byte"])		return kJANBTTagByte;
	if ([self isEqualToString:@"short"])	return kJANBTTagShort;
	if ([self isEqualToString:@"int"])		return kJANBTTagInt;
	if ([self isEqualToString:@"long"])		return kJANBTTagLong;
	if ([self isEqualToString:@"float"])	return kJANBTTagFloat;
	if ([self isEqualToString:@"double"])	return kJANBTTagDouble;
	if ([self isEqualToString:@"data"])		return kJANBTTagByteArray;
	if ([self isEqualToString:@"string"])	return kJANBTTagString;
	return kJANBTTagUnknown;
}

@end


@implementation NSData (JANBTInternal)

- (JANBTTagType) ja_NBTType
{
	return kJANBTTagByteArray;
}

@end
