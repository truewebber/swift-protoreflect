//
// TypeRegistry.swift
// SwiftProtoReflect
//
// Created: 2025-05-24
//

import Foundation
import SwiftProtobuf

/// TypeRegistry.
///
/// Centralized registry for managing all known Protocol Buffers types.
/// Provides registration, lookup and dependency resolution between types.
///
/// ## Main capabilities:
/// - Registration of FileDescriptor, MessageDescriptor, EnumDescriptor, ServiceDescriptor.
/// - Fast type lookup by full name.
/// - Automatic type extraction from FileDescriptor.
/// - Thread-safe operations.
/// - Dependency resolution between types.
public class TypeRegistry {
  // MARK: - Properties

  /// Registry of file descriptors by file name.
  private var fileDescriptors: [String: FileDescriptor] = [:]

  /// Registry of message descriptors by full name.
  private var messageDescriptors: [String: MessageDescriptor] = [:]

  /// Registry of enum descriptors by full name.
  private var enumDescriptors: [String: EnumDescriptor] = [:]

  /// Registry of service descriptors by full name.
  private var serviceDescriptors: [String: ServiceDescriptor] = [:]

  /// Queue for thread-safe operations.
  private let accessQueue = DispatchQueue(label: "com.swiftprotoreflect.typeregistry", attributes: .concurrent)

  // MARK: - Initialization

  /// Creates a new TypeRegistry instance.
  public init() {
    // Registry is initialized empty
  }

  // MARK: - File Registration Methods

  /// Registers FileDescriptor and automatically extracts all types contained in it.
  ///
  /// - Parameter fileDescriptor: File descriptor to register.
  /// - Throws: `RegistryError.duplicateFile` if file is already registered
  public func registerFile(_ fileDescriptor: FileDescriptor) throws {
    try accessQueue.sync(flags: .barrier) {
      // Check for duplicate files
      if fileDescriptors[fileDescriptor.name] != nil {
        throw RegistryError.duplicateFile(fileDescriptor.name)
      }

      // Register file
      fileDescriptors[fileDescriptor.name] = fileDescriptor

      // Automatically register all types from file
      try registerTypesFromFile(fileDescriptor)
    }
  }

  /// Extracts and registers all types from FileDescriptor.
  private func registerTypesFromFile(_ fileDescriptor: FileDescriptor) throws {
    // Register all messages
    for (_, messageDescriptor) in fileDescriptor.messages {
      try registerMessageRecursively(messageDescriptor)
    }

    // Register all enums
    for (_, enumDescriptor) in fileDescriptor.enums {
      if enumDescriptors[enumDescriptor.fullName] != nil {
        throw RegistryError.duplicateType(enumDescriptor.fullName)
      }
      enumDescriptors[enumDescriptor.fullName] = enumDescriptor
    }

    // Register all services
    for (_, serviceDescriptor) in fileDescriptor.services {
      if serviceDescriptors[serviceDescriptor.fullName] != nil {
        throw RegistryError.duplicateType(serviceDescriptor.fullName)
      }
      serviceDescriptors[serviceDescriptor.fullName] = serviceDescriptor
    }
  }

  /// Recursively registers message and all its nested types.
  private func registerMessageRecursively(_ messageDescriptor: MessageDescriptor) throws {
    // Check for duplicates
    if messageDescriptors[messageDescriptor.fullName] != nil {
      throw RegistryError.duplicateType(messageDescriptor.fullName)
    }

    // Register the message itself
    messageDescriptors[messageDescriptor.fullName] = messageDescriptor

    // Register nested messages
    for (_, nestedMessage) in messageDescriptor.nestedMessages {
      try registerMessageRecursively(nestedMessage)
    }

    // Register nested enums
    for (_, nestedEnum) in messageDescriptor.nestedEnums {
      if enumDescriptors[nestedEnum.fullName] != nil {
        throw RegistryError.duplicateType(nestedEnum.fullName)
      }
      enumDescriptors[nestedEnum.fullName] = nestedEnum
    }
  }

  // MARK: - Direct Type Registration Methods

  /// Registers MessageDescriptor directly.
  ///
  /// - Parameter messageDescriptor: Message descriptor.
  /// - Throws: `RegistryError.duplicateType` if type is already registered
  public func registerMessage(_ messageDescriptor: MessageDescriptor) throws {
    try accessQueue.sync(flags: .barrier) {
      try registerMessageRecursively(messageDescriptor)
    }
  }

  /// Registers EnumDescriptor directly.
  ///
  /// - Parameter enumDescriptor: Enum descriptor.
  /// - Throws: `RegistryError.duplicateType` if type is already registered
  public func registerEnum(_ enumDescriptor: EnumDescriptor) throws {
    try accessQueue.sync(flags: .barrier) {
      if enumDescriptors[enumDescriptor.fullName] != nil {
        throw RegistryError.duplicateType(enumDescriptor.fullName)
      }
      enumDescriptors[enumDescriptor.fullName] = enumDescriptor
    }
  }

  /// Registers ServiceDescriptor directly.
  ///
  /// - Parameter serviceDescriptor: Service descriptor.
  /// - Throws: `RegistryError.duplicateType` if type is already registered
  public func registerService(_ serviceDescriptor: ServiceDescriptor) throws {
    try accessQueue.sync(flags: .barrier) {
      if serviceDescriptors[serviceDescriptor.fullName] != nil {
        throw RegistryError.duplicateType(serviceDescriptor.fullName)
      }
      serviceDescriptors[serviceDescriptor.fullName] = serviceDescriptor
    }
  }

  // MARK: - Lookup Methods

  /// Finds FileDescriptor by file name.
  ///
  /// - Parameter fileName: File name.
  /// - Returns: FileDescriptor or nil if not found.
  public func findFile(named fileName: String) -> FileDescriptor? {
    return accessQueue.sync {
      return fileDescriptors[fileName]
    }
  }

  /// Finds MessageDescriptor by full name.
  ///
  /// - Parameter fullName: Full message name.
  /// - Returns: MessageDescriptor or nil if not found.
  public func findMessage(named fullName: String) -> MessageDescriptor? {
    return accessQueue.sync {
      return messageDescriptors[fullName]
    }
  }

  /// Finds EnumDescriptor by full name.
  ///
  /// - Parameter fullName: Full enum name.
  /// - Returns: EnumDescriptor or nil if not found.
  public func findEnum(named fullName: String) -> EnumDescriptor? {
    return accessQueue.sync {
      return enumDescriptors[fullName]
    }
  }

  /// Finds ServiceDescriptor by full name.
  ///
  /// - Parameter fullName: Full service name.
  /// - Returns: ServiceDescriptor or nil if not found.
  public func findService(named fullName: String) -> ServiceDescriptor? {
    return accessQueue.sync {
      return serviceDescriptors[fullName]
    }
  }

  // MARK: - Query Methods

  /// Checks if file is registered.
  ///
  /// - Parameter fileName: File name.
  /// - Returns: true if file is registered.
  public func hasFile(named fileName: String) -> Bool {
    return findFile(named: fileName) != nil
  }

  /// Checks if message is registered.
  ///
  /// - Parameter fullName: Full message name.
  /// - Returns: true if message is registered.
  public func hasMessage(named fullName: String) -> Bool {
    return findMessage(named: fullName) != nil
  }

  /// Checks if enum is registered.
  ///
  /// - Parameter fullName: Full enum name.
  /// - Returns: true if enum is registered.
  public func hasEnum(named fullName: String) -> Bool {
    return findEnum(named: fullName) != nil
  }

  /// Checks if service is registered.
  ///
  /// - Parameter fullName: Full service name.
  /// - Returns: true if service is registered.
  public func hasService(named fullName: String) -> Bool {
    return findService(named: fullName) != nil
  }

  // MARK: - Enumeration Methods

  /// Returns all registered files.
  ///
  /// - Returns: Array of all FileDescriptor.
  public func allFiles() -> [FileDescriptor] {
    return accessQueue.sync {
      return Array(fileDescriptors.values)
    }
  }

  /// Returns all registered messages.
  ///
  /// - Returns: Array of all MessageDescriptor.
  public func allMessages() -> [MessageDescriptor] {
    return accessQueue.sync {
      return Array(messageDescriptors.values)
    }
  }

  /// Returns all registered enums.
  ///
  /// - Returns: Array of all EnumDescriptor.
  public func allEnums() -> [EnumDescriptor] {
    return accessQueue.sync {
      return Array(enumDescriptors.values)
    }
  }

  /// Returns all registered services.
  ///
  /// - Returns: Array of all ServiceDescriptor.
  public func allServices() -> [ServiceDescriptor] {
    return accessQueue.sync {
      return Array(serviceDescriptors.values)
    }
  }

  // MARK: - Dependency Resolution Methods

  /// Resolves dependencies for specified message type.
  ///
  /// Finds all types that this message depends on.
  /// (field types, nested types, etc.)
  ///
  /// - Parameter fullName: Full message name.
  /// - Returns: Array of dependent type full names.
  /// - Throws: `RegistryError.typeNotFound` if message not found
  public func resolveDependencies(for fullName: String) throws -> [String] {
    return try accessQueue.sync {
      guard let messageDescriptor = messageDescriptors[fullName] else {
        throw RegistryError.typeNotFound(fullName)
      }

      var dependencies: Set<String> = []
      collectDependencies(from: messageDescriptor, into: &dependencies)

      return Array(dependencies).sorted()
    }
  }

  /// Recursively collects dependencies from MessageDescriptor.
  private func collectDependencies(from messageDescriptor: MessageDescriptor, into dependencies: inout Set<String>) {
    // Collect dependencies from fields
    for field in messageDescriptor.allFields() {
      if let typeName = field.typeName, !typeName.isEmpty {
        dependencies.insert(typeName)

        // Recursively process messages
        if let nestedMessage = messageDescriptors[typeName] {
          collectDependencies(from: nestedMessage, into: &dependencies)
        }
      }
    }

    // Add nested types
    for (_, nestedMessage) in messageDescriptor.nestedMessages {
      dependencies.insert(nestedMessage.fullName)
      collectDependencies(from: nestedMessage, into: &dependencies)
    }

    for (_, nestedEnum) in messageDescriptor.nestedEnums {
      dependencies.insert(nestedEnum.fullName)
    }
  }

  // MARK: - Clear Methods

  /// Clears all registered types.
  public func clear() {
    accessQueue.sync(flags: .barrier) {
      fileDescriptors.removeAll()
      messageDescriptors.removeAll()
      enumDescriptors.removeAll()
      serviceDescriptors.removeAll()
    }
  }

  /// Removes specific file and all related types.
  ///
  /// - Parameter fileName: File name to remove.
  /// - Returns: true if file was found and removed.
  public func removeFile(named fileName: String) -> Bool {
    return accessQueue.sync(flags: .barrier) {
      guard let fileDescriptor = fileDescriptors.removeValue(forKey: fileName) else {
        return false
      }

      // Remove all types from this file
      removeTypesFromFile(fileDescriptor)
      return true
    }
  }

  /// Removes all types belonging to specified file.
  private func removeTypesFromFile(_ fileDescriptor: FileDescriptor) {
    // Remove messages from file
    for (_, messageDescriptor) in fileDescriptor.messages {
      removeMessageRecursively(messageDescriptor)
    }

    // Remove enums from file
    for (_, enumDescriptor) in fileDescriptor.enums {
      enumDescriptors.removeValue(forKey: enumDescriptor.fullName)
    }

    // Remove services from file
    for (_, serviceDescriptor) in fileDescriptor.services {
      serviceDescriptors.removeValue(forKey: serviceDescriptor.fullName)
    }
  }

  /// Recursively removes message and all its nested types.
  private func removeMessageRecursively(_ messageDescriptor: MessageDescriptor) {
    // Remove the message itself
    messageDescriptors.removeValue(forKey: messageDescriptor.fullName)

    // Remove nested messages
    for (_, nestedMessage) in messageDescriptor.nestedMessages {
      removeMessageRecursively(nestedMessage)
    }

    // Remove nested enums
    for (_, nestedEnum) in messageDescriptor.nestedEnums {
      enumDescriptors.removeValue(forKey: nestedEnum.fullName)
    }
  }
}

// MARK: - RegistryError

/// TypeRegistry errors.
public enum RegistryError: Error, Equatable {
  /// File already registered.
  case duplicateFile(String)

  /// Type already registered.
  case duplicateType(String)

  /// Type not found.
  case typeNotFound(String)
}

extension RegistryError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .duplicateFile(let fileName):
      return "File '\(fileName)' is already registered"
    case .duplicateType(let typeName):
      return "Type '\(typeName)' is already registered"
    case .typeNotFound(let typeName):
      return "Type '\(typeName)' was not found in registry"
    }
  }
}
