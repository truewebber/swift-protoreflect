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
  case fieldNotFound(fieldName: String)
  case fieldNotFoundByNumber(fieldNumber: Int)
  case typeMismatch(fieldName: String, expectedType: String, actualType: String)
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

  @discardableResult
  public mutating func set(_ value: Any, forField fieldName: String) throws -> Self {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }
    return try set(value, forField: field.number)
  }

  @discardableResult
  public mutating func set(_ value: Any, forField fieldNumber: Int) throws -> Self {
    let wrapped = try Self.wrapAnyForImpl(value)
    try impl.set(wrapped, forField: fieldNumber)
    return self
  }

  public func get(forField fieldName: String) throws -> Any? {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }
    return try get(forField: field.number)
  }

  public func get(forField fieldNumber: Int) throws -> Any? {
    guard let raw = try impl.get(forField: fieldNumber) else {
      return nil
    }
    return Self.unwrapAnyFromImpl(raw)
  }

  public func hasValue(forField fieldName: String) throws -> Bool {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }
    return try impl.hasValue(forField: field.number)
  }

  public func hasValue(forField fieldNumber: Int) throws -> Bool {
    try impl.hasValue(forField: fieldNumber)
  }

  @discardableResult
  public mutating func clearField(_ fieldName: String) throws -> Self {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }
    try impl.clearField(field.number)
    return self
  }

  @discardableResult
  public mutating func clearField(_ fieldNumber: Int) throws -> Self {
    try impl.clearField(fieldNumber)
    return self
  }

  public mutating func setUnknownFields(_ data: Data) {
    impl.setUnknownFields(data)
  }

  @discardableResult
  public mutating func addRepeatedValue(_ value: Any, forField fieldName: String) throws -> Self {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }
    return try addRepeatedValue(value, forField: field.number)
  }

  @discardableResult
  public mutating func addRepeatedValue(_ value: Any, forField fieldNumber: Int) throws -> Self {
    let wrapped = try Self.wrapAnyForImpl(value)
    try impl.addRepeatedValue(wrapped, forField: fieldNumber)
    return self
  }

  @discardableResult
  public mutating func setMapEntry(_ value: Any, forKey key: AnyHashable, inField fieldName: String) throws -> Self {
    guard let field = descriptor.field(named: fieldName) else {
      throw DynamicMessageError.fieldNotFound(fieldName: fieldName)
    }
    return try setMapEntry(value, forKey: key, inField: field.number)
  }

  @discardableResult
  public mutating func setMapEntry(_ value: Any, forKey key: AnyHashable, inField fieldNumber: Int) throws -> Self {
    let wrapped = try Self.wrapAnyForImpl(value)
    try impl.setMapEntry(wrapped, forKey: key, inField: fieldNumber)
    return self
  }

  public static func == (lhs: DynamicMessage, rhs: DynamicMessage) -> Bool {
    lhs.impl == rhs.impl
  }
}

// MARK: - MessageFactory

/// Factory for creating and managing dynamic Protocol Buffers messages.
public struct MessageFactory: Sendable {

  public init() {}

  private let backing = _MessageFactory()

  public func createMessage(from descriptor: MessageDescriptor) -> DynamicMessage {
    DynamicMessage(impl: backing.createMessage(from: _MessageDescriptor(from: descriptor)))
  }

  public func createMessage(from descriptor: MessageDescriptor, with fieldValues: [String: Any]) throws
    -> DynamicMessage
  {
    var message = DynamicMessage(descriptor: descriptor)
    for (fieldName, value) in fieldValues {
      try message.set(value, forField: fieldName)
    }
    return message
  }

  public func createMessage(from descriptor: MessageDescriptor, with fieldValues: [Int: Any]) throws -> DynamicMessage {
    var message = DynamicMessage(descriptor: descriptor)
    for (fieldNumber, value) in fieldValues {
      try message.set(value, forField: fieldNumber)
    }
    return message
  }

  public func clone(_ message: DynamicMessage) throws -> DynamicMessage {
    try DynamicMessage(impl: backing.clone(message.impl))
  }

  public func validate(_ message: DynamicMessage) -> ValidationResult {
    backing.validate(message.impl)
  }

  @available(*, deprecated, message: "Use validate(_:) instead; syntax is now read from descriptor.syntax")
  public func validate(_ message: DynamicMessage, syntax: String) -> ValidationResult {
    backing.validate(message.impl, syntax: syntax)
  }
}

// MARK: - ValidationResult

/// Message validation result.
public struct ValidationResult {
  public let isValid: Bool
  public let errors: [ValidationError]

  public init(isValid: Bool, errors: [ValidationError]) {
    self.isValid = isValid
    self.errors = errors
  }
}

// MARK: - ValidationError

/// Message validation error types.
public enum ValidationError: Error, Equatable {
  case missingRequiredField(fieldName: String)
  case nestedMessageValidationFailed(fieldName: String, nestedErrors: [ValidationError])
  case repeatedFieldValidationFailed(fieldName: String, index: Int, nestedErrors: [ValidationError])
  case mapFieldValidationFailed(fieldName: String, key: String, nestedErrors: [ValidationError])
  case validationError(fieldName: String, error: Error)

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

  public func getString(_ fieldName: String) -> String? { impl.getString(fieldName) }
  public func getString(_ fieldNumber: Int) -> String? { impl.getString(fieldNumber) }
  public func getInt32(_ fieldName: String) -> Int32? { impl.getInt32(fieldName) }
  public func getInt32(_ fieldNumber: Int) -> Int32? { impl.getInt32(fieldNumber) }
  public func getInt64(_ fieldName: String) -> Int64? { impl.getInt64(fieldName) }
  public func getInt64(_ fieldNumber: Int) -> Int64? { impl.getInt64(fieldNumber) }
  public func getUInt32(_ fieldName: String) -> UInt32? { impl.getUInt32(fieldName) }
  public func getUInt32(_ fieldNumber: Int) -> UInt32? { impl.getUInt32(fieldNumber) }
  public func getUInt64(_ fieldName: String) -> UInt64? { impl.getUInt64(fieldName) }
  public func getUInt64(_ fieldNumber: Int) -> UInt64? { impl.getUInt64(fieldNumber) }
  public func getFloat(_ fieldName: String) -> Float? { impl.getFloat(fieldName) }
  public func getFloat(_ fieldNumber: Int) -> Float? { impl.getFloat(fieldNumber) }
  public func getDouble(_ fieldName: String) -> Double? { impl.getDouble(fieldName) }
  public func getDouble(_ fieldNumber: Int) -> Double? { impl.getDouble(fieldNumber) }
  public func getBool(_ fieldName: String) -> Bool? { impl.getBool(fieldName) }
  public func getBool(_ fieldNumber: Int) -> Bool? { impl.getBool(fieldNumber) }
  public func getData(_ fieldName: String) -> Data? { impl.getData(fieldName) }
  public func getData(_ fieldNumber: Int) -> Data? { impl.getData(fieldNumber) }

  public func getMessage(_ fieldName: String) -> DynamicMessage? {
    impl.getMessage(fieldName).map { DynamicMessage(impl: $0) }
  }

  public func getMessage(_ fieldNumber: Int) -> DynamicMessage? {
    impl.getMessage(fieldNumber).map { DynamicMessage(impl: $0) }
  }

  public func getStringArray(_ fieldName: String) -> [String]? { impl.getStringArray(fieldName) }
  public func getStringArray(_ fieldNumber: Int) -> [String]? { impl.getStringArray(fieldNumber) }
  public func getInt32Array(_ fieldName: String) -> [Int32]? { impl.getInt32Array(fieldName) }
  public func getInt32Array(_ fieldNumber: Int) -> [Int32]? { impl.getInt32Array(fieldNumber) }
  public func getInt64Array(_ fieldName: String) -> [Int64]? { impl.getInt64Array(fieldName) }
  public func getInt64Array(_ fieldNumber: Int) -> [Int64]? { impl.getInt64Array(fieldNumber) }

  public func getMessageArray(_ fieldName: String) -> [DynamicMessage]? {
    impl.getMessageArray(fieldName).map { $0.map { DynamicMessage(impl: $0) } }
  }

  public func getMessageArray(_ fieldNumber: Int) -> [DynamicMessage]? {
    impl.getMessageArray(fieldNumber).map { $0.map { DynamicMessage(impl: $0) } }
  }

  public func getStringMap(_ fieldName: String) -> [String: String]? { impl.getStringMap(fieldName) }
  public func getStringMap(_ fieldNumber: Int) -> [String: String]? { impl.getStringMap(fieldNumber) }
  public func getStringToInt32Map(_ fieldName: String) -> [String: Int32]? {
    impl.getStringToInt32Map(fieldName)
  }
  public func getStringToInt32Map(_ fieldNumber: Int) -> [String: Int32]? {
    impl.getStringToInt32Map(fieldNumber)
  }

  public func getStringToMessageMap(_ fieldName: String) -> [String: DynamicMessage]? {
    impl.getStringToMessageMap(fieldName).map { $0.mapValues { DynamicMessage(impl: $0) } }
  }

  public func getStringToMessageMap(_ fieldNumber: Int) -> [String: DynamicMessage]? {
    impl.getStringToMessageMap(fieldNumber).map { $0.mapValues { DynamicMessage(impl: $0) } }
  }

  public func hasValue(_ fieldName: String) -> Bool { impl.hasValue(fieldName) }
  public func hasValue(_ fieldNumber: Int) -> Bool { impl.hasValue(fieldNumber) }
  public func fieldExists(_ fieldName: String) -> Bool { impl.fieldExists(fieldName) }
  public func fieldExists(_ fieldNumber: Int) -> Bool { impl.fieldExists(fieldNumber) }

  public func getFieldType(_ fieldName: String) -> FieldType? {
    impl.getFieldType(fieldName).map { FieldType(from: $0) }
  }

  public func getFieldType(_ fieldNumber: Int) -> FieldType? {
    impl.getFieldType(fieldNumber).map { FieldType(from: $0) }
  }

  public func getValue<T>(_ fieldName: String, as type: T.Type) -> T? {
    if type == DynamicMessage.self {
      return getMessage(fieldName) as? T
    }
    return impl.getValue(fieldName, as: type)
  }

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

  public init(_ message: inout DynamicMessage) {
    impl = _MutableFieldAccessor(&message.impl)
  }

  @discardableResult
  public mutating func setString(_ value: String, forField fieldName: String) -> Bool {
    impl.setString(value, forField: fieldName)
  }

  @discardableResult
  public mutating func setString(_ value: String, forField fieldNumber: Int) -> Bool {
    impl.setString(value, forField: fieldNumber)
  }

  @discardableResult
  public mutating func setInt32(_ value: Int32, forField fieldName: String) -> Bool {
    impl.setInt32(value, forField: fieldName)
  }

  @discardableResult
  public mutating func setInt32(_ value: Int32, forField fieldNumber: Int) -> Bool {
    impl.setInt32(value, forField: fieldNumber)
  }

  @discardableResult
  public mutating func setBool(_ value: Bool, forField fieldName: String) -> Bool {
    impl.setBool(value, forField: fieldName)
  }

  @discardableResult
  public mutating func setBool(_ value: Bool, forField fieldNumber: Int) -> Bool {
    impl.setBool(value, forField: fieldNumber)
  }

  @discardableResult
  public mutating func setMessage(_ value: DynamicMessage, forField fieldName: String) -> Bool {
    impl.setMessage(value.impl, forField: fieldName)
  }

  @discardableResult
  public mutating func setMessage(_ value: DynamicMessage, forField fieldNumber: Int) -> Bool {
    impl.setMessage(value.impl, forField: fieldNumber)
  }

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
