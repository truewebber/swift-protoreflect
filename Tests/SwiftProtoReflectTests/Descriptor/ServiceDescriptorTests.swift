//
// ServiceDescriptorTests.swift
// SwiftProtoReflectTests
//
// Created: 2025-05-23
//

import XCTest

@testable import SwiftProtoReflect

final class ServiceDescriptorTests: XCTestCase {
  // MARK: - Properties

  // Test data
  let serviceName = "UserService"
  let serviceFullName = "example.UserService"
  let methodName = "GetUser"
  let inputType = "example.GetUserRequest"
  let outputType = "example.GetUserResponse"

  // MARK: - Setup

  override func setUp() async throws {
    try await super.setUp()
    // Test setup
  }

  override func tearDown() async throws {
    // Cleanup after tests
    try await super.tearDown()
  }

  // MARK: - Tests

  // MARK: Initialization Tests

  func testInitWithNameAndFullName() async throws {
    // Arrange & Act
    let service = ServiceDescriptor(name: serviceName, fullName: serviceFullName)

    // Assert
    XCTAssertEqual(service.name, serviceName)
    XCTAssertEqual(service.fullName, serviceFullName)
    XCTAssertNil(service.fileDescriptorPath)
    XCTAssertTrue(service.methodsByName.isEmpty)
    XCTAssertTrue(service.options.isEmpty)
  }

  func testInitWithParent() async throws {
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

  func testInitWithOptions() async throws {
    // Arrange
    let options: [String: DescriptorOption] = ["deprecated": .bool(true), "customOption": .string("value")]

    // Act
    let service = ServiceDescriptor(name: serviceName, fullName: serviceFullName, options: options)

    // Assert
    XCTAssertEqual(service.name, serviceName)
    XCTAssertEqual(service.fullName, serviceFullName)
    XCTAssertEqual(service.options.count, 2)
    XCTAssertEqual(service.options["deprecated"], .bool(true))
    XCTAssertEqual(service.options["customOption"], .string("value"))
  }

  // MARK: Method Management Tests

  func testAddMethod() async throws {
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

  func testAddMultipleMethods() async throws {
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

  func testHasMethod() async throws {
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

  func testGetMethod() async throws {
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

    // Check for non-existent method
    XCTAssertNil(service.method(named: "NonExistentMethod"))
  }

  func testAllMethods() async throws {
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

  func testMethodDescriptorInitialization() async throws {
    // Arrange & Act
    let method = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      clientStreaming: true,
      serverStreaming: true,
      options: ["deprecated": .bool(true)]
    )

    // Assert
    XCTAssertEqual(method.name, methodName)
    XCTAssertEqual(method.inputType, inputType)
    XCTAssertEqual(method.outputType, outputType)
    XCTAssertTrue(method.clientStreaming)
    XCTAssertTrue(method.serverStreaming)
    XCTAssertEqual(method.options.count, 1)
    XCTAssertEqual(method.options["deprecated"], .bool(true))
  }

  func testMethodDescriptorDefaultValues() async throws {
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

  func testServiceDescriptorEquality() async throws {
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

  func testServiceDescriptorInequality() async throws {
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

  func testServiceDescriptorInequalityDifferentMethods() async throws {
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

  func testMethodDescriptorEquality() async throws {
    // Arrange
    let method1 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      clientStreaming: true,
      serverStreaming: false,
      options: ["deprecated": .bool(true)]
    )

    let method2 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      clientStreaming: true,
      serverStreaming: false,
      options: ["deprecated": .bool(true)]
    )

    // Act & Assert
    XCTAssertEqual(method1, method2)
  }

  func testMethodDescriptorInequality() async throws {
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
      clientStreaming: false,  // Different value
      serverStreaming: false
    )

    // Act & Assert
    XCTAssertNotEqual(method1, method2)
  }

  // MARK: Additional tests for code coverage improvement

  // MARK: Additional tests for MethodDescriptor

  func testMethodDescriptorDifferentOptions() async throws {
    // Arrange
    let method1 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      options: ["option1": .bool(true), "option2": .string("value")]
    )

    let method2 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      options: ["option1": .bool(true), "option3": .string("different")]
    )

    // Act & Assert
    XCTAssertNotEqual(method1, method2)
  }

  func testMethodDescriptorOptionsWithDifferentTypes() async throws {
    // Boolean options
    let method1 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      options: ["boolOption": .bool(true)]
    )

    let method2 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      options: ["boolOption": .bool(false)]
    )

    XCTAssertNotEqual(method1, method2)

    // Integer options
    let method3 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      options: ["intOption": .int(10)]
    )

    let method4 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      options: ["intOption": .int(20)]
    )

    XCTAssertNotEqual(method3, method4)

    // String options
    let method5 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      options: ["stringOption": .string("value1")]
    )

    let method6 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      options: ["stringOption": .string("value2")]
    )

    XCTAssertNotEqual(method5, method6)

    // Float options
    let method7 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      options: ["floatOption": .float(1.0)]
    )

    let method8 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      options: ["floatOption": .float(2.0)]
    )

    XCTAssertNotEqual(method7, method8)
  }

  // MARK: Additional tests for ServiceDescriptor

  func testServiceDescriptorDifferentMethodCount() async throws {
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

    // Act
    service1.addMethod(method1)
    service1.addMethod(method2)
    service2.addMethod(method1)

    // Assert - different number of methods
    XCTAssertNotEqual(service1, service2)
  }

  func testServiceDescriptorWithDifferentOptions() async throws {
    // Arrange
    let options1: [String: DescriptorOption] = ["option1": .bool(true), "option2": .string("value")]
    let options2: [String: DescriptorOption] = ["option1": .bool(true), "option3": .string("different")]

    let service1 = ServiceDescriptor(name: serviceName, fullName: serviceFullName, options: options1)
    let service2 = ServiceDescriptor(name: serviceName, fullName: serviceFullName, options: options2)

    // Act & Assert
    XCTAssertNotEqual(service1, service2)
  }

  func testServiceDescriptorOptionsWithDifferentTypes() async throws {
    // Boolean options
    let service1 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["boolOption": .bool(true)]
    )

    let service2 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["boolOption": .bool(false)]
    )

    XCTAssertNotEqual(service1, service2)

    // Integer options
    let service3 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["intOption": .int(10)]
    )

    let service4 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["intOption": .int(20)]
    )

    XCTAssertNotEqual(service3, service4)

    // String options
    let service5 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["stringOption": .string("value1")]
    )

    let service6 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["stringOption": .string("value2")]
    )

    XCTAssertNotEqual(service5, service6)

    // Float options
    let service7 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["floatOption": .float(1.0)]
    )

    let service8 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["floatOption": .float(2.0)]
    )

    XCTAssertNotEqual(service7, service8)
  }

  func testServiceDescriptorComplexOptionsComparison() async throws {
    let service1 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["floatOption": .float(1.5), "nameOption": .string("alpha")]
    )

    let service2 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["floatOption": .float(1.5), "nameOption": .string("alpha")]
    )

    let service3 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["floatOption": .float(9.9), "nameOption": .string("alpha")]
    )

    XCTAssertEqual(service1, service2)
    XCTAssertNotEqual(service1, service3)
  }

  // MARK: - == false-branches: fullName, fileDescriptorPath, same-named method content

  func test_serviceDescriptorEquality_whenFullNameDiffers_isNotEqual() async throws {
    // Same name but different fullName
    let service1 = ServiceDescriptor(name: serviceName, fullName: "pkgA.UserService")
    let service2 = ServiceDescriptor(name: serviceName, fullName: "pkgB.UserService")

    XCTAssertNotEqual(service1, service2)
  }

  func test_serviceDescriptorEquality_whenFileDescriptorPathDiffers_isNotEqual() async throws {
    // Same name and fullName (same package), different file path
    let file1 = FileDescriptor(name: "service_v1.proto", package: "example")
    let file2 = FileDescriptor(name: "service_v2.proto", package: "example")
    let service1 = ServiceDescriptor(name: serviceName, parent: file1)
    let service2 = ServiceDescriptor(name: serviceName, parent: file2)

    // Both share "example.UserService" fullName but differ in fileDescriptorPath
    XCTAssertEqual(service1.fullName, service2.fullName)
    XCTAssertNotEqual(service1.fileDescriptorPath, service2.fileDescriptorPath)
    XCTAssertNotEqual(service1, service2)
  }

  func test_serviceDescriptorEquality_whenSameMethodNameDiffersInContent_isNotEqual() async throws {
    // Same method name but different inputType — key found in rhs but method != lhsMethod
    var service1 = ServiceDescriptor(name: serviceName, fullName: serviceFullName)
    var service2 = ServiceDescriptor(name: serviceName, fullName: serviceFullName)

    service1.addMethod(
      ServiceDescriptor.MethodDescriptor(name: methodName, inputType: inputType, outputType: outputType)
    )
    service2.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: methodName,
        inputType: "example.DifferentRequest",
        outputType: outputType
      )
    )

    XCTAssertNotEqual(service1, service2)
  }
}
