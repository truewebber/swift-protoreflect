//
// JSONDeserializer.swift
// SwiftProtoReflect
//
// Created: 2025-05-25
//

import Foundation

/// JSONDeserializer.
///
/// Provides functionality for deserializing JSON data to dynamic Protocol Buffers messages
/// according to official Protocol Buffers JSON mapping specification.
/// Ensures full compatibility with JSONSerializer for round-trip operations.
public struct JSONDeserializer {

  // MARK: - Properties

  /// JSON deserialization options.
  public let options: JSONDeserializationOptions

  // MARK: - Initialization

  /// Creates new JSONDeserializer instance.
  ///
  /// - Parameter options: JSON deserialization options.
  public init(options: JSONDeserializationOptions = JSONDeserializationOptions()) {
    self.options = options
  }

  // MARK: - Deserialization Methods

  /// Deserializes JSON data to dynamic message.
  ///
  /// - Parameters:
  ///   - data: JSON data to deserialize.
  ///   - descriptor: Message descriptor to determine structure.
  /// - Returns: Deserialized dynamic message.
  /// - Throws: JSONDeserializationError if deserialization failed.
  public func deserialize(_ data: Data, using descriptor: MessageDescriptor) throws -> DynamicMessage {
    // Parse JSON to object
    let jsonObject: Any
    do {
      jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
    }
    catch {
      throw JSONDeserializationError.invalidJSON(underlyingError: error)
    }

    // JSON object should be dictionary for message
    guard let jsonDictionary = jsonObject as? [String: Any] else {
      throw JSONDeserializationError.invalidJSONStructure(
        expected: "Object",
        actual: String(describing: type(of: jsonObject))
      )
    }

    return try deserializeFromJSONObject(jsonDictionary, using: descriptor)
  }

  /// Deserializes JSON object to dynamic message.
  ///
  /// - Parameters:
  ///   - jsonObject: JSON object (Dictionary) to deserialize.
  ///   - descriptor: Message descriptor to determine structure.
  /// - Returns: Deserialized dynamic message.
  /// - Throws: JSONDeserializationError if deserialization failed.
  public func deserializeFromJSONObject(_ jsonObject: [String: Any], using descriptor: MessageDescriptor) throws
    -> DynamicMessage
  {
    let factory = MessageFactory()
    var message = factory.createMessage(from: descriptor)

    // Process each field from JSON
    for (jsonFieldName, jsonValue) in jsonObject {
      // Find field by name (support both original and camelCase names)
      guard let field = findField(byJSONName: jsonFieldName, in: descriptor) else {
        if options.ignoreUnknownFields {
          continue  // Skip unknown fields
        }
        else {
          throw JSONDeserializationError.unknownField(fieldName: jsonFieldName, messageName: descriptor.name)
        }
      }

      // Deserialize field value
      let fieldValue = try deserializeFieldValue(jsonValue, for: field)
      try message.set(fieldValue, forField: field.name)
    }

    return message
  }

  // MARK: - Private Methods

  /// Finds field by JSON name (supports original names and camelCase).
  private func findField(byJSONName jsonName: String, in descriptor: MessageDescriptor) -> FieldDescriptor? {
    for field in descriptor.allFields() {
      // Check original name
      if field.name == jsonName {
        return field
      }
      // Check JSON name (camelCase)
      if field.jsonName == jsonName {
        return field
      }
    }
    return nil
  }

  /// Deserializes field value from JSON.
  private func deserializeFieldValue(_ jsonValue: Any, for field: FieldDescriptor) throws -> Any {
    if field.isMap {
      return try deserializeMapField(jsonValue, for: field)
    }
    else if field.isRepeated {
      return try deserializeRepeatedField(jsonValue, for: field)
    }
    else {
      return try deserializeSingleField(jsonValue, for: field)
    }
  }

  /// Deserializes single field.
  private func deserializeSingleField(_ jsonValue: Any, for field: FieldDescriptor) throws -> Any {
    return try convertJSONValueToFieldType(jsonValue, type: field.type, typeName: field.typeName, fieldName: field.name)
  }

  /// Deserializes repeated field.
  private func deserializeRepeatedField(_ jsonValue: Any, for field: FieldDescriptor) throws -> Any {
    guard let jsonArray = jsonValue as? [Any] else {
      throw JSONDeserializationError.invalidFieldType(
        fieldName: field.name,
        expectedType: "Array",
        actualType: String(describing: type(of: jsonValue))
      )
    }

    var resultArray: [Any] = []

    for (index, arrayElement) in jsonArray.enumerated() {
      do {
        let convertedValue = try convertJSONValueToFieldType(
          arrayElement,
          type: field.type,
          typeName: field.typeName,
          fieldName: "\(field.name)[\(index)]"
        )
        resultArray.append(convertedValue)
      }
      catch {
        throw JSONDeserializationError.invalidArrayElement(
          fieldName: field.name,
          index: index,
          underlyingError: error
        )
      }
    }

    return resultArray
  }

  /// Deserializes map field.
  private func deserializeMapField(_ jsonValue: Any, for field: FieldDescriptor) throws -> Any {
    guard let jsonObject = jsonValue as? [String: Any] else {
      throw JSONDeserializationError.invalidFieldType(
        fieldName: field.name,
        expectedType: "Object",
        actualType: String(describing: type(of: jsonValue))
      )
    }

    guard let mapEntryInfo = field.mapEntryInfo else {
      throw JSONDeserializationError.missingMapEntryInfo(fieldName: field.name)
    }

    var resultMap: [AnyHashable: Any] = [:]

    for (jsonKey, jsonMapValue) in jsonObject {
      // Convert JSON key (always string) back to needed type
      let mapKey = try convertJSONStringToMapKey(
        jsonKey,
        keyType: mapEntryInfo.keyFieldInfo.type,
        fieldName: field.name
      )

      // Convert value
      let mapValue = try convertJSONValueToFieldType(
        jsonMapValue,
        type: mapEntryInfo.valueFieldInfo.type,
        typeName: mapEntryInfo.valueFieldInfo.typeName,
        fieldName: "\(field.name)[\(jsonKey)]"
      )

      guard let hashableKey = mapKey as? AnyHashable else {
        throw JSONDeserializationError.invalidMapKey(
          fieldName: field.name,
          key: String(describing: mapKey)
        )
      }

      resultMap[hashableKey] = mapValue
    }

    return resultMap
  }

  /// Converts JSON value to corresponding field type.
  private func convertJSONValueToFieldType(
    _ jsonValue: Any,
    type: FieldType,
    typeName: String?,
    fieldName: String
  ) throws -> Any {

    switch type {
    case .double:
      return try convertJSONToDouble(jsonValue, fieldName: fieldName)

    case .float:
      return try convertJSONToFloat(jsonValue, fieldName: fieldName)

    case .int32, .sint32, .sfixed32:
      return try convertJSONToInt32(jsonValue, fieldName: fieldName)

    case .int64, .sint64, .sfixed64:
      return try convertJSONToInt64(jsonValue, fieldName: fieldName)

    case .uint32, .fixed32:
      return try convertJSONToUInt32(jsonValue, fieldName: fieldName)

    case .uint64, .fixed64:
      return try convertJSONToUInt64(jsonValue, fieldName: fieldName)

    case .bool:
      return try convertJSONToBool(jsonValue, fieldName: fieldName)

    case .string:
      return try convertJSONToString(jsonValue, fieldName: fieldName)

    case .bytes:
      return try convertJSONToBytes(jsonValue, fieldName: fieldName)

    case .message:
      return try convertJSONToMessage(jsonValue, typeName: typeName, fieldName: fieldName)

    case .enum:
      return try convertJSONToEnum(jsonValue, fieldName: fieldName)

    case .group:
      throw JSONDeserializationError.unsupportedFieldType(type: "group")
    }
  }

  // MARK: - JSON Value Conversion Methods

  /// Converts JSON value to Double.
  private func convertJSONToDouble(_ jsonValue: Any, fieldName: String) throws -> Double {
    if let numberValue = jsonValue as? NSNumber {
      return numberValue.doubleValue
    }
    else if let stringValue = jsonValue as? String {
      // Handle special values
      switch stringValue {
      case "Infinity":
        return Double.infinity
      case "-Infinity":
        return -Double.infinity
      case "NaN":
        return Double.nan
      default:
        guard let doubleValue = Double(stringValue) else {
          throw JSONDeserializationError.invalidNumberFormat(fieldName: fieldName, value: stringValue)
        }
        return doubleValue
      }
    }
    else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  /// Converts JSON value to Float.
  private func convertJSONToFloat(_ jsonValue: Any, fieldName: String) throws -> Float {
    if let numberValue = jsonValue as? NSNumber {
      return numberValue.floatValue
    }
    else if let stringValue = jsonValue as? String {
      // Handle special values
      switch stringValue {
      case "Infinity":
        return Float.infinity
      case "-Infinity":
        return -Float.infinity
      case "NaN":
        return Float.nan
      default:
        guard let floatValue = Float(stringValue) else {
          throw JSONDeserializationError.invalidNumberFormat(fieldName: fieldName, value: stringValue)
        }
        return floatValue
      }
    }
    else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  /// Converts JSON value to Int32.
  private func convertJSONToInt32(_ jsonValue: Any, fieldName: String) throws -> Int32 {
    if let numberValue = jsonValue as? NSNumber {
      let int64Value = numberValue.int64Value
      guard int64Value >= Int64(Int32.min) && int64Value <= Int64(Int32.max) else {
        throw JSONDeserializationError.numberOutOfRange(
          fieldName: fieldName,
          value: int64Value,
          expectedRange: "Int32"
        )
      }
      return Int32(int64Value)
    }
    else if let stringValue = jsonValue as? String {
      guard let int32Value = Int32(stringValue) else {
        throw JSONDeserializationError.invalidNumberFormat(fieldName: fieldName, value: stringValue)
      }
      return int32Value
    }
    else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  /// Converts JSON value to Int64.
  private func convertJSONToInt64(_ jsonValue: Any, fieldName: String) throws -> Int64 {
    if let numberValue = jsonValue as? NSNumber {
      return numberValue.int64Value
    }
    else if let stringValue = jsonValue as? String {
      guard let int64Value = Int64(stringValue) else {
        throw JSONDeserializationError.invalidNumberFormat(fieldName: fieldName, value: stringValue)
      }
      return int64Value
    }
    else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  /// Converts JSON value to UInt32.
  private func convertJSONToUInt32(_ jsonValue: Any, fieldName: String) throws -> UInt32 {
    if let numberValue = jsonValue as? NSNumber {
      let uint64Value = numberValue.uint64Value
      guard uint64Value <= UInt64(UInt32.max) else {
        throw JSONDeserializationError.numberOutOfRange(
          fieldName: fieldName,
          value: Int64(uint64Value),
          expectedRange: "UInt32"
        )
      }
      return UInt32(uint64Value)
    }
    else if let stringValue = jsonValue as? String {
      guard let uint32Value = UInt32(stringValue) else {
        throw JSONDeserializationError.invalidNumberFormat(fieldName: fieldName, value: stringValue)
      }
      return uint32Value
    }
    else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  /// Converts JSON value to UInt64.
  private func convertJSONToUInt64(_ jsonValue: Any, fieldName: String) throws -> UInt64 {
    if let numberValue = jsonValue as? NSNumber {
      return numberValue.uint64Value
    }
    else if let stringValue = jsonValue as? String {
      guard let uint64Value = UInt64(stringValue) else {
        throw JSONDeserializationError.invalidNumberFormat(fieldName: fieldName, value: stringValue)
      }
      return uint64Value
    }
    else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  /// Converts JSON value to Bool.
  private func convertJSONToBool(_ jsonValue: Any, fieldName: String) throws -> Bool {
    if let boolValue = jsonValue as? Bool {
      return boolValue
    }
    else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Boolean",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  /// Converts JSON value to String.
  private func convertJSONToString(_ jsonValue: Any, fieldName: String) throws -> String {
    if let stringValue = jsonValue as? String {
      return stringValue
    }
    else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  /// Converts JSON value to Data (from base64).
  private func convertJSONToBytes(_ jsonValue: Any, fieldName: String) throws -> Data {
    guard let base64String = jsonValue as? String else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "String (base64)",
        actual: String(describing: type(of: jsonValue))
      )
    }

    guard let data = Data(base64Encoded: base64String) else {
      throw JSONDeserializationError.invalidBase64(fieldName: fieldName, value: base64String)
    }

    return data
  }

  /// Converts JSON value to DynamicMessage.
  private func convertJSONToMessage(_ jsonValue: Any, typeName: String?, fieldName: String) throws -> DynamicMessage {
    guard jsonValue is [String: Any] else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Object",
        actual: String(describing: type(of: jsonValue))
      )
    }

    guard let typeName = typeName else {
      throw JSONDeserializationError.missingTypeName(fieldName: fieldName)
    }

    // For nested message deserialization we need its descriptor
    // In real implementation this should be obtained from TypeRegistry
    // For now using stub
    throw JSONDeserializationError.unsupportedNestedMessage(
      fieldName: fieldName,
      typeName: typeName
    )
  }

  /// Converts JSON value to enum.
  private func convertJSONToEnum(_ jsonValue: Any, fieldName: String) throws -> Int32 {
    if let numberValue = jsonValue as? NSNumber {
      return numberValue.int32Value
    }
    else if let stringValue = jsonValue as? String {
      // In future can add support for enum names
      guard let enumValue = Int32(stringValue) else {
        throw JSONDeserializationError.invalidEnumValue(fieldName: fieldName, value: stringValue)
      }
      return enumValue
    }
    else {
      throw JSONDeserializationError.valueTypeMismatch(
        fieldName: fieldName,
        expected: "Number or String",
        actual: String(describing: type(of: jsonValue))
      )
    }
  }

  /// Converts JSON string to map key.
  private func convertJSONStringToMapKey(_ jsonKey: String, keyType: FieldType, fieldName: String) throws -> Any {
    switch keyType {
    case .string:
      return jsonKey

    case .int32, .sint32, .sfixed32:
      guard let int32Value = Int32(jsonKey) else {
        throw JSONDeserializationError.invalidMapKeyFormat(
          fieldName: fieldName,
          keyType: "Int32",
          value: jsonKey
        )
      }
      return int32Value

    case .int64, .sint64, .sfixed64:
      guard let int64Value = Int64(jsonKey) else {
        throw JSONDeserializationError.invalidMapKeyFormat(
          fieldName: fieldName,
          keyType: "Int64",
          value: jsonKey
        )
      }
      return int64Value

    case .uint32, .fixed32:
      guard let uint32Value = UInt32(jsonKey) else {
        throw JSONDeserializationError.invalidMapKeyFormat(
          fieldName: fieldName,
          keyType: "UInt32",
          value: jsonKey
        )
      }
      return uint32Value

    case .uint64, .fixed64:
      guard let uint64Value = UInt64(jsonKey) else {
        throw JSONDeserializationError.invalidMapKeyFormat(
          fieldName: fieldName,
          keyType: "UInt64",
          value: jsonKey
        )
      }
      return uint64Value

    case .bool:
      switch jsonKey {
      case "true":
        return true
      case "false":
        return false
      default:
        throw JSONDeserializationError.invalidMapKeyFormat(
          fieldName: fieldName,
          keyType: "Bool",
          value: jsonKey
        )
      }

    default:
      throw JSONDeserializationError.invalidMapKeyType(
        fieldName: fieldName,
        keyType: String(describing: keyType)
      )
    }
  }
}

// MARK: - JSON Deserialization Options

/// Options for JSON deserialization.
public struct JSONDeserializationOptions {
  /// Ignore unknown fields in JSON.
  public let ignoreUnknownFields: Bool

  /// Strict type validation.
  public let strictTypeValidation: Bool

  /// Creates JSON deserialization options.
  public init(
    ignoreUnknownFields: Bool = true,
    strictTypeValidation: Bool = true
  ) {
    self.ignoreUnknownFields = ignoreUnknownFields
    self.strictTypeValidation = strictTypeValidation
  }
}

// MARK: - JSON Deserialization Errors

/// JSON deserialization errors.
public enum JSONDeserializationError: Error, Equatable {
  case invalidJSON(underlyingError: Error)
  case invalidJSONStructure(expected: String, actual: String)
  case unknownField(fieldName: String, messageName: String)
  case invalidFieldType(fieldName: String, expectedType: String, actualType: String)
  case valueTypeMismatch(fieldName: String, expected: String, actual: String)
  case invalidNumberFormat(fieldName: String, value: String)
  case numberOutOfRange(fieldName: String, value: Int64, expectedRange: String)
  case invalidBase64(fieldName: String, value: String)
  case invalidEnumValue(fieldName: String, value: String)
  case invalidMapKeyFormat(fieldName: String, keyType: String, value: String)
  case invalidMapKeyType(fieldName: String, keyType: String)
  case invalidMapKey(fieldName: String, key: String)
  case invalidArrayElement(fieldName: String, index: Int, underlyingError: Error)
  case missingMapEntryInfo(fieldName: String)
  case missingTypeName(fieldName: String)
  case unsupportedNestedMessage(fieldName: String, typeName: String)
  case unsupportedFieldType(type: String)

  public var description: String {
    switch self {
    case .invalidJSON(let underlyingError):
      return "Invalid JSON: \(underlyingError.localizedDescription)"
    case .invalidJSONStructure(let expected, let actual):
      return "Invalid JSON structure: expected \(expected), got \(actual)"
    case .unknownField(let fieldName, let messageName):
      return "Unknown field '\(fieldName)' in message '\(messageName)'"
    case .invalidFieldType(let fieldName, let expectedType, let actualType):
      return "Invalid field type for '\(fieldName)': expected \(expectedType), got \(actualType)"
    case .valueTypeMismatch(let fieldName, let expected, let actual):
      return "Value type mismatch for field '\(fieldName)': expected \(expected), got \(actual)"
    case .invalidNumberFormat(let fieldName, let value):
      return "Invalid number format for field '\(fieldName)': \(value)"
    case .numberOutOfRange(let fieldName, let value, let expectedRange):
      return "Number out of range for field '\(fieldName)': \(value) (expected \(expectedRange))"
    case .invalidBase64(let fieldName, let value):
      return "Invalid base64 string for field '\(fieldName)': \(value)"
    case .invalidEnumValue(let fieldName, let value):
      return "Invalid enum value for field '\(fieldName)': \(value)"
    case .invalidMapKeyFormat(let fieldName, let keyType, let value):
      return "Invalid map key format for field '\(fieldName)': expected \(keyType), got '\(value)'"
    case .invalidMapKeyType(let fieldName, let keyType):
      return "Invalid map key type for field '\(fieldName)': \(keyType)"
    case .invalidMapKey(let fieldName, let key):
      return "Invalid map key for field '\(fieldName)': \(key)"
    case .invalidArrayElement(let fieldName, let index, let underlyingError):
      return "Invalid array element for field '\(fieldName)' at index \(index): \(underlyingError.localizedDescription)"
    case .missingMapEntryInfo(let fieldName):
      return "Missing map entry info for field '\(fieldName)'"
    case .missingTypeName(let fieldName):
      return "Missing type name for field '\(fieldName)'"
    case .unsupportedNestedMessage(let fieldName, let typeName):
      return "Unsupported nested message for field '\(fieldName)': \(typeName)"
    case .unsupportedFieldType(let type):
      return "Unsupported field type: \(type)"
    }
  }

  public static func == (lhs: JSONDeserializationError, rhs: JSONDeserializationError) -> Bool {
    switch (lhs, rhs) {
    case (.invalidJSON(_), .invalidJSON(_)):
      return true  // Hard to compare underlying errors
    case (
      .invalidJSONStructure(let lExpected, let lActual),
      .invalidJSONStructure(let rExpected, let rActual)
    ):
      return lExpected == rExpected && lActual == rActual
    case (
      .unknownField(let lField, let lMessage),
      .unknownField(let rField, let rMessage)
    ):
      return lField == rField && lMessage == rMessage
    case (
      .invalidFieldType(let lField, let lExpected, let lActual),
      .invalidFieldType(let rField, let rExpected, let rActual)
    ):
      return lField == rField && lExpected == rExpected && lActual == rActual
    case (
      .valueTypeMismatch(let lField, let lExpected, let lActual),
      .valueTypeMismatch(let rField, let rExpected, let rActual)
    ):
      return lField == rField && lExpected == rExpected && lActual == rActual
    case (
      .invalidNumberFormat(let lField, let lValue),
      .invalidNumberFormat(let rField, let rValue)
    ):
      return lField == rField && lValue == rValue
    case (
      .numberOutOfRange(let lField, let lValue, let lRange),
      .numberOutOfRange(let rField, let rValue, let rRange)
    ):
      return lField == rField && lValue == rValue && lRange == rRange
    case (
      .invalidBase64(let lField, let lValue),
      .invalidBase64(let rField, let rValue)
    ):
      return lField == rField && lValue == rValue
    case (
      .invalidEnumValue(let lField, let lValue),
      .invalidEnumValue(let rField, let rValue)
    ):
      return lField == rField && lValue == rValue
    case (
      .invalidMapKeyFormat(let lField, let lType, let lValue),
      .invalidMapKeyFormat(let rField, let rType, let rValue)
    ):
      return lField == rField && lType == rType && lValue == rValue
    case (
      .invalidMapKeyType(let lField, let lType),
      .invalidMapKeyType(let rField, let rType)
    ):
      return lField == rField && lType == rType
    case (
      .invalidMapKey(let lField, let lKey),
      .invalidMapKey(let rField, let rKey)
    ):
      return lField == rField && lKey == rKey
    case (
      .invalidArrayElement(let lField, let lIndex, _),
      .invalidArrayElement(let rField, let rIndex, _)
    ):
      return lField == rField && lIndex == rIndex  // Don't compare underlying errors
    case (.missingMapEntryInfo(let lField), .missingMapEntryInfo(let rField)):
      return lField == rField
    case (.missingTypeName(let lField), .missingTypeName(let rField)):
      return lField == rField
    case (
      .unsupportedNestedMessage(let lField, let lType),
      .unsupportedNestedMessage(let rField, let rType)
    ):
      return lField == rField && lType == rType
    case (.unsupportedFieldType(let lType), .unsupportedFieldType(let rType)):
      return lType == rType
    default:
      return false
    }
  }
}
