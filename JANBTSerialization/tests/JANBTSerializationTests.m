#import <XCTest/XCTest.h>

#import "JANBTSerialization.h"
#import "JAZLibCompressor.h"
#import "JANBTTagType.h"

@interface JANBTSerializationTests : XCTestCase

@end


@implementation JANBTSerializationTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (NSData *)NBTWithName:(NSString *)name
{
	NSURL *URL = [[NSBundle bundleForClass:self.class] URLForResource:name withExtension:@"nbt"];
	NSAssert(URL != nil, @"Expected file to exist");
	NSData *data = [NSData dataWithContentsOfURL:URL];
	NSAssert(data != nil, @"Expected file to exist");
	return data;
}

- (void)testReadSimpleTest
{
	// This is the basic test.nbt from the NBT spec.
	NSData *testNBT = [self NBTWithName:@"test"];

	NSString *rootName;
	NSError *error;
	id root = [JANBTSerialization NBTObjectWithData:testNBT rootName:&rootName options:JANBTReadingOptionsUncompressed schema:nil error:&error];

	XCTAssertNil(error);
	XCTAssertEqualObjects(rootName, @"hello world");
	XCTAssertEqualObjects(root, @{ @"name": @"Bananrama" });
}

static NSString * const byteArrayTestKey = @"byteArrayTest (the first 1000 values of (n*n*255+n*7)%100, starting with n=0 (0, 62, 34, 16, 8, ...))";

- (void)testReadComplexTest
{
	// This is the bigger test case from the NBT spec. It contains all tags except IntArray.
	NSData *testNBT = [self NBTWithName:@"bigtest"];

	NSString *rootName;
	NSError *error;
	id root = [JANBTSerialization NBTObjectWithData:testNBT rootName:&rootName options:0 schema:nil error:&error];

	NSDictionary *expected =
	  @{
		@"shortTest": @32767,
		@"longTest": @9223372036854775807LL,
		@"floatTest": @0.49823147f,
		@"stringTest": @"HELLO WORLD THIS IS A TEST STRING ÅÄÖ!",
		@"intTest": @2147483647,
		@"nested compound test": @{
			@"ham": @{
				@"name": @"Hampus",
				@"value": @0.75
			},
			@"egg": @{
				@"name": @"Eggbert",
				@"value": @0.5
			}
		},
		@"listTest (long)": @[
			@11,
			@12,
			@13,
			@14,
			@15,
		],
		@"byteTest": @127,
		@"listTest (compound)": @[
			@{
				@"name": @"Compound tag #0",
				@"created-on": @1264099775885LL,
			},
			@{
				@"name": @"Compound tag #1",
				@"created-on": @1264099775885LL,
			},
		],
		byteArrayTestKey: self.bigTestBytes,
		@"doubleTest": @0.4931287132182315
	};

	XCTAssertNil(error);
	XCTAssertEqualObjects(rootName, @"Level");
	XCTAssertEqualObjects(root, expected);
}

- (NSData *)bigTestBytes
{
	NSUInteger n;
	uint8_t result[1000];

	for (n = 0; n < 1000; n++) {
		result[n] = (n*n*255+n*7)%100;
	}
	return [NSData dataWithBytes:result length:1000];
}

- (void)testRoundtripSimpleTest
{
	NSData *testNBT = [self NBTWithName:@"test"];

	NSString *rootName;
	id root = [JANBTSerialization NBTObjectWithData:testNBT rootName:&rootName options:JANBTReadingOptionsUncompressed schema:nil error:nil];

	NSError *error;
	NSData *reencoded = [JANBTSerialization dataWithNBTObject:root rootName:rootName options:JANBTWritingOptionsUncompressed schema:nil error:&error];

	XCTAssertNil(error);
	XCTAssertEqualObjects(testNBT, reencoded);	// NOTE: dictionary only contains one key, so this is OK.
}

- (void)testRoundtripBigTest
{
	NSData *testNBT = [self NBTWithName:@"bigtest"];

	NSString *rootName;
	id root = [JANBTSerialization NBTObjectWithData:testNBT rootName:&rootName options:0 schema:nil error:nil];

	NSError *error;
	NSData *reencoded = [JANBTSerialization dataWithNBTObject:root rootName:rootName options:0 schema:nil error:&error];
	XCTAssertNil(error);

	// Because it's a dictionary, reencoding may have reordered contents. Decoding should provide the same data, though.
	NSDictionary *newRoot = [JANBTSerialization NBTObjectWithData:reencoded rootName:&rootName options:0 schema:nil error:&error];

	XCTAssertNil(error);
	XCTAssertEqualObjects(root, newRoot);

	XCTAssertEqual([newRoot[@"shortTest"] ja_NBTType], kJANBTTagShort);
	XCTAssertEqual([newRoot[@"longTest"] ja_NBTType], kJANBTTagLong);
	XCTAssertEqual([newRoot[@"floatTest"] ja_NBTType], kJANBTTagFloat);
	XCTAssertEqual([newRoot[@"stringTest"] ja_NBTType], kJANBTTagString);
	XCTAssertEqual([newRoot[@"intTest"] ja_NBTType], kJANBTTagInt);
	XCTAssertEqual([newRoot[@"nested compound test"] ja_NBTType], kJANBTTagCompound);
	XCTAssertEqual([newRoot[@"listTest (long)"] ja_NBTType], kJANBTTagList);
	XCTAssertEqual([newRoot[@"listTest (long)"] ja_NBTListElementType], kJANBTTagLong);
	XCTAssertEqual([newRoot[@"byteTest"] ja_NBTType], kJANBTTagByte);
	XCTAssertEqual([newRoot[@"listTest (compound)"] ja_NBTType], kJANBTTagList);
	XCTAssertEqual([newRoot[@"listTest (compound)"] ja_NBTListElementType], kJANBTTagCompound);
	XCTAssertEqual([newRoot[byteArrayTestKey] ja_NBTType], kJANBTTagByteArray);
	XCTAssertEqual([newRoot[@"doubleTest"] ja_NBTType], kJANBTTagDouble);
}

@end
