#import "JAGenericToString.h"


NSString *JAStringFromNumber(NSNumber *number)
{
	static NSNumberFormatter *formatter = nil;
	if (formatter == nil)
	{
		formatter = [NSNumberFormatter new];
		formatter.numberStyle = NSNumberFormatterDecimalStyle;
	}
	return [formatter stringFromNumber:number];
}


NSString *JAStringFromInteger(long long value)
{
	return JAStringFromNumber([NSNumber numberWithLongLong:value]);
}


NSString *JAStringFromUnsignedInteger(unsigned long long value)
{
	return JAStringFromNumber([NSNumber numberWithUnsignedLongLong:value]);
}


NSString *JAStringFromDouble(double value)
{
	return JAStringFromNumber([NSNumber numberWithDouble:value]);
}
