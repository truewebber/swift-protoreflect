//
// DeserializationOptionsTests.swift
// SwiftProtoReflect
//
// Created: 2026-04-04
//

import XCTest

@testable import SwiftProtoReflect

final class DeserializationOptionsTests: XCTestCase {

  // MARK: - New API (with explicit TypeRegistry)

  func test_init_withTypeRegistry_storesRegistry() async throws {
    let registry = TypeRegistry()
    let options = DeserializationOptions(
      preserveUnknownFields: true,
      strictUTF8Validation: true,
      typeRegistry: registry
    )
    let allFiles = await options.typeRegistry.allFiles()
    XCTAssertEqual(allFiles.count, 0)
  }

  func test_init_preserveUnknownFieldsDefault_isTrue() {
    let options = DeserializationOptions(typeRegistry: TypeRegistry())
    XCTAssertTrue(options.preserveUnknownFields)
  }

  func test_init_strictUTF8ValidationDefault_isTrue() {
    let options = DeserializationOptions(typeRegistry: TypeRegistry())
    XCTAssertTrue(options.strictUTF8Validation)
  }

  func test_deserializationOptions_newInit_storesRegistry() async throws {
    let registry = try await TypeRegistry(fileDescriptors: [])
    let options = DeserializationOptions(
      preserveUnknownFields: true,
      strictUTF8Validation: true,
      typeRegistry: registry
    )
    let allFiles = await options.typeRegistry.allFiles()
    XCTAssertEqual(allFiles.count, 0)
  }

  func test_jsonSerializationOptions_newInit_storesRegistry() async throws {
    let registry = try await TypeRegistry(fileDescriptors: [])
    let options = JSONSerializationOptions(
      useOriginalFieldNames: false,
      prettyPrinted: false,
      includeDefaultValues: false,
      typeRegistry: registry
    )
    let allFiles = await options.typeRegistry.allFiles()
    XCTAssertEqual(allFiles.count, 0)
  }

  func test_jsonDeserializationOptions_newInit_storesRegistry() async throws {
    let registry = try await TypeRegistry(fileDescriptors: [])
    let options = JSONDeserializationOptions(
      typeRegistry: registry
    )
    XCTAssertTrue(options.ignoreUnknownFields)
    XCTAssertTrue(options.strictTypeValidation)
    XCTAssertEqual(options.maxNestingDepth, 64)
    let allFiles = await options.typeRegistry.allFiles()
    XCTAssertEqual(allFiles.count, 0)
  }
}
