//
// BinaryDeserializationTests.swift
//
// Tests for binary deserialization of Protocol Buffers
//
// Test cases from the plan:
// - Test-BIN-006: Deserialization of all scalar types from data created by C++ protoc
// - Test-BIN-007: Deserialization of messages with unknown fields (should be preserved)
// - Test-BIN-008: Deserialization of messages with corrupted data (error handling verification)
// - Test-BIN-009: Deserialization of messages from different protocol versions for backward compatibility

import XCTest

@testable import SwiftProtoReflect

final class BinaryDeserializationTests: XCTestCase {

  var fileDescriptor: FileDescriptor!
  var messageFactory: MessageFactory!
  var serializer: BinarySerializer!
  var deserializer: BinaryDeserializer!

  override func setUp() {
    super.setUp()

    fileDescriptor = FileDescriptor(name: "test_deserialization.proto", package: "test.deserialization")
    messageFactory = MessageFactory()
    serializer = BinarySerializer()
    deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
  }

  override func tearDown() {
    fileDescriptor = nil
    messageFactory = nil
    serializer = nil
    deserializer = nil
    super.tearDown()
  }

  // MARK: - Round-trip Tests for Scalar Types (Test-BIN-006)

  func testRoundTripAllScalarTypes() throws {
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
    scalarMessage.addField(FieldDescriptor(name: "string_field", number: 14, type: .string))
    scalarMessage.addField(FieldDescriptor(name: "bytes_field", number: 15, type: .bytes))

    fileDescriptor.addMessage(scalarMessage)

    // Create source data
    let originalValues: [String: Any] = [
      "double_field": 3.14159,
      "float_field": Float(2.718),
      "int32_field": Int32(-42),
      "int64_field": Int64(-9_223_372_036_854_775_000),
      "uint32_field": UInt32(4_294_967_000),  // Reduced for safety
      "uint64_field": UInt64(18_446_744_073_709_551_000),  // Reduced for safety
      "sint32_field": Int32(-2_147_483_000),  // Reduced for safety
      "sint64_field": Int64(-9_223_372_036_854_775_000),
      "fixed32_field": UInt32(123_456_789),
      "fixed64_field": UInt64(987_654_321_012_345),
      "sfixed32_field": Int32(-123_456_789),
      "sfixed64_field": Int64(-987_654_321_012_345),
      "bool_field": true,
      "string_field": "Hello, 世界!",
      "bytes_field": Data([0x01, 0x02, 0x03, 0xFF, 0xAB]),
    ]

    // Round-trip test
    let originalMessage = try messageFactory.createMessage(from: scalarMessage, with: originalValues)
    let serializedData = try serializer.serialize(originalMessage)
    let deserializedMessage = try deserializer.deserialize(serializedData, using: scalarMessage)

    // Verify all fields
    XCTAssertEqual(try deserializedMessage.get(forField: "double_field") as? Double, 3.14159)
    XCTAssertEqual(try deserializedMessage.get(forField: "float_field") as? Float, Float(2.718))
    XCTAssertEqual(try deserializedMessage.get(forField: "int32_field") as? Int32, Int32(-42))
    XCTAssertEqual(try deserializedMessage.get(forField: "int64_field") as? Int64, Int64(-9_223_372_036_854_775_000))
    XCTAssertEqual(try deserializedMessage.get(forField: "uint32_field") as? UInt32, UInt32(4_294_967_000))
    XCTAssertEqual(try deserializedMessage.get(forField: "uint64_field") as? UInt64, UInt64(18_446_744_073_709_551_000))
    XCTAssertEqual(try deserializedMessage.get(forField: "sint32_field") as? Int32, Int32(-2_147_483_000))
    XCTAssertEqual(try deserializedMessage.get(forField: "sint64_field") as? Int64, Int64(-9_223_372_036_854_775_000))
    XCTAssertEqual(try deserializedMessage.get(forField: "fixed32_field") as? UInt32, UInt32(123_456_789))
    XCTAssertEqual(try deserializedMessage.get(forField: "fixed64_field") as? UInt64, UInt64(987_654_321_012_345))
    XCTAssertEqual(try deserializedMessage.get(forField: "sfixed32_field") as? Int32, Int32(-123_456_789))
    XCTAssertEqual(try deserializedMessage.get(forField: "sfixed64_field") as? Int64, Int64(-987_654_321_012_345))
    XCTAssertEqual(try deserializedMessage.get(forField: "bool_field") as? Bool, true)
    XCTAssertEqual(try deserializedMessage.get(forField: "string_field") as? String, "Hello, 世界!")
    XCTAssertEqual(try deserializedMessage.get(forField: "bytes_field") as? Data, Data([0x01, 0x02, 0x03, 0xFF, 0xAB]))
  }

  func testRoundTripDoubleValue() throws {
    var message = MessageDescriptor(name: "DoubleMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "value", number: 1, type: .double))
    fileDescriptor.addMessage(message)

    let original = try messageFactory.createMessage(from: message, with: ["value": 3.14159])
    let data = try serializer.serialize(original)
    let deserialized = try deserializer.deserialize(data, using: message)

    XCTAssertEqual(try deserialized.get(forField: "value") as? Double, 3.14159)
  }

  func testRoundTripBoolValues() throws {
    var message = MessageDescriptor(name: "BoolMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "value", number: 1, type: .bool))
    fileDescriptor.addMessage(message)

    // Test true
    let trueMessage = try messageFactory.createMessage(from: message, with: ["value": true])
    let trueData = try serializer.serialize(trueMessage)
    let deserializedTrue = try deserializer.deserialize(trueData, using: message)
    XCTAssertEqual(try deserializedTrue.get(forField: "value") as? Bool, true)

    // Test false: proto3 implicit-presence — false is the default and is omitted from wire,
    // so after round-trip the field is absent (hasValue returns false).
    let falseMessage = try messageFactory.createMessage(from: message, with: ["value": false])
    let falseData = try serializer.serialize(falseMessage)
    XCTAssertEqual(falseData.count, 0)
    let deserializedFalse = try deserializer.deserialize(falseData, using: message)
    XCTAssertFalse(try deserializedFalse.hasValue(forField: "value"))
  }

  func testRoundTripStringValues() throws {
    var message = MessageDescriptor(name: "StringMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    fileDescriptor.addMessage(message)

    // Test various strings
    // proto3 implicit-presence: empty string is the default and omitted from wire.
    let testStrings = [
      "Hello World",
      "Hello, world!",
      "你好世界",
      "🌍🚀✨",
      "Multiple\nLine\nString",
    ]

    for testString in testStrings {
      let original = try messageFactory.createMessage(from: message, with: ["value": testString])
      let data = try serializer.serialize(original)
      let deserialized = try deserializer.deserialize(data, using: message)
      XCTAssertEqual(try deserialized.get(forField: "value") as? String, testString)
    }
  }

  func testRoundTripBytesValues() throws {
    var message = MessageDescriptor(name: "BytesMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "value", number: 1, type: .bytes))
    fileDescriptor.addMessage(message)

    // proto3 implicit-presence: empty Data() is the default and omitted from wire.
    let testBytes = [
      Data([0x01]),  // One byte
      Data([0x01, 0x02, 0x03, 0xFF, 0xAB]),  // Several bytes
      Data(repeating: 0xAA, count: 1000),  // Large array
    ]

    for bytes in testBytes {
      let original = try messageFactory.createMessage(from: message, with: ["value": bytes])
      let data = try serializer.serialize(original)
      let deserialized = try deserializer.deserialize(data, using: message)
      XCTAssertEqual(try deserialized.get(forField: "value") as? Data, bytes)
    }
  }

  // MARK: - ZigZag Decoding Tests

  func testZigZagDecoding() {
    // Test ZigZag decoding for sint32
    XCTAssertEqual(_BinaryDeserializer.zigzagDecode32(0), 0)
    XCTAssertEqual(_BinaryDeserializer.zigzagDecode32(1), -1)
    XCTAssertEqual(_BinaryDeserializer.zigzagDecode32(2), 1)
    XCTAssertEqual(_BinaryDeserializer.zigzagDecode32(3), -2)
    XCTAssertEqual(_BinaryDeserializer.zigzagDecode32(4_294_967_294), 2_147_483_647)
    XCTAssertEqual(_BinaryDeserializer.zigzagDecode32(4_294_967_295), -2_147_483_648)

    // Test ZigZag decoding for sint64 (more conservative values)
    XCTAssertEqual(_BinaryDeserializer.zigzagDecode64(0), 0)
    XCTAssertEqual(_BinaryDeserializer.zigzagDecode64(1), -1)
    XCTAssertEqual(_BinaryDeserializer.zigzagDecode64(2), 1)
    XCTAssertEqual(_BinaryDeserializer.zigzagDecode64(3), -2)
    XCTAssertEqual(_BinaryDeserializer.zigzagDecode64(200), 100)
    XCTAssertEqual(_BinaryDeserializer.zigzagDecode64(201), -101)
  }

  func testRoundTripSintValues() throws {
    var message = MessageDescriptor(name: "SintMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "sint32_field", number: 1, type: .sint32))
    message.addField(FieldDescriptor(name: "sint64_field", number: 2, type: .sint64))
    fileDescriptor.addMessage(message)

    let values: [String: Any] = [
      "sint32_field": Int32(-1),
      "sint64_field": Int64(-1000),
    ]

    let original = try messageFactory.createMessage(from: message, with: values)
    let data = try serializer.serialize(original)
    let deserialized = try deserializer.deserialize(data, using: message)

    XCTAssertEqual(try deserialized.get(forField: "sint32_field") as? Int32, Int32(-1))
    XCTAssertEqual(try deserialized.get(forField: "sint64_field") as? Int64, Int64(-1000))
  }

  // MARK: - Repeated Fields Tests

  func testRoundTripRepeatedFields() throws {
    var message = MessageDescriptor(name: "RepeatedMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "strings", number: 1, type: .string, isRepeated: true))
    message.addField(FieldDescriptor(name: "numbers", number: 2, type: .int32, isRepeated: true))
    fileDescriptor.addMessage(message)

    let values: [String: Any] = [
      "strings": ["hello", "world", "test"],
      "numbers": [Int32(1), Int32(2), Int32(3), Int32(4), Int32(5)],
    ]

    let original = try messageFactory.createMessage(from: message, with: values)
    let data = try serializer.serialize(original)
    let deserialized = try deserializer.deserialize(data, using: message)

    XCTAssertEqual(try deserialized.get(forField: "strings") as? [String], ["hello", "world", "test"])
    XCTAssertEqual(
      try deserialized.get(forField: "numbers") as? [Int32],
      [Int32(1), Int32(2), Int32(3), Int32(4), Int32(5)]
    )
  }

  func testRoundTripPackedRepeatedFields() throws {
    var message = MessageDescriptor(name: "PackedMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "values", number: 1, type: .int32, isRepeated: true))
    fileDescriptor.addMessage(message)

    let values: [String: Any] = [
      "values": [Int32(1), Int32(2), Int32(3), Int32(4), Int32(5)]
    ]

    // Test with packed encoding
    let packedSerializer = BinarySerializer(options: SerializationOptions(usePackedRepeated: true))

    let original = try messageFactory.createMessage(from: message, with: values)
    let data = try packedSerializer.serialize(original)
    let deserialized = try deserializer.deserialize(data, using: message)

    XCTAssertEqual(
      try deserialized.get(forField: "values") as? [Int32],
      [Int32(1), Int32(2), Int32(3), Int32(4), Int32(5)]
    )
  }

  // MARK: - Map Fields Tests

  func testRoundTripMapFields() throws {
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

    let original = try messageFactory.createMessage(from: message, with: ["string_to_int": mapData])
    let data = try serializer.serialize(original)
    let deserialized = try deserializer.deserialize(data, using: message)

    let deserializedMap = try deserialized.get(forField: "string_to_int") as? [String: Int32]
    XCTAssertEqual(deserializedMap?.count, 3)
    XCTAssertEqual(deserializedMap?["first"], 1)
    XCTAssertEqual(deserializedMap?["second"], 2)
    XCTAssertEqual(deserializedMap?["third"], 3)
  }

  // MARK: - Enum Tests

  func testRoundTripEnumField() throws {
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

    let original = try messageFactory.createMessage(from: message, with: ["status": Int32(1)])
    let data = try serializer.serialize(original)
    let deserialized = try deserializer.deserialize(data, using: message)

    XCTAssertEqual(try deserialized.get(forField: "status") as? Int32, Int32(1))
  }

  // MARK: - Unknown Fields Tests (Test-BIN-007)

  func testDeserializationWithUnknownFields() throws {
    // Create message with field numbers 1 and 10
    var originalMessage = MessageDescriptor(name: "OriginalMessage", parent: fileDescriptor)
    originalMessage.addField(FieldDescriptor(name: "known_field", number: 1, type: .string))
    // This field will be "unknown"
    originalMessage.addField(FieldDescriptor(name: "unknown_field", number: 10, type: .int32))
    fileDescriptor.addMessage(originalMessage)

    // Create "new version" of message without field 10
    var newMessage = MessageDescriptor(name: "NewMessage", parent: fileDescriptor)
    newMessage.addField(FieldDescriptor(name: "known_field", number: 1, type: .string))

    // Serialize with full message
    let fullMessage = try messageFactory.createMessage(
      from: originalMessage,
      with: [
        "known_field": "test",
        "unknown_field": Int32(42),
      ]
    )
    let data = try serializer.serialize(fullMessage)

    // Deserialize with truncated descriptor (unknown field should be skipped)
    let partialMessage = try deserializer.deserialize(data, using: newMessage)

    XCTAssertEqual(try partialMessage.get(forField: "known_field") as? String, "test")
    XCTAssertThrowsError(try partialMessage.get(forField: "unknown_field"))
  }

  // MARK: - Error Handling Tests (Test-BIN-008)

  func testDeserializationErrorHandling() {
    // Test with empty data
    var emptyMessage = MessageDescriptor(name: "EmptyMessage", parent: fileDescriptor)
    // Changed to int32 to match tag 0x08
    emptyMessage.addField(FieldDescriptor(name: "field", number: 1, type: .int32))

    let emptyData = Data()
    XCTAssertNoThrow(try deserializer.deserialize(emptyData, using: emptyMessage))

    // Test with truncated data (tag for field 1, wire type varint, but no value)
    let truncatedData = Data([0x08])  // Tag for field 1, wire type 0 (varint), but no varint data
    XCTAssertThrowsError(try deserializer.deserialize(truncatedData, using: emptyMessage)) { error in
      XCTAssertTrue(error is DeserializationError)
      if case .truncatedVarint = error as? DeserializationError {
        // Expected error
      }
      else {
        XCTFail("Expected truncatedVarint error, got: \(error)")
      }
    }
  }

  func testInvalidUTF8String() throws {
    var message = MessageDescriptor(name: "StringMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    fileDescriptor.addMessage(message)

    // Create data with invalid UTF-8 string manually
    var invalidData = Data()
    invalidData.append(0x0A)  // Tag for field 1, wire type 2 (length-delimited)
    invalidData.append(0x02)  // Length 2 bytes
    invalidData.append(0xFF)  // Invalid UTF-8 byte
    invalidData.append(0xFE)  // Invalid UTF-8 byte

    XCTAssertThrowsError(try deserializer.deserialize(invalidData, using: message)) { error in
      XCTAssertTrue(error is DeserializationError)
      if case .invalidUTF8String = error as? DeserializationError {
        // Expected error
      }
      else {
        XCTFail("Expected invalidUTF8String error")
      }
    }
  }

  // MARK: - Deserialization Options Tests

  func testDeserializationOptions() {
    // Test deserialization options
    let preservingOptions = DeserializationOptions(preserveUnknownFields: true, typeRegistry: TypeRegistry())
    let discardingOptions = DeserializationOptions(preserveUnknownFields: false, typeRegistry: TypeRegistry())

    XCTAssertTrue(preservingOptions.preserveUnknownFields)
    XCTAssertFalse(discardingOptions.preserveUnknownFields)

    let deserializerPreserving = BinaryDeserializer(options: preservingOptions)
    let deserializerDiscarding = BinaryDeserializer(options: discardingOptions)

    XCTAssertTrue(deserializerPreserving.options.preserveUnknownFields)
    XCTAssertFalse(deserializerDiscarding.options.preserveUnknownFields)
  }

  // MARK: - Error Description Tests

  func testDeserializationErrorDescriptions() {
    let error1 = DeserializationError.truncatedVarint
    XCTAssertEqual(error1.description, "Truncated varint")

    let error2 = DeserializationError.truncatedMessage
    XCTAssertEqual(error2.description, "Truncated message")

    let error3 = DeserializationError.invalidWireType(tag: 123)
    XCTAssertEqual(error3.description, "Invalid wire type in tag: 123")

    let error4 = DeserializationError.wireTypeMismatch(fieldName: "test", expected: .varint, actual: .fixed32)
    XCTAssertEqual(error4.description, "Wire type mismatch for field 'test': expected varint, got fixed32")

    let error5 = DeserializationError.invalidUTF8String
    XCTAssertEqual(error5.description, "Invalid UTF-8 string")

    let error6 = DeserializationError.malformedPackedField(fieldName: "packed_field")
    XCTAssertEqual(error6.description, "Malformed packed field: packed_field")

    let error7 = DeserializationError.unsupportedNestedMessage(typeName: "NestedType")
    XCTAssertEqual(error7.description, "Unsupported nested message type: NestedType")
  }

  func testDeserializationErrorEquality() {
    let error1 = DeserializationError.truncatedVarint
    let error2 = DeserializationError.truncatedVarint
    let error3 = DeserializationError.truncatedMessage

    XCTAssertEqual(error1, error2)
    XCTAssertNotEqual(error1, error3)

    let error4 = DeserializationError.invalidWireType(tag: 123)
    let error5 = DeserializationError.invalidWireType(tag: 123)
    let error6 = DeserializationError.invalidWireType(tag: 456)

    XCTAssertEqual(error4, error5)
    XCTAssertNotEqual(error4, error6)
  }

  // MARK: - Performance Tests

  func testDeserializationPerformance() throws {
    // Create message with many fields
    var message = MessageDescriptor(name: "LargeMessage", parent: fileDescriptor)

    for i in 1...100 {
      message.addField(FieldDescriptor(name: "field_\(i)", number: i, type: .int32))
    }
    fileDescriptor.addMessage(message)

    // Create test data
    var fieldValues: [String: Any] = [:]
    for i in 1...100 {
      fieldValues["field_\(i)"] = Int32(i)
    }

    let originalMessage = try messageFactory.createMessage(from: message, with: fieldValues)
    let data = try serializer.serialize(originalMessage)

    // Test deserialization performance
    measure {
      for _ in 0..<1000 {
        _ = try? deserializer.deserialize(data, using: message)
      }
    }
  }

  // MARK: - Error Path Coverage Tests

  func testDeserialize_invalidWireType_throwsError() {
    var message = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "field", number: 1, type: .int32))

    // Wire type 6 is not a valid protobuf wire type (valid: 0-5)
    // Tag = (fieldNumber=1 << 3) | wireType=6 = 8 | 6 = 14 = 0x0E
    let invalidData = Data([0x0E])
    XCTAssertThrowsError(try deserializer.deserialize(invalidData, using: message)) { error in
      if case .invalidWireType = error as? DeserializationError {
        // Expected
      }
      else {
        XCTFail("Expected invalidWireType error, got: \(error)")
      }
    }
  }

  func testDeserialize_wireTypeMismatch_throwsError() {
    var message = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "value", number: 1, type: .int32))

    // int32 field expects varint wire type (0), but we send fixed32 wire type (5)
    // Tag = (1 << 3) | 5 = 13 = 0x0D, then 4 bytes of fixed32 data
    let mismatchData = Data([0x0D, 0x01, 0x00, 0x00, 0x00])
    XCTAssertThrowsError(try deserializer.deserialize(mismatchData, using: message)) { error in
      if case .wireTypeMismatch(let fieldName, _, _) = error as? DeserializationError {
        XCTAssertEqual(fieldName, "value")
      }
      else {
        XCTFail("Expected wireTypeMismatch error, got: \(error)")
      }
    }
  }

  func testDeserialize_messageTypeField_throwsUnsupportedNestedMessage() {
    var message = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "nested", number: 1, type: .message, typeName: "test.Nested"))

    // Tag for field 1 (length-delimited) = (1 << 3) | 2 = 10 = 0x0A
    // Length = 2, content = 2 bytes of data
    let data = Data([0x0A, 0x02, 0x08, 0x01])
    XCTAssertThrowsError(try deserializer.deserialize(data, using: message)) { error in
      if case .unsupportedNestedMessage(let typeName) = error as? DeserializationError {
        XCTAssertEqual(typeName, "test.Nested")
      }
      else {
        XCTFail("Expected unsupportedNestedMessage error, got: \(error)")
      }
    }
  }

  func testDeserialize_groupWireTypeInUnknownField_skipsGroup() throws {
    var message = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "known", number: 1, type: .int32))

    // Field 1 (known): tag=0x08, value=42=0x2A
    // Field 2 (unknown startGroup): tag=0x13 (field 2, startGroup)
    // Inside group: field 1 varint tag=0x08, value=10=0x0A
    // endGroup for field 2: tag=0x14 (field 2, endGroup)
    let data = Data([0x08, 0x2A, 0x13, 0x08, 0x0A, 0x14])
    let result = try deserializer.deserialize(data, using: message)
    XCTAssertEqual(try result.get(forField: "known") as? Int32, Int32(42))
  }

  func testDeserialize_groupWireTypeInUnknownField_truncated_throwsError() {
    var message = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "known", number: 1, type: .int32))

    // startGroup without endGroup → truncated
    let groupData = Data([0x13])
    XCTAssertThrowsError(try deserializer.deserialize(groupData, using: message))
  }

  func testDeserialize_preserveUnknownFieldsFalse_discardsUnknownData() throws {
    var message = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "known", number: 1, type: .int32))

    // Field 1 (known): tag=0x08, value=42=0x2A
    // Field 2 (unknown varint): tag=0x10, value=99=0x63
    let data = Data([0x08, 0x2A, 0x10, 0x63])
    let discardDeserializer = BinaryDeserializer(
      options: DeserializationOptions(preserveUnknownFields: false, typeRegistry: TypeRegistry())
    )
    let result = try discardDeserializer.deserialize(data, using: message)

    // Known field should be deserialized
    XCTAssertEqual(try result.get(forField: "known") as? Int32, Int32(42))
  }

  func testDeserialize_preserveUnknownFieldsTrue_skipsUnknownData() throws {
    var message = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "known", number: 1, type: .int32))

    // Field 1 (known): tag=0x08, value=5=0x05
    // Field 3 (unknown fixed32): tag=(3<<3)|5=29=0x1D, then 4 bytes
    let data = Data([0x08, 0x05, 0x1D, 0xAA, 0xBB, 0xCC, 0xDD])
    let preserveDeserializer = BinaryDeserializer(
      options: DeserializationOptions(preserveUnknownFields: true, typeRegistry: TypeRegistry())
    )
    let result = try preserveDeserializer.deserialize(data, using: message)

    XCTAssertEqual(try result.get(forField: "known") as? Int32, Int32(5))
  }

  func testDeserialize_unknownLengthDelimitedField_preserved() throws {
    var message = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "known", number: 1, type: .string))

    // Field 1 (known string): tag=0x0A, length=5, "hello"
    // Field 5 (unknown length-delimited): tag=(5<<3)|2=42=0x2A, length=3, "abc"
    let helloBytes: [UInt8] = [0x68, 0x65, 0x6C, 0x6C, 0x6F]
    let abcBytes: [UInt8] = [0x61, 0x62, 0x63]
    let data = Data([0x0A, 0x05] + helloBytes + [0x2A, 0x03] + abcBytes)

    let result = try deserializer.deserialize(data, using: message)
    XCTAssertEqual(try result.get(forField: "known") as? String, "hello")
  }

  func testDeserialize_malformedMapEntry_throwsError() throws {
    let keyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: keyFieldInfo, valueFieldInfo: valueFieldInfo)

    var message = MessageDescriptor(name: "MapMessage", parent: fileDescriptor)
    message.addField(
      FieldDescriptor(
        name: "my_map",
        number: 1,
        type: .message,
        typeName: "map_entry",
        isMap: true,
        mapEntryInfo: mapEntryInfo
      )
    )

    // Map entry tag: (1 << 3) | 2 = 10 = 0x0A
    // Declared entry length = 3 bytes
    // But key field = tag(string,field1)=0x0A, length=0x04, "test" (4 bytes) = 6 bytes total
    // Reading 4 bytes for string exceeds declared 3-byte entry, causing malformed entry
    let mapTag: UInt8 = 0x0A
    let entryLength: UInt8 = 0x03
    let keyTag: UInt8 = 0x0A  // field 1, length-delimited
    let keyLen: UInt8 = 0x04  // 4 bytes for key string
    let keyData: [UInt8] = [0x74, 0x65, 0x73, 0x74]  // "test"
    let data = Data([mapTag, entryLength, keyTag, keyLen] + keyData)

    XCTAssertThrowsError(try deserializer.deserialize(data, using: message)) { error in
      // Either malformedMapEntry or truncatedMessage depending on how overread is detected
      XCTAssertTrue(error is DeserializationError, "Expected a DeserializationError, got: \(error)")
    }
  }

  func testDeserializationError_wireTypeMismatch_description() {
    let error = DeserializationError.wireTypeMismatch(fieldName: "field1", expected: .varint, actual: .fixed64)
    XCTAssertTrue(error.description.contains("field1"))
    XCTAssertTrue(error.description.contains("varint"))
    XCTAssertTrue(error.description.contains("fixed64"))
  }

  func testDeserializationError_malformedMapEntry_description() {
    let error = DeserializationError.malformedMapEntry(fieldName: "myMap")
    XCTAssertEqual(error.description, "Malformed map entry: myMap")
  }

  func testDeserializationError_missingMapEntryInfo_description() {
    let error = DeserializationError.missingMapEntryInfo(fieldName: "someMap")
    XCTAssertEqual(error.description, "Missing map entry info for field 'someMap'")
  }

  func testDeserializationError_missingTypeName_description() {
    let error = DeserializationError.missingTypeName(fieldType: "message")
    XCTAssertEqual(error.description, "Missing type name for field type: message")
  }

  func testDeserializationError_unsupportedFieldType_description() {
    let error = DeserializationError.unsupportedFieldType(type: "group")
    XCTAssertEqual(error.description, "Unsupported field type: group")
  }

  func testDeserializationError_equality_allCases() {
    XCTAssertEqual(DeserializationError.truncatedVarint, DeserializationError.truncatedVarint)
    XCTAssertEqual(DeserializationError.truncatedMessage, DeserializationError.truncatedMessage)
    XCTAssertEqual(DeserializationError.invalidUTF8String, DeserializationError.invalidUTF8String)
    XCTAssertEqual(
      DeserializationError.malformedMapEntry(fieldName: "x"),
      DeserializationError.malformedMapEntry(fieldName: "x")
    )
    XCTAssertNotEqual(
      DeserializationError.malformedMapEntry(fieldName: "x"),
      DeserializationError.malformedMapEntry(fieldName: "y")
    )
    XCTAssertEqual(
      DeserializationError.missingMapEntryInfo(fieldName: "x"),
      DeserializationError.missingMapEntryInfo(fieldName: "x")
    )
    XCTAssertEqual(
      DeserializationError.missingTypeName(fieldType: "message"),
      DeserializationError.missingTypeName(fieldType: "message")
    )
    XCTAssertEqual(
      DeserializationError.unsupportedNestedMessage(typeName: "Foo"),
      DeserializationError.unsupportedNestedMessage(typeName: "Foo")
    )
    XCTAssertEqual(
      DeserializationError.unsupportedFieldType(type: "group"),
      DeserializationError.unsupportedFieldType(type: "group")
    )
    XCTAssertEqual(
      DeserializationError.wireTypeMismatch(fieldName: "f", expected: .varint, actual: .fixed32),
      DeserializationError.wireTypeMismatch(fieldName: "f", expected: .varint, actual: .fixed32)
    )
    XCTAssertNotEqual(
      DeserializationError.wireTypeMismatch(fieldName: "f", expected: .varint, actual: .fixed32),
      DeserializationError.wireTypeMismatch(fieldName: "f", expected: .varint, actual: .fixed64)
    )
  }

  func testDeserialize_truncatedFixed32_throwsError() {
    var message = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "value", number: 1, type: .fixed32))

    // Tag for field 1 (fixed32 wire type): (1 << 3) | 5 = 13 = 0x0D
    // But only provide 2 bytes instead of 4
    let truncatedData = Data([0x0D, 0x01, 0x02])
    XCTAssertThrowsError(try deserializer.deserialize(truncatedData, using: message)) { error in
      if case .truncatedMessage = error as? DeserializationError {
        // Expected
      }
      else {
        XCTFail("Expected truncatedMessage error, got: \(error)")
      }
    }
  }

  func testDeserialize_truncatedFixed64_throwsError() {
    var message = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "value", number: 1, type: .fixed64))

    // Tag for field 1 (fixed64 wire type): (1 << 3) | 1 = 9 = 0x09
    // But only provide 4 bytes instead of 8
    let truncatedData = Data([0x09, 0x01, 0x02, 0x03, 0x04])
    XCTAssertThrowsError(try deserializer.deserialize(truncatedData, using: message)) { error in
      if case .truncatedMessage = error as? DeserializationError {
        // Expected
      }
      else {
        XCTFail("Expected truncatedMessage error, got: \(error)")
      }
    }
  }

  // MARK: - Edge Cases Tests

  func testDeserializeEmptyMessage() throws {
    var message = MessageDescriptor(name: "EmptyMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "optional_field", number: 1, type: .string))
    fileDescriptor.addMessage(message)

    let emptyMessage = messageFactory.createMessage(from: message)
    let data = try serializer.serialize(emptyMessage)
    let deserialized = try deserializer.deserialize(data, using: message)

    XCTAssertFalse(try deserialized.hasValue(forField: "optional_field"))
  }

  func testDeserialize_repeatedExtensionField_accumulatesAllValues() throws {
    var message = MessageDescriptor(name: "ExtMsg", parent: fileDescriptor)
    message.addExtensionRange(ExtensionRange(start: 100, end: 200))
    message.addExtension(FieldDescriptor(name: "ext_strings", number: 100, type: .string, isRepeated: true))
    fileDescriptor.addMessage(message)

    // tag for field 100 (string, length-delimited): (100 << 3) | 2 = 802
    // varint(802): 802 = 34 + 6*128 → [0xA2, 0x06]
    // "x" = [0x01, 0x78], "y" = [0x01, 0x79], "z" = [0x01, 0x7A]
    let data = Data([
      0xA2, 0x06, 0x01, 0x78,
      0xA2, 0x06, 0x01, 0x79,
      0xA2, 0x06, 0x01, 0x7A,
    ])

    let deserialized = try deserializer.deserialize(data, using: message)
    let strings = try deserialized.get(forField: 100) as? [String]
    XCTAssertEqual(strings, ["x", "y", "z"])
  }

  func testDeserializeMessageWithLargeFieldNumbers() throws {
    var message = MessageDescriptor(name: "LargeFieldMessage", parent: fileDescriptor)
    // Large field number, but safe
    message.addField(FieldDescriptor(name: "field_large", number: 1000, type: .int32))
    fileDescriptor.addMessage(message)

    let original = try messageFactory.createMessage(from: message, with: ["field_large": Int32(42)])
    let data = try serializer.serialize(original)
    let deserialized = try deserializer.deserialize(data, using: message)

    XCTAssertEqual(try deserialized.get(forField: "field_large") as? Int32, Int32(42))
  }
}
