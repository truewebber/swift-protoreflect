import XCTest
@testable import SwiftProtoReflect

class ProtoDynamicMessageTests: XCTestCase {

    var descriptor: ProtoMessageDescriptor!
    var message: ProtoDynamicMessage!

    override func setUp() {
        super.setUp()
        descriptor = ProtoMessageDescriptor(
            fullName: "DynamicMessage",
            fields: [
                ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
            ],
            enums: [],
            nestedMessages: []
        )
        message = ProtoDynamicMessage(descriptor: descriptor)
    }

    // Positive Test: Set and retrieve field values dynamically
    func testSetAndGetFieldValues() {
        message.set(field: descriptor.fields[0], value: .intValue(100))
        let value = message.get(field: descriptor.fields[0])
        XCTAssertEqual(value?.getInt(), 100)
    }

    // Negative Test: Get non-existent field
    func testGetNonExistentField() {
        let nonExistentField = ProtoFieldDescriptor(name: "nonExistent", number: 99, type: .int32, isRepeated: false, isMap: false)
        let value = message.get(field: nonExistentField)
        XCTAssertNil(value)
    }

    // Negative Test: Set incorrect type
    func testSetIncorrectFieldType() {
        message.set(field: descriptor.fields[0], value: .stringValue("invalid"))
        let value = message.get(field: descriptor.fields[0])
        XCTAssertNil(value?.getInt())
    }

    // Positive Test: Message validity
    func testValidDynamicMessage() {
        XCTAssertTrue(message.isValid())
    }
}
