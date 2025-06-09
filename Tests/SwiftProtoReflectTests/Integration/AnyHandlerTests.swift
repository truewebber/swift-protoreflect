/**
 * AnyHandlerTests.swift
 * SwiftProtoReflectTests
 *
 * Comprehensive тесты для AnyHandler - google.protobuf.Any поддержка
 */

import XCTest

@testable import SwiftProtoReflect

final class AnyHandlerTests: XCTestCase {

  // MARK: - Handler Basic Properties

  func testHandlerBasicProperties() {
    // Проверяем базовые свойства handler'а
    XCTAssertEqual(AnyHandler.handledTypeName, WellKnownTypeNames.any)
    XCTAssertEqual(AnyHandler.supportPhase, .advanced)
  }

  // MARK: - AnyValue Initialization

  func testAnyValueInitialization() throws {
    // Тест успешной инициализации
    let typeUrl = "type.googleapis.com/google.protobuf.Duration"
    let data = Data([0x08, 0x96, 0x01])

    let anyValue = try AnyHandler.AnyValue(typeUrl: typeUrl, value: data)
    XCTAssertEqual(anyValue.typeUrl, typeUrl)
    XCTAssertEqual(anyValue.value, data)
  }

  func testAnyValueInitializationWithInvalidTypeUrl() {
    // Тест неудачной инициализации с невалидным URL
    let invalidUrls = [
      "",  // пустой
      "no-slash",  // без косой черты
      "http://example.com/",  // пустое имя типа
      "type.googleapis.com/InvalidType",  // без точки в имени типа
    ]

    for invalidUrl in invalidUrls {
      XCTAssertThrowsError(
        try AnyHandler.AnyValue(typeUrl: invalidUrl, value: Data())
      ) { error in
        XCTAssertTrue(error is WellKnownTypeError)
      }
    }
  }

  // MARK: - URL Utilities

  func testCreateTypeUrl() {
    let typeName = "google.protobuf.Duration"
    let expectedUrl = "type.googleapis.com/google.protobuf.Duration"
    let actualUrl = AnyHandler.AnyValue.createTypeUrl(for: typeName)
    XCTAssertEqual(actualUrl, expectedUrl)
  }

  func testExtractTypeName() {
    let typeUrl = "type.googleapis.com/google.protobuf.Duration"
    let expectedTypeName = "google.protobuf.Duration"
    let actualTypeName = AnyHandler.AnyValue.extractTypeName(from: typeUrl)
    XCTAssertEqual(actualTypeName, expectedTypeName)
  }

  func testExtractTypeNameFromSimpleUrl() {
    // Тест извлечения из простого URL без префикса
    let typeUrl = "simple.type.Name"
    let expectedTypeName = "simple.type.Name"
    let actualTypeName = AnyHandler.AnyValue.extractTypeName(from: typeUrl)
    XCTAssertEqual(actualTypeName, expectedTypeName)
  }

  func testIsValidTypeUrl() {
    // Валидные URLs
    let validUrls = [
      "type.googleapis.com/google.protobuf.Duration",
      "custom.domain.com/my.package.Message",
      "simple.example.com/package.Type",
    ]

    for url in validUrls {
      XCTAssertTrue(AnyHandler.AnyValue.isValidTypeUrl(url), "Should be valid: \(url)")
    }

    // Невалидные URLs
    let invalidUrls = [
      "",  // пустой
      "no-slash",  // без косой черты
      "http://example.com/",  // пустое имя типа
      "type.googleapis.com/InvalidType",  // без точки в имени типа
      "simple/package.Type",  // домен без точки
      "/just.TypeName",  // нет домена (начинается с "/")
    ]

    for url in invalidUrls {
      XCTAssertFalse(AnyHandler.AnyValue.isValidTypeUrl(url), "Should be invalid: \(url)")
    }
  }

  // MARK: - Pack/Unpack Operations

  func testPackUnpackSimpleMessage() throws {
    // Создаем простое сообщение для упаковки
    let originalMessage = try createTestMessage()

    // Упаковываем в Any
    let anyValue = try AnyHandler.AnyValue.pack(originalMessage)

    // Проверяем URL типа
    let expectedTypeUrl = "type.googleapis.com/test.package.TestMessage"
    XCTAssertEqual(anyValue.typeUrl, expectedTypeUrl)
    XCTAssertFalse(anyValue.value.isEmpty)

    // Проверяем получение имени типа
    XCTAssertEqual(anyValue.getTypeName(), "test.package.TestMessage")

    // Распаковываем обратно
    let unpackedMessage = try anyValue.unpack(to: originalMessage.descriptor)

    // Проверяем что данные совпадают
    XCTAssertEqual(
      try unpackedMessage.get(forField: "name") as? String,
      try originalMessage.get(forField: "name") as? String
    )
    XCTAssertEqual(
      try unpackedMessage.get(forField: "value") as? Int32,
      try originalMessage.get(forField: "value") as? Int32
    )
  }

  func testUnpackTypeMismatch() throws {
    // Создаем сообщение и упаковываем
    let originalMessage = try createTestMessage()
    let anyValue = try AnyHandler.AnyValue.pack(originalMessage)

    // Пытаемся распаковать в другой тип
    let wrongDescriptor = try createWrongMessageDescriptor()

    XCTAssertThrowsError(
      try anyValue.unpack(to: wrongDescriptor)
    ) { error in
      guard case WellKnownTypeError.conversionFailed = error else {
        XCTFail("Expected conversionFailed error")
        return
      }
    }
  }

  // MARK: - Handler Implementation

  func testCreateSpecializedFromMessage() throws {
    // Создаем Any сообщение
    let anyDescriptor = try createAnyDescriptor()
    let factory = MessageFactory()
    var anyMessage = factory.createMessage(from: anyDescriptor)

    // Устанавливаем поля
    try anyMessage.set("type.googleapis.com/test.Message", forField: "type_url")
    try anyMessage.set(Data([0x08, 0x96, 0x01]), forField: "value")

    // Создаем специализированное представление
    let specialized = try AnyHandler.createSpecialized(from: anyMessage)

    XCTAssertTrue(specialized is AnyHandler.AnyValue)
    let anyValue = specialized as! AnyHandler.AnyValue
    XCTAssertEqual(anyValue.typeUrl, "type.googleapis.com/test.Message")
    XCTAssertEqual(anyValue.value, Data([0x08, 0x96, 0x01]))
  }

  func testCreateSpecializedFromInvalidMessage() throws {
    // Попытка создать из неправильного типа сообщения
    let wrongMessage = try createTestMessage()

    XCTAssertThrowsError(
      try AnyHandler.createSpecialized(from: wrongMessage)
    ) { error in
      guard case WellKnownTypeError.invalidData = error else {
        XCTFail("Expected invalidData error")
        return
      }
    }
  }

  func testCreateSpecializedWithMissingFields() throws {
    // Создаем Any сообщение без обязательных полей
    let anyDescriptor = try createAnyDescriptor()
    let factory = MessageFactory()
    let anyMessage = factory.createMessage(from: anyDescriptor)

    // Не устанавливаем никаких полей
    XCTAssertThrowsError(
      try AnyHandler.createSpecialized(from: anyMessage)
    ) { error in
      guard case WellKnownTypeError.invalidData = error else {
        XCTFail("Expected invalidData error")
        return
      }
    }
  }

  func testCreateDynamicFromSpecialized() throws {
    // Создаем AnyValue
    let anyValue = try AnyHandler.AnyValue(
      typeUrl: "type.googleapis.com/test.Message",
      value: Data([0x08, 0x96, 0x01])
    )

    // Создаем динамическое сообщение
    let dynamicMessage = try AnyHandler.createDynamic(from: anyValue)

    // Проверяем результат
    XCTAssertEqual(dynamicMessage.descriptor.fullName, WellKnownTypeNames.any)
    XCTAssertEqual(
      try dynamicMessage.get(forField: "type_url") as? String,
      "type.googleapis.com/test.Message"
    )
    XCTAssertEqual(
      try dynamicMessage.get(forField: "value") as? Data,
      Data([0x08, 0x96, 0x01])
    )
  }

  func testCreateDynamicFromInvalidSpecialized() {
    // Попытка создать из неправильного типа
    let wrongObject = "not an AnyValue"

    XCTAssertThrowsError(
      try AnyHandler.createDynamic(from: wrongObject)
    ) { error in
      guard case WellKnownTypeError.conversionFailed = error else {
        XCTFail("Expected conversionFailed error")
        return
      }
    }
  }

  // MARK: - Validation

  func testValidate() throws {
    // Валидный AnyValue
    let validAnyValue = try AnyHandler.AnyValue(
      typeUrl: "type.googleapis.com/test.Message",
      value: Data([0x08, 0x96, 0x01])
    )
    XCTAssertTrue(AnyHandler.validate(validAnyValue))

    // Невалидный объект
    let invalidObject = "not an AnyValue"
    XCTAssertFalse(AnyHandler.validate(invalidObject))
  }

  // MARK: - DynamicMessage Extensions

  func testPackIntoAnyExtension() throws {
    let originalMessage = try createTestMessage()
    let anyMessage = try originalMessage.packIntoAny()

    XCTAssertEqual(anyMessage.descriptor.fullName, WellKnownTypeNames.any)
    XCTAssertNotNil(try anyMessage.get(forField: "type_url"))
    XCTAssertNotNil(try anyMessage.get(forField: "value"))
  }

  func testUnpackFromAnyExtension() throws {
    // Создаем и упаковываем сообщение
    let originalMessage = try createTestMessage()
    let anyMessage = try originalMessage.packIntoAny()

    // Распаковываем обратно
    let unpackedMessage = try anyMessage.unpackFromAny(to: originalMessage.descriptor)

    // Проверяем данные
    XCTAssertEqual(
      try unpackedMessage.get(forField: "name") as? String,
      try originalMessage.get(forField: "name") as? String
    )
  }

  func testUnpackFromAnyWithWrongMessage() throws {
    let wrongMessage = try createTestMessage()

    XCTAssertThrowsError(
      try wrongMessage.unpackFromAny(to: wrongMessage.descriptor)
    ) { error in
      guard case WellKnownTypeError.invalidData = error else {
        XCTFail("Expected invalidData error")
        return
      }
    }
  }

  func testIsAnyOfExtension() throws {
    let originalMessage = try createTestMessage()
    let anyMessage = try originalMessage.packIntoAny()

    XCTAssertTrue(try anyMessage.isAnyOf(typeName: "test.package.TestMessage"))
    XCTAssertFalse(try anyMessage.isAnyOf(typeName: "other.package.OtherMessage"))
  }

  func testGetAnyTypeNameExtension() throws {
    let originalMessage = try createTestMessage()
    let anyMessage = try originalMessage.packIntoAny()

    let typeName = try anyMessage.getAnyTypeName()
    XCTAssertEqual(typeName, "test.package.TestMessage")
  }

  // MARK: - TypeRegistry Integration

  func testUnpackUsingRegistry() throws {
    // Создаем registry и регистрируем тип
    let registry = TypeRegistry()
    let testDescriptor = try createTestMessageDescriptor()
    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test.package")
    fileDescriptor.addMessage(testDescriptor)
    try registry.registerFile(fileDescriptor)

    // Создаем и упаковываем сообщение
    let factory = MessageFactory()
    var originalMessage = factory.createMessage(from: testDescriptor)
    try originalMessage.set("test_name", forField: "name")
    try originalMessage.set(Int32(42), forField: "value")

    let anyValue = try AnyHandler.AnyValue.pack(originalMessage)

    // Распаковываем используя registry
    let unpackedMessage = try anyValue.unpack(using: registry)

    XCTAssertEqual(
      try unpackedMessage.get(forField: "name") as? String,
      "test_name"
    )
    XCTAssertEqual(
      try unpackedMessage.get(forField: "value") as? Int32,
      42
    )
  }

  func testUnpackUsingRegistryWithUnknownType() throws {
    let registry = TypeRegistry()

    let anyValue = try AnyHandler.AnyValue(
      typeUrl: "type.googleapis.com/unknown.Type",
      value: Data([0x08, 0x96, 0x01])
    )

    XCTAssertThrowsError(
      try anyValue.unpack(using: registry)
    ) { error in
      guard case WellKnownTypeError.conversionFailed = error else {
        XCTFail("Expected conversionFailed error")
        return
      }
    }
  }

  // MARK: - Registry Integration

  func testRegistryIntegration() {
    let registry = WellKnownTypesRegistry.shared

    // Проверяем что AnyHandler зарегистрирован
    let handler = registry.getHandler(for: WellKnownTypeNames.any)
    XCTAssertNotNil(handler)
    XCTAssertTrue(handler is AnyHandler.Type)
  }

  func testRegistryCreateSpecialized() throws {
    let registry = WellKnownTypesRegistry.shared

    // Создаем Any сообщение
    let anyDescriptor = try createAnyDescriptor()
    let factory = MessageFactory()
    var anyMessage = factory.createMessage(from: anyDescriptor)
    try anyMessage.set("type.googleapis.com/test.Message", forField: "type_url")
    try anyMessage.set(Data([0x08, 0x96, 0x01]), forField: "value")

    // Создаем через registry
    let specialized = try registry.createSpecialized(
      from: anyMessage,
      typeName: WellKnownTypeNames.any
    )

    XCTAssertTrue(specialized is AnyHandler.AnyValue)
  }

  func testRegistryCreateDynamic() throws {
    let registry = WellKnownTypesRegistry.shared

    let anyValue = try AnyHandler.AnyValue(
      typeUrl: "type.googleapis.com/test.Message",
      value: Data([0x08, 0x96, 0x01])
    )

    let dynamicMessage = try registry.createDynamic(
      from: anyValue,
      typeName: WellKnownTypeNames.any
    )

    XCTAssertEqual(dynamicMessage.descriptor.fullName, WellKnownTypeNames.any)
  }

  // MARK: - Round-trip Conversion

  func testRoundTripConversion() throws {
    // Создаем исходное сообщение
    var originalMessage = try createTestMessage()
    try originalMessage.set("round_trip_test", forField: "name")
    try originalMessage.set(Int32(123), forField: "value")

    // Any Value round-trip
    let anyValue = try AnyHandler.AnyValue.pack(originalMessage)
    let unpackedMessage = try anyValue.unpack(to: originalMessage.descriptor)

    XCTAssertEqual(
      try unpackedMessage.get(forField: "name") as? String,
      "round_trip_test"
    )
    XCTAssertEqual(
      try unpackedMessage.get(forField: "value") as? Int32,
      123
    )

    // Dynamic Message round-trip
    let anyMessage = try AnyHandler.createDynamic(from: anyValue)
    let roundTripAnyValue = try AnyHandler.createSpecialized(from: anyMessage) as! AnyHandler.AnyValue

    XCTAssertEqual(anyValue, roundTripAnyValue)
  }

  // MARK: - Description and Equality

  func testAnyValueDescription() throws {
    let anyValue = try AnyHandler.AnyValue(
      typeUrl: "type.googleapis.com/test.Message",
      value: Data([0x08, 0x96, 0x01])
    )

    let description = anyValue.description
    XCTAssertTrue(description.contains("Any"))
    XCTAssertTrue(description.contains("type.googleapis.com/test.Message"))
    XCTAssertTrue(description.contains("3 bytes"))
  }

  func testAnyValueEquality() throws {
    let anyValue1 = try AnyHandler.AnyValue(
      typeUrl: "type.googleapis.com/test.Message",
      value: Data([0x08, 0x96, 0x01])
    )

    let anyValue2 = try AnyHandler.AnyValue(
      typeUrl: "type.googleapis.com/test.Message",
      value: Data([0x08, 0x96, 0x01])
    )

    let anyValue3 = try AnyHandler.AnyValue(
      typeUrl: "type.googleapis.com/other.Message",
      value: Data([0x08, 0x96, 0x01])
    )

    XCTAssertEqual(anyValue1, anyValue2)
    XCTAssertNotEqual(anyValue1, anyValue3)
  }

  // MARK: - Performance Tests

  func testPackUnpackPerformance() throws {
    let originalMessage = try createTestMessage()

    measure {
      do {
        for _ in 0..<100 {
          let anyValue = try AnyHandler.AnyValue.pack(originalMessage)
          _ = try anyValue.unpack(to: originalMessage.descriptor)
        }
      }
      catch {
        XCTFail("Performance test failed: \(error)")
      }
    }
  }

  // MARK: - Helper Methods

  private func createTestMessage() throws -> DynamicMessage {
    let descriptor = try createTestMessageDescriptor()
    let factory = MessageFactory()
    var message = factory.createMessage(from: descriptor)
    try message.set("test_name", forField: "name")
    try message.set(Int32(42), forField: "value")
    return message
  }

  private func createTestMessageDescriptor() throws -> MessageDescriptor {
    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test.package")
    var messageDescriptor = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)

    let nameField = FieldDescriptor(name: "name", number: 1, type: .string)
    let valueField = FieldDescriptor(name: "value", number: 2, type: .int32)

    messageDescriptor.addField(nameField)
    messageDescriptor.addField(valueField)
    fileDescriptor.addMessage(messageDescriptor)

    return messageDescriptor
  }

  private func createWrongMessageDescriptor() throws -> MessageDescriptor {
    var fileDescriptor = FileDescriptor(name: "wrong.proto", package: "wrong.package")
    var messageDescriptor = MessageDescriptor(name: "WrongMessage", parent: fileDescriptor)

    let wrongField = FieldDescriptor(name: "wrong", number: 1, type: .string)
    messageDescriptor.addField(wrongField)
    fileDescriptor.addMessage(messageDescriptor)

    return messageDescriptor
  }

  private func createAnyDescriptor() throws -> MessageDescriptor {
    var fileDescriptor = FileDescriptor(name: "google/protobuf/any.proto", package: "google.protobuf")
    var messageDescriptor = MessageDescriptor(name: "Any", parent: fileDescriptor)

    let typeUrlField = FieldDescriptor(name: "type_url", number: 1, type: .string)
    let valueField = FieldDescriptor(name: "value", number: 2, type: .bytes)

    messageDescriptor.addField(typeUrlField)
    messageDescriptor.addField(valueField)
    fileDescriptor.addMessage(messageDescriptor)

    return messageDescriptor
  }
}
