//
// FieldAccessorTests.swift
// SwiftProtoReflectTests
//
// Created: 2025-05-24
//

import XCTest

@testable import SwiftProtoReflect

final class FieldAccessorTests: XCTestCase {

  // MARK: - Test Properties

  var fileDescriptor: FileDescriptor!
  var messageDescriptor: MessageDescriptor!
  var personMessage: DynamicMessage!

  // MARK: - Setup and Teardown

  override func setUp() {
    super.setUp()

    // Create file descriptor
    fileDescriptor = FileDescriptor(name: "test.proto", package: "test")

    // Create message descriptor Person
    messageDescriptor = MessageDescriptor(name: "Person", parent: fileDescriptor)

    // Add fields
    messageDescriptor.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    messageDescriptor.addField(FieldDescriptor(name: "age", number: 2, type: .int32))
    messageDescriptor.addField(FieldDescriptor(name: "height", number: 3, type: .double))
    messageDescriptor.addField(FieldDescriptor(name: "weight", number: 4, type: .float))
    messageDescriptor.addField(FieldDescriptor(name: "is_active", number: 5, type: .bool))
    messageDescriptor.addField(FieldDescriptor(name: "avatar", number: 6, type: .bytes))
    messageDescriptor.addField(FieldDescriptor(name: "user_id", number: 7, type: .int64))
    messageDescriptor.addField(FieldDescriptor(name: "score", number: 8, type: .uint32))
    messageDescriptor.addField(FieldDescriptor(name: "total_score", number: 9, type: .uint64))

    // Repeated fields
    messageDescriptor.addField(FieldDescriptor(name: "tags", number: 10, type: .string, isRepeated: true))
    messageDescriptor.addField(FieldDescriptor(name: "numbers", number: 11, type: .int32, isRepeated: true))
    messageDescriptor.addField(FieldDescriptor(name: "scores", number: 12, type: .int64, isRepeated: true))

    // Map fields
    let stringMapField = FieldDescriptor(
      name: "attributes",
      number: 13,
      type: .string,
      isMap: true,
      mapEntryInfo: MapEntryInfo(
        keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
        valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .string)
      )
    )
    messageDescriptor.addField(stringMapField)

    let stringToInt32MapField = FieldDescriptor(
      name: "counters",
      number: 14,
      type: .int32,
      isMap: true,
      mapEntryInfo: MapEntryInfo(
        keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
        valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .int32)
      )
    )
    messageDescriptor.addField(stringToInt32MapField)

    // Nested message field
    var addressDescriptor = MessageDescriptor(name: "Address", parent: fileDescriptor)
    addressDescriptor.addField(FieldDescriptor(name: "street", number: 1, type: .string))
    addressDescriptor.addField(FieldDescriptor(name: "city", number: 2, type: .string))

    let addressField = FieldDescriptor(name: "address", number: 15, type: .message, typeName: "test.Address")
    messageDescriptor.addField(addressField)

    // Repeated messages field
    var phoneDescriptor = MessageDescriptor(name: "Phone", parent: fileDescriptor)
    phoneDescriptor.addField(FieldDescriptor(name: "number", number: 1, type: .string))
    phoneDescriptor.addField(FieldDescriptor(name: "type", number: 2, type: .string))

    let phonesField = FieldDescriptor(
      name: "phones",
      number: 16,
      type: .message,
      typeName: "test.Phone",
      isRepeated: true
    )
    messageDescriptor.addField(phonesField)

    // Map with message values field
    let messageMapField = FieldDescriptor(
      name: "contacts",
      number: 17,
      type: .message,
      typeName: "test.Phone",
      isMap: true,
      mapEntryInfo: MapEntryInfo(
        keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
        valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .message, typeName: "test.Phone")
      )
    )
    messageDescriptor.addField(messageMapField)

    // Create empty message
    personMessage = DynamicMessage(descriptor: messageDescriptor)
  }

  // MARK: - Basic Field Access Tests

  func testStringFieldAccess() throws {
    // Test getting non-existent field
    let accessor = personMessage.fieldAccessor
    XCTAssertNil(accessor.getString("name"))
    XCTAssertNil(accessor.getString(1))

    // Set value and check retrieval
    try personMessage.set("John Doe", forField: "name")

    let updatedAccessor = personMessage.fieldAccessor
    XCTAssertEqual(updatedAccessor.getString("name"), "John Doe")
    XCTAssertEqual(updatedAccessor.getString(1), "John Doe")
  }

  func testInt32FieldAccess() throws {
    let accessor = personMessage.fieldAccessor
    XCTAssertNil(accessor.getInt32("age"))
    XCTAssertNil(accessor.getInt32(2))

    try personMessage.set(Int32(25), forField: "age")

    let updatedAccessor = personMessage.fieldAccessor
    XCTAssertEqual(updatedAccessor.getInt32("age"), 25)
    XCTAssertEqual(updatedAccessor.getInt32(2), 25)
  }

  func testInt64FieldAccess() throws {
    let accessor = personMessage.fieldAccessor
    XCTAssertNil(accessor.getInt64("user_id"))
    XCTAssertNil(accessor.getInt64(7))

    try personMessage.set(Int64(123_456_789), forField: "user_id")

    let updatedAccessor = personMessage.fieldAccessor
    XCTAssertEqual(updatedAccessor.getInt64("user_id"), 123_456_789)
    XCTAssertEqual(updatedAccessor.getInt64(7), 123_456_789)
  }

  func testUInt32FieldAccess() throws {
    let accessor = personMessage.fieldAccessor
    XCTAssertNil(accessor.getUInt32("score"))
    XCTAssertNil(accessor.getUInt32(8))

    try personMessage.set(UInt32(100), forField: "score")

    let updatedAccessor = personMessage.fieldAccessor
    XCTAssertEqual(updatedAccessor.getUInt32("score"), 100)
    XCTAssertEqual(updatedAccessor.getUInt32(8), 100)
  }

  func testUInt64FieldAccess() throws {
    let accessor = personMessage.fieldAccessor
    XCTAssertNil(accessor.getUInt64("total_score"))
    XCTAssertNil(accessor.getUInt64(9))

    try personMessage.set(UInt64(987_654_321), forField: "total_score")

    let updatedAccessor = personMessage.fieldAccessor
    XCTAssertEqual(updatedAccessor.getUInt64("total_score"), 987_654_321)
    XCTAssertEqual(updatedAccessor.getUInt64(9), 987_654_321)
  }

  func testFloatFieldAccess() throws {
    let accessor = personMessage.fieldAccessor
    XCTAssertNil(accessor.getFloat("weight"))
    XCTAssertNil(accessor.getFloat(4))

    try personMessage.set(Float(75.5), forField: "weight")

    let updatedAccessor = personMessage.fieldAccessor
    XCTAssertEqual(updatedAccessor.getFloat("weight"), 75.5)
    XCTAssertEqual(updatedAccessor.getFloat(4), 75.5)
  }

  func testDoubleFieldAccess() throws {
    let accessor = personMessage.fieldAccessor
    XCTAssertNil(accessor.getDouble("height"))
    XCTAssertNil(accessor.getDouble(3))

    try personMessage.set(Double(180.5), forField: "height")

    let updatedAccessor = personMessage.fieldAccessor
    XCTAssertEqual(updatedAccessor.getDouble("height"), 180.5)
    XCTAssertEqual(updatedAccessor.getDouble(3), 180.5)
  }

  func testBoolFieldAccess() throws {
    let accessor = personMessage.fieldAccessor
    XCTAssertNil(accessor.getBool("is_active"))
    XCTAssertNil(accessor.getBool(5))

    try personMessage.set(true, forField: "is_active")

    let updatedAccessor = personMessage.fieldAccessor
    XCTAssertEqual(updatedAccessor.getBool("is_active"), true)
    XCTAssertEqual(updatedAccessor.getBool(5), true)
  }

  func testDataFieldAccess() throws {
    let accessor = personMessage.fieldAccessor
    XCTAssertNil(accessor.getData("avatar"))
    XCTAssertNil(accessor.getData(6))

    let testData = Data([1, 2, 3, 4, 5])
    try personMessage.set(testData, forField: "avatar")

    let updatedAccessor = personMessage.fieldAccessor
    XCTAssertEqual(updatedAccessor.getData("avatar"), testData)
    XCTAssertEqual(updatedAccessor.getData(6), testData)
  }

  func testMessageFieldAccess() throws {
    // Create address
    var addressDescriptor = MessageDescriptor(name: "Address", parent: fileDescriptor)
    addressDescriptor.addField(FieldDescriptor(name: "street", number: 1, type: .string))
    addressDescriptor.addField(FieldDescriptor(name: "city", number: 2, type: .string))

    var address = DynamicMessage(descriptor: addressDescriptor)
    try address.set("Main St", forField: "street")
    try address.set("New York", forField: "city")

    let accessor = personMessage.fieldAccessor
    XCTAssertNil(accessor.getMessage("address"))
    XCTAssertNil(accessor.getMessage(15))

    try personMessage.set(address, forField: "address")

    let updatedAccessor = personMessage.fieldAccessor
    let retrievedAddress = updatedAccessor.getMessage("address")
    XCTAssertNotNil(retrievedAddress)
    XCTAssertEqual(try retrievedAddress?.get(forField: "street") as? String, "Main St")

    let retrievedAddressById = updatedAccessor.getMessage(15)
    XCTAssertNotNil(retrievedAddressById)
    XCTAssertEqual(try retrievedAddressById?.get(forField: "city") as? String, "New York")
  }

  // MARK: - Repeated Field Access Tests

  func testStringArrayFieldAccess() throws {
    let accessor = personMessage.fieldAccessor
    XCTAssertNil(accessor.getStringArray("tags"))
    XCTAssertNil(accessor.getStringArray(10))

    let tags = ["swift", "programming", "mobile"]
    try personMessage.set(tags, forField: "tags")

    let updatedAccessor = personMessage.fieldAccessor
    XCTAssertEqual(updatedAccessor.getStringArray("tags"), tags)
    XCTAssertEqual(updatedAccessor.getStringArray(10), tags)
  }

  func testInt32ArrayFieldAccess() throws {
    let accessor = personMessage.fieldAccessor
    XCTAssertNil(accessor.getInt32Array("numbers"))
    XCTAssertNil(accessor.getInt32Array(11))

    let numbers: [Int32] = [1, 2, 3, 4, 5]
    try personMessage.set(numbers, forField: "numbers")

    let updatedAccessor = personMessage.fieldAccessor
    XCTAssertEqual(updatedAccessor.getInt32Array("numbers"), numbers)
    XCTAssertEqual(updatedAccessor.getInt32Array(11), numbers)
  }

  func testInt64ArrayFieldAccess() throws {
    let accessor = personMessage.fieldAccessor
    XCTAssertNil(accessor.getInt64Array("scores"))
    XCTAssertNil(accessor.getInt64Array(12))

    let scores: [Int64] = [100, 200, 300, 400, 500]
    try personMessage.set(scores, forField: "scores")

    let updatedAccessor = personMessage.fieldAccessor
    XCTAssertEqual(updatedAccessor.getInt64Array("scores"), scores)
    XCTAssertEqual(updatedAccessor.getInt64Array(12), scores)
  }

  func testMessageArrayFieldAccess() throws {
    // Create phones
    var phoneDescriptor = MessageDescriptor(name: "Phone", parent: fileDescriptor)
    phoneDescriptor.addField(FieldDescriptor(name: "number", number: 1, type: .string))
    phoneDescriptor.addField(FieldDescriptor(name: "type", number: 2, type: .string))

    var phone1 = DynamicMessage(descriptor: phoneDescriptor)
    try phone1.set("123-456-7890", forField: "number")
    try phone1.set("mobile", forField: "type")

    var phone2 = DynamicMessage(descriptor: phoneDescriptor)
    try phone2.set("098-765-4321", forField: "number")
    try phone2.set("home", forField: "type")

    let phones = [phone1, phone2]
    try personMessage.set(phones, forField: "phones")

    let accessor = personMessage.fieldAccessor
    let retrievedPhones = accessor.getMessageArray("phones")
    XCTAssertNotNil(retrievedPhones)
    XCTAssertEqual(retrievedPhones?.count, 2)

    let retrievedPhonesById = accessor.getMessageArray(16)
    XCTAssertNotNil(retrievedPhonesById)
    XCTAssertEqual(retrievedPhonesById?.count, 2)
  }

  // MARK: - Map Field Access Tests

  func testStringMapFieldAccess() throws {
    let accessor = personMessage.fieldAccessor
    XCTAssertNil(accessor.getStringMap("attributes"))
    XCTAssertNil(accessor.getStringMap(13))

    let attributes = ["color": "blue", "size": "large", "material": "cotton"]
    try personMessage.set(attributes, forField: "attributes")

    let updatedAccessor = personMessage.fieldAccessor
    XCTAssertEqual(updatedAccessor.getStringMap("attributes"), attributes)
    XCTAssertEqual(updatedAccessor.getStringMap(13), attributes)
  }

  func testStringToInt32MapFieldAccess() throws {
    let accessor = personMessage.fieldAccessor
    XCTAssertNil(accessor.getStringToInt32Map("counters"))
    XCTAssertNil(accessor.getStringToInt32Map(14))

    let counters: [String: Int32] = ["visits": 10, "clicks": 25, "conversions": 3]
    try personMessage.set(counters, forField: "counters")

    let updatedAccessor = personMessage.fieldAccessor
    XCTAssertEqual(updatedAccessor.getStringToInt32Map("counters"), counters)
    XCTAssertEqual(updatedAccessor.getStringToInt32Map(14), counters)
  }

  func testStringToMessageMapFieldAccess() throws {
    // Create phone for map
    var phoneDescriptor = MessageDescriptor(name: "Phone", parent: fileDescriptor)
    phoneDescriptor.addField(FieldDescriptor(name: "number", number: 1, type: .string))
    phoneDescriptor.addField(FieldDescriptor(name: "type", number: 2, type: .string))

    var mobilePhone = DynamicMessage(descriptor: phoneDescriptor)
    try mobilePhone.set("123-456-7890", forField: "number")
    try mobilePhone.set("mobile", forField: "type")

    var homePhone = DynamicMessage(descriptor: phoneDescriptor)
    try homePhone.set("098-765-4321", forField: "number")
    try homePhone.set("home", forField: "type")

    // Create map with phones
    try personMessage.setMapEntry(mobilePhone, forKey: "mobile", inField: "contacts")
    try personMessage.setMapEntry(homePhone, forKey: "home", inField: "contacts")

    let accessor = personMessage.fieldAccessor
    let contacts = accessor.getStringToMessageMap("contacts")
    XCTAssertNotNil(contacts)
    XCTAssertEqual(contacts?.count, 2)
    XCTAssertNotNil(contacts?["mobile"])
    XCTAssertNotNil(contacts?["home"])

    let contactsById = accessor.getStringToMessageMap(17)
    XCTAssertNotNil(contactsById)
    XCTAssertEqual(contactsById?.count, 2)
  }

  // MARK: - Field Existence and Safety Tests

  func testHasValueMethods() throws {
    let accessor = personMessage.fieldAccessor

    // Check that fields are initially not set
    XCTAssertFalse(accessor.hasValue("name"))
    XCTAssertFalse(accessor.hasValue(1))

    // Set value and check
    try personMessage.set("John", forField: "name")

    let updatedAccessor = personMessage.fieldAccessor
    XCTAssertTrue(updatedAccessor.hasValue("name"))
    XCTAssertTrue(updatedAccessor.hasValue(1))

    // Check non-existent field
    XCTAssertFalse(updatedAccessor.hasValue("nonexistent"))
    XCTAssertFalse(updatedAccessor.hasValue(999))
  }

  func testFieldExistsMethods() {
    let accessor = personMessage.fieldAccessor

    // Check existing fields
    XCTAssertTrue(accessor.fieldExists("name"))
    XCTAssertTrue(accessor.fieldExists(1))
    XCTAssertTrue(accessor.fieldExists("age"))
    XCTAssertTrue(accessor.fieldExists(2))

    // Check non-existent fields
    XCTAssertFalse(accessor.fieldExists("nonexistent"))
    XCTAssertFalse(accessor.fieldExists(999))
  }

  func testGetFieldTypeMethods() {
    let accessor = personMessage.fieldAccessor

    // Check types of existing fields
    XCTAssertEqual(accessor.getFieldType("name"), .string)
    XCTAssertEqual(accessor.getFieldType(1), .string)
    XCTAssertEqual(accessor.getFieldType("age"), .int32)
    XCTAssertEqual(accessor.getFieldType(2), .int32)
    XCTAssertEqual(accessor.getFieldType("height"), .double)
    XCTAssertEqual(accessor.getFieldType(3), .double)

    // Check non-existent fields
    XCTAssertNil(accessor.getFieldType("nonexistent"))
    XCTAssertNil(accessor.getFieldType(999))
  }

  // MARK: - Generic Field Access Tests

  func testGenericValueAccess() throws {
    let accessor = personMessage.fieldAccessor

    // Check getting non-existent values
    XCTAssertNil(accessor.getValue("name", as: String.self))
    XCTAssertNil(accessor.getValue(1, as: String.self))

    // Set values of different types
    try personMessage.set("John", forField: "name")
    try personMessage.set(Int32(25), forField: "age")
    try personMessage.set(true, forField: "is_active")

    let updatedAccessor = personMessage.fieldAccessor

    // Check getting with correct types
    XCTAssertEqual(updatedAccessor.getValue("name", as: String.self), "John")
    XCTAssertEqual(updatedAccessor.getValue(1, as: String.self), "John")
    XCTAssertEqual(updatedAccessor.getValue("age", as: Int32.self), 25)
    XCTAssertEqual(updatedAccessor.getValue(2, as: Int32.self), 25)
    XCTAssertEqual(updatedAccessor.getValue("is_active", as: Bool.self), true)
    XCTAssertEqual(updatedAccessor.getValue(5, as: Bool.self), true)

    // Check getting with incorrect types
    XCTAssertNil(updatedAccessor.getValue("name", as: Int32.self))
    XCTAssertNil(updatedAccessor.getValue("age", as: String.self))
    XCTAssertNil(updatedAccessor.getValue("is_active", as: Float.self))
  }

  // MARK: - Type Safety Tests

  func testTypeSafetyForWrongTypes() throws {
    // Set string value
    try personMessage.set("John", forField: "name")

    let accessor = personMessage.fieldAccessor

    // Try to get string as numeric types
    XCTAssertNil(accessor.getInt32("name"))
    XCTAssertNil(accessor.getInt64("name"))
    XCTAssertNil(accessor.getUInt32("name"))
    XCTAssertNil(accessor.getUInt64("name"))
    XCTAssertNil(accessor.getFloat("name"))
    XCTAssertNil(accessor.getDouble("name"))
    XCTAssertNil(accessor.getBool("name"))
    XCTAssertNil(accessor.getData("name"))
    XCTAssertNil(accessor.getMessage("name"))

    // Set number and try to get as string
    try personMessage.set(Int32(25), forField: "age")

    let updatedAccessor = personMessage.fieldAccessor
    XCTAssertNil(updatedAccessor.getString("age"))
  }

  func testTypeSafetyForRepeatedFields() throws {
    // Set repeated strings
    try personMessage.set(["tag1", "tag2"], forField: "tags")

    let accessor = personMessage.fieldAccessor

    // Try to get repeated strings as other types
    XCTAssertNil(accessor.getInt32Array("tags"))
    XCTAssertNil(accessor.getInt64Array("tags"))
    XCTAssertNil(accessor.getMessageArray("tags"))

    // Set repeated numbers and try to get as strings
    try personMessage.set([Int32(1), Int32(2)], forField: "numbers")

    let updatedAccessor = personMessage.fieldAccessor
    XCTAssertNil(updatedAccessor.getStringArray("numbers"))
  }

  func testTypeSafetyForMapFields() throws {
    // Set string->string map
    try personMessage.set(["key": "value"], forField: "attributes")

    let accessor = personMessage.fieldAccessor

    // Try to get string->string map as string->int32 map
    XCTAssertNil(accessor.getStringToInt32Map("attributes"))
    XCTAssertNil(accessor.getStringToMessageMap("attributes"))

    // Set string->int32 map and try to get as string->string map
    try personMessage.set(["count": Int32(5)], forField: "counters")

    let updatedAccessor = personMessage.fieldAccessor
    XCTAssertNil(updatedAccessor.getStringMap("counters"))
  }

  // MARK: - Mixed Type Arrays Safety Tests

  func testMixedTypeArraySafety() throws {
    // Create array with mixed types (this should not happen in reality,
    // but testing safety)
    let mixedArray: [Any] = ["string", Int32(42), true]

    // Try to set mixed array - DynamicMessage should prevent this
    do {
      try personMessage.set(mixedArray, forField: "tags")
      XCTFail("Expected error when setting mixed array")
    }
    catch {
      // Expected behavior - type validation error
    }
  }

  // MARK: - MutableFieldAccessor Tests

  func testMutableFieldAccessorBasicOperations() {
    var mutableMessage = personMessage!
    var mutableAccessor = mutableMessage.mutableFieldAccessor()

    // Test setting string value
    XCTAssertTrue(mutableAccessor.setString("Alice", forField: "name"))
    XCTAssertTrue(mutableAccessor.setString("Bob", forField: 1))

    // Test setting numeric values
    XCTAssertTrue(mutableAccessor.setInt32(30, forField: "age"))
    XCTAssertTrue(mutableAccessor.setInt32(35, forField: 2))

    // Test setting boolean values
    XCTAssertTrue(mutableAccessor.setBool(true, forField: "is_active"))
    XCTAssertTrue(mutableAccessor.setBool(false, forField: 5))

    // Get updated message
    let updatedMessage = mutableAccessor.updatedMessage()
    let readAccessor = updatedMessage.fieldAccessor

    // Check set values
    XCTAssertEqual(readAccessor.getString("name"), "Bob")  // Last set value
    XCTAssertEqual(readAccessor.getInt32("age"), 35)  // Last set value
    XCTAssertEqual(readAccessor.getBool("is_active"), false)  // Last set value
  }

  func testMutableFieldAccessorWithNestedMessage() throws {
    // Create address
    var addressDescriptor = MessageDescriptor(name: "Address", parent: fileDescriptor)
    addressDescriptor.addField(FieldDescriptor(name: "street", number: 1, type: .string))
    addressDescriptor.addField(FieldDescriptor(name: "city", number: 2, type: .string))

    var address = DynamicMessage(descriptor: addressDescriptor)
    try address.set("Broadway", forField: "street")
    try address.set("NYC", forField: "city")

    var mutableMessage = personMessage!
    var mutableAccessor = mutableMessage.mutableFieldAccessor()

    // Set nested message
    XCTAssertTrue(mutableAccessor.setMessage(address, forField: "address"))
    XCTAssertTrue(mutableAccessor.setMessage(address, forField: 15))

    // Check set value
    let updatedMessage = mutableAccessor.updatedMessage()
    let readAccessor = updatedMessage.fieldAccessor

    let retrievedAddress = readAccessor.getMessage("address")
    XCTAssertNotNil(retrievedAddress)
    XCTAssertEqual(try retrievedAddress?.get(forField: "street") as? String, "Broadway")
  }

  func testMutableFieldAccessorErrorHandling() {
    var mutableMessage = personMessage!
    var mutableAccessor = mutableMessage.mutableFieldAccessor()

    // Try to set value in non-existent field
    XCTAssertFalse(mutableAccessor.setString("test", forField: "nonexistent"))
    XCTAssertFalse(mutableAccessor.setString("test", forField: 999))

    // Try to set incorrect type (this should be handled by DynamicMessage)
    // Create fake nested message for field that expects string
    let fakeDescriptor = MessageDescriptor(name: "Fake", parent: fileDescriptor)
    let fakeMessage = DynamicMessage(descriptor: fakeDescriptor)

    // Attempt to set message in string field should fail
    XCTAssertFalse(mutableAccessor.setMessage(fakeMessage, forField: "name"))
  }

  // MARK: - Convenience Extension Tests

  func testConvenienceExtensions() {
    // Test fieldAccessor extension
    let readAccessor = personMessage.fieldAccessor
    XCTAssertNotNil(readAccessor)
    XCTAssertFalse(readAccessor.hasValue("name"))

    // Test mutableFieldAccessor extension
    var mutableMessage = personMessage!
    var mutableAccessor = mutableMessage.mutableFieldAccessor()
    XCTAssertTrue(mutableAccessor.setString("Test", forField: "name"))

    // Check that change is reflected in original message
    let updatedMessage = mutableAccessor.updatedMessage()
    XCTAssertEqual(updatedMessage.fieldAccessor.getString("name"), "Test")
  }

  // MARK: - Edge Cases Tests

  func testEmptyRepeatedFields() throws {
    // Set empty repeated fields
    try personMessage.set([String](), forField: "tags")
    try personMessage.set([Int32](), forField: "numbers")

    let accessor = personMessage.fieldAccessor

    // Check that we get empty arrays, not nil
    XCTAssertEqual(accessor.getStringArray("tags"), [])
    XCTAssertEqual(accessor.getInt32Array("numbers"), [])
  }

  func testEmptyMapFields() throws {
    // Set empty map fields
    try personMessage.set([String: String](), forField: "attributes")
    try personMessage.set([String: Int32](), forField: "counters")

    let accessor = personMessage.fieldAccessor

    // Check that we get empty dictionaries, not nil
    XCTAssertEqual(accessor.getStringMap("attributes"), [:])
    XCTAssertEqual(accessor.getStringToInt32Map("counters"), [:])
  }

  func testNilDefaultValues() {
    let accessor = personMessage.fieldAccessor

    // All methods should return nil for unset fields
    XCTAssertNil(accessor.getString("name"))
    XCTAssertNil(accessor.getInt32("age"))
    XCTAssertNil(accessor.getInt64("user_id"))
    XCTAssertNil(accessor.getUInt32("score"))
    XCTAssertNil(accessor.getUInt64("total_score"))
    XCTAssertNil(accessor.getFloat("weight"))
    XCTAssertNil(accessor.getDouble("height"))
    XCTAssertNil(accessor.getBool("is_active"))
    XCTAssertNil(accessor.getData("avatar"))
    XCTAssertNil(accessor.getMessage("address"))
    XCTAssertNil(accessor.getStringArray("tags"))
    XCTAssertNil(accessor.getInt32Array("numbers"))
    XCTAssertNil(accessor.getInt64Array("scores"))
    XCTAssertNil(accessor.getMessageArray("phones"))
    XCTAssertNil(accessor.getStringMap("attributes"))
    XCTAssertNil(accessor.getStringToInt32Map("counters"))
    XCTAssertNil(accessor.getStringToMessageMap("contacts"))
  }
}
