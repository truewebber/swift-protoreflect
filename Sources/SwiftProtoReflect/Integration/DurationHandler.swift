/**
 * DurationHandler.swift
 * SwiftProtoReflect
 *
 * Handler for google.protobuf.Duration - conversion between DynamicMessage and TimeInterval
 */

import Foundation
import SwiftProtobuf

// MARK: - Duration Handler

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

      // Calculate nanoseconds with sign consideration
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
        // Negative duration - make positive
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
        // For very small values show in milliseconds or nanoseconds
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
    /// - Parameter nanos: Nanoseconds value.
    /// - Returns: true if valid.
    internal static func isValidNanos(_ nanos: Int32) -> Bool {
      return nanos >= -999_999_999 && nanos <= 999_999_999
    }

    /// Validates combination of seconds and nanoseconds.
    /// - Parameters:
    ///   - seconds: Seconds.
    ///   - nanos: Nanoseconds.
    /// - Returns: true if combination is valid.
    internal static func isValidSecondsNanosCombination(seconds: Int64, nanos: Int32) -> Bool {
      // If one value is zero, combination is always valid
      if seconds == 0 || nanos == 0 {
        return true
      }

      // Both values must have same sign
      return (seconds > 0 && nanos > 0) || (seconds < 0 && nanos < 0)
    }
  }

  // MARK: - Handler Implementation

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    // Check message type
    guard message.descriptor.fullName == handledTypeName else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Expected \(handledTypeName), got \(message.descriptor.fullName)"
      )
    }

    // Extract seconds and nanos fields
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

    // Create DurationValue
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

    // Create descriptor for Duration
    let durationDescriptor = createDurationDescriptor()

    // Create message
    let factory = MessageFactory()
    var message = factory.createMessage(from: durationDescriptor)

    // Set fields
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

  // MARK: - Descriptor Creation

  /// Creates descriptor for google.protobuf.Duration.
  /// - Returns: MessageDescriptor for Duration.
  private static func createDurationDescriptor() -> MessageDescriptor {
    // Create file descriptor
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/duration.proto",
      package: "google.protobuf"
    )

    // Create message descriptor
    var messageDescriptor = MessageDescriptor(
      name: "Duration",
      parent: fileDescriptor
    )

    // Add seconds field
    let secondsField = FieldDescriptor(
      name: "seconds",
      number: 1,
      type: .int64
    )
    messageDescriptor.addField(secondsField)

    // Add nanos field
    let nanosField = FieldDescriptor(
      name: "nanos",
      number: 2,
      type: .int32
    )
    messageDescriptor.addField(nanosField)

    // Register in file
    fileDescriptor.addMessage(messageDescriptor)

    return messageDescriptor
  }
}

// MARK: - Convenience Extensions

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
