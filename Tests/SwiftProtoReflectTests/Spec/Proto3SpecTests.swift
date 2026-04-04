//
// Proto3SpecTests.swift
// SwiftProtoReflect
//
// Tests verifying proto3 specification compliance.
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class Proto3SpecTests: XCTestCase {

  // MARK: - Helpers

  private func makeScalarDescriptor() -> MessageDescriptor {
    var desc = MessageDescriptor(name: "ScalarMsg", fullName: "test.ScalarMsg")
    desc.addField(FieldDescriptor(name: "f_int32", number: 1, type: .int32))
    desc.addField(FieldDescriptor(name: "f_int64", number: 2, type: .int64))
    desc.addField(FieldDescriptor(name: "f_uint32", number: 3, type: .uint32))
    desc.addField(FieldDescriptor(name: "f_uint64", number: 4, type: .uint64))
    desc.addField(FieldDescriptor(name: "f_bool", number: 5, type: .bool))
    desc.addField(FieldDescriptor(name: "f_string", number: 6, type: .string))
    desc.addField(FieldDescriptor(name: "f_bytes", number: 7, type: .bytes))
    desc.addField(FieldDescriptor(name: "f_double", number: 8, type: .double))
    desc.addField(FieldDescriptor(name: "f_float", number: 9, type: .float))
    return desc
  }

  // MARK: - Scalar defaults

  func test_scalarDefaults_allTypesZeroValue() throws {
    let desc = makeScalarDescriptor()
    let msg = MessageFactory().createMessage(from: desc)

    XCTAssertNil(try msg.get(forField: "f_int32"))
    XCTAssertNil(try msg.get(forField: "f_int64"))
    XCTAssertNil(try msg.get(forField: "f_uint32"))
    XCTAssertNil(try msg.get(forField: "f_uint64"))
    XCTAssertNil(try msg.get(forField: "f_bool"))
    XCTAssertNil(try msg.get(forField: "f_string"))
    XCTAssertNil(try msg.get(forField: "f_bytes"))
    XCTAssertNil(try msg.get(forField: "f_double"))
    XCTAssertNil(try msg.get(forField: "f_float"))
  }

  // MARK: - No required fields in proto3

  func test_noRequiredFields_proto3() {
    let factory = MessageFactory()
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "x", number: 1, type: .int32, isRequired: true))
    let msg = factory.createMessage(from: desc)

    let result = factory.validate(msg)
    XCTAssertTrue(result.isValid, "Proto3 must not enforce required fields")
  }

  func test_requiredField_proto2_enforced() {
    let factory = MessageFactory()
    var desc = MessageDescriptor(name: "M", fullName: "test.M", syntax: "proto2")
    desc.addField(FieldDescriptor(name: "x", number: 1, type: .int32, isRequired: true))
    let msg = factory.createMessage(from: desc)

    let result = factory.validate(msg)
    XCTAssertFalse(result.isValid, "Proto2 must enforce required fields")
  }

  // MARK: - Enum first value zero

  func test_enumFirstValueZero() {
    var e = EnumDescriptor(name: "Status", fullName: "test.Status")
    e.addValue(.init(name: "UNKNOWN", number: 0))
    e.addValue(.init(name: "ACTIVE", number: 1))
    let errors = e.validateProto3()
    XCTAssertTrue(errors.isEmpty)
  }

  func test_enumNoZeroValue_validationFails() {
    var e = EnumDescriptor(name: "Status", fullName: "test.Status")
    e.addValue(.init(name: "ACTIVE", number: 1))
    let errors = e.validateProto3()
    XCTAssertFalse(errors.isEmpty)
  }

  // MARK: - Unknown fields preserved

  func test_unknownFields_preserved() throws {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))

    let factory = MessageFactory()
    var msg = factory.createMessage(from: desc)
    try msg.set(Int32(1), forField: "id")
    let unknownData = Data([0x10, 0x2A])
    msg.setUnknownFields(unknownData)

    let serializer = BinarySerializer()
    let data = try serializer.serialize(msg)

    let deserializer = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))
    let decoded = try deserializer.deserialize(data, using: desc)

    XCTAssertEqual(decoded.unknownFields, unknownData)
  }

  // MARK: - JSON canonical encoding

  func test_jsonCanonicalEncoding_int64AsString() throws {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "val", number: 1, type: .int64))

    let factory = MessageFactory()
    var msg = factory.createMessage(from: desc)
    try msg.set(Int64(9_007_199_254_740_993), forField: "val")

    let serializer = JSONSerializer(options: .init(typeRegistry: TypeRegistry()))
    let json = try serializer.serializeToJSONObject(msg)
    XCTAssertTrue(json["val"] is String, "int64 must be serialized as string in JSON")
  }

  func test_jsonCanonicalEncoding_bytesAsBase64() throws {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(FieldDescriptor(name: "data", number: 1, type: .bytes))

    let factory = MessageFactory()
    var msg = factory.createMessage(from: desc)
    try msg.set("Hello".data(using: .utf8)!, forField: "data")

    let serializer = JSONSerializer(options: .init(typeRegistry: TypeRegistry()))
    let json = try serializer.serializeToJSONObject(msg)
    XCTAssertEqual(json["data"] as? String, "SGVsbG8=")
  }

  func test_jsonCanonicalEncoding_enumAsName() throws {
    var statusEnum = EnumDescriptor(name: "Status", fullName: "test.Status")
    statusEnum.addValue(.init(name: "UNKNOWN", number: 0))
    statusEnum.addValue(.init(name: "ACTIVE", number: 1))

    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(
      FieldDescriptor(name: "status", number: 1, type: .enum, typeName: "test.Status")
    )
    desc.addNestedEnum(statusEnum)

    let factory = MessageFactory()
    var msg = factory.createMessage(from: desc)
    try msg.set(Int32(1), forField: "status")

    let serializer = JSONSerializer(options: .init(typeRegistry: TypeRegistry()))
    let json = try serializer.serializeToJSONObject(msg)
    XCTAssertEqual(json["status"] as? String, "ACTIVE")
  }

  // MARK: - Proto3 optional presence tracking

  func test_proto3Optional_presenceTracking() throws {
    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(
      FieldDescriptor(name: "opt_val", number: 1, type: .int32, proto3Optional: true)
    )

    let factory = MessageFactory()
    var msg = factory.createMessage(from: desc)

    XCTAssertNil(try msg.get(forField: "opt_val"), "Unset proto3 optional must return nil")

    try msg.set(Int32(0), forField: "opt_val")
    XCTAssertEqual(
      try msg.get(forField: "opt_val") as? Int32,
      0,
      "Proto3 optional set to 0 must be distinguishable from unset"
    )
  }

  // MARK: - FileDescriptor syntax

  func test_fileDescriptorSyntax_defaultProto3() {
    let fd = FileDescriptor(name: "test.proto", package: "test")
    XCTAssertEqual(fd.syntax, "proto3")
  }

  func test_fileDescriptorSyntax_emptyIsProto2() {
    let fd = FileDescriptor(name: "test.proto", package: "test", syntax: "")
    XCTAssertEqual(fd.syntax, "proto2")
  }
}
