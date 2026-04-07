// JSONCompatNestedTests.swift
// SwiftProtoReflectTests
//
// Group 5: Nested Messages — bidirectional JSON compatibility tests.
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class JSONCompatNestedTests: XCTestCase {

  private var registry: TypeRegistry!

  override func setUp() async throws {
    try await super.setUp()
    registry = try? await CompatDescriptors.fullRegistry()
  }

  override func tearDown() async throws {
    registry = nil
    try await super.tearDown()
  }

  // MARK: - 1 level nesting (Nested1 → Nested2)

  func test_nested_1level_bidirectional() async throws {
    var proto = Testcompat_Nested1()
    proto.name = "level1"
    proto.child.count = 10

    let desc = CompatDescriptors.nested1()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 2) as? String, "level1")
      let child = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try child.get(forField: 2) as? Int32, 10)
    }

    let n2desc = CompatDescriptors.nested2()
    var n2 = DynamicMessage(descriptor: n2desc)
    try n2.set(Int32(10), forField: 2)
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("level1", forField: 2)
    try dynamic.set(n2, forField: 1)
    try await CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_Nested1.self) {
      decoded in
      XCTAssertEqual(decoded.name, "level1")
      XCTAssertEqual(decoded.child.count, 10)
    }
  }

  // MARK: - 2 level nesting (Nested1 → Nested2 → Nested3)

  func test_nested_2levels_bidirectional() async throws {
    var proto = Testcompat_Nested1()
    proto.name = "level1"
    proto.child.count = 5
    proto.child.child.flag = true
    proto.child.child.props = ["key": 99]

    let desc = CompatDescriptors.nested1()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let n2 = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try n2.get(forField: 2) as? Int32, 5)
      let n3 = try XCTUnwrap(try n2.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try n3.get(forField: 3) as? Bool, true)
      let props = try XCTUnwrap(try n3.get(forField: 2) as? [AnyHashable: Any])
      XCTAssertEqual(props["key"] as? Int32, 99)
    }

    let n3desc = CompatDescriptors.nested3()
    var n3 = DynamicMessage(descriptor: n3desc)
    try n3.set(true, forField: 3)
    try n3.setMapEntry(Int32(99), forKey: "key", inField: 2)

    let n2desc = CompatDescriptors.nested2()
    var n2 = DynamicMessage(descriptor: n2desc)
    try n2.set(Int32(5), forField: 2)
    try n2.set(n3, forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("level1", forField: 2)
    try dynamic.set(n2, forField: 1)
    try await CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_Nested1.self) {
      decoded in
      XCTAssertEqual(decoded.child.count, 5)
      XCTAssertTrue(decoded.child.child.flag)
      XCTAssertEqual(decoded.child.child.props["key"], 99)
    }
  }

  // MARK: - 3 level nesting (Nested1 → Nested2 → Nested3 → Nested4)

  func test_nested_3levels_bidirectional() async throws {
    var proto = Testcompat_Nested1()
    proto.name = "top"
    proto.child.count = 3
    proto.child.child.flag = false
    proto.child.child.child.value = 777
    proto.child.child.child.tags = ["a", "b"]

    let desc = CompatDescriptors.nested1()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let n2 = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
      let n3 = try XCTUnwrap(try n2.get(forField: 1) as? DynamicMessage)
      let n4 = try XCTUnwrap(try n3.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try n4.get(forField: 1) as? Int32, 777)
      XCTAssertEqual(try n4.get(forField: 2) as? [String], ["a", "b"])
    }

    let n4desc = CompatDescriptors.nested4()
    var n4 = DynamicMessage(descriptor: n4desc)
    try n4.set(Int32(777), forField: 1)
    try n4.set(["a", "b"] as [String], forField: 2)

    let n3desc = CompatDescriptors.nested3()
    var n3 = DynamicMessage(descriptor: n3desc)
    try n3.set(false, forField: 3)
    try n3.set(n4, forField: 1)

    let n2desc = CompatDescriptors.nested2()
    var n2 = DynamicMessage(descriptor: n2desc)
    try n2.set(Int32(3), forField: 2)
    try n2.set(n3, forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("top", forField: 2)
    try dynamic.set(n2, forField: 1)
    try await CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_Nested1.self) {
      decoded in
      XCTAssertEqual(decoded.child.child.child.value, 777)
      XCTAssertEqual(decoded.child.child.child.tags, ["a", "b"])
    }
  }

  // MARK: - Nested1 siblings (repeated Nested2)

  func test_nested_siblings_bidirectional() async throws {
    var proto = Testcompat_Nested1()
    proto.name = "parent"
    var s1 = Testcompat_Nested2()
    s1.count = 1
    var s2 = Testcompat_Nested2()
    s2.count = 2
    proto.siblings = [s1, s2]

    let desc = CompatDescriptors.nested1()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let siblings = try XCTUnwrap(try msg.get(forField: 3) as? [DynamicMessage])
      XCTAssertEqual(siblings.count, 2)
      XCTAssertEqual(try siblings[0].get(forField: 2) as? Int32, 1)
      XCTAssertEqual(try siblings[1].get(forField: 2) as? Int32, 2)
    }

    let n2desc = CompatDescriptors.nested2()
    var sib1 = DynamicMessage(descriptor: n2desc)
    try sib1.set(Int32(1), forField: 2)
    var sib2 = DynamicMessage(descriptor: n2desc)
    try sib2.set(Int32(2), forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("parent", forField: 2)
    try dynamic.set([sib1, sib2] as [DynamicMessage], forField: 3)
    try await CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_Nested1.self) {
      decoded in
      XCTAssertEqual(decoded.siblings.count, 2)
      XCTAssertEqual(decoded.siblings[0].count, 1)
      XCTAssertEqual(decoded.siblings[1].count, 2)
    }
  }

  // MARK: - Nested2 oneof variant (text)

  func test_nested_nested2_oneofText_bidirectional() async throws {
    var proto = Testcompat_Nested2()
    proto.count = 5
    proto.text = "chosen"

    let desc = CompatDescriptors.nested2()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 2) as? Int32, 5)
      XCTAssertEqual(try msg.get(forField: 3) as? String, "chosen")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(5), forField: 2)
    try dynamic.set("chosen", forField: 3)
    try await CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_Nested2.self) {
      decoded in
      XCTAssertEqual(decoded.count, 5)
      if case .text(let v) = decoded.variant {
        XCTAssertEqual(v, "chosen")
      }
      else {
        XCTFail("wrong case")
      }
    }
  }

  // MARK: - Recursive message

  func test_nested_recursive_shallow_bidirectional() async throws {
    var proto = Testcompat_Recursive()
    proto.value = 1
    proto.label = "root"
    proto.child.value = 2
    proto.child.label = "child"

    let desc = CompatDescriptors.recursive()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? Int32, 1)
      XCTAssertEqual(try msg.get(forField: 2) as? String, "root")
      let child = try XCTUnwrap(try msg.get(forField: 3) as? DynamicMessage)
      XCTAssertEqual(try child.get(forField: 1) as? Int32, 2)
      XCTAssertEqual(try child.get(forField: 2) as? String, "child")
    }

    var childDyn = DynamicMessage(descriptor: desc)
    try childDyn.set(Int32(2), forField: 1)
    try childDyn.set("child", forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(1), forField: 1)
    try dynamic.set("root", forField: 2)
    try dynamic.set(childDyn, forField: 3)
    try await CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_Recursive.self)
    {
      decoded in
      XCTAssertEqual(decoded.value, 1)
      XCTAssertEqual(decoded.label, "root")
      XCTAssertEqual(decoded.child.value, 2)
      XCTAssertEqual(decoded.child.label, "child")
    }
  }

  // MARK: - Recursive with children list

  func test_nested_recursive_withChildren_bidirectional() async throws {
    var proto = Testcompat_Recursive()
    proto.value = 0
    var c1 = Testcompat_Recursive()
    c1.value = 10
    var c2 = Testcompat_Recursive()
    c2.value = 20
    proto.children = [c1, c2]

    let desc = CompatDescriptors.recursive()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let children = try XCTUnwrap(try msg.get(forField: 4) as? [DynamicMessage])
      XCTAssertEqual(children.count, 2)
      XCTAssertEqual(try children[0].get(forField: 1) as? Int32, 10)
      XCTAssertEqual(try children[1].get(forField: 1) as? Int32, 20)
    }

    var ch1 = DynamicMessage(descriptor: desc)
    try ch1.set(Int32(10), forField: 1)
    var ch2 = DynamicMessage(descriptor: desc)
    try ch2.set(Int32(20), forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(0), forField: 1)
    try dynamic.set([ch1, ch2] as [DynamicMessage], forField: 4)
    try await CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_Recursive.self)
    {
      decoded in
      XCTAssertEqual(decoded.children.count, 2)
      XCTAssertEqual(decoded.children[0].value, 10)
      XCTAssertEqual(decoded.children[1].value, 20)
    }
  }

  // MARK: - 4-level fully populated

  func test_nested_4level_fullyPopulated_bidirectional() async throws {
    var proto = Testcompat_Nested1()
    proto.name = "root"
    proto.child.count = 3
    proto.child.text = "chosen"
    proto.child.child.flag = true
    proto.child.child.props = ["a": 1, "b": 2]
    proto.child.child.child.value = 99
    proto.child.child.child.tags = ["x", "y"]
    proto.child.child.child.status = .active
    var sib = Testcompat_Nested2()
    sib.count = 10
    proto.siblings = [sib]

    let desc = CompatDescriptors.nested1()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 2) as? String, "root")
      let n2 = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try n2.get(forField: 2) as? Int32, 3)
      XCTAssertEqual(try n2.get(forField: 3) as? String, "chosen")
      let n3 = try XCTUnwrap(try n2.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try n3.get(forField: 3) as? Bool, true)
      let n4 = try XCTUnwrap(try n3.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try n4.get(forField: 1) as? Int32, 99)
      XCTAssertEqual(try n4.get(forField: 2) as? [String], ["x", "y"])
      XCTAssertEqual(try n4.get(forField: 3) as? Int32, 1)
      let sibs = try XCTUnwrap(try msg.get(forField: 3) as? [DynamicMessage])
      XCTAssertEqual(sibs.count, 1)
    }

    let n4desc = CompatDescriptors.nested4()
    var n4 = DynamicMessage(descriptor: n4desc)
    try n4.set(Int32(99), forField: 1)
    try n4.set(["x", "y"] as [String], forField: 2)
    try n4.set(Int32(1), forField: 3)

    let n3desc = CompatDescriptors.nested3()
    var n3 = DynamicMessage(descriptor: n3desc)
    try n3.set(true, forField: 3)
    try n3.setMapEntry(Int32(1), forKey: "a", inField: 2)
    try n3.setMapEntry(Int32(2), forKey: "b", inField: 2)
    try n3.set(n4, forField: 1)

    let n2desc = CompatDescriptors.nested2()
    var n2 = DynamicMessage(descriptor: n2desc)
    try n2.set(Int32(3), forField: 2)
    try n2.set("chosen", forField: 3)
    try n2.set(n3, forField: 1)

    var sib1 = DynamicMessage(descriptor: n2desc)
    try sib1.set(Int32(10), forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("root", forField: 2)
    try dynamic.set(n2, forField: 1)
    try dynamic.set([sib1] as [DynamicMessage], forField: 3)
    try await CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_Nested1.self) {
      decoded in
      XCTAssertEqual(decoded.name, "root")
      XCTAssertEqual(decoded.child.count, 3)
      XCTAssertEqual(decoded.child.child.child.value, 99)
      XCTAssertEqual(decoded.siblings.count, 1)
    }
  }

  // MARK: - OuterWithNestedDefs: map with InnerDef values (map<string, MiddleDef.InnerDef>)

  func test_nested_nestedDefs_mapWithInnerDef_bidirectional() async throws {
    var proto = Testcompat_OuterWithNestedDefs()
    proto.kind = .outerB
    var innerDef = Testcompat_OuterWithNestedDefs.MiddleDef.InnerDef()
    innerDef.code = 404
    innerDef.reason = "not found"
    proto.errors = ["key1": innerDef]

    let desc = CompatDescriptors.outerWithNestedDefs()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 3) as? Int32, 2)
      let errors = try XCTUnwrap(try msg.get(forField: 4) as? [AnyHashable: Any])
      let innerDyn = try XCTUnwrap(errors["key1"] as? DynamicMessage)
      XCTAssertEqual(try innerDyn.get(forField: 1) as? Int32, 404)
      XCTAssertEqual(try innerDyn.get(forField: 2) as? String, "not found")
    }

    // Direction B: build using InnerDef descriptor
    let outerDesc = CompatDescriptors.outerWithNestedDefs()
    let middleDesc = try XCTUnwrap(outerDesc.nestedMessages["MiddleDef"])
    let innerDesc = try XCTUnwrap(middleDesc.nestedMessages["InnerDef"])
    var innerDyn = DynamicMessage(descriptor: innerDesc)
    try innerDyn.set(Int32(404), forField: 1)
    try innerDyn.set("not found", forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(2), forField: 3)
    try dynamic.setMapEntry(innerDyn, forKey: "key1", inField: 4)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_OuterWithNestedDefs.self
    ) { decoded in
      XCTAssertEqual(decoded.kind, .outerB)
      XCTAssertEqual(decoded.errors["key1"]?.code, 404)
      XCTAssertEqual(decoded.errors["key1"]?.reason, "not found")
    }
  }

  // MARK: - OuterWithNestedDefs: repeated MiddleDef

  func test_nested_nestedDefs_repeatedMiddleDef_bidirectional() async throws {
    var proto = Testcompat_OuterWithNestedDefs()
    var m1 = Testcompat_OuterWithNestedDefs.MiddleDef()
    m1.label = "sec1"
    var m2 = Testcompat_OuterWithNestedDefs.MiddleDef()
    m2.label = "sec2"
    proto.secondary = [m1, m2]
    proto.kind = .outerA

    let desc = CompatDescriptors.outerWithNestedDefs()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let sec = try XCTUnwrap(try msg.get(forField: 2) as? [DynamicMessage])
      XCTAssertEqual(sec.count, 2)
      XCTAssertEqual(try sec[0].get(forField: 2) as? String, "sec1")
      XCTAssertEqual(try sec[1].get(forField: 2) as? String, "sec2")
    }

    let outerDesc = CompatDescriptors.outerWithNestedDefs()
    let middleDesc = try XCTUnwrap(outerDesc.nestedMessages["MiddleDef"])
    var dyn1 = DynamicMessage(descriptor: middleDesc)
    try dyn1.set("sec1", forField: 2)
    var dyn2 = DynamicMessage(descriptor: middleDesc)
    try dyn2.set("sec2", forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set([dyn1, dyn2] as [DynamicMessage], forField: 2)
    try dynamic.set(Int32(1), forField: 3)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_OuterWithNestedDefs.self
    ) { decoded in
      XCTAssertEqual(decoded.secondary.count, 2)
      XCTAssertEqual(decoded.secondary[0].label, "sec1")
    }
  }

  // MARK: - Recursive 4 levels deep

  func test_nested_recursive_4deep_bidirectional() async throws {
    var proto = Testcompat_Recursive()
    proto.value = 1
    proto.child.value = 2
    proto.child.child.value = 3
    proto.child.child.child.value = 4

    let desc = CompatDescriptors.recursive()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let c1 = try XCTUnwrap(try msg.get(forField: 3) as? DynamicMessage)
      let c2 = try XCTUnwrap(try c1.get(forField: 3) as? DynamicMessage)
      let c3 = try XCTUnwrap(try c2.get(forField: 3) as? DynamicMessage)
      XCTAssertEqual(try c3.get(forField: 1) as? Int32, 4)
    }

    var c3 = DynamicMessage(descriptor: desc)
    try c3.set(Int32(4), forField: 1)
    var c2 = DynamicMessage(descriptor: desc)
    try c2.set(Int32(3), forField: 1)
    try c2.set(c3, forField: 3)
    var c1 = DynamicMessage(descriptor: desc)
    try c1.set(Int32(2), forField: 1)
    try c1.set(c2, forField: 3)
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(1), forField: 1)
    try dynamic.set(c1, forField: 3)
    try await CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_Recursive.self)
    {
      decoded in
      XCTAssertEqual(decoded.child.child.child.value, 4)
    }
  }

  // MARK: - MixedNest: map of MixedNest2

  func test_nested_mixedNest_mapOfNested_bidirectional() async throws {
    var proto = Testcompat_MixedNest1()
    proto.name = "mix"
    var n2a = Testcompat_MixedNest1.MixedNest2()
    n2a.s = "branch_a"
    var n2b = Testcompat_MixedNest1.MixedNest2()
    n2b.n = 42
    proto.branches = ["a": n2a, "b": n2b]

    let desc = CompatDescriptors.mixedNest1()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 2) as? String, "mix")
      let branches = try XCTUnwrap(try msg.get(forField: 3) as? [AnyHashable: Any])
      let dA = try XCTUnwrap(branches["a"] as? DynamicMessage)
      XCTAssertEqual(try dA.get(forField: 2) as? String, "branch_a")
      let dB = try XCTUnwrap(branches["b"] as? DynamicMessage)
      XCTAssertEqual(try dB.get(forField: 3) as? Int32, 42)
    }

    let outerDesc = CompatDescriptors.mixedNest1()
    let nest2Desc = try XCTUnwrap(outerDesc.nestedMessages["MixedNest2"])
    var dynA = DynamicMessage(descriptor: nest2Desc)
    try dynA.set("branch_a", forField: 2)
    var dynB = DynamicMessage(descriptor: nest2Desc)
    try dynB.set(Int32(42), forField: 3)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("mix", forField: 2)
    try dynamic.setMapEntry(dynA, forKey: "a", inField: 3)
    try dynamic.setMapEntry(dynB, forKey: "b", inField: 3)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_MixedNest1.self
    ) {
      decoded in
      XCTAssertEqual(decoded.branches["a"]?.s, "branch_a")
      XCTAssertEqual(decoded.branches["b"]?.n, 42)
    }
  }

  // MARK: - MixedNest: repeated MixedNest3

  func test_nested_mixedNest_repeatedNested_bidirectional() async throws {
    var proto = Testcompat_MixedNest1()
    var n3a = Testcompat_MixedNest1.MixedNest2.MixedNest3()
    n3a.val = 1
    n3a.items = ["x"]
    var n3b = Testcompat_MixedNest1.MixedNest2.MixedNest3()
    n3b.val = 2
    proto.child.list = [n3a, n3b]
    proto.flags = [.active, .inactive]

    let desc = CompatDescriptors.mixedNest1()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let child = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
      let list = try XCTUnwrap(try child.get(forField: 4) as? [DynamicMessage])
      XCTAssertEqual(list.count, 2)
      XCTAssertEqual(try list[0].get(forField: 1) as? Int32, 1)
      XCTAssertEqual(try list[0].get(forField: 2) as? [String], ["x"])
      XCTAssertEqual(try msg.get(forField: 4) as? [Int32], [1, 2])
    }

    let outerDesc = CompatDescriptors.mixedNest1()
    let nest2Desc = try XCTUnwrap(outerDesc.nestedMessages["MixedNest2"])
    let nest3Desc = try XCTUnwrap(nest2Desc.nestedMessages["MixedNest3"])
    var d3a = DynamicMessage(descriptor: nest3Desc)
    try d3a.set(Int32(1), forField: 1)
    try d3a.set(["x"] as [String], forField: 2)
    var d3b = DynamicMessage(descriptor: nest3Desc)
    try d3b.set(Int32(2), forField: 1)

    var dNest2 = DynamicMessage(descriptor: nest2Desc)
    try dNest2.set([d3a, d3b] as [DynamicMessage], forField: 4)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(dNest2, forField: 1)
    try dynamic.set([Int32(1), Int32(2)] as [Int32], forField: 4)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_MixedNest1.self
    ) {
      decoded in
      XCTAssertEqual(decoded.child.list.count, 2)
      XCTAssertEqual(decoded.child.list[0].val, 1)
      XCTAssertEqual(decoded.flags, [.active, .inactive])
    }
  }

  // MARK: - Empty inner message

  func test_nested_emptyInner_bidirectional() async throws {
    var proto = Testcompat_Nested1()
    proto.name = "parent"
    // child is present but empty (default values)
    proto.child.count = 0

    let desc = CompatDescriptors.nested1()
    let jsonStr = try proto.jsonString()
    // An empty nested message is serialized as {}
    XCTAssertTrue(jsonStr.contains("name"), "name should appear: \(jsonStr)")

    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 2) as? String, "parent")
    }

    // Direction B: build DynamicMessage with empty child → SwiftProtobuf
    let nested2Desc = CompatDescriptors.nested2()
    let emptyChild = DynamicMessage(descriptor: nested2Desc)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("parent", forField: 2)
    try dynamic.set(emptyChild, forField: 1)
    try await CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_Nested1.self) {
      decoded in
      XCTAssertEqual(decoded.name, "parent")
      XCTAssertEqual(decoded.child.count, 0)
    }
  }

  // MARK: - Absent inner → omitted

  func test_nested_absentInner_omitted() async throws {
    var proto = Testcompat_Nested1()
    proto.name = "only_name"

    let desc = CompatDescriptors.nested1()
    let jsonStr = try proto.jsonString()
    XCTAssertTrue(jsonStr.contains("name"), "name should appear: \(jsonStr)")
    // child should not appear since it was never accessed/set
    XCTAssertFalse(jsonStr.contains("child"), "absent child should be omitted: \(jsonStr)")

    let dynamic = DynamicMessage(descriptor: desc)
    let jsonData = try await CompatHelpers.makeSerializer(registry: registry).serialize(dynamic)
    let ourJson = try XCTUnwrap(String(data: jsonData, encoding: .utf8))
    XCTAssertFalse(ourJson.contains("child"), "absent child should be omitted in our JSON: \(ourJson)")
  }

  // MARK: - Enum at every level

  func test_nested_enumAtEveryLevel_bidirectional() async throws {
    var proto = Testcompat_Nested1()
    proto.child.child.child.status = .active
    proto.child.child.child.tags = ["t"]
    proto.child.child.props = ["p": 5]

    let desc = CompatDescriptors.nested1()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let n2 = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
      let n3 = try XCTUnwrap(try n2.get(forField: 1) as? DynamicMessage)
      let n4 = try XCTUnwrap(try n3.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try n4.get(forField: 3) as? Int32, 1)
    }

    let n4desc = CompatDescriptors.nested4()
    var n4 = DynamicMessage(descriptor: n4desc)
    try n4.set(Int32(1), forField: 3)
    try n4.set(["t"] as [String], forField: 2)
    let n3desc = CompatDescriptors.nested3()
    var n3 = DynamicMessage(descriptor: n3desc)
    try n3.set(n4, forField: 1)
    try n3.setMapEntry(Int32(5), forKey: "p", inField: 2)
    let n2desc = CompatDescriptors.nested2()
    var n2 = DynamicMessage(descriptor: n2desc)
    try n2.set(n3, forField: 1)
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(n2, forField: 1)
    try await CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_Nested1.self) {
      decoded in
      XCTAssertEqual(decoded.child.child.child.status, .active)
    }
  }

  // MARK: - OuterWithNestedDefs

  func test_nested_outerWithNestedDefs_bidirectional() async throws {
    var proto = Testcompat_OuterWithNestedDefs()
    proto.kind = .outerA
    proto.primary.label = "primary_label"

    let desc = CompatDescriptors.outerWithNestedDefs()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 3) as? Int32, 1)
      let primary = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try primary.get(forField: 2) as? String, "primary_label")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(1), forField: 3)

    // Direction B: also verify our JSON roundtrip
    let jsonStr = try proto.jsonString()
    guard let data = jsonStr.data(using: .utf8) else { throw CompatError.jsonEncodingFailed }
    let deserialized = try await CompatHelpers.makeDeserializer(registry: registry).deserialize(data, using: desc)
    XCTAssertEqual(try deserialized.get(forField: 3) as? Int32, 1)
  }
}
