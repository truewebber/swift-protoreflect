//
// ServiceDescriptorTests.swift
// SwiftProtoReflectTests
//
// Создан: 2025-05-23
//

import XCTest
@testable import SwiftProtoReflect

final class ServiceDescriptorTests: XCTestCase {
  // MARK: - Properties
  
  // Тестовые данные
  let serviceName = "UserService"
  let serviceFullName = "example.UserService"
  let methodName = "GetUser"
  let inputType = "example.GetUserRequest"
  let outputType = "example.GetUserResponse"
  
  // MARK: - Setup
  
  override func setUp() {
    super.setUp()
    // Настройка тестов
  }
  
  override func tearDown() {
    // Очистка после тестов
    super.tearDown()
  }
  
  // MARK: - Tests
  
  // MARK: Initialization Tests
  
  func testInitWithNameAndFullName() {
    // Arrange & Act
    let service = ServiceDescriptor(name: serviceName, fullName: serviceFullName)
    
    // Assert
    XCTAssertEqual(service.name, serviceName)
    XCTAssertEqual(service.fullName, serviceFullName)
    XCTAssertNil(service.fileDescriptorPath)
    XCTAssertTrue(service.methodsByName.isEmpty)
    XCTAssertTrue(service.options.isEmpty)
  }
  
  func testInitWithParent() {
    // Arrange
    let fileDescriptor = FileDescriptor(name: "user.proto", package: "example")
    
    // Act
    let service = ServiceDescriptor(name: serviceName, parent: fileDescriptor)
    
    // Assert
    XCTAssertEqual(service.name, serviceName)
    XCTAssertEqual(service.fullName, "example.UserService")
    XCTAssertEqual(service.fileDescriptorPath, "user.proto")
    XCTAssertTrue(service.methodsByName.isEmpty)
    XCTAssertTrue(service.options.isEmpty)
  }
  
  func testInitWithOptions() {
    // Arrange
    let options: [String: Any] = ["deprecated": true, "customOption": "value"]
    
    // Act
    let service = ServiceDescriptor(name: serviceName, fullName: serviceFullName, options: options)
    
    // Assert
    XCTAssertEqual(service.name, serviceName)
    XCTAssertEqual(service.fullName, serviceFullName)
    XCTAssertEqual(service.options.count, 2)
    XCTAssertEqual(service.options["deprecated"] as? Bool, true)
    XCTAssertEqual(service.options["customOption"] as? String, "value")
  }
  
  // MARK: Method Management Tests
  
  func testAddMethod() {
    // Arrange
    var service = ServiceDescriptor(name: serviceName, fullName: serviceFullName)
    let method = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType
    )
    
    // Act
    service.addMethod(method)
    
    // Assert
    XCTAssertEqual(service.methodsByName.count, 1)
    XCTAssertTrue(service.hasMethod(named: methodName))
  }
  
  func testAddMultipleMethods() {
    // Arrange
    var service = ServiceDescriptor(name: serviceName, fullName: serviceFullName)
    let method1 = ServiceDescriptor.MethodDescriptor(
      name: "GetUser",
      inputType: "example.GetUserRequest",
      outputType: "example.GetUserResponse"
    )
    let method2 = ServiceDescriptor.MethodDescriptor(
      name: "CreateUser",
      inputType: "example.CreateUserRequest",
      outputType: "example.CreateUserResponse",
      clientStreaming: true
    )
    let method3 = ServiceDescriptor.MethodDescriptor(
      name: "ListUsers",
      inputType: "example.ListUsersRequest",
      outputType: "example.ListUsersResponse",
      serverStreaming: true
    )
    
    // Act
    service.addMethod(method1)
    service.addMethod(method2)
    service.addMethod(method3)
    
    // Assert
    XCTAssertEqual(service.methodsByName.count, 3)
    XCTAssertTrue(service.hasMethod(named: "GetUser"))
    XCTAssertTrue(service.hasMethod(named: "CreateUser"))
    XCTAssertTrue(service.hasMethod(named: "ListUsers"))
  }
  
  func testHasMethod() {
    // Arrange
    var service = ServiceDescriptor(name: serviceName, fullName: serviceFullName)
    let method = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType
    )
    service.addMethod(method)
    
    // Act & Assert
    XCTAssertTrue(service.hasMethod(named: methodName))
    XCTAssertFalse(service.hasMethod(named: "NonExistentMethod"))
  }
  
  func testGetMethod() {
    // Arrange
    var service = ServiceDescriptor(name: serviceName, fullName: serviceFullName)
    let method = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      clientStreaming: true,
      serverStreaming: false
    )
    service.addMethod(method)
    
    // Act
    let retrievedMethod = service.method(named: methodName)
    
    // Assert
    XCTAssertNotNil(retrievedMethod)
    XCTAssertEqual(retrievedMethod?.name, methodName)
    XCTAssertEqual(retrievedMethod?.inputType, inputType)
    XCTAssertEqual(retrievedMethod?.outputType, outputType)
    XCTAssertEqual(retrievedMethod?.clientStreaming, true)
    XCTAssertEqual(retrievedMethod?.serverStreaming, false)
    
    // Проверка несуществующего метода
    XCTAssertNil(service.method(named: "NonExistentMethod"))
  }
  
  func testAllMethods() {
    // Arrange
    var service = ServiceDescriptor(name: serviceName, fullName: serviceFullName)
    let method1 = ServiceDescriptor.MethodDescriptor(
      name: "GetUser",
      inputType: "example.GetUserRequest",
      outputType: "example.GetUserResponse"
    )
    let method2 = ServiceDescriptor.MethodDescriptor(
      name: "CreateUser",
      inputType: "example.CreateUserRequest",
      outputType: "example.CreateUserResponse"
    )
    service.addMethod(method1)
    service.addMethod(method2)
    
    // Act
    let allMethods = service.allMethods()
    
    // Assert
    XCTAssertEqual(allMethods.count, 2)
    XCTAssertTrue(allMethods.contains { $0.name == "GetUser" })
    XCTAssertTrue(allMethods.contains { $0.name == "CreateUser" })
  }
  
  // MARK: Method Descriptor Tests
  
  func testMethodDescriptorInitialization() {
    // Arrange & Act
    let method = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      clientStreaming: true,
      serverStreaming: true,
      options: ["deprecated": true]
    )
    
    // Assert
    XCTAssertEqual(method.name, methodName)
    XCTAssertEqual(method.inputType, inputType)
    XCTAssertEqual(method.outputType, outputType)
    XCTAssertTrue(method.clientStreaming)
    XCTAssertTrue(method.serverStreaming)
    XCTAssertEqual(method.options.count, 1)
    XCTAssertEqual(method.options["deprecated"] as? Bool, true)
  }
  
  func testMethodDescriptorDefaultValues() {
    // Arrange & Act
    let method = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType
    )
    
    // Assert
    XCTAssertEqual(method.name, methodName)
    XCTAssertEqual(method.inputType, inputType)
    XCTAssertEqual(method.outputType, outputType)
    XCTAssertFalse(method.clientStreaming)
    XCTAssertFalse(method.serverStreaming)
    XCTAssertTrue(method.options.isEmpty)
  }
  
  // MARK: Equatable Tests
  
  func testServiceDescriptorEquality() {
    // Arrange
    var service1 = ServiceDescriptor(name: serviceName, fullName: serviceFullName)
    var service2 = ServiceDescriptor(name: serviceName, fullName: serviceFullName)
    let method = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType
    )
    service1.addMethod(method)
    service2.addMethod(method)
    
    // Act & Assert
    XCTAssertEqual(service1, service2)
  }
  
  func testServiceDescriptorInequality() {
    // Arrange
    var service1 = ServiceDescriptor(name: serviceName, fullName: serviceFullName)
    var service2 = ServiceDescriptor(name: "DifferentService", fullName: "example.DifferentService")
    let method = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType
    )
    service1.addMethod(method)
    service2.addMethod(method)
    
    // Act & Assert
    XCTAssertNotEqual(service1, service2)
  }
  
  func testServiceDescriptorInequalityDifferentMethods() {
    // Arrange
    var service1 = ServiceDescriptor(name: serviceName, fullName: serviceFullName)
    var service2 = ServiceDescriptor(name: serviceName, fullName: serviceFullName)
    
    let method1 = ServiceDescriptor.MethodDescriptor(
      name: "Method1",
      inputType: inputType,
      outputType: outputType
    )
    let method2 = ServiceDescriptor.MethodDescriptor(
      name: "Method2",
      inputType: inputType,
      outputType: outputType
    )
    
    service1.addMethod(method1)
    service2.addMethod(method2)
    
    // Act & Assert
    XCTAssertNotEqual(service1, service2)
  }
  
  func testMethodDescriptorEquality() {
    // Arrange
    let method1 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      clientStreaming: true,
      serverStreaming: false,
      options: ["deprecated": true]
    )
    
    let method2 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      clientStreaming: true,
      serverStreaming: false,
      options: ["deprecated": true]
    )
    
    // Act & Assert
    XCTAssertEqual(method1, method2)
  }
  
  func testMethodDescriptorInequality() {
    // Arrange
    let method1 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      clientStreaming: true,
      serverStreaming: false
    )
    
    let method2 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      clientStreaming: false,  // Разное значение
      serverStreaming: false
    )
    
    // Act & Assert
    XCTAssertNotEqual(method1, method2)
  }
}
