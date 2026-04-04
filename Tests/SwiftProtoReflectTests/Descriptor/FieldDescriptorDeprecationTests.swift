//
// FieldDescriptorDeprecationTests.swift
// SwiftProtoReflectTests
//

import XCTest

import struct SwiftProtobuf.Google_Protobuf_FieldDescriptorProto

@testable import SwiftProtoReflect

final class FieldDescriptorDeprecationTests: XCTestCase {

  // MARK: - isRequired Default

  func test_isRequired_defaultFalse() {
    let field = FieldDescriptor(name: "value", number: 1, type: .int32)
    XCTAssertFalse(field.isRequired)
  }

  // MARK: - Validation Gated on Syntax

  func test_validate_proto3Message_requiredFieldIgnored() {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto3")
    desc.addField(FieldDescriptor(name: "value", number: 1, type: .int32, isRequired: true))

    let msg = DynamicMessage(descriptor: desc)
    let factory = MessageFactory()
    let result = factory.validate(msg)

    XCTAssertTrue(result.isValid, "Proto3 should ignore isRequired: \(result.errors)")
  }

  func test_validate_proto2Message_requiredFieldChecked() {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    desc.addField(FieldDescriptor(name: "value", number: 1, type: .int32, isRequired: true))

    let msg = DynamicMessage(descriptor: desc)
    let factory = MessageFactory()
    let result = factory.validate(msg)

    XCTAssertFalse(result.isValid, "Proto2 should report missing required field")
  }

  // MARK: - Bridge

  func test_bridge_proto3Label_neverSetsRequired() throws {
    var proto = Google_Protobuf_FieldDescriptorProto()
    proto.name = "value"
    proto.number = 1
    proto.type = .int32
    proto.label = .required

    let bridge = DescriptorBridge()
    let field = try bridge.fromProtobufFieldDescriptor(proto, syntax: "proto3")
    XCTAssertFalse(field.isRequired, "Proto3 should never have isRequired = true")
  }

  func test_bridge_proto2Label_setsRequired() throws {
    var proto = Google_Protobuf_FieldDescriptorProto()
    proto.name = "value"
    proto.number = 1
    proto.type = .int32
    proto.label = .required

    let bridge = DescriptorBridge()
    let field = try bridge.fromProtobufFieldDescriptor(proto, syntax: "proto2")
    XCTAssertTrue(field.isRequired, "Proto2 should respect LABEL_REQUIRED")
  }
}
