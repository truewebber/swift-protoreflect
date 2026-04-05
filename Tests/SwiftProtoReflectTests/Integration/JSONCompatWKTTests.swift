// JSONCompatWKTTests.swift
// SwiftProtoReflectTests
//
// Group 6: Well-Known Types — bidirectional JSON compatibility tests.
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class JSONCompatWKTTests: XCTestCase {

  private var registry: TypeRegistry!

  override func setUp() {
    super.setUp()
    registry = try? CompatDescriptors.fullRegistry()
  }

  override func tearDown() {
    registry = nil
    super.tearDown()
  }

  // MARK: - Timestamp (RFC 3339 string)

  func test_wkt_timestamp_bidirectional() throws {
    var proto = Testcompat_WKTHolder()
    proto.ts.seconds = 1_700_000_000
    proto.ts.nanos = 500_000_000

    let desc = CompatDescriptors.wktHolder()
    let tsDesc = CompatDescriptors.wktTimestamp()

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let tsDyn = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try tsDyn.get(forField: 1) as? Int64, 1_700_000_000)
      XCTAssertEqual(try tsDyn.get(forField: 2) as? Int32, 500_000_000)
    }

    var tsDyn = DynamicMessage(descriptor: tsDesc)
    try tsDyn.set(Int64(1_700_000_000), forField: 1)
    try tsDyn.set(Int32(500_000_000), forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(tsDyn, forField: 1)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTHolder.self) {
      decoded in
      XCTAssertEqual(decoded.ts.seconds, 1_700_000_000)
      XCTAssertEqual(decoded.ts.nanos, 500_000_000)
    }
  }

  // MARK: - Duration

  func test_wkt_duration_bidirectional() throws {
    var proto = Testcompat_WKTHolder()
    proto.dur.seconds = 3600
    proto.dur.nanos = 0

    let desc = CompatDescriptors.wktHolder()
    let durDesc = CompatDescriptors.wktDuration()

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let durDyn = try XCTUnwrap(try msg.get(forField: 2) as? DynamicMessage)
      XCTAssertEqual(try durDyn.get(forField: 1) as? Int64, 3600)
      // nanos=0 is the default; field may not be stored (returns nil) — treat nil as 0
      XCTAssertEqual((try durDyn.get(forField: 2) as? Int32) ?? 0, 0)
    }

    var durDyn = DynamicMessage(descriptor: durDesc)
    try durDyn.set(Int64(3600), forField: 1)
    try durDyn.set(Int32(0), forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(durDyn, forField: 2)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTHolder.self) {
      decoded in
      XCTAssertEqual(decoded.dur.seconds, 3600)
      XCTAssertEqual(decoded.dur.nanos, 0)
    }
  }

  // MARK: - FieldMask (comma-separated paths)

  func test_wkt_fieldMask_bidirectional() throws {
    var proto = Testcompat_WKTHolder()
    proto.mask.paths = ["field_one", "nested.field_two", "another"]

    let desc = CompatDescriptors.wktHolder()
    let fmDesc = CompatDescriptors.wktFieldMask()

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let fmDyn = try XCTUnwrap(try msg.get(forField: 3) as? DynamicMessage)
      XCTAssertEqual(try fmDyn.get(forField: 1) as? [String], ["field_one", "nested.field_two", "another"])
    }

    var fmDyn = DynamicMessage(descriptor: fmDesc)
    try fmDyn.set(["field_one", "nested.field_two", "another"] as [String], forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(fmDyn, forField: 3)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTHolder.self) {
      decoded in
      XCTAssertEqual(decoded.mask.paths, ["field_one", "nested.field_two", "another"])
    }
  }

  // MARK: - Int64Value wrapper

  func test_wkt_int64Value_bidirectional() throws {
    var proto = Testcompat_WKTHolder()
    proto.i64W.value = Int64.max

    let desc = CompatDescriptors.wktHolder()
    let wrapDesc = CompatDescriptors.wktWrapper(name: "Int64Value", fieldType: .int64)

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let wDyn = try XCTUnwrap(try msg.get(forField: 10) as? DynamicMessage)
      XCTAssertEqual(try wDyn.get(forField: 1) as? Int64, Int64.max)
    }

    var wDyn = DynamicMessage(descriptor: wrapDesc)
    try wDyn.set(Int64.max, forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(wDyn, forField: 10)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTHolder.self) {
      decoded in
      XCTAssertEqual(decoded.i64W.value, Int64.max)
    }
  }

  // MARK: - StringValue wrapper

  func test_wkt_stringValue_bidirectional() throws {
    var proto = Testcompat_WKTHolder()
    proto.strW.value = "wrapped string"

    let desc = CompatDescriptors.wktHolder()
    let wrapDesc = CompatDescriptors.wktWrapper(name: "StringValue", fieldType: .string)

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let wDyn = try XCTUnwrap(try msg.get(forField: 15) as? DynamicMessage)
      XCTAssertEqual(try wDyn.get(forField: 1) as? String, "wrapped string")
    }

    var wDyn = DynamicMessage(descriptor: wrapDesc)
    try wDyn.set("wrapped string", forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(wDyn, forField: 15)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTHolder.self) {
      decoded in
      XCTAssertEqual(decoded.strW.value, "wrapped string")
    }
  }

  // MARK: - BoolValue wrapper

  func test_wkt_boolValue_bidirectional() throws {
    var proto = Testcompat_WKTHolder()
    proto.boolW.value = true

    let desc = CompatDescriptors.wktHolder()
    let wrapDesc = CompatDescriptors.wktWrapper(name: "BoolValue", fieldType: .bool)

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let wDyn = try XCTUnwrap(try msg.get(forField: 14) as? DynamicMessage)
      XCTAssertEqual(try wDyn.get(forField: 1) as? Bool, true)
    }

    var wDyn = DynamicMessage(descriptor: wrapDesc)
    try wDyn.set(true, forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(wDyn, forField: 14)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTHolder.self) {
      decoded in
      XCTAssertTrue(decoded.boolW.value)
    }
  }

  // MARK: - BytesValue wrapper

  func test_wkt_bytesValue_bidirectional() throws {
    let testBytes = Data([0x01, 0x02, 0x03])
    var proto = Testcompat_WKTHolder()
    proto.bytesW.value = testBytes

    let desc = CompatDescriptors.wktHolder()
    let wrapDesc = CompatDescriptors.wktWrapper(name: "BytesValue", fieldType: .bytes)

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let wDyn = try XCTUnwrap(try msg.get(forField: 16) as? DynamicMessage)
      XCTAssertEqual(try wDyn.get(forField: 1) as? Data, testBytes)
    }

    var wDyn = DynamicMessage(descriptor: wrapDesc)
    try wDyn.set(testBytes, forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(wDyn, forField: 16)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTHolder.self) {
      decoded in
      XCTAssertEqual(decoded.bytesW.value, testBytes)
    }
  }

  // MARK: - DoubleValue wrapper

  func test_wkt_doubleValue_bidirectional() throws {
    var proto = Testcompat_WKTHolder()
    proto.dblW.value = 3.14

    let desc = CompatDescriptors.wktHolder()
    let wrapDesc = CompatDescriptors.wktWrapper(name: "DoubleValue", fieldType: .double)

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let wDyn = try XCTUnwrap(try msg.get(forField: 8) as? DynamicMessage)
      XCTAssertEqual(try wDyn.get(forField: 1) as? Double, 3.14)
    }

    var wDyn = DynamicMessage(descriptor: wrapDesc)
    try wDyn.set(Double(3.14), forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(wDyn, forField: 8)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTHolder.self) {
      decoded in
      XCTAssertEqual(decoded.dblW.value, 3.14)
    }
  }

  // MARK: - FloatValue wrapper

  func test_wkt_floatValue_bidirectional() throws {
    var proto = Testcompat_WKTHolder()
    proto.fltW.value = 2.5

    let desc = CompatDescriptors.wktHolder()
    let wrapDesc = CompatDescriptors.wktWrapper(name: "FloatValue", fieldType: .float)

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let wDyn = try XCTUnwrap(try msg.get(forField: 9) as? DynamicMessage)
      XCTAssertEqual(try wDyn.get(forField: 1) as? Float, 2.5)
    }

    var wDyn = DynamicMessage(descriptor: wrapDesc)
    try wDyn.set(Float(2.5), forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(wDyn, forField: 9)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTHolder.self) {
      decoded in
      XCTAssertEqual(decoded.fltW.value, 2.5)
    }
  }

  // MARK: - Int32Value wrapper

  func test_wkt_int32Value_bidirectional() throws {
    var proto = Testcompat_WKTHolder()
    proto.i32W.value = Int32.max

    let desc = CompatDescriptors.wktHolder()
    let wrapDesc = CompatDescriptors.wktWrapper(name: "Int32Value", fieldType: .int32)

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let wDyn = try XCTUnwrap(try msg.get(forField: 12) as? DynamicMessage)
      XCTAssertEqual(try wDyn.get(forField: 1) as? Int32, Int32.max)
    }

    var wDyn = DynamicMessage(descriptor: wrapDesc)
    try wDyn.set(Int32.max, forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(wDyn, forField: 12)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTHolder.self) {
      decoded in
      XCTAssertEqual(decoded.i32W.value, Int32.max)
    }
  }

  // MARK: - UInt32Value / UInt64Value wrappers

  func test_wkt_uint32Value_bidirectional() throws {
    var proto = Testcompat_WKTHolder()
    proto.u32W.value = UInt32.max

    let desc = CompatDescriptors.wktHolder()
    let wrapDesc = CompatDescriptors.wktWrapper(name: "UInt32Value", fieldType: .uint32)

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let wDyn = try XCTUnwrap(try msg.get(forField: 13) as? DynamicMessage)
      XCTAssertEqual(try wDyn.get(forField: 1) as? UInt32, UInt32.max)
    }

    var wDyn = DynamicMessage(descriptor: wrapDesc)
    try wDyn.set(UInt32.max, forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(wDyn, forField: 13)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTHolder.self) {
      decoded in
      XCTAssertEqual(decoded.u32W.value, UInt32.max)
    }
  }

  func test_wkt_uint64Value_bidirectional() throws {
    var proto = Testcompat_WKTHolder()
    proto.u64W.value = UInt64.max

    let desc = CompatDescriptors.wktHolder()
    let wrapDesc = CompatDescriptors.wktWrapper(name: "UInt64Value", fieldType: .uint64)

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let wDyn = try XCTUnwrap(try msg.get(forField: 11) as? DynamicMessage)
      XCTAssertEqual(try wDyn.get(forField: 1) as? UInt64, UInt64.max)
    }

    var wDyn = DynamicMessage(descriptor: wrapDesc)
    try wDyn.set(UInt64.max, forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(wDyn, forField: 11)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTHolder.self) {
      decoded in
      XCTAssertEqual(decoded.u64W.value, UInt64.max)
    }
  }

  // MARK: - Empty

  func test_wkt_empty_bidirectional() throws {
    var proto = Testcompat_WKTHolder()
    proto.emptyVal = Google_Protobuf_Empty()

    let desc = CompatDescriptors.wktHolder()
    let emptyDesc = CompatDescriptors.wktEmpty()

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let eDyn = try XCTUnwrap(try msg.get(forField: 17) as? DynamicMessage)
      XCTAssertEqual(eDyn.descriptor.name, "Empty")
    }

    let eDyn = DynamicMessage(descriptor: emptyDesc)
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(eDyn, forField: 17)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTHolder.self) {
      decoded in
      XCTAssertEqual(decoded.emptyVal, Google_Protobuf_Empty())
    }
  }

  // MARK: - Repeated WKTs

  func test_wkt_repeatedTimestamps_bidirectional() throws {
    var proto = Testcompat_RepeatedWKTs()
    var ts1 = Google_Protobuf_Timestamp()
    ts1.seconds = 100
    var ts2 = Google_Protobuf_Timestamp()
    ts2.seconds = 200
    proto.timestamps = [ts1, ts2]

    let desc = CompatDescriptors.repeatedWKTs()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let tsList = try XCTUnwrap(try msg.get(forField: 1) as? [DynamicMessage])
      XCTAssertEqual(tsList.count, 2)
      XCTAssertEqual(try tsList[0].get(forField: 1) as? Int64, 100)
      XCTAssertEqual(try tsList[1].get(forField: 1) as? Int64, 200)
    }

    let tsDesc = CompatDescriptors.wktTimestamp()
    var tsDyn1 = DynamicMessage(descriptor: tsDesc)
    try tsDyn1.set(Int64(100), forField: 1)
    var tsDyn2 = DynamicMessage(descriptor: tsDesc)
    try tsDyn2.set(Int64(200), forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set([tsDyn1, tsDyn2] as [DynamicMessage], forField: 1)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_RepeatedWKTs.self) {
      decoded in
      XCTAssertEqual(decoded.timestamps.count, 2)
      XCTAssertEqual(decoded.timestamps[0].seconds, 100)
      XCTAssertEqual(decoded.timestamps[1].seconds, 200)
    }
  }

  // MARK: - Repeated StringValues

  func test_wkt_repeatedStringValues_bidirectional() throws {
    var proto = Testcompat_RepeatedWKTs()
    var sv1 = Google_Protobuf_StringValue()
    sv1.value = "a"
    var sv2 = Google_Protobuf_StringValue()
    sv2.value = "b"
    let sv3 = Google_Protobuf_StringValue()
    proto.stringVals = [sv1, sv2, sv3]

    let desc = CompatDescriptors.repeatedWKTs()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let vals = try XCTUnwrap(try msg.get(forField: 4) as? [DynamicMessage])
      XCTAssertEqual(vals.count, 3)
      XCTAssertEqual(try vals[0].get(forField: 1) as? String, "a")
      XCTAssertEqual(try vals[1].get(forField: 1) as? String, "b")
    }

    let strWrapDesc = CompatDescriptors.wktWrapper(name: "StringValue", fieldType: .string)
    var sw1 = DynamicMessage(descriptor: strWrapDesc)
    try sw1.set("a", forField: 1)
    var sw2 = DynamicMessage(descriptor: strWrapDesc)
    try sw2.set("b", forField: 1)
    var sw3 = DynamicMessage(descriptor: strWrapDesc)
    // empty string (default)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set([sw1, sw2, sw3] as [DynamicMessage], forField: 4)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_RepeatedWKTs.self) {
      decoded in
      XCTAssertEqual(decoded.stringVals.count, 3)
      XCTAssertEqual(decoded.stringVals[0].value, "a")
      XCTAssertEqual(decoded.stringVals[1].value, "b")
    }
  }

  // MARK: - Map<string, Timestamp>

  func test_wkt_mapTimestampValues_bidirectional() throws {
    var proto = Testcompat_MapWKTValues()
    var ts = Google_Protobuf_Timestamp()
    ts.seconds = 999
    proto.tsMap = ["now": ts]

    let desc = CompatDescriptors.mapWKTValues()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let mapVal = try XCTUnwrap(try msg.get(forField: 1) as? [AnyHashable: Any])
      let tsDyn = try XCTUnwrap(mapVal["now"] as? DynamicMessage)
      XCTAssertEqual(try tsDyn.get(forField: 1) as? Int64, 999)
    }

    let tsDesc = CompatDescriptors.wktTimestamp()
    var tsDyn = DynamicMessage(descriptor: tsDesc)
    try tsDyn.set(Int64(999), forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry(tsDyn, forKey: "now", inField: 1)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MapWKTValues.self) {
      decoded in
      XCTAssertEqual(decoded.tsMap["now"]?.seconds, 999)
    }
  }

  // MARK: - Any (wrapped regular message)

  func test_wkt_any_regularMessage_bidirectional() throws {
    var inner = Testcompat_SimpleMessage()
    inner.id = 42
    inner.name = "any_inner"
    let packed = try Google_Protobuf_Any(message: inner)

    var proto = Testcompat_WKTHolder()
    proto.anyVal = packed

    let desc = CompatDescriptors.wktHolder()
    let anyDesc = CompatDescriptors.wktAny()

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let anyDyn = try XCTUnwrap(try msg.get(forField: 4) as? DynamicMessage)
      XCTAssertEqual(anyDyn.descriptor.name, "Any")
      let typeUrl = try XCTUnwrap(try anyDyn.get(forField: 1) as? String)
      XCTAssertTrue(typeUrl.contains("SimpleMessage"), "typeUrl should contain message name: \(typeUrl)")
    }

    var anyDyn = DynamicMessage(descriptor: anyDesc)
    try anyDyn.set("type.googleapis.com/testcompat.SimpleMessage", forField: 1)
    let innerData = try inner.serializedData()
    try anyDyn.set(innerData, forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(anyDyn, forField: 4)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTHolder.self) {
      decoded in
      XCTAssertFalse(decoded.anyVal.typeURL.isEmpty, "typeURL should be set")
    }
  }

  // MARK: - Struct

  func test_wkt_struct_bidirectional() throws {
    var proto = Testcompat_WKTHolder()
    proto.structVal.fields["name"] = Google_Protobuf_Value.with { $0.stringValue = "test" }
    proto.structVal.fields["count"] = Google_Protobuf_Value.with { $0.numberValue = 5 }
    proto.structVal.fields["active"] = Google_Protobuf_Value.with { $0.boolValue = true }

    let desc = CompatDescriptors.wktHolder()
    // Direction A: verify actual field data is preserved
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let structDyn = try XCTUnwrap(try msg.get(forField: 5) as? DynamicMessage)
      XCTAssertEqual(structDyn.descriptor.name, "Struct")
    }

    // Direction B: build Struct with real data → SwiftProtobuf → verify content
    let structDesc = CompatDescriptors.wktStruct()
    let valueDesc = CompatDescriptors.wktValue()

    var nameVal = DynamicMessage(descriptor: valueDesc)
    try nameVal.set("test", forField: 3)  // string_value

    var countVal = DynamicMessage(descriptor: valueDesc)
    try countVal.set(Double(5), forField: 2)  // number_value

    var activeVal = DynamicMessage(descriptor: valueDesc)
    try activeVal.set(true, forField: 4)  // bool_value

    var structDyn = DynamicMessage(descriptor: structDesc)
    try structDyn.setMapEntry(nameVal, forKey: "name", inField: 1)
    try structDyn.setMapEntry(countVal, forKey: "count", inField: 1)
    try structDyn.setMapEntry(activeVal, forKey: "active", inField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(structDyn, forField: 5)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTHolder.self) {
      decoded in
      XCTAssertTrue(decoded.hasStructVal)
      XCTAssertEqual(decoded.structVal.fields["name"]?.stringValue, "test")
      XCTAssertEqual(decoded.structVal.fields["count"]?.numberValue, 5)
      XCTAssertEqual(decoded.structVal.fields["active"]?.boolValue, true)
    }
  }

  // MARK: - Value (all 6 kinds)

  func test_wkt_value_allKinds_bidirectional() throws {
    // All 6 Value kinds: null, number, string, bool, struct, list
    var protoNull = Testcompat_WKTHolder()
    protoNull.valueVal = Google_Protobuf_Value.with { $0.nullValue = .nullValue }
    var protoNumber = Testcompat_WKTHolder()
    protoNumber.valueVal = Google_Protobuf_Value.with { $0.numberValue = 3.14 }
    var protoString = Testcompat_WKTHolder()
    protoString.valueVal = Google_Protobuf_Value.with { $0.stringValue = "hello" }
    var protoBool = Testcompat_WKTHolder()
    protoBool.valueVal = Google_Protobuf_Value.with { $0.boolValue = true }

    var innerStruct = Google_Protobuf_Struct()
    innerStruct.fields["x"] = Google_Protobuf_Value.with { $0.numberValue = 1 }
    var protoStruct = Testcompat_WKTHolder()
    protoStruct.valueVal = Google_Protobuf_Value.with { $0.structValue = innerStruct }

    var innerList = Google_Protobuf_ListValue()
    innerList.values = [Google_Protobuf_Value.with { $0.stringValue = "item" }]
    var protoList = Testcompat_WKTHolder()
    protoList.valueVal = Google_Protobuf_Value.with { $0.listValue = innerList }

    let desc = CompatDescriptors.wktHolder()
    let allProtos: [(Testcompat_WKTHolder, String)] = [
      (protoNull, "null"), (protoNumber, "number"), (protoString, "string"),
      (protoBool, "bool"), (protoStruct, "struct"), (protoList, "list"),
    ]

    // Direction A: each kind
    for (proto, label) in allProtos {
      try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
        let valDyn = try XCTUnwrap(try msg.get(forField: 6) as? DynamicMessage)
        XCTAssertEqual(valDyn.descriptor.name, "Value", "Value descriptor name for kind \(label)")
      }
    }

    // Direction B: number value
    let valueDesc = CompatDescriptors.wktValue()
    var valDyn = DynamicMessage(descriptor: valueDesc)
    try valDyn.set(Double(3.14), forField: 2)  // number_value

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(valDyn, forField: 6)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTHolder.self) {
      decoded in
      XCTAssertTrue(decoded.hasValueVal)
      XCTAssertEqual(decoded.valueVal.numberValue, 3.14, accuracy: 0.001)
    }

    // Direction B: string value
    var valDynStr = DynamicMessage(descriptor: valueDesc)
    try valDynStr.set("hello", forField: 3)  // string_value

    var dynamicStr = DynamicMessage(descriptor: desc)
    try dynamicStr.set(valDynStr, forField: 6)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamicStr, registry: registry, protoType: Testcompat_WKTHolder.self) {
      decoded in
      XCTAssertEqual(decoded.valueVal.stringValue, "hello")
    }

    // Direction B: bool value
    var valDynBool = DynamicMessage(descriptor: valueDesc)
    try valDynBool.set(true, forField: 4)  // bool_value

    var dynamicBool = DynamicMessage(descriptor: desc)
    try dynamicBool.set(valDynBool, forField: 6)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamicBool, registry: registry, protoType: Testcompat_WKTHolder.self) {
      decoded in
      XCTAssertTrue(decoded.valueVal.boolValue)
    }
  }

  // MARK: - ListValue

  func test_wkt_listValue_bidirectional() throws {
    var proto = Testcompat_WKTHolder()
    proto.listVal.values = [
      Google_Protobuf_Value.with { $0.numberValue = 1 },
      Google_Protobuf_Value.with { $0.stringValue = "two" },
      Google_Protobuf_Value.with { $0.boolValue = false },
    ]

    let desc = CompatDescriptors.wktHolder()
    // Direction A: verify ListValue is deserialized correctly
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let listDyn = try XCTUnwrap(try msg.get(forField: 7) as? DynamicMessage)
      XCTAssertEqual(listDyn.descriptor.name, "ListValue")
    }

    // Direction B: build ListValue with real data → SwiftProtobuf → verify contents
    let listDesc = CompatDescriptors.wktListValue()
    let valueDesc = CompatDescriptors.wktValue()

    var v1 = DynamicMessage(descriptor: valueDesc)
    try v1.set(Double(1), forField: 2)  // number_value

    var v2 = DynamicMessage(descriptor: valueDesc)
    try v2.set("two", forField: 3)  // string_value

    var v3 = DynamicMessage(descriptor: valueDesc)
    try v3.set(false, forField: 4)  // bool_value

    var listDyn = DynamicMessage(descriptor: listDesc)
    try listDyn.set([v1, v2, v3] as [DynamicMessage], forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(listDyn, forField: 7)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTHolder.self) {
      decoded in
      XCTAssertTrue(decoded.hasListVal)
      XCTAssertEqual(decoded.listVal.values.count, 3)
      XCTAssertEqual(decoded.listVal.values[0].numberValue, 1)
      XCTAssertEqual(decoded.listVal.values[1].stringValue, "two")
      XCTAssertFalse(decoded.listVal.values[2].boolValue)
    }
  }

  // MARK: - WKT nested: Inner with Timestamp + Duration + wrapper

  func test_wkt_nested_innerWithWKTs_bidirectional() throws {
    var proto = Testcompat_WKTNested()
    proto.primary.created.seconds = 12345
    proto.primary.ttl.seconds = 60
    proto.primary.count.value = 7

    let desc = CompatDescriptors.wktNested()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let primary = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
      let created = try XCTUnwrap(try primary.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try created.get(forField: 1) as? Int64, 12345)
      let ttl = try XCTUnwrap(try primary.get(forField: 2) as? DynamicMessage)
      XCTAssertEqual(try ttl.get(forField: 1) as? Int64, 60)
      let count = try XCTUnwrap(try primary.get(forField: 3) as? DynamicMessage)
      XCTAssertEqual(try count.get(forField: 1) as? Int32, 7)
    }

    let nestedDesc = CompatDescriptors.wktNested()
    let innerDesc = try XCTUnwrap(nestedDesc.nestedMessages["Inner"])

    let tsDesc = CompatDescriptors.wktTimestamp()
    var tsDyn = DynamicMessage(descriptor: tsDesc)
    try tsDyn.set(Int64(12345), forField: 1)

    let durDesc = CompatDescriptors.wktDuration()
    var durDyn = DynamicMessage(descriptor: durDesc)
    try durDyn.set(Int64(60), forField: 1)

    let i32wDesc = CompatDescriptors.wktWrapper(name: "Int32Value", fieldType: .int32)
    var i32wDyn = DynamicMessage(descriptor: i32wDesc)
    try i32wDyn.set(Int32(7), forField: 1)

    var innerDyn = DynamicMessage(descriptor: innerDesc)
    try innerDyn.set(tsDyn, forField: 1)
    try innerDyn.set(durDyn, forField: 2)
    try innerDyn.set(i32wDyn, forField: 3)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(innerDyn, forField: 1)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTNested.self) {
      decoded in
      XCTAssertEqual(decoded.primary.created.seconds, 12345)
      XCTAssertEqual(decoded.primary.ttl.seconds, 60)
      XCTAssertEqual(decoded.primary.count.value, 7)
    }
  }

  // MARK: - WKT nested: repeated history

  func test_wkt_nested_repeatedHistory_bidirectional() throws {
    var proto = Testcompat_WKTNested()
    var e1 = Testcompat_WKTNested.Inner()
    e1.created.seconds = 100
    var e2 = Testcompat_WKTNested.Inner()
    e2.created.seconds = 200
    proto.history = [e1, e2]

    let desc = CompatDescriptors.wktNested()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let hist = try XCTUnwrap(try msg.get(forField: 2) as? [DynamicMessage])
      XCTAssertEqual(hist.count, 2)
      let ts0 = try XCTUnwrap(try hist[0].get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try ts0.get(forField: 1) as? Int64, 100)
    }

    let nestedDesc = CompatDescriptors.wktNested()
    let innerDesc = try XCTUnwrap(nestedDesc.nestedMessages["Inner"])
    let tsDesc = CompatDescriptors.wktTimestamp()

    var ts1 = DynamicMessage(descriptor: tsDesc)
    try ts1.set(Int64(100), forField: 1)
    var inner1 = DynamicMessage(descriptor: innerDesc)
    try inner1.set(ts1, forField: 1)

    var ts2 = DynamicMessage(descriptor: tsDesc)
    try ts2.set(Int64(200), forField: 1)
    var inner2 = DynamicMessage(descriptor: innerDesc)
    try inner2.set(ts2, forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set([inner1, inner2] as [DynamicMessage], forField: 2)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTNested.self) {
      decoded in
      XCTAssertEqual(decoded.history.count, 2)
      XCTAssertEqual(decoded.history[0].created.seconds, 100)
    }
  }

  // MARK: - WKT mixed: oneof with Duration

  func test_wkt_mixed_oneofDuration_bidirectional() throws {
    var proto = Testcompat_WKTMixed()
    proto.ts.seconds = 500
    proto.durVal.seconds = 120
    proto.status = .active

    let desc = CompatDescriptors.wktMixed()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let tsDyn = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try tsDyn.get(forField: 1) as? Int64, 500)
      let durDyn = try XCTUnwrap(try msg.get(forField: 4) as? DynamicMessage)
      XCTAssertEqual(try durDyn.get(forField: 1) as? Int64, 120)
      XCTAssertEqual(try msg.get(forField: 12) as? Int32, 1)
    }

    let tsDesc = CompatDescriptors.wktTimestamp()
    var tsDyn = DynamicMessage(descriptor: tsDesc)
    try tsDyn.set(Int64(500), forField: 1)

    let durDesc = CompatDescriptors.wktDuration()
    var durDyn = DynamicMessage(descriptor: durDesc)
    try durDyn.set(Int64(120), forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(tsDyn, forField: 1)
    try dynamic.set(durDyn, forField: 4)
    try dynamic.set(Int32(1), forField: 12)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTMixed.self) {
      decoded in
      XCTAssertEqual(decoded.ts.seconds, 500)
      if case .durVal(let d) = decoded.wktOrScalar {
        XCTAssertEqual(d.seconds, 120)
      }
      else {
        XCTFail("wrong oneof case")
      }
      XCTAssertEqual(decoded.status, .active)
    }
  }

  // MARK: - WKT map: map<string, Struct>

  func test_wkt_mapValues_structMap_bidirectional() throws {
    var proto = Testcompat_MapWKTValues()
    proto.structMap["config"] = Google_Protobuf_Struct.with {
      $0.fields["key"] = Google_Protobuf_Value.with { $0.stringValue = "v" }
    }

    let desc = CompatDescriptors.mapWKTValues()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let map = try XCTUnwrap(try msg.get(forField: 4) as? [AnyHashable: Any])
      let sDyn = try XCTUnwrap(map["config"] as? DynamicMessage)
      XCTAssertEqual(sDyn.descriptor.name, "Struct")
    }

    let structDesc = CompatDescriptors.wktStruct()
    let structDyn = DynamicMessage(descriptor: structDesc)
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry(structDyn, forKey: "config", inField: 4)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MapWKTValues.self) {
      decoded in
      XCTAssertNotNil(decoded.structMap["config"])
    }
  }

  // MARK: - All WKT fields at once (WKTHolder fully populated)

  func test_wkt_allFieldsAtOnce_bidirectional() throws {
    var proto = Testcompat_WKTHolder()
    proto.ts.seconds = 1_000_000
    proto.dur.seconds = 3600
    proto.mask.paths = ["a.b", "c"]
    proto.dblW.value = 2.71
    proto.fltW.value = 1.5
    proto.i64W.value = Int64.max
    proto.u64W.value = UInt64.max
    proto.i32W.value = Int32.max
    proto.u32W.value = UInt32.max
    proto.boolW.value = true
    proto.strW.value = "hello"
    proto.bytesW.value = Data([0x01, 0x02])
    proto.emptyVal = Google_Protobuf_Empty()

    let desc = CompatDescriptors.wktHolder()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let tsDyn = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try tsDyn.get(forField: 1) as? Int64, 1_000_000)
      let i64wDyn = try XCTUnwrap(try msg.get(forField: 10) as? DynamicMessage)
      XCTAssertEqual(try i64wDyn.get(forField: 1) as? Int64, Int64.max)
      let strwDyn = try XCTUnwrap(try msg.get(forField: 15) as? DynamicMessage)
      XCTAssertEqual(try strwDyn.get(forField: 1) as? String, "hello")
    }

    let tsDesc = CompatDescriptors.wktTimestamp()
    var tsDyn = DynamicMessage(descriptor: tsDesc)
    try tsDyn.set(Int64(1_000_000), forField: 1)

    let strwDesc = CompatDescriptors.wktWrapper(name: "StringValue", fieldType: .string)
    var strwDyn = DynamicMessage(descriptor: strwDesc)
    try strwDyn.set("hello", forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(tsDyn, forField: 1)
    try dynamic.set(strwDyn, forField: 15)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTHolder.self) {
      decoded in
      XCTAssertEqual(decoded.ts.seconds, 1_000_000)
      XCTAssertEqual(decoded.strW.value, "hello")
    }
  }

  // MARK: - Any wrapping a WKT (Timestamp)

  func test_wkt_any_wktValue_bidirectional() throws {
    let ts = Google_Protobuf_Timestamp.with {
      $0.seconds = 1_700_000_000
      $0.nanos = 500_000_000
    }
    let packed = try Google_Protobuf_Any(message: ts)

    var proto = Testcompat_WKTHolder()
    proto.anyVal = packed

    let desc = CompatDescriptors.wktHolder()
    let anyDesc = CompatDescriptors.wktAny()

    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let anyDyn = try XCTUnwrap(try msg.get(forField: 4) as? DynamicMessage)
      XCTAssertEqual(anyDyn.descriptor.name, "Any")
      let typeUrl = try XCTUnwrap(try anyDyn.get(forField: 1) as? String)
      XCTAssertTrue(typeUrl.contains("Timestamp"), "typeUrl should reference Timestamp: \(typeUrl)")
    }

    var anyDyn = DynamicMessage(descriptor: anyDesc)
    try anyDyn.set("type.googleapis.com/google.protobuf.Timestamp", forField: 1)
    let tsData = try ts.serializedData()
    try anyDyn.set(tsData, forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(anyDyn, forField: 4)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WKTHolder.self) {
      decoded in
      XCTAssertTrue(
        decoded.anyVal.typeURL.contains("Timestamp"),
        "typeURL should reference Timestamp: \(decoded.anyVal.typeURL)"
      )
      let decodedTs = try Google_Protobuf_Timestamp(unpackingAny: decoded.anyVal)
      XCTAssertEqual(decodedTs.seconds, 1_700_000_000)
      XCTAssertEqual(decodedTs.nanos, 500_000_000)
    }
  }

  // MARK: - All WKTs absent → empty JSON

  func test_wkt_allAbsent_emptyJSON() throws {
    let proto = Testcompat_WKTHolder()
    let jsonStr = try proto.jsonString()
    XCTAssertEqual(jsonStr, "{}")

    let desc = CompatDescriptors.wktHolder()
    let dynamic = DynamicMessage(descriptor: desc)
    let jsonData = try CompatHelpers.makeSerializer(registry: registry).serialize(dynamic)
    let ourJson = try XCTUnwrap(String(data: jsonData, encoding: .utf8))
    XCTAssertEqual(ourJson, "{}")
  }
}
