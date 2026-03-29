//
// Proto2DescriptorTests.swift
// SwiftProtoReflect
//
// Tests for proto2-specific descriptor features.
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class Proto2DescriptorTests: XCTestCase {

  // MARK: - 1.0 MessageDescriptor.syntax

  func test_messageDescriptor_syntax_defaultIsProto3() {
    let desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    XCTAssertEqual(desc.syntax, "proto3")
  }

  func test_messageDescriptor_syntax_setExplicitly() {
    let desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    XCTAssertEqual(desc.syntax, "proto2")
  }

  func test_messageDescriptor_syntax_emptyNormalisedToProto2() {
    let desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "")
    XCTAssertEqual(desc.syntax, "proto2")
  }

  func test_fileDescriptor_addMessage_propagatesSyntax() {
    var file = FileDescriptor(name: "test.proto", package: "test", syntax: "proto2")
    let msg = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    file.addMessage(msg)

    XCTAssertEqual(file.messages["Msg"]?.syntax, "proto2")
  }

  func test_fileDescriptor_addMessage_propagatesSyntaxProto3() {
    var file = FileDescriptor(name: "test.proto", package: "test", syntax: "proto3")
    let msg = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto2")
    file.addMessage(msg)

    XCTAssertEqual(file.messages["Msg"]?.syntax, "proto3")
  }

  func test_messageDescriptor_addNestedMessage_propagatesSyntax() {
    var parent = MessageDescriptor(name: "Parent", fullName: "test.Parent", syntax: "proto2")
    let child = MessageDescriptor(name: "Child", fullName: "test.Parent.Child")
    parent.addNestedMessage(child)

    XCTAssertEqual(parent.nestedMessages["Child"]?.syntax, "proto2")
  }

  func test_messageDescriptor_initWithParentFile_inheritsSyntax() {
    let file = FileDescriptor(name: "test.proto", package: "test", syntax: "proto2")
    let msg = MessageDescriptor(name: "Msg", parent: file)

    XCTAssertEqual(msg.syntax, "proto2")
  }

  func test_messageDescriptor_initWithParentMessage_inheritsSyntax() {
    let parent = MessageDescriptor(name: "Parent", fullName: "test.Parent", syntax: "proto2")
    let child = MessageDescriptor(name: "Child", parent: parent)

    XCTAssertEqual(child.syntax, "proto2")
  }

  func test_messageDescriptor_initWithNilParent_usesDefaultProto3() {
    let msg = MessageDescriptor(name: "Msg", parent: nil)
    XCTAssertEqual(msg.syntax, "proto3")
  }

  // MARK: - 1.1 ExtensionRange and Extensions

  func test_messageDescriptor_addExtensionRange_stored() {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    let range = ExtensionRange(start: 100, end: 200)
    desc.addExtensionRange(range)

    XCTAssertEqual(desc.extensionRanges.count, 1)
    XCTAssertEqual(desc.extensionRanges[0].start, 100)
    XCTAssertEqual(desc.extensionRanges[0].end, 200)
  }

  func test_messageDescriptor_addMultipleExtensionRanges() {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addExtensionRange(ExtensionRange(start: 100, end: 200))
    desc.addExtensionRange(ExtensionRange(start: 300, end: 400))

    XCTAssertEqual(desc.extensionRanges.count, 2)
  }

  func test_messageDescriptor_addExtension_stored() {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addExtensionRange(ExtensionRange(start: 100, end: 200))
    let extField = FieldDescriptor(name: "ext_field", number: 100, type: .string)
    desc.addExtension(extField)

    XCTAssertEqual(desc.extensions.count, 1)
    XCTAssertEqual(desc.extensions[100]?.name, "ext_field")
  }

  func test_messageDescriptor_isExtensionNumber_true_inRange() {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addExtensionRange(ExtensionRange(start: 100, end: 200))

    XCTAssertTrue(desc.isExtensionNumber(100))
    XCTAssertTrue(desc.isExtensionNumber(150))
    XCTAssertTrue(desc.isExtensionNumber(199))
  }

  func test_messageDescriptor_isExtensionNumber_false_outsideRange() {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addExtensionRange(ExtensionRange(start: 100, end: 200))

    XCTAssertFalse(desc.isExtensionNumber(99))
    XCTAssertFalse(desc.isExtensionNumber(200))
    XCTAssertFalse(desc.isExtensionNumber(50))
  }

  func test_messageDescriptor_isExtensionNumber_false_noRanges() {
    let desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    XCTAssertFalse(desc.isExtensionNumber(100))
  }

  func test_extensionRange_equatable() {
    let a = ExtensionRange(start: 100, end: 200)
    let b = ExtensionRange(start: 100, end: 200)
    let c = ExtensionRange(start: 100, end: 300)

    XCTAssertEqual(a, b)
    XCTAssertNotEqual(a, c)
  }

  // MARK: - 1.2 FieldDescriptor defaultValue in ==

  func test_fieldDescriptor_defaultValue_includedInEquality() {
    let a = FieldDescriptor(
      name: "f",
      number: 1,
      type: .string,
      defaultValue: .string("hello")
    )
    let b = FieldDescriptor(
      name: "f",
      number: 1,
      type: .string,
      defaultValue: .string("world")
    )

    XCTAssertNotEqual(a, b)
  }

  func test_fieldDescriptor_defaultValue_nil_equalToNil() {
    let a = FieldDescriptor(name: "f", number: 1, type: .string)
    let b = FieldDescriptor(name: "f", number: 1, type: .string)

    XCTAssertEqual(a, b)
  }

  func test_fieldDescriptor_defaultValue_sameValue_equal() {
    let a = FieldDescriptor(
      name: "f",
      number: 1,
      type: .int32,
      defaultValue: .int(42)
    )
    let b = FieldDescriptor(
      name: "f",
      number: 1,
      type: .int32,
      defaultValue: .int(42)
    )

    XCTAssertEqual(a, b)
  }

  func test_fieldDescriptor_defaultValue_nilVsValue_notEqual() {
    let a = FieldDescriptor(name: "f", number: 1, type: .string)
    let b = FieldDescriptor(
      name: "f",
      number: 1,
      type: .string,
      defaultValue: .string("")
    )

    XCTAssertNotEqual(a, b)
  }

  // MARK: - 1.3 DescriptorOption.double

  func test_descriptorOption_double_storedCorrectly() {
    let option = DescriptorOption.double(3.14)
    if case .double(let v) = option {
      XCTAssertEqual(v, 3.14, accuracy: 0.001)
    }
    else {
      XCTFail("Expected .double case")
    }
  }

  func test_descriptorOption_double_asAny() {
    let option = DescriptorOption.double(2.718)
    let value = option.asAny
    XCTAssertTrue(value is Double)
    guard let doubleValue = value as? Double else {
      XCTFail("Expected Double")
      return
    }
    XCTAssertEqual(doubleValue, 2.718, accuracy: 0.001)
  }

  func test_descriptorOption_double_equatable() {
    let a = DescriptorOption.double(1.5)
    let b = DescriptorOption.double(1.5)
    let c = DescriptorOption.double(2.5)

    XCTAssertEqual(a, b)
    XCTAssertNotEqual(a, c)
  }

  func test_descriptorOption_double_notEqualToFloat() {
    let d = DescriptorOption.double(1.5)
    let f = DescriptorOption.float(1.5)

    XCTAssertNotEqual(d, f)
  }

  // MARK: - 1.4 EnumDescriptor.validateProto2

  func test_enumDescriptor_validateProto2_noValueZero_valid() {
    var enumDesc = EnumDescriptor(name: "Priority", fullName: "test.Priority")
    enumDesc.addValue(.init(name: "LOW", number: 1))
    enumDesc.addValue(.init(name: "HIGH", number: 2))

    let errors = enumDesc.validateProto2()
    XCTAssertTrue(errors.isEmpty, "Proto2 enum without zero value should be valid")
  }

  func test_enumDescriptor_validateProto2_withValueZero_valid() {
    var enumDesc = EnumDescriptor(name: "Status", fullName: "test.Status")
    enumDesc.addValue(.init(name: "UNKNOWN", number: 0))
    enumDesc.addValue(.init(name: "ACTIVE", number: 1))

    let errors = enumDesc.validateProto2()
    XCTAssertTrue(errors.isEmpty)
  }

  func test_enumDescriptor_validateProto2_empty_invalid() {
    let enumDesc = EnumDescriptor(name: "Empty", fullName: "test.Empty")

    let errors = enumDesc.validateProto2()
    XCTAssertFalse(errors.isEmpty)
    XCTAssertTrue(errors[0].contains("at least one value"))
  }

  func test_enumDescriptor_validateProto3_noZero_vs_validateProto2_noZero() {
    var enumDesc = EnumDescriptor(name: "Priority", fullName: "test.Priority")
    enumDesc.addValue(.init(name: "LOW", number: 1))

    let proto3Errors = enumDesc.validateProto3()
    let proto2Errors = enumDesc.validateProto2()

    XCTAssertFalse(proto3Errors.isEmpty, "Proto3 should fail without zero value")
    XCTAssertTrue(proto2Errors.isEmpty, "Proto2 should pass without zero value")
  }

  // MARK: - 1.5 FieldDescriptor.isPacked

  func test_fieldDescriptor_isPacked_nil_byDefault() {
    let field = FieldDescriptor(name: "values", number: 1, type: .int32, isRepeated: true)
    XCTAssertNil(field.isPacked)
  }

  func test_fieldDescriptor_isPacked_true_whenSet() {
    let field = FieldDescriptor(
      name: "values",
      number: 1,
      type: .int32,
      isRepeated: true,
      isPacked: true
    )
    XCTAssertEqual(field.isPacked, true)
  }

  func test_fieldDescriptor_isPacked_false_whenSet() {
    let field = FieldDescriptor(
      name: "values",
      number: 1,
      type: .int32,
      isRepeated: true,
      isPacked: false
    )
    XCTAssertEqual(field.isPacked, false)
  }

  func test_fieldDescriptor_effectiveIsPacked_nilInProto3_true() {
    let field = FieldDescriptor(name: "values", number: 1, type: .int32, isRepeated: true)
    XCTAssertTrue(field.effectiveIsPacked(syntax: "proto3"))
  }

  func test_fieldDescriptor_effectiveIsPacked_nilInProto2_false() {
    let field = FieldDescriptor(name: "values", number: 1, type: .int32, isRepeated: true)
    XCTAssertFalse(field.effectiveIsPacked(syntax: "proto2"))
  }

  func test_fieldDescriptor_effectiveIsPacked_explicitTrue_proto2_true() {
    let field = FieldDescriptor(
      name: "values",
      number: 1,
      type: .int32,
      isRepeated: true,
      isPacked: true
    )
    XCTAssertTrue(field.effectiveIsPacked(syntax: "proto2"))
  }

  func test_fieldDescriptor_effectiveIsPacked_explicitFalse_proto3_false() {
    let field = FieldDescriptor(
      name: "values",
      number: 1,
      type: .int32,
      isRepeated: true,
      isPacked: false
    )
    XCTAssertFalse(field.effectiveIsPacked(syntax: "proto3"))
  }

  func test_fieldDescriptor_isPacked_includedInEquality() {
    let a = FieldDescriptor(
      name: "values",
      number: 1,
      type: .int32,
      isRepeated: true,
      isPacked: true
    )
    let b = FieldDescriptor(
      name: "values",
      number: 1,
      type: .int32,
      isRepeated: true,
      isPacked: false
    )

    XCTAssertNotEqual(a, b)
  }

  func test_fieldDescriptor_isPacked_nilEqualsNil() {
    let a = FieldDescriptor(name: "values", number: 1, type: .int32, isRepeated: true)
    let b = FieldDescriptor(name: "values", number: 1, type: .int32, isRepeated: true)

    XCTAssertEqual(a, b)
  }

  // MARK: - Default value for every scalar type

  func test_fieldDescriptor_defaultValue_everyScalarType() {
    let cases: [(FieldType, DescriptorOption)] = [
      (.int32, .int(42)),
      (.int64, .int(100)),
      (.string, .string("hello")),
      (.bool, .bool(true)),
      (.bytes, .bytes(Data([0x01, 0x02]))),
      (.float, .float(1.5)),
      (.double, .double(3.14)),
    ]

    for (fieldType, defaultVal) in cases {
      let field = FieldDescriptor(
        name: "f",
        number: 1,
        type: fieldType,
        defaultValue: defaultVal
      )
      XCTAssertEqual(field.defaultValue, defaultVal, "Default for \(fieldType) should be stored")
    }
  }
}
