import XCTest

@testable import SwiftProtoReflect

class SimpleMapFieldTests: XCTestCase {

  func testSimpleMapFieldWithoutSerialization() {
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
      type: .string,
      isRepeated: false,
      isMap: false
    )

    // Create a message descriptor for the map entry
    let entryDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage.StringMapEntry",
      fields: [keyFieldDescriptor, valueFieldDescriptor],
      enums: [],
      nestedMessages: []
    )

    // Create a field descriptor for a map field
    let mapFieldDescriptor = ProtoFieldDescriptor(
      name: "string_map",
      number: 1,
      type: .message(entryDescriptor),
      isRepeated: true,
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

    // Create a simple map with just one entry
    var mapEntries: [String: ProtoValue] = [:]
    mapEntries["key1"] = .stringValue("value1")

    // Set the map field
    let setResult = message.set(field: mapFieldDescriptor, value: .mapValue(mapEntries))
    XCTAssertTrue(setResult, "Setting map field should succeed")

    // Verify the map field was set correctly
    let mapFieldValue = message.get(field: mapFieldDescriptor)
    XCTAssertNotNil(mapFieldValue, "Map field value should not be nil")

    if case .mapValue(let entries)? = mapFieldValue {
      XCTAssertEqual(entries.count, 1, "Map should have 1 entry")
      XCTAssertEqual(entries["key1"]?.getString(), "value1", "Value for key 'key1' should be 'value1'")
    }
    else {
      XCTFail("Field value should be a map value")
    }
  }

  func testMapEntryMessageSerialization() {
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
      type: .string,
      isRepeated: false,
      isMap: false
    )

    // Create a message descriptor for the map entry
    let entryDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage.StringMapEntry",
      fields: [keyFieldDescriptor, valueFieldDescriptor],
      enums: [],
      nestedMessages: []
    )

    // Create a map entry message directly
    let entryMessage = ProtoDynamicMessage(descriptor: entryDescriptor)
    entryMessage.set(field: keyFieldDescriptor, value: .stringValue("key1"))
    entryMessage.set(field: valueFieldDescriptor, value: .stringValue("value1"))

    // Serialize just the entry message
    guard let data = ProtoWireFormat.marshal(message: entryMessage) else {
      XCTFail("Failed to marshal map entry message")
      return
    }

    // Deserialize the entry message
    guard
      let deserializedEntry = ProtoWireFormat.unmarshal(data: data, messageDescriptor: entryDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal map entry message")
      return
    }

    // Verify the entry fields were preserved
    XCTAssertEqual(deserializedEntry.get(field: keyFieldDescriptor)?.getString(), "key1")
    XCTAssertEqual(deserializedEntry.get(field: valueFieldDescriptor)?.getString(), "value1")
  }

  func testMapFieldAsRepeatedMessage() {
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
      type: .string,
      isRepeated: false,
      isMap: false
    )

    // Create a message descriptor for the map entry
    let entryDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage.StringMapEntry",
      fields: [keyFieldDescriptor, valueFieldDescriptor],
      enums: [],
      nestedMessages: []
    )

    // Create a field descriptor for a repeated message field (not marked as map)
    let repeatedMessageFieldDescriptor = ProtoFieldDescriptor(
      name: "entries",
      number: 1,
      type: .message(entryDescriptor),
      isRepeated: true,
      isMap: false,  // Not marked as map
      messageType: entryDescriptor
    )

    // Create a message descriptor with the repeated message field
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [repeatedMessageFieldDescriptor],
      enums: [],
      nestedMessages: [entryDescriptor]
    )

    // Create a dynamic message
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)

    // Create entry messages
    let entry1 = ProtoDynamicMessage(descriptor: entryDescriptor)
    entry1.set(field: keyFieldDescriptor, value: .stringValue("key1"))
    entry1.set(field: valueFieldDescriptor, value: .stringValue("value1"))

    let entry2 = ProtoDynamicMessage(descriptor: entryDescriptor)
    entry2.set(field: keyFieldDescriptor, value: .stringValue("key2"))
    entry2.set(field: valueFieldDescriptor, value: .stringValue("value2"))

    // Set as repeated message field
    message.set(
      field: repeatedMessageFieldDescriptor,
      value: ProtoValue.repeatedValue([
        ProtoValue.messageValue(entry1),
        ProtoValue.messageValue(entry2),
      ])
    )

    // Serialize the message
    guard let data = ProtoWireFormat.marshal(message: message) else {
      XCTFail("Failed to marshal message with repeated entries")
      return
    }

    // Deserialize the message
    guard
      let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal message with repeated entries")
      return
    }

    // Verify the repeated field was preserved
    guard let repeatedValue = deserializedMessage.get(field: repeatedMessageFieldDescriptor)?.getRepeated() else {
      XCTFail("Failed to get repeated field")
      return
    }

    XCTAssertEqual(repeatedValue.count, 2, "Should have 2 entries")

    // Check first entry
    if case .messageValue(let entryMsg1) = repeatedValue[0] {
      XCTAssertEqual(entryMsg1.get(field: keyFieldDescriptor)?.getString(), "key1")
      XCTAssertEqual(entryMsg1.get(field: valueFieldDescriptor)?.getString(), "value1")
    }
    else {
      XCTFail("First entry should be a message")
    }

    // Check second entry
    if case .messageValue(let entryMsg2) = repeatedValue[1] {
      XCTAssertEqual(entryMsg2.get(field: keyFieldDescriptor)?.getString(), "key2")
      XCTAssertEqual(entryMsg2.get(field: valueFieldDescriptor)?.getString(), "value2")
    }
    else {
      XCTFail("Second entry should be a message")
    }
  }

  func testManualMapFieldSerialization() {
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
      type: .string,
      isRepeated: false,
      isMap: false
    )

    // Create a message descriptor for the map entry
    let entryDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage.StringMapEntry",
      fields: [keyFieldDescriptor, valueFieldDescriptor],
      enums: [],
      nestedMessages: []
    )

    // Create a field descriptor for a map field
    let mapFieldDescriptor = ProtoFieldDescriptor(
      name: "string_map",
      number: 1,
      type: .message(entryDescriptor),
      isRepeated: true,
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

    // Create a dynamic message
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)

    // Create a map with entries
    var mapEntries: [String: ProtoValue] = [:]
    mapEntries["key1"] = .stringValue("value1")
    mapEntries["key2"] = .stringValue("value2")

    // Set the map field using mapValue
    message.set(field: mapFieldDescriptor, value: .mapValue(mapEntries))

    // Serialize the message
    guard let data = ProtoWireFormat.marshal(message: message) else {
      XCTFail("Failed to marshal message with map entries")
      return
    }

    // Deserialize the message
    guard
      let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal message with map entries")
      return
    }

    // The deserialized message should have a map field
    let mapValue = deserializedMessage.get(field: mapFieldDescriptor)
    XCTAssertNotNil(mapValue, "Map field should be present in unmarshalled message")

    if let mapValue = mapValue {
      // Check if it was deserialized as a map
      if case .mapValue(let entries) = mapValue {
        XCTAssertEqual(entries.count, 2, "Map should have 2 entries")
        XCTAssertEqual(entries["key1"]?.getString(), "value1", "Value for key 'key1' should be 'value1'")
        XCTAssertEqual(entries["key2"]?.getString(), "value2", "Value for key 'key2' should be 'value2'")
      }
      // Or as a repeated field (which is also valid)
      else if case .repeatedValue(let repeatedEntries) = mapValue {
        XCTAssertEqual(repeatedEntries.count, 2, "Should have 2 entries")

        // Extract keys and values from the repeated entries
        var extractedMap: [String: String] = [:]
        for entry in repeatedEntries {
          if case .messageValue(let entryMsg) = entry,
            let key = entryMsg.get(field: keyFieldDescriptor)?.getString(),
            let value = entryMsg.get(field: valueFieldDescriptor)?.getString()
          {
            extractedMap[key] = value
          }
        }

        XCTAssertEqual(extractedMap.count, 2, "Should have 2 key-value pairs")
        XCTAssertEqual(extractedMap["key1"], "value1", "Value for key 'key1' should be 'value1'")
        XCTAssertEqual(extractedMap["key2"], "value2", "Value for key 'key2' should be 'value2'")
      }
      else {
        XCTFail("Field value should be a map value or repeated value, but got \(mapValue)")
      }
    }
  }
}
