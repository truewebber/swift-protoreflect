//
// MessageDescriptorTests.swift
// SwiftProtoReflectTests
//
// Создан: 2025-05-18
//

import XCTest

@testable import SwiftProtoReflect

/// Тесты для компонента MessageDescriptor.
///
/// Покрывает все основные функции включая:
/// - Работу с вложенными OneOf полями
/// - Корректность типов полей для сложных типов (сообщения, перечисления)
/// - Циклические зависимости между сообщениями
/// - Обработку импортированных типов
final class MessageDescriptorTests: XCTestCase {
  // MARK: - Properties

  var messageDescriptor: MessageDescriptor!
  var fileDescriptor: FileDescriptor!

  // MARK: - Setup

  override func setUp() {
    super.setUp()
    fileDescriptor = FileDescriptor(
      name: "person.proto",
      package: "example.person"
    )

    messageDescriptor = MessageDescriptor(
      name: "Person",
      parent: fileDescriptor,
      options: ["deprecated": false]
    )
  }

  override func tearDown() {
    messageDescriptor = nil
    fileDescriptor = nil
    super.tearDown()
  }

  // MARK: - Tests

  func testInitialization() {
    XCTAssertEqual(messageDescriptor.name, "Person")
    XCTAssertEqual(messageDescriptor.fullName, "example.person.Person")
    XCTAssertEqual(messageDescriptor.options["deprecated"] as? Bool, false)
    XCTAssertTrue(messageDescriptor.fields.isEmpty)
    XCTAssertTrue(messageDescriptor.nestedMessages.isEmpty)
    XCTAssertTrue(messageDescriptor.nestedEnums.isEmpty)
    XCTAssertEqual(messageDescriptor.fileDescriptorPath, "person.proto")
    XCTAssertNil(messageDescriptor.parentMessageFullName)
  }

  func testInitializationWithoutParent() {
    let descriptor = MessageDescriptor(name: "Test", fullName: "test.Test")
    XCTAssertEqual(descriptor.name, "Test")
    XCTAssertEqual(descriptor.fullName, "test.Test")
    XCTAssertNil(descriptor.fileDescriptorPath)
    XCTAssertNil(descriptor.parentMessageFullName)
  }

  func testInitializationWithParentMessage() {
    let parentMessage = MessageDescriptor(name: "Parent", fullName: "example.Parent")
    let childMessage = MessageDescriptor(name: "Child", parent: parentMessage)

    XCTAssertEqual(childMessage.name, "Child")
    XCTAssertEqual(childMessage.fullName, "example.Parent.Child")
    XCTAssertNotNil(childMessage.parentMessageFullName)
    XCTAssertEqual(childMessage.parentMessageFullName, "example.Parent")
  }

  func testAddField() {
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

  func testAddMultipleFields() {
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

    // Проверяем упорядоченный список полей
    let allFields = messageDescriptor.allFields()
    XCTAssertEqual(allFields.count, 3)
    XCTAssertEqual(allFields[0].number, 1)
    XCTAssertEqual(allFields[1].number, 2)
    XCTAssertEqual(allFields[2].number, 3)
  }

  func testAddFieldReplacement() {
    let nameField1 = FieldDescriptor(name: "name", number: 1, type: .string)
    messageDescriptor.addField(nameField1)

    let nameField2 = FieldDescriptor(name: "name", number: 1, type: .string, isOptional: true)
    messageDescriptor.addField(nameField2)

    XCTAssertEqual(messageDescriptor.fields.count, 1, "Поле должно быть заменено")
    XCTAssertTrue(messageDescriptor.field(number: 1)!.isOptional, "Должно быть использовано новое поле")
  }

  func testAddNestedMessage() {
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

  func testAddNestedEnum() {
    let genderEnum = EnumDescriptor(name: "Gender")
    messageDescriptor.addNestedEnum(genderEnum)

    XCTAssertEqual(messageDescriptor.nestedEnums.count, 1)
    XCTAssertTrue(messageDescriptor.hasNestedEnum(named: "Gender"))

    let nestedGender = messageDescriptor.nestedEnum(named: "Gender")
    XCTAssertNotNil(nestedGender)
    XCTAssertEqual(nestedGender?.name, "Gender")
  }

  func testMessageWithComplexFields() {
    // Создаем поле с типом сообщения
    let addressField = FieldDescriptor(
      name: "address",
      number: 1,
      type: .message,
      typeName: "example.person.Address",
      isOptional: true
    )

    // Создаем поле с типом перечисления
    let genderField = FieldDescriptor(
      name: "gender",
      number: 2,
      type: .enum,
      typeName: "example.person.Gender",
      isOptional: true
    )

    // Создаем повторяющееся поле
    let phoneField = FieldDescriptor(
      name: "phones",
      number: 3,
      type: .string,
      isRepeated: true
    )

    messageDescriptor.addField(addressField)
    messageDescriptor.addField(genderField)
    messageDescriptor.addField(phoneField)

    // Проверяем типы полей
    guard let addressFieldResult = messageDescriptor.field(number: 1) else {
      XCTFail("Поле address не найдено")
      return
    }

    guard let genderFieldResult = messageDescriptor.field(number: 2) else {
      XCTFail("Поле gender не найдено")
      return
    }

    guard let phoneFieldResult = messageDescriptor.field(number: 3) else {
      XCTFail("Поле phones не найдено")
      return
    }

    // Проверяем тип поля address
    XCTAssertEqual(addressFieldResult.type, .message)
    XCTAssertEqual(addressFieldResult.typeName, "example.person.Address")

    // Проверяем тип поля gender
    XCTAssertEqual(genderFieldResult.type, .enum)
    XCTAssertEqual(genderFieldResult.typeName, "example.person.Gender")

    // Проверяем тип поля phones
    XCTAssertEqual(phoneFieldResult.type, .string)
    XCTAssertTrue(phoneFieldResult.isRepeated)
  }

  // MARK: - Business Tests

  /// Проверяет работу с вложенными OneOf полями.
  func testNestedOneOfFields() {
    // Создаем вложенное сообщение с OneOf полями
    var addressMessage = MessageDescriptor(name: "Address", parent: messageDescriptor)
    
    // Добавляем OneOf поля в вложенное сообщение
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
    
    // Проверяем, что OneOf поля корректно добавлены
    let nestedAddress = messageDescriptor.nestedMessage(named: "Address")
    XCTAssertNotNil(nestedAddress)
    
    let retrievedStreetField = nestedAddress?.field(number: 1)
    let retrievedBuildingField = nestedAddress?.field(number: 2)
    let retrievedPoBoxField = nestedAddress?.field(number: 3)
    
    XCTAssertEqual(retrievedStreetField?.oneofIndex, 0)
    XCTAssertEqual(retrievedBuildingField?.oneofIndex, 0)
    XCTAssertEqual(retrievedPoBoxField?.oneofIndex, 1)
    
    // Проверяем, что поля street и building в одной OneOf группе
    XCTAssertEqual(retrievedStreetField?.oneofIndex, retrievedBuildingField?.oneofIndex)
    XCTAssertNotEqual(retrievedStreetField?.oneofIndex, retrievedPoBoxField?.oneofIndex)
  }

  /// Проверяет корректность типа поля для сложных типов (сообщения, перечисления).
  func testComplexFieldTypes() {
    // Создаем поле с типом сообщения
    let addressField = FieldDescriptor(
      name: "address",
      number: 1,
      type: .message,
      typeName: "example.person.Address"
    )
    
    // Создаем поле с типом перечисления
    let statusField = FieldDescriptor(
      name: "status",
      number: 2,
      type: .enum,
      typeName: "example.person.Status"
    )
    
    // Создаем Map поле с типом сообщения в значении
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
    
    // Создаем Repeated поле с типом перечисления
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
    
    // Проверяем типы и имена типов
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
    
    // Проверяем Map поле
    guard let retrievedContactsField = messageDescriptor.field(number: 3) else {
      XCTFail("Contacts map field not found")
      return
    }
    
    XCTAssertTrue(retrievedContactsField.isMap)
    XCTAssertTrue(retrievedContactsField.isRepeated) // Map поля автоматически repeated
    XCTAssertEqual(retrievedContactsField.type, .message)
    
    let mapInfo = retrievedContactsField.getMapKeyValueInfo()
    XCTAssertNotNil(mapInfo)
    XCTAssertEqual(mapInfo?.keyFieldInfo.type, .string)
    XCTAssertEqual(mapInfo?.valueFieldInfo.type, .message)
    XCTAssertEqual(mapInfo?.valueFieldInfo.typeName, "example.person.ContactInfo")
    
    // Проверяем Repeated enum поле
    guard let retrievedTagsField = messageDescriptor.field(number: 4) else {
      XCTFail("Tags repeated field not found")
      return
    }
    
    XCTAssertTrue(retrievedTagsField.isRepeated)
    XCTAssertEqual(retrievedTagsField.type, .enum)
    XCTAssertEqual(retrievedTagsField.typeName, "example.person.Tag")
  }

  /// Тестирует циклические зависимости между сообщениями.
  func testCyclicDependencies() {
    // Создаем сообщение Node, которое может ссылаться само на себя
    var nodeMessage = MessageDescriptor(name: "Node", parent: fileDescriptor)
    
    // Добавляем поле, которое ссылается на то же сообщение (циклическая зависимость)
    let parentField = FieldDescriptor(
      name: "parent",
      number: 1,
      type: .message,
      typeName: "example.person.Node", // Ссылка на себя
      isOptional: true
    )
    
    let childrenField = FieldDescriptor(
      name: "children",
      number: 2,
      type: .message,
      typeName: "example.person.Node", // Ссылка на себя
      isRepeated: true
    )
    
    nodeMessage.addField(parentField)
    nodeMessage.addField(childrenField)
    
    fileDescriptor.addMessage(nodeMessage)
    
    // Проверяем, что циклические ссылки обрабатываются корректно
    let retrievedNode = fileDescriptor.messages["Node"]
    XCTAssertNotNil(retrievedNode)
    
    let retrievedParentField = retrievedNode?.field(number: 1)
    let retrievedChildrenField = retrievedNode?.field(number: 2)
    
    XCTAssertEqual(retrievedParentField?.typeName, "example.person.Node")
    XCTAssertEqual(retrievedChildrenField?.typeName, "example.person.Node")
    XCTAssertTrue(retrievedParentField?.isOptional ?? false)
    XCTAssertTrue(retrievedChildrenField?.isRepeated ?? false)
    
    // Создаем взаимно ссылающиеся сообщения
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
    
    // Проверяем взаимные ссылки
    let retrievedA = fileDescriptor.messages["A"]
    let retrievedB = fileDescriptor.messages["B"]
    
    XCTAssertNotNil(retrievedA)
    XCTAssertNotNil(retrievedB)
    
    XCTAssertEqual(retrievedA?.field(number: 1)?.typeName, "example.person.B")
    XCTAssertEqual(retrievedB?.field(number: 1)?.typeName, "example.person.A")
  }

  /// Проверяет обработку импортированных типов.
  func testImportedTypes() {
    // Создаем файл с зависимостями
    var fileWithImports = FileDescriptor(
      name: "user.proto",
      package: "example.user",
      dependencies: [
        "google/protobuf/timestamp.proto",
        "example/common/address.proto",
        "example/common/types.proto"
      ]
    )
    
    var userMessage = MessageDescriptor(name: "User", parent: fileWithImports)
    
    // Добавляем поля с импортированными типами
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
    
    // Проверяем зависимости файла
    XCTAssertEqual(fileWithImports.dependencies.count, 3)
    XCTAssertTrue(fileWithImports.dependencies.contains("google/protobuf/timestamp.proto"))
    XCTAssertTrue(fileWithImports.dependencies.contains("example/common/address.proto"))
    XCTAssertTrue(fileWithImports.dependencies.contains("example/common/types.proto"))
    
    // Проверяем импортированные типы в полях
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
    
    // Проверяем, что полные имена генерируются корректно для локальных типов
    XCTAssertEqual(fileWithImports.getFullName(for: "LocalType"), "example.user.LocalType")
    
    // Проверяем работу с вложенными сообщениями и импортированными типами
    var profileMessage = MessageDescriptor(name: "Profile", parent: retrievedUser!)
    
    let avatarField = FieldDescriptor(
      name: "avatar",
      number: 1,
      type: .message,
      typeName: "example.common.Image"
    )
    
    profileMessage.addField(avatarField)
    userMessage.addNestedMessage(profileMessage)
    
    // Обновляем сообщение в файле
    fileWithImports.addMessage(userMessage)
    
    // Получаем обновленное сообщение
    let updatedUser = fileWithImports.messages["User"]
    let nestedProfile = updatedUser?.nestedMessage(named: "Profile")
    XCTAssertNotNil(nestedProfile)
    XCTAssertEqual(nestedProfile?.fullName, "example.user.User.Profile")
    XCTAssertEqual(nestedProfile?.field(number: 1)?.typeName, "example.common.Image")
  }

  // MARK: - Helpers
}
