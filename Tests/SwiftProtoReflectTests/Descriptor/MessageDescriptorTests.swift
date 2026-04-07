//
// MessageDescriptorTests.swift
// SwiftProtoReflectTests
//
// Created: 2025-05-18
//

import XCTest

@testable import SwiftProtoReflect

/// Tests for MessageDescriptor component.
///
/// Covers all main features including:
/// - Working with nested OneOf fields
/// - Correctness of field types for complex types (messages, enums)
/// - Cyclic dependencies between messages
/// - Handling of imported types
final class MessageDescriptorTests: XCTestCase {
  // MARK: - Properties

  var messageDescriptor: MessageDescriptor!
  var fileDescriptor: FileDescriptor!

  // MARK: - Setup

  override func setUp() async throws {
    try await super.setUp()
    fileDescriptor = FileDescriptor(
      name: "person.proto",
      package: "example.person"
    )

    messageDescriptor = MessageDescriptor(
      name: "Person",
      parent: fileDescriptor,
      options: ["deprecated": .bool(false)]
    )
  }

  override func tearDown() async throws {
    messageDescriptor = nil
    fileDescriptor = nil
    try await super.tearDown()
  }

  // MARK: - Tests

  func testInitialization() async throws {
    XCTAssertEqual(messageDescriptor.name, "Person")
    XCTAssertEqual(messageDescriptor.fullName, "example.person.Person")
    XCTAssertEqual(messageDescriptor.options["deprecated"], .bool(false))
    XCTAssertTrue(messageDescriptor.fields.isEmpty)
    XCTAssertTrue(messageDescriptor.nestedMessages.isEmpty)
    XCTAssertTrue(messageDescriptor.nestedEnums.isEmpty)
    XCTAssertTrue(messageDescriptor.oneofDecls.isEmpty)
    XCTAssertEqual(messageDescriptor.fileDescriptorPath, "person.proto")
    XCTAssertNil(messageDescriptor.parentMessageFullName)
  }

  func testInitializationWithoutParent() async throws {
    let descriptor = MessageDescriptor(name: "Test", fullName: "test.Test")
    XCTAssertEqual(descriptor.name, "Test")
    XCTAssertEqual(descriptor.fullName, "test.Test")
    XCTAssertNil(descriptor.fileDescriptorPath)
    XCTAssertNil(descriptor.parentMessageFullName)
  }

  func testInitializationWithParentMessage() async throws {
    let parentMessage = MessageDescriptor(name: "Parent", fullName: "example.Parent")
    let childMessage = MessageDescriptor(name: "Child", parent: parentMessage)

    XCTAssertEqual(childMessage.name, "Child")
    XCTAssertEqual(childMessage.fullName, "example.Parent.Child")
    XCTAssertNotNil(childMessage.parentMessageFullName)
    XCTAssertEqual(childMessage.parentMessageFullName, "example.Parent")
  }

  func testAddField() async throws {
    let nameField = FieldDescriptor(
      name: "name",
      number: 1,
      type: .string,
      isOptional: true
    )

    messageDescriptor.addField(nameField)

    XCTAssertEqual(messageDescriptor.fields.count, 1)
    XCTAssertTrue(messageDescriptor.hasField(number: 1))
    XCTAssertTrue(messageDescriptor.hasField(named: "name"))
    XCTAssertEqual(messageDescriptor.field(number: 1)?.name, "name")
    XCTAssertEqual(messageDescriptor.field(named: "name")?.number, 1)
  }

  func testAddMultipleFields() async throws {
    let nameField = FieldDescriptor(name: "name", number: 1, type: .string)
    let ageField = FieldDescriptor(name: "age", number: 2, type: .int32)
    let activeField = FieldDescriptor(name: "active", number: 3, type: .bool)

    messageDescriptor.addField(nameField)
    messageDescriptor.addField(ageField)
    messageDescriptor.addField(activeField)

    XCTAssertEqual(messageDescriptor.fields.count, 3)
    XCTAssertTrue(messageDescriptor.hasField(number: 1))
    XCTAssertTrue(messageDescriptor.hasField(number: 2))
    XCTAssertTrue(messageDescriptor.hasField(number: 3))

    // Verify ordered list of fields
    let allFields = messageDescriptor.allFields()
    XCTAssertEqual(allFields.count, 3)
    XCTAssertEqual(allFields[0].number, 1)
    XCTAssertEqual(allFields[1].number, 2)
    XCTAssertEqual(allFields[2].number, 3)
  }

  func testAddFieldReplacement() async throws {
    let nameField1 = FieldDescriptor(name: "name", number: 1, type: .string)
    messageDescriptor.addField(nameField1)

    let nameField2 = FieldDescriptor(name: "name", number: 1, type: .string, isOptional: true)
    messageDescriptor.addField(nameField2)

    XCTAssertEqual(messageDescriptor.fields.count, 1, "Field should be replaced")
    XCTAssertTrue(messageDescriptor.field(number: 1)!.isOptional, "New field should be used")
  }

  func testAddNestedMessage() async throws {
    let addressMessage = MessageDescriptor(name: "Address", parent: messageDescriptor)
    messageDescriptor.addNestedMessage(addressMessage)

    XCTAssertEqual(messageDescriptor.nestedMessages.count, 1)
    XCTAssertTrue(messageDescriptor.hasNestedMessage(named: "Address"))

    let nestedAddress = messageDescriptor.nestedMessage(named: "Address")
    XCTAssertNotNil(nestedAddress)
    XCTAssertEqual(nestedAddress?.name, "Address")
    XCTAssertEqual(nestedAddress?.fullName, "example.person.Person.Address")
    XCTAssertEqual(nestedAddress?.parentMessageFullName, "example.person.Person")
    XCTAssertEqual(nestedAddress?.fileDescriptorPath, "person.proto")
  }

  func testAddNestedEnum() async throws {
    let genderEnum = EnumDescriptor(name: "Gender")
    messageDescriptor.addNestedEnum(genderEnum)

    XCTAssertEqual(messageDescriptor.nestedEnums.count, 1)
    XCTAssertTrue(messageDescriptor.hasNestedEnum(named: "Gender"))

    let nestedGender = messageDescriptor.nestedEnum(named: "Gender")
    XCTAssertNotNil(nestedGender)
    XCTAssertEqual(nestedGender?.name, "Gender")
  }

  func testMessageWithComplexFields() async throws {
    // Create field with message type
    let addressField = FieldDescriptor(
      name: "address",
      number: 1,
      type: .message,
      typeName: "example.person.Address",
      isOptional: true
    )

    // Create field with enum type
    let genderField = FieldDescriptor(
      name: "gender",
      number: 2,
      type: .enum,
      typeName: "example.person.Gender",
      isOptional: true
    )

    // Create repeated field
    let phoneField = FieldDescriptor(
      name: "phones",
      number: 3,
      type: .string,
      isRepeated: true
    )

    messageDescriptor.addField(addressField)
    messageDescriptor.addField(genderField)
    messageDescriptor.addField(phoneField)

    // Verify field types
    guard let addressFieldResult = messageDescriptor.field(number: 1) else {
      XCTFail("Address field not found")
      return
    }

    guard let genderFieldResult = messageDescriptor.field(number: 2) else {
      XCTFail("Gender field not found")
      return
    }

    guard let phoneFieldResult = messageDescriptor.field(number: 3) else {
      XCTFail("Phones field not found")
      return
    }

    // Verify address field type
    XCTAssertEqual(addressFieldResult.type, .message)
    XCTAssertEqual(addressFieldResult.typeName, "example.person.Address")

    // Verify gender field type
    XCTAssertEqual(genderFieldResult.type, .enum)
    XCTAssertEqual(genderFieldResult.typeName, "example.person.Gender")

    // Verify phones field type
    XCTAssertEqual(phoneFieldResult.type, .string)
    XCTAssertTrue(phoneFieldResult.isRepeated)
  }

  // MARK: - Business Tests

  /// Verifies working with nested OneOf fields.
  func testNestedOneOfFields() async throws {
    // Create nested message with OneOf fields
    var addressMessage = MessageDescriptor(name: "Address", parent: messageDescriptor)

    // Add OneOf fields to nested message
    let streetField = FieldDescriptor(
      name: "street",
      number: 1,
      type: .string,
      oneofIndex: 0
    )

    let buildingField = FieldDescriptor(
      name: "building",
      number: 2,
      type: .string,
      oneofIndex: 0
    )

    let poBoxField = FieldDescriptor(
      name: "po_box",
      number: 3,
      type: .string,
      oneofIndex: 1
    )

    addressMessage.addField(streetField)
    addressMessage.addField(buildingField)
    addressMessage.addField(poBoxField)

    messageDescriptor.addNestedMessage(addressMessage)

    // Verify that OneOf fields are correctly added
    let nestedAddress = messageDescriptor.nestedMessage(named: "Address")
    XCTAssertNotNil(nestedAddress)

    let retrievedStreetField = nestedAddress?.field(number: 1)
    let retrievedBuildingField = nestedAddress?.field(number: 2)
    let retrievedPoBoxField = nestedAddress?.field(number: 3)

    XCTAssertEqual(retrievedStreetField?.oneofIndex, 0)
    XCTAssertEqual(retrievedBuildingField?.oneofIndex, 0)
    XCTAssertEqual(retrievedPoBoxField?.oneofIndex, 1)

    // Verify that street and building fields are in the same OneOf group
    XCTAssertEqual(retrievedStreetField?.oneofIndex, retrievedBuildingField?.oneofIndex)
    XCTAssertNotEqual(retrievedStreetField?.oneofIndex, retrievedPoBoxField?.oneofIndex)
  }

  /// Verifies correctness of field type for complex types (messages, enums).
  func testComplexFieldTypes() async throws {
    // Create field with message type
    let addressField = FieldDescriptor(
      name: "address",
      number: 1,
      type: .message,
      typeName: "example.person.Address"
    )

    // Create field with enum type
    let statusField = FieldDescriptor(
      name: "status",
      number: 2,
      type: .enum,
      typeName: "example.person.Status"
    )

    // Create Map field with message type in value
    let mapKeyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let mapValueInfo = ValueFieldInfo(name: "value", number: 2, type: .message, typeName: "example.person.ContactInfo")
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: mapKeyInfo, valueFieldInfo: mapValueInfo)

    let contactsMapField = FieldDescriptor(
      name: "contacts",
      number: 3,
      type: .message,
      typeName: "example.person.ContactsEntry",
      isMap: true,
      mapEntryInfo: mapEntryInfo
    )

    // Create Repeated field with enum type
    let tagsField = FieldDescriptor(
      name: "tags",
      number: 4,
      type: .enum,
      typeName: "example.person.Tag",
      isRepeated: true
    )

    messageDescriptor.addField(addressField)
    messageDescriptor.addField(statusField)
    messageDescriptor.addField(contactsMapField)
    messageDescriptor.addField(tagsField)

    // Verify types and type names
    guard let retrievedAddressField = messageDescriptor.field(number: 1) else {
      XCTFail("Address field not found")
      return
    }

    XCTAssertEqual(retrievedAddressField.type, .message)
    XCTAssertEqual(retrievedAddressField.typeName, "example.person.Address")
    XCTAssertEqual(retrievedAddressField.getFullTypeName(), "example.person.Address")
    XCTAssertFalse(retrievedAddressField.isScalarType())

    guard let retrievedStatusField = messageDescriptor.field(number: 2) else {
      XCTFail("Status field not found")
      return
    }

    XCTAssertEqual(retrievedStatusField.type, .enum)
    XCTAssertEqual(retrievedStatusField.typeName, "example.person.Status")
    XCTAssertFalse(retrievedStatusField.isScalarType())

    // Verify Map field
    guard let retrievedContactsField = messageDescriptor.field(number: 3) else {
      XCTFail("Contacts map field not found")
      return
    }

    XCTAssertTrue(retrievedContactsField.isMap)
    XCTAssertTrue(retrievedContactsField.isRepeated)  // Map fields are automatically repeated
    XCTAssertEqual(retrievedContactsField.type, .message)

    let mapInfo = retrievedContactsField.getMapKeyValueInfo()
    XCTAssertNotNil(mapInfo)
    XCTAssertEqual(mapInfo?.keyFieldInfo.type, .string)
    XCTAssertEqual(mapInfo?.valueFieldInfo.type, .message)
    XCTAssertEqual(mapInfo?.valueFieldInfo.typeName, "example.person.ContactInfo")

    // Verify Repeated enum field
    guard let retrievedTagsField = messageDescriptor.field(number: 4) else {
      XCTFail("Tags repeated field not found")
      return
    }

    XCTAssertTrue(retrievedTagsField.isRepeated)
    XCTAssertEqual(retrievedTagsField.type, .enum)
    XCTAssertEqual(retrievedTagsField.typeName, "example.person.Tag")
  }

  /// Tests cyclic dependencies between messages.
  func testCyclicDependencies() async throws {
    // Create Node message that can reference itself
    var nodeMessage = MessageDescriptor(name: "Node", parent: fileDescriptor)

    // Add field that references the same message (cyclic dependency)
    let parentField = FieldDescriptor(
      name: "parent",
      number: 1,
      type: .message,
      typeName: "example.person.Node",  // Self-reference
      isOptional: true
    )

    let childrenField = FieldDescriptor(
      name: "children",
      number: 2,
      type: .message,
      typeName: "example.person.Node",  // Self-reference
      isRepeated: true
    )

    nodeMessage.addField(parentField)
    nodeMessage.addField(childrenField)

    fileDescriptor.addMessage(nodeMessage)

    // Verify that cyclic references are handled correctly
    let retrievedNode = fileDescriptor.messages["Node"]
    XCTAssertNotNil(retrievedNode)

    let retrievedParentField = retrievedNode?.field(number: 1)
    let retrievedChildrenField = retrievedNode?.field(number: 2)

    XCTAssertEqual(retrievedParentField?.typeName, "example.person.Node")
    XCTAssertEqual(retrievedChildrenField?.typeName, "example.person.Node")
    XCTAssertTrue(retrievedParentField?.isOptional ?? false)
    XCTAssertTrue(retrievedChildrenField?.isRepeated ?? false)

    // Create mutually referencing messages
    var aMessage = MessageDescriptor(name: "A", parent: fileDescriptor)
    var bMessage = MessageDescriptor(name: "B", parent: fileDescriptor)

    let fieldAtoB = FieldDescriptor(
      name: "b_ref",
      number: 1,
      type: .message,
      typeName: "example.person.B"
    )

    let fieldBtoA = FieldDescriptor(
      name: "a_ref",
      number: 1,
      type: .message,
      typeName: "example.person.A"
    )

    aMessage.addField(fieldAtoB)
    bMessage.addField(fieldBtoA)

    fileDescriptor.addMessage(aMessage)
    fileDescriptor.addMessage(bMessage)

    // Verify mutual references
    let retrievedA = fileDescriptor.messages["A"]
    let retrievedB = fileDescriptor.messages["B"]

    XCTAssertNotNil(retrievedA)
    XCTAssertNotNil(retrievedB)

    XCTAssertEqual(retrievedA?.field(number: 1)?.typeName, "example.person.B")
    XCTAssertEqual(retrievedB?.field(number: 1)?.typeName, "example.person.A")
  }

  /// Verifies handling of imported types.
  func testImportedTypes() async throws {
    // Create file with dependencies
    var fileWithImports = FileDescriptor(
      name: "user.proto",
      package: "example.user",
      dependencies: [
        "google/protobuf/timestamp.proto",
        "example/common/address.proto",
        "example/common/types.proto",
      ]
    )

    var userMessage = MessageDescriptor(name: "User", parent: fileWithImports)

    // Add fields with imported types
    let timestampField = FieldDescriptor(
      name: "created_at",
      number: 1,
      type: .message,
      typeName: "google.protobuf.Timestamp"
    )

    let addressField = FieldDescriptor(
      name: "address",
      number: 2,
      type: .message,
      typeName: "example.common.Address"
    )

    let statusField = FieldDescriptor(
      name: "status",
      number: 3,
      type: .enum,
      typeName: "example.common.UserStatus"
    )

    userMessage.addField(timestampField)
    userMessage.addField(addressField)
    userMessage.addField(statusField)

    fileWithImports.addMessage(userMessage)

    // Verify file dependencies
    XCTAssertEqual(fileWithImports.dependencies.count, 3)
    XCTAssertTrue(fileWithImports.dependencies.contains("google/protobuf/timestamp.proto"))
    XCTAssertTrue(fileWithImports.dependencies.contains("example/common/address.proto"))
    XCTAssertTrue(fileWithImports.dependencies.contains("example/common/types.proto"))

    // Verify imported types in fields
    let retrievedUser = fileWithImports.messages["User"]
    XCTAssertNotNil(retrievedUser)

    let retrievedTimestampField = retrievedUser?.field(number: 1)
    XCTAssertEqual(retrievedTimestampField?.typeName, "google.protobuf.Timestamp")
    XCTAssertEqual(retrievedTimestampField?.type, .message)

    let retrievedAddressField = retrievedUser?.field(number: 2)
    XCTAssertEqual(retrievedAddressField?.typeName, "example.common.Address")
    XCTAssertEqual(retrievedAddressField?.type, .message)

    let retrievedStatusField = retrievedUser?.field(number: 3)
    XCTAssertEqual(retrievedStatusField?.typeName, "example.common.UserStatus")
    XCTAssertEqual(retrievedStatusField?.type, .enum)

    // Verify that full names are generated correctly for local types
    XCTAssertEqual(fileWithImports.getFullName(for: "LocalType"), "example.user.LocalType")

    // Verify working with nested messages and imported types
    var profileMessage = MessageDescriptor(name: "Profile", parent: retrievedUser!)

    let avatarField = FieldDescriptor(
      name: "avatar",
      number: 1,
      type: .message,
      typeName: "example.common.Image"
    )

    profileMessage.addField(avatarField)
    userMessage.addNestedMessage(profileMessage)

    // Update message in file
    fileWithImports.addMessage(userMessage)

    // Get updated message
    let updatedUser = fileWithImports.messages["User"]
    let nestedProfile = updatedUser?.nestedMessage(named: "Profile")
    XCTAssertNotNil(nestedProfile)
    XCTAssertEqual(nestedProfile?.fullName, "example.user.User.Profile")
    XCTAssertEqual(nestedProfile?.field(number: 1)?.typeName, "example.common.Image")
  }

  // MARK: - Oneof Decls Tests

  func testAddOneofDecl() async throws {
    let oneof = OneofDescriptor(name: "contact", index: 0)
    messageDescriptor.addOneofDecl(oneof)

    XCTAssertEqual(messageDescriptor.oneofDecls.count, 1)
    XCTAssertEqual(messageDescriptor.oneofDecls[0].name, "contact")
    XCTAssertEqual(messageDescriptor.oneofDecls[0].index, 0)

    let found = messageDescriptor.oneof(at: 0)
    XCTAssertNotNil(found)
    XCTAssertEqual(found?.name, "contact")
    XCTAssertEqual(found?.index, 0)
  }

  func testAddMultipleOneofDecls() async throws {
    let oneof0 = OneofDescriptor(name: "contact", index: 0)
    let oneof1 = OneofDescriptor(name: "identifier", index: 1)
    messageDescriptor.addOneofDecl(oneof0)
    messageDescriptor.addOneofDecl(oneof1)

    XCTAssertEqual(messageDescriptor.oneofDecls.count, 2)

    let found0 = messageDescriptor.oneof(at: 0)
    XCTAssertNotNil(found0)
    XCTAssertEqual(found0?.name, "contact")

    let found1 = messageDescriptor.oneof(at: 1)
    XCTAssertNotNil(found1)
    XCTAssertEqual(found1?.name, "identifier")
  }

  func testOneofAtIndexNotFound() async throws {
    let oneof = OneofDescriptor(name: "contact", index: 0)
    messageDescriptor.addOneofDecl(oneof)

    XCTAssertNil(messageDescriptor.oneof(at: 99))
  }

  func testOneofDeclsOrderedByInsertion() async throws {
    let oneofC = OneofDescriptor(name: "c_group", index: 2)
    let oneofA = OneofDescriptor(name: "a_group", index: 0)
    let oneofB = OneofDescriptor(name: "b_group", index: 1)
    messageDescriptor.addOneofDecl(oneofC)
    messageDescriptor.addOneofDecl(oneofA)
    messageDescriptor.addOneofDecl(oneofB)

    XCTAssertEqual(messageDescriptor.oneofDecls[0].name, "c_group")
    XCTAssertEqual(messageDescriptor.oneofDecls[1].name, "a_group")
    XCTAssertEqual(messageDescriptor.oneofDecls[2].name, "b_group")
  }

  func testAddOneofDeclReturnsSelf() async throws {
    let oneof0 = OneofDescriptor(name: "contact", index: 0)
    let oneof1 = OneofDescriptor(name: "identifier", index: 1)

    let returned = messageDescriptor.addOneofDecl(oneof0)
    XCTAssertEqual(returned.oneofDecls.count, 1)
    XCTAssertEqual(returned.oneofDecls[0].name, "contact")

    messageDescriptor.addOneofDecl(oneof1)
    XCTAssertEqual(messageDescriptor.oneofDecls.count, 2)
    XCTAssertEqual(messageDescriptor.oneofDecls[1].name, "identifier")
  }

  // MARK: - OPE-221 MessageDescriptor oneof API (T-MD-07…17)

  func test_messageDescriptor_whenFieldsAndOneofDeclsAdded_remainIndependent_TMD07() async throws {
    messageDescriptor.addField(
      FieldDescriptor(name: "email", number: 1, type: .string, oneofIndex: 0)
    )
    messageDescriptor.addOneofDecl(OneofDescriptor(name: "contact", index: 0))
    XCTAssertEqual(messageDescriptor.fields.count, 1)
    XCTAssertEqual(messageDescriptor.oneofDecls.count, 1)
  }

  func test_messageDescriptor_fieldOneofIndexResolvesViaOneofAt_TMD08() async throws {
    messageDescriptor.addField(
      FieldDescriptor(name: "email", number: 2, type: .string, oneofIndex: 0)
    )
    messageDescriptor.addOneofDecl(OneofDescriptor(name: "contact", index: 0))
    guard let idx = messageDescriptor.field(named: "email")?.oneofIndex else {
      XCTFail("expected oneofIndex")
      return
    }
    XCTAssertEqual(messageDescriptor.oneof(at: idx)?.name, "contact")
  }

  func test_messageDescriptor_allFieldsOneofLookup_returnsGroupName_TMD09() async throws {
    messageDescriptor.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    messageDescriptor.addField(
      FieldDescriptor(name: "email", number: 2, type: .string, oneofIndex: 0)
    )
    messageDescriptor.addField(
      FieldDescriptor(name: "phone", number: 3, type: .string, oneofIndex: 0)
    )
    messageDescriptor.addOneofDecl(OneofDescriptor(name: "contact", index: 0))

    for field in messageDescriptor.allFields() {
      if let idx = field.oneofIndex {
        XCTAssertEqual(messageDescriptor.oneof(at: idx)?.name, "contact")
      }
    }
  }

  func test_messageDescriptor_nestedMessage_hasIndependentOneofDecls_TMD10() async throws {
    var parent = MessageDescriptor(name: "Parent", fullName: "Parent")
    var child = MessageDescriptor(name: "Child", fullName: "Parent.Child")
    child.addOneofDecl(OneofDescriptor(name: "childGroup", index: 0))
    parent.addNestedMessage(child)
    XCTAssertTrue(parent.oneofDecls.isEmpty)
    XCTAssertEqual(parent.nestedMessage(named: "Child")?.oneofDecls.count, 1)
  }

  func test_messageDescriptor_whenOneofDeclsEmpty_oneofAtReturnsNil_TMD12() async throws {
    XCTAssertTrue(messageDescriptor.oneofDecls.isEmpty)
    XCTAssertNil(messageDescriptor.oneof(at: 0))
  }

  func test_messageDescriptor_whenFieldHasNoOneofIndex_oneofLookupNotUsed_TMD13() async throws {
    messageDescriptor.addField(FieldDescriptor(name: "plain", number: 1, type: .string))
    messageDescriptor.addOneofDecl(OneofDescriptor(name: "contact", index: 0))
    XCTAssertNil(messageDescriptor.field(named: "plain")?.oneofIndex)
  }

  func test_messageDescriptor_whenDuplicateOneofIndex_oneofAtReturnsFirst_TMD14() async throws {
    messageDescriptor.addOneofDecl(OneofDescriptor(name: "first", index: 0))
    messageDescriptor.addOneofDecl(OneofDescriptor(name: "second", index: 0))
    XCTAssertEqual(messageDescriptor.oneofDecls.count, 2)
    XCTAssertEqual(messageDescriptor.oneof(at: 0)?.name, "first")
  }

  func test_messageDescriptor_whenDuplicateNameDifferentIndex_bothStored_TMD15() async throws {
    messageDescriptor.addOneofDecl(OneofDescriptor(name: "x", index: 0))
    messageDescriptor.addOneofDecl(OneofDescriptor(name: "x", index: 1))
    XCTAssertEqual(messageDescriptor.oneof(at: 0)?.name, "x")
    XCTAssertEqual(messageDescriptor.oneof(at: 1)?.name, "x")
  }

  func test_messageDescriptor_whenFieldOneofIndexHasNoMatchingDecl_oneofAtReturnsNil_TMD16() async throws {
    messageDescriptor.addField(
      FieldDescriptor(name: "orphan", number: 1, type: .string, oneofIndex: 2)
    )
    messageDescriptor.addOneofDecl(OneofDescriptor(name: "only", index: 0))
    XCTAssertNil(messageDescriptor.oneof(at: 2))
  }

  func test_messageDescriptor_whenOneofDeclAddedAfterFields_lookupStillWorks_TMD17() async throws {
    messageDescriptor.addField(
      FieldDescriptor(name: "email", number: 2, type: .string, oneofIndex: 0)
    )
    messageDescriptor.addOneofDecl(OneofDescriptor(name: "contact", index: 0))
    XCTAssertEqual(messageDescriptor.oneof(at: 0)?.name, "contact")

    var other = MessageDescriptor(name: "M2", fullName: "M2")
    other.addOneofDecl(OneofDescriptor(name: "g", index: 0))
    other.addField(FieldDescriptor(name: "f", number: 1, type: .string, oneofIndex: 0))
    XCTAssertEqual(other.oneof(at: 0)?.name, "g")
  }

  // MARK: - _MessageDescriptor.isExtensionNumber (internal)

  func test_internalMessageDescriptor_isExtensionNumber_trueWhenInRange() throws {
    var desc = _MessageDescriptor(name: "M", fullName: "M")
    desc.addExtensionRange(_ExtensionRange(start: 100, end: 200))

    XCTAssertTrue(desc.isExtensionNumber(100))
    XCTAssertTrue(desc.isExtensionNumber(150))
    XCTAssertTrue(desc.isExtensionNumber(199))
  }

  func test_internalMessageDescriptor_isExtensionNumber_falseWhenOutsideRange() throws {
    var desc = _MessageDescriptor(name: "M", fullName: "M")
    desc.addExtensionRange(_ExtensionRange(start: 100, end: 200))

    XCTAssertFalse(desc.isExtensionNumber(99))
    XCTAssertFalse(desc.isExtensionNumber(200))
    XCTAssertFalse(desc.isExtensionNumber(50))
  }

  func test_internalMessageDescriptor_isExtensionNumber_falseWhenNoRanges() throws {
    let desc = _MessageDescriptor(name: "M", fullName: "M")
    XCTAssertFalse(desc.isExtensionNumber(100))
  }

  // MARK: - Helpers
}
