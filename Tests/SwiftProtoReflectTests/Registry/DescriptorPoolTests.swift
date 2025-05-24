//
// DescriptorPoolTests.swift
// SwiftProtoReflectTests
//
// Создан: 2025-05-24
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
  
  override func setUp() {
    super.setUp()
    
    // Создаем дескриптор файла для тестов
    fileDescriptor = FileDescriptor(
      name: "test.proto",
      package: "test"
    )
    
    // Создаем сообщение
    messageDescriptor = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    messageDescriptor.addField(FieldDescriptor(
      name: "id",
      number: 1,
      type: .int32
    ))
    messageDescriptor.addField(FieldDescriptor(
      name: "name",
      number: 2,
      type: .string
    ))
    
    // Создаем перечисление
    enumDescriptor = EnumDescriptor(name: "Status", parent: fileDescriptor)
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "ACTIVE", number: 1))
    
    // Создаем сервис
    serviceDescriptor = ServiceDescriptor(name: "TestService", parent: fileDescriptor)
    serviceDescriptor.addMethod(ServiceDescriptor.MethodDescriptor(
      name: "TestMethod",
      inputType: "test.TestMessage",
      outputType: "test.TestMessage"
    ))
    
    // Добавляем все в файл
    fileDescriptor.addMessage(messageDescriptor)
    fileDescriptor.addEnum(enumDescriptor)
    fileDescriptor.addService(serviceDescriptor)
  }
  
  override func tearDown() {
    descriptorPool = nil
    fileDescriptor = nil
    messageDescriptor = nil
    enumDescriptor = nil
    serviceDescriptor = nil
    super.tearDown()
  }
  
  // MARK: - Initialization Tests
  
  func testInitializationWithBuiltinDescriptors() {
    // Act
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: true)
    
    // Assert
    XCTAssertNotNil(descriptorPool)
    
    // Проверяем, что встроенные типы добавлены
    let builtinFile = descriptorPool.findFileDescriptor(named: "google/protobuf/descriptor.proto")
    XCTAssertNotNil(builtinFile)
    
    let anyMessage = descriptorPool.findMessageDescriptor(named: "google.protobuf.Any")
    XCTAssertNotNil(anyMessage)
    
    let timestampMessage = descriptorPool.findMessageDescriptor(named: "google.protobuf.Timestamp")
    XCTAssertNotNil(timestampMessage)
  }
  
  func testInitializationWithoutBuiltinDescriptors() {
    // Act
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    
    // Assert
    XCTAssertNotNil(descriptorPool)
    
    // Проверяем, что встроенных типов нет
    let builtinFile = descriptorPool.findFileDescriptor(named: "google/protobuf/descriptor.proto")
    XCTAssertNil(builtinFile)
    
    let anyMessage = descriptorPool.findMessageDescriptor(named: "google.protobuf.Any")
    XCTAssertNil(anyMessage)
  }
  
  // MARK: - FileDescriptor Management Tests
  
  func testAddFileDescriptor() throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    
    // Act
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    // Assert
    let foundFile = descriptorPool.findFileDescriptor(named: "test.proto")
    XCTAssertNotNil(foundFile)
    XCTAssertEqual(foundFile?.name, "test.proto")
    XCTAssertEqual(foundFile?.package, "test")
  }
  
  func testAddDuplicateFileDescriptor() throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    // Act & Assert
    XCTAssertThrowsError(try descriptorPool.addFileDescriptor(fileDescriptor)) { error in
      guard case DescriptorPoolError.duplicateFile(let fileName) = error else {
        XCTFail("Expected duplicateFile error")
        return
      }
      XCTAssertEqual(fileName, "test.proto")
    }
  }
  
  func testExtractDescriptorsFromFile() throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    
    // Act
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    // Assert - проверяем что все дескрипторы извлечены
    XCTAssertNotNil(descriptorPool.findMessageDescriptor(named: "test.TestMessage"))
    XCTAssertNotNil(descriptorPool.findEnumDescriptor(named: "test.Status"))
    XCTAssertNotNil(descriptorPool.findServiceDescriptor(named: "test.TestService"))
    XCTAssertNotNil(descriptorPool.findFieldDescriptor(named: "test.TestMessage.id"))
    XCTAssertNotNil(descriptorPool.findFieldDescriptor(named: "test.TestMessage.name"))
  }
  
  func testExtractDescriptorsWithNestedTypes() throws {
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
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    // Assert
    XCTAssertNotNil(descriptorPool.findMessageDescriptor(named: "test.Parent"))
    XCTAssertNotNil(descriptorPool.findMessageDescriptor(named: "test.Parent.Nested"))
    XCTAssertNotNil(descriptorPool.findEnumDescriptor(named: "test.Parent.NestedEnum"))
    XCTAssertNotNil(descriptorPool.findFieldDescriptor(named: "test.Parent.Nested.value"))
  }
  
  // MARK: - Lookup Methods Tests
  
  func testFindFileDescriptor() throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    // Act & Assert
    let found = descriptorPool.findFileDescriptor(named: "test.proto")
    XCTAssertNotNil(found)
    XCTAssertEqual(found?.name, "test.proto")
    
    let notFound = descriptorPool.findFileDescriptor(named: "nonexistent.proto")
    XCTAssertNil(notFound)
  }
  
  func testFindMessageDescriptor() throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    // Act & Assert
    let found = descriptorPool.findMessageDescriptor(named: "test.TestMessage")
    XCTAssertNotNil(found)
    XCTAssertEqual(found?.name, "TestMessage")
    XCTAssertEqual(found?.fullName, "test.TestMessage")
    
    let notFound = descriptorPool.findMessageDescriptor(named: "test.NonexistentMessage")
    XCTAssertNil(notFound)
  }
  
  func testFindEnumDescriptor() throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    // Act & Assert
    let found = descriptorPool.findEnumDescriptor(named: "test.Status")
    XCTAssertNotNil(found)
    XCTAssertEqual(found?.name, "Status")
    XCTAssertEqual(found?.fullName, "test.Status")
    
    let notFound = descriptorPool.findEnumDescriptor(named: "test.NonexistentEnum")
    XCTAssertNil(notFound)
  }
  
  func testFindServiceDescriptor() throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    // Act & Assert
    let found = descriptorPool.findServiceDescriptor(named: "test.TestService")
    XCTAssertNotNil(found)
    XCTAssertEqual(found?.name, "TestService")
    XCTAssertEqual(found?.fullName, "test.TestService")
    
    let notFound = descriptorPool.findServiceDescriptor(named: "test.NonexistentService")
    XCTAssertNil(notFound)
  }
  
  func testFindFieldDescriptor() throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    // Act & Assert
    let foundId = descriptorPool.findFieldDescriptor(named: "test.TestMessage.id")
    XCTAssertNotNil(foundId)
    XCTAssertEqual(foundId?.name, "id")
    XCTAssertEqual(foundId?.number, 1)
    XCTAssertEqual(foundId?.type, .int32)
    
    let foundName = descriptorPool.findFieldDescriptor(named: "test.TestMessage.name")
    XCTAssertNotNil(foundName)
    XCTAssertEqual(foundName?.name, "name")
    XCTAssertEqual(foundName?.number, 2)
    XCTAssertEqual(foundName?.type, .string)
    
    let notFound = descriptorPool.findFieldDescriptor(named: "test.TestMessage.nonexistent")
    XCTAssertNil(notFound)
  }
  
  func testFindFileContainingSymbol() throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    // Act & Assert
    let fileWithMessage = descriptorPool.findFileContainingSymbol("test.TestMessage")
    XCTAssertNotNil(fileWithMessage)
    XCTAssertEqual(fileWithMessage?.name, "test.proto")
    
    let fileWithEnum = descriptorPool.findFileContainingSymbol("test.Status")
    XCTAssertNotNil(fileWithEnum)
    XCTAssertEqual(fileWithEnum?.name, "test.proto")
    
    let fileWithService = descriptorPool.findFileContainingSymbol("test.TestService")
    XCTAssertNotNil(fileWithService)
    XCTAssertEqual(fileWithService?.name, "test.proto")
    
    let fileWithNonexistent = descriptorPool.findFileContainingSymbol("test.Nonexistent")
    XCTAssertNil(fileWithNonexistent)
  }
  
  // MARK: - Factory Integration Tests
  
  func testCreateMessage() throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    // Act
    let message = descriptorPool.createMessage(forType: "test.TestMessage")
    
    // Assert
    XCTAssertNotNil(message)
    XCTAssertEqual(message?.descriptor.fullName, "test.TestMessage")
    
    let nonexistentMessage = descriptorPool.createMessage(forType: "test.NonexistentMessage")
    XCTAssertNil(nonexistentMessage)
  }
  
  func testCreateMessageWithFieldValues() throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    let fieldValues: [String: Any] = [
      "id": 42,
      "name": "Test Name"
    ]
    
    // Act
    let message = try descriptorPool.createMessage(forType: "test.TestMessage", fieldValues: fieldValues)
    
    // Assert
    XCTAssertNotNil(message)
    XCTAssertEqual(message?.descriptor.fullName, "test.TestMessage")
    
    // Проверяем установленные значения
    XCTAssertEqual(try message?.get(forField: "id") as? Int32, 42)
    XCTAssertEqual(try message?.get(forField: "name") as? String, "Test Name")
    
    let nonexistentMessage = try descriptorPool.createMessage(forType: "test.NonexistentMessage", fieldValues: fieldValues)
    XCTAssertNil(nonexistentMessage)
  }
  
  // MARK: - Discovery Methods Tests
  
  func testAllMessageTypeNames() throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    // Act
    let messageTypeNames = descriptorPool.allMessageTypeNames()
    
    // Assert
    XCTAssertTrue(messageTypeNames.contains("test.TestMessage"))
    XCTAssertEqual(messageTypeNames.filter { $0.hasPrefix("test.") }.count, 1)
  }
  
  func testAllEnumTypeNames() throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    // Act
    let enumTypeNames = descriptorPool.allEnumTypeNames()
    
    // Assert
    XCTAssertTrue(enumTypeNames.contains("test.Status"))
    XCTAssertEqual(enumTypeNames.filter { $0.hasPrefix("test.") }.count, 1)
  }
  
  func testAllServiceNames() throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    // Act
    let serviceNames = descriptorPool.allServiceNames()
    
    // Assert
    XCTAssertTrue(serviceNames.contains("test.TestService"))
    XCTAssertEqual(serviceNames.filter { $0.hasPrefix("test.") }.count, 1)
  }
  
  func testAllFileNames() throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    // Act
    let fileNames = descriptorPool.allFileNames()
    
    // Assert
    XCTAssertTrue(fileNames.contains("test.proto"))
    XCTAssertEqual(fileNames.count, 1)
  }
  
  func testDiscoveryWithBuiltinDescriptors() {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: true)
    
    // Act & Assert
    let messageTypeNames = descriptorPool.allMessageTypeNames()
    XCTAssertTrue(messageTypeNames.contains("google.protobuf.Any"))
    XCTAssertTrue(messageTypeNames.contains("google.protobuf.Timestamp"))
    XCTAssertTrue(messageTypeNames.contains("google.protobuf.Duration"))
    XCTAssertTrue(messageTypeNames.contains("google.protobuf.Empty"))
    
    let fileNames = descriptorPool.allFileNames()
    XCTAssertTrue(fileNames.contains("google/protobuf/descriptor.proto"))
  }
  
  // MARK: - Dependency Resolution Tests
  
  func testFindDependencies() throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    
    // Создаем сообщение с зависимостями
    var dependentMessage = MessageDescriptor(name: "DependentMessage", parent: fileDescriptor)
    dependentMessage.addField(FieldDescriptor(
      name: "test_message",
      number: 1,
      type: .message,
      typeName: "test.TestMessage"
    ))
    dependentMessage.addField(FieldDescriptor(
      name: "status",
      number: 2,
      type: .enum,
      typeName: "test.Status"
    ))
    
    fileDescriptor.addMessage(dependentMessage)
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    // Act
    let dependencies = try descriptorPool.findDependencies(for: "test.DependentMessage")
    
    // Assert
    XCTAssertTrue(dependencies.contains("test.TestMessage"))
    XCTAssertTrue(dependencies.contains("test.Status"))
  }
  
  func testFindDependenciesForNonexistentType() throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    // Act & Assert
    XCTAssertThrowsError(try descriptorPool.findDependencies(for: "test.NonexistentMessage")) { error in
      guard case DescriptorPoolError.symbolNotFound(let symbolName) = error else {
        XCTFail("Expected symbolNotFound error")
        return
      }
      XCTAssertEqual(symbolName, "test.NonexistentMessage")
    }
  }
  
  func testFindDependenciesWithNestedTypes() throws {
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
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    // Act
    let dependencies = try descriptorPool.findDependencies(for: "test.Parent")
    
    // Assert
    XCTAssertTrue(dependencies.contains("test.Parent.Nested"))
    XCTAssertTrue(dependencies.contains("test.Parent.NestedEnum"))
  }
  
  // MARK: - Clear Methods Tests
  
  func testClear() throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: true)
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    // Проверяем что дескрипторы есть
    XCTAssertNotNil(descriptorPool.findFileDescriptor(named: "test.proto"))
    XCTAssertNotNil(descriptorPool.findMessageDescriptor(named: "test.TestMessage"))
    XCTAssertNotNil(descriptorPool.findMessageDescriptor(named: "google.protobuf.Any"))
    
    // Act
    descriptorPool.clear()
    
    // Assert
    XCTAssertNil(descriptorPool.findFileDescriptor(named: "test.proto"))
    XCTAssertNil(descriptorPool.findMessageDescriptor(named: "test.TestMessage"))
    XCTAssertNil(descriptorPool.findMessageDescriptor(named: "google.protobuf.Any"))
    
    XCTAssertTrue(descriptorPool.allFileNames().isEmpty)
    XCTAssertTrue(descriptorPool.allMessageTypeNames().isEmpty)
    XCTAssertTrue(descriptorPool.allEnumTypeNames().isEmpty)
    XCTAssertTrue(descriptorPool.allServiceNames().isEmpty)
  }
  
  // MARK: - Error Tests
  
  func testDescriptorPoolErrorDescriptions() {
    // Act & Assert
    let duplicateFileError = DescriptorPoolError.duplicateFile("test.proto")
    XCTAssertEqual(duplicateFileError.localizedDescription, "File 'test.proto' already exists in descriptor pool")
    
    let duplicateSymbolError = DescriptorPoolError.duplicateSymbol("test.TestMessage")
    XCTAssertEqual(duplicateSymbolError.localizedDescription, "Symbol 'test.TestMessage' already exists in descriptor pool")
    
    let symbolNotFoundError = DescriptorPoolError.symbolNotFound("test.NonexistentMessage")
    XCTAssertEqual(symbolNotFoundError.localizedDescription, "Symbol 'test.NonexistentMessage' was not found in descriptor pool")
    
    let invalidDescriptorError = DescriptorPoolError.invalidDescriptor("missing required field")
    XCTAssertEqual(invalidDescriptorError.localizedDescription, "Invalid descriptor: missing required field")
  }
  
  func testDescriptorPoolErrorEquality() {
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
  
  func testConcurrentAccess() throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    let expectation = XCTestExpectation(description: "Concurrent access completed")
    expectation.expectedFulfillmentCount = 10
    
    // Act - множественные одновременные операции чтения
    for i in 0..<10 {
      DispatchQueue.global().async {
        let found = self.descriptorPool.findMessageDescriptor(named: "test.TestMessage")
        XCTAssertNotNil(found, "Iteration \(i) failed")
        expectation.fulfill()
      }
    }
    
    // Assert
    wait(for: [expectation], timeout: 5.0)
  }
  
  // MARK: - Performance Tests
  
  func testLookupPerformance() throws {
    // Arrange
    descriptorPool = DescriptorPool(includeBuiltinDescriptors: false)
    try descriptorPool.addFileDescriptor(fileDescriptor)
    
    // Act & Assert
    measure {
      for _ in 0..<1000 {
        _ = descriptorPool.findMessageDescriptor(named: "test.TestMessage")
        _ = descriptorPool.findEnumDescriptor(named: "test.Status")
        _ = descriptorPool.findServiceDescriptor(named: "test.TestService")
      }
    }
  }
}
