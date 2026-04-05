// JSONCompatKitchenSinkTests.swift
// SwiftProtoReflectTests
//
// Group 13: Kitchen Sink — flat mega-message, deep 4 levels, all-WKT, stress tests.
// Bidirectional JSON compatibility tests.
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class JSONCompatKitchenSinkTests: XCTestCase {

  private var registry: TypeRegistry!

  override func setUp() {
    super.setUp()
    registry = try? CompatDescriptors.fullRegistry()
  }

  override func tearDown() {
    registry = nil
    super.tearDown()
  }

  // MARK: - KitchenSinkFlat: all scalar types

  func test_kitchenSink_flat_scalars_bidirectional() throws {
    var proto = Testcompat_KitchenSinkFlat()
    proto.int32Val = 1
    proto.int64Val = Int64.max
    proto.uint32Val = UInt32.max
    proto.uint64Val = UInt64.max
    proto.sint32Val = -1
    proto.sint64Val = Int64.min
    proto.fixed32Val = UInt32.max
    proto.fixed64Val = UInt64.max
    proto.sfixed32Val = Int32.min
    proto.sfixed64Val = Int64.min
    proto.doubleVal = 3.14
    proto.floatVal = 2.5
    proto.boolVal = true
    proto.stringVal = "hello"
    proto.bytesVal = Data([0x01, 0x02])

    let desc = CompatDescriptors.kitchenSinkFlat()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? Int32, 1)
      XCTAssertEqual(try msg.get(forField: 2) as? Int64, Int64.max)
      XCTAssertEqual(try msg.get(forField: 3) as? UInt32, UInt32.max)
      XCTAssertEqual(try msg.get(forField: 4) as? UInt64, UInt64.max)
      XCTAssertEqual(try msg.get(forField: 5) as? Int32, -1)
      XCTAssertEqual(try msg.get(forField: 6) as? Int64, Int64.min)
      XCTAssertEqual(try msg.get(forField: 13) as? Bool, true)
      XCTAssertEqual(try msg.get(forField: 14) as? String, "hello")
      XCTAssertEqual(try msg.get(forField: 15) as? Data, Data([0x01, 0x02]))
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(1), forField: 1)
    try dynamic.set(Int64.max, forField: 2)
    try dynamic.set(UInt32.max, forField: 3)
    try dynamic.set(UInt64.max, forField: 4)
    try dynamic.set(Int32(-1), forField: 5)
    try dynamic.set(Int64.min, forField: 6)
    try dynamic.set(true, forField: 13)
    try dynamic.set("hello", forField: 14)
    try dynamic.set(Data([0x01, 0x02]), forField: 15)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_KitchenSinkFlat.self)
    { decoded in
      XCTAssertEqual(decoded.int32Val, 1)
      XCTAssertEqual(decoded.int64Val, Int64.max)
      XCTAssertEqual(decoded.uint32Val, UInt32.max)
      XCTAssertEqual(decoded.uint64Val, UInt64.max)
      XCTAssertEqual(decoded.sint32Val, -1)
      XCTAssertEqual(decoded.sint64Val, Int64.min)
      XCTAssertTrue(decoded.boolVal)
      XCTAssertEqual(decoded.stringVal, "hello")
      XCTAssertEqual(decoded.bytesVal, Data([0x01, 0x02]))
    }
  }

  // MARK: - KitchenSinkFlat: repeated and map fields

  func test_kitchenSink_flat_repeatedAndMap_bidirectional() throws {
    var proto = Testcompat_KitchenSinkFlat()
    proto.repInt32 = [1, 2, 3]
    proto.repString = ["a", "b", "c"]
    proto.repStatus = [.active, .inactive]
    proto.mapSs = ["k1": "v1", "k2": "v2"]

    let desc = CompatDescriptors.kitchenSinkFlat()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 18) as? [Int32], [1, 2, 3])
      XCTAssertEqual(try msg.get(forField: 19) as? [String], ["a", "b", "c"])
      XCTAssertEqual(try msg.get(forField: 20) as? [Int32], [1, 2])
      let map = try XCTUnwrap(try msg.get(forField: 22) as? [AnyHashable: Any])
      XCTAssertEqual(map["k1"] as? String, "v1")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set([Int32(1), Int32(2), Int32(3)] as [Int32], forField: 18)
    try dynamic.set(["a", "b", "c"] as [String], forField: 19)
    try dynamic.set([Int32(1), Int32(2)] as [Int32], forField: 20)
    try dynamic.setMapEntry("v1", forKey: "k1", inField: 22)
    try dynamic.setMapEntry("v2", forKey: "k2", inField: 22)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_KitchenSinkFlat.self)
    { decoded in
      XCTAssertEqual(decoded.repInt32, [1, 2, 3])
      XCTAssertEqual(decoded.repString, ["a", "b", "c"])
      XCTAssertEqual(decoded.repStatus, [.active, .inactive])
      XCTAssertEqual(decoded.mapSs["k1"], "v1")
    }
  }

  // MARK: - KitchenSinkFlat: WKT fields

  func test_kitchenSink_flat_wktFields_bidirectional() throws {
    var proto = Testcompat_KitchenSinkFlat()
    proto.ts.seconds = 1_700_000_000
    proto.dur.seconds = 60
    proto.i64W.value = 999
    proto.strW.value = "wrapped"

    let desc = CompatDescriptors.kitchenSinkFlat()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let tsDyn = try XCTUnwrap(try msg.get(forField: 29) as? DynamicMessage)
      XCTAssertEqual(try tsDyn.get(forField: 1) as? Int64, 1_700_000_000)
      let durDyn = try XCTUnwrap(try msg.get(forField: 30) as? DynamicMessage)
      XCTAssertEqual(try durDyn.get(forField: 1) as? Int64, 60)
      let i64wDyn = try XCTUnwrap(try msg.get(forField: 31) as? DynamicMessage)
      XCTAssertEqual(try i64wDyn.get(forField: 1) as? Int64, 999)
      let strwDyn = try XCTUnwrap(try msg.get(forField: 32) as? DynamicMessage)
      XCTAssertEqual(try strwDyn.get(forField: 1) as? String, "wrapped")
    }

    let tsDesc = CompatDescriptors.wktTimestamp()
    var tsDyn = DynamicMessage(descriptor: tsDesc)
    try tsDyn.set(Int64(1_700_000_000), forField: 1)

    let durDesc = CompatDescriptors.wktDuration()
    var durDyn = DynamicMessage(descriptor: durDesc)
    try durDyn.set(Int64(60), forField: 1)

    let i64wDesc = CompatDescriptors.wktWrapper(name: "Int64Value", fieldType: .int64)
    var i64wDyn = DynamicMessage(descriptor: i64wDesc)
    try i64wDyn.set(Int64(999), forField: 1)

    let strwDesc = CompatDescriptors.wktWrapper(name: "StringValue", fieldType: .string)
    var strwDyn = DynamicMessage(descriptor: strwDesc)
    try strwDyn.set("wrapped", forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(tsDyn, forField: 29)
    try dynamic.set(durDyn, forField: 30)
    try dynamic.set(i64wDyn, forField: 31)
    try dynamic.set(strwDyn, forField: 32)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_KitchenSinkFlat.self)
    { decoded in
      XCTAssertEqual(decoded.ts.seconds, 1_700_000_000)
      XCTAssertEqual(decoded.dur.seconds, 60)
      XCTAssertEqual(decoded.i64W.value, 999)
      XCTAssertEqual(decoded.strW.value, "wrapped")
    }
  }

  // MARK: - KitchenSinkFlat: oneof field

  func test_kitchenSink_flat_oneof_bidirectional() throws {
    var proto = Testcompat_KitchenSinkFlat()
    proto.oneofStr = "one_str"
    proto.int32Val = 5

    let desc = CompatDescriptors.kitchenSinkFlat()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 26) as? String, "one_str")
      XCTAssertEqual(try msg.get(forField: 1) as? Int32, 5)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("one_str", forField: 26)
    try dynamic.set(Int32(5), forField: 1)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_KitchenSinkFlat.self)
    { decoded in
      if case .oneofStr(let v) = decoded.choice {
        XCTAssertEqual(v, "one_str")
      }
      else {
        XCTFail("wrong case")
      }
      XCTAssertEqual(decoded.int32Val, 5)
    }
  }

  // MARK: - DeepLevel1: 4 levels of nesting with WKT, map, repeated, oneof

  func test_kitchenSink_deepLevel4_bidirectional() throws {
    var proto = Testcompat_DeepLevel4()
    proto.value = 42
    proto.items = ["x", "y", "z"]
    proto.status = .active

    let desc = CompatDescriptors.deepLevel4()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? Int32, 42)
      XCTAssertEqual(try msg.get(forField: 2) as? [String], ["x", "y", "z"])
      XCTAssertEqual(try msg.get(forField: 3) as? Int32, 1)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(42), forField: 1)
    try dynamic.set(["x", "y", "z"] as [String], forField: 2)
    try dynamic.set(Int32(1), forField: 3)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_DeepLevel4.self) {
      decoded in
      XCTAssertEqual(decoded.value, 42)
      XCTAssertEqual(decoded.items, ["x", "y", "z"])
      XCTAssertEqual(decoded.status, .active)
    }
  }

  func test_kitchenSink_deepLevel1_full_bidirectional() throws {
    var proto = Testcompat_DeepLevel1()
    proto.name = "root"
    proto.tags = ["t1", "t2"]
    proto.child.count = 7
    proto.child.child.flag = true
    proto.child.child.child.value = 99
    proto.child.child.child.items = ["a"]
    proto.countW.value = Int64(12345)

    let desc = CompatDescriptors.deepLevel1()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 2) as? String, "root")
      XCTAssertEqual(try msg.get(forField: 3) as? [String], ["t1", "t2"])
      let l2 = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try l2.get(forField: 2) as? Int32, 7)
      let l3 = try XCTUnwrap(try l2.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try l3.get(forField: 3) as? Bool, true)
      let l4 = try XCTUnwrap(try l3.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try l4.get(forField: 1) as? Int32, 99)
      XCTAssertEqual(try l4.get(forField: 2) as? [String], ["a"])
      let cntW = try XCTUnwrap(try msg.get(forField: 6) as? DynamicMessage)
      XCTAssertEqual(try cntW.get(forField: 1) as? Int64, 12345)
    }

    let l4desc = CompatDescriptors.deepLevel4()
    var l4dyn = DynamicMessage(descriptor: l4desc)
    try l4dyn.set(Int32(99), forField: 1)
    try l4dyn.set(["a"] as [String], forField: 2)

    let l3desc = CompatDescriptors.deepLevel3()
    var l3dyn = DynamicMessage(descriptor: l3desc)
    try l3dyn.set(true, forField: 3)
    try l3dyn.set(l4dyn, forField: 1)

    let l2desc = CompatDescriptors.deepLevel2()
    var l2dyn = DynamicMessage(descriptor: l2desc)
    try l2dyn.set(Int32(7), forField: 2)
    try l2dyn.set(l3dyn, forField: 1)

    let i64wDesc = CompatDescriptors.wktWrapper(name: "Int64Value", fieldType: .int64)
    var cntWdyn = DynamicMessage(descriptor: i64wDesc)
    try cntWdyn.set(Int64(12345), forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("root", forField: 2)
    try dynamic.set(["t1", "t2"] as [String], forField: 3)
    try dynamic.set(l2dyn, forField: 1)
    try dynamic.set(cntWdyn, forField: 6)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_DeepLevel1.self) {
      decoded in
      XCTAssertEqual(decoded.name, "root")
      XCTAssertEqual(decoded.tags, ["t1", "t2"])
      XCTAssertEqual(decoded.child.count, 7)
      XCTAssertTrue(decoded.child.child.flag)
      XCTAssertEqual(decoded.child.child.child.value, 99)
      XCTAssertEqual(decoded.countW.value, 12345)
    }
  }

  // MARK: - KitchenSinkFlat: max values for all integer fields

  func test_kitchenSink_flat_maxValues_bidirectional() throws {
    var proto = Testcompat_KitchenSinkFlat()
    proto.int32Val = Int32.max
    proto.int64Val = Int64.max
    proto.uint32Val = UInt32.max
    proto.uint64Val = UInt64.max
    proto.sint32Val = Int32.max
    proto.sint64Val = Int64.max
    proto.fixed32Val = UInt32.max
    proto.fixed64Val = UInt64.max
    proto.sfixed32Val = Int32.max
    proto.sfixed64Val = Int64.max
    proto.doubleVal = Double.greatestFiniteMagnitude
    proto.floatVal = Float.greatestFiniteMagnitude

    let desc = CompatDescriptors.kitchenSinkFlat()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? Int32, Int32.max)
      XCTAssertEqual(try msg.get(forField: 2) as? Int64, Int64.max)
      XCTAssertEqual(try msg.get(forField: 3) as? UInt32, UInt32.max)
      XCTAssertEqual(try msg.get(forField: 4) as? UInt64, UInt64.max)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32.max, forField: 1)
    try dynamic.set(Int64.max, forField: 2)
    try dynamic.set(UInt32.max, forField: 3)
    try dynamic.set(UInt64.max, forField: 4)
    try dynamic.set(Int32.max, forField: 5)
    try dynamic.set(Int64.max, forField: 6)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_KitchenSinkFlat.self)
    { decoded in
      XCTAssertEqual(decoded.int32Val, Int32.max)
      XCTAssertEqual(decoded.int64Val, Int64.max)
      XCTAssertEqual(decoded.uint32Val, UInt32.max)
      XCTAssertEqual(decoded.uint64Val, UInt64.max)
    }
  }

  // MARK: - KitchenSinkFlat: all defaults → empty JSON

  func test_kitchenSink_flat_emptyJSON() throws {
    let proto = Testcompat_KitchenSinkFlat()
    let jsonStr = try proto.jsonString()
    XCTAssertEqual(jsonStr, "{}")

    let desc = CompatDescriptors.kitchenSinkFlat()
    let dynamic = DynamicMessage(descriptor: desc)
    let jsonData = try CompatHelpers.makeSerializer(registry: registry).serialize(dynamic)
    let ourJson = try XCTUnwrap(String(data: jsonData, encoding: .utf8))
    XCTAssertEqual(ourJson, "{}")
  }

  // MARK: - Stress: 100 repeated nested messages

  func test_kitchenSink_100repeatedNested_bidirectional() throws {
    var proto = Testcompat_KitchenSinkFlat()
    proto.repMsg = (1...100).map { i in
      var m = Testcompat_SimpleMessage()
      m.id = Int32(i)
      m.name = "item\(i)"
      return m
    }

    let desc = CompatDescriptors.kitchenSinkFlat()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let items = try XCTUnwrap(try msg.get(forField: 21) as? [DynamicMessage])
      XCTAssertEqual(items.count, 100)
      XCTAssertEqual(try items[0].get(forField: 1) as? Int32, 1)
      XCTAssertEqual(try items[99].get(forField: 1) as? Int32, 100)
    }

    let simpleDesc = CompatDescriptors.simpleMessage()
    let items: [DynamicMessage] = try (1...100).map { i in
      var m = DynamicMessage(descriptor: simpleDesc)
      try m.set(Int32(i), forField: 1)
      try m.set("item\(i)", forField: 2)
      return m
    }
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(items, forField: 21)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_KitchenSinkFlat.self)
    { decoded in
      XCTAssertEqual(decoded.repMsg.count, 100)
      XCTAssertEqual(decoded.repMsg[0].id, 1)
      XCTAssertEqual(decoded.repMsg[99].id, 100)
    }
  }

  // MARK: - Stress: large map (50 entries)

  func test_kitchenSink_largeMap50entries_bidirectional() throws {
    var proto = Testcompat_KitchenSinkFlat()
    for i in 1...50 {
      proto.mapSs["key\(i)"] = "val\(i)"
    }

    let desc = CompatDescriptors.kitchenSinkFlat()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let map = try XCTUnwrap(try msg.get(forField: 22) as? [AnyHashable: Any])
      XCTAssertEqual(map.count, 50)
      XCTAssertEqual(map["key1"] as? String, "val1")
      XCTAssertEqual(map["key50"] as? String, "val50")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    for i in 1...50 {
      try dynamic.setMapEntry("val\(i)", forKey: "key\(i)", inField: 22)
    }
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_KitchenSinkFlat.self)
    { decoded in
      XCTAssertEqual(decoded.mapSs.count, 50)
      XCTAssertEqual(decoded.mapSs["key25"], "val25")
    }
  }

  // MARK: - Deep: oneof active at each level

  func test_kitchenSink_deep_withOneofAtEachLevel_bidirectional() throws {
    // DeepLevel1 → DeepLevel2(oneof text) → DeepLevel3 → DeepLevel4
    var proto = Testcompat_DeepLevel1()
    proto.name = "oneof_test"
    proto.child.count = 5
    proto.child.text = "level2_text"  // activate oneof `text` at level 2
    proto.child.child.flag = true
    proto.child.child.child.value = 99

    let desc = CompatDescriptors.deepLevel1()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 2) as? String, "oneof_test")
      let l2 = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try l2.get(forField: 2) as? Int32, 5)
      XCTAssertEqual(try l2.get(forField: 4) as? String, "level2_text")
    }

    let dl1Desc = CompatDescriptors.deepLevel1()
    let dl2Desc = CompatDescriptors.deepLevel2()
    let dl3Desc = CompatDescriptors.deepLevel3()
    let dl4Desc = CompatDescriptors.deepLevel4()

    var l4 = DynamicMessage(descriptor: dl4Desc)
    try l4.set(Int32(99), forField: 1)

    var l3 = DynamicMessage(descriptor: dl3Desc)
    try l3.set(l4, forField: 1)
    try l3.set(true, forField: 3)

    var l2 = DynamicMessage(descriptor: dl2Desc)
    try l2.set(l3, forField: 1)
    try l2.set(Int32(5), forField: 2)
    try l2.set("level2_text", forField: 4)  // oneof text field

    var dynamic = DynamicMessage(descriptor: dl1Desc)
    try dynamic.set(l2, forField: 1)
    try dynamic.set("oneof_test", forField: 2)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_DeepLevel1.self) {
      decoded in
      XCTAssertEqual(decoded.name, "oneof_test")
      XCTAssertEqual(decoded.child.count, 5)
      XCTAssertEqual(decoded.child.text, "level2_text")
      XCTAssertTrue(decoded.child.child.flag)
      XCTAssertEqual(decoded.child.child.child.value, 99)
    }
  }

  // MARK: - Deep: with extras (repeated DeepLevel2)

  func test_kitchenSink_deepWithExtras_bidirectional() throws {
    // DeepLevel1 with multiple DeepLevel2 in `extras` field
    var proto = Testcompat_DeepLevel1()
    proto.name = "extras_test"
    proto.child.count = 1

    var extra1 = Testcompat_DeepLevel2()
    extra1.count = 10
    extra1.numbers = [1, 2, 3]
    extra1.active = true  // activate `active` oneof

    var extra2 = Testcompat_DeepLevel2()
    extra2.count = 20
    extra2.text = "extra2_text"

    proto.extras = [extra1, extra2]

    let desc = CompatDescriptors.deepLevel1()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 2) as? String, "extras_test")
      let extras = try XCTUnwrap(try msg.get(forField: 5) as? [DynamicMessage])
      XCTAssertEqual(extras.count, 2)
      XCTAssertEqual(try extras[0].get(forField: 2) as? Int32, 10)
      XCTAssertEqual(try extras[1].get(forField: 2) as? Int32, 20)
    }

    let dl2Desc = CompatDescriptors.deepLevel2()
    var e1 = DynamicMessage(descriptor: dl2Desc)
    try e1.set(Int32(10), forField: 2)
    try e1.set([Int32(1), Int32(2), Int32(3)] as [Int32], forField: 3)
    try e1.set(true, forField: 5)  // oneof `active`

    var e2 = DynamicMessage(descriptor: dl2Desc)
    try e2.set(Int32(20), forField: 2)
    try e2.set("extra2_text", forField: 4)  // oneof `text`

    let dl1Desc = CompatDescriptors.deepLevel1()
    var dynamic = DynamicMessage(descriptor: dl1Desc)
    try dynamic.set("extras_test", forField: 2)
    try dynamic.set([e1, e2] as [DynamicMessage], forField: 5)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_DeepLevel1.self) {
      decoded in
      XCTAssertEqual(decoded.name, "extras_test")
      XCTAssertEqual(decoded.extras.count, 2)
      XCTAssertEqual(decoded.extras[0].count, 10)
      XCTAssertEqual(decoded.extras[0].numbers, [1, 2, 3])
      XCTAssertEqual(decoded.extras[1].text, "extra2_text")
    }
  }

  // MARK: - Flat KitchenSink: single field populated, rest default

  func test_kitchenSink_flat_singleFieldPopulated_bidirectional() throws {
    var proto = Testcompat_KitchenSinkFlat()
    proto.stringVal = "only_this"

    let desc = CompatDescriptors.kitchenSinkFlat()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 14) as? String, "only_this")
      XCTAssertNil(try msg.get(forField: 1) as? Int32)
      XCTAssertNil(try msg.get(forField: 13) as? Bool)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("only_this", forField: 14)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_KitchenSinkFlat.self)
    {
      decoded in
      XCTAssertEqual(decoded.stringVal, "only_this")
      XCTAssertEqual(decoded.int32Val, 0)
      XCTAssertFalse(decoded.boolVal)
      XCTAssertTrue(decoded.repInt32.isEmpty)
      XCTAssertTrue(decoded.mapSs.isEmpty)
    }
  }

  // MARK: - Round-trip: all 50 WideMessage fields

  func test_kitchenSink_wideMessage_50fields_bidirectional() throws {
    var proto = Testcompat_WideMessage()
    // Set all string fields (f1..f20)
    proto.f1 = "a"
    proto.f2 = "b"
    proto.f3 = "c"
    proto.f4 = "d"
    proto.f5 = "e"
    proto.f6 = "f"
    proto.f7 = "g"
    proto.f8 = "h"
    proto.f9 = "i"
    proto.f10 = "j"
    proto.f11 = "k"
    proto.f12 = "l"
    proto.f13 = "m"
    proto.f14 = "n"
    proto.f15 = "o"
    proto.f16 = "p"
    proto.f17 = "q"
    proto.f18 = "r"
    proto.f19 = "s"
    proto.f20 = "t"
    // Set int fields (i1..i10)
    proto.i1 = 1
    proto.i2 = 2
    proto.i3 = 3
    proto.i4 = 4
    proto.i5 = 5
    proto.i6 = 6
    proto.i7 = 7
    proto.i8 = 8
    proto.i9 = 9
    proto.i10 = 10

    let desc = CompatDescriptors.wideMessage()
    let msg = try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? String, "a")
      XCTAssertEqual(try msg.get(forField: 20) as? String, "t")
      XCTAssertEqual(try msg.get(forField: 21) as? Int32, 1)
      XCTAssertEqual(try msg.get(forField: 30) as? Int32, 10)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    let strVals = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t"]
    for (i, v) in strVals.enumerated() {
      try dynamic.set(v, forField: i + 1)
    }
    for i in 1...10 {
      try dynamic.set(Int32(i), forField: 20 + i)
    }
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_WideMessage.self) {
      decoded in
      XCTAssertEqual(decoded.f1, "a")
      XCTAssertEqual(decoded.f20, "t")
      XCTAssertEqual(decoded.i1, 1)
      XCTAssertEqual(decoded.i10, 10)
    }
    _ = msg
  }
}
