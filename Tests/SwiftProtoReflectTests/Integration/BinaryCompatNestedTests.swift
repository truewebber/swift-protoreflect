// BinaryCompatNestedTests.swift
// SwiftProtoReflectTests
//
// Group: Nested Messages — bidirectional binary compatibility tests.
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
//   - Nested messages use wire type 2 (LEN), tag = (fieldNumber << 3) | 2.
//   - Empty explicitly-set message: tag + 0x00 (2 bytes).
//   - Absent message field: no bytes at all.
//   - Map fields: byte-for-byte comparison is unreliable due to non-deterministic iteration order.
//     Use round-trip-then-compare-values pattern for all map-containing tests.

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class BinaryCompatNestedTests: XCTestCase {

  private var registry: TypeRegistry!

  override func setUp() async throws {
    try await super.setUp()
    registry = try? await CompatDescriptors.fullRegistry()
  }

  override func tearDown() async throws {
    registry = nil
    try await super.tearDown()
  }

  // MARK: - 1. 1-level nesting (Nested1 → Nested2)

  func test_nested_1level_bidirectional() async throws {
    var proto = Testcompat_Nested1()
    proto.name = "level1"
    proto.child.count = 10

    let desc = CompatDescriptors.nested1()
    let n2desc = CompatDescriptors.nested2()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 2) as? String, "level1")
        let child = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
        XCTAssertEqual(try child.get(forField: 2) as? Int32, 10)
      },
      buildDynamic: {
        var n2 = DynamicMessage(descriptor: n2desc)
        try n2.set(Int32(10), forField: 2)
        var d = DynamicMessage(descriptor: desc)
        try d.set("level1", forField: 2)
        try d.set(n2, forField: 1)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.name, "level1")
        XCTAssertEqual(p.child.count, 10)
      }
    )
  }

  // MARK: - 2. 2-level nesting (Nested1 → Nested2 → Nested3)

  func test_nested_2levels_bidirectional() async throws {
    var proto = Testcompat_Nested1()
    proto.name = "level1"
    proto.child.count = 5
    proto.child.child.flag = true
    proto.child.child.props = ["key": 99]

    let desc = CompatDescriptors.nested1()
    let n2desc = CompatDescriptors.nested2()
    let n3desc = CompatDescriptors.nested3()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let n2 = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
        XCTAssertEqual(try n2.get(forField: 2) as? Int32, 5)
        let n3 = try XCTUnwrap(try n2.get(forField: 1) as? DynamicMessage)
        XCTAssertEqual(try n3.get(forField: 3) as? Bool, true)
        let props = try XCTUnwrap(try n3.get(forField: 2) as? [AnyHashable: Any])
        XCTAssertEqual(props["key"] as? Int32, 99)
      },
      buildDynamic: {
        var n3 = DynamicMessage(descriptor: n3desc)
        try n3.set(true, forField: 3)
        try n3.setMapEntry(Int32(99), forKey: "key", inField: 2)

        var n2 = DynamicMessage(descriptor: n2desc)
        try n2.set(Int32(5), forField: 2)
        try n2.set(n3, forField: 1)

        var d = DynamicMessage(descriptor: desc)
        try d.set("level1", forField: 2)
        try d.set(n2, forField: 1)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.child.count, 5)
        XCTAssertTrue(p.child.child.flag)
        XCTAssertEqual(p.child.child.props["key"], 99)
      }
    )
  }

  // MARK: - 3. 3-level nesting (Nested1 → Nested2 → Nested3 → Nested4)

  func test_nested_3levels_bidirectional() async throws {
    var proto = Testcompat_Nested1()
    proto.name = "top"
    proto.child.count = 3
    proto.child.child.flag = false
    proto.child.child.child.value = 777
    proto.child.child.child.tags = ["a", "b"]

    let desc = CompatDescriptors.nested1()
    let n2desc = CompatDescriptors.nested2()
    let n3desc = CompatDescriptors.nested3()
    let n4desc = CompatDescriptors.nested4()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let n2 = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
        let n3 = try XCTUnwrap(try n2.get(forField: 1) as? DynamicMessage)
        let n4 = try XCTUnwrap(try n3.get(forField: 1) as? DynamicMessage)
        XCTAssertEqual(try n4.get(forField: 1) as? Int32, 777)
        XCTAssertEqual(try n4.get(forField: 2) as? [String], ["a", "b"])
      },
      buildDynamic: {
        var n4 = DynamicMessage(descriptor: n4desc)
        try n4.set(Int32(777), forField: 1)
        try n4.set(["a", "b"] as [String], forField: 2)

        var n3 = DynamicMessage(descriptor: n3desc)
        try n3.set(n4, forField: 1)

        var n2 = DynamicMessage(descriptor: n2desc)
        try n2.set(Int32(3), forField: 2)
        try n2.set(n3, forField: 1)

        var d = DynamicMessage(descriptor: desc)
        try d.set("top", forField: 2)
        try d.set(n2, forField: 1)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.child.child.child.value, 777)
        XCTAssertEqual(p.child.child.child.tags, ["a", "b"])
      }
    )
  }

  // MARK: - 4. Nested1 with repeated siblings (two Nested2 messages)

  func test_nested_siblings_bidirectional() async throws {
    var proto = Testcompat_Nested1()
    proto.name = "parent"
    var s1 = Testcompat_Nested2()
    s1.count = 1
    var s2 = Testcompat_Nested2()
    s2.count = 2
    proto.siblings = [s1, s2]

    let desc = CompatDescriptors.nested1()
    let n2desc = CompatDescriptors.nested2()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let siblings = try XCTUnwrap(try msg.get(forField: 3) as? [DynamicMessage])
        XCTAssertEqual(siblings.count, 2)
        XCTAssertEqual(try siblings[0].get(forField: 2) as? Int32, 1)
        XCTAssertEqual(try siblings[1].get(forField: 2) as? Int32, 2)
      },
      buildDynamic: {
        var sib1 = DynamicMessage(descriptor: n2desc)
        try sib1.set(Int32(1), forField: 2)
        var sib2 = DynamicMessage(descriptor: n2desc)
        try sib2.set(Int32(2), forField: 2)

        var d = DynamicMessage(descriptor: desc)
        try d.set("parent", forField: 2)
        try d.set([sib1, sib2] as [DynamicMessage], forField: 3)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.siblings.count, 2)
        XCTAssertEqual(p.siblings[0].count, 1)
        XCTAssertEqual(p.siblings[1].count, 2)
      }
    )
  }

  // MARK: - 5. Nested2 with oneof text variant alongside count

  func test_nested_nested2_oneofText_bidirectional() async throws {
    var proto = Testcompat_Nested2()
    proto.count = 5
    proto.text = "chosen"

    let desc = CompatDescriptors.nested2()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 2) as? Int32, 5)
        XCTAssertEqual(try msg.get(forField: 3) as? String, "chosen")
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(5), forField: 2)
        try d.set("chosen", forField: 3)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.count, 5)
        if case .text(let v) = p.variant {
          XCTAssertEqual(v, "chosen")
        }
        else {
          XCTFail("expected text variant")
        }
      }
    )
  }

  // MARK: - 6. Recursive: root (value=1) with single child (value=2)

  func test_nested_recursive_shallow_bidirectional() async throws {
    var proto = Testcompat_Recursive()
    proto.value = 1
    proto.label = "root"
    proto.child.value = 2
    proto.child.label = "child"

    let desc = CompatDescriptors.recursive()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? Int32, 1)
        XCTAssertEqual(try msg.get(forField: 2) as? String, "root")
        let child = try XCTUnwrap(try msg.get(forField: 3) as? DynamicMessage)
        XCTAssertEqual(try child.get(forField: 1) as? Int32, 2)
        XCTAssertEqual(try child.get(forField: 2) as? String, "child")
      },
      buildDynamic: {
        var childDyn = DynamicMessage(descriptor: desc)
        try childDyn.set(Int32(2), forField: 1)
        try childDyn.set("child", forField: 2)

        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(1), forField: 1)
        try d.set("root", forField: 2)
        try d.set(childDyn, forField: 3)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.value, 1)
        XCTAssertEqual(p.label, "root")
        XCTAssertEqual(p.child.value, 2)
        XCTAssertEqual(p.child.label, "child")
      }
    )
  }

  // MARK: - 7. Recursive with repeated children list (value=10, value=20)

  func test_nested_recursive_withChildren_bidirectional() async throws {
    var proto = Testcompat_Recursive()
    proto.value = 5
    var c1 = Testcompat_Recursive()
    c1.value = 10
    var c2 = Testcompat_Recursive()
    c2.value = 20
    proto.children = [c1, c2]

    let desc = CompatDescriptors.recursive()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? Int32, 5)
        let children = try XCTUnwrap(try msg.get(forField: 4) as? [DynamicMessage])
        XCTAssertEqual(children.count, 2)
        XCTAssertEqual(try children[0].get(forField: 1) as? Int32, 10)
        XCTAssertEqual(try children[1].get(forField: 1) as? Int32, 20)
      },
      buildDynamic: {
        var ch1 = DynamicMessage(descriptor: desc)
        try ch1.set(Int32(10), forField: 1)
        var ch2 = DynamicMessage(descriptor: desc)
        try ch2.set(Int32(20), forField: 1)

        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(5), forField: 1)
        try d.set([ch1, ch2] as [DynamicMessage], forField: 4)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.children.count, 2)
        XCTAssertEqual(p.children[0].value, 10)
        XCTAssertEqual(p.children[1].value, 20)
      }
    )
  }

  // MARK: - 8. 4-level fully populated (Nested1 → Nested2 → Nested3 → Nested4)

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
    let n2desc = CompatDescriptors.nested2()
    let n3desc = CompatDescriptors.nested3()
    let n4desc = CompatDescriptors.nested4()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
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
      },
      buildDynamic: {
        var n4 = DynamicMessage(descriptor: n4desc)
        try n4.set(Int32(99), forField: 1)
        try n4.set(["x", "y"] as [String], forField: 2)
        try n4.set(Int32(1), forField: 3)

        var n3 = DynamicMessage(descriptor: n3desc)
        try n3.set(true, forField: 3)
        try n3.setMapEntry(Int32(1), forKey: "a", inField: 2)
        try n3.setMapEntry(Int32(2), forKey: "b", inField: 2)
        try n3.set(n4, forField: 1)

        var n2 = DynamicMessage(descriptor: n2desc)
        try n2.set(Int32(3), forField: 2)
        try n2.set("chosen", forField: 3)
        try n2.set(n3, forField: 1)

        var sib1 = DynamicMessage(descriptor: n2desc)
        try sib1.set(Int32(10), forField: 2)

        var d = DynamicMessage(descriptor: desc)
        try d.set("root", forField: 2)
        try d.set(n2, forField: 1)
        try d.set([sib1] as [DynamicMessage], forField: 3)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.name, "root")
        XCTAssertEqual(p.child.count, 3)
        XCTAssertEqual(p.child.child.child.value, 99)
        XCTAssertEqual(p.siblings.count, 1)
      }
    )
  }

  // MARK: - 9. OuterWithNestedDefs: map<string, MiddleDef.InnerDef>

  func test_nested_nestedDefs_mapWithInnerDef_bidirectional() async throws {
    var proto = Testcompat_OuterWithNestedDefs()
    proto.kind = .outerB
    var innerDef = Testcompat_OuterWithNestedDefs.MiddleDef.InnerDef()
    innerDef.code = 404
    innerDef.reason = "not found"
    proto.errors = ["key1": innerDef]

    let desc = CompatDescriptors.outerWithNestedDefs()
    let middleDesc = try XCTUnwrap(desc.nestedMessages["MiddleDef"])
    let innerDesc = try XCTUnwrap(middleDesc.nestedMessages["InnerDef"])

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 3) as? Int32, 2)
        let errors = try XCTUnwrap(try msg.get(forField: 4) as? [AnyHashable: Any])
        let innerDyn = try XCTUnwrap(errors["key1"] as? DynamicMessage)
        XCTAssertEqual(try innerDyn.get(forField: 1) as? Int32, 404)
        XCTAssertEqual(try innerDyn.get(forField: 2) as? String, "not found")
      },
      buildDynamic: {
        var innerDyn = DynamicMessage(descriptor: innerDesc)
        try innerDyn.set(Int32(404), forField: 1)
        try innerDyn.set("not found", forField: 2)

        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(2), forField: 3)
        try d.setMapEntry(innerDyn, forKey: "key1", inField: 4)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.kind, .outerB)
        XCTAssertEqual(p.errors["key1"]?.code, 404)
        XCTAssertEqual(p.errors["key1"]?.reason, "not found")
      }
    )
  }

  // MARK: - 10. OuterWithNestedDefs: repeated MiddleDef messages

  func test_nested_nestedDefs_repeatedMiddleDef_bidirectional() async throws {
    var proto = Testcompat_OuterWithNestedDefs()
    var m1 = Testcompat_OuterWithNestedDefs.MiddleDef()
    m1.label = "sec1"
    var m2 = Testcompat_OuterWithNestedDefs.MiddleDef()
    m2.label = "sec2"
    proto.secondary = [m1, m2]
    proto.kind = .outerA

    let desc = CompatDescriptors.outerWithNestedDefs()
    let middleDesc = try XCTUnwrap(desc.nestedMessages["MiddleDef"])

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let sec = try XCTUnwrap(try msg.get(forField: 2) as? [DynamicMessage])
        XCTAssertEqual(sec.count, 2)
        XCTAssertEqual(try sec[0].get(forField: 2) as? String, "sec1")
        XCTAssertEqual(try sec[1].get(forField: 2) as? String, "sec2")
      },
      buildDynamic: {
        var dyn1 = DynamicMessage(descriptor: middleDesc)
        try dyn1.set("sec1", forField: 2)
        var dyn2 = DynamicMessage(descriptor: middleDesc)
        try dyn2.set("sec2", forField: 2)

        var d = DynamicMessage(descriptor: desc)
        try d.set([dyn1, dyn2] as [DynamicMessage], forField: 2)
        try d.set(Int32(1), forField: 3)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.secondary.count, 2)
        XCTAssertEqual(p.secondary[0].label, "sec1")
        XCTAssertEqual(p.secondary[1].label, "sec2")
      }
    )
  }

  // MARK: - 11. Recursive 4 levels deep (value 1→2→3→4)

  func test_nested_recursive_4deep_bidirectional() async throws {
    var proto = Testcompat_Recursive()
    proto.value = 1
    proto.child.value = 2
    proto.child.child.value = 3
    proto.child.child.child.value = 4

    let desc = CompatDescriptors.recursive()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? Int32, 1)
        let c1 = try XCTUnwrap(try msg.get(forField: 3) as? DynamicMessage)
        XCTAssertEqual(try c1.get(forField: 1) as? Int32, 2)
        let c2 = try XCTUnwrap(try c1.get(forField: 3) as? DynamicMessage)
        XCTAssertEqual(try c2.get(forField: 1) as? Int32, 3)
        let c3 = try XCTUnwrap(try c2.get(forField: 3) as? DynamicMessage)
        XCTAssertEqual(try c3.get(forField: 1) as? Int32, 4)
      },
      buildDynamic: {
        var c3 = DynamicMessage(descriptor: desc)
        try c3.set(Int32(4), forField: 1)
        var c2 = DynamicMessage(descriptor: desc)
        try c2.set(Int32(3), forField: 1)
        try c2.set(c3, forField: 3)
        var c1 = DynamicMessage(descriptor: desc)
        try c1.set(Int32(2), forField: 1)
        try c1.set(c2, forField: 3)
        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(1), forField: 1)
        try d.set(c1, forField: 3)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.value, 1)
        XCTAssertEqual(p.child.value, 2)
        XCTAssertEqual(p.child.child.value, 3)
        XCTAssertEqual(p.child.child.child.value, 4)
      }
    )
  }

  // MARK: - 12. MixedNest1: map<string, MixedNest2>

  func test_nested_mixedNest_mapOfNested_bidirectional() async throws {
    var proto = Testcompat_MixedNest1()
    proto.name = "mix"
    var n2a = Testcompat_MixedNest1.MixedNest2()
    n2a.s = "branch_a"
    var n2b = Testcompat_MixedNest1.MixedNest2()
    n2b.n = 42
    proto.branches = ["a": n2a, "b": n2b]

    let desc = CompatDescriptors.mixedNest1()
    let nest2Desc = try XCTUnwrap(desc.nestedMessages["MixedNest2"])

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 2) as? String, "mix")
        let branches = try XCTUnwrap(try msg.get(forField: 3) as? [AnyHashable: Any])
        let dA = try XCTUnwrap(branches["a"] as? DynamicMessage)
        XCTAssertEqual(try dA.get(forField: 2) as? String, "branch_a")
        let dB = try XCTUnwrap(branches["b"] as? DynamicMessage)
        XCTAssertEqual(try dB.get(forField: 3) as? Int32, 42)
      },
      buildDynamic: {
        var dynA = DynamicMessage(descriptor: nest2Desc)
        try dynA.set("branch_a", forField: 2)
        var dynB = DynamicMessage(descriptor: nest2Desc)
        try dynB.set(Int32(42), forField: 3)

        var d = DynamicMessage(descriptor: desc)
        try d.set("mix", forField: 2)
        try d.setMapEntry(dynA, forKey: "a", inField: 3)
        try d.setMapEntry(dynB, forKey: "b", inField: 3)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.branches["a"]?.s, "branch_a")
        XCTAssertEqual(p.branches["b"]?.n, 42)
      }
    )
  }

  // MARK: - 13. MixedNest1: child.list (repeated MixedNest3) + flags (repeated enum)

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
    let nest2Desc = try XCTUnwrap(desc.nestedMessages["MixedNest2"])
    let nest3Desc = try XCTUnwrap(nest2Desc.nestedMessages["MixedNest3"])

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let child = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
        let list = try XCTUnwrap(try child.get(forField: 4) as? [DynamicMessage])
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(try list[0].get(forField: 1) as? Int32, 1)
        XCTAssertEqual(try list[0].get(forField: 2) as? [String], ["x"])
        XCTAssertEqual(try msg.get(forField: 4) as? [Int32], [1, 2])
      },
      buildDynamic: {
        var d3a = DynamicMessage(descriptor: nest3Desc)
        try d3a.set(Int32(1), forField: 1)
        try d3a.set(["x"] as [String], forField: 2)
        var d3b = DynamicMessage(descriptor: nest3Desc)
        try d3b.set(Int32(2), forField: 1)

        var dNest2 = DynamicMessage(descriptor: nest2Desc)
        try dNest2.set([d3a, d3b] as [DynamicMessage], forField: 4)

        var d = DynamicMessage(descriptor: desc)
        try d.set(dNest2, forField: 1)
        try d.set([Int32(1), Int32(2)] as [Int32], forField: 4)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.child.list.count, 2)
        XCTAssertEqual(p.child.list[0].val, 1)
        XCTAssertEqual(p.flags, [.active, .inactive])
      }
    )
  }

  // MARK: - 14. Empty explicitly-set Nested2 child (bidirectional)

  func test_nested_emptyInner_bidirectional() async throws {
    // proto.child.count = 0 causes swift-protobuf to treat child as explicitly present
    // (hasChild == true), so it is serialized as field 1 tag + 0x00 (empty body).
    var proto = Testcompat_Nested1()
    proto.name = "parent"
    proto.child.count = 0

    let desc = CompatDescriptors.nested1()
    let n2desc = CompatDescriptors.nested2()
    let serializer = BinaryCompatHelpers.makeSerializer()

    // Direction A: oracle serializes (includes child tag + 0x00), we deserialize.
    let refData = try proto.serializedData()
    // The reference bytes must contain the child field tag 0x0A.
    XCTAssertTrue(refData.contains(0x0A), "oracle must include child tag 0x0A for explicitly-set empty child")

    let dynamic = try await BinaryCompatHelpers.makeDeserializer(registry: registry)
      .deserialize(refData, using: desc)
    XCTAssertEqual(try dynamic.get(forField: 2) as? String, "parent")

    // Direction B: set an empty DynamicMessage child, serialize, oracle parses.
    let emptyChild = DynamicMessage(descriptor: n2desc)
    var ourMsg = DynamicMessage(descriptor: desc)
    try ourMsg.set("parent", forField: 2)
    try ourMsg.set(emptyChild, forField: 1)

    let ourData = try await serializer.serialize(ourMsg)
    XCTAssertTrue(
      ourData.contains(0x0A),
      "BinarySerializer must include child tag 0x0A for explicitly-set empty child"
    )

    let decoded = try Testcompat_Nested1(serializedBytes: ourData)
    XCTAssertEqual(decoded.name, "parent")
    XCTAssertTrue(decoded.hasChild, "explicitly-set empty child must have presence in oracle")
  }

  // MARK: - 15. Absent Nested2 child produces no wire bytes for field 1

  func test_nested_absentInner_producesNoWireBytes() async throws {
    let desc = CompatDescriptors.nested1()
    let serializer = BinaryCompatHelpers.makeSerializer()

    // Oracle: only name set, no child.
    var proto = Testcompat_Nested1()
    proto.name = "only_name"
    let refData = try proto.serializedData()
    XCTAssertFalse(
      refData.contains(0x0A),
      "oracle must omit child tag 0x0A when child is absent"
    )

    // Ours: only name field, no child set.
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("only_name", forField: 2)
    let ourData = try await serializer.serialize(dynamic)
    XCTAssertFalse(
      ourData.contains(0x0A),
      "BinarySerializer must omit field 1 (child) tag when child is absent"
    )
  }

  // MARK: - 16. Status enum at Nested4 level through all 4 levels

  func test_nested_enumAtEveryLevel_bidirectional() async throws {
    var proto = Testcompat_Nested1()
    proto.child.child.child.status = .active
    proto.child.child.child.tags = ["t"]
    proto.child.child.props = ["p": 5]

    let desc = CompatDescriptors.nested1()
    let n2desc = CompatDescriptors.nested2()
    let n3desc = CompatDescriptors.nested3()
    let n4desc = CompatDescriptors.nested4()

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let n2 = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
        let n3 = try XCTUnwrap(try n2.get(forField: 1) as? DynamicMessage)
        let n4 = try XCTUnwrap(try n3.get(forField: 1) as? DynamicMessage)
        XCTAssertEqual(try n4.get(forField: 3) as? Int32, 1)
        XCTAssertEqual(try n4.get(forField: 2) as? [String], ["t"])
      },
      buildDynamic: {
        var n4 = DynamicMessage(descriptor: n4desc)
        try n4.set(Int32(1), forField: 3)
        try n4.set(["t"] as [String], forField: 2)

        var n3 = DynamicMessage(descriptor: n3desc)
        try n3.set(n4, forField: 1)
        try n3.setMapEntry(Int32(5), forKey: "p", inField: 2)

        var n2 = DynamicMessage(descriptor: n2desc)
        try n2.set(n3, forField: 1)

        var d = DynamicMessage(descriptor: desc)
        try d.set(n2, forField: 1)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.child.child.child.status, .active)
        XCTAssertEqual(p.child.child.child.tags, ["t"])
      }
    )
  }

  // MARK: - 17. OuterWithNestedDefs: kind enum + primary MiddleDef label

  func test_nested_outerWithNestedDefs_bidirectional() async throws {
    var proto = Testcompat_OuterWithNestedDefs()
    proto.kind = .outerA
    proto.primary.label = "primary_label"

    let desc = CompatDescriptors.outerWithNestedDefs()
    let middleDesc = try XCTUnwrap(desc.nestedMessages["MiddleDef"])

    try await BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 3) as? Int32, 1)
        let primary = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
        XCTAssertEqual(try primary.get(forField: 2) as? String, "primary_label")
      },
      buildDynamic: {
        var primaryDyn = DynamicMessage(descriptor: middleDesc)
        try primaryDyn.set("primary_label", forField: 2)

        var d = DynamicMessage(descriptor: desc)
        try d.set(Int32(1), forField: 3)
        try d.set(primaryDyn, forField: 1)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.kind, .outerA)
        XCTAssertEqual(p.primary.label, "primary_label")
      }
    )
  }

  // MARK: - 18. Nested message field uses wire type 2: first tag byte is 0x0A

  func test_nested_messageField_wireType2_exactTag() async throws {
    // field 1 = child (Nested2), wire type 2 (LEN): tag = (1 << 3) | 2 = 0x0A
    let desc = CompatDescriptors.nested1()
    let n2desc = CompatDescriptors.nested2()
    let serializer = BinaryCompatHelpers.makeSerializer()

    var n2 = DynamicMessage(descriptor: n2desc)
    try n2.set(Int32(7), forField: 2)

    // Only set the child field (no name) so child is the first field in the output.
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(n2, forField: 1)

    let data = try await serializer.serialize(dynamic)
    XCTAssertFalse(data.isEmpty, "serialized data must not be empty when child is set")
    XCTAssertEqual(
      data.first,
      0x0A,
      "first byte must be 0x0A (field 1, wire type 2) for nested message field"
    )
  }

  // MARK: - 19. Empty explicitly-set child ≠ absent child in wire bytes

  func test_nested_emptyVsAbsent_wireDistinction() async throws {
    // When only the child field is set (and it's empty), wire output = 0x0A 0x00 (2 bytes).
    // When nothing is set, wire output = empty Data.
    let desc = CompatDescriptors.nested1()
    let n2desc = CompatDescriptors.nested2()
    let serializer = BinaryCompatHelpers.makeSerializer()

    // Empty child explicitly set (no name, no other fields).
    let emptyChild = DynamicMessage(descriptor: n2desc)
    var withEmpty = DynamicMessage(descriptor: desc)
    try withEmpty.set(emptyChild, forField: 1)
    let emptyChildData = try await serializer.serialize(withEmpty)

    // Absent child (nothing set).
    let absent = DynamicMessage(descriptor: desc)
    let absentData = try await serializer.serialize(absent)

    XCTAssertEqual(absentData, Data(), "absent child must produce empty wire output")
    XCTAssertNotEqual(emptyChildData, absentData, "empty explicitly-set child must differ from absent child")
    XCTAssertEqual(
      emptyChildData,
      Data([0x0A, 0x00]),
      "explicitly-set empty child must produce exactly 0x0A 0x00 (tag + zero-length)"
    )
  }
}
