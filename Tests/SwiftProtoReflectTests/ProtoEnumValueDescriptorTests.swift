import XCTest

@testable import SwiftProtoReflect

class ProtoEnumValueDescriptorTests: XCTestCase {

  // Positive Test: Create valid enum value descriptor
  func testValidEnumValueDescriptor() {
    let enumValue = ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
    XCTAssertTrue(enumValue.isValid())
    XCTAssertEqual(enumValue.name, "VALUE_1")
    XCTAssertEqual(enumValue.number, 1)
  }

  // Negative Test: Create invalid enum value descriptor
  func testInvalidEnumValueDescriptor() {
    let invalidEnumValue = ProtoEnumValueDescriptor(name: "", number: 1)
    XCTAssertFalse(invalidEnumValue.isValid())
  }

  // Positive Test: Enum value descriptor equality
  func testEnumValueDescriptorEquality() {
    let value1 = ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
    let value2 = ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
    XCTAssertEqual(value1, value2)
  }

  // Negative Test: Enum value descriptor inequality
  func testEnumValueDescriptorInequality() {
    let value1 = ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
    let value2 = ProtoEnumValueDescriptor(name: "VALUE_2", number: 2)
    XCTAssertNotEqual(value1, value2)
  }
}
