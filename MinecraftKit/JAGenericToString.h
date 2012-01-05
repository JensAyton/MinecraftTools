/*
	JAGenericToString.h
	
	The overloaded function $tostring(x) converts various types to NSStrings.
	Specifically, it currently supports primitive number types, C strings, and
	Objective-C objects.
	
	Numbers (NSNumber or any primitive number type) are converted using
	locale-appropriate NSNumberFormatterDecimalStyle. These conversions are
	also exposed through the JAStringFrom{Number|Integer|Double} helper
	functions.
	
	“Apple LLVM Compiler 3.0” or mainline clang 3.0 is required because of the
	use of __attribute__((overloadable)). (It should work with earlier compilers
	in Objective-C++.)
	
	
	A minor annoyance: C string constants are supported, but convert at runtime,
	so they should be avoided in favour of NSString constants. This could be
	avoided in gcc using __builtin_chose_expr and __builtin_constant_p, but
	__builtin_constant_p doesn’t work for C string literals in clang.
	
	
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


#ifdef __cplusplus
#ifndef JA_INLINE_OVERLOAD
#define JA_INLINE_OVERLOAD inline
#endif
#ifndef JA_EXTERN_C
#define JA_EXTERN_C extern "C"
#endif
#else
#ifndef JA_INLINE_OVERLOAD
#define JA_INLINE_OVERLOAD __attribute__((overloadable)) static inline
#endif
#ifndef JA_EXTERN_C
#define JA_EXTERN_C
#endif
#endif


/*
	JAStringFrom{Number|Integer|UnsignedInteger|Double}
	
	Format numbers using locale-appropriate NSNumberFormatterDecimalStyle.
*/
JA_EXTERN_C NSString *JAStringFromNumber(NSNumber *number);
JA_EXTERN_C NSString *JAStringFromInteger(long long value);
JA_EXTERN_C NSString *JAStringFromUnsignedInteger(unsigned long long value);
JA_EXTERN_C NSString *JAStringFromDouble(double value);


JA_INLINE_OVERLOAD NSString *$tostring(id object) { return [object description]; }
JA_INLINE_OVERLOAD NSString *$tostring(NSString *string) { return string; }
JA_INLINE_OVERLOAD NSString *$tostring(NSNumber *number) { return JAStringFromNumber(number); }

JA_INLINE_OVERLOAD NSString *$tostring(const char *cstring) { return [NSString stringWithUTF8String:cstring]; }

JA_INLINE_OVERLOAD NSString *$tostring(char value) { return JAStringFromInteger(value); }
JA_INLINE_OVERLOAD NSString *$tostring(signed char value) { return JAStringFromInteger(value); }
JA_INLINE_OVERLOAD NSString *$tostring(unsigned char value) { return JAStringFromUnsignedInteger(value); }
JA_INLINE_OVERLOAD NSString *$tostring(short value) { return JAStringFromInteger(value); }
JA_INLINE_OVERLOAD NSString *$tostring(unsigned short value) { return JAStringFromUnsignedInteger(value); }
JA_INLINE_OVERLOAD NSString *$tostring(int value) { return JAStringFromInteger(value); }
JA_INLINE_OVERLOAD NSString *$tostring(unsigned int value) { return JAStringFromUnsignedInteger(value); }
JA_INLINE_OVERLOAD NSString *$tostring(long value) { return JAStringFromInteger(value); }
JA_INLINE_OVERLOAD NSString *$tostring(unsigned long value) { return JAStringFromUnsignedInteger(value); }
JA_INLINE_OVERLOAD NSString *$tostring(long long value) { return JAStringFromInteger(value); }
JA_INLINE_OVERLOAD NSString *$tostring(unsigned long long value) { return JAStringFromUnsignedInteger(value); }
JA_INLINE_OVERLOAD NSString *$tostring(float value) { return JAStringFromDouble(value); }
JA_INLINE_OVERLOAD NSString *$tostring(double value) { return JAStringFromDouble(value); }
JA_INLINE_OVERLOAD NSString *$tostring(long double value) { return JAStringFromDouble(value); }
