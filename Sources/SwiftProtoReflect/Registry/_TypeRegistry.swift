//
// _TypeRegistry.swift
// SwiftProtoReflect
//
// Created: 2025-05-24
//

import Foundation

// @unchecked Sendable: all mutations serialised on `accessQueue` (concurrent reads, barrier writes)
internal final class _TypeRegistry: @unchecked Sendable {

  // MARK: - Properties

  private var fileDescriptors: [String: _FileDescriptor] = [:]
  private var messageDescriptors: [String: _MessageDescriptor] = [:]
  private var enumDescriptors: [String: _EnumDescriptor] = [:]
  private var serviceDescriptors: [String: _ServiceDescriptor] = [:]
  private let accessQueue = DispatchQueue(label: "com.swiftprotoreflect.typeregistry", attributes: .concurrent)

  // MARK: - Initialization

  init() {}

  // MARK: - File Registration

  func registerFile(_ fileDescriptor: _FileDescriptor) throws {
    try accessQueue.sync(flags: .barrier) {
      if fileDescriptors[fileDescriptor.name] != nil {
        throw _RegistryError.duplicateFile(fileDescriptor.name)
      }
      fileDescriptors[fileDescriptor.name] = fileDescriptor
      try registerTypesFromFile(fileDescriptor)
    }
  }

  private func registerTypesFromFile(_ fileDescriptor: _FileDescriptor) throws {
    for (_, messageDescriptor) in fileDescriptor.messages {
      try registerMessageRecursively(messageDescriptor)
    }
    for (_, enumDescriptor) in fileDescriptor.enums {
      if enumDescriptors[enumDescriptor.fullName] != nil {
        throw _RegistryError.duplicateType(enumDescriptor.fullName)
      }
      enumDescriptors[enumDescriptor.fullName] = enumDescriptor
    }
    for (_, serviceDescriptor) in fileDescriptor.services {
      if serviceDescriptors[serviceDescriptor.fullName] != nil {
        throw _RegistryError.duplicateType(serviceDescriptor.fullName)
      }
      serviceDescriptors[serviceDescriptor.fullName] = serviceDescriptor
    }
  }

  private func registerMessageRecursively(_ messageDescriptor: _MessageDescriptor) throws {
    if messageDescriptors[messageDescriptor.fullName] != nil {
      throw _RegistryError.duplicateType(messageDescriptor.fullName)
    }
    messageDescriptors[messageDescriptor.fullName] = messageDescriptor
    for (_, nestedMessage) in messageDescriptor.nestedMessages {
      try registerMessageRecursively(nestedMessage)
    }
    for (_, nestedEnum) in messageDescriptor.nestedEnums {
      if enumDescriptors[nestedEnum.fullName] != nil {
        throw _RegistryError.duplicateType(nestedEnum.fullName)
      }
      enumDescriptors[nestedEnum.fullName] = nestedEnum
    }
  }

  // MARK: - Direct Type Registration

  func registerMessage(_ messageDescriptor: _MessageDescriptor) throws {
    try accessQueue.sync(flags: .barrier) {
      try registerMessageRecursively(messageDescriptor)
    }
  }

  func registerEnum(_ enumDescriptor: _EnumDescriptor) throws {
    try accessQueue.sync(flags: .barrier) {
      if enumDescriptors[enumDescriptor.fullName] != nil {
        throw _RegistryError.duplicateType(enumDescriptor.fullName)
      }
      enumDescriptors[enumDescriptor.fullName] = enumDescriptor
    }
  }

  func registerService(_ serviceDescriptor: _ServiceDescriptor) throws {
    try accessQueue.sync(flags: .barrier) {
      if serviceDescriptors[serviceDescriptor.fullName] != nil {
        throw _RegistryError.duplicateType(serviceDescriptor.fullName)
      }
      serviceDescriptors[serviceDescriptor.fullName] = serviceDescriptor
    }
  }

  // MARK: - Lookup

  func findFile(named fileName: String) -> _FileDescriptor? {
    accessQueue.sync { fileDescriptors[fileName] }
  }

  func findMessage(named fullName: String) -> _MessageDescriptor? {
    accessQueue.sync { messageDescriptors[fullName] }
  }

  func findEnum(named fullName: String) -> _EnumDescriptor? {
    accessQueue.sync { enumDescriptors[fullName] }
  }

  func findService(named fullName: String) -> _ServiceDescriptor? {
    accessQueue.sync { serviceDescriptors[fullName] }
  }

  func syntaxForType(_ fullName: String) -> String? {
    findMessage(named: fullName)?.syntax
  }

  func findExtension(forMessage messageFullName: String, fieldNumber: Int) -> _FieldDescriptor? {
    findMessage(named: messageFullName)?.extensions[fieldNumber]
  }

  // MARK: - Query

  func hasFile(named fileName: String) -> Bool {
    findFile(named: fileName) != nil
  }

  func hasMessage(named fullName: String) -> Bool {
    findMessage(named: fullName) != nil
  }

  func hasEnum(named fullName: String) -> Bool {
    findEnum(named: fullName) != nil
  }

  func hasService(named fullName: String) -> Bool {
    findService(named: fullName) != nil
  }

  // MARK: - Enumeration

  func allFiles() -> [_FileDescriptor] {
    accessQueue.sync { Array(fileDescriptors.values) }
  }

  func allMessages() -> [_MessageDescriptor] {
    accessQueue.sync { Array(messageDescriptors.values) }
  }

  func allEnums() -> [_EnumDescriptor] {
    accessQueue.sync { Array(enumDescriptors.values) }
  }

  func allServices() -> [_ServiceDescriptor] {
    accessQueue.sync { Array(serviceDescriptors.values) }
  }

  // MARK: - Dependency Resolution

  func resolveDependencies(for fullName: String) throws -> [String] {
    return try accessQueue.sync {
      guard let messageDescriptor = messageDescriptors[fullName] else {
        throw _RegistryError.typeNotFound(fullName)
      }
      var dependencies: Set<String> = []
      collectDependencies(from: messageDescriptor, into: &dependencies)
      return Array(dependencies).sorted()
    }
  }

  private func collectDependencies(from messageDescriptor: _MessageDescriptor, into dependencies: inout Set<String>) {
    for field in messageDescriptor.allFields() {
      if let typeName = field.typeName, !typeName.isEmpty {
        dependencies.insert(typeName)
        if let nestedMessage = messageDescriptors[typeName] {
          collectDependencies(from: nestedMessage, into: &dependencies)
        }
      }
    }
    for (_, nestedMessage) in messageDescriptor.nestedMessages {
      dependencies.insert(nestedMessage.fullName)
      collectDependencies(from: nestedMessage, into: &dependencies)
    }
    for (_, nestedEnum) in messageDescriptor.nestedEnums {
      dependencies.insert(nestedEnum.fullName)
    }
  }

  // MARK: - Clear / Remove

  func clear() {
    accessQueue.sync(flags: .barrier) {
      fileDescriptors.removeAll()
      messageDescriptors.removeAll()
      enumDescriptors.removeAll()
      serviceDescriptors.removeAll()
    }
  }

  func removeFile(named fileName: String) -> Bool {
    return accessQueue.sync(flags: .barrier) {
      guard let fileDescriptor = fileDescriptors.removeValue(forKey: fileName) else {
        return false
      }
      removeTypesFromFile(fileDescriptor)
      return true
    }
  }

  private func removeTypesFromFile(_ fileDescriptor: _FileDescriptor) {
    for (_, messageDescriptor) in fileDescriptor.messages {
      removeMessageRecursively(messageDescriptor)
    }
    for (_, enumDescriptor) in fileDescriptor.enums {
      enumDescriptors.removeValue(forKey: enumDescriptor.fullName)
    }
    for (_, serviceDescriptor) in fileDescriptor.services {
      serviceDescriptors.removeValue(forKey: serviceDescriptor.fullName)
    }
  }

  private func removeMessageRecursively(_ messageDescriptor: _MessageDescriptor) {
    messageDescriptors.removeValue(forKey: messageDescriptor.fullName)
    for (_, nestedMessage) in messageDescriptor.nestedMessages {
      removeMessageRecursively(nestedMessage)
    }
    for (_, nestedEnum) in messageDescriptor.nestedEnums {
      enumDescriptors.removeValue(forKey: nestedEnum.fullName)
    }
  }
}

// MARK: - _RegistryError

internal enum _RegistryError: Error, Equatable {
  case duplicateFile(String)
  case duplicateType(String)
  case typeNotFound(String)
}

extension _RegistryError: LocalizedError {
  var errorDescription: String? {
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
