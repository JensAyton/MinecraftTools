/*
	JAZLibCompressor.m
	
	
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

#import "JAZLibCompressor.h"
#import <zlib.h>
#import "MYCollectionUtilities.h"


enum
{
	kBufferSize					= 128,// << 10,
	kFlushThreshold				= kBufferSize * 3 / 4
};


NSString * const kJAZLibErrorDomain = @"se.jens.ayton net.zlib Error Domain";


static void SetZLibError(int code, z_stream *stream, NSError **outError);


@implementation JAZLibCompressor
{
	NSOutputStream				*_stream;
	uint8_t						*_inBuffer;
	uint8_t						*_outBuffer;
	NSUInteger					_inCursor;
	z_stream					_zstream;
	BOOL						_streamWasClosed;
	BOOL						_failed;
	BOOL						_zOpen;
}

- (id) initWithStream:(NSOutputStream *)stream mode:(JAZLibCompressionMode)mode
{
	if (stream == nil)  return nil;
	
	if ((self = [super init]))
	{
		_inBuffer = malloc(kBufferSize);
		_outBuffer = malloc(kBufferSize);
		
		if (_inBuffer == nil || _outBuffer == nil)
		{
			free(_inBuffer);
			free(_outBuffer);
			[NSException raise:NSMallocException format:@"Could not allocate space for zlib compression."];
		}
		
		_stream = stream;
		if (stream.streamStatus == NSStreamStatusNotOpen)
		{
			_streamWasClosed = YES;
			[stream open];
		}
		
		int windowBits = 15;
		switch (mode)
		{
			case kJAZLibCompressionRawDeflate:
				windowBits = -windowBits;
				break;
				
			case kJAZLibCompressionZLib:
				break;
				
			case kJAZLibCompressionGZip:
				windowBits += 16;
				break;
		}
		
		_zstream.next_in = _inBuffer;
		_zstream.next_out = _outBuffer;
		_zstream.avail_out = kBufferSize;
		
		int zstatus = deflateInit2(&_zstream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, windowBits, 9, Z_DEFAULT_STRATEGY);
		if (zstatus != Z_OK)  return nil;
		
		_zOpen = YES;
	}
	
	return self;
}


- (void) dealloc
{
	if (!_failed && _zOpen)  [self flushWithError:NULL];
	if (_zOpen)  deflateEnd(&_zstream);
	if (_streamWasClosed)  [_stream close];
	
	free(_inBuffer);
	free(_outBuffer);
}


- (BOOL) writeToOutStreamWithError:(NSError **)outError
{
	uint8_t *outBytes = _outBuffer;
	NSUInteger outRemaining = kBufferSize - _zstream.avail_out;
		  
	while (outRemaining > 0)
	{
		NSInteger status = [_stream write:outBytes maxLength:outRemaining];
		if (status > 0)
		{
			outBytes += status;
			outRemaining -= status;
		}
		else
		{
			if (outError != NULL)  *outError = _stream.streamError;
			_failed = YES;
			return NO;
		}
	}
	
	// Reset buffer pointers.
	_zstream.next_out = _outBuffer;
	_zstream.avail_out = kBufferSize;
	
	return YES;
}


- (BOOL) write:(const uint8_t *)bytes length:(NSUInteger)length error:(NSError **)outError
{
	NSParameterAssert(bytes != NULL);
	if (_failed)  return NO;
	
	while (length > 0)
	{
		// Copy input into deflate buffer.
		NSUInteger inSpace = kBufferSize - _inCursor;
		if (inSpace > 0)
		{
			NSUInteger toCopy = MIN(inSpace, length);
			bcopy(bytes, _inBuffer + _inCursor, toCopy);
			_inCursor += toCopy;
			bytes += toCopy;
			length -= toCopy;
			_zstream.avail_in += toCopy;
		}
		
		if (length == 0 && _inCursor < kFlushThreshold)  break;
		
		// Do some deflating.
		int zstatus = deflate(&_zstream, inSpace > 0 ? Z_NO_FLUSH : Z_BLOCK);
		if (zstatus != Z_OK)
		{
			SetZLibError(zstatus, &_zstream, outError);
			_failed = YES;
			return NO;
		}
		
		if (_zstream.avail_in == 0)
		{
			_zstream.next_in = _inBuffer;
			_inCursor = 0;
		}
		
		if (_zstream.avail_out < kBufferSize - kFlushThreshold)
		{
			// Write deflated data if any.
			if (![self writeToOutStreamWithError:outError])  return NO;
		}
	}
	
	return YES;
}


- (BOOL) flushWithError:(NSError **)outError
{
	if (_failed)  return NO;
	if (!_zOpen)  return YES;
	
	int zstatus = Z_OK;
	do
	{
		zstatus = deflate(&_zstream, Z_FINISH);
		if (zstatus != Z_OK && zstatus != Z_STREAM_END)
		{
			SetZLibError(zstatus, &_zstream, outError);
			_failed = YES;
			return NO;
		}
		
		if (![self writeToOutStreamWithError:outError])  return NO;
	}
	while (zstatus != Z_STREAM_END);
	
	deflateEnd(&_zstream);
	_zOpen = NO;
	
	if (_streamWasClosed)
	{
		[_stream close];
		_streamWasClosed = NO;
	}
	
	return YES;
}


- (NSUInteger) rawBytesWritten
{
	return _zstream.total_in + _zstream.avail_in;
}


- (NSUInteger) compressedBytesWritten
{
	return _zstream.total_out;
}

@end


static void SetZLibError(int code, z_stream *stream, NSError **outError)
{
	if (outError == NULL || code == Z_OK)  return;
	
	NSString *message;
	if (stream != NULL && stream->msg != NULL)
	{
		message = [NSString stringWithUTF8String:stream->msg];
	}
	
	*outError = [NSError errorWithDomain:kJAZLibErrorDomain
									code:code
								userInfo:$dict(NSLocalizedFailureReasonErrorKey, message)];
}
