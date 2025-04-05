import XCTest

@testable import SwiftProtoReflect

class MapFieldTests: XCTestCase {

  func testMapFieldEncoding() {
    // Create field descriptors for the map entry
    let keyFieldDescriptor = ProtoFieldDescriptor(
      name: "key",
      number: 1,
      type: .string,
      isRepeated: false,
      isMap: false
    )

    let valueFieldDescriptor = ProtoFieldDescriptor(
      name: "value",
      number: 2,
      type: .int32,
      isRepeated: false,
      isMap: false
    )

    // Create a message descriptor for the map entry
    let entryDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage.TestMapEntry",
      fields: [keyFieldDescriptor, valueFieldDescriptor],
      enums: [],
      nestedMessages: []
    )

    // Create a field descriptor for a map field
    let mapFieldDescriptor = ProtoFieldDescriptor(
      name: "test_map",
      number: 1,  // Use a simple field number
      type: .message(entryDescriptor),
      isRepeated: true,  // Map fields are encoded as repeated messages
      isMap: true,
      messageType: entryDescriptor
    )

    // Create a message descriptor with the map field
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [mapFieldDescriptor],
      enums: [],
      nestedMessages: [entryDescriptor]
    )

    // Create a dynamic message with the map field
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)

    // Create a simple map with just one entry to simplify debugging
    var mapEntries: [String: ProtoValue] = [:]
    mapEntries["one"] = ProtoValue.intValue(1)

    // Set the map field
    let setResult = message.set(field: mapFieldDescriptor, value: ProtoValue.mapValue(mapEntries))
    XCTAssertTrue(setResult, "Setting map field should succeed")

    // Verify the map field was set correctly
    let mapFieldValue = message.get(field: mapFieldDescriptor)
    XCTAssertNotNil(mapFieldValue, "Map field value should not be nil")

    if case let ProtoValue.mapValue(entries)? = mapFieldValue {
      XCTAssertEqual(entries.count, 1, "Map should have 1 entry")
      XCTAssertEqual(entries["one"]?.getInt(), 1, "Value for key 'one' should be 1")
    }
    else {
      XCTFail("Field value should be a map value")
    }

    // Marshal the message using the safe helper
    guard let serializedData = safeMarshal(message: message) else {
      return
    }

    // Unmarshal using the safe helper
    let unmarshalledMessage =
      safeUnmarshal(data: serializedData, messageDescriptor: messageDescriptor) as? ProtoDynamicMessage
    XCTAssertNotNil(unmarshalledMessage, "Message should be deserialized")

    // Verify the map field values in the unmarshalled message
    let mapValue = unmarshalledMessage?.get(field: mapFieldDescriptor)
    XCTAssertNotNil(mapValue, "Map field should be present in unmarshalled message")

    if case let ProtoValue.mapValue(entries)? = mapValue {
      XCTAssertEqual(entries.count, 1, "Map should have 1 entry")
      XCTAssertEqual(entries["one"]?.getInt(), 1, "Value for key 'one' should be 1")
    }
    else {
      XCTFail("Field value should be a map value")
    }
  }
}
