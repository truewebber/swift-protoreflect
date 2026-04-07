//
// StructProtoGoldenBytesTests.swift
// SwiftProtoReflect
//
// Golden-byte tests for google.protobuf.Value, Struct, and ListValue.
//
// Every byte sequence below is derived from the protobuf binary wire-format spec
// (https://protobuf.dev/programming-guides/encoding/) and cross-validated against
// SwiftProtobuf's generated types (which use protoc-compiled descriptors).
//
// For each case the test asserts THREE things:
//   1. SwiftProtobuf produces exactly those bytes   → confirms our spec derivation
//   2. Our BinarySerializer produces exactly those bytes → confirms our implementation
//   3. Our BinaryDeserializer correctly decodes those bytes → confirms our deserializer
//
// Wire-format reminder:
//   tag  = (field_number << 3) | wire_type
//   wire types: 0 = varint, 1 = 64-bit, 2 = LEN, 5 = 32-bit
//   double fields are encoded as 64-bit (LE IEEE 754).
//   enum fields inside a oneof are ALWAYS emitted, even when the value is 0.
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class StructProtoGoldenBytesTests: XCTestCase {

  private let serializer = BinarySerializer()
  private var deserializer: BinaryDeserializer!
  private var registry: TypeRegistry!

  override func setUp() async throws {
    registry = TypeRegistry()
    try await registry.registerFile(StructProtoDescriptors.fileDescriptor)
    deserializer = BinaryDeserializer(options: DeserializationOptions(typeRegistry: registry))
  }

  // MARK: - Value: null_value

  func test_golden_value_nullValue() async throws {
    // Field 1 (null_value, NullValue enum), varint wire type:
    //   tag  = (1 << 3) | 0 = 0x08
    //   value = NULL_VALUE(0) = 0x00
    // NOTE: null_value is inside a oneof, so it IS emitted even though the value is 0.
    let golden = Data([0x08, 0x00])

    var swiftpbValue = Google_Protobuf_Value()
    swiftpbValue.nullValue = .nullValue
    XCTAssertEqual(
      try swiftpbValue.serializedData(),
      golden,
      "SwiftProtobuf golden mismatch for null_value"
    )

    let dynMsg = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.nullValue)
    let _asyncResult1 = try serializer.serialize(dynMsg)
    XCTAssertEqual(
      _asyncResult1,
      golden,
      "Our serializer golden mismatch for null_value"
    )

    let decoded = try await deserializer.deserialize(golden, using: StructProtoDescriptors.valueDescriptor)
    let result = try XCTUnwrap(
      try ValueHandler.createSpecialized(from: decoded) as? ValueHandler.ValueValue
    )
    XCTAssertEqual(result, .nullValue)
  }

  // MARK: - Value: number_value

  func test_golden_value_numberValue_one() async throws {
    // Field 2 (number_value, double), 64-bit wire type:
    //   tag  = (2 << 3) | 1 = 0x11
    //   1.0  = 0x3FF0_0000_0000_0000 IEEE 754 LE
    //        = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0x3F]
    let golden = Data([0x11, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0x3F])

    var swiftpbValue = Google_Protobuf_Value()
    swiftpbValue.numberValue = 1.0
    XCTAssertEqual(
      try swiftpbValue.serializedData(),
      golden,
      "SwiftProtobuf golden mismatch for number_value=1.0"
    )

    let dynMsg = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.numberValue(1.0))
    let _asyncResult2 = try serializer.serialize(dynMsg)
    XCTAssertEqual(
      _asyncResult2,
      golden,
      "Our serializer golden mismatch for number_value=1.0"
    )

    let decoded = try await deserializer.deserialize(golden, using: StructProtoDescriptors.valueDescriptor)
    let result = try XCTUnwrap(
      try ValueHandler.createSpecialized(from: decoded) as? ValueHandler.ValueValue
    )
    XCTAssertEqual(result, .numberValue(1.0))
  }

  // MARK: - Value: string_value

  func test_golden_value_stringValue() async throws {
    // Field 3 (string_value, string), LEN wire type:
    //   tag  = (3 << 3) | 2 = 0x1A
    //   len  = 2 = 0x02
    //   "hi" = [0x68, 0x69]
    let golden = Data([0x1A, 0x02, 0x68, 0x69])

    var swiftpbValue = Google_Protobuf_Value()
    swiftpbValue.stringValue = "hi"
    XCTAssertEqual(
      try swiftpbValue.serializedData(),
      golden,
      "SwiftProtobuf golden mismatch for string_value='hi'"
    )

    let dynMsg = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.stringValue("hi"))
    let _asyncResult3 = try serializer.serialize(dynMsg)
    XCTAssertEqual(
      _asyncResult3,
      golden,
      "Our serializer golden mismatch for string_value='hi'"
    )

    let decoded = try await deserializer.deserialize(golden, using: StructProtoDescriptors.valueDescriptor)
    let result = try XCTUnwrap(
      try ValueHandler.createSpecialized(from: decoded) as? ValueHandler.ValueValue
    )
    XCTAssertEqual(result, .stringValue("hi"))
  }

  // MARK: - Value: bool_value = true

  func test_golden_value_boolValue_true() async throws {
    // Field 4 (bool_value, bool), varint wire type:
    //   tag  = (4 << 3) | 0 = 0x20
    //   true = 0x01
    let golden = Data([0x20, 0x01])

    var swiftpbValue = Google_Protobuf_Value()
    swiftpbValue.boolValue = true
    XCTAssertEqual(
      try swiftpbValue.serializedData(),
      golden,
      "SwiftProtobuf golden mismatch for bool_value=true"
    )

    let dynMsg = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.boolValue(true))
    let _asyncResult4 = try serializer.serialize(dynMsg)
    XCTAssertEqual(
      _asyncResult4,
      golden,
      "Our serializer golden mismatch for bool_value=true"
    )

    let decoded = try await deserializer.deserialize(golden, using: StructProtoDescriptors.valueDescriptor)
    let result = try XCTUnwrap(
      try ValueHandler.createSpecialized(from: decoded) as? ValueHandler.ValueValue
    )
    XCTAssertEqual(result, .boolValue(true))
  }

  // MARK: - Value: bool_value = false (critical oneof edge case)

  func test_golden_value_boolValue_false() async throws {
    // Field 4 (bool_value, bool), varint wire type:
    //   tag   = (4 << 3) | 0 = 0x20
    //   false = 0x00
    // KEY POINT: bool_value = false is inside a oneof, so it IS emitted even though
    // the value is the proto default (0). A regular proto3 bool=false would be omitted,
    // but oneof fields are always written when the oneof is set.
    let golden = Data([0x20, 0x00])

    var swiftpbValue = Google_Protobuf_Value()
    swiftpbValue.boolValue = false
    XCTAssertEqual(
      try swiftpbValue.serializedData(),
      golden,
      "SwiftProtobuf golden mismatch for bool_value=false (must be emitted inside oneof)"
    )

    let dynMsg = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.boolValue(false))
    let _asyncResult5 = try serializer.serialize(dynMsg)
    XCTAssertEqual(
      _asyncResult5,
      golden,
      "Our serializer golden mismatch for bool_value=false"
    )

    let decoded = try await deserializer.deserialize(golden, using: StructProtoDescriptors.valueDescriptor)
    let result = try XCTUnwrap(
      try ValueHandler.createSpecialized(from: decoded) as? ValueHandler.ValueValue
    )
    XCTAssertEqual(result, .boolValue(false))
  }

  // MARK: - ListValue

  func test_golden_listValue_singleEntry() async throws {
    // ListValue { values: [Value { string_value: "hi" }] }
    //
    // Value(string_value="hi") = [0x1A, 0x02, 0x68, 0x69]  (4 bytes)
    //
    // ListValue field 1 (values, repeated Value), LEN wire type:
    //   tag = (1 << 3) | 2 = 0x0A
    //   len = 4 = 0x04
    //   payload = [0x1A, 0x02, 0x68, 0x69]
    let golden = Data([0x0A, 0x04, 0x1A, 0x02, 0x68, 0x69])

    var swiftpbList = Google_Protobuf_ListValue()
    swiftpbList.values = [Google_Protobuf_Value(stringValue: "hi")]
    XCTAssertEqual(
      try swiftpbList.serializedData(),
      golden,
      "SwiftProtobuf golden mismatch for ListValue([string_value='hi'])"
    )

    let dynMsg = try ListValueHandler.createDynamic(from: [StructHandler.ValueValue.stringValue("hi")])
    let _asyncResult6 = try serializer.serialize(dynMsg)
    XCTAssertEqual(
      _asyncResult6,
      golden,
      "Our serializer golden mismatch for ListValue([string_value='hi'])"
    )

    let decoded = try await deserializer.deserialize(golden, using: StructProtoDescriptors.listValueDescriptor)
    let result = try XCTUnwrap(
      try ListValueHandler.createSpecialized(from: decoded) as? [StructHandler.ValueValue]
    )
    XCTAssertEqual(result, [.stringValue("hi")])
  }

  // MARK: - Struct

  func test_golden_struct_singleStringField() async throws {
    // Struct { fields: {"k": Value { string_value: "v" }} }
    //
    // Value(string_value="v"):
    //   tag  = (3 << 3) | 2 = 0x1A, len=1, "v"=0x76
    //   → [0x1A, 0x01, 0x76]                               (3 bytes)
    //
    // FieldsEntry { key: "k", value: Value(string_value="v") }:
    //   key   field 1, LEN:  tag=0x0A, len=1, "k"=0x6B → [0x0A, 0x01, 0x6B]
    //   value field 2, LEN:  tag=0x12, len=3, payload   → [0x12, 0x03, 0x1A, 0x01, 0x76]
    //   → [0x0A, 0x01, 0x6B, 0x12, 0x03, 0x1A, 0x01, 0x76] (8 bytes)
    //
    // Struct field 1 (fields, map), LEN wire type:
    //   tag = (1 << 3) | 2 = 0x0A, len=8
    //   → [0x0A, 0x08, 0x0A, 0x01, 0x6B, 0x12, 0x03, 0x1A, 0x01, 0x76]
    let golden = Data([0x0A, 0x08, 0x0A, 0x01, 0x6B, 0x12, 0x03, 0x1A, 0x01, 0x76])

    var swiftpbStruct = Google_Protobuf_Struct()
    swiftpbStruct.fields["k"] = Google_Protobuf_Value(stringValue: "v")
    XCTAssertEqual(
      try swiftpbStruct.serializedData(),
      golden,
      "SwiftProtobuf golden mismatch for Struct({k:string_value='v'})"
    )

    let sv = StructHandler.StructValue(fields: ["k": .stringValue("v")])
    let dynMsg = try StructHandler.createDynamic(from: sv)
    let _asyncResult7 = try serializer.serialize(dynMsg)
    XCTAssertEqual(
      _asyncResult7,
      golden,
      "Our serializer golden mismatch for Struct({k:string_value='v'})"
    )

    let decoded = try await deserializer.deserialize(golden, using: StructProtoDescriptors.structDescriptor)
    let result = try XCTUnwrap(
      try StructHandler.createSpecialized(from: decoded) as? StructHandler.StructValue
    )
    XCTAssertEqual(result.fields["k"], .stringValue("v"))
    XCTAssertEqual(result.fields.count, 1)
  }

  // MARK: - Value containing Struct (field 5)

  func test_golden_value_structValue() async throws {
    // Value { struct_value: Struct { fields: {"k": Value { string_value: "v" }} } }
    //
    // Struct bytes (from test above):
    //   [0x0A, 0x08, 0x0A, 0x01, 0x6B, 0x12, 0x03, 0x1A, 0x01, 0x76]  (10 bytes)
    //
    // Value field 5 (struct_value, Struct), LEN wire type:
    //   tag = (5 << 3) | 2 = 0x2A, len=10=0x0A
    let golden = Data([
      0x2A, 0x0A,
      0x0A, 0x08, 0x0A, 0x01, 0x6B, 0x12, 0x03, 0x1A, 0x01, 0x76,
    ])

    var innerStruct = Google_Protobuf_Struct()
    innerStruct.fields["k"] = Google_Protobuf_Value(stringValue: "v")
    var swiftpbValue = Google_Protobuf_Value()
    swiftpbValue.structValue = innerStruct
    XCTAssertEqual(
      try swiftpbValue.serializedData(),
      golden,
      "SwiftProtobuf golden mismatch for Value(struct_value)"
    )

    let libSv = StructHandler.StructValue(fields: ["k": .stringValue("v")])
    let dynMsg = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.structValue(libSv))
    let _asyncResult8 = try serializer.serialize(dynMsg)
    XCTAssertEqual(
      _asyncResult8,
      golden,
      "Our serializer golden mismatch for Value(struct_value)"
    )

    let decoded = try await deserializer.deserialize(golden, using: StructProtoDescriptors.valueDescriptor)
    let result = try XCTUnwrap(
      try ValueHandler.createSpecialized(from: decoded) as? ValueHandler.ValueValue
    )
    guard case .structValue(let sv) = result else {
      XCTFail("Expected structValue")
      return
    }
    XCTAssertEqual(sv.fields["k"], .stringValue("v"))
  }

  // MARK: - Value containing ListValue (field 6)

  func test_golden_value_listValue() async throws {
    // Value { list_value: ListValue { values: [Value { string_value: "hi" }] } }
    //
    // ListValue bytes (from test above):
    //   [0x0A, 0x04, 0x1A, 0x02, 0x68, 0x69]  (6 bytes)
    //
    // Value field 6 (list_value, ListValue), LEN wire type:
    //   tag = (6 << 3) | 2 = 0x32, len=6=0x06
    let golden = Data([0x32, 0x06, 0x0A, 0x04, 0x1A, 0x02, 0x68, 0x69])

    var innerList = Google_Protobuf_ListValue()
    innerList.values = [Google_Protobuf_Value(stringValue: "hi")]
    var swiftpbValue = Google_Protobuf_Value()
    swiftpbValue.listValue = innerList
    XCTAssertEqual(
      try swiftpbValue.serializedData(),
      golden,
      "SwiftProtobuf golden mismatch for Value(list_value)"
    )

    let dynMsg = try ValueHandler.createDynamic(from: ValueHandler.ValueValue.listValue([.stringValue("hi")]))
    let _asyncResult9 = try serializer.serialize(dynMsg)
    XCTAssertEqual(
      _asyncResult9,
      golden,
      "Our serializer golden mismatch for Value(list_value)"
    )

    let decoded = try await deserializer.deserialize(golden, using: StructProtoDescriptors.valueDescriptor)
    let result = try XCTUnwrap(
      try ValueHandler.createSpecialized(from: decoded) as? ValueHandler.ValueValue
    )
    guard case .listValue(let items) = result else {
      XCTFail("Expected listValue")
      return
    }
    XCTAssertEqual(items, [.stringValue("hi")])
  }
}
