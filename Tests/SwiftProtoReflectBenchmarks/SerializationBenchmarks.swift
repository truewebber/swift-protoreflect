import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

class SerializationBenchmarks: XCTestCase {

  // Test message descriptor with various field types
  var messageDescriptor: ProtoMessageDescriptor!

  // Test message with values for all field types
  var testMessage: ProtoDynamicMessage!

  // Serialized data for deserialization benchmarks
  var serializedData: Data!

  override func setUp() {
    super.setUp()

    // Create a message descriptor with all primitive field types
    messageDescriptor = ProtoMessageDescriptor(
      fullName: "BenchmarkMessage",
      fields: [
        ProtoFieldDescriptor(name: "int32_field", number: 1, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "int64_field", number: 2, type: .int64, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "uint32_field", number: 3, type: .uint32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "uint64_field", number: 4, type: .uint64, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "sint32_field", number: 5, type: .sint32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "sint64_field", number: 6, type: .sint64, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "fixed32_field", number: 7, type: .fixed32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "fixed64_field", number: 8, type: .fixed64, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "sfixed32_field", number: 9, type: .sfixed32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "sfixed64_field", number: 10, type: .sfixed64, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "float_field", number: 11, type: .float, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "double_field", number: 12, type: .double, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "bool_field", number: 13, type: .bool, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "string_field", number: 14, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "bytes_field", number: 15, type: .bytes, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "repeated_int32", number: 16, type: .int32, isRepeated: true, isMap: false),
        ProtoFieldDescriptor(name: "repeated_string", number: 17, type: .string, isRepeated: true, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a message with values for each field
    testMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
    testMessage.set(fieldName: "int32_field", value: .intValue(42))
    testMessage.set(fieldName: "int64_field", value: .intValue(9_223_372_036_854_775_807))  // Max Int64
    testMessage.set(fieldName: "uint32_field", value: .uintValue(4_294_967_295))  // Max UInt32
    testMessage.set(fieldName: "uint64_field", value: .uintValue(18_446_744_073_709_551_615))  // Max UInt64
    testMessage.set(fieldName: "sint32_field", value: .intValue(-42))
    testMessage.set(fieldName: "sint64_field", value: .intValue(-9_223_372_036_854_775_808))  // Min Int64
    testMessage.set(fieldName: "fixed32_field", value: .uintValue(42))
    testMessage.set(fieldName: "fixed64_field", value: .uintValue(42))
    testMessage.set(fieldName: "sfixed32_field", value: .intValue(-42))
    testMessage.set(fieldName: "sfixed64_field", value: .intValue(-42))
    testMessage.set(fieldName: "float_field", value: .floatValue(3.14159))
    testMessage.set(fieldName: "double_field", value: .doubleValue(2.71828))
    testMessage.set(fieldName: "bool_field", value: .boolValue(true))
    testMessage.set(fieldName: "string_field", value: .stringValue("Hello, Protocol Buffers!"))
    testMessage.set(fieldName: "bytes_field", value: .bytesValue(Data([0x00, 0x01, 0x02, 0x03, 0xFF])))

    // Set repeated fields
    var repeatedInts: [ProtoValue] = []
    for i in 0..<100 {
      repeatedInts.append(.intValue(i))
    }
    testMessage.set(fieldName: "repeated_int32", value: .repeatedValue(repeatedInts))

    var repeatedStrings: [ProtoValue] = []
    for i in 0..<100 {
      repeatedStrings.append(.stringValue("String \(i)"))
    }
    testMessage.set(fieldName: "repeated_string", value: .repeatedValue(repeatedStrings))

    // Serialize the message once to get the data for deserialization benchmarks
    serializedData = ProtoWireFormat.marshal(message: testMessage)!
  }

  func testSerializationPerformance() {
    // Measure the performance of serializing a message
    measure {
      for _ in 0..<1000 {
        _ = ProtoWireFormat.marshal(message: testMessage)
      }
    }
  }

  func testDeserializationPerformance() {
    // Measure the performance of deserializing a message
    measure {
      for _ in 0..<1000 {
        _ = ProtoWireFormat.unmarshal(data: serializedData, messageDescriptor: messageDescriptor)
      }
    }
  }

  func testSerializationSizeEfficiency() {
    // Test the size efficiency of the serialized data

    // Create a simple message with just a few fields
    let simpleDescriptor = ProtoMessageDescriptor(
      fullName: "SimpleMessage",
      fields: [
        ProtoFieldDescriptor(name: "int32_field", number: 1, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "string_field", number: 2, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "bool_field", number: 3, type: .bool, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    let simpleMessage = ProtoDynamicMessage(descriptor: simpleDescriptor)
    simpleMessage.set(fieldName: "int32_field", value: .intValue(42))
    simpleMessage.set(fieldName: "string_field", value: .stringValue("Hello"))
    simpleMessage.set(fieldName: "bool_field", value: .boolValue(true))

    // Serialize the simple message
    let simpleData = ProtoWireFormat.marshal(message: simpleMessage)!

    // Expected size calculation:
    // int32_field: 1 byte for tag (8) + 1 byte for value (42) = 2 bytes
    // string_field: 1 byte for tag (18) + 1 byte for length (5) + 5 bytes for "Hello" = 7 bytes
    // bool_field: 1 byte for tag (24) + 1 byte for value (1) = 2 bytes
    // Total: 11 bytes

    XCTAssertEqual(simpleData.count, 11, "Serialized data size should be efficient")

    // Print the actual bytes for debugging
    print("Serialized bytes: \(Array(simpleData))")
  }

  func testLargeMessagePerformance() {
    // Create a message with a large repeated field
    let largeDescriptor = ProtoMessageDescriptor(
      fullName: "LargeMessage",
      fields: [
        ProtoFieldDescriptor(name: "repeated_string", number: 1, type: .string, isRepeated: true, isMap: false)
      ],
      enums: [],
      nestedMessages: []
    )

    let largeMessage = ProtoDynamicMessage(descriptor: largeDescriptor)

    // Create 10,000 string values
    var stringValues: [ProtoValue] = []
    for i in 0..<10000 {
      stringValues.append(.stringValue("String value \(i)"))
    }

    largeMessage.set(fieldName: "repeated_string", value: .repeatedValue(stringValues))

    // Measure serialization performance
    let serializationStart = Date()
    let largeData = ProtoWireFormat.marshal(message: largeMessage)!
    let serializationEnd = Date()

    let serializationTime = serializationEnd.timeIntervalSince(serializationStart)
    print("Large message serialization time: \(serializationTime) seconds")
    print("Large message serialized size: \(largeData.count) bytes")

    // Measure deserialization performance
    let deserializationStart = Date()
    _ = ProtoWireFormat.unmarshal(data: largeData, messageDescriptor: largeDescriptor)
    let deserializationEnd = Date()

    let deserializationTime = deserializationEnd.timeIntervalSince(deserializationStart)
    print("Large message deserialization time: \(deserializationTime) seconds")

    // Verify performance is within acceptable limits
    XCTAssertLessThan(serializationTime, 1.0, "Serialization should complete in under 1 second")
    XCTAssertLessThan(deserializationTime, 1.0, "Deserialization should complete in under 1 second")
  }

  func testCompareWithManualSerialization() {
    // This test compares our serialization with a manual implementation
    // to verify that our implementation is efficient

    // Create a simple message
    let simpleDescriptor = ProtoMessageDescriptor(
      fullName: "SimpleMessage",
      fields: [
        ProtoFieldDescriptor(name: "int32_field", number: 1, type: .int32, isRepeated: false, isMap: false)
      ],
      enums: [],
      nestedMessages: []
    )

    let simpleMessage = ProtoDynamicMessage(descriptor: simpleDescriptor)
    simpleMessage.set(fieldName: "int32_field", value: .intValue(42))

    // Measure our implementation
    let ourStart = Date()
    for _ in 0..<10000 {
      _ = ProtoWireFormat.marshal(message: simpleMessage)
    }
    let ourEnd = Date()
    let ourTime = ourEnd.timeIntervalSince(ourStart)

    // Manual implementation for comparison
    let manualStart = Date()
    for _ in 0..<10000 {
      var data = Data()
      // Field 1, wire type 0 (varint) = tag 8
      data.append(8)
      // Value 42
      data.append(42)
    }
    let manualEnd = Date()
    let manualTime = manualEnd.timeIntervalSince(manualStart)

    print("Our implementation: \(ourTime) seconds")
    print("Manual implementation: \(manualTime) seconds")
    print("Performance ratio: \(ourTime / manualTime)x")

    // Our implementation should be within 500% of the manual implementation
    // Note: This is a very simple test case, real-world performance may vary
    // The manual implementation is extremely simplified and doesn't include any of the
    // validation, type checking, or flexibility that our implementation provides
    XCTAssertLessThan(ourTime / manualTime, 6.0, "Performance should be within 500% of manual implementation")
  }
}
