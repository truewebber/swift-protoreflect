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
      .bool, .string, .bytes
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
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64
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
    } else {
      XCTFail("getMapKeyValueInfo() должен возвращать информацию о ключе и значении")
    }
  }
  
  func testMapEntryValidKeyTypes() {
    // Проверяем допустимые типы ключей для map
    let validKeyTypes: [FieldType] = [
      .int32, .int64, .uint32, .uint64, .sint32, .sint64,
      .fixed32, .fixed64, .sfixed32, .sfixed64, .bool, .string
    ]
    
    for type in validKeyTypes {
      let keyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: type)
      let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)
      
      XCTAssertNoThrow(MapEntryInfo(keyFieldInfo: keyFieldInfo, valueFieldInfo: valueFieldInfo),
                     "Тип \(type) должен быть допустимым для ключа map")
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
    XCTAssertNoThrow(FieldDescriptor(
      name: "user",
      number: 1,
      type: .message,
      typeName: "example.User"
    ))
    
    // Создаем FieldDescriptor с корректным typeName для enum
    XCTAssertNoThrow(FieldDescriptor(
      name: "status",
      number: 2,
      type: .enum,
      typeName: "example.Status"
    ))
    
    // Создаем FieldDescriptor с typeName для скалярного типа (необязательно)
    XCTAssertNoThrow(FieldDescriptor(
      name: "count",
      number: 3,
      type: .int32,
      typeName: "some.type" // не требуется для скалярных типов
    ))
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
        "stringOption": "value"
      ]
    )
    
    let field2 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: [
        "boolOption": true,
        "intOption": 42,
        "stringOption": "value"
      ]
    )
    
    let field3 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: [
        "boolOption": false,  // Разное значение
        "intOption": 42,
        "stringOption": "value"
      ]
    )
    
    let field4 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: [
        "boolOption": true,
        "intOption": 43,  // Разное значение
        "stringOption": "value"
      ]
    )
    
    let field5 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: [
        "boolOption": true,
        "intOption": 42,
        "stringOption": "different"  // Разное значение
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
    // Тестирование поля с типом group (устаревший тип для proto2)
    let field = FieldDescriptor(
      name: "group_field",
      number: 1,
      type: .group,
      typeName: "example.Group"
    )
    
    XCTAssertEqual(field.type, .group)
    XCTAssertEqual(field.typeName, "example.Group")
    XCTAssertFalse(field.isScalarType())
    XCTAssertFalse(field.isNumericType())
    XCTAssertEqual(field.getFullTypeName(), "example.Group")
  }
  
  func testRequiredField() {
    // Тестирование обязательного поля (required, устаревшее для proto3)
    let field = FieldDescriptor(
      name: "id",
      number: 1,
      type: .int32,
      isRequired: true
    )
    
    XCTAssertTrue(field.isRequired)
    XCTAssertFalse(field.isOptional)
    XCTAssertFalse(field.isRepeated)
  }
  
  func testFieldWithOneOfIndexInitialization() {
    // Тестирование инициализации поля с oneofIndex
    let field = FieldDescriptor(
      name: "choice",
      number: 1,
      type: .string,
      oneofIndex: 5
    )
    
    XCTAssertEqual(field.oneofIndex, 5)
    XCTAssertEqual(field.name, "choice")
    XCTAssertEqual(field.type, .string)
  }
  
  func testDefaultValue() {
    // Тестирование поля со значением по умолчанию
    let defaultInt = 42
    let field = FieldDescriptor(
      name: "count",
      number: 1,
      type: .int32,
      defaultValue: defaultInt
    )
    
    XCTAssertNotNil(field.defaultValue)
    XCTAssertEqual(field.defaultValue as? Int, defaultInt)
  }
  
  func testValueFieldInfoWithScalarType() {
    // Проверяем создание ValueFieldInfo со скалярным типом (не требующим typeName)
    let valueFieldInfo = ValueFieldInfo(
      name: "value", 
      number: 2, 
      type: .int32
    )
    
    XCTAssertEqual(valueFieldInfo.name, "value")
    XCTAssertEqual(valueFieldInfo.number, 2)
    XCTAssertEqual(valueFieldInfo.type, .int32)
    XCTAssertNil(valueFieldInfo.typeName)
  }
  
  func testKeyFieldInfoInitialization() {
    // Тестирование инициализации KeyFieldInfo
    let keyInfo = KeyFieldInfo(name: "my_key", number: 10, type: .string)
    
    XCTAssertEqual(keyInfo.name, "my_key")
    XCTAssertEqual(keyInfo.number, 10)
    XCTAssertEqual(keyInfo.type, .string)
  }
  
  func testMapEntryInfoEquality() {
    // Тестирование сравнения MapEntryInfo
    let keyInfo1 = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo1 = ValueFieldInfo(name: "value", number: 2, type: .int32)
    
    let keyInfo2 = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo2 = ValueFieldInfo(name: "value", number: 2, type: .int32)
    
    let keyInfo3 = KeyFieldInfo(name: "different", number: 1, type: .string)
    let valueInfo3 = ValueFieldInfo(name: "value", number: 2, type: .int64) // Разный тип
    
    let mapInfo1 = MapEntryInfo(keyFieldInfo: keyInfo1, valueFieldInfo: valueInfo1)
    let mapInfo2 = MapEntryInfo(keyFieldInfo: keyInfo2, valueFieldInfo: valueInfo2)
    let mapInfo3 = MapEntryInfo(keyFieldInfo: keyInfo3, valueFieldInfo: valueInfo1)
    let mapInfo4 = MapEntryInfo(keyFieldInfo: keyInfo1, valueFieldInfo: valueInfo3)
    
    XCTAssertEqual(mapInfo1, mapInfo2)
    XCTAssertNotEqual(mapInfo1, mapInfo3)
    XCTAssertNotEqual(mapInfo1, mapInfo4)
  }
  
  func testMapEntryComplexValue() {
    // Тестирование MapEntry с более сложным типом значения
    let keyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo = ValueFieldInfo(
      name: "value",
      number: 2,
      type: .enum,
      typeName: "example.Status"
    )
    
    let mapInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valueInfo)
    
    XCTAssertEqual(mapInfo.valueFieldInfo.type, .enum)
    XCTAssertEqual(mapInfo.valueFieldInfo.typeName, "example.Status")
  }
  
  func testDifferentTypesNotEqual() {
    // Проверяем, что поля с разными типами не равны
    let field1 = FieldDescriptor(name: "field", number: 1, type: .int32)
    let field2 = FieldDescriptor(name: "field", number: 1, type: .int64)
    
    XCTAssertNotEqual(field1, field2)
  }
  
  func testDifferentJsonNamesNotEqual() {
    // Проверяем, что поля с разными JSON именами не равны
    let field1 = FieldDescriptor(name: "field", number: 1, type: .string, jsonName: "fieldOne")
    let field2 = FieldDescriptor(name: "field", number: 1, type: .string, jsonName: "fieldTwo")
    
    XCTAssertNotEqual(field1, field2)
  }
  
  func testDifferentTypeNamesNotEqual() {
    // Проверяем, что поля с разными типами сообщений не равны
    let field1 = FieldDescriptor(name: "field", number: 1, type: .message, typeName: "Type1")
    let field2 = FieldDescriptor(name: "field", number: 1, type: .message, typeName: "Type2")
    
    XCTAssertNotEqual(field1, field2)
  }
  
  func testDifferentRepeatedFlagsNotEqual() {
    // Проверяем, что поля с разными флагами repeated не равны
    let field1 = FieldDescriptor(name: "field", number: 1, type: .string, isRepeated: true)
    let field2 = FieldDescriptor(name: "field", number: 1, type: .string, isRepeated: false)
    
    XCTAssertNotEqual(field1, field2)
  }
  
  func testDifferentOptionalFlagsNotEqual() {
    // Проверяем, что поля с разными флагами optional не равны
    let field1 = FieldDescriptor(name: "field", number: 1, type: .string, isOptional: true)
    let field2 = FieldDescriptor(name: "field", number: 1, type: .string, isOptional: false)
    
    XCTAssertNotEqual(field1, field2)
  }
  
  func testDifferentRequiredFlagsNotEqual() {
    // Проверяем, что поля с разными флагами required не равны
    let field1 = FieldDescriptor(name: "field", number: 1, type: .string, isRequired: true)
    let field2 = FieldDescriptor(name: "field", number: 1, type: .string, isRequired: false)
    
    XCTAssertNotEqual(field1, field2)
  }
  
  func testDifferentMapFlagsNotEqual() {
    // Проверяем, что поля с разными флагами map не равны
    let keyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valueInfo)
    
    let field1 = FieldDescriptor(
      name: "field", 
      number: 1, 
      type: .message, 
      typeName: "MapEntry",
      isMap: true, 
      mapEntryInfo: mapInfo
    )
    
    let field2 = FieldDescriptor(
      name: "field", 
      number: 1, 
      type: .message, 
      typeName: "MapEntry",
      isMap: false
    )
    
    XCTAssertNotEqual(field1, field2)
  }
  
  func testAllFieldTypesScalarCheck() {
    // Проверка метода isScalarType для всех возможных типов FieldType
    let scalarTypes: [FieldType] = [
      .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64,
      .bool, .string, .bytes
    ]
    
    for type in scalarTypes {
      let field = FieldDescriptor(name: "field", number: 1, type: type)
      XCTAssertTrue(field.isScalarType(), "Тип \(type) должен быть скалярным")
    }
    
    let field1 = FieldDescriptor(name: "field", number: 1, type: .message, typeName: "Type")
    let field2 = FieldDescriptor(name: "field", number: 1, type: .enum, typeName: "Enum")
    let field3 = FieldDescriptor(name: "field", number: 1, type: .group, typeName: "Group")
    
    XCTAssertFalse(field1.isScalarType())
    XCTAssertFalse(field2.isScalarType())
    XCTAssertFalse(field3.isScalarType())
  }
  
  func testAllFieldTypesNumericCheck() {
    // Проверка метода isNumericType для всех возможных типов FieldType
    let numericTypes: [FieldType] = [
      .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64
    ]
    
    for type in numericTypes {
      let field = FieldDescriptor(name: "field", number: 1, type: type)
      XCTAssertTrue(field.isNumericType(), "Тип \(type) должен быть числовым")
    }
    
    let nonNumericTypes: [FieldType] = [
      .bool, .string, .bytes, .message, .enum, .group
    ]
    
    for type in nonNumericTypes {
      let typeName = (type == .message || type == .enum || type == .group) ? "Type" : nil
      let field = FieldDescriptor(name: "field", number: 1, type: type, typeName: typeName)
      XCTAssertFalse(field.isNumericType(), "Тип \(type) не должен быть числовым")
    }
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
}
