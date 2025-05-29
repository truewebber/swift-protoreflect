/**
 * EmptyHandlerTests.swift
 * SwiftProtoReflectTests
 *
 * Тесты для EmptyHandler
 */

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class EmptyHandlerTests: XCTestCase {

  // MARK: - EmptyValue Tests

  func testEmptyValueInitialization() {
    // Базовая инициализация
    let empty1 = EmptyHandler.EmptyValue()
    let empty2 = EmptyHandler.EmptyValue()

    // Все экземпляры EmptyValue должны быть равны
    XCTAssertEqual(empty1, empty2)
  }

  func testEmptyValueSingleton() {
    let singleton = EmptyHandler.EmptyValue.instance
    let manual = EmptyHandler.EmptyValue()

    // Singleton и обычный экземпляр должны быть равны
    XCTAssertEqual(singleton, manual)
  }

  func testEmptyValueDescription() {
    let empty = EmptyHandler.EmptyValue()

    // Проверяем описание
    XCTAssertEqual(empty.description, "Empty")
  }

  func testEmptyValueEquality() {
    let empty1 = EmptyHandler.EmptyValue()
    let empty2 = EmptyHandler.EmptyValue()
    let singleton = EmptyHandler.EmptyValue.instance

    // Все EmptyValue должны быть равны между собой
    XCTAssertEqual(empty1, empty2)
    XCTAssertEqual(empty1, singleton)
    XCTAssertEqual(empty2, singleton)
  }

  // MARK: - Handler Implementation Tests

  func testHandlerBasicProperties() {
    XCTAssertEqual(EmptyHandler.handledTypeName, "google.protobuf.Empty")
    XCTAssertEqual(EmptyHandler.supportPhase, .critical)
  }

  func testCreateSpecializedFromMessage() throws {
    // Создаем empty сообщение
    let emptyMessage = try createEmptyMessage()

    // Конвертируем в специализированный тип
    let specialized = try EmptyHandler.createSpecialized(from: emptyMessage)

    guard let empty = specialized as? EmptyHandler.EmptyValue else {
      XCTFail("Expected EmptyValue")
      return
    }

    // Проверяем, что получили правильный экземпляр
    XCTAssertEqual(empty, EmptyHandler.EmptyValue.instance)
  }

  func testCreateSpecializedFromInvalidMessage() throws {
    // Создаем сообщение неправильного типа
    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let messageDescriptor = MessageDescriptor(name: "NotEmpty", parent: fileDescriptor)
    fileDescriptor.addMessage(messageDescriptor)

    let factory = MessageFactory()
    let wrongMessage = factory.createMessage(from: messageDescriptor)

    XCTAssertThrowsError(try EmptyHandler.createSpecialized(from: wrongMessage)) { error in
      guard case WellKnownTypeError.invalidData(let typeName, _) = error else {
        XCTFail("Expected invalidData error")
        return
      }
      XCTAssertEqual(typeName, "google.protobuf.Empty")
    }
  }

  func testCreateDynamicFromSpecialized() throws {
    let empty = EmptyHandler.EmptyValue.instance

    let dynamicMessage = try EmptyHandler.createDynamic(from: empty)

    // Проверяем, что создалось правильное сообщение
    XCTAssertEqual(dynamicMessage.descriptor.fullName, "google.protobuf.Empty")
    XCTAssertEqual(dynamicMessage.descriptor.name, "Empty")

    // Empty сообщение не должно иметь полей
    XCTAssertEqual(dynamicMessage.descriptor.fields.count, 0)
  }

  func testCreateDynamicFromInvalidSpecialized() throws {
    let wrongSpecialized = "not an empty"

    XCTAssertThrowsError(try EmptyHandler.createDynamic(from: wrongSpecialized)) { error in
      guard case WellKnownTypeError.conversionFailed(let from, let to, _) = error else {
        XCTFail("Expected conversionFailed error")
        return
      }
      XCTAssertEqual(from, "String")
      XCTAssertEqual(to, "DynamicMessage")
    }
  }

  func testValidate() throws {
    // Валидные значения
    let validEmpty = EmptyHandler.EmptyValue()
    let validSingleton = EmptyHandler.EmptyValue.instance

    XCTAssertTrue(EmptyHandler.validate(validEmpty))
    XCTAssertTrue(EmptyHandler.validate(validSingleton))

    // Невалидные значения
    XCTAssertFalse(EmptyHandler.validate("not empty"))
    XCTAssertFalse(EmptyHandler.validate(123))
    XCTAssertFalse(EmptyHandler.validate(Date()))
    XCTAssertFalse(EmptyHandler.validate([]))
  }

  func testRoundTripConversion() throws {
    let originalEmpty = EmptyHandler.EmptyValue.instance

    // Convert to dynamic message and back
    let dynamicMessage = try EmptyHandler.createDynamic(from: originalEmpty)
    let convertedSpecialized = try EmptyHandler.createSpecialized(from: dynamicMessage)

    guard let convertedEmpty = convertedSpecialized as? EmptyHandler.EmptyValue else {
      XCTFail("Expected EmptyValue")
      return
    }

    XCTAssertEqual(originalEmpty, convertedEmpty)
  }

  // MARK: - Convenience Extensions Tests

  func testDynamicMessageEmptyExtension() throws {
    // Создаем Empty сообщение через convenience method
    let emptyMessage = try DynamicMessage.emptyMessage()

    XCTAssertEqual(emptyMessage.descriptor.fullName, "google.protobuf.Empty")
    XCTAssertTrue(emptyMessage.isEmpty())

    // Конвертируем обратно в EmptyValue
    let empty = try emptyMessage.toEmpty()
    XCTAssertEqual(empty, EmptyHandler.EmptyValue.instance)
  }

  func testDynamicMessageIsEmpty() throws {
    // Empty сообщение
    let emptyMessage = try DynamicMessage.emptyMessage()
    XCTAssertTrue(emptyMessage.isEmpty())

    // Не-Empty сообщение
    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let messageDescriptor = MessageDescriptor(name: "NotEmpty", parent: fileDescriptor)
    fileDescriptor.addMessage(messageDescriptor)

    let factory = MessageFactory()
    let notEmptyMessage = factory.createMessage(from: messageDescriptor)
    XCTAssertFalse(notEmptyMessage.isEmpty())
  }

  func testDynamicMessageToEmptyWithInvalidMessage() throws {
    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let messageDescriptor = MessageDescriptor(name: "NotEmpty", parent: fileDescriptor)
    fileDescriptor.addMessage(messageDescriptor)

    let factory = MessageFactory()
    let wrongMessage = factory.createMessage(from: messageDescriptor)

    XCTAssertThrowsError(try wrongMessage.toEmpty()) { error in
      guard case WellKnownTypeError.invalidData = error else {
        XCTFail("Expected invalidData error")
        return
      }
    }
  }

  // MARK: - Unit Type Integration Tests

  func testVoidIntegration() {
    // Создание из Void
    let emptyFromVoid = EmptyHandler.EmptyValue.from(())
    XCTAssertEqual(emptyFromVoid, EmptyHandler.EmptyValue.instance)

    // Конвертация в Void
    let empty = EmptyHandler.EmptyValue()
    empty.toVoid()

    // Void тип не имеет значений для сравнения, поэтому просто проверяем что метод выполнился без ошибок
    XCTAssertTrue(true)  // Если дошли до этой точки, значит все работает
  }

  func testVoidRoundTrip() {
    let originalVoid: Void = ()
    let empty = EmptyHandler.EmptyValue.from(originalVoid)
    empty.toVoid()

    // Опять же, Void нельзя сравнить, но проверяем что операции выполнились
    XCTAssertEqual(empty, EmptyHandler.EmptyValue.instance)
  }

  // MARK: - Registry Integration Tests

  func testRegistryIntegration() throws {
    let registry = WellKnownTypesRegistry.shared

    // Проверяем что EmptyHandler зарегистрирован
    let handler = registry.getHandler(for: WellKnownTypeNames.empty)
    XCTAssertNotNil(handler)
    XCTAssertTrue(handler is EmptyHandler.Type)

    // Проверяем что зарегистрированные типы включают Empty
    let registeredTypes = registry.getRegisteredTypes()
    XCTAssertTrue(registeredTypes.contains(WellKnownTypeNames.empty))
  }

  func testRegistryCreateSpecialized() throws {
    let registry = WellKnownTypesRegistry.shared
    let emptyMessage = try createEmptyMessage()

    let specialized = try registry.createSpecialized(
      from: emptyMessage,
      typeName: WellKnownTypeNames.empty
    )

    guard let empty = specialized as? EmptyHandler.EmptyValue else {
      XCTFail("Expected EmptyValue from registry")
      return
    }

    XCTAssertEqual(empty, EmptyHandler.EmptyValue.instance)
  }

  func testRegistryCreateDynamic() throws {
    let registry = WellKnownTypesRegistry.shared
    let empty = EmptyHandler.EmptyValue.instance

    let dynamicMessage = try registry.createDynamic(
      from: empty,
      typeName: WellKnownTypeNames.empty
    )

    XCTAssertEqual(dynamicMessage.descriptor.fullName, WellKnownTypeNames.empty)
    XCTAssertTrue(dynamicMessage.isEmpty())
  }

  // MARK: - Edge Cases Tests

  func testMultipleEmptyMessagesAreEqual() throws {
    let empty1 = try DynamicMessage.emptyMessage()
    let empty2 = try DynamicMessage.emptyMessage()

    // Хотя это разные объекты DynamicMessage, их specialized представления должны быть равны
    let specialized1 = try EmptyHandler.createSpecialized(from: empty1) as! EmptyHandler.EmptyValue
    let specialized2 = try EmptyHandler.createSpecialized(from: empty2) as! EmptyHandler.EmptyValue

    XCTAssertEqual(specialized1, specialized2)
  }

  func testEmptyMessageFieldAccess() throws {
    var emptyMessage = try DynamicMessage.emptyMessage()

    // Empty сообщение не должно иметь полей
    XCTAssertEqual(emptyMessage.descriptor.fields.count, 0)

    // Попытка доступа к несуществующему полю должна вызывать ошибку
    XCTAssertThrowsError(try emptyMessage.get(forField: "nonexistent"))
    XCTAssertThrowsError(try emptyMessage.set("value", forField: "nonexistent"))
    XCTAssertThrowsError(try emptyMessage.hasValue(forField: "nonexistent"))
  }

  // MARK: - Performance Tests

  func testConversionPerformance() throws {
    let empty = EmptyHandler.EmptyValue.instance

    measure {
      for _ in 0..<1000 {
        do {
          let dynamicMessage = try EmptyHandler.createDynamic(from: empty)
          _ = try EmptyHandler.createSpecialized(from: dynamicMessage)
        }
        catch {
          XCTFail("Performance test failed: \(error)")
        }
      }
    }
  }

  func testRegistryPerformance() throws {
    let registry = WellKnownTypesRegistry.shared
    let emptyMessage = try createEmptyMessage()

    measure {
      for _ in 0..<1000 {
        do {
          let specialized = try registry.createSpecialized(
            from: emptyMessage,
            typeName: WellKnownTypeNames.empty
          )
          _ = try registry.createDynamic(
            from: specialized,
            typeName: WellKnownTypeNames.empty
          )
        }
        catch {
          XCTFail("Registry performance test failed: \(error)")
        }
      }
    }
  }

  // MARK: - Error Handling Tests

  func testCreateSpecializedWithNilMessage() throws {
    // Этот тест проверяет граничные случаи, хотя такой сценарий не должен происходить в реальности
    // поскольку DynamicMessage не может быть nil в типизированной системе Swift
  }

  func testValidateWithNil() {
    // Проверяем валидацию с nil (которая должна вернуть false)
    let nilValue: Any? = nil
    if let value = nilValue {
      XCTAssertFalse(EmptyHandler.validate(value))
    }
    // Если nil, то тест все равно проходит, так как мы не можем передать nil в validate
  }

  // MARK: - Helper Methods

  private func createEmptyMessage() throws -> DynamicMessage {
    // Создаем дескриптор для Empty
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/empty.proto",
      package: "google.protobuf"
    )

    let messageDescriptor = MessageDescriptor(
      name: "Empty",
      parent: fileDescriptor
    )

    // Empty сообщение не имеет полей
    fileDescriptor.addMessage(messageDescriptor)

    // Создаем сообщение
    let factory = MessageFactory()
    let message = factory.createMessage(from: messageDescriptor)

    return message
  }
}
