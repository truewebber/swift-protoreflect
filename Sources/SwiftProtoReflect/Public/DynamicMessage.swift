//
// DynamicMessage.swift (public API)
// SwiftProtoReflect
//

// MARK: - Sendable policy (OPE-302)
//
// `DynamicMessage` is `@unchecked Sendable` because `_DynamicMessage` stores field values in
// `[Int: Any]`, `[Int: [Any]]`, and `[Int: [AnyHashable: Any]]`, and `Any` is not `Sendable`.
// Invariant: every stored value is an immutable protobuf scalar, `Data`, `String`, nested
// `_DynamicMessage`, or homogeneous collections of those, inserted only through this type's
// `set`/`addRepeatedValue`/`setMapEntry` APIs (type-checked at runtime). Same contract as
// pre–public-split `DynamicMessage`.

import Foundation
import SwiftProtobuf

// MARK: - DynamicMessageError

/// Errors that occur when working with dynamic messages.
public enum DynamicMessageError: Error, LocalizedError, Sendable {
  /// No field with the given name exists in the message descriptor.
  case fieldNotFound(fieldName: String)
  /// No field with the given number exists in the message descriptor.
  case fieldNotFoundByNumber(fieldNumber: Int)
  /// The value supplied for a field does not match its declared type.
  case typeMismatch(fieldName: String, expectedType: String, actualType: String)
  /// The nested message type does not match the field's expected message type.
  case messageMismatch(fieldName: String, expectedType: String, actualType: String)
  /// The operation requires a repeated field, but the field is singular.
  case notRepeatedField(fieldName: String)
  /// The operation requires a map field, but the field is not a map.
  case notMapField(fieldName: String)
  /// The key type is not valid for use as a protobuf map key.
  case invalidMapKeyType(type: FieldType)

  /// Human-readable description of the error.
  public var errorDescription: String? {
    switch self {
    case .fieldNotFound(let fieldName):
      return "Field with name '\(fieldName)' not found"
    case .fieldNotFoundByNumber(let fieldNumber):
      return "Field with number \(fieldNumber) not found"
    case .typeMismatch(let fieldName, let expectedType, let actualType):
      return "Type mismatch for field '\(fieldName)': expected \(expectedType), got \(actualType)"
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

// MARK: - DynamicMessage

/// Dynamic representation of a Protocol Buffers message,
/// which allows creating and manipulating messages
/// at runtime without prior code generation.
public struct DynamicMessage: Equatable, @unchecked Sendable {

  internal var impl: _DynamicMessage

  internal init(impl: _DynamicMessage) {
    self.impl = impl
  }

  /// Creates a new DynamicMessage instance.
  ///
  /// - Parameter descriptor: Message descriptor.
  ///
  /// TODO(Strangler migration / OPE-302): Drop `_MessageDescriptor(from:)` conversion here
  /// when callers that need empty messages can supply `_MessageDescriptor` or conversion is
  /// centralized elsewhere.
  public init(descriptor: MessageDescriptor) {
    self.impl = _DynamicMessage(descriptor: _MessageDescriptor(from: descriptor))
  }

  /// Message descriptor defining its structure.
  ///
  /// TODO(Strangler migration / OPE-302): Revisit per-access `MessageDescriptor(from:)` when
  /// hot paths keep `_MessageDescriptor` and only the public surface pays conversion cost.
  public var descriptor: MessageDescriptor {
    MessageDescriptor(from: impl.descriptor)
  }

  /// Raw bytes of fields not recognised by the descriptor.
  public var unknownFields: Data {
    get { impl.unknownFields }
    set { impl.setUnknownFields(newValue) }
  }

  // TODO(Strangler migration / OPE-302): Revisit or delete once nested values use a typed
  // representation (e.g. `ProtoValue`) or internal-only storage removes the need for
  // recursive `DynamicMessage` ↔ `_DynamicMessage` conversion at the public boundary.
  private static func wrapAnyForImpl(_ value: Any) throws -> Any {
    if let m = value as? DynamicMessage {
      return m.impl
    }
    // [DynamicMessage] does not bridge to [Any] at runtime through Any boxing,
    // so we handle it explicitly before the generic [Any] path.
    // TODO(Strangler migration / OPE-302): Remove once field storage is typed (ProtoValue),
    // eliminating the need for explicit [DynamicMessage] ↔ [_DynamicMessage] round-trips.
    if let arr = value as? [DynamicMessage] {
      return arr.map(\.impl) as [Any]
    }
    if let arr = value as? [Any] {
      return try arr.map { try wrapAnyForImpl($0) }
    }
    if let map = value as? [AnyHashable: Any] {
      var out: [AnyHashable: Any] = [:]
      for (k, v) in map {
        out[k] = try wrapAnyForImpl(v)
      }
      return out
    }
    return value
  }

  private static func unwrapAnyFromImpl(_ value: Any) -> Any {
    if let m = value as? _DynamicMessage {
      return DynamicMessage(impl: m)
    }
    if let arr = value as? [Any] {
      return arr.map { unwrapAnyFromImpl($0) }
    }
    if let map = value as? [AnyHashable: Any] {
      var out: [AnyHashable: Any] = [:]
      for (k, v) in map {
        out[k] = unwrapAnyFromImpl(v)
      }
      return out
    }
    return value
  }

  /// Sets a field value by name.
  ///
  /// - Parameters:
  ///   - value: Value to set.
  ///   - fieldName: Field name as defined in the descriptor.
  /// - Returns: The updated message (`self`) for chaining.
  /// - Throws: `DynamicMessageError` if the field is not found or type is mismatched.
  @discardableResult
  public mutating func set(_ value: Any, forField fieldName: String) throws -> Self {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }
    return try set(value, forField: field.number)
  }

  /// Sets a field value by number.
  ///
  /// - Parameters:
  ///   - value: Value to set.
  ///   - fieldNumber: Field number as defined in the descriptor.
  /// - Returns: The updated message (`self`) for chaining.
  /// - Throws: `DynamicMessageError` if the field is not found or type is mismatched.
  @discardableResult
  public mutating func set(_ value: Any, forField fieldNumber: Int) throws -> Self {
    let wrapped = try Self.wrapAnyForImpl(value)
    try impl.set(wrapped, forField: fieldNumber)
    return self
  }

  /// Returns the value of a field by name, or `nil` if the field is not set.
  ///
  /// - Parameter fieldName: Field name as defined in the descriptor.
  /// - Returns: Field value, or `nil` if unset.
  /// - Throws: `DynamicMessageError` if the field does not exist.
  public func get(forField fieldName: String) throws -> Any? {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }
    return try get(forField: field.number)
  }

  /// Returns the value of a field by number, or `nil` if the field is not set.
  ///
  /// - Parameter fieldNumber: Field number as defined in the descriptor.
  /// - Returns: Field value, or `nil` if unset.
  /// - Throws: `DynamicMessageError` if the field does not exist.
  public func get(forField fieldNumber: Int) throws -> Any? {
    guard let raw = try impl.get(forField: fieldNumber) else {
      return nil
    }
    return Self.unwrapAnyFromImpl(raw)
  }

  /// Returns whether a field has an explicitly set value, looked up by name.
  ///
  /// - Parameter fieldName: Field name as defined in the descriptor.
  /// - Returns: `true` if the field has a value.
  /// - Throws: `DynamicMessageError` if the field does not exist.
  public func hasValue(forField fieldName: String) throws -> Bool {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }
    return try impl.hasValue(forField: field.number)
  }

  /// Returns whether a field has an explicitly set value, looked up by number.
  ///
  /// - Parameter fieldNumber: Field number as defined in the descriptor.
  /// - Returns: `true` if the field has a value.
  /// - Throws: `DynamicMessageError` if the field does not exist.
  public func hasValue(forField fieldNumber: Int) throws -> Bool {
    try impl.hasValue(forField: fieldNumber)
  }

  /// Clears the value of a field by name, resetting it to its default.
  ///
  /// - Parameter fieldName: Field name as defined in the descriptor.
  /// - Returns: The updated message (`self`) for chaining.
  /// - Throws: `DynamicMessageError` if the field does not exist.
  @discardableResult
  public mutating func clearField(_ fieldName: String) throws -> Self {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }
    try impl.clearField(field.number)
    return self
  }

  /// Clears the value of a field by number, resetting it to its default.
  ///
  /// - Parameter fieldNumber: Field number as defined in the descriptor.
  /// - Returns: The updated message (`self`) for chaining.
  /// - Throws: `DynamicMessageError` if the field does not exist.
  @discardableResult
  public mutating func clearField(_ fieldNumber: Int) throws -> Self {
    try impl.clearField(fieldNumber)
    return self
  }

  /// Replaces the raw unknown-field bytes on this message.
  ///
  /// - Parameter data: Serialized unknown fields to store.
  public mutating func setUnknownFields(_ data: Data) {
    impl.setUnknownFields(data)
  }

  /// Appends a value to a repeated field, looked up by name.
  ///
  /// - Parameters:
  ///   - value: Value to append.
  ///   - fieldName: Field name as defined in the descriptor.
  /// - Returns: The updated message (`self`) for chaining.
  /// - Throws: `DynamicMessageError` if the field is not found or is not repeated.
  @discardableResult
  public mutating func addRepeatedValue(_ value: Any, forField fieldName: String) throws -> Self {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }
    return try addRepeatedValue(value, forField: field.number)
  }

  /// Appends a value to a repeated field, looked up by number.
  ///
  /// - Parameters:
  ///   - value: Value to append.
  ///   - fieldNumber: Field number as defined in the descriptor.
  /// - Returns: The updated message (`self`) for chaining.
  /// - Throws: `DynamicMessageError` if the field is not found or is not repeated.
  @discardableResult
  public mutating func addRepeatedValue(_ value: Any, forField fieldNumber: Int) throws -> Self {
    let wrapped = try Self.wrapAnyForImpl(value)
    try impl.addRepeatedValue(wrapped, forField: fieldNumber)
    return self
  }

  /// Sets a map entry in a map field, looked up by name.
  ///
  /// - Parameters:
  ///   - value: Entry value.
  ///   - key: Entry key.
  ///   - fieldName: Field name as defined in the descriptor.
  /// - Returns: The updated message (`self`) for chaining.
  /// - Throws: `DynamicMessageError` if the field is not found or is not a map.
  @discardableResult
  public mutating func setMapEntry(_ value: Any, forKey key: AnyHashable, inField fieldName: String) throws -> Self {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }
    return try setMapEntry(value, forKey: key, inField: field.number)
  }

  /// Sets a map entry in a map field, looked up by number.
  ///
  /// - Parameters:
  ///   - value: Entry value.
  ///   - key: Entry key.
  ///   - fieldNumber: Field number as defined in the descriptor.
  /// - Returns: The updated message (`self`) for chaining.
  /// - Throws: `DynamicMessageError` if the field is not found or is not a map.
  @discardableResult
  public mutating func setMapEntry(_ value: Any, forKey key: AnyHashable, inField fieldNumber: Int) throws -> Self {
    let wrapped = try Self.wrapAnyForImpl(value)
    try impl.setMapEntry(wrapped, forKey: key, inField: fieldNumber)
    return self
  }

  /// Returns `true` if both messages have equal field values.
  public static func == (lhs: DynamicMessage, rhs: DynamicMessage) -> Bool {
    lhs.impl == rhs.impl
  }
}

// MARK: - MessageFactory

/// Factory for creating and managing dynamic Protocol Buffers messages.
public struct MessageFactory: Sendable {

  /// Creates a new `MessageFactory` instance.
  public init() {}

  private let backing = _MessageFactory()

  /// Creates an empty message from the given descriptor.
  ///
  /// - Parameter descriptor: Message descriptor defining the message structure.
  /// - Returns: A new empty `DynamicMessage`.
  public func createMessage(from descriptor: MessageDescriptor) -> DynamicMessage {
    DynamicMessage(impl: backing.createMessage(from: _MessageDescriptor(from: descriptor)))
  }

  /// Creates a message from the given descriptor and populates it with the supplied field values (by name).
  ///
  /// - Parameters:
  ///   - descriptor: Message descriptor.
  ///   - fieldValues: Field values keyed by field name.
  /// - Returns: A populated `DynamicMessage`.
  /// - Throws: `DynamicMessageError` if any field is not found or type-mismatched.
  public func createMessage(from descriptor: MessageDescriptor, with fieldValues: [String: Any]) throws
    -> DynamicMessage
  {
    var message = DynamicMessage(descriptor: descriptor)
    for (fieldName, value) in fieldValues {
      try message.set(value, forField: fieldName)
    }
    return message
  }

  /// Creates a message from the given descriptor and populates it with the supplied field values (by number).
  ///
  /// - Parameters:
  ///   - descriptor: Message descriptor.
  ///   - fieldValues: Field values keyed by field number.
  /// - Returns: A populated `DynamicMessage`.
  /// - Throws: `DynamicMessageError` if any field is not found or type-mismatched.
  public func createMessage(from descriptor: MessageDescriptor, with fieldValues: [Int: Any]) throws -> DynamicMessage {
    var message = DynamicMessage(descriptor: descriptor)
    for (fieldNumber, value) in fieldValues {
      try message.set(value, forField: fieldNumber)
    }
    return message
  }

  /// Returns a deep copy of the given message.
  ///
  /// - Parameter message: Message to clone.
  /// - Returns: A new `DynamicMessage` with copies of all field values.
  /// - Throws: `DynamicMessageError` if any field cannot be cloned.
  public func clone(_ message: DynamicMessage) throws -> DynamicMessage {
    try DynamicMessage(impl: backing.clone(message.impl))
  }

  /// Validates a dynamic message against its descriptor rules.
  ///
  /// - Parameter message: Message to validate.
  /// - Returns: Validation result containing any errors found.
  public func validate(_ message: DynamicMessage) -> ValidationResult {
    backing.validate(message.impl)
  }
}

// MARK: - ValidationResult

/// Message validation result.
public struct ValidationResult {
  /// Whether the message is valid (no errors).
  public let isValid: Bool
  /// List of validation errors; empty when `isValid` is `true`.
  public let errors: [ValidationError]

  /// Creates a new `ValidationResult`.
  ///
  /// - Parameters:
  ///   - isValid: Whether the message passed validation.
  ///   - errors: Errors found during validation.
  public init(isValid: Bool, errors: [ValidationError]) {
    self.isValid = isValid
    self.errors = errors
  }
}

// MARK: - ValidationError

/// Message validation error types.
public enum ValidationError: Error, Equatable {
  /// A required field (proto2) has no value.
  case missingRequiredField(fieldName: String)
  /// A nested message field failed validation.
  case nestedMessageValidationFailed(fieldName: String, nestedErrors: [ValidationError])
  /// An element of a repeated message field failed validation.
  case repeatedFieldValidationFailed(fieldName: String, index: Int, nestedErrors: [ValidationError])
  /// A value of a map message field failed validation.
  case mapFieldValidationFailed(fieldName: String, key: String, nestedErrors: [ValidationError])
  /// An unexpected error occurred while validating a field.
  case validationError(fieldName: String, error: Error)

  /// Returns `true` if both errors represent the same failure.
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
      return lhsField == rhsField
    default:
      return false
    }
  }
}

extension ValidationError: LocalizedError {
  /// Human-readable description of the validation error.
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

// MARK: - FieldAccessor

/// Provides type-safe and convenient interface for accessing fields
/// of dynamic Protocol Buffers messages.
public struct FieldAccessor {
  private let impl: _FieldAccessor

  /// Creates a new FieldAccessor instance for the given message.
  public init(_ message: DynamicMessage) {
    self.impl = _FieldAccessor(message.impl)
  }

  /// Returns the string value of a field by name, or `nil` if unset or wrong type.
  public func getString(_ fieldName: String) -> String? { impl.getString(fieldName) }
  /// Returns the string value of a field by number, or `nil` if unset or wrong type.
  public func getString(_ fieldNumber: Int) -> String? { impl.getString(fieldNumber) }
  /// Returns the Int32 value of a field by name, or `nil` if unset or wrong type.
  public func getInt32(_ fieldName: String) -> Int32? { impl.getInt32(fieldName) }
  /// Returns the Int32 value of a field by number, or `nil` if unset or wrong type.
  public func getInt32(_ fieldNumber: Int) -> Int32? { impl.getInt32(fieldNumber) }
  /// Returns the Int64 value of a field by name, or `nil` if unset or wrong type.
  public func getInt64(_ fieldName: String) -> Int64? { impl.getInt64(fieldName) }
  /// Returns the Int64 value of a field by number, or `nil` if unset or wrong type.
  public func getInt64(_ fieldNumber: Int) -> Int64? { impl.getInt64(fieldNumber) }
  /// Returns the UInt32 value of a field by name, or `nil` if unset or wrong type.
  public func getUInt32(_ fieldName: String) -> UInt32? { impl.getUInt32(fieldName) }
  /// Returns the UInt32 value of a field by number, or `nil` if unset or wrong type.
  public func getUInt32(_ fieldNumber: Int) -> UInt32? { impl.getUInt32(fieldNumber) }
  /// Returns the UInt64 value of a field by name, or `nil` if unset or wrong type.
  public func getUInt64(_ fieldName: String) -> UInt64? { impl.getUInt64(fieldName) }
  /// Returns the UInt64 value of a field by number, or `nil` if unset or wrong type.
  public func getUInt64(_ fieldNumber: Int) -> UInt64? { impl.getUInt64(fieldNumber) }
  /// Returns the Float value of a field by name, or `nil` if unset or wrong type.
  public func getFloat(_ fieldName: String) -> Float? { impl.getFloat(fieldName) }
  /// Returns the Float value of a field by number, or `nil` if unset or wrong type.
  public func getFloat(_ fieldNumber: Int) -> Float? { impl.getFloat(fieldNumber) }
  /// Returns the Double value of a field by name, or `nil` if unset or wrong type.
  public func getDouble(_ fieldName: String) -> Double? { impl.getDouble(fieldName) }
  /// Returns the Double value of a field by number, or `nil` if unset or wrong type.
  public func getDouble(_ fieldNumber: Int) -> Double? { impl.getDouble(fieldNumber) }
  /// Returns the Bool value of a field by name, or `nil` if unset or wrong type.
  public func getBool(_ fieldName: String) -> Bool? { impl.getBool(fieldName) }
  /// Returns the Bool value of a field by number, or `nil` if unset or wrong type.
  public func getBool(_ fieldNumber: Int) -> Bool? { impl.getBool(fieldNumber) }
  /// Returns the Data value of a field by name, or `nil` if unset or wrong type.
  public func getData(_ fieldName: String) -> Data? { impl.getData(fieldName) }
  /// Returns the Data value of a field by number, or `nil` if unset or wrong type.
  public func getData(_ fieldNumber: Int) -> Data? { impl.getData(fieldNumber) }

  /// Returns the nested `DynamicMessage` value of a field by name, or `nil` if unset or wrong type.
  public func getMessage(_ fieldName: String) -> DynamicMessage? {
    impl.getMessage(fieldName).map { DynamicMessage(impl: $0) }
  }

  /// Returns the nested `DynamicMessage` value of a field by number, or `nil` if unset or wrong type.
  public func getMessage(_ fieldNumber: Int) -> DynamicMessage? {
    impl.getMessage(fieldNumber).map { DynamicMessage(impl: $0) }
  }

  /// Returns the repeated String array of a field by name, or `nil` if unset or wrong type.
  public func getStringArray(_ fieldName: String) -> [String]? { impl.getStringArray(fieldName) }
  /// Returns the repeated String array of a field by number, or `nil` if unset or wrong type.
  public func getStringArray(_ fieldNumber: Int) -> [String]? { impl.getStringArray(fieldNumber) }
  /// Returns the repeated Int32 array of a field by name, or `nil` if unset or wrong type.
  public func getInt32Array(_ fieldName: String) -> [Int32]? { impl.getInt32Array(fieldName) }
  /// Returns the repeated Int32 array of a field by number, or `nil` if unset or wrong type.
  public func getInt32Array(_ fieldNumber: Int) -> [Int32]? { impl.getInt32Array(fieldNumber) }
  /// Returns the repeated Int64 array of a field by name, or `nil` if unset or wrong type.
  public func getInt64Array(_ fieldName: String) -> [Int64]? { impl.getInt64Array(fieldName) }
  /// Returns the repeated Int64 array of a field by number, or `nil` if unset or wrong type.
  public func getInt64Array(_ fieldNumber: Int) -> [Int64]? { impl.getInt64Array(fieldNumber) }

  /// Returns the repeated message array of a field by name, or `nil` if unset or wrong type.
  public func getMessageArray(_ fieldName: String) -> [DynamicMessage]? {
    impl.getMessageArray(fieldName).map { $0.map { DynamicMessage(impl: $0) } }
  }

  /// Returns the repeated message array of a field by number, or `nil` if unset or wrong type.
  public func getMessageArray(_ fieldNumber: Int) -> [DynamicMessage]? {
    impl.getMessageArray(fieldNumber).map { $0.map { DynamicMessage(impl: $0) } }
  }

  /// Returns the `[String: String]` map of a field by name, or `nil` if unset or wrong type.
  public func getStringMap(_ fieldName: String) -> [String: String]? { impl.getStringMap(fieldName) }
  /// Returns the `[String: String]` map of a field by number, or `nil` if unset or wrong type.
  public func getStringMap(_ fieldNumber: Int) -> [String: String]? { impl.getStringMap(fieldNumber) }
  /// Returns the `[String: Int32]` map of a field by name, or `nil` if unset or wrong type.
  public func getStringToInt32Map(_ fieldName: String) -> [String: Int32]? {
    impl.getStringToInt32Map(fieldName)
  }
  /// Returns the `[String: Int32]` map of a field by number, or `nil` if unset or wrong type.
  public func getStringToInt32Map(_ fieldNumber: Int) -> [String: Int32]? {
    impl.getStringToInt32Map(fieldNumber)
  }

  /// Returns the `[String: DynamicMessage]` map of a field by name, or `nil` if unset or wrong type.
  public func getStringToMessageMap(_ fieldName: String) -> [String: DynamicMessage]? {
    impl.getStringToMessageMap(fieldName).map { $0.mapValues { DynamicMessage(impl: $0) } }
  }

  /// Returns the `[String: DynamicMessage]` map of a field by number, or `nil` if unset or wrong type.
  public func getStringToMessageMap(_ fieldNumber: Int) -> [String: DynamicMessage]? {
    impl.getStringToMessageMap(fieldNumber).map { $0.mapValues { DynamicMessage(impl: $0) } }
  }

  /// Returns `true` if the field identified by name has a value set.
  public func hasValue(_ fieldName: String) -> Bool { impl.hasValue(fieldName) }
  /// Returns `true` if the field identified by number has a value set.
  public func hasValue(_ fieldNumber: Int) -> Bool { impl.hasValue(fieldNumber) }
  /// Returns `true` if the field identified by name exists in the descriptor.
  public func fieldExists(_ fieldName: String) -> Bool { impl.fieldExists(fieldName) }
  /// Returns `true` if the field identified by number exists in the descriptor.
  public func fieldExists(_ fieldNumber: Int) -> Bool { impl.fieldExists(fieldNumber) }

  /// Returns the declared `FieldType` of a field by name, or `nil` if not found.
  public func getFieldType(_ fieldName: String) -> FieldType? {
    impl.getFieldType(fieldName).map { FieldType(from: $0) }
  }

  /// Returns the declared `FieldType` of a field by number, or `nil` if not found.
  public func getFieldType(_ fieldNumber: Int) -> FieldType? {
    impl.getFieldType(fieldNumber).map { FieldType(from: $0) }
  }

  /// Returns the field value cast to the given type by name, or `nil` if not found or type mismatch.
  public func getValue<T>(_ fieldName: String, as type: T.Type) -> T? {
    if type == DynamicMessage.self {
      return getMessage(fieldName) as? T
    }
    return impl.getValue(fieldName, as: type)
  }

  /// Returns the field value cast to the given type by number, or `nil` if not found or type mismatch.
  public func getValue<T>(_ fieldNumber: Int, as type: T.Type) -> T? {
    if type == DynamicMessage.self {
      return getMessage(fieldNumber) as? T
    }
    return impl.getValue(fieldNumber, as: type)
  }
}

// MARK: - MutableFieldAccessor

/// Mutable access to dynamic message fields with soft failure (returns Bool).
public struct MutableFieldAccessor {
  private var impl: _MutableFieldAccessor

  /// Creates a `MutableFieldAccessor` that mutates the given message in place.
  ///
  /// - Parameter message: The message to mutate.
  public init(_ message: inout DynamicMessage) {
    impl = _MutableFieldAccessor(&message.impl)
  }

  /// Sets a string value for the field identified by name; returns `false` on failure.
  @discardableResult
  public mutating func setString(_ value: String, forField fieldName: String) -> Bool {
    impl.setString(value, forField: fieldName)
  }

  /// Sets a string value for the field identified by number; returns `false` on failure.
  @discardableResult
  public mutating func setString(_ value: String, forField fieldNumber: Int) -> Bool {
    impl.setString(value, forField: fieldNumber)
  }

  /// Sets an Int32 value for the field identified by name; returns `false` on failure.
  @discardableResult
  public mutating func setInt32(_ value: Int32, forField fieldName: String) -> Bool {
    impl.setInt32(value, forField: fieldName)
  }

  /// Sets an Int32 value for the field identified by number; returns `false` on failure.
  @discardableResult
  public mutating func setInt32(_ value: Int32, forField fieldNumber: Int) -> Bool {
    impl.setInt32(value, forField: fieldNumber)
  }

  /// Sets a Bool value for the field identified by name; returns `false` on failure.
  @discardableResult
  public mutating func setBool(_ value: Bool, forField fieldName: String) -> Bool {
    impl.setBool(value, forField: fieldName)
  }

  /// Sets a Bool value for the field identified by number; returns `false` on failure.
  @discardableResult
  public mutating func setBool(_ value: Bool, forField fieldNumber: Int) -> Bool {
    impl.setBool(value, forField: fieldNumber)
  }

  /// Sets a nested message value for the field identified by name; returns `false` on failure.
  @discardableResult
  public mutating func setMessage(_ value: DynamicMessage, forField fieldName: String) -> Bool {
    impl.setMessage(value.impl, forField: fieldName)
  }

  /// Sets a nested message value for the field identified by number; returns `false` on failure.
  @discardableResult
  public mutating func setMessage(_ value: DynamicMessage, forField fieldNumber: Int) -> Bool {
    impl.setMessage(value.impl, forField: fieldNumber)
  }

  /// Returns the message with all mutations applied.
  public func updatedMessage() -> DynamicMessage {
    DynamicMessage(impl: impl.updatedMessage())
  }
}

extension DynamicMessage {
  /// Creates FieldAccessor for reading fields of this message.
  public var fieldAccessor: FieldAccessor {
    FieldAccessor(self)
  }

  /// Creates MutableFieldAccessor for modifying fields of this message.
  public mutating func mutableFieldAccessor() -> MutableFieldAccessor {
    MutableFieldAccessor(&self)
  }
}
