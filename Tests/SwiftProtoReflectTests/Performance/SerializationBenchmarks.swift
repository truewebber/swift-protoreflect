//
// SerializationBenchmarks.swift
//
// Tests for measuring Protocol Buffers serialization/deserialization performance
//
// Test cases from the plan:
// - Test-PERF-001: Comparison of serialization time with protoc-generated code
// - Test-PERF-002: Comparison of deserialization time with protoc-generated code
// - Test-PERF-003: Performance when working with large datasets
// - Test-PERF-004: Analysis of reflection overhead compared to compiled code

import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

/// Comprehensive performance benchmarks for serialization and deserialization.
final class SerializationBenchmarks: XCTestCase {

  // MARK: - Test Setup

  nonisolated(unsafe) private var smallMessage: DynamicMessage!
  nonisolated(unsafe) private var mediumMessage: DynamicMessage!
  nonisolated(unsafe) private var largeMessage: DynamicMessage!
  nonisolated(unsafe) private var registry: TypeRegistry!
  nonisolated(unsafe) private var binarySerializer: BinarySerializer!
  nonisolated(unsafe) private var binaryDeserializer: BinaryDeserializer!
  nonisolated(unsafe) private var jsonSerializer: JSONSerializer!
  nonisolated(unsafe) private var jsonDeserializer: JSONDeserializer!

  override func setUpWithError() throws {
    try super.setUpWithError()

    registry = TypeRegistry()
    binarySerializer = BinarySerializer()
    binaryDeserializer = BinaryDeserializer()
    jsonSerializer = JSONSerializer()
    jsonDeserializer = JSONDeserializer()

    // Create test messages of different sizes
    try setupTestMessages()
  }

  private func setupTestMessages() throws {
    // Small message: simple message with a few fields
    let smallDescriptor = try createPersonDescriptor()
    try registry.registerMessage(smallDescriptor)

    smallMessage = MessageFactory().createMessage(from: smallDescriptor)
    try smallMessage.set("John Doe", forField: "name")
    try smallMessage.set(Int32(30), forField: "age")
    try smallMessage.set("john@example.com", forField: "email")

    // Medium message: message with nested structures and repeated fields
    let mediumDescriptor = try createCompanyDescriptor()
    try registry.registerMessage(mediumDescriptor)

    mediumMessage = MessageFactory().createMessage(from: mediumDescriptor)
    try mediumMessage.set("TechCorp Inc", forField: "name")
    try mediumMessage.set(Int32(1000), forField: "employee_count")

    // Add repeated fields
    let departments = ["Engineering", "Marketing", "Sales", "HR", "Finance"]
    try mediumMessage.set(departments, forField: "departments")

    // Large message: large message with many fields and data
    let largeDescriptor = try createDatabaseDescriptor()
    try registry.registerMessage(largeDescriptor)

    largeMessage = MessageFactory().createMessage(from: largeDescriptor)
    try largeMessage.set("ProductDB", forField: "name")
    try largeMessage.set(Int32(50000), forField: "record_count")

    // Create large data array
    let records = (0..<1000).map { "Record_\($0)" }
    try largeMessage.set(records, forField: "records")

    // Add map field
    let metadata: [String: String] = [
      "version": "2.1.0",
      "environment": "production",
      "region": "us-west-2",
      "backup_schedule": "daily",
    ]
    try largeMessage.set(metadata, forField: "metadata")
  }

  // MARK: - Binary Serialization Performance Tests

  /// Test-PERF-001: Binary serialization performance - small messages.
  func testBinarySerializationPerformanceSmall() {
    measure {
      do {
        let _ = try binarySerializer.serialize(smallMessage)
      }
      catch {
        XCTFail("Serialization failed: \(error)")
      }
    }
  }

  /// Test-PERF-001: Binary serialization performance - medium messages.
  func testBinarySerializationPerformanceMedium() {
    measure {
      do {
        let _ = try binarySerializer.serialize(mediumMessage)
      }
      catch {
        XCTFail("Serialization failed: \(error)")
      }
    }
  }

  /// Test-PERF-001: Binary serialization performance - large messages.
  func testBinarySerializationPerformanceLarge() {
    measure {
      do {
        let _ = try binarySerializer.serialize(largeMessage)
      }
      catch {
        XCTFail("Serialization failed: \(error)")
      }
    }
  }

  // MARK: - Binary Deserialization Performance Tests

  /// Test-PERF-002: Binary deserialization performance - small messages.
  func testBinaryDeserializationPerformanceSmall() throws {
    let serializedData = try binarySerializer.serialize(smallMessage)

    measure {
      do {
        let _ = try binaryDeserializer.deserialize(
          serializedData,
          using: smallMessage.descriptor
        )
      }
      catch {
        XCTFail("Deserialization failed: \(error)")
      }
    }
  }

  /// Test-PERF-002: Binary deserialization performance - medium messages.
  func testBinaryDeserializationPerformanceMedium() throws {
    let serializedData = try binarySerializer.serialize(mediumMessage)

    measure {
      do {
        let _ = try binaryDeserializer.deserialize(
          serializedData,
          using: mediumMessage.descriptor
        )
      }
      catch {
        XCTFail("Deserialization failed: \(error)")
      }
    }
  }

  /// Test-PERF-002: Binary deserialization performance - large messages.
  func testBinaryDeserializationPerformanceLarge() throws {
    let serializedData = try binarySerializer.serialize(largeMessage)

    measure {
      do {
        let _ = try binaryDeserializer.deserialize(
          serializedData,
          using: largeMessage.descriptor
        )
      }
      catch {
        XCTFail("Deserialization failed: \(error)")
      }
    }
  }

  // MARK: - JSON Serialization Performance Tests

  /// Test-PERF-001: JSON serialization performance - small messages.
  func testJSONSerializationPerformanceSmall() {
    measure {
      do {
        let _ = try jsonSerializer.serialize(smallMessage)
      }
      catch {
        XCTFail("JSON serialization failed: \(error)")
      }
    }
  }

  /// Test-PERF-001: JSON serialization performance - medium messages.
  func testJSONSerializationPerformanceMedium() {
    measure {
      do {
        let _ = try jsonSerializer.serialize(mediumMessage)
      }
      catch {
        XCTFail("JSON serialization failed: \(error)")
      }
    }
  }

  /// Test-PERF-001: JSON serialization performance - large messages.
  func testJSONSerializationPerformanceLarge() {
    measure {
      do {
        let _ = try jsonSerializer.serialize(largeMessage)
      }
      catch {
        XCTFail("JSON serialization failed: \(error)")
      }
    }
  }

  // MARK: - JSON Deserialization Performance Tests

  /// Test-PERF-002: JSON deserialization performance - small messages.
  func testJSONDeserializationPerformanceSmall() throws {
    let jsonData = try jsonSerializer.serialize(smallMessage)

    measure {
      do {
        let _ = try jsonDeserializer.deserialize(
          jsonData,
          using: smallMessage.descriptor
        )
      }
      catch {
        XCTFail("JSON deserialization failed: \(error)")
      }
    }
  }

  /// Test-PERF-002: JSON deserialization performance - medium messages.
  func testJSONDeserializationPerformanceMedium() throws {
    let jsonData = try jsonSerializer.serialize(mediumMessage)

    measure {
      do {
        let _ = try jsonDeserializer.deserialize(
          jsonData,
          using: mediumMessage.descriptor
        )
      }
      catch {
        XCTFail("JSON deserialization failed: \(error)")
      }
    }
  }

  /// Test-PERF-002: JSON deserialization performance - large messages.
  func testJSONDeserializationPerformanceLarge() throws {
    let jsonData = try jsonSerializer.serialize(largeMessage)

    measure {
      do {
        let _ = try jsonDeserializer.deserialize(
          jsonData,
          using: largeMessage.descriptor
        )
      }
      catch {
        XCTFail("JSON deserialization failed: \(error)")
      }
    }
  }

  // MARK: - Round Trip Performance Tests

  /// Test-PERF-003: Binary round-trip performance with large datasets.
  func testBinaryRoundTripPerformanceLarge() throws {
    measure {
      do {
        let serializedData = try binarySerializer.serialize(largeMessage)
        let _ = try binaryDeserializer.deserialize(
          serializedData,
          using: largeMessage.descriptor
        )
      }
      catch {
        XCTFail("Round-trip failed: \(error)")
      }
    }
  }

  /// Test-PERF-003: JSON round-trip performance with large datasets.
  func testJSONRoundTripPerformanceLarge() throws {
    measure {
      do {
        let jsonData = try jsonSerializer.serialize(largeMessage)
        let _ = try jsonDeserializer.deserialize(
          jsonData,
          using: largeMessage.descriptor
        )
      }
      catch {
        XCTFail("JSON round-trip failed: \(error)")
      }
    }
  }

  // MARK: - Comparative Performance Tests

  /// Test-PERF-004: Comparison of binary vs JSON serialization.
  func testBinaryVsJSONSerializationComparison() throws {
    var binaryTimes: [TimeInterval] = []
    var jsonTimes: [TimeInterval] = []

    // Measure binary serialization
    for _ in 0..<10 {
      let startTime = Date()
      let _ = try binarySerializer.serialize(mediumMessage)
      binaryTimes.append(Date().timeIntervalSince(startTime))
    }

    // Measure JSON serialization
    for _ in 0..<10 {
      let startTime = Date()
      let _ = try jsonSerializer.serialize(mediumMessage)
      jsonTimes.append(Date().timeIntervalSince(startTime))
    }

    let avgBinaryTime = binaryTimes.reduce(0, +) / Double(binaryTimes.count)
    let avgJSONTime = jsonTimes.reduce(0, +) / Double(jsonTimes.count)

    print("Binary serialization average time: \(avgBinaryTime * 1000) ms")
    print("JSON serialization average time: \(avgJSONTime * 1000) ms")
    print("Performance ratio (JSON/Binary): \(avgJSONTime / avgBinaryTime)")

    // JSON is usually slower than binary, but we check that the difference is reasonable
    XCTAssertLessThan(avgJSONTime / avgBinaryTime, 20.0, "JSON should not be more than 20x slower than binary")
  }

  // MARK: - Memory Usage Tests

  /// Test-PERF-003: Memory usage during large message processing.
  func testMemoryUsageLargeMessage() throws {
    // Create very large message to test memory usage
    let veryLargeDescriptor = try createVeryLargeDataDescriptor()
    try registry.registerMessage(veryLargeDescriptor)

    var veryLargeMessage = MessageFactory().createMessage(from: veryLargeDescriptor)

    let largeData = (0..<2000).map { "LargeDataEntry_\($0)_With_Long_Content_To_Test_Memory_Usage" }
    try veryLargeMessage.set(largeData, forField: "data_entries")

    measure {
      do {
        let serializedData = try binarySerializer.serialize(veryLargeMessage)
        let _ = try binaryDeserializer.deserialize(
          serializedData,
          using: veryLargeMessage.descriptor
        )
      }
      catch {
        XCTFail("Large message processing failed: \(error)")
      }
    }
  }

  // MARK: - Stress Testing

  /// Test-PERF-003: Concurrent serialization stress test.
  func testConcurrentSerializationStress() throws {
    let queue = DispatchQueue.global(qos: .userInitiated)

    measure {
      let expectation = self.expectation(description: "Concurrent serialization")
      expectation.expectedFulfillmentCount = 100

      let serializer = self.binarySerializer!
      let message = self.mediumMessage!
      for _ in 0..<100 {
        queue.async {
          do {
            let _ = try serializer.serialize(message)
            expectation.fulfill()
          }
          catch {
            XCTFail("Concurrent serialization failed: \(error)")
          }
        }
      }

      wait(for: [expectation], timeout: 10.0)
    }
  }

  // MARK: - Helper Methods for Test Message Creation

  private func createPersonDescriptor() throws -> MessageDescriptor {
    let fileDescriptor = FileDescriptor(name: "person.proto", package: "performance.test")
    var personMessage = MessageDescriptor(name: "Person", parent: fileDescriptor)

    personMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    personMessage.addField(FieldDescriptor(name: "age", number: 2, type: .int32))
    personMessage.addField(FieldDescriptor(name: "email", number: 3, type: .string))

    var fileDescriptorMutable = fileDescriptor
    fileDescriptorMutable.addMessage(personMessage)
    return personMessage
  }

  private func createCompanyDescriptor() throws -> MessageDescriptor {
    let fileDescriptor = FileDescriptor(name: "company.proto", package: "performance.test")
    var companyMessage = MessageDescriptor(name: "Company", parent: fileDescriptor)

    companyMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    companyMessage.addField(FieldDescriptor(name: "employee_count", number: 2, type: .int32))
    companyMessage.addField(FieldDescriptor(name: "departments", number: 3, type: .string, isRepeated: true))

    var fileDescriptorMutable = fileDescriptor
    fileDescriptorMutable.addMessage(companyMessage)
    return companyMessage
  }

  private func createDatabaseDescriptor() throws -> MessageDescriptor {
    let fileDescriptor = FileDescriptor(name: "database.proto", package: "performance.test")
    var databaseMessage = MessageDescriptor(name: "Database", parent: fileDescriptor)

    databaseMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    databaseMessage.addField(FieldDescriptor(name: "record_count", number: 2, type: .int32))
    databaseMessage.addField(FieldDescriptor(name: "records", number: 3, type: .string, isRepeated: true))
    databaseMessage.addField(
      FieldDescriptor(
        name: "metadata",
        number: 4,
        type: .string,
        isMap: true,
        mapEntryInfo: MapEntryInfo(
          keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
          valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .string)
        )
      )
    )

    var fileDescriptorMutable = fileDescriptor
    fileDescriptorMutable.addMessage(databaseMessage)
    return databaseMessage
  }

  private func createVeryLargeDataDescriptor() throws -> MessageDescriptor {
    let fileDescriptor = FileDescriptor(name: "large_data.proto", package: "performance.test")
    var largeDataMessage = MessageDescriptor(name: "VeryLargeData", parent: fileDescriptor)

    largeDataMessage.addField(FieldDescriptor(name: "data_entries", number: 1, type: .string, isRepeated: true))

    var fileDescriptorMutable = fileDescriptor
    fileDescriptorMutable.addMessage(largeDataMessage)
    return largeDataMessage
  }
}
