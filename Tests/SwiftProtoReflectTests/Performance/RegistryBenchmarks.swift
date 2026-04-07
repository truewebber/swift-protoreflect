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

/// Prevents the compiler from optimising away unused return values in benchmarks.
@inline(never)
private func _blackhole<T>(_ value: T) {}

/// Performance benchmarks for type registry system.
final class RegistryBenchmarks: XCTestCase {

  // MARK: - Test Setup

  nonisolated(unsafe) private var typeRegistry: TypeRegistry!
  nonisolated(unsafe) private var descriptorPool: DescriptorPool!
  nonisolated(unsafe) private var testMessages: [MessageDescriptor] = []
  nonisolated(unsafe) private var testEnums: [EnumDescriptor] = []
  nonisolated(unsafe) private var testServices: [ServiceDescriptor] = []

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
  func testBulkTypeRegistrationPerformance() async throws {
    let registry = TypeRegistry()

    do {
      for message in testMessages {
        try await registry.registerMessage(message)
      }

      for enumDesc in testEnums {
        try await registry.registerEnum(enumDesc)
      }

      for service in testServices {
        try await registry.registerService(service)
      }
    }
    catch {
      XCTFail("Bulk registration failed: \(error)")
    }
  }

  /// Performance test for file registration.
  func testFileRegistrationPerformance() async throws {
    let registry = TypeRegistry()

    do {
      // Register first 100 files
      for i in 0..<100 {
        let fileDescriptor = FileDescriptor(name: "test_\(i).proto", package: "performance.test")
        try await registry.registerFile(fileDescriptor)
      }
    }
    catch {
      XCTFail("File registration failed: \(error)")
    }
  }

  // MARK: - Type Lookup Performance Tests

  /// Performance test for type lookup by name.
  func testTypeLookupPerformance() async throws {
    // First register all types
    for message in testMessages {
      try await typeRegistry.registerMessage(message)
    }

    // Search for random types
    for i in stride(from: 0, to: 1000, by: 10) {
      let typeName = "performance.test.TestMessage\(i)"
      let _ = await typeRegistry.findMessage(named: typeName)
    }
  }

  /// Performance test for enum type lookup.
  func testEnumLookupPerformance() async throws {
    // Register all enums
    for enumDesc in testEnums {
      try await typeRegistry.registerEnum(enumDesc)
    }

    // Search for random enums
    for i in stride(from: 0, to: 1000, by: 10) {
      let enumName = "performance.test.TestEnum\(i)"
      let _ = await typeRegistry.findEnum(named: enumName)
    }
  }

  /// Performance test for service type lookup.
  func testServiceLookupPerformance() async throws {
    // Register all services
    for service in testServices {
      try await typeRegistry.registerService(service)
    }

    // Search for random services
    for i in stride(from: 0, to: 1000, by: 10) {
      let serviceName = "performance.test.TestService\(i)"
      let _ = await typeRegistry.findService(named: serviceName)
    }
  }

  // MARK: - Concurrent Access Performance Tests

  /// Performance test for concurrent registry access.
  func testConcurrentRegistryAccess() async throws {
    // Pre-register types
    for message in testMessages {
      try await typeRegistry.registerMessage(message)
    }

    let queue = DispatchQueue.global(qos: .userInitiated)

    let expectation = self.expectation(description: "Concurrent access")
    expectation.expectedFulfillmentCount = 200

    let registry = self.typeRegistry!
    // 100 reader threads + 100 search operations
    for i in 0..<100 {
      queue.async {
        Task {
          let typeName = "performance.test.TestMessage\(i % 100)"
          let _ = await registry.findMessage(named: typeName)
          expectation.fulfill()
        }
      }

      queue.async {
        Task {
          let enumName = "performance.test.TestEnum\(i % 100)"
          let _ = await registry.findEnum(named: enumName)
          expectation.fulfill()
        }
      }
    }

    await fulfillment(of: [expectation], timeout: 10.0)
  }

  /// Performance test for concurrent registration.
  func testConcurrentRegistrationPerformance() async throws {
    let queue = DispatchQueue.global(qos: .userInitiated)

    let registry = TypeRegistry()
    let expectation = self.expectation(description: "Concurrent registration")
    expectation.expectedFulfillmentCount = 100

    let messages = self.testMessages
    for i in 0..<100 {
      queue.async {
        Task {
          do {
            if i < messages.count {
              try await registry.registerMessage(messages[i])
            }
          }
          catch {
            // Ignore registration errors for performance testing
          }
          expectation.fulfill()
        }
      }
    }

    await fulfillment(of: [expectation], timeout: 10.0)
  }

  // MARK: - DescriptorPool Performance Tests

  /// Performance test for message creation through DescriptorPool.
  func testDescriptorPoolMessageCreationPerformance() async throws {
    // Register types in pool with unique file names
    for i in testMessages.prefix(100).indices {
      try await descriptorPool.addFileDescriptor(FileDescriptor(name: "test\(i).proto", package: "performance.test"))
    }

    for i in 0..<100 {
      let typeName = "performance.test.TestMessage\(i)"
      let _ = try await descriptorPool.createMessage(
        forType: typeName,
        fieldValues: [
          "id": Int32(i),
          "name": "Test \(i)",
          "data": Data("test\(i)".utf8),
        ]
      )
    }
  }

  /// Performance test for message validation.
  func testDescriptorPoolValidationPerformance() async throws {
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
  func testLargeRegistryMemoryUsage() async throws {
    let registry = TypeRegistry()

    do {
      // Register all types and measure memory impact
      for message in testMessages {
        try await registry.registerMessage(message)
      }

      for enumDesc in testEnums {
        try await registry.registerEnum(enumDesc)
      }

      for service in testServices {
        try await registry.registerService(service)
      }

      // Perform search operations to check memory stability
      for i in 0..<100 {
        let typeName = "performance.test.TestMessage\(i)"
        let _ = await registry.findMessage(named: typeName)
      }
    }
    catch {
      XCTFail("Large registry test failed: \(error)")
    }
  }

  // MARK: - Cache Performance Tests

  /// Performance test for type cache efficiency.
  func testTypeCacheEfficiency() async throws {
    // Register types
    for message in testMessages.prefix(100) {
      try await typeRegistry.registerMessage(message)
    }

    // First run - populate cache
    for i in 0..<100 {
      let typeName = "performance.test.TestMessage\(i)"
      let _ = await typeRegistry.findMessage(named: typeName)
    }

    // Second run - test cached lookups
    for _ in 0..<10 {  // Repeat search to check cache hit
      for i in 0..<100 {
        let typeName = "performance.test.TestMessage\(i)"
        let _ = await typeRegistry.findMessage(named: typeName)
      }
    }
  }

  // MARK: - Stress Tests

  /// Stress test for large number of concurrent operations.
  func testHighVolumeOperationsStress() async throws {
    // Pre-registration
    for message in testMessages.prefix(500) {
      try await typeRegistry.registerMessage(message)
    }

    let queue = DispatchQueue.global(qos: .userInitiated)

    let expectation = self.expectation(description: "High volume operations")
    expectation.expectedFulfillmentCount = 1000

    let registry = self.typeRegistry!
    // 1000 parallel search operations
    for i in 0..<1000 {
      queue.async {
        Task {
          let typeName = "performance.test.TestMessage\(i % 500)"
          let _ = await registry.findMessage(named: typeName)
          expectation.fulfill()
        }
      }
    }

    await fulfillment(of: [expectation], timeout: 15.0)
  }

  // MARK: - Comparative Tests

  /// Comparison between TypeRegistry (actor-isolated) and a plain Dictionary baseline
  /// at a fixed size of 100 types, 1 000 measured iterations each (like Go b.N).
  ///
  /// The plain Dictionary represents the minimum possible overhead for a name → descriptor
  /// lookup — essentially what a compiled protobuf runtime does. The gap between the two
  /// shows the cost of actor isolation in TypeRegistry.
  func testLookupStrategyComparison() async throws {
    try await runLookupComparison(size: 100, overheadLimit: 50.0)
  }

  /// Scalability comparison: TypeRegistry vs plain Dictionary across registry sizes
  /// 100, 1 000, 10 000 and 100 000.
  ///
  /// Each size is measured with 1 000 individual lookup iterations so per-op latency
  /// is accurate. A rising ratio across sizes signals a structural regression.
  func testLookupScalabilityComparison() async throws {
    let sizes: [(size: Int, label: String)] = [
      (100, "100"),
      (1_000, "1k"),
      (10_000, "10k"),
      (100_000, "100k"),
    ]

    print("\n--- Lookup scalability: TypeRegistry vs plain Dictionary (1 000 iterations each) ---")
    print(String(format: "%-8@ %14@ %14@ %10@", "Size", "Actor (ns/op)", "Dict (ns/op)", "Ratio"))
    print(String(repeating: "-", count: 52))

    for (size, label) in sizes {
      let (actorNs, dictNs, ratio) = try await runLookupComparison(
        size: size,
        overheadLimit: 500.0,
        namespace: "scalability.\(label)"
      )
      print(String(format: "%-8@ %14.1f %14.1f %9.1fx", label, actorNs, dictNs, ratio))
    }
  }

  // MARK: - Helpers

  /// Builds `size` MessageDescriptors grouped into files of `msgsPerFile` each, registers
  /// them in a new TypeRegistry and a plain Dictionary, warms both up, then measures
  /// exactly `iterations` individual lookups — like Go's `b.N` pattern.
  ///
  /// Grouping reduces the number of FileDescriptor objects in memory, preventing crashes
  /// at large sizes (e.g. 100k).
  ///
  /// - Returns: (actorNsPerOp, dictNsPerOp, ratio) — nanoseconds per single lookup.
  @discardableResult
  private func runLookupComparison(
    size: Int,
    iterations: Int = 1_000,
    warmup: Int = 100,
    overheadLimit: Double,
    namespace: String = "comparison",
    msgsPerFile: Int = 100
  ) async throws -> (actorNsPerOp: Double, dictNsPerOp: Double, ratio: Double) {
    var fileDescriptors: [FileDescriptor] = []
    var baseline: [String: MessageDescriptor] = [:]
    let package = "perf.\(namespace)"

    let numFiles = (size + msgsPerFile - 1) / msgsPerFile
    for f in 0..<numFiles {
      var file = FileDescriptor(name: "\(namespace)_\(f).proto", package: package)
      for m in 0..<msgsPerFile {
        let i = f * msgsPerFile + m
        guard i < size else { break }
        var msg = MessageDescriptor(name: "Msg\(i)", parent: file)
        msg.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
        baseline["\(package).Msg\(i)"] = msg
        file.addMessage(msg)
      }
      fileDescriptors.append(file)
    }

    let registry = try await TypeRegistry(fileDescriptors: fileDescriptors)

    // Pre-build lookup keys so String allocation is NOT included in measurement
    let keys = (0..<iterations).map { "\(package).Msg\($0 % size)" }
    let warmupKeys = (0..<warmup).map { "\(package).Msg\($0 % size)" }

    // Warmup — not measured, ensures caches and actor executor are primed
    for key in warmupKeys {
      _blackhole(await registry.findMessage(named: key))
      _blackhole(baseline[key])
    }

    // Measure actor: total wall time for `iterations` sequential lookups
    let actorStart = Date()
    for key in keys {
      _blackhole(await registry.findMessage(named: key))
    }
    let actorTotal = Date().timeIntervalSince(actorStart)

    // Measure plain Dictionary: total wall time for the same `iterations` lookups
    let dictStart = Date()
    for key in keys {
      _blackhole(baseline[key])
    }
    let dictTotal = Date().timeIntervalSince(dictStart)

    let actorNsPerOp = actorTotal / Double(iterations) * 1_000_000_000
    let dictNsPerOp = dictTotal / Double(iterations) * 1_000_000_000
    let ratio = actorNsPerOp / max(dictNsPerOp, 1e-6)

    XCTAssertLessThan(
      ratio,
      overheadLimit,
      "TypeRegistry overhead vs plain Dictionary should be <\(overheadLimit)x at size \(size)"
    )

    return (actorNsPerOp, dictNsPerOp, ratio)
  }
}
