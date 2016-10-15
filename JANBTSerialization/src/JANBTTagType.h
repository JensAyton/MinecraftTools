/*
	JANBTTagType.h
	
	Internal type used to identify NBT file elements.
	
	
	Copyright © 2011-2013 Jens Ayton
	
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


typedef enum
{
	kJANBTTagEnd				= 0,
	kJANBTTagByte				= 1,
	kJANBTTagShort				= 2,
	kJANBTTagInt				= 3,
	kJANBTTagLong				= 4,
	kJANBTTagFloat				= 5,
	kJANBTTagDouble				= 6,
	kJANBTTagByteArray			= 7,
	kJANBTTagString				= 8,
	kJANBTTagList				= 9,
	kJANBTTagCompound			= 10,
	kJANBTTagIntArray			= 11,
	
	kJANBTTagIntArrayContent	= 0xFD,	// Special ja_NBTListElementType value for NSArrays to be represented as IntArrays.
	kJANBTTagAny				= 0xFE,
	kJANBTTagUnknown			= 0xFF
} JANBTTagType;


NSString *JANBTTagNameFromTagType(JANBTTagType type);
NSString *JANBTTagNameFromSchema(id schema);
BOOL JANBTIsKnownTagType(JANBTTagType type);	// True if type is valid for use in NBT file. (Doesn’t include kJANBTTagEnd, which is only valid in specific circumstances.)


@interface NSObject (JANBTInternal)

@property (readonly, getter=ja_NBTType) JANBTTagType NBTType;
@property (readonly, getter=ja_NBTSchemaType) JANBTTagType NBTSchemaType;

@end


@interface NSArray (JANBTInternal)

@property (nonatomic, getter=ja_NBTListElementType, setter=ja_setNBTListElementType:) JANBTTagType NBTListElementType;

@end


static inline BOOL JANBTIsNumericalTagType(JANBTTagType type)
{
	return kJANBTTagByte <= type && type <= kJANBTTagDouble;
}


static inline BOOL JANBTIsNumericalSchema(id schema)
{
	if (schema != nil)
	{
		return JANBTIsNumericalTagType([schema ja_NBTSchemaType]);
	}
	return YES;
}
