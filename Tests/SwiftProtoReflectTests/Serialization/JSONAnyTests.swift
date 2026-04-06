//
// JSONAnyTests.swift
// SwiftProtoReflect
//
// Created: 2026-04-05
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class JSONAnyTests: XCTestCase {

  // MARK: - Helpers

  private func makeAnyDescriptor() -> MessageDescriptor {
    var file = FileDescriptor(name: "google/protobuf/any.proto", package: "google.protobuf")
    var desc = MessageDescriptor(name: "Any", parent: file)
    desc.addField(FieldDescriptor(name: "type_url", number: 1, type: .string))
    desc.addField(FieldDescriptor(name: "value", number: 2, type: .bytes))
    file.addMessage(desc)
    return file.messages["Any"]!
  }

  /// Build a simple "Ping" message descriptor and return (file, descriptor).
  private func makePingFileAndDescriptor() -> (FileDescriptor, MessageDescriptor) {
    var file = FileDescriptor(name: "test.proto", package: "test")
    var desc = MessageDescriptor(name: "Ping", parent: file)
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32, jsonName: "id"))
    file.addMessage(desc)
    return (file, file.messages["Ping"]!)
  }

  private func makePingMessage(id: Int32) throws -> DynamicMessage {
    let (_, desc) = makePingFileAndDescriptor()
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(id, forField: 1)
    return msg
  }

  /// Packs a DynamicMessage into a google.protobuf.Any DynamicMessage.
  private func packIntoAny(_ inner: DynamicMessage) throws -> DynamicMessage {
    let typeUrl = "type.googleapis.com/\(inner.descriptor.fullName)"
    let binaryData = try BinarySerializer().serialize(inner)
    let anyDesc = makeAnyDescriptor()
    var anyMsg = DynamicMessage(descriptor: anyDesc)
    try anyMsg.set(typeUrl, forField: 1)
    try anyMsg.set(binaryData, forField: 2)
    return anyMsg
  }

  private func makeRegistry(with file: FileDescriptor) async throws -> TypeRegistry {
    return try await TypeRegistry(fileDescriptors: [file])
  }

  private func canonicalSerializer(registry: TypeRegistry) -> JSONSerializer {
    JSONSerializer(
      options: JSONSerializationOptions(
        useCanonicalWellKnownTypeEncoding: true,
        typeRegistry: registry
      )
    )
  }

  private func deserializer(registry: TypeRegistry) -> JSONDeserializer {
    JSONDeserializer(options: JSONDeserializationOptions(typeRegistry: registry))
  }

  // MARK: - Encoder tests

  func test_serialize_any_regularMessage_expandsFields() async throws {
    let (pingFile, _) = makePingFileAndDescriptor()
    let registry = try await makeRegistry(with: pingFile)
    let ping = try makePingMessage(id: 42)
    let anyMsg = try packIntoAny(ping)

    let data = try await canonicalSerializer(registry: registry).serialize(anyMsg)
    let json = try XCTUnwrap(
      try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any]
    )

    XCTAssertEqual(json["@type"] as? String, "type.googleapis.com/test.Ping")
    XCTAssertEqual(json["id"] as? Int, 42)
    XCTAssertNil(json["typeUrl"])
    XCTAssertNil(json["value"])
  }

  func test_serialize_any_wktValue_usesValueKey() async throws {
    // Pack a google.protobuf.StringValue inside Any
    let strDesc = MessageDescriptor(name: "StringValue", fullName: WellKnownTypeNames.stringValue)
    _ = DynamicMessage(descriptor: strDesc)
    // StringValue wraps a string in field 1, but for Any packing we binary-serialize it.
    // We'll use a regular string field since the WKT canonical encoder handles it.
    // Actually we need a proper descriptor with field 1 as string:
    var fileWKT = FileDescriptor(name: "google/protobuf/wrappers.proto", package: "google.protobuf")
    var strDesc2 = MessageDescriptor(name: "StringValue", parent: fileWKT)
    strDesc2.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    fileWKT.addMessage(strDesc2)
    let actualStrDesc = fileWKT.messages["StringValue"]!

    var innerMsg = DynamicMessage(descriptor: actualStrDesc)
    try innerMsg.set("hello", forField: 1)

    let typeUrl = "type.googleapis.com/\(WellKnownTypeNames.stringValue)"
    let binaryData = try BinarySerializer().serialize(innerMsg)
    let anyDesc = makeAnyDescriptor()
    var anyMsg = DynamicMessage(descriptor: anyDesc)
    try anyMsg.set(typeUrl, forField: 1)
    try anyMsg.set(binaryData, forField: 2)

    let registry = try await TypeRegistry(fileDescriptors: [fileWKT])
    let data = try await canonicalSerializer(registry: registry).serialize(anyMsg)
    let json = try XCTUnwrap(
      try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any]
    )

    XCTAssertEqual(json["@type"] as? String, typeUrl)
    // WKT StringValue canonical value is the string itself
    XCTAssertEqual(json["value"] as? String, "hello")
  }

  func test_serialize_any_unknownType_fallsBackToStandard() async throws {
    // Type not in registry → standard field-by-field fallback
    let registry = TypeRegistry()
    let ping = try makePingMessage(id: 7)
    let anyMsg = try packIntoAny(ping)

    let data = try await canonicalSerializer(registry: registry).serialize(anyMsg)
    let json = try XCTUnwrap(
      try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any]
    )

    // Falls back to standard encoding: field name "type_url" (no camelCase since no jsonName set), no @type
    XCTAssertNotNil(json["type_url"])
    XCTAssertNil(json["@type"])
  }

  // MARK: - Decoder tests

  func test_deserialize_any_regularMessage_fromExpandedFields() async throws {
    let (pingFile, _) = makePingFileAndDescriptor()
    let registry = try await makeRegistry(with: pingFile)

    let jsonStr = #"{"@type":"type.googleapis.com/test.Ping","id":42}"#
    let data = jsonStr.data(using: .utf8)!
    let anyDesc = makeAnyDescriptor()

    let msg = try await deserializer(registry: registry).deserialize(data, using: anyDesc)
    let typeUrl = try XCTUnwrap(try msg.get(forField: 1) as? String)
    let valueBytes = try XCTUnwrap(try msg.get(forField: 2) as? Data)

    XCTAssertEqual(typeUrl, "type.googleapis.com/test.Ping")
    XCTAssertFalse(valueBytes.isEmpty)

    // Verify the packed message decodes back to id=42
    let (_, pingDesc) = makePingFileAndDescriptor()
    let unpacked = try await BinaryDeserializer(options: DeserializationOptions(typeRegistry: TypeRegistry()))
      .deserialize(
        valueBytes,
        using: pingDesc
      )
    XCTAssertEqual(try unpacked.get(forField: 1) as? Int32, 42)
  }

  func test_deserialize_any_wktValue_fromValueKey() async throws {
    var fileWKT = FileDescriptor(name: "google/protobuf/wrappers.proto", package: "google.protobuf")
    var strDesc = MessageDescriptor(name: "StringValue", parent: fileWKT)
    strDesc.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    fileWKT.addMessage(strDesc)
    let registry = try await TypeRegistry(fileDescriptors: [fileWKT])

    let jsonStr =
      #"{"@type":"type.googleapis.com/google.protobuf.StringValue","value":"hello"}"#
    let data = jsonStr.data(using: .utf8)!
    let anyDesc = makeAnyDescriptor()

    let msg = try await deserializer(registry: registry).deserialize(data, using: anyDesc)
    let typeUrl = try XCTUnwrap(try msg.get(forField: 1) as? String)
    let valueBytes = try XCTUnwrap(try msg.get(forField: 2) as? Data)

    XCTAssertEqual(typeUrl, "type.googleapis.com/google.protobuf.StringValue")

    let actualStrDesc = fileWKT.messages["StringValue"]!
    let unpacked = try await BinaryDeserializer(options: DeserializationOptions(typeRegistry: TypeRegistry()))
      .deserialize(
        valueBytes,
        using: actualStrDesc
      )
    XCTAssertEqual(try unpacked.get(forField: 1) as? String, "hello")
  }

  // MARK: - Round-trip tests

  func test_roundTrip_any_regularMessage_preservesData() async throws {
    let (pingFile, pingDesc) = makePingFileAndDescriptor()
    let registry = try await makeRegistry(with: pingFile)

    let ping = try makePingMessage(id: 99)
    let anyMsg = try packIntoAny(ping)
    let anyDesc = makeAnyDescriptor()

    let serialized = try await canonicalSerializer(registry: registry).serialize(anyMsg)
    let roundTripped = try await deserializer(registry: registry).deserialize(serialized, using: anyDesc)

    let valueBytes = try XCTUnwrap(try roundTripped.get(forField: 2) as? Data)
    let unpacked = try await BinaryDeserializer(options: DeserializationOptions(typeRegistry: TypeRegistry()))
      .deserialize(
        valueBytes,
        using: pingDesc
      )
    XCTAssertEqual(try unpacked.get(forField: 1) as? Int32, 99)
  }

  func test_roundTrip_any_wktMessage_preservesData() async throws {
    var fileWKT = FileDescriptor(name: "google/protobuf/wrappers.proto", package: "google.protobuf")
    var strDesc = MessageDescriptor(name: "StringValue", parent: fileWKT)
    strDesc.addField(FieldDescriptor(name: "value", number: 1, type: .string))
    fileWKT.addMessage(strDesc)
    let registry = try await TypeRegistry(fileDescriptors: [fileWKT])
    let actualStrDesc = fileWKT.messages["StringValue"]!

    var innerMsg = DynamicMessage(descriptor: actualStrDesc)
    try innerMsg.set("round-trip", forField: 1)

    let typeUrl = "type.googleapis.com/\(WellKnownTypeNames.stringValue)"
    let binaryData = try BinarySerializer().serialize(innerMsg)
    let anyDesc = makeAnyDescriptor()
    var anyMsg = DynamicMessage(descriptor: anyDesc)
    try anyMsg.set(typeUrl, forField: 1)
    try anyMsg.set(binaryData, forField: 2)

    let serialized = try await canonicalSerializer(registry: registry).serialize(anyMsg)
    let roundTripped = try await deserializer(registry: registry).deserialize(serialized, using: anyDesc)

    let valueBytes = try XCTUnwrap(try roundTripped.get(forField: 2) as? Data)
    let unpacked = try await BinaryDeserializer(options: DeserializationOptions(typeRegistry: TypeRegistry()))
      .deserialize(
        valueBytes,
        using: actualStrDesc
      )
    XCTAssertEqual(try unpacked.get(forField: 1) as? String, "round-trip")
  }
}
