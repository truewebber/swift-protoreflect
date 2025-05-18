//
// MessageDescriptorTests.swift
// SwiftProtoReflectTests
//
// Создан: 2025-05-18
//

import XCTest
@testable import SwiftProtoReflect

/// Тесты для компонента MessageDescriptor
///
/// # TODO: Расширение тестов
/// - Проверить работу с вложенными OneOf полями
/// - Проверить корректность типа поля для сложных типов (сообщения, перечисления)
/// - Тестировать циклические зависимости между сообщениями
/// - Проверить обработку импортированных типов
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
      type: .message("example.person.Address"),
      isOptional: true
    )
    
    // Создаем поле с типом перечисления
    let genderField = FieldDescriptor(
      name: "gender",
      number: 2,
      type: .enum("example.person.Gender"),
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
    if case .message(let typeName) = addressFieldResult.type {
      XCTAssertEqual(typeName, "example.person.Address")
    } else {
      XCTFail("Поле address должно иметь тип .message")
    }
    
    // Проверяем тип поля gender
    if case .enum(let typeName) = genderFieldResult.type {
      XCTAssertEqual(typeName, "example.person.Gender")
    } else {
      XCTFail("Поле gender должно иметь тип .enum")
    }
    
    // Проверяем тип поля phones
    if case .string = phoneFieldResult.type {
      XCTAssertTrue(phoneFieldResult.isRepeated)
    } else {
      XCTFail("Поле phones должно иметь тип .string")
    }
  }
  
  // MARK: - Helpers
}
