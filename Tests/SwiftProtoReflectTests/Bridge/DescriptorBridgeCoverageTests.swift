import Foundation
import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

final class DescriptorBridgeCoverageTests: XCTestCase {

  private let bridge = DescriptorBridge()

  // MARK: - toProtobuf: required label

  func test_toProtobuf_requiredField_setsRequiredLabel() throws {
    var desc = MessageDescriptor(name: "Test", fullName: "Test")
    desc.addField(
      FieldDescriptor(
        name: "id",
        number: 1,
        type: .int32,
        isRequired: true
      )
    )
    let proto = try bridge.toProtobufDescriptor(from: desc)
    XCTAssertEqual(proto.field[0].label, .required)
  }

  // MARK: - Default value parsing: bytes

  func test_fromProtobuf_bytesDefaultValue_parsedCorrectly() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "data"
    fieldProto.number = 1
    fieldProto.type = .bytes
    fieldProto.label = .optional
    fieldProto.defaultValue = "hello"

    var msgProto = Google_Protobuf_DescriptorProto()
    msgProto.name = "Test"
    msgProto.field = [fieldProto]

    let descriptor = try bridge.fromProtobufDescriptor(msgProto, parent: nil as (any DescriptorParent)?)
    let field = descriptor.field(named: "data")
    XCTAssertEqual(field?.defaultValue, .bytes(Data("hello".utf8)))
  }

  // MARK: - Default value parsing: sint64, uint32, uint64

  func test_fromProtobuf_sint64DefaultValue_parsedAsInt() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "val"
    fieldProto.number = 1
    fieldProto.type = .sint64
    fieldProto.label = .optional
    fieldProto.defaultValue = "42"

    var msgProto = Google_Protobuf_DescriptorProto()
    msgProto.name = "Test"
    msgProto.field = [fieldProto]

    let descriptor = try bridge.fromProtobufDescriptor(msgProto, parent: nil as (any DescriptorParent)?)
    let field = descriptor.field(named: "val")
    XCTAssertEqual(field?.defaultValue, .int(42))
  }

  func test_fromProtobuf_uint32DefaultValue_parsedAsInt() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "val"
    fieldProto.number = 1
    fieldProto.type = .uint32
    fieldProto.label = .optional
    fieldProto.defaultValue = "100"

    var msgProto = Google_Protobuf_DescriptorProto()
    msgProto.name = "Test"
    msgProto.field = [fieldProto]

    let descriptor = try bridge.fromProtobufDescriptor(msgProto, parent: nil as (any DescriptorParent)?)
    let field = descriptor.field(named: "val")
    XCTAssertEqual(field?.defaultValue, .int(100))
  }

  func test_fromProtobuf_uint64DefaultValue_parsedAsInt() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "val"
    fieldProto.number = 1
    fieldProto.type = .uint64
    fieldProto.label = .optional
    fieldProto.defaultValue = "999"

    var msgProto = Google_Protobuf_DescriptorProto()
    msgProto.name = "Test"
    msgProto.field = [fieldProto]

    let descriptor = try bridge.fromProtobufDescriptor(msgProto, parent: nil as (any DescriptorParent)?)
    let field = descriptor.field(named: "val")
    XCTAssertEqual(field?.defaultValue, .int(999))
  }

  func test_fromProtobuf_invalidIntDefaultValue_fallsBackToString() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "val"
    fieldProto.number = 1
    fieldProto.type = .sint64
    fieldProto.label = .optional
    fieldProto.defaultValue = "not_a_number"

    var msgProto = Google_Protobuf_DescriptorProto()
    msgProto.name = "Test"
    msgProto.field = [fieldProto]

    let descriptor = try bridge.fromProtobufDescriptor(msgProto, parent: nil as (any DescriptorParent)?)
    let field = descriptor.field(named: "val")
    XCTAssertEqual(field?.defaultValue, .string("not_a_number"))
  }

  // MARK: - Default value parsing: enum

  func test_fromProtobuf_enumDefaultValue_parsedAsString() throws {
    var fieldProto = Google_Protobuf_FieldDescriptorProto()
    fieldProto.name = "status"
    fieldProto.number = 1
    fieldProto.type = .enum
    fieldProto.typeName = ".Status"
    fieldProto.label = .optional
    fieldProto.defaultValue = "ACTIVE"

    var msgProto = Google_Protobuf_DescriptorProto()
    msgProto.name = "Test"
    msgProto.field = [fieldProto]

    let descriptor = try bridge.fromProtobufDescriptor(msgProto, parent: nil as (any DescriptorParent)?)
    let field = descriptor.field(named: "status")
    XCTAssertEqual(field?.defaultValue, .string("ACTIVE"))
  }

  // MARK: - Map entry validation: missing fields

  func test_fromProtobuf_mapEntryMissingValueField_throws() throws {
    var keyField = Google_Protobuf_FieldDescriptorProto()
    keyField.name = "key"
    keyField.number = 1
    keyField.type = .string
    keyField.label = .optional

    var entry = Google_Protobuf_DescriptorProto()
    entry.name = "DataEntry"
    entry.options.mapEntry = true
    entry.field = [keyField]

    var mapField = Google_Protobuf_FieldDescriptorProto()
    mapField.name = "data"
    mapField.number = 1
    mapField.type = .message
    mapField.label = .repeated
    mapField.typeName = ".Test.DataEntry"

    var parent = Google_Protobuf_DescriptorProto()
    parent.name = "Test"
    parent.field = [mapField]
    parent.nestedType = [entry]

    XCTAssertThrowsError(try bridge.fromProtobufDescriptor(parent, parent: nil as (any DescriptorParent)?))
  }

  // MARK: - Map entry validation: wrong field names

  func test_fromProtobuf_mapEntryWrongFieldNames_throws() throws {
    var keyField = Google_Protobuf_FieldDescriptorProto()
    keyField.name = "k"
    keyField.number = 1
    keyField.type = .string
    keyField.label = .optional

    var valueField = Google_Protobuf_FieldDescriptorProto()
    valueField.name = "v"
    valueField.number = 2
    valueField.type = .string
    valueField.label = .optional

    var entry = Google_Protobuf_DescriptorProto()
    entry.name = "DataEntry"
    entry.options.mapEntry = true
    entry.field = [keyField, valueField]

    var mapField = Google_Protobuf_FieldDescriptorProto()
    mapField.name = "data"
    mapField.number = 1
    mapField.type = .message
    mapField.label = .repeated
    mapField.typeName = ".Test.DataEntry"

    var parent = Google_Protobuf_DescriptorProto()
    parent.name = "Test"
    parent.field = [mapField]
    parent.nestedType = [entry]

    XCTAssertThrowsError(try bridge.fromProtobufDescriptor(parent, parent: nil as (any DescriptorParent)?))
  }

  // MARK: - Map entry validation: invalid key type

  func test_fromProtobuf_mapEntryFloatKeyType_throws() throws {
    var keyField = Google_Protobuf_FieldDescriptorProto()
    keyField.name = "key"
    keyField.number = 1
    keyField.type = .float
    keyField.label = .optional

    var valueField = Google_Protobuf_FieldDescriptorProto()
    valueField.name = "value"
    valueField.number = 2
    valueField.type = .string
    valueField.label = .optional

    var entry = Google_Protobuf_DescriptorProto()
    entry.name = "DataEntry"
    entry.options.mapEntry = true
    entry.field = [keyField, valueField]

    var mapField = Google_Protobuf_FieldDescriptorProto()
    mapField.name = "data"
    mapField.number = 1
    mapField.type = .message
    mapField.label = .repeated
    mapField.typeName = ".Test.DataEntry"

    var parent = Google_Protobuf_DescriptorProto()
    parent.name = "Test"
    parent.field = [mapField]
    parent.nestedType = [entry]

    XCTAssertThrowsError(try bridge.fromProtobufDescriptor(parent, parent: nil as (any DescriptorParent)?))
  }
}
