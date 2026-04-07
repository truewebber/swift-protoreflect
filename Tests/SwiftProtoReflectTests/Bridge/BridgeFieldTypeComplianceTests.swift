//
// BridgeFieldTypeComplianceTests.swift
// SwiftProtoReflectTests
//
// Compliance tests for DescriptorBridge covering sint32/sfixed32/fixed32/sfixed64/fixed64
// field types, parseDefaultValue branches, and coverage for structural edge cases.
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class BridgeFieldTypeComplianceTests: XCTestCase {

  private var bridge: DescriptorBridge!

  override func setUp() async throws {
    try await super.setUp()
    bridge = DescriptorBridge()
  }

  // MARK: - parseDefaultValue branch coverage: sint32

  func test_bridge_fromProtobuf_defaultValue_sint32_parsedAsInt() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "val"
    fieldProto.number = 1
    fieldProto.type = .sint32
    fieldProto.label = .optional
    fieldProto.defaultValue = "-7"

    let field = try bridge.fromProtobufFieldDescriptor(fieldProto, syntax: "proto2")
    XCTAssertEqual(field.defaultValue, .int(-7))
  }

  // MARK: - parseDefaultValue branch coverage: sfixed32

  func test_bridge_fromProtobuf_defaultValue_sfixed32_parsedAsInt() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "val"
    fieldProto.number = 1
    fieldProto.type = .sfixed32
    fieldProto.label = .optional
    fieldProto.defaultValue = "128"

    let field = try bridge.fromProtobufFieldDescriptor(fieldProto, syntax: "proto2")
    XCTAssertEqual(field.defaultValue, .int(128))
  }

  // MARK: - parseDefaultValue branch coverage: int64

  func test_bridge_fromProtobuf_defaultValue_int64_parsedAsInt() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "val"
    fieldProto.number = 1
    fieldProto.type = .int64
    fieldProto.label = .optional
    fieldProto.defaultValue = "9000"

    let field = try bridge.fromProtobufFieldDescriptor(fieldProto, syntax: "proto2")
    XCTAssertEqual(field.defaultValue, .int(9000))
  }

  // MARK: - parseDefaultValue branch coverage: sfixed64

  func test_bridge_fromProtobuf_defaultValue_sfixed64_parsedAsInt() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "val"
    fieldProto.number = 1
    fieldProto.type = .sfixed64
    fieldProto.label = .optional
    fieldProto.defaultValue = "-500"

    let field = try bridge.fromProtobufFieldDescriptor(fieldProto, syntax: "proto2")
    XCTAssertEqual(field.defaultValue, .int(-500))
  }

  // MARK: - parseDefaultValue branch coverage: fixed32

  func test_bridge_fromProtobuf_defaultValue_fixed32_parsedAsInt() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "val"
    fieldProto.number = 1
    fieldProto.type = .fixed32
    fieldProto.label = .optional
    fieldProto.defaultValue = "256"

    let field = try bridge.fromProtobufFieldDescriptor(fieldProto, syntax: "proto2")
    XCTAssertEqual(field.defaultValue, .int(256))
  }

  // MARK: - parseDefaultValue branch coverage: fixed64

  func test_bridge_fromProtobuf_defaultValue_fixed64_parsedAsInt() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "val"
    fieldProto.number = 1
    fieldProto.type = .fixed64
    fieldProto.label = .optional
    fieldProto.defaultValue = "1024"

    let field = try bridge.fromProtobufFieldDescriptor(fieldProto, syntax: "proto2")
    XCTAssertEqual(field.defaultValue, .int(1024))
  }

  // MARK: - parseDefaultValue invalid: sint32 with non-numeric string

  func test_bridge_fromProtobuf_defaultValue_sint32_invalidString_fallsBackToString() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "val"
    fieldProto.number = 1
    fieldProto.type = .sint32
    fieldProto.label = .optional
    fieldProto.defaultValue = "xyz"

    let field = try bridge.fromProtobufFieldDescriptor(fieldProto, syntax: "proto2")
    XCTAssertEqual(field.defaultValue, .string("xyz"))
  }

  // MARK: - parseDefaultValue invalid: sfixed64 with non-numeric string

  func test_bridge_fromProtobuf_defaultValue_sfixed64_invalidString_fallsBackToString() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "val"
    fieldProto.number = 1
    fieldProto.type = .sfixed64
    fieldProto.label = .optional
    fieldProto.defaultValue = "not_a_number"

    let field = try bridge.fromProtobufFieldDescriptor(fieldProto, syntax: "proto2")
    XCTAssertEqual(field.defaultValue, .string("not_a_number"))
  }

  // MARK: - parseDefaultValue invalid: fixed32 with non-numeric string

  func test_bridge_fromProtobuf_defaultValue_fixed32_invalidString_fallsBackToString() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "val"
    fieldProto.number = 1
    fieldProto.type = .fixed32
    fieldProto.label = .optional
    fieldProto.defaultValue = "bad"

    let field = try bridge.fromProtobufFieldDescriptor(fieldProto, syntax: "proto2")
    XCTAssertEqual(field.defaultValue, .string("bad"))
  }

  // MARK: - findMapEntryMessage with nil parent (standalone fromProtobufFieldDescriptor)

  func test_bridge_fromProtobuf_repeatedMessageFieldWithoutContext_isNotMap() throws {
    // Calling the standalone overload means messageDescriptor is nil.
    // detectMapField → findMapEntryMessage(in: nil) → returns nil → isMap = false.
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "items"
    fieldProto.number = 1
    fieldProto.type = .message
    fieldProto.label = .repeated
    fieldProto.typeName = ".TestPackage.ItemEntry"

    let field = try bridge.fromProtobufFieldDescriptor(fieldProto)
    XCTAssertFalse(field.isMap)
    XCTAssertTrue(field.isRepeated)
    XCTAssertEqual(field.typeName, ".TestPackage.ItemEntry")
  }

  // MARK: - fromProtobufFileDescriptor without syntax (hasSyntax = false)

  func test_bridge_fromProtobufFileDescriptor_withoutSyntax_defaultsToProto2() throws {
    var fileProto = Google_Protobuf_FileDescriptorProto()
    fileProto.name = "no_syntax.proto"
    fileProto.package = "test"
    // Do NOT set fileProto.syntax — hasSyntax will be false.
    // _FileDescriptor defaults empty syntax to "proto2".

    let fileDesc = try bridge.fromProtobufFileDescriptor(fileProto)
    XCTAssertEqual(fileDesc.name, "no_syntax.proto")
    XCTAssertEqual(fileDesc.syntax, "proto2")
  }

  // MARK: - fromProtobufFileDescriptor without package (hasPackage = false)

  func test_bridge_fromProtobufFileDescriptor_withoutPackage_usesEmptyString() throws {
    var fileProto = Google_Protobuf_FileDescriptorProto()
    fileProto.name = "no_package.proto"
    // Do NOT set fileProto.package — hasPackage will be false

    let fileDesc = try bridge.fromProtobufFileDescriptor(fileProto)
    XCTAssertEqual(fileDesc.name, "no_package.proto")
    XCTAssertEqual(fileDesc.package, "")
  }

  // MARK: - toProtobufFileDescriptor with empty package omits proto.package

  func test_bridge_toProtobufFileDescriptor_emptyPackage_omitsPackageField() throws {
    let fileDesc = FileDescriptor(name: "empty_pkg.proto", package: "")

    let proto = try bridge.toProtobufFileDescriptor(from: fileDesc)
    XCTAssertEqual(proto.name, "empty_pkg.proto")
    XCTAssertFalse(proto.hasPackage)
  }

  // MARK: - Binary compliance: sint32 matches SwiftProtobuf output

  func test_bridge_binaryComplianceSint32_matchesSwiftProtobuf() throws {
    let descriptor = makeScalarDescriptor(name: "sint32_val", number: 7, type: .sint32)
    var msg = DynamicMessage(descriptor: descriptor)
    try msg.set(Int32(-1), forField: "sint32_val")

    let dynamicBytes = try BinarySerializer().serialize(msg)

    var staticMsg = Testcompat_ScalarMessage()
    staticMsg.sint32Field = -1
    let staticBytes = try staticMsg.serializedData()

    let fieldBytesFromDynamic = extractFieldBytes(number: 7, from: dynamicBytes)
    let fieldBytesFromStatic = extractFieldBytes(number: 7, from: staticBytes)
    XCTAssertEqual(fieldBytesFromDynamic, fieldBytesFromStatic, "sint32 binary encoding mismatch")
  }

  func test_bridge_binaryComplianceSint32_positiveValue_matchesSwiftProtobuf() throws {
    let descriptor = makeScalarDescriptor(name: "sint32_val", number: 7, type: .sint32)
    var msg = DynamicMessage(descriptor: descriptor)
    try msg.set(Int32(42), forField: "sint32_val")

    let dynamicBytes = try BinarySerializer().serialize(msg)

    var staticMsg = Testcompat_ScalarMessage()
    staticMsg.sint32Field = 42
    let staticBytes = try staticMsg.serializedData()

    let fieldBytesFromDynamic = extractFieldBytes(number: 7, from: dynamicBytes)
    let fieldBytesFromStatic = extractFieldBytes(number: 7, from: staticBytes)
    XCTAssertEqual(fieldBytesFromDynamic, fieldBytesFromStatic, "sint32 positive binary encoding mismatch")
  }

  // MARK: - Binary compliance: sfixed32 matches SwiftProtobuf output

  func test_bridge_binaryComplianceSfixed32_matchesSwiftProtobuf() throws {
    let descriptor = makeScalarDescriptor(name: "sfixed32_val", number: 11, type: .sfixed32)
    var msg = DynamicMessage(descriptor: descriptor)
    try msg.set(Int32(-100), forField: "sfixed32_val")

    let dynamicBytes = try BinarySerializer().serialize(msg)

    var staticMsg = Testcompat_ScalarMessage()
    staticMsg.sfixed32Field = -100
    let staticBytes = try staticMsg.serializedData()

    let fieldBytesFromDynamic = extractFieldBytes(number: 11, from: dynamicBytes)
    let fieldBytesFromStatic = extractFieldBytes(number: 11, from: staticBytes)
    XCTAssertEqual(fieldBytesFromDynamic, fieldBytesFromStatic, "sfixed32 binary encoding mismatch")
  }

  // MARK: - Binary compliance: fixed32 matches SwiftProtobuf output

  func test_bridge_binaryComplianceFixed32_matchesSwiftProtobuf() throws {
    let descriptor = makeScalarDescriptor(name: "fixed32_val", number: 9, type: .fixed32)
    var msg = DynamicMessage(descriptor: descriptor)
    try msg.set(UInt32(300), forField: "fixed32_val")

    let dynamicBytes = try BinarySerializer().serialize(msg)

    var staticMsg = Testcompat_ScalarMessage()
    staticMsg.fixed32Field = 300
    let staticBytes = try staticMsg.serializedData()

    let fieldBytesFromDynamic = extractFieldBytes(number: 9, from: dynamicBytes)
    let fieldBytesFromStatic = extractFieldBytes(number: 9, from: staticBytes)
    XCTAssertEqual(fieldBytesFromDynamic, fieldBytesFromStatic, "fixed32 binary encoding mismatch")
  }

  // MARK: - Binary compliance: sfixed64 matches SwiftProtobuf output

  func test_bridge_binaryComplianceSfixed64_matchesSwiftProtobuf() throws {
    let descriptor = makeScalarDescriptor(name: "sfixed64_val", number: 12, type: .sfixed64)
    var msg = DynamicMessage(descriptor: descriptor)
    try msg.set(Int64(-999), forField: "sfixed64_val")

    let dynamicBytes = try BinarySerializer().serialize(msg)

    var staticMsg = Testcompat_ScalarMessage()
    staticMsg.sfixed64Field = -999
    let staticBytes = try staticMsg.serializedData()

    let fieldBytesFromDynamic = extractFieldBytes(number: 12, from: dynamicBytes)
    let fieldBytesFromStatic = extractFieldBytes(number: 12, from: staticBytes)
    XCTAssertEqual(fieldBytesFromDynamic, fieldBytesFromStatic, "sfixed64 binary encoding mismatch")
  }

  // MARK: - Binary compliance: fixed64 matches SwiftProtobuf output

  func test_bridge_binaryComplianceFixed64_matchesSwiftProtobuf() throws {
    let descriptor = makeScalarDescriptor(name: "fixed64_val", number: 10, type: .fixed64)
    var msg = DynamicMessage(descriptor: descriptor)
    try msg.set(UInt64(1_000_000), forField: "fixed64_val")

    let dynamicBytes = try BinarySerializer().serialize(msg)

    var staticMsg = Testcompat_ScalarMessage()
    staticMsg.fixed64Field = 1_000_000
    let staticBytes = try staticMsg.serializedData()

    let fieldBytesFromDynamic = extractFieldBytes(number: 10, from: dynamicBytes)
    let fieldBytesFromStatic = extractFieldBytes(number: 10, from: staticBytes)
    XCTAssertEqual(fieldBytesFromDynamic, fieldBytesFromStatic, "fixed64 binary encoding mismatch")
  }

  // MARK: - Bridge round-trip for all 6 special numeric types

  func test_bridge_roundTrip_sint32FieldPreservesType() throws {
    let fieldDesc = FieldDescriptor(name: "val", number: 7, type: .sint32)
    let proto = try bridge.toProtobufFieldDescriptor(from: fieldDesc)
    XCTAssertEqual(proto.type, .sint32)
    let back = try bridge.fromProtobufFieldDescriptor(proto)
    XCTAssertEqual(back.type, .sint32)
    XCTAssertEqual(back.name, "val")
    XCTAssertEqual(back.number, 7)
  }

  func test_bridge_roundTrip_sfixed32FieldPreservesType() throws {
    let fieldDesc = FieldDescriptor(name: "val", number: 11, type: .sfixed32)
    let proto = try bridge.toProtobufFieldDescriptor(from: fieldDesc)
    XCTAssertEqual(proto.type, .sfixed32)
    let back = try bridge.fromProtobufFieldDescriptor(proto)
    XCTAssertEqual(back.type, .sfixed32)
  }

  func test_bridge_roundTrip_fixed32FieldPreservesType() throws {
    let fieldDesc = FieldDescriptor(name: "val", number: 9, type: .fixed32)
    let proto = try bridge.toProtobufFieldDescriptor(from: fieldDesc)
    XCTAssertEqual(proto.type, .fixed32)
    let back = try bridge.fromProtobufFieldDescriptor(proto)
    XCTAssertEqual(back.type, .fixed32)
  }

  func test_bridge_roundTrip_sint64FieldPreservesType() throws {
    let fieldDesc = FieldDescriptor(name: "val", number: 8, type: .sint64)
    let proto = try bridge.toProtobufFieldDescriptor(from: fieldDesc)
    XCTAssertEqual(proto.type, .sint64)
    let back = try bridge.fromProtobufFieldDescriptor(proto)
    XCTAssertEqual(back.type, .sint64)
  }

  func test_bridge_roundTrip_sfixed64FieldPreservesType() throws {
    let fieldDesc = FieldDescriptor(name: "val", number: 12, type: .sfixed64)
    let proto = try bridge.toProtobufFieldDescriptor(from: fieldDesc)
    XCTAssertEqual(proto.type, .sfixed64)
    let back = try bridge.fromProtobufFieldDescriptor(proto)
    XCTAssertEqual(back.type, .sfixed64)
  }

  func test_bridge_roundTrip_fixed64FieldPreservesType() throws {
    let fieldDesc = FieldDescriptor(name: "val", number: 10, type: .fixed64)
    let proto = try bridge.toProtobufFieldDescriptor(from: fieldDesc)
    XCTAssertEqual(proto.type, .fixed64)
    let back = try bridge.fromProtobufFieldDescriptor(proto)
    XCTAssertEqual(back.type, .fixed64)
  }

  // MARK: - DescriptorBridgeError descriptions

  func test_descriptorBridgeError_allCasesHaveDescriptions() {
    let errors: [DescriptorBridgeError] = [
      .unsupportedFieldType(99),
      .conversionFailed("details"),
      .missingRequiredField("myField"),
      .invalidDescriptorStructure("bad"),
    ]
    for error in errors {
      XCTAssertNotNil(error.errorDescription)
      XCTAssertFalse(error.errorDescription!.isEmpty)
    }
  }

  // MARK: - Helpers

  private func makeScalarDescriptor(name: String, number: Int, type: SwiftProtoReflect.FieldType) -> MessageDescriptor {
    var file = FileDescriptor(name: "scalar_types.proto", package: "testcompat")
    var desc = MessageDescriptor(name: "ScalarMessage", parent: file)
    desc.addField(
      FieldDescriptor(
        name: name,
        number: number,
        type: type,
        jsonName: name
      )
    )
    file.addMessage(desc)
    return file.messages["ScalarMessage"]!
  }

  /// Extracts the raw bytes for a specific field number from serialized proto bytes.
  ///
  /// Handles both varint and fixed-width wire types.
  private func extractFieldBytes(number: Int, from data: Data) -> Data? {
    var index = data.startIndex
    while index < data.endIndex {
      let tagStart = index
      guard let (tag, tagLen) = decodeVarint(data, at: index) else { return nil }
      index = data.index(index, offsetBy: tagLen)
      let fieldNumber = Int(tag >> 3)
      let wireType = Int(tag & 0x7)
      if fieldNumber == number {
        let fieldStart = tagStart
        switch wireType {
        case 0:
          guard let (_, vlen) = decodeVarint(data, at: index) else { return nil }
          let end = data.index(index, offsetBy: vlen)
          return Data(data[fieldStart..<end])
        case 1:
          let end = data.index(index, offsetBy: 8)
          return Data(data[fieldStart..<end])
        case 2:
          guard let (length, llen) = decodeVarint(data, at: index) else { return nil }
          let afterLen = data.index(index, offsetBy: llen)
          let end = data.index(afterLen, offsetBy: Int(length))
          return Data(data[fieldStart..<end])
        case 5:
          let end = data.index(index, offsetBy: 4)
          return Data(data[fieldStart..<end])
        default:
          return nil
        }
      }
      else {
        switch wireType {
        case 0:
          guard let (_, vlen) = decodeVarint(data, at: index) else { return nil }
          index = data.index(index, offsetBy: vlen)
        case 1:
          index = data.index(index, offsetBy: 8)
        case 2:
          guard let (length, llen) = decodeVarint(data, at: index) else { return nil }
          let afterLen = data.index(index, offsetBy: llen)
          index = data.index(afterLen, offsetBy: Int(length))
        case 5:
          index = data.index(index, offsetBy: 4)
        default:
          return nil
        }
      }
    }
    return nil
  }

  private func decodeVarint(_ data: Data, at start: Data.Index) -> (UInt64, Int)? {
    var value: UInt64 = 0
    var shift: UInt64 = 0
    var i = start
    while i < data.endIndex {
      let byte = data[i]
      value |= UInt64(byte & 0x7F) << shift
      shift += 7
      i = data.index(after: i)
      if byte & 0x80 == 0 {
        return (value, data.distance(from: start, to: i))
      }
    }
    return nil
  }
}
