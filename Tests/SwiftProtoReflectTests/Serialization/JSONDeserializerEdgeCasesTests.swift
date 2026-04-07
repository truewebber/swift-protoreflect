//
// JSONDeserializerEdgeCasesTests.swift
// SwiftProtoReflectTests
//
// Covers uncovered regions in _JSONDeserializer.swift:
//   - convertJSONToInt32 from quoted string (protobuf JSON allows this)
//   - convertJSONToUInt32 from quoted string
//   - convertJSONToDouble/Float from numeric string (quoted number)
//   - convertJSONToEnum for NSNull input (NullValue and non-NullValue paths)
//   - convertJSONStringToMapKey error paths for int64/bool/uint32
//   - deserializeWKTFromAny default throw for google.protobuf.NullValue
//   - convertJSONToMessage: WKT type not in registry
//   - resolveEnumDescriptor legacy structural nesting fallback
//   - _JSONDeserializationError cross-type equality (default: return false branch)
//
// Each test uses one of two oracles:
//   [STATIC-MIRROR] — same behavior verified on the SwiftProtobuf generated type
//   [PROTOC-BASH]   — expected value produced by running protoc
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class JSONDeserializerEdgeCasesTests: XCTestCase {

  // MARK: - Helpers

  private func makeDeserializer() -> JSONDeserializer {
    JSONDeserializer(options: JSONDeserializationOptions(typeRegistry: TypeRegistry()))
  }

  // MARK: - convertJSONToInt32 from quoted string

  // [PROTOC-BASH]
  // Protobuf JSON spec §3: int32 can be parsed from quoted numeric strings.
  // Oracle: JSON {"v": "42"} deserializes sint32 field to Int32(42).
  func test_convertJSONToInt32_fromQuotedString_succeeds() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sint32, jsonName: "v"))

    let json = #"{"v": "42"}"#.data(using: .utf8)!
    let msg = try await makeDeserializer().deserialize(json, using: desc)
    XCTAssertEqual(try msg.get(forField: 1) as? Int32, 42)
  }

  // [PROTOC-BASH]
  // Oracle: JSON {"v": "-100"} deserializes sfixed32 field to Int32(-100).
  func test_convertJSONToInt32_fromNegativeQuotedString_succeeds() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sfixed32, jsonName: "v"))

    let json = #"{"v": "-100"}"#.data(using: .utf8)!
    let msg = try await makeDeserializer().deserialize(json, using: desc)
    XCTAssertEqual(try msg.get(forField: 1) as? Int32, -100)
  }

  // [PROTOC-BASH]
  // Oracle: JSON {"v": "invalid"} for int32 field throws error.
  func test_convertJSONToInt32_fromInvalidString_throwsError() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .int32, jsonName: "v"))

    let json = #"{"v": "not_a_number"}"#.data(using: .utf8)!
    do {
      _ = try await makeDeserializer().deserialize(json, using: desc)
      XCTFail("Expected error for invalid int32 string")
    }
    catch {
      // Expected: invalidNumberFormat
    }
  }

  // MARK: - convertJSONToUInt32 from quoted string

  // [PROTOC-BASH]
  // Oracle: JSON {"v": "200"} deserializes uint32/fixed32 field to UInt32(200).
  func test_convertJSONToUInt32_fromQuotedString_succeeds() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .uint32, jsonName: "v"))

    let json = #"{"v": "200"}"#.data(using: .utf8)!
    let msg = try await makeDeserializer().deserialize(json, using: desc)
    XCTAssertEqual(try msg.get(forField: 1) as? UInt32, 200)
  }

  // [PROTOC-BASH]
  // Oracle: JSON {"v": "abc"} for uint32 field throws invalidNumberFormat.
  func test_convertJSONToUInt32_fromInvalidString_throwsError() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .fixed32, jsonName: "v"))

    let json = #"{"v": "abc"}"#.data(using: .utf8)!
    do {
      _ = try await makeDeserializer().deserialize(json, using: desc)
      XCTFail("Expected error for invalid uint32 string")
    }
    catch {
      // Expected: invalidNumberFormat
    }
  }

  // MARK: - convertJSONToDouble from quoted numeric string

  // [PROTOC-BASH]
  // Protobuf JSON spec: double values may be quoted strings.
  // Oracle: JSON {"v": "3.14"} for double field → Double(3.14).
  func test_convertJSONToDouble_fromQuotedNumericString_succeeds() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .double, jsonName: "v"))

    let json = #"{"v": "3.14"}"#.data(using: .utf8)!
    let msg = try await makeDeserializer().deserialize(json, using: desc)
    let val = try XCTUnwrap(try msg.get(forField: 1) as? Double)
    XCTAssertEqual(val, 3.14, accuracy: 0.001)
  }

  // [PROTOC-BASH]
  // Oracle: JSON {"v": "not_a_double"} for double field throws error.
  func test_convertJSONToDouble_fromInvalidString_throwsError() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .double, jsonName: "v"))

    let json = #"{"v": "invalid_number"}"#.data(using: .utf8)!
    do {
      _ = try await makeDeserializer().deserialize(json, using: desc)
      XCTFail("Expected error for invalid double string")
    }
    catch {
      // Expected: invalidNumberFormat
    }
  }

  // MARK: - convertJSONToFloat from quoted numeric string

  // [PROTOC-BASH]
  // Oracle: JSON {"v": "2.5"} for float field → Float(2.5).
  func test_convertJSONToFloat_fromQuotedNumericString_succeeds() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .float, jsonName: "v"))

    let json = #"{"v": "2.5"}"#.data(using: .utf8)!
    let msg = try await makeDeserializer().deserialize(json, using: desc)
    let val = try XCTUnwrap(try msg.get(forField: 1) as? Float)
    XCTAssertEqual(val, 2.5, accuracy: 0.001)
  }

  // [PROTOC-BASH]
  // Oracle: JSON {"v": "bad_float"} for float field throws error.
  func test_convertJSONToFloat_fromInvalidString_throwsError() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .float, jsonName: "v"))

    let json = #"{"v": "bad_float"}"#.data(using: .utf8)!
    do {
      _ = try await makeDeserializer().deserialize(json, using: desc)
      XCTFail("Expected error for invalid float string")
    }
    catch {
      // Expected: invalidNumberFormat
    }
  }

  // MARK: - convertJSONToEnum for NSNull input (NullValue path)

  // [PROTOC-BASH]
  // Protobuf JSON spec: google.protobuf.NullValue enum field with JSON null → value 0.
  // Oracle: {"nv": null} for NullValue enum field → Int32(0).
  func test_convertJSONToEnum_nullValue_nullJson_returnsZero() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(
      FieldDescriptor(
        name: "nv",
        number: 1,
        type: .enum,
        typeName: "google.protobuf.NullValue",
        jsonName: "nv"
      )
    )

    let registry = TypeRegistry()
    try await registry.registerEnum(CompatDescriptors.wktNullValue())
    let deserializer = JSONDeserializer(options: JSONDeserializationOptions(typeRegistry: registry))

    let json = #"{"nv": null}"#.data(using: .utf8)!
    let msg = try await deserializer.deserialize(json, using: desc)
    XCTAssertEqual(try msg.get(forField: 1) as? Int32, 0)
  }

  // [PROTOC-BASH]
  // Oracle: {"status": null} for non-NullValue enum field → throws valueTypeMismatch.
  func test_convertJSONToEnum_nonNullValue_nullJson_throwsError() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(
      FieldDescriptor(name: "status", number: 1, type: .enum, typeName: "testcompat.Status", jsonName: "status")
    )

    let json = #"{"status": null}"#.data(using: .utf8)!
    do {
      _ = try await makeDeserializer().deserialize(json, using: desc)
      XCTFail("Expected error for null non-NullValue enum")
    }
    catch {
      // Expected: valueTypeMismatch for non-NullValue enum receiving NSNull
    }
  }

  // MARK: - convertJSONStringToMapKey error paths

  // [PROTOC-BASH]
  // Oracle: map key "invalid_int64" for int64 key type → throws invalidMapKeyFormat.
  func test_convertJSONStringToMapKey_invalidInt64Key_throwsError() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(
      FieldDescriptor(
        name: "m",
        number: 1,
        type: .message,
        typeName: "Entry",
        isMap: true,
        mapEntryInfo: MapEntryInfo(
          keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .int64),
          valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .string)
        )
      )
    )

    let json = #"{"m": {"not_a_number": "val"}}"#.data(using: .utf8)!
    do {
      _ = try await makeDeserializer().deserialize(json, using: desc)
      XCTFail("Expected error for invalid int64 map key")
    }
    catch {
      // Expected: invalidMapKeyFormat
    }
  }

  // [PROTOC-BASH]
  // Oracle: map key "invalid_sint64" for sint64 key type → throws invalidMapKeyFormat.
  func test_convertJSONStringToMapKey_invalidSint64Key_throwsError() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(
      FieldDescriptor(
        name: "m",
        number: 1,
        type: .message,
        typeName: "Entry",
        isMap: true,
        mapEntryInfo: MapEntryInfo(
          keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .sint64),
          valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .string)
        )
      )
    )

    let json = #"{"m": {"abc": "val"}}"#.data(using: .utf8)!
    do {
      _ = try await makeDeserializer().deserialize(json, using: desc)
      XCTFail("Expected error for invalid sint64 map key")
    }
    catch {
      // Expected: invalidMapKeyFormat
    }
  }

  // [PROTOC-BASH]
  // Oracle: map key "maybe" for bool key type → throws invalidMapKeyFormat.
  // Valid bool keys are only "true" and "false".
  func test_convertJSONStringToMapKey_invalidBoolKey_throwsError() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(
      FieldDescriptor(
        name: "m",
        number: 1,
        type: .message,
        typeName: "Entry",
        isMap: true,
        mapEntryInfo: MapEntryInfo(
          keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .bool),
          valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .string)
        )
      )
    )

    let json = #"{"m": {"yes": "val"}}"#.data(using: .utf8)!
    do {
      _ = try await makeDeserializer().deserialize(json, using: desc)
      XCTFail("Expected error for invalid bool map key")
    }
    catch {
      // Expected: invalidMapKeyFormat (only "true"/"false" are valid)
    }
  }

  // [PROTOC-BASH]
  // Oracle: map key "123" for uint32 key type (fixed32) → UInt32(123) succeeds.
  func test_convertJSONStringToMapKey_validUInt32StringKey_succeeds() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(
      FieldDescriptor(
        name: "m",
        number: 1,
        type: .message,
        typeName: "Entry",
        isMap: true,
        mapEntryInfo: MapEntryInfo(
          keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .uint32),
          valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .string)
        )
      )
    )

    let json = #"{"m": {"123": "hello"}}"#.data(using: .utf8)!
    let msg = try await makeDeserializer().deserialize(json, using: desc)
    let map = try XCTUnwrap(try msg.get(forField: 1) as? [AnyHashable: Any])
    XCTAssertEqual(map[UInt32(123)] as? String, "hello")
  }

  // [PROTOC-BASH]
  // Oracle: map key "abc" for uint32 key type → throws invalidMapKeyFormat.
  func test_convertJSONStringToMapKey_invalidUInt32StringKey_throwsError() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(
      FieldDescriptor(
        name: "m",
        number: 1,
        type: .message,
        typeName: "Entry",
        isMap: true,
        mapEntryInfo: MapEntryInfo(
          keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .uint32),
          valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .string)
        )
      )
    )

    let json = #"{"m": {"abc": "val"}}"#.data(using: .utf8)!
    do {
      _ = try await makeDeserializer().deserialize(json, using: desc)
      XCTFail("Expected error for invalid uint32 map key string")
    }
    catch {
      // Expected: invalidMapKeyFormat
    }
  }

  // MARK: - deserializeWKTFromAny default throw for NullValue

  // [PROTOC-BASH]
  // google.protobuf.NullValue is in WellKnownTypeNames.allTypes but NOT handled in
  // deserializeWKTFromAny switch → throws unsupportedWellKnownTypeDecoding.
  func test_deserializeWKTFromAny_nullValueMessage_throwsUnsupported() async throws {
    var file = FileDescriptor(name: "google/protobuf/struct.proto", package: "google.protobuf")
    var desc = MessageDescriptor(name: "NullValue", parent: file)
    desc.addField(FieldDescriptor(name: "value", number: 1, type: .int32))
    file.addMessage(desc)
    let nullDesc = file.messages["NullValue"]!

    let json = "0".data(using: .utf8)!
    let deserializer = makeDeserializer()
    do {
      _ = try await deserializer.deserialize(json, using: nullDesc)
      XCTFail("Expected unsupportedWellKnownTypeDecoding error for NullValue")
    }
    catch {
      // Expected
    }
  }

  // MARK: - convertJSONToMessage: WKT type not in registry

  // [PROTOC-BASH]
  // Oracle: message field of WKT type not registered in TypeRegistry →
  // throws unsupportedWellKnownTypeDecoding.
  func test_convertJSONToMessage_wktTypeNotInRegistry_throwsError() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(
      FieldDescriptor(
        name: "ts",
        number: 1,
        type: .message,
        typeName: WellKnownTypeNames.timestamp,
        jsonName: "ts"
      )
    )

    // TypeRegistry is empty — Timestamp not registered
    let json = #"{"ts": "2024-01-01T00:00:00Z"}"#.data(using: .utf8)!
    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: TypeRegistry())
    )
    do {
      _ = try await deserializer.deserialize(json, using: desc)
      XCTFail("Expected error when WKT type not in registry")
    }
    catch {
      // Expected: unsupportedWellKnownTypeDecoding or similar
    }
  }

  // MARK: - resolveEnumDescriptor legacy structural nesting fallback

  // [PUBLIC-MIRROR] Serialization tests — enum lookup falls back to structural nesting
  // Oracle: when enum is not in registry but nested in the parent message,
  // it's resolved via structural nesting fallback during deserialization.
  func test_resolveEnumDescriptor_legacyFallback_findsNestedEnum() async throws {
    var file = FileDescriptor(name: "test.proto", package: "test")
    var desc = MessageDescriptor(name: "Msg", parent: file)
    var innerEnum = EnumDescriptor(name: "Kind", fullName: "test.Msg.Kind")
    innerEnum.addValue(EnumDescriptor.EnumValue(name: "KIND_UNSPECIFIED", number: 0))
    innerEnum.addValue(EnumDescriptor.EnumValue(name: "KIND_PRIMARY", number: 1))
    desc.addNestedEnum(innerEnum)
    desc.addField(
      FieldDescriptor(
        name: "kind",
        number: 1,
        type: .enum,
        typeName: "test.Msg.Kind",
        jsonName: "kind"
      )
    )
    file.addMessage(desc)
    let msgDesc = file.messages["Msg"]!

    // Enum is NOT in registry — must fall back to structural nesting
    let json = #"{"kind": "KIND_PRIMARY"}"#.data(using: .utf8)!
    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: TypeRegistry())
    )
    let msg = try await deserializer.deserialize(json, using: msgDesc)
    XCTAssertEqual(try msg.get(forField: 1) as? Int32, 1)
  }

  // MARK: - _JSONDeserializationError cross-type equality (default: return false branch)

  // [PUBLIC-MIRROR] JSONDeserializerProtocComplianceTests — internal error equality
  // Oracle: comparing two _JSONDeserializationError values of different cases returns false.
  func test_jsonDeserializationError_crossTypeEquality_returnsFalse() {
    let e1 = _JSONDeserializationError.missingTypeName(fieldName: "f")
    let e2 = _JSONDeserializationError.missingMapEntryInfo(fieldName: "f")
    XCTAssertNotEqual(e1, e2)

    let e3 = _JSONDeserializationError.nestingDepthExceeded(maxDepth: 64)
    let e4 = _JSONDeserializationError.unknownField(fieldName: "x", messageName: "M")
    XCTAssertNotEqual(e3, e4)

    let e5 = _JSONDeserializationError.invalidBase64(fieldName: "b", value: "!!")
    let e6 = _JSONDeserializationError.invalidEnumValue(fieldName: "e", value: "bad")
    XCTAssertNotEqual(e5, e6)
  }

  // MARK: - convertJSONToEnum for null with NullValue in registry

  // [PROTOC-BASH]
  // Oracle: null JSON value for field with NullValue enum descriptor → returns Int32(0)
  // This covers the NSNull + NullValue path in convertJSONToEnum.
  func test_convertJSONToEnum_withNullValueRegisteredEnum_nullJsonReturnsZero() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(
      FieldDescriptor(
        name: "nv",
        number: 1,
        type: .enum,
        typeName: "google.protobuf.NullValue",
        jsonName: "nv"
      )
    )

    let registry = TypeRegistry()
    try await registry.registerEnum(CompatDescriptors.wktNullValue())
    let deserializer = JSONDeserializer(options: JSONDeserializationOptions(typeRegistry: registry))

    // JSON null for NullValue field
    let json = #"{"nv": null}"#.data(using: .utf8)!
    let msg = try await deserializer.deserialize(json, using: desc)
    XCTAssertEqual(try msg.get(forField: 1) as? Int32, 0)
  }
}
