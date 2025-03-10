import XCTest

@testable import SwiftProtoReflect

class ProtoDynamicMessageTests: XCTestCase {

  var descriptor: ProtoMessageDescriptor!
  var message: ProtoDynamicMessage!

  override func setUp() {
    super.setUp()
    descriptor = ProtoMessageDescriptor(
      fullName: "DynamicMessage",
      fields: [
        ProtoFieldDescriptor(name: "intField", number: 1, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "stringField", number: 2, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "boolField", number: 3, type: .bool, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "repeatedIntField", number: 4, type: .int32, isRepeated: true, isMap: false),
        ProtoFieldDescriptor(name: "mapField", number: 5, type: .string, isRepeated: false, isMap: true),
      ],
      enums: [],
      nestedMessages: []
    )
    message = ProtoDynamicMessage(descriptor: descriptor)
  }

  // MARK: - Basic Field Operations Tests

  func testSetAndGetFieldValues() {
    message.set(field: descriptor.field(named: "intField")!, value: .intValue(100))
    message.set(field: descriptor.field(named: "stringField")!, value: .stringValue("hello"))
    message.set(field: descriptor.field(named: "boolField")!, value: .boolValue(true))

    let intValue = message.get(field: descriptor.field(named: "intField")!)
    let stringValue = message.get(field: descriptor.field(named: "stringField")!)
    let boolValue = message.get(field: descriptor.field(named: "boolField")!)

    XCTAssertEqual(intValue?.getInt(), 100)
    XCTAssertEqual(stringValue?.getString(), "hello")
    XCTAssertEqual(boolValue?.getBool(), true)
  }

  func testSetAndGetFieldValuesByName() {
    message.set(fieldName: "intField", value: .intValue(100))
    message.set(fieldName: "stringField", value: .stringValue("hello"))
    message.set(fieldName: "boolField", value: .boolValue(true))

    let intValue = message.get(fieldName: "intField")
    let stringValue = message.get(fieldName: "stringField")
    let boolValue = message.get(fieldName: "boolField")

    XCTAssertEqual(intValue?.getInt(), 100)
    XCTAssertEqual(stringValue?.getString(), "hello")
    XCTAssertEqual(boolValue?.getBool(), true)
  }

  func testSetAndGetFieldValuesByNumber() {
    message.set(fieldNumber: 1, value: .intValue(100))
    message.set(fieldNumber: 2, value: .stringValue("hello"))
    message.set(fieldNumber: 3, value: .boolValue(true))

    let intValue = message.get(fieldNumber: 1)
    let stringValue = message.get(fieldNumber: 2)
    let boolValue = message.get(fieldNumber: 3)

    XCTAssertEqual(intValue?.getInt(), 100)
    XCTAssertEqual(stringValue?.getString(), "hello")
    XCTAssertEqual(boolValue?.getBool(), true)
  }

  func testClearField() {
    message.set(fieldName: "intField", value: .intValue(100))
    XCTAssertNotNil(message.get(fieldName: "intField"))

    message.clear(fieldName: "intField")
    XCTAssertNil(message.get(fieldName: "intField"))
  }

  func testHasField() {
    XCTAssertFalse(message.has(fieldName: "intField"))

    message.set(fieldName: "intField", value: .intValue(100))
    XCTAssertTrue(message.has(fieldName: "intField"))

    message.clear(fieldName: "intField")
    XCTAssertFalse(message.has(fieldName: "intField"))
  }

  // MARK: - Repeated Field Tests

  func testRepeatedField() {
    // Add values to the repeated field
    XCTAssertTrue(message.add(toRepeatedFieldNamed: "repeatedIntField", value: .intValue(1)))
    XCTAssertTrue(message.add(toRepeatedFieldNamed: "repeatedIntField", value: .intValue(2)))
    XCTAssertTrue(message.add(toRepeatedFieldNamed: "repeatedIntField", value: .intValue(3)))

    // Check the count
    XCTAssertEqual(message.count(ofRepeatedFieldNamed: "repeatedIntField"), 3)

    // Get values by index
    let value1 = message.get(fromRepeatedFieldNamed: "repeatedIntField", at: 0)
    let value2 = message.get(fromRepeatedFieldNamed: "repeatedIntField", at: 1)
    let value3 = message.get(fromRepeatedFieldNamed: "repeatedIntField", at: 2)

    XCTAssertEqual(value1?.getInt(), 1)
    XCTAssertEqual(value2?.getInt(), 2)
    XCTAssertEqual(value3?.getInt(), 3)

    // Out of bounds index should return nil
    XCTAssertNil(message.get(fromRepeatedFieldNamed: "repeatedIntField", at: 3))

    // Clear the field
    message.clear(fieldName: "repeatedIntField")
    XCTAssertEqual(message.count(ofRepeatedFieldNamed: "repeatedIntField"), 0)
  }

  func testInvalidRepeatedFieldOperations() {
    // Try to add a string value to an int repeated field
    XCTAssertFalse(message.add(toRepeatedFieldNamed: "repeatedIntField", value: .stringValue("invalid")))

    // Try to add to a non-repeated field
    XCTAssertFalse(message.add(toRepeatedFieldNamed: "intField", value: .intValue(1)))

    // Try to add to a non-existent field
    XCTAssertFalse(message.add(toRepeatedFieldNamed: "nonExistentField", value: .intValue(1)))
  }

  // MARK: - Map Field Tests

  func testMapField() {
    // Set values in the map field
    XCTAssertTrue(message.set(inMapFieldNamed: "mapField", key: "key1", value: .stringValue("value1")))
    XCTAssertTrue(message.set(inMapFieldNamed: "mapField", key: "key2", value: .stringValue("value2")))

    // Check the count
    XCTAssertEqual(message.count(ofMapFieldNamed: "mapField"), 2)

    // Get values by key
    let value1 = message.get(fromMapFieldNamed: "mapField", key: "key1")
    let value2 = message.get(fromMapFieldNamed: "mapField", key: "key2")

    XCTAssertEqual(value1?.getString(), "value1")
    XCTAssertEqual(value2?.getString(), "value2")

    // Non-existent key should return nil
    XCTAssertNil(message.get(fromMapFieldNamed: "mapField", key: "nonExistentKey"))

    // Remove a key
    XCTAssertTrue(message.remove(fromMapField: descriptor.field(named: "mapField")!, key: "key1"))
    XCTAssertEqual(message.count(ofMapFieldNamed: "mapField"), 1)
    XCTAssertNil(message.get(fromMapFieldNamed: "mapField", key: "key1"))

    // Clear the field
    message.clear(fieldName: "mapField")
    XCTAssertEqual(message.count(ofMapFieldNamed: "mapField"), 0)
  }

  func testInvalidMapFieldOperations() {
    // Try to set a value in a non-map field
    XCTAssertFalse(message.set(inMapFieldNamed: "intField", key: "key", value: .stringValue("value")))

    // Try to set a value in a non-existent field
    XCTAssertFalse(message.set(inMapFieldNamed: "nonExistentField", key: "key", value: .stringValue("value")))

    // Try to remove a key from a non-map field
    XCTAssertFalse(message.remove(fromMapField: descriptor.field(named: "intField")!, key: "key"))
  }

  // MARK: - Nested Message Tests

  func testNestedMessage() {
    // Create a nested message descriptor
    let addressDescriptor = ProtoMessageDescriptor(
      fullName: "Address",
      fields: [
        ProtoFieldDescriptor(name: "street", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "city", number: 2, type: .string, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a message descriptor with a nested message field
    let personDescriptor = ProtoMessageDescriptor(
      fullName: "Person",
      fields: [
        ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(
          name: "address",
          number: 2,
          type: .message,
          isRepeated: false,
          isMap: false,
          messageType: addressDescriptor
        ),
      ],
      enums: [],
      nestedMessages: [addressDescriptor]
    )

    // Create a person message
    let person = ProtoDynamicMessage(descriptor: personDescriptor)
    person.set(fieldName: "name", value: .stringValue("John Doe"))

    // Create an address message
    let address = ProtoDynamicMessage(descriptor: addressDescriptor)
    address.set(fieldName: "street", value: .stringValue("123 Main St"))
    address.set(fieldName: "city", value: .stringValue("Anytown"))

    // Set the address in the person message
    person.setNestedMessage(fieldName: "address", message: address)

    // Verify the nested message
    let retrievedAddress = person.get(fieldName: "address")?.getMessage() as? ProtoDynamicMessage
    XCTAssertNotNil(retrievedAddress)
    XCTAssertEqual(retrievedAddress?.get(fieldName: "street")?.getString(), "123 Main St")
    XCTAssertEqual(retrievedAddress?.get(fieldName: "city")?.getString(), "Anytown")
  }

  // MARK: - Validation Tests

  func testValidation() {
    // Valid field values
    XCTAssertTrue(message.set(fieldName: "intField", value: .intValue(100)))
    XCTAssertTrue(message.set(fieldName: "stringField", value: .stringValue("hello")))

    // Valid conversions
    XCTAssertTrue(message.set(fieldName: "stringField", value: .intValue(100)))  // Int can be converted to String

    // Invalid field values
    // String that can't be converted to Int
    XCTAssertFalse(message.set(fieldName: "intField", value: .stringValue("not a number")))

    // Non-existent field
    XCTAssertFalse(message.set(fieldName: "nonExistentField", value: .intValue(100)))
  }

  // MARK: - Equality and Hashing Tests

  func testEquality() {
    let message1 = ProtoDynamicMessage(descriptor: descriptor)
    let message2 = ProtoDynamicMessage(descriptor: descriptor)

    // Empty messages with the same descriptor should be equal
    XCTAssertEqual(message1, message2)

    // Set the same fields to the same values
    message1.set(fieldName: "intField", value: .intValue(100))
    message1.set(fieldName: "stringField", value: .stringValue("hello"))

    message2.set(fieldName: "intField", value: .intValue(100))
    message2.set(fieldName: "stringField", value: .stringValue("hello"))

    // Messages with the same fields and values should be equal
    XCTAssertEqual(message1, message2)

    // Change a value in one message
    message2.set(fieldName: "intField", value: .intValue(200))

    // Messages with different values should not be equal
    XCTAssertNotEqual(message1, message2)

    // Create a message with a different descriptor
    let differentDescriptor = ProtoMessageDescriptor(
      fullName: "DifferentMessage",
      fields: [],
      enums: [],
      nestedMessages: []
    )
    let differentMessage = ProtoDynamicMessage(descriptor: differentDescriptor)

    // Messages with different descriptors should not be equal
    XCTAssertNotEqual(message1, differentMessage)
  }

  func testHashing() {
    let message1 = ProtoDynamicMessage(descriptor: descriptor)
    let message2 = ProtoDynamicMessage(descriptor: descriptor)

    // Set the same fields to the same values
    message1.set(fieldName: "intField", value: .intValue(100))
    message1.set(fieldName: "stringField", value: .stringValue("hello"))

    message2.set(fieldName: "intField", value: .intValue(100))
    message2.set(fieldName: "stringField", value: .stringValue("hello"))

    // Create a set with both messages
    var messageSet = Set<ProtoDynamicMessage>()
    messageSet.insert(message1)
    messageSet.insert(message2)

    // The set should contain only one message since they are equal
    XCTAssertEqual(messageSet.count, 1)
  }

  // MARK: - Negative Tests

  func testGetNonExistentField() {
    let nonExistentField = ProtoFieldDescriptor(
      name: "nonExistent",
      number: 99,
      type: .int32,
      isRepeated: false,
      isMap: false
    )
    let value = message.get(field: nonExistentField)
    XCTAssertNil(value)
  }

  func testSetIncorrectFieldType() {
    message.set(field: descriptor.fields[0], value: .stringValue("invalid"))
    let value = message.get(field: descriptor.fields[0])
    XCTAssertNil(value?.getInt())
  }

  func testValidDynamicMessage() {
    XCTAssertTrue(message.isValid())
  }

  // MARK: - Test Setup

  // Create test descriptors for a complex message structure
  lazy var addressDescriptor = ProtoMessageDescriptor(
    fullName: "Address",
    fields: [
      ProtoFieldDescriptor(name: "street", number: 1, type: .string, isRepeated: false, isMap: false),
      ProtoFieldDescriptor(name: "city", number: 2, type: .string, isRepeated: false, isMap: false),
      ProtoFieldDescriptor(name: "zip_code", number: 3, type: .int32, isRepeated: false, isMap: false),
    ],
    enums: [],
    nestedMessages: []
  )

  lazy var phoneDescriptor = ProtoMessageDescriptor(
    fullName: "Phone",
    fields: [
      ProtoFieldDescriptor(name: "number", number: 1, type: .string, isRepeated: false, isMap: false),
      ProtoFieldDescriptor(name: "type", number: 2, type: .string, isRepeated: false, isMap: false),
    ],
    enums: [],
    nestedMessages: []
  )

  // Create a map entry descriptor for the attributes map
  lazy var attributeEntryDescriptor = ProtoMessageDescriptor(
    fullName: "Person.AttributesEntry",
    fields: [
      ProtoFieldDescriptor(name: "key", number: 1, type: .string, isRepeated: false, isMap: false),
      ProtoFieldDescriptor(name: "value", number: 2, type: .string, isRepeated: false, isMap: false),
    ],
    enums: [],
    nestedMessages: []
  )

  lazy var personDescriptor = ProtoMessageDescriptor(
    fullName: "Person",
    fields: [
      ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false),
      ProtoFieldDescriptor(name: "age", number: 2, type: .int32, isRepeated: false, isMap: false),
      ProtoFieldDescriptor(
        name: "address",
        number: 3,
        type: .message,
        isRepeated: false,
        isMap: false,
        messageType: addressDescriptor
      ),
      ProtoFieldDescriptor(
        name: "phones",
        number: 4,
        type: .message,
        isRepeated: true,
        isMap: false,
        messageType: phoneDescriptor
      ),
      ProtoFieldDescriptor(
        name: "attributes",
        number: 5,
        type: .message,
        isRepeated: false,
        isMap: true,
        messageType: attributeEntryDescriptor
      ),
    ],
    enums: [],
    nestedMessages: [addressDescriptor, phoneDescriptor, attributeEntryDescriptor]
  )

  // MARK: - Nested Message Tests

  func testCreateNestedMessage() {
    let person = ProtoDynamicMessage(descriptor: personDescriptor)

    // Test creating a nested message
    guard let address = person.createNestedMessage(for: personDescriptor.field(named: "address")!) else {
      XCTFail("Failed to create nested address message")
      return
    }

    // Verify the nested message has the correct descriptor
    XCTAssertEqual(address.descriptor().fullName, addressDescriptor.fullName)

    // Set fields on the nested message
    address.set(field: addressDescriptor.field(named: "street")!, value: ProtoValue.stringValue("123 Main St"))
    address.set(field: addressDescriptor.field(named: "city")!, value: ProtoValue.stringValue("Anytown"))
    address.set(field: addressDescriptor.field(named: "zip_code")!, value: ProtoValue.intValue(12345))

    // Set the nested message on the parent
    XCTAssertTrue(person.setNestedMessage(field: personDescriptor.field(named: "address")!, message: address))

    // Verify the nested message was set correctly
    guard let retrievedAddress = person.getNestedMessage(field: personDescriptor.field(named: "address")!) else {
      XCTFail("Failed to retrieve nested address message")
      return
    }

    XCTAssertEqual(retrievedAddress.descriptor().fullName, addressDescriptor.fullName)

    // Verify the fields were set correctly
    let addressDynamic = retrievedAddress as! ProtoDynamicMessage
    XCTAssertEqual(addressDynamic.get(field: addressDescriptor.field(named: "street")!)?.getString(), "123 Main St")
    XCTAssertEqual(addressDynamic.get(field: addressDescriptor.field(named: "city")!)?.getString(), "Anytown")
    XCTAssertEqual(addressDynamic.get(field: addressDescriptor.field(named: "zip_code")!)?.getInt(), 12345)
  }

  func testNestedMessageFieldAccess() {
    let person = ProtoDynamicMessage(descriptor: personDescriptor)

    // Create and set a nested address message
    guard let address = person.createNestedMessage(for: personDescriptor.field(named: "address")!) else {
      XCTFail("Failed to create nested address message")
      return
    }

    address.set(field: addressDescriptor.field(named: "street")!, value: ProtoValue.stringValue("123 Main St"))
    address.set(field: addressDescriptor.field(named: "city")!, value: ProtoValue.stringValue("Anytown"))
    address.set(field: addressDescriptor.field(named: "zip_code")!, value: ProtoValue.intValue(12345))

    XCTAssertTrue(person.setNestedMessage(field: personDescriptor.field(named: "address")!, message: address))

    // Test accessing the nested message fields through the parent
    XCTAssertEqual(person.get(fieldName: "address")?.getMessage()?.descriptor().fullName, addressDescriptor.fullName)

    let addressMessage = person.get(fieldName: "address")?.getMessage() as! ProtoDynamicMessage
    XCTAssertEqual(addressMessage.get(fieldName: "street")?.getString(), "123 Main St")
    XCTAssertEqual(addressMessage.get(fieldName: "city")?.getString(), "Anytown")
    XCTAssertEqual(addressMessage.get(fieldName: "zip_code")?.getInt(), 12345)
  }

  // MARK: - Repeated Field Tests

  func testRepeatedMessageFields() {
    let person = ProtoDynamicMessage(descriptor: personDescriptor)

    // Create phone messages
    let phone1 = ProtoDynamicMessage(descriptor: phoneDescriptor)
    phone1.set(fieldName: "number", value: .stringValue("555-1234"))
    phone1.set(fieldName: "type", value: .stringValue("home"))

    let phone2 = ProtoDynamicMessage(descriptor: phoneDescriptor)
    phone2.set(fieldName: "number", value: .stringValue("555-5678"))
    phone2.set(fieldName: "type", value: .stringValue("work"))

    // Set the repeated field
    XCTAssertTrue(
      person.set(
        fieldName: "phones",
        value: .repeatedValue([
          .messageValue(phone1),
          .messageValue(phone2),
        ])
      )
    )

    // Test accessing elements in the repeated field
    guard let phones = person.get(fieldName: "phones")?.getRepeated() else {
      XCTFail("Failed to retrieve phones repeated field")
      return
    }

    XCTAssertEqual(phones.count, 2)

    // Test first phone
    guard let phone1Retrieved = phones[0].getMessage() as? ProtoDynamicMessage else {
      XCTFail("Failed to retrieve first phone message")
      return
    }

    XCTAssertEqual(phone1Retrieved.get(fieldName: "number")?.getString(), "555-1234")
    XCTAssertEqual(phone1Retrieved.get(fieldName: "type")?.getString(), "home")

    // Test second phone
    guard let phone2Retrieved = phones[1].getMessage() as? ProtoDynamicMessage else {
      XCTFail("Failed to retrieve second phone message")
      return
    }

    XCTAssertEqual(phone2Retrieved.get(fieldName: "number")?.getString(), "555-5678")
    XCTAssertEqual(phone2Retrieved.get(fieldName: "type")?.getString(), "work")

    // Test getting elements by index
    guard
      let phone1FromIndex = person.get(fromRepeatedFieldNamed: "phones", at: 0)?.getMessage() as? ProtoDynamicMessage
    else {
      XCTFail("Failed to retrieve first phone by index")
      return
    }

    XCTAssertEqual(phone1FromIndex.get(fieldName: "number")?.getString(), "555-1234")

    // Test adding to repeated field
    let phone3 = ProtoDynamicMessage(descriptor: phoneDescriptor)
    phone3.set(fieldName: "number", value: .stringValue("555-9876"))
    phone3.set(fieldName: "type", value: .stringValue("mobile"))

    XCTAssertTrue(person.add(toRepeatedFieldNamed: "phones", value: .messageValue(phone3)))

    // Verify the new element was added
    XCTAssertEqual(person.count(ofRepeatedFieldNamed: "phones"), 3)

    guard
      let phone3FromIndex = person.get(fromRepeatedFieldNamed: "phones", at: 2)?.getMessage() as? ProtoDynamicMessage
    else {
      XCTFail("Failed to retrieve third phone by index")
      return
    }

    XCTAssertEqual(phone3FromIndex.get(fieldName: "number")?.getString(), "555-9876")
    XCTAssertEqual(phone3FromIndex.get(fieldName: "type")?.getString(), "mobile")
  }

  // MARK: - Map Field Tests

  func testMapFields() {
    let person = ProtoDynamicMessage(descriptor: personDescriptor)

    // Set map field
    XCTAssertTrue(
      person.set(
        fieldName: "attributes",
        value: .mapValue([
          "height": .stringValue("6'0\""),
          "weight": .stringValue("180lbs"),
          "hair_color": .stringValue("brown"),
        ])
      )
    )

    // Test accessing map entries
    guard let attributes = person.get(fieldName: "attributes")?.getMap() else {
      XCTFail("Failed to retrieve attributes map field")
      return
    }

    XCTAssertEqual(attributes.count, 3)
    XCTAssertEqual(attributes["height"]?.getString(), "6'0\"")
    XCTAssertEqual(attributes["weight"]?.getString(), "180lbs")
    XCTAssertEqual(attributes["hair_color"]?.getString(), "brown")

    // Test getting map entries by key
    XCTAssertEqual(person.get(fromMapFieldNamed: "attributes", key: "height")?.getString(), "6'0\"")
    XCTAssertEqual(person.get(fromMapFieldNamed: "attributes", key: "weight")?.getString(), "180lbs")

    // Test setting map entries
    XCTAssertTrue(person.set(inMapFieldNamed: "attributes", key: "height", value: .stringValue("6'1\"")))
    XCTAssertEqual(person.get(fromMapFieldNamed: "attributes", key: "height")?.getString(), "6'1\"")

    // Test adding new map entries
    XCTAssertTrue(person.set(inMapFieldNamed: "attributes", key: "eye_color", value: .stringValue("blue")))
    XCTAssertEqual(person.get(fromMapFieldNamed: "attributes", key: "eye_color")?.getString(), "blue")

    // Test map size
    XCTAssertEqual(person.count(ofMapFieldNamed: "attributes"), 4)

    // Test removing map entries
    XCTAssertTrue(person.remove(fromMapFieldNamed: "attributes", key: "weight"))
    XCTAssertNil(person.get(fromMapFieldNamed: "attributes", key: "weight"))
    XCTAssertEqual(person.count(ofMapFieldNamed: "attributes"), 3)
  }

  // MARK: - Equality and Hashing Tests

  func testMessageEquality() {
    // Create two identical messages
    let person1 = ProtoDynamicMessage(descriptor: personDescriptor)
    person1.set(fieldName: "name", value: .stringValue("John Doe"))
    person1.set(fieldName: "age", value: .intValue(30))

    let address1 = ProtoDynamicMessage(descriptor: addressDescriptor)
    address1.set(fieldName: "street", value: .stringValue("123 Main St"))
    address1.set(fieldName: "city", value: .stringValue("Anytown"))
    address1.set(fieldName: "zip_code", value: .intValue(12345))
    person1.setNestedMessage(fieldName: "address", message: address1)

    let person2 = ProtoDynamicMessage(descriptor: personDescriptor)
    person2.set(fieldName: "name", value: .stringValue("John Doe"))
    person2.set(fieldName: "age", value: .intValue(30))

    let address2 = ProtoDynamicMessage(descriptor: addressDescriptor)
    address2.set(fieldName: "street", value: .stringValue("123 Main St"))
    address2.set(fieldName: "city", value: .stringValue("Anytown"))
    address2.set(fieldName: "zip_code", value: .intValue(12345))
    person2.setNestedMessage(fieldName: "address", message: address2)

    // Test equality
    XCTAssertEqual(person1, person2)

    // Test inequality after changing a field
    person2.set(fieldName: "name", value: .stringValue("Jane Doe"))
    XCTAssertNotEqual(person1, person2)

    // Test inequality after changing a nested field
    person2.set(fieldName: "name", value: .stringValue("John Doe"))
    let address2Updated = person2.getNestedMessage(fieldName: "address") as! ProtoDynamicMessage
    address2Updated.set(fieldName: "city", value: .stringValue("Othertown"))
    person2.setNestedMessage(fieldName: "address", message: address2Updated)
    XCTAssertNotEqual(person1, person2)
  }

  func testMessageHashing() {
    // Create two identical messages
    let person1 = ProtoDynamicMessage(descriptor: personDescriptor)
    person1.set(fieldName: "name", value: .stringValue("John Doe"))
    person1.set(fieldName: "age", value: .intValue(30))

    let person2 = ProtoDynamicMessage(descriptor: personDescriptor)
    person2.set(fieldName: "name", value: .stringValue("John Doe"))
    person2.set(fieldName: "age", value: .intValue(30))

    // Test hash values
    XCTAssertEqual(person1.hashValue, person2.hashValue)

    // Test hash values after changing a field
    person2.set(fieldName: "name", value: .stringValue("Jane Doe"))
    XCTAssertNotEqual(person1.hashValue, person2.hashValue)
  }

  // MARK: - Validation Tests

  func testMessageValidation() {
    // Create a person message
    let person = ProtoDynamicMessage(descriptor: personDescriptor)

    // Set required fields
    person.set(fieldName: "name", value: .stringValue("John Doe"))
    person.set(fieldName: "age", value: .intValue(30))

    // Create and set a valid address
    let address = ProtoDynamicMessage(descriptor: addressDescriptor)
    address.set(fieldName: "street", value: .stringValue("123 Main St"))
    address.set(fieldName: "city", value: .stringValue("Anytown"))

    person.setNestedMessage(fieldName: "address", message: address)

    // Validate the message
    XCTAssertTrue(person.isValid())

    // Test validation with invalid value type
    // Since our implementation now handles string values for int fields by checking if they can be converted to int,
    // we need to use a string that cannot be converted to an int
    let result = person.set(fieldName: "age", value: .stringValue("thirty"))

    // The set method should return false because "thirty" cannot be converted to an int
    XCTAssertFalse(result)

    // The message should still be valid because the invalid value was not set
    XCTAssertTrue(person.isValid())

    // Reset to valid state
    person.set(fieldName: "age", value: .intValue(30))
    XCTAssertTrue(person.isValid())

    // Test validation with invalid nested message
    let invalidAddress = ProtoDynamicMessage(descriptor: phoneDescriptor)
    XCTAssertFalse(person.setNestedMessage(fieldName: "address", message: invalidAddress))
  }
}
