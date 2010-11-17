/*
	JANBTParser.m
	
	
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

#import "JANBTParser.h"
#import "NSData+DDGZip.h"


#ifndef NDEBUG
static NSString *NameFromTagType(JANBTTagType type);
#endif


@interface JANBTTag ()
{
	union
	{
		id objectVal;
		long long integerVal;
		double floatVal;
		double doubleVal;
	} _value;
}

@property (readwrite, setter=priv_setType:) JANBTTagType type;
@property (readwrite, copy, setter=priv_setName:) NSString *name;

- (id) initWithName:(NSString *)name integerValue:(long long)value type:(JANBTTagType)type;
- (id) initWithName:(NSString *)name integerValue:(long long)value;	// Selects smallest type.
- (id) initWithName:(NSString *)name floatValue:(float)value;
- (id) initWithName:(NSString *)name doubleValue:(double)value;
- (id) initWithName:(NSString *)name byteArrayValue:(NSData *)value;
- (id) initWithName:(NSString *)name stringValue:(NSString *)value;
- (id) initWithName:(NSString *)name listValue:(NSArray *)value;
- (id) initWithName:(NSString *)name compoundValue:(NSDictionary *)value;

- (void) encodeInto:(NSMutableData *)data;
- (void) encodeWithoutHeaderInto:(NSMutableData *)data;

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

@synthesize type = _type;
@synthesize name = _name;


+ (id) tagWithName:(NSString *)name integerValue:(long long)value type:(JANBTTagType)type
{
	return [[[self alloc] initWithName:name integerValue:value type:type] autorelease];
}


+ (id) tagWithName:(NSString *)name integerValue:(long long)value
{
	return [[[self alloc] initWithName:name integerValue:value] autorelease];
}


+ (id) tagWithName:(NSString *)name floatValue:(float)value
{
	return [[[self alloc] initWithName:name floatValue:value] autorelease];
}


+ (id) tagWithName:(NSString *)name doubleValue:(double)value
{
	return [[[self alloc] initWithName:name doubleValue:value] autorelease];
}


+ (id) tagWithName:(NSString *)name byteArrayValue:(NSData *)value
{
	return [[[self alloc] initWithName:name byteArrayValue:value] autorelease];
}


+ (id) tagWithName:(NSString *)name stringValue:(NSString *)value
{
	return [[[self alloc] initWithName:name stringValue:value] autorelease];
}


+ (id) tagWithName:(NSString *)name listValue:(NSArray *)value
{
	return [[[self alloc] initWithName:name listValue:value] autorelease];
}


+ (id) tagWithName:(NSString *)name compoundValue:(NSDictionary *)value
{
	return [[[self alloc] initWithName:name compoundValue:value] autorelease];
}


- (id) initWithName:(NSString *)name integerValue:(long long)value type:(JANBTTagType)type
{
	switch (type)
	{
		case kJANBTTagByte:
			value = (int8_t)value;
			break;
			
		case kJANBTTagShort:
			value = (int16_t)value;
			break;
			
		case kJANBTTagInt:
			value = (int32_t)value;
			break;
			
		case kJANBTTagLong:
			value = (int64_t)value;
			break;
			
		default:
			[self release];
			return nil;
	}
	
	if ((self = [super init]))
	{
		self.type = type;
		self.name = name;
		_value.integerVal = value;
	}
	
	return self;
}


- (id) initWithName:(NSString *)name integerValue:(long long)value
{
	JANBTTagType type;
	if (-128 <= value && value <= 127)
	{
		type = kJANBTTagByte;
	}
	else if (-32768 <= value && value <= 32767)
	{
		type = kJANBTTagShort;
	}
	else if (-2147483648 <= value && value <= 2147483647)
	{
		type = kJANBTTagInt;
	}
	else
	{
		type = kJANBTTagLong;
	}
	
	return [self initWithName:name integerValue:value type:type];
}


- (id) initWithName:(NSString *)name floatValue:(float)value
{
	if ((self = [super init]))
	{
		self.type = kJANBTTagFloat;
		self.name = name;
		_value.floatVal = value;
	}
	return self;
}


- (id) initWithName:(NSString *)name doubleValue:(double)value
{
	if ((self = [super init]))
	{
		self.type = kJANBTTagDouble;
		self.name = name;
		_value.doubleVal = value;
	}
	return self;
}


- (id) priv_initWithName:(NSString *)name type:(JANBTTagType)type object:(id)value
{
	if ((self = [super init]))
	{
		self.type = type;
		self.name = name;
		_value.objectVal = [value retain];
		[[NSGarbageCollector defaultCollector] disableCollectorForPointer:value];
	}
	return self;
}


- (id) initWithName:(NSString *)name byteArrayValue:(NSData *)value
{
	return [self priv_initWithName:name type:kJANBTTagByteArray object:value];
}


- (id) initWithName:(NSString *)name stringValue:(NSString *)value
{
	return [self priv_initWithName:name type:kJANBTTagString object:value];
}


- (id) initWithName:(NSString *)name listValue:(NSArray *)value
{
	return [self priv_initWithName:name type:kJANBTTagList object:value];
}


- (id) initWithName:(NSString *)name compoundValue:(NSDictionary *)value
{
	return [self priv_initWithName:name type:kJANBTTagCompound object:value];
}


- (void) dealloc
{
	self.name = nil;
	
	if (IsObjectType(self.type))
	{
		[_value.objectVal release];
		_value.objectVal = nil;
	}
	
	[super dealloc];
}


- (void) finalize
{
	[[NSGarbageCollector defaultCollector] enableCollectorForPointer:_value.objectVal];
	
	[super finalize];
}


- (id) copyWithZone:(NSZone *)zone
{
	return [self retain];
}


- (id) objectValue
{
	JANBTTagType type = self.type;
	if (IsObjectType(type))  return _value.objectVal;
	if (IsIntegerType(type))  return [NSNumber numberWithLongLong:_value.integerVal];
	if (type == kJANBTTagFloat)  return [NSNumber numberWithFloat:_value.floatVal];
	if (type == kJANBTTagDouble)  return [NSNumber numberWithDouble:_value.doubleVal];
	
	return nil;
}


- (double) doubleValue
{
	JANBTTagType type = self.type;
	if (type == kJANBTTagFloat)  return _value.floatVal;
	if (type == kJANBTTagDouble)  return _value.doubleVal;
	if (IsIntegerType(type))  return _value.integerVal;
	if (IsObjectType(type) && [_value.objectVal respondsToSelector:@selector(doubleValue)])  return [_value.objectVal doubleValue];
	
	return NAN;
}


- (long long) integerValue
{
	JANBTTagType type = self.type;
	if (IsIntegerType(type))  return _value.integerVal;
	if (type == kJANBTTagFloat)  return _value.floatVal;
	if (type == kJANBTTagDouble)  return _value.doubleVal;
	if (IsObjectType(type))
	{
		if ([_value.objectVal respondsToSelector:@selector(longLongValue)])  return [_value.objectVal longLongValue];
		if ([_value.objectVal respondsToSelector:@selector(integerValue)])  return [_value.objectVal integerValue];
		if ([_value.objectVal respondsToSelector:@selector(intValue)])  return [_value.objectVal intValue];
	}
	
	return 0;
}


- (BOOL) isIntegerType
{
	return IsIntegerType(self.type);
}


- (BOOL) isFloatType
{
	return self.type == kJANBTTagFloat || self.type == kJANBTTagDouble;
}


- (BOOL) isObjectType
{
	return IsObjectType(self.type);
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
{
	NSData					*_data;
	const uint8_t			*_bytes;
	size_t					_remaining;
}

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
{
	JANBTTag				*_rootTag;
	NSData					*_data;
}
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
	
	if (self = [super init])
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
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		JANBTTag *tag = [self priv_parseOneTag];
		[pool release];
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
	return [[[JANBTTag alloc] initWithName:name integerValue:byteVal type:kJANBTTagByte] autorelease];
}


- (JANBTTag *) priv_parseShortWithName:(NSString *)name
{
	int16_t shortVal = [self readShort];
	return [[[JANBTTag alloc] initWithName:name integerValue:shortVal type:kJANBTTagShort] autorelease];
}


- (JANBTTag *) priv_parseIntWithName:(NSString *)name
{
	int32_t intVal = [self readInt];
	return [[[JANBTTag alloc] initWithName:name integerValue:intVal type:kJANBTTagInt] autorelease];
}


- (JANBTTag *) priv_parseLongWithName:(NSString *)name
{
	int64_t longVal = [self readLong];
	return [[[JANBTTag alloc] initWithName:name integerValue:longVal type:kJANBTTagLong] autorelease];
}


- (JANBTTag *) priv_parseFloatWithName:(NSString *)name
{
	int32_t floatBytes = [self readInt];
	Float32 floatVal = *(Float32 *)&floatBytes;
	return [[[JANBTTag alloc] initWithName:name floatValue:floatVal] autorelease];
}


- (JANBTTag *) priv_parseDoubleWithName:(NSString *)name
{
	int64_t doubleBytes = [self readLong];
	Float64 doubleVal = *(Float64 *)&doubleBytes;
	return [[[JANBTTag alloc] initWithName:name doubleValue:doubleVal] autorelease];
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
	return [[[JANBTTag alloc] initWithName:name byteArrayValue:data] autorelease];
}


- (JANBTTag *) priv_parseStringWithName:(NSString *)name
{
	NSString *string = [self readString];
	return [[[JANBTTag alloc] initWithName:name stringValue:string] autorelease];
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
	return [[[JANBTTag alloc] initWithName:name listValue:[NSArray arrayWithArray:array]] autorelease];
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
	
	return [[[JANBTTag alloc] initWithName:name compoundValue:[NSDictionary dictionaryWithDictionary:subTags]] autorelease];
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
