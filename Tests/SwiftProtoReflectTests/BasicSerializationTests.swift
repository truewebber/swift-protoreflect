import SwiftProtobuf
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

  func testAllPrimitiveFieldTypes() {
    // Create a message descriptor with all primitive field types
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "AllTypesMessage",
      fields: [
        ProtoFieldDescriptor(name: "int32_field", number: 1, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "int64_field", number: 2, type: .int64, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "uint32_field", number: 3, type: .uint32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "uint64_field", number: 4, type: .uint64, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "sint32_field", number: 5, type: .sint32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "sint64_field", number: 6, type: .sint64, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "fixed32_field", number: 7, type: .fixed32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "fixed64_field", number: 8, type: .fixed64, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "sfixed32_field", number: 9, type: .sfixed32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "sfixed64_field", number: 10, type: .sfixed64, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "float_field", number: 11, type: .float, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "double_field", number: 12, type: .double, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "bool_field", number: 13, type: .bool, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "string_field", number: 14, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "bytes_field", number: 15, type: .bytes, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a message with values for each field
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(fieldName: "int32_field", value: .intValue(42))
    message.set(fieldName: "int64_field", value: .intValue(9_223_372_036_854_775_807))  // Max Int64
    message.set(fieldName: "uint32_field", value: .uintValue(4_294_967_295))  // Max UInt32
    message.set(fieldName: "uint64_field", value: .uintValue(18_446_744_073_709_551_615))  // Max UInt64
    message.set(fieldName: "sint32_field", value: .intValue(-42))  // Use a smaller negative value
    message.set(fieldName: "sint64_field", value: .intValue(-42))  // Use a smaller negative value
    message.set(fieldName: "fixed32_field", value: .uintValue(42))
    message.set(fieldName: "fixed64_field", value: .uintValue(42))
    message.set(fieldName: "sfixed32_field", value: .intValue(-42))
    message.set(fieldName: "sfixed64_field", value: .intValue(-42))
    message.set(fieldName: "float_field", value: .floatValue(3.14159))
    message.set(fieldName: "double_field", value: .doubleValue(2.71828))
    message.set(fieldName: "bool_field", value: .boolValue(true))
    message.set(fieldName: "string_field", value: .stringValue("Hello, Protocol Buffers!"))
    message.set(fieldName: "bytes_field", value: .bytesValue(Data([0x00, 0x01, 0x02, 0x03, 0xFF])))

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
    XCTAssertEqual(deserializedMessage.get(fieldName: "int64_field")?.getInt(), 9_223_372_036_854_775_807)
    XCTAssertEqual(deserializedMessage.get(fieldName: "uint32_field")?.getUInt(), 4_294_967_295)
    XCTAssertEqual(deserializedMessage.get(fieldName: "uint64_field")?.getUInt(), 18_446_744_073_709_551_615)
    XCTAssertEqual(deserializedMessage.get(fieldName: "sint32_field")?.getInt(), -42)
    XCTAssertEqual(deserializedMessage.get(fieldName: "sint64_field")?.getInt(), -42)
    XCTAssertEqual(deserializedMessage.get(fieldName: "fixed32_field")?.getUInt(), 42)
    XCTAssertEqual(deserializedMessage.get(fieldName: "fixed64_field")?.getUInt(), 42)
    XCTAssertEqual(deserializedMessage.get(fieldName: "sfixed32_field")?.getInt(), -42)
    XCTAssertEqual(deserializedMessage.get(fieldName: "sfixed64_field")?.getInt(), -42)

    if let floatValue = deserializedMessage.get(fieldName: "float_field")?.getFloat() {
      XCTAssertEqual(floatValue, 3.14159, accuracy: 0.00001)
    }
    else {
      XCTFail("Float value should not be nil")
    }

    if let doubleValue = deserializedMessage.get(fieldName: "double_field")?.getDouble() {
      XCTAssertEqual(doubleValue, 2.71828, accuracy: 0.00001)
    }
    else {
      XCTFail("Double value should not be nil")
    }

    XCTAssertEqual(deserializedMessage.get(fieldName: "bool_field")?.getBool(), true)
    XCTAssertEqual(deserializedMessage.get(fieldName: "string_field")?.getString(), "Hello, Protocol Buffers!")
    XCTAssertEqual(deserializedMessage.get(fieldName: "bytes_field")?.getBytes(), Data([0x00, 0x01, 0x02, 0x03, 0xFF]))
  }

  func testEdgeCases() {
    // Create a message descriptor with fields for testing edge cases
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "EdgeCasesMessage",
      fields: [
        ProtoFieldDescriptor(name: "empty_string", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "empty_bytes", number: 2, type: .bytes, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "zero_int", number: 3, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "zero_float", number: 4, type: .float, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "false_bool", number: 5, type: .bool, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "large_string", number: 6, type: .string, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a message with edge case values
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(fieldName: "empty_string", value: .stringValue(""))
    message.set(fieldName: "empty_bytes", value: .bytesValue(Data()))
    message.set(fieldName: "zero_int", value: .intValue(0))
    message.set(fieldName: "zero_float", value: .floatValue(0.0))
    message.set(fieldName: "false_bool", value: .boolValue(false))

    // Create a large string (10KB)
    let largeString = String(repeating: "a", count: 10240)
    message.set(fieldName: "large_string", value: .stringValue(largeString))

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
    XCTAssertEqual(deserializedMessage.get(fieldName: "empty_string")?.getString(), "")
    XCTAssertEqual(deserializedMessage.get(fieldName: "empty_bytes")?.getBytes(), Data())
    XCTAssertEqual(deserializedMessage.get(fieldName: "zero_int")?.getInt(), 0)
    XCTAssertEqual(deserializedMessage.get(fieldName: "zero_float")?.getFloat(), 0.0)
    XCTAssertEqual(deserializedMessage.get(fieldName: "false_bool")?.getBool(), false)
    XCTAssertEqual(deserializedMessage.get(fieldName: "large_string")?.getString(), largeString)
  }

  func testFieldValidation() {
    // Create a message descriptor with various field types
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "ValidationTestMessage",
      fields: [
        ProtoFieldDescriptor(name: "int_field", number: 1, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "string_field", number: 2, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "float_field", number: 3, type: .float, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a message with valid values
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(fieldName: "int_field", value: .intValue(42))
    message.set(fieldName: "string_field", value: .stringValue("Hello"))
    message.set(fieldName: "float_field", value: .floatValue(3.14))

    // Serialization should succeed with valid values
    let validData = ProtoWireFormat.marshal(message: message)
    XCTAssertNotNil(validData, "Serialization should succeed with valid field values")

    // Create a new message for testing invalid values
    let invalidMessage1 = ProtoDynamicMessage(descriptor: messageDescriptor)

    // Use direct field access to bypass validation
    if let field = messageDescriptor.field(named: "int_field") {
      invalidMessage1.set(field: field, value: .stringValue("not an int"))
    }
    invalidMessage1.set(fieldName: "string_field", value: .stringValue("Hello"))
    invalidMessage1.set(fieldName: "float_field", value: .floatValue(3.14))

    // Serialization should fail with invalid values
    let invalidData1 = ProtoWireFormat.marshal(message: invalidMessage1)
    XCTAssertNil(invalidData1, "Serialization should fail with invalid field values")

    // Create another message for testing different invalid values
    let invalidMessage2 = ProtoDynamicMessage(descriptor: messageDescriptor)
    invalidMessage2.set(fieldName: "int_field", value: .intValue(42))
    invalidMessage2.set(fieldName: "string_field", value: .stringValue("Hello"))

    // Use direct field access to bypass validation
    if let field = messageDescriptor.field(named: "float_field") {
      invalidMessage2.set(field: field, value: .boolValue(true))
    }

    // Serialization should fail with invalid values
    let invalidData2 = ProtoWireFormat.marshal(message: invalidMessage2)
    XCTAssertNil(invalidData2, "Serialization should fail with invalid field values")
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

  func testNestedMessageSerialization() {
    // Create a nested message descriptor
    let addressDescriptor = ProtoMessageDescriptor(
      fullName: "Address",
      fields: [
        ProtoFieldDescriptor(name: "street", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "city", number: 2, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "zip", number: 3, type: .string, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a message descriptor with a nested message field
    let personDescriptor = ProtoMessageDescriptor(
      fullName: "Person",
      fields: [
        ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(
          name: "address",
          number: 2,
          type: .message,
          isRepeated: false,
          isMap: false,
          messageType: addressDescriptor
        ),
      ],
      enums: [],
      nestedMessages: [addressDescriptor]
    )

    // Create the nested address message
    let address = ProtoDynamicMessage(descriptor: addressDescriptor)
    address.set(fieldName: "street", value: .stringValue("123 Main St"))
    address.set(fieldName: "city", value: .stringValue("Anytown"))
    address.set(fieldName: "zip", value: .stringValue("12345"))

    // Create the person message with the nested address
    let person = ProtoDynamicMessage(descriptor: personDescriptor)
    person.set(fieldName: "name", value: .stringValue("John Doe"))
    person.set(fieldName: "address", value: .messageValue(address))

    // Serialize the message
    guard let data = ProtoWireFormat.marshal(message: person) else {
      XCTFail("Failed to marshal message with nested message")
      return
    }

    // Deserialize the message
    guard
      let deserializedPerson = ProtoWireFormat.unmarshal(data: data, messageDescriptor: personDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal message with nested message")
      return
    }

    // Verify the top-level field
    XCTAssertEqual(deserializedPerson.get(fieldName: "name")?.getString(), "John Doe")

    // Verify the nested message field
    guard let addressValue = deserializedPerson.get(fieldName: "address") else {
      XCTFail("Address field should be present")
      return
    }

    guard let addressMessage = addressValue.getMessage() as? ProtoDynamicMessage else {
      XCTFail("Address field should be a message value")
      return
    }

    XCTAssertEqual(addressMessage.get(fieldName: "street")?.getString(), "123 Main St")
    XCTAssertEqual(addressMessage.get(fieldName: "city")?.getString(), "Anytown")
    XCTAssertEqual(addressMessage.get(fieldName: "zip")?.getString(), "12345")
  }

  func testPerformanceSerialization() {
    // Create a message descriptor with all primitive field types
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "PerformanceMessage",
      fields: [
        ProtoFieldDescriptor(name: "int32_field", number: 1, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "string_field", number: 2, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "bytes_field", number: 3, type: .bytes, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "double_field", number: 4, type: .double, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a message with values for each field
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(fieldName: "int32_field", value: .intValue(42))
    message.set(fieldName: "string_field", value: .stringValue("Hello, Protocol Buffers!"))
    message.set(fieldName: "bytes_field", value: .bytesValue(Data([0x00, 0x01, 0x02, 0x03, 0xFF])))
    message.set(fieldName: "double_field", value: .doubleValue(3.14159))

    // Measure serialization performance
    measure {
      for _ in 0..<1000 {
        _ = ProtoWireFormat.marshal(message: message)
      }
    }
  }

  func testPerformanceDeserialization() {
    // Create a message descriptor with all primitive field types
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "PerformanceMessage",
      fields: [
        ProtoFieldDescriptor(name: "int32_field", number: 1, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "string_field", number: 2, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "bytes_field", number: 3, type: .bytes, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "double_field", number: 4, type: .double, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a message with values for each field
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(fieldName: "int32_field", value: .intValue(42))
    message.set(fieldName: "string_field", value: .stringValue("Hello, Protocol Buffers!"))
    message.set(fieldName: "bytes_field", value: .bytesValue(Data([0x00, 0x01, 0x02, 0x03, 0xFF])))
    message.set(fieldName: "double_field", value: .doubleValue(3.14159))

    // Serialize the message once to get the data for deserialization testing
    guard let data = ProtoWireFormat.marshal(message: message) else {
      XCTFail("Failed to marshal message")
      return
    }

    // Measure deserialization performance
    measure {
      for _ in 0..<1000 {
        _ = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
      }
    }
  }

  func testEnumFieldSerialization() {
    // Create an enum descriptor
    let colorEnumDescriptor = ProtoEnumDescriptor(
      name: "Color",
      values: [
        ProtoEnumValueDescriptor(name: "RED", number: 0),
        ProtoEnumValueDescriptor(name: "GREEN", number: 1),
        ProtoEnumValueDescriptor(name: "BLUE", number: 2),
      ]
    )

    // Create a message descriptor with an enum field
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "EnumMessage",
      fields: [
        ProtoFieldDescriptor(
          name: "color",
          number: 1,
          type: .enum,
          isRepeated: false,
          isMap: false,
          enumType: colorEnumDescriptor
        )
      ],
      enums: [colorEnumDescriptor],
      nestedMessages: []
    )

    // Create a message with an enum value
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(
      fieldName: "color",
      value: .enumValue(name: "GREEN", number: 1, enumDescriptor: colorEnumDescriptor)
    )

    // Serialize the message
    guard let data = ProtoWireFormat.marshal(message: message) else {
      XCTFail("Failed to marshal message with enum field")
      return
    }

    // Deserialize the message
    guard
      let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal message with enum field")
      return
    }

    // Verify the enum field value
    if let enumValue = deserializedMessage.get(fieldName: "color")?.getEnum() {
      XCTAssertEqual(enumValue.number, 1)
      XCTAssertEqual(enumValue.name, "GREEN")
    }
    else {
      XCTFail("Enum field should be present and have the correct value")
    }
  }

  func testLargeMessageSerialization() {
    // Create a message descriptor with a repeated field for testing large messages
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "LargeMessage",
      fields: [
        ProtoFieldDescriptor(name: "repeated_string", number: 1, type: .string, isRepeated: true, isMap: false)
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a message with a large number of repeated strings
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)

    // Create 1000 string values
    var stringValues: [ProtoValue] = []
    for i in 0..<1000 {
      stringValues.append(.stringValue("String value \(i)"))
    }

    message.set(fieldName: "repeated_string", value: .repeatedValue(stringValues))

    // Serialize the message
    guard let data = ProtoWireFormat.marshal(message: message) else {
      XCTFail("Failed to marshal large message")
      return
    }

    // Verify the serialized data is not empty
    XCTAssertFalse(data.isEmpty, "Serialized data should not be empty")

    // Deserialize the message
    guard
      let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal large message")
      return
    }

    // Verify the repeated field values were preserved
    guard let repeatedValues = deserializedMessage.get(fieldName: "repeated_string")?.getRepeated() else {
      XCTFail("Failed to get repeated field values")
      return
    }

    XCTAssertEqual(repeatedValues.count, 1000, "Should have 1000 string values")
    XCTAssertEqual(repeatedValues[0].getString(), "String value 0")
    XCTAssertEqual(repeatedValues[999].getString(), "String value 999")
  }

  func testErrorHandlingDuringDeserialization() {
    // Create a message descriptor
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "ErrorTestMessage",
      fields: [
        ProtoFieldDescriptor(name: "string_field", number: 1, type: .string, isRepeated: false, isMap: false)
      ],
      enums: [],
      nestedMessages: []
    )

    // Create corrupted data that doesn't match the descriptor
    let corruptedData = Data([0x0A, 0xFF, 0xFF, 0xFF])  // Invalid length for string field

    // Attempt to deserialize the corrupted data
    let deserializedMessage = ProtoWireFormat.unmarshal(data: corruptedData, messageDescriptor: messageDescriptor)

    // Verify that deserialization fails gracefully
    XCTAssertNil(deserializedMessage, "Deserialization should fail with corrupted data")
  }
}
