import XCTest

@testable import SwiftProtoReflect

class ProtoFieldPathTests: XCTestCase {

  var addressDescriptor: ProtoMessageDescriptor!
  var personDescriptor: ProtoMessageDescriptor!
  var person: ProtoDynamicMessage!

  override func setUp() {
    super.setUp()

    // Create a nested message descriptor for address
    addressDescriptor = ProtoMessageDescriptor(
      fullName: "Address",
      fields: [
        ProtoFieldDescriptor(name: "street", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "city", number: 2, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "zip_code", number: 3, type: .int32, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a nested message descriptor for phone
    let phoneDescriptor = ProtoMessageDescriptor(
      fullName: "Phone",
      fields: [
        ProtoFieldDescriptor(name: "number", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "type", number: 2, type: .int32, isRepeated: false, isMap: false),
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
          type: .message(addressDescriptor),
          isRepeated: false,
          isMap: false,
          messageType: addressDescriptor
        ),
        ProtoFieldDescriptor(
          name: "phones",
          number: 4,
          type: .message(phoneDescriptor),
          isRepeated: true,
          isMap: false,
          messageType: phoneDescriptor
        ),
        ProtoFieldDescriptor(name: "attributes", number: 5, type: .string, isRepeated: false, isMap: true),
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a person message
    person = ProtoDynamicMessage(descriptor: personDescriptor)

    // Set some initial values
    person.set(field: personDescriptor.field(named: "name")!, value: .stringValue("John Doe"))
    person.set(field: personDescriptor.field(named: "age")!, value: .intValue(30))

    // Create an address message
    let address = ProtoDynamicMessage(descriptor: addressDescriptor)
    address.set(field: addressDescriptor.field(named: "street")!, value: .stringValue("123 Main St"))
    address.set(field: addressDescriptor.field(named: "city")!, value: .stringValue("Anytown"))

    // Set the address in the person message
    person.set(field: personDescriptor.field(named: "address")!, value: .messageValue(address))
  }

  func testGetValueWithSimplePath() {
    let path = ProtoFieldPath(path: "name")
    let value = path.getValue(from: person)

    XCTAssertNotNil(value)
    XCTAssertEqual(value?.getString(), "John Doe")
  }

  func testGetValueWithNestedPath() {
    let path = ProtoFieldPath(path: "address.street")
    let value = path.getValue(from: person)

    XCTAssertNotNil(value)
    XCTAssertEqual(value?.getString(), "123 Main St")
  }

  func testGetValueWithInvalidPath() {
    let path = ProtoFieldPath(path: "nonexistent")
    let value = path.getValue(from: person)

    XCTAssertNil(value)
  }

  func testGetValueWithInvalidNestedPath() {
    let path = ProtoFieldPath(path: "address.nonexistent")
    let value = path.getValue(from: person)

    XCTAssertNil(value)
  }

  func testSetValueWithSimplePath() {
    let path = ProtoFieldPath(path: "name")
    let result = path.setValue(.stringValue("Jane Doe"), in: person)

    XCTAssertTrue(result)
    XCTAssertEqual(person.get(field: personDescriptor.field(named: "name")!)?.getString(), "Jane Doe")
  }

  func testSetValueWithNestedPath() {
    let path = ProtoFieldPath(path: "address.street")
    let result = path.setValue(.stringValue("456 Oak Ave"), in: person)

    XCTAssertTrue(result)

    let address = person.get(field: personDescriptor.field(named: "address")!)?.getMessage() as? ProtoDynamicMessage
    XCTAssertNotNil(address)
    XCTAssertEqual(address?.get(field: addressDescriptor.field(named: "street")!)?.getString(), "456 Oak Ave")
  }

  func testSetValueWithNonexistentNestedPath() {
    let path = ProtoFieldPath(path: "address.zip_code")
    let result = path.setValue(.intValue(12345), in: person)

    XCTAssertTrue(result)

    let address = person.get(field: personDescriptor.field(named: "address")!)?.getMessage() as? ProtoDynamicMessage
    XCTAssertNotNil(address)
    XCTAssertEqual(address?.get(field: addressDescriptor.field(named: "zip_code")!)?.getInt(), 12345)
  }

  func testSetValueWithInvalidPath() {
    let path = ProtoFieldPath(path: "nonexistent")
    let result = path.setValue(.stringValue("value"), in: person)

    XCTAssertFalse(result)
  }

  func testSetValueWithInvalidNestedPath() {
    let path = ProtoFieldPath(path: "address.nonexistent")
    let result = path.setValue(.stringValue("value"), in: person)

    XCTAssertFalse(result)
  }

  func testClearValueWithSimplePath() {
    let path = ProtoFieldPath(path: "name")
    let result = path.clearValue(in: person)

    XCTAssertTrue(result)
    XCTAssertNil(person.get(field: personDescriptor.field(named: "name")!))
  }

  func testClearValueWithNestedPath() {
    let path = ProtoFieldPath(path: "address.street")
    let result = path.clearValue(in: person)

    XCTAssertTrue(result)

    let address = person.get(field: personDescriptor.field(named: "address")!)?.getMessage() as? ProtoDynamicMessage
    XCTAssertNotNil(address)
    XCTAssertNil(address?.get(field: addressDescriptor.field(named: "street")!))
  }

  func testClearValueWithInvalidPath() {
    let path = ProtoFieldPath(path: "nonexistent")
    let result = path.clearValue(in: person)

    XCTAssertFalse(result)
  }

  func testClearValueWithInvalidNestedPath() {
    let path = ProtoFieldPath(path: "address.nonexistent")
    let result = path.clearValue(in: person)

    XCTAssertFalse(result)
  }

  func testHasValueWithSimplePath() {
    let path = ProtoFieldPath(path: "name")
    let result = path.hasValue(in: person)

    XCTAssertTrue(result)

    path.clearValue(in: person)
    XCTAssertFalse(path.hasValue(in: person))
  }

  func testHasValueWithNestedPath() {
    let path = ProtoFieldPath(path: "address.street")
    let result = path.hasValue(in: person)

    XCTAssertTrue(result)

    path.clearValue(in: person)
    XCTAssertFalse(path.hasValue(in: person))
  }

  func testHasValueWithInvalidPath() {
    let path = ProtoFieldPath(path: "nonexistent")
    let result = path.hasValue(in: person)

    XCTAssertFalse(result)
  }

  func testHasValueWithInvalidNestedPath() {
    let path = ProtoFieldPath(path: "address.nonexistent")
    let result = path.hasValue(in: person)

    XCTAssertFalse(result)
  }

  func testPathDescription() {
    let path = ProtoFieldPath(path: "address.street")
    XCTAssertEqual(path.description(), "address.street")
  }

  func testCreatePathFromComponents() {
    let path = ProtoFieldPath(path: "address.street")
    let value = path.getValue(from: person)

    XCTAssertNotNil(value)
    XCTAssertEqual(value?.getString(), "123 Main St")
  }
}
