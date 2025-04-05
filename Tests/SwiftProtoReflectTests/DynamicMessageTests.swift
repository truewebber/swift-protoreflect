import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class DynamicMessageTests: XCTestCase {
  var messageDescriptor: ProtoMessageDescriptor!

  override func setUp() {
    super.setUp()
    // Create a test descriptor with some fields
    messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "intField", number: 1, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "stringField", number: 2, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "boolField", number: 3, type: .bool, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )
  }

  func testSetAndGetFields() {
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)

    // Test setting and getting int32
    XCTAssertTrue(message.set(fieldName: "intField", value: .intValue(42)))
    XCTAssertEqual(message.get(fieldName: "intField")?.getInt(), 42)

    // Test setting and getting string
    XCTAssertTrue(message.set(fieldName: "stringField", value: .stringValue("Hello")))
    XCTAssertEqual(message.get(fieldName: "stringField")?.getString(), "Hello")

    // Test setting and getting bool
    XCTAssertTrue(message.set(fieldName: "boolField", value: .boolValue(true)))
    XCTAssertEqual(message.get(fieldName: "boolField")?.getBool(), true)
  }

  func testInvalidFieldNumber() {
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)

    // Test setting invalid field name
    XCTAssertFalse(message.set(fieldName: "nonExistentField", value: .stringValue("Invalid")))
    XCTAssertNil(message.get(fieldName: "nonExistentField"))
  }

  func testTypeMismatch() {
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)

    // Test setting wrong type for int32 field
    XCTAssertFalse(message.set(fieldName: "intField", value: .stringValue("Wrong Type")))

    // Test setting wrong type for string field
    XCTAssertFalse(message.set(fieldName: "stringField", value: .intValue(42)))

    // Test setting wrong type for bool field
    XCTAssertFalse(message.set(fieldName: "boolField", value: .stringValue("Wrong Type")))
  }

  func testSerialization() throws {
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)

    // Set some test values
    message.set(fieldName: "intField", value: .intValue(42))
    message.set(fieldName: "stringField", value: .stringValue("Test"))
    message.set(fieldName: "boolField", value: .boolValue(true))

    // Serialize
    let data = try ProtoWireFormat.marshal(message: message)
    XCTAssertFalse(data.isEmpty)

    // Verify basic structure (we can add more detailed verification if needed)
    XCTAssertGreaterThan(data.count, 3)  // Should have at least a few bytes
  }

  func testSerializationAndDeserialization() throws {
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)

    // Set test values
    message.set(fieldName: "intField", value: .intValue(42))
    message.set(fieldName: "stringField", value: .stringValue("Hello World"))
    message.set(fieldName: "boolField", value: .boolValue(true))

    // Serialize
    let data = try ProtoWireFormat.marshal(message: message)
    XCTAssertFalse(data.isEmpty)

    // Deserialize
    let decodedMessage =
      try ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor) as? ProtoDynamicMessage
    XCTAssertNotNil(decodedMessage)

    // Verify values
    XCTAssertEqual(decodedMessage?.get(fieldName: "intField")?.getInt(), 42)
    XCTAssertEqual(decodedMessage?.get(fieldName: "stringField")?.getString(), "Hello World")
    XCTAssertEqual(decodedMessage?.get(fieldName: "boolField")?.getBool(), true)
  }

  func testMalformedProtobuf() {
    let malformedData = Data([0xFF, 0xFF])  // Invalid varint
    XCTAssertThrowsError(try ProtoWireFormat.unmarshal(data: malformedData, messageDescriptor: messageDescriptor)) {
      error in
      // Verify the error is the expected type
      XCTAssertTrue(error is ProtoWireFormatError)
    }
  }

  func testUnknownFields() throws {
    // Create data with an unknown field (field number 999)
    var data = Data()
    data.append(contentsOf: [0xF8, 0x7B])  // Field number 999, wire type 0 (varint)
    data.append(contentsOf: [0x2A])  // Value 42

    // Add a known field
    data.append(contentsOf: [0x08])  // Field number 1, wire type 0 (varint)
    data.append(contentsOf: [0x2A])  // Value 42

    // Deserialize should succeed, ignoring unknown field
    let message =
      try ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor) as? ProtoDynamicMessage
    XCTAssertNotNil(message)
    XCTAssertEqual(message?.get(fieldName: "intField")?.getInt(), 42)

    // Check unknown fields are preserved
    let unknownFields = message?.getUnknownFields()
    XCTAssertEqual(unknownFields?[999]?.first?.count, 3)  // 3 bytes: tag(2) + value(1)
  }

  func testPartialDeserialization() throws {
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(fieldName: "intField", value: .intValue(42))
    message.set(fieldName: "stringField", value: .stringValue("Test"))
    message.set(fieldName: "boolField", value: .boolValue(true))

    do {
      let data = try ProtoWireFormat.marshal(message: message)

      // Create a new message with just one field
      let partialMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
      partialMessage.set(fieldName: "intField", value: .intValue(100))

      // Deserialize the full message data
      let fullMessage =
        try ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor) as? ProtoDynamicMessage
      XCTAssertNotNil(fullMessage)

      // Copy values from full message to partial message
      if let field = messageDescriptor.field(named: "intField"),
        let value = fullMessage?.get(field: field)
      {
        partialMessage.set(field: field, value: value)
      }

      if let field = messageDescriptor.field(named: "stringField"),
        let value = fullMessage?.get(field: field)
      {
        partialMessage.set(field: field, value: value)
      }

      if let field = messageDescriptor.field(named: "boolField"),
        let value = fullMessage?.get(field: field)
      {
        partialMessage.set(field: field, value: value)
      }

      // Verify the values were copied correctly
      XCTAssertEqual(partialMessage.get(fieldName: "intField")?.getInt(), 42)
      XCTAssertEqual(partialMessage.get(fieldName: "stringField")?.getString(), "Test")
      XCTAssertEqual(partialMessage.get(fieldName: "boolField")?.getBool(), true)
    }
    catch {
      XCTFail("Failed to marshal or unmarshal message: \(error)")
    }
  }
}
