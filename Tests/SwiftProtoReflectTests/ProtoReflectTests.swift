import XCTest

@testable import SwiftProtoReflect

class ProtoReflectTests: XCTestCase {

  var personDescriptor: ProtoMessageDescriptor!
  var addressDescriptor: ProtoMessageDescriptor!

  override func setUp() {
    super.setUp()

    // Create a nested message descriptor for address
    addressDescriptor = ProtoMessageDescriptor(
      fullName: "Address",
      fields: [
        ProtoFieldDescriptor(name: "street", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "city", number: 2, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "zipCode", number: 3, type: .string, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a message descriptor for person with a nested address field
    personDescriptor = ProtoMessageDescriptor(
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
        ProtoFieldDescriptor(name: "tags", number: 4, type: .string, isRepeated: true, isMap: false),
        ProtoFieldDescriptor(name: "attributes", number: 5, type: .string, isRepeated: false, isMap: true),
      ],
      enums: [],
      nestedMessages: [addressDescriptor]
    )

    // Register the descriptors
    ProtoReflect.registerDescriptor(personDescriptor)
    ProtoReflect.registerDescriptor(addressDescriptor)
  }

  func testCreateMessage() {
    let person = ProtoReflect.createMessage(from: personDescriptor)
    XCTAssertNotNil(person)

    let message = person.build()
    XCTAssertEqual(message.descriptor().fullName, "Person")
  }

  func testCreateMessageByName() {
    let person = ProtoReflect.createMessage(fromTypeName: "Person")
    XCTAssertNotNil(person)

    let message = person!.build()
    XCTAssertEqual(message.descriptor().fullName, "Person")

    // Test with non-existent descriptor
    let nonExistent = ProtoReflect.createMessage(fromTypeName: "NonExistent")
    XCTAssertNil(nonExistent)
  }

  func testSetAndGetSimpleValues() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    // Set simple values
    person.set("name", to: "John Doe")
    person.set("age", to: 30)

    // Get values
    let name = person.get("name")
    let age = person.get("age")

    XCTAssertEqual(name?.getString(), "John Doe")
    XCTAssertEqual(age?.getInt(), 30)
  }

  func testSetAndGetNestedValues() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    // Set nested values
    person.set("address.street", to: "123 Main St")
    person.set("address.city", to: "Anytown")
    person.set("address.zipCode", to: "12345")

    // Get nested values
    let street = person.get("address.street")
    let city = person.get("address.city")
    let zipCode = person.get("address.zipCode")

    XCTAssertEqual(street?.getString(), "123 Main St")
    XCTAssertEqual(city?.getString(), "Anytown")
    XCTAssertEqual(zipCode?.getString(), "12345")
  }

  func testSetAndGetRepeatedValues() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    // Set repeated values
    person.set("tags", to: ["tag1", "tag2", "tag3"])

    // Get repeated values
    let tags = person.get("tags")?.getRepeated()

    XCTAssertNotNil(tags)
    XCTAssertEqual(tags?.count, 3)
    XCTAssertEqual(tags?[0].getString(), "tag1")
    XCTAssertEqual(tags?[1].getString(), "tag2")
    XCTAssertEqual(tags?[2].getString(), "tag3")
  }

  func testSetAndGetMapValues() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    // Set map values
    person.set("attributes", to: ["key1": "value1", "key2": "value2"])

    // Get map values
    let attributes = person.get("attributes")?.getMap()

    XCTAssertNotNil(attributes)
    XCTAssertEqual(attributes?.count, 2)
    XCTAssertEqual(attributes?["key1"]?.getString(), "value1")
    XCTAssertEqual(attributes?["key2"]?.getString(), "value2")
  }

  func testClearValues() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    // Set and clear simple value
    person.set("name", to: "John Doe")
    XCTAssertNotNil(person.get("name"))

    person.clear("name")
    XCTAssertNil(person.get("name"))

    // Set and clear nested value
    person.set("address.street", to: "123 Main St")
    XCTAssertNotNil(person.get("address.street"))

    person.clear("address.street")
    XCTAssertNil(person.get("address.street"))
  }

  func testHasValues() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    // Test has for simple value
    XCTAssertFalse(person.has("name"))

    person.set("name", to: "John Doe")
    XCTAssertTrue(person.has("name"))

    // Test has for nested value
    XCTAssertFalse(person.has("address.street"))

    person.set("address.street", to: "123 Main St")
    XCTAssertTrue(person.has("address.street"))
  }

  func testMethodChaining() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    // Use method chaining
    person
      .set("name", to: "John Doe")
      .set("age", to: 30)
      .set("address.street", to: "123 Main St")
      .set("address.city", to: "Anytown")

    // Verify values
    XCTAssertEqual(person.get("name")?.getString(), "John Doe")
    XCTAssertEqual(person.get("age")?.getInt(), 30)
    XCTAssertEqual(person.get("address.street")?.getString(), "123 Main St")
    XCTAssertEqual(person.get("address.city")?.getString(), "Anytown")
  }

  func testValueConversion() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    // Test various value types
    person.set("name", to: "John Doe")  // String
    person.set("age", to: 30)  // Int
    person.set("age", to: 30.5)  // Double (should be converted)
    person.set("tags", to: ["tag1", 2, true])  // Mixed array (should be converted)

    XCTAssertEqual(person.get("name")?.getString(), "John Doe")
    XCTAssertEqual(person.get("age")?.asInt32(), 30)

    let tags = person.get("tags")?.getRepeated()
    XCTAssertNotNil(tags)
    XCTAssertEqual(tags?.count, 3)
    XCTAssertEqual(tags?[0].getString(), "tag1")
    XCTAssertEqual(tags?[1].asInt32(), 2)
    XCTAssertEqual(tags?[2].asBool(), true)
  }

  func testMarshalAndUnmarshal() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    // Set some values
    person.set("name", to: "John Doe")
    person.set("age", to: 30)
    person.set("address.street", to: "123 Main St")

    // Marshal to wire format
    let data = ProtoReflect.marshal(message: person.build())
    XCTAssertNotNil(data)

    // Unmarshal from wire format
    let unmarshaledMessage = ProtoReflect.unmarshal(data: data!, descriptor: personDescriptor)
    XCTAssertNotNil(unmarshaledMessage)

    // Verify values
    let unmarshaledPerson = unmarshaledMessage as? ProtoDynamicMessage
    XCTAssertNotNil(unmarshaledPerson)

    let name = unmarshaledPerson?.get(field: personDescriptor.field(named: "name")!)
    XCTAssertEqual(name?.getString(), "John Doe")

    let age = unmarshaledPerson?.get(field: personDescriptor.field(named: "age")!)
    XCTAssertEqual(age?.getInt(), 30)
  }
}
