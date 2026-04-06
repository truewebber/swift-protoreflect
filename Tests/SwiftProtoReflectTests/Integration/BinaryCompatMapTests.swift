// BinaryCompatMapTests.swift
// SwiftProtoReflectTests
//
// Group: Map Fields — bidirectional binary compatibility tests.
//
// Oracle strategy: Option A — swift-protobuf generated types (.pb.swift).
//
// Binary-specific notes:
//   - Each map entry is encoded as a length-delimited (wire type 2) nested message
//     with key at field 1 and value at field 2 inside the entry.
//   - Map entry iteration order is non-deterministic; all tests use value comparison,
//     never byte-for-byte comparison.
//   - Empty map fields produce no wire bytes (no entries, no tags).

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class BinaryCompatMapTests: XCTestCase {

  private var registry: TypeRegistry!
  private let serializer = BinaryCompatHelpers.makeSerializer()

  override func setUp() {
    super.setUp()
    registry = try? CompatDescriptors.fullRegistry()
  }

  override func tearDown() {
    registry = nil
    super.tearDown()
  }

  // MARK: - 1. map<string, string>

  func test_map_stringString_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapStringString = ["key1": "val1", "key2": "val2", "": "empty_key"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let map = try XCTUnwrap(try msg.get(forField: 1) as? [AnyHashable: Any])
        XCTAssertEqual(map["key1"] as? String, "val1")
        XCTAssertEqual(map["key2"] as? String, "val2")
        XCTAssertEqual(map[""] as? String, "empty_key")
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.setMapEntry("val1", forKey: "key1", inField: 1)
        try d.setMapEntry("val2", forKey: "key2", inField: 1)
        try d.setMapEntry("empty_key", forKey: "", inField: 1)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.mapStringString["key1"], "val1")
        XCTAssertEqual(p.mapStringString["key2"], "val2")
        XCTAssertEqual(p.mapStringString[""], "empty_key")
      }
    )
  }

  // MARK: - 2. map<int32, string>

  func test_map_int32Key_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapInt32String = [-1: "neg", 0: "zero", Int32.max: "max"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let map = try XCTUnwrap(try msg.get(forField: 2) as? [AnyHashable: Any])
        XCTAssertEqual(map[Int32(-1)] as? String, "neg")
        XCTAssertEqual(map[Int32(0)] as? String, "zero")
        XCTAssertEqual(map[Int32.max] as? String, "max")
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.setMapEntry("neg", forKey: Int32(-1), inField: 2)
        try d.setMapEntry("zero", forKey: Int32(0), inField: 2)
        try d.setMapEntry("max", forKey: Int32.max, inField: 2)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.mapInt32String[-1], "neg")
        XCTAssertEqual(p.mapInt32String[0], "zero")
        XCTAssertEqual(p.mapInt32String[Int32.max], "max")
      }
    )
  }

  // MARK: - 3. map<int64, string>

  func test_map_int64Key_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapInt64String = [Int64.min: "min", 0: "zero", Int64.max: "max"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let map = try XCTUnwrap(try msg.get(forField: 3) as? [AnyHashable: Any])
        XCTAssertEqual(map[Int64.min] as? String, "min")
        XCTAssertEqual(map[Int64(0)] as? String, "zero")
        XCTAssertEqual(map[Int64.max] as? String, "max")
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.setMapEntry("min", forKey: Int64.min, inField: 3)
        try d.setMapEntry("zero", forKey: Int64(0), inField: 3)
        try d.setMapEntry("max", forKey: Int64.max, inField: 3)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.mapInt64String[Int64.min], "min")
        XCTAssertEqual(p.mapInt64String[0], "zero")
        XCTAssertEqual(p.mapInt64String[Int64.max], "max")
      }
    )
  }

  // MARK: - 4. map<uint32, string>

  func test_map_uint32Key_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapUint32String = [0: "zero", UInt32.max: "max", 42: "answer"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let map = try XCTUnwrap(try msg.get(forField: 4) as? [AnyHashable: Any])
        XCTAssertEqual(map[UInt32(0)] as? String, "zero")
        XCTAssertEqual(map[UInt32.max] as? String, "max")
        XCTAssertEqual(map[UInt32(42)] as? String, "answer")
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.setMapEntry("zero", forKey: UInt32(0), inField: 4)
        try d.setMapEntry("max", forKey: UInt32.max, inField: 4)
        try d.setMapEntry("answer", forKey: UInt32(42), inField: 4)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.mapUint32String[0], "zero")
        XCTAssertEqual(p.mapUint32String[UInt32.max], "max")
        XCTAssertEqual(p.mapUint32String[42], "answer")
      }
    )
  }

  // MARK: - 5. map<uint64, string>

  func test_map_uint64Key_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapUint64String = [0: "zero", UInt64.max: "max"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let map = try XCTUnwrap(try msg.get(forField: 5) as? [AnyHashable: Any])
        XCTAssertEqual(map[UInt64(0)] as? String, "zero")
        XCTAssertEqual(map[UInt64.max] as? String, "max")
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.setMapEntry("zero", forKey: UInt64(0), inField: 5)
        try d.setMapEntry("max", forKey: UInt64.max, inField: 5)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.mapUint64String[0], "zero")
        XCTAssertEqual(p.mapUint64String[UInt64.max], "max")
      }
    )
  }

  // MARK: - 6. map<sint32, string> (zigzag key encoding in map entry)

  func test_map_sint32Key_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapSint32String = [-100: "neg", 100: "pos"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let map = try XCTUnwrap(try msg.get(forField: 6) as? [AnyHashable: Any])
        XCTAssertEqual(map[Int32(-100)] as? String, "neg")
        XCTAssertEqual(map[Int32(100)] as? String, "pos")
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.setMapEntry("neg", forKey: Int32(-100), inField: 6)
        try d.setMapEntry("pos", forKey: Int32(100), inField: 6)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.mapSint32String[-100], "neg")
        XCTAssertEqual(p.mapSint32String[100], "pos")
      }
    )
  }

  // MARK: - 7. map<sint64, string> (zigzag key encoding in map entry)

  func test_map_sint64Key_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapSint64String = [Int64.min: "min", Int64.max: "max"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let map = try XCTUnwrap(try msg.get(forField: 7) as? [AnyHashable: Any])
        XCTAssertEqual(map[Int64.min] as? String, "min")
        XCTAssertEqual(map[Int64.max] as? String, "max")
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.setMapEntry("min", forKey: Int64.min, inField: 7)
        try d.setMapEntry("max", forKey: Int64.max, inField: 7)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.mapSint64String[Int64.min], "min")
        XCTAssertEqual(p.mapSint64String[Int64.max], "max")
      }
    )
  }

  // MARK: - 8. map<fixed32, string> (4-byte little-endian key in map entry)

  func test_map_fixed32Key_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapFixed32String = [0: "zero", UInt32.max: "max"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let map = try XCTUnwrap(try msg.get(forField: 8) as? [AnyHashable: Any])
        XCTAssertEqual(map[UInt32(0)] as? String, "zero")
        XCTAssertEqual(map[UInt32.max] as? String, "max")
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.setMapEntry("zero", forKey: UInt32(0), inField: 8)
        try d.setMapEntry("max", forKey: UInt32.max, inField: 8)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.mapFixed32String[0], "zero")
        XCTAssertEqual(p.mapFixed32String[UInt32.max], "max")
      }
    )
  }

  // MARK: - 9. map<fixed64, string> (8-byte little-endian key in map entry)

  func test_map_fixed64Key_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapFixed64String = [UInt64.max: "max"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let map = try XCTUnwrap(try msg.get(forField: 9) as? [AnyHashable: Any])
        XCTAssertEqual(map[UInt64.max] as? String, "max")
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.setMapEntry("max", forKey: UInt64.max, inField: 9)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.mapFixed64String[UInt64.max], "max")
      }
    )
  }

  // MARK: - 10. map<sfixed32, string> (4-byte signed fixed key in map entry)

  func test_map_sfixed32Key_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapSfixed32String = [Int32.min: "min", Int32.max: "max"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let map = try XCTUnwrap(try msg.get(forField: 10) as? [AnyHashable: Any])
        XCTAssertEqual(map[Int32.min] as? String, "min")
        XCTAssertEqual(map[Int32.max] as? String, "max")
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.setMapEntry("min", forKey: Int32.min, inField: 10)
        try d.setMapEntry("max", forKey: Int32.max, inField: 10)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.mapSfixed32String[Int32.min], "min")
        XCTAssertEqual(p.mapSfixed32String[Int32.max], "max")
      }
    )
  }

  // MARK: - 11. map<sfixed64, string> (8-byte signed fixed key in map entry)

  func test_map_sfixed64Key_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapSfixed64String = [Int64.min: "min"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let map = try XCTUnwrap(try msg.get(forField: 11) as? [AnyHashable: Any])
        XCTAssertEqual(map[Int64.min] as? String, "min")
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.setMapEntry("min", forKey: Int64.min, inField: 11)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.mapSfixed64String[Int64.min], "min")
      }
    )
  }

  // MARK: - 12. map<bool, string>

  func test_map_boolKey_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapBoolString = [true: "yes", false: "no"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let map = try XCTUnwrap(try msg.get(forField: 12) as? [AnyHashable: Any])
        XCTAssertEqual(map[true] as? String, "yes")
        XCTAssertEqual(map[false] as? String, "no")
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.setMapEntry("yes", forKey: true, inField: 12)
        try d.setMapEntry("no", forKey: false, inField: 12)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.mapBoolString[true], "yes")
        XCTAssertEqual(p.mapBoolString[false], "no")
      }
    )
  }

  // MARK: - 13. map<string, SimpleMessage> (embedded message value in map entry)

  func test_map_messageValue_bidirectional() throws {
    var m1 = Testcompat_SimpleMessage()
    m1.id = 42
    m1.name = "test"
    var proto = Testcompat_MapAllValueTypes()
    proto.mapSSimple = ["key": m1]

    let desc = CompatDescriptors.mapAllValueTypes()
    let simpleDesc = CompatDescriptors.simpleMessage()

    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let map = try XCTUnwrap(try msg.get(forField: 10) as? [AnyHashable: Any])
        let dMsg = try XCTUnwrap(map["key"] as? DynamicMessage)
        XCTAssertEqual(try dMsg.get(forField: 1) as? Int32, 42)
        XCTAssertEqual(try dMsg.get(forField: 2) as? String, "test")
      },
      buildDynamic: {
        var inner = DynamicMessage(descriptor: simpleDesc)
        try inner.set(Int32(42), forField: 1)
        try inner.set("test", forField: 2)
        var d = DynamicMessage(descriptor: desc)
        try d.setMapEntry(inner, forKey: "key", inField: 10)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.mapSSimple["key"]?.id, 42)
        XCTAssertEqual(p.mapSSimple["key"]?.name, "test")
      }
    )
  }

  // MARK: - 14. map<string, Status> (enum value in map entry)

  func test_map_enumValue_bidirectional() throws {
    var proto = Testcompat_MapAllValueTypes()
    proto.mapSEnum = ["a": .active, "b": .inactive]

    let desc = CompatDescriptors.mapAllValueTypes()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let map = try XCTUnwrap(try msg.get(forField: 9) as? [AnyHashable: Any])
        XCTAssertEqual(map["a"] as? Int32, 1)
        XCTAssertEqual(map["b"] as? Int32, 2)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.setMapEntry(Int32(1), forKey: "a", inField: 9)
        try d.setMapEntry(Int32(2), forKey: "b", inField: 9)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.mapSEnum["a"], .active)
        XCTAssertEqual(p.mapSEnum["b"], .inactive)
      }
    )
  }

  // MARK: - 15. MixedContainers: repeated + map simultaneously

  func test_map_mixedContainers_bidirectional() throws {
    var proto = Testcompat_MixedContainers()
    proto.ids = [1, 2, 3]
    proto.names = ["a", "b"]
    proto.scores = ["x": 10, "y": 20]

    let desc = CompatDescriptors.mixedContainers()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        XCTAssertEqual(try msg.get(forField: 1) as? [Int32], [1, 2, 3])
        XCTAssertEqual(try msg.get(forField: 2) as? [String], ["a", "b"])
        let scores = try XCTUnwrap(try msg.get(forField: 3) as? [AnyHashable: Any])
        XCTAssertEqual(scores["x"] as? Int32, 10)
        XCTAssertEqual(scores["y"] as? Int32, 20)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.set([Int32(1), Int32(2), Int32(3)] as [Int32], forField: 1)
        try d.set(["a", "b"] as [String], forField: 2)
        try d.setMapEntry(Int32(10), forKey: "x", inField: 3)
        try d.setMapEntry(Int32(20), forKey: "y", inField: 3)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.ids, [1, 2, 3])
        XCTAssertEqual(p.names, ["a", "b"])
        XCTAssertEqual(p.scores["x"], 10)
        XCTAssertEqual(p.scores["y"], 20)
      }
    )
  }

  // MARK: - 16. map<string, int32> boundary values

  func test_map_stringInt32_bidirectional() throws {
    var proto = Testcompat_MapAllValueTypes()
    proto.mapSInt32 = ["a": Int32.min, "b": 0, "c": Int32.max]

    let desc = CompatDescriptors.mapAllValueTypes()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let map = try XCTUnwrap(try msg.get(forField: 1) as? [AnyHashable: Any])
        XCTAssertEqual(map["a"] as? Int32, Int32.min)
        XCTAssertEqual(map["b"] as? Int32, 0)
        XCTAssertEqual(map["c"] as? Int32, Int32.max)
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.setMapEntry(Int32.min, forKey: "a", inField: 1)
        try d.setMapEntry(Int32(0), forKey: "b", inField: 1)
        try d.setMapEntry(Int32.max, forKey: "c", inField: 1)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.mapSInt32["a"], Int32.min)
        XCTAssertEqual(p.mapSInt32["b"], 0)
        XCTAssertEqual(p.mapSInt32["c"], Int32.max)
      }
    )
  }

  // MARK: - 17. Empty map produces no wire bytes

  func test_map_empty_producesNoWireOutput() throws {
    // Direction A: oracle with all-empty maps → serializedData() = Data()
    let proto = Testcompat_MapAllKeyTypes()
    let referenceData = try proto.serializedData()
    XCTAssertEqual(referenceData, Data(), "swift-protobuf must produce empty bytes for all-empty map fields")

    // Direction B: our serializer with no entries set → Data()
    let desc = CompatDescriptors.mapAllKeyTypes()
    let dynamic = DynamicMessage(descriptor: desc)
    let ourData = try serializer.serialize(dynamic)
    XCTAssertEqual(ourData, Data(), "BinarySerializer must produce empty bytes when no map entries are set")
  }

  // MARK: - 18. Single-entry map<string, string>

  func test_map_singleEntry_bidirectional() throws {
    var proto = Testcompat_MapAllKeyTypes()
    proto.mapStringString = ["only": "one"]

    let desc = CompatDescriptors.mapAllKeyTypes()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let map = try XCTUnwrap(try msg.get(forField: 1) as? [AnyHashable: Any])
        XCTAssertEqual(map.count, 1)
        XCTAssertEqual(map["only"] as? String, "one")
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        try d.setMapEntry("one", forKey: "only", inField: 1)
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.mapStringString.count, 1)
        XCTAssertEqual(p.mapStringString["only"], "one")
      }
    )
  }

  // MARK: - 19. Large map: 50 entries map<string, int32>

  func test_map_largeMap_50entries_bidirectional() throws {
    var proto = Testcompat_MapAllValueTypes()
    for i in 0..<50 {
      proto.mapSInt32["key\(i)"] = Int32(i * 2)
    }

    let desc = CompatDescriptors.mapAllValueTypes()
    try BinaryCompatHelpers.assertBidirectional(
      proto: proto,
      descriptor: desc,
      registry: registry,
      validateDynamic: { msg in
        let map = try XCTUnwrap(try msg.get(forField: 1) as? [AnyHashable: Any])
        XCTAssertEqual(map.count, 50)
        for i in 0..<50 {
          XCTAssertEqual(map["key\(i)"] as? Int32, Int32(i * 2), "mismatch at key\(i)")
        }
      },
      buildDynamic: {
        var d = DynamicMessage(descriptor: desc)
        for i in 0..<50 {
          try d.setMapEntry(Int32(i * 2), forKey: "key\(i)", inField: 1)
        }
        return d
      },
      validateProto: { p in
        XCTAssertEqual(p.mapSInt32.count, 50)
        for i in 0..<50 {
          XCTAssertEqual(p.mapSInt32["key\(i)"], Int32(i * 2), "mismatch at key\(i)")
        }
      }
    )
  }
}
