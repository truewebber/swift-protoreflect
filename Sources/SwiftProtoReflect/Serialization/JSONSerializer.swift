//
// JSONSerializer.swift
// SwiftProtoReflect
//
// Created: 2025-05-25
//

import Foundation

/// JSONSerializer.
///
/// Provides functionality for serializing dynamic Protocol Buffers messages
/// to JSON format according to official Protocol Buffers JSON mapping specification.
/// Ensures full compatibility with protoc --json_out.
public struct JSONSerializer {

  // MARK: - Properties

  /// JSON serialization options.
  public let options: JSONSerializationOptions

  // MARK: - Initialization

  /// Creates new JSONSerializer instance.
  ///
  /// - Parameter options: JSON serialization options.
  public init(options: JSONSerializationOptions) {
    self.options = options
  }

  /// Creates a JSONSerializer with default options and an empty TypeRegistry.
  ///
  /// - Note: Deprecated. Use `init(options:)` with an explicit `TypeRegistry` so that
  ///   cross-file message types can be resolved correctly.
  @available(*, deprecated, message: "Use init(options:) with an explicit TypeRegistry")
  public init() {
    self.init(
      options: JSONSerializationOptions(
        useOriginalFieldNames: false,
        prettyPrinted: false,
        includeDefaultValues: false,
        typeRegistry: TypeRegistry()
      )
    )
  }

  // MARK: - Serialization Methods

  /// Serializes dynamic message to JSON format.
  ///
  /// - Parameter message: Dynamic message to serialize.
  /// - Returns: JSON string in Data format.
  /// - Throws: JSONSerializationError if serialization failed.
  public func serialize(_ message: DynamicMessage) throws -> Data {
    let jsonObject = try serializeToJSONObject(message)

    let options: JSONSerialization.WritingOptions = self.options.prettyPrinted ? .prettyPrinted : []

    do {
      return try JSONSerialization.data(withJSONObject: jsonObject, options: options)
    }
    catch {
      throw JSONSerializationError.jsonWriteError(underlyingError: error)
    }
  }

  /// Serializes dynamic message to JSON object.
  ///
  /// - Parameter message: Dynamic message to serialize.
  /// - Returns: JSON compatible object (Dictionary).
  /// - Throws: JSONSerializationError if serialization failed.
  public func serializeToJSONObject(_ message: DynamicMessage) throws -> [String: Any] {
    var result: [String: Any] = [:]

    let descriptor = message.descriptor
    let fieldAccess = FieldAccessor(message)

    var allFields = descriptor.allFields()
    allFields.append(contentsOf: descriptor.extensions.values)

    for field in allFields {
      let hasValue = fieldAccess.hasValue(field.number)
      let fieldName = options.useOriginalFieldNames ? field.name : field.jsonName

      if hasValue {
        result[fieldName] = try serializeFieldValue(field, from: fieldAccess, descriptor: descriptor)
      }
      else if options.includeDefaultValues {
        if field.proto3Optional { continue }
        if case .message = field.type, !field.isMap { continue }

        result[fieldName] = proto3DefaultJSON(for: field, in: descriptor)
      }
    }

    return result
  }

  /// Resolves an `EnumDescriptor` for a field.
  ///
  /// 1. `options.typeRegistry` by fully-qualified name (primary).
  /// 2. Structural nesting on `descriptor` (deprecated fallback).
  private func resolveEnumDescriptor(
    for field: FieldDescriptor,
    in descriptor: MessageDescriptor
  ) -> EnumDescriptor? {
    guard case .enum = field.type, let typeName = field.typeName else { return nil }
    let normalized = typeName.hasPrefix(".") ? String(typeName.dropFirst()) : typeName
    if let desc = options.typeRegistry.findEnum(named: normalized) {
      return desc
    }
    // DEPRECATED: Legacy structural nesting fallback. Will be removed in a future major version.
    // Users should register all types in TypeRegistry instead of relying on addNestedEnum().
    let simpleName = typeName.split(separator: ".").last.map(String.init) ?? typeName
    return descriptor.nestedEnum(named: simpleName)
  }

  /// Returns the proto3 JSON default for a field that has no value set.
  private func proto3DefaultJSON(for field: FieldDescriptor, in descriptor: MessageDescriptor) -> Any {
    if field.isMap {
      return [String: Any]()
    }
    if field.isRepeated {
      return [Any]()
    }
    switch field.type {
    case .double, .float: return 0
    case .int32, .sint32, .sfixed32, .uint32, .fixed32: return 0
    case .int64, .sint64, .sfixed64, .uint64, .fixed64: return "0"
    case .bool: return false
    case .string: return ""
    case .bytes: return ""
    case .enum:
      if let enumDesc = resolveEnumDescriptor(for: field, in: descriptor),
        let zeroVal = enumDesc.value(number: 0)
      {
        return zeroVal.name
      }
      return 0
    case .message, .group: return NSNull()
    }
  }

  // MARK: - Private Methods

  /// Serializes field value to JSON compatible object.
  private func serializeFieldValue(
    _ field: FieldDescriptor,
    from fieldAccess: FieldAccessor,
    descriptor: MessageDescriptor
  ) throws -> Any {
    if field.isMap {
      return try serializeMapField(field, from: fieldAccess, descriptor: descriptor)
    }
    else if field.isRepeated {
      return try serializeRepeatedField(field, from: fieldAccess, descriptor: descriptor)
    }
    else {
      return try serializeSingleField(field, from: fieldAccess, descriptor: descriptor)
    }
  }

  /// Serializes single field.
  private func serializeSingleField(
    _ field: FieldDescriptor,
    from fieldAccess: FieldAccessor,
    descriptor: MessageDescriptor
  ) throws -> Any {
    guard let value = fieldAccess.getValue(field.number, as: Any.self) else {
      throw JSONSerializationError.missingFieldValue(fieldName: field.name)
    }

    let enumDesc = resolveEnumDescriptor(for: field, in: descriptor)
    return try convertValueToJSON(value, type: field.type, typeName: field.typeName, enumDescriptor: enumDesc)
  }

  /// Serializes repeated field.
  private func serializeRepeatedField(
    _ field: FieldDescriptor,
    from fieldAccess: FieldAccessor,
    descriptor: MessageDescriptor
  ) throws -> Any {
    guard let values = fieldAccess.getValue(field.number, as: [Any].self) else {
      throw JSONSerializationError.invalidFieldType(
        fieldName: field.name,
        expectedType: "Array",
        actualType: String(describing: type(of: fieldAccess.getValue(field.number, as: Any.self)))
      )
    }

    let enumDesc = resolveEnumDescriptor(for: field, in: descriptor)
    var jsonArray: [Any] = []
    for value in values {
      let jsonValue = try convertValueToJSON(
        value,
        type: field.type,
        typeName: field.typeName,
        enumDescriptor: enumDesc
      )
      jsonArray.append(jsonValue)
    }

    return jsonArray
  }

  /// Serializes map field.
  private func serializeMapField(
    _ field: FieldDescriptor,
    from fieldAccess: FieldAccessor,
    descriptor: MessageDescriptor
  ) throws -> Any {
    guard let mapEntryInfo = field.mapEntryInfo else {
      throw JSONSerializationError.missingMapEntryInfo(fieldName: field.name)
    }

    guard let mapValues = fieldAccess.getValue(field.number, as: [AnyHashable: Any].self) else {
      throw JSONSerializationError.invalidFieldType(
        fieldName: field.name,
        expectedType: "Dictionary",
        actualType: String(describing: type(of: fieldAccess.getValue(field.number, as: Any.self)))
      )
    }

    var jsonObject: [String: Any] = [:]

    let enumDesc: EnumDescriptor? = {
      guard case .enum = mapEntryInfo.valueFieldInfo.type,
        let typeName = mapEntryInfo.valueFieldInfo.typeName
      else { return nil }
      let normalized = typeName.hasPrefix(".") ? String(typeName.dropFirst()) : typeName
      if let desc = options.typeRegistry.findEnum(named: normalized) {
        return desc
      }
      // DEPRECATED: Legacy structural nesting fallback. Will be removed in a future major version.
      // Users should register all types in TypeRegistry instead of relying on addNestedEnum().
      let simpleName = typeName.split(separator: ".").last.map(String.init) ?? typeName
      return descriptor.nestedEnum(named: simpleName)
    }()

    for (key, value) in mapValues {
      let jsonKey = try convertMapKeyToJSONString(key, keyType: mapEntryInfo.keyFieldInfo.type)
      let jsonValue = try convertValueToJSON(
        value,
        type: mapEntryInfo.valueFieldInfo.type,
        typeName: mapEntryInfo.valueFieldInfo.typeName,
        enumDescriptor: enumDesc
      )
      jsonObject[jsonKey] = jsonValue
    }

    return jsonObject
  }

  /// Converts value to JSON compatible type.
  internal func convertValueToJSON(
    _ value: Any,
    type: FieldType,
    typeName: String?,
    enumDescriptor: EnumDescriptor? = nil
  ) throws -> Any {
    switch type {
    case .double:
      guard let doubleValue = value as? Double else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "Double",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return convertDoubleToJSON(doubleValue)

    case .float:
      guard let floatValue = value as? Float else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "Float",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return convertFloatToJSON(floatValue)

    case .int32, .sint32, .sfixed32:
      guard let int32Value = value as? Int32 else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "Int32",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return Int(int32Value)

    case .int64, .sint64, .sfixed64:
      guard let int64Value = value as? Int64 else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "Int64",
          actual: String(describing: Swift.type(of: value))
        )
      }
      // int64 is represented as string in JSON
      return String(int64Value)

    case .uint32, .fixed32:
      guard let uint32Value = value as? UInt32 else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "UInt32",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return UInt(uint32Value)

    case .uint64, .fixed64:
      guard let uint64Value = value as? UInt64 else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "UInt64",
          actual: String(describing: Swift.type(of: value))
        )
      }
      // uint64 is represented as string in JSON
      return String(uint64Value)

    case .bool:
      guard let boolValue = value as? Bool else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "Bool",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return boolValue

    case .string:
      guard let stringValue = value as? String else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "String",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return stringValue

    case .bytes:
      guard let bytesValue = value as? Data else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "Data",
          actual: String(describing: Swift.type(of: value))
        )
      }
      // bytes are represented as base64 string
      return bytesValue.base64EncodedString()

    case .message:
      guard let messageValue = value as? DynamicMessage else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "DynamicMessage",
          actual: String(describing: Swift.type(of: value))
        )
      }
      // Recursively serialize nested message
      return try serializeToJSONObject(messageValue)

    case .enum:
      guard let enumValue = value as? Int32 else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "Int32",
          actual: String(describing: Swift.type(of: value))
        )
      }
      if let enumDesc = enumDescriptor,
        let enumVal = enumDesc.value(number: Int(enumValue))
      {
        return enumVal.name
      }
      return Int(enumValue)

    case .group:
      guard let groupMessage = value as? DynamicMessage else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "DynamicMessage (group)",
          actual: String(describing: Swift.type(of: value))
        )
      }
      return try serializeToJSONObject(groupMessage)
    }
  }

  /// Converts map key to JSON string.
  internal func convertMapKeyToJSONString(_ key: Any, keyType: FieldType) throws -> String {
    switch keyType {
    case .string:
      guard let stringKey = key as? String else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "String",
          actual: String(describing: Swift.type(of: key))
        )
      }
      return stringKey

    case .int32, .sint32, .sfixed32:
      guard let int32Key = key as? Int32 else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "Int32",
          actual: String(describing: Swift.type(of: key))
        )
      }
      return String(int32Key)

    case .int64, .sint64, .sfixed64:
      guard let int64Key = key as? Int64 else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "Int64",
          actual: String(describing: Swift.type(of: key))
        )
      }
      return String(int64Key)

    case .uint32, .fixed32:
      guard let uint32Key = key as? UInt32 else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "UInt32",
          actual: String(describing: Swift.type(of: key))
        )
      }
      return String(uint32Key)

    case .uint64, .fixed64:
      guard let uint64Key = key as? UInt64 else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "UInt64",
          actual: String(describing: Swift.type(of: key))
        )
      }
      return String(uint64Key)

    case .bool:
      guard let boolKey = key as? Bool else {
        throw JSONSerializationError.valueTypeMismatch(
          expected: "Bool",
          actual: String(describing: Swift.type(of: key))
        )
      }
      return boolKey ? "true" : "false"

    default:
      throw JSONSerializationError.invalidMapKeyType(keyType: String(describing: keyType))
    }
  }

  /// Converts double value with handling of special cases.
  private func convertDoubleToJSON(_ value: Double) -> Any {
    if value.isInfinite {
      return value > 0 ? "Infinity" : "-Infinity"
    }
    else if value.isNaN {
      return "NaN"
    }
    else {
      return value
    }
  }

  /// Converts float value with handling of special cases.
  private func convertFloatToJSON(_ value: Float) -> Any {
    if value.isInfinite {
      return value > 0 ? "Infinity" : "-Infinity"
    }
    else if value.isNaN {
      return "NaN"
    }
    else {
      return value
    }
  }
}

// MARK: - JSON Serialization Options

/// Options for JSON serialization.
public struct JSONSerializationOptions {
  /// Use original field names instead of camelCase.
  public let useOriginalFieldNames: Bool

  /// Format JSON with indentation for readability.
  public let prettyPrinted: Bool

  /// Include fields with default values.
  public let includeDefaultValues: Bool

  /// Registry for resolving message types by fully-qualified name.
  ///
  /// Pass a populated `TypeRegistry` to enable cross-file type resolution during serialization.
  /// For hand-built descriptors without cross-file references, an empty `TypeRegistry()` is sufficient.
  public let typeRegistry: TypeRegistry

  /// Creates JSON serialization options with a required TypeRegistry.
  ///
  /// - Parameters:
  ///   - useOriginalFieldNames: Whether to use original proto field names instead of camelCase. Defaults to `false`.
  ///   - prettyPrinted: Whether to format JSON with indentation. Defaults to `false`.
  ///   - includeDefaultValues: Whether to include fields with default values. Defaults to `false`.
  ///   - typeRegistry: Registry for resolving message types by fully-qualified name.
  public init(
    useOriginalFieldNames: Bool = false,
    prettyPrinted: Bool = false,
    includeDefaultValues: Bool = false,
    typeRegistry: TypeRegistry
  ) {
    self.useOriginalFieldNames = useOriginalFieldNames
    self.prettyPrinted = prettyPrinted
    self.includeDefaultValues = includeDefaultValues
    self.typeRegistry = typeRegistry
  }

  /// Creates JSON serialization options with an empty TypeRegistry.
  ///
  /// - Note: Deprecated. Use `init(useOriginalFieldNames:prettyPrinted:includeDefaultValues:typeRegistry:)`
  ///   with an explicit `TypeRegistry` so that cross-file message types can be resolved correctly.
  @available(
    *,
    deprecated,
    message:
      "Use init(useOriginalFieldNames:prettyPrinted:includeDefaultValues:typeRegistry:) with an explicit TypeRegistry"
  )
  public init(
    useOriginalFieldNames: Bool = false,
    prettyPrinted: Bool = false,
    includeDefaultValues: Bool = false
  ) {
    self.init(
      useOriginalFieldNames: useOriginalFieldNames,
      prettyPrinted: prettyPrinted,
      includeDefaultValues: includeDefaultValues,
      typeRegistry: TypeRegistry()
    )
  }
}

// MARK: - JSON Serialization Errors

/// JSON serialization errors.
public enum JSONSerializationError: Error, Equatable {
  case invalidFieldType(fieldName: String, expectedType: String, actualType: String)
  case valueTypeMismatch(expected: String, actual: String)
  case missingMapEntryInfo(fieldName: String)
  case missingFieldValue(fieldName: String)
  case unsupportedFieldType(type: String)
  case invalidMapKeyType(keyType: String)
  case jsonWriteError(underlyingError: Error)

  public var description: String {
    switch self {
    case .invalidFieldType(let fieldName, let expectedType, let actualType):
      return "Invalid field type for field '\(fieldName)': expected \(expectedType), got \(actualType)"
    case .valueTypeMismatch(let expected, let actual):
      return "Value type mismatch: expected \(expected), got \(actual)"
    case .missingMapEntryInfo(let fieldName):
      return "Missing map entry info for field '\(fieldName)'"
    case .missingFieldValue(let fieldName):
      return "Missing value for field '\(fieldName)'"
    case .unsupportedFieldType(let type):
      return "Unsupported field type: \(type)"
    case .invalidMapKeyType(let keyType):
      return "Invalid map key type: \(keyType)"
    case .jsonWriteError(let underlyingError):
      return "JSON write error: \(underlyingError.localizedDescription)"
    }
  }

  public static func == (lhs: JSONSerializationError, rhs: JSONSerializationError) -> Bool {
    switch (lhs, rhs) {
    case (
      .invalidFieldType(let lField, let lExpected, let lActual),
      .invalidFieldType(let rField, let rExpected, let rActual)
    ):
      return lField == rField && lExpected == rExpected && lActual == rActual
    case (
      .valueTypeMismatch(let lExpected, let lActual),
      .valueTypeMismatch(let rExpected, let rActual)
    ):
      return lExpected == rExpected && lActual == rActual
    case (.missingMapEntryInfo(let lField), .missingMapEntryInfo(let rField)):
      return lField == rField
    case (.missingFieldValue(let lField), .missingFieldValue(let rField)):
      return lField == rField
    case (.unsupportedFieldType(let lType), .unsupportedFieldType(let rType)):
      return lType == rType
    case (.invalidMapKeyType(let lType), .invalidMapKeyType(let rType)):
      return lType == rType
    case (.jsonWriteError(_), .jsonWriteError(_)):
      // Hard to compare underlying errors, so consider equal if both are jsonWriteError
      return true
    default:
      return false
    }
  }
}
