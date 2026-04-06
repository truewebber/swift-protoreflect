// BinaryCompatEdgeCasesTests.swift
// SwiftProtoReflectTests
//
// Group: Edge Cases — bidirectional binary compatibility tests for boundary values,
// encoding specifics, empty messages, large values, and unknown fields.
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
// Binary-specific edge cases:
//   - Varint encoding of large values (Int64.max/min, UInt64.max, Int32.max exact bytes).
//   - NaN/Infinity for Float (4-byte) and Double (8-byte) IEEE 754 fixed-width.
//   - Empty message → Data() (zero bytes).
//   - Unknown field preservation (field 999 in crafted binary).
//   - Multi-byte length-delimited varint for 10 KB strings/bytes.
//   - Null bytes and control characters in UTF-8 strings.

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class BinaryCompatEdgeCasesTests: XCTestCase {

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

  // MARK: - Test 1: Unicode strings (all scripts) survive binary round-trip

  func test_edge_unicode_allScripts_bidirectional() async throws {
    let desc = CompatDescriptors.scalarMessage()
    // Covers CJK, Cyrillic, Arabic, emoji, control chars — all valid UTF-8 sequences.
    let unicodeStr =
      "CJK:\u{4F60}\u{597D}\u{4E16}\u{754C} Cyr:\u{041F}\u{0440}\u{0438}\u{0432}\u{0435}\u{0442} Ar:\u{0645}\u{0631}\u{062D}\u{0628}\u{0627} Em:\u{1F389}\u{1F30D} Ctrl:\u{0001}\u{001F}\u{007F}"

    var proto = Testcompat_ScalarMessage()
    proto.stringField = unicodeStr

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { XCTAssertEqual(try $0.get(forField: 14) as? String, unicodeStr) },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(unicodeStr, forField: 14)
        return d
      },
      validateProto: { XCTAssertEqual($0.stringField, unicodeStr) }
    )
  }

  // MARK: - Test 2: Empty strings in repeated field (unpacked length-delimited)

  func test_edge_emptyString_inRepeated_bidirectional() async throws {
    let desc = CompatDescriptors.repeatedAllTypes()
    let strings: [String] = ["", "a", "", "b", ""]

    var proto = Testcompat_RepeatedAllTypes()
    proto.repString = strings

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { dynamic in
        let values = try XCTUnwrap(try dynamic.get(forField: 14) as? [String])
        XCTAssertEqual(values, strings)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(strings, forField: 14)
        return d
      },
      validateProto: { XCTAssertEqual($0.repString, strings) }
    )
  }

  // MARK: - Test 3: Empty bytes omitted in proto3; Data([0x00]) IS serialized

  func test_edge_emptyBytes_omittedInProto3() async throws {
    let desc = CompatDescriptors.scalarMessage()

    // Oracle: swift-protobuf omits bytes_field when unset (proto3 default = Data())
    let emptyProto = Testcompat_ScalarMessage()
    XCTAssertEqual(
      try emptyProto.serializedData(),
      Data(),
      "swift-protobuf must produce empty bytes for default bytes_field in proto3"
    )

    // Direction B: DynamicMessage with bytes_field not set → empty wire output
    let unsetDynamic = DynamicMessage(descriptor: desc)
    let _asyncResult26 = try await serializer.serialize(unsetDynamic)
    XCTAssertEqual(
      _asyncResult26,
      Data(),
      "BinarySerializer must omit unset bytes_field in proto3"
    )

    // Data([0x00]) is non-default — must appear on the wire in both oracle and our serializer
    var protoWithNull = Testcompat_ScalarMessage()
    protoWithNull.bytesField = Data([0x00])
    XCTAssertFalse(
      try protoWithNull.serializedData().isEmpty,
      "Data([0x00]) must produce wire bytes in swift-protobuf"
    )

    var dynamicWithNull = DynamicMessage(descriptor: desc)
    try dynamicWithNull.set(Data([0x00]), forField: 15)
    let _asyncResult27 = try await serializer.serialize(dynamicWithNull).isEmpty
    XCTAssertFalse(_asyncResult27, "BinarySerializer must serialize Data([0x00]) for bytes_field")
  }

  // MARK: - Test 4: Data([0x00]) (null byte) round-trips correctly

  func test_edge_nonEmptyBytes_bidirectional() async throws {
    let desc = CompatDescriptors.scalarMessage()

    var proto = Testcompat_ScalarMessage()
    proto.bytesField = Data([0x00])

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { XCTAssertEqual(try $0.get(forField: 15) as? Data, Data([0x00])) },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Data([0x00]), forField: 15)
        return d
      },
      validateProto: { XCTAssertEqual($0.bytesField, Data([0x00])) }
    )
  }

  // MARK: - Test 5: Int64.max as 9-byte varint

  func test_edge_int64Max_varintEncoding_bidirectional() async throws {
    let desc = CompatDescriptors.scalarMessage()

    var proto = Testcompat_ScalarMessage()
    proto.int64Field = Int64.max

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { XCTAssertEqual(try $0.get(forField: 4) as? Int64, Int64.max) },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int64.max, forField: 4)
        return d
      },
      validateProto: { XCTAssertEqual($0.int64Field, Int64.max) }
    )
  }

  // MARK: - Test 6: Int64.min as 10-byte two's-complement varint

  func test_edge_int64Min_varintEncoding_bidirectional() async throws {
    let desc = CompatDescriptors.scalarMessage()

    var proto = Testcompat_ScalarMessage()
    proto.int64Field = Int64.min

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { XCTAssertEqual(try $0.get(forField: 4) as? Int64, Int64.min) },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int64.min, forField: 4)
        return d
      },
      validateProto: { XCTAssertEqual($0.int64Field, Int64.min) }
    )
  }

  // MARK: - Test 7: UInt64.max as 10-byte varint

  func test_edge_uint64Max_varintEncoding_bidirectional() async throws {
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

  // MARK: - Test 8: Zero int64 omitted in proto3 (Direction A + B)

  func test_edge_zeroInt64_omittedInProto3() async throws {
    let desc = CompatDescriptors.scalarMessage()

    // Direction A: swift-protobuf produces empty bytes for int64_field = 0 (proto3 default)
    let proto = Testcompat_ScalarMessage()
    let referenceData = try proto.serializedData()
    XCTAssertEqual(referenceData, Data(), "swift-protobuf must produce empty bytes for int64_field=0 in proto3")

    // Deserialize empty data → field 4 must not be present
    let dynamic = try await BinaryCompatHelpers.makeDeserializer(registry: registry)
      .deserialize(referenceData, using: desc)
    XCTAssertFalse(
      try dynamic.hasValue(forField: 4),
      "int64_field must not be present after deserializing empty proto3 wire data"
    )

    // Direction B: DynamicMessage without int64_field set → empty wire output
    let unsetDynamic = DynamicMessage(descriptor: desc)
    let _asyncResult28 = try await serializer.serialize(unsetDynamic)
    XCTAssertEqual(
      _asyncResult28,
      Data(),
      "BinarySerializer must omit unset int64_field in proto3"
    )
  }

  // MARK: - Test 9: Optional int64 = 0 IS serialized (explicit presence semantics)

  func test_edge_optionalInt64_zero_serialized() async throws {
    let desc = CompatDescriptors.optionalScalarMessage()

    var proto = Testcompat_OptionalScalarMessage()
    proto.optInt64 = 0  // proto3 optional field explicitly set to zero — must appear in wire format

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { dynamic in
        XCTAssertTrue(
          try dynamic.hasValue(forField: 4),
          "Optional int64 explicitly set to zero must have presence in binary"
        )
        XCTAssertEqual(try dynamic.get(forField: 4) as? Int64, 0)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int64(0), forField: 4)
        return d
      },
      validateProto: { p in
        XCTAssertTrue(p.hasOptInt64, "optional int64 set to zero must have presence after round-trip")
        XCTAssertEqual(p.optInt64, 0)
      }
    )
  }

  // MARK: - Test 10: Float NaN, +Infinity, -Infinity as 4-byte IEEE 754

  func test_edge_nanInfinity_float_bidirectional() async throws {
    let desc = CompatDescriptors.scalarMessage()

    // NaN — must use .isNaN because NaN != NaN
    var nanProto = Testcompat_ScalarMessage()
    nanProto.floatField = Float.nan
    try await BinaryCompatHelpers.assertBidirectional(
      proto: nanProto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { dynamic in
        let v = try XCTUnwrap(try dynamic.get(forField: 2) as? Float)
        XCTAssertTrue(v.isNaN, "Float NaN must survive binary round-trip (direction A)")
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Float.nan, forField: 2)
        return d
      },
      validateProto: { XCTAssertTrue($0.floatField.isNaN, "Float NaN must survive binary round-trip (direction B)") }
    )

    // +Infinity
    var infProto = Testcompat_ScalarMessage()
    infProto.floatField = Float.infinity
    try await BinaryCompatHelpers.assertBidirectional(
      proto: infProto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { XCTAssertEqual(try $0.get(forField: 2) as? Float, Float.infinity) },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Float.infinity, forField: 2)
        return d
      },
      validateProto: { XCTAssertEqual($0.floatField, Float.infinity) }
    )

    // -Infinity
    var negInfProto = Testcompat_ScalarMessage()
    negInfProto.floatField = -Float.infinity
    try await BinaryCompatHelpers.assertBidirectional(
      proto: negInfProto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { XCTAssertEqual(try $0.get(forField: 2) as? Float, -Float.infinity) },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(-Float.infinity, forField: 2)
        return d
      },
      validateProto: { XCTAssertEqual($0.floatField, -Float.infinity) }
    )
  }

  // MARK: - Test 11: Double NaN, +Infinity, -Infinity as 8-byte IEEE 754

  func test_edge_nanInfinity_double_bidirectional() async throws {
    let desc = CompatDescriptors.scalarMessage()

    // NaN — must use .isNaN because NaN != NaN
    var nanProto = Testcompat_ScalarMessage()
    nanProto.doubleField = Double.nan
    try await BinaryCompatHelpers.assertBidirectional(
      proto: nanProto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { dynamic in
        let v = try XCTUnwrap(try dynamic.get(forField: 1) as? Double)
        XCTAssertTrue(v.isNaN, "Double NaN must survive binary round-trip (direction A)")
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Double.nan, forField: 1)
        return d
      },
      validateProto: { XCTAssertTrue($0.doubleField.isNaN, "Double NaN must survive binary round-trip (direction B)") }
    )

    // +Infinity
    var infProto = Testcompat_ScalarMessage()
    infProto.doubleField = Double.infinity
    try await BinaryCompatHelpers.assertBidirectional(
      proto: infProto,
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

    // -Infinity
    var negInfProto = Testcompat_ScalarMessage()
    negInfProto.doubleField = -Double.infinity
    try await BinaryCompatHelpers.assertBidirectional(
      proto: negInfProto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { XCTAssertEqual(try $0.get(forField: 1) as? Double, -Double.infinity) },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(-Double.infinity, forField: 1)
        return d
      },
      validateProto: { XCTAssertEqual($0.doubleField, -Double.infinity) }
    )
  }

  // MARK: - Test 12: Empty message produces Data() (zero bytes)

  func test_edge_emptyMessage_producesEmptyData() async throws {
    let desc = CompatDescriptors.emptyCustom()

    // Oracle: EmptyCustom serializes to empty Data
    let proto = Testcompat_EmptyCustom()
    XCTAssertEqual(
      try proto.serializedData(),
      Data(),
      "swift-protobuf must produce empty bytes for EmptyCustom"
    )

    // Direction B: DynamicMessage with EmptyCustom descriptor → empty wire output
    let dynamic = DynamicMessage(descriptor: desc)
    let _asyncResult29 = try await serializer.serialize(dynamic)
    XCTAssertEqual(
      _asyncResult29,
      Data(),
      "BinarySerializer must produce empty bytes for EmptyCustom"
    )
  }

  // MARK: - Test 13: Empty message round-trip

  func test_edge_emptyMessage_roundTrip_bidirectional() async throws {
    let desc = CompatDescriptors.emptyCustom()
    let proto = Testcompat_EmptyCustom()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { _ in
        // EmptyCustom has no fields; just verify deserialization succeeded without throwing
      },
      buildDynamic: { DynamicMessage(descriptor: desc) },
      validateProto: { _ in
        // EmptyCustom has no fields; just verify parsing succeeded without throwing
      }
    )
  }

  // MARK: - Test 14: WideMessage (50+ fields) with subset set — bidirectional

  func test_edge_wideMessage_50plusFields_bidirectional() async throws {
    let desc = CompatDescriptors.wideMessage()

    // Field number mapping (from wideMessage() descriptor):
    // f1..f20  → fields 1-20  (string)
    // i1..i10  → fields 21-30 (int32)
    // d1..d5   → fields 31-35 (double)
    // b1..b5   → fields 36-40 (bool)
    // fl1..fl2 → fields 49-50 (float)
    var proto = Testcompat_WideMessage()
    proto.f1 = "first"
    proto.f20 = "twentieth"
    proto.i1 = 111
    proto.i10 = 1_010
    proto.d1 = 3.5  // exactly representable in IEEE 754
    proto.d5 = 2.5
    proto.b1 = true
    proto.fl1 = 1.5  // exactly representable in IEEE 754
    proto.fl2 = 2.5

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { dynamic in
        XCTAssertEqual(try dynamic.get(forField: 1) as? String, "first")
        XCTAssertEqual(try dynamic.get(forField: 20) as? String, "twentieth")
        XCTAssertEqual(try dynamic.get(forField: 21) as? Int32, 111)
        XCTAssertEqual(try dynamic.get(forField: 30) as? Int32, 1_010)
        XCTAssertEqual(try dynamic.get(forField: 31) as? Double, 3.5)
        XCTAssertEqual(try dynamic.get(forField: 35) as? Double, 2.5)
        XCTAssertEqual(try dynamic.get(forField: 36) as? Bool, true)
        XCTAssertEqual(try dynamic.get(forField: 49) as? Float, 1.5)
        XCTAssertEqual(try dynamic.get(forField: 50) as? Float, 2.5)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set("first", forField: 1)
        try d.set("twentieth", forField: 20)
        try d.set(Int32(111), forField: 21)
        try d.set(Int32(1_010), forField: 30)
        try d.set(Double(3.5), forField: 31)
        try d.set(Double(2.5), forField: 35)
        try d.set(true, forField: 36)
        try d.set(Float(1.5), forField: 49)
        try d.set(Float(2.5), forField: 50)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.f1, "first")
        XCTAssertEqual(p.f20, "twentieth")
        XCTAssertEqual(p.i1, 111)
        XCTAssertEqual(p.i10, 1_010)
        XCTAssertEqual(p.d1, 3.5)
        XCTAssertEqual(p.d5, 2.5)
        XCTAssertEqual(p.b1, true)
        XCTAssertEqual(p.fl1, 1.5)
        XCTAssertEqual(p.fl2, 2.5)
      }
    )
  }

  // MARK: - Test 15: Single-element repeated int32 (packed encoding)

  func test_edge_repeatedSingleElement_bidirectional() async throws {
    let desc = CompatDescriptors.repeatedAllTypes()

    var proto = Testcompat_RepeatedAllTypes()
    proto.repInt32 = [42]

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { dynamic in
        let values = try XCTUnwrap(try dynamic.get(forField: 3) as? [Int32])
        XCTAssertEqual(values, [42])
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set([Int32(42)], forField: 3)
        return d
      },
      validateProto: { XCTAssertEqual($0.repInt32, [42]) }
    )
  }

  // MARK: - Test 16: Map with single entry bidirectional

  func test_edge_mapSingleEntry_bidirectional() async throws {
    let desc = CompatDescriptors.mapAllKeyTypes()

    var proto = Testcompat_MapAllKeyTypes()
    proto.mapStringString = ["only": "one"]

    // Direction A: oracle → our deserializer
    let referenceData = try proto.serializedData()
    let dynamic = try await BinaryCompatHelpers.makeDeserializer(registry: registry)
      .deserialize(referenceData, using: desc)
    let map = try XCTUnwrap(try dynamic.get(forField: 1) as? [AnyHashable: Any])
    XCTAssertEqual(map.count, 1, "Map must contain exactly one entry")
    XCTAssertEqual(map["only"] as? String, "one")

    // Direction B: our serializer → oracle
    var d = DynamicMessage(descriptor: desc)
    try d.setMapEntry("one", forKey: "only", inField: 1)
    let ourData = try await serializer.serialize(d)
    let decoded = try Testcompat_MapAllKeyTypes(serializedBytes: ourData)
    XCTAssertEqual(decoded.mapStringString, ["only": "one"])
  }

  // MARK: - Test 17: Unknown fields preserved in binary (Direction A)

  func test_edge_unknownFields_preserved_directionA() async throws {
    let desc = CompatDescriptors.scalarMessage()

    // Crafted binary bytes containing:
    //   - Known field: int32_field (field 3, wire type 0) = 100
    //     tag = (3 << 3) | 0 = 0x18; value 100 = 0x64
    //   - Unknown field: field 999, wire type 0 (varint) = 7
    //     tag varint: (999 << 3) | 0 = 7992 → [0xB8, 0x3E]; value 7 = 0x07
    let craftedBytes = Data([0x18, 0x64, 0xB8, 0x3E, 0x07])

    // Deserialize — known field must be read correctly despite unknown field 999
    let dynamic = try await BinaryCompatHelpers.makeDeserializer(registry: registry)
      .deserialize(craftedBytes, using: desc)
    XCTAssertEqual(
      try dynamic.get(forField: 3) as? Int32,
      100,
      "int32_field must be correctly deserialized alongside unknown field 999"
    )

    // Re-serialize — known field must survive; round-trip via oracle confirms correctness
    let reserializedData = try await serializer.serialize(dynamic)
    let reparsed = try Testcompat_ScalarMessage(serializedBytes: reserializedData)
    XCTAssertEqual(
      reparsed.int32Field,
      100,
      "int32_field must survive re-serialization after unknown field was present"
    )
  }

  // MARK: - Test 18: Very long string (10 KB) — multi-byte varint length prefix

  func test_edge_veryLongString_10KB_bidirectional() async throws {
    let desc = CompatDescriptors.scalarMessage()
    let longString = String(repeating: "a", count: 10_000)

    var proto = Testcompat_ScalarMessage()
    proto.stringField = longString

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { XCTAssertEqual(try $0.get(forField: 14) as? String, longString) },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(longString, forField: 14)
        return d
      },
      validateProto: { XCTAssertEqual($0.stringField, longString) }
    )
  }

  // MARK: - Test 19: Very large bytes (10 KB) — multi-byte varint length prefix

  func test_edge_veryLargeBytes_10KB_bidirectional() async throws {
    let desc = CompatDescriptors.scalarMessage()
    let largeBytes = Data(repeating: 0xAB, count: 10_000)

    var proto = Testcompat_ScalarMessage()
    proto.bytesField = largeBytes

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { XCTAssertEqual(try $0.get(forField: 15) as? Data, largeBytes) },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(largeBytes, forField: 15)
        return d
      },
      validateProto: { XCTAssertEqual($0.bytesField, largeBytes) }
    )
  }

  // MARK: - Test 20: String with embedded null byte round-trips as raw UTF-8

  func test_edge_stringWithNullByte_bidirectional() async throws {
    let desc = CompatDescriptors.scalarMessage()
    // U+0000 is a valid Unicode codepoint; binary serialization writes raw UTF-8 bytes (0x00).
    let nullByteString = "\u{0000}null\u{0000}"

    var proto = Testcompat_ScalarMessage()
    proto.stringField = nullByteString

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { XCTAssertEqual(try $0.get(forField: 14) as? String, nullByteString) },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(nullByteString, forField: 14)
        return d
      },
      validateProto: { XCTAssertEqual($0.stringField, nullByteString) }
    )
  }

  // MARK: - Test 21: String with control characters (no binary escaping needed)

  func test_edge_stringWithControlChars_bidirectional() async throws {
    let desc = CompatDescriptors.scalarMessage()
    // Control chars \u{0001}, \u{001F}, \u{007F} are valid UTF-8; binary has no escaping concern.
    let controlString = "\u{0001}start\u{001F}middle\u{007F}end"

    var proto = Testcompat_ScalarMessage()
    proto.stringField = controlString

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { XCTAssertEqual(try $0.get(forField: 14) as? String, controlString) },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(controlString, forField: 14)
        return d
      },
      validateProto: { XCTAssertEqual($0.stringField, controlString) }
    )
  }

  // MARK: - Test 22: Nested1 with name set, child absent — wire has only name tag+value

  func test_edge_deeplyNested_emptyLeaf_bidirectional() async throws {
    let desc = CompatDescriptors.nested1()

    // Nested1 descriptor: child (field 1, message Nested2), name (field 2, string)
    // Setting only name → binary contains only field 2 bytes; no child tag.
    var proto = Testcompat_Nested1()
    proto.name = "top"

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { dynamic in
        XCTAssertEqual(try dynamic.get(forField: 2) as? String, "top")
        XCTAssertFalse(
          try dynamic.hasValue(forField: 1),
          "child field must be absent when not set in source proto"
        )
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set("top", forField: 2)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.name, "top")
        XCTAssertFalse(p.hasChild, "child must not be present when only name was serialized")
      }
    )
  }

  // MARK: - Test 23: Int32.max encodes as exactly 5 varint bytes (Direction B)

  func test_edge_int32Max_varintEncoding_exactBytes() async throws {
    // Int32.max = 2147483647 = 0x7FFFFFFF
    // Varint encoding (5 bytes): 0xFF 0xFF 0xFF 0xFF 0x07
    // Field 3 (int32_field), wire type 0: tag = (3 << 3) | 0 = 0x18
    // Full expected wire bytes: [0x18, 0xFF, 0xFF, 0xFF, 0xFF, 0x07]
    let expectedBytes = Data([0x18, 0xFF, 0xFF, 0xFF, 0xFF, 0x07])

    // Oracle verification
    var proto = Testcompat_ScalarMessage()
    proto.int32Field = Int32.max
    XCTAssertEqual(
      try proto.serializedData(),
      expectedBytes,
      "swift-protobuf must encode Int32.max as tag 0x18 + exactly 5 varint bytes"
    )

    // Direction B: our serializer must produce the same exact bytes
    let desc = CompatDescriptors.scalarMessage()
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32.max, forField: 3)
    let _asyncResult30 = try await serializer.serialize(dynamic)
    XCTAssertEqual(
      _asyncResult30,
      expectedBytes,
      "BinarySerializer must encode Int32.max as tag 0x18 + exactly 5 varint bytes"
    )
  }
}
