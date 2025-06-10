//
// StaticMessageBridge.swift
// SwiftProtoReflect
//
// Created: 2025-05-25
//

import Foundation
import SwiftProtobuf

/// StaticMessageBridge provides conversion between static Swift Protobuf messages
/// and dynamic DynamicMessage objects.
///
/// This component allows:
/// - Converting static messages to dynamic for reflection.
/// - Creating static messages from dynamic for integration with existing code.
/// - Ensuring compatibility between static and dynamic approaches.
public struct StaticMessageBridge {

  // MARK: - Initialization

  /// Creates new StaticMessageBridge instance.
  public init() {}

  // MARK: - Static to Dynamic Conversion

  /// Converts static Swift Protobuf message to dynamic DynamicMessage.
  ///
  /// - Parameters:
  ///   - staticMessage: Static message to convert.
  ///   - descriptor: Descriptor for creating dynamic message.
  /// - Returns: Dynamic message with data from static.
  /// - Throws: Error if conversion is impossible.
  public func toDynamicMessage<T: SwiftProtobuf.Message>(
    from staticMessage: T,
    using descriptor: MessageDescriptor
  ) throws -> DynamicMessage {
    // Serialize static message to binary format
    let binaryData = try staticMessage.serializedData()

    // Deserialize to dynamic message
    let deserializer = BinaryDeserializer()
    return try deserializer.deserialize(binaryData, using: descriptor)
  }

  /// Converts static Swift Protobuf message to dynamic DynamicMessage
  /// with automatic descriptor creation.
  ///
  /// - Parameter staticMessage: Static message to convert.
  /// - Returns: Dynamic message with data from static.
  /// - Throws: Error if conversion is impossible or descriptor cannot be created.
  public func toDynamicMessage<T: SwiftProtobuf.Message>(
    from staticMessage: T
  ) throws -> DynamicMessage {
    // Create descriptor from static message
    let descriptor = try createDescriptor(from: staticMessage)

    // Convert using created descriptor
    return try toDynamicMessage(from: staticMessage, using: descriptor)
  }

  // MARK: - Dynamic to Static Conversion

  /// Converts dynamic DynamicMessage to static Swift Protobuf message.
  ///
  /// - Parameters:
  ///   - dynamicMessage: Dynamic message to convert.
  ///   - messageType: Static message type to create.
  /// - Returns: Static message with data from dynamic.
  /// - Throws: Error if conversion is impossible.
  public func toStaticMessage<T: SwiftProtobuf.Message>(
    from dynamicMessage: DynamicMessage,
    as messageType: T.Type
  ) throws -> T {
    // Serialize dynamic message to binary format
    let serializer = BinarySerializer()
    let binaryData = try serializer.serialize(dynamicMessage)

    // Deserialize to static message
    return try T(serializedBytes: binaryData)
  }

  // MARK: - Batch Conversion Methods

  /// Converts array of static messages to array of dynamic messages.
  ///
  /// - Parameters:
  ///   - staticMessages: Array of static messages.
  ///   - descriptor: Descriptor for creating dynamic messages.
  /// - Returns: Array of dynamic messages.
  /// - Throws: Error if any conversion is impossible.
  public func toDynamicMessages<T: SwiftProtobuf.Message>(
    from staticMessages: [T],
    using descriptor: MessageDescriptor
  ) throws -> [DynamicMessage] {
    return try staticMessages.map { staticMessage in
      try toDynamicMessage(from: staticMessage, using: descriptor)
    }
  }

  /// Converts array of dynamic messages to array of static messages.
  ///
  /// - Parameters:
  ///   - dynamicMessages: Array of dynamic messages.
  ///   - messageType: Static message type to create.
  /// - Returns: Array of static messages.
  /// - Throws: Error if any conversion is impossible.
  public func toStaticMessages<T: SwiftProtobuf.Message>(
    from dynamicMessages: [DynamicMessage],
    as messageType: T.Type
  ) throws -> [T] {
    return try dynamicMessages.map { dynamicMessage in
      try toStaticMessage(from: dynamicMessage, as: messageType)
    }
  }

  // MARK: - Validation Methods

  /// Checks compatibility of static message with descriptor.
  ///
  /// - Parameters:
  ///   - staticMessage: Static message to check.
  ///   - descriptor: Descriptor for comparison.
  /// - Returns: true if message is compatible with descriptor.
  public func isCompatible<T: SwiftProtobuf.Message>(
    staticMessage: T,
    with descriptor: MessageDescriptor
  ) -> Bool {
    do {
      // Try to convert and check that no errors occur
      _ = try toDynamicMessage(from: staticMessage, using: descriptor)
      return true
    }
    catch {
      return false
    }
  }

  /// Checks compatibility of dynamic message with static message type.
  ///
  /// - Parameters:
  ///   - dynamicMessage: Dynamic message to check.
  ///   - messageType: Static message type for comparison.
  /// - Returns: true if message is compatible with type.
  public func isCompatible<T: SwiftProtobuf.Message>(
    dynamicMessage: DynamicMessage,
    with messageType: T.Type
  ) -> Bool {
    do {
      // Try to convert and check that no errors occur
      _ = try toStaticMessage(from: dynamicMessage, as: messageType)
      return true
    }
    catch {
      return false
    }
  }

  // MARK: - Helper Methods

  /// Creates MessageDescriptor from static Swift Protobuf message.
  ///
  /// - Parameter staticMessage: Static message.
  /// - Returns: Message descriptor.
  /// - Throws: Error if descriptor cannot be created.
  private func createDescriptor<T: SwiftProtobuf.Message>(
    from staticMessage: T
  ) throws -> MessageDescriptor {
    // Get message type name
    let typeName = String(describing: T.self)

    // Create basic descriptor
    // In real implementation there should be logic for extracting
    // metadata from static message through reflection
    let descriptor = MessageDescriptor(name: typeName)

    // TODO: Implement field extraction from static message
    // This requires deeper integration with Swift Protobuf

    return descriptor
  }
}

/// Errors that occur when working with StaticMessageBridge.
public enum StaticMessageBridgeError: Error, LocalizedError {
  case incompatibleTypes(staticType: String, descriptorType: String)
  case serializationFailed(underlying: Error)
  case deserializationFailed(underlying: Error)
  case descriptorCreationFailed(messageType: String)
  case unsupportedMessageType(String)

  public var errorDescription: String? {
    switch self {
    case .incompatibleTypes(let staticType, let descriptorType):
      return "Incompatible types: static type '\(staticType)' does not match descriptor '\(descriptorType)'"
    case .serializationFailed(let underlying):
      return "Serialization error: \(underlying.localizedDescription)"
    case .deserializationFailed(let underlying):
      return "Deserialization error: \(underlying.localizedDescription)"
    case .descriptorCreationFailed(let messageType):
      return "Failed to create descriptor for message type '\(messageType)'"
    case .unsupportedMessageType(let messageType):
      return "Unsupported message type: '\(messageType)'"
    }
  }
}

// MARK: - Extensions

/// Extension for DynamicMessage for convenient conversion to static messages.
extension DynamicMessage {

  /// Converts this dynamic message to static Swift Protobuf message.
  ///
  /// - Parameter messageType: Static message type to create.
  /// - Returns: Static message with data from this dynamic.
  /// - Throws: Error if conversion is impossible.
  public func toStaticMessage<T: SwiftProtobuf.Message>(as messageType: T.Type) throws -> T {
    let bridge = StaticMessageBridge()
    return try bridge.toStaticMessage(from: self, as: messageType)
  }
}

/// Extension for Swift Protobuf Message for convenient conversion to dynamic messages.
extension SwiftProtobuf.Message {

  /// Converts this static message to dynamic DynamicMessage.
  ///
  /// - Parameter descriptor: Descriptor for creating dynamic message.
  /// - Returns: Dynamic message with data from this static.
  /// - Throws: Error if conversion is impossible.
  public func toDynamicMessage(using descriptor: MessageDescriptor) throws -> DynamicMessage {
    let bridge = StaticMessageBridge()
    return try bridge.toDynamicMessage(from: self, using: descriptor)
  }

  /// Converts this static message to dynamic DynamicMessage
  /// with automatic descriptor creation.
  ///
  /// - Returns: Dynamic message with data from this static.
  /// - Throws: Error if conversion is impossible or descriptor cannot be created.
  public func toDynamicMessage() throws -> DynamicMessage {
    let bridge = StaticMessageBridge()
    return try bridge.toDynamicMessage(from: self)
  }
}
