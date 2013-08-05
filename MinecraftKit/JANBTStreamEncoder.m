/*
	JANBTStreamEncoder.m
	
	
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

#import "JANBTStreamEncoder.h"
#import "JANBTTagType.h"
#include <zlib.h>
#import "MYCollectionUtilities.h"
#import "JAZLibCompressor.h"


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


@interface JANBTStreamEncoder ()

- (void) setErrorIfClear:(NSInteger)errorCode underlyingError:(NSError *)underlyingError format:(NSString *)format, ... NS_FORMAT_FUNCTION(3, 4);

- (BOOL) encodeObjectInner:(id)root withSchema:(id)schema rootName:(NSString *)rootName;

- (BOOL) encodeOneTagBody:(id)value ofType:(JANBTTagType)type withSchema:(id)schema;
- (BOOL) encodeByte:(NSNumber *)value withSchema:(id)schema;
- (BOOL) encodeShort:(NSNumber *)value withSchema:(id)schema;
- (BOOL) encodeInt:(NSNumber *)value withSchema:(id)schema;
- (BOOL) encodeLong:(NSNumber *)value withSchema:(id)schema;
- (BOOL) encodeFloat:(NSNumber *)value withSchema:(id)schema;
- (BOOL) encodeDouble:(NSNumber *)value withSchema:(id)schema;
- (BOOL) encodeByteArray:(NSData *)value withSchema:(id)schema;
- (BOOL) encodeString:(NSString *)value withSchema:(id)schema;
- (BOOL) encodeList:(NSArray *)value withSchema:(id)schema;
- (BOOL) encodeCompound:(NSDictionary *)value withSchema:(id)schema;

- (BOOL) writeByte:(uint8_t)value __attribute__((warn_unused_result));
- (BOOL) writeShort:(uint16_t)value __attribute__((warn_unused_result));
- (BOOL) writeInt:(uint32_t)value __attribute__((warn_unused_result));
- (BOOL) writeLong:(uint64_t)value __attribute__((warn_unused_result));
- (BOOL) writeFloat:(Float32)value __attribute__((warn_unused_result));
- (BOOL) writeDouble:(Float64)value __attribute__((warn_unused_result));
- (BOOL) writeString:(NSString *)value __attribute__((nonnull, warn_unused_result));
- (BOOL) writeBytes:(const void *)bytes length:(NSUInteger)length __attribute__((nonnull, warn_unused_result));

@end


static JANBTTagType NormalizedTagType(id value, id schema);


@implementation JANBTStreamEncoder
{
	JAZLibCompressor			*_compressor;
	NSError						*_error;
}


- (id) initWithStream:(NSOutputStream *)stream options:(JANBTWritingOptions)options
{
	if ((self = [super init]))
	{
		if (stream != nil)
		{
			_compressor = [[JAZLibCompressor alloc] initWithStream:stream mode:kJAZLibCompressionGZip];
			if (_compressor == nil)  return nil;
		}
	}
	
	return self;
}


- (BOOL) encodeObject:(id)root withSchema:(id)schema rootName:(NSString *)rootName error:(NSError **)outError
{
	BOOL OK;
	
	@autoreleasepool
	{
		OK = [self encodeObjectInner:root withSchema:schema rootName:rootName];
		if (OK && _compressor != nil)
		{
			NSError __autoreleasing *error;
			OK = [_compressor flushWithError:&error];
			if (!OK)  _error = error;
		}
	}
	
	if (!OK && outError != NULL)  *outError = _error;
	return OK;
}


- (NSUInteger) bytesWritten
{
	return _compressor.compressedBytesWritten;
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
							 userInfo:@{ NSLocalizedDescriptionKey: message, NSUnderlyingErrorKey: underlyingError }];
}


- (BOOL) encodeObjectInner:(id)root withSchema:(id)schema rootName:(NSString *)rootName
{
	JANBTTagType rootType = NormalizedTagType(root, schema);
	REQUIRE_ERR(JANBTIsKnownTagType(rootType), kJANBTSerializationWrongTypeError, @"Object is not an NBT value.");
	REQUIRE([self writeByte:rootType]);
	REQUIRE([self writeString:rootName]);
	
	REQUIRE([self encodeOneTagBody:root ofType:rootType withSchema:schema]);
	
	return YES;
}


- (BOOL) encodeOneTagBody:(id)value ofType:(JANBTTagType)type withSchema:(id)schema
{
	/*
		Caller is responsible for ensuring objects are of the right classes.
		Callers assume that objects’ ja_NBTTypes are not misleading. Since
		it’s an internal method, there’s no reasonable expectation it will be
		overridden to lie.
	*/
	
	switch (type)
	{
		case kJANBTTagByte:
			return [self encodeByte:value withSchema:schema];
			
		case kJANBTTagShort:
			return [self encodeShort:value withSchema:schema];
			
		case kJANBTTagInt:
			return [self encodeInt:value withSchema:schema];
			
		case kJANBTTagLong:
			return [self encodeLong:value withSchema:schema];
			
		case kJANBTTagFloat:
			return [self encodeFloat:value withSchema:schema];
			
		case kJANBTTagDouble:
			return [self encodeDouble:value withSchema:schema];
			
		case kJANBTTagByteArray:
			return [self encodeByteArray:value withSchema:schema];
			
		case kJANBTTagString:
			return [self encodeString:value withSchema:schema];
			
		case kJANBTTagList:
			return [self encodeList:value withSchema:schema];
			
		case kJANBTTagCompound:
			return [self encodeCompound:value withSchema:schema];
			
		case kJANBTTagIntArray:
			return [self encodeIntArray:value withSchema:schema];
			
		case kJANBTTagEnd:
		case kJANBTTagIntArrayContent:
		case kJANBTTagAny:
		case kJANBTTagUnknown:
			;
	}
	
	[self setErrorIfClear:kJANBTSerializationUnknownTagError underlyingError:nil format:@"Unknown NBT tag %u.", type];
	return NO;
}


#define REQUIRE_SCHEMA(COND, EXPECTED, SCH)  REQUIRE_ERR(COND, kJANBTSerializationWrongTypeError, @"Object does not conform to schema; expected %@, got %@.", JANBTTagNameFromSchema(SCH), EXPECTED)
#define REQUIRE_NUMERICAL_SCHEMA(SCH)  REQUIRE_SCHEMA(JANBTIsNumericalSchema(SCH), @"numerical type", SCH)

- (BOOL) encodeByte:(NSNumber *)value withSchema:(id)schema
{
	REQUIRE_NUMERICAL_SCHEMA(schema);
	return [self writeByte:value.charValue];
}


- (BOOL) encodeShort:(NSNumber *)value withSchema:(id)schema
{
	REQUIRE_NUMERICAL_SCHEMA(schema);
	return [self writeShort:value.shortValue];
}


- (BOOL) encodeInt:(NSNumber *)value withSchema:(id)schema
{
	REQUIRE_NUMERICAL_SCHEMA(schema);
	return [self writeInt:value.intValue];
}


- (BOOL) encodeLong:(NSNumber *)value withSchema:(id)schema
{
	REQUIRE_NUMERICAL_SCHEMA(schema);
	return [self writeLong:value.longLongValue];
}


- (BOOL) encodeFloat:(NSNumber *)value withSchema:(id)schema
{
	REQUIRE_NUMERICAL_SCHEMA(schema);
	return [self writeFloat:value.floatValue];
}


- (BOOL) encodeDouble:(NSNumber *)value withSchema:(id)schema
{
	REQUIRE_NUMERICAL_SCHEMA(schema);
	return [self writeDouble:value.doubleValue];
}


- (BOOL) encodeByteArray:(NSData *)value withSchema:(id)schema
{
	REQUIRE_SCHEMA(schema == nil || [schema isEqual:@"data"], @"TAG_Byte_Array", schema);
	
	NSUInteger length = value.length;
	REQUIRE_ERR(length <= INT32_MAX, kJANBTSerializationObjectTooLargeError, @"Byte array is too long (%lu bytes)", length);
	
	REQUIRE([self writeInt:length]);
	return [self writeBytes:value.bytes length:length];
	
}


- (BOOL) encodeString:(NSString *)value withSchema:(id)schema
{
	REQUIRE_SCHEMA(schema == nil || [schema isEqual:@"string"], @"TAG_String", schema);
	return [self writeString:value];
}


- (BOOL) encodeList:(NSArray *)value withSchema:(id)schema
{
	if (value.ja_NBTListElementType == kJANBTTagIntArrayContent || [schema isEqual:@"intarray"])
	{
		return [self encodeIntArray:value withSchema:schema];
	}
	
	REQUIRE_SCHEMA(schema == nil || ([schema isKindOfClass:[NSArray class]] && [schema count] == 1), @"TAG_List", schema);
	
	schema = [schema objectAtIndex:0];
	
	JANBTTagType type = value.ja_NBTListElementType;
	if (type == kJANBTTagUnknown && schema != nil)
	{
		type = [schema ja_NBTSchemaType];
	}
	else
	{
		REQUIRE_ERR(schema == nil || type == [schema ja_NBTSchemaType], kJANBTSerializationWrongTypeError, @"Object does not conform to schema; expected list element type %@, got %@.", JANBTTagNameFromSchema(schema), JANBTTagNameFromTagType(type));
	}
	REQUIRE_ERR(JANBTIsKnownTagType(type), kJANBTSerializationWrongTypeError, @"Object contains list with unknown NBT type.");
	
	NSUInteger count = value.count;
	REQUIRE_ERR(count <= INT32_MAX, kJANBTSerializationObjectTooLargeError, @"List too long (%lu items)", count);
	
	REQUIRE([self writeByte:type]);
	REQUIRE([self writeInt:count]);
	
	for (id elem in value)
	{
		JANBTTagType elemType = [elem ja_NBTType];
		if (elemType == type || (JANBTIsNumericalTagType(elemType) && JANBTIsNumericalTagType(type)))
		{
			REQUIRE([self encodeOneTagBody:elem ofType:type withSchema:schema]);
		}
	}
	
	return YES;
}


- (BOOL) encodeCompound:(NSDictionary *)value withSchema:(id)schema
{
	REQUIRE_SCHEMA(schema == nil || [schema isKindOfClass:[NSDictionary class]], @"TAG_Compound", schema);
	
	for (id key in value)
	{
		@autoreleasepool
		{
			REQUIRE_ERR([key isKindOfClass:[NSString class]], kJANBTSerializationWrongTypeError, @"Object countains a non-string dictionary key.");
			id element = [value objectForKey:key];
			id elementSchema = [schema objectForKey:key];
			
			JANBTTagType type = NormalizedTagType(element, elementSchema);
			REQUIRE_ERR(JANBTIsKnownTagType(type), kJANBTSerializationWrongTypeError, @"Object contains a dictionary value of unknown NBT type.");
			
			REQUIRE([self writeByte:type]);
			REQUIRE([self writeString:key]);
			
			REQUIRE([self encodeOneTagBody:element ofType:type withSchema:elementSchema]);
		}
	}
	
	return [self writeByte:kJANBTTagEnd];
}


- (BOOL) encodeIntArray:(NSArray *)value withSchema:(id)schema
{
	REQUIRE_SCHEMA(schema == nil || [schema isEqual:@"intarray"], @"TAG_Int_Array", schema);
	
	NSUInteger count = value.count;
	REQUIRE_ERR(count <= INT32_MAX, kJANBTSerializationObjectTooLargeError, @"List too long (%lu items)", count);
	
	REQUIRE([self writeInt:count]);
	
	for (id elem in value)
	{
		REQUIRE_ERR([elem respondsToSelector:@selector(intValue)], kJANBTSerializationWrongTypeError, @"Int array contains non-numerical object.");
		REQUIRE([self writeInt:[elem intValue]]);
	}
	
	return YES;
}


- (BOOL) writeByte:(uint8_t)value
{
	return [self writeBytes:&value length:sizeof value];
}


- (BOOL) writeShort:(uint16_t)value
{
	value = CFSwapInt16HostToBig(value);
	return [self writeBytes:&value length:sizeof value];
}


- (BOOL) writeInt:(uint32_t)value
{
	value = CFSwapInt32HostToBig(value);
	return [self writeBytes:&value length:sizeof value];
}


- (BOOL) writeLong:(uint64_t)value
{
	value = CFSwapInt64HostToBig(value);
	return [self writeBytes:&value length:sizeof value];
}


- (BOOL) writeFloat:(Float32)value
{
	union { int32_t i; Float32 f; } convert;
	convert.f = value;
	return [self writeInt:convert.i];
}


- (BOOL) writeDouble:(Float64)value 
{
	union { int64_t i; Float64 f; } convert;
	convert.f = value;
	return [self writeLong:convert.i];
}


- (BOOL) writeString:(NSString *)value
{
	NSData *bytes = [value dataUsingEncoding:NSUTF8StringEncoding];
	NSUInteger length = bytes.length;
	REQUIRE_ERR(length <= INT16_MAX, kJANBTSerializationObjectTooLargeError, @"String is too long (%lu bytes)", length);
	
	REQUIRE([self writeShort:length]);
	return [self writeBytes:bytes.bytes length:length];
}


- (BOOL) writeBytes:(const void *)bytes length:(NSUInteger)length
{
	if (_compressor == nil)  return YES;
	NSError __autoreleasing *error;
	BOOL OK = [_compressor write:bytes length:length error:&error];
	if (!OK)  _error = error;
	return OK;
}

@end


static JANBTTagType NormalizedTagType(id value, id schema)
{
	if (schema != nil && [value isKindOfClass:[NSNumber class]])
	{
		JANBTTagType schemaType = [schema ja_NBTSchemaType];
		if (JANBTIsNumericalTagType(schemaType))  return schemaType;
	}
	return [value ja_NBTType];
}
