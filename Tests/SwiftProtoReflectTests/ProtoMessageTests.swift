import XCTest

@testable import SwiftProtoReflect

class ProtoMessageTests: XCTestCase {

  var descriptor: ProtoMessageDescriptor!
  var message: ProtoMessage!

  override func setUp() {
    super.setUp()
    descriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "testField", number: 1, type: .int32, isRepeated: false, isMap: false)
      ],
      enums: [],
      nestedMessages: []
    )
    message = ProtoDynamicMessage(descriptor: descriptor)
  }

  // Positive Test: Retrieve field value using get
  func testGetFieldValue() {
    message.set(field: descriptor.fields[0], value: .intValue(123))
    let value = message.get(field: descriptor.fields[0])
    XCTAssertEqual(value?.getInt(), 123)
  }

  // Positive Test: Set field value
  func testSetFieldValue() {
    message.set(field: descriptor.fields[0], value: .intValue(456))
    let value = message.get(field: descriptor.fields[0])
    XCTAssertEqual(value?.getInt(), 456)
  }

  // Negative Test: Retrieve non-existent field
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

  // Positive Test: Clear field value
  func testClearFieldValue() {
    message.set(field: descriptor.fields[0], value: .intValue(789))
    message.clear(field: descriptor.fields[0])
    let value = message.get(field: descriptor.fields[0])
    XCTAssertNil(value)
  }

  // Negative Test: Set invalid field value type
  func testSetInvalidFieldType() {
    message.set(field: descriptor.fields[0], value: .stringValue("invalid"))
    let value = message.get(field: descriptor.fields[0])
    XCTAssertNil(value?.getInt())
  }

  // Positive Test: Message validity
  func testIsValidMessage() {
    XCTAssertTrue(message.isValid())
  }

  // Negative Test: Invalid message
  func testInvalidMessage() {
    let invalidDescriptor = ProtoMessageDescriptor(fullName: "", fields: [], enums: [], nestedMessages: [])
    let invalidMessage = ProtoDynamicMessage(descriptor: invalidDescriptor)
    XCTAssertFalse(invalidMessage.isValid())
  }
}
