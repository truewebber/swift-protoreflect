//
// FieldAccessor.swift
// SwiftProtoReflect
//
// Created: 2025-05-24
//

import Foundation
import SwiftProtobuf

/// FieldAccessor.
///
/// Provides type-safe and convenient interface for accessing fields
/// of dynamic Protocol Buffers messages. Simplifies getting and setting
/// field values with minimal error handling and maximum type safety.
public struct FieldAccessor {
  // MARK: - Properties

  /// Target message for field access.
  private let message: DynamicMessage

  // MARK: - Initialization

  /// Creates a new FieldAccessor instance for the given message.
  ///
  /// - Parameter message: Dynamic message for field access.
  public init(_ message: DynamicMessage) {
    self.message = message
  }

  // MARK: - Typed Field Access Methods

  /// Safely gets string field value.
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: String value or nil if field is not set or has different type.
  public func getString(_ fieldName: String) -> String? {
    return getValue(fieldName, as: String.self)
  }

  /// Safely gets string field value by number.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: String value or nil if field is not set or has different type.
  public func getString(_ fieldNumber: Int) -> String? {
    return getValue(fieldNumber, as: String.self)
  }

  /// Safely gets integer field value (Int32).
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: Integer value or nil if field is not set or has different type.
  public func getInt32(_ fieldName: String) -> Int32? {
    return getValue(fieldName, as: Int32.self)
  }

  /// Safely gets integer field value (Int32) by number.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: Integer value or nil if field is not set or has different type.
  public func getInt32(_ fieldNumber: Int) -> Int32? {
    return getValue(fieldNumber, as: Int32.self)
  }

  /// Safely gets integer field value (Int64).
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: Integer value or nil if field is not set or has different type.
  public func getInt64(_ fieldName: String) -> Int64? {
    return getValue(fieldName, as: Int64.self)
  }

  /// Safely gets integer field value (Int64) by number.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: Integer value or nil if field is not set or has different type.
  public func getInt64(_ fieldNumber: Int) -> Int64? {
    return getValue(fieldNumber, as: Int64.self)
  }

  /// Safely gets unsigned integer field value (UInt32).
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: Unsigned integer value or nil if field is not set or has different type.
  public func getUInt32(_ fieldName: String) -> UInt32? {
    return getValue(fieldName, as: UInt32.self)
  }

  /// Safely gets unsigned integer field value (UInt32) by number.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: Unsigned integer value or nil if field is not set or has different type.
  public func getUInt32(_ fieldNumber: Int) -> UInt32? {
    return getValue(fieldNumber, as: UInt32.self)
  }

  /// Safely gets unsigned integer field value (UInt64).
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: Unsigned integer value or nil if field is not set or has different type.
  public func getUInt64(_ fieldName: String) -> UInt64? {
    return getValue(fieldName, as: UInt64.self)
  }

  /// Safely gets unsigned integer field value (UInt64) by number.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: Unsigned integer value or nil if field is not set or has different type.
  public func getUInt64(_ fieldNumber: Int) -> UInt64? {
    return getValue(fieldNumber, as: UInt64.self)
  }

  /// Safely gets floating point field value (Float).
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: Floating point value or nil if field is not set or has different type.
  public func getFloat(_ fieldName: String) -> Float? {
    return getValue(fieldName, as: Float.self)
  }

  /// Safely gets floating point field value (Float) by number.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: Floating point value or nil if field is not set or has different type.
  public func getFloat(_ fieldNumber: Int) -> Float? {
    return getValue(fieldNumber, as: Float.self)
  }

  /// Safely gets floating point field value (Double).
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: Floating point value or nil if field is not set or has different type.
  public func getDouble(_ fieldName: String) -> Double? {
    return getValue(fieldName, as: Double.self)
  }

  /// Safely gets floating point field value (Double) by number.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: Floating point value or nil if field is not set or has different type.
  public func getDouble(_ fieldNumber: Int) -> Double? {
    return getValue(fieldNumber, as: Double.self)
  }

  /// Safely gets boolean field value.
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: Boolean value or nil if field is not set or has different type.
  public func getBool(_ fieldName: String) -> Bool? {
    return getValue(fieldName, as: Bool.self)
  }

  /// Safely gets boolean field value by number.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: Boolean value or nil if field is not set or has different type.
  public func getBool(_ fieldNumber: Int) -> Bool? {
    return getValue(fieldNumber, as: Bool.self)
  }

  /// Safely gets data field value.
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: Data or nil if field is not set or has different type.
  public func getData(_ fieldName: String) -> Data? {
    return getValue(fieldName, as: Data.self)
  }

  /// Safely gets data field value by number.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: Data or nil if field is not set or has different type.
  public func getData(_ fieldNumber: Int) -> Data? {
    return getValue(fieldNumber, as: Data.self)
  }

  /// Safely gets nested message field value.
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: Dynamic message or nil if field is not set or has different type.
  public func getMessage(_ fieldName: String) -> DynamicMessage? {
    return getValue(fieldName, as: DynamicMessage.self)
  }

  /// Safely gets nested message field value by number.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: Dynamic message or nil if field is not set or has different type.
  public func getMessage(_ fieldNumber: Int) -> DynamicMessage? {
    return getValue(fieldNumber, as: DynamicMessage.self)
  }

  // MARK: - Repeated Field Access Methods

  /// Safely gets repeated string field.
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: Array of strings or nil if field is not set or has different type.
  public func getStringArray(_ fieldName: String) -> [String]? {
    return getRepeatedValue(fieldName, as: String.self)
  }

  /// Safely gets repeated string field by number.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: Array of strings or nil if field is not set or has different type.
  public func getStringArray(_ fieldNumber: Int) -> [String]? {
    return getRepeatedValue(fieldNumber, as: String.self)
  }

  /// Safely gets repeated integer field (Int32).
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: Array of integers or nil if field is not set or has different type.
  public func getInt32Array(_ fieldName: String) -> [Int32]? {
    return getRepeatedValue(fieldName, as: Int32.self)
  }

  /// Safely gets repeated integer field (Int32) by number.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: Array of integers or nil if field is not set or has different type.
  public func getInt32Array(_ fieldNumber: Int) -> [Int32]? {
    return getRepeatedValue(fieldNumber, as: Int32.self)
  }

  /// Safely gets repeated integer field (Int64).
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: Array of integers or nil if field is not set or has different type.
  public func getInt64Array(_ fieldName: String) -> [Int64]? {
    return getRepeatedValue(fieldName, as: Int64.self)
  }

  /// Safely gets repeated integer field (Int64) by number.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: Array of integers or nil if field is not set or has different type.
  public func getInt64Array(_ fieldNumber: Int) -> [Int64]? {
    return getRepeatedValue(fieldNumber, as: Int64.self)
  }

  /// Safely gets repeated nested message field.
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: Array of dynamic messages or nil if field is not set or has different type.
  public func getMessageArray(_ fieldName: String) -> [DynamicMessage]? {
    return getRepeatedValue(fieldName, as: DynamicMessage.self)
  }

  /// Safely gets repeated nested message field by number.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: Array of dynamic messages or nil if field is not set or has different type.
  public func getMessageArray(_ fieldNumber: Int) -> [DynamicMessage]? {
    return getRepeatedValue(fieldNumber, as: DynamicMessage.self)
  }

  // MARK: - Map Field Access Methods

  /// Safely gets map field with string keys and values.
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: Dictionary of strings or nil if field is not set or has different type.
  public func getStringMap(_ fieldName: String) -> [String: String]? {
    return getMapValue(fieldName, keyType: String.self, valueType: String.self)
  }

  /// Safely gets map field with string keys and values by number.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: Dictionary of strings or nil if field is not set or has different type.
  public func getStringMap(_ fieldNumber: Int) -> [String: String]? {
    return getMapValue(fieldNumber, keyType: String.self, valueType: String.self)
  }

  /// Safely gets map field with string keys and integer values (Int32).
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: Dictionary with integer values or nil if field is not set or has different type.
  public func getStringToInt32Map(_ fieldName: String) -> [String: Int32]? {
    return getMapValue(fieldName, keyType: String.self, valueType: Int32.self)
  }

  /// Safely gets map field with string keys and integer values (Int32) by number.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: Dictionary with integer values or nil if field is not set or has different type.
  public func getStringToInt32Map(_ fieldNumber: Int) -> [String: Int32]? {
    return getMapValue(fieldNumber, keyType: String.self, valueType: Int32.self)
  }

  /// Safely gets map field with string keys and messages as values.
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: Dictionary with messages or nil if field is not set or has different type.
  public func getStringToMessageMap(_ fieldName: String) -> [String: DynamicMessage]? {
    return getMapValue(fieldName, keyType: String.self, valueType: DynamicMessage.self)
  }

  /// Safely gets map field with string keys and messages as values by number.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: Dictionary with messages or nil if field is not set or has different type.
  public func getStringToMessageMap(_ fieldNumber: Int) -> [String: DynamicMessage]? {
    return getMapValue(fieldNumber, keyType: String.self, valueType: DynamicMessage.self)
  }

  // MARK: - Field Existence and Safety Methods

  /// Checks if field exists and has a value set.
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: true if field exists and has value, false otherwise.
  public func hasValue(_ fieldName: String) -> Bool {
    do {
      return try message.hasValue(forField: fieldName)
    }
    catch {
      return false
    }
  }

  /// Checks if field exists and has a value set by number.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: true if field exists and has value, false otherwise.
  public func hasValue(_ fieldNumber: Int) -> Bool {
    do {
      return try message.hasValue(forField: fieldNumber)
    }
    catch {
      return false
    }
  }

  /// Checks if field exists in message descriptor.
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: true if field exists in descriptor.
  public func fieldExists(_ fieldName: String) -> Bool {
    return message.descriptor.field(named: fieldName) != nil
  }

  /// Checks if field exists in message descriptor by number.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: true if field exists in descriptor.
  public func fieldExists(_ fieldNumber: Int) -> Bool {
    return message.descriptor.field(number: fieldNumber) != nil
  }

  /// Gets field type by name.
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: Field type or nil if field doesn't exist.
  public func getFieldType(_ fieldName: String) -> FieldType? {
    return message.descriptor.field(named: fieldName)?.type
  }

  /// Gets field type by number.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: Field type or nil if field doesn't exist.
  public func getFieldType(_ fieldNumber: Int) -> FieldType? {
    return message.descriptor.field(number: fieldNumber)?.type
  }

  // MARK: - Generic Field Access Methods

  /// Generic method for safely getting field value with cast to specified type.
  ///
  /// - Parameters:
  ///   - fieldName: Field name.
  ///   - type: Type to cast value to.
  /// - Returns: Value of specified type or nil if field is not set or has different type.
  public func getValue<T>(_ fieldName: String, as type: T.Type) -> T? {
    do {
      guard let value = try message.get(forField: fieldName) else {
        return nil
      }
      return value as? T
    }
    catch {
      return nil
    }
  }

  /// Generic method for safely getting field value with cast to specified type by number.
  ///
  /// - Parameters:
  ///   - fieldNumber: Field number.
  ///   - type: Type to cast value to.
  /// - Returns: Value of specified type or nil if field is not set or has different type.
  public func getValue<T>(_ fieldNumber: Int, as type: T.Type) -> T? {
    do {
      guard let value = try message.get(forField: fieldNumber) else {
        return nil
      }
      return value as? T
    }
    catch {
      return nil
    }
  }

  // MARK: - Private Helper Methods

  /// Safely gets repeated field with elements of specified type.
  ///
  /// - Parameters:
  ///   - fieldName: Field name.
  ///   - type: Type of array elements.
  /// - Returns: Array of elements of specified type or nil.
  private func getRepeatedValue<T>(_ fieldName: String, as type: T.Type) -> [T]? {
    do {
      guard let value = try message.get(forField: fieldName) else {
        return nil
      }
      guard let array = value as? [Any] else {
        return nil
      }

      // Check that all elements have correct type
      var result: [T] = []
      for item in array {
        guard let typedItem = item as? T else {
          return nil  // If at least one element doesn't match type, return nil
        }
        result.append(typedItem)
      }

      return result
    }
    catch {
      return nil
    }
  }

  /// Safely gets repeated field with elements of specified type by number.
  ///
  /// - Parameters:
  ///   - fieldNumber: Field number.
  ///   - type: Type of array elements.
  /// - Returns: Array of elements of specified type or nil.
  private func getRepeatedValue<T>(_ fieldNumber: Int, as type: T.Type) -> [T]? {
    do {
      guard let value = try message.get(forField: fieldNumber) else {
        return nil
      }
      guard let array = value as? [Any] else {
        return nil
      }

      // Check that all elements have correct type
      var result: [T] = []
      for item in array {
        guard let typedItem = item as? T else {
          return nil  // If at least one element doesn't match type, return nil
        }
        result.append(typedItem)
      }

      return result
    }
    catch {
      return nil
    }
  }

  /// Safely gets map field with keys and values of specified types.
  ///
  /// - Parameters:
  ///   - fieldName: Field name.
  ///   - keyType: Type of keys.
  ///   - valueType: Type of values.
  /// - Returns: Dictionary with keys and values of specified types or nil.
  private func getMapValue<K: Hashable, V>(_ fieldName: String, keyType: K.Type, valueType: V.Type) -> [K: V]? {
    do {
      guard let value = try message.get(forField: fieldName) else {
        return nil
      }
      guard let map = value as? [AnyHashable: Any] else {
        return nil
      }

      // Check and convert keys and values
      var result: [K: V] = [:]
      for (key, mapValue) in map {
        guard let typedKey = key as? K else {
          return nil  // If at least one key doesn't match type, return nil
        }
        guard let typedValue = mapValue as? V else {
          return nil  // If at least one value doesn't match type, return nil
        }
        result[typedKey] = typedValue
      }

      return result
    }
    catch {
      return nil
    }
  }

  /// Safely gets map field with keys and values of specified types by number.
  ///
  /// - Parameters:
  ///   - fieldNumber: Field number.
  ///   - keyType: Type of keys.
  ///   - valueType: Type of values.
  /// - Returns: Dictionary with keys and values of specified types or nil.
  private func getMapValue<K: Hashable, V>(_ fieldNumber: Int, keyType: K.Type, valueType: V.Type) -> [K: V]? {
    do {
      guard let value = try message.get(forField: fieldNumber) else {
        return nil
      }
      guard let map = value as? [AnyHashable: Any] else {
        return nil
      }

      // Check and convert keys and values
      var result: [K: V] = [:]
      for (key, mapValue) in map {
        guard let typedKey = key as? K else {
          return nil  // If at least one key doesn't match type, return nil
        }
        guard let typedValue = mapValue as? V else {
          return nil  // If at least one value doesn't match type, return nil
        }
        result[typedKey] = typedValue
      }

      return result
    }
    catch {
      return nil
    }
  }
}

// MARK: - Mutable Field Access

/// MutableFieldAccessor.
///
/// Extension of FieldAccessor for mutable access to dynamic message fields.
/// Allows safely setting field values with minimal error handling.
public struct MutableFieldAccessor {
  // MARK: - Properties

  /// Target message for field modification.
  private var message: DynamicMessage

  // MARK: - Initialization

  /// Creates a new MutableFieldAccessor instance for the given message.
  ///
  /// - Parameter message: Dynamic message for field modification.
  public init(_ message: inout DynamicMessage) {
    self.message = message
  }

  // MARK: - Field Setting Methods

  /// Safely sets string field value.
  ///
  /// - Parameters:
  ///   - value: String value to set.
  ///   - fieldName: Field name.
  /// - Returns: true if value was successfully set, false otherwise.
  @discardableResult
  public mutating func setString(_ value: String, forField fieldName: String) -> Bool {
    do {
      try message.set(value, forField: fieldName)
      return true
    }
    catch {
      return false
    }
  }

  /// Safely sets string field value by number.
  ///
  /// - Parameters:
  ///   - value: String value to set.
  ///   - fieldNumber: Field number.
  /// - Returns: true if value was successfully set, false otherwise.
  @discardableResult
  public mutating func setString(_ value: String, forField fieldNumber: Int) -> Bool {
    do {
      try message.set(value, forField: fieldNumber)
      return true
    }
    catch {
      return false
    }
  }

  /// Safely sets integer field value (Int32).
  ///
  /// - Parameters:
  ///   - value: Integer value to set.
  ///   - fieldName: Field name.
  /// - Returns: true if value was successfully set, false otherwise.
  @discardableResult
  public mutating func setInt32(_ value: Int32, forField fieldName: String) -> Bool {
    do {
      try message.set(value, forField: fieldName)
      return true
    }
    catch {
      return false
    }
  }

  /// Safely sets integer field value (Int32) by number.
  ///
  /// - Parameters:
  ///   - value: Integer value to set.
  ///   - fieldNumber: Field number.
  /// - Returns: true if value was successfully set, false otherwise.
  @discardableResult
  public mutating func setInt32(_ value: Int32, forField fieldNumber: Int) -> Bool {
    do {
      try message.set(value, forField: fieldNumber)
      return true
    }
    catch {
      return false
    }
  }

  /// Safely sets boolean field value.
  ///
  /// - Parameters:
  ///   - value: Boolean value to set.
  ///   - fieldName: Field name.
  /// - Returns: true if value was successfully set, false otherwise.
  @discardableResult
  public mutating func setBool(_ value: Bool, forField fieldName: String) -> Bool {
    do {
      try message.set(value, forField: fieldName)
      return true
    }
    catch {
      return false
    }
  }

  /// Safely sets boolean field value by number.
  ///
  /// - Parameters:
  ///   - value: Boolean value to set.
  ///   - fieldNumber: Field number.
  /// - Returns: true if value was successfully set, false otherwise.
  @discardableResult
  public mutating func setBool(_ value: Bool, forField fieldNumber: Int) -> Bool {
    do {
      try message.set(value, forField: fieldNumber)
      return true
    }
    catch {
      return false
    }
  }

  /// Safely sets nested message field value.
  ///
  /// - Parameters:
  ///   - value: Dynamic message to set.
  ///   - fieldName: Field name.
  /// - Returns: true if value was successfully set, false otherwise.
  @discardableResult
  public mutating func setMessage(_ value: DynamicMessage, forField fieldName: String) -> Bool {
    do {
      try message.set(value, forField: fieldName)
      return true
    }
    catch {
      return false
    }
  }

  /// Safely sets nested message field value by number.
  ///
  /// - Parameters:
  ///   - value: Dynamic message to set.
  ///   - fieldNumber: Field number.
  /// - Returns: true if value was successfully set, false otherwise.
  @discardableResult
  public mutating func setMessage(_ value: DynamicMessage, forField fieldNumber: Int) -> Bool {
    do {
      try message.set(value, forField: fieldNumber)
      return true
    }
    catch {
      return false
    }
  }

  /// Returns updated message.
  ///
  /// - Returns: Updated dynamic message.
  public func updatedMessage() -> DynamicMessage {
    return message
  }
}

// MARK: - Convenience Extensions

extension DynamicMessage {
  /// Creates FieldAccessor for reading fields of this message.
  ///
  /// - Returns: FieldAccessor for safe field reading.
  public var fieldAccessor: FieldAccessor {
    return FieldAccessor(self)
  }

  /// Creates MutableFieldAccessor for modifying fields of this message.
  ///
  /// - Returns: MutableFieldAccessor for safe field modification.
  public mutating func mutableFieldAccessor() -> MutableFieldAccessor {
    return MutableFieldAccessor(&self)
  }
}
