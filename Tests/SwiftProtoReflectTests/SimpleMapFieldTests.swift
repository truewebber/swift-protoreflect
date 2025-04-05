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
    do {
      let data = try ProtoWireFormat.marshal(message: entryMessage)

      // Deserialize the entry message
      do {
        guard
          let deserializedEntry = try ProtoWireFormat.unmarshal(data: data, messageDescriptor: entryDescriptor)
            as? ProtoDynamicMessage
        else {
          XCTFail("Failed to unmarshal map entry message")
          return
        }

        // Verify key and value were preserved
        XCTAssertEqual(deserializedEntry.get(fieldName: "key")?.getString(), "key1")
        XCTAssertEqual(deserializedEntry.get(fieldName: "value")?.getString(), "value1")
      }
      catch {
        XCTFail("Failed to unmarshal map entry: \(error)")
      }
    }
    catch {
      XCTFail("Failed to marshal map entry message: \(error)")
    }
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
    do {
      let data = try ProtoWireFormat.marshal(message: message)

      // Deserialize the message
      do {
        guard
          let deserializedMessage = try ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
            as? ProtoDynamicMessage
        else {
          XCTFail("Failed to unmarshal message with repeated entries")
          return
        }

        // Verify map field was preserved
        guard let mapField = deserializedMessage.get(field: repeatedMessageFieldDescriptor) else {
          XCTFail("Map field not found in deserialized message")
          return
        }

        guard case .repeatedValue(let repeatedValue) = mapField else {
          XCTFail("Field should be a repeated value")
          return
        }

        XCTAssertEqual(repeatedValue.count, 2)

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

        // Дополнительная проверка: если интерпретировать повторяющиеся сообщения как карту
        // В некоторых случаях Proto3 может обрабатывать повторяющиеся записи как map
        var extractedMap: [String: String] = [:]
        for element in repeatedValue {
          if case .messageValue(let entryMsg) = element,
            let key = entryMsg.get(field: keyFieldDescriptor)?.getString(),
            let value = entryMsg.get(field: valueFieldDescriptor)?.getString()
          {
            extractedMap[key] = value
          }
        }

        XCTAssertEqual(extractedMap.count, 2, "Should successfully extract 2 key-value pairs")
        XCTAssertEqual(extractedMap["key1"], "value1", "Value for key 'key1' should be 'value1'")
        XCTAssertEqual(extractedMap["key2"], "value2", "Value for key 'key2' should be 'value2'")
      }
      catch {
        XCTFail("Failed to unmarshal message: \(error)")
      }
    }
    catch {
      XCTFail("Failed to marshal message with repeated entries: \(error)")
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
    do {
      let data = try ProtoWireFormat.marshal(message: message)

      // Deserialize the message
      do {
        guard
          let deserializedMessage = try ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
            as? ProtoDynamicMessage
        else {
          XCTFail("Failed to unmarshal message with map entries")
          return
        }

        // Verify map field was preserved
        guard let mapField = deserializedMessage.get(field: mapFieldDescriptor) else {
          XCTFail("Map field not found in deserialized message")
          return
        }

        guard case .mapValue(let mapValues) = mapField else {
          XCTFail("Field should be a map value")
          return
        }

        XCTAssertEqual(mapValues.count, 2)
        XCTAssertEqual(mapValues["key1"]?.getString(), "value1")
        XCTAssertEqual(mapValues["key2"]?.getString(), "value2")
      }
      catch {
        XCTFail("Failed to unmarshal message: \(error)")
      }
    }
    catch {
      XCTFail("Failed to marshal message with map entries: \(error)")
    }
  }
}
