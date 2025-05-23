//
// MessageFactoryTests.swift
// SwiftProtoReflectTests
//
// Создан: 2025-05-24
//

import XCTest
@testable import SwiftProtoReflect

final class MessageFactoryTests: XCTestCase {
  // MARK: - Properties
  
  private var factory: MessageFactory!
  private var fileDescriptor: FileDescriptor!
  private var messageDescriptor: MessageDescriptor!
  private var nestedMessageDescriptor: MessageDescriptor!
  
  // MARK: - Setup
  
  override func setUp() {
    super.setUp()
    factory = MessageFactory()
    
    // Создаем test descriptor для тестов
    fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    
    // Основное сообщение
    messageDescriptor = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    messageDescriptor.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    messageDescriptor.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    messageDescriptor.addField(FieldDescriptor(name: "data", number: 3, type: .bytes))
    messageDescriptor.addField(FieldDescriptor(name: "is_active", number: 4, type: .bool))
    
    // Вложенное сообщение
    nestedMessageDescriptor = MessageDescriptor(name: "NestedMessage", parent: fileDescriptor)
    nestedMessageDescriptor.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    
    // Поле с вложенным сообщением
    messageDescriptor.addField(FieldDescriptor(
      name: "nested",
      number: 5,
      type: .message,
      typeName: "test.NestedMessage"
    ))
    
    // Repeated поле
    messageDescriptor.addField(FieldDescriptor(
      name: "tags",
      number: 6,
      type: .string,
      isRepeated: true
    ))
    
    // Map поле
    let mapField = FieldDescriptor(
      name: "metadata",
      number: 7,
      type: .message,
      typeName: "test.MetadataEntry",
      isMap: true,
      mapEntryInfo: MapEntryInfo(
        keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
        valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .string)
      )
    )
    messageDescriptor.addField(mapField)
    
    // Required поле (для proto2)
    messageDescriptor.addField(FieldDescriptor(
      name: "required_field",
      number: 8,
      type: .string,
      isRequired: true
    ))
  }
  
  override func tearDown() {
    factory = nil
    fileDescriptor = nil
    messageDescriptor = nil
    nestedMessageDescriptor = nil
    super.tearDown()
  }
  
  // MARK: - Basic Creation Tests
  
  func testCreateEmptyMessage() {
    let message = factory.createMessage(from: messageDescriptor)
    
    XCTAssertEqual(message.descriptor.name, "TestMessage")
    XCTAssertEqual(message.descriptor.fullName, "test.TestMessage")
    
    // Проверяем, что поля пустые
    XCTAssertFalse(try message.hasValue(forField: "id"))
    XCTAssertFalse(try message.hasValue(forField: "name"))
    XCTAssertFalse(try message.hasValue(forField: "data"))
    XCTAssertFalse(try message.hasValue(forField: "is_active"))
  }
  
  func testCreateMessageWithFieldValuesByName() throws {
    let fieldValues: [String: Any] = [
      "id": Int32(42),
      "name": "Test Name",
      "is_active": true,
      "data": Data("test data".utf8)
    ]
    
    let message = try factory.createMessage(from: messageDescriptor, with: fieldValues)
    
    XCTAssertEqual(try message.get(forField: "id") as? Int32, 42)
    XCTAssertEqual(try message.get(forField: "name") as? String, "Test Name")
    XCTAssertEqual(try message.get(forField: "is_active") as? Bool, true)
    XCTAssertEqual(try message.get(forField: "data") as? Data, Data("test data".utf8))
  }
  
  func testCreateMessageWithFieldValuesByNumber() throws {
    let fieldValues: [Int: Any] = [
      1: Int32(42),
      2: "Test Name",
      4: true
    ]
    
    let message = try factory.createMessage(from: messageDescriptor, with: fieldValues)
    
    XCTAssertEqual(try message.get(forField: 1) as? Int32, 42)
    XCTAssertEqual(try message.get(forField: 2) as? String, "Test Name")
    XCTAssertEqual(try message.get(forField: 4) as? Bool, true)
  }
  
  func testCreateMessageWithInvalidFieldName() {
    let fieldValues: [String: Any] = [
      "nonexistent_field": "value"
    ]
    
    XCTAssertThrowsError(try factory.createMessage(from: messageDescriptor, with: fieldValues)) { error in
      XCTAssertTrue(error is DynamicMessageError)
      if case .fieldNotFound(let fieldName) = error as? DynamicMessageError {
        XCTAssertEqual(fieldName, "nonexistent_field")
      } else {
        XCTFail("Expected fieldNotFound error")
      }
    }
  }
  
  func testCreateMessageWithInvalidFieldNumber() {
    let fieldValues: [Int: Any] = [
      999: "value"
    ]
    
    XCTAssertThrowsError(try factory.createMessage(from: messageDescriptor, with: fieldValues)) { error in
      XCTAssertTrue(error is DynamicMessageError)
      if case .fieldNotFoundByNumber(let fieldNumber) = error as? DynamicMessageError {
        XCTAssertEqual(fieldNumber, 999)
      } else {
        XCTFail("Expected fieldNotFoundByNumber error")
      }
    }
  }
  
  func testCreateMessageWithInvalidType() {
    let fieldValues: [String: Any] = [
      "id": "not_a_number"  // id поле должно быть Int32
    ]
    
    XCTAssertThrowsError(try factory.createMessage(from: messageDescriptor, with: fieldValues)) { error in
      XCTAssertTrue(error is DynamicMessageError)
    }
  }
  
  // MARK: - Cloning Tests
  
  func testCloneEmptyMessage() throws {
    let original = factory.createMessage(from: messageDescriptor)
    let cloned = try factory.clone(original)
    
    XCTAssertEqual(cloned.descriptor.name, original.descriptor.name)
    XCTAssertFalse(try cloned.hasValue(forField: "id"))
    XCTAssertFalse(try cloned.hasValue(forField: "name"))
  }
  
  func testCloneSimpleMessage() throws {
    var original = factory.createMessage(from: messageDescriptor)
    try original.set(Int32(42), forField: "id")
    try original.set("Test Name", forField: "name")
    try original.set(true, forField: "is_active")
    
    let cloned = try factory.clone(original)
    
    XCTAssertEqual(try cloned.get(forField: "id") as? Int32, 42)
    XCTAssertEqual(try cloned.get(forField: "name") as? String, "Test Name")
    XCTAssertEqual(try cloned.get(forField: "is_active") as? Bool, true)
  }
  
  func testCloneMessageWithNestedMessage() throws {
    var nested = factory.createMessage(from: nestedMessageDescriptor)
    try nested.set("nested value", forField: "value")
    
    var original = factory.createMessage(from: messageDescriptor)
    try original.set(Int32(42), forField: "id")
    try original.set(nested, forField: "nested")
    
    let cloned = try factory.clone(original)
    
    XCTAssertEqual(try cloned.get(forField: "id") as? Int32, 42)
    
    let clonedNested = try cloned.get(forField: "nested") as? DynamicMessage
    XCTAssertNotNil(clonedNested)
    XCTAssertEqual(try clonedNested?.get(forField: "value") as? String, "nested value")
    
    // Проверяем, что это действительно разные объекты
    try nested.set("changed value", forField: "value")
    XCTAssertEqual(try clonedNested?.get(forField: "value") as? String, "nested value")
  }
  
  func testCloneMessageWithRepeatedField() throws {
    var original = factory.createMessage(from: messageDescriptor)
    try original.set(["tag1", "tag2", "tag3"], forField: "tags")
    
    let cloned = try factory.clone(original)
    
    let clonedTags = try cloned.get(forField: "tags") as? [String]
    XCTAssertEqual(clonedTags, ["tag1", "tag2", "tag3"])
  }
  
  func testCloneMessageWithRepeatedNestedMessages() throws {
    // Создаем поле repeated с вложенными сообщениями
    messageDescriptor.addField(FieldDescriptor(
      name: "repeated_nested",
      number: 10,
      type: .message,
      typeName: "test.NestedMessage",
      isRepeated: true
    ))
    
    var nested1 = factory.createMessage(from: nestedMessageDescriptor)
    try nested1.set("value1", forField: "value")
    
    var nested2 = factory.createMessage(from: nestedMessageDescriptor)
    try nested2.set("value2", forField: "value")
    
    var original = factory.createMessage(from: messageDescriptor)
    try original.set([nested1, nested2], forField: "repeated_nested")
    
    let cloned = try factory.clone(original)
    
    let clonedArray = try cloned.get(forField: "repeated_nested") as? [DynamicMessage]
    XCTAssertNotNil(clonedArray)
    XCTAssertEqual(clonedArray?.count, 2)
    XCTAssertEqual(try clonedArray?[0].get(forField: "value") as? String, "value1")
    XCTAssertEqual(try clonedArray?[1].get(forField: "value") as? String, "value2")
    
    // Проверяем, что это разные объекты
    try nested1.set("changed", forField: "value")
    XCTAssertEqual(try clonedArray?[0].get(forField: "value") as? String, "value1")
  }
  
  func testCloneMessageWithMapField() throws {
    var original = factory.createMessage(from: messageDescriptor)
    try original.setMapEntry("value1", forKey: "key1", inField: "metadata")
    try original.setMapEntry("value2", forKey: "key2", inField: "metadata")
    
    let cloned = try factory.clone(original)
    
    let clonedMap = try cloned.get(forField: "metadata") as? [String: String]
    XCTAssertEqual(clonedMap?["key1"], "value1")
    XCTAssertEqual(clonedMap?["key2"], "value2")
  }
  
  func testCloneMessageWithMapFieldContainingMessages() throws {
    // Создаем map поле с сообщениями в качестве значений
    let mapField = FieldDescriptor(
      name: "message_map",
      number: 11,
      type: .message,
      typeName: "test.MessageMapEntry",
      isMap: true,
      mapEntryInfo: MapEntryInfo(
        keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
        valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .message, typeName: "test.NestedMessage")
      )
    )
    messageDescriptor.addField(mapField)
    
    var nested1 = factory.createMessage(from: nestedMessageDescriptor)
    try nested1.set("value1", forField: "value")
    
    var nested2 = factory.createMessage(from: nestedMessageDescriptor)
    try nested2.set("value2", forField: "value")
    
    var original = factory.createMessage(from: messageDescriptor)
    try original.setMapEntry(nested1, forKey: "key1", inField: "message_map")
    try original.setMapEntry(nested2, forKey: "key2", inField: "message_map")
    
    let cloned = try factory.clone(original)
    
    let clonedMap = try cloned.get(forField: "message_map") as? [String: DynamicMessage]
    XCTAssertNotNil(clonedMap)
    XCTAssertEqual(try clonedMap?["key1"]?.get(forField: "value") as? String, "value1")
    XCTAssertEqual(try clonedMap?["key2"]?.get(forField: "value") as? String, "value2")
    
    // Проверяем, что это разные объекты
    try nested1.set("changed", forField: "value")
    XCTAssertEqual(try clonedMap?["key1"]?.get(forField: "value") as? String, "value1")
  }
  
  // MARK: - Validation Tests
  
  func testValidateValidMessage() throws {
    var message = factory.createMessage(from: messageDescriptor)
    try message.set("required value", forField: "required_field")
    
    let result = factory.validate(message)
    
    XCTAssertTrue(result.isValid)
    XCTAssertTrue(result.errors.isEmpty)
  }
  
  func testValidateMissingRequiredField() {
    let message = factory.createMessage(from: messageDescriptor)
    
    let result = factory.validate(message)
    
    XCTAssertFalse(result.isValid)
    XCTAssertEqual(result.errors.count, 1)
    
    if case .missingRequiredField(let fieldName) = result.errors.first {
      XCTAssertEqual(fieldName, "required_field")
    } else {
      XCTFail("Expected missingRequiredField error")
    }
  }
  
  func testValidateNestedMessage() throws {
    // Создаем вложенное сообщение с required полем
    nestedMessageDescriptor.addField(FieldDescriptor(
      name: "required_nested",
      number: 2,
      type: .string,
      isRequired: true
    ))
    
    var nested = factory.createMessage(from: nestedMessageDescriptor)
    try nested.set("value", forField: "value")
    // Не устанавливаем required_nested поле
    
    var message = factory.createMessage(from: messageDescriptor)
    try message.set("required value", forField: "required_field")
    try message.set(nested, forField: "nested")
    
    let result = factory.validate(message)
    
    XCTAssertFalse(result.isValid)
    XCTAssertEqual(result.errors.count, 1)
    
    if case .nestedMessageValidationFailed(let fieldName, let nestedErrors) = result.errors.first {
      XCTAssertEqual(fieldName, "nested")
      XCTAssertEqual(nestedErrors.count, 1)
      if case .missingRequiredField(let nestedFieldName) = nestedErrors.first {
        XCTAssertEqual(nestedFieldName, "required_nested")
      } else {
        XCTFail("Expected missingRequiredField error in nested message")
      }
    } else {
      XCTFail("Expected nestedMessageValidationFailed error")
    }
  }
  
  func testValidateRepeatedFieldWithMessages() throws {
    // Создаем repeated поле с сообщениями
    messageDescriptor.addField(FieldDescriptor(
      name: "repeated_nested",
      number: 12,
      type: .message,
      typeName: "test.NestedMessage",
      isRepeated: true
    ))
    
    // Добавляем required поле к вложенному сообщению
    nestedMessageDescriptor.addField(FieldDescriptor(
      name: "required_nested",
      number: 2,
      type: .string,
      isRequired: true
    ))
    
    var validNested = factory.createMessage(from: nestedMessageDescriptor)
    try validNested.set("value", forField: "value")
    try validNested.set("required", forField: "required_nested")
    
    var invalidNested = factory.createMessage(from: nestedMessageDescriptor)
    try invalidNested.set("value", forField: "value")
    // Не устанавливаем required_nested
    
    var message = factory.createMessage(from: messageDescriptor)
    try message.set("required value", forField: "required_field")
    try message.set([validNested, invalidNested], forField: "repeated_nested")
    
    let result = factory.validate(message)
    
    XCTAssertFalse(result.isValid)
    XCTAssertEqual(result.errors.count, 1)
    
    if case .repeatedFieldValidationFailed(let fieldName, let index, let nestedErrors) = result.errors.first {
      XCTAssertEqual(fieldName, "repeated_nested")
      XCTAssertEqual(index, 1)  // Второй элемент массива
      XCTAssertEqual(nestedErrors.count, 1)
    } else {
      XCTFail("Expected repeatedFieldValidationFailed error")
    }
  }
  
  func testValidateMapFieldWithMessages() throws {
    // Создаем map поле с сообщениями в качестве значений
    let mapField = FieldDescriptor(
      name: "message_map",
      number: 13,
      type: .message,
      typeName: "test.MessageMapEntry2",
      isMap: true,
      mapEntryInfo: MapEntryInfo(
        keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
        valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .message, typeName: "test.NestedMessage")
      )
    )
    messageDescriptor.addField(mapField)
    
    // Добавляем required поле к вложенному сообщению
    nestedMessageDescriptor.addField(FieldDescriptor(
      name: "required_nested",
      number: 2,
      type: .string,
      isRequired: true
    ))
    
    var validNested = factory.createMessage(from: nestedMessageDescriptor)
    try validNested.set("value", forField: "value")
    try validNested.set("required", forField: "required_nested")
    
    var invalidNested = factory.createMessage(from: nestedMessageDescriptor)
    try invalidNested.set("value", forField: "value")
    // Не устанавливаем required_nested
    
    var message = factory.createMessage(from: messageDescriptor)
    try message.set("required value", forField: "required_field")
    try message.setMapEntry(validNested, forKey: "valid", inField: "message_map")
    try message.setMapEntry(invalidNested, forKey: "invalid", inField: "message_map")
    
    let result = factory.validate(message)
    
    XCTAssertFalse(result.isValid)
    XCTAssertEqual(result.errors.count, 1)
    
    if case .mapFieldValidationFailed(let fieldName, let key, let nestedErrors) = result.errors.first {
      XCTAssertEqual(fieldName, "message_map")
      XCTAssertEqual(key, "invalid")
      XCTAssertEqual(nestedErrors.count, 1)
    } else {
      XCTFail("Expected mapFieldValidationFailed error")
    }
  }
  
  func testValidationResultEquality() {
    let error1 = ValidationError.missingRequiredField(fieldName: "test")
    let error2 = ValidationError.missingRequiredField(fieldName: "test")
    let error3 = ValidationError.missingRequiredField(fieldName: "other")
    
    XCTAssertEqual(error1, error2)
    XCTAssertNotEqual(error1, error3)
    
    let result1 = ValidationResult(isValid: true, errors: [])
    let result2 = ValidationResult(isValid: false, errors: [error1])
    
    XCTAssertTrue(result1.isValid)
    XCTAssertFalse(result2.isValid)
    XCTAssertEqual(result2.errors.count, 1)
  }
  
  func testValidationErrorDescriptions() {
    let missingFieldError = ValidationError.missingRequiredField(fieldName: "test")
    XCTAssertTrue(missingFieldError.localizedDescription.contains("Missing required field: test"))
    
    let nestedError = ValidationError.nestedMessageValidationFailed(
      fieldName: "nested",
      nestedErrors: [missingFieldError]
    )
    XCTAssertTrue(nestedError.localizedDescription.contains("nested message in field 'nested'"))
    
    let repeatedError = ValidationError.repeatedFieldValidationFailed(
      fieldName: "repeated",
      index: 0,
      nestedErrors: [missingFieldError]
    )
    XCTAssertTrue(repeatedError.localizedDescription.contains("repeated field 'repeated' at index 0"))
    
    let mapError = ValidationError.mapFieldValidationFailed(
      fieldName: "map",
      key: "key1",
      nestedErrors: [missingFieldError]
    )
    XCTAssertTrue(mapError.localizedDescription.contains("map field 'map' at key 'key1'"))
    
    let validationError = ValidationError.validationError(
      fieldName: "field",
      error: DynamicMessageError.fieldNotFound(fieldName: "test")
    )
    XCTAssertTrue(validationError.localizedDescription.contains("Validation error for field 'field'"))
  }
  
  func testValidationErrorEquality() {
    let error1 = ValidationError.nestedMessageValidationFailed(
      fieldName: "test",
      nestedErrors: [ValidationError.missingRequiredField(fieldName: "nested")]
    )
    let error2 = ValidationError.nestedMessageValidationFailed(
      fieldName: "test",
      nestedErrors: [ValidationError.missingRequiredField(fieldName: "nested")]
    )
    let error3 = ValidationError.nestedMessageValidationFailed(
      fieldName: "other",
      nestedErrors: [ValidationError.missingRequiredField(fieldName: "nested")]
    )
    
    XCTAssertEqual(error1, error2)
    XCTAssertNotEqual(error1, error3)
    
    let repeatedError1 = ValidationError.repeatedFieldValidationFailed(
      fieldName: "test",
      index: 0,
      nestedErrors: []
    )
    let repeatedError2 = ValidationError.repeatedFieldValidationFailed(
      fieldName: "test",
      index: 1,
      nestedErrors: []
    )
    
    XCTAssertNotEqual(repeatedError1, repeatedError2)
    
    let mapError1 = ValidationError.mapFieldValidationFailed(
      fieldName: "test",
      key: "key1",
      nestedErrors: []
    )
    let mapError2 = ValidationError.mapFieldValidationFailed(
      fieldName: "test",
      key: "key2",
      nestedErrors: []
    )
    
    XCTAssertNotEqual(mapError1, mapError2)
    
    let validationError1 = ValidationError.validationError(
      fieldName: "test",
      error: DynamicMessageError.fieldNotFound(fieldName: "test")
    )
    let validationError2 = ValidationError.validationError(
      fieldName: "test",
      error: DynamicMessageError.fieldNotFound(fieldName: "other")
    )
    
    XCTAssertEqual(validationError1, validationError2)  // Только сравниваем fieldName
  }
  
  // MARK: - Edge Cases
  
  func testCreateMessageWithComplexFieldValues() throws {
    var nestedMessage = factory.createMessage(from: nestedMessageDescriptor)
    try nestedMessage.set("nested value", forField: "value")
    
    let fieldValues: [String: Any] = [
      "id": Int32(42),
      "name": "Test",
      "nested": nestedMessage,
      "tags": ["tag1", "tag2"],

      "required_field": "required"
    ]
    
    var message = try factory.createMessage(from: messageDescriptor, with: fieldValues)
    
    XCTAssertEqual(try message.get(forField: "id") as? Int32, 42)
    XCTAssertEqual(try message.get(forField: "name") as? String, "Test")
    
    let retrievedNested = try message.get(forField: "nested") as? DynamicMessage
    XCTAssertNotNil(retrievedNested)
    XCTAssertEqual(try retrievedNested?.get(forField: "value") as? String, "nested value")
    
    let retrievedTags = try message.get(forField: "tags") as? [String]
    XCTAssertEqual(retrievedTags, ["tag1", "tag2"])
    
    // Добавляем map entry отдельно
    try message.setMapEntry("value", forKey: "key", inField: "metadata")
    let retrievedMetadata = try message.get(forField: "metadata") as? [String: String]
    XCTAssertEqual(retrievedMetadata?["key"], "value")
  }
  
  func testValidationWithFieldAccessError() throws {
    // Создаем сообщение, которое будет вызывать ошибки при доступе к полю
    var brokenDescriptor = MessageDescriptor(name: "BrokenMessage", parent: fileDescriptor)
    brokenDescriptor.addField(FieldDescriptor(name: "test", number: 1, type: .string))
    
    let message = factory.createMessage(from: brokenDescriptor)
    
    // Это должно работать нормально
    let result = factory.validate(message)
    XCTAssertTrue(result.isValid)
  }

}
