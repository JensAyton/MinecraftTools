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


#define DEBUG_LOGGING	1
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


typedef JAMinecraftSchematic *(*CircuitProcessor)(JAMinecraftSchematic *currentCircuit, NSUInteger argc, NSUInteger *consumed, const char *argv[]);


typedef struct
{
	const char				*command;
	char					shortcut;
	CircuitProcessor		process;
	unsigned				minArgs;
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
		1
	},
	{
		"move", 'M',
		ProcessMove,
		3
	},
	{
		"flipx", 'X',
		ProcessFlipX,
		0
	},
	{
		"flipy", 'Y',
		ProcessFlipY,
		0
	},
	{
		"rotl", 'L',
		ProcessRotateAntiClockwise,
		0
	},
	{
		"rotr", 'R',
		ProcessRotateClockwise,
		0
	},
	{
		"rot180", 'O',
		ProcessRotate180,
		0
	},
};


const NSUInteger kProcessCount = sizeof kProcesses / sizeof *kProcesses;


int main (int argc, const char * argv[])
{
	if (argc < 2)
	{
		EPrint(@"No output file specified.\n");
		return EXIT_FAILURE;
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
		Print(@"Resulting circuit size is %lu × %lu × %lu.\n", JACircuitExtentsWidth(outputExtents), JACircuitExtentsHeight(outputExtents), JACircuitExtentsDepth(outputExtents));
	}
	
	NSData *outputData = nil;
	NSError *error = nil;
	if ([[[outputPath pathExtension] lowercaseString] isEqualToString:@"rdat"])
	{
		outputData = [outputCircuit rDatDataWithError:&error];
	}
	else
	{
		EPrint(@"Schematic output is not supported.\n");
		return EXIT_FAILURE;
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
	dst.x = atoll(argv[1]) - srcExtents.minX;
	dst.y = atoll(argv[2]) - srcExtents.minY;
	dst.z = atoll(argv[3]) - srcExtents.minY;
	
	JAMinecraftSchematic *moved = [JAMinecraftSchematic new];
	[moved copyRegion:srcExtents from:currentCircuit at:dst];
	
	return moved;
}


static JAMinecraftSchematic *ProcessFlipX(JAMinecraftSchematic *currentCircuit, NSUInteger argc, NSUInteger *consumed, const char *argv[])
{
	JAMinecraftSchematic *result = [JAMinecraftSchematic new];
	JACircuitExtents extents = currentCircuit.extents;
	NSUInteger width = JACircuitExtentsWidth(extents);
	NSUInteger height = JACircuitExtentsHeight(extents);
	NSUInteger depth = JACircuitExtentsDepth(extents);
	
	for (NSUInteger z = 0; z < depth; z++)
	{
		for (NSUInteger y = 0; y < height; y++)
		{
			for (NSUInteger x = 0; x < width; x++)
			{
				JACellLocation loc = { extents.minX + x, extents.minY + y, extents.minZ + z };
				JAMinecraftCell cell = [currentCircuit cellAt:loc];
				loc.x = extents.maxX - x;
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
	NSUInteger width = JACircuitExtentsWidth(extents);
	NSUInteger height = JACircuitExtentsHeight(extents);
	NSUInteger depth = JACircuitExtentsDepth(extents);
	
	for (NSUInteger z = 0; z < depth; z++)
	{
		for (NSUInteger y = 0; y < height; y++)
		{
			for (NSUInteger x = 0; x < width; x++)
			{
				JACellLocation loc = { extents.minX + x, extents.minY + y, extents.minZ + z };
				JAMinecraftCell cell = [currentCircuit cellAt:loc];
				loc.y = extents.maxY - y;
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
	NSUInteger width = JACircuitExtentsWidth(extents);
	NSUInteger height = JACircuitExtentsHeight(extents);
	NSUInteger depth = JACircuitExtentsDepth(extents);
	
	for (NSUInteger z = 0; z < depth; z++)
	{
		for (NSUInteger y = 0; y < height; y++)
		{
			for (NSUInteger x = 0; x < width; x++)
			{
				JACellLocation loc = { extents.minX + x, extents.minY + y, extents.minZ + z };
				JAMinecraftCell cell = [currentCircuit cellAt:loc];
				loc.x = extents.maxX - x;
				loc.y = extents.maxY - y;
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
	NSUInteger width = JACircuitExtentsWidth(extents);
	NSUInteger height = JACircuitExtentsHeight(extents);
	NSUInteger depth = JACircuitExtentsDepth(extents);
	
	for (NSUInteger z = 0; z < depth; z++)
	{
		for (NSUInteger y = 0; y < height; y++)
		{
			for (NSUInteger x = 0; x < width; x++)
			{
				JACellLocation loc = { extents.minX + x, extents.minY + y, extents.minZ + z };
				JAMinecraftCell cell = [currentCircuit cellAt:loc];
				loc.y = loc.x;
				loc.x = extents.maxY - y;
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
	NSUInteger width = JACircuitExtentsWidth(extents);
	NSUInteger height = JACircuitExtentsHeight(extents);
	NSUInteger depth = JACircuitExtentsDepth(extents);
	
	for (NSUInteger z = 0; z < depth; z++)
	{
		for (NSUInteger y = 0; y < height; y++)
		{
			for (NSUInteger x = 0; x < width; x++)
			{
				JACellLocation loc = { extents.minX + x, extents.minY + y, extents.minZ + z };
				JAMinecraftCell cell = [currentCircuit cellAt:loc];
				loc.x = loc.y;
				loc.y = extents.maxX - x;
				MCCellSetOrientation(&cell, JARotateAntiClockwise(MCCellGetOrientation(cell)));
				[result setCell:cell at:loc];
			}
		}
	}
	
	return result;
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
