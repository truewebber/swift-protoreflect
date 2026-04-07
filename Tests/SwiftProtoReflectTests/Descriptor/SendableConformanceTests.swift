//
// SendableConformanceTests.swift
// SwiftProtoReflectTests
//
// Created: 2026-03-20
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

/// Verifies that all descriptor types explicitly conform to `Sendable`.
///
/// Each test assigns an instance to `any Sendable`, which is a compile-time
/// guarantee — the file won't build unless the conformance is declared.
final class SendableConformanceTests: XCTestCase {

  func test_fieldDescriptor_conformsSendable() async throws {
    let value = FieldDescriptor(name: "field", number: 1, type: .string)
    let _: any Sendable = value
  }

  func test_fieldType_conformsSendable() async throws {
    let value: FieldType = .string
    let _: any Sendable = value
  }

  func test_mapEntryInfo_conformsSendable() async throws {
    let key = KeyFieldInfo(name: "key", number: 1, type: .string)
    let val = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let value = MapEntryInfo(keyFieldInfo: key, valueFieldInfo: val)
    let _: any Sendable = value
  }

  func test_keyFieldInfo_conformsSendable() async throws {
    let value = KeyFieldInfo(name: "key", number: 1, type: .string)
    let _: any Sendable = value
  }

  func test_valueFieldInfo_conformsSendable() async throws {
    let value = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let _: any Sendable = value
  }

  func test_enumDescriptor_conformsSendable() async throws {
    let value = EnumDescriptor(name: "Status")
    let _: any Sendable = value
  }

  func test_enumValue_conformsSendable() async throws {
    let value = EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0)
    let _: any Sendable = value
  }

  func test_messageDescriptor_conformsSendable() async throws {
    let value = MessageDescriptor(name: "Msg", fullName: "pkg.Msg")
    let _: any Sendable = value
  }

  func test_fileDescriptor_conformsSendable() async throws {
    let value = FileDescriptor(name: "test.proto", package: "pkg")
    let _: any Sendable = value
  }

  func test_serviceDescriptor_conformsSendable() async throws {
    let file = FileDescriptor(name: "test.proto", package: "pkg")
    let value = ServiceDescriptor(name: "Svc", parent: file)
    let _: any Sendable = value
  }

  func test_methodDescriptor_conformsSendable() async throws {
    let value = ServiceDescriptor.MethodDescriptor(
      name: "DoWork",
      inputType: "Request",
      outputType: "Response"
    )
    let _: any Sendable = value
  }

  func test_oneofDescriptor_conformsSendable() async throws {
    let value = OneofDescriptor(name: "contact", index: 0)
    let _: any Sendable = value
  }

  func test_descriptorOption_conformsSendable() async throws {
    let value: DescriptorOption = .bool(true)
    let _: any Sendable = value
  }
}
