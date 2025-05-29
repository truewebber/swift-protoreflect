/**
 * DurationHandlerTests.swift
 * SwiftProtoReflectTests
 *
 * Тесты для DurationHandler
 */

import XCTest
@testable import SwiftProtoReflect
import Foundation

final class DurationHandlerTests: XCTestCase {
    
    // MARK: - DurationValue Tests
    
    func testDurationValueInitialization() {
        // Валидная инициализация
        XCTAssertNoThrow(try DurationHandler.DurationValue(seconds: 1234567890, nanos: 123456789))
        XCTAssertNoThrow(try DurationHandler.DurationValue(seconds: 0, nanos: 0))
        XCTAssertNoThrow(try DurationHandler.DurationValue(seconds: -1, nanos: -999999999))
        XCTAssertNoThrow(try DurationHandler.DurationValue(seconds: 5, nanos: 0))
        XCTAssertNoThrow(try DurationHandler.DurationValue(seconds: 0, nanos: 123456789))
        
        // Валидная инициализация с одинаковыми знаками
        XCTAssertNoThrow(try DurationHandler.DurationValue(seconds: 1, nanos: 500000000))
        XCTAssertNoThrow(try DurationHandler.DurationValue(seconds: -1, nanos: -500000000))
        
        // Невалидные наносекунды (вне диапазона)
        XCTAssertThrowsError(try DurationHandler.DurationValue(seconds: 0, nanos: 1000000000)) { error in
            guard case WellKnownTypeError.invalidData(let typeName, let reason) = error else {
                XCTFail("Expected invalidData error")
                return
            }
            XCTAssertEqual(typeName, "google.protobuf.Duration")
            XCTAssertTrue(reason.contains("nanos must be in range"))
        }
        
        XCTAssertThrowsError(try DurationHandler.DurationValue(seconds: 0, nanos: -1000000000)) { error in
            guard case WellKnownTypeError.invalidData = error else {
                XCTFail("Expected invalidData error")
                return
            }
        }
        
        // Невалидная комбинация знаков
        XCTAssertThrowsError(try DurationHandler.DurationValue(seconds: 1, nanos: -500000000)) { error in
            guard case WellKnownTypeError.invalidData(let typeName, let reason) = error else {
                XCTFail("Expected invalidData error")
                return
            }
            XCTAssertEqual(typeName, "google.protobuf.Duration")
            XCTAssertTrue(reason.contains("same sign"))
        }
        
        XCTAssertThrowsError(try DurationHandler.DurationValue(seconds: -1, nanos: 500000000)) { error in
            guard case WellKnownTypeError.invalidData = error else {
                XCTFail("Expected invalidData error")
                return
            }
        }
    }
    
    func testDurationValueFromTimeInterval() {
        // Положительный интервал
        let positiveInterval: TimeInterval = 123.456789
        let positiveDuration = DurationHandler.DurationValue(from: positiveInterval)
        XCTAssertEqual(positiveDuration.seconds, 123)
        // Проверяем наносекунды с некоторой толерантностью
        XCTAssertTrue(abs(positiveDuration.nanos - 456789000) < 1000)
        
        // Отрицательный интервал
        let negativeInterval: TimeInterval = -123.456789
        let negativeDuration = DurationHandler.DurationValue(from: negativeInterval)
        XCTAssertEqual(negativeDuration.seconds, -123)
        XCTAssertTrue(abs(negativeDuration.nanos + 456789000) < 1000)
        
        // Нулевой интервал
        let zeroDuration = DurationHandler.DurationValue(from: 0.0)
        XCTAssertEqual(zeroDuration.seconds, 0)
        XCTAssertEqual(zeroDuration.nanos, 0)
        
        // Только дробная часть
        let fractionalDuration = DurationHandler.DurationValue(from: 0.123)
        XCTAssertEqual(fractionalDuration.seconds, 0)
        XCTAssertTrue(abs(fractionalDuration.nanos - 123000000) < 1000)
    }
    
    func testDurationValueToTimeInterval() {
        do {
            // Положительная длительность
            let positiveDuration = try DurationHandler.DurationValue(seconds: 123, nanos: 456789000)
            let positiveInterval = positiveDuration.toTimeInterval()
            XCTAssertEqual(positiveInterval, 123.456789, accuracy: 0.001)
            
            // Отрицательная длительность
            let negativeDuration = try DurationHandler.DurationValue(seconds: -123, nanos: -456789000)
            let negativeInterval = negativeDuration.toTimeInterval()
            XCTAssertEqual(negativeInterval, -123.456789, accuracy: 0.001)
            
            // Нулевая длительность
            let zeroDuration = try DurationHandler.DurationValue(seconds: 0, nanos: 0)
            XCTAssertEqual(zeroDuration.toTimeInterval(), 0.0)
            
            // Только наносекунды
            let nanosDuration = try DurationHandler.DurationValue(seconds: 0, nanos: 500000000)
            XCTAssertEqual(nanosDuration.toTimeInterval(), 0.5, accuracy: 0.001)
        } catch {
            XCTFail("Failed to create duration: \(error)")
        }
    }
    
    func testDurationValueRoundTrip() {
        let testIntervals: [TimeInterval] = [
            0.0,
            0.123456,
            123.456789,
            -123.456789,
            -0.123456,
            1.0,
            -1.0,
            3600.0, // 1 hour
            -3600.0
        ]
        
        for originalInterval in testIntervals {
            let duration = DurationHandler.DurationValue(from: originalInterval)
            let convertedInterval = duration.toTimeInterval()
            
            // Должны быть близки с точностью до микросекунд
            XCTAssertEqual(originalInterval, convertedInterval, accuracy: 0.001,
                          "Round trip failed for interval: \(originalInterval)")
        }
    }
    
    func testDurationValueZero() {
        let zero = DurationHandler.DurationValue.zero()
        XCTAssertEqual(zero.seconds, 0)
        XCTAssertEqual(zero.nanos, 0)
        XCTAssertEqual(zero.toTimeInterval(), 0.0)
    }
    
    func testDurationValueAbs() {
        do {
            // Положительная длительность остается положительной
            let positive = try DurationHandler.DurationValue(seconds: 5, nanos: 123456789)
            let positiveAbs = positive.abs()
            XCTAssertEqual(positiveAbs.seconds, 5)
            XCTAssertEqual(positiveAbs.nanos, 123456789)
            
            // Отрицательная длительность становится положительной
            let negative = try DurationHandler.DurationValue(seconds: -5, nanos: -123456789)
            let negativeAbs = negative.abs()
            XCTAssertEqual(negativeAbs.seconds, 5)
            XCTAssertEqual(negativeAbs.nanos, 123456789)
            
            // Нулевая остается нулевой
            let zero = DurationHandler.DurationValue.zero()
            let zeroAbs = zero.abs()
            XCTAssertEqual(zeroAbs.seconds, 0)
            XCTAssertEqual(zeroAbs.nanos, 0)
            
            // Отрицательные только наносекунды
            let negativeNanos = try DurationHandler.DurationValue(seconds: 0, nanos: -123456789)
            let negativeNanosAbs = negativeNanos.abs()
            XCTAssertEqual(negativeNanosAbs.seconds, 0)
            XCTAssertEqual(negativeNanosAbs.nanos, 123456789)
        } catch {
            XCTFail("Failed to create duration: \(error)")
        }
    }
    
    func testDurationValueNegated() {
        do {
            // Положительная становится отрицательной
            let positive = try DurationHandler.DurationValue(seconds: 5, nanos: 123456789)
            let negated = positive.negated()
            XCTAssertEqual(negated.seconds, -5)
            XCTAssertEqual(negated.nanos, -123456789)
            
            // Отрицательная становится положительной
            let negative = try DurationHandler.DurationValue(seconds: -5, nanos: -123456789)
            let negatedNegative = negative.negated()
            XCTAssertEqual(negatedNegative.seconds, 5)
            XCTAssertEqual(negatedNegative.nanos, 123456789)
            
            // Двойное отрицание возвращает к оригиналу
            let doubleNegated = negated.negated()
            XCTAssertEqual(doubleNegated.seconds, positive.seconds)
            XCTAssertEqual(doubleNegated.nanos, positive.nanos)
        } catch {
            XCTFail("Failed to create duration: \(error)")
        }
    }
    
    func testDurationValueDescription() {
        do {
            // Нулевая длительность
            let zero = DurationHandler.DurationValue.zero()
            XCTAssertEqual(zero.description, "0s")
            
            // Положительная длительность в секундах
            let positive = try DurationHandler.DurationValue(seconds: 5, nanos: 123456789)
            XCTAssertTrue(positive.description.contains("5.123s"))
            
            // Отрицательная длительность
            let negative = try DurationHandler.DurationValue(seconds: -5, nanos: -123456789)
            XCTAssertTrue(negative.description.contains("-5.123s"))
            
            // Миллисекунды
            let millis = try DurationHandler.DurationValue(seconds: 0, nanos: 123456789)
            XCTAssertTrue(millis.description.contains("ms") || millis.description.contains("s"))
            
            // Очень маленькие значения (наносекунды)
            let nanos = try DurationHandler.DurationValue(seconds: 0, nanos: 123)
            XCTAssertTrue(nanos.description.contains("ns") || nanos.description.contains("ms"))
        } catch {
            XCTFail("Failed to create duration: \(error)")
        }
    }
    
    func testDurationValueEquality() {
        do {
            let duration1 = try DurationHandler.DurationValue(seconds: 5, nanos: 123456789)
            let duration2 = try DurationHandler.DurationValue(seconds: 5, nanos: 123456789)
            let duration3 = try DurationHandler.DurationValue(seconds: 5, nanos: 123456790)
            let duration4 = try DurationHandler.DurationValue(seconds: 6, nanos: 123456789)
            
            XCTAssertEqual(duration1, duration2)
            XCTAssertNotEqual(duration1, duration3)
            XCTAssertNotEqual(duration1, duration4)
        } catch {
            XCTFail("Failed to create durations: \(error)")
        }
    }
    
    // MARK: - Handler Implementation Tests
    
    func testHandlerBasicProperties() {
        XCTAssertEqual(DurationHandler.handledTypeName, "google.protobuf.Duration")
        XCTAssertEqual(DurationHandler.supportPhase, .critical)
    }
    
    func testCreateSpecializedFromMessage() throws {
        // Создаем duration сообщение
        let durationMessage = try createDurationMessage(seconds: 5, nanos: 123456789)
        
        // Конвертируем в специализированный тип
        let specialized = try DurationHandler.createSpecialized(from: durationMessage)
        
        guard let duration = specialized as? DurationHandler.DurationValue else {
            XCTFail("Expected DurationValue")
            return
        }
        
        XCTAssertEqual(duration.seconds, 5)
        XCTAssertEqual(duration.nanos, 123456789)
    }
    
    func testCreateSpecializedFromMessageWithMissingFields() throws {
        // Создаем сообщение только с seconds
        let durationMessage = try createDurationMessage(seconds: 5, nanos: nil)
        
        let specialized = try DurationHandler.createSpecialized(from: durationMessage)
        
        guard let duration = specialized as? DurationHandler.DurationValue else {
            XCTFail("Expected DurationValue")
            return
        }
        
        XCTAssertEqual(duration.seconds, 5)
        XCTAssertEqual(duration.nanos, 0) // Должно быть значение по умолчанию
    }
    
    func testCreateSpecializedFromMessageWithNegativeValues() throws {
        // Создаем отрицательное сообщение
        let negativeDurationMessage = try createDurationMessage(seconds: -5, nanos: -123456789)
        
        let specialized = try DurationHandler.createSpecialized(from: negativeDurationMessage)
        
        guard let duration = specialized as? DurationHandler.DurationValue else {
            XCTFail("Expected DurationValue")
            return
        }
        
        XCTAssertEqual(duration.seconds, -5)
        XCTAssertEqual(duration.nanos, -123456789)
    }
    
    func testCreateSpecializedFromInvalidMessage() throws {
        // Создаем сообщение неправильного типа
        var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
        let messageDescriptor = MessageDescriptor(name: "NotDuration", parent: fileDescriptor)
        fileDescriptor.addMessage(messageDescriptor)
        
        let factory = MessageFactory()
        let wrongMessage = factory.createMessage(from: messageDescriptor)
        
        XCTAssertThrowsError(try DurationHandler.createSpecialized(from: wrongMessage)) { error in
            guard case WellKnownTypeError.invalidData(let typeName, _) = error else {
                XCTFail("Expected invalidData error")
                return
            }
            XCTAssertEqual(typeName, "google.protobuf.Duration")
        }
    }
    
    func testCreateDynamicFromSpecialized() throws {
        let duration = try DurationHandler.DurationValue(seconds: 5, nanos: 123456789)
        
        let dynamicMessage = try DurationHandler.createDynamic(from: duration)
        
        XCTAssertEqual(dynamicMessage.descriptor.fullName, "google.protobuf.Duration")
        
        let seconds = try dynamicMessage.get(forField: "seconds") as! Int64
        let nanos = try dynamicMessage.get(forField: "nanos") as! Int32
        
        XCTAssertEqual(seconds, 5)
        XCTAssertEqual(nanos, 123456789)
    }
    
    func testCreateDynamicFromNegativeSpecialized() throws {
        let negativeDuration = try DurationHandler.DurationValue(seconds: -5, nanos: -123456789)
        
        let dynamicMessage = try DurationHandler.createDynamic(from: negativeDuration)
        
        let seconds = try dynamicMessage.get(forField: "seconds") as! Int64
        let nanos = try dynamicMessage.get(forField: "nanos") as! Int32
        
        XCTAssertEqual(seconds, -5)
        XCTAssertEqual(nanos, -123456789)
    }
    
    func testCreateDynamicFromInvalidSpecialized() throws {
        let wrongSpecialized = "not a duration"
        
        XCTAssertThrowsError(try DurationHandler.createDynamic(from: wrongSpecialized)) { error in
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
        let validDuration = try DurationHandler.DurationValue(seconds: 5, nanos: 123456789)
        XCTAssertTrue(DurationHandler.validate(validDuration))
        
        let negativeDuration = try DurationHandler.DurationValue(seconds: -5, nanos: -123456789)
        XCTAssertTrue(DurationHandler.validate(negativeDuration))
        
        let zeroDuration = DurationHandler.DurationValue.zero()
        XCTAssertTrue(DurationHandler.validate(zeroDuration))
        
        // Невалидные значения
        XCTAssertFalse(DurationHandler.validate("not a duration"))
        XCTAssertFalse(DurationHandler.validate(123))
        XCTAssertFalse(DurationHandler.validate(Date()))
        XCTAssertFalse(DurationHandler.validate(5.0))
    }
    
    func testRoundTripConversion() throws {
        let testCases = [
            try DurationHandler.DurationValue(seconds: 5, nanos: 123456789),
            try DurationHandler.DurationValue(seconds: -5, nanos: -123456789),
            try DurationHandler.DurationValue(seconds: 0, nanos: 123456789),
            try DurationHandler.DurationValue(seconds: 0, nanos: -123456789),
            DurationHandler.DurationValue.zero()
        ]
        
        for originalDuration in testCases {
            // Convert to dynamic message and back
            let dynamicMessage = try DurationHandler.createDynamic(from: originalDuration)
            let convertedSpecialized = try DurationHandler.createSpecialized(from: dynamicMessage)
            
            guard let convertedDuration = convertedSpecialized as? DurationHandler.DurationValue else {
                XCTFail("Expected DurationValue")
                return
            }
            
            XCTAssertEqual(originalDuration, convertedDuration, 
                          "Round trip failed for: \(originalDuration)")
        }
    }
    
    // MARK: - Convenience Extensions Tests
    
    func testTimeIntervalExtensions() {
        let testIntervals: [TimeInterval] = [0.0, 123.456, -123.456, 0.001, -0.001]
        
        for originalInterval in testIntervals {
            let durationValue = originalInterval.toDurationValue()
            let convertedInterval = TimeInterval(from: durationValue)
            
            XCTAssertEqual(originalInterval, convertedInterval, accuracy: 0.001,
                          "Extension round trip failed for: \(originalInterval)")
        }
    }
    
    func testDynamicMessageDurationExtension() throws {
        let testIntervals: [TimeInterval] = [0.0, 123.456, -123.456, 3600.0, -3600.0]
        
        for interval in testIntervals {
            let durationMessage = try DynamicMessage.durationMessage(from: interval)
            XCTAssertEqual(durationMessage.descriptor.fullName, "google.protobuf.Duration")
            
            let convertedInterval = try durationMessage.toTimeInterval()
            XCTAssertEqual(interval, convertedInterval, accuracy: 0.001,
                          "Dynamic message extension failed for: \(interval)")
        }
    }
    
    func testDynamicMessageToTimeIntervalWithInvalidMessage() throws {
        var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
        let messageDescriptor = MessageDescriptor(name: "NotDuration", parent: fileDescriptor)
        fileDescriptor.addMessage(messageDescriptor)
        
        let factory = MessageFactory()
        let wrongMessage = factory.createMessage(from: messageDescriptor)
        
        XCTAssertThrowsError(try wrongMessage.toTimeInterval()) { error in
            guard case WellKnownTypeError.invalidData = error else {
                XCTFail("Expected invalidData error")
                return
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testExtremeDurations() throws {
        // Очень большая положительная длительность
        let largeDuration = try DurationHandler.DurationValue(seconds: Int64.max / 2, nanos: 999999999)
        XCTAssertTrue(largeDuration.toTimeInterval() > 0)
        
        // Очень большая отрицательная длительность  
        let largeNegativeDuration = try DurationHandler.DurationValue(seconds: Int64.min / 2, nanos: -999999999)
        XCTAssertTrue(largeNegativeDuration.toTimeInterval() < 0)
        
        // Максимальные наносекунды
        let maxNanos = try DurationHandler.DurationValue(seconds: 0, nanos: 999999999)
        XCTAssertEqual(maxNanos.nanos, 999999999)
        
        // Минимальные наносекунды
        let minNanos = try DurationHandler.DurationValue(seconds: 0, nanos: -999999999)
        XCTAssertEqual(minNanos.nanos, -999999999)
    }
    
    func testBoundaryNanos() throws {
        // Тестируем граничные значения наносекунд
        let boundaries: [Int32] = [
            -999999999, -500000000, -1, 0, 1, 500000000, 999999999
        ]
        
        for nanos in boundaries {
            XCTAssertNoThrow(try DurationHandler.DurationValue(seconds: 0, nanos: nanos),
                           "Should accept boundary nanos value: \(nanos)")
        }
        
        // Тестируем значения за границами
        let outOfBounds: [Int32] = [-1000000000, 1000000000]
        
        for nanos in outOfBounds {
            XCTAssertThrowsError(try DurationHandler.DurationValue(seconds: 0, nanos: nanos),
                               "Should reject out-of-bounds nanos value: \(nanos)")
        }
    }
    
    func testMixedSignValidation() throws {
        // Валидные комбинации (одинаковые знаки или один ноль)
        let validCombinations: [(Int64, Int32)] = [
            (0, 0),
            (1, 0),
            (0, 1),
            (-1, 0),
            (0, -1),
            (5, 123456789),
            (-5, -123456789)
        ]
        
        for (seconds, nanos) in validCombinations {
            XCTAssertNoThrow(try DurationHandler.DurationValue(seconds: seconds, nanos: nanos),
                           "Should accept valid combination: seconds=\(seconds), nanos=\(nanos)")
        }
        
        // Невалидные комбинации (разные знаки)
        let invalidCombinations: [(Int64, Int32)] = [
            (1, -123456789),
            (-1, 123456789),
            (5, -500000000),
            (-5, 500000000)
        ]
        
        for (seconds, nanos) in invalidCombinations {
            XCTAssertThrowsError(try DurationHandler.DurationValue(seconds: seconds, nanos: nanos),
                               "Should reject invalid combination: seconds=\(seconds), nanos=\(nanos)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testConversionPerformance() {
        let interval: TimeInterval = 123.456789
        
        measure {
            for _ in 0..<1000 {
                let duration = DurationHandler.DurationValue(from: interval)
                _ = duration.toTimeInterval()
            }
        }
    }
    
    func testHandlerPerformance() throws {
        let durationMessage = try createDurationMessage(seconds: 5, nanos: 123456789)
        
        measure {
            for _ in 0..<100 {
                do {
                    let specialized = try DurationHandler.createSpecialized(from: durationMessage)
                    _ = try DurationHandler.createDynamic(from: specialized)
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }
    
    func testAbsAndNegatedPerformance() throws {
        let duration = try DurationHandler.DurationValue(seconds: -5, nanos: -123456789)
        
        measure {
            for _ in 0..<10000 {
                _ = duration.abs()
                _ = duration.negated()
            }
        }
    }
    
    // MARK: - Registry Integration Tests
    
    func testRegistryIntegration() throws {
        let registry = WellKnownTypesRegistry.shared
        
        // Проверяем что DurationHandler зарегистрирован
        let handler = registry.getHandler(for: WellKnownTypeNames.duration)
        XCTAssertNotNil(handler)
        XCTAssertTrue(handler is DurationHandler.Type)
        
        // Тестируем через registry
        let duration = try DurationHandler.DurationValue(seconds: 5, nanos: 123456789)
        let dynamicMessage = try DurationHandler.createDynamic(from: duration)
        
        let specializedFromRegistry = try registry.createSpecialized(
            from: dynamicMessage, 
            typeName: WellKnownTypeNames.duration
        )
        
        guard let convertedDuration = specializedFromRegistry as? DurationHandler.DurationValue else {
            XCTFail("Expected DurationValue from registry")
            return
        }
        
        XCTAssertEqual(duration, convertedDuration)
    }
    
    // MARK: - Helper Methods
    
    private func createDurationMessage(seconds: Int64, nanos: Int32?) throws -> DynamicMessage {
        // Создаем дескриптор для Duration
        var fileDescriptor = FileDescriptor(
            name: "google/protobuf/duration.proto",
            package: "google.protobuf"
        )
        
        var messageDescriptor = MessageDescriptor(
            name: "Duration",
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
