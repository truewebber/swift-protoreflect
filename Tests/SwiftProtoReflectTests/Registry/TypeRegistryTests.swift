//
// TypeRegistryTests.swift
// SwiftProtoReflectTests
//
// Created: 2025-05-24
//

import XCTest

@testable import SwiftProtoReflect

final class TypeRegistryTests: XCTestCase {
  // MARK: - Properties

  nonisolated(unsafe) var typeRegistry: TypeRegistry!
  nonisolated(unsafe) var fileDescriptor: FileDescriptor!
  nonisolated(unsafe) var messageDescriptor: MessageDescriptor!
  nonisolated(unsafe) var enumDescriptor: EnumDescriptor!
  nonisolated(unsafe) var serviceDescriptor: ServiceDescriptor!

  // MARK: - Setup

  override func setUp() async throws {
    try await super.setUp()
    typeRegistry = TypeRegistry()

    // Create test descriptors
    setupTestDescriptors()
  }

  override func tearDown() async throws {
    typeRegistry = nil
    fileDescriptor = nil
    messageDescriptor = nil
    enumDescriptor = nil
    serviceDescriptor = nil
    try await super.tearDown()
  }

  private func setupTestDescriptors() {
    // Create file descriptor
    fileDescriptor = FileDescriptor(name: "test.proto", package: "test")

    // Create enum descriptor
    var tempEnum = EnumDescriptor(name: "Status", parent: fileDescriptor)
    tempEnum.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
    tempEnum.addValue(EnumDescriptor.EnumValue(name: "SUCCESS", number: 1))
    enumDescriptor = tempEnum

    // Create message descriptor
    var tempMessage = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    tempMessage.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    tempMessage.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    tempMessage.addField(FieldDescriptor(name: "status", number: 3, type: .enum, typeName: enumDescriptor.fullName))
    messageDescriptor = tempMessage

    // Create service descriptor
    var tempService = ServiceDescriptor(name: "TestService", parent: fileDescriptor)
    tempService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "GetTest",
        inputType: "test.GetTestRequest",
        outputType: "test.GetTestResponse"
      )
    )
    serviceDescriptor = tempService

    // Add types to file
    fileDescriptor.addMessage(messageDescriptor)
    fileDescriptor.addEnum(enumDescriptor)
    fileDescriptor.addService(serviceDescriptor)
  }

  // MARK: - Initialization Tests

  func testInitialization() async throws {
    let registry = TypeRegistry()
    let _asyncResult28 = await registry.allFiles().count
    XCTAssertEqual(_asyncResult28, 0)
    let _asyncResult29 = await registry.allMessages().count
    XCTAssertEqual(_asyncResult29, 0)
    let _asyncResult30 = await registry.allEnums().count
    XCTAssertEqual(_asyncResult30, 0)
    let _asyncResult31 = await registry.allServices().count
    XCTAssertEqual(_asyncResult31, 0)
  }

  // MARK: - File Registration Tests

  func testRegisterFile() async throws {
    try await typeRegistry.registerFile(fileDescriptor)

    // Check that file is registered
    let _asyncResult32 = await typeRegistry.hasFile(named: "test.proto")
    XCTAssertTrue(_asyncResult32)
    let _asyncResult33 = await typeRegistry.findFile(named: "test.proto")
    XCTAssertNotNil(_asyncResult33)

    // Check that all types from file are automatically registered
    let _asyncResult34 = await typeRegistry.hasMessage(named: "test.TestMessage")
    XCTAssertTrue(_asyncResult34)
    let _asyncResult35 = await typeRegistry.hasEnum(named: "test.Status")
    XCTAssertTrue(_asyncResult35)
    let _asyncResult36 = await typeRegistry.hasService(named: "test.TestService")
    XCTAssertTrue(_asyncResult36)
  }

  func testRegisterFileDuplicate() async throws {
    try await typeRegistry.registerFile(fileDescriptor)

    // Attempting to register the same file should throw an error
    do {
      try await typeRegistry.registerFile(fileDescriptor)
      XCTFail("Expected error to be thrown")
    }
    catch {
      XCTAssertEqual(error as? RegistryError, .duplicateFile("test.proto"))
    }
  }

  func testRegisterFileWithNestedTypes() async throws {
    // Create new file with nested types
    var nestedFile = FileDescriptor(name: "nested.proto", package: "nested")

    // Create file with nested types
    var outerMessage = MessageDescriptor(name: "OuterMessage", parent: nestedFile)
    var innerMessage = MessageDescriptor(name: "InnerMessage", parent: outerMessage)
    innerMessage.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    var innerEnum = EnumDescriptor(name: "InnerEnum", parent: outerMessage)
    innerEnum.addValue(EnumDescriptor.EnumValue(name: "OPTION_A", number: 0))

    outerMessage.addNestedMessage(innerMessage)
    outerMessage.addNestedEnum(innerEnum)

    nestedFile.addMessage(outerMessage)

    try await typeRegistry.registerFile(nestedFile)

    // Check nested types registration
    let _asyncResult37 = await typeRegistry.hasMessage(named: "nested.OuterMessage")
    XCTAssertTrue(_asyncResult37)
    let _asyncResult38 = await typeRegistry.hasMessage(named: "nested.OuterMessage.InnerMessage")
    XCTAssertTrue(_asyncResult38)
    let _asyncResult39 = await typeRegistry.hasEnum(named: "nested.OuterMessage.InnerEnum")
    XCTAssertTrue(_asyncResult39)
  }

  // MARK: - Direct Type Registration Tests

  func testRegisterMessageDirectly() async throws {
    var directMessage = MessageDescriptor(name: "DirectMessage", fullName: "direct.DirectMessage")
    directMessage.addField(FieldDescriptor(name: "text", number: 1, type: .string))

    try await typeRegistry.registerMessage(directMessage)

    let _asyncResult40 = await typeRegistry.hasMessage(named: "direct.DirectMessage")
    XCTAssertTrue(_asyncResult40)
    let _asyncResult41 = await typeRegistry.findMessage(named: "direct.DirectMessage")
    XCTAssertNotNil(_asyncResult41)
  }

  func testRegisterEnumDirectly() async throws {
    var directEnum = EnumDescriptor(name: "DirectEnum", fullName: "direct.DirectEnum")
    directEnum.addValue(EnumDescriptor.EnumValue(name: "VALUE", number: 0))

    try await typeRegistry.registerEnum(directEnum)

    let _asyncResult42 = await typeRegistry.hasEnum(named: "direct.DirectEnum")
    XCTAssertTrue(_asyncResult42)
    let _asyncResult43 = await typeRegistry.findEnum(named: "direct.DirectEnum")
    XCTAssertNotNil(_asyncResult43)
  }

  func testRegisterServiceDirectly() async throws {
    var directService = ServiceDescriptor(name: "DirectService", fullName: "direct.DirectService")
    directService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "DirectMethod",
        inputType: "direct.Request",
        outputType: "direct.Response"
      )
    )

    try await typeRegistry.registerService(directService)

    let _asyncResult44 = await typeRegistry.hasService(named: "direct.DirectService")
    XCTAssertTrue(_asyncResult44)
    let _asyncResult45 = await typeRegistry.findService(named: "direct.DirectService")
    XCTAssertNotNil(_asyncResult45)
  }

  func testRegisterDuplicateTypes() async throws {
    let message1 = MessageDescriptor(name: "Message", fullName: "test.Message")
    let message2 = MessageDescriptor(name: "Message", fullName: "test.Message")

    try await typeRegistry.registerMessage(message1)

    // Registering duplicate should throw an error
    do {
      try await typeRegistry.registerMessage(message2)
      XCTFail("Expected error to be thrown")
    }
    catch {
      XCTAssertEqual(error as? RegistryError, .duplicateType("test.Message"))
    }
  }

  // MARK: - Lookup Tests

  func testFindTypes() async throws {
    try await typeRegistry.registerFile(fileDescriptor)

    // Test finding all types
    let foundFile = await typeRegistry.findFile(named: "test.proto")
    XCTAssertNotNil(foundFile)
    XCTAssertEqual(foundFile?.name, "test.proto")

    let foundMessage = await typeRegistry.findMessage(named: "test.TestMessage")
    XCTAssertNotNil(foundMessage)
    XCTAssertEqual(foundMessage?.name, "TestMessage")

    let foundEnum = await typeRegistry.findEnum(named: "test.Status")
    XCTAssertNotNil(foundEnum)
    XCTAssertEqual(foundEnum?.name, "Status")

    let foundService = await typeRegistry.findService(named: "test.TestService")
    XCTAssertNotNil(foundService)
    XCTAssertEqual(foundService?.name, "TestService")
  }

  func testFindNonExistentTypes() async throws {
    // Finding non-existent types should return nil
    let _asyncResult46 = await typeRegistry.findFile(named: "nonexistent.proto")
    XCTAssertNil(_asyncResult46)
    let _asyncResult47 = await typeRegistry.findMessage(named: "nonexistent.Message")
    XCTAssertNil(_asyncResult47)
    let _asyncResult48 = await typeRegistry.findEnum(named: "nonexistent.Enum")
    XCTAssertNil(_asyncResult48)
    let _asyncResult49 = await typeRegistry.findService(named: "nonexistent.Service")
    XCTAssertNil(_asyncResult49)

    let _asyncResult50 = await typeRegistry.hasFile(named: "nonexistent.proto")
    XCTAssertFalse(_asyncResult50)
    let _asyncResult51 = await typeRegistry.hasMessage(named: "nonexistent.Message")
    XCTAssertFalse(_asyncResult51)
    let _asyncResult52 = await typeRegistry.hasEnum(named: "nonexistent.Enum")
    XCTAssertFalse(_asyncResult52)
    let _asyncResult53 = await typeRegistry.hasService(named: "nonexistent.Service")
    XCTAssertFalse(_asyncResult53)
  }

  // MARK: - Enumeration Tests

  func testAllTypesEnumeration() async throws {
    try await typeRegistry.registerFile(fileDescriptor)

    let allFiles = await typeRegistry.allFiles()
    XCTAssertEqual(allFiles.count, 1)
    XCTAssertEqual(allFiles[0].name, "test.proto")

    let allMessages = await typeRegistry.allMessages()
    XCTAssertEqual(allMessages.count, 1)
    XCTAssertEqual(allMessages[0].name, "TestMessage")

    let allEnums = await typeRegistry.allEnums()
    XCTAssertEqual(allEnums.count, 1)
    XCTAssertEqual(allEnums[0].name, "Status")

    let allServices = await typeRegistry.allServices()
    XCTAssertEqual(allServices.count, 1)
    XCTAssertEqual(allServices[0].name, "TestService")
  }

  func testMultipleFilesEnumeration() async throws {
    // Register first file
    try await typeRegistry.registerFile(fileDescriptor)

    // Create and register second file
    var secondFile = FileDescriptor(name: "second.proto", package: "second")
    let secondMessage = MessageDescriptor(name: "SecondMessage", parent: secondFile)
    secondFile.addMessage(secondMessage)

    try await typeRegistry.registerFile(secondFile)

    // Check that all files and types are accounted for
    let _asyncResult54 = await typeRegistry.allFiles().count
    XCTAssertEqual(_asyncResult54, 2)
    let _asyncResult55 = await typeRegistry.allMessages().count
    XCTAssertEqual(_asyncResult55, 2)
    let _asyncResult56 = await typeRegistry.allEnums().count
    XCTAssertEqual(_asyncResult56, 1)
    let _asyncResult57 = await typeRegistry.allServices().count
    XCTAssertEqual(_asyncResult57, 1)
  }

  // MARK: - Dependency Resolution Tests

  func testResolveDependencies() async throws {
    // Create structure with dependencies
    var dependentFile = FileDescriptor(name: "dependent.proto", package: "dependent")

    var addressMessage = MessageDescriptor(name: "Address", parent: dependentFile)
    addressMessage.addField(FieldDescriptor(name: "street", number: 1, type: .string))
    addressMessage.addField(FieldDescriptor(name: "city", number: 2, type: .string))

    var personMessage = MessageDescriptor(name: "Person", parent: dependentFile)
    personMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    personMessage.addField(FieldDescriptor(name: "address", number: 2, type: .message, typeName: "dependent.Address"))

    dependentFile.addMessage(addressMessage)
    dependentFile.addMessage(personMessage)

    try await typeRegistry.registerFile(dependentFile)

    // Check dependency resolution
    let dependencies = try await typeRegistry.resolveDependencies(for: "dependent.Person")
    XCTAssertTrue(dependencies.contains("dependent.Address"))
  }

  func testResolveDependenciesForNonExistentType() async throws {
    do {
      _ = try await typeRegistry.resolveDependencies(for: "nonexistent.Type")
      XCTFail("Expected error to be thrown")
    }
    catch {
      XCTAssertEqual(error as? RegistryError, .typeNotFound("nonexistent.Type"))
    }
  }

  func testResolveDependenciesWithNestedTypes() async throws {
    // Create structure with nested types and dependencies
    var complexFile = FileDescriptor(name: "complex.proto", package: "complex")

    var outerMessage = MessageDescriptor(name: "OuterMessage", parent: complexFile)
    var innerMessage = MessageDescriptor(name: "InnerMessage", parent: outerMessage)
    innerMessage.addField(FieldDescriptor(name: "data", number: 1, type: .string))
    var innerEnum = EnumDescriptor(name: "InnerEnum", parent: outerMessage)
    innerEnum.addValue(EnumDescriptor.EnumValue(name: "OPTION", number: 0))

    outerMessage.addNestedMessage(innerMessage)
    outerMessage.addNestedEnum(innerEnum)
    outerMessage.addField(
      FieldDescriptor(name: "inner", number: 1, type: .message, typeName: "complex.OuterMessage.InnerMessage")
    )

    complexFile.addMessage(outerMessage)

    try await typeRegistry.registerFile(complexFile)

    let dependencies = try await typeRegistry.resolveDependencies(for: "complex.OuterMessage")
    XCTAssertTrue(dependencies.contains("complex.OuterMessage.InnerMessage"))
    XCTAssertTrue(dependencies.contains("complex.OuterMessage.InnerEnum"))
  }

  // MARK: - Clear and Remove Tests

  func testClear() async throws {
    try await typeRegistry.registerFile(fileDescriptor)

    // Check that types are registered
    let _asyncResult58 = await typeRegistry.allFiles().count
    XCTAssertEqual(_asyncResult58, 1)
    let _asyncResult59 = await typeRegistry.allMessages().count
    XCTAssertEqual(_asyncResult59, 1)

    // Clear registry
    await typeRegistry.clear()

    // Check that all types are removed
    let _asyncResult60 = await typeRegistry.allFiles().count
    XCTAssertEqual(_asyncResult60, 0)
    let _asyncResult61 = await typeRegistry.allMessages().count
    XCTAssertEqual(_asyncResult61, 0)
    let _asyncResult62 = await typeRegistry.allEnums().count
    XCTAssertEqual(_asyncResult62, 0)
    let _asyncResult63 = await typeRegistry.allServices().count
    XCTAssertEqual(_asyncResult63, 0)
  }

  func testRemoveFile() async throws {
    try await typeRegistry.registerFile(fileDescriptor)

    // Check initial state
    let _asyncResult64 = await typeRegistry.hasFile(named: "test.proto")
    XCTAssertTrue(_asyncResult64)
    let _asyncResult65 = await typeRegistry.hasMessage(named: "test.TestMessage")
    XCTAssertTrue(_asyncResult65)

    // Remove file
    let removed = await typeRegistry.removeFile(named: "test.proto")
    XCTAssertTrue(removed)

    // Check that file and all associated types are removed
    let _asyncResult66 = await typeRegistry.hasFile(named: "test.proto")
    XCTAssertFalse(_asyncResult66)
    let _asyncResult67 = await typeRegistry.hasMessage(named: "test.TestMessage")
    XCTAssertFalse(_asyncResult67)
    let _asyncResult68 = await typeRegistry.hasEnum(named: "test.Status")
    XCTAssertFalse(_asyncResult68)
    let _asyncResult69 = await typeRegistry.hasService(named: "test.TestService")
    XCTAssertFalse(_asyncResult69)
  }

  func testRemoveNonExistentFile() async throws {
    let removed = await typeRegistry.removeFile(named: "nonexistent.proto")
    XCTAssertFalse(removed)
  }

  // MARK: - Thread Safety Tests

  func testConcurrentAccess() async throws {
    let expectation = XCTestExpectation(description: "Concurrent operations complete")
    expectation.expectedFulfillmentCount = 4

    // Register initial file
    try await typeRegistry.registerFile(fileDescriptor)

    let queue = DispatchQueue.global(qos: .default)
    let registry = self.typeRegistry!

    // Parallel read operations
    queue.async {
      Task {
        for _ in 0..<100 {
          _ = await registry.hasMessage(named: "test.TestMessage")
          _ = await registry.findEnum(named: "test.Status")
        }
        expectation.fulfill()
      }
    }

    queue.async {
      Task {
        for _ in 0..<100 {
          _ = await registry.allMessages()
          _ = await registry.allEnums()
        }
        expectation.fulfill()
      }
    }

    // Parallel operation registering new types
    queue.async {
      Task {
        do {
          for i in 0..<10 {
            let message = MessageDescriptor(name: "Message\(i)", fullName: "test.Message\(i)")
            try await registry.registerMessage(message)
          }
        }
        catch {
          // Duplicate error may occur, this is normal in parallel environment
        }
        expectation.fulfill()
      }
    }

    // Parallel dependency resolution operation
    queue.async {
      Task {
        do {
          for _ in 0..<50 {
            _ = try await registry.resolveDependencies(for: "test.TestMessage")
          }
        }
        catch {
          // Errors are possible but should not cause crash
        }
        expectation.fulfill()
      }
    }

    await fulfillment(of: [expectation], timeout: 10.0)
  }

  // MARK: - Error Tests

  func testRegistryErrorEquality() {
    XCTAssertEqual(RegistryError.duplicateFile("test.proto"), RegistryError.duplicateFile("test.proto"))
    XCTAssertEqual(RegistryError.duplicateType("test.Type"), RegistryError.duplicateType("test.Type"))
    XCTAssertEqual(RegistryError.typeNotFound("test.Type"), RegistryError.typeNotFound("test.Type"))

    XCTAssertNotEqual(RegistryError.duplicateFile("test1.proto"), RegistryError.duplicateFile("test2.proto"))
    XCTAssertNotEqual(RegistryError.duplicateType("Type1"), RegistryError.duplicateType("Type2"))
    XCTAssertNotEqual(RegistryError.typeNotFound("Type1"), RegistryError.duplicateType("Type1"))
  }

  func testRegistryErrorDescriptions() {
    let duplicateFileError = RegistryError.duplicateFile("test.proto")
    XCTAssertEqual(duplicateFileError.errorDescription, "File 'test.proto' is already registered")

    let duplicateTypeError = RegistryError.duplicateType("test.Type")
    XCTAssertEqual(duplicateTypeError.errorDescription, "Type 'test.Type' is already registered")

    let typeNotFoundError = RegistryError.typeNotFound("test.Type")
    XCTAssertEqual(typeNotFoundError.errorDescription, "Type 'test.Type' was not found in registry")
  }

  // MARK: - Performance Tests

  func testRegistrationPerformance() async throws {
    let registry = TypeRegistry()
    do {
      for i in 0..<1000 {
        var message = MessageDescriptor(name: "Message\(i)", fullName: "test.Message\(i)")
        message.addField(FieldDescriptor(name: "field1", number: 1, type: .string))
        message.addField(FieldDescriptor(name: "field2", number: 2, type: .int32))
        try await registry.registerMessage(message)
      }
    }
    catch {
      XCTFail("Registration should not fail: \(error)")
    }
  }

  func testLookupPerformance() async throws {
    // Prepare data
    for i in 0..<1000 {
      let message = MessageDescriptor(name: "Message\(i)", fullName: "test.Message\(i)")
      try await typeRegistry.registerMessage(message)
    }

    for i in 0..<1000 {
      _ = await typeRegistry.findMessage(named: "test.Message\(i)")
    }
  }

  // MARK: - init(fileDescriptors:) Tests

  func test_initFileDescriptors_emptyArray_createsEmptyRegistry() async throws {
    let registry = try await TypeRegistry(fileDescriptors: [])
    let _asyncResult70 = await registry.allFiles().count
    XCTAssertEqual(_asyncResult70, 0)
    let _asyncResult71 = await registry.allMessages().count
    XCTAssertEqual(_asyncResult71, 0)
    let _asyncResult72 = await registry.allEnums().count
    XCTAssertEqual(_asyncResult72, 0)
    let _asyncResult73 = await registry.allServices().count
    XCTAssertEqual(_asyncResult73, 0)
  }

  func test_initFileDescriptors_singleFile_registersAllTypes() async throws {
    let registry = try await TypeRegistry(fileDescriptors: [fileDescriptor])

    let _asyncResult74 = await registry.hasFile(named: "test.proto")
    XCTAssertTrue(_asyncResult74)
    let _asyncResult75 = await registry.hasMessage(named: "test.TestMessage")
    XCTAssertTrue(_asyncResult75)
    let _asyncResult76 = await registry.hasEnum(named: "test.Status")
    XCTAssertTrue(_asyncResult76)
    let _asyncResult77 = await registry.hasService(named: "test.TestService")
    XCTAssertTrue(_asyncResult77)
  }

  func test_initFileDescriptors_registersTopLevelEnums() async throws {
    var file = FileDescriptor(name: "enums.proto", package: "enums")
    var topLevelEnum = EnumDescriptor(name: "Color", parent: file)
    topLevelEnum.addValue(EnumDescriptor.EnumValue(name: "RED", number: 0))
    topLevelEnum.addValue(EnumDescriptor.EnumValue(name: "GREEN", number: 1))
    file.addEnum(topLevelEnum)

    let registry = try await TypeRegistry(fileDescriptors: [file])

    let _asyncResult78 = await registry.hasEnum(named: "enums.Color")
    XCTAssertTrue(_asyncResult78)
    let _asyncResult79 = await registry.findEnum(named: "enums.Color")
    XCTAssertNotNil(_asyncResult79)
  }

  func test_initFileDescriptors_registersNestedMessages() async throws {
    var file = FileDescriptor(name: "nested.proto", package: "nested")
    var outer = MessageDescriptor(name: "Outer", parent: file)
    let inner = MessageDescriptor(name: "Inner", parent: outer)
    outer.addNestedMessage(inner)
    file.addMessage(outer)

    let registry = try await TypeRegistry(fileDescriptors: [file])

    let _asyncResult80 = await registry.hasMessage(named: "nested.Outer")
    XCTAssertTrue(_asyncResult80)
    let _asyncResult81 = await registry.hasMessage(named: "nested.Outer.Inner")
    XCTAssertTrue(_asyncResult81)
  }

  func test_initFileDescriptors_registersNestedEnums() async throws {
    var file = FileDescriptor(name: "nested_enums.proto", package: "nested_enums")
    var outer = MessageDescriptor(name: "Outer", parent: file)
    var nestedEnum = EnumDescriptor(name: "State", parent: outer)
    nestedEnum.addValue(EnumDescriptor.EnumValue(name: "ACTIVE", number: 0))
    outer.addNestedEnum(nestedEnum)
    file.addMessage(outer)

    let registry = try await TypeRegistry(fileDescriptors: [file])

    let _asyncResult82 = await registry.hasEnum(named: "nested_enums.Outer.State")
    XCTAssertTrue(_asyncResult82)
  }

  func test_initFileDescriptors_multipleFiles_registersAll() async throws {
    var file1 = FileDescriptor(name: "file1.proto", package: "file1")
    let msg1 = MessageDescriptor(name: "Msg1", parent: file1)
    file1.addMessage(msg1)

    var file2 = FileDescriptor(name: "file2.proto", package: "file2")
    let msg2 = MessageDescriptor(name: "Msg2", parent: file2)
    file2.addMessage(msg2)

    let registry = try await TypeRegistry(fileDescriptors: [file1, file2])

    let _asyncResult83 = await registry.hasFile(named: "file1.proto")
    XCTAssertTrue(_asyncResult83)
    let _asyncResult84 = await registry.hasFile(named: "file2.proto")
    XCTAssertTrue(_asyncResult84)
    let _asyncResult85 = await registry.hasMessage(named: "file1.Msg1")
    XCTAssertTrue(_asyncResult85)
    let _asyncResult86 = await registry.hasMessage(named: "file2.Msg2")
    XCTAssertTrue(_asyncResult86)
  }

  func test_initFileDescriptors_duplicateFileName_throwsDuplicateFile() async throws {
    let file1 = FileDescriptor(name: "dup.proto", package: "pkg1")
    let file2 = FileDescriptor(name: "dup.proto", package: "pkg2")

    do {
      _ = try await TypeRegistry(fileDescriptors: [file1, file2])
      XCTFail("Expected error to be thrown")
    }
    catch {
      XCTAssertEqual(error as? RegistryError, .duplicateFile("dup.proto"))
    }
  }

  func test_initFileDescriptors_duplicateTypeName_throwsDuplicateType() async throws {
    var file1 = FileDescriptor(name: "a.proto", package: "shared")
    let msg1 = MessageDescriptor(name: "Common", parent: file1)
    file1.addMessage(msg1)

    var file2 = FileDescriptor(name: "b.proto", package: "shared")
    let msg2 = MessageDescriptor(name: "Common", parent: file2)
    file2.addMessage(msg2)

    do {
      _ = try await TypeRegistry(fileDescriptors: [file1, file2])
      XCTFail("Expected error to be thrown")
    }
    catch {
      XCTAssertEqual(error as? RegistryError, .duplicateType("shared.Common"))
    }
  }

  func test_initFileDescriptors_registersServices() async throws {
    var file = FileDescriptor(name: "svc.proto", package: "svc")
    var svc = ServiceDescriptor(name: "MyService", parent: file)
    svc.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "DoWork",
        inputType: "svc.Request",
        outputType: "svc.Response"
      )
    )
    file.addService(svc)

    let registry = try await TypeRegistry(fileDescriptors: [file])

    let _asyncResult87 = await registry.hasService(named: "svc.MyService")
    XCTAssertTrue(_asyncResult87)
    let _asyncResult88 = await registry.findService(named: "svc.MyService")
    XCTAssertNotNil(_asyncResult88)
  }

  // MARK: - Helpers
}
