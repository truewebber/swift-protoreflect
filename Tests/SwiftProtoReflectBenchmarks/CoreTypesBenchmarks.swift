import XCTest

@testable import SwiftProtoReflect

class CoreTypesBenchmarks: XCTestCase {

  // MARK: - ProtoValue Benchmarks

  func testProtoValueCreationPerformance() {
    let result = BenchmarkUtils.benchmark(name: "ProtoValue.creation", iterations: 100000) {
      _ = ProtoValue.intValue(42)
      _ = ProtoValue.stringValue("Hello")
      _ = ProtoValue.boolValue(true)
      _ = ProtoValue.doubleValue(3.14)
    }

    XCTAssertTrue(result.averageDurationMs < 0.01, "ProtoValue creation should be extremely fast (< 0.01ms)")
  }

  func testProtoValueAccessPerformance() {
    let intValue = ProtoValue.intValue(42)
    let stringValue = ProtoValue.stringValue("Hello")
    let boolValue = ProtoValue.boolValue(true)
    let doubleValue = ProtoValue.doubleValue(3.14)

    let result = BenchmarkUtils.benchmark(name: "ProtoValue.access", iterations: 100000) {
      _ = intValue.getInt()
      _ = stringValue.getString()
      _ = boolValue.getBool()
      _ = doubleValue.getDouble()
    }

    XCTAssertTrue(result.averageDurationMs < 0.01, "ProtoValue access should be extremely fast (< 0.01ms)")
  }

  func testProtoValueHashablePerformance() {
    let values: [ProtoValue] = [
      .intValue(42),
      .stringValue("Hello"),
      .boolValue(true),
      .doubleValue(3.14),
      .bytesValue(Data([0x01, 0x02, 0x03])),
      .repeatedValue([.intValue(1), .intValue(2), .intValue(3)]),
      .mapValue(["key1": .intValue(1), "key2": .stringValue("value")]),
    ]

    let result = BenchmarkUtils.benchmark(name: "ProtoValue.hashable", iterations: 10000) {
      var set = Set<ProtoValue>()
      for value in values {
        set.insert(value)
      }
      _ = set.count
    }

    XCTAssertTrue(result.averageDurationMs < 0.1, "ProtoValue hashable operations should be fast (< 0.1ms)")
  }

  func testProtoValueEqualityPerformance() {
    let value1 = ProtoValue.mapValue([
      "key1": .intValue(1),
      "key2": .stringValue("value"),
      "key3": .repeatedValue([.intValue(1), .intValue(2), .intValue(3)]),
    ])

    let value2 = ProtoValue.mapValue([
      "key1": .intValue(1),
      "key2": .stringValue("value"),
      "key3": .repeatedValue([.intValue(1), .intValue(2), .intValue(3)]),
    ])

    let result = BenchmarkUtils.benchmark(name: "ProtoValue.equality", iterations: 10000) {
      _ = value1 == value2
    }

    XCTAssertTrue(result.averageDurationMs < 0.05, "ProtoValue equality check should be fast (< 0.05ms)")
  }

  // MARK: - ProtoFieldDescriptor Benchmarks

  func testProtoFieldDescriptorCreationPerformance() {
    let result = BenchmarkUtils.benchmark(name: "ProtoFieldDescriptor.creation", iterations: 10000) {
      _ = ProtoFieldDescriptor(
        name: "test_field",
        number: 1,
        type: .int32,
        isRepeated: false,
        isMap: false
      )
    }

    XCTAssertTrue(result.averageDurationMs < 0.01, "ProtoFieldDescriptor creation should be extremely fast (< 0.01ms)")
  }

  func testProtoFieldDescriptorValidationPerformance() {
    let validField = ProtoFieldDescriptor(
      name: "test_field",
      number: 1,
      type: .int32,
      isRepeated: false,
      isMap: false
    )

    let invalidField = ProtoFieldDescriptor(
      name: "",
      number: 0,
      type: .int32,
      isRepeated: false,
      isMap: false
    )

    let result = BenchmarkUtils.benchmark(name: "ProtoFieldDescriptor.validation", iterations: 10000) {
      _ = validField.isValid()
      _ = invalidField.isValid()
    }

    XCTAssertTrue(
      result.averageDurationMs < 0.01,
      "ProtoFieldDescriptor validation should be extremely fast (< 0.01ms)"
    )
  }

  func testProtoFieldDescriptorHashablePerformance() {
    let fields: [ProtoFieldDescriptor] = [
      ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false),
      ProtoFieldDescriptor(name: "field2", number: 2, type: .string, isRepeated: false, isMap: false),
      ProtoFieldDescriptor(name: "field3", number: 3, type: .bool, isRepeated: false, isMap: false),
      ProtoFieldDescriptor(name: "field4", number: 4, type: .double, isRepeated: false, isMap: false),
      ProtoFieldDescriptor(name: "field5", number: 5, type: .bytes, isRepeated: false, isMap: false),
    ]

    let result = BenchmarkUtils.benchmark(name: "ProtoFieldDescriptor.hashable", iterations: 10000) {
      var set = Set<ProtoFieldDescriptor>()
      for field in fields {
        set.insert(field)
      }
      _ = set.count
    }

    XCTAssertTrue(result.averageDurationMs < 0.05, "ProtoFieldDescriptor hashable operations should be fast (< 0.05ms)")
  }

  // MARK: - ProtoMessageDescriptor Benchmarks

  func testProtoMessageDescriptorCreationPerformance() {
    let fields = [
      ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false),
      ProtoFieldDescriptor(name: "field2", number: 2, type: .string, isRepeated: false, isMap: false),
      ProtoFieldDescriptor(name: "field3", number: 3, type: .bool, isRepeated: false, isMap: false),
    ]

    let result = BenchmarkUtils.benchmark(name: "ProtoMessageDescriptor.creation", iterations: 10000) {
      _ = ProtoMessageDescriptor(
        fullName: "TestMessage",
        fields: fields,
        enums: [],
        nestedMessages: []
      )
    }

    XCTAssertTrue(result.averageDurationMs < 0.05, "ProtoMessageDescriptor creation should be fast (< 0.05ms)")
  }

  func testProtoMessageDescriptorFieldLookupPerformance() {
    let fields = [
      ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false),
      ProtoFieldDescriptor(name: "field2", number: 2, type: .string, isRepeated: false, isMap: false),
      ProtoFieldDescriptor(name: "field3", number: 3, type: .bool, isRepeated: false, isMap: false),
      ProtoFieldDescriptor(name: "field4", number: 4, type: .double, isRepeated: false, isMap: false),
      ProtoFieldDescriptor(name: "field5", number: 5, type: .bytes, isRepeated: false, isMap: false),
    ]

    let descriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: fields,
      enums: [],
      nestedMessages: []
    )

    let result = BenchmarkUtils.benchmark(name: "ProtoMessageDescriptor.fieldLookup", iterations: 100000) {
      _ = descriptor.field(named: "field3")
      _ = descriptor.field(number: 2)
    }

    XCTAssertTrue(
      result.averageDurationMs < 0.01,
      "ProtoMessageDescriptor field lookup should be extremely fast (< 0.01ms)"
    )
  }
}
