import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

class DescriptorRegistryBenchmarks: XCTestCase {

  var registry: DescriptorRegistry!
  var fileDescriptor: Google_Protobuf_FileDescriptorProto!

  override func setUp() {
    super.setUp()
    registry = DescriptorRegistry.shared

    // Create a test file descriptor with multiple messages and enums
    fileDescriptor = createTestFileDescriptor()
  }

  func testRegistrationPerformance() {
    let result = BenchmarkUtils.benchmark(name: "DescriptorRegistry.registerFileDescriptor", iterations: 100) {
      try? registry.registerFileDescriptor(fileDescriptor)
    }

    XCTAssertTrue(result.averageDurationMs < 10.0, "Registration should be fast (< 10ms)")
  }

  func testMessageLookupPerformance() {
    // Register the file descriptor first
    try? registry.registerFileDescriptor(fileDescriptor)

    let result = BenchmarkUtils.benchmark(name: "DescriptorRegistry.messageDescriptor", iterations: 1000) {
      try? registry.messageDescriptor(forTypeName: "test.TestMessage")
    }

    XCTAssertTrue(result.averageDurationMs < 1.0, "Message lookup should be very fast (< 1ms)")
  }

  func testEnumLookupPerformance() {
    // Register the file descriptor first
    try? registry.registerFileDescriptor(fileDescriptor)

    let result = BenchmarkUtils.benchmark(name: "DescriptorRegistry.enumDescriptor", iterations: 1000) {
      try? registry.enumDescriptor(forTypeName: "test.TestEnum")
    }

    XCTAssertTrue(result.averageDurationMs < 1.0, "Enum lookup should be very fast (< 1ms)")
  }

  func testNestedMessageLookupPerformance() {
    // Register the file descriptor first
    try? registry.registerFileDescriptor(fileDescriptor)

    let result = BenchmarkUtils.benchmark(name: "DescriptorRegistry.nestedMessageDescriptor", iterations: 1000) {
      try? registry.messageDescriptor(forTypeName: "test.OuterMessage.NestedMessage")
    }

    XCTAssertTrue(result.averageDurationMs < 1.0, "Nested message lookup should be very fast (< 1ms)")
  }

  // MARK: - Helper Methods

  private func createTestFileDescriptor() -> Google_Protobuf_FileDescriptorProto {
    var fileDescriptor = Google_Protobuf_FileDescriptorProto()
    fileDescriptor.name = "test.proto"
    fileDescriptor.package = "test"

    // Add a simple message
    var simpleMessage = Google_Protobuf_DescriptorProto()
    simpleMessage.name = "TestMessage"

    var field1 = Google_Protobuf_FieldDescriptorProto()
    field1.name = "int_field"
    field1.number = 1
    field1.type = .int32
    field1.label = .optional

    var field2 = Google_Protobuf_FieldDescriptorProto()
    field2.name = "string_field"
    field2.number = 2
    field2.type = .string
    field2.label = .optional

    simpleMessage.field.append(field1)
    simpleMessage.field.append(field2)

    // Add an enum
    var enumType = Google_Protobuf_EnumDescriptorProto()
    enumType.name = "TestEnum"

    var enumValue1 = Google_Protobuf_EnumValueDescriptorProto()
    enumValue1.name = "VALUE_1"
    enumValue1.number = 0

    var enumValue2 = Google_Protobuf_EnumValueDescriptorProto()
    enumValue2.name = "VALUE_2"
    enumValue2.number = 1

    enumType.value.append(enumValue1)
    enumType.value.append(enumValue2)

    // Add a message with a nested message
    var outerMessage = Google_Protobuf_DescriptorProto()
    outerMessage.name = "OuterMessage"

    var outerField = Google_Protobuf_FieldDescriptorProto()
    outerField.name = "outer_field"
    outerField.number = 1
    outerField.type = .int32
    outerField.label = .optional

    var nestedMessage = Google_Protobuf_DescriptorProto()
    nestedMessage.name = "NestedMessage"

    var nestedField = Google_Protobuf_FieldDescriptorProto()
    nestedField.name = "nested_field"
    nestedField.number = 1
    nestedField.type = .string
    nestedField.label = .optional

    nestedMessage.field.append(nestedField)
    outerMessage.field.append(outerField)
    outerMessage.nestedType.append(nestedMessage)

    // Add everything to the file descriptor
    fileDescriptor.messageType.append(simpleMessage)
    fileDescriptor.enumType.append(enumType)
    fileDescriptor.messageType.append(outerMessage)

    return fileDescriptor
  }
}
