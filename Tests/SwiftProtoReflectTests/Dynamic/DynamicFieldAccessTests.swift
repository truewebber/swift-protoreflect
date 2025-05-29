//
// DynamicFieldAccessTests.swift
//
// Тесты для проверки доступа к полям динамических Protocol Buffers сообщений
//
// Тестовые случаи из плана:
// - Test-DYN-004: Манипуляция repeated полями (добавление, удаление, изменение элементов)
// - Test-DYN-005: Манипуляция map полями со всеми допустимыми типами ключей и значений
// - Test-DYN-006: Работа с oneof полями (установка, проверка, переключение между вариантами)
// - Test-DYN-007: Обработка enum-значений, включая неизвестные значения

import XCTest

@testable import SwiftProtoReflect

final class DynamicFieldAccessTests: XCTestCase {
  // MARK: - Properties

  private var fileDescriptor: FileDescriptor!
  private var messageFactory: MessageFactory!
  private var testMessage: MessageDescriptor!
  private var nestedMessage: MessageDescriptor!
  private var enumDescriptor: EnumDescriptor!

  // MARK: - Setup

  override func setUp() {
    super.setUp()

    messageFactory = MessageFactory()
    fileDescriptor = FileDescriptor(name: "test_field_access.proto", package: "test.access")

    // Создаем enum для тестирования
    enumDescriptor = EnumDescriptor(name: "Color", parent: fileDescriptor)
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN_COLOR", number: 0))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "RED", number: 1))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "GREEN", number: 2))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "BLUE", number: 3))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "CUSTOM", number: 999))  // Нестандартное значение
    fileDescriptor.addEnum(enumDescriptor)

    // Вложенное сообщение для тестирования
    nestedMessage = MessageDescriptor(name: "NestedItem", parent: fileDescriptor)
    nestedMessage.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    nestedMessage.addField(FieldDescriptor(name: "label", number: 2, type: .string))
    nestedMessage.addField(FieldDescriptor(name: "value", number: 3, type: .double))
    fileDescriptor.addMessage(nestedMessage)

    // Основное сообщение для тестирования всех типов полей
    testMessage = MessageDescriptor(name: "FieldAccessTestMessage", parent: fileDescriptor)

    // Repeated поля всех основных типов
    testMessage.addField(FieldDescriptor(name: "repeated_strings", number: 1, type: .string, isRepeated: true))
    testMessage.addField(FieldDescriptor(name: "repeated_int32", number: 2, type: .int32, isRepeated: true))
    testMessage.addField(FieldDescriptor(name: "repeated_int64", number: 3, type: .int64, isRepeated: true))
    testMessage.addField(FieldDescriptor(name: "repeated_uint32", number: 4, type: .uint32, isRepeated: true))
    testMessage.addField(FieldDescriptor(name: "repeated_uint64", number: 5, type: .uint64, isRepeated: true))
    testMessage.addField(FieldDescriptor(name: "repeated_float", number: 6, type: .float, isRepeated: true))
    testMessage.addField(FieldDescriptor(name: "repeated_double", number: 7, type: .double, isRepeated: true))
    testMessage.addField(FieldDescriptor(name: "repeated_bool", number: 8, type: .bool, isRepeated: true))
    testMessage.addField(FieldDescriptor(name: "repeated_bytes", number: 9, type: .bytes, isRepeated: true))
    testMessage.addField(
      FieldDescriptor(
        name: "repeated_messages",
        number: 10,
        type: .message,
        typeName: "test.access.NestedItem",
        isRepeated: true
      )
    )
    testMessage.addField(
      FieldDescriptor(
        name: "repeated_enums",
        number: 11,
        type: .enum,
        typeName: "test.access.Color",
        isRepeated: true
      )
    )

    // Map поля с различными типами ключей и значений
    // String -> String map
    let stringStringMapEntry = MapEntryInfo(
      keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
      valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .string)
    )
    testMessage.addField(
      FieldDescriptor(
        name: "string_to_string_map",
        number: 20,
        type: .message,
        typeName: "map<string, string>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: stringStringMapEntry
      )
    )

    // Int32 -> String map
    let int32StringMapEntry = MapEntryInfo(
      keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .int32),
      valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .string)
    )
    testMessage.addField(
      FieldDescriptor(
        name: "int32_to_string_map",
        number: 21,
        type: .message,
        typeName: "map<int32, string>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: int32StringMapEntry
      )
    )

    // Int64 -> Int32 map
    let int64Int32MapEntry = MapEntryInfo(
      keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .int64),
      valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .int32)
    )
    testMessage.addField(
      FieldDescriptor(
        name: "int64_to_int32_map",
        number: 22,
        type: .message,
        typeName: "map<int64, int32>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: int64Int32MapEntry
      )
    )

    // UInt32 -> UInt64 map
    let uint32Uint64MapEntry = MapEntryInfo(
      keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .uint32),
      valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .uint64)
    )
    testMessage.addField(
      FieldDescriptor(
        name: "uint32_to_uint64_map",
        number: 23,
        type: .message,
        typeName: "map<uint32, uint64>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: uint32Uint64MapEntry
      )
    )

    // Bool -> Float map
    let boolFloatMapEntry = MapEntryInfo(
      keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .bool),
      valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .float)
    )
    testMessage.addField(
      FieldDescriptor(
        name: "bool_to_float_map",
        number: 24,
        type: .message,
        typeName: "map<bool, float>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: boolFloatMapEntry
      )
    )

    // String -> Message map
    let stringMessageMapEntry = MapEntryInfo(
      keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
      valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .message, typeName: "test.access.NestedItem")
    )
    testMessage.addField(
      FieldDescriptor(
        name: "string_to_message_map",
        number: 25,
        type: .message,
        typeName: "map<string, NestedItem>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: stringMessageMapEntry
      )
    )

    // String -> Enum map
    let stringEnumMapEntry = MapEntryInfo(
      keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
      valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .enum, typeName: "test.access.Color")
    )
    testMessage.addField(
      FieldDescriptor(
        name: "string_to_enum_map",
        number: 26,
        type: .message,
        typeName: "map<string, Color>",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: stringEnumMapEntry
      )
    )

    // Oneof поля с разными типами
    testMessage.addField(FieldDescriptor(name: "oneof_string", number: 30, type: .string, oneofIndex: 1))
    testMessage.addField(FieldDescriptor(name: "oneof_int32", number: 31, type: .int32, oneofIndex: 1))
    testMessage.addField(FieldDescriptor(name: "oneof_bool", number: 32, type: .bool, oneofIndex: 1))
    testMessage.addField(
      FieldDescriptor(
        name: "oneof_message",
        number: 33,
        type: .message,
        typeName: "test.access.NestedItem",
        oneofIndex: 1
      )
    )
    testMessage.addField(
      FieldDescriptor(
        name: "oneof_enum",
        number: 34,
        type: .enum,
        typeName: "test.access.Color",
        oneofIndex: 1
      )
    )

    // Второй oneof для тестирования множественных oneof групп
    testMessage.addField(FieldDescriptor(name: "second_oneof_a", number: 40, type: .string, oneofIndex: 2))
    testMessage.addField(FieldDescriptor(name: "second_oneof_b", number: 41, type: .int64, oneofIndex: 2))

    // Enum поля разных типов
    testMessage.addField(
      FieldDescriptor(
        name: "single_enum",
        number: 50,
        type: .enum,
        typeName: "test.access.Color"
      )
    )
    testMessage.addField(
      FieldDescriptor(
        name: "optional_enum",
        number: 51,
        type: .enum,
        typeName: "test.access.Color",
        isOptional: true
      )
    )

    fileDescriptor.addMessage(testMessage)
  }

  override func tearDown() {
    fileDescriptor = nil
    messageFactory = nil
    testMessage = nil
    nestedMessage = nil
    enumDescriptor = nil
    super.tearDown()
  }

  // MARK: - Test-DYN-004: Манипуляция repeated полями

  func testRepeatedFieldAddition() throws {
    var message = messageFactory.createMessage(from: testMessage)

    // Добавляем элементы в repeated строковое поле
    try message.addRepeatedValue("first", forField: "repeated_strings")
    try message.addRepeatedValue("second", forField: "repeated_strings")
    try message.addRepeatedValue("third", forField: "repeated_strings")

    // Проверяем через FieldAccessor
    let accessor = FieldAccessor(message)
    let strings = accessor.getStringArray("repeated_strings")
    XCTAssertEqual(strings?.count, 3)
    XCTAssertEqual(strings?[0], "first")
    XCTAssertEqual(strings?[1], "second")
    XCTAssertEqual(strings?[2], "third")

    // Добавляем числовые значения
    try message.addRepeatedValue(Int32(10), forField: "repeated_int32")
    try message.addRepeatedValue(Int32(20), forField: "repeated_int32")

    let updatedAccessor = FieldAccessor(message)
    let int32Array = updatedAccessor.getInt32Array("repeated_int32")
    XCTAssertEqual(int32Array?.count, 2)
    XCTAssertEqual(int32Array?[0], 10)
    XCTAssertEqual(int32Array?[1], 20)

    // Добавляем булевы значения
    try message.addRepeatedValue(true, forField: "repeated_bool")
    try message.addRepeatedValue(false, forField: "repeated_bool")
    try message.addRepeatedValue(true, forField: "repeated_bool")

    let boolArray = try message.get(forField: "repeated_bool") as? [Bool]
    XCTAssertEqual(boolArray?.count, 3)
    XCTAssertEqual(boolArray?[0], true)
    XCTAssertEqual(boolArray?[1], false)
    XCTAssertEqual(boolArray?[2], true)
  }

  func testRepeatedFieldReplacement() throws {
    var message = messageFactory.createMessage(from: testMessage)

    // Устанавливаем массив целиком
    let originalStrings = ["a", "b", "c"]
    try message.set(originalStrings, forField: "repeated_strings")

    let accessor = FieldAccessor(message)
    XCTAssertEqual(accessor.getStringArray("repeated_strings"), originalStrings)

    // Заменяем массив новым
    let newStrings = ["x", "y", "z", "w"]
    try message.set(newStrings, forField: "repeated_strings")

    let updatedAccessor = FieldAccessor(message)
    XCTAssertEqual(updatedAccessor.getStringArray("repeated_strings"), newStrings)
    XCTAssertEqual(updatedAccessor.getStringArray("repeated_strings")?.count, 4)
  }

  func testRepeatedFieldClearing() throws {
    var message = messageFactory.createMessage(from: testMessage)

    // Добавляем элементы
    try message.addRepeatedValue(Int64(100), forField: "repeated_int64")
    try message.addRepeatedValue(Int64(200), forField: "repeated_int64")

    let accessor = FieldAccessor(message)
    XCTAssertEqual(accessor.getInt64Array("repeated_int64")?.count, 2)

    // Очищаем поле
    try message.clearField("repeated_int64")

    let clearedAccessor = FieldAccessor(message)
    XCTAssertNil(clearedAccessor.getInt64Array("repeated_int64"))
    XCTAssertFalse(try message.hasValue(forField: "repeated_int64"))
  }

  func testRepeatedMessageFields() throws {
    var message = messageFactory.createMessage(from: testMessage)

    // Создаем вложенные сообщения
    let nested1 = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int32(1),
        "label": "First",
        "value": 1.1,
      ]
    )
    let nested2 = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int32(2),
        "label": "Second",
        "value": 2.2,
      ]
    )

    // Добавляем по одному
    try message.addRepeatedValue(nested1, forField: "repeated_messages")
    try message.addRepeatedValue(nested2, forField: "repeated_messages")

    let accessor = FieldAccessor(message)
    let messages = accessor.getMessageArray("repeated_messages")
    XCTAssertEqual(messages?.count, 2)
    XCTAssertEqual(try messages?[0].get(forField: "id") as? Int32, 1)
    XCTAssertEqual(try messages?[1].get(forField: "label") as? String, "Second")

    // Добавляем еще одно и проверяем, что массив увеличился
    let nested3 = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int32(3),
        "label": "Third",
        "value": 3.3,
      ]
    )
    try message.addRepeatedValue(nested3, forField: "repeated_messages")

    let updatedAccessor = FieldAccessor(message)
    XCTAssertEqual(updatedAccessor.getMessageArray("repeated_messages")?.count, 3)
  }

  func testRepeatedFieldsAllNumericTypes() throws {
    var message = messageFactory.createMessage(from: testMessage)

    // Тестируем все числовые типы
    try message.set([UInt32(1), UInt32(2), UInt32(3)], forField: "repeated_uint32")
    try message.set([UInt64(10), UInt64(20), UInt64(30)], forField: "repeated_uint64")
    try message.set([Float(1.1), Float(2.2), Float(3.3)], forField: "repeated_float")
    try message.set([Double(10.1), Double(20.2), Double(30.3)], forField: "repeated_double")

    let accessor = FieldAccessor(message)

    XCTAssertEqual(accessor.getValue("repeated_uint32", as: [UInt32].self), [1, 2, 3])
    XCTAssertEqual(accessor.getValue("repeated_uint64", as: [UInt64].self), [10, 20, 30])

    let floatArray = accessor.getValue("repeated_float", as: [Float].self)
    XCTAssertEqual(floatArray?.count, 3)
    XCTAssertEqual(floatArray?[0] ?? 0.0, Float(1.1), accuracy: Float(0.01))

    let doubleArray = accessor.getValue("repeated_double", as: [Double].self)
    XCTAssertEqual(doubleArray?.count, 3)
    XCTAssertEqual(doubleArray?[0] ?? 0.0, 10.1, accuracy: 0.01)
  }

  func testRepeatedBytesField() throws {
    var message = messageFactory.createMessage(from: testMessage)

    let data1 = Data("hello".utf8)
    let data2 = Data("world".utf8)
    let data3 = Data([0x01, 0x02, 0x03])

    try message.set([data1, data2, data3], forField: "repeated_bytes")

    let bytesArray = try message.get(forField: "repeated_bytes") as? [Data]
    XCTAssertEqual(bytesArray?.count, 3)
    XCTAssertEqual(bytesArray?[0], data1)
    XCTAssertEqual(bytesArray?[1], data2)
    XCTAssertEqual(bytesArray?[2], data3)
    XCTAssertEqual(String(data: bytesArray?[0] ?? Data(), encoding: .utf8), "hello")
  }

  // MARK: - Test-DYN-005: Манипуляция map полями

  func testMapFieldsAllKeyTypes() throws {
    var message = messageFactory.createMessage(from: testMessage)

    // String -> String map
    try message.setMapEntry("value1", forKey: "key1", inField: "string_to_string_map")
    try message.setMapEntry("value2", forKey: "key2", inField: "string_to_string_map")

    let accessor = FieldAccessor(message)
    let stringMap = accessor.getStringMap("string_to_string_map")
    XCTAssertEqual(stringMap?.count, 2)
    XCTAssertEqual(stringMap?["key1"], "value1")
    XCTAssertEqual(stringMap?["key2"], "value2")

    // Int32 -> String map
    try message.setMapEntry("int32_value1", forKey: Int32(1), inField: "int32_to_string_map")
    try message.setMapEntry("int32_value2", forKey: Int32(2), inField: "int32_to_string_map")

    let int32StringMap = try message.get(forField: "int32_to_string_map") as? [Int32: String]
    XCTAssertEqual(int32StringMap?.count, 2)
    XCTAssertEqual(int32StringMap?[Int32(1)], "int32_value1")
    XCTAssertEqual(int32StringMap?[Int32(2)], "int32_value2")

    // Int64 -> Int32 map
    try message.setMapEntry(Int32(10), forKey: Int64(100), inField: "int64_to_int32_map")
    try message.setMapEntry(Int32(20), forKey: Int64(200), inField: "int64_to_int32_map")

    let int64Int32Map = try message.get(forField: "int64_to_int32_map") as? [Int64: Int32]
    XCTAssertEqual(int64Int32Map?.count, 2)
    XCTAssertEqual(int64Int32Map?[Int64(100)], Int32(10))
    XCTAssertEqual(int64Int32Map?[Int64(200)], Int32(20))

    // UInt32 -> UInt64 map
    try message.setMapEntry(UInt64(1000), forKey: UInt32(10), inField: "uint32_to_uint64_map")
    try message.setMapEntry(UInt64(2000), forKey: UInt32(20), inField: "uint32_to_uint64_map")

    let uint32Uint64Map = try message.get(forField: "uint32_to_uint64_map") as? [UInt32: UInt64]
    XCTAssertEqual(uint32Uint64Map?.count, 2)
    XCTAssertEqual(uint32Uint64Map?[UInt32(10)], UInt64(1000))
    XCTAssertEqual(uint32Uint64Map?[UInt32(20)], UInt64(2000))

    // Bool -> Float map
    try message.setMapEntry(Float(3.14), forKey: true, inField: "bool_to_float_map")
    try message.setMapEntry(Float(2.71), forKey: false, inField: "bool_to_float_map")

    let boolFloatMap = try message.get(forField: "bool_to_float_map") as? [Bool: Float]
    XCTAssertEqual(boolFloatMap?.count, 2)
    XCTAssertEqual(boolFloatMap?[true] ?? 0.0, Float(3.14), accuracy: Float(0.01))
    XCTAssertEqual(boolFloatMap?[false] ?? 0.0, Float(2.71), accuracy: Float(0.01))
  }

  func testMapFieldsWithMessages() throws {
    var message = messageFactory.createMessage(from: testMessage)

    // Создаем вложенные сообщения для map
    let nested1 = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int32(1),
        "label": "Map Value 1",
        "value": 1.23,
      ]
    )
    let nested2 = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int32(2),
        "label": "Map Value 2",
        "value": 4.56,
      ]
    )

    // Добавляем в map по одному
    try message.setMapEntry(nested1, forKey: "first", inField: "string_to_message_map")
    try message.setMapEntry(nested2, forKey: "second", inField: "string_to_message_map")

    let accessor = FieldAccessor(message)
    let messageMap = accessor.getStringToMessageMap("string_to_message_map")
    XCTAssertEqual(messageMap?.count, 2)
    XCTAssertEqual(try messageMap?["first"]?.get(forField: "id") as? Int32, 1)
    XCTAssertEqual(try messageMap?["second"]?.get(forField: "label") as? String, "Map Value 2")

    // Устанавливаем map целиком
    let nested3 = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int32(3),
        "label": "Map Value 3",
        "value": 7.89,
      ]
    )
    let fullMap = ["third": nested3, "fourth": nested1]
    try message.set(fullMap, forField: "string_to_message_map")

    let updatedAccessor = FieldAccessor(message)
    let updatedMap = updatedAccessor.getStringToMessageMap("string_to_message_map")
    XCTAssertEqual(updatedMap?.count, 2)
    XCTAssertEqual(try updatedMap?["third"]?.get(forField: "id") as? Int32, 3)
    XCTAssertEqual(try updatedMap?["fourth"]?.get(forField: "id") as? Int32, 1)
  }

  func testMapFieldsWithEnums() throws {
    var message = messageFactory.createMessage(from: testMessage)

    // Добавляем enum значения в map
    try message.setMapEntry(Int32(1), forKey: "red", inField: "string_to_enum_map")  // RED
    try message.setMapEntry("GREEN", forKey: "green", inField: "string_to_enum_map")  // По имени
    try message.setMapEntry(Int32(3), forKey: "blue", inField: "string_to_enum_map")  // BLUE

    let enumMap = try message.get(forField: "string_to_enum_map") as? [String: Any]
    XCTAssertEqual(enumMap?.count, 3)
    XCTAssertEqual(enumMap?["red"] as? Int32, 1)
    XCTAssertEqual(enumMap?["green"] as? String, "GREEN")
    XCTAssertEqual(enumMap?["blue"] as? Int32, 3)
  }

  func testMapFieldModification() throws {
    var message = messageFactory.createMessage(from: testMessage)

    // Создаем начальный map
    try message.setMapEntry("original", forKey: "key1", inField: "string_to_string_map")
    try message.setMapEntry("value2", forKey: "key2", inField: "string_to_string_map")

    let accessor = FieldAccessor(message)
    XCTAssertEqual(accessor.getStringMap("string_to_string_map")?.count, 2)

    // Изменяем существующий ключ
    try message.setMapEntry("modified", forKey: "key1", inField: "string_to_string_map")

    let updatedAccessor = FieldAccessor(message)
    let updatedMap = updatedAccessor.getStringMap("string_to_string_map")
    XCTAssertEqual(updatedMap?.count, 2)  // Количество не изменилось
    XCTAssertEqual(updatedMap?["key1"], "modified")
    XCTAssertEqual(updatedMap?["key2"], "value2")

    // Добавляем новый ключ
    try message.setMapEntry("new_value", forKey: "key3", inField: "string_to_string_map")

    let finalAccessor = FieldAccessor(message)
    XCTAssertEqual(finalAccessor.getStringMap("string_to_string_map")?.count, 3)
  }

  func testMapFieldClearing() throws {
    var message = messageFactory.createMessage(from: testMessage)

    // Добавляем данные в map
    try message.setMapEntry("value1", forKey: "key1", inField: "string_to_string_map")
    try message.setMapEntry("value2", forKey: "key2", inField: "string_to_string_map")

    let accessor = FieldAccessor(message)
    XCTAssertEqual(accessor.getStringMap("string_to_string_map")?.count, 2)

    // Очищаем map поле
    try message.clearField("string_to_string_map")

    let clearedAccessor = FieldAccessor(message)
    XCTAssertNil(clearedAccessor.getStringMap("string_to_string_map"))
    XCTAssertFalse(try message.hasValue(forField: "string_to_string_map"))
  }

  // MARK: - Test-DYN-006: Работа с oneof полями

  func testOneofFieldSwitching() throws {
    var message = messageFactory.createMessage(from: testMessage)

    // Изначально все oneof поля не установлены
    let initialAccessor = FieldAccessor(message)
    XCTAssertFalse(initialAccessor.hasValue("oneof_string"))
    XCTAssertFalse(initialAccessor.hasValue("oneof_int32"))
    XCTAssertFalse(initialAccessor.hasValue("oneof_bool"))
    XCTAssertFalse(initialAccessor.hasValue("oneof_message"))
    XCTAssertFalse(initialAccessor.hasValue("oneof_enum"))

    // Устанавливаем string вариант
    try message.set("oneof_value", forField: "oneof_string")
    let stringAccessor = FieldAccessor(message)
    XCTAssertTrue(stringAccessor.hasValue("oneof_string"))
    XCTAssertFalse(stringAccessor.hasValue("oneof_int32"))
    XCTAssertEqual(stringAccessor.getString("oneof_string"), "oneof_value")

    // Переключаемся на int32 - должен очистить string
    try message.set(Int32(42), forField: "oneof_int32")
    let updatedAccessor = FieldAccessor(message)
    XCTAssertFalse(updatedAccessor.hasValue("oneof_string"))
    XCTAssertTrue(updatedAccessor.hasValue("oneof_int32"))
    XCTAssertEqual(updatedAccessor.getInt32("oneof_int32"), 42)

    // Переключаемся на bool
    try message.set(true, forField: "oneof_bool")
    let boolAccessor = FieldAccessor(message)
    XCTAssertFalse(boolAccessor.hasValue("oneof_string"))
    XCTAssertFalse(boolAccessor.hasValue("oneof_int32"))
    XCTAssertTrue(boolAccessor.hasValue("oneof_bool"))
    XCTAssertEqual(boolAccessor.getBool("oneof_bool"), true)
  }

  func testOneofFieldWithMessage() throws {
    var message = messageFactory.createMessage(from: testMessage)

    // Создаем вложенное сообщение для oneof
    let nestedMsg = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int32(123),
        "label": "Oneof Message",
        "value": 9.99,
      ]
    )

    // Устанавливаем message вариант
    try message.set(nestedMsg, forField: "oneof_message")

    let accessor = FieldAccessor(message)
    XCTAssertTrue(accessor.hasValue("oneof_message"))
    XCTAssertFalse(accessor.hasValue("oneof_string"))

    let retrievedMessage = accessor.getMessage("oneof_message")
    XCTAssertNotNil(retrievedMessage)
    XCTAssertEqual(try retrievedMessage?.get(forField: "id") as? Int32, 123)
    XCTAssertEqual(try retrievedMessage?.get(forField: "label") as? String, "Oneof Message")

    // Переключаемся на string - должен очистить message
    try message.set("new_string", forField: "oneof_string")

    let switchedAccessor = FieldAccessor(message)
    XCTAssertFalse(switchedAccessor.hasValue("oneof_message"))
    XCTAssertTrue(switchedAccessor.hasValue("oneof_string"))
    XCTAssertEqual(switchedAccessor.getString("oneof_string"), "new_string")
  }

  func testOneofFieldWithEnum() throws {
    var message = messageFactory.createMessage(from: testMessage)

    // Устанавливаем enum вариант по номеру
    try message.set(Int32(2), forField: "oneof_enum")  // GREEN

    let accessor = FieldAccessor(message)
    XCTAssertTrue(accessor.hasValue("oneof_enum"))
    XCTAssertEqual(try message.get(forField: "oneof_enum") as? Int32, 2)

    // Переключаемся на enum по имени
    try message.set("BLUE", forField: "oneof_enum")

    let nameAccessor = FieldAccessor(message)
    XCTAssertTrue(nameAccessor.hasValue("oneof_enum"))
    XCTAssertEqual(try message.get(forField: "oneof_enum") as? String, "BLUE")

    // Переключаемся на другое поле oneof
    try message.set("back_to_string", forField: "oneof_string")

    let finalAccessor = FieldAccessor(message)
    XCTAssertFalse(finalAccessor.hasValue("oneof_enum"))
    XCTAssertTrue(finalAccessor.hasValue("oneof_string"))
  }

  func testMultipleOneofGroups() throws {
    var message = messageFactory.createMessage(from: testMessage)

    // Устанавливаем поля из первой oneof группы
    try message.set("first_group", forField: "oneof_string")

    // Устанавливаем поля из второй oneof группы
    try message.set("second_group", forField: "second_oneof_a")

    let accessor = FieldAccessor(message)
    XCTAssertTrue(accessor.hasValue("oneof_string"))
    XCTAssertTrue(accessor.hasValue("second_oneof_a"))
    XCTAssertEqual(accessor.getString("oneof_string"), "first_group")
    XCTAssertEqual(accessor.getString("second_oneof_a"), "second_group")

    // Переключаем первую группу - вторая не должна измениться
    try message.set(Int32(99), forField: "oneof_int32")

    let switchedAccessor = FieldAccessor(message)
    XCTAssertFalse(switchedAccessor.hasValue("oneof_string"))
    XCTAssertTrue(switchedAccessor.hasValue("oneof_int32"))
    XCTAssertTrue(switchedAccessor.hasValue("second_oneof_a"))  // Не изменилось
    XCTAssertEqual(switchedAccessor.getInt32("oneof_int32"), 99)

    // Переключаем вторую группу - первая не должна измениться
    try message.set(Int64(777), forField: "second_oneof_b")

    let finalAccessor = FieldAccessor(message)
    XCTAssertTrue(finalAccessor.hasValue("oneof_int32"))  // Не изменилось
    XCTAssertFalse(finalAccessor.hasValue("second_oneof_a"))
    XCTAssertTrue(finalAccessor.hasValue("second_oneof_b"))
    XCTAssertEqual(finalAccessor.getValue("second_oneof_b", as: Int64.self), 777)
  }

  func testOneofFieldClearing() throws {
    var message = messageFactory.createMessage(from: testMessage)

    // Устанавливаем oneof поле
    try message.set("test_value", forField: "oneof_string")

    let accessor = FieldAccessor(message)
    XCTAssertTrue(accessor.hasValue("oneof_string"))

    // Очищаем oneof поле
    try message.clearField("oneof_string")

    let clearedAccessor = FieldAccessor(message)
    XCTAssertFalse(clearedAccessor.hasValue("oneof_string"))
    XCTAssertFalse(clearedAccessor.hasValue("oneof_int32"))
    XCTAssertFalse(clearedAccessor.hasValue("oneof_bool"))
  }

  // MARK: - Test-DYN-007: Обработка enum-значений

  func testEnumByNumber() throws {
    var message = messageFactory.createMessage(from: testMessage)

    // Устанавливаем enum значения по номеру
    try message.set(Int32(0), forField: "single_enum")  // UNKNOWN_COLOR
    XCTAssertEqual(try message.get(forField: "single_enum") as? Int32, 0)

    try message.set(Int32(1), forField: "single_enum")  // RED
    XCTAssertEqual(try message.get(forField: "single_enum") as? Int32, 1)

    try message.set(Int32(2), forField: "single_enum")  // GREEN
    XCTAssertEqual(try message.get(forField: "single_enum") as? Int32, 2)

    try message.set(Int32(3), forField: "single_enum")  // BLUE
    XCTAssertEqual(try message.get(forField: "single_enum") as? Int32, 3)

    // Нестандартное значение
    try message.set(Int32(999), forField: "single_enum")  // CUSTOM
    XCTAssertEqual(try message.get(forField: "single_enum") as? Int32, 999)
  }

  func testEnumByName() throws {
    var message = messageFactory.createMessage(from: testMessage)

    // Устанавливаем enum значения по имени
    try message.set("UNKNOWN_COLOR", forField: "single_enum")
    XCTAssertEqual(try message.get(forField: "single_enum") as? String, "UNKNOWN_COLOR")

    try message.set("RED", forField: "single_enum")
    XCTAssertEqual(try message.get(forField: "single_enum") as? String, "RED")

    try message.set("GREEN", forField: "single_enum")
    XCTAssertEqual(try message.get(forField: "single_enum") as? String, "GREEN")

    try message.set("BLUE", forField: "single_enum")
    XCTAssertEqual(try message.get(forField: "single_enum") as? String, "BLUE")

    try message.set("CUSTOM", forField: "single_enum")
    XCTAssertEqual(try message.get(forField: "single_enum") as? String, "CUSTOM")
  }

  func testEnumUnknownValues() throws {
    var message = messageFactory.createMessage(from: testMessage)

    // Тестируем неизвестные номера enum (протобуфы должны их поддерживать)
    try message.set(Int32(42), forField: "single_enum")  // Неизвестное значение
    XCTAssertEqual(try message.get(forField: "single_enum") as? Int32, 42)

    try message.set(Int32(-1), forField: "single_enum")  // Отрицательное значение
    XCTAssertEqual(try message.get(forField: "single_enum") as? Int32, -1)

    try message.set(Int32(1_000_000), forField: "single_enum")  // Очень большое значение
    XCTAssertEqual(try message.get(forField: "single_enum") as? Int32, 1_000_000)

    // Переключение между известным и неизвестным значением
    try message.set(Int32(1), forField: "single_enum")  // RED (известное)
    XCTAssertEqual(try message.get(forField: "single_enum") as? Int32, 1)

    try message.set(Int32(500), forField: "single_enum")  // Неизвестное
    XCTAssertEqual(try message.get(forField: "single_enum") as? Int32, 500)
  }

  func testEnumInRepeatedField() throws {
    var message = messageFactory.createMessage(from: testMessage)

    // Добавляем enum значения в repeated поле по номерам
    try message.addRepeatedValue(Int32(1), forField: "repeated_enums")  // RED
    try message.addRepeatedValue(Int32(2), forField: "repeated_enums")  // GREEN
    try message.addRepeatedValue(Int32(3), forField: "repeated_enums")  // BLUE

    let enumArray = try message.get(forField: "repeated_enums") as? [Int32]
    XCTAssertEqual(enumArray?.count, 3)
    XCTAssertEqual(enumArray?[0], 1)
    XCTAssertEqual(enumArray?[1], 2)
    XCTAssertEqual(enumArray?[2], 3)

    // Добавляем по именам
    try message.addRepeatedValue("UNKNOWN_COLOR", forField: "repeated_enums")
    try message.addRepeatedValue("CUSTOM", forField: "repeated_enums")

    let mixedEnumArray = try message.get(forField: "repeated_enums") as? [Any]
    XCTAssertEqual(mixedEnumArray?.count, 5)
    XCTAssertEqual(mixedEnumArray?[3] as? String, "UNKNOWN_COLOR")
    XCTAssertEqual(mixedEnumArray?[4] as? String, "CUSTOM")

    // Добавляем неизвестное значение
    try message.addRepeatedValue(Int32(777), forField: "repeated_enums")

    let finalEnumArray = try message.get(forField: "repeated_enums") as? [Any]
    XCTAssertEqual(finalEnumArray?.count, 6)
    XCTAssertEqual(finalEnumArray?[5] as? Int32, 777)
  }

  func testEnumValidation() throws {
    var message = messageFactory.createMessage(from: testMessage)

    // Валидные типы должны работать
    XCTAssertNoThrow(try message.set(Int32(1), forField: "single_enum"))
    XCTAssertNoThrow(try message.set("RED", forField: "single_enum"))

    // Невалидные типы должны вызывать ошибку
    XCTAssertThrowsError(try message.set(123.45, forField: "single_enum")) { error in
      XCTAssertTrue(error is DynamicMessageError)
    }

    XCTAssertThrowsError(try message.set(["array"], forField: "single_enum")) { error in
      XCTAssertTrue(error is DynamicMessageError)
    }

    XCTAssertThrowsError(try message.set(Data(), forField: "single_enum")) { error in
      XCTAssertTrue(error is DynamicMessageError)
    }
  }

  func testEnumEquality() throws {
    var message1 = messageFactory.createMessage(from: testMessage)
    var message2 = messageFactory.createMessage(from: testMessage)

    // Устанавливаем одинаковые enum значения разными способами
    try message1.set(Int32(1), forField: "single_enum")  // По номеру
    try message2.set("RED", forField: "single_enum")  // По имени

    // Сообщения НЕ должны быть равны, так как хранятся разные типы
    XCTAssertNotEqual(message1, message2)

    // Устанавливаем одинаковыми способами
    try message1.set(Int32(1), forField: "single_enum")
    try message2.set(Int32(1), forField: "single_enum")
    XCTAssertEqual(message1, message2)

    try message1.set("RED", forField: "single_enum")
    try message2.set("RED", forField: "single_enum")
    XCTAssertEqual(message1, message2)
  }

  // MARK: - Integration Tests

  func testCombinedFieldTypes() throws {
    // Тест интеграции всех типов полей вместе
    var message = messageFactory.createMessage(from: testMessage)

    // Repeated поля
    try message.set(["a", "b", "c"], forField: "repeated_strings")
    try message.set([Int32(1), Int32(2), Int32(3)], forField: "repeated_int32")

    // Map поля
    try message.setMapEntry("map_value", forKey: "map_key", inField: "string_to_string_map")

    // Oneof поля
    try message.set("oneof_value", forField: "oneof_string")
    try message.set("second_oneof_value", forField: "second_oneof_a")

    // Enum поля
    try message.set(Int32(2), forField: "single_enum")  // GREEN
    try message.set([Int32(1), Int32(3)], forField: "repeated_enums")  // RED, BLUE

    // Проверяем через FieldAccessor
    let accessor = FieldAccessor(message)

    XCTAssertEqual(accessor.getStringArray("repeated_strings")?.count, 3)
    XCTAssertEqual(accessor.getInt32Array("repeated_int32")?.count, 3)
    XCTAssertEqual(accessor.getStringMap("string_to_string_map")?["map_key"], "map_value")
    XCTAssertEqual(accessor.getString("oneof_string"), "oneof_value")
    XCTAssertEqual(accessor.getString("second_oneof_a"), "second_oneof_value")
    XCTAssertEqual(try message.get(forField: "single_enum") as? Int32, 2)

    // Валидация всего сообщения
    let validationResult = messageFactory.validate(message)
    XCTAssertTrue(validationResult.isValid, "Combined message should be valid: \(validationResult.errors)")
  }

  // MARK: - Performance Tests

  func testRepeatedFieldPerformance() {
    measure {
      var message = messageFactory.createMessage(from: testMessage)
      for i in 0..<1000 {
        do {
          try message.addRepeatedValue("item_\(i)", forField: "repeated_strings")
        }
        catch {
          XCTFail("Performance test failed: \(error)")
        }
      }

      let accessor = FieldAccessor(message)
      XCTAssertEqual(accessor.getStringArray("repeated_strings")?.count, 1000)
    }
  }

  func testMapFieldPerformance() throws {
    var message = messageFactory.createMessage(from: testMessage)

    measure {
      for i in 0..<1000 {
        do {
          try message.setMapEntry("value_\(i)", forKey: "key_\(i)", inField: "string_to_string_map")
        }
        catch {
          XCTFail("Performance test failed: \(error)")
        }
      }
    }

    let accessor = FieldAccessor(message)
    XCTAssertEqual(accessor.getStringMap("string_to_string_map")?.count, 1000)
  }
}
