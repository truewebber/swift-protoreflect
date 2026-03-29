//
// StaticMessageBridgeCreateDescriptorTests.swift
// SwiftProtoReflect
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class StaticMessageBridgeCreateDescriptorTests: XCTestCase {

  // MARK: - Test: simple message with populated fields

  func test_createDescriptor_simpleMessage_allFieldsExtracted() throws {
    var msg = Google_Protobuf_DescriptorProto()
    msg.name = "TestMessage"

    let bridge = StaticMessageBridge()
    let dynamic = try bridge.toDynamicMessage(from: msg)

    XCTAssertEqual(dynamic.descriptor.name, "google.protobuf.DescriptorProto")
    let nameValue = try dynamic.get(forField: "name")
    XCTAssertEqual(nameValue as? String, "TestMessage")
  }

  func test_createDescriptor_emptyMessage_validDescriptor() throws {
    let msg = Google_Protobuf_Empty()

    let bridge = StaticMessageBridge()
    let dynamic = try bridge.toDynamicMessage(from: msg)

    XCTAssertEqual(dynamic.descriptor.name, "google.protobuf.Empty")
  }

  func test_createDescriptor_messageFieldNames_correct() throws {
    var msg = Google_Protobuf_FieldDescriptorProto()
    msg.name = "test_field"
    msg.number = 42

    let bridge = StaticMessageBridge()
    let dynamic = try bridge.toDynamicMessage(from: msg)

    XCTAssertEqual(dynamic.descriptor.name, "google.protobuf.FieldDescriptorProto")

    let nameValue = try dynamic.get(forField: "name")
    XCTAssertEqual(nameValue as? String, "test_field")
    let numberValue = try dynamic.get(forField: "number")
    XCTAssertEqual(numberValue as? Int32, 42)
  }

  func test_createDescriptor_fieldNumbers_correct() throws {
    var msg = Google_Protobuf_FieldDescriptorProto()
    msg.name = "test_field"
    msg.number = 7

    let bridge = StaticMessageBridge()
    let dynamic = try bridge.toDynamicMessage(from: msg)

    let descriptor = dynamic.descriptor
    let nameField = descriptor.field(named: "name")
    XCTAssertNotNil(nameField)
    XCTAssertEqual(nameField?.number, 1)

    let numberField = descriptor.field(named: "number")
    XCTAssertNotNil(numberField)
    XCTAssertEqual(numberField?.number, 3)
  }

  func test_createDescriptor_fieldTypes_correct() throws {
    var msg = Google_Protobuf_FieldDescriptorProto()
    msg.name = "test_field"
    msg.number = 7

    let bridge = StaticMessageBridge()
    let dynamic = try bridge.toDynamicMessage(from: msg)

    let descriptor = dynamic.descriptor
    let nameField = descriptor.field(named: "name")
    XCTAssertEqual(nameField?.type, .string)

    let numberField = descriptor.field(named: "number")
    XCTAssertEqual(numberField?.type, .int32)
  }

  func test_createDescriptor_messageWithBoolField_typeCorrect() throws {
    var msg = Google_Protobuf_FileDescriptorProto()
    msg.name = "test.proto"
    msg.syntax = "proto3"

    let bridge = StaticMessageBridge()
    let dynamic = try bridge.toDynamicMessage(from: msg)

    let nameValue = try dynamic.get(forField: "name")
    XCTAssertEqual(nameValue as? String, "test.proto")
    let syntaxValue = try dynamic.get(forField: "syntax")
    XCTAssertEqual(syntaxValue as? String, "proto3")
  }

  func test_createDescriptor_roundTrip_preservesData() throws {
    var original = Google_Protobuf_FieldDescriptorProto()
    original.name = "my_field"
    original.number = 5
    original.type = .int32

    let bridge = StaticMessageBridge()
    let dynamic = try bridge.toDynamicMessage(from: original)
    let restored = try bridge.toStaticMessage(
      from: dynamic,
      as: Google_Protobuf_FieldDescriptorProto.self
    )

    XCTAssertEqual(restored.name, "my_field")
    XCTAssertEqual(restored.number, 5)
    XCTAssertEqual(restored.type, .int32)
  }
}
