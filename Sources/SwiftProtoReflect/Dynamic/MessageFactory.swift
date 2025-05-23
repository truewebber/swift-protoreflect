//
// MessageFactory.swift
// SwiftProtoReflect
//
// Создан: 2025-05-24
//

import Foundation
import SwiftProtobuf

/// MessageFactory
///
/// Фабрика для создания и управления динамическими сообщениями Protocol Buffers.
/// Предоставляет удобные методы для создания пустых сообщений, сообщений с предзаполненными
/// значениями, клонирования и валидации существующих сообщений.
public struct MessageFactory {
  // MARK: - Initialization
  
  /// Создает новый экземпляр MessageFactory
  public init() {
  }
  
  // MARK: - Message Creation Methods
  
  /// Создает пустое динамическое сообщение на основе дескриптора.
  ///
  /// - Parameter descriptor: Дескриптор сообщения.
  /// - Returns: Новое пустое динамическое сообщение.
  public func createMessage(from descriptor: MessageDescriptor) -> DynamicMessage {
    return DynamicMessage(descriptor: descriptor)
  }
  
  /// Создает динамическое сообщение с предзаполненными значениями.
  ///
  /// - Parameters:
  ///   - descriptor: Дескриптор сообщения.
  ///   - fieldValues: Словарь со значениями полей (ключ - имя поля, значение - значение поля).
  /// - Returns: Новое динамическое сообщение с установленными значениями.
  /// - Throws: Ошибку, если какое-либо поле не существует или значение имеет неправильный тип.
  public func createMessage(from descriptor: MessageDescriptor, with fieldValues: [String: Any]) throws -> DynamicMessage {
    var message = DynamicMessage(descriptor: descriptor)
    
    for (fieldName, value) in fieldValues {
      try message.set(value, forField: fieldName)
    }
    
    return message
  }
  
  /// Создает динамическое сообщение с предзаполненными значениями, используя номера полей.
  ///
  /// - Parameters:
  ///   - descriptor: Дескриптор сообщения.
  ///   - fieldValues: Словарь со значениями полей (ключ - номер поля, значение - значение поля).
  /// - Returns: Новое динамическое сообщение с установленными значениями.
  /// - Throws: Ошибку, если какое-либо поле не существует или значение имеет неправильный тип.
  public func createMessage(from descriptor: MessageDescriptor, with fieldValues: [Int: Any]) throws -> DynamicMessage {
    var message = DynamicMessage(descriptor: descriptor)
    
    for (fieldNumber, value) in fieldValues {
      try message.set(value, forField: fieldNumber)
    }
    
    return message
  }
  
  // MARK: - Message Cloning Methods
  
  /// Создает полную копию существующего динамического сообщения.
  ///
  /// - Parameter message: Исходное сообщение для клонирования.
  /// - Returns: Новое сообщение - точная копия исходного.
  /// - Throws: Ошибку, если произошла ошибка при копировании полей.
  public func clone(_ message: DynamicMessage) throws -> DynamicMessage {
    var clonedMessage = DynamicMessage(descriptor: message.descriptor)
    
    // Копируем все установленные поля
    for field in message.descriptor.allFields() {
      if try message.hasValue(forField: field.number) {
        let value = try message.get(forField: field.number)
        
        // Обрабатываем значение, включая случаи когда оно может быть nil
        // Для вложенных сообщений создаем глубокую копию
        if field.type == .message && !field.isRepeated && !field.isMap {
          if let nestedMessage = value as? DynamicMessage {
            let clonedNestedMessage = try clone(nestedMessage)
            try clonedMessage.set(clonedNestedMessage, forField: field.number)
          }
        } else if field.isRepeated && field.type == .message && !field.isMap {
          // Для repeated полей с сообщениями создаем копии всех элементов
          if let array = value as? [Any] {
            var clonedArray: [Any] = []
            for item in array {
              if let messageItem = item as? DynamicMessage {
                clonedArray.append(try clone(messageItem))
              } else {
                clonedArray.append(item)
              }
            }
            try clonedMessage.set(clonedArray, forField: field.number)
          }
        } else if field.isMap {
          // Для map полей - используем setMapEntry для каждой пары ключ-значение
          if let map = value as? [AnyHashable: Any] {
            for (key, mapValue) in map {
              if field.mapEntryInfo?.valueFieldInfo.type == .message, let messageValue = mapValue as? DynamicMessage {
                let clonedNestedMessage = try clone(messageValue)
                try clonedMessage.setMapEntry(clonedNestedMessage, forKey: key, inField: field.number)
              } else {
                try clonedMessage.setMapEntry(mapValue, forKey: key, inField: field.number)
              }
            }
          }
        } else if let actualValue = value {
          // Для всех остальных типов просто копируем значение, если оно не nil
          try clonedMessage.set(actualValue, forField: field.number)
        }
      }
    }
    
    return clonedMessage
  }
  
  // MARK: - Message Validation Methods
  
  /// Проверяет валидность динамического сообщения согласно его дескриптору.
  ///
  /// - Parameter message: Сообщение для проверки.
  /// - Returns: Результат валидации с информацией об ошибках, если они есть.
  public func validate(_ message: DynamicMessage) -> ValidationResult {
    var errors: [ValidationError] = []
    
    // Проверяем все поля в дескрипторе
    for field in message.descriptor.allFields() {
      do {
        let hasValue = try message.hasValue(forField: field.number)
        
        // Проверка обязательных полей (для proto2)
        if field.isRequired && !hasValue {
          errors.append(.missingRequiredField(fieldName: field.name))
          continue
        }
        
        // Если значение установлено, проверяем его корректность
        if hasValue {
          let value = try message.get(forField: field.number)
          if let actualValue = value {
            let fieldErrors = try validateFieldValue(actualValue, for: field, message: message)
            errors.append(contentsOf: fieldErrors)
          }
        }
      } catch {
        errors.append(.validationError(fieldName: field.name, error: error))
      }
    }
    
    return ValidationResult(isValid: errors.isEmpty, errors: errors)
  }
  
  // MARK: - Private Helper Methods
  
  /// Проверяет корректность значения конкретного поля.
  ///
  /// - Parameters:
  ///   - value: Значение для проверки.
  ///   - field: Дескриптор поля.
  ///   - message: Сообщение, содержащее значение.
  /// - Returns: Массив ошибок валидации (пустой, если ошибок нет).
  /// - Throws: Ошибку, если произошла неожиданная ошибка валидации.
  private func validateFieldValue(_ value: Any, for field: FieldDescriptor, message: DynamicMessage) throws -> [ValidationError] {
    var errors: [ValidationError] = []
    
    // Для вложенных сообщений рекурсивно проверяем их содержимое
    if field.type == .message {
      if let nestedMessage = value as? DynamicMessage {
        let nestedResult = validate(nestedMessage)
        if !nestedResult.isValid {
          errors.append(.nestedMessageValidationFailed(
            fieldName: field.name,
            nestedErrors: nestedResult.errors
          ))
        }
      }
    } else if field.isRepeated && field.type == .message {
      // Для repeated полей с сообщениями
      if let array = value as? [Any] {
        for (index, item) in array.enumerated() {
          if let messageItem = item as? DynamicMessage {
            let nestedResult = validate(messageItem)
            if !nestedResult.isValid {
              errors.append(.repeatedFieldValidationFailed(
                fieldName: field.name,
                index: index,
                nestedErrors: nestedResult.errors
              ))
            }
          }
        }
      }
    } else if field.isMap && field.mapEntryInfo?.valueFieldInfo.type == .message {
      // Для map полей с сообщениями в качестве значений
      if let map = value as? [AnyHashable: Any] {
        for (key, mapValue) in map {
          if let messageValue = mapValue as? DynamicMessage {
            let nestedResult = validate(messageValue)
            if !nestedResult.isValid {
              errors.append(.mapFieldValidationFailed(
                fieldName: field.name,
                key: String(describing: key),
                nestedErrors: nestedResult.errors
              ))
            }
          }
        }
      }
    }
    
    return errors
  }
}

// MARK: - Validation Types

/// Результат валидации сообщения.
public struct ValidationResult {
  /// Флаг, указывающий, является ли сообщение валидным.
  public let isValid: Bool
  
  /// Массив ошибок валидации (пустой для валидных сообщений).
  public let errors: [ValidationError]
  
  /// Создает новый результат валидации.
  ///
  /// - Parameters:
  ///   - isValid: Флаг валидности.
  ///   - errors: Массив ошибок.
  public init(isValid: Bool, errors: [ValidationError]) {
    self.isValid = isValid
    self.errors = errors
  }
}

/// Типы ошибок валидации сообщений.
public enum ValidationError: Error, Equatable {
  /// Отсутствует обязательное поле.
  case missingRequiredField(fieldName: String)
  
  /// Ошибка валидации вложенного сообщения.
  case nestedMessageValidationFailed(fieldName: String, nestedErrors: [ValidationError])
  
  /// Ошибка валидации элемента в repeated поле.
  case repeatedFieldValidationFailed(fieldName: String, index: Int, nestedErrors: [ValidationError])
  
  /// Ошибка валидации значения в map поле.
  case mapFieldValidationFailed(fieldName: String, key: String, nestedErrors: [ValidationError])
  
  /// Общая ошибка валидации поля.
  case validationError(fieldName: String, error: Error)
  
  // MARK: - Equatable
  
  public static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
    switch (lhs, rhs) {
    case (.missingRequiredField(let lhsField), .missingRequiredField(let rhsField)):
      return lhsField == rhsField
    case (.nestedMessageValidationFailed(let lhsField, let lhsErrors), 
          .nestedMessageValidationFailed(let rhsField, let rhsErrors)):
      return lhsField == rhsField && lhsErrors == rhsErrors
    case (.repeatedFieldValidationFailed(let lhsField, let lhsIndex, let lhsErrors),
          .repeatedFieldValidationFailed(let rhsField, let rhsIndex, let rhsErrors)):
      return lhsField == rhsField && lhsIndex == rhsIndex && lhsErrors == rhsErrors
    case (.mapFieldValidationFailed(let lhsField, let lhsKey, let lhsErrors),
          .mapFieldValidationFailed(let rhsField, let rhsKey, let rhsErrors)):
      return lhsField == rhsField && lhsKey == rhsKey && lhsErrors == rhsErrors
    case (.validationError(let lhsField, _), .validationError(let rhsField, _)):
      return lhsField == rhsField  // Не сравниваем Error, так как он не Equatable
    default:
      return false
    }
  }
}

extension ValidationError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .missingRequiredField(let fieldName):
      return "Missing required field: \(fieldName)"
    case .nestedMessageValidationFailed(let fieldName, let nestedErrors):
      return "Validation failed for nested message in field '\(fieldName)': \(nestedErrors.count) error(s)"
    case .repeatedFieldValidationFailed(let fieldName, let index, let nestedErrors):
      return "Validation failed for repeated field '\(fieldName)' at index \(index): \(nestedErrors.count) error(s)"
    case .mapFieldValidationFailed(let fieldName, let key, let nestedErrors):
      return "Validation failed for map field '\(fieldName)' at key '\(key)': \(nestedErrors.count) error(s)"
    case .validationError(let fieldName, let error):
      return "Validation error for field '\(fieldName)': \(error.localizedDescription)"
    }
  }
}
