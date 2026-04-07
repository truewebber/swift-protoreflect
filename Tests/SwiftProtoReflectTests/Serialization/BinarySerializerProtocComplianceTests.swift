//
// BinarySerializerProtocComplianceTests.swift
// SwiftProtoReflectTests
//
// Covers _BinarySerializer.swift (81%→95%) and Public/Serialization.swift (80%→95%).
//
// Each assertion is backed by one of two oracles:
//   [PUBLIC-MIRROR] <File>.<testMethod> — same behavior verified on the public API
//   [PROTOC-BASH]   <command> — expected value produced by running protoc
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class BinarySerializerProtocComplianceTests: XCTestCase {

  // MARK: - sfixed32 / sfixed64 exact bytes

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { sfixed32 v = 1; }' > /tmp/t.proto
  // printf 'v: -42' | protoc --encode=M /tmp/t.proto | xxd -p
  // → 0dd6ffffff  (tag=0x0D=(1<<3)|5, -42 little-endian = D6 FF FF FF)
  func test_sfixed32_negativeValue_littleEndianEncoding() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sfixed32))

    var msg = MessageFactory().createMessage(from: desc)
    try msg.set(Int32(-42), forField: "v")

    let data = try BinarySerializer().serialize(msg)

    // Tag 0x0D = (1<<3)|5 (sfixed32 wire type = fixed32)
    // -42 as UInt32(bitPattern:) = 0xFFFFFFD6, little-endian = D6 FF FF FF
    XCTAssertEqual(data, Data([0x0D, 0xD6, 0xFF, 0xFF, 0xFF]))
  }

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { sfixed64 v = 1; }' > /tmp/t.proto
  // printf 'v: -1' | protoc --encode=M /tmp/t.proto | xxd -p
  // → 09ffffffffffffffff  (tag=0x09=(1<<3)|1, -1 little-endian 8 bytes = FF FF FF FF FF FF FF FF)
  func test_sfixed64_negativeOne_littleEndianEncoding() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sfixed64))

    var msg = MessageFactory().createMessage(from: desc)
    try msg.set(Int64(-1), forField: "v")

    let data = try BinarySerializer().serialize(msg)

    // Tag 0x09 = (1<<3)|1 (sfixed64 wire type = fixed64)
    // -1 as UInt64(bitPattern:) = 0xFFFFFFFFFFFFFFFF, little-endian
    XCTAssertEqual(data, Data([0x09, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]))
  }

  // MARK: - sint32 / sint64 zigzag encoding

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { sint32 v = 1; }' > /tmp/t.proto
  // printf 'v: -1' | protoc --encode=M /tmp/t.proto | xxd -p
  // → 0801  (tag=0x08=(1<<3)|0, zigzag(-1)=1, varint(1)=0x01)
  func test_sint32_negativeOne_zigzagEncoding() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sint32))

    var msg = MessageFactory().createMessage(from: desc)
    try msg.set(Int32(-1), forField: "v")

    let data = try BinarySerializer().serialize(msg)

    // Tag 0x08 = (1<<3)|0 (varint wire type)
    // zigzag(-1) = 1 → varint(1) = 0x01
    XCTAssertEqual(data, Data([0x08, 0x01]))
  }

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { sint32 v = 1; }' > /tmp/t.proto
  // printf 'v: -2' | protoc --encode=M /tmp/t.proto | xxd -p
  // → 0803  (zigzag(-2)=3, varint(3)=0x03)
  func test_sint32_negativeTwo_zigzagEncoding() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sint32))

    var msg = MessageFactory().createMessage(from: desc)
    try msg.set(Int32(-2), forField: "v")

    let data = try BinarySerializer().serialize(msg)

    // zigzag(-2) = 3 → varint = 0x03
    XCTAssertEqual(data, Data([0x08, 0x03]))
  }

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { sint64 v = 1; }' > /tmp/t.proto
  // printf 'v: -1' | protoc --encode=M /tmp/t.proto | xxd -p
  // → 0801  (zigzag64(-1)=1, varint(1)=0x01)
  func test_sint64_negativeOne_zigzagEncoding() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sint64))

    var msg = MessageFactory().createMessage(from: desc)
    try msg.set(Int64(-1), forField: "v")

    let data = try BinarySerializer().serialize(msg)

    // zigzag64(-1) = 1 → varint = 0x01
    XCTAssertEqual(data, Data([0x08, 0x01]))
  }

  // MARK: - ZigZag encoding static methods

  // [PROTOC-BASH] zigzag encoding formula: (n << 1) XOR (n >> 31)
  // Oracle: zigzag(0)=0, zigzag(-1)=1, zigzag(1)=2, zigzag(-2)=3, zigzag(Int32.min)=UInt32.max
  func test_zigzagEncode32_allCases() async throws {
    XCTAssertEqual(_BinarySerializer.zigzagEncode32(0), 0)
    XCTAssertEqual(_BinarySerializer.zigzagEncode32(-1), 1)
    XCTAssertEqual(_BinarySerializer.zigzagEncode32(1), 2)
    XCTAssertEqual(_BinarySerializer.zigzagEncode32(-2), 3)
    XCTAssertEqual(_BinarySerializer.zigzagEncode32(2), 4)
    XCTAssertEqual(_BinarySerializer.zigzagEncode32(Int32.max), 0xFFFF_FFFE)
    XCTAssertEqual(_BinarySerializer.zigzagEncode32(Int32.min), 0xFFFF_FFFF)
  }

  // [PROTOC-BASH] zigzag64 formula: (n << 1) XOR (n >> 63)
  // Oracle: zigzag64(0)=0, zigzag64(-1)=1
  func test_zigzagEncode64_allCases() async throws {
    XCTAssertEqual(_BinarySerializer.zigzagEncode64(0), 0)
    XCTAssertEqual(_BinarySerializer.zigzagEncode64(-1), 1)
    XCTAssertEqual(_BinarySerializer.zigzagEncode64(1), 2)
    XCTAssertEqual(_BinarySerializer.zigzagEncode64(-2), 3)
    XCTAssertEqual(_BinarySerializer.zigzagEncode64(Int64.max), 0xFFFF_FFFF_FFFF_FFFE)
    XCTAssertEqual(_BinarySerializer.zigzagEncode64(Int64.min), 0xFFFF_FFFF_FFFF_FFFF)
  }

  // MARK: - Group type encoding

  // [PROTOC-BASH]
  // echo 'syntax="proto2"; message M { optional group G = 1 { optional int32 v = 1; } }' > /tmp/t.proto
  // printf 'g { v: 42 }' | protoc --encode=M /tmp/t.proto | xxd -p
  // → 0b082a0c
  // 0x0B = (1<<3)|3 = startGroup tag for field 1
  // 0x08 = (1<<3)|0 = varint tag for inner field 1
  // 0x2A = 42 in varint
  // 0x0C = (1<<3)|4 = endGroup tag for field 1
  func test_groupType_serialization_correctWireFormat() async throws {
    // Group body descriptor
    var groupBodyDesc = MessageDescriptor(name: "G", fullName: "M.G", syntax: "proto2")
    groupBodyDesc.addField(FieldDescriptor(name: "v", number: 1, type: .int32))

    // Outer message with a group field
    var outerDesc = MessageDescriptor(name: "M", fullName: "M", syntax: "proto2")
    outerDesc.addField(
      FieldDescriptor(
        name: "g",
        number: 1,
        type: .group,
        typeName: "M.G"
      )
    )

    // Create group body message
    var groupMsg = MessageFactory().createMessage(from: groupBodyDesc)
    try groupMsg.set(Int32(42), forField: "v")

    // Set the group body on the outer message
    var outerMsg = MessageFactory().createMessage(from: outerDesc)
    try outerMsg.set(groupMsg, forField: "g")

    let data = try BinarySerializer().serialize(outerMsg)

    // [PROTOC-BASH] expected: 0B 08 2A 0C
    XCTAssertEqual(data, Data([0x0B, 0x08, 0x2A, 0x0C]))
  }

  // [PUBLIC-MIRROR] BinaryCompatScalarsTests — group with empty body
  // Oracle: group with no fields → only startGroup + endGroup tags
  func test_groupType_emptyBody_onlyBracketTags() async throws {
    let groupBodyDesc = MessageDescriptor(name: "G", fullName: "M.G", syntax: "proto2")

    var outerDesc = MessageDescriptor(name: "M", fullName: "M", syntax: "proto2")
    outerDesc.addField(
      FieldDescriptor(name: "g", number: 1, type: .group, typeName: "M.G")
    )

    let groupMsg = MessageFactory().createMessage(from: groupBodyDesc)
    var outerMsg = MessageFactory().createMessage(from: outerDesc)
    try outerMsg.set(groupMsg, forField: "g")

    let data = try BinarySerializer().serialize(outerMsg)

    // startGroup(1) = 0x0B, endGroup(1) = 0x0C
    XCTAssertEqual(data, Data([0x0B, 0x0C]))
  }

  // MARK: - unknown fields raw bytes passthrough

  // [PUBLIC-MIRROR] UnknownFieldsTests — unknownFields raw bytes appended verbatim
  // Oracle: unknownFields bytes appear at end of serialized output
  func test_unknownFields_appendedVerbatim() async throws {
    let unknownBytes = Data([0x78, 0x01])  // field 15, varint, value 1

    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    var msg = MessageFactory().createMessage(from: desc)
    try msg.set(Int32(1), forField: "id")
    msg.unknownFields = unknownBytes

    let data = try BinarySerializer().serialize(msg)

    // field 1, int32=1: 08 01
    // Unknown bytes appended: 78 01
    XCTAssertTrue(data.hasSuffix(unknownBytes), "Unknown fields should be appended verbatim at end")
    XCTAssertEqual(data, Data([0x08, 0x01, 0x78, 0x01]))
  }

  // MARK: - proto2 required fields

  // [PUBLIC-MIRROR] Proto2BinarySerializationTests — required field with default value IS serialized
  // Oracle: proto2 required fields always appear on wire even if at default value
  func test_proto2_requiredField_atDefaultValue_isSerialized() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M", syntax: "proto2")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32, isRequired: true))

    var msg = MessageFactory().createMessage(from: desc)
    try msg.set(Int32(0), forField: "id")  // default value

    let data = try BinarySerializer().serialize(msg)

    // Proto2 required: even zero must be on wire
    // field 1, varint, value 0: 0x08 0x00
    XCTAssertEqual(data, Data([0x08, 0x00]))
  }

  // MARK: - repeated field with usePackedRepeated: false

  // [PUBLIC-MIRROR] BinaryCompatRepeatedTests — repeated int32 non-packed encoding
  // Oracle: each element has its own tag when usePackedRepeated:false
  func test_repeatedInt32_nonPacked_eachElementHasOwnTag() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(
      FieldDescriptor(
        name: "vals",
        number: 1,
        type: .int32,
        isRepeated: true,
        isPacked: false
      )
    )

    var msg = MessageFactory().createMessage(from: desc)
    try msg.set([Int32(1), Int32(2), Int32(3)] as [Int32], forField: "vals")

    let serializer = BinarySerializer(options: SerializationOptions(usePackedRepeated: false))
    let data = try serializer.serialize(msg)

    // With isPacked:false, each element: 08 01, 08 02, 08 03
    XCTAssertEqual(data, Data([0x08, 0x01, 0x08, 0x02, 0x08, 0x03]))
  }

  // MARK: - SerializationOptions

  // [PUBLIC-MIRROR] BinaryCompatRepeatedTests — default options use packed
  // Oracle: default SerializationOptions has usePackedRepeated:true
  func test_serializationOptions_defaultValues() async throws {
    let opts = SerializationOptions()
    XCTAssertTrue(opts.usePackedRepeated)

    let opts2 = SerializationOptions(usePackedRepeated: false)
    XCTAssertFalse(opts2.usePackedRepeated)
  }

  // MARK: - WireType conversions (Public/Serialization.swift)

  // [PUBLIC-MIRROR] BinaryCompatScalarsTests — all wire types exist in Public API
  // Oracle: WireType enum has 6 cases matching protobuf spec
  func test_wireType_init_fromImplAllCases() async throws {
    XCTAssertEqual(WireType(from: _WireType.varint), .varint)
    XCTAssertEqual(WireType(from: _WireType.fixed64), .fixed64)
    XCTAssertEqual(WireType(from: _WireType.lengthDelimited), .lengthDelimited)
    XCTAssertEqual(WireType(from: _WireType.startGroup), .startGroup)
    XCTAssertEqual(WireType(from: _WireType.endGroup), .endGroup)
    XCTAssertEqual(WireType(from: _WireType.fixed32), .fixed32)
  }

  // [PUBLIC-MIRROR] BinaryCompatScalarsTests — reverse mapping
  // Oracle: _WireType.init(from:WireType) round-trips all cases
  func test_wireType_init_fromPubAllCases() async throws {
    XCTAssertEqual(_WireType(from: WireType.varint), _WireType.varint)
    XCTAssertEqual(_WireType(from: WireType.fixed64), _WireType.fixed64)
    XCTAssertEqual(_WireType(from: WireType.lengthDelimited), _WireType.lengthDelimited)
    XCTAssertEqual(_WireType(from: WireType.startGroup), _WireType.startGroup)
    XCTAssertEqual(_WireType(from: WireType.endGroup), _WireType.endGroup)
    XCTAssertEqual(_WireType(from: WireType.fixed32), _WireType.fixed32)
  }

  // MARK: - SerializationError.description (Public/Serialization.swift)

  // [PUBLIC-MIRROR] BinarySerializerTypeMismatchTests — error descriptions for readability
  // Oracle: each case has a human-readable description
  func test_serializationError_description_allCases() async throws {
    let e1 = SerializationError.invalidFieldType(
      fieldName: "f",
      expectedType: "Array",
      actualType: "String"
    )
    XCTAssertTrue(e1.description.contains("f"))
    XCTAssertTrue(e1.description.contains("Array"))

    let e2 = SerializationError.valueTypeMismatch(expected: "Int32", actual: "String")
    XCTAssertTrue(e2.description.contains("Int32"))

    let e3 = SerializationError.missingMapEntryInfo(fieldName: "mymap")
    XCTAssertTrue(e3.description.contains("mymap"))

    let e4 = SerializationError.missingFieldValue(fieldName: "id")
    XCTAssertTrue(e4.description.contains("id"))

    let e5 = SerializationError.unsupportedFieldType(type: "oneof")
    XCTAssertTrue(e5.description.contains("oneof"))
  }

  // MARK: - DeserializationError.description (Public/Serialization.swift)

  // [PUBLIC-MIRROR] BinaryDeserializerTests — deserialization error descriptions
  // Oracle: each DeserializationError case has non-empty description
  func test_deserializationError_description_allCases() async throws {
    XCTAssertFalse(DeserializationError.truncatedVarint.description.isEmpty)
    XCTAssertFalse(DeserializationError.truncatedMessage.description.isEmpty)
    XCTAssertFalse(DeserializationError.invalidWireType(tag: 99).description.isEmpty)
    XCTAssertFalse(
      DeserializationError.wireTypeMismatch(
        fieldName: "f",
        expected: .varint,
        actual: .fixed32
      ).description.isEmpty
    )
    XCTAssertFalse(DeserializationError.invalidUTF8String.description.isEmpty)
    XCTAssertFalse(DeserializationError.malformedPackedField(fieldName: "pf").description.isEmpty)
    XCTAssertFalse(DeserializationError.malformedMapEntry(fieldName: "mf").description.isEmpty)
    XCTAssertFalse(DeserializationError.missingMapEntryInfo(fieldName: "mm").description.isEmpty)
    XCTAssertFalse(DeserializationError.missingTypeName(fieldType: "message").description.isEmpty)
    XCTAssertFalse(DeserializationError.unsupportedNestedMessage(typeName: "X").description.isEmpty)
    XCTAssertFalse(DeserializationError.unsupportedFieldType(type: "group").description.isEmpty)
  }

  // MARK: - DeserializationError.init(from:) (Public/Serialization.swift)

  // [PUBLIC-MIRROR] BinaryDeserializerTests — all _DeserializationError cases convert
  // Oracle: each internal error case maps to correct public case
  func test_deserializationError_initFromImpl_allCases() async throws {
    XCTAssertEqual(DeserializationError(from: _DeserializationError.truncatedVarint), .truncatedVarint)
    XCTAssertEqual(DeserializationError(from: _DeserializationError.truncatedMessage), .truncatedMessage)
    XCTAssertEqual(
      DeserializationError(from: _DeserializationError.invalidWireType(tag: 7)),
      .invalidWireType(tag: 7)
    )
    XCTAssertEqual(
      DeserializationError(
        from: _DeserializationError.wireTypeMismatch(
          fieldName: "f",
          expected: _WireType.varint,
          actual: _WireType.fixed32
        )
      ),
      .wireTypeMismatch(fieldName: "f", expected: .varint, actual: .fixed32)
    )
    XCTAssertEqual(DeserializationError(from: _DeserializationError.invalidUTF8String), .invalidUTF8String)
    XCTAssertEqual(
      DeserializationError(from: _DeserializationError.malformedPackedField(fieldName: "pf")),
      .malformedPackedField(fieldName: "pf")
    )
    XCTAssertEqual(
      DeserializationError(from: _DeserializationError.malformedMapEntry(fieldName: "mf")),
      .malformedMapEntry(fieldName: "mf")
    )
    XCTAssertEqual(
      DeserializationError(from: _DeserializationError.missingMapEntryInfo(fieldName: "mm")),
      .missingMapEntryInfo(fieldName: "mm")
    )
    XCTAssertEqual(
      DeserializationError(from: _DeserializationError.missingTypeName(fieldType: "message")),
      .missingTypeName(fieldType: "message")
    )
    XCTAssertEqual(
      DeserializationError(from: _DeserializationError.unsupportedNestedMessage(typeName: "X")),
      .unsupportedNestedMessage(typeName: "X")
    )
    XCTAssertEqual(
      DeserializationError(from: _DeserializationError.unsupportedFieldType(type: "group")),
      .unsupportedFieldType(type: "group")
    )
  }

  // MARK: - SerializationError.init(from:) (Public/Serialization.swift)

  // [PUBLIC-MIRROR] BinarySerializerTypeMismatchTests — all _SerializationError cases convert
  // Oracle: each internal error case maps to correct public case
  func test_serializationError_initFromImpl_allCases() async throws {
    XCTAssertEqual(
      SerializationError(
        from: _SerializationError.invalidFieldType(fieldName: "f", expectedType: "E", actualType: "A")
      ),
      .invalidFieldType(fieldName: "f", expectedType: "E", actualType: "A")
    )
    XCTAssertEqual(
      SerializationError(from: _SerializationError.valueTypeMismatch(expected: "E", actual: "A")),
      .valueTypeMismatch(expected: "E", actual: "A")
    )
    XCTAssertEqual(
      SerializationError(from: _SerializationError.missingMapEntryInfo(fieldName: "mm")),
      .missingMapEntryInfo(fieldName: "mm")
    )
    XCTAssertEqual(
      SerializationError(from: _SerializationError.missingFieldValue(fieldName: "id")),
      .missingFieldValue(fieldName: "id")
    )
    XCTAssertEqual(
      SerializationError(from: _SerializationError.unsupportedFieldType(type: "oneof")),
      .unsupportedFieldType(type: "oneof")
    )
  }

  // MARK: - _SerializationError.description (internal)

  // [PUBLIC-MIRROR] BinarySerializerTypeMismatchTests — internal error description
  // Oracle: each _SerializationError case has non-empty description
  func test_serializationError_internalDescription_allCases() async throws {
    let e1 = _SerializationError.invalidFieldType(
      fieldName: "f",
      expectedType: "Array",
      actualType: "String"
    )
    XCTAssertFalse(e1.description.isEmpty)

    let e2 = _SerializationError.valueTypeMismatch(expected: "Int32", actual: "String")
    XCTAssertFalse(e2.description.isEmpty)

    let e3 = _SerializationError.missingMapEntryInfo(fieldName: "mymap")
    XCTAssertFalse(e3.description.isEmpty)

    let e4 = _SerializationError.missingFieldValue(fieldName: "id")
    XCTAssertFalse(e4.description.isEmpty)

    let e5 = _SerializationError.unsupportedFieldType(type: "oneof")
    XCTAssertFalse(e5.description.isEmpty)
  }

  // MARK: - DeserializationOptions

  // [PUBLIC-MIRROR] BinaryDeserializerTests — DeserializationOptions stores settings
  // Oracle: DeserializationOptions preserves all constructor args
  func test_deserializationOptions_preservesSettings() async throws {
    let registry = TypeRegistry()
    let opts = DeserializationOptions(
      preserveUnknownFields: false,
      strictUTF8Validation: false,
      typeRegistry: registry
    )
    XCTAssertFalse(opts.preserveUnknownFields)
    XCTAssertFalse(opts.strictUTF8Validation)
  }

  // [PUBLIC-MIRROR] BinaryDeserializerTests — default options
  // Oracle: default options have preserveUnknownFields:true, strictUTF8Validation:true
  func test_deserializationOptions_defaultValues() async throws {
    let registry = TypeRegistry()
    let opts = DeserializationOptions(typeRegistry: registry)
    XCTAssertTrue(opts.preserveUnknownFields)
    XCTAssertTrue(opts.strictUTF8Validation)
  }

  // MARK: - BinaryDeserializer async API

  // [PUBLIC-MIRROR] BinarySerializationIntegrationTests — round-trip via public async API
  // Oracle: serialize+deserialize gives back the same field values
  func test_binaryDeserializer_asyncAPI_roundTrip() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    desc.addField(FieldDescriptor(name: "name", number: 2, type: .string))

    var msg = MessageFactory().createMessage(from: desc)
    try msg.set(Int32(42), forField: "id")
    try msg.set("Alice", forField: "name")

    let registry = TypeRegistry()
    let serializer = BinarySerializer()
    let data = try serializer.serialize(msg)

    let deserializer = BinaryDeserializer(
      options: DeserializationOptions(typeRegistry: registry)
    )
    let result = try await deserializer.deserialize(data, using: desc)

    XCTAssertEqual(try result.get(forField: "id") as? Int32, 42)
    XCTAssertEqual(try result.get(forField: "name") as? String, "Alice")
  }

  // MARK: - proto3 default values NOT on wire

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { int32 v = 1; }' > /tmp/t.proto
  // printf 'v: 0' | protoc --encode=M /tmp/t.proto | xxd -p
  // → (empty) — proto3 default int32=0 is not serialized
  func test_proto3_defaultInt32_notSerializedOnWire() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M", syntax: "proto3")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .int32))

    var msg = MessageFactory().createMessage(from: desc)
    try msg.set(Int32(0), forField: "v")

    let data = try BinarySerializer().serialize(msg)

    // Proto3: default values not on wire
    XCTAssertEqual(data, Data())
  }
}

// MARK: - Data extension for test helpers

extension Data {
  fileprivate func hasSuffix(_ suffix: Data) -> Bool {
    guard count >= suffix.count else { return false }
    return self.suffix(suffix.count) == suffix
  }
}
