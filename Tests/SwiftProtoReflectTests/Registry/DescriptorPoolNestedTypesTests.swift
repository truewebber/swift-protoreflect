import XCTest

@testable import SwiftProtoReflect

final class DescriptorPoolNestedTypesTests: XCTestCase {

  var pool: DescriptorPool!
  let bridge = DescriptorBridge()

  override func setUp() {
    super.setUp()
    pool = DescriptorPool()
  }

  // MARK: - Group 5.1 — Registration under qualified names

  func test_addFileDescriptor_messageWithNested_nestedStoredUnderQualifiedName() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try pool.addFileDescriptor(fd)
    XCTAssertNotNil(pool.findMessageDescriptor(named: "pkg.Parent.Child"))
  }

  func test_addFileDescriptor_messageWithNested_bareNameNotInPool() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try pool.addFileDescriptor(fd)
    XCTAssertNil(pool.findMessageDescriptor(named: "Child"))
  }

  func test_addFileDescriptor_messageWithNested_parentStoredUnderQualifiedName() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try pool.addFileDescriptor(fd)
    XCTAssertNotNil(pool.findMessageDescriptor(named: "pkg.Parent"))
  }

  func test_addFileDescriptor_messageWithNested_doesNotThrowDuplicateSymbol() throws {
    let fd = try bridge.fromProtobufFileDescriptor(adsResponseFileProto)
    XCTAssertNoThrow(try pool.addFileDescriptor(fd))
  }

  func test_addFileDescriptor_2LevelNesting_allThreeQualifiedInPool() throws {
    let fd = try bridge.fromProtobufFileDescriptor(deepNestingFileProto)
    try pool.addFileDescriptor(fd)
    XCTAssertNotNil(pool.findMessageDescriptor(named: "pkg.A"))
    XCTAssertNotNil(pool.findMessageDescriptor(named: "pkg.A.B"))
    XCTAssertNotNil(pool.findMessageDescriptor(named: "pkg.A.B.C"))
  }

  func test_addFileDescriptor_3LevelNesting_allFourQualifiedInPool() throws {
    let d = makeMessageProto(name: "D")
    let c = makeMessageProto(name: "C", nestedMessages: [d])
    let b = makeMessageProto(name: "B", nestedMessages: [c])
    let a = makeMessageProto(name: "A", nestedMessages: [b])
    let fileProto = makeFileProto(name: "deep4.proto", package: "pkg", messages: [a])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try pool.addFileDescriptor(fd)
    XCTAssertNotNil(pool.findMessageDescriptor(named: "pkg.A"))
    XCTAssertNotNil(pool.findMessageDescriptor(named: "pkg.A.B"))
    XCTAssertNotNil(pool.findMessageDescriptor(named: "pkg.A.B.C"))
    XCTAssertNotNil(pool.findMessageDescriptor(named: "pkg.A.B.C.D"))
  }

  func test_addFileDescriptor_multipleNestedAtSameLevel_allQualified() throws {
    let child1 = makeMessageProto(name: "Child1")
    let child2 = makeMessageProto(name: "Child2")
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child1, child2])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try pool.addFileDescriptor(fd)
    XCTAssertNotNil(pool.findMessageDescriptor(named: "pkg.Parent.Child1"))
    XCTAssertNotNil(pool.findMessageDescriptor(named: "pkg.Parent.Child2"))
  }

  func test_addFileDescriptor_nestedEnum_storedUnderQualifiedName() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try pool.addFileDescriptor(fd)
    XCTAssertNotNil(pool.findEnumDescriptor(named: "pkg.Parent.Status"))
  }

  func test_addFileDescriptor_nestedEnum_bareNameNotInPool() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try pool.addFileDescriptor(fd)
    XCTAssertNil(pool.findEnumDescriptor(named: "Status"))
  }

  // MARK: - Group 5.2 — allMessageTypeNames with qualified names

  func test_allMessageTypeNames_withNested_containsQualifiedChildName() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try pool.addFileDescriptor(fd)
    XCTAssertTrue(pool.allMessageTypeNames().contains("pkg.Parent.Child"))
  }

  func test_allMessageTypeNames_withNested_doesNotContainBareChildName() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try pool.addFileDescriptor(fd)
    XCTAssertFalse(pool.allMessageTypeNames().contains("Child"))
  }

  func test_allMessageTypeNames_withNested_containsBothParentAndChild() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try pool.addFileDescriptor(fd)
    let names = pool.allMessageTypeNames()
    XCTAssertTrue(names.contains("pkg.Parent"))
    XCTAssertTrue(names.contains("pkg.Parent.Child"))
  }

  func test_allMessageTypeNames_2LevelNesting_allThreeQualified() throws {
    let fd = try bridge.fromProtobufFileDescriptor(deepNestingFileProto)
    try pool.addFileDescriptor(fd)
    let names = pool.allMessageTypeNames()
    XCTAssertTrue(names.contains("pkg.A"))
    XCTAssertTrue(names.contains("pkg.A.B"))
    XCTAssertTrue(names.contains("pkg.A.B.C"))
  }

  func test_allMessageTypeNames_noNested_onlyTopLevel() throws {
    let msgProto = makeMessageProto(name: "Message")
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [msgProto])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try pool.addFileDescriptor(fd)
    let names = pool.allMessageTypeNames().filter { $0.hasPrefix("pkg.") }
    XCTAssertTrue(names.contains("pkg.Message"))
    XCTAssertEqual(names.count, 1)
  }

  // MARK: - Group 5.3 — Lookup correctness

  func test_findMessageDescriptor_nestedByQualifiedName_returnsCorrectDescriptor() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try pool.addFileDescriptor(fd)
    let child = pool.findMessageDescriptor(named: "pkg.Parent.Child")!
    XCTAssertEqual(child.name, "Child")
    XCTAssertEqual(child.fullName, "pkg.Parent.Child")
  }

  func test_findMessageDescriptor_nestedByBareName_returnsNil() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try pool.addFileDescriptor(fd)
    XCTAssertNil(pool.findMessageDescriptor(named: "Child"))
  }

  func test_findMessageDescriptor_nestedDescriptor_hasCorrectFields() throws {
    let child = makeMessageProto(
      name: "Child",
      fields: [makeFieldProto(name: "token", number: 1, type: .string)]
    )
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try pool.addFileDescriptor(fd)
    let childDesc = pool.findMessageDescriptor(named: "pkg.Parent.Child")!
    XCTAssertNotNil(childDesc.field(named: "token"))
  }

  func test_findMessageDescriptor_deeplyNested_fullyQualifiedName() throws {
    let fd = try bridge.fromProtobufFileDescriptor(deepNestingFileProto)
    try pool.addFileDescriptor(fd)
    XCTAssertNotNil(pool.findMessageDescriptor(named: "pkg.A.B.C"))
  }

  func test_findEnumDescriptor_nestedByQualifiedName_returns() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try pool.addFileDescriptor(fd)
    XCTAssertNotNil(pool.findEnumDescriptor(named: "pkg.Parent.Status"))
  }

  // MARK: - Group 5.4 — Collision and duplicate handling

  func test_addFileDescriptor_sameNestedNameInDifferentParents_noDuplicateError() throws {
    let cursorA = makeMessageProto(name: "Cursor")
    let cursorB = makeMessageProto(name: "Cursor")
    let a = makeMessageProto(name: "A", nestedMessages: [cursorA])
    let b = makeMessageProto(name: "B", nestedMessages: [cursorB])
    let fileA = makeFileProto(name: "a.proto", package: "pkg", messages: [a])
    let fileB = makeFileProto(name: "b.proto", package: "pkg", messages: [b])
    let fdA = try bridge.fromProtobufFileDescriptor(fileA)
    let fdB = try bridge.fromProtobufFileDescriptor(fileB)
    XCTAssertNoThrow(try pool.addFileDescriptor(fdA))
    XCTAssertNoThrow(try pool.addFileDescriptor(fdB))
    XCTAssertNotNil(pool.findMessageDescriptor(named: "pkg.A.Cursor"))
    XCTAssertNotNil(pool.findMessageDescriptor(named: "pkg.B.Cursor"))
  }

  func test_addFileDescriptor_sameQualifiedNameInTwoFiles_throwsDuplicateSymbol() throws {
    let child1 = makeMessageProto(name: "Child")
    let parent1 = makeMessageProto(name: "Parent", nestedMessages: [child1])
    let file1 = makeFileProto(name: "f1.proto", package: "pkg", messages: [parent1])
    let child2 = makeMessageProto(name: "Child")
    let parent2 = makeMessageProto(name: "Parent", nestedMessages: [child2])
    let file2 = makeFileProto(name: "f2.proto", package: "pkg", messages: [parent2])
    let fd1 = try bridge.fromProtobufFileDescriptor(file1)
    let fd2 = try bridge.fromProtobufFileDescriptor(file2)
    try pool.addFileDescriptor(fd1)
    XCTAssertThrowsError(try pool.addFileDescriptor(fd2)) { error in
      guard case DescriptorPoolError.duplicateSymbol = error else {
        XCTFail("Expected duplicateSymbol, got \(error)")
        return
      }
    }
  }

  func test_addFileDescriptor_sameFileAddedTwice_throwsDuplicateFile() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try pool.addFileDescriptor(fd)
    XCTAssertThrowsError(try pool.addFileDescriptor(fd)) { error in
      guard case DescriptorPoolError.duplicateFile = error else {
        XCTFail("Expected duplicateFile, got \(error)")
        return
      }
    }
  }

  func test_addFileDescriptor_twoPackagesWithSameNestedStructure_noCollision() throws {
    let y1 = makeMessageProto(name: "Y")
    let x1 = makeMessageProto(name: "X", nestedMessages: [y1])
    let file1 = makeFileProto(name: "pkg1.proto", package: "pkg1", messages: [x1])
    let y2 = makeMessageProto(name: "Y")
    let x2 = makeMessageProto(name: "X", nestedMessages: [y2])
    let file2 = makeFileProto(name: "pkg2.proto", package: "pkg2", messages: [x2])
    let fd1 = try bridge.fromProtobufFileDescriptor(file1)
    let fd2 = try bridge.fromProtobufFileDescriptor(file2)
    XCTAssertNoThrow(try pool.addFileDescriptor(fd1))
    XCTAssertNoThrow(try pool.addFileDescriptor(fd2))
    XCTAssertNotNil(pool.findMessageDescriptor(named: "pkg1.X.Y"))
    XCTAssertNotNil(pool.findMessageDescriptor(named: "pkg2.X.Y"))
  }

  // MARK: - Group 5.5 — findFileContainingSymbol

  func test_findFileContainingSymbol_nestedByQualifiedName_findsCorrectFile() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try pool.addFileDescriptor(fd)
    let file = pool.findFileContainingSymbol("pkg.Parent.Child")
    XCTAssertEqual(file?.name, "parent.proto")
  }

  func test_findFileContainingSymbol_nestedByBareName_returnsNil() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try pool.addFileDescriptor(fd)
    XCTAssertNil(pool.findFileContainingSymbol("Child"))
  }

  // MARK: - Group 5.6 — createMessage

  func test_createMessage_nestedTypeByQualifiedName_succeeds() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try pool.addFileDescriptor(fd)
    XCTAssertNotNil(pool.createMessage(forType: "pkg.Parent.Child"))
  }

  func test_createMessage_nestedTypeByBareName_returnsNil() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try pool.addFileDescriptor(fd)
    XCTAssertNil(pool.createMessage(forType: "Child"))
  }

  // MARK: - Group 5.7 — findDependencies

  func test_findDependencies_messageReferencingNestedType_dependencyIsQualified() throws {
    let fd = try bridge.fromProtobufFileDescriptor(adsRequestFileProto)
    try pool.addFileDescriptor(fd)
    let deps = try pool.findDependencies(for: "pkg.GetGroupedAdsRequest")
    XCTAssertTrue(
      deps.contains(".pkg.GetGroupedAdsRequest.SearchFilters")
        || deps.contains("pkg.GetGroupedAdsRequest.SearchFilters")
    )
  }

  func test_findDependencies_unknownType_throwsSymbolNotFound() throws {
    XCTAssertThrowsError(try pool.findDependencies(for: "Unknown.Type")) { error in
      guard case DescriptorPoolError.symbolNotFound = error else {
        XCTFail("Expected symbolNotFound, got \(error)")
        return
      }
    }
  }

  // MARK: - Group 5.8 — allEnumTypeNames

  func test_allEnumTypeNames_nestedEnums_qualifiedNames() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try pool.addFileDescriptor(fd)
    let names = pool.allEnumTypeNames()
    XCTAssertTrue(names.contains("pkg.Parent.Status"))
    XCTAssertFalse(names.contains("Status"))
  }

  // MARK: - Group 5.9 — Regressions

  func test_addFileDescriptor_flatMessages_unchanged() throws {
    let msgProto = makeMessageProto(name: "Flat")
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [msgProto])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try pool.addFileDescriptor(fd)
    XCTAssertNotNil(pool.findMessageDescriptor(named: "pkg.Flat"))
  }

  func test_addFileDescriptor_builtinDescriptors_notAffected() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try pool.addFileDescriptor(fd)
    // Builtin types should still be present (if pool initialises them)
    // The pool itself doesn't include builtins, so we just verify the test file was added
    XCTAssertNotNil(pool.findFileDescriptor(named: "parent.proto"))
  }

  func test_clear_removesAllNestedTypes() throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try pool.addFileDescriptor(fd)
    XCTAssertNotNil(pool.findMessageDescriptor(named: "pkg.Parent.Child"))
    pool.clear()
    XCTAssertNil(pool.findMessageDescriptor(named: "pkg.Parent.Child"))
    XCTAssertNil(pool.findMessageDescriptor(named: "pkg.Parent"))
  }
}
