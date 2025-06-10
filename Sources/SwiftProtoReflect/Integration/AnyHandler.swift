/**
 * AnyHandler.swift
 * SwiftProtoReflect
 *
 * Handler for google.protobuf.Any - type erasure support for arbitrary typed messages
 */

import Foundation

// MARK: - Any Handler

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
      // Create type URL from message descriptor
      let typeUrl = Self.createTypeUrl(for: message.descriptor.fullName)

      // Serialize message to binary format
      let serializer = BinarySerializer()
      let serializedData = try serializer.serialize(message)

      return try AnyValue(typeUrl: typeUrl, value: serializedData)
    }

    /// Unpacks Any to concrete message type.
    /// - Parameter targetDescriptor: Target type descriptor
    /// - Returns: Unpacked dynamic message
    /// - Throws: WellKnownTypeError if unpacking fails
    public func unpack(to targetDescriptor: MessageDescriptor) throws -> DynamicMessage {
      // Check that type_url matches expected type
      let expectedTypeName = targetDescriptor.fullName
      let actualTypeName = getTypeName()

      guard actualTypeName == expectedTypeName else {
        throw WellKnownTypeError.conversionFailed(
          from: "AnyValue[\(typeUrl)]",
          to: expectedTypeName,
          reason: "Type URL mismatch. Expected: \(expectedTypeName), got: \(actualTypeName)"
        )
      }

      // Deserialize data to message
      if value.isEmpty {
        // Return empty message for empty data
        let factory = MessageFactory()
        return factory.createMessage(from: targetDescriptor)
      }
      else {
        let deserializer = BinaryDeserializer()
        return try deserializer.deserialize(value, using: targetDescriptor)
      }
    }

    /// Extracts message type name from type URL.
    /// - Returns: Full type name (e.g., "google.protobuf.Duration")
    public func getTypeName() -> String {
      return Self.extractTypeName(from: typeUrl)
    }

    // MARK: - URL Utilities

    /// Creates type URL for specified type name.
    /// - Parameter typeName: Full type name
    /// - Returns: Correctly formatted type URL
    internal static func createTypeUrl(for typeName: String) -> String {
      return "type.googleapis.com/\(typeName)"
    }

    /// Extracts type name from type URL.
    /// - Parameter typeUrl: Type URL
    /// - Returns: Type name
    internal static func extractTypeName(from typeUrl: String) -> String {
      if let lastSlashIndex = typeUrl.lastIndex(of: "/") {
        return String(typeUrl[typeUrl.index(after: lastSlashIndex)...])
      }
      return typeUrl
    }

    /// Validates type URL.
    /// - Parameter typeUrl: URL to validate
    /// - Returns: true if URL is valid
    internal static func isValidTypeUrl(_ typeUrl: String) -> Bool {
      // Check basic format
      guard !typeUrl.isEmpty else { return false }

      // Check that there is at least one slash
      guard let slashIndex = typeUrl.lastIndex(of: "/") else { return false }

      // Check that there is domain before slash (cannot start with "/")
      guard slashIndex != typeUrl.startIndex else { return false }

      // Extract domain and type name
      let domain = String(typeUrl[..<slashIndex])
      let typeName = String(typeUrl[typeUrl.index(after: slashIndex)...])

      // Domain must not be empty and should contain at least one dot
      guard !domain.isEmpty && domain.contains(".") else { return false }

      // Type name must not be empty and should contain dot for package.Type
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
    // Check message type
    guard message.descriptor.fullName == handledTypeName else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Expected \(handledTypeName), got \(message.descriptor.fullName)"
      )
    }

    // Extract type_url and value fields
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

    // Create descriptor for Any
    let anyDescriptor = createAnyDescriptor()

    // Create message
    let factory = MessageFactory()
    var message = factory.createMessage(from: anyDescriptor)

    // Set fields
    try message.set(anyValue.typeUrl, forField: "type_url")
    try message.set(anyValue.value, forField: "value")

    return message
  }

  public static func validate(_ specialized: Any) -> Bool {
    guard let anyValue = specialized as? AnyValue else { return false }

    // Check type URL validity
    return AnyValue.isValidTypeUrl(anyValue.typeUrl)
  }

  // MARK: - Descriptor Creation

  /// Creates descriptor for google.protobuf.Any.
  /// - Returns: MessageDescriptor for Any.
  private static func createAnyDescriptor() -> MessageDescriptor {
    // Create file descriptor
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/any.proto",
      package: "google.protobuf"
    )

    // Create Any message descriptor
    var messageDescriptor = MessageDescriptor(
      name: "Any",
      parent: fileDescriptor
    )

    // Add type_url field
    let typeUrlField = FieldDescriptor(
      name: "type_url",
      number: 1,
      type: .string
    )
    messageDescriptor.addField(typeUrlField)

    // Add value field
    let valueField = FieldDescriptor(
      name: "value",
      number: 2,
      type: .bytes
    )
    messageDescriptor.addField(valueField)

    // Register in file
    fileDescriptor.addMessage(messageDescriptor)

    return messageDescriptor
  }
}

// MARK: - Convenience Extensions

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

// MARK: - Type Registry Integration

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
