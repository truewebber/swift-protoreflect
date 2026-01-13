//
// MessageFactory.swift
// SwiftProtoReflect
//
// Created: 2025-05-24
//

import Foundation
import SwiftProtobuf

/// MessageFactory.
///
/// Factory for creating and managing dynamic Protocol Buffers messages.
/// Provides convenient methods for creating empty messages, messages with pre-filled
/// values, cloning and validation of existing messages.
public struct MessageFactory: @unchecked Sendable {
  // MARK: - Initialization

  /// Creates a new MessageFactory instance.
  public init() {
  }

  // MARK: - Message Creation Methods

  /// Creates an empty dynamic message based on descriptor.
  ///
  /// - Parameter descriptor: Message descriptor.
  /// - Returns: New empty dynamic message.
  public func createMessage(from descriptor: MessageDescriptor) -> DynamicMessage {
    return DynamicMessage(descriptor: descriptor)
  }

  /// Creates a dynamic message with pre-filled values.
  ///
  /// - Parameters:
  ///   - descriptor: Message descriptor.
  ///   - fieldValues: Dictionary with field values (key - field name, value - field value).
  /// - Returns: New dynamic message with set values.
  /// - Throws: Error if any field doesn't exist or value has wrong type.
  public func createMessage(from descriptor: MessageDescriptor, with fieldValues: [String: Any]) throws
    -> DynamicMessage
  {
    var message = DynamicMessage(descriptor: descriptor)

    for (fieldName, value) in fieldValues {
      try message.set(value, forField: fieldName)
    }

    return message
  }

  /// Creates a dynamic message with pre-filled values, using field numbers.
  ///
  /// - Parameters:
  ///   - descriptor: Message descriptor.
  ///   - fieldValues: Dictionary with field values (key - field number, value - field value).
  /// - Returns: New dynamic message with set values.
  /// - Throws: Error if any field doesn't exist or value has wrong type.
  public func createMessage(from descriptor: MessageDescriptor, with fieldValues: [Int: Any]) throws -> DynamicMessage {
    var message = DynamicMessage(descriptor: descriptor)

    for (fieldNumber, value) in fieldValues {
      try message.set(value, forField: fieldNumber)
    }

    return message
  }

  // MARK: - Message Cloning Methods

  /// Creates a complete copy of existing dynamic message.
  ///
  /// - Parameter message: Source message to clone.
  /// - Returns: New message - exact copy of the source.
  /// - Throws: Error if an error occurred while copying fields.
  public func clone(_ message: DynamicMessage) throws -> DynamicMessage {
    var clonedMessage = DynamicMessage(descriptor: message.descriptor)

    // Copy all set fields
    for field in message.descriptor.allFields() where try message.hasValue(forField: field.number) {
      let value = try message.get(forField: field.number)

      // Handle value, including cases when it might be nil
      // For nested messages create deep copy
      if field.type == .message && !field.isRepeated && !field.isMap {
        if let nestedMessage = value as? DynamicMessage {
          let clonedNestedMessage = try clone(nestedMessage)
          try clonedMessage.set(clonedNestedMessage, forField: field.number)
        }
      }
      else if field.isRepeated && field.type == .message && !field.isMap {
        // For repeated fields with messages create copies of all elements
        if let array = value as? [Any] {
          var clonedArray: [Any] = []
          for item in array {
            if let messageItem = item as? DynamicMessage {
              clonedArray.append(try clone(messageItem))
            }
            else {
              clonedArray.append(item)
            }
          }
          try clonedMessage.set(clonedArray, forField: field.number)
        }
      }
      else if field.isMap {
        // For map fields - use setMapEntry for each key-value pair
        if let map = value as? [AnyHashable: Any] {
          for (key, mapValue) in map {
            if field.mapEntryInfo?.valueFieldInfo.type == .message, let messageValue = mapValue as? DynamicMessage {
              let clonedNestedMessage = try clone(messageValue)
              try clonedMessage.setMapEntry(clonedNestedMessage, forKey: key, inField: field.number)
            }
            else {
              try clonedMessage.setMapEntry(mapValue, forKey: key, inField: field.number)
            }
          }
        }
      }
      else if let actualValue = value {
        // For all other types just copy value if it's not nil
        try clonedMessage.set(actualValue, forField: field.number)
      }
    }

    return clonedMessage
  }

  // MARK: - Message Validation Methods

  /// Validates dynamic message according to its descriptor.
  ///
  /// - Parameter message: Message to validate.
  /// - Returns: Validation result with error information if any.
  public func validate(_ message: DynamicMessage) -> ValidationResult {
    var errors: [ValidationError] = []

    // Check all fields in descriptor
    for field in message.descriptor.allFields() {
      do {
        let hasValue = try message.hasValue(forField: field.number)

        // Check required fields (for proto2)
        if field.isRequired && !hasValue {
          errors.append(.missingRequiredField(fieldName: field.name))
          continue
        }

        // If value is set, check its correctness
        if hasValue {
          let value = try message.get(forField: field.number)
          if let actualValue = value {
            let fieldErrors = try validateFieldValue(actualValue, for: field, message: message)
            errors.append(contentsOf: fieldErrors)
          }
        }
      }
      catch {
        errors.append(.validationError(fieldName: field.name, error: error))
      }
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors)
  }

  // MARK: - Private Helper Methods

  /// Validates correctness of specific field value.
  ///
  /// - Parameters:
  ///   - value: Value to validate.
  ///   - field: Field descriptor.
  ///   - message: Message containing the value.
  /// - Returns: Array of validation errors (empty if no errors).
  /// - Throws: Error if unexpected validation error occurred.
  private func validateFieldValue(_ value: Any, for field: FieldDescriptor, message: DynamicMessage) throws
    -> [ValidationError]
  {
    var errors: [ValidationError] = []

    // Check map fields FIRST (since they also have isRepeated = true)
    if field.isMap && field.mapEntryInfo?.valueFieldInfo.type == .message {
      // For map fields with messages as values
      if let map = value as? [AnyHashable: Any] {
        for (key, mapValue) in map {
          if let messageValue = mapValue as? DynamicMessage {
            let nestedResult = validate(messageValue)
            if !nestedResult.isValid {
              errors.append(
                .mapFieldValidationFailed(
                  fieldName: field.name,
                  key: String(describing: key),
                  nestedErrors: nestedResult.errors
                )
              )
            }
          }
        }
      }
    }
    else if field.isRepeated && field.type == .message {
      // For repeated fields with messages (NOT map)
      if let array = value as? [Any] {
        for (index, item) in array.enumerated() {
          if let messageItem = item as? DynamicMessage {
            let nestedResult = validate(messageItem)
            if !nestedResult.isValid {
              errors.append(
                .repeatedFieldValidationFailed(
                  fieldName: field.name,
                  index: index,
                  nestedErrors: nestedResult.errors
                )
              )
            }
          }
        }
      }
    }
    else if field.type == .message && !field.isRepeated && !field.isMap {
      // For simple nested messages
      if let nestedMessage = value as? DynamicMessage {
        let nestedResult = validate(nestedMessage)
        if !nestedResult.isValid {
          errors.append(
            .nestedMessageValidationFailed(
              fieldName: field.name,
              nestedErrors: nestedResult.errors
            )
          )
        }
      }
    }

    return errors
  }
}

// MARK: - Validation Types

/// Message validation result.
public struct ValidationResult {
  /// Flag indicating if message is valid.
  public let isValid: Bool

  /// Array of validation errors (empty for valid messages).
  public let errors: [ValidationError]

  /// Creates a new validation result.
  ///
  /// - Parameters:
  ///   - isValid: Validity flag.
  ///   - errors: Array of errors.
  public init(isValid: Bool, errors: [ValidationError]) {
    self.isValid = isValid
    self.errors = errors
  }
}

/// Message validation error types.
public enum ValidationError: Error, Equatable {
  /// Missing required field.
  case missingRequiredField(fieldName: String)

  /// Nested message validation failed.
  case nestedMessageValidationFailed(fieldName: String, nestedErrors: [ValidationError])

  /// Repeated field element validation failed.
  case repeatedFieldValidationFailed(fieldName: String, index: Int, nestedErrors: [ValidationError])

  /// Map field value validation failed.
  case mapFieldValidationFailed(fieldName: String, key: String, nestedErrors: [ValidationError])

  /// General field validation error.
  case validationError(fieldName: String, error: Error)

  // MARK: - Equatable

  public static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
    switch (lhs, rhs) {
    case (.missingRequiredField(let lhsField), .missingRequiredField(let rhsField)):
      return lhsField == rhsField
    case (
      .nestedMessageValidationFailed(let lhsField, let lhsErrors),
      .nestedMessageValidationFailed(let rhsField, let rhsErrors)
    ):
      return lhsField == rhsField && lhsErrors == rhsErrors
    case (
      .repeatedFieldValidationFailed(let lhsField, let lhsIndex, let lhsErrors),
      .repeatedFieldValidationFailed(let rhsField, let rhsIndex, let rhsErrors)
    ):
      return lhsField == rhsField && lhsIndex == rhsIndex && lhsErrors == rhsErrors
    case (
      .mapFieldValidationFailed(let lhsField, let lhsKey, let lhsErrors),
      .mapFieldValidationFailed(let rhsField, let rhsKey, let rhsErrors)
    ):
      return lhsField == rhsField && lhsKey == rhsKey && lhsErrors == rhsErrors
    case (.validationError(let lhsField, _), .validationError(let rhsField, _)):
      return lhsField == rhsField  // Don't compare Error as it's not Equatable
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
