import XCTest

@testable import SwiftProtoReflect

final class DescriptorParentProtocolTests: XCTestCase {

  // MARK: - Group 4.1 — FileDescriptor conformance

  func test_fileDescriptor_descriptorFullNamePrefix_equalsPackage() {
    let fd = FileDescriptor(name: "f.proto", package: "pkg")
    XCTAssertEqual(fd.descriptorFullNamePrefix, "pkg")
  }

  func test_fileDescriptor_descriptorFullNamePrefix_emptyPackage() {
    let fd = FileDescriptor(name: "f.proto", package: "")
    XCTAssertEqual(fd.descriptorFullNamePrefix, "")
  }

  func test_fileDescriptor_descriptorFilePath_equalsName() {
    let fd = FileDescriptor(name: "f.proto", package: "pkg")
    XCTAssertEqual(fd.descriptorFilePath, "f.proto")
  }

  func test_fileDescriptor_descriptorSyntax_equalsFileSyntax() {
    let fd = FileDescriptor(name: "f.proto", package: "pkg", syntax: "proto3")
    XCTAssertEqual(fd.descriptorSyntax, "proto3")
  }

  func test_fileDescriptor_descriptorParentMessageFullName_isNil() {
    let fd = FileDescriptor(name: "f.proto", package: "pkg")
    XCTAssertNil(fd.descriptorParentMessageFullName)
  }

  func test_fileDescriptor_conformsToDescriptorParent() {
    let fd = FileDescriptor(name: "f.proto", package: "pkg")
    let _: any DescriptorParent = fd
  }

  // MARK: - Group 4.2 — MessageDescriptor conformance

  func test_messageDescriptor_descriptorFullNamePrefix_equalsFullName() {
    let msg = MessageDescriptor(name: "Msg", fullName: "pkg.Msg")
    XCTAssertEqual(msg.descriptorFullNamePrefix, "pkg.Msg")
  }

  func test_messageDescriptor_descriptorFilePath_equalsFileDescriptorPath() {
    var msg = MessageDescriptor(name: "Msg", fullName: "pkg.Msg")
    msg.fileDescriptorPath = "f.proto"
    XCTAssertEqual(msg.descriptorFilePath, "f.proto")
  }

  func test_messageDescriptor_descriptorFilePath_nilWhenNotSet() {
    let msg = MessageDescriptor(name: "Msg", fullName: "Msg")
    XCTAssertNil(msg.descriptorFilePath)
  }

  func test_messageDescriptor_descriptorSyntax_equalsSyntax() {
    let msg = MessageDescriptor(name: "M", fullName: "M", syntax: "proto2")
    XCTAssertEqual(msg.descriptorSyntax, "proto2")
  }

  func test_messageDescriptor_descriptorParentMessageFullName_equalsFullName() {
    let msg = MessageDescriptor(name: "M", fullName: "pkg.Parent.M")
    XCTAssertEqual(msg.descriptorParentMessageFullName, "pkg.Parent.M")
  }

  func test_messageDescriptor_conformsToDescriptorParent() {
    let msg = MessageDescriptor(name: "Msg", fullName: "pkg.Msg")
    let _: any DescriptorParent = msg
  }

  // MARK: - Group 4.3 — Protocol usage in init / factory functions

  func test_descriptorParent_fileDescriptor_usedInMessageDescriptorInit_fullNameCorrect() {
    let fd = FileDescriptor(name: "f.proto", package: "pkg")
    let msg = MessageDescriptor(name: "Msg", parent: fd)
    XCTAssertEqual(msg.fullName, "pkg.Msg")
  }

  func test_descriptorParent_messageDescriptor_usedInMessageDescriptorInit_fullNameCorrect() {
    let parentMsg = MessageDescriptor(name: "Parent", fullName: "pkg.Parent")
    let child = MessageDescriptor(name: "Child", parent: parentMsg)
    XCTAssertEqual(child.fullName, "pkg.Parent.Child")
  }

  func test_descriptorParent_fileDescriptor_usedInEnumDescriptorInit_fullNameCorrect() {
    let fd = FileDescriptor(name: "f.proto", package: "pkg")
    let e = EnumDescriptor(name: "Status", parent: fd)
    XCTAssertEqual(e.fullName, "pkg.Status")
  }

  func test_descriptorParent_messageDescriptor_usedInEnumDescriptorInit_fullNameCorrect() {
    let parentMsg = MessageDescriptor(name: "Parent", fullName: "pkg.Parent")
    let e = EnumDescriptor(name: "Status", parent: parentMsg)
    XCTAssertEqual(e.fullName, "pkg.Parent.Status")
  }

  func test_descriptorParent_nil_messageDescriptorInit_fullNameEqualsName() {
    let msg = MessageDescriptor(name: "Msg", parent: nil as (any DescriptorParent)?)
    XCTAssertEqual(msg.fullName, "Msg")
  }

  func test_descriptorParent_nil_enumDescriptorInit_fullNameEqualsName() {
    let e = EnumDescriptor(name: "Status", parent: nil as (any DescriptorParent)?)
    XCTAssertEqual(e.fullName, "Status")
  }
}
