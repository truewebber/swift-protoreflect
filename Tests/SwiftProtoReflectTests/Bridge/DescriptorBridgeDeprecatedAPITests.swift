import XCTest

@testable import SwiftProtoReflect

// swiftlint:disable deprecated_usage
@available(*, deprecated)
final class DescriptorBridgeDeprecatedAPITests: XCTestCase {

  let bridge = DescriptorBridge()

  // MARK: - Group 3b.1 — fromProtobufDescriptor(parent: FileDescriptor?) wrapper

  func test_fromProtobufDescriptor_deprecatedFileDescriptorWrapper_withFileDescriptor_succeeds() throws {
    let fd = FileDescriptor(name: "t.proto", package: "pkg")
    let msgProto = makeMessageProto(name: "Message")
    let result = try bridge.fromProtobufDescriptor(msgProto, parent: fd as FileDescriptor?)
    XCTAssertEqual(result.fullName, "pkg.Message")
  }

  func test_fromProtobufDescriptor_deprecatedFileDescriptorWrapper_withNil_succeeds() throws {
    let msgProto = makeMessageProto(name: "Message")
    let result = try bridge.fromProtobufDescriptor(msgProto, parent: nil as FileDescriptor?)
    XCTAssertEqual(result.fullName, "Message")
  }

  func test_fromProtobufDescriptor_deprecatedFileDescriptorWrapper_nestedFullNamesQualified() throws {
    let child = makeMessageProto(name: "Child")
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child])
    let fd = FileDescriptor(name: "t.proto", package: "pkg")
    let result = try bridge.fromProtobufDescriptor(parent, parent: fd as FileDescriptor?)
    XCTAssertEqual(result.nestedMessages["Child"]?.fullName, "pkg.Parent.Child")
  }

  // MARK: - Group 3b.2 — fromProtobufEnumDescriptor(parent: Any?) wrapper

  func test_fromProtobufEnumDescriptor_deprecatedAnyWrapper_withFileDescriptor_delegatesCorrectly() throws {
    let fd = FileDescriptor(name: "t.proto", package: "pkg")
    let enumProto = makeEnumProto(name: "Status", values: [("UNKNOWN", 0)])
    let result = try bridge.fromProtobufEnumDescriptor(enumProto, parent: fd as Any)
    XCTAssertEqual(result.fullName, "pkg.Status")
  }

  func test_fromProtobufEnumDescriptor_deprecatedAnyWrapper_withMessageDescriptor_delegatesCorrectly() throws {
    let parentMsg = MessageDescriptor(name: "Parent", fullName: "pkg.Parent")
    let enumProto = makeEnumProto(name: "Status", values: [("UNKNOWN", 0)])
    let result = try bridge.fromProtobufEnumDescriptor(enumProto, parent: parentMsg as Any)
    XCTAssertEqual(result.fullName, "pkg.Parent.Status")
  }

  func test_fromProtobufEnumDescriptor_deprecatedAnyWrapper_withWrongType_treatsAsNilParent() throws {
    let enumProto = makeEnumProto(name: "Status", values: [("UNKNOWN", 0)])
    let result = try bridge.fromProtobufEnumDescriptor(enumProto, parent: "wrong_type" as Any)
    XCTAssertEqual(result.fullName, "Status")
  }

  // MARK: - Group 3b.3 — MessageDescriptor.init(name:parent: Any?) wrapper

  func test_messageDescriptorInit_deprecatedAnyWrapper_withFileDescriptor_delegatesCorrectly() {
    let fd = FileDescriptor(name: "t.proto", package: "pkg")
    let result = MessageDescriptor(name: "X", parent: fd as Any)
    XCTAssertEqual(result.fullName, "pkg.X")
  }

  func test_messageDescriptorInit_deprecatedAnyWrapper_withMessageDescriptor_delegatesCorrectly() {
    let parentMsg = MessageDescriptor(name: "Parent", fullName: "pkg.Parent")
    let result = MessageDescriptor(name: "Child", parent: parentMsg as Any)
    XCTAssertEqual(result.fullName, "pkg.Parent.Child")
  }

  func test_messageDescriptorInit_deprecatedAnyWrapper_withWrongType_treatsAsNilParent() {
    let result = MessageDescriptor(name: "X", parent: "some_string" as Any)
    XCTAssertEqual(result.fullName, "X")
  }

  // MARK: - Group 3b.4 — EnumDescriptor.init(name:parent: Any?) wrapper

  func test_enumDescriptorInit_deprecatedAnyWrapper_withFileDescriptor_delegatesCorrectly() {
    let fd = FileDescriptor(name: "t.proto", package: "pkg")
    let result = EnumDescriptor(name: "Status", parent: fd as Any)
    XCTAssertEqual(result.fullName, "pkg.Status")
  }

  func test_enumDescriptorInit_deprecatedAnyWrapper_withWrongType_treatsAsNilParent() {
    let result = EnumDescriptor(name: "Status", parent: 42 as Any)
    XCTAssertEqual(result.fullName, "Status")
  }
}
// swiftlint:enable deprecated_usage
