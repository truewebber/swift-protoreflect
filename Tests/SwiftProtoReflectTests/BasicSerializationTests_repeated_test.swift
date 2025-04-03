import XCTest
@testable import SwiftProtoReflect

class BasicSerializationTests_repeated: XCTestCase {
    func testSimpleRepeatedString() {
        // Create a message descriptor with a repeated string field
        let messageDescriptor = ProtoMessageDescriptor(
            fullName: "TestMessage",
            fields: [
                ProtoFieldDescriptor(name: "repeated_string", number: 1, type: .string, isRepeated: true, isMap: false)
            ],
            enums: [],
            nestedMessages: []
        )
        
        // Create a message with a few repeated values
        let message = ProtoDynamicMessage(descriptor: messageDescriptor)
        message.set(fieldName: "repeated_string", value: .repeatedValue([
            .stringValue("test1"),
            .stringValue("test2"),
            .stringValue("test3")
        ]))
        
        // Serialize
        guard let data = ProtoWireFormat.marshal(message: message) else {
            XCTFail("Failed to marshal message")
            return
        }
        
        XCTAssertFalse(data.isEmpty, "Serialized data should not be empty")
        
        // Deserialize
        guard let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor) as? ProtoDynamicMessage else {
            XCTFail("Failed to unmarshal message")
            return
        }
        
        // Verify values
        guard let repeatedValues = deserializedMessage.get(fieldName: "repeated_string")?.getRepeated() else {
            XCTFail("Failed to get repeated values")
            return
        }
        
        XCTAssertEqual(repeatedValues.count, 3, "Should have 3 values")
        XCTAssertEqual(repeatedValues[0].getString(), "test1")
        XCTAssertEqual(repeatedValues[1].getString(), "test2")
        XCTAssertEqual(repeatedValues[2].getString(), "test3")
    }
    
    func testRepeatedInt32() {
        // Create a message descriptor with a repeated int32 field
        let messageDescriptor = ProtoMessageDescriptor(
            fullName: "TestMessage",
            fields: [
                ProtoFieldDescriptor(name: "repeated_int32", number: 1, type: .int32, isRepeated: true, isMap: false)
            ],
            enums: [],
            nestedMessages: []
        )
        
        // Create a message with repeated int32 values
        let message = ProtoDynamicMessage(descriptor: messageDescriptor)
        message.set(fieldName: "repeated_int32", value: .repeatedValue([
            .intValue(1),
            .intValue(2),
            .intValue(3)
        ]))
        
        // Serialize
        guard let data = ProtoWireFormat.marshal(message: message) else {
            XCTFail("Failed to marshal message")
            return
        }
        
        XCTAssertFalse(data.isEmpty, "Serialized data should not be empty")
        
        // Deserialize
        guard let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor) as? ProtoDynamicMessage else {
            XCTFail("Failed to unmarshal message")
            return
        }
        
        // Verify values
        guard let repeatedValues = deserializedMessage.get(fieldName: "repeated_int32")?.getRepeated() else {
            XCTFail("Failed to get repeated values")
            return
        }
        
        XCTAssertEqual(repeatedValues.count, 3, "Should have 3 values")
        XCTAssertEqual(repeatedValues[0].getInt(), 1)
        XCTAssertEqual(repeatedValues[1].getInt(), 2)
        XCTAssertEqual(repeatedValues[2].getInt(), 3)
    }
    
    func testEmptyRepeatedField() {
        // Create a message descriptor with a repeated field
        let messageDescriptor = ProtoMessageDescriptor(
            fullName: "TestMessage",
            fields: [
                ProtoFieldDescriptor(name: "repeated_string", number: 1, type: .string, isRepeated: true, isMap: false)
            ],
            enums: [],
            nestedMessages: []
        )
        
        // Create a message with empty repeated field
        let message = ProtoDynamicMessage(descriptor: messageDescriptor)
        message.set(fieldName: "repeated_string", value: .repeatedValue([]))
        
        // Serialize
        guard let data = ProtoWireFormat.marshal(message: message) else {
            XCTFail("Failed to marshal message")
            return
        }
        
        // Empty repeated field should still produce valid serialized data
        XCTAssertFalse(data.isEmpty, "Serialized data should not be empty even with empty repeated field")
        
        // Deserialize
        guard let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor) as? ProtoDynamicMessage else {
            XCTFail("Failed to unmarshal message")
            return
        }
        
        // Verify empty values array
        guard let repeatedValues = deserializedMessage.get(fieldName: "repeated_string")?.getRepeated() else {
            XCTFail("Failed to get repeated values")
            return
        }
        
        XCTAssertEqual(repeatedValues.count, 0, "Should have no values")
    }
}
