// JSONCompatRepeatedTests.swift
// SwiftProtoReflectTests
//
// Group 2: Repeated Fields — bidirectional JSON compatibility tests.
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class JSONCompatRepeatedTests: XCTestCase {

  private var registry: TypeRegistry!

  override func setUp() {
    super.setUp()
    registry = try? CompatDescriptors.fullRegistry()
  }

  override func tearDown() {
    registry = nil
    super.tearDown()
  }

  // MARK: - Repeated int32

  func test_repeated_int32_bidirectional() throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repInt32 = [1, -1, 0, Int32.max, Int32.min]

    let desc = CompatDescriptors.repeatedAllTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let vals = try XCTUnwrap(try msg.get(forField: 3) as? [Int32])
      XCTAssertEqual(vals, [1, -1, 0, Int32.max, Int32.min])
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set([Int32(1), Int32(-1), Int32(0), Int32.max, Int32.min] as [Int32], forField: 3)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_RepeatedAllTypes.self
    ) { decoded in
      XCTAssertEqual(decoded.repInt32, [1, -1, 0, Int32.max, Int32.min])
    }
  }

  // MARK: - Repeated int64 (quoted strings in array)

  func test_repeated_int64_quotedInArray_bidirectional() throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repInt64 = [Int64.max, Int64.min, 0, 9_000_000_000]

    let desc = CompatDescriptors.repeatedAllTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let vals = try XCTUnwrap(try msg.get(forField: 4) as? [Int64])
      XCTAssertEqual(vals, [Int64.max, Int64.min, 0, 9_000_000_000])
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set([Int64.max, Int64.min, Int64(0), Int64(9_000_000_000)] as [Int64], forField: 4)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_RepeatedAllTypes.self
    ) { decoded in
      XCTAssertEqual(decoded.repInt64, [Int64.max, Int64.min, 0, 9_000_000_000])
    }
  }

  // MARK: - Repeated uint64 (quoted strings in array)

  func test_repeated_uint64_quotedInArray_bidirectional() throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repUint64 = [UInt64.max, 0, 18_000_000_000]

    let desc = CompatDescriptors.repeatedAllTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let vals = try XCTUnwrap(try msg.get(forField: 6) as? [UInt64])
      XCTAssertEqual(vals, [UInt64.max, 0, 18_000_000_000])
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set([UInt64.max, UInt64(0), UInt64(18_000_000_000)] as [UInt64], forField: 6)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_RepeatedAllTypes.self
    ) { decoded in
      XCTAssertEqual(decoded.repUint64, [UInt64.max, 0, 18_000_000_000])
    }
  }

  // MARK: - Repeated signed types

  func test_repeated_allSignedTypes_bidirectional() throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repSint32 = [-100, 0, 100, Int32.min, Int32.max]
    proto.repSint64 = [-9_000_000_000, 0, 9_000_000_000]
    proto.repSfixed32 = [Int32.min, -1, 0, 1, Int32.max]
    proto.repSfixed64 = [Int64.min, 0, Int64.max]

    let desc = CompatDescriptors.repeatedAllTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 7) as? [Int32], [-100, 0, 100, Int32.min, Int32.max])
      XCTAssertEqual(try msg.get(forField: 8) as? [Int64], [-9_000_000_000, 0, 9_000_000_000])
      XCTAssertEqual(try msg.get(forField: 11) as? [Int32], [Int32.min, -1, 0, 1, Int32.max])
      XCTAssertEqual(try msg.get(forField: 12) as? [Int64], [Int64.min, 0, Int64.max])
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set([-100, 0, 100, Int32.min, Int32.max] as [Int32], forField: 7)
    try dynamic.set([-9_000_000_000, 0, 9_000_000_000] as [Int64], forField: 8)
    try dynamic.set([Int32.min, -1, 0, 1, Int32.max] as [Int32], forField: 11)
    try dynamic.set([Int64.min, 0, Int64.max] as [Int64], forField: 12)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_RepeatedAllTypes.self
    ) { decoded in
      XCTAssertEqual(decoded.repSint32, [-100, 0, 100, Int32.min, Int32.max])
      XCTAssertEqual(decoded.repSint64, [-9_000_000_000, 0, 9_000_000_000])
      XCTAssertEqual(decoded.repSfixed32, [Int32.min, -1, 0, 1, Int32.max])
      XCTAssertEqual(decoded.repSfixed64, [Int64.min, 0, Int64.max])
    }
  }

  // MARK: - Repeated fixed types

  func test_repeated_allFixedTypes_bidirectional() throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repFixed32 = [0, 1, UInt32.max]
    proto.repFixed64 = [0, 1, UInt64.max]
    proto.repUint32 = [0, 1, UInt32.max]

    let desc = CompatDescriptors.repeatedAllTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 9) as? [UInt32], [0, 1, UInt32.max])
      XCTAssertEqual(try msg.get(forField: 10) as? [UInt64], [0, 1, UInt64.max])
      XCTAssertEqual(try msg.get(forField: 5) as? [UInt32], [0, 1, UInt32.max])
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set([UInt32(0), UInt32(1), UInt32.max] as [UInt32], forField: 9)
    try dynamic.set([UInt64(0), UInt64(1), UInt64.max] as [UInt64], forField: 10)
    try dynamic.set([UInt32(0), UInt32(1), UInt32.max] as [UInt32], forField: 5)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_RepeatedAllTypes.self
    ) { decoded in
      XCTAssertEqual(decoded.repFixed32, [0, 1, UInt32.max])
      XCTAssertEqual(decoded.repFixed64, [0, 1, UInt64.max])
      XCTAssertEqual(decoded.repUint32, [0, 1, UInt32.max])
    }
  }

  // MARK: - Repeated string with empty and unicode

  func test_repeated_string_withEmptyAndUnicode_bidirectional() throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repString = ["", "hello", "Привет", "🎉", "中文", ""]

    let desc = CompatDescriptors.repeatedAllTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 14) as? [String], ["", "hello", "Привет", "🎉", "中文", ""])
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(["", "hello", "Привет", "🎉", "中文", ""] as [String], forField: 14)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_RepeatedAllTypes.self
    ) { decoded in
      XCTAssertEqual(decoded.repString, ["", "hello", "Привет", "🎉", "中文", ""])
    }
  }

  // MARK: - Repeated bytes (base64 array)

  func test_repeated_bytes_base64Array_bidirectional() throws {
    let b1 = Data([0x01, 0x02])
    let b2 = Data()
    let b3 = Data([0xFF, 0x00, 0x7F])

    var proto = Testcompat_RepeatedAllTypes()
    proto.repBytes = [b1, b2, b3]

    let desc = CompatDescriptors.repeatedAllTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let vals = try XCTUnwrap(try msg.get(forField: 15) as? [Data])
      XCTAssertEqual(vals, [b1, b2, b3])
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set([b1, b2, b3] as [Data], forField: 15)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_RepeatedAllTypes.self
    ) { decoded in
      XCTAssertEqual(decoded.repBytes, [b1, b2, b3])
    }
  }

  // MARK: - Repeated double/float with special values

  func test_repeated_double_specialValues_bidirectional() throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repDouble = [0.0, 1.5, -1.5, Double.nan, Double.infinity, -Double.infinity]

    let desc = CompatDescriptors.repeatedAllTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let vals = try XCTUnwrap(try msg.get(forField: 1) as? [Double])
      XCTAssertEqual(vals[0], 0.0)
      XCTAssertEqual(vals[1], 1.5)
      XCTAssertEqual(vals[2], -1.5)
      XCTAssertTrue(vals[3].isNaN)
      XCTAssertTrue(vals[4].isInfinite && vals[4] > 0)
      XCTAssertTrue(vals[5].isInfinite && vals[5] < 0)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set([0.0, 1.5, -1.5, Double.nan, Double.infinity, -Double.infinity] as [Double], forField: 1)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_RepeatedAllTypes.self
    ) { decoded in
      XCTAssertEqual(decoded.repDouble[0], 0.0)
      XCTAssertEqual(decoded.repDouble[1], 1.5)
      XCTAssertTrue(decoded.repDouble[3].isNaN)
      XCTAssertTrue(decoded.repDouble[4].isInfinite && decoded.repDouble[4] > 0)
    }
  }

  func test_repeated_float_specialValues_bidirectional() throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repFloat = [0.0, 1.5, -1.5, Float.nan, Float.infinity, -Float.infinity]

    let desc = CompatDescriptors.repeatedAllTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let vals = try XCTUnwrap(try msg.get(forField: 2) as? [Float])
      XCTAssertEqual(vals[0], 0.0)
      XCTAssertTrue(vals[3].isNaN)
      XCTAssertTrue(vals[4].isInfinite && vals[4] > 0)
      XCTAssertTrue(vals[5].isInfinite && vals[5] < 0)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(
      [Float(0.0), Float(1.5), Float(-1.5), Float.nan, Float.infinity, -Float.infinity] as [Float],
      forField: 2
    )
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_RepeatedAllTypes.self
    ) { decoded in
      XCTAssertEqual(decoded.repFloat[0], 0.0)
      XCTAssertTrue(decoded.repFloat[3].isNaN)
    }
  }

  // MARK: - Repeated bool

  func test_repeated_bool_bidirectional() throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repBool = [true, false, true, true, false]

    let desc = CompatDescriptors.repeatedAllTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 13) as? [Bool], [true, false, true, true, false])
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set([true, false, true, true, false] as [Bool], forField: 13)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_RepeatedAllTypes.self
    ) { decoded in
      XCTAssertEqual(decoded.repBool, [true, false, true, true, false])
    }
  }

  // MARK: - Repeated nested message

  func test_repeated_nestedMessage_bidirectional() throws {
    var proto = Testcompat_RepeatedAllTypes()
    var m1 = Testcompat_SimpleMessage()
    m1.id = 1
    m1.name = "first"
    var m2 = Testcompat_SimpleMessage()
    m2.id = 2
    m2.name = "second"
    proto.repSimple = [m1, m2]

    let desc = CompatDescriptors.repeatedAllTypes()
    let simpleDesc = CompatDescriptors.simpleMessage()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let msgs = try XCTUnwrap(try msg.get(forField: 18) as? [DynamicMessage])
      XCTAssertEqual(msgs.count, 2)
      XCTAssertEqual(try msgs[0].get(forField: 1) as? Int32, 1)
      XCTAssertEqual(try msgs[0].get(forField: 2) as? String, "first")
      XCTAssertEqual(try msgs[1].get(forField: 1) as? Int32, 2)
      XCTAssertEqual(try msgs[1].get(forField: 2) as? String, "second")
    }

    var inner1 = DynamicMessage(descriptor: simpleDesc)
    try inner1.set(Int32(1), forField: 1)
    try inner1.set("first", forField: 2)
    var inner2 = DynamicMessage(descriptor: simpleDesc)
    try inner2.set(Int32(2), forField: 1)
    try inner2.set("second", forField: 2)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set([inner1, inner2] as [DynamicMessage], forField: 18)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_RepeatedAllTypes.self
    ) { decoded in
      XCTAssertEqual(decoded.repSimple.count, 2)
      XCTAssertEqual(decoded.repSimple[0].id, 1)
      XCTAssertEqual(decoded.repSimple[0].name, "first")
    }
  }

  // MARK: - Repeated enum by name

  func test_repeated_enum_byName_bidirectional() throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repEnum = [.active, .inactive, .deleted, .unspecified]

    let desc = CompatDescriptors.repeatedAllTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let vals = try XCTUnwrap(try msg.get(forField: 17) as? [Int32])
      XCTAssertEqual(vals, [1, 2, 3, 0])
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set([Int32(1), Int32(2), Int32(3), Int32(0)] as [Int32], forField: 17)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_RepeatedAllTypes.self
    ) { decoded in
      XCTAssertEqual(decoded.repEnum, [.active, .inactive, .deleted, .unspecified])
    }
  }

  // MARK: - Empty repeated → omitted

  func test_repeated_empty_omitted() throws {
    let proto = Testcompat_RepeatedAllTypes()
    let jsonStr = try proto.jsonString()
    XCTAssertEqual(jsonStr, "{}")

    let desc = CompatDescriptors.repeatedAllTypes()
    let dynamic = DynamicMessage(descriptor: desc)
    let jsonData = try CompatHelpers.makeSerializer(registry: registry).serialize(dynamic)
    let ourJson = try XCTUnwrap(String(data: jsonData, encoding: .utf8))
    XCTAssertEqual(ourJson, "{}")
  }

  // MARK: - Large array (100 elements)

  func test_repeated_largeArray_100elements_bidirectional() throws {
    var proto = Testcompat_RepeatedAllTypes()
    proto.repInt32 = (1...100).map { Int32($0) }

    let desc = CompatDescriptors.repeatedAllTypes()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let vals = try XCTUnwrap(try msg.get(forField: 3) as? [Int32])
      XCTAssertEqual(vals.count, 100)
      XCTAssertEqual(vals[0], 1)
      XCTAssertEqual(vals[99], 100)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set((1...100).map { Int32($0) } as [Int32], forField: 3)
    try CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_RepeatedAllTypes.self
    ) { decoded in
      XCTAssertEqual(decoded.repInt32.count, 100)
      XCTAssertEqual(decoded.repInt32[0], 1)
      XCTAssertEqual(decoded.repInt32[99], 100)
    }
  }
}
