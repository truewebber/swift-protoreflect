import XCTest
@testable import SwiftProtoReflect

class ProtoEnumDescriptorTests: XCTestCase {

    // Positive Test: Retrieve enum value by name
    func testGetEnumValueByName() {
        let value = ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
        let descriptor = ProtoEnumDescriptor(name: "TestEnum", values: [value])
        let retrievedValue = descriptor.value(named: "VALUE_1")
        XCTAssertEqual(retrievedValue?.number, 1)
    }

    // Negative Test: Retrieve non-existent enum value by name
    func testGetNonExistentEnumValue() {
        let descriptor = ProtoEnumDescriptor(name: "TestEnum", values: [])
        let value = descriptor.value(named: "NON_EXISTENT")
        XCTAssertNil(value)
    }

    // Positive Test: Enum descriptor validity
    func testValidEnumDescriptor() {
        let value = ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
        let descriptor = ProtoEnumDescriptor(name: "TestEnum", values: [value])
        XCTAssertTrue(descriptor.isValid())
    }

    // Negative Test: Invalid enum descriptor
    func testInvalidEnumDescriptor() {
        let descriptor = ProtoEnumDescriptor(name: "", values: [])
        XCTAssertFalse(descriptor.isValid())
    }
}
