//
// DeserializationOptionsTests.swift
// SwiftProtoReflect
//
// Created: 2026-04-04
//

import XCTest

@testable import SwiftProtoReflect

final class DeserializationOptionsTests: XCTestCase {

  func test_init_defaultOptions_typeRegistryIsEmpty() {
    let options = DeserializationOptions()
    XCTAssertEqual(options.typeRegistry.allFiles().count, 0)
  }

  func test_init_withTypeRegistry_storesRegistry() {
    let registry = TypeRegistry()
    let options = DeserializationOptions(
      preserveUnknownFields: true,
      strictUTF8Validation: true,
      typeRegistry: registry
    )
    XCTAssertEqual(options.typeRegistry.allFiles().count, 0)
  }

  func test_init_preserveUnknownFieldsDefault_isTrue() {
    let options = DeserializationOptions()
    XCTAssertTrue(options.preserveUnknownFields)
  }

  func test_init_strictUTF8ValidationDefault_isTrue() {
    let options = DeserializationOptions()
    XCTAssertTrue(options.strictUTF8Validation)
  }

  // MARK: - OPE-256: Non-optional TypeRegistry API

  func test_deserializationOptions_deprecatedInit_createsEmptyRegistry() {
    let options = DeserializationOptions()
    XCTAssertEqual(options.typeRegistry.allFiles().count, 0)
  }

  func test_jsonDeserializationOptions_deprecatedInit_createsEmptyRegistry() {
    let options = JSONDeserializationOptions()
    XCTAssertEqual(options.typeRegistry.allFiles().count, 0)
  }

  func test_jsonSerializationOptions_deprecatedInit_createsEmptyRegistry() {
    let options = JSONSerializationOptions()
    XCTAssertEqual(options.typeRegistry.allFiles().count, 0)
  }

  func test_deserializationOptions_newInit_storesRegistry() throws {
    let registry = try TypeRegistry(fileDescriptors: [])
    let options = DeserializationOptions(
      preserveUnknownFields: true,
      strictUTF8Validation: true,
      typeRegistry: registry
    )
    XCTAssertEqual(options.typeRegistry.allFiles().count, 0)
  }

  func test_jsonSerializationOptions_newInit_storesRegistry() throws {
    let registry = try TypeRegistry(fileDescriptors: [])
    let options = JSONSerializationOptions(
      useOriginalFieldNames: false,
      prettyPrinted: false,
      includeDefaultValues: false,
      typeRegistry: registry
    )
    XCTAssertEqual(options.typeRegistry.allFiles().count, 0)
  }
}
