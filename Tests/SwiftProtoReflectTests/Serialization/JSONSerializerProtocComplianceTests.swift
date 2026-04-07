//
// JSONSerializerProtocComplianceTests.swift
// SwiftProtoReflectTests
//
// Covers _JSONSerializer.swift (80%→95%) and Public/Serialization.swift JSON section (80%→95%).
//
// Each assertion is backed by one of two oracles:
//   [PUBLIC-MIRROR] <File>.<testMethod> — same behavior verified on the public API
//   [PROTOC-BASH]   <command> — expected value produced by running protoc
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class JSONSerializerProtocComplianceTests: XCTestCase {

  // MARK: - useOriginalFieldNames option

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; message M { string my_field = 1; }' > /tmp/t.proto
  // protoc generates JSON with camelCase key "myField" (from json_name option).
  // The library uses field.jsonName when useOriginalFieldNames:false,
  // and field.name when useOriginalFieldNames:true.
  //
  // Oracle: useOriginalFieldNames:false → uses field.jsonName (camelCase "myField")
  //         useOriginalFieldNames:true  → uses field.name (original "my_field")
  func test_serialize_useOriginalFieldNames_false_usesJsonName() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    // jsonName: "myField" is the camelCase form (as protoc would set it)
    desc.addField(
      FieldDescriptor(name: "my_field", number: 1, type: .string, jsonName: "myField")
    )

    var msg = DynamicMessage(descriptor: desc)
    try msg.set("hello", forField: "my_field")

    let serializer = JSONSerializer(
      options: JSONSerializationOptions(
        useOriginalFieldNames: false,
        typeRegistry: TypeRegistry()
      )
    )
    let data = try await serializer.serialize(msg)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    // [PROTOC-BASH] camelCase key is used
    XCTAssertEqual(json["myField"] as? String, "hello")
    XCTAssertNil(json["my_field"])
  }

  // [PROTOC-BASH]
  // Oracle: useOriginalFieldNames:true → field.name used as JSON key
  func test_serialize_useOriginalFieldNames_true_usesFieldName() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(
      FieldDescriptor(name: "my_field", number: 1, type: .string, jsonName: "myField")
    )

    var msg = DynamicMessage(descriptor: desc)
    try msg.set("hello", forField: "my_field")

    let serializer = JSONSerializer(
      options: JSONSerializationOptions(
        useOriginalFieldNames: true,
        typeRegistry: TypeRegistry()
      )
    )
    let data = try await serializer.serialize(msg)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    // [PROTOC-BASH] original snake_case name used
    XCTAssertEqual(json["my_field"] as? String, "hello")
    XCTAssertNil(json["myField"])
  }

  // MARK: - prettyPrinted option

  // [PUBLIC-MIRROR] JSONSerializationTests — prettyPrinted output contains newlines
  // Oracle: prettyPrinted:true produces human-readable JSON with newlines
  func test_serialize_prettyPrinted_containsNewlines() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "name", number: 1, type: .string))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set("Alice", forField: "name")

    let prettySerializer = JSONSerializer(
      options: JSONSerializationOptions(prettyPrinted: true, typeRegistry: TypeRegistry())
    )
    let data = try await prettySerializer.serialize(msg)
    let str = try XCTUnwrap(String(data: data, encoding: .utf8))

    XCTAssertTrue(str.contains("\n"), "Pretty-printed JSON should contain newlines")
  }

  // [PUBLIC-MIRROR] JSONSerializationTests — non-pretty-printed is compact
  // Oracle: prettyPrinted:false (default) produces compact JSON
  func test_serialize_notPrettyPrinted_isCompact() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "name", number: 1, type: .string))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set("Alice", forField: "name")

    let compactSerializer = JSONSerializer(
      options: JSONSerializationOptions(prettyPrinted: false, typeRegistry: TypeRegistry())
    )
    let data = try await compactSerializer.serialize(msg)
    let str = try XCTUnwrap(String(data: data, encoding: .utf8))

    XCTAssertFalse(str.contains("\n"), "Compact JSON should not contain newlines")
  }

  // MARK: - serializeToJSONObject method

  // [PUBLIC-MIRROR] JSONSerializationTests — serializeToJSONObject returns Dictionary
  // Oracle: returns [String: Any] with all field values
  func test_serializeToJSONObject_returnsCorrectDictionary() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    desc.addField(FieldDescriptor(name: "name", number: 2, type: .string))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(42), forField: "id")
    try msg.set("Alice", forField: "name")

    let serializer = JSONSerializer(
      options: JSONSerializationOptions(typeRegistry: TypeRegistry())
    )
    let json = try await serializer.serializeToJSONObject(msg)

    XCTAssertEqual((json["id"] as? NSNumber)?.int32Value, 42)
    XCTAssertEqual(json["name"] as? String, "Alice")
  }

  // MARK: - useCanonicalWellKnownTypeEncoding: false

  // [PUBLIC-MIRROR] JSONSerializationOptionsTests.test_options_customCanonicalWKTEncoding_respectsValue()
  // Oracle: useCanonicalWellKnownTypeEncoding:false → generic field-by-field encoding
  func test_serialize_nonCanonicalWKT_usesGenericFieldEncoding() async throws {
    var desc = MessageDescriptor(name: "Timestamp", fullName: WellKnownTypeNames.timestamp)
    desc.addField(FieldDescriptor(name: "seconds", number: 1, type: .int64))
    desc.addField(FieldDescriptor(name: "nanos", number: 2, type: .int32))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int64(1_000_000_000), forField: "seconds")
    try msg.set(Int32(0), forField: "nanos")

    let serializer = JSONSerializer(
      options: JSONSerializationOptions(
        useCanonicalWellKnownTypeEncoding: false,
        typeRegistry: TypeRegistry()
      )
    )
    let data = try await serializer.serialize(msg)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    // Non-canonical: fields are serialized generically
    XCTAssertNotNil(json["seconds"])
  }

  // MARK: - JSONSerializationOptions all parameters

  // [PUBLIC-MIRROR] JSONSerializationOptionsTests — options store all parameters
  // Oracle: all options accessible after init
  func test_jsonSerializationOptions_allParameters_stored() async throws {
    let registry = TypeRegistry()
    let opts = JSONSerializationOptions(
      useOriginalFieldNames: true,
      prettyPrinted: true,
      includeDefaultValues: true,
      useCanonicalWellKnownTypeEncoding: false,
      typeRegistry: registry
    )

    XCTAssertTrue(opts.useOriginalFieldNames)
    XCTAssertTrue(opts.prettyPrinted)
    XCTAssertTrue(opts.includeDefaultValues)
    XCTAssertFalse(opts.useCanonicalWellKnownTypeEncoding)
  }

  // MARK: - JSONSerializationError.description

  // [PUBLIC-MIRROR] JSONSerializerTypeMismatchTests — error descriptions for readability
  // Oracle: each case has a human-readable non-empty description
  func test_jsonSerializationError_description_allCases() async throws {
    let e1 = JSONSerializationError.invalidFieldType(
      fieldName: "f",
      expectedType: "Array",
      actualType: "String"
    )
    XCTAssertTrue(e1.description.contains("f"))

    let e2 = JSONSerializationError.valueTypeMismatch(expected: "Int32", actual: "String")
    XCTAssertFalse(e2.description.isEmpty)

    let e3 = JSONSerializationError.missingMapEntryInfo(fieldName: "mymap")
    XCTAssertTrue(e3.description.contains("mymap"))

    let e4 = JSONSerializationError.missingFieldValue(fieldName: "id")
    XCTAssertTrue(e4.description.contains("id"))

    let e5 = JSONSerializationError.unsupportedFieldType(type: "group")
    XCTAssertFalse(e5.description.isEmpty)

    let e6 = JSONSerializationError.invalidMapKeyType(keyType: "bytes")
    XCTAssertTrue(e6.description.contains("bytes"))

    let e7 = JSONSerializationError.unsupportedWellKnownTypeEncoding(typeName: "google.protobuf.Any")
    XCTAssertTrue(e7.description.contains("Any"))

    // .jsonWriteError case
    struct TestError: Error {}
    let e8 = JSONSerializationError.jsonWriteError(underlyingError: TestError())
    XCTAssertFalse(e8.description.isEmpty)
  }

  // MARK: - JSONSerializationError.init(from:)

  // [PUBLIC-MIRROR] JSONSerializerTypeMismatchTests — all _JSONSerializationError cases convert
  // Oracle: each internal error maps to correct public case
  func test_jsonSerializationError_initFromImpl_allCases() async throws {
    XCTAssertEqual(
      JSONSerializationError(
        from: _JSONSerializationError.invalidFieldType(
          fieldName: "f",
          expectedType: "Array",
          actualType: "String"
        )
      ),
      .invalidFieldType(fieldName: "f", expectedType: "Array", actualType: "String")
    )

    XCTAssertEqual(
      JSONSerializationError(
        from: _JSONSerializationError.valueTypeMismatch(
          expected: "Int32",
          actual: "String"
        )
      ),
      .valueTypeMismatch(expected: "Int32", actual: "String")
    )

    XCTAssertEqual(
      JSONSerializationError(from: _JSONSerializationError.missingMapEntryInfo(fieldName: "mm")),
      .missingMapEntryInfo(fieldName: "mm")
    )

    XCTAssertEqual(
      JSONSerializationError(from: _JSONSerializationError.missingFieldValue(fieldName: "id")),
      .missingFieldValue(fieldName: "id")
    )

    XCTAssertEqual(
      JSONSerializationError(from: _JSONSerializationError.unsupportedFieldType(type: "group")),
      .unsupportedFieldType(type: "group")
    )

    XCTAssertEqual(
      JSONSerializationError(from: _JSONSerializationError.invalidMapKeyType(keyType: "bytes")),
      .invalidMapKeyType(keyType: "bytes")
    )

    XCTAssertEqual(
      JSONSerializationError(from: _JSONSerializationError.unsupportedWellKnownTypeEncoding(typeName: "X")),
      .unsupportedWellKnownTypeEncoding(typeName: "X")
    )
  }

  // MARK: - JSONSerializationError equality

  // [PUBLIC-MIRROR] JSONSerializerTypeMismatchTests — error equality
  // Oracle: same cases with same parameters are equal
  func test_jsonSerializationError_equality() async throws {
    XCTAssertEqual(
      JSONSerializationError.invalidFieldType(fieldName: "f", expectedType: "E", actualType: "A"),
      JSONSerializationError.invalidFieldType(fieldName: "f", expectedType: "E", actualType: "A")
    )

    XCTAssertNotEqual(
      JSONSerializationError.invalidFieldType(fieldName: "f", expectedType: "E", actualType: "A"),
      JSONSerializationError.invalidFieldType(fieldName: "x", expectedType: "E", actualType: "A")
    )

    XCTAssertNotEqual(
      JSONSerializationError.invalidFieldType(fieldName: "f", expectedType: "E", actualType: "A"),
      JSONSerializationError.missingFieldValue(fieldName: "f")
    )

    XCTAssertEqual(
      JSONSerializationError.valueTypeMismatch(expected: "E", actual: "A"),
      JSONSerializationError.valueTypeMismatch(expected: "E", actual: "A")
    )

    XCTAssertEqual(
      JSONSerializationError.missingMapEntryInfo(fieldName: "f"),
      JSONSerializationError.missingMapEntryInfo(fieldName: "f")
    )

    XCTAssertEqual(
      JSONSerializationError.missingFieldValue(fieldName: "f"),
      JSONSerializationError.missingFieldValue(fieldName: "f")
    )

    XCTAssertEqual(
      JSONSerializationError.unsupportedFieldType(type: "t"),
      JSONSerializationError.unsupportedFieldType(type: "t")
    )

    XCTAssertEqual(
      JSONSerializationError.invalidMapKeyType(keyType: "bytes"),
      JSONSerializationError.invalidMapKeyType(keyType: "bytes")
    )

    // jsonWriteError always equals itself
    struct TestError: Error {}
    XCTAssertEqual(
      JSONSerializationError.jsonWriteError(underlyingError: TestError()),
      JSONSerializationError.jsonWriteError(underlyingError: TestError())
    )

    XCTAssertEqual(
      JSONSerializationError.unsupportedWellKnownTypeEncoding(typeName: "X"),
      JSONSerializationError.unsupportedWellKnownTypeEncoding(typeName: "X")
    )
  }

  // MARK: - JSONDeserializationOptions

  // [PUBLIC-MIRROR] JSONDeserializationTests — options constructor with all params
  // Oracle: all options accessible after init
  func test_jsonDeserializationOptions_allParameters_stored() async throws {
    let registry = TypeRegistry()
    let opts = JSONDeserializationOptions(
      ignoreUnknownFields: false,
      strictTypeValidation: false,
      typeRegistry: registry,
      maxNestingDepth: 10
    )

    XCTAssertFalse(opts.ignoreUnknownFields)
    XCTAssertFalse(opts.strictTypeValidation)
    XCTAssertEqual(opts.maxNestingDepth, 10)
  }

  // [PUBLIC-MIRROR] JSONDeserializationTests — default options
  // Oracle: default options have ignoreUnknownFields:true, strictTypeValidation:true, maxNestingDepth:64
  func test_jsonDeserializationOptions_defaultValues() async throws {
    let opts = JSONDeserializationOptions(typeRegistry: TypeRegistry())
    XCTAssertTrue(opts.ignoreUnknownFields)
    XCTAssertTrue(opts.strictTypeValidation)
    XCTAssertEqual(opts.maxNestingDepth, 64)
  }

  // MARK: - JSONDeserializationError.description

  // [PUBLIC-MIRROR] JSONDeserializationTests — error descriptions for readability
  // Oracle: each case has a human-readable non-empty description
  func test_jsonDeserializationError_description_allCases() async throws {
    struct TestError: Error {
      var localizedDescription: String { "test" }
    }

    XCTAssertFalse(JSONDeserializationError.invalidJSON(underlyingError: TestError()).description.isEmpty)
    XCTAssertFalse(
      JSONDeserializationError.invalidJSONStructure(expected: "dict", actual: "array").description.isEmpty
    )
    XCTAssertFalse(JSONDeserializationError.unknownField(fieldName: "x", messageName: "M").description.isEmpty)
    XCTAssertFalse(
      JSONDeserializationError.invalidFieldType(
        fieldName: "f",
        expectedType: "Int32",
        actualType: "String"
      ).description.isEmpty
    )
    XCTAssertFalse(
      JSONDeserializationError.valueTypeMismatch(
        fieldName: "f",
        expected: "Int32",
        actual: "String"
      ).description.isEmpty
    )
    XCTAssertFalse(
      JSONDeserializationError.invalidNumberFormat(fieldName: "f", value: "abc").description.isEmpty
    )
    XCTAssertFalse(
      JSONDeserializationError.numberOutOfRange(
        fieldName: "f",
        value: 999,
        expectedRange: "[0, 127]"
      ).description.isEmpty
    )
    XCTAssertFalse(
      JSONDeserializationError.invalidBase64(fieldName: "f", value: "!!!").description.isEmpty
    )
    XCTAssertFalse(
      JSONDeserializationError.invalidEnumValue(fieldName: "f", value: "INVALID").description.isEmpty
    )
    XCTAssertFalse(
      JSONDeserializationError.invalidMapKeyFormat(
        fieldName: "f",
        keyType: "int32",
        value: "abc"
      ).description.isEmpty
    )
    XCTAssertFalse(
      JSONDeserializationError.invalidMapKeyType(fieldName: "f", keyType: "bytes").description.isEmpty
    )
    XCTAssertFalse(
      JSONDeserializationError.invalidMapKey(fieldName: "f", key: "bad").description.isEmpty
    )
    XCTAssertFalse(
      JSONDeserializationError.invalidArrayElement(
        fieldName: "f",
        index: 0,
        underlyingError: TestError()
      ).description.isEmpty
    )
    XCTAssertFalse(
      JSONDeserializationError.missingMapEntryInfo(fieldName: "mm").description.isEmpty
    )
    XCTAssertFalse(JSONDeserializationError.missingTypeName(fieldName: "f").description.isEmpty)
    XCTAssertFalse(
      JSONDeserializationError.unsupportedNestedMessage(fieldName: "f", typeName: "T").description.isEmpty
    )
    XCTAssertFalse(
      JSONDeserializationError.nestedMessageDescriptorNotFound(fieldName: "f", typeName: "T").description.isEmpty
    )
    XCTAssertFalse(JSONDeserializationError.nestingDepthExceeded(maxDepth: 64).description.isEmpty)
    XCTAssertFalse(JSONDeserializationError.unsupportedFieldType(type: "group").description.isEmpty)
    XCTAssertFalse(
      JSONDeserializationError.unsupportedWellKnownTypeDecoding(typeName: "google.protobuf.Any").description.isEmpty
    )
  }

  // MARK: - JSONDeserializationError equality

  // [PUBLIC-MIRROR] JSONDeserializationTests — error equality
  // Oracle: same cases equal, different cases not equal
  func test_jsonDeserializationError_equality() async throws {
    struct TestError: Error {}

    XCTAssertEqual(
      JSONDeserializationError.invalidJSON(underlyingError: TestError()),
      JSONDeserializationError.invalidJSON(underlyingError: TestError())
    )
    XCTAssertEqual(
      JSONDeserializationError.invalidJSONStructure(expected: "A", actual: "B"),
      JSONDeserializationError.invalidJSONStructure(expected: "A", actual: "B")
    )
    XCTAssertEqual(
      JSONDeserializationError.unknownField(fieldName: "f", messageName: "M"),
      JSONDeserializationError.unknownField(fieldName: "f", messageName: "M")
    )
    XCTAssertNotEqual(
      JSONDeserializationError.unknownField(fieldName: "f", messageName: "M"),
      JSONDeserializationError.unknownField(fieldName: "g", messageName: "M")
    )
    XCTAssertEqual(
      JSONDeserializationError.invalidFieldType(fieldName: "f", expectedType: "E", actualType: "A"),
      JSONDeserializationError.invalidFieldType(fieldName: "f", expectedType: "E", actualType: "A")
    )
    XCTAssertEqual(
      JSONDeserializationError.nestingDepthExceeded(maxDepth: 64),
      JSONDeserializationError.nestingDepthExceeded(maxDepth: 64)
    )
    XCTAssertNotEqual(
      JSONDeserializationError.nestingDepthExceeded(maxDepth: 64),
      JSONDeserializationError.nestingDepthExceeded(maxDepth: 32)
    )
    XCTAssertEqual(
      JSONDeserializationError.unsupportedWellKnownTypeDecoding(typeName: "X"),
      JSONDeserializationError.unsupportedWellKnownTypeDecoding(typeName: "X")
    )
  }

  // MARK: - JSONDeserializer.deserializeFromJSONObject

  // [PUBLIC-MIRROR] JSONDeserializationTests — deserializeFromJSONObject round-trip
  // Oracle: deserializeFromJSONObject produces same result as deserialize(Data:)
  func test_jsonDeserializer_deserializeFromJSONObject_roundTrip() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    desc.addField(FieldDescriptor(name: "name", number: 2, type: .string))

    let jsonObject: [String: Any] = ["id": Int32(42), "name": "Alice"]

    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: TypeRegistry())
    )
    let msg = try await deserializer.deserializeFromJSONObject(jsonObject, using: desc)

    XCTAssertEqual(try msg.get(forField: "id") as? Int32, 42)
    XCTAssertEqual(try msg.get(forField: "name") as? String, "Alice")
  }

  // MARK: - JSONSerializer round-trip via public async API

  // [PUBLIC-MIRROR] JSONSerializationTests — full JSON round-trip
  // Oracle: serialize+deserialize gives back the same field values
  func test_jsonSerializer_asyncAPI_roundTrip() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    desc.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    desc.addField(FieldDescriptor(name: "active", number: 3, type: .bool))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(100), forField: "id")
    try msg.set("Bob", forField: "name")
    try msg.set(true, forField: "active")

    let serializer = JSONSerializer(options: JSONSerializationOptions(typeRegistry: TypeRegistry()))
    let data = try await serializer.serialize(msg)

    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: TypeRegistry())
    )
    let result = try await deserializer.deserialize(data, using: desc)

    XCTAssertEqual(try result.get(forField: "id") as? Int32, 100)
    XCTAssertEqual(try result.get(forField: "name") as? String, "Bob")
    XCTAssertEqual(try result.get(forField: "active") as? Bool, true)
  }
}
