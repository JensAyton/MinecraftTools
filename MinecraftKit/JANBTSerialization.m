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
#import "JANBTTagType.h"
#import "JANBTStreamParser.h"
#import "MYCollectionUtilities.h"


NSString * const kJANBTSerializationErrorDomain = @"se.ayton.jens.minecraftkit JANBTSerialization ErrorDomain";

// Create an NSError in kJANBTSerializationErrorDomain if outError is not null.
static void SetError(NSError **outError, NSInteger errorCode, NSString *format, ...) NS_FORMAT_FUNCTION(3, 4);


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


NSString *JANBTTagNameFromSchema(id schema)
{
	return JANBTTagNameFromTagType(schema ? [schema ja_NBTSchemaType] : kJANBTTagAny);
}


NSString *JANBTTagNameFromTagType(JANBTTagType type)
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
