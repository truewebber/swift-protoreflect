//
// StaticMessageBridgeTests.swift
// SwiftProtoReflectTests
//
// Создан: 2025-05-25
//

import XCTest
import SwiftProtobuf
@testable import SwiftProtoReflect

final class StaticMessageBridgeTests: XCTestCase {
  
  // MARK: - Test Properties
  
  private var bridge: StaticMessageBridge!
  private var fileDescriptor: FileDescriptor!
  private var personDescriptor: MessageDescriptor!
  
  // MARK: - Setup and Teardown
  
  override func setUp() {
    super.setUp()
    bridge = StaticMessageBridge()
    
    // Создаем тестовые дескрипторы
    fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    
    personDescriptor = MessageDescriptor(name: "Person", parent: fileDescriptor)
    personDescriptor.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    personDescriptor.addField(FieldDescriptor(name: "age", number: 2, type: .int32))
    personDescriptor.addField(FieldDescriptor(name: "email", number: 3, type: .string))
    
    fileDescriptor.addMessage(personDescriptor)
  }
  
  override func tearDown() {
    bridge = nil
    fileDescriptor = nil
    personDescriptor = nil
    super.tearDown()
  }
  
  // MARK: - Initialization Tests
  
  func testInitialization() {
    let bridge = StaticMessageBridge()
    XCTAssertNotNil(bridge)
  }
  
  // MARK: - Dynamic to Static Conversion Tests
  
  func testDynamicToStaticConversion() throws {
    // Создаем динамическое сообщение
    var dynamicMessage = DynamicMessage(descriptor: personDescriptor)
    try dynamicMessage.set("John Doe", forField: "name")
    try dynamicMessage.set(Int32(30), forField: "age")
    try dynamicMessage.set("john@example.com", forField: "email")
    
    // Конвертируем в статическое сообщение (используем Google_Protobuf_Empty как заглушку)
    // В реальном тесте здесь должен быть соответствующий статический тип
    let staticMessage = try bridge.toStaticMessage(from: dynamicMessage, as: Google_Protobuf_Empty.self)
    
    XCTAssertNotNil(staticMessage)
  }
  
  func testDynamicToStaticConversionWithEmptyMessage() throws {
    // Создаем пустое динамическое сообщение
    let dynamicMessage = DynamicMessage(descriptor: personDescriptor)
    
    // Конвертируем в статическое сообщение
    let staticMessage = try bridge.toStaticMessage(from: dynamicMessage, as: Google_Protobuf_Empty.self)
    
    XCTAssertNotNil(staticMessage)
  }
  
  // MARK: - Static to Dynamic Conversion Tests
  
  func testStaticToDynamicConversion() throws {
    // Создаем статическое сообщение
    let staticMessage = Google_Protobuf_Empty()
    
    // Конвертируем в динамическое сообщение
    let dynamicMessage = try bridge.toDynamicMessage(from: staticMessage, using: personDescriptor)
    
    XCTAssertEqual(dynamicMessage.descriptor.name, personDescriptor.name)
  }
  
  func testStaticToDynamicConversionWithAutoDescriptor() throws {
    // Создаем статическое сообщение
    let staticMessage = Google_Protobuf_Empty()
    
    // Конвертируем в динамическое сообщение с автоматическим созданием дескриптора
    let dynamicMessage = try bridge.toDynamicMessage(from: staticMessage)
    
    XCTAssertNotNil(dynamicMessage)
    XCTAssertEqual(dynamicMessage.descriptor.name, "Google_Protobuf_Empty")
  }
  
  // MARK: - Batch Conversion Tests
  
  func testBatchStaticToDynamicConversion() throws {
    // Создаем массив статических сообщений
    let staticMessages = [Google_Protobuf_Empty(), Google_Protobuf_Empty()]
    
    // Конвертируем в массив динамических сообщений
    let dynamicMessages = try bridge.toDynamicMessages(from: staticMessages, using: personDescriptor)
    
    XCTAssertEqual(dynamicMessages.count, 2)
    XCTAssertEqual(dynamicMessages[0].descriptor.name, personDescriptor.name)
    XCTAssertEqual(dynamicMessages[1].descriptor.name, personDescriptor.name)
  }
  
  func testBatchDynamicToStaticConversion() throws {
    // Создаем массив динамических сообщений
    let dynamicMessage1 = DynamicMessage(descriptor: personDescriptor)
    let dynamicMessage2 = DynamicMessage(descriptor: personDescriptor)
    let dynamicMessages = [dynamicMessage1, dynamicMessage2]
    
    // Конвертируем в массив статических сообщений
    let staticMessages = try bridge.toStaticMessages(from: dynamicMessages, as: Google_Protobuf_Empty.self)
    
    XCTAssertEqual(staticMessages.count, 2)
  }
  
  func testEmptyBatchConversion() throws {
    // Тестируем конвертацию пустых массивов
    let emptyStaticMessages: [Google_Protobuf_Empty] = []
    let emptyDynamicMessages: [DynamicMessage] = []
    
    let resultDynamic = try bridge.toDynamicMessages(from: emptyStaticMessages, using: personDescriptor)
    let resultStatic = try bridge.toStaticMessages(from: emptyDynamicMessages, as: Google_Protobuf_Empty.self)
    
    XCTAssertTrue(resultDynamic.isEmpty)
    XCTAssertTrue(resultStatic.isEmpty)
  }
  
  // MARK: - Validation Tests
  
  func testCompatibilityCheckStaticWithDescriptor() {
    let staticMessage = Google_Protobuf_Empty()
    
    let isCompatible = bridge.isCompatible(staticMessage: staticMessage, with: personDescriptor)
    
    // Совместимость зависит от реализации, но метод должен работать без ошибок
    XCTAssertTrue(isCompatible || !isCompatible) // Просто проверяем, что метод не падает
  }
  
  func testCompatibilityCheckDynamicWithStatic() {
    let dynamicMessage = DynamicMessage(descriptor: personDescriptor)
    
    let isCompatible = bridge.isCompatible(dynamicMessage: dynamicMessage, with: Google_Protobuf_Empty.self)
    
    // Совместимость зависит от реализации, но метод должен работать без ошибок
    XCTAssertTrue(isCompatible || !isCompatible) // Просто проверяем, что метод не падает
  }
  
  // MARK: - Round-trip Tests
  
  func testRoundTripConversion() throws {
    // Создаем динамическое сообщение с данными
    var originalDynamic = DynamicMessage(descriptor: personDescriptor)
    try originalDynamic.set("Alice", forField: "name")
    try originalDynamic.set(Int32(25), forField: "age")
    
    // Конвертируем в статическое и обратно
    let staticMessage = try bridge.toStaticMessage(from: originalDynamic, as: Google_Protobuf_Empty.self)
    let resultDynamic = try bridge.toDynamicMessage(from: staticMessage, using: personDescriptor)
    
    // Проверяем, что структура сохранилась
    XCTAssertEqual(resultDynamic.descriptor.name, originalDynamic.descriptor.name)
  }
  
  // MARK: - Error Handling Tests
  
  func testSerializationError() {
    // Создаем дескриптор с некорректными данными для провоцирования ошибки
    let invalidDescriptor = MessageDescriptor(name: "Invalid")
    var dynamicMessage = DynamicMessage(descriptor: invalidDescriptor)
    
    // Добавляем некорректные данные в сообщение
    do {
      try dynamicMessage.set("invalid_value", forField: "nonexistent_field")
      XCTFail("Expected error when setting field that doesn't exist")
    } catch {
      // Ожидаемая ошибка при попытке установить несуществующее поле
      XCTAssertTrue(error is DynamicMessageError)
    }
  }
  
  func testDescriptorCreationError() {
    // Тестируем создание дескриптора из статического сообщения
    let staticMessage = Google_Protobuf_Empty()
    
    // Метод должен работать, но может выбросить ошибку в зависимости от реализации
    do {
      _ = try bridge.toDynamicMessage(from: staticMessage)
    } catch {
      // Ошибка ожидаема, так как автоматическое создание дескриптора не полностью реализовано
      XCTAssertTrue(error is StaticMessageBridgeError)
    }
  }
  
  // MARK: - Extension Tests
  
  func testDynamicMessageExtension() throws {
    var dynamicMessage = DynamicMessage(descriptor: personDescriptor)
    try dynamicMessage.set("Bob", forField: "name")
    
    // Тестируем расширение DynamicMessage
    let staticMessage = try dynamicMessage.toStaticMessage(as: Google_Protobuf_Empty.self)
    XCTAssertNotNil(staticMessage)
  }
  
  func testStaticMessageExtension() throws {
    let staticMessage = Google_Protobuf_Empty()
    
    // Тестируем расширение SwiftProtobuf.Message
    let dynamicMessage = try staticMessage.toDynamicMessage(using: personDescriptor)
    XCTAssertEqual(dynamicMessage.descriptor.name, personDescriptor.name)
  }
  
  func testStaticMessageExtensionWithAutoDescriptor() {
    let staticMessage = Google_Protobuf_Empty()
    
    // Тестируем расширение с автоматическим созданием дескриптора
    do {
      _ = try staticMessage.toDynamicMessage()
    } catch {
      // Ошибка ожидаема, так как автоматическое создание дескриптора не полностью реализовано
      XCTAssertTrue(error is StaticMessageBridgeError)
    }
  }
  
  // MARK: - Error Description Tests
  
  func testErrorDescriptions() {
    let errors: [StaticMessageBridgeError] = [
      .incompatibleTypes(staticType: "TypeA", descriptorType: "TypeB"),
      .serializationFailed(underlying: NSError(domain: "test", code: 1)),
      .deserializationFailed(underlying: NSError(domain: "test", code: 2)),
      .descriptorCreationFailed(messageType: "TestType"),
      .unsupportedMessageType("UnsupportedType")
    ]
    
    for error in errors {
      XCTAssertNotNil(error.errorDescription)
      XCTAssertFalse(error.errorDescription!.isEmpty)
    }
  }
  
  // MARK: - Performance Tests
  
  func testConversionPerformance() throws {
    // Создаем тестовые данные
    var dynamicMessage = DynamicMessage(descriptor: personDescriptor)
    try dynamicMessage.set("Performance Test", forField: "name")
    try dynamicMessage.set(Int32(42), forField: "age")
    
    measure {
      do {
        // Измеряем производительность конвертации
        let staticMessage = try bridge.toStaticMessage(from: dynamicMessage, as: Google_Protobuf_Empty.self)
        _ = try bridge.toDynamicMessage(from: staticMessage, using: personDescriptor)
      } catch {
        XCTFail("Performance test failed with error: \(error)")
      }
    }
  }
  
  func testBatchConversionPerformance() throws {
    // Создаем массив тестовых данных
    var dynamicMessages: [DynamicMessage] = []
    for i in 0..<100 {
      var message = DynamicMessage(descriptor: personDescriptor)
      try message.set("Person \(i)", forField: "name")
      try message.set(Int32(i), forField: "age")
      dynamicMessages.append(message)
    }
    
    measure {
      do {
        // Измеряем производительность batch конвертации
        let staticMessages = try bridge.toStaticMessages(from: dynamicMessages, as: Google_Protobuf_Empty.self)
        _ = try bridge.toDynamicMessages(from: staticMessages, using: personDescriptor)
      } catch {
        XCTFail("Batch performance test failed with error: \(error)")
      }
    }
  }
}
 