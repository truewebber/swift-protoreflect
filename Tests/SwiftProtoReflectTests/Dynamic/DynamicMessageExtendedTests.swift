//
// DynamicMessageExtendedTests.swift
// SwiftProtoReflectTests
//
// Created: 2025-05-23
// Additional tests to improve code coverage for DynamicMessage
//

import XCTest

@testable import SwiftProtoReflect

final class DynamicMessageExtendedTests: XCTestCase {
  // MARK: - Properties

  private var fileDescriptor: FileDescriptor!
  private var personMessage: MessageDescriptor!
  private var addressMessage: MessageDescriptor!
  private var enumDescriptor: EnumDescriptor!

  // MARK: - Setup

  override func setUp() {
    super.setUp()

    // Create test file descriptor
    fileDescriptor = FileDescriptor(name: "test.proto", package: "test")

    // Create enum descriptor PhoneType
    enumDescriptor = EnumDescriptor(name: "PhoneType", parent: fileDescriptor)
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "MOBILE", number: 0))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "HOME", number: 1))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "WORK", number: 2))

    fileDescriptor.addEnum(enumDescriptor)

    // Create message descriptor Address
    addressMessage = MessageDescriptor(name: "Address", parent: fileDescriptor)
    addressMessage.addField(
      FieldDescriptor(
        name: "street",
        number: 1,
        type: .string
      )
    )
    addressMessage.addField(
      FieldDescriptor(
        name: "city",
        number: 2,
        type: .string
      )
    )

    fileDescriptor.addMessage(addressMessage)

    // Create message descriptor Person
    personMessage = MessageDescriptor(name: "Person", parent: fileDescriptor)
    personMessage.addField(
      FieldDescriptor(
        name: "name",
        number: 1,
        type: .string
      )
    )
    personMessage.addField(
      FieldDescriptor(
        name: "id",
        number: 2,
        type: .int32
      )
    )
    personMessage.addField(
      FieldDescriptor(
        name: "address",
        number: 3,
        type: .message,
        typeName: "test.Address"
      )
    )

    fileDescriptor.addMessage(personMessage)
  }

  override func tearDown() {
    fileDescriptor = nil
    personMessage = nil
    addressMessage = nil
    enumDescriptor = nil
    super.tearDown()
  }

  // MARK: - Field Not Found Error Tests

  func testFieldNotFoundErrors() {
    var message = DynamicMessage(descriptor: personMessage)

    // Test fieldNotFound error for set methods
    XCTAssertThrowsError(try message.set("value", forField: "non_existent_field")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Expected DynamicMessageError")
        return
      }

      if case .fieldNotFound(let fieldName) = dynamicError {
        XCTAssertEqual(fieldName, "non_existent_field")
      }
      else {
        XCTFail("Expected fieldNotFound error")
      }
    }

    // Test fieldNotFoundByNumber error for set methods
    XCTAssertThrowsError(try message.set("value", forField: 999)) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Expected DynamicMessageError")
        return
      }

      if case .fieldNotFoundByNumber(let fieldNumber) = dynamicError {
        XCTAssertEqual(fieldNumber, 999)
      }
      else {
        XCTFail("Expected fieldNotFoundByNumber error")
      }
    }

    // Test fieldNotFound error for get methods
    XCTAssertThrowsError(try message.get(forField: "non_existent_field")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Expected DynamicMessageError")
        return
      }

      if case .fieldNotFound(let fieldName) = dynamicError {
        XCTAssertEqual(fieldName, "non_existent_field")
      }
      else {
        XCTFail("Expected fieldNotFound error")
      }
    }

    // Test fieldNotFoundByNumber error for get methods
    XCTAssertThrowsError(try message.get(forField: 999)) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Expected DynamicMessageError")
        return
      }

      if case .fieldNotFoundByNumber(let fieldNumber) = dynamicError {
        XCTAssertEqual(fieldNumber, 999)
      }
      else {
        XCTFail("Expected fieldNotFoundByNumber error")
      }
    }

    // Test fieldNotFound error for hasValue methods
    XCTAssertThrowsError(try message.hasValue(forField: "non_existent_field")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Expected DynamicMessageError")
        return
      }

      if case .fieldNotFound(let fieldName) = dynamicError {
        XCTAssertEqual(fieldName, "non_existent_field")
      }
      else {
        XCTFail("Expected fieldNotFound error")
      }
    }

    // Test fieldNotFoundByNumber error for hasValue methods
    XCTAssertThrowsError(try message.hasValue(forField: 999)) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Expected DynamicMessageError")
        return
      }

      if case .fieldNotFoundByNumber(let fieldNumber) = dynamicError {
        XCTAssertEqual(fieldNumber, 999)
      }
      else {
        XCTFail("Expected fieldNotFoundByNumber error")
      }
    }

    // Test fieldNotFound error for clearField methods
    XCTAssertThrowsError(try message.clearField("non_existent_field")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Expected DynamicMessageError")
        return
      }

      if case .fieldNotFound(let fieldName) = dynamicError {
        XCTAssertEqual(fieldName, "non_existent_field")
      }
      else {
        XCTFail("Expected fieldNotFound error")
      }
    }

    // Test fieldNotFoundByNumber error for clearField methods
    XCTAssertThrowsError(try message.clearField(999)) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Expected DynamicMessageError")
        return
      }

      if case .fieldNotFoundByNumber(let fieldNumber) = dynamicError {
        XCTAssertEqual(fieldNumber, 999)
      }
      else {
        XCTFail("Expected fieldNotFoundByNumber error")
      }
    }
  }

  // MARK: - Message Type Validation Tests

  func testMessageTypeMismatchErrors() {
    var message = DynamicMessage(descriptor: personMessage)

    // Create message with wrong type
    let wrongMessage = DynamicMessage(descriptor: personMessage)  // Person instead of Address

    // Test messageMismatch error when setting nested message
    XCTAssertThrowsError(try message.set(wrongMessage, forField: "address")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Expected DynamicMessageError")
        return
      }

      if case .messageMismatch(let fieldName, let expectedType, let actualType) = dynamicError {
        XCTAssertEqual(fieldName, "address")
        XCTAssertEqual(expectedType, "test.Address")
        XCTAssertEqual(actualType, "test.Person")
      }
      else {
        XCTFail("Expected messageMismatch error")
      }
    }

    // Test typeMismatch error when trying to set non-DynamicMessage for message field
    XCTAssertThrowsError(try message.set("not a message", forField: "address")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Expected DynamicMessageError")
        return
      }

      if case .typeMismatch(let fieldName, let expectedType, _) = dynamicError {
        XCTAssertEqual(fieldName, "address")
        XCTAssertEqual(expectedType, "DynamicMessage")
      }
      else {
        XCTFail("Expected typeMismatch error")
      }
    }
  }

  // MARK: - Enum Type Validation Tests

  func testEnumTypeValidation() {
    // Create message with enum field
    var messageDesc = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    messageDesc.addField(
      FieldDescriptor(
        name: "enum_field",
        number: 1,
        type: .enum,
        typeName: "test.PhoneType"
      )
    )

    fileDescriptor.addMessage(messageDesc)

    var message = DynamicMessage(descriptor: messageDesc)

    // Test typeMismatch error for incorrect enum type
    XCTAssertThrowsError(try message.set(42.5, forField: "enum_field")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Expected DynamicMessageError")
        return
      }

      if case .typeMismatch(let fieldName, let expectedType, _) = dynamicError {
        XCTAssertEqual(fieldName, "enum_field")
        XCTAssertEqual(expectedType, "Enum (Int32 or String)")
      }
      else {
        XCTFail("Expected typeMismatch error")
      }
    }
  }

  // MARK: - Group Type Tests

  func testGroupTypeValidation() {
    // Create message with group field (deprecated type)
    var messageDesc = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    messageDesc.addField(
      FieldDescriptor(
        name: "group_field",
        number: 1,
        type: .group,
        typeName: "test.SomeGroup"
      )
    )

    fileDescriptor.addMessage(messageDesc)

    var message = DynamicMessage(descriptor: messageDesc)

    // Test valid group field
    let groupMessage = DynamicMessage(descriptor: addressMessage)
    do {
      try message.set(groupMessage, forField: "group_field")
      XCTAssertTrue(try message.hasValue(forField: "group_field"))
    }
    catch {
      XCTFail("Should not have error when setting valid group message: \(error)")
    }

    // Test typeMismatch error for incorrect group type
    XCTAssertThrowsError(try message.set("not a group", forField: "group_field")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Expected DynamicMessageError")
        return
      }

      if case .typeMismatch(let fieldName, let expectedType, _) = dynamicError {
        XCTAssertEqual(fieldName, "group_field")
        XCTAssertEqual(expectedType, "DynamicMessage (group)")
      }
      else {
        XCTFail("Expected typeMismatch error")
      }
    }
  }

  // MARK: - Repeated Field Error Tests

  func testRepeatedFieldErrors() {
    var message = DynamicMessage(descriptor: personMessage)

    // Test fieldNotFoundByNumber error for addRepeatedValue
    XCTAssertThrowsError(try message.addRepeatedValue("value", forField: 999)) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Expected DynamicMessageError")
        return
      }

      if case .fieldNotFoundByNumber(let fieldNumber) = dynamicError {
        XCTAssertEqual(fieldNumber, 999)
      }
      else {
        XCTFail("Expected fieldNotFoundByNumber error")
      }
    }

    // Test notRepeatedField error for regular field
    XCTAssertThrowsError(try message.addRepeatedValue("value", forField: "name")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Expected DynamicMessageError")
        return
      }

      if case .notRepeatedField(let fieldName) = dynamicError {
        XCTAssertEqual(fieldName, "name")
      }
      else {
        XCTFail("Expected notRepeatedField error")
      }
    }
  }

  // MARK: - Map Field Error Tests

  func testMapFieldErrors() {
    var message = DynamicMessage(descriptor: personMessage)

    // Test fieldNotFoundByNumber error for setMapEntry
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: "key", inField: 999)) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Expected DynamicMessageError")
        return
      }

      if case .fieldNotFoundByNumber(let fieldNumber) = dynamicError {
        XCTAssertEqual(fieldNumber, 999)
      }
      else {
        XCTFail("Expected fieldNotFoundByNumber error")
      }
    }

    // Test notMapField error for regular field
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: "key", inField: "name")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Expected DynamicMessageError")
        return
      }

      if case .notMapField(let fieldName) = dynamicError {
        XCTAssertEqual(fieldName, "name")
      }
      else {
        XCTFail("Expected notMapField error")
      }
    }
  }

  // MARK: - Clear Nested Message Field Tests

  func testClearNestedMessageField() {
    var message = DynamicMessage(descriptor: personMessage)

    do {
      // Set nested message
      let address = DynamicMessage(descriptor: addressMessage)
      try message.set(address, forField: "address")
      XCTAssertTrue(try message.hasValue(forField: "address"))

      // Clear nested message
      try message.clearField("address")
      XCTAssertFalse(try message.hasValue(forField: "address"))

      // Clear nested message by field number
      try message.set(address, forField: 3)
      XCTAssertTrue(try message.hasValue(forField: 3))

      try message.clearField(3)
      XCTAssertFalse(try message.hasValue(forField: 3))
    }
    catch {
      XCTFail("Should not have exceptions when clearing nested message: \(error)")
    }
  }

  // MARK: - Map Key Type Validation Tests

  func testMapKeyTypeValidation() {
    // Create various map fields for testing all key types
    var messageDesc = MessageDescriptor(name: "MapKeyTest", parent: fileDescriptor)

    // Map with int32 key
    let int32KeyInfo = KeyFieldInfo(name: "key", number: 1, type: .int32)
    let stringValueInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    messageDesc.addField(
      FieldDescriptor(
        name: "int32_map",
        number: 1,
        type: .message,
        typeName: "map<int32, string>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: MapEntryInfo(keyFieldInfo: int32KeyInfo, valueFieldInfo: stringValueInfo)
      )
    )

    // Map with int64 key
    let int64KeyInfo = KeyFieldInfo(name: "key", number: 1, type: .int64)
    messageDesc.addField(
      FieldDescriptor(
        name: "int64_map",
        number: 2,
        type: .message,
        typeName: "map<int64, string>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: MapEntryInfo(keyFieldInfo: int64KeyInfo, valueFieldInfo: stringValueInfo)
      )
    )

    // Map with uint32 key
    let uint32KeyInfo = KeyFieldInfo(name: "key", number: 1, type: .uint32)
    messageDesc.addField(
      FieldDescriptor(
        name: "uint32_map",
        number: 3,
        type: .message,
        typeName: "map<uint32, string>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: MapEntryInfo(keyFieldInfo: uint32KeyInfo, valueFieldInfo: stringValueInfo)
      )
    )

    // Map with uint64 key
    let uint64KeyInfo = KeyFieldInfo(name: "key", number: 1, type: .uint64)
    messageDesc.addField(
      FieldDescriptor(
        name: "uint64_map",
        number: 4,
        type: .message,
        typeName: "map<uint64, string>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: MapEntryInfo(keyFieldInfo: uint64KeyInfo, valueFieldInfo: stringValueInfo)
      )
    )

    // Map with bool key
    let boolKeyInfo = KeyFieldInfo(name: "key", number: 1, type: .bool)
    messageDesc.addField(
      FieldDescriptor(
        name: "bool_map",
        number: 5,
        type: .message,
        typeName: "map<bool, string>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: MapEntryInfo(keyFieldInfo: boolKeyInfo, valueFieldInfo: stringValueInfo)
      )
    )

    fileDescriptor.addMessage(messageDesc)

    var message = DynamicMessage(descriptor: messageDesc)

    // Test type errors for int32 keys
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: "string_key", inField: "int32_map"))

    // Test type errors for int64 keys
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: "string_key", inField: "int64_map"))

    // Test type errors for uint32 keys
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: "string_key", inField: "uint32_map"))

    // Test type errors for uint64 keys
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: "string_key", inField: "uint64_map"))

    // Test type errors for bool keys
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: "string_key", inField: "bool_map"))
  }

  // MARK: - Invalid Map Key Type Test

  func testInvalidMapKeyType() {
    // Test DynamicMessageError.invalidMapKeyType error directly
    let error = DynamicMessageError.invalidMapKeyType(type: .double)
    XCTAssertEqual(error.errorDescription, "Invalid key type double for map field")

    // Test with other invalid types
    let floatError = DynamicMessageError.invalidMapKeyType(type: .float)
    XCTAssertEqual(floatError.errorDescription, "Invalid key type float for map field")

    let bytesError = DynamicMessageError.invalidMapKeyType(type: .bytes)
    XCTAssertEqual(bytesError.errorDescription, "Invalid key type bytes for map field")
  }

  // MARK: - NSNumber Conversion Tests

  func testNSNumberConversions() {
    // Create message with fields for NSNumber conversions
    var messageDesc = MessageDescriptor(name: "NSNumberTest", parent: fileDescriptor)
    messageDesc.addField(FieldDescriptor(name: "float_field", number: 1, type: .float))
    messageDesc.addField(FieldDescriptor(name: "double_field", number: 2, type: .double))

    fileDescriptor.addMessage(messageDesc)

    var message = DynamicMessage(descriptor: messageDesc)

    do {
      // Test NSNumber conversion for float field
      let floatNumber = NSNumber(value: 3.14 as Double)  // not Float
      try message.set(floatNumber, forField: "float_field")

      let retrievedFloat = try message.get(forField: "float_field") as? Float
      XCTAssertEqual(retrievedFloat!, 3.14, accuracy: 0.001)

      // Test NSNumber conversion for double field
      let doubleNumber = NSNumber(value: 2.71 as Float)  // not Double
      try message.set(doubleNumber, forField: "double_field")

      let retrievedDouble = try message.get(forField: "double_field") as? Double
      XCTAssertEqual(retrievedDouble!, 2.71, accuracy: 0.001)
    }
    catch {
      XCTFail("Should not have exceptions during NSNumber conversion: \(error)")
    }
  }

  // MARK: - Map Key Conversion Tests

  func testMapKeyConversions() {
    // Create map fields for testing key conversions
    var messageDesc = MessageDescriptor(name: "MapKeyConversion", parent: fileDescriptor)

    // Map with int32 key
    let int32KeyInfo = KeyFieldInfo(name: "key", number: 1, type: .int32)
    let stringValueInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    messageDesc.addField(
      FieldDescriptor(
        name: "int32_map",
        number: 1,
        type: .message,
        typeName: "map<int32, string>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: MapEntryInfo(keyFieldInfo: int32KeyInfo, valueFieldInfo: stringValueInfo)
      )
    )

    // Map with int64 key
    let int64KeyInfo = KeyFieldInfo(name: "key", number: 1, type: .int64)
    messageDesc.addField(
      FieldDescriptor(
        name: "int64_map",
        number: 2,
        type: .message,
        typeName: "map<int64, string>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: MapEntryInfo(keyFieldInfo: int64KeyInfo, valueFieldInfo: stringValueInfo)
      )
    )

    // Map with uint32 key
    let uint32KeyInfo = KeyFieldInfo(name: "key", number: 1, type: .uint32)
    messageDesc.addField(
      FieldDescriptor(
        name: "uint32_map",
        number: 3,
        type: .message,
        typeName: "map<uint32, string>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: MapEntryInfo(keyFieldInfo: uint32KeyInfo, valueFieldInfo: stringValueInfo)
      )
    )

    // Map with uint64 key
    let uint64KeyInfo = KeyFieldInfo(name: "key", number: 1, type: .uint64)
    messageDesc.addField(
      FieldDescriptor(
        name: "uint64_map",
        number: 4,
        type: .message,
        typeName: "map<uint64, string>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: MapEntryInfo(keyFieldInfo: uint64KeyInfo, valueFieldInfo: stringValueInfo)
      )
    )

    fileDescriptor.addMessage(messageDesc)

    var message = DynamicMessage(descriptor: messageDesc)

    do {
      // Test Int -> Int32 conversion for keys
      try message.setMapEntry("value1", forKey: Int(42), inField: "int32_map")
      let int32Map = try message.get(forField: "int32_map") as? [AnyHashable: String]
      XCTAssertEqual(int32Map?[Int32(42)], "value1")

      // Test Int -> Int64 conversion for keys
      try message.setMapEntry("value2", forKey: Int(84), inField: "int64_map")
      let int64Map = try message.get(forField: "int64_map") as? [AnyHashable: String]
      XCTAssertEqual(int64Map?[Int64(84)], "value2")

      // Test UInt -> UInt32 conversion for keys
      try message.setMapEntry("value3", forKey: UInt(123), inField: "uint32_map")
      let uint32Map = try message.get(forField: "uint32_map") as? [AnyHashable: String]
      XCTAssertEqual(uint32Map?[UInt32(123)], "value3")

      // Test UInt -> UInt64 conversion for keys
      try message.setMapEntry("value4", forKey: UInt(456), inField: "uint64_map")
      let uint64Map = try message.get(forField: "uint64_map") as? [AnyHashable: String]
      XCTAssertEqual(uint64Map?[UInt64(456)], "value4")
    }
    catch {
      XCTFail("Should not have exceptions during map key conversion: \(error)")
    }
  }

  // MARK: - Map Field Validation Error Tests

  func testMapFieldValidationErrors() {
    // Create normal (non-map) field to test notMapField error
    var normalMessage = MessageDescriptor(name: "NormalMessage", parent: fileDescriptor)
    normalMessage.addField(
      FieldDescriptor(
        name: "normal_field",
        number: 1,
        type: .string
      )
    )

    fileDescriptor.addMessage(normalMessage)

    var normalDynamicMessage = DynamicMessage(descriptor: normalMessage)

    // Test notMapField error when trying to use normal field as map
    XCTAssertThrowsError(try normalDynamicMessage.setMapEntry("value", forKey: "key", inField: "normal_field")) {
      error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Expected DynamicMessageError")
        return
      }

      if case .notMapField(let fieldName) = dynamicError {
        XCTAssertEqual(fieldName, "normal_field")
      }
      else {
        XCTFail("Expected notMapField error")
      }
    }
  }
}
