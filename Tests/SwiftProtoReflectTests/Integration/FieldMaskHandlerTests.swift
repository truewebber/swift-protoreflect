/**
 * FieldMaskHandlerTests.swift
 * SwiftProtoReflectTests
 *
 * Тесты для FieldMaskHandler
 */

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class FieldMaskHandlerTests: XCTestCase {

  // MARK: - FieldMaskValue Tests

  func testFieldMaskValueInitialization() {
    // Валидная инициализация
    XCTAssertNoThrow(try FieldMaskHandler.FieldMaskValue(paths: ["name", "age", "address.city"]))
    XCTAssertNoThrow(try FieldMaskHandler.FieldMaskValue(paths: []))
    XCTAssertNoThrow(try FieldMaskHandler.FieldMaskValue(path: "user.name"))

    // Пустая маска
    let emptyMask = FieldMaskHandler.FieldMaskValue()
    XCTAssertEqual(emptyMask.paths, [])

    // Невалидные пути
    XCTAssertThrowsError(try FieldMaskHandler.FieldMaskValue(paths: [""])) { error in
      guard case WellKnownTypeError.invalidData(let typeName, let reason) = error else {
        XCTFail("Expected invalidData error")
        return
      }
      XCTAssertEqual(typeName, "google.protobuf.FieldMask")
      XCTAssertTrue(reason.contains("Invalid field path"))
    }

    XCTAssertThrowsError(try FieldMaskHandler.FieldMaskValue(paths: ["invalid-path"])) { error in
      guard case WellKnownTypeError.invalidData = error else {
        XCTFail("Expected invalidData error")
        return
      }
    }

    XCTAssertThrowsError(try FieldMaskHandler.FieldMaskValue(paths: ["field with spaces"])) { error in
      guard case WellKnownTypeError.invalidData = error else {
        XCTFail("Expected invalidData error")
        return
      }
    }
  }

  func testFieldMaskValueContains() {
    do {
      let fieldMask = try FieldMaskHandler.FieldMaskValue(paths: ["name", "age", "address.city"])

      XCTAssertTrue(fieldMask.contains("name"))
      XCTAssertTrue(fieldMask.contains("age"))
      XCTAssertTrue(fieldMask.contains("address.city"))
      XCTAssertFalse(fieldMask.contains("address"))
      XCTAssertFalse(fieldMask.contains("nonexistent"))
    }
    catch {
      XCTFail("Failed to create field mask: \(error)")
    }
  }

  func testFieldMaskValueCovers() {
    do {
      let fieldMask = try FieldMaskHandler.FieldMaskValue(paths: ["name", "address"])

      // Точные совпадения
      XCTAssertTrue(fieldMask.covers("name"))
      XCTAssertTrue(fieldMask.covers("address"))

      // Дочерние пути должны покрываться родительскими
      XCTAssertTrue(fieldMask.covers("address.city"))
      XCTAssertTrue(fieldMask.covers("address.street.number"))

      // Непокрытые пути
      XCTAssertFalse(fieldMask.covers("age"))
      XCTAssertFalse(fieldMask.covers("contact.email"))
    }
    catch {
      XCTFail("Failed to create field mask: \(error)")
    }
  }

  func testFieldMaskValueAdding() {
    do {
      let originalMask = try FieldMaskHandler.FieldMaskValue(paths: ["name"])

      // Добавление валидного пути
      let updatedMask = try originalMask.adding("age")
      XCTAssertTrue(updatedMask.contains("name"))
      XCTAssertTrue(updatedMask.contains("age"))

      // Добавление существующего пути (не должно дублироваться)
      let sameMask = try originalMask.adding("name")
      XCTAssertEqual(sameMask.paths.count, 1)
      XCTAssertTrue(sameMask.contains("name"))

      // Добавление невалидного пути
      XCTAssertThrowsError(try originalMask.adding("invalid-path")) { error in
        guard case WellKnownTypeError.invalidData = error else {
          XCTFail("Expected invalidData error")
          return
        }
      }
    }
    catch {
      XCTFail("Failed to create field mask: \(error)")
    }
  }

  func testFieldMaskValueRemoving() {
    do {
      let originalMask = try FieldMaskHandler.FieldMaskValue(paths: ["name", "age", "address"])

      let updatedMask = originalMask.removing("age")
      XCTAssertTrue(updatedMask.contains("name"))
      XCTAssertFalse(updatedMask.contains("age"))
      XCTAssertTrue(updatedMask.contains("address"))

      // Удаление несуществующего пути
      let sameMask = originalMask.removing("nonexistent")
      XCTAssertEqual(sameMask.paths.count, 3)
    }
    catch {
      XCTFail("Failed to create field mask: \(error)")
    }
  }

  func testFieldMaskValueUnion() {
    do {
      let mask1 = try FieldMaskHandler.FieldMaskValue(paths: ["name", "age"])
      let mask2 = try FieldMaskHandler.FieldMaskValue(paths: ["age", "address"])

      let unionMask = mask1.union(mask2)
      XCTAssertEqual(unionMask.paths.sorted(), ["address", "age", "name"])
    }
    catch {
      XCTFail("Failed to create field masks: \(error)")
    }
  }

  func testFieldMaskValueIntersection() {
    do {
      let mask1 = try FieldMaskHandler.FieldMaskValue(paths: ["name", "age", "address"])
      let mask2 = try FieldMaskHandler.FieldMaskValue(paths: ["age", "address", "phone"])

      let intersectionMask = mask1.intersection(mask2)
      XCTAssertEqual(intersectionMask.paths.sorted(), ["address", "age"])
    }
    catch {
      XCTFail("Failed to create field masks: \(error)")
    }
  }

  func testFieldMaskValueStaticMethods() {
    // Empty mask
    let emptyMask = FieldMaskHandler.FieldMaskValue.empty()
    XCTAssertEqual(emptyMask.paths, [])

    // With paths
    do {
      let mask = try FieldMaskHandler.FieldMaskValue.with(paths: ["name", "age"])
      XCTAssertEqual(mask.paths, ["name", "age"])
    }
    catch {
      XCTFail("Failed to create field mask: \(error)")
    }
  }

  func testFieldMaskValueDescription() {
    do {
      let emptyMask = FieldMaskHandler.FieldMaskValue.empty()
      XCTAssertEqual(emptyMask.description, "FieldMask(empty)")

      let mask = try FieldMaskHandler.FieldMaskValue(paths: ["name", "age"])
      XCTAssertEqual(mask.description, "FieldMask(name, age)")
    }
    catch {
      XCTFail("Failed to create field mask: \(error)")
    }
  }

  func testFieldMaskValueEquality() {
    do {
      let mask1 = try FieldMaskHandler.FieldMaskValue(paths: ["name", "age"])
      let mask2 = try FieldMaskHandler.FieldMaskValue(paths: ["name", "age"])
      let mask3 = try FieldMaskHandler.FieldMaskValue(paths: ["name"])

      XCTAssertEqual(mask1, mask2)
      XCTAssertNotEqual(mask1, mask3)
    }
    catch {
      XCTFail("Failed to create field masks: \(error)")
    }
  }

  // MARK: - Path Validation Tests

  func testPathValidation() {
    // Валидные пути
    XCTAssertTrue(FieldMaskHandler.FieldMaskValue.isValidPath("name"))
    XCTAssertTrue(FieldMaskHandler.FieldMaskValue.isValidPath("user_name"))
    XCTAssertTrue(FieldMaskHandler.FieldMaskValue.isValidPath("address.city"))
    XCTAssertTrue(FieldMaskHandler.FieldMaskValue.isValidPath("user.address.street_name"))
    XCTAssertTrue(FieldMaskHandler.FieldMaskValue.isValidPath("field123"))
    XCTAssertTrue(FieldMaskHandler.FieldMaskValue.isValidPath("FIELD_NAME"))

    // Невалидные пути
    XCTAssertFalse(FieldMaskHandler.FieldMaskValue.isValidPath(""))
    XCTAssertFalse(FieldMaskHandler.FieldMaskValue.isValidPath("field-name"))
    XCTAssertFalse(FieldMaskHandler.FieldMaskValue.isValidPath("field name"))
    XCTAssertFalse(FieldMaskHandler.FieldMaskValue.isValidPath("field@name"))
    XCTAssertFalse(FieldMaskHandler.FieldMaskValue.isValidPath("field/name"))
    XCTAssertFalse(FieldMaskHandler.FieldMaskValue.isValidPath("field+name"))
  }

  // MARK: - Handler Implementation Tests

  func testHandlerBasicProperties() {
    XCTAssertEqual(FieldMaskHandler.handledTypeName, "google.protobuf.FieldMask")
    XCTAssertEqual(FieldMaskHandler.supportPhase, .important)
  }

  func testCreateSpecializedFromMessage() throws {
    // Создаем FieldMask сообщение
    let fieldMaskMessage = try createFieldMaskMessage(paths: ["name", "age", "address.city"])

    // Конвертируем в специализированный тип
    let specialized = try FieldMaskHandler.createSpecialized(from: fieldMaskMessage)

    guard let fieldMask = specialized as? FieldMaskHandler.FieldMaskValue else {
      XCTFail("Expected FieldMaskValue")
      return
    }

    XCTAssertEqual(fieldMask.paths.sorted(), ["address.city", "age", "name"])
  }

  func testCreateSpecializedFromMessageWithEmptyPaths() throws {
    // Создаем сообщение с пустыми путями
    let fieldMaskMessage = try createFieldMaskMessage(paths: [])

    let specialized = try FieldMaskHandler.createSpecialized(from: fieldMaskMessage)

    guard let fieldMask = specialized as? FieldMaskHandler.FieldMaskValue else {
      XCTFail("Expected FieldMaskValue")
      return
    }

    XCTAssertEqual(fieldMask.paths, [])
  }

  func testCreateSpecializedFromMessageWithMissingField() throws {
    // Создаем сообщение без поля paths
    let fieldMaskMessage = try createFieldMaskMessage(paths: nil)

    let specialized = try FieldMaskHandler.createSpecialized(from: fieldMaskMessage)

    guard let fieldMask = specialized as? FieldMaskHandler.FieldMaskValue else {
      XCTFail("Expected FieldMaskValue")
      return
    }

    XCTAssertEqual(fieldMask.paths, [])
  }

  func testCreateSpecializedFromInvalidMessage() throws {
    // Создаем сообщение неправильного типа
    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let messageDescriptor = MessageDescriptor(name: "NotFieldMask", parent: fileDescriptor)
    fileDescriptor.addMessage(messageDescriptor)

    let factory = MessageFactory()
    let wrongMessage = factory.createMessage(from: messageDescriptor)

    XCTAssertThrowsError(try FieldMaskHandler.createSpecialized(from: wrongMessage)) { error in
      guard case WellKnownTypeError.invalidData(let typeName, _) = error else {
        XCTFail("Expected invalidData error")
        return
      }
      XCTAssertEqual(typeName, "google.protobuf.FieldMask")
    }
  }

  func testCreateDynamicFromSpecialized() throws {
    let fieldMask = try FieldMaskHandler.FieldMaskValue(paths: ["name", "age", "address.city"])

    let dynamicMessage = try FieldMaskHandler.createDynamic(from: fieldMask)

    XCTAssertEqual(dynamicMessage.descriptor.fullName, "google.protobuf.FieldMask")

    let paths = try dynamicMessage.get(forField: "paths") as! [String]
    XCTAssertEqual(paths.sorted(), ["address.city", "age", "name"])
  }

  func testCreateDynamicFromInvalidSpecialized() throws {
    let wrongSpecialized = "not a field mask"

    XCTAssertThrowsError(try FieldMaskHandler.createDynamic(from: wrongSpecialized)) { error in
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
    let validFieldMask = try FieldMaskHandler.FieldMaskValue(paths: ["name", "age"])
    XCTAssertTrue(FieldMaskHandler.validate(validFieldMask))

    let emptyFieldMask = FieldMaskHandler.FieldMaskValue.empty()
    XCTAssertTrue(FieldMaskHandler.validate(emptyFieldMask))

    // Невалидные значения
    XCTAssertFalse(FieldMaskHandler.validate("not a field mask"))
    XCTAssertFalse(FieldMaskHandler.validate(123))
    XCTAssertFalse(FieldMaskHandler.validate(["name", "age"]))
  }

  func testRoundTripConversion() throws {
    let originalFieldMask = try FieldMaskHandler.FieldMaskValue(paths: ["name", "age", "address.city"])

    // Convert to dynamic message and back
    let dynamicMessage = try FieldMaskHandler.createDynamic(from: originalFieldMask)
    let convertedSpecialized = try FieldMaskHandler.createSpecialized(from: dynamicMessage)

    guard let convertedFieldMask = convertedSpecialized as? FieldMaskHandler.FieldMaskValue else {
      XCTFail("Expected FieldMaskValue")
      return
    }

    XCTAssertEqual(originalFieldMask, convertedFieldMask)
  }

  // MARK: - Convenience Extensions Tests

  func testArrayExtension() throws {
    let paths = ["name", "age", "address.city"]
    let fieldMask = try paths.toFieldMaskValue()

    XCTAssertEqual(fieldMask.paths, paths)
  }

  func testArrayExtensionWithInvalidPaths() throws {
    let invalidPaths = ["name", "invalid-path"]

    XCTAssertThrowsError(try invalidPaths.toFieldMaskValue()) { error in
      guard case WellKnownTypeError.invalidData = error else {
        XCTFail("Expected invalidData error")
        return
      }
    }
  }

  func testDynamicMessageExtensions() throws {
    let paths = ["name", "age", "address.city"]

    let fieldMaskMessage = try DynamicMessage.fieldMaskMessage(from: paths)
    XCTAssertEqual(fieldMaskMessage.descriptor.fullName, "google.protobuf.FieldMask")

    let convertedPaths = try fieldMaskMessage.toFieldPaths()
    XCTAssertEqual(convertedPaths.sorted(), paths.sorted())
  }

  func testDynamicMessageToFieldPathsWithInvalidMessage() throws {
    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let messageDescriptor = MessageDescriptor(name: "NotFieldMask", parent: fileDescriptor)
    fileDescriptor.addMessage(messageDescriptor)

    let factory = MessageFactory()
    let wrongMessage = factory.createMessage(from: messageDescriptor)

    XCTAssertThrowsError(try wrongMessage.toFieldPaths()) { error in
      guard case WellKnownTypeError.invalidData = error else {
        XCTFail("Expected invalidData error")
        return
      }
    }
  }

  // MARK: - Edge Cases Tests

  func testComplexPaths() throws {
    let complexPaths = [
      "user.personal_info.name",
      "user.address.street_address.line1",
      "metadata.creation_timestamp",
      "settings.notification_preferences.email_enabled",
    ]

    let fieldMask = try FieldMaskHandler.FieldMaskValue(paths: complexPaths)
    XCTAssertEqual(fieldMask.paths, complexPaths)

    // Тестируем covers для сложных путей
    XCTAssertTrue(fieldMask.covers("user.personal_info.name"))
    XCTAssertTrue(fieldMask.covers("user.address.street_address.line1"))
    XCTAssertFalse(fieldMask.covers("user.personal_info.age"))
  }

  func testLargePaths() throws {
    // Тестируем с большим количеством путей
    let largePaths = (1...100).map { "field\($0)" }
    let fieldMask = try FieldMaskHandler.FieldMaskValue(paths: largePaths)

    XCTAssertEqual(fieldMask.paths.count, 100)
    XCTAssertTrue(fieldMask.contains("field50"))
    XCTAssertFalse(fieldMask.contains("field101"))
  }

  func testDuplicatePathsInOperations() throws {
    let mask1 = try FieldMaskHandler.FieldMaskValue(paths: ["name", "age"])
    let mask2 = try FieldMaskHandler.FieldMaskValue(paths: ["name", "address"])

    // Union должен удалить дубликаты
    let unionMask = mask1.union(mask2)
    XCTAssertEqual(Set(unionMask.paths), Set(["name", "age", "address"]))
    XCTAssertEqual(unionMask.paths.count, 3)  // Не должно быть дубликатов
  }

  func testCoversWithComplexHierarchy() throws {
    let fieldMask = try FieldMaskHandler.FieldMaskValue(paths: ["user", "metadata.tags"])

    // user должен покрывать все дочерние пути
    XCTAssertTrue(fieldMask.covers("user"))
    XCTAssertTrue(fieldMask.covers("user.name"))
    XCTAssertTrue(fieldMask.covers("user.address.city"))

    // metadata.tags должен покрывать свои дочерние пути
    XCTAssertTrue(fieldMask.covers("metadata.tags"))
    XCTAssertTrue(fieldMask.covers("metadata.tags.category"))

    // metadata (без .tags) не должен покрываться
    XCTAssertFalse(fieldMask.covers("metadata.description"))
  }

  // MARK: - Performance Tests

  func testPerformanceWithLargeFieldMask() {
    let largePaths = (1...1000).map { "field\($0).subfield\($0).value" }

    measure {
      do {
        let fieldMask = try FieldMaskHandler.FieldMaskValue(paths: largePaths)
        _ = fieldMask.contains("field500.subfield500.value")
        _ = fieldMask.covers("field500.subfield500.value.detail")
      }
      catch {
        XCTFail("Performance test failed: \(error)")
      }
    }
  }

  func testHandlerPerformance() throws {
    let fieldMaskMessage = try createFieldMaskMessage(paths: ["name", "age", "address.city"])

    measure {
      for _ in 0..<100 {
        do {
          let specialized = try FieldMaskHandler.createSpecialized(from: fieldMaskMessage)
          _ = try FieldMaskHandler.createDynamic(from: specialized)
        }
        catch {
          XCTFail("Performance test failed: \(error)")
        }
      }
    }
  }

  // MARK: - Helper Methods

  private func createFieldMaskMessage(paths: [String]?) throws -> DynamicMessage {
    // Создаем дескриптор для FieldMask
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/field_mask.proto",
      package: "google.protobuf"
    )

    var messageDescriptor = MessageDescriptor(
      name: "FieldMask",
      parent: fileDescriptor
    )

    let pathsField = FieldDescriptor(
      name: "paths",
      number: 1,
      type: .string,
      isRepeated: true
    )
    messageDescriptor.addField(pathsField)

    fileDescriptor.addMessage(messageDescriptor)

    // Создаем сообщение
    let factory = MessageFactory()
    var message = factory.createMessage(from: messageDescriptor)

    // Устанавливаем поля, если переданы
    if let paths = paths {
      try message.set(paths, forField: "paths")
    }

    return message
  }
}
