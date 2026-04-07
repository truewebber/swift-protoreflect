//
// PublicBridgeProtocComplianceTests.swift
// SwiftProtoReflectTests
//
// Covers uncovered paths in Public/Bridge.swift and Bridge/_StaticMessageBridge.swift:
//   - DescriptorBridgeError.init(from: _DescriptorBridgeError) — all 4 cases
//   - _DescriptorBridgeError.errorDescription — all 4 cases
//   - StaticMessageBridgeError.init(from: _StaticMessageBridgeError) — all 5 cases
//   - _StaticMessageBridgeError.errorDescription — all 5 cases
//   - Service descriptor bridge (toProtobuf / fromProtobuf) round-trip
//   - proto2 extension ranges via DescriptorBridge
//   - DynamicMessage.toStaticMessage(as:) convenience extension
//   - SwiftProtobuf.Message.toDynamicMessage(using:) and .toDynamicMessage() extensions
//

import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class PublicBridgeProtocComplianceTests: XCTestCase {

  private let bridge = DescriptorBridge()

  // MARK: - DescriptorBridgeError.init(from:) — all 4 cases

  // [PUBLIC-MIRROR] DescriptorBridgeTests.testErrorDescriptions()
  // Oracle: DescriptorBridgeError(from:) converts each _DescriptorBridgeError case correctly
  func test_descriptorBridgeError_initFromImpl_allCases() {
    let cases: [(_DescriptorBridgeError, DescriptorBridgeError)] = [
      (.unsupportedFieldType(99), .unsupportedFieldType(99)),
      (.conversionFailed("details"), .conversionFailed("details")),
      (.missingRequiredField("fieldName"), .missingRequiredField("fieldName")),
      (.invalidDescriptorStructure("info"), .invalidDescriptorStructure("info")),
    ]

    for (impl, expected) in cases {
      let pub = DescriptorBridgeError(from: impl)
      XCTAssertEqual(pub.errorDescription, expected.errorDescription)
    }
  }

  // MARK: - _DescriptorBridgeError.errorDescription — all 4 cases

  // [PUBLIC-MIRROR] DescriptorBridgeTests.testErrorDescriptions()
  // Oracle: each internal error has a non-empty human-readable description
  func test_internalDescriptorBridgeError_errorDescription_allCases() {
    let cases: [(error: _DescriptorBridgeError, contains: String)] = [
      (.unsupportedFieldType(42), "42"),
      (.conversionFailed("bad field"), "bad field"),
      (.missingRequiredField("id"), "id"),
      (.invalidDescriptorStructure("structure"), "structure"),
    ]

    for (error, substring) in cases {
      let desc = error.errorDescription
      XCTAssertNotNil(desc)
      XCTAssertTrue(desc!.contains(substring), "Expected '\(desc!)' to contain '\(substring)'")
    }
  }

  // MARK: - StaticMessageBridgeError.init(from:) — all 5 cases

  // [PUBLIC-MIRROR] StaticMessageBridgeTests.testErrorDescriptions()
  // Oracle: StaticMessageBridgeError(from:) converts each _StaticMessageBridgeError case correctly
  func test_staticMessageBridgeError_initFromImpl_allCases() {
    let underlyingError = NSError(domain: "test", code: 1)
    let cases: [(_StaticMessageBridgeError, StaticMessageBridgeError)] = [
      (
        .incompatibleTypes(staticType: "A", descriptorType: "B"),
        .incompatibleTypes(staticType: "A", descriptorType: "B")
      ),
      (.serializationFailed(underlying: underlyingError), .serializationFailed(underlying: underlyingError)),
      (
        .deserializationFailed(underlying: underlyingError),
        .deserializationFailed(underlying: underlyingError)
      ),
      (.descriptorCreationFailed(messageType: "Foo"), .descriptorCreationFailed(messageType: "Foo")),
      (.unsupportedMessageType("Bar"), .unsupportedMessageType("Bar")),
    ]

    for (impl, expected) in cases {
      let pub = StaticMessageBridgeError(from: impl)
      XCTAssertEqual(pub.errorDescription, expected.errorDescription)
    }
  }

  // MARK: - _StaticMessageBridgeError.errorDescription — all 5 cases

  // [PUBLIC-MIRROR] StaticMessageBridgeTests.testErrorDescriptions()
  // Oracle: each internal error has a non-empty human-readable description
  func test_internalStaticMessageBridgeError_errorDescription_allCases() {
    let underlyingError = NSError(domain: "test.domain", code: 42, userInfo: nil)
    let cases: [(error: _StaticMessageBridgeError, contains: String)] = [
      (.incompatibleTypes(staticType: "TypeX", descriptorType: "TypeY"), "TypeX"),
      (.serializationFailed(underlying: underlyingError), "Serialization"),
      (.deserializationFailed(underlying: underlyingError), "Deserialization"),
      (.descriptorCreationFailed(messageType: "MyMessage"), "MyMessage"),
      (.unsupportedMessageType("WeirdType"), "WeirdType"),
    ]

    for (error, substring) in cases {
      let desc = error.errorDescription
      XCTAssertNotNil(desc)
      XCTAssertTrue(desc!.contains(substring), "Expected '\(desc!)' to contain '\(substring)'")
    }
  }

  // MARK: - Service descriptor bridge round-trip

  // [PUBLIC-MIRROR] DescriptorBridgeTests.testServiceDescriptorToProtobuf()
  // Oracle: ServiceDescriptor converted to protobuf and back preserves name and methods
  func test_serviceDescriptorBridge_roundTrip_preservesNameAndMethods() throws {
    let fileDesc = FileDescriptor(name: "svc.proto", package: "pkg")
    var svc = ServiceDescriptor(name: "EchoService", parent: fileDesc)
    svc.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "Echo",
        inputType: "pkg.EchoRequest",
        outputType: "pkg.EchoResponse",
        clientStreaming: false,
        serverStreaming: false
      )
    )

    let proto = try bridge.toProtobufServiceDescriptor(from: svc)
    XCTAssertEqual(proto.name, "EchoService")
    XCTAssertEqual(proto.method.count, 1)
    XCTAssertEqual(proto.method[0].name, "Echo")

    let back = try bridge.fromProtobufServiceDescriptor(proto, parent: fileDesc)
    XCTAssertEqual(back.name, "EchoService")
    XCTAssertEqual(back.allMethods().count, 1)
    XCTAssertEqual(back.method(named: "Echo")?.name, "Echo")
  }

  // MARK: - proto2 extension ranges via DescriptorBridge

  // [PUBLIC-MIRROR] DescriptorBridgeRegressionTests.test_fromProtobufDescriptor_extensionRange_preservedCorrectly()
  // Oracle: extension ranges in proto2 messages are preserved during bridge round-trip
  func test_descriptorBridge_proto2ExtensionRanges_preservedOnRoundTrip() throws {
    var msgProto = Google_Protobuf_DescriptorProto()
    msgProto.name = "Extendable"
    var rangeProto = Google_Protobuf_DescriptorProto.ExtensionRange()
    rangeProto.start = 100
    rangeProto.end = 200
    msgProto.extensionRange = [rangeProto]

    let result = try bridge.fromProtobufDescriptor(msgProto, parent: nil as (any DescriptorParent)?)
    XCTAssertEqual(result.extensionRanges.count, 1)
    XCTAssertEqual(result.extensionRanges[0].start, 100)
    XCTAssertEqual(result.extensionRanges[0].end, 200)

    let back = try bridge.toProtobufDescriptor(from: result)
    XCTAssertEqual(back.extensionRange.count, 1)
    XCTAssertEqual(back.extensionRange[0].start, 100)
    XCTAssertEqual(back.extensionRange[0].end, 200)
  }

  // MARK: - DynamicMessage.toStaticMessage(as:) convenience extension

  // [PUBLIC-MIRROR] StaticMessageBridgeTests — DynamicMessage.toStaticMessage convenience method
  // Oracle: DynamicMessage.toStaticMessage(as:) delegates to StaticMessageBridge
  func test_dynamicMessage_toStaticMessage_convenienceExtension() throws {
    var desc = MessageDescriptor(name: "pkg.Empty", fullName: "pkg.Empty")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(7), forField: "id")

    let staticMsg = try msg.toStaticMessage(as: Google_Protobuf_Empty.self)
    XCTAssertNotNil(staticMsg)
  }

  // MARK: - SwiftProtobuf.Message.toDynamicMessage(using:) extension

  // [PUBLIC-MIRROR] StaticMessageBridgeTests — SwiftProtobuf.Message.toDynamicMessage(using:)
  // Oracle: toDynamicMessage(using:) converts static message to DynamicMessage with correct fields
  func test_swiftProtobufMessage_toDynamicMessageUsingDescriptor() throws {
    let staticMsg = Google_Protobuf_Empty()
    var desc = MessageDescriptor(name: "google.protobuf.Empty", fullName: "google.protobuf.Empty")

    let result = try staticMsg.toDynamicMessage(using: desc)
    XCTAssertNotNil(result)
    XCTAssertEqual(result.descriptor.name, "google.protobuf.Empty")
  }

  // MARK: - SwiftProtobuf.Message.toDynamicMessage() extension (auto descriptor)

  // [PUBLIC-MIRROR] StaticMessageBridgeTests — SwiftProtobuf.Message.toDynamicMessage() (auto descriptor)
  // Oracle: toDynamicMessage() without descriptor auto-creates descriptor and converts
  func test_swiftProtobufMessage_toDynamicMessageAutoDescriptor() throws {
    let staticMsg = Google_Protobuf_Empty()
    let result = try staticMsg.toDynamicMessage()
    XCTAssertNotNil(result)
  }
}
