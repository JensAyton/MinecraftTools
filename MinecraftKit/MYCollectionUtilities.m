/*
	MYCollectionUtilities.m
	
	
	Copyright © 2008, Jens Alfke <jens@mooseyard.com>. All rights reserved.
	With modifications by Jens Ayton.
	
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:
	
	• Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	• Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS”
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSE-
	QUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
	GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
	HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
	LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
	OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
	SUCH DAMAGE.
*/

#import "MYCollectionUtilities.h"


static id JADictOfImpl(JA_UNSAFE_UNRETAINED id values[], size_t count, Class cls)
{
	NSCParameterAssert((count & 1) == 0);
	if (count == 0)  return [NSDictionary dictionary];
	
	JA_UNSAFE_UNRETAINED id objects[count / 2], keys[count / 2];
	size_t n = 0;
	for (size_t i = 0; i < count; i += 2)
	{
		id key = values[i], value = values[i + 1];
		if (value != nil)
		{
			objects[n] = value;
			keys[n] = key;
			n++;
		}
	}
	return [cls dictionaryWithObjects:objects forKeys:keys count:n];
}


NSDictionary *JADictOf(JA_UNSAFE_UNRETAINED id values[], size_t count)
{
	return JADictOfImpl(values, count, [NSDictionary class]);
}


NSDictionary *JAMutableDictOf(JA_UNSAFE_UNRETAINED id values[], size_t count)
{
	return JADictOfImpl(values, count, [NSMutableDictionary class]);
}


BOOL $equal(id obj1, id obj2)	  // Like -isEqual: but works even if either/both are nil
{
	if (obj1 != nil)
	{
		return (obj2 != nil) && [obj1 isEqual:obj2];
	}
	else
	{
		return obj2 == nil;
	}
}
