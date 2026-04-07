import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class TypeRegistryNestedTypesTests: XCTestCase {

  var registry: TypeRegistry!
  let bridge = DescriptorBridge()

  override func setUp() async throws {
    try await super.setUp()
    registry = TypeRegistry()
  }

  // MARK: - Group 6.1 — registerFile with nested types (preferred API)

  func test_registerFile_messageWithNested_nestedRegisteredUnderQualifiedName() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await registry.registerFile(fd)
    let _asyncResult89 = await registry.findMessage(named: "pkg.Parent.Child")
    XCTAssertNotNil(_asyncResult89)
  }

  func test_registerFile_messageWithNested_bareNameNotRegistered() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await registry.registerFile(fd)
    let _asyncResult90 = await registry.findMessage(named: "Child")
    XCTAssertNil(_asyncResult90)
  }

  func test_registerFile_messageWithNested_noThrowDuplicateType() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(adsResponseFileProto)
    try await registry.registerFile(fd)
  }

  func test_registerFile_2LevelNesting_allQualifiedRegistered() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(deepNestingFileProto)
    try await registry.registerFile(fd)
    let _asyncResult91 = await registry.findMessage(named: "pkg.A")
    XCTAssertNotNil(_asyncResult91)
    let _asyncResult92 = await registry.findMessage(named: "pkg.A.B")
    XCTAssertNotNil(_asyncResult92)
    let _asyncResult93 = await registry.findMessage(named: "pkg.A.B.C")
    XCTAssertNotNil(_asyncResult93)
  }

  func test_registerFile_nestedEnum_registeredUnderQualifiedName() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await registry.registerFile(fd)
    let _asyncResult94 = await registry.findEnum(named: "pkg.Parent.Status")
    XCTAssertNotNil(_asyncResult94)
  }

  func test_registerFile_nestedEnum_bareNameNotRegistered() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await registry.registerFile(fd)
    let _asyncResult95 = await registry.findEnum(named: "Status")
    XCTAssertNil(_asyncResult95)
  }

  func test_registerFile_twoMessagesEachWithNested_allQualified() async throws {
    let xMsg = makeMessageProto(name: "X")
    let yMsg = makeMessageProto(name: "Y")
    let a = makeMessageProto(name: "A", nestedMessages: [xMsg])
    let b = makeMessageProto(name: "B", nestedMessages: [yMsg])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [a, b])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try await registry.registerFile(fd)
    let _asyncResult96 = await registry.findMessage(named: "pkg.A.X")
    XCTAssertNotNil(_asyncResult96)
    let _asyncResult97 = await registry.findMessage(named: "pkg.B.Y")
    XCTAssertNotNil(_asyncResult97)
  }

  func test_registerFile_sameFileRegisteredTwice_throwsDuplicateFile() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await registry.registerFile(fd)
    do {
      try await registry.registerFile(fd)
      XCTFail("Expected error to be thrown")
    }
    catch {
      guard case RegistryError.duplicateFile = error else {
        XCTFail("Expected duplicateFile, got \(error)")
        return
      }
    }
  }

  // MARK: - Group 6.2 — registerMessage directly

  func test_registerMessage_topLevelWithNested_alsoRegistersNestedRecursively() async throws {
    let child = makeMessageProto(name: "Child")
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let parentDesc = fd.messages["Parent"]!
    try await registry.registerMessage(parentDesc)
    let _asyncResult98 = await registry.findMessage(named: "pkg.Parent.Child")
    XCTAssertNotNil(_asyncResult98)
  }

  func test_registerMessage_nestedDirectly_registeredUnderQualifiedName() async throws {
    let child = makeMessageProto(name: "Child")
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let childDesc = fd.messages["Parent"]!.nestedMessages["Child"]!
    try await registry.registerMessage(childDesc)
    let _asyncResult99 = await registry.findMessage(named: "pkg.Parent.Child")
    XCTAssertNotNil(_asyncResult99)
  }

  func test_registerMessage_parentAfterChildDirectly_throwsDuplicateType() async throws {
    let child = makeMessageProto(name: "Child")
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let childDesc = fd.messages["Parent"]!.nestedMessages["Child"]!
    let parentDesc = fd.messages["Parent"]!
    try await registry.registerMessage(childDesc)
    do {
      try await registry.registerMessage(parentDesc)
      XCTFail("Expected error to be thrown")
    }
    catch {
      guard case RegistryError.duplicateType = error else {
        XCTFail("Expected duplicateType, got \(error)")
        return
      }
    }
  }

  func test_registerMessage_parentAfterChildDirectly_errorContainsQualifiedName() async throws {
    let child = makeMessageProto(name: "Child")
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let childDesc = fd.messages["Parent"]!.nestedMessages["Child"]!
    let parentDesc = fd.messages["Parent"]!
    try await registry.registerMessage(childDesc)
    do {
      try await registry.registerMessage(parentDesc)
      XCTFail("Expected error to be thrown")
    }
    catch {
      if case RegistryError.duplicateType(let name) = error {
        XCTAssertEqual(name, "pkg.Parent.Child")
      }
      else {
        XCTFail("Expected duplicateType with qualified name, got \(error)")
      }
    }
  }

  // MARK: - Group 6.3 — findMessage after registration

  func test_findMessage_nestedByQualifiedName_returnsDescriptor() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await registry.registerFile(fd)
    let _asyncResult100 = await registry.findMessage(named: "pkg.Parent.Child")
    XCTAssertNotNil(_asyncResult100)
  }

  func test_findMessage_nestedByBareName_returnsNil() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await registry.registerFile(fd)
    let _asyncResult101 = await registry.findMessage(named: "Child")
    XCTAssertNil(_asyncResult101)
  }

  func test_findMessage_returnedDescriptor_hasCorrectFullName() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await registry.registerFile(fd)
    let child = await registry.findMessage(named: "pkg.Parent.Child")!
    XCTAssertEqual(child.fullName, "pkg.Parent.Child")
  }

  func test_findMessage_returnedDescriptor_hasCorrectFields() async throws {
    let child = makeMessageProto(
      name: "Child",
      fields: [makeFieldProto(name: "id", number: 1, type: .string)]
    )
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try await registry.registerFile(fd)
    let childDesc = await registry.findMessage(named: "pkg.Parent.Child")!
    XCTAssertNotNil(childDesc.field(named: "id"))
  }

  func test_findMessage_deeplyNestedByFullyQualifiedName() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(deepNestingFileProto)
    try await registry.registerFile(fd)
    let _asyncResult102 = await registry.findMessage(named: "pkg.A.B.C")
    XCTAssertNotNil(_asyncResult102)
  }

  // MARK: - Group 6.4 — hasMessage

  func test_hasMessage_nestedByQualifiedName_returnsTrue() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await registry.registerFile(fd)
    let _asyncResult103 = await registry.hasMessage(named: "pkg.Parent.Child")
    XCTAssertTrue(_asyncResult103)
  }

  func test_hasMessage_nestedByBareName_returnsFalse() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await registry.registerFile(fd)
    let _asyncResult104 = await registry.hasMessage(named: "Child")
    XCTAssertFalse(_asyncResult104)
  }

  // MARK: - Group 6.5 — resolveDependencies

  func test_resolveDependencies_messageWithNestedField_dependencyIsQualifiedName() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(adsRequestFileProto)
    try await registry.registerFile(fd)
    let deps = try await registry.resolveDependencies(for: "pkg.GetGroupedAdsRequest")
    // field.typeName includes leading dot from proto format
    XCTAssertTrue(
      deps.contains(".pkg.GetGroupedAdsRequest.SearchFilters")
        || deps.contains("pkg.GetGroupedAdsRequest.SearchFilters")
        || deps.contains("pkg.GetGroupedAdsRequest.SearchFilters")
    )
  }

  func test_resolveDependencies_nestedType_includesNestedFullName() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await registry.registerFile(fd)
    let deps = try await registry.resolveDependencies(for: "pkg.Parent")
    XCTAssertTrue(deps.contains("pkg.Parent.Child"))
  }

  // MARK: - Group 6.6 — removeFile

  func test_removeFile_withNestedTypes_removesNestedFromRegistry() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await registry.registerFile(fd)
    let _asyncResult105 = await registry.findMessage(named: "pkg.Parent.Child")
    XCTAssertNotNil(_asyncResult105)
    let removed = await registry.removeFile(named: "parent.proto")
    XCTAssertTrue(removed)
    let _asyncResult106 = await registry.findMessage(named: "pkg.Parent.Child")
    XCTAssertNil(_asyncResult106)
  }

  func test_removeFile_withNestedEnum_removesNestedEnum() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await registry.registerFile(fd)
    let _asyncResult107 = await registry.findEnum(named: "pkg.Parent.Status")
    XCTAssertNotNil(_asyncResult107)
    _ = await registry.removeFile(named: "parent.proto")
    let _asyncResult108 = await registry.findEnum(named: "pkg.Parent.Status")
    XCTAssertNil(_asyncResult108)
  }

  // MARK: - Group 6.7 — allMessages

  func test_allMessages_includesNestedWithQualifiedFullNames() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await registry.registerFile(fd)
    let _asyncResult109 = await registry.allMessages().contains { $0.fullName == "pkg.Parent.Child" }
    XCTAssertTrue(_asyncResult109)
  }

  func test_allMessages_noMessagesWithBareNestedNames() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await registry.registerFile(fd)
    let _asyncResult110 = await registry.allMessages().contains { $0.fullName == "Child" }
    XCTAssertFalse(_asyncResult110)
  }

  // MARK: - Group 6.8 — Corner cases

  func test_registerFile_sameNestedNameInDifferentMessages_bothRegistered() async throws {
    let cursorA = makeMessageProto(name: "Cursor")
    let cursorB = makeMessageProto(name: "Cursor")
    let a = makeMessageProto(name: "A", nestedMessages: [cursorA])
    let b = makeMessageProto(name: "B", nestedMessages: [cursorB])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [a, b])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try await registry.registerFile(fd)
    let _asyncResult111 = await registry.findMessage(named: "pkg.A.Cursor")
    XCTAssertNotNil(_asyncResult111)
    let _asyncResult112 = await registry.findMessage(named: "pkg.B.Cursor")
    XCTAssertNotNil(_asyncResult112)
  }

  func test_registerFile_noPackage_nestedRegisteredWithoutPackagePrefix() async throws {
    let b = makeMessageProto(name: "B")
    let a = makeMessageProto(name: "A", nestedMessages: [b])
    let fileProto = makeFileProto(name: "t.proto", package: "", messages: [a])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try await registry.registerFile(fd)
    let _asyncResult113 = await registry.findMessage(named: "A.B")
    XCTAssertNotNil(_asyncResult113)
  }

  func test_registerMessage_emptyNestedMessages_registersOnlyParent() async throws {
    let msgProto = makeMessageProto(name: "Flat")
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [msgProto])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let flatDesc = fd.messages["Flat"]!
    try await registry.registerMessage(flatDesc)
    let _asyncResult114 = await registry.findMessage(named: "pkg.Flat")
    XCTAssertNotNil(_asyncResult114)
  }

  // MARK: - Group 6.9 — Regressions

  func test_registerFile_flatMessages_unchanged() async throws {
    let msgProto = makeMessageProto(name: "Flat")
    let fileProto = makeFileProto(name: "flat.proto", package: "pkg", messages: [msgProto])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try await registry.registerFile(fd)
    let _asyncResult115 = await registry.findMessage(named: "pkg.Flat")
    XCTAssertNotNil(_asyncResult115)
  }

  func test_registerEnum_topLevel_unchanged() async throws {
    let enumProto = makeEnumProto(name: "TopLevel", values: [("NONE", 0)])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", enums: [enumProto])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try await registry.registerFile(fd)
    let _asyncResult116 = await registry.findEnum(named: "pkg.TopLevel")
    XCTAssertNotNil(_asyncResult116)
  }

  // MARK: - Group 6.2 addendum — childDirectlyThenParent variant

  func test_registerMessage_childDirectlyThenParent_errorContainsQualifiedName() async throws {
    // Register child first, then parent → duplicateType with qualified name
    let child = makeMessageProto(name: "Child")
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let childDesc = fd.messages["Parent"]!.nestedMessages["Child"]!
    let parentDesc = fd.messages["Parent"]!
    try await registry.registerMessage(childDesc)
    do {
      try await registry.registerMessage(parentDesc)
      XCTFail("Expected error to be thrown")
    }
    catch {
      if case RegistryError.duplicateType(let name) = error {
        XCTAssertEqual(name, "pkg.Parent.Child", "Error must contain qualified name, not bare name")
      }
      else {
        XCTFail("Expected duplicateType with qualified name, got \(error)")
      }
    }
  }

  func test_registerService_unchanged() async throws {
    var methodProto = Google_Protobuf_MethodDescriptorProto()
    methodProto.name = "DoThing"
    methodProto.inputType = ".pkg.FooReq"
    methodProto.outputType = ".pkg.FooRes"
    var serviceProto = Google_Protobuf_ServiceDescriptorProto()
    serviceProto.name = "FooService"
    serviceProto.method = [methodProto]
    var fileProto = Google_Protobuf_FileDescriptorProto()
    fileProto.name = "t.proto"
    fileProto.package = "pkg"
    fileProto.syntax = "proto3"
    fileProto.service = [serviceProto]
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try await registry.registerFile(fd)
    let _asyncResult117 = await registry.findService(named: "pkg.FooService")
    XCTAssertNotNil(_asyncResult117)
  }
}
