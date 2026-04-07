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

/// Centralized registry for managing all known Protocol Buffers types.
///
/// Provides registration, lookup and dependency resolution between types.
///
/// ## Main capabilities:
/// - Registration of FileDescriptor, MessageDescriptor, EnumDescriptor, ServiceDescriptor.
/// - Fast type lookup by full name.
/// - Automatic type extraction from FileDescriptor.
/// - Thread-safe operations via actor isolation.
/// - Dependency resolution between types.
public actor TypeRegistry {

  private var impl: _TypeRegistry

  // Internal accessor so Serialization/Bridge modules can pass a snapshot of the impl directly
  // to _BinaryDeserializer, _JSONSerializer, etc. without going through the public layer.
  var typeRegistryImpl: _TypeRegistry { impl }

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
  public init(fileDescriptors: [FileDescriptor]) async throws {
    self.impl = _TypeRegistry()
    for file in fileDescriptors {
      try registerFileImpl(file)
    }
  }

  // MARK: - File Registration

  /// Registers FileDescriptor and automatically extracts all types contained in it.
  ///
  /// - Parameter fileDescriptor: File descriptor to register.
  /// - Throws: `RegistryError.duplicateFile` if file is already registered
  public func registerFile(_ fileDescriptor: FileDescriptor) throws {
    try registerFileImpl(fileDescriptor)
  }

  private func registerFileImpl(_ fileDescriptor: FileDescriptor) throws {
    do {
      try impl.registerFile(_FileDescriptor(from: fileDescriptor))
    }
    catch let e as _RegistryError {
      throw RegistryError(from: e)
    }
  }

  // MARK: - Direct Type Registration

  /// Registers MessageDescriptor directly.
  ///
  /// - Parameter messageDescriptor: Message descriptor.
  /// - Throws: `RegistryError.duplicateType` if type is already registered
  public func registerMessage(_ messageDescriptor: MessageDescriptor) throws {
    do {
      try impl.registerMessage(_MessageDescriptor(from: messageDescriptor))
    }
    catch let e as _RegistryError {
      throw RegistryError(from: e)
    }
  }

  /// Registers EnumDescriptor directly.
  ///
  /// - Parameter enumDescriptor: Enum descriptor.
  /// - Throws: `RegistryError.duplicateType` if type is already registered
  public func registerEnum(_ enumDescriptor: EnumDescriptor) throws {
    do {
      try impl.registerEnum(_EnumDescriptor(from: enumDescriptor))
    }
    catch let e as _RegistryError {
      throw RegistryError(from: e)
    }
  }

  /// Registers ServiceDescriptor directly.
  ///
  /// - Parameter serviceDescriptor: Service descriptor.
  /// - Throws: `RegistryError.duplicateType` if type is already registered
  public func registerService(_ serviceDescriptor: ServiceDescriptor) throws {
    do {
      try impl.registerService(_ServiceDescriptor(from: serviceDescriptor))
    }
    catch let e as _RegistryError {
      throw RegistryError(from: e)
    }
  }

  // MARK: - Lookup

  /// Finds FileDescriptor by file name.
  ///
  /// - Parameter fileName: File name.
  /// - Returns: FileDescriptor or nil if not found.
  public func findFile(named fileName: String) -> FileDescriptor? {
    impl.findFile(named: fileName).map { FileDescriptor(from: $0) }
  }

  /// Finds MessageDescriptor by full name.
  ///
  /// - Parameter fullName: Full message name.
  /// - Returns: MessageDescriptor or nil if not found.
  public func findMessage(named fullName: String) -> MessageDescriptor? {
    impl.findMessage(named: fullName).map { MessageDescriptor(from: $0) }
  }

  /// Finds EnumDescriptor by full name.
  ///
  /// - Parameter fullName: Full enum name.
  /// - Returns: EnumDescriptor or nil if not found.
  public func findEnum(named fullName: String) -> EnumDescriptor? {
    impl.findEnum(named: fullName).map { EnumDescriptor(from: $0) }
  }

  /// Finds ServiceDescriptor by full name.
  ///
  /// - Parameter fullName: Full service name.
  /// - Returns: ServiceDescriptor or nil if not found.
  public func findService(named fullName: String) -> ServiceDescriptor? {
    impl.findService(named: fullName).map { ServiceDescriptor(from: $0) }
  }

  // MARK: - Proto2-aware Lookup

  /// Returns the syntax of a registered message type.
  ///
  /// - Parameter fullName: Full message name.
  /// - Returns: Syntax string (`"proto2"` or `"proto3"`) or nil if not found.
  public func syntaxForType(_ fullName: String) -> String? {
    impl.syntaxForType(fullName)
  }

  /// Finds an extension field descriptor for a registered message.
  ///
  /// - Parameters:
  ///   - messageFullName: Full name of the message that declares the extension range.
  ///   - fieldNumber: Extension field number.
  /// - Returns: `FieldDescriptor` for the extension or nil if not found.
  public func findExtension(forMessage messageFullName: String, fieldNumber: Int) -> FieldDescriptor? {
    impl.findExtension(forMessage: messageFullName, fieldNumber: fieldNumber).map { FieldDescriptor(from: $0) }
  }

  // MARK: - Query

  /// Checks if file is registered.
  ///
  /// - Parameter fileName: File name.
  /// - Returns: true if file is registered.
  public func hasFile(named fileName: String) -> Bool {
    impl.hasFile(named: fileName)
  }

  /// Checks if message is registered.
  ///
  /// - Parameter fullName: Full message name.
  /// - Returns: true if message is registered.
  public func hasMessage(named fullName: String) -> Bool {
    impl.hasMessage(named: fullName)
  }

  /// Checks if enum is registered.
  ///
  /// - Parameter fullName: Full enum name.
  /// - Returns: true if enum is registered.
  public func hasEnum(named fullName: String) -> Bool {
    impl.hasEnum(named: fullName)
  }

  /// Checks if service is registered.
  ///
  /// - Parameter fullName: Full service name.
  /// - Returns: true if service is registered.
  public func hasService(named fullName: String) -> Bool {
    impl.hasService(named: fullName)
  }

  // MARK: - Enumeration

  /// Returns all registered files.
  ///
  /// - Returns: Array of all FileDescriptor.
  public func allFiles() -> [FileDescriptor] {
    impl.allFiles().map { FileDescriptor(from: $0) }
  }

  /// Returns all registered messages.
  ///
  /// - Returns: Array of all MessageDescriptor.
  public func allMessages() -> [MessageDescriptor] {
    impl.allMessages().map { MessageDescriptor(from: $0) }
  }

  /// Returns all registered enums.
  ///
  /// - Returns: Array of all EnumDescriptor.
  public func allEnums() -> [EnumDescriptor] {
    impl.allEnums().map { EnumDescriptor(from: $0) }
  }

  /// Returns all registered services.
  ///
  /// - Returns: Array of all ServiceDescriptor.
  public func allServices() -> [ServiceDescriptor] {
    impl.allServices().map { ServiceDescriptor(from: $0) }
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
    impl.clear()
  }

  /// Removes specific file and all related types.
  ///
  /// - Parameter fileName: File name to remove.
  /// - Returns: true if file was found and removed.
  public func removeFile(named fileName: String) -> Bool {
    impl.removeFile(named: fileName)
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
/// - Thread-safe operations via actor isolation.
/// - Integration with MessageFactory for creating dynamic messages.
public actor DescriptorPool {

  private var storage: _DescriptorPoolStorage

  // MARK: - Initialization

  /// Creates a new DescriptorPool instance.
  ///
  /// - Parameter includeBuiltinDescriptors: If true, adds built-in descriptors for standard Protocol Buffers types.
  public init(includeBuiltinDescriptors: Bool = true) {
    self.storage = _DescriptorPoolStorage(includeBuiltinDescriptors: includeBuiltinDescriptors)
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
      try storage.addFileDescriptor(_FileDescriptor(from: fileDescriptor))
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
    storage.findFileDescriptor(named: fileName).map { FileDescriptor(from: $0) }
  }

  /// Finds MessageDescriptor by full name.
  ///
  /// - Parameter fullName: Full message name.
  /// - Returns: MessageDescriptor or nil if not found.
  public func findMessageDescriptor(named fullName: String) -> MessageDescriptor? {
    storage.findMessageDescriptor(named: fullName).map { MessageDescriptor(from: $0) }
  }

  /// Finds EnumDescriptor by full name.
  ///
  /// - Parameter fullName: Full enum name.
  /// - Returns: EnumDescriptor or nil if not found.
  public func findEnumDescriptor(named fullName: String) -> EnumDescriptor? {
    storage.findEnumDescriptor(named: fullName).map { EnumDescriptor(from: $0) }
  }

  /// Finds ServiceDescriptor by full name.
  ///
  /// - Parameter fullName: Full service name.
  /// - Returns: ServiceDescriptor or nil if not found.
  public func findServiceDescriptor(named fullName: String) -> ServiceDescriptor? {
    storage.findServiceDescriptor(named: fullName).map { ServiceDescriptor(from: $0) }
  }

  /// Finds FieldDescriptor by full name.
  ///
  /// - Parameter fullName: Full field name (including containing message name).
  /// - Returns: FieldDescriptor or nil if not found.
  public func findFieldDescriptor(named fullName: String) -> FieldDescriptor? {
    storage.findFieldDescriptor(named: fullName).map { FieldDescriptor(from: $0) }
  }

  /// Finds FileDescriptor containing specified symbol.
  ///
  /// - Parameter symbolName: Symbol name to search for.
  /// - Returns: FileDescriptor containing symbol or nil if not found.
  public func findFileContainingSymbol(_ symbolName: String) -> FileDescriptor? {
    storage.findFileContainingSymbol(symbolName).map { FileDescriptor(from: $0) }
  }

  // MARK: - Factory Integration

  /// Creates DynamicMessage for specified type using MessageFactory.
  ///
  /// - Parameter typeName: Full message type name.
  /// - Returns: New DynamicMessage or nil if type not found.
  public func createMessage(forType typeName: String) -> DynamicMessage? {
    storage.createMessage(forType: typeName).map { DynamicMessage(impl: $0) }
  }

  /// Creates DynamicMessage with pre-filled values.
  ///
  /// - Parameters:
  ///   - typeName: Full message type name.
  ///   - fieldValues: Dictionary of field values.
  /// - Returns: New DynamicMessage with set values or nil if type not found.
  /// - Throws: Creation or field value setting errors.
  public func createMessage(forType typeName: String, fieldValues: [String: Any]) throws -> DynamicMessage? {
    try storage.createMessage(forType: typeName, fieldValues: fieldValues).map { DynamicMessage(impl: $0) }
  }

  // MARK: - Discovery

  /// Returns all known message type names.
  ///
  /// - Returns: Array of full names of all registered message types.
  public func allMessageTypeNames() -> [String] {
    storage.allMessageTypeNames()
  }

  /// Returns all known enum type names.
  ///
  /// - Returns: Array of full names of all registered enum types.
  public func allEnumTypeNames() -> [String] {
    storage.allEnumTypeNames()
  }

  /// Returns all known service names.
  ///
  /// - Returns: Array of full names of all registered services.
  public func allServiceNames() -> [String] {
    storage.allServiceNames()
  }

  /// Returns all known file names.
  ///
  /// - Returns: Array of names of all registered files.
  public func allFileNames() -> [String] {
    storage.allFileNames()
  }

  // MARK: - Dependency Resolution

  /// Finds all dependencies for specified type.
  ///
  /// - Parameter typeName: Full type name.
  /// - Returns: Array of full names of all dependent types.
  /// - Throws: `DescriptorPoolError.symbolNotFound` if type not found
  public func findDependencies(for typeName: String) throws -> [String] {
    do {
      return try storage.findDependencies(for: typeName)
    }
    catch let e as _DescriptorPoolError {
      throw DescriptorPoolError(from: e)
    }
  }

  // MARK: - Clear

  /// Clears all descriptors from pool.
  public func clear() {
    storage.clear()
  }
}
