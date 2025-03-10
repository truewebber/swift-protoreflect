import XCTest

@testable import SwiftProtoReflect

class ProtoWireFormatBenchmarks: XCTestCase {

  var messageDescriptor: ProtoMessageDescriptor!

  override func setUp() {
    super.setUp()

    // Create a message descriptor with various field types
    messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "int_field", number: 1, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "string_field", number: 2, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "bool_field", number: 3, type: .bool, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "double_field", number: 4, type: .double, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "bytes_field", number: 5, type: .bytes, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )
  }

  func testVarintEncodingPerformance() {
    let result = BenchmarkUtils.benchmark(name: "ProtoWireFormat.encodeVarint", iterations: 100000) {
      _ = ProtoWireFormat.encodeVarint(UInt64.random(in: 0...UInt64.max))
    }

    XCTAssertTrue(result.averageDurationMs < 0.01, "Varint encoding should be extremely fast (< 0.01ms)")
  }

  func testVarintDecodingPerformance() {
    // Create a set of test data
    let testData = Data([0x96, 0x01])  // 150 as a varint

    let result = BenchmarkUtils.benchmark(name: "ProtoWireFormat.decodeVarint", iterations: 100000) {
      _ = ProtoWireFormat.decodeVarint(testData)
    }

    XCTAssertTrue(result.averageDurationMs < 0.01, "Varint decoding should be extremely fast (< 0.01ms)")
  }

  func testFieldEncodingPerformance() {
    // Test encoding a string field
    let field = messageDescriptor.fields[1]  // string_field
    let value = ProtoValue.stringValue("Hello, world!")

    let result = BenchmarkUtils.benchmark(name: "ProtoWireFormat.encodeField", iterations: 10000) {
      var data = Data()
      try? ProtoWireFormat.encodeField(field: field, value: value, to: &data)
    }

    XCTAssertTrue(result.averageDurationMs < 0.05, "Field encoding should be fast (< 0.05ms)")
  }

  func testWireTypePerformance() {
    let result = BenchmarkUtils.benchmark(name: "ProtoWireFormat.determineWireType", iterations: 100000) {
      _ = ProtoWireFormat.determineWireType(for: .int32)
      _ = ProtoWireFormat.determineWireType(for: .string)
      _ = ProtoWireFormat.determineWireType(for: .message)
      _ = ProtoWireFormat.determineWireType(for: .bytes)
      _ = ProtoWireFormat.determineWireType(for: .float)
    }

    XCTAssertTrue(result.averageDurationMs < 0.01, "Wire type determination should be extremely fast (< 0.01ms)")
  }
}
