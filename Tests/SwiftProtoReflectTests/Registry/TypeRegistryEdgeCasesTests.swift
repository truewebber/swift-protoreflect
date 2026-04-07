//
// TypeRegistryEdgeCasesTests.swift
// SwiftProtoReflectTests
//
// Covers edge-case paths in Registry/_TypeRegistry.swift:
//   - registerTypesFromFile: duplicate service across two files throws duplicateType
//   - registerTypesFromFile: duplicate enum across two files throws duplicateType
//   - registerMessageRecursively: nested enum duplicate throws duplicateType
//   - removeTypesFromFile with services and nested enums
//   - allFiles(), allMessages(), allEnums(), allServices() after clear
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class TypeRegistryEdgeCasesTests: XCTestCase {

  // MARK: - Duplicate service from two different files

  // [PUBLIC-MIRROR] TypeRegistryTests.testDirectServiceRegistration()
  // Oracle: registering two files with the same service fullName throws RegistryError.duplicateType
  func test_registerFile_duplicateService_throwsDuplicateType() async throws {
    let registry = TypeRegistry()

    var file1 = FileDescriptor(name: "a.proto", package: "pkg")
    var svc = ServiceDescriptor(name: "MyService", parent: file1)
    svc.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "Ping",
        inputType: "pkg.Req",
        outputType: "pkg.Resp"
      )
    )
    file1.addService(svc)
    try await registry.registerFile(file1)

    var file2 = FileDescriptor(name: "b.proto", package: "pkg")
    file2.addService(svc)

    do {
      try await registry.registerFile(file2)
      XCTFail("Expected RegistryError.duplicateType")
    }
    catch let error as RegistryError {
      if case .duplicateType = error {
        // Expected
      }
      else {
        XCTFail("Expected duplicateType, got \(error)")
      }
    }
  }

  // MARK: - Duplicate enum from two different files

  // [PUBLIC-MIRROR] TypeRegistryTests.testDirectEnumRegistration()
  // Oracle: registering two files with the same enum fullName throws RegistryError.duplicateType
  func test_registerFile_duplicateEnum_throwsDuplicateType() async throws {
    let registry = TypeRegistry()

    var file1 = FileDescriptor(name: "a.proto", package: "pkg")
    var enumDesc = EnumDescriptor(name: "Status", parent: file1)
    enumDesc.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
    file1.addEnum(enumDesc)
    try await registry.registerFile(file1)

    var file2 = FileDescriptor(name: "b.proto", package: "pkg")
    file2.addEnum(enumDesc)

    do {
      try await registry.registerFile(file2)
      XCTFail("Expected RegistryError.duplicateType")
    }
    catch let error as RegistryError {
      if case .duplicateType = error {
        // Expected
      }
      else {
        XCTFail("Expected duplicateType, got \(error)")
      }
    }
  }

  // MARK: - Duplicate nested enum in same message across files

  // [PUBLIC-MIRROR] TypeRegistryTests.testDirectEnumRegistration()
  // Oracle: registering a message with nested enum, then registering another message
  //         with same nested enum fullName throws RegistryError.duplicateType
  func test_registerFile_duplicateNestedEnum_throwsDuplicateType() async throws {
    let registry = TypeRegistry()

    var file1 = FileDescriptor(name: "a.proto", package: "pkg")
    var msg1 = MessageDescriptor(name: "Order", parent: file1)
    var status1 = EnumDescriptor(name: "Status", parent: msg1)
    status1.addValue(EnumDescriptor.EnumValue(name: "PENDING", number: 0))
    msg1.addNestedEnum(status1)
    file1.addMessage(msg1)
    try await registry.registerFile(file1)

    var file2 = FileDescriptor(name: "b.proto", package: "pkg")
    var msg2 = MessageDescriptor(name: "Invoice", fullName: "pkg.Invoice", syntax: "proto3")
    var status2 = EnumDescriptor(name: "Status", parent: msg1)  // same fullName as status1
    status2.addValue(EnumDescriptor.EnumValue(name: "PENDING", number: 0))
    msg2.addNestedEnum(status2)
    file2.addMessage(msg2)

    do {
      try await registry.registerFile(file2)
      XCTFail("Expected RegistryError.duplicateType")
    }
    catch let error as RegistryError {
      if case .duplicateType = error {
        // Expected
      }
      else {
        XCTFail("Expected duplicateType, got \(error)")
      }
    }
  }

  // MARK: - removeFile removes services from registry

  // [PUBLIC-MIRROR] TypeRegistryTests.testRemoveFile()
  // Oracle: after removeFile, hasService returns false for services in that file
  func test_removeFile_removesServicesFromRegistry() async throws {
    let registry = TypeRegistry()

    var file = FileDescriptor(name: "svc.proto", package: "pkg")
    var svc = ServiceDescriptor(name: "Greeter", parent: file)
    svc.addMethod(
      ServiceDescriptor.MethodDescriptor(name: "Hello", inputType: "pkg.Req", outputType: "pkg.Resp")
    )
    file.addService(svc)
    try await registry.registerFile(file)

    let hasBefore = await registry.hasService(named: "pkg.Greeter")
    XCTAssertTrue(hasBefore)

    let removed = await registry.removeFile(named: "svc.proto")
    XCTAssertTrue(removed)
    let hasAfter = await registry.hasService(named: "pkg.Greeter")
    XCTAssertFalse(hasAfter)
  }

  // MARK: - clear() removes all types

  // [PUBLIC-MIRROR] TypeRegistryTests.testClearRegistry()
  // Oracle: after clear(), allFiles, allMessages, allEnums, allServices all return empty arrays
  func test_clear_removesAllTypes() async throws {
    let registry = TypeRegistry()

    var file = FileDescriptor(name: "t.proto", package: "pkg")
    var msg = MessageDescriptor(name: "Msg", parent: file)
    msg.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    file.addMessage(msg)
    try await registry.registerFile(file)

    let filesBefore = await registry.allFiles()
    let msgsBefore = await registry.allMessages()
    XCTAssertFalse(filesBefore.isEmpty)
    XCTAssertFalse(msgsBefore.isEmpty)

    await registry.clear()

    let filesAfter = await registry.allFiles()
    let msgsAfter = await registry.allMessages()
    let enumsAfter = await registry.allEnums()
    let svcsAfter = await registry.allServices()
    XCTAssertTrue(filesAfter.isEmpty)
    XCTAssertTrue(msgsAfter.isEmpty)
    XCTAssertTrue(enumsAfter.isEmpty)
    XCTAssertTrue(svcsAfter.isEmpty)
  }
}
