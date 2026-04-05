//
// JSONSerializationOptionsTests.swift
// SwiftProtoReflect
//
// Created: 2026-04-05
//

import XCTest

@testable import SwiftProtoReflect

final class JSONSerializationOptionsTests: XCTestCase {

  func test_options_defaultCanonicalWKTEncoding_isTrue() {
    let options = JSONSerializationOptions(typeRegistry: TypeRegistry())
    XCTAssertTrue(options.useCanonicalWellKnownTypeEncoding)
  }

  func test_options_customCanonicalWKTEncoding_respectsValue() {
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

  // swiftlint:disable deprecated_usage
  @available(*, deprecated)
  func test_options_deprecatedInit_hasCanonicalWKTEncodingTrue() {
    let options = JSONSerializationOptions()
    XCTAssertTrue(options.useCanonicalWellKnownTypeEncoding)
  }
  // swiftlint:enable deprecated_usage
}
