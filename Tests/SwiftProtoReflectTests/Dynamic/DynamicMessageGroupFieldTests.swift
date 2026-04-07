//
// DynamicMessageGroupFieldTests.swift
// SwiftProtoReflectTests
//
// Covers uncovered paths in Dynamic/_DynamicMessage.swift:
//   - get(forField:) for .group type → returns from nestedMessages
//   - hasValue(forField:) for .group type → checks nestedMessages
//   - clearField for .group type
//   - resolveField via extensions dictionary (field lookup by number with extensions)
//   - validateValue for .group type when value IS a DynamicMessage (success path)
//

import Foundation
import XCTest

@testable import SwiftProtoReflect

final class DynamicMessageGroupFieldTests: XCTestCase {

  // MARK: - get(forField:) for .group type

  // [PUBLIC-MIRROR] DynamicMessageEdgeCaseTests.test_set_groupFieldWithString_throwsTypeMismatch()
  // Oracle: get for a group field returns value from nestedMessages storage
  func test_get_groupField_returnsStoredDynamicMessage() throws {
    var groupBodyDesc = _MessageDescriptor(name: "G", fullName: "M.G")
    groupBodyDesc.addField(_FieldDescriptor(name: "v", number: 1, type: .int32))

    var outerDesc = _MessageDescriptor(name: "M", fullName: "M")
    outerDesc.addField(
      _FieldDescriptor(name: "g", number: 1, type: .group, typeName: "M.G")
    )
    outerDesc.addNestedMessage(groupBodyDesc)

    var groupMsg = _DynamicMessage(descriptor: groupBodyDesc)
    try groupMsg.set(Int32(42), forField: 1)

    var outerMsg = _DynamicMessage(descriptor: outerDesc)
    try outerMsg.set(groupMsg, forField: 1)

    let retrieved = try outerMsg.get(forField: 1)
    XCTAssertNotNil(retrieved)
    XCTAssertTrue(retrieved is _DynamicMessage)
  }

  // MARK: - hasValue(forField:) for .group type

  // [PUBLIC-MIRROR] DynamicMessageEdgeCaseTests.test_set_groupFieldWithString_throwsTypeMismatch()
  // Oracle: hasValue for a group field checks nestedMessages storage
  func test_hasValue_groupField_returnsTrueWhenSet() throws {
    var groupBodyDesc = _MessageDescriptor(name: "G", fullName: "M.G")
    groupBodyDesc.addField(_FieldDescriptor(name: "v", number: 1, type: .int32))

    var outerDesc = _MessageDescriptor(name: "M", fullName: "M")
    outerDesc.addField(
      _FieldDescriptor(name: "g", number: 1, type: .group, typeName: "M.G")
    )
    outerDesc.addNestedMessage(groupBodyDesc)

    var outerMsg = _DynamicMessage(descriptor: outerDesc)
    XCTAssertFalse(try outerMsg.hasValue(forField: 1))

    var groupMsg = _DynamicMessage(descriptor: groupBodyDesc)
    try groupMsg.set(Int32(1), forField: 1)
    try outerMsg.set(groupMsg, forField: 1)

    XCTAssertTrue(try outerMsg.hasValue(forField: 1))
  }

  // MARK: - clearField for .group type

  // [PUBLIC-MIRROR] DynamicMessageExtendedTests — clearField by number
  // Oracle: clearField on a group field removes it from nestedMessages
  func test_clearField_groupField_removesValue() throws {
    var groupBodyDesc = _MessageDescriptor(name: "G", fullName: "M.G")
    groupBodyDesc.addField(_FieldDescriptor(name: "v", number: 1, type: .int32))

    var outerDesc = _MessageDescriptor(name: "M", fullName: "M")
    outerDesc.addField(
      _FieldDescriptor(name: "g", number: 1, type: .group, typeName: "M.G")
    )
    outerDesc.addNestedMessage(groupBodyDesc)

    var groupMsg = _DynamicMessage(descriptor: groupBodyDesc)
    try groupMsg.set(Int32(99), forField: 1)

    var outerMsg = _DynamicMessage(descriptor: outerDesc)
    try outerMsg.set(groupMsg, forField: 1)
    XCTAssertTrue(try outerMsg.hasValue(forField: 1))

    try outerMsg.clearField(1)
    XCTAssertFalse(try outerMsg.hasValue(forField: 1))
  }

  // MARK: - resolveField via extensions dictionary

  // [PUBLIC-MIRROR] Proto2BridgeTests — extension field access
  // Oracle: resolveField falls back to descriptor.extensions when regular field not found
  func test_get_extensionField_resolvedViaExtensionsDict() throws {
    var desc = _MessageDescriptor(name: "Extendable", fullName: "Extendable")
    desc.addField(_FieldDescriptor(name: "id", number: 1, type: .int32))

    let extField = _FieldDescriptor(name: "ext_name", number: 100, type: .string)
    desc.addExtension(extField)

    var msg = _DynamicMessage(descriptor: desc)
    try msg.set("extension_value", forField: 100)

    let retrieved = try msg.get(forField: 100)
    XCTAssertEqual(retrieved as? String, "extension_value")
    XCTAssertTrue(try msg.hasValue(forField: 100))
  }

  // MARK: - validateValue for .group type with correct DynamicMessage (success)

  // [PUBLIC-MIRROR] DynamicMessageEdgeCaseTests.test_set_groupFieldWithString_throwsTypeMismatch()
  // Oracle: setting a correct _DynamicMessage for a group field succeeds without error
  func test_set_groupField_withCorrectDynamicMessage_succeeds() throws {
    var groupBodyDesc = _MessageDescriptor(name: "G", fullName: "M.G")
    groupBodyDesc.addField(_FieldDescriptor(name: "v", number: 1, type: .int32))

    var outerDesc = _MessageDescriptor(name: "M", fullName: "M")
    outerDesc.addField(
      _FieldDescriptor(name: "g", number: 1, type: .group, typeName: "M.G")
    )

    var groupMsg = _DynamicMessage(descriptor: groupBodyDesc)
    try groupMsg.set(Int32(7), forField: 1)

    var outerMsg = _DynamicMessage(descriptor: outerDesc)
    XCTAssertNoThrow(try outerMsg.set(groupMsg, forField: 1))
  }
}
