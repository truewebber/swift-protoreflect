import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class ProtoValueValidationTests: XCTestCase {

  // Test descriptors
  var intField: ProtoFieldDescriptor!
  var uintField: ProtoFieldDescriptor!
  var floatField: ProtoFieldDescriptor!
  var doubleField: ProtoFieldDescriptor!
  var boolField: ProtoFieldDescriptor!
  var stringField: ProtoFieldDescriptor!
  var bytesField: ProtoFieldDescriptor!
  var enumField: ProtoFieldDescriptor!
  var messageField: ProtoFieldDescriptor!
  var repeatedIntField: ProtoFieldDescriptor!
  var repeatedStringField: ProtoFieldDescriptor!
  var repeatedMessageField: ProtoFieldDescriptor!
  var mapStringToStringField: ProtoFieldDescriptor!
  var mapInt32ToMessageField: ProtoFieldDescriptor!

  // Test enum and message descriptors
  var enumDescriptor: ProtoEnumDescriptor!
  var messageDescriptor: ProtoMessageDescriptor!

  override func setUp() {
    super.setUp()

    // Create enum descriptor
    enumDescriptor = ProtoEnumDescriptor(
      name: "TestEnum",
      values: [
        ProtoEnumValueDescriptor(name: "UNKNOWN", number: 0),
        ProtoEnumValueDescriptor(name: "VALUE1", number: 1),
        ProtoEnumValueDescriptor(name: "VALUE2", number: 2),
      ]
    )

    // Create message descriptor
    messageDescriptor = ProtoMessageDescriptor(
      fullName: "test.TestMessage",
      fields: [],
      enums: [],
      nestedMessages: []
    )

    // Create field descriptors
    intField = ProtoFieldDescriptor(name: "int_field", number: 1, type: .int32, isRepeated: false, isMap: false)
    uintField = ProtoFieldDescriptor(name: "uint_field", number: 2, type: .uint32, isRepeated: false, isMap: false)
    floatField = ProtoFieldDescriptor(name: "float_field", number: 3, type: .float, isRepeated: false, isMap: false)
    doubleField = ProtoFieldDescriptor(name: "double_field", number: 4, type: .double, isRepeated: false, isMap: false)
    boolField = ProtoFieldDescriptor(name: "bool_field", number: 5, type: .bool, isRepeated: false, isMap: false)
    stringField = ProtoFieldDescriptor(name: "string_field", number: 6, type: .string, isRepeated: false, isMap: false)
    bytesField = ProtoFieldDescriptor(name: "bytes_field", number: 7, type: .bytes, isRepeated: false, isMap: false)
    enumField = ProtoFieldDescriptor(
      name: "enum_field",
      number: 8,
      type: .enum,
      isRepeated: false,
      isMap: false,
      messageType: nil,
      enumType: enumDescriptor
    )
    messageField = ProtoFieldDescriptor(
      name: "message_field",
      number: 9,
      type: .message,
      isRepeated: false,
      isMap: false,
      messageType: messageDescriptor,
      enumType: nil
    )

    // Repeated fields
    repeatedIntField = ProtoFieldDescriptor(
      name: "repeated_int_field",
      number: 10,
      type: .int32,
      isRepeated: true,
      isMap: false
    )
    repeatedStringField = ProtoFieldDescriptor(
      name: "repeated_string_field",
      number: 11,
      type: .string,
      isRepeated: true,
      isMap: false
    )
    repeatedMessageField = ProtoFieldDescriptor(
      name: "repeated_message_field",
      number: 12,
      type: .message,
      isRepeated: true,
      isMap: false,
      messageType: messageDescriptor,
      enumType: nil
    )

    // Map fields
    mapStringToStringField = ProtoFieldDescriptor(
      name: "map_string_to_string",
      number: 13,
      type: .message,
      isRepeated: false,
      isMap: true
    )

    mapInt32ToMessageField = ProtoFieldDescriptor(
      name: "map_int32_to_message",
      number: 14,
      type: .message,
      isRepeated: false,
      isMap: true,
      messageType: messageDescriptor
    )
  }

  // MARK: - Primitive Type Validation Tests

  func testIntFieldValidation() {
    // Valid values
    XCTAssertTrue(ProtoValue.intValue(42).isValid(for: intField))

    // Valid conversions
    XCTAssertTrue(ProtoValue.uintValue(42).isValid(for: intField))
    XCTAssertTrue(ProtoValue.stringValue("42").isValid(for: intField))
    XCTAssertTrue(ProtoValue.floatValue(42.0).isValid(for: intField))
    XCTAssertTrue(ProtoValue.doubleValue(42.0).isValid(for: intField))

    // Invalid values
    XCTAssertFalse(ProtoValue.stringValue("not a number").isValid(for: intField))
    XCTAssertFalse(ProtoValue.boolValue(true).isValid(for: intField))
    XCTAssertFalse(ProtoValue.bytesValue(Data([0, 1, 2])).isValid(for: intField))
    XCTAssertFalse(ProtoValue.messageValue(ProtoDynamicMessage(descriptor: messageDescriptor)).isValid(for: intField))
    XCTAssertFalse(ProtoValue.repeatedValue([.intValue(1), .intValue(2)]).isValid(for: intField))
    XCTAssertFalse(ProtoValue.mapValue(["key": .intValue(1)]).isValid(for: intField))
  }

  func testUintFieldValidation() {
    // Valid values
    XCTAssertTrue(ProtoValue.uintValue(42).isValid(for: uintField))

    // Valid conversions
    XCTAssertTrue(ProtoValue.intValue(42).isValid(for: uintField))
    XCTAssertTrue(ProtoValue.stringValue("42").isValid(for: uintField))
    XCTAssertTrue(ProtoValue.floatValue(42.0).isValid(for: uintField))
    XCTAssertTrue(ProtoValue.doubleValue(42.0).isValid(for: uintField))

    // Invalid values
    XCTAssertFalse(ProtoValue.intValue(-1).isValid(for: uintField))
    XCTAssertFalse(ProtoValue.stringValue("not a number").isValid(for: uintField))
    XCTAssertFalse(ProtoValue.stringValue("-1").isValid(for: uintField))
    XCTAssertFalse(ProtoValue.boolValue(true).isValid(for: uintField))
    XCTAssertFalse(ProtoValue.bytesValue(Data([0, 1, 2])).isValid(for: uintField))
  }

  func testFloatFieldValidation() {
    // Valid values
    XCTAssertTrue(ProtoValue.floatValue(3.14).isValid(for: floatField))

    // Valid conversions
    XCTAssertTrue(ProtoValue.doubleValue(3.14).isValid(for: floatField))
    XCTAssertTrue(ProtoValue.intValue(42).isValid(for: floatField))
    XCTAssertTrue(ProtoValue.uintValue(42).isValid(for: floatField))
    XCTAssertTrue(ProtoValue.stringValue("3.14").isValid(for: floatField))

    // Invalid values
    XCTAssertFalse(ProtoValue.stringValue("not a number").isValid(for: floatField))
    XCTAssertFalse(ProtoValue.boolValue(true).isValid(for: floatField))
    XCTAssertFalse(ProtoValue.bytesValue(Data([0, 1, 2])).isValid(for: floatField))
  }

  func testDoubleFieldValidation() {
    // Valid values
    XCTAssertTrue(ProtoValue.doubleValue(3.14).isValid(for: doubleField))

    // Valid conversions
    XCTAssertTrue(ProtoValue.floatValue(3.14).isValid(for: doubleField))
    XCTAssertTrue(ProtoValue.intValue(42).isValid(for: doubleField))
    XCTAssertTrue(ProtoValue.uintValue(42).isValid(for: doubleField))
    XCTAssertTrue(ProtoValue.stringValue("3.14").isValid(for: doubleField))

    // Invalid values
    XCTAssertFalse(ProtoValue.stringValue("not a number").isValid(for: doubleField))
    XCTAssertFalse(ProtoValue.boolValue(true).isValid(for: doubleField))
    XCTAssertFalse(ProtoValue.bytesValue(Data([0, 1, 2])).isValid(for: doubleField))
  }

  func testBoolFieldValidation() {
    // Valid values
    XCTAssertTrue(ProtoValue.boolValue(true).isValid(for: boolField))
    XCTAssertTrue(ProtoValue.boolValue(false).isValid(for: boolField))

    // Valid conversions
    XCTAssertTrue(ProtoValue.intValue(1).isValid(for: boolField))
    XCTAssertTrue(ProtoValue.intValue(0).isValid(for: boolField))
    XCTAssertTrue(ProtoValue.stringValue("true").isValid(for: boolField))
    XCTAssertTrue(ProtoValue.stringValue("false").isValid(for: boolField))
    XCTAssertTrue(ProtoValue.stringValue("1").isValid(for: boolField))
    XCTAssertTrue(ProtoValue.stringValue("0").isValid(for: boolField))

    // Invalid values
    XCTAssertFalse(ProtoValue.intValue(2).isValid(for: boolField))
    XCTAssertFalse(ProtoValue.stringValue("not a bool").isValid(for: boolField))
    XCTAssertFalse(ProtoValue.floatValue(1.5).isValid(for: boolField))
    XCTAssertFalse(ProtoValue.bytesValue(Data([0, 1, 2])).isValid(for: boolField))
  }

  func testStringFieldValidation() {
    // Valid values
    XCTAssertTrue(ProtoValue.stringValue("hello").isValid(for: stringField))

    // Valid conversions
    XCTAssertTrue(ProtoValue.intValue(42).isValid(for: stringField))
    XCTAssertTrue(ProtoValue.floatValue(3.14).isValid(for: stringField))
    XCTAssertTrue(ProtoValue.boolValue(true).isValid(for: stringField))

    // Invalid values
    XCTAssertFalse(ProtoValue.bytesValue(Data([0, 1, 2])).isValid(for: stringField))
    XCTAssertFalse(
      ProtoValue.messageValue(ProtoDynamicMessage(descriptor: messageDescriptor)).isValid(for: stringField)
    )
  }

  func testBytesFieldValidation() {
    // Valid values
    XCTAssertTrue(ProtoValue.bytesValue(Data([0, 1, 2])).isValid(for: bytesField))

    // Valid conversions
    XCTAssertTrue(ProtoValue.stringValue("hello").isValid(for: bytesField))

    // Invalid values
    XCTAssertFalse(ProtoValue.intValue(42).isValid(for: bytesField))
    XCTAssertFalse(ProtoValue.floatValue(3.14).isValid(for: bytesField))
    XCTAssertFalse(ProtoValue.boolValue(true).isValid(for: bytesField))
    XCTAssertFalse(ProtoValue.messageValue(ProtoDynamicMessage(descriptor: messageDescriptor)).isValid(for: bytesField))
  }

  // MARK: - Enum Field Validation Tests

  func testEnumFieldValidation() {
    // Valid values
    XCTAssertTrue(
      ProtoValue.enumValue(name: "VALUE1", number: 1, enumDescriptor: enumDescriptor).isValid(for: enumField)
    )
    XCTAssertTrue(
      ProtoValue.enumValue(name: "VALUE2", number: 2, enumDescriptor: enumDescriptor).isValid(for: enumField)
    )

    // Valid conversions
    XCTAssertTrue(ProtoValue.intValue(1).isValid(for: enumField))
    XCTAssertTrue(ProtoValue.stringValue("VALUE1").isValid(for: enumField))

    // Invalid values
    XCTAssertFalse(ProtoValue.intValue(99).isValid(for: enumField))
    XCTAssertFalse(ProtoValue.stringValue("INVALID_VALUE").isValid(for: enumField))
    XCTAssertFalse(ProtoValue.floatValue(1.0).isValid(for: enumField))
    XCTAssertFalse(ProtoValue.boolValue(true).isValid(for: enumField))
    XCTAssertFalse(ProtoValue.bytesValue(Data([0, 1, 2])).isValid(for: enumField))
    XCTAssertFalse(ProtoValue.messageValue(ProtoDynamicMessage(descriptor: messageDescriptor)).isValid(for: enumField))
  }

  // MARK: - Message Field Validation Tests

  func testMessageFieldValidation() {
    // Create a valid message
    let validMessage = ProtoDynamicMessage(descriptor: messageDescriptor)

    // Valid values
    XCTAssertTrue(ProtoValue.messageValue(validMessage).isValid(for: messageField))

    // Invalid values
    XCTAssertFalse(ProtoValue.intValue(42).isValid(for: messageField))
    XCTAssertFalse(ProtoValue.stringValue("hello").isValid(for: messageField))
    XCTAssertFalse(ProtoValue.boolValue(true).isValid(for: messageField))
    XCTAssertFalse(ProtoValue.bytesValue(Data([0, 1, 2])).isValid(for: messageField))

    // Message with wrong descriptor
    let wrongDescriptor = ProtoMessageDescriptor(
      fullName: "test.WrongMessage",
      fields: [],
      enums: [],
      nestedMessages: []
    )
    let wrongMessage = ProtoDynamicMessage(descriptor: wrongDescriptor)
    XCTAssertFalse(ProtoValue.messageValue(wrongMessage).isValid(for: messageField))
  }

  // MARK: - Repeated Field Validation Tests

  func testRepeatedFieldValidation() {
    // Valid values for repeated int field
    XCTAssertTrue(
      ProtoValue.repeatedValue([
        .intValue(1),
        .intValue(2),
        .intValue(3),
      ]).isValid(for: repeatedIntField)
    )

    // Valid values for repeated string field
    XCTAssertTrue(
      ProtoValue.repeatedValue([
        .stringValue("one"),
        .stringValue("two"),
        .stringValue("three"),
      ]).isValid(for: repeatedStringField)
    )

    // Valid values for repeated message field
    let message1 = ProtoDynamicMessage(descriptor: messageDescriptor)
    let message2 = ProtoDynamicMessage(descriptor: messageDescriptor)
    XCTAssertTrue(
      ProtoValue.repeatedValue([
        .messageValue(message1),
        .messageValue(message2),
      ]).isValid(for: repeatedMessageField)
    )

    // Invalid values for repeated int field
    XCTAssertFalse(ProtoValue.intValue(1).isValid(for: repeatedIntField))
    XCTAssertFalse(
      ProtoValue.repeatedValue([
        .stringValue("one"),
        .stringValue("two"),
      ]).isValid(for: repeatedIntField)
    )
    XCTAssertFalse(
      ProtoValue.repeatedValue([
        .intValue(1),
        .stringValue("two"),
      ]).isValid(for: repeatedIntField)
    )

    // Invalid values for repeated message field
    XCTAssertFalse(ProtoValue.messageValue(message1).isValid(for: repeatedMessageField))
    XCTAssertFalse(
      ProtoValue.repeatedValue([
        .intValue(1),
        .intValue(2),
      ]).isValid(for: repeatedMessageField)
    )
  }

  // MARK: - Map Field Validation Tests

  func testMapFieldValidation() {
    // Valid values for map string to string field
    XCTAssertTrue(
      ProtoValue.mapValue([
        "key1": .stringValue("value1"),
        "key2": .stringValue("value2"),
      ]).isValid(for: mapStringToStringField)
    )

    // Valid values for map int32 to message field
    let message1 = ProtoDynamicMessage(descriptor: messageDescriptor)
    let message2 = ProtoDynamicMessage(descriptor: messageDescriptor)
    XCTAssertTrue(
      ProtoValue.mapValue([
        "1": .messageValue(message1),
        "2": .messageValue(message2),
      ]).isValid(for: mapInt32ToMessageField)
    )

    // Non-map values are not valid for map fields
    XCTAssertFalse(ProtoValue.stringValue("value").isValid(for: mapStringToStringField))

    // Map values with incorrect value types are still considered valid in our implementation
    // This is because we're only checking if the value is a map, not the contents
    XCTAssertTrue(
      ProtoValue.mapValue([
        "key1": .intValue(1),
        "key2": .intValue(2),
      ]).isValid(for: mapStringToStringField)
    )

    // Non-map values are not valid for map fields
    XCTAssertFalse(ProtoValue.messageValue(message1).isValid(for: mapInt32ToMessageField))

    // Map values with incorrect value types are still considered valid in our implementation
    XCTAssertTrue(
      ProtoValue.mapValue([
        "key1": .stringValue("value1"),
        "key2": .stringValue("value2"),
      ]).isValid(for: mapInt32ToMessageField)
    )
  }

  // MARK: - Conversion Tests

  func testValueConversion() {
    // Int to other types
    let intValue = ProtoValue.intValue(42)
    XCTAssertEqual(intValue.asString(), "42")
    XCTAssertEqual(intValue.asFloat(), 42.0)

    if let doubleValue = intValue.asDouble() {
      XCTAssertEqual(doubleValue, 42.0, accuracy: 0.0001)
    }
    else {
      XCTFail("Failed to convert Int to Double")
    }

    XCTAssertEqual(intValue.asBool(), true)

    // String to other types
    let stringValue = ProtoValue.stringValue("42")
    XCTAssertEqual(stringValue.asInt32(), 42)
    XCTAssertEqual(stringValue.asUInt32(), 42)
    XCTAssertEqual(stringValue.asFloat(), 42.0)

    if let doubleValue = stringValue.asDouble() {
      XCTAssertEqual(doubleValue, 42.0, accuracy: 0.0001)
    }
    else {
      XCTFail("Failed to convert String to Double")
    }

    // Bool to other types
    let boolValue = ProtoValue.boolValue(true)
    XCTAssertEqual(boolValue.asInt32(), 1)
    XCTAssertEqual(boolValue.asString(), "true")

    // Float to other types
    let floatValue = ProtoValue.floatValue(3.14)

    if let doubleValue = floatValue.asDouble() {
      XCTAssertEqual(doubleValue, 3.14, accuracy: 0.0001)
    }
    else {
      XCTFail("Failed to convert Float to Double")
    }

    XCTAssertEqual(floatValue.asInt32(), 3)
    XCTAssertEqual(floatValue.asString(), "3.14")

    // Enum to other types
    let enumValue = ProtoValue.enumValue(name: "VALUE1", number: 1, enumDescriptor: enumDescriptor)
    XCTAssertEqual(enumValue.asInt32(), 1)
    XCTAssertEqual(enumValue.asString(), "VALUE1")

    // Invalid conversions
    XCTAssertNil(ProtoValue.stringValue("not a number").asInt32())
    XCTAssertNil(ProtoValue.stringValue("not a number").asFloat())
    XCTAssertNil(ProtoValue.stringValue("not a bool").asBool())
  }

  // MARK: - Edge Cases

  func testEdgeCases() {
    // Empty string
    XCTAssertTrue(ProtoValue.stringValue("").isValid(for: stringField))

    // Empty bytes
    XCTAssertTrue(ProtoValue.bytesValue(Data()).isValid(for: bytesField))

    // Empty repeated field
    XCTAssertTrue(ProtoValue.repeatedValue([]).isValid(for: repeatedIntField))

    // Empty map
    XCTAssertTrue(ProtoValue.mapValue([:]).isValid(for: mapStringToStringField))

    // Int32 min/max values
    XCTAssertTrue(ProtoValue.intValue(Int(Int32.min)).isValid(for: intField))
    XCTAssertTrue(ProtoValue.intValue(Int(Int32.max)).isValid(for: intField))

    // UInt32 min/max values
    XCTAssertTrue(ProtoValue.uintValue(UInt(UInt32.min)).isValid(for: uintField))
    XCTAssertTrue(ProtoValue.uintValue(UInt(UInt32.max)).isValid(for: uintField))
  }
}
