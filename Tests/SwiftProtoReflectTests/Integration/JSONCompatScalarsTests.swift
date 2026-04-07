// JSONCompatScalarsTests.swift
// SwiftProtoReflectTests
//
// Group 1: All Scalar Types — bidirectional JSON compatibility tests.
// SwiftProtobuf generated types are the source of truth.
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class JSONCompatScalarsTests: XCTestCase {

  private var registry: TypeRegistry!

  override func setUp() async throws {
    try await super.setUp()
    registry = try? await CompatDescriptors.fullRegistry()
  }

  override func tearDown() async throws {
    registry = nil
    try await super.tearDown()
  }

  // MARK: - All 15 types with non-default values

  func test_scalars_allTypes_bidirectional() async throws {
    // Direction A: SwiftProtobuf → JSON → our deserializer
    var proto = Testcompat_ScalarMessage()
    proto.doubleField = 1.5
    proto.floatField = 2.5
    proto.int32Field = 42
    proto.int64Field = 9_000_000_000
    proto.uint32Field = 100
    proto.uint64Field = 18_000_000_000
    proto.sint32Field = -10
    proto.sint64Field = -9_000_000_000
    proto.fixed32Field = 77
    proto.fixed64Field = 88
    proto.sfixed32Field = -5
    proto.sfixed64Field = -6
    proto.boolField = true
    proto.stringField = "hello"
    proto.bytesField = Data([0x01, 0x02, 0x03])

    let desc = CompatDescriptors.scalarMessage()
    let msg = try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? Double, 1.5)
      XCTAssertEqual(try msg.get(forField: 2) as? Float, 2.5)
      XCTAssertEqual(try msg.get(forField: 3) as? Int32, 42)
      XCTAssertEqual(try msg.get(forField: 4) as? Int64, 9_000_000_000)
      XCTAssertEqual(try msg.get(forField: 5) as? UInt32, 100)
      XCTAssertEqual(try msg.get(forField: 6) as? UInt64, 18_000_000_000)
      XCTAssertEqual(try msg.get(forField: 7) as? Int32, -10)
      XCTAssertEqual(try msg.get(forField: 8) as? Int64, -9_000_000_000)
      XCTAssertEqual(try msg.get(forField: 9) as? UInt32, 77)
      XCTAssertEqual(try msg.get(forField: 10) as? UInt64, 88)
      XCTAssertEqual(try msg.get(forField: 11) as? Int32, -5)
      XCTAssertEqual(try msg.get(forField: 12) as? Int64, -6)
      XCTAssertEqual(try msg.get(forField: 13) as? Bool, true)
      XCTAssertEqual(try msg.get(forField: 14) as? String, "hello")
      XCTAssertEqual(try msg.get(forField: 15) as? Data, Data([0x01, 0x02, 0x03]))
    }

    // Direction B: build DynamicMessage → JSON → SwiftProtobuf
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Double(1.5), forField: 1)
    try dynamic.set(Float(2.5), forField: 2)
    try dynamic.set(Int32(42), forField: 3)
    try dynamic.set(Int64(9_000_000_000), forField: 4)
    try dynamic.set(UInt32(100), forField: 5)
    try dynamic.set(UInt64(18_000_000_000), forField: 6)
    try dynamic.set(Int32(-10), forField: 7)
    try dynamic.set(Int64(-9_000_000_000), forField: 8)
    try dynamic.set(UInt32(77), forField: 9)
    try dynamic.set(UInt64(88), forField: 10)
    try dynamic.set(Int32(-5), forField: 11)
    try dynamic.set(Int64(-6), forField: 12)
    try dynamic.set(true, forField: 13)
    try dynamic.set("hello", forField: 14)
    try dynamic.set(Data([0x01, 0x02, 0x03]), forField: 15)

    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_ScalarMessage.self
    ) {
      decoded in
      XCTAssertEqual(decoded.doubleField, 1.5)
      XCTAssertEqual(decoded.floatField, 2.5)
      XCTAssertEqual(decoded.int32Field, 42)
      XCTAssertEqual(decoded.int64Field, 9_000_000_000)
      XCTAssertEqual(decoded.uint32Field, 100)
      XCTAssertEqual(decoded.uint64Field, 18_000_000_000)
      XCTAssertEqual(decoded.sint32Field, -10)
      XCTAssertEqual(decoded.sint64Field, -9_000_000_000)
      XCTAssertEqual(decoded.fixed32Field, 77)
      XCTAssertEqual(decoded.fixed64Field, 88)
      XCTAssertEqual(decoded.sfixed32Field, -5)
      XCTAssertEqual(decoded.sfixed64Field, -6)
      XCTAssertEqual(decoded.boolField, true)
      XCTAssertEqual(decoded.stringField, "hello")
      XCTAssertEqual(decoded.bytesField, Data([0x01, 0x02, 0x03]))
    }
    _ = msg
  }

  // MARK: - int64/uint64 as quoted strings in JSON

  func test_scalars_int64AsQuotedString_bidirectional() async throws {
    var proto = Testcompat_ScalarMessage()
    proto.int64Field = Int64.max

    let desc = CompatDescriptors.scalarMessage()
    // Direction A: protoc emits int64 as quoted string — we must parse it
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 4) as? Int64, Int64.max)
    }

    // Direction B: we emit int64 as quoted string — protoc must parse it
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int64.max, forField: 4)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_ScalarMessage.self
    ) {
      decoded in
      XCTAssertEqual(decoded.int64Field, Int64.max)
    }
  }

  func test_scalars_uint64AsQuotedString_bidirectional() async throws {
    var proto = Testcompat_ScalarMessage()
    proto.uint64Field = UInt64.max

    let desc = CompatDescriptors.scalarMessage()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 6) as? UInt64, UInt64.max)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(UInt64.max, forField: 6)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_ScalarMessage.self
    ) {
      decoded in
      XCTAssertEqual(decoded.uint64Field, UInt64.max)
    }
  }

  func test_scalars_sint_sfixed_types_bidirectional() async throws {
    var proto = Testcompat_ScalarMessage()
    proto.sint32Field = Int32.min
    proto.sint64Field = Int64.min
    proto.sfixed32Field = Int32.min
    proto.sfixed64Field = Int64.min

    let desc = CompatDescriptors.scalarMessage()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 7) as? Int32, Int32.min)
      XCTAssertEqual(try msg.get(forField: 8) as? Int64, Int64.min)
      XCTAssertEqual(try msg.get(forField: 11) as? Int32, Int32.min)
      XCTAssertEqual(try msg.get(forField: 12) as? Int64, Int64.min)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32.min, forField: 7)
    try dynamic.set(Int64.min, forField: 8)
    try dynamic.set(Int32.min, forField: 11)
    try dynamic.set(Int64.min, forField: 12)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_ScalarMessage.self
    ) {
      decoded in
      XCTAssertEqual(decoded.sint32Field, Int32.min)
      XCTAssertEqual(decoded.sint64Field, Int64.min)
      XCTAssertEqual(decoded.sfixed32Field, Int32.min)
      XCTAssertEqual(decoded.sfixed64Field, Int64.min)
    }
  }

  // MARK: - bytes as base64

  func test_scalars_bytes_base64_bidirectional() async throws {
    let testBytes = Data([0x00, 0xFF, 0x7F, 0x80, 0x42, 0xDE, 0xAD, 0xBE, 0xEF])

    var proto = Testcompat_ScalarMessage()
    proto.bytesField = testBytes

    let desc = CompatDescriptors.scalarMessage()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 15) as? Data, testBytes)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(testBytes, forField: 15)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_ScalarMessage.self
    ) {
      decoded in
      XCTAssertEqual(decoded.bytesField, testBytes)
    }
  }

  // MARK: - float/double NaN

  func test_scalars_float_nan_bidirectional() async throws {
    var proto = Testcompat_ScalarMessage()
    proto.floatField = Float.nan

    let desc = CompatDescriptors.scalarMessage()
    // Direction A
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let val = try XCTUnwrap(try msg.get(forField: 2) as? Float)
      XCTAssertTrue(val.isNaN)
    }

    // Direction B
    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Float.nan, forField: 2)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_ScalarMessage.self
    ) {
      decoded in
      XCTAssertTrue(decoded.floatField.isNaN)
    }
  }

  func test_scalars_float_infinity_bidirectional() async throws {
    var proto = Testcompat_ScalarMessage()
    proto.floatField = Float.infinity

    let desc = CompatDescriptors.scalarMessage()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let val = try XCTUnwrap(try msg.get(forField: 2) as? Float)
      XCTAssertTrue(val.isInfinite && val > 0)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Float.infinity, forField: 2)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_ScalarMessage.self
    ) {
      decoded in
      XCTAssertTrue(decoded.floatField.isInfinite && decoded.floatField > 0)
    }
  }

  func test_scalars_float_negInfinity_bidirectional() async throws {
    var proto = Testcompat_ScalarMessage()
    proto.floatField = -Float.infinity

    let desc = CompatDescriptors.scalarMessage()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let val = try XCTUnwrap(try msg.get(forField: 2) as? Float)
      XCTAssertTrue(val.isInfinite && val < 0)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(-Float.infinity, forField: 2)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_ScalarMessage.self
    ) {
      decoded in
      XCTAssertTrue(decoded.floatField.isInfinite && decoded.floatField < 0)
    }
  }

  // MARK: - Max values for integer types

  func test_scalars_maxValues_allIntTypes_bidirectional() async throws {
    var proto = Testcompat_ScalarMessage()
    proto.int32Field = Int32.max
    proto.int64Field = Int64.max
    proto.uint32Field = UInt32.max
    proto.uint64Field = UInt64.max
    proto.sint32Field = Int32.max
    proto.sint64Field = Int64.max
    proto.fixed32Field = UInt32.max
    proto.fixed64Field = UInt64.max
    proto.sfixed32Field = Int32.max
    proto.sfixed64Field = Int64.max

    let desc = CompatDescriptors.scalarMessage()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 3) as? Int32, Int32.max)
      XCTAssertEqual(try msg.get(forField: 4) as? Int64, Int64.max)
      XCTAssertEqual(try msg.get(forField: 5) as? UInt32, UInt32.max)
      XCTAssertEqual(try msg.get(forField: 6) as? UInt64, UInt64.max)
      XCTAssertEqual(try msg.get(forField: 7) as? Int32, Int32.max)
      XCTAssertEqual(try msg.get(forField: 8) as? Int64, Int64.max)
      XCTAssertEqual(try msg.get(forField: 9) as? UInt32, UInt32.max)
      XCTAssertEqual(try msg.get(forField: 10) as? UInt64, UInt64.max)
      XCTAssertEqual(try msg.get(forField: 11) as? Int32, Int32.max)
      XCTAssertEqual(try msg.get(forField: 12) as? Int64, Int64.max)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32.max, forField: 3)
    try dynamic.set(Int64.max, forField: 4)
    try dynamic.set(UInt32.max, forField: 5)
    try dynamic.set(UInt64.max, forField: 6)
    try dynamic.set(Int32.max, forField: 7)
    try dynamic.set(Int64.max, forField: 8)
    try dynamic.set(UInt32.max, forField: 9)
    try dynamic.set(UInt64.max, forField: 10)
    try dynamic.set(Int32.max, forField: 11)
    try dynamic.set(Int64.max, forField: 12)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_ScalarMessage.self
    ) {
      decoded in
      XCTAssertEqual(decoded.int32Field, Int32.max)
      XCTAssertEqual(decoded.int64Field, Int64.max)
      XCTAssertEqual(decoded.uint32Field, UInt32.max)
      XCTAssertEqual(decoded.uint64Field, UInt64.max)
      XCTAssertEqual(decoded.sint32Field, Int32.max)
      XCTAssertEqual(decoded.sint64Field, Int64.max)
      XCTAssertEqual(decoded.fixed32Field, UInt32.max)
      XCTAssertEqual(decoded.fixed64Field, UInt64.max)
      XCTAssertEqual(decoded.sfixed32Field, Int32.max)
      XCTAssertEqual(decoded.sfixed64Field, Int64.max)
    }
  }

  // MARK: - Min values for signed types

  func test_scalars_minValues_allIntTypes_bidirectional() async throws {
    var proto = Testcompat_ScalarMessage()
    proto.int32Field = Int32.min
    proto.int64Field = Int64.min
    proto.sint32Field = Int32.min
    proto.sint64Field = Int64.min
    proto.sfixed32Field = Int32.min
    proto.sfixed64Field = Int64.min

    let desc = CompatDescriptors.scalarMessage()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 3) as? Int32, Int32.min)
      XCTAssertEqual(try msg.get(forField: 4) as? Int64, Int64.min)
      XCTAssertEqual(try msg.get(forField: 7) as? Int32, Int32.min)
      XCTAssertEqual(try msg.get(forField: 8) as? Int64, Int64.min)
      XCTAssertEqual(try msg.get(forField: 11) as? Int32, Int32.min)
      XCTAssertEqual(try msg.get(forField: 12) as? Int64, Int64.min)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32.min, forField: 3)
    try dynamic.set(Int64.min, forField: 4)
    try dynamic.set(Int32.min, forField: 7)
    try dynamic.set(Int64.min, forField: 8)
    try dynamic.set(Int32.min, forField: 11)
    try dynamic.set(Int64.min, forField: 12)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_ScalarMessage.self
    ) {
      decoded in
      XCTAssertEqual(decoded.int32Field, Int32.min)
      XCTAssertEqual(decoded.int64Field, Int64.min)
      XCTAssertEqual(decoded.sint32Field, Int32.min)
      XCTAssertEqual(decoded.sint64Field, Int64.min)
      XCTAssertEqual(decoded.sfixed32Field, Int32.min)
      XCTAssertEqual(decoded.sfixed64Field, Int64.min)
    }
  }

  // MARK: - All defaults → empty JSON in proto3

  func test_scalars_allDefaults_emptyJSON() async throws {
    // proto3 default message → JSON should be "{}"
    let proto = Testcompat_ScalarMessage()
    let jsonStr = try proto.jsonString()
    XCTAssertEqual(jsonStr, "{}")

    // Our serializer: DynamicMessage with all defaults → "{}"
    let desc = CompatDescriptors.scalarMessage()
    let dynamic = DynamicMessage(descriptor: desc)
    let jsonData = try await CompatHelpers.makeSerializer(registry: registry).serialize(dynamic)
    let ourJson = try XCTUnwrap(String(data: jsonData, encoding: .utf8))
    XCTAssertEqual(ourJson, "{}")
  }

  // MARK: - Single field set, rest default

  func test_scalars_singleFieldSet_restDefault_bidirectional() async throws {
    var proto = Testcompat_ScalarMessage()
    proto.stringField = "only_this"

    let desc = CompatDescriptors.scalarMessage()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 14) as? String, "only_this")
      // All others should be nil/default
      XCTAssertNil(try msg.get(forField: 1) as? Double)
      XCTAssertNil(try msg.get(forField: 3) as? Int32)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("only_this", forField: 14)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_ScalarMessage.self
    ) {
      decoded in
      XCTAssertEqual(decoded.stringField, "only_this")
      XCTAssertEqual(decoded.int32Field, 0)
      XCTAssertFalse(decoded.boolField)
    }
  }

  // MARK: - double NaN

  func test_scalars_double_nan_bidirectional() async throws {
    var proto = Testcompat_ScalarMessage()
    proto.doubleField = Double.nan

    let desc = CompatDescriptors.scalarMessage()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let val = try XCTUnwrap(try msg.get(forField: 1) as? Double)
      XCTAssertTrue(val.isNaN)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Double.nan, forField: 1)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_ScalarMessage.self
    ) {
      decoded in
      XCTAssertTrue(decoded.doubleField.isNaN)
    }
  }

  func test_scalars_double_infinity_bidirectional() async throws {
    var proto = Testcompat_ScalarMessage()
    proto.doubleField = Double.infinity

    let desc = CompatDescriptors.scalarMessage()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let val = try XCTUnwrap(try msg.get(forField: 1) as? Double)
      XCTAssertTrue(val.isInfinite && val > 0)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Double.infinity, forField: 1)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_ScalarMessage.self
    ) {
      decoded in
      XCTAssertTrue(decoded.doubleField.isInfinite && decoded.doubleField > 0)
    }
  }

  func test_scalars_double_negInfinity_bidirectional() async throws {
    var proto = Testcompat_ScalarMessage()
    proto.doubleField = -Double.infinity

    let desc = CompatDescriptors.scalarMessage()
    try await CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let val = try XCTUnwrap(try msg.get(forField: 1) as? Double)
      XCTAssertTrue(val.isInfinite && val < 0)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(-Double.infinity, forField: 1)
    try await CompatHelpers.assertUsToProtoc(
      dynamic: dynamic,
      registry: registry,
      protoType: Testcompat_ScalarMessage.self
    ) {
      decoded in
      XCTAssertTrue(decoded.doubleField.isInfinite && decoded.doubleField < 0)
    }
  }
}
