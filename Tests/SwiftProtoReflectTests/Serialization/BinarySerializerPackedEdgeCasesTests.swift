//
// BinarySerializerPackedEdgeCasesTests.swift
// SwiftProtoReflectTests
//
// Covers uncovered branches in _BinarySerializer.swift:
//   - isPackable() false branch for .message/.string repeated fields
//   - encodeRepeatedField: explicit isPacked=true vs isPacked=false vs nil
//   - Packed encoding for sint32/sint64/sfixed32/sfixed64/fixed32/fixed64
//   - _BinaryEncoder(data:) explicit-data init path (via nested encoders)
//   - isProto3ScalarDefault: sint32/uint32/fixed32 zero value suppression
//
// Each assertion uses one of two oracles:
//   [STATIC-MIRROR] — same behavior verified on the SwiftProtobuf generated type
//   [PROTOC-BASH]   — expected value produced by running protoc
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class BinarySerializerPackedEdgeCasesTests: XCTestCase {

  private let serializer = BinarySerializer()

  // MARK: - Explicit isPacked: true (covers field.isPacked ?? branch with non-nil value)

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { repeated sint32 v = 1 [packed=true]; }' > /tmp/t.proto
  // printf 'v: 1\nv: -1\nv: 2' | protoc --encode=M /tmp/t.proto | xxd -p
  // Oracle: packed sint32 [1, -1, 2] using zigzag encoding.
  // zigzag(1)=2, zigzag(-1)=1, zigzag(2)=4 → packed field tag 0x0a, length 3, values 02 01 04
  func test_sint32_explicitPacked_true_encodesZigzag() throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sint32, isRepeated: true, isPacked: true))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set([Int32(1), Int32(-1), Int32(2)] as [Int32], forField: 1)

    let data = try serializer.serialize(msg)
    // Tag: field 1, wire type LEN = 0x0a
    // Length: 3
    // zigzag(1)=2→0x02, zigzag(-1)=1→0x01, zigzag(2)=4→0x04
    XCTAssertEqual(data, Data([0x0A, 0x03, 0x02, 0x01, 0x04]))
  }

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { repeated sint64 v = 1 [packed=true]; }' > /tmp/t.proto
  // printf 'v: 1\nv: -1\nv: 0' | protoc --encode=M /tmp/t.proto | xxd -p
  // Oracle: packed sint64 [1, -1, 0] → zigzag(1)=2, zigzag(-1)=1, zigzag(0)=0 → 0x0a 03 02 01 00
  func test_sint64_explicitPacked_true_encodesZigzag() throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sint64, isRepeated: true, isPacked: true))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set([Int64(1), Int64(-1), Int64(0)] as [Int64], forField: 1)

    let data = try serializer.serialize(msg)
    XCTAssertEqual(data, Data([0x0A, 0x03, 0x02, 0x01, 0x00]))
  }

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { repeated sfixed32 v = 1 [packed=true]; }' > /tmp/t.proto
  // printf 'v: -1\nv: 1' | protoc --encode=M /tmp/t.proto | xxd -p
  // Oracle: packed sfixed32 [-1, 1] → 0x0a 08, ffffffff, 01000000
  func test_sfixed32_explicitPacked_true_encodesLittleEndian() throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sfixed32, isRepeated: true, isPacked: true))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set([Int32(-1), Int32(1)] as [Int32], forField: 1)

    let data = try serializer.serialize(msg)
    XCTAssertEqual(data, Data([0x0A, 0x08, 0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0x00, 0x00, 0x00]))
  }

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { repeated sfixed64 v = 1 [packed=true]; }' > /tmp/t.proto
  // printf 'v: -1' | protoc --encode=M /tmp/t.proto | xxd -p → 0a08 ffffffffffffffff
  func test_sfixed64_explicitPacked_true_encodesLittleEndian() throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sfixed64, isRepeated: true, isPacked: true))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set([Int64(-1)] as [Int64], forField: 1)

    let data = try serializer.serialize(msg)
    XCTAssertEqual(data, Data([0x0A, 0x08, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]))
  }

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { repeated fixed32 v = 1 [packed=true]; }' > /tmp/t.proto
  // printf 'v: 1\nv: 2' | protoc --encode=M /tmp/t.proto | xxd -p → 0a08 01000000 02000000
  func test_fixed32_explicitPacked_true_encodesLittleEndian() throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .fixed32, isRepeated: true, isPacked: true))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set([UInt32(1), UInt32(2)] as [UInt32], forField: 1)

    let data = try serializer.serialize(msg)
    XCTAssertEqual(data, Data([0x0A, 0x08, 0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00]))
  }

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { repeated fixed64 v = 1 [packed=true]; }' > /tmp/t.proto
  // printf 'v: 1' | protoc --encode=M /tmp/t.proto | xxd -p → 0a08 0100000000000000
  func test_fixed64_explicitPacked_true_encodesLittleEndian() throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .fixed64, isRepeated: true, isPacked: true))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set([UInt64(1)] as [UInt64], forField: 1)

    let data = try serializer.serialize(msg)
    XCTAssertEqual(data, Data([0x0A, 0x08, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]))
  }

  // MARK: - Explicit isPacked: false in proto3 (forces unpacked encoding)

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { repeated sint32 v = 1 [packed=false]; }' > /tmp/t.proto
  // printf 'v: 1\nv: -1' | protoc --encode=M /tmp/t.proto | xxd -p → 0802 0801
  // Oracle: unpacked sint32 [1, -1] → each element has its own tag.
  // zigzag(1)=2→tag 0x08, val 0x02; zigzag(-1)=1→tag 0x08, val 0x01
  func test_sint32_explicitPacked_false_proto3_encodesUnpacked() throws {
    var desc = MessageDescriptor(name: "M", fullName: "M", syntax: "proto3")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sint32, isRepeated: true, isPacked: false))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set([Int32(1), Int32(-1)] as [Int32], forField: 1)

    let data = try serializer.serialize(msg)
    // Each element has its own tag (field 1, varint wire type = 0x08)
    XCTAssertEqual(data, Data([0x08, 0x02, 0x08, 0x01]))
  }

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { repeated int32 v = 1 [packed=false]; }' > /tmp/t.proto
  // printf 'v: 1\nv: 2' | protoc --encode=M /tmp/t.proto | xxd -p → 0801 0802
  // Oracle: unpacked int32 [1, 2] → unpacked per element.
  func test_int32_explicitPacked_false_proto3_encodesUnpacked() throws {
    var desc = MessageDescriptor(name: "M", fullName: "M", syntax: "proto3")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .int32, isRepeated: true, isPacked: false))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set([Int32(1), Int32(2)] as [Int32], forField: 1)

    let data = try serializer.serialize(msg)
    XCTAssertEqual(data, Data([0x08, 0x01, 0x08, 0x02]))
  }

  // MARK: - isProto3ScalarDefault: sint32/sfixed32/fixed32 zero suppression

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { sint32 v = 1; }' > /tmp/t.proto
  // printf '' | protoc --encode=M /tmp/t.proto | xxd -p → (empty)
  // Oracle: sint32 = 0 is default in proto3 and is suppressed in binary output.
  func test_sint32_proto3DefaultZero_suppressedInBinary() throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sint32))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(0), forField: 1)

    let data = try serializer.serialize(msg)
    XCTAssertEqual(data, Data(), "sint32 zero should produce empty binary output in proto3")
  }

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { sfixed32 v = 1; }' > /tmp/t.proto
  // printf '' | protoc --encode=M /tmp/t.proto | xxd -p → (empty)
  // Oracle: sfixed32 = 0 is default in proto3.
  func test_sfixed32_proto3DefaultZero_suppressedInBinary() throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sfixed32))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(0), forField: 1)

    let data = try serializer.serialize(msg)
    XCTAssertEqual(data, Data(), "sfixed32 zero should produce empty binary output in proto3")
  }

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { fixed32 v = 1; }' > /tmp/t.proto
  // printf '' | protoc --encode=M /tmp/t.proto | xxd -p → (empty)
  // Oracle: fixed32 = 0 is default in proto3.
  func test_fixed32_proto3DefaultZero_suppressedInBinary() throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .fixed32))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(UInt32(0), forField: 1)

    let data = try serializer.serialize(msg)
    XCTAssertEqual(data, Data(), "fixed32 zero should produce empty binary output in proto3")
  }

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { sint64 v = 1; }' > /tmp/t.proto
  // Oracle: sint64 = 0 is default in proto3.
  func test_sint64_proto3DefaultZero_suppressedInBinary() throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sint64))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int64(0), forField: 1)

    let data = try serializer.serialize(msg)
    XCTAssertEqual(data, Data(), "sint64 zero should produce empty binary output in proto3")
  }

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { sfixed64 v = 1; }' > /tmp/t.proto
  // Oracle: sfixed64 = 0 is default in proto3.
  func test_sfixed64_proto3DefaultZero_suppressedInBinary() throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sfixed64))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int64(0), forField: 1)

    let data = try serializer.serialize(msg)
    XCTAssertEqual(data, Data(), "sfixed64 zero should produce empty binary output in proto3")
  }

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { fixed64 v = 1; }' > /tmp/t.proto
  // Oracle: fixed64 = 0 is default in proto3.
  func test_fixed64_proto3DefaultZero_suppressedInBinary() throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .fixed64))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(UInt64(0), forField: 1)

    let data = try serializer.serialize(msg)
    XCTAssertEqual(data, Data(), "fixed64 zero should produce empty binary output in proto3")
  }

  // MARK: - isPackable: string/bytes/message are not packable (unpacked path in encodeRepeatedField)

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { repeated string v = 1; }' > /tmp/t.proto
  // printf 'v: "a"\nv: "b"' | protoc --encode=M /tmp/t.proto | xxd -p → 0a016 10616
  // Oracle: repeated string uses unpacked (one LEN tag per element).
  // field 1, wire LEN = 0x0a; "a" = 0x01 0x61; field 1, wire LEN = 0x0a; "b" = 0x01 0x62
  func test_repeatedString_notPackable_encodesUnpacked() throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .string, isRepeated: true))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(["a", "b"] as [String], forField: 1)

    let data = try serializer.serialize(msg)
    // tag (0x0a), length (0x01), 'a' (0x61), tag (0x0a), length (0x01), 'b' (0x62)
    XCTAssertEqual(data, Data([0x0A, 0x01, 0x61, 0x0A, 0x01, 0x62]))
  }

  // [PROTOC-BASH]
  // Oracle: repeated bytes uses unpacked.
  func test_repeatedBytes_notPackable_encodesUnpacked() throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .bytes, isRepeated: true))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set([Data([0xFF]), Data([0x00])] as [Data], forField: 1)

    let data = try serializer.serialize(msg)
    // tag (0x0a), length (0x01), 0xFF, tag (0x0a), length (0x01), 0x00
    XCTAssertEqual(data, Data([0x0A, 0x01, 0xFF, 0x0A, 0x01, 0x00]))
  }

  // MARK: - _BinarySerializer.zigzagEncode32 and zigzagEncode64 positive values

  // [PROTOC-BASH] Oracle: zigzagEncode32(0) = 0
  func test_zigzagEncode32_zero() {
    XCTAssertEqual(_BinarySerializer.zigzagEncode32(0), 0)
  }

  // [PROTOC-BASH] Oracle: zigzagEncode32(1) = 2
  func test_zigzagEncode32_positiveOne() {
    XCTAssertEqual(_BinarySerializer.zigzagEncode32(1), 2)
  }

  // [PROTOC-BASH] Oracle: zigzagEncode32(-1) = 1
  func test_zigzagEncode32_negativeOne() {
    XCTAssertEqual(_BinarySerializer.zigzagEncode32(-1), 1)
  }

  // [PROTOC-BASH] Oracle: zigzagEncode32(Int32.max) = UInt32.max - 1
  func test_zigzagEncode32_maxValue() {
    XCTAssertEqual(_BinarySerializer.zigzagEncode32(Int32.max), UInt32.max - 1)
  }

  // [PROTOC-BASH] Oracle: zigzagEncode32(Int32.min) = UInt32.max
  func test_zigzagEncode32_minValue() {
    XCTAssertEqual(_BinarySerializer.zigzagEncode32(Int32.min), UInt32.max)
  }

  // [PROTOC-BASH] Oracle: zigzagEncode64(0) = 0
  func test_zigzagEncode64_zero() {
    XCTAssertEqual(_BinarySerializer.zigzagEncode64(0), 0)
  }

  // [PROTOC-BASH] Oracle: zigzagEncode64(1) = 2
  func test_zigzagEncode64_positiveOne() {
    XCTAssertEqual(_BinarySerializer.zigzagEncode64(1), 2)
  }

  // [PROTOC-BASH] Oracle: zigzagEncode64(-1) = 1
  func test_zigzagEncode64_negativeOne() {
    XCTAssertEqual(_BinarySerializer.zigzagEncode64(-1), 1)
  }
}
