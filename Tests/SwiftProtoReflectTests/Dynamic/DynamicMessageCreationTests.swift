//
// DynamicMessageCreationTests.swift
//
// Тесты для проверки создания динамических Protocol Buffers сообщений
//
// Тестовые случаи из плана:
// - Test-DYN-001: Создание сообщений из полученных protodescriptor с соответствием поведению C++
// - Test-DYN-002: Установка и получение значений полей всех типов данных proto3
// - Test-DYN-003: Проверка создания и манипуляции сложных вложенных структур

import XCTest

@testable import SwiftProtoReflect

final class DynamicMessageCreationTests: XCTestCase {
  // MARK: - Properties

  private var fileDescriptor: FileDescriptor!
  private var messageFactory: MessageFactory!
  private var simpleMessage: MessageDescriptor!
  private var complexMessage: MessageDescriptor!
  private var nestedMessage: MessageDescriptor!
  private var enumDescriptor: EnumDescriptor!

  // MARK: - Setup

  override func setUp() {
    super.setUp()

    messageFactory = MessageFactory()
    fileDescriptor = FileDescriptor(name: "test_creation.proto", package: "test.creation")

    // Создаем enum для тестирования
    enumDescriptor = EnumDescriptor(name: "Status", parent: fileDescriptor)
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "ACTIVE", number: 1))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "INACTIVE", number: 2))
    fileDescriptor.addEnum(enumDescriptor)

    // Простое сообщение с базовыми типами
    simpleMessage = MessageDescriptor(name: "SimpleMessage", parent: fileDescriptor)
    simpleMessage.addField(FieldDescriptor(name: "text", number: 1, type: .string))
    simpleMessage.addField(FieldDescriptor(name: "number", number: 2, type: .int32))
    simpleMessage.addField(FieldDescriptor(name: "flag", number: 3, type: .bool))
    fileDescriptor.addMessage(simpleMessage)

    // Вложенное сообщение
    nestedMessage = MessageDescriptor(name: "NestedMessage", parent: fileDescriptor)
    nestedMessage.addField(FieldDescriptor(name: "id", number: 1, type: .int64))
    nestedMessage.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    fileDescriptor.addMessage(nestedMessage)

    // Сложное сообщение со всеми типами полей
    complexMessage = MessageDescriptor(name: "ComplexMessage", parent: fileDescriptor)

    // Все скалярные типы proto3
    complexMessage.addField(FieldDescriptor(name: "double_field", number: 1, type: .double))
    complexMessage.addField(FieldDescriptor(name: "float_field", number: 2, type: .float))
    complexMessage.addField(FieldDescriptor(name: "int32_field", number: 3, type: .int32))
    complexMessage.addField(FieldDescriptor(name: "int64_field", number: 4, type: .int64))
    complexMessage.addField(FieldDescriptor(name: "uint32_field", number: 5, type: .uint32))
    complexMessage.addField(FieldDescriptor(name: "uint64_field", number: 6, type: .uint64))
    complexMessage.addField(FieldDescriptor(name: "sint32_field", number: 7, type: .sint32))
    complexMessage.addField(FieldDescriptor(name: "sint64_field", number: 8, type: .sint64))
    complexMessage.addField(FieldDescriptor(name: "fixed32_field", number: 9, type: .fixed32))
    complexMessage.addField(FieldDescriptor(name: "fixed64_field", number: 10, type: .fixed64))
    complexMessage.addField(FieldDescriptor(name: "sfixed32_field", number: 11, type: .sfixed32))
    complexMessage.addField(FieldDescriptor(name: "sfixed64_field", number: 12, type: .sfixed64))
    complexMessage.addField(FieldDescriptor(name: "bool_field", number: 13, type: .bool))
    complexMessage.addField(FieldDescriptor(name: "string_field", number: 14, type: .string))
    complexMessage.addField(FieldDescriptor(name: "bytes_field", number: 15, type: .bytes))

    // Сложные типы
    complexMessage.addField(
      FieldDescriptor(
        name: "nested_message",
        number: 16,
        type: .message,
        typeName: "test.creation.NestedMessage"
      )
    )
    complexMessage.addField(
      FieldDescriptor(
        name: "enum_field",
        number: 17,
        type: .enum,
        typeName: "test.creation.Status"
      )
    )

    // Repeated поля
    complexMessage.addField(
      FieldDescriptor(
        name: "repeated_strings",
        number: 18,
        type: .string,
        isRepeated: true
      )
    )
    complexMessage.addField(
      FieldDescriptor(
        name: "repeated_messages",
        number: 19,
        type: .message,
        typeName: "test.creation.NestedMessage",
        isRepeated: true
      )
    )

    // Map поля
    let stringMapEntry = MapEntryInfo(
      keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
      valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .string)
    )
    complexMessage.addField(
      FieldDescriptor(
        name: "string_map",
        number: 20,
        type: .message,
        typeName: "map<string, string>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: stringMapEntry
      )
    )

    let messageMapEntry = MapEntryInfo(
      keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
      valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .message, typeName: "test.creation.NestedMessage")
    )
    complexMessage.addField(
      FieldDescriptor(
        name: "message_map",
        number: 21,
        type: .message,
        typeName: "map<string, NestedMessage>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: messageMapEntry
      )
    )

    // Oneof поля
    complexMessage.addField(
      FieldDescriptor(
        name: "option_a",
        number: 22,
        type: .string,
        oneofIndex: 1
      )
    )
    complexMessage.addField(
      FieldDescriptor(
        name: "option_b",
        number: 23,
        type: .int32,
        oneofIndex: 1
      )
    )

    fileDescriptor.addMessage(complexMessage)
  }

  override func tearDown() {
    fileDescriptor = nil
    messageFactory = nil
    simpleMessage = nil
    complexMessage = nil
    nestedMessage = nil
    enumDescriptor = nil
    super.tearDown()
  }

  // MARK: - Test-DYN-001: Создание сообщений из protodescriptor

  func testCreateEmptyMessageFromDescriptor() {
    // Создание пустого сообщения должно работать как в C++ protobuf
    let message = messageFactory.createMessage(from: simpleMessage)

    XCTAssertEqual(message.descriptor.name, "SimpleMessage")
    XCTAssertEqual(message.descriptor.fullName, "test.creation.SimpleMessage")

    // Все поля должны быть не установлены (поведение proto3)
    XCTAssertFalse(try message.hasValue(forField: "text"))
    XCTAssertFalse(try message.hasValue(forField: "number"))
    XCTAssertFalse(try message.hasValue(forField: "flag"))

    // Получение значений должно возвращать значения по умолчанию
    XCTAssertNil(try message.get(forField: "text"))
    XCTAssertNil(try message.get(forField: "number"))
    XCTAssertNil(try message.get(forField: "flag"))
  }

  func testCreateMessageWithFieldValues() throws {
    // Создание сообщения с предзаполненными значениями (по именам полей)
    let fieldValues: [String: Any] = [
      "text": "Hello World",
      "number": Int32(42),
      "flag": true,
    ]

    let message = try messageFactory.createMessage(from: simpleMessage, with: fieldValues)

    XCTAssertTrue(try message.hasValue(forField: "text"))
    XCTAssertEqual(try message.get(forField: "text") as? String, "Hello World")

    XCTAssertTrue(try message.hasValue(forField: "number"))
    XCTAssertEqual(try message.get(forField: "number") as? Int32, 42)

    XCTAssertTrue(try message.hasValue(forField: "flag"))
    XCTAssertEqual(try message.get(forField: "flag") as? Bool, true)
  }

  func testCreateMessageWithFieldNumbers() throws {
    // Создание сообщения с предзаполненными значениями (по номерам полей)
    let fieldValues: [Int: Any] = [
      1: "Test Message",
      2: Int32(123),
      3: false,
    ]

    let message = try messageFactory.createMessage(from: simpleMessage, with: fieldValues)

    XCTAssertEqual(try message.get(forField: 1) as? String, "Test Message")
    XCTAssertEqual(try message.get(forField: 2) as? Int32, 123)
    XCTAssertEqual(try message.get(forField: 3) as? Bool, false)
  }

  func testCreateMessageErrorHandling() {
    // Тестирование ошибок при создании с некорректными данными
    let invalidFieldValues: [String: Any] = [
      "text": 123,  // Неправильный тип
      "nonexistent": "value",  // Несуществующее поле
    ]

    XCTAssertThrowsError(try messageFactory.createMessage(from: simpleMessage, with: invalidFieldValues))

    let invalidFieldNumbers: [Int: Any] = [
      999: "value"  // Несуществующий номер поля
    ]

    XCTAssertThrowsError(try messageFactory.createMessage(from: simpleMessage, with: invalidFieldNumbers))
  }

  // MARK: - Test-DYN-002: Все типы данных proto3

  func testAllScalarTypesProto3() throws {
    // Создание сообщения со всеми скалярными типами proto3
    let scalarValues: [String: Any] = [
      "double_field": 3.14159,
      "float_field": Float(2.718),
      "int32_field": Int32(-42),
      "int64_field": Int64(-9_223_372_036_854_775_808),
      "uint32_field": UInt32(4_294_967_295),
      "uint64_field": UInt64(18_446_744_073_709_551_615),
      "sint32_field": Int32(-2_147_483_648),
      "sint64_field": Int64(-9_223_372_036_854_775_808),
      "fixed32_field": UInt32(123_456_789),
      "fixed64_field": UInt64(987_654_321_012_345),
      "sfixed32_field": Int32(-123_456_789),
      "sfixed64_field": Int64(-987_654_321_012_345),
      "bool_field": true,
      "string_field": "Protocol Buffers",
      "bytes_field": Data("binary data".utf8),
    ]

    let message = try messageFactory.createMessage(from: complexMessage, with: scalarValues)

    // Проверяем все типы
    XCTAssertEqual(try message.get(forField: "double_field") as? Double ?? 0.0, 3.14159, accuracy: 0.00001)
    XCTAssertEqual(try message.get(forField: "float_field") as? Float ?? 0.0, Float(2.718), accuracy: Float(0.001))
    XCTAssertEqual(try message.get(forField: "int32_field") as? Int32, -42)
    XCTAssertEqual(try message.get(forField: "int64_field") as? Int64, -9_223_372_036_854_775_808)
    XCTAssertEqual(try message.get(forField: "uint32_field") as? UInt32, 4_294_967_295)
    XCTAssertEqual(try message.get(forField: "uint64_field") as? UInt64, 18_446_744_073_709_551_615)
    XCTAssertEqual(try message.get(forField: "sint32_field") as? Int32, -2_147_483_648)
    XCTAssertEqual(try message.get(forField: "sint64_field") as? Int64, -9_223_372_036_854_775_808)
    XCTAssertEqual(try message.get(forField: "fixed32_field") as? UInt32, 123_456_789)
    XCTAssertEqual(try message.get(forField: "fixed64_field") as? UInt64, 987_654_321_012_345)
    XCTAssertEqual(try message.get(forField: "sfixed32_field") as? Int32, -123_456_789)
    XCTAssertEqual(try message.get(forField: "sfixed64_field") as? Int64, -987_654_321_012_345)
    XCTAssertEqual(try message.get(forField: "bool_field") as? Bool, true)
    XCTAssertEqual(try message.get(forField: "string_field") as? String, "Protocol Buffers")
    XCTAssertEqual(try message.get(forField: "bytes_field") as? Data, Data("binary data".utf8))
  }

  func testComplexTypesCreation() throws {
    // Создаем вложенное сообщение
    let nestedMsg = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int64(12345),
        "name": "Nested Object",
      ]
    )

    // Создаем сложное сообщение с вложенными типами
    var complexMsg = messageFactory.createMessage(from: complexMessage)

    // Устанавливаем вложенное сообщение
    try complexMsg.set(nestedMsg, forField: "nested_message")

    // Устанавливаем enum (по номеру и по имени)
    try complexMsg.set(Int32(1), forField: "enum_field")  // ACTIVE

    // Проверяем результат
    let retrievedNested = try complexMsg.get(forField: "nested_message") as? DynamicMessage
    XCTAssertNotNil(retrievedNested)
    XCTAssertEqual(try retrievedNested?.get(forField: "id") as? Int64, 12345)
    XCTAssertEqual(try retrievedNested?.get(forField: "name") as? String, "Nested Object")

    XCTAssertEqual(try complexMsg.get(forField: "enum_field") as? Int32, 1)

    // Тестируем enum по имени
    try complexMsg.set("INACTIVE", forField: "enum_field")
    XCTAssertEqual(try complexMsg.get(forField: "enum_field") as? String, "INACTIVE")
  }

  func testRepeatedFieldsCreation() throws {
    // Создание сообщения с repeated полями
    let strings = ["first", "second", "third"]

    let nestedMsg1 = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int64(1),
        "name": "First",
      ]
    )
    let nestedMsg2 = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int64(2),
        "name": "Second",
      ]
    )

    let messages = [nestedMsg1, nestedMsg2]

    let complexValues: [String: Any] = [
      "repeated_strings": strings,
      "repeated_messages": messages,
    ]

    let message = try messageFactory.createMessage(from: complexMessage, with: complexValues)

    let retrievedStrings = try message.get(forField: "repeated_strings") as? [String]
    XCTAssertEqual(retrievedStrings, strings)

    let retrievedMessages = try message.get(forField: "repeated_messages") as? [DynamicMessage]
    XCTAssertEqual(retrievedMessages?.count, 2)
    XCTAssertEqual(try retrievedMessages?[0].get(forField: "id") as? Int64, 1)
    XCTAssertEqual(try retrievedMessages?[1].get(forField: "name") as? String, "Second")
  }

  func testMapFieldsCreation() throws {
    // Создание сообщения с map полями
    let stringMap = ["key1": "value1", "key2": "value2"]

    let nestedMsg1 = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int64(100),
        "name": "Map Value 1",
      ]
    )
    let nestedMsg2 = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int64(200),
        "name": "Map Value 2",
      ]
    )

    let messageMap = ["msg1": nestedMsg1, "msg2": nestedMsg2]

    let mapValues: [String: Any] = [
      "string_map": stringMap,
      "message_map": messageMap,
    ]

    let message = try messageFactory.createMessage(from: complexMessage, with: mapValues)

    let retrievedStringMap = try message.get(forField: "string_map") as? [String: String]
    XCTAssertEqual(retrievedStringMap?["key1"], "value1")
    XCTAssertEqual(retrievedStringMap?["key2"], "value2")

    let retrievedMessageMap = try message.get(forField: "message_map") as? [String: DynamicMessage]
    XCTAssertEqual(retrievedMessageMap?.count, 2)
    XCTAssertEqual(try retrievedMessageMap?["msg1"]?.get(forField: "id") as? Int64, 100)
    XCTAssertEqual(try retrievedMessageMap?["msg2"]?.get(forField: "name") as? String, "Map Value 2")
  }

  // MARK: - Test-DYN-003: Сложные вложенные структуры

  func testDeepNestedMessageCreation() throws {
    // Создаем глубоко вложенную структуру

    // Уровень 3 (самый глубокий) - простое вложенное сообщение
    let level3 = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int64(3),
        "name": "Level 3",
      ]
    )

    // Уровень 2 - также простое вложенное сообщение, содержащее ссылку на Level 3 в виде строки
    let level2 = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int64(2),
        "name": "Level 2 -> \(try level3.get(forField: "name") as? String ?? "")",
      ]
    )

    // Уровень 1 - сложное сообщение, содержащее Level 2
    var level1 = messageFactory.createMessage(from: complexMessage)
    try level1.set("Level 1", forField: "string_field")
    try level1.set(level2, forField: "nested_message")

    // Проверяем доступ к вложенным данным
    let retrievedLevel2 = try level1.get(forField: "nested_message") as? DynamicMessage
    XCTAssertNotNil(retrievedLevel2)
    XCTAssertEqual(try retrievedLevel2?.get(forField: "id") as? Int64, 2)
    XCTAssertEqual(try retrievedLevel2?.get(forField: "name") as? String, "Level 2 -> Level 3")

    // Создаем еще более сложную структуру с repeated полем вложенных сообщений
    var complexLevel1 = messageFactory.createMessage(from: complexMessage)
    let nestedArray = [level2, level3]
    try complexLevel1.set(nestedArray, forField: "repeated_messages")
    try complexLevel1.set("Complex Level 1", forField: "string_field")

    let retrievedArray = try complexLevel1.get(forField: "repeated_messages") as? [DynamicMessage]
    XCTAssertEqual(retrievedArray?.count, 2)
    XCTAssertEqual(try retrievedArray?[0].get(forField: "id") as? Int64, 2)
    XCTAssertEqual(try retrievedArray?[1].get(forField: "id") as? Int64, 3)
  }

  func testComplexNestedStructureWithAllFieldTypes() throws {
    // Создаем сложную структуру с комбинацией всех типов полей

    // Вложенные сообщения для repeated поля
    let nestedMsg1 = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int64(1),
        "name": "Nested 1",
      ]
    )
    let nestedMsg2 = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int64(2),
        "name": "Nested 2",
      ]
    )

    // Вложенные сообщения для map поля
    let mapNestedMsg1 = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int64(10),
        "name": "Map Nested 1",
      ]
    )
    let mapNestedMsg2 = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int64(20),
        "name": "Map Nested 2",
      ]
    )

    // Основное сообщение для вложения
    let mainNestedMsg = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int64(999),
        "name": "Main Nested",
      ]
    )

    // Создаем комплексное сообщение
    let complexValues: [String: Any] = [
      "double_field": 1.23456789,
      "string_field": "Complex Structure",
      "bool_field": true,
      "nested_message": mainNestedMsg,
      "enum_field": Int32(2),  // INACTIVE
      "repeated_strings": ["a", "b", "c"],
      "repeated_messages": [nestedMsg1, nestedMsg2],
      "string_map": ["key1": "value1", "key2": "value2"],
      "message_map": ["nested1": mapNestedMsg1, "nested2": mapNestedMsg2],
      "option_a": "Oneof option A",  // oneof поле
    ]

    let message = try messageFactory.createMessage(from: complexMessage, with: complexValues)

    // Валидируем результат
    let validationResult = messageFactory.validate(message)
    XCTAssertTrue(validationResult.isValid, "Message should be valid: \(validationResult.errors)")

    // Проверяем все компоненты
    XCTAssertEqual(try message.get(forField: "double_field") as? Double ?? 0.0, 1.23456789, accuracy: 0.000000001)
    XCTAssertEqual(try message.get(forField: "string_field") as? String, "Complex Structure")

    let mainNested = try message.get(forField: "nested_message") as? DynamicMessage
    XCTAssertEqual(try mainNested?.get(forField: "id") as? Int64, 999)

    let repeatedMessages = try message.get(forField: "repeated_messages") as? [DynamicMessage]
    XCTAssertEqual(repeatedMessages?.count, 2)

    let messageMap = try message.get(forField: "message_map") as? [String: DynamicMessage]
    XCTAssertEqual(messageMap?.count, 2)
    XCTAssertEqual(try messageMap?["nested1"]?.get(forField: "id") as? Int64, 10)

    // Проверяем oneof поле
    XCTAssertEqual(try message.get(forField: "option_a") as? String, "Oneof option A")
    XCTAssertFalse(try message.hasValue(forField: "option_b"))
  }

  func testMessageCloning() throws {
    // Тестируем глубокое клонирование сложных структур
    let originalNested = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int64(42),
        "name": "Original",
      ]
    )

    let original = try messageFactory.createMessage(
      from: complexMessage,
      with: [
        "string_field": "Original Message",
        "int32_field": Int32(123),
        "nested_message": originalNested,
        "repeated_strings": ["one", "two"],
        "string_map": ["key": "value"],
      ]
    )

    // Клонируем сообщение
    let cloned = try messageFactory.clone(original)

    // Проверяем, что клон идентичен оригиналу
    XCTAssertEqual(original, cloned)

    // Изменяем клон и проверяем, что оригинал не изменился
    var mutableCloned = cloned
    try mutableCloned.set("Modified Clone", forField: "string_field")

    XCTAssertNotEqual(original, mutableCloned)
    XCTAssertEqual(try original.get(forField: "string_field") as? String, "Original Message")
    XCTAssertEqual(try mutableCloned.get(forField: "string_field") as? String, "Modified Clone")
  }

  func testMessageValidation() throws {
    // Тестируем валидацию сложных структур

    // Создаем валидное сообщение
    let validNested = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int64(1),
        "name": "Valid",
      ]
    )

    let validMessage = try messageFactory.createMessage(
      from: complexMessage,
      with: [
        "string_field": "Valid Message",
        "nested_message": validNested,
      ]
    )

    let validResult = messageFactory.validate(validMessage)
    XCTAssertTrue(validResult.isValid)
    XCTAssertTrue(validResult.errors.isEmpty)

    // Тестируем валидацию с ошибками в вложенных сообщениях
    // (это более сложный случай, который требует специальной настройки дескрипторов)
  }

  // MARK: - Performance Tests

  func testMessageCreationPerformance() {
    // Тестируем производительность создания сообщений
    measure {
      for _ in 0..<1000 {
        let message = messageFactory.createMessage(from: simpleMessage)
        _ = message.descriptor.name  // Используем результат
      }
    }
  }

  func testComplexMessageCreationPerformance() throws {
    // Тестируем производительность создания сложных сообщений
    let nestedMsg = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int64(1),
        "name": "Performance Test",
      ]
    )

    let complexValues: [String: Any] = [
      "string_field": "Performance Test",
      "int32_field": Int32(42),
      "nested_message": nestedMsg,
      "repeated_strings": ["a", "b", "c", "d", "e"],
    ]

    measure {
      for _ in 0..<100 {
        do {
          let message = try messageFactory.createMessage(from: complexMessage, with: complexValues)
          _ = try message.get(forField: "string_field")  // Используем результат
        }
        catch {
          XCTFail("Performance test failed: \(error)")
        }
      }
    }
  }
}
