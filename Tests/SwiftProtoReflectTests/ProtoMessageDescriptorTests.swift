import XCTest

@testable import SwiftProtoReflect

class ProtoMessageDescriptorTests: XCTestCase {

  // MARK: - Initialization Tests

  func testInitialization() {
    // Given
    let fullName = "TestMessage"
    let fields = [ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)]
    let enums = [ProtoEnumDescriptor(name: "TestEnum", values: [ProtoEnumValueDescriptor(name: "VALUE1", number: 1)])]
    let nestedMessages = [ProtoMessageDescriptor(fullName: "NestedMessage", fields: [], enums: [], nestedMessages: [])]

    // When
    let descriptor = ProtoMessageDescriptor(
      fullName: fullName,
      fields: fields,
      enums: enums,
      nestedMessages: nestedMessages
    )

    // Then
    XCTAssertEqual(descriptor.fullName, fullName)
    XCTAssertEqual(descriptor.fields.count, 1)
    XCTAssertEqual(descriptor.enums.count, 1)
    XCTAssertEqual(descriptor.nestedMessages.count, 1)
  }

  // MARK: - Field Access Tests

  func testFieldAccessByName() {
    // Given
    let field = ProtoFieldDescriptor(name: "testField", number: 1, type: .int32, isRepeated: false, isMap: false)
    let descriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [field],
      enums: [],
      nestedMessages: []
    )

    // When
    let retrievedField = descriptor.field(named: "testField")

    // Then
    XCTAssertNotNil(retrievedField)
    XCTAssertEqual(retrievedField?.name, "testField")
    XCTAssertEqual(retrievedField?.number, 1)
  }

  func testFieldAccessByIndex() {
    // Given
    let field = ProtoFieldDescriptor(name: "testField", number: 1, type: .int32, isRepeated: false, isMap: false)
    let descriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [field],
      enums: [],
      nestedMessages: []
    )

    // When
    let retrievedField = descriptor.field(at: 0)

    // Then
    XCTAssertNotNil(retrievedField)
    XCTAssertEqual(retrievedField?.name, "testField")
    XCTAssertEqual(retrievedField?.number, 1)
  }

  func testFieldAccessByIndexOutOfBounds() {
    // Given
    let descriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)],
      enums: [],
      nestedMessages: []
    )

    // When
    let field = descriptor.field(at: 1)  // Out of bounds

    // Then
    XCTAssertNil(field)
  }

  func testGetNonExistentFieldByName() {
    // Given
    let descriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
      ],
      enums: [],
      nestedMessages: []
    )

    // When
    let field = descriptor.field(named: "nonExistentField")

    // Then
    XCTAssertNil(field)
  }

  // MARK: - Validation Tests

  func testValidMessageDescriptor() {
    // Given
    let descriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
      ],
      enums: [],
      nestedMessages: []
    )

    // Then
    XCTAssertTrue(descriptor.isValid())
    XCTAssertNil(descriptor.validationError())
  }

  func testInvalidMessageDescriptorEmptyName() {
    // Given
    let descriptor = ProtoMessageDescriptor(fullName: "", fields: [], enums: [], nestedMessages: [])

    // Then
    XCTAssertFalse(descriptor.isValid())
    XCTAssertEqual(descriptor.validationError(), "Message full name cannot be empty")
  }

  func testInvalidMessageDescriptorDuplicateFieldNumbers() {
    // Given
    let descriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false),
        // Same number
        ProtoFieldDescriptor(name: "field2", number: 1, type: .string, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Then
    XCTAssertNotNil(descriptor.validationError())
    XCTAssertTrue(descriptor.validationError()?.contains("Duplicate field number") ?? false)
  }

  func testInvalidMessageDescriptorInvalidField() {
    // Given
    let descriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "", number: 1, type: .int32, isRepeated: false, isMap: false)  // Empty name
      ],
      enums: [],
      nestedMessages: []
    )

    // Then
    XCTAssertNotNil(descriptor.validationError())
    XCTAssertTrue(descriptor.validationError()?.contains("Invalid field") ?? false)
  }

  func testInvalidMessageDescriptorInvalidNestedMessage() {
    // Given
    let invalidNestedMessage = ProtoMessageDescriptor(fullName: "", fields: [], enums: [], nestedMessages: [])
    let descriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
      ],
      enums: [],
      nestedMessages: [invalidNestedMessage]
    )

    // Then
    XCTAssertNotNil(descriptor.validationError())
    XCTAssertTrue(descriptor.validationError()?.contains("Invalid nested message") ?? false)
  }

  // MARK: - Edge Case Tests

  func testMessageDescriptorWithManyFields() {
    // Given
    var fields: [ProtoFieldDescriptor] = []
    for i in 1...100 {
      fields.append(ProtoFieldDescriptor(name: "field\(i)", number: i, type: .int32, isRepeated: false, isMap: false))
    }

    // When
    let descriptor = ProtoMessageDescriptor(fullName: "LargeMessage", fields: fields, enums: [], nestedMessages: [])

    // Then
    XCTAssertTrue(descriptor.isValid())
    XCTAssertEqual(descriptor.fields.count, 100)
    XCTAssertNotNil(descriptor.field(named: "field50"))
    XCTAssertEqual(descriptor.field(at: 49)?.number, 50)
  }

  func testNestedMessageHierarchy() {
    // Given
    let deeplyNestedMessage = ProtoMessageDescriptor(
      fullName: "Level3",
      fields: [ProtoFieldDescriptor(name: "deepField", number: 1, type: .int32, isRepeated: false, isMap: false)],
      enums: [],
      nestedMessages: []
    )

    let nestedMessage = ProtoMessageDescriptor(
      fullName: "Level2",
      fields: [ProtoFieldDescriptor(name: "nestedField", number: 1, type: .int32, isRepeated: false, isMap: false)],
      enums: [],
      nestedMessages: [deeplyNestedMessage]
    )

    // When
    let rootMessage = ProtoMessageDescriptor(
      fullName: "Level1",
      fields: [ProtoFieldDescriptor(name: "rootField", number: 1, type: .int32, isRepeated: false, isMap: false)],
      enums: [],
      nestedMessages: [nestedMessage]
    )

    // Then
    XCTAssertTrue(rootMessage.isValid())
    XCTAssertEqual(rootMessage.nestedMessages.count, 1)
    XCTAssertEqual(rootMessage.nestedMessages[0].nestedMessages.count, 1)
  }
}
