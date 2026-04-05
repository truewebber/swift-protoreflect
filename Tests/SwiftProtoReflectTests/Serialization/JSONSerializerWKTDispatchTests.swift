//
// JSONSerializerWKTDispatchTests.swift
// SwiftProtoReflect
//
// Created: 2026-04-05
//

import XCTest

@testable import SwiftProtoReflect

final class JSONSerializerWKTDispatchTests: XCTestCase {

  // MARK: - Helpers

  private func makeEmptyDescriptor() -> MessageDescriptor {
    var file = FileDescriptor(name: "google/protobuf/empty.proto", package: "google.protobuf")
    let desc = MessageDescriptor(name: "Empty", parent: file)
    file.addMessage(desc)
    return file.messages["Empty"]!
  }

  private func makeTimestampDescriptor() -> MessageDescriptor {
    var file = FileDescriptor(name: "google/protobuf/timestamp.proto", package: "google.protobuf")
    var desc = MessageDescriptor(name: "Timestamp", parent: file)
    desc.addField(FieldDescriptor(name: "seconds", number: 1, type: .int64))
    desc.addField(FieldDescriptor(name: "nanos", number: 2, type: .int32))
    file.addMessage(desc)
    return file.messages["Timestamp"]!
  }

  // MARK: - Non-WKT messages always use standard field-by-field encoding

  func test_serialize_nonWKTMessage_withCanonicalEnabled_usesStandardEncoding() throws {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addField(FieldDescriptor(name: "name", number: 1, type: .string, jsonName: "name"))
    var msg = DynamicMessage(descriptor: desc)
    try msg.set("hello", forField: 1)

    let serializer = JSONSerializer(
      options: JSONSerializationOptions(
        useCanonicalWellKnownTypeEncoding: true,
        typeRegistry: TypeRegistry()
      )
    )
    let data = try serializer.serialize(msg)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertEqual(json?["name"] as? String, "hello")
  }

  func test_serialize_nonWKTMessage_withCanonicalDisabled_usesStandardEncoding() throws {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addField(FieldDescriptor(name: "value", number: 1, type: .int32, jsonName: "value"))
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(42), forField: 1)

    let serializer = JSONSerializer(
      options: JSONSerializationOptions(
        useCanonicalWellKnownTypeEncoding: false,
        typeRegistry: TypeRegistry()
      )
    )
    let data = try serializer.serialize(msg)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertEqual(json?["value"] as? Int, 42)
  }

  // MARK: - WKT with canonical disabled uses standard field-by-field encoding

  func test_serialize_wktMessage_withCanonicalDisabled_usesStandardEncoding() throws {
    let desc = makeEmptyDescriptor()
    let msg = DynamicMessage(descriptor: desc)

    let serializer = JSONSerializer(
      options: JSONSerializationOptions(
        useCanonicalWellKnownTypeEncoding: false,
        typeRegistry: TypeRegistry()
      )
    )
    let data = try serializer.serialize(msg)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertNotNil(json)
  }

  // MARK: - WKT dispatch — unimplemented WKT throws descriptive error

  func test_serializeMessageToAny_dispatchesToWKTEncoder() throws {
    let desc = makeTimestampDescriptor()
    let msg = DynamicMessage(descriptor: desc)

    let serializer = JSONSerializer(
      options: JSONSerializationOptions(
        useCanonicalWellKnownTypeEncoding: true,
        typeRegistry: TypeRegistry()
      )
    )
    XCTAssertThrowsError(try serializer.serialize(msg)) { error in
      guard case JSONSerializationError.unsupportedWellKnownTypeEncoding(let typeName) = error else {
        XCTFail("Expected unsupportedWellKnownTypeEncoding, got \(error)")
        return
      }
      XCTAssertEqual(typeName, "google.protobuf.Timestamp")
    }
  }

  // MARK: - google.protobuf.Empty canonical encoding produces {}

  func test_serialize_empty_withCanonicalEnabled_producesEmptyObject() throws {
    let desc = makeEmptyDescriptor()
    let msg = DynamicMessage(descriptor: desc)

    let serializer = JSONSerializer(
      options: JSONSerializationOptions(
        useCanonicalWellKnownTypeEncoding: true,
        typeRegistry: TypeRegistry()
      )
    )
    let data = try serializer.serialize(msg)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertNotNil(json)
    XCTAssertEqual(json?.count, 0)
  }
}
