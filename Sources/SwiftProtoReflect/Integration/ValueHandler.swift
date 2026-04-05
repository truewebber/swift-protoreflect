/**
 * ValueHandler.swift
 * SwiftProtoReflect
 *
 * Handler for google.protobuf.Value - universal JSON-like values
 */

import Foundation

// MARK: - Value Handler

/// Handler for google.protobuf.Value.
public struct ValueHandler: WellKnownTypeHandler {

  public static let handledTypeName = WellKnownTypeNames.value
  public static let supportPhase: WellKnownSupportPhase = .important

  // MARK: - Type Aliases

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

// MARK: - Convenience Extensions

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
