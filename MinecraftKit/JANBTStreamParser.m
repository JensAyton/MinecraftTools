/*
	JANBTStreamParser.m
	
	
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

#import "JANBTStreamParser.h"
#import "JANBTTagType.h"
#import "JANBTTypedNumbers.h"
#include <zlib.h>
#import "MYCollectionUtilities.h"


static inline BOOL IsNumericalSchema(id schema);


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
#define REQUIRE_ERR(COND, ERRCODE, FORMAT...) do { if (__builtin_expect(!(COND), 0)) { [self setErrorIfClear:ERRCODE underlyingError:nil format:FORMAT]; return 0; }} while (0)

#define REQUIRE(COND) do { if (__builtin_expect(!(COND), 0))  return 0; } while (0)


@interface JANBTStreamParser ()

- (BOOL) parseWithSchemaInner:(id)schema expectedRootName:(NSString *)expectedName  __attribute__((warn_unused_result));
- (id) parseOneTagBodyOfType:(JANBTTagType)type withSchema:(id)schema;

- (void) cleanUp;
- (void) setErrorIfClear:(NSInteger)errorCode underlyingError:(NSError *)underlyingError format:(NSString *)format, ... NS_FORMAT_FUNCTION(3, 4);

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


@implementation JANBTStreamParser
{
	id						_result;
	NSString				*_rootName;
	NSInputStream			*_stream;
	NSMutableData			*_readBuffer;
	NSMutableData			*_expandBuffer;
	NSError					*_error;
	z_stream				_zstream;
	uInt					_readCursor;
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
		int zstatus = inflateInit2(&_zstream, 31);
		if (zstatus != Z_OK)  return nil;
		
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


- (void) setErrorIfClear:(NSInteger)errorCode underlyingError:(NSError *)underlyingError format:(NSString *)format, ...
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
	
	_error = [NSError errorWithDomain:kJANBTSerializationErrorDomain code:errorCode userInfo:$dict(NSLocalizedDescriptionKey, message, NSUnderlyingErrorKey, underlyingError)];
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
	
	[self setErrorIfClear:kJANBTSerializationUnknownTagError underlyingError:nil format:@"Unknown NBT tag %u.", type];
	return nil;
}


#define REQUIRE_SCHEMA(COND, GOT, SCH)  REQUIRE_ERR(COND, kJANBTSerializationWrongTypeError, @"Wrong type in NBT - expected %@, got %@.", JANBTTagNameFromSchema(SCH), GOT)
#define REQUIRE_NUMERICAL_SCHEMA(SCH)  REQUIRE_SCHEMA(JANBTIsNumericalSchema(SCH), @"numerical type", SCH)


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
	REQUIRE_SCHEMA(schema == nil || [schema isEqual:@"data"], @"TAG_Byte_Array", schema);
	
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
	REQUIRE_SCHEMA(schema == nil || [schema isEqual:@"string"], @"TAG_String", schema);
	return [self readStringMutable:_mutableLeaves];
}


- (NSArray *) parseListWithSchema:(id)schema
{
	REQUIRE_SCHEMA(schema == nil || ([schema isKindOfClass:[NSArray class]] && [schema count] == 1), @"TAG_List", schema);
	
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
	if (schema == nil)  array.ja_NBTListElementType = type;
	return array;
}


- (NSDictionary *) parseCompoundWithSchema:(id)schema
{
	REQUIRE_SCHEMA(schema == nil || [schema isKindOfClass:[NSDictionary class]], @"TAG_Compound", schema);
	
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
				if (status > 0)  _zstream.avail_in = status;
				else
				{
					if (status == 0)  [self setErrorIfClear:kJANBTSerializationReadError
											underlyingError:nil
													 format:@"Premature end of file."];
					else  [self setErrorIfClear:kJANBTSerializationReadError
								underlyingError:_stream.streamError
										 format:@"Read error."];
						return NO;
				}
			}
			
			int zstatus = inflate(&_zstream, Z_SYNC_FLUSH);
			REQUIRE_ERR(zstatus == Z_OK || zstatus == Z_STREAM_END, kJANBTSerializationCompressionError, @"Zlib error %i.", zstatus);
		}
	}
	
	return YES;
}

@end
