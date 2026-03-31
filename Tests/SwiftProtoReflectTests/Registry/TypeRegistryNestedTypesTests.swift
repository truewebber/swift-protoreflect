import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class TypeRegistryNestedTypesTests: XCTestCase {

  var registry: TypeRegistry!
  let bridge = DescriptorBridge()

  override func setUp() {
    super.setUp()
    registry = TypeRegistry()
  }

  // MARK: - Group 6.1 — registerFile with nested types (preferred API)

  func test_registerFile_messageWithNested_nestedRegisteredUnderQualifiedName() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try registry.registerFile(fd)
    XCTAssertNotNil(registry.findMessage(named: "pkg.Parent.Child"))
  }

  func test_registerFile_messageWithNested_bareNameNotRegistered() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try registry.registerFile(fd)
    XCTAssertNil(registry.findMessage(named: "Child"))
  }

  func test_registerFile_messageWithNested_noThrowDuplicateType() throws {
    let fd = try bridge.fromProtobufFileDescriptor(adsResponseFileProto)
    XCTAssertNoThrow(try registry.registerFile(fd))
  }

  func test_registerFile_2LevelNesting_allQualifiedRegistered() throws {
    let fd = try bridge.fromProtobufFileDescriptor(deepNestingFileProto)
    try registry.registerFile(fd)
    XCTAssertNotNil(registry.findMessage(named: "pkg.A"))
    XCTAssertNotNil(registry.findMessage(named: "pkg.A.B"))
    XCTAssertNotNil(registry.findMessage(named: "pkg.A.B.C"))
  }

  func test_registerFile_nestedEnum_registeredUnderQualifiedName() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try registry.registerFile(fd)
    XCTAssertNotNil(registry.findEnum(named: "pkg.Parent.Status"))
  }

  func test_registerFile_nestedEnum_bareNameNotRegistered() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try registry.registerFile(fd)
    XCTAssertNil(registry.findEnum(named: "Status"))
  }

  func test_registerFile_twoMessagesEachWithNested_allQualified() throws {
    let xMsg = makeMessageProto(name: "X")
    let yMsg = makeMessageProto(name: "Y")
    let a = makeMessageProto(name: "A", nestedMessages: [xMsg])
    let b = makeMessageProto(name: "B", nestedMessages: [yMsg])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [a, b])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try registry.registerFile(fd)
    XCTAssertNotNil(registry.findMessage(named: "pkg.A.X"))
    XCTAssertNotNil(registry.findMessage(named: "pkg.B.Y"))
  }

  func test_registerFile_sameFileRegisteredTwice_throwsDuplicateFile() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try registry.registerFile(fd)
    XCTAssertThrowsError(try registry.registerFile(fd)) { error in
      guard case RegistryError.duplicateFile = error else {
        XCTFail("Expected duplicateFile, got \(error)")
        return
      }
    }
  }

  // MARK: - Group 6.2 — registerMessage directly

  func test_registerMessage_topLevelWithNested_alsoRegistersNestedRecursively() throws {
    let child = makeMessageProto(name: "Child")
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let parentDesc = fd.messages["Parent"]!
    try registry.registerMessage(parentDesc)
    XCTAssertNotNil(registry.findMessage(named: "pkg.Parent.Child"))
  }

  func test_registerMessage_nestedDirectly_registeredUnderQualifiedName() throws {
    let child = makeMessageProto(name: "Child")
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let childDesc = fd.messages["Parent"]!.nestedMessages["Child"]!
    try registry.registerMessage(childDesc)
    XCTAssertNotNil(registry.findMessage(named: "pkg.Parent.Child"))
  }

  func test_registerMessage_parentAfterChildDirectly_throwsDuplicateType() throws {
    let child = makeMessageProto(name: "Child")
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let childDesc = fd.messages["Parent"]!.nestedMessages["Child"]!
    let parentDesc = fd.messages["Parent"]!
    try registry.registerMessage(childDesc)
    XCTAssertThrowsError(try registry.registerMessage(parentDesc)) { error in
      guard case RegistryError.duplicateType = error else {
        XCTFail("Expected duplicateType, got \(error)")
        return
      }
    }
  }

  func test_registerMessage_parentAfterChildDirectly_errorContainsQualifiedName() throws {
    let child = makeMessageProto(name: "Child")
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let childDesc = fd.messages["Parent"]!.nestedMessages["Child"]!
    let parentDesc = fd.messages["Parent"]!
    try registry.registerMessage(childDesc)
    XCTAssertThrowsError(try registry.registerMessage(parentDesc)) { error in
      if case RegistryError.duplicateType(let name) = error {
        XCTAssertEqual(name, "pkg.Parent.Child")
      }
      else {
        XCTFail("Expected duplicateType with qualified name, got \(error)")
      }
    }
  }

  // MARK: - Group 6.3 — findMessage after registration

  func test_findMessage_nestedByQualifiedName_returnsDescriptor() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try registry.registerFile(fd)
    XCTAssertNotNil(registry.findMessage(named: "pkg.Parent.Child"))
  }

  func test_findMessage_nestedByBareName_returnsNil() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try registry.registerFile(fd)
    XCTAssertNil(registry.findMessage(named: "Child"))
  }

  func test_findMessage_returnedDescriptor_hasCorrectFullName() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try registry.registerFile(fd)
    let child = registry.findMessage(named: "pkg.Parent.Child")!
    XCTAssertEqual(child.fullName, "pkg.Parent.Child")
  }

  func test_findMessage_returnedDescriptor_hasCorrectFields() throws {
    let child = makeMessageProto(
      name: "Child",
      fields: [makeFieldProto(name: "id", number: 1, type: .string)]
    )
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try registry.registerFile(fd)
    let childDesc = registry.findMessage(named: "pkg.Parent.Child")!
    XCTAssertNotNil(childDesc.field(named: "id"))
  }

  func test_findMessage_deeplyNestedByFullyQualifiedName() throws {
    let fd = try bridge.fromProtobufFileDescriptor(deepNestingFileProto)
    try registry.registerFile(fd)
    XCTAssertNotNil(registry.findMessage(named: "pkg.A.B.C"))
  }

  // MARK: - Group 6.4 — hasMessage

  func test_hasMessage_nestedByQualifiedName_returnsTrue() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try registry.registerFile(fd)
    XCTAssertTrue(registry.hasMessage(named: "pkg.Parent.Child"))
  }

  func test_hasMessage_nestedByBareName_returnsFalse() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try registry.registerFile(fd)
    XCTAssertFalse(registry.hasMessage(named: "Child"))
  }

  // MARK: - Group 6.5 — resolveDependencies

  func test_resolveDependencies_messageWithNestedField_dependencyIsQualifiedName() throws {
    let fd = try bridge.fromProtobufFileDescriptor(adsRequestFileProto)
    try registry.registerFile(fd)
    let deps = try registry.resolveDependencies(for: "pkg.GetGroupedAdsRequest")
    // field.typeName includes leading dot from proto format
    XCTAssertTrue(
      deps.contains(".pkg.GetGroupedAdsRequest.SearchFilters")
        || deps.contains("pkg.GetGroupedAdsRequest.SearchFilters")
        || deps.contains("pkg.GetGroupedAdsRequest.SearchFilters")
    )
  }

  func test_resolveDependencies_nestedType_includesNestedFullName() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try registry.registerFile(fd)
    let deps = try registry.resolveDependencies(for: "pkg.Parent")
    XCTAssertTrue(deps.contains("pkg.Parent.Child"))
  }

  // MARK: - Group 6.6 — removeFile

  func test_removeFile_withNestedTypes_removesNestedFromRegistry() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try registry.registerFile(fd)
    XCTAssertNotNil(registry.findMessage(named: "pkg.Parent.Child"))
    let removed = registry.removeFile(named: "parent.proto")
    XCTAssertTrue(removed)
    XCTAssertNil(registry.findMessage(named: "pkg.Parent.Child"))
  }

  func test_removeFile_withNestedEnum_removesNestedEnum() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try registry.registerFile(fd)
    XCTAssertNotNil(registry.findEnum(named: "pkg.Parent.Status"))
    registry.removeFile(named: "parent.proto")
    XCTAssertNil(registry.findEnum(named: "pkg.Parent.Status"))
  }

  // MARK: - Group 6.7 — allMessages

  func test_allMessages_includesNestedWithQualifiedFullNames() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try registry.registerFile(fd)
    XCTAssertTrue(registry.allMessages().contains { $0.fullName == "pkg.Parent.Child" })
  }

  func test_allMessages_noMessagesWithBareNestedNames() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try registry.registerFile(fd)
    XCTAssertFalse(registry.allMessages().contains { $0.fullName == "Child" })
  }

  // MARK: - Group 6.8 — Corner cases

  func test_registerFile_sameNestedNameInDifferentMessages_bothRegistered() throws {
    let cursorA = makeMessageProto(name: "Cursor")
    let cursorB = makeMessageProto(name: "Cursor")
    let a = makeMessageProto(name: "A", nestedMessages: [cursorA])
    let b = makeMessageProto(name: "B", nestedMessages: [cursorB])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [a, b])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try registry.registerFile(fd)
    XCTAssertNotNil(registry.findMessage(named: "pkg.A.Cursor"))
    XCTAssertNotNil(registry.findMessage(named: "pkg.B.Cursor"))
  }

  func test_registerFile_noPackage_nestedRegisteredWithoutPackagePrefix() throws {
    let b = makeMessageProto(name: "B")
    let a = makeMessageProto(name: "A", nestedMessages: [b])
    let fileProto = makeFileProto(name: "t.proto", package: "", messages: [a])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try registry.registerFile(fd)
    XCTAssertNotNil(registry.findMessage(named: "A.B"))
  }

  func test_registerMessage_emptyNestedMessages_registersOnlyParent() throws {
    let msgProto = makeMessageProto(name: "Flat")
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [msgProto])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let flatDesc = fd.messages["Flat"]!
    try registry.registerMessage(flatDesc)
    XCTAssertNotNil(registry.findMessage(named: "pkg.Flat"))
  }

  // MARK: - Group 6.9 — Regressions

  func test_registerFile_flatMessages_unchanged() throws {
    let msgProto = makeMessageProto(name: "Flat")
    let fileProto = makeFileProto(name: "flat.proto", package: "pkg", messages: [msgProto])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try registry.registerFile(fd)
    XCTAssertNotNil(registry.findMessage(named: "pkg.Flat"))
  }

  func test_registerEnum_topLevel_unchanged() throws {
    let enumProto = makeEnumProto(name: "TopLevel", values: [("NONE", 0)])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", enums: [enumProto])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try registry.registerFile(fd)
    XCTAssertNotNil(registry.findEnum(named: "pkg.TopLevel"))
  }

  // MARK: - Group 6.2 addendum — childDirectlyThenParent variant

  func test_registerMessage_childDirectlyThenParent_errorContainsQualifiedName() throws {
    // Register child first, then parent → duplicateType with qualified name
    let child = makeMessageProto(name: "Child")
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let childDesc = fd.messages["Parent"]!.nestedMessages["Child"]!
    let parentDesc = fd.messages["Parent"]!
    try registry.registerMessage(childDesc)
    XCTAssertThrowsError(try registry.registerMessage(parentDesc)) { error in
      if case RegistryError.duplicateType(let name) = error {
        XCTAssertEqual(name, "pkg.Parent.Child", "Error must contain qualified name, not bare name")
      }
      else {
        XCTFail("Expected duplicateType with qualified name, got \(error)")
      }
    }
  }

  func test_registerService_unchanged() throws {
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
    try registry.registerFile(fd)
    XCTAssertNotNil(registry.findService(named: "pkg.FooService"))
  }
}
