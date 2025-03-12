import XCTest

@testable import SwiftProtoReflect

class BasicSerializationTests: XCTestCase {

  func testBasicFieldTypes() {
    // Create a message descriptor with just a few basic field types
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

    // Create a message with values for each field
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(fieldName: "int32_field", value: .intValue(42))
    message.set(fieldName: "string_field", value: .stringValue("Hello, world!"))
    message.set(fieldName: "bool_field", value: .boolValue(true))

    // Serialize the message
    guard let data = ProtoWireFormat.marshal(message: message) else {
      XCTFail("Failed to marshal message")
      return
    }

    // Deserialize the message
    guard
      let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal message")
      return
    }

    // Verify the field values were preserved
    XCTAssertEqual(deserializedMessage.get(fieldName: "int32_field")?.getInt(), 42)
    XCTAssertEqual(deserializedMessage.get(fieldName: "string_field")?.getString(), "Hello, world!")
    XCTAssertEqual(deserializedMessage.get(fieldName: "bool_field")?.getBool(), true)
  }

  func testRepeatedFieldTypes() {
    // Create a message descriptor with a repeated field
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "repeated_int32", number: 1, type: .int32, isRepeated: true, isMap: false)
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a message with a repeated field
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(
      fieldName: "repeated_int32",
      value: .repeatedValue([
        .intValue(1),
        .intValue(2),
        .intValue(3),
      ])
    )

    // Serialize the message
    guard let data = ProtoWireFormat.marshal(message: message) else {
      XCTFail("Failed to marshal message")
      return
    }

    // Deserialize the message
    guard
      let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal message")
      return
    }

    // Verify the repeated field values were preserved
    guard let repeatedValues = deserializedMessage.get(fieldName: "repeated_int32")?.getRepeated() else {
      XCTFail("Failed to get repeated field values")
      return
    }

    XCTAssertEqual(repeatedValues.count, 3)
    XCTAssertEqual(repeatedValues[0].getInt(), 1)
    XCTAssertEqual(repeatedValues[1].getInt(), 2)
    XCTAssertEqual(repeatedValues[2].getInt(), 3)
  }

  func testSimpleMapField() {
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
      number: 1,
      type: .message,
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
    mapEntries["one"] = .intValue(1)

    // Set the map field
    let setResult = message.set(field: mapFieldDescriptor, value: .mapValue(mapEntries))
    XCTAssertTrue(setResult, "Setting map field should succeed")

    // Verify the map field was set correctly
    let mapFieldValue = message.get(field: mapFieldDescriptor)
    XCTAssertNotNil(mapFieldValue, "Map field value should not be nil")

    if case .mapValue(let entries)? = mapFieldValue {
      XCTAssertEqual(entries.count, 1, "Map should have 1 entry")
      XCTAssertEqual(entries["one"]?.getInt(), 1, "Value for key 'one' should be 1")
    }
    else {
      XCTFail("Field value should be a map value")
    }
  }

  func testMapFieldSerialization() {
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
      number: 1,
      type: .message,
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

    // Create a map with entries
    var mapEntries: [String: ProtoValue] = [:]
    mapEntries["one"] = .intValue(1)
    mapEntries["two"] = .intValue(2)

    // Set the map field
    let setResult = message.set(field: mapFieldDescriptor, value: .mapValue(mapEntries))
    XCTAssertTrue(setResult, "Setting map field should succeed")

    // Serialize the message
    guard let data = ProtoWireFormat.marshal(message: message) else {
      XCTFail("Failed to marshal message")
      return
    }

    // Deserialize the message
    guard
      let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal message")
      return
    }

    // Verify the map field values in the unmarshalled message
    guard let mapValue = deserializedMessage.get(field: mapFieldDescriptor) else {
      XCTFail("Map field should be present in unmarshalled message")
      return
    }

    if case .mapValue(let entries) = mapValue {
      XCTAssertEqual(entries.count, 2, "Map should have 2 entries")
      XCTAssertEqual(entries["one"]?.getInt(), 1, "Value for key 'one' should be 1")
      XCTAssertEqual(entries["two"]?.getInt(), 2, "Value for key 'two' should be 2")
    }
    else {
      XCTFail("Field value should be a map value")
    }
  }

  func testVerySimpleMapField() {
    // Create a simpler test for map fields

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
      type: .string,  // Using string instead of int32
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
      type: .message,
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

    // Serialize the message
    guard let data = ProtoWireFormat.marshal(message: message) else {
      XCTFail("Failed to marshal message")
      return
    }

    // Deserialize the message
    guard
      let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal message")
      return
    }

    // Verify the map field values in the unmarshalled message
    guard let mapValue = deserializedMessage.get(field: mapFieldDescriptor) else {
      XCTFail("Map field should be present in unmarshalled message")
      return
    }

    if case .mapValue(let entries) = mapValue {
      XCTAssertEqual(entries.count, 1, "Map should have 1 entry")
      XCTAssertEqual(entries["key1"]?.getString(), "value1", "Value for key 'key1' should be 'value1'")
    }
    else {
      XCTFail("Field value should be a map value")
    }
  }
}
