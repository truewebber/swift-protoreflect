//
// Proto2BridgeTests.swift
// SwiftProtoReflect
//
// Tests for proto2-specific bridge features:
// syntax propagation, defaultValue parsing, extension ranges, isPacked.
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class Proto2BridgeTests: XCTestCase {

  private var bridge: DescriptorBridge!

  override func setUp() {
    super.setUp()
    bridge = DescriptorBridge()
  }

  // MARK: - Syntax propagation through bridge

  func test_bridge_fromProtobufFile_syntaxPropagatesToFields() throws {
    var fileProto = Google_Protobuf_FileDescriptorProto()
    fileProto.name = "test.proto"
    fileProto.syntax = "proto2"

    var msgProto = Google_Protobuf_DescriptorProto()
    msgProto.name = "TestMsg"

    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "req_field"
    fieldProto.number = 1
    fieldProto.type = .string
    fieldProto.label = .required
    msgProto.field = [fieldProto]

    fileProto.messageType = [msgProto]

    let fileDesc = try bridge.fromProtobufFileDescriptor(fileProto)
    let msg = fileDesc.messages["TestMsg"]

    XCTAssertEqual(msg?.syntax, "proto2")
    let field = msg?.field(named: "req_field")
    XCTAssertEqual(field?.isRequired, true)
  }

  func test_bridge_fromProtobuf_requiredLabel_proto2_setsIsRequired() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "req"
    fieldProto.number = 1
    fieldProto.type = .string
    fieldProto.label = .required

    let field = try bridge.fromProtobufFieldDescriptor(fieldProto, syntax: "proto2")
    XCTAssertTrue(field.isRequired)
  }

  func test_bridge_fromProtobuf_requiredLabel_proto3_ignores() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "req"
    fieldProto.number = 1
    fieldProto.type = .string
    fieldProto.label = .required

    let field = try bridge.fromProtobufFieldDescriptor(fieldProto, syntax: "proto3")
    XCTAssertFalse(field.isRequired)
  }

  // MARK: - Default value parsing

  func test_bridge_fromProtobuf_defaultValue_string() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "name"
    fieldProto.number = 1
    fieldProto.type = .string
    fieldProto.label = .optional
    fieldProto.defaultValue = "hello"

    let field = try bridge.fromProtobufFieldDescriptor(fieldProto, syntax: "proto2")
    XCTAssertEqual(field.defaultValue, .string("hello"))
  }

  func test_bridge_fromProtobuf_defaultValue_int32() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "count"
    fieldProto.number = 1
    fieldProto.type = .int32
    fieldProto.label = .optional
    fieldProto.defaultValue = "42"

    let field = try bridge.fromProtobufFieldDescriptor(fieldProto, syntax: "proto2")
    XCTAssertEqual(field.defaultValue, .int(42))
  }

  func test_bridge_fromProtobuf_defaultValue_bool_true() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "flag"
    fieldProto.number = 1
    fieldProto.type = .bool
    fieldProto.label = .optional
    fieldProto.defaultValue = "true"

    let field = try bridge.fromProtobufFieldDescriptor(fieldProto, syntax: "proto2")
    XCTAssertEqual(field.defaultValue, .bool(true))
  }

  func test_bridge_fromProtobuf_defaultValue_double() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "ratio"
    fieldProto.number = 1
    fieldProto.type = .double
    fieldProto.label = .optional
    fieldProto.defaultValue = "3.14"

    let field = try bridge.fromProtobufFieldDescriptor(fieldProto, syntax: "proto2")
    XCTAssertEqual(field.defaultValue, .double(3.14))
  }

  func test_bridge_fromProtobuf_defaultValue_float() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "weight"
    fieldProto.number = 1
    fieldProto.type = .float
    fieldProto.label = .optional
    fieldProto.defaultValue = "1.5"

    let field = try bridge.fromProtobufFieldDescriptor(fieldProto, syntax: "proto2")
    XCTAssertEqual(field.defaultValue, .float(1.5))
  }

  func test_bridge_fromProtobuf_emptyDefaultValue_meansNoDefault() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "name"
    fieldProto.number = 1
    fieldProto.type = .string
    fieldProto.label = .optional

    let field = try bridge.fromProtobufFieldDescriptor(fieldProto, syntax: "proto2")
    XCTAssertNil(field.defaultValue)
  }

  // MARK: - isPacked from options

  func test_bridge_fromProtobuf_packed_option_true() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "values"
    fieldProto.number = 1
    fieldProto.type = .int32
    fieldProto.label = .repeated
    fieldProto.options.packed = true

    let field = try bridge.fromProtobufFieldDescriptor(fieldProto, syntax: "proto2")
    XCTAssertEqual(field.isPacked, true)
  }

  func test_bridge_fromProtobuf_packed_option_false() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "values"
    fieldProto.number = 1
    fieldProto.type = .int32
    fieldProto.label = .repeated
    fieldProto.options.packed = false

    let field = try bridge.fromProtobufFieldDescriptor(fieldProto, syntax: "proto3")
    XCTAssertEqual(field.isPacked, false)
  }

  func test_bridge_fromProtobuf_noPacked_option_nil() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "values"
    fieldProto.number = 1
    fieldProto.type = .int32
    fieldProto.label = .repeated

    let field = try bridge.fromProtobufFieldDescriptor(fieldProto, syntax: "proto2")
    XCTAssertNil(field.isPacked)
  }

  // MARK: - Extension ranges

  func test_bridge_fromProtobuf_extensionRange_converted() throws {
    var msgProto = Google_Protobuf_DescriptorProto()
    msgProto.name = "Extendable"

    var range = Google_Protobuf_DescriptorProto.ExtensionRange()
    range.start = 100
    range.end = 200
    msgProto.extensionRange = [range]

    let desc = try bridge.fromProtobufDescriptor(msgProto)
    XCTAssertEqual(desc.extensionRanges.count, 1)
    XCTAssertEqual(desc.extensionRanges[0].start, 100)
    XCTAssertEqual(desc.extensionRanges[0].end, 200)
  }

  func test_bridge_fromProtobuf_multipleExtensionRanges() throws {
    var msgProto = Google_Protobuf_DescriptorProto()
    msgProto.name = "Extendable"

    var range1 = Google_Protobuf_DescriptorProto.ExtensionRange()
    range1.start = 100
    range1.end = 200
    var range2 = Google_Protobuf_DescriptorProto.ExtensionRange()
    range2.start = 300
    range2.end = 400
    msgProto.extensionRange = [range1, range2]

    let desc = try bridge.fromProtobufDescriptor(msgProto)
    XCTAssertEqual(desc.extensionRanges.count, 2)
  }

  func test_bridge_toProtobuf_extensionRange_preserved() throws {
    var desc = MessageDescriptor(name: "Extendable", fullName: "test.Extendable")
    desc.addExtensionRange(ExtensionRange(start: 100, end: 200))

    let proto = try bridge.toProtobufDescriptor(from: desc)
    XCTAssertEqual(proto.extensionRange.count, 1)
    XCTAssertEqual(proto.extensionRange[0].start, 100)
    XCTAssertEqual(proto.extensionRange[0].end, 200)
  }
}
