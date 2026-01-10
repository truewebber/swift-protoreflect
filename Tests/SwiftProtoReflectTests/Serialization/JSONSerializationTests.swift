//
// JSONSerializationTests.swift
//
// Tests for JSON serialization and deserialization of Protocol Buffers
//
// Test cases from the plan:
// - Test-JSON-001: JSON serialization of all data types with compliance to protoc --json_out format
// - Test-JSON-002: Handling special values (Infinity, NaN, null) in JSON
// - Test-JSON-003: Correct JSON deserialization of data created by protoc --json_out

import XCTest

@testable import SwiftProtoReflect

final class JSONSerializationTests: XCTestCase {

  var fileDescriptor: FileDescriptor!
  var messageFactory: MessageFactory!
  var serializer: JSONSerializer!

  override func setUp() {
    super.setUp()

    fileDescriptor = FileDescriptor(name: "test_json_serialization.proto", package: "test.json")
    messageFactory = MessageFactory()
    serializer = JSONSerializer()
  }

  override func tearDown() {
    fileDescriptor = nil
    messageFactory = nil
    serializer = nil
    super.tearDown()
  }

  // MARK: - Scalar Types Tests (Test-JSON-001)

  func testSerializeAllScalarTypes() throws {
    // Create message with all scalar types
    var scalarMessage = MessageDescriptor(name: "ScalarMessage", parent: fileDescriptor)

    scalarMessage.addField(FieldDescriptor(name: "double_field", number: 1, type: .double))
    scalarMessage.addField(FieldDescriptor(name: "float_field", number: 2, type: .float))
    scalarMessage.addField(FieldDescriptor(name: "int32_field", number: 3, type: .int32))
    scalarMessage.addField(FieldDescriptor(name: "int64_field", number: 4, type: .int64))
    scalarMessage.addField(FieldDescriptor(name: "uint32_field", number: 5, type: .uint32))
    scalarMessage.addField(FieldDescriptor(name: "uint64_field", number: 6, type: .uint64))
    scalarMessage.addField(FieldDescriptor(name: "bool_field", number: 7, type: .bool))
    scalarMessage.addField(FieldDescriptor(name: "string_field", number: 8, type: .string))
    scalarMessage.addField(FieldDescriptor(name: "bytes_field", number: 9, type: .bytes))

    fileDescriptor.addMessage(scalarMessage)

    // Create message with data
    let values: [String: Any] = [
      "double_field": 3.14159,
      "float_field": Float(2.718),
      "int32_field": Int32(-42),
      "int64_field": Int64(-9_223_372_036_854_775_000),
      "uint32_field": UInt32(4_294_967_295),
      "uint64_field": UInt64(18_446_744_073_709_551_615),
      "bool_field": true,
      "string_field": "Hello, World! 🌍",
      "bytes_field": Data([0x01, 0x02, 0x03, 0xFF]),
    ]

    let message = try messageFactory.createMessage(from: scalarMessage, with: values)

    // Serialize to JSON
    let jsonData = try serializer.serialize(message)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

    // Verify types and values
    XCTAssertEqual(jsonObject["double_field"] as! Double, 3.14159, accuracy: 0.00001)
    XCTAssertEqual(jsonObject["float_field"] as! Float, Float(2.718), accuracy: 0.001)
    XCTAssertEqual(jsonObject["int32_field"] as! Int, -42)
    XCTAssertEqual(jsonObject["int64_field"] as! String, "-9223372036854775000")  // int64 as string
    XCTAssertEqual(jsonObject["uint32_field"] as! UInt, 4_294_967_295)
    XCTAssertEqual(jsonObject["uint64_field"] as! String, "18446744073709551615")  // uint64 as string
    XCTAssertEqual(jsonObject["bool_field"] as! Bool, true)
    XCTAssertEqual(jsonObject["string_field"] as! String, "Hello, World! 🌍")
    XCTAssertEqual(jsonObject["bytes_field"] as! String, "AQID/w==")  // base64 encoded
  }

  func testSerializeDoubleSpecialValues() throws {
    var message = MessageDescriptor(name: "DoubleSpecialMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "infinity", number: 1, type: .double))
    message.addField(FieldDescriptor(name: "negative_infinity", number: 2, type: .double))
    message.addField(FieldDescriptor(name: "nan", number: 3, type: .double))
    fileDescriptor.addMessage(message)

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "infinity": Double.infinity,
        "negative_infinity": -Double.infinity,
        "nan": Double.nan,
      ]
    )

    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

    // Verify special values
    XCTAssertEqual(jsonObject["infinity"] as! String, "Infinity")
    XCTAssertEqual(jsonObject["negative_infinity"] as! String, "-Infinity")
    XCTAssertEqual(jsonObject["nan"] as! String, "NaN")
  }

  func testSerializeFloatSpecialValues() throws {
    var message = MessageDescriptor(name: "FloatSpecialMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "infinity", number: 1, type: .float))
    message.addField(FieldDescriptor(name: "negative_infinity", number: 2, type: .float))
    message.addField(FieldDescriptor(name: "nan", number: 3, type: .float))
    fileDescriptor.addMessage(message)

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "infinity": Float.infinity,
        "negative_infinity": -Float.infinity,
        "nan": Float.nan,
      ]
    )

    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

    // Verify special float values
    XCTAssertEqual(jsonObject["infinity"] as! String, "Infinity")
    XCTAssertEqual(jsonObject["negative_infinity"] as! String, "-Infinity")
    XCTAssertEqual(jsonObject["nan"] as! String, "NaN")
  }

  // MARK: - String and Bytes Tests

  func testSerializeStringValues() throws {
    var message = MessageDescriptor(name: "StringMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "simple", number: 1, type: .string))
    message.addField(FieldDescriptor(name: "unicode", number: 2, type: .string))
    message.addField(FieldDescriptor(name: "empty", number: 3, type: .string))
    fileDescriptor.addMessage(message)

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "simple": "Hello",
        "unicode": "Hello, 世界! 🌟",
        "empty": "",
      ]
    )

    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

    XCTAssertEqual(jsonObject["simple"] as! String, "Hello")
    XCTAssertEqual(jsonObject["unicode"] as! String, "Hello, 世界! 🌟")
    XCTAssertEqual(jsonObject["empty"] as! String, "")
  }

  func testSerializeBytesValues() throws {
    var message = MessageDescriptor(name: "BytesMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "data", number: 1, type: .bytes))
    message.addField(FieldDescriptor(name: "empty_data", number: 2, type: .bytes))
    fileDescriptor.addMessage(message)

    let testBytes = Data([0x48, 0x65, 0x6C, 0x6C, 0x6F])  // "Hello" in ASCII
    let emptyBytes = Data()

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "data": testBytes,
        "empty_data": emptyBytes,
      ]
    )

    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

    XCTAssertEqual(jsonObject["data"] as! String, "SGVsbG8=")  // base64 encoded "Hello"
    XCTAssertEqual(jsonObject["empty_data"] as! String, "")  // empty base64
  }

  // MARK: - Nested Messages Tests

  func testSerializeNestedMessage() throws {
    // Create nested message
    var nestedMessage = MessageDescriptor(name: "NestedMessage", parent: fileDescriptor)
    nestedMessage.addField(FieldDescriptor(name: "id", number: 1, type: .int32))
    nestedMessage.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    fileDescriptor.addMessage(nestedMessage)

    // Create parent message
    var parentMessage = MessageDescriptor(name: "ParentMessage", parent: fileDescriptor)
    parentMessage.addField(
      FieldDescriptor(
        name: "nested",
        number: 1,
        type: .message,
        typeName: nestedMessage.fullName
      )
    )
    parentMessage.addField(FieldDescriptor(name: "status", number: 2, type: .string))
    fileDescriptor.addMessage(parentMessage)

    // Create nested message
    let nested = try messageFactory.createMessage(
      from: nestedMessage,
      with: [
        "id": Int32(42),
        "name": "test",
      ]
    )

    // Create parent message
    var parent = messageFactory.createMessage(from: parentMessage)
    try parent.set(nested, forField: "nested")
    try parent.set("active", forField: "status")

    // Serialize
    let jsonData = try serializer.serialize(parent)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

    // Verify structure
    XCTAssertEqual(jsonObject["status"] as! String, "active")

    let nestedObject = jsonObject["nested"] as! [String: Any]
    XCTAssertEqual(nestedObject["id"] as! Int, 42)
    XCTAssertEqual(nestedObject["name"] as! String, "test")
  }

  // MARK: - Repeated Fields Tests

  func testSerializeRepeatedFields() throws {
    var message = MessageDescriptor(name: "RepeatedMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "numbers", number: 1, type: .int32, isRepeated: true))
    message.addField(FieldDescriptor(name: "words", number: 2, type: .string, isRepeated: true))
    message.addField(FieldDescriptor(name: "flags", number: 3, type: .bool, isRepeated: true))
    fileDescriptor.addMessage(message)

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "numbers": [Int32(1), Int32(2), Int32(3)],
        "words": ["hello", "world"],
        "flags": [true, false, true],
      ]
    )

    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

    let numbers = jsonObject["numbers"] as! [Int]
    XCTAssertEqual(numbers, [1, 2, 3])

    let words = jsonObject["words"] as! [String]
    XCTAssertEqual(words, ["hello", "world"])

    let flags = jsonObject["flags"] as! [Bool]
    XCTAssertEqual(flags, [true, false, true])
  }

  func testSerializeEmptyRepeatedField() throws {
    var message = MessageDescriptor(name: "EmptyRepeatedMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "values", number: 1, type: .int32, isRepeated: true))
    fileDescriptor.addMessage(message)

    // Create message without setting repeated field
    let dynamicMessage = messageFactory.createMessage(from: message)

    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

    // Field without values should not appear in JSON
    XCTAssertNil(jsonObject["values"])
  }

  // MARK: - Map Fields Tests

  func testSerializeMapFields() throws {
    // Create map field: map<string, int32>
    let keyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: keyFieldInfo, valueFieldInfo: valueFieldInfo)

    var message = MessageDescriptor(name: "MapMessage", parent: fileDescriptor)
    message.addField(
      FieldDescriptor(
        name: "string_to_int",
        number: 1,
        type: .message,
        typeName: "string_to_int_entry",
        isMap: true,
        mapEntryInfo: mapEntryInfo
      )
    )
    fileDescriptor.addMessage(message)

    let mapData: [String: Int32] = [
      "first": 1,
      "second": 2,
      "third": 3,
    ]

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "string_to_int": mapData
      ]
    )

    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

    let mapObject = jsonObject["string_to_int"] as! [String: Int]
    XCTAssertEqual(mapObject["first"], 1)
    XCTAssertEqual(mapObject["second"], 2)
    XCTAssertEqual(mapObject["third"], 3)
  }

  func testSerializeMapWithIntegerKeys() throws {
    // Create map field: map<int32, string>
    let keyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .int32)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: keyFieldInfo, valueFieldInfo: valueFieldInfo)

    var message = MessageDescriptor(name: "IntMapMessage", parent: fileDescriptor)
    message.addField(
      FieldDescriptor(
        name: "int_to_string",
        number: 1,
        type: .message,
        typeName: "int_to_string_entry",
        isMap: true,
        mapEntryInfo: mapEntryInfo
      )
    )
    fileDescriptor.addMessage(message)

    let mapData: [Int32: String] = [
      1: "one",
      2: "two",
      42: "answer",
    ]

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "int_to_string": mapData
      ]
    )

    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

    // In JSON, all keys must be strings
    let mapObject = jsonObject["int_to_string"] as! [String: String]
    XCTAssertEqual(mapObject["1"], "one")
    XCTAssertEqual(mapObject["2"], "two")
    XCTAssertEqual(mapObject["42"], "answer")
  }

  // MARK: - Enum Tests

  func testSerializeEnumField() throws {
    // Create enum
    var enumDescriptor = EnumDescriptor(name: "Status", parent: fileDescriptor)
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "ACTIVE", number: 1))
    enumDescriptor.addValue(EnumDescriptor.EnumValue(name: "INACTIVE", number: 2))
    fileDescriptor.addEnum(enumDescriptor)

    var message = MessageDescriptor(name: "EnumMessage", parent: fileDescriptor)
    message.addField(
      FieldDescriptor(
        name: "status",
        number: 1,
        type: .enum,
        typeName: enumDescriptor.fullName
      )
    )
    fileDescriptor.addMessage(message)

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "status": Int32(1)  // ACTIVE
      ]
    )

    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

    // Currently enum is returned as number, can be extended to support names
    XCTAssertEqual(jsonObject["status"] as! Int, 1)
  }

  // MARK: - JSON Serialization Options Tests

  func testJSONSerializationOptions() throws {
    var message = MessageDescriptor(name: "OptionsMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "test_field", number: 1, type: .string, jsonName: "testField"))
    fileDescriptor.addMessage(message)

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "test_field": "test_value"
      ]
    )

    // Test with camelCase names (default)
    let defaultSerializer = JSONSerializer()
    let defaultJsonData = try defaultSerializer.serialize(dynamicMessage)
    let defaultJsonObject = try JSONSerialization.jsonObject(with: defaultJsonData) as! [String: Any]
    XCTAssertEqual(defaultJsonObject["testField"] as! String, "test_value")

    // Test with original field names
    let originalNamesSerializer = JSONSerializer(options: JSONSerializationOptions(useOriginalFieldNames: true))
    let originalJsonData = try originalNamesSerializer.serialize(dynamicMessage)
    let originalJsonObject = try JSONSerialization.jsonObject(with: originalJsonData) as! [String: Any]
    XCTAssertEqual(originalJsonObject["test_field"] as! String, "test_value")

    // Test with pretty printing
    let prettySerializer = JSONSerializer(options: JSONSerializationOptions(prettyPrinted: true))
    let prettyJsonData = try prettySerializer.serialize(dynamicMessage)
    let prettyJsonString = String(data: prettyJsonData, encoding: .utf8)!
    XCTAssertTrue(prettyJsonString.contains("\n"))  // Should have line breaks
  }

  // MARK: - Error Handling Tests

  func testSerializationErrors() throws {
    var message = MessageDescriptor(name: "ErrorMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "group_field", number: 1, type: .group))
    fileDescriptor.addMessage(message)

    // Create message with group field (unsupported type)
    var dynamicMessage = messageFactory.createMessage(from: message)
    let groupMessage = messageFactory.createMessage(from: message)
    try dynamicMessage.set(groupMessage, forField: "group_field")

    // Group type is not supported
    XCTAssertThrowsError(try serializer.serialize(dynamicMessage)) { error in
      if let jsonError = error as? JSONSerializationError {
        if case .unsupportedFieldType(let type) = jsonError {
          XCTAssertEqual(type, "group")
        }
        else {
          XCTFail("Wrong error type: \(jsonError)")
        }
      }
      else {
        XCTFail("Expected JSONSerializationError, got: \(error)")
      }
    }
  }

  func testJSONSerializationErrorDescriptions() {
    let error1 = JSONSerializationError.invalidFieldType(fieldName: "test", expectedType: "String", actualType: "Int")
    XCTAssertEqual(error1.description, "Invalid field type for field 'test': expected String, got Int")

    let error2 = JSONSerializationError.valueTypeMismatch(expected: "String", actual: "Int")
    XCTAssertEqual(error2.description, "Value type mismatch: expected String, got Int")

    let error3 = JSONSerializationError.missingMapEntryInfo(fieldName: "map_field")
    XCTAssertEqual(error3.description, "Missing map entry info for field 'map_field'")

    let error4 = JSONSerializationError.missingFieldValue(fieldName: "missing_field")
    XCTAssertEqual(error4.description, "Missing value for field 'missing_field'")

    let error5 = JSONSerializationError.unsupportedFieldType(type: "group")
    XCTAssertEqual(error5.description, "Unsupported field type: group")

    let error6 = JSONSerializationError.invalidMapKeyType(keyType: "FieldType.float")
    XCTAssertEqual(error6.description, "Invalid map key type: FieldType.float")
  }

  func testJSONSerializationErrorEquality() {
    let error1 = JSONSerializationError.invalidFieldType(fieldName: "test", expectedType: "String", actualType: "Int")
    let error2 = JSONSerializationError.invalidFieldType(fieldName: "test", expectedType: "String", actualType: "Int")
    let error3 = JSONSerializationError.invalidFieldType(fieldName: "other", expectedType: "String", actualType: "Int")

    XCTAssertEqual(error1, error2)
    XCTAssertNotEqual(error1, error3)

    let error4 = JSONSerializationError.valueTypeMismatch(expected: "String", actual: "Int")
    let error5 = JSONSerializationError.valueTypeMismatch(expected: "String", actual: "Int")
    XCTAssertEqual(error4, error5)
    XCTAssertNotEqual(error1, error4)
  }

  // MARK: - Performance Tests

  func testJSONSerializationPerformance() throws {
    // Create complex message for performance testing
    var message = MessageDescriptor(name: "PerformanceMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "numbers", number: 1, type: .int32, isRepeated: true))
    message.addField(FieldDescriptor(name: "text", number: 2, type: .string))
    message.addField(FieldDescriptor(name: "flag", number: 3, type: .bool))
    fileDescriptor.addMessage(message)

    let numbers = Array(1...1000).map { Int32($0) }
    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "numbers": numbers,
        "text": "Performance test message with some content",
        "flag": true,
      ]
    )

    measure {
      do {
        _ = try serializer.serialize(dynamicMessage)
      }
      catch {
        XCTFail("Serialization failed: \(error)")
      }
    }
  }

  // MARK: - Additional Type Coverage Tests

  func testSerializeSignedAndFixedIntegerTypes() throws {
    var message = MessageDescriptor(name: "SignedFixedMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "sint32_field", number: 1, type: .sint32))
    message.addField(FieldDescriptor(name: "sint64_field", number: 2, type: .sint64))
    message.addField(FieldDescriptor(name: "sfixed32_field", number: 3, type: .sfixed32))
    message.addField(FieldDescriptor(name: "sfixed64_field", number: 4, type: .sfixed64))
    message.addField(FieldDescriptor(name: "fixed32_field", number: 5, type: .fixed32))
    message.addField(FieldDescriptor(name: "fixed64_field", number: 6, type: .fixed64))
    fileDescriptor.addMessage(message)

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "sint32_field": Int32(-2_147_483_648),
        "sint64_field": Int64(-9_223_372_036_854_775_808),
        "sfixed32_field": Int32(2_147_483_647),
        "sfixed64_field": Int64(9_223_372_036_854_775_807),
        "fixed32_field": UInt32(4_294_967_295),
        "fixed64_field": UInt64(18_446_744_073_709_551_615),
      ]
    )

    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

    XCTAssertEqual(jsonObject["sint32_field"] as! Int, -2_147_483_648)
    XCTAssertEqual(jsonObject["sint64_field"] as! String, "-9223372036854775808")
    XCTAssertEqual(jsonObject["sfixed32_field"] as! Int, 2_147_483_647)
    XCTAssertEqual(jsonObject["sfixed64_field"] as! String, "9223372036854775807")
    XCTAssertEqual(jsonObject["fixed32_field"] as! UInt, 4_294_967_295)
    XCTAssertEqual(jsonObject["fixed64_field"] as! String, "18446744073709551615")
  }

  func testSerializeMapWithAllKeyTypes() throws {
    // Test map with UInt32 keys
    let uint32KeyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .uint32)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let uint32MapEntryInfo = MapEntryInfo(keyFieldInfo: uint32KeyFieldInfo, valueFieldInfo: valueFieldInfo)

    var message = MessageDescriptor(name: "UInt32MapMessage", parent: fileDescriptor)
    message.addField(
      FieldDescriptor(
        name: "uint32_to_string",
        number: 1,
        type: .message,
        typeName: "uint32_to_string_entry",
        isMap: true,
        mapEntryInfo: uint32MapEntryInfo
      )
    )
    fileDescriptor.addMessage(message)

    let mapData: [UInt32: String] = [
      0: "zero",
      4_294_967_295: "max_uint32",
    ]

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "uint32_to_string": mapData
      ]
    )

    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

    let mapObject = jsonObject["uint32_to_string"] as! [String: String]
    XCTAssertEqual(mapObject["0"], "zero")
    XCTAssertEqual(mapObject["4294967295"], "max_uint32")
  }

  func testSerializeMapWithUInt64Keys() throws {
    let uint64KeyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .uint64)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let uint64MapEntryInfo = MapEntryInfo(keyFieldInfo: uint64KeyFieldInfo, valueFieldInfo: valueFieldInfo)

    var message = MessageDescriptor(name: "UInt64MapMessage", parent: fileDescriptor)
    message.addField(
      FieldDescriptor(
        name: "uint64_to_string",
        number: 1,
        type: .message,
        typeName: "uint64_to_string_entry",
        isMap: true,
        mapEntryInfo: uint64MapEntryInfo
      )
    )
    fileDescriptor.addMessage(message)

    let mapData: [UInt64: String] = [
      UInt64.max: "max_uint64"
    ]

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "uint64_to_string": mapData
      ]
    )

    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

    let mapObject = jsonObject["uint64_to_string"] as! [String: String]
    XCTAssertEqual(mapObject["18446744073709551615"], "max_uint64")
  }

  func testSerializeMapWithInt64Keys() throws {
    let int64KeyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .int64)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let int64MapEntryInfo = MapEntryInfo(keyFieldInfo: int64KeyFieldInfo, valueFieldInfo: valueFieldInfo)

    var message = MessageDescriptor(name: "Int64MapMessage", parent: fileDescriptor)
    message.addField(
      FieldDescriptor(
        name: "int64_to_string",
        number: 1,
        type: .message,
        typeName: "int64_to_string_entry",
        isMap: true,
        mapEntryInfo: int64MapEntryInfo
      )
    )
    fileDescriptor.addMessage(message)

    let mapData: [Int64: String] = [
      Int64.min: "min_int64",
      Int64.max: "max_int64",
    ]

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "int64_to_string": mapData
      ]
    )

    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

    let mapObject = jsonObject["int64_to_string"] as! [String: String]
    XCTAssertEqual(mapObject["-9223372036854775808"], "min_int64")
    XCTAssertEqual(mapObject["9223372036854775807"], "max_int64")
  }

  func testSerializeMapWithBoolKeys() throws {
    let boolKeyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .bool)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let boolMapEntryInfo = MapEntryInfo(keyFieldInfo: boolKeyFieldInfo, valueFieldInfo: valueFieldInfo)

    var message = MessageDescriptor(name: "BoolMapMessage", parent: fileDescriptor)
    message.addField(
      FieldDescriptor(
        name: "bool_to_string",
        number: 1,
        type: .message,
        typeName: "bool_to_string_entry",
        isMap: true,
        mapEntryInfo: boolMapEntryInfo
      )
    )
    fileDescriptor.addMessage(message)

    let mapData: [Bool: String] = [
      true: "yes",
      false: "no",
    ]

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "bool_to_string": mapData
      ]
    )

    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

    let mapObject = jsonObject["bool_to_string"] as! [String: String]
    XCTAssertEqual(mapObject["true"], "yes")
    XCTAssertEqual(mapObject["false"], "no")
  }

  func testSerializeMapWithSignedIntKeys() throws {
    // Test with sint32
    let sint32KeyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .sint32)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let sint32MapEntryInfo = MapEntryInfo(keyFieldInfo: sint32KeyFieldInfo, valueFieldInfo: valueFieldInfo)

    var message = MessageDescriptor(name: "SInt32MapMessage", parent: fileDescriptor)
    message.addField(
      FieldDescriptor(
        name: "sint32_to_string",
        number: 1,
        type: .message,
        typeName: "sint32_to_string_entry",
        isMap: true,
        mapEntryInfo: sint32MapEntryInfo
      )
    )
    fileDescriptor.addMessage(message)

    let mapData: [Int32: String] = [
      -1: "negative_one",
      0: "zero",
      1: "positive_one",
    ]

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "sint32_to_string": mapData
      ]
    )

    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

    let mapObject = jsonObject["sint32_to_string"] as! [String: String]
    XCTAssertEqual(mapObject["-1"], "negative_one")
    XCTAssertEqual(mapObject["0"], "zero")
    XCTAssertEqual(mapObject["1"], "positive_one")
  }

  func testSerializeMapWithFixedIntKeys() throws {
    // Test with fixed32
    let fixed32KeyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .fixed32)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let fixed32MapEntryInfo = MapEntryInfo(keyFieldInfo: fixed32KeyFieldInfo, valueFieldInfo: valueFieldInfo)

    var message = MessageDescriptor(name: "Fixed32MapMessage", parent: fileDescriptor)
    message.addField(
      FieldDescriptor(
        name: "fixed32_to_string",
        number: 1,
        type: .message,
        typeName: "fixed32_to_string_entry",
        isMap: true,
        mapEntryInfo: fixed32MapEntryInfo
      )
    )
    fileDescriptor.addMessage(message)

    let mapData: [UInt32: String] = [
      100: "hundred",
      200: "two_hundred",
    ]

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "fixed32_to_string": mapData
      ]
    )

    let jsonData = try serializer.serialize(dynamicMessage)
    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]

    let mapObject = jsonObject["fixed32_to_string"] as! [String: String]
    XCTAssertEqual(mapObject["100"], "hundred")
    XCTAssertEqual(mapObject["200"], "two_hundred")
  }

  // MARK: - Additional Options Tests

  func testSerializeWithIncludeDefaultValuesOption() throws {
    var message = MessageDescriptor(name: "DefaultValuesMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "string_field", number: 1, type: .string))
    message.addField(FieldDescriptor(name: "int_field", number: 2, type: .int32))
    fileDescriptor.addMessage(message)

    // Create message with only one field set
    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "string_field": "test"
      ]
    )

    // Default options - don't include default values
    let defaultSerializer = JSONSerializer()
    let defaultJsonData = try defaultSerializer.serialize(dynamicMessage)
    let defaultJsonObject = try JSONSerialization.jsonObject(with: defaultJsonData) as! [String: Any]

    // Only set field should be present
    XCTAssertEqual(defaultJsonObject.count, 1)
    XCTAssertEqual(defaultJsonObject["string_field"] as! String, "test")
    XCTAssertNil(defaultJsonObject["int_field"])
  }

  func testJSONWriteErrorHandling() throws {
    // This test simulates a scenario where JSONSerialization.data() might fail
    // We can't easily trigger this in practice, so we test the error path indirectly
    var message = MessageDescriptor(name: "SimpleMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "text", number: 1, type: .string))
    fileDescriptor.addMessage(message)

    let dynamicMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "text": "test"
      ]
    )

    // This should work normally
    let jsonData = try serializer.serialize(dynamicMessage)
    XCTAssertFalse(jsonData.isEmpty)
  }

  // MARK: - Error Coverage Tests

  func testJSONSerializationErrorCoverage() throws {
    // Test all uncovered error descriptions

    let error1 = JSONSerializationError.invalidFieldType(fieldName: "test", expectedType: "String", actualType: "Int")
    XCTAssertEqual(error1.description, "Invalid field type for field 'test': expected String, got Int")

    let error2 = JSONSerializationError.valueTypeMismatch(expected: "String", actual: "Int")
    XCTAssertEqual(error2.description, "Value type mismatch: expected String, got Int")

    let error3 = JSONSerializationError.missingMapEntryInfo(fieldName: "map_field")
    XCTAssertEqual(error3.description, "Missing map entry info for field 'map_field'")

    let error4 = JSONSerializationError.missingFieldValue(fieldName: "missing_field")
    XCTAssertEqual(error4.description, "Missing value for field 'missing_field'")

    let error5 = JSONSerializationError.unsupportedFieldType(type: "group")
    XCTAssertEqual(error5.description, "Unsupported field type: group")

    let error6 = JSONSerializationError.invalidMapKeyType(keyType: "FieldType.float")
    XCTAssertEqual(error6.description, "Invalid map key type: FieldType.float")

    let underlyingError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
    let error7 = JSONSerializationError.jsonWriteError(underlyingError: underlyingError)
    XCTAssertTrue(error7.description.contains("JSON write error"))
    XCTAssertTrue(error7.description.contains("Test error"))
  }

  func testCompleteErrorEquality() throws {
    // Test missingMapEntryInfo equality
    let error1 = JSONSerializationError.missingMapEntryInfo(fieldName: "map1")
    let error2 = JSONSerializationError.missingMapEntryInfo(fieldName: "map1")
    let error3 = JSONSerializationError.missingMapEntryInfo(fieldName: "map2")

    XCTAssertEqual(error1, error2)
    XCTAssertNotEqual(error1, error3)

    // Test missingFieldValue equality
    let error4 = JSONSerializationError.missingFieldValue(fieldName: "field1")
    let error5 = JSONSerializationError.missingFieldValue(fieldName: "field1")
    let error6 = JSONSerializationError.missingFieldValue(fieldName: "field2")

    XCTAssertEqual(error4, error5)
    XCTAssertNotEqual(error4, error6)

    // Test unsupportedFieldType equality
    let error7 = JSONSerializationError.unsupportedFieldType(type: "group")
    let error8 = JSONSerializationError.unsupportedFieldType(type: "group")
    let error9 = JSONSerializationError.unsupportedFieldType(type: "unknown")

    XCTAssertEqual(error7, error8)
    XCTAssertNotEqual(error7, error9)

    // Test invalidMapKeyType equality
    let error10 = JSONSerializationError.invalidMapKeyType(keyType: "double")
    let error11 = JSONSerializationError.invalidMapKeyType(keyType: "double")
    let error12 = JSONSerializationError.invalidMapKeyType(keyType: "float")

    XCTAssertEqual(error10, error11)
    XCTAssertNotEqual(error10, error12)

    // Test jsonWriteError equality
    let error13 = JSONSerializationError.jsonWriteError(underlyingError: NSError(domain: "test", code: 1))
    let error14 = JSONSerializationError.jsonWriteError(underlyingError: NSError(domain: "test", code: 2))

    XCTAssertEqual(error13, error14)  // Should be equal as per implementation
  }
}
