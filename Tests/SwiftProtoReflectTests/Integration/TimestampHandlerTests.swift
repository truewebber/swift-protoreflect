/**
 * TimestampHandlerTests.swift
 * SwiftProtoReflectTests
 *
 * Тесты для TimestampHandler
 */

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class TimestampHandlerTests: XCTestCase {

  // MARK: - TimestampValue Tests

  func testTimestampValueInitialization() {
    // Валидная инициализация
    XCTAssertNoThrow(try TimestampHandler.TimestampValue(seconds: 1_234_567_890, nanos: 123_456_789))
    XCTAssertNoThrow(try TimestampHandler.TimestampValue(seconds: 0, nanos: 0))
    XCTAssertNoThrow(try TimestampHandler.TimestampValue(seconds: -1, nanos: 999_999_999))

    // Невалидные наносекунды
    XCTAssertThrowsError(try TimestampHandler.TimestampValue(seconds: 0, nanos: -1)) { error in
      guard case WellKnownTypeError.invalidData(let typeName, let reason) = error else {
        XCTFail("Expected invalidData error")
        return
      }
      XCTAssertEqual(typeName, "google.protobuf.Timestamp")
      XCTAssertTrue(reason.contains("nanos must be in range"))
    }

    XCTAssertThrowsError(try TimestampHandler.TimestampValue(seconds: 0, nanos: 1_000_000_000)) { error in
      guard case WellKnownTypeError.invalidData = error else {
        XCTFail("Expected invalidData error")
        return
      }
    }
  }

  func testTimestampValueFromDate() {
    let date = Date(timeIntervalSince1970: 1234567890.123456789)
    let timestamp = TimestampHandler.TimestampValue(from: date)

    XCTAssertEqual(timestamp.seconds, 1_234_567_890)
    // Проверяем наносекунды с некоторой толерантностью
    XCTAssertTrue(abs(timestamp.nanos - 123_456_789) < 1000)  // До микросекунды точности
  }

  func testTimestampValueToDate() {
    do {
      let timestamp = try TimestampHandler.TimestampValue(seconds: 1_234_567_890, nanos: 123_456_789)
      let date = timestamp.toDate()

      let expectedDate = Date(timeIntervalSince1970: 1234567890.123456789)
      XCTAssertEqual(date.timeIntervalSince1970, expectedDate.timeIntervalSince1970, accuracy: 0.001)
    }
    catch {
      XCTFail("Failed to create timestamp: \(error)")
    }
  }

  func testTimestampValueRoundTrip() {
    let originalDate = Date()
    let timestamp = TimestampHandler.TimestampValue(from: originalDate)
    let convertedDate = timestamp.toDate()

    // Должны быть близки с точностью до наносекунд
    XCTAssertEqual(originalDate.timeIntervalSince1970, convertedDate.timeIntervalSince1970, accuracy: 0.001)
  }

  func testTimestampValueNow() {
    let now = TimestampHandler.TimestampValue.now()
    let currentTime = Date().timeIntervalSince1970
    let timestampTime = now.toDate().timeIntervalSince1970

    // Должны быть в пределах секунды
    XCTAssertEqual(currentTime, timestampTime, accuracy: 1.0)
  }

  func testTimestampValueDescription() {
    do {
      let timestamp = try TimestampHandler.TimestampValue(seconds: 1_234_567_890, nanos: 123_456_789)
      let description = timestamp.description

      // Должен содержать ISO8601 формат
      XCTAssertTrue(description.contains("2009"))
      XCTAssertTrue(description.contains("T"))
      XCTAssertTrue(description.contains("Z"))
    }
    catch {
      XCTFail("Failed to create timestamp: \(error)")
    }
  }

  func testTimestampValueEquality() {
    do {
      let timestamp1 = try TimestampHandler.TimestampValue(seconds: 1_234_567_890, nanos: 123_456_789)
      let timestamp2 = try TimestampHandler.TimestampValue(seconds: 1_234_567_890, nanos: 123_456_789)
      let timestamp3 = try TimestampHandler.TimestampValue(seconds: 1_234_567_890, nanos: 123_456_790)

      XCTAssertEqual(timestamp1, timestamp2)
      XCTAssertNotEqual(timestamp1, timestamp3)
    }
    catch {
      XCTFail("Failed to create timestamps: \(error)")
    }
  }

  // MARK: - Handler Implementation Tests

  func testHandlerBasicProperties() {
    XCTAssertEqual(TimestampHandler.handledTypeName, "google.protobuf.Timestamp")
    XCTAssertEqual(TimestampHandler.supportPhase, .critical)
  }

  func testCreateSpecializedFromMessage() throws {
    // Создаем timestamp сообщение
    let timestampMessage = try createTimestampMessage(seconds: 1_234_567_890, nanos: 123_456_789)

    // Конвертируем в специализированный тип
    let specialized = try TimestampHandler.createSpecialized(from: timestampMessage)

    guard let timestamp = specialized as? TimestampHandler.TimestampValue else {
      XCTFail("Expected TimestampValue")
      return
    }

    XCTAssertEqual(timestamp.seconds, 1_234_567_890)
    XCTAssertEqual(timestamp.nanos, 123_456_789)
  }

  func testCreateSpecializedFromMessageWithMissingFields() throws {
    // Создаем сообщение только с seconds
    let timestampMessage = try createTimestampMessage(seconds: 1_234_567_890, nanos: nil)

    let specialized = try TimestampHandler.createSpecialized(from: timestampMessage)

    guard let timestamp = specialized as? TimestampHandler.TimestampValue else {
      XCTFail("Expected TimestampValue")
      return
    }

    XCTAssertEqual(timestamp.seconds, 1_234_567_890)
    XCTAssertEqual(timestamp.nanos, 0)  // Должно быть значение по умолчанию
  }

  func testCreateSpecializedFromInvalidMessage() throws {
    // Создаем сообщение неправильного типа
    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let messageDescriptor = MessageDescriptor(name: "NotTimestamp", parent: fileDescriptor)
    fileDescriptor.addMessage(messageDescriptor)

    let factory = MessageFactory()
    let wrongMessage = factory.createMessage(from: messageDescriptor)

    XCTAssertThrowsError(try TimestampHandler.createSpecialized(from: wrongMessage)) { error in
      guard case WellKnownTypeError.invalidData(let typeName, _) = error else {
        XCTFail("Expected invalidData error")
        return
      }
      XCTAssertEqual(typeName, "google.protobuf.Timestamp")
    }
  }

  func testCreateDynamicFromSpecialized() throws {
    let timestamp = try TimestampHandler.TimestampValue(seconds: 1_234_567_890, nanos: 123_456_789)

    let dynamicMessage = try TimestampHandler.createDynamic(from: timestamp)

    XCTAssertEqual(dynamicMessage.descriptor.fullName, "google.protobuf.Timestamp")

    let seconds = try dynamicMessage.get(forField: "seconds") as! Int64
    let nanos = try dynamicMessage.get(forField: "nanos") as! Int32

    XCTAssertEqual(seconds, 1_234_567_890)
    XCTAssertEqual(nanos, 123_456_789)
  }

  func testCreateDynamicFromInvalidSpecialized() throws {
    let wrongSpecialized = "not a timestamp"

    XCTAssertThrowsError(try TimestampHandler.createDynamic(from: wrongSpecialized)) { error in
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
    let validTimestamp = try TimestampHandler.TimestampValue(seconds: 1_234_567_890, nanos: 123_456_789)
    XCTAssertTrue(TimestampHandler.validate(validTimestamp))

    // Невалидные значения
    XCTAssertFalse(TimestampHandler.validate("not a timestamp"))
    XCTAssertFalse(TimestampHandler.validate(123))
    XCTAssertFalse(TimestampHandler.validate(Date()))
  }

  func testRoundTripConversion() throws {
    let originalTimestamp = try TimestampHandler.TimestampValue(seconds: 1_234_567_890, nanos: 123_456_789)

    // Convert to dynamic message and back
    let dynamicMessage = try TimestampHandler.createDynamic(from: originalTimestamp)
    let convertedSpecialized = try TimestampHandler.createSpecialized(from: dynamicMessage)

    guard let convertedTimestamp = convertedSpecialized as? TimestampHandler.TimestampValue else {
      XCTFail("Expected TimestampValue")
      return
    }

    XCTAssertEqual(originalTimestamp, convertedTimestamp)
  }

  // MARK: - Convenience Extensions Tests

  func testDateExtensions() {
    let originalDate = Date(timeIntervalSince1970: 1234567890.123)
    let timestampValue = originalDate.toTimestampValue()
    let convertedDate = Date(from: timestampValue)

    XCTAssertEqual(originalDate.timeIntervalSince1970, convertedDate.timeIntervalSince1970, accuracy: 0.001)
  }

  func testDynamicMessageTimestampExtension() throws {
    let date = Date(timeIntervalSince1970: 1234567890.123)

    let timestampMessage = try DynamicMessage.timestampMessage(from: date)
    XCTAssertEqual(timestampMessage.descriptor.fullName, "google.protobuf.Timestamp")

    let convertedDate = try timestampMessage.toDate()
    XCTAssertEqual(date.timeIntervalSince1970, convertedDate.timeIntervalSince1970, accuracy: 0.001)
  }

  func testDynamicMessageToDateWithInvalidMessage() throws {
    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    let messageDescriptor = MessageDescriptor(name: "NotTimestamp", parent: fileDescriptor)
    fileDescriptor.addMessage(messageDescriptor)

    let factory = MessageFactory()
    let wrongMessage = factory.createMessage(from: messageDescriptor)

    XCTAssertThrowsError(try wrongMessage.toDate()) { error in
      guard case WellKnownTypeError.invalidData = error else {
        XCTFail("Expected invalidData error")
        return
      }
    }
  }

  // MARK: - Edge Cases Tests

  func testExtremeTimestamps() throws {
    // Unix epoch
    let epoch = try TimestampHandler.TimestampValue(seconds: 0, nanos: 0)
    XCTAssertEqual(epoch.toDate().timeIntervalSince1970, 0)

    // Future timestamp
    let future = try TimestampHandler.TimestampValue(seconds: 2_147_483_647, nanos: 999_999_999)
    XCTAssertTrue(future.toDate().timeIntervalSince1970 > 0)

    // Past timestamp
    let past = try TimestampHandler.TimestampValue(seconds: -1, nanos: 0)
    XCTAssertTrue(past.toDate().timeIntervalSince1970 < 0)
  }

  func testMaxNanos() throws {
    // Тестируем значение, которое не приводит к округлению до целой секунды
    let timestamp = try TimestampHandler.TimestampValue(seconds: 1, nanos: 500_000_000)  // 1.5 секунды
    XCTAssertEqual(timestamp.nanos, 500_000_000)

    let date = timestamp.toDate()
    print("Original timestamp: seconds=\(timestamp.seconds), nanos=\(timestamp.nanos)")
    print("Converted to date: timeInterval=\(date.timeIntervalSince1970)")

    let roundTrip = TimestampHandler.TimestampValue(from: date)
    print("Round trip timestamp: seconds=\(roundTrip.seconds), nanos=\(roundTrip.nanos)")

    // Проверяем правильность конвертации
    XCTAssertEqual(roundTrip.seconds, 1)

    // Наносекунды должны быть близкими к оригиналу (с некоторой толерантностью из-за double precision)
    XCTAssertTrue(
      abs(roundTrip.nanos - 500_000_000) < 1000,
      "Expected nanos to be close to 500,000,000, but got \(roundTrip.nanos), difference: \(abs(roundTrip.nanos - 500_000_000))"
    )
  }

  func testExtremeNanos() throws {
    // Отдельный тест для экстремальных значений наносекунд
    // Максимальное значение наносекунд (999,999,999) может округляться до следующей секунды
    let extremeTimestamp = try TimestampHandler.TimestampValue(seconds: 0, nanos: 999_999_999)
    let date = extremeTimestamp.toDate()
    let roundTrip = TimestampHandler.TimestampValue(from: date)

    // Либо получаем (0, ~999999999), либо (1, 0) из-за округления double
    let totalOriginalNanos = extremeTimestamp.seconds * 1_000_000_000 + Int64(extremeTimestamp.nanos)
    let totalRoundTripNanos = roundTrip.seconds * 1_000_000_000 + Int64(roundTrip.nanos)

    // Общее количество наносекунд должно быть очень близким
    XCTAssertTrue(
      abs(totalOriginalNanos - totalRoundTripNanos) < 1_000_000,
      "Total nanoseconds should be close: original=\(totalOriginalNanos), roundtrip=\(totalRoundTripNanos)"
    )
  }

  // MARK: - Performance Tests

  func testConversionPerformance() {
    let date = Date()

    measure {
      for _ in 0..<1000 {
        let timestamp = TimestampHandler.TimestampValue(from: date)
        _ = timestamp.toDate()
      }
    }
  }

  func testHandlerPerformance() throws {
    let timestampMessage = try createTimestampMessage(seconds: 1_234_567_890, nanos: 123_456_789)

    measure {
      for _ in 0..<100 {
        do {
          let specialized = try TimestampHandler.createSpecialized(from: timestampMessage)
          _ = try TimestampHandler.createDynamic(from: specialized)
        }
        catch {
          XCTFail("Performance test failed: \(error)")
        }
      }
    }
  }

  // MARK: - Helper Methods

  private func createTimestampMessage(seconds: Int64, nanos: Int32?) throws -> DynamicMessage {
    // Создаем дескриптор для Timestamp
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/timestamp.proto",
      package: "google.protobuf"
    )

    var messageDescriptor = MessageDescriptor(
      name: "Timestamp",
      parent: fileDescriptor
    )

    let secondsField = FieldDescriptor(
      name: "seconds",
      number: 1,
      type: .int64
    )
    messageDescriptor.addField(secondsField)

    let nanosField = FieldDescriptor(
      name: "nanos",
      number: 2,
      type: .int32
    )
    messageDescriptor.addField(nanosField)

    fileDescriptor.addMessage(messageDescriptor)

    // Создаем сообщение
    let factory = MessageFactory()
    var message = factory.createMessage(from: messageDescriptor)

    // Устанавливаем поля
    try message.set(seconds, forField: "seconds")
    if let nanos = nanos {
      try message.set(nanos, forField: "nanos")
    }

    return message
  }
}
