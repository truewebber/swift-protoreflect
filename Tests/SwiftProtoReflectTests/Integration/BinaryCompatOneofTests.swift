// BinaryCompatOneofTests.swift
// SwiftProtoReflectTests
//
// Group: Oneof Fields — bidirectional binary compatibility tests.
//
// Oracle strategy: Option A — swift-protobuf generated types (.pb.swift).
//
// Pattern (mirrors BinaryCompatScalarsTests):
//   Direction A (oracle → us):
//     1. Build Testcompat_<Type> (generated), call serializedData() → referenceData.
//     2. Deserialize referenceData via BinaryDeserializer + CompatDescriptors → DynamicMessage.
//     3. Assert field values on DynamicMessage.
//   Direction B (us → oracle):
//     1. Build DynamicMessage via CompatDescriptors, call BinarySerializer.serialize() → ourData.
//     2. Parse ourData via Testcompat_<Type>(serializedBytes:) → generated message.
//     3. Assert field values on generated message.
//
// Binary-specific notes for oneof:
//   - Unset oneof produces no wire bytes at all.
//   - Last-field-wins: when multiple oneof-member fields appear in binary, the last one wins.
//   - double/float use wire type 1/5 (fixed-width 8/4 bytes) — same applies inside oneof.
//   - int32/int64/uint32/uint64/bool/enum use wire type 0 (varint) — standard, NOT zigzag.
//   - string/bytes/message use wire type 2 (LEN).
//   - int32 = -1 encodes as 10-byte 2's-complement varint, not 1-byte zigzag.

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class BinaryCompatOneofTests: XCTestCase {

  private var registry: TypeRegistry!

  override func setUp() {
    super.setUp()
    registry = try? CompatDescriptors.fullRegistry()
  }

  override func tearDown() {
    registry = nil
    super.tearDown()
  }

  // MARK: - 1. doubleVal variant: 3.14 as 8-byte fixed-width IEEE 754

  func test_oneof_scalars_double_bidirectional() throws {
    var proto = Testcompat_OneofScalars()
    proto.doubleVal = 3.14

    let desc = CompatDescriptors.oneofScalars()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? Double, 3.14)
        XCTAssertNil(try msg.get(forField: 3) as? Int32)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Double(3.14), forField: 1)
        return d
      },
      validateProto: { p in
        if case .doubleVal(let v) = p.value {
          XCTAssertEqual(v, 3.14)
        }
        else {
          XCTFail("expected doubleVal case")
        }
      }
    )
  }

  // MARK: - 2. int32Val variant: -42 as varint

  func test_oneof_scalars_int32_bidirectional() throws {
    var proto = Testcompat_OneofScalars()
    proto.int32Val = -42

    let desc = CompatDescriptors.oneofScalars()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 3) as? Int32, -42)
        XCTAssertNil(try msg.get(forField: 1) as? Double)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(-42), forField: 3)
        return d
      },
      validateProto: { p in
        if case .int32Val(let v) = p.value {
          XCTAssertEqual(v, -42)
        }
        else {
          XCTFail("expected int32Val case")
        }
      }
    )
  }

  // MARK: - 3. stringVal variant: "hello world" as length-delimited

  func test_oneof_scalars_string_bidirectional() throws {
    var proto = Testcompat_OneofScalars()
    proto.stringVal = "hello world"

    let desc = CompatDescriptors.oneofScalars()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 8) as? String, "hello world")
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set("hello world", forField: 8)
        return d
      },
      validateProto: { p in
        if case .stringVal(let v) = p.value {
          XCTAssertEqual(v, "hello world")
        }
        else {
          XCTFail("expected stringVal case")
        }
      }
    )
  }

  // MARK: - 4. bytesVal variant: Data([0xDE,0xAD,0xBE,0xEF]) as length-delimited

  func test_oneof_scalars_bytes_bidirectional() throws {
    let testBytes = Data([0xDE, 0xAD, 0xBE, 0xEF])
    var proto = Testcompat_OneofScalars()
    proto.bytesVal = testBytes

    let desc = CompatDescriptors.oneofScalars()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 9) as? Data, testBytes)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(testBytes, forField: 9)
        return d
      },
      validateProto: { p in
        if case .bytesVal(let v) = p.value {
          XCTAssertEqual(v, testBytes)
        }
        else {
          XCTFail("expected bytesVal case")
        }
      }
    )
  }

  // MARK: - 5. boolVal variant: true as varint 1

  func test_oneof_scalars_bool_bidirectional() throws {
    var proto = Testcompat_OneofScalars()
    proto.boolVal = true

    let desc = CompatDescriptors.oneofScalars()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 7) as? Bool, true)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(true, forField: 7)
        return d
      },
      validateProto: { p in
        if case .boolVal(let v) = p.value {
          XCTAssertTrue(v)
        }
        else {
          XCTFail("expected boolVal case")
        }
      }
    )
  }

  // MARK: - 6. Unset oneof: no variants set → empty Data

  func test_oneof_unset_producesNoWireBytes() throws {
    let desc = CompatDescriptors.oneofScalars()

    // Direction A: oracle serializes empty message → empty bytes → our deserializer
    let emptyProto = Testcompat_OneofScalars()
    let referenceData = try emptyProto.serializedData()
    XCTAssertEqual(referenceData, Data(), "oracle empty oneof message should produce no wire bytes")

    let deserialized = try BinaryCompatHelpers.makeDeserializer(registry: registry)
      .deserialize(referenceData, using: desc)
    XCTAssertNil(try deserialized.get(forField: 1) as? Double)
    XCTAssertNil(try deserialized.get(forField: 3) as? Int32)
    XCTAssertNil(try deserialized.get(forField: 8) as? String)

    // Direction B: empty DynamicMessage → our serializer → should produce empty bytes
    let emptyDynamic = DynamicMessage(descriptor: desc)
    let ourData = try BinaryCompatHelpers.makeSerializer().serialize(emptyDynamic)
    XCTAssertEqual(ourData, Data(), "unset oneof DynamicMessage should produce no wire bytes")
  }

  // MARK: - 7. msgVal variant: nested ScalarMessage (int32Field=99, stringField="inner")

  func test_oneof_complex_message_bidirectional() throws {
    var inner = Testcompat_ScalarMessage()
    inner.int32Field = 99
    inner.stringField = "inner"
    var proto = Testcompat_OneofComplex()
    proto.msgVal = inner

    let desc = CompatDescriptors.oneofComplex()
    let innerDesc = CompatDescriptors.scalarMessage()

    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let innerMsg = try XCTUnwrap(try msg.get(forField: 3) as? DynamicMessage)
        XCTAssertEqual(try innerMsg.get(forField: 3) as? Int32, 99)
        XCTAssertEqual(try innerMsg.get(forField: 14) as? String, "inner")
      },
      buildDynamic: {
        var innerDyn = DynamicMessage(descriptor: innerDesc)
        try innerDyn.set(Int32(99), forField: 3)
        try innerDyn.set("inner", forField: 14)
        var d = DynamicMessage(descriptor: desc)
        try d.set(innerDyn, forField: 3)
        return d
      },
      validateProto: { p in
        if case .msgVal(let m) = p.choice {
          XCTAssertEqual(m.int32Field, 99)
          XCTAssertEqual(m.stringField, "inner")
        }
        else {
          XCTFail("expected msgVal case")
        }
      }
    )
  }

  // MARK: - 8. enumVal variant: ACTIVE=1 as varint

  func test_oneof_complex_enum_bidirectional() throws {
    var proto = Testcompat_OneofComplex()
    proto.enumVal = .active

    let desc = CompatDescriptors.oneofComplex()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 5) as? Int32, 1)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(1), forField: 5)
        return d
      },
      validateProto: { p in
        if case .enumVal(let v) = p.choice {
          XCTAssertEqual(v, .active)
        }
        else {
          XCTFail("expected enumVal case")
        }
      }
    )
  }

  // MARK: - 9. intVal in oneof + name regular field both present

  func test_oneof_complex_regularFieldWithOneof_bidirectional() throws {
    var proto = Testcompat_OneofComplex()
    proto.intVal = 7
    proto.name = "outside"

    let desc = CompatDescriptors.oneofComplex()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? Int32, 7)
        XCTAssertEqual(try msg.get(forField: 10) as? String, "outside")
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(7), forField: 1)
        try d.set("outside", forField: 10)
        return d
      },
      validateProto: { p in
        if case .intVal(let v) = p.choice {
          XCTAssertEqual(v, 7)
        }
        else {
          XCTFail("expected intVal case")
        }
        XCTAssertEqual(p.name, "outside")
      }
    )
  }

  // MARK: - 10. MultiOneof: firstInt set + label regular field

  func test_multiOneof_firstChoice_bidirectional() throws {
    var proto = Testcompat_MultiOneof()
    proto.firstInt = 42
    proto.label = "lbl"

    let desc = CompatDescriptors.multiOneof()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? Int32, 42)
        XCTAssertEqual(try msg.get(forField: 20) as? String, "lbl")
        XCTAssertNil(try msg.get(forField: 4) as? Double)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(42), forField: 1)
        try d.set("lbl", forField: 20)
        return d
      },
      validateProto: { p in
        if case .firstInt(let v) = p.firstChoice {
          XCTAssertEqual(v, 42)
        }
        else {
          XCTFail("expected firstInt case")
        }
        XCTAssertEqual(p.label, "lbl")
      }
    )
  }

  // MARK: - 11. MultiOneof: secondDbl = 2.71 (8-byte fixed)

  func test_multiOneof_secondChoice_bidirectional() throws {
    var proto = Testcompat_MultiOneof()
    proto.secondDbl = 2.71

    let desc = CompatDescriptors.multiOneof()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 4) as? Double, 2.71)
        XCTAssertNil(try msg.get(forField: 1) as? Int32)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Double(2.71), forField: 4)
        return d
      },
      validateProto: { p in
        if case .secondDbl(let v) = p.secondChoice {
          XCTAssertEqual(v, 2.71)
        }
        else {
          XCTFail("expected secondDbl case")
        }
      }
    )
  }

  // MARK: - 12. int64Val variant: Int64.max as varint

  func test_oneof_scalars_int64_bidirectional() throws {
    var proto = Testcompat_OneofScalars()
    proto.int64Val = Int64.max

    let desc = CompatDescriptors.oneofScalars()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 4) as? Int64, Int64.max)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int64.max, forField: 4)
        return d
      },
      validateProto: { p in
        if case .int64Val(let v) = p.value {
          XCTAssertEqual(v, Int64.max)
        }
        else {
          XCTFail("expected int64Val case")
        }
      }
    )
  }

  // MARK: - 13. floatVal variant: 1.5 as 4-byte fixed-width IEEE 754

  func test_oneof_scalars_float_bidirectional() throws {
    var proto = Testcompat_OneofScalars()
    proto.floatVal = 1.5

    let desc = CompatDescriptors.oneofScalars()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 2) as? Float, 1.5)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Float(1.5), forField: 2)
        return d
      },
      validateProto: { p in
        if case .floatVal(let v) = p.value {
          XCTAssertEqual(v, 1.5)
        }
        else {
          XCTFail("expected floatVal case")
        }
      }
    )
  }

  // MARK: - 14. uint32Val variant: UInt32.max as varint

  func test_oneof_scalars_uint32_bidirectional() throws {
    var proto = Testcompat_OneofScalars()
    proto.uint32Val = UInt32.max

    let desc = CompatDescriptors.oneofScalars()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 5) as? UInt32, UInt32.max)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(UInt32.max, forField: 5)
        return d
      },
      validateProto: { p in
        if case .uint32Val(let v) = p.value {
          XCTAssertEqual(v, UInt32.max)
        }
        else {
          XCTFail("expected uint32Val case")
        }
      }
    )
  }

  // MARK: - 15. uint64Val variant: UInt64.max as varint

  func test_oneof_scalars_uint64_bidirectional() throws {
    var proto = Testcompat_OneofScalars()
    proto.uint64Val = UInt64.max

    let desc = CompatDescriptors.oneofScalars()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 6) as? UInt64, UInt64.max)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(UInt64.max, forField: 6)
        return d
      },
      validateProto: { p in
        if case .uint64Val(let v) = p.value {
          XCTAssertEqual(v, UInt64.max)
        }
        else {
          XCTFail("expected uint64Val case")
        }
      }
    )
  }

  // MARK: - 16. OneofWKT: tsVal variant with Timestamp (seconds=1_700_000_000) + tag int field

  func test_oneof_wkt_timestamp_bidirectional() throws {
    var proto = Testcompat_OneofWKT()
    proto.tsVal.seconds = 1_700_000_000
    proto.tsVal.nanos = 0
    proto.tag = 5

    let desc = CompatDescriptors.oneofWKT()
    let tsDesc = CompatDescriptors.wktTimestamp()

    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let tsDyn = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
        XCTAssertEqual(try tsDyn.get(forField: 1) as? Int64, 1_700_000_000)
        XCTAssertEqual(try msg.get(forField: 10) as? Int32, 5)
      },
      buildDynamic: {
        var tsDyn = DynamicMessage(descriptor: tsDesc)
        try tsDyn.set(Int64(1_700_000_000), forField: 1)
        var d = DynamicMessage(descriptor: desc)
        try d.set(tsDyn, forField: 1)
        try d.set(Int32(5), forField: 10)
        return d
      },
      validateProto: { p in
        if case .tsVal(let ts) = p.wktChoice {
          XCTAssertEqual(ts.seconds, 1_700_000_000)
        }
        else {
          XCTFail("expected tsVal case")
        }
        XCTAssertEqual(p.tag, 5)
      }
    )
  }

  // MARK: - 17. OneofWKT: structVal variant (empty Struct message in oneof)

  func test_oneof_wkt_struct_bidirectional() throws {
    var proto = Testcompat_OneofWKT()
    proto.structVal = Google_Protobuf_Struct()

    let desc = CompatDescriptors.oneofWKT()
    let structDesc = CompatDescriptors.wktStruct()

    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let structDyn = try XCTUnwrap(try msg.get(forField: 4) as? DynamicMessage)
        XCTAssertEqual(structDyn.descriptor.name, "Struct")
      },
      buildDynamic: {
        let structDyn = DynamicMessage(descriptor: structDesc)
        var d = DynamicMessage(descriptor: desc)
        try d.set(structDyn, forField: 4)
        return d
      },
      validateProto: { p in
        if case .structVal = p.wktChoice {
          // Correct case — empty Struct in oneof
        }
        else {
          XCTFail("expected structVal case")
        }
      }
    )
  }

  // MARK: - 18. MultiOneof with all 3 oneofs active + label: firstStr, secondEnum, thirdMsg

  func test_multiOneof_allActive_bidirectional() throws {
    var proto = Testcompat_MultiOneof()
    proto.firstStr = "first"
    proto.secondEnum = .active
    var simpleMsg = Testcompat_SimpleMessage()
    simpleMsg.id = 7
    proto.thirdMsg = simpleMsg
    proto.label = "all"

    let desc = CompatDescriptors.multiOneof()
    let simpleDesc = CompatDescriptors.simpleMessage()

    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 2) as? String, "first")
        XCTAssertEqual(try msg.get(forField: 6) as? Int32, 1)
        let thirdMsg = try XCTUnwrap(try msg.get(forField: 7) as? DynamicMessage)
        XCTAssertEqual(try thirdMsg.get(forField: 1) as? Int32, 7)
        XCTAssertEqual(try msg.get(forField: 20) as? String, "all")
      },
      buildDynamic: {
        var simpleDyn = DynamicMessage(descriptor: simpleDesc)
        try simpleDyn.set(Int32(7), forField: 1)
        var d = DynamicMessage(descriptor: desc)
        try d.set("first", forField: 2)
        try d.set(Int32(1), forField: 6)
        try d.set(simpleDyn, forField: 7)
        try d.set("all", forField: 20)
        return d
      },
      validateProto: { p in
        if case .firstStr(let v) = p.firstChoice {
          XCTAssertEqual(v, "first")
        }
        else {
          XCTFail("expected firstStr case")
        }
        if case .secondEnum(let v) = p.secondChoice {
          XCTAssertEqual(v, .active)
        }
        else {
          XCTFail("expected secondEnum case")
        }
        if case .thirdMsg(let m) = p.thirdChoice {
          XCTAssertEqual(m.id, 7)
        }
        else {
          XCTFail("expected thirdMsg case")
        }
        XCTAssertEqual(p.label, "all")
      }
    )
  }

  // MARK: - 19. Last-field-wins: crafted binary with field 1 then field 3 in same oneof

  func test_oneof_lastFieldWins_directionA() throws {
    // Craft binary bytes containing both field 1 (doubleVal, wire type 1) and field 3 (int32Val, wire type 0)
    // of the same oneof. Proto binary last-field-wins: field 3 must overwrite field 1.
    //
    // Encoding:
    //   Field 1 tag: (1 << 3) | 1 = 0x09 (wire type 1 = 64-bit)
    //   double 1.0 little-endian: 0x00 0x00 0x00 0x00 0x00 0x00 0xF0 0x3F
    //   Field 3 tag: (3 << 3) | 0 = 0x18 (wire type 0 = varint)
    //   int32 42 varint: 0x2A
    let crafted = Data([
      0x09,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0x3F,
      0x18,
      0x2A,
    ])

    let desc = CompatDescriptors.oneofScalars()
    let deserialized = try BinaryCompatHelpers.makeDeserializer(registry: registry)
      .deserialize(crafted, using: desc)

    // Last-field-wins: only field 3 (int32Val=42) should be present
    XCTAssertEqual(try deserialized.get(forField: 3) as? Int32, 42)
    XCTAssertNil(
      try deserialized.get(forField: 1) as? Double,
      "field 1 (doubleVal) should be overwritten by field 3 (last-field-wins)"
    )
  }

  // MARK: - 20. int32 uses standard varint (not zigzag) in oneof

  func test_oneof_scalars_sint32_bidirectional() throws {
    // OneofScalars has no sint32 field. int32_val (field 3) uses standard 2's-complement varint,
    // not zigzag. Verify that negative int32 (-1) round-trips correctly and that the
    // serialized byte count matches standard varint encoding (10 value bytes, not 1 zigzag byte).
    var proto = Testcompat_OneofScalars()
    proto.int32Val = -1

    let desc = CompatDescriptors.oneofScalars()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 3) as? Int32, -1)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(-1), forField: 3)
        return d
      },
      validateProto: { p in
        if case .int32Val(let v) = p.value {
          XCTAssertEqual(v, -1)
        }
        else {
          XCTFail("expected int32Val case with value -1")
        }
      }
    )

    // Verify wire encoding is 2's-complement varint for -1:
    //   tag (1 byte, 0x18) + 10-byte varint = 11 total bytes.
    //   Zigzag(-1) would be 1 (1 byte), yielding only 2 total bytes.
    var d = DynamicMessage(descriptor: desc)
    try d.set(Int32(-1), forField: 3)
    let bytes = try BinaryCompatHelpers.makeSerializer().serialize(d)
    XCTAssertEqual(
      bytes.count,
      11,
      "int32=-1 must use 10-byte 2's-complement varint + 1 tag byte (standard varint, not zigzag)"
    )
  }

  // MARK: - 21. 8-byte fixed-width encoding verified via double variant in oneof

  func test_oneof_scalars_fixed64_bidirectional() throws {
    // OneofScalars has no fixed64 field. double_val (field 1) uses wire type 1 (64-bit fixed-width),
    // identical to fixed64 in the wire format. This test verifies 8-byte little-endian encoding
    // in oneof context and checks the total serialized byte count.
    let val: Double = 1_234_567_890.12345

    var proto = Testcompat_OneofScalars()
    proto.doubleVal = val

    let desc = CompatDescriptors.oneofScalars()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        if let got = try msg.get(forField: 1) as? Double {
          XCTAssertEqual(got, val, accuracy: 1e-5)
        }
        else {
          XCTFail("expected doubleVal in field 1")
        }
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(val, forField: 1)
        return d
      },
      validateProto: { p in
        if case .doubleVal(let v) = p.value {
          XCTAssertEqual(v, val, accuracy: 1e-5)
        }
        else {
          XCTFail("expected doubleVal case")
        }
      }
    )

    // Verify wire encoding: field 1 tag (0x09, 1 byte) + 8-byte double = 9 total bytes.
    var d = DynamicMessage(descriptor: desc)
    try d.set(val, forField: 1)
    let bytes = try BinaryCompatHelpers.makeSerializer().serialize(d)
    XCTAssertEqual(
      bytes.count,
      9,
      "double in oneof uses wire type 1 (64-bit): 1-byte tag + 8-byte payload = 9 total"
    )
  }
}
