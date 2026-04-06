//
// ValidationTests.swift
// SwiftProtoReflect
//
// Tests for validating proto3 format rules.
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class ValidationTests: XCTestCase {

  // MARK: - Proto3 must not have required fields

  func test_validate_proto3_ignoresRequired() async throws {
    let factory = MessageFactory()
    var desc = MessageDescriptor(name: "M", fullName: "test.M", syntax: "proto3")
    desc.addField(
      FieldDescriptor(name: "name", number: 1, type: .string, isRequired: true)
    )
    let msg = factory.createMessage(from: desc)

    let result = factory.validate(msg)
    XCTAssertTrue(result.isValid, "Proto3 must ignore isRequired flag")
  }

  func test_validate_proto2_enforcesRequired() async throws {
    let factory = MessageFactory()
    var desc = MessageDescriptor(name: "M", fullName: "test.M", syntax: "proto2")
    desc.addField(
      FieldDescriptor(name: "name", number: 1, type: .string, isRequired: true)
    )
    let msg = factory.createMessage(from: desc)

    let result = factory.validate(msg)
    XCTAssertFalse(result.isValid, "Proto2 must enforce required fields")
  }

  // MARK: - Proto3 optional keyword

  func test_validate_proto3Optional_unset_isValid() async throws {
    let factory = MessageFactory()
    var desc = MessageDescriptor(name: "M", fullName: "test.M", syntax: "proto3")
    desc.addField(
      FieldDescriptor(name: "val", number: 1, type: .int32, proto3Optional: true)
    )
    let msg = factory.createMessage(from: desc)

    let result = factory.validate(msg)
    XCTAssertTrue(result.isValid, "Unset proto3 optional is valid")
  }

  // MARK: - Enum validation rules

  func test_validate_enumFirstValueZero_valid() async throws {
    var e = EnumDescriptor(name: "E", fullName: "test.E")
    e.addValue(.init(name: "DEFAULT", number: 0))
    e.addValue(.init(name: "ONE", number: 1))
    XCTAssertTrue(e.validateProto3().isEmpty)
  }

  func test_validate_enumNoZeroValue_invalid() async throws {
    var e = EnumDescriptor(name: "E", fullName: "test.E")
    e.addValue(.init(name: "ONE", number: 1))
    XCTAssertFalse(e.validateProto3().isEmpty)
  }

  func test_validate_enumEmpty_invalid() async throws {
    let e = EnumDescriptor(name: "E", fullName: "test.E")
    let errors = e.validateProto3()
    XCTAssertFalse(errors.isEmpty, "Empty enum should fail proto3 validation")
  }

  // MARK: - FileDescriptor syntax field

  func test_fileDescriptor_syntaxProto3() async throws {
    let fd = FileDescriptor(name: "test.proto", package: "test", syntax: "proto3")
    XCTAssertEqual(fd.syntax, "proto3")
  }

  func test_fileDescriptor_syntaxProto2() async throws {
    let fd = FileDescriptor(name: "test.proto", package: "test", syntax: "proto2")
    XCTAssertEqual(fd.syntax, "proto2")
  }

  func test_fileDescriptor_emptySyntax_normalisedToProto2() async throws {
    let fd = FileDescriptor(name: "test.proto", package: "test", syntax: "")
    XCTAssertEqual(fd.syntax, "proto2")
  }

  // MARK: - Field group type deprecated

  func test_validate_groupField_serializesSuccessfully() async throws {
    var innerDesc = MessageDescriptor(name: "G", fullName: "test.G")
    innerDesc.addField(FieldDescriptor(name: "v", number: 1, type: .int32))

    var desc = MessageDescriptor(name: "M", fullName: "test.M")
    desc.addField(
      FieldDescriptor(name: "g", number: 1, type: .group, typeName: "test.G")
    )
    desc.addNestedMessage(innerDesc)

    var msg = DynamicMessage(descriptor: desc)
    var group = DynamicMessage(descriptor: innerDesc)
    try group.set(Int32(42), forField: "v")
    try msg.set(group, forField: 1)

    let data = try BinarySerializer().serialize(msg)
    XCTAssertFalse(data.isEmpty)
  }
}
