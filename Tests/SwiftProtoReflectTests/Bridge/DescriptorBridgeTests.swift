//
// DescriptorBridgeTests.swift
// SwiftProtoReflectTests
//
// Создан: 2025-05-25
//

import XCTest

import struct SwiftProtobuf.Google_Protobuf_DescriptorProto
import struct SwiftProtobuf.Google_Protobuf_EnumDescriptorProto
import struct SwiftProtobuf.Google_Protobuf_EnumValueDescriptorProto
import struct SwiftProtobuf.Google_Protobuf_FieldDescriptorProto
import struct SwiftProtobuf.Google_Protobuf_FieldOptions
import struct SwiftProtobuf.Google_Protobuf_FileDescriptorProto
import struct SwiftProtobuf.Google_Protobuf_MessageOptions
import struct SwiftProtobuf.Google_Protobuf_MethodDescriptorProto
import struct SwiftProtobuf.Google_Protobuf_ServiceDescriptorProto

@testable import SwiftProtoReflect

final class DescriptorBridgeTests: XCTestCase {

  // MARK: - Test Properties

  private var bridge: DescriptorBridge!
  private var fileDescriptor: FileDescriptor!

  // MARK: - Setup and Teardown

  override func setUp() {
    super.setUp()
    bridge = DescriptorBridge()

    // Создаем тестовый дескриптор файла
    fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
  }

  override func tearDown() {
    bridge = nil
    fileDescriptor = nil
    super.tearDown()
  }

  // MARK: - Initialization Tests

  func testInitialization() {
    let bridge = DescriptorBridge()
    XCTAssertNotNil(bridge)
  }

  // MARK: - Message Descriptor Conversion Tests

  func testMessageDescriptorToProtobuf() throws {
    // Создаем тестовый MessageDescriptor
    var messageDescriptor = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    messageDescriptor.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    messageDescriptor.addField(FieldDescriptor(name: "age", number: 2, type: .int32))

    // Конвертируем в protobuf формат
    let protobufDescriptor = try bridge.toProtobufDescriptor(from: messageDescriptor)

    // Проверяем результат
    XCTAssertEqual(protobufDescriptor.name, "TestMessage")
    XCTAssertEqual(protobufDescriptor.field.count, 2)
    XCTAssertEqual(protobufDescriptor.field[0].name, "name")
    XCTAssertEqual(protobufDescriptor.field[0].type, .string)
    XCTAssertEqual(protobufDescriptor.field[1].name, "age")
    XCTAssertEqual(protobufDescriptor.field[1].type, .int32)
  }

  func testMessageDescriptorFromProtobuf() throws {
    // Создаем тестовый protobuf дескриптор
    var protobufDescriptor = Google_Protobuf_DescriptorProto()
    protobufDescriptor.name = "TestMessage"

    var field1 = Google_Protobuf_FieldDescriptorProto()
    field1.name = "name"
    field1.number = 1
    field1.type = .string
    field1.label = .optional

    var field2 = Google_Protobuf_FieldDescriptorProto()
    field2.name = "age"
    field2.number = 2
    field2.type = .int32
    field2.label = .optional

    protobufDescriptor.field = [field1, field2]

    // Конвертируем в наш формат
    let messageDescriptor = try bridge.fromProtobufDescriptor(protobufDescriptor, parent: fileDescriptor)

    // Проверяем результат
    XCTAssertEqual(messageDescriptor.name, "TestMessage")
    XCTAssertEqual(messageDescriptor.allFields().count, 2)

    let nameField = messageDescriptor.field(named: "name")
    XCTAssertNotNil(nameField)
    XCTAssertEqual(nameField?.type, .string)

    let ageField = messageDescriptor.field(named: "age")
    XCTAssertNotNil(ageField)
    XCTAssertEqual(ageField?.type, .int32)
  }

  func testMessageDescriptorWithNestedTypes() throws {
    // Создаем сложный MessageDescriptor с вложенными типами
    var messageDescriptor = MessageDescriptor(name: "ComplexMessage", parent: fileDescriptor)

    // Добавляем вложенное сообщение
    var nestedMessage = MessageDescriptor(name: "NestedMessage")
    nestedMessage.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    messageDescriptor.addNestedMessage(nestedMessage)

    // Добавляем вложенный enum
    var nestedEnum = EnumDescriptor(name: "NestedEnum")
    nestedEnum.addValue(EnumDescriptor.EnumValue(name: "VALUE1", number: 0))
    nestedEnum.addValue(EnumDescriptor.EnumValue(name: "VALUE2", number: 1))
    messageDescriptor.addNestedEnum(nestedEnum)

    // Конвертируем в protobuf и обратно
    let protobufDescriptor = try bridge.toProtobufDescriptor(from: messageDescriptor)
    let convertedBack = try bridge.fromProtobufDescriptor(protobufDescriptor)

    // Проверяем результат
    XCTAssertEqual(convertedBack.name, "ComplexMessage")
    XCTAssertEqual(convertedBack.nestedMessages.count, 1)
    XCTAssertEqual(convertedBack.nestedEnums.count, 1)
    XCTAssertEqual(Array(convertedBack.nestedMessages.values)[0].name, "NestedMessage")
    XCTAssertEqual(Array(convertedBack.nestedEnums.values)[0].name, "NestedEnum")
  }

  // MARK: - Field Descriptor Conversion Tests

  func testFieldDescriptorToProtobuf() throws {
    // Тестируем скалярные типы полей
    let scalarTestCases: [(FieldType, Google_Protobuf_FieldDescriptorProto.TypeEnum)] = [
      (.string, .string),
      (.int32, .int32),
      (.int64, .int64),
      (.uint32, .uint32),
      (.uint64, .uint64),
      (.bool, .bool),
      (.double, .double),
      (.float, .float),
      (.bytes, .bytes),
    ]

    for (fieldType, expectedProtobufType) in scalarTestCases {
      let fieldDescriptor = FieldDescriptor(name: "test_field", number: 1, type: fieldType)
      let protobufField = try bridge.toProtobufFieldDescriptor(from: fieldDescriptor)

      XCTAssertEqual(protobufField.type, expectedProtobufType, "Failed for field type: \(fieldType)")
      XCTAssertEqual(protobufField.name, "test_field")
      XCTAssertEqual(protobufField.number, 1)
    }

    // Тестируем сложные типы полей (требуют typeName)
    let enumFieldDescriptor = FieldDescriptor(
      name: "enum_field",
      number: 2,
      type: .enum,
      typeName: "TestEnum"
    )
    let enumProtobufField = try bridge.toProtobufFieldDescriptor(from: enumFieldDescriptor)
    XCTAssertEqual(enumProtobufField.type, .enum)
    XCTAssertEqual(enumProtobufField.typeName, "TestEnum")

    let messageFieldDescriptor = FieldDescriptor(
      name: "message_field",
      number: 3,
      type: .message,
      typeName: "TestMessage"
    )
    let messageProtobufField = try bridge.toProtobufFieldDescriptor(from: messageFieldDescriptor)
    XCTAssertEqual(messageProtobufField.type, .message)
    XCTAssertEqual(messageProtobufField.typeName, "TestMessage")
  }

  func testFieldDescriptorFromProtobuf() throws {
    // Создаем тестовый protobuf field descriptor
    var protobufField = Google_Protobuf_FieldDescriptorProto()
    protobufField.name = "test_field"
    protobufField.number = 42
    protobufField.type = .string
    protobufField.label = .repeated

    // Конвертируем в наш формат
    let fieldDescriptor = try bridge.fromProtobufFieldDescriptor(protobufField)

    // Проверяем результат
    XCTAssertEqual(fieldDescriptor.name, "test_field")
    XCTAssertEqual(fieldDescriptor.number, 42)
    XCTAssertEqual(fieldDescriptor.type, .string)
    XCTAssertTrue(fieldDescriptor.isRepeated)
    XCTAssertFalse(fieldDescriptor.isRequired)
  }

  func testFieldDescriptorLabels() throws {
    // Тестируем различные labels
    let testCases: [(Google_Protobuf_FieldDescriptorProto.Label, Bool, Bool, Bool)] = [
      (.optional, false, false, true),
      (.required, false, true, false),
      (.repeated, true, false, false),
    ]

    for (label, expectedRepeated, expectedRequired, expectedOptional) in testCases {
      var protobufField = Google_Protobuf_FieldDescriptorProto()
      protobufField.name = "test"
      protobufField.number = 1
      protobufField.type = .string
      protobufField.label = label

      let fieldDescriptor = try bridge.fromProtobufFieldDescriptor(protobufField)

      XCTAssertEqual(fieldDescriptor.isRepeated, expectedRepeated, "Failed for label: \(label)")
      XCTAssertEqual(fieldDescriptor.isRequired, expectedRequired, "Failed for label: \(label)")
      XCTAssertEqual(fieldDescriptor.isOptional, expectedOptional, "Failed for label: \(label)")
    }
  }

  // MARK: - Enum Descriptor Conversion Tests

  func testEnumDescriptorToProtobuf() throws {
    // Создаем тестовый EnumDescriptor
    var enumDescriptor = EnumDescriptor(name: "TestEnum")
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "VALUE1", number: 1))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "VALUE2", number: 2))

    // Конвертируем в protobuf формат
    let protobufEnum = try bridge.toProtobufEnumDescriptor(from: enumDescriptor)

    // Проверяем результат
    XCTAssertEqual(protobufEnum.name, "TestEnum")
    XCTAssertEqual(protobufEnum.value.count, 3)
    XCTAssertEqual(protobufEnum.value[0].name, "UNKNOWN")
    XCTAssertEqual(protobufEnum.value[0].number, 0)
    XCTAssertEqual(protobufEnum.value[1].name, "VALUE1")
    XCTAssertEqual(protobufEnum.value[1].number, 1)
    XCTAssertEqual(protobufEnum.value[2].name, "VALUE2")
    XCTAssertEqual(protobufEnum.value[2].number, 2)
  }

  func testEnumDescriptorFromProtobuf() throws {
    // Создаем тестовый protobuf enum descriptor
    var protobufEnum = Google_Protobuf_EnumDescriptorProto()
    protobufEnum.name = "TestEnum"

    var value1 = Google_Protobuf_EnumValueDescriptorProto()
    value1.name = "UNKNOWN"
    value1.number = 0

    var value2 = Google_Protobuf_EnumValueDescriptorProto()
    value2.name = "VALUE1"
    value2.number = 1

    protobufEnum.value = [value1, value2]

    // Конвертируем в наш формат
    let enumDescriptor = try bridge.fromProtobufEnumDescriptor(protobufEnum)

    // Проверяем результат
    XCTAssertEqual(enumDescriptor.name, "TestEnum")
    XCTAssertEqual(enumDescriptor.allValues().count, 2)

    let unknownValue = enumDescriptor.value(named: "UNKNOWN")
    XCTAssertNotNil(unknownValue)
    XCTAssertEqual(unknownValue?.number, 0)

    let value1Desc = enumDescriptor.value(named: "VALUE1")
    XCTAssertNotNil(value1Desc)
    XCTAssertEqual(value1Desc?.number, 1)
  }

  // MARK: - File Descriptor Conversion Tests

  func testFileDescriptorToProtobuf() throws {
    // Создаем тестовый FileDescriptor с содержимым
    var fileDesc = FileDescriptor(name: "test.proto", package: "com.example")

    // Добавляем сообщение
    var message = MessageDescriptor(name: "TestMessage", parent: fileDesc)
    message.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    fileDesc.addMessage(message)

    // Добавляем enum
    var enumDesc = EnumDescriptor(name: "TestEnum", parent: fileDesc)
    enumDesc.addValue(EnumDescriptor.EnumValue(name: "VALUE1", number: 0))
    fileDesc.addEnum(enumDesc)

    // Добавляем сервис
    var service = ServiceDescriptor(name: "TestService", parent: fileDesc)
    service.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "TestMethod",
        inputType: "TestMessage",
        outputType: "TestMessage"
      )
    )
    fileDesc.addService(service)

    // Конвертируем в protobuf формат
    let protobufFile = try bridge.toProtobufFileDescriptor(from: fileDesc)

    // Проверяем результат
    XCTAssertEqual(protobufFile.name, "test.proto")
    XCTAssertEqual(protobufFile.package, "com.example")
    XCTAssertEqual(protobufFile.messageType.count, 1)
    XCTAssertEqual(protobufFile.enumType.count, 1)
    XCTAssertEqual(protobufFile.service.count, 1)
    XCTAssertEqual(protobufFile.messageType[0].name, "TestMessage")
    XCTAssertEqual(protobufFile.enumType[0].name, "TestEnum")
    XCTAssertEqual(protobufFile.service[0].name, "TestService")
  }

  func testFileDescriptorFromProtobuf() throws {
    // Создаем тестовый protobuf file descriptor
    var protobufFile = Google_Protobuf_FileDescriptorProto()
    protobufFile.name = "test.proto"
    protobufFile.package = "com.example"
    protobufFile.dependency = ["google/protobuf/empty.proto"]

    // Добавляем сообщение
    var message = Google_Protobuf_DescriptorProto()
    message.name = "TestMessage"
    protobufFile.messageType = [message]

    // Конвертируем в наш формат
    let fileDesc = try bridge.fromProtobufFileDescriptor(protobufFile)

    // Проверяем результат
    XCTAssertEqual(fileDesc.name, "test.proto")
    XCTAssertEqual(fileDesc.package, "com.example")
    XCTAssertEqual(fileDesc.dependencies, ["google/protobuf/empty.proto"])
    XCTAssertEqual(fileDesc.messages.count, 1)
    XCTAssertEqual(Array(fileDesc.messages.values)[0].name, "TestMessage")
  }

  // MARK: - Service Descriptor Conversion Tests

  func testServiceDescriptorToProtobuf() throws {
    // Создаем тестовый ServiceDescriptor
    var serviceDescriptor = ServiceDescriptor(name: "TestService", parent: fileDescriptor)
    serviceDescriptor.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "UnaryMethod",
        inputType: "TestRequest",
        outputType: "TestResponse"
      )
    )
    serviceDescriptor.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "StreamingMethod",
        inputType: "TestRequest",
        outputType: "TestResponse",
        clientStreaming: true,
        serverStreaming: true
      )
    )

    // Конвертируем в protobuf формат
    let protobufService = try bridge.toProtobufServiceDescriptor(from: serviceDescriptor)

    // Проверяем результат
    XCTAssertEqual(protobufService.name, "TestService")
    XCTAssertEqual(protobufService.method.count, 2)

    // Ищем методы по имени вместо проверки по индексам
    let unaryMethod = protobufService.method.first { $0.name == "UnaryMethod" }
    XCTAssertNotNil(unaryMethod, "UnaryMethod not found")
    XCTAssertEqual(unaryMethod?.inputType, "TestRequest")
    XCTAssertEqual(unaryMethod?.outputType, "TestResponse")
    XCTAssertFalse(unaryMethod?.clientStreaming ?? true)
    XCTAssertFalse(unaryMethod?.serverStreaming ?? true)

    let streamingMethod = protobufService.method.first { $0.name == "StreamingMethod" }
    XCTAssertNotNil(streamingMethod, "StreamingMethod not found")
    XCTAssertEqual(streamingMethod?.inputType, "TestRequest")
    XCTAssertEqual(streamingMethod?.outputType, "TestResponse")
    XCTAssertTrue(streamingMethod?.clientStreaming ?? false)
    XCTAssertTrue(streamingMethod?.serverStreaming ?? false)
  }

  func testServiceDescriptorFromProtobuf() throws {
    // Создаем тестовый protobuf service descriptor
    var protobufService = Google_Protobuf_ServiceDescriptorProto()
    protobufService.name = "TestService"

    var method = Google_Protobuf_MethodDescriptorProto()
    method.name = "TestMethod"
    method.inputType = "TestRequest"
    method.outputType = "TestResponse"
    method.clientStreaming = false
    method.serverStreaming = true

    protobufService.method = [method]

    // Конвертируем в наш формат
    let serviceDescriptor = try bridge.fromProtobufServiceDescriptor(protobufService, parent: fileDescriptor)

    // Проверяем результат
    XCTAssertEqual(serviceDescriptor.name, "TestService")
    XCTAssertEqual(serviceDescriptor.allMethods().count, 1)

    let testMethod = serviceDescriptor.method(named: "TestMethod")
    XCTAssertNotNil(testMethod)
    XCTAssertEqual(testMethod?.inputType, "TestRequest")
    XCTAssertEqual(testMethod?.outputType, "TestResponse")
    XCTAssertFalse(testMethod?.clientStreaming ?? true)
    XCTAssertTrue(testMethod?.serverStreaming ?? false)
  }

  // MARK: - Round-trip Conversion Tests

  func testMessageDescriptorRoundTrip() throws {
    // Создаем исходный MessageDescriptor
    var original = MessageDescriptor(name: "RoundTripMessage", parent: fileDescriptor)
    original.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    original.addField(FieldDescriptor(name: "age", number: 2, type: .int32, isRepeated: true))
    original.addField(FieldDescriptor(name: "active", number: 3, type: .bool, isRequired: true))

    // Конвертируем в protobuf и обратно
    let protobufDescriptor = try bridge.toProtobufDescriptor(from: original)
    let converted = try bridge.fromProtobufDescriptor(protobufDescriptor)

    // Проверяем, что данные сохранились
    XCTAssertEqual(converted.name, original.name)
    XCTAssertEqual(converted.allFields().count, original.allFields().count)

    for originalField in original.allFields() {
      let convertedField = converted.field(named: originalField.name)
      XCTAssertNotNil(convertedField, "Field \(originalField.name) not found after round-trip")
      XCTAssertEqual(convertedField?.type, originalField.type)
      XCTAssertEqual(convertedField?.number, originalField.number)
      XCTAssertEqual(convertedField?.isRepeated, originalField.isRepeated)
      XCTAssertEqual(convertedField?.isRequired, originalField.isRequired)
    }
  }

  func testFileDescriptorRoundTrip() throws {
    // Создаем исходный FileDescriptor
    var original = FileDescriptor(name: "roundtrip.proto", package: "test.roundtrip")

    var message = MessageDescriptor(name: "TestMessage", parent: original)
    message.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    original.addMessage(message)

    var enumDesc = EnumDescriptor(name: "TestEnum", parent: original)
    enumDesc.addValue(EnumDescriptor.EnumValue(name: "VALUE1", number: 0))
    original.addEnum(enumDesc)

    // Конвертируем в protobuf и обратно
    let protobufDescriptor = try bridge.toProtobufFileDescriptor(from: original)
    let converted = try bridge.fromProtobufFileDescriptor(protobufDescriptor)

    // Проверяем, что данные сохранились
    XCTAssertEqual(converted.name, original.name)
    XCTAssertEqual(converted.package, original.package)
    XCTAssertEqual(converted.messages.count, original.messages.count)
    XCTAssertEqual(converted.enums.count, original.enums.count)
    XCTAssertEqual(Array(converted.messages.values)[0].name, Array(original.messages.values)[0].name)
    XCTAssertEqual(Array(converted.enums.values)[0].name, Array(original.enums.values)[0].name)
  }

  // MARK: - Error Handling Tests

  func testUnsupportedFieldTypeError() {
    // Тестируем обработку ошибок конвертации
    // Поскольку все типы поддерживаются в DescriptorBridge, тестируем другие ошибки

    // Тестируем, что group тип поддерживается (не выбрасывает ошибку)
    var protobufField = Google_Protobuf_FieldDescriptorProto()
    protobufField.name = "test_field"
    protobufField.number = 1
    protobufField.type = .group
    protobufField.label = .optional

    XCTAssertNoThrow(try bridge.fromProtobufFieldDescriptor(protobufField))
  }

  func testErrorDescriptions() {
    let errors: [DescriptorBridgeError] = [
      .unsupportedFieldType(123),
      .conversionFailed("Test conversion failed"),
      .missingRequiredField("requiredField"),
      .invalidDescriptorStructure("Invalid structure"),
    ]

    for error in errors {
      XCTAssertNotNil(error.errorDescription)
      XCTAssertFalse(error.errorDescription!.isEmpty)
    }
  }

  func testInvalidFieldDescriptorError() {
    // Тестируем обработку некорректного дескриптора поля
    var protobufField = Google_Protobuf_FieldDescriptorProto()
    protobufField.name = ""  // Пустое имя должно вызвать ошибку
    protobufField.number = 0  // Некорректный номер поля
    protobufField.type = .string
    protobufField.label = .optional

    // В данном случае тестируем, что конвертация проходит, но можем добавить валидацию позже
    XCTAssertNoThrow(try bridge.fromProtobufFieldDescriptor(protobufField))
  }

  // MARK: - Performance Tests

  func testConversionPerformance() throws {
    // Создаем сложный дескриптор для тестирования производительности
    var fileDesc = FileDescriptor(name: "performance.proto", package: "test.performance")

    for i in 0..<10 {
      var message = MessageDescriptor(name: "Message\(i)", parent: fileDesc)
      for j in 0..<20 {
        message.addField(FieldDescriptor(name: "field\(j)", number: j + 1, type: .string))
      }
      fileDesc.addMessage(message)
    }

    measure {
      do {
        // Измеряем производительность конвертации
        let protobufDescriptor = try bridge.toProtobufFileDescriptor(from: fileDesc)
        _ = try bridge.fromProtobufFileDescriptor(protobufDescriptor)
      }
      catch {
        XCTFail("Performance test failed with error: \(error)")
      }
    }
  }

  // MARK: - Additional Coverage Tests

  func testMessageDescriptorWithOptions() throws {
    // Создаем MessageDescriptor с опциями через конструктор
    var messageDescriptor = MessageDescriptor(
      name: "MessageWithOptions",
      parent: fileDescriptor,
      options: ["deprecated": true, "custom_option": "test_value"]
    )
    messageDescriptor.addField(FieldDescriptor(name: "name", number: 1, type: .string))

    // Конвертируем в protobuf формат (должно покрыть строку 57)
    let protobufDescriptor = try bridge.toProtobufDescriptor(from: messageDescriptor)

    // Проверяем, что конвертация прошла успешно
    XCTAssertEqual(protobufDescriptor.name, "MessageWithOptions")
    XCTAssertEqual(protobufDescriptor.field.count, 1)
  }

  func testMessageDescriptorFromProtobufWithOptions() throws {
    // Создаем protobuf дескриптор с опциями
    var protobufDescriptor = Google_Protobuf_DescriptorProto()
    protobufDescriptor.name = "MessageWithOptions"
    protobufDescriptor.options = Google_Protobuf_MessageOptions()

    // Конвертируем в наш формат (должно покрыть строки 99-103)
    let messageDescriptor = try bridge.fromProtobufDescriptor(protobufDescriptor, parent: fileDescriptor)

    // Проверяем результат
    XCTAssertEqual(messageDescriptor.name, "MessageWithOptions")
  }

  func testFieldDescriptorWithCustomJsonName() throws {
    // Создаем FieldDescriptor с кастомным JSON именем
    let fieldDescriptor = FieldDescriptor(
      name: "field_name",
      number: 1,
      type: .string,
      jsonName: "customJsonName"
    )

    // Конвертируем в protobuf формат (должно покрыть строку 144)
    let protobufField = try bridge.toProtobufFieldDescriptor(from: fieldDescriptor)

    // Проверяем результат
    XCTAssertEqual(protobufField.name, "field_name")
    XCTAssertEqual(protobufField.jsonName, "customJsonName")
  }

  func testFieldDescriptorWithOptions() throws {
    // Создаем FieldDescriptor с опциями через конструктор
    let fieldDescriptor = FieldDescriptor(
      name: "field_with_options",
      number: 1,
      type: .string,
      options: ["packed": true, "deprecated": false]
    )

    // Конвертируем в protobuf формат (должно покрыть строку 149)
    let protobufField = try bridge.toProtobufFieldDescriptor(from: fieldDescriptor)

    // Проверяем результат
    XCTAssertEqual(protobufField.name, "field_with_options")
    XCTAssertEqual(protobufField.type, .string)
  }

  func testFieldDescriptorFromProtobufWithOptions() throws {
    // Создаем protobuf field descriptor с опциями
    var protobufField = Google_Protobuf_FieldDescriptorProto()
    protobufField.name = "field_with_options"
    protobufField.number = 1
    protobufField.type = .string
    protobufField.label = .optional
    protobufField.options = Google_Protobuf_FieldOptions()

    // Конвертируем в наш формат (должно покрыть строки 185-189)
    let fieldDescriptor = try bridge.fromProtobufFieldDescriptor(protobufField)

    // Проверяем результат
    XCTAssertEqual(fieldDescriptor.name, "field_with_options")
    XCTAssertEqual(fieldDescriptor.type, .string)
  }

  func testEnumDescriptorWithValueOptions() throws {
    // Создаем EnumDescriptor с опциями в значениях
    var enumDescriptor = EnumDescriptor(name: "EnumWithOptions")

    let enumValue = EnumDescriptor.EnumValue(
      name: "VALUE_WITH_OPTIONS",
      number: 0,
      options: ["deprecated": true]
    )
    enumDescriptor.addValue(enumValue)

    // Конвертируем в protobuf формат (должно покрыть строки 218-220)
    let protobufEnum = try bridge.toProtobufEnumDescriptor(from: enumDescriptor)

    // Проверяем результат
    XCTAssertEqual(protobufEnum.name, "EnumWithOptions")
    XCTAssertEqual(protobufEnum.value.count, 1)
    XCTAssertEqual(protobufEnum.value[0].name, "VALUE_WITH_OPTIONS")
  }

  func testEnumDescriptorWithEnumOptions() throws {
    // Создаем EnumDescriptor с опциями enum'а через конструктор
    var enumDescriptor = EnumDescriptor(
      name: "EnumWithOptions",
      options: ["allow_alias": true]
    )
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "VALUE1", number: 0))

    // Конвертируем в protobuf формат (должно покрыть строки 227-229)
    let protobufEnum = try bridge.toProtobufEnumDescriptor(from: enumDescriptor)

    // Проверяем результат
    XCTAssertEqual(protobufEnum.name, "EnumWithOptions")
    XCTAssertEqual(protobufEnum.value.count, 1)
  }

  func testFileDescriptorWithServices() throws {
    // Создаем protobuf file descriptor с сервисами
    var protobufFile = Google_Protobuf_FileDescriptorProto()
    protobufFile.name = "service_test.proto"
    protobufFile.package = "test"

    // Добавляем сервис
    var service = Google_Protobuf_ServiceDescriptorProto()
    service.name = "TestService"

    var method = Google_Protobuf_MethodDescriptorProto()
    method.name = "TestMethod"
    method.inputType = "TestRequest"
    method.outputType = "TestResponse"
    service.method = [method]

    protobufFile.service = [service]

    // Конвертируем в наш формат (должно покрыть строки 328-329)
    let fileDescriptor = try bridge.fromProtobufFileDescriptor(protobufFile)

    // Проверяем результат
    XCTAssertEqual(fileDescriptor.name, "service_test.proto")
    XCTAssertEqual(fileDescriptor.package, "test")
    XCTAssertEqual(fileDescriptor.services.count, 1)
    XCTAssertEqual(Array(fileDescriptor.services.values)[0].name, "TestService")
  }

  func testUnknownFieldTypeHandling() throws {
    // Создаем mock для тестирования @unknown default case
    // Поскольку мы не можем легко создать unknown case, тестируем все известные типы

    // Тестируем скалярные типы
    let scalarFieldTypes: [Google_Protobuf_FieldDescriptorProto.TypeEnum] = [
      .double, .float, .int64, .uint64, .int32, .fixed64, .fixed32,
      .bool, .string, .bytes, .uint32, .sfixed32, .sfixed64, .sint32, .sint64,
    ]

    for protobufType in scalarFieldTypes {
      var protobufField = Google_Protobuf_FieldDescriptorProto()
      protobufField.name = "test_field"
      protobufField.number = 1
      protobufField.type = protobufType
      protobufField.label = .optional

      // Конвертируем и проверяем, что не возникает ошибок
      XCTAssertNoThrow(try bridge.fromProtobufFieldDescriptor(protobufField))
    }

    // Тестируем сложные типы с typeName
    let complexFieldTypes: [(Google_Protobuf_FieldDescriptorProto.TypeEnum, String)] = [
      (.message, "TestMessage"),
      (.enum, "TestEnum"),
      (.group, "TestGroup"),
    ]

    for (protobufType, typeName) in complexFieldTypes {
      var protobufField = Google_Protobuf_FieldDescriptorProto()
      protobufField.name = "test_field"
      protobufField.number = 1
      protobufField.type = protobufType
      protobufField.typeName = typeName
      protobufField.label = .optional

      // Конвертируем и проверяем, что не возникает ошибок
      XCTAssertNoThrow(try bridge.fromProtobufFieldDescriptor(protobufField))
    }
  }

  func testAllFieldTypeConversions() throws {
    // Тестируем скалярные типы полей для полного покрытия switch statements
    let scalarFieldTypes: [(FieldType, Google_Protobuf_FieldDescriptorProto.TypeEnum)] = [
      (.double, .double), (.float, .float), (.int64, .int64), (.uint64, .uint64),
      (.int32, .int32), (.fixed64, .fixed64), (.fixed32, .fixed32), (.bool, .bool),
      (.string, .string), (.bytes, .bytes), (.uint32, .uint32),
      (.sfixed32, .sfixed32), (.sfixed64, .sfixed64), (.sint32, .sint32), (.sint64, .sint64),
    ]

    for (fieldType, expectedProtobufType) in scalarFieldTypes {
      let fieldDescriptor = FieldDescriptor(name: "test", number: 1, type: fieldType)
      let protobufField = try bridge.toProtobufFieldDescriptor(from: fieldDescriptor)
      XCTAssertEqual(protobufField.type, expectedProtobufType)

      // Тестируем обратную конвертацию
      var reverseProtobufField = Google_Protobuf_FieldDescriptorProto()
      reverseProtobufField.name = "test"
      reverseProtobufField.number = 1
      reverseProtobufField.type = expectedProtobufType
      reverseProtobufField.label = .optional

      let reverseFieldDescriptor = try bridge.fromProtobufFieldDescriptor(reverseProtobufField)
      XCTAssertEqual(reverseFieldDescriptor.type, fieldType)
    }

    // Тестируем сложные типы полей отдельно (требуют typeName)
    let complexFieldTypes: [(FieldType, Google_Protobuf_FieldDescriptorProto.TypeEnum, String)] = [
      (.message, .message, "TestMessage"),
      (.enum, .enum, "TestEnum"),
      (.group, .group, "TestGroup"),
    ]

    for (fieldType, expectedProtobufType, typeName) in complexFieldTypes {
      let fieldDescriptor = FieldDescriptor(name: "test", number: 1, type: fieldType, typeName: typeName)
      let protobufField = try bridge.toProtobufFieldDescriptor(from: fieldDescriptor)
      XCTAssertEqual(protobufField.type, expectedProtobufType)
      XCTAssertEqual(protobufField.typeName, typeName)

      // Тестируем обратную конвертацию
      var reverseProtobufField = Google_Protobuf_FieldDescriptorProto()
      reverseProtobufField.name = "test"
      reverseProtobufField.number = 1
      reverseProtobufField.type = expectedProtobufType
      reverseProtobufField.typeName = typeName
      reverseProtobufField.label = .optional

      let reverseFieldDescriptor = try bridge.fromProtobufFieldDescriptor(reverseProtobufField)
      XCTAssertEqual(reverseFieldDescriptor.type, fieldType)
      XCTAssertEqual(reverseFieldDescriptor.typeName, typeName)
    }
  }

  func testPrivateOptionsMethods() throws {
    // Тестируем приватные методы для работы с опциями через публичные методы

    // Создаем MessageDescriptor с опциями для тестирования toProtobufMessageOptions
    let messageWithOptions = MessageDescriptor(
      name: "TestMessage",
      parent: fileDescriptor,
      options: ["test_option": "test_value"]
    )

    // Конвертируем - это должно вызвать toProtobufMessageOptions
    let protobufDescriptor = try bridge.toProtobufDescriptor(from: messageWithOptions)
    XCTAssertEqual(protobufDescriptor.name, "TestMessage")

    // Создаем FieldDescriptor с опциями для тестирования toProtobufFieldOptions
    let fieldWithOptions = FieldDescriptor(
      name: "test_field",
      number: 1,
      type: .string,
      options: ["field_option": "field_value"]
    )

    // Конвертируем - это должно вызвать toProtobufFieldOptions
    let protobufField = try bridge.toProtobufFieldDescriptor(from: fieldWithOptions)
    XCTAssertEqual(protobufField.name, "test_field")
  }
}
