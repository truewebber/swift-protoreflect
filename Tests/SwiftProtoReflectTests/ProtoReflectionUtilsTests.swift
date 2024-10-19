import XCTest
@testable import SwiftProtoReflect

class ProtoReflectionUtilsTests: XCTestCase {

    // Positive Test: Validate valid field descriptor
    func testValidateValidFieldDescriptor() {
        let fieldDescriptor = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
        XCTAssertTrue(ProtoReflectionUtils.validateFieldDescriptor(fieldDescriptor))
    }

    // Negative Test: Validate invalid field descriptor
    func testValidateInvalidFieldDescriptor() {
        let invalidFieldDescriptor = ProtoFieldDescriptor(name: "", number: -1, type: .int32, isRepeated: false, isMap: false)
        XCTAssertFalse(ProtoReflectionUtils.validateFieldDescriptor(invalidFieldDescriptor))
    }

    // Positive Test: Describe valid message
    func testDescribeValidMessage() {
        let descriptor = ProtoMessageDescriptor(fullName: "TestMessage", fields: [], enums: [], nestedMessages: [])
        let message = ProtoDynamicMessage(descriptor: descriptor)
        let description = ProtoReflectionUtils.describeMessage(message)
        XCTAssertTrue(description.contains("TestMessage"))
    }
}
