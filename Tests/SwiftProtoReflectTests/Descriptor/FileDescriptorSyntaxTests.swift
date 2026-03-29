//
// FileDescriptorSyntaxTests.swift
// SwiftProtoReflectTests
//

import XCTest

import struct SwiftProtobuf.Google_Protobuf_FileDescriptorProto

@testable import SwiftProtoReflect

final class FileDescriptorSyntaxTests: XCTestCase {

  // MARK: - Properties

  private var bridge: DescriptorBridge!

  // MARK: - Setup

  override func setUp() {
    super.setUp()
    bridge = DescriptorBridge()
  }

  override func tearDown() {
    bridge = nil
    super.tearDown()
  }

  // MARK: - FileDescriptor Init Tests

  func test_init_defaultSyntax_isProto3() {
    let fd = FileDescriptor(name: "test.proto", package: "test")
    XCTAssertEqual(fd.syntax, "proto3")
  }

  func test_init_explicitProto3_storesSyntax() {
    let fd = FileDescriptor(name: "test.proto", package: "test", syntax: "proto3")
    XCTAssertEqual(fd.syntax, "proto3")
  }

  func test_init_explicitProto2_storesSyntax() {
    let fd = FileDescriptor(name: "test.proto", package: "test", syntax: "proto2")
    XCTAssertEqual(fd.syntax, "proto2")
  }

  func test_init_emptySyntax_treatedAsProto2() {
    let fd = FileDescriptor(name: "test.proto", package: "test", syntax: "")
    XCTAssertEqual(fd.syntax, "proto2")
  }

  func test_init_unknownSyntax_storedAsIs() {
    let fd = FileDescriptor(name: "test.proto", package: "test", syntax: "proto4")
    XCTAssertEqual(fd.syntax, "proto4")
  }

  // MARK: - Bridge: fromProtobufFileDescriptor

  func test_bridgeFromProtobuf_proto3Syntax_preserved() throws {
    var proto = Google_Protobuf_FileDescriptorProto()
    proto.name = "test.proto"
    proto.package = "test"
    proto.syntax = "proto3"

    let fd = try bridge.fromProtobufFileDescriptor(proto)
    XCTAssertEqual(fd.syntax, "proto3")
  }

  func test_bridgeFromProtobuf_proto2Syntax_preserved() throws {
    var proto = Google_Protobuf_FileDescriptorProto()
    proto.name = "test.proto"
    proto.package = "test"
    proto.syntax = "proto2"

    let fd = try bridge.fromProtobufFileDescriptor(proto)
    XCTAssertEqual(fd.syntax, "proto2")
  }

  func test_bridgeFromProtobuf_emptySyntax_defaultsToProto2() throws {
    var proto = Google_Protobuf_FileDescriptorProto()
    proto.name = "test.proto"
    proto.package = "test"

    let fd = try bridge.fromProtobufFileDescriptor(proto)
    XCTAssertEqual(fd.syntax, "proto2")
  }

  // MARK: - Bridge: toProtobufFileDescriptor

  func test_bridgeToProtobuf_proto3Syntax_preserved() throws {
    let fd = FileDescriptor(name: "test.proto", package: "test", syntax: "proto3")
    let proto = try bridge.toProtobufFileDescriptor(from: fd)
    XCTAssertEqual(proto.syntax, "proto3")
  }

  func test_bridgeToProtobuf_proto2Syntax_preserved() throws {
    let fd = FileDescriptor(name: "test.proto", package: "test", syntax: "proto2")
    let proto = try bridge.toProtobufFileDescriptor(from: fd)
    XCTAssertEqual(proto.syntax, "proto2")
  }

  // MARK: - Round-trip

  func test_bridgeRoundTrip_syntaxPreserved() throws {
    let original = FileDescriptor(name: "test.proto", package: "test", syntax: "proto3")
    let proto = try bridge.toProtobufFileDescriptor(from: original)
    let restored = try bridge.fromProtobufFileDescriptor(proto)
    XCTAssertEqual(restored.syntax, original.syntax)
  }

  // MARK: - Syntax Comparison

  func test_equality_differentSyntax_notEqual() {
    let fd1 = FileDescriptor(name: "test.proto", package: "test", syntax: "proto2")
    let fd2 = FileDescriptor(name: "test.proto", package: "test", syntax: "proto3")
    XCTAssertNotEqual(fd1.syntax, fd2.syntax)
  }

  func test_equality_sameSyntax_equal() {
    let fd1 = FileDescriptor(name: "test.proto", package: "test", syntax: "proto3")
    let fd2 = FileDescriptor(name: "test.proto", package: "test", syntax: "proto3")
    XCTAssertEqual(fd1.syntax, fd2.syntax)
    XCTAssertEqual(fd1.name, fd2.name)
    XCTAssertEqual(fd1.package, fd2.package)
  }
}
