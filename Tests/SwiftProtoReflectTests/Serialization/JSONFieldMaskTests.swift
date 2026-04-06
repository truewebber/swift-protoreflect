//
// JSONFieldMaskTests.swift
// SwiftProtoReflect
//
// Created: 2026-04-05
//

import XCTest

@testable import SwiftProtoReflect

final class JSONFieldMaskTests: XCTestCase {

  // MARK: - Helpers

  private func makeFieldMaskDescriptor() -> MessageDescriptor {
    var file = FileDescriptor(name: "google/protobuf/field_mask.proto", package: "google.protobuf")
    var desc = MessageDescriptor(name: "FieldMask", parent: file)
    desc.addField(FieldDescriptor(name: "paths", number: 1, type: .string, isRepeated: true))
    file.addMessage(desc)
    return file.messages["FieldMask"]!
  }

  private func makeFieldMaskMessage(paths: [String]) throws -> DynamicMessage {
    let desc = makeFieldMaskDescriptor()
    var msg = DynamicMessage(descriptor: desc)
    if !paths.isEmpty {
      try msg.set(paths, forField: 1)
    }
    return msg
  }

  private func canonicalSerializer() -> JSONSerializer {
    JSONSerializer(
      options: JSONSerializationOptions(
        useCanonicalWellKnownTypeEncoding: true,
        typeRegistry: TypeRegistry()
      )
    )
  }

  private func deserializer() -> JSONDeserializer {
    JSONDeserializer(options: JSONDeserializationOptions(typeRegistry: TypeRegistry()))
  }

  // MARK: - Encoder tests

  func test_serialize_fieldMask_singlePath_producesCamelCase() async throws {
    let msg = try makeFieldMaskMessage(paths: ["foo_bar"])
    let data = try await canonicalSerializer().serialize(msg)
    let str = try XCTUnwrap(String(data: data, encoding: .utf8))
    XCTAssertEqual(str, #""fooBar""#)
  }

  func test_serialize_fieldMask_multiplePaths_producesCommaSeparated() async throws {
    let msg = try makeFieldMaskMessage(paths: ["foo_bar", "baz_qux"])
    let data = try await canonicalSerializer().serialize(msg)
    let str = try XCTUnwrap(String(data: data, encoding: .utf8))
    XCTAssertEqual(str, #""fooBar,bazQux""#)
  }

  func test_serialize_fieldMask_empty_producesEmptyString() async throws {
    let msg = try makeFieldMaskMessage(paths: [])
    let data = try await canonicalSerializer().serialize(msg)
    let str = try XCTUnwrap(String(data: data, encoding: .utf8))
    XCTAssertEqual(str, #""""#)
  }

  func test_serialize_fieldMask_deepPath_producesCamelCase() async throws {
    let msg = try makeFieldMaskMessage(paths: ["foo_bar_baz"])
    let data = try await canonicalSerializer().serialize(msg)
    let str = try XCTUnwrap(String(data: data, encoding: .utf8))
    XCTAssertEqual(str, #""fooBarBaz""#)
  }

  func test_serialize_fieldMask_alreadyLowercase_unchanged() async throws {
    let msg = try makeFieldMaskMessage(paths: ["name"])
    let data = try await canonicalSerializer().serialize(msg)
    let str = try XCTUnwrap(String(data: data, encoding: .utf8))
    XCTAssertEqual(str, #""name""#)
  }

  // MARK: - Decoder tests

  func test_deserialize_fieldMask_camelCase_toSnakeCase() async throws {
    let json = #""fooBar,bazQux""#.data(using: .utf8)!
    let desc = makeFieldMaskDescriptor()
    let msg = try await deserializer().deserialize(json, using: desc)
    let paths = try XCTUnwrap(try msg.get(forField: 1) as? [String])
    XCTAssertEqual(paths, ["foo_bar", "baz_qux"])
  }

  func test_deserialize_fieldMask_empty_producesEmptyPaths() async throws {
    let json = #""""#.data(using: .utf8)!
    let desc = makeFieldMaskDescriptor()
    let msg = try await deserializer().deserialize(json, using: desc)
    // Empty paths — field may be absent or empty array
    let paths = (try? msg.get(forField: 1) as? [String]) ?? []
    XCTAssertEqual(paths, [])
  }

  func test_deserialize_fieldMask_nonString_throwsError() async throws {
    let json = #"{"paths":["foo_bar"]}"#.data(using: .utf8)!
    let desc = makeFieldMaskDescriptor()
    do {
      try await deserializer().deserialize(json, using: desc)
      XCTFail("Expected error to be thrown")
    }
    catch {
      guard case JSONDeserializationError.invalidJSONStructure = error else {
        XCTFail("Expected invalidJSONStructure, got \(error)")
        return
      }
    }
  }

  func test_deserialize_fieldMask_singlePath() async throws {
    let json = #""fooBarBaz""#.data(using: .utf8)!
    let desc = makeFieldMaskDescriptor()
    let msg = try await deserializer().deserialize(json, using: desc)
    let paths = try XCTUnwrap(try msg.get(forField: 1) as? [String])
    XCTAssertEqual(paths, ["foo_bar_baz"])
  }

  // MARK: - Round-trip tests

  func test_roundTrip_fieldMask_preservesPaths() async throws {
    let original = ["foo_bar", "baz_qux_quux"]
    let msg = try makeFieldMaskMessage(paths: original)

    let data = try await canonicalSerializer().serialize(msg)
    let roundTripped = try await deserializer().deserialize(data, using: makeFieldMaskDescriptor())

    let paths = try XCTUnwrap(try roundTripped.get(forField: 1) as? [String])
    XCTAssertEqual(paths, original)
  }
}
