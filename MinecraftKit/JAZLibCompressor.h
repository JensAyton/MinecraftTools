/*
	JAZLibCompressor.h
	
	Streaming ZLib compressor which takes data, compresses it and writes it to
	a stream. Not an NSOutputStream itself because it doesn’t support
	asynchronous operation on a run loop. Writing through a JAZLibCompressor
	is currently synchronous/blocking, but may not be in future.
	
	
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

#import <Foundation/Foundation.h>


// Compression mode determines the type of header generated.
typedef enum
{
	kJAZLibCompressionRawDeflate,
	kJAZLibCompressionZLib,
	kJAZLibCompressionGZip
} JAZLibCompressionMode;


@interface JAZLibCompressor: NSObject

- (id) initWithStream:(NSOutputStream *)stream mode:(JAZLibCompressionMode)mode;

- (BOOL) write:(const uint8_t *)bytes length:(NSUInteger)length error:(NSError **)outError;
- (BOOL) flushWithError:(NSError **)outError;

@property (readonly) NSUInteger rawBytesWritten;
@property (readonly) NSUInteger compressedBytesWritten;

@end


extern NSString * const kJAZLibErrorDomain;	// Error codes are defined in zlib.h.
