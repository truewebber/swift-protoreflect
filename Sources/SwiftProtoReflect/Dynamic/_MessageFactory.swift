//
// _MessageFactory.swift
// SwiftProtoReflect
//
// Created: 2025-05-24
//

import Foundation
import SwiftProtobuf

/// Internal factory for creating and validating `_DynamicMessage` values.
internal struct _MessageFactory {

  func createMessage(from descriptor: _MessageDescriptor) -> _DynamicMessage {
    _DynamicMessage(descriptor: descriptor)
  }

  func createMessage(from descriptor: _MessageDescriptor, with fieldValues: [String: Any]) throws -> _DynamicMessage {
    var message = _DynamicMessage(descriptor: descriptor)
    for (fieldName, value) in fieldValues {
      try message.set(value, forField: fieldName)
    }
    return message
  }

  func createMessage(from descriptor: _MessageDescriptor, with fieldValues: [Int: Any]) throws -> _DynamicMessage {
    var message = _DynamicMessage(descriptor: descriptor)
    for (fieldNumber, value) in fieldValues {
      try message.set(value, forField: fieldNumber)
    }
    return message
  }

  func clone(_ message: _DynamicMessage) throws -> _DynamicMessage {
    var clonedMessage = _DynamicMessage(descriptor: message.descriptor)

    for field in message.descriptor.allFields() where try message.hasValue(forField: field.number) {
      let value = try message.get(forField: field.number)

      if field.type == .message && !field.isRepeated && !field.isMap {
        if let nestedMessage = value as? _DynamicMessage {
          let clonedNestedMessage = try clone(nestedMessage)
          try clonedMessage.set(clonedNestedMessage, forField: field.number)
        }
      }
      else if field.isRepeated && field.type == .message && !field.isMap {
        if let array = value as? [Any] {
          var clonedArray: [Any] = []
          for item in array {
            if let messageItem = item as? _DynamicMessage {
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
        if let map = value as? [AnyHashable: Any] {
          for (key, mapValue) in map {
            if field.mapEntryInfo?.valueFieldInfo.type == .message, let messageValue = mapValue as? _DynamicMessage {
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
        try clonedMessage.set(actualValue, forField: field.number)
      }
    }

    if !message.unknownFields.isEmpty {
      clonedMessage.setUnknownFields(message.unknownFields)
    }

    return clonedMessage
  }

  func validate(_ message: _DynamicMessage) -> ValidationResult {
    performValidation(message, syntax: message.descriptor.syntax)
  }

  private func performValidation(_ message: _DynamicMessage, syntax: String) -> ValidationResult {
    var errors: [ValidationError] = []

    for field in message.descriptor.allFields() {
      do {
        let hasValue = try message.hasValue(forField: field.number)

        if syntax != "proto3" && field.isRequired && !hasValue {
          errors.append(.missingRequiredField(fieldName: field.name))
          continue
        }

        if hasValue {
          let value = try message.get(forField: field.number)
          if let actualValue = value {
            let fieldErrors = try validateFieldValue(actualValue, for: field, syntax: syntax)
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

  private func validateFieldValue(
    _ value: Any,
    for field: _FieldDescriptor,
    syntax: String = "proto3"
  ) throws -> [ValidationError] {
    var errors: [ValidationError] = []

    if field.isMap && field.mapEntryInfo?.valueFieldInfo.type == .message {
      if let map = value as? [AnyHashable: Any] {
        for (key, mapValue) in map {
          if let messageValue = mapValue as? _DynamicMessage {
            let nestedResult = performValidation(messageValue, syntax: syntax)
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
      if let array = value as? [Any] {
        for (index, item) in array.enumerated() {
          if let messageItem = item as? _DynamicMessage {
            let nestedResult = performValidation(messageItem, syntax: syntax)
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
      if let nestedMessage = value as? _DynamicMessage {
        let nestedResult = performValidation(nestedMessage, syntax: syntax)
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
