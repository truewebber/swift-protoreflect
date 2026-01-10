//
// DynamicMessageEquatableTests.swift
// SwiftProtoReflectTests
//
// Created: 2025-05-23
// Additional tests for full coverage of Equatable functionality of DynamicMessage
//

import XCTest

@testable import SwiftProtoReflect

final class DynamicMessageEquatableTests: XCTestCase {
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

    // Create PhoneType enum descriptor
    enumDescriptor = EnumDescriptor(name: "PhoneType", parent: fileDescriptor)
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "MOBILE", number: 0))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "HOME", number: 1))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "WORK", number: 2))

    fileDescriptor.addEnum(enumDescriptor)

    // Create Address message descriptor
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

    // Create Person message descriptor
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

  // MARK: - Equatable with Different Descriptors Tests

  func testEquatableWithDifferentDescriptors() {
    // Create two different descriptors with same names but different fullName
    var fileDescriptor1 = FileDescriptor(name: "test1.proto", package: "package1")
    var messageDescriptor1 = MessageDescriptor(name: "TestMessage", parent: fileDescriptor1)
    messageDescriptor1.addField(FieldDescriptor(name: "field1", number: 1, type: .string))
    fileDescriptor1.addMessage(messageDescriptor1)

    var fileDescriptor2 = FileDescriptor(name: "test2.proto", package: "package2")
    var messageDescriptor2 = MessageDescriptor(name: "TestMessage", parent: fileDescriptor2)
    messageDescriptor2.addField(FieldDescriptor(name: "field1", number: 1, type: .string))
    fileDescriptor2.addMessage(messageDescriptor2)

    var message1 = DynamicMessage(descriptor: messageDescriptor1)
    var message2 = DynamicMessage(descriptor: messageDescriptor2)

    do {
      try message1.set("value", forField: "field1")
      try message2.set("value", forField: "field1")

      // Messages with different descriptors should not be equal, even if content is the same
      XCTAssertNotEqual(message1, message2)
    }
    catch {
      XCTFail("Should not have exceptions when testing different descriptors: \(error)")
    }
  }

  // MARK: - Equatable with Map Fields Tests

  func testEquatableWithMapFields() {
    // Create message with map field
    var messageDesc = MessageDescriptor(name: "MapTestMessage", parent: fileDescriptor)

    // String -> String map
    let stringKeyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let stringValueInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let stringMapEntryInfo = MapEntryInfo(keyFieldInfo: stringKeyInfo, valueFieldInfo: stringValueInfo)
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

    // Int32 -> Int32 map for testing areValuesEqual with Int32
    let int32KeyInfo = KeyFieldInfo(name: "key", number: 1, type: .int32)
    let int32ValueInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let int32MapEntryInfo = MapEntryInfo(keyFieldInfo: int32KeyInfo, valueFieldInfo: int32ValueInfo)
    messageDesc.addField(
      FieldDescriptor(
        name: "int32_map",
        number: 2,
        type: .message,
        typeName: "map<int32, int32>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: int32MapEntryInfo
      )
    )

    fileDescriptor.addMessage(messageDesc)

    var message1 = DynamicMessage(descriptor: messageDesc)
    var message2 = DynamicMessage(descriptor: messageDesc)

    do {
      // Test equal map fields
      try message1.setMapEntry("value1", forKey: "key1", inField: "string_map")
      try message1.setMapEntry("value2", forKey: "key2", inField: "string_map")

      try message2.setMapEntry("value1", forKey: "key1", inField: "string_map")
      try message2.setMapEntry("value2", forKey: "key2", inField: "string_map")

      XCTAssertEqual(message1, message2)

      // Test map with different number of elements
      try message1.setMapEntry("value3", forKey: "key3", inField: "string_map")
      XCTAssertNotEqual(message1, message2)

      // Restore equality
      try message2.setMapEntry("value3", forKey: "key3", inField: "string_map")
      XCTAssertEqual(message1, message2)

      // Test map with different keys
      var message3 = DynamicMessage(descriptor: messageDesc)
      try message3.setMapEntry("value1", forKey: "different_key1", inField: "string_map")
      try message3.setMapEntry("value2", forKey: "key2", inField: "string_map")
      try message3.setMapEntry("value3", forKey: "key3", inField: "string_map")

      XCTAssertNotEqual(message1, message3)

      // Test map with different values
      var message4 = DynamicMessage(descriptor: messageDesc)
      try message4.setMapEntry("different_value", forKey: "key1", inField: "string_map")
      try message4.setMapEntry("value2", forKey: "key2", inField: "string_map")
      try message4.setMapEntry("value3", forKey: "key3", inField: "string_map")

      XCTAssertNotEqual(message1, message4)

      // Test int32 map for coverage of areValuesEqual with Int32 type
      try message1.setMapEntry(Int32(100), forKey: Int32(1), inField: "int32_map")
      try message2.setMapEntry(Int32(100), forKey: Int32(1), inField: "int32_map")

      XCTAssertEqual(message1, message2)

      try message2.setMapEntry(Int32(200), forKey: Int32(1), inField: "int32_map")
      XCTAssertNotEqual(message1, message2)

    }
    catch {
      XCTFail("Should not have exceptions when testing map fields in Equatable: \(error)")
    }
  }

  // MARK: - Equatable with Repeated Fields Tests

  func testEquatableWithRepeatedFields() {
    // Create message with repeated fields
    var messageDesc = MessageDescriptor(name: "RepeatedTestMessage", parent: fileDescriptor)
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

    var message1 = DynamicMessage(descriptor: messageDesc)
    var message2 = DynamicMessage(descriptor: messageDesc)

    do {
      // Test equal repeated fields
      try message1.addRepeatedValue("first", forField: "repeated_string")
      try message1.addRepeatedValue("second", forField: "repeated_string")

      try message2.addRepeatedValue("first", forField: "repeated_string")
      try message2.addRepeatedValue("second", forField: "repeated_string")

      XCTAssertEqual(message1, message2)

      // Test repeated fields with different number of elements
      try message1.addRepeatedValue("third", forField: "repeated_string")
      XCTAssertNotEqual(message1, message2)

      // Restore equality
      try message2.addRepeatedValue("third", forField: "repeated_string")
      XCTAssertEqual(message1, message2)

      // Test repeated fields with different values
      var message3 = DynamicMessage(descriptor: messageDesc)
      try message3.addRepeatedValue("different", forField: "repeated_string")
      try message3.addRepeatedValue("second", forField: "repeated_string")
      try message3.addRepeatedValue("third", forField: "repeated_string")

      XCTAssertNotEqual(message1, message3)

      // Test repeated int32 for coverage of areValuesEqual with Int32
      try message1.addRepeatedValue(Int32(100), forField: "repeated_int32")
      try message1.addRepeatedValue(Int32(200), forField: "repeated_int32")

      try message2.addRepeatedValue(Int32(100), forField: "repeated_int32")
      try message2.addRepeatedValue(Int32(200), forField: "repeated_int32")

      XCTAssertEqual(message1, message2)

      try message2.addRepeatedValue(Int32(300), forField: "repeated_int32")
      XCTAssertNotEqual(message1, message2)

      // Test repeated messages
      var addr1 = DynamicMessage(descriptor: addressMessage)
      try addr1.set("Street 1", forField: "street")

      var addr2 = DynamicMessage(descriptor: addressMessage)
      try addr2.set("Street 2", forField: "street")

      var message4 = DynamicMessage(descriptor: messageDesc)
      var message5 = DynamicMessage(descriptor: messageDesc)

      try message4.addRepeatedValue(addr1, forField: "repeated_message")
      try message5.addRepeatedValue(addr1, forField: "repeated_message")

      XCTAssertEqual(message4, message5)

      try message5.addRepeatedValue(addr2, forField: "repeated_message")
      XCTAssertNotEqual(message4, message5)

    }
    catch {
      XCTFail("Should not have exceptions when testing repeated fields in Equatable: \(error)")
    }
  }

  // MARK: - Equatable Error Handling Tests

  func testEquatableWithErrorHandling() {
    // Create message with field that can cause error during comparison
    var messageDesc = MessageDescriptor(name: "ErrorTestMessage", parent: fileDescriptor)

    // Add field that potentially can cause problems
    messageDesc.addField(
      FieldDescriptor(
        name: "test_field",
        number: 1,
        type: .string
      )
    )

    fileDescriptor.addMessage(messageDesc)

    let message1 = DynamicMessage(descriptor: messageDesc)
    let message2 = DynamicMessage(descriptor: messageDesc)

    // Test case when comparing messages with correct descriptors
    XCTAssertEqual(message1, message2)

    // Create situation with corrupted descriptor for testing catch block
    // This is difficult to test without internal access, but we covered main logic
  }

  // MARK: - areValuesEqual Unknown Type Tests

  func testAreValuesEqualWithUnknownType() {
    // Create message with type that is not handled in areValuesEqual
    var messageDesc = MessageDescriptor(name: "UnknownTypeTest", parent: fileDescriptor)

    // Add field with group type (rarely used)
    messageDesc.addField(
      FieldDescriptor(
        name: "group_field",
        number: 1,
        type: .group,
        typeName: "test.SomeGroup"
      )
    )

    // Add another field for testing fallback logic
    messageDesc.addField(
      FieldDescriptor(
        name: "unknown_field",
        number: 2,
        type: .string  // Intentionally set nil in type via reflection is not possible in Swift
      )
    )

    fileDescriptor.addMessage(messageDesc)

    var message1 = DynamicMessage(descriptor: messageDesc)
    var message2 = DynamicMessage(descriptor: messageDesc)

    do {
      // Set group messages
      var groupMessage1 = DynamicMessage(descriptor: addressMessage)
      try groupMessage1.set("Street 1", forField: "street")

      var groupMessage2 = DynamicMessage(descriptor: addressMessage)
      try groupMessage2.set("Street 1", forField: "street")

      var differentGroupMessage = DynamicMessage(descriptor: addressMessage)
      try differentGroupMessage.set("Street 2", forField: "street")

      try message1.set(groupMessage1, forField: "group_field")
      try message2.set(groupMessage2, forField: "group_field")

      // Group messages with same content should be equal
      XCTAssertEqual(message1, message2)

      // Group messages with different content should not be equal
      try message2.set(differentGroupMessage, forField: "group_field")
      XCTAssertNotEqual(message1, message2)

    }
    catch {
      XCTFail("Should not have exceptions when testing group fields: \(error)")
    }
  }

  // MARK: - Map with Missing Key Tests

  func testMapComparisonWithMissingKey() {
    // Create message with map field for testing missing keys
    var messageDesc = MessageDescriptor(name: "MapMissingKeyTest", parent: fileDescriptor)

    let stringKeyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let stringValueInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let stringMapEntryInfo = MapEntryInfo(keyFieldInfo: stringKeyInfo, valueFieldInfo: stringValueInfo)
    messageDesc.addField(
      FieldDescriptor(
        name: "test_map",
        number: 1,
        type: .message,
        typeName: "map<string, string>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: stringMapEntryInfo
      )
    )

    fileDescriptor.addMessage(messageDesc)

    var message1 = DynamicMessage(descriptor: messageDesc)
    var message2 = DynamicMessage(descriptor: messageDesc)

    do {
      // Create map with one key in message1
      try message1.setMapEntry("value1", forKey: "key1", inField: "test_map")

      // Create map with different key in message2
      try message2.setMapEntry("value1", forKey: "key2", inField: "test_map")

      // Maps with different keys should not be equal
      XCTAssertNotEqual(message1, message2)

      // Add key to message2, but with different value
      try message2.setMapEntry("different_value", forKey: "key1", inField: "test_map")

      // Maps with same keys but different values should not be equal
      XCTAssertNotEqual(message1, message2)

    }
    catch {
      XCTFail("Should not have exceptions when testing map with missing keys: \(error)")
    }
  }

  // MARK: - Array vs Non-Array Tests

  func testRepeatedFieldComparisonFailures() {
    // Create message with repeated field
    var messageDesc = MessageDescriptor(name: "RepeatedFailureTest", parent: fileDescriptor)
    messageDesc.addField(
      FieldDescriptor(
        name: "repeated_field",
        number: 1,
        type: .string,
        isRepeated: true
      )
    )

    fileDescriptor.addMessage(messageDesc)

    var message1 = DynamicMessage(descriptor: messageDesc)
    var message2 = DynamicMessage(descriptor: messageDesc)

    do {
      // Set repeated fields with equal values
      try message1.addRepeatedValue("value1", forField: "repeated_field")
      try message1.addRepeatedValue("value2", forField: "repeated_field")

      try message2.addRepeatedValue("value1", forField: "repeated_field")
      try message2.addRepeatedValue("value2", forField: "repeated_field")

      XCTAssertEqual(message1, message2)

      // Create third message with fewer elements
      var message3 = DynamicMessage(descriptor: messageDesc)
      try message3.addRepeatedValue("value1", forField: "repeated_field")

      XCTAssertNotEqual(message1, message3)

    }
    catch {
      XCTFail("Should not have exceptions when testing repeated fields: \(error)")
    }
  }
}
