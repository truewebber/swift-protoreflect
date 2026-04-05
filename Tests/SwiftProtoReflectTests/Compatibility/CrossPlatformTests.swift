//
// CrossPlatformTests.swift
// SwiftProtoReflect
//
// Tests verifying cross-platform compatibility of serialized Protocol Buffers messages.
// These tests use known reference payloads that any compliant protobuf implementation
// would produce for the same schema and values.
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class CrossPlatformTests: XCTestCase {

  // MARK: - Helpers

  private let serializer = BinarySerializer()
  private let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))

  // MARK: - Deterministic field ordering

  func test_fieldsSortedByNumber() throws {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "z", number: 3, type: .int32))
    desc.addField(FieldDescriptor(name: "a", number: 1, type: .int32))
    desc.addField(FieldDescriptor(name: "m", number: 2, type: .int32))

    var msg = MessageFactory().createMessage(from: desc)
    try msg.set(Int32(10), forField: "a")
    try msg.set(Int32(20), forField: "m")
    try msg.set(Int32(30), forField: "z")

    let data = try serializer.serialize(msg)
    let decoded = try deserializer.deserialize(data, using: desc)
    XCTAssertEqual(try decoded.get(forField: "a") as? Int32, 10)
    XCTAssertEqual(try decoded.get(forField: "m") as? Int32, 20)
    XCTAssertEqual(try decoded.get(forField: "z") as? Int32, 30)

    XCTAssertEqual(data[0] >> 3, 1, "First field on wire should be number 1")
  }

  // MARK: - Reference payloads from other implementations

  func test_deserialize_referencePayload_int32() throws {
    // protoc: message M { int32 a = 1; } with a = 150
    // Canonical output: 08 96 01
    let reference = Data([0x08, 0x96, 0x01])

    var desc = MessageDescriptor(name: "M", fullName: "ref.M")
    desc.addField(FieldDescriptor(name: "a", number: 1, type: .int32))

    let msg = try deserializer.deserialize(reference, using: desc)
    XCTAssertEqual(try msg.get(forField: "a") as? Int32, 150)
  }

  func test_deserialize_referencePayload_string() throws {
    // protoc: message M { string s = 2; } with s = "testing"
    // Canonical output: 12 07 74 65 73 74 69 6e 67
    let reference = Data([0x12, 0x07, 0x74, 0x65, 0x73, 0x74, 0x69, 0x6E, 0x67])

    var desc = MessageDescriptor(name: "M", fullName: "ref.M")
    desc.addField(FieldDescriptor(name: "s", number: 2, type: .string))

    let msg = try deserializer.deserialize(reference, using: desc)
    XCTAssertEqual(try msg.get(forField: "s") as? String, "testing")
  }

  func test_deserialize_referencePayload_negativeSint32() throws {
    // protoc: message M { sint32 v = 1; } with v = -1
    // zigzag(-1) = 1, then varint 1 → 0x01
    let reference = Data([0x08, 0x01])

    var desc = MessageDescriptor(name: "M", fullName: "ref.M")
    desc.addField(FieldDescriptor(name: "v", number: 1, type: .sint32))

    let msg = try deserializer.deserialize(reference, using: desc)
    XCTAssertEqual(try msg.get(forField: "v") as? Int32, -1)
  }

  // MARK: - Empty message wire identity

  func test_emptyMessage_emptyWire() throws {
    let desc = MessageDescriptor(name: "M", fullName: "test.M")
    let msg = MessageFactory().createMessage(from: desc)
    let data = try serializer.serialize(msg)
    XCTAssertTrue(data.isEmpty, "All implementations encode empty message as zero bytes")
  }

  // MARK: - JSON cross-platform

  func test_jsonRoundtrip_preservesValues() throws {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    desc.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    desc.addField(FieldDescriptor(name: "active", number: 3, type: .bool))

    var msg = MessageFactory().createMessage(from: desc)
    try msg.set(Int32(42), forField: "id")
    try msg.set("Alice", forField: "name")
    try msg.set(true, forField: "active")

    let jsonData = try JSONSerializer(options: .init(typeRegistry: TypeRegistry())).serialize(msg)
    let restored = try JSONDeserializer(options: .init(typeRegistry: TypeRegistry())).deserialize(jsonData, using: desc)

    XCTAssertEqual(try restored.get(forField: "id") as? Int32, 42)
    XCTAssertEqual(try restored.get(forField: "name") as? String, "Alice")
    XCTAssertEqual(try restored.get(forField: "active") as? Bool, true)
  }
}
