/*
	regiondumper.m
	
	Print information about Minecraft region files.
	
	
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


#import <JAMinecraftKit/JAMinecraftRegionReader.h>
#import <JAMinecraftKit/JANBTSerialization.h>
#import <JAMinecraftKit/JAPropertyListAccessors.h>
#import <JAMinecraftKit/MYCollectionUtilities.h>


static NSString *GetPath(const char *path);
static void FPrintv(FILE *file, NSString *format, va_list args);
static void Print(NSString *format, ...);
static void FPrint(FILE *file, NSString *format, ...);
static void EPrint(NSString *format, ...);

static void PrintHelpAndExit(void) __attribute__((noreturn));

static void DumpRegionInfo(JAMinecraftRegionReader *reader);
static void DumpChunkInfo(NSData *chunkData);
static void DumpEntities(NSArray *entities);
static void DumpTileEntities(NSArray *entities);


int main (int argc, const char * argv[])
{
	@autoreleasepool
	{
		if (argc < 2 || strcasecmp(argv[1], "--help") == 0 || strcmp(argv[1], "-?") == 0)
		{
			PrintHelpAndExit();
		}
		
		NSString *inputPath = GetPath(argv[1]);
		if (inputPath == nil)
		{
			EPrint(@"Failed to resolve input path \"%s\".\n", argv[1]);
			return EXIT_FAILURE;
		}
		
		JAMinecraftRegionReader *reader = [JAMinecraftRegionReader regionReaderWithURL:[NSURL fileURLWithPath:inputPath]];
		if (reader == nil)
		{
			EPrint(@"Failed to read region file.");
			return EXIT_FAILURE;
		}
		
		DumpRegionInfo(reader);
	}
    return 0;
}


static void DumpRegionInfo(JAMinecraftRegionReader *reader)
{
	for (unsigned x = 0; x < 32; x++)
	{
		for (unsigned z = 0; z < 32; z++)
		{
			Print(@"Chunk %u, %u:", x, z);
			if ([reader hasChunkAtLocalX:x localZ:z])
			{
				NSData *chunkData = [reader chunkDataAtLocalX:x localZ:z];
				if (chunkData != nil)
				{
					Print(@"\n");
					DumpChunkInfo(chunkData);
				}
				else
				{
					Print(@" UNREADABLE\n");
				}
			}
			else
			{
				Print(@" absent\n");
			}
		}
	}
}


static void DumpChunkInfo(NSData *chunkData)
{
	NSError *error;
	NSDictionary *root = [JANBTSerialization NBTObjectWithData:chunkData rootName:nil options:0 schema:nil error:&error];
	if (root == nil)
	{
		Print(@"  ERROR PARSING CHUNK: %@\n", error);
		return;
	}
	
	NSDictionary *level = [root ja_dictionaryForKey:@"Level"];
	if (level == nil)
	{
		Print(@"  ERROR PARSING CHUNK: %@\n", @"Level compound is missing.");
		return;
	}
	
	NSInteger x = [level ja_integerForKey:@"xPos"];
	NSInteger z = [level ja_integerForKey:@"zPos"];
	Print(@"  Coordinates: %li, %li (%li, %li)\n", x, z, x * 16, z * 16);
	Print(@"  LastUpdate: %li\n", [level ja_integerForKey:@"LastUpdate"]);
	
	NSArray *entities = [level ja_arrayForKey:@"Entities"];
	if (entities.count != 0)
	{
		Print(@"  Entities: %li\n", entities.count);
		DumpEntities(entities);
	}
	
	entities = [level ja_arrayForKey:@"TileEntities"];
	if (entities.count != 0)
	{
		Print(@"  TileEntities: %li\n", entities.count);
		DumpTileEntities(entities);
	}
	
	if (![level ja_boolForKey:@"TerrainPopulated"])
	{
		Print(@"  Terrain unpopulated\n");
	}
	
	// List unknown keys.
	static NSSet *knownKeys;
	if (knownKeys == nil)  knownKeys = $set(@"Blocks", @"Data", @"SkyLight", @"BlockLight", @"HeightMap", @"Entities", @"TileEntities", @"LastUpdate", @"xPos", @"zPos", @"TerrainPopulated");
	NSMutableArray *unknown;
	
	for (id key in level)
	{
		if (![knownKeys containsObject:key])
		{
			if (unknown == nil)  unknown = [NSMutableArray array];
			[unknown addObject:key];
		}
	}
	
	if (unknown != nil)
	{
		if (unknown.count == 1)
		{
			Print(@"  Unknown key: %@", [unknown objectAtIndex:0]);
		}
		else
		{
			[unknown sortUsingSelector:@selector(caseInsensitiveCompare:)];
			Print(@"  Unknown keys: %@", [unknown componentsJoinedByString:@", "]);
		}
	}
}


static void DumpEntities(NSArray *entities)
{
	NSUInteger idx, count = entities.count;
	for (idx = 0; idx < count; idx++)
	{
		NSDictionary *entity = [entities objectAtIndex:idx];
		Print(@"    %li:\n", idx);
		Print(@"      ID: %@\n", [entity ja_stringForKey:@"id"]);
		NSArray *pos = [entity ja_arrayForKey:@"Pos"];
		if (pos.count == 3)
		{
			Print(@"      Coordinates: %g, %g, %g\n", [pos ja_doubleAtIndex:0], [pos ja_doubleAtIndex:1], [pos ja_doubleAtIndex:2]);
		}
	}
}


static void DumpTileEntities(NSArray *entities)
{
	NSUInteger idx, count = entities.count;
	for (idx = 0; idx < count; idx++)
	{
		NSDictionary *entity = [entities objectAtIndex:idx];
		Print(@"    %li:\n", idx);
		Print(@"      ID: %@\n", [entity ja_stringForKey:@"id"]);
		Print(@"      Coordinates: %g, %g, %g\n", [entity ja_doubleForKey:@"x"], [entity ja_doubleForKey:@"y"], [entity ja_doubleForKey:@"z"]);
	}
}


static void PrintHelpAndExit(void)
{
	printf("Usage: regiondump <file.mcr>");
	
	exit(EXIT_SUCCESS);
}


static NSString *GetPath(const char *path)
{
	char buffer[PATH_MAX];
	realpath(path, buffer);
	return [NSString stringWithUTF8String:buffer];
}


static void FPrintv(FILE *file, NSString *format, va_list args)
{
	NSString *string = [[NSString alloc] initWithFormat:format arguments:args];
	fputs([string UTF8String], file);
}


static void FPrint(FILE *file, NSString *format, ...)
{
	va_list args;
	va_start(args, format);
	FPrintv(file, format, args);
	va_end(args);
}


static void Print(NSString *format, ...)
{
	va_list args;
	va_start(args, format);
	FPrintv(stdout, format, args);
	va_end(args);
}


static void EPrint(NSString *format, ...)
{
	va_list args;
	va_start(args, format);
	FPrintv(stderr, format, args);
	va_end(args);
}
