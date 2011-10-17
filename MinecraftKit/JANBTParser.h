/*
	JANBTParser.h
	
	Parse an NBT binary file.
	
	The NBT format is conceptually similar to a binary property list. However,
	NBT-based formats specify which type of number is to be used, so the
	standard property list types can’t safely be used.
	
	For format documentation, see:
	http://www.minecraft.net/docs/NBT.txt
	
	
	Copyright © 2010–2011 Jens Ayton
	
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

/*
	A schema is a property list type specifying the expected types of NBT
	entries. See Schematic.schema for an example and grammar.
	The schema is advisory; if a value can’t be represented in the specified
	type, or none is specified, an appropriate type will be selected automatically.
*/
- (id) propertyListRepresentation;
+ (id) tagWithName:(NSString *)name propertyListRepresentation:(id)plist schema:(id)schema;

+ (id) tagWithName:(NSString *)name integerValue:(long long)value type:(JANBTTagType)type;
+ (id) tagWithName:(NSString *)name integerValue:(long long)value;	// Selects smallest appropriate type.
+ (id) tagWithName:(NSString *)name floatValue:(float)value;
+ (id) tagWithName:(NSString *)name doubleValue:(double)value;
+ (id) tagWithName:(NSString *)name byteArrayValue:(NSData *)value;
+ (id) tagWithName:(NSString *)name stringValue:(NSString *)value;
+ (id) tagWithName:(NSString *)name listValue:(NSArray *)value;		// Value type is inferred from first value. List may not be empty.
+ (id) tagWithName:(NSString *)name listValue:(NSArray *)value elementType:(JANBTTagType)type;
+ (id) tagWithName:(NSString *)name compoundValue:(id)value;		// Value may be dictionary or array of named tags. objectValue will always be dictionary.

@end


/*
	JANBTParser
	
	Deserialize an NBT file into JANBTTags.
*/
@interface JANBTParser: NSObject

+ (JANBTTag *) parseData:(NSData *)data;

- (id) initWithData:(NSData *)data;

- (JANBTTag *) parsedTags;

@end


/*
	JANBTEncoder
	
	Serialize a JANBTTag hierarchy into an NBT file.
	The specification requires the root to be a compound tag, but this isn’t
	enforced.
*/
@interface JANBTEncoder: NSObject

+ (NSData *) encodeTag:(JANBTTag *)tag;

- (id) initWithRootTag:(JANBTTag *)tag;

- (NSData *) encodedData;

@end


// Helpers for building compounds.
@interface NSMutableDictionary (JANBTHelpers)

- (void) ja_setNBTInteger:(long long)value type:(JANBTTagType)type forKey:(NSString *)key;
- (void) ja_setNBTInteger:(long long)value forKey:(NSString *)key;
- (void) ja_setNBTFloat:(float)value forKey:(NSString *)key;
- (void) ja_setNBTDouble:(double)value forKey:(NSString *)key;
- (void) ja_setNBTByteArray:(NSData *)value forKey:(NSString *)key;
- (void) ja_setNBTString:(NSString *)value forKey:(NSString *)key;
- (void) ja_setNBTList:(NSArray *)value forKey:(NSString *)key;
- (void) ja_setNBTCompound:(NSDictionary *)value forKey:(NSString *)key;

- (JANBTTag *) ja_asNBTTagWithName:(NSString *)name;

@end
