/*
	Schema loading: in JAMinecraftKit.framework, schemata are stored in
	property list files inside the framework. In libminecraftkit, schemata
	are instead compiled into the code as binary plists. This file provides
	uniform access to both representations.
*/

#if MCKIT_STATIC

#import "SchematicSchema.h"
#import "DataSchema.h"
#import "ChunkSchema.h"
#import "AnvilChunkSchema.h"
#import "BlockDescriptions.h"

#else
#import "JAMinecraftBlock.h"

static inline id GetNamedSchema(NSString *name)
{
	return [NSDictionary dictionaryWithContentsOfURL:[[NSBundle bundleForClass:[JAMinecraftBlock class]] URLForResource:name withExtension:@"schema"]];
}


static inline id GetSchematicSchema(void)
{
	return GetNamedSchema(@"Schematic");
}


static inline id GetDataSchema(void)
{
	return GetNamedSchema(@"Data");
}


static inline id GetChunkSchema(void)
{
	return GetNamedSchema(@"Chunk");
}


static inline id GetAnvilChunkSchema(void)
{
	return GetNamedSchema(@"AnvilChunk");
}


static inline id GetBlockDescriptions(void)
{
	return [NSDictionary dictionaryWithContentsOfURL:[[NSBundle bundleForClass:[JAMinecraftBlock class]] URLForResource:@"BlockDescriptions" withExtension:@"plist"]];
}

#endif
