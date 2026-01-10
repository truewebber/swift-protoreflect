//
// BinarySerializationTests.swift
//
// Tests for binary serialization of Protocol Buffers
//
// Test cases from the plan:
// - Test-BIN-001: Serialization of all proto3 scalar types with exact byte representation matching C++ protoc
// - Test-BIN-002: Serialization of strings with various encodings, including UTF-8 and multibyte characters
// - Test-BIN-003: Serialization of nested messages with verification of correct wire format representation
// - Test-BIN-004: Serialization of repeated fields with packed and non-packed formats
// - Test-BIN-005: Serialization of map fields with various key and value types

import XCTest

@testable import SwiftProtoReflect

final class BinarySerializationTests: XCTestCase {

  var fileDescriptor: FileDescriptor!
  var messageFactory: MessageFactory!
  var serializer: BinarySerializer!

  override func setUp() {
    super.setUp()

    fileDescriptor = FileDescriptor(name: "test_serialization.proto", package: "test.serialization")
    messageFactory = MessageFactory()
    serializer = BinarySerializer()
  }

  override func tearDown() {
    fileDescriptor = nil
    messageFactory = nil
    serializer = nil
    super.tearDown()
  }

  // MARK: - Scalar Types Tests (Test-BIN-001)

  func testSerializeAllScalarTypes() throws {
    // Create message with all scalar types
    var scalarMessage = MessageDescriptor(name: "ScalarMessage", parent: fileDescriptor)

    scalarMessage.addField(FieldDescriptor(name: "double_field", number: 1, type: .double))
    scalarMessage.addField(FieldDescriptor(name: "float_field", number: 2, type: .float))
    scalarMessage.addField(FieldDescriptor(name: "int32_field", number: 3, type: .int32))
    scalarMessage.addField(FieldDescriptor(name: "int64_field", number: 4, type: .int64))
    scalarMessage.addField(FieldDescriptor(name: "uint32_field", number: 5, type: .uint32))
    scalarMessage.addField(FieldDescriptor(name: "uint64_field", number: 6, type: .uint64))
    scalarMessage.addField(FieldDescriptor(name: "sint32_field", number: 7, type: .sint32))
    scalarMessage.addField(FieldDescriptor(name: "sint64_field", number: 8, type: .sint64))
    scalarMessage.addField(FieldDescriptor(name: "fixed32_field", number: 9, type: .fixed32))
    scalarMessage.addField(FieldDescriptor(name: "fixed64_field", number: 10, type: .fixed64))
    scalarMessage.addField(FieldDescriptor(name: "sfixed32_field", number: 11, type: .sfixed32))
    scalarMessage.addField(FieldDescriptor(name: "sfixed64_field", number: 12, type: .sfixed64))
    scalarMessage.addField(FieldDescriptor(name: "bool_field", number: 13, type: .bool))

    fileDescriptor.addMessage(scalarMessage)

    // Create message with data
    let values: [String: Any] = [
      "double_field": 3.14159,
      "float_field": Float(2.718),
      "int32_field": Int32(-42),
      "int64_field": Int64(-9_223_372_036_854_775_000),
      "uint32_field": UInt32(4_294_967_295),
      "uint64_field": UInt64(18_446_744_073_709_551_615),
      "sint32_field": Int32(-2_147_483_648),
      "sint64_field": Int64(-9_223_372_036_854_775_000),
      "fixed32_field": UInt32(123_456_789),
      "fixed64_field": UInt64(987_654_321_012_345),
      "sfixed32_field": Int32(-123_456_789),
      "sfixed64_field": Int64(-987_654_321_012_345),
      "bool_field": true,
    ]

    let message = try messageFactory.createMessage(from: scalarMessage, with: values)

    // Serialize
    let data = try serializer.serialize(message)

    // Verify that data is not empty
    XCTAssertFalse(data.isEmpty)

    // Verify presence of tags for each field
    // Tags: double=1, float=2, int32=3, etc.
    // Wire types: varint=0, fixed64=1, fixed32=5, length-delimited=2

    // Verify that correct tags are present for known values
    let dataArray = Array(data)

    // Tag for field 1 (double): (1 << 3) | 1 = 9 (fixed64)
    XCTAssertTrue(dataArray.contains(9))

    // Tag for field 2 (float): (2 << 3) | 5 = 21 (fixed32)
    XCTAssertTrue(dataArray.contains(21))

    // Tag for field 3 (int32): (3 << 3) | 0 = 24 (varint)
    XCTAssertTrue(dataArray.contains(24))

    // Tag for field 13 (bool): (13 << 3) | 0 = 104 (varint)
    XCTAssertTrue(dataArray.contains(104))
  }

  func testSerializeDoubleValue() throws {
    var message = MessageDescriptor(name: "DoubleMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "value", number: 1, type: .double))
    fileDescriptor.addMessage(message)

    let dynamicMessage = try messageFactory.createMessage(from: message, with: ["value": 3.14159])
    let data = try serializer.serialize(dynamicMessage)

    // Verify wire format: tag (field 1, wire type 1) + 8 bytes double
    XCTAssertEqual(data.count, 9)  // 1 byte tag + 8 bytes double
    XCTAssertEqual(data[0], 9)  // Tag: (1 << 3) | 1 = 9
  }

  func testSerializeFloatValue() throws {
    var message = MessageDescriptor(name: "FloatMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "value", number: 1, type: .float))
    fileDescriptor.addMessage(message)

    let dynamicMessage = try messageFactory.createMessage(from: message, with: ["value": Float(2.718)])
    let data = try serializer.serialize(dynamicMessage)

    // Verify wire format: tag (field 1, wire type 5) + 4 bytes float
    XCTAssertEqual(data.count, 5)  // 1 byte tag + 4 bytes float
    XCTAssertEqual(data[0], 13)  // Tag: (1 << 3) | 5 = 13
  }

  func testSerializeBoolValue() throws {
    var message = MessageDescriptor(name: "BoolMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "value", number: 1, type: .bool))
    fileDescriptor.addMessage(message)

    // Test true
    let trueMessage = try messageFactory.createMessage(from: message, with: ["value": true])
    let trueData = try serializer.serialize(trueMessage)

    XCTAssertEqual(trueData.count, 2)  // 1 byte tag + 1 byte value
    XCTAssertEqual(trueData[0], 8)  // Tag: (1 << 3) | 0 = 8
    XCTAssertEqual(trueData[1], 1)  // true = 1

    // Test false
    let falseMessage = try messageFactory.createMessage(from: message, with: ["value": false])
    let falseData = try serializer.serialize(falseMessage)

    XCTAssertEqual(falseData.count, 2)
    XCTAssertEqual(falseData[0], 8)
    XCTAssertEqual(falseData[1], 0)  // false = 0
  }

  // MARK: - String and Bytes Tests (Test-BIN-002)

  func testSerializeStringValue() throws {
    var message = MessageDescriptor(name: "StringMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    fileDescriptor.addMessage(message)

    let testString = "Hello, 世界!"
    let dynamicMessage = try messageFactory.createMessage(from: message, with: ["value": testString])
    let data = try serializer.serialize(dynamicMessage)

    // Verify wire format: tag + length + UTF-8 bytes
    XCTAssertGreaterThanOrEqual(data.count, testString.utf8.count + 2)  // at least tag + length + content
    XCTAssertEqual(data[0], 10)  // Tag: (1 << 3) | 2 = 10 (length-delimited)

    // Verify that string is properly UTF-8 encoded
    let utf8Data = testString.data(using: .utf8)!
    XCTAssertEqual(data[1], UInt8(utf8Data.count))  // String length

    // Verify content
    let stringContent = data.suffix(from: 2)
    XCTAssertEqual(Data(stringContent), utf8Data)
  }

  func testSerializeBytesValue() throws {
    var message = MessageDescriptor(name: "BytesMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "value", number: 1, type: .bytes))
    fileDescriptor.addMessage(message)

    let testBytes = Data([0x01, 0x02, 0x03, 0xFF, 0xAB])
    let dynamicMessage = try messageFactory.createMessage(from: message, with: ["value": testBytes])
    let data = try serializer.serialize(dynamicMessage)

    // Verify wire format
    XCTAssertEqual(data.count, testBytes.count + 2)  // tag + length + content
    XCTAssertEqual(data[0], 10)  // Tag: (1 << 3) | 2 = 10
    XCTAssertEqual(data[1], UInt8(testBytes.count))  // Length

    // Verify content
    let bytesContent = data.suffix(from: 2)
    XCTAssertEqual(Data(bytesContent), testBytes)
  }

  func testSerializeEmptyString() throws {
    var message = MessageDescriptor(name: "EmptyStringMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    fileDescriptor.addMessage(message)

    let dynamicMessage = try messageFactory.createMessage(from: message, with: ["value": ""])
    let data = try serializer.serialize(dynamicMessage)

    XCTAssertEqual(data.count, 2)  // tag + length(0)
    XCTAssertEqual(data[0], 10)  // Tag: (1 << 3) | 2 = 10
    XCTAssertEqual(data[1], 0)  // Length = 0
  }

  // MARK: - Nested Messages Tests (Test-BIN-003)

  func testSerializeNestedMessage() throws {
    // Create nested message
    var nestedMessage = MessageDescriptor(name: "NestedMessage", parent: fileDescriptor)
    nestedMessage.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    nestedMessage.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    fileDescriptor.addMessage(nestedMessage)

    // Create parent message
    var parentMessage = MessageDescriptor(name: "ParentMessage", parent: fileDescriptor)
    parentMessage.addField(
      FieldDescriptor(
        name: "nested",
        number: 1,
        type: .message,
        typeName: nestedMessage.fullName
      )
    )
    fileDescriptor.addMessage(parentMessage)

    // Create nested message
    let nested = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int32(42),
        "name": "test",
      ]
    )

    // Create parent message
    var parent = messageFactory.createMessage(from: parentMessage)
    try parent.set(nested, forField: "nested")

    // Serialize
    let data = try serializer.serialize(parent)

    // Verify structure: tag + length + nested_content
    XCTAssertGreaterThan(data.count, 5)  // at least several bytes
    XCTAssertEqual(data[0], 10)  // Tag: (1 << 3) | 2 = 10 (length-delimited)

    // Verify that nested message contains correct tags
    let nestedLength = data[1]
    let nestedContent = data.suffix(from: 2).prefix(Int(nestedLength))
    let nestedArray = Array(nestedContent)

    // Look for nested field tags: id (field 1, int32) and name (field 2, string)
    XCTAssertTrue(nestedArray.contains(8))  // Tag for id: (1 << 3) | 0 = 8
    XCTAssertTrue(nestedArray.contains(18))  // Tag for name: (2 << 3) | 2 = 18
  }

  // MARK: - Repeated Fields Tests (Test-BIN-004)

  func testSerializeRepeatedFieldNonPacked() throws {
    var message = MessageDescriptor(name: "RepeatedMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "values", number: 1, type: .string, isRepeated: true))
    fileDescriptor.addMessage(message)

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "values": ["hello", "world", "test"]
      ]
    )

    // Use non-packed serialization for strings
    let serializer = BinarySerializer(options: SerializationOptions(usePackedRepeated: false))
    let data = try serializer.serialize(dynamicMessage)

    // Verify that each element has its own tag
    let dataArray = Array(data)
    let tagCount = dataArray.filter { $0 == 10 }.count  // Tag: (1 << 3) | 2 = 10
    XCTAssertEqual(tagCount, 3)  // Three elements = three tags
  }

  func testSerializeRepeatedFieldPacked() throws {
    var message = MessageDescriptor(name: "PackedMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "values", number: 1, type: .int32, isRepeated: true))
    fileDescriptor.addMessage(message)

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "values": [Int32(1), Int32(2), Int32(3), Int32(4), Int32(5)]
      ]
    )

    // Use packed serialization
    let data = try serializer.serialize(dynamicMessage)

    // Verify that only one tag with length-delimited wire type is used
    let dataArray = Array(data)
    let tagCount = dataArray.filter { $0 == 10 }.count  // Tag: (1 << 3) | 2 = 10 (packed)
    XCTAssertEqual(tagCount, 1)  // Only one tag for packed field
  }

  func testSerializeEmptyRepeatedField() throws {
    var message = MessageDescriptor(name: "EmptyRepeatedMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "values", number: 1, type: .int32, isRepeated: true))
    fileDescriptor.addMessage(message)

    // Create message without setting empty array
    let dynamicMessage = messageFactory.createMessage(from: message)

    let data = try serializer.serialize(dynamicMessage)

    // Field without values should not generate data in proto3
    XCTAssertEqual(data.count, 0)
  }

  // MARK: - Map Fields Tests (Test-BIN-005)

  func testSerializeMapField() throws {
    // Create map field: map<string, int32>
    let keyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: keyFieldInfo, valueFieldInfo: valueFieldInfo)

    var message = MessageDescriptor(name: "MapMessage", parent: fileDescriptor)
    message.addField(
      FieldDescriptor(
        name: "string_to_int",
        number: 1,
        type: .message,
        typeName: "string_to_int_entry",
        isMap: true,
        mapEntryInfo: mapEntryInfo
      )
    )
    fileDescriptor.addMessage(message)

    let mapData: [String: Int32] = [
      "first": 1,
      "second": 2,
      "third": 3,
    ]

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "string_to_int": mapData
      ]
    )

    let data = try serializer.serialize(dynamicMessage)

    // Verify that data is not empty for map with 3 elements
    XCTAssertGreaterThan(data.count, 0)

    let dataArray = Array(data)

    // Verify presence of entry tag (field 1, length-delimited)
    XCTAssertTrue(dataArray.contains(10))  // Tag: (1 << 3) | 2 = 10

    // Verify that inside entries there are tags for values
    // Value field tag: (2 << 3) | 0 = 16
    XCTAssertTrue(dataArray.contains(16))  // Tag for value field
  }

  func testSerializeEmptyMapField() throws {
    let keyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: keyFieldInfo, valueFieldInfo: valueFieldInfo)

    var message = MessageDescriptor(name: "EmptyMapMessage", parent: fileDescriptor)
    message.addField(
      FieldDescriptor(
        name: "empty_map",
        number: 1,
        type: .message,
        typeName: "empty_map_entry",
        isMap: true,
        mapEntryInfo: mapEntryInfo
      )
    )
    fileDescriptor.addMessage(message)

    // Create message without setting map field
    let dynamicMessage = messageFactory.createMessage(from: message)

    let data = try serializer.serialize(dynamicMessage)

    // Map field without values should not generate data
    XCTAssertEqual(data.count, 0)
  }

  // MARK: - Enum Tests

  func testSerializeEnumField() throws {
    // Create enum
    var enumDescriptor = EnumDescriptor(name: "Status", parent: fileDescriptor)
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "ACTIVE", number: 1))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "INACTIVE", number: 2))
    fileDescriptor.addEnum(enumDescriptor)

    var message = MessageDescriptor(name: "EnumMessage", parent: fileDescriptor)
    message.addField(
      FieldDescriptor(
        name: "status",
        number: 1,
        type: .enum,
        typeName: enumDescriptor.fullName
      )
    )
    fileDescriptor.addMessage(message)

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "status": Int32(1)  // ACTIVE
      ]
    )

    let data = try serializer.serialize(dynamicMessage)

    XCTAssertEqual(data.count, 2)  // tag + value
    XCTAssertEqual(data[0], 8)  // Tag: (1 << 3) | 0 = 8
    XCTAssertEqual(data[1], 1)  // ACTIVE = 1
  }

  // MARK: - ZigZag Encoding Tests

  func testZigZagEncoding() {
    // Test ZigZag encoding for sint32
    XCTAssertEqual(BinarySerializer.zigzagEncode32(0), 0)
    XCTAssertEqual(BinarySerializer.zigzagEncode32(-1), 1)
    XCTAssertEqual(BinarySerializer.zigzagEncode32(1), 2)
    XCTAssertEqual(BinarySerializer.zigzagEncode32(-2), 3)
    XCTAssertEqual(BinarySerializer.zigzagEncode32(2_147_483_647), 4_294_967_294)
    XCTAssertEqual(BinarySerializer.zigzagEncode32(-2_147_483_648), 4_294_967_295)

    // Test ZigZag encoding for sint64
    XCTAssertEqual(BinarySerializer.zigzagEncode64(0), 0)
    XCTAssertEqual(BinarySerializer.zigzagEncode64(-1), 1)
    XCTAssertEqual(BinarySerializer.zigzagEncode64(1), 2)
    XCTAssertEqual(BinarySerializer.zigzagEncode64(-2), 3)
  }

  func testSerializeSint32Value() throws {
    var message = MessageDescriptor(name: "Sint32Message", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "value", number: 1, type: .sint32))
    fileDescriptor.addMessage(message)

    let dynamicMessage = try messageFactory.createMessage(from: message, with: ["value": Int32(-1)])
    let data = try serializer.serialize(dynamicMessage)

    XCTAssertEqual(data.count, 2)  // tag + zigzag encoded value
    XCTAssertEqual(data[0], 8)  // Tag: (1 << 3) | 0 = 8
    XCTAssertEqual(data[1], 1)  // ZigZag(-1) = 1
  }

  // MARK: - Error Handling Tests

  func testSerializationErrors() throws {
    var message = MessageDescriptor(name: "ErrorMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    fileDescriptor.addMessage(message)

    // Create empty message (without set fields)
    let emptyMessage = messageFactory.createMessage(from: message)

    // Empty message serialization should work (proto3 semantics)
    let data = try serializer.serialize(emptyMessage)
    XCTAssertEqual(data.count, 0)  // Empty fields are not serialized in proto3
  }

  func testSerializeUnsupportedFieldType() throws {
    var message = MessageDescriptor(name: "GroupMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "group_field", number: 1, type: .group))
    fileDescriptor.addMessage(message)

    // Create message and force set value through low-level API
    var dynamicMessage = messageFactory.createMessage(from: message)

    // For testing we will create message that passes hasValue check but causes encoding error

    // Simple way: create DynamicMessage for group field
    let groupMessage = messageFactory.createMessage(from: message)
    try dynamicMessage.set(groupMessage, forField: "group_field")

    // Group type is not supported in value encoding
    XCTAssertThrowsError(try serializer.serialize(dynamicMessage)) { error in
      if let serializationError = error as? SerializationError {
        if case .unsupportedFieldType(let type) = serializationError {
          XCTAssertEqual(type, "group")
        }
        else {
          XCTFail("Wrong error type: \(serializationError)")
        }
      }
      else {
        XCTFail("Expected SerializationError, got: \(error)")
      }
    }
  }

  func testSerializationErrorDescriptions() {
    let error1 = SerializationError.invalidFieldType(fieldName: "test", expectedType: "String", actualType: "Int")
    XCTAssertEqual(error1.description, "Invalid field type for field 'test': expected String, got Int")

    let error2 = SerializationError.valueTypeMismatch(expected: "String", actual: "Int")
    XCTAssertEqual(error2.description, "Value type mismatch: expected String, got Int")

    let error3 = SerializationError.missingMapEntryInfo(fieldName: "map_field")
    XCTAssertEqual(error3.description, "Missing map entry info for field 'map_field'")

    let error4 = SerializationError.missingFieldValue(fieldName: "missing_field")
    XCTAssertEqual(error4.description, "Missing value for field 'missing_field'")

    let error5 = SerializationError.unsupportedFieldType(type: "group")
    XCTAssertEqual(error5.description, "Unsupported field type: group")
  }

  func testSerializationErrorEquality() {
    let error1 = SerializationError.invalidFieldType(fieldName: "test", expectedType: "String", actualType: "Int")
    let error2 = SerializationError.invalidFieldType(fieldName: "test", expectedType: "String", actualType: "Int")
    let error3 = SerializationError.invalidFieldType(fieldName: "other", expectedType: "String", actualType: "Int")

    XCTAssertEqual(error1, error2)
    XCTAssertNotEqual(error1, error3)
  }

  // MARK: - Serialization Options Tests

  func testSerializationOptionsDefault() {
    let options = SerializationOptions()
    XCTAssertTrue(options.usePackedRepeated)
  }

  func testSerializationOptionsCustom() {
    let options = SerializationOptions(usePackedRepeated: false)
    XCTAssertFalse(options.usePackedRepeated)
  }

  func testBinarySerializerWithOptions() {
    let options = SerializationOptions(usePackedRepeated: false)
    let serializer = BinarySerializer(options: options)
    XCTAssertFalse(serializer.options.usePackedRepeated)
  }

  // MARK: - Edge Cases Tests

  func testSerializeMessageWithNoFields() throws {
    let message = MessageDescriptor(name: "EmptyMessage", parent: fileDescriptor)
    fileDescriptor.addMessage(message)

    let dynamicMessage = messageFactory.createMessage(from: message)
    let data = try serializer.serialize(dynamicMessage)

    // Message without fields should give empty data
    XCTAssertEqual(data.count, 0)
  }

  func testSerializeFieldWithMaxNumber() throws {
    var message = MessageDescriptor(name: "MaxFieldMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "max_field", number: 536_870_911, type: .int32))  // Maximum field number
    fileDescriptor.addMessage(message)

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "max_field": Int32(42)
      ]
    )

    let data = try serializer.serialize(dynamicMessage)

    // Should serialize without errors
    XCTAssertGreaterThan(data.count, 0)
  }

  func testSerializeLargeVarint() throws {
    var message = MessageDescriptor(name: "LargeMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "large_value", number: 1, type: .uint64))
    fileDescriptor.addMessage(message)

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "large_value": UInt64.max
      ]
    )

    let data = try serializer.serialize(dynamicMessage)

    // Maximum UInt64 value should encode in 10 byte varint + 1 byte tag
    XCTAssertGreaterThanOrEqual(data.count, 11)
  }

  // MARK: - Performance Tests

  func testSerializationPerformance() throws {
    // Create message with many fields for performance testing
    var message = MessageDescriptor(name: "PerformanceMessage", parent: fileDescriptor)

    for i in 1...100 {
      message.addField(FieldDescriptor(name: "field_\(i)", number: i, type: .int32))
    }

    fileDescriptor.addMessage(message)

    var values: [String: Any] = [:]
    for i in 1...100 {
      values["field_\(i)"] = Int32(i)
    }

    let dynamicMessage = try messageFactory.createMessage(from: message, with: values)

    measure {
      do {
        _ = try serializer.serialize(dynamicMessage)
      }
      catch {
        XCTFail("Serialization failed: \(error)")
      }
    }
  }
}
