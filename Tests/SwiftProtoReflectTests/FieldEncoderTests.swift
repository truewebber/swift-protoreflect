import XCTest
@testable import SwiftProtoReflect

class FieldEncoderTests: XCTestCase {

    // Positive Test: Encode int field
    func testEncodeIntField() {
        let fieldDescriptor = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
        let value = ProtoValue.intValue(123)
        let encodedData = FieldEncoder.encode(fieldDescriptor: fieldDescriptor, value: value)
        XCTAssertNotNil(encodedData)
    }

    // Negative Test: Encode unsupported type
    func testEncodeUnsupportedType() {
        let fieldDescriptor = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
        let value = ProtoValue.messageValue(ProtoDynamicMessage(descriptor: createTestMessageDescriptor()))
        let encodedData = FieldEncoder.encode(fieldDescriptor: fieldDescriptor, value: value)
        XCTAssertTrue(encodedData.isEmpty)
    }

    private func createTestMessageDescriptor() -> ProtoMessageDescriptor {
        return ProtoMessageDescriptor(fullName: "TestMessage", fields: [], enums: [], nestedMessages: [])
    }
}
