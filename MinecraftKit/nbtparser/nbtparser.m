#import <Foundation/Foundation.h>
#if 0
#import "JANBTParser.h"
#endif
#import "JANBTSerialization.h"
#import "JANBTTagType.h"


int main (int argc, const char * argv[])
{
	@autoreleasepool
	{
		if (argc < 2)
		{
			fprintf(stderr, "Usage: nbtparser filename\n");
			return EXIT_FAILURE;
		}
		
		NSString *fileName = [[NSString alloc] initWithCString:argv[1] encoding:NSUTF8StringEncoding];
		NSData *data = [NSData dataWithContentsOfFile:fileName];
		if (data == nil)
		{
			fprintf(stderr, "Could not read file.\n");
			return EXIT_FAILURE;
		}
		
#if 0
		JANBTTag *root = [JANBTParser parseData:data];
		NSLog(@"Tags:\n%@", [root debugDescription]);
#endif
		
		return 0;
	}
}
