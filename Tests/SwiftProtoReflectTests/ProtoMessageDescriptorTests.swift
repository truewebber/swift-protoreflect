import XCTest
@testable import SwiftProtoReflect

class ProtoMessageDescriptorTests: XCTestCase {

    // Positive Test: Create a valid message descriptor
    func testValidMessageDescriptor() {
        let descriptor = ProtoMessageDescriptor(
            fullName: "TestMessage",
            fields: [
                ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
            ],
            enums: [],
            nestedMessages: []
        )
        XCTAssertTrue(descriptor.isValid())
        XCTAssertNotNil(descriptor.field(named: "field1"))
    }

    // Negative Test: Create an invalid message descriptor
    func testInvalidMessageDescriptor() {
        let descriptor = ProtoMessageDescriptor(fullName: "", fields: [], enums: [], nestedMessages: [])
        XCTAssertFalse(descriptor.isValid())
    }

    // Negative Test: Retrieve non-existent field by name
    func testGetNonExistentFieldByName() {
        let descriptor = ProtoMessageDescriptor(
            fullName: "TestMessage",
            fields: [
                ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
            ],
            enums: [],
            nestedMessages: []
        )
        let field = descriptor.field(named: "nonExistentField")
        XCTAssertNil(field)
    }
}
