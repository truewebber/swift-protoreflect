//
// WellKnownTypeHandlers.swift (public API)
// SwiftProtoReflect
//
// All well-known type handlers, their value types, and convenience extensions.
//

import Foundation
import SwiftProtobuf

// MARK: - StructProtoDescriptors

/// Shared factory that provides correctly structured descriptors for all four types
/// defined in `google/protobuf/struct.proto`: `Struct`, `Value`, `ListValue`, and
/// the `NullValue` enum.
///
/// All descriptors are built once and cached via `static let`, making the factory
/// thread-safe without any locking. The descriptors are value types (`struct`/`enum`)
/// so they are inherently safe to share across threads.
///
/// The factory resolves the mutual-dependency problem between the four types
/// (Value references Struct and ListValue; Struct references Value; ListValue
/// references Value) by placing all four in a single `FileDescriptor`.
public enum StructProtoDescriptors {

  // MARK: - Shared FileDescriptor

  /// The `FileDescriptor` that contains all four struct.proto types.
  ///
  /// Name: `"google/protobuf/struct.proto"`, package: `"google.protobuf"`.
  public static let fileDescriptor: FileDescriptor = _buildFileDescriptor()

  // MARK: - Message Descriptors

  /// Descriptor for `google.protobuf.Struct`.
  ///
  /// Contains one map field:
  /// - `fields` (field 1): `map<string, google.protobuf.Value>`
  ///
  /// Also contains a nested `FieldsEntry` message for schema completeness.
  public static let structDescriptor: MessageDescriptor = fileDescriptor.messages["Struct"]!

  /// Descriptor for `google.protobuf.Value`.
  ///
  /// Contains a single `kind` oneof with six alternatives at field numbers 1–6:
  /// `null_value`, `number_value`, `string_value`, `bool_value`, `struct_value`, `list_value`.
  public static let valueDescriptor: MessageDescriptor = fileDescriptor.messages["Value"]!

  /// Descriptor for `google.protobuf.ListValue`.
  ///
  /// Contains one repeated field:
  /// - `values` (field 1): `repeated google.protobuf.Value`
  public static let listValueDescriptor: MessageDescriptor = fileDescriptor.messages["ListValue"]!

  // MARK: - Enum Descriptors

  /// Descriptor for the `google.protobuf.NullValue` enum.
  ///
  /// Contains a single value: `NULL_VALUE = 0`.
  public static let nullValueEnum: EnumDescriptor = fileDescriptor.enums["NullValue"]!

  // MARK: - Private Builder

  private static func _buildFileDescriptor() -> FileDescriptor {
    var file = FileDescriptor(
      name: "google/protobuf/struct.proto",
      package: "google.protobuf"
    )

    file.addEnum(_buildNullValueEnum(parent: file))
    file.addMessage(_buildStructMessage(parent: file))
    file.addMessage(_buildValueMessage(parent: file))
    file.addMessage(_buildListValueMessage(parent: file))

    return file
  }

  private static func _buildNullValueEnum(parent: FileDescriptor) -> EnumDescriptor {
    var nullValueEnum = EnumDescriptor(name: "NullValue", parent: parent)
    nullValueEnum.addValue(EnumDescriptor.EnumValue(name: "NULL_VALUE", number: 0))
    return nullValueEnum
  }

  private static func _buildStructMessage(parent: FileDescriptor) -> MessageDescriptor {
    var structMsg = MessageDescriptor(name: "Struct", parent: parent)

    var fieldsEntry = MessageDescriptor(name: "FieldsEntry", parent: structMsg)
    fieldsEntry.addField(
      FieldDescriptor(name: "key", number: 1, type: .string)
    )
    fieldsEntry.addField(
      FieldDescriptor(
        name: "value",
        number: 2,
        type: .message,
        typeName: "google.protobuf.Value"
      )
    )
    structMsg.addNestedMessage(fieldsEntry)

    structMsg.addField(
      FieldDescriptor(
        name: "fields",
        number: 1,
        type: .message,
        typeName: "google.protobuf.Struct.FieldsEntry",
        isMap: true,
        mapEntryInfo: MapEntryInfo(
          keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
          valueFieldInfo: ValueFieldInfo(
            name: "value",
            number: 2,
            type: .message,
            typeName: "google.protobuf.Value"
          )
        )
      )
    )

    return structMsg
  }

  private static func _buildValueMessage(parent: FileDescriptor) -> MessageDescriptor {
    var valueMsg = MessageDescriptor(name: "Value", parent: parent)

    let kindOneof = OneofDescriptor(name: "kind", index: 0)
    valueMsg.addOneofDecl(kindOneof)

    valueMsg.addField(
      FieldDescriptor(
        name: "null_value",
        number: 1,
        type: .enum,
        typeName: "google.protobuf.NullValue",
        oneofIndex: 0
      )
    )
    valueMsg.addField(
      FieldDescriptor(name: "number_value", number: 2, type: .double, oneofIndex: 0)
    )
    valueMsg.addField(
      FieldDescriptor(name: "string_value", number: 3, type: .string, oneofIndex: 0)
    )
    valueMsg.addField(
      FieldDescriptor(name: "bool_value", number: 4, type: .bool, oneofIndex: 0)
    )
    valueMsg.addField(
      FieldDescriptor(
        name: "struct_value",
        number: 5,
        type: .message,
        typeName: "google.protobuf.Struct",
        oneofIndex: 0
      )
    )
    valueMsg.addField(
      FieldDescriptor(
        name: "list_value",
        number: 6,
        type: .message,
        typeName: "google.protobuf.ListValue",
        oneofIndex: 0
      )
    )

    return valueMsg
  }

  private static func _buildListValueMessage(parent: FileDescriptor) -> MessageDescriptor {
    var listValueMsg = MessageDescriptor(name: "ListValue", parent: parent)

    listValueMsg.addField(
      FieldDescriptor(
        name: "values",
        number: 1,
        type: .message,
        typeName: "google.protobuf.Value",
        isRepeated: true
      )
    )

    return listValueMsg
  }
}

// MARK: - TimestampHandler

/// Handler for google.protobuf.Timestamp.
public struct TimestampHandler: WellKnownTypeHandler {

  public static let handledTypeName = WellKnownTypeNames.timestamp
  public static let supportPhase: WellKnownSupportPhase = .critical

  // MARK: - Timestamp Representation

  /// Specialized representation of Timestamp.
  public struct TimestampValue: Equatable, CustomStringConvertible {

    /// Seconds of UTC time since Unix epoch (1970-01-01T00:00:00Z).
    public let seconds: Int64

    /// Non-negative fractions of a second at nanosecond resolution.
    public let nanos: Int32

    /// Initialization with seconds and nanoseconds.
    /// - Parameters:
    ///   - seconds: Seconds since Unix epoch.
    ///   - nanos: Nanoseconds (0-999999999).
    /// - Throws: WellKnownTypeError if values are invalid.
    public init(seconds: Int64, nanos: Int32) throws {
      guard Self.isValidNanos(nanos) else {
        throw WellKnownTypeError.invalidData(
          typeName: WellKnownTypeNames.timestamp,
          reason: "nanos must be in range [0, 999999999], got \(nanos)"
        )
      }

      guard Self.isValidSeconds(seconds) else {
        throw WellKnownTypeError.invalidData(
          typeName: WellKnownTypeNames.timestamp,
          reason: "seconds out of valid range: \(seconds)"
        )
      }

      self.seconds = seconds
      self.nanos = nanos
    }

    /// Initialization from Date.
    /// - Parameter date: Foundation Date.
    public init(from date: Date) {
      let timeInterval = date.timeIntervalSince1970
      self.seconds = Int64(timeInterval)
      self.nanos = Int32((timeInterval - Double(self.seconds)) * 1_000_000_000)
    }

    /// Conversion to Date.
    /// - Returns: Foundation Date.
    public func toDate() -> Date {
      let timeInterval = Double(seconds) + Double(nanos) / 1_000_000_000.0
      return Date(timeIntervalSince1970: timeInterval)
    }

    /// Current time.
    /// - Returns: TimestampValue with current time.
    public static func now() -> TimestampValue {
      return TimestampValue(from: Date())
    }

    public var description: String {
      let date = toDate()

      #if canImport(Foundation) && !os(Linux)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
      #else
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
      #endif
    }

    // MARK: - Validation

    /// Validates nanoseconds.
    internal static func isValidNanos(_ nanos: Int32) -> Bool {
      return nanos >= 0 && nanos <= 999_999_999
    }

    /// Validates seconds (within reasonable bounds).
    internal static func isValidSeconds(_ seconds: Int64) -> Bool {
      return seconds >= -9_223_372_036 && seconds <= 253_402_300_799
    }
  }

  // MARK: - Handler Implementation

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    guard message.descriptor.fullName == handledTypeName else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Expected \(handledTypeName), got \(message.descriptor.fullName)"
      )
    }

    let secondsValue: Int64
    let nanosValue: Int32

    do {
      if try message.hasValue(forField: "seconds") {
        if let value = try message.get(forField: "seconds") as? Int64 {
          secondsValue = value
        }
        else {
          secondsValue = 0
        }
      }
      else {
        secondsValue = 0
      }

      if try message.hasValue(forField: "nanos") {
        if let value = try message.get(forField: "nanos") as? Int32 {
          nanosValue = value
        }
        else {
          nanosValue = 0
        }
      }
      else {
        nanosValue = 0
      }
    }
    catch {
      throw WellKnownTypeError.conversionFailed(
        from: "DynamicMessage",
        to: "TimestampValue",
        reason: "Failed to extract fields: \(error.localizedDescription)"
      )
    }

    return try TimestampValue(seconds: secondsValue, nanos: nanosValue)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    guard let timestampValue = specialized as? TimestampValue else {
      throw WellKnownTypeError.conversionFailed(
        from: String(describing: type(of: specialized)),
        to: "DynamicMessage",
        reason: "Expected TimestampValue"
      )
    }

    let timestampDescriptor = _createTimestampDescriptor()
    let factory = MessageFactory()
    var message = factory.createMessage(from: timestampDescriptor)

    try message.set(timestampValue.seconds, forField: "seconds")
    try message.set(timestampValue.nanos, forField: "nanos")

    return message
  }

  public static func validate(_ specialized: Any) -> Bool {
    guard let timestampValue = specialized as? TimestampValue else {
      return false
    }

    return TimestampValue.isValidNanos(timestampValue.nanos)
      && TimestampValue.isValidSeconds(timestampValue.seconds)
  }

  private static func _createTimestampDescriptor() -> MessageDescriptor {
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/timestamp.proto",
      package: "google.protobuf"
    )

    var messageDescriptor = MessageDescriptor(
      name: "Timestamp",
      parent: fileDescriptor
    )

    messageDescriptor.addField(FieldDescriptor(name: "seconds", number: 1, type: .int64))
    messageDescriptor.addField(FieldDescriptor(name: "nanos", number: 2, type: .int32))
    fileDescriptor.addMessage(messageDescriptor)

    return messageDescriptor
  }
}

// MARK: - TimestampHandler Convenience Extensions

extension Date {

  /// Creates Date from TimestampValue.
  /// - Parameter timestamp: TimestampValue.
  /// - Returns: Date.
  public init(from timestamp: TimestampHandler.TimestampValue) {
    self = timestamp.toDate()
  }

  /// Converts Date to TimestampValue.
  /// - Returns: TimestampValue.
  public func toTimestampValue() -> TimestampHandler.TimestampValue {
    return TimestampHandler.TimestampValue(from: self)
  }
}

extension DynamicMessage {

  /// Creates DynamicMessage from Date for google.protobuf.Timestamp.
  /// - Parameter date: Foundation Date.
  /// - Returns: DynamicMessage representing Timestamp.
  /// - Throws: WellKnownTypeError.
  public static func timestampMessage(from date: Date) throws -> DynamicMessage {
    let timestamp = TimestampHandler.TimestampValue(from: date)
    return try TimestampHandler.createDynamic(from: timestamp)
  }

  /// Converts DynamicMessage to Date (if it's Timestamp).
  /// - Returns: Date.
  /// - Throws: WellKnownTypeError if message is not Timestamp.
  public func toDate() throws -> Date {
    guard descriptor.fullName == WellKnownTypeNames.timestamp else {
      throw WellKnownTypeError.invalidData(
        typeName: descriptor.fullName,
        reason: "Message is not a Timestamp"
      )
    }

    let timestamp = try TimestampHandler.createSpecialized(from: self) as! TimestampHandler.TimestampValue
    return timestamp.toDate()
  }
}

// MARK: - DurationHandler

/// Handler for google.protobuf.Duration.
public struct DurationHandler: WellKnownTypeHandler {

  public static let handledTypeName = WellKnownTypeNames.duration
  public static let supportPhase: WellKnownSupportPhase = .critical

  // MARK: - Duration Representation

  /// Specialized representation of Duration.
  public struct DurationValue: Equatable, CustomStringConvertible {

    /// Signed seconds of the span of time.
    public let seconds: Int64

    /// Signed fractions of a second at nanosecond resolution.
    ///
    /// Must be from -999,999,999 to +999,999,999 inclusive.
    public let nanos: Int32

    /// Initialization with seconds and nanoseconds.
    /// - Parameters:
    ///   - seconds: Duration seconds (can be negative).
    ///   - nanos: Nanoseconds (must have same sign as seconds, or be 0).
    /// - Throws: WellKnownTypeError if values are invalid.
    public init(seconds: Int64, nanos: Int32) throws {
      guard Self.isValidNanos(nanos) else {
        throw WellKnownTypeError.invalidData(
          typeName: WellKnownTypeNames.duration,
          reason: "nanos must be in range [-999999999, 999999999], got \(nanos)"
        )
      }

      guard Self.isValidSecondsNanosCombination(seconds: seconds, nanos: nanos) else {
        throw WellKnownTypeError.invalidData(
          typeName: WellKnownTypeNames.duration,
          reason: "seconds and nanos must have the same sign or one of them must be zero"
        )
      }

      self.seconds = seconds
      self.nanos = nanos
    }

    /// Initialization from TimeInterval.
    /// - Parameter timeInterval: Foundation TimeInterval (seconds as Double).
    public init(from timeInterval: TimeInterval) {
      let totalSeconds = timeInterval
      self.seconds = Int64(totalSeconds)

      let fractionalSeconds = totalSeconds - Double(self.seconds)
      self.nanos = Int32(fractionalSeconds * 1_000_000_000)
    }

    /// Conversion to TimeInterval.
    /// - Returns: Foundation TimeInterval.
    public func toTimeInterval() -> TimeInterval {
      return Double(seconds) + Double(nanos) / 1_000_000_000.0
    }

    /// Creates zero duration.
    /// - Returns: DurationValue equal to zero.
    public static func zero() -> DurationValue {
      return try! DurationValue(seconds: 0, nanos: 0)
    }

    /// Absolute value of duration.
    /// - Returns: DurationValue with positive values.
    public func abs() -> DurationValue {
      if seconds < 0 || (seconds == 0 && nanos < 0) {
        return try! DurationValue(seconds: -seconds, nanos: -nanos)
      }
      return self
    }

    /// Negative duration.
    /// - Returns: DurationValue with opposite sign.
    public func negated() -> DurationValue {
      return try! DurationValue(seconds: -seconds, nanos: -nanos)
    }

    public var description: String {
      let totalSeconds = toTimeInterval()
      if totalSeconds == 0 {
        return "0s"
      }
      else if totalSeconds >= 1 || totalSeconds <= -1 {
        return String(format: "%.3fs", totalSeconds)
      }
      else {
        let totalMillis = totalSeconds * 1000
        if Swift.abs(totalMillis) >= 1 {
          return String(format: "%.3fms", totalMillis)
        }
        else {
          return "\(seconds * 1_000_000_000 + Int64(nanos))ns"
        }
      }
    }

    /// Validates nanoseconds.
    internal static func isValidNanos(_ nanos: Int32) -> Bool {
      return nanos >= -999_999_999 && nanos <= 999_999_999
    }

    /// Validates combination of seconds and nanoseconds.
    internal static func isValidSecondsNanosCombination(seconds: Int64, nanos: Int32) -> Bool {
      if seconds == 0 || nanos == 0 {
        return true
      }
      return (seconds > 0 && nanos > 0) || (seconds < 0 && nanos < 0)
    }
  }

  // MARK: - Handler Implementation

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    guard message.descriptor.fullName == handledTypeName else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Expected \(handledTypeName), got \(message.descriptor.fullName)"
      )
    }

    let secondsValue: Int64
    let nanosValue: Int32

    do {
      if try message.hasValue(forField: "seconds") {
        if let value = try message.get(forField: "seconds") as? Int64 {
          secondsValue = value
        }
        else {
          secondsValue = 0
        }
      }
      else {
        secondsValue = 0
      }

      if try message.hasValue(forField: "nanos") {
        if let value = try message.get(forField: "nanos") as? Int32 {
          nanosValue = value
        }
        else {
          nanosValue = 0
        }
      }
      else {
        nanosValue = 0
      }
    }
    catch {
      throw WellKnownTypeError.conversionFailed(
        from: "DynamicMessage",
        to: "DurationValue",
        reason: "Failed to extract fields: \(error.localizedDescription)"
      )
    }

    return try DurationValue(seconds: secondsValue, nanos: nanosValue)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    guard let durationValue = specialized as? DurationValue else {
      throw WellKnownTypeError.conversionFailed(
        from: String(describing: type(of: specialized)),
        to: "DynamicMessage",
        reason: "Expected DurationValue"
      )
    }

    let durationDescriptor = _createDurationDescriptor()
    let factory = MessageFactory()
    var message = factory.createMessage(from: durationDescriptor)

    try message.set(durationValue.seconds, forField: "seconds")
    try message.set(durationValue.nanos, forField: "nanos")

    return message
  }

  public static func validate(_ specialized: Any) -> Bool {
    guard let durationValue = specialized as? DurationValue else {
      return false
    }

    return DurationValue.isValidNanos(durationValue.nanos)
      && DurationValue.isValidSecondsNanosCombination(seconds: durationValue.seconds, nanos: durationValue.nanos)
  }

  private static func _createDurationDescriptor() -> MessageDescriptor {
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/duration.proto",
      package: "google.protobuf"
    )

    var messageDescriptor = MessageDescriptor(
      name: "Duration",
      parent: fileDescriptor
    )

    messageDescriptor.addField(FieldDescriptor(name: "seconds", number: 1, type: .int64))
    messageDescriptor.addField(FieldDescriptor(name: "nanos", number: 2, type: .int32))
    fileDescriptor.addMessage(messageDescriptor)

    return messageDescriptor
  }
}

// MARK: - DurationHandler Convenience Extensions

extension TimeInterval {

  /// Creates TimeInterval from DurationValue.
  /// - Parameter duration: DurationValue.
  /// - Returns: TimeInterval.
  public init(from duration: DurationHandler.DurationValue) {
    self = duration.toTimeInterval()
  }

  /// Converts TimeInterval to DurationValue.
  /// - Returns: DurationValue.
  public func toDurationValue() -> DurationHandler.DurationValue {
    return DurationHandler.DurationValue(from: self)
  }
}

extension DynamicMessage {

  /// Creates DynamicMessage from TimeInterval for google.protobuf.Duration.
  /// - Parameter timeInterval: Foundation TimeInterval.
  /// - Returns: DynamicMessage representing Duration.
  /// - Throws: WellKnownTypeError.
  public static func durationMessage(from timeInterval: TimeInterval) throws -> DynamicMessage {
    let duration = DurationHandler.DurationValue(from: timeInterval)
    return try DurationHandler.createDynamic(from: duration)
  }

  /// Converts DynamicMessage to TimeInterval (if it's Duration).
  /// - Returns: TimeInterval.
  /// - Throws: WellKnownTypeError if message is not Duration.
  public func toTimeInterval() throws -> TimeInterval {
    guard descriptor.fullName == WellKnownTypeNames.duration else {
      throw WellKnownTypeError.invalidData(
        typeName: descriptor.fullName,
        reason: "Message is not a Duration"
      )
    }

    let duration = try DurationHandler.createSpecialized(from: self) as! DurationHandler.DurationValue
    return duration.toTimeInterval()
  }
}

// MARK: - EmptyHandler

/// Handler for google.protobuf.Empty.
public struct EmptyHandler: WellKnownTypeHandler {

  public static let handledTypeName = WellKnownTypeNames.empty
  public static let supportPhase: WellKnownSupportPhase = .critical

  // MARK: - Empty Representation

  /// Specialized representation of Empty.
  ///
  /// Empty messages contain no fields, so this is a simple unit type.
  public struct EmptyValue: Equatable, CustomStringConvertible, Sendable {

    /// Creates the single instance of EmptyValue.
    public init() {}

    /// The single instance of Empty (singleton pattern).
    public static let instance = EmptyValue()

    public var description: String {
      return "Empty"
    }
  }

  // MARK: - Handler Implementation

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    guard message.descriptor.fullName == handledTypeName else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Expected \(handledTypeName), got \(message.descriptor.fullName)"
      )
    }

    return EmptyValue.instance
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    guard specialized is EmptyValue else {
      throw WellKnownTypeError.conversionFailed(
        from: String(describing: type(of: specialized)),
        to: "DynamicMessage",
        reason: "Expected EmptyValue"
      )
    }

    let emptyDescriptor = _createEmptyDescriptor()
    let factory = MessageFactory()
    let message = factory.createMessage(from: emptyDescriptor)

    return message
  }

  public static func validate(_ specialized: Any) -> Bool {
    return specialized is EmptyValue
  }

  private static func _createEmptyDescriptor() -> MessageDescriptor {
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/empty.proto",
      package: "google.protobuf"
    )

    let messageDescriptor = MessageDescriptor(
      name: "Empty",
      parent: fileDescriptor
    )

    fileDescriptor.addMessage(messageDescriptor)

    return messageDescriptor
  }
}

// MARK: - EmptyHandler Convenience Extensions

extension DynamicMessage {

  /// Creates DynamicMessage for google.protobuf.Empty.
  /// - Returns: DynamicMessage representing Empty.
  /// - Throws: WellKnownTypeError.
  public static func emptyMessage() throws -> DynamicMessage {
    return try EmptyHandler.createDynamic(from: EmptyHandler.EmptyValue.instance)
  }

  /// Checks if DynamicMessage is an empty message (Empty).
  /// - Returns: true if message is Empty.
  public func isEmpty() -> Bool {
    return descriptor.fullName == WellKnownTypeNames.empty
  }

  /// Converts DynamicMessage to EmptyValue (if it's Empty).
  /// - Returns: EmptyValue.
  /// - Throws: WellKnownTypeError if message is not Empty.
  public func toEmpty() throws -> EmptyHandler.EmptyValue {
    guard descriptor.fullName == WellKnownTypeNames.empty else {
      throw WellKnownTypeError.invalidData(
        typeName: descriptor.fullName,
        reason: "Message is not an Empty"
      )
    }

    let empty = try EmptyHandler.createSpecialized(from: self) as! EmptyHandler.EmptyValue
    return empty
  }
}

extension EmptyHandler.EmptyValue {

  /// Creates EmptyValue from Void.
  /// - Parameter void: Void value.
  /// - Returns: EmptyValue.
  public static func from(_ void: Void) -> EmptyHandler.EmptyValue {
    return EmptyHandler.EmptyValue.instance
  }

  /// Converts EmptyValue to Void.
  /// - Returns: Void.
  public func toVoid() {
    return ()
  }
}

// MARK: - FieldMaskHandler

/// Handler for google.protobuf.FieldMask.
public struct FieldMaskHandler: WellKnownTypeHandler {

  public static let handledTypeName = WellKnownTypeNames.fieldMask
  public static let supportPhase: WellKnownSupportPhase = .important

  // MARK: - FieldMask Representation

  /// Specialized representation of FieldMask.
  public struct FieldMaskValue: Equatable, CustomStringConvertible {

    /// Field paths.
    public let paths: [String]

    /// Initialization with field paths.
    /// - Parameter paths: List of field paths.
    /// - Throws: WellKnownTypeError if paths are invalid.
    public init(paths: [String]) throws {
      for path in paths {
        guard Self.isValidPath(path) else {
          throw WellKnownTypeError.invalidData(
            typeName: WellKnownTypeNames.fieldMask,
            reason:
              "Invalid field path: '\(path)'. Path must not be empty and can only contain alphanumeric characters, dots, and underscores."
          )
        }
      }

      self.paths = paths
    }

    /// Initialization with single path.
    /// - Parameter path: Field path.
    /// - Throws: WellKnownTypeError if path is invalid.
    public init(path: String) throws {
      try self.init(paths: [path])
    }

    /// Initialization of empty mask.
    public init() {
      self.paths = []
    }

    /// Checks if mask contains specified path.
    public func contains(_ path: String) -> Bool {
      return paths.contains(path)
    }

    /// Checks if mask contains path or its parent path.
    public func covers(_ path: String) -> Bool {
      if paths.contains(path) {
        return true
      }

      let components = path.split(separator: ".").map(String.init)
      for i in 1..<components.count {
        let parentPath = components[0..<i].joined(separator: ".")
        if paths.contains(parentPath) {
          return true
        }
      }

      return false
    }

    /// Adds path to mask.
    public func adding(_ path: String) throws -> FieldMaskValue {
      guard Self.isValidPath(path) else {
        throw WellKnownTypeError.invalidData(
          typeName: WellKnownTypeNames.fieldMask,
          reason: "Invalid field path: '\(path)'"
        )
      }

      var newPaths = paths
      if !newPaths.contains(path) {
        newPaths.append(path)
      }
      return try FieldMaskValue(paths: newPaths)
    }

    /// Removes path from mask.
    public func removing(_ path: String) -> FieldMaskValue {
      let newPaths = paths.filter { $0 != path }
      return try! FieldMaskValue(paths: newPaths)
    }

    /// Merges two field masks.
    public func union(_ other: FieldMaskValue) -> FieldMaskValue {
      let combinedPaths = Array(Set(paths + other.paths)).sorted()
      return try! FieldMaskValue(paths: combinedPaths)
    }

    /// Intersection of two field masks.
    public func intersection(_ other: FieldMaskValue) -> FieldMaskValue {
      let intersectionPaths = paths.filter { other.paths.contains($0) }
      return try! FieldMaskValue(paths: intersectionPaths)
    }

    /// Empty field mask.
    public static func empty() -> FieldMaskValue {
      return FieldMaskValue()
    }

    /// Mask with all specified fields.
    public static func with(paths: [String]) throws -> FieldMaskValue {
      return try FieldMaskValue(paths: paths)
    }

    public var description: String {
      if paths.isEmpty {
        return "FieldMask(empty)"
      }
      return "FieldMask(\(paths.joined(separator: ", ")))"
    }

    /// Validates field path.
    internal static func isValidPath(_ path: String) -> Bool {
      guard !path.isEmpty else {
        return false
      }

      let allowedCharacters = CharacterSet.alphanumerics.union(.init(charactersIn: "._"))
      return path.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }
  }

  // MARK: - Handler Implementation

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    guard message.descriptor.fullName == handledTypeName else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Expected \(handledTypeName), got \(message.descriptor.fullName)"
      )
    }

    let pathsValue: [String]

    do {
      if try message.hasValue(forField: "paths") {
        if let value = try message.get(forField: "paths") as? [String] {
          pathsValue = value
        }
        else {
          pathsValue = []
        }
      }
      else {
        pathsValue = []
      }
    }
    catch {
      throw WellKnownTypeError.conversionFailed(
        from: "DynamicMessage",
        to: "FieldMaskValue",
        reason: "Failed to extract paths field: \(error.localizedDescription)"
      )
    }

    return try FieldMaskValue(paths: pathsValue)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    guard let fieldMaskValue = specialized as? FieldMaskValue else {
      throw WellKnownTypeError.conversionFailed(
        from: String(describing: type(of: specialized)),
        to: "DynamicMessage",
        reason: "Expected FieldMaskValue"
      )
    }

    let fieldMaskDescriptor = _createFieldMaskDescriptor()
    let factory = MessageFactory()
    var message = factory.createMessage(from: fieldMaskDescriptor)

    try message.set(fieldMaskValue.paths, forField: "paths")

    return message
  }

  public static func validate(_ specialized: Any) -> Bool {
    guard let fieldMaskValue = specialized as? FieldMaskValue else {
      return false
    }

    return fieldMaskValue.paths.allSatisfy { FieldMaskValue.isValidPath($0) }
  }

  private static func _createFieldMaskDescriptor() -> MessageDescriptor {
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/field_mask.proto",
      package: "google.protobuf"
    )

    var messageDescriptor = MessageDescriptor(
      name: "FieldMask",
      parent: fileDescriptor
    )

    messageDescriptor.addField(
      FieldDescriptor(name: "paths", number: 1, type: .string, isRepeated: true)
    )

    fileDescriptor.addMessage(messageDescriptor)

    return messageDescriptor
  }
}

// MARK: - FieldMaskHandler Convenience Extensions

extension Array where Element == String {

  /// Creates FieldMaskValue from string array.
  /// - Returns: FieldMaskValue.
  /// - Throws: WellKnownTypeError if any path is invalid.
  public func toFieldMaskValue() throws -> FieldMaskHandler.FieldMaskValue {
    return try FieldMaskHandler.FieldMaskValue(paths: self)
  }
}

extension DynamicMessage {

  /// Creates DynamicMessage from path array for google.protobuf.FieldMask.
  /// - Parameter paths: Field paths.
  /// - Returns: DynamicMessage representing FieldMask.
  /// - Throws: WellKnownTypeError.
  public static func fieldMaskMessage(from paths: [String]) throws -> DynamicMessage {
    let fieldMask = try FieldMaskHandler.FieldMaskValue(paths: paths)
    return try FieldMaskHandler.createDynamic(from: fieldMask)
  }

  /// Converts DynamicMessage to path array (if it's FieldMask).
  /// - Returns: Array of field paths.
  /// - Throws: WellKnownTypeError if message is not FieldMask.
  public func toFieldPaths() throws -> [String] {
    guard descriptor.fullName == WellKnownTypeNames.fieldMask else {
      throw WellKnownTypeError.invalidData(
        typeName: descriptor.fullName,
        reason: "Message is not a FieldMask"
      )
    }

    let fieldMask = try FieldMaskHandler.createSpecialized(from: self) as! FieldMaskHandler.FieldMaskValue
    return fieldMask.paths
  }
}

// MARK: - StructHandler

/// Handler for google.protobuf.Struct.
public struct StructHandler: WellKnownTypeHandler {

  public static let handledTypeName = WellKnownTypeNames.structType
  public static let supportPhase: WellKnownSupportPhase = .important

  // MARK: - Struct Representation

  /// Specialized representation of Struct.
  public struct StructValue: Equatable, CustomStringConvertible {

    /// Structure fields.
    public let fields: [String: ValueValue]

    /// Initialization with structure fields.
    /// - Parameter fields: Dictionary of structure fields.
    public init(fields: [String: ValueValue] = [:]) {
      self.fields = fields
    }

    /// Initialization from Dictionary<String, Any>.
    /// - Parameter dictionary: Dictionary with arbitrary values.
    /// - Throws: WellKnownTypeError if conversion is impossible.
    public init(from dictionary: [String: Any]) throws {
      var convertedFields: [String: ValueValue] = [:]

      for (key, value) in dictionary {
        convertedFields[key] = try ValueValue(from: value)
      }

      self.fields = convertedFields
    }

    /// Creates empty structure.
    public static func empty() -> StructValue {
      return StructValue()
    }

    /// Checks if structure contains specified key.
    public func contains(_ key: String) -> Bool {
      return fields[key] != nil
    }

    /// Gets value by key.
    public func getValue(_ key: String) -> ValueValue? {
      return fields[key]
    }

    /// Creates new structure with added field.
    public func adding(_ key: String, value: ValueValue) -> StructValue {
      var newFields = fields
      newFields[key] = value
      return StructValue(fields: newFields)
    }

    /// Creates new structure without specified field.
    public func removing(_ key: String) -> StructValue {
      var newFields = fields
      newFields.removeValue(forKey: key)
      return StructValue(fields: newFields)
    }

    /// Merges two structures.
    public func merging(_ other: StructValue) -> StructValue {
      var newFields = fields
      for (key, value) in other.fields {
        newFields[key] = value
      }
      return StructValue(fields: newFields)
    }

    /// Converts to Dictionary<String, Any>.
    public func toDictionary() -> [String: Any] {
      var result: [String: Any] = [:]
      for (key, value) in fields {
        result[key] = value.toAny()
      }
      return result
    }

    public var description: String {
      if fields.isEmpty {
        return "Struct(empty)"
      }

      let fieldStrings = fields.map { "\($0.key): \($0.value)" }.sorted()
      return "Struct({\(fieldStrings.joined(separator: ", "))})"
    }
  }

  // MARK: - Value Representation

  /// Specialized representation for google.protobuf.Value.
  public enum ValueValue: Equatable, CustomStringConvertible {
    case nullValue
    case numberValue(Double)
    case stringValue(String)
    case boolValue(Bool)
    case structValue(StructValue)
    case listValue([ValueValue])

    /// Initialization from arbitrary Swift value.
    /// - Parameter value: Arbitrary value for conversion.
    /// - Throws: WellKnownTypeError if type is not supported.
    public init(from value: Any) throws {
      switch value {
      case is NSNull:
        self = .nullValue
      case let number as NSNumber:
        #if canImport(CoreFoundation) && !os(Linux)
          if CFGetTypeID(number) == CFBooleanGetTypeID() {
            self = .boolValue(number.boolValue)
          }
          else {
            self = .numberValue(number.doubleValue)
          }
        #else
          let objCType = String(cString: number.objCType)
          if objCType == "c" || objCType == "B" {
            self = .boolValue(number.boolValue)
          }
          else {
            self = .numberValue(number.doubleValue)
          }
        #endif
      case let bool as Bool:
        self = .boolValue(bool)
      case let int as Int:
        self = .numberValue(Double(int))
      case let int32 as Int32:
        self = .numberValue(Double(int32))
      case let int64 as Int64:
        self = .numberValue(Double(int64))
      case let uint as UInt:
        self = .numberValue(Double(uint))
      case let uint32 as UInt32:
        self = .numberValue(Double(uint32))
      case let uint64 as UInt64:
        self = .numberValue(Double(uint64))
      case let float as Float:
        self = .numberValue(Double(float))
      case let double as Double:
        self = .numberValue(double)
      case let string as String:
        self = .stringValue(string)
      case let dict as [String: Any]:
        let structValue = try StructValue(from: dict)
        self = .structValue(structValue)
      case let array as [Any]:
        let listValues = try array.map { try ValueValue(from: $0) }
        self = .listValue(listValues)
      default:
        throw WellKnownTypeError.invalidData(
          typeName: WellKnownTypeNames.value,
          reason: "Unsupported value type: \(type(of: value))"
        )
      }
    }

    /// Converts to arbitrary Swift value.
    public func toAny() -> Any {
      switch self {
      case .nullValue:
        return NSNull()
      case .numberValue(let number):
        return number
      case .stringValue(let string):
        return string
      case .boolValue(let bool):
        return bool
      case .structValue(let structValue):
        return structValue.toDictionary()
      case .listValue(let list):
        return list.map { $0.toAny() }
      }
    }

    public var description: String {
      switch self {
      case .nullValue:
        return "null"
      case .numberValue(let number):
        return String(number)
      case .stringValue(let string):
        return "\"\(string)\""
      case .boolValue(let bool):
        return String(bool)
      case .structValue(let structValue):
        return structValue.description
      case .listValue(let list):
        let elements = list.map { $0.description }
        return "[\(elements.joined(separator: ", "))]"
      }
    }
  }

  // MARK: - Handler Implementation

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    guard message.descriptor.fullName == handledTypeName else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Expected \(handledTypeName), got \(message.descriptor.fullName)"
      )
    }

    return try _dynamicMessageToStructValue(message)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    guard let structValue = specialized as? StructValue else {
      throw WellKnownTypeError.conversionFailed(
        from: String(describing: type(of: specialized)),
        to: "DynamicMessage",
        reason: "Expected StructValue"
      )
    }

    return try _structValueToDynamicMessage(structValue)
  }

  public static func validate(_ specialized: Any) -> Bool {
    return specialized is StructValue
  }
}

// MARK: - StructHandler Convenience Extensions

extension Dictionary where Key == String, Value == Any {

  /// Creates StructValue from dictionary.
  /// - Returns: StructValue.
  /// - Throws: WellKnownTypeError if conversion is impossible.
  public func toStructValue() throws -> StructHandler.StructValue {
    return try StructHandler.StructValue(from: self)
  }
}

extension DynamicMessage {

  /// Creates DynamicMessage from dictionary for google.protobuf.Struct.
  /// - Parameter fields: Structure fields.
  /// - Returns: DynamicMessage representing Struct.
  /// - Throws: WellKnownTypeError.
  public static func structMessage(from fields: [String: Any]) throws -> DynamicMessage {
    let structValue = try StructHandler.StructValue(from: fields)
    return try StructHandler.createDynamic(from: structValue)
  }

  /// Converts DynamicMessage to dictionary (if it's Struct).
  /// - Returns: Dictionary of structure fields.
  /// - Throws: WellKnownTypeError if message is not Struct.
  public func toFieldsDictionary() throws -> [String: Any] {
    guard descriptor.fullName == WellKnownTypeNames.structType else {
      throw WellKnownTypeError.invalidData(
        typeName: descriptor.fullName,
        reason: "Message is not a Struct"
      )
    }

    let structValue = try StructHandler.createSpecialized(from: self) as! StructHandler.StructValue
    return structValue.toDictionary()
  }
}

// MARK: - ValueHandler

/// Handler for google.protobuf.Value.
public struct ValueHandler: WellKnownTypeHandler {

  public static let handledTypeName = WellKnownTypeNames.value
  public static let supportPhase: WellKnownSupportPhase = .important

  /// Reuse ValueValue from StructHandler for compatibility.
  public typealias ValueValue = StructHandler.ValueValue

  // MARK: - Handler Implementation

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    guard message.descriptor.fullName == handledTypeName else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Expected \(handledTypeName), got \(message.descriptor.fullName)"
      )
    }

    return try dynamicMessageToValueValue(message)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    guard let valueValue = specialized as? ValueValue else {
      throw WellKnownTypeError.conversionFailed(
        from: String(describing: type(of: specialized)),
        to: "DynamicMessage",
        reason: "Expected ValueValue"
      )
    }

    return try valueValueToDynamicMessage(valueValue)
  }

  public static func validate(_ specialized: Any) -> Bool {
    return specialized is ValueValue
  }
}

// MARK: - ValueHandler Convenience Extensions

extension DynamicMessage {

  /// Creates DynamicMessage from arbitrary value for google.protobuf.Value.
  /// - Parameter value: Arbitrary value.
  /// - Returns: DynamicMessage representing Value.
  /// - Throws: WellKnownTypeError.
  public static func valueMessage(from value: Any) throws -> DynamicMessage {
    let valueValue = try ValueHandler.ValueValue(from: value)
    return try ValueHandler.createDynamic(from: valueValue)
  }

  /// Converts DynamicMessage to arbitrary value (if it's Value).
  /// - Returns: Arbitrary value.
  /// - Throws: WellKnownTypeError if message is not Value.
  public func toAnyValue() throws -> Any {
    guard descriptor.fullName == WellKnownTypeNames.value else {
      throw WellKnownTypeError.invalidData(
        typeName: descriptor.fullName,
        reason: "Message is not a Value"
      )
    }

    let valueValue = try ValueHandler.createSpecialized(from: self) as! ValueHandler.ValueValue
    return valueValue.toAny()
  }
}

// MARK: - ListValueHandler

/// Handler for google.protobuf.ListValue.
public struct ListValueHandler: WellKnownTypeHandler {

  public static let handledTypeName = WellKnownTypeNames.listValue
  public static let supportPhase: WellKnownSupportPhase = .advanced

  // MARK: - Handler Implementation

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    guard message.descriptor.fullName == handledTypeName else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Expected \(handledTypeName), got \(message.descriptor.fullName)"
      )
    }

    return try _dynamicMessageToListValue(message)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    guard let values = specialized as? [StructHandler.ValueValue] else {
      throw WellKnownTypeError.conversionFailed(
        from: String(describing: type(of: specialized)),
        to: "DynamicMessage",
        reason: "Expected [ValueValue]"
      )
    }

    return try _listValueToDynamicMessage(values)
  }

  public static func validate(_ specialized: Any) -> Bool {
    return specialized is [StructHandler.ValueValue]
  }

  // MARK: - Descriptor

  /// Returns the canonical descriptor for `google.protobuf.ListValue`.
  public static func createListValueDescriptor() -> MessageDescriptor {
    return StructProtoDescriptors.listValueDescriptor
  }
}

// MARK: - AnyHandler

/// Handler for google.protobuf.Any.
public struct AnyHandler: WellKnownTypeHandler {

  public static let handledTypeName = WellKnownTypeNames.any
  public static let supportPhase: WellKnownSupportPhase = .advanced

  // MARK: - Any Representation

  /// Specialized representation of Any.
  ///
  /// Any contains an arbitrary serialized message with type URL for type erasure.
  public struct AnyValue: Equatable, CustomStringConvertible {

    // MARK: - Properties

    /// Type URL that describes the type of the serialized message.
    /// Format: type.googleapis.com/package.MessageType
    public let typeUrl: String

    /// Serialized message data.
    public let value: Data

    // MARK: - Initialization

    /// Creates AnyValue with specified type URL and data.
    /// - Parameters:
    ///   - typeUrl: Message type URL
    ///   - value: Serialized message data
    /// - Throws: WellKnownTypeError if type URL is invalid
    public init(typeUrl: String, value: Data) throws {
      guard Self.isValidTypeUrl(typeUrl) else {
        throw WellKnownTypeError.invalidData(
          typeName: AnyHandler.handledTypeName,
          reason: "Invalid type URL format: '\(typeUrl)'"
        )
      }
      self.typeUrl = typeUrl
      self.value = value
    }

    /// Creates AnyValue from arbitrary DynamicMessage.
    /// - Parameter message: Dynamic message to pack
    /// - Returns: AnyValue containing packed message
    /// - Throws: WellKnownTypeError if packing fails
    public static func pack(_ message: DynamicMessage) throws -> AnyValue {
      let typeUrl = Self.createTypeUrl(for: message.descriptor.fullName)

      let serializer = BinarySerializer()
      let serializedData = try serializer.serialize(message)

      return try AnyValue(typeUrl: typeUrl, value: serializedData)
    }

    /// Unpacks Any to concrete message type.
    /// - Parameter targetDescriptor: Target type descriptor
    /// - Returns: Unpacked dynamic message
    /// - Throws: WellKnownTypeError if unpacking fails
    public func unpack(to targetDescriptor: MessageDescriptor) throws -> DynamicMessage {
      let expectedTypeName = targetDescriptor.fullName
      let actualTypeName = getTypeName()

      guard actualTypeName == expectedTypeName else {
        throw WellKnownTypeError.conversionFailed(
          from: "AnyValue[\(typeUrl)]",
          to: expectedTypeName,
          reason: "Type URL mismatch. Expected: \(expectedTypeName), got: \(actualTypeName)"
        )
      }

      if value.isEmpty {
        let factory = MessageFactory()
        return factory.createMessage(from: targetDescriptor)
      }
      else {
        let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
        return try deserializer.deserialize(value, using: targetDescriptor)
      }
    }

    /// Extracts message type name from type URL.
    /// - Returns: Full type name (e.g., "google.protobuf.Duration")
    public func getTypeName() -> String {
      return Self.extractTypeName(from: typeUrl)
    }

    // MARK: - URL Utilities

    internal static func createTypeUrl(for typeName: String) -> String {
      return "type.googleapis.com/\(typeName)"
    }

    internal static func extractTypeName(from typeUrl: String) -> String {
      if let lastSlashIndex = typeUrl.lastIndex(of: "/") {
        return String(typeUrl[typeUrl.index(after: lastSlashIndex)...])
      }
      return typeUrl
    }

    internal static func isValidTypeUrl(_ typeUrl: String) -> Bool {
      guard !typeUrl.isEmpty else { return false }
      guard let slashIndex = typeUrl.lastIndex(of: "/") else { return false }
      guard slashIndex != typeUrl.startIndex else { return false }

      let domain = String(typeUrl[..<slashIndex])
      let typeName = String(typeUrl[typeUrl.index(after: slashIndex)...])

      guard !domain.isEmpty && domain.contains(".") else { return false }
      guard !typeName.isEmpty && typeName.contains(".") else { return false }

      return true
    }

    // MARK: - Equatable

    public static func == (lhs: AnyValue, rhs: AnyValue) -> Bool {
      return lhs.typeUrl == rhs.typeUrl && lhs.value == rhs.value
    }

    // MARK: - CustomStringConvertible

    public var description: String {
      return "Any(typeUrl: \(typeUrl), value: \(value.count) bytes)"
    }
  }

  // MARK: - Handler Implementation

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    guard message.descriptor.fullName == handledTypeName else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Expected \(handledTypeName), got \(message.descriptor.fullName)"
      )
    }

    guard let typeUrl = try message.get(forField: "type_url") as? String else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Missing or invalid type_url field"
      )
    }

    guard let valueData = try message.get(forField: "value") as? Data else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Missing or invalid value field"
      )
    }

    return try AnyValue(typeUrl: typeUrl, value: valueData)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    guard let anyValue = specialized as? AnyValue else {
      throw WellKnownTypeError.conversionFailed(
        from: String(describing: type(of: specialized)),
        to: "DynamicMessage",
        reason: "Expected AnyValue"
      )
    }

    let anyDescriptor = _createAnyDescriptor()
    let factory = MessageFactory()
    var message = factory.createMessage(from: anyDescriptor)

    try message.set(anyValue.typeUrl, forField: "type_url")
    try message.set(anyValue.value, forField: "value")

    return message
  }

  public static func validate(_ specialized: Any) -> Bool {
    guard let anyValue = specialized as? AnyValue else { return false }
    return AnyValue.isValidTypeUrl(anyValue.typeUrl)
  }

  private static func _createAnyDescriptor() -> MessageDescriptor {
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/any.proto",
      package: "google.protobuf"
    )

    var messageDescriptor = MessageDescriptor(
      name: "Any",
      parent: fileDescriptor
    )

    messageDescriptor.addField(FieldDescriptor(name: "type_url", number: 1, type: .string))
    messageDescriptor.addField(FieldDescriptor(name: "value", number: 2, type: .bytes))
    fileDescriptor.addMessage(messageDescriptor)

    return messageDescriptor
  }
}

// MARK: - AnyHandler Convenience Extensions

extension DynamicMessage {

  /// Packs DynamicMessage into google.protobuf.Any.
  /// - Returns: DynamicMessage representing Any.
  /// - Throws: WellKnownTypeError.
  public func packIntoAny() throws -> DynamicMessage {
    let anyValue = try AnyHandler.AnyValue.pack(self)
    return try AnyHandler.createDynamic(from: anyValue)
  }

  /// Unpacks google.protobuf.Any to DynamicMessage.
  /// - Parameter targetDescriptor: Target type descriptor
  /// - Returns: Unpacked message.
  /// - Throws: WellKnownTypeError if message is not Any or types don't match.
  public func unpackFromAny(to targetDescriptor: MessageDescriptor) throws -> DynamicMessage {
    guard descriptor.fullName == WellKnownTypeNames.any else {
      throw WellKnownTypeError.invalidData(
        typeName: descriptor.fullName,
        reason: "Message is not an Any"
      )
    }

    let anyValue = try AnyHandler.createSpecialized(from: self) as! AnyHandler.AnyValue
    return try anyValue.unpack(to: targetDescriptor)
  }

  /// Checks if Any contains message of specified type.
  /// - Parameter typeName: Full type name to check
  /// - Returns: true if Any contains message of specified type
  /// - Throws: WellKnownTypeError if message is not Any
  public func isAnyOf(typeName: String) throws -> Bool {
    guard descriptor.fullName == WellKnownTypeNames.any else {
      throw WellKnownTypeError.invalidData(
        typeName: descriptor.fullName,
        reason: "Message is not an Any"
      )
    }

    let anyValue = try AnyHandler.createSpecialized(from: self) as! AnyHandler.AnyValue
    return anyValue.getTypeName() == typeName
  }

  /// Gets type name of message contained in Any.
  /// - Returns: Full type name of the message
  /// - Throws: WellKnownTypeError if message is not Any
  public func getAnyTypeName() throws -> String {
    guard descriptor.fullName == WellKnownTypeNames.any else {
      throw WellKnownTypeError.invalidData(
        typeName: descriptor.fullName,
        reason: "Message is not an Any"
      )
    }

    let anyValue = try AnyHandler.createSpecialized(from: self) as! AnyHandler.AnyValue
    return anyValue.getTypeName()
  }
}

extension AnyHandler.AnyValue {

  /// Unpacks Any using TypeRegistry for type resolution.
  /// - Parameter registry: Type registry for descriptor resolution
  /// - Returns: Unpacked dynamic message
  /// - Throws: WellKnownTypeError if type not found or deserialization fails
  public func unpack(using registry: TypeRegistry) throws -> DynamicMessage {
    let typeName = getTypeName()

    guard let messageDescriptor = registry.findMessage(named: typeName) else {
      throw WellKnownTypeError.conversionFailed(
        from: "AnyValue",
        to: typeName,
        reason: "Message type '\(typeName)' not found in registry"
      )
    }

    return try unpack(to: messageDescriptor)
  }
}

// MARK: - Wrapper Handlers

// MARK: - StringValueHandler

/// Handler for google.protobuf.StringValue.
public struct StringValueHandler: WellKnownTypeHandler {
  public static let handledTypeName = WellKnownTypeNames.stringValue
  public static let supportPhase: WellKnownSupportPhase = .advanced

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    try _wrapperCreateSpecialized(from: message, typeName: handledTypeName, as: String.self)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    try _wrapperCreateDynamic(
      from: specialized,
      typeName: handledTypeName,
      descriptorName: "StringValue",
      fieldType: .string,
      as: String.self
    )
  }

  public static func validate(_ specialized: Any) -> Bool { specialized is String }
}

// MARK: - Int32ValueHandler

/// Handler for google.protobuf.Int32Value.
public struct Int32ValueHandler: WellKnownTypeHandler {
  public static let handledTypeName = WellKnownTypeNames.int32Value
  public static let supportPhase: WellKnownSupportPhase = .advanced

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    try _wrapperCreateSpecialized(from: message, typeName: handledTypeName, as: Int32.self)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    try _wrapperCreateDynamic(
      from: specialized,
      typeName: handledTypeName,
      descriptorName: "Int32Value",
      fieldType: .int32,
      as: Int32.self
    )
  }

  public static func validate(_ specialized: Any) -> Bool { specialized is Int32 }
}

// MARK: - Int64ValueHandler

/// Handler for google.protobuf.Int64Value.
public struct Int64ValueHandler: WellKnownTypeHandler {
  public static let handledTypeName = WellKnownTypeNames.int64Value
  public static let supportPhase: WellKnownSupportPhase = .advanced

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    try _wrapperCreateSpecialized(from: message, typeName: handledTypeName, as: Int64.self)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    try _wrapperCreateDynamic(
      from: specialized,
      typeName: handledTypeName,
      descriptorName: "Int64Value",
      fieldType: .int64,
      as: Int64.self
    )
  }

  public static func validate(_ specialized: Any) -> Bool { specialized is Int64 }
}

// MARK: - UInt32ValueHandler

/// Handler for google.protobuf.UInt32Value.
public struct UInt32ValueHandler: WellKnownTypeHandler {
  public static let handledTypeName = WellKnownTypeNames.uint32Value
  public static let supportPhase: WellKnownSupportPhase = .advanced

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    try _wrapperCreateSpecialized(from: message, typeName: handledTypeName, as: UInt32.self)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    try _wrapperCreateDynamic(
      from: specialized,
      typeName: handledTypeName,
      descriptorName: "UInt32Value",
      fieldType: .uint32,
      as: UInt32.self
    )
  }

  public static func validate(_ specialized: Any) -> Bool { specialized is UInt32 }
}

// MARK: - UInt64ValueHandler

/// Handler for google.protobuf.UInt64Value.
public struct UInt64ValueHandler: WellKnownTypeHandler {
  public static let handledTypeName = WellKnownTypeNames.uint64Value
  public static let supportPhase: WellKnownSupportPhase = .advanced

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    try _wrapperCreateSpecialized(from: message, typeName: handledTypeName, as: UInt64.self)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    try _wrapperCreateDynamic(
      from: specialized,
      typeName: handledTypeName,
      descriptorName: "UInt64Value",
      fieldType: .uint64,
      as: UInt64.self
    )
  }

  public static func validate(_ specialized: Any) -> Bool { specialized is UInt64 }
}

// MARK: - BoolValueHandler

/// Handler for google.protobuf.BoolValue.
public struct BoolValueHandler: WellKnownTypeHandler {
  public static let handledTypeName = WellKnownTypeNames.boolValue
  public static let supportPhase: WellKnownSupportPhase = .advanced

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    try _wrapperCreateSpecialized(from: message, typeName: handledTypeName, as: Bool.self)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    try _wrapperCreateDynamic(
      from: specialized,
      typeName: handledTypeName,
      descriptorName: "BoolValue",
      fieldType: .bool,
      as: Bool.self
    )
  }

  public static func validate(_ specialized: Any) -> Bool { specialized is Bool }
}

// MARK: - FloatValueHandler

/// Handler for google.protobuf.FloatValue.
public struct FloatValueHandler: WellKnownTypeHandler {
  public static let handledTypeName = WellKnownTypeNames.floatValue
  public static let supportPhase: WellKnownSupportPhase = .advanced

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    try _wrapperCreateSpecialized(from: message, typeName: handledTypeName, as: Float.self)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    try _wrapperCreateDynamic(
      from: specialized,
      typeName: handledTypeName,
      descriptorName: "FloatValue",
      fieldType: .float,
      as: Float.self
    )
  }

  public static func validate(_ specialized: Any) -> Bool { specialized is Float }
}

// MARK: - DoubleValueHandler

/// Handler for google.protobuf.DoubleValue.
public struct DoubleValueHandler: WellKnownTypeHandler {
  public static let handledTypeName = WellKnownTypeNames.doubleValue
  public static let supportPhase: WellKnownSupportPhase = .advanced

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    try _wrapperCreateSpecialized(from: message, typeName: handledTypeName, as: Double.self)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    try _wrapperCreateDynamic(
      from: specialized,
      typeName: handledTypeName,
      descriptorName: "DoubleValue",
      fieldType: .double,
      as: Double.self
    )
  }

  public static func validate(_ specialized: Any) -> Bool { specialized is Double }
}

// MARK: - BytesValueHandler

/// Handler for google.protobuf.BytesValue.
public struct BytesValueHandler: WellKnownTypeHandler {
  public static let handledTypeName = WellKnownTypeNames.bytesValue
  public static let supportPhase: WellKnownSupportPhase = .advanced

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    try _wrapperCreateSpecialized(from: message, typeName: handledTypeName, as: Data.self)
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    try _wrapperCreateDynamic(
      from: specialized,
      typeName: handledTypeName,
      descriptorName: "BytesValue",
      fieldType: .bytes,
      as: Data.self
    )
  }

  public static func validate(_ specialized: Any) -> Bool { specialized is Data }
}

// MARK: - Private Wrapper Helpers

private func _wrapperCreateSpecialized<T>(
  from message: DynamicMessage,
  typeName: String,
  as _: T.Type
) throws -> Any {
  guard let value = try message.get(forField: "value") else {
    throw WellKnownTypeError.invalidData(
      typeName: typeName,
      reason: "missing 'value' field"
    )
  }
  guard let typed = value as? T else {
    throw WellKnownTypeError.conversionFailed(
      from: String(describing: type(of: value)),
      to: String(describing: T.self),
      reason: "value is not \(T.self)"
    )
  }
  return typed
}

private func _wrapperCreateDynamic<T>(
  from specialized: Any,
  typeName: String,
  descriptorName: String,
  fieldType: FieldType,
  as _: T.Type
) throws -> DynamicMessage {
  guard let typed = specialized as? T else {
    throw WellKnownTypeError.conversionFailed(
      from: String(describing: type(of: specialized)),
      to: typeName,
      reason: "expected \(T.self)"
    )
  }
  var desc = MessageDescriptor(name: descriptorName, fullName: typeName)
  desc.addField(FieldDescriptor(name: "value", number: 1, type: fieldType))
  let factory = MessageFactory()
  var msg = factory.createMessage(from: desc)
  try msg.set(typed, forField: "value")
  return msg
}
