//
// DescriptorBridgeDynamicMessageIntegrationTests.swift
// SwiftProtoReflectTests
//
// Created: 2025-02-04
//

import XCTest

import struct SwiftProtobuf.Google_Protobuf_DescriptorProto
import struct SwiftProtobuf.Google_Protobuf_FieldDescriptorProto
import struct SwiftProtobuf.Google_Protobuf_MessageOptions

@testable import SwiftProtoReflect

/// Integration tests for map fields detected by DescriptorBridge with DynamicMessage.
final class DescriptorBridgeDynamicMessageIntegrationTests: XCTestCase {

  // MARK: - Test Properties

  private var bridge: DescriptorBridge!

  // MARK: - Setup and Teardown

  override func setUp() {
    super.setUp()
    bridge = DescriptorBridge()
  }

  override func tearDown() {
    bridge = nil
    super.tearDown()
  }

  // MARK: - Integration Tests

  func testDynamicMessageWithDetectedStringToStringMap() throws {
    // Create message with map field
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "metadata",
      fieldNumber: 1,
      keyType: .string,
      valueType: .string
    )

    let messageDescriptor = try bridge.fromProtobufDescriptor(messageProto)

    // Create DynamicMessage and use detected map field
    var dynamicMsg = DynamicMessage(descriptor: messageDescriptor)

    // Set map entries
    try dynamicMsg.setMapEntry("value1", forKey: "key1", inField: "metadata")
    try dynamicMsg.setMapEntry("value2", forKey: "key2", inField: "metadata")

    // Get map and verify
    let metadata = try dynamicMsg.get(forField: "metadata") as? [String: String]
    XCTAssertNotNil(metadata)
    XCTAssertEqual(metadata?.count, 2)
    XCTAssertEqual(metadata?["key1"], "value1")
    XCTAssertEqual(metadata?["key2"], "value2")

    // Check hasValue
    XCTAssertTrue(try dynamicMsg.hasValue(forField: "metadata"))
  }

  func testDynamicMessageWithDetectedStringToInt32Map() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "counters",
      fieldNumber: 1,
      keyType: .string,
      valueType: .int32
    )

    let messageDescriptor = try bridge.fromProtobufDescriptor(messageProto)
    var dynamicMsg = DynamicMessage(descriptor: messageDescriptor)

    // Set map entries
    try dynamicMsg.setMapEntry(Int32(42), forKey: "requests", inField: "counters")
    try dynamicMsg.setMapEntry(Int32(100), forKey: "errors", inField: "counters")

    // Get map
    let counters = try dynamicMsg.get(forField: "counters") as? [String: Int32]
    XCTAssertEqual(counters?["requests"], 42)
    XCTAssertEqual(counters?["errors"], 100)
  }

  func testDynamicMessageWithDetectedInt32ToStringMap() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "names",
      fieldNumber: 1,
      keyType: .int32,
      valueType: .string
    )

    let messageDescriptor = try bridge.fromProtobufDescriptor(messageProto)
    var dynamicMsg = DynamicMessage(descriptor: messageDescriptor)

    // Set map entries with Int32 keys
    try dynamicMsg.setMapEntry("Alice", forKey: Int32(1), inField: "names")
    try dynamicMsg.setMapEntry("Bob", forKey: Int32(2), inField: "names")

    // Get map
    let names = try dynamicMsg.get(forField: "names") as? [AnyHashable: String]
    XCTAssertEqual(names?[Int32(1)] as? String, "Alice")
    XCTAssertEqual(names?[Int32(2)] as? String, "Bob")
  }

  func testDynamicMessageWithDetectedInt64ToInt64Map() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "big_counters",
      fieldNumber: 1,
      keyType: .int64,
      valueType: .int64
    )

    let messageDescriptor = try bridge.fromProtobufDescriptor(messageProto)
    var dynamicMsg = DynamicMessage(descriptor: messageDescriptor)

    // Set map entries with Int64
    try dynamicMsg.setMapEntry(Int64(1000000000), forKey: Int64(1), inField: "big_counters")
    try dynamicMsg.setMapEntry(Int64(2000000000), forKey: Int64(2), inField: "big_counters")

    // Get map
    let counters = try dynamicMsg.get(forField: "big_counters") as? [Int64: Int64]
    XCTAssertEqual(counters?[Int64(1)], 1000000000)
    XCTAssertEqual(counters?[Int64(2)], 2000000000)
  }

  func testDynamicMessageWithDetectedBoolToStringMap() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "bool_map",
      fieldNumber: 1,
      keyType: .bool,
      valueType: .string
    )

    let messageDescriptor = try bridge.fromProtobufDescriptor(messageProto)
    var dynamicMsg = DynamicMessage(descriptor: messageDescriptor)

    // Set map entries with Bool keys
    try dynamicMsg.setMapEntry("yes", forKey: true, inField: "bool_map")
    try dynamicMsg.setMapEntry("no", forKey: false, inField: "bool_map")

    // Get map
    let boolMap = try dynamicMsg.get(forField: "bool_map") as? [Bool: String]
    XCTAssertEqual(boolMap?[true], "yes")
    XCTAssertEqual(boolMap?[false], "no")
  }

  func testSetEntireMapOnDetectedField() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "attributes",
      fieldNumber: 1,
      keyType: .string,
      valueType: .string
    )

    let messageDescriptor = try bridge.fromProtobufDescriptor(messageProto)
    var dynamicMsg = DynamicMessage(descriptor: messageDescriptor)

    // Set entire map at once
    let attributes = ["name": "John", "role": "Developer", "level": "Senior"]
    try dynamicMsg.set(attributes, forField: "attributes")

    // Get and verify
    let result = try dynamicMsg.get(forField: "attributes") as? [String: String]
    XCTAssertEqual(result?.count, 3)
    XCTAssertEqual(result?["name"], "John")
    XCTAssertEqual(result?["role"], "Developer")
    XCTAssertEqual(result?["level"], "Senior")
  }

  func testClearDetectedMapField() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "data",
      fieldNumber: 1,
      keyType: .string,
      valueType: .int32
    )

    let messageDescriptor = try bridge.fromProtobufDescriptor(messageProto)
    var dynamicMsg = DynamicMessage(descriptor: messageDescriptor)

    // Set map entries
    try dynamicMsg.setMapEntry(Int32(10), forKey: "a", inField: "data")
    try dynamicMsg.setMapEntry(Int32(20), forKey: "b", inField: "data")

    // Verify it's set
    XCTAssertTrue(try dynamicMsg.hasValue(forField: "data"))

    // Clear field
    try dynamicMsg.clearField("data")

    // Verify it's cleared
    XCTAssertFalse(try dynamicMsg.hasValue(forField: "data"))
    XCTAssertNil(try dynamicMsg.get(forField: "data"))
  }

  func testMultipleMapFieldsInDynamicMessage() throws {
    // Create message with multiple map fields
    var messageProto = Google_Protobuf_DescriptorProto()
    messageProto.name = "MultiMapMessage"

    // Map 1: string -> int32
    let (_, mapField1) = createMapFieldComponents(
      fieldName: "counters",
      fieldNumber: 1,
      keyType: .string,
      valueType: .int32
    )

    // Map 2: int64 -> string
    let (_, mapField2) = createMapFieldComponents(
      fieldName: "names",
      fieldNumber: 2,
      keyType: .int64,
      valueType: .string
    )

    // Map 3: bool -> int32
    let (_, mapField3) = createMapFieldComponents(
      fieldName: "flags",
      fieldNumber: 3,
      keyType: .bool,
      valueType: .int32
    )

    // Create entry messages
    let entryMessage1 = createMapEntryMessage(
      name: "CountersEntry",
      keyType: .string,
      valueType: .int32
    )
    let entryMessage2 = createMapEntryMessage(
      name: "NamesEntry",
      keyType: .int64,
      valueType: .string
    )
    let entryMessage3 = createMapEntryMessage(
      name: "FlagsEntry",
      keyType: .bool,
      valueType: .int32
    )

    messageProto.nestedType = [entryMessage1, entryMessage2, entryMessage3]
    messageProto.field = [mapField1, mapField2, mapField3]

    let messageDescriptor = try bridge.fromProtobufDescriptor(messageProto)
    var dynamicMsg = DynamicMessage(descriptor: messageDescriptor)

    // Set values in all three maps
    try dynamicMsg.setMapEntry(Int32(42), forKey: "requests", inField: "counters")
    try dynamicMsg.setMapEntry("Alice", forKey: Int64(1), inField: "names")
    try dynamicMsg.setMapEntry(Int32(1), forKey: true, inField: "flags")

    // Verify all maps
    let counters = try dynamicMsg.get(forField: "counters") as? [String: Int32]
    XCTAssertEqual(counters?["requests"], 42)

    let names = try dynamicMsg.get(forField: "names") as? [AnyHashable: String]
    XCTAssertEqual(names?[Int64(1)] as? String, "Alice")

    let flags = try dynamicMsg.get(forField: "flags") as? [Bool: Int32]
    XCTAssertEqual(flags?[true], 1)
  }

  func testUpdateMapEntryOnDetectedField() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "config",
      fieldNumber: 1,
      keyType: .string,
      valueType: .string
    )

    let messageDescriptor = try bridge.fromProtobufDescriptor(messageProto)
    var dynamicMsg = DynamicMessage(descriptor: messageDescriptor)

    // Set initial value
    try dynamicMsg.setMapEntry("value1", forKey: "key1", inField: "config")
    XCTAssertEqual(
      (try dynamicMsg.get(forField: "config") as? [String: String])?["key1"],
      "value1"
    )

    // Update the same key
    try dynamicMsg.setMapEntry("value2", forKey: "key1", inField: "config")

    // Verify updated value
    let config = try dynamicMsg.get(forField: "config") as? [String: String]
    XCTAssertEqual(config?["key1"], "value2")
  }

  func testFieldAccessorWithDetectedMap() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "settings",
      fieldNumber: 1,
      keyType: .string,
      valueType: .string
    )

    let messageDescriptor = try bridge.fromProtobufDescriptor(messageProto)
    var dynamicMsg = DynamicMessage(descriptor: messageDescriptor)

    // Set using DynamicMessage
    try dynamicMsg.setMapEntry("dark", forKey: "theme", inField: "settings")

    // Read using FieldAccessor
    let accessor = dynamicMsg.fieldAccessor
    let settings = accessor.getStringMap("settings")

    XCTAssertNotNil(settings)
    XCTAssertEqual(settings?["theme"], "dark")
  }

  // MARK: - Helper Methods

  /// Creates a complete message descriptor with a map field and its entry message.
  private func createMapFieldDescriptor(
    fieldName: String,
    fieldNumber: Int32,
    keyType: Google_Protobuf_FieldDescriptorProto.TypeEnum,
    valueType: Google_Protobuf_FieldDescriptorProto.TypeEnum,
    valueTypeName: String? = nil
  ) -> (Google_Protobuf_DescriptorProto, Google_Protobuf_FieldDescriptorProto) {
    var messageProto = Google_Protobuf_DescriptorProto()
    messageProto.name = "TestMessage"

    let (entryMessage, mapField) = createMapFieldComponents(
      fieldName: fieldName,
      fieldNumber: fieldNumber,
      keyType: keyType,
      valueType: valueType,
      valueTypeName: valueTypeName
    )

    messageProto.nestedType = [entryMessage]
    messageProto.field = [mapField]

    return (messageProto, mapField)
  }

  /// Creates map field and entry message components.
  private func createMapFieldComponents(
    fieldName: String,
    fieldNumber: Int32,
    keyType: Google_Protobuf_FieldDescriptorProto.TypeEnum,
    valueType: Google_Protobuf_FieldDescriptorProto.TypeEnum,
    valueTypeName: String? = nil
  ) -> (Google_Protobuf_DescriptorProto, Google_Protobuf_FieldDescriptorProto) {
    // Create map field
    var mapField = Google_Protobuf_FieldDescriptorProto()
    mapField.name = fieldName
    mapField.number = fieldNumber
    mapField.type = .message
    mapField.label = .repeated

    // Entry message name
    let entryName = fieldName.prefix(1).uppercased() + fieldName.dropFirst() + "Entry"
    mapField.typeName = ".test.TestMessage.\(entryName)"

    // Create entry message
    let entryMessage = createMapEntryMessage(
      name: entryName,
      keyType: keyType,
      valueType: valueType,
      valueTypeName: valueTypeName
    )

    return (entryMessage, mapField)
  }

  /// Creates a map entry message with the specified key and value types.
  private func createMapEntryMessage(
    name: String,
    keyType: Google_Protobuf_FieldDescriptorProto.TypeEnum,
    valueType: Google_Protobuf_FieldDescriptorProto.TypeEnum,
    valueTypeName: String? = nil
  ) -> Google_Protobuf_DescriptorProto {
    var entryMessage = Google_Protobuf_DescriptorProto()
    entryMessage.name = name

    // Set map_entry option
    var options = Google_Protobuf_MessageOptions()
    options.mapEntry = true
    entryMessage.options = options

    // Create key field
    var keyField = Google_Protobuf_FieldDescriptorProto()
    keyField.name = "key"
    keyField.number = 1
    keyField.type = keyType
    keyField.label = .optional

    // Create value field
    var valueField = Google_Protobuf_FieldDescriptorProto()
    valueField.name = "value"
    valueField.number = 2
    valueField.type = valueType
    valueField.label = .optional

    if let typeName = valueTypeName {
      valueField.typeName = typeName
    }

    entryMessage.field = [keyField, valueField]

    return entryMessage
  }
}
