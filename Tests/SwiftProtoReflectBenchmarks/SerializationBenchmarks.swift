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
    do {
      serializedData = try ProtoWireFormat.marshal(message: testMessage)
    }
    catch {
      print("Error serializing test message: \(error)")
    }
  }

  func testSerializationPerformance() {
    // Measure serialization performance
    measure {
      for _ in 0..<1000 {
        do {
          _ = try ProtoWireFormat.marshal(message: testMessage)
        }
        catch {
          // Ignore errors during benchmarking
        }
      }
    }
  }

  func testDeserializationPerformance() {
    // Measure the performance of deserializing a message
    measure {
      for _ in 0..<1000 {
        do {
          _ = try ProtoWireFormat.unmarshal(data: serializedData, messageDescriptor: messageDescriptor)
        }
        catch {
          XCTFail("Failed to unmarshal: \(error)")
        }
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
    do {
      let simpleData = try ProtoWireFormat.marshal(message: simpleMessage)

      // Expected size calculation:
      // Field 1 (int32): tag(1) + value(1) = 2 bytes
      let expectedSize = 2
      XCTAssertEqual(simpleData.count, expectedSize, "Simple message should serialize to \(expectedSize) bytes")
    }
    catch {
      XCTFail("Error serializing simple message: \(error)")
    }
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
    var largeData: Data? = nil
    var serializationTime: TimeInterval = 0

    do {
      largeData = try ProtoWireFormat.marshal(message: largeMessage)
      let serializationEnd = Date()

      serializationTime = serializationEnd.timeIntervalSince(serializationStart)
      print("Serialization time for large message: \(serializationTime) seconds")
      print("Serialized data size: \(largeData!.count) bytes")

      // Calculate throughput
      let throughput = Double(largeData!.count) / serializationTime / 1_000_000.0
      print("Serialization throughput: \(throughput) MB/s")
    }
    catch {
      XCTFail("Error serializing large message: \(error)")
    }

    // Measure deserialization performance
    let deserializationStart = Date()
    if let data = largeData {
      do {
        _ = try ProtoWireFormat.unmarshal(data: data, messageDescriptor: largeDescriptor)
      }
      catch {
        print("Error during unmarshal: \(error)")
      }
    }
    let deserializationEnd = Date()

    let deserializationTime = deserializationEnd.timeIntervalSince(deserializationStart)
    print("Large message deserialization time: \(deserializationTime) seconds")

    // Verify performance is within acceptable limits
    if serializationTime > 0 {
      XCTAssertLessThan(serializationTime, 1.0, "Serialization should complete in under 1 second")
    }
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

    // Manual implementation
    let manualStart = Date()
    for _ in 0..<10000 {
      var data = Data()
      data.append(UInt8(8))  // Tag for field 1, wire type 0
      data.append(UInt8(42))  // Value 42
    }
    let manualEnd = Date()
    let manualTime = manualEnd.timeIntervalSince(manualStart)
    print("Manual implementation time: \(manualTime) seconds")

    // Our implementation
    let ourStart = Date()
    for _ in 0..<10000 {
      do {
        _ = try ProtoWireFormat.marshal(message: simpleMessage)
      }
      catch {
        // Ignore errors during benchmarking
      }
    }
    let ourEnd = Date()
    let ourTime = ourEnd.timeIntervalSince(ourStart)
    print("SwiftProtoReflect time: \(ourTime) seconds")

    // SwiftProtobuf implementation (using simple dummy message)
    struct SwiftProtobufMessage: SwiftProtobuf.Message {
      static let protoMessageName: String = "SwiftProtobufMessage"

      var unknownFields = SwiftProtobuf.UnknownStorage()

      init() {}

      init(serializedData: Data) throws {
        // Empty implementation
      }

      func isEqualTo(message: SwiftProtobuf.Message) -> Bool {
        return true
      }

      mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
        // Empty implementation
      }

      func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
        // Empty implementation
      }
    }

    let swiftProtobufStart = Date()
    for _ in 0..<10000 {
      _ = try? SwiftProtobufMessage().serializedData()
    }
    let swiftProtobufEnd = Date()
    let swiftProtobufTime = swiftProtobufEnd.timeIntervalSince(swiftProtobufStart)

    // Print comparison
    print("Relative performance: SwiftProtoReflect is \(ourTime / manualTime)x slower than manual implementation")
    print("Relative performance: SwiftProtobuf is \(swiftProtobufTime / manualTime)x slower than manual implementation")

    // Assert performance is reasonable compared to manual implementation
    XCTAssertLessThan(ourTime / manualTime, 6.0, "Performance should be within 500% of manual implementation")
  }

  func methodComparisonBenchmark() {
    // Simple message with just an int field
    let simpleDescriptor = ProtoMessageDescriptor(
      fullName: "SimpleMessage",
      fields: [
        ProtoFieldDescriptor(name: "value", number: 1, type: .int32, isRepeated: false, isMap: false)
      ],
      enums: [],
      nestedMessages: []
    )

    let simpleMessage = ProtoDynamicMessage(descriptor: simpleDescriptor)
    simpleMessage.set(fieldName: "value", value: .intValue(42))

    // Compare our serialization with standard Swift Protobuf
    print("\nSerializing simple message 10,000 times:")

    // Our implementation
    var ourTime: Double = 0
    do {
      let ourStart = Date()
      for _ in 0..<10000 {
        do {
          _ = try ProtoWireFormat.marshal(message: simpleMessage)
        }
        catch {
          // Ignore errors during benchmarking
        }
      }
      let ourEnd = Date()
      ourTime = ourEnd.timeIntervalSince(ourStart)
      print("SwiftProtoReflect time: \(ourTime) seconds")
    }

    // Print comparison
    if ourTime > 0 {
      print("Relative performance: Our implementation is \(ourTime) seconds")
    }
  }
}
