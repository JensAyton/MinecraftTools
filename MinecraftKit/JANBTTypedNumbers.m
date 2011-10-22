/*
	JANBTTypedNumbers.m
	
	
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

#import "JANBTTypedNumbers.h"
#import "MYCollectionUtilities.h"


@implementation JANBTInteger
{
	NSInteger					_value;
	JANBTTagType				_type;
}


- (id) initWithValue:(NSInteger)value type:(JANBTTagType)type
{
	if ((self = [super init]))
	{
		_value = value;
		_type = type;
	}
	return self;
}


- (void) getValue:(void *)value
{
	if (__builtin_expect(value == NULL, 0))  return;
	
	switch (_type)
	{
		case kJANBTTagByte:
			*(int8_t *)value = _value;
			break;
			
		case kJANBTTagShort:
			*(int16_t *)value = _value;
			break;
			
		case kJANBTTagInt:
			*(int32_t *)value = _value;
			break;
			
		case kJANBTTagLong:
			*(int64_t *)value = _value;
			break;
			
		default:
			[NSException raise:NSInternalInconsistencyException format:@"JANBTInteger has non-integer type"];
	}
}


- (const char *) objCType
{
	switch (_type)
	{
		case kJANBTTagByte:
			return @encode(int8_t);
			
		case kJANBTTagShort:
			return @encode(int16_t);
			
		case kJANBTTagInt:
			return @encode(int32_t);
			
		case kJANBTTagLong:
			return @encode(int64_t);
			
		default:
			[NSException raise:NSInternalInconsistencyException format:@"JANBTInteger has non-integer type"];
			__builtin_unreachable();
	}
}


- (char) charValue
{
	return _value;
}


- (unsigned char) unsignedCharValue
{
	return _value;
}


- (short) shortValue
{
	return _value;
}


- (unsigned short) unsignedShortValue
{
	return _value;
}


- (int) intValue
{
	return _value;
}


- (unsigned int) unsignedIntValue
{
	return _value;
}


- (long) longValue
{
	return _value;
}


- (unsigned long) unsignedLongValue
{
	return _value;
}


- (long long) longLongValue
{
	return _value;
}


- (unsigned long long) unsignedLongLongValue
{
	return _value;
}


- (float) floatValue
{
	return _value;
}


- (double) doubleValue
{
	return _value;
}


- (BOOL) boolValue
{
	return _value != 0;
}


- (NSInteger) integerValue
{
	return _value;
}


- (NSUInteger) unsignedIntegerValue
{
	return _value;
}


- (NSString *)stringValue
{
	return $sprintf(@"%llu", _value);
}


- (JANBTTagType) ja_NBTType
{
	return _type;
}

@end


@implementation JANBTFloat
{
	Float32						_value;
}

- (id) initWithValue:(Float32)value
{
	if ((self = [super init]))
	{
		_value = value;
	}
	return self;
}


- (void) getValue:(void *)value
{
	if (__builtin_expect(value == NULL, 0))  return;
	*(Float32 *)value = _value;
}


- (const char *) objCType
{
	return @encode(Float32);
}


- (char) charValue
{
	return _value;
}


- (unsigned char) unsignedCharValue
{
	return _value;
}


- (short) shortValue
{
	return _value;
}


- (unsigned short) unsignedShortValue
{
	return _value;
}


- (int) intValue
{
	return _value;
}


- (unsigned int) unsignedIntValue
{
	return _value;
}


- (long) longValue
{
	return _value;
}


- (unsigned long) unsignedLongValue
{
	return _value;
}


- (long long) longLongValue
{
	return _value;
}


- (unsigned long long) unsignedLongLongValue
{
	return _value;
}


- (float) floatValue
{
	return _value;
}


- (double) doubleValue
{
	return _value;
}


- (BOOL) boolValue
{
	return _value != 0;
}


- (NSInteger) integerValue
{
	return _value;
}


- (NSUInteger) unsignedIntegerValue
{
	return _value;
}


- (JANBTTagType) ja_NBTType
{
	return kJANBTTagFloat;
}

@end


@implementation JANBTDouble
{
	Float64						_value;
}

- (id) initWithValue:(Float64)value
{
	if ((self = [super init]))
	{
		_value = value;
	}
	return self;
}


- (void) getValue:(void *)value
{
	if (__builtin_expect(value == NULL, 0))  return;
	*(Float64 *)value = _value;
}


- (const char *) objCType
{
	return @encode(Float64);
}


- (char) charValue
{
	return _value;
}


- (unsigned char) unsignedCharValue
{
	return _value;
}


- (short) shortValue
{
	return _value;
}


- (unsigned short) unsignedShortValue
{
	return _value;
}


- (int) intValue
{
	return _value;
}


- (unsigned int) unsignedIntValue
{
	return _value;
}


- (long) longValue
{
	return _value;
}


- (unsigned long) unsignedLongValue
{
	return _value;
}


- (long long) longLongValue
{
	return _value;
}


- (unsigned long long) unsignedLongLongValue
{
	return _value;
}


- (float) floatValue
{
	return _value;
}


- (double) doubleValue
{
	return _value;
}


- (BOOL) boolValue
{
	return _value != 0;
}


- (NSInteger) integerValue
{
	return _value;
}


- (NSUInteger) unsignedIntegerValue
{
	return _value;
}


- (JANBTTagType) ja_NBTType
{
	return kJANBTTagDouble;
}

@end


@implementation NSNumber (JANBTNumberType)

- (JANBTTagType) ja_NBTType
{
	const char *type = self.objCType;
	if (strcmp(type, @encode(float)) == 0)
	{
		return kJANBTTagFloat;
	}
	else if (strcmp(type, @encode(double)) == 0)
	{
		return kJANBTTagDouble;
	}
	else if (strcmp(type, @encode(long double)) == 0)
	{
		return kJANBTTagDouble;
	}
	
	NSInteger value = self.integerValue;
	if (INT8_MIN <= value && value <= INT8_MAX)  return kJANBTTagByte;
	else if (INT16_MIN <= value && value <= INT16_MAX)  return kJANBTTagShort;
	else if (INT32_MIN <= value && value <= INT32_MAX)  return kJANBTTagInt;
	else return kJANBTTagLong;
}

@end
