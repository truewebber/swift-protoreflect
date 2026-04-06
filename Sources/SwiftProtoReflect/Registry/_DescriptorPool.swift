//
// _DescriptorPool.swift
// SwiftProtoReflect
//
// Created: 2025-05-24
//

import Foundation

// @unchecked Sendable: all mutations serialised on `accessQueue` (concurrent reads, barrier writes)
internal final class _DescriptorPool: @unchecked Sendable {

  // MARK: - Properties

  private var fileDescriptors: [String: _FileDescriptor] = [:]
  private var messageDescriptors: [String: _MessageDescriptor] = [:]
  private var enumDescriptors: [String: _EnumDescriptor] = [:]
  private var serviceDescriptors: [String: _ServiceDescriptor] = [:]
  private var fieldDescriptors: [String: _FieldDescriptor] = [:]
  private let accessQueue = DispatchQueue(label: "com.swiftprotoreflect.descriptorpool", attributes: .concurrent)
  private let includeBuiltinDescriptors: Bool

  // MARK: - Initialization

  init(includeBuiltinDescriptors: Bool = true) {
    self.includeBuiltinDescriptors = includeBuiltinDescriptors
    if includeBuiltinDescriptors {
      setupBuiltinDescriptors()
    }
  }

  // MARK: - FileDescriptor Management

  func addFileDescriptor(_ fileDescriptor: _FileDescriptor) throws {
    try accessQueue.sync(flags: .barrier) {
      if fileDescriptors[fileDescriptor.name] != nil {
        throw _DescriptorPoolError.duplicateFile(fileDescriptor.name)
      }
      fileDescriptors[fileDescriptor.name] = fileDescriptor
      try extractDescriptorsFromFile(fileDescriptor)
    }
  }

  private func extractDescriptorsFromFile(_ fileDescriptor: _FileDescriptor) throws {
    for (_, messageDescriptor) in fileDescriptor.messages {
      try addMessageDescriptorRecursively(messageDescriptor)
    }
    for (_, enumDescriptor) in fileDescriptor.enums {
      if enumDescriptors[enumDescriptor.fullName] != nil {
        throw _DescriptorPoolError.duplicateSymbol(enumDescriptor.fullName)
      }
      enumDescriptors[enumDescriptor.fullName] = enumDescriptor
    }
    for (_, serviceDescriptor) in fileDescriptor.services {
      if serviceDescriptors[serviceDescriptor.fullName] != nil {
        throw _DescriptorPoolError.duplicateSymbol(serviceDescriptor.fullName)
      }
      serviceDescriptors[serviceDescriptor.fullName] = serviceDescriptor
    }
  }

  private func addMessageDescriptorRecursively(_ messageDescriptor: _MessageDescriptor) throws {
    if messageDescriptors[messageDescriptor.fullName] != nil {
      throw _DescriptorPoolError.duplicateSymbol(messageDescriptor.fullName)
    }
    messageDescriptors[messageDescriptor.fullName] = messageDescriptor
    for field in messageDescriptor.allFields() {
      let fieldFullName = "\(messageDescriptor.fullName).\(field.name)"
      fieldDescriptors[fieldFullName] = field
    }
    for (_, nestedMessage) in messageDescriptor.nestedMessages {
      try addMessageDescriptorRecursively(nestedMessage)
    }
    for (_, nestedEnum) in messageDescriptor.nestedEnums {
      if enumDescriptors[nestedEnum.fullName] != nil {
        throw _DescriptorPoolError.duplicateSymbol(nestedEnum.fullName)
      }
      enumDescriptors[nestedEnum.fullName] = nestedEnum
    }
  }

  // MARK: - Lookup

  func findFileDescriptor(named fileName: String) -> _FileDescriptor? {
    accessQueue.sync { fileDescriptors[fileName] }
  }

  func findMessageDescriptor(named fullName: String) -> _MessageDescriptor? {
    accessQueue.sync { messageDescriptors[fullName] }
  }

  func findEnumDescriptor(named fullName: String) -> _EnumDescriptor? {
    accessQueue.sync { enumDescriptors[fullName] }
  }

  func findServiceDescriptor(named fullName: String) -> _ServiceDescriptor? {
    accessQueue.sync { serviceDescriptors[fullName] }
  }

  func findFieldDescriptor(named fullName: String) -> _FieldDescriptor? {
    accessQueue.sync { fieldDescriptors[fullName] }
  }

  func findFileContainingSymbol(_ symbolName: String) -> _FileDescriptor? {
    return accessQueue.sync {
      if let messageDescriptor = messageDescriptors[symbolName] {
        return fileDescriptors[messageDescriptor.fileDescriptorPath ?? ""]
      }
      if let enumDescriptor = enumDescriptors[symbolName] {
        return fileDescriptors[enumDescriptor.fileDescriptorPath ?? ""]
      }
      if let serviceDescriptor = serviceDescriptors[symbolName] {
        return fileDescriptors[serviceDescriptor.fileDescriptorPath ?? ""]
      }
      return nil
    }
  }

  // MARK: - Factory Integration

  func createMessage(forType typeName: String) -> _DynamicMessage? {
    guard let descriptor = findMessageDescriptor(named: typeName) else { return nil }
    let factory = _MessageFactory()
    return factory.createMessage(from: descriptor)
  }

  func createMessage(forType typeName: String, fieldValues: [String: Any]) throws -> _DynamicMessage? {
    guard let descriptor = findMessageDescriptor(named: typeName) else { return nil }
    let factory = _MessageFactory()
    return try factory.createMessage(from: descriptor, with: fieldValues)
  }

  // MARK: - Discovery

  func allMessageTypeNames() -> [String] {
    accessQueue.sync { Array(messageDescriptors.keys).sorted() }
  }

  func allEnumTypeNames() -> [String] {
    accessQueue.sync { Array(enumDescriptors.keys).sorted() }
  }

  func allServiceNames() -> [String] {
    accessQueue.sync { Array(serviceDescriptors.keys).sorted() }
  }

  func allFileNames() -> [String] {
    accessQueue.sync { Array(fileDescriptors.keys).sorted() }
  }

  // MARK: - Dependency Resolution

  func findDependencies(for typeName: String) throws -> [String] {
    return try accessQueue.sync {
      guard let messageDescriptor = messageDescriptors[typeName] else {
        throw _DescriptorPoolError.symbolNotFound(typeName)
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

  // MARK: - Built-in Descriptors

  private func setupBuiltinDescriptors() {
    var googleProtobufFile = _FileDescriptor(
      name: "google/protobuf/descriptor.proto",
      package: "google.protobuf"
    )
    setupWellKnownTypes(&googleProtobufFile)
    try? addFileDescriptor(googleProtobufFile)
  }

  private func setupWellKnownTypes(_ file: inout _FileDescriptor) {
    var anyMessage = _MessageDescriptor(name: "Any", parent: file)
    anyMessage.addField(_FieldDescriptor(name: "type_url", number: 1, type: .string))
    anyMessage.addField(_FieldDescriptor(name: "value", number: 2, type: .bytes))
    file.addMessage(anyMessage)

    var timestampMessage = _MessageDescriptor(name: "Timestamp", parent: file)
    timestampMessage.addField(_FieldDescriptor(name: "seconds", number: 1, type: .int64))
    timestampMessage.addField(_FieldDescriptor(name: "nanos", number: 2, type: .int32))
    file.addMessage(timestampMessage)

    var durationMessage = _MessageDescriptor(name: "Duration", parent: file)
    durationMessage.addField(_FieldDescriptor(name: "seconds", number: 1, type: .int64))
    durationMessage.addField(_FieldDescriptor(name: "nanos", number: 2, type: .int32))
    file.addMessage(durationMessage)

    let emptyMessage = _MessageDescriptor(name: "Empty", parent: file)
    file.addMessage(emptyMessage)
  }

  // MARK: - Clear

  func clear() {
    accessQueue.sync(flags: .barrier) {
      fileDescriptors.removeAll()
      messageDescriptors.removeAll()
      enumDescriptors.removeAll()
      serviceDescriptors.removeAll()
      fieldDescriptors.removeAll()
    }
  }
}

// MARK: - _DescriptorPoolError

internal enum _DescriptorPoolError: Error, Equatable {
  case duplicateFile(String)
  case duplicateSymbol(String)
  case symbolNotFound(String)
  case invalidDescriptor(String)
}

extension _DescriptorPoolError: LocalizedError {
  var errorDescription: String? {
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
