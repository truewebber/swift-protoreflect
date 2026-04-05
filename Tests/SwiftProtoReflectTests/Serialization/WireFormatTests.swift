//
// WireFormatTests.swift
// SwiftProtoReflect
//
// Byte-level wire format compliance tests for Protocol Buffers binary encoding.
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class WireFormatTests: XCTestCase {

  // MARK: - Helpers

  private func serializeField(
    name: String,
    number: Int,
    type: FieldType,
    value: Any
  ) throws -> Data {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: name, number: number, type: type))
    let factory = MessageFactory()
    var msg = factory.createMessage(from: desc)
    try msg.set(value, forField: name)
    return try BinarySerializer().serialize(msg)
  }

  // MARK: - Varint encoding

  func test_varint_encoding_smallNumber() throws {
    let data = try serializeField(name: "x", number: 1, type: .int32, value: Int32(1))
    // tag = (1 << 3) | 0 = 0x08, value = 0x01
    XCTAssertEqual(data, Data([0x08, 0x01]))
  }

  func test_varint_encoding_150() throws {
    let data = try serializeField(name: "x", number: 1, type: .int32, value: Int32(150))
    // tag = 0x08, varint 150 = [0x96, 0x01]
    XCTAssertEqual(data, Data([0x08, 0x96, 0x01]))
  }

  func test_varint_encoding_zero() throws {
    let data = try serializeField(name: "x", number: 1, type: .int32, value: Int32(0))
    // tag = 0x08, varint 0 = [0x00]
    XCTAssertEqual(data, Data([0x08, 0x00]))
  }

  func test_varint_encoding_maxUInt64() throws {
    let data = try serializeField(
      name: "x",
      number: 1,
      type: .uint64,
      value: UInt64.max
    )
    // tag = 0x08, varint UInt64.max = 10 bytes of 0xFF, then 0x01
    XCTAssertEqual(data.count, 1 + 10)
    XCTAssertEqual(data[0], 0x08)
    for i in 1...9 {
      XCTAssertEqual(data[i], 0xFF)
    }
    XCTAssertEqual(data[10], 0x01)
  }

  // MARK: - ZigZag encoding

  func test_zigzag_encoding_positive() {
    XCTAssertEqual(BinarySerializer.zigzagEncode32(1), 2)
  }

  func test_zigzag_encoding_negative() {
    XCTAssertEqual(BinarySerializer.zigzagEncode32(-1), 1)
  }

  func test_zigzag_encoding_zero() {
    XCTAssertEqual(BinarySerializer.zigzagEncode32(0), 0)
  }

  func test_zigzag_encoding_minInt32() {
    let encoded = BinarySerializer.zigzagEncode32(Int32.min)
    XCTAssertEqual(encoded, UInt32.max)
  }

  func test_zigzag_roundtrip() {
    for val: Int32 in [0, 1, -1, 42, -42, .min, .max] {
      let encoded = BinarySerializer.zigzagEncode32(val)
      let decoded = BinaryDeserializer.zigzagDecode32(encoded)
      XCTAssertEqual(decoded, val, "Round-trip failed for \(val)")
    }
  }

  func test_zigzag64_roundtrip() {
    for val: Int64 in [0, 1, -1, 42, -42, .min, .max] {
      let encoded = BinarySerializer.zigzagEncode64(val)
      let decoded = BinaryDeserializer.zigzagDecode64(encoded)
      XCTAssertEqual(decoded, val, "Round-trip failed for \(val)")
    }
  }

  // MARK: - Fixed encoding (little-endian)

  func test_fixed32_encoding_littleEndian() throws {
    let data = try serializeField(
      name: "x",
      number: 1,
      type: .fixed32,
      value: UInt32(0x1234_5678)
    )
    // tag = (1 << 3) | 5 = 0x0D, then 4 bytes little-endian
    XCTAssertEqual(data, Data([0x0D, 0x78, 0x56, 0x34, 0x12]))
  }

  func test_fixed64_encoding_littleEndian() throws {
    let data = try serializeField(
      name: "x",
      number: 1,
      type: .fixed64,
      value: UInt64(0x0102_0304_0506_0708)
    )
    // tag = (1 << 3) | 1 = 0x09, then 8 bytes little-endian
    XCTAssertEqual(data, Data([0x09, 0x08, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01]))
  }

  // MARK: - Tag encoding

  func test_tag_encoding_fieldNumber1Varint() throws {
    let data = try serializeField(name: "x", number: 1, type: .int32, value: Int32(0))
    XCTAssertEqual(data[0], 0x08, "Field 1, varint → tag 0x08")
  }

  func test_tag_encoding_fieldNumber15LengthDelimited() throws {
    let data = try serializeField(name: "x", number: 15, type: .string, value: "a")
    // (15 << 3) | 2 = 122 = 0x7A — single byte tag
    XCTAssertEqual(data[0], 0x7A)
  }

  func test_tag_encoding_fieldNumber16Varint() throws {
    let data = try serializeField(name: "x", number: 16, type: .int32, value: Int32(0))
    // (16 << 3) | 0 = 128 → varint [0x80, 0x01]
    XCTAssertEqual(data[0], 0x80)
    XCTAssertEqual(data[1], 0x01)
  }

  func test_tag_encoding_maxFieldNumber() throws {
    let maxField = (1 << 29) - 1
    let data = try serializeField(
      name: "x",
      number: maxField,
      type: .int32,
      value: Int32(0)
    )
    // Tag = (maxField << 3) | 0, which is a 5-byte varint
    XCTAssertTrue(data.count >= 5, "Max field number tag should be at least 5 bytes")

    let deserialized = try BinaryDeserializer(options: .init(typeRegistry: TypeRegistry())).deserialize(
      data,
      using: {
        var d = MessageDescriptor(name: "M", fullName: "test.M")
        d.addField(FieldDescriptor(name: "x", number: maxField, type: .int32))
        return d
      }()
    )
    XCTAssertEqual(try deserialized.get(forField: "x") as? Int32, 0)
  }

  // MARK: - Length-delimited edge cases

  func test_lengthDelimited_emptyString() throws {
    let data = try serializeField(name: "x", number: 1, type: .string, value: "")
    // tag = 0x0A (field 1, wire type 2), length = 0x00
    XCTAssertEqual(data, Data([0x0A, 0x00]))
  }

  func test_lengthDelimited_emptyBytes() throws {
    let data = try serializeField(name: "x", number: 1, type: .bytes, value: Data())
    // tag = 0x0A (field 1, wire type 2), length = 0x00
    XCTAssertEqual(data, Data([0x0A, 0x00]))
  }

  // MARK: - Round-trip through serialization

  func test_allScalarTypes_roundtrip() throws {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "f_int32", number: 1, type: .int32))
    desc.addField(FieldDescriptor(name: "f_int64", number: 2, type: .int64))
    desc.addField(FieldDescriptor(name: "f_uint32", number: 3, type: .uint32))
    desc.addField(FieldDescriptor(name: "f_uint64", number: 4, type: .uint64))
    desc.addField(FieldDescriptor(name: "f_sint32", number: 5, type: .sint32))
    desc.addField(FieldDescriptor(name: "f_sint64", number: 6, type: .sint64))
    desc.addField(FieldDescriptor(name: "f_bool", number: 7, type: .bool))
    desc.addField(FieldDescriptor(name: "f_string", number: 8, type: .string))
    desc.addField(FieldDescriptor(name: "f_bytes", number: 9, type: .bytes))
    desc.addField(FieldDescriptor(name: "f_double", number: 10, type: .double))
    desc.addField(FieldDescriptor(name: "f_float", number: 11, type: .float))
    desc.addField(FieldDescriptor(name: "f_fixed32", number: 12, type: .fixed32))
    desc.addField(FieldDescriptor(name: "f_fixed64", number: 13, type: .fixed64))
    desc.addField(FieldDescriptor(name: "f_sfixed32", number: 14, type: .sfixed32))
    desc.addField(FieldDescriptor(name: "f_sfixed64", number: 15, type: .sfixed64))

    let factory = MessageFactory()
    var msg = factory.createMessage(from: desc)
    try msg.set(Int32(42), forField: "f_int32")
    try msg.set(Int64(123_456_789), forField: "f_int64")
    try msg.set(UInt32(100), forField: "f_uint32")
    try msg.set(UInt64(200), forField: "f_uint64")
    try msg.set(Int32(-42), forField: "f_sint32")
    try msg.set(Int64(-123), forField: "f_sint64")
    try msg.set(true, forField: "f_bool")
    try msg.set("hello", forField: "f_string")
    try msg.set(Data([0xDE, 0xAD]), forField: "f_bytes")
    try msg.set(Double(3.14), forField: "f_double")
    try msg.set(Float(2.71), forField: "f_float")
    try msg.set(UInt32(999), forField: "f_fixed32")
    try msg.set(UInt64(9999), forField: "f_fixed64")
    try msg.set(Int32(-999), forField: "f_sfixed32")
    try msg.set(Int64(-9999), forField: "f_sfixed64")

    let serializer = BinarySerializer()
    let data = try serializer.serialize(msg)

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let decoded = try deserializer.deserialize(data, using: desc)

    XCTAssertEqual(try decoded.get(forField: "f_int32") as? Int32, 42)
    XCTAssertEqual(try decoded.get(forField: "f_int64") as? Int64, 123_456_789)
    XCTAssertEqual(try decoded.get(forField: "f_uint32") as? UInt32, 100)
    XCTAssertEqual(try decoded.get(forField: "f_uint64") as? UInt64, 200)
    XCTAssertEqual(try decoded.get(forField: "f_sint32") as? Int32, -42)
    XCTAssertEqual(try decoded.get(forField: "f_sint64") as? Int64, -123)
    XCTAssertEqual(try decoded.get(forField: "f_bool") as? Bool, true)
    XCTAssertEqual(try decoded.get(forField: "f_string") as? String, "hello")
    XCTAssertEqual(try decoded.get(forField: "f_bytes") as? Data, Data([0xDE, 0xAD]))
    XCTAssertEqual(try decoded.get(forField: "f_double") as? Double, 3.14)
    XCTAssertEqual(try decoded.get(forField: "f_float") as? Float, 2.71)
    XCTAssertEqual(try decoded.get(forField: "f_fixed32") as? UInt32, 999)
    XCTAssertEqual(try decoded.get(forField: "f_fixed64") as? UInt64, 9999)
    XCTAssertEqual(try decoded.get(forField: "f_sfixed32") as? Int32, -999)
    XCTAssertEqual(try decoded.get(forField: "f_sfixed64") as? Int64, -9999)
  }
}
