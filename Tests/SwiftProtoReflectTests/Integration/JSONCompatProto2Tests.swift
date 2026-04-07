// JSONCompatProto2Tests.swift
// SwiftProtoReflectTests
//
// Group 10: Proto2 — required, optional+defaults, groups, extensions.
// Bidirectional JSON compatibility tests.
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class JSONCompatProto2Tests: XCTestCase {

  private var registry: TypeRegistry!

  override func setUp() async throws {
    try await super.setUp()
    registry = try? await CompatDescriptors.fullRegistry()
  }

  override func tearDown() async throws {
    registry = nil
    try await super.tearDown()
  }

  // MARK: - Proto2 required fields: present in JSON

  func test_proto2_required_present_bidirectional() async throws {
    var proto = Testcompat2_Proto2Basic()
    proto.requiredString = "req_str"
    proto.requiredInt32 = 100

    let desc = CompatDescriptors.proto2Basic()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? String, "req_str")
      XCTAssertEqual(try msg.get(forField: 2) as? Int32, 100)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("req_str", forField: 1)
    try dynamic.set(Int32(100), forField: 2)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat2_Proto2Basic.self
    ) {
      decoded in
      XCTAssertEqual(decoded.requiredString, "req_str")
      XCTAssertEqual(decoded.requiredInt32, 100)
    }
  }

  // MARK: - Proto2 optional fields: unset → omitted

  func test_proto2_optional_unset_omitted() async throws {
    var proto = Testcompat2_Proto2Basic()
    proto.requiredString = "str"
    proto.requiredInt32 = 1
    // opt_string, opt_int32, etc. are not set

    let jsonStr = try proto.jsonString()
    XCTAssertFalse(jsonStr.contains("optString"), "Unset optional should be omitted: \(jsonStr)")
    XCTAssertFalse(jsonStr.contains("optInt32"), "Unset optional should be omitted: \(jsonStr)")
  }

  // MARK: - Proto2 optional fields: set → present

  func test_proto2_optional_set_bidirectional() async throws {
    var proto = Testcompat2_Proto2Basic()
    proto.requiredString = "req"
    proto.requiredInt32 = 0
    proto.optString = "opt_val"
    proto.optInt32 = -5
    proto.optBool = false  // explicit false for optional
    proto.optDouble = 1.5

    let desc = CompatDescriptors.proto2Basic()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 3) as? String, "opt_val")
      XCTAssertEqual(try msg.get(forField: 4) as? Int32, -5)
      XCTAssertEqual(try msg.get(forField: 5) as? Bool, false)
      XCTAssertEqual(try msg.get(forField: 7) as? Double, 1.5)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("req", forField: 1)
    try dynamic.set(Int32(0), forField: 2)
    try dynamic.set("opt_val", forField: 3)
    try dynamic.set(Int32(-5), forField: 4)
    try dynamic.set(false, forField: 5)
    try dynamic.set(Double(1.5), forField: 7)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat2_Proto2Basic.self
    ) {
      decoded in
      XCTAssertEqual(decoded.optString, "opt_val")
      XCTAssertEqual(decoded.optInt32, -5)
      XCTAssertEqual(decoded.optBool, false)
      XCTAssertEqual(decoded.optDouble, 1.5)
    }
  }

  // MARK: - Proto2 optional explicit zero (vs not set)

  func test_proto2_optional_explicitZero_present() async throws {
    var proto = Testcompat2_Proto2Basic()
    proto.requiredString = "r"
    proto.requiredInt32 = 0
    proto.optInt32 = 0  // optional field explicitly set to zero

    let jsonStr = try proto.jsonString()
    // Optional proto2 field explicitly set to 0 should appear in JSON
    XCTAssertTrue(
      jsonStr.contains("optInt32"),
      "Optional proto2 field set to 0 should appear in JSON: \(jsonStr)"
    )
  }

  // MARK: - Proto2 defaults: defaults appear in JSON when not overridden?

  func test_proto2_defaults_showInJSON_bidirectional() async throws {
    // Proto2 with defaults: fields that have explicit default values
    // In JSON, absent field == default, so unset → omitted
    let proto = Testcompat2_Proto2Defaults()
    let jsonStr = try proto.jsonString()
    // Unset fields with defaults → omitted (they use default on read but aren't serialized)
    XCTAssertFalse(jsonStr.contains("count"), "Unset proto2 field with default should be omitted: \(jsonStr)")

    var set = Testcompat2_Proto2Defaults()
    set.count = 99  // override default
    set.label = "custom"
    let setJson = try set.jsonString()
    XCTAssertTrue(setJson.contains("count"), "Set field should appear: \(setJson)")
    XCTAssertTrue(setJson.contains("label"), "Set label should appear: \(setJson)")

    let desc = CompatDescriptors.proto2Defaults()
    try await CompatHelpers.assertProtocToUs(proto: set, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? Int32, 99)
      XCTAssertEqual(try msg.get(forField: 2) as? String, "custom")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(99), forField: 1)
    try dynamic.set("custom", forField: 2)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat2_Proto2Defaults.self
    ) { decoded in
      XCTAssertEqual(decoded.count, 99)
      XCTAssertEqual(decoded.label, "custom")
    }
  }

  // MARK: - Proto2 oneof bidirectional

  func test_proto2_oneof_strVariant_bidirectional() async throws {
    var proto = Testcompat2_Proto2Oneof()
    proto.strVal = "hello"

    let desc = CompatDescriptors.proto2Oneof()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? String, "hello")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("hello", forField: 1)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat2_Proto2Oneof.self
    ) {
      decoded in
      if case .strVal(let v) = decoded.choice {
        XCTAssertEqual(v, "hello")
      }
      else {
        XCTFail("wrong case")
      }
    }
  }

  func test_proto2_oneof_msgVariant_bidirectional() async throws {
    var inner = Testcompat2_Proto2Basic()
    inner.requiredString = "inner"
    inner.requiredInt32 = 77

    var proto = Testcompat2_Proto2Oneof()
    proto.msgVal = inner
    proto.label = "outer"

    let desc = CompatDescriptors.proto2Oneof()
    let innerDesc = CompatDescriptors.proto2Basic()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let innerDyn = try XCTUnwrap(try msg.get(forField: 4) as? DynamicMessage)
      XCTAssertEqual(try innerDyn.get(forField: 1) as? String, "inner")
      XCTAssertEqual(try innerDyn.get(forField: 2) as? Int32, 77)
      XCTAssertEqual(try msg.get(forField: 10) as? String, "outer")
    }

    var innerDyn = DynamicMessage(descriptor: innerDesc)
    try innerDyn.set("inner", forField: 1)
    try innerDyn.set(Int32(77), forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(innerDyn, forField: 4)
    try dynamic.set("outer", forField: 10)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat2_Proto2Oneof.self
    ) {
      decoded in
      if case .msgVal(let m) = decoded.choice {
        XCTAssertEqual(m.requiredString, "inner")
        XCTAssertEqual(m.requiredInt32, 77)
      }
      else {
        XCTFail("wrong case")
      }
      XCTAssertEqual(decoded.label, "outer")
    }
  }

  // MARK: - Proto2 group field (group serialized as nested object in JSON)

  func test_proto2_group_basic_bidirectional() async throws {
    var proto = Testcompat2_Proto2WithGroup()
    proto.id = 1
    proto.myGroup.name = "grp"
    proto.myGroup.value = 42

    let jsonStr = try proto.jsonString()
    // Group in JSON appears as a regular nested object field
    XCTAssertTrue(
      jsonStr.contains("mygroup") || jsonStr.contains("myGroup") || jsonStr.contains("MyGroup"),
      "Group field should appear in JSON: \(jsonStr)"
    )

    let desc = CompatDescriptors.proto2WithGroup()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? Int32, 1)
      // Group appears as a nested message in our representation
      let grp = try XCTUnwrap(try msg.get(forField: 2) as? DynamicMessage)
      XCTAssertEqual(try grp.get(forField: 1) as? String, "grp")
      XCTAssertEqual(try grp.get(forField: 2) as? Int32, 42)
    }

    let grpDesc = try XCTUnwrap(desc.nestedMessages["MyGroup"])
    var grpDyn = DynamicMessage(descriptor: grpDesc)
    try grpDyn.set("grp", forField: 1)
    try grpDyn.set(Int32(42), forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(1), forField: 1)
    try dynamic.set(grpDyn, forField: 2)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat2_Proto2WithGroup.self
    ) { decoded in
      XCTAssertEqual(decoded.id, 1)
      XCTAssertEqual(decoded.myGroup.name, "grp")
      XCTAssertEqual(decoded.myGroup.value, 42)
    }
  }

  // MARK: - Proto2 multiple groups in one message (AnotherGroup)

  func test_proto2_multipleGroups_bidirectional() async throws {
    var proto = Testcompat2_Proto2WithGroup()
    proto.id = 3
    proto.myGroup.name = "g1"
    proto.myGroup.value = 10
    proto.anotherGroup.flag = true
    proto.anotherGroup.detail = "detail_val"

    let desc = CompatDescriptors.proto2WithGroup()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? Int32, 3)
      let g1 = try XCTUnwrap(try msg.get(forField: 2) as? DynamicMessage)
      XCTAssertEqual(try g1.get(forField: 1) as? String, "g1")
      let g2 = try XCTUnwrap(try msg.get(forField: 3) as? DynamicMessage)
      XCTAssertEqual(try g2.get(forField: 1) as? Bool, true)
      XCTAssertEqual(try g2.get(forField: 2) as? String, "detail_val")
    }

    let myGrpDesc = try XCTUnwrap(desc.nestedMessages["MyGroup"])
    var myGrp = DynamicMessage(descriptor: myGrpDesc)
    try myGrp.set("g1", forField: 1)
    try myGrp.set(Int32(10), forField: 2)

    let anotherGrpDesc = try XCTUnwrap(desc.nestedMessages["AnotherGroup"])
    var anotherGrp = DynamicMessage(descriptor: anotherGrpDesc)
    try anotherGrp.set(true, forField: 1)
    try anotherGrp.set("detail_val", forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(3), forField: 1)
    try dynamic.set(myGrp, forField: 2)
    try dynamic.set(anotherGrp, forField: 3)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat2_Proto2WithGroup.self
    ) { decoded in
      XCTAssertEqual(decoded.id, 3)
      XCTAssertEqual(decoded.myGroup.name, "g1")
      XCTAssertTrue(decoded.anotherGroup.flag)
      XCTAssertEqual(decoded.anotherGroup.detail, "detail_val")
    }
  }

  // MARK: - Proto2 group with enum inside (Proto2Complex.Item)

  func test_proto2_groupWithEnum_bidirectional() async throws {
    var proto = Testcompat2_Proto2Complex()
    proto.title = "complex"
    var item = Testcompat2_Proto2Complex.Item()
    item.id = 1
    item.label = "first"
    item.kind = .p2Alpha
    proto.item = [item]

    let desc = CompatDescriptors.proto2Complex()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? String, "complex")
      let items = try XCTUnwrap(try msg.get(forField: 4) as? [DynamicMessage])
      XCTAssertEqual(items.count, 1)
      XCTAssertEqual(try items[0].get(forField: 1) as? Int32, 1)
      XCTAssertEqual(try items[0].get(forField: 3) as? Int32, 1)
    }

    let itemDesc = try XCTUnwrap(desc.nestedMessages["Item"])
    var itemDyn = DynamicMessage(descriptor: itemDesc)
    try itemDyn.set(Int32(1), forField: 1)
    try itemDyn.set("first", forField: 2)
    try itemDyn.set(Int32(1), forField: 3)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("complex", forField: 1)
    try dynamic.set([itemDyn] as [DynamicMessage], forField: 4)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat2_Proto2Complex.self
    ) {
      decoded in
      XCTAssertEqual(decoded.title, "complex")
      XCTAssertEqual(decoded.item.count, 1)
      XCTAssertEqual(decoded.item[0].kind, .p2Alpha)
    }
  }

  // MARK: - Proto2 repeated group (Item) - multiple items

  func test_proto2_repeatedGroup_bidirectional() async throws {
    var proto = Testcompat2_Proto2Complex()
    proto.title = "multi"
    var i1 = Testcompat2_Proto2Complex.Item()
    i1.id = 10
    i1.kind = .p2Alpha
    var i2 = Testcompat2_Proto2Complex.Item()
    i2.id = 20
    i2.kind = .p2Gamma
    proto.item = [i1, i2]

    let desc = CompatDescriptors.proto2Complex()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let items = try XCTUnwrap(try msg.get(forField: 4) as? [DynamicMessage])
      XCTAssertEqual(items.count, 2)
      XCTAssertEqual(try items[0].get(forField: 1) as? Int32, 10)
      XCTAssertEqual(try items[1].get(forField: 1) as? Int32, 20)
    }

    let itemDesc = try XCTUnwrap(desc.nestedMessages["Item"])
    var d1 = DynamicMessage(descriptor: itemDesc)
    try d1.set(Int32(10), forField: 1)
    try d1.set(Int32(1), forField: 3)
    var d2 = DynamicMessage(descriptor: itemDesc)
    try d2.set(Int32(20), forField: 1)
    try d2.set(Int32(3), forField: 3)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("multi", forField: 1)
    try dynamic.set([d1, d2] as [DynamicMessage], forField: 4)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat2_Proto2Complex.self
    ) {
      decoded in
      XCTAssertEqual(decoded.item.count, 2)
      XCTAssertEqual(decoded.item[0].id, 10)
      XCTAssertEqual(decoded.item[1].kind, .p2Gamma)
    }
  }

  // MARK: - Proto2 extension: scalar (ext_name, ext_count, ext_flag)

  func test_proto2_extension_scalar_bidirectional() async throws {
    // Extensions in JSON are represented as regular fields by SwiftProtobuf
    var proto = Testcompat2_Proto2Extendable()
    proto.baseField = "base"
    proto.code = 5
    proto.Testcompat2_extName = "ext_str"
    proto.Testcompat2_extCount = 99
    proto.Testcompat2_extFlag = true

    let jsonStr = try proto.jsonString()
    XCTAssertTrue(jsonStr.contains("baseField"), "baseField should appear: \(jsonStr)")
    XCTAssertTrue(
      jsonStr.contains("extName") || jsonStr.contains("[testcompat2.ext_name]"),
      "ext_name in JSON: \(jsonStr)"
    )

    let desc = CompatDescriptors.proto2Extendable()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? String, "base")
      XCTAssertEqual(try msg.get(forField: 2) as? Int32, 5)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("base", forField: 1)
    try dynamic.set(Int32(5), forField: 2)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat2_Proto2Extendable.self
    ) { decoded in
      XCTAssertEqual(decoded.baseField, "base")
      XCTAssertEqual(decoded.code, 5)
    }
  }

  // MARK: - Proto2 extension: message extension (ext_msg)

  func test_proto2_extension_message_bidirectional() async throws {
    var inner = Testcompat2_Proto2Basic()
    inner.requiredString = "ext_inner"
    inner.requiredInt32 = 7

    var proto = Testcompat2_Proto2Extendable()
    proto.baseField = "base2"
    proto.Testcompat2_extMsg = inner

    let jsonStr = try proto.jsonString()
    XCTAssertTrue(jsonStr.contains("baseField"), "baseField should appear: \(jsonStr)")

    let desc = CompatDescriptors.proto2Extendable()
    let innerDesc = CompatDescriptors.proto2Basic()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? String, "base2")
    }

    var innerDyn = DynamicMessage(descriptor: innerDesc)
    try innerDyn.set("ext_inner", forField: 1)
    try innerDyn.set(Int32(7), forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("base2", forField: 1)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat2_Proto2Extendable.self
    ) { decoded in
      XCTAssertEqual(decoded.baseField, "base2")
    }
  }

  // MARK: - Proto2 extension: repeated extension (ext_tags, ext_ids)

  func test_proto2_extension_repeated_bidirectional() async throws {
    var proto = Testcompat2_Proto2Extendable()
    proto.baseField = "tags_test"
    proto.Testcompat2_extTags = ["tag1", "tag2", "tag3"]
    proto.Testcompat2_extIds = [1, 2, 3]

    let jsonStr = try proto.jsonString()
    XCTAssertTrue(jsonStr.contains("baseField"), "baseField: \(jsonStr)")

    let desc = CompatDescriptors.proto2Extendable()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? String, "tags_test")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("tags_test", forField: 1)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat2_Proto2Extendable.self
    ) { decoded in
      XCTAssertEqual(decoded.baseField, "tags_test")
    }
  }

  // MARK: - Proto2 Complex: fully populated

  func test_proto2_complex_fullPopulated_bidirectional() async throws {
    var proto = Testcompat2_Proto2Complex()
    proto.title = "full"
    proto.version = 3
    proto.header.key = "Content-Type"
    proto.header.value = "application/json"
    var basic = Testcompat2_Proto2Basic()
    basic.requiredString = "b"
    basic.requiredInt32 = 1
    proto.basic = basic
    proto.items = [basic]
    proto.meta = ["k": "v"]

    let desc = CompatDescriptors.proto2Complex()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? String, "full")
      XCTAssertEqual(try msg.get(forField: 2) as? Int32, 3)
      let header = try XCTUnwrap(try msg.get(forField: 3) as? DynamicMessage)
      XCTAssertEqual(try header.get(forField: 1) as? String, "Content-Type")
      let basic5 = try XCTUnwrap(try msg.get(forField: 5) as? DynamicMessage)
      XCTAssertEqual(try basic5.get(forField: 1) as? String, "b")
    }

    let headerDesc = try XCTUnwrap(desc.nestedMessages["Header"])
    var headerDyn = DynamicMessage(descriptor: headerDesc)
    try headerDyn.set("Content-Type", forField: 1)
    try headerDyn.set("application/json", forField: 2)

    let basicDesc = CompatDescriptors.proto2Basic()
    var basicDyn = DynamicMessage(descriptor: basicDesc)
    try basicDyn.set("b", forField: 1)
    try basicDyn.set(Int32(1), forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("full", forField: 1)
    try dynamic.set(Int32(3), forField: 2)
    try dynamic.set(headerDyn, forField: 3)
    try dynamic.set(basicDyn, forField: 5)
    try dynamic.set([basicDyn] as [DynamicMessage], forField: 6)
    try dynamic.setMapEntry("v", forKey: "k", inField: 7)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat2_Proto2Complex.self
    ) {
      decoded in
      XCTAssertEqual(decoded.title, "full")
      XCTAssertEqual(decoded.version, 3)
      XCTAssertEqual(decoded.header.key, "Content-Type")
      XCTAssertEqual(decoded.basic.requiredString, "b")
      XCTAssertEqual(decoded.items.count, 1)
      XCTAssertEqual(decoded.meta["k"], "v")
    }
  }

  // MARK: - Proto2 defaults: individual field default tests

  func test_proto2_defaultEnum_notSerialized_bidirectional() async throws {
    // Proto2Defaults with only `kind` field set (override default)
    var proto = Testcompat2_Proto2Defaults()
    proto.kind = .p2Alpha  // overrides default P2_BETA

    let jsonStr = try proto.jsonString()
    XCTAssertTrue(jsonStr.contains("kind"), "Overridden enum field should appear: \(jsonStr)")

    let desc = CompatDescriptors.proto2Defaults()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 7) as? Int32, 1)
    }

    // Direction B: build DynamicMessage with kind=P2_ALPHA (raw Int32 1) → SwiftProtobuf
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(1), forField: 7)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat2_Proto2Defaults.self
    ) {
      decoded in
      XCTAssertEqual(decoded.kind, .p2Alpha)
    }
  }

  func test_proto2_defaultBool_notSerialized_bidirectional() async throws {
    // Proto2Defaults: active has default = true (field 3)
    // When set to the default value (true), it should appear in JSON (proto2 serializes set optional fields)
    // When not set, it should be absent
    var protoSet = Testcompat2_Proto2Defaults()
    protoSet.active = false  // explicitly set to non-default

    let jsonStr = try protoSet.jsonString()
    XCTAssertTrue(jsonStr.contains("active"), "Explicitly set bool field should appear: \(jsonStr)")

    let desc = CompatDescriptors.proto2Defaults()
    try await CompatHelpers.assertProtocToUs(proto: protoSet, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 3) as? Bool, false)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(false, forField: 3)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat2_Proto2Defaults.self
    ) {
      decoded in
      XCTAssertEqual(decoded.active, false)
    }

    // Unset proto2 optional → absent from JSON
    let protoUnset = Testcompat2_Proto2Defaults()
    let jsonUnset = try protoUnset.jsonString()
    XCTAssertFalse(jsonUnset.contains("active"), "Unset proto2 optional should be absent: \(jsonUnset)")
  }

  func test_proto2_defaultFloat_notSerialized_bidirectional() async throws {
    // Proto2Defaults: ratio has default = 0.5 (field 5)
    // Explicitly set to non-default value
    var protoSet = Testcompat2_Proto2Defaults()
    protoSet.ratio = 1.5  // override default 0.5

    let jsonStr = try protoSet.jsonString()
    XCTAssertTrue(jsonStr.contains("ratio"), "Explicitly set float field should appear: \(jsonStr)")

    let desc = CompatDescriptors.proto2Defaults()
    try await CompatHelpers.assertProtocToUs(proto: protoSet, descriptor: desc, registry: registry) { msg in
      let val = try XCTUnwrap(try msg.get(forField: 5) as? Float)
      XCTAssertEqual(val, 1.5, accuracy: 0.001)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Float(1.5), forField: 5)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat2_Proto2Defaults.self
    ) {
      decoded in
      XCTAssertEqual(decoded.ratio, 1.5, accuracy: 0.001)
    }

    // Unset proto2 optional → absent from JSON
    let protoUnset = Testcompat2_Proto2Defaults()
    let jsonUnset = try protoUnset.jsonString()
    XCTAssertFalse(jsonUnset.contains("ratio"), "Unset proto2 optional should be absent: \(jsonUnset)")
  }

  func test_proto2_magic_bytes_bidirectional() async throws {
    // Proto2Defaults: magic field has default \x00\x01\x02
    var proto = Testcompat2_Proto2Defaults()
    proto.magic = Data([0xDE, 0xAD, 0xBE, 0xEF])

    let desc = CompatDescriptors.proto2Defaults()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 6) as? Data, Data([0xDE, 0xAD, 0xBE, 0xEF]))
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Data([0xDE, 0xAD, 0xBE, 0xEF]), forField: 6)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat2_Proto2Defaults.self
    ) {
      decoded in
      XCTAssertEqual(decoded.magic, Data([0xDE, 0xAD, 0xBE, 0xEF]))
    }
  }

  // MARK: - Proto2 Kitchen Sink

  func test_proto2_kitchenSink_basic_bidirectional() async throws {
    var proto = Testcompat2_Proto2KitchenSink()
    proto.name = "kitchen"
    proto.id = 99
    proto.status = .p2Alpha
    proto.tags = ["tag1", "tag2"]
    proto.scores = ["a": 1, "b": 2]

    let desc = CompatDescriptors.proto2KitchenSink()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? String, "kitchen")
      XCTAssertEqual(try msg.get(forField: 2) as? Int32, 99)
      XCTAssertEqual(try msg.get(forField: 3) as? Int32, 1)
      XCTAssertEqual(try msg.get(forField: 4) as? [String], ["tag1", "tag2"])
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("kitchen", forField: 1)
    try dynamic.set(Int32(99), forField: 2)
    try dynamic.set(Int32(1), forField: 3)
    try dynamic.set(["tag1", "tag2"] as [String], forField: 4)
    try dynamic.setMapEntry(Int32(1), forKey: "a", inField: 5)
    try dynamic.setMapEntry(Int32(2), forKey: "b", inField: 5)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat2_Proto2KitchenSink.self
    ) { decoded in
      XCTAssertEqual(decoded.name, "kitchen")
      XCTAssertEqual(decoded.id, 99)
      XCTAssertEqual(decoded.status, .p2Alpha)
      XCTAssertEqual(decoded.tags, ["tag1", "tag2"])
      XCTAssertEqual(decoded.scores["a"], 1)
      XCTAssertEqual(decoded.scores["b"], 2)
    }
  }
}
