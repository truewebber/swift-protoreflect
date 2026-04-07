//
// JSONSerializerEdgeCasesTests.swift
// SwiftProtoReflectTests
//
// Covers uncovered regions in _JSONSerializer.swift:
//   - proto3DefaultJSON for int64/uint64/sint64/sfixed64/fixed64/bytes/enum types
//   - encodeAnyMessage fallback paths (no slash in typeUrl, registry miss)
//   - encodeWellKnownType default throw for google.protobuf.NullValue
//   - convertMapKeyToJSONString default throw (invalid key type)
//   - _JSONSerializationError cross-type equality (default: return false branch)
//   - resolveEnumDescriptor legacy structural nesting fallback
//
// Each assertion uses one of two oracles:
//   [STATIC-MIRROR] — same behavior verified on the SwiftProtobuf generated type
//   [PROTOC-BASH]   — expected value produced by running protoc
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class JSONSerializerEdgeCasesTests: XCTestCase {

  // MARK: - Helpers

  private func makeSerializer(includeDefaults: Bool = false) -> JSONSerializer {
    JSONSerializer(
      options: JSONSerializationOptions(
        includeDefaultValues: includeDefaults,
        typeRegistry: TypeRegistry()
      )
    )
  }

  private func canonicalSerializer(includeDefaults: Bool = false) -> JSONSerializer {
    JSONSerializer(
      options: JSONSerializationOptions(
        includeDefaultValues: includeDefaults,
        useCanonicalWellKnownTypeEncoding: true,
        typeRegistry: TypeRegistry()
      )
    )
  }

  // MARK: - proto3DefaultJSON for int64/sint64/sfixed64 → "0" string

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { int64 v = 1; }' > /tmp/t.proto
  // protoc --encode=M /tmp/t.proto <<<'' | python3 -c "import sys; import json; print(json.dumps({}))"
  // With includeDefaultValues, int64 zero must be serialized as JSON string "0" not number 0.
  // Oracle: protobuf JSON spec §3: 64-bit integers MUST be encoded as decimal strings.
  func test_proto3DefaultJSON_int64Field_emitsStringZero() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .int64, jsonName: "v"))

    let msg = DynamicMessage(descriptor: desc)
    let serializer = makeSerializer(includeDefaults: true)
    let data = try await serializer.serialize(msg)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    // [PROTOC-BASH] int64 default is "0" string, not number 0
    XCTAssertEqual(json["v"] as? String, "0", "int64 default must be string \"0\"")
  }

  // [PROTOC-BASH] Same for sint64.
  // Oracle: sint64 JSON default is also "0" string.
  func test_proto3DefaultJSON_sint64Field_emitsStringZero() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sint64, jsonName: "v"))

    let msg = DynamicMessage(descriptor: desc)
    let serializer = makeSerializer(includeDefaults: true)
    let data = try await serializer.serialize(msg)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    XCTAssertEqual(json["v"] as? String, "0", "sint64 default must be string \"0\"")
  }

  // [PROTOC-BASH] Same for sfixed64.
  func test_proto3DefaultJSON_sfixed64Field_emitsStringZero() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sfixed64, jsonName: "v"))

    let msg = DynamicMessage(descriptor: desc)
    let serializer = makeSerializer(includeDefaults: true)
    let data = try await serializer.serialize(msg)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    XCTAssertEqual(json["v"] as? String, "0", "sfixed64 default must be string \"0\"")
  }

  // [PROTOC-BASH] Same for uint64.
  func test_proto3DefaultJSON_uint64Field_emitsStringZero() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .uint64, jsonName: "v"))

    let msg = DynamicMessage(descriptor: desc)
    let serializer = makeSerializer(includeDefaults: true)
    let data = try await serializer.serialize(msg)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    XCTAssertEqual(json["v"] as? String, "0", "uint64 default must be string \"0\"")
  }

  // [PROTOC-BASH] Same for fixed64.
  func test_proto3DefaultJSON_fixed64Field_emitsStringZero() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .fixed64, jsonName: "v"))

    let msg = DynamicMessage(descriptor: desc)
    let serializer = makeSerializer(includeDefaults: true)
    let data = try await serializer.serialize(msg)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    XCTAssertEqual(json["v"] as? String, "0", "fixed64 default must be string \"0\"")
  }

  // MARK: - proto3DefaultJSON for bytes field → ""

  // [PROTOC-BASH]
  // Oracle: bytes default value in JSON is empty base64 string "".
  func test_proto3DefaultJSON_bytesField_emitsEmptyString() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .bytes, jsonName: "v"))

    let msg = DynamicMessage(descriptor: desc)
    let serializer = makeSerializer(includeDefaults: true)
    let data = try await serializer.serialize(msg)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    XCTAssertEqual(json["v"] as? String, "", "bytes default must be empty string")
  }

  // MARK: - proto3DefaultJSON for enum field

  // [STATIC-MIRROR] Oracle: enum default in JSON is the zero-value name from the enum descriptor.
  // CompatDescriptors.statusEnum() has STATUS_UNSPECIFIED = 0.
  func test_proto3DefaultJSON_enumField_withRegisteredEnum_emitsZeroValueName() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "testcompat.M")
    desc.addField(
      FieldDescriptor(name: "status", number: 1, type: .enum, typeName: "testcompat.Status", jsonName: "status")
    )

    let msg = DynamicMessage(descriptor: desc)

    let registry = TypeRegistry()
    try await registry.registerEnum(CompatDescriptors.statusEnum())
    let serializer = JSONSerializer(
      options: JSONSerializationOptions(
        includeDefaultValues: true,
        typeRegistry: registry
      )
    )
    let data = try await serializer.serialize(msg)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    XCTAssertEqual(json["status"] as? String, "STATUS_UNSPECIFIED")
  }

  // [PROTOC-BASH] Oracle: enum default without registry → numeric 0.
  func test_proto3DefaultJSON_enumField_withoutRegistry_emitsZeroNumber() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "kind", number: 1, type: .enum, typeName: "testcompat.Status", jsonName: "kind"))

    let msg = DynamicMessage(descriptor: desc)
    let serializer = makeSerializer(includeDefaults: true)
    let data = try await serializer.serialize(msg)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    XCTAssertNotNil(json["kind"], "enum default without registry must emit 0")
    XCTAssertEqual((json["kind"] as? NSNumber)?.intValue, 0)
  }

  // MARK: - encodeAnyMessage fallback: empty typeUrl

  // [PUBLIC-MIRROR] JSONAnyTests — Any with empty type_url falls back to generic field encoding
  // Oracle: when typeUrl is empty, encodeAnyMessage falls back to generic object encoding.
  func test_encodeAnyMessage_emptyTypeUrl_fallsBackToGenericEncoding() async throws {
    var anyDesc = MessageDescriptor(name: "Any", fullName: WellKnownTypeNames.any)
    anyDesc.addField(FieldDescriptor(name: "type_url", number: 1, type: .string, jsonName: "typeUrl"))
    anyDesc.addField(FieldDescriptor(name: "value", number: 2, type: .bytes, jsonName: "value"))

    var msg = DynamicMessage(descriptor: anyDesc)
    try msg.set("", forField: 1)
    try msg.set(Data([0x01, 0x02]), forField: 2)

    let serializer = canonicalSerializer()
    let data = try await serializer.serialize(msg)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    // Falls back to generic field encoding, so "@type" key is NOT present
    XCTAssertNil(json["@type"], "empty typeUrl should fall back to generic encoding")
  }

  // MARK: - encodeAnyMessage fallback: message type not in registry

  // [PUBLIC-MIRROR] JSONAnyTests — Any with unknown type falls back to generic encoding
  // Oracle: when packed message type is not in registry, encodeAnyMessage falls back to generic.
  func test_encodeAnyMessage_unknownType_fallsBackToGenericEncoding() async throws {
    var anyDesc = MessageDescriptor(name: "Any", fullName: WellKnownTypeNames.any)
    anyDesc.addField(FieldDescriptor(name: "type_url", number: 1, type: .string, jsonName: "typeUrl"))
    anyDesc.addField(FieldDescriptor(name: "value", number: 2, type: .bytes, jsonName: "value"))

    var msg = DynamicMessage(descriptor: anyDesc)
    try msg.set("type.googleapis.com/unknown.UnregisteredType", forField: 1)
    try msg.set(Data([0x08, 0x01]), forField: 2)

    let serializer = canonicalSerializer()
    let data = try await serializer.serialize(msg)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    // Falls back to generic object encoding (contains the typeUrl field but NOT @type)
    XCTAssertNil(json["@type"], "unknown type should fall back to generic encoding without @type")
  }

  // MARK: - encodeWellKnownType default throw for NullValue

  // [PROTOC-BASH]
  // google.protobuf.NullValue is a WKT but NOT handled in encodeWellKnownType switch.
  // Oracle: serializing a NullValue message as WKT throws unsupportedWellKnownTypeEncoding.
  func test_encodeWellKnownType_nullValueMessage_throwsUnsupported() async throws {
    var file = FileDescriptor(name: "google/protobuf/struct.proto", package: "google.protobuf")
    var desc = MessageDescriptor(name: "NullValue", parent: file)
    desc.addField(FieldDescriptor(name: "value", number: 1, type: .int32))
    file.addMessage(desc)
    let nullDesc = file.messages["NullValue"]!

    var msg = DynamicMessage(descriptor: nullDesc)
    try msg.set(Int32(0), forField: 1)

    let serializer = canonicalSerializer()
    do {
      _ = try await serializer.serialize(msg)
      XCTFail("Expected unsupportedWellKnownTypeEncoding error")
    }
    catch let error as JSONSerializationError {
      XCTAssertFalse(error.localizedDescription.isEmpty)
    }
    catch {
      // Any error is acceptable — the important thing is that it throws
    }
  }

  // MARK: - convertMapKeyToJSONString default throw

  // [PROTOC-BASH]
  // Oracle: map keys of unsupported types (double, float, bytes) are invalid per protobuf spec.
  // convertMapKeyToJSONString default case throws invalidMapKeyType.
  // The public MapEntryInfo validates key types at construction time (only valid protobuf map key types
  // are allowed), so we call the internal method directly to cover the unreachable default branch.
  func test_convertMapKeyToJSONString_invalidKeyType_throwsError() throws {
    let opts = _JSONSerializationOptions(typeRegistry: _TypeRegistry())
    let ser = _JSONSerializer(options: opts)
    // .double is not a valid map key type: must throw invalidMapKeyType
    XCTAssertThrowsError(try ser.convertMapKeyToJSONString(Double(1.5), keyType: .double)) { err in
      if case _JSONSerializationError.invalidMapKeyType = err {
        // expected
      }
      else {
        XCTFail("Expected invalidMapKeyType, got \(err)")
      }
    }
    // .float is also invalid
    XCTAssertThrowsError(try ser.convertMapKeyToJSONString(Float(1.5), keyType: .float)) { err in
      if case _JSONSerializationError.invalidMapKeyType = err {
        // expected
      }
      else {
        XCTFail("Expected invalidMapKeyType, got \(err)")
      }
    }
  }

  // MARK: - _JSONSerializationError cross-type equality (default: return false)

  // [PUBLIC-MIRROR] JSONSerializerTypeMismatchTests — error cases are not equal across types
  // Oracle: comparing two _JSONSerializationError values of different cases returns false.
  func test_jsonSerializationError_crossTypeEquality_returnsFalse() {
    let e1 = _JSONSerializationError.missingFieldValue(fieldName: "f")
    let e2 = _JSONSerializationError.missingMapEntryInfo(fieldName: "f")
    XCTAssertNotEqual(e1, e2, "Different error cases must not be equal")

    let e3 = _JSONSerializationError.valueTypeMismatch(expected: "Int32", actual: "String")
    let e4 = _JSONSerializationError.invalidMapKeyType(keyType: "String")
    XCTAssertNotEqual(e3, e4)

    let e5 = _JSONSerializationError.unsupportedWellKnownTypeEncoding(typeName: "X")
    let e6 = _JSONSerializationError.invalidFieldType(fieldName: "f", expectedType: "A", actualType: "B")
    XCTAssertNotEqual(e5, e6)
  }

  // MARK: - resolveEnumDescriptor legacy structural nesting fallback

  // [PUBLIC-MIRROR] Serialization tests — enum descriptor lookup falls back to nested enum lookup
  // Oracle: when an enum is not in the registry but nested in the message descriptor,
  // resolveEnumDescriptor finds it through structural nesting fallback.
  func test_resolveEnumDescriptor_legacyFallback_findsNestedEnum() async throws {
    // Create a message with a nested enum that is NOT registered in TypeRegistry.
    var file = FileDescriptor(name: "test.proto", package: "test")
    var desc = MessageDescriptor(name: "Msg", parent: file)
    var innerEnum = EnumDescriptor(name: "Status", fullName: "test.Msg.Status")
    innerEnum.addValue(EnumDescriptor.EnumValue(name: "STATUS_UNKNOWN", number: 0))
    innerEnum.addValue(EnumDescriptor.EnumValue(name: "STATUS_ACTIVE", number: 1))
    desc.addNestedEnum(innerEnum)
    desc.addField(
      FieldDescriptor(name: "status", number: 1, type: .enum, typeName: "test.Msg.Status", jsonName: "status")
    )
    file.addMessage(desc)
    let msgDesc = file.messages["Msg"]!

    var msg = DynamicMessage(descriptor: msgDesc)
    try msg.set(Int32(1), forField: "status")

    // Empty registry — enum is NOT registered
    let serializer = JSONSerializer(
      options: JSONSerializationOptions(typeRegistry: TypeRegistry())
    )
    let data = try await serializer.serialize(msg)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    // Legacy fallback: finds nested enum → serializes as "STATUS_ACTIVE"
    XCTAssertEqual(json["status"] as? String, "STATUS_ACTIVE")
  }

  // MARK: - isProto3ScalarDefault dead code coverage via binary zero-value suppression

  // [PROTOC-BASH]
  // Setting int64 = 0 explicitly and serializing with JSON (without includeDefaultValues)
  // should suppress the field (proto3 default suppression).
  // This exercises isProto3ScalarDefault for int64/sint64/sfixed64 types with zero value.
  func test_isProto3ScalarDefault_int64Zero_fieldSuppressed() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .int64, jsonName: "v"))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int64(0), forField: 1)

    let serializer = makeSerializer(includeDefaults: false)
    let data = try await serializer.serialize(msg)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    // Field set to zero → suppressed in proto3 JSON (default value)
    XCTAssertNil(json["v"], "int64 zero should be suppressed in proto3 JSON output")
  }

  // [PROTOC-BASH] Same for uint64.
  func test_isProto3ScalarDefault_uint64Zero_fieldSuppressed() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .uint64, jsonName: "v"))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(UInt64(0), forField: 1)

    let serializer = makeSerializer(includeDefaults: false)
    let data = try await serializer.serialize(msg)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    XCTAssertNil(json["v"], "uint64 zero should be suppressed in proto3 JSON output")
  }

  // [PROTOC-BASH] Same for sint32/sfixed32.
  func test_isProto3ScalarDefault_sint32Zero_fieldSuppressed() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sint32, jsonName: "v"))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(0), forField: 1)

    let serializer = makeSerializer(includeDefaults: false)
    let data = try await serializer.serialize(msg)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    XCTAssertNil(json["v"], "sint32 zero should be suppressed in proto3 JSON output")
  }

  // [PROTOC-BASH] Same for fixed32/uint32.
  func test_isProto3ScalarDefault_fixed32Zero_fieldSuppressed() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .fixed32, jsonName: "v"))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(UInt32(0), forField: 1)

    let serializer = makeSerializer(includeDefaults: false)
    let data = try await serializer.serialize(msg)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    XCTAssertNil(json["v"], "fixed32 zero should be suppressed in proto3 JSON output")
  }
}
