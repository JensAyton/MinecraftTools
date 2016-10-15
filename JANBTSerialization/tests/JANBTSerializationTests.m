#import <XCTest/XCTest.h>

#import "JANBTSerialization.h"

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
		@"byteArrayTest (the first 1000 values of (n*n*255+n*7)%100, starting with n=0 (0, 62, 34, 16, 8, ...))": self.bigTestBytes,
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

@end
