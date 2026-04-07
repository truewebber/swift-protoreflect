//
// BinaryDeserializerEdgeCasesTests.swift
// SwiftProtoReflectTests
//
// Covers edge-case paths in Serialization/_BinaryDeserializer.swift:
//   - skipUnknownField for .startGroup wire type (→ skipGroup)
//   - skipGroup reading nested groups until endGroup
//   - resolveMessageDescriptor via structural nesting fallback (not TypeRegistry)
//   - Unknown fields accumulated when preserveUnknownFields is true
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class BinaryDeserializerEdgeCasesTests: XCTestCase {

  // MARK: - skipUnknownField with startGroup wire type

  // [PROTOC-BASH]
  // Simulate encountering an unknown group field (wire type 3 = startGroup) in binary data.
  // Proto binary format for unknown group: 0x0B (startGroup tag field=1) 0x10 0x2A (varint inner field)
  // 0x0C (endGroup tag field=1)
  // Our deserializer should skip the unknown group and proceed without error.
  func test_deserialize_unknownGroupField_skippedCorrectly() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "id", number: 2, type: .int32))

    // Binary data: unknown group field=1 (startGroup tag 0x0B), inner varint field 2 (0x10, 0x2A=42),
    // endGroup tag (0x0C), then known field 2 int32 = 7 (0x10, 0x07)
    let data = Data([
      0x0B,  // field=1, wireType=3 (startGroup)
      0x10, 0x2A,  // inner field 2, varint 42
      0x0C,  // field=1, wireType=4 (endGroup)
      0x10, 0x07,  // field=2, wireType=0 (varint), value=7
    ])

    let deserializer = BinaryDeserializer(
      options: DeserializationOptions(typeRegistry: TypeRegistry())
    )

    let result = try await deserializer.deserialize(data, using: desc)
    let idValue = try result.get(forField: "id") as? Int32
    XCTAssertEqual(idValue, 7)
  }

  // MARK: - resolveMessageDescriptor via structural nesting path

  // [PUBLIC-MIRROR] BinaryDeserializationTests — nested message deserialization
  // Oracle: nested message descriptor resolved from parent descriptor's nestedMessages dict
  func test_deserialize_nestedMessage_resolvedFromStructuralNesting() async throws {
    var innerDesc = MessageDescriptor(name: "Inner", fullName: "M.Inner")
    innerDesc.addField(FieldDescriptor(name: "val", number: 1, type: .int32))

    var outerDesc = MessageDescriptor(name: "M", fullName: "M")
    outerDesc.addNestedMessage(innerDesc)
    outerDesc.addField(FieldDescriptor(name: "inner", number: 1, type: .message, typeName: "M.Inner"))

    var innerMsg = MessageFactory().createMessage(from: innerDesc)
    try innerMsg.set(Int32(42), forField: "val")

    var outerMsg = MessageFactory().createMessage(from: outerDesc)
    try outerMsg.set(innerMsg, forField: "inner")

    let serializer = BinarySerializer()
    let data = try serializer.serialize(outerMsg)

    // Deserialize WITHOUT adding types to TypeRegistry — forces structural nesting resolution
    let deserializer = BinaryDeserializer(
      options: DeserializationOptions(typeRegistry: TypeRegistry())
    )
    let result = try await deserializer.deserialize(data, using: outerDesc)
    XCTAssertNotNil(result)
    XCTAssertNotNil(try result.get(forField: "inner"))
  }

  // MARK: - wireTypeMismatch error on wrong wire type

  // [PUBLIC-MIRROR] BinaryDeserializationTests.testDeserialize_wireTypeMismatch_throwsError()
  // Oracle: sending length-delimited data for an int32 field throws wireTypeMismatch
  func test_deserialize_wireTypeMismatch_lengthDelimitedForVarint_throws() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    // Field 1, wireType=2 (length-delimited) for an int32 field (expects wireType=0/varint)
    let data = Data([0x0A, 0x01, 0x42])  // tag=0x0A (field=1, wire=2), len=1, byte=0x42

    let deserializer = BinaryDeserializer(
      options: DeserializationOptions(typeRegistry: TypeRegistry())
    )

    do {
      _ = try await deserializer.deserialize(data, using: desc)
      XCTFail("Expected wireTypeMismatch error")
    }
    catch {}
  }

  // MARK: - invalidUTF8String error

  // [PUBLIC-MIRROR] BinaryDeserializationTests — invalid UTF-8 string error
  // Oracle: deserializing invalid UTF-8 bytes for a string field throws invalidUTF8String
  func test_deserialize_invalidUTF8String_throws() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "name", number: 1, type: .string))

    // Field 1, wire=2 (length-delimited), 2 bytes of invalid UTF-8
    let data = Data([0x0A, 0x02, 0xFF, 0xFE])

    let deserializer = BinaryDeserializer(
      options: DeserializationOptions(typeRegistry: TypeRegistry())
    )

    do {
      _ = try await deserializer.deserialize(data, using: desc)
      XCTFail("Expected invalidUTF8String error")
    }
    catch let error as DeserializationError {
      if case .invalidUTF8String = error {
        // Expected
      }
      else {
        XCTFail("Expected invalidUTF8String, got \(error)")
      }
    }
  }

  // MARK: - preserveUnknownFields: unknown varint field stored as raw bytes

  // [PUBLIC-MIRROR] DeserializationOptionsTests — preserveUnknownFields option behavior
  // Oracle: unknown varint field is preserved in unknownFields when option is true
  func test_deserialize_unknownVarintField_preservedInUnknownFields() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    // Unknown field 3, varint value 99
    let data = Data([
      0x08, 0x07,  // field=1, varint=7 (known)
      0x18, 0x63,  // field=3, varint=99 (unknown)
    ])

    let options = DeserializationOptions(
      preserveUnknownFields: true,
      typeRegistry: TypeRegistry()
    )
    let deserializer = BinaryDeserializer(options: options)
    let result = try await deserializer.deserialize(data, using: desc)
    XCTAssertEqual(try result.get(forField: "id") as? Int32, 7)
    XCTAssertNotNil(result.unknownFields)
  }
}
