#import <Foundation/Foundation.h>
#import "JANBTSerialization.h"
#import "JANBTTagType.h"


@interface NSObject (NBTParser)

- (void) ja_printNBTStructureWithName:(NSString *)name indent:(NSUInteger)indent;
- (void) ja_printNBTStructureBaseWithName:(NSString *)name indent:(NSUInteger)indent;

@end


#define Print(format...)  fputs([[NSString stringWithFormat:format] UTF8String], stdout)
static NSString *IndentString(NSUInteger count);


int main (int argc, const char * argv[])
{
	@autoreleasepool
	{
		@try
		{
			if (argc < 2)
			{
				fprintf(stderr, "Usage: nbtparser filename\n");
				return EXIT_FAILURE;
			}
			
			NSString *fileName = [[NSString alloc] initWithCString:argv[1] encoding:NSUTF8StringEncoding];
			fileName = [[fileName stringByStandardizingPath] stringByExpandingTildeInPath];
			NSData *data = [NSData dataWithContentsOfFile:fileName];
			if (data == nil)
			{
				fprintf(stderr, "Could not read file.\n");
				return EXIT_FAILURE;
			}
			
			NSString __autoreleasing *rootName;
			NSError __autoreleasing *error;
			id root = [JANBTSerialization NBTObjectWithData:data rootName:&rootName options:kJANBTReadingAllowFragments schema:nil error:&error];
			
			if (root == nil)
			{
				if (error == nil)
				{
					Print(@"Empty.\n");
					return 0;
				}
				else
				{
					fprintf(stderr, "Parsing failed. %s\n", [[error description] UTF8String]);
					return EXIT_FAILURE;
				}
			}
			
			[root ja_printNBTStructureWithName:rootName indent:0];
			
			return 0;
		}
		@catch (id e)
		{
			fprintf(stderr, "EXCEPTION: %s", [[e description] UTF8String]);
		}
	}
}


@implementation NSObject (NBTParser)

- (void) ja_printNBTStructureWithName:(NSString *)name indent:(NSUInteger)indent
{
	[self ja_printNBTStructureBaseWithName:name indent:indent];
	Print(@" <unexected representation type %@>\n", self.class);
}


- (void) ja_printNBTStructureBaseWithName:(NSString *)name indent:(NSUInteger)indent
{
	JANBTTagType type = self.ja_NBTType;
	Print(@"%@%@", IndentString(indent), JANBTTagNameFromTagType(type));
	if (name != nil)
	{
		Print(@"(\"%@\")", name);
	}
}

@end


@implementation NSNumber (NBTParser)

- (void) ja_printNBTStructureWithName:(NSString *)name indent:(NSUInteger)indent
{
	[self ja_printNBTStructureBaseWithName:name indent:indent];
	JANBTTagType type = self.ja_NBTType;
	if (type == kJANBTTagFloat || type == kJANBTTagDouble)
	{
		Print(@": %g\n", self.doubleValue);
	}
	else
	{
		Print(@": %li\n", self.integerValue);
	}
}

@end


@implementation NSString (NBTParser)

- (void) ja_printNBTStructureWithName:(NSString *)name indent:(NSUInteger)indent
{
	[self ja_printNBTStructureBaseWithName:name indent:indent];
	NSString *string = self;
	if (string.length > 100)
	{
		string = [[string substringToIndex:95] stringByAppendingString:@"..."];
	}
	Print(@": \"%@\"\n", string);
}

@end


@implementation NSData (NBTParser)

- (void) ja_printNBTStructureWithName:(NSString *)name indent:(NSUInteger)indent
{
	[self ja_printNBTStructureBaseWithName:name indent:indent];
	Print(@": [%lu bytes]\n", self.length);
}

@end


@implementation NSArray (NBTParser)

- (void) ja_printNBTStructureWithName:(NSString *)name indent:(NSUInteger)indent
{
	[self ja_printNBTStructureBaseWithName:name indent:indent];
	NSUInteger count = self.count;
	Print(@": %lu entries of type %@\n", count, JANBTTagNameFromTagType(self.ja_NBTListElementType));
	if (count > 0)
	{
		Print(@"%@{\n", IndentString(indent));
		for (id element in self)
		{
			[element ja_printNBTStructureWithName:nil indent:indent + 1];
		}
		Print(@"%@}\n", IndentString(indent));
	}
}

@end


@implementation NSDictionary (NBTParser)

- (void) ja_printNBTStructureWithName:(NSString *)name indent:(NSUInteger)indent
{
	[self ja_printNBTStructureBaseWithName:name indent:indent];
	NSUInteger count = self.count;
	Print(@": %lu entries\n", count);
	if (count > 0)
	{
		Print(@"%@{\n", IndentString(indent));
		for (id key in self)
		{
			id element = [self objectForKey:key];
			[element ja_printNBTStructureWithName:key indent:indent + 1];
		}
		Print(@"%@}\n", IndentString(indent));
	}
}

@end


static NSString *IndentString(NSUInteger count)
{
	NSString * const staticTabs[] =
	{
		@"",
		@"\t",
		@"\t\t",
		@"\t\t\t",
		@"\t\t\t\t",
		@"\t\t\t\t\t",
		@"\t\t\t\t\t\t",
		@"\t\t\t\t\t\t\t"
	};
	
	if (count < sizeof staticTabs / sizeof *staticTabs)
	{
		return staticTabs[count];
	}
	else
	{
		NSMutableString *result = [NSMutableString stringWithCapacity:count];
		for (NSUInteger i = 0; i < count; i++)
		{
			[result appendString:@"\t"];
		}
		return result;
	}
}
