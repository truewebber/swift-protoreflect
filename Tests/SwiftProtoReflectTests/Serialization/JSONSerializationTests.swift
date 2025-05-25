//
// JSONSerializationTests.swift
//
// Тесты для проверки JSON сериализации и десериализации Protocol Buffers
//
// Тестовые случаи из плана:
// - Test-JSON-001: JSON сериализация всех типов данных с соответствием формату protoc --json_out
// - Test-JSON-002: Обработка специальных значений (Infinity, NaN, null) в JSON
// - Test-JSON-003: Корректная JSON десериализация данных, созданных protoc --json_out

import XCTest

@testable import SwiftProtoReflect

final class JSONSerializationTests: XCTestCase {
  
  var fileDescriptor: FileDescriptor!
  var messageFactory: MessageFactory!
  var serializer: JSONSerializer!
  
  override func setUp() {
    super.setUp()
    
    fileDescriptor = FileDescriptor(name: "test_json_serialization.proto", package: "test.json")
    messageFactory = MessageFactory()
    serializer = JSONSerializer()
  }
  
  override func tearDown() {
    fileDescriptor = nil
    messageFactory = nil
    serializer = nil
    super.tearDown()
  }
  
  // MARK: - Scalar Types Tests (Test-JSON-001)
  
  func testSerializeAllScalarTypes() throws {
    // Создаем сообщение со всеми скалярными типами
    var scalarMessage = MessageDescriptor(name: "ScalarMessage", parent: fileDescriptor)
    
    scalarMessage.addField(FieldDescriptor(name: "double_field", number: 1, type: .double))
    scalarMessage.addField(FieldDescriptor(name: "float_field", number: 2, type: .float))
    scalarMessage.addField(FieldDescriptor(name: "int32_field", number: 3, type: .int32))
    scalarMessage.addField(FieldDescriptor(name: "int64_field", number: 4, type: .int64))
    scalarMessage.addField(FieldDescriptor(name: "uint32_field", number: 5, type: .uint32))
    scalarMessage.addField(FieldDescriptor(name: "uint64_field", number: 6, type: .uint64))
    scalarMessage.addField(FieldDescriptor(name: "bool_field", number: 7, type: .bool))
    scalarMessage.addField(FieldDescriptor(name: "string_field", number: 8, type: .string))
    scalarMessage.addField(FieldDescriptor(name: "bytes_field", number: 9, type: .bytes))
    
    fileDescriptor.addMessage(scalarMessage)
    
    // Создаем сообщение с данными
    let values: [String: Any] = [
      "double_field": 3.14159,
      "float_field": Float(2.718),
      "int32_field": Int32(-42),
      "int64_field": Int64(-9223372036854775000),
      "uint32_field": UInt32(4294967295),
      "uint64_field": UInt64(18446744073709551615),
      "bool_field": true,
      "string_field": "Hello, World! 🌍",
      "bytes_field": Data([0x01, 0x02, 0x03, 0xFF])
    ]
    
    let message = try messageFactory.createMessage(from: scalarMessage, with: values)
    
    // Сериализуем в JSON
    let jsonData = try serializer.serialize(message)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
    
    // Проверяем типы и значения
    XCTAssertEqual(jsonObject["double_field"] as! Double, 3.14159, accuracy: 0.00001)
    XCTAssertEqual(jsonObject["float_field"] as! Float, Float(2.718), accuracy: 0.001)
    XCTAssertEqual(jsonObject["int32_field"] as! Int, -42)
    XCTAssertEqual(jsonObject["int64_field"] as! String, "-9223372036854775000") // int64 как строка
    XCTAssertEqual(jsonObject["uint32_field"] as! UInt, 4294967295)
    XCTAssertEqual(jsonObject["uint64_field"] as! String, "18446744073709551615") // uint64 как строка
    XCTAssertEqual(jsonObject["bool_field"] as! Bool, true)
    XCTAssertEqual(jsonObject["string_field"] as! String, "Hello, World! 🌍")
    XCTAssertEqual(jsonObject["bytes_field"] as! String, "AQID/w==") // base64 encoded
  }
  
  func testSerializeDoubleSpecialValues() throws {
    var message = MessageDescriptor(name: "DoubleSpecialMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "infinity", number: 1, type: .double))
    message.addField(FieldDescriptor(name: "negative_infinity", number: 2, type: .double))
    message.addField(FieldDescriptor(name: "nan", number: 3, type: .double))
    fileDescriptor.addMessage(message)
    
    let dynamicMessage = try messageFactory.createMessage(from: message, with: [
      "infinity": Double.infinity,
      "negative_infinity": -Double.infinity,
      "nan": Double.nan
    ])
    
    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
    
    // Проверяем специальные значения
    XCTAssertEqual(jsonObject["infinity"] as! String, "Infinity")
    XCTAssertEqual(jsonObject["negative_infinity"] as! String, "-Infinity")
    XCTAssertEqual(jsonObject["nan"] as! String, "NaN")
  }
  
  func testSerializeFloatSpecialValues() throws {
    var message = MessageDescriptor(name: "FloatSpecialMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "infinity", number: 1, type: .float))
    message.addField(FieldDescriptor(name: "negative_infinity", number: 2, type: .float))
    message.addField(FieldDescriptor(name: "nan", number: 3, type: .float))
    fileDescriptor.addMessage(message)
    
    let dynamicMessage = try messageFactory.createMessage(from: message, with: [
      "infinity": Float.infinity,
      "negative_infinity": -Float.infinity,
      "nan": Float.nan
    ])
    
    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
    
    // Проверяем специальные значения для float
    XCTAssertEqual(jsonObject["infinity"] as! String, "Infinity")
    XCTAssertEqual(jsonObject["negative_infinity"] as! String, "-Infinity")
    XCTAssertEqual(jsonObject["nan"] as! String, "NaN")
  }
  
  // MARK: - String and Bytes Tests
  
  func testSerializeStringValues() throws {
    var message = MessageDescriptor(name: "StringMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "simple", number: 1, type: .string))
    message.addField(FieldDescriptor(name: "unicode", number: 2, type: .string))
    message.addField(FieldDescriptor(name: "empty", number: 3, type: .string))
    fileDescriptor.addMessage(message)
    
    let dynamicMessage = try messageFactory.createMessage(from: message, with: [
      "simple": "Hello",
      "unicode": "Привет, 世界! 🌟",
      "empty": ""
    ])
    
    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
    
    XCTAssertEqual(jsonObject["simple"] as! String, "Hello")
    XCTAssertEqual(jsonObject["unicode"] as! String, "Привет, 世界! 🌟")
    XCTAssertEqual(jsonObject["empty"] as! String, "")
  }
  
  func testSerializeBytesValues() throws {
    var message = MessageDescriptor(name: "BytesMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "data", number: 1, type: .bytes))
    message.addField(FieldDescriptor(name: "empty_data", number: 2, type: .bytes))
    fileDescriptor.addMessage(message)
    
    let testBytes = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F]) // "Hello" в ASCII
    let emptyBytes = Data()
    
    let dynamicMessage = try messageFactory.createMessage(from: message, with: [
      "data": testBytes,
      "empty_data": emptyBytes
    ])
    
    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
    
    XCTAssertEqual(jsonObject["data"] as! String, "SGVsbG8=") // base64 encoded "Hello"
    XCTAssertEqual(jsonObject["empty_data"] as! String, "") // empty base64
  }
  
  // MARK: - Nested Messages Tests
  
  func testSerializeNestedMessage() throws {
    // Создаем вложенное сообщение
    var nestedMessage = MessageDescriptor(name: "NestedMessage", parent: fileDescriptor)
    nestedMessage.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    nestedMessage.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    fileDescriptor.addMessage(nestedMessage)
    
    // Создаем основное сообщение
    var parentMessage = MessageDescriptor(name: "ParentMessage", parent: fileDescriptor)
    parentMessage.addField(FieldDescriptor(
      name: "nested",
      number: 1,
      type: .message,
      typeName: nestedMessage.fullName
    ))
    parentMessage.addField(FieldDescriptor(name: "status", number: 2, type: .string))
    fileDescriptor.addMessage(parentMessage)
    
    // Создаем вложенное сообщение
    let nested = try messageFactory.createMessage(from: nestedMessage, with: [
      "id": Int32(42),
      "name": "test"
    ])
    
    // Создаем родительское сообщение
    var parent = messageFactory.createMessage(from: parentMessage)
    try parent.set(nested, forField: "nested")
    try parent.set("active", forField: "status")
    
    // Сериализуем
    let jsonData = try serializer.serialize(parent)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
    
    // Проверяем структуру
    XCTAssertEqual(jsonObject["status"] as! String, "active")
    
    let nestedObject = jsonObject["nested"] as! [String: Any]
    XCTAssertEqual(nestedObject["id"] as! Int, 42)
    XCTAssertEqual(nestedObject["name"] as! String, "test")
  }
  
  // MARK: - Repeated Fields Tests
  
  func testSerializeRepeatedFields() throws {
    var message = MessageDescriptor(name: "RepeatedMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "numbers", number: 1, type: .int32, isRepeated: true))
    message.addField(FieldDescriptor(name: "words", number: 2, type: .string, isRepeated: true))
    message.addField(FieldDescriptor(name: "flags", number: 3, type: .bool, isRepeated: true))
    fileDescriptor.addMessage(message)
    
    let dynamicMessage = try messageFactory.createMessage(from: message, with: [
      "numbers": [Int32(1), Int32(2), Int32(3)],
      "words": ["hello", "world"],
      "flags": [true, false, true]
    ])
    
    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
    
    let numbers = jsonObject["numbers"] as! [Int]
    XCTAssertEqual(numbers, [1, 2, 3])
    
    let words = jsonObject["words"] as! [String]
    XCTAssertEqual(words, ["hello", "world"])
    
    let flags = jsonObject["flags"] as! [Bool]
    XCTAssertEqual(flags, [true, false, true])
  }
  
  func testSerializeEmptyRepeatedField() throws {
    var message = MessageDescriptor(name: "EmptyRepeatedMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "values", number: 1, type: .int32, isRepeated: true))
    fileDescriptor.addMessage(message)
    
    // Создаем сообщение без установки repeated поля
    let dynamicMessage = messageFactory.createMessage(from: message)
    
    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
    
    // Поле без значений не должно появляться в JSON
    XCTAssertNil(jsonObject["values"])
  }
  
  // MARK: - Map Fields Tests
  
  func testSerializeMapFields() throws {
    // Создаем map поле: map<string, int32>
    let keyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: keyFieldInfo, valueFieldInfo: valueFieldInfo)
    
    var message = MessageDescriptor(name: "MapMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(
      name: "string_to_int",
      number: 1,
      type: .message,
      typeName: "string_to_int_entry",
      isMap: true,
      mapEntryInfo: mapEntryInfo
    ))
    fileDescriptor.addMessage(message)
    
    let mapData: [String: Int32] = [
      "first": 1,
      "second": 2,
      "third": 3
    ]
    
    let dynamicMessage = try messageFactory.createMessage(from: message, with: [
      "string_to_int": mapData
    ])
    
    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
    
    let mapObject = jsonObject["string_to_int"] as! [String: Int]
    XCTAssertEqual(mapObject["first"], 1)
    XCTAssertEqual(mapObject["second"], 2)
    XCTAssertEqual(mapObject["third"], 3)
  }
  
  func testSerializeMapWithIntegerKeys() throws {
    // Создаем map поле: map<int32, string>
    let keyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .int32)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: keyFieldInfo, valueFieldInfo: valueFieldInfo)
    
    var message = MessageDescriptor(name: "IntMapMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(
      name: "int_to_string",
      number: 1,
      type: .message,
      typeName: "int_to_string_entry",
      isMap: true,
      mapEntryInfo: mapEntryInfo
    ))
    fileDescriptor.addMessage(message)
    
    let mapData: [Int32: String] = [
      1: "one",
      2: "two",
      42: "answer"
    ]
    
    let dynamicMessage = try messageFactory.createMessage(from: message, with: [
      "int_to_string": mapData
    ])
    
    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
    
    // В JSON все ключи должны быть строками
    let mapObject = jsonObject["int_to_string"] as! [String: String]
    XCTAssertEqual(mapObject["1"], "one")
    XCTAssertEqual(mapObject["2"], "two")
    XCTAssertEqual(mapObject["42"], "answer")
  }
  
  // MARK: - Enum Tests
  
  func testSerializeEnumField() throws {
    // Создаем enum
    var enumDescriptor = EnumDescriptor(name: "Status", parent: fileDescriptor)
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "ACTIVE", number: 1))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "INACTIVE", number: 2))
    fileDescriptor.addEnum(enumDescriptor)
    
    var message = MessageDescriptor(name: "EnumMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(
      name: "status",
      number: 1,
      type: .enum,
      typeName: enumDescriptor.fullName
    ))
    fileDescriptor.addMessage(message)
    
    let dynamicMessage = try messageFactory.createMessage(from: message, with: [
      "status": Int32(1) // ACTIVE
    ])
    
    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
    
    // Пока enum возвращается как число, можно расширить для поддержки имен
    XCTAssertEqual(jsonObject["status"] as! Int, 1)
  }
  
  // MARK: - JSON Serialization Options Tests
  
  func testJSONSerializationOptions() throws {
    var message = MessageDescriptor(name: "OptionsMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "test_field", number: 1, type: .string, jsonName: "testField"))
    fileDescriptor.addMessage(message)
    
    let dynamicMessage = try messageFactory.createMessage(from: message, with: [
      "test_field": "test_value"
    ])
    
    // Тест с camelCase именами (по умолчанию)
    let defaultSerializer = JSONSerializer()
    let defaultJsonData = try defaultSerializer.serialize(dynamicMessage)
    let defaultJsonObject = try JSONSerialization.jsonObject(with: defaultJsonData) as! [String: Any]
    XCTAssertEqual(defaultJsonObject["testField"] as! String, "test_value")
    
    // Тест с оригинальными именами полей
    let originalNamesSerializer = JSONSerializer(options: JSONSerializationOptions(useOriginalFieldNames: true))
    let originalJsonData = try originalNamesSerializer.serialize(dynamicMessage)
    let originalJsonObject = try JSONSerialization.jsonObject(with: originalJsonData) as! [String: Any]
    XCTAssertEqual(originalJsonObject["test_field"] as! String, "test_value")
    
    // Тест с pretty printing
    let prettySerializer = JSONSerializer(options: JSONSerializationOptions(prettyPrinted: true))
    let prettyJsonData = try prettySerializer.serialize(dynamicMessage)
    let prettyJsonString = String(data: prettyJsonData, encoding: .utf8)!
    XCTAssertTrue(prettyJsonString.contains("\n")) // Должны быть переносы строк
  }
  
  // MARK: - Error Handling Tests
  
  func testSerializationErrors() throws {
    var message = MessageDescriptor(name: "ErrorMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "group_field", number: 1, type: .group))
    fileDescriptor.addMessage(message)
    
    // Создаем сообщение с group полем (неподдерживаемый тип)
    var dynamicMessage = messageFactory.createMessage(from: message)
    let groupMessage = messageFactory.createMessage(from: message)
    try dynamicMessage.set(groupMessage, forField: "group_field")
    
    // Group тип не поддерживается
    XCTAssertThrowsError(try serializer.serialize(dynamicMessage)) { error in
      if let jsonError = error as? JSONSerializationError {
        if case .unsupportedFieldType(let type) = jsonError {
          XCTAssertEqual(type, "group")
        } else {
          XCTFail("Wrong error type: \(jsonError)")
        }
      } else {
        XCTFail("Expected JSONSerializationError, got: \(error)")
      }
    }
  }
  
  func testJSONSerializationErrorDescriptions() {
    let error1 = JSONSerializationError.invalidFieldType(fieldName: "test", expectedType: "String", actualType: "Int")
    XCTAssertEqual(error1.description, "Invalid field type for field 'test': expected String, got Int")
    
    let error2 = JSONSerializationError.valueTypeMismatch(expected: "String", actual: "Int")
    XCTAssertEqual(error2.description, "Value type mismatch: expected String, got Int")
    
    let error3 = JSONSerializationError.missingMapEntryInfo(fieldName: "map_field")
    XCTAssertEqual(error3.description, "Missing map entry info for field 'map_field'")
    
    let error4 = JSONSerializationError.missingFieldValue(fieldName: "missing_field")
    XCTAssertEqual(error4.description, "Missing value for field 'missing_field'")
    
    let error5 = JSONSerializationError.unsupportedFieldType(type: "group")
    XCTAssertEqual(error5.description, "Unsupported field type: group")
    
    let error6 = JSONSerializationError.invalidMapKeyType(keyType: "FieldType.float")
    XCTAssertEqual(error6.description, "Invalid map key type: FieldType.float")
  }
  
  func testJSONSerializationErrorEquality() {
    let error1 = JSONSerializationError.invalidFieldType(fieldName: "test", expectedType: "String", actualType: "Int")
    let error2 = JSONSerializationError.invalidFieldType(fieldName: "test", expectedType: "String", actualType: "Int")
    let error3 = JSONSerializationError.invalidFieldType(fieldName: "other", expectedType: "String", actualType: "Int")
    
    XCTAssertEqual(error1, error2)
    XCTAssertNotEqual(error1, error3)
    
    let error4 = JSONSerializationError.valueTypeMismatch(expected: "String", actual: "Int")
    let error5 = JSONSerializationError.valueTypeMismatch(expected: "String", actual: "Int")
    XCTAssertEqual(error4, error5)
    XCTAssertNotEqual(error1, error4)
  }
  
  // MARK: - Performance Tests
  
  func testJSONSerializationPerformance() throws {
    // Создаем сложное сообщение для тестирования производительности
    var message = MessageDescriptor(name: "PerformanceMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "numbers", number: 1, type: .int32, isRepeated: true))
    message.addField(FieldDescriptor(name: "text", number: 2, type: .string))
    message.addField(FieldDescriptor(name: "flag", number: 3, type: .bool))
    fileDescriptor.addMessage(message)
    
    let numbers = Array(1...1000).map { Int32($0) }
    let dynamicMessage = try messageFactory.createMessage(from: message, with: [
      "numbers": numbers,
      "text": "Performance test message with some content",
      "flag": true
    ])
    
    measure {
      do {
        _ = try serializer.serialize(dynamicMessage)
      } catch {
        XCTFail("Serialization failed: \(error)")
      }
    }
  }
}
