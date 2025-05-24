//
// TypeRegistryTests.swift
// SwiftProtoReflectTests
//
// Создан: 2025-05-24
//

import XCTest
@testable import SwiftProtoReflect

final class TypeRegistryTests: XCTestCase {
  // MARK: - Properties
  
  var typeRegistry: TypeRegistry!
  var fileDescriptor: FileDescriptor!
  var messageDescriptor: MessageDescriptor!
  var enumDescriptor: EnumDescriptor!
  var serviceDescriptor: ServiceDescriptor!
  
  // MARK: - Setup
  
  override func setUp() {
    super.setUp()
    typeRegistry = TypeRegistry()
    
    // Создаем тестовые дескрипторы
    setupTestDescriptors()
  }
  
  override func tearDown() {
    typeRegistry = nil
    fileDescriptor = nil
    messageDescriptor = nil
    enumDescriptor = nil
    serviceDescriptor = nil
    super.tearDown()
  }
  
  private func setupTestDescriptors() {
    // Создаем файловый дескриптор
    fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    
    // Создаем дескриптор перечисления
    var tempEnum = EnumDescriptor(name: "Status", parent: fileDescriptor)
    tempEnum.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
    tempEnum.addValue(EnumDescriptor.EnumValue(name: "SUCCESS", number: 1))
    enumDescriptor = tempEnum
    
    // Создаем дескриптор сообщения
    var tempMessage = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    tempMessage.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    tempMessage.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    tempMessage.addField(FieldDescriptor(name: "status", number: 3, type: .enum, typeName: enumDescriptor.fullName))
    messageDescriptor = tempMessage
    
    // Создаем дескриптор сервиса
    var tempService = ServiceDescriptor(name: "TestService", parent: fileDescriptor)
    tempService.addMethod(ServiceDescriptor.MethodDescriptor(
      name: "GetTest",
      inputType: "test.GetTestRequest",
      outputType: "test.GetTestResponse"
    ))
    serviceDescriptor = tempService
    
    // Добавляем типы в файл
    fileDescriptor.addMessage(messageDescriptor)
    fileDescriptor.addEnum(enumDescriptor)
    fileDescriptor.addService(serviceDescriptor)
  }
  
  // MARK: - Initialization Tests
  
  func testInitialization() {
    let registry = TypeRegistry()
    XCTAssertEqual(registry.allFiles().count, 0)
    XCTAssertEqual(registry.allMessages().count, 0)
    XCTAssertEqual(registry.allEnums().count, 0)
    XCTAssertEqual(registry.allServices().count, 0)
  }
  
  // MARK: - File Registration Tests
  
  func testRegisterFile() throws {
    try typeRegistry.registerFile(fileDescriptor)
    
    // Проверяем, что файл зарегистрирован
    XCTAssertTrue(typeRegistry.hasFile(named: "test.proto"))
    XCTAssertNotNil(typeRegistry.findFile(named: "test.proto"))
    
    // Проверяем, что все типы из файла автоматически зарегистрированы
    XCTAssertTrue(typeRegistry.hasMessage(named: "test.TestMessage"))
    XCTAssertTrue(typeRegistry.hasEnum(named: "test.Status"))
    XCTAssertTrue(typeRegistry.hasService(named: "test.TestService"))
  }
  
  func testRegisterFileDuplicate() throws {
    try typeRegistry.registerFile(fileDescriptor)
    
    // Попытка зарегистрировать тот же файл должна вызвать ошибку
    XCTAssertThrowsError(try typeRegistry.registerFile(fileDescriptor)) { error in
      XCTAssertEqual(error as? RegistryError, .duplicateFile("test.proto"))
    }
  }
  
  func testRegisterFileWithNestedTypes() throws {
    // Создаем новый файл с вложенными типами
    var nestedFile = FileDescriptor(name: "nested.proto", package: "nested")
    
    // Создаем файл с вложенными типами
    var outerMessage = MessageDescriptor(name: "OuterMessage", parent: nestedFile)
    var innerMessage = MessageDescriptor(name: "InnerMessage", parent: outerMessage)
    innerMessage.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    var innerEnum = EnumDescriptor(name: "InnerEnum", parent: outerMessage)
    innerEnum.addValue(EnumDescriptor.EnumValue(name: "OPTION_A", number: 0))
    
    outerMessage.addNestedMessage(innerMessage)
    outerMessage.addNestedEnum(innerEnum)
    
    nestedFile.addMessage(outerMessage)
    
    try typeRegistry.registerFile(nestedFile)
    
    // Проверяем регистрацию вложенных типов
    XCTAssertTrue(typeRegistry.hasMessage(named: "nested.OuterMessage"))
    XCTAssertTrue(typeRegistry.hasMessage(named: "nested.OuterMessage.InnerMessage"))
    XCTAssertTrue(typeRegistry.hasEnum(named: "nested.OuterMessage.InnerEnum"))
  }
  
  // MARK: - Direct Type Registration Tests
  
  func testRegisterMessageDirectly() throws {
    var directMessage = MessageDescriptor(name: "DirectMessage", fullName: "direct.DirectMessage")
    directMessage.addField(FieldDescriptor(name: "text", number: 1, type: .string))
    
    try typeRegistry.registerMessage(directMessage)
    
    XCTAssertTrue(typeRegistry.hasMessage(named: "direct.DirectMessage"))
    XCTAssertNotNil(typeRegistry.findMessage(named: "direct.DirectMessage"))
  }
  
  func testRegisterEnumDirectly() throws {
    var directEnum = EnumDescriptor(name: "DirectEnum", fullName: "direct.DirectEnum")
    directEnum.addValue(EnumDescriptor.EnumValue(name: "VALUE", number: 0))
    
    try typeRegistry.registerEnum(directEnum)
    
    XCTAssertTrue(typeRegistry.hasEnum(named: "direct.DirectEnum"))
    XCTAssertNotNil(typeRegistry.findEnum(named: "direct.DirectEnum"))
  }
  
  func testRegisterServiceDirectly() throws {
    var directService = ServiceDescriptor(name: "DirectService", fullName: "direct.DirectService")
    directService.addMethod(ServiceDescriptor.MethodDescriptor(
      name: "DirectMethod",
      inputType: "direct.Request",
      outputType: "direct.Response"
    ))
    
    try typeRegistry.registerService(directService)
    
    XCTAssertTrue(typeRegistry.hasService(named: "direct.DirectService"))
    XCTAssertNotNil(typeRegistry.findService(named: "direct.DirectService"))
  }
  
  func testRegisterDuplicateTypes() throws {
    let message1 = MessageDescriptor(name: "Message", fullName: "test.Message")
    let message2 = MessageDescriptor(name: "Message", fullName: "test.Message")
    
    try typeRegistry.registerMessage(message1)
    
    // Регистрация дубликата должна вызвать ошибку
    XCTAssertThrowsError(try typeRegistry.registerMessage(message2)) { error in
      XCTAssertEqual(error as? RegistryError, .duplicateType("test.Message"))
    }
  }
  
  // MARK: - Lookup Tests
  
  func testFindTypes() throws {
    try typeRegistry.registerFile(fileDescriptor)
    
    // Тестируем поиск всех типов
    let foundFile = typeRegistry.findFile(named: "test.proto")
    XCTAssertNotNil(foundFile)
    XCTAssertEqual(foundFile?.name, "test.proto")
    
    let foundMessage = typeRegistry.findMessage(named: "test.TestMessage")
    XCTAssertNotNil(foundMessage)
    XCTAssertEqual(foundMessage?.name, "TestMessage")
    
    let foundEnum = typeRegistry.findEnum(named: "test.Status")
    XCTAssertNotNil(foundEnum)
    XCTAssertEqual(foundEnum?.name, "Status")
    
    let foundService = typeRegistry.findService(named: "test.TestService")
    XCTAssertNotNil(foundService)
    XCTAssertEqual(foundService?.name, "TestService")
  }
  
  func testFindNonExistentTypes() {
    // Поиск несуществующих типов должен возвращать nil
    XCTAssertNil(typeRegistry.findFile(named: "nonexistent.proto"))
    XCTAssertNil(typeRegistry.findMessage(named: "nonexistent.Message"))
    XCTAssertNil(typeRegistry.findEnum(named: "nonexistent.Enum"))
    XCTAssertNil(typeRegistry.findService(named: "nonexistent.Service"))
    
    XCTAssertFalse(typeRegistry.hasFile(named: "nonexistent.proto"))
    XCTAssertFalse(typeRegistry.hasMessage(named: "nonexistent.Message"))
    XCTAssertFalse(typeRegistry.hasEnum(named: "nonexistent.Enum"))
    XCTAssertFalse(typeRegistry.hasService(named: "nonexistent.Service"))
  }
  
  // MARK: - Enumeration Tests
  
  func testAllTypesEnumeration() throws {
    try typeRegistry.registerFile(fileDescriptor)
    
    let allFiles = typeRegistry.allFiles()
    XCTAssertEqual(allFiles.count, 1)
    XCTAssertEqual(allFiles[0].name, "test.proto")
    
    let allMessages = typeRegistry.allMessages()
    XCTAssertEqual(allMessages.count, 1)
    XCTAssertEqual(allMessages[0].name, "TestMessage")
    
    let allEnums = typeRegistry.allEnums()
    XCTAssertEqual(allEnums.count, 1)
    XCTAssertEqual(allEnums[0].name, "Status")
    
    let allServices = typeRegistry.allServices()
    XCTAssertEqual(allServices.count, 1)
    XCTAssertEqual(allServices[0].name, "TestService")
  }
  
  func testMultipleFilesEnumeration() throws {
    // Регистрируем первый файл
    try typeRegistry.registerFile(fileDescriptor)
    
    // Создаем и регистрируем второй файл
    var secondFile = FileDescriptor(name: "second.proto", package: "second")
    let secondMessage = MessageDescriptor(name: "SecondMessage", parent: secondFile)
    secondFile.addMessage(secondMessage)
    
    try typeRegistry.registerFile(secondFile)
    
    // Проверяем, что все файлы и типы учтены
    XCTAssertEqual(typeRegistry.allFiles().count, 2)
    XCTAssertEqual(typeRegistry.allMessages().count, 2)
    XCTAssertEqual(typeRegistry.allEnums().count, 1)
    XCTAssertEqual(typeRegistry.allServices().count, 1)
  }
  
  // MARK: - Dependency Resolution Tests
  
  func testResolveDependencies() throws {
    // Создаем структуру с зависимостями
    var dependentFile = FileDescriptor(name: "dependent.proto", package: "dependent")
    
    var addressMessage = MessageDescriptor(name: "Address", parent: dependentFile)
    addressMessage.addField(FieldDescriptor(name: "street", number: 1, type: .string))
    addressMessage.addField(FieldDescriptor(name: "city", number: 2, type: .string))
    
    var personMessage = MessageDescriptor(name: "Person", parent: dependentFile)
    personMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    personMessage.addField(FieldDescriptor(name: "address", number: 2, type: .message, typeName: "dependent.Address"))
    
    dependentFile.addMessage(addressMessage)
    dependentFile.addMessage(personMessage)
    
    try typeRegistry.registerFile(dependentFile)
    
    // Проверяем разрешение зависимостей
    let dependencies = try typeRegistry.resolveDependencies(for: "dependent.Person")
    XCTAssertTrue(dependencies.contains("dependent.Address"))
  }
  
  func testResolveDependenciesForNonExistentType() {
    XCTAssertThrowsError(try typeRegistry.resolveDependencies(for: "nonexistent.Type")) { error in
      XCTAssertEqual(error as? RegistryError, .typeNotFound("nonexistent.Type"))
    }
  }
  
  func testResolveDependenciesWithNestedTypes() throws {
    // Создаем структуру с вложенными типами и зависимостями
    var complexFile = FileDescriptor(name: "complex.proto", package: "complex")
    
    var outerMessage = MessageDescriptor(name: "OuterMessage", parent: complexFile)
    var innerMessage = MessageDescriptor(name: "InnerMessage", parent: outerMessage)
    innerMessage.addField(FieldDescriptor(name: "data", number: 1, type: .string))
    var innerEnum = EnumDescriptor(name: "InnerEnum", parent: outerMessage)
    innerEnum.addValue(EnumDescriptor.EnumValue(name: "OPTION", number: 0))
    
    outerMessage.addNestedMessage(innerMessage)
    outerMessage.addNestedEnum(innerEnum)
    outerMessage.addField(FieldDescriptor(name: "inner", number: 1, type: .message, typeName: "complex.OuterMessage.InnerMessage"))
    
    complexFile.addMessage(outerMessage)
    
    try typeRegistry.registerFile(complexFile)
    
    let dependencies = try typeRegistry.resolveDependencies(for: "complex.OuterMessage")
    XCTAssertTrue(dependencies.contains("complex.OuterMessage.InnerMessage"))
    XCTAssertTrue(dependencies.contains("complex.OuterMessage.InnerEnum"))
  }
  
  // MARK: - Clear and Remove Tests
  
  func testClear() throws {
    try typeRegistry.registerFile(fileDescriptor)
    
    // Проверяем, что типы зарегистрированы
    XCTAssertEqual(typeRegistry.allFiles().count, 1)
    XCTAssertEqual(typeRegistry.allMessages().count, 1)
    
    // Очищаем реестр
    typeRegistry.clear()
    
    // Проверяем, что все типы удалены
    XCTAssertEqual(typeRegistry.allFiles().count, 0)
    XCTAssertEqual(typeRegistry.allMessages().count, 0)
    XCTAssertEqual(typeRegistry.allEnums().count, 0)
    XCTAssertEqual(typeRegistry.allServices().count, 0)
  }
  
  func testRemoveFile() throws {
    try typeRegistry.registerFile(fileDescriptor)
    
    // Проверяем исходное состояние
    XCTAssertTrue(typeRegistry.hasFile(named: "test.proto"))
    XCTAssertTrue(typeRegistry.hasMessage(named: "test.TestMessage"))
    
    // Удаляем файл
    let removed = typeRegistry.removeFile(named: "test.proto")
    XCTAssertTrue(removed)
    
    // Проверяем, что файл и все связанные типы удалены
    XCTAssertFalse(typeRegistry.hasFile(named: "test.proto"))
    XCTAssertFalse(typeRegistry.hasMessage(named: "test.TestMessage"))
    XCTAssertFalse(typeRegistry.hasEnum(named: "test.Status"))
    XCTAssertFalse(typeRegistry.hasService(named: "test.TestService"))
  }
  
  func testRemoveNonExistentFile() {
    let removed = typeRegistry.removeFile(named: "nonexistent.proto")
    XCTAssertFalse(removed)
  }
  
  // MARK: - Thread Safety Tests
  
  func testConcurrentAccess() throws {
    let expectation = XCTestExpectation(description: "Concurrent operations complete")
    expectation.expectedFulfillmentCount = 4
    
    // Регистрируем исходный файл
    try typeRegistry.registerFile(fileDescriptor)
    
    let queue = DispatchQueue.global(qos: .default)
    
    // Параллельные операции чтения
    queue.async {
      for _ in 0..<100 {
        _ = self.typeRegistry.hasMessage(named: "test.TestMessage")
        _ = self.typeRegistry.findEnum(named: "test.Status")
      }
      expectation.fulfill()
    }
    
    queue.async {
      for _ in 0..<100 {
        _ = self.typeRegistry.allMessages()
        _ = self.typeRegistry.allEnums()
      }
      expectation.fulfill()
    }
    
    // Параллельная операция регистрации новых типов
    queue.async {
      do {
        for i in 0..<10 {
          let message = MessageDescriptor(name: "Message\(i)", fullName: "test.Message\(i)")
          try self.typeRegistry.registerMessage(message)
        }
      } catch {
        // Может возникнуть ошибка дубликата, это нормально в параллельной среде
      }
      expectation.fulfill()
    }
    
    // Параллельная операция разрешения зависимостей
    queue.async {
      do {
        for _ in 0..<50 {
          _ = try self.typeRegistry.resolveDependencies(for: "test.TestMessage")
        }
      } catch {
        // Ошибки возможны, но не должны вызывать краш
      }
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 10.0)
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
  
  func testRegistrationPerformance() throws {
    measure {
      let registry = TypeRegistry()
      do {
        for i in 0..<1000 {
          var message = MessageDescriptor(name: "Message\(i)", fullName: "test.Message\(i)")
          message.addField(FieldDescriptor(name: "field1", number: 1, type: .string))
          message.addField(FieldDescriptor(name: "field2", number: 2, type: .int32))
          try registry.registerMessage(message)
        }
      } catch {
        XCTFail("Registration should not fail: \(error)")
      }
    }
  }
  
  func testLookupPerformance() throws {
    // Подготавливаем данные
    for i in 0..<1000 {
      let message = MessageDescriptor(name: "Message\(i)", fullName: "test.Message\(i)")
      try typeRegistry.registerMessage(message)
    }
    
    measure {
      for i in 0..<1000 {
        _ = typeRegistry.findMessage(named: "test.Message\(i)")
      }
    }
  }
  
  // MARK: - Helpers
}
