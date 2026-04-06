//
// Registry.swift
// SwiftProtoReflect
//
// Public surface for TypeRegistry and DescriptorPool.
// Internal implementations live in Registry/_TypeRegistry.swift and Registry/_DescriptorPool.swift.
//

import Foundation

// MARK: - RegistryError

/// TypeRegistry errors.
public enum RegistryError: Error, Equatable, Sendable {
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

extension RegistryError {
  init(from impl: _RegistryError) {
    switch impl {
    case .duplicateFile(let s): self = .duplicateFile(s)
    case .duplicateType(let s): self = .duplicateType(s)
    case .typeNotFound(let s): self = .typeNotFound(s)
    }
  }
}

// MARK: - DescriptorPoolError

/// DescriptorPool errors.
public enum DescriptorPoolError: Error, Equatable, Sendable {
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

extension DescriptorPoolError {
  init(from impl: _DescriptorPoolError) {
    switch impl {
    case .duplicateFile(let s): self = .duplicateFile(s)
    case .duplicateSymbol(let s): self = .duplicateSymbol(s)
    case .symbolNotFound(let s): self = .symbolNotFound(s)
    case .invalidDescriptor(let s): self = .invalidDescriptor(s)
    }
  }
}

// MARK: - TypeRegistry

// TODO(Strangler migration / OPE-298): Remove _TypeRegistryStorage, accessQueue, and the three
// private store/remove helpers once TypeRegistry is migrated to an actor. At that point all mutable
// state lives in the actor body and reads delegate directly to `impl` (_TypeRegistry).
// @unchecked Sendable: all mutations serialised on TypeRegistry.accessQueue
private final class _TypeRegistryStorage: @unchecked Sendable {
  var fileDescriptors: [String: FileDescriptor] = [:]
  var messageDescriptors: [String: MessageDescriptor] = [:]
  var enumDescriptors: [String: EnumDescriptor] = [:]
  var serviceDescriptors: [String: ServiceDescriptor] = [:]
}

/// Centralized registry for managing all known Protocol Buffers types.
///
/// Provides registration, lookup and dependency resolution between types.
///
/// ## Main capabilities:
/// - Registration of FileDescriptor, MessageDescriptor, EnumDescriptor, ServiceDescriptor.
/// - Fast type lookup by full name.
/// - Automatic type extraction from FileDescriptor.
/// - Thread-safe operations.
/// - Dependency resolution between types.
public final class TypeRegistry: Sendable {

  private let storage = _TypeRegistryStorage()
  private let accessQueue = DispatchQueue(
    label: "com.swiftprotoreflect.typeregistry",
    attributes: .concurrent
  )

  // TODO(Strangler migration / OPE-298): When Serialization/Bridge/Integration switch to
  // _TypeRegistry directly, remove the sync writes to `impl` and drop `_TypeRegistryStorage`
  // in favour of delegating reads to `impl` (the inverse of the current arrangement).
  // Internal registry kept in sync on every write; currently no internal module reads from it.
  private let impl: _TypeRegistry

  // MARK: - Initialization

  /// Creates a new TypeRegistry instance.
  public init() {
    self.impl = _TypeRegistry()
  }

  /// Creates a new TypeRegistry pre-populated from an array of file descriptors.
  ///
  /// Registers every type found in each file — messages (recursively, including nested),
  /// top-level enums, and services.
  ///
  /// - Parameter fileDescriptors: File descriptors to register.
  /// - Throws: `RegistryError.duplicateFile` if the same file name appears more than once.
  ///           `RegistryError.duplicateType` if the same type full name appears across files.
  public convenience init(fileDescriptors: [FileDescriptor]) throws {
    self.init()
    for file in fileDescriptors {
      try registerFile(file)
    }
  }

  // MARK: - File Registration

  /// Registers FileDescriptor and automatically extracts all types contained in it.
  ///
  /// - Parameter fileDescriptor: File descriptor to register.
  /// - Throws: `RegistryError.duplicateFile` if file is already registered
  public func registerFile(_ fileDescriptor: FileDescriptor) throws {
    try accessQueue.sync(flags: .barrier) {
      do {
        try impl.registerFile(_FileDescriptor(from: fileDescriptor))
      }
      catch let e as _RegistryError {
        throw RegistryError(from: e)
      }
      storage.fileDescriptors[fileDescriptor.name] = fileDescriptor
      for (_, msg) in fileDescriptor.messages {
        storeMessage(msg)
      }
      for (_, enm) in fileDescriptor.enums {
        storage.enumDescriptors[enm.fullName] = enm
      }
      for (_, svc) in fileDescriptor.services {
        storage.serviceDescriptors[svc.fullName] = svc
      }
    }
  }

  private func storeMessage(_ message: MessageDescriptor) {
    storage.messageDescriptors[message.fullName] = message
    for (_, nested) in message.nestedMessages {
      storeMessage(nested)
    }
    for (_, nestedEnum) in message.nestedEnums {
      storage.enumDescriptors[nestedEnum.fullName] = nestedEnum
    }
  }

  // MARK: - Direct Type Registration

  /// Registers MessageDescriptor directly.
  ///
  /// - Parameter messageDescriptor: Message descriptor.
  /// - Throws: `RegistryError.duplicateType` if type is already registered
  public func registerMessage(_ messageDescriptor: MessageDescriptor) throws {
    try accessQueue.sync(flags: .barrier) {
      do {
        try impl.registerMessage(_MessageDescriptor(from: messageDescriptor))
      }
      catch let e as _RegistryError {
        throw RegistryError(from: e)
      }
      storeMessage(messageDescriptor)
    }
  }

  /// Registers EnumDescriptor directly.
  ///
  /// - Parameter enumDescriptor: Enum descriptor.
  /// - Throws: `RegistryError.duplicateType` if type is already registered
  public func registerEnum(_ enumDescriptor: EnumDescriptor) throws {
    try accessQueue.sync(flags: .barrier) {
      do {
        try impl.registerEnum(_EnumDescriptor(from: enumDescriptor))
      }
      catch let e as _RegistryError {
        throw RegistryError(from: e)
      }
      storage.enumDescriptors[enumDescriptor.fullName] = enumDescriptor
    }
  }

  /// Registers ServiceDescriptor directly.
  ///
  /// - Parameter serviceDescriptor: Service descriptor.
  /// - Throws: `RegistryError.duplicateType` if type is already registered
  public func registerService(_ serviceDescriptor: ServiceDescriptor) throws {
    try accessQueue.sync(flags: .barrier) {
      do {
        try impl.registerService(_ServiceDescriptor(from: serviceDescriptor))
      }
      catch let e as _RegistryError {
        throw RegistryError(from: e)
      }
      storage.serviceDescriptors[serviceDescriptor.fullName] = serviceDescriptor
    }
  }

  // MARK: - Lookup

  /// Finds FileDescriptor by file name.
  ///
  /// - Parameter fileName: File name.
  /// - Returns: FileDescriptor or nil if not found.
  public func findFile(named fileName: String) -> FileDescriptor? {
    accessQueue.sync { storage.fileDescriptors[fileName] }
  }

  /// Finds MessageDescriptor by full name.
  ///
  /// - Parameter fullName: Full message name.
  /// - Returns: MessageDescriptor or nil if not found.
  public func findMessage(named fullName: String) -> MessageDescriptor? {
    accessQueue.sync { storage.messageDescriptors[fullName] }
  }

  /// Finds EnumDescriptor by full name.
  ///
  /// - Parameter fullName: Full enum name.
  /// - Returns: EnumDescriptor or nil if not found.
  public func findEnum(named fullName: String) -> EnumDescriptor? {
    accessQueue.sync { storage.enumDescriptors[fullName] }
  }

  /// Finds ServiceDescriptor by full name.
  ///
  /// - Parameter fullName: Full service name.
  /// - Returns: ServiceDescriptor or nil if not found.
  public func findService(named fullName: String) -> ServiceDescriptor? {
    accessQueue.sync { storage.serviceDescriptors[fullName] }
  }

  // MARK: - Proto2-aware Lookup

  /// Returns the syntax of a registered message type.
  ///
  /// - Parameter fullName: Full message name.
  /// - Returns: Syntax string (`"proto2"` or `"proto3"`) or nil if not found.
  public func syntaxForType(_ fullName: String) -> String? {
    findMessage(named: fullName)?.syntax
  }

  /// Finds an extension field descriptor for a registered message.
  ///
  /// - Parameters:
  ///   - messageFullName: Full name of the message that declares the extension range.
  ///   - fieldNumber: Extension field number.
  /// - Returns: `FieldDescriptor` for the extension or nil if not found.
  public func findExtension(forMessage messageFullName: String, fieldNumber: Int) -> FieldDescriptor? {
    findMessage(named: messageFullName)?.extensions[fieldNumber]
  }

  // MARK: - Query

  /// Checks if file is registered.
  ///
  /// - Parameter fileName: File name.
  /// - Returns: true if file is registered.
  public func hasFile(named fileName: String) -> Bool {
    findFile(named: fileName) != nil
  }

  /// Checks if message is registered.
  ///
  /// - Parameter fullName: Full message name.
  /// - Returns: true if message is registered.
  public func hasMessage(named fullName: String) -> Bool {
    findMessage(named: fullName) != nil
  }

  /// Checks if enum is registered.
  ///
  /// - Parameter fullName: Full enum name.
  /// - Returns: true if enum is registered.
  public func hasEnum(named fullName: String) -> Bool {
    findEnum(named: fullName) != nil
  }

  /// Checks if service is registered.
  ///
  /// - Parameter fullName: Full service name.
  /// - Returns: true if service is registered.
  public func hasService(named fullName: String) -> Bool {
    findService(named: fullName) != nil
  }

  // MARK: - Enumeration

  /// Returns all registered files.
  ///
  /// - Returns: Array of all FileDescriptor.
  public func allFiles() -> [FileDescriptor] {
    accessQueue.sync { Array(storage.fileDescriptors.values) }
  }

  /// Returns all registered messages.
  ///
  /// - Returns: Array of all MessageDescriptor.
  public func allMessages() -> [MessageDescriptor] {
    accessQueue.sync { Array(storage.messageDescriptors.values) }
  }

  /// Returns all registered enums.
  ///
  /// - Returns: Array of all EnumDescriptor.
  public func allEnums() -> [EnumDescriptor] {
    accessQueue.sync { Array(storage.enumDescriptors.values) }
  }

  /// Returns all registered services.
  ///
  /// - Returns: Array of all ServiceDescriptor.
  public func allServices() -> [ServiceDescriptor] {
    accessQueue.sync { Array(storage.serviceDescriptors.values) }
  }

  // MARK: - Dependency Resolution

  /// Resolves dependencies for specified message type.
  ///
  /// - Parameter fullName: Full message name.
  /// - Returns: Array of dependent type full names.
  /// - Throws: `RegistryError.typeNotFound` if message not found
  public func resolveDependencies(for fullName: String) throws -> [String] {
    do {
      return try impl.resolveDependencies(for: fullName)
    }
    catch let e as _RegistryError {
      throw RegistryError(from: e)
    }
  }

  // MARK: - Clear

  /// Clears all registered types.
  public func clear() {
    accessQueue.sync(flags: .barrier) {
      impl.clear()
      storage.fileDescriptors.removeAll()
      storage.messageDescriptors.removeAll()
      storage.enumDescriptors.removeAll()
      storage.serviceDescriptors.removeAll()
    }
  }

  /// Removes specific file and all related types.
  ///
  /// - Parameter fileName: File name to remove.
  /// - Returns: true if file was found and removed.
  public func removeFile(named fileName: String) -> Bool {
    return accessQueue.sync(flags: .barrier) {
      guard let file = storage.fileDescriptors.removeValue(forKey: fileName) else {
        return false
      }
      let _ = impl.removeFile(named: fileName)
      removeTypesFromStorage(file)
      return true
    }
  }

  private func removeTypesFromStorage(_ fileDescriptor: FileDescriptor) {
    for (_, msg) in fileDescriptor.messages {
      removeMessageFromStorage(msg)
    }
    for (_, enm) in fileDescriptor.enums {
      storage.enumDescriptors.removeValue(forKey: enm.fullName)
    }
    for (_, svc) in fileDescriptor.services {
      storage.serviceDescriptors.removeValue(forKey: svc.fullName)
    }
  }

  private func removeMessageFromStorage(_ message: MessageDescriptor) {
    storage.messageDescriptors.removeValue(forKey: message.fullName)
    for (_, nested) in message.nestedMessages {
      removeMessageFromStorage(nested)
    }
    for (_, nestedEnum) in message.nestedEnums {
      storage.enumDescriptors.removeValue(forKey: nestedEnum.fullName)
    }
  }
}

// MARK: - DescriptorPool

/// Container for dynamic creation and management of Protocol Buffers descriptors at runtime.
///
/// DescriptorPool is used for working with protobuf types that cannot be predefined in advance.
/// This is a lower-level component compared to TypeRegistry, designed for dynamic work
/// with descriptors and creating messages from FileDescriptorProto.
///
/// ## Main capabilities:
/// - Dynamic creation of descriptors from FileDescriptorProto.
/// - Support for builtin descriptors for standard Protocol Buffers types.
/// - Descriptor lookup by various criteria.
/// - Building dependency chains between descriptors.
/// - Thread-safe operations.
/// - Integration with MessageFactory for creating dynamic messages.
public final class DescriptorPool: Sendable {

  private let impl: _DescriptorPool

  // MARK: - Initialization

  /// Creates a new DescriptorPool instance.
  ///
  /// - Parameter includeBuiltinDescriptors: If true, adds built-in descriptors for standard Protocol Buffers types.
  public init(includeBuiltinDescriptors: Bool = true) {
    self.impl = _DescriptorPool(includeBuiltinDescriptors: includeBuiltinDescriptors)
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
    do {
      try impl.addFileDescriptor(_FileDescriptor(from: fileDescriptor))
    }
    catch let e as _DescriptorPoolError {
      throw DescriptorPoolError(from: e)
    }
  }

  // MARK: - Lookup

  /// Finds FileDescriptor by file name.
  ///
  /// - Parameter fileName: File name.
  /// - Returns: FileDescriptor or nil if not found.
  public func findFileDescriptor(named fileName: String) -> FileDescriptor? {
    impl.findFileDescriptor(named: fileName).map { FileDescriptor(from: $0) }
  }

  /// Finds MessageDescriptor by full name.
  ///
  /// - Parameter fullName: Full message name.
  /// - Returns: MessageDescriptor or nil if not found.
  public func findMessageDescriptor(named fullName: String) -> MessageDescriptor? {
    impl.findMessageDescriptor(named: fullName).map { MessageDescriptor(from: $0) }
  }

  /// Finds EnumDescriptor by full name.
  ///
  /// - Parameter fullName: Full enum name.
  /// - Returns: EnumDescriptor or nil if not found.
  public func findEnumDescriptor(named fullName: String) -> EnumDescriptor? {
    impl.findEnumDescriptor(named: fullName).map { EnumDescriptor(from: $0) }
  }

  /// Finds ServiceDescriptor by full name.
  ///
  /// - Parameter fullName: Full service name.
  /// - Returns: ServiceDescriptor or nil if not found.
  public func findServiceDescriptor(named fullName: String) -> ServiceDescriptor? {
    impl.findServiceDescriptor(named: fullName).map { ServiceDescriptor(from: $0) }
  }

  /// Finds FieldDescriptor by full name.
  ///
  /// - Parameter fullName: Full field name (including containing message name).
  /// - Returns: FieldDescriptor or nil if not found.
  public func findFieldDescriptor(named fullName: String) -> FieldDescriptor? {
    impl.findFieldDescriptor(named: fullName).map { FieldDescriptor(from: $0) }
  }

  /// Finds FileDescriptor containing specified symbol.
  ///
  /// - Parameter symbolName: Symbol name to search for.
  /// - Returns: FileDescriptor containing symbol or nil if not found.
  public func findFileContainingSymbol(_ symbolName: String) -> FileDescriptor? {
    impl.findFileContainingSymbol(symbolName).map { FileDescriptor(from: $0) }
  }

  // MARK: - Factory Integration

  /// Creates DynamicMessage for specified type using MessageFactory.
  ///
  /// - Parameter typeName: Full message type name.
  /// - Returns: New DynamicMessage or nil if type not found.
  public func createMessage(forType typeName: String) -> DynamicMessage? {
    impl.createMessage(forType: typeName).map { DynamicMessage(impl: $0) }
  }

  /// Creates DynamicMessage with pre-filled values.
  ///
  /// - Parameters:
  ///   - typeName: Full message type name.
  ///   - fieldValues: Dictionary of field values.
  /// - Returns: New DynamicMessage with set values or nil if type not found.
  /// - Throws: Creation or field value setting errors.
  public func createMessage(forType typeName: String, fieldValues: [String: Any]) throws -> DynamicMessage? {
    try impl.createMessage(forType: typeName, fieldValues: fieldValues).map { DynamicMessage(impl: $0) }
  }

  // MARK: - Discovery

  /// Returns all known message type names.
  ///
  /// - Returns: Array of full names of all registered message types.
  public func allMessageTypeNames() -> [String] {
    impl.allMessageTypeNames()
  }

  /// Returns all known enum type names.
  ///
  /// - Returns: Array of full names of all registered enum types.
  public func allEnumTypeNames() -> [String] {
    impl.allEnumTypeNames()
  }

  /// Returns all known service names.
  ///
  /// - Returns: Array of full names of all registered services.
  public func allServiceNames() -> [String] {
    impl.allServiceNames()
  }

  /// Returns all known file names.
  ///
  /// - Returns: Array of names of all registered files.
  public func allFileNames() -> [String] {
    impl.allFileNames()
  }

  // MARK: - Dependency Resolution

  /// Finds all dependencies for specified type.
  ///
  /// - Parameter typeName: Full type name.
  /// - Returns: Array of full names of all dependent types.
  /// - Throws: `DescriptorPoolError.symbolNotFound` if type not found
  public func findDependencies(for typeName: String) throws -> [String] {
    do {
      return try impl.findDependencies(for: typeName)
    }
    catch let e as _DescriptorPoolError {
      throw DescriptorPoolError(from: e)
    }
  }

  // MARK: - Clear

  /// Clears all descriptors from pool.
  public func clear() {
    impl.clear()
  }
}
