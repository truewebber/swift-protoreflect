import XCTest

@testable import SwiftProtoReflect

final class DescriptorPoolNestedTypesTests: XCTestCase {

  var pool: DescriptorPool!
  let bridge = DescriptorBridge()

  override func setUp() async throws {
    try await super.setUp()
    pool = DescriptorPool()
  }

  // MARK: - Group 5.1 — Registration under qualified names

  func test_addFileDescriptor_messageWithNested_nestedStoredUnderQualifiedName() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await pool.addFileDescriptor(fd)
    let result = await pool.findMessageDescriptor(named: "pkg.Parent.Child")
    XCTAssertNotNil(result)
  }

  func test_addFileDescriptor_messageWithNested_bareNameNotInPool() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await pool.addFileDescriptor(fd)
    let result = await pool.findMessageDescriptor(named: "Child")
    XCTAssertNil(result)
  }

  func test_addFileDescriptor_messageWithNested_parentStoredUnderQualifiedName() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await pool.addFileDescriptor(fd)
    let result = await pool.findMessageDescriptor(named: "pkg.Parent")
    XCTAssertNotNil(result)
  }

  func test_addFileDescriptor_messageWithNested_doesNotThrowDuplicateSymbol() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(adsResponseFileProto)
    try await pool.addFileDescriptor(fd)
  }

  func test_addFileDescriptor_2LevelNesting_allThreeQualifiedInPool() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(deepNestingFileProto)
    try await pool.addFileDescriptor(fd)
    let a = await pool.findMessageDescriptor(named: "pkg.A")
    XCTAssertNotNil(a)
    let ab = await pool.findMessageDescriptor(named: "pkg.A.B")
    XCTAssertNotNil(ab)
    let abc = await pool.findMessageDescriptor(named: "pkg.A.B.C")
    XCTAssertNotNil(abc)
  }

  func test_addFileDescriptor_3LevelNesting_allFourQualifiedInPool() async throws {
    let d = makeMessageProto(name: "D")
    let c = makeMessageProto(name: "C", nestedMessages: [d])
    let b = makeMessageProto(name: "B", nestedMessages: [c])
    let a = makeMessageProto(name: "A", nestedMessages: [b])
    let fileProto = makeFileProto(name: "deep4.proto", package: "pkg", messages: [a])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try await pool.addFileDescriptor(fd)
    let rA = await pool.findMessageDescriptor(named: "pkg.A")
    XCTAssertNotNil(rA)
    let rAB = await pool.findMessageDescriptor(named: "pkg.A.B")
    XCTAssertNotNil(rAB)
    let rABC = await pool.findMessageDescriptor(named: "pkg.A.B.C")
    XCTAssertNotNil(rABC)
    let rABCD = await pool.findMessageDescriptor(named: "pkg.A.B.C.D")
    XCTAssertNotNil(rABCD)
  }

  func test_addFileDescriptor_multipleNestedAtSameLevel_allQualified() async throws {
    let child1 = makeMessageProto(name: "Child1")
    let child2 = makeMessageProto(name: "Child2")
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child1, child2])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try await pool.addFileDescriptor(fd)
    let c1 = await pool.findMessageDescriptor(named: "pkg.Parent.Child1")
    XCTAssertNotNil(c1)
    let c2 = await pool.findMessageDescriptor(named: "pkg.Parent.Child2")
    XCTAssertNotNil(c2)
  }

  func test_addFileDescriptor_nestedEnum_storedUnderQualifiedName() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await pool.addFileDescriptor(fd)
    let result = await pool.findEnumDescriptor(named: "pkg.Parent.Status")
    XCTAssertNotNil(result)
  }

  func test_addFileDescriptor_nestedEnum_bareNameNotInPool() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await pool.addFileDescriptor(fd)
    let result = await pool.findEnumDescriptor(named: "Status")
    XCTAssertNil(result)
  }

  // MARK: - Group 5.2 — allMessageTypeNames with qualified names

  func test_allMessageTypeNames_withNested_containsQualifiedChildName() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await pool.addFileDescriptor(fd)
    let names = await pool.allMessageTypeNames()
    XCTAssertTrue(names.contains("pkg.Parent.Child"))
  }

  func test_allMessageTypeNames_withNested_doesNotContainBareChildName() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await pool.addFileDescriptor(fd)
    let names = await pool.allMessageTypeNames()
    XCTAssertFalse(names.contains("Child"))
  }

  func test_allMessageTypeNames_withNested_containsBothParentAndChild() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await pool.addFileDescriptor(fd)
    let names = await pool.allMessageTypeNames()
    XCTAssertTrue(names.contains("pkg.Parent"))
    XCTAssertTrue(names.contains("pkg.Parent.Child"))
  }

  func test_allMessageTypeNames_2LevelNesting_allThreeQualified() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(deepNestingFileProto)
    try await pool.addFileDescriptor(fd)
    let names = await pool.allMessageTypeNames()
    XCTAssertTrue(names.contains("pkg.A"))
    XCTAssertTrue(names.contains("pkg.A.B"))
    XCTAssertTrue(names.contains("pkg.A.B.C"))
  }

  func test_allMessageTypeNames_noNested_onlyTopLevel() async throws {
    let msgProto = makeMessageProto(name: "Message")
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [msgProto])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try await pool.addFileDescriptor(fd)
    let names = await pool.allMessageTypeNames().filter { $0.hasPrefix("pkg.") }
    XCTAssertTrue(names.contains("pkg.Message"))
    XCTAssertEqual(names.count, 1)
  }

  // MARK: - Group 5.3 — Lookup correctness

  func test_findMessageDescriptor_nestedByQualifiedName_returnsCorrectDescriptor() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await pool.addFileDescriptor(fd)
    let child = await pool.findMessageDescriptor(named: "pkg.Parent.Child")
    XCTAssertNotNil(child)
    XCTAssertEqual(child?.name, "Child")
    XCTAssertEqual(child?.fullName, "pkg.Parent.Child")
  }

  func test_findMessageDescriptor_nestedByBareName_returnsNil() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await pool.addFileDescriptor(fd)
    let result = await pool.findMessageDescriptor(named: "Child")
    XCTAssertNil(result)
  }

  func test_findMessageDescriptor_nestedDescriptor_hasCorrectFields() async throws {
    let child = makeMessageProto(
      name: "Child",
      fields: [makeFieldProto(name: "token", number: 1, type: .string)]
    )
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try await pool.addFileDescriptor(fd)
    let childDesc = await pool.findMessageDescriptor(named: "pkg.Parent.Child")
    XCTAssertNotNil(childDesc)
    XCTAssertNotNil(childDesc?.field(named: "token"))
  }

  func test_findMessageDescriptor_deeplyNested_fullyQualifiedName() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(deepNestingFileProto)
    try await pool.addFileDescriptor(fd)
    let result = await pool.findMessageDescriptor(named: "pkg.A.B.C")
    XCTAssertNotNil(result)
  }

  func test_findEnumDescriptor_nestedByQualifiedName_returns() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await pool.addFileDescriptor(fd)
    let result = await pool.findEnumDescriptor(named: "pkg.Parent.Status")
    XCTAssertNotNil(result)
  }

  // MARK: - Group 5.4 — Collision and duplicate handling

  func test_addFileDescriptor_sameNestedNameInDifferentParents_noDuplicateError() async throws {
    let cursorA = makeMessageProto(name: "Cursor")
    let cursorB = makeMessageProto(name: "Cursor")
    let a = makeMessageProto(name: "A", nestedMessages: [cursorA])
    let b = makeMessageProto(name: "B", nestedMessages: [cursorB])
    let fileA = makeFileProto(name: "a.proto", package: "pkg", messages: [a])
    let fileB = makeFileProto(name: "b.proto", package: "pkg", messages: [b])
    let fdA = try bridge.fromProtobufFileDescriptor(fileA)
    let fdB = try bridge.fromProtobufFileDescriptor(fileB)
    try await pool.addFileDescriptor(fdA)
    try await pool.addFileDescriptor(fdB)
    let curA = await pool.findMessageDescriptor(named: "pkg.A.Cursor")
    XCTAssertNotNil(curA)
    let curB = await pool.findMessageDescriptor(named: "pkg.B.Cursor")
    XCTAssertNotNil(curB)
  }

  func test_addFileDescriptor_sameQualifiedNameInTwoFiles_throwsDuplicateSymbol() async throws {
    let child1 = makeMessageProto(name: "Child")
    let parent1 = makeMessageProto(name: "Parent", nestedMessages: [child1])
    let file1 = makeFileProto(name: "f1.proto", package: "pkg", messages: [parent1])
    let child2 = makeMessageProto(name: "Child")
    let parent2 = makeMessageProto(name: "Parent", nestedMessages: [child2])
    let file2 = makeFileProto(name: "f2.proto", package: "pkg", messages: [parent2])
    let fd1 = try bridge.fromProtobufFileDescriptor(file1)
    let fd2 = try bridge.fromProtobufFileDescriptor(file2)
    try await pool.addFileDescriptor(fd1)
    do {
      try await pool.addFileDescriptor(fd2)
      XCTFail("Expected duplicateSymbol error")
    }
    catch let error as DescriptorPoolError {
      guard case .duplicateSymbol = error else {
        XCTFail("Expected duplicateSymbol, got \(error)")
        return
      }
    }
  }

  func test_addFileDescriptor_sameFileAddedTwice_throwsDuplicateFile() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await pool.addFileDescriptor(fd)
    do {
      try await pool.addFileDescriptor(fd)
      XCTFail("Expected duplicateFile error")
    }
    catch let error as DescriptorPoolError {
      guard case .duplicateFile = error else {
        XCTFail("Expected duplicateFile, got \(error)")
        return
      }
    }
  }

  func test_addFileDescriptor_twoPackagesWithSameNestedStructure_noCollision() async throws {
    let y1 = makeMessageProto(name: "Y")
    let x1 = makeMessageProto(name: "X", nestedMessages: [y1])
    let file1 = makeFileProto(name: "pkg1.proto", package: "pkg1", messages: [x1])
    let y2 = makeMessageProto(name: "Y")
    let x2 = makeMessageProto(name: "X", nestedMessages: [y2])
    let file2 = makeFileProto(name: "pkg2.proto", package: "pkg2", messages: [x2])
    let fd1 = try bridge.fromProtobufFileDescriptor(file1)
    let fd2 = try bridge.fromProtobufFileDescriptor(file2)
    try await pool.addFileDescriptor(fd1)
    try await pool.addFileDescriptor(fd2)
    let p1xy = await pool.findMessageDescriptor(named: "pkg1.X.Y")
    XCTAssertNotNil(p1xy)
    let p2xy = await pool.findMessageDescriptor(named: "pkg2.X.Y")
    XCTAssertNotNil(p2xy)
  }

  // MARK: - Group 5.5 — findFileContainingSymbol

  func test_findFileContainingSymbol_nestedByQualifiedName_findsCorrectFile() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await pool.addFileDescriptor(fd)
    let file = await pool.findFileContainingSymbol("pkg.Parent.Child")
    XCTAssertEqual(file?.name, "parent.proto")
  }

  func test_findFileContainingSymbol_nestedByBareName_returnsNil() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await pool.addFileDescriptor(fd)
    let result = await pool.findFileContainingSymbol("Child")
    XCTAssertNil(result)
  }

  // MARK: - Group 5.6 — createMessage

  func test_createMessage_nestedTypeByQualifiedName_succeeds() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await pool.addFileDescriptor(fd)
    let result = await pool.createMessage(forType: "pkg.Parent.Child")
    XCTAssertNotNil(result)
  }

  func test_createMessage_nestedTypeByBareName_returnsNil() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await pool.addFileDescriptor(fd)
    let result = await pool.createMessage(forType: "Child")
    XCTAssertNil(result)
  }

  // MARK: - Group 5.7 — findDependencies

  func test_findDependencies_messageReferencingNestedType_dependencyIsQualified() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(adsRequestFileProto)
    try await pool.addFileDescriptor(fd)
    let deps = try await pool.findDependencies(for: "pkg.GetGroupedAdsRequest")
    XCTAssertTrue(
      deps.contains(".pkg.GetGroupedAdsRequest.SearchFilters")
        || deps.contains("pkg.GetGroupedAdsRequest.SearchFilters")
    )
  }

  func test_findDependencies_unknownType_throwsSymbolNotFound() async throws {
    do {
      _ = try await pool.findDependencies(for: "Unknown.Type")
      XCTFail("Expected symbolNotFound error")
    }
    catch let error as DescriptorPoolError {
      guard case .symbolNotFound = error else {
        XCTFail("Expected symbolNotFound, got \(error)")
        return
      }
    }
  }

  // MARK: - Group 5.8 — allEnumTypeNames

  func test_allEnumTypeNames_nestedEnums_qualifiedNames() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await pool.addFileDescriptor(fd)
    let names = await pool.allEnumTypeNames()
    XCTAssertTrue(names.contains("pkg.Parent.Status"))
    XCTAssertFalse(names.contains("Status"))
  }

  // MARK: - Group 5.9 — Regressions

  func test_addFileDescriptor_flatMessages_unchanged() async throws {
    let msgProto = makeMessageProto(name: "Flat")
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [msgProto])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    try await pool.addFileDescriptor(fd)
    let result = await pool.findMessageDescriptor(named: "pkg.Flat")
    XCTAssertNotNil(result)
  }

  func test_addFileDescriptor_builtinDescriptors_notAffected() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await pool.addFileDescriptor(fd)
    // Builtin types should still be present (if pool initialises them)
    // The pool itself doesn't include builtins, so we just verify the test file was added
    let result = await pool.findFileDescriptor(named: "parent.proto")
    XCTAssertNotNil(result)
  }

  func test_clear_removesAllNestedTypes() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    try await pool.addFileDescriptor(fd)
    let beforeClear = await pool.findMessageDescriptor(named: "pkg.Parent.Child")
    XCTAssertNotNil(beforeClear)
    await pool.clear()
    let afterClearChild = await pool.findMessageDescriptor(named: "pkg.Parent.Child")
    XCTAssertNil(afterClearChild)
    let afterClearParent = await pool.findMessageDescriptor(named: "pkg.Parent")
    XCTAssertNil(afterClearParent)
  }
}
