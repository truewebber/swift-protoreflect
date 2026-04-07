// JSONCompatCrossFileTests.swift
// SwiftProtoReflectTests
//
// Group 11: Cross-File — messages referencing types from other .proto files.
// Bidirectional JSON compatibility tests.
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class JSONCompatCrossFileTests: XCTestCase {

  private var registry: TypeRegistry!

  override func setUp() async throws {
    try await super.setUp()
    registry = try? await CompatDescriptors.fullRegistry()
  }

  override func tearDown() async throws {
    registry = nil
    try await super.tearDown()
  }

  // MARK: - CrossFileAll: all message types from different files

  func test_crossFile_all_basicFields_bidirectional() async throws {
    var proto = Testcompat_CrossFileAll()
    proto.simple.id = 1
    proto.simple.name = "cross"
    proto.status = .active
    proto.priority = .low

    let desc = CompatDescriptors.crossFileAll()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let simpleDyn = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try simpleDyn.get(forField: 1) as? Int32, 1)
      XCTAssertEqual(try simpleDyn.get(forField: 2) as? String, "cross")
      XCTAssertEqual(try msg.get(forField: 7) as? Int32, 1)
      XCTAssertEqual(try msg.get(forField: 8) as? Int32, 1)
    }

    let simpleDesc = CompatDescriptors.simpleMessage()
    var simpleDyn = DynamicMessage(descriptor: simpleDesc)
    try simpleDyn.set(Int32(1), forField: 1)
    try simpleDyn.set("cross", forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(simpleDyn, forField: 1)
    try dynamic.set(Int32(1), forField: 7)
    try dynamic.set(Int32(1), forField: 8)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_CrossFileAll.self
    ) {
      decoded in
      XCTAssertEqual(decoded.simple.id, 1)
      XCTAssertEqual(decoded.simple.name, "cross")
      XCTAssertEqual(decoded.status, .active)
      XCTAssertEqual(decoded.priority, .low)
    }
  }

  // MARK: - CrossFileAll: scalar field nested from scalar_types.proto

  func test_crossFile_all_scalarMessage_bidirectional() async throws {
    var proto = Testcompat_CrossFileAll()
    proto.scalar.int32Field = 42
    proto.scalar.stringField = "nested"
    proto.scalar.boolField = true

    let desc = CompatDescriptors.crossFileAll()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let scalarDyn = try XCTUnwrap(try msg.get(forField: 2) as? DynamicMessage)
      XCTAssertEqual(try scalarDyn.get(forField: 3) as? Int32, 42)
      XCTAssertEqual(try scalarDyn.get(forField: 14) as? String, "nested")
      XCTAssertEqual(try scalarDyn.get(forField: 13) as? Bool, true)
    }

    let scalarDesc = CompatDescriptors.scalarMessage()
    var scalarDyn = DynamicMessage(descriptor: scalarDesc)
    try scalarDyn.set(Int32(42), forField: 3)
    try scalarDyn.set("nested", forField: 14)
    try scalarDyn.set(true, forField: 13)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(scalarDyn, forField: 2)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_CrossFileAll.self
    ) {
      decoded in
      XCTAssertEqual(decoded.scalar.int32Field, 42)
      XCTAssertEqual(decoded.scalar.stringField, "nested")
      XCTAssertTrue(decoded.scalar.boolField)
    }
  }

  // MARK: - CrossFileMixed: repeated + map + oneof from different files

  func test_crossFile_mixed_repeatedAndMap_bidirectional() async throws {
    var proto = Testcompat_CrossFileMixed()
    var s1 = Testcompat_SimpleMessage()
    s1.id = 10
    s1.name = "item1"
    proto.items = [s1]
    proto.statuses = [.active, .inactive]

    let desc = CompatDescriptors.crossFileMixed()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let items = try XCTUnwrap(try msg.get(forField: 1) as? [DynamicMessage])
      XCTAssertEqual(items.count, 1)
      XCTAssertEqual(try items[0].get(forField: 1) as? Int32, 10)
      let statuses = try XCTUnwrap(try msg.get(forField: 6) as? [Int32])
      XCTAssertEqual(statuses, [1, 2])
    }

    let simpleDesc = CompatDescriptors.simpleMessage()
    var dItem = DynamicMessage(descriptor: simpleDesc)
    try dItem.set(Int32(10), forField: 1)
    try dItem.set("item1", forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set([dItem] as [DynamicMessage], forField: 1)
    try dynamic.set([Int32(1), Int32(2)] as [Int32], forField: 6)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_CrossFileMixed.self
    ) { decoded in
      XCTAssertEqual(decoded.items.count, 1)
      XCTAssertEqual(decoded.items[0].id, 10)
      XCTAssertEqual(decoded.statuses, [.active, .inactive])
    }
  }

  // MARK: - CrossFileMixed: oneof referencing types from different files

  func test_crossFile_mixed_oneof_simplePick_bidirectional() async throws {
    var proto = Testcompat_CrossFileMixed()
    proto.simplePick.id = 5
    proto.simplePick.name = "pick"

    let desc = CompatDescriptors.crossFileMixed()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let picked = try XCTUnwrap(try msg.get(forField: 3) as? DynamicMessage)
      XCTAssertEqual(try picked.get(forField: 1) as? Int32, 5)
      XCTAssertEqual(try picked.get(forField: 2) as? String, "pick")
    }

    let simpleDesc = CompatDescriptors.simpleMessage()
    var pickedDyn = DynamicMessage(descriptor: simpleDesc)
    try pickedDyn.set(Int32(5), forField: 1)
    try pickedDyn.set("pick", forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(pickedDyn, forField: 3)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_CrossFileMixed.self
    ) { decoded in
      if case .simplePick(let m) = decoded.pick {
        XCTAssertEqual(m.id, 5)
        XCTAssertEqual(m.name, "pick")
      }
      else {
        XCTFail("wrong oneof case")
      }
    }
  }

  // MARK: - CrossPackageRef: mixing proto2 types with proto3

  func test_crossFile_crossPackageRef_bidirectional() async throws {
    var proto = Testcompat_CrossPackageRef()
    proto.p2Basic.requiredString = "p2str"
    proto.p2Basic.requiredInt32 = 7
    proto.label = "cross_pkg"
    proto.created.seconds = 12345

    let desc = CompatDescriptors.crossPackageRef()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let p2Dyn = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try p2Dyn.get(forField: 1) as? String, "p2str")
      XCTAssertEqual(try p2Dyn.get(forField: 2) as? Int32, 7)
      XCTAssertEqual(try msg.get(forField: 10) as? String, "cross_pkg")
      let tsDyn = try XCTUnwrap(try msg.get(forField: 11) as? DynamicMessage)
      XCTAssertEqual(try tsDyn.get(forField: 1) as? Int64, 12345)
    }

    let p2BasicDesc = CompatDescriptors.proto2Basic()
    var p2Dyn = DynamicMessage(descriptor: p2BasicDesc)
    try p2Dyn.set("p2str", forField: 1)
    try p2Dyn.set(Int32(7), forField: 2)

    let tsDesc = CompatDescriptors.wktTimestamp()
    var tsDyn = DynamicMessage(descriptor: tsDesc)
    try tsDyn.set(Int64(12345), forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(p2Dyn, forField: 1)
    try dynamic.set("cross_pkg", forField: 10)
    try dynamic.set(tsDyn, forField: 11)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_CrossPackageRef.self
    ) { decoded in
      XCTAssertEqual(decoded.p2Basic.requiredString, "p2str")
      XCTAssertEqual(decoded.p2Basic.requiredInt32, 7)
      XCTAssertEqual(decoded.label, "cross_pkg")
      XCTAssertEqual(decoded.created.seconds, 12345)
    }
  }

  // MARK: - CrossFileMixed: map<string, ScalarMessage>

  func test_crossFile_mixed_mapCrossType_bidirectional() async throws {
    var scalar = Testcompat_ScalarMessage()
    scalar.int32Field = 99
    scalar.stringField = "v"

    var proto = Testcompat_CrossFileMixed()
    proto.details = ["key": scalar]

    let desc = CompatDescriptors.crossFileMixed()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let map = try XCTUnwrap(try msg.get(forField: 2) as? [AnyHashable: Any])
      let dyn = try XCTUnwrap(map["key"] as? DynamicMessage)
      XCTAssertEqual(try dyn.get(forField: 3) as? Int32, 99)
      XCTAssertEqual(try dyn.get(forField: 14) as? String, "v")
    }

    let scalarDesc = CompatDescriptors.scalarMessage()
    var scalarDyn = DynamicMessage(descriptor: scalarDesc)
    try scalarDyn.set(Int32(99), forField: 3)
    try scalarDyn.set("v", forField: 14)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry(scalarDyn, forKey: "key", inField: 2)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_CrossFileMixed.self
    ) { decoded in
      XCTAssertEqual(decoded.details["key"]?.int32Field, 99)
    }
  }

  // MARK: - CrossFileMixed: oneof nested_pick (Nested1 from nesting_types)

  func test_crossFile_mixed_oneof_nestedPick_bidirectional() async throws {
    var proto = Testcompat_CrossFileMixed()
    proto.nestedPick.name = "nested_in_oneof"

    let desc = CompatDescriptors.crossFileMixed()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let picked = try XCTUnwrap(try msg.get(forField: 5) as? DynamicMessage)
      XCTAssertEqual(try picked.get(forField: 2) as? String, "nested_in_oneof")
    }

    let nestedDesc = CompatDescriptors.nested1()
    var nestedDyn = DynamicMessage(descriptor: nestedDesc)
    try nestedDyn.set("nested_in_oneof", forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(nestedDyn, forField: 5)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_CrossFileMixed.self
    ) { decoded in
      if case .nestedPick(let n) = decoded.pick {
        XCTAssertEqual(n.name, "nested_in_oneof")
      }
      else {
        XCTFail("wrong oneof")
      }
    }
  }

  // MARK: - MegaMixed: deeply nested cross-file types

  func test_megaMixed_deepNested_bidirectional() async throws {
    var proto = Testcompat_MegaMixed()
    proto.name = "mega"
    proto.child.inner.simple.id = 1
    proto.child.inner.simple.name = "deep"
    proto.child.text = "leaf_text"

    let desc = CompatDescriptors.megaMixed()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 2) as? String, "mega")
      let child = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
      let inner = try XCTUnwrap(try child.get(forField: 1) as? DynamicMessage)
      let simple = try XCTUnwrap(try inner.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try simple.get(forField: 1) as? Int32, 1)
      XCTAssertEqual(try simple.get(forField: 2) as? String, "deep")
      XCTAssertEqual(try child.get(forField: 3) as? String, "leaf_text")
    }

    let outerDesc = CompatDescriptors.megaMixed()
    let layer2Desc = try XCTUnwrap(outerDesc.nestedMessages["Layer2"])
    let layer3Desc = try XCTUnwrap(layer2Desc.nestedMessages["Layer3"])
    let simpleDesc = CompatDescriptors.simpleMessage()

    var simpleDyn = DynamicMessage(descriptor: simpleDesc)
    try simpleDyn.set(Int32(1), forField: 1)
    try simpleDyn.set("deep", forField: 2)

    var layer3Dyn = DynamicMessage(descriptor: layer3Desc)
    try layer3Dyn.set(simpleDyn, forField: 1)

    var layer2Dyn = DynamicMessage(descriptor: layer2Desc)
    try layer2Dyn.set(layer3Dyn, forField: 1)
    try layer2Dyn.set("leaf_text", forField: 3)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("mega", forField: 2)
    try dynamic.set(layer2Dyn, forField: 1)
    try await CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MegaMixed.self)
    {
      decoded in
      XCTAssertEqual(decoded.name, "mega")
      XCTAssertEqual(decoded.child.inner.simple.id, 1)
      XCTAssertEqual(decoded.child.text, "leaf_text")
    }
  }

  // MARK: - MegaMixed: map<string, Layer2>

  func test_megaMixed_mapOfLayers_bidirectional() async throws {
    var proto = Testcompat_MegaMixed()
    proto.name = "map_test"
    var l2a = Testcompat_MegaMixed.Layer2()
    l2a.text = "text_a"
    var l2b = Testcompat_MegaMixed.Layer2()
    l2b.text = "text_b"
    proto.branches = ["a": l2a, "b": l2b]

    let desc = CompatDescriptors.megaMixed()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let branches = try XCTUnwrap(try msg.get(forField: 3) as? [AnyHashable: Any])
      XCTAssertEqual(branches.count, 2)
      let dA = try XCTUnwrap(branches["a"] as? DynamicMessage)
      XCTAssertEqual(try dA.get(forField: 3) as? String, "text_a")
    }

    let outerDesc = CompatDescriptors.megaMixed()
    let layer2Desc = try XCTUnwrap(outerDesc.nestedMessages["Layer2"])
    var dynA = DynamicMessage(descriptor: layer2Desc)
    try dynA.set("text_a", forField: 3)
    var dynB = DynamicMessage(descriptor: layer2Desc)
    try dynB.set("text_b", forField: 3)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("map_test", forField: 2)
    try dynamic.setMapEntry(dynA, forKey: "a", inField: 3)
    try dynamic.setMapEntry(dynB, forKey: "b", inField: 3)
    try await CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MegaMixed.self)
    {
      decoded in
      XCTAssertEqual(decoded.branches["a"]?.text, "text_a")
      XCTAssertEqual(decoded.branches["b"]?.text, "text_b")
    }
  }

  // MARK: - MegaMixed: fully populated (ts, nested, repeated oneofs)

  func test_megaMixed_fullyPopulated_bidirectional() async throws {
    var proto = Testcompat_MegaMixed()
    proto.name = "full"
    proto.ts.seconds = 9999
    proto.nested.name = "nested_top"
    var oc = Testcompat_OneofComplex()
    oc.intVal = 42
    proto.oneofs = [oc]
    proto.child.text = "child_text"

    let desc = CompatDescriptors.megaMixed()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 2) as? String, "full")
      let tsDyn = try XCTUnwrap(try msg.get(forField: 5) as? DynamicMessage)
      XCTAssertEqual(try tsDyn.get(forField: 1) as? Int64, 9999)
      let nestedDyn = try XCTUnwrap(try msg.get(forField: 6) as? DynamicMessage)
      XCTAssertEqual(try nestedDyn.get(forField: 2) as? String, "nested_top")
    }

    let tsDesc = CompatDescriptors.wktTimestamp()
    var tsDyn = DynamicMessage(descriptor: tsDesc)
    try tsDyn.set(Int64(9999), forField: 1)

    let nestedDesc = CompatDescriptors.nested1()
    var nestedDyn = DynamicMessage(descriptor: nestedDesc)
    try nestedDyn.set("nested_top", forField: 2)

    let ocDesc = CompatDescriptors.oneofComplex()
    var ocDyn = DynamicMessage(descriptor: ocDesc)
    try ocDyn.set(Int32(42), forField: 1)

    let outerDesc = CompatDescriptors.megaMixed()
    let layer2Desc = try XCTUnwrap(outerDesc.nestedMessages["Layer2"])
    var l2Dyn = DynamicMessage(descriptor: layer2Desc)
    try l2Dyn.set("child_text", forField: 3)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("full", forField: 2)
    try dynamic.set(tsDyn, forField: 5)
    try dynamic.set(nestedDyn, forField: 6)
    try dynamic.set([ocDyn] as [DynamicMessage], forField: 4)
    try dynamic.set(l2Dyn, forField: 1)
    try await CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MegaMixed.self)
    {
      decoded in
      XCTAssertEqual(decoded.name, "full")
      XCTAssertEqual(decoded.ts.seconds, 9999)
      XCTAssertEqual(decoded.nested.name, "nested_top")
      XCTAssertEqual(decoded.oneofs.count, 1)
    }
  }

  // MARK: - CrossPackageRef: Int64Value wrapper from WKT

  func test_crossFile_crossPackageRef_int64Value_bidirectional() async throws {
    var proto = Testcompat_CrossPackageRef()
    proto.p2Basic.requiredString = "r"
    proto.p2Basic.requiredInt32 = 0
    proto.count.value = Int64.max

    let desc = CompatDescriptors.crossPackageRef()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let cntDyn = try XCTUnwrap(try msg.get(forField: 12) as? DynamicMessage)
      XCTAssertEqual(try cntDyn.get(forField: 1) as? Int64, Int64.max)
    }

    let p2BasicDesc = CompatDescriptors.proto2Basic()
    var p2Dyn = DynamicMessage(descriptor: p2BasicDesc)
    try p2Dyn.set("r", forField: 1)
    try p2Dyn.set(Int32(0), forField: 2)

    let i64wDesc = CompatDescriptors.wktWrapper(name: "Int64Value", fieldType: .int64)
    var cntDyn = DynamicMessage(descriptor: i64wDesc)
    try cntDyn.set(Int64.max, forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(p2Dyn, forField: 1)
    try dynamic.set(cntDyn, forField: 12)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_CrossPackageRef.self
    ) { decoded in
      XCTAssertEqual(decoded.count.value, Int64.max)
    }
  }

  // MARK: - Cross-package: proto2 defaults inside proto3 wrapper

  func test_crossPackage_proto2DefaultsInProto3_bidirectional() async throws {
    // CrossPackageRef.p2Defaults: proto2 message with declared defaults.
    // When p2Defaults fields are left unset, they should be absent from JSON
    // (proto2 optional unset = no field presence).
    var proto = Testcompat_CrossPackageRef()
    proto.label = "defaults_test"
    // p2Defaults fields intentionally left unset — proto2 optional unset = absent in JSON

    let desc = CompatDescriptors.crossPackageRef()
    let jsonStr = try proto.jsonString()
    // Unset proto2 optional fields should not appear
    XCTAssertFalse(
      jsonStr.contains("\"count\""),
      "Unset proto2 optional count should be absent: \(jsonStr)"
    )
    XCTAssertFalse(
      jsonStr.contains("\"active\""),
      "Unset proto2 optional active should be absent: \(jsonStr)"
    )

    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 10) as? String, "defaults_test")
      // p2Defaults sub-message absent → nil
      XCTAssertNil(try msg.get(forField: 2) as? DynamicMessage)
    }

    // Direction B: explicitly set some proto2 defaults fields to non-default values
    var protoExplicit = Testcompat_CrossPackageRef()
    protoExplicit.label = "explicit"
    protoExplicit.p2Defaults.count = 100  // default is 42
    protoExplicit.p2Defaults.label = "overridden"  // default is "hello"

    let p2DefaultsDesc = CompatDescriptors.proto2Defaults()
    var p2Dyn = DynamicMessage(descriptor: p2DefaultsDesc)
    try p2Dyn.set(Int32(100), forField: 1)
    try p2Dyn.set("overridden", forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(p2Dyn, forField: 2)
    try dynamic.set("explicit", forField: 10)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_CrossPackageRef.self
    ) { decoded in
      XCTAssertEqual(decoded.label, "explicit")
      XCTAssertEqual(decoded.p2Defaults.count, 100)
      XCTAssertEqual(decoded.p2Defaults.label, "overridden")
    }
  }
}
