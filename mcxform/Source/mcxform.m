/*
	mcxform.m
	
	Simple Minecraft schematic manipulator.
	
	
	Copyright © 2010 Jens Ayton
	
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
#import "JAMinecraftSchematic.h"
#import "JAMinecraftSchematic+RDatIO.h"
#import "JAMinecraftSchematic+SchematicIO.h"
#import "JAValueToString.h"


#define DEBUG_LOGGING	(!defined(NDEBUG))
#if DEBUG_LOGGING
#define LOG Print
static inline NSString *ExtentsDesc(JACircuitExtents extents)
{
	return JACircuitExtentsEmpty(extents) ? @"empty" : JA_ENCODE(extents);
}
#else
#define LOG(...) do {} while (0)
#endif


static NSString *GetPath(const char *path);
static void FPrintv(FILE *file, NSString *format, va_list args);
static void Print(NSString *format, ...);
static void FPrint(FILE *file, NSString *format, ...);
static void EPrint(NSString *format, ...);

static void PrintHelpAndExit(void) __attribute__((noreturn));


typedef JAMinecraftSchematic *(*CircuitProcessor)(JAMinecraftSchematic *currentCircuit, NSUInteger argc, NSUInteger *consumed, const char *argv[]);


typedef struct
{
	const char				*command;
	char					shortcut;
	CircuitProcessor		process;
	unsigned				minArgs;
	
	const char				*paramDesc;
	const char				*helpString;
} ProcessDefinition;


/*
	In accordance with C tradition, argc and argv include the command word
	itself at slot 0.
	
	consumed is the number of arguments acutally used. It is initialized to
	minArgs.
 */
static JAMinecraftSchematic *ProcessInputFile(JAMinecraftSchematic *currentCircuit, NSUInteger argc, NSUInteger *consumed, const char *argv[]);
static JAMinecraftSchematic *ProcessMove(JAMinecraftSchematic *currentCircuit, NSUInteger argc, NSUInteger *consumed, const char *argv[]);
static JAMinecraftSchematic *ProcessFlipX(JAMinecraftSchematic *currentCircuit, NSUInteger argc, NSUInteger *consumed, const char *argv[]);
static JAMinecraftSchematic *ProcessFlipY(JAMinecraftSchematic *currentCircuit, NSUInteger argc, NSUInteger *consumed, const char *argv[]);
static JAMinecraftSchematic *ProcessRotate180(JAMinecraftSchematic *currentCircuit, NSUInteger argc, NSUInteger *consumed, const char *argv[]);
static JAMinecraftSchematic *ProcessRotateClockwise(JAMinecraftSchematic *currentCircuit, NSUInteger argc, NSUInteger *consumed, const char *argv[]);
static JAMinecraftSchematic *ProcessRotateAntiClockwise(JAMinecraftSchematic *currentCircuit, NSUInteger argc, NSUInteger *consumed, const char *argv[]);


const ProcessDefinition kProcesses[] =
{
	{
		"in", 'I',
		ProcessInputFile,
		1,
		"<filename>",
		"Load <filename> (a schematic or rdat file) into the\n                    working schematic, at the origin. Non-air blocks in the\n                    file will replace any blocks in the working schematic. Air\n                    blocks in the file will not replace anything."
	},
	{
		"move", 'M',
		ProcessMove,
		3,
		"<x> <y> <z>",
		"Move the blocks of the working schematic the specified\n                    distance along each axis.\n                    <x> is a distance to the west (resulting in new data being\n                        loaded to the east).\n                    <y> is a distance to the south (resulting in new data\n                        being loaded to the north).\n                    <z> is a distance upward (resulting in new data being\n                        loaded below)."
	},
	{
		"flipx", 'X',
		ProcessFlipX,
		0,
		NULL,
		"Flip the schematic in the east-west direction."
	},
	{
		"flipy", 'Y',
		ProcessFlipY,
		0,
		NULL,
		"Flip the schematic in the north-south direction."
	},
	{
		"rotl", 'L',
		ProcessRotateAntiClockwise,
		0,
		NULL,
		"Rotate the schematic 90 degrees to the left (anti-\n                    clockwise) as seen from above."
	},
	{
		"rotr", 'R',
		ProcessRotateClockwise,
		0,
		NULL,
		"Rotate the schematic 90 degrees to the right (clockwise)\n                    as seen from above."
	},
	{
		"rot180", 'O',
		ProcessRotate180,
		0,
		NULL,
		"Rotate the schematic 180 degrees."
	},
};


const NSUInteger kProcessCount = sizeof kProcesses / sizeof *kProcesses;


int main (int argc, const char * argv[])
{
	if (argc < 2 || strcasecmp(argv[1], "--help") == 0 || strcmp(argv[1], "-?") == 0)
	{
		PrintHelpAndExit();
	}
	
	NSString *outputPath = GetPath(argv[1]);
	if (outputPath == nil)
	{
		EPrint(@"Failed to resolve output path \"%s\".\n", argv[1]);
		return EXIT_FAILURE;
	}
	
	JAMinecraftSchematic *outputCircuit = [JAMinecraftSchematic new];
	
	for (int n = 2; n < argc; n++)
	{
		LOG(@"[processing command \"%s\"]\n", argv[n]);
		
		char shortcut = 0;
		const char *arg = argv[n];
		if (arg[0] == '-')
		{
			if (arg[1] == '-')  arg += 2;
			else  shortcut = arg[1];
		}
		
		BOOL match = NO;
		for (NSUInteger p = 0; p < kProcessCount; p++)
		{
			const ProcessDefinition *process = &kProcesses[p];
			if (shortcut != 0)  match = (shortcut == process->shortcut);
			else  match = !strcmp(arg, process->command);
			
			if (match)
			{
				if (argc <= process->minArgs)
				{
					EPrint(@"Not enough arguments to command %s.\n", arg);
					return EXIT_FAILURE;
				}
				
				NSUInteger consumed = process->minArgs;
				outputCircuit = process->process(outputCircuit, argc - n, &consumed, argv + n);
				n += consumed;
				
				break;
			}
		}
		
		if (!match)
		{
			EPrint(@"Unknown command %s.\n", arg);
			return EXIT_FAILURE;
		}
		
		LOG(@"[extents: %@]\n", ExtentsDesc(outputCircuit.extents));
	}
	
	JACircuitExtents outputExtents = outputCircuit.extents;
	if (JACircuitExtentsEmpty(outputExtents))
	{
		Print(@"Resulting circuit is empty, not writing.\n");
		return EXIT_SUCCESS;
	}
	else
	{
		Print(@"Resulting circuit size is %lu × %lu × %lu.\n", JACircuitExtentsLength(outputExtents), JACircuitExtentsWidth(outputExtents), JACircuitExtentsHeight(outputExtents));
	}
	
	NSData *outputData = nil;
	NSError *error = nil;
	if ([[[outputPath pathExtension] lowercaseString] isEqualToString:@"rdat"])
	{
		outputData = [outputCircuit rDatDataWithError:&error];
	}
	else
	{
		outputData = [outputCircuit schematicDataWithError:&error];
	}
	
	if (outputData == nil)
	{
		EPrint(@"Could not write circuit data.\n");
		return EXIT_FAILURE;
	}
	
	[outputData writeToFile:outputPath atomically:YES];
	
    return 0;
}


static JAMinecraftSchematic *ProcessInputFile(JAMinecraftSchematic *currentCircuit, NSUInteger argc, NSUInteger *consumed, const char *argv[])
{
	NSString *path = GetPath(argv[1]);
	NSData *data = [NSData dataWithContentsOfFile:path];
	
	JAMinecraftSchematic *loaded = nil;
	NSError *error = nil;
	
	if (data != nil)
	{
		if ([[[path pathExtension] lowercaseString] isEqualToString:@"rdat"])
		{
			loaded = [[JAMinecraftSchematic alloc] initWithRDatData:data error:&error];
		}
		else
		{
			loaded = [[JAMinecraftSchematic alloc] initWithSchematicData:data error:&error];
		}
	}
	
	if (loaded == nil)
	{
		EPrint(@"Could not load %s.\n", argv[1]);
		exit(EXIT_FAILURE);
	}
	
	LOG(@"[Loaded file with extents %@]\n", ExtentsDesc(loaded.extents));
	
	[currentCircuit copyRegion:loaded.extents from:loaded at:(JACellLocation){ 0, 0, 0 }];
	
	return currentCircuit;
}


static JAMinecraftSchematic *ProcessMove(JAMinecraftSchematic *currentCircuit, NSUInteger argc, NSUInteger *consumed, const char *argv[])
{
	JACellLocation dst;
	JACircuitExtents srcExtents = currentCircuit.extents;
	dst.z = atoll(argv[1]) - srcExtents.minZ;
	dst.x = atoll(argv[2]) - srcExtents.minX;
	dst.y = atoll(argv[3]) - srcExtents.minY;
	
	JAMinecraftSchematic *moved = [JAMinecraftSchematic new];
	[moved copyRegion:srcExtents from:currentCircuit at:dst];
	
	return moved;
}


static JAMinecraftSchematic *ProcessFlipX(JAMinecraftSchematic *currentCircuit, NSUInteger argc, NSUInteger *consumed, const char *argv[])
{
	JAMinecraftSchematic *result = [JAMinecraftSchematic new];
	JACircuitExtents extents = currentCircuit.extents;
	NSUInteger length = JACircuitExtentsLength(extents);
	NSUInteger width = JACircuitExtentsWidth(extents);
	NSUInteger height = JACircuitExtentsHeight(extents);
	
	for (NSUInteger z = 0; z < length; z++)
	{
		for (NSUInteger y = 0; y < height; y++)
		{
			for (NSUInteger x = 0; x < width; x++)
			{
				JACellLocation loc = { extents.minX + x, extents.minY + y, extents.minZ + z };
				JAMinecraftCell cell = [currentCircuit cellAt:loc];
				loc.z = extents.maxZ - z;
				MCCellSetOrientation(&cell, JADirectionFlipEastWest(MCCellGetOrientation(cell)));
				[result setCell:cell at:loc];
			}
		}
	}
	
	return result;
}


static JAMinecraftSchematic *ProcessFlipY(JAMinecraftSchematic *currentCircuit, NSUInteger argc, NSUInteger *consumed, const char *argv[])
{
	JAMinecraftSchematic *result = [JAMinecraftSchematic new];
	JACircuitExtents extents = currentCircuit.extents;
	NSUInteger length = JACircuitExtentsLength(extents);
	NSUInteger width = JACircuitExtentsWidth(extents);
	NSUInteger height = JACircuitExtentsHeight(extents);
	
	for (NSUInteger z = 0; z < length; z++)
	{
		for (NSUInteger y = 0; y < height; y++)
		{
			for (NSUInteger x = 0; x < width; x++)
			{
				JACellLocation loc = { extents.minX + x, extents.minY + y, extents.minZ + z };
				JAMinecraftCell cell = [currentCircuit cellAt:loc];
				loc.x = extents.maxX - x;
				MCCellSetOrientation(&cell, JADirectionFlipNorthSouth(MCCellGetOrientation(cell)));
				[result setCell:cell at:loc];
			}
		}
	}
	
	return result;
}


static JAMinecraftSchematic *ProcessRotate180(JAMinecraftSchematic *currentCircuit, NSUInteger argc, NSUInteger *consumed, const char *argv[])
{
	JAMinecraftSchematic *result = [JAMinecraftSchematic new];
	JACircuitExtents extents = currentCircuit.extents;
	NSUInteger length = JACircuitExtentsLength(extents);
	NSUInteger width = JACircuitExtentsWidth(extents);
	NSUInteger height = JACircuitExtentsHeight(extents);
	
	for (NSUInteger z = 0; z < length; z++)
	{
		for (NSUInteger y = 0; y < height; y++)
		{
			for (NSUInteger x = 0; x < width; x++)
			{
				JACellLocation loc = { extents.minX + x, extents.minY + y, extents.minZ + z };
				JAMinecraftCell cell = [currentCircuit cellAt:loc];
				loc.x = extents.maxX - x;
				loc.z = extents.maxZ - z;
				MCCellSetOrientation(&cell, JADirectionFlipNorthSouth(JADirectionFlipEastWest(MCCellGetOrientation(cell))));
				[result setCell:cell at:loc];
			}
		}
	}
	
	return result;
}


static JAMinecraftSchematic *ProcessRotateClockwise(JAMinecraftSchematic *currentCircuit, NSUInteger argc, NSUInteger *consumed, const char *argv[])
{
	JAMinecraftSchematic *result = [JAMinecraftSchematic new];
	JACircuitExtents extents = currentCircuit.extents;
	NSUInteger length = JACircuitExtentsLength(extents);
	NSUInteger width = JACircuitExtentsWidth(extents);
	NSUInteger height = JACircuitExtentsHeight(extents);
	
	for (NSUInteger z = 0; z < length; z++)
	{
		for (NSUInteger y = 0; y < height; y++)
		{
			for (NSUInteger x = 0; x < width; x++)
			{
				JACellLocation loc = { extents.minX + x, extents.minY + y, extents.minZ + z };
				JAMinecraftCell cell = [currentCircuit cellAt:loc];
				loc.z = loc.x;
				loc.x = extents.maxZ - z;
				MCCellSetOrientation(&cell, JARotateClockwise(MCCellGetOrientation(cell)));
				[result setCell:cell at:loc];
			}
		}
	}
	
	return result;
}


static JAMinecraftSchematic *ProcessRotateAntiClockwise(JAMinecraftSchematic *currentCircuit, NSUInteger argc, NSUInteger *consumed, const char *argv[])
{
	JAMinecraftSchematic *result = [JAMinecraftSchematic new];
	JACircuitExtents extents = currentCircuit.extents;
	NSUInteger length = JACircuitExtentsLength(extents);
	NSUInteger width = JACircuitExtentsWidth(extents);
	NSUInteger height = JACircuitExtentsHeight(extents);
	
	for (NSUInteger z = 0; z < length; z++)
	{
		for (NSUInteger y = 0; y < height; y++)
		{
			for (NSUInteger x = 0; x < width; x++)
			{
				JACellLocation loc = { extents.minX + x, extents.minY + y, extents.minZ + z };
				JAMinecraftCell cell = [currentCircuit cellAt:loc];
				loc.x = loc.z;
				loc.z = extents.maxX - x;
				MCCellSetOrientation(&cell, JARotateAntiClockwise(MCCellGetOrientation(cell)));
				[result setCell:cell at:loc];
			}
		}
	}
	
	return result;
}


static void PrintHelpAndExit(void)
{
#define INDENT_WIDTH 19
	
	printf("mcxform " VERSION_STRING " © 2010 Jens Ayton\n\nusage: mcxform --help\n       mcxform <outputfile> [commands]\n\nmcxform is a tool for manipulating Minecraft schematics, as used by tools such\nas MCEdit and Redstone Simulator. mcxform works by loading schematics into a\n“working schematic” in memory, performing actions on this working schematic,\nand writing it out when all commands are completed. For example, to place two\ncopies of a schematic side by side:\n\n  mcxform out.schematic --in in.schematic --move 20 0 0 --in in.schematic\n\nThis command loads “in.schematic” into the working schematic at the origin,\nmoves the contents of the working schematic 20 steps to the west, and loads\n“in.schematic” at the origin again – which is now 20 steps to the east of the\noriginal. It then writes the combined result to out.schematic.\n\nNOTES:\n  • mcxform does not preserve entities and tile entities. This is not a\n    problem for redstone circuits, but may be for arbitrary map segments from MCEdit.\n  • mcxform trims away empty space (air blocks) on all sides of the working\n    schematic before saving. This can be exploited to trim a schematic without\n    any other transformations:\n       mcxform trimmed.schematic --in source.schematic\n    There is currently no way to stop it from trimming space.\n  • mcxform can read both schematic files and Redstone Simulator rdat files.\n    However, they are treated somewhat differently. Redstone Simulator reads\n    and writes schematics with north to the left of its window, which I assume\n    is a bug. mcxform loads schematics correctly, and loads rdat files with\n    the top of Redstone Simulator’s window as north. This can lead to\n    surprising results when using both schematics and rdats in one operation.\n\nCommands:\n");
	
	for (NSUInteger i = 0; i < kProcessCount; i++)
	{
		const ProcessDefinition *proc = &kProcesses[i];
		if (proc->helpString != NULL)
		{
			NSUInteger indent;
			indent = printf("--%s", proc->command);
			if (proc->paramDesc != NULL)
			{
				indent += printf(" %s", proc->paramDesc);
			}
			printf(":");
			while (indent < INDENT_WIDTH)
			{
				printf(" ");
				indent++;
			}
			
			printf("%s\n", proc->helpString);
		}
	}
	
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
