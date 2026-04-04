//
// DeserializationOptionsTests.swift
// SwiftProtoReflect
//
// Created: 2026-04-04
//

import XCTest

@testable import SwiftProtoReflect

final class DeserializationOptionsTests: XCTestCase {

  func test_init_defaultOptions_typeRegistryIsNil() {
    let options = DeserializationOptions()
    XCTAssertNil(options.typeRegistry)
  }

  func test_init_withTypeRegistry_storesRegistry() {
    let registry = TypeRegistry()
    let options = DeserializationOptions(typeRegistry: registry)
    XCTAssertNotNil(options.typeRegistry)
  }

  func test_init_preserveUnknownFieldsDefault_isTrue() {
    let options = DeserializationOptions()
    XCTAssertTrue(options.preserveUnknownFields)
  }

  func test_init_strictUTF8ValidationDefault_isTrue() {
    let options = DeserializationOptions()
    XCTAssertTrue(options.strictUTF8Validation)
  }
}
