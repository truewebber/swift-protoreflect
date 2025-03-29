import XCTest

@testable import SwiftProtoReflect

class ProtoFieldDescriptorTests: XCTestCase {

  // MARK: - Initialization Tests

  func testInitialization() {
    // Given
    let name = "test_field"
    let number = 1
    let type = ProtoFieldType.int32
    let isRepeated = false
    let isMap = false

    // When
    let field = ProtoFieldDescriptor(name: name, number: number, type: type, isRepeated: isRepeated, isMap: isMap)

    // Then
    XCTAssertEqual(field.name, name)
    XCTAssertEqual(field.number, number)
    XCTAssertEqual(field.type, type)
    XCTAssertEqual(field.isRepeated, isRepeated)
    XCTAssertEqual(field.isMap, isMap)
    XCTAssertNil(field.defaultValue)
    XCTAssertNil(field.messageType)
  }

  func testInitializationWithDefaultValue() {
    // Given
    let defaultValue = ProtoValue.intValue(42)

    // When
    let field = ProtoFieldDescriptor(
      name: "field",
      number: 1,
      type: .int32,
      isRepeated: false,
      isMap: false,
      defaultValue: defaultValue
    )

    // Then
    XCTAssertEqual(field.defaultValue?.getInt(), 42)
  }

  func testInitializationWithMessageType() {
    // Given
    let messageType = ProtoMessageDescriptor(fullName: "TestMessage", fields: [], enums: [], nestedMessages: [])

    // When
    let field = ProtoFieldDescriptor(
      name: "message_field",
      number: 1,
      type: .message(messageType),
      isRepeated: false,
      isMap: false,
      messageType: messageType
    )

    // Then
    XCTAssertNotNil(field.messageType)
    XCTAssertEqual(field.messageType?.fullName, "TestMessage")
  }

  // MARK: - Equality Tests

  func testFieldDescriptorEquality() {
    // Given
    let field1 = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
    let field2 = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
    let field3 = ProtoFieldDescriptor(name: "field2", number: 1, type: .int32, isRepeated: false, isMap: false)
    let field4 = ProtoFieldDescriptor(name: "field1", number: 2, type: .int32, isRepeated: false, isMap: false)
    let field5 = ProtoFieldDescriptor(name: "field1", number: 1, type: .string, isRepeated: false, isMap: false)

    // Then
    XCTAssertEqual(field1, field2)
    XCTAssertNotEqual(field1, field3)
    XCTAssertNotEqual(field1, field4)
    XCTAssertNotEqual(field1, field5)
  }

  // MARK: - Hashability Tests

  func testFieldDescriptorHashable() {
    // Given
    let field = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
    var fieldMap = [ProtoFieldDescriptor: ProtoValue]()

    // When
    fieldMap[field] = .intValue(123)

    // Then
    XCTAssertEqual(fieldMap[field]?.getInt(), 123)
  }

  // MARK: - Validation Tests

  func testValidFieldDescriptor() {
    // Given
    let validField = ProtoFieldDescriptor(name: "valid_field", number: 1, type: .int32, isRepeated: false, isMap: false)

    // Then
    XCTAssertTrue(validField.isValid())
    XCTAssertNil(validField.validationError())
  }

  func testInvalidFieldDescriptorEmptyName() {
    // Given
    let invalidField = ProtoFieldDescriptor(name: "", number: 1, type: .int32, isRepeated: false, isMap: false)

    // Then
    XCTAssertFalse(invalidField.isValid())
    XCTAssertEqual(invalidField.validationError(), "Field name cannot be empty")
  }

  func testInvalidFieldDescriptorNegativeNumber() {
    // Given
    let invalidField = ProtoFieldDescriptor(name: "field", number: -1, type: .int32, isRepeated: false, isMap: false)

    // Then
    XCTAssertFalse(invalidField.isValid())
    XCTAssertEqual(invalidField.validationError(), "Field number must be positive (got -1)")
  }

  func testInvalidFieldDescriptorZeroNumber() {
    // Given
    let invalidField = ProtoFieldDescriptor(name: "field", number: 0, type: .int32, isRepeated: false, isMap: false)

    // Then
    XCTAssertFalse(invalidField.isValid())
    XCTAssertEqual(invalidField.validationError(), "Field number must be positive (got 0)")
  }

  func testInvalidFieldDescriptorMissingMessageType() {
    // Given
    let invalidField = ProtoFieldDescriptor(
      name: "message_field",
      number: 1,
      type: .message(nil),
      isRepeated: false,
      isMap: false
    )

    // Then
    XCTAssertFalse(invalidField.isValid())
    XCTAssertEqual(
      invalidField.validationError(),
      "Message type field 'message_field' requires a messageType descriptor"
    )
  }

  // MARK: - Edge Case Tests

  func testFieldWithMaximumNumber() {
    // Given
    let field = ProtoFieldDescriptor(name: "max_field", number: Int.max, type: .int32, isRepeated: false, isMap: false)

    // Then
    XCTAssertTrue(field.isValid())
  }

  func testAllFieldTypes() {
    // Given
    let testMessageType = ProtoMessageDescriptor(fullName: "TestMessage", fields: [], enums: [], nestedMessages: [])
    let testEnumType = ProtoEnumDescriptor(name: "TestEnum", values: [ProtoEnumValueDescriptor(name: "TEST_VALUE", number: 0)])

    let validTypes: [(type: ProtoFieldType, messageType: ProtoMessageDescriptor?, enumType: ProtoEnumDescriptor?)] = [
      (.int32, nil, nil),
      (.int64, nil, nil),
      (.uint32, nil, nil),
      (.uint64, nil, nil),
      (.sint32, nil, nil),
      (.sint64, nil, nil),
      (.sfixed32, nil, nil),
      (.sfixed64, nil, nil),
      (.fixed32, nil, nil),
      (.fixed64, nil, nil),
      (.float, nil, nil),
      (.double, nil, nil),
      (.bool, nil, nil),
      (.string, nil, nil),
      (.bytes, nil, nil),
      (.message(testMessageType), testMessageType, nil),
      (.enum(testEnumType), nil, testEnumType),
      (.group, nil, nil)  // Group type is deprecated but still valid
    ]

    for typeInfo in validTypes {
      let descriptor = ProtoFieldDescriptor(
        name: "test_field",
        number: 1,
        type: typeInfo.type,
        isRepeated: false,
        isMap: false,
        messageType: typeInfo.messageType,
        enumType: typeInfo.enumType
      )

      XCTAssertEqual(descriptor.type, typeInfo.type)
      XCTAssertTrue(descriptor.isValid())
    }

    // Unknown type should be invalid
    let unknownDescriptor = ProtoFieldDescriptor(
      name: "test_field",
      number: 1,
      type: .unknown,
      isRepeated: false,
      isMap: false
    )
    XCTAssertEqual(unknownDescriptor.type, .unknown)
    XCTAssertFalse(unknownDescriptor.isValid())
  }
}
