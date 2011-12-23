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


#import "JAPropertyListAccessors.h"
#import "JAGenericToString.h"


#define TEMPLATE(string, NAME)			[string stringByReplacingOccurrencesOfString:(@"<$"#NAME"$>") withString:$tostring(NAME)]
#define TEMPLATE_KEY(dict, key, NAME)	({ NSString *template = [dict ja_stringForKey:key]; TEMPLATE(template, NAME); })

#define TEMPLATE2(string, NAME1, NAME2)					TEMPLATE(TEMPLATE(string, NAME1), NAME2)
#define TEMPLATE3(string, NAME1, NAME2, NAME3)			TEMPLATE(TEMPLATE2(string, NAME1, NAME2), NAME3)

#define TEMPLATE_KEY2(dict, key, NAME1, NAME2)			TEMPLATE(TEMPLATE_KEY(dict, key, NAME1), NAME2)
#define TEMPLATE_KEY3(dict, key, NAME1, NAME2, NAME3)	TEMPLATE(TEMPLATE_KEY2(dict, key, NAME1, NAME2), NAME3)
