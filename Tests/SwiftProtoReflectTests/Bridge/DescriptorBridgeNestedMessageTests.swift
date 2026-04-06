import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class DescriptorBridgeNestedMessageTests: XCTestCase {

  let bridge = DescriptorBridge()

  // MARK: - Group 1.1 — fullName computation for nested messages (core fix)

  func test_fromProtobufDescriptor_flatMessage_withPackage_fullNameIncludesPackage() async throws {
    let fileProto = makeFileProto(
      name: "test.proto",
      package: "pkg",
      messages: [makeMessageProto(name: "Person")]
    )
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    XCTAssertEqual(fd.messages["Person"]?.fullName, "pkg.Person")
  }

  func test_fromProtobufDescriptor_flatMessage_emptyPackage_fullNameEqualsName() async throws {
    let fileProto = makeFileProto(
      name: "test.proto",
      package: "",
      messages: [makeMessageProto(name: "Person")]
    )
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    XCTAssertEqual(fd.messages["Person"]?.fullName, "Person")
  }

  func test_fromProtobufDescriptor_nestedMessage_fullNameIsQualified() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    let parent = fd.messages["Parent"]!
    XCTAssertEqual(parent.nestedMessages["Child"]?.fullName, "pkg.Parent.Child")
  }

  func test_fromProtobufDescriptor_nestedMessage_parentFullNameUnchangedAfterAdd() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    XCTAssertEqual(fd.messages["Parent"]?.fullName, "pkg.Parent")
  }

  func test_fromProtobufDescriptor_nestedMessage_bareNameNeverUsedAsFullName() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    let child = fd.messages["Parent"]!.nestedMessages["Child"]!
    XCTAssertNotEqual(child.fullName, "Child")
  }

  func test_fromProtobufDescriptor_nestedMessage_emptyPackage_noPackagePrefix() async throws {
    let child = makeMessageProto(name: "Child")
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child])
    let fileProto = makeFileProto(name: "t.proto", package: "", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    XCTAssertEqual(fd.messages["Parent"]!.nestedMessages["Child"]?.fullName, "Parent.Child")
  }

  func test_fromProtobufDescriptor_doubleNestedMessage_allFullNamesQualified() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(deepNestingFileProto)
    let a = fd.messages["A"]!
    let b = a.nestedMessages["B"]!
    let c = b.nestedMessages["C"]!
    XCTAssertEqual(a.fullName, "pkg.A")
    XCTAssertEqual(b.fullName, "pkg.A.B")
    XCTAssertEqual(c.fullName, "pkg.A.B.C")
  }

  func test_fromProtobufDescriptor_tripleNestedMessage_fullyQualified() async throws {
    let d = makeMessageProto(name: "D")
    let c = makeMessageProto(name: "C", nestedMessages: [d])
    let b = makeMessageProto(name: "B", nestedMessages: [c])
    let a = makeMessageProto(name: "A", nestedMessages: [b])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [a])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let dMsg = fd.messages["A"]!.nestedMessages["B"]!.nestedMessages["C"]!.nestedMessages["D"]!
    XCTAssertEqual(dMsg.fullName, "pkg.A.B.C.D")
  }

  func test_fromProtobufDescriptor_multipleNestedMessages_eachGetsOwnQualifiedName() async throws {
    let child1 = makeMessageProto(name: "Child1")
    let child2 = makeMessageProto(name: "Child2")
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child1, child2])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let p = fd.messages["Parent"]!
    XCTAssertEqual(p.nestedMessages["Child1"]?.fullName, "pkg.Parent.Child1")
    XCTAssertEqual(p.nestedMessages["Child2"]?.fullName, "pkg.Parent.Child2")
  }

  func test_fromProtobufDescriptor_nestedMessage_storedUnderSimpleNameInDict() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    let parent = fd.messages["Parent"]!
    XCTAssertNotNil(parent.nestedMessages["Child"])
    XCTAssertNil(parent.nestedMessages["pkg.Parent.Child"])
  }

  func test_fromProtobufDescriptor_nestedMessage_sameNameAsParent_stillQualified() async throws {
    let inner = makeMessageProto(
      name: "A",
      fields: [makeFieldProto(name: "x", number: 1, type: .string)]
    )
    let outer = makeMessageProto(name: "A", nestedMessages: [inner])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [outer])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let innerMsg = fd.messages["A"]!.nestedMessages["A"]!
    XCTAssertEqual(innerMsg.fullName, "pkg.A.A")
  }

  // MARK: - Group 1.2 — Inherited properties

  func test_fromProtobufDescriptor_nestedMessage_inheritsParentSyntax() async throws {
    let fileProto = makeFileProto(
      name: "t.proto",
      package: "pkg",
      syntax: "proto3",
      messages: [makeMessageProto(name: "Parent", nestedMessages: [makeMessageProto(name: "Child")])]
    )
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    XCTAssertEqual(fd.messages["Parent"]!.nestedMessages["Child"]!.syntax, "proto3")
  }

  func test_fromProtobufDescriptor_nestedMessage_inheritsSyntaxProto2() async throws {
    let fileProto = makeFileProto(
      name: "t.proto",
      package: "pkg",
      syntax: "proto2",
      messages: [makeMessageProto(name: "Parent", nestedMessages: [makeMessageProto(name: "Child")])]
    )
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    XCTAssertEqual(fd.messages["Parent"]!.nestedMessages["Child"]!.syntax, "proto2")
  }

  func test_fromProtobufDescriptor_nestedMessage_inheritsFileDescriptorPath() async throws {
    let fileProto = makeFileProto(
      name: "myfile.proto",
      package: "pkg",
      messages: [makeMessageProto(name: "Parent", nestedMessages: [makeMessageProto(name: "Child")])]
    )
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    XCTAssertEqual(fd.messages["Parent"]!.nestedMessages["Child"]!.fileDescriptorPath, "myfile.proto")
  }

  func test_fromProtobufDescriptor_nestedMessage_parentMessageFullNameSet() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    let child = fd.messages["Parent"]!.nestedMessages["Child"]!
    XCTAssertEqual(child.parentMessageFullName, "pkg.Parent")
  }

  func test_fromProtobufDescriptor_nestedMessage_fieldsPreserved() async throws {
    let child = makeMessageProto(
      name: "Child",
      fields: [makeFieldProto(name: "name", number: 1, type: .string)]
    )
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    XCTAssertEqual(fd.messages["Parent"]!.nestedMessages["Child"]!.field(number: 1)?.name, "name")
  }

  // MARK: - Group 1.3 — fromProtobufDescriptor with explicit parents

  func test_fromProtobufDescriptor_withFileDescriptorParent_behaviorUnchanged() async throws {
    let fileDesc = FileDescriptor(name: "t.proto", package: "pkg")
    let msgProto = makeMessageProto(name: "Message")
    let result = try bridge.fromProtobufDescriptor(msgProto, parent: fileDesc as any DescriptorParent)
    XCTAssertEqual(result.fullName, "pkg.Message")
  }

  func test_fromProtobufDescriptor_withMessageDescriptorParent_qualifiesCorrectly() async throws {
    let parentMsg = MessageDescriptor(name: "Outer", fullName: "pkg.Outer")
    let innerProto = makeMessageProto(name: "Inner")
    let result = try bridge.fromProtobufDescriptor(innerProto, parent: parentMsg)
    XCTAssertEqual(result.fullName, "pkg.Outer.Inner")
  }

  func test_fromProtobufDescriptor_withNilParent_fullNameEqualsName() async throws {
    let msgProto = makeMessageProto(name: "MessageName")
    let result = try bridge.fromProtobufDescriptor(msgProto, parent: nil as (any DescriptorParent)?)
    XCTAssertEqual(result.fullName, "MessageName")
  }

  // MARK: - Group 1.4 — fromProtobufFileDescriptor integration

  func test_fromProtobufFileDescriptor_messageWithNested_qualifiedFullNames() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    XCTAssertEqual(fd.messages["Parent"]?.fullName, "pkg.Parent")
    XCTAssertEqual(fd.messages["Parent"]?.nestedMessages["Child"]?.fullName, "pkg.Parent.Child")
  }

  func test_fromProtobufFileDescriptor_twoTopLevelMessagesEachWithNested() async throws {
    let xMsg = makeMessageProto(name: "X")
    let yMsg = makeMessageProto(name: "Y")
    let a = makeMessageProto(name: "A", nestedMessages: [xMsg])
    let b = makeMessageProto(name: "B", nestedMessages: [yMsg])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [a, b])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    XCTAssertEqual(fd.messages["A"]!.nestedMessages["X"]?.fullName, "pkg.A.X")
    XCTAssertEqual(fd.messages["B"]!.nestedMessages["Y"]?.fullName, "pkg.B.Y")
  }

  func test_fromProtobufFileDescriptor_3LevelNesting_allQualified() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(deepNestingFileProto)
    XCTAssertEqual(fd.messages["A"]?.fullName, "pkg.A")
    XCTAssertEqual(fd.messages["A"]?.nestedMessages["B"]?.fullName, "pkg.A.B")
    XCTAssertEqual(fd.messages["A"]?.nestedMessages["B"]?.nestedMessages["C"]?.fullName, "pkg.A.B.C")
  }

  func test_fromProtobufFileDescriptor_noPackage_nestedHasNoPackagePrefix() async throws {
    let child = makeMessageProto(name: "B")
    let parent = makeMessageProto(name: "A", nestedMessages: [child])
    let fileProto = makeFileProto(name: "t.proto", package: "", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    XCTAssertEqual(fd.messages["A"]?.nestedMessages["B"]?.fullName, "A.B")
  }

  // MARK: - Group 1.5 — Fields referencing nested types

  func test_fromProtobufDescriptor_fieldTypeName_notModifiedByBridge() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(adsResponseFileProto)
    let cursorField = fd.messages["GetGroupedAdsResponse"]!.field(named: "cursor")!
    XCTAssertEqual(cursorField.typeName, ".pkg.GetGroupedAdsResponse.Cursor")
  }

  func test_fromProtobufDescriptor_repeatedNestedMessageField_typeNamePreserved() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(adsResponseFileProto)
    let itemsField = fd.messages["GetGroupedAdsResponse"]!.field(named: "items")!
    XCTAssertEqual(itemsField.typeName, ".pkg.GetGroupedAdsResponse.Item")
  }

  func test_fromProtobufDescriptor_mapFieldWithNestedMessageValue_typeNamePreserved() async throws {
    var mapValue = Google_Protobuf_FieldDescriptorProto()
    mapValue.name = "value"
    mapValue.number = 2
    mapValue.type = .message
    mapValue.label = .optional
    mapValue.typeName = ".pkg.Parent.Child"

    var mapKey = Google_Protobuf_FieldDescriptorProto()
    mapKey.name = "key"
    mapKey.number = 1
    mapKey.type = .string
    mapKey.label = .optional

    var mapEntryOptions = Google_Protobuf_MessageOptions()
    mapEntryOptions.mapEntry = true
    var mapEntryProto = Google_Protobuf_DescriptorProto()
    mapEntryProto.name = "ChildMapEntry"
    mapEntryProto.field = [mapKey, mapValue]
    mapEntryProto.options = mapEntryOptions

    let mapField = makeFieldProto(
      name: "child_map",
      number: 1,
      type: .message,
      label: .repeated,
      typeName: ".pkg.Parent.ChildMapEntry"
    )
    let parent = makeMessageProto(name: "Parent", fields: [mapField], nestedMessages: [mapEntryProto])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let field = fd.messages["Parent"]!.field(named: "child_map")!
    XCTAssertTrue(field.isMap)
    XCTAssertEqual(field.mapEntryInfo?.valueFieldInfo.typeName, ".pkg.Parent.Child")
  }
}
