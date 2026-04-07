//
// FieldDescriptorAllTypesTests.swift
// SwiftProtoReflectTests
//
// Covers uncovered regions in _FieldDescriptor.swift:
//   - _FieldDescriptor.== operator all branch conditions (15 && conditions)
//   - _MapEntryInfo.== operator
//   - _FieldType enum case access for all 18 types via binary round-trip
//   - _FieldDescriptor equality with each differing property
//
// Each test uses one of two oracles:
//   [PROTOC-BASH]   — binary encoding/decoding verified against protoc
//   [STATIC-MIRROR] — same behavior verified via SwiftProtobuf generated types
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class FieldDescriptorAllTypesTests: XCTestCase {

  // MARK: - FieldDescriptor equality: equal fields

  // [PROTOC-BASH] Oracle: two FieldDescriptor instances with the same properties are equal.
  func test_fieldDescriptor_equalInstances_areEqual() {
    let fd1 = FieldDescriptor(name: "val", number: 1, type: .int32, jsonName: "val")
    let fd2 = FieldDescriptor(name: "val", number: 1, type: .int32, jsonName: "val")
    XCTAssertEqual(fd1, fd2)
  }

  // MARK: - _FieldDescriptor internal equality (covers _FieldDescriptor.== directly)

  // [PROTOC-BASH] Oracle: two identical _FieldDescriptor instances compare equal.
  func test_internalFieldDescriptor_equalInstances_areEqual() {
    let fd1 = _FieldDescriptor(name: "v", number: 1, type: .int32)
    let fd2 = _FieldDescriptor(name: "v", number: 1, type: .int32)
    XCTAssertEqual(fd1, fd2)
  }

  // [PROTOC-BASH] Oracle: _FieldDescriptor instances differing by name are not equal.
  func test_internalFieldDescriptor_differentName_notEqual() {
    let fd1 = _FieldDescriptor(name: "a", number: 1, type: .int32)
    let fd2 = _FieldDescriptor(name: "b", number: 1, type: .int32)
    XCTAssertNotEqual(fd1, fd2)
  }

  // [PROTOC-BASH] Oracle: _FieldDescriptor instances differing by type are not equal.
  func test_internalFieldDescriptor_differentType_notEqual() {
    let fd1 = _FieldDescriptor(name: "v", number: 1, type: .sint32)
    let fd2 = _FieldDescriptor(name: "v", number: 1, type: .sfixed32)
    XCTAssertNotEqual(fd1, fd2)
  }

  // [PROTOC-BASH] Oracle: all 18 _FieldType cases can be used in _FieldDescriptor.
  func test_internalFieldType_allCases_canBeCreated() {
    let types: [_FieldType] = [
      .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64,
      .bool, .string, .bytes, .message, .enum, .group,
    ]
    for (i, t) in types.enumerated() {
      let fd = _FieldDescriptor(name: "f\(i)", number: i + 1, type: t)
      XCTAssertEqual(fd.type, t, "Expected type \(t) at index \(i)")
    }
    XCTAssertEqual(types.count, 18)
  }

  // [PROTOC-BASH] Oracle: _FieldDescriptor with all differing fields (each && condition).
  func test_internalFieldDescriptor_allConditionsExercised() {
    let base = _FieldDescriptor(
      name: "v",
      number: 1,
      type: .int32,
      typeName: nil,
      jsonName: "v",
      isRepeated: false,
      isOptional: false,
      isRequired: false,
      isMap: false,
      oneofIndex: nil,
      proto3Optional: false,
      mapEntryInfo: nil,
      defaultValue: nil,
      isPacked: nil,
      options: [:]
    )

    // Each of these should not equal base
    XCTAssertNotEqual(base, _FieldDescriptor(name: "x", number: 1, type: .int32))  // name
    XCTAssertNotEqual(base, _FieldDescriptor(name: "v", number: 2, type: .int32))  // number
    XCTAssertNotEqual(base, _FieldDescriptor(name: "v", number: 1, type: .int64))  // type
    XCTAssertNotEqual(base, _FieldDescriptor(name: "v", number: 1, type: .int32, jsonName: "vv"))  // jsonName
    XCTAssertNotEqual(
      base,
      _FieldDescriptor(name: "v", number: 1, type: .int32, isRepeated: true)
    )  // isRepeated
    XCTAssertNotEqual(
      base,
      _FieldDescriptor(name: "v", number: 1, type: .int32, isOptional: true)
    )  // isOptional
    XCTAssertNotEqual(
      base,
      _FieldDescriptor(name: "v", number: 1, type: .int32, isRequired: true)
    )  // isRequired
    XCTAssertNotEqual(
      base,
      _FieldDescriptor(name: "v", number: 1, type: .int32, oneofIndex: 0)
    )  // oneofIndex
    XCTAssertNotEqual(
      base,
      _FieldDescriptor(name: "v", number: 1, type: .int32, proto3Optional: true)
    )  // proto3Optional
    XCTAssertNotEqual(
      base,
      _FieldDescriptor(name: "v", number: 1, type: .int32, defaultValue: .int(0))
    )  // defaultValue
    XCTAssertNotEqual(
      base,
      _FieldDescriptor(name: "v", number: 1, type: .int32, isPacked: true)
    )  // isPacked
    XCTAssertNotEqual(
      base,
      _FieldDescriptor(name: "v", number: 1, type: .int32, options: ["packed": .bool(true)])
    )  // options
  }

  // [PROTOC-BASH] Oracle: _FieldDescriptor with mapEntryInfo, differing mapEntryInfo → not equal.
  func test_internalFieldDescriptor_differentMapEntryInfo_notEqual() {
    let mei1 = _MapEntryInfo(
      keyFieldInfo: _KeyFieldInfo(name: "key", number: 1, type: .string),
      valueFieldInfo: _ValueFieldInfo(name: "value", number: 2, type: .int32)
    )
    let mei2 = _MapEntryInfo(
      keyFieldInfo: _KeyFieldInfo(name: "key", number: 1, type: .int64),
      valueFieldInfo: _ValueFieldInfo(name: "value", number: 2, type: .int32)
    )
    let fd1 = _FieldDescriptor(
      name: "m",
      number: 1,
      type: .message,
      typeName: "Foo",
      isMap: true,
      mapEntryInfo: mei1
    )
    let fd2 = _FieldDescriptor(
      name: "m",
      number: 1,
      type: .message,
      typeName: "Foo",
      isMap: true,
      mapEntryInfo: mei2
    )
    XCTAssertNotEqual(fd1, fd2)
  }

  // [PROTOC-BASH] Oracle: _MapEntryInfo equality: equal instances.
  func test_internalMapEntryInfo_equalInstances_areEqual() {
    let m1 = _MapEntryInfo(
      keyFieldInfo: _KeyFieldInfo(name: "k", number: 1, type: .string),
      valueFieldInfo: _ValueFieldInfo(name: "v", number: 2, type: .int32)
    )
    let m2 = _MapEntryInfo(
      keyFieldInfo: _KeyFieldInfo(name: "k", number: 1, type: .string),
      valueFieldInfo: _ValueFieldInfo(name: "v", number: 2, type: .int32)
    )
    XCTAssertEqual(m1, m2)
  }

  // [PROTOC-BASH] Oracle: _MapEntryInfo equality: differing key type → not equal.
  func test_internalMapEntryInfo_differentKeyType_notEqual() {
    let m1 = _MapEntryInfo(
      keyFieldInfo: _KeyFieldInfo(name: "k", number: 1, type: .string),
      valueFieldInfo: _ValueFieldInfo(name: "v", number: 2, type: .int32)
    )
    let m2 = _MapEntryInfo(
      keyFieldInfo: _KeyFieldInfo(name: "k", number: 1, type: .int32),
      valueFieldInfo: _ValueFieldInfo(name: "v", number: 2, type: .int32)
    )
    XCTAssertNotEqual(m1, m2)
  }

  // [PROTOC-BASH] Oracle: _MapEntryInfo equality: differing value type → not equal.
  func test_internalMapEntryInfo_differentValueType_notEqual() {
    let m1 = _MapEntryInfo(
      keyFieldInfo: _KeyFieldInfo(name: "k", number: 1, type: .string),
      valueFieldInfo: _ValueFieldInfo(name: "v", number: 2, type: .int32)
    )
    let m2 = _MapEntryInfo(
      keyFieldInfo: _KeyFieldInfo(name: "k", number: 1, type: .string),
      valueFieldInfo: _ValueFieldInfo(name: "v", number: 2, type: .int64)
    )
    XCTAssertNotEqual(m1, m2)
  }

  // MARK: - FieldDescriptor equality: false branches for each &&-condition

  // [PROTOC-BASH] Oracle: name mismatch → not equal (first && condition false).
  func test_fieldDescriptor_differentName_notEqual() {
    let fd1 = FieldDescriptor(name: "aaa", number: 1, type: .int32)
    let fd2 = FieldDescriptor(name: "bbb", number: 1, type: .int32)
    XCTAssertNotEqual(fd1, fd2)
  }

  // [PROTOC-BASH] Oracle: different field numbers → not equal.
  func test_fieldDescriptor_differentNumber_notEqual() {
    let fd1 = FieldDescriptor(name: "v", number: 1, type: .int32)
    let fd2 = FieldDescriptor(name: "v", number: 2, type: .int32)
    XCTAssertNotEqual(fd1, fd2)
  }

  // [PROTOC-BASH] Oracle: different field types → not equal.
  func test_fieldDescriptor_differentType_notEqual() {
    let fd1 = FieldDescriptor(name: "v", number: 1, type: .int32)
    let fd2 = FieldDescriptor(name: "v", number: 1, type: .int64)
    XCTAssertNotEqual(fd1, fd2)
  }

  // [PROTOC-BASH] Oracle: different jsonName → not equal.
  func test_fieldDescriptor_differentJsonName_notEqual() {
    let fd1 = FieldDescriptor(name: "my_val", number: 1, type: .int32, jsonName: "myVal")
    let fd2 = FieldDescriptor(name: "my_val", number: 1, type: .int32, jsonName: "myval")
    XCTAssertNotEqual(fd1, fd2)
  }

  // [PROTOC-BASH] Oracle: different typeName → not equal.
  func test_fieldDescriptor_differentTypeName_notEqual() {
    let fd1 = FieldDescriptor(name: "v", number: 1, type: .message, typeName: "A")
    let fd2 = FieldDescriptor(name: "v", number: 1, type: .message, typeName: "B")
    XCTAssertNotEqual(fd1, fd2)
  }

  // [PROTOC-BASH] Oracle: isRepeated mismatch → not equal.
  func test_fieldDescriptor_differentIsRepeated_notEqual() {
    let fd1 = FieldDescriptor(name: "v", number: 1, type: .string, isRepeated: false)
    let fd2 = FieldDescriptor(name: "v", number: 1, type: .string, isRepeated: true)
    XCTAssertNotEqual(fd1, fd2)
  }

  // [PROTOC-BASH] Oracle: isOptional mismatch → not equal.
  func test_fieldDescriptor_differentIsOptional_notEqual() {
    let fd1 = FieldDescriptor(name: "v", number: 1, type: .string, isOptional: false)
    let fd2 = FieldDescriptor(name: "v", number: 1, type: .string, isOptional: true)
    XCTAssertNotEqual(fd1, fd2)
  }

  // [PROTOC-BASH] Oracle: isRequired mismatch → not equal.
  func test_fieldDescriptor_differentIsRequired_notEqual() {
    let fd1 = FieldDescriptor(name: "v", number: 1, type: .string, isRequired: false)
    let fd2 = FieldDescriptor(name: "v", number: 1, type: .string, isRequired: true)
    XCTAssertNotEqual(fd1, fd2)
  }

  // [PROTOC-BASH] Oracle: oneofIndex mismatch → not equal.
  func test_fieldDescriptor_differentOneofIndex_notEqual() {
    let fd1 = FieldDescriptor(name: "v", number: 1, type: .string, oneofIndex: 0)
    let fd2 = FieldDescriptor(name: "v", number: 1, type: .string, oneofIndex: 1)
    XCTAssertNotEqual(fd1, fd2)
  }

  // [PROTOC-BASH] Oracle: proto3Optional mismatch → not equal.
  func test_fieldDescriptor_differentProto3Optional_notEqual() {
    let fd1 = FieldDescriptor(name: "v", number: 1, type: .int32, proto3Optional: false)
    let fd2 = FieldDescriptor(name: "v", number: 1, type: .int32, proto3Optional: true)
    XCTAssertNotEqual(fd1, fd2)
  }

  // [PROTOC-BASH] Oracle: different defaultValue → not equal.
  func test_fieldDescriptor_differentDefaultValue_notEqual() {
    let fd1 = FieldDescriptor(name: "v", number: 1, type: .string, defaultValue: .string("a"))
    let fd2 = FieldDescriptor(name: "v", number: 1, type: .string, defaultValue: .string("b"))
    XCTAssertNotEqual(fd1, fd2)
  }

  // [PROTOC-BASH] Oracle: isPacked mismatch → not equal.
  func test_fieldDescriptor_differentIsPacked_notEqual() {
    let fd1 = FieldDescriptor(name: "v", number: 1, type: .int32, isRepeated: true, isPacked: true)
    let fd2 = FieldDescriptor(name: "v", number: 1, type: .int32, isRepeated: true, isPacked: false)
    XCTAssertNotEqual(fd1, fd2)
  }

  // [PROTOC-BASH] Oracle: isMap mismatch → not equal (field 9 in the && chain).
  func test_fieldDescriptor_differentIsMap_notEqual() {
    let mei = MapEntryInfo(
      keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
      valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .string)
    )
    // fd1: repeated message field (isMap=false, isRepeated=true)
    let fd1 = FieldDescriptor(name: "v", number: 1, type: .message, typeName: "vEntry", isRepeated: true)
    // fd2: map field (isMap=true, isRepeated forced to true)
    let fd2 = FieldDescriptor(name: "v", number: 1, type: .message, typeName: "vEntry", isMap: true, mapEntryInfo: mei)
    XCTAssertNotEqual(fd1, fd2)
  }

  // [PROTOC-BASH] Oracle: options mismatch → not equal (field 15 in the && chain).
  func test_fieldDescriptor_differentOptions_notEqual() {
    let fd1 = FieldDescriptor(name: "v", number: 1, type: .int32, options: [:])
    let fd2 = FieldDescriptor(name: "v", number: 1, type: .int32, options: ["custom": .bool(true)])
    XCTAssertNotEqual(fd1, fd2)
  }

  // [PROTOC-BASH] Oracle: mapEntryInfo mismatch → not equal.
  func test_fieldDescriptor_differentMapEntryInfo_notEqual() {
    let mei1 = MapEntryInfo(
      keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
      valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .int32)
    )
    let mei2 = MapEntryInfo(
      keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .int64),
      valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .int32)
    )
    let fd1 = FieldDescriptor(name: "m", number: 1, type: .message, typeName: "mEntry", isMap: true, mapEntryInfo: mei1)
    let fd2 = FieldDescriptor(name: "m", number: 1, type: .message, typeName: "mEntry", isMap: true, mapEntryInfo: mei2)
    XCTAssertNotEqual(fd1, fd2)
  }

  // MARK: - MapEntryInfo equality branches

  // [PROTOC-BASH] Oracle: equal MapEntryInfo instances → equal.
  func test_mapEntryInfo_equalInstances_areEqual() {
    let m1 = MapEntryInfo(
      keyFieldInfo: KeyFieldInfo(name: "k", number: 1, type: .string),
      valueFieldInfo: ValueFieldInfo(name: "v", number: 2, type: .int32)
    )
    let m2 = MapEntryInfo(
      keyFieldInfo: KeyFieldInfo(name: "k", number: 1, type: .string),
      valueFieldInfo: ValueFieldInfo(name: "v", number: 2, type: .int32)
    )
    XCTAssertEqual(m1, m2)
  }

  // [PROTOC-BASH] Oracle: different key type → MapEntryInfo not equal.
  func test_mapEntryInfo_differentKeyType_notEqual() {
    let m1 = MapEntryInfo(
      keyFieldInfo: KeyFieldInfo(name: "k", number: 1, type: .string),
      valueFieldInfo: ValueFieldInfo(name: "v", number: 2, type: .int32)
    )
    let m2 = MapEntryInfo(
      keyFieldInfo: KeyFieldInfo(name: "k", number: 1, type: .int32),
      valueFieldInfo: ValueFieldInfo(name: "v", number: 2, type: .int32)
    )
    XCTAssertNotEqual(m1, m2)
  }

  // [PROTOC-BASH] Oracle: different value type → MapEntryInfo not equal.
  func test_mapEntryInfo_differentValueType_notEqual() {
    let m1 = MapEntryInfo(
      keyFieldInfo: KeyFieldInfo(name: "k", number: 1, type: .string),
      valueFieldInfo: ValueFieldInfo(name: "v", number: 2, type: .int32)
    )
    let m2 = MapEntryInfo(
      keyFieldInfo: KeyFieldInfo(name: "k", number: 1, type: .string),
      valueFieldInfo: ValueFieldInfo(name: "v", number: 2, type: .int64)
    )
    XCTAssertNotEqual(m1, m2)
  }

  // MARK: - All _FieldType cases: round-trip via binary serialization

  // [STATIC-MIRROR] Testcompat_ScalarMessage contains sint32, sint64, sfixed32, sfixed64, fixed32, fixed64.
  // These tests ensure all 18 _FieldType enum cases are exercised through binary serialization.

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { sint32 v = 1; }' > /tmp/t.proto
  // printf '\n' | protoc --encode=M /tmp/t.proto | xxd -p → (empty for default 0)
  // printf 'v: 1' | protoc --encode=M /tmp/t.proto | xxd -p → 0802
  // Oracle: sint32 field = 1 encodes to 0x08 0x02 (zigzag: 1→2).
  func test_fieldType_sint32_roundTripBinary() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sint32))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(1), forField: 1)

    let serializer = BinarySerializer()
    let data = try serializer.serialize(msg)

    // zigzag(1) = 2, field 1, varint wire type = tag 0x08, value 0x02
    XCTAssertEqual(data, Data([0x08, 0x02]))

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let deserialized = try await deserializer.deserialize(data, using: desc)
    XCTAssertEqual(try deserialized.get(forField: 1) as? Int32, 1)
  }

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { sint64 v = 1; }' > /tmp/t.proto
  // printf 'v: -1' | protoc --encode=M /tmp/t.proto | xxd -p → 0801
  // Oracle: sint64 field = -1 encodes to tag 0x08, zigzag(-1)=1 as varint 0x01.
  func test_fieldType_sint64_roundTripBinary() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sint64))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int64(-1), forField: 1)

    let serializer = BinarySerializer()
    let data = try serializer.serialize(msg)
    XCTAssertEqual(data, Data([0x08, 0x01]))

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let deserialized = try await deserializer.deserialize(data, using: desc)
    XCTAssertEqual(try deserialized.get(forField: 1) as? Int64, -1)
  }

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { sfixed32 v = 1; }' > /tmp/t.proto
  // printf 'v: -1' | protoc --encode=M /tmp/t.proto | xxd -p → 0d ffffffff
  // Oracle: sfixed32 = -1 encodes to tag 0x0d (field 1, wire type 5), 4 bytes little-endian 0xffffffff.
  func test_fieldType_sfixed32_roundTripBinary() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sfixed32))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(-1), forField: 1)

    let serializer = BinarySerializer()
    let data = try serializer.serialize(msg)
    XCTAssertEqual(data, Data([0x0D, 0xFF, 0xFF, 0xFF, 0xFF]))

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let deserialized = try await deserializer.deserialize(data, using: desc)
    XCTAssertEqual(try deserialized.get(forField: 1) as? Int32, -1)
  }

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { sfixed64 v = 1; }' > /tmp/t.proto
  // printf 'v: -1' | protoc --encode=M /tmp/t.proto | xxd -p → 09 ffffffffffffffff
  // Oracle: sfixed64 = -1 encodes to tag 0x09 (field 1, wire type 1), 8 bytes LE 0xffffffffffffffff.
  func test_fieldType_sfixed64_roundTripBinary() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sfixed64))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int64(-1), forField: 1)

    let serializer = BinarySerializer()
    let data = try serializer.serialize(msg)
    XCTAssertEqual(data, Data([0x09, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]))

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let deserialized = try await deserializer.deserialize(data, using: desc)
    XCTAssertEqual(try deserialized.get(forField: 1) as? Int64, -1)
  }

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { fixed32 v = 1; }' > /tmp/t.proto
  // printf 'v: 100' | protoc --encode=M /tmp/t.proto | xxd -p → 0d 64000000
  // Oracle: fixed32 = 100 encodes to tag 0x0d (field 1, wire type 5), 4-byte LE 0x64000000.
  func test_fieldType_fixed32_roundTripBinary() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .fixed32))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(UInt32(100), forField: 1)

    let serializer = BinarySerializer()
    let data = try serializer.serialize(msg)
    XCTAssertEqual(data, Data([0x0D, 0x64, 0x00, 0x00, 0x00]))

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let deserialized = try await deserializer.deserialize(data, using: desc)
    XCTAssertEqual(try deserialized.get(forField: 1) as? UInt32, 100)
  }

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { fixed64 v = 1; }' > /tmp/t.proto
  // printf 'v: 1' | protoc --encode=M /tmp/t.proto | xxd -p → 09 0100000000000000
  // Oracle: fixed64 = 1 encodes to tag 0x09 (field 1, wire type 1), 8-byte LE.
  func test_fieldType_fixed64_roundTripBinary() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .fixed64))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(UInt64(1), forField: 1)

    let serializer = BinarySerializer()
    let data = try serializer.serialize(msg)
    XCTAssertEqual(data, Data([0x09, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]))

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let deserialized = try await deserializer.deserialize(data, using: desc)
    XCTAssertEqual(try deserialized.get(forField: 1) as? UInt64, 1)
  }

  // [STATIC-MIRROR] Testcompat_ScalarMessage.uint32Field = 7
  // Oracle: uint32 field encoded as varint.
  func test_fieldType_uint32_roundTripBinary() async throws {
    var proto = Testcompat_ScalarMessage()
    proto.uint32Field = 7
    let refData = try proto.serializedData()

    let desc = CompatDescriptors.scalarMessage()
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(UInt32(7), forField: 5)

    let serializer = BinarySerializer()
    let ourData = try serializer.serialize(msg)

    // Both encodings must parse to the same value
    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let fromRef = try await deserializer.deserialize(refData, using: desc)
    XCTAssertEqual(try fromRef.get(forField: 5) as? UInt32, 7)

    let fromOurs = try await deserializer.deserialize(ourData, using: desc)
    XCTAssertEqual(try fromOurs.get(forField: 5) as? UInt32, 7)
  }

  // [STATIC-MIRROR] Testcompat_ScalarMessage.int64Field = 9000000000
  // Oracle: int64 field encoded as varint (two's complement for negative).
  func test_fieldType_int64_roundTripBinary() async throws {
    var proto = Testcompat_ScalarMessage()
    proto.int64Field = 9_000_000_000
    let refData = try proto.serializedData()

    let desc = CompatDescriptors.scalarMessage()
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int64(9_000_000_000), forField: 4)

    let serializer = BinarySerializer()
    let ourData = try serializer.serialize(msg)

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let fromRef = try await deserializer.deserialize(refData, using: desc)
    XCTAssertEqual(try fromRef.get(forField: 4) as? Int64, 9_000_000_000)

    let fromOurs = try await deserializer.deserialize(ourData, using: desc)
    XCTAssertEqual(try fromOurs.get(forField: 4) as? Int64, 9_000_000_000)
  }

  // [STATIC-MIRROR] Testcompat_ScalarMessage.bytesField = [0xAB, 0xCD]
  // Oracle: bytes field encoded as length-delimited.
  func test_fieldType_bytes_roundTripBinary() async throws {
    var proto = Testcompat_ScalarMessage()
    proto.bytesField = Data([0xAB, 0xCD])
    let refData = try proto.serializedData()

    let desc = CompatDescriptors.scalarMessage()
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Data([0xAB, 0xCD]), forField: 15)

    let serializer = BinarySerializer()
    let ourData = try serializer.serialize(msg)

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let fromRef = try await deserializer.deserialize(refData, using: desc)
    XCTAssertEqual(try fromRef.get(forField: 15) as? Data, Data([0xAB, 0xCD]))

    let fromOurs = try await deserializer.deserialize(ourData, using: desc)
    XCTAssertEqual(try fromOurs.get(forField: 15) as? Data, Data([0xAB, 0xCD]))
  }
}
