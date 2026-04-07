//
// Proto2RegistryTests.swift
// SwiftProtoReflect
//
// Tests for proto2-specific registry features:
// syntaxForType, extension descriptor lookup.
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class Proto2RegistryTests: XCTestCase {

  // MARK: - syntaxForType

  func test_syntaxForType_registeredProto2_returnsProto2() async throws {
    let registry = TypeRegistry()
    let desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    try await registry.registerMessage(desc)

    let _asyncResult118 = await registry.syntaxForType("test.Msg")
    XCTAssertEqual(_asyncResult118, "proto2")
  }

  func test_syntaxForType_registeredProto3_returnsProto3() async throws {
    let registry = TypeRegistry()
    let desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto3")
    try await registry.registerMessage(desc)

    let _asyncResult119 = await registry.syntaxForType("test.Msg")
    XCTAssertEqual(_asyncResult119, "proto3")
  }

  func test_syntaxForType_unknownType_returnsNil() async throws {
    let registry = TypeRegistry()
    let _asyncResult120 = await registry.syntaxForType("unknown.Type")
    XCTAssertNil(_asyncResult120)
  }

  // MARK: - findExtension

  func test_findExtension_existingExtension_returnsField() async throws {
    let registry = TypeRegistry()
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    desc.addExtensionRange(ExtensionRange(start: 100, end: 200))
    desc.addExtension(FieldDescriptor(name: "ext_field", number: 100, type: .string))
    try await registry.registerMessage(desc)

    let ext = await registry.findExtension(forMessage: "test.Msg", fieldNumber: 100)
    XCTAssertNotNil(ext)
    XCTAssertEqual(ext?.name, "ext_field")
    XCTAssertEqual(ext?.type, .string)
  }

  func test_findExtension_nonExistentNumber_returnsNil() async throws {
    let registry = TypeRegistry()
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    desc.addExtensionRange(ExtensionRange(start: 100, end: 200))
    desc.addExtension(FieldDescriptor(name: "ext_field", number: 100, type: .string))
    try await registry.registerMessage(desc)

    let _asyncResult121 = await registry.findExtension(forMessage: "test.Msg", fieldNumber: 150)
    XCTAssertNil(_asyncResult121)
  }

  func test_findExtension_unknownMessage_returnsNil() async throws {
    let registry = TypeRegistry()
    let _asyncResult122 = await registry.findExtension(forMessage: "unknown.Msg", fieldNumber: 100)
    XCTAssertNil(_asyncResult122)
  }
}
