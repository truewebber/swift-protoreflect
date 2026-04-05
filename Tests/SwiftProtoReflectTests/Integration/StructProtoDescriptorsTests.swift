//
// StructProtoDescriptorsTests.swift
// SwiftProtoReflectTests
//
// Tests for StructProtoDescriptors — shared descriptor factory for struct.proto types.
//

import XCTest

@testable import SwiftProtoReflect

final class StructProtoDescriptorsTests: XCTestCase {

  // MARK: - Struct Descriptor Tests

  func test_structDescriptor_hasCorrectMapField() {
    let descriptor = StructProtoDescriptors.structDescriptor

    XCTAssertEqual(descriptor.fullName, "google.protobuf.Struct")

    let fieldsField = descriptor.field(number: 1)
    XCTAssertNotNil(fieldsField, "Field 1 (fields) must exist")
    XCTAssertEqual(fieldsField?.name, "fields")
    XCTAssertEqual(fieldsField?.type, .message)
    XCTAssertTrue(fieldsField?.isMap == true, "fields field must be a map")

    let mapEntryInfo = fieldsField?.mapEntryInfo
    XCTAssertNotNil(mapEntryInfo, "mapEntryInfo must be present")
    XCTAssertEqual(mapEntryInfo?.keyFieldInfo.type, .string)
    XCTAssertEqual(mapEntryInfo?.valueFieldInfo.type, .message)
    XCTAssertEqual(mapEntryInfo?.valueFieldInfo.typeName, "google.protobuf.Value")
  }

  func test_structDescriptor_fieldsField_hasCorrectTypeName() {
    let descriptor = StructProtoDescriptors.structDescriptor
    let fieldsField = descriptor.field(number: 1)

    XCTAssertEqual(fieldsField?.typeName, "google.protobuf.Struct.FieldsEntry")
    XCTAssertEqual(fieldsField?.mapEntryInfo?.keyFieldInfo.name, "key")
    XCTAssertEqual(fieldsField?.mapEntryInfo?.keyFieldInfo.number, 1)
    XCTAssertEqual(fieldsField?.mapEntryInfo?.valueFieldInfo.name, "value")
    XCTAssertEqual(fieldsField?.mapEntryInfo?.valueFieldInfo.number, 2)
  }

  func test_structDescriptor_hasFieldsEntryNestedMessage() {
    let descriptor = StructProtoDescriptors.structDescriptor

    let fieldsEntry = descriptor.nestedMessage(named: "FieldsEntry")
    XCTAssertNotNil(fieldsEntry, "Struct must have a nested FieldsEntry message")
    XCTAssertEqual(fieldsEntry?.fullName, "google.protobuf.Struct.FieldsEntry")

    let keyField = fieldsEntry?.field(number: 1)
    XCTAssertNotNil(keyField, "FieldsEntry must have key field at number 1")
    XCTAssertEqual(keyField?.name, "key")
    XCTAssertEqual(keyField?.type, .string)

    let valueField = fieldsEntry?.field(number: 2)
    XCTAssertNotNil(valueField, "FieldsEntry must have value field at number 2")
    XCTAssertEqual(valueField?.name, "value")
    XCTAssertEqual(valueField?.type, .message)
    XCTAssertEqual(valueField?.typeName, "google.protobuf.Value")
  }

  // MARK: - Value Descriptor Tests

  func test_valueDescriptor_hasOneof_withSixFields() {
    let descriptor = StructProtoDescriptors.valueDescriptor

    XCTAssertEqual(descriptor.fullName, "google.protobuf.Value")
    XCTAssertEqual(descriptor.oneofDecls.count, 1)

    let kindOneof = descriptor.oneofDecls.first
    XCTAssertEqual(kindOneof?.name, "kind")
    XCTAssertEqual(kindOneof?.index, 0)

    let allFields = descriptor.allFields()
    XCTAssertEqual(allFields.count, 6, "Value must have exactly 6 fields")

    for field in allFields {
      XCTAssertEqual(field.oneofIndex, 0, "All fields must belong to oneof at index 0")
    }

    let nullField = descriptor.field(number: 1)
    XCTAssertEqual(nullField?.name, "null_value")
    XCTAssertEqual(nullField?.type, .enum)
    XCTAssertEqual(nullField?.typeName, "google.protobuf.NullValue")

    let numberField = descriptor.field(number: 2)
    XCTAssertEqual(numberField?.name, "number_value")
    XCTAssertEqual(numberField?.type, .double)

    let stringField = descriptor.field(number: 3)
    XCTAssertEqual(stringField?.name, "string_value")
    XCTAssertEqual(stringField?.type, .string)

    let boolField = descriptor.field(number: 4)
    XCTAssertEqual(boolField?.name, "bool_value")
    XCTAssertEqual(boolField?.type, .bool)

    let structField = descriptor.field(number: 5)
    XCTAssertEqual(structField?.name, "struct_value")
    XCTAssertEqual(structField?.type, .message)
    XCTAssertEqual(structField?.typeName, "google.protobuf.Struct")

    let listField = descriptor.field(number: 6)
    XCTAssertEqual(listField?.name, "list_value")
    XCTAssertEqual(listField?.type, .message)
    XCTAssertEqual(listField?.typeName, "google.protobuf.ListValue")
  }

  // MARK: - ListValue Descriptor Tests

  func test_listValueDescriptor_hasRepeatedValueField() {
    let descriptor = StructProtoDescriptors.listValueDescriptor

    XCTAssertEqual(descriptor.fullName, "google.protobuf.ListValue")

    let valuesField = descriptor.field(number: 1)
    XCTAssertNotNil(valuesField, "Field 1 (values) must exist")
    XCTAssertEqual(valuesField?.name, "values")
    XCTAssertEqual(valuesField?.type, .message)
    XCTAssertEqual(valuesField?.typeName, "google.protobuf.Value")
    XCTAssertTrue(valuesField?.isRepeated == true, "values field must be repeated")
    XCTAssertFalse(valuesField?.isMap == true, "values field must not be a map")
  }

  // MARK: - NullValue Enum Tests

  func test_nullValueEnum_hasNullValueZero() {
    let enumDescriptor = StructProtoDescriptors.nullValueEnum

    XCTAssertEqual(enumDescriptor.fullName, "google.protobuf.NullValue")

    let nullValueEntry = enumDescriptor.value(named: "NULL_VALUE")
    XCTAssertNotNil(nullValueEntry, "NullValue enum must have NULL_VALUE")
    XCTAssertEqual(nullValueEntry?.number, 0)

    let byNumber = enumDescriptor.value(number: 0)
    XCTAssertNotNil(byNumber)
    XCTAssertEqual(byNumber?.name, "NULL_VALUE")
  }

  // MARK: - Shared FileDescriptor Tests

  func test_allDescriptors_shareTheSameFileDescriptor() {
    let structDesc = StructProtoDescriptors.structDescriptor
    let valueDesc = StructProtoDescriptors.valueDescriptor
    let listValueDesc = StructProtoDescriptors.listValueDescriptor
    let nullValueEnum = StructProtoDescriptors.nullValueEnum

    let expectedFile = "google/protobuf/struct.proto"
    XCTAssertEqual(structDesc.fileDescriptorPath, expectedFile)
    XCTAssertEqual(valueDesc.fileDescriptorPath, expectedFile)
    XCTAssertEqual(listValueDesc.fileDescriptorPath, expectedFile)
    XCTAssertEqual(nullValueEnum.fileDescriptorPath, expectedFile)
  }

  func test_fileDescriptor_containsAllFourTypes() {
    let file = StructProtoDescriptors.fileDescriptor

    XCTAssertEqual(file.name, "google/protobuf/struct.proto")
    XCTAssertTrue(file.hasMessage(named: "Struct"))
    XCTAssertTrue(file.hasMessage(named: "Value"))
    XCTAssertTrue(file.hasMessage(named: "ListValue"))
    XCTAssertTrue(file.hasEnum(named: "NullValue"))
  }
}
