//
// Serialization.swift (public API)
// SwiftProtoReflect
//
// Public surface for binary and JSON serialization/deserialization.
// Internal implementations live in Serialization/_BinarySerializer.swift,
// _BinaryDeserializer.swift, _JSONSerializer.swift, _JSONDeserializer.swift.
//

import Foundation

// MARK: - WireType

/// Wire type for Protocol Buffers encoding.
public enum WireType: UInt32, Equatable, Sendable {
  case varint = 0
  case fixed64 = 1
  case lengthDelimited = 2
  case startGroup = 3
  case endGroup = 4
  case fixed32 = 5
}

extension WireType {
  init(from impl: _WireType) {
    switch impl {
    case .varint: self = .varint
    case .fixed64: self = .fixed64
    case .lengthDelimited: self = .lengthDelimited
    case .startGroup: self = .startGroup
    case .endGroup: self = .endGroup
    case .fixed32: self = .fixed32
    }
  }
}

extension _WireType {
  init(from pub: WireType) {
    switch pub {
    case .varint: self = .varint
    case .fixed64: self = .fixed64
    case .lengthDelimited: self = .lengthDelimited
    case .startGroup: self = .startGroup
    case .endGroup: self = .endGroup
    case .fixed32: self = .fixed32
    }
  }
}

// MARK: - SerializationOptions

/// Options for binary serialization.
public struct SerializationOptions: Sendable {
  /// Whether to use packed encoding for repeated numeric fields.
  public let usePackedRepeated: Bool

  /// Creates serialization options.
  public init(usePackedRepeated: Bool = true) {
    self.usePackedRepeated = usePackedRepeated
  }
}

extension _SerializationOptions {
  init(from pub: SerializationOptions) {
    self.init(usePackedRepeated: pub.usePackedRepeated)
  }
}

// MARK: - SerializationError

/// Serialization errors.
public enum SerializationError: Error, Equatable, Sendable {
  case invalidFieldType(fieldName: String, expectedType: String, actualType: String)
  case valueTypeMismatch(expected: String, actual: String)
  case missingMapEntryInfo(fieldName: String)
  case missingFieldValue(fieldName: String)
  case unsupportedFieldType(type: String)

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
    }
  }
}

extension SerializationError {
  init(from impl: _SerializationError) {
    switch impl {
    case .invalidFieldType(let f, let e, let a): self = .invalidFieldType(fieldName: f, expectedType: e, actualType: a)
    case .valueTypeMismatch(let e, let a): self = .valueTypeMismatch(expected: e, actual: a)
    case .missingMapEntryInfo(let f): self = .missingMapEntryInfo(fieldName: f)
    case .missingFieldValue(let f): self = .missingFieldValue(fieldName: f)
    case .unsupportedFieldType(let t): self = .unsupportedFieldType(type: t)
    }
  }
}

// MARK: - BinarySerializer

/// Serializes dynamic Protocol Buffers messages to binary wire format.
///
/// Provides functionality for serializing dynamic Protocol Buffers messages
/// to binary wire format, using integration with Swift Protobuf library
/// to ensure compatibility with Protocol Buffers standard.
public struct BinarySerializer: Sendable {

  // MARK: - Properties

  /// Serialization options.
  public let options: SerializationOptions

  private let impl: _BinarySerializer

  // MARK: - Initialization

  /// Creates new BinarySerializer instance.
  ///
  /// - Parameter options: Serialization options.
  public init(options: SerializationOptions = SerializationOptions()) {
    self.options = options
    self.impl = _BinarySerializer(options: _SerializationOptions(from: options))
  }

  // MARK: - Serialization Methods

  /// Serializes dynamic message to binary format.
  ///
  /// - Parameter message: Dynamic message to serialize.
  /// - Returns: Serialized data in binary format.
  /// - Throws: `SerializationError` if serialization failed.
  public func serialize(_ message: DynamicMessage) throws -> Data {
    do {
      return try impl.serialize(_DynamicMessage(from: message))
    }
    catch let e as _SerializationError {
      throw SerializationError(from: e)
    }
  }

}

// MARK: - DeserializationOptions

/// Options for binary deserialization.
public struct DeserializationOptions {
  /// Whether to preserve unknown fields for backward compatibility.
  public let preserveUnknownFields: Bool

  /// Strict UTF-8 string validation.
  public let strictUTF8Validation: Bool

  /// Registry used to resolve message-type fields by fully-qualified name.
  ///
  /// Pass a populated `TypeRegistry` to enable cross-file and sibling-message resolution.
  /// For hand-built descriptors without cross-file references, an empty `TypeRegistry()` is sufficient.
  public let typeRegistry: TypeRegistry

  /// Creates deserialization options with a required TypeRegistry.
  ///
  /// - Parameters:
  ///   - preserveUnknownFields: Whether to preserve unknown fields. Defaults to `true`.
  ///   - strictUTF8Validation: Whether to enforce strict UTF-8 string validation. Defaults to `true`.
  ///   - typeRegistry: Registry for resolving message types by fully-qualified name.
  public init(
    preserveUnknownFields: Bool = true,
    strictUTF8Validation: Bool = true,
    typeRegistry: TypeRegistry
  ) {
    self.preserveUnknownFields = preserveUnknownFields
    self.strictUTF8Validation = strictUTF8Validation
    self.typeRegistry = typeRegistry
  }
}

extension _DeserializationOptions {
  init(from pub: DeserializationOptions) {
    self.init(
      preserveUnknownFields: pub.preserveUnknownFields,
      strictUTF8Validation: pub.strictUTF8Validation,
      typeRegistry: pub.typeRegistry.typeRegistryImpl
    )
  }
}

// MARK: - DeserializationError

/// Deserialization errors.
public enum DeserializationError: Error, Equatable {
  case truncatedVarint
  case truncatedMessage
  case invalidWireType(tag: UInt32)
  case wireTypeMismatch(fieldName: String, expected: WireType, actual: WireType)
  case invalidUTF8String
  case malformedPackedField(fieldName: String)
  case malformedMapEntry(fieldName: String)
  case missingMapEntryInfo(fieldName: String)
  case missingTypeName(fieldType: String)
  case unsupportedNestedMessage(typeName: String)
  case unsupportedFieldType(type: String)

  public var description: String {
    switch self {
    case .truncatedVarint:
      return "Truncated varint"
    case .truncatedMessage:
      return "Truncated message"
    case .invalidWireType(let tag):
      return "Invalid wire type in tag: \(tag)"
    case .wireTypeMismatch(let fieldName, let expected, let actual):
      return "Wire type mismatch for field '\(fieldName)': expected \(expected), got \(actual)"
    case .invalidUTF8String:
      return "Invalid UTF-8 string"
    case .malformedPackedField(let fieldName):
      return "Malformed packed field: \(fieldName)"
    case .malformedMapEntry(let fieldName):
      return "Malformed map entry: \(fieldName)"
    case .missingMapEntryInfo(let fieldName):
      return "Missing map entry info for field '\(fieldName)'"
    case .missingTypeName(let fieldType):
      return "Missing type name for field type: \(fieldType)"
    case .unsupportedNestedMessage(let typeName):
      return "Unsupported nested message type: \(typeName)"
    case .unsupportedFieldType(let type):
      return "Unsupported field type: \(type)"
    }
  }
}

extension DeserializationError {
  init(from impl: _DeserializationError) {
    switch impl {
    case .truncatedVarint: self = .truncatedVarint
    case .truncatedMessage: self = .truncatedMessage
    case .invalidWireType(let t): self = .invalidWireType(tag: t)
    case .wireTypeMismatch(let f, let e, let a):
      self = .wireTypeMismatch(fieldName: f, expected: WireType(from: e), actual: WireType(from: a))
    case .invalidUTF8String: self = .invalidUTF8String
    case .malformedPackedField(let f): self = .malformedPackedField(fieldName: f)
    case .malformedMapEntry(let f): self = .malformedMapEntry(fieldName: f)
    case .missingMapEntryInfo(let f): self = .missingMapEntryInfo(fieldName: f)
    case .missingTypeName(let t): self = .missingTypeName(fieldType: t)
    case .unsupportedNestedMessage(let t): self = .unsupportedNestedMessage(typeName: t)
    case .unsupportedFieldType(let t): self = .unsupportedFieldType(type: t)
    }
  }
}

// MARK: - BinaryDeserializer

/// Deserializes binary Protocol Buffers data to dynamic messages.
///
/// Provides functionality for deserializing dynamic Protocol Buffers messages
/// from binary wire format, using integration with Swift Protobuf library
/// to ensure compatibility with Protocol Buffers standard.
public struct BinaryDeserializer {

  // MARK: - Properties

  /// Deserialization options.
  public let options: DeserializationOptions

  private let impl: _BinaryDeserializer

  // MARK: - Initialization

  /// Creates new BinaryDeserializer instance.
  ///
  /// - Parameter options: Deserialization options.
  public init(options: DeserializationOptions) {
    self.options = options
    self.impl = _BinaryDeserializer(options: _DeserializationOptions(from: options))
  }

  // MARK: - Deserialization Methods

  /// Deserializes binary data to dynamic message.
  ///
  /// - Parameters:
  ///   - data: Binary data to deserialize.
  ///   - descriptor: Message descriptor to determine structure.
  /// - Returns: Deserialized dynamic message.
  /// - Throws: `DeserializationError` if deserialization failed.
  public func deserialize(_ data: Data, using descriptor: MessageDescriptor) throws -> DynamicMessage {
    do {
      let result = try impl.deserialize(data, using: _MessageDescriptor(from: descriptor))
      return DynamicMessage(from: result)
    }
    catch let e as _DeserializationError {
      throw DeserializationError(from: e)
    }
  }
}

// MARK: - JSONSerializationOptions

/// Options for JSON serialization.
public struct JSONSerializationOptions {
  /// Use original field names instead of camelCase.
  public let useOriginalFieldNames: Bool

  /// Format JSON with indentation for readability.
  public let prettyPrinted: Bool

  /// Include fields with default values.
  public let includeDefaultValues: Bool

  /// Use protobuf-spec canonical representations for well-known types.
  ///
  /// When `true`, the serializer emits well-known type values using their canonical
  /// protobuf JSON mapping (e.g. `Timestamp` as an RFC 3339 string) instead of
  /// generic field-by-field encoding. Defaults to `true`.
  public let useCanonicalWellKnownTypeEncoding: Bool

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
  ///   - useCanonicalWellKnownTypeEncoding: Whether to use canonical protobuf JSON for well-known types. Defaults to `true`.
  ///   - typeRegistry: Registry for resolving message types by fully-qualified name.
  public init(
    useOriginalFieldNames: Bool = false,
    prettyPrinted: Bool = false,
    includeDefaultValues: Bool = false,
    useCanonicalWellKnownTypeEncoding: Bool = true,
    typeRegistry: TypeRegistry
  ) {
    self.useOriginalFieldNames = useOriginalFieldNames
    self.prettyPrinted = prettyPrinted
    self.includeDefaultValues = includeDefaultValues
    self.useCanonicalWellKnownTypeEncoding = useCanonicalWellKnownTypeEncoding
    self.typeRegistry = typeRegistry
  }

}

extension _JSONSerializationOptions {
  init(from pub: JSONSerializationOptions) {
    self.init(
      useOriginalFieldNames: pub.useOriginalFieldNames,
      prettyPrinted: pub.prettyPrinted,
      includeDefaultValues: pub.includeDefaultValues,
      useCanonicalWellKnownTypeEncoding: pub.useCanonicalWellKnownTypeEncoding,
      typeRegistry: pub.typeRegistry.typeRegistryImpl
    )
  }
}

// MARK: - JSONSerializationError

/// JSON serialization errors.
public enum JSONSerializationError: Error, Equatable {
  case invalidFieldType(fieldName: String, expectedType: String, actualType: String)
  case valueTypeMismatch(expected: String, actual: String)
  case missingMapEntryInfo(fieldName: String)
  case missingFieldValue(fieldName: String)
  case unsupportedFieldType(type: String)
  case invalidMapKeyType(keyType: String)
  case jsonWriteError(underlyingError: Error)
  /// Canonical JSON encoding for a well-known type is not yet implemented.
  case unsupportedWellKnownTypeEncoding(typeName: String)

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
    case .unsupportedWellKnownTypeEncoding(let typeName):
      return "Canonical JSON encoding for well-known type '\(typeName)' is not yet implemented"
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
      return true
    case (
      .unsupportedWellKnownTypeEncoding(let lType),
      .unsupportedWellKnownTypeEncoding(let rType)
    ):
      return lType == rType
    default:
      return false
    }
  }
}

extension JSONSerializationError {
  init(from impl: _JSONSerializationError) {
    switch impl {
    case .invalidFieldType(let f, let e, let a):
      self = .invalidFieldType(fieldName: f, expectedType: e, actualType: a)
    case .valueTypeMismatch(let e, let a): self = .valueTypeMismatch(expected: e, actual: a)
    case .missingMapEntryInfo(let f): self = .missingMapEntryInfo(fieldName: f)
    case .missingFieldValue(let f): self = .missingFieldValue(fieldName: f)
    case .unsupportedFieldType(let t): self = .unsupportedFieldType(type: t)
    case .invalidMapKeyType(let t): self = .invalidMapKeyType(keyType: t)
    case .jsonWriteError(let e): self = .jsonWriteError(underlyingError: e)
    case .unsupportedWellKnownTypeEncoding(let t): self = .unsupportedWellKnownTypeEncoding(typeName: t)
    }
  }
}

// MARK: - JSONSerializer

/// Serializes dynamic Protocol Buffers messages to JSON format.
///
/// Provides functionality for serializing dynamic Protocol Buffers messages
/// to JSON format according to official Protocol Buffers JSON mapping specification.
/// Ensures full compatibility with protoc --json_out.
public struct JSONSerializer {

  // MARK: - Properties

  /// JSON serialization options.
  public let options: JSONSerializationOptions

  private let impl: _JSONSerializer

  // MARK: - Initialization

  /// Creates new JSONSerializer instance.
  ///
  /// - Parameter options: JSON serialization options.
  public init(options: JSONSerializationOptions) {
    self.options = options
    self.impl = _JSONSerializer(options: _JSONSerializationOptions(from: options))
  }

  // MARK: - Serialization Methods

  /// Serializes dynamic message to JSON format.
  ///
  /// - Parameter message: Dynamic message to serialize.
  /// - Returns: JSON string in Data format.
  /// - Throws: `JSONSerializationError` if serialization failed.
  public func serialize(_ message: DynamicMessage) throws -> Data {
    do {
      return try impl.serialize(_DynamicMessage(from: message))
    }
    catch let e as _JSONSerializationError {
      throw JSONSerializationError(from: e)
    }
  }

  /// Serializes dynamic message to a JSON-compatible object dictionary.
  ///
  /// - Parameter message: Dynamic message to serialize.
  /// - Returns: JSON compatible object (Dictionary).
  /// - Throws: `JSONSerializationError` if serialization failed.
  public func serializeToJSONObject(_ message: DynamicMessage) throws -> [String: Any] {
    do {
      return try impl.serializeToJSONObject(_DynamicMessage(from: message))
    }
    catch let e as _JSONSerializationError {
      throw JSONSerializationError(from: e)
    }
  }
}

// MARK: - JSONDeserializationOptions

/// Options for JSON deserialization.
public struct JSONDeserializationOptions {
  /// Ignore unknown fields in JSON.
  public let ignoreUnknownFields: Bool

  /// Strict type validation.
  public let strictTypeValidation: Bool

  /// Registry for resolving nested message descriptors by fully-qualified name.
  ///
  /// Pass a populated `TypeRegistry` to enable cross-file and sibling-message resolution.
  /// For hand-built descriptors without cross-file references, an empty `TypeRegistry()` is sufficient.
  public let typeRegistry: TypeRegistry

  /// Maximum allowed nesting depth for recursive message deserialization.
  public let maxNestingDepth: Int

  /// Creates JSON deserialization options with a required TypeRegistry.
  ///
  /// - Parameters:
  ///   - ignoreUnknownFields: Whether to ignore unknown JSON fields. Defaults to `true`.
  ///   - strictTypeValidation: Whether to enforce strict type validation. Defaults to `true`.
  ///   - typeRegistry: Registry for resolving nested message types by fully-qualified name.
  ///   - maxNestingDepth: Maximum allowed nesting depth. Defaults to `64`.
  public init(
    ignoreUnknownFields: Bool = true,
    strictTypeValidation: Bool = true,
    typeRegistry: TypeRegistry,
    maxNestingDepth: Int = 64
  ) {
    self.ignoreUnknownFields = ignoreUnknownFields
    self.strictTypeValidation = strictTypeValidation
    self.typeRegistry = typeRegistry
    self.maxNestingDepth = maxNestingDepth
  }
}

extension _JSONDeserializationOptions {
  init(from pub: JSONDeserializationOptions) {
    self.init(
      ignoreUnknownFields: pub.ignoreUnknownFields,
      strictTypeValidation: pub.strictTypeValidation,
      typeRegistry: pub.typeRegistry.typeRegistryImpl,
      maxNestingDepth: pub.maxNestingDepth
    )
  }
}

// MARK: - JSONDeserializationError

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
  case nestedMessageDescriptorNotFound(fieldName: String, typeName: String)
  case nestingDepthExceeded(maxDepth: Int)
  case unsupportedFieldType(type: String)
  /// Canonical JSON decoding for a well-known type is not yet implemented.
  case unsupportedWellKnownTypeDecoding(typeName: String)

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
      return
        "Invalid array element for field '\(fieldName)' at index \(index): \(underlyingError.localizedDescription)"
    case .missingMapEntryInfo(let fieldName):
      return "Missing map entry info for field '\(fieldName)'"
    case .missingTypeName(let fieldName):
      return "Missing type name for field '\(fieldName)'"
    case .unsupportedNestedMessage(let fieldName, let typeName):
      return "Unsupported nested message for field '\(fieldName)': \(typeName)"
    case .nestedMessageDescriptorNotFound(let fieldName, let typeName):
      return "Nested message descriptor not found for field '\(fieldName)': \(typeName)"
    case .nestingDepthExceeded(let maxDepth):
      return "Nesting depth exceeded maximum of \(maxDepth)"
    case .unsupportedFieldType(let type):
      return "Unsupported field type: \(type)"
    case .unsupportedWellKnownTypeDecoding(let typeName):
      return "Canonical JSON decoding for well-known type '\(typeName)' is not yet implemented"
    }
  }

  public static func == (lhs: JSONDeserializationError, rhs: JSONDeserializationError) -> Bool {
    switch (lhs, rhs) {
    case (.invalidJSON(_), .invalidJSON(_)):
      return true
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
      return lField == rField && lIndex == rIndex
    case (.missingMapEntryInfo(let lField), .missingMapEntryInfo(let rField)):
      return lField == rField
    case (.missingTypeName(let lField), .missingTypeName(let rField)):
      return lField == rField
    case (
      .unsupportedNestedMessage(let lField, let lType),
      .unsupportedNestedMessage(let rField, let rType)
    ):
      return lField == rField && lType == rType
    case (
      .nestedMessageDescriptorNotFound(let lField, let lType),
      .nestedMessageDescriptorNotFound(let rField, let rType)
    ):
      return lField == rField && lType == rType
    case (.nestingDepthExceeded(let lMax), .nestingDepthExceeded(let rMax)):
      return lMax == rMax
    case (.unsupportedFieldType(let lType), .unsupportedFieldType(let rType)):
      return lType == rType
    case (
      .unsupportedWellKnownTypeDecoding(let lType),
      .unsupportedWellKnownTypeDecoding(let rType)
    ):
      return lType == rType
    default:
      return false
    }
  }
}

extension JSONDeserializationError {
  init(from impl: _JSONDeserializationError) {
    switch impl {
    case .invalidJSON(let e): self = .invalidJSON(underlyingError: e)
    case .invalidJSONStructure(let e, let a): self = .invalidJSONStructure(expected: e, actual: a)
    case .unknownField(let f, let m): self = .unknownField(fieldName: f, messageName: m)
    case .invalidFieldType(let f, let e, let a):
      self = .invalidFieldType(fieldName: f, expectedType: e, actualType: a)
    case .valueTypeMismatch(let f, let e, let a):
      self = .valueTypeMismatch(fieldName: f, expected: e, actual: a)
    case .invalidNumberFormat(let f, let v): self = .invalidNumberFormat(fieldName: f, value: v)
    case .numberOutOfRange(let f, let v, let r):
      self = .numberOutOfRange(fieldName: f, value: v, expectedRange: r)
    case .invalidBase64(let f, let v): self = .invalidBase64(fieldName: f, value: v)
    case .invalidEnumValue(let f, let v): self = .invalidEnumValue(fieldName: f, value: v)
    case .invalidMapKeyFormat(let f, let k, let v):
      self = .invalidMapKeyFormat(fieldName: f, keyType: k, value: v)
    case .invalidMapKeyType(let f, let k): self = .invalidMapKeyType(fieldName: f, keyType: k)
    case .invalidMapKey(let f, let k): self = .invalidMapKey(fieldName: f, key: k)
    case .invalidArrayElement(let f, let i, let e):
      self = .invalidArrayElement(fieldName: f, index: i, underlyingError: e)
    case .missingMapEntryInfo(let f): self = .missingMapEntryInfo(fieldName: f)
    case .missingTypeName(let f): self = .missingTypeName(fieldName: f)
    case .unsupportedNestedMessage(let f, let t):
      self = .unsupportedNestedMessage(fieldName: f, typeName: t)
    case .nestedMessageDescriptorNotFound(let f, let t):
      self = .nestedMessageDescriptorNotFound(fieldName: f, typeName: t)
    case .nestingDepthExceeded(let m): self = .nestingDepthExceeded(maxDepth: m)
    case .unsupportedFieldType(let t): self = .unsupportedFieldType(type: t)
    case .unsupportedWellKnownTypeDecoding(let t): self = .unsupportedWellKnownTypeDecoding(typeName: t)
    }
  }
}

// MARK: - JSONDeserializer

/// Deserializes JSON data to dynamic Protocol Buffers messages.
///
/// Provides functionality for deserializing JSON data to dynamic Protocol Buffers messages
/// according to official Protocol Buffers JSON mapping specification.
/// Ensures full compatibility with JSONSerializer for round-trip operations.
public struct JSONDeserializer {

  // MARK: - Properties

  /// JSON deserialization options.
  public let options: JSONDeserializationOptions

  private let impl: _JSONDeserializer

  // MARK: - Initialization

  /// Creates new JSONDeserializer instance.
  ///
  /// - Parameter options: JSON deserialization options.
  public init(options: JSONDeserializationOptions) {
    self.options = options
    self.impl = _JSONDeserializer(options: _JSONDeserializationOptions(from: options))
  }

  // MARK: - Deserialization Methods

  /// Deserializes JSON data to dynamic message.
  ///
  /// - Parameters:
  ///   - data: JSON data to deserialize.
  ///   - descriptor: Message descriptor to determine structure.
  /// - Returns: Deserialized dynamic message.
  /// - Throws: `JSONDeserializationError` if deserialization failed.
  public func deserialize(_ data: Data, using descriptor: MessageDescriptor) throws -> DynamicMessage {
    do {
      let result = try impl.deserialize(data, using: _MessageDescriptor(from: descriptor))
      return DynamicMessage(from: result)
    }
    catch let e as _JSONDeserializationError {
      throw JSONDeserializationError(from: e)
    }
  }

  /// Deserializes a JSON object dictionary to dynamic message.
  ///
  /// - Parameters:
  ///   - jsonObject: JSON object (Dictionary) to deserialize.
  ///   - descriptor: Message descriptor to determine structure.
  /// - Returns: Deserialized dynamic message.
  /// - Throws: `JSONDeserializationError` if deserialization failed.
  public func deserializeFromJSONObject(
    _ jsonObject: [String: Any],
    using descriptor: MessageDescriptor
  ) throws -> DynamicMessage {
    do {
      let result = try impl.deserializeFromJSONObject(jsonObject, using: _MessageDescriptor(from: descriptor))
      return DynamicMessage(from: result)
    }
    catch let e as _JSONDeserializationError {
      throw JSONDeserializationError(from: e)
    }
  }
}
