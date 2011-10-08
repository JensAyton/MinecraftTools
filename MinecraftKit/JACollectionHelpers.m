//
//  JACollectionHelpers.m
//
//  Created by Jens Ayton on 2011-10-08.
//  Copyright 2011 Jens Ayton. All rights reserved.
//

#import "JACollectionHelpers.h"

enum
{
	KMaxStackBuffer = 128
};


@implementation NSArray (JACollectionBlocks)

- (NSArray *) ja_map:(id(^)(id value))mapper
{
	id			*results = NULL;
	NSUInteger	count = self.count;
	size_t		size = sizeof (id) * count;
	BOOL		useHeap = count > KMaxStackBuffer;
	
	results = alloca((!useHeap) ? size : 1);
	
	if (useHeap)
	{
		results = malloc(size);
		if (__builtin_expect(results == NULL, NO))
		{
			[NSException raise:NSMallocException format:@"Could not allocate memory."];
		}
	}
	
	@try
	{
		NSUInteger i = 0;
		for (id value in self)
		{
			results[i++] = mapper(value);
		}
		
		return [NSArray arrayWithObjects:results count:count];
	}
	@finally
	{
		if (useHeap)  free(results);
	}
}

@end


@implementation NSDictionary (JACollectionBlocks)

- (NSDictionary *) ja_mapValues:(id(^)(id key, id value))mapper
{
	NSArray *keys = self.allKeys;
	NSArray *values = [keys ja_map:^(id key)
	{
		return mapper(key, [self objectForKey:key]);
	}];
	return [NSDictionary dictionaryWithObjects:values forKeys:keys];
}


- (NSDictionary *) ja_dictionaryByRemovingObjectsForKeys:(NSSet *)excludeKeys
{
	id			*keys = NULL, *values = NULL;
	NSUInteger	count = self.count, i = 0;
	size_t		size = sizeof (id) * count;
	BOOL		useHeap = count > KMaxStackBuffer / 2;
	
	keys = alloca((!useHeap) ? size : 1);
	values = alloca((!useHeap) ? size : 1);
	
	@try
	{
		if (useHeap)
		{
			keys = malloc(size);
			values = malloc(size);
			
			if (__builtin_expect(keys == NULL || values == NULL, NO))
			{
				[NSException raise:NSMallocException format:@"Could not allocate memory."];
			}
		}
		
		for (id key in self)
		{
			if (![excludeKeys containsObject:key])
			{
				keys[i] = key;
				values[i] = [self objectForKey:key];
				i++;
			}
		}
		
		return [NSDictionary dictionaryWithObjects:values forKeys:keys count:i];
	}
	@finally
	{
		if (useHeap)
		{
			free(keys);
			free(values);
		}
	}
}

@end

