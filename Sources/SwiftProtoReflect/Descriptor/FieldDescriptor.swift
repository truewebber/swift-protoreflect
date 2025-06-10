//
// FieldDescriptor.swift
// SwiftProtoReflect
//
// Created: 2025-05-18
//

import Foundation
import SwiftProtobuf

/// FieldDescriptor.
///
/// Protocol Buffers field descriptor describing properties of a message field,
/// including its type, name, number, options and other metadata.
public struct FieldDescriptor: Equatable {
  // MARK: - Properties

  /// Field name (e.g., "first_name").
  public let name: String

  /// JSON field name (if different from name).
  public let jsonName: String

  /// Field number in the message.
  public let number: Int

  /// Field type (int32, string, message, etc.)
  public let type: FieldType

  /// Full name of message or enum type (for message and enum types).
  public let typeName: String?

  /// Indicates if the field is an array (repeated).
  public let isRepeated: Bool

  /// Indicates if the field is optional.
  public let isOptional: Bool

  /// Indicates if the field is required - deprecated for proto3.
  public let isRequired: Bool

  /// Indicates if the field is a map (map<key, value>).
  public let isMap: Bool

  /// Indicates if the field is part of a oneof group.
  public let oneofIndex: Int?

  /// Contains metadata for map type fields.
  public let mapEntryInfo: MapEntryInfo?

  /// Default value for the field (if defined).
  public let defaultValue: Any?

  /// Field options.
  public let options: [String: Any]

  // MARK: - Initialization

  /// Creates a new FieldDescriptor instance.
  ///
  /// - Parameters:
  ///   - name: Field name.
  ///   - number: Field number.
  ///   - type: Field type.
  ///   - typeName: Full type name (for message and enum).
  ///   - jsonName: JSON field name (defaults to name).
  ///   - isRepeated: Whether the field is an array.
  ///   - isOptional: Whether the field is optional.
  ///   - isRequired: Whether the field is required.
  ///   - isMap: Whether the field is a map.
  ///   - oneofIndex: Oneof group index if the field is part of a oneof.
  ///   - mapEntryInfo: Metadata for map fields.
  ///   - defaultValue: Default value.
  ///   - options: Field options.
  public init(
    name: String,
    number: Int,
    type: FieldType,
    typeName: String? = nil,
    jsonName: String? = nil,
    isRepeated: Bool = false,
    isOptional: Bool = false,
    isRequired: Bool = false,
    isMap: Bool = false,
    oneofIndex: Int? = nil,
    mapEntryInfo: MapEntryInfo? = nil,
    defaultValue: Any? = nil,
    options: [String: Any] = [:]
  ) {
    self.name = name
    self.number = number
    self.type = type
    self.typeName = typeName
    self.jsonName = jsonName ?? name
    // Map fields are automatically repeated fields in Protocol Buffers
    self.isRepeated = isMap ? true : isRepeated
    self.isOptional = isOptional
    self.isRequired = isRequired
    self.isMap = isMap
    self.oneofIndex = oneofIndex
    self.mapEntryInfo = mapEntryInfo
    self.defaultValue = defaultValue
    self.options = options

    // Validation: ensure typeName is specified for message and enum types
    if case .message = type, typeName == nil {
      fatalError("typeName must be specified for 'message' type fields")
    }
    if case .enum = type, typeName == nil {
      fatalError("typeName must be specified for 'enum' type fields")
    }

    // Validation: ensure mapEntryInfo is specified for map fields
    if isMap && mapEntryInfo == nil {
      fatalError("mapEntryInfo must be specified for 'map' type fields")
    }
  }

  // MARK: - Methods

  /// Returns the full type name for messages and enums.
  ///
  /// - Returns: Full type name or nil for scalar types.
  public func getFullTypeName() -> String? {
    return typeName
  }

  /// Checks if the field is a scalar type.
  ///
  /// - Returns: true if the field has a scalar type.
  public func isScalarType() -> Bool {
    switch type {
    case .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64,
      .bool, .string, .bytes:
      return true
    case .message, .enum, .group:
      return false
    }
  }

  /// Checks if the field is a numeric type.
  ///
  /// - Returns: true if the field has a numeric type.
  public func isNumericType() -> Bool {
    switch type {
    case .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64:
      return true
    case .bool, .string, .bytes, .message, .enum, .group:
      return false
    }
  }

  /// Gets key and value information for map fields.
  ///
  /// - Returns: Map field information or nil if the field is not a map.
  public func getMapKeyValueInfo() -> MapEntryInfo? {
    guard isMap else {
      return nil
    }

    return mapEntryInfo
  }

  // MARK: - Equatable

  public static func == (lhs: FieldDescriptor, rhs: FieldDescriptor) -> Bool {
    // Compare main properties
    guard
      lhs.name == rhs.name && lhs.jsonName == rhs.jsonName && lhs.number == rhs.number && lhs.type == rhs.type
        && lhs.typeName == rhs.typeName && lhs.isRepeated == rhs.isRepeated && lhs.isOptional == rhs.isOptional
        && lhs.isRequired == rhs.isRequired && lhs.isMap == rhs.isMap && lhs.oneofIndex == rhs.oneofIndex
        && lhs.mapEntryInfo == rhs.mapEntryInfo
    else {
      return false
    }

    // Compare options: check keys and values
    // May require individual comparison for each possible value type
    let lhsKeys = Set(lhs.options.keys)
    let rhsKeys = Set(rhs.options.keys)

    guard lhsKeys == rhsKeys else {
      return false
    }

    // Check value matching for all keys
    for key in lhsKeys {
      // Since options is of type [String: Any], we can only check string representation
      // or convert to known types where possible
      let lhsValue = lhs.options[key]
      let rhsValue = rhs.options[key]

      // Check known value types
      if let lhsBool = lhsValue as? Bool, let rhsBool = rhsValue as? Bool {
        if lhsBool != rhsBool {
          return false
        }
      }
      else if let lhsInt = lhsValue as? Int, let rhsInt = rhsValue as? Int {
        if lhsInt != rhsInt {
          return false
        }
      }
      else if let lhsString = lhsValue as? String, let rhsString = rhsValue as? String {
        if lhsString != rhsString {
          return false
        }
      }
      else {
        // For other types, compare string representations
        if String(describing: lhsValue) != String(describing: rhsValue) {
          return false
        }
      }
    }

    return true
  }
}

/// Protocol Buffers field type.
public enum FieldType: Equatable {
  case double
  case float
  case int32
  case int64
  case uint32
  case uint64
  case sint32
  case sint64
  case fixed32
  case fixed64
  case sfixed32
  case sfixed64
  case bool
  case string
  case bytes
  case message
  case `enum`
  case group  // Deprecated, for proto2 compatibility
}

/// Class describing metadata for map<key, value> type fields.
///
/// Uses reference-type to avoid circular references.
public final class MapEntryInfo: Equatable {
  /// Key field information.
  public let keyFieldInfo: KeyFieldInfo

  /// Value field information.
  public let valueFieldInfo: ValueFieldInfo

  /// Creates a new MapEntryInfo instance.
  ///
  /// - Parameters:
  ///   - keyFieldInfo: Key field information.
  ///   - valueFieldInfo: Value field information.
  public init(keyFieldInfo: KeyFieldInfo, valueFieldInfo: ValueFieldInfo) {
    // Validate key type (must be scalar except float, double, bytes)
    let validKeyTypes: [FieldType] = [
      .int32, .int64, .uint32, .uint64, .sint32, .sint64,
      .fixed32, .fixed64, .sfixed32, .sfixed64, .bool, .string,
    ]

    guard validKeyTypes.contains(keyFieldInfo.type) else {
      fatalError("Invalid key type for map: \(keyFieldInfo.type)")
    }

    self.keyFieldInfo = keyFieldInfo
    self.valueFieldInfo = valueFieldInfo
  }

  public static func == (lhs: MapEntryInfo, rhs: MapEntryInfo) -> Bool {
    return lhs.keyFieldInfo == rhs.keyFieldInfo && lhs.valueFieldInfo == rhs.valueFieldInfo
  }
}

/// Key field information in a map.
public struct KeyFieldInfo: Equatable {
  public let name: String
  public let number: Int
  public let type: FieldType

  public init(name: String, number: Int, type: FieldType) {
    self.name = name
    self.number = number
    self.type = type
  }
}

/// Value field information in a map.
public struct ValueFieldInfo: Equatable {
  public let name: String
  public let number: Int
  public let type: FieldType
  public let typeName: String?

  public init(name: String, number: Int, type: FieldType, typeName: String? = nil) {
    self.name = name
    self.number = number
    self.type = type
    self.typeName = typeName

    if case .message = type, typeName == nil {
      fatalError("typeName must be specified for 'message' type fields")
    }
    if case .enum = type, typeName == nil {
      fatalError("typeName must be specified for 'enum' type fields")
    }
  }
}
