// JSONCompatOneofTests.swift
// SwiftProtoReflectTests
//
// Group 4: Oneof Fields — bidirectional JSON compatibility tests.
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class JSONCompatOneofTests: XCTestCase {

  private var registry: TypeRegistry!

  override func setUp() {
    super.setUp()
    registry = try? CompatDescriptors.fullRegistry()
  }

  override func tearDown() {
    registry = nil
    super.tearDown()
  }

  // MARK: - Oneof scalars: each variant

  func test_oneof_scalars_double_bidirectional() throws {
    var proto = Testcompat_OneofScalars()
    proto.doubleVal = 3.14

    let desc = CompatDescriptors.oneofScalars()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? Double, 3.14)
      XCTAssertNil(try msg.get(forField: 3) as? Int32)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Double(3.14), forField: 1)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_OneofScalars.self) {
      decoded in
      if case .doubleVal(let v) = decoded.value {
        XCTAssertEqual(v, 3.14)
      }
      else {
        XCTFail("wrong case")
      }
    }
  }

  func test_oneof_scalars_int32_bidirectional() throws {
    var proto = Testcompat_OneofScalars()
    proto.int32Val = -42

    let desc = CompatDescriptors.oneofScalars()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 3) as? Int32, -42)
      XCTAssertNil(try msg.get(forField: 1) as? Double)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(-42), forField: 3)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_OneofScalars.self) {
      decoded in
      if case .int32Val(let v) = decoded.value {
        XCTAssertEqual(v, -42)
      }
      else {
        XCTFail("wrong case")
      }
    }
  }

  func test_oneof_scalars_string_bidirectional() throws {
    var proto = Testcompat_OneofScalars()
    proto.stringVal = "hello world"

    let desc = CompatDescriptors.oneofScalars()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 8) as? String, "hello world")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("hello world", forField: 8)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_OneofScalars.self) {
      decoded in
      if case .stringVal(let v) = decoded.value {
        XCTAssertEqual(v, "hello world")
      }
      else {
        XCTFail("wrong case")
      }
    }
  }

  func test_oneof_scalars_bytes_bidirectional() throws {
    let testBytes = Data([0xDE, 0xAD, 0xBE, 0xEF])
    var proto = Testcompat_OneofScalars()
    proto.bytesVal = testBytes

    let desc = CompatDescriptors.oneofScalars()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 9) as? Data, testBytes)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(testBytes, forField: 9)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_OneofScalars.self) {
      decoded in
      if case .bytesVal(let v) = decoded.value {
        XCTAssertEqual(v, testBytes)
      }
      else {
        XCTFail("wrong case")
      }
    }
  }

  func test_oneof_scalars_bool_bidirectional() throws {
    var proto = Testcompat_OneofScalars()
    proto.boolVal = true

    let desc = CompatDescriptors.oneofScalars()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 7) as? Bool, true)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(true, forField: 7)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_OneofScalars.self) {
      decoded in
      if case .boolVal(let v) = decoded.value {
        XCTAssertTrue(v)
      }
      else {
        XCTFail("wrong case")
      }
    }
  }

  // MARK: - Oneof unset → empty JSON

  func test_oneof_unset_emptyJSON() throws {
    let proto = Testcompat_OneofScalars()
    let jsonStr = try proto.jsonString()
    XCTAssertEqual(jsonStr, "{}")

    let desc = CompatDescriptors.oneofScalars()
    let dynamic = DynamicMessage(descriptor: desc)
    let jsonData = try CompatHelpers.makeSerializer(registry: registry).serialize(dynamic)
    let ourJson = try XCTUnwrap(String(data: jsonData, encoding: .utf8))
    XCTAssertEqual(ourJson, "{}")
  }

  // MARK: - Oneof complex: message variant

  func test_oneof_complex_message_bidirectional() throws {
    var proto = Testcompat_OneofComplex()
    var inner = Testcompat_ScalarMessage()
    inner.int32Field = 99
    inner.stringField = "inner"
    proto.msgVal = inner

    let desc = CompatDescriptors.oneofComplex()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let inner = try XCTUnwrap(try msg.get(forField: 3) as? DynamicMessage)
      XCTAssertEqual(try inner.get(forField: 3) as? Int32, 99)
      XCTAssertEqual(try inner.get(forField: 14) as? String, "inner")
    }

    let innerDesc = CompatDescriptors.scalarMessage()
    var innerDynamic = DynamicMessage(descriptor: innerDesc)
    try innerDynamic.set(Int32(99), forField: 3)
    try innerDynamic.set("inner", forField: 14)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(innerDynamic, forField: 3)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_OneofComplex.self) {
      decoded in
      if case .msgVal(let m) = decoded.choice {
        XCTAssertEqual(m.int32Field, 99)
        XCTAssertEqual(m.stringField, "inner")
      }
      else {
        XCTFail("wrong case")
      }
    }
  }

  // MARK: - Oneof complex: enum variant

  func test_oneof_complex_enum_bidirectional() throws {
    var proto = Testcompat_OneofComplex()
    proto.enumVal = .active

    let desc = CompatDescriptors.oneofComplex()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 5) as? Int32, 1)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(1), forField: 5)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_OneofComplex.self) {
      decoded in
      if case .enumVal(let v) = decoded.choice {
        XCTAssertEqual(v, .active)
      }
      else {
        XCTFail("wrong case")
      }
    }
  }

  // MARK: - Oneof complex: regular field alongside oneof

  func test_oneof_complex_regularFieldWithOneof_bidirectional() throws {
    var proto = Testcompat_OneofComplex()
    proto.intVal = 7
    proto.name = "outside"

    let desc = CompatDescriptors.oneofComplex()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? Int32, 7)
      XCTAssertEqual(try msg.get(forField: 10) as? String, "outside")
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(7), forField: 1)
    try dynamic.set("outside", forField: 10)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_OneofComplex.self) {
      decoded in
      if case .intVal(let v) = decoded.choice {
        XCTAssertEqual(v, 7)
      }
      else {
        XCTFail("wrong case")
      }
      XCTAssertEqual(decoded.name, "outside")
    }
  }

  // MARK: - Multiple oneofs: first_choice set

  func test_multiOneof_firstChoice_bidirectional() throws {
    var proto = Testcompat_MultiOneof()
    proto.firstInt = 42
    proto.label = "lbl"

    let desc = CompatDescriptors.multiOneof()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 1) as? Int32, 42)
      XCTAssertEqual(try msg.get(forField: 20) as? String, "lbl")
      XCTAssertNil(try msg.get(forField: 4) as? Double)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int32(42), forField: 1)
    try dynamic.set("lbl", forField: 20)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MultiOneof.self) {
      decoded in
      if case .firstInt(let v) = decoded.firstChoice {
        XCTAssertEqual(v, 42)
      }
      else {
        XCTFail("wrong first")
      }
      XCTAssertEqual(decoded.label, "lbl")
    }
  }

  // MARK: - Multiple oneofs: second_choice set

  func test_multiOneof_secondChoice_bidirectional() throws {
    var proto = Testcompat_MultiOneof()
    proto.secondDbl = 2.71

    let desc = CompatDescriptors.multiOneof()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 4) as? Double, 2.71)
      XCTAssertNil(try msg.get(forField: 1) as? Int32)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Double(2.71), forField: 4)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MultiOneof.self) {
      decoded in
      if case .secondDbl(let v) = decoded.secondChoice {
        XCTAssertEqual(v, 2.71)
      }
      else {
        XCTFail("wrong second")
      }
    }
  }

  // MARK: - Oneof int64 (quoted string) variant

  func test_oneof_scalars_int64_bidirectional() throws {
    var proto = Testcompat_OneofScalars()
    proto.int64Val = Int64.max

    let desc = CompatDescriptors.oneofScalars()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 4) as? Int64, Int64.max)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Int64.max, forField: 4)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_OneofScalars.self) {
      decoded in
      if case .int64Val(let v) = decoded.value {
        XCTAssertEqual(v, Int64.max)
      }
      else {
        XCTFail("wrong case")
      }
    }
  }

  // MARK: - Oneof float variant

  func test_oneof_scalars_float_bidirectional() throws {
    var proto = Testcompat_OneofScalars()
    proto.floatVal = 1.5

    let desc = CompatDescriptors.oneofScalars()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 2) as? Float, 1.5)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(Float(1.5), forField: 2)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_OneofScalars.self) {
      decoded in
      if case .floatVal(let v) = decoded.value {
        XCTAssertEqual(v, 1.5)
      }
      else {
        XCTFail("wrong case")
      }
    }
  }

  // MARK: - Oneof uint32 variant

  func test_oneof_scalars_uint32_bidirectional() throws {
    var proto = Testcompat_OneofScalars()
    proto.uint32Val = UInt32.max

    let desc = CompatDescriptors.oneofScalars()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 5) as? UInt32, UInt32.max)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(UInt32.max, forField: 5)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_OneofScalars.self) {
      decoded in
      if case .uint32Val(let v) = decoded.value {
        XCTAssertEqual(v, UInt32.max)
      }
      else {
        XCTFail("wrong case")
      }
    }
  }

  // MARK: - Oneof uint64 variant

  func test_oneof_scalars_uint64_bidirectional() throws {
    var proto = Testcompat_OneofScalars()
    proto.uint64Val = UInt64.max

    let desc = CompatDescriptors.oneofScalars()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 6) as? UInt64, UInt64.max)
    }

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(UInt64.max, forField: 6)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_OneofScalars.self) {
      decoded in
      if case .uint64Val(let v) = decoded.value {
        XCTAssertEqual(v, UInt64.max)
      }
      else {
        XCTFail("wrong case")
      }
    }
  }

  // MARK: - WKT Timestamp in oneof

  func test_oneof_wkt_timestamp_bidirectional() throws {
    var proto = Testcompat_OneofWKT()
    proto.tsVal.seconds = 1_700_000_000
    proto.tsVal.nanos = 0
    proto.tag = 5

    let desc = CompatDescriptors.oneofWKT()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let tsDyn = try XCTUnwrap(try msg.get(forField: 1) as? DynamicMessage)
      XCTAssertEqual(try tsDyn.get(forField: 1) as? Int64, 1_700_000_000)
      XCTAssertEqual(try msg.get(forField: 10) as? Int32, 5)
    }

    let tsDesc = CompatDescriptors.wktTimestamp()
    var tsDyn = DynamicMessage(descriptor: tsDesc)
    try tsDyn.set(Int64(1_700_000_000), forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(tsDyn, forField: 1)
    try dynamic.set(Int32(5), forField: 10)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_OneofWKT.self) {
      decoded in
      if case .tsVal(let ts) = decoded.wktChoice {
        XCTAssertEqual(ts.seconds, 1_700_000_000)
      }
      else {
        XCTFail("wrong case")
      }
      XCTAssertEqual(decoded.tag, 5)
    }
  }

  // MARK: - WKT Struct in oneof

  func test_oneof_wkt_struct_bidirectional() throws {
    var proto = Testcompat_OneofWKT()
    proto.structVal.fields["key"] = Google_Protobuf_Value.with { $0.stringValue = "val" }

    let desc = CompatDescriptors.oneofWKT()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      let structDyn = try XCTUnwrap(try msg.get(forField: 4) as? DynamicMessage)
      XCTAssertEqual(structDyn.descriptor.name, "Struct")
    }

    let structDesc = CompatDescriptors.wktStruct()
    let structDyn = DynamicMessage(descriptor: structDesc)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set(structDyn, forField: 4)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_OneofWKT.self) {
      decoded in
      if case .structVal = decoded.wktChoice {
      }
      else {
        XCTFail("wrong case")
      }
    }
  }

  // MARK: - MultiOneof: all three blocks active simultaneously

  func test_multiOneof_allActive_bidirectional() throws {
    var proto = Testcompat_MultiOneof()
    proto.firstStr = "first"
    proto.secondEnum = .active
    var simpleMsg = Testcompat_SimpleMessage()
    simpleMsg.id = 7
    proto.thirdMsg = simpleMsg
    proto.label = "all"

    let desc = CompatDescriptors.multiOneof()
    try CompatHelpers.assertProtocToUs(proto: proto, descriptor: desc, registry: registry) { msg in
      XCTAssertEqual(try msg.get(forField: 2) as? String, "first")
      XCTAssertEqual(try msg.get(forField: 6) as? Int32, 1)
      let thirdMsg = try XCTUnwrap(try msg.get(forField: 7) as? DynamicMessage)
      XCTAssertEqual(try thirdMsg.get(forField: 1) as? Int32, 7)
      XCTAssertEqual(try msg.get(forField: 20) as? String, "all")
    }

    let simpleDesc = CompatDescriptors.simpleMessage()
    var simpleDyn = DynamicMessage(descriptor: simpleDesc)
    try simpleDyn.set(Int32(7), forField: 1)

    var dynamic = DynamicMessage(descriptor: desc)
    try dynamic.set("first", forField: 2)
    try dynamic.set(Int32(1), forField: 6)
    try dynamic.set(simpleDyn, forField: 7)
    try dynamic.set("all", forField: 20)
    try CompatHelpers.assertUsToProtoc(dynamic: dynamic, registry: registry, protoType: Testcompat_MultiOneof.self) {
      decoded in
      if case .firstStr(let v) = decoded.firstChoice {
        XCTAssertEqual(v, "first")
      }
      else {
        XCTFail("first wrong")
      }
      if case .secondEnum(let v) = decoded.secondChoice {
        XCTAssertEqual(v, .active)
      }
      else {
        XCTFail("second wrong")
      }
      if case .thirdMsg(let m) = decoded.thirdChoice {
        XCTAssertEqual(m.id, 7)
      }
      else {
        XCTFail("third wrong")
      }
      XCTAssertEqual(decoded.label, "all")
    }
  }
}
