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

  func test_syntaxForType_registeredProto2_returnsProto2() throws {
    let registry = TypeRegistry()
    let desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    try registry.registerMessage(desc)

    XCTAssertEqual(registry.syntaxForType("test.Msg"), "proto2")
  }

  func test_syntaxForType_registeredProto3_returnsProto3() throws {
    let registry = TypeRegistry()
    let desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto3")
    try registry.registerMessage(desc)

    XCTAssertEqual(registry.syntaxForType("test.Msg"), "proto3")
  }

  func test_syntaxForType_unknownType_returnsNil() {
    let registry = TypeRegistry()
    XCTAssertNil(registry.syntaxForType("unknown.Type"))
  }

  // MARK: - findExtension

  func test_findExtension_existingExtension_returnsField() throws {
    let registry = TypeRegistry()
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    desc.addExtensionRange(ExtensionRange(start: 100, end: 200))
    desc.addExtension(FieldDescriptor(name: "ext_field", number: 100, type: .string))
    try registry.registerMessage(desc)

    let ext = registry.findExtension(forMessage: "test.Msg", fieldNumber: 100)
    XCTAssertNotNil(ext)
    XCTAssertEqual(ext?.name, "ext_field")
    XCTAssertEqual(ext?.type, .string)
  }

  func test_findExtension_nonExistentNumber_returnsNil() throws {
    let registry = TypeRegistry()
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    desc.addExtensionRange(ExtensionRange(start: 100, end: 200))
    desc.addExtension(FieldDescriptor(name: "ext_field", number: 100, type: .string))
    try registry.registerMessage(desc)

    XCTAssertNil(registry.findExtension(forMessage: "test.Msg", fieldNumber: 150))
  }

  func test_findExtension_unknownMessage_returnsNil() {
    let registry = TypeRegistry()
    XCTAssertNil(registry.findExtension(forMessage: "unknown.Msg", fieldNumber: 100))
  }
}
