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

  func test_options_defaultEscapeSlashesInStrings_isTrue() async throws {
    let options = JSONSerializationOptions(typeRegistry: TypeRegistry())
    XCTAssertTrue(options.escapeSlashesInStrings)
  }

  func test_options_customEscapeSlashesInStrings_respectsValue() async throws {
    let optionsTrue = JSONSerializationOptions(
      escapeSlashesInStrings: true,
      typeRegistry: TypeRegistry()
    )
    XCTAssertTrue(optionsTrue.escapeSlashesInStrings)

    let optionsFalse = JSONSerializationOptions(
      escapeSlashesInStrings: false,
      typeRegistry: TypeRegistry()
    )
    XCTAssertFalse(optionsFalse.escapeSlashesInStrings)
  }

  func test_options_defaultSortJSONObjectKeys_isFalse() async throws {
    let options = JSONSerializationOptions(typeRegistry: TypeRegistry())
    XCTAssertFalse(options.sortJSONObjectKeys)
  }

  func test_options_customSortJSONObjectKeys_respectsValue() async throws {
    let optionsTrue = JSONSerializationOptions(
      sortJSONObjectKeys: true,
      typeRegistry: TypeRegistry()
    )
    XCTAssertTrue(optionsTrue.sortJSONObjectKeys)

    let optionsFalse = JSONSerializationOptions(
      sortJSONObjectKeys: false,
      typeRegistry: TypeRegistry()
    )
    XCTAssertFalse(optionsFalse.sortJSONObjectKeys)
  }

}
