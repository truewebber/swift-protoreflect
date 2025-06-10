//
// FileDescriptor.swift
// SwiftProtoReflect
//
// Created: 2025-05-17
//

import Foundation
import SwiftProtobuf

/// FileDescriptor.
///
/// Representation of a .proto file containing metadata about messages, enums,
/// services and other elements defined in the Protocol Buffers file.
public struct FileDescriptor {
  // MARK: - Properties

  /// File name (e.g., "person.proto").
  public let name: String

  /// Package the file belongs to (e.g., "example.person").
  public let package: String

  /// File dependencies (imported .proto files).
  public let dependencies: [String]

  /// File options.
  public let options: [String: Any]

  /// List of messages defined in the file.
  public private(set) var messages: [String: MessageDescriptor] = [:]

  /// List of enums defined in the file.
  public private(set) var enums: [String: EnumDescriptor] = [:]

  /// List of services defined in the file.
  public private(set) var services: [String: ServiceDescriptor] = [:]

  // MARK: - Initialization

  /// Creates a new FileDescriptor instance.
  public init(
    name: String,
    package: String,
    dependencies: [String] = [],
    options: [String: Any] = [:]
  ) {
    self.name = name
    self.package = package
    self.dependencies = dependencies
    self.options = options
  }

  // MARK: - Methods

  /// Adds a message descriptor to the file.
  ///
  /// - Parameter messageDescriptor: Message descriptor to add.
  /// - Returns: Updated FileDescriptor.
  @discardableResult
  public mutating func addMessage(_ messageDescriptor: MessageDescriptor) -> Self {
    // Create new message considering parent file
    var newMessage = messageDescriptor

    // Set file descriptor path if not specified
    if newMessage.fileDescriptorPath == nil && newMessage.parentMessageFullName == nil {
      newMessage.fileDescriptorPath = self.name
    }

    messages[messageDescriptor.name] = newMessage
    return self
  }

  /// Adds an enum descriptor to the file.
  ///
  /// - Parameter enumDescriptor: Enum descriptor to add.
  /// - Returns: Updated FileDescriptor.
  @discardableResult
  public mutating func addEnum(_ enumDescriptor: EnumDescriptor) -> Self {
    enums[enumDescriptor.name] = enumDescriptor
    return self
  }

  /// Adds a service descriptor to the file.
  ///
  /// - Parameter serviceDescriptor: Service descriptor to add.
  /// - Returns: Updated FileDescriptor.
  @discardableResult
  public mutating func addService(_ serviceDescriptor: ServiceDescriptor) -> Self {
    services[serviceDescriptor.name] = serviceDescriptor
    return self
  }

  /// Gets the full path for a type in this file.
  ///
  /// - Parameter typeName: Type name.
  /// - Returns: Full name with package.
  public func getFullName(for typeName: String) -> String {
    return package.isEmpty ? typeName : "\(package).\(typeName)"
  }

  /// Checks if the file contains the specified message.
  ///
  /// - Parameter name: Message name.
  /// - Returns: true if the message exists.
  public func hasMessage(named name: String) -> Bool {
    return messages[name] != nil
  }

  /// Checks if the file contains the specified enum.
  ///
  /// - Parameter name: Enum name.
  /// - Returns: true if the enum exists.
  public func hasEnum(named name: String) -> Bool {
    return enums[name] != nil
  }

  /// Checks if the file contains the specified service.
  ///
  /// - Parameter name: Service name.
  /// - Returns: true if the service exists.
  public func hasService(named name: String) -> Bool {
    return services[name] != nil
  }
}
