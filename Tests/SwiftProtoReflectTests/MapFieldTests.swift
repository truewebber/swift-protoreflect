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
      fullName: "MapEntry",
      fields: [keyFieldDescriptor, valueFieldDescriptor],
      enums: [],
      nestedMessages: []
    )

    // Create a field descriptor for a map field
    let mapFieldDescriptor = ProtoFieldDescriptor(
      name: "test_map",
      number: 1,  // Use a simple field number
      type: .message,
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

    // Create a map with entries
    var mapEntries: [String: ProtoValue] = [:]
    mapEntries["one"] = .intValue(1)
    mapEntries["two"] = .intValue(2)
    mapEntries["three"] = .intValue(3)

    // Set the map field
    let setResult = message.set(field: mapFieldDescriptor, value: .mapValue(mapEntries))
    XCTAssertTrue(setResult, "Setting map field should succeed")

    // Verify the map field was set correctly
    let mapFieldValue = message.get(field: mapFieldDescriptor)
    XCTAssertNotNil(mapFieldValue, "Map field value should not be nil")

    if case .mapValue(let entries)? = mapFieldValue {
      XCTAssertEqual(entries.count, 3, "Map should have 3 entries")
      XCTAssertEqual(entries["one"]?.getInt(), 1, "Value for key 'one' should be 1")
      XCTAssertEqual(entries["two"]?.getInt(), 2, "Value for key 'two' should be 2")
      XCTAssertEqual(entries["three"]?.getInt(), 3, "Value for key 'three' should be 3")
    }
    else {
      XCTFail("Field value should be a map value")
    }

    // Marshal the message
    guard let serializedData = ProtoWireFormat.marshal(message: message) else {
      XCTFail("Failed to marshal message")
      return
    }

    // Unmarshal the message
    let unmarshalledMessage =
      ProtoWireFormat.unmarshal(data: serializedData, messageDescriptor: messageDescriptor) as? ProtoDynamicMessage
    XCTAssertNotNil(unmarshalledMessage, "Message should be deserialized")

    // Verify the map field values in the unmarshalled message
    let mapValue = unmarshalledMessage?.get(field: mapFieldDescriptor)
    XCTAssertNotNil(mapValue, "Map field should be present in unmarshalled message")

    if case .mapValue(let entries)? = mapValue {
      XCTAssertEqual(entries.count, 3, "Map should have 3 entries")
      XCTAssertEqual(entries["one"]?.getInt(), 1, "Value for key 'one' should be 1")
      XCTAssertEqual(entries["two"]?.getInt(), 2, "Value for key 'two' should be 2")
      XCTAssertEqual(entries["three"]?.getInt(), 3, "Value for key 'three' should be 3")
    }
    else {
      XCTFail("Field value should be a map value")
    }
  }
}
