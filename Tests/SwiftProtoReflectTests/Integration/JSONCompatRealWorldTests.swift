// JSONCompatRealWorldTests.swift
// SwiftProtoReflectTests
//
// Group 12: Real-World Patterns — nullable, non-sequential, reserved fields, etc.
// Bidirectional JSON compatibility tests.
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class JSONCompatRealWorldTests: XCTestCase {

  private var registry: TypeRegistry!

  override func setUp() {
    super.setUp()
    registry = try? CompatDescriptors.fullRegistry()
  }

  override func tearDown() {
    registry = nil
    super.tearDown()
  }

  // MARK: - Nullable oneof + NullValue pattern

  func test_realworld_nullableUint32_null_bidirectional() throws {
    var proto = Testcompat_NullableUint32()
    proto.nullVal = .nullValue

    let desc = CompatDescriptors.nullableUint32()

    // Direction A: protoc → us (NullValue deserialized from JSON null literal)
    let jsonStr = try proto.jsonString()
    guard let jsonData = jsonStr.data(using: .utf8) else { throw CompatError.jsonEncodingFailed }
    let deserialized = try CompatHelpers.makeDeserializer(registry: registry).deserialize(jsonData, using: desc)
    XCTAssertEqual(try deserialized.get(forField: 1) as? Int32, 0, "null_val should be 0 (NULL_VALUE)")
    XCTAssertNil(try deserialized.get(forField: 2) as? UInt32, "value field should not be set")

    // Direction B: our serializer → protoc (works - we can round-trip via protoc)
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(0), forField: 1)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_NullableUint32.self)
    { decoded in
      if case .nullVal = decoded.kind {
      }
      else {
        XCTFail("expected null variant")
      }
    }
  }

  func test_realworld_nullableUint32_value_bidirectional() throws {
    var proto = Testcompat_NullableUint32()
    proto.value = 42

    let desc = CompatDescriptors.nullableUint32()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 2) as? UInt32, 42)
      XCTAssertNil(try msg.get(forField: 1) as? Int32)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(UInt32(42), forField: 2)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_NullableUint32.self)
    { decoded in
      if case .value(let v) = decoded.kind {
        XCTAssertEqual(v, 42)
      }
      else {
        XCTFail("expected value variant")
      }
    }
  }

  func test_realworld_nullableDouble_null_bidirectional() throws {
    var proto = Testcompat_NullableDouble()
    proto.nullVal = .nullValue

    let desc = CompatDescriptors.nullableDouble()

    // Direction A: protoc → us (NullValue deserialized from JSON null literal)
    let jsonStr2 = try proto.jsonString()
    guard let jsonData2 = jsonStr2.data(using: .utf8) else { throw CompatError.jsonEncodingFailed }
    let deserialized2 = try CompatHelpers.makeDeserializer(registry: registry).deserialize(jsonData2, using: desc)
    XCTAssertEqual(try deserialized2.get(forField: 1) as? Int32, 0, "null_val should be 0 (NULL_VALUE)")
    XCTAssertNil(try deserialized2.get(forField: 2) as? Double, "value field should not be set")

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(0), forField: 1)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_NullableDouble.self)
    { decoded in
      if case .nullVal = decoded.kind {
      }
      else {
        XCTFail("expected null")
      }
    }
  }

  func test_realworld_nullableDouble_value_bidirectional() throws {
    var proto = Testcompat_NullableDouble()
    proto.value = 3.14

    let desc = CompatDescriptors.nullableDouble()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 2) as? Double, 3.14)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Double(3.14), forField: 2)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_NullableDouble.self)
    { decoded in
      if case .value(let v) = decoded.kind {
        XCTAssertEqual(v, 3.14)
      }
      else {
        XCTFail("expected value")
      }
    }
  }

  // MARK: - WithNullables: multiple nullable fields

  func test_realworld_withNullables_mixed_bidirectional() throws {
    var proto = Testcompat_WithNullables()
    proto.count.value = 10
    proto.active.nullVal = .nullValue
    proto.label.value = "label_val"
    proto.name = "outer"

    let desc = CompatDescriptors.withNullables()

    // Direction A: protoc → us (WithNullables containing NullableBool.nullVal = JSON null)
    let jsonStrW = try proto.jsonString()
    guard let jsonDataW = jsonStrW.data(using: .utf8) else { throw CompatError.jsonEncodingFailed }
    let deserializedW = try CompatHelpers.makeDeserializer(registry: registry).deserialize(jsonDataW, using: desc)
    let countMsg = try XCTUnwrap(try deserializedW.get(forField: 1) as? DynamicMessage, "count must be set")
    XCTAssertEqual(try countMsg.get(forField: 2) as? UInt32, 10, "count.value should be 10")
    let activeMsg = try XCTUnwrap(try deserializedW.get(forField: 3) as? DynamicMessage, "active must be set")
    XCTAssertEqual(try activeMsg.get(forField: 1) as? Int32, 0, "active.null_val should be 0 (NULL_VALUE)")
    let labelMsg = try XCTUnwrap(try deserializedW.get(forField: 4) as? DynamicMessage, "label must be set")
    XCTAssertEqual(try labelMsg.get(forField: 2) as? String, "label_val", "label.value should be 'label_val'")
    XCTAssertEqual(try deserializedW.get(forField: 10) as? String, "outer", "name should be 'outer'")

    let nullableUint32Desc = CompatDescriptors.nullableUint32()
    var countDyn = DynamicMessage(descriptor: nullableUint32Desc)
    try countDyn.set(UInt32(10), forField: 2)

    let nullableBoolDesc = CompatDescriptors.nullableBool()
    var activeDyn = DynamicMessage(descriptor: nullableBoolDesc)
    try activeDyn.set(Int32(0), forField: 1)

    let nullableStringDesc = CompatDescriptors.nullableString()
    var labelDyn = DynamicMessage(descriptor: nullableStringDesc)
    try labelDyn.set("label_val", forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(countDyn, forField: 1)
    try dynamic.set(activeDyn, forField: 3)
    try dynamic.set(labelDyn, forField: 4)
    try dynamic.set("outer", forField: 10)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WithNullables.self) {
      decoded in
      if case .value(let v) = decoded.count.kind {
        XCTAssertEqual(v, 10)
      }
      else {
        XCTFail("count")
      }
      if case .nullVal = decoded.active.kind {
      }
      else {
        XCTFail("active")
      }
      if case .value(let v) = decoded.label.kind {
        XCTAssertEqual(v, "label_val")
      }
      else {
        XCTFail("label")
      }
      XCTAssertEqual(decoded.name, "outer")
    }
  }

  // MARK: - Non-sequential / large field numbers

  func test_realworld_nonSequentialFields_bidirectional() throws {
    var proto = Testcompat_NonSequentialFields()
    proto.name = "test"
    proto.code = 42
    proto.description_p = "desc"
    proto.bigNumber = Int64.max
    proto.flag = true
    proto.createdAt.seconds = 1_234_567_890
    proto.updatedAt.seconds = 1_234_567_891

    let desc = CompatDescriptors.nonSequentialFields()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? String, "test")
      XCTAssertEqual(try msg.get(forField: 2) as? Int32, 42)
      XCTAssertEqual(try msg.get(forField: 10) as? String, "desc")
      XCTAssertEqual(try msg.get(forField: 50) as? Int64, Int64.max)
      XCTAssertEqual(try msg.get(forField: 100) as? Bool, true)
      let tsDyn = try XCTUnwrap(try msg.get(forField: 71) as? DynamicMessage)
      XCTAssertEqual(try tsDyn.get(forField: 1) as? Int64, 1_234_567_890)
    }

    let tsDesc = CompatDescriptors.wktTimestamp()
    var ts1 = DynamicMessage(descriptor: tsDesc)
    try ts1.set(Int64(1_234_567_890), forField: 1)
    var ts2 = DynamicMessage(descriptor: tsDesc)
    try ts2.set(Int64(1_234_567_891), forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("test", forField: 1)
    try dynamic.set(Int32(42), forField: 2)
    try dynamic.set("desc", forField: 10)
    try dynamic.set(Int64.max, forField: 50)
    try dynamic.set(true, forField: 100)
    try dynamic.set(ts1, forField: 71)
    try dynamic.set(ts2, forField: 72)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_NonSequentialFields.self
    ) { decoded in
      XCTAssertEqual(decoded.name, "test")
      XCTAssertEqual(decoded.code, 42)
      XCTAssertEqual(decoded.description_p, "desc")
      XCTAssertEqual(decoded.bigNumber, Int64.max)
      XCTAssertTrue(decoded.flag)
      XCTAssertEqual(decoded.createdAt.seconds, 1_234_567_890)
      XCTAssertEqual(decoded.updatedAt.seconds, 1_234_567_891)
    }
  }

  // MARK: - Reserved fields: normal active fields work

  func test_realworld_withReserved_activeFields_bidirectional() throws {
    var proto = Testcompat_WithReserved()
    proto.name = "reserved_test"
    proto.version = 3
    proto.status = "active"
    proto.priority = 10

    let desc = CompatDescriptors.withReserved()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? String, "reserved_test")
      XCTAssertEqual(try msg.get(forField: 5) as? Int32, 3)
      XCTAssertEqual(try msg.get(forField: 9) as? String, "active")
      XCTAssertEqual(try msg.get(forField: 10) as? Int32, 10)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("reserved_test", forField: 1)
    try dynamic.set(Int32(3), forField: 5)
    try dynamic.set("active", forField: 9)
    try dynamic.set(Int32(10), forField: 10)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WithReserved.self) {
      decoded in
      XCTAssertEqual(decoded.name, "reserved_test")
      XCTAssertEqual(decoded.version, 3)
      XCTAssertEqual(decoded.status, "active")
      XCTAssertEqual(decoded.priority, 10)
    }
  }

  // MARK: - ReportResponse: deeply nested real-world type

  func test_realworld_reportResponse_basic_bidirectional() throws {
    var proto = Testcompat_ReportResponse()
    proto.total = 100
    proto.limit = 10
    proto.offset = 0

    var keyword = Testcompat_ReportResponse.Keyword()
    keyword.keyword = "swift"
    keyword.tags = ["ios", "mobile"]
    proto.keywords = [keyword]

    let desc = CompatDescriptors.reportResponse()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? UInt32, 100)
      XCTAssertEqual(try msg.get(forField: 2) as? UInt32, 10)
      let keywords = try XCTUnwrap(try msg.get(forField: 4) as? [DynamicMessage])
      XCTAssertEqual(keywords.count, 1)
      XCTAssertEqual(try keywords[0].get(forField: 1) as? String, "swift")
      XCTAssertEqual(try keywords[0].get(forField: 2) as? [String], ["ios", "mobile"])
    }

    // Direction B: build with keywords included
    let reportDesc = CompatDescriptors.reportResponse()
    let kwDesc = reportDesc.nestedMessages["Keyword"]!

    var kwDyn = DynamicMessage(descriptor: kwDesc)
    try kwDyn.set("swift", forField: 1)
    try kwDyn.set(["ios", "mobile"] as [String], forField: 2)

    var dynamic = DynamicMessage(descriptor: reportDesc)
    try dynamic.set(UInt32(100), forField: 1)
    try dynamic.set(UInt32(10), forField: 2)
    try dynamic.set(UInt32(0), forField: 3)
    try dynamic.set([kwDyn] as [DynamicMessage], forField: 4)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_ReportResponse.self)
    { decoded in
      XCTAssertEqual(decoded.total, 100)
      XCTAssertEqual(decoded.limit, 10)
      XCTAssertEqual(decoded.offset, 0)
      XCTAssertEqual(decoded.keywords.count, 1)
      XCTAssertEqual(decoded.keywords[0].keyword, "swift")
      XCTAssertEqual(decoded.keywords[0].tags, ["ios", "mobile"])
    }
  }

  // MARK: - DateValue: simple struct-like message

  func test_realworld_dateValue_bidirectional() throws {
    var proto = Testcompat_DateValue()
    proto.year = 2024
    proto.month = 3
    proto.day = 15

    let desc = CompatDescriptors.dateValue()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? Int32, 2024)
      XCTAssertEqual(try msg.get(forField: 2) as? Int32, 3)
      XCTAssertEqual(try msg.get(forField: 3) as? Int32, 15)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(2024), forField: 1)
    try dynamic.set(Int32(3), forField: 2)
    try dynamic.set(Int32(15), forField: 3)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_DateValue.self) {
      decoded in
      XCTAssertEqual(decoded.year, 2024)
      XCTAssertEqual(decoded.month, 3)
      XCTAssertEqual(decoded.day, 15)
    }
  }

  // MARK: - NullableBool: explicit false value

  func test_realworld_nullableBool_false_bidirectional() throws {
    var proto = Testcompat_NullableBool()
    proto.value = false

    let desc = CompatDescriptors.nullableBool()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 2) as? Bool, false)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(false, forField: 2)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_NullableBool.self) {
      decoded in
      if case .value(let v) = decoded.kind {
        XCTAssertFalse(v)
      }
      else {
        XCTFail("expected bool value")
      }
    }
  }

  // MARK: - NullableString: value set

  func test_realworld_nullableString_value_bidirectional() throws {
    var proto = Testcompat_NullableString()
    proto.value = "hello_null"

    let desc = CompatDescriptors.nullableString()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 2) as? String, "hello_null")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("hello_null", forField: 2)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_NullableString.self)
    {
      decoded in
      if case .value(let v) = decoded.kind {
        XCTAssertEqual(v, "hello_null")
      }
      else {
        XCTFail("expected string value")
      }
    }
  }

  // MARK: - NullableMessage: message value set

  func test_realworld_nullableMessage_value_bidirectional() throws {
    var inner = Testcompat_SimpleMessage()
    inner.id = 77
    inner.name = "nullable_inner"

    var proto = Testcompat_NullableMessage()
    proto.value = inner

    let desc = CompatDescriptors.nullableMessage()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let innerDyn = try XCTUnwrap(try msg.get(forField: 2) as? DynamicMessage)
      XCTAssertEqual(try innerDyn.get(forField: 1) as? Int32, 77)
      XCTAssertEqual(try innerDyn.get(forField: 2) as? String, "nullable_inner")
    }

    let simpleDesc = CompatDescriptors.simpleMessage()
    var innerDyn = DynamicMessage(descriptor: simpleDesc)
    try innerDyn.set(Int32(77), forField: 1)
    try innerDyn.set("nullable_inner", forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(innerDyn, forField: 2)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_NullableMessage.self)
    {
      decoded in
      if case .value(let m) = decoded.kind {
        XCTAssertEqual(m.id, 77)
        XCTAssertEqual(m.name, "nullable_inner")
      }
      else {
        XCTFail("expected message value")
      }
    }
  }

  // MARK: - Nullable: unset → empty JSON

  func test_realworld_nullable_unset_emptyJSON() throws {
    let proto = Testcompat_NullableUint32()
    let jsonStr = try proto.jsonString()
    XCTAssertEqual(jsonStr, "{}")

    let desc = CompatDescriptors.nullableUint32()
    let dynamic = DynamicMessage(descriptor: desc)
    let jsonData = try CompatHelpers.makeSerializer(registry: registry).serialize(dynamic)
    let ourJson = try XCTUnwrap(String(data: jsonData, encoding: .utf8))
    XCTAssertEqual(ourJson, "{}")
  }

  // MARK: - Proto3Optional: optional message field set vs unset

  func test_realworld_proto3Optional_messageField_setVsUnset_bidirectional() throws {
    // Unset
    var protoUnset = Testcompat_Proto3OptionalMessages()
    protoUnset.label = "unset"
    let jsonUnset = try protoUnset.jsonString()
    XCTAssertFalse(jsonUnset.contains("optSimple"), "Unset optional message should not appear: \(jsonUnset)")

    // Set
    var protoSet = Testcompat_Proto3OptionalMessages()
    protoSet.optSimple.id = 55
    protoSet.label = "set"

    let desc = CompatDescriptors.proto3OptionalMessages()
    try CompatHelpers.assertProtocToUs(proto: protoSet, descriptor: desc, registry: registry) { msg in
      let sub = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try sub.get(forField: 1) as? Int32, 55)
      XCTAssertEqual(try msg.get(forField: 10) as? String, "set")
    }

    let simpleDesc = CompatDescriptors.simpleMessage()
    var subDyn = DynamicMessage(descriptor: simpleDesc)
    try subDyn.set(Int32(55), forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(subDyn, forField: 1)
    try dynamic.set("set", forField: 10)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_Proto3OptionalMessages.self
    ) { decoded in
      XCTAssertEqual(decoded.optSimple.id, 55)
    }
  }

  // MARK: - Proto3Optional: optional WKT field set vs unset

  func test_realworld_proto3Optional_wktField_setVsUnset_bidirectional() throws {
    // Unset
    let protoUnset = Testcompat_Proto3OptionalMessages()
    let jsonUnset = try protoUnset.jsonString()
    XCTAssertFalse(jsonUnset.contains("optTs"), "Unset optional WKT should not appear: \(jsonUnset)")

    // Set
    var protoSet = Testcompat_Proto3OptionalMessages()
    protoSet.optTs.seconds = 42

    let desc = CompatDescriptors.proto3OptionalMessages()
    try CompatHelpers.assertProtocToUs(proto: protoSet, descriptor: desc, registry: registry) { msg in
      let tsDyn = try XCTUnwrap(try msg.get(forField: 3) as? DynamicMessage)
      XCTAssertEqual(try tsDyn.get(forField: 1) as? Int64, 42)
    }

    let tsDesc = CompatDescriptors.wktTimestamp()
    var tsDyn = DynamicMessage(descriptor: tsDesc)
    try tsDyn.set(Int64(42), forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(tsDyn, forField: 3)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_Proto3OptionalMessages.self
    ) { decoded in
      XCTAssertEqual(decoded.optTs.seconds, 42)
    }
  }

  // MARK: - IntentFlag: all gap values bidirectional

  func test_realworld_intentHolder_allIntentFlags_bidirectional() throws {
    var proto = Testcompat_IntentHolder()
    proto.intent = .intentCommercial
    proto.allIntents = [
      .intentDefault, .intentInformational, .intentNavigational, .intentTransactional, .intentCommercial,
    ]
    proto.byName = ["c": .intentCommercial, "t": .intentTransactional]

    let desc = CompatDescriptors.intentHolder()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? Int32, 8)
      let vals = try XCTUnwrap(try msg.get(forField: 2) as? [Int32])
      XCTAssertEqual(vals, [0, 1, 2, 4, 8])
      let map = try XCTUnwrap(try msg.get(forField: 3) as? [AnyHashable: Any])
      XCTAssertEqual(map["c"] as? Int32, 8)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(8), forField: 1)
    try dynamic.set([Int32(0), Int32(1), Int32(2), Int32(4), Int32(8)] as [Int32], forField: 2)
    try dynamic.setMapEntry(Int32(8), forKey: "c", inField: 3)
    try dynamic.setMapEntry(Int32(4), forKey: "t", inField: 3)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_IntentHolder.self) {
      decoded in
      XCTAssertEqual(decoded.intent, .intentCommercial)
      XCTAssertEqual(decoded.allIntents.count, 5)
      XCTAssertEqual(decoded.byName["c"], .intentCommercial)
    }
  }

  // MARK: - NullableBool: false vs null distinction

  // MARK: - WithNullables: all nullable fields set to non-null values

  func test_withNullables_allSet_bidirectional() throws {
    var proto = Testcompat_WithNullables()
    proto.count.value = 42
    proto.rate.value = 2.71
    proto.active.value = true
    proto.label.value = "all_set"
    proto.detail.value.id = 7
    proto.detail.value.name = "detail_msg"
    proto.name = "all_set_outer"

    let desc = CompatDescriptors.withNullables()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let countDyn = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try countDyn.get(forField: 2) as? UInt32, 42)
      XCTAssertEqual(try msg.get(forField: 10) as? String, "all_set_outer")
    }

    let nullableUint32Desc = CompatDescriptors.nullableUint32()
    var countDyn = DynamicMessage(descriptor: nullableUint32Desc)
    try countDyn.set(UInt32(42), forField: 2)

    let nullableDoubleDesc = CompatDescriptors.nullableDouble()
    var rateDyn = DynamicMessage(descriptor: nullableDoubleDesc)
    try rateDyn.set(Double(2.71), forField: 2)

    let nullableBoolDesc = CompatDescriptors.nullableBool()
    var activeDyn = DynamicMessage(descriptor: nullableBoolDesc)
    try activeDyn.set(true, forField: 2)

    let nullableStringDesc = CompatDescriptors.nullableString()
    var labelDyn = DynamicMessage(descriptor: nullableStringDesc)
    try labelDyn.set("all_set", forField: 2)

    let simpleDesc = CompatDescriptors.simpleMessage()
    var innerSimpleDyn = DynamicMessage(descriptor: simpleDesc)
    try innerSimpleDyn.set(Int32(7), forField: 1)
    try innerSimpleDyn.set("detail_msg", forField: 2)

    let nullableMessageDesc = CompatDescriptors.nullableMessage()
    var detailDyn = DynamicMessage(descriptor: nullableMessageDesc)
    try detailDyn.set(innerSimpleDyn, forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(countDyn, forField: 1)
    try dynamic.set(rateDyn, forField: 2)
    try dynamic.set(activeDyn, forField: 3)
    try dynamic.set(labelDyn, forField: 4)
    try dynamic.set(detailDyn, forField: 5)
    try dynamic.set("all_set_outer", forField: 10)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WithNullables.self) {
      decoded in
      if case .value(let v) = decoded.count.kind {
        XCTAssertEqual(v, 42)
      }
      else {
        XCTFail("count should have value")
      }
      if case .value(let v) = decoded.rate.kind {
        XCTAssertEqual(v, 2.71, accuracy: 0.001)
      }
      else {
        XCTFail("rate should have value")
      }
      if case .value(let v) = decoded.active.kind {
        XCTAssertTrue(v)
      }
      else {
        XCTFail("active should have value")
      }
      if case .value(let v) = decoded.label.kind {
        XCTAssertEqual(v, "all_set")
      }
      else {
        XCTFail("label should have value")
      }
      if case .value(let v) = decoded.detail.kind {
        XCTAssertEqual(v.id, 7)
        XCTAssertEqual(v.name, "detail_msg")
      }
      else {
        XCTFail("detail should have value")
      }
      XCTAssertEqual(decoded.name, "all_set_outer")
    }
  }

  // MARK: - ReportResponse: deep sibling definitions chain

  func test_reportResponse_deepSiblingDefs_bidirectional() throws {
    var proto = Testcompat_ReportResponse()
    proto.total = 5
    proto.limit = 2
    proto.offset = 0

    var metrics = Testcompat_ReportResponse.Metrics()
    metrics.position = 1
    metrics.visibility = 0.95
    metrics.traffic = 1250.5

    var position = Testcompat_ReportResponse.Position()
    position.metrics = metrics
    position.serpFeatures = [.active, .inactive]
    position.url = "https://example.com"

    var competitor = Testcompat_ReportResponse.CompetitorData()
    competitor.competitor.id = 99
    competitor.competitor.name = "CompetitorX"
    competitor.position = position

    var dateEntry = Testcompat_ReportResponse.DateEntry()
    dateEntry.date = "2024-01-01"
    dateEntry.isCrawled = true
    dateEntry.competitors = [competitor]

    var interval = Testcompat_ReportResponse.Interval()
    interval.begin = dateEntry
    interval.end = dateEntry
    interval.diff = [competitor]

    var keyword = Testcompat_ReportResponse.Keyword()
    keyword.keyword = "swift protobuf"
    keyword.tags = ["ios", "serialization"]
    keyword.cpc.value = 2.5
    keyword.volume.value = 1000
    keyword.serps = interval

    proto.keywords = [keyword]

    let desc = CompatDescriptors.reportResponse()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? UInt32, 5)
      XCTAssertEqual(try msg.get(forField: 2) as? UInt32, 2)
      let keywords = try XCTUnwrap(try msg.get(forField: 4) as? [DynamicMessage])
      XCTAssertEqual(keywords.count, 1)
      let kw = keywords[0]
      XCTAssertEqual(try kw.get(forField: 1) as? String, "swift protobuf")
      let tags = try XCTUnwrap(try kw.get(forField: 2) as? [String])
      XCTAssertEqual(tags, ["ios", "serialization"])
    }

    // Direction B: build via DynamicMessage
    let reportDesc = CompatDescriptors.reportResponse()
    let kwDesc = reportDesc.nestedMessages["Keyword"]!
    let cpcDesc = CompatDescriptors.nullableDouble()
    let volDesc = CompatDescriptors.nullableUint32()

    var cpcDyn = DynamicMessage(descriptor: cpcDesc)
    try cpcDyn.set(Double(2.5), forField: 2)

    var volDyn = DynamicMessage(descriptor: volDesc)
    try volDyn.set(UInt32(1000), forField: 2)

    var kwDyn = DynamicMessage(descriptor: kwDesc)
    try kwDyn.set("swift protobuf", forField: 1)
    try kwDyn.set(["ios", "serialization"] as [String], forField: 2)
    try kwDyn.set(cpcDyn, forField: 3)
    try kwDyn.set(volDyn, forField: 4)

    var dynamic = DynamicMessage(descriptor: reportDesc)
    try dynamic.set(UInt32(5), forField: 1)
    try dynamic.set(UInt32(2), forField: 2)
    try dynamic.set(UInt32(0), forField: 3)
    try dynamic.set([kwDyn] as [DynamicMessage], forField: 4)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_ReportResponse.self)
    {
      decoded in
      XCTAssertEqual(decoded.total, 5)
      XCTAssertEqual(decoded.keywords.count, 1)
      XCTAssertEqual(decoded.keywords[0].keyword, "swift protobuf")
      XCTAssertEqual(decoded.keywords[0].tags, ["ios", "serialization"])
      if case .value(let v) = decoded.keywords[0].cpc.kind {
        XCTAssertEqual(v, 2.5, accuracy: 0.001)
      }
      else {
        XCTFail("cpc should have value")
      }
    }
  }

  func test_realworld_nullableBool_false_vs_null() throws {
    var protoFalse = Testcompat_NullableBool()
    protoFalse.value = false

    var protoNull = Testcompat_NullableBool()
    protoNull.nullVal = .nullValue

    let falseJson = try protoFalse.jsonString()
    let nullJson = try protoNull.jsonString()

    XCTAssertTrue(falseJson.contains("value") || falseJson.contains("false"), "false variant: \(falseJson)")
    XCTAssertTrue(nullJson.contains("nullVal") || nullJson.contains("null"), "null variant: \(nullJson)")
    XCTAssertNotEqual(falseJson, nullJson, "false and null must produce different JSON")
  }
}
