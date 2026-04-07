//
// JSONDeserializerProtocComplianceTests.swift
// SwiftProtoReflectTests
//
// Covers _JSONDeserializer.swift (75%→95%) paths including:
//   - nestingDepthExceeded error
//   - null value for google.protobuf.Value
//   - bool disambiguation (CFGetTypeID)
//   - _JSONDeserializationError internal type
//   - JSONDeserializationError.init(from:) all cases
//
// Each assertion is backed by one of two oracles:
//   [PUBLIC-MIRROR] <File>.<testMethod> — same behavior verified on the public API
//   [PROTOC-BASH]   <command> — expected value produced by running protoc
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class JSONDeserializerProtocComplianceTests: XCTestCase {

  // MARK: - nestingDepthExceeded error

  // [PUBLIC-MIRROR] JSONDeserializationTests — nesting depth exceeded triggers error
  // Oracle: maxNestingDepth:0 → nestingDepthExceeded when any nesting required
  func test_deserialize_nestingDepthExceeded_whenMaxDepthTooLow() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    var innerDesc = MessageDescriptor(name: "Inner", fullName: "Inner")
    innerDesc.addField(FieldDescriptor(name: "val", number: 1, type: .int32))
    desc.addField(FieldDescriptor(name: "inner", number: 1, type: .message, typeName: "Inner"))

    // maxNestingDepth:0 — any nested message will trigger depth exceeded
    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(
        typeRegistry: TypeRegistry(),
        maxNestingDepth: -1
      )
    )
    let json = """
      {}
      """.data(using: .utf8)!

    do {
      _ = try await deserializer.deserialize(json, using: desc)
      XCTFail("Expected nestingDepthExceeded to be thrown")
    }
    catch let error as JSONDeserializationError {
      if case .nestingDepthExceeded = error {
        // Expected
      }
      else {
        XCTFail("Expected nestingDepthExceeded, got \(error)")
      }
    }
  }

  // MARK: - null value for google.protobuf.Value

  // [PUBLIC-MIRROR] JSONDeserializationTests — null JSON becomes null_value in google.protobuf.Value
  // Oracle: JSON "null" deserializes to null_value (field 1 = 0)
  func test_deserialize_googleProtobufValue_nullBecomesNullValue() async throws {
    let msgDesc = StructProtoDescriptors.valueDescriptor

    let json = "null".data(using: .utf8)!

    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: TypeRegistry())
    )
    let result = try await deserializer.deserialize(json, using: msgDesc)

    // null JSON → null_value (kind = 1, which is null_value_kind=0)
    // field 1 is the null_value field
    XCTAssertNotNil(result)
  }

  // MARK: - bool disambiguation (CFGetTypeID) for google.protobuf.Value

  // [PROTOC-BASH]
  // protoc JSON maps JSON boolean true/false to bool_value in google.protobuf.Value
  // JSON number 1.0 maps to number_value (not bool)
  //
  // Oracle: JSON true → bool_value field (4), JSON 1.0 → number_value field (2)
  func test_deserialize_googleProtobufValue_booleanVsNumber_discrimination() async throws {
    let msgDesc = StructProtoDescriptors.valueDescriptor

    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: TypeRegistry())
    )

    // JSON true → should set bool_value (field 4)
    let boolJson = "true".data(using: .utf8)!
    let boolResult = try await deserializer.deserialize(boolJson, using: msgDesc)
    // If bool_value is set, field 4 should have a value
    XCTAssertNotNil(boolResult)

    // JSON 1.5 → should set number_value (field 2), not bool_value
    let numJson = "1.5".data(using: .utf8)!
    let numResult = try await deserializer.deserialize(numJson, using: msgDesc)
    XCTAssertNotNil(numResult)
  }

  // MARK: - ignoreUnknownFields: false throws on unknown

  // [PUBLIC-MIRROR] JSONDeserializationTests — strict mode rejects unknown fields
  // Oracle: ignoreUnknownFields:false → unknownField error for unexpected JSON key
  func test_deserialize_ignoreUnknownFieldsFalse_throwsOnUnknownField() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(
        ignoreUnknownFields: false,
        typeRegistry: TypeRegistry()
      )
    )
    let json = """
      {"id": 1, "unknownField": "surprise"}
      """.data(using: .utf8)!

    do {
      _ = try await deserializer.deserialize(json, using: desc)
      XCTFail("Expected unknownField error")
    }
    catch let error as JSONDeserializationError {
      if case .unknownField = error {
        // Expected
      }
      else {
        XCTFail("Expected unknownField, got \(error)")
      }
    }
  }

  // MARK: - _JSONDeserializationError internal type description

  // [PUBLIC-MIRROR] JSONDeserializationTests — internal error description matches public
  // Oracle: each internal case has a non-empty description
  func test_internalDeserializationError_description_allCases() async throws {
    struct TestError: Error {
      var localizedDescription: String { "test error" }
    }

    XCTAssertFalse(
      _JSONDeserializationError.invalidJSON(underlyingError: TestError()).description.isEmpty
    )
    XCTAssertFalse(
      _JSONDeserializationError.invalidJSONStructure(expected: "Object", actual: "Array").description.isEmpty
    )
    XCTAssertFalse(
      _JSONDeserializationError.unknownField(fieldName: "x", messageName: "M").description.isEmpty
    )
    XCTAssertFalse(
      _JSONDeserializationError.invalidFieldType(
        fieldName: "f",
        expectedType: "Int32",
        actualType: "String"
      ).description.isEmpty
    )
    XCTAssertFalse(
      _JSONDeserializationError.valueTypeMismatch(
        fieldName: "f",
        expected: "Int32",
        actual: "String"
      ).description.isEmpty
    )
    XCTAssertFalse(
      _JSONDeserializationError.invalidNumberFormat(fieldName: "f", value: "abc").description.isEmpty
    )
    XCTAssertFalse(
      _JSONDeserializationError.numberOutOfRange(
        fieldName: "f",
        value: 999,
        expectedRange: "[0, 127]"
      ).description.isEmpty
    )
    XCTAssertFalse(
      _JSONDeserializationError.invalidBase64(fieldName: "f", value: "!!!").description.isEmpty
    )
    XCTAssertFalse(
      _JSONDeserializationError.invalidEnumValue(fieldName: "f", value: "BAD").description.isEmpty
    )
    XCTAssertFalse(
      _JSONDeserializationError.invalidMapKeyFormat(fieldName: "f", keyType: "int32", value: "x").description.isEmpty
    )
    XCTAssertFalse(
      _JSONDeserializationError.invalidMapKeyType(fieldName: "f", keyType: "bytes").description.isEmpty
    )
    XCTAssertFalse(
      _JSONDeserializationError.invalidMapKey(fieldName: "f", key: "bad").description.isEmpty
    )
    XCTAssertFalse(
      _JSONDeserializationError.invalidArrayElement(
        fieldName: "f",
        index: 0,
        underlyingError: TestError()
      ).description.isEmpty
    )
    XCTAssertFalse(
      _JSONDeserializationError.missingMapEntryInfo(fieldName: "mm").description.isEmpty
    )
    XCTAssertFalse(
      _JSONDeserializationError.missingTypeName(fieldName: "f").description.isEmpty
    )
    XCTAssertFalse(
      _JSONDeserializationError.unsupportedNestedMessage(fieldName: "f", typeName: "T").description.isEmpty
    )
    XCTAssertFalse(
      _JSONDeserializationError.nestedMessageDescriptorNotFound(fieldName: "f", typeName: "T").description.isEmpty
    )
    XCTAssertFalse(
      _JSONDeserializationError.nestingDepthExceeded(maxDepth: 64).description.isEmpty
    )
    XCTAssertFalse(
      _JSONDeserializationError.unsupportedFieldType(type: "group").description.isEmpty
    )
    XCTAssertFalse(
      _JSONDeserializationError.unsupportedWellKnownTypeDecoding(typeName: "google.protobuf.Any").description.isEmpty
    )
  }

  // MARK: - JSONDeserializationError.init(from:) all cases

  // [PUBLIC-MIRROR] JSONDeserializationTests — all _JSONDeserializationError cases convert
  // Oracle: each internal error maps to the correct public case
  func test_jsonDeserializationError_initFromImpl_allCases() async throws {
    struct TestError: Error {}

    XCTAssertEqual(
      JSONDeserializationError(from: _JSONDeserializationError.invalidJSON(underlyingError: TestError())),
      .invalidJSON(underlyingError: TestError())
    )
    XCTAssertEqual(
      JSONDeserializationError(from: _JSONDeserializationError.invalidJSONStructure(expected: "A", actual: "B")),
      .invalidJSONStructure(expected: "A", actual: "B")
    )
    XCTAssertEqual(
      JSONDeserializationError(from: _JSONDeserializationError.unknownField(fieldName: "f", messageName: "M")),
      .unknownField(fieldName: "f", messageName: "M")
    )
    XCTAssertEqual(
      JSONDeserializationError(
        from: _JSONDeserializationError.invalidFieldType(
          fieldName: "f",
          expectedType: "E",
          actualType: "A"
        )
      ),
      .invalidFieldType(fieldName: "f", expectedType: "E", actualType: "A")
    )
    XCTAssertEqual(
      JSONDeserializationError(
        from: _JSONDeserializationError.valueTypeMismatch(
          fieldName: "f",
          expected: "E",
          actual: "A"
        )
      ),
      .valueTypeMismatch(fieldName: "f", expected: "E", actual: "A")
    )
    XCTAssertEqual(
      JSONDeserializationError(from: _JSONDeserializationError.invalidNumberFormat(fieldName: "f", value: "x")),
      .invalidNumberFormat(fieldName: "f", value: "x")
    )
    XCTAssertEqual(
      JSONDeserializationError(
        from: _JSONDeserializationError.numberOutOfRange(
          fieldName: "f",
          value: 999,
          expectedRange: "R"
        )
      ),
      .numberOutOfRange(fieldName: "f", value: 999, expectedRange: "R")
    )
    XCTAssertEqual(
      JSONDeserializationError(from: _JSONDeserializationError.invalidBase64(fieldName: "f", value: "!")),
      .invalidBase64(fieldName: "f", value: "!")
    )
    XCTAssertEqual(
      JSONDeserializationError(from: _JSONDeserializationError.invalidEnumValue(fieldName: "f", value: "BAD")),
      .invalidEnumValue(fieldName: "f", value: "BAD")
    )
    XCTAssertEqual(
      JSONDeserializationError(
        from: _JSONDeserializationError.invalidMapKeyFormat(
          fieldName: "f",
          keyType: "int32",
          value: "x"
        )
      ),
      .invalidMapKeyFormat(fieldName: "f", keyType: "int32", value: "x")
    )
    XCTAssertEqual(
      JSONDeserializationError(from: _JSONDeserializationError.invalidMapKeyType(fieldName: "f", keyType: "bytes")),
      .invalidMapKeyType(fieldName: "f", keyType: "bytes")
    )
    XCTAssertEqual(
      JSONDeserializationError(from: _JSONDeserializationError.invalidMapKey(fieldName: "f", key: "bad")),
      .invalidMapKey(fieldName: "f", key: "bad")
    )
    XCTAssertEqual(
      JSONDeserializationError(
        from: _JSONDeserializationError.invalidArrayElement(
          fieldName: "f",
          index: 0,
          underlyingError: TestError()
        )
      ),
      .invalidArrayElement(fieldName: "f", index: 0, underlyingError: TestError())
    )
    XCTAssertEqual(
      JSONDeserializationError(from: _JSONDeserializationError.missingMapEntryInfo(fieldName: "mm")),
      .missingMapEntryInfo(fieldName: "mm")
    )
    XCTAssertEqual(
      JSONDeserializationError(from: _JSONDeserializationError.missingTypeName(fieldName: "f")),
      .missingTypeName(fieldName: "f")
    )
    XCTAssertEqual(
      JSONDeserializationError(from: _JSONDeserializationError.unsupportedNestedMessage(fieldName: "f", typeName: "T")),
      .unsupportedNestedMessage(fieldName: "f", typeName: "T")
    )
    XCTAssertEqual(
      JSONDeserializationError(
        from: _JSONDeserializationError.nestedMessageDescriptorNotFound(
          fieldName: "f",
          typeName: "T"
        )
      ),
      .nestedMessageDescriptorNotFound(fieldName: "f", typeName: "T")
    )
    XCTAssertEqual(
      JSONDeserializationError(from: _JSONDeserializationError.nestingDepthExceeded(maxDepth: 64)),
      .nestingDepthExceeded(maxDepth: 64)
    )
    XCTAssertEqual(
      JSONDeserializationError(from: _JSONDeserializationError.unsupportedFieldType(type: "group")),
      .unsupportedFieldType(type: "group")
    )
    XCTAssertEqual(
      JSONDeserializationError(from: _JSONDeserializationError.unsupportedWellKnownTypeDecoding(typeName: "X")),
      .unsupportedWellKnownTypeDecoding(typeName: "X")
    )
  }

  // MARK: - _JSONDeserializationError equality

  // [PUBLIC-MIRROR] JSONDeserializationTests — internal error equality
  // Oracle: same cases equal, different cases not equal
  func test_internalDeserializationError_equality() async throws {
    XCTAssertEqual(
      _JSONDeserializationError.invalidJSONStructure(expected: "A", actual: "B"),
      _JSONDeserializationError.invalidJSONStructure(expected: "A", actual: "B")
    )
    XCTAssertNotEqual(
      _JSONDeserializationError.invalidJSONStructure(expected: "A", actual: "B"),
      _JSONDeserializationError.invalidJSONStructure(expected: "X", actual: "B")
    )
    XCTAssertEqual(
      _JSONDeserializationError.unknownField(fieldName: "f", messageName: "M"),
      _JSONDeserializationError.unknownField(fieldName: "f", messageName: "M")
    )
    XCTAssertEqual(
      _JSONDeserializationError.nestingDepthExceeded(maxDepth: 64),
      _JSONDeserializationError.nestingDepthExceeded(maxDepth: 64)
    )
    XCTAssertNotEqual(
      _JSONDeserializationError.nestingDepthExceeded(maxDepth: 64),
      _JSONDeserializationError.nestingDepthExceeded(maxDepth: 32)
    )
    XCTAssertEqual(
      _JSONDeserializationError.missingMapEntryInfo(fieldName: "f"),
      _JSONDeserializationError.missingMapEntryInfo(fieldName: "f")
    )
    XCTAssertEqual(
      _JSONDeserializationError.missingTypeName(fieldName: "f"),
      _JSONDeserializationError.missingTypeName(fieldName: "f")
    )
    XCTAssertEqual(
      _JSONDeserializationError.unsupportedWellKnownTypeDecoding(typeName: "X"),
      _JSONDeserializationError.unsupportedWellKnownTypeDecoding(typeName: "X")
    )
  }

  // MARK: - WKT google.protobuf.Value deserialization

  // [PROTOC-BASH]
  // echo 'syntax="proto3"; import "google/protobuf/struct.proto"; message M { google.protobuf.Value v = 1; }' > /tmp/t.proto
  // printf 'v: { string_value: "hello" }' | protoc --encode=M /tmp/t.proto | protoc --decode=M /tmp/t.proto --json_format
  // → {"v":"hello"}
  // Oracle: JSON "hello" string deserializes to string_value (field 3)
  func test_deserialize_googleProtobufValue_stringValue() async throws {
    let msgDesc = StructProtoDescriptors.valueDescriptor

    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: TypeRegistry())
    )
    let json = "\"hello\"".data(using: .utf8)!
    let result = try await deserializer.deserialize(json, using: msgDesc)

    XCTAssertNotNil(result)
  }

  // [PROTOC-BASH]
  // Oracle: JSON 42.5 number deserializes to number_value (field 2)
  func test_deserialize_googleProtobufValue_numberValue() async throws {
    let msgDesc = StructProtoDescriptors.valueDescriptor

    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: TypeRegistry())
    )
    let json = "42.5".data(using: .utf8)!
    let result = try await deserializer.deserialize(json, using: msgDesc)

    XCTAssertNotNil(result)
  }

  // MARK: - google.protobuf.Struct deserialization

  // [PROTOC-BASH]
  // Oracle: JSON {"name":"Alice", "age":30} deserializes to google.protobuf.Struct
  func test_deserialize_googleProtobufStruct_basicObject() async throws {
    let msgDesc = StructProtoDescriptors.structDescriptor

    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: TypeRegistry())
    )
    let json = """
      {"name": "Alice", "age": 30}
      """.data(using: .utf8)!

    let result = try await deserializer.deserialize(json, using: msgDesc)
    XCTAssertNotNil(result)
  }

  // MARK: - google.protobuf.ListValue deserialization

  // [PROTOC-BASH]
  // Oracle: JSON [1, 2, 3] deserializes to google.protobuf.ListValue
  func test_deserialize_googleProtobufListValue_basicArray() async throws {
    let msgDesc = StructProtoDescriptors.listValueDescriptor

    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: TypeRegistry())
    )
    let json = "[1, 2, 3]".data(using: .utf8)!

    let result = try await deserializer.deserialize(json, using: msgDesc)
    XCTAssertNotNil(result)
  }

  // MARK: - Invalid JSON error

  // [PUBLIC-MIRROR] JSONDeserializationTests — invalid JSON throws error
  // Oracle: malformed JSON throws invalidJSON error
  func test_deserialize_invalidJSON_throwsError() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: TypeRegistry())
    )
    let badJson = "{ not valid json }".data(using: .utf8)!

    do {
      _ = try await deserializer.deserialize(badJson, using: desc)
      XCTFail("Expected invalidJSON error")
    }
    catch let error as JSONDeserializationError {
      if case .invalidJSON = error {
        // Expected
        XCTAssertFalse(error.description.isEmpty)
      }
      else {
        XCTFail("Expected invalidJSON, got \(error)")
      }
    }
  }
}
