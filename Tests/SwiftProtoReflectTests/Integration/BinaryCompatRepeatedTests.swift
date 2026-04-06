// BinaryCompatRepeatedTests.swift
// SwiftProtoReflectTests
//
// Group: Repeated Fields — bidirectional binary compatibility tests.
//
// Oracle strategy: Option A — swift-protobuf generated types (.pb.swift).
//
// Pattern (mirrors BinaryCompatScalarsTests):
//   Direction A (oracle → us):
//     1. Build Testcompat_RepeatedAllTypes (generated), call serializedData() → referenceData.
//     2. Deserialize referenceData via BinaryDeserializer + CompatDescriptors → DynamicMessage.
//     3. Assert field values on DynamicMessage.
//   Direction B (us → oracle):
//     1. Build DynamicMessage via CompatDescriptors, call BinarySerializer.serialize() → ourData.
//     2. Parse ourData via Testcompat_RepeatedAllTypes(serializedBytes:) → generated message.
//     3. Assert field values on generated message.
//
// Binary-specific notes:
//   - All scalar repeated fields use packed encoding in proto3 (wire type 2).
//   - String and bytes repeated fields use unpacked encoding (one LEN segment per element).
//   - Nested message repeated fields use unpacked encoding (one LEN segment per element).
//   - Empty repeated field produces zero wire bytes (no tag, no length, no payload).

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class BinaryCompatRepeatedTests: XCTestCase {

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

  // MARK: - 1. Repeated int32 packed encoding

  func test_repeated_int32_packedEncoding_bidirectional() async throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repInt32 = [1, -1, 0, Int32.max, Int32.min]

    let desc = CompatDescriptors.repeatedAllTypes()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let vals = try XCTUnwrap(try msg.get(forField: 3) as? [Int32])
        XCTAssertEqual(vals, [1, -1, 0, Int32.max, Int32.min])
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set([Int32(1), Int32(-1), Int32(0), Int32.max, Int32.min] as [Int32], forField: 3)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.repInt32, [1, -1, 0, Int32.max, Int32.min])
      }
    )
  }

  // MARK: - 2. Repeated int64 packed encoding

  func test_repeated_int64_bidirectional() async throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repInt64 = [Int64.max, Int64.min, 0, 9_000_000_000]

    let desc = CompatDescriptors.repeatedAllTypes()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let vals = try XCTUnwrap(try msg.get(forField: 4) as? [Int64])
        XCTAssertEqual(vals, [Int64.max, Int64.min, 0, 9_000_000_000])
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set([Int64.max, Int64.min, Int64(0), Int64(9_000_000_000)] as [Int64], forField: 4)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.repInt64, [Int64.max, Int64.min, 0, 9_000_000_000])
      }
    )
  }

  // MARK: - 3. Repeated uint64 packed encoding

  func test_repeated_uint64_bidirectional() async throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repUint64 = [UInt64.max, 0, 18_000_000_000]

    let desc = CompatDescriptors.repeatedAllTypes()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let vals = try XCTUnwrap(try msg.get(forField: 6) as? [UInt64])
        XCTAssertEqual(vals, [UInt64.max, 0, 18_000_000_000])
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set([UInt64.max, UInt64(0), UInt64(18_000_000_000)] as [UInt64], forField: 6)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.repUint64, [UInt64.max, 0, 18_000_000_000])
      }
    )
  }

  // MARK: - 4. Repeated signed types: sint32, sint64, sfixed32, sfixed64

  func test_repeated_allSignedTypes_bidirectional() async throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repSint32 = [-100, 0, 100, Int32.min, Int32.max]
    proto.repSint64 = [-9_000_000_000, 0, 9_000_000_000]
    proto.repSfixed32 = [Int32.min, -1, 0, 1, Int32.max]
    proto.repSfixed64 = [Int64.min, 0, Int64.max]

    let desc = CompatDescriptors.repeatedAllTypes()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 7) as? [Int32], [-100, 0, 100, Int32.min, Int32.max])
        XCTAssertEqual(try msg.get(forField: 8) as? [Int64], [-9_000_000_000, 0, 9_000_000_000])
        XCTAssertEqual(try msg.get(forField: 11) as? [Int32], [Int32.min, -1, 0, 1, Int32.max])
        XCTAssertEqual(try msg.get(forField: 12) as? [Int64], [Int64.min, 0, Int64.max])
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set([-100, 0, 100, Int32.min, Int32.max] as [Int32], forField: 7)
        try d.set([-9_000_000_000, 0, 9_000_000_000] as [Int64], forField: 8)
        try d.set([Int32.min, -1, 0, 1, Int32.max] as [Int32], forField: 11)
        try d.set([Int64.min, 0, Int64.max] as [Int64], forField: 12)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.repSint32, [-100, 0, 100, Int32.min, Int32.max])
        XCTAssertEqual(p.repSint64, [-9_000_000_000, 0, 9_000_000_000])
        XCTAssertEqual(p.repSfixed32, [Int32.min, -1, 0, 1, Int32.max])
        XCTAssertEqual(p.repSfixed64, [Int64.min, 0, Int64.max])
      }
    )
  }

  // MARK: - 5. Repeated fixed types: fixed32, fixed64, uint32

  func test_repeated_allFixedTypes_bidirectional() async throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repFixed32 = [0, 1, UInt32.max]
    proto.repFixed64 = [0, 1, UInt64.max]
    proto.repUint32 = [0, 1, UInt32.max]

    let desc = CompatDescriptors.repeatedAllTypes()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 9) as? [UInt32], [0, 1, UInt32.max])
        XCTAssertEqual(try msg.get(forField: 10) as? [UInt64], [0, 1, UInt64.max])
        XCTAssertEqual(try msg.get(forField: 5) as? [UInt32], [0, 1, UInt32.max])
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set([UInt32(0), UInt32(1), UInt32.max] as [UInt32], forField: 9)
        try d.set([UInt64(0), UInt64(1), UInt64.max] as [UInt64], forField: 10)
        try d.set([UInt32(0), UInt32(1), UInt32.max] as [UInt32], forField: 5)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.repFixed32, [0, 1, UInt32.max])
        XCTAssertEqual(p.repFixed64, [0, 1, UInt64.max])
        XCTAssertEqual(p.repUint32, [0, 1, UInt32.max])
      }
    )
  }

  // MARK: - 6. Repeated string (unpacked, one LEN segment per element)

  func test_repeated_string_withEmptyAndUnicode_bidirectional() async throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repString = ["", "hello", "Привет", "🎉", "中文", ""]

    let desc = CompatDescriptors.repeatedAllTypes()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 14) as? [String], ["", "hello", "Привет", "🎉", "中文", ""])
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(["", "hello", "Привет", "🎉", "中文", ""] as [String], forField: 14)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.repString, ["", "hello", "Привет", "🎉", "中文", ""])
      }
    )
  }

  // MARK: - 7. Repeated bytes (unpacked, one LEN segment per element)

  func test_repeated_bytes_bidirectional() async throws {
    let b1 = Data([0x01, 0x02])
    let b2 = Data()
    let b3 = Data([0xFF, 0x00, 0x7F])

    var proto = Testcompat_RepeatedAllTypes()
    proto.repBytes = [b1, b2, b3]

    let desc = CompatDescriptors.repeatedAllTypes()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let vals = try XCTUnwrap(try msg.get(forField: 15) as? [Data])
        XCTAssertEqual(vals, [b1, b2, b3])
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set([b1, b2, b3] as [Data], forField: 15)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.repBytes, [b1, b2, b3])
      }
    )
  }

  // MARK: - 8. Repeated double special values (packed, 8-byte IEEE 754 each)

  func test_repeated_double_specialValues_bidirectional() async throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repDouble = [Double.nan, Double.infinity, -Double.infinity]

    let desc = CompatDescriptors.repeatedAllTypes()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let vals = try XCTUnwrap(try msg.get(forField: 1) as? [Double])
        XCTAssertEqual(vals.count, 3)
        XCTAssertTrue(vals[0].isNaN)
        XCTAssertTrue(vals[1].isInfinite && vals[1] > 0)
        XCTAssertTrue(vals[2].isInfinite && vals[2] < 0)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set([Double.nan, Double.infinity, -Double.infinity] as [Double], forField: 1)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.repDouble.count, 3)
        XCTAssertTrue(p.repDouble[0].isNaN)
        XCTAssertTrue(p.repDouble[1].isInfinite && p.repDouble[1] > 0)
        XCTAssertTrue(p.repDouble[2].isInfinite && p.repDouble[2] < 0)
      }
    )
  }

  // MARK: - 9. Repeated float special values (packed, 4-byte IEEE 754 each)

  func test_repeated_float_specialValues_bidirectional() async throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repFloat = [Float.nan, Float.infinity, -Float.infinity]

    let desc = CompatDescriptors.repeatedAllTypes()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let vals = try XCTUnwrap(try msg.get(forField: 2) as? [Float])
        XCTAssertEqual(vals.count, 3)
        XCTAssertTrue(vals[0].isNaN)
        XCTAssertTrue(vals[1].isInfinite && vals[1] > 0)
        XCTAssertTrue(vals[2].isInfinite && vals[2] < 0)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set([Float.nan, Float.infinity, -Float.infinity] as [Float], forField: 2)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.repFloat.count, 3)
        XCTAssertTrue(p.repFloat[0].isNaN)
        XCTAssertTrue(p.repFloat[1].isInfinite && p.repFloat[1] > 0)
        XCTAssertTrue(p.repFloat[2].isInfinite && p.repFloat[2] < 0)
      }
    )
  }

  // MARK: - 10. Repeated bool packed (varint 0 or 1 per element)

  func test_repeated_bool_bidirectional() async throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repBool = [true, false, true, true, false]

    let desc = CompatDescriptors.repeatedAllTypes()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 13) as? [Bool], [true, false, true, true, false])
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set([true, false, true, true, false] as [Bool], forField: 13)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.repBool, [true, false, true, true, false])
      }
    )
  }

  // MARK: - 11. Repeated nested message (unpacked, one LEN segment per element)

  func test_repeated_nestedMessage_bidirectional() async throws {
    var m1 = Testcompat_SimpleMessage()
    m1.id = 1
    m1.name = "first"
    var m2 = Testcompat_SimpleMessage()
    m2.id = 2
    m2.name = "second"

    var proto = Testcompat_RepeatedAllTypes()
    proto.repSimple = [m1, m2]

    let desc = CompatDescriptors.repeatedAllTypes()
    let simpleDesc = CompatDescriptors.simpleMessage()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let msgs = try XCTUnwrap(try msg.get(forField: 18) as? [DynamicMessage])
        XCTAssertEqual(msgs.count, 2)
        XCTAssertEqual(try msgs[0].get(forField: 1) as? Int32, 1)
        XCTAssertEqual(try msgs[0].get(forField: 2) as? String, "first")
        XCTAssertEqual(try msgs[1].get(forField: 1) as? Int32, 2)
        XCTAssertEqual(try msgs[1].get(forField: 2) as? String, "second")
      },
      buildDynamic: {
        var inner1 = DynamicMessage(descriptor: simpleDesc)
        try inner1.set(Int32(1), forField: 1)
        try inner1.set("first", forField: 2)
        var inner2 = DynamicMessage(descriptor: simpleDesc)
        try inner2.set(Int32(2), forField: 1)
        try inner2.set("second", forField: 2)
        var d = DynamicMessage(descriptor: desc)
        try d.set([inner1, inner2] as [DynamicMessage], forField: 18)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.repSimple.count, 2)
        XCTAssertEqual(p.repSimple[0].id, 1)
        XCTAssertEqual(p.repSimple[0].name, "first")
        XCTAssertEqual(p.repSimple[1].id, 2)
        XCTAssertEqual(p.repSimple[1].name, "second")
      }
    )
  }

  // MARK: - 12. Repeated enum packed (varint per element)

  func test_repeated_enum_bidirectional() async throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repEnum = [.active, .inactive, .deleted, .unspecified]

    let desc = CompatDescriptors.repeatedAllTypes()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let vals = try XCTUnwrap(try msg.get(forField: 17) as? [Int32])
        XCTAssertEqual(vals, [1, 2, 3, 0])
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set([Int32(1), Int32(2), Int32(3), Int32(0)] as [Int32], forField: 17)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.repEnum, [.active, .inactive, .deleted, .unspecified])
      }
    )
  }

  // MARK: - 13. Empty repeated field produces no wire output

  func test_repeated_empty_producesNoWireOutput() async throws {
    // Direction A: swift-protobuf with empty repeated fields → serializedData() = Data()
    let proto = Testcompat_RepeatedAllTypes()
    let referenceData = try proto.serializedData()
    XCTAssertEqual(referenceData, Data(), "swift-protobuf must produce empty bytes for all-empty repeated fields")

    // Direction B: our serializer with no repeated fields set → Data()
    let desc = CompatDescriptors.repeatedAllTypes()
    let dynamic = DynamicMessage(descriptor: desc)
    let ourData = try await serializer.serialize(dynamic)
    XCTAssertEqual(ourData, Data(), "BinarySerializer must produce empty bytes when no repeated fields are set")
  }

  // MARK: - 14. Large array (100 elements) packed encoding

  func test_repeated_largeArray_100elements_bidirectional() async throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repInt32 = (1...100).map { Int32($0) }

    let desc = CompatDescriptors.repeatedAllTypes()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let vals = try XCTUnwrap(try msg.get(forField: 3) as? [Int32])
        XCTAssertEqual(vals.count, 100)
        XCTAssertEqual(vals[0], 1)
        XCTAssertEqual(vals[99], 100)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set((1...100).map { Int32($0) } as [Int32], forField: 3)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.repInt32.count, 100)
        XCTAssertEqual(p.repInt32[0], 1)
        XCTAssertEqual(p.repInt32[99], 100)
      }
    )
  }

  // MARK: - 15. Exact packed wire bytes for int32 [1, 2, 3] in field 3

  func test_repeated_int32_exactPackedWireBytes() async throws {
    // Field 3 (int32, repeated) uses packed encoding in proto3.
    // Tag = (3 << 3) | 2 = 0x1A (field 3, wire type 2 = LEN)
    // Length varint = 3 (three 1-byte varints follow)
    // Values: 1 → 0x01, 2 → 0x02, 3 → 0x03
    // Expected wire bytes: 0x1A 0x03 0x01 0x02 0x03
    let expected = Data([0x1A, 0x03, 0x01, 0x02, 0x03])

    // Verify swift-protobuf produces the same bytes (oracle).
    var proto = Testcompat_RepeatedAllTypes()
    proto.repInt32 = [1, 2, 3]
    XCTAssertEqual(
      try proto.serializedData(),
      expected,
      "swift-protobuf oracle: [1,2,3] in int32 packed field 3 must match expected wire bytes"
    )

    // Verify our serializer produces the same bytes (Direction B).
    let desc = CompatDescriptors.repeatedAllTypes()
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set([Int32(1), Int32(2), Int32(3)] as [Int32], forField: 3)
    let _asyncResult19 = try await serializer.serialize(dynamic)
    XCTAssertEqual(
      _asyncResult19,
      expected,
      "BinarySerializer: [1,2,3] in int32 packed field 3 must produce 0x1A 0x03 0x01 0x02 0x03"
    )
  }

  // MARK: - 16. Single-element repeated int32 (packed still applies)

  func test_repeated_singleElement_bidirectional() async throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repInt32 = [42]

    let desc = CompatDescriptors.repeatedAllTypes()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let vals = try XCTUnwrap(try msg.get(forField: 3) as? [Int32])
        XCTAssertEqual(vals, [42])
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set([Int32(42)] as [Int32], forField: 3)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.repInt32, [42])
      }
    )
  }
}
