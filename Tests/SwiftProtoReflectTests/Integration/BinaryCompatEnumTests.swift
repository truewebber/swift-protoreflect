// BinaryCompatEnumTests.swift
// SwiftProtoReflectTests
//
// Group: Enum Fields — bidirectional binary compatibility tests.
//
// Oracle strategy: Option A — swift-protobuf generated types (.pb.swift).
//
// Binary-specific notes:
//   - Enum values are encoded as plain varints (not string names as in JSON).
//   - Negative enum values use 10-byte 2's-complement varint (same as negative int32).
//     Zigzag encoding does NOT apply to enum fields.
//   - Zero enum value (proto3 default) produces no wire bytes for singular fields.
//   - Unknown enum values are preserved as raw Int32 on deserialization.
//   - Map fields: byte-for-byte comparison is unreliable due to non-deterministic ordering.
//     Use value comparison in validateDynamic/validateProto instead.

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class BinaryCompatEnumTests: XCTestCase {

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

  // MARK: - 1. Enum field stored as varint (no name lookup)

  func test_enum_topLevel_varintEncoding_bidirectional() async throws {
    var proto = Testcompat_WithNestedEnum()
    proto.kind = .innerAlpha  // raw value 1

    let desc = CompatDescriptors.withNestedEnum()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? Int32, 1)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(1), forField: 1)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.kind, .innerAlpha)
      }
    )
  }

  // MARK: - 2. All IntentFlag enum values as varints (Direction B)

  func test_enum_allStatusValues_bidirectional() async throws {
    let desc = CompatDescriptors.intentHolder()
    // Non-zero IntentFlag values: 1=INFORMATIONAL, 2=NAVIGATIONAL, 4=TRANSACTIONAL, 8=COMMERCIAL
    let cases: [(Int32, Testcompat_IntentFlag)] = [
      (1, .intentInformational),
      (2, .intentNavigational),
      (4, .intentTransactional),
      (8, .intentCommercial),
    ]
    for (rawValue, expected) in cases {
      var d = DynamicMessage(descriptor: desc)
      try d.set(rawValue, forField: 1)
      try await BinaryCompatHelpers.assertUsToOracle(
        dynamic: d,
        protoType: Testcompat_IntentHolder.self
      ) { decoded in
        XCTAssertEqual(decoded.intent, expected, "intent raw=\(rawValue) mismatch")
      }
    }
  }

  // MARK: - 3. Aliased enum round-trip (INTENT_INFORMATIONAL = 1)

  func test_enum_aliased_bidirectional() async throws {
    var proto = Testcompat_IntentHolder()
    proto.intent = .intentInformational  // raw value 1

    let desc = CompatDescriptors.intentHolder()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? Int32, 1)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(1), forField: 1)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.intent, .intentInformational)
      }
    )
  }

  // MARK: - 4. Negative enum values as 10-byte 2's-complement varints (not zigzag)

  func test_enum_negativeValues_bidirectional() async throws {
    let desc = CompatDescriptors.directionHolder()

    // DOWN = -1
    var protoDown = Testcompat_DirectionHolder()
    protoDown.dir = .down
    try await BinaryCompatHelpers.assertBidirectional(
      proto: protoDown,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? Int32, -1)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(-1), forField: 1)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.dir, .down)
      }
    )

    // LEFT = -2
    var protoLeft = Testcompat_DirectionHolder()
    protoLeft.dir = .left
    try await BinaryCompatHelpers.assertBidirectional(
      proto: protoLeft,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? Int32, -2)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(-2), forField: 1)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.dir, .left)
      }
    )
  }

  // MARK: - 5. Repeated enum packed as varints

  func test_enum_repeated_bidirectional() async throws {
    var proto = Testcompat_IntentHolder()
    proto.allIntents = [.intentInformational, .intentNavigational, .intentTransactional, .intentCommercial]

    let desc = CompatDescriptors.intentHolder()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let vals = try XCTUnwrap(try msg.get(forField: 2) as? [Int32])
        XCTAssertEqual(vals, [1, 2, 4, 8])
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set([Int32(1), Int32(2), Int32(4), Int32(8)] as [Int32], forField: 2)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(
          p.allIntents,
          [.intentInformational, .intentNavigational, .intentTransactional, .intentCommercial]
        )
      }
    )
  }

  // MARK: - 6. Map with enum value (non-deterministic order — compare values, not bytes)

  func test_enum_mapValue_bidirectional() async throws {
    var proto = Testcompat_IntentHolder()
    proto.byName = ["search": .intentNavigational, "buy": .intentTransactional]

    let desc = CompatDescriptors.intentHolder()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let map = try XCTUnwrap(try msg.get(forField: 3) as? [AnyHashable: Any])
        XCTAssertEqual(map["search"] as? Int32, 2)
        XCTAssertEqual(map["buy"] as? Int32, 4)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.setMapEntry(Int32(2), forKey: "search", inField: 3)
        try d.setMapEntry(Int32(4), forKey: "buy", inField: 3)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.byName["search"], .intentNavigational)
        XCTAssertEqual(p.byName["buy"], .intentTransactional)
      }
    )
  }

  // MARK: - 7. Zero enum value (proto3 default) produces no wire bytes

  func test_enum_defaultValue_omittedInProto3() async throws {
    // Direction A: oracle with intent = .intentDefault (0) → empty serializedData
    var proto = Testcompat_IntentHolder()
    proto.intent = .intentDefault
    let referenceData = try proto.serializedData()
    XCTAssertEqual(referenceData, Data(), "swift-protobuf must omit zero enum (proto3 default) from wire output")

    // Direction B: our serializer with no field set → empty bytes
    let desc = CompatDescriptors.intentHolder()
    let dynamic = DynamicMessage(descriptor: desc)
    let ourData = try serializer.serialize(dynamic)
    XCTAssertEqual(ourData, Data(), "BinarySerializer must produce empty bytes when enum field not set")
  }

  // MARK: - 8. Aliased Priority enum (NORMAL == MEDIUM, both value 2)

  func test_enum_aliased_priorityNormalMedium_bidirectional() async throws {
    var proto = Testcompat_CrossFileAll()
    proto.priority = .normal  // raw value 2 (same as .medium)

    let desc = CompatDescriptors.crossFileAll()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 8) as? Int32, 2)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(2), forField: 8)
        return d
      },
      validateProto: { p in
        // Both .normal and .medium have raw value 2
        XCTAssertTrue(p.priority == .normal || p.priority == .medium)
      }
    )
  }

  // MARK: - 9. Enum inside oneof (OneofComplex.enumVal = DELETED = 3)

  func test_enum_inOneof_bidirectional() async throws {
    var proto = Testcompat_OneofComplex()
    proto.enumVal = .deleted  // raw value 3

    let desc = CompatDescriptors.oneofComplex()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 5) as? Int32, 3)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(3), forField: 5)
        return d
      },
      validateProto: { p in
        if case .enumVal(let v) = p.choice {
          XCTAssertEqual(v, .deleted)
        }
        else {
          XCTFail("expected enumVal case in oneof")
        }
      }
    )
  }

  // MARK: - 10. All IntentHolder enum field types simultaneously

  func test_enum_allEnumTypes_simultaneously_bidirectional() async throws {
    var proto = Testcompat_IntentHolder()
    proto.intent = .intentTransactional  // 4
    proto.allIntents = [.intentInformational, .intentNavigational, .intentTransactional, .intentCommercial]
    proto.byName = ["info": .intentInformational, "buy": .intentTransactional]

    let desc = CompatDescriptors.intentHolder()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? Int32, 4)
        let vals = try XCTUnwrap(try msg.get(forField: 2) as? [Int32])
        XCTAssertEqual(vals, [1, 2, 4, 8])
        let map = try XCTUnwrap(try msg.get(forField: 3) as? [AnyHashable: Any])
        XCTAssertEqual(map["info"] as? Int32, 1)
        XCTAssertEqual(map["buy"] as? Int32, 4)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(4), forField: 1)
        try d.set([Int32(1), Int32(2), Int32(4), Int32(8)] as [Int32], forField: 2)
        try d.setMapEntry(Int32(1), forKey: "info", inField: 3)
        try d.setMapEntry(Int32(4), forKey: "buy", inField: 3)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.intent, .intentTransactional)
        XCTAssertEqual(p.allIntents.count, 4)
        XCTAssertEqual(p.byName["info"], .intentInformational)
        XCTAssertEqual(p.byName["buy"], .intentTransactional)
      }
    )
  }

  // MARK: - 11. Round-trip all Direction values including negatives

  func test_enum_roundTrip_allDirectionValues() async throws {
    // [0=UNSPECIFIED, 1=UP, -1=DOWN, -2=LEFT, 2=RIGHT]
    var proto = Testcompat_DirectionHolder()
    proto.dirs = [.unspecified, .up, .down, .left, .right]

    let desc = CompatDescriptors.directionHolder()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let vals = try XCTUnwrap(try msg.get(forField: 2) as? [Int32])
        XCTAssertEqual(vals, [0, 1, -1, -2, 2])
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set([Int32(0), Int32(1), Int32(-1), Int32(-2), Int32(2)] as [Int32], forField: 2)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.dirs, [.unspecified, .up, .down, .left, .right])
      }
    )

    // Binary self-roundtrip: serialize → deserialize → verify values preserved
    let allValues: [Int32] = [0, 1, -1, -2, 2]
    var dynRt = DynamicMessage(descriptor: desc)
    try dynRt.set(allValues, forField: 2)
    let roundTripData = try serializer.serialize(dynRt)
    let restored = try await BinaryCompatHelpers.makeDeserializer(registry: registry)
      .deserialize(roundTripData, using: desc)
    let restoredVals = try XCTUnwrap(try restored.get(forField: 2) as? [Int32])
    XCTAssertEqual(restoredVals, allValues, "binary self-roundtrip must preserve negative enum values")
  }

  // MARK: - 12. Nested enum inside message (INNER_GAMMA = 3)

  func test_enum_nestedInsideMessage_bidirectional() async throws {
    var proto = Testcompat_WithNestedEnum()
    proto.kind = .innerGamma  // raw value 3
    proto.label = "gamma test"

    let desc = CompatDescriptors.withNestedEnum()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? Int32, 3)
        XCTAssertEqual(try msg.get(forField: 2) as? String, "gamma test")
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(3), forField: 1)
        try d.set("gamma test", forField: 2)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.kind, .innerGamma)
        XCTAssertEqual(p.label, "gamma test")
      }
    )
  }

  // MARK: - 13. Negative enum encodes as 10-byte 2's-complement varint (not zigzag)

  func test_enum_negativeValue_varintEncoding_10bytes() async throws {
    // Field 1 (wire type 0): tag = (1 << 3) | 0 = 0x08
    // -1 as int32 → sign-extended to uint64 → 0xFFFFFFFFFFFFFFFF
    // Encoded as 10-byte varint: 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0xFF 0x01
    let expected = Data([
      0x08,  // tag: field 1, wire type 0
      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01,  // -1 as 10-byte varint
    ])

    // Verify oracle produces the same bytes (Direction A oracle cross-check)
    var proto = Testcompat_DirectionHolder()
    proto.dir = .down  // -1
    XCTAssertEqual(
      try proto.serializedData(),
      expected,
      "swift-protobuf oracle: Direction.DOWN(-1) must encode as 10-byte varint, not zigzag"
    )

    // Verify our serializer (Direction B)
    let desc = CompatDescriptors.directionHolder()
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(-1), forField: 1)
    let _asyncResult20 = try serializer.serialize(dynamic)
    XCTAssertEqual(
      _asyncResult20,
      expected,
      "BinarySerializer: enum -1 must encode as 10-byte 2's-complement varint (0xFF×9 + 0x01)"
    )
  }

  // MARK: - 14. Unknown enum value preserved as raw Int32 on deserialization

  func test_enum_unknownValue_preserved_bidirectional() async throws {
    // Craft binary: IntentHolder field 1 = 999 (unknown value)
    // tag = (1 << 3) | 0 = 0x08
    // 999 as varint: 999 = 0x3E7 → 0xE7 (low 7 bits + continue) 0x07 (high 7 bits)
    let crafted = Data([0x08, 0xE7, 0x07])

    let desc = CompatDescriptors.intentHolder()
    let dynamic = try await BinaryCompatHelpers.makeDeserializer(registry: registry)
      .deserialize(crafted, using: desc)
    let value = try XCTUnwrap(try dynamic.get(forField: 1) as? Int32)
    XCTAssertEqual(value, 999, "Unknown enum value 999 must be preserved as raw Int32 by BinaryDeserializer")
  }
}
