#import "JACollectionHelpers.h"

#if defined(__has_feature) && __has_feature(objc_arc)
#define HAS_ARC		1
#else
#define HAS_ARC		0
#endif


enum
{
	KMaxStackBuffer = 128
};


@implementation NSArray (JACollectionBlocks)

- (NSArray *) ja_map:(id(^)(id value))mapper
{
#if HAS_ARC
	// FIXME: use horrible pointer cast annotations in ARC?
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
	
	for (id value in self)
	{
		[result addObject:mapper(value)];
	}
	return [result copy];
	
#else
	id				*results = NULL;
	NSUInteger		count = self.count;
	size_t			size = sizeof (id) * count;
	BOOL			useHeap = count > KMaxStackBuffer;
	
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
#endif
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
#if HAS_ARC
	// FIXME: use horrible pointer cast annotations in ARC?
	NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:self.count];
	
	for (id key in self)
	{
		if (![excludeKeys containsObject:key])
		{
			[result setObject:[self objectForKey:key] forKey:key];
		}
	}
	
	return [result copy];
#else
	id				*keys = NULL, *values = NULL;
	NSUInteger		count = self.count, i = 0;
	size_t			size = sizeof (id) * count;
	BOOL			useHeap = count > KMaxStackBuffer / 2;
	
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
#endif
}

@end

