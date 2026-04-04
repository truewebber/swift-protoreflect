//
// ErrorHandlingTests.swift
// SwiftProtoReflect
//
// Tests for error handling in Protocol Buffers operations.
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class ErrorHandlingTests: XCTestCase {

  // MARK: - Incorrect message descriptors

  func test_setField_unknownFieldName_throws() {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    var msg = MessageFactory().createMessage(from: desc)

    XCTAssertThrowsError(try msg.set(Int32(1), forField: "nonexistent"))
  }

  func test_getField_unknownFieldName_throws() {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    let msg = MessageFactory().createMessage(from: desc)

    XCTAssertThrowsError(try msg.get(forField: "nonexistent"))
  }

  // MARK: - Incorrect binary data

  func test_deserialize_emptyData_returnsEmptyMessage() throws {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    let msg = try BinaryDeserializer(options: .init(typeRegistry: TypeRegistry())).deserialize(Data(), using: desc)
    XCTAssertNil(try msg.get(forField: "id"))
  }

  func test_deserialize_truncatedVarint_throws() {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    let truncated = Data([0x08, 0x80])
    XCTAssertThrowsError(
      try BinaryDeserializer(options: .init(typeRegistry: TypeRegistry())).deserialize(truncated, using: desc)
    )
  }

  func test_deserialize_truncatedFixed32_throws() {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "val", number: 1, type: .fixed32))

    let truncated = Data([0x0D, 0x01, 0x02])
    XCTAssertThrowsError(
      try BinaryDeserializer(options: .init(typeRegistry: TypeRegistry())).deserialize(truncated, using: desc)
    )
  }

  func test_deserialize_truncatedLengthDelimited_throws() {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "name", number: 1, type: .string))

    let truncated = Data([0x0A, 0x05, 0x41])
    XCTAssertThrowsError(
      try BinaryDeserializer(options: .init(typeRegistry: TypeRegistry())).deserialize(truncated, using: desc)
    )
  }

  // MARK: - Incorrect JSON data

  func test_deserializeJSON_invalidJSON_throws() {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    let badJSON = Data("not json".utf8)
    XCTAssertThrowsError(
      try JSONDeserializer(options: .init(typeRegistry: TypeRegistry())).deserialize(badJSON, using: desc)
    )
  }

  func test_deserializeJSON_wrongType_throws() {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    let json = Data("{\"id\": \"not_a_number\"}".utf8)
    XCTAssertThrowsError(
      try JSONDeserializer(options: .init(typeRegistry: TypeRegistry())).deserialize(json, using: desc)
    )
  }

  func test_deserializeJSON_emptyObject_returnsEmptyMessage() throws {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    let json = Data("{}".utf8)
    let msg = try JSONDeserializer(options: .init(typeRegistry: TypeRegistry())).deserialize(json, using: desc)
    XCTAssertNil(try msg.get(forField: "id"))
  }

  // MARK: - Type mismatch on set

  func test_setField_typeMismatch_throws() {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    var msg = MessageFactory().createMessage(from: desc)

    XCTAssertThrowsError(try msg.set("not_int", forField: "id"))
  }

  // MARK: - Oversized varint

  func test_deserialize_invalidWireType_throws() {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    let badWireType = Data([0x0F])
    XCTAssertThrowsError(
      try BinaryDeserializer(options: .init(typeRegistry: TypeRegistry())).deserialize(badWireType, using: desc)
    )
  }

  // MARK: - Serialization of unsupported type

  func test_serialize_groupField_succeeds() throws {
    var innerDesc = MessageDescriptor(name: "G", fullName: "test.G")
    innerDesc.addField(FieldDescriptor(name: "v", number: 1, type: .int32))

    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(
      FieldDescriptor(name: "g", number: 1, type: .group, typeName: "test.G")
    )
    desc.addNestedMessage(innerDesc)

    var msg = DynamicMessage(descriptor: desc)
    var group = DynamicMessage(descriptor: innerDesc)
    try group.set(Int32(1), forField: "v")
    try msg.set(group, forField: 1)

    let data = try BinarySerializer().serialize(msg)
    XCTAssertFalse(data.isEmpty)
  }
}
