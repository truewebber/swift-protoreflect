// BinaryCompatWKTTests.swift
// SwiftProtoReflectTests
//
// Group: Well-Known Types — bidirectional binary compatibility tests.
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
// Binary-specific notes:
//   - WKTs are encoded as ordinary nested messages — no special canonical representation.
//   - Timestamp.nanos=0 is proto3 default; it MUST be omitted from wire.
//   - Map fields: byte-for-byte comparison is unreliable (non-deterministic iteration order).
//     Use round-trip-then-compare-values pattern for all map-containing tests.

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class BinaryCompatWKTTests: XCTestCase {

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

  // MARK: - 1. Timestamp (two varint fields: seconds, nanos)

  func test_wkt_timestamp_bidirectional() async throws {
    var proto = Testcompat_WKTHolder()
    proto.ts.seconds = 1_700_000_000
    proto.ts.nanos = 500_000_000

    let desc = CompatDescriptors.wktHolder()
    let tsDesc = CompatDescriptors.wktTimestamp()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let tsDyn = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
        XCTAssertEqual(try tsDyn.get(forField: 1) as? Int64, 1_700_000_000)
        XCTAssertEqual(try tsDyn.get(forField: 2) as? Int32, 500_000_000)
      },
      buildDynamic: {
        var tsDyn = DynamicMessage(descriptor: tsDesc)
        try tsDyn.set(Int64(1_700_000_000), forField: 1)
        try tsDyn.set(Int32(500_000_000), forField: 2)
        var d = DynamicMessage(descriptor: desc)
        try d.set(tsDyn, forField: 1)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.ts.seconds, 1_700_000_000)
        XCTAssertEqual(p.ts.nanos, 500_000_000)
      }
    )
  }

  // MARK: - 2. Duration (seconds=3600, nanos=0)

  func test_wkt_duration_bidirectional() async throws {
    var proto = Testcompat_WKTHolder()
    proto.dur.seconds = 3600

    let desc = CompatDescriptors.wktHolder()
    let durDesc = CompatDescriptors.wktDuration()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let durDyn = try XCTUnwrap(try msg.get(forField: 2) as? DynamicMessage)
        XCTAssertEqual(try durDyn.get(forField: 1) as? Int64, 3600)
        // nanos=0 is the proto3 default; field may be absent — treat nil as 0
        XCTAssertEqual((try durDyn.get(forField: 2) as? Int32) ?? 0, 0)
      },
      buildDynamic: {
        var durDyn = DynamicMessage(descriptor: durDesc)
        try durDyn.set(Int64(3600), forField: 1)
        var d = DynamicMessage(descriptor: desc)
        try d.set(durDyn, forField: 2)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.dur.seconds, 3600)
        XCTAssertEqual(p.dur.nanos, 0)
      }
    )
  }

  // MARK: - 3. FieldMask (repeated string paths)

  func test_wkt_fieldMask_bidirectional() async throws {
    var proto = Testcompat_WKTHolder()
    proto.mask.paths = ["field_one", "nested.field_two", "another"]

    let desc = CompatDescriptors.wktHolder()
    let fmDesc = CompatDescriptors.wktFieldMask()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let fmDyn = try XCTUnwrap(try msg.get(forField: 3) as? DynamicMessage)
        XCTAssertEqual(
          try fmDyn.get(forField: 1) as? [String],
          ["field_one", "nested.field_two", "another"]
        )
      },
      buildDynamic: {
        var fmDyn = DynamicMessage(descriptor: fmDesc)
        try fmDyn.set(["field_one", "nested.field_two", "another"] as [String], forField: 1)
        var d = DynamicMessage(descriptor: desc)
        try d.set(fmDyn, forField: 3)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.mask.paths, ["field_one", "nested.field_two", "another"])
      }
    )
  }

  // MARK: - 4. Int64Value wrapper (value=Int64.max)

  func test_wkt_int64Value_bidirectional() async throws {
    var proto = Testcompat_WKTHolder()
    proto.i64W.value = Int64.max

    let desc = CompatDescriptors.wktHolder()
    let wrapDesc = CompatDescriptors.wktWrapper(name: "Int64Value", fieldType: .int64)

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let wDyn = try XCTUnwrap(try msg.get(forField: 10) as? DynamicMessage)
        XCTAssertEqual(try wDyn.get(forField: 1) as? Int64, Int64.max)
      },
      buildDynamic: {
        var wDyn = DynamicMessage(descriptor: wrapDesc)
        try wDyn.set(Int64.max, forField: 1)
        var d = DynamicMessage(descriptor: desc)
        try d.set(wDyn, forField: 10)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.i64W.value, Int64.max)
      }
    )
  }

  // MARK: - 5. StringValue wrapper (value="wrapped string")

  func test_wkt_stringValue_bidirectional() async throws {
    var proto = Testcompat_WKTHolder()
    proto.strW.value = "wrapped string"

    let desc = CompatDescriptors.wktHolder()
    let wrapDesc = CompatDescriptors.wktWrapper(name: "StringValue", fieldType: .string)

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let wDyn = try XCTUnwrap(try msg.get(forField: 15) as? DynamicMessage)
        XCTAssertEqual(try wDyn.get(forField: 1) as? String, "wrapped string")
      },
      buildDynamic: {
        var wDyn = DynamicMessage(descriptor: wrapDesc)
        try wDyn.set("wrapped string", forField: 1)
        var d = DynamicMessage(descriptor: desc)
        try d.set(wDyn, forField: 15)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.strW.value, "wrapped string")
      }
    )
  }

  // MARK: - 6. BoolValue wrapper (value=true)

  func test_wkt_boolValue_bidirectional() async throws {
    var proto = Testcompat_WKTHolder()
    proto.boolW.value = true

    let desc = CompatDescriptors.wktHolder()
    let wrapDesc = CompatDescriptors.wktWrapper(name: "BoolValue", fieldType: .bool)

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let wDyn = try XCTUnwrap(try msg.get(forField: 14) as? DynamicMessage)
        XCTAssertEqual(try wDyn.get(forField: 1) as? Bool, true)
      },
      buildDynamic: {
        var wDyn = DynamicMessage(descriptor: wrapDesc)
        try wDyn.set(true, forField: 1)
        var d = DynamicMessage(descriptor: desc)
        try d.set(wDyn, forField: 14)
        return d
      },
      validateProto: { p in
        XCTAssertTrue(p.boolW.value)
      }
    )
  }

  // MARK: - 7. BytesValue wrapper (value=Data([0x01,0x02,0x03]))

  func test_wkt_bytesValue_bidirectional() async throws {
    let testBytes = Data([0x01, 0x02, 0x03])
    var proto = Testcompat_WKTHolder()
    proto.bytesW.value = testBytes

    let desc = CompatDescriptors.wktHolder()
    let wrapDesc = CompatDescriptors.wktWrapper(name: "BytesValue", fieldType: .bytes)

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let wDyn = try XCTUnwrap(try msg.get(forField: 16) as? DynamicMessage)
        XCTAssertEqual(try wDyn.get(forField: 1) as? Data, testBytes)
      },
      buildDynamic: {
        var wDyn = DynamicMessage(descriptor: wrapDesc)
        try wDyn.set(testBytes, forField: 1)
        var d = DynamicMessage(descriptor: desc)
        try d.set(wDyn, forField: 16)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.bytesW.value, testBytes)
      }
    )
  }

  // MARK: - 8. DoubleValue wrapper (value=3.14, 8-byte fixed)

  func test_wkt_doubleValue_bidirectional() async throws {
    var proto = Testcompat_WKTHolder()
    proto.dblW.value = 3.14

    let desc = CompatDescriptors.wktHolder()
    let wrapDesc = CompatDescriptors.wktWrapper(name: "DoubleValue", fieldType: .double)

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let wDyn = try XCTUnwrap(try msg.get(forField: 8) as? DynamicMessage)
        XCTAssertEqual(try wDyn.get(forField: 1) as? Double, 3.14)
      },
      buildDynamic: {
        var wDyn = DynamicMessage(descriptor: wrapDesc)
        try wDyn.set(Double(3.14), forField: 1)
        var d = DynamicMessage(descriptor: desc)
        try d.set(wDyn, forField: 8)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.dblW.value, 3.14)
      }
    )
  }

  // MARK: - 9. FloatValue wrapper (value=2.5, 4-byte fixed)

  func test_wkt_floatValue_bidirectional() async throws {
    var proto = Testcompat_WKTHolder()
    proto.fltW.value = 2.5

    let desc = CompatDescriptors.wktHolder()
    let wrapDesc = CompatDescriptors.wktWrapper(name: "FloatValue", fieldType: .float)

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let wDyn = try XCTUnwrap(try msg.get(forField: 9) as? DynamicMessage)
        XCTAssertEqual(try wDyn.get(forField: 1) as? Float, 2.5)
      },
      buildDynamic: {
        var wDyn = DynamicMessage(descriptor: wrapDesc)
        try wDyn.set(Float(2.5), forField: 1)
        var d = DynamicMessage(descriptor: desc)
        try d.set(wDyn, forField: 9)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.fltW.value, 2.5)
      }
    )
  }

  // MARK: - 10. Int32Value wrapper (value=Int32.max)

  func test_wkt_int32Value_bidirectional() async throws {
    var proto = Testcompat_WKTHolder()
    proto.i32W.value = Int32.max

    let desc = CompatDescriptors.wktHolder()
    let wrapDesc = CompatDescriptors.wktWrapper(name: "Int32Value", fieldType: .int32)

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let wDyn = try XCTUnwrap(try msg.get(forField: 12) as? DynamicMessage)
        XCTAssertEqual(try wDyn.get(forField: 1) as? Int32, Int32.max)
      },
      buildDynamic: {
        var wDyn = DynamicMessage(descriptor: wrapDesc)
        try wDyn.set(Int32.max, forField: 1)
        var d = DynamicMessage(descriptor: desc)
        try d.set(wDyn, forField: 12)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.i32W.value, Int32.max)
      }
    )
  }

  // MARK: - 11. UInt32Value wrapper (value=UInt32.max)

  func test_wkt_uint32Value_bidirectional() async throws {
    var proto = Testcompat_WKTHolder()
    proto.u32W.value = UInt32.max

    let desc = CompatDescriptors.wktHolder()
    let wrapDesc = CompatDescriptors.wktWrapper(name: "UInt32Value", fieldType: .uint32)

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let wDyn = try XCTUnwrap(try msg.get(forField: 13) as? DynamicMessage)
        XCTAssertEqual(try wDyn.get(forField: 1) as? UInt32, UInt32.max)
      },
      buildDynamic: {
        var wDyn = DynamicMessage(descriptor: wrapDesc)
        try wDyn.set(UInt32.max, forField: 1)
        var d = DynamicMessage(descriptor: desc)
        try d.set(wDyn, forField: 13)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.u32W.value, UInt32.max)
      }
    )
  }

  // MARK: - 12. UInt64Value wrapper (value=UInt64.max)

  func test_wkt_uint64Value_bidirectional() async throws {
    var proto = Testcompat_WKTHolder()
    proto.u64W.value = UInt64.max

    let desc = CompatDescriptors.wktHolder()
    let wrapDesc = CompatDescriptors.wktWrapper(name: "UInt64Value", fieldType: .uint64)

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let wDyn = try XCTUnwrap(try msg.get(forField: 11) as? DynamicMessage)
        XCTAssertEqual(try wDyn.get(forField: 1) as? UInt64, UInt64.max)
      },
      buildDynamic: {
        var wDyn = DynamicMessage(descriptor: wrapDesc)
        try wDyn.set(UInt64.max, forField: 1)
        var d = DynamicMessage(descriptor: desc)
        try d.set(wDyn, forField: 11)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.u64W.value, UInt64.max)
      }
    )
  }

  // MARK: - 13. Empty (encoded as zero bytes inside LEN field)

  func test_wkt_empty_bidirectional() async throws {
    var proto = Testcompat_WKTHolder()
    proto.emptyVal = Google_Protobuf_Empty()

    let desc = CompatDescriptors.wktHolder()
    let emptyDesc = CompatDescriptors.wktEmpty()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let eDyn = try XCTUnwrap(try msg.get(forField: 17) as? DynamicMessage)
        XCTAssertEqual(eDyn.descriptor.name, "Empty")
      },
      buildDynamic: {
        let eDyn = DynamicMessage(descriptor: emptyDesc)
        var d = DynamicMessage(descriptor: desc)
        try d.set(eDyn, forField: 17)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.emptyVal, Google_Protobuf_Empty())
      }
    )
  }

  // MARK: - 14. Repeated Timestamp: two messages

  func test_wkt_repeatedTimestamps_bidirectional() async throws {
    var proto = Testcompat_RepeatedWKTs()
    var ts1 = Google_Protobuf_Timestamp()
    ts1.seconds = 100
    var ts2 = Google_Protobuf_Timestamp()
    ts2.seconds = 200
    proto.timestamps = [ts1, ts2]

    let desc = CompatDescriptors.repeatedWKTs()
    let tsDesc = CompatDescriptors.wktTimestamp()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let tsList = try XCTUnwrap(try msg.get(forField: 1) as? [DynamicMessage])
        XCTAssertEqual(tsList.count, 2)
        XCTAssertEqual(try tsList[0].get(forField: 1) as? Int64, 100)
        XCTAssertEqual(try tsList[1].get(forField: 1) as? Int64, 200)
      },
      buildDynamic: {
        var tsDyn1 = DynamicMessage(descriptor: tsDesc)
        try tsDyn1.set(Int64(100), forField: 1)
        var tsDyn2 = DynamicMessage(descriptor: tsDesc)
        try tsDyn2.set(Int64(200), forField: 1)
        var d = DynamicMessage(descriptor: desc)
        try d.set([tsDyn1, tsDyn2] as [DynamicMessage], forField: 1)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.timestamps.count, 2)
        XCTAssertEqual(p.timestamps[0].seconds, 100)
        XCTAssertEqual(p.timestamps[1].seconds, 200)
      }
    )
  }

  // MARK: - 15. Repeated StringValue: three wrappers ("a", "b", "")

  func test_wkt_repeatedStringValues_bidirectional() async throws {
    var proto = Testcompat_RepeatedWKTs()
    var sv1 = Google_Protobuf_StringValue()
    sv1.value = "a"
    var sv2 = Google_Protobuf_StringValue()
    sv2.value = "b"
    let sv3 = Google_Protobuf_StringValue()
    proto.stringVals = [sv1, sv2, sv3]

    let desc = CompatDescriptors.repeatedWKTs()
    let strWrapDesc = CompatDescriptors.wktWrapper(name: "StringValue", fieldType: .string)

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let vals = try XCTUnwrap(try msg.get(forField: 4) as? [DynamicMessage])
        XCTAssertEqual(vals.count, 3)
        XCTAssertEqual(try vals[0].get(forField: 1) as? String, "a")
        XCTAssertEqual(try vals[1].get(forField: 1) as? String, "b")
      },
      buildDynamic: {
        var sw1 = DynamicMessage(descriptor: strWrapDesc)
        try sw1.set("a", forField: 1)
        var sw2 = DynamicMessage(descriptor: strWrapDesc)
        try sw2.set("b", forField: 1)
        let sw3 = DynamicMessage(descriptor: strWrapDesc)
        var d = DynamicMessage(descriptor: desc)
        try d.set([sw1, sw2, sw3] as [DynamicMessage], forField: 4)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.stringVals.count, 3)
        XCTAssertEqual(p.stringVals[0].value, "a")
        XCTAssertEqual(p.stringVals[1].value, "b")
        XCTAssertEqual(p.stringVals[2].value, "")
      }
    )
  }

  // MARK: - 16. Map<string, Timestamp>: one entry "now"→seconds=999

  func test_wkt_mapTimestampValues_bidirectional() async throws {
    var proto = Testcompat_MapWKTValues()
    var ts = Google_Protobuf_Timestamp()
    ts.seconds = 999
    proto.tsMap = ["now": ts]

    let desc = CompatDescriptors.mapWKTValues()
    let tsDesc = CompatDescriptors.wktTimestamp()

    // Direction A: oracle → our deserializer
    try await BinaryCompatHelpers.assertOracleToUs(
      proto: proto,
      descriptor: desc,
      registry: registry
    ) { msg in
      let mapVal = try XCTUnwrap(try msg.get(forField: 1) as? [AnyHashable: Any])
      let tsDyn = try XCTUnwrap(mapVal["now"] as? DynamicMessage)
      XCTAssertEqual(try tsDyn.get(forField: 1) as? Int64, 999)
    }

    // Direction B: our serializer → oracle (round-trip-then-compare-values, no byte comparison)
    var tsDyn = DynamicMessage(descriptor: tsDesc)
    try tsDyn.set(Int64(999), forField: 1)
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry(tsDyn, forKey: "now", inField: 1)

    try await BinaryCompatHelpers.assertUsToOracle(
      dynamic: dynamic,
      protoType: Testcompat_MapWKTValues.self
    ) { decoded in
      XCTAssertEqual(decoded.tsMap["now"]?.seconds, 999)
    }
  }

  // MARK: - 17. Any wrapping a regular SimpleMessage

  func test_wkt_any_regularMessage_bidirectional() async throws {
    var inner = Testcompat_SimpleMessage()
    inner.id = 42
    inner.name = "any_inner"
    let packed = try Google_Protobuf_Any(message: inner)

    var proto = Testcompat_WKTHolder()
    proto.anyVal = packed

    let desc = CompatDescriptors.wktHolder()
    let anyDesc = CompatDescriptors.wktAny()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let anyDyn = try XCTUnwrap(try msg.get(forField: 4) as? DynamicMessage)
        XCTAssertEqual(anyDyn.descriptor.name, "Any")
        let typeUrl = try XCTUnwrap(try anyDyn.get(forField: 1) as? String)
        XCTAssertTrue(typeUrl.contains("SimpleMessage"), "typeUrl should reference SimpleMessage: \(typeUrl)")
      },
      buildDynamic: {
        var anyDyn = DynamicMessage(descriptor: anyDesc)
        try anyDyn.set("type.googleapis.com/testcompat.SimpleMessage", forField: 1)
        let innerData = try inner.serializedData()
        try anyDyn.set(innerData, forField: 2)
        var d = DynamicMessage(descriptor: desc)
        try d.set(anyDyn, forField: 4)
        return d
      },
      validateProto: { p in
        XCTAssertFalse(p.anyVal.typeURL.isEmpty, "typeURL must be set")
        XCTAssertTrue(p.anyVal.typeURL.contains("SimpleMessage"))
      }
    )
  }

  // MARK: - 18. Struct (fields map with string, number, bool Value entries)

  func test_wkt_struct_bidirectional() async throws {
    var proto = Testcompat_WKTHolder()
    proto.structVal.fields["name"] = Google_Protobuf_Value.with { $0.stringValue = "test" }
    proto.structVal.fields["count"] = Google_Protobuf_Value.with { $0.numberValue = 5 }
    proto.structVal.fields["active"] = Google_Protobuf_Value.with { $0.boolValue = true }

    let desc = CompatDescriptors.wktHolder()
    let structDesc = CompatDescriptors.wktStruct()
    let valueDesc = CompatDescriptors.wktValue()

    // Direction A: verify Struct is deserialized as a DynamicMessage named "Struct"
    try await BinaryCompatHelpers.assertOracleToUs(
      proto: proto,
      descriptor: desc,
      registry: registry
    ) { msg in
      let structDyn = try XCTUnwrap(try msg.get(forField: 5) as? DynamicMessage)
      XCTAssertEqual(structDyn.descriptor.name, "Struct")
    }

    // Direction B: build Struct DynamicMessage → oracle → verify content
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

    try await BinaryCompatHelpers.assertUsToOracle(
      dynamic: dynamic,
      protoType: Testcompat_WKTHolder.self
    ) { decoded in
      XCTAssertTrue(decoded.hasStructVal)
      XCTAssertEqual(decoded.structVal.fields["name"]?.stringValue, "test")
      XCTAssertEqual(decoded.structVal.fields["count"]?.numberValue, 5)
      XCTAssertEqual(decoded.structVal.fields["active"]?.boolValue, true)
    }
  }

  // MARK: - 19. Value oneof: null, number, string, bool kinds

  func test_wkt_value_allKinds_bidirectional() async throws {
    let desc = CompatDescriptors.wktHolder()

    // Direction A: each Value kind round-trips through oracle → our deserializer
    let kindCases: [(Testcompat_WKTHolder, String)] = [
      (
        {
          var h = Testcompat_WKTHolder()
          h.valueVal = Google_Protobuf_Value.with { $0.nullValue = .nullValue }
          return h
        }(), "null"
      ),
      (
        {
          var h = Testcompat_WKTHolder()
          h.valueVal = Google_Protobuf_Value.with { $0.numberValue = 3.14 }
          return h
        }(), "number"
      ),
      (
        {
          var h = Testcompat_WKTHolder()
          h.valueVal = Google_Protobuf_Value.with { $0.stringValue = "hello" }
          return h
        }(), "string"
      ),
      (
        {
          var h = Testcompat_WKTHolder()
          h.valueVal = Google_Protobuf_Value.with { $0.boolValue = true }
          return h
        }(), "bool"
      ),
    ]

    for (proto, label) in kindCases {
      try await BinaryCompatHelpers.assertOracleToUs(
        proto: proto,
        descriptor: desc,
        registry: registry
      ) { msg in
        let valDyn = try XCTUnwrap(try msg.get(forField: 6) as? DynamicMessage)
        XCTAssertEqual(valDyn.descriptor.name, "Value", "Value descriptor for kind '\(label)'")
      }
    }

    // Direction B: number_value
    let valueDesc = CompatDescriptors.wktValue()
    var valNum = DynamicMessage(descriptor: valueDesc)
    try valNum.set(Double(3.14), forField: 2)

    var dynNum = DynamicMessage(descriptor: desc)
    try dynNum.set(valNum, forField: 6)

    try await BinaryCompatHelpers.assertUsToOracle(dynamic: dynNum, protoType: Testcompat_WKTHolder.self) { decoded in
      XCTAssertTrue(decoded.hasValueVal)
      XCTAssertEqual(decoded.valueVal.numberValue, 3.14, accuracy: 0.001)
    }

    // Direction B: string_value
    var valStr = DynamicMessage(descriptor: valueDesc)
    try valStr.set("hello", forField: 3)

    var dynStr = DynamicMessage(descriptor: desc)
    try dynStr.set(valStr, forField: 6)

    try await BinaryCompatHelpers.assertUsToOracle(dynamic: dynStr, protoType: Testcompat_WKTHolder.self) { decoded in
      XCTAssertEqual(decoded.valueVal.stringValue, "hello")
    }

    // Direction B: bool_value
    var valBool = DynamicMessage(descriptor: valueDesc)
    try valBool.set(true, forField: 4)

    var dynBool = DynamicMessage(descriptor: desc)
    try dynBool.set(valBool, forField: 6)

    try await BinaryCompatHelpers.assertUsToOracle(dynamic: dynBool, protoType: Testcompat_WKTHolder.self) { decoded in
      XCTAssertTrue(decoded.valueVal.boolValue)
    }
  }

  // MARK: - 20. ListValue (repeated Value: number, string, bool)

  func test_wkt_listValue_bidirectional() async throws {
    var proto = Testcompat_WKTHolder()
    proto.listVal.values = [
      Google_Protobuf_Value.with { $0.numberValue = 1 },
      Google_Protobuf_Value.with { $0.stringValue = "two" },
      Google_Protobuf_Value.with { $0.boolValue = false },
    ]

    let desc = CompatDescriptors.wktHolder()
    let listDesc = CompatDescriptors.wktListValue()
    let valueDesc = CompatDescriptors.wktValue()

    // Direction A: verify ListValue is deserialized correctly
    try await BinaryCompatHelpers.assertOracleToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let listDyn = try XCTUnwrap(try msg.get(forField: 7) as? DynamicMessage)
      XCTAssertEqual(listDyn.descriptor.name, "ListValue")
    }

    // Direction B: build ListValue with real data → oracle → verify contents
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

    try await BinaryCompatHelpers.assertUsToOracle(dynamic: dynamic, protoType: Testcompat_WKTHolder.self) { decoded in
      XCTAssertTrue(decoded.hasListVal)
      XCTAssertEqual(decoded.listVal.values.count, 3)
      XCTAssertEqual(decoded.listVal.values[0].numberValue, 1)
      XCTAssertEqual(decoded.listVal.values[1].stringValue, "two")
      XCTAssertFalse(decoded.listVal.values[2].boolValue)
    }
  }

  // MARK: - 21. WKTNested.Inner: Timestamp + Duration + Int32Value combined

  func test_wkt_nested_innerWithWKTs_bidirectional() async throws {
    var proto = Testcompat_WKTNested()
    proto.primary.created.seconds = 12345
    proto.primary.ttl.seconds = 60
    proto.primary.count.value = 7

    let desc = CompatDescriptors.wktNested()
    let tsDesc = CompatDescriptors.wktTimestamp()
    let durDesc = CompatDescriptors.wktDuration()
    let i32wDesc = CompatDescriptors.wktWrapper(name: "Int32Value", fieldType: .int32)

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let primary = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
        let created = try XCTUnwrap(try primary.get(forField: 1) as? DynamicMessage)
        XCTAssertEqual(try created.get(forField: 1) as? Int64, 12345)
        let ttl = try XCTUnwrap(try primary.get(forField: 2) as? DynamicMessage)
        XCTAssertEqual(try ttl.get(forField: 1) as? Int64, 60)
        let count = try XCTUnwrap(try primary.get(forField: 3) as? DynamicMessage)
        XCTAssertEqual(try count.get(forField: 1) as? Int32, 7)
      },
      buildDynamic: {
        let innerDesc = try XCTUnwrap(desc.nestedMessages["Inner"])

        var tsDyn = DynamicMessage(descriptor: tsDesc)
        try tsDyn.set(Int64(12345), forField: 1)

        var durDyn = DynamicMessage(descriptor: durDesc)
        try durDyn.set(Int64(60), forField: 1)

        var i32wDyn = DynamicMessage(descriptor: i32wDesc)
        try i32wDyn.set(Int32(7), forField: 1)

        var innerDyn = DynamicMessage(descriptor: innerDesc)
        try innerDyn.set(tsDyn, forField: 1)
        try innerDyn.set(durDyn, forField: 2)
        try innerDyn.set(i32wDyn, forField: 3)

        var d = DynamicMessage(descriptor: desc)
        try d.set(innerDyn, forField: 1)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.primary.created.seconds, 12345)
        XCTAssertEqual(p.primary.ttl.seconds, 60)
        XCTAssertEqual(p.primary.count.value, 7)
      }
    )
  }

  // MARK: - 22. WKTNested: repeated Inner history list with two entries

  func test_wkt_nested_repeatedHistory_bidirectional() async throws {
    var proto = Testcompat_WKTNested()
    var e1 = Testcompat_WKTNested.Inner()
    e1.created.seconds = 100
    var e2 = Testcompat_WKTNested.Inner()
    e2.created.seconds = 200
    proto.history = [e1, e2]

    let desc = CompatDescriptors.wktNested()
    let tsDesc = CompatDescriptors.wktTimestamp()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let hist = try XCTUnwrap(try msg.get(forField: 2) as? [DynamicMessage])
        XCTAssertEqual(hist.count, 2)
        let ts0 = try XCTUnwrap(try hist[0].get(forField: 1) as? DynamicMessage)
        XCTAssertEqual(try ts0.get(forField: 1) as? Int64, 100)
        let ts1 = try XCTUnwrap(try hist[1].get(forField: 1) as? DynamicMessage)
        XCTAssertEqual(try ts1.get(forField: 1) as? Int64, 200)
      },
      buildDynamic: {
        let innerDesc = try XCTUnwrap(desc.nestedMessages["Inner"])

        var ts1 = DynamicMessage(descriptor: tsDesc)
        try ts1.set(Int64(100), forField: 1)
        var inner1 = DynamicMessage(descriptor: innerDesc)
        try inner1.set(ts1, forField: 1)

        var ts2 = DynamicMessage(descriptor: tsDesc)
        try ts2.set(Int64(200), forField: 1)
        var inner2 = DynamicMessage(descriptor: innerDesc)
        try inner2.set(ts2, forField: 1)

        var d = DynamicMessage(descriptor: desc)
        try d.set([inner1, inner2] as [DynamicMessage], forField: 2)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.history.count, 2)
        XCTAssertEqual(p.history[0].created.seconds, 100)
        XCTAssertEqual(p.history[1].created.seconds, 200)
      }
    )
  }

  // MARK: - 23. WKTMixed: Timestamp + oneof Duration + status enum

  func test_wkt_mixed_oneofDuration_bidirectional() async throws {
    var proto = Testcompat_WKTMixed()
    proto.ts.seconds = 500
    proto.durVal.seconds = 120
    proto.status = .active

    let desc = CompatDescriptors.wktMixed()
    let tsDesc = CompatDescriptors.wktTimestamp()
    let durDesc = CompatDescriptors.wktDuration()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let tsDyn = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
        XCTAssertEqual(try tsDyn.get(forField: 1) as? Int64, 500)
        let durDyn = try XCTUnwrap(try msg.get(forField: 4) as? DynamicMessage)
        XCTAssertEqual(try durDyn.get(forField: 1) as? Int64, 120)
        XCTAssertEqual(try msg.get(forField: 12) as? Int32, 1)
      },
      buildDynamic: {
        var tsDyn = DynamicMessage(descriptor: tsDesc)
        try tsDyn.set(Int64(500), forField: 1)

        var durDyn = DynamicMessage(descriptor: durDesc)
        try durDyn.set(Int64(120), forField: 1)

        var d = DynamicMessage(descriptor: desc)
        try d.set(tsDyn, forField: 1)
        try d.set(durDyn, forField: 4)
        try d.set(Int32(1), forField: 12)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.ts.seconds, 500)
        if case .durVal(let d) = p.wktOrScalar {
          XCTAssertEqual(d.seconds, 120)
        }
        else {
          XCTFail("wrong oneof case: expected durVal")
        }
        XCTAssertEqual(p.status, .active)
      }
    )
  }

  // MARK: - 24. Map<string, Struct>: one entry "config"

  func test_wkt_mapValues_structMap_bidirectional() async throws {
    var proto = Testcompat_MapWKTValues()
    proto.structMap["config"] = Google_Protobuf_Struct.with {
      $0.fields["key"] = Google_Protobuf_Value.with { $0.stringValue = "v" }
    }

    let desc = CompatDescriptors.mapWKTValues()
    let structDesc = CompatDescriptors.wktStruct()

    // Direction A: oracle → our deserializer
    try await BinaryCompatHelpers.assertOracleToUs(
      proto: proto,
      descriptor: desc,
      registry: registry
    ) { msg in
      let mapVal = try XCTUnwrap(try msg.get(forField: 4) as? [AnyHashable: Any])
      let sDyn = try XCTUnwrap(mapVal["config"] as? DynamicMessage)
      XCTAssertEqual(sDyn.descriptor.name, "Struct")
    }

    // Direction B: our serializer → oracle (round-trip-then-compare-values)
    let structDyn = DynamicMessage(descriptor: structDesc)
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry(structDyn, forKey: "config", inField: 4)

    try await BinaryCompatHelpers.assertUsToOracle(
      dynamic: dynamic,
      protoType: Testcompat_MapWKTValues.self
    ) { decoded in
      XCTAssertNotNil(decoded.structMap["config"])
    }
  }

  // MARK: - 25. WKTHolder with Timestamp + StringValue set simultaneously

  func test_wkt_allFieldsAtOnce_bidirectional() async throws {
    var proto = Testcompat_WKTHolder()
    proto.ts.seconds = 1_000_000
    proto.strW.value = "hello"

    let desc = CompatDescriptors.wktHolder()
    let tsDesc = CompatDescriptors.wktTimestamp()
    let strwDesc = CompatDescriptors.wktWrapper(name: "StringValue", fieldType: .string)

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let tsDyn = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
        XCTAssertEqual(try tsDyn.get(forField: 1) as? Int64, 1_000_000)
        let strwDyn = try XCTUnwrap(try msg.get(forField: 15) as? DynamicMessage)
        XCTAssertEqual(try strwDyn.get(forField: 1) as? String, "hello")
      },
      buildDynamic: {
        var tsDyn = DynamicMessage(descriptor: tsDesc)
        try tsDyn.set(Int64(1_000_000), forField: 1)

        var strwDyn = DynamicMessage(descriptor: strwDesc)
        try strwDyn.set("hello", forField: 1)

        var d = DynamicMessage(descriptor: desc)
        try d.set(tsDyn, forField: 1)
        try d.set(strwDyn, forField: 15)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.ts.seconds, 1_000_000)
        XCTAssertEqual(p.strW.value, "hello")
      }
    )
  }

  // MARK: - 26. Any wrapping a Timestamp: type_url + serialized Timestamp bytes

  func test_wkt_any_wktValue_bidirectional() async throws {
    let ts = Google_Protobuf_Timestamp.with {
      $0.seconds = 1_700_000_000
      $0.nanos = 500_000_000
    }
    let packed = try Google_Protobuf_Any(message: ts)

    var proto = Testcompat_WKTHolder()
    proto.anyVal = packed

    let desc = CompatDescriptors.wktHolder()
    let anyDesc = CompatDescriptors.wktAny()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let anyDyn = try XCTUnwrap(try msg.get(forField: 4) as? DynamicMessage)
        XCTAssertEqual(anyDyn.descriptor.name, "Any")
        let typeUrl = try XCTUnwrap(try anyDyn.get(forField: 1) as? String)
        XCTAssertTrue(typeUrl.contains("Timestamp"), "typeUrl must reference Timestamp: \(typeUrl)")
        let valueBytes = try XCTUnwrap(try anyDyn.get(forField: 2) as? Data)
        XCTAssertFalse(valueBytes.isEmpty, "Any.value bytes must be non-empty")
      },
      buildDynamic: {
        var anyDyn = DynamicMessage(descriptor: anyDesc)
        try anyDyn.set("type.googleapis.com/google.protobuf.Timestamp", forField: 1)
        let tsData = try ts.serializedData()
        try anyDyn.set(tsData, forField: 2)
        var d = DynamicMessage(descriptor: desc)
        try d.set(anyDyn, forField: 4)
        return d
      },
      validateProto: { p in
        XCTAssertTrue(p.anyVal.typeURL.contains("Timestamp"), "typeURL must reference Timestamp")
        let decodedTs = try Google_Protobuf_Timestamp(unpackingAny: p.anyVal)
        XCTAssertEqual(decodedTs.seconds, 1_700_000_000)
        XCTAssertEqual(decodedTs.nanos, 500_000_000)
      }
    )
  }

  // MARK: - 27. WKTHolder with no WKT fields set → empty Data

  func test_wkt_allAbsent_producesNoWireBytes() async throws {
    // Direction A: oracle produces empty bytes for unset WKTHolder
    let proto = Testcompat_WKTHolder()
    let referenceData = try proto.serializedData()
    XCTAssertEqual(referenceData, Data(), "swift-protobuf must produce empty bytes for all-absent WKTHolder")

    // Direction B: our serializer also produces empty bytes
    let desc = CompatDescriptors.wktHolder()
    let dynamic = DynamicMessage(descriptor: desc)
    let ourData = try serializer.serialize(dynamic)
    XCTAssertEqual(ourData, Data(), "BinarySerializer must produce empty bytes for all-absent WKTHolder")
  }

  // MARK: - 28. Timestamp: nanos=0 (proto3 default) MUST be omitted from wire

  func test_wkt_timestamp_zeroNanos_bidirectional() async throws {
    // Direction A: oracle serializes Timestamp(seconds=54321, nanos=0 default) → no nanos field in wire
    var proto = Testcompat_WKTHolder()
    proto.ts.seconds = 54321
    // ts.nanos left at default (0) — oracle will NOT include nanos in wire

    let desc = CompatDescriptors.wktHolder()
    let tsDesc = CompatDescriptors.wktTimestamp()

    try await BinaryCompatHelpers.assertOracleToUs(
      proto: proto,
      descriptor: desc,
      registry: registry
    ) { msg in
      let tsDyn = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try tsDyn.get(forField: 1) as? Int64, 54321)
      // nanos=0 was not in the wire; field should be absent or zero
      XCTAssertEqual((try tsDyn.get(forField: 2) as? Int32) ?? 0, 0)
    }

    // Direction B: build Timestamp with only seconds set (nanos not set = default)
    // The serializer must NOT include nanos=0 in wire bytes
    var tsDyn = DynamicMessage(descriptor: tsDesc)
    try tsDyn.set(Int64(54321), forField: 1)

    // Verify wire bytes of Timestamp directly: must not contain field 2 tag (0x10 = field 2, wire type 0)
    let tsBytes = try serializer.serialize(tsDyn)
    XCTAssertFalse(
      tsBytes.contains(0x10),
      "nanos=0 (proto3 default, unset) must not produce field 2 tag 0x10 in Timestamp wire bytes"
    )

    // Verify oracle parses our serialized WKTHolder correctly
    var holderDyn = DynamicMessage(descriptor: desc)
    try holderDyn.set(tsDyn, forField: 1)

    try await BinaryCompatHelpers.assertUsToOracle(
      dynamic: holderDyn,
      protoType: Testcompat_WKTHolder.self
    ) { decoded in
      XCTAssertEqual(decoded.ts.seconds, 54321)
      XCTAssertEqual(decoded.ts.nanos, 0)
    }
  }

  // MARK: - 29. Duration: negative (seconds=-1, nanos=-500_000_000) round-trips correctly

  func test_wkt_duration_negative_bidirectional() async throws {
    var proto = Testcompat_WKTHolder()
    proto.dur.seconds = -1
    proto.dur.nanos = -500_000_000

    let desc = CompatDescriptors.wktHolder()
    let durDesc = CompatDescriptors.wktDuration()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let durDyn = try XCTUnwrap(try msg.get(forField: 2) as? DynamicMessage)
        XCTAssertEqual(try durDyn.get(forField: 1) as? Int64, -1)
        XCTAssertEqual(try durDyn.get(forField: 2) as? Int32, -500_000_000)
      },
      buildDynamic: {
        var durDyn = DynamicMessage(descriptor: durDesc)
        try durDyn.set(Int64(-1), forField: 1)
        try durDyn.set(Int32(-500_000_000), forField: 2)
        var d = DynamicMessage(descriptor: desc)
        try d.set(durDyn, forField: 2)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.dur.seconds, -1)
        XCTAssertEqual(p.dur.nanos, -500_000_000)
      }
    )
  }

  // MARK: - 30. Any: encode type_url + value bytes, oracle parses typeURL and raw bytes correctly

  func test_wkt_any_typeUrlAndValue_roundTrip() async throws {
    var inner = Testcompat_SimpleMessage()
    inner.id = 99
    inner.name = "round_trip"
    let innerData = try inner.serializedData()

    let typeURL = "type.googleapis.com/testcompat.SimpleMessage"

    let desc = CompatDescriptors.wktHolder()
    let anyDesc = CompatDescriptors.wktAny()

    // Direction B: build Any DynamicMessage → oracle → verify typeURL and value bytes
    var anyDyn = DynamicMessage(descriptor: anyDesc)
    try anyDyn.set(typeURL, forField: 1)
    try anyDyn.set(innerData, forField: 2)

    var holderDyn = DynamicMessage(descriptor: desc)
    try holderDyn.set(anyDyn, forField: 4)

    try await BinaryCompatHelpers.assertUsToOracle(
      dynamic: holderDyn,
      protoType: Testcompat_WKTHolder.self
    ) { decoded in
      XCTAssertEqual(decoded.anyVal.typeURL, typeURL)
      XCTAssertEqual(decoded.anyVal.value, innerData)
    }

    // Direction A: oracle → our deserializer
    var proto = Testcompat_WKTHolder()
    proto.anyVal.typeURL = typeURL
    proto.anyVal.value = innerData

    try await BinaryCompatHelpers.assertOracleToUs(
      proto: proto,
      descriptor: desc,
      registry: registry
    ) { msg in
      let anyDynDecoded = try XCTUnwrap(try msg.get(forField: 4) as? DynamicMessage)
      XCTAssertEqual(try anyDynDecoded.get(forField: 1) as? String, typeURL)
      XCTAssertEqual(try anyDynDecoded.get(forField: 2) as? Data, innerData)
    }
  }
}
