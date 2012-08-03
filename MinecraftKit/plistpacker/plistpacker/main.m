#import <Foundation/Foundation.h>


static void Print(FILE *file, NSString *format, ...) NS_FORMAT_FUNCTION(2, 3);


int RealMain(int argc, const char * argv[])
{
	if (argc != 3)
	{
		Print(stderr, @"Usage: plistpacker <inputfile> <name>\n");
		return(EXIT_FAILURE);
	}
	
	// Read input file.
	NSString *fileName = [[NSString alloc] initWithCString:argv[1] encoding:NSUTF8StringEncoding];
	fileName = [[fileName stringByStandardizingPath] stringByExpandingTildeInPath];
	NSData *data = [NSData dataWithContentsOfFile:fileName];
	if (data == nil)
	{
		Print(stderr, @"error: could not read file %@.\n", fileName);
		return EXIT_FAILURE;
	}
	
	// Parse as property list.
	NSString *errDesc;
	id plist = [NSPropertyListSerialization propertyListFromData:data
												mutabilityOption:NSPropertyListImmutable
														  format:NULL
												errorDescription:&errDesc];
	if (plist == nil)
	{
		Print(stderr, @"error: could not parse property list %@. %@\n", fileName.lastPathComponent, errDesc);
		return EXIT_FAILURE;
	}
	
	// Generate binary plist.
	data = [NSPropertyListSerialization dataFromPropertyList:plist
													  format:NSPropertyListBinaryFormat_v1_0
											errorDescription:&errDesc];
	if (data == nil)
	{
		Print(stderr, @"error: could not reserialize property list %@. %@\n", fileName.lastPathComponent, errDesc);
		return EXIT_FAILURE;
	}
	
	// Generate blob files.
	NSString *outputName = [[NSString alloc] initWithCString:argv[2] encoding:NSUTF8StringEncoding];
	const uint8_t *bytes = data.bytes;
	NSUInteger i, length = data.length;
	
	FILE *header = fopen([[outputName stringByAppendingPathExtension:@"h"] UTF8String], "w");
	if (header == NULL)
	{
		
		Print(stderr, @"error: could not open %@.h for output. %s\n", outputName, strerror(errno));
		return EXIT_FAILURE;
	}
	Print(header,
		  @"/*\n"
		  "\t%@.h\n\t\n\tAutomatically generated from %@. Do not edit.\n*/\n\n"
		  "#include <CoreFoundation/CoreFoundation.h>\n\n\n"
		  "enum\n"
		  "{\n"
		  "\tk%@Size = %lu\n"
		  "};\n\n"
		  "extern char k%@[k%@Size];\n\n\n"
		  "#if __OBJC__\n"
		  "#import <Foundation/Foundation.h>\n\n"
		  "static inline id Get%@(void)\n"
		  "{\n"
		  "\tNSData *data = [NSData dataWithBytesNoCopy:k%@ length:k%@Size freeWhenDone:NO];\n"
		  "\treturn [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:NULL];\n"
		  "}\n"
		  "#endif\n\n"
		  "static inline CFPropertyListRef Copy%@(void)\n"
		  "{\n"
		  "\tCFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, (const UInt8 *)k%@, k%@Size, kCFAllocatorNull);\n"
		  "\tCFPropertyListRef result = CFPropertyListCreateWithData(kCFAllocatorDefault, data, kCFPropertyListImmutable, NULL, NULL);\n"
		  "\tCFRelease(data);\n"
		  "\treturn result;\n"
		  "}\n",
		  outputName, [fileName lastPathComponent],
		  outputName, length,
		  outputName, outputName,
		  outputName,
		  outputName, outputName,
		  outputName,
		  outputName, outputName);
	fclose(header);
	
	FILE *cfile = fopen([[outputName stringByAppendingPathExtension:@"c"] UTF8String], "w");
	if (cfile == NULL)
	{
		
		Print(stderr, @"error: could not open %@.c for output. %s\n", outputName, strerror(errno));
		return EXIT_FAILURE;
	}
	Print(cfile, @"/*\n\t%@.c\n\t\n\tAutomatically generated from %@. Do not edit.\n*/\n\n#include \"%@.h\"\n\n\nchar k%@[k%@Size] =\n{", outputName, [fileName lastPathComponent], outputName, outputName, outputName);
	
	for (i = 0; i < length; i++)
	{
		if (i != 0)
		{
			fputc(',', cfile);
		}
		if (i % 10 == 0)
		{
			fputs("\n\t", cfile);
		}
		else
		{
			fputc(' ', cfile);
		}
		
		fprintf(cfile, "0x%.2X", bytes[i]);
	}
	
	Print(cfile, @"\n};\n");
	
	fclose(cfile);
	
	return EXIT_SUCCESS;
}


int main (int argc, const char * argv[])
{
	@autoreleasepool
	{
		@try
		{
			return RealMain(argc, argv);
		}
		@catch (id e)
		{
			NSLog(@"EXCEPTION: %@", e);
			return EXIT_FAILURE;
		}
	}
    return 0;
}


static void Print(FILE *file, NSString *format, ...)
{
	va_list args;
	va_start(args, format);
	NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
	va_end(args);
	
	
	fputs([message UTF8String], file);
}
