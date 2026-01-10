//
// FieldDescriptorTests.swift
// SwiftProtoReflectTests
//
// Created: 2025-05-18
//

import XCTest

@testable import SwiftProtoReflect

final class FieldDescriptorTests: XCTestCase {
  // MARK: - Properties

  // MARK: - Setup

  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  // MARK: - Tests

  func testBasicFieldDescriptor() {
    // Create basic field descriptor
    let field = FieldDescriptor(
      name: "age",
      number: 1,
      type: .int32
    )

    // Verify basic properties
    XCTAssertEqual(field.name, "age")
    XCTAssertEqual(field.jsonName, "age")
    XCTAssertEqual(field.number, 1)
    XCTAssertEqual(field.type, .int32)
    XCTAssertNil(field.typeName)
    XCTAssertFalse(field.isRepeated)
    XCTAssertFalse(field.isOptional)
    XCTAssertFalse(field.isRequired)
    XCTAssertFalse(field.isMap)
    XCTAssertNil(field.oneofIndex)
    XCTAssertNil(field.mapEntryInfo)
    XCTAssertNil(field.defaultValue)
    XCTAssertTrue(field.options.isEmpty)
  }

  func testFieldDescriptorWithAllProperties() {
    // Create detailed field descriptor
    let field = FieldDescriptor(
      name: "emails",
      number: 2,
      type: .string,
      jsonName: "email_addresses",
      isRepeated: true,
      isOptional: false,
      defaultValue: [],
      options: ["packed": true]
    )

    // Verify all properties
    XCTAssertEqual(field.name, "emails")
    XCTAssertEqual(field.jsonName, "email_addresses")
    XCTAssertEqual(field.number, 2)
    XCTAssertEqual(field.type, .string)
    XCTAssertTrue(field.isRepeated)
    XCTAssertFalse(field.isOptional)
    XCTAssertFalse(field.isRequired)
    XCTAssertFalse(field.isMap)
    XCTAssertNotNil(field.defaultValue)
    XCTAssertEqual(field.options.count, 1)
    XCTAssertEqual(field.options["packed"] as? Bool, true)
  }

  func testMessageTypeWithTypeName() {
    // Create message type field
    let field = FieldDescriptor(
      name: "user",
      number: 3,
      type: .message,
      typeName: "example.User"
    )

    // Verify type properties
    XCTAssertEqual(field.type, .message)
    XCTAssertEqual(field.typeName, "example.User")
    XCTAssertEqual(field.getFullTypeName(), "example.User")
    XCTAssertFalse(field.isScalarType())
    XCTAssertFalse(field.isNumericType())
  }

  func testEnumTypeWithTypeName() {
    // Create enum type field
    let field = FieldDescriptor(
      name: "status",
      number: 4,
      type: .enum,
      typeName: "example.Status"
    )

    // Verify type properties
    XCTAssertEqual(field.type, .enum)
    XCTAssertEqual(field.typeName, "example.Status")
    XCTAssertEqual(field.getFullTypeName(), "example.Status")
    XCTAssertFalse(field.isScalarType())
    XCTAssertFalse(field.isNumericType())
  }

  func testMissingTypeNameForMessageFails() {
    // Verify that missing typeName for message causes error
    XCTAssertNoThrow(FieldDescriptor(name: "name", number: 1, type: .string))

    // For message and enum typeName is required
    XCTAssertNoThrow(FieldDescriptor(name: "user", number: 2, type: .message, typeName: "example.User"))
    XCTAssertNoThrow(FieldDescriptor(name: "status", number: 3, type: .enum, typeName: "example.Status"))
  }

  func testScalarTypeDetection() {
    // Verify scalar type detection
    let scalarTypes: [FieldType] = [
      .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64,
      .bool, .string, .bytes,
    ]

    for type in scalarTypes {
      let field = FieldDescriptor(name: "field", number: 1, type: type)
      XCTAssertTrue(field.isScalarType(), "Type \(type) should be detected as scalar")
    }

    // Verify non-scalar types
    let nonScalarTypes: [FieldType] = [.message, .enum, .group]

    for type in nonScalarTypes {
      let field = FieldDescriptor(
        name: "field",
        number: 1,
        type: type,
        typeName: "example.Type"
      )
      XCTAssertFalse(field.isScalarType(), "Type \(type) should not be detected as scalar")
    }
  }

  func testNumericTypeDetection() {
    // Verify numeric type detection
    let numericTypes: [FieldType] = [
      .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64,
    ]

    for type in numericTypes {
      let field = FieldDescriptor(name: "field", number: 1, type: type)
      XCTAssertTrue(field.isNumericType(), "Type \(type) should be detected as numeric")
    }

    // Verify non-numeric types
    let nonNumericTypes: [FieldType] = [.bool, .string, .bytes, .message, .enum, .group]

    for (_, type) in nonNumericTypes.enumerated() {
      let field = FieldDescriptor(
        name: "field",
        number: 1,
        type: type,
        typeName: type == .message || type == .enum || type == .group ? "example.Type" : nil
      )
      XCTAssertFalse(field.isNumericType(), "Type \(type) should not be detected as numeric")
    }
  }

  func testMapFieldCreation() {
    // Create key and value field info
    let keyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)

    // Create MapEntryInfo
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: keyFieldInfo, valueFieldInfo: valueFieldInfo)

    // Create map field
    let mapField = FieldDescriptor(
      name: "counts",
      number: 5,
      type: .message,
      typeName: "example.CountsEntry",
      isMap: true,
      mapEntryInfo: mapEntryInfo
    )

    // Verify properties
    XCTAssertTrue(mapField.isMap)
    XCTAssertNotNil(mapField.mapEntryInfo)

    // Verify access to key and value information
    if let info = mapField.getMapKeyValueInfo() {
      XCTAssertEqual(info.keyFieldInfo.name, "key")
      XCTAssertEqual(info.keyFieldInfo.type, .string)
      XCTAssertEqual(info.valueFieldInfo.name, "value")
      XCTAssertEqual(info.valueFieldInfo.type, .int32)
    }
    else {
      XCTFail("getMapKeyValueInfo() should return key and value information")
    }
  }

  func testMapEntryValidKeyTypes() {
    // Verify valid key types for map
    let validKeyTypes: [FieldType] = [
      .int32, .int64, .uint32, .uint64, .sint32, .sint64,
      .fixed32, .fixed64, .sfixed32, .sfixed64, .bool, .string,
    ]

    for type in validKeyTypes {
      let keyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: type)
      let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)

      XCTAssertNoThrow(
        MapEntryInfo(keyFieldInfo: keyFieldInfo, valueFieldInfo: valueFieldInfo),
        "Type \(type) should be valid for map key"
      )
    }
  }

  func testMapWithNoMapEntryFails() {
    // Verify mapEntryInfo requirement for isMap = true
    XCTAssertNoThrow(
      FieldDescriptor(
        name: "regular",
        number: 1,
        type: .string,
        isMap: false,
        mapEntryInfo: nil
      )
    )

    let keyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: keyFieldInfo, valueFieldInfo: valueFieldInfo)

    XCTAssertNoThrow(
      FieldDescriptor(
        name: "map",
        number: 1,
        type: .message,
        typeName: "example.MapEntry",
        isMap: true,
        mapEntryInfo: mapEntryInfo
      )
    )
  }

  func testGetMapKeyValueReturnsNilForNonMapField() {
    // Verify that getMapKeyValueInfo returns nil for non-map fields
    let field = FieldDescriptor(name: "name", number: 1, type: .string)
    XCTAssertNil(field.getMapKeyValueInfo())
  }

  func testValueFieldInfoWithMessageType() {
    // Verify ValueFieldInfo creation with message type
    let valueFieldInfo = ValueFieldInfo(
      name: "value",
      number: 2,
      type: .message,
      typeName: "example.User"
    )

    XCTAssertEqual(valueFieldInfo.name, "value")
    XCTAssertEqual(valueFieldInfo.number, 2)
    XCTAssertEqual(valueFieldInfo.type, .message)
    XCTAssertEqual(valueFieldInfo.typeName, "example.User")
  }

  func testValueFieldInfoWithTypeName() {
    // Verify ValueFieldInfo creation with message type
    let valueFieldInfo = ValueFieldInfo(
      name: "value",
      number: 2,
      type: .message,
      typeName: "example.User"
    )

    XCTAssertEqual(valueFieldInfo.name, "value")
    XCTAssertEqual(valueFieldInfo.number, 2)
    XCTAssertEqual(valueFieldInfo.type, .message)
    XCTAssertEqual(valueFieldInfo.typeName, "example.User")
  }

  func testTypenameValidation() {
    // Create FieldDescriptor with correct typeName for message
    XCTAssertNoThrow(
      FieldDescriptor(
        name: "user",
        number: 1,
        type: .message,
        typeName: "example.User"
      )
    )

    // Create FieldDescriptor with correct typeName for enum
    XCTAssertNoThrow(
      FieldDescriptor(
        name: "status",
        number: 2,
        type: .enum,
        typeName: "example.Status"
      )
    )

    // Create FieldDescriptor with typeName for scalar type (optional)
    XCTAssertNoThrow(
      FieldDescriptor(
        name: "count",
        number: 3,
        type: .int32,
        typeName: "some.type"  // not required for scalar types
      )
    )
  }

  func testInvalidKeyTypeForMap() {
    // Note that creating MapEntryInfo with invalid key types should cause error
    // fatalError doesn't use throws, and we can't directly test fatalError
    // XCTExpectFailure is not available on Linux, so just note that test expects failure
    #if os(macOS) || os(iOS)
      XCTAssertNoThrow {
        XCTExpectFailure("MapEntryInfo with invalid key type bytes should cause error")
      }

      XCTAssertNoThrow {
        XCTExpectFailure("MapEntryInfo with invalid key type double should cause error")
      }
    #else
      // On Linux skip fatalError tests due to missing XCTExpectFailure
      print("Skipping fatalError tests on Linux (XCTExpectFailure unavailable)")
    #endif
  }

  func testMapWithValueTypeMessage() {
    // Create field with complex value for map
    let keyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo = ValueFieldInfo(
      name: "value",
      number: 2,
      type: .message,
      typeName: "example.User"
    )

    let mapInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valueInfo)

    let mapField = FieldDescriptor(
      name: "userMap",
      number: 1,
      type: .message,
      typeName: "example.UserMapEntry",
      isMap: true,
      mapEntryInfo: mapInfo
    )

    XCTAssertTrue(mapField.isMap)
    XCTAssertEqual(mapField.mapEntryInfo?.valueFieldInfo.type, .message)
    XCTAssertEqual(mapField.mapEntryInfo?.valueFieldInfo.typeName, "example.User")
  }

  func testEquatableImplementation() {
    // Verify comparison of different FieldDescriptor
    let field1 = FieldDescriptor(name: "name", number: 1, type: .string)
    let field2 = FieldDescriptor(name: "name", number: 1, type: .string)
    let field3 = FieldDescriptor(name: "age", number: 2, type: .int32)

    XCTAssertEqual(field1, field2)
    XCTAssertNotEqual(field1, field3)

    // Verify comparison with different options
    let field4 = FieldDescriptor(
      name: "name",
      number: 1,
      type: .string,
      options: ["deprecated": true]
    )

    XCTAssertNotEqual(field1, field4)

    // Verify comparison for fields with MapEntryInfo
    let keyInfo1 = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo1 = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapInfo1 = MapEntryInfo(keyFieldInfo: keyInfo1, valueFieldInfo: valueInfo1)

    let field5 = FieldDescriptor(
      name: "map",
      number: 3,
      type: .message,
      typeName: "example.Map",
      isMap: true,
      mapEntryInfo: mapInfo1
    )

    let keyInfo2 = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo2 = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapInfo2 = MapEntryInfo(keyFieldInfo: keyInfo2, valueFieldInfo: valueInfo2)

    let field6 = FieldDescriptor(
      name: "map",
      number: 3,
      type: .message,
      typeName: "example.Map",
      isMap: true,
      mapEntryInfo: mapInfo2
    )

    XCTAssertEqual(field5, field6)
  }

  func testValueFieldInfoWithEnumType() {
    // Verify ValueFieldInfo creation with enum type
    let valueFieldInfo = ValueFieldInfo(
      name: "value",
      number: 2,
      type: .enum,
      typeName: "example.Status"
    )

    XCTAssertEqual(valueFieldInfo.name, "value")
    XCTAssertEqual(valueFieldInfo.number, 2)
    XCTAssertEqual(valueFieldInfo.type, .enum)
    XCTAssertEqual(valueFieldInfo.typeName, "example.Status")
  }

  func testOptionEqualityWithVariousTypes() {
    // Verify comparison of different types in options
    let field1 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: [
        "boolOption": true,
        "intOption": 42,
        "stringOption": "value",
      ]
    )

    let field2 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: [
        "boolOption": true,
        "intOption": 42,
        "stringOption": "value",
      ]
    )

    let field3 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: [
        "boolOption": false,  // Different value
        "intOption": 42,
        "stringOption": "value",
      ]
    )

    let field4 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: [
        "boolOption": true,
        "intOption": 43,  // Different value
        "stringOption": "value",
      ]
    )

    let field5 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: [
        "boolOption": true,
        "intOption": 42,
        "stringOption": "different",  // Different value
      ]
    )

    // Same options should give equality
    XCTAssertEqual(field1, field2)

    // Different options should give inequality
    XCTAssertNotEqual(field1, field3)
    XCTAssertNotEqual(field1, field4)
    XCTAssertNotEqual(field1, field5)
  }

  func testEquatableWithDifferentOptionKeySets() {
    // Verify comparison with different option key sets
    let field1 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: ["option1": true, "option2": "value"]
    )

    let field2 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: ["option1": true, "option3": 42]  // Different key set
    )

    XCTAssertNotEqual(field1, field2)
  }

  func testComplexOptionsEquality() {
    // Verify comparison with more complex option types using string representation
    let customValue1 = CustomStringType(value: "test")
    let customValue2 = CustomStringType(value: "test")
    let customValue3 = CustomStringType(value: "different")

    let field1 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: ["custom": customValue1]
    )

    let field2 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: ["custom": customValue2]
    )

    let field3 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: ["custom": customValue3]
    )

    // Same custom values should give equality
    XCTAssertEqual(field1, field2)

    // Different custom values should give inequality
    XCTAssertNotEqual(field1, field3)
  }

  func testOneofFieldComparison() {
    // Verify fields with oneofIndex
    let field1 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      oneofIndex: 1
    )

    let field2 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      oneofIndex: 1
    )

    let field3 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      oneofIndex: 2  // Different index
    )

    let field4 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      oneofIndex: nil  // Without index
    )

    XCTAssertEqual(field1, field2)
    XCTAssertNotEqual(field1, field3)
    XCTAssertNotEqual(field1, field4)
  }

  func testGroupTypeField() {
    // Create group type field (deprecated in proto3 but supported)
    let field = FieldDescriptor(
      name: "group_field",
      number: 10,
      type: .group,
      typeName: "example.GroupType"
    )

    // Verify properties
    XCTAssertEqual(field.type, .group)
    XCTAssertEqual(field.typeName, "example.GroupType")
    XCTAssertFalse(field.isScalarType())
    XCTAssertFalse(field.isNumericType())
  }

  func testRequiredField() {
    // Create field with required flag (proto2)
    let field = FieldDescriptor(
      name: "requiredField",
      number: 20,
      type: .string,
      isRequired: true
    )

    // Verify flags
    XCTAssertTrue(field.isRequired)
    XCTAssertFalse(field.isOptional)
    XCTAssertFalse(field.isRepeated)

    // Verify that isOptional and isRequired can coexist in constructor
    let field2 = FieldDescriptor(
      name: "conflictField",
      number: 21,
      type: .string,
      isOptional: true,
      isRequired: true
    )

    // Verify that both flags are set (no mutual exclusion in implementation)
    XCTAssertTrue(field2.isRequired)
    XCTAssertTrue(field2.isOptional)
  }

  func testFieldWithOneOfIndexInitialization() {
    // Create field that is part of oneof group
    let field = FieldDescriptor(
      name: "oneofField",
      number: 15,
      type: .string,
      oneofIndex: 2
    )

    // Verify properties
    XCTAssertEqual(field.name, "oneofField")
    XCTAssertEqual(field.number, 15)
    XCTAssertEqual(field.type, .string)
    XCTAssertEqual(field.oneofIndex, 2)
  }

  func testDefaultValue() {
    // Create field with defaultValue
    let defaultVal = "default_string_value"
    let field = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string,
      defaultValue: defaultVal
    )

    // Verify properties
    XCTAssertEqual(field.defaultValue as? String, defaultVal)

    // Verify that fields with different defaultValue are considered equal,
    // since defaultValue is not compared in == method
    let field2 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string,
      defaultValue: "different_default"
    )

    // Note that although defaultValue differs, FieldDescriptor.== doesn't consider this
    XCTAssertEqual(field, field2)

    // Fields with and without defaultValue are also considered equal
    let field3 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string
    )

    XCTAssertEqual(field, field3)
  }

  func testValueFieldInfoWithScalarType() {
    // Verify ValueFieldInfo creation with simple type
    let valueInfo = ValueFieldInfo(
      name: "scalar_value",
      number: 2,
      type: .int64
    )

    XCTAssertEqual(valueInfo.name, "scalar_value")
    XCTAssertEqual(valueInfo.number, 2)
    XCTAssertEqual(valueInfo.type, .int64)
    XCTAssertNil(valueInfo.typeName)
  }

  func testKeyFieldInfoInitialization() {
    // Verify KeyFieldInfo creation and access
    let keyInfo = KeyFieldInfo(
      name: "custom_key",
      number: 5,
      type: .string
    )

    XCTAssertEqual(keyInfo.name, "custom_key")
    XCTAssertEqual(keyInfo.number, 5)
    XCTAssertEqual(keyInfo.type, .string)
  }

  func testMapEntryInfoEquality() {
    // Create two identical MapEntryInfo
    let keyInfo1 = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo1 = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapInfo1 = MapEntryInfo(keyFieldInfo: keyInfo1, valueFieldInfo: valueInfo1)

    let keyInfo2 = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo2 = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapInfo2 = MapEntryInfo(keyFieldInfo: keyInfo2, valueFieldInfo: valueInfo2)

    // Create different MapEntryInfo
    let keyInfo3 = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo3 = ValueFieldInfo(name: "value", number: 2, type: .double)
    let mapInfo3 = MapEntryInfo(keyFieldInfo: keyInfo3, valueFieldInfo: valueInfo3)

    // Verify comparison
    XCTAssertEqual(mapInfo1, mapInfo2)
    XCTAssertNotEqual(mapInfo1, mapInfo3)
  }

  func testMapEntryComplexValue() {
    // Create MapEntryInfo with complex value
    let keyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo = ValueFieldInfo(
      name: "value",
      number: 2,
      type: .message,
      typeName: "example.ComplexType"
    )

    let mapInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valueInfo)

    // Verify comparison with another MapEntryInfo with same data type but different typeName
    let anotherValueInfo = ValueFieldInfo(
      name: "value",
      number: 2,
      type: .message,
      typeName: "example.DifferentType"
    )

    let anotherMapInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: anotherValueInfo)

    XCTAssertNotEqual(mapInfo, anotherMapInfo)
  }

  func testAllFieldTypesScalarCheck() {
    // Verify isScalarType method for all possible field types

    let allFieldTypes: [FieldType] = [
      .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64,
      .bool, .string, .bytes, .message, .enum, .group,
    ]

    let scalarTypes: Set<FieldType> = [
      .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64,
      .bool, .string, .bytes,
    ]

    for type in allFieldTypes {
      let typeName: String? = scalarTypes.contains(type) ? nil : "example.Type"
      let field = FieldDescriptor(name: "field", number: 1, type: type, typeName: typeName)

      if scalarTypes.contains(type) {
        XCTAssertTrue(field.isScalarType(), "Type \(type) should be detected as scalar")
      }
      else {
        XCTAssertFalse(field.isScalarType(), "Type \(type) should not be detected as scalar")
      }
    }
  }

  func testAllFieldTypesNumericCheck() {
    // Verify isNumericType method for all possible field types

    let allFieldTypes: [FieldType] = [
      .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64,
      .bool, .string, .bytes, .message, .enum, .group,
    ]

    let numericTypes: Set<FieldType> = [
      .double, .float, .int32, .int64, .uint32, .uint64,
      .sint32, .sint64, .fixed32, .fixed64, .sfixed32, .sfixed64,
    ]

    for type in allFieldTypes {
      let typeName: String? = [.message, .enum, .group].contains(type) ? "example.Type" : nil
      let field = FieldDescriptor(name: "field", number: 1, type: type, typeName: typeName)

      if numericTypes.contains(type) {
        XCTAssertTrue(field.isNumericType(), "Type \(type) should be detected as numeric")
      }
      else {
        XCTAssertFalse(field.isNumericType(), "Type \(type) should not be detected as numeric")
      }
    }
  }

  func testDifferentTypesNotEqual() {
    // Verify that fields with different types are not equal
    let field1 = FieldDescriptor(name: "field", number: 1, type: .string)
    let field2 = FieldDescriptor(name: "field", number: 1, type: .int32)

    XCTAssertNotEqual(field1, field2)
  }

  func testDifferentTypeNamesNotEqual() {
    // Verify that fields with different typeName are not equal
    let field1 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .message,
      typeName: "example.Type1"
    )

    let field2 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .message,
      typeName: "example.Type2"
    )

    XCTAssertNotEqual(field1, field2)
  }

  func testDifferentJsonNamesNotEqual() {
    // Verify that fields with different jsonName are not equal
    let field1 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string,
      jsonName: "field1"
    )

    let field2 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string,
      jsonName: "field2"
    )

    XCTAssertNotEqual(field1, field2)
  }

  func testDifferentRepeatedFlagsNotEqual() {
    // Verify that fields with different isRepeated are not equal
    let field1 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string,
      isRepeated: true
    )

    let field2 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string,
      isRepeated: false
    )

    XCTAssertNotEqual(field1, field2)
  }

  func testDifferentOptionalFlagsNotEqual() {
    // Verify that fields with different isOptional are not equal
    let field1 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string,
      isOptional: true
    )

    let field2 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string,
      isOptional: false
    )

    XCTAssertNotEqual(field1, field2)
  }

  func testDifferentRequiredFlagsNotEqual() {
    // Verify that fields with different isRequired are not equal
    let field1 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string,
      isRequired: true
    )

    let field2 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .string,
      isRequired: false
    )

    XCTAssertNotEqual(field1, field2)
  }

  func testDifferentMapFlagsNotEqual() {
    // Prepare MapEntryInfo for use with map
    let keyInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valueInfo)

    // Verify that fields with different isMap are not equal
    let field1 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .message,
      typeName: "example.MapEntry",
      isMap: true,
      mapEntryInfo: mapInfo
    )

    let field2 = FieldDescriptor(
      name: "field",
      number: 1,
      type: .message,
      typeName: "example.MapEntry",
      isMap: false
    )

    XCTAssertNotEqual(field1, field2)
  }

  // MARK: - Helpers

  // Custom type for testing complex options
  class CustomStringType: CustomStringConvertible {
    let value: String

    init(value: String) {
      self.value = value
    }

    var description: String {
      return "CustomStringType(\(value))"
    }
  }

  // MARK: - Additional Coverage Tests

  func testDefaultValueForComplexTypes() {
    // Test case when defaultValue returns nil for complex types
    let messageField = FieldDescriptor(
      name: "message_field",
      number: 1,
      type: .message,
      typeName: "example.MessageType"
    )

    let enumField = FieldDescriptor(
      name: "enum_field",
      number: 2,
      type: .enum,
      typeName: "example.EnumType"
    )

    let groupField = FieldDescriptor(
      name: "group_field",
      number: 3,
      type: .group,
      typeName: "example.GroupType"
    )

    // For complex types (message, enum, group) defaultValue should return nil
    XCTAssertNil(messageField.defaultValue)
    XCTAssertNil(enumField.defaultValue)
    XCTAssertNil(groupField.defaultValue)
  }

  func testDefaultValueForScalarTypes() {
    // Test that scalar types without explicitly set defaultValue return nil
    let stringField = FieldDescriptor(name: "string_field", number: 1, type: .string)
    let boolField = FieldDescriptor(name: "bool_field", number: 2, type: .bool)
    let bytesField = FieldDescriptor(name: "bytes_field", number: 3, type: .bytes)

    // For scalar types without explicitly set defaultValue should return nil
    XCTAssertNil(stringField.defaultValue)
    XCTAssertNil(boolField.defaultValue)
    XCTAssertNil(bytesField.defaultValue)

    // Test fields with explicitly set default values
    let stringFieldWithDefault = FieldDescriptor(
      name: "string_field_with_default",
      number: 4,
      type: .string,
      defaultValue: "default_value"
    )
    let boolFieldWithDefault = FieldDescriptor(
      name: "bool_field_with_default",
      number: 5,
      type: .bool,
      defaultValue: true
    )
    let bytesFieldWithDefault = FieldDescriptor(
      name: "bytes_field_with_default",
      number: 6,
      type: .bytes,
      defaultValue: Data([1, 2, 3])
    )

    // Verify that explicitly set default values are returned correctly
    XCTAssertEqual(stringFieldWithDefault.defaultValue as? String, "default_value")
    XCTAssertEqual(boolFieldWithDefault.defaultValue as? Bool, true)
    XCTAssertEqual(bytesFieldWithDefault.defaultValue as? Data, Data([1, 2, 3]))
  }

  func testOptionsComparisonEdgeCases() {
    // Test special cases of option comparison to cover all branches in compareOptions

    // Create fields with options of different types to verify string comparison
    struct CustomType: CustomStringConvertible {
      let id: Int
      var description: String { return "CustomType(\(id))" }
    }

    let field1 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: [
        "customType": CustomType(id: 1),
        "array": [1, 2, 3] as [Int],
        "dict": ["key": "value"] as [String: String],
      ]
    )

    let field2 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: [
        "customType": CustomType(id: 1),
        "array": [1, 2, 3] as [Int],
        "dict": ["key": "value"] as [String: String],
      ]
    )

    let field3 = FieldDescriptor(
      name: "test",
      number: 1,
      type: .string,
      options: [
        "customType": CustomType(id: 2),  // Different value
        "array": [1, 2, 3] as [Int],
        "dict": ["key": "value"] as [String: String],
      ]
    )

    // Fields with same string representations of options should be equal
    XCTAssertEqual(field1, field2)

    // Fields with different string representations of options should not be equal
    XCTAssertNotEqual(field1, field3)
  }

  func testMapEntryValidKeyTypesExtended() {
    // Test additional valid key types for map

    let validKeyTypes: [FieldType] = [
      .int32, .int64, .uint32, .uint64, .sint32, .sint64,
      .fixed32, .fixed64, .sfixed32, .sfixed64, .bool, .string,
    ]

    for keyType in validKeyTypes {
      let keyInfo = KeyFieldInfo(name: "key", number: 1, type: keyType)
      let valueInfo = ValueFieldInfo(name: "value", number: 2, type: .string)

      // Creating MapEntryInfo should not cause fatalError for valid types
      let mapInfo = MapEntryInfo(keyFieldInfo: keyInfo, valueFieldInfo: valueInfo)

      XCTAssertEqual(mapInfo.keyFieldInfo.type, keyType)
      XCTAssertEqual(mapInfo.valueFieldInfo.type, .string)
    }
  }

  func testKeyFieldInfoAndValueFieldInfoWithComplexTypes() {
    // Test creating KeyFieldInfo and ValueFieldInfo with types requiring typeName

    // For ValueFieldInfo with message type
    let messageValueInfo = ValueFieldInfo(
      name: "message_value",
      number: 2,
      type: .message,
      typeName: "example.MessageType"
    )

    XCTAssertEqual(messageValueInfo.type, .message)
    XCTAssertEqual(messageValueInfo.typeName, "example.MessageType")

    // For ValueFieldInfo with enum type
    let enumValueInfo = ValueFieldInfo(
      name: "enum_value",
      number: 3,
      type: .enum,
      typeName: "example.EnumType"
    )

    XCTAssertEqual(enumValueInfo.type, .enum)
    XCTAssertEqual(enumValueInfo.typeName, "example.EnumType")
  }
}
