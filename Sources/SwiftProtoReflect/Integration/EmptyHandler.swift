/**
 * EmptyHandler.swift
 * SwiftProtoReflect
 *
 * Handler for google.protobuf.Empty - represents empty messages without fields
 */

import Foundation
import SwiftProtobuf

// MARK: - Empty Handler

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
    // Check message type
    guard message.descriptor.fullName == handledTypeName else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Expected \(handledTypeName), got \(message.descriptor.fullName)"
      )
    }

    // For Empty message just return the single instance
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

    // Create descriptor for Empty
    let emptyDescriptor = createEmptyDescriptor()

    // Create empty message
    let factory = MessageFactory()
    let message = factory.createMessage(from: emptyDescriptor)

    // Empty message has no fields, so just return the created message
    return message
  }

  public static func validate(_ specialized: Any) -> Bool {
    // EmptyValue is always valid
    return specialized is EmptyValue
  }

  // MARK: - Descriptor Creation

  /// Creates descriptor for google.protobuf.Empty.
  /// - Returns: MessageDescriptor for Empty.
  private static func createEmptyDescriptor() -> MessageDescriptor {
    // Create file descriptor
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/empty.proto",
      package: "google.protobuf"
    )

    // Create message descriptor
    let messageDescriptor = MessageDescriptor(
      name: "Empty",
      parent: fileDescriptor
    )

    // Empty message has no fields - only register in file
    fileDescriptor.addMessage(messageDescriptor)

    return messageDescriptor
  }
}

// MARK: - Convenience Extensions

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

// MARK: - Unit Type Integration

/// Extension for integration with Swift Void as analog of Empty.
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
