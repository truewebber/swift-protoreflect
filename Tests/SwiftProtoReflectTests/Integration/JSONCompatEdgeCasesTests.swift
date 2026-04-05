// JSONCompatEdgeCasesTests.swift
// SwiftProtoReflectTests
//
// Group 14: Edge Cases — unicode, max/min int64, NaN/Infinity, empty, 50+ fields.
// Bidirectional JSON compatibility tests.
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class JSONCompatEdgeCasesTests: XCTestCase {

  private var registry: TypeRegistry!

  override func setUp() {
    super.setUp()
    registry = try? CompatDescriptors.fullRegistry()
  }

  override func tearDown() {
    registry = nil
    super.tearDown()
  }

  // MARK: - Unicode strings

  func test_edge_unicode_allScripts_bidirectional() throws {
    let unicodeStrings = [
      "Hello, 世界",
      "Привет, мир!",
      "مرحبا",
      "こんにちは",
      "안녕하세요",
      "🌍🎉🚀💡",
      "café, naïve, façade",
      "\u{0000}null\u{0000}embedded",
      "line\nfeed\ttab",
      "quote\"and\\backslash",
    ]

    let desc = CompatDescriptors.scalarMessage()

    for str in unicodeStrings {
      var proto = Testcompat_ScalarMessage()
      proto.stringField = str

      try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
        XCTAssertEqual(try msg.get(forField: 14) as? String, str, "Unicode string failed: \(str)")
      }

      var dynamic = DynamicMessage(descriptor: desc)
      try dynamic.set(str, forField: 14)
      try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_ScalarMessage.self)
      { decoded in
        XCTAssertEqual(decoded.stringField, str, "Unicode round-trip failed: \(str)")
      }
    }
  }

  // MARK: - Empty string (different from omitted)

  func test_edge_emptyString_inRepeated_bidirectional() throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repString = ["", "a", "", "b", ""]

    let desc = CompatDescriptors.repeatedAllTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 14) as? [String], ["", "a", "", "b", ""])
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(["", "a", "", "b", ""] as [String], forField: 14)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_RepeatedAllTypes.self
    ) { decoded in
      XCTAssertEqual(decoded.repString, ["", "a", "", "b", ""])
    }
  }

  // MARK: - Empty bytes

  func test_edge_emptyBytes_bidirectional() throws {
    var proto = Testcompat_ScalarMessage()
    proto.bytesField = Data()

    // Note: empty bytes == default in proto3, so JSON omits it
    let jsonStr = try proto.jsonString()
    XCTAssertFalse(jsonStr.contains("bytesField"), "Empty bytes should be omitted: \(jsonStr)")

    // Set a non-empty bytes value and round-trip (Direction A)
    proto.bytesField = Data([0x00])
    let desc = CompatDescriptors.scalarMessage()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 15) as? Data, Data([0x00]))
    }

    // Direction B: build DynamicMessage with null byte → SwiftProtobuf
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Data([0x00]), forField: 15)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_ScalarMessage.self) {
      decoded in
      XCTAssertEqual(decoded.bytesField, Data([0x00]))
    }
  }

  // MARK: - Max/min int64 as quoted strings in JSON

  func test_edge_int64MaxMin_quotedStrings_bidirectional() throws {
    var proto = Testcompat_ScalarMessage()
    proto.int64Field = Int64.max

    let desc = CompatDescriptors.scalarMessage()
    let jsonStr = try proto.jsonString()
    // int64 must be represented as a quoted string
    XCTAssertTrue(
      jsonStr.contains("\"9223372036854775807\""),
      "Int64.max must be quoted in JSON: \(jsonStr)"
    )

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 4) as? Int64, Int64.max)
    }

    var proto2 = Testcompat_ScalarMessage()
    proto2.int64Field = Int64.min
    let jsonStr2 = try proto2.jsonString()
    XCTAssertTrue(
      jsonStr2.contains("\"-9223372036854775808\""),
      "Int64.min must be quoted in JSON: \(jsonStr2)"
    )

    try CompatHelpers.assertProtocToUs(proto: proto2, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 4) as? Int64, Int64.min)
    }

    // Direction B: Int64.max
    var dynMax = DynamicMessage(descriptor: desc)
    try dynMax.set(Int64.max, forField: 4)
    try CompatHelpers.assertUsToProtoc(dynamic: dynMax, registry: registry, protoType: Testcompat_ScalarMessage.self) {
      decoded in
      XCTAssertEqual(decoded.int64Field, Int64.max)
    }

    // Direction B: Int64.min
    var dynMin = DynamicMessage(descriptor: desc)
    try dynMin.set(Int64.min, forField: 4)
    try CompatHelpers.assertUsToProtoc(dynamic: dynMin, registry: registry, protoType: Testcompat_ScalarMessage.self) {
      decoded in
      XCTAssertEqual(decoded.int64Field, Int64.min)
    }
  }

  // MARK: - Zero int64 as quoted "0"

  func test_edge_zeroInt64_quotedZero_bidirectional() throws {
    var proto = Testcompat_ScalarMessage()
    proto.int64Field = 0

    let jsonStr = try proto.jsonString()
    // proto3: zero int64 is omitted (default value)
    XCTAssertFalse(
      jsonStr.contains("int64Field"),
      "Zero int64 is proto3 default and should be omitted: \(jsonStr)"
    )

    // OptionalScalarMessage: optional int64 set to 0 → should appear as "0" (quoted)
    var protoOpt = Testcompat_OptionalScalarMessage()
    protoOpt.optInt64 = 0

    let optDesc = CompatDescriptors.optionalScalarMessage()
    let optJsonStr = try protoOpt.jsonString()
    XCTAssertTrue(
      optJsonStr.contains("\"0\"") || optJsonStr.contains("optInt64"),
      "Optional int64 set to 0 should appear as quoted zero: \(optJsonStr)"
    )

    try CompatHelpers.assertProtocToUs(proto: protoOpt, descriptor: optDesc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 4) as? Int64, 0)
    }

    var dynamic = DynamicMessage(descriptor: optDesc)
    try dynamic.set(Int64(0), forField: 4)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_OptionalScalarMessage.self
    ) { decoded in
      XCTAssertTrue(decoded.hasOptInt64, "Optional int64 set to 0 should have presence")
      XCTAssertEqual(decoded.optInt64, 0)
    }
  }

  // MARK: - NaN and Infinity for Float (bidirectional)

  func test_edge_nanInfinity_float_bidirectional() throws {
    let desc = CompatDescriptors.scalarMessage()

    // Float NaN
    var protoNaN = Testcompat_ScalarMessage()
    protoNaN.floatField = Float.nan
    try CompatHelpers.assertProtocToUs(proto: protoNaN, descriptor: desc, registry: registry) { msg in
      let val = try XCTUnwrap(try msg.get(forField: 2) as? Float)
      XCTAssertTrue(val.isNaN)
    }
    var dynNaN = DynamicMessage(descriptor: desc)
    try dynNaN.set(Float.nan, forField: 2)
    try CompatHelpers.assertUsToProtoc(dynamic: dynNaN, registry: registry, protoType: Testcompat_ScalarMessage.self) {
      decoded in
      XCTAssertTrue(decoded.floatField.isNaN)
    }

    // Float +Infinity
    var protoInf = Testcompat_ScalarMessage()
    protoInf.floatField = Float.infinity
    try CompatHelpers.assertProtocToUs(proto: protoInf, descriptor: desc, registry: registry) { msg in
      let val = try XCTUnwrap(try msg.get(forField: 2) as? Float)
      XCTAssertTrue(val.isInfinite && val > 0)
    }
    var dynInf = DynamicMessage(descriptor: desc)
    try dynInf.set(Float.infinity, forField: 2)
    try CompatHelpers.assertUsToProtoc(dynamic: dynInf, registry: registry, protoType: Testcompat_ScalarMessage.self) {
      decoded in
      XCTAssertTrue(decoded.floatField.isInfinite && decoded.floatField > 0)
    }

    // Float -Infinity
    var protoNegInf = Testcompat_ScalarMessage()
    protoNegInf.floatField = -Float.infinity
    try CompatHelpers.assertProtocToUs(proto: protoNegInf, descriptor: desc, registry: registry) { msg in
      let val = try XCTUnwrap(try msg.get(forField: 2) as? Float)
      XCTAssertTrue(val.isInfinite && val < 0)
    }
    var dynNegInf = DynamicMessage(descriptor: desc)
    try dynNegInf.set(-Float.infinity, forField: 2)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynNegInf,
      registry: registry,
      protoType: Testcompat_ScalarMessage.self
    ) { decoded in
      XCTAssertTrue(decoded.floatField.isInfinite && decoded.floatField < 0)
    }
  }

  // MARK: - NaN and Infinity in JSON

  func test_edge_nan_infinity_inJSON() throws {
    let desc = CompatDescriptors.scalarMessage()

    // NaN
    var protoNaN = Testcompat_ScalarMessage()
    protoNaN.doubleField = Double.nan
    let jsonStr = try protoNaN.jsonString()
    XCTAssertTrue(jsonStr.contains("\"NaN\""), "NaN must appear as \\\"NaN\\\" in JSON: \(jsonStr)")
    try CompatHelpers.assertProtocToUs(proto: protoNaN, descriptor: desc, registry: registry) { msg in
      let val = try XCTUnwrap(try msg.get(forField: 1) as? Double)
      XCTAssertTrue(val.isNaN)
    }
    var dynNaN = DynamicMessage(descriptor: desc)
    try dynNaN.set(Double.nan, forField: 1)
    try CompatHelpers.assertUsToProtoc(dynamic: dynNaN, registry: registry, protoType: Testcompat_ScalarMessage.self) {
      decoded in
      XCTAssertTrue(decoded.doubleField.isNaN)
    }

    // +Infinity
    var protoInf = Testcompat_ScalarMessage()
    protoInf.doubleField = Double.infinity
    let jsonStr2 = try protoInf.jsonString()
    XCTAssertTrue(jsonStr2.contains("\"Infinity\""), "Infinity must appear as \\\"Infinity\\\": \(jsonStr2)")
    try CompatHelpers.assertProtocToUs(proto: protoInf, descriptor: desc, registry: registry) { msg in
      let val = try XCTUnwrap(try msg.get(forField: 1) as? Double)
      XCTAssertTrue(val.isInfinite && val > 0)
    }
    var dynInf = DynamicMessage(descriptor: desc)
    try dynInf.set(Double.infinity, forField: 1)
    try CompatHelpers.assertUsToProtoc(dynamic: dynInf, registry: registry, protoType: Testcompat_ScalarMessage.self) {
      decoded in
      XCTAssertTrue(decoded.doubleField.isInfinite && decoded.doubleField > 0)
    }

    // -Infinity
    var protoNegInf = Testcompat_ScalarMessage()
    protoNegInf.doubleField = -Double.infinity
    let jsonStr3 = try protoNegInf.jsonString()
    XCTAssertTrue(jsonStr3.contains("\"-Infinity\""), "-Infinity must appear as \\\"-Infinity\\\": \(jsonStr3)")
    try CompatHelpers.assertProtocToUs(proto: protoNegInf, descriptor: desc, registry: registry) { msg in
      let val = try XCTUnwrap(try msg.get(forField: 1) as? Double)
      XCTAssertTrue(val.isInfinite && val < 0)
    }
    var dynNegInf = DynamicMessage(descriptor: desc)
    try dynNegInf.set(-Double.infinity, forField: 1)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynNegInf,
      registry: registry,
      protoType: Testcompat_ScalarMessage.self
    ) { decoded in
      XCTAssertTrue(decoded.doubleField.isInfinite && decoded.doubleField < 0)
    }
  }

  // MARK: - Empty message → {}

  func test_edge_emptyMessage_emptyJSON_bidirectional() throws {
    let proto = Testcompat_EmptyCustom()
    let jsonStr = try proto.jsonString()
    XCTAssertEqual(jsonStr, "{}")

    let desc = CompatDescriptors.emptyCustom()
    let dynamic = DynamicMessage(descriptor: desc)
    let jsonData = try CompatHelpers.makeSerializer(registry: registry).serialize(dynamic)
    let ourJson = try XCTUnwrap(String(data: jsonData, encoding: .utf8))
    XCTAssertEqual(ourJson, "{}")
  }

  // MARK: - Empty message round-trip via deserialization

  func test_edge_emptyMessage_deserialize_bidirectional() throws {
    let proto = Testcompat_EmptyCustom()
    let desc = CompatDescriptors.emptyCustom()

    // Direction A: SwiftProtobuf → our deserializer
    let jsonStr = try proto.jsonString()
    guard let data = jsonStr.data(using: .utf8) else { throw CompatError.jsonEncodingFailed }
    let msg = try CompatHelpers.makeDeserializer(registry: registry).deserialize(data, using: desc)
    XCTAssertNotNil(msg)

    // Direction B: empty DynamicMessage → our serializer → SwiftProtobuf
    let dynamic = DynamicMessage(descriptor: desc)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_EmptyCustom.self) {
      decoded in
      XCTAssertEqual(decoded, Testcompat_EmptyCustom())
    }
  }

  // MARK: - 50+ fields in WideMessage

  func test_edge_wideMessage_50plusFields_bidirectional() throws {
    var proto = Testcompat_WideMessage()
    proto.f1 = "v1"
    proto.f20 = "v20"
    proto.i1 = 100
    proto.i10 = 1000
    proto.d1 = 3.14
    proto.d5 = 2.71
    proto.b1 = true
    proto.b5 = false
    proto.by1 = Data([0xFF])
    proto.l1 = Int64.max
    proto.l3 = Int64.min
    proto.u1 = UInt64.max
    proto.fl1 = Float.infinity
    proto.fl2 = Float.nan

    let desc = CompatDescriptors.wideMessage()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? String, "v1")
      XCTAssertEqual(try msg.get(forField: 20) as? String, "v20")
      XCTAssertEqual(try msg.get(forField: 21) as? Int32, 100)
      XCTAssertEqual(try msg.get(forField: 30) as? Int32, 1000)
      let f1 = try XCTUnwrap(try msg.get(forField: 49) as? Float)
      XCTAssertTrue(f1.isInfinite)
      let f2 = try XCTUnwrap(try msg.get(forField: 50) as? Float)
      XCTAssertTrue(f2.isNaN)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("v1", forField: 1)
    try dynamic.set("v20", forField: 20)
    try dynamic.set(Int32(100), forField: 21)
    try dynamic.set(Int32(1000), forField: 30)
    try dynamic.set(Float.infinity, forField: 49)
    try dynamic.set(Float.nan, forField: 50)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WideMessage.self) {
      decoded in
      XCTAssertEqual(decoded.f1, "v1")
      XCTAssertEqual(decoded.f20, "v20")
      XCTAssertEqual(decoded.i1, 100)
      XCTAssertTrue(decoded.fl1.isInfinite)
      XCTAssertTrue(decoded.fl2.isNaN)
    }
  }

  // MARK: - Repeated single element

  func test_edge_repeatedSingleElement_bidirectional() throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repInt32 = [42]

    let desc = CompatDescriptors.repeatedAllTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 3) as? [Int32], [42])
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set([Int32(42)] as [Int32], forField: 3)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_RepeatedAllTypes.self
    ) { decoded in
      XCTAssertEqual(decoded.repInt32, [42])
    }
  }

  // MARK: - Map with single entry

  func test_edge_mapSingleEntry_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapStringString = ["only": "one"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let m = try XCTUnwrap(try msg.get(forField: 1) as? [AnyHashable: Any])
      XCTAssertEqual(m.count, 1)
      XCTAssertEqual(m["only"] as? String, "one")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry("one", forKey: "only", inField: 1)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MapAllKeyTypes.self)
    { decoded in
      XCTAssertEqual(decoded.mapStringString.count, 1)
      XCTAssertEqual(decoded.mapStringString["only"], "one")
    }
  }

  // MARK: - Field order independence (Direction A)

  func test_edge_fieldOrderIndependent_directionA() throws {
    // JSON keys in arbitrary order should deserialize to the same DynamicMessage
    let json1 = """
      {"stringField":"hello","int32Field":42,"boolField":true}
      """
    let json2 = """
      {"boolField":true,"int32Field":42,"stringField":"hello"}
      """
    let json3 = """
      {"int32Field":42,"stringField":"hello","boolField":true}
      """

    let desc = CompatDescriptors.scalarMessage()
    let deserializer = CompatHelpers.makeDeserializer(registry: registry)

    for jsonStr in [json1, json2, json3] {
      guard let data = jsonStr.data(using: .utf8) else { throw CompatError.jsonEncodingFailed }
      let msg = try deserializer.deserialize(data, using: desc)
      XCTAssertEqual(try msg.get(forField: 14) as? String, "hello", "Failed for: \(jsonStr)")
      XCTAssertEqual(try msg.get(forField: 3) as? Int32, 42, "Failed for: \(jsonStr)")
      XCTAssertEqual(try msg.get(forField: 13) as? Bool, true, "Failed for: \(jsonStr)")
    }
  }

  // MARK: - Max uint64 as quoted string

  func test_edge_maxUint64_quotedString_bidirectional() throws {
    var proto = Testcompat_ScalarMessage()
    proto.uint64Field = UInt64.max

    let desc = CompatDescriptors.scalarMessage()
    let jsonStr = try proto.jsonString()
    // uint64 max: 18446744073709551615
    XCTAssertTrue(
      jsonStr.contains("\"18446744073709551615\""),
      "UInt64.max must be quoted in JSON: \(jsonStr)"
    )

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 6) as? UInt64, UInt64.max)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(UInt64.max, forField: 6)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_ScalarMessage.self) {
      decoded in
      XCTAssertEqual(decoded.uint64Field, UInt64.max)
    }
  }

  // MARK: - Very long string (10KB)

  func test_edge_veryLongString_bidirectional() throws {
    let longStr = String(repeating: "a", count: 10_000)
    var proto = Testcompat_ScalarMessage()
    proto.stringField = longStr

    let desc = CompatDescriptors.scalarMessage()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual((try msg.get(forField: 14) as? String)?.count, 10_000)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(longStr, forField: 14)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_ScalarMessage.self) {
      decoded in
      XCTAssertEqual(decoded.stringField.count, 10_000)
    }
  }

  // MARK: - String with JSON control characters

  func test_edge_stringWithControlChars_bidirectional() throws {
    let controlStr = "a\u{00}b\u{01}c\u{1F}d\u{7F}e"

    var proto = Testcompat_ScalarMessage()
    proto.stringField = controlStr

    let desc = CompatDescriptors.scalarMessage()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 14) as? String, controlStr)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(controlStr, forField: 14)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_ScalarMessage.self) {
      decoded in
      XCTAssertEqual(decoded.stringField, controlStr)
    }
  }

  // MARK: - Deeply nested empty message

  func test_edge_deeplyNested_emptyLeaf_bidirectional() throws {
    var proto = Testcompat_Nested1()
    proto.name = "top"
    // child is default/empty

    let desc = CompatDescriptors.nested1()
    let jsonStr = try proto.jsonString()
    XCTAssertTrue(jsonStr.contains("name"), "name should appear: \(jsonStr)")

    // Direction A
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 2) as? String, "top")
    }

    // Direction B: only name set, child absent → SwiftProtobuf
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("top", forField: 2)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_Nested1.self) {
      decoded in
      XCTAssertEqual(decoded.name, "top")
      XCTAssertFalse(decoded.hasChild, "absent child should remain absent")
    }
  }
}
