/*
	JAMinecraftSchematic+SchematicIO.h
	
	Support for importing and exporting schematic files, the de facto standard
	interchange format for partial Minecraft maps.
	
	For format documentation, see:
	http://www.minecraftwiki.net/wiki/Schematic_File_Format
	http://www.minecraft.net/docs/NBT.txt
	
	IMPORTANT: this does not deal with all aspects of schematics; for instance,
	entities (not tile entities) are ignored.
	
	
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

#import "JAMinecraftSchematic.h"


@interface JAMinecraftSchematic (SchematicIO)

- (id) initWithSchematicData:(NSData *)data error:(NSError **)outError;

- (NSData *) schematicDataWithError:(NSError **)outError;
- (NSData *) schematicDataForRegion:(MCGridExtents)region withError:(NSError **)outError;

@end


extern NSString * const kJAMinecraftSchematicUTI;	// "com.davidvierra.mcedit.schematic"
