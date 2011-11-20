#import "JACollectionHelpers.h"

#if defined(__has_feature) && __has_feature(objc_arc)
#define HAS_ARC				1
#else
#define HAS_ARC				0
#endif

enum
{
	KMaxStackBuffer = 128
};


#if HAS_ARC
/*
	CFArrayCallBacks which release a value but don’t retain it.
	This allows us to minimize retain/release traffic under ARC by using
	__bridge_retained to take ownership of mapped values.
	
	We could instead use __bridge and the default callbacks. The result would
	semantically be the same. However, by using __bridge_retained we get to use
	objc_retainAutoreleasedReturnValue(), which avoids putting the result of
	the mapper in an autorelease pool if the mapper is implemented in ARC
	code.
*/

static void ReleaseCallback(CFAllocatorRef allocator, const void *value)
{
	CFRelease(value);
}


static const CFArrayCallBacks kOwnershipTakingArrayCallbacks =
{
	0,
	NULL,
	ReleaseCallback,
	CFCopyDescription,
	CFEqual
};
#endif


@implementation NSArray (JACollectionBlocks)

- (NSArray *) ja_map:(id(^)(id value))mapper
{
	const void		**results = NULL;
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
			id mapped = mapper(value);
#if HAS_ARC
			if (__builtin_expect(mapped == nil, 0))
			{
				// N.b.: +[NSArray arrayWithObjects:count:] handles this for
				// us in non-ARC mode, but CFArrayCreate does not.
				[NSException raise:NSInvalidArgumentException format:@"attempt to map to nil object at mapper(objects[%lu])", i];
			}
			
			results[i++] = (__bridge_retained void *)mapped;
#else
			results[i++] = (void *)mapped;
#endif
		}
		
#if HAS_ARC
		CFArrayRef result = CFArrayCreate(kCFAllocatorDefault, results, count, &kOwnershipTakingArrayCallbacks);
		return CFBridgingRelease(result);
#else
		[NSArray arrayWithObjects:results count:count];
#endif
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
	const void		**keys = NULL, **values = NULL;
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
#if HAS_ARC
				keys[i] = (__bridge void *)key;
				values[i] = (__bridge void *)[self objectForKey:key];
#else
				keys[i] = key;
				values[i] = [self objectForKey:key];
#endif
				i++;
			}
		}
		
#if HAS_ARC
		CFDictionaryRef result = CFDictionaryCreate(kCFAllocatorDefault, keys, values, i, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		return CFBridgingRelease(result);
#else
		return [NSDictionary dictionaryWithObjects:values forKeys:keys count:i];
#endif
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

