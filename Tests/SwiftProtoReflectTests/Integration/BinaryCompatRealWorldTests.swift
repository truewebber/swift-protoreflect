// BinaryCompatRealWorldTests.swift
// SwiftProtoReflectTests
//
// Group: Real-World Message Patterns — bidirectional binary compatibility tests.
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
// Real-world patterns covered:
//   - Nullable oneofs (NullValue=0 vs actual value) — must produce different wire tags.
//   - Non-sequential field numbers (50, 71, 72, 100) — verify large field number tags.
//   - Reserved field numbers produce no wire bytes.
//   - ReportResponse deep nesting: Keyword with NullableDouble/NullableUint32 + tags.
//   - Proto3 optional message/WKT fields: absent vs set distinction via bytes.
//   - IntentHolder: packed repeated enum + map<string, enum>.
//   - NullableBool false vs null produce different binary wire bytes (different tag bytes).

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class BinaryCompatRealWorldTests: XCTestCase {

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

  // MARK: - 1. NullableUint32: null_val variant (oneof field 1, NullValue=0)

  func test_realworld_nullableUint32_null_bidirectional() async throws {
    var proto = Testcompat_NullableUint32()
    proto.nullVal = .nullValue  // oneof field 1, enum NullValue=0

    let desc = CompatDescriptors.nullableUint32()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        // field 1 = enum NullValue=0, stored as Int32(0) in DynamicMessage
        XCTAssertEqual(try msg.get(forField: 1) as? Int32, 0)
        XCTAssertNil(try msg.get(forField: 2))
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(0), forField: 1)  // null_val = NullValue = 0
        return d
      },
      validateProto: { p in
        if case .nullVal(let v) = p.kind {
          XCTAssertEqual(v, .nullValue)
        }
        else {
          XCTFail("expected nullVal case")
        }
      }
    )
  }

  // MARK: - 2. NullableUint32: value variant (oneof field 2, uint32=42)

  func test_realworld_nullableUint32_value_bidirectional() async throws {
    var proto = Testcompat_NullableUint32()
    proto.value = 42

    let desc = CompatDescriptors.nullableUint32()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 2) as? UInt32, 42)
        XCTAssertNil(try msg.get(forField: 1))
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(UInt32(42), forField: 2)
        return d
      },
      validateProto: { p in
        if case .value(let v) = p.kind {
          XCTAssertEqual(v, 42)
        }
        else {
          XCTFail("expected value case")
        }
      }
    )
  }

  // MARK: - 3. NullableDouble: null_val variant (oneof field 1, NullValue=0)

  func test_realworld_nullableDouble_null_bidirectional() async throws {
    var proto = Testcompat_NullableDouble()
    proto.nullVal = .nullValue

    let desc = CompatDescriptors.nullableDouble()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? Int32, 0)
        XCTAssertNil(try msg.get(forField: 2))
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(0), forField: 1)
        return d
      },
      validateProto: { p in
        if case .nullVal(let v) = p.kind {
          XCTAssertEqual(v, .nullValue)
        }
        else {
          XCTFail("expected nullVal case")
        }
      }
    )
  }

  // MARK: - 4. NullableDouble: value=3.14 (oneof field 2, 8-byte fixed IEEE 754)

  func test_realworld_nullableDouble_value_bidirectional() async throws {
    var proto = Testcompat_NullableDouble()
    proto.value = 3.14

    let desc = CompatDescriptors.nullableDouble()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 2) as? Double, 3.14)
        XCTAssertNil(try msg.get(forField: 1))
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Double(3.14), forField: 2)
        return d
      },
      validateProto: { p in
        if case .value(let v) = p.kind {
          XCTAssertEqual(v, 3.14, accuracy: 1e-10)
        }
        else {
          XCTFail("expected value case")
        }
      }
    )
  }

  // MARK: - 5. WithNullables: count.value=10, active.nullVal=0, label.value="label_val", name="outer"

  func test_realworld_withNullables_mixed_bidirectional() async throws {
    var proto = Testcompat_WithNullables()
    proto.count.value = 10
    proto.active.nullVal = .nullValue
    proto.label.value = "label_val"
    proto.name = "outer"

    let desc = CompatDescriptors.withNullables()
    let nullableUint32Desc = CompatDescriptors.nullableUint32()
    let nullableBoolDesc = CompatDescriptors.nullableBool()
    let nullableStringDesc = CompatDescriptors.nullableString()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let count = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
        XCTAssertEqual(try count.get(forField: 2) as? UInt32, 10)

        let active = try XCTUnwrap(try msg.get(forField: 3) as? DynamicMessage)
        XCTAssertEqual(try active.get(forField: 1) as? Int32, 0)

        let label = try XCTUnwrap(try msg.get(forField: 4) as? DynamicMessage)
        XCTAssertEqual(try label.get(forField: 2) as? String, "label_val")

        XCTAssertEqual(try msg.get(forField: 10) as? String, "outer")
        XCTAssertNil(try msg.get(forField: 2))  // rate not set
      },
      buildDynamic: {
        var countMsg = DynamicMessage(descriptor: nullableUint32Desc)
        try countMsg.set(UInt32(10), forField: 2)

        var activeMsg = DynamicMessage(descriptor: nullableBoolDesc)
        try activeMsg.set(Int32(0), forField: 1)  // null_val = NullValue = 0

        var labelMsg = DynamicMessage(descriptor: nullableStringDesc)
        try labelMsg.set("label_val", forField: 2)

        var d = DynamicMessage(descriptor: desc)
        try d.set(countMsg, forField: 1)
        try d.set(activeMsg, forField: 3)
        try d.set(labelMsg, forField: 4)
        try d.set("outer", forField: 10)
        return d
      },
      validateProto: { p in
        XCTAssertTrue(p.hasCount)
        if case .value(let v) = p.count.kind {
          XCTAssertEqual(v, 10)
        }
        else {
          XCTFail("expected count.value")
        }
        XCTAssertTrue(p.hasActive)
        if case .nullVal(let v) = p.active.kind {
          XCTAssertEqual(v, .nullValue)
        }
        else {
          XCTFail("expected active.nullVal")
        }
        XCTAssertTrue(p.hasLabel)
        if case .value(let v) = p.label.kind {
          XCTAssertEqual(v, "label_val")
        }
        else {
          XCTFail("expected label.value")
        }
        XCTAssertEqual(p.name, "outer")
        XCTAssertFalse(p.hasRate)
      }
    )
  }

  // MARK: - 6. NonSequentialFields: all fields with non-sequential and large field numbers

  func test_realworld_nonSequentialFields_bidirectional() async throws {
    var proto = Testcompat_NonSequentialFields()
    proto.name = "name_val"
    proto.code = 42
    proto.description_p = "desc_val"
    proto.bigNumber = 9_876_543_210
    proto.flag = true
    proto.createdAt.seconds = 1_000_000
    proto.createdAt.nanos = 0
    proto.updatedAt.seconds = 2_000_000
    proto.updatedAt.nanos = 500_000_000

    let desc = CompatDescriptors.nonSequentialFields()
    let tsDesc = CompatDescriptors.wktTimestamp()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? String, "name_val")
        XCTAssertEqual(try msg.get(forField: 2) as? Int32, 42)
        XCTAssertEqual(try msg.get(forField: 10) as? String, "desc_val")
        XCTAssertEqual(try msg.get(forField: 50) as? Int64, 9_876_543_210)
        XCTAssertEqual(try msg.get(forField: 100) as? Bool, true)
        let createdAt = try XCTUnwrap(try msg.get(forField: 71) as? DynamicMessage)
        XCTAssertEqual(try createdAt.get(forField: 1) as? Int64, 1_000_000)
        let updatedAt = try XCTUnwrap(try msg.get(forField: 72) as? DynamicMessage)
        XCTAssertEqual(try updatedAt.get(forField: 1) as? Int64, 2_000_000)
        XCTAssertEqual(try updatedAt.get(forField: 2) as? Int32, 500_000_000)
      },
      buildDynamic: {
        var createdAtMsg = DynamicMessage(descriptor: tsDesc)
        try createdAtMsg.set(Int64(1_000_000), forField: 1)

        var updatedAtMsg = DynamicMessage(descriptor: tsDesc)
        try updatedAtMsg.set(Int64(2_000_000), forField: 1)
        try updatedAtMsg.set(Int32(500_000_000), forField: 2)

        var d = DynamicMessage(descriptor: desc)
        try d.set("name_val", forField: 1)
        try d.set(Int32(42), forField: 2)
        try d.set("desc_val", forField: 10)
        try d.set(Int64(9_876_543_210), forField: 50)
        try d.set(true, forField: 100)
        try d.set(createdAtMsg, forField: 71)
        try d.set(updatedAtMsg, forField: 72)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.name, "name_val")
        XCTAssertEqual(p.code, 42)
        XCTAssertEqual(p.description_p, "desc_val")
        XCTAssertEqual(p.bigNumber, 9_876_543_210)
        XCTAssertTrue(p.flag)
        XCTAssertEqual(p.createdAt.seconds, 1_000_000)
        XCTAssertEqual(p.updatedAt.seconds, 2_000_000)
        XCTAssertEqual(p.updatedAt.nanos, 500_000_000)
      }
    )
  }

  // MARK: - 7. WithReserved: active fields only (reserved field numbers produce no bytes)

  func test_realworld_withReserved_activeFields_bidirectional() async throws {
    var proto = Testcompat_WithReserved()
    proto.name = "reserved_test"
    proto.version = 5
    proto.status = "active"
    proto.priority = 10

    let desc = CompatDescriptors.withReserved()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? String, "reserved_test")
        XCTAssertEqual(try msg.get(forField: 5) as? Int32, 5)
        XCTAssertEqual(try msg.get(forField: 9) as? String, "active")
        XCTAssertEqual(try msg.get(forField: 10) as? Int32, 10)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set("reserved_test", forField: 1)
        try d.set(Int32(5), forField: 5)
        try d.set("active", forField: 9)
        try d.set(Int32(10), forField: 10)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.name, "reserved_test")
        XCTAssertEqual(p.version, 5)
        XCTAssertEqual(p.status, "active")
        XCTAssertEqual(p.priority, 10)
      }
    )
  }

  // MARK: - 8. ReportResponse: basic fields + one keyword with tags

  func test_realworld_reportResponse_basic_bidirectional() async throws {
    var keyword = Testcompat_ReportResponse.Keyword()
    keyword.keyword = "swift"
    keyword.tags = ["ios", "mobile"]

    var proto = Testcompat_ReportResponse()
    proto.total = 100
    proto.limit = 10
    proto.offset = 0
    proto.keywords = [keyword]

    let desc = CompatDescriptors.reportResponse()
    let keywordDesc = try XCTUnwrap(desc.nestedMessage(named: "Keyword"))

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? UInt32, 100)
        XCTAssertEqual(try msg.get(forField: 2) as? UInt32, 10)
        let keywords = try XCTUnwrap(try msg.get(forField: 4) as? [DynamicMessage])
        XCTAssertEqual(keywords.count, 1)
        XCTAssertEqual(try keywords[0].get(forField: 1) as? String, "swift")
        XCTAssertEqual(try keywords[0].get(forField: 2) as? [String], ["ios", "mobile"])
      },
      buildDynamic: {
        var kw = DynamicMessage(descriptor: keywordDesc)
        try kw.set("swift", forField: 1)
        try kw.set(["ios", "mobile"] as [String], forField: 2)

        var d = DynamicMessage(descriptor: desc)
        try d.set(UInt32(100), forField: 1)
        try d.set(UInt32(10), forField: 2)
        try d.set([kw] as [DynamicMessage], forField: 4)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.total, 100)
        XCTAssertEqual(p.limit, 10)
        XCTAssertEqual(p.offset, 0)
        XCTAssertEqual(p.keywords.count, 1)
        XCTAssertEqual(p.keywords[0].keyword, "swift")
        XCTAssertEqual(p.keywords[0].tags, ["ios", "mobile"])
      }
    )
  }

  // MARK: - 9. DateValue: year=2024, month=3, day=15 (all varint fields)

  func test_realworld_dateValue_bidirectional() async throws {
    var proto = Testcompat_DateValue()
    proto.year = 2024
    proto.month = 3
    proto.day = 15

    let desc = CompatDescriptors.dateValue()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? Int32, 2024)
        XCTAssertEqual(try msg.get(forField: 2) as? Int32, 3)
        XCTAssertEqual(try msg.get(forField: 3) as? Int32, 15)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(2024), forField: 1)
        try d.set(Int32(3), forField: 2)
        try d.set(Int32(15), forField: 3)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.year, 2024)
        XCTAssertEqual(p.month, 3)
        XCTAssertEqual(p.day, 15)
      }
    )
  }

  // MARK: - 10. NullableBool: value=false (oneof field 2, binary encodes as varint 0)

  func test_realworld_nullableBool_false_bidirectional() async throws {
    var proto = Testcompat_NullableBool()
    proto.value = false  // explicitly sets oneof to .value(false)

    let desc = CompatDescriptors.nullableBool()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        // field 2 = bool false, stored in DynamicMessage
        XCTAssertEqual(try msg.get(forField: 2) as? Bool, false)
        XCTAssertNil(try msg.get(forField: 1))
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(false, forField: 2)
        return d
      },
      validateProto: { p in
        if case .value(let v) = p.kind {
          XCTAssertFalse(v)
        }
        else {
          XCTFail("expected value(false) case")
        }
      }
    )
  }

  // MARK: - 11. NullableString: value="hello_null" (oneof field 2, length-delimited)

  func test_realworld_nullableString_value_bidirectional() async throws {
    var proto = Testcompat_NullableString()
    proto.value = "hello_null"

    let desc = CompatDescriptors.nullableString()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 2) as? String, "hello_null")
        XCTAssertNil(try msg.get(forField: 1))
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set("hello_null", forField: 2)
        return d
      },
      validateProto: { p in
        if case .value(let v) = p.kind {
          XCTAssertEqual(v, "hello_null")
        }
        else {
          XCTFail("expected value(string) case")
        }
      }
    )
  }

  // MARK: - 12. NullableMessage: value=SimpleMessage(id=77, name="nullable_inner")

  func test_realworld_nullableMessage_value_bidirectional() async throws {
    var inner = Testcompat_SimpleMessage()
    inner.id = 77
    inner.name = "nullable_inner"

    var proto = Testcompat_NullableMessage()
    proto.value = inner

    let desc = CompatDescriptors.nullableMessage()
    let simpleDesc = CompatDescriptors.simpleMessage()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let value = try XCTUnwrap(try msg.get(forField: 2) as? DynamicMessage)
        XCTAssertEqual(try value.get(forField: 1) as? Int32, 77)
        XCTAssertEqual(try value.get(forField: 2) as? String, "nullable_inner")
        XCTAssertNil(try msg.get(forField: 1))
      },
      buildDynamic: {
        var simpleMsg = DynamicMessage(descriptor: simpleDesc)
        try simpleMsg.set(Int32(77), forField: 1)
        try simpleMsg.set("nullable_inner", forField: 2)

        var d = DynamicMessage(descriptor: desc)
        try d.set(simpleMsg, forField: 2)
        return d
      },
      validateProto: { p in
        if case .value(let v) = p.kind {
          XCTAssertEqual(v.id, 77)
          XCTAssertEqual(v.name, "nullable_inner")
        }
        else {
          XCTFail("expected value(SimpleMessage) case")
        }
      }
    )
  }

  // MARK: - 13. Unset oneof produces no wire bytes (Data())

  func test_realworld_nullable_unset_producesEmptyData() async throws {
    // Direction A: oracle with no variant set → serializedData() = Data()
    let proto = Testcompat_NullableUint32()  // kind = nil
    let referenceData = try proto.serializedData()
    XCTAssertEqual(referenceData, Data(), "oracle must produce empty bytes for unset oneof")

    // Direction B: our serializer with no fields set → Data()
    let desc = CompatDescriptors.nullableUint32()
    let dynamic = DynamicMessage(descriptor: desc)
    let ourData = try await serializer.serialize(dynamic)
    XCTAssertEqual(ourData, Data(), "BinarySerializer must produce empty bytes when no oneof variant is set")
  }

  // MARK: - 14. Proto3OptionalMessages: set optSimple (id=55) vs unset (no LEN tag)

  func test_realworld_proto3Optional_messageField_setVsUnset_bidirectional() async throws {
    let desc = CompatDescriptors.proto3OptionalMessages()
    let simpleDesc = CompatDescriptors.simpleMessage()

    // --- Set scenario: optSimple = SimpleMessage(id=55) ---
    var protoSet = Testcompat_Proto3OptionalMessages()
    protoSet.optSimple.id = 55

    try await BinaryCompatHelpers.assertBidirectional(
      proto: protoSet,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let optSimple = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
        XCTAssertEqual(try optSimple.get(forField: 1) as? Int32, 55)
      },
      buildDynamic: {
        var simpleMsg = DynamicMessage(descriptor: simpleDesc)
        try simpleMsg.set(Int32(55), forField: 1)
        var d = DynamicMessage(descriptor: desc)
        try d.set(simpleMsg, forField: 1)
        return d
      },
      validateProto: { p in
        XCTAssertTrue(p.hasOptSimple)
        XCTAssertEqual(p.optSimple.id, 55)
      }
    )

    // --- Unset scenario: optSimple not set → no field 1 bytes ---
    let protoUnset = Testcompat_Proto3OptionalMessages()
    XCTAssertFalse(protoUnset.hasOptSimple)
    let unsetData = try protoUnset.serializedData()

    // Field 1 tag = (1 << 3) | 2 = 0x0A; verify it's absent from the bytes
    XCTAssertFalse(
      unsetData.contains(0x0A),
      "unset optional message must produce no LEN tag in binary"
    )

    let dynamicUnset = DynamicMessage(descriptor: desc)
    let ourUnsetData = try await serializer.serialize(dynamicUnset)
    XCTAssertFalse(
      ourUnsetData.contains(0x0A),
      "BinarySerializer must produce no tag for unset optional message field"
    )
  }

  // MARK: - 15. Proto3OptionalMessages: set optTs (seconds=42) vs unset

  func test_realworld_proto3Optional_wktField_setVsUnset_bidirectional() async throws {
    let desc = CompatDescriptors.proto3OptionalMessages()
    let tsDesc = CompatDescriptors.wktTimestamp()

    // --- Set scenario: optTs = Timestamp(seconds=42) ---
    var protoSet = Testcompat_Proto3OptionalMessages()
    protoSet.optTs.seconds = 42

    try await BinaryCompatHelpers.assertBidirectional(
      proto: protoSet,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let optTs = try XCTUnwrap(try msg.get(forField: 3) as? DynamicMessage)
        XCTAssertEqual(try optTs.get(forField: 1) as? Int64, 42)
      },
      buildDynamic: {
        var tsMsg = DynamicMessage(descriptor: tsDesc)
        try tsMsg.set(Int64(42), forField: 1)
        var d = DynamicMessage(descriptor: desc)
        try d.set(tsMsg, forField: 3)
        return d
      },
      validateProto: { p in
        XCTAssertTrue(p.hasOptTs)
        XCTAssertEqual(p.optTs.seconds, 42)
      }
    )

    // --- Unset scenario: optTs not set → no field 3 LEN bytes ---
    let protoUnset = Testcompat_Proto3OptionalMessages()
    XCTAssertFalse(protoUnset.hasOptTs)
    let unsetData = try protoUnset.serializedData()

    // Field 3 tag = (3 << 3) | 2 = 0x1A; verify it's absent
    XCTAssertFalse(
      unsetData.contains(0x1A),
      "unset optional Timestamp field must produce no LEN tag in binary"
    )

    let dynamicUnset = DynamicMessage(descriptor: desc)
    let ourUnsetData = try await serializer.serialize(dynamicUnset)
    XCTAssertFalse(
      ourUnsetData.contains(0x1A),
      "BinarySerializer must produce no tag for unset optional Timestamp field"
    )
  }

  // MARK: - 16. IntentHolder: intent=8 (COMMERCIAL), allIntents packed, byName map

  func test_realworld_intentHolder_allIntentFlags_bidirectional() async throws {
    var proto = Testcompat_IntentHolder()
    proto.intent = .intentCommercial  // 8
    proto.allIntents = [
      .intentDefault, .intentInformational, .intentNavigational,
      .intentTransactional, .intentCommercial,
    ]
    proto.byName = ["commercial": .intentCommercial, "info": .intentInformational]

    let desc = CompatDescriptors.intentHolder()
    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? Int32, 8)
        let allIntents = try XCTUnwrap(try msg.get(forField: 2) as? [Int32])
        XCTAssertEqual(allIntents, [0, 1, 2, 4, 8])
        let byName = try XCTUnwrap(try msg.get(forField: 3) as? [AnyHashable: Any])
        XCTAssertEqual(byName["commercial"] as? Int32, 8)
        XCTAssertEqual(byName["info"] as? Int32, 1)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(8), forField: 1)
        try d.set([Int32(0), Int32(1), Int32(2), Int32(4), Int32(8)] as [Int32], forField: 2)
        try d.setMapEntry(Int32(8), forKey: "commercial", inField: 3)
        try d.setMapEntry(Int32(1), forKey: "info", inField: 3)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.intent, .intentCommercial)
        XCTAssertEqual(
          p.allIntents,
          [
            .intentDefault, .intentInformational, .intentNavigational,
            .intentTransactional, .intentCommercial,
          ]
        )
        XCTAssertEqual(p.byName["commercial"], .intentCommercial)
        XCTAssertEqual(p.byName["info"], .intentInformational)
      }
    )
  }

  // MARK: - 17. WithNullables: all five nested fields + name set

  func test_realworld_withNullables_allSet_bidirectional() async throws {
    var inner = Testcompat_SimpleMessage()
    inner.id = 1
    inner.name = "inner_detail"

    var proto = Testcompat_WithNullables()
    proto.count.value = 99
    proto.rate.value = 2.71828
    proto.active.value = true
    proto.label.value = "all_set_label"
    proto.detail.value = inner
    proto.name = "all_set"

    let desc = CompatDescriptors.withNullables()
    let nullableUint32Desc = CompatDescriptors.nullableUint32()
    let nullableDoubleDesc = CompatDescriptors.nullableDouble()
    let nullableBoolDesc = CompatDescriptors.nullableBool()
    let nullableStringDesc = CompatDescriptors.nullableString()
    let nullableMessageDesc = CompatDescriptors.nullableMessage()
    let simpleDesc = CompatDescriptors.simpleMessage()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let count = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
        XCTAssertEqual(try count.get(forField: 2) as? UInt32, 99)

        let rate = try XCTUnwrap(try msg.get(forField: 2) as? DynamicMessage)
        let rateVal = try XCTUnwrap(try rate.get(forField: 2) as? Double)
        XCTAssertEqual(rateVal, 2.71828, accuracy: 1e-5)

        let active = try XCTUnwrap(try msg.get(forField: 3) as? DynamicMessage)
        XCTAssertEqual(try active.get(forField: 2) as? Bool, true)

        let label = try XCTUnwrap(try msg.get(forField: 4) as? DynamicMessage)
        XCTAssertEqual(try label.get(forField: 2) as? String, "all_set_label")

        let detail = try XCTUnwrap(try msg.get(forField: 5) as? DynamicMessage)
        let detailValue = try XCTUnwrap(try detail.get(forField: 2) as? DynamicMessage)
        XCTAssertEqual(try detailValue.get(forField: 1) as? Int32, 1)
        XCTAssertEqual(try detailValue.get(forField: 2) as? String, "inner_detail")

        XCTAssertEqual(try msg.get(forField: 10) as? String, "all_set")
      },
      buildDynamic: {
        var countMsg = DynamicMessage(descriptor: nullableUint32Desc)
        try countMsg.set(UInt32(99), forField: 2)

        var rateMsg = DynamicMessage(descriptor: nullableDoubleDesc)
        try rateMsg.set(Double(2.71828), forField: 2)

        var activeMsg = DynamicMessage(descriptor: nullableBoolDesc)
        try activeMsg.set(true, forField: 2)

        var labelMsg = DynamicMessage(descriptor: nullableStringDesc)
        try labelMsg.set("all_set_label", forField: 2)

        var innerSimple = DynamicMessage(descriptor: simpleDesc)
        try innerSimple.set(Int32(1), forField: 1)
        try innerSimple.set("inner_detail", forField: 2)

        var detailMsg = DynamicMessage(descriptor: nullableMessageDesc)
        try detailMsg.set(innerSimple, forField: 2)

        var d = DynamicMessage(descriptor: desc)
        try d.set(countMsg, forField: 1)
        try d.set(rateMsg, forField: 2)
        try d.set(activeMsg, forField: 3)
        try d.set(labelMsg, forField: 4)
        try d.set(detailMsg, forField: 5)
        try d.set("all_set", forField: 10)
        return d
      },
      validateProto: { p in
        XCTAssertTrue(p.hasCount)
        XCTAssertTrue(p.hasRate)
        XCTAssertTrue(p.hasActive)
        XCTAssertTrue(p.hasLabel)
        XCTAssertTrue(p.hasDetail)
        if case .value(let v) = p.count.kind {
          XCTAssertEqual(v, 99)
        }
        else {
          XCTFail("expected count.value")
        }
        if case .value(let v) = p.rate.kind {
          XCTAssertEqual(v, 2.71828, accuracy: 1e-5)
        }
        else {
          XCTFail("expected rate.value")
        }
        if case .value(let v) = p.active.kind {
          XCTAssertTrue(v)
        }
        else {
          XCTFail("expected active.value")
        }
        if case .value(let v) = p.label.kind {
          XCTAssertEqual(v, "all_set_label")
        }
        else {
          XCTFail("expected label.value")
        }
        if case .value(let v) = p.detail.kind {
          XCTAssertEqual(v.id, 1)
          XCTAssertEqual(v.name, "inner_detail")
        }
        else {
          XCTFail("expected detail.value")
        }
        XCTAssertEqual(p.name, "all_set")
      }
    )
  }

  // MARK: - 18. ReportResponse: keyword with cpc NullableDouble + volume NullableUint32 + tags

  func test_realworld_reportResponse_deepSiblingDefs_bidirectional() async throws {
    var cpc = Testcompat_NullableDouble()
    cpc.value = 1.5

    var volume = Testcompat_NullableUint32()
    volume.value = 500

    var keyword = Testcompat_ReportResponse.Keyword()
    keyword.keyword = "deep_kw"
    keyword.tags = ["seo", "paid"]
    keyword.cpc = cpc
    keyword.volume = volume

    var proto = Testcompat_ReportResponse()
    proto.total = 1
    proto.keywords = [keyword]

    let desc = CompatDescriptors.reportResponse()
    let keywordDesc = try XCTUnwrap(desc.nestedMessage(named: "Keyword"))
    let nullableDoubleDesc = CompatDescriptors.nullableDouble()
    let nullableUint32Desc = CompatDescriptors.nullableUint32()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let keywords = try XCTUnwrap(try msg.get(forField: 4) as? [DynamicMessage])
        XCTAssertEqual(keywords.count, 1)
        let kw = keywords[0]
        XCTAssertEqual(try kw.get(forField: 1) as? String, "deep_kw")
        XCTAssertEqual(try kw.get(forField: 2) as? [String], ["seo", "paid"])

        // cpc = NullableDouble at field 3
        let cpcMsg = try XCTUnwrap(try kw.get(forField: 3) as? DynamicMessage)
        let cpcVal = try XCTUnwrap(try cpcMsg.get(forField: 2) as? Double)
        XCTAssertEqual(cpcVal, 1.5, accuracy: 1e-10)

        // volume = NullableUint32 at field 4
        let volMsg = try XCTUnwrap(try kw.get(forField: 4) as? DynamicMessage)
        XCTAssertEqual(try volMsg.get(forField: 2) as? UInt32, 500)
      },
      buildDynamic: {
        var cpcMsg = DynamicMessage(descriptor: nullableDoubleDesc)
        try cpcMsg.set(Double(1.5), forField: 2)

        var volMsg = DynamicMessage(descriptor: nullableUint32Desc)
        try volMsg.set(UInt32(500), forField: 2)

        var kw = DynamicMessage(descriptor: keywordDesc)
        try kw.set("deep_kw", forField: 1)
        try kw.set(["seo", "paid"] as [String], forField: 2)
        try kw.set(cpcMsg, forField: 3)
        try kw.set(volMsg, forField: 4)

        var d = DynamicMessage(descriptor: desc)
        try d.set(UInt32(1), forField: 1)
        try d.set([kw] as [DynamicMessage], forField: 4)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.total, 1)
        XCTAssertEqual(p.keywords.count, 1)
        XCTAssertEqual(p.keywords[0].keyword, "deep_kw")
        XCTAssertEqual(p.keywords[0].tags, ["seo", "paid"])
        XCTAssertTrue(p.keywords[0].hasCpc)
        if case .value(let v) = p.keywords[0].cpc.kind {
          XCTAssertEqual(v, 1.5, accuracy: 1e-10)
        }
        else {
          XCTFail("expected cpc.value")
        }
        XCTAssertTrue(p.keywords[0].hasVolume)
        if case .value(let v) = p.keywords[0].volume.kind {
          XCTAssertEqual(v, 500)
        }
        else {
          XCTFail("expected volume.value")
        }
      }
    )
  }

  // MARK: - 19. NullableBool: false (field 2) vs null (field 1) — different wire tags

  func test_realworld_nullableBool_false_vs_null_binaryDistinct() async throws {
    let desc = CompatDescriptors.nullableBool()

    // false: oneof field 2 (bool), tag = (2 << 3) | 0 = 0x10
    var falseMsg = DynamicMessage(descriptor: desc)
    try falseMsg.set(false, forField: 2)
    let falseData = try await serializer.serialize(falseMsg)

    // null: oneof field 1 (enum NullValue=0), tag = (1 << 3) | 0 = 0x08
    var nullMsg = DynamicMessage(descriptor: desc)
    try nullMsg.set(Int32(0), forField: 1)
    let nullData = try await serializer.serialize(nullMsg)

    XCTAssertNotEqual(falseData, nullData, "false and null variants must produce different wire bytes")

    // Verify the tag bytes explicitly:
    // null_val tag: 0x08 (field 1, varint), value: 0x00
    XCTAssertTrue(nullData.starts(with: Data([0x08, 0x00])), "null variant tag must be 0x08")
    // value tag: 0x10 (field 2, varint), value: 0x00
    XCTAssertTrue(falseData.starts(with: Data([0x10, 0x00])), "false variant tag must be 0x10")

    // Also verify oracle round-trip for null:
    let oracleNull = try Testcompat_NullableBool(serializedBytes: nullData)
    if case .nullVal(let v) = oracleNull.kind {
      XCTAssertEqual(v, .nullValue)
    }
    else {
      XCTFail("expected nullVal case from null bytes")
    }

    // Oracle round-trip for false:
    let oracleFalse = try Testcompat_NullableBool(serializedBytes: falseData)
    if case .value(let v) = oracleFalse.kind {
      XCTAssertFalse(v)
    }
    else {
      XCTFail("expected value(false) case from false bytes")
    }
  }

  // MARK: - 20. NonSequentialFields: flag at field 100 encodes as varint tag 0xA0 0x06

  func test_realworld_nonSequentialFields_largeFieldNumber_wireTag() async throws {
    let desc = CompatDescriptors.nonSequentialFields()

    // Direction B only: build DynamicMessage with only flag=true set
    var d = DynamicMessage(descriptor: desc)
    try d.set(true, forField: 100)
    let data = try await serializer.serialize(d)

    // flag at field 100, wire type 0 (varint): tag = (100 << 3) | 0 = 800
    // Varint(800): 800 = 0x320; low 7 bits = 0x20 with continuation = 0xA0; next 7 bits = 0x06
    // So tag bytes = [0xA0, 0x06], then bool true = [0x01]
    let tagBytes = Data([0xA0, 0x06])
    XCTAssertTrue(
      data.starts(with: tagBytes),
      "field 100 tag must be 0xA0 0x06 (varint 800), got: \(data.map { String(format: "%02X", $0) }.joined(separator: " "))"
    )
    XCTAssertEqual(data.count, 3, "flag=true at field 100 must be exactly 3 bytes: tag(2) + value(1)")

    // Also verify oracle parse:
    let oracle = try Testcompat_NonSequentialFields(serializedBytes: data)
    XCTAssertTrue(oracle.flag)
    XCTAssertEqual(oracle.name, "")  // other fields are absent
  }

  // MARK: - 21. WithNullables with no fields set → empty Data()

  func test_realworld_withNullables_allUnset_producesEmptyData() async throws {
    // Direction A: oracle with no fields set → serializedData() = Data()
    let proto = Testcompat_WithNullables()
    let referenceData = try proto.serializedData()
    XCTAssertEqual(referenceData, Data(), "oracle must produce empty bytes for all-unset WithNullables")

    // Direction B: our serializer with no fields set → Data()
    let desc = CompatDescriptors.withNullables()
    let dynamic = DynamicMessage(descriptor: desc)
    let ourData = try await serializer.serialize(dynamic)
    XCTAssertEqual(ourData, Data(), "BinarySerializer must produce empty bytes for all-unset WithNullables")
  }
}
