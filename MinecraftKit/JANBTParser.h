/*
	JANBTParser.h
	
	Parse an NBT binary file.
	
	The NBT format is conceptually similar to a binary property list. However,
	NBT-based formats specify which type of number is to be used, so the
	standard property list types can’t safely be used.
	
	For format documentation, see:
	http://www.minecraft.net/docs/NBT.txt
	
	
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

#import <Foundation/Foundation.h>


typedef enum
{
	kJANBTTagEnd		= 0,	// Not seen externally.
	kJANBTTagByte		= 1,
	kJANBTTagShort		= 2,
	kJANBTTagInt		= 3,
	kJANBTTagLong		= 4,
	kJANBTTagFloat		= 5,
	kJANBTTagDouble		= 6,
	kJANBTTagByteArray	= 7,
	kJANBTTagString		= 8,
	kJANBTTagList		= 9,
	kJANBTTagCompound	= 10
} JANBTTagType;


@interface JANBTTag: NSObject <NSCopying>

@property (readonly) JANBTTagType type;
@property (readonly, copy) NSString *name;
@property (readonly) id objectValue;	// NSDictionary for compound, NSArray for array; NSString, NSNumber or NSData for leaves.

@property (readonly) double doubleValue;
@property (readonly) long long integerValue;

@property (readonly, getter=isIntegerType) BOOL integerType;
@property (readonly, getter=isFloatType) BOOL floatType;
@property (readonly, getter=isObjectType) BOOL objectType;

#ifndef NDEBUG
- (NSString *) debugDescription;
#endif

@end


@interface JANBTParser: NSObject

+ (JANBTTag *) parseData:(NSData *)data;

- (id) initWithData:(NSData *)data;

- (JANBTTag *) parsedTags;

@end
