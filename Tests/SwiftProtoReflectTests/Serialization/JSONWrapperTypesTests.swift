//
// JSONWrapperTypesTests.swift
// SwiftProtoReflect
//
// Created: 2026-04-05
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class JSONWrapperTypesTests: XCTestCase {

  // MARK: - Helpers

  private func makeWrapperDescriptor(name: String, fullName: String, fieldType: FieldType) -> MessageDescriptor {
    var desc = MessageDescriptor(name: name, fullName: fullName)
    desc.addField(FieldDescriptor(name: "value", number: 1, type: fieldType))
    return desc
  }

  private func canonicalSerializer() -> JSONSerializer {
    JSONSerializer(
      options: JSONSerializationOptions(
        useCanonicalWellKnownTypeEncoding: true,
        typeRegistry: TypeRegistry()
      )
    )
  }

  private func deserializer() -> JSONDeserializer {
    JSONDeserializer(options: JSONDeserializationOptions(typeRegistry: TypeRegistry()))
  }

  // MARK: - Encoder tests

  func test_serialize_doubleValue_producesNumber() async throws {
    let desc = makeWrapperDescriptor(name: "DoubleValue", fullName: WellKnownTypeNames.doubleValue, fieldType: .double)
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Double(3.14), forField: 1)
    let data = try await canonicalSerializer().serialize(msg)
    let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
    let doubleVal = try XCTUnwrap(json as? Double)
    XCTAssertEqual(doubleVal, 3.14, accuracy: 0.0001)
  }

  func test_serialize_floatValue_producesNumber() async throws {
    let desc = makeWrapperDescriptor(name: "FloatValue", fullName: WellKnownTypeNames.floatValue, fieldType: .float)
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Float(1.5), forField: 1)
    let data = try await canonicalSerializer().serialize(msg)
    let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
    let floatVal = try XCTUnwrap((json as? NSNumber)?.doubleValue)
    XCTAssertEqual(floatVal, 1.5, accuracy: 0.001)
  }

  func test_serialize_int64Value_producesString() async throws {
    let desc = makeWrapperDescriptor(name: "Int64Value", fullName: WellKnownTypeNames.int64Value, fieldType: .int64)
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int64(9_007_199_254_740_993), forField: 1)
    let data = try await canonicalSerializer().serialize(msg)
    let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
    XCTAssertEqual(json as? String, "9007199254740993")
  }

  func test_serialize_uint64Value_producesString() async throws {
    let desc = makeWrapperDescriptor(
      name: "UInt64Value",
      fullName: WellKnownTypeNames.uint64Value,
      fieldType: .uint64
    )
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(UInt64(18_446_744_073_709_551_615), forField: 1)
    let data = try await canonicalSerializer().serialize(msg)
    let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
    XCTAssertEqual(json as? String, "18446744073709551615")
  }

  func test_serialize_int32Value_producesNumber() async throws {
    let desc = makeWrapperDescriptor(name: "Int32Value", fullName: WellKnownTypeNames.int32Value, fieldType: .int32)
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(42), forField: 1)
    let data = try await canonicalSerializer().serialize(msg)
    let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
    XCTAssertEqual(json as? Int, 42)
  }

  func test_serialize_uint32Value_producesNumber() async throws {
    let desc = makeWrapperDescriptor(
      name: "UInt32Value",
      fullName: WellKnownTypeNames.uint32Value,
      fieldType: .uint32
    )
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(UInt32(100), forField: 1)
    let data = try await canonicalSerializer().serialize(msg)
    let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
    XCTAssertEqual(json as? Int, 100)
  }

  func test_serialize_boolValue_producesBool() async throws {
    let desc = makeWrapperDescriptor(name: "BoolValue", fullName: WellKnownTypeNames.boolValue, fieldType: .bool)
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(true, forField: 1)
    let data = try await canonicalSerializer().serialize(msg)
    let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
    XCTAssertEqual(json as? Bool, true)
  }

  func test_serialize_stringValue_producesString() async throws {
    let desc = makeWrapperDescriptor(name: "StringValue", fullName: WellKnownTypeNames.stringValue, fieldType: .string)
    var msg = DynamicMessage(descriptor: desc)
    try msg.set("hello", forField: 1)
    let data = try await canonicalSerializer().serialize(msg)
    let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
    XCTAssertEqual(json as? String, "hello")
  }

  func test_serialize_bytesValue_producesBase64String() async throws {
    let desc = makeWrapperDescriptor(name: "BytesValue", fullName: WellKnownTypeNames.bytesValue, fieldType: .bytes)
    var msg = DynamicMessage(descriptor: desc)
    let bytes = Data([0x01, 0x02, 0x03])
    try msg.set(bytes, forField: 1)
    let data = try await canonicalSerializer().serialize(msg)
    let json = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
    let base64 = try XCTUnwrap(json as? String)
    XCTAssertEqual(Data(base64Encoded: base64), bytes)
  }

  // MARK: - Decoder tests

  func test_deserialize_doubleValue_fromNumber() async throws {
    let json = "3.14".data(using: .utf8)!
    let desc = makeWrapperDescriptor(name: "DoubleValue", fullName: WellKnownTypeNames.doubleValue, fieldType: .double)
    let msg = try await deserializer().deserialize(json, using: desc)
    let value = try XCTUnwrap(try msg.get(forField: 1) as? Double)
    XCTAssertEqual(value, 3.14, accuracy: 0.0001)
  }

  func test_deserialize_boolValue_fromBool() async throws {
    let json = "true".data(using: .utf8)!
    let desc = makeWrapperDescriptor(name: "BoolValue", fullName: WellKnownTypeNames.boolValue, fieldType: .bool)
    let msg = try await deserializer().deserialize(json, using: desc)
    let value = try XCTUnwrap(try msg.get(forField: 1) as? Bool)
    XCTAssertTrue(value)
  }

  func test_deserialize_stringValue_fromString() async throws {
    let json = #""hello""#.data(using: .utf8)!
    let desc = makeWrapperDescriptor(name: "StringValue", fullName: WellKnownTypeNames.stringValue, fieldType: .string)
    let msg = try await deserializer().deserialize(json, using: desc)
    let value = try XCTUnwrap(try msg.get(forField: 1) as? String)
    XCTAssertEqual(value, "hello")
  }

  func test_deserialize_int64Value_fromString() async throws {
    let json = #""9007199254740993""#.data(using: .utf8)!
    let desc = makeWrapperDescriptor(name: "Int64Value", fullName: WellKnownTypeNames.int64Value, fieldType: .int64)
    let msg = try await deserializer().deserialize(json, using: desc)
    let value = try XCTUnwrap(try msg.get(forField: 1) as? Int64)
    XCTAssertEqual(value, 9_007_199_254_740_993)
  }

  func test_deserialize_wrapperNull_meansAbsent() async throws {
    let json = "null".data(using: .utf8)!
    let desc = makeWrapperDescriptor(name: "StringValue", fullName: WellKnownTypeNames.stringValue, fieldType: .string)
    let msg = try await deserializer().deserialize(json, using: desc)
    // null means absent — field 1 should not be set
    let hasValue = (try? msg.hasValue(forField: 1)) ?? false
    XCTAssertFalse(hasValue)
  }

  func test_deserialize_bytesValue_fromBase64() async throws {
    let bytes = Data([0x01, 0x02, 0x03])
    let base64 = bytes.base64EncodedString()
    let json = "\"\(base64)\"".data(using: .utf8)!
    let desc = makeWrapperDescriptor(name: "BytesValue", fullName: WellKnownTypeNames.bytesValue, fieldType: .bytes)
    let msg = try await deserializer().deserialize(json, using: desc)
    let value = try XCTUnwrap(try msg.get(forField: 1) as? Data)
    XCTAssertEqual(value, bytes)
  }

  // MARK: - Decoder: alternate accepted formats per proto3 JSON spec

  func test_deserialize_doubleValue_fromInfinityString() async throws {
    let json = #""Infinity""#.data(using: .utf8)!
    let desc = makeWrapperDescriptor(name: "DoubleValue", fullName: WellKnownTypeNames.doubleValue, fieldType: .double)
    let msg = try await deserializer().deserialize(json, using: desc)
    let value = try XCTUnwrap(try msg.get(forField: 1) as? Double)
    XCTAssertTrue(value.isInfinite && value > 0)
  }

  func test_deserialize_doubleValue_fromNegativeInfinityString() async throws {
    let json = #""-Infinity""#.data(using: .utf8)!
    let desc = makeWrapperDescriptor(name: "DoubleValue", fullName: WellKnownTypeNames.doubleValue, fieldType: .double)
    let msg = try await deserializer().deserialize(json, using: desc)
    let value = try XCTUnwrap(try msg.get(forField: 1) as? Double)
    XCTAssertTrue(value.isInfinite && value < 0)
  }

  func test_deserialize_doubleValue_fromNaNString() async throws {
    let json = #""NaN""#.data(using: .utf8)!
    let desc = makeWrapperDescriptor(name: "DoubleValue", fullName: WellKnownTypeNames.doubleValue, fieldType: .double)
    let msg = try await deserializer().deserialize(json, using: desc)
    let value = try XCTUnwrap(try msg.get(forField: 1) as? Double)
    XCTAssertTrue(value.isNaN)
  }

  func test_deserialize_floatValue_fromInfinityString() async throws {
    let json = #""Infinity""#.data(using: .utf8)!
    let desc = makeWrapperDescriptor(name: "FloatValue", fullName: WellKnownTypeNames.floatValue, fieldType: .float)
    let msg = try await deserializer().deserialize(json, using: desc)
    let value = try XCTUnwrap(try msg.get(forField: 1) as? Float)
    XCTAssertTrue(value.isInfinite && value > 0)
  }

  func test_deserialize_floatValue_fromNegativeInfinityString() async throws {
    let json = #""-Infinity""#.data(using: .utf8)!
    let desc = makeWrapperDescriptor(name: "FloatValue", fullName: WellKnownTypeNames.floatValue, fieldType: .float)
    let msg = try await deserializer().deserialize(json, using: desc)
    let value = try XCTUnwrap(try msg.get(forField: 1) as? Float)
    XCTAssertTrue(value.isInfinite && value < 0)
  }

  func test_deserialize_floatValue_fromNaNString() async throws {
    let json = #""NaN""#.data(using: .utf8)!
    let desc = makeWrapperDescriptor(name: "FloatValue", fullName: WellKnownTypeNames.floatValue, fieldType: .float)
    let msg = try await deserializer().deserialize(json, using: desc)
    let value = try XCTUnwrap(try msg.get(forField: 1) as? Float)
    XCTAssertTrue(value.isNaN)
  }

  func test_deserialize_int32Value_fromString() async throws {
    let json = #""42""#.data(using: .utf8)!
    let desc = makeWrapperDescriptor(name: "Int32Value", fullName: WellKnownTypeNames.int32Value, fieldType: .int32)
    let msg = try await deserializer().deserialize(json, using: desc)
    let value = try XCTUnwrap(try msg.get(forField: 1) as? Int32)
    XCTAssertEqual(value, 42)
  }

  func test_deserialize_int32Value_negativeFromString() async throws {
    let json = #""-100""#.data(using: .utf8)!
    let desc = makeWrapperDescriptor(name: "Int32Value", fullName: WellKnownTypeNames.int32Value, fieldType: .int32)
    let msg = try await deserializer().deserialize(json, using: desc)
    let value = try XCTUnwrap(try msg.get(forField: 1) as? Int32)
    XCTAssertEqual(value, -100)
  }

  func test_deserialize_uint32Value_fromString() async throws {
    let json = #""4294967295""#.data(using: .utf8)!
    let desc = makeWrapperDescriptor(
      name: "UInt32Value",
      fullName: WellKnownTypeNames.uint32Value,
      fieldType: .uint32
    )
    let msg = try await deserializer().deserialize(json, using: desc)
    let value = try XCTUnwrap(try msg.get(forField: 1) as? UInt32)
    XCTAssertEqual(value, 4_294_967_295)
  }

  func test_deserialize_int64Value_fromNumber() async throws {
    let json = "42".data(using: .utf8)!
    let desc = makeWrapperDescriptor(name: "Int64Value", fullName: WellKnownTypeNames.int64Value, fieldType: .int64)
    let msg = try await deserializer().deserialize(json, using: desc)
    let value = try XCTUnwrap(try msg.get(forField: 1) as? Int64)
    XCTAssertEqual(value, 42)
  }

  func test_deserialize_uint64Value_fromNumber() async throws {
    let json = "42".data(using: .utf8)!
    let desc = makeWrapperDescriptor(
      name: "UInt64Value",
      fullName: WellKnownTypeNames.uint64Value,
      fieldType: .uint64
    )
    let msg = try await deserializer().deserialize(json, using: desc)
    let value = try XCTUnwrap(try msg.get(forField: 1) as? UInt64)
    XCTAssertEqual(value, 42)
  }

  func test_deserialize_uint64Value_fromString() async throws {
    let json = #""18446744073709551615""#.data(using: .utf8)!
    let desc = makeWrapperDescriptor(
      name: "UInt64Value",
      fullName: WellKnownTypeNames.uint64Value,
      fieldType: .uint64
    )
    let msg = try await deserializer().deserialize(json, using: desc)
    let value = try XCTUnwrap(try msg.get(forField: 1) as? UInt64)
    XCTAssertEqual(value, 18_446_744_073_709_551_615)
  }

  // MARK: - Round-trip tests

  func test_roundTrip_allWrapperTypes_preserveValues() async throws {
    // Int32
    let int32Desc = makeWrapperDescriptor(
      name: "Int32Value",
      fullName: WellKnownTypeNames.int32Value,
      fieldType: .int32
    )
    var int32Msg = DynamicMessage(descriptor: int32Desc)
    try int32Msg.set(Int32(-7), forField: 1)
    let int32Data = try await canonicalSerializer().serialize(int32Msg)
    let int32RT = try await deserializer().deserialize(int32Data, using: int32Desc)
    XCTAssertEqual(try int32RT.get(forField: 1) as? Int32, -7)

    // Bool false
    let boolDesc = makeWrapperDescriptor(name: "BoolValue", fullName: WellKnownTypeNames.boolValue, fieldType: .bool)
    var boolMsg = DynamicMessage(descriptor: boolDesc)
    try boolMsg.set(false, forField: 1)
    let boolData = try await canonicalSerializer().serialize(boolMsg)
    let boolRT = try await deserializer().deserialize(boolData, using: boolDesc)
    XCTAssertEqual(try boolRT.get(forField: 1) as? Bool, false)

    // String
    let strDesc = makeWrapperDescriptor(
      name: "StringValue",
      fullName: WellKnownTypeNames.stringValue,
      fieldType: .string
    )
    var strMsg = DynamicMessage(descriptor: strDesc)
    try strMsg.set("world", forField: 1)
    let strData = try await canonicalSerializer().serialize(strMsg)
    let strRT = try await deserializer().deserialize(strData, using: strDesc)
    XCTAssertEqual(try strRT.get(forField: 1) as? String, "world")
  }
}
