import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

class DescriptorRegistryTests: XCTestCase {

  // MARK: - Properties

  var registry: DescriptorRegistry!

  // MARK: - Setup & Teardown

  override func setUp() {
    super.setUp()
    registry = DescriptorRegistry.shared
  }

  // MARK: - Tests

  func testSharedInstance() {
    // Verify that the shared instance is a singleton
    let instance1 = DescriptorRegistry.shared
    let instance2 = DescriptorRegistry.shared

    XCTAssertTrue(instance1 === instance2, "Shared instance should be a singleton")
  }

  func testRegisterFileDescriptor() {
    // Create a simple file descriptor
    var fileDescriptor = Google_Protobuf_FileDescriptorProto()
    fileDescriptor.name = "test.proto"
    fileDescriptor.package = "test"

    // Create a message descriptor
    var messageDescriptor = Google_Protobuf_DescriptorProto()
    messageDescriptor.name = "TestMessage"

    // Create a field descriptor
    var fieldDescriptor = Google_Protobuf_FieldDescriptorProto()
    fieldDescriptor.name = "test_field"
    fieldDescriptor.number = 1
    fieldDescriptor.type = .string
    fieldDescriptor.label = .optional

    // Add the field to the message
    messageDescriptor.field.append(fieldDescriptor)

    // Add the message to the file
    fileDescriptor.messageType.append(messageDescriptor)

    // Register the file descriptor
    XCTAssertNoThrow(
      try registry.registerFileDescriptor(fileDescriptor),
      "Should not throw when registering a valid file descriptor"
    )
  }

  func testRegisterInvalidFileDescriptor() {
    // Create an invalid file descriptor (no name)
    let fileDescriptor = Google_Protobuf_FileDescriptorProto()

    // Attempt to register the invalid file descriptor
    XCTAssertThrowsError(
      try registry.registerFileDescriptor(fileDescriptor),
      "Should throw when registering an invalid file descriptor"
    ) { error in
      XCTAssertTrue(error is DescriptorError, "Error should be a DescriptorError")
      if let descriptorError = error as? DescriptorError {
        switch descriptorError {
        case .invalidFileDescriptor:
          // Expected error
          break
        default:
          XCTFail("Unexpected error: \(descriptorError)")
        }
      }
    }
  }

  func testMessageDescriptorLookup() {
    // Create and register a file descriptor
    var fileDescriptor = Google_Protobuf_FileDescriptorProto()
    fileDescriptor.name = "test_lookup.proto"
    fileDescriptor.package = "test"

    var messageDescriptor = Google_Protobuf_DescriptorProto()
    messageDescriptor.name = "TestMessage"

    var fieldDescriptor = Google_Protobuf_FieldDescriptorProto()
    fieldDescriptor.name = "test_field"
    fieldDescriptor.number = 1
    fieldDescriptor.type = .string
    fieldDescriptor.label = .optional

    messageDescriptor.field.append(fieldDescriptor)
    fileDescriptor.messageType.append(messageDescriptor)

    try? registry.registerFileDescriptor(fileDescriptor)

    // Look up the message descriptor
    do {
      let descriptor = try registry.messageDescriptor(forTypeName: "test.TestMessage")
      XCTAssertEqual(descriptor.fullName, "test.TestMessage", "Full name should match")
      XCTAssertEqual(descriptor.fields.count, 1, "Should have one field")
      XCTAssertEqual(descriptor.fields[0].name, "test_field", "Field name should match")
      XCTAssertEqual(descriptor.fields[0].number, 1, "Field number should match")
      XCTAssertEqual(descriptor.fields[0].type, .string, "Field type should match")
    }
    catch {
      XCTFail("Failed to look up message descriptor: \(error)")
    }
  }

  func testMessageDescriptorNotFound() {
    // Attempt to look up a non-existent message descriptor
    XCTAssertThrowsError(
      try registry.messageDescriptor(forTypeName: "nonexistent.Message"),
      "Should throw when looking up a non-existent message descriptor"
    ) { error in
      XCTAssertTrue(error is DescriptorError, "Error should be a DescriptorError")
      if let descriptorError = error as? DescriptorError {
        switch descriptorError {
        case .descriptorNotFound:
          // Expected error
          break
        default:
          XCTFail("Unexpected error: \(descriptorError)")
        }
      }
    }
  }

  func testEnumDescriptorLookup() {
    // Create and register a file descriptor with an enum
    var fileDescriptor = Google_Protobuf_FileDescriptorProto()
    fileDescriptor.name = "test_enum.proto"
    fileDescriptor.package = "test"

    var enumDescriptor = Google_Protobuf_EnumDescriptorProto()
    enumDescriptor.name = "TestEnum"

    var enumValue1 = Google_Protobuf_EnumValueDescriptorProto()
    enumValue1.name = "VALUE_1"
    enumValue1.number = 0

    var enumValue2 = Google_Protobuf_EnumValueDescriptorProto()
    enumValue2.name = "VALUE_2"
    enumValue2.number = 1

    enumDescriptor.value.append(enumValue1)
    enumDescriptor.value.append(enumValue2)

    fileDescriptor.enumType.append(enumDescriptor)

    try? registry.registerFileDescriptor(fileDescriptor)

    // Look up the enum descriptor
    do {
      let descriptor = try registry.enumDescriptor(forTypeName: "test.TestEnum")
      XCTAssertEqual(descriptor.name, "TestEnum", "Name should match")
      XCTAssertEqual(descriptor.values.count, 2, "Should have two values")
      XCTAssertEqual(descriptor.values[0].name, "VALUE_1", "First value name should match")
      XCTAssertEqual(descriptor.values[0].number, 0, "First value number should match")
      XCTAssertEqual(descriptor.values[1].name, "VALUE_2", "Second value name should match")
      XCTAssertEqual(descriptor.values[1].number, 1, "Second value number should match")
    }
    catch {
      XCTFail("Failed to look up enum descriptor: \(error)")
    }
  }

  func testEnumDescriptorNotFound() {
    // Attempt to look up a non-existent enum descriptor
    XCTAssertThrowsError(
      try registry.enumDescriptor(forTypeName: "nonexistent.Enum"),
      "Should throw when looking up a non-existent enum descriptor"
    ) { error in
      XCTAssertTrue(error is DescriptorError, "Error should be a DescriptorError")
      if let descriptorError = error as? DescriptorError {
        switch descriptorError {
        case .descriptorNotFound:
          // Expected error
          break
        default:
          XCTFail("Unexpected error: \(descriptorError)")
        }
      }
    }
  }

  func testNestedMessageDescriptorLookup() {
    // Create and register a file descriptor with a nested message
    var fileDescriptor = Google_Protobuf_FileDescriptorProto()
    fileDescriptor.name = "test_nested.proto"
    fileDescriptor.package = "test"

    var outerMessage = Google_Protobuf_DescriptorProto()
    outerMessage.name = "OuterMessage"

    var nestedMessage = Google_Protobuf_DescriptorProto()
    nestedMessage.name = "NestedMessage"

    var fieldDescriptor = Google_Protobuf_FieldDescriptorProto()
    fieldDescriptor.name = "nested_field"
    fieldDescriptor.number = 1
    fieldDescriptor.type = .string
    fieldDescriptor.label = .optional

    nestedMessage.field.append(fieldDescriptor)
    outerMessage.nestedType.append(nestedMessage)
    fileDescriptor.messageType.append(outerMessage)

    try? registry.registerFileDescriptor(fileDescriptor)

    // Look up the outer message descriptor
    do {
      let descriptor = try registry.messageDescriptor(forTypeName: "test.OuterMessage")
      XCTAssertEqual(descriptor.fullName, "test.OuterMessage", "Full name should match")
      XCTAssertEqual(descriptor.nestedMessages.count, 1, "Should have one nested message")

      // Check the nested message
      let nestedDescriptor = descriptor.nestedMessages[0]
      XCTAssertEqual(
        nestedDescriptor.fullName,
        "test.OuterMessage.NestedMessage",
        "Nested message full name should match"
      )
      XCTAssertEqual(nestedDescriptor.fields.count, 1, "Nested message should have one field")
      XCTAssertEqual(nestedDescriptor.fields[0].name, "nested_field", "Nested field name should match")
    }
    catch {
      XCTFail("Failed to look up message descriptor: \(error)")
    }
  }
}
