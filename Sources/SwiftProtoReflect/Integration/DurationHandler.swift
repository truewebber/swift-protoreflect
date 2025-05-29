/**
 * DurationHandler.swift
 * SwiftProtoReflect
 *
 * Обработчик для google.protobuf.Duration - конвертация между DynamicMessage и TimeInterval
 */

import Foundation
import SwiftProtobuf

// MARK: - Duration Handler

/// Обработчик для google.protobuf.Duration
public struct DurationHandler: WellKnownTypeHandler {
    
    public static let handledTypeName = WellKnownTypeNames.duration
    public static let supportPhase: WellKnownSupportPhase = .critical
    
    // MARK: - Duration Representation
    
    /// Специализированное представление Duration
    public struct DurationValue: Equatable, CustomStringConvertible {
        
        /// Signed seconds of the span of time
        public let seconds: Int64
        
        /// Signed fractions of a second at nanosecond resolution
        /// Must be from -999,999,999 to +999,999,999 inclusive
        public let nanos: Int32
        
        /// Инициализация с секундами и наносекундами
        /// - Parameters:
        ///   - seconds: Секунды длительности (могут быть отрицательными)
        ///   - nanos: Наносекунды (должны иметь тот же знак что и seconds, или быть 0)
        /// - Throws: WellKnownTypeError если значения невалидны
        public init(seconds: Int64, nanos: Int32) throws {
            guard Self.isValidNanos(nanos) else {
                throw WellKnownTypeError.invalidData(
                    typeName: WellKnownTypeNames.duration,
                    reason: "nanos must be in range [-999999999, 999999999], got \(nanos)"
                )
            }
            
            guard Self.isValidSecondsNanosCombination(seconds: seconds, nanos: nanos) else {
                throw WellKnownTypeError.invalidData(
                    typeName: WellKnownTypeNames.duration,
                    reason: "seconds and nanos must have the same sign or one of them must be zero"
                )
            }
            
            self.seconds = seconds
            self.nanos = nanos
        }
        
        /// Инициализация из TimeInterval
        /// - Parameter timeInterval: Foundation TimeInterval (секунды как Double)
        public init(from timeInterval: TimeInterval) {
            let totalSeconds = timeInterval
            self.seconds = Int64(totalSeconds)
            
            // Вычисляем наносекунды с учетом знака
            let fractionalSeconds = totalSeconds - Double(self.seconds)
            self.nanos = Int32(fractionalSeconds * 1_000_000_000)
        }
        
        /// Конвертация в TimeInterval
        /// - Returns: Foundation TimeInterval
        public func toTimeInterval() -> TimeInterval {
            return Double(seconds) + Double(nanos) / 1_000_000_000.0
        }
        
        /// Создает нулевую длительность
        /// - Returns: DurationValue равная нулю
        public static func zero() -> DurationValue {
            return try! DurationValue(seconds: 0, nanos: 0)
        }
        
        /// Абсолютное значение длительности
        /// - Returns: DurationValue с положительными значениями
        public func abs() -> DurationValue {
            if seconds < 0 || (seconds == 0 && nanos < 0) {
                // Отрицательная длительность - делаем положительной
                return try! DurationValue(seconds: -seconds, nanos: -nanos)
            }
            return self
        }
        
        /// Отрицательная длительность
        /// - Returns: DurationValue с противоположным знаком
        public func negated() -> DurationValue {
            return try! DurationValue(seconds: -seconds, nanos: -nanos)
        }
        
        public var description: String {
            let totalSeconds = toTimeInterval()
            if totalSeconds == 0 {
                return "0s"
            } else if totalSeconds >= 1 || totalSeconds <= -1 {
                return String(format: "%.3fs", totalSeconds)
            } else {
                // Для очень маленьких значений показываем в миллисекундах или наносекундах
                let totalMillis = totalSeconds * 1000
                if Swift.abs(totalMillis) >= 1 {
                    return String(format: "%.3fms", totalMillis)
                } else {
                    return "\(seconds * 1_000_000_000 + Int64(nanos))ns"
                }
            }
        }
        
        // MARK: - Validation
        
        /// Валидация наносекунд
        /// - Parameter nanos: Значение наносекунд
        /// - Returns: true если валидны
        internal static func isValidNanos(_ nanos: Int32) -> Bool {
            return nanos >= -999_999_999 && nanos <= 999_999_999
        }
        
        /// Валидация комбинации секунд и наносекунд
        /// - Parameters:
        ///   - seconds: Секунды
        ///   - nanos: Наносекунды
        /// - Returns: true если комбинация валидна
        internal static func isValidSecondsNanosCombination(seconds: Int64, nanos: Int32) -> Bool {
            // Если одно из значений ноль, то комбинация всегда валидна
            if seconds == 0 || nanos == 0 {
                return true
            }
            
            // Оба значения должны иметь одинаковый знак
            return (seconds > 0 && nanos > 0) || (seconds < 0 && nanos < 0)
        }
    }
    
    // MARK: - Handler Implementation
    
    public static func createSpecialized(from message: DynamicMessage) throws -> Any {
        // Проверяем тип сообщения
        guard message.descriptor.fullName == handledTypeName else {
            throw WellKnownTypeError.invalidData(
                typeName: handledTypeName,
                reason: "Expected \(handledTypeName), got \(message.descriptor.fullName)"
            )
        }
        
        // Извлекаем поля seconds и nanos
        let secondsValue: Int64
        let nanosValue: Int32
        
        do {
            if try message.hasValue(forField: "seconds") {
                if let value = try message.get(forField: "seconds") as? Int64 {
                    secondsValue = value
                } else {
                    secondsValue = 0
                }
            } else {
                secondsValue = 0
            }
            
            if try message.hasValue(forField: "nanos") {
                if let value = try message.get(forField: "nanos") as? Int32 {
                    nanosValue = value
                } else {
                    nanosValue = 0
                }
            } else {
                nanosValue = 0
            }
        } catch {
            throw WellKnownTypeError.conversionFailed(
                from: "DynamicMessage",
                to: "DurationValue",
                reason: "Failed to extract fields: \(error.localizedDescription)"
            )
        }
        
        // Создаем DurationValue
        return try DurationValue(seconds: secondsValue, nanos: nanosValue)
    }
    
    public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
        guard let durationValue = specialized as? DurationValue else {
            throw WellKnownTypeError.conversionFailed(
                from: String(describing: type(of: specialized)),
                to: "DynamicMessage",
                reason: "Expected DurationValue"
            )
        }
        
        // Создаем дескриптор для Duration
        let durationDescriptor = try createDurationDescriptor()
        
        // Создаем сообщение
        let factory = MessageFactory()
        var message = factory.createMessage(from: durationDescriptor)
        
        // Устанавливаем поля
        try message.set(durationValue.seconds, forField: "seconds")
        try message.set(durationValue.nanos, forField: "nanos")
        
        return message
    }
    
    public static func validate(_ specialized: Any) -> Bool {
        guard let durationValue = specialized as? DurationValue else {
            return false
        }
        
        return DurationValue.isValidNanos(durationValue.nanos) &&
               DurationValue.isValidSecondsNanosCombination(seconds: durationValue.seconds, nanos: durationValue.nanos)
    }
    
    // MARK: - Descriptor Creation
    
    /// Создает дескриптор для google.protobuf.Duration
    /// - Returns: MessageDescriptor для Duration
    /// - Throws: ReflectionError если создание неудачно
    private static func createDurationDescriptor() throws -> MessageDescriptor {
        // Создаем файл дескриптор
        var fileDescriptor = FileDescriptor(
            name: "google/protobuf/duration.proto",
            package: "google.protobuf"
        )
        
        // Создаем дескриптор сообщения
        var messageDescriptor = MessageDescriptor(
            name: "Duration",
            parent: fileDescriptor
        )
        
        // Добавляем поле seconds
        let secondsField = FieldDescriptor(
            name: "seconds",
            number: 1,
            type: .int64
        )
        messageDescriptor.addField(secondsField)
        
        // Добавляем поле nanos
        let nanosField = FieldDescriptor(
            name: "nanos",
            number: 2,
            type: .int32
        )
        messageDescriptor.addField(nanosField)
        
        // Регистрируем в файле
        fileDescriptor.addMessage(messageDescriptor)
        
        return messageDescriptor
    }
}

// MARK: - Convenience Extensions

extension TimeInterval {
    
    /// Создает TimeInterval из DurationValue
    /// - Parameter duration: DurationValue
    /// - Returns: TimeInterval
    public init(from duration: DurationHandler.DurationValue) {
        self = duration.toTimeInterval()
    }
    
    /// Конвертирует TimeInterval в DurationValue
    /// - Returns: DurationValue
    public func toDurationValue() -> DurationHandler.DurationValue {
        return DurationHandler.DurationValue(from: self)
    }
}

extension DynamicMessage {
    
    /// Создает DynamicMessage из TimeInterval для google.protobuf.Duration
    /// - Parameter timeInterval: Foundation TimeInterval
    /// - Returns: DynamicMessage представляющий Duration
    /// - Throws: WellKnownTypeError
    public static func durationMessage(from timeInterval: TimeInterval) throws -> DynamicMessage {
        let duration = DurationHandler.DurationValue(from: timeInterval)
        return try DurationHandler.createDynamic(from: duration)
    }
    
    /// Конвертирует DynamicMessage в TimeInterval (если это Duration)
    /// - Returns: TimeInterval
    /// - Throws: WellKnownTypeError если сообщение не является Duration
    public func toTimeInterval() throws -> TimeInterval {
        guard descriptor.fullName == WellKnownTypeNames.duration else {
            throw WellKnownTypeError.invalidData(
                typeName: descriptor.fullName,
                reason: "Message is not a Duration"
            )
        }
        
        let duration = try DurationHandler.createSpecialized(from: self) as! DurationHandler.DurationValue
        return duration.toTimeInterval()
    }
}
