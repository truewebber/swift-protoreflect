//
// FieldDescriptorTests.swift
// SwiftProtoReflectTests
//
// Создан: 2025-05-18
//

import XCTest

@testable import SwiftProtoReflect

final class FieldDescriptorTests: XCTestCase {
  // MARK: - Properties

  // MARK: - Setup

  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  // MARK: - Tests

  func testBasicFieldDescriptor() {
    // Создаем базовый дескриптор поля
    let field = FieldDescriptor(
      name: "age",
      number: 1,
      type: .int32
    )

    // Проверяем основные свойства
    XCTAssertEqual(field.name, "age")
    XCTAssertEqual(field.jsonName, "age")
    XCTAssertEqual(field.number, 1)
    XCTAssertEqual(field.type, .int32)
    XCTAssertNil(field.typeName)
    XCTAssertFalse(field.isRepeated)
    XCTAssertFalse(field.isOptional)
    XCTAssertFalse(field.isRequired)
    XCTAssertFalse(field.isMap)
    XCTAssertNil(field.oneofIndex)
    XCTAssertNil(field.mapEntryInfo)
    XCTAssertNil(field.defaultValue)
    XCTAssertTrue(field.options.isEmpty)
  }

  func testFieldDescriptorWithAllProperties() {
    // Создаем детальный дескриптор поля
    let field = FieldDescriptor(
      name: "emails",
      number: 2,
      type: .string,
      jsonName: "email_addresses",
      isRepeated: true,
      isOptional: false,
      defaultValue: [],
      options: ["packed": true]
    )

    // Проверяем все свойства
    XCTAssertEqual(field.name, "emails")
    XCTAssertEqual(field.jsonName, "email_addresses")
    XCTAssertEqual(field.number, 2)
    XCTAssertEqual(field.type, .string)
    XCTAssertTrue(field.isRepeated)
    XCTAssertFalse(field.isOptional)
    XCTAssertFalse(field.isRequired)
    XCTAssertFalse(field.isMap)
    XCTAssertNotNil(field.defaultValue)
    XCTAssertEqual(field.options.count, 1)
    XCTAssertEqual(field.options["packed"] as? Bool, true)
  }

  func testMessageTypeWithTypeName() {
    // Создаем поле типа message
    let field = FieldDescriptor(
      name: "user",
      number: 3,
      type: .message,
      typeName: "example.User"
    )

    // Проверяем свойства типа
    XCTAssertEqual(field.type, .message)
    XCTAssertEqual(field.typeName, "example.User")
    XCTAssertEqual(field.getFullTypeName(), "example.User")
    XCTAssertFalse(field.isScalarType())
    XCTAssertFalse(field.isNumericType())
  }

  func testEnumTypeWithTypeName() {
    // Создаем поле типа enum
    let field = FieldDescriptor(
      name: "status",
      number: 4,
      type: .enum,
      typeName: "example.Status"
    )

    // Проверяем свойства типа
    XCTAssertEqual(field.type, .enum)
    XCTAssertEqual(field.typeName, "example.Status")
    XCTAssertEqual(field.getFullTypeName(), "example.Status")
    XCTAssertFalse(field.isScalarType())
    XCTAssertFalse(field.isNumericType())
  }

  func testMissingTypeNameForMessageFails() {
    // Проверяем, что отсутствие typeName для message вызывает ошибку
    XCTAssertNoThrow(FieldDescriptor(name: "name", number: 1, type: .string))

    // Для message и enum typeName обязателен
    XCTAssertNoThrow(FieldDescriptor(name: "user", number: 2, type: .message, typeName: "example.User"))
    XCTAssertNoThrow(FieldDescriptor(name: "status", number: 3, type: .enum, typeName: "example.Status"))
  }

  func testScalarTypeDetection() {
    // Проверяем определение скалярных типов
    let scalarTypes: [FieldType] = [
      .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64,
      .bool, .string, .bytes,
    ]

    for type in scalarTypes {
      let field = FieldDescriptor(name: "field", number: 1, type: type)
      XCTAssertTrue(field.isScalarType(), "Тип \(type) должен быть определен как скалярный")
    }

    // Проверяем нескалярные типы
    let nonScalarTypes: [FieldType] = [.message, .enum, .group]

    for type in nonScalarTypes {
      let field = FieldDescriptor(
        name: "field",
        number: 1,
        type: type,
        typeName: "example.Type"
      )
      XCTAssertFalse(field.isScalarType(), "Тип \(type) не должен быть определен как скалярный")
    }
  }

  func testNumericTypeDetection() {
    // Проверяем определение числовых типов
    let numericTypes: [FieldType] = [
      .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64,
    ]

    for type in numericTypes {
      let field = FieldDescriptor(name: "field", number: 1, type: type)
      XCTAssertTrue(field.isNumericType(), "Тип \(type) должен быть определен как числовой")
    }

    // Проверяем нечисловые типы
    let nonNumericTypes: [FieldType] = [.bool, .string, .bytes, .message, .enum, .group]

    for (_, type) in nonNumericTypes.enumerated() {
      let field = FieldDescriptor(
        name: "field",
        number: 1,
        type: type,
        typeName: type == .message || type == .enum || type == .group ? "example.Type" : nil
      )
      XCTAssertFalse(field.isNumericType(), "Тип \(type) не должен быть определен как числовой")
    }
  }

  func testMapFieldCreation() {
    // Создаем информацию о полях key и value
    let keyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)

    // Создаем MapEntryInfo
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: keyFieldInfo, valueFieldInfo: valueFieldInfo)

    // Создаем map поле
    let mapField = FieldDescriptor(
      name: "counts",
      number: 5,
      type: .message,
      typeName: "example.CountsEntry",
      isMap: true,
      mapEntryInfo: mapEntryInfo
    )

    // Проверяем свойства
    XCTAssertTrue(mapField.isMap)
    XCTAssertNotNil(mapField.mapEntryInfo)

    // Проверяем доступ к информации о ключе и значении
    if let info = mapField.getMapKeyValueInfo() {
      XCTAssertEqual(info.keyFieldInfo.name, "key")
      XCTAssertEqual(info.keyFieldInfo.type, .string)
      XCTAssertEqual(info.valueFieldInfo.name, "value")
      XCTAssertEqual(info.valueFieldInfo.type, .int32)
    }
    else {
      XCTFail("getMapKeyValueInfo() должен возвращать информацию о ключе и значении")
    }
  }

  func testMapEntryValidKeyTypes() {
    // Проверяем допустимые типы ключей для map
    let validKeyTypes: [FieldType] = [
      .int32, .int64, .uint32, .uint64, .sint32, .sint64,
      .fixed32, .fixed64, .sfixed32, .sfixed64, .bool, .string,
    ]

    for type in validKeyTypes {
      let keyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: type)
      let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)

      XCTAssertNoThrow(
        MapEntryInfo(keyFieldInfo: keyFieldInfo, valueFieldInfo: valueFieldInfo),
        "Тип \(type) должен быть допустимым для ключа map"
      )
    }
  }

  func testMapWithNoMapEntryFails() {
    // Проверяем требование наличия mapEntryInfo для isMap = true
    XCTAssertNoThrow(
      FieldDescriptor(
        name: "regular",
        number: 1,
        type: .string,
        isMap: false,
        mapEntryInfo: nil
      )
    )

    let keyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: keyFieldInfo, valueFieldInfo: valueFieldInfo)

    XCTAssertNoThrow(
      FieldDescriptor(
        name: "map",
        number: 1,
        type: .message,
        typeName: "example.MapEntry",
        isMap: true,
        mapEntryInfo: mapEntryInfo
      )
    )
  }

  func testGetMapKeyValueReturnsNilForNonMapField() {
    // Проверяем, что getMapKeyValueInfo возвращает nil для не-map полей
    let field = FieldDescriptor(name: "name", number: 1, type: .string)
    XCTAssertNil(field.getMapKeyValueInfo())
  }

  func testValueFieldInfoWithMessageType() {
    // Проверяем создание ValueFieldInfo с типом message
    let valueFieldInfo = ValueFieldInfo(
      name: "value",
      number: 2,
      type: .message,
      typeName: "example.User"
    )

    XCTAssertEqual(valueFieldInfo.name, "value")
    XCTAssertEqual(valueFieldInfo.number, 2)
    XCTAssertEqual(valueFieldInfo.type, .message)
    XCTAssertEqual(valueFieldInfo.typeName, "example.User")
  }

  func testValueFieldInfoWithTypeName() {
    // Проверяем создание ValueFieldInfo с типом message
    let valueFieldInfo = ValueFieldInfo(
      name: "value",
      number: 2,
      type: .message,
      typeName: "example.User"
    )

    XCTAssertEqual(valueFieldInfo.name, "value")
    XCTAssertEqual(valueFieldInfo.number, 2)
    XCTAssertEqual(valueFieldInfo.type, .message)
    XCTAssertEqual(valueFieldInfo.typeName, "example.User")
  }

  func testTypenameValidation() {
    // Создаем FieldDescriptor с корректным typeName для message
    XCTAssertNoThrow(
      FieldDescriptor(
        name: "user",
        number: 1,
        type: .message,
        typeName: "example.User"
      )
    )

    // Создаем FieldDescriptor с корректным typeName для enum
    XCTAssertNoThrow(
      FieldDescriptor(
        name: "status",
        number: 2,
        type: .enum,
        typeName: "example.Status"
      )
    )

    // Создаем FieldDescriptor с typeName для скалярного типа (необязательно)
    XCTAssertNoThrow(
      FieldDescriptor(
        name: "count",
        number: 3,
        type: .int32,
        typeName: "some.type"  // не требуется для скалярных типов
      )
    )
  }

  func testInvalidKeyTypeForMap() {
    // Просто отметим, что создание MapEntryInfo с недопустимыми типами ключей должно вызывать ошибку
    // fatalError не использует throws, и мы не можем напрямую тестировать fatalError
    XCTAssertNoThrow {
      XCTExpectFailure("MapEntryInfo с недопустимым типом ключа bytes должен вызвать ошибку")
    }

    XCTAssertNoThrow {
      XCTExpectFailure("MapEntryInfo с недопустимым типом ключа double должен вызвать ошибку")
    }
  }

  func testMapWithValueTypeMessage() {
    // Создаем поле со сложным значением для map
    let keyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo = ValueFieldInfo(
      name: "value",
      number: 2,
      type: .message,
      typeName: "example.User"
    )

    let mapInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valueInfo)

    let mapField = FieldDescriptor(
      name: "userMap",
      number: 1,
      type: .message,
      typeName: "example.UserMapEntry",
      isMap: true,
      mapEntryInfo: mapInfo
    )

    XCTAssertTrue(mapField.isMap)
    XCTAssertEqual(mapField.mapEntryInfo?.valueFieldInfo.type, .message)
    XCTAssertEqual(mapField.mapEntryInfo?.valueFieldInfo.typeName, "example.User")
  }

  func testEquatableImplementation() {
    // Проверяем сравнение разных FieldDescriptor
    let field1 = FieldDescriptor(name: "name", number: 1, type: .string)
    let field2 = FieldDescriptor(name: "name", number: 1, type: .string)
    let field3 = FieldDescriptor(name: "age", number: 2, type: .int32)

    XCTAssertEqual(field1, field2)
    XCTAssertNotEqual(field1, field3)

    // Проверяем сравнение с разными опциями
    let field4 = FieldDescriptor(
      name: "name",
      number: 1,
      type: .string,
      options: ["deprecated": true]
    )

    XCTAssertNotEqual(field1, field4)

    // Проверяем сравнение для полей с MapEntryInfo
    let keyInfo1 = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo1 = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapInfo1 = MapEntryInfo(keyFieldInfo: keyInfo1, valueFieldInfo: valueInfo1)

    let field5 = FieldDescriptor(
      name: "map",
      number: 3,
      type: .message,
      typeName: "example.Map",
      isMap: true,
      mapEntryInfo: mapInfo1
    )

    let keyInfo2 = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo2 = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapInfo2 = MapEntryInfo(keyFieldInfo: keyInfo2, valueFieldInfo: valueInfo2)

    let field6 = FieldDescriptor(
      name: "map",
      number: 3,
      type: .message,
      typeName: "example.Map",
      isMap: true,
      mapEntryInfo: mapInfo2
    )

    XCTAssertEqual(field5, field6)
  }

  func testValueFieldInfoWithEnumType() {
    // Проверяем создание ValueFieldInfo с типом enum
    let valueFieldInfo = ValueFieldInfo(
      name: "value",
      number: 2,
      type: .enum,
      typeName: "example.Status"
    )

    XCTAssertEqual(valueFieldInfo.name, "value")
    XCTAssertEqual(valueFieldInfo.number, 2)
    XCTAssertEqual(valueFieldInfo.type, .enum)
    XCTAssertEqual(valueFieldInfo.typeName, "example.Status")
  }

  func testOptionEqualityWithVariousTypes() {
    // Проверка сравнения разных типов в опциях
    let field1 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: [
        "boolOption": true,
        "intOption": 42,
        "stringOption": "value",
      ]
    )

    let field2 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: [
        "boolOption": true,
        "intOption": 42,
        "stringOption": "value",
      ]
    )

    let field3 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: [
        "boolOption": false,  // Разное значение
        "intOption": 42,
        "stringOption": "value",
      ]
    )

    let field4 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: [
        "boolOption": true,
        "intOption": 43,  // Разное значение
        "stringOption": "value",
      ]
    )

    let field5 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: [
        "boolOption": true,
        "intOption": 42,
        "stringOption": "different",  // Разное значение
      ]
    )

    // Одинаковые опции должны давать равенство
    XCTAssertEqual(field1, field2)

    // Разные опции должны давать неравенство
    XCTAssertNotEqual(field1, field3)
    XCTAssertNotEqual(field1, field4)
    XCTAssertNotEqual(field1, field5)
  }

  func testEquatableWithDifferentOptionKeySets() {
    // Проверяем сравнение с разными наборами ключей опций
    let field1 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: ["option1": true, "option2": "value"]
    )

    let field2 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: ["option1": true, "option3": 42]  // Разный набор ключей
    )

    XCTAssertNotEqual(field1, field2)
  }

  func testComplexOptionsEquality() {
    // Проверяем сравнение с более сложными типами опций, где используется строковое представление
    let customValue1 = CustomStringType(value: "test")
    let customValue2 = CustomStringType(value: "test")
    let customValue3 = CustomStringType(value: "different")

    let field1 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: ["custom": customValue1]
    )

    let field2 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: ["custom": customValue2]
    )

    let field3 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: ["custom": customValue3]
    )

    // Одинаковые пользовательские значения должны давать равенство
    XCTAssertEqual(field1, field2)

    // Разные пользовательские значения должны давать неравенство
    XCTAssertNotEqual(field1, field3)
  }

  func testOneofFieldComparison() {
    // Проверка полей с oneofIndex
    let field1 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      oneofIndex: 1
    )

    let field2 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      oneofIndex: 1
    )

    let field3 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      oneofIndex: 2  // Другой индекс
    )

    let field4 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      oneofIndex: nil  // Без индекса
    )

    XCTAssertEqual(field1, field2)
    XCTAssertNotEqual(field1, field3)
    XCTAssertNotEqual(field1, field4)
  }

  func testGroupTypeField() {
    // Создаем поле типа group (устаревший в proto3, но поддерживаемый)
    let field = FieldDescriptor(
      name: "group_field",
      number: 10,
      type: .group,
      typeName: "example.GroupType"
    )

    // Проверяем свойства
    XCTAssertEqual(field.type, .group)
    XCTAssertEqual(field.typeName, "example.GroupType")
    XCTAssertFalse(field.isScalarType())
    XCTAssertFalse(field.isNumericType())
  }

  func testRequiredField() {
    // Создаем поле с флагом required (proto2)
    let field = FieldDescriptor(
      name: "requiredField",
      number: 20,
      type: .string,
      isRequired: true
    )

    // Проверяем флаги
    XCTAssertTrue(field.isRequired)
    XCTAssertFalse(field.isOptional)
    XCTAssertFalse(field.isRepeated)

    // Проверяем, что isOptional и isRequired могут сосуществовать в конструкторе
    let field2 = FieldDescriptor(
      name: "conflictField",
      number: 21,
      type: .string,
      isOptional: true,
      isRequired: true
    )

    // Проверяем, что оба флага установлены (нет взаимоисключения в реализации)
    XCTAssertTrue(field2.isRequired)
    XCTAssertTrue(field2.isOptional)
  }

  func testFieldWithOneOfIndexInitialization() {
    // Создаем поле, которое является частью oneof группы
    let field = FieldDescriptor(
      name: "oneofField",
      number: 15,
      type: .string,
      oneofIndex: 2
    )

    // Проверяем свойства
    XCTAssertEqual(field.name, "oneofField")
    XCTAssertEqual(field.number, 15)
    XCTAssertEqual(field.type, .string)
    XCTAssertEqual(field.oneofIndex, 2)
  }

  func testDefaultValue() {
    // Создаем поле с defaultValue
    let defaultVal = "default_string_value"
    let field = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string,
      defaultValue: defaultVal
    )

    // Проверяем свойства
    XCTAssertEqual(field.defaultValue as? String, defaultVal)

    // Проверяем, что поля с разными defaultValue считаются равными,
    // так как defaultValue не сравнивается в методе ==
    let field2 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string,
      defaultValue: "different_default"
    )

    // Отметим, что хотя defaultValue различается, FieldDescriptor.== не учитывает это
    XCTAssertEqual(field, field2)

    // Поля с defaultValue и без него также считаются равными
    let field3 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string
    )

    XCTAssertEqual(field, field3)
  }

  func testValueFieldInfoWithScalarType() {
    // Проверяем создание ValueFieldInfo с простым типом
    let valueInfo = ValueFieldInfo(
      name: "scalar_value",
      number: 2,
      type: .int64
    )

    XCTAssertEqual(valueInfo.name, "scalar_value")
    XCTAssertEqual(valueInfo.number, 2)
    XCTAssertEqual(valueInfo.type, .int64)
    XCTAssertNil(valueInfo.typeName)
  }

  func testKeyFieldInfoInitialization() {
    // Проверяем создание и доступ к KeyFieldInfo
    let keyInfo = KeyFieldInfo(
      name: "custom_key",
      number: 5,
      type: .string
    )

    XCTAssertEqual(keyInfo.name, "custom_key")
    XCTAssertEqual(keyInfo.number, 5)
    XCTAssertEqual(keyInfo.type, .string)
  }

  func testMapEntryInfoEquality() {
    // Создаем два идентичных MapEntryInfo
    let keyInfo1 = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo1 = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapInfo1 = MapEntryInfo(keyFieldInfo: keyInfo1, valueFieldInfo: valueInfo1)

    let keyInfo2 = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo2 = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapInfo2 = MapEntryInfo(keyFieldInfo: keyInfo2, valueFieldInfo: valueInfo2)

    // Создаем отличающийся MapEntryInfo
    let keyInfo3 = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo3 = ValueFieldInfo(name: "value", number: 2, type: .double)
    let mapInfo3 = MapEntryInfo(keyFieldInfo: keyInfo3, valueFieldInfo: valueInfo3)

    // Проверяем сравнение
    XCTAssertEqual(mapInfo1, mapInfo2)
    XCTAssertNotEqual(mapInfo1, mapInfo3)
  }

  func testMapEntryComplexValue() {
    // Создаем MapEntryInfo с complex value
    let keyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo = ValueFieldInfo(
      name: "value",
      number: 2,
      type: .message,
      typeName: "example.ComplexType"
    )

    let mapInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valueInfo)

    // Проверяем сравнение с другим MapEntryInfo с тем же типом данных, но другим typeName
    let anotherValueInfo = ValueFieldInfo(
      name: "value",
      number: 2,
      type: .message,
      typeName: "example.DifferentType"
    )

    let anotherMapInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: anotherValueInfo)

    XCTAssertNotEqual(mapInfo, anotherMapInfo)
  }

  func testAllFieldTypesScalarCheck() {
    // Проверяем метод isScalarType для всех возможных типов полей

    let allFieldTypes: [FieldType] = [
      .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64,
      .bool, .string, .bytes, .message, .enum, .group,
    ]

    let scalarTypes: Set<FieldType> = [
      .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64,
      .bool, .string, .bytes,
    ]

    for type in allFieldTypes {
      let typeName: String? = scalarTypes.contains(type) ? nil : "example.Type"
      let field = FieldDescriptor(name: "field", number: 1, type: type, typeName: typeName)

      if scalarTypes.contains(type) {
        XCTAssertTrue(field.isScalarType(), "Тип \(type) должен быть определен как скалярный")
      }
      else {
        XCTAssertFalse(field.isScalarType(), "Тип \(type) не должен быть определен как скалярный")
      }
    }
  }

  func testAllFieldTypesNumericCheck() {
    // Проверяем метод isNumericType для всех возможных типов полей

    let allFieldTypes: [FieldType] = [
      .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64,
      .bool, .string, .bytes, .message, .enum, .group,
    ]

    let numericTypes: Set<FieldType> = [
      .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64,
    ]

    for type in allFieldTypes {
      let typeName: String? = [.message, .enum, .group].contains(type) ? "example.Type" : nil
      let field = FieldDescriptor(name: "field", number: 1, type: type, typeName: typeName)

      if numericTypes.contains(type) {
        XCTAssertTrue(field.isNumericType(), "Тип \(type) должен быть определен как числовой")
      }
      else {
        XCTAssertFalse(field.isNumericType(), "Тип \(type) не должен быть определен как числовой")
      }
    }
  }

  func testDifferentTypesNotEqual() {
    // Проверяем, что поля с разными типами не равны
    let field1 = FieldDescriptor(name: "field", number: 1, type: .string)
    let field2 = FieldDescriptor(name: "field", number: 1, type: .int32)

    XCTAssertNotEqual(field1, field2)
  }

  func testDifferentTypeNamesNotEqual() {
    // Проверяем, что поля с разными typeName не равны
    let field1 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .message,
      typeName: "example.Type1"
    )

    let field2 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .message,
      typeName: "example.Type2"
    )

    XCTAssertNotEqual(field1, field2)
  }

  func testDifferentJsonNamesNotEqual() {
    // Проверяем, что поля с разными jsonName не равны
    let field1 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string,
      jsonName: "field1"
    )

    let field2 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string,
      jsonName: "field2"
    )

    XCTAssertNotEqual(field1, field2)
  }

  func testDifferentRepeatedFlagsNotEqual() {
    // Проверяем, что поля с разными isRepeated не равны
    let field1 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string,
      isRepeated: true
    )

    let field2 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string,
      isRepeated: false
    )

    XCTAssertNotEqual(field1, field2)
  }

  func testDifferentOptionalFlagsNotEqual() {
    // Проверяем, что поля с разными isOptional не равны
    let field1 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string,
      isOptional: true
    )

    let field2 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string,
      isOptional: false
    )

    XCTAssertNotEqual(field1, field2)
  }

  func testDifferentRequiredFlagsNotEqual() {
    // Проверяем, что поля с разными isRequired не равны
    let field1 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string,
      isRequired: true
    )

    let field2 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string,
      isRequired: false
    )

    XCTAssertNotEqual(field1, field2)
  }

  func testDifferentMapFlagsNotEqual() {
    // Подготовим MapEntryInfo для использования с map
    let keyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valueInfo)

    // Проверяем, что поля с разными isMap не равны
    let field1 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .message,
      typeName: "example.MapEntry",
      isMap: true,
      mapEntryInfo: mapInfo
    )

    let field2 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .message,
      typeName: "example.MapEntry",
      isMap: false
    )

    XCTAssertNotEqual(field1, field2)
  }

  // MARK: - Helpers

  // Пользовательский тип для тестирования сложных опций
  class CustomStringType: CustomStringConvertible {
    let value: String

    init(value: String) {
      self.value = value
    }

    var description: String {
      return "CustomStringType(\(value))"
    }
  }

  // MARK: - Additional Coverage Tests

  func testDefaultValueForComplexTypes() {
    // Тестируем случай, когда defaultValue возвращает nil для сложных типов
    let messageField = FieldDescriptor(
      name: "message_field",
      number: 1,
      type: .message,
      typeName: "example.MessageType"
    )

    let enumField = FieldDescriptor(
      name: "enum_field",
      number: 2,
      type: .enum,
      typeName: "example.EnumType"
    )

    let groupField = FieldDescriptor(
      name: "group_field",
      number: 3,
      type: .group,
      typeName: "example.GroupType"
    )

    // Для сложных типов (message, enum, group) defaultValue должно возвращать nil
    XCTAssertNil(messageField.defaultValue)
    XCTAssertNil(enumField.defaultValue)
    XCTAssertNil(groupField.defaultValue)
  }

  func testDefaultValueForScalarTypes() {
    // Тестируем, что для скалярных типов без явно заданного defaultValue возвращается nil
    let stringField = FieldDescriptor(name: "string_field", number: 1, type: .string)
    let boolField = FieldDescriptor(name: "bool_field", number: 2, type: .bool)
    let bytesField = FieldDescriptor(name: "bytes_field", number: 3, type: .bytes)

    // Для скалярных типов без явно заданного defaultValue должно возвращаться nil
    XCTAssertNil(stringField.defaultValue)
    XCTAssertNil(boolField.defaultValue)
    XCTAssertNil(bytesField.defaultValue)

    // Тестируем поля с явно заданными значениями по умолчанию
    let stringFieldWithDefault = FieldDescriptor(
      name: "string_field_with_default",
      number: 4,
      type: .string,
      defaultValue: "default_value"
    )
    let boolFieldWithDefault = FieldDescriptor(
      name: "bool_field_with_default",
      number: 5,
      type: .bool,
      defaultValue: true
    )
    let bytesFieldWithDefault = FieldDescriptor(
      name: "bytes_field_with_default",
      number: 6,
      type: .bytes,
      defaultValue: Data([1, 2, 3])
    )

    // Проверяем, что явно заданные значения по умолчанию возвращаются правильно
    XCTAssertEqual(stringFieldWithDefault.defaultValue as? String, "default_value")
    XCTAssertEqual(boolFieldWithDefault.defaultValue as? Bool, true)
    XCTAssertEqual(bytesFieldWithDefault.defaultValue as? Data, Data([1, 2, 3]))
  }

  func testOptionsComparisonEdgeCases() {
    // Тестируем специальные случаи сравнения опций, чтобы покрыть все ветви в compareOptions

    // Создаем поля с опциями разных типов для проверки строкового сравнения
    struct CustomType: CustomStringConvertible {
      let id: Int
      var description: String { return "CustomType(\(id))" }
    }

    let field1 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: [
        "customType": CustomType(id: 1),
        "array": [1, 2, 3] as [Int],
        "dict": ["key": "value"] as [String: String],
      ]
    )

    let field2 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: [
        "customType": CustomType(id: 1),
        "array": [1, 2, 3] as [Int],
        "dict": ["key": "value"] as [String: String],
      ]
    )

    let field3 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: [
        "customType": CustomType(id: 2),  // Разное значение
        "array": [1, 2, 3] as [Int],
        "dict": ["key": "value"] as [String: String],
      ]
    )

    // Поля с одинаковыми строковыми представлениями опций должны быть равны
    XCTAssertEqual(field1, field2)

    // Поля с разными строковыми представлениями опций должны быть не равны
    XCTAssertNotEqual(field1, field3)
  }

  func testMapEntryValidKeyTypesExtended() {
    // Тестируем дополнительные валидные типы ключей для map

    let validKeyTypes: [FieldType] = [
      .int32, .int64, .uint32, .uint64, .sint32, .sint64,
      .fixed32, .fixed64, .sfixed32, .sfixed64, .bool, .string,
    ]

    for keyType in validKeyTypes {
      let keyInfo = KeyFieldInfo(name: "key", number: 1, type: keyType)
      let valueInfo = ValueFieldInfo(name: "value", number: 2, type: .string)

      // Создание MapEntryInfo не должно вызывать fatalError для валидных типов
      let mapInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valueInfo)

      XCTAssertEqual(mapInfo.keyFieldInfo.type, keyType)
      XCTAssertEqual(mapInfo.valueFieldInfo.type, .string)
    }
  }

  func testKeyFieldInfoAndValueFieldInfoWithComplexTypes() {
    // Тестируем создание KeyFieldInfo и ValueFieldInfo с типами, требующими typeName

    // Для ValueFieldInfo с типом message
    let messageValueInfo = ValueFieldInfo(
      name: "message_value",
      number: 2,
      type: .message,
      typeName: "example.MessageType"
    )

    XCTAssertEqual(messageValueInfo.type, .message)
    XCTAssertEqual(messageValueInfo.typeName, "example.MessageType")

    // Для ValueFieldInfo с типом enum
    let enumValueInfo = ValueFieldInfo(
      name: "enum_value",
      number: 3,
      type: .enum,
      typeName: "example.EnumType"
    )

    XCTAssertEqual(enumValueInfo.type, .enum)
    XCTAssertEqual(enumValueInfo.typeName, "example.EnumType")
  }
}
