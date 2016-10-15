/*
	JANBTParserNullCompressor.m


	Copyright © 2016 Jens Ayton

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

#import "JANBTParserNullCompressor.h"

NS_ASSUME_NONNULL_BEGIN

@interface JANBTParserNullCompressor ()

@property (readonly, strong) NSOutputStream *stream;
@property (readwrite) NSUInteger compressedBytesWritten;

@end

@interface JANBTParserNullDecompressor ()

@property (readonly, strong) NSInputStream *stream;

@end


@implementation JANBTParserNullCompressor

- (id)initWithStream:(NSOutputStream *)stream
{
	if ((self = [super init]))
	{
		_stream = stream;
	}
	return self;
}


- (BOOL)write:(const uint8_t *)bytes length:(NSUInteger)length error:(NSError **)outError
{
	NSParameterAssert(bytes != nil);

	while (length > 0) {
		NSInteger written = [self.stream write:bytes maxLength:length];
		if (written < 1) {
			if (outError != nil) {
				*outError = self.stream.streamError;
				return NO;
			}
		}

		bytes += written;
		length -= written;
		self.compressedBytesWritten += written;
	}

	if (outError != nil) {
		*outError = nil;
	}
	return YES;
}


- (BOOL)flushWithError:(NSError **)outError
{
	if (outError != nil) {
		*outError = nil;
	}
	return YES;
}

@end


@implementation JANBTParserNullDecompressor

- (id)initWithStream:(NSInputStream *)stream
{
	if ((self = [super init]))
	{
		_stream = stream;
	}
	return self;
}


- (NSInteger)read:(uint8_t *)bytes length:(NSInteger)length error:(NSError **)outError
{
	NSInteger result = [self.stream read:bytes maxLength:length];
	if (result < 0 && outError != nil) {
		*outError = self.stream.streamError;
	}
	return result;
}

@end

NS_ASSUME_NONNULL_END
