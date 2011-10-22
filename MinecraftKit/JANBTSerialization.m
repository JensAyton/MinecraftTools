/*
	JANBTSerialization.m
	
	
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

#import "JANBTSerialization.h"
#import <zlib.h>
#import "MYCollectionUtilities.h"


typedef enum
{
	kJANBTTagEnd		= 0,
	kJANBTTagByte		= 1,
	kJANBTTagShort		= 2,
	kJANBTTagInt		= 3,
	kJANBTTagLong		= 4,
	kJANBTTagFloat		= 5,
	kJANBTTagDouble		= 6,
	kJANBTTagByteArray	= 7,
	kJANBTTagString		= 8,
	kJANBTTagList		= 9,
	kJANBTTagCompound	= 10,
	
	kJANBTTagAny		= 0xFE,
	kJANBTTagUnknown	= 0xFF
} JANBTTagType;


NSString * const kJANBTSerializationErrorDomain = @"se.ayton.jens.minecraftkit JANBTSerialization ErrorDomain";

// Create an NSError in kJANBTSerializationErrorDomain if outError is not null.
static void SetError(NSError **outError, NSInteger errorCode, NSString *format, ...) NS_FORMAT_FUNCTION(3, 4);


static inline BOOL IsNumericalSchema(id schema);
static NSString *NameFromTagType(JANBTTagType type);
static NSString *TypeNameFromSchema(id schema);


enum
{
	kBufferLength				= 32 << 10
};


/*
	REQUIRE(cond)
	REQUIRE_ERR(condition, errorCode, format)
	Helper macros to deal with error propagation.
	
	Each parser method signals failure by returning either NO or nil. These
	macros propagates failures and handles all four type combinations
	by virtue of C’s horribly weak type system.
	
	REQUIRE_ERR() also creates an NSError and puts it in _error if _error is
	currently nil.
*/
#define REQUIRE_ERR(COND, ERRCODE, FORMAT...) do { if (__builtin_expect(!(COND), 0)) { [self setErrorIfClear:ERRCODE format:FORMAT]; return 0; }} while (0)

#define REQUIRE(COND) do { if (__builtin_expect(!(COND), 0))  return 0; } while (0)


@interface JANBTStreamParser: NSObject <NSStreamDelegate>

- (id) initWithStream:(NSInputStream *)stream options:(JANBTReadingOptions)options;
- (BOOL) parseWithSchema:(id)schema expectedRootName:(NSString *)expectedName error:(NSError **)outError;

@property (readonly) id root;
@property (readonly) NSString *rootName;

// Parsing internals.
- (BOOL) parseWithSchemaInner:(id)schema expectedRootName:(NSString *)expectedName  __attribute__((warn_unused_result));
- (id) parseOneTagBodyOfType:(JANBTTagType)type withSchema:(id)schema;

- (void) cleanUp;
- (void) setErrorIfClear:(NSInteger)errorCode format:(NSString *)format, ... NS_FORMAT_FUNCTION(2, 3);

- (NSNumber *) parseByteWithSchema:(id)schema;
- (NSNumber *) parseShortWithSchema:(id)schema;
- (NSNumber *) parseIntWithSchema:(id)schema;
- (NSNumber *) parseLongWithSchema:(id)schema;
- (NSNumber *) parseFloatWithSchema:(id)schema;
- (NSNumber *) parseDoubleWithSchema:(id)schema;
- (NSData *) parseByteArrayWithSchema:(id)schema;
- (NSString *) parseStringWithSchema:(id)schema;
- (NSArray *) parseListWithSchema:(id)schema;
- (NSDictionary *) parseCompoundWithSchema:(id)schema;

// Read functions all throw exception on failure.
- (BOOL) readBytes:(void *)bytes length:(NSUInteger)length __attribute__((nonnull, warn_unused_result));
- (BOOL) readByte:(int8_t *)value __attribute__((nonnull, warn_unused_result));
- (BOOL) readShort:(int16_t *)value __attribute__((nonnull, warn_unused_result));
- (BOOL) readInt:(int32_t *)value __attribute__((nonnull, warn_unused_result));
- (BOOL) readLong:(int64_t *)value __attribute__((nonnull, warn_unused_result));
- (BOOL) readFloat:(Float32 *)value __attribute__((nonnull, warn_unused_result));
- (BOOL) readDouble:(Float64 *)value __attribute__((nonnull, warn_unused_result));
- (NSString *) readStringMutable:(BOOL)mutable;

@end


@interface JANBTInteger: NSNumber

- (id) initWithValue:(NSInteger)value type:(JANBTTagType)type;

@end


@interface JANBTFloat: NSNumber

- (id) initWithValue:(Float32)value;

@end


@interface JANBTDouble: NSNumber

- (id) initWithValue:(Float64)value;

@end


@interface NSNumber (JANBTNumberType)

- (JANBTTagType) ja_NBTType;

@end


@interface NSObject (JANBTInternal)

- (JANBTTagType) ja_NBTSchemaType;

@end


@implementation JANBTSerialization

- (id) init
{
	return nil;
}


+ (BOOL) isValidNBTObject:(id)obj
{
	return [self isValidNBTObject:obj conformingToSchema:nil options:0];
}


+ (BOOL) isValidNBTObject:(id)obj conformingToSchema:(id)schema options:(JANBTWritingOptions)options
{
	return NO;
}


+ (NSData *) dataWithNBTObject:(id)root
					  rootName:(NSString *)rootName
					   options:(JANBTWritingOptions)options
						schema:(id)schema
						 error:(NSError **)outError
{
	NSOutputStream *stream = [NSOutputStream outputStreamToMemory];
	NSInteger bytesWritten = [self writeNBTObject:root rootName:rootName toStream:stream options:options schema:schema error:outError];
	if (bytesWritten == 0)  return nil;
	
	return [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
}


+ (id) NBTObjectWithData:(NSData *)data
				rootName:(NSString **)outRootName
				 options:(JANBTReadingOptions)options
				  schema:(id)schema
				   error:(NSError **)outError
{
	NSInputStream *stream = [NSInputStream inputStreamWithData:data];
	return [self NBTObjectWithStream:stream rootName:outRootName options:options schema:schema error:outError];
}


+ (NSInteger) writeNBTObject:(id)obj
					rootName:(NSString *)rootName
					toStream:(NSOutputStream *)stream
					 options:(JANBTWritingOptions)opt
					  schema:(id)schema
					   error:(NSError **)error
{
	return 0;
}


+ (id) NBTObjectWithStream:(NSInputStream *)stream
				  rootName:(NSString **)ioRootName
				   options:(JANBTReadingOptions)options
					schema:(id)schema
					 error:(NSError **)outError
{
	if (stream == nil)  return nil;
	
	JANBTStreamParser *parser = [[JANBTStreamParser alloc] initWithStream:stream options:options];
	if (parser == nil)
	{
		SetError(outError, kJANBTSerializationMemoryError, @"Could not create NBT parser.");
		return nil;
	}
	
	NSString *expectedName;
	if (ioRootName != NULL)  expectedName = *ioRootName;
	if (![parser parseWithSchema:schema expectedRootName:expectedName error:outError])
	{
		return nil;
	}
	
	if (ioRootName != NULL)  *ioRootName = parser.rootName;
	return parser.root;
}

@end


@implementation JANBTStreamParser
{
	id						_result;
	NSString				*_rootName;
	NSMutableData			*_readBuffer;
	NSMutableData			*_expandBuffer;
	NSInputStream			*_stream;
	z_stream				_zstream;
	uInt					_readCursor;
	NSError					*_error;
	BOOL					_mutableContainers;
	BOOL					_mutableLeaves;
	BOOL					_allowFragments;
}


- (id) initWithStream:(NSInputStream *)stream options:(JANBTReadingOptions)options
{
	NSParameterAssert(stream != nil);
	
	if ((self = [super init]))
	{
		_readBuffer = [NSMutableData dataWithLength:kBufferLength];
		_expandBuffer = [NSMutableData dataWithLength:kBufferLength];
		if (_readBuffer == nil || _expandBuffer == nil)  return nil;
		
		_zstream.next_in = _readBuffer.mutableBytes;
		_zstream.next_out = _expandBuffer.mutableBytes;
		_zstream.avail_out = kBufferLength;
		int zerror = inflateInit2(&_zstream, 31);
		if (zerror != Z_OK)  return nil;
		
		_stream = stream;
		_mutableContainers = options & kJANBTReadingMutableContainers;
		_mutableLeaves = options & kJANBTReadingMutableLeaves;
		_allowFragments = options & kJANBTReadingAllowFragments;
	}
	return self;
}


- (void) dealloc
{
	[self cleanUp];
}


- (void) cleanUp
{
	inflateEnd(&_zstream);
	_stream.delegate = nil;
	_stream = nil;
	_readBuffer = nil;
	_expandBuffer = nil;
	_error = nil;
}


- (void) setErrorIfClear:(NSInteger)errorCode format:(NSString *)format, ...
{
	if (_error != nil)  return;
	
	NSString *message;
	if (format != nil)
	{
		format = [[NSBundle bundleForClass:[JANBTSerialization class]] localizedStringForKey:format value:format table:nil];
		va_list args;
		va_start(args, format);
		message = [[NSString alloc] initWithFormat:format arguments:args];
		va_end(args);
	}
	
	_error = [NSError errorWithDomain:kJANBTSerializationErrorDomain code:errorCode userInfo:$dict(NSLocalizedDescriptionKey, message)];
}


@synthesize root = _result, rootName = _rootName;


- (BOOL) parseWithSchema:(id)schema expectedRootName:(NSString *)expectedName error:(NSError **)outError
{
	NSError *error;
	BOOL OK;
	
	@autoreleasepool
	{
		[_stream open];
		OK = [self parseWithSchemaInner:schema expectedRootName:expectedName];
		if (!OK)  error = _error;
		[self cleanUp];
	}
	
	if (!OK && outError != NULL)  *outError = error;
	return OK;
}


- (BOOL) parseWithSchemaInner:(id)schema expectedRootName:(NSString *)expectedName
{
	int8_t rootType;
	REQUIRE([self readByte:&rootType]);
	
	REQUIRE_ERR(rootType == kJANBTTagCompound || _allowFragments, kJANBTSerializationWrongTypeError, @"NBT root is not a compound, and fragments are not permitted.");
	
	if (rootType != kJANBTTagEnd)
	{
		REQUIRE(_rootName = [self readStringMutable:NO]);
		REQUIRE_ERR(expectedName == nil || [_rootName isEqualToString:expectedName], kJANBTSerializationWrongRootNameError, @"Expected NBT root name to be %@, but found %@.", expectedName, _rootName);
		
		REQUIRE(_result = [self parseOneTagBodyOfType:rootType withSchema:schema]);
	}
	// else empty fragment; result is nil.
	
	return YES;
}


- (id) parseOneTagBodyOfType:(JANBTTagType)type withSchema:(id)schema
{
	switch (type)
	{
		case kJANBTTagByte:
			return [self parseByteWithSchema:schema];
			
		case kJANBTTagShort:
			return [self parseShortWithSchema:schema];
			
		case kJANBTTagInt:
			return [self parseIntWithSchema:schema];
			
		case kJANBTTagLong:
			return [self parseLongWithSchema:schema];
			
		case kJANBTTagFloat:
			return [self parseFloatWithSchema:schema];
			
		case kJANBTTagDouble:
			return [self parseDoubleWithSchema:schema];
			
		case kJANBTTagByteArray:
			return [self parseByteArrayWithSchema:schema];
			
		case kJANBTTagString:
			return [self parseStringWithSchema:schema];
			
		case kJANBTTagList:
			return [self parseListWithSchema:schema];
			
		case kJANBTTagCompound:
			return [self parseCompoundWithSchema:schema];
			
		case kJANBTTagEnd:
		case kJANBTTagAny:
		case kJANBTTagUnknown:
			;
	}
	
	[self setErrorIfClear:kJANBTSerializationUnknownTagError format:@"Unknown NBT tag %u.", type];
	return nil;
}


#define REQUIRE_SCHEMA(COND, EXPECTED, GOT)  REQUIRE_ERR(COND, kJANBTSerializationWrongTypeError, @"Wrong type in NBT - expected %@, got %@.", EXPECTED, TypeNameFromSchema(GOT))
#define REQUIRE_NUMERICAL_SCHEMA(SCH)  REQUIRE_SCHEMA(IsNumericalSchema(SCH), @"numerical type", SCH)


- (NSNumber *) parseByteWithSchema:(id)schema
{
	REQUIRE_NUMERICAL_SCHEMA(schema);
	
	int8_t value;
	REQUIRE([self readByte:&value]);
	if (schema != nil)  return [NSNumber numberWithChar:value];
	else  return [[JANBTInteger alloc] initWithValue:value type:kJANBTTagByte];
}


- (NSNumber *) parseShortWithSchema:(id)schema
{
	REQUIRE_NUMERICAL_SCHEMA(schema);
	
	int16_t value;
	REQUIRE([self readShort:&value]);
	if (schema != nil)  return [NSNumber numberWithShort:value];
	else  return [[JANBTInteger alloc] initWithValue:value type:kJANBTTagShort];
}


- (NSNumber *) parseIntWithSchema:(id)schema
{
	REQUIRE_NUMERICAL_SCHEMA(schema);
	
	int32_t value;
	REQUIRE([self readInt:&value]);
	if (schema != nil)  return [NSNumber numberWithInt:value];
	else  return [[JANBTInteger alloc] initWithValue:value type:kJANBTTagInt];
}


- (NSNumber *) parseLongWithSchema:(id)schema
{
	REQUIRE_NUMERICAL_SCHEMA(schema);
	
	int64_t value;
	REQUIRE([self readLong:&value]);
	if (schema != nil)  return [NSNumber numberWithLong:value];
	else  return [[JANBTInteger alloc] initWithValue:value type:kJANBTTagLong];
}


- (NSNumber *) parseFloatWithSchema:(id)schema
{
	REQUIRE_NUMERICAL_SCHEMA(schema);
	
	float value;
	REQUIRE([self readFloat:&value]);
	if (schema != nil)  return [NSNumber numberWithFloat:value];
	else  return [[JANBTFloat alloc] initWithValue:value];
}


- (NSNumber *) parseDoubleWithSchema:(id)schema
{
	REQUIRE_NUMERICAL_SCHEMA(schema);
	
	double value;
	REQUIRE([self readDouble:&value]);
	if (schema != nil)  return [NSNumber numberWithDouble:value];
	else  return [[JANBTDouble alloc] initWithValue:value];
}


- (NSData *) parseByteArrayWithSchema:(id)schema
{
	REQUIRE_SCHEMA(schema == nil || [schema isEqual:@"data"], @"byte array", schema);
	
	uint32_t length;
	REQUIRE([self readInt:(int32_t *)&length]);
	void *bytes = malloc(length);
	REQUIRE_ERR(bytes, kJANBTSerializationMemoryError, @"Not enough memory for byte array of length %u.", length);
	
	if ([self readBytes:bytes length:length])
	{
		Class dataClass = _mutableLeaves ? [NSMutableData class] : [NSData class];
		return [[dataClass alloc] initWithBytesNoCopy:bytes length:length freeWhenDone:YES];
	}
	else
	{
		free(bytes);
		return nil;
	}
}


- (NSString *) parseStringWithSchema:(id)schema
{
	REQUIRE_SCHEMA(schema == nil || [schema isEqual:@"string"], @"string", schema);
	return [self readStringMutable:_mutableLeaves];
}


- (NSArray *) parseListWithSchema:(id)schema
{
	REQUIRE_SCHEMA(schema == nil || ([schema isKindOfClass:[NSArray class]] && [schema count] == 1), @"list", schema);
	
	int8_t type;
	uint32_t i, count;
	REQUIRE([self readByte:&type]);
	REQUIRE([self readInt:(int32_t *)&count]);
	
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
	schema = [schema objectAtIndex:0];
	
	for (i = 0; i < count; i++)
	{
		id value = [self parseOneTagBodyOfType:type withSchema:schema];
		REQUIRE(value);
		[array addObject:value];
	}
	
	if (!_mutableContainers)  array = [array copy];
	return array;
}


- (NSDictionary *) parseCompoundWithSchema:(id)schema
{
	REQUIRE_SCHEMA(schema == nil || [schema isKindOfClass:[NSDictionary class]], @"compound", schema);
	
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	
	for (;;)
	{
		int8_t type;
		REQUIRE([self readByte:&type]);
		if (type == kJANBTTagEnd)  break;
		
		@autoreleasepool
		{
			NSString *key = [self readStringMutable:NO];
			REQUIRE(key);
			id value = [self parseOneTagBodyOfType:type withSchema:[schema objectForKey:key]];
			REQUIRE(value);
			[dictionary setObject:value forKey:key];
		}
	}
	
	if (!_mutableContainers)  dictionary = [dictionary copy];
	return dictionary;
}


- (BOOL) readByte:(int8_t *)value
{
	NSParameterAssert(value != NULL);
	return [self readBytes:value length:sizeof *value];
}


- (BOOL) readShort:(int16_t *)value
{
	NSParameterAssert(value != NULL);
	uint16_t raw;
	REQUIRE([self readBytes:&raw length:sizeof raw]);
	*value = CFSwapInt16BigToHost(raw);
	return YES;
}


- (BOOL) readInt:(int32_t *)value
{
	NSParameterAssert(value != NULL);
	uint32_t raw;
	REQUIRE([self readBytes:&raw length:sizeof raw]);
	*value = CFSwapInt32BigToHost(raw);
	return YES;
}


- (BOOL) readLong:(int64_t *)value
{
	NSParameterAssert(value != NULL);
	uint64_t raw;
	REQUIRE([self readBytes:&raw length:sizeof raw]);
	*value = CFSwapInt64BigToHost(raw);
	return YES;
}


- (BOOL) readFloat:(Float32 *)value
{
	NSParameterAssert(value != NULL);
	union { int32_t i; Float32 f; } convert;
	REQUIRE([self readInt:&convert.i]);
	*value = convert.f;
	return YES;
}


- (BOOL) readDouble:(Float64 *)value
{
	NSParameterAssert(value != NULL);
	union { int64_t i; Float64 f; } convert;
	REQUIRE([self readLong:&convert.i]);
	*value = convert.f;
	return YES;
}


- (NSString *) readStringMutable:(BOOL)mutable
{
	uint16_t length;
	REQUIRE([self readShort:(int16_t *)&length]);
	char *bytes = malloc(length);
	REQUIRE_ERR(bytes, kJANBTSerializationMemoryError, @"Not enough memory for string of length %u.", length);
	
	if ([self readBytes:bytes length:length])
	{
		Class stringClass = mutable ? [NSMutableString class] : [NSString class];
		return [[stringClass alloc] initWithBytesNoCopy:bytes length:length encoding:NSUTF8StringEncoding freeWhenDone:YES];
	}
	else
	{
		free(bytes);
		return nil;
	}
}


- (BOOL) readBytes:(void *)bytes length:(NSUInteger)length
{
	NSParameterAssert(bytes != NULL);
	char *next = bytes;
	
	while (length > 0)
	{
		size_t pending = kBufferLength - _zstream.avail_out;
		
		if (pending != 0)
		{
			NSUInteger toCopy = MIN(pending, length);
			bcopy(_expandBuffer.bytes + _readCursor, next, toCopy);
			
			next += toCopy;
			_readCursor += toCopy;
			length -= toCopy;
			
			if (_zstream.avail_out == 0)
			{
				_zstream.next_out = _expandBuffer.mutableBytes;
				_zstream.avail_out = kBufferLength;
				_readCursor = 0;
			}
		}
		else
		{
			if (_zstream.avail_in == 0)
			{
				_zstream.next_in = _readBuffer.mutableBytes;
				NSInteger status = [_stream read:_zstream.next_in maxLength:kBufferLength];
				if (status > 1)  _zstream.avail_in = status;
				else  REQUIRE_ERR(status == 0, kJANBTSerializationUnexpectedEOFError, @"Premature end of file.");
			}
			
			int zstate = inflate(&_zstream, Z_SYNC_FLUSH);
			REQUIRE_ERR(zstate == Z_OK || zstate == Z_STREAM_END, kJANBTSerializationUnexpectedEOFError, @"Zlib error %i.", zstate);
		}
	}
	
	return YES;
}

@end


@implementation JANBTInteger
{
	NSInteger					_value;
	JANBTTagType				_type;
}


- (id) initWithValue:(NSInteger)value type:(JANBTTagType)type
{
	if ((self = [super init]))
	{
		_value = value;
		_type = type;
	}
	return self;
}


- (void) getValue:(void *)value
{
	if (__builtin_expect(value == NULL, 0))  return;
	
	switch (_type)
	{
		case kJANBTTagByte:
			*(int8_t *)value = _value;
			break;
			
		case kJANBTTagShort:
			*(int16_t *)value = _value;
			break;
			
		case kJANBTTagInt:
			*(int32_t *)value = _value;
			break;
			
		case kJANBTTagLong:
			*(int64_t *)value = _value;
			break;
			
		default:
			[NSException raise:NSInternalInconsistencyException format:@"JANBTInteger has non-integer type"];
	}
}


- (const char *) objCType
{
	switch (_type)
	{
		case kJANBTTagByte:
			return @encode(int8_t);
			
		case kJANBTTagShort:
			return @encode(int16_t);
			
		case kJANBTTagInt:
			return @encode(int32_t);
			
		case kJANBTTagLong:
			return @encode(int64_t);
			
		default:
			[NSException raise:NSInternalInconsistencyException format:@"JANBTInteger has non-integer type"];
			__builtin_unreachable();
	}
}


- (char) charValue
{
	return _value;
}


- (unsigned char) unsignedCharValue
{
	return _value;
}


- (short) shortValue
{
	return _value;
}


- (unsigned short) unsignedShortValue
{
	return _value;
}


- (int) intValue
{
	return _value;
}


- (unsigned int) unsignedIntValue
{
	return _value;
}


- (long) longValue
{
	return _value;
}


- (unsigned long) unsignedLongValue
{
	return _value;
}


- (long long) longLongValue
{
	return _value;
}


- (unsigned long long) unsignedLongLongValue
{
	return _value;
}


- (float) floatValue
{
	return _value;
}


- (double) doubleValue
{
	return _value;
}


- (BOOL) boolValue
{
	return _value != 0;
}


- (NSInteger) integerValue
{
	return _value;
}


- (NSUInteger) unsignedIntegerValue
{
	return _value;
}


- (NSString *)stringValue
{
	return $sprintf(@"%llu", _value);
}


- (JANBTTagType) ja_NBTType
{
	return _type;
}

@end


@implementation JANBTFloat
{
	Float32						_value;
}

- (id) initWithValue:(Float32)value
{
	if ((self = [super init]))
	{
		_value = value;
	}
	return self;
}


- (void) getValue:(void *)value
{
	if (__builtin_expect(value == NULL, 0))  return;
	*(Float32 *)value = _value;
}


- (const char *) objCType
{
	return @encode(Float32);
}


- (char) charValue
{
	return _value;
}


- (unsigned char) unsignedCharValue
{
	return _value;
}


- (short) shortValue
{
	return _value;
}


- (unsigned short) unsignedShortValue
{
	return _value;
}


- (int) intValue
{
	return _value;
}


- (unsigned int) unsignedIntValue
{
	return _value;
}


- (long) longValue
{
	return _value;
}


- (unsigned long) unsignedLongValue
{
	return _value;
}


- (long long) longLongValue
{
	return _value;
}


- (unsigned long long) unsignedLongLongValue
{
	return _value;
}


- (float) floatValue
{
	return _value;
}


- (double) doubleValue
{
	return _value;
}


- (BOOL) boolValue
{
	return _value != 0;
}


- (NSInteger) integerValue
{
	return _value;
}


- (NSUInteger) unsignedIntegerValue
{
	return _value;
}


- (JANBTTagType) ja_NBTType
{
	return kJANBTTagFloat;
}

@end


@implementation JANBTDouble
{
	Float64						_value;
}

- (id) initWithValue:(Float64)value
{
	if ((self = [super init]))
	{
		_value = value;
	}
	return self;
}


- (void) getValue:(void *)value
{
	if (__builtin_expect(value == NULL, 0))  return;
	*(Float64 *)value = _value;
}


- (const char *) objCType
{
	return @encode(Float64);
}


- (char) charValue
{
	return _value;
}


- (unsigned char) unsignedCharValue
{
	return _value;
}


- (short) shortValue
{
	return _value;
}


- (unsigned short) unsignedShortValue
{
	return _value;
}


- (int) intValue
{
	return _value;
}


- (unsigned int) unsignedIntValue
{
	return _value;
}


- (long) longValue
{
	return _value;
}


- (unsigned long) unsignedLongValue
{
	return _value;
}


- (long long) longLongValue
{
	return _value;
}


- (unsigned long long) unsignedLongLongValue
{
	return _value;
}


- (float) floatValue
{
	return _value;
}


- (double) doubleValue
{
	return _value;
}


- (BOOL) boolValue
{
	return _value != 0;
}


- (NSInteger) integerValue
{
	return _value;
}


- (NSUInteger) unsignedIntegerValue
{
	return _value;
}


- (JANBTTagType) ja_NBTType
{
	return kJANBTTagDouble;
}

@end


@implementation NSNumber (JANBTNumberType)

- (JANBTTagType) ja_NBTType
{
	const char *type = self.objCType;
	if (strcmp(type, @encode(float)) == 0)
	{
		return kJANBTTagFloat;
	}
	else if (strcmp(type, @encode(double)) == 0)
	{
		return kJANBTTagDouble;
	}
	else if (strcmp(type, @encode(long double)) == 0)
	{
		return kJANBTTagDouble;
	}
	
	NSInteger value = self.integerValue;
	if (INT8_MIN <= value && value <= INT8_MAX)  return kJANBTTagByte;
	else if (INT16_MIN <= value && value <= INT16_MAX)  return kJANBTTagShort;
	else if (INT32_MIN <= value && value <= INT32_MAX)  return kJANBTTagInt;
	else return kJANBTTagLong;
}

@end


@implementation NSObject (JANBTInternal)

- (JANBTTagType) ja_NBTSchemaType
{
	return kJANBTTagUnknown;
}

@end


@implementation NSArray (JANBTInternal)

- (JANBTTagType) ja_NBTSchemaType
{
	return kJANBTTagList;
}

@end


@implementation NSDictionary (JANBTInternal)

- (JANBTTagType) ja_NBTSchemaType
{
	return kJANBTTagCompound;
}

@end


@implementation NSString (JANBTInternal)

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


static void SetError(NSError **outError, NSInteger errorCode, NSString *format, ...)
{
	if (outError != nil)
	{
		NSString *message;
		if (format != nil)
		{
			format = [[NSBundle bundleForClass:[JANBTSerialization class]] localizedStringForKey:format value:format table:nil];
			va_list args;
			va_start(args, format);
			message = [[NSString alloc] initWithFormat:format arguments:args];
			va_end(args);
		}
		
		*outError = [NSError errorWithDomain:kJANBTSerializationErrorDomain code:errorCode userInfo:$dict(NSLocalizedDescriptionKey, message)];
	}
}


static inline BOOL IsNumericalSchema(id schema)
{
	if (schema != nil)
	{
		JANBTTagType type = [schema ja_NBTSchemaType];
		return kJANBTTagByte <= type && type <= kJANBTTagDouble;
	}
	return YES;
}


static NSString *TypeNameFromSchema(id schema)
{
	return NameFromTagType(schema ? [schema ja_NBTSchemaType] : kJANBTTagAny);
}


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
			
		case kJANBTTagAny:
			return @"wildcard";
			
		case kJANBTTagUnknown:
			;
			// Fall through
	}
	
	return @"**UNKNOWN TAG**";
}
