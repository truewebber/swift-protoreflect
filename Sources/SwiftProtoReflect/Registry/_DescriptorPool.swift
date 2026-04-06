//
// _DescriptorPool.swift
// SwiftProtoReflect
//
// Created: 2025-05-24
//

import Foundation

// MARK: - _DescriptorPoolStorage

internal struct _DescriptorPoolStorage {

  // MARK: - Properties

  private var fileDescriptors: [String: _FileDescriptor] = [:]
  private var messageDescriptors: [String: _MessageDescriptor] = [:]
  private var enumDescriptors: [String: _EnumDescriptor] = [:]
  private var serviceDescriptors: [String: _ServiceDescriptor] = [:]
  private var fieldDescriptors: [String: _FieldDescriptor] = [:]

  // MARK: - Initialization

  init(includeBuiltinDescriptors: Bool = true) {
    if includeBuiltinDescriptors {
      setupBuiltinDescriptors()
    }
  }

  // MARK: - FileDescriptor Management

  mutating func addFileDescriptor(_ fileDescriptor: _FileDescriptor) throws {
    if fileDescriptors[fileDescriptor.name] != nil {
      throw _DescriptorPoolError.duplicateFile(fileDescriptor.name)
    }
    fileDescriptors[fileDescriptor.name] = fileDescriptor
    try extractDescriptorsFromFile(fileDescriptor)
  }

  private mutating func extractDescriptorsFromFile(_ fileDescriptor: _FileDescriptor) throws {
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

  private mutating func addMessageDescriptorRecursively(_ messageDescriptor: _MessageDescriptor) throws {
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
    fileDescriptors[fileName]
  }

  func findMessageDescriptor(named fullName: String) -> _MessageDescriptor? {
    messageDescriptors[fullName]
  }

  func findEnumDescriptor(named fullName: String) -> _EnumDescriptor? {
    enumDescriptors[fullName]
  }

  func findServiceDescriptor(named fullName: String) -> _ServiceDescriptor? {
    serviceDescriptors[fullName]
  }

  func findFieldDescriptor(named fullName: String) -> _FieldDescriptor? {
    fieldDescriptors[fullName]
  }

  func findFileContainingSymbol(_ symbolName: String) -> _FileDescriptor? {
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
    Array(messageDescriptors.keys).sorted()
  }

  func allEnumTypeNames() -> [String] {
    Array(enumDescriptors.keys).sorted()
  }

  func allServiceNames() -> [String] {
    Array(serviceDescriptors.keys).sorted()
  }

  func allFileNames() -> [String] {
    Array(fileDescriptors.keys).sorted()
  }

  // MARK: - Dependency Resolution

  func findDependencies(for typeName: String) throws -> [String] {
    guard let messageDescriptor = messageDescriptors[typeName] else {
      throw _DescriptorPoolError.symbolNotFound(typeName)
    }
    var dependencies: Set<String> = []
    collectDependencies(from: messageDescriptor, into: &dependencies)
    return Array(dependencies).sorted()
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

  private mutating func setupBuiltinDescriptors() {
    var googleProtobufFile = _FileDescriptor(
      name: "google/protobuf/descriptor.proto",
      package: "google.protobuf"
    )
    setupWellKnownTypes(&googleProtobufFile)
    try? addFileDescriptor(googleProtobufFile)
  }

  private mutating func setupWellKnownTypes(_ file: inout _FileDescriptor) {
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

  mutating func clear() {
    fileDescriptors.removeAll()
    messageDescriptors.removeAll()
    enumDescriptors.removeAll()
    serviceDescriptors.removeAll()
    fieldDescriptors.removeAll()
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
