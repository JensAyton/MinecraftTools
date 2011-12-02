/*
	Classes for tracking terrain statistics.
	
	The statistic classes are not thread safe. Instead, statistics for each
	region are gathered asyncronously, then merged together on the main queue.
*/


#import <Foundation/Foundation.h>


@interface JATerrainTypeHistorgram: NSObject

- (NSUInteger) valueForBlockType:(uint8_t)type;
- (void) setValue:(NSUInteger)value forBlockType:(uint8_t)type;
- (void) incrementValueForBlockType:(uint8_t)type;

- (void) addValuesFromHistogram:(JATerrainTypeHistorgram *)other;

@end


@interface JATerrainTypeByLayerHistorgram: NSObject

- (NSUInteger) valueForBlockType:(uint8_t)type onLayer:(uint8_t)layer;
- (void) setValue:(NSUInteger)value forBlockType:(uint8_t)type onLayer:(uint8_t)layer;
- (void) incrementValueForBlockType:(uint8_t)type onLayer:(uint8_t)layer;

- (void) addValuesFromHistogram:(JATerrainTypeByLayerHistorgram *)other;

@end


@interface JATerrainStatistics: NSObject

@property (readonly, strong, nonatomic) JATerrainTypeByLayerHistorgram *countsByLayer;	// Sum of blocks per layer
@property (readonly, strong, nonatomic) JATerrainTypeHistorgram *totalCounts;				// Sum of blocks on all layers
@property (readonly, strong, nonatomic) JATerrainTypeHistorgram *adjacentToAirCounts;		// Counts for blocks whose six face neighbours include air
@property (readonly, strong, nonatomic) JATerrainTypeHistorgram *adjacentToLavaCounts;		// Counts for blocks whose six face neighbours include lava
@property (readonly, strong, nonatomic) JATerrainTypeHistorgram *topmostCounts;				// Counts for highest block that’s not air
@property (readonly, strong, nonatomic) JATerrainTypeHistorgram *topmostTerrainCounts;		// Counts for highest block that’s opaque or liquid

@property (readonly) NSUInteger chunkCount;
@property (readonly) NSUInteger rejectedChunkCount;
@property (readonly) NSUInteger regionCount;

- (void) incrementChunkCount;
- (void) incrementRejectedChunkCount;
- (void) incrementRegionCount;

- (void) addValuesFromStatistics:(JATerrainStatistics *)other;

@end
