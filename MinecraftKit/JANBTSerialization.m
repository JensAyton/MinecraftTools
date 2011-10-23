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
#import "JANBTStreamEncoder.h"
#import "MYCollectionUtilities.h"


NSString * const kJANBTSerializationErrorDomain = @"se.ayton.jens.minecraftkit JANBTSerialization ErrorDomain";

// Create an NSError in kJANBTSerializationErrorDomain if outError is not null.
static void SetError(NSError **outError, NSInteger errorCode, NSString *format, ...) NS_FORMAT_FUNCTION(3, 4);


@implementation JANBTSerialization

- (id) init
{
	return nil;
}


+ (BOOL) isValidNBTObject:(id)object
{
	return [self isValidNBTObject:object conformingToSchema:nil options:0];
}


+ (BOOL) isValidNBTObject:(id)object conformingToSchema:(id)schema options:(JANBTWritingOptions)options
{
	JANBTStreamEncoder *encoder = [[JANBTStreamEncoder alloc] initWithStream:nil options:options];
	if (encoder == nil)  return YES;	// Your guess is as good as mine.
	
	return [encoder encodeObject:object withSchema:schema rootName:@"" error:NULL];
}


+ (NSData *) dataWithNBTObject:(id)root
					  rootName:(NSString *)rootName
					   options:(JANBTWritingOptions)options
						schema:(id)schema
						 error:(NSError **)outError
{
	NSOutputStream *stream = [NSOutputStream outputStreamToMemory];
	[stream open];
	NSInteger bytesWritten = [self writeNBTObject:root rootName:rootName toStream:stream options:options schema:schema error:outError];
	[stream close];
	
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
	[stream open];
	id result = [self NBTObjectWithStream:stream rootName:outRootName options:options schema:schema error:outError];
	[stream close];
	return result;
}


+ (NSInteger) writeNBTObject:(id)object
					rootName:(NSString *)rootName
					toStream:(NSOutputStream *)stream
					 options:(JANBTWritingOptions)options
					  schema:(id)schema
					   error:(NSError **)outError
{
	if (stream == nil)  return 0;
	
	JANBTStreamEncoder *encoder = [[JANBTStreamEncoder alloc] initWithStream:stream options:options];
	if (encoder == nil)
	{
		SetError(outError, kJANBTSerializationMemoryError, @"Could not create NBT encoder.");
		return 0;
	}
	
	BOOL success = [encoder encodeObject:object withSchema:schema rootName:rootName error:outError];
	
	if (success)  return encoder.bytesWritten;
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
