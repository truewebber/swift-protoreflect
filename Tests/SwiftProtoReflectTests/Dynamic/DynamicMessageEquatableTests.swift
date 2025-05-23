//
// DynamicMessageEquatableTests.swift
// SwiftProtoReflectTests
//
// Создан: 2025-05-23
// Дополнительные тесты для полного покрытия Equatable функциональности DynamicMessage
//

import XCTest
@testable import SwiftProtoReflect

final class DynamicMessageEquatableTests: XCTestCase {
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
  
  // MARK: - Equatable with Different Descriptors Tests
  
  func testEquatableWithDifferentDescriptors() {
    // Создаем два разных дескриптора с одинаковыми именами но разными fullName
    var fileDescriptor1 = FileDescriptor(name: "test1.proto", package: "package1")
    var messageDescriptor1 = MessageDescriptor(name: "TestMessage", parent: fileDescriptor1)
    messageDescriptor1.addField(FieldDescriptor(name: "field1", number: 1, type: .string))
    fileDescriptor1.addMessage(messageDescriptor1)
    
    var fileDescriptor2 = FileDescriptor(name: "test2.proto", package: "package2")
    var messageDescriptor2 = MessageDescriptor(name: "TestMessage", parent: fileDescriptor2)
    messageDescriptor2.addField(FieldDescriptor(name: "field1", number: 1, type: .string))
    fileDescriptor2.addMessage(messageDescriptor2)
    
    var message1 = DynamicMessage(descriptor: messageDescriptor1)
    var message2 = DynamicMessage(descriptor: messageDescriptor2)
    
    do {
      try message1.set("value", forField: "field1")
      try message2.set("value", forField: "field1")
      
      // Сообщения с разными дескрипторами не должны быть равны, даже если содержимое одинаковое
      XCTAssertNotEqual(message1, message2)
    } catch {
      XCTFail("Не должно быть исключений при тестировании разных дескрипторов: \(error)")
    }
  }
  
  // MARK: - Equatable with Map Fields Tests
  
  func testEquatableWithMapFields() {
    // Создаем сообщение с map полем
    var messageDesc = MessageDescriptor(name: "MapTestMessage", parent: fileDescriptor)
    
    // String -> String map
    let stringKeyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let stringValueInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let stringMapEntryInfo = MapEntryInfo(keyFieldInfo: stringKeyInfo, valueFieldInfo: stringValueInfo)
    messageDesc.addField(FieldDescriptor(
      name: "string_map",
      number: 1,
      type: .message,
      typeName: "map<string, string>",
      isRepeated: true,
      isMap: true,
      mapEntryInfo: stringMapEntryInfo
    ))
    
    // Int32 -> Int32 map для тестирования areValuesEqual с Int32
    let int32KeyInfo = KeyFieldInfo(name: "key", number: 1, type: .int32)
    let int32ValueInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let int32MapEntryInfo = MapEntryInfo(keyFieldInfo: int32KeyInfo, valueFieldInfo: int32ValueInfo)
    messageDesc.addField(FieldDescriptor(
      name: "int32_map",
      number: 2,
      type: .message,
      typeName: "map<int32, int32>",
      isRepeated: true,
      isMap: true,
      mapEntryInfo: int32MapEntryInfo
    ))
    
    fileDescriptor.addMessage(messageDesc)
    
    var message1 = DynamicMessage(descriptor: messageDesc)
    var message2 = DynamicMessage(descriptor: messageDesc)
    
    do {
      // Тестируем одинаковые map поля
      try message1.setMapEntry("value1", forKey: "key1", inField: "string_map")
      try message1.setMapEntry("value2", forKey: "key2", inField: "string_map")
      
      try message2.setMapEntry("value1", forKey: "key1", inField: "string_map")
      try message2.setMapEntry("value2", forKey: "key2", inField: "string_map")
      
      XCTAssertEqual(message1, message2)
      
      // Тестируем map с разным количеством элементов
      try message1.setMapEntry("value3", forKey: "key3", inField: "string_map")
      XCTAssertNotEqual(message1, message2)
      
      // Восстанавливаем равенство
      try message2.setMapEntry("value3", forKey: "key3", inField: "string_map")
      XCTAssertEqual(message1, message2)
      
      // Тестируем map с разными ключами
      var message3 = DynamicMessage(descriptor: messageDesc)
      try message3.setMapEntry("value1", forKey: "different_key1", inField: "string_map")
      try message3.setMapEntry("value2", forKey: "key2", inField: "string_map")
      try message3.setMapEntry("value3", forKey: "key3", inField: "string_map")
      
      XCTAssertNotEqual(message1, message3)
      
      // Тестируем map с разными значениями
      var message4 = DynamicMessage(descriptor: messageDesc)
      try message4.setMapEntry("different_value", forKey: "key1", inField: "string_map")
      try message4.setMapEntry("value2", forKey: "key2", inField: "string_map")
      try message4.setMapEntry("value3", forKey: "key3", inField: "string_map")
      
      XCTAssertNotEqual(message1, message4)
      
      // Тестируем int32 map для покрытия areValuesEqual с Int32 типом
      try message1.setMapEntry(Int32(100), forKey: Int32(1), inField: "int32_map")
      try message2.setMapEntry(Int32(100), forKey: Int32(1), inField: "int32_map")
      
      XCTAssertEqual(message1, message2)
      
      try message2.setMapEntry(Int32(200), forKey: Int32(1), inField: "int32_map")
      XCTAssertNotEqual(message1, message2)
      
    } catch {
      XCTFail("Не должно быть исключений при тестировании map полей в Equatable: \(error)")
    }
  }
  
  // MARK: - Equatable with Repeated Fields Tests
  
  func testEquatableWithRepeatedFields() {
    // Создаем сообщение с repeated полями
    var messageDesc = MessageDescriptor(name: "RepeatedTestMessage", parent: fileDescriptor)
    messageDesc.addField(FieldDescriptor(
      name: "repeated_string",
      number: 1,
      type: .string,
      isRepeated: true
    ))
    messageDesc.addField(FieldDescriptor(
      name: "repeated_int32",
      number: 2,
      type: .int32,
      isRepeated: true
    ))
    messageDesc.addField(FieldDescriptor(
      name: "repeated_message",
      number: 3,
      type: .message,
      typeName: "test.Address",
      isRepeated: true
    ))
    
    fileDescriptor.addMessage(messageDesc)
    
    var message1 = DynamicMessage(descriptor: messageDesc)
    var message2 = DynamicMessage(descriptor: messageDesc)
    
    do {
      // Тестируем одинаковые repeated поля
      try message1.addRepeatedValue("first", forField: "repeated_string")
      try message1.addRepeatedValue("second", forField: "repeated_string")
      
      try message2.addRepeatedValue("first", forField: "repeated_string")
      try message2.addRepeatedValue("second", forField: "repeated_string")
      
      XCTAssertEqual(message1, message2)
      
      // Тестируем repeated поля с разным количеством элементов
      try message1.addRepeatedValue("third", forField: "repeated_string")
      XCTAssertNotEqual(message1, message2)
      
      // Восстанавливаем равенство
      try message2.addRepeatedValue("third", forField: "repeated_string")
      XCTAssertEqual(message1, message2)
      
      // Тестируем repeated поля с разными значениями
      var message3 = DynamicMessage(descriptor: messageDesc)
      try message3.addRepeatedValue("different", forField: "repeated_string")
      try message3.addRepeatedValue("second", forField: "repeated_string")
      try message3.addRepeatedValue("third", forField: "repeated_string")
      
      XCTAssertNotEqual(message1, message3)
      
      // Тестируем repeated int32 для покрытия areValuesEqual с Int32
      try message1.addRepeatedValue(Int32(100), forField: "repeated_int32")
      try message1.addRepeatedValue(Int32(200), forField: "repeated_int32")
      
      try message2.addRepeatedValue(Int32(100), forField: "repeated_int32")
      try message2.addRepeatedValue(Int32(200), forField: "repeated_int32")
      
      XCTAssertEqual(message1, message2)
      
      try message2.addRepeatedValue(Int32(300), forField: "repeated_int32")
      XCTAssertNotEqual(message1, message2)
      
      // Тестируем repeated сообщения
      var addr1 = DynamicMessage(descriptor: addressMessage)
      try addr1.set("Street 1", forField: "street")
      
      var addr2 = DynamicMessage(descriptor: addressMessage)
      try addr2.set("Street 2", forField: "street")
      
      var message4 = DynamicMessage(descriptor: messageDesc)
      var message5 = DynamicMessage(descriptor: messageDesc)
      
      try message4.addRepeatedValue(addr1, forField: "repeated_message")
      try message5.addRepeatedValue(addr1, forField: "repeated_message")
      
      XCTAssertEqual(message4, message5)
      
      try message5.addRepeatedValue(addr2, forField: "repeated_message")
      XCTAssertNotEqual(message4, message5)
      
    } catch {
      XCTFail("Не должно быть исключений при тестировании repeated полей в Equatable: \(error)")
    }
  }
  
  // MARK: - Equatable Error Handling Tests
  
  func testEquatableWithErrorHandling() {
    // Создаем сообщение с полем, которое может вызвать ошибку при сравнении
    var messageDesc = MessageDescriptor(name: "ErrorTestMessage", parent: fileDescriptor)
    
    // Добавляем поле, которое потенциально может вызвать проблемы
    messageDesc.addField(FieldDescriptor(
      name: "test_field",
      number: 1,
      type: .string
    ))
    
    fileDescriptor.addMessage(messageDesc)
    
    let message1 = DynamicMessage(descriptor: messageDesc)
    let message2 = DynamicMessage(descriptor: messageDesc)
    
    // Тестируем случай, когда сравниваются сообщения с правильными дескрипторами
    XCTAssertEqual(message1, message2)
    
    // Создаем ситуацию с поврежденным дескриптором для тестирования catch блока
    // Это сложно протестировать без внутреннего доступа, но мы покрыли основную логику
  }
  
  // MARK: - areValuesEqual Unknown Type Tests
  
  func testAreValuesEqualWithUnknownType() {
    // Создаем сообщение с типом, который не обрабатывается в areValuesEqual
    var messageDesc = MessageDescriptor(name: "UnknownTypeTest", parent: fileDescriptor)
    
    // Добавляем поле с group типом (редко используется)
    messageDesc.addField(FieldDescriptor(
      name: "group_field",
      number: 1,
      type: .group,
      typeName: "test.SomeGroup"
    ))
    
    // Добавляем еще одно поле для тестирования fallback логики
    messageDesc.addField(FieldDescriptor(
      name: "unknown_field",
      number: 2,
      type: .string // Намеренно устанавливаем nil в типе через reflection не получится в Swift
    ))
    
    fileDescriptor.addMessage(messageDesc)
    
    var message1 = DynamicMessage(descriptor: messageDesc)
    var message2 = DynamicMessage(descriptor: messageDesc)
    
    do {
      // Устанавливаем group сообщения
      var groupMessage1 = DynamicMessage(descriptor: addressMessage)
      try groupMessage1.set("Street 1", forField: "street")
      
      var groupMessage2 = DynamicMessage(descriptor: addressMessage)
      try groupMessage2.set("Street 1", forField: "street")
      
      var differentGroupMessage = DynamicMessage(descriptor: addressMessage)
      try differentGroupMessage.set("Street 2", forField: "street")
      
      try message1.set(groupMessage1, forField: "group_field")
      try message2.set(groupMessage2, forField: "group_field")
      
      // Group сообщения с одинаковым содержимым должны быть равны
      XCTAssertEqual(message1, message2)
      
      // Group сообщения с разным содержимым не должны быть равны
      try message2.set(differentGroupMessage, forField: "group_field")
      XCTAssertNotEqual(message1, message2)
      
    } catch {
      XCTFail("Не должно быть исключений при тестировании group полей: \(error)")
    }
  }
  
  // MARK: - Map with Missing Key Tests
  
  func testMapComparisonWithMissingKey() {
    // Создаем сообщение с map полем для тестирования отсутствующих ключей
    var messageDesc = MessageDescriptor(name: "MapMissingKeyTest", parent: fileDescriptor)
    
    let stringKeyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let stringValueInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let stringMapEntryInfo = MapEntryInfo(keyFieldInfo: stringKeyInfo, valueFieldInfo: stringValueInfo)
    messageDesc.addField(FieldDescriptor(
      name: "test_map",
      number: 1,
      type: .message,
      typeName: "map<string, string>",
      isRepeated: true,
      isMap: true,
      mapEntryInfo: stringMapEntryInfo
    ))
    
    fileDescriptor.addMessage(messageDesc)
    
    var message1 = DynamicMessage(descriptor: messageDesc)
    var message2 = DynamicMessage(descriptor: messageDesc)
    
    do {
      // Создаем map с одним ключом в message1
      try message1.setMapEntry("value1", forKey: "key1", inField: "test_map")
      
      // Создаем map с другим ключом в message2
      try message2.setMapEntry("value1", forKey: "key2", inField: "test_map")
      
      // Map с разными ключами не должны быть равны
      XCTAssertNotEqual(message1, message2)
      
      // Добавляем ключ в message2, но с другим значением
      try message2.setMapEntry("different_value", forKey: "key1", inField: "test_map")
      
      // Map с одинаковыми ключами но разными значениями не должны быть равны
      XCTAssertNotEqual(message1, message2)
      
    } catch {
      XCTFail("Не должно быть исключений при тестировании map с отсутствующими ключами: \(error)")
    }
  }
  
  // MARK: - Array vs Non-Array Tests
  
  func testRepeatedFieldComparisonFailures() {
    // Создаем сообщение с repeated полем
    var messageDesc = MessageDescriptor(name: "RepeatedFailureTest", parent: fileDescriptor)
    messageDesc.addField(FieldDescriptor(
      name: "repeated_field",
      number: 1,
      type: .string,
      isRepeated: true
    ))
    
    fileDescriptor.addMessage(messageDesc)
    
    var message1 = DynamicMessage(descriptor: messageDesc)
    var message2 = DynamicMessage(descriptor: messageDesc)
    
    do {
      // Устанавливаем repeated поля с одинаковыми значениями
      try message1.addRepeatedValue("value1", forField: "repeated_field")
      try message1.addRepeatedValue("value2", forField: "repeated_field")
      
      try message2.addRepeatedValue("value1", forField: "repeated_field")
      try message2.addRepeatedValue("value2", forField: "repeated_field")
      
      XCTAssertEqual(message1, message2)
      
      // Создаем третье сообщение с меньшим количеством элементов
      var message3 = DynamicMessage(descriptor: messageDesc)
      try message3.addRepeatedValue("value1", forField: "repeated_field")
      
      XCTAssertNotEqual(message1, message3)
      
    } catch {
      XCTFail("Не должно быть исключений при тестировании repeated полей: \(error)")
    }
  }
}
