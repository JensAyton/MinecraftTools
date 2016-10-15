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

- (NSData *)testNBTWithName:(NSString *)name
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
	NSData *testNBT = [self testNBTWithName:@"test"];

	NSString *rootName;
	NSError *error;
	id root = [JANBTSerialization NBTObjectWithData:testNBT rootName:&rootName options:JANBTReadingOptionsUncompressed schema:nil error:&error];

	XCTAssertNil(error);
	XCTAssertEqualObjects(rootName, @"hello world");
	XCTAssertEqualObjects(root, @{ @"name": @"Bananrama" });
}

@end
