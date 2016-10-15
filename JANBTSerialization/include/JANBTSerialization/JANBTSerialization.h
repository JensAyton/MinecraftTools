/*
	JANBTSerialization.h
	
	Parser and encoder for Minecraft NBT format. Uses property list types for
	in-memory representation. Closely modelled on NSJSONSerialization.
	
	The main interface difference from NSJSONSerialization is the schema. This
	is an optional property list specifying the expected tag types in the data
	being read.
	
	The schema is optional for both reading and writing. When reading, if a
	schema is specified it will be enforced: if the read data doesn’t produce
	the same Objective-C class as the schema expects, reading will fail.
	(Wrong number types will be glossed over.)
	
	When reading, numbers whose type is not defined in the schema are tagged
	with their NBT type. These numbers act like normal NSNumbers, but are
	costlier (they’re real objects rather than tagged values). This allows
	you to read and write an NBT without a known schema and maintain type
	information. Using the same schema on read and write will avoid the cost
	as long as the NBT strictly conforms to the schema.
	
	When writing, the schema is used to validate the property list and to ensure
	the correct number types are written. Unknown dictionary keys will still
	be written; for numbers, the smallest possible type will be used unless
	the number is tagged for round-trip compatibility.
	
	
	Schema format:
	A schema is a property list consisting of dictionaries, arrays and strings.
	A dictionary corresponds to NBT_Compound, its keys to the names of tags
	in compounds, and its values to their types.
	An array corresponds to NBT_List. Its must contain exactly one value,
	which specifies the type of list members.
	Strings specify atomic types. The supported type names are:
		byte			8-bit signed integer, TAG_Byte
		short			16-bit signed integer, TAG_Short
		int				32-bit signed integer, TAG_Int
		long			64-bit signed integer, TAG_Long
		float			32-bit IEEE float, TAG_Float
		double			64-bit IEEE float, TAG_Double
		data			Binary data, TAG_Byte_Array
		string			UTF-8 string, TAG_String
		intarray		list of 32-bit signed integers, TAG_Int_Array
	
	For example, here’s a fragment of a schema in OpenStep plist format. It
	specifies that Items is a TAG_List containing TAG_Compounds with four
	known numerical subtags.
		Items =
		(
			{
				id = short;
				Count = byte;
				Slot = byte;
				Damage = short;
			}
		);
	
	For a full NBT, the root must be a named compound. In the corresponding
	schema, the root element is a dictionary and its name is not part of the
	schema. The separate rootName parameters can be used instead.
	
	An NBT has a root name, which is used to identify the type of NBT. When
	reading, the ioRootName parameter may be NULL (ignored), a pointer to a
	nil NSString* variable which will be set to the read root name, or a pointer
	to an initialized NSString* variable, in which case parsing will fail if
	the read value doesn’t match.
	
	
	Copyright © 2011-2013 Jens Ayton
	
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


typedef NS_ENUM(NSInteger, JANBTReadingOptions)
{
	// Produce mutable NSDictionaries and NSArrays.
	JANBTReadingOptionsMutableContainers	= 0x0001,
	
	// Produce mutable NSStrings and NSDatas.
	JANBTReadingOptionsMutableLeaves		= 0x0002,
	
	// Allow top-level objects that are not dictionaries or arrays.
	JANBTReadingOptionsAllowFragments		= 0x0004,
};


typedef NSInteger JANBTWritingOptions;	 // No options defined, use 0.


@interface JANBTSerialization : NSObject

// Test whether dataWithNBTObject:… can be expected to succeed.
+ (BOOL) isValidNBTObject:(id)obj;

+ (BOOL) isValidNBTObject:(id)obj conformingToSchema:(id)schema options:(JANBTWritingOptions)options;


+ (NSData *) dataWithNBTObject:(id)root
					  rootName:(NSString *)rootName
					   options:(JANBTWritingOptions)options
						schema:(id)schema
						 error:(NSError **)outError;


+ (id) NBTObjectWithData:(NSData *)data
				rootName:(NSString **)ioRootName
				 options:(JANBTReadingOptions)options
				  schema:(id)schema
				   error:(NSError **)outError;

+ (NSInteger) writeNBTObject:(id)obj
					rootName:(NSString *)rootName
					toStream:(NSOutputStream *)stream
					 options:(JANBTWritingOptions)options
					  schema:(id)schema
					   error:(NSError **)outError;

+ (id) NBTObjectWithStream:(NSInputStream *)stream
				  rootName:(NSString **)ioRootName
				   options:(JANBTReadingOptions)options
					schema:(id)schema
					 error:(NSError **)outError;
@end


extern NSString * const kJANBTSerializationErrorDomain;

enum
{
	kJANBTSerializationNoError,
	kJANBTSerializationMemoryError,
	kJANBTSerializationReadError,
	kJANBTSerializationWriteError,
	kJANBTSerializationCompressionError,
	kJANBTSerializationUnknownTagError,
	kJANBTSerializationWrongTypeError,
	kJANBTSerializationObjectTooLargeError,
	kJANBTSerializationWrongRootNameError,
	kJANBTSerializationInvalidSchemaError
};
