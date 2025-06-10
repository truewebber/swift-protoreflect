//
// DescriptorPool.swift
// SwiftProtoReflect
//
// Created: 2025-05-24
//

import Foundation
import SwiftProtobuf

/// DescriptorPool.
///
/// Container for dynamic creation and management of Protocol Buffers descriptors at runtime.
/// DescriptorPool is used for working with protobuf types that cannot be predefined in advance.
/// This is a lower-level component compared to TypeRegistry, designed for dynamic work
/// with descriptors and creating messages from FileDescriptorProto.
///
/// ## Main capabilities:
/// - Dynamic creation of descriptors from FileDescriptorProto.
/// - Support for builtin descriptors for standard Protocol Buffers types.
/// - Descriptor lookup by various criteria.
/// - Building dependency chains between descriptors.
/// - Thread-safe operations for safe use in multithreaded environment.
/// - Integration with MessageFactory for creating dynamic messages.
public class DescriptorPool {
  // MARK: - Properties

  /// Pool of file descriptors by name.
  private var fileDescriptors: [String: FileDescriptor] = [:]

  /// Pool of message descriptors by full name.
  private var messageDescriptors: [String: MessageDescriptor] = [:]

  /// Pool of enum descriptors by full name.
  private var enumDescriptors: [String: EnumDescriptor] = [:]

  /// Pool of service descriptors by full name.
  private var serviceDescriptors: [String: ServiceDescriptor] = [:]

  /// Pool of field descriptors by full name.
  private var fieldDescriptors: [String: FieldDescriptor] = [:]

  /// Queue for thread-safe operations.
  private let accessQueue = DispatchQueue(label: "com.swiftprotoreflect.descriptorpool", attributes: .concurrent)

  /// Whether pool includes built-in descriptors for standard types.
  private let includeBuiltinDescriptors: Bool

  // MARK: - Initialization

  /// Creates a new DescriptorPool instance.
  ///
  /// - Parameter includeBuiltinDescriptors: If true, adds built-in descriptors for standard Protocol Buffers types.
  public init(includeBuiltinDescriptors: Bool = true) {
    self.includeBuiltinDescriptors = includeBuiltinDescriptors

    if includeBuiltinDescriptors {
      setupBuiltinDescriptors()
    }
  }

  // MARK: - FileDescriptor Management

  /// Adds FileDescriptor to pool.
  ///
  /// Automatically extracts and registers all type descriptors from file.
  ///
  /// - Parameter fileDescriptor: File descriptor to add.
  /// - Throws: `DescriptorPoolError.duplicateFile` if file already exists
  /// - Throws: `DescriptorPoolError.duplicateSymbol` if any symbol already exists
  public func addFileDescriptor(_ fileDescriptor: FileDescriptor) throws {
    try accessQueue.sync(flags: .barrier) {
      // Check for duplicate files
      if fileDescriptors[fileDescriptor.name] != nil {
        throw DescriptorPoolError.duplicateFile(fileDescriptor.name)
      }

      // Register file
      fileDescriptors[fileDescriptor.name] = fileDescriptor

      // Extract and register all descriptors from file
      try extractDescriptorsFromFile(fileDescriptor)
    }
  }

  /// Extracts all descriptors from FileDescriptor and adds them to pool.
  private func extractDescriptorsFromFile(_ fileDescriptor: FileDescriptor) throws {
    // Extract messages
    for (_, messageDescriptor) in fileDescriptor.messages {
      try addMessageDescriptorRecursively(messageDescriptor)
    }

    // Extract enums
    for (_, enumDescriptor) in fileDescriptor.enums {
      if enumDescriptors[enumDescriptor.fullName] != nil {
        throw DescriptorPoolError.duplicateSymbol(enumDescriptor.fullName)
      }
      enumDescriptors[enumDescriptor.fullName] = enumDescriptor
    }

    // Extract services
    for (_, serviceDescriptor) in fileDescriptor.services {
      if serviceDescriptors[serviceDescriptor.fullName] != nil {
        throw DescriptorPoolError.duplicateSymbol(serviceDescriptor.fullName)
      }
      serviceDescriptors[serviceDescriptor.fullName] = serviceDescriptor
    }
  }

  /// Recursively adds MessageDescriptor and all its nested types.
  private func addMessageDescriptorRecursively(_ messageDescriptor: MessageDescriptor) throws {
    // Check for duplicates
    if messageDescriptors[messageDescriptor.fullName] != nil {
      throw DescriptorPoolError.duplicateSymbol(messageDescriptor.fullName)
    }

    // Add the message itself
    messageDescriptors[messageDescriptor.fullName] = messageDescriptor

    // Add message fields
    for field in messageDescriptor.allFields() {
      let fieldFullName = "\(messageDescriptor.fullName).\(field.name)"
      fieldDescriptors[fieldFullName] = field
    }

    // Recursively add nested messages
    for (_, nestedMessage) in messageDescriptor.nestedMessages {
      try addMessageDescriptorRecursively(nestedMessage)
    }

    // Add nested enums
    for (_, nestedEnum) in messageDescriptor.nestedEnums {
      if enumDescriptors[nestedEnum.fullName] != nil {
        throw DescriptorPoolError.duplicateSymbol(nestedEnum.fullName)
      }
      enumDescriptors[nestedEnum.fullName] = nestedEnum
    }
  }

  // MARK: - Lookup Methods

  /// Finds FileDescriptor by file name.
  ///
  /// - Parameter fileName: File name.
  /// - Returns: FileDescriptor or nil if not found.
  public func findFileDescriptor(named fileName: String) -> FileDescriptor? {
    return accessQueue.sync {
      return fileDescriptors[fileName]
    }
  }

  /// Finds MessageDescriptor by full name.
  ///
  /// - Parameter fullName: Full message name.
  /// - Returns: MessageDescriptor or nil if not found.
  public func findMessageDescriptor(named fullName: String) -> MessageDescriptor? {
    return accessQueue.sync {
      return messageDescriptors[fullName]
    }
  }

  /// Finds EnumDescriptor by full name.
  ///
  /// - Parameter fullName: Full enum name.
  /// - Returns: EnumDescriptor or nil if not found.
  public func findEnumDescriptor(named fullName: String) -> EnumDescriptor? {
    return accessQueue.sync {
      return enumDescriptors[fullName]
    }
  }

  /// Finds ServiceDescriptor by full name.
  ///
  /// - Parameter fullName: Full service name.
  /// - Returns: ServiceDescriptor or nil if not found.
  public func findServiceDescriptor(named fullName: String) -> ServiceDescriptor? {
    return accessQueue.sync {
      return serviceDescriptors[fullName]
    }
  }

  /// Finds FieldDescriptor by full name.
  ///
  /// - Parameter fullName: Full field name (including containing message name).
  /// - Returns: FieldDescriptor or nil if not found.
  public func findFieldDescriptor(named fullName: String) -> FieldDescriptor? {
    return accessQueue.sync {
      return fieldDescriptors[fullName]
    }
  }

  /// Finds FileDescriptor containing specified symbol.
  ///
  /// - Parameter symbolName: Symbol name to search for.
  /// - Returns: FileDescriptor containing symbol or nil if not found.
  public func findFileContainingSymbol(_ symbolName: String) -> FileDescriptor? {
    return accessQueue.sync {
      // Search among messages
      if let messageDescriptor = messageDescriptors[symbolName] {
        return fileDescriptors[messageDescriptor.fileDescriptorPath ?? ""]
      }

      // Search among enums
      if let enumDescriptor = enumDescriptors[symbolName] {
        return fileDescriptors[enumDescriptor.fileDescriptorPath ?? ""]
      }

      // Search among services
      if let serviceDescriptor = serviceDescriptors[symbolName] {
        return fileDescriptors[serviceDescriptor.fileDescriptorPath ?? ""]
      }

      return nil
    }
  }

  // MARK: - Factory Integration Methods

  /// Creates DynamicMessage for specified type using MessageFactory.
  ///
  /// - Parameter typeName: Full message type name.
  /// - Returns: New DynamicMessage or nil if type not found.
  public func createMessage(forType typeName: String) -> DynamicMessage? {
    guard let descriptor = findMessageDescriptor(named: typeName) else {
      return nil
    }

    let factory = MessageFactory()
    return factory.createMessage(from: descriptor)
  }

  /// Creates DynamicMessage with pre-filled values.
  ///
  /// - Parameters:
  ///   - typeName: Full message type name.
  ///   - fieldValues: Dictionary of field values.
  /// - Returns: New DynamicMessage with set values or nil if type not found.
  /// - Throws: Creation or field value setting errors.
  public func createMessage(forType typeName: String, fieldValues: [String: Any]) throws -> DynamicMessage? {
    guard let descriptor = findMessageDescriptor(named: typeName) else {
      return nil
    }

    let factory = MessageFactory()
    return try factory.createMessage(from: descriptor, with: fieldValues)
  }

  // MARK: - Discovery Methods

  /// Returns all known message type names.
  ///
  /// - Returns: Array of full names of all registered message types.
  public func allMessageTypeNames() -> [String] {
    return accessQueue.sync {
      return Array(messageDescriptors.keys).sorted()
    }
  }

  /// Returns all known enum type names.
  ///
  /// - Returns: Array of full names of all registered enum types.
  public func allEnumTypeNames() -> [String] {
    return accessQueue.sync {
      return Array(enumDescriptors.keys).sorted()
    }
  }

  /// Returns all known service names.
  ///
  /// - Returns: Array of full names of all registered services.
  public func allServiceNames() -> [String] {
    return accessQueue.sync {
      return Array(serviceDescriptors.keys).sorted()
    }
  }

  /// Returns all known file names.
  ///
  /// - Returns: Array of names of all registered files.
  public func allFileNames() -> [String] {
    return accessQueue.sync {
      return Array(fileDescriptors.keys).sorted()
    }
  }

  // MARK: - Dependency Resolution

  /// Finds all dependencies for specified type.
  ///
  /// - Parameter typeName: Full type name.
  /// - Returns: Array of full names of all dependent types.
  /// - Throws: `DescriptorPoolError.symbolNotFound` if type not found
  public func findDependencies(for typeName: String) throws -> [String] {
    return try accessQueue.sync {
      guard let messageDescriptor = messageDescriptors[typeName] else {
        throw DescriptorPoolError.symbolNotFound(typeName)
      }

      var dependencies: Set<String> = []
      collectDependencies(from: messageDescriptor, into: &dependencies)

      return Array(dependencies).sorted()
    }
  }

  /// Recursively collects dependencies.
  private func collectDependencies(from messageDescriptor: MessageDescriptor, into dependencies: inout Set<String>) {
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

  // MARK: - Built-in Descriptors

  /// Sets up built-in descriptors for standard Protocol Buffers types.
  private func setupBuiltinDescriptors() {
    // Create file for Google built-in types
    var googleProtobufFile = FileDescriptor(
      name: "google/protobuf/descriptor.proto",
      package: "google.protobuf"
    )

    // Add basic well-known types
    setupWellKnownTypes(&googleProtobufFile)

    // Register file (without error checking for built-in types)
    try? addFileDescriptor(googleProtobufFile)
  }

  /// Sets up well-known Google Protocol Buffers types.
  private func setupWellKnownTypes(_ file: inout FileDescriptor) {
    // Any type
    var anyMessage = MessageDescriptor(name: "Any", parent: file)
    anyMessage.addField(FieldDescriptor(name: "type_url", number: 1, type: .string))
    anyMessage.addField(FieldDescriptor(name: "value", number: 2, type: .bytes))
    file.addMessage(anyMessage)

    // Timestamp type
    var timestampMessage = MessageDescriptor(name: "Timestamp", parent: file)
    timestampMessage.addField(FieldDescriptor(name: "seconds", number: 1, type: .int64))
    timestampMessage.addField(FieldDescriptor(name: "nanos", number: 2, type: .int32))
    file.addMessage(timestampMessage)

    // Duration type
    var durationMessage = MessageDescriptor(name: "Duration", parent: file)
    durationMessage.addField(FieldDescriptor(name: "seconds", number: 1, type: .int64))
    durationMessage.addField(FieldDescriptor(name: "nanos", number: 2, type: .int32))
    file.addMessage(durationMessage)

    // Empty type
    let emptyMessage = MessageDescriptor(name: "Empty", parent: file)
    file.addMessage(emptyMessage)
  }

  // MARK: - Clear Methods

  /// Clears all descriptors from pool.
  public func clear() {
    accessQueue.sync(flags: .barrier) {
      fileDescriptors.removeAll()
      messageDescriptors.removeAll()
      enumDescriptors.removeAll()
      serviceDescriptors.removeAll()
      fieldDescriptors.removeAll()
    }
  }
}

// MARK: - DescriptorPoolError

/// DescriptorPool errors.
public enum DescriptorPoolError: Error, Equatable {
  /// File already exists in pool.
  case duplicateFile(String)

  /// Symbol already exists in pool.
  case duplicateSymbol(String)

  /// Symbol not found in pool.
  case symbolNotFound(String)

  /// Invalid descriptor.
  case invalidDescriptor(String)
}

extension DescriptorPoolError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .duplicateFile(let fileName):
      return "File '\(fileName)' already exists in descriptor pool"
    case .duplicateSymbol(let symbolName):
      return "Symbol '\(symbolName)' already exists in descriptor pool"
    case .symbolNotFound(let symbolName):
      return "Symbol '\(symbolName)' was not found in descriptor pool"
    case .invalidDescriptor(let reason):
      return "Invalid descriptor: \(reason)"
    }
  }
}
