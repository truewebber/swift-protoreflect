import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

class BasicSerializationTests: XCTestCase {
  // Helper descriptors for nested message tests
  let addressDescriptor = ProtoMessageDescriptor(
    fullName: "Address",
    fields: [
      ProtoFieldDescriptor(name: "street", number: 1, type: .string, isRepeated: false, isMap: false),
      ProtoFieldDescriptor(name: "city", number: 2, type: .string, isRepeated: false, isMap: false)
    ],
    enums: [],
    nestedMessages: []
  )
  
  var personDescriptor: ProtoMessageDescriptor!
  
  override func setUp() {
    super.setUp()
    // Initialize person descriptor with address as nested message
    personDescriptor = ProtoMessageDescriptor(
      fullName: "Person",
      fields: [
        ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(
          name: "address",
          number: 2,
          type: .message(addressDescriptor),
          isRepeated: false,
          isMap: false,
          messageType: addressDescriptor
        )
      ],
      enums: [],
      nestedMessages: [addressDescriptor]
    )
  }
  
  // Helper function to create messages
  private func createSimpleMessage(descriptor: ProtoMessageDescriptor) -> ProtoDynamicMessage {
    return ProtoDynamicMessage(descriptor: descriptor)
  }

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
        ProtoFieldDescriptor(name: "double_field", number: 4, type: .double, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "bool_field", number: 5, type: .bool, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "bytes_field", number: 6, type: .bytes, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Test 1: Valid values for all fields
    let validMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
    validMessage.set(fieldName: "int_field", value: .intValue(42))
    validMessage.set(fieldName: "string_field", value: .stringValue("Hello"))
    validMessage.set(fieldName: "float_field", value: .floatValue(3.14))
    validMessage.set(fieldName: "double_field", value: .doubleValue(2.718))
    validMessage.set(fieldName: "bool_field", value: .boolValue(true))
    validMessage.set(fieldName: "bytes_field", value: .bytesValue(Data([0x00, 0x01, 0x02])))

    let validData = ProtoWireFormat.marshal(message: validMessage)
    XCTAssertNotNil(validData, "Serialization should succeed with valid field values")

    // Test 2: Invalid type for int32 field
    let invalidIntMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
    if let field = messageDescriptor.field(named: "int_field") {
      invalidIntMessage.set(field: field, value: .stringValue("not an int"))
    }
    invalidIntMessage.set(fieldName: "string_field", value: .stringValue("Hello"))
    invalidIntMessage.set(fieldName: "float_field", value: .floatValue(3.14))

    let invalidIntData = ProtoWireFormat.marshal(message: invalidIntMessage)
    XCTAssertNil(invalidIntData, "Serialization should fail with invalid int32 value")

    // Test 3: Invalid type for float field
    let invalidFloatMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
    invalidFloatMessage.set(fieldName: "int_field", value: .intValue(42))
    invalidFloatMessage.set(fieldName: "string_field", value: .stringValue("Hello"))
    if let field = messageDescriptor.field(named: "float_field") {
      invalidFloatMessage.set(field: field, value: .boolValue(true))
    }

    let invalidFloatData = ProtoWireFormat.marshal(message: invalidFloatMessage)
    XCTAssertNil(invalidFloatData, "Serialization should fail with invalid float value")

    // Test 4: Invalid wire format for int32 field
    let invalidWireFormatMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
    if let field = messageDescriptor.field(named: "int_field") {
      invalidWireFormatMessage.set(field: field, value: .bytesValue(Data([0xFF, 0xFF, 0xFF])))
    }
    invalidWireFormatMessage.set(fieldName: "string_field", value: .stringValue("Hello"))
    invalidWireFormatMessage.set(fieldName: "float_field", value: .floatValue(3.14))

    let invalidWireFormatData = ProtoWireFormat.marshal(message: invalidWireFormatMessage)
    XCTAssertNil(invalidWireFormatData, "Serialization should fail with invalid wire format")

    // Test 5: Edge cases for numeric types
    let edgeCaseMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
    edgeCaseMessage.set(fieldName: "int_field", value: .intValue(Int(Int32.max)))
    edgeCaseMessage.set(fieldName: "float_field", value: .floatValue(Float.infinity))
    edgeCaseMessage.set(fieldName: "double_field", value: .doubleValue(Double.infinity))
    edgeCaseMessage.set(fieldName: "string_field", value: .stringValue("Hello"))

    let edgeCaseData = ProtoWireFormat.marshal(message: edgeCaseMessage)
    XCTAssertNotNil(edgeCaseData, "Serialization should succeed with edge case values")

    // Test 6: Invalid repeated field value
    let invalidRepeatedMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
    invalidRepeatedMessage.set(fieldName: "int_field", value: .repeatedValue([.intValue(1), .intValue(2)]))
    invalidRepeatedMessage.set(fieldName: "string_field", value: .stringValue("Hello"))
    invalidRepeatedMessage.set(fieldName: "float_field", value: .floatValue(3.14))

    let invalidRepeatedData = ProtoWireFormat.marshal(message: invalidRepeatedMessage)
    XCTAssertNil(invalidRepeatedData, "Serialization should fail with repeated value for non-repeated field")
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
    mapEntries["one"] = .intValue(1)

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
      fullName: "TestMessage.StringToIntMapEntry",
      fields: [keyFieldDescriptor, valueFieldDescriptor],
      enums: [],
      nestedMessages: []
    )

    // Create a field descriptor for a map field
    let mapFieldDescriptor = ProtoFieldDescriptor(
      name: "string_to_int_map",
      number: 21,
      type: .message(entryDescriptor),
      isRepeated: false,
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

    // Test 1: Basic map serialization
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    let mapValue = ProtoValue.mapValue([
      "one": .intValue(1),
      "two": .intValue(2),
    ])
    message.set(field: mapFieldDescriptor, value: mapValue)

    var data = Data()
    XCTAssertNoThrow(try ProtoWireFormat.encodeField(field: mapFieldDescriptor, value: mapValue, to: &data))
    XCTAssertTrue(data.count > 0, "Encoded map field should not be empty")

    // Test 2: Map with empty key
    let emptyKeyMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
    let emptyKeyMapValue = ProtoValue.mapValue([
      "": .intValue(0)
    ])
    emptyKeyMessage.set(field: mapFieldDescriptor, value: emptyKeyMapValue)

    var emptyKeyData = Data()
    XCTAssertNoThrow(
      try ProtoWireFormat.encodeField(field: mapFieldDescriptor, value: emptyKeyMapValue, to: &emptyKeyData)
    )
    XCTAssertTrue(emptyKeyData.count > 0, "Encoded map field with empty key should not be empty")

    // Test 3: Map with large values
    let largeValueMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
    let largeValueMapValue = ProtoValue.mapValue([
      "large": .intValue(Int(Int32.max))
    ])
    largeValueMessage.set(field: mapFieldDescriptor, value: largeValueMapValue)

    var largeValueData = Data()
    XCTAssertNoThrow(
      try ProtoWireFormat.encodeField(field: mapFieldDescriptor, value: largeValueMapValue, to: &largeValueData)
    )
    XCTAssertTrue(largeValueData.count > 0, "Encoded map field with large value should not be empty")

    // Test 4: Map with many entries
    let manyEntriesMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
    var manyEntriesMap: [String: ProtoValue] = [:]
    for i in 0..<100 {
      manyEntriesMap["key\(i)"] = .intValue(i)
    }
    let manyEntriesMapValue = ProtoValue.mapValue(manyEntriesMap)
    manyEntriesMessage.set(field: mapFieldDescriptor, value: manyEntriesMapValue)

    var manyEntriesData = Data()
    XCTAssertNoThrow(
      try ProtoWireFormat.encodeField(field: mapFieldDescriptor, value: manyEntriesMapValue, to: &manyEntriesData)
    )
    XCTAssertTrue(manyEntriesData.count > 0, "Encoded map field with many entries should not be empty")

    // Test 5: Decode and verify map entries
    guard
      let decodedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Unmarshal should succeed")
      return
    }

    let decodedMap = decodedMessage.get(field: mapFieldDescriptor)?.getMap()
    XCTAssertEqual(decodedMap?.count, 2, "Decoded map should have 2 entries")
    XCTAssertEqual(decodedMap?["one"]?.getInt(), 1)
    XCTAssertEqual(decodedMap?["two"]?.getInt(), 2)

    // Test 6: Invalid map entry type
    let invalidMapValue = ProtoValue.mapValue([
      "invalid": .stringValue("not an int")
    ])
    var invalidData = Data()
    XCTAssertThrowsError(
      try ProtoWireFormat.encodeField(field: mapFieldDescriptor, value: invalidMapValue, to: &invalidData)
    )
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
    let setResult = message.set(field: mapFieldDescriptor, value: ProtoValue.mapValue(mapEntries))
    XCTAssertTrue(setResult, "Setting map field should succeed")

    // Verify the map field was set correctly
    let mapFieldValue = message.get(field: mapFieldDescriptor)
    XCTAssertNotNil(mapFieldValue, "Map field value should not be nil")

    if case let ProtoValue.mapValue(entries)? = mapFieldValue {
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

    if case let ProtoValue.mapValue(entries) = mapValue {
      XCTAssertEqual(entries.count, 1, "Map should have 1 entry")
      XCTAssertEqual(entries["key1"]?.getString(), "value1", "Value for key 'key1' should be 'value1'")
    }
    else {
      XCTFail("Field value should be a map value")
    }
  }

  func testNestedMessageSerialization() {
    // Test 1: Simple nested message
    let address = createSimpleMessage(descriptor: addressDescriptor)
    address.set(field: addressDescriptor.field(named: "street")!, value: .stringValue("123 Main St"))
    address.set(field: addressDescriptor.field(named: "city")!, value: .stringValue("Springfield"))
    
    let person = createSimpleMessage(descriptor: personDescriptor)
    person.set(field: personDescriptor.field(named: "name")!, value: .stringValue("John Doe"))
    person.set(field: personDescriptor.field(named: "address")!, value: .messageValue(address))
    
    // Test length-delimited format
    guard let data = ProtoWireFormat.marshal(message: person) else {
        XCTFail("Failed to marshal message")
        return
    }
    
    // Verify length-delimited format
    var offset = 0
    while offset < data.count {
        let (tag, tagBytes) = ProtoWireFormat.decodeVarint(data.dropFirst(offset))
        XCTAssertNotNil(tag)
        offset += tagBytes
        
        let wireType = Int(tag! & 0x7)
        if wireType == ProtoWireFormat.wireTypeLengthDelimited {
            let (length, lengthBytes) = ProtoWireFormat.decodeVarint(data.dropFirst(offset))
            XCTAssertNotNil(length)
            offset += lengthBytes
            offset += Int(length!)
        }
    }
    
    // Test deserialization
    guard let decodedPerson = ProtoWireFormat.unmarshal(data: data, messageDescriptor: personDescriptor) else {
        XCTFail("Failed to unmarshal message")
        return
    }
    
    // Verify decoded values
    XCTAssertEqual(decodedPerson.get(field: personDescriptor.field(named: "name")!)?.getString(), "John Doe")
    guard case .messageValue(let decodedAddress) = decodedPerson.get(field: personDescriptor.field(named: "address")!) else {
        XCTFail("Failed to get address field")
        return
    }
    XCTAssertEqual(decodedAddress.get(field: addressDescriptor.field(named: "street")!)?.getString(), "123 Main St")
    XCTAssertEqual(decodedAddress.get(field: addressDescriptor.field(named: "city")!)?.getString(), "Springfield")

    // Test 2: Deeply nested messages
    let cityDescriptor = ProtoMessageDescriptor(
      fullName: "City",
      fields: [
        ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "population", number: 2, type: .int32, isRepeated: false, isMap: false)
      ],
      enums: [],
      nestedMessages: []
    )

    let stateDescriptor = ProtoMessageDescriptor(
      fullName: "State",
      fields: [
        ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(
          name: "capital",
          number: 2,
          type: .message(cityDescriptor),
          isRepeated: false,
          isMap: false,
          messageType: cityDescriptor
        ),
        ProtoFieldDescriptor(
          name: "cities",
          number: 3,
          type: .message(cityDescriptor),
          isRepeated: true,
          isMap: false,
          messageType: cityDescriptor
        )
      ],
      enums: [],
      nestedMessages: [cityDescriptor]
    )

    let countryDescriptor = ProtoMessageDescriptor(
      fullName: "Country",
      fields: [
        ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(
          name: "capital",
          number: 2,
          type: .message(cityDescriptor),
          isRepeated: false,
          isMap: false,
          messageType: cityDescriptor
        ),
        ProtoFieldDescriptor(
          name: "states",
          number: 3,
          type: .message(stateDescriptor),
          isRepeated: true,
          isMap: false,
          messageType: stateDescriptor
        )
      ],
      enums: [],
      nestedMessages: [cityDescriptor, stateDescriptor]
    )

    // Create deeply nested structure
    let city = ProtoDynamicMessage(descriptor: cityDescriptor)
    city.set(field: cityDescriptor.field(named: "name")!, value: .stringValue("Washington"))
    city.set(field: cityDescriptor.field(named: "population")!, value: .intValue(705749))

    let state = ProtoDynamicMessage(descriptor: stateDescriptor)
    state.set(field: stateDescriptor.field(named: "name")!, value: .stringValue("California"))
    state.set(field: stateDescriptor.field(named: "capital")!, value: .messageValue(city))

    let cities: [ProtoValue] = [
      {
        let msg = ProtoDynamicMessage(descriptor: cityDescriptor)
        msg.set(field: cityDescriptor.field(named: "name")!, value: .stringValue("San Francisco"))
        msg.set(field: cityDescriptor.field(named: "population")!, value: .intValue(873965))
        return .messageValue(msg)
      }(),
      {
        let msg = ProtoDynamicMessage(descriptor: cityDescriptor)
        msg.set(field: cityDescriptor.field(named: "name")!, value: .stringValue("Los Angeles"))
        msg.set(field: cityDescriptor.field(named: "population")!, value: .intValue(3898747))
        return .messageValue(msg)
      }()
    ]
    state.set(field: stateDescriptor.field(named: "cities")!, value: .repeatedValue(cities))

    let country = ProtoDynamicMessage(descriptor: countryDescriptor)
    country.set(field: countryDescriptor.field(named: "name")!, value: .stringValue("United States"))
    country.set(field: countryDescriptor.field(named: "capital")!, value: .messageValue(city))
    country.set(field: countryDescriptor.field(named: "states")!, value: .repeatedValue([.messageValue(state)]))

    // Test serialization of deeply nested structure
    guard let deepData = ProtoWireFormat.marshal(message: country) else {
      XCTFail("Failed to marshal deeply nested message")
      return
    }

    // Test deserialization of deeply nested structure
    guard let decodedCountry = ProtoWireFormat.unmarshal(data: deepData, messageDescriptor: countryDescriptor) as? ProtoDynamicMessage else {
      XCTFail("Failed to unmarshal deeply nested message")
      return
    }

    // Verify deeply nested structure
    XCTAssertEqual(decodedCountry.get(field: countryDescriptor.field(named: "name")!)?.getString(), "United States")
    
    guard case .messageValue(let decodedCapital) = decodedCountry.get(field: countryDescriptor.field(named: "capital")!) else {
      XCTFail("Failed to get capital")
      return
    }
    XCTAssertEqual(decodedCapital.get(field: cityDescriptor.field(named: "name")!)?.getString(), "Washington")
    XCTAssertEqual(decodedCapital.get(field: cityDescriptor.field(named: "population")!)?.getInt(), 705749)

    guard let states = decodedCountry.get(field: countryDescriptor.field(named: "states")!)?.getRepeated() else {
      XCTFail("Failed to get states")
      return
    }
    XCTAssertEqual(states.count, 1)

    guard case .messageValue(let decodedState) = states[0] else {
      XCTFail("Failed to get first state")
      return
    }
    XCTAssertEqual(decodedState.get(field: stateDescriptor.field(named: "name")!)?.getString(), "California")

    guard let decodedCities = decodedState.get(field: stateDescriptor.field(named: "cities")!)?.getRepeated() else {
      XCTFail("Failed to get cities")
      return
    }
    XCTAssertEqual(decodedCities.count, 2)

    guard case .messageValue(let firstCity) = decodedCities[0] else {
      XCTFail("Failed to get first city")
      return
    }
    XCTAssertEqual(firstCity.get(field: cityDescriptor.field(named: "name")!)?.getString(), "San Francisco")
    XCTAssertEqual(firstCity.get(field: cityDescriptor.field(named: "population")!)?.getInt(), 873965)

    guard case .messageValue(let secondCity) = decodedCities[1] else {
      XCTFail("Failed to get second city")
      return
    }
    XCTAssertEqual(secondCity.get(field: cityDescriptor.field(named: "name")!)?.getString(), "Los Angeles")
    XCTAssertEqual(secondCity.get(field: cityDescriptor.field(named: "population")!)?.getInt(), 3898747)
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
          type: .enum(colorEnumDescriptor),
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

  func testUnknownFields() {
    // Create a message descriptor with some fields
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "known_field", number: 1, type: .int32, isRepeated: false, isMap: false)
      ],
      enums: [],
      nestedMessages: []
    )

    // Create serialized data with unknown fields
    let serializedData = Data([
      8, 42,  // known_field = 42
      16, 1,  // unknown_field = 1
      24, 2,  // another_unknown_field = 2
      32, 3,  // unknown_enum_field = 3
      42, 4,  // unknown_bytes_field = 4
      50, 5,  // unknown_string_field = 5
    ])

    // Deserialize the message
    guard
      let message = ProtoWireFormat.unmarshal(data: serializedData, messageDescriptor: messageDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal message with unknown fields")
      return
    }

    // Verify known field
    XCTAssertEqual(message.get(fieldName: "known_field")?.getInt(), 42)

    // Verify unknown fields are preserved
    let unknownFields = message.getUnknownFields()
    XCTAssertEqual(unknownFields.count, 5)

    // Test 1: Unknown int32 field (field number 16, value 1)
    XCTAssertEqual(unknownFields[16]?.first, Data([16, 1]))

    // Test 2: Unknown int32 field with different number (field number 24, value 2)
    XCTAssertEqual(unknownFields[24]?.first, Data([24, 2]))

    // Test 3: Unknown enum field (field number 32, value 3)
    XCTAssertEqual(unknownFields[32]?.first, Data([32, 3]))

    // Test 4: Unknown bytes field (field number 42, value 4)
    XCTAssertEqual(unknownFields[42]?.first, Data([42, 4]))

    // Test 5: Unknown string field (field number 50, value "5")
    XCTAssertEqual(unknownFields[50]?.first, Data([50, 5]))

    // Test 6: Serialize message with unknown fields
    guard let reserializedData = ProtoWireFormat.marshal(message: message) else {
      XCTFail("Failed to reserialize message with unknown fields")
      return
    }

    // Verify that unknown fields are preserved in reserialization
    XCTAssertTrue(reserializedData.contains(Data([16, 1])))  // unknown_field = 1
    XCTAssertTrue(reserializedData.contains(Data([24, 2])))  // another_unknown_field = 2
    XCTAssertTrue(reserializedData.contains(Data([32, 3])))  // unknown_enum_field = 3
    XCTAssertTrue(reserializedData.contains(Data([42, 4])))  // unknown_bytes_field = 4
    XCTAssertTrue(reserializedData.contains(Data([50, 5])))  // unknown_string_field = 5

    // Test 7: Unknown fields in nested message
    let nestedMessageDescriptor = ProtoMessageDescriptor(
      fullName: "NestedMessage",
      fields: [
        ProtoFieldDescriptor(name: "nested_field", number: 1, type: .int32, isRepeated: false, isMap: false)
      ],
      enums: [],
      nestedMessages: []
    )

    let nestedData = Data([8, 42, 16, 1])  // nested_field = 42, unknown_field = 1

    guard
      let nestedMessage = ProtoWireFormat.unmarshal(data: nestedData, messageDescriptor: nestedMessageDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal nested message with unknown fields")
      return
    }

    XCTAssertEqual(nestedMessage.get(fieldName: "nested_field")?.getInt(), 42)
    XCTAssertEqual(nestedMessage.getUnknownFields()[16]?.first, Data([16, 1]))
  }

  func testOneofFields() {
    // Create field descriptors first
    let nameField = ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false)
    let ageField = ProtoFieldDescriptor(name: "age", number: 2, type: .int32, isRepeated: false, isMap: false)
    let stringField = ProtoFieldDescriptor(name: "string_field", number: 3, type: .string, isRepeated: false, isMap: false)
    let intField = ProtoFieldDescriptor(name: "int_field", number: 4, type: .int32, isRepeated: false, isMap: false)
    
    // Use the new factory method to create a message descriptor with oneof fields
    let messageDescriptor = ProtoMessageDescriptor.createWithOneofs(
      fullName: "TestMessage",
      regularFields: [nameField, ageField],
      oneofs: [
        (name: "test_oneof", fields: [stringField, intField])
      ]
    )

    // Test 1: Basic oneof field behavior
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(fieldName: "name", value: ProtoValue.stringValue("John"))
    message.set(fieldName: "age", value: ProtoValue.intValue(30))
    message.set(fieldName: "string_field", value: ProtoValue.stringValue("test"))

    // Verify oneof field behavior
    XCTAssertEqual(message.get(fieldName: "string_field")?.getString(), "test")
    XCTAssertNil(message.get(fieldName: "int_field"))

    // Test 2: Setting another oneof field
    message.set(fieldName: "int_field", value: ProtoValue.intValue(42))

    // Verify previous oneof field is cleared
    XCTAssertNil(message.get(fieldName: "string_field"))
    XCTAssertEqual(message.get(fieldName: "int_field")?.getInt(), 42)

    // Test 3: Serialization and deserialization
    guard let data = ProtoWireFormat.marshal(message: message) else {
      XCTFail("Failed to marshal message with oneof field")
      return
    }

    guard
      let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal message with oneof field")
      return
    }

    // Verify deserialized message
    XCTAssertEqual(deserializedMessage.get(fieldName: "name")?.getString(), "John")
    XCTAssertEqual(deserializedMessage.get(fieldName: "age")?.getInt(), 30)
    XCTAssertNil(deserializedMessage.get(fieldName: "string_field"))
    XCTAssertEqual(deserializedMessage.get(fieldName: "int_field")?.getInt(), 42)

    // Test 4: Empty oneof field
    let emptyMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
    emptyMessage.set(fieldName: "name", value: ProtoValue.stringValue("Empty"))

    guard let emptyData = ProtoWireFormat.marshal(message: emptyMessage) else {
      XCTFail("Failed to marshal message with empty oneof field")
      return
    }

    guard
      let deserializedEmptyMessage = ProtoWireFormat.unmarshal(data: emptyData, messageDescriptor: messageDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal message with empty oneof field")
      return
    }

    XCTAssertEqual(deserializedEmptyMessage.get(fieldName: "name")?.getString(), "Empty")
    XCTAssertNil(deserializedEmptyMessage.get(fieldName: "string_field"))
    XCTAssertNil(deserializedEmptyMessage.get(fieldName: "int_field"))

    // Test 5: Setting non-oneof field doesn't affect oneof
    let nonOneofMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
    nonOneofMessage.set(fieldName: "string_field", value: ProtoValue.stringValue("test"))
    nonOneofMessage.set(fieldName: "name", value: ProtoValue.stringValue("John"))

    XCTAssertEqual(nonOneofMessage.get(fieldName: "string_field")?.getString(), "test")
    XCTAssertEqual(nonOneofMessage.get(fieldName: "name")?.getString(), "John")
  }

  func testExtensions() {
    // Create extension field descriptors
    let extensionFieldDescriptor = ProtoFieldDescriptor(
      name: "extension_field",
      number: 100,
      type: .string,
      isRepeated: false,
      isMap: false
    )

    let extensionField2Descriptor = ProtoFieldDescriptor(
      name: "extension_field2",
      number: 101,
      type: .int32,
      isRepeated: false,
      isMap: false
    )

    // Create a message descriptor with extension field
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "base_field", number: 1, type: .int32, isRepeated: false, isMap: false),
        extensionFieldDescriptor,
      ],
      enums: [],
      nestedMessages: []
    )

    // Test 1: Basic extension field behavior
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(fieldName: "base_field", value: ProtoValue.intValue(42))
    message.set(fieldName: "extension_field", value: ProtoValue.stringValue("extension value"))

    // Verify extension field
    XCTAssertEqual(message.get(fieldName: "extension_field")?.getString(), "extension value")

    // Test 2: Serialization and deserialization
    guard let data = ProtoWireFormat.marshal(message: message) else {
      XCTFail("Failed to marshal message with extension")
      return
    }

    guard
      let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal message with extension")
      return
    }

    // Verify extension field is preserved
    XCTAssertEqual(deserializedMessage.get(fieldName: "extension_field")?.getString(), "extension value")

    // Test 3: Multiple extension fields
    let messageWithMultipleExtensions = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "base_field", number: 1, type: .int32, isRepeated: false, isMap: false),
        extensionFieldDescriptor,
        extensionField2Descriptor,
      ],
      enums: [],
      nestedMessages: []
    )

    let multipleExtensionsMessage = ProtoDynamicMessage(descriptor: messageWithMultipleExtensions)
    multipleExtensionsMessage.set(fieldName: "base_field", value: ProtoValue.intValue(42))
    multipleExtensionsMessage.set(fieldName: "extension_field", value: ProtoValue.stringValue("first extension"))
    multipleExtensionsMessage.set(fieldName: "extension_field2", value: ProtoValue.intValue(100))

    guard let multipleExtensionsData = ProtoWireFormat.marshal(message: multipleExtensionsMessage) else {
      XCTFail("Failed to marshal message with multiple extensions")
      return
    }

    guard
      let deserializedMultipleExtensionsMessage = ProtoWireFormat.unmarshal(
        data: multipleExtensionsData,
        messageDescriptor: messageWithMultipleExtensions
      ) as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal message with multiple extensions")
      return
    }

    XCTAssertEqual(
      deserializedMultipleExtensionsMessage.get(fieldName: "extension_field")?.getString(),
      "first extension"
    )
    XCTAssertEqual(deserializedMultipleExtensionsMessage.get(fieldName: "extension_field2")?.getInt(), 100)

    // Test 4: Extension field in nested message
    let nestedMessageDescriptor = ProtoMessageDescriptor(
      fullName: "NestedMessage",
      fields: [
        ProtoFieldDescriptor(name: "nested_field", number: 1, type: .int32, isRepeated: false, isMap: false),
        extensionFieldDescriptor,
      ],
      enums: [],
      nestedMessages: []
    )

    let nestedMessage = ProtoDynamicMessage(descriptor: nestedMessageDescriptor)
    nestedMessage.set(fieldName: "nested_field", value: ProtoValue.intValue(42))
    nestedMessage.set(fieldName: "extension_field", value: ProtoValue.stringValue("nested extension"))

    guard let nestedData = ProtoWireFormat.marshal(message: nestedMessage) else {
      XCTFail("Failed to marshal nested message with extension")
      return
    }

    guard
      let deserializedNestedMessage = ProtoWireFormat.unmarshal(
        data: nestedData,
        messageDescriptor: nestedMessageDescriptor
      ) as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal nested message with extension")
      return
    }

    XCTAssertEqual(deserializedNestedMessage.get(fieldName: "nested_field")?.getInt(), 42)
    XCTAssertEqual(deserializedNestedMessage.get(fieldName: "extension_field")?.getString(), "nested extension")
  }
}
