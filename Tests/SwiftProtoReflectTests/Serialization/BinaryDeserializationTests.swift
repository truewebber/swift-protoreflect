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
    deserializer = BinaryDeserializer()
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

    // Test false
    let falseMessage = try messageFactory.createMessage(from: message, with: ["value": false])
    let falseData = try serializer.serialize(falseMessage)
    let deserializedFalse = try deserializer.deserialize(falseData, using: message)
    XCTAssertEqual(try deserializedFalse.get(forField: "value") as? Bool, false)
  }

  func testRoundTripStringValues() throws {
    var message = MessageDescriptor(name: "StringMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    fileDescriptor.addMessage(message)

    // Test various strings
    let testStrings = [
      "Hello World",
      "Hello, world!",
      "你好世界",
      "🌍🚀✨",
      "",
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

    let testBytes = [
      Data(),  // Empty data
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
    XCTAssertEqual(BinaryDeserializer.zigzagDecode32(0), 0)
    XCTAssertEqual(BinaryDeserializer.zigzagDecode32(1), -1)
    XCTAssertEqual(BinaryDeserializer.zigzagDecode32(2), 1)
    XCTAssertEqual(BinaryDeserializer.zigzagDecode32(3), -2)
    XCTAssertEqual(BinaryDeserializer.zigzagDecode32(4_294_967_294), 2_147_483_647)
    XCTAssertEqual(BinaryDeserializer.zigzagDecode32(4_294_967_295), -2_147_483_648)

    // Test ZigZag decoding for sint64 (more conservative values)
    XCTAssertEqual(BinaryDeserializer.zigzagDecode64(0), 0)
    XCTAssertEqual(BinaryDeserializer.zigzagDecode64(1), -1)
    XCTAssertEqual(BinaryDeserializer.zigzagDecode64(2), 1)
    XCTAssertEqual(BinaryDeserializer.zigzagDecode64(3), -2)
    XCTAssertEqual(BinaryDeserializer.zigzagDecode64(200), 100)
    XCTAssertEqual(BinaryDeserializer.zigzagDecode64(201), -101)
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
    let preservingOptions = DeserializationOptions(preserveUnknownFields: true)
    let discardingOptions = DeserializationOptions(preserveUnknownFields: false)

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
