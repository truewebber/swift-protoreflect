//
// SerializerDeprecatedAPITests.swift
// SwiftProtoReflect
//
// Verifies that deprecated no-argument initializers for BinaryDeserializer,
// JSONSerializer, and JSONDeserializer still function correctly and produce
// instances equivalent to their options-based counterparts with an empty
// TypeRegistry.
//

import XCTest

@testable import SwiftProtoReflect

// swiftlint:disable deprecated_usage
final class SerializerDeprecatedAPITests: XCTestCase {

  // MARK: - BinaryDeserializer deprecated init

  func test_binaryDeserializer_deprecatedInit_createsInstanceWithDefaultOptions() {
    let deserializer = BinaryDeserializer()
    XCTAssertTrue(deserializer.options.preserveUnknownFields)
    XCTAssertTrue(deserializer.options.strictUTF8Validation)
    XCTAssertEqual(deserializer.options.typeRegistry.allFiles().count, 0)
  }

  func test_binaryDeserializer_deprecatedInit_matchesNewInitWithEmptyRegistry() {
    let deprecated = BinaryDeserializer()
    let explicit = BinaryDeserializer(options: .init(typeRegistry: TypeRegistry()))

    XCTAssertEqual(deprecated.options.preserveUnknownFields, explicit.options.preserveUnknownFields)
    XCTAssertEqual(deprecated.options.strictUTF8Validation, explicit.options.strictUTF8Validation)
    XCTAssertEqual(deprecated.options.typeRegistry.allFiles().count, explicit.options.typeRegistry.allFiles().count)
  }

  func test_binaryDeserializer_deprecatedInit_canDeserializeScalarMessage() throws {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    var msg = DynamicMessage(descriptor: desc)
    try msg.set(Int32(42), forField: 1)

    let serializer = BinarySerializer()
    let data = try serializer.serialize(msg)

    let deserializer = BinaryDeserializer()
    let result = try deserializer.deserialize(data, using: desc)
    XCTAssertEqual(try result.get(forField: 1) as? Int32, 42)
  }

  // MARK: - JSONSerializer deprecated init

  func test_jsonSerializer_deprecatedInit_createsInstanceWithDefaultOptions() {
    let serializer = JSONSerializer()
    XCTAssertFalse(serializer.options.useOriginalFieldNames)
    XCTAssertFalse(serializer.options.prettyPrinted)
    XCTAssertFalse(serializer.options.includeDefaultValues)
    XCTAssertEqual(serializer.options.typeRegistry.allFiles().count, 0)
  }

  func test_jsonSerializer_deprecatedInit_matchesNewInitWithEmptyRegistry() {
    let deprecated = JSONSerializer()
    let explicit = JSONSerializer(options: .init(typeRegistry: TypeRegistry()))

    XCTAssertEqual(deprecated.options.useOriginalFieldNames, explicit.options.useOriginalFieldNames)
    XCTAssertEqual(deprecated.options.prettyPrinted, explicit.options.prettyPrinted)
    XCTAssertEqual(deprecated.options.includeDefaultValues, explicit.options.includeDefaultValues)
    XCTAssertEqual(deprecated.options.typeRegistry.allFiles().count, explicit.options.typeRegistry.allFiles().count)
  }

  func test_jsonSerializer_deprecatedInit_canSerializeScalarMessage() throws {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addField(FieldDescriptor(name: "name", number: 1, type: .string, jsonName: "name"))
    var msg = DynamicMessage(descriptor: desc)
    try msg.set("hello", forField: 1)

    let serializer = JSONSerializer()
    let data = try serializer.serialize(msg)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertEqual(json?["name"] as? String, "hello")
  }

  // MARK: - JSONDeserializer deprecated init

  func test_jsonDeserializer_deprecatedInit_createsInstanceWithDefaultOptions() {
    let deserializer = JSONDeserializer()
    XCTAssertTrue(deserializer.options.ignoreUnknownFields)
    XCTAssertTrue(deserializer.options.strictTypeValidation)
    XCTAssertEqual(deserializer.options.maxNestingDepth, 64)
    XCTAssertEqual(deserializer.options.typeRegistry.allFiles().count, 0)
  }

  func test_jsonDeserializer_deprecatedInit_matchesNewInitWithEmptyRegistry() {
    let deprecated = JSONDeserializer()
    let explicit = JSONDeserializer(options: .init(typeRegistry: TypeRegistry()))

    XCTAssertEqual(deprecated.options.ignoreUnknownFields, explicit.options.ignoreUnknownFields)
    XCTAssertEqual(deprecated.options.strictTypeValidation, explicit.options.strictTypeValidation)
    XCTAssertEqual(deprecated.options.maxNestingDepth, explicit.options.maxNestingDepth)
    XCTAssertEqual(deprecated.options.typeRegistry.allFiles().count, explicit.options.typeRegistry.allFiles().count)
  }

  func test_jsonDeserializer_deprecatedInit_canDeserializeScalarMessage() throws {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg")
    desc.addField(FieldDescriptor(name: "name", number: 1, type: .string, jsonName: "name"))

    let json = #"{"name":"hello"}"#.data(using: .utf8)!
    let deserializer = JSONDeserializer()
    let result = try deserializer.deserialize(json, using: desc)
    XCTAssertEqual(try result.get(forField: 1) as? String, "hello")
  }

  // MARK: - Options deprecated inits

  func test_deserializationOptions_deprecatedInit_createsEmptyRegistry() {
    let options = DeserializationOptions()
    XCTAssertTrue(options.preserveUnknownFields)
    XCTAssertTrue(options.strictUTF8Validation)
    XCTAssertEqual(options.typeRegistry.allFiles().count, 0)
  }

  func test_deserializationOptions_deprecatedInit_matchesNewInit() {
    let deprecated = DeserializationOptions()
    let explicit = DeserializationOptions(typeRegistry: TypeRegistry())

    XCTAssertEqual(deprecated.preserveUnknownFields, explicit.preserveUnknownFields)
    XCTAssertEqual(deprecated.strictUTF8Validation, explicit.strictUTF8Validation)
    XCTAssertEqual(deprecated.typeRegistry.allFiles().count, explicit.typeRegistry.allFiles().count)
  }

  func test_jsonSerializationOptions_deprecatedInit_createsEmptyRegistry() {
    let options = JSONSerializationOptions()
    XCTAssertFalse(options.useOriginalFieldNames)
    XCTAssertFalse(options.prettyPrinted)
    XCTAssertFalse(options.includeDefaultValues)
    XCTAssertEqual(options.typeRegistry.allFiles().count, 0)
  }

  func test_jsonSerializationOptions_deprecatedInit_matchesNewInit() {
    let deprecated = JSONSerializationOptions()
    let explicit = JSONSerializationOptions(typeRegistry: TypeRegistry())

    XCTAssertEqual(deprecated.useOriginalFieldNames, explicit.useOriginalFieldNames)
    XCTAssertEqual(deprecated.prettyPrinted, explicit.prettyPrinted)
    XCTAssertEqual(deprecated.includeDefaultValues, explicit.includeDefaultValues)
    XCTAssertEqual(deprecated.typeRegistry.allFiles().count, explicit.typeRegistry.allFiles().count)
  }

  func test_jsonDeserializationOptions_deprecatedInit_createsEmptyRegistry() {
    let options = JSONDeserializationOptions()
    XCTAssertTrue(options.ignoreUnknownFields)
    XCTAssertTrue(options.strictTypeValidation)
    XCTAssertEqual(options.maxNestingDepth, 64)
    XCTAssertEqual(options.typeRegistry.allFiles().count, 0)
  }

  func test_jsonDeserializationOptions_deprecatedInit_matchesNewInit() {
    let deprecated = JSONDeserializationOptions()
    let explicit = JSONDeserializationOptions(typeRegistry: TypeRegistry())

    XCTAssertEqual(deprecated.ignoreUnknownFields, explicit.ignoreUnknownFields)
    XCTAssertEqual(deprecated.strictTypeValidation, explicit.strictTypeValidation)
    XCTAssertEqual(deprecated.maxNestingDepth, explicit.maxNestingDepth)
    XCTAssertEqual(deprecated.typeRegistry.allFiles().count, explicit.typeRegistry.allFiles().count)
  }

  func test_jsonSerializationOptions_deprecatedInitWithCustomValues_preservesSettings() {
    let options = JSONSerializationOptions(useOriginalFieldNames: true, prettyPrinted: true, includeDefaultValues: true)
    XCTAssertTrue(options.useOriginalFieldNames)
    XCTAssertTrue(options.prettyPrinted)
    XCTAssertTrue(options.includeDefaultValues)
    XCTAssertEqual(options.typeRegistry.allFiles().count, 0)
  }

  func test_deserializationOptions_deprecatedInitWithCustomValues_preservesSettings() {
    let options = DeserializationOptions(preserveUnknownFields: false, strictUTF8Validation: false)
    XCTAssertFalse(options.preserveUnknownFields)
    XCTAssertFalse(options.strictUTF8Validation)
    XCTAssertEqual(options.typeRegistry.allFiles().count, 0)
  }

  func test_jsonDeserializationOptions_deprecatedInitWithCustomValues_preservesSettings() {
    let options = JSONDeserializationOptions(
      ignoreUnknownFields: false,
      strictTypeValidation: false,
      maxNestingDepth: 10
    )
    XCTAssertFalse(options.ignoreUnknownFields)
    XCTAssertFalse(options.strictTypeValidation)
    XCTAssertEqual(options.maxNestingDepth, 10)
    XCTAssertEqual(options.typeRegistry.allFiles().count, 0)
  }

  // MARK: - MessageFactory.validate(_:syntax:) deprecated

  func test_messageFactory_deprecatedValidateWithSyntax_stillWorks() throws {
    var desc = MessageDescriptor(name: "Msg", fullName: "test.Msg", syntax: "proto3")
    desc.addField(FieldDescriptor(name: "req", number: 1, type: .string, isRequired: true))

    let msg = DynamicMessage(descriptor: desc)
    let factory = MessageFactory()

    let result = factory.validate(msg, syntax: "proto2")
    XCTAssertFalse(result.isValid, "Explicit syntax parameter should override descriptor.syntax")
  }
}
// swiftlint:enable deprecated_usage
