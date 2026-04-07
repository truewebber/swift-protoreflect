//
// SchemaEvolutionTests.swift
// SwiftProtoReflect
//
// Tests for verifying compatibility during Protocol Buffers schema evolution.
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class SchemaEvolutionTests: XCTestCase {

  // MARK: - Helpers

  private let serializer = BinarySerializer()
  private let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
  private let factory = MessageFactory()

  // MARK: - Add new field

  func test_addNewField_oldDataStillDeserializes() async throws {
    var oldDesc = MessageDescriptor(name: "M", fullName: "test.M")
    oldDesc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    var oldMsg = factory.createMessage(from: oldDesc)
    try oldMsg.set(Int32(42), forField: "id")
    let data = try serializer.serialize(oldMsg)

    var newDesc = MessageDescriptor(name: "M", fullName: "test.M")
    newDesc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    newDesc.addField(FieldDescriptor(name: "name", number: 2, type: .string))

    let newMsg = try await deserializer.deserialize(data, using: newDesc)
    XCTAssertEqual(try newMsg.get(forField: "id") as? Int32, 42)
    XCTAssertNil(try newMsg.get(forField: "name"))
  }

  // MARK: - Remove field

  func test_removeField_newDataIgnoresOldField() async throws {
    var oldDesc = MessageDescriptor(name: "M", fullName: "test.M")
    oldDesc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    oldDesc.addField(FieldDescriptor(name: "name", number: 2, type: .string))

    var oldMsg = factory.createMessage(from: oldDesc)
    try oldMsg.set(Int32(1), forField: "id")
    try oldMsg.set("Alice", forField: "name")
    let data = try serializer.serialize(oldMsg)

    var newDesc = MessageDescriptor(name: "M", fullName: "test.M")
    newDesc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    let newMsg = try await deserializer.deserialize(data, using: newDesc)
    XCTAssertEqual(try newMsg.get(forField: "id") as? Int32, 1)
    XCTAssertFalse(newMsg.unknownFields.isEmpty, "Removed field should be preserved as unknown")
  }

  // MARK: - Rename field

  func test_renameField_binaryUnaffected() async throws {
    var oldDesc = MessageDescriptor(name: "M", fullName: "test.M")
    oldDesc.addField(FieldDescriptor(name: "user_name", number: 1, type: .string))

    var oldMsg = factory.createMessage(from: oldDesc)
    try oldMsg.set("Alice", forField: "user_name")
    let data = try serializer.serialize(oldMsg)

    var newDesc = MessageDescriptor(name: "M", fullName: "test.M")
    newDesc.addField(FieldDescriptor(name: "display_name", number: 1, type: .string))

    let newMsg = try await deserializer.deserialize(data, using: newDesc)
    XCTAssertEqual(
      try newMsg.get(forField: "display_name") as? String,
      "Alice",
      "Field number unchanged → binary works regardless of name"
    )
  }

  // MARK: - Add enum value

  func test_addEnumValue_oldClientPreservesUnknown() async throws {
    var statusEnum = EnumDescriptor(name: "Status", fullName: "test.Status")
    statusEnum.addValue(.init(name: "UNKNOWN", number: 0))
    statusEnum.addValue(.init(name: "ACTIVE", number: 1))
    statusEnum.addValue(.init(name: "DELETED", number: 2))

    var writerDesc = MessageDescriptor(name: "M", fullName: "test.M")
    writerDesc.addField(
      FieldDescriptor(name: "status", number: 1, type: .enum, typeName: "test.Status")
    )
    writerDesc.addNestedEnum(statusEnum)

    var msg = factory.createMessage(from: writerDesc)
    try msg.set(Int32(2), forField: "status")
    let data = try serializer.serialize(msg)

    var oldStatusEnum = EnumDescriptor(name: "Status", fullName: "test.Status")
    oldStatusEnum.addValue(.init(name: "UNKNOWN", number: 0))
    oldStatusEnum.addValue(.init(name: "ACTIVE", number: 1))

    var readerDesc = MessageDescriptor(name: "M", fullName: "test.M")
    readerDesc.addField(
      FieldDescriptor(name: "status", number: 1, type: .enum, typeName: "test.Status")
    )
    readerDesc.addNestedEnum(oldStatusEnum)

    let decoded = try await deserializer.deserialize(data, using: readerDesc)
    let val = try decoded.get(forField: "status") as? Int32
    XCTAssertEqual(val, 2, "Unknown enum number should be preserved as-is")
  }

  // MARK: - Add map field

  func test_addMapField_backwardCompatible() async throws {
    var oldDesc = MessageDescriptor(name: "M", fullName: "test.M")
    oldDesc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    var oldMsg = factory.createMessage(from: oldDesc)
    try oldMsg.set(Int32(5), forField: "id")
    let data = try serializer.serialize(oldMsg)

    var newDesc = MessageDescriptor(name: "M", fullName: "test.M")
    newDesc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    newDesc.addField(
      FieldDescriptor(
        name: "tags",
        number: 2,
        type: .message,
        typeName: "test.M.TagsEntry",
        isRepeated: true,
        mapEntryInfo: MapEntryInfo(
          keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
          valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .string)
        )
      )
    )

    let newMsg = try await deserializer.deserialize(data, using: newDesc)
    XCTAssertEqual(try newMsg.get(forField: "id") as? Int32, 5)
  }

  // MARK: - Unknown fields survive re-serialization

  func test_unknownFields_survivesRoundtrip() async throws {
    var oldDesc = MessageDescriptor(name: "M", fullName: "test.M")
    oldDesc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    oldDesc.addField(FieldDescriptor(name: "name", number: 2, type: .string))

    var oldMsg = factory.createMessage(from: oldDesc)
    try oldMsg.set(Int32(1), forField: "id")
    try oldMsg.set("Alice", forField: "name")
    let data = try serializer.serialize(oldMsg)

    var newDesc = MessageDescriptor(name: "M", fullName: "test.M")
    newDesc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    let intermediate = try await deserializer.deserialize(data, using: newDesc)
    let reserializedData = try serializer.serialize(intermediate)

    let restored = try await deserializer.deserialize(reserializedData, using: oldDesc)
    XCTAssertEqual(try restored.get(forField: "id") as? Int32, 1)
    XCTAssertEqual(try restored.get(forField: "name") as? String, "Alice")
  }
}
