//
// DescriptorBridgeMapTests.swift
// SwiftProtoReflectTests
//
// Created: 2025-02-04
//

import XCTest

import struct SwiftProtobuf.Google_Protobuf_DescriptorProto
import struct SwiftProtobuf.Google_Protobuf_FieldDescriptorProto
import struct SwiftProtobuf.Google_Protobuf_FileDescriptorProto
import struct SwiftProtobuf.Google_Protobuf_MessageOptions

@testable import SwiftProtoReflect

/// Tests for map field detection in DescriptorBridge.
final class DescriptorBridgeMapTests: XCTestCase {

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

  // MARK: - Basic Map Detection Tests

  func testDetectStringToStringMap() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "string_map",
      fieldNumber: 1,
      keyType: .string,
      valueType: .string
    )

    let messageDescriptor = try bridge.fromProtobufDescriptor(messageProto)

    let field = messageDescriptor.field(named: "string_map")
    XCTAssertNotNil(field, "Map field should be created")
    XCTAssertTrue(field!.isMap, "Field should be detected as map")
    XCTAssertNotNil(field!.mapEntryInfo, "MapEntryInfo should be populated")
    XCTAssertEqual(field!.mapEntryInfo?.keyFieldInfo.type, .string)
    XCTAssertEqual(field!.mapEntryInfo?.valueFieldInfo.type, .string)
  }

  func testDetectStringToInt32Map() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "counters",
      fieldNumber: 1,
      keyType: .string,
      valueType: .int32
    )

    let messageDescriptor = try bridge.fromProtobufDescriptor(messageProto)

    let field = messageDescriptor.field(named: "counters")
    XCTAssertNotNil(field)
    XCTAssertTrue(field!.isMap)
    XCTAssertEqual(field!.mapEntryInfo?.keyFieldInfo.type, .string)
    XCTAssertEqual(field!.mapEntryInfo?.valueFieldInfo.type, .int32)
  }

  func testDetectInt32ToStringMap() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "names",
      fieldNumber: 1,
      keyType: .int32,
      valueType: .string
    )

    let messageDescriptor = try bridge.fromProtobufDescriptor(messageProto)

    let field = messageDescriptor.field(named: "names")
    XCTAssertNotNil(field)
    XCTAssertTrue(field!.isMap)
    XCTAssertEqual(field!.mapEntryInfo?.keyFieldInfo.type, .int32)
    XCTAssertEqual(field!.mapEntryInfo?.valueFieldInfo.type, .string)
  }

  func testDetectInt64ToMessageMap() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "entities",
      fieldNumber: 1,
      keyType: .int64,
      valueType: .message,
      valueTypeName: ".test.Entity"
    )

    let messageDescriptor = try bridge.fromProtobufDescriptor(messageProto)

    let field = messageDescriptor.field(named: "entities")
    XCTAssertNotNil(field)
    XCTAssertTrue(field!.isMap)
    XCTAssertEqual(field!.mapEntryInfo?.keyFieldInfo.type, .int64)
    XCTAssertEqual(field!.mapEntryInfo?.valueFieldInfo.type, .message)
    XCTAssertEqual(field!.mapEntryInfo?.valueFieldInfo.typeName, ".test.Entity")
  }

  // MARK: - All Key Types Tests

  func testMapWithInt32Key() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "int32_map",
      fieldNumber: 1,
      keyType: .int32,
      valueType: .string
    )

    let field = try bridge.fromProtobufDescriptor(messageProto).field(named: "int32_map")
    XCTAssertTrue(field!.isMap)
    XCTAssertEqual(field!.mapEntryInfo?.keyFieldInfo.type, .int32)
  }

  func testMapWithInt64Key() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "int64_map",
      fieldNumber: 1,
      keyType: .int64,
      valueType: .string
    )

    let field = try bridge.fromProtobufDescriptor(messageProto).field(named: "int64_map")
    XCTAssertTrue(field!.isMap)
    XCTAssertEqual(field!.mapEntryInfo?.keyFieldInfo.type, .int64)
  }

  func testMapWithUInt32Key() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "uint32_map",
      fieldNumber: 1,
      keyType: .uint32,
      valueType: .string
    )

    let field = try bridge.fromProtobufDescriptor(messageProto).field(named: "uint32_map")
    XCTAssertTrue(field!.isMap)
    XCTAssertEqual(field!.mapEntryInfo?.keyFieldInfo.type, .uint32)
  }

  func testMapWithUInt64Key() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "uint64_map",
      fieldNumber: 1,
      keyType: .uint64,
      valueType: .string
    )

    let field = try bridge.fromProtobufDescriptor(messageProto).field(named: "uint64_map")
    XCTAssertTrue(field!.isMap)
    XCTAssertEqual(field!.mapEntryInfo?.keyFieldInfo.type, .uint64)
  }

  func testMapWithSInt32Key() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "sint32_map",
      fieldNumber: 1,
      keyType: .sint32,
      valueType: .string
    )

    let field = try bridge.fromProtobufDescriptor(messageProto).field(named: "sint32_map")
    XCTAssertTrue(field!.isMap)
    XCTAssertEqual(field!.mapEntryInfo?.keyFieldInfo.type, .sint32)
  }

  func testMapWithSInt64Key() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "sint64_map",
      fieldNumber: 1,
      keyType: .sint64,
      valueType: .string
    )

    let field = try bridge.fromProtobufDescriptor(messageProto).field(named: "sint64_map")
    XCTAssertTrue(field!.isMap)
    XCTAssertEqual(field!.mapEntryInfo?.keyFieldInfo.type, .sint64)
  }

  func testMapWithFixed32Key() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "fixed32_map",
      fieldNumber: 1,
      keyType: .fixed32,
      valueType: .string
    )

    let field = try bridge.fromProtobufDescriptor(messageProto).field(named: "fixed32_map")
    XCTAssertTrue(field!.isMap)
    XCTAssertEqual(field!.mapEntryInfo?.keyFieldInfo.type, .fixed32)
  }

  func testMapWithFixed64Key() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "fixed64_map",
      fieldNumber: 1,
      keyType: .fixed64,
      valueType: .string
    )

    let field = try bridge.fromProtobufDescriptor(messageProto).field(named: "fixed64_map")
    XCTAssertTrue(field!.isMap)
    XCTAssertEqual(field!.mapEntryInfo?.keyFieldInfo.type, .fixed64)
  }

  func testMapWithSFixed32Key() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "sfixed32_map",
      fieldNumber: 1,
      keyType: .sfixed32,
      valueType: .string
    )

    let field = try bridge.fromProtobufDescriptor(messageProto).field(named: "sfixed32_map")
    XCTAssertTrue(field!.isMap)
    XCTAssertEqual(field!.mapEntryInfo?.keyFieldInfo.type, .sfixed32)
  }

  func testMapWithSFixed64Key() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "sfixed64_map",
      fieldNumber: 1,
      keyType: .sfixed64,
      valueType: .string
    )

    let field = try bridge.fromProtobufDescriptor(messageProto).field(named: "sfixed64_map")
    XCTAssertTrue(field!.isMap)
    XCTAssertEqual(field!.mapEntryInfo?.keyFieldInfo.type, .sfixed64)
  }

  func testMapWithBoolKey() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "bool_map",
      fieldNumber: 1,
      keyType: .bool,
      valueType: .string
    )

    let field = try bridge.fromProtobufDescriptor(messageProto).field(named: "bool_map")
    XCTAssertTrue(field!.isMap)
    XCTAssertEqual(field!.mapEntryInfo?.keyFieldInfo.type, .bool)
  }

  func testMapWithStringKey() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "string_map",
      fieldNumber: 1,
      keyType: .string,
      valueType: .int32
    )

    let field = try bridge.fromProtobufDescriptor(messageProto).field(named: "string_map")
    XCTAssertTrue(field!.isMap)
    XCTAssertEqual(field!.mapEntryInfo?.keyFieldInfo.type, .string)
  }

  // MARK: - All Value Types Tests

  func testMapWithScalarValues() throws {
    let scalarTypes: [Google_Protobuf_FieldDescriptorProto.TypeEnum] = [
      .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64,
      .bool, .string, .bytes,
    ]

    for (index, valueType) in scalarTypes.enumerated() {
      let (messageProto, _) = createMapFieldDescriptor(
        fieldName: "map_\(index)",
        fieldNumber: Int32(index + 1),
        keyType: .string,
        valueType: valueType
      )

      let field = try bridge.fromProtobufDescriptor(messageProto).field(named: "map_\(index)")
      XCTAssertTrue(field!.isMap, "Field with value type \(valueType) should be detected as map")
      XCTAssertNotNil(field!.mapEntryInfo, "MapEntryInfo should be populated for value type \(valueType)")
    }
  }

  func testMapWithEnumValue() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "enum_map",
      fieldNumber: 1,
      keyType: .string,
      valueType: .enum,
      valueTypeName: ".test.Status"
    )

    let field = try bridge.fromProtobufDescriptor(messageProto).field(named: "enum_map")
    XCTAssertTrue(field!.isMap)
    XCTAssertEqual(field!.mapEntryInfo?.valueFieldInfo.type, .enum)
    XCTAssertEqual(field!.mapEntryInfo?.valueFieldInfo.typeName, ".test.Status")
  }

  func testMapWithMessageValue() throws {
    let (messageProto, _) = createMapFieldDescriptor(
      fieldName: "message_map",
      fieldNumber: 1,
      keyType: .string,
      valueType: .message,
      valueTypeName: ".test.Data"
    )

    let field = try bridge.fromProtobufDescriptor(messageProto).field(named: "message_map")
    XCTAssertTrue(field!.isMap)
    XCTAssertEqual(field!.mapEntryInfo?.valueFieldInfo.type, .message)
    XCTAssertEqual(field!.mapEntryInfo?.valueFieldInfo.typeName, ".test.Data")
  }

  // MARK: - Edge Cases Tests

  func testMultipleMapFieldsInMessage() throws {
    var messageProto = Google_Protobuf_DescriptorProto()
    messageProto.name = "MultiMapMessage"

    // Create multiple map fields
    let (_, mapField1) = createMapFieldDescriptor(
      fieldName: "map1",
      fieldNumber: 1,
      keyType: .string,
      valueType: .int32
    )
    let (_, mapField2) = createMapFieldDescriptor(
      fieldName: "map2",
      fieldNumber: 2,
      keyType: .int64,
      valueType: .string
    )

    // Create entry messages for both maps
    let entryMessage1 = createMapEntryMessage(
      name: "Map1Entry",
      keyType: .string,
      valueType: .int32
    )
    let entryMessage2 = createMapEntryMessage(
      name: "Map2Entry",
      keyType: .int64,
      valueType: .string
    )

    messageProto.nestedType = [entryMessage1, entryMessage2]
    messageProto.field = [mapField1, mapField2]

    let messageDescriptor = try bridge.fromProtobufDescriptor(messageProto)

    let field1 = messageDescriptor.field(named: "map1")
    XCTAssertTrue(field1!.isMap)
    XCTAssertEqual(field1!.mapEntryInfo?.keyFieldInfo.type, .string)
    XCTAssertEqual(field1!.mapEntryInfo?.valueFieldInfo.type, .int32)

    let field2 = messageDescriptor.field(named: "map2")
    XCTAssertTrue(field2!.isMap)
    XCTAssertEqual(field2!.mapEntryInfo?.keyFieldInfo.type, .int64)
    XCTAssertEqual(field2!.mapEntryInfo?.valueFieldInfo.type, .string)
  }

  func testMapFieldMixedWithRepeatedFields() throws {
    var messageProto = Google_Protobuf_DescriptorProto()
    messageProto.name = "MixedMessage"

    // Create map field
    let (_, mapField) = createMapFieldDescriptor(
      fieldName: "metadata",
      fieldNumber: 1,
      keyType: .string,
      valueType: .string
    )

    // Create regular repeated field
    var repeatedField = Google_Protobuf_FieldDescriptorProto()
    repeatedField.name = "items"
    repeatedField.number = 2
    repeatedField.type = .string
    repeatedField.label = .repeated

    let entryMessage = createMapEntryMessage(
      name: "MetadataEntry",
      keyType: .string,
      valueType: .string
    )

    messageProto.nestedType = [entryMessage]
    messageProto.field = [mapField, repeatedField]

    let messageDescriptor = try bridge.fromProtobufDescriptor(messageProto)

    let mapFieldResult = messageDescriptor.field(named: "metadata")
    XCTAssertTrue(mapFieldResult!.isMap, "Map field should be detected as map")

    let repeatedFieldResult = messageDescriptor.field(named: "items")
    XCTAssertFalse(repeatedFieldResult!.isMap, "Regular repeated field should not be detected as map")
    XCTAssertTrue(repeatedFieldResult!.isRepeated)
  }

  func testRegularRepeatedFieldNotDetectedAsMap() throws {
    var messageProto = Google_Protobuf_DescriptorProto()
    messageProto.name = "TestMessage"

    var repeatedField = Google_Protobuf_FieldDescriptorProto()
    repeatedField.name = "values"
    repeatedField.number = 1
    repeatedField.type = .string
    repeatedField.label = .repeated

    messageProto.field = [repeatedField]

    let messageDescriptor = try bridge.fromProtobufDescriptor(messageProto)

    let field = messageDescriptor.field(named: "values")
    XCTAssertFalse(field!.isMap, "Regular repeated field should not be detected as map")
    XCTAssertTrue(field!.isRepeated)
    XCTAssertNil(field!.mapEntryInfo)
  }

  func testRepeatedMessageWithoutMapEntryOption() throws {
    var messageProto = Google_Protobuf_DescriptorProto()
    messageProto.name = "TestMessage"

    var repeatedMessageField = Google_Protobuf_FieldDescriptorProto()
    repeatedMessageField.name = "items"
    repeatedMessageField.number = 1
    repeatedMessageField.type = .message
    repeatedMessageField.typeName = ".test.TestMessage.Item"
    repeatedMessageField.label = .repeated

    // Create nested message WITHOUT map_entry option
    var nestedMessage = Google_Protobuf_DescriptorProto()
    nestedMessage.name = "Item"

    var field1 = Google_Protobuf_FieldDescriptorProto()
    field1.name = "key"
    field1.number = 1
    field1.type = .string

    var field2 = Google_Protobuf_FieldDescriptorProto()
    field2.name = "value"
    field2.number = 2
    field2.type = .string

    nestedMessage.field = [field1, field2]
    // NO map_entry option set

    messageProto.nestedType = [nestedMessage]
    messageProto.field = [repeatedMessageField]

    let messageDescriptor = try bridge.fromProtobufDescriptor(messageProto)

    let field = messageDescriptor.field(named: "items")
    XCTAssertFalse(field!.isMap, "Repeated message without map_entry option should not be detected as map")
    XCTAssertTrue(field!.isRepeated)
    XCTAssertNil(field!.mapEntryInfo)
  }

  // MARK: - Round-trip Conversion Tests

  func testMapFieldRoundTripConversion() throws {
    // Create original field descriptor with map
    let keyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: keyFieldInfo, valueFieldInfo: valueFieldInfo)

    let originalField = FieldDescriptor(
      name: "metadata",
      number: 1,
      type: .message,
      typeName: ".test.MetadataEntry",
      isMap: true,
      mapEntryInfo: mapEntryInfo
    )

    var originalMessage = MessageDescriptor(name: "TestMessage")
    originalMessage.addField(originalField)

    // Convert to protobuf format
    let protobufMessage = try bridge.toProtobufDescriptor(from: originalMessage)

    // Note: Round-trip conversion for maps is limited because toProtobufDescriptor
    // doesn't create map entry messages. This test verifies the forward conversion works.
    XCTAssertEqual(protobufMessage.name, "TestMessage")
    XCTAssertEqual(protobufMessage.field.count, 1)
    XCTAssertEqual(protobufMessage.field[0].name, "metadata")
    XCTAssertEqual(protobufMessage.field[0].label, .repeated)
    XCTAssertEqual(protobufMessage.field[0].type, .message)
  }

  // MARK: - Helper Methods

  /// Creates a complete message descriptor with a map field and its entry message.
  ///
  /// - Parameters:
  ///   - fieldName: Name of the map field.
  ///   - fieldNumber: Field number.
  ///   - keyType: Type of the map key.
  ///   - valueType: Type of the map value.
  ///   - valueTypeName: Type name for enum or message values.
  /// - Returns: Tuple of (message descriptor, field descriptor).
  private func createMapFieldDescriptor(
    fieldName: String,
    fieldNumber: Int32,
    keyType: Google_Protobuf_FieldDescriptorProto.TypeEnum,
    valueType: Google_Protobuf_FieldDescriptorProto.TypeEnum,
    valueTypeName: String? = nil
  ) -> (Google_Protobuf_DescriptorProto, Google_Protobuf_FieldDescriptorProto) {
    var messageProto = Google_Protobuf_DescriptorProto()
    messageProto.name = "TestMessage"

    // Create map field
    var mapField = Google_Protobuf_FieldDescriptorProto()
    mapField.name = fieldName
    mapField.number = fieldNumber
    mapField.type = .message
    mapField.label = .repeated

    // Entry message name: capitalize first letter and append "Entry"
    let entryName = fieldName.prefix(1).uppercased() + fieldName.dropFirst() + "Entry"
    mapField.typeName = ".test.TestMessage.\(entryName)"

    // Create entry message
    let entryMessage = createMapEntryMessage(
      name: entryName,
      keyType: keyType,
      valueType: valueType,
      valueTypeName: valueTypeName
    )

    messageProto.nestedType = [entryMessage]
    messageProto.field = [mapField]

    return (messageProto, mapField)
  }

  /// Creates a map entry message with the specified key and value types.
  ///
  /// - Parameters:
  ///   - name: Name of the entry message.
  ///   - keyType: Type of the key field.
  ///   - valueType: Type of the value field.
  ///   - valueTypeName: Type name for enum or message values.
  /// - Returns: Map entry message descriptor.
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
