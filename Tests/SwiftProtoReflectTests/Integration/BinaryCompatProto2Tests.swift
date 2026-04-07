// BinaryCompatProto2Tests.swift
// SwiftProtoReflectTests
//
// Group: Proto2 — required fields, optional+presence, custom defaults, groups, extensions.
// Bidirectional binary compatibility tests.
//
// Oracle strategy: Option A — swift-protobuf generated types (.pb.swift).
//
// Pattern (mirrors BinaryCompatScalarsTests):
//   Direction A (oracle → us):
//     1. Build Testcompat2_<Type> (generated), call serializedData() → referenceData.
//     2. Deserialize referenceData via BinaryDeserializer + CompatDescriptors → DynamicMessage.
//     3. Assert field values on DynamicMessage.
//   Direction B (us → oracle):
//     1. Build DynamicMessage via CompatDescriptors, call BinarySerializer.serialize() → ourData.
//     2. Parse ourData via Testcompat2_<Type>(serializedBytes:) → generated message.
//     3. Assert field values on generated message.
//
// Binary-specific notes for proto2:
//   - Required fields: always serialized even when set to default value (0, "").
//   - Optional fields: explicitly set → serialized even at zero/default; unset → no wire bytes.
//   - Groups: use wire type 3 (SGROUP) / 4 (EGROUP) pairs instead of LEN wire type.
//   - Extensions: fields in extension range encoded as regular fields by field number.
//   - Extension tests use Testcompat2_Proto2Types_Extensions map for oracle parsing.

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class BinaryCompatProto2Tests: XCTestCase {

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

  // MARK: - Group 1: Required field presence — Proto2Basic (4 tests)

  func test_proto2_required_allPresent_bidirectional() async throws {
    let desc = CompatDescriptors.proto2Basic()

    var proto = Testcompat2_Proto2Basic()
    proto.requiredString = "test"
    proto.requiredInt32 = 100

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? String, "test")
        XCTAssertEqual(try msg.get(forField: 2) as? Int32, 100)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set("test", forField: 1)
        try d.set(Int32(100), forField: 2)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.requiredString, "test")
        XCTAssertEqual(p.requiredInt32, 100)
      }
    )
  }

  func test_proto2_required_defaultInt_alwaysSerialized() async throws {
    let desc = CompatDescriptors.proto2Basic()

    // Direction B: required_int32=0 MUST be serialized (unlike proto3 which omits 0)
    // Tag for field 2, wire type 0 (varint): (2 << 3) | 0 = 0x10
    var d = DynamicMessage(descriptor: desc)
    try d.set("r", forField: 1)
    try d.set(Int32(0), forField: 2)

    let data = try serializer.serialize(d)
    let bytes = [UInt8](data)

    XCTAssertTrue(bytes.contains(0x10), "required_int32=0 must produce tag 0x10 in wire output")

    let decoded = try Testcompat2_Proto2Basic(serializedBytes: data)
    XCTAssertTrue(decoded.hasRequiredInt32, "required_int32 must have presence after parsing")
    XCTAssertEqual(decoded.requiredInt32, 0)
  }

  func test_proto2_required_emptyString_alwaysSerialized() async throws {
    let desc = CompatDescriptors.proto2Basic()

    // Direction B: required_string="" is always serialized (tag + length 0 in wire)
    // Tag for field 1, wire type 2 (LEN): (1 << 3) | 2 = 0x0A
    var d = DynamicMessage(descriptor: desc)
    try d.set("", forField: 1)
    try d.set(Int32(1), forField: 2)

    let data = try serializer.serialize(d)
    let bytes = [UInt8](data)

    XCTAssertTrue(bytes.contains(0x0A), "required_string=\"\" must produce tag 0x0A in wire output")

    let decoded = try Testcompat2_Proto2Basic(serializedBytes: data)
    XCTAssertTrue(decoded.hasRequiredString, "required_string must have presence after parsing")
    XCTAssertEqual(decoded.requiredString, "")
  }

  func test_proto2_required_exactWireTag() async throws {
    let desc = CompatDescriptors.proto2Basic()

    // Direction B: Proto2Basic.required_int32 (field 2, wire type 0) → exact tag byte = 0x10
    // Verifies: tag = (field_number << 3) | wire_type = (2 << 3) | 0 = 16 = 0x10
    var d = DynamicMessage(descriptor: desc)
    try d.set("x", forField: 1)
    try d.set(Int32(1), forField: 2)

    let data = try serializer.serialize(d)
    let bytes = [UInt8](data)

    XCTAssertTrue(
      bytes.contains(0x10),
      "Proto2Basic.required_int32 (field 2, varint) must produce exact tag byte 0x10"
    )
  }

  // MARK: - Group 2: Optional field presence — Proto2Basic (5 tests)

  func test_proto2_optional_set_bidirectional() async throws {
    let desc = CompatDescriptors.proto2Basic()

    var proto = Testcompat2_Proto2Basic()
    proto.requiredString = "req"
    proto.requiredInt32 = 0
    proto.optString = "opt_val"
    proto.optInt32 = -5
    proto.optBool = false
    proto.optDouble = 1.5

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 3) as? String, "opt_val")
        XCTAssertEqual(try msg.get(forField: 4) as? Int32, -5)
        XCTAssertEqual(try msg.get(forField: 5) as? Bool, false)
        XCTAssertEqual(try msg.get(forField: 7) as? Double, 1.5)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set("req", forField: 1)
        try d.set(Int32(0), forField: 2)
        try d.set("opt_val", forField: 3)
        try d.set(Int32(-5), forField: 4)
        try d.set(false, forField: 5)
        try d.set(Double(1.5), forField: 7)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.optString, "opt_val")
        XCTAssertEqual(p.optInt32, -5)
        XCTAssertEqual(p.optBool, false)
        XCTAssertEqual(p.optDouble, 1.5)
      }
    )
  }

  func test_proto2_optional_setToZero_serialized() async throws {
    let desc = CompatDescriptors.proto2Basic()

    // Direction B: opt_int32=0 explicitly set IS serialized (proto2 presence semantics)
    // Tag for field 4, wire type 0 (varint): (4 << 3) | 0 = 32 = 0x20
    var d = DynamicMessage(descriptor: desc)
    try d.set("r", forField: 1)
    try d.set(Int32(1), forField: 2)
    try d.set(Int32(0), forField: 4)

    let data = try serializer.serialize(d)
    let bytes = [UInt8](data)

    XCTAssertTrue(bytes.contains(0x20), "Explicitly set opt_int32=0 must produce tag 0x20 in wire output")

    let decoded = try Testcompat2_Proto2Basic(serializedBytes: data)
    XCTAssertTrue(decoded.hasOptInt32, "opt_int32 explicitly set to 0 must have presence after parsing")
    XCTAssertEqual(decoded.optInt32, 0)
  }

  func test_proto2_optional_unset_producesNoBytes() async throws {
    let desc = CompatDescriptors.proto2Basic()

    // Direction A: oracle with only required fields → unset optionals absent from DynamicMessage
    var proto = Testcompat2_Proto2Basic()
    proto.requiredString = "r"
    proto.requiredInt32 = 1

    try await BinaryCompatHelpers.assertOracleToUs(
      proto: proto,
      descriptor: desc,
      registry: registry
    ) { msg in
      XCTAssertFalse(
        try msg.hasValue(forField: 4),
        "Unset opt_int32 must not be present after deserialization"
      )
      XCTAssertFalse(
        try msg.hasValue(forField: 3),
        "Unset opt_string must not be present after deserialization"
      )
    }

    // Direction B: DynamicMessage with only required fields → no tag for field 3/4 in wire
    var d = DynamicMessage(descriptor: desc)
    try d.set("r", forField: 1)
    try d.set(Int32(1), forField: 2)

    let data = try serializer.serialize(d)
    let bytes = [UInt8](data)

    // Tag for field 3 LEN: (3 << 3) | 2 = 0x1A; tag for field 4 varint: (4 << 3) | 0 = 0x20
    XCTAssertFalse(bytes.contains(0x1A), "Unset opt_string must produce no tag 0x1A in wire")
    XCTAssertFalse(bytes.contains(0x20), "Unset opt_int32 must produce no tag 0x20 in wire")
  }

  func test_proto2_optional_string_unsetVsEmpty() async throws {
    let desc = CompatDescriptors.proto2Basic()

    // Unset opt_string → no tag in wire
    var unsetD = DynamicMessage(descriptor: desc)
    try unsetD.set("r", forField: 1)
    try unsetD.set(Int32(1), forField: 2)

    let unsetBytes = [UInt8](try serializer.serialize(unsetD))
    // Tag for field 3, wire type 2 (LEN): (3 << 3) | 2 = 0x1A
    XCTAssertFalse(unsetBytes.contains(0x1A), "Unset opt_string produces no tag 0x1A")

    // Explicitly set to "" → tag 0x1A + length 0x00 present
    var emptyD = DynamicMessage(descriptor: desc)
    try emptyD.set("r", forField: 1)
    try emptyD.set(Int32(1), forField: 2)
    try emptyD.set("", forField: 3)

    let emptyData = try serializer.serialize(emptyD)
    let emptyBytes = [UInt8](emptyData)
    XCTAssertTrue(emptyBytes.contains(0x1A), "opt_string=\"\" must produce tag 0x1A")

    let decoded = try Testcompat2_Proto2Basic(serializedBytes: emptyData)
    XCTAssertTrue(decoded.hasOptString, "opt_string explicitly set to \"\" must have presence")
    XCTAssertEqual(decoded.optString, "")
  }

  func test_proto2_required_vs_optional_differentWire() async throws {
    let desc = CompatDescriptors.proto2Basic()

    // required_int32(field 2)=0 → tag 0x10 always present
    // unset opt_int32(field 4) → no tag 0x20 present
    // Same int32 value 0, but different wire behavior
    var d = DynamicMessage(descriptor: desc)
    try d.set("r", forField: 1)
    try d.set(Int32(0), forField: 2)
    // field 4 (opt_int32) intentionally NOT set

    let data = try serializer.serialize(d)
    let bytes = [UInt8](data)

    XCTAssertTrue(bytes.contains(0x10), "required_int32=0 must produce tag 0x10 (field 2 varint)")
    XCTAssertFalse(bytes.contains(0x20), "Unset opt_int32 must NOT produce tag 0x20 (field 4 varint)")
  }

  // MARK: - Group 3: Custom default values — Proto2Defaults (5 tests)

  func test_proto2_defaults_nonDefault_bidirectional() async throws {
    let desc = CompatDescriptors.proto2Defaults()

    var proto = Testcompat2_Proto2Defaults()
    proto.count = 100  // overrides default 42
    proto.label = "custom"  // overrides default "hello"

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? Int32, 100)
        XCTAssertEqual(try msg.get(forField: 2) as? String, "custom")
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(100), forField: 1)
        try d.set("custom", forField: 2)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.count, 100)
        XCTAssertEqual(p.label, "custom")
      }
    )
  }

  func test_proto2_defaults_setToExactDefault_serialized() async throws {
    let desc = CompatDescriptors.proto2Defaults()

    // Direction B: setting count to exactly 42 (the default) IS still serialized in proto2
    // because the field has been explicitly set (has_* semantics)
    // Tag for field 1, wire type 0 (varint): (1 << 3) | 0 = 8 = 0x08
    var d = DynamicMessage(descriptor: desc)
    try d.set(Int32(42), forField: 1)

    let data = try serializer.serialize(d)
    let bytes = [UInt8](data)

    XCTAssertTrue(
      bytes.contains(0x08),
      "count=42 (exact default) must produce tag 0x08 because it was explicitly set"
    )

    let decoded = try Testcompat2_Proto2Defaults(serializedBytes: data)
    XCTAssertTrue(decoded.hasCount, "count set to default value must have presence after parsing")
    XCTAssertEqual(decoded.count, 42)
  }

  func test_proto2_defaults_enum_override_bidirectional() async throws {
    let desc = CompatDescriptors.proto2Defaults()

    // Proto2Defaults: kind(7) = P2_ALPHA (raw 1), overriding default P2_BETA (raw 2)
    var proto = Testcompat2_Proto2Defaults()
    proto.kind = .p2Alpha

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 7) as? Int32, 1)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(1), forField: 7)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.kind, .p2Alpha)
        XCTAssertTrue(p.hasKind)
      }
    )
  }

  func test_proto2_defaults_bool_override_bidirectional() async throws {
    let desc = CompatDescriptors.proto2Defaults()

    // Proto2Defaults: active(3) = false, overriding default true; varint 0 in wire
    var protoFalse = Testcompat2_Proto2Defaults()
    protoFalse.active = false

    try await BinaryCompatHelpers.assertBidirectional(
      proto: protoFalse,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 3) as? Bool, false)
        XCTAssertTrue(try msg.hasValue(forField: 3))
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(false, forField: 3)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.active, false)
        XCTAssertTrue(p.hasActive)
      }
    )

    // Unset → no bytes for field 3; tag for field 3, wire type 0: (3 << 3) | 0 = 24 = 0x18
    let emptyD = DynamicMessage(descriptor: desc)
    let emptyBytes = [UInt8](try serializer.serialize(emptyD))
    XCTAssertFalse(emptyBytes.contains(0x18), "Unset active must produce no tag 0x18")
  }

  func test_proto2_defaults_bytes_bidirectional() async throws {
    let desc = CompatDescriptors.proto2Defaults()

    var proto = Testcompat2_Proto2Defaults()
    proto.magic = Data([0xDE, 0xAD, 0xBE, 0xEF])

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 6) as? Data, Data([0xDE, 0xAD, 0xBE, 0xEF]))
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Data([0xDE, 0xAD, 0xBE, 0xEF]), forField: 6)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.magic, Data([0xDE, 0xAD, 0xBE, 0xEF]))
      }
    )
  }

  // MARK: - Group 4: Groups — wire type 3/4 (3 tests)

  func test_proto2_group_basic_bidirectional() async throws {
    let desc = CompatDescriptors.proto2WithGroup()
    let grpDesc = try XCTUnwrap(desc.nestedMessages["MyGroup"])

    var proto = Testcompat2_Proto2WithGroup()
    proto.id = 1
    proto.myGroup.name = "grp"
    proto.myGroup.value = 42

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? Int32, 1)
        let grp = try XCTUnwrap(try msg.get(forField: 2) as? DynamicMessage)
        XCTAssertEqual(try grp.get(forField: 1) as? String, "grp")
        XCTAssertEqual(try grp.get(forField: 2) as? Int32, 42)
      },
      buildDynamic: {
        var grpDyn = DynamicMessage(descriptor: grpDesc)
        try grpDyn.set("grp", forField: 1)
        try grpDyn.set(Int32(42), forField: 2)
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(1), forField: 1)
        try d.set(grpDyn, forField: 2)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.id, 1)
        XCTAssertEqual(p.myGroup.name, "grp")
        XCTAssertEqual(p.myGroup.value, 42)
      }
    )
  }

  func test_proto2_group_multipleGroups_bidirectional() async throws {
    let desc = CompatDescriptors.proto2WithGroup()
    let myGrpDesc = try XCTUnwrap(desc.nestedMessages["MyGroup"])
    let anotherGrpDesc = try XCTUnwrap(desc.nestedMessages["AnotherGroup"])

    var proto = Testcompat2_Proto2WithGroup()
    proto.id = 3
    proto.myGroup.name = "g1"
    proto.myGroup.value = 10
    proto.anotherGroup.flag = true
    proto.anotherGroup.detail = "detail_val"

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? Int32, 3)
        let g1 = try XCTUnwrap(try msg.get(forField: 2) as? DynamicMessage)
        XCTAssertEqual(try g1.get(forField: 1) as? String, "g1")
        XCTAssertEqual(try g1.get(forField: 2) as? Int32, 10)
        let g2 = try XCTUnwrap(try msg.get(forField: 3) as? DynamicMessage)
        XCTAssertEqual(try g2.get(forField: 1) as? Bool, true)
        XCTAssertEqual(try g2.get(forField: 2) as? String, "detail_val")
      },
      buildDynamic: {
        var myGrp = DynamicMessage(descriptor: myGrpDesc)
        try myGrp.set("g1", forField: 1)
        try myGrp.set(Int32(10), forField: 2)
        var anotherGrp = DynamicMessage(descriptor: anotherGrpDesc)
        try anotherGrp.set(true, forField: 1)
        try anotherGrp.set("detail_val", forField: 2)
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(3), forField: 1)
        try d.set(myGrp, forField: 2)
        try d.set(anotherGrp, forField: 3)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.id, 3)
        XCTAssertEqual(p.myGroup.name, "g1")
        XCTAssertEqual(p.myGroup.value, 10)
        XCTAssertTrue(p.anotherGroup.flag)
        XCTAssertEqual(p.anotherGroup.detail, "detail_val")
      }
    )
  }

  // TODO: BLOCKED — Library bug: BinarySerializer.encodeRepeatedField does not write EGROUP wire-type
  // tag (wire type 4) after encoding repeated group field bodies. encodeRepeatedField writes the
  // SGROUP tag (wire type 3) and the group body via encodeValue, but the matching EGROUP tag is
  // only written in encodeSingleField. Swift-protobuf's BinaryDecoder returns "truncated" because
  // the EGROUP tag is never found. Fix: encodeRepeatedField must write the end-group tag after
  // each group element, mirroring the logic in encodeSingleField.
  func test_proto2_group_repeatedWithEnum_bidirectional() async throws {
    let desc = CompatDescriptors.proto2Complex()
    let itemDesc = try XCTUnwrap(desc.nestedMessages["Item"])

    var i1 = Testcompat2_Proto2Complex.Item()
    i1.id = 10
    i1.label = "first"
    i1.kind = .p2Alpha

    var i2 = Testcompat2_Proto2Complex.Item()
    i2.id = 20
    i2.label = "second"
    i2.kind = .p2Gamma

    var proto = Testcompat2_Proto2Complex()
    proto.title = "grp_test"
    proto.item = [i1, i2]

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? String, "grp_test")
        let items = try XCTUnwrap(try msg.get(forField: 4) as? [DynamicMessage])
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(try items[0].get(forField: 1) as? Int32, 10)
        XCTAssertEqual(try items[0].get(forField: 3) as? Int32, 1)  // p2Alpha raw = 1
        XCTAssertEqual(try items[1].get(forField: 1) as? Int32, 20)
        XCTAssertEqual(try items[1].get(forField: 3) as? Int32, 3)  // p2Gamma raw = 3
      },
      buildDynamic: {
        var d1 = DynamicMessage(descriptor: itemDesc)
        try d1.set(Int32(10), forField: 1)
        try d1.set("first", forField: 2)
        try d1.set(Int32(1), forField: 3)
        var d2 = DynamicMessage(descriptor: itemDesc)
        try d2.set(Int32(20), forField: 1)
        try d2.set("second", forField: 2)
        try d2.set(Int32(3), forField: 3)
        var d = DynamicMessage(descriptor: desc)
        try d.set("grp_test", forField: 1)
        try d.set([d1, d2] as [DynamicMessage], forField: 4)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.title, "grp_test")
        XCTAssertEqual(p.item.count, 2)
        XCTAssertEqual(p.item[0].kind, .p2Alpha)
        XCTAssertEqual(p.item[1].kind, .p2Gamma)
      }
    )
  }

  // MARK: - Group 5: Extensions (3 tests)

  func test_proto2_extension_scalar_bidirectional() async throws {
    let desc = CompatDescriptors.proto2Extendable()

    // Direction A: oracle with extensions → our DynamicMessage
    var proto = Testcompat2_Proto2Extendable()
    proto.baseField = "base"
    proto.code = 5
    proto.Testcompat2_extName = "ext_str"
    proto.Testcompat2_extCount = 99
    proto.Testcompat2_extFlag = true

    try await BinaryCompatHelpers.assertOracleToUs(
      proto: proto,
      descriptor: desc,
      registry: registry
    ) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? String, "base")
      XCTAssertEqual(try msg.get(forField: 2) as? Int32, 5)
      XCTAssertEqual(try msg.get(forField: 100) as? String, "ext_str")
      XCTAssertEqual(try msg.get(forField: 101) as? Int32, 99)
      XCTAssertEqual(try msg.get(forField: 102) as? Bool, true)
    }

    // Direction B: our DynamicMessage → oracle with extension map for proper extension parsing
    var d = DynamicMessage(descriptor: desc)
    try d.set("base", forField: 1)
    try d.set(Int32(5), forField: 2)
    try d.set("ext_str", forField: 100)
    try d.set(Int32(99), forField: 101)
    try d.set(true, forField: 102)

    let ourData = try serializer.serialize(d)
    let decoded = try Testcompat2_Proto2Extendable(
      serializedBytes: ourData,
      extensions: Testcompat2_Proto2Types_Extensions
    )
    XCTAssertEqual(decoded.baseField, "base")
    XCTAssertEqual(decoded.code, 5)
    XCTAssertEqual(decoded.Testcompat2_extName, "ext_str")
    XCTAssertEqual(decoded.Testcompat2_extCount, 99)
    XCTAssertTrue(decoded.Testcompat2_extFlag)
  }

  func test_proto2_extension_message_bidirectional() async throws {
    let desc = CompatDescriptors.proto2Extendable()
    let innerDesc = CompatDescriptors.proto2Basic()

    // Direction A: oracle with ext_msg → our DynamicMessage
    var inner = Testcompat2_Proto2Basic()
    inner.requiredString = "inner"
    inner.requiredInt32 = 7

    var proto = Testcompat2_Proto2Extendable()
    proto.baseField = "base2"
    proto.Testcompat2_extMsg = inner

    try await BinaryCompatHelpers.assertOracleToUs(
      proto: proto,
      descriptor: desc,
      registry: registry
    ) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? String, "base2")
      let extMsg = try XCTUnwrap(try msg.get(forField: 104) as? DynamicMessage)
      XCTAssertEqual(try extMsg.get(forField: 1) as? String, "inner")
      XCTAssertEqual(try extMsg.get(forField: 2) as? Int32, 7)
    }

    // Direction B: our DynamicMessage → oracle with extension map
    var innerDyn = DynamicMessage(descriptor: innerDesc)
    try innerDyn.set("inner", forField: 1)
    try innerDyn.set(Int32(7), forField: 2)

    var d = DynamicMessage(descriptor: desc)
    try d.set("base2", forField: 1)
    try d.set(innerDyn, forField: 104)

    let ourData = try serializer.serialize(d)
    let decoded = try Testcompat2_Proto2Extendable(
      serializedBytes: ourData,
      extensions: Testcompat2_Proto2Types_Extensions
    )
    XCTAssertEqual(decoded.baseField, "base2")
    XCTAssertTrue(decoded.hasTestcompat2_extMsg)
    XCTAssertEqual(decoded.Testcompat2_extMsg.requiredString, "inner")
    XCTAssertEqual(decoded.Testcompat2_extMsg.requiredInt32, 7)
  }

  // TODO: BLOCKED — Library bug: BinaryDeserializer.decodeRepeatedField accumulates values by
  // looking up existing data via fieldAccess.hasValue(field.name). For extension fields,
  // field.name ("ext_tags", "ext_ids") is NOT in MessageDescriptor.fieldsByName (only in
  // the extensions dict keyed by number), so fieldAccess.hasValue returns false on every
  // invocation and the array is reset to empty each time. Result: only the last value is
  // kept. Fix: decodeRepeatedField should use field.number (not field.name) when retrieving
  // accumulated values, or call fieldAccess.hasValue(field.number) instead.
  func test_proto2_extension_repeated_bidirectional() async throws {
    let desc = CompatDescriptors.proto2Extendable()

    // Direction A: oracle with repeated extensions → our DynamicMessage
    var proto = Testcompat2_Proto2Extendable()
    proto.baseField = "tags_test"
    proto.Testcompat2_extTags = ["tag1", "tag2", "tag3"]
    proto.Testcompat2_extIds = [1, 2, 3]

    try await BinaryCompatHelpers.assertOracleToUs(
      proto: proto,
      descriptor: desc,
      registry: registry
    ) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? String, "tags_test")
      XCTAssertEqual(try msg.get(forField: 105) as? [String], ["tag1", "tag2", "tag3"])
      XCTAssertEqual(try msg.get(forField: 106) as? [Int32], [1, 2, 3])
    }

    // Direction B: our DynamicMessage → oracle with extension map
    var d = DynamicMessage(descriptor: desc)
    try d.set("tags_test", forField: 1)
    try d.set(["tag1", "tag2", "tag3"] as [String], forField: 105)
    try d.set([Int32(1), Int32(2), Int32(3)] as [Int32], forField: 106)

    let ourData = try serializer.serialize(d)
    let decoded = try Testcompat2_Proto2Extendable(
      serializedBytes: ourData,
      extensions: Testcompat2_Proto2Types_Extensions
    )
    XCTAssertEqual(decoded.baseField, "tags_test")
    XCTAssertEqual(decoded.Testcompat2_extTags, ["tag1", "tag2", "tag3"])
    XCTAssertEqual(decoded.Testcompat2_extIds, [1, 2, 3])
  }

  // MARK: - Group 6: Oneof in proto2 (2 tests)

  func test_proto2_oneof_strVariant_bidirectional() async throws {
    let desc = CompatDescriptors.proto2Oneof()

    var proto = Testcompat2_Proto2Oneof()
    proto.strVal = "hello"
    proto.label = "outer"

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? String, "hello")
        XCTAssertEqual(try msg.get(forField: 10) as? String, "outer")
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set("hello", forField: 1)
        try d.set("outer", forField: 10)
        return d
      },
      validateProto: { p in
        if case .strVal(let v) = p.choice {
          XCTAssertEqual(v, "hello")
        }
        else {
          XCTFail("Expected strVal oneof case")
        }
        XCTAssertEqual(p.label, "outer")
      }
    )
  }

  func test_proto2_oneof_msgVariant_bidirectional() async throws {
    let desc = CompatDescriptors.proto2Oneof()
    let innerDesc = CompatDescriptors.proto2Basic()

    var inner = Testcompat2_Proto2Basic()
    inner.requiredString = "inner"
    inner.requiredInt32 = 77

    var proto = Testcompat2_Proto2Oneof()
    proto.msgVal = inner
    proto.label = "outer"

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let innerDyn = try XCTUnwrap(try msg.get(forField: 4) as? DynamicMessage)
        XCTAssertEqual(try innerDyn.get(forField: 1) as? String, "inner")
        XCTAssertEqual(try innerDyn.get(forField: 2) as? Int32, 77)
        XCTAssertEqual(try msg.get(forField: 10) as? String, "outer")
      },
      buildDynamic: {
        var innerDyn = DynamicMessage(descriptor: innerDesc)
        try innerDyn.set("inner", forField: 1)
        try innerDyn.set(Int32(77), forField: 2)
        var d = DynamicMessage(descriptor: desc)
        try d.set(innerDyn, forField: 4)
        try d.set("outer", forField: 10)
        return d
      },
      validateProto: { p in
        if case .msgVal(let m) = p.choice {
          XCTAssertEqual(m.requiredString, "inner")
          XCTAssertEqual(m.requiredInt32, 77)
        }
        else {
          XCTFail("Expected msgVal oneof case")
        }
        XCTAssertEqual(p.label, "outer")
      }
    )
  }

  // MARK: - Group 7: Complex / Kitchen Sink (2 tests)

  // TODO: BLOCKED — Library bug: same as test_proto2_group_repeatedWithEnum_bidirectional.
  // Proto2Complex.item (field 4) is a repeated group. BinarySerializer.encodeRepeatedField
  // omits the EGROUP tag for each repeated group element. When the serialized bytes reach
  // Swift-protobuf's BinaryDecoder, it finds an unterminated group and throws "truncated".
  // The Header group (field 3, single) serializes correctly; only the repeated Item group
  // (field 4) causes the failure. Fix: same fix as test_proto2_group_repeatedWithEnum.
  func test_proto2_complex_fullyPopulated_bidirectional() async throws {
    let desc = CompatDescriptors.proto2Complex()
    let headerDesc = try XCTUnwrap(desc.nestedMessages["Header"])
    let itemDesc = try XCTUnwrap(desc.nestedMessages["Item"])
    let basicDesc = CompatDescriptors.proto2Basic()

    var header = Testcompat2_Proto2Complex.Header()
    header.key = "Content-Type"
    header.value = "application/json"

    var item1 = Testcompat2_Proto2Complex.Item()
    item1.id = 1
    item1.label = "item_one"
    item1.kind = .p2Beta

    var basic = Testcompat2_Proto2Basic()
    basic.requiredString = "b"
    basic.requiredInt32 = 1

    var proto = Testcompat2_Proto2Complex()
    proto.title = "full"
    proto.version = 3
    proto.header = header
    proto.item = [item1]
    proto.basic = basic
    proto.items = [basic]
    proto.meta = ["k": "v"]

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? String, "full")
        XCTAssertEqual(try msg.get(forField: 2) as? Int32, 3)
        let hdr = try XCTUnwrap(try msg.get(forField: 3) as? DynamicMessage)
        XCTAssertEqual(try hdr.get(forField: 1) as? String, "Content-Type")
        XCTAssertEqual(try hdr.get(forField: 2) as? String, "application/json")
        let grpItems = try XCTUnwrap(try msg.get(forField: 4) as? [DynamicMessage])
        XCTAssertEqual(grpItems.count, 1)
        XCTAssertEqual(try grpItems[0].get(forField: 1) as? Int32, 1)
        XCTAssertEqual(try grpItems[0].get(forField: 3) as? Int32, 2)  // p2Beta raw = 2
        let basic5 = try XCTUnwrap(try msg.get(forField: 5) as? DynamicMessage)
        XCTAssertEqual(try basic5.get(forField: 1) as? String, "b")
        let msgItems = try XCTUnwrap(try msg.get(forField: 6) as? [DynamicMessage])
        XCTAssertEqual(msgItems.count, 1)
      },
      buildDynamic: {
        var headerDyn = DynamicMessage(descriptor: headerDesc)
        try headerDyn.set("Content-Type", forField: 1)
        try headerDyn.set("application/json", forField: 2)

        var itemDyn = DynamicMessage(descriptor: itemDesc)
        try itemDyn.set(Int32(1), forField: 1)
        try itemDyn.set("item_one", forField: 2)
        try itemDyn.set(Int32(2), forField: 3)  // p2Beta raw = 2

        var basicDyn = DynamicMessage(descriptor: basicDesc)
        try basicDyn.set("b", forField: 1)
        try basicDyn.set(Int32(1), forField: 2)

        var d = DynamicMessage(descriptor: desc)
        try d.set("full", forField: 1)
        try d.set(Int32(3), forField: 2)
        try d.set(headerDyn, forField: 3)
        try d.set([itemDyn] as [DynamicMessage], forField: 4)
        try d.set(basicDyn, forField: 5)
        try d.set([basicDyn] as [DynamicMessage], forField: 6)
        try d.setMapEntry("v", forKey: "k", inField: 7)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.title, "full")
        XCTAssertEqual(p.version, 3)
        XCTAssertEqual(p.header.key, "Content-Type")
        XCTAssertEqual(p.item.count, 1)
        XCTAssertEqual(p.item[0].kind, .p2Beta)
        XCTAssertEqual(p.basic.requiredString, "b")
        XCTAssertEqual(p.items.count, 1)
        XCTAssertEqual(p.meta["k"], "v")
      }
    )
  }

  func test_proto2_kitchenSink_bidirectional() async throws {
    let desc = CompatDescriptors.proto2KitchenSink()
    let basicDesc = CompatDescriptors.proto2Basic()
    let detailDesc = try XCTUnwrap(desc.nestedMessages["Detail"])

    var nestedBasic = Testcompat2_Proto2Basic()
    nestedBasic.requiredString = "nested_str"
    nestedBasic.requiredInt32 = 10

    var itemBasic = Testcompat2_Proto2Basic()
    itemBasic.requiredString = "item_str"
    itemBasic.requiredInt32 = 20

    var detail = Testcompat2_Proto2KitchenSink.Detail()
    detail.info = "info_val"
    detail.code = 99

    var proto = Testcompat2_Proto2KitchenSink()
    proto.name = "kitchen"
    proto.id = 42
    proto.status = .p2Alpha
    proto.tags = ["tag1", "tag2"]
    proto.scores = ["a": 1, "b": 2]
    proto.detail = detail
    proto.strVariant = "str_v"
    proto.nested = nestedBasic
    proto.items = [itemBasic]

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? String, "kitchen")
        XCTAssertEqual(try msg.get(forField: 2) as? Int32, 42)
        XCTAssertEqual(try msg.get(forField: 3) as? Int32, 1)  // p2Alpha raw = 1
        XCTAssertEqual(try msg.get(forField: 4) as? [String], ["tag1", "tag2"])
        let detailDyn = try XCTUnwrap(try msg.get(forField: 6) as? DynamicMessage)
        XCTAssertEqual(try detailDyn.get(forField: 1) as? String, "info_val")
        XCTAssertEqual(try detailDyn.get(forField: 2) as? Int32, 99)
        XCTAssertEqual(try msg.get(forField: 7) as? String, "str_v")
        let nestedDyn = try XCTUnwrap(try msg.get(forField: 9) as? DynamicMessage)
        XCTAssertEqual(try nestedDyn.get(forField: 1) as? String, "nested_str")
        let itemsDyn = try XCTUnwrap(try msg.get(forField: 10) as? [DynamicMessage])
        XCTAssertEqual(itemsDyn.count, 1)
      },
      buildDynamic: {
        var nestedDyn = DynamicMessage(descriptor: basicDesc)
        try nestedDyn.set("nested_str", forField: 1)
        try nestedDyn.set(Int32(10), forField: 2)

        var itemDyn = DynamicMessage(descriptor: basicDesc)
        try itemDyn.set("item_str", forField: 1)
        try itemDyn.set(Int32(20), forField: 2)

        var detailDyn = DynamicMessage(descriptor: detailDesc)
        try detailDyn.set("info_val", forField: 1)
        try detailDyn.set(Int32(99), forField: 2)

        var d = DynamicMessage(descriptor: desc)
        try d.set("kitchen", forField: 1)
        try d.set(Int32(42), forField: 2)
        try d.set(Int32(1), forField: 3)
        try d.set(["tag1", "tag2"] as [String], forField: 4)
        try d.setMapEntry(Int32(1), forKey: "a", inField: 5)
        try d.setMapEntry(Int32(2), forKey: "b", inField: 5)
        try d.set(detailDyn, forField: 6)
        try d.set("str_v", forField: 7)
        try d.set(nestedDyn, forField: 9)
        try d.set([itemDyn] as [DynamicMessage], forField: 10)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.name, "kitchen")
        XCTAssertEqual(p.id, 42)
        XCTAssertEqual(p.status, .p2Alpha)
        XCTAssertEqual(p.tags, ["tag1", "tag2"])
        XCTAssertEqual(p.scores["a"], 1)
        XCTAssertEqual(p.scores["b"], 2)
        XCTAssertEqual(p.detail.info, "info_val")
        XCTAssertEqual(p.detail.code, 99)
        if case .strVariant(let v) = p.variant {
          XCTAssertEqual(v, "str_v")
        }
        else {
          XCTFail("Expected strVariant oneof case")
        }
        XCTAssertEqual(p.nested.requiredString, "nested_str")
        XCTAssertEqual(p.items.count, 1)
      }
    )
  }
}
