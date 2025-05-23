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

  // MARK: Дополнительные тесты для повышения покрытия кода

  // MARK: Дополнительные тесты для MethodDescriptor

  func testMethodDescriptorDifferentOptions() {
    // Arrange
    let method1 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      options: ["option1": true, "option2": "value"]
    )

    let method2 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      options: ["option1": true, "option3": "different"]
    )

    // Act & Assert
    XCTAssertNotEqual(method1, method2)
  }

  func testMethodDescriptorOptionsWithDifferentTypes() {
    // Проверка различных типов опций

    // Boolean options
    let method1 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      options: ["boolOption": true]
    )

    let method2 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      options: ["boolOption": false]
    )

    XCTAssertNotEqual(method1, method2)

    // Integer options
    let method3 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      options: ["intOption": 10]
    )

    let method4 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      options: ["intOption": 20]
    )

    XCTAssertNotEqual(method3, method4)

    // String options
    let method5 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      options: ["stringOption": "value1"]
    )

    let method6 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      options: ["stringOption": "value2"]
    )

    XCTAssertNotEqual(method5, method6)

    // Custom type options
    let customValue1 = ["key": "value"]
    let customValue2 = ["key": "different"]

    let method7 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      options: ["customOption": customValue1]
    )

    let method8 = ServiceDescriptor.MethodDescriptor(
      name: methodName,
      inputType: inputType,
      outputType: outputType,
      options: ["customOption": customValue2]
    )

    XCTAssertNotEqual(method7, method8)
  }

  // MARK: Дополнительные тесты для ServiceDescriptor

  func testServiceDescriptorDifferentMethodCount() {
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

    // Assert - разное количество методов
    XCTAssertNotEqual(service1, service2)
  }

  func testServiceDescriptorWithDifferentOptions() {
    // Arrange
    let options1: [String: Any] = ["option1": true, "option2": "value"]
    let options2: [String: Any] = ["option1": true, "option3": "different"]

    let service1 = ServiceDescriptor(name: serviceName, fullName: serviceFullName, options: options1)
    let service2 = ServiceDescriptor(name: serviceName, fullName: serviceFullName, options: options2)

    // Act & Assert
    XCTAssertNotEqual(service1, service2)
  }

  func testServiceDescriptorOptionsWithDifferentTypes() {
    // Boolean options
    let service1 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["boolOption": true]
    )

    let service2 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["boolOption": false]
    )

    XCTAssertNotEqual(service1, service2)

    // Integer options
    let service3 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["intOption": 10]
    )

    let service4 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["intOption": 20]
    )

    XCTAssertNotEqual(service3, service4)

    // String options
    let service5 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["stringOption": "value1"]
    )

    let service6 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["stringOption": "value2"]
    )

    XCTAssertNotEqual(service5, service6)

    // Custom type options
    let customValue1 = ["key": "value"]
    let customValue2 = ["key": "different"]

    let service7 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["customOption": customValue1]
    )

    let service8 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["customOption": customValue2]
    )

    XCTAssertNotEqual(service7, service8)
  }

  // Тест для покрытия сравнения сложных типов в опциях
  func testServiceDescriptorComplexOptionsComparison() {
    // Используем класс для создания сложного типа данных
    class ComplexValue: CustomStringConvertible {
      let value: String

      init(value: String) {
        self.value = value
      }

      // Реализация протокола CustomStringConvertible
      var description: String {
        return "ComplexValue(\(value))"
      }
    }

    // Создаем два сервиса с разными сложными опциями
    let complex1 = ComplexValue(value: "value1")
    let complex2 = ComplexValue(value: "value2")

    let service1 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["complexOption": complex1]
    )

    let service2 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["complexOption": complex2]
    )

    // Эти сервисы должны быть разными из-за разных значений сложной опции
    XCTAssertNotEqual(service1, service2)

    // Проверяем, что сервисы с одинаковыми сложными опциями равны
    let complex3 = ComplexValue(value: "value1")
    let service3 = ServiceDescriptor(
      name: serviceName,
      fullName: serviceFullName,
      options: ["complexOption": complex3]
    )

    // Они должны быть равны, потому что description одинаковый
    XCTAssertEqual(service1, service3)
  }
}
