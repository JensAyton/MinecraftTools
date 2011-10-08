#import <Foundation/Foundation.h>


@interface NSArray (JACollectionBlocks)

- (NSArray *) ja_map:(id(^)(id value))mapper;

@end


@interface NSDictionary (JACollectionBlocks)

- (NSDictionary *) ja_mapValues:(id(^)(id key, id value))mapper;

- (NSDictionary *) ja_dictionaryByRemovingObjectsForKeys:(NSSet *)keys;

@end
