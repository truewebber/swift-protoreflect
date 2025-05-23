//
// DynamicMessageExtendedTests.swift
// SwiftProtoReflectTests
//
// Создан: 2025-05-23
// Дополнительные тесты для повышения покрытия кода DynamicMessage
//

import XCTest
@testable import SwiftProtoReflect

final class DynamicMessageExtendedTests: XCTestCase {
  // MARK: - Properties
  
  private var fileDescriptor: FileDescriptor!
  private var personMessage: MessageDescriptor!
  private var addressMessage: MessageDescriptor!
  private var enumDescriptor: EnumDescriptor!
  
  // MARK: - Setup
  
  override func setUp() {
    super.setUp()
    
    // Создаем тестовый файловый дескриптор
    fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    
    // Создаем дескриптор перечисления PhoneType
    enumDescriptor = EnumDescriptor(name: "PhoneType", parent: fileDescriptor)
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "MOBILE", number: 0))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "HOME", number: 1))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "WORK", number: 2))
    
    fileDescriptor.addEnum(enumDescriptor)
    
    // Создаем дескриптор сообщения Address
    addressMessage = MessageDescriptor(name: "Address", parent: fileDescriptor)
    addressMessage.addField(FieldDescriptor(
      name: "street",
      number: 1,
      type: .string
    ))
    addressMessage.addField(FieldDescriptor(
      name: "city",
      number: 2,
      type: .string
    ))
    
    fileDescriptor.addMessage(addressMessage)
    
    // Создаем дескриптор сообщения Person
    personMessage = MessageDescriptor(name: "Person", parent: fileDescriptor)
    personMessage.addField(FieldDescriptor(
      name: "name",
      number: 1,
      type: .string
    ))
    personMessage.addField(FieldDescriptor(
      name: "id",
      number: 2,
      type: .int32
    ))
    personMessage.addField(FieldDescriptor(
      name: "address",
      number: 3,
      type: .message,
      typeName: "test.Address"
    ))
    
    fileDescriptor.addMessage(personMessage)
  }
  
  override func tearDown() {
    fileDescriptor = nil
    personMessage = nil
    addressMessage = nil
    enumDescriptor = nil
    super.tearDown()
  }
  
  // MARK: - Field Not Found Error Tests
  
  func testFieldNotFoundErrors() {
    var message = DynamicMessage(descriptor: personMessage)
    
    // Тестируем ошибку fieldNotFound для set методов
    XCTAssertThrowsError(try message.set("value", forField: "non_existent_field")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Ожидалась ошибка DynamicMessageError")
        return
      }
      
      if case .fieldNotFound(let fieldName) = dynamicError {
        XCTAssertEqual(fieldName, "non_existent_field")
      } else {
        XCTFail("Ожидалась ошибка fieldNotFound")
      }
    }
    
    // Тестируем ошибку fieldNotFoundByNumber для set методов
    XCTAssertThrowsError(try message.set("value", forField: 999)) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Ожидалась ошибка DynamicMessageError")
        return
      }
      
      if case .fieldNotFoundByNumber(let fieldNumber) = dynamicError {
        XCTAssertEqual(fieldNumber, 999)
      } else {
        XCTFail("Ожидалась ошибка fieldNotFoundByNumber")
      }
    }
    
    // Тестируем ошибку fieldNotFound для get методов
    XCTAssertThrowsError(try message.get(forField: "non_existent_field")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Ожидалась ошибка DynamicMessageError")
        return
      }
      
      if case .fieldNotFound(let fieldName) = dynamicError {
        XCTAssertEqual(fieldName, "non_existent_field")
      } else {
        XCTFail("Ожидалась ошибка fieldNotFound")
      }
    }
    
    // Тестируем ошибку fieldNotFoundByNumber для get методов
    XCTAssertThrowsError(try message.get(forField: 999)) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Ожидалась ошибка DynamicMessageError")
        return
      }
      
      if case .fieldNotFoundByNumber(let fieldNumber) = dynamicError {
        XCTAssertEqual(fieldNumber, 999)
      } else {
        XCTFail("Ожидалась ошибка fieldNotFoundByNumber")
      }
    }
    
    // Тестируем ошибку fieldNotFound для hasValue методов
    XCTAssertThrowsError(try message.hasValue(forField: "non_existent_field")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Ожидалась ошибка DynamicMessageError")
        return
      }
      
      if case .fieldNotFound(let fieldName) = dynamicError {
        XCTAssertEqual(fieldName, "non_existent_field")
      } else {
        XCTFail("Ожидалась ошибка fieldNotFound")
      }
    }
    
    // Тестируем ошибку fieldNotFoundByNumber для hasValue методов
    XCTAssertThrowsError(try message.hasValue(forField: 999)) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Ожидалась ошибка DynamicMessageError")
        return
      }
      
      if case .fieldNotFoundByNumber(let fieldNumber) = dynamicError {
        XCTAssertEqual(fieldNumber, 999)
      } else {
        XCTFail("Ожидалась ошибка fieldNotFoundByNumber")
      }
    }
    
    // Тестируем ошибку fieldNotFound для clearField методов
    XCTAssertThrowsError(try message.clearField("non_existent_field")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Ожидалась ошибка DynamicMessageError")
        return
      }
      
      if case .fieldNotFound(let fieldName) = dynamicError {
        XCTAssertEqual(fieldName, "non_existent_field")
      } else {
        XCTFail("Ожидалась ошибка fieldNotFound")
      }
    }
    
    // Тестируем ошибку fieldNotFoundByNumber для clearField методов
    XCTAssertThrowsError(try message.clearField(999)) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Ожидалась ошибка DynamicMessageError")
        return
      }
      
      if case .fieldNotFoundByNumber(let fieldNumber) = dynamicError {
        XCTAssertEqual(fieldNumber, 999)
      } else {
        XCTFail("Ожидалась ошибка fieldNotFoundByNumber")
      }
    }
  }
  
  // MARK: - Message Type Validation Tests
  
  func testMessageTypeMismatchErrors() {
    var message = DynamicMessage(descriptor: personMessage)
    
    // Создаем сообщение с неправильным типом
    let wrongMessage = DynamicMessage(descriptor: personMessage) // Person вместо Address
    
    // Тестируем ошибку messageMismatch при установке вложенного сообщения
    XCTAssertThrowsError(try message.set(wrongMessage, forField: "address")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Ожидалась ошибка DynamicMessageError")
        return
      }
      
      if case .messageMismatch(let fieldName, let expectedType, let actualType) = dynamicError {
        XCTAssertEqual(fieldName, "address")
        XCTAssertEqual(expectedType, "test.Address")
        XCTAssertEqual(actualType, "test.Person")
      } else {
        XCTFail("Ожидалась ошибка messageMismatch")
      }
    }
    
    // Тестируем ошибку typeMismatch при попытке установить не DynamicMessage для message поля
    XCTAssertThrowsError(try message.set("not a message", forField: "address")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Ожидалась ошибка DynamicMessageError")
        return
      }
      
      if case .typeMismatch(let fieldName, let expectedType, _) = dynamicError {
        XCTAssertEqual(fieldName, "address")
        XCTAssertEqual(expectedType, "DynamicMessage")
      } else {
        XCTFail("Ожидалась ошибка typeMismatch")
      }
    }
  }
  
  // MARK: - Enum Type Validation Tests
  
  func testEnumTypeValidation() {
    // Создаем сообщение с enum полем
    var messageDesc = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    messageDesc.addField(FieldDescriptor(
      name: "enum_field",
      number: 1,
      type: .enum,
      typeName: "test.PhoneType"
    ))
    
    fileDescriptor.addMessage(messageDesc)
    
    var message = DynamicMessage(descriptor: messageDesc)
    
    // Тестируем ошибку typeMismatch для неправильного типа enum
    XCTAssertThrowsError(try message.set(42.5, forField: "enum_field")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Ожидалась ошибка DynamicMessageError")
        return
      }
      
      if case .typeMismatch(let fieldName, let expectedType, _) = dynamicError {
        XCTAssertEqual(fieldName, "enum_field")
        XCTAssertEqual(expectedType, "Enum (Int32 or String)")
      } else {
        XCTFail("Ожидалась ошибка typeMismatch")
      }
    }
  }
  
  // MARK: - Group Type Tests
  
  func testGroupTypeValidation() {
    // Создаем сообщение с group полем (устаревший тип)
    var messageDesc = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    messageDesc.addField(FieldDescriptor(
      name: "group_field",
      number: 1,
      type: .group,
      typeName: "test.SomeGroup"
    ))
    
    fileDescriptor.addMessage(messageDesc)
    
    var message = DynamicMessage(descriptor: messageDesc)
    
    // Тестируем валидное group поле
    let groupMessage = DynamicMessage(descriptor: addressMessage)
    do {
      try message.set(groupMessage, forField: "group_field")
      XCTAssertTrue(try message.hasValue(forField: "group_field"))
    } catch {
      XCTFail("Не должно быть ошибки при установке валидного group сообщения: \(error)")
    }
    
    // Тестируем ошибку typeMismatch для неправильного типа group
    XCTAssertThrowsError(try message.set("not a group", forField: "group_field")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Ожидалась ошибка DynamicMessageError")
        return
      }
      
      if case .typeMismatch(let fieldName, let expectedType, _) = dynamicError {
        XCTAssertEqual(fieldName, "group_field")
        XCTAssertEqual(expectedType, "DynamicMessage (group)")
      } else {
        XCTFail("Ожидалась ошибка typeMismatch")
      }
    }
  }
  
  // MARK: - Repeated Field Error Tests
  
  func testRepeatedFieldErrors() {
    var message = DynamicMessage(descriptor: personMessage)
    
    // Тестируем ошибку fieldNotFoundByNumber для addRepeatedValue
    XCTAssertThrowsError(try message.addRepeatedValue("value", forField: 999)) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Ожидалась ошибка DynamicMessageError")
        return
      }
      
      if case .fieldNotFoundByNumber(let fieldNumber) = dynamicError {
        XCTAssertEqual(fieldNumber, 999)
      } else {
        XCTFail("Ожидалась ошибка fieldNotFoundByNumber")
      }
    }
    
    // Тестируем ошибку notRepeatedField для обычного поля
    XCTAssertThrowsError(try message.addRepeatedValue("value", forField: "name")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Ожидалась ошибка DynamicMessageError")
        return
      }
      
      if case .notRepeatedField(let fieldName) = dynamicError {
        XCTAssertEqual(fieldName, "name")
      } else {
        XCTFail("Ожидалась ошибка notRepeatedField")
      }
    }
  }
  
  // MARK: - Map Field Error Tests
  
  func testMapFieldErrors() {
    var message = DynamicMessage(descriptor: personMessage)
    
    // Тестируем ошибку fieldNotFoundByNumber для setMapEntry
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: "key", inField: 999)) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Ожидалась ошибка DynamicMessageError")
        return
      }
      
      if case .fieldNotFoundByNumber(let fieldNumber) = dynamicError {
        XCTAssertEqual(fieldNumber, 999)
      } else {
        XCTFail("Ожидалась ошибка fieldNotFoundByNumber")
      }
    }
    
    // Тестируем ошибку notMapField для обычного поля
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: "key", inField: "name")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Ожидалась ошибка DynamicMessageError")
        return
      }
      
      if case .notMapField(let fieldName) = dynamicError {
        XCTAssertEqual(fieldName, "name")
      } else {
        XCTFail("Ожидалась ошибка notMapField")
      }
    }
  }
  
  // MARK: - Clear Nested Message Field Tests
  
  func testClearNestedMessageField() {
    var message = DynamicMessage(descriptor: personMessage)
    
    do {
      // Устанавливаем вложенное сообщение
      let address = DynamicMessage(descriptor: addressMessage)
      try message.set(address, forField: "address")
      XCTAssertTrue(try message.hasValue(forField: "address"))
      
      // Очищаем вложенное сообщение
      try message.clearField("address")
      XCTAssertFalse(try message.hasValue(forField: "address"))
      
      // Очищаем вложенное сообщение по номеру поля
      try message.set(address, forField: 3)
      XCTAssertTrue(try message.hasValue(forField: 3))
      
      try message.clearField(3)
      XCTAssertFalse(try message.hasValue(forField: 3))
    } catch {
      XCTFail("Не должно быть исключений при очистке вложенного сообщения: \(error)")
    }
  }
  
  // MARK: - Map Key Type Validation Tests
  
  func testMapKeyTypeValidation() {
    // Создаем различные map поля для тестирования всех типов ключей
    var messageDesc = MessageDescriptor(name: "MapKeyTest", parent: fileDescriptor)
    
    // Map с int32 ключом
    let int32KeyInfo = KeyFieldInfo(name: "key", number: 1, type: .int32)
    let stringValueInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    messageDesc.addField(FieldDescriptor(
      name: "int32_map",
      number: 1,
      type: .message,
      typeName: "map<int32, string>",
      isRepeated: true,
      isMap: true,
      mapEntryInfo: MapEntryInfo(keyFieldInfo: int32KeyInfo, valueFieldInfo: stringValueInfo)
    ))
    
    // Map с int64 ключом
    let int64KeyInfo = KeyFieldInfo(name: "key", number: 1, type: .int64)
    messageDesc.addField(FieldDescriptor(
      name: "int64_map",
      number: 2,
      type: .message,
      typeName: "map<int64, string>",
      isRepeated: true,
      isMap: true,
      mapEntryInfo: MapEntryInfo(keyFieldInfo: int64KeyInfo, valueFieldInfo: stringValueInfo)
    ))
    
    // Map с uint32 ключом
    let uint32KeyInfo = KeyFieldInfo(name: "key", number: 1, type: .uint32)
    messageDesc.addField(FieldDescriptor(
      name: "uint32_map",
      number: 3,
      type: .message,
      typeName: "map<uint32, string>",
      isRepeated: true,
      isMap: true,
      mapEntryInfo: MapEntryInfo(keyFieldInfo: uint32KeyInfo, valueFieldInfo: stringValueInfo)
    ))
    
    // Map с uint64 ключом
    let uint64KeyInfo = KeyFieldInfo(name: "key", number: 1, type: .uint64)
    messageDesc.addField(FieldDescriptor(
      name: "uint64_map",
      number: 4,
      type: .message,
      typeName: "map<uint64, string>",
      isRepeated: true,
      isMap: true,
      mapEntryInfo: MapEntryInfo(keyFieldInfo: uint64KeyInfo, valueFieldInfo: stringValueInfo)
    ))
    
    // Map с bool ключом
    let boolKeyInfo = KeyFieldInfo(name: "key", number: 1, type: .bool)
    messageDesc.addField(FieldDescriptor(
      name: "bool_map",
      number: 5,
      type: .message,
      typeName: "map<bool, string>",
      isRepeated: true,
      isMap: true,
      mapEntryInfo: MapEntryInfo(keyFieldInfo: boolKeyInfo, valueFieldInfo: stringValueInfo)
    ))
    
    fileDescriptor.addMessage(messageDesc)
    
    var message = DynamicMessage(descriptor: messageDesc)
    
    // Тестируем ошибки типов для int32 ключей
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: "string_key", inField: "int32_map"))
    
    // Тестируем ошибки типов для int64 ключей  
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: "string_key", inField: "int64_map"))
    
    // Тестируем ошибки типов для uint32 ключей
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: "string_key", inField: "uint32_map"))
    
    // Тестируем ошибки типов для uint64 ключей
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: "string_key", inField: "uint64_map"))
    
    // Тестируем ошибки типов для bool ключей
    XCTAssertThrowsError(try message.setMapEntry("value", forKey: "string_key", inField: "bool_map"))
  }
  
  // MARK: - Invalid Map Key Type Test
  
  func testInvalidMapKeyType() {
    // Тестируем ошибку DynamicMessageError.invalidMapKeyType напрямую
    let error = DynamicMessageError.invalidMapKeyType(type: .double)
    XCTAssertEqual(error.errorDescription, "Недопустимый тип ключа double для map поля")
    
    // Тестируем с другими недопустимыми типами
    let floatError = DynamicMessageError.invalidMapKeyType(type: .float)
    XCTAssertEqual(floatError.errorDescription, "Недопустимый тип ключа float для map поля")
    
    let bytesError = DynamicMessageError.invalidMapKeyType(type: .bytes)
    XCTAssertEqual(bytesError.errorDescription, "Недопустимый тип ключа bytes для map поля")
  }
  
  // MARK: - NSNumber Conversion Tests
  
  func testNSNumberConversions() {
    // Создаем сообщение с полями для NSNumber конверсий
    var messageDesc = MessageDescriptor(name: "NSNumberTest", parent: fileDescriptor)
    messageDesc.addField(FieldDescriptor(name: "float_field", number: 1, type: .float))
    messageDesc.addField(FieldDescriptor(name: "double_field", number: 2, type: .double))
    
    fileDescriptor.addMessage(messageDesc)
    
    var message = DynamicMessage(descriptor: messageDesc)
    
    do {
      // Тестируем конверсию NSNumber для float поля
      let floatNumber = NSNumber(value: 3.14 as Double) // не Float
      try message.set(floatNumber, forField: "float_field")
      
      let retrievedFloat = try message.get(forField: "float_field") as? Float
      XCTAssertEqual(retrievedFloat!, 3.14, accuracy: 0.001)
      
      // Тестируем конверсию NSNumber для double поля
      let doubleNumber = NSNumber(value: 2.71 as Float) // не Double
      try message.set(doubleNumber, forField: "double_field")
      
      let retrievedDouble = try message.get(forField: "double_field") as? Double
      XCTAssertEqual(retrievedDouble!, 2.71, accuracy: 0.001)
    } catch {
      XCTFail("Не должно быть исключений при конверсии NSNumber: \(error)")
    }
  }
  
  // MARK: - Map Key Conversion Tests
  
  func testMapKeyConversions() {
    // Создаем map поля для тестирования конверсий ключей
    var messageDesc = MessageDescriptor(name: "MapKeyConversion", parent: fileDescriptor)
    
    // Map с int32 ключом
    let int32KeyInfo = KeyFieldInfo(name: "key", number: 1, type: .int32)
    let stringValueInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    messageDesc.addField(FieldDescriptor(
      name: "int32_map",
      number: 1,
      type: .message,
      typeName: "map<int32, string>",
      isRepeated: true,
      isMap: true,
      mapEntryInfo: MapEntryInfo(keyFieldInfo: int32KeyInfo, valueFieldInfo: stringValueInfo)
    ))
    
    // Map с int64 ключом
    let int64KeyInfo = KeyFieldInfo(name: "key", number: 1, type: .int64)
    messageDesc.addField(FieldDescriptor(
      name: "int64_map",
      number: 2,
      type: .message,
      typeName: "map<int64, string>",
      isRepeated: true,
      isMap: true,
      mapEntryInfo: MapEntryInfo(keyFieldInfo: int64KeyInfo, valueFieldInfo: stringValueInfo)
    ))
    
    // Map с uint32 ключом
    let uint32KeyInfo = KeyFieldInfo(name: "key", number: 1, type: .uint32)
    messageDesc.addField(FieldDescriptor(
      name: "uint32_map",
      number: 3,
      type: .message,
      typeName: "map<uint32, string>",
      isRepeated: true,
      isMap: true,
      mapEntryInfo: MapEntryInfo(keyFieldInfo: uint32KeyInfo, valueFieldInfo: stringValueInfo)
    ))
    
    // Map с uint64 ключом
    let uint64KeyInfo = KeyFieldInfo(name: "key", number: 1, type: .uint64)
    messageDesc.addField(FieldDescriptor(
      name: "uint64_map",
      number: 4,
      type: .message,
      typeName: "map<uint64, string>",
      isRepeated: true,
      isMap: true,
      mapEntryInfo: MapEntryInfo(keyFieldInfo: uint64KeyInfo, valueFieldInfo: stringValueInfo)
    ))
    
    fileDescriptor.addMessage(messageDesc)
    
    var message = DynamicMessage(descriptor: messageDesc)
    
    do {
      // Тестируем конверсию Int -> Int32 для ключей
      try message.setMapEntry("value1", forKey: Int(42), inField: "int32_map")
      let int32Map = try message.get(forField: "int32_map") as? [AnyHashable: String]
      XCTAssertEqual(int32Map?[Int32(42)], "value1")
      
      // Тестируем конверсию Int -> Int64 для ключей
      try message.setMapEntry("value2", forKey: Int(84), inField: "int64_map")
      let int64Map = try message.get(forField: "int64_map") as? [AnyHashable: String]
      XCTAssertEqual(int64Map?[Int64(84)], "value2")
      
      // Тестируем конверсию UInt -> UInt32 для ключей
      try message.setMapEntry("value3", forKey: UInt(123), inField: "uint32_map")
      let uint32Map = try message.get(forField: "uint32_map") as? [AnyHashable: String]
      XCTAssertEqual(uint32Map?[UInt32(123)], "value3")
      
      // Тестируем конверсию UInt -> UInt64 для ключей
      try message.setMapEntry("value4", forKey: UInt(456), inField: "uint64_map")
      let uint64Map = try message.get(forField: "uint64_map") as? [AnyHashable: String]
      XCTAssertEqual(uint64Map?[UInt64(456)], "value4")
    } catch {
      XCTFail("Не должно быть исключений при конверсии ключей map: \(error)")
    }
  }
  
  // MARK: - Map Field Validation Error Tests
  
  func testMapFieldValidationErrors() {
    // Создаем обычное (не map) поле для тестирования ошибки notMapField
    var normalMessage = MessageDescriptor(name: "NormalMessage", parent: fileDescriptor)
    normalMessage.addField(FieldDescriptor(
      name: "normal_field",
      number: 1,
      type: .string
    ))
    
    fileDescriptor.addMessage(normalMessage)
    
    var normalDynamicMessage = DynamicMessage(descriptor: normalMessage)
    
    // Тестируем ошибку notMapField при попытке использовать обычное поле как map
    XCTAssertThrowsError(try normalDynamicMessage.setMapEntry("value", forKey: "key", inField: "normal_field")) { error in
      guard let dynamicError = error as? DynamicMessageError else {
        XCTFail("Ожидалась ошибка DynamicMessageError")
        return
      }
      
      if case .notMapField(let fieldName) = dynamicError {
        XCTAssertEqual(fieldName, "normal_field")
      } else {
        XCTFail("Ожидалась ошибка notMapField")
      }
    }
  }
}
