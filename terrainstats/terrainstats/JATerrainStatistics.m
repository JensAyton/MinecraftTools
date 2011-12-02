#import "JATerrainStatistics.h"


@implementation JATerrainStatistics

@synthesize countsByLayer = _countsByLayer;
@synthesize totalCounts = _totalCounts;
@synthesize adjacentToAirCounts = _adjacentToAirCounts;
@synthesize adjacentToLavaCounts = _adjacentToLavaCounts;
@synthesize topmostCounts = _topmostCounts;
@synthesize topmostTerrainCounts = _topmostTerrainCounts;
@synthesize chunkCount = _chunkCount;
@synthesize rejectedChunkCount = _rejectedChunkCount;
@synthesize regionCount = _regionCount;


- (id) init
{
	if ((self = [super init]))
	{
		_countsByLayer = [JATerrainTypeByLayerHistorgram new];
		_totalCounts = [JATerrainTypeHistorgram new];
		_adjacentToAirCounts = [JATerrainTypeHistorgram new];
		_adjacentToLavaCounts = [JATerrainTypeHistorgram new];
		_topmostCounts = [JATerrainTypeHistorgram new];
		_topmostTerrainCounts = [JATerrainTypeHistorgram new];
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
	[self.adjacentToAirCounts addValuesFromHistogram:other.adjacentToAirCounts];
	[self.adjacentToLavaCounts addValuesFromHistogram:other.adjacentToLavaCounts];
	[self.topmostCounts addValuesFromHistogram:other.topmostCounts];
	[self.topmostTerrainCounts addValuesFromHistogram:other.topmostTerrainCounts];
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
