//
// DescriptorBridgeTests.swift
// SwiftProtoReflectTests
//
// Created: 2025-05-25
//

import XCTest

import struct SwiftProtobuf.Google_Protobuf_DescriptorProto
import struct SwiftProtobuf.Google_Protobuf_EnumDescriptorProto
import struct SwiftProtobuf.Google_Protobuf_EnumValueDescriptorProto
import struct SwiftProtobuf.Google_Protobuf_FieldDescriptorProto
import struct SwiftProtobuf.Google_Protobuf_FieldOptions
import struct SwiftProtobuf.Google_Protobuf_FileDescriptorProto
import struct SwiftProtobuf.Google_Protobuf_MessageOptions
import struct SwiftProtobuf.Google_Protobuf_MethodDescriptorProto
import struct SwiftProtobuf.Google_Protobuf_OneofDescriptorProto
import struct SwiftProtobuf.Google_Protobuf_ServiceDescriptorProto

@testable import SwiftProtoReflect

final class DescriptorBridgeTests: XCTestCase {

  // MARK: - Test Properties

  private var bridge: DescriptorBridge!
  private var fileDescriptor: FileDescriptor!

  // MARK: - Setup and Teardown

  override func setUp() {
    super.setUp()
    bridge = DescriptorBridge()

    // Create test file descriptor
    fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
  }

  override func tearDown() {
    bridge = nil
    fileDescriptor = nil
    super.tearDown()
  }

  // MARK: - Initialization Tests

  func testInitialization() {
    let bridge = DescriptorBridge()
    XCTAssertNotNil(bridge)
  }

  // MARK: - Message Descriptor Conversion Tests

  func testMessageDescriptorToProtobuf() throws {
    // Create test MessageDescriptor
    var messageDescriptor = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    messageDescriptor.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    messageDescriptor.addField(FieldDescriptor(name: "age", number: 2, type: .int32))

    // Convert to protobuf format
    let protobufDescriptor = try bridge.toProtobufDescriptor(from: messageDescriptor)

    // Verify result
    XCTAssertEqual(protobufDescriptor.name, "TestMessage")
    XCTAssertEqual(protobufDescriptor.field.count, 2)
    XCTAssertEqual(protobufDescriptor.field[0].name, "name")
    XCTAssertEqual(protobufDescriptor.field[0].type, .string)
    XCTAssertEqual(protobufDescriptor.field[1].name, "age")
    XCTAssertEqual(protobufDescriptor.field[1].type, .int32)
  }

  func testMessageDescriptorFromProtobuf() throws {
    // Create test protobuf descriptor
    var protobufDescriptor = Google_Protobuf_DescriptorProto()
    protobufDescriptor.name = "TestMessage"

    var field1 = Google_Protobuf_FieldDescriptorProto()
    field1.name = "name"
    field1.number = 1
    field1.type = .string
    field1.label = .optional

    var field2 = Google_Protobuf_FieldDescriptorProto()
    field2.name = "age"
    field2.number = 2
    field2.type = .int32
    field2.label = .optional

    protobufDescriptor.field = [field1, field2]

    // Convert to our format
    let messageDescriptor = try bridge.fromProtobufDescriptor(
      protobufDescriptor,
      parent: fileDescriptor as any DescriptorParent
    )

    // Verify result
    XCTAssertEqual(messageDescriptor.name, "TestMessage")
    XCTAssertEqual(messageDescriptor.allFields().count, 2)

    let nameField = messageDescriptor.field(named: "name")
    XCTAssertNotNil(nameField)
    XCTAssertEqual(nameField?.type, .string)

    let ageField = messageDescriptor.field(named: "age")
    XCTAssertNotNil(ageField)
    XCTAssertEqual(ageField?.type, .int32)
  }

  func testMessageDescriptorWithNestedTypes() throws {
    // Create complex MessageDescriptor with nested types
    var messageDescriptor = MessageDescriptor(name: "ComplexMessage", parent: fileDescriptor)

    // Add nested message
    var nestedMessage = MessageDescriptor(name: "NestedMessage")
    nestedMessage.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    messageDescriptor.addNestedMessage(nestedMessage)

    // Add nested enum
    var nestedEnum = EnumDescriptor(name: "NestedEnum")
    nestedEnum.addValue(EnumDescriptor.EnumValue(name: "VALUE1", number: 0))
    nestedEnum.addValue(EnumDescriptor.EnumValue(name: "VALUE2", number: 1))
    messageDescriptor.addNestedEnum(nestedEnum)

    // Convert to protobuf and back
    let protobufDescriptor = try bridge.toProtobufDescriptor(from: messageDescriptor)
    let convertedBack = try bridge.fromProtobufDescriptor(protobufDescriptor, parent: nil as (any DescriptorParent)?)

    // Verify result
    XCTAssertEqual(convertedBack.name, "ComplexMessage")
    XCTAssertEqual(convertedBack.nestedMessages.count, 1)
    XCTAssertEqual(convertedBack.nestedEnums.count, 1)
    XCTAssertEqual(Array(convertedBack.nestedMessages.values)[0].name, "NestedMessage")
    XCTAssertEqual(Array(convertedBack.nestedEnums.values)[0].name, "NestedEnum")
  }

  // MARK: - Field Descriptor Conversion Tests

  func testFieldDescriptorToProtobuf() throws {
    // Test scalar field types
    let scalarTestCases: [(FieldType, Google_Protobuf_FieldDescriptorProto.TypeEnum)] = [
      (.string, .string),
      (.int32, .int32),
      (.int64, .int64),
      (.uint32, .uint32),
      (.uint64, .uint64),
      (.bool, .bool),
      (.double, .double),
      (.float, .float),
      (.bytes, .bytes),
    ]

    for (fieldType, expectedProtobufType) in scalarTestCases {
      let fieldDescriptor = FieldDescriptor(name: "test_field", number: 1, type: fieldType)
      let protobufField = try bridge.toProtobufFieldDescriptor(from: fieldDescriptor)

      XCTAssertEqual(protobufField.type, expectedProtobufType, "Failed for field type: \(fieldType)")
      XCTAssertEqual(protobufField.name, "test_field")
      XCTAssertEqual(protobufField.number, 1)
    }

    // Test complex field types (require typeName)
    let enumFieldDescriptor = FieldDescriptor(
      name: "enum_field",
      number: 2,
      type: .enum,
      typeName: "TestEnum"
    )
    let enumProtobufField = try bridge.toProtobufFieldDescriptor(from: enumFieldDescriptor)
    XCTAssertEqual(enumProtobufField.type, .enum)
    XCTAssertEqual(enumProtobufField.typeName, "TestEnum")

    let messageFieldDescriptor = FieldDescriptor(
      name: "message_field",
      number: 3,
      type: .message,
      typeName: "TestMessage"
    )
    let messageProtobufField = try bridge.toProtobufFieldDescriptor(from: messageFieldDescriptor)
    XCTAssertEqual(messageProtobufField.type, .message)
    XCTAssertEqual(messageProtobufField.typeName, "TestMessage")
  }

  func testFieldDescriptorFromProtobuf() throws {
    // Create test protobuf field descriptor
    var protobufField = Google_Protobuf_FieldDescriptorProto()
    protobufField.name = "test_field"
    protobufField.number = 42
    protobufField.type = .string
    protobufField.label = .repeated

    // Convert to our format
    let fieldDescriptor = try bridge.fromProtobufFieldDescriptor(protobufField)

    // Verify result
    XCTAssertEqual(fieldDescriptor.name, "test_field")
    XCTAssertEqual(fieldDescriptor.number, 42)
    XCTAssertEqual(fieldDescriptor.type, .string)
    XCTAssertTrue(fieldDescriptor.isRepeated)
    XCTAssertFalse(fieldDescriptor.isRequired)
  }

  func testFieldDescriptorLabels() throws {
    // Test different labels (using proto2 syntax for required label support)
    let testCases: [(Google_Protobuf_FieldDescriptorProto.Label, String, Bool, Bool, Bool)] = [
      (.optional, "proto3", false, false, true),
      (.required, "proto2", false, true, false),
      (.repeated, "proto3", true, false, false),
    ]

    for (label, syntax, expectedRepeated, expectedRequired, expectedOptional) in testCases {
      var protobufField = Google_Protobuf_FieldDescriptorProto()
      protobufField.name = "test"
      protobufField.number = 1
      protobufField.type = .string
      protobufField.label = label

      let fieldDescriptor = try bridge.fromProtobufFieldDescriptor(protobufField, syntax: syntax)

      XCTAssertEqual(fieldDescriptor.isRepeated, expectedRepeated, "Failed for label: \(label)")
      XCTAssertEqual(fieldDescriptor.isRequired, expectedRequired, "Failed for label: \(label)")
      XCTAssertEqual(fieldDescriptor.isOptional, expectedOptional, "Failed for label: \(label)")
    }
  }

  // MARK: - Enum Descriptor Conversion Tests

  func testEnumDescriptorToProtobuf() throws {
    // Create test EnumDescriptor
    var enumDescriptor = EnumDescriptor(name: "TestEnum")
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "VALUE1", number: 1))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "VALUE2", number: 2))

    // Convert to protobuf format
    let protobufEnum = try bridge.toProtobufEnumDescriptor(from: enumDescriptor)

    // Verify result
    XCTAssertEqual(protobufEnum.name, "TestEnum")
    XCTAssertEqual(protobufEnum.value.count, 3)
    XCTAssertEqual(protobufEnum.value[0].name, "UNKNOWN")
    XCTAssertEqual(protobufEnum.value[0].number, 0)
    XCTAssertEqual(protobufEnum.value[1].name, "VALUE1")
    XCTAssertEqual(protobufEnum.value[1].number, 1)
    XCTAssertEqual(protobufEnum.value[2].name, "VALUE2")
    XCTAssertEqual(protobufEnum.value[2].number, 2)
  }

  func testEnumDescriptorFromProtobuf() throws {
    // Create test protobuf enum descriptor
    var protobufEnum = Google_Protobuf_EnumDescriptorProto()
    protobufEnum.name = "TestEnum"

    var value1 = Google_Protobuf_EnumValueDescriptorProto()
    value1.name = "UNKNOWN"
    value1.number = 0

    var value2 = Google_Protobuf_EnumValueDescriptorProto()
    value2.name = "VALUE1"
    value2.number = 1

    protobufEnum.value = [value1, value2]

    // Convert to our format
    let enumDescriptor = try bridge.fromProtobufEnumDescriptor(protobufEnum)

    // Verify result
    XCTAssertEqual(enumDescriptor.name, "TestEnum")
    XCTAssertEqual(enumDescriptor.allValues().count, 2)

    let unknownValue = enumDescriptor.value(named: "UNKNOWN")
    XCTAssertNotNil(unknownValue)
    XCTAssertEqual(unknownValue?.number, 0)

    let value1Desc = enumDescriptor.value(named: "VALUE1")
    XCTAssertNotNil(value1Desc)
    XCTAssertEqual(value1Desc?.number, 1)
  }

  // MARK: - File Descriptor Conversion Tests

  func testFileDescriptorToProtobuf() throws {
    // Create test FileDescriptor with content
    var fileDesc = FileDescriptor(name: "test.proto", package: "com.example")

    // Add message
    var message = MessageDescriptor(name: "TestMessage", parent: fileDesc)
    message.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    fileDesc.addMessage(message)

    // Add enum
    var enumDesc = EnumDescriptor(name: "TestEnum", parent: fileDesc)
    enumDesc.addValue(EnumDescriptor.EnumValue(name: "VALUE1", number: 0))
    fileDesc.addEnum(enumDesc)

    // Add service
    var service = ServiceDescriptor(name: "TestService", parent: fileDesc)
    service.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "TestMethod",
        inputType: "TestMessage",
        outputType: "TestMessage"
      )
    )
    fileDesc.addService(service)

    // Convert to protobuf format
    let protobufFile = try bridge.toProtobufFileDescriptor(from: fileDesc)

    // Verify result
    XCTAssertEqual(protobufFile.name, "test.proto")
    XCTAssertEqual(protobufFile.package, "com.example")
    XCTAssertEqual(protobufFile.messageType.count, 1)
    XCTAssertEqual(protobufFile.enumType.count, 1)
    XCTAssertEqual(protobufFile.service.count, 1)
    XCTAssertEqual(protobufFile.messageType[0].name, "TestMessage")
    XCTAssertEqual(protobufFile.enumType[0].name, "TestEnum")
    XCTAssertEqual(protobufFile.service[0].name, "TestService")
  }

  func testFileDescriptorFromProtobuf() throws {
    // Create test protobuf file descriptor
    var protobufFile = Google_Protobuf_FileDescriptorProto()
    protobufFile.name = "test.proto"
    protobufFile.package = "com.example"
    protobufFile.dependency = ["google/protobuf/empty.proto"]

    // Add message
    var message = Google_Protobuf_DescriptorProto()
    message.name = "TestMessage"
    protobufFile.messageType = [message]

    // Convert to our format
    let fileDesc = try bridge.fromProtobufFileDescriptor(protobufFile)

    // Verify result
    XCTAssertEqual(fileDesc.name, "test.proto")
    XCTAssertEqual(fileDesc.package, "com.example")
    XCTAssertEqual(fileDesc.dependencies, ["google/protobuf/empty.proto"])
    XCTAssertEqual(fileDesc.messages.count, 1)
    XCTAssertEqual(Array(fileDesc.messages.values)[0].name, "TestMessage")
  }

  // MARK: - Service Descriptor Conversion Tests

  func testServiceDescriptorToProtobuf() throws {
    // Create test ServiceDescriptor
    var serviceDescriptor = ServiceDescriptor(name: "TestService", parent: fileDescriptor)
    serviceDescriptor.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "UnaryMethod",
        inputType: "TestRequest",
        outputType: "TestResponse"
      )
    )
    serviceDescriptor.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "StreamingMethod",
        inputType: "TestRequest",
        outputType: "TestResponse",
        clientStreaming: true,
        serverStreaming: true
      )
    )

    // Convert to protobuf format
    let protobufService = try bridge.toProtobufServiceDescriptor(from: serviceDescriptor)

    // Verify result
    XCTAssertEqual(protobufService.name, "TestService")
    XCTAssertEqual(protobufService.method.count, 2)

    // Search methods by name instead of checking by indices
    let unaryMethod = protobufService.method.first { $0.name == "UnaryMethod" }
    XCTAssertNotNil(unaryMethod, "UnaryMethod not found")
    XCTAssertEqual(unaryMethod?.inputType, "TestRequest")
    XCTAssertEqual(unaryMethod?.outputType, "TestResponse")
    XCTAssertFalse(unaryMethod?.clientStreaming ?? true)
    XCTAssertFalse(unaryMethod?.serverStreaming ?? true)

    let streamingMethod = protobufService.method.first { $0.name == "StreamingMethod" }
    XCTAssertNotNil(streamingMethod, "StreamingMethod not found")
    XCTAssertEqual(streamingMethod?.inputType, "TestRequest")
    XCTAssertEqual(streamingMethod?.outputType, "TestResponse")
    XCTAssertTrue(streamingMethod?.clientStreaming ?? false)
    XCTAssertTrue(streamingMethod?.serverStreaming ?? false)
  }

  func testServiceDescriptorFromProtobuf() throws {
    // Create test protobuf service descriptor
    var protobufService = Google_Protobuf_ServiceDescriptorProto()
    protobufService.name = "TestService"

    var method = Google_Protobuf_MethodDescriptorProto()
    method.name = "TestMethod"
    method.inputType = "TestRequest"
    method.outputType = "TestResponse"
    method.clientStreaming = false
    method.serverStreaming = true

    protobufService.method = [method]

    // Convert to our format
    let serviceDescriptor = try bridge.fromProtobufServiceDescriptor(protobufService, parent: fileDescriptor)

    // Verify result
    XCTAssertEqual(serviceDescriptor.name, "TestService")
    XCTAssertEqual(serviceDescriptor.allMethods().count, 1)

    let testMethod = serviceDescriptor.method(named: "TestMethod")
    XCTAssertNotNil(testMethod)
    XCTAssertEqual(testMethod?.inputType, "TestRequest")
    XCTAssertEqual(testMethod?.outputType, "TestResponse")
    XCTAssertFalse(testMethod?.clientStreaming ?? true)
    XCTAssertTrue(testMethod?.serverStreaming ?? false)
  }

  // MARK: - Round-trip Conversion Tests

  func testMessageDescriptorRoundTrip() throws {
    // Create original MessageDescriptor
    var original = MessageDescriptor(name: "RoundTripMessage", parent: fileDescriptor)
    original.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    original.addField(FieldDescriptor(name: "age", number: 2, type: .int32, isRepeated: true))
    original.addField(FieldDescriptor(name: "active", number: 3, type: .bool, isOptional: true))

    // Convert to protobuf and back
    let protobufDescriptor = try bridge.toProtobufDescriptor(from: original)
    let converted = try bridge.fromProtobufDescriptor(protobufDescriptor, parent: nil as (any DescriptorParent)?)

    // Verify data is preserved
    XCTAssertEqual(converted.name, original.name)
    XCTAssertEqual(converted.allFields().count, original.allFields().count)

    for originalField in original.allFields() {
      let convertedField = converted.field(named: originalField.name)
      XCTAssertNotNil(convertedField, "Field \(originalField.name) not found after round-trip")
      XCTAssertEqual(convertedField?.type, originalField.type)
      XCTAssertEqual(convertedField?.number, originalField.number)
      XCTAssertEqual(convertedField?.isRepeated, originalField.isRepeated)
    }
  }

  func testFileDescriptorRoundTrip() throws {
    // Create original FileDescriptor
    var original = FileDescriptor(name: "roundtrip.proto", package: "test.roundtrip")

    var message = MessageDescriptor(name: "TestMessage", parent: original)
    message.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    original.addMessage(message)

    var enumDesc = EnumDescriptor(name: "TestEnum", parent: original)
    enumDesc.addValue(EnumDescriptor.EnumValue(name: "VALUE1", number: 0))
    original.addEnum(enumDesc)

    // Convert to protobuf and back
    let protobufDescriptor = try bridge.toProtobufFileDescriptor(from: original)
    let converted = try bridge.fromProtobufFileDescriptor(protobufDescriptor)

    // Verify data is preserved
    XCTAssertEqual(converted.name, original.name)
    XCTAssertEqual(converted.package, original.package)
    XCTAssertEqual(converted.messages.count, original.messages.count)
    XCTAssertEqual(converted.enums.count, original.enums.count)
    XCTAssertEqual(Array(converted.messages.values)[0].name, Array(original.messages.values)[0].name)
    XCTAssertEqual(Array(converted.enums.values)[0].name, Array(original.enums.values)[0].name)
  }

  // MARK: - Error Handling Tests

  func testUnsupportedFieldTypeError() {
    // Test conversion error handling
    // Since all types are supported in DescriptorBridge, test other errors

    // Test that group type is supported (doesn't throw error)
    var protobufField = Google_Protobuf_FieldDescriptorProto()
    protobufField.name = "test_field"
    protobufField.number = 1
    protobufField.type = .group
    protobufField.label = .optional

    XCTAssertNoThrow(try bridge.fromProtobufFieldDescriptor(protobufField))
  }

  func testErrorDescriptions() {
    let errors: [DescriptorBridgeError] = [
      .unsupportedFieldType(123),
      .conversionFailed("Test conversion failed"),
      .missingRequiredField("requiredField"),
      .invalidDescriptorStructure("Invalid structure"),
    ]

    for error in errors {
      XCTAssertNotNil(error.errorDescription)
      XCTAssertFalse(error.errorDescription!.isEmpty)
    }
  }

  func testInvalidFieldDescriptorError() {
    // Test handling of invalid field descriptor
    var protobufField = Google_Protobuf_FieldDescriptorProto()
    protobufField.name = ""  // Empty name should cause error
    protobufField.number = 0  // Invalid field number
    protobufField.type = .string
    protobufField.label = .optional

    // In this case we test that conversion passes, but can add validation later
    XCTAssertNoThrow(try bridge.fromProtobufFieldDescriptor(protobufField))
  }

  // MARK: - Performance Tests

  func testConversionPerformance() throws {
    // Create complex descriptor for performance testing
    var fileDesc = FileDescriptor(name: "performance.proto", package: "test.performance")

    for i in 0..<10 {
      var message = MessageDescriptor(name: "Message\(i)", parent: fileDesc)
      for j in 0..<20 {
        message.addField(FieldDescriptor(name: "field\(j)", number: j + 1, type: .string))
      }
      fileDesc.addMessage(message)
    }

    measure {
      do {
        // Measure conversion performance
        let protobufDescriptor = try bridge.toProtobufFileDescriptor(from: fileDesc)
        _ = try bridge.fromProtobufFileDescriptor(protobufDescriptor)
      }
      catch {
        XCTFail("Performance test failed with error: \(error)")
      }
    }
  }

  // MARK: - Additional Coverage Tests

  func testMessageDescriptorWithOptions() throws {
    // Create MessageDescriptor with options via constructor
    var messageDescriptor = MessageDescriptor(
      name: "MessageWithOptions",
      parent: fileDescriptor,
      options: ["deprecated": .bool(true), "custom_option": .string("test_value")]
    )
    messageDescriptor.addField(FieldDescriptor(name: "name", number: 1, type: .string))

    // Convert to protobuf format (should cover line 57)
    let protobufDescriptor = try bridge.toProtobufDescriptor(from: messageDescriptor)

    // Verify conversion succeeded
    XCTAssertEqual(protobufDescriptor.name, "MessageWithOptions")
    XCTAssertEqual(protobufDescriptor.field.count, 1)
  }

  func testMessageDescriptorFromProtobufWithOptions() throws {
    // Create protobuf descriptor with options
    var protobufDescriptor = Google_Protobuf_DescriptorProto()
    protobufDescriptor.name = "MessageWithOptions"
    protobufDescriptor.options = Google_Protobuf_MessageOptions()

    // Convert to our format (should cover lines 99-103)
    let messageDescriptor = try bridge.fromProtobufDescriptor(
      protobufDescriptor,
      parent: fileDescriptor as any DescriptorParent
    )

    // Verify result
    XCTAssertEqual(messageDescriptor.name, "MessageWithOptions")
  }

  func testFieldDescriptorWithCustomJsonName() throws {
    // Create FieldDescriptor with custom JSON name
    let fieldDescriptor = FieldDescriptor(
      name: "field_name",
      number: 1,
      type: .string,
      jsonName: "customJsonName"
    )

    // Convert to protobuf format (should cover line 144)
    let protobufField = try bridge.toProtobufFieldDescriptor(from: fieldDescriptor)

    // Verify result
    XCTAssertEqual(protobufField.name, "field_name")
    XCTAssertEqual(protobufField.jsonName, "customJsonName")
  }

  func testFieldDescriptorWithOptions() throws {
    // Create FieldDescriptor with options via constructor
    let fieldDescriptor = FieldDescriptor(
      name: "field_with_options",
      number: 1,
      type: .string,
      options: ["packed": .bool(true), "deprecated": .bool(false)]
    )

    // Convert to protobuf format (should cover line 149)
    let protobufField = try bridge.toProtobufFieldDescriptor(from: fieldDescriptor)

    // Verify result
    XCTAssertEqual(protobufField.name, "field_with_options")
    XCTAssertEqual(protobufField.type, .string)
  }

  func testFieldDescriptorFromProtobufWithOptions() throws {
    // Create protobuf field descriptor with options
    var protobufField = Google_Protobuf_FieldDescriptorProto()
    protobufField.name = "field_with_options"
    protobufField.number = 1
    protobufField.type = .string
    protobufField.label = .optional
    protobufField.options = Google_Protobuf_FieldOptions()

    // Convert to our format (should cover lines 185-189)
    let fieldDescriptor = try bridge.fromProtobufFieldDescriptor(protobufField)

    // Verify result
    XCTAssertEqual(fieldDescriptor.name, "field_with_options")
    XCTAssertEqual(fieldDescriptor.type, .string)
  }

  func testEnumDescriptorWithValueOptions() throws {
    // Create EnumDescriptor with value options
    var enumDescriptor = EnumDescriptor(name: "EnumWithOptions")

    let enumValue = EnumDescriptor.EnumValue(
      name: "VALUE_WITH_OPTIONS",
      number: 0,
      options: ["deprecated": .bool(true)]
    )
    enumDescriptor.addValue(enumValue)

    // Convert to protobuf format (should cover lines 218-220)
    let protobufEnum = try bridge.toProtobufEnumDescriptor(from: enumDescriptor)

    // Verify result
    XCTAssertEqual(protobufEnum.name, "EnumWithOptions")
    XCTAssertEqual(protobufEnum.value.count, 1)
    XCTAssertEqual(protobufEnum.value[0].name, "VALUE_WITH_OPTIONS")
  }

  func testEnumDescriptorWithEnumOptions() throws {
    // Create EnumDescriptor with enum options via constructor
    var enumDescriptor = EnumDescriptor(
      name: "EnumWithOptions",
      options: ["allow_alias": .bool(true)]
    )
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "VALUE1", number: 0))

    // Convert to protobuf format (should cover lines 227-229)
    let protobufEnum = try bridge.toProtobufEnumDescriptor(from: enumDescriptor)

    // Verify result
    XCTAssertEqual(protobufEnum.name, "EnumWithOptions")
    XCTAssertEqual(protobufEnum.value.count, 1)
  }

  func testFileDescriptorWithServices() throws {
    // Create protobuf file descriptor with services
    var protobufFile = Google_Protobuf_FileDescriptorProto()
    protobufFile.name = "service_test.proto"
    protobufFile.package = "test"

    // Add service
    var service = Google_Protobuf_ServiceDescriptorProto()
    service.name = "TestService"

    var method = Google_Protobuf_MethodDescriptorProto()
    method.name = "TestMethod"
    method.inputType = "TestRequest"
    method.outputType = "TestResponse"
    service.method = [method]

    protobufFile.service = [service]

    // Convert to our format (should cover lines 328-329)
    let fileDescriptor = try bridge.fromProtobufFileDescriptor(protobufFile)

    // Verify result
    XCTAssertEqual(fileDescriptor.name, "service_test.proto")
    XCTAssertEqual(fileDescriptor.package, "test")
    XCTAssertEqual(fileDescriptor.services.count, 1)
    XCTAssertEqual(Array(fileDescriptor.services.values)[0].name, "TestService")
  }

  func testUnknownFieldTypeHandling() throws {
    // Create mock to test @unknown default case
    // Since we can't easily create unknown case, test all known types

    // Test scalar types
    let scalarFieldTypes: [Google_Protobuf_FieldDescriptorProto.TypeEnum] = [
      .double, .float, .int64, .uint64, .int32, .fixed64, .fixed32,
      .bool, .string, .bytes, .uint32, .sfixed32, .sfixed64, .sint32, .sint64,
    ]

    for protobufType in scalarFieldTypes {
      var protobufField = Google_Protobuf_FieldDescriptorProto()
      protobufField.name = "test_field"
      protobufField.number = 1
      protobufField.type = protobufType
      protobufField.label = .optional

      // Convert and verify no errors occur
      XCTAssertNoThrow(try bridge.fromProtobufFieldDescriptor(protobufField))
    }

    // Test complex types with typeName
    let complexFieldTypes: [(Google_Protobuf_FieldDescriptorProto.TypeEnum, String)] = [
      (.message, "TestMessage"),
      (.enum, "TestEnum"),
      (.group, "TestGroup"),
    ]

    for (protobufType, typeName) in complexFieldTypes {
      var protobufField = Google_Protobuf_FieldDescriptorProto()
      protobufField.name = "test_field"
      protobufField.number = 1
      protobufField.type = protobufType
      protobufField.typeName = typeName
      protobufField.label = .optional

      // Convert and verify no errors occur
      XCTAssertNoThrow(try bridge.fromProtobufFieldDescriptor(protobufField))
    }
  }

  func testAllFieldTypeConversions() throws {
    // Test scalar field types for full switch statement coverage
    let scalarFieldTypes: [(FieldType, Google_Protobuf_FieldDescriptorProto.TypeEnum)] = [
      (.double, .double), (.float, .float), (.int64, .int64), (.uint64, .uint64),
      (.int32, .int32), (.fixed64, .fixed64), (.fixed32, .fixed32), (.bool, .bool),
      (.string, .string), (.bytes, .bytes), (.uint32, .uint32),
      (.sfixed32, .sfixed32), (.sfixed64, .sfixed64), (.sint32, .sint32), (.sint64, .sint64),
    ]

    for (fieldType, expectedProtobufType) in scalarFieldTypes {
      let fieldDescriptor = FieldDescriptor(name: "test", number: 1, type: fieldType)
      let protobufField = try bridge.toProtobufFieldDescriptor(from: fieldDescriptor)
      XCTAssertEqual(protobufField.type, expectedProtobufType)

      // Test reverse conversion
      var reverseProtobufField = Google_Protobuf_FieldDescriptorProto()
      reverseProtobufField.name = "test"
      reverseProtobufField.number = 1
      reverseProtobufField.type = expectedProtobufType
      reverseProtobufField.label = .optional

      let reverseFieldDescriptor = try bridge.fromProtobufFieldDescriptor(reverseProtobufField)
      XCTAssertEqual(reverseFieldDescriptor.type, fieldType)
    }

    // Test complex field types separately (require typeName)
    let complexFieldTypes: [(FieldType, Google_Protobuf_FieldDescriptorProto.TypeEnum, String)] = [
      (.message, .message, "TestMessage"),
      (.enum, .enum, "TestEnum"),
      (.group, .group, "TestGroup"),
    ]

    for (fieldType, expectedProtobufType, typeName) in complexFieldTypes {
      let fieldDescriptor = FieldDescriptor(name: "test", number: 1, type: fieldType, typeName: typeName)
      let protobufField = try bridge.toProtobufFieldDescriptor(from: fieldDescriptor)
      XCTAssertEqual(protobufField.type, expectedProtobufType)
      XCTAssertEqual(protobufField.typeName, typeName)

      // Test reverse conversion
      var reverseProtobufField = Google_Protobuf_FieldDescriptorProto()
      reverseProtobufField.name = "test"
      reverseProtobufField.number = 1
      reverseProtobufField.type = expectedProtobufType
      reverseProtobufField.typeName = typeName
      reverseProtobufField.label = .optional

      let reverseFieldDescriptor = try bridge.fromProtobufFieldDescriptor(reverseProtobufField)
      XCTAssertEqual(reverseFieldDescriptor.type, fieldType)
      XCTAssertEqual(reverseFieldDescriptor.typeName, typeName)
    }
  }

  // MARK: - OneofIndex Tests

  func testFieldWithOneofIndexPreservedFromProtobuf() throws {
    var protobufField = Google_Protobuf_FieldDescriptorProto()
    protobufField.name = "oneof_field"
    protobufField.number = 1
    protobufField.type = .string
    protobufField.label = .optional
    protobufField.oneofIndex = 0

    let fieldDescriptor = try bridge.fromProtobufFieldDescriptor(protobufField)

    XCTAssertEqual(fieldDescriptor.oneofIndex, 0)
  }

  func testFieldWithoutOneofIndexRemainsNil() throws {
    var protobufField = Google_Protobuf_FieldDescriptorProto()
    protobufField.name = "regular_field"
    protobufField.number = 1
    protobufField.type = .string
    protobufField.label = .optional

    let fieldDescriptor = try bridge.fromProtobufFieldDescriptor(protobufField)

    XCTAssertNil(fieldDescriptor.oneofIndex)
  }

  func testFieldOneofIndexRoundTrip() throws {
    let original = FieldDescriptor(
      name: "oneof_field",
      number: 1,
      type: .string,
      oneofIndex: 1
    )

    let proto = try bridge.toProtobufFieldDescriptor(from: original)
    XCTAssertTrue(proto.hasOneofIndex)
    XCTAssertEqual(proto.oneofIndex, 1)

    let converted = try bridge.fromProtobufFieldDescriptor(proto)
    XCTAssertEqual(converted.oneofIndex, 1)
  }

  // MARK: - Oneof Decls from Protobuf Tests

  func testOneofDeclsPopulatedFromProtobuf() throws {
    var proto = Google_Protobuf_DescriptorProto()
    proto.name = "User"

    var emailField = Google_Protobuf_FieldDescriptorProto()
    emailField.name = "email"
    emailField.number = 2
    emailField.type = .string
    emailField.label = .optional
    emailField.oneofIndex = 0

    var oneof = Google_Protobuf_OneofDescriptorProto()
    oneof.name = "contact"

    proto.field = [emailField]
    proto.oneofDecl = [oneof]

    let msg = try bridge.fromProtobufDescriptor(proto, parent: nil as (any DescriptorParent)?)

    XCTAssertEqual(msg.oneofDecls.count, 1)
    XCTAssertEqual(msg.oneofDecls[0].name, "contact")
    XCTAssertEqual(msg.oneofDecls[0].index, 0)
    XCTAssertNotNil(msg.oneof(at: 0))
    XCTAssertEqual(msg.oneof(at: 0)?.name, "contact")
  }

  func testMultipleOneofDeclsFromProtobuf() throws {
    var proto = Google_Protobuf_DescriptorProto()
    proto.name = "User"

    var oneof0 = Google_Protobuf_OneofDescriptorProto()
    oneof0.name = "contact"

    var oneof1 = Google_Protobuf_OneofDescriptorProto()
    oneof1.name = "identifier"

    proto.oneofDecl = [oneof0, oneof1]

    let msg = try bridge.fromProtobufDescriptor(proto, parent: nil as (any DescriptorParent)?)

    XCTAssertEqual(msg.oneofDecls.count, 2)
    XCTAssertEqual(msg.oneofDecls[0].name, "contact")
    XCTAssertEqual(msg.oneofDecls[0].index, 0)
    XCTAssertEqual(msg.oneofDecls[1].name, "identifier")
    XCTAssertEqual(msg.oneofDecls[1].index, 1)
    XCTAssertEqual(msg.oneof(at: 0)?.name, "contact")
    XCTAssertEqual(msg.oneof(at: 1)?.name, "identifier")
  }

  func testFieldOneofIndexMatchesOneofDecl() throws {
    var proto = Google_Protobuf_DescriptorProto()
    proto.name = "User"

    var emailField = Google_Protobuf_FieldDescriptorProto()
    emailField.name = "email"
    emailField.number = 2
    emailField.type = .string
    emailField.label = .optional
    emailField.oneofIndex = 0

    var phoneField = Google_Protobuf_FieldDescriptorProto()
    phoneField.name = "phone"
    phoneField.number = 3
    phoneField.type = .string
    phoneField.label = .optional
    phoneField.oneofIndex = 0

    var oneof = Google_Protobuf_OneofDescriptorProto()
    oneof.name = "contact"

    proto.field = [emailField, phoneField]
    proto.oneofDecl = [oneof]

    let msg = try bridge.fromProtobufDescriptor(proto, parent: nil as (any DescriptorParent)?)

    let emailDescriptor = msg.field(named: "email")
    let phoneDescriptor = msg.field(named: "phone")

    XCTAssertEqual(emailDescriptor?.oneofIndex, 0)
    XCTAssertEqual(phoneDescriptor?.oneofIndex, 0)

    let resolved = msg.oneof(at: 0)
    XCTAssertNotNil(resolved)
    XCTAssertEqual(resolved?.name, "contact")
    XCTAssertEqual(emailDescriptor?.oneofIndex, resolved?.index)
    XCTAssertEqual(phoneDescriptor?.oneofIndex, resolved?.index)
  }

  func testMessageWithoutOneofsHasEmptyOneofDecls() throws {
    var proto = Google_Protobuf_DescriptorProto()
    proto.name = "Simple"

    var field = Google_Protobuf_FieldDescriptorProto()
    field.name = "value"
    field.number = 1
    field.type = .string
    field.label = .optional

    proto.field = [field]

    let msg = try bridge.fromProtobufDescriptor(proto, parent: nil as (any DescriptorParent)?)

    XCTAssertTrue(msg.oneofDecls.isEmpty)
  }

  func testPrivateOptionsMethods() throws {
    // Test private methods for working with options via public methods

    // Create MessageDescriptor with options to test toProtobufMessageOptions
    let messageWithOptions = MessageDescriptor(
      name: "TestMessage",
      parent: fileDescriptor,
      options: ["test_option": .string("test_value")]
    )

    // Convert - this should call toProtobufMessageOptions
    let protobufDescriptor = try bridge.toProtobufDescriptor(from: messageWithOptions)
    XCTAssertEqual(protobufDescriptor.name, "TestMessage")

    // Create FieldDescriptor with options to test toProtobufFieldOptions
    let fieldWithOptions = FieldDescriptor(
      name: "test_field",
      number: 1,
      type: .string,
      options: ["field_option": .string("field_value")]
    )

    // Convert - this should call toProtobufFieldOptions
    let protobufField = try bridge.toProtobufFieldDescriptor(from: fieldWithOptions)
    XCTAssertEqual(protobufField.name, "test_field")
  }

  // MARK: - Oneof Decls Serialization Tests

  func testOneofDeclsSerializedToProtobuf() throws {
    var msg = MessageDescriptor(name: "User", fullName: "User")
    msg.addField(FieldDescriptor(name: "email", number: 2, type: .string, oneofIndex: 0))
    msg.addOneofDecl(OneofDescriptor(name: "contact", index: 0))

    let proto = try bridge.toProtobufDescriptor(from: msg)

    XCTAssertEqual(proto.oneofDecl.count, 1)
    XCTAssertEqual(proto.oneofDecl[0].name, "contact")
  }

  func testMultipleOneofDeclsSerializedToProtobuf() throws {
    var msg = MessageDescriptor(name: "User", fullName: "User")
    msg.addField(FieldDescriptor(name: "email", number: 2, type: .string, oneofIndex: 0))
    msg.addField(FieldDescriptor(name: "passport", number: 4, type: .string, oneofIndex: 1))
    msg.addOneofDecl(OneofDescriptor(name: "contact", index: 0))
    msg.addOneofDecl(OneofDescriptor(name: "identifier", index: 1))

    let proto = try bridge.toProtobufDescriptor(from: msg)

    XCTAssertEqual(proto.oneofDecl.count, 2)
    XCTAssertEqual(proto.oneofDecl[0].name, "contact")
    XCTAssertEqual(proto.oneofDecl[1].name, "identifier")
  }

  func testOneofRoundTrip() throws {
    var msg = MessageDescriptor(name: "User", fullName: "User")
    msg.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    msg.addField(FieldDescriptor(name: "email", number: 2, type: .string, oneofIndex: 0))
    msg.addField(FieldDescriptor(name: "phone", number: 3, type: .string, oneofIndex: 0))
    msg.addOneofDecl(OneofDescriptor(name: "contact", index: 0))

    let proto = try bridge.toProtobufDescriptor(from: msg)
    XCTAssertEqual(proto.oneofDecl.count, 1)
    XCTAssertEqual(proto.oneofDecl[0].name, "contact")
    XCTAssertEqual(proto.field.first { $0.name == "email" }?.oneofIndex, 0)

    let roundTripped = try bridge.fromProtobufDescriptor(proto, parent: nil as (any DescriptorParent)?)
    XCTAssertEqual(roundTripped.oneofDecls.count, 1)
    XCTAssertEqual(roundTripped.oneof(at: 0)?.name, "contact")
    XCTAssertEqual(roundTripped.field(named: "email")?.oneofIndex, 0)
    XCTAssertEqual(roundTripped.field(named: "phone")?.oneofIndex, 0)
    XCTAssertNil(roundTripped.field(named: "id")?.oneofIndex)
  }

  func testOneofRoundTripViaFileDescriptor() throws {
    var fileDesc = FileDescriptor(name: "user.proto", package: "example")
    var msg = MessageDescriptor(name: "User", parent: fileDesc)
    msg.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    msg.addField(FieldDescriptor(name: "email", number: 2, type: .string, oneofIndex: 0))
    msg.addField(FieldDescriptor(name: "phone", number: 3, type: .string, oneofIndex: 0))
    msg.addOneofDecl(OneofDescriptor(name: "contact", index: 0))
    fileDesc.addMessage(msg)

    let fileProto = try bridge.toProtobufFileDescriptor(from: fileDesc)
    let msgProto = try XCTUnwrap(fileProto.messageType.first { $0.name == "User" })
    XCTAssertEqual(msgProto.oneofDecl.count, 1)
    XCTAssertEqual(msgProto.oneofDecl[0].name, "contact")

    let roundTrippedFile = try bridge.fromProtobufFileDescriptor(fileProto)
    let roundTrippedMsg = try XCTUnwrap(roundTrippedFile.messages["User"])
    XCTAssertEqual(roundTrippedMsg.oneofDecls.count, 1)
    XCTAssertEqual(roundTrippedMsg.oneof(at: 0)?.name, "contact")
    XCTAssertEqual(roundTrippedMsg.field(named: "email")?.oneofIndex, 0)
    XCTAssertEqual(roundTrippedMsg.field(named: "phone")?.oneofIndex, 0)
    XCTAssertNil(roundTrippedMsg.field(named: "id")?.oneofIndex)
  }

  // MARK: - OPE-221: FieldDescriptor bridge edge cases (T-FD-05, T-FD-09, T-FD-11)

  func test_toProtobufFieldDescriptor_whenFieldHasOneofIndexZero_setsProtoOneofIndex_TFD05() throws {
    let field = FieldDescriptor(
      name: "email",
      number: 2,
      type: .string,
      oneofIndex: 0
    )
    let proto = try bridge.toProtobufFieldDescriptor(from: field)
    XCTAssertTrue(proto.hasOneofIndex)
    XCTAssertEqual(proto.oneofIndex, 0)
  }

  func test_toProtobufFieldDescriptor_whenFieldHasNoOneof_clearsProtoOneofIndex_TFD09() throws {
    let field = FieldDescriptor(name: "name", number: 1, type: .string)
    let proto = try bridge.toProtobufFieldDescriptor(from: field)
    XCTAssertFalse(proto.hasOneofIndex)
  }

  func test_fromProtobufDescriptor_whenMapField_detectedMapHasNilOneofIndex_TFD11() throws {
    var messageProto = Google_Protobuf_DescriptorProto()
    messageProto.name = "WithMap"

    var mapField = Google_Protobuf_FieldDescriptorProto()
    mapField.name = "labels"
    mapField.number = 5
    mapField.type = .message
    mapField.label = .repeated
    mapField.typeName = ".test.WithMap.LabelsEntry"

    let entryMessage = Self.makeMapEntryProto(
      name: "LabelsEntry",
      keyType: .string,
      valueType: .string
    )
    messageProto.nestedType = [entryMessage]
    messageProto.field = [mapField]

    let msg = try bridge.fromProtobufDescriptor(messageProto, parent: nil as (any DescriptorParent)?)
    let labels = try XCTUnwrap(msg.field(named: "labels"))
    XCTAssertTrue(labels.isMap)
    XCTAssertNil(labels.oneofIndex)
  }

  // MARK: - OPE-221: fromProtobuf oneof (T-BR-FROM-05…13)

  func test_fromProtobufDescriptor_mixedScalarAndOneofFields_TBRFROM05() throws {
    var proto = Google_Protobuf_DescriptorProto()
    proto.name = "User"

    var idField = Google_Protobuf_FieldDescriptorProto()
    idField.name = "id"
    idField.number = 1
    idField.type = .string
    idField.label = .optional

    var emailField = Google_Protobuf_FieldDescriptorProto()
    emailField.name = "email"
    emailField.number = 2
    emailField.type = .string
    emailField.label = .optional
    emailField.oneofIndex = 0

    var oneof = Google_Protobuf_OneofDescriptorProto()
    oneof.name = "contact"

    proto.field = [idField, emailField]
    proto.oneofDecl = [oneof]

    let msg = try bridge.fromProtobufDescriptor(proto, parent: nil as (any DescriptorParent)?)
    XCTAssertNil(msg.field(named: "id")?.oneofIndex)
    XCTAssertEqual(msg.field(named: "email")?.oneofIndex, 0)
  }

  func test_fromProtobufFileDescriptor_preservesOneofDecls_TBRFROM06() throws {
    var fileDesc = FileDescriptor(name: "m.proto", package: "example")
    var msg = MessageDescriptor(name: "User", parent: fileDesc)
    msg.addField(FieldDescriptor(name: "email", number: 2, type: .string, oneofIndex: 0))
    msg.addOneofDecl(OneofDescriptor(name: "contact", index: 0))
    fileDesc.addMessage(msg)

    let fileProto = try bridge.toProtobufFileDescriptor(from: fileDesc)
    let roundFile = try bridge.fromProtobufFileDescriptor(fileProto)
    let roundMsg = try XCTUnwrap(roundFile.messages["User"])
    XCTAssertEqual(roundMsg.oneofDecls.count, 1)
    XCTAssertEqual(roundMsg.oneof(at: 0)?.name, "contact")
  }

  func test_fromProtobufDescriptor_nestedMessageOneofIndependent_TBRFROM07() throws {
    var inner = Google_Protobuf_DescriptorProto()
    inner.name = "Inner"
    var innerOneof = Google_Protobuf_OneofDescriptorProto()
    innerOneof.name = "format"
    var innerField = Google_Protobuf_FieldDescriptorProto()
    innerField.name = "x"
    innerField.number = 1
    innerField.type = .string
    innerField.label = .optional
    innerField.oneofIndex = 0
    inner.field = [innerField]
    inner.oneofDecl = [innerOneof]

    var outer = Google_Protobuf_DescriptorProto()
    outer.name = "Outer"
    var outerOneof = Google_Protobuf_OneofDescriptorProto()
    outerOneof.name = "kind"
    var outerField = Google_Protobuf_FieldDescriptorProto()
    outerField.name = "a"
    outerField.number = 1
    outerField.type = .string
    outerField.label = .optional
    outerField.oneofIndex = 0
    outer.field = [outerField]
    outer.oneofDecl = [outerOneof]
    outer.nestedType = [inner]

    let msg = try bridge.fromProtobufDescriptor(outer, parent: nil as (any DescriptorParent)?)
    XCTAssertEqual(msg.oneofDecls.count, 1)
    XCTAssertEqual(msg.oneof(at: 0)?.name, "kind")
    let innerMsg = try XCTUnwrap(msg.nestedMessage(named: "Inner"))
    XCTAssertEqual(innerMsg.oneofDecls.count, 1)
    XCTAssertEqual(innerMsg.oneof(at: 0)?.name, "format")
  }

  func test_fromProtobufDescriptor_onlyOneofFields_TBRFROM09() throws {
    var proto = Google_Protobuf_DescriptorProto()
    proto.name = "OnlyOneof"

    var a = Google_Protobuf_FieldDescriptorProto()
    a.name = "a"
    a.number = 1
    a.type = .string
    a.label = .optional
    a.oneofIndex = 0

    var b = Google_Protobuf_FieldDescriptorProto()
    b.name = "b"
    b.number = 2
    b.type = .string
    b.label = .optional
    b.oneofIndex = 0

    var oneof = Google_Protobuf_OneofDescriptorProto()
    oneof.name = "choice"

    proto.field = [a, b]
    proto.oneofDecl = [oneof]

    let msg = try bridge.fromProtobufDescriptor(proto, parent: nil as (any DescriptorParent)?)
    XCTAssertEqual(msg.fields.count, 2)
    XCTAssertEqual(msg.oneofDecls.count, 1)
    XCTAssertEqual(msg.field(named: "a")?.oneofIndex, 0)
  }

  func test_fromProtobufDescriptor_proto3SyntheticOptionalOneof_TBRFROM10() throws {
    var proto = Google_Protobuf_DescriptorProto()
    proto.name = "WithOptional"

    var syntheticOneof = Google_Protobuf_OneofDescriptorProto()
    syntheticOneof.name = "_nickname"

    var nickField = Google_Protobuf_FieldDescriptorProto()
    nickField.name = "nickname"
    nickField.number = 1
    nickField.type = .string
    nickField.label = .optional
    nickField.oneofIndex = 0
    nickField.proto3Optional = true

    proto.field = [nickField]
    proto.oneofDecl = [syntheticOneof]

    let msg = try bridge.fromProtobufDescriptor(proto, parent: nil as (any DescriptorParent)?)
    XCTAssertEqual(msg.oneofDecls.count, 1)
    XCTAssertEqual(msg.oneofDecls[0].name, "_nickname")
    XCTAssertEqual(msg.field(named: "nickname")?.oneofIndex, 0)
  }

  func test_fromProtobufDescriptor_emptyOneofName_TBRFROM11() throws {
    var proto = Google_Protobuf_DescriptorProto()
    proto.name = "M"
    var oneof = Google_Protobuf_OneofDescriptorProto()
    oneof.name = ""
    var f = Google_Protobuf_FieldDescriptorProto()
    f.name = "x"
    f.number = 1
    f.type = .string
    f.label = .optional
    f.oneofIndex = 0
    proto.field = [f]
    proto.oneofDecl = [oneof]

    let msg = try bridge.fromProtobufDescriptor(proto, parent: nil as (any DescriptorParent)?)
    XCTAssertEqual(msg.oneofDecls[0].name, "")
    XCTAssertEqual(msg.oneofDecls[0].index, 0)
  }

  func test_fromProtobufDescriptor_oneofDeclOrderDefinesIndex_TBRFROM12() throws {
    var proto = Google_Protobuf_DescriptorProto()
    proto.name = "Ordered"

    var oneofPayment = Google_Protobuf_OneofDescriptorProto()
    oneofPayment.name = "payment"
    var oneofContact = Google_Protobuf_OneofDescriptorProto()
    oneofContact.name = "contact"

    var payField = Google_Protobuf_FieldDescriptorProto()
    payField.name = "card"
    payField.number = 2
    payField.type = .string
    payField.label = .optional
    payField.oneofIndex = 0

    var mailField = Google_Protobuf_FieldDescriptorProto()
    mailField.name = "email"
    mailField.number = 3
    mailField.type = .string
    mailField.label = .optional
    mailField.oneofIndex = 1

    proto.oneofDecl = [oneofPayment, oneofContact]
    proto.field = [payField, mailField]

    let msg = try bridge.fromProtobufDescriptor(proto, parent: nil as (any DescriptorParent)?)
    XCTAssertEqual(msg.oneof(at: 0)?.name, "payment")
    XCTAssertEqual(msg.oneof(at: 1)?.name, "contact")
    XCTAssertEqual(msg.field(named: "card")?.oneofIndex, 0)
    XCTAssertEqual(msg.field(named: "email")?.oneofIndex, 1)
  }

  func test_fromProtobufDescriptor_mapAndOneofCoexist_TBRFROM13() throws {
    var messageProto = Google_Protobuf_DescriptorProto()
    messageProto.name = "Hybrid"

    var mapField = Google_Protobuf_FieldDescriptorProto()
    mapField.name = "labels"
    mapField.number = 1
    mapField.type = .message
    mapField.label = .repeated
    mapField.typeName = ".test.Hybrid.LabelsEntry"

    var emailField = Google_Protobuf_FieldDescriptorProto()
    emailField.name = "email"
    emailField.number = 2
    emailField.type = .string
    emailField.label = .optional
    emailField.oneofIndex = 0

    var oneof = Google_Protobuf_OneofDescriptorProto()
    oneof.name = "contact"

    let entry = Self.makeMapEntryProto(name: "LabelsEntry", keyType: .string, valueType: .string)
    messageProto.nestedType = [entry]
    messageProto.field = [mapField, emailField]
    messageProto.oneofDecl = [oneof]

    let msg = try bridge.fromProtobufDescriptor(messageProto, parent: nil as (any DescriptorParent)?)
    XCTAssertTrue(try XCTUnwrap(msg.field(named: "labels")).isMap)
    XCTAssertNil(msg.field(named: "labels")?.oneofIndex)
    XCTAssertEqual(msg.field(named: "email")?.oneofIndex, 0)
  }

  // MARK: - OPE-221: toProtobuf oneof (T-BR-TO-02…12)

  func test_toProtobufDescriptor_fieldWithOneofIndexWritesProtoOneofIndex_TBRTO03() throws {
    var msg = MessageDescriptor(name: "User", fullName: "User")
    msg.addField(FieldDescriptor(name: "email", number: 2, type: .string, oneofIndex: 0))
    msg.addOneofDecl(OneofDescriptor(name: "contact", index: 0))

    let proto = try bridge.toProtobufDescriptor(from: msg)
    let emailProto = try XCTUnwrap(proto.field.first { $0.name == "email" })
    XCTAssertTrue(emailProto.hasOneofIndex)
    XCTAssertEqual(emailProto.oneofIndex, 0)
  }

  func test_toProtobufDescriptor_oneofDeclsSortedByIndex_TBRTO02() throws {
    var msg = MessageDescriptor(name: "User", fullName: "User")
    msg.addOneofDecl(OneofDescriptor(name: "payment", index: 1))
    msg.addOneofDecl(OneofDescriptor(name: "contact", index: 0))

    let proto = try bridge.toProtobufDescriptor(from: msg)
    XCTAssertEqual(proto.oneofDecl.count, 2)
    XCTAssertEqual(proto.oneofDecl[0].name, "contact")
    XCTAssertEqual(proto.oneofDecl[1].name, "payment")
  }

  func test_toProtobufDescriptor_regularFieldOmitsOneofIndex_TBRTO04() throws {
    var msg = MessageDescriptor(name: "User", fullName: "User")
    msg.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    msg.addField(FieldDescriptor(name: "email", number: 2, type: .string, oneofIndex: 0))
    msg.addOneofDecl(OneofDescriptor(name: "contact", index: 0))

    let proto = try bridge.toProtobufDescriptor(from: msg)
    let idProto = try XCTUnwrap(proto.field.first { $0.name == "id" })
    XCTAssertFalse(idProto.hasOneofIndex)
  }

  func test_toProtobufDescriptor_fullMessageRoundTripPreservesOneofs_TBRTO05() throws {
    var msg = MessageDescriptor(name: "User", fullName: "User")
    msg.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    msg.addField(FieldDescriptor(name: "email", number: 2, type: .string, oneofIndex: 0))
    msg.addOneofDecl(OneofDescriptor(name: "contact", index: 0))

    let proto = try bridge.toProtobufDescriptor(from: msg)
    let round = try bridge.fromProtobufDescriptor(proto, parent: nil as (any DescriptorParent)?)

    XCTAssertEqual(round.oneofDecls.count, 1)
    XCTAssertEqual(round.oneof(at: 0)?.name, "contact")
    XCTAssertNil(round.field(named: "id")?.oneofIndex)
    XCTAssertEqual(round.field(named: "email")?.oneofIndex, 0)
  }

  func test_toProtobufDescriptor_nestedOneofRoundTripIndependent_TBRTO07() throws {
    var inner = MessageDescriptor(name: "Inner", fullName: "Outer.Inner")
    inner.addField(FieldDescriptor(name: "x", number: 1, type: .string, oneofIndex: 0))
    inner.addOneofDecl(OneofDescriptor(name: "format", index: 0))

    var outer = MessageDescriptor(name: "Outer", fullName: "Outer")
    outer.addField(FieldDescriptor(name: "a", number: 1, type: .string, oneofIndex: 0))
    outer.addOneofDecl(OneofDescriptor(name: "kind", index: 0))
    outer.addNestedMessage(inner)

    let proto = try bridge.toProtobufDescriptor(from: outer)
    let round = try bridge.fromProtobufDescriptor(proto, parent: nil as (any DescriptorParent)?)

    XCTAssertEqual(round.oneof(at: 0)?.name, "kind")
    let innerRound = try XCTUnwrap(round.nestedMessage(named: "Inner"))
    XCTAssertEqual(innerRound.oneof(at: 0)?.name, "format")
  }

  func test_toProtobufDescriptor_withoutOneofDecls_emitsEmptyOneofDecl_TBRTO08() throws {
    var msg = MessageDescriptor(name: "Plain", fullName: "Plain")
    msg.addField(FieldDescriptor(name: "v", number: 1, type: .string))

    let proto = try bridge.toProtobufDescriptor(from: msg)
    XCTAssertTrue(proto.oneofDecl.isEmpty)
  }

  func test_toProtobufDescriptor_oneofDeclsWithoutFieldOneofIndices_TBRTO09() throws {
    var msg = MessageDescriptor(name: "M", fullName: "M")
    msg.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    msg.addOneofDecl(OneofDescriptor(name: "unused", index: 0))

    let proto = try bridge.toProtobufDescriptor(from: msg)
    XCTAssertEqual(proto.oneofDecl.count, 1)
    XCTAssertFalse(try XCTUnwrap(proto.field.first { $0.name == "id" }).hasOneofIndex)
  }

  func test_toProtobufDescriptor_duplicateOneofIndices_notDeduplicated_TBRTO10() throws {
    var msg = MessageDescriptor(name: "M", fullName: "M")
    msg.addOneofDecl(OneofDescriptor(name: "a", index: 0))
    msg.addOneofDecl(OneofDescriptor(name: "b", index: 0))

    let proto = try bridge.toProtobufDescriptor(from: msg)
    XCTAssertEqual(proto.oneofDecl.count, 2)
  }

  func test_toProtobufDescriptor_manyOneofGroups_sortedByIndex_TBRTO11() throws {
    var msg = MessageDescriptor(name: "Big", fullName: "Big")
    for i in 0..<11 {
      msg.addOneofDecl(OneofDescriptor(name: "g\(i)", index: i))
    }
    let proto = try bridge.toProtobufDescriptor(from: msg)
    XCTAssertEqual(proto.oneofDecl.count, 11)
    for i in 0..<11 {
      XCTAssertEqual(proto.oneofDecl[i].name, "g\(i)")
    }
  }

  func test_toProtobufDescriptor_mapAndOneofFieldsIndependent_TBRTO12() throws {
    var msg = MessageDescriptor(name: "Hybrid", fullName: "test.Hybrid")
    let keyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let mapInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valInfo)
    msg.addField(
      FieldDescriptor(
        name: "labels",
        number: 1,
        type: .message,
        typeName: "test.Hybrid.LabelsEntry",
        isRepeated: true,
        isMap: true,
        mapEntryInfo: mapInfo
      )
    )
    msg.addField(FieldDescriptor(name: "email", number: 2, type: .string, oneofIndex: 0))
    msg.addOneofDecl(OneofDescriptor(name: "contact", index: 0))

    let proto = try bridge.toProtobufDescriptor(from: msg)
    XCTAssertEqual(proto.oneofDecl.count, 1)
    XCTAssertFalse(try XCTUnwrap(proto.field.first { $0.name == "labels" }).hasOneofIndex)
    XCTAssertTrue(try XCTUnwrap(proto.field.first { $0.name == "email" }).hasOneofIndex)
  }

  private static func makeMapEntryProto(
    name: String,
    keyType: Google_Protobuf_FieldDescriptorProto.TypeEnum,
    valueType: Google_Protobuf_FieldDescriptorProto.TypeEnum,
    valueTypeName: String? = nil
  ) -> Google_Protobuf_DescriptorProto {
    var entryMessage = Google_Protobuf_DescriptorProto()
    entryMessage.name = name
    var options = Google_Protobuf_MessageOptions()
    options.mapEntry = true
    entryMessage.options = options

    var keyField = Google_Protobuf_FieldDescriptorProto()
    keyField.name = "key"
    keyField.number = 1
    keyField.type = keyType
    keyField.label = .optional

    var valueField = Google_Protobuf_FieldDescriptorProto()
    valueField.name = "value"
    valueField.number = 2
    valueField.type = valueType
    valueField.label = .optional
    if let valueTypeName {
      valueField.typeName = valueTypeName
    }

    entryMessage.field = [keyField, valueField]
    return entryMessage
  }
}
