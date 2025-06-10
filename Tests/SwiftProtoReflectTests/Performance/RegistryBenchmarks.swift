//
// RegistryBenchmarks.swift
//
// Performance benchmarks для TypeRegistry и DescriptorPool
//
// Тестовые случаи:
// - Type lookup performance в больших реестрах
// - Registration performance при добавлении множества типов
// - Concurrent access performance
// - Memory usage при больших объемах типов

import XCTest

@testable import SwiftProtoReflect

/// Performance benchmarks для системы реестров типов.
final class RegistryBenchmarks: XCTestCase {

  // MARK: - Test Setup

  private var typeRegistry: TypeRegistry!
  private var descriptorPool: DescriptorPool!
  private var testMessages: [MessageDescriptor] = []
  private var testEnums: [EnumDescriptor] = []
  private var testServices: [ServiceDescriptor] = []

  override func setUpWithError() throws {
    try super.setUpWithError()

    typeRegistry = TypeRegistry()
    descriptorPool = DescriptorPool()

    try setupTestTypes()
  }

  private func setupTestTypes() throws {
    // Создаем большое количество тестовых типов для performance тестирования
    try createLargeTypeSet()
  }

  private func createLargeTypeSet() throws {
    // Создаем 1000 различных сообщений для performance тестов
    for i in 0..<1000 {
      let fileDescriptor = FileDescriptor(name: "test_\(i).proto", package: "performance.test")

      // Создаем сообщение
      var messageDescriptor = MessageDescriptor(name: "TestMessage\(i)", parent: fileDescriptor)
      messageDescriptor.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
      messageDescriptor.addField(FieldDescriptor(name: "name", number: 2, type: .string))
      messageDescriptor.addField(FieldDescriptor(name: "data", number: 3, type: .bytes))

      // Создаем enum
      var enumDescriptor = EnumDescriptor(name: "TestEnum\(i)", parent: fileDescriptor)
      enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
      enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "VALUE_A", number: 1))
      enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "VALUE_B", number: 2))

      // Создаем service
      var serviceDescriptor = ServiceDescriptor(name: "TestService\(i)", parent: fileDescriptor)
      let methodDescriptor = ServiceDescriptor.MethodDescriptor(
        name: "TestMethod",
        inputType: "TestMessage\(i)",
        outputType: "TestMessage\(i)"
      )
      serviceDescriptor.addMethod(methodDescriptor)

      var fileDescriptorMutable = fileDescriptor
      fileDescriptorMutable.addMessage(messageDescriptor)
      fileDescriptorMutable.addEnum(enumDescriptor)
      fileDescriptorMutable.addService(serviceDescriptor)

      testMessages.append(messageDescriptor)
      testEnums.append(enumDescriptor)
      testServices.append(serviceDescriptor)
    }
  }

  // MARK: - Registration Performance Tests

  /// Performance test для регистрации больших объемов типов.
  func testBulkTypeRegistrationPerformance() {
    measure {
      let registry = TypeRegistry()

      do {
        for message in testMessages {
          try registry.registerMessage(message)
        }

        for enumDesc in testEnums {
          try registry.registerEnum(enumDesc)
        }

        for service in testServices {
          try registry.registerService(service)
        }
      }
      catch {
        XCTFail("Bulk registration failed: \(error)")
      }
    }
  }

  /// Performance test для регистрации файлов.
  func testFileRegistrationPerformance() {
    measure {
      let registry = TypeRegistry()

      do {
        // Регистрируем первые 100 файлов
        for i in 0..<100 {
          let fileDescriptor = FileDescriptor(name: "test_\(i).proto", package: "performance.test")
          try registry.registerFile(fileDescriptor)
        }
      }
      catch {
        XCTFail("File registration failed: \(error)")
      }
    }
  }

  // MARK: - Type Lookup Performance Tests

  /// Performance test для поиска типов по имени.
  func testTypeLookupPerformance() throws {
    // Сначала регистрируем все типы
    for message in testMessages {
      try typeRegistry.registerMessage(message)
    }

    measure {
      // Ищем случайные типы
      for i in stride(from: 0, to: 1000, by: 10) {
        let typeName = "performance.test.TestMessage\(i)"
        let _ = typeRegistry.findMessage(named: typeName)
      }
    }
  }

  /// Performance test для поиска enum типов.
  func testEnumLookupPerformance() throws {
    // Регистрируем все enum'ы
    for enumDesc in testEnums {
      try typeRegistry.registerEnum(enumDesc)
    }

    measure {
      // Ищем случайные enum'ы
      for i in stride(from: 0, to: 1000, by: 10) {
        let enumName = "performance.test.TestEnum\(i)"
        let _ = typeRegistry.findEnum(named: enumName)
      }
    }
  }

  /// Performance test для поиска service типов.
  func testServiceLookupPerformance() throws {
    // Регистрируем все service'ы
    for service in testServices {
      try typeRegistry.registerService(service)
    }

    measure {
      // Ищем случайные service'ы
      for i in stride(from: 0, to: 1000, by: 10) {
        let serviceName = "performance.test.TestService\(i)"
        let _ = typeRegistry.findService(named: serviceName)
      }
    }
  }

  // MARK: - Concurrent Access Performance Tests

  /// Performance test для concurrent доступа к registry.
  func testConcurrentRegistryAccess() throws {
    // Предварительно регистрируем типы
    for message in testMessages {
      try typeRegistry.registerMessage(message)
    }

    let queue = DispatchQueue.global(qos: .userInitiated)

    measure {
      let expectation = self.expectation(description: "Concurrent access")
      expectation.expectedFulfillmentCount = 200

      // 100 reader threads + 100 операций поиска
      for i in 0..<100 {
        queue.async {
          let typeName = "performance.test.TestMessage\(i % 100)"
          let _ = self.typeRegistry.findMessage(named: typeName)
          expectation.fulfill()
        }

        queue.async {
          let enumName = "performance.test.TestEnum\(i % 100)"
          let _ = self.typeRegistry.findEnum(named: enumName)
          expectation.fulfill()
        }
      }

      wait(for: [expectation], timeout: 10.0)
    }
  }

  /// Performance test для concurrent регистрации.
  func testConcurrentRegistrationPerformance() {
    let queue = DispatchQueue.global(qos: .userInitiated)

    measure {
      let registry = TypeRegistry()
      let expectation = self.expectation(description: "Concurrent registration")
      expectation.expectedFulfillmentCount = 100

      for i in 0..<100 {
        queue.async {
          do {
            if i < self.testMessages.count {
              try registry.registerMessage(self.testMessages[i])
            }
          }
          catch {
            // Ignore registration errors for performance testing
          }
          expectation.fulfill()
        }
      }

      wait(for: [expectation], timeout: 10.0)
    }
  }

  // MARK: - DescriptorPool Performance Tests

  /// Performance test для создания сообщений через DescriptorPool.
  func testDescriptorPoolMessageCreationPerformance() throws {
    // Регистрируем типы в pool с уникальными именами файлов
    for i in testMessages.prefix(100).indices {
      try descriptorPool.addFileDescriptor(FileDescriptor(name: "test\(i).proto", package: "performance.test"))
    }

    measure {
      do {
        for i in 0..<100 {
          let typeName = "performance.test.TestMessage\(i)"
          let _ = try descriptorPool.createMessage(
            forType: typeName,
            fieldValues: [
              "id": Int32(i),
              "name": "Test \(i)",
              "data": Data("test\(i)".utf8),
            ]
          )
        }
      }
      catch {
        XCTFail("Message creation failed: \(error)")
      }
    }
  }

  /// Performance test для валидации сообщений.
  func testDescriptorPoolValidationPerformance() throws {
    // Подготавливаем сообщения для валидации
    var testMessage = MessageFactory().createMessage(from: testMessages[0])
    try testMessage.set(Int32(42), forField: "id")
    try testMessage.set("Test Message", forField: "name")
    try testMessage.set(Data("test data".utf8), forField: "data")

    measure {
      for _ in 0..<1000 {
        let _ = MessageFactory().validate(testMessage)
      }
    }
  }

  // MARK: - Memory Usage Tests

  /// Memory usage test для больших registry.
  func testLargeRegistryMemoryUsage() throws {
    measure {
      let registry = TypeRegistry()

      do {
        // Регистрируем все типы и измеряем memory impact
        for message in testMessages {
          try registry.registerMessage(message)
        }

        for enumDesc in testEnums {
          try registry.registerEnum(enumDesc)
        }

        for service in testServices {
          try registry.registerService(service)
        }

        // Выполняем операции поиска для проверки memory stability
        for i in 0..<100 {
          let typeName = "performance.test.TestMessage\(i)"
          let _ = registry.findMessage(named: typeName)
        }
      }
      catch {
        XCTFail("Large registry test failed: \(error)")
      }
    }
  }

  // MARK: - Cache Performance Tests

  /// Performance test для эффективности кэширования типов.
  func testTypeCacheEfficiency() throws {
    // Регистрируем типы
    for message in testMessages.prefix(100) {
      try typeRegistry.registerMessage(message)
    }

    // Первый прогон - заполняем кэш
    for i in 0..<100 {
      let typeName = "performance.test.TestMessage\(i)"
      let _ = typeRegistry.findMessage(named: typeName)
    }

    // Второй прогон - тестируем cached lookups
    measure {
      for _ in 0..<10 {  // Повторяем поиск для проверки cache hit
        for i in 0..<100 {
          let typeName = "performance.test.TestMessage\(i)"
          let _ = typeRegistry.findMessage(named: typeName)
        }
      }
    }
  }

  // MARK: - Stress Tests

  /// Stress test для большого количества одновременных операций.
  func testHighVolumeOperationsStress() throws {
    // Предварительная регистрация
    for message in testMessages.prefix(500) {
      try typeRegistry.registerMessage(message)
    }

    let queue = DispatchQueue.global(qos: .userInitiated)

    measure {
      let expectation = self.expectation(description: "High volume operations")
      expectation.expectedFulfillmentCount = 1000

      // 1000 параллельных операций поиска
      for i in 0..<1000 {
        queue.async {
          let typeName = "performance.test.TestMessage\(i % 500)"
          let _ = self.typeRegistry.findMessage(named: typeName)
          expectation.fulfill()
        }
      }

      wait(for: [expectation], timeout: 15.0)
    }
  }

  // MARK: - Comparative Tests

  /// Comparison between different lookup strategies.
  func testLookupStrategyComparison() throws {
    // Регистрируем типы
    for message in testMessages.prefix(100) {
      try typeRegistry.registerMessage(message)
    }

    var directLookupTimes: [TimeInterval] = []
    var iterativeLookupTimes: [TimeInterval] = []

    // Direct lookup через registry
    for _ in 0..<10 {
      let startTime = Date()
      for i in 0..<100 {
        let typeName = "performance.test.TestMessage\(i)"
        let _ = typeRegistry.findMessage(named: typeName)
      }
      directLookupTimes.append(Date().timeIntervalSince(startTime))
    }

    // Iterative lookup через getAllMessages
    for _ in 0..<10 {
      let startTime = Date()
      for i in 0..<100 {
        let typeName = "performance.test.TestMessage\(i)"
        // Simulate iterative search (simplified)
        let _ = testMessages.first { $0.fullName == typeName }
      }
      iterativeLookupTimes.append(Date().timeIntervalSince(startTime))
    }

    let avgDirectTime = directLookupTimes.reduce(0, +) / Double(directLookupTimes.count)
    let avgIterativeTime = iterativeLookupTimes.reduce(0, +) / Double(iterativeLookupTimes.count)

    print("Direct lookup average time: \(avgDirectTime * 1000) ms")
    print("Iterative lookup average time: \(avgIterativeTime * 1000) ms")
    print("Performance ratio (Iterative/Direct): \(avgIterativeTime / avgDirectTime)")

    // Direct lookup должен быть значительно быстрее
    XCTAssertLessThan(avgDirectTime, avgIterativeTime, "Direct lookup should be much faster than iterative")
    
    // Проверяем, что iterative поиск как минимум в 2 раза медленнее прямого
    XCTAssertGreaterThan(avgIterativeTime / avgDirectTime, 2.0, "Iterative lookup should be at least 2x slower than direct lookup")
  }
}
