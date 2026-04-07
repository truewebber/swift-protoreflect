import XCTest

@testable import SwiftProtoReflect

final class DescriptorBridgeNestedEnumTests: XCTestCase {

  let bridge = DescriptorBridge()

  // MARK: - Group 2.1 — fullName computation for nested enums (core fix)

  func test_fromProtobufDescriptor_nestedEnum_fullNameIsQualified() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    let status = fd.messages["Parent"]!.nestedEnums["Status"]!
    XCTAssertEqual(status.fullName, "pkg.Parent.Status")
  }

  func test_fromProtobufDescriptor_nestedEnum_bareNameNeverUsedAsFullName() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    let status = fd.messages["Parent"]!.nestedEnums["Status"]!
    XCTAssertNotEqual(status.fullName, "Status")
  }

  func test_fromProtobufDescriptor_nestedEnum_parentMessageFullNameSet() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    let status = fd.messages["Parent"]!.nestedEnums["Status"]!
    XCTAssertEqual(status.parentMessageFullName, "pkg.Parent")
  }

  func test_fromProtobufDescriptor_nestedEnum_emptyPackage_noPackagePrefix() async throws {
    let status = makeEnumProto(name: "Status", values: [("UNKNOWN", 0)])
    let parent = makeMessageProto(name: "Parent", nestedEnums: [status])
    let fileProto = makeFileProto(name: "t.proto", package: "", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    XCTAssertEqual(fd.messages["Parent"]!.nestedEnums["Status"]?.fullName, "Parent.Status")
  }

  func test_fromProtobufDescriptor_multipleNestedEnums_eachQualified() async throws {
    let status = makeEnumProto(name: "Status", values: [("UNKNOWN", 0)])
    let typeEnum = makeEnumProto(name: "Type", values: [("NONE", 0)])
    let parent = makeMessageProto(name: "Parent", nestedEnums: [status, typeEnum])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    XCTAssertEqual(fd.messages["Parent"]!.nestedEnums["Status"]?.fullName, "pkg.Parent.Status")
    XCTAssertEqual(fd.messages["Parent"]!.nestedEnums["Type"]?.fullName, "pkg.Parent.Type")
  }

  func test_fromProtobufDescriptor_nestedEnum_inDoublyNestedMessage_fullyQualified() async throws {
    let color = makeEnumProto(name: "Color", values: [("RED", 0)])
    let b = makeMessageProto(name: "B", nestedEnums: [color])
    let a = makeMessageProto(name: "A", nestedMessages: [b])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [a])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let colorEnum = fd.messages["A"]!.nestedMessages["B"]!.nestedEnums["Color"]!
    XCTAssertEqual(colorEnum.fullName, "pkg.A.B.Color")
  }

  func test_fromProtobufDescriptor_nestedEnumAndNestedMessage_bothQualified() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    let parent = fd.messages["Parent"]!
    XCTAssertEqual(parent.nestedMessages["Child"]?.fullName, "pkg.Parent.Child")
    XCTAssertEqual(parent.nestedEnums["Status"]?.fullName, "pkg.Parent.Status")
  }

  func test_fromProtobufDescriptor_nestedEnum_valuesPreserved() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    let status = fd.messages["Parent"]!.nestedEnums["Status"]!
    XCTAssertEqual(status.allValues().count, 2)
    XCTAssertEqual(status.value(named: "UNKNOWN")?.number, 0)
    XCTAssertEqual(status.value(named: "ACTIVE")?.number, 1)
  }

  // MARK: - Group 2.2 — fromProtobufEnumDescriptor with explicit parents

  func test_fromProtobufEnumDescriptor_withMessageDescriptorParent_qualifiesCorrectly() async throws {
    let parentMsg = MessageDescriptor(name: "Parent", fullName: "pkg.Parent")
    let enumProto = makeEnumProto(name: "Status", values: [("UNKNOWN", 0)])
    let result = try bridge.fromProtobufEnumDescriptor(enumProto, parent: parentMsg)
    XCTAssertEqual(result.fullName, "pkg.Parent.Status")
  }

  func test_fromProtobufEnumDescriptor_withFileDescriptorParent_behaviorUnchanged() async throws {
    let fd = FileDescriptor(name: "t.proto", package: "pkg")
    let enumProto = makeEnumProto(name: "Status", values: [("UNKNOWN", 0)])
    let result = try bridge.fromProtobufEnumDescriptor(enumProto, parent: fd)
    XCTAssertEqual(result.fullName, "pkg.Status")
  }

  func test_fromProtobufEnumDescriptor_withNilParent_fullNameEqualsName() async throws {
    let enumProto = makeEnumProto(name: "Status", values: [("UNKNOWN", 0)])
    let result = try bridge.fromProtobufEnumDescriptor(enumProto, parent: nil as (any DescriptorParent)?)
    XCTAssertEqual(result.fullName, "Status")
  }

  // MARK: - Group 2.3 — Inherited properties and edge cases

  func test_fromProtobufDescriptor_nestedEnum_fileDescriptorPathInherited() async throws {
    let status = makeEnumProto(name: "Status", values: [("UNKNOWN", 0)])
    let parent = makeMessageProto(name: "Parent", nestedEnums: [status])
    let fileProto = makeFileProto(name: "myfile.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    XCTAssertEqual(fd.messages["Parent"]!.nestedEnums["Status"]?.fileDescriptorPath, "myfile.proto")
  }

  func test_fromProtobufDescriptor_nestedEnumSameNameAsNestedMessage_bothQualified() async throws {
    let statusMsg = makeMessageProto(name: "Status")
    let statusEnum = makeEnumProto(name: "Status", values: [("UNKNOWN", 0)])
    let parent = makeMessageProto(name: "Parent", nestedMessages: [statusMsg], nestedEnums: [statusEnum])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    XCTAssertEqual(fd.messages["Parent"]!.nestedEnums["Status"]?.fullName, "pkg.Parent.Status")
    XCTAssertEqual(fd.messages["Parent"]!.nestedMessages["Status"]?.fullName, "pkg.Parent.Status")
  }

  func test_fromProtobufDescriptor_nestedMessageWithItsOwnNestedEnum_qualifiedDeep() async throws {
    let childStatus = makeEnumProto(name: "ChildStatus", values: [("UNKNOWN", 0)])
    let child = makeMessageProto(name: "Child", nestedEnums: [childStatus])
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let childStatusEnum = fd.messages["Parent"]!.nestedMessages["Child"]!.nestedEnums["ChildStatus"]!
    XCTAssertEqual(childStatusEnum.fullName, "pkg.Parent.Child.ChildStatus")
  }

  func test_fromProtobufDescriptor_nestedEnum_noLeadingDot_noPackage() async throws {
    let status = makeEnumProto(name: "Status", values: [("UNKNOWN", 0)])
    let parent = makeMessageProto(name: "Parent", nestedEnums: [status])
    let fileProto = makeFileProto(name: "t.proto", package: "", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    let statusFullName = fd.messages["Parent"]!.nestedEnums["Status"]!.fullName
    XCTAssertFalse(statusFullName.hasPrefix("."))
  }

  func test_fromProtobufFileDescriptor_withNestedEnum_fullPipelineQualified() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    XCTAssertEqual(fd.messages["Parent"]?.nestedEnums["Status"]?.fullName, "pkg.Parent.Status")
  }

  func test_fromProtobufDescriptor_proto2Message_nestedEnum_qualified() async throws {
    let status = makeEnumProto(name: "Status", values: [("UNKNOWN", 0)])
    let parent = makeMessageProto(name: "Parent", nestedEnums: [status])
    let fileProto = makeFileProto(name: "t.proto", package: "pkg", syntax: "proto2", messages: [parent])
    let fd = try bridge.fromProtobufFileDescriptor(fileProto)
    XCTAssertEqual(fd.messages["Parent"]!.nestedEnums["Status"]?.fullName, "pkg.Parent.Status")
  }

  func test_fromProtobufDescriptor_nestedEnumValues_accessible() async throws {
    let fd = try bridge.fromProtobufFileDescriptor(parentWithEnumFileProto)
    let status = fd.messages["Parent"]!.nestedEnums["Status"]!
    XCTAssertEqual(status.value(named: "ACTIVE")?.number, 1)
  }
}
