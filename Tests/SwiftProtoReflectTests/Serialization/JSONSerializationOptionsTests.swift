//
// JSONSerializationOptionsTests.swift
// SwiftProtoReflect
//
// Created: 2026-04-05
//

import XCTest

@testable import SwiftProtoReflect

final class JSONSerializationOptionsTests: XCTestCase {

  func test_options_defaultCanonicalWKTEncoding_isTrue() async throws {
    let options = JSONSerializationOptions(typeRegistry: TypeRegistry())
    XCTAssertTrue(options.useCanonicalWellKnownTypeEncoding)
  }

  func test_options_customCanonicalWKTEncoding_respectsValue() async throws {
    let optionsTrue = JSONSerializationOptions(
      useCanonicalWellKnownTypeEncoding: true,
      typeRegistry: TypeRegistry()
    )
    XCTAssertTrue(optionsTrue.useCanonicalWellKnownTypeEncoding)

    let optionsFalse = JSONSerializationOptions(
      useCanonicalWellKnownTypeEncoding: false,
      typeRegistry: TypeRegistry()
    )
    XCTAssertFalse(optionsFalse.useCanonicalWellKnownTypeEncoding)
  }

}
