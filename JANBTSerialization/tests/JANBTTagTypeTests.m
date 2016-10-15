#import <XCTest/XCTest.h>

#import "JANBTTagType.h"
#import "JANBTTypedNumbers.h"

@interface JANBTTagTypeTests : XCTestCase

@end


@implementation JANBTTagTypeTests

- (void)testJANBTIsNumericalTagType
{
	XCTAssertFalse(JANBTIsNumericalTagType(kJANBTTagEnd));
	XCTAssertTrue (JANBTIsNumericalTagType(kJANBTTagByte));
	XCTAssertTrue (JANBTIsNumericalTagType(kJANBTTagShort));
	XCTAssertTrue (JANBTIsNumericalTagType(kJANBTTagInt));
	XCTAssertTrue (JANBTIsNumericalTagType(kJANBTTagLong));
	XCTAssertTrue (JANBTIsNumericalTagType(kJANBTTagFloat));
	XCTAssertTrue (JANBTIsNumericalTagType(kJANBTTagDouble));
	XCTAssertFalse(JANBTIsNumericalTagType(kJANBTTagByteArray));
	XCTAssertFalse(JANBTIsNumericalTagType(kJANBTTagString));
	XCTAssertFalse(JANBTIsNumericalTagType(kJANBTTagList));
	XCTAssertFalse(JANBTIsNumericalTagType(kJANBTTagCompound));
	XCTAssertFalse(JANBTIsNumericalTagType(kJANBTTagIntArray));
	XCTAssertFalse(JANBTIsNumericalTagType(kJANBTTagIntArrayContent));
	XCTAssertFalse(JANBTIsNumericalTagType(kJANBTTagAny));
	XCTAssertFalse(JANBTIsNumericalTagType(kJANBTTagUnknown));
}

- (void)testNBTTypeAccessor
{
	XCTAssertEqual([NSObject new].NBTType, kJANBTTagUnknown);
	XCTAssertEqual(@"".NBTType, kJANBTTagString);
	XCTAssertTrue(JANBTIsNumericalTagType((@1).NBTType));
	XCTAssertEqual(@[].NBTType, kJANBTTagList);
	XCTAssertEqual(@{}.NBTType, kJANBTTagCompound);
	XCTAssertEqual([NSData data].NBTType, kJANBTTagByteArray);
}

- (void)testNBTListElementType
{
	XCTAssertEqual(@[].NBTListElementType, kJANBTTagUnknown);
	XCTAssertTrue(JANBTIsNumericalTagType(@[@1].NBTListElementType));
	XCTAssertEqual(@[[NSData data]].NBTListElementType, kJANBTTagByteArray);

	NSArray *testArray = @[@""];
	XCTAssertEqual(testArray.NBTListElementType, kJANBTTagString);

	// Explicit value should override.
	testArray.NBTListElementType = kJANBTTagByte;
	XCTAssertEqual(testArray.NBTListElementType, kJANBTTagByte);
}

- (void)testNBTInteger
{
	NSNumber *value;
	value = [[JANBTInteger alloc] initWithValue:15 type:kJANBTTagLong];
	XCTAssertEqualObjects(value, @15);
	XCTAssertEqual(value.NBTType, kJANBTTagLong);
	
	value = [[JANBTInteger alloc] initWithValue:15 type:kJANBTTagByte];
	XCTAssertEqualObjects(value, @15);
	XCTAssertEqual(value.NBTType, kJANBTTagByte);
}

- (void)testNBTFloat
{
	NSNumber *value;
	value = [[JANBTFloat alloc] initWithValue:0.25];
	XCTAssertEqualObjects(value, @0.25);
	XCTAssertEqual(value.NBTType, kJANBTTagFloat);
}

- (void)testNBTDouble
{
	NSNumber *value;
	value = [[JANBTDouble alloc] initWithValue:0.25];
	XCTAssertEqualObjects(value, @0.25);
	XCTAssertEqual(value.NBTType, kJANBTTagDouble);
}

@end
