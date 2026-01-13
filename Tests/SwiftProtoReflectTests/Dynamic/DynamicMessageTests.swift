//
// DynamicMessageTests.swift
// SwiftProtoReflectTests
//
// Created: 2025-05-23
//

import XCTest

@testable import SwiftProtoReflect

final class DynamicMessageTests: XCTestCase {
  // MARK: - Properties

  // Test descriptors
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

    // Add enum to file
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
    addressMessage.addField(
      FieldDescriptor(
        name: "zip_code",
        number: 3,
        type: .string
      )
    )

    // Add Address message to file
    fileDescriptor.addMessage(addressMessage)

    // Create message descriptor Person
    personMessage = MessageDescriptor(name: "Person", parent: fileDescriptor)

    // Add simple fields
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
        name: "email",
        number: 3,
        type: .string,
        isOptional: true
      )
    )

    // Add field for nested message
    personMessage.addField(
      FieldDescriptor(
        name: "address",
        number: 4,
        type: .message,
        typeName: "test.Address"
      )
    )

    // Add enum field
    personMessage.addField(
      FieldDescriptor(
        name: "phone_type",
        number: 5,
        type: .enum,
        typeName: "test.PhoneType"
      )
    )

    // Add repeated field
    personMessage.addField(
      FieldDescriptor(
        name: "phone_numbers",
        number: 6,
        type: .string,
        isRepeated: true
      )
    )

    // Add map field
    let keyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valueInfo)

    personMessage.addField(
      FieldDescriptor(
        name: "attributes",
        number: 7,
        type: .message,
        typeName: "map<string, string>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: mapEntryInfo
      )
    )

    // Add oneof fields
    personMessage.addField(
      FieldDescriptor(
        name: "work_email",
        number: 8,
        type: .string,
        oneofIndex: 1
      )
    )
    personMessage.addField(
      FieldDescriptor(
        name: "personal_email",
        number: 9,
        type: .string,
        oneofIndex: 1
      )
    )

    // Add Person message to file
    fileDescriptor.addMessage(personMessage)
  }

  override func tearDown() {
    fileDescriptor = nil
    personMessage = nil
    addressMessage = nil
    enumDescriptor = nil
    super.tearDown()
  }

  // MARK: - Initialization Tests

  func testInitialization() {
    // Create DynamicMessage instance
    let message = DynamicMessage(descriptor: personMessage)

    // Check that descriptor is set correctly
    XCTAssertEqual(message.descriptor.name, "Person")
    XCTAssertEqual(message.descriptor.fullName, "test.Person")

    // Check that values are empty
    XCTAssertFalse(try message.hasValue(forField: "name"))
    XCTAssertNil(try message.get(forField: "name"))
  }

  // MARK: - Field Access Tests

  func testSetAndGetScalarFields() {
    var message = DynamicMessage(descriptor: personMessage)

    // Set and get string field
    do {
      try message.set("John Doe", forField: "name")
      XCTAssertTrue(try message.hasValue(forField: "name"))
      XCTAssertEqual(try message.get(forField: "name") as? String, "John Doe")

      // Set and get numeric field
      try message.set(Int32(123), forField: "id")
      XCTAssertTrue(try message.hasValue(forField: "id"))
      XCTAssertEqual(try message.get(forField: "id") as? Int32, 123)

      // Use field number instead of name
      try message.set("john.doe@example.com", forField: 3)  // email
      XCTAssertTrue(try message.hasValue(forField: 3))
      XCTAssertEqual(try message.get(forField: 3) as? String, "john.doe@example.com")
    }
    catch {
      XCTFail("Should not have exceptions when setting/getting fields: \(error)")
    }
  }

  func testNestedMessageField() {
    var message = DynamicMessage(descriptor: personMessage)
    var addressMsg = DynamicMessage(descriptor: addressMessage)

    do {
      // Fill address
      try addressMsg.set("123 Main St", forField: "street")
      try addressMsg.set("Anytown", forField: "city")
      try addressMsg.set("12345", forField: "zip_code")

      // Set address in Person
      try message.set(addressMsg, forField: "address")

      // Check that address is set
      XCTAssertTrue(try message.hasValue(forField: "address"))

      // Get and check address
      let retrievedAddress = try message.get(forField: "address") as? DynamicMessage
      XCTAssertNotNil(retrievedAddress)
      XCTAssertEqual(try retrievedAddress?.get(forField: "street") as? String, "123 Main St")
      XCTAssertEqual(try retrievedAddress?.get(forField: "city") as? String, "Anytown")
      XCTAssertEqual(try retrievedAddress?.get(forField: "zip_code") as? String, "12345")
    }
    catch {
      XCTFail("Should not have exceptions when working with nested messages: \(error)")
    }
  }

  func testEnumField() {
    var message = DynamicMessage(descriptor: personMessage)

    do {
      // Set enum by number
      try message.set(Int32(1), forField: "phone_type")  // HOME
      XCTAssertTrue(try message.hasValue(forField: "phone_type"))
      XCTAssertEqual(try message.get(forField: "phone_type") as? Int32, 1)

      // Set enum by name
      try message.set("WORK", forField: "phone_type")
      XCTAssertTrue(try message.hasValue(forField: "phone_type"))
      XCTAssertEqual(try message.get(forField: "phone_type") as? String, "WORK")
    }
    catch {
      XCTFail("Should not have exceptions when working with enum fields: \(error)")
    }
  }

  func testRepeatedField() {
    var message = DynamicMessage(descriptor: personMessage)

    do {
      // Add phone numbers one by one
      try message.addRepeatedValue("+1-555-1234", forField: "phone_numbers")
      try message.addRepeatedValue("+1-555-5678", forField: "phone_numbers")

      // Check that field is set
      XCTAssertTrue(try message.hasValue(forField: "phone_numbers"))

      // Get array and check its contents
      let phoneNumbers = try message.get(forField: "phone_numbers") as? [String]
      XCTAssertNotNil(phoneNumbers)
      XCTAssertEqual(phoneNumbers?.count, 2)
      XCTAssertEqual(phoneNumbers?[0], "+1-555-1234")
      XCTAssertEqual(phoneNumbers?[1], "+1-555-5678")

      // Set entire array
      let newNumbers = ["+1-555-9876", "+1-555-4321"]
      try message.set(newNumbers, forField: "phone_numbers")

      // Check updated array
      let updatedNumbers = try message.get(forField: "phone_numbers") as? [String]
      XCTAssertNotNil(updatedNumbers)
      XCTAssertEqual(updatedNumbers?.count, 2)
      XCTAssertEqual(updatedNumbers?[0], "+1-555-9876")
      XCTAssertEqual(updatedNumbers?[1], "+1-555-4321")
    }
    catch {
      XCTFail("Should not have exceptions when working with repeated fields: \(error)")
    }
  }

  func testMapField() {
    var message = DynamicMessage(descriptor: personMessage)

    do {
      // Add entries to map one by one
      try message.setMapEntry("Developer", forKey: "role", inField: "attributes")
      try message.setMapEntry("John", forKey: "first_name", inField: "attributes")

      // Check that field is set
      XCTAssertTrue(try message.hasValue(forField: "attributes"))

      // Get map and check its contents
      let attributes = try message.get(forField: "attributes") as? [String: String]
      XCTAssertNotNil(attributes)
      XCTAssertEqual(attributes?.count, 2)
      XCTAssertEqual(attributes?["role"], "Developer")
      XCTAssertEqual(attributes?["first_name"], "John")

      // Set entire map
      let newAttributes = ["department": "Engineering", "level": "Senior"]
      try message.set(newAttributes, forField: "attributes")

      // Check updated map
      let updatedAttributes = try message.get(forField: "attributes") as? [String: String]
      XCTAssertNotNil(updatedAttributes)
      XCTAssertEqual(updatedAttributes?.count, 2)
      XCTAssertEqual(updatedAttributes?["department"], "Engineering")
      XCTAssertEqual(updatedAttributes?["level"], "Senior")
    }
    catch {
      XCTFail("Should not have exceptions when working with map fields: \(error)")
    }
  }

  func testOneofField() {
    var message = DynamicMessage(descriptor: personMessage)

    do {
      // Set first oneof
      try message.set("work@example.com", forField: "work_email")
      XCTAssertTrue(try message.hasValue(forField: "work_email"))
      XCTAssertFalse(try message.hasValue(forField: "personal_email"))
      XCTAssertEqual(try message.get(forField: "work_email") as? String, "work@example.com")

      // Set second oneof - should clear first
      try message.set("personal@example.com", forField: "personal_email")
      XCTAssertFalse(try message.hasValue(forField: "work_email"))
      XCTAssertTrue(try message.hasValue(forField: "personal_email"))
      XCTAssertEqual(try message.get(forField: "personal_email") as? String, "personal@example.com")

      // Clear oneof field
      try message.clearField("personal_email")
      XCTAssertFalse(try message.hasValue(forField: "personal_email"))
      XCTAssertFalse(try message.hasValue(forField: "work_email"))
    }
    catch {
      XCTFail("Should not have exceptions when working with oneof fields: \(error)")
    }
  }

  func testClearField() {
    var message = DynamicMessage(descriptor: personMessage)

    do {
      // Set values
      try message.set("John Doe", forField: "name")
      try message.set(Int32(123), forField: "id")

      // Check that values are set
      XCTAssertTrue(try message.hasValue(forField: "name"))
      XCTAssertTrue(try message.hasValue(forField: "id"))

      // Clear one field
      try message.clearField("name")

      // Check result
      XCTAssertFalse(try message.hasValue(forField: "name"))
      XCTAssertTrue(try message.hasValue(forField: "id"))

      // Set value again
      try message.set("Jane Doe", forField: "name")
      XCTAssertTrue(try message.hasValue(forField: "name"))
      XCTAssertEqual(try message.get(forField: "name") as? String, "Jane Doe")
    }
    catch {
      XCTFail("Should not have exceptions when clearing fields: \(error)")
    }
  }

  // MARK: - Type Validation Tests

  func testTypeValidation() {
    var message = DynamicMessage(descriptor: personMessage)

    // Check error when setting value with incorrect type
    XCTAssertThrowsError(try message.set(123, forField: "name")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Expected DynamicMessageError")
        return
      }

      if case .typeMismatch(let fieldName, let expectedType, _) = dynamicError {
        XCTAssertEqual(fieldName, "name")
        XCTAssertEqual(expectedType, "String")
      }
      else {
        XCTFail("Expected typeMismatch")
      }
    }

    // Check error when setting incorrect nested message type
    let wrongMessage = DynamicMessage(descriptor: personMessage)  // Person instead of Address
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
        XCTFail("Expected messageMismatch")
      }
    }
  }

  func testNonExistentFieldAccess() {
    let message = DynamicMessage(descriptor: personMessage)

    // Check error when accessing non-existent field by name
    XCTAssertThrowsError(try message.get(forField: "non_existent")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Expected DynamicMessageError")
        return
      }

      if case .fieldNotFound(let fieldName) = dynamicError {
        XCTAssertEqual(fieldName, "non_existent")
      }
      else {
        XCTFail("Expected fieldNotFound")
      }
    }

    // Check error when accessing non-existent field by number
    XCTAssertThrowsError(try message.get(forField: 999)) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Expected DynamicMessageError")
        return
      }

      if case .fieldNotFoundByNumber(let fieldNumber) = dynamicError {
        XCTAssertEqual(fieldNumber, 999)
      }
      else {
        XCTFail("Expected fieldNotFoundByNumber")
      }
    }
  }

  // MARK: - Equatable Tests

  func testEquatable() {
    var message1 = DynamicMessage(descriptor: personMessage)
    var message2 = DynamicMessage(descriptor: personMessage)

    // Empty messages should be equal
    XCTAssertEqual(message1, message2)

    do {
      // Add same data
      try message1.set("John Doe", forField: "name")
      try message2.set("John Doe", forField: "name")

      // Messages with same data should be equal
      XCTAssertEqual(message1, message2)

      // Change one field in message2
      try message2.set("Jane Doe", forField: "name")

      // Messages with different data should not be equal
      XCTAssertNotEqual(message1, message2)

      // Set same data again
      try message2.set("John Doe", forField: "name")
      XCTAssertEqual(message1, message2)

      // Add additional field to message1
      try message1.set(Int32(123), forField: "id")

      // Messages should differ if one has field and other doesn't
      XCTAssertNotEqual(message1, message2)

      // Add same field to message2
      try message2.set(Int32(123), forField: "id")

      // Messages should be equal again
      XCTAssertEqual(message1, message2)
    }
    catch {
      XCTFail("Should not have exceptions when testing Equatable: \(error)")
    }
  }

  func testEquatableWithComplexFields() {
    var message1 = DynamicMessage(descriptor: personMessage)
    var message2 = DynamicMessage(descriptor: personMessage)

    do {
      // Setup complex fields
      var address1 = DynamicMessage(descriptor: addressMessage)
      try address1.set("123 Main St", forField: "street")
      try address1.set("Anytown", forField: "city")

      var address2 = DynamicMessage(descriptor: addressMessage)
      try address2.set("123 Main St", forField: "street")
      try address2.set("Anytown", forField: "city")

      // Set addresses
      try message1.set(address1, forField: "address")
      try message2.set(address2, forField: "address")

      // Messages with identical nested messages should be equal
      XCTAssertEqual(message1, message2)

      // Modify one field in address2
      try address2.set("456 Oak St", forField: "street")

      // Update address in message2
      try message2.set(address2, forField: "address")

      // Messages with different nested messages should not be equal
      XCTAssertNotEqual(message1, message2)

      // Set identical repeated fields
      let phoneNumbers = ["+1-555-1234", "+1-555-5678"]
      try message1.set(phoneNumbers, forField: "phone_numbers")
      try message2.set(phoneNumbers, forField: "phone_numbers")

      // Messages should still not be equal due to different addresses
      XCTAssertNotEqual(message1, message2)

      // Fix address in message2
      address2 = DynamicMessage(descriptor: addressMessage)
      try address2.set("123 Main St", forField: "street")
      try address2.set("Anytown", forField: "city")
      try message2.set(address2, forField: "address")

      // Now messages should be equal
      XCTAssertEqual(message1, message2)
    }
    catch {
      XCTFail("Should not have exceptions when testing Equatable for complex fields: \(error)")
    }
  }

  // MARK: - Comprehensive Type Tests

  func testAllScalarTypes() {
    // Create message with all scalar type fields
    var message = MessageDescriptor(name: "AllTypes", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "double_value", number: 1, type: .double))
    message.addField(FieldDescriptor(name: "float_value", number: 2, type: .float))
    message.addField(FieldDescriptor(name: "int32_value", number: 3, type: .int32))
    message.addField(FieldDescriptor(name: "int64_value", number: 4, type: .int64))
    message.addField(FieldDescriptor(name: "uint32_value", number: 5, type: .uint32))
    message.addField(FieldDescriptor(name: "uint64_value", number: 6, type: .uint64))
    message.addField(FieldDescriptor(name: "sint32_value", number: 7, type: .sint32))
    message.addField(FieldDescriptor(name: "sint64_value", number: 8, type: .sint64))
    message.addField(FieldDescriptor(name: "fixed32_value", number: 9, type: .fixed32))
    message.addField(FieldDescriptor(name: "fixed64_value", number: 10, type: .fixed64))
    message.addField(FieldDescriptor(name: "sfixed32_value", number: 11, type: .sfixed32))
    message.addField(FieldDescriptor(name: "sfixed64_value", number: 12, type: .sfixed64))
    message.addField(FieldDescriptor(name: "bool_value", number: 13, type: .bool))
    message.addField(FieldDescriptor(name: "string_value", number: 14, type: .string))
    message.addField(FieldDescriptor(name: "bytes_value", number: 15, type: .bytes))

    fileDescriptor.addMessage(message)

    var dynamicMessage = DynamicMessage(descriptor: message)

    do {
      // Set values of all types
      try dynamicMessage.set(Double(3.14159), forField: "double_value")
      try dynamicMessage.set(Float(2.71828), forField: "float_value")
      try dynamicMessage.set(Int32(42), forField: "int32_value")
      try dynamicMessage.set(Int64(1_234_567_890_123), forField: "int64_value")
      try dynamicMessage.set(UInt32(4_294_967_295), forField: "uint32_value")
      try dynamicMessage.set(UInt64(18_446_744_073_709_551_615), forField: "uint64_value")
      try dynamicMessage.set(Int32(-123), forField: "sint32_value")
      try dynamicMessage.set(Int64(-9_876_543_210), forField: "sint64_value")
      try dynamicMessage.set(UInt32(42), forField: "fixed32_value")
      try dynamicMessage.set(UInt64(42), forField: "fixed64_value")
      try dynamicMessage.set(Int32(-42), forField: "sfixed32_value")
      try dynamicMessage.set(Int64(-42), forField: "sfixed64_value")
      try dynamicMessage.set(true, forField: "bool_value")
      try dynamicMessage.set("Hello, world!", forField: "string_value")
      try dynamicMessage.set(Data("binary data".utf8), forField: "bytes_value")

      // Check all set values
      XCTAssertEqual(try dynamicMessage.get(forField: "double_value") as? Double, 3.14159)
      XCTAssertEqual(try dynamicMessage.get(forField: "float_value") as? Float, 2.71828)
      XCTAssertEqual(try dynamicMessage.get(forField: "int32_value") as? Int32, 42)
      XCTAssertEqual(try dynamicMessage.get(forField: "int64_value") as? Int64, 1_234_567_890_123)
      XCTAssertEqual(try dynamicMessage.get(forField: "uint32_value") as? UInt32, 4_294_967_295)
      XCTAssertEqual(try dynamicMessage.get(forField: "uint64_value") as? UInt64, 18_446_744_073_709_551_615)
      XCTAssertEqual(try dynamicMessage.get(forField: "sint32_value") as? Int32, -123)
      XCTAssertEqual(try dynamicMessage.get(forField: "sint64_value") as? Int64, -9_876_543_210)
      XCTAssertEqual(try dynamicMessage.get(forField: "fixed32_value") as? UInt32, 42)
      XCTAssertEqual(try dynamicMessage.get(forField: "fixed64_value") as? UInt64, 42)
      XCTAssertEqual(try dynamicMessage.get(forField: "sfixed32_value") as? Int32, -42)
      XCTAssertEqual(try dynamicMessage.get(forField: "sfixed64_value") as? Int64, -42)
      XCTAssertEqual(try dynamicMessage.get(forField: "bool_value") as? Bool, true)
      XCTAssertEqual(try dynamicMessage.get(forField: "string_value") as? String, "Hello, world!")
      XCTAssertEqual(try dynamicMessage.get(forField: "bytes_value") as? Data, Data("binary data".utf8))

      // Check conversion from Int to Int32/Int64 types
      try dynamicMessage.set(Int(42), forField: "int32_value")
      XCTAssertEqual(try dynamicMessage.get(forField: "int32_value") as? Int32, 42)

      try dynamicMessage.set(Int(42), forField: "int64_value")
      XCTAssertEqual(try dynamicMessage.get(forField: "int64_value") as? Int64, 42)

      // Check conversion from UInt to UInt32/UInt64 types
      try dynamicMessage.set(UInt(42), forField: "uint32_value")
      XCTAssertEqual(try dynamicMessage.get(forField: "uint32_value") as? UInt32, 42)

      try dynamicMessage.set(UInt(42), forField: "uint64_value")
      XCTAssertEqual(try dynamicMessage.get(forField: "uint64_value") as? UInt64, 42)

      // Check NSNumber for numeric types
      let doubleNumber = NSNumber(value: 3.14159)
      try dynamicMessage.set(doubleNumber, forField: "double_value")
      XCTAssertEqual(try dynamicMessage.get(forField: "double_value") as? Double, 3.14159)

      let floatNumber = NSNumber(value: 2.71828 as Float)
      try dynamicMessage.set(floatNumber, forField: "float_value")
      XCTAssertEqual(try dynamicMessage.get(forField: "float_value") as? Float, 2.71828)
    }
    catch {
      XCTFail("Should not have exceptions when working with scalar types: \(error)")
    }

    // Check type errors for different fields
    XCTAssertThrowsError(try dynamicMessage.set("not a number", forField: "double_value"))
    XCTAssertThrowsError(try dynamicMessage.set("not a number", forField: "float_value"))
    XCTAssertThrowsError(try dynamicMessage.set("not a number", forField: "int32_value"))
    XCTAssertThrowsError(try dynamicMessage.set("not a number", forField: "int64_value"))
    XCTAssertThrowsError(try dynamicMessage.set("not a number", forField: "uint32_value"))
    XCTAssertThrowsError(try dynamicMessage.set("not a number", forField: "uint64_value"))
    XCTAssertThrowsError(try dynamicMessage.set("not a boolean", forField: "bool_value"))
    XCTAssertThrowsError(try dynamicMessage.set(42, forField: "string_value"))
    XCTAssertThrowsError(try dynamicMessage.set("not binary data", forField: "bytes_value"))

    // Check errors for Int32 values out of range
    XCTAssertThrowsError(try dynamicMessage.set(Int(Int32.max) + 1, forField: "int32_value"))
    XCTAssertThrowsError(try dynamicMessage.set(Int(Int32.min) - 1, forField: "int32_value"))

    // Check errors for UInt32 values out of range
    XCTAssertThrowsError(try dynamicMessage.set(UInt(UInt32.max) + 1, forField: "uint32_value"))
  }

  func testComplexMapFieldOperations() {
    // Create message with different types of map fields
    var messageDesc = MessageDescriptor(name: "MapTypes", parent: fileDescriptor)

    // Map string -> string
    let stringMapKeyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let stringMapValueInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let stringMapEntryInfo = MapEntryInfo(keyFieldInfo: stringMapKeyInfo, valueFieldInfo: stringMapValueInfo)
    messageDesc.addField(
      FieldDescriptor(
        name: "string_map",
        number: 1,
        type: .message,
        typeName: "map<string, string>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: stringMapEntryInfo
      )
    )

    // Map int32 -> string
    let int32MapKeyInfo = KeyFieldInfo(name: "key", number: 1, type: .int32)
    let int32MapValueInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let int32MapEntryInfo = MapEntryInfo(keyFieldInfo: int32MapKeyInfo, valueFieldInfo: int32MapValueInfo)
    messageDesc.addField(
      FieldDescriptor(
        name: "int32_map",
        number: 2,
        type: .message,
        typeName: "map<int32, string>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: int32MapEntryInfo
      )
    )

    // Map bool -> int32
    let boolMapKeyInfo = KeyFieldInfo(name: "key", number: 1, type: .bool)
    let boolMapValueInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let boolMapEntryInfo = MapEntryInfo(keyFieldInfo: boolMapKeyInfo, valueFieldInfo: boolMapValueInfo)
    messageDesc.addField(
      FieldDescriptor(
        name: "bool_map",
        number: 3,
        type: .message,
        typeName: "map<bool, int32>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: boolMapEntryInfo
      )
    )

    fileDescriptor.addMessage(messageDesc)

    var message = DynamicMessage(descriptor: messageDesc)

    do {
      // Check operations with string -> string map
      try message.setMapEntry("value1", forKey: "key1", inField: "string_map")
      try message.setMapEntry("value2", forKey: "key2", inField: "string_map")

      let stringMap = try message.get(forField: "string_map") as? [String: String]
      XCTAssertEqual(stringMap?["key1"], "value1")
      XCTAssertEqual(stringMap?["key2"], "value2")

      // Overwrite value
      try message.setMapEntry("new_value", forKey: "key1", inField: "string_map")
      let updatedStringMap = try message.get(forField: "string_map") as? [String: String]
      XCTAssertEqual(updatedStringMap?["key1"], "new_value")

      // Check operations with int32 -> string map
      try message.setMapEntry("value1", forKey: Int32(1), inField: "int32_map")
      try message.setMapEntry("value2", forKey: Int32(2), inField: "int32_map")
      try message.setMapEntry("value3", forKey: 3, inField: "int32_map")  // Use Int instead of Int32

      let int32Map = try message.get(forField: "int32_map") as? [AnyHashable: String]
      XCTAssertEqual(int32Map?[Int32(1)] as? String, "value1")
      XCTAssertEqual(int32Map?[Int32(2)] as? String, "value2")
      XCTAssertEqual(int32Map?[Int32(3)] as? String, "value3")

      // Check operations with bool -> int32 map
      try message.setMapEntry(Int32(100), forKey: true, inField: "bool_map")
      try message.setMapEntry(Int32(200), forKey: false, inField: "bool_map")

      let boolMap = try message.get(forField: "bool_map") as? [Bool: Int32]
      XCTAssertEqual(boolMap?[true], 100)
      XCTAssertEqual(boolMap?[false], 200)

      // Clear map field
      try message.clearField("string_map")
      XCTAssertFalse(try message.hasValue(forField: "string_map"))

      // Set entire dictionary
      let newMap = ["new1": "value1", "new2": "value2", "new3": "value3"]
      try message.set(newMap, forField: "string_map")

      let finalMap = try message.get(forField: "string_map") as? [String: String]
      XCTAssertEqual(finalMap?.count, 3)
      XCTAssertEqual(finalMap?["new1"], "value1")
      XCTAssertEqual(finalMap?["new2"], "value2")
      XCTAssertEqual(finalMap?["new3"], "value3")

    }
    catch {
      XCTFail("Should not have exceptions when working with map fields: \(error)")
    }

    // Check type errors for map fields
    XCTAssertThrowsError(try message.setMapEntry(42, forKey: "key", inField: "string_map"))
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: 42, inField: "string_map"))
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: true, inField: "string_map"))
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: "key", inField: "non_existent_map"))
    XCTAssertThrowsError(try message.set("not a map", forField: "string_map"))
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: "key", inField: "name"))  // not a map field
  }

  func testRepeatedFieldOperations() {
    // Message with different repeated fields
    var messageDesc = MessageDescriptor(name: "RepeatedTypes", parent: fileDescriptor)
    messageDesc.addField(
      FieldDescriptor(
        name: "repeated_string",
        number: 1,
        type: .string,
        isRepeated: true
      )
    )
    messageDesc.addField(
      FieldDescriptor(
        name: "repeated_int32",
        number: 2,
        type: .int32,
        isRepeated: true
      )
    )
    messageDesc.addField(
      FieldDescriptor(
        name: "repeated_message",
        number: 3,
        type: .message,
        typeName: "test.Address",
        isRepeated: true
      )
    )

    fileDescriptor.addMessage(messageDesc)

    var message = DynamicMessage(descriptor: messageDesc)

    do {
      // Add string elements
      try message.addRepeatedValue("first", forField: "repeated_string")
      try message.addRepeatedValue("second", forField: "repeated_string")
      try message.addRepeatedValue("third", forField: "repeated_string")

      var strings = try message.get(forField: "repeated_string") as? [String]
      XCTAssertEqual(strings?.count, 3)
      XCTAssertEqual(strings?[0], "first")
      XCTAssertEqual(strings?[1], "second")
      XCTAssertEqual(strings?[2], "third")

      // Replace entire array
      let newStrings = ["new1", "new2"]
      try message.set(newStrings, forField: "repeated_string")

      strings = try message.get(forField: "repeated_string") as? [String]
      XCTAssertEqual(strings?.count, 2)
      XCTAssertEqual(strings?[0], "new1")
      XCTAssertEqual(strings?[1], "new2")

      // Add Int32 elements
      try message.addRepeatedValue(Int32(10), forField: "repeated_int32")
      try message.addRepeatedValue(Int32(20), forField: "repeated_int32")
      try message.addRepeatedValue(Int(30), forField: "repeated_int32")  // Use Int instead of Int32

      let repeatedInt32 = try message.get(forField: "repeated_int32") as? [Any]
      XCTAssertEqual(repeatedInt32?.count, 3)
      XCTAssertEqual(repeatedInt32?[0] as? Int32, 10)
      XCTAssertEqual(repeatedInt32?[1] as? Int32, 20)

      // Int can be stored as Int or Int32, check both variants
      if let value = repeatedInt32?[2] as? Int32 {
        XCTAssertEqual(value, 30)
      }
      else if let value = repeatedInt32?[2] as? Int {
        XCTAssertEqual(value, 30)
      }
      else {
        XCTFail("Value should be Int32 or Int")
      }

      // Add nested messages
      var address1 = DynamicMessage(descriptor: addressMessage)
      try address1.set("123 Main St", forField: "street")
      try address1.set("New York", forField: "city")

      var address2 = DynamicMessage(descriptor: addressMessage)
      try address2.set("456 Oak Ave", forField: "street")
      try address2.set("San Francisco", forField: "city")

      try message.addRepeatedValue(address1, forField: "repeated_message")
      try message.addRepeatedValue(address2, forField: "repeated_message")

      let addresses = try message.get(forField: "repeated_message") as? [DynamicMessage]
      XCTAssertEqual(addresses?.count, 2)

      let addr1 = addresses?[0]
      XCTAssertEqual(try addr1?.get(forField: "street") as? String, "123 Main St")
      XCTAssertEqual(try addr1?.get(forField: "city") as? String, "New York")

      let addr2 = addresses?[1]
      XCTAssertEqual(try addr2?.get(forField: "street") as? String, "456 Oak Ave")
      XCTAssertEqual(try addr2?.get(forField: "city") as? String, "San Francisco")

      // Clear repeated field
      try message.clearField("repeated_string")
      XCTAssertFalse(try message.hasValue(forField: "repeated_string"))

    }
    catch {
      XCTFail("Should not have exceptions when working with repeated fields: \(error)")
    }

    // Check type errors for repeated fields
    XCTAssertThrowsError(try message.addRepeatedValue(42, forField: "repeated_string"))
    XCTAssertThrowsError(try message.addRepeatedValue("string", forField: "repeated_int32"))
    XCTAssertThrowsError(
      try message.addRepeatedValue(DynamicMessage(descriptor: personMessage), forField: "repeated_message")
    )
    XCTAssertThrowsError(try message.addRepeatedValue("value", forField: "name"))  // not a repeated field
    XCTAssertThrowsError(try message.set("not an array", forField: "repeated_string"))

    // Check type errors for array elements
    let mixedArray: [Any] = ["string", 42, true]
    XCTAssertThrowsError(try message.set(mixedArray, forField: "repeated_string"))
  }

  func testDefaultValues() {
    // Create message with fields with default values
    var messageDesc = MessageDescriptor(name: "DefaultValues", parent: fileDescriptor)
    messageDesc.addField(
      FieldDescriptor(
        name: "string_with_default",
        number: 1,
        type: .string,
        defaultValue: "default"
      )
    )
    messageDesc.addField(
      FieldDescriptor(
        name: "int32_with_default",
        number: 2,
        type: .int32,
        defaultValue: Int32(42)
      )
    )
    messageDesc.addField(
      FieldDescriptor(
        name: "bool_with_default",
        number: 3,
        type: .bool,
        defaultValue: true
      )
    )
    messageDesc.addField(
      FieldDescriptor(
        name: "string_without_default",
        number: 4,
        type: .string
      )
    )

    fileDescriptor.addMessage(messageDesc)

    let message = DynamicMessage(descriptor: messageDesc)

    do {
      // Get default values
      if let defaultStr = try message.get(forField: "string_with_default") as? String {
        XCTAssertEqual(defaultStr, "default")
      }

      if let defaultInt = try message.get(forField: "int32_with_default") as? Int32 {
        XCTAssertEqual(defaultInt, 42)
      }

      if let defaultBool = try message.get(forField: "bool_with_default") as? Bool {
        XCTAssertEqual(defaultBool, true)
      }

      // Field without default value should return nil
      XCTAssertNil(try message.get(forField: "string_without_default"))

      // hasValue should return false since value was not explicitly set
      XCTAssertFalse(try message.hasValue(forField: "string_with_default"))
      XCTAssertFalse(try message.hasValue(forField: "int32_with_default"))
      XCTAssertFalse(try message.hasValue(forField: "bool_with_default"))
      XCTAssertFalse(try message.hasValue(forField: "string_without_default"))
    }
    catch {
      XCTFail("Should not have exceptions when working with default values: \(error)")
    }
  }

  func testComprehensiveEquatable() {
    // Create test for areValuesEqual method and comparison of different field types
    var message = MessageDescriptor(name: "EquatableTest", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "double_value", number: 1, type: .double))
    message.addField(FieldDescriptor(name: "float_value", number: 2, type: .float))
    message.addField(FieldDescriptor(name: "int32_value", number: 3, type: .int32))
    message.addField(FieldDescriptor(name: "int64_value", number: 4, type: .int64))
    message.addField(FieldDescriptor(name: "uint32_value", number: 5, type: .uint32))
    message.addField(FieldDescriptor(name: "uint64_value", number: 6, type: .uint64))
    message.addField(FieldDescriptor(name: "bool_value", number: 7, type: .bool))
    message.addField(FieldDescriptor(name: "string_value", number: 8, type: .string))
    message.addField(FieldDescriptor(name: "bytes_value", number: 9, type: .bytes))
    message.addField(FieldDescriptor(name: "enum_value", number: 10, type: .enum, typeName: "test.PhoneType"))

    fileDescriptor.addMessage(message)

    var msg1 = DynamicMessage(descriptor: message)
    var msg2 = DynamicMessage(descriptor: message)

    do {
      // Double
      try msg1.set(1.0, forField: "double_value")
      try msg2.set(1.0, forField: "double_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set(2.0, forField: "double_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set(1.0, forField: "double_value")
      XCTAssertEqual(msg1, msg2)

      // Float
      try msg1.set(Float(1.0), forField: "float_value")
      try msg2.set(Float(1.0), forField: "float_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set(Float(2.0), forField: "float_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set(Float(1.0), forField: "float_value")
      XCTAssertEqual(msg1, msg2)

      // Int32
      try msg1.set(Int32(10), forField: "int32_value")
      try msg2.set(Int32(10), forField: "int32_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set(Int32(20), forField: "int32_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set(Int32(10), forField: "int32_value")
      XCTAssertEqual(msg1, msg2)

      // Int64
      try msg1.set(Int64(1000), forField: "int64_value")
      try msg2.set(Int64(1000), forField: "int64_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set(Int64(2000), forField: "int64_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set(Int64(1000), forField: "int64_value")
      XCTAssertEqual(msg1, msg2)

      // UInt32
      try msg1.set(UInt32(10), forField: "uint32_value")
      try msg2.set(UInt32(10), forField: "uint32_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set(UInt32(20), forField: "uint32_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set(UInt32(10), forField: "uint32_value")
      XCTAssertEqual(msg1, msg2)

      // UInt64
      try msg1.set(UInt64(1000), forField: "uint64_value")
      try msg2.set(UInt64(1000), forField: "uint64_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set(UInt64(2000), forField: "uint64_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set(UInt64(1000), forField: "uint64_value")
      XCTAssertEqual(msg1, msg2)

      // Bool
      try msg1.set(true, forField: "bool_value")
      try msg2.set(true, forField: "bool_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set(false, forField: "bool_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set(true, forField: "bool_value")
      XCTAssertEqual(msg1, msg2)

      // String
      try msg1.set("test", forField: "string_value")
      try msg2.set("test", forField: "string_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set("different", forField: "string_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set("test", forField: "string_value")
      XCTAssertEqual(msg1, msg2)

      // Bytes
      let data1 = Data("binary".utf8)
      let data2 = Data("different".utf8)

      try msg1.set(data1, forField: "bytes_value")
      try msg2.set(data1, forField: "bytes_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set(data2, forField: "bytes_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set(data1, forField: "bytes_value")
      XCTAssertEqual(msg1, msg2)

      // Enum (as number)
      try msg1.set(Int32(0), forField: "enum_value")
      try msg2.set(Int32(0), forField: "enum_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set(Int32(1), forField: "enum_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set(Int32(0), forField: "enum_value")
      XCTAssertEqual(msg1, msg2)

      // Enum (as string)
      try msg1.set("MOBILE", forField: "enum_value")
      try msg2.set("MOBILE", forField: "enum_value")
      XCTAssertEqual(msg1, msg2)

      try msg2.set("HOME", forField: "enum_value")
      XCTAssertNotEqual(msg1, msg2)

      try msg2.set("MOBILE", forField: "enum_value")
      XCTAssertEqual(msg1, msg2)

      // Comparison of different enum types - should not be equal
      try msg1.set(Int32(0), forField: "enum_value")
      try msg2.set("MOBILE", forField: "enum_value")
      XCTAssertNotEqual(msg1, msg2)
    }
    catch {
      XCTFail("Should not have exceptions when checking Equatable: \(error)")
    }
  }

  func testErrorDescriptions() {
    // Check localized error descriptions
    let fieldNameError = DynamicMessageError.fieldNotFound(fieldName: "test_field")
    XCTAssertEqual(fieldNameError.errorDescription, "Field with name 'test_field' not found")

    let fieldNumberError = DynamicMessageError.fieldNotFoundByNumber(fieldNumber: 42)
    XCTAssertEqual(fieldNumberError.errorDescription, "Field with number 42 not found")

    let typeMismatchError = DynamicMessageError.typeMismatch(
      fieldName: "test_field",
      expectedType: "String",
      actualType: "Int"
    )
    XCTAssertTrue(typeMismatchError.errorDescription?.contains("Type mismatch for field 'test_field'") ?? false)
    XCTAssertTrue(typeMismatchError.errorDescription?.contains("expected String") ?? false)

    let messageMismatchError = DynamicMessageError.messageMismatch(
      fieldName: "message_field",
      expectedType: "test.Person",
      actualType: "test.Address"
    )
    XCTAssertTrue(
      messageMismatchError.errorDescription?.contains("Message type mismatch for field 'message_field'") ?? false
    )
    XCTAssertTrue(messageMismatchError.errorDescription?.contains("expected test.Person") ?? false)
    XCTAssertTrue(messageMismatchError.errorDescription?.contains("got test.Address") ?? false)

    let notRepeatedError = DynamicMessageError.notRepeatedField(fieldName: "test_field")
    XCTAssertEqual(notRepeatedError.errorDescription, "Field 'test_field' is not a repeated field")

    let notMapError = DynamicMessageError.notMapField(fieldName: "test_field")
    XCTAssertEqual(notMapError.errorDescription, "Field 'test_field' is not a map field")

    let invalidMapKeyTypeError = DynamicMessageError.invalidMapKeyType(type: .double)
    XCTAssertEqual(invalidMapKeyTypeError.errorDescription, "Invalid key type double for map field")
  }
}
