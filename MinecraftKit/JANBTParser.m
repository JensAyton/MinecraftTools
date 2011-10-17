/*
	JANBTParser.m
	
	
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

#import "JANBTParser.h"
#import "NSData+DDGZip.h"
#import "JACollectionHelpers.h"


#ifndef NDEBUG
static NSString *NameFromTagType(JANBTTagType type);
#endif


@interface JANBTIntegerTag: JANBTTag

- (id) initWithName:(NSString *)name integerValue:(long long)value type:(JANBTTagType)type;

@end


@interface JANBTFloatTag: JANBTTag

- (id) initWithName:(NSString *)name floatValue:(float)value;

@end


@interface JANBTDoubleTag: JANBTTag

- (id) initWithName:(NSString *)name doubleValue:(double)value;

@end


@interface JANBTObjectTag: JANBTTag

- (id) initWithName:(NSString *)name objectValue:(id)object type:(JANBTTagType)type;

@end


@interface JANBTTag ()

@property (readwrite, copy, setter=priv_setName:) NSString *name;

- (id) initWithName:(NSString *)name;

- (void) encodeInto:(NSMutableData *)data;
- (void) encodeWithoutHeaderInto:(NSMutableData *)data;

@end


@interface NSObject (JANBTTag)

- (id) japriv_NBTFromPlistWithName:(NSString *)name;

@end


static inline BOOL IsObjectType(JANBTTagType type)
{
	switch (type)
	{
		case kJANBTTagEnd:
		case kJANBTTagByte:
		case kJANBTTagShort:
		case kJANBTTagInt:
		case kJANBTTagLong:
		case kJANBTTagFloat:
		case kJANBTTagDouble:
			return NO;
			
		case kJANBTTagByteArray:
		case kJANBTTagString:
		case kJANBTTagList:
		case kJANBTTagCompound:
			return YES;
	}
	
	return NO;
}


static inline BOOL IsIntegerType(JANBTTagType type)
{
	switch (type)
	{
		case kJANBTTagEnd:
			return NO;
			
		case kJANBTTagByte:
		case kJANBTTagShort:
		case kJANBTTagInt:
		case kJANBTTagLong:
			return YES;
			
		case kJANBTTagFloat:
		case kJANBTTagDouble:
		case kJANBTTagByteArray:
		case kJANBTTagString:
		case kJANBTTagList:
		case kJANBTTagCompound:
			return NO;
	}
	
	return NO;
}


static inline BOOL IsFloatType(JANBTTagType type)
{
	switch (type)
	{
		case kJANBTTagEnd:
		case kJANBTTagByte:
		case kJANBTTagShort:
		case kJANBTTagInt:
		case kJANBTTagLong:
			return NO;
			
		case kJANBTTagFloat:
		case kJANBTTagDouble:
			return YES;
			
		case kJANBTTagByteArray:
		case kJANBTTagString:
		case kJANBTTagList:
		case kJANBTTagCompound:
			return NO;
	}
	
	return NO;
}


@implementation JANBTTag

@synthesize name = _name;


+ (id) tagWithName:(NSString *)name integerValue:(long long)value type:(JANBTTagType)type
{
	return [[[JANBTIntegerTag alloc] initWithName:name integerValue:value type:type] autorelease];
}


+ (id) tagWithName:(NSString *)name integerValue:(long long)value
{
	JANBTTagType type;
	if (INT8_MIN <= value && value <= INT8_MAX)
	{
		type = kJANBTTagByte;
	}
	else if (INT16_MIN <= value && value <= INT16_MAX)
	{
		type = kJANBTTagShort;
	}
	else if (INT32_MIN <= value && value <= INT32_MAX)
	{
		type = kJANBTTagInt;
	}
	else
	{
		type = kJANBTTagLong;
	}
	
	return [[[JANBTIntegerTag alloc] initWithName:name integerValue:value type:type] autorelease];
}


+ (id) tagWithName:(NSString *)name floatValue:(float)value
{
	return [[[JANBTFloatTag alloc] initWithName:name floatValue:value] autorelease];
}


+ (id) tagWithName:(NSString *)name doubleValue:(double)value
{
	return [[[JANBTDoubleTag alloc] initWithName:name doubleValue:value] autorelease];
}


+ (id) tagWithName:(NSString *)name byteArrayValue:(NSData *)value
{
	return [[[JANBTObjectTag alloc] initWithName:name objectValue:value type:kJANBTTagByteArray] autorelease];
}


+ (id) tagWithName:(NSString *)name stringValue:(NSString *)value
{
	return [[[JANBTObjectTag alloc] initWithName:name objectValue:value type:kJANBTTagString] autorelease];
}


+ (id) tagWithName:(NSString *)name listValue:(NSArray *)value
{
	return [[[JANBTObjectTag alloc] initWithName:name objectValue:value type:kJANBTTagList] autorelease];
}


+ (id) tagWithName:(NSString *)name compoundValue:(NSDictionary *)value
{
	return [[[JANBTObjectTag alloc] initWithName:name objectValue:value type:kJANBTTagCompound] autorelease];
}


- (id) initWithName:(NSString *)name
{	
	if ((self = [super init]))
	{
		self.name = name;
	}
	
	return self;
}


- (id) copyWithZone:(NSZone *)zone
{
	return [self retain];
}


@dynamic type, objectValue;	// Subclass responsibilities


- (double) doubleValue
{
	return [self.objectValue doubleValue];
}


- (long long) integerValue
{
	return [self.objectValue integerValue];
}


- (BOOL) isIntegerType
{
	return NO;
}


- (BOOL) isFloatType
{
	return NO;
}


- (BOOL) isObjectType
{
	return NO;
}


static void WriteByte(NSMutableData *data, uint8_t byteVal)
{
	[data appendBytes:&byteVal length:1];
}


static void WriteShort(NSMutableData *data, uint16_t shortVal)
{
	int8_t shortBytes[] =
	{
		(shortVal >> 8) & 0xFF,
		(shortVal) & 0xFF
	};
	[data appendBytes:shortBytes length:sizeof shortBytes];
}


static void WriteInt(NSMutableData *data, uint32_t intVal)
{
	int8_t intBytes[] =
	{
		(intVal >> 24) & 0xFF,
		(intVal >> 16) & 0xFF,
		(intVal >> 8) & 0xFF,
		(intVal) & 0xFF
	};
	[data appendBytes:intBytes length:sizeof intBytes];
}


static void WriteLong(NSMutableData *data, uint64_t longVal)
{
	int8_t longBytes[] =
	{
		(longVal >> 56) & 0xFF,
		(longVal >> 48) & 0xFF,
		(longVal >> 40) & 0xFF,
		(longVal >> 32) & 0xFF,
		(longVal >> 24) & 0xFF,
		(longVal >> 16) & 0xFF,
		(longVal >> 8) & 0xFF,
		(longVal) & 0xFF
	};
	[data appendBytes:longBytes length:sizeof longVal];
}


static void WriteString(NSMutableData *data, NSString *string)
{
	NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
	WriteShort(data, stringData.length);
	[data appendData:stringData];
}


- (void) encodeInto:(NSMutableData *)data
{
	JANBTTagType type = self.type;
	
	WriteByte(data, type);
	WriteString(data, self.name);
	
	[self encodeWithoutHeaderInto:data];
}


- (void) encodeWithoutHeaderInto:(NSMutableData *)data
{
	switch (self.type)
	{
		case kJANBTTagEnd:
			break;
			
		case kJANBTTagByte:
			WriteByte(data, self.integerValue);
			break;
			
		case kJANBTTagShort:
			WriteShort(data, self.integerValue);
			break;
			
		case kJANBTTagInt:
			WriteInt(data, self.integerValue);
			break;
			
		case kJANBTTagLong:
			WriteLong(data, self.integerValue);
			break;
			
		case kJANBTTagFloat:
		{
			Float32 floatVal = self.doubleValue;
			WriteInt(data, *(int32_t *)&floatVal);
			break;
		}
			
		case kJANBTTagDouble:
		{
			Float64 doubleVal = self.doubleValue;
			WriteLong(data, *(int64_t *)&doubleVal);
			break;
		}
			
		case kJANBTTagByteArray:
		{
			NSData *byteArrayVal = self.objectValue;
			WriteInt(data, byteArrayVal.length);
			[data appendData:byteArrayVal];
			break;
		}
			
		case kJANBTTagString:
		{
			WriteString(data, self.objectValue);
			break;
		}
			
		case kJANBTTagList:
		{
			NSArray *listVal = self.objectValue;
			
			// FIXME: store type for collections.
			NSUInteger count = listVal.count;
			JANBTTagType subType = kJANBTTagByte;
			if (count > 0)  subType = [(JANBTTag *)[listVal objectAtIndex:0] type];
			
			WriteByte(data, subType);
			WriteInt(data, count);
			
			for (JANBTTag *tag in listVal)
			{
				[tag encodeWithoutHeaderInto:data];
			}
			break;
		}
			
		case kJANBTTagCompound:
		{
			NSDictionary *compoundVal = self.objectValue;
			for (JANBTTag *tag in compoundVal.allValues)
			{
				[tag encodeInto:data];
			}
			
			// Write a TAG_End to terminate.
			WriteByte(data, kJANBTTagEnd);
			break;
		}
	}
}


#ifndef NDEBUG
static NSString *IndentString(NSUInteger count)
{
	NSString * const staticTabs[] =
	{
		@"",
		@"\t",
		@"\t\t",
		@"\t\t\t",
		@"\t\t\t\t",
		@"\t\t\t\t\t",
		@"\t\t\t\t\t\t",
		@"\t\t\t\t\t\t\t"
	};
	
	if (count < sizeof staticTabs / sizeof *staticTabs)
	{
		return staticTabs[count];
	}
	else
	{
		NSMutableString *result = [NSMutableString stringWithCapacity:count];
		for (NSUInteger i = 0; i < count; i++)
		{
			[result appendString:@"\t"];
		}
		return result;
	}
}


- (NSString *) debugDescriptionWithIndentLevel:(NSUInteger)indent
{
	NSMutableString *result = [NSMutableString stringWithString:NameFromTagType(self.type)];
	if (self.type != kJANBTTagEnd)
	{
		if (self.name.length > 0)  [result appendFormat:@"(\"%@\")", self.name];
		[result appendString:@": "];
		
		JANBTTagType type = self.type;
		if (IsIntegerType(type))
		{
			[result appendFormat:@"%lli", self.integerValue];
		}
		else if (IsFloatType(type))
		{
			[result appendFormat:@"%g", self.doubleValue];
		}
		else if (type == kJANBTTagByteArray)
		{
			[result appendFormat:@"[%llu bytes]", (long long)[self.objectValue length]];
		//	[result appendFormat:@" %@", self.objectValue];
		}
		else if (type == kJANBTTagString)
		{
			[result appendString:self.objectValue];
		}
		else if (type == kJANBTTagList)
		{
			NSArray *list = self.objectValue;
			NSUInteger count = list.count;
			if (count == 0)  [result appendString:@"0 entries"];	// Strictly, we shouldn't be losing type info in this case.
			else
			{
				JANBTTag *subTag = [list objectAtIndex:0];
				[result appendFormat:@"%llu entries of type %@\n%@{", count, NameFromTagType(subTag.type), IndentString(indent)];
				
				for (subTag in list)
				{
					[result appendFormat:@"\n%@%@", IndentString(indent + 1), [subTag debugDescriptionWithIndentLevel:indent + 1]];
				}
				
				[result appendFormat:@"\n%@}", IndentString(indent)];
			}
		}
		else if (type == kJANBTTagCompound)
		{
			NSDictionary *dict = self.objectValue;
			NSUInteger count = dict.count;
			if (count == 0)  [result appendString:@"0 entries"];	// Strictly, we shouldn't be losing type info in this case.
			else
			{
				[result appendFormat:@"%llu entries\n%@{", count, IndentString(indent)];
				
				for (NSString *key in dict)
				{
					JANBTTag *subTag = [dict objectForKey:key];
					[result appendFormat:@"\n%@%@", IndentString(indent + 1), [subTag debugDescriptionWithIndentLevel:indent + 1]];
				}
				
				[result appendFormat:@"\n%@}", IndentString(indent)];
			}
		}
	}
	
	return result;
}


- (NSString *) debugDescription
{
	return [self debugDescriptionWithIndentLevel:0];
}


- (NSString *) description
{
	JANBTTagType type = self.type;
	NSMutableString *result = [NSMutableString stringWithFormat:@"<%@ %p>{%@", self.class, self, NameFromTagType(type)];
	NSString *name = self.name;
	if (name != nil)  [result appendFormat:@" \"%@\"", name];
	
	switch (type)
	{
		case kJANBTTagEnd:
			break;
			
		case kJANBTTagByte:
		case kJANBTTagShort:
		case kJANBTTagInt:
		case kJANBTTagLong:
			[result appendFormat:@": %lli", self.integerValue];
			break;
			
		case kJANBTTagFloat:
		case kJANBTTagDouble:
			[result appendFormat:@": %g", self.doubleValue];
			break;
			
		case kJANBTTagByteArray:
			[result appendFormat:@": %lu bytes", [self.objectValue length]];
			break;
			
		case kJANBTTagString:
			[result appendFormat:@": \"%@\"", self.objectValue];
			break;
			
		case kJANBTTagList:
		case kJANBTTagCompound:
			[result appendFormat:@": %lu items", [self.objectValue count]];
			break;
	}
	
	[result appendString:@"}"];
	return result;
}
#endif


- (id) propertyListRepresentation
{
	switch (self.type)
	{
		case kJANBTTagEnd:
			return nil;
			
		case kJANBTTagByte:
		case kJANBTTagShort:
		case kJANBTTagInt:
		case kJANBTTagLong:
		case kJANBTTagFloat:
		case kJANBTTagDouble:
		case kJANBTTagByteArray:
		case kJANBTTagString:
			return self.objectValue;
			
		case kJANBTTagList:
		{
			NSArray *array = self.objectValue;
			return [array ja_map:^(id value){ return [value propertyListRepresentation]; }];
		}
			
		case kJANBTTagCompound:
		{
			NSDictionary *dict = self.objectValue;
			return [dict ja_mapValues:^(id key, id value){ return [value propertyListRepresentation]; }];
		}
	}
}


+ (id) tagWithName:(NSString *)name propertyListRepresentation:(id)plist
{
	return [plist japriv_NBTFromPlistWithName:name];
}

@end


@implementation JANBTIntegerTag
{
	NSInteger			_value;
	JANBTTagType		_type;
}


- (id) initWithName:(NSString *)name integerValue:(long long)value type:(JANBTTagType)type
{
	if ((self = [super initWithName:name]))
	{
		switch (type)
		{
			case kJANBTTagByte:
				_value = (int8_t)value;
				break;
				
			case kJANBTTagShort:
				_value = (int16_t)value;
				break;
				
			case kJANBTTagInt:
				_value = (int32_t)value;
				break;
				
			case kJANBTTagLong:
				_value = (int64_t)value;
				break;
				
			default:
				[self release];
				return nil;
		}
		
		_type = type;
	}
	
	return self;
}


- (JANBTTagType) type
{
	return _type;
}


- (double) doubleValue
{
	return _value;
}


- (long long) integerValue
{
	return _value;
}


- (id) objectValue
{
	return [NSNumber numberWithInteger:_value];
}


- (BOOL) isIntegerType
{
	return YES;
}

@end


@implementation JANBTFloatTag
{
	float			_value;
}

- (id) initWithName:(NSString *)name floatValue:(float)value
{
	if ((self = [super initWithName:name]))
	{
		_value = value;
	}
	
	return self;
}


- (JANBTTagType) type
{
	return kJANBTTagFloat;
}


- (double) doubleValue
{
	return _value;
}


- (long long) integerValue
{
	return _value;
}


- (id) objectValue
{
	return [NSNumber numberWithFloat:_value];
}


- (BOOL) isFloatType
{
	return YES;
}

@end


@implementation JANBTDoubleTag
{
	double			_value;
}

- (id) initWithName:(NSString *)name doubleValue:(double)value
{
	if ((self = [super initWithName:name]))
	{
		_value = value;
	}
	
	return self;
}


- (JANBTTagType) type
{
	return kJANBTTagDouble;
}


- (double) doubleValue
{
	return _value;
}


- (long long) integerValue
{
	return _value;
}


- (id) objectValue
{
	return [NSNumber numberWithDouble:_value];
}


- (BOOL) isFloatType
{
	return YES;
}

@end


@implementation JANBTObjectTag
{
	id					_value;
	JANBTTagType		_type;
}

- (id) initWithName:(NSString *)name objectValue:(id)value type:(JANBTTagType)type
{
	if ((self = [super initWithName:name]))
	{
		_value = [value copy];
		_type = type;
	}
	
	return self;
}


- (void) dealloc
{
	[_value release];
	[super dealloc];
}


- (JANBTTagType) type
{
	return _type;
}


- (id) objectValue
{
	return _value;
}


- (BOOL) isObjectType
{
	return YES;
}

@end


@implementation NSObject (JANBTTag)

- (id) japriv_NBTFromPlistWithName:(NSString *)name
{
	return nil;
}

@end


@implementation NSNumber (JANBTTag)

- (id) japriv_NBTFromPlistWithName:(NSString *)name
{
	const char *type = [self objCType];
	if (strcmp(type, @encode(float)) == 0)
	{
		return [JANBTTag tagWithName:name floatValue:[self floatValue]];
	}
	if (strcmp(type, @encode(double)) == 0)
	{
		return [JANBTTag tagWithName:name doubleValue:[self doubleValue]];
	}
	return [JANBTTag tagWithName:name integerValue:[self integerValue]];
}

@end


@implementation NSData (JANBTTag)

- (id) japriv_NBTFromPlistWithName:(NSString *)name
{
	return [JANBTTag tagWithName:name byteArrayValue:self];
}

@end


@implementation NSString (JANBTTag)

- (id) japriv_NBTFromPlistWithName:(NSString *)name
{
	return [JANBTTag tagWithName:name stringValue:self];
}

@end


@implementation NSArray (JANBTTag)

- (id) japriv_NBTFromPlistWithName:(NSString *)name
{
	NSArray *elements = [self ja_map:^(id value)
	{
		return [JANBTTag tagWithName:nil propertyListRepresentation:value];
	}];
	return [JANBTTag tagWithName:name listValue:elements];	
}

@end


@implementation NSDictionary (JANBTTag)

- (id) japriv_NBTFromPlistWithName:(NSString *)name
{
	NSDictionary *elements = [self ja_mapValues:^(id key, id value)
	{
		return [JANBTTag tagWithName:key propertyListRepresentation:value];
	}];
	return [JANBTTag tagWithName:name compoundValue:elements];
}

@end


#ifndef NDEBUG
static NSString *NameFromTagType(JANBTTagType type)
{
	switch (type)
	{
		case kJANBTTagEnd:
			return @"TAG_End";
			
		case kJANBTTagByte:
			return @"TAG_Byte";
			
		case kJANBTTagShort:
			return @"TAG_Short";
			
		case kJANBTTagInt:
			return @"TAG_Int";
			
		case kJANBTTagLong:
			return @"TAG_Long";
			
		case kJANBTTagFloat:
			return @"TAG_Float";
			
		case kJANBTTagDouble:
			return @"TAG_Double";
			
		case kJANBTTagByteArray:
			return @"TAG_Byte_Array";
			
		case kJANBTTagString:
			return @"TAG_String";
			
		case kJANBTTagList:
			return @"TAG_List";
			
		case kJANBTTagCompound:
			return @"TAG_Compound";
	}
	
	return @"**UNKNOWN TAG**";
}
#endif


static NSString * const kJANBTParserUnexpectedEOFException = @"se.ayton.jens JANBTParser Unexpected EOF";
static NSString * const kJANBTParserUnknownTagException = @"se.ayton.jens JANBTParser Unknown Tag";


@interface JANBTParser ()

// These will raise kJANBTParserUnexpectedEOFException if they would otherwise pass the end of the data.
- (void) readBytes:(void *)buffer length:(size_t)length;

// Note that "Short", "Int" and "Long" refer to NBT types, not native types.
- (int8_t) readByte;
- (int16_t) readShort;
- (int32_t) readInt;
- (int64_t) readLong;

- (NSString *) readString;

@end


@interface JANBTParser (Parsing)

- (JANBTTag *) priv_parseOneTag;
- (JANBTTag *) priv_parseTagBodyWithType:(JANBTTagType)type name:(NSString *)name;

- (JANBTTag *) priv_parseByteWithName:(NSString *)name;
- (JANBTTag *) priv_parseShortWithName:(NSString *)name;
- (JANBTTag *) priv_parseIntWithName:(NSString *)name;
- (JANBTTag *) priv_parseLongWithName:(NSString *)name;
- (JANBTTag *) priv_parseFloatWithName:(NSString *)name;
- (JANBTTag *) priv_parseDoubleWithName:(NSString *)name;
- (JANBTTag *) priv_parseByteArrayWithName:(NSString *)name;
- (JANBTTag *) priv_parseStringWithName:(NSString *)name;
- (JANBTTag *) priv_parseListWithName:(NSString *)name;
- (JANBTTag *) priv_parseCompoundWithName:(NSString *)name;

@end


@interface JANBTEncoder ()
@end


static void UnexpectedEOF(void) __attribute__((noreturn));
static void UnexpectedEOF(void)
{
	[NSException raise:kJANBTParserUnexpectedEOFException format:nil];
	__builtin_unreachable();
}


@implementation JANBTParser

+ (JANBTTag *) parseData:(NSData *)data
{
	JANBTParser *parser = [[self alloc] initWithData:data];
	JANBTTag *result = [parser parsedTags];
	[parser release];
	
	return result;
}


- (id) initWithData:(NSData *)data
{
	// TODO: use a streaming deflate approach instead.
	data = [data dd_gzipInflate];
	if (data == nil)
	{
		[self release];
		return nil;
	}
	
	if ((self = [super init]))
	{
		_data = [data retain];
		_bytes = data.bytes;
		_remaining = data.length;
	}
	
	return self;
}


- (void) dealloc
{
	[_data release];
	_data = nil;
	
	[super dealloc];
}


- (JANBTTag *) parsedTags
{
	@try
	{
		JANBTTag *tag = nil;
		@autoreleasepool
		{
			tag = [self priv_parseOneTag];
		}
		return tag;
	}
	@catch (NSException *e)
	{
		if ([e.reason hasPrefix:@"se.ayton.jens JANBTParser"])
		{
			// Invalid file.
			return nil;
		}
		else
		{
			// We broke something!
			[e raise];
		}

	}
}


- (void) readBytes:(void *)buffer length:(size_t)length
{
	NSParameterAssert(buffer != NULL || length == 0);
	
	if (_remaining >= length)
	{
		memcpy(buffer, _bytes, length);
		_remaining -= length;
		_bytes += length;
	}
	else  UnexpectedEOF();

}


- (int8_t) readByte
{
	if (_remaining >= 1)
	{
		_remaining--;
		return *_bytes++;
	}
	else  UnexpectedEOF();
}


- (int16_t) readShort
{
	if (_remaining >= 2)
	{
		_remaining -= 2;
		uint16_t result = *_bytes++;
		result = (result << 8) | *_bytes++;
		return result;
	}
	else  UnexpectedEOF();
}


- (int32_t) readInt
{
	if (_remaining >= 4)
	{
		_remaining -= 4;
		uint32_t result = *_bytes++;
		result = (result << 8) | *_bytes++;
		result = (result << 8) | *_bytes++;
		result = (result << 8) | *_bytes++;
		return result;
	}
	else  UnexpectedEOF();
}


- (int64_t) readLong
{
	if (_remaining >= 8)
	{
		_remaining -= 8;
		uint64_t result = *_bytes++;
		result = (result << 8) | *_bytes++;
		result = (result << 8) | *_bytes++;
		result = (result << 8) | *_bytes++;
		result = (result << 8) | *_bytes++;
		result = (result << 8) | *_bytes++;
		result = (result << 8) | *_bytes++;
		result = (result << 8) | *_bytes++;
		return result;
	}
	else  UnexpectedEOF();
}


- (NSString *) readString
{
	uint16_t length = [self readShort];
	char *bytes = malloc(length);
	if (bytes == NULL)  [NSException raise:NSMallocException format:@"Out of memory"];
	
	@try
	{
		[self readBytes:bytes length:length];
	}
	@catch (id e)
	{
		free(bytes);
		[e raise];
	}
	
	NSString *result = [[NSString alloc] initWithBytesNoCopy:bytes length:length encoding:NSUTF8StringEncoding freeWhenDone:YES];
	return [result autorelease];
}

@end


@implementation JANBTParser (Parsing)


- (JANBTTag *) priv_parseOneTag
{
	JANBTTagType type = [self readByte];
	NSString *name = nil;
	if (type != kJANBTTagEnd)
	{
		name = [self readString];
		if (name.length == 0)  name = nil;
	}
	
	return [self priv_parseTagBodyWithType:type name:name];
}


- (JANBTTag *) priv_parseTagBodyWithType:(JANBTTagType)type name:(NSString *)name
{
	switch (type)
	{
		case kJANBTTagEnd:
			return nil;
			
		case kJANBTTagByte:
			return [self priv_parseByteWithName:name];
			
		case kJANBTTagShort:
			return [self priv_parseShortWithName:name];
			
		case kJANBTTagInt:
			return [self priv_parseIntWithName:name];
			
		case kJANBTTagLong:
			return [self priv_parseLongWithName:name];
			
		case kJANBTTagFloat:
			return [self priv_parseFloatWithName:name];
			
		case kJANBTTagDouble:
			return [self priv_parseDoubleWithName:name];
			
		case kJANBTTagByteArray:
			return [self priv_parseByteArrayWithName:name];
			
		case kJANBTTagString:
			return [self priv_parseStringWithName:name];
			
		case kJANBTTagList:
			return [self priv_parseListWithName:name];
			
		case kJANBTTagCompound:
			return [self priv_parseCompoundWithName:name];
			
		default:
			[NSException raise:kJANBTParserUnknownTagException format:@"Unknown NBT tag %u", type];
	}
	return nil;
}


- (JANBTTag *) priv_parseByteWithName:(NSString *)name
{
	int8_t byteVal = [self readByte];
	return [[[JANBTIntegerTag alloc] initWithName:name integerValue:byteVal type:kJANBTTagByte] autorelease];
}


- (JANBTTag *) priv_parseShortWithName:(NSString *)name
{
	int16_t shortVal = [self readShort];
	return [[[JANBTIntegerTag alloc] initWithName:name integerValue:shortVal type:kJANBTTagShort] autorelease];
}


- (JANBTTag *) priv_parseIntWithName:(NSString *)name
{
	int32_t intVal = [self readInt];
	return [[[JANBTIntegerTag alloc] initWithName:name integerValue:intVal type:kJANBTTagInt] autorelease];
}


- (JANBTTag *) priv_parseLongWithName:(NSString *)name
{
	int64_t longVal = [self readLong];
	return [[[JANBTIntegerTag alloc] initWithName:name integerValue:longVal type:kJANBTTagLong] autorelease];
}


- (JANBTTag *) priv_parseFloatWithName:(NSString *)name
{
	int32_t floatBytes = [self readInt];
	Float32 floatVal = *(Float32 *)&floatBytes;
	return [[[JANBTFloatTag alloc] initWithName:name floatValue:floatVal] autorelease];
}


- (JANBTTag *) priv_parseDoubleWithName:(NSString *)name
{
	int64_t doubleBytes = [self readLong];
	Float64 doubleVal = *(Float64 *)&doubleBytes;
	return [[[JANBTDoubleTag alloc] initWithName:name doubleValue:doubleVal] autorelease];
}


- (JANBTTag *) priv_parseByteArrayWithName:(NSString *)name
{
	int32_t length = [self readInt];
	void *bytes = malloc(length);
	if (bytes == NULL)  [NSException raise:NSMallocException format:@"Out of memory"];
	
	@try
	{
		[self readBytes:bytes length:length];
	}
	@catch (id e)
	{
		free(bytes);
		[e raise];
	}
	
	NSData *data = [NSData dataWithBytesNoCopy:bytes length:length freeWhenDone:YES];
	return [JANBTTag tagWithName:name byteArrayValue:data];
}


- (JANBTTag *) priv_parseStringWithName:(NSString *)name
{
	return [JANBTTag tagWithName:name stringValue:[self readString]];
}


- (JANBTTag *) priv_parseListWithName:(NSString *)name
{
	JANBTTagType type = [self readByte];
	int32_t i, count = [self readInt];
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
	
	for (i = 0; i < count; i++)
	{
		JANBTTag *tag = [self priv_parseTagBodyWithType:type name:nil];
		[array addObject:tag];
	}
	
	// NOTE: loses type info if list is empty. This could be a problem.
	return [JANBTTag tagWithName:name listValue:[NSArray arrayWithArray:array]];
}


- (JANBTTag *) priv_parseCompoundWithName:(NSString *)name
{
	NSMutableDictionary *subTags = [NSMutableDictionary dictionary];
	for (;;)
	{
		JANBTTag *tag = [self priv_parseOneTag];
		if (tag == nil) break;	// Signifies TAG_End
		
		NSString *key = tag.name;
		if (key == nil)  continue;
		[subTags setObject:tag forKey:key];
	}
	
	return [JANBTTag tagWithName:name compoundValue:[NSDictionary dictionaryWithDictionary:subTags]];
}

@end


@implementation JANBTEncoder

+ (NSData *) encodeTag:(JANBTTag *)tag
{
	JANBTEncoder *encoder = [[self alloc] initWithRootTag:tag];
	NSData *result = [encoder encodedData];
	[encoder release];
	
	return result;
}


- (id) initWithRootTag:(JANBTTag *)tag
{
	if (tag == nil)
	{
		[self release];
		return nil;
	}
	
	if ((self = [super init]))
	{
		_rootTag = [tag retain];
	}
	
	return self;
}


- (void) dealloc
{
	[_rootTag release];
	_rootTag = nil;
	
	[_data release];
	_data = nil;
	
	[super dealloc];
}


- (NSData *) encodedData
{
	if (_data == nil)
	{
		NSMutableData *rawData = [NSMutableData data];
		[_rootTag encodeInto:rawData];
		_data = [[rawData dd_gzipDeflate] retain];
		[_rootTag release];
		_rootTag = nil;
	}
	
	return _data;
}

@end


@implementation NSMutableDictionary (JANBTHelpers)

- (void) ja_setNBTInteger:(long long)value type:(JANBTTagType)type forKey:(NSString *)key
{
	if (key == nil)  return;
	[self setObject:[JANBTTag tagWithName:key integerValue:value type:type] forKey:key];
}


- (void) ja_setNBTInteger:(long long)value forKey:(NSString *)key
{
	if (key == nil)  return;
	[self setObject:[JANBTTag tagWithName:key integerValue:value] forKey:key];
}


- (void) ja_setNBTFloat:(float)value forKey:(NSString *)key
{
	if (key == nil)  return;
	[self setObject:[JANBTTag tagWithName:key floatValue:value] forKey:key];
}


- (void) ja_setNBTDouble:(double)value forKey:(NSString *)key
{
	if (key == nil)  return;
	[self setObject:[JANBTTag tagWithName:key doubleValue:value] forKey:key];
}


- (void) ja_setNBTByteArray:(NSData *)value forKey:(NSString *)key
{
	if (key == nil)  return;
	[self setObject:[JANBTTag tagWithName:key byteArrayValue:value] forKey:key];
}


- (void) ja_setNBTString:(NSString *)value forKey:(NSString *)key
{
	if (key == nil)  return;
	[self setObject:[JANBTTag tagWithName:key stringValue:value] forKey:key];
}


- (void) ja_setNBTList:(NSArray *)value forKey:(NSString *)key
{
	if (key == nil)  return;
	[self setObject:[JANBTTag tagWithName:key listValue:value] forKey:key];
}


- (void) ja_setNBTCompound:(NSDictionary *)value forKey:(NSString *)key
{
	if (key == nil)  return;
	[self setObject:[JANBTTag tagWithName:key compoundValue:value] forKey:key];
}


- (JANBTTag *) ja_asNBTTagWithName:(NSString *)name
{
	return [JANBTTag tagWithName:name compoundValue:self];
}

@end
