//
// JSONSerializationWritingOptionsTests.swift
// SwiftProtoReflectTests
//
// Covers escapeSlashesInStrings and sortJSONObjectKeys options.
//
// Each assertion uses one of two oracles:
//   [STATIC-MIRROR] — same behavior verified on the SwiftProtobuf generated type
//   [PROTOC-BASH]   — expected value produced by running protoc
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class JSONSerializationWritingOptionsTests: XCTestCase {

  // MARK: - Helpers

  private func descriptor(fields: [(name: String, number: Int, type: FieldType)]) -> MessageDescriptor {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    for f in fields {
      desc.addField(FieldDescriptor(name: f.name, number: f.number, type: f.type, jsonName: f.name))
    }
    return desc
  }

  private func serialize(_ message: DynamicMessage, escapeSlashes: Bool, sortKeys: Bool) async throws -> String {
    let serializer = JSONSerializer(
      options: JSONSerializationOptions(
        escapeSlashesInStrings: escapeSlashes,
        sortJSONObjectKeys: sortKeys,
        typeRegistry: TypeRegistry()
      )
    )
    let data = try await serializer.serialize(message)
    return try XCTUnwrap(String(data: data, encoding: .utf8))
  }

  // MARK: - escapeSlashesInStrings

  // [STATIC-MIRROR]
  // Foundation JSONSerialization by default escapes '/' as '\/' in strings.
  // Oracle: with escapeSlashesInStrings: true, the raw JSON bytes contain '\/'
  func test_serialize_escapeSlashesTrue_slashEscapedInOutput() async throws {
    let desc = descriptor(fields: [("url", 1, .string)])
    var msg = DynamicMessage(descriptor: desc)
    try msg.set("type.googleapis.com/pkg.Message", forField: 1)

    let json = try await serialize(msg, escapeSlashes: true, sortKeys: false)
    XCTAssertTrue(json.contains("\\/"), "Expected escaped slash '\\/' in output, got: \(json)")
    XCTAssertFalse(json.contains("com/pkg"), "Raw '/' should not appear unescaped, got: \(json)")
  }

  // [STATIC-MIRROR]
  // Oracle: with escapeSlashesInStrings: false, the raw JSON bytes contain '/' directly
  func test_serialize_escapeSlashesFalse_slashNotEscapedInOutput() async throws {
    let desc = descriptor(fields: [("url", 1, .string)])
    var msg = DynamicMessage(descriptor: desc)
    try msg.set("type.googleapis.com/pkg.Message", forField: 1)

    let json = try await serialize(msg, escapeSlashes: false, sortKeys: false)
    XCTAssertTrue(json.contains("com/pkg"), "Expected unescaped '/' in output, got: \(json)")
    XCTAssertFalse(json.contains("\\/"), "Escaped '\\/' should not appear, got: \(json)")
  }

  // [STATIC-MIRROR]
  // Oracle: parsed string value is identical regardless of escapeSlashesInStrings
  func test_serialize_escapeSlashes_roundTrip_sameValue() async throws {
    let desc = descriptor(fields: [("url", 1, .string)])
    var msg = DynamicMessage(descriptor: desc)
    try msg.set("type.googleapis.com/pkg.Message", forField: 1)

    let jsonEscaped = try await serialize(msg, escapeSlashes: true, sortKeys: false)
    let jsonUnescaped = try await serialize(msg, escapeSlashes: false, sortKeys: false)

    let parsedEscaped = try XCTUnwrap(
      JSONSerialization.jsonObject(with: Data(jsonEscaped.utf8)) as? [String: Any]
    )
    let parsedUnescaped = try XCTUnwrap(
      JSONSerialization.jsonObject(with: Data(jsonUnescaped.utf8)) as? [String: Any]
    )

    XCTAssertEqual(parsedEscaped["url"] as? String, parsedUnescaped["url"] as? String)
  }

  // [STATIC-MIRROR]
  // serializeToJSONObject is not affected by escapeSlashesInStrings — strings are returned as-is.
  func test_serializeToJSONObject_unaffectedByEscapeSlashes() async throws {
    let desc = descriptor(fields: [("url", 1, .string)])
    var msg = DynamicMessage(descriptor: desc)
    try msg.set("type.googleapis.com/pkg.Message", forField: 1)

    let serializerEscaped = JSONSerializer(
      options: JSONSerializationOptions(escapeSlashesInStrings: true, typeRegistry: TypeRegistry())
    )
    let serializerUnescaped = JSONSerializer(
      options: JSONSerializationOptions(escapeSlashesInStrings: false, typeRegistry: TypeRegistry())
    )

    let objEscaped = try await serializerEscaped.serializeToJSONObject(msg)
    let objUnescaped = try await serializerUnescaped.serializeToJSONObject(msg)

    XCTAssertEqual(objEscaped["url"] as? String, objUnescaped["url"] as? String)
  }

  // [STATIC-MIRROR]
  // Backslash in string values must still be escaped as '\\' regardless of escapeSlashesInStrings.
  func test_serialize_backslashInString_alwaysEscaped() async throws {
    let desc = descriptor(fields: [("path", 1, .string)])
    var msg = DynamicMessage(descriptor: desc)
    try msg.set("C:\\Users\\test", forField: 1)

    let jsonEscaped = try await serialize(msg, escapeSlashes: true, sortKeys: false)
    let jsonUnescaped = try await serialize(msg, escapeSlashes: false, sortKeys: false)

    // Both must encode backslash as \\
    XCTAssertTrue(jsonEscaped.contains("\\\\"), "Backslash must be escaped in output: \(jsonEscaped)")
    XCTAssertTrue(jsonUnescaped.contains("\\\\"), "Backslash must be escaped in output: \(jsonUnescaped)")
  }

  // MARK: - sortJSONObjectKeys

  // [STATIC-MIRROR]
  // Oracle: Foundation .sortedKeys produces lexicographically sorted keys in JSON text.
  func test_serialize_sortKeysTrue_keysAreSortedLexicographically() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "zebra", number: 1, type: .string, jsonName: "zebra"))
    desc.addField(FieldDescriptor(name: "apple", number: 2, type: .string, jsonName: "apple"))
    desc.addField(FieldDescriptor(name: "mango", number: 3, type: .string, jsonName: "mango"))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set("z", forField: 1)
    try msg.set("a", forField: 2)
    try msg.set("m", forField: 3)

    let json = try await serialize(msg, escapeSlashes: true, sortKeys: true)

    let appleIdx = try XCTUnwrap(json.range(of: "\"apple\"")).lowerBound
    let mangoIdx = try XCTUnwrap(json.range(of: "\"mango\"")).lowerBound
    let zebraIdx = try XCTUnwrap(json.range(of: "\"zebra\"")).lowerBound

    XCTAssertLessThan(appleIdx, mangoIdx, "\"apple\" must come before \"mango\"")
    XCTAssertLessThan(mangoIdx, zebraIdx, "\"mango\" must come before \"zebra\"")
  }

  // [STATIC-MIRROR]
  // Oracle: round-trip with sortKeys produces the same deserialized message.
  func test_serialize_sortKeysTrue_roundTrip_sameMessage() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "zebra", number: 1, type: .string, jsonName: "zebra"))
    desc.addField(FieldDescriptor(name: "apple", number: 2, type: .string, jsonName: "apple"))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set("z", forField: 1)
    try msg.set("a", forField: 2)

    let serializer = JSONSerializer(
      options: JSONSerializationOptions(sortJSONObjectKeys: true, typeRegistry: TypeRegistry())
    )
    let data = try await serializer.serialize(msg)

    let deserializer = JSONDeserializer(
      options: JSONDeserializationOptions(typeRegistry: TypeRegistry())
    )
    let restored = try await deserializer.deserialize(data, using: desc)

    XCTAssertEqual(try restored.get(forField: 1) as? String, "z")
    XCTAssertEqual(try restored.get(forField: 2) as? String, "a")
  }

  // [STATIC-MIRROR]
  // Oracle: sortJSONObjectKeys does not reorder array elements.
  func test_serialize_sortKeysTrue_doesNotReorderArrays() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    let field = FieldDescriptor(name: "tags", number: 1, type: .string, jsonName: "tags", isRepeated: true)
    desc.addField(field)

    var msg = DynamicMessage(descriptor: desc)
    try msg.set(["zebra", "apple", "mango"] as [String], forField: 1)

    let json = try await serialize(msg, escapeSlashes: true, sortKeys: true)
    let parsed = try XCTUnwrap(
      JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
    )
    let tags = try XCTUnwrap(parsed["tags"] as? [String])

    XCTAssertEqual(tags, ["zebra", "apple", "mango"], "Array element order must be preserved")
  }

  // [STATIC-MIRROR]
  // Oracle: sortJSONObjectKeys does not affect serializeToJSONObject (no JSONSerialization involved).
  func test_serializeToJSONObject_unaffectedBySortKeys() async throws {
    var desc = MessageDescriptor(name: "M", fullName: "M")
    desc.addField(FieldDescriptor(name: "zebra", number: 1, type: .string, jsonName: "zebra"))
    desc.addField(FieldDescriptor(name: "apple", number: 2, type: .string, jsonName: "apple"))

    var msg = DynamicMessage(descriptor: desc)
    try msg.set("z", forField: 1)
    try msg.set("a", forField: 2)

    let serializerSorted = JSONSerializer(
      options: JSONSerializationOptions(sortJSONObjectKeys: true, typeRegistry: TypeRegistry())
    )
    let serializerUnsorted = JSONSerializer(
      options: JSONSerializationOptions(sortJSONObjectKeys: false, typeRegistry: TypeRegistry())
    )

    let objSorted = try await serializerSorted.serializeToJSONObject(msg)
    let objUnsorted = try await serializerUnsorted.serializeToJSONObject(msg)

    XCTAssertEqual(objSorted["zebra"] as? String, objUnsorted["zebra"] as? String)
    XCTAssertEqual(objSorted["apple"] as? String, objUnsorted["apple"] as? String)
  }
}
