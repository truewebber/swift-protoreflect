//
// JSONDeserializationTests.swift
//
// Тесты для проверки JSON десериализации Protocol Buffers
//
// Тестовые случаи из плана:
// - Test-JSON-Deser-001: JSON десериализация всех типов данных с round-trip тестированием
// - Test-JSON-Deser-002: Обработка специальных значений (Infinity, NaN, base64) из JSON
// - Test-JSON-Deser-003: Корректная обработка ошибок и валидация JSON данных
// - Test-JSON-Deser-004: Round-trip совместимость с JSONSerializer

import XCTest

@testable import SwiftProtoReflect

final class JSONDeserializationTests: XCTestCase {
  
  var fileDescriptor: FileDescriptor!
  var messageFactory: MessageFactory!
  var serializer: JSONSerializer!
  var deserializer: JSONDeserializer!
  
  override func setUp() {
    super.setUp()
    
    fileDescriptor = FileDescriptor(name: "test_json_deserialization.proto", package: "test.json.deser")
    messageFactory = MessageFactory()
    serializer = JSONSerializer()
    deserializer = JSONDeserializer()
  }
  
  override func tearDown() {
    fileDescriptor = nil
    messageFactory = nil
    serializer = nil
    deserializer = nil
    super.tearDown()
  }
  
  // MARK: - Round-trip Tests (Test-JSON-Deser-004)
  
  func testRoundTripAllScalarTypes() throws {
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
    
    // Создаем оригинальное сообщение
    let originalValues: [String: Any] = [
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
    
    let originalMessage = try messageFactory.createMessage(from: scalarMessage, with: originalValues)
    
    // Round-trip: Message -> JSON -> Message
    let jsonData = try serializer.serialize(originalMessage)
    let deserializedMessage = try deserializer.deserialize(jsonData, using: scalarMessage)
    
    // Проверяем все поля
    let originalAccess = FieldAccessor(originalMessage)
    let deserializedAccess = FieldAccessor(deserializedMessage)
    
    XCTAssertEqual(originalAccess.getValue("double_field", as: Double.self)!, 
                   deserializedAccess.getValue("double_field", as: Double.self)!, accuracy: 0.00001)
    XCTAssertEqual(originalAccess.getValue("float_field", as: Float.self)!, 
                   deserializedAccess.getValue("float_field", as: Float.self)!, accuracy: 0.001)
    XCTAssertEqual(originalAccess.getValue("int32_field", as: Int32.self)!, 
                   deserializedAccess.getValue("int32_field", as: Int32.self)!)
    XCTAssertEqual(originalAccess.getValue("int64_field", as: Int64.self)!, 
                   deserializedAccess.getValue("int64_field", as: Int64.self)!)
    XCTAssertEqual(originalAccess.getValue("uint32_field", as: UInt32.self)!, 
                   deserializedAccess.getValue("uint32_field", as: UInt32.self)!)
    XCTAssertEqual(originalAccess.getValue("uint64_field", as: UInt64.self)!, 
                   deserializedAccess.getValue("uint64_field", as: UInt64.self)!)
    XCTAssertEqual(originalAccess.getValue("bool_field", as: Bool.self)!, 
                   deserializedAccess.getValue("bool_field", as: Bool.self)!)
    XCTAssertEqual(originalAccess.getValue("string_field", as: String.self)!, 
                   deserializedAccess.getValue("string_field", as: String.self)!)
    XCTAssertEqual(originalAccess.getValue("bytes_field", as: Data.self)!, 
                   deserializedAccess.getValue("bytes_field", as: Data.self)!)
  }
  
  func testRoundTripSpecialFloatValues() throws {
    var message = MessageDescriptor(name: "SpecialFloatMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "double_infinity", number: 1, type: .double))
    message.addField(FieldDescriptor(name: "double_neg_infinity", number: 2, type: .double))
    message.addField(FieldDescriptor(name: "double_nan", number: 3, type: .double))
    message.addField(FieldDescriptor(name: "float_infinity", number: 4, type: .float))
    message.addField(FieldDescriptor(name: "float_neg_infinity", number: 5, type: .float))
    message.addField(FieldDescriptor(name: "float_nan", number: 6, type: .float))
    fileDescriptor.addMessage(message)
    
    let originalMessage = try messageFactory.createMessage(from: message, with: [
      "double_infinity": Double.infinity,
      "double_neg_infinity": -Double.infinity,
      "double_nan": Double.nan,
      "float_infinity": Float.infinity,
      "float_neg_infinity": -Float.infinity,
      "float_nan": Float.nan
    ])
    
    // Round-trip
    let jsonData = try serializer.serialize(originalMessage)
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)
    
    let _ = FieldAccessor(originalMessage)
    let deserializedAccess = FieldAccessor(deserializedMessage)
    
    // Проверяем специальные значения
    let doubleInfinity = deserializedAccess.getValue("double_infinity", as: Double.self)!
    XCTAssertTrue(doubleInfinity.isInfinite && doubleInfinity > 0)
    
    let doubleNegInfinity = deserializedAccess.getValue("double_neg_infinity", as: Double.self)!
    XCTAssertTrue(doubleNegInfinity.isInfinite && doubleNegInfinity < 0)
    
    let doubleNaN = deserializedAccess.getValue("double_nan", as: Double.self)!
    XCTAssertTrue(doubleNaN.isNaN)
    
    let floatInfinity = deserializedAccess.getValue("float_infinity", as: Float.self)!
    XCTAssertTrue(floatInfinity.isInfinite && floatInfinity > 0)
    
    let floatNegInfinity = deserializedAccess.getValue("float_neg_infinity", as: Float.self)!
    XCTAssertTrue(floatNegInfinity.isInfinite && floatNegInfinity < 0)
    
    let floatNaN = deserializedAccess.getValue("float_nan", as: Float.self)!
    XCTAssertTrue(floatNaN.isNaN)
  }
  
  func testRoundTripRepeatedFields() throws {
    var message = MessageDescriptor(name: "RepeatedMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "numbers", number: 1, type: .int32, isRepeated: true))
    message.addField(FieldDescriptor(name: "words", number: 2, type: .string, isRepeated: true))
    message.addField(FieldDescriptor(name: "flags", number: 3, type: .bool, isRepeated: true))
    fileDescriptor.addMessage(message)
    
    let originalMessage = try messageFactory.createMessage(from: message, with: [
      "numbers": [Int32(1), Int32(2), Int32(3)],
      "words": ["hello", "world", "test"],
      "flags": [true, false, true]
    ])
    
    // Round-trip
    let jsonData = try serializer.serialize(originalMessage)
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)
    
    let originalAccess = FieldAccessor(originalMessage)
    let deserializedAccess = FieldAccessor(deserializedMessage)
    
    XCTAssertEqual(originalAccess.getValue("numbers", as: [Int32].self)!, 
                   deserializedAccess.getValue("numbers", as: [Int32].self)!)
    XCTAssertEqual(originalAccess.getValue("words", as: [String].self)!, 
                   deserializedAccess.getValue("words", as: [String].self)!)
    XCTAssertEqual(originalAccess.getValue("flags", as: [Bool].self)!, 
                   deserializedAccess.getValue("flags", as: [Bool].self)!)
  }
  
  func testRoundTripMapFields() throws {
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
    
    let originalMessage = try messageFactory.createMessage(from: message, with: [
      "string_to_int": mapData
    ])
    
    // Round-trip
    let jsonData = try serializer.serialize(originalMessage)
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)
    
    let originalAccess = FieldAccessor(originalMessage)
    let deserializedAccess = FieldAccessor(deserializedMessage)
    
    let originalMap = originalAccess.getValue("string_to_int", as: [String: Int32].self)!
    let deserializedMap = deserializedAccess.getValue("string_to_int", as: [String: Int32].self)!
    
    XCTAssertEqual(originalMap, deserializedMap)
  }
  
  // MARK: - Direct JSON Deserialization Tests (Test-JSON-Deser-001)
  
  func testDeserializeScalarTypesFromJSON() throws {
    var message = MessageDescriptor(name: "ScalarMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "double_field", number: 1, type: .double))
    message.addField(FieldDescriptor(name: "int32_field", number: 2, type: .int32))
    message.addField(FieldDescriptor(name: "int64_field", number: 3, type: .int64))
    message.addField(FieldDescriptor(name: "bool_field", number: 4, type: .bool))
    message.addField(FieldDescriptor(name: "string_field", number: 5, type: .string))
    fileDescriptor.addMessage(message)
    
    let jsonString = """
    {
      "double_field": 3.14159,
      "int32_field": -42,
      "int64_field": "-9223372036854775000",
      "bool_field": true,
      "string_field": "Hello, World!"
    }
    """
    
    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)
    
    let fieldAccess = FieldAccessor(deserializedMessage)
    
    XCTAssertEqual(fieldAccess.getValue("double_field", as: Double.self)!, 3.14159, accuracy: 0.00001)
    XCTAssertEqual(fieldAccess.getValue("int32_field", as: Int32.self)!, -42)
    XCTAssertEqual(fieldAccess.getValue("int64_field", as: Int64.self)!, -9223372036854775000)
    XCTAssertEqual(fieldAccess.getValue("bool_field", as: Bool.self)!, true)
    XCTAssertEqual(fieldAccess.getValue("string_field", as: String.self)!, "Hello, World!")
  }
  
  func testDeserializeBytesFromJSON() throws {
    var message = MessageDescriptor(name: "BytesMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "data", number: 1, type: .bytes))
    fileDescriptor.addMessage(message)
    
    let jsonString = """
    {
      "data": "AQID/w=="
    }
    """
    
    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)
    
    let fieldAccess = FieldAccessor(deserializedMessage)
    let bytesData = fieldAccess.getValue("data", as: Data.self)!
    
    XCTAssertEqual(bytesData, Data([0x01, 0x02, 0x03, 0xFF]))
  }
  
  func testDeserializeSpecialFloatValuesFromJSON() throws {
    var message = MessageDescriptor(name: "SpecialFloatMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "infinity", number: 1, type: .double))
    message.addField(FieldDescriptor(name: "negative_infinity", number: 2, type: .double))
    message.addField(FieldDescriptor(name: "nan", number: 3, type: .double))
    fileDescriptor.addMessage(message)
    
    let jsonString = """
    {
      "infinity": "Infinity",
      "negative_infinity": "-Infinity",
      "nan": "NaN"
    }
    """
    
    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)
    
    let fieldAccess = FieldAccessor(deserializedMessage)
    
    let infinity = fieldAccess.getValue("infinity", as: Double.self)!
    XCTAssertTrue(infinity.isInfinite && infinity > 0)
    
    let negativeInfinity = fieldAccess.getValue("negative_infinity", as: Double.self)!
    XCTAssertTrue(negativeInfinity.isInfinite && negativeInfinity < 0)
    
    let nan = fieldAccess.getValue("nan", as: Double.self)!
    XCTAssertTrue(nan.isNaN)
  }
  
  func testDeserializeRepeatedFieldsFromJSON() throws {
    var message = MessageDescriptor(name: "RepeatedMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "numbers", number: 1, type: .int32, isRepeated: true))
    message.addField(FieldDescriptor(name: "words", number: 2, type: .string, isRepeated: true))
    fileDescriptor.addMessage(message)
    
    let jsonString = """
    {
      "numbers": [1, 2, 3, 4, 5],
      "words": ["hello", "world", "test"]
    }
    """
    
    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)
    
    let fieldAccess = FieldAccessor(deserializedMessage)
    
    let numbers = fieldAccess.getValue("numbers", as: [Int32].self)!
    XCTAssertEqual(numbers, [1, 2, 3, 4, 5])
    
    let words = fieldAccess.getValue("words", as: [String].self)!
    XCTAssertEqual(words, ["hello", "world", "test"])
  }
  
  func testDeserializeMapFieldsFromJSON() throws {
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
    
    let jsonString = """
    {
      "string_to_int": {
        "first": 1,
        "second": 2,
        "third": 3
      }
    }
    """
    
    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)
    
    let fieldAccess = FieldAccessor(deserializedMessage)
    let mapData = fieldAccess.getValue("string_to_int", as: [String: Int32].self)!
    
    XCTAssertEqual(mapData["first"], 1)
    XCTAssertEqual(mapData["second"], 2)
    XCTAssertEqual(mapData["third"], 3)
  }
  
  func testDeserializeMapWithIntegerKeysFromJSON() throws {
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
    
    let jsonString = """
    {
      "int_to_string": {
        "1": "one",
        "2": "two",
        "42": "answer"
      }
    }
    """
    
    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)
    
    let fieldAccess = FieldAccessor(deserializedMessage)
    let mapData = fieldAccess.getValue("int_to_string", as: [Int32: String].self)!
    
    XCTAssertEqual(mapData[1], "one")
    XCTAssertEqual(mapData[2], "two")
    XCTAssertEqual(mapData[42], "answer")
  }
  
  // MARK: - Field Name Handling Tests
  
  func testDeserializeWithCamelCaseFieldNames() throws {
    var message = MessageDescriptor(name: "CamelCaseMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "test_field", number: 1, type: .string, jsonName: "testField"))
    message.addField(FieldDescriptor(name: "another_field", number: 2, type: .int32, jsonName: "anotherField"))
    fileDescriptor.addMessage(message)
    
    let jsonString = """
    {
      "testField": "hello",
      "anotherField": 42
    }
    """
    
    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)
    
    let fieldAccess = FieldAccessor(deserializedMessage)
    
    XCTAssertEqual(fieldAccess.getValue("test_field", as: String.self)!, "hello")
    XCTAssertEqual(fieldAccess.getValue("another_field", as: Int32.self)!, 42)
  }
  
  func testDeserializeWithOriginalFieldNames() throws {
    var message = MessageDescriptor(name: "OriginalFieldMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "test_field", number: 1, type: .string, jsonName: "testField"))
    message.addField(FieldDescriptor(name: "another_field", number: 2, type: .int32, jsonName: "anotherField"))
    fileDescriptor.addMessage(message)
    
    let jsonString = """
    {
      "test_field": "hello",
      "another_field": 42
    }
    """
    
    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)
    
    let fieldAccess = FieldAccessor(deserializedMessage)
    
    XCTAssertEqual(fieldAccess.getValue("test_field", as: String.self)!, "hello")
    XCTAssertEqual(fieldAccess.getValue("another_field", as: Int32.self)!, 42)
  }
  
  // MARK: - Options Tests
  
  func testDeserializeWithIgnoreUnknownFields() throws {
    var message = MessageDescriptor(name: "KnownFieldsMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "known_field", number: 1, type: .string))
    fileDescriptor.addMessage(message)
    
    let jsonString = """
    {
      "known_field": "hello",
      "unknown_field": "should be ignored",
      "another_unknown": 42
    }
    """
    
    let jsonData = jsonString.data(using: .utf8)!
    
    // С игнорированием неизвестных полей (по умолчанию)
    let ignoreUnknownDeserializer = JSONDeserializer(options: JSONDeserializationOptions(ignoreUnknownFields: true))
    let deserializedMessage = try ignoreUnknownDeserializer.deserialize(jsonData, using: message)
    
    let fieldAccess = FieldAccessor(deserializedMessage)
    XCTAssertEqual(fieldAccess.getValue("known_field", as: String.self)!, "hello")
  }
  
  func testDeserializeWithStrictUnknownFields() throws {
    var message = MessageDescriptor(name: "StrictFieldsMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "known_field", number: 1, type: .string))
    fileDescriptor.addMessage(message)
    
    let jsonString = """
    {
      "known_field": "hello",
      "unknown_field": "should cause error"
    }
    """
    
    let jsonData = jsonString.data(using: .utf8)!
    
    // Без игнорирования неизвестных полей
    let strictDeserializer = JSONDeserializer(options: JSONDeserializationOptions(ignoreUnknownFields: false))
    
    XCTAssertThrowsError(try strictDeserializer.deserialize(jsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError {
        if case .unknownField(let fieldName, let messageName) = jsonError {
          XCTAssertEqual(fieldName, "unknown_field")
          XCTAssertEqual(messageName, "StrictFieldsMessage")
        } else {
          XCTFail("Wrong error type: \(jsonError)")
        }
      } else {
        XCTFail("Expected JSONDeserializationError, got: \(error)")
      }
    }
  }
  
  // MARK: - Error Handling Tests (Test-JSON-Deser-003)
  
  func testDeserializeInvalidJSON() throws {
    var message = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "test_field", number: 1, type: .string))
    fileDescriptor.addMessage(message)
    
    let invalidJsonData = "{ invalid json }".data(using: .utf8)!
    
    XCTAssertThrowsError(try deserializer.deserialize(invalidJsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError {
        if case .invalidJSON(_) = jsonError {
          // Ожидаемая ошибка
        } else {
          XCTFail("Wrong error type: \(jsonError)")
        }
      } else {
        XCTFail("Expected JSONDeserializationError, got: \(error)")
      }
    }
  }
  
  func testDeserializeInvalidJSONStructure() throws {
    var message = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "test_field", number: 1, type: .string))
    fileDescriptor.addMessage(message)
    
    let arrayJsonData = "[]".data(using: .utf8)!
    
    XCTAssertThrowsError(try deserializer.deserialize(arrayJsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError {
        if case .invalidJSONStructure(let expected, let actual) = jsonError {
          XCTAssertEqual(expected, "Object")
          XCTAssertTrue(actual.contains("Array"))
        } else {
          XCTFail("Wrong error type: \(jsonError)")
        }
      } else {
        XCTFail("Expected JSONDeserializationError, got: \(error)")
      }
    }
  }
  
  func testDeserializeValueTypeMismatch() throws {
    var message = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "int_field", number: 1, type: .int32))
    fileDescriptor.addMessage(message)
    
    let jsonString = """
    {
      "int_field": "not a number"
    }
    """
    
    let jsonData = jsonString.data(using: .utf8)!
    
    XCTAssertThrowsError(try deserializer.deserialize(jsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError {
        if case .invalidNumberFormat(let fieldName, let value) = jsonError {
          XCTAssertEqual(fieldName, "int_field")
          XCTAssertEqual(value, "not a number")
        } else {
          XCTFail("Wrong error type: \(jsonError)")
        }
      } else {
        XCTFail("Expected JSONDeserializationError, got: \(error)")
      }
    }
  }
  
  func testDeserializeInvalidBase64() throws {
    var message = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "bytes_field", number: 1, type: .bytes))
    fileDescriptor.addMessage(message)
    
    let jsonString = """
    {
      "bytes_field": "invalid base64!"
    }
    """
    
    let jsonData = jsonString.data(using: .utf8)!
    
    XCTAssertThrowsError(try deserializer.deserialize(jsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError {
        if case .invalidBase64(let fieldName, let value) = jsonError {
          XCTAssertEqual(fieldName, "bytes_field")
          XCTAssertEqual(value, "invalid base64!")
        } else {
          XCTFail("Wrong error type: \(jsonError)")
        }
      } else {
        XCTFail("Expected JSONDeserializationError, got: \(error)")
      }
    }
  }
  
  func testDeserializeNumberOutOfRange() throws {
    var message = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "int32_field", number: 1, type: .int32))
    fileDescriptor.addMessage(message)
    
    let jsonString = """
    {
      "int32_field": 9223372036854775807
    }
    """
    
    let jsonData = jsonString.data(using: .utf8)!
    
    XCTAssertThrowsError(try deserializer.deserialize(jsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError {
        if case .numberOutOfRange(let fieldName, _, let expectedRange) = jsonError {
          XCTAssertEqual(fieldName, "int32_field")
          XCTAssertEqual(expectedRange, "Int32")
        } else {
          XCTFail("Wrong error type: \(jsonError)")
        }
      } else {
        XCTFail("Expected JSONDeserializationError, got: \(error)")
      }
    }
  }
  
  func testDeserializeInvalidRepeatedField() throws {
    var message = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "repeated_field", number: 1, type: .int32, isRepeated: true))
    fileDescriptor.addMessage(message)
    
    let jsonString = """
    {
      "repeated_field": "not an array"
    }
    """
    
    let jsonData = jsonString.data(using: .utf8)!
    
    XCTAssertThrowsError(try deserializer.deserialize(jsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError {
        if case .invalidFieldType(let fieldName, let expectedType, _) = jsonError {
          XCTAssertEqual(fieldName, "repeated_field")
          XCTAssertEqual(expectedType, "Array")
        } else {
          XCTFail("Wrong error type: \(jsonError)")
        }
      } else {
        XCTFail("Expected JSONDeserializationError, got: \(error)")
      }
    }
  }
  
  func testDeserializeInvalidMapField() throws {
    let keyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: keyFieldInfo, valueFieldInfo: valueFieldInfo)
    
    var message = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(
      name: "map_field",
      number: 1,
      type: .message,
      typeName: "map_entry",
      isMap: true,
      mapEntryInfo: mapEntryInfo
    ))
    fileDescriptor.addMessage(message)
    
    let jsonString = """
    {
      "map_field": "not an object"
    }
    """
    
    let jsonData = jsonString.data(using: .utf8)!
    
    XCTAssertThrowsError(try deserializer.deserialize(jsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError {
        if case .invalidFieldType(let fieldName, let expectedType, _) = jsonError {
          XCTAssertEqual(fieldName, "map_field")
          XCTAssertEqual(expectedType, "Object")
        } else {
          XCTFail("Wrong error type: \(jsonError)")
        }
      } else {
        XCTFail("Expected JSONDeserializationError, got: \(error)")
      }
    }
  }
  
  // MARK: - Error Descriptions Tests
  
  func testErrorDescriptions() {
    let error1 = JSONDeserializationError.unknownField(fieldName: "test", messageName: "TestMessage")
    XCTAssertEqual(error1.description, "Unknown field 'test' in message 'TestMessage'")
    
    let error2 = JSONDeserializationError.valueTypeMismatch(fieldName: "field", expected: "String", actual: "Int")
    XCTAssertEqual(error2.description, "Value type mismatch for field 'field': expected String, got Int")
    
    let error3 = JSONDeserializationError.invalidNumberFormat(fieldName: "field", value: "abc")
    XCTAssertEqual(error3.description, "Invalid number format for field 'field': abc")
    
    let error4 = JSONDeserializationError.invalidBase64(fieldName: "field", value: "invalid!")
    XCTAssertEqual(error4.description, "Invalid base64 string for field 'field': invalid!")
  }
  
  func testErrorEquality() {
    let error1 = JSONDeserializationError.unknownField(fieldName: "test", messageName: "TestMessage")
    let error2 = JSONDeserializationError.unknownField(fieldName: "test", messageName: "TestMessage")
    let error3 = JSONDeserializationError.unknownField(fieldName: "other", messageName: "TestMessage")
    
    XCTAssertEqual(error1, error2)
    XCTAssertNotEqual(error1, error3)
    
    let error4 = JSONDeserializationError.valueTypeMismatch(fieldName: "field", expected: "String", actual: "Int")
    let error5 = JSONDeserializationError.valueTypeMismatch(fieldName: "field", expected: "String", actual: "Int")
    XCTAssertEqual(error4, error5)
    XCTAssertNotEqual(error1, error4)
  }
  
  // MARK: - Performance Tests
  
  func testJSONDeserializationPerformance() throws {
    // Создаем сложное сообщение для тестирования производительности
    var message = MessageDescriptor(name: "PerformanceMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "numbers", number: 1, type: .int32, isRepeated: true))
    message.addField(FieldDescriptor(name: "text", number: 2, type: .string))
    message.addField(FieldDescriptor(name: "flag", number: 3, type: .bool))
    fileDescriptor.addMessage(message)
    
    // Создаем большой JSON
    let numbers = Array(1...1000).map { String($0) }.joined(separator: ", ")
    let jsonString = """
    {
      "numbers": [\(numbers)],
      "text": "Performance test message with some content",
      "flag": true
    }
    """
    
    let jsonData = jsonString.data(using: .utf8)!
    
    measure {
      do {
        _ = try deserializer.deserialize(jsonData, using: message)
      } catch {
        XCTFail("Deserialization failed: \(error)")
      }
    }
  }
}
