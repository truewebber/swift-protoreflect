//
// DescriptorPoolTests.swift
// SwiftProtoReflectTests
//
// Created: 2025-05-24
//

import XCTest

@testable import SwiftProtoReflect

final class DescriptorPoolTests: XCTestCase {
  // MARK: - Properties

  var descriptorPool: DescriptorPool!
  var fileDescriptor: FileDescriptor!
  var messageDescriptor: MessageDescriptor!
  var enumDescriptor: EnumDescriptor!
  var serviceDescriptor: ServiceDescriptor!

  // MARK: - Setup

  override func setUp() async throws {
    try await super.setUp()

    // Create file descriptor for tests
    fileDescriptor = FileDescriptor(
      name: "test.proto",
      package: "test"
    )

    // Create message
    messageDescriptor = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    messageDescriptor.addField(
      FieldDescriptor(
        name: "id",
        number: 1,
        type: .int32
      )
    )
    messageDescriptor.addField(
      FieldDescriptor(
        name: "name",
        number: 2,
        type: .string
      )
    )

    // Create enum
    enumDescriptor = EnumDescriptor(name: "Status", parent: fileDescriptor)
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "ACTIVE", number: 1))

    // Create service
    serviceDescriptor = ServiceDescriptor(name: "TestService", parent: fileDescriptor)
    serviceDescriptor.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "TestMethod",
        inputType: "test.TestMessage",
        outputType: "test.TestMessage"
      )
    )

    // Add everything to file
    fileDescriptor.addMessage(messageDescriptor)
    fileDescriptor.addEnum(enumDescriptor)
    fileDescriptor.addService(serviceDescriptor)
  }

  override func tearDown() async throws {
    descriptorPool = nil
    fileDescriptor = nil
    messageDescriptor = nil
    enumDescriptor = nil
    serviceDescriptor = nil
    try await super.tearDown()
  }

  // MARK: - Initialization Tests

  func testInitializationWithBuiltinDescriptors() async throws {
    // Act
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: true)

    // Assert
    XCTAssertNotNil(descriptorPool)

    // Check that builtin types are added
    let builtinFile = await descriptorPool.findFileDescriptor(named: "google/protobuf/descriptor.proto")
    XCTAssertNotNil(builtinFile)

    let anyMessage = await descriptorPool.findMessageDescriptor(named: "google.protobuf.Any")
    XCTAssertNotNil(anyMessage)

    let timestampMessage = await descriptorPool.findMessageDescriptor(named: "google.protobuf.Timestamp")
    XCTAssertNotNil(timestampMessage)
  }

  func testInitializationWithoutBuiltinDescriptors() async throws {
    // Act
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)

    // Assert
    XCTAssertNotNil(descriptorPool)

    // Check that there are no builtin types
    let builtinFile = await descriptorPool.findFileDescriptor(named: "google/protobuf/descriptor.proto")
    XCTAssertNil(builtinFile)

    let anyMessage = await descriptorPool.findMessageDescriptor(named: "google.protobuf.Any")
    XCTAssertNil(anyMessage)
  }

  // MARK: - FileDescriptor Management Tests

  func testAddFileDescriptor() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)

    // Act
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    // Assert
    let foundFile = await descriptorPool.findFileDescriptor(named: "test.proto")
    XCTAssertNotNil(foundFile)
    XCTAssertEqual(foundFile?.name, "test.proto")
    XCTAssertEqual(foundFile?.package, "test")
  }

  func testAddDuplicateFileDescriptor() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    // Act & Assert
    do {
      try await descriptorPool.addFileDescriptor(fileDescriptor)
      XCTFail("Expected error to be thrown")
    }
    catch let error as DescriptorPoolError {
      guard case .duplicateFile(let fileName) = error else {
        XCTFail("Expected duplicateFile error")
        return
      }
      XCTAssertEqual(fileName, "test.proto")
    }
  }

  func testExtractDescriptorsFromFile() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)

    // Act
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    // Assert - check that all descriptors are extracted
    let msg = await descriptorPool.findMessageDescriptor(named: "test.TestMessage")
    XCTAssertNotNil(msg)
    let enm = await descriptorPool.findEnumDescriptor(named: "test.Status")
    XCTAssertNotNil(enm)
    let svc = await descriptorPool.findServiceDescriptor(named: "test.TestService")
    XCTAssertNotNil(svc)
    let fldId = await descriptorPool.findFieldDescriptor(named: "test.TestMessage.id")
    XCTAssertNotNil(fldId)
    let fldName = await descriptorPool.findFieldDescriptor(named: "test.TestMessage.name")
    XCTAssertNotNil(fldName)
  }

  func testExtractDescriptorsWithNestedTypes() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)

    var parentMessage = MessageDescriptor(name: "Parent", parent: fileDescriptor)
    var nestedMessage = MessageDescriptor(name: "Nested", parent: parentMessage)
    nestedMessage.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    parentMessage.addNestedMessage(nestedMessage)

    var nestedEnum = EnumDescriptor(name: "NestedEnum", parent: parentMessage)
    nestedEnum.addValue(EnumDescriptor.EnumValue(name: "OPTION1", number: 0))
    parentMessage.addNestedEnum(nestedEnum)

    fileDescriptor.addMessage(parentMessage)

    // Act
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    // Assert
    let parentDesc = await descriptorPool.findMessageDescriptor(named: "test.Parent")
    XCTAssertNotNil(parentDesc)
    let nestedDesc = await descriptorPool.findMessageDescriptor(named: "test.Parent.Nested")
    XCTAssertNotNil(nestedDesc)
    let nestedEnumDesc = await descriptorPool.findEnumDescriptor(named: "test.Parent.NestedEnum")
    XCTAssertNotNil(nestedEnumDesc)
    let nestedField = await descriptorPool.findFieldDescriptor(named: "test.Parent.Nested.value")
    XCTAssertNotNil(nestedField)
  }

  // MARK: - Lookup Methods Tests

  func testFindFileDescriptor() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    // Act & Assert
    let found = await descriptorPool.findFileDescriptor(named: "test.proto")
    XCTAssertNotNil(found)
    XCTAssertEqual(found?.name, "test.proto")

    let notFound = await descriptorPool.findFileDescriptor(named: "nonexistent.proto")
    XCTAssertNil(notFound)
  }

  func testFindMessageDescriptor() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    // Act & Assert
    let found = await descriptorPool.findMessageDescriptor(named: "test.TestMessage")
    XCTAssertNotNil(found)
    XCTAssertEqual(found?.name, "TestMessage")
    XCTAssertEqual(found?.fullName, "test.TestMessage")

    let notFound = await descriptorPool.findMessageDescriptor(named: "test.NonexistentMessage")
    XCTAssertNil(notFound)
  }

  func testFindEnumDescriptor() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    // Act & Assert
    let found = await descriptorPool.findEnumDescriptor(named: "test.Status")
    XCTAssertNotNil(found)
    XCTAssertEqual(found?.name, "Status")
    XCTAssertEqual(found?.fullName, "test.Status")

    let notFound = await descriptorPool.findEnumDescriptor(named: "test.NonexistentEnum")
    XCTAssertNil(notFound)
  }

  func testFindServiceDescriptor() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    // Act & Assert
    let found = await descriptorPool.findServiceDescriptor(named: "test.TestService")
    XCTAssertNotNil(found)
    XCTAssertEqual(found?.name, "TestService")
    XCTAssertEqual(found?.fullName, "test.TestService")

    let notFound = await descriptorPool.findServiceDescriptor(named: "test.NonexistentService")
    XCTAssertNil(notFound)
  }

  func testFindFieldDescriptor() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    // Act & Assert
    let foundId = await descriptorPool.findFieldDescriptor(named: "test.TestMessage.id")
    XCTAssertNotNil(foundId)
    XCTAssertEqual(foundId?.name, "id")
    XCTAssertEqual(foundId?.number, 1)
    XCTAssertEqual(foundId?.type, .int32)

    let foundName = await descriptorPool.findFieldDescriptor(named: "test.TestMessage.name")
    XCTAssertNotNil(foundName)
    XCTAssertEqual(foundName?.name, "name")
    XCTAssertEqual(foundName?.number, 2)
    XCTAssertEqual(foundName?.type, .string)

    let notFound = await descriptorPool.findFieldDescriptor(named: "test.TestMessage.nonexistent")
    XCTAssertNil(notFound)
  }

  func testFindFileContainingSymbol() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    // Act & Assert
    let fileWithMessage = await descriptorPool.findFileContainingSymbol("test.TestMessage")
    XCTAssertNotNil(fileWithMessage)
    XCTAssertEqual(fileWithMessage?.name, "test.proto")

    let fileWithEnum = await descriptorPool.findFileContainingSymbol("test.Status")
    XCTAssertNotNil(fileWithEnum)
    XCTAssertEqual(fileWithEnum?.name, "test.proto")

    let fileWithService = await descriptorPool.findFileContainingSymbol("test.TestService")
    XCTAssertNotNil(fileWithService)
    XCTAssertEqual(fileWithService?.name, "test.proto")

    let fileWithNonexistent = await descriptorPool.findFileContainingSymbol("test.Nonexistent")
    XCTAssertNil(fileWithNonexistent)
  }

  // MARK: - Factory Integration Tests

  func testCreateMessage() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    // Act
    let message = await descriptorPool.createMessage(forType: "test.TestMessage")

    // Assert
    XCTAssertNotNil(message)
    XCTAssertEqual(message?.descriptor.fullName, "test.TestMessage")

    let nonexistentMessage = await descriptorPool.createMessage(forType: "test.NonexistentMessage")
    XCTAssertNil(nonexistentMessage)
  }

  func testCreateMessageWithFieldValues() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    let fieldValues: [String: Any] = [
      "id": 42,
      "name": "Test Name",
    ]

    // Act
    let message = try await descriptorPool.createMessage(forType: "test.TestMessage", fieldValues: fieldValues)

    // Assert
    XCTAssertNotNil(message)
    XCTAssertEqual(message?.descriptor.fullName, "test.TestMessage")

    // Check set values
    XCTAssertEqual(try message?.get(forField: "id") as? Int32, 42)
    XCTAssertEqual(try message?.get(forField: "name") as? String, "Test Name")

    let nonexistentMessage = try await descriptorPool.createMessage(
      forType: "test.NonexistentMessage",
      fieldValues: fieldValues
    )
    XCTAssertNil(nonexistentMessage)
  }

  // MARK: - Discovery Methods Tests

  func testAllMessageTypeNames() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    // Act
    let messageTypeNames = await descriptorPool.allMessageTypeNames()

    // Assert
    XCTAssertTrue(messageTypeNames.contains("test.TestMessage"))
    XCTAssertEqual(messageTypeNames.filter { $0.hasPrefix("test.") }.count, 1)
  }

  func testAllEnumTypeNames() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    // Act
    let enumTypeNames = await descriptorPool.allEnumTypeNames()

    // Assert
    XCTAssertTrue(enumTypeNames.contains("test.Status"))
    XCTAssertEqual(enumTypeNames.filter { $0.hasPrefix("test.") }.count, 1)
  }

  func testAllServiceNames() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    // Act
    let serviceNames = await descriptorPool.allServiceNames()

    // Assert
    XCTAssertTrue(serviceNames.contains("test.TestService"))
    XCTAssertEqual(serviceNames.filter { $0.hasPrefix("test.") }.count, 1)
  }

  func testAllFileNames() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    // Act
    let fileNames = await descriptorPool.allFileNames()

    // Assert
    XCTAssertTrue(fileNames.contains("test.proto"))
    XCTAssertEqual(fileNames.count, 1)
  }

  func testDiscoveryWithBuiltinDescriptors() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: true)

    // Act & Assert
    let messageTypeNames = await descriptorPool.allMessageTypeNames()
    XCTAssertTrue(messageTypeNames.contains("google.protobuf.Any"))
    XCTAssertTrue(messageTypeNames.contains("google.protobuf.Timestamp"))
    XCTAssertTrue(messageTypeNames.contains("google.protobuf.Duration"))
    XCTAssertTrue(messageTypeNames.contains("google.protobuf.Empty"))

    let fileNames = await descriptorPool.allFileNames()
    XCTAssertTrue(fileNames.contains("google/protobuf/descriptor.proto"))
  }

  // MARK: - Dependency Resolution Tests

  func testFindDependencies() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)

    // Create message with dependencies
    var dependentMessage = MessageDescriptor(name: "DependentMessage", parent: fileDescriptor)
    dependentMessage.addField(
      FieldDescriptor(
        name: "test_message",
        number: 1,
        type: .message,
        typeName: "test.TestMessage"
      )
    )
    dependentMessage.addField(
      FieldDescriptor(
        name: "status",
        number: 2,
        type: .enum,
        typeName: "test.Status"
      )
    )

    fileDescriptor.addMessage(dependentMessage)
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    // Act
    let dependencies = try await descriptorPool.findDependencies(for: "test.DependentMessage")

    // Assert
    XCTAssertTrue(dependencies.contains("test.TestMessage"))
    XCTAssertTrue(dependencies.contains("test.Status"))
  }

  func testFindDependenciesForNonexistentType() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    // Act & Assert
    do {
      _ = try await descriptorPool.findDependencies(for: "test.NonexistentMessage")
      XCTFail("Expected error to be thrown")
    }
    catch let error as DescriptorPoolError {
      guard case .symbolNotFound(let symbolName) = error else {
        XCTFail("Expected symbolNotFound error")
        return
      }
      XCTAssertEqual(symbolName, "test.NonexistentMessage")
    }
  }

  func testFindDependenciesWithNestedTypes() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)

    var parentMessage = MessageDescriptor(name: "Parent", parent: fileDescriptor)
    var nestedMessage = MessageDescriptor(name: "Nested", parent: parentMessage)
    nestedMessage.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    parentMessage.addNestedMessage(nestedMessage)

    var nestedEnum = EnumDescriptor(name: "NestedEnum", parent: parentMessage)
    nestedEnum.addValue(EnumDescriptor.EnumValue(name: "OPTION1", number: 0))
    parentMessage.addNestedEnum(nestedEnum)

    fileDescriptor.addMessage(parentMessage)
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    // Act
    let dependencies = try await descriptorPool.findDependencies(for: "test.Parent")

    // Assert
    XCTAssertTrue(dependencies.contains("test.Parent.Nested"))
    XCTAssertTrue(dependencies.contains("test.Parent.NestedEnum"))
  }

  // MARK: - Clear Methods Tests

  func testClear() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: true)
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    // Check that descriptors exist
    let preClearFile = await descriptorPool.findFileDescriptor(named: "test.proto")
    XCTAssertNotNil(preClearFile)
    let preClearMsg = await descriptorPool.findMessageDescriptor(named: "test.TestMessage")
    XCTAssertNotNil(preClearMsg)
    let preClearAny = await descriptorPool.findMessageDescriptor(named: "google.protobuf.Any")
    XCTAssertNotNil(preClearAny)

    // Act
    await descriptorPool.clear()

    // Assert
    let postClearFile = await descriptorPool.findFileDescriptor(named: "test.proto")
    XCTAssertNil(postClearFile)
    let postClearMsg = await descriptorPool.findMessageDescriptor(named: "test.TestMessage")
    XCTAssertNil(postClearMsg)
    let postClearAny = await descriptorPool.findMessageDescriptor(named: "google.protobuf.Any")
    XCTAssertNil(postClearAny)

    let fileNames = await descriptorPool.allFileNames()
    XCTAssertTrue(fileNames.isEmpty)
    let msgNames = await descriptorPool.allMessageTypeNames()
    XCTAssertTrue(msgNames.isEmpty)
    let enumNames = await descriptorPool.allEnumTypeNames()
    XCTAssertTrue(enumNames.isEmpty)
    let svcNames = await descriptorPool.allServiceNames()
    XCTAssertTrue(svcNames.isEmpty)
  }

  // MARK: - Error Tests

  func testDescriptorPoolErrorDescriptions() async throws {
    // Act & Assert
    let duplicateFileError = DescriptorPoolError.duplicateFile("test.proto")
    XCTAssertEqual(duplicateFileError.localizedDescription, "File 'test.proto' already exists in descriptor pool")

    let duplicateSymbolError = DescriptorPoolError.duplicateSymbol("test.TestMessage")
    XCTAssertEqual(
      duplicateSymbolError.localizedDescription,
      "Symbol 'test.TestMessage' already exists in descriptor pool"
    )

    let symbolNotFoundError = DescriptorPoolError.symbolNotFound("test.NonexistentMessage")
    XCTAssertEqual(
      symbolNotFoundError.localizedDescription,
      "Symbol 'test.NonexistentMessage' was not found in descriptor pool"
    )

    let invalidDescriptorError = DescriptorPoolError.invalidDescriptor("missing required field")
    XCTAssertEqual(invalidDescriptorError.localizedDescription, "Invalid descriptor: missing required field")
  }

  func testDescriptorPoolErrorEquality() async throws {
    // Act & Assert
    XCTAssertEqual(
      DescriptorPoolError.duplicateFile("test.proto"),
      DescriptorPoolError.duplicateFile("test.proto")
    )

    XCTAssertNotEqual(
      DescriptorPoolError.duplicateFile("test.proto"),
      DescriptorPoolError.duplicateFile("other.proto")
    )

    XCTAssertNotEqual(
      DescriptorPoolError.duplicateFile("test.proto"),
      DescriptorPoolError.duplicateSymbol("test.proto")
    )
  }

  // MARK: - Concurrency Tests

  func testConcurrentAccess() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    // Act — multiple concurrent read operations via Tasks
    await withTaskGroup(of: MessageDescriptor?.self) { group in
      for _ in 0..<10 {
        group.addTask {
          await self.descriptorPool.findMessageDescriptor(named: "test.TestMessage")
        }
      }
      var count = 0
      for await result in group {
        XCTAssertNotNil(result)
        count += 1
      }
      XCTAssertEqual(count, 10)
    }
  }

  // MARK: - Performance Tests

  func testLookupPerformance() async throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try await descriptorPool.addFileDescriptor(fileDescriptor)

    // Act & Assert — validate basic lookup correctness at volume
    for _ in 0..<100 {
      let msg = await descriptorPool.findMessageDescriptor(named: "test.TestMessage")
      let enm = await descriptorPool.findEnumDescriptor(named: "test.Status")
      let svc = await descriptorPool.findServiceDescriptor(named: "test.TestService")
      XCTAssertNotNil(msg)
      XCTAssertNotNil(enm)
      XCTAssertNotNil(svc)
    }
  }
}
