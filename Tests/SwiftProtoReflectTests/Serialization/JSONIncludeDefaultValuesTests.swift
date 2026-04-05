//
// JSONIncludeDefaultValuesTests.swift
// SwiftProtoReflectTests
//

import XCTest

@testable import SwiftProtoReflect

final class JSONIncludeDefaultValuesTests: XCTestCase {

  // MARK: - Helpers

  private func makeDescriptor() -> MessageDescriptor {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addField(FieldDescriptor(name: "int_field", number: 1, type: .int32, jsonName: "intField"))
    desc.addField(FieldDescriptor(name: "str_field", number: 2, type: .string, jsonName: "strField"))
    desc.addField(FieldDescriptor(name: "bool_field", number: 3, type: .bool, jsonName: "boolField"))
    desc.addField(FieldDescriptor(name: "double_field", number: 4, type: .double, jsonName: "doubleField"))
    desc.addField(
      FieldDescriptor(name: "repeated_field", number: 5, type: .int32, jsonName: "repeatedField", isRepeated: true)
    )
    return desc
  }

  private func makeSerializer(includeDefaults: Bool, useOriginalNames: Bool = false) -> JSONSerializer {
    JSONSerializer(
      options: JSONSerializationOptions(
        useOriginalFieldNames: useOriginalNames,
        includeDefaultValues: includeDefaults,
        typeRegistry: TypeRegistry()
      )
    )
  }

  private func jsonDict(_ data: Data) throws -> [String: Any] {
    try JSONSerialization.jsonObject(with: data) as! [String: Any]
  }

  // MARK: - includeDefaultValues = true

  func test_includeDefaults_int32Field_emitsZero() throws {
    let desc = makeDescriptor()
    let msg = DynamicMessage(descriptor: desc)
    let serializer = makeSerializer(includeDefaults: true)
    let json = try jsonDict(serializer.serialize(msg))
    XCTAssertEqual(json["intField"] as? Int, 0)
  }

  func test_includeDefaults_stringField_emitsEmpty() throws {
    let desc = makeDescriptor()
    let msg = DynamicMessage(descriptor: desc)
    let serializer = makeSerializer(includeDefaults: true)
    let json = try jsonDict(serializer.serialize(msg))
    XCTAssertEqual(json["strField"] as? String, "")
  }

  func test_includeDefaults_boolField_emitsFalse() throws {
    let desc = makeDescriptor()
    let msg = DynamicMessage(descriptor: desc)
    let serializer = makeSerializer(includeDefaults: true)
    let json = try jsonDict(serializer.serialize(msg))
    XCTAssertEqual(json["boolField"] as? Bool, false)
  }

  func test_includeDefaults_doubleField_emitsZero() throws {
    let desc = makeDescriptor()
    let msg = DynamicMessage(descriptor: desc)
    let serializer = makeSerializer(includeDefaults: true)
    let json = try jsonDict(serializer.serialize(msg))
    XCTAssertEqual(json["doubleField"] as? Double, 0)
  }

  func test_includeDefaults_repeatedField_emitsEmptyArray() throws {
    let desc = makeDescriptor()
    let msg = DynamicMessage(descriptor: desc)
    let serializer = makeSerializer(includeDefaults: true)
    let json = try jsonDict(serializer.serialize(msg))
    let arr = json["repeatedField"] as? [Any]
    XCTAssertNotNil(arr)
    XCTAssertEqual(arr?.count, 0)
  }

  func test_includeDefaults_messageField_omitted() throws {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addField(
      FieldDescriptor(name: "nested", number: 1, type: .message, typeName: "test.Inner", jsonName: "nested")
    )
    let msg = DynamicMessage(descriptor: desc)
    let serializer = makeSerializer(includeDefaults: true)
    let json = try jsonDict(serializer.serialize(msg))
    XCTAssertNil(json["nested"], "Unset message fields should be omitted even with includeDefaultValues")
  }

  func test_includeDefaults_fieldSetToNonDefault_emitted() throws {
    let desc = makeDescriptor()
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(42), forField: 1)
    let serializer = makeSerializer(includeDefaults: true)
    let json = try jsonDict(serializer.serialize(msg))
    XCTAssertEqual(json["intField"] as? Int, 42)
  }

  func test_includeDefaults_mixedSetAndUnset_allPresent() throws {
    let desc = makeDescriptor()
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(42), forField: 1)
    try msg.set("hello", forField: 2)
    let serializer = makeSerializer(includeDefaults: true)
    let json = try jsonDict(serializer.serialize(msg))
    XCTAssertEqual(json["intField"] as? Int, 42)
    XCTAssertEqual(json["strField"] as? String, "hello")
    XCTAssertEqual(json["boolField"] as? Bool, false)
    XCTAssertEqual(json["doubleField"] as? Double, 0)
  }

  // MARK: - includeDefaultValues = false

  func test_includeDefaults_false_unsetFieldsOmitted() throws {
    let desc = makeDescriptor()
    let msg = DynamicMessage(descriptor: desc)
    let serializer = makeSerializer(includeDefaults: false)
    let json = try jsonDict(serializer.serialize(msg))
    XCTAssertTrue(json.isEmpty)
  }

  // MARK: - Respects useOriginalFieldNames

  func test_includeDefaults_respectsUseOriginalFieldNames() throws {
    let desc = makeDescriptor()
    let msg = DynamicMessage(descriptor: desc)
    let serializer = makeSerializer(includeDefaults: true, useOriginalNames: true)
    let json = try jsonDict(serializer.serialize(msg))
    XCTAssertNotNil(json["int_field"])
    XCTAssertNil(json["intField"])
  }

  // MARK: - Proto3 Optional with includeDefaults

  func test_includeDefaults_proto3OptionalNotSet_stillOmitted() throws {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addField(
      FieldDescriptor(
        name: "opt_value",
        number: 1,
        type: .int32,
        jsonName: "optValue",
        proto3Optional: true
      )
    )
    let msg = DynamicMessage(descriptor: desc)
    let serializer = makeSerializer(includeDefaults: true)
    let json = try jsonDict(serializer.serialize(msg))
    XCTAssertNil(json["optValue"], "Proto3 optional without value should be omitted even with includeDefaults")
  }

  // MARK: - Map field default

  func test_includeDefaults_mapField_emitsEmptyObject() throws {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    let mapEntry = MapEntryInfo(
      keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
      valueFieldInfo: ValueFieldInfo(name: "value", number: 2, type: .int32)
    )
    desc.addField(
      FieldDescriptor(
        name: "tags",
        number: 1,
        type: .message,
        typeName: "test.TagsEntry",
        jsonName: "tags",
        isMap: true,
        mapEntryInfo: mapEntry
      )
    )
    let msg = DynamicMessage(descriptor: desc)
    let serializer = makeSerializer(includeDefaults: true)
    let json = try jsonDict(serializer.serialize(msg))
    let obj = json["tags"] as? [String: Any]
    XCTAssertNotNil(obj)
    XCTAssertEqual(obj?.count, 0)
  }
}
