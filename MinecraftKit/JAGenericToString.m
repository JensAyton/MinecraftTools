#import "JAGenericToString.h"


NSString *JAStringFromNumber(NSNumber *number)
{
	return [NSNumberFormatter localizedStringFromNumber:number numberStyle:NSNumberFormatterDecimalStyle];
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
