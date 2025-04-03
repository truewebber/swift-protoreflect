import XCTest
import SwiftProtobuf
@testable import SwiftProtoReflect

final class DynamicMessageTests: XCTestCase {
    var descriptor: Google_Protobuf_DescriptorProto!
    
    override func setUp() {
        super.setUp()
        // Create a test descriptor with some fields
        var builder = Google_Protobuf_DescriptorProto()
        builder.name = "TestMessage"
        
        // Add an int32 field
        var intField = Google_Protobuf_FieldDescriptorProto()
        intField.name = "intField"
        intField.number = 1
        intField.type = .int32
        builder.field.append(intField)
        
        // Add a string field
        var stringField = Google_Protobuf_FieldDescriptorProto()
        stringField.name = "stringField"
        stringField.number = 2
        stringField.type = .string
        builder.field.append(stringField)
        
        // Add a bool field
        var boolField = Google_Protobuf_FieldDescriptorProto()
        boolField.name = "boolField"
        boolField.number = 3
        boolField.type = .bool
        builder.field.append(boolField)
        
        descriptor = builder
    }
    
    func testSetAndGetFields() {
        let message = DynamicMessage(descriptor: descriptor)
        
        // Test setting and getting int32
        XCTAssertTrue(message.set(fieldNumber: 1, value: Int32(42)))
        XCTAssertEqual(message.get(fieldNumber: 1) as? Int32, 42)
        
        // Test setting and getting string
        XCTAssertTrue(message.set(fieldNumber: 2, value: "Hello"))
        XCTAssertEqual(message.get(fieldNumber: 2) as? String, "Hello")
        
        // Test setting and getting bool
        XCTAssertTrue(message.set(fieldNumber: 3, value: true))
        XCTAssertEqual(message.get(fieldNumber: 3) as? Bool, true)
    }
    
    func testInvalidFieldNumber() {
        let message = DynamicMessage(descriptor: descriptor)
        
        // Test setting invalid field number
        XCTAssertFalse(message.set(fieldNumber: 999, value: "Invalid"))
        XCTAssertNil(message.get(fieldNumber: 999))
    }
    
    func testTypeMismatch() {
        let message = DynamicMessage(descriptor: descriptor)
        
        // Test setting wrong type for int32 field
        XCTAssertFalse(message.set(fieldNumber: 1, value: "Wrong Type"))
        
        // Test setting wrong type for string field
        XCTAssertFalse(message.set(fieldNumber: 2, value: 42))
        
        // Test setting wrong type for bool field
        XCTAssertFalse(message.set(fieldNumber: 3, value: "Wrong Type"))
    }
    
    func testSerialization() throws {
        let message = DynamicMessage(descriptor: descriptor)
        
        // Set some test values
        message.set(fieldNumber: 1, value: Int32(42))
        message.set(fieldNumber: 2, value: "Test")
        message.set(fieldNumber: 3, value: true)
        
        // Serialize
        let data = try message.serializeToProtobuf()
        XCTAssertFalse(data.isEmpty)
        
        // Verify basic structure (we can add more detailed verification if needed)
        XCTAssertGreaterThan(data.count, 3) // Should have at least a few bytes
    }
    
    func testSerializationAndDeserialization() throws {
        let message = DynamicMessage(descriptor: descriptor)
        
        // Set test values
        message.set(fieldNumber: 1, value: Int32(42))
        message.set(fieldNumber: 2, value: "Hello World")
        message.set(fieldNumber: 3, value: true)
        
        // Serialize
        let data = try message.serializeToProtobuf()
        XCTAssertFalse(data.isEmpty)
        
        // Deserialize
        let decodedMessage = try DynamicMessage.fromProtobuf(data, descriptor: descriptor)
        
        // Verify values
        XCTAssertEqual(decodedMessage.get(fieldNumber: 1) as? Int32, 42)
        XCTAssertEqual(decodedMessage.get(fieldNumber: 2) as? String, "Hello World")
        XCTAssertEqual(decodedMessage.get(fieldNumber: 3) as? Bool, true)
    }
    
    func testMalformedProtobuf() {
        let malformedData = Data([0xFF, 0xFF]) // Invalid varint
        XCTAssertThrowsError(try DynamicMessage.fromProtobuf(malformedData, descriptor: descriptor)) { error in
            XCTAssertTrue(error is DynamicMessageError)
            XCTAssertEqual(error as? DynamicMessageError, .malformedProtobuf)
        }
    }
    
    func testUnknownFields() throws {
        // Create data with an unknown field (field number 999)
        var data = Data()
        data.append(contentsOf: [0xF8, 0x7B]) // Field number 999, wire type 0 (varint)
        data.append(contentsOf: [0x2A]) // Value 42
        
        // Add a known field
        data.append(contentsOf: [0x08]) // Field number 1, wire type 0 (varint)
        data.append(contentsOf: [0x2A]) // Value 42
        
        // Deserialize should succeed, ignoring unknown field
        let message = try DynamicMessage.fromProtobuf(data, descriptor: descriptor)
        XCTAssertEqual(message.get(fieldNumber: 1) as? Int32, 42)
        XCTAssertNil(message.get(fieldNumber: 999))
    }
    
    func testPartialDeserialization() throws {
        let message = DynamicMessage(descriptor: descriptor)
        message.set(fieldNumber: 1, value: Int32(42))
        message.set(fieldNumber: 2, value: "Test")
        message.set(fieldNumber: 3, value: true)
        
        let data = try message.serializeToProtobuf()
        
        // Create a new message with just one field
        let partialMessage = DynamicMessage(descriptor: descriptor)
        partialMessage.set(fieldNumber: 1, value: Int32(100))
        
        // Merge the full message data
        try partialMessage.mergeFromProtobuf(data)
        
        // Verify the merge updated the existing field and added new ones
        XCTAssertEqual(partialMessage.get(fieldNumber: 1) as? Int32, 42)
        XCTAssertEqual(partialMessage.get(fieldNumber: 2) as? String, "Test")
        XCTAssertEqual(partialMessage.get(fieldNumber: 3) as? Bool, true)
    }
} 