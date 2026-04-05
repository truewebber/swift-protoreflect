// JSONCompatMapTests.swift
// SwiftProtoReflectTests
//
// Group 3: Map Fields — bidirectional JSON compatibility tests.
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class JSONCompatMapTests: XCTestCase {

  private var registry: TypeRegistry!

  override func setUp() {
    super.setUp()
    registry = try? CompatDescriptors.fullRegistry()
  }

  override func tearDown() {
    registry = nil
    super.tearDown()
  }

  // MARK: - String-string map

  func test_map_stringString_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapStringString = ["key1": "val1", "key2": "val2", "": "empty_key"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let map = try XCTUnwrap(try msg.get(forField: 1) as? [AnyHashable: Any])
      XCTAssertEqual(map["key1"] as? String, "val1")
      XCTAssertEqual(map["key2"] as? String, "val2")
      XCTAssertEqual(map[""] as? String, "empty_key")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry("val1", forKey: "key1", inField: 1)
    try dynamic.setMapEntry("val2", forKey: "key2", inField: 1)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MapAllKeyTypes.self)
    { decoded in
      XCTAssertEqual(decoded.mapStringString["key1"], "val1")
      XCTAssertEqual(decoded.mapStringString["key2"], "val2")
    }
  }

  // MARK: - Int32 key

  func test_map_int32Key_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapInt32String = [-1: "neg", 0: "zero", Int32.max: "max"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let map = try XCTUnwrap(try msg.get(forField: 2) as? [AnyHashable: Any])
      XCTAssertEqual(map[Int32(-1)] as? String, "neg")
      XCTAssertEqual(map[Int32(0)] as? String, "zero")
      XCTAssertEqual(map[Int32.max] as? String, "max")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry("neg", forKey: Int32(-1), inField: 2)
    try dynamic.setMapEntry("zero", forKey: Int32(0), inField: 2)
    try dynamic.setMapEntry("max", forKey: Int32.max, inField: 2)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MapAllKeyTypes.self)
    { decoded in
      XCTAssertEqual(decoded.mapInt32String[-1], "neg")
      XCTAssertEqual(decoded.mapInt32String[0], "zero")
      XCTAssertEqual(decoded.mapInt32String[Int32.max], "max")
    }
  }

  // MARK: - Int64 key (quoted in JSON)

  func test_map_int64Key_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapInt64String = [Int64.min: "min", 0: "zero", Int64.max: "max"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let map = try XCTUnwrap(try msg.get(forField: 3) as? [AnyHashable: Any])
      XCTAssertEqual(map[Int64.min] as? String, "min")
      XCTAssertEqual(map[Int64(0)] as? String, "zero")
      XCTAssertEqual(map[Int64.max] as? String, "max")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry("min", forKey: Int64.min, inField: 3)
    try dynamic.setMapEntry("zero", forKey: Int64(0), inField: 3)
    try dynamic.setMapEntry("max", forKey: Int64.max, inField: 3)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MapAllKeyTypes.self)
    { decoded in
      XCTAssertEqual(decoded.mapInt64String[Int64.min], "min")
      XCTAssertEqual(decoded.mapInt64String[0], "zero")
      XCTAssertEqual(decoded.mapInt64String[Int64.max], "max")
    }
  }

  // MARK: - UInt32 key

  func test_map_uint32Key_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapUint32String = [0: "zero", UInt32.max: "max", 42: "answer"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let map = try XCTUnwrap(try msg.get(forField: 4) as? [AnyHashable: Any])
      XCTAssertEqual(map[UInt32(0)] as? String, "zero")
      XCTAssertEqual(map[UInt32.max] as? String, "max")
      XCTAssertEqual(map[UInt32(42)] as? String, "answer")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry("zero", forKey: UInt32(0), inField: 4)
    try dynamic.setMapEntry("max", forKey: UInt32.max, inField: 4)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MapAllKeyTypes.self)
    { decoded in
      XCTAssertEqual(decoded.mapUint32String[0], "zero")
      XCTAssertEqual(decoded.mapUint32String[UInt32.max], "max")
    }
  }

  // MARK: - UInt64 key

  func test_map_uint64Key_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapUint64String = [0: "zero", UInt64.max: "max"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let map = try XCTUnwrap(try msg.get(forField: 5) as? [AnyHashable: Any])
      XCTAssertEqual(map[UInt64(0)] as? String, "zero")
      XCTAssertEqual(map[UInt64.max] as? String, "max")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry("zero", forKey: UInt64(0), inField: 5)
    try dynamic.setMapEntry("max", forKey: UInt64.max, inField: 5)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MapAllKeyTypes.self)
    { decoded in
      XCTAssertEqual(decoded.mapUint64String[0], "zero")
    }
  }

  // MARK: - Sint32 key

  func test_map_sint32Key_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapSint32String = [-100: "neg", 100: "pos"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let map = try XCTUnwrap(try msg.get(forField: 6) as? [AnyHashable: Any])
      XCTAssertEqual(map[Int32(-100)] as? String, "neg")
      XCTAssertEqual(map[Int32(100)] as? String, "pos")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry("neg", forKey: Int32(-100), inField: 6)
    try dynamic.setMapEntry("pos", forKey: Int32(100), inField: 6)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MapAllKeyTypes.self)
    { decoded in
      XCTAssertEqual(decoded.mapSint32String[-100], "neg")
      XCTAssertEqual(decoded.mapSint32String[100], "pos")
    }
  }

  // MARK: - Sint64 key

  func test_map_sint64Key_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapSint64String = [Int64.min: "min", Int64.max: "max"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let map = try XCTUnwrap(try msg.get(forField: 7) as? [AnyHashable: Any])
      XCTAssertEqual(map[Int64.min] as? String, "min")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry("min", forKey: Int64.min, inField: 7)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MapAllKeyTypes.self)
    { decoded in
      XCTAssertEqual(decoded.mapSint64String[Int64.min], "min")
    }
  }

  // MARK: - Fixed32 / Fixed64 / Sfixed32 / Sfixed64 keys

  func test_map_fixed32Key_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapFixed32String = [0: "zero", UInt32.max: "max"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let map = try XCTUnwrap(try msg.get(forField: 8) as? [AnyHashable: Any])
      XCTAssertEqual(map[UInt32(0)] as? String, "zero")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry("zero", forKey: UInt32(0), inField: 8)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MapAllKeyTypes.self)
    { decoded in
      XCTAssertEqual(decoded.mapFixed32String[0], "zero")
    }
  }

  func test_map_fixed64Key_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapFixed64String = [UInt64.max: "max"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let map = try XCTUnwrap(try msg.get(forField: 9) as? [AnyHashable: Any])
      XCTAssertEqual(map[UInt64.max] as? String, "max")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry("max", forKey: UInt64.max, inField: 9)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MapAllKeyTypes.self)
    { decoded in
      XCTAssertEqual(decoded.mapFixed64String[UInt64.max], "max")
    }
  }

  func test_map_sfixed32Key_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapSfixed32String = [Int32.min: "min", Int32.max: "max"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let map = try XCTUnwrap(try msg.get(forField: 10) as? [AnyHashable: Any])
      XCTAssertEqual(map[Int32.min] as? String, "min")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry("min", forKey: Int32.min, inField: 10)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MapAllKeyTypes.self)
    { decoded in
      XCTAssertEqual(decoded.mapSfixed32String[Int32.min], "min")
    }
  }

  func test_map_sfixed64Key_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapSfixed64String = [Int64.min: "min"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let map = try XCTUnwrap(try msg.get(forField: 11) as? [AnyHashable: Any])
      XCTAssertEqual(map[Int64.min] as? String, "min")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry("min", forKey: Int64.min, inField: 11)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MapAllKeyTypes.self)
    { decoded in
      XCTAssertEqual(decoded.mapSfixed64String[Int64.min], "min")
    }
  }

  // MARK: - Bool key ("true"/"false" in JSON)

  func test_map_boolKey_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapBoolString = [true: "yes", false: "no"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let map = try XCTUnwrap(try msg.get(forField: 12) as? [AnyHashable: Any])
      XCTAssertEqual(map[true] as? String, "yes")
      XCTAssertEqual(map[false] as? String, "no")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry("yes", forKey: true, inField: 12)
    try dynamic.setMapEntry("no", forKey: false, inField: 12)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MapAllKeyTypes.self)
    { decoded in
      XCTAssertEqual(decoded.mapBoolString[true], "yes")
      XCTAssertEqual(decoded.mapBoolString[false], "no")
    }
  }

  // MARK: - Message value

  func test_map_messageValue_bidirectional() throws {
    var proto = Testcompat_MapAllValueTypes()
    var m1 = Testcompat_SimpleMessage()
    m1.id = 42
    m1.name = "test"
    proto.mapSSimple = ["key": m1]

    let desc = CompatDescriptors.mapAllValueTypes()
    let simpleDesc = CompatDescriptors.simpleMessage()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let map = try XCTUnwrap(try msg.get(forField: 10) as? [AnyHashable: Any])
      let dMsg = try XCTUnwrap(map["key"] as? DynamicMessage)
      XCTAssertEqual(try dMsg.get(forField: 1) as? Int32, 42)
      XCTAssertEqual(try dMsg.get(forField: 2) as? String, "test")
    }

    var inner = DynamicMessage(descriptor: simpleDesc)
    try inner.set(Int32(42), forField: 1)
    try inner.set("test", forField: 2)
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry(inner, forKey: "key", inField: 10)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_MapAllValueTypes.self
    ) { decoded in
      XCTAssertEqual(decoded.mapSSimple["key"]?.id, 42)
      XCTAssertEqual(decoded.mapSSimple["key"]?.name, "test")
    }
  }

  // MARK: - Enum value

  func test_map_enumValue_bidirectional() throws {
    var proto = Testcompat_MapAllValueTypes()
    proto.mapSEnum = ["a": .active, "b": .inactive]

    let desc = CompatDescriptors.mapAllValueTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let map = try XCTUnwrap(try msg.get(forField: 9) as? [AnyHashable: Any])
      XCTAssertEqual(map["a"] as? Int32, 1)
      XCTAssertEqual(map["b"] as? Int32, 2)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry(Int32(1), forKey: "a", inField: 9)
    try dynamic.setMapEntry(Int32(2), forKey: "b", inField: 9)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_MapAllValueTypes.self
    ) { decoded in
      XCTAssertEqual(decoded.mapSEnum["a"], .active)
      XCTAssertEqual(decoded.mapSEnum["b"], .inactive)
    }
  }

  // MARK: - Mixed containers

  func test_map_mixedContainers_bidirectional() throws {
    var proto = Testcompat_MixedContainers()
    proto.ids = [1, 2, 3]
    proto.names = ["a", "b"]
    proto.scores = ["x": 10, "y": 20]

    let desc = CompatDescriptors.mixedContainers()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? [Int32], [1, 2, 3])
      XCTAssertEqual(try msg.get(forField: 2) as? [String], ["a", "b"])
      let scores = try XCTUnwrap(try msg.get(forField: 3) as? [AnyHashable: Any])
      XCTAssertEqual(scores["x"] as? Int32, 10)
      XCTAssertEqual(scores["y"] as? Int32, 20)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set([Int32(1), Int32(2), Int32(3)] as [Int32], forField: 1)
    try dynamic.set(["a", "b"] as [String], forField: 2)
    try dynamic.setMapEntry(Int32(10), forKey: "x", inField: 3)
    try dynamic.setMapEntry(Int32(20), forKey: "y", inField: 3)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MixedContainers.self)
    { decoded in
      XCTAssertEqual(decoded.ids, [1, 2, 3])
      XCTAssertEqual(decoded.names, ["a", "b"])
      XCTAssertEqual(decoded.scores["x"], 10)
      XCTAssertEqual(decoded.scores["y"], 20)
    }
  }

  // MARK: - map stringInt32

  func test_map_stringInt32_bidirectional() throws {
    var proto = Testcompat_MapAllValueTypes()
    proto.mapSInt32 = ["a": Int32.min, "b": 0, "c": Int32.max]

    let desc = CompatDescriptors.mapAllValueTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let map = try XCTUnwrap(try msg.get(forField: 1) as? [AnyHashable: Any])
      XCTAssertEqual(map["a"] as? Int32, Int32.min)
      XCTAssertEqual(map["b"] as? Int32, 0)
      XCTAssertEqual(map["c"] as? Int32, Int32.max)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.setMapEntry(Int32.min, forKey: "a", inField: 1)
    try dynamic.setMapEntry(Int32(0), forKey: "b", inField: 1)
    try dynamic.setMapEntry(Int32.max, forKey: "c", inField: 1)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_MapAllValueTypes.self
    ) { decoded in
      XCTAssertEqual(decoded.mapSInt32["a"], Int32.min)
      XCTAssertEqual(decoded.mapSInt32["b"], 0)
      XCTAssertEqual(decoded.mapSInt32["c"], Int32.max)
    }
  }
}
