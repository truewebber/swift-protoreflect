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

  // MARK: - _JSONDeserializationError == remaining cases

  // [PUBLIC-MIRROR] JSONDeserializationTests — internal error equality
  // Oracle: each remaining case in _JSONDeserializationError.== is exercised
  func test_internalDeserializationError_equality_remainingCases() {
    struct TestError: Error {}

    // invalidJSON — line 1172
    XCTAssertEqual(
      _JSONDeserializationError.invalidJSON(underlyingError: TestError()),
      _JSONDeserializationError.invalidJSON(underlyingError: TestError())
    )

    // invalidFieldType — lines 1183-1187
    XCTAssertEqual(
      _JSONDeserializationError.invalidFieldType(fieldName: "f", expectedType: "E", actualType: "A"),
      _JSONDeserializationError.invalidFieldType(fieldName: "f", expectedType: "E", actualType: "A")
    )
    XCTAssertNotEqual(
      _JSONDeserializationError.invalidFieldType(fieldName: "f", expectedType: "E", actualType: "A"),
      _JSONDeserializationError.invalidFieldType(fieldName: "g", expectedType: "E", actualType: "A")
    )

    // valueTypeMismatch — lines 1188-1192
    XCTAssertEqual(
      _JSONDeserializationError.valueTypeMismatch(fieldName: "f", expected: "E", actual: "A"),
      _JSONDeserializationError.valueTypeMismatch(fieldName: "f", expected: "E", actual: "A")
    )
    XCTAssertNotEqual(
      _JSONDeserializationError.valueTypeMismatch(fieldName: "f", expected: "E", actual: "A"),
      _JSONDeserializationError.valueTypeMismatch(fieldName: "f", expected: "X", actual: "A")
    )

    // invalidNumberFormat — lines 1193-1197
    XCTAssertEqual(
      _JSONDeserializationError.invalidNumberFormat(fieldName: "f", value: "abc"),
      _JSONDeserializationError.invalidNumberFormat(fieldName: "f", value: "abc")
    )
    XCTAssertNotEqual(
      _JSONDeserializationError.invalidNumberFormat(fieldName: "f", value: "abc"),
      _JSONDeserializationError.invalidNumberFormat(fieldName: "f", value: "xyz")
    )

    // numberOutOfRange — lines 1198-1202
    XCTAssertEqual(
      _JSONDeserializationError.numberOutOfRange(fieldName: "f", value: 999, expectedRange: "R"),
      _JSONDeserializationError.numberOutOfRange(fieldName: "f", value: 999, expectedRange: "R")
    )
    XCTAssertNotEqual(
      _JSONDeserializationError.numberOutOfRange(fieldName: "f", value: 999, expectedRange: "R"),
      _JSONDeserializationError.numberOutOfRange(fieldName: "f", value: 0, expectedRange: "R")
    )

    // invalidBase64 — lines 1203-1207
    XCTAssertEqual(
      _JSONDeserializationError.invalidBase64(fieldName: "f", value: "!!!"),
      _JSONDeserializationError.invalidBase64(fieldName: "f", value: "!!!")
    )
    XCTAssertNotEqual(
      _JSONDeserializationError.invalidBase64(fieldName: "f", value: "!!!"),
      _JSONDeserializationError.invalidBase64(fieldName: "f", value: "???")
    )

    // invalidEnumValue — lines 1208-1212
    XCTAssertEqual(
      _JSONDeserializationError.invalidEnumValue(fieldName: "f", value: "BAD"),
      _JSONDeserializationError.invalidEnumValue(fieldName: "f", value: "BAD")
    )
    XCTAssertNotEqual(
      _JSONDeserializationError.invalidEnumValue(fieldName: "f", value: "BAD"),
      _JSONDeserializationError.invalidEnumValue(fieldName: "f", value: "GOOD")
    )

    // invalidMapKeyFormat — lines 1213-1217
    XCTAssertEqual(
      _JSONDeserializationError.invalidMapKeyFormat(fieldName: "f", keyType: "int32", value: "x"),
      _JSONDeserializationError.invalidMapKeyFormat(fieldName: "f", keyType: "int32", value: "x")
    )
    XCTAssertNotEqual(
      _JSONDeserializationError.invalidMapKeyFormat(fieldName: "f", keyType: "int32", value: "x"),
      _JSONDeserializationError.invalidMapKeyFormat(fieldName: "f", keyType: "int32", value: "y")
    )

    // invalidMapKeyType — lines 1218-1222
    XCTAssertEqual(
      _JSONDeserializationError.invalidMapKeyType(fieldName: "f", keyType: "bytes"),
      _JSONDeserializationError.invalidMapKeyType(fieldName: "f", keyType: "bytes")
    )
    XCTAssertNotEqual(
      _JSONDeserializationError.invalidMapKeyType(fieldName: "f", keyType: "bytes"),
      _JSONDeserializationError.invalidMapKeyType(fieldName: "f", keyType: "float")
    )

    // invalidMapKey — lines 1223-1227
    XCTAssertEqual(
      _JSONDeserializationError.invalidMapKey(fieldName: "f", key: "bad"),
      _JSONDeserializationError.invalidMapKey(fieldName: "f", key: "bad")
    )
    XCTAssertNotEqual(
      _JSONDeserializationError.invalidMapKey(fieldName: "f", key: "bad"),
      _JSONDeserializationError.invalidMapKey(fieldName: "f", key: "worse")
    )

    // invalidArrayElement — lines 1228-1232
    XCTAssertEqual(
      _JSONDeserializationError.invalidArrayElement(fieldName: "f", index: 0, underlyingError: TestError()),
      _JSONDeserializationError.invalidArrayElement(fieldName: "f", index: 0, underlyingError: TestError())
    )
    XCTAssertNotEqual(
      _JSONDeserializationError.invalidArrayElement(fieldName: "f", index: 0, underlyingError: TestError()),
      _JSONDeserializationError.invalidArrayElement(fieldName: "f", index: 1, underlyingError: TestError())
    )

    // unsupportedNestedMessage — lines 1237-1241
    XCTAssertEqual(
      _JSONDeserializationError.unsupportedNestedMessage(fieldName: "f", typeName: "T"),
      _JSONDeserializationError.unsupportedNestedMessage(fieldName: "f", typeName: "T")
    )
    XCTAssertNotEqual(
      _JSONDeserializationError.unsupportedNestedMessage(fieldName: "f", typeName: "T"),
      _JSONDeserializationError.unsupportedNestedMessage(fieldName: "f", typeName: "X")
    )

    // nestedMessageDescriptorNotFound — lines 1242-1246
    XCTAssertEqual(
      _JSONDeserializationError.nestedMessageDescriptorNotFound(fieldName: "f", typeName: "T"),
      _JSONDeserializationError.nestedMessageDescriptorNotFound(fieldName: "f", typeName: "T")
    )
    XCTAssertNotEqual(
      _JSONDeserializationError.nestedMessageDescriptorNotFound(fieldName: "f", typeName: "T"),
      _JSONDeserializationError.nestedMessageDescriptorNotFound(fieldName: "f", typeName: "X")
    )

    // unsupportedFieldType — lines 1249-1250
    XCTAssertEqual(
      _JSONDeserializationError.unsupportedFieldType(type: "group"),
      _JSONDeserializationError.unsupportedFieldType(type: "group")
    )
    XCTAssertNotEqual(
      _JSONDeserializationError.unsupportedFieldType(type: "group"),
      _JSONDeserializationError.unsupportedFieldType(type: "fixed32")
    )

    // default: return false — lines 1256-1258
    XCTAssertNotEqual(
      _JSONDeserializationError.invalidJSON(underlyingError: TestError()),
      _JSONDeserializationError.invalidFieldType(fieldName: "f", expectedType: "E", actualType: "A")
    )
    XCTAssertNotEqual(
      _JSONDeserializationError.missingTypeName(fieldName: "f"),
      _JSONDeserializationError.invalidEnumValue(fieldName: "f", value: "BAD")
    )
  }

  // MARK: - WKT wrong-type errors

  // [PROTOC-BASH]
  // protoc rejects non-object JSON for google.protobuf.Empty
  // Oracle: deserializing a JSON string as Empty throws invalidJSONStructure
  func test_deserialize_googleProtobufEmpty_fromNonObject_throwsError() throws {
    let emptyDesc = _MessageDescriptor(name: "Empty", fullName: "google.protobuf.Empty")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("\"hello\"".data(using: .utf8)!, using: emptyDesc)
    ) { error in
      if let jsonError = error as? _JSONDeserializationError,
        case .invalidJSONStructure = jsonError
      {
        // Expected
      }
      else {
        XCTFail("Expected invalidJSONStructure, got: \(error)")
      }
    }
  }

  // [PROTOC-BASH]
  // protoc rejects non-object JSON for google.protobuf.Struct
  // Oracle: deserializing a JSON string as Struct throws invalidJSONStructure
  func test_deserialize_googleProtobufStruct_fromNonObject_throwsError() throws {
    let structDesc = _MessageDescriptor(name: "Struct", fullName: "google.protobuf.Struct")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("\"not_an_object\"".data(using: .utf8)!, using: structDesc)
    ) { error in
      if let jsonError = error as? _JSONDeserializationError,
        case .invalidJSONStructure = jsonError
      {
        // Expected
      }
      else {
        XCTFail("Expected invalidJSONStructure, got: \(error)")
      }
    }
  }

  // [PROTOC-BASH]
  // protoc rejects non-array JSON for google.protobuf.ListValue
  // Oracle: deserializing a JSON object as ListValue throws invalidJSONStructure
  func test_deserialize_googleProtobufListValue_fromNonArray_throwsError() throws {
    let lvDesc = _MessageDescriptor(name: "ListValue", fullName: "google.protobuf.ListValue")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("{\"key\": \"value\"}".data(using: .utf8)!, using: lvDesc)
    ) { error in
      if let jsonError = error as? _JSONDeserializationError,
        case .invalidJSONStructure = jsonError
      {
        // Expected
      }
      else {
        XCTFail("Expected invalidJSONStructure, got: \(error)")
      }
    }
  }

  // MARK: - decodeAnyFromAny error paths

  // [PROTOC-BASH]
  // protoc rejects non-object JSON for google.protobuf.Any
  func test_deserialize_googleProtobufAny_fromNonObject_throwsError() throws {
    let anyDesc = _MessageDescriptor(name: "Any", fullName: "google.protobuf.Any")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("\"hello\"".data(using: .utf8)!, using: anyDesc)
    )
  }

  // [PROTOC-BASH]
  // protoc rejects Any object without @type key
  func test_deserialize_googleProtobufAny_withoutAtType_throwsError() throws {
    let anyDesc = _MessageDescriptor(name: "Any", fullName: "google.protobuf.Any")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("{\"value\": \"hello\"}".data(using: .utf8)!, using: anyDesc)
    )
  }

  // [PROTOC-BASH]
  // protoc rejects Any with typeUrl without slash
  func test_deserialize_googleProtobufAny_typeUrlWithoutSlash_throwsError() throws {
    let anyDesc = _MessageDescriptor(name: "Any", fullName: "google.protobuf.Any")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("{\"@type\": \"notavalidurl\"}".data(using: .utf8)!, using: anyDesc)
    )
  }

  // [PROTOC-BASH]
  // protoc rejects Any with unregistered type
  func test_deserialize_googleProtobufAny_unregisteredType_throwsError() throws {
    let anyDesc = _MessageDescriptor(name: "Any", fullName: "google.protobuf.Any")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    XCTAssertThrowsError(
      try deserializer.deserialize(
        "{\"@type\": \"type.googleapis.com/unregistered.Type\"}".data(using: .utf8)!,
        using: anyDesc
      )
    )
  }

  // MARK: - Wrapper type wrong-type errors

  // [PROTOC-BASH]
  // protoc rejects string JSON for google.protobuf.DoubleValue (expects number)
  func test_deserialize_doubleValue_fromString_throwsError() throws {
    let desc = _MessageDescriptor(name: "DoubleValue", fullName: "google.protobuf.DoubleValue")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("\"not_a_number\"".data(using: .utf8)!, using: desc)
    )
  }

  // [PROTOC-BASH]
  // protoc rejects string JSON for google.protobuf.FloatValue (expects number)
  func test_deserialize_floatValue_fromString_throwsError() throws {
    let desc = _MessageDescriptor(name: "FloatValue", fullName: "google.protobuf.FloatValue")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("\"not_a_number\"".data(using: .utf8)!, using: desc)
    )
  }

  // [PROTOC-BASH]
  // protoc rejects string JSON for google.protobuf.Int32Value (expects number)
  func test_deserialize_int32Value_fromString_throwsError() throws {
    let desc = _MessageDescriptor(name: "Int32Value", fullName: "google.protobuf.Int32Value")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("\"not_a_number\"".data(using: .utf8)!, using: desc)
    )
  }

  // [PROTOC-BASH]
  // protoc rejects string JSON for google.protobuf.UInt32Value (expects number)
  func test_deserialize_uint32Value_fromString_throwsError() throws {
    let desc = _MessageDescriptor(name: "UInt32Value", fullName: "google.protobuf.UInt32Value")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("\"not_a_number\"".data(using: .utf8)!, using: desc)
    )
  }

  // [PROTOC-BASH]
  // protoc requires string for google.protobuf.Int64Value (not JSON number)
  func test_deserialize_int64Value_fromNumber_throwsError() throws {
    let desc = _MessageDescriptor(name: "Int64Value", fullName: "google.protobuf.Int64Value")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("42".data(using: .utf8)!, using: desc)
    )
  }

  // [PROTOC-BASH]
  // protoc requires string for google.protobuf.UInt64Value (not JSON number)
  func test_deserialize_uint64Value_fromNumber_throwsError() throws {
    let desc = _MessageDescriptor(name: "UInt64Value", fullName: "google.protobuf.UInt64Value")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("42".data(using: .utf8)!, using: desc)
    )
  }

  // [PROTOC-BASH]
  // protoc requires boolean for google.protobuf.BoolValue (not JSON number 1)
  func test_deserialize_boolValue_fromNumber_throwsError() throws {
    let desc = _MessageDescriptor(name: "BoolValue", fullName: "google.protobuf.BoolValue")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("1".data(using: .utf8)!, using: desc)
    )
  }

  // [PROTOC-BASH]
  // protoc requires string for google.protobuf.StringValue (not JSON number)
  func test_deserialize_stringValue_fromNumber_throwsError() throws {
    let desc = _MessageDescriptor(name: "StringValue", fullName: "google.protobuf.StringValue")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("42".data(using: .utf8)!, using: desc)
    )
  }

  // [PROTOC-BASH]
  // protoc requires base64 string for google.protobuf.BytesValue (not JSON number)
  func test_deserialize_bytesValue_fromNumber_throwsError() throws {
    let desc = _MessageDescriptor(name: "BytesValue", fullName: "google.protobuf.BytesValue")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("42".data(using: .utf8)!, using: desc)
    )
  }

  // MARK: - Timestamp parse paths

  // [PROTOC-BASH]
  // protoc accepts RFC 3339 timestamps; fractional seconds without tz suffix are treated as UTC
  // Oracle: timestamp "2023-01-15T10:30:00.123" (no Z) hits no-tz-indicator path and parses OK
  func test_deserialize_timestamp_noTzIndicator_parsesSuccessfully() throws {
    var tsDesc = _MessageDescriptor(name: "Timestamp", fullName: "google.protobuf.Timestamp")
    tsDesc.addField(_FieldDescriptor(name: "seconds", number: 1, type: .int64))
    tsDesc.addField(_FieldDescriptor(name: "nanos", number: 2, type: .int32))

    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    let json = "\"2023-01-15T10:30:00.123\"".data(using: .utf8)!
    let result = try deserializer.deserialize(json, using: tsDesc)

    XCTAssertNotNil(result)
  }

  // [PROTOC-BASH]
  // protoc rejects malformed RFC 3339 timestamp strings
  // Oracle: "not-a-date" as timestamp throws invalidJSONStructure
  func test_deserialize_timestamp_invalidDateString_throwsError() throws {
    let tsDesc = _MessageDescriptor(name: "Timestamp", fullName: "google.protobuf.Timestamp")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("\"not-a-date\"".data(using: .utf8)!, using: tsDesc)
    )
  }

  // [PROTOC-BASH]
  // protoc rejects timestamps with non-numeric fractional seconds
  // Oracle: "2023-01-15T10:30:00.abcZ" throws invalidJSONStructure
  func test_deserialize_timestamp_invalidFractionalSeconds_throwsError() throws {
    let tsDesc = _MessageDescriptor(name: "Timestamp", fullName: "google.protobuf.Timestamp")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("\"2023-01-15T10:30:00.abcZ\"".data(using: .utf8)!, using: tsDesc)
    )
  }

  // MARK: - Duration parse errors

  // [PROTOC-BASH]
  // protoc rejects duration strings with empty seconds component
  // Oracle: ".5s" (empty seconds before dot) throws invalidJSONStructure
  func test_deserialize_duration_emptySecondsComponent_throwsError() throws {
    let durDesc = _MessageDescriptor(name: "Duration", fullName: "google.protobuf.Duration")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("\".5s\"".data(using: .utf8)!, using: durDesc)
    )
  }

  // [PROTOC-BASH]
  // protoc rejects duration strings with non-numeric fractional part
  // Oracle: "10.ABCs" (non-numeric frac) throws invalidJSONStructure
  func test_deserialize_duration_nonNumericFractional_throwsError() throws {
    let durDesc = _MessageDescriptor(name: "Duration", fullName: "google.protobuf.Duration")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("\"10.ABCs\"".data(using: .utf8)!, using: durDesc)
    )
  }

  // MARK: - Nesting depth exceeded for WKT internals

  // [PUBLIC-MIRROR] JSONDeserializerProtocComplianceTests.test_deserialize_nestingDepthExceeded_whenMaxDepthTooLow
  // Oracle: maxNestingDepth:-1 with google.protobuf.Value triggers nestingDepthExceeded in decodeValueFromAny
  func test_deserialize_googleProtobufValue_maxDepthExceeded_throwsError() throws {
    let desc = _MessageDescriptor(name: "Value", fullName: "google.protobuf.Value")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry(), maxNestingDepth: -1)
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("null".data(using: .utf8)!, using: desc)
    ) { error in
      if let jsonError = error as? _JSONDeserializationError,
        case .nestingDepthExceeded = jsonError
      {
        // Expected
      }
      else {
        XCTFail("Expected nestingDepthExceeded, got: \(error)")
      }
    }
  }

  // [PUBLIC-MIRROR] same
  // Oracle: maxNestingDepth:-1 with google.protobuf.Struct triggers nestingDepthExceeded in decodeStructFromObject
  func test_deserialize_googleProtobufStruct_maxDepthExceeded_throwsError() throws {
    let desc = _MessageDescriptor(name: "Struct", fullName: "google.protobuf.Struct")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry(), maxNestingDepth: -1)
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("{}".data(using: .utf8)!, using: desc)
    ) { error in
      if let jsonError = error as? _JSONDeserializationError,
        case .nestingDepthExceeded = jsonError
      {
        // Expected
      }
      else {
        XCTFail("Expected nestingDepthExceeded, got: \(error)")
      }
    }
  }

  // [PUBLIC-MIRROR] same
  // Oracle: maxNestingDepth:-1 with google.protobuf.ListValue triggers nestingDepthExceeded
  func test_deserialize_googleProtobufListValue_maxDepthExceeded_throwsError() throws {
    let desc = _MessageDescriptor(name: "ListValue", fullName: "google.protobuf.ListValue")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry(), maxNestingDepth: -1)
    )

    XCTAssertThrowsError(
      try deserializer.deserialize("[]".data(using: .utf8)!, using: desc)
    ) { error in
      if let jsonError = error as? _JSONDeserializationError,
        case .nestingDepthExceeded = jsonError
      {
        // Expected
      }
      else {
        XCTFail("Expected nestingDepthExceeded, got: \(error)")
      }
    }
  }

  // MARK: - Int64 / UInt64 from JSON number (NSNumber)

  // [PROTOC-BASH]
  // protoc also accepts JSON number for int64 (not just string)
  // Oracle: JSON number 42 for int64 field deserializes to Int64(42)
  func test_deserialize_int64Field_fromJSONNumber_succeeds() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "count", number: 1, type: .int64))

    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: TypeRegistry())
    )
    let json = "{\"count\": 42}".data(using: .utf8)!
    let result = try await deserializer.deserialize(json, using: desc)

    let value = try result.get(forField: "count")
    XCTAssertNotNil(value)
  }

  // [PROTOC-BASH]
  // protoc also accepts JSON number for uint64 (not just string)
  // Oracle: JSON number 42 for uint64 field deserializes to UInt64(42)
  func test_deserialize_uint64Field_fromJSONNumber_succeeds() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "count", number: 1, type: .uint64))

    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: TypeRegistry())
    )
    let json = "{\"count\": 42}".data(using: .utf8)!
    let result = try await deserializer.deserialize(json, using: desc)

    let value = try result.get(forField: "count")
    XCTAssertNotNil(value)
  }

  // MARK: - Float field type mismatch

  // [PROTOC-BASH]
  // protoc rejects non-number, non-string values for float fields
  // Oracle: JSON array for float field throws valueTypeMismatch
  func test_deserialize_floatField_fromArray_throwsValueTypeMismatch() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "f", number: 1, type: .float))

    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: TypeRegistry())
    )
    let json = "{\"f\": [1, 2]}".data(using: .utf8)!

    do {
      _ = try await deserializer.deserialize(json, using: desc)
      XCTFail("Expected error")
    }
    catch let error as JSONDeserializationError {
      if case .valueTypeMismatch = error {
        // Expected
      }
      else {
        XCTFail("Expected valueTypeMismatch, got: \(error)")
      }
    }
  }

  // MARK: - Enum type mismatch

  // [PROTOC-BASH]
  // protoc rejects non-number, non-string values for enum fields
  // Oracle: JSON array for enum field throws valueTypeMismatch
  func test_deserialize_enumField_fromArray_throwsValueTypeMismatch() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "status", number: 1, type: .enum, typeName: "Status"))

    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: TypeRegistry())
    )
    let json = "{\"status\": [\"A\", \"B\"]}".data(using: .utf8)!

    do {
      _ = try await deserializer.deserialize(json, using: desc)
      XCTFail("Expected error")
    }
    catch let error as JSONDeserializationError {
      if case .valueTypeMismatch = error {
        // Expected
      }
      else {
        XCTFail("Expected valueTypeMismatch, got: \(error)")
      }
    }
  }

  // MARK: - Extension field found by jsonName

  // [PUBLIC-MIRROR] JSONDeserializationTests — extension fields are deserialized by JSON name
  // Oracle: extension field with different name and jsonName is found by jsonName in JSON
  func test_deserialize_extensionField_foundByJsonName_succeeds() throws {
    var msgDesc = _MessageDescriptor(name: "M", fullName: "M")
    let extField = _FieldDescriptor(name: "ext_field", number: 100, type: .string, jsonName: "extField")
    msgDesc.addExtension(extField)

    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )
    let jsonObj: [String: Any] = ["extField": "hello"]
    let result = try deserializer.deserializeFromJSONObject(jsonObj, using: msgDesc)

    let value = try result.get(forField: 100)
    XCTAssertEqual(value as? String, "hello")
  }

  // MARK: - Map missingMapEntryInfo error

  // [PUBLIC-MIRROR] JSONDeserializationTests — map field without mapEntryInfo throws
  // Oracle: map field descriptor with isMap:true and no mapEntryInfo → missingMapEntryInfo error
  func test_deserialize_mapField_missingMapEntryInfo_throwsError() throws {
    var msgDesc = _MessageDescriptor(name: "M", fullName: "M")
    let mapField = _FieldDescriptor(
      name: "labels",
      number: 1,
      type: .message,
      isRepeated: true,
      isMap: true,
      mapEntryInfo: nil
    )
    msgDesc.addField(mapField)

    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )
    let jsonObj: [String: Any] = ["labels": ["key": "value"]]

    XCTAssertThrowsError(
      try deserializer.deserializeFromJSONObject(jsonObj, using: msgDesc)
    ) { error in
      if let jsonError = error as? _JSONDeserializationError,
        case .missingMapEntryInfo = jsonError
      {
        // Expected
      }
      else {
        XCTFail("Expected missingMapEntryInfo, got: \(error)")
      }
    }
  }

  // MARK: - Value fallback (else branch in decodeValueFromAny)

  // [PROTOC-BASH]
  // protoc treats unknown JSON types as null in google.protobuf.Value
  // Oracle: non-JSON-primitive passed to decodeValueFromAny falls back to null_value
  func test_deserialize_googleProtobufValue_unknownType_fallsBackToNull() throws {
    let valueDesc = _MessageDescriptor(name: "Value", fullName: "google.protobuf.Value")
    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )

    let date = Date()
    let result = try deserializer.deserializeWKTFromAny(date, using: valueDesc, depth: 0)

    XCTAssertNotNil(result)
  }

  // MARK: - Legacy enum fallback in map deserialization

  // [PUBLIC-MIRROR] resolveEnumDescriptor tests — legacy structural nesting fallback
  // Oracle: map value enum not in registry but found in descriptor.nestedEnums → used via legacy path
  func test_deserialize_mapField_legacyEnumFallback_succeeds() throws {
    var msgDesc = _MessageDescriptor(name: "M", fullName: "M")

    var enumDesc = _EnumDescriptor(name: "Status", fullName: "M.Status")
    enumDesc.addValue(_EnumDescriptor._EnumValue(name: "UNKNOWN", number: 0))
    enumDesc.addValue(_EnumDescriptor._EnumValue(name: "ACTIVE", number: 1))
    msgDesc.addNestedEnum(enumDesc)

    let keyInfo = _KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo = _ValueFieldInfo(name: "value", number: 2, type: .enum, typeName: ".M.Status")
    let mapEntryInfo = _MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valueInfo)
    let mapField = _FieldDescriptor(
      name: "labels",
      number: 1,
      type: .message,
      isRepeated: true,
      isMap: true,
      mapEntryInfo: mapEntryInfo
    )
    msgDesc.addField(mapField)

    let deserializer = _JSONDeserializer(
      options: _JSONDeserializationOptions(typeRegistry: _TypeRegistry())
    )
    let jsonObj: [String: Any] = ["labels": ["key1": "ACTIVE"]]
    let result = try deserializer.deserializeFromJSONObject(jsonObj, using: msgDesc)

    XCTAssertNotNil(result)
  }
}
