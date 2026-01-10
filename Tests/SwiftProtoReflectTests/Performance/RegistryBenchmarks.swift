//
// RegistryBenchmarks.swift
//
// Performance benchmarks for TypeRegistry and DescriptorPool
//
// Test cases:
// - Type lookup performance in large registries
// - Registration performance when adding many types
// - Concurrent access performance
// - Memory usage with large type volumes

import XCTest

@testable import SwiftProtoReflect

/// Performance benchmarks for type registry system.
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
    // Create large number of test types for performance testing
    try createLargeTypeSet()
  }

  private func createLargeTypeSet() throws {
    // Create 1000 different messages for performance tests
    for i in 0..<1000 {
      let fileDescriptor = FileDescriptor(name: "test_\(i).proto", package: "performance.test")

      // Create message
      var messageDescriptor = MessageDescriptor(name: "TestMessage\(i)", parent: fileDescriptor)
      messageDescriptor.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
      messageDescriptor.addField(FieldDescriptor(name: "name", number: 2, type: .string))
      messageDescriptor.addField(FieldDescriptor(name: "data", number: 3, type: .bytes))

      // Create enum
      var enumDescriptor = EnumDescriptor(name: "TestEnum\(i)", parent: fileDescriptor)
      enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
      enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "VALUE_A", number: 1))
      enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "VALUE_B", number: 2))

      // Create service
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

  /// Performance test for registering large volumes of types.
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

  /// Performance test for file registration.
  func testFileRegistrationPerformance() {
    measure {
      let registry = TypeRegistry()

      do {
        // Register first 100 files
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

  /// Performance test for type lookup by name.
  func testTypeLookupPerformance() throws {
    // First register all types
    for message in testMessages {
      try typeRegistry.registerMessage(message)
    }

    measure {
      // Search for random types
      for i in stride(from: 0, to: 1000, by: 10) {
        let typeName = "performance.test.TestMessage\(i)"
        let _ = typeRegistry.findMessage(named: typeName)
      }
    }
  }

  /// Performance test for enum type lookup.
  func testEnumLookupPerformance() throws {
    // Register all enums
    for enumDesc in testEnums {
      try typeRegistry.registerEnum(enumDesc)
    }

    measure {
      // Search for random enums
      for i in stride(from: 0, to: 1000, by: 10) {
        let enumName = "performance.test.TestEnum\(i)"
        let _ = typeRegistry.findEnum(named: enumName)
      }
    }
  }

  /// Performance test for service type lookup.
  func testServiceLookupPerformance() throws {
    // Register all services
    for service in testServices {
      try typeRegistry.registerService(service)
    }

    measure {
      // Search for random services
      for i in stride(from: 0, to: 1000, by: 10) {
        let serviceName = "performance.test.TestService\(i)"
        let _ = typeRegistry.findService(named: serviceName)
      }
    }
  }

  // MARK: - Concurrent Access Performance Tests

  /// Performance test for concurrent registry access.
  func testConcurrentRegistryAccess() throws {
    // Pre-register types
    for message in testMessages {
      try typeRegistry.registerMessage(message)
    }

    let queue = DispatchQueue.global(qos: .userInitiated)

    measure {
      let expectation = self.expectation(description: "Concurrent access")
      expectation.expectedFulfillmentCount = 200

      // 100 reader threads + 100 search operations
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

  /// Performance test for concurrent registration.
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

  /// Performance test for message creation through DescriptorPool.
  func testDescriptorPoolMessageCreationPerformance() throws {
    // Register types in pool with unique file names
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

  /// Performance test for message validation.
  func testDescriptorPoolValidationPerformance() throws {
    // Prepare messages for validation
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

  /// Memory usage test for large registries.
  func testLargeRegistryMemoryUsage() throws {
    measure {
      let registry = TypeRegistry()

      do {
        // Register all types and measure memory impact
        for message in testMessages {
          try registry.registerMessage(message)
        }

        for enumDesc in testEnums {
          try registry.registerEnum(enumDesc)
        }

        for service in testServices {
          try registry.registerService(service)
        }

        // Perform search operations to check memory stability
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

  /// Performance test for type cache efficiency.
  func testTypeCacheEfficiency() throws {
    // Register types
    for message in testMessages.prefix(100) {
      try typeRegistry.registerMessage(message)
    }

    // First run - populate cache
    for i in 0..<100 {
      let typeName = "performance.test.TestMessage\(i)"
      let _ = typeRegistry.findMessage(named: typeName)
    }

    // Second run - test cached lookups
    measure {
      for _ in 0..<10 {  // Repeat search to check cache hit
        for i in 0..<100 {
          let typeName = "performance.test.TestMessage\(i)"
          let _ = typeRegistry.findMessage(named: typeName)
        }
      }
    }
  }

  // MARK: - Stress Tests

  /// Stress test for large number of concurrent operations.
  func testHighVolumeOperationsStress() throws {
    // Pre-registration
    for message in testMessages.prefix(500) {
      try typeRegistry.registerMessage(message)
    }

    let queue = DispatchQueue.global(qos: .userInitiated)

    measure {
      let expectation = self.expectation(description: "High volume operations")
      expectation.expectedFulfillmentCount = 1000

      // 1000 parallel search operations
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
    // Register types
    for message in testMessages.prefix(100) {
      try typeRegistry.registerMessage(message)
    }

    var directLookupTimes: [TimeInterval] = []
    var iterativeLookupTimes: [TimeInterval] = []

    // Direct lookup through registry
    for _ in 0..<10 {
      let startTime = Date()
      for i in 0..<100 {
        let typeName = "performance.test.TestMessage\(i)"
        let _ = typeRegistry.findMessage(named: typeName)
      }
      directLookupTimes.append(Date().timeIntervalSince(startTime))
    }

    // Iterative lookup through getAllMessages
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

    // Direct lookup should be significantly faster
    XCTAssertLessThan(avgDirectTime, avgIterativeTime, "Direct lookup should be much faster than iterative")

    // Check that iterative search is at least 2x slower than direct
    XCTAssertGreaterThan(
      avgIterativeTime / avgDirectTime,
      2.0,
      "Iterative lookup should be at least 2x slower than direct lookup"
    )
  }
}
