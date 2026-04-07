//
// DescriptorPoolProtocComplianceTests.swift
// SwiftProtoReflectTests
//
// Covers uncovered paths in Registry/_DescriptorPool.swift, Registry/_TypeRegistry.swift,
// and Public/Registry.swift:
//   - _DescriptorPoolError.errorDescription — all 4 cases
//   - DescriptorPoolError.init(from: _DescriptorPoolError) — all 4 cases
//   - _RegistryError.errorDescription — all 3 cases
//   - RegistryError.init(from: _RegistryError) — all 3 cases
//   - _DescriptorPoolStorage.findFileContainingSymbol via enum and service symbol branches
//   - _DescriptorPoolStorage.createMessage(forType:fieldValues:) for unknown type → nil
//   - DescriptorPool.findDependencies for type with enum dependencies
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class DescriptorPoolProtocComplianceTests: XCTestCase {

  // MARK: - _DescriptorPoolError.errorDescription — all 4 cases

  // [PUBLIC-MIRROR] DescriptorPoolTests.testDescriptorPoolErrorDescriptions()
  // Oracle: each internal _DescriptorPoolError has a human-readable description matching
  //         the public DescriptorPoolError description
  func test_internalDescriptorPoolError_errorDescription_allCases() {
    let cases: [(error: _DescriptorPoolError, substring: String)] = [
      (.duplicateFile("myfile.proto"), "myfile.proto"),
      (.duplicateSymbol("pkg.MyType"), "pkg.MyType"),
      (.symbolNotFound("pkg.Missing"), "pkg.Missing"),
      (.invalidDescriptor("missing field"), "missing field"),
    ]

    for (error, substring) in cases {
      let desc = error.errorDescription
      XCTAssertNotNil(desc)
      XCTAssertTrue(desc!.contains(substring), "Expected '\(desc!)' to contain '\(substring)'")
    }
  }

  // MARK: - DescriptorPoolError.init(from: _DescriptorPoolError) — all 4 cases

  // [PUBLIC-MIRROR] DescriptorPoolTests.testDescriptorPoolErrorDescriptions()
  // Oracle: DescriptorPoolError(from:) converts each _DescriptorPoolError correctly
  func test_descriptorPoolError_initFromImpl_allCases() {
    let cases: [(_DescriptorPoolError, DescriptorPoolError)] = [
      (.duplicateFile("a.proto"), .duplicateFile("a.proto")),
      (.duplicateSymbol("pkg.Foo"), .duplicateSymbol("pkg.Foo")),
      (.symbolNotFound("pkg.Bar"), .symbolNotFound("pkg.Bar")),
      (.invalidDescriptor("bad field"), .invalidDescriptor("bad field")),
    ]

    for (impl, expected) in cases {
      let pub = DescriptorPoolError(from: impl)
      XCTAssertEqual(pub, expected)
      XCTAssertEqual(pub.errorDescription, expected.errorDescription)
    }
  }

  // MARK: - _RegistryError.errorDescription — all 3 cases

  // [PUBLIC-MIRROR] TypeRegistryTests.testRegistryErrorDescriptions()
  // Oracle: each internal _RegistryError has a description matching the public RegistryError description
  func test_internalRegistryError_errorDescription_allCases() {
    let cases: [(error: _RegistryError, substring: String)] = [
      (.duplicateFile("test.proto"), "test.proto"),
      (.duplicateType("pkg.Type"), "pkg.Type"),
      (.typeNotFound("pkg.Missing"), "pkg.Missing"),
    ]

    for (error, substring) in cases {
      let desc = error.errorDescription
      XCTAssertNotNil(desc)
      XCTAssertTrue(desc!.contains(substring), "Expected '\(desc!)' to contain '\(substring)'")
    }
  }

  // MARK: - RegistryError.init(from: _RegistryError) — all 3 cases

  // [PUBLIC-MIRROR] TypeRegistryTests.testRegistryErrorDescriptions()
  // Oracle: RegistryError(from:) converts each _RegistryError correctly
  func test_registryError_initFromImpl_allCases() {
    let cases: [(_RegistryError, RegistryError)] = [
      (.duplicateFile("test.proto"), .duplicateFile("test.proto")),
      (.duplicateType("pkg.Foo"), .duplicateType("pkg.Foo")),
      (.typeNotFound("pkg.Bar"), .typeNotFound("pkg.Bar")),
    ]

    for (impl, expected) in cases {
      let pub = RegistryError(from: impl)
      XCTAssertEqual(pub, expected)
      XCTAssertEqual(pub.errorDescription, expected.errorDescription)
    }
  }

  // MARK: - _DescriptorPoolStorage enum symbol branch

  // [PUBLIC-MIRROR] DescriptorPoolTests.testFindFileContainingSymbol()
  // Oracle: findFileContainingSymbol returns file containing enum even when no message matches
  func test_descriptorPoolStorage_findFileContainingSymbol_enumBranch() throws {
    var storage = _DescriptorPoolStorage(includeBuiltinDescriptors: false)

    var fileDesc = _FileDescriptor(name: "e.proto", package: "pkg")
    var enumDesc = _EnumDescriptor(name: "MyEnum", parent: fileDesc)
    enumDesc.addValue(_EnumDescriptor._EnumValue(name: "UNSET", number: 0))
    fileDesc.addEnum(enumDesc)
    try storage.addFileDescriptor(fileDesc)

    let found = storage.findFileContainingSymbol("pkg.MyEnum")
    XCTAssertEqual(found?.name, "e.proto")

    let notFound = storage.findFileContainingSymbol("pkg.NoSuchThing")
    XCTAssertNil(notFound)
  }

  // MARK: - _DescriptorPoolStorage service symbol branch

  // [PUBLIC-MIRROR] DescriptorPoolTests.testFindFileContainingSymbol()
  // Oracle: findFileContainingSymbol returns file containing service when no message or enum matches
  func test_descriptorPoolStorage_findFileContainingSymbol_serviceBranch() throws {
    var storage = _DescriptorPoolStorage(includeBuiltinDescriptors: false)

    var fileDesc = _FileDescriptor(name: "svc.proto", package: "pkg")
    var svcDesc = _ServiceDescriptor(name: "MyService", fullName: "pkg.MyService")
    svcDesc.fileDescriptorPath = "svc.proto"
    fileDesc.addService(svcDesc)
    try storage.addFileDescriptor(fileDesc)

    let found = storage.findFileContainingSymbol("pkg.MyService")
    XCTAssertEqual(found?.name, "svc.proto")
  }

  // MARK: - _DescriptorPoolStorage createMessage(forType:fieldValues:) → nil for unknown type

  // [PUBLIC-MIRROR] DescriptorPoolTests.testCreateMessageWithFieldValues()
  // Oracle: createMessage(forType:fieldValues:) returns nil when type not registered
  func test_descriptorPoolStorage_createMessageWithFieldValues_unknownType_returnsNil() throws {
    let storage = _DescriptorPoolStorage(includeBuiltinDescriptors: false)
    let result = try storage.createMessage(forType: "pkg.Nonexistent", fieldValues: ["id": 1])
    XCTAssertNil(result)
  }

  // MARK: - _DescriptorPoolStorage findDependencies with enum dependency

  // [PUBLIC-MIRROR] DescriptorPoolTests.testFindDependencies()
  // Oracle: findDependencies includes nested enum type names when present
  func test_descriptorPoolStorage_findDependencies_withNestedEnum() throws {
    var storage = _DescriptorPoolStorage(includeBuiltinDescriptors: false)

    var fileDesc = _FileDescriptor(name: "t.proto", package: "pkg")
    var msgDesc = _MessageDescriptor(name: "Order", parent: fileDesc)
    var nestedEnum = _EnumDescriptor(name: "Status", parent: msgDesc)
    nestedEnum.addValue(_EnumDescriptor._EnumValue(name: "PENDING", number: 0))
    msgDesc.addNestedEnum(nestedEnum)
    fileDesc.addMessage(msgDesc)
    try storage.addFileDescriptor(fileDesc)

    let deps = try storage.findDependencies(for: "pkg.Order")
    XCTAssertTrue(deps.contains("pkg.Order.Status"), "Expected 'pkg.Order.Status' in \(deps)")
  }

  // MARK: - _DescriptorPoolStorage findDependencies error path

  // [PUBLIC-MIRROR] DescriptorPoolNestedTypesTests.test_findDependencies_unknownType_throwsSymbolNotFound()
  // Oracle: findDependencies throws symbolNotFound for unregistered type
  func test_descriptorPoolStorage_findDependencies_unknownType_throwsSymbolNotFound() {
    let storage = _DescriptorPoolStorage(includeBuiltinDescriptors: false)

    XCTAssertThrowsError(try storage.findDependencies(for: "pkg.NotHere")) { error in
      if let poolError = error as? _DescriptorPoolError, case .symbolNotFound = poolError {
        // Expected
      }
      else {
        XCTFail("Expected _DescriptorPoolError.symbolNotFound, got \(error)")
      }
    }
  }
}
