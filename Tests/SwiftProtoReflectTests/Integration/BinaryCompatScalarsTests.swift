// BinaryCompatScalarsTests.swift
// SwiftProtoReflectTests
//
// Group 1: All proto3 scalar types — bidirectional binary compatibility tests.
//
// Oracle strategy: Option A — swift-protobuf generated types (.pb.swift).
//
// Pattern (mirrors JSON compat tests):
//   Direction A (oracle → us):
//     1. Build Testcompat_<Type> (generated), call serializedData() → referenceData.
//     2. Deserialize referenceData via BinaryDeserializer + CompatDescriptors → DynamicMessage.
//     3. Assert field values on DynamicMessage.
//   Direction B (us → oracle):
//     1. Build DynamicMessage via CompatDescriptors, call BinarySerializer.serialize() → ourData.
//     2. Parse ourData via Testcompat_<Type>(serializedBytes:) → generated message.
//     3. Assert field values on generated message.
//
// Map fields: byte-for-byte comparison is unreliable due to non-deterministic iteration order.
// Use round-trip-then-compare-values pattern instead (see test_scalars_map* tests if applicable).

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class BinaryCompatScalarsTests: XCTestCase {

  private var registry: TypeRegistry!
  private let serializer = BinaryCompatHelpers.makeSerializer()

  override func setUp() async throws {
    try await super.setUp()
    registry = try? await CompatDescriptors.fullRegistry()
  }

  override func tearDown() async throws {
    registry = nil
    try await super.tearDown()
  }

  // MARK: - All 15 scalar types set to non-zero values

  func test_scalars_allTypes_nonZeroValues_bidirectional() async throws {
    let desc = CompatDescriptors.scalarMessage()

    var proto = Testcompat_ScalarMessage()
    proto.doubleField = 1.5
    proto.floatField = 2.5
    proto.int32Field = 300
    proto.int64Field = 400
    proto.uint32Field = 500
    proto.uint64Field = 600
    proto.sint32Field = -7
    proto.sint64Field = -8
    proto.fixed32Field = 900
    proto.fixed64Field = 1000
    proto.sfixed32Field = -11
    proto.sfixed64Field = -12
    proto.boolField = true
    proto.stringField = "hello"
    proto.bytesField = Data([0x01, 0x02, 0x03])

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { dynamic in
        XCTAssertEqual(try dynamic.get(forField: 1) as? Double, 1.5)
        XCTAssertEqual(try dynamic.get(forField: 2) as? Float, 2.5)
        XCTAssertEqual(try dynamic.get(forField: 3) as? Int32, 300)
        XCTAssertEqual(try dynamic.get(forField: 4) as? Int64, 400)
        XCTAssertEqual(try dynamic.get(forField: 5) as? UInt32, 500)
        XCTAssertEqual(try dynamic.get(forField: 6) as? UInt64, 600)
        XCTAssertEqual(try dynamic.get(forField: 7) as? Int32, -7)
        XCTAssertEqual(try dynamic.get(forField: 8) as? Int64, -8)
        XCTAssertEqual(try dynamic.get(forField: 9) as? UInt32, 900)
        XCTAssertEqual(try dynamic.get(forField: 10) as? UInt64, 1000)
        XCTAssertEqual(try dynamic.get(forField: 11) as? Int32, -11)
        XCTAssertEqual(try dynamic.get(forField: 12) as? Int64, -12)
        XCTAssertEqual(try dynamic.get(forField: 13) as? Bool, true)
        XCTAssertEqual(try dynamic.get(forField: 14) as? String, "hello")
        XCTAssertEqual(try dynamic.get(forField: 15) as? Data, Data([0x01, 0x02, 0x03]))
      },
      buildDynamic: {
        var dynamic = DynamicMessage(descriptor: desc)
        try dynamic.set(Double(1.5), forField: 1)
        try dynamic.set(Float(2.5), forField: 2)
        try dynamic.set(Int32(300), forField: 3)
        try dynamic.set(Int64(400), forField: 4)
        try dynamic.set(UInt32(500), forField: 5)
        try dynamic.set(UInt64(600), forField: 6)
        try dynamic.set(Int32(-7), forField: 7)
        try dynamic.set(Int64(-8), forField: 8)
        try dynamic.set(UInt32(900), forField: 9)
        try dynamic.set(UInt64(1000), forField: 10)
        try dynamic.set(Int32(-11), forField: 11)
        try dynamic.set(Int64(-12), forField: 12)
        try dynamic.set(true, forField: 13)
        try dynamic.set("hello", forField: 14)
        try dynamic.set(Data([0x01, 0x02, 0x03]), forField: 15)
        return dynamic
      },
      validateProto: { p in
        XCTAssertEqual(p.doubleField, 1.5)
        XCTAssertEqual(p.floatField, 2.5)
        XCTAssertEqual(p.int32Field, 300)
        XCTAssertEqual(p.int64Field, 400)
        XCTAssertEqual(p.uint32Field, 500)
        XCTAssertEqual(p.uint64Field, 600)
        XCTAssertEqual(p.sint32Field, -7)
        XCTAssertEqual(p.sint64Field, -8)
        XCTAssertEqual(p.fixed32Field, 900)
        XCTAssertEqual(p.fixed64Field, 1000)
        XCTAssertEqual(p.sfixed32Field, -11)
        XCTAssertEqual(p.sfixed64Field, -12)
        XCTAssertEqual(p.boolField, true)
        XCTAssertEqual(p.stringField, "hello")
        XCTAssertEqual(p.bytesField, Data([0x01, 0x02, 0x03]))
      }
    )
  }

  // MARK: - Proto3 zero values are not serialized

  func test_scalars_proto3ZeroValues_notSerialized() async throws {
    let proto = Testcompat_ScalarMessage()
    let referenceData = try proto.serializedData()
    XCTAssertEqual(referenceData, Data(), "swift-protobuf must produce empty bytes for all-zero proto3 message")

    let desc = CompatDescriptors.scalarMessage()
    let dynamic = DynamicMessage(descriptor: desc)
    let ourData = try await serializer.serialize(dynamic)
    XCTAssertEqual(ourData, Data(), "BinarySerializer must produce empty bytes for all-zero proto3 message")
  }

  // MARK: - Varint boundary values

  func test_scalars_int32_varint150_correctEncoding() async throws {
    // Field 3, wire type 0 (varint): tag = 0x18; value 150 = 0x96 0x01
    let expected = Data([0x18, 0x96, 0x01])

    var proto = Testcompat_ScalarMessage()
    proto.int32Field = 150
    XCTAssertEqual(try proto.serializedData(), expected)

    let desc = CompatDescriptors.scalarMessage()
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(150), forField: 3)
    let _asyncResult21 = try await serializer.serialize(dynamic)
    XCTAssertEqual(_asyncResult21, expected)
  }

  func test_scalars_int32_maxValue_bidirectional() async throws {
    let desc = CompatDescriptors.scalarMessage()
    var proto = Testcompat_ScalarMessage()
    proto.int32Field = Int32.max

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { XCTAssertEqual(try $0.get(forField: 3) as? Int32, Int32.max) },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32.max, forField: 3)
        return d
      },
      validateProto: { XCTAssertEqual($0.int32Field, Int32.max) }
    )
  }

  func test_scalars_int32_minValue_bidirectional() async throws {
    let desc = CompatDescriptors.scalarMessage()
    var proto = Testcompat_ScalarMessage()
    proto.int32Field = Int32.min

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { XCTAssertEqual(try $0.get(forField: 3) as? Int32, Int32.min) },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32.min, forField: 3)
        return d
      },
      validateProto: { XCTAssertEqual($0.int32Field, Int32.min) }
    )
  }

  func test_scalars_uint64_maxValue_bidirectional() async throws {
    let desc = CompatDescriptors.scalarMessage()
    var proto = Testcompat_ScalarMessage()
    proto.uint64Field = UInt64.max

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { XCTAssertEqual(try $0.get(forField: 6) as? UInt64, UInt64.max) },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(UInt64.max, forField: 6)
        return d
      },
      validateProto: { XCTAssertEqual($0.uint64Field, UInt64.max) }
    )
  }

  // MARK: - sint32/sint64 zigzag encoding

  func test_scalars_sint32_negativeValue_zigzagEncoding() async throws {
    // sint32 uses zigzag: -1 → 1, -2 → 3, 1 → 2, 2 → 4
    // Field 7, tag = (7 << 3) | 0 = 0x38; value -1 zigzag = 1 → 0x38 0x01
    let expected = Data([0x38, 0x01])

    var proto = Testcompat_ScalarMessage()
    proto.sint32Field = -1
    XCTAssertEqual(
      try proto.serializedData(),
      expected,
      "swift-protobuf: sint32 = -1 should zigzag-encode to varint 1"
    )

    let desc = CompatDescriptors.scalarMessage()
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(-1), forField: 7)
    let _asyncResult22 = try await serializer.serialize(dynamic)
    XCTAssertEqual(
      _asyncResult22,
      expected,
      "BinarySerializer: sint32 = -1 should zigzag-encode to varint 1"
    )
  }

  func test_scalars_sint64_largeNegativeValue_bidirectional() async throws {
    let desc = CompatDescriptors.scalarMessage()
    var proto = Testcompat_ScalarMessage()
    proto.sint64Field = Int64.min

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { XCTAssertEqual(try $0.get(forField: 8) as? Int64, Int64.min) },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int64.min, forField: 8)
        return d
      },
      validateProto: { XCTAssertEqual($0.sint64Field, Int64.min) }
    )
  }

  // MARK: - fixed32/fixed64/sfixed32/sfixed64 (little-endian fixed width)

  func test_scalars_fixed32_littleEndianEncoding() async throws {
    // fixed32 field 9: tag = (9 << 3) | 5 = 0x4D; value 1 = 0x01 0x00 0x00 0x00
    let expected = Data([0x4D, 0x01, 0x00, 0x00, 0x00])

    var proto = Testcompat_ScalarMessage()
    proto.fixed32Field = 1
    XCTAssertEqual(try proto.serializedData(), expected)

    let desc = CompatDescriptors.scalarMessage()
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(UInt32(1), forField: 9)
    let _asyncResult23 = try await serializer.serialize(dynamic)
    XCTAssertEqual(_asyncResult23, expected)
  }

  func test_scalars_fixed64_littleEndianEncoding() async throws {
    // fixed64 field 10: tag = (10 << 3) | 1 = 0x51; value 1 = 8 little-endian bytes
    let expected = Data([0x51, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])

    var proto = Testcompat_ScalarMessage()
    proto.fixed64Field = 1
    XCTAssertEqual(try proto.serializedData(), expected)

    let desc = CompatDescriptors.scalarMessage()
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(UInt64(1), forField: 10)
    let _asyncResult24 = try await serializer.serialize(dynamic)
    XCTAssertEqual(_asyncResult24, expected)
  }

  // MARK: - String encoding

  func test_scalars_string_utf8MultibyteCharacters_bidirectional() async throws {
    let desc = CompatDescriptors.scalarMessage()
    var proto = Testcompat_ScalarMessage()
    proto.stringField = "Привет 🌍"

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { XCTAssertEqual(try $0.get(forField: 14) as? String, "Привет 🌍") },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set("Привет 🌍", forField: 14)
        return d
      },
      validateProto: { XCTAssertEqual($0.stringField, "Привет 🌍") }
    )
  }

  // NOTE: swift-protobuf silently omits proto3 fields set to their default value
  // (e.g. stringField = "" → omitted). DynamicMessage stores the value when explicitly
  // set, so BinarySerializer includes the field tag + 0-length payload (2 bytes).
  // Both are valid proto3 wire representations; zero-length LEN field is legal per spec.
  // The unset case (field never touched) matches: both produce empty Data.
  func test_scalars_string_unset_notSerialized() async throws {
    let proto = Testcompat_ScalarMessage()
    XCTAssertEqual(try proto.serializedData(), Data())

    let desc = CompatDescriptors.scalarMessage()
    let dynamic = DynamicMessage(descriptor: desc)
    let _asyncResult25 = try await serializer.serialize(dynamic)
    XCTAssertEqual(_asyncResult25, Data())
  }

  // TODO: BinarySerializer bug — proto3 non-optional fields explicitly set to their default
  // value (0, false, "", Data()) must be omitted from the wire format, matching protoc and
  // swift-protobuf behaviour. Currently BinarySerializer writes the tag+zero-value bytes
  // because DynamicMessage.hasValue returns true for any stored value without checking
  // whether it equals the proto3 default for a non-optional field.
  // Fix: in BinarySerializer.encodeMessage, skip a field when all of the following hold:
  //   • message.descriptor.syntax == "proto3"
  //   • field is not repeated, not a map, not a message/group
  //   • field.isOptional == false && field.proto3Optional == false
  //   • stored value equals the proto3 scalar default (0 / false / "" / Data())
  func test_scalars_proto3NonOptional_defaultValues_mustBeOmitted() async throws {
    let desc = CompatDescriptors.scalarMessage()

    // Each sub-test: set one field to its proto3 default, expect empty wire output.
    // protoc and swift-protobuf both produce Data() in every case below.

    let cases: [(String, Int, Any)] = [
      ("double=0.0", 1, Double(0.0)),
      ("float=0.0", 2, Float(0.0)),
      ("int32=0", 3, Int32(0)),
      ("int64=0", 4, Int64(0)),
      ("uint32=0", 5, UInt32(0)),
      ("uint64=0", 6, UInt64(0)),
      ("sint32=0", 7, Int32(0)),
      ("sint64=0", 8, Int64(0)),
      ("fixed32=0", 9, UInt32(0)),
      ("fixed64=0", 10, UInt64(0)),
      ("sfixed32=0", 11, Int32(0)),
      ("sfixed64=0", 12, Int64(0)),
      ("bool=false", 13, false),
      ("string=\"\"", 14, ""),
      ("bytes=[]", 15, Data()),
    ]

    for (label, fieldNumber, value) in cases {
      var dynamic = DynamicMessage(descriptor: desc)
      try dynamic.set(value, forField: fieldNumber)
      let data = try await serializer.serialize(dynamic)
      XCTAssertEqual(
        data,
        Data(),
        "proto3 non-optional field \(label) set to default must produce empty wire output (protoc/swift-protobuf omit it)"
      )
    }
  }

  // MARK: - Bytes encoding

  func test_scalars_bytes_allByteValues_bidirectional() async throws {
    let allBytes = Data((0..<256).map { UInt8($0) })
    let desc = CompatDescriptors.scalarMessage()
    var proto = Testcompat_ScalarMessage()
    proto.bytesField = allBytes

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { XCTAssertEqual(try $0.get(forField: 15) as? Data, allBytes) },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(allBytes, forField: 15)
        return d
      },
      validateProto: { XCTAssertEqual($0.bytesField, allBytes) }
    )
  }

  // MARK: - double/float special values

  func test_scalars_double_infinity_bidirectional() async throws {
    let desc = CompatDescriptors.scalarMessage()
    var proto = Testcompat_ScalarMessage()
    proto.doubleField = Double.infinity

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { XCTAssertEqual(try $0.get(forField: 1) as? Double, Double.infinity) },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Double.infinity, forField: 1)
        return d
      },
      validateProto: { XCTAssertEqual($0.doubleField, Double.infinity) }
    )
  }

  func test_scalars_float_nan_bidirectional() async throws {
    let desc = CompatDescriptors.scalarMessage()
    var proto = Testcompat_ScalarMessage()
    proto.floatField = Float.nan

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { dynamic in
        let v = try XCTUnwrap(try dynamic.get(forField: 2) as? Float)
        XCTAssertTrue(v.isNaN)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Float.nan, forField: 2)
        return d
      },
      validateProto: { XCTAssertTrue($0.floatField.isNaN) }
    )
  }

  // MARK: - Proto3 optional scalar (explicit presence)

  func test_scalars_proto3Optional_zeroValuePresent_bidirectional() async throws {
    let desc = CompatDescriptors.optionalScalarMessage()

    var proto = Testcompat_OptionalScalarMessage()
    proto.optInt32 = 0  // optional field explicitly set to zero — must appear in wire format
    proto.optBool = false
    // plainInt32 left at default (0) — must NOT appear in wire format

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { dynamic in
        XCTAssertTrue(
          try dynamic.hasValue(forField: 3),
          "Optional int32 explicitly set to zero must be present"
        )
        XCTAssertEqual(try dynamic.get(forField: 3) as? Int32, 0)
        XCTAssertTrue(
          try dynamic.hasValue(forField: 13),
          "Optional bool explicitly set to false must be present"
        )
        XCTAssertEqual(try dynamic.get(forField: 13) as? Bool, false)
        XCTAssertFalse(
          try dynamic.hasValue(forField: 16),
          "Non-optional zero field must not appear in wire format"
        )
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(0), forField: 3)  // proto3Optional field: set stores even zero
        try d.set(false, forField: 13)
        return d
      },
      validateProto: { p in
        XCTAssertTrue(p.hasOptInt32, "optional int32 set to zero must have presence")
        XCTAssertEqual(p.optInt32, 0)
        XCTAssertTrue(p.hasOptBool, "optional bool set to false must have presence")
        XCTAssertEqual(p.optBool, false)
      }
    )
  }
}
