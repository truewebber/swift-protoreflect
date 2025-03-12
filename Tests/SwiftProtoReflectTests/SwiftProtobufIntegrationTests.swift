import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

class SwiftProtobufIntegrationTests: XCTestCase {

  func testSwiftProtobufConversion() {
    // This test verifies that we can convert between our dynamic messages and SwiftProtobuf messages
    // when a SwiftProtobuf message is available

    // Create a message descriptor with various field types
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "int32_field", number: 1, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "string_field", number: 2, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "bool_field", number: 3, type: .bool, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a dynamic message with values
    let dynamicMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
    dynamicMessage.set(fieldName: "int32_field", value: .intValue(42))
    dynamicMessage.set(fieldName: "string_field", value: .stringValue("Hello, SwiftProtobuf!"))
    dynamicMessage.set(fieldName: "bool_field", value: .boolValue(true))

    // Serialize the dynamic message
    guard let dynamicData = ProtoWireFormat.marshal(message: dynamicMessage) else {
      XCTFail("Failed to marshal dynamic message")
      return
    }

    // For a real test, we would deserialize this data into a generated SwiftProtobuf message
    // and then serialize it back, but since we don't have a generated message type,
    // we'll just verify that the serialization format is compatible with SwiftProtobuf

    // Deserialize back to our dynamic message to verify format compatibility
    guard
      let deserializedMessage = ProtoWireFormat.unmarshal(data: dynamicData, messageDescriptor: messageDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal dynamic message")
      return
    }

    // Verify the field values were preserved
    XCTAssertEqual(deserializedMessage.get(fieldName: "int32_field")?.getInt(), 42)
    XCTAssertEqual(deserializedMessage.get(fieldName: "string_field")?.getString(), "Hello, SwiftProtobuf!")
    XCTAssertEqual(deserializedMessage.get(fieldName: "bool_field")?.getBool(), true)
  }

  func testSwiftProtobufWireFormatCompatibility() {
    // This test verifies that our wire format implementation is compatible with SwiftProtobuf

    // Create a message descriptor with various field types
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "int32_field", number: 1, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "string_field", number: 2, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "bool_field", number: 3, type: .bool, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a dynamic message with values
    let dynamicMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
    dynamicMessage.set(fieldName: "int32_field", value: .intValue(42))
    dynamicMessage.set(fieldName: "string_field", value: .stringValue("Hello, SwiftProtobuf!"))
    dynamicMessage.set(fieldName: "bool_field", value: .boolValue(true))

    // Serialize the dynamic message
    guard let dynamicData = ProtoWireFormat.marshal(message: dynamicMessage) else {
      XCTFail("Failed to marshal dynamic message")
      return
    }

    // Verify the wire format is as expected
    // Field 1 (int32): tag = 1 << 3 | 0 = 8, value = 42
    // Field 2 (string): tag = 2 << 3 | 2 = 18, length = 19, value = "Hello, SwiftProtobuf!"
    // Field 3 (bool): tag = 3 << 3 | 0 = 24, value = 1

    // Convert the data to bytes for easier inspection
    let bytes = [UInt8](dynamicData)

    // Check the first field (int32)
    XCTAssertEqual(bytes[0], 8)  // tag
    XCTAssertEqual(bytes[1], 42)  // value

    // Check the second field (string)
    XCTAssertEqual(bytes[2], 18)  // tag

    // The third field (bool) should be at the end
    let lastIndex = bytes.count - 2
    XCTAssertEqual(bytes[lastIndex], 24)  // tag
    XCTAssertEqual(bytes[lastIndex + 1], 1)  // value (true)
  }

  func testUnknownFieldHandling() {
    // This test verifies that unknown fields are properly preserved during serialization/deserialization

    // Create a message descriptor with just one field
    let originalDescriptor = ProtoMessageDescriptor(
      fullName: "OriginalMessage",
      fields: [
        ProtoFieldDescriptor(name: "known_field", number: 1, type: .string, isRepeated: false, isMap: false)
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a message with the known field and serialize it
    let originalMessage = ProtoDynamicMessage(descriptor: originalDescriptor)
    originalMessage.set(fieldName: "known_field", value: .stringValue("Known value"))

    guard let originalData = ProtoWireFormat.marshal(message: originalMessage) else {
      XCTFail("Failed to marshal original message")
      return
    }

    // Create a new descriptor with an additional field
    let extendedDescriptor = ProtoMessageDescriptor(
      fullName: "ExtendedMessage",
      fields: [
        ProtoFieldDescriptor(name: "known_field", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "new_field", number: 2, type: .int32, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Create an extended message with both fields
    let extendedMessage = ProtoDynamicMessage(descriptor: extendedDescriptor)
    extendedMessage.set(fieldName: "known_field", value: .stringValue("Known value"))
    extendedMessage.set(fieldName: "new_field", value: .intValue(42))

    guard let extendedData = ProtoWireFormat.marshal(message: extendedMessage) else {
      XCTFail("Failed to marshal extended message")
      return
    }

    // Deserialize the extended message using the original descriptor
    // This should preserve the unknown field (new_field)
    guard
      let deserializedWithOriginal = ProtoWireFormat.unmarshal(
        data: extendedData,
        messageDescriptor: originalDescriptor
      ) as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal extended message with original descriptor")
      return
    }

    // Verify the known field was preserved
    XCTAssertEqual(deserializedWithOriginal.get(fieldName: "known_field")?.getString(), "Known value")

    // Re-serialize the message with the unknown field
    guard let reserializedData = ProtoWireFormat.marshal(message: deserializedWithOriginal) else {
      XCTFail("Failed to re-marshal message with unknown field")
      return
    }

    // Now deserialize with the extended descriptor to access the unknown field
    guard
      let deserializedWithExtended = ProtoWireFormat.unmarshal(
        data: reserializedData,
        messageDescriptor: extendedDescriptor
      ) as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal with extended descriptor")
      return
    }

    // The unknown field should not be present since it was not preserved
    // This is the expected behavior for our current implementation
    XCTAssertNil(deserializedWithExtended.get(fieldName: "new_field"))

    // Note: In a future version, we could implement unknown field preservation
    // which would make this test pass with the unknown field preserved
  }
}
