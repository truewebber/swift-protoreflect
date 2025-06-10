//
// DynamicMessage.swift
// SwiftProtoReflect
//
// Created: 2025-05-23
//

import Foundation
import SwiftProtobuf

/// DynamicMessage.
///
/// Dynamic representation of a Protocol Buffers message,
/// which allows creating and manipulating messages
/// at runtime without prior code generation.
public struct DynamicMessage: Equatable {
  // MARK: - Properties

  /// Message descriptor defining its structure.
  public let descriptor: MessageDescriptor

  /// Storage for field values.
  private var values: [Int: Any] = [:]

  /// Storage for nested messages.
  private var nestedMessages: [Int: DynamicMessage] = [:]

  /// Storage for repeated fields.
  private var repeatedValues: [Int: [Any]] = [:]

  /// Storage for map fields.
  private var mapValues: [Int: [AnyHashable: Any]] = [:]

  /// Information about which oneOf is active (if any).
  private var activeOneofFields: [Int: Int] = [:]

  // MARK: - Initialization

  /// Creates a new DynamicMessage instance.
  ///
  /// - Parameter descriptor: Message descriptor.
  public init(descriptor: MessageDescriptor) {
    self.descriptor = descriptor
  }

  // MARK: - Field Access Methods

  /// Sets field value by name.
  ///
  /// - Parameters:
  ///   - value: Value to set.
  ///   - fieldName: Field name.
  /// - Returns: Updated message.
  /// - Throws: Error if field doesn't exist or types are incompatible.
  @discardableResult
  public mutating func set(_ value: Any, forField fieldName: String) throws -> Self {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }

    return try set(value, forField: field.number)
  }

  /// Sets field value by number.
  ///
  /// - Parameters:
  ///   - value: Value to set.
  ///   - fieldNumber: Field number.
  /// - Returns: Updated message.
  /// - Throws: Error if field doesn't exist or types are incompatible.
  @discardableResult
  public mutating func set(_ value: Any, forField fieldNumber: Int) throws -> Self {
    guard let field = descriptor.field(number: fieldNumber) else {
      throw DynamicMessageError.fieldNotFoundByNumber(fieldNumber: fieldNumber)
    }

    // Handle oneof fields
    if let oneofIndex = field.oneofIndex {
      if let currentField = activeOneofFields[oneofIndex], currentField != fieldNumber {
        // Clear previous value in this oneof group
        clearOneofField(currentField)
      }
      activeOneofFields[oneofIndex] = fieldNumber
    }

    // Handle different field types
    if field.isRepeated {
      // Repeated fields
      if field.isMap {
        // Map fields (special case of repeated)
        guard let mapValue = value as? [AnyHashable: Any] else {
          throw DynamicMessageError.typeMismatch(
            fieldName: field.name,
            expectedType: "Map<Key, Value>",
            actualValue: value
          )
        }

        try validateMapValues(mapValue, for: field)

        // Convert keys and values in map if needed
        var convertedMap: [AnyHashable: Any] = [:]
        for (key, val) in mapValue {
          let convertedKey = convertMapKey(key, for: field.mapEntryInfo!.keyFieldInfo)
          let convertedValue = convertMapValue(val, for: field.mapEntryInfo!.valueFieldInfo)
          convertedMap[convertedKey] = convertedValue
        }

        mapValues[fieldNumber] = convertedMap
      }
      else {
        // Regular repeated fields
        guard let arrayValue = value as? [Any] else {
          throw DynamicMessageError.typeMismatch(
            fieldName: field.name,
            expectedType: "Array<\(field.type)>",
            actualValue: value
          )
        }

        // Validate and convert all array elements
        var convertedArray: [Any] = []
        for (index, item) in arrayValue.enumerated() {
          try validateValue(item, for: field, itemIndex: index)
          convertedArray.append(convertToCorrectType(item, for: field))
        }

        repeatedValues[fieldNumber] = convertedArray
      }
    }
    else {
      // Regular (non-repeated) fields
      try validateValue(value, for: field)

      if case .message = field.type {
        if let dynamicMessage = value as? DynamicMessage {
          // Store nested dynamic message
          nestedMessages[fieldNumber] = dynamicMessage
        }
        else {
          throw DynamicMessageError.typeMismatch(
            fieldName: field.name,
            expectedType: "DynamicMessage",
            actualValue: value
          )
        }
      }
      else {
        // Convert and store regular value
        let convertedValue = convertToCorrectType(value, for: field)
        values[fieldNumber] = convertedValue
      }
    }

    return self
  }

  /// Gets field value by name.
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: Field value or nil if value is not set.
  /// - Throws: Error if field doesn't exist.
  public func get(forField fieldName: String) throws -> Any? {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }

    return try get(forField: field.number)
  }

  /// Gets field value by number.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: Field value or nil if value is not set.
  /// - Throws: Error if field doesn't exist.
  public func get(forField fieldNumber: Int) throws -> Any? {
    guard let field = descriptor.field(number: fieldNumber) else {
      throw DynamicMessageError.fieldNotFoundByNumber(fieldNumber: fieldNumber)
    }

    // Determine where to get value based on field type
    if field.isRepeated {
      if field.isMap {
        return mapValues[fieldNumber]
      }
      else {
        return repeatedValues[fieldNumber]
      }
    }
    else if case .message = field.type {
      return nestedMessages[fieldNumber]
    }
    else {
      return values[fieldNumber] ?? field.defaultValue
    }
  }

  /// Checks if a value was set for the field.
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: true if value is set.
  /// - Throws: Error if field doesn't exist.
  public func hasValue(forField fieldName: String) throws -> Bool {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }

    return try hasValue(forField: field.number)
  }

  /// Checks if a value was set for the field.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: true if value is set.
  /// - Throws: Error if field doesn't exist.
  public func hasValue(forField fieldNumber: Int) throws -> Bool {
    guard let field = descriptor.field(number: fieldNumber) else {
      throw DynamicMessageError.fieldNotFoundByNumber(fieldNumber: fieldNumber)
    }

    if field.isRepeated {
      if field.isMap {
        return mapValues[fieldNumber] != nil
      }
      else {
        return repeatedValues[fieldNumber] != nil
      }
    }
    else if case .message = field.type {
      return nestedMessages[fieldNumber] != nil
    }
    else {
      return values[fieldNumber] != nil
    }
  }

  /// Clears field value.
  ///
  /// - Parameter fieldName: Field name.
  /// - Returns: Updated message.
  /// - Throws: Error if field doesn't exist.
  @discardableResult
  public mutating func clearField(_ fieldName: String) throws -> Self {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }

    return try clearField(field.number)
  }

  /// Clears field value.
  ///
  /// - Parameter fieldNumber: Field number.
  /// - Returns: Updated message.
  /// - Throws: Error if field doesn't exist.
  @discardableResult
  public mutating func clearField(_ fieldNumber: Int) throws -> Self {
    guard let field = descriptor.field(number: fieldNumber) else {
      throw DynamicMessageError.fieldNotFoundByNumber(fieldNumber: fieldNumber)
    }

    if field.isRepeated {
      if field.isMap {
        mapValues.removeValue(forKey: fieldNumber)
      }
      else {
        repeatedValues.removeValue(forKey: fieldNumber)
      }
    }
    else if case .message = field.type {
      nestedMessages.removeValue(forKey: fieldNumber)
    }
    else {
      values.removeValue(forKey: fieldNumber)
    }

    // Update oneof fields state
    if let oneofIndex = field.oneofIndex, activeOneofFields[oneofIndex] == fieldNumber {
      activeOneofFields.removeValue(forKey: oneofIndex)
    }

    return self
  }

  // MARK: - Repeated Field Methods

  /// Adds element to repeated field.
  ///
  /// - Parameters:
  ///   - value: Value to add.
  ///   - fieldName: Field name.
  /// - Returns: Updated message.
  /// - Throws: Error if field doesn't exist, is not repeated, or type doesn't match.
  @discardableResult
  public mutating func addRepeatedValue(_ value: Any, forField fieldName: String) throws -> Self {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }

    return try addRepeatedValue(value, forField: field.number)
  }

  /// Adds element to repeated field.
  ///
  /// - Parameters:
  ///   - value: Value to add.
  ///   - fieldNumber: Field number.
  /// - Returns: Updated message.
  /// - Throws: Error if field doesn't exist, is not repeated, or type doesn't match.
  @discardableResult
  public mutating func addRepeatedValue(_ value: Any, forField fieldNumber: Int) throws -> Self {
    guard let field = descriptor.field(number: fieldNumber) else {
      throw DynamicMessageError.fieldNotFoundByNumber(fieldNumber: fieldNumber)
    }

    guard field.isRepeated && !field.isMap else {
      throw DynamicMessageError.notRepeatedField(fieldName: field.name)
    }

    // Check value type
    try validateValue(value, for: field)

    // Convert value if needed
    let convertedValue = convertToCorrectType(value, for: field)

    // Add to array
    var currentValues = repeatedValues[fieldNumber] ?? []
    currentValues.append(convertedValue)
    repeatedValues[fieldNumber] = currentValues

    return self
  }

  // MARK: - Map Field Methods

  /// Sets entry in map field.
  ///
  /// - Parameters:
  ///   - value: Value to set.
  ///   - key: Key.
  ///   - fieldName: Field name.
  /// - Returns: Updated message.
  /// - Throws: Error if field doesn't exist, is not map, or types don't match.
  @discardableResult
  public mutating func setMapEntry(_ value: Any, forKey key: AnyHashable, inField fieldName: String) throws -> Self {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }

    return try setMapEntry(value, forKey: key, inField: field.number)
  }

  /// Sets entry in map field.
  ///
  /// - Parameters:
  ///   - value: Value to set.
  ///   - key: Key.
  ///   - fieldNumber: Field number.
  /// - Returns: Updated message.
  /// - Throws: Error if field doesn't exist, is not map, or types don't match.
  @discardableResult
  public mutating func setMapEntry(_ value: Any, forKey key: AnyHashable, inField fieldNumber: Int) throws -> Self {
    guard let field = descriptor.field(number: fieldNumber) else {
      throw DynamicMessageError.fieldNotFoundByNumber(fieldNumber: fieldNumber)
    }

    guard field.isMap, let mapInfo = field.mapEntryInfo else {
      throw DynamicMessageError.notMapField(fieldName: field.name)
    }

    // Check key type
    try validateMapKey(key, for: mapInfo.keyFieldInfo)

    // Check value type
    try validateMapValue(value, for: mapInfo.valueFieldInfo)

    // Convert key and value to correct types
    let convertedKey = convertMapKey(key, for: mapInfo.keyFieldInfo)
    let convertedValue = convertMapValue(value, for: mapInfo.valueFieldInfo)

    // Add to map
    var currentMap = mapValues[fieldNumber] ?? [:]
    currentMap[convertedKey] = convertedValue
    mapValues[fieldNumber] = currentMap

    return self
  }

  // MARK: - Private Helper Methods

  /// Clears oneof field value by its number.
  ///
  /// Used for proper clearing of all field types when switching oneof.
  ///
  /// - Parameter fieldNumber: Field number to clear.
  private mutating func clearOneofField(_ fieldNumber: Int) {
    guard let field = descriptor.field(number: fieldNumber) else {
      return  // Field not found, do nothing
    }

    // Clear value from appropriate storage based on field type
    if field.isRepeated {
      if field.isMap {
        mapValues.removeValue(forKey: fieldNumber)
      }
      else {
        repeatedValues.removeValue(forKey: fieldNumber)
      }
    }
    else if case .message = field.type {
      nestedMessages.removeValue(forKey: fieldNumber)
    }
    else {
      values.removeValue(forKey: fieldNumber)
    }
  }

  // MARK: - Validation Methods

  /// Checks if value matches the required field type.
  ///
  /// - Parameters:
  ///   - value: Value to check.
  ///   - field: Field descriptor.
  ///   - itemIndex: Element index in array (for repeated fields).
  /// - Throws: Error if type doesn't match.
  private func validateValue(_ value: Any, for field: FieldDescriptor, itemIndex: Int? = nil) throws {
    let indexSuffix = itemIndex != nil ? " at index \(itemIndex!)" : ""
    let fieldDesc = "\(field.name)\(indexSuffix)"

    switch field.type {
    case .double:
      guard value is Double || value is NSNumber else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "Double",
          actualValue: value
        )
      }
    case .float:
      guard value is Float || value is NSNumber else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "Float",
          actualValue: value
        )
      }
    case .int32, .sint32, .sfixed32:
      guard value is Int32 || (value is Int && (value as! Int) >= Int32.min && (value as! Int) <= Int32.max) else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "Int32",
          actualValue: value
        )
      }
    case .int64, .sint64, .sfixed64:
      guard value is Int64 || value is Int else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "Int64",
          actualValue: value
        )
      }
    case .uint32, .fixed32:
      guard value is UInt32 || (value is UInt && (value as! UInt) <= UInt32.max) else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "UInt32",
          actualValue: value
        )
      }
    case .uint64, .fixed64:
      guard value is UInt64 || value is UInt else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "UInt64",
          actualValue: value
        )
      }
    case .bool:
      guard value is Bool else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "Bool",
          actualValue: value
        )
      }
    case .string:
      guard value is String else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "String",
          actualValue: value
        )
      }
    case .bytes:
      guard value is Data else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "Data",
          actualValue: value
        )
      }
    case .message:
      guard value is DynamicMessage else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "DynamicMessage",
          actualValue: value
        )
      }

      // Check if message type matches expected
      let message = value as! DynamicMessage
      let expectedTypeName = field.typeName ?? ""
      let actualTypeName = message.descriptor.fullName

      guard expectedTypeName == actualTypeName else {
        throw DynamicMessageError.messageMismatch(
          fieldName: fieldDesc,
          expectedType: expectedTypeName,
          actualType: actualTypeName
        )
      }
    case .enum:
      // For enums we expect either Int32 (number) or String (name)
      guard value is Int32 || value is String else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "Enum (Int32 or String)",
          actualValue: value
        )
      }

    // TODO: Full enum value validation when type registry is available
    case .group:
      // Group - deprecated type, support for proto2 compatibility
      guard value is DynamicMessage else {
        throw DynamicMessageError.typeMismatch(
          fieldName: fieldDesc,
          expectedType: "DynamicMessage (group)",
          actualValue: value
        )
      }
    }
  }

  /// Validates map values correctness.
  ///
  /// - Parameters:
  ///   - mapValue: Map to check.
  ///   - field: Field descriptor.
  /// - Throws: Error if key or value type doesn't match.
  private func validateMapValues(_ mapValue: [AnyHashable: Any], for field: FieldDescriptor) throws {
    guard let mapInfo = field.mapEntryInfo else {
      throw DynamicMessageError.notMapField(fieldName: field.name)
    }

    // Check all keys and values
    for (key, value) in mapValue {
      try validateMapKey(key, for: mapInfo.keyFieldInfo)
      try validateMapValue(value, for: mapInfo.valueFieldInfo)
    }
  }

  /// Validates map key correctness.
  ///
  /// - Parameters:
  ///   - key: Key to check.
  ///   - keyFieldInfo: Key field information.
  /// - Throws: Error if key type doesn't match.
  private func validateMapKey(_ key: AnyHashable, for keyFieldInfo: KeyFieldInfo) throws {
    switch keyFieldInfo.type {
    case .int32, .sint32, .sfixed32:
      guard key is Int32 || (key is Int && (key as! Int) >= Int32.min && (key as! Int) <= Int32.max) else {
        throw DynamicMessageError.typeMismatch(
          fieldName: "map key",
          expectedType: "Int32",
          actualValue: key
        )
      }
    case .int64, .sint64, .sfixed64:
      guard key is Int64 || key is Int else {
        throw DynamicMessageError.typeMismatch(
          fieldName: "map key",
          expectedType: "Int64",
          actualValue: key
        )
      }
    case .uint32, .fixed32:
      guard key is UInt32 || (key is UInt && (key as! UInt) <= UInt32.max) else {
        throw DynamicMessageError.typeMismatch(
          fieldName: "map key",
          expectedType: "UInt32",
          actualValue: key
        )
      }
    case .uint64, .fixed64:
      guard key is UInt64 || key is UInt else {
        throw DynamicMessageError.typeMismatch(
          fieldName: "map key",
          expectedType: "UInt64",
          actualValue: key
        )
      }
    case .bool:
      guard key is Bool else {
        throw DynamicMessageError.typeMismatch(
          fieldName: "map key",
          expectedType: "Bool",
          actualValue: key
        )
      }
    case .string:
      guard key is String else {
        throw DynamicMessageError.typeMismatch(
          fieldName: "map key",
          expectedType: "String",
          actualValue: key
        )
      }
    default:
      // Other types are not allowed for map keys
      throw DynamicMessageError.invalidMapKeyType(type: keyFieldInfo.type)
    }
  }

  /// Validates map value correctness.
  ///
  /// - Parameters:
  ///   - value: Value to check.
  ///   - valueFieldInfo: Value field information.
  /// - Throws: Error if value type doesn't match.
  private func validateMapValue(_ value: Any, for valueFieldInfo: ValueFieldInfo) throws {
    // Create temporary field descriptor to reuse validation
    let tempField = FieldDescriptor(
      name: "value",
      number: valueFieldInfo.number,
      type: valueFieldInfo.type,
      typeName: valueFieldInfo.typeName
    )

    try validateValue(value, for: tempField)
  }

  /// Converts value to correct type for storage if needed.
  ///
  /// - Parameters:
  ///   - value: Source value.
  ///   - field: Field descriptor.
  /// - Returns: Converted value suitable for storage.
  private func convertToCorrectType(_ value: Any, for field: FieldDescriptor) -> Any {
    switch field.type {
    case .int32, .sint32, .sfixed32:
      if let intValue = value as? Int {
        return Int32(intValue)
      }
    case .int64, .sint64, .sfixed64:
      if let intValue = value as? Int {
        return Int64(intValue)
      }
    case .uint32, .fixed32:
      if let uintValue = value as? UInt {
        return UInt32(uintValue)
      }
    case .uint64, .fixed64:
      if let uintValue = value as? UInt {
        return UInt64(uintValue)
      }
    case .float:
      if let number = value as? NSNumber, !(value is Float) {
        return number.floatValue
      }
    case .double:
      if let number = value as? NSNumber, !(value is Double) {
        return number.doubleValue
      }
    default:
      break
    }
    return value
  }

  /// Converts map key to correct type.
  private func convertMapKey(_ key: AnyHashable, for keyFieldInfo: KeyFieldInfo) -> AnyHashable {
    switch keyFieldInfo.type {
    case .int32, .sint32, .sfixed32:
      if let intValue = key as? Int {
        return Int32(intValue) as AnyHashable
      }
    case .int64, .sint64, .sfixed64:
      if let intValue = key as? Int {
        return Int64(intValue) as AnyHashable
      }
    case .uint32, .fixed32:
      if let uintValue = key as? UInt {
        return UInt32(uintValue) as AnyHashable
      }
    case .uint64, .fixed64:
      if let uintValue = key as? UInt {
        return UInt64(uintValue) as AnyHashable
      }
    default:
      break
    }
    return key
  }

  /// Converts map value to correct type.
  private func convertMapValue(_ value: Any, for valueFieldInfo: ValueFieldInfo) -> Any {
    // Create temporary field descriptor to reuse validation
    let tempField = FieldDescriptor(
      name: "value",
      number: valueFieldInfo.number,
      type: valueFieldInfo.type,
      typeName: valueFieldInfo.typeName
    )

    return convertToCorrectType(value, for: tempField)
  }

  // MARK: - Equatable

  public static func == (lhs: DynamicMessage, rhs: DynamicMessage) -> Bool {
    // Compare by descriptor and field values
    guard lhs.descriptor.fullName == rhs.descriptor.fullName else {
      return false
    }

    // Get all descriptor fields
    let allFields = lhs.descriptor.allFields()

    for field in allFields {
      let fieldNumber = field.number

      do {
        let lhsHasValue = try lhs.hasValue(forField: fieldNumber)
        let rhsHasValue = try rhs.hasValue(forField: fieldNumber)

        // If value presence differs, messages are not equal
        if lhsHasValue != rhsHasValue {
          return false
        }

        // If both don't have value, proceed to next field
        if !lhsHasValue && !rhsHasValue {
          continue
        }

        // Get values
        let lhsValue = try lhs.get(forField: fieldNumber)
        let rhsValue = try rhs.get(forField: fieldNumber)

        // Compare values based on field type
        if field.isRepeated {
          if field.isMap {
            // Compare map
            let lhsMap = lhsValue as? [AnyHashable: Any]
            let rhsMap = rhsValue as? [AnyHashable: Any]

            guard let lm = lhsMap, let rm = rhsMap, lm.count == rm.count else {
              return false
            }

            // Compare keys
            let lhsKeys = Set(lm.keys.map { String(describing: $0) })
            let rhsKeys = Set(rm.keys.map { String(describing: $0) })

            if lhsKeys != rhsKeys {
              return false
            }

            // Compare values for each key
            for (key, lhsMapValue) in lm {
              guard let rhsMapValue = rm[key] else {
                return false
              }

              if !areValuesEqual(lhsMapValue, rhsMapValue, fieldType: field.mapEntryInfo?.valueFieldInfo.type) {
                return false
              }
            }
          }
          else {
            // Compare repeated
            let lhsArray = lhsValue as? [Any]
            let rhsArray = rhsValue as? [Any]

            guard let la = lhsArray, let ra = rhsArray, la.count == ra.count else {
              return false
            }

            // Compare each element
            for i in 0..<la.count where !areValuesEqual(la[i], ra[i], fieldType: field.type) {
              return false
            }
          }
        }
        else {
          // Compare regular fields
          if !areValuesEqual(lhsValue!, rhsValue!, fieldType: field.type) {
            return false
          }
        }
      }
      catch {
        // On field access error consider messages not equal
        return false
      }
    }

    return true
  }

  /// Compares two values for equality considering field type.
  ///
  /// - Parameters:
  ///   - lhs: First value.
  ///   - rhs: Second value.
  ///   - fieldType: Field type.
  /// - Returns: true if values are equal.
  private static func areValuesEqual(_ lhs: Any, _ rhs: Any, fieldType: FieldType?) -> Bool {
    switch fieldType {
    case .double:
      return (lhs as? Double) == (rhs as? Double)
    case .float:
      return (lhs as? Float) == (rhs as? Float)
    case .int32, .sint32, .sfixed32:
      return (lhs as? Int32) == (rhs as? Int32)
    case .int64, .sint64, .sfixed64:
      return (lhs as? Int64) == (rhs as? Int64)
    case .uint32, .fixed32:
      return (lhs as? UInt32) == (rhs as? UInt32)
    case .uint64, .fixed64:
      return (lhs as? UInt64) == (rhs as? UInt64)
    case .bool:
      return (lhs as? Bool) == (rhs as? Bool)
    case .string:
      return (lhs as? String) == (rhs as? String)
    case .bytes:
      return (lhs as? Data) == (rhs as? Data)
    case .enum:
      // For enums compare either numbers or strings
      if let lhsInt = lhs as? Int32, let rhsInt = rhs as? Int32 {
        return lhsInt == rhsInt
      }
      else if let lhsStr = lhs as? String, let rhsStr = rhs as? String {
        return lhsStr == rhsStr
      }
      else {
        return false
      }
    case .message, .group:
      // For messages compare using built-in Equatable
      return (lhs as? DynamicMessage) == (rhs as? DynamicMessage)
    default:
      // For other types use general description
      return String(describing: lhs) == String(describing: rhs)
    }
  }
}

/// Errors that occur when working with dynamic messages.
public enum DynamicMessageError: Error, LocalizedError {
  case fieldNotFound(fieldName: String)
  case fieldNotFoundByNumber(fieldNumber: Int)
  case typeMismatch(fieldName: String, expectedType: String, actualValue: Any)
  case messageMismatch(fieldName: String, expectedType: String, actualType: String)
  case notRepeatedField(fieldName: String)
  case notMapField(fieldName: String)
  case invalidMapKeyType(type: FieldType)

  public var errorDescription: String? {
    switch self {
    case .fieldNotFound(let fieldName):
      return "Field with name '\(fieldName)' not found"
    case .fieldNotFoundByNumber(let fieldNumber):
      return "Field with number \(fieldNumber) not found"
    case .typeMismatch(let fieldName, let expectedType, let actualValue):
      return "Type mismatch for field '\(fieldName)': expected \(expectedType), got \(type(of: actualValue))"
    case .messageMismatch(let fieldName, let expectedType, let actualType):
      return "Message type mismatch for field '\(fieldName)': expected \(expectedType), got \(actualType)"
    case .notRepeatedField(let fieldName):
      return "Field '\(fieldName)' is not a repeated field"
    case .notMapField(let fieldName):
      return "Field '\(fieldName)' is not a map field"
    case .invalidMapKeyType(let type):
      return "Invalid key type \(type) for map field"
    }
  }
}
