#import "JATerrainStatistics.h"


@implementation JATerrainStatistics

@synthesize countsByLayer = _countsByLayer;
@synthesize totalCounts = _totalCounts;
@synthesize adjacentToAirBelow60Counts = _adjacentToAirBelow60Counts;
@synthesize nonadjacentToAirBelow60Counts = _nonadjacentToAirBelow60Counts;
@synthesize topmostCounts = _topmostCounts;
@synthesize topmostTerrainCounts = _topmostTerrainCounts;
@synthesize spawnerMobs = _spawnerMobs;
@synthesize chestContents = _chestContents;
@synthesize chunkCount = _chunkCount;
@synthesize rejectedChunkCount = _rejectedChunkCount;
@synthesize regionCount = _regionCount;


- (id) init
{
	if ((self = [super init]))
	{
		_countsByLayer = [JATerrainTypeByLayerHistorgram new];
		_totalCounts = [JATerrainTypeHistorgram new];
		_adjacentToAirBelow60Counts = [JATerrainTypeHistorgram new];
		_nonadjacentToAirBelow60Counts = [JATerrainTypeHistorgram new];
		_topmostCounts = [JATerrainTypeHistorgram new];
		_topmostTerrainCounts = [JATerrainTypeHistorgram new];
		_spawnerMobs = [JAObjectHistogram new];
		_chestContents = [JAObjectHistogram new];
	}
	
	return self;
}


- (void) incrementChunkCount
{
	_chunkCount++;
}


- (void) incrementRejectedChunkCount
{
	_rejectedChunkCount++;
}


- (void) incrementRegionCount
{
	_regionCount++;
}


- (void) addValuesFromStatistics:(JATerrainStatistics *)other
{
	[self.countsByLayer addValuesFromHistogram:other.countsByLayer];
	[self.totalCounts addValuesFromHistogram:other.totalCounts];
	[self.adjacentToAirBelow60Counts addValuesFromHistogram:other.adjacentToAirBelow60Counts];
	[self.nonadjacentToAirBelow60Counts addValuesFromHistogram:other.nonadjacentToAirBelow60Counts];
	[self.topmostCounts addValuesFromHistogram:other.topmostCounts];
	[self.topmostTerrainCounts addValuesFromHistogram:other.topmostTerrainCounts];
	[self.spawnerMobs addValuesFromHistogram:other.spawnerMobs];
	[self.chestContents addValuesFromHistogram:other.chestContents];
	_chunkCount += other.chunkCount;
	_rejectedChunkCount += other.rejectedChunkCount;
	_regionCount += other.regionCount;
}

@end


@implementation JATerrainTypeHistorgram
{
	NSUInteger				_counts[256];
}


- (NSUInteger) valueForBlockType:(uint8_t)type
{
	return _counts[type];
}


- (void) setValue:(NSUInteger)value forBlockType:(uint8_t)type
{
	_counts[type] = value;
}


- (void) incrementValueForBlockType:(uint8_t)type
{
	_counts[type]++;
}


- (void) addValuesFromHistogram:(JATerrainTypeHistorgram *)other
{
	for (NSUInteger i = 0; i < 256; i++)
	{
		_counts[i] += [other valueForBlockType:i];
	}
}

@end


@implementation JATerrainTypeByLayerHistorgram
{
	NSUInteger				_counts[256][128];
}

- (NSUInteger) valueForBlockType:(uint8_t)type onLayer:(uint8_t)layer
{
	NSParameterAssert(layer < 128);
	
	return _counts[type][layer];
}


- (void) setValue:(NSUInteger)value forBlockType:(uint8_t)type onLayer:(uint8_t)layer
{
	NSParameterAssert(layer < 128);
	
	_counts[type][layer] = value;
}


- (void) incrementValueForBlockType:(uint8_t)type onLayer:(uint8_t)layer
{
	NSParameterAssert(layer < 128);
	
	_counts[type][layer]++;
}


- (void) addValuesFromHistogram:(JATerrainTypeByLayerHistorgram *)other
{
	for (NSUInteger type = 0; type < 256; type++)
	{
		for (NSUInteger layer = 0; layer < 128; layer++)
		{
			_counts[type][layer] += [other valueForBlockType:type onLayer:layer];
		}
	}
}

@end


@implementation JAObjectHistogram
{
	NSMutableDictionary			*_data;
}

- (id) init
{
	if ((self = [super init]))
	{
		_data = [NSMutableDictionary new];
	}
	return self;
}


- (NSUInteger) valueForObject:(id <NSCopying>)object
{
	return [[_data objectForKey:object] unsignedIntegerValue];
}


- (void) setValue:(NSUInteger)value forObject:(id <NSCopying>)object
{
	[_data setObject:[NSNumber numberWithUnsignedInteger:value] forKey:object];
}


- (void) addValue:(NSUInteger)delta forObject:(id <NSCopying>)object
{
	[self setValue:[self valueForObject:object] + delta forObject:object];
}


- (void) incrementValueForObject:(id <NSCopying>)object
{
	[self addValue:1 forObject:object];
}


- (NSArray *) knownObjects
{
	return _data.allKeys;
}


- (void) addValuesFromHistogram:(JAObjectHistogram *)other
{
	for (id object in other.knownObjects)
	{
		[self setValue:[self valueForObject:object] + [other valueForObject:object] forObject:object];
	}
}

@end

