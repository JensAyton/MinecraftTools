/*
	JABozoStringTemplate.h
	
	Ridiculously simple string template “engine” which allows simple pseudo-
	interposing of object variables.
	
	Example of use:
		NSString *planet = @"World";
		NSString *message = TEMPLATE(@"Hello, <$planet$>!", planet);
	
	Since the variables to replace are specified explicitly, this is safe to
	use on strings from external sources. Because only object descriptions
	are supported, there are no type safety issues as with printf-style format
	strings.
*/


#import "JAPropertyListAccessors.h"


#define TEMPLATE(string, NAME)			[string stringByReplacingOccurrencesOfString:(@"<$"#NAME"$>") withString:[NAME description]]
#define TEMPLATE_KEY(dict, key, NAME)	({ NSString *template = [dict ja_stringForKey:key]; TEMPLATE(template, NAME); })

#define TEMPLATE2(string, NAME1, NAME2)					TEMPLATE(TEMPLATE(string, NAME1), NAME2)
#define TEMPLATE3(string, NAME1, NAME2, NAME3)			TEMPLATE(TEMPLATE2(string, NAME1, NAME2), NAME3)

#define TEMPLATE_KEY2(dict, key, NAME1, NAME2)			TEMPLATE(TEMPLATE_KEY(dict, key, NAME1), NAME2)
#define TEMPLATE_KEY3(dict, key, NAME1, NAME2, NAME3)	TEMPLATE(TEMPLATE_KEY2(dict, key, NAME1, NAME2), NAME3)
