/*
	JANBTStreamParser.m
	
	
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

#import "JANBTStreamParser.h"
#import "JANBTTagType.h"
#import "JANBTTypedNumbers.h"
#import "JAZLibCompressor.h"


#define LOG_PARSING 0
#if LOG_PARSING
static void ParseLog(NSString *message, NSInteger indent, NSUInteger offset);
#define PARSE_LOG(format...) ParseLog([NSString stringWithFormat:format], _parseLogIndent, _decompressor.rawBytesRead);
#define PARSE_LOG_INDENT() do { _parseLogIndent++; } while (0)
#define PARSE_LOG_OUTDENT() do { _parseLogIndent--; } while (0)
#else
#define PARSE_LOG(...) do {} while (0)
#define PARSE_LOG_INDENT() do {} while (0)
#define PARSE_LOG_OUTDENT() do {} while (0)
#endif



static inline BOOL IsNumericalSchema(id schema);


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


@implementation JANBTStreamParser
{
	id						_result;
	NSString				*_rootName;
	JAZlibDecompressor		*_decompressor;
	NSError					*_error;
	NSMutableArray			*_keyPath;
	BOOL					_mutableContainers;
	BOOL					_mutableLeaves;
	BOOL					_allowFragments;
	
#if LOG_PARSING
	NSInteger				_parseLogIndent;
#endif
}


- (id) initWithStream:(NSInputStream *)stream options:(JANBTReadingOptions)options
{
	NSParameterAssert(stream != nil);
	
	if ((self = [super init]))
	{
		_decompressor = [[JAZlibDecompressor alloc] initWithStream:stream mode:kJAZLibCompressionAutoDetect];
		
		_mutableContainers = options & kJANBTReadingMutableContainers;
		_mutableLeaves = options & kJANBTReadingMutableLeaves;
		_allowFragments = options & kJANBTReadingAllowFragments;
		
		_keyPath = [NSMutableArray new];
	}
	return self;
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
	
	_error = [NSError errorWithDomain:kJANBTSerializationErrorDomain
								 code:errorCode
							 userInfo:@{ NSLocalizedDescriptionKey: message,
										 NSUnderlyingErrorKey: underlyingError ?: @"" }];
}


@synthesize root = _result, rootName = _rootName;


- (BOOL) parseWithSchema:(id)schema expectedRootName:(NSString *)expectedName error:(NSError **)outError
{
	NSError *error;
	BOOL OK;
	
	@autoreleasepool
	{
		OK = [self parseWithSchemaInner:schema expectedRootName:expectedName];
		if (!OK)  error = _error;
		_decompressor = nil;
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
		
		PARSE_LOG(@"Root %@ [%@] =", _rootName, JANBTTagNameFromTagType(rootType));
		PARSE_LOG_INDENT();
		
		REQUIRE(_result = [self parseOneTagBodyOfType:rootType withSchema:schema]);
		
		PARSE_LOG_OUTDENT();
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
			
		case kJANBTTagIntArray:
			return [self parseIntArrayWithSchema:schema];
			
		case kJANBTTagIntArrayContent:
		case kJANBTTagEnd:
		case kJANBTTagAny:
		case kJANBTTagUnknown:
			;
	}
	
	[self setErrorIfClear:kJANBTSerializationUnknownTagError underlyingError:nil format:@"Unknown NBT tag %u.", type];
	return nil;
}


#define REQUIRE_SCHEMA(COND, GOT, SCH)  REQUIRE_ERR(COND, kJANBTSerializationWrongTypeError, @"Wrong type in NBT - expected %@, got %@ - at %@.", JANBTTagNameFromSchema(SCH), GOT, self.currentKeyPath)
#define REQUIRE_NUMERICAL_SCHEMA(SCH)  REQUIRE_SCHEMA(JANBTIsNumericalSchema(SCH), @"numerical type", SCH)

#define PUSH_PATH(FORMAT, ELEM)	do { [_keyPath addObject:FORMAT]; [_keyPath addObject:ELEM]; } while (0)
#define POP_PATH()				do { [_keyPath removeLastObject]; [_keyPath removeLastObject]; } while (0)


- (NSString *) currentKeyPath
{
	NSMutableString *result = [NSMutableString stringWithString:_rootName];
	
	for (NSUInteger i = 0; i < _keyPath.count; i += 2)
	{
		NSString *format = _keyPath[i];
		id value = _keyPath[i + 1];
		[result appendString:[format stringByReplacingOccurrencesOfString:@"%@" withString:[value description]]];
	}
	
	return result;
}


- (NSNumber *) parseByteWithSchema:(id)schema
{
	REQUIRE_NUMERICAL_SCHEMA(schema);
	
	int8_t value;
	REQUIRE([self readByte:&value]);
	PARSE_LOG(@"BYTE: %i", value);
	if (schema != nil)  return [NSNumber numberWithChar:value];
	else  return [[JANBTInteger alloc] initWithValue:value type:kJANBTTagByte];
}


- (NSNumber *) parseShortWithSchema:(id)schema
{
	REQUIRE_NUMERICAL_SCHEMA(schema);
	
	int16_t value;
	REQUIRE([self readShort:&value]);
	PARSE_LOG(@"SHORT: %i", value);
	if (schema != nil)  return [NSNumber numberWithShort:value];
	else  return [[JANBTInteger alloc] initWithValue:value type:kJANBTTagShort];
}


- (NSNumber *) parseIntWithSchema:(id)schema
{
	REQUIRE_NUMERICAL_SCHEMA(schema);
	
	int32_t value;
	REQUIRE([self readInt:&value]);
	PARSE_LOG(@"INT: %i", value);
	if (schema != nil)  return [NSNumber numberWithInt:value];
	else  return [[JANBTInteger alloc] initWithValue:value type:kJANBTTagInt];
}


- (NSNumber *) parseLongWithSchema:(id)schema
{
	REQUIRE_NUMERICAL_SCHEMA(schema);
	
	int64_t value;
	REQUIRE([self readLong:&value]);
	PARSE_LOG(@"BYTE: %lli", value);
	if (schema != nil)  return [NSNumber numberWithLong:value];
	else  return [[JANBTInteger alloc] initWithValue:value type:kJANBTTagLong];
}


- (NSNumber *) parseFloatWithSchema:(id)schema
{
	REQUIRE_NUMERICAL_SCHEMA(schema);
	
	float value;
	REQUIRE([self readFloat:&value]);
	PARSE_LOG(@"FLOAT: %g", value);
	if (schema != nil)  return [NSNumber numberWithFloat:value];
	else  return [[JANBTFloat alloc] initWithValue:value];
}


- (NSNumber *) parseDoubleWithSchema:(id)schema
{
	REQUIRE_NUMERICAL_SCHEMA(schema);
	
	double value;
	REQUIRE([self readDouble:&value]);
	PARSE_LOG(@"DOUBLE: %g", value);
	if (schema != nil)  return [NSNumber numberWithDouble:value];
	else  return [[JANBTDouble alloc] initWithValue:value];
}


- (NSData *) parseByteArrayWithSchema:(id)schema
{
	REQUIRE_SCHEMA(schema == nil || [schema isEqual:@"data"], @"TAG_Byte_Array", schema);
	
	uint32_t length;
	REQUIRE([self readInt:(int32_t *)&length]);
	PARSE_LOG(@"BYTE ARRAY: %u bytes", length);
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
	id result = [self readStringMutable:_mutableLeaves];
	PARSE_LOG(@"STRING: %@", result);
	return result;
}


- (NSArray *) parseListWithSchema:(id)schema
{
	REQUIRE_SCHEMA(schema == nil || ([schema isKindOfClass:[NSArray class]] && [schema count] == 1), @"TAG_List", schema);
	
	int8_t type;
	uint32_t i, count;
	REQUIRE([self readByte:&type]);
	REQUIRE([self readInt:(int32_t *)&count]);
	
	PARSE_LOG(@"ARRAY: %u x %@", count, JANBTTagNameFromTagType(type));
	PARSE_LOG_INDENT();
	
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
	schema = [schema objectAtIndex:0];
	
	for (i = 0; i < count; i++)
	{
		PUSH_PATH(@"[%@]", @(i));
		
		id value = [self parseOneTagBodyOfType:type withSchema:schema];
		REQUIRE(value);
		[array addObject:value];
		
		POP_PATH();
	}
	
	PARSE_LOG_OUTDENT();
	
	if (!_mutableContainers)  array = [array copy];
	if (schema == nil)  array.NBTListElementType = type;
	return array;
}


- (NSDictionary *) parseCompoundWithSchema:(id)schema
{
	REQUIRE_SCHEMA(schema == nil || [schema isKindOfClass:[NSDictionary class]], @"TAG_Compound", schema);
	
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	
	PARSE_LOG(@"COMPOUND:");
	PARSE_LOG_INDENT();
	
	for (;;)
	{
		int8_t type;
		REQUIRE([self readByte:&type]);
		if (type == kJANBTTagEnd)  break;
		
		@autoreleasepool
		{
			NSString *key = [self readStringMutable:NO];
			PUSH_PATH(@".%@", key);
			
			PARSE_LOG(@"%@ [%@] =", key, JANBTTagNameFromTagType(type));
			REQUIRE(key);
			id value = [self parseOneTagBodyOfType:type withSchema:[schema objectForKey:key]];
			REQUIRE(value);
			[dictionary setObject:value forKey:key];
			
			POP_PATH();
		}
	}
	
	PARSE_LOG_OUTDENT();
	
	if (!_mutableContainers)  dictionary = [dictionary copy];
	return dictionary;
}


- (NSArray *) parseIntArrayWithSchema:(id)schema
{
	REQUIRE_SCHEMA(schema == nil || [schema isEqual:@"intarray"], @"TAG_Int_Array", schema);
	
	uint32_t i, count;
	REQUIRE([self readInt:(int32_t *)&count]);
	
	PARSE_LOG(@"INTARRAY: %u x int", count);
	PARSE_LOG_INDENT();
	
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:count];
	
	for (i = 0; i < count; i++)
	{
		int32_t value;
		REQUIRE([self readInt:&value]);
		[array addObject:@(value)];
	}
	
	PARSE_LOG_OUTDENT();
	
	if (!_mutableContainers)  array = [array copy];
	array.NBTListElementType = kJANBTTagIntArrayContent;
	return array;
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
	NSParameterAssert(length <= NSIntegerMax);
	
	NSError *error;
	NSInteger read = [_decompressor read:bytes length:length error:&error];
	if (read == (NSInteger)length)  return YES;
	
	if (read >= 0)  [self setErrorIfClear:kJANBTSerializationReadError
						  underlyingError:nil
								   format:@"Premature end of file."];
	else  [self setErrorIfClear:kJANBTSerializationReadError
				underlyingError:error
						 format:@"Read error."];
	
	return NO;
}

@end


#if LOG_PARSING
static NSString *IndentString(NSUInteger count);
static void ParseLog(NSString *message, NSInteger indent, NSUInteger offset)
{
	message = [NSString stringWithFormat:@"%@[%lu] %@", IndentString(indent), offset, message];
	puts([message UTF8String]);
}


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
#endif
