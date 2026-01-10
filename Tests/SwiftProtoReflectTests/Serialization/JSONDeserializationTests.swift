//
// JSONDeserializationTests.swift
//
// Tests for JSON deserialization of Protocol Buffers
//
// Test cases from the plan:
// - Test-JSON-Deser-001: JSON deserialization of all data types with round-trip testing
// - Test-JSON-Deser-002: Handling special values (Infinity, NaN, base64) from JSON
// - Test-JSON-Deser-003: Correct error handling and JSON data validation
// - Test-JSON-Deser-004: Round-trip compatibility with JSONSerializer

import XCTest

@testable import SwiftProtoReflect

final class JSONDeserializationTests: XCTestCase {

  var fileDescriptor: FileDescriptor!
  var messageFactory: MessageFactory!
  var serializer: JSONSerializer!
  var deserializer: JSONDeserializer!

  override func setUp() {
    super.setUp()

    fileDescriptor = FileDescriptor(name: "test_json_deserialization.proto", package: "test.json.deser")
    messageFactory = MessageFactory()
    serializer = JSONSerializer()
    deserializer = JSONDeserializer()
  }

  override func tearDown() {
    fileDescriptor = nil
    messageFactory = nil
    serializer = nil
    deserializer = nil
    super.tearDown()
  }

  // MARK: - Round-trip Tests (Test-JSON-Deser-004)

  func testRoundTripAllScalarTypes() throws {
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

    // Create original message
    let originalValues: [String: Any] = [
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

    let originalMessage = try messageFactory.createMessage(from: scalarMessage, with: originalValues)

    // Round-trip: Message -> JSON -> Message
    let jsonData = try serializer.serialize(originalMessage)
    let deserializedMessage = try deserializer.deserialize(jsonData, using: scalarMessage)

    // Verify all fields
    let originalAccess = FieldAccessor(originalMessage)
    let deserializedAccess = FieldAccessor(deserializedMessage)

    XCTAssertEqual(
      originalAccess.getValue("double_field", as: Double.self)!,
      deserializedAccess.getValue("double_field", as: Double.self)!,
      accuracy: 0.00001
    )
    XCTAssertEqual(
      originalAccess.getValue("float_field", as: Float.self)!,
      deserializedAccess.getValue("float_field", as: Float.self)!,
      accuracy: 0.001
    )
    XCTAssertEqual(
      originalAccess.getValue("int32_field", as: Int32.self)!,
      deserializedAccess.getValue("int32_field", as: Int32.self)!
    )
    XCTAssertEqual(
      originalAccess.getValue("int64_field", as: Int64.self)!,
      deserializedAccess.getValue("int64_field", as: Int64.self)!
    )
    XCTAssertEqual(
      originalAccess.getValue("uint32_field", as: UInt32.self)!,
      deserializedAccess.getValue("uint32_field", as: UInt32.self)!
    )
    XCTAssertEqual(
      originalAccess.getValue("uint64_field", as: UInt64.self)!,
      deserializedAccess.getValue("uint64_field", as: UInt64.self)!
    )
    XCTAssertEqual(
      originalAccess.getValue("bool_field", as: Bool.self)!,
      deserializedAccess.getValue("bool_field", as: Bool.self)!
    )
    XCTAssertEqual(
      originalAccess.getValue("string_field", as: String.self)!,
      deserializedAccess.getValue("string_field", as: String.self)!
    )
    XCTAssertEqual(
      originalAccess.getValue("bytes_field", as: Data.self)!,
      deserializedAccess.getValue("bytes_field", as: Data.self)!
    )
  }

  func testRoundTripSpecialFloatValues() throws {
    var message = MessageDescriptor(name: "SpecialFloatMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "double_infinity", number: 1, type: .double))
    message.addField(FieldDescriptor(name: "double_neg_infinity", number: 2, type: .double))
    message.addField(FieldDescriptor(name: "double_nan", number: 3, type: .double))
    message.addField(FieldDescriptor(name: "float_infinity", number: 4, type: .float))
    message.addField(FieldDescriptor(name: "float_neg_infinity", number: 5, type: .float))
    message.addField(FieldDescriptor(name: "float_nan", number: 6, type: .float))
    fileDescriptor.addMessage(message)

    let originalMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "double_infinity": Double.infinity,
        "double_neg_infinity": -Double.infinity,
        "double_nan": Double.nan,
        "float_infinity": Float.infinity,
        "float_neg_infinity": -Float.infinity,
        "float_nan": Float.nan,
      ]
    )

    // Round-trip
    let jsonData = try serializer.serialize(originalMessage)
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)

    let _ = FieldAccessor(originalMessage)
    let deserializedAccess = FieldAccessor(deserializedMessage)

    // Verify special values
    let doubleInfinity = deserializedAccess.getValue("double_infinity", as: Double.self)!
    XCTAssertTrue(doubleInfinity.isInfinite && doubleInfinity > 0)

    let doubleNegInfinity = deserializedAccess.getValue("double_neg_infinity", as: Double.self)!
    XCTAssertTrue(doubleNegInfinity.isInfinite && doubleNegInfinity < 0)

    let doubleNaN = deserializedAccess.getValue("double_nan", as: Double.self)!
    XCTAssertTrue(doubleNaN.isNaN)

    let floatInfinity = deserializedAccess.getValue("float_infinity", as: Float.self)!
    XCTAssertTrue(floatInfinity.isInfinite && floatInfinity > 0)

    let floatNegInfinity = deserializedAccess.getValue("float_neg_infinity", as: Float.self)!
    XCTAssertTrue(floatNegInfinity.isInfinite && floatNegInfinity < 0)

    let floatNaN = deserializedAccess.getValue("float_nan", as: Float.self)!
    XCTAssertTrue(floatNaN.isNaN)
  }

  func testRoundTripRepeatedFields() throws {
    var message = MessageDescriptor(name: "RepeatedMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "numbers", number: 1, type: .int32, isRepeated: true))
    message.addField(FieldDescriptor(name: "words", number: 2, type: .string, isRepeated: true))
    message.addField(FieldDescriptor(name: "flags", number: 3, type: .bool, isRepeated: true))
    fileDescriptor.addMessage(message)

    let originalMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "numbers": [Int32(1), Int32(2), Int32(3)],
        "words": ["hello", "world", "test"],
        "flags": [true, false, true],
      ]
    )

    // Round-trip
    let jsonData = try serializer.serialize(originalMessage)
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)

    let originalAccess = FieldAccessor(originalMessage)
    let deserializedAccess = FieldAccessor(deserializedMessage)

    XCTAssertEqual(
      originalAccess.getValue("numbers", as: [Int32].self)!,
      deserializedAccess.getValue("numbers", as: [Int32].self)!
    )
    XCTAssertEqual(
      originalAccess.getValue("words", as: [String].self)!,
      deserializedAccess.getValue("words", as: [String].self)!
    )
    XCTAssertEqual(
      originalAccess.getValue("flags", as: [Bool].self)!,
      deserializedAccess.getValue("flags", as: [Bool].self)!
    )
  }

  func testRoundTripMapFields() throws {
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

    let originalMessage = try messageFactory.createMessage(
      from: message,
      with: [
        "string_to_int": mapData
      ]
    )

    // Round-trip
    let jsonData = try serializer.serialize(originalMessage)
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)

    let originalAccess = FieldAccessor(originalMessage)
    let deserializedAccess = FieldAccessor(deserializedMessage)

    let originalMap = originalAccess.getValue("string_to_int", as: [String: Int32].self)!
    let deserializedMap = deserializedAccess.getValue("string_to_int", as: [String: Int32].self)!

    XCTAssertEqual(originalMap, deserializedMap)
  }

  // MARK: - Direct JSON Deserialization Tests (Test-JSON-Deser-001)

  func testDeserializeScalarTypesFromJSON() throws {
    var message = MessageDescriptor(name: "ScalarMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "double_field", number: 1, type: .double))
    message.addField(FieldDescriptor(name: "int32_field", number: 2, type: .int32))
    message.addField(FieldDescriptor(name: "int64_field", number: 3, type: .int64))
    message.addField(FieldDescriptor(name: "bool_field", number: 4, type: .bool))
    message.addField(FieldDescriptor(name: "string_field", number: 5, type: .string))
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "double_field": 3.14159,
        "int32_field": -42,
        "int64_field": "-9223372036854775000",
        "bool_field": true,
        "string_field": "Hello, World!"
      }
      """

    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)

    let fieldAccess = FieldAccessor(deserializedMessage)

    XCTAssertEqual(fieldAccess.getValue("double_field", as: Double.self)!, 3.14159, accuracy: 0.00001)
    XCTAssertEqual(fieldAccess.getValue("int32_field", as: Int32.self)!, -42)
    XCTAssertEqual(fieldAccess.getValue("int64_field", as: Int64.self)!, -9_223_372_036_854_775_000)
    XCTAssertEqual(fieldAccess.getValue("bool_field", as: Bool.self)!, true)
    XCTAssertEqual(fieldAccess.getValue("string_field", as: String.self)!, "Hello, World!")
  }

  func testDeserializeBytesFromJSON() throws {
    var message = MessageDescriptor(name: "BytesMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "data", number: 1, type: .bytes))
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "data": "AQID/w=="
      }
      """

    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)

    let fieldAccess = FieldAccessor(deserializedMessage)
    let bytesData = fieldAccess.getValue("data", as: Data.self)!

    XCTAssertEqual(bytesData, Data([0x01, 0x02, 0x03, 0xFF]))
  }

  func testDeserializeSpecialFloatValuesFromJSON() throws {
    var message = MessageDescriptor(name: "SpecialFloatMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "infinity", number: 1, type: .double))
    message.addField(FieldDescriptor(name: "negative_infinity", number: 2, type: .double))
    message.addField(FieldDescriptor(name: "nan", number: 3, type: .double))
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "infinity": "Infinity",
        "negative_infinity": "-Infinity",
        "nan": "NaN"
      }
      """

    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)

    let fieldAccess = FieldAccessor(deserializedMessage)

    let infinity = fieldAccess.getValue("infinity", as: Double.self)!
    XCTAssertTrue(infinity.isInfinite && infinity > 0)

    let negativeInfinity = fieldAccess.getValue("negative_infinity", as: Double.self)!
    XCTAssertTrue(negativeInfinity.isInfinite && negativeInfinity < 0)

    let nan = fieldAccess.getValue("nan", as: Double.self)!
    XCTAssertTrue(nan.isNaN)
  }

  func testDeserializeRepeatedFieldsFromJSON() throws {
    var message = MessageDescriptor(name: "RepeatedMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "numbers", number: 1, type: .int32, isRepeated: true))
    message.addField(FieldDescriptor(name: "words", number: 2, type: .string, isRepeated: true))
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "numbers": [1, 2, 3, 4, 5],
        "words": ["hello", "world", "test"]
      }
      """

    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)

    let fieldAccess = FieldAccessor(deserializedMessage)

    let numbers = fieldAccess.getValue("numbers", as: [Int32].self)!
    XCTAssertEqual(numbers, [1, 2, 3, 4, 5])

    let words = fieldAccess.getValue("words", as: [String].self)!
    XCTAssertEqual(words, ["hello", "world", "test"])
  }

  func testDeserializeMapFieldsFromJSON() throws {
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

    let jsonString = """
      {
        "string_to_int": {
          "first": 1,
          "second": 2,
          "third": 3
        }
      }
      """

    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)

    let fieldAccess = FieldAccessor(deserializedMessage)
    let mapData = fieldAccess.getValue("string_to_int", as: [String: Int32].self)!

    XCTAssertEqual(mapData["first"], 1)
    XCTAssertEqual(mapData["second"], 2)
    XCTAssertEqual(mapData["third"], 3)
  }

  func testDeserializeMapWithIntegerKeysFromJSON() throws {
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

    let jsonString = """
      {
        "int_to_string": {
          "1": "one",
          "2": "two",
          "42": "answer"
        }
      }
      """

    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)

    let fieldAccess = FieldAccessor(deserializedMessage)
    let mapData = fieldAccess.getValue("int_to_string", as: [Int32: String].self)!

    XCTAssertEqual(mapData[1], "one")
    XCTAssertEqual(mapData[2], "two")
    XCTAssertEqual(mapData[42], "answer")
  }

  // MARK: - Field Name Handling Tests

  func testDeserializeWithCamelCaseFieldNames() throws {
    var message = MessageDescriptor(name: "CamelCaseMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "test_field", number: 1, type: .string, jsonName: "testField"))
    message.addField(FieldDescriptor(name: "another_field", number: 2, type: .int32, jsonName: "anotherField"))
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "testField": "hello",
        "anotherField": 42
      }
      """

    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)

    let fieldAccess = FieldAccessor(deserializedMessage)

    XCTAssertEqual(fieldAccess.getValue("test_field", as: String.self)!, "hello")
    XCTAssertEqual(fieldAccess.getValue("another_field", as: Int32.self)!, 42)
  }

  func testDeserializeWithOriginalFieldNames() throws {
    var message = MessageDescriptor(name: "OriginalFieldMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "test_field", number: 1, type: .string, jsonName: "testField"))
    message.addField(FieldDescriptor(name: "another_field", number: 2, type: .int32, jsonName: "anotherField"))
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "test_field": "hello",
        "another_field": 42
      }
      """

    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)

    let fieldAccess = FieldAccessor(deserializedMessage)

    XCTAssertEqual(fieldAccess.getValue("test_field", as: String.self)!, "hello")
    XCTAssertEqual(fieldAccess.getValue("another_field", as: Int32.self)!, 42)
  }

  // MARK: - Options Tests

  func testDeserializeWithIgnoreUnknownFields() throws {
    var message = MessageDescriptor(name: "KnownFieldsMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "known_field", number: 1, type: .string))
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "known_field": "hello",
        "unknown_field": "should be ignored",
        "another_unknown": 42
      }
      """

    let jsonData = jsonString.data(using: .utf8)!

    // With ignoring unknown fields (default)
    let ignoreUnknownDeserializer = JSONDeserializer(options: JSONDeserializationOptions(ignoreUnknownFields: true))
    let deserializedMessage = try ignoreUnknownDeserializer.deserialize(jsonData, using: message)

    let fieldAccess = FieldAccessor(deserializedMessage)
    XCTAssertEqual(fieldAccess.getValue("known_field", as: String.self)!, "hello")
  }

  func testDeserializeWithStrictUnknownFields() throws {
    var message = MessageDescriptor(name: "StrictFieldsMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "known_field", number: 1, type: .string))
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "known_field": "hello",
        "unknown_field": "should cause error"
      }
      """

    let jsonData = jsonString.data(using: .utf8)!

    // Without ignoring unknown fields
    let strictDeserializer = JSONDeserializer(options: JSONDeserializationOptions(ignoreUnknownFields: false))

    XCTAssertThrowsError(try strictDeserializer.deserialize(jsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError {
        if case .unknownField(let fieldName, let messageName) = jsonError {
          XCTAssertEqual(fieldName, "unknown_field")
          XCTAssertEqual(messageName, "StrictFieldsMessage")
        }
        else {
          XCTFail("Wrong error type: \(jsonError)")
        }
      }
      else {
        XCTFail("Expected JSONDeserializationError, got: \(error)")
      }
    }
  }

  // MARK: - Error Handling Tests (Test-JSON-Deser-003)

  func testDeserializeInvalidJSON() throws {
    var message = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "test_field", number: 1, type: .string))
    fileDescriptor.addMessage(message)

    let invalidJsonData = "{ invalid json }".data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(invalidJsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError,
        case .invalidJSON = jsonError
      {
        // Expected error
      }
      else {
        XCTFail("Expected invalidJSON error, got: \(error)")
      }
    }
  }

  func testDeserializeInvalidJSONStructure() throws {
    var message = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "test_field", number: 1, type: .string))
    fileDescriptor.addMessage(message)

    // JSON is not an object (it's an array)
    let arrayJsonData = "[1, 2, 3]".data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(arrayJsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError,
        case .invalidJSONStructure(let expected, let actual) = jsonError
      {
        XCTAssertEqual(expected, "Object")
        XCTAssertTrue(actual.contains("Array"))
      }
      else {
        XCTFail("Expected invalidJSONStructure error, got: \(error)")
      }
    }
  }

  func testDeserializeTypeConversionErrorsForPrimitives() throws {
    var message = MessageDescriptor(name: "TypeErrorMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "double_field", number: 1, type: .double))
    message.addField(FieldDescriptor(name: "int32_field", number: 2, type: .int32))
    message.addField(FieldDescriptor(name: "int64_field", number: 3, type: .int64))
    message.addField(FieldDescriptor(name: "uint32_field", number: 4, type: .uint32))
    message.addField(FieldDescriptor(name: "uint64_field", number: 5, type: .uint64))
    message.addField(FieldDescriptor(name: "bool_field", number: 6, type: .bool))
    fileDescriptor.addMessage(message)

    // Test for double with wrong type
    let doubleErrorJson = """
      {
        "double_field": []
      }
      """.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(doubleErrorJson, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError,
        case .valueTypeMismatch(let fieldName, let expected, let actual) = jsonError
      {
        XCTAssertEqual(fieldName, "double_field")
        XCTAssertEqual(expected, "Number or String")
        XCTAssertTrue(actual.contains("Array"))
      }
      else {
        XCTFail("Expected valueTypeMismatch error for double, got: \(error)")
      }
    }

    // Test for int32 with wrong type
    let int32ErrorJson = """
      {
        "int32_field": {}
      }
      """.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(int32ErrorJson, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError,
        case .valueTypeMismatch(let fieldName, let expected, let actual) = jsonError
      {
        XCTAssertEqual(fieldName, "int32_field")
        XCTAssertEqual(expected, "Number or String")
        XCTAssertTrue(actual.contains("Dictionary"))
      }
      else {
        XCTFail("Expected valueTypeMismatch error for int32, got: \(error)")
      }
    }

    // Test for int64 with wrong type
    let int64ErrorJson = """
      {
        "int64_field": []
      }
      """.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(int64ErrorJson, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError,
        case .valueTypeMismatch(let fieldName, let expected, let actual) = jsonError
      {
        XCTAssertEqual(fieldName, "int64_field")
        XCTAssertEqual(expected, "Number or String")
        XCTAssertTrue(actual.contains("Array"))
      }
      else {
        XCTFail("Expected valueTypeMismatch error for int64, got: \(error)")
      }
    }

    // Test for uint32 with wrong type
    let uint32ErrorJson = """
      {
        "uint32_field": null
      }
      """.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(uint32ErrorJson, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError,
        case .valueTypeMismatch(let fieldName, let expected, let actual) = jsonError
      {
        XCTAssertEqual(fieldName, "uint32_field")
        XCTAssertEqual(expected, "Number or String")
        XCTAssertTrue(actual.contains("NSNull"))
      }
      else {
        XCTFail("Expected valueTypeMismatch error for uint32, got: \(error)")
      }
    }

    // Test for uint64 with wrong type
    let uint64ErrorJson = """
      {
        "uint64_field": []
      }
      """.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(uint64ErrorJson, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError,
        case .valueTypeMismatch(let fieldName, let expected, let actual) = jsonError
      {
        XCTAssertEqual(fieldName, "uint64_field")
        XCTAssertEqual(expected, "Number or String")
        XCTAssertTrue(actual.contains("Array"))
      }
      else {
        XCTFail("Expected valueTypeMismatch error for uint64, got: \(error)")
      }
    }

    // Test for bool with wrong type
    let boolErrorJson = """
      {
        "bool_field": "not a bool"
      }
      """.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(boolErrorJson, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError,
        case .valueTypeMismatch(let fieldName, let expected, let actual) = jsonError
      {
        XCTAssertEqual(fieldName, "bool_field")
        XCTAssertEqual(expected, "Boolean")
        XCTAssertTrue(actual.contains("String"))
      }
      else {
        XCTFail("Expected valueTypeMismatch error for bool, got: \(error)")
      }
    }
  }

  func testDeserializeInvalidNumberFormat() throws {
    var message = MessageDescriptor(name: "NumberFormatMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "int32_field", number: 1, type: .int32))
    message.addField(FieldDescriptor(name: "int64_field", number: 2, type: .int64))
    message.addField(FieldDescriptor(name: "uint32_field", number: 3, type: .uint32))
    message.addField(FieldDescriptor(name: "uint64_field", number: 4, type: .uint64))
    message.addField(FieldDescriptor(name: "double_field", number: 5, type: .double))
    message.addField(FieldDescriptor(name: "float_field", number: 6, type: .float))
    fileDescriptor.addMessage(message)

    // Test for int32 with invalid string format
    let int32ErrorJson = """
      {
        "int32_field": "not_a_number"
      }
      """.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(int32ErrorJson, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError,
        case .invalidNumberFormat(let fieldName, let value) = jsonError
      {
        XCTAssertEqual(fieldName, "int32_field")
        XCTAssertEqual(value, "not_a_number")
      }
      else {
        XCTFail("Expected invalidNumberFormat error for int32, got: \(error)")
      }
    }

    // Test for int64 with invalid string format
    let int64ErrorJson = """
      {
        "int64_field": "invalid_int64"
      }
      """.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(int64ErrorJson, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError,
        case .invalidNumberFormat(let fieldName, let value) = jsonError
      {
        XCTAssertEqual(fieldName, "int64_field")
        XCTAssertEqual(value, "invalid_int64")
      }
      else {
        XCTFail("Expected invalidNumberFormat error for int64, got: \(error)")
      }
    }

    // Test for uint32 with invalid string format
    let uint32ErrorJson = """
      {
        "uint32_field": "invalid_uint32"
      }
      """.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(uint32ErrorJson, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError,
        case .invalidNumberFormat(let fieldName, let value) = jsonError
      {
        XCTAssertEqual(fieldName, "uint32_field")
        XCTAssertEqual(value, "invalid_uint32")
      }
      else {
        XCTFail("Expected invalidNumberFormat error for uint32, got: \(error)")
      }
    }

    // Test for uint64 with invalid string format
    let uint64ErrorJson = """
      {
        "uint64_field": "invalid_uint64"
      }
      """.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(uint64ErrorJson, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError,
        case .invalidNumberFormat(let fieldName, let value) = jsonError
      {
        XCTAssertEqual(fieldName, "uint64_field")
        XCTAssertEqual(value, "invalid_uint64")
      }
      else {
        XCTFail("Expected invalidNumberFormat error for uint64, got: \(error)")
      }
    }

    // Test for double with invalid string format
    let doubleErrorJson = """
      {
        "double_field": "not_a_double"
      }
      """.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(doubleErrorJson, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError,
        case .invalidNumberFormat(let fieldName, let value) = jsonError
      {
        XCTAssertEqual(fieldName, "double_field")
        XCTAssertEqual(value, "not_a_double")
      }
      else {
        XCTFail("Expected invalidNumberFormat error for double, got: \(error)")
      }
    }

    // Test for float with invalid string format
    let floatErrorJson = """
      {
        "float_field": "not_a_float"
      }
      """.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(floatErrorJson, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError,
        case .invalidNumberFormat(let fieldName, let value) = jsonError
      {
        XCTAssertEqual(fieldName, "float_field")
        XCTAssertEqual(value, "not_a_float")
      }
      else {
        XCTFail("Expected invalidNumberFormat error for float, got: \(error)")
      }
    }
  }

  // MARK: - Error Description and Equality Tests

  func testErrorDescriptions() throws {
    // Test all error types and their descriptions

    let error1 = JSONDeserializationError.invalidJSON(underlyingError: NSError(domain: "test", code: 1, userInfo: nil))
    XCTAssertTrue(error1.description.contains("Invalid JSON"))

    let error2 = JSONDeserializationError.invalidJSONStructure(expected: "Object", actual: "Array")
    XCTAssertEqual(error2.description, "Invalid JSON structure: expected Object, got Array")

    let error3 = JSONDeserializationError.unknownField(fieldName: "unknown_field", messageName: "TestMessage")
    XCTAssertEqual(error3.description, "Unknown field 'unknown_field' in message 'TestMessage'")

    let error4 = JSONDeserializationError.invalidFieldType(
      fieldName: "test_field",
      expectedType: "Object",
      actualType: "String"
    )
    XCTAssertEqual(error4.description, "Invalid field type for 'test_field': expected Object, got String")

    let error5 = JSONDeserializationError.valueTypeMismatch(
      fieldName: "test_field",
      expected: "Number",
      actual: "String"
    )
    XCTAssertEqual(error5.description, "Value type mismatch for field 'test_field': expected Number, got String")

    let error6 = JSONDeserializationError.invalidNumberFormat(fieldName: "test_field", value: "invalid")
    XCTAssertEqual(error6.description, "Invalid number format for field 'test_field': invalid")

    let error7 = JSONDeserializationError.numberOutOfRange(
      fieldName: "test_field",
      value: 999999,
      expectedRange: "Int32"
    )
    XCTAssertEqual(error7.description, "Number out of range for field 'test_field': 999999 (expected Int32)")

    let error8 = JSONDeserializationError.invalidBase64(fieldName: "test_field", value: "invalid")
    XCTAssertEqual(error8.description, "Invalid base64 string for field 'test_field': invalid")

    let error9 = JSONDeserializationError.invalidEnumValue(fieldName: "test_field", value: "invalid")
    XCTAssertEqual(error9.description, "Invalid enum value for field 'test_field': invalid")

    let error10 = JSONDeserializationError.invalidMapKeyFormat(
      fieldName: "test_field",
      keyType: "Int32",
      value: "invalid"
    )
    XCTAssertEqual(error10.description, "Invalid map key format for field 'test_field': expected Int32, got 'invalid'")

    let error11 = JSONDeserializationError.invalidMapKeyType(fieldName: "test_field", keyType: "Float")
    XCTAssertEqual(error11.description, "Invalid map key type for field 'test_field': Float")

    let error12 = JSONDeserializationError.invalidMapKey(fieldName: "test_field", key: "invalid")
    XCTAssertEqual(error12.description, "Invalid map key for field 'test_field': invalid")

    let error13 = JSONDeserializationError.invalidArrayElement(
      fieldName: "test_field",
      index: 5,
      underlyingError: NSError(domain: "test", code: 1, userInfo: nil)
    )
    XCTAssertTrue(error13.description.contains("Invalid array element for field 'test_field' at index 5"))

    let error14 = JSONDeserializationError.missingMapEntryInfo(fieldName: "test_field")
    XCTAssertEqual(error14.description, "Missing map entry info for field 'test_field'")

    let error15 = JSONDeserializationError.missingTypeName(fieldName: "test_field")
    XCTAssertEqual(error15.description, "Missing type name for field 'test_field'")

    let error16 = JSONDeserializationError.unsupportedNestedMessage(fieldName: "test_field", typeName: "TestType")
    XCTAssertEqual(error16.description, "Unsupported nested message for field 'test_field': TestType")

    let error17 = JSONDeserializationError.unsupportedFieldType(type: "group")
    XCTAssertEqual(error17.description, "Unsupported field type: group")
  }

  func testErrorEquality() throws {
    // Test error equality

    // invalidJSON
    let invalidJson1 = JSONDeserializationError.invalidJSON(
      underlyingError: NSError(domain: "test", code: 1, userInfo: nil)
    )
    let invalidJson2 = JSONDeserializationError.invalidJSON(
      underlyingError: NSError(domain: "test", code: 2, userInfo: nil)
    )
    XCTAssertEqual(invalidJson1, invalidJson2)  // Underlying errors are not compared

    // invalidJSONStructure
    let invalidStruct1 = JSONDeserializationError.invalidJSONStructure(expected: "Object", actual: "Array")
    let invalidStruct2 = JSONDeserializationError.invalidJSONStructure(expected: "Object", actual: "Array")
    let invalidStruct3 = JSONDeserializationError.invalidJSONStructure(expected: "Object", actual: "String")
    XCTAssertEqual(invalidStruct1, invalidStruct2)
    XCTAssertNotEqual(invalidStruct1, invalidStruct3)

    // unknownField
    let unknownField1 = JSONDeserializationError.unknownField(fieldName: "field1", messageName: "Message1")
    let unknownField2 = JSONDeserializationError.unknownField(fieldName: "field1", messageName: "Message1")
    let unknownField3 = JSONDeserializationError.unknownField(fieldName: "field2", messageName: "Message1")
    XCTAssertEqual(unknownField1, unknownField2)
    XCTAssertNotEqual(unknownField1, unknownField3)

    // invalidFieldType
    let invalidType1 = JSONDeserializationError.invalidFieldType(
      fieldName: "field1",
      expectedType: "Object",
      actualType: "String"
    )
    let invalidType2 = JSONDeserializationError.invalidFieldType(
      fieldName: "field1",
      expectedType: "Object",
      actualType: "String"
    )
    let invalidType3 = JSONDeserializationError.invalidFieldType(
      fieldName: "field1",
      expectedType: "Array",
      actualType: "String"
    )
    XCTAssertEqual(invalidType1, invalidType2)
    XCTAssertNotEqual(invalidType1, invalidType3)

    // valueTypeMismatch
    let typeMismatch1 = JSONDeserializationError.valueTypeMismatch(
      fieldName: "field1",
      expected: "Number",
      actual: "String"
    )
    let typeMismatch2 = JSONDeserializationError.valueTypeMismatch(
      fieldName: "field1",
      expected: "Number",
      actual: "String"
    )
    let typeMismatch3 = JSONDeserializationError.valueTypeMismatch(
      fieldName: "field1",
      expected: "Number",
      actual: "Array"
    )
    XCTAssertEqual(typeMismatch1, typeMismatch2)
    XCTAssertNotEqual(typeMismatch1, typeMismatch3)

    // invalidNumberFormat
    let numberFormat1 = JSONDeserializationError.invalidNumberFormat(fieldName: "field1", value: "invalid")
    let numberFormat2 = JSONDeserializationError.invalidNumberFormat(fieldName: "field1", value: "invalid")
    let numberFormat3 = JSONDeserializationError.invalidNumberFormat(fieldName: "field1", value: "other")
    XCTAssertEqual(numberFormat1, numberFormat2)
    XCTAssertNotEqual(numberFormat1, numberFormat3)

    // numberOutOfRange
    let outOfRange1 = JSONDeserializationError.numberOutOfRange(fieldName: "field1", value: 999, expectedRange: "Int32")
    let outOfRange2 = JSONDeserializationError.numberOutOfRange(fieldName: "field1", value: 999, expectedRange: "Int32")
    let outOfRange3 = JSONDeserializationError.numberOutOfRange(fieldName: "field1", value: 888, expectedRange: "Int32")
    XCTAssertEqual(outOfRange1, outOfRange2)
    XCTAssertNotEqual(outOfRange1, outOfRange3)

    // invalidBase64
    let base64N1 = JSONDeserializationError.invalidBase64(fieldName: "field1", value: "invalid")
    let base64N2 = JSONDeserializationError.invalidBase64(fieldName: "field1", value: "invalid")
    let base64N3 = JSONDeserializationError.invalidBase64(fieldName: "field1", value: "other")
    XCTAssertEqual(base64N1, base64N2)
    XCTAssertNotEqual(base64N1, base64N3)

    // invalidEnumValue
    let enumValue1 = JSONDeserializationError.invalidEnumValue(fieldName: "field1", value: "invalid")
    let enumValue2 = JSONDeserializationError.invalidEnumValue(fieldName: "field1", value: "invalid")
    let enumValue3 = JSONDeserializationError.invalidEnumValue(fieldName: "field1", value: "other")
    XCTAssertEqual(enumValue1, enumValue2)
    XCTAssertNotEqual(enumValue1, enumValue3)

    // invalidMapKeyFormat
    let mapKeyFormat1 = JSONDeserializationError.invalidMapKeyFormat(
      fieldName: "field1",
      keyType: "Int32",
      value: "invalid"
    )
    let mapKeyFormat2 = JSONDeserializationError.invalidMapKeyFormat(
      fieldName: "field1",
      keyType: "Int32",
      value: "invalid"
    )
    let mapKeyFormat3 = JSONDeserializationError.invalidMapKeyFormat(
      fieldName: "field1",
      keyType: "Int64",
      value: "invalid"
    )
    XCTAssertEqual(mapKeyFormat1, mapKeyFormat2)
    XCTAssertNotEqual(mapKeyFormat1, mapKeyFormat3)

    // invalidMapKeyType
    let mapKeyType1 = JSONDeserializationError.invalidMapKeyType(fieldName: "field1", keyType: "Float")
    let mapKeyType2 = JSONDeserializationError.invalidMapKeyType(fieldName: "field1", keyType: "Float")
    let mapKeyType3 = JSONDeserializationError.invalidMapKeyType(fieldName: "field1", keyType: "Double")
    XCTAssertEqual(mapKeyType1, mapKeyType2)
    XCTAssertNotEqual(mapKeyType1, mapKeyType3)

    // invalidMapKey
    let mapKey1 = JSONDeserializationError.invalidMapKey(fieldName: "field1", key: "invalid")
    let mapKey2 = JSONDeserializationError.invalidMapKey(fieldName: "field1", key: "invalid")
    let mapKey3 = JSONDeserializationError.invalidMapKey(fieldName: "field1", key: "other")
    XCTAssertEqual(mapKey1, mapKey2)
    XCTAssertNotEqual(mapKey1, mapKey3)

    // invalidArrayElement
    let arrayElement1 = JSONDeserializationError.invalidArrayElement(
      fieldName: "field1",
      index: 5,
      underlyingError: NSError(domain: "test", code: 1, userInfo: nil)
    )
    let arrayElement2 = JSONDeserializationError.invalidArrayElement(
      fieldName: "field1",
      index: 5,
      underlyingError: NSError(domain: "test", code: 2, userInfo: nil)
    )
    let arrayElement3 = JSONDeserializationError.invalidArrayElement(
      fieldName: "field1",
      index: 6,
      underlyingError: NSError(domain: "test", code: 1, userInfo: nil)
    )
    XCTAssertEqual(arrayElement1, arrayElement2)  // Underlying errors are not compared
    XCTAssertNotEqual(arrayElement1, arrayElement3)

    // missingMapEntryInfo
    let missingInfo1 = JSONDeserializationError.missingMapEntryInfo(fieldName: "field1")
    let missingInfo2 = JSONDeserializationError.missingMapEntryInfo(fieldName: "field1")
    let missingInfo3 = JSONDeserializationError.missingMapEntryInfo(fieldName: "field2")
    XCTAssertEqual(missingInfo1, missingInfo2)
    XCTAssertNotEqual(missingInfo1, missingInfo3)

    // missingTypeName
    let missingType1 = JSONDeserializationError.missingTypeName(fieldName: "field1")
    let missingType2 = JSONDeserializationError.missingTypeName(fieldName: "field1")
    let missingType3 = JSONDeserializationError.missingTypeName(fieldName: "field2")
    XCTAssertEqual(missingType1, missingType2)
    XCTAssertNotEqual(missingType1, missingType3)

    // unsupportedNestedMessage
    let unsupportedMsg1 = JSONDeserializationError.unsupportedNestedMessage(fieldName: "field1", typeName: "Type1")
    let unsupportedMsg2 = JSONDeserializationError.unsupportedNestedMessage(fieldName: "field1", typeName: "Type1")
    let unsupportedMsg3 = JSONDeserializationError.unsupportedNestedMessage(fieldName: "field1", typeName: "Type2")
    XCTAssertEqual(unsupportedMsg1, unsupportedMsg2)
    XCTAssertNotEqual(unsupportedMsg1, unsupportedMsg3)

    // unsupportedFieldType
    let unsupportedType1 = JSONDeserializationError.unsupportedFieldType(type: "group")
    let unsupportedType2 = JSONDeserializationError.unsupportedFieldType(type: "group")
    let unsupportedType3 = JSONDeserializationError.unsupportedFieldType(type: "other")
    XCTAssertEqual(unsupportedType1, unsupportedType2)
    XCTAssertNotEqual(unsupportedType1, unsupportedType3)

    // Different error types are not equal
    XCTAssertNotEqual(invalidJson1, invalidStruct1)
    XCTAssertNotEqual(unknownField1, invalidType1)
  }

  // MARK: - Performance Tests

  func testJSONDeserializationPerformance() throws {
    // Create complex message for performance testing
    var message = MessageDescriptor(name: "PerformanceMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "numbers", number: 1, type: .int32, isRepeated: true))
    message.addField(FieldDescriptor(name: "text", number: 2, type: .string))
    message.addField(FieldDescriptor(name: "flag", number: 3, type: .bool))
    fileDescriptor.addMessage(message)

    // Create large JSON
    let numbers = Array(1...1000).map { String($0) }.joined(separator: ", ")
    let jsonString = """
      {
        "numbers": [\(numbers)],
        "text": "Performance test message with some content",
        "flag": true
      }
      """

    let jsonData = jsonString.data(using: .utf8)!

    measure {
      do {
        _ = try deserializer.deserialize(jsonData, using: message)
      }
      catch {
        XCTFail("Deserialization failed: \(error)")
      }
    }
  }

  // MARK: - Additional Type Coverage Tests

  func testDeserializeSignedAndFixedIntegerTypes() throws {
    var message = MessageDescriptor(name: "SignedFixedMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "sint32_field", number: 1, type: .sint32))
    message.addField(FieldDescriptor(name: "sint64_field", number: 2, type: .sint64))
    message.addField(FieldDescriptor(name: "sfixed32_field", number: 3, type: .sfixed32))
    message.addField(FieldDescriptor(name: "sfixed64_field", number: 4, type: .sfixed64))
    message.addField(FieldDescriptor(name: "fixed32_field", number: 5, type: .fixed32))
    message.addField(FieldDescriptor(name: "fixed64_field", number: 6, type: .fixed64))
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "sint32_field": -2147483648,
        "sint64_field": "-9223372036854775808",
        "sfixed32_field": 2147483647,
        "sfixed64_field": "9223372036854775807",
        "fixed32_field": 4294967295,
        "fixed64_field": "18446744073709551615"
      }
      """

    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)

    let fieldAccess = FieldAccessor(deserializedMessage)

    XCTAssertEqual(fieldAccess.getValue("sint32_field", as: Int32.self)!, Int32.min)
    XCTAssertEqual(fieldAccess.getValue("sint64_field", as: Int64.self)!, Int64.min)
    XCTAssertEqual(fieldAccess.getValue("sfixed32_field", as: Int32.self)!, Int32.max)
    XCTAssertEqual(fieldAccess.getValue("sfixed64_field", as: Int64.self)!, Int64.max)
    XCTAssertEqual(fieldAccess.getValue("fixed32_field", as: UInt32.self)!, UInt32.max)
    XCTAssertEqual(fieldAccess.getValue("fixed64_field", as: UInt64.self)!, UInt64.max)
  }

  func testDeserializeUInt32AndUInt64OutOfRange() throws {
    var message = MessageDescriptor(name: "UIntRangeMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "uint32_field", number: 1, type: .uint32))
    fileDescriptor.addMessage(message)

    // Test value greater than UInt32.max
    let jsonString = """
      {
        "uint32_field": 4294967296
      }
      """

    let jsonData = jsonString.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(jsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError {
        if case .numberOutOfRange(let fieldName, _, let expectedRange) = jsonError {
          XCTAssertEqual(fieldName, "uint32_field")
          XCTAssertEqual(expectedRange, "UInt32")
        }
        else {
          XCTFail("Wrong error type: \(jsonError)")
        }
      }
      else {
        XCTFail("Expected JSONDeserializationError, got: \(error)")
      }
    }
  }

  func testDeserializeFloatTypesFromStringNumbers() throws {
    var message = MessageDescriptor(name: "FloatFromStringMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "float_field", number: 1, type: .float))
    message.addField(FieldDescriptor(name: "double_field", number: 2, type: .double))
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "float_field": "3.14159",
        "double_field": "2.718281828"
      }
      """

    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)

    let fieldAccess = FieldAccessor(deserializedMessage)

    XCTAssertEqual(fieldAccess.getValue("float_field", as: Float.self)!, 3.14159, accuracy: 0.00001)
    XCTAssertEqual(fieldAccess.getValue("double_field", as: Double.self)!, 2.718281828, accuracy: 0.000000001)
  }

  func testDeserializeInvalidFloatFromString() throws {
    var message = MessageDescriptor(name: "InvalidFloatMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "float_field", number: 1, type: .float))
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "float_field": "not-a-number"
      }
      """

    let jsonData = jsonString.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(jsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError {
        if case .invalidNumberFormat(let fieldName, let value) = jsonError {
          XCTAssertEqual(fieldName, "float_field")
          XCTAssertEqual(value, "not-a-number")
        }
        else {
          XCTFail("Wrong error type: \(jsonError)")
        }
      }
      else {
        XCTFail("Expected JSONDeserializationError, got: \(error)")
      }
    }
  }

  func testDeserializeInvalidDoubleFromString() throws {
    var message = MessageDescriptor(name: "InvalidDoubleMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "double_field", number: 1, type: .double))
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "double_field": "invalid-double"
      }
      """

    let jsonData = jsonString.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(jsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError {
        if case .invalidNumberFormat(let fieldName, let value) = jsonError {
          XCTAssertEqual(fieldName, "double_field")
          XCTAssertEqual(value, "invalid-double")
        }
        else {
          XCTFail("Wrong error type: \(jsonError)")
        }
      }
      else {
        XCTFail("Expected JSONDeserializationError, got: \(error)")
      }
    }
  }

  func testDeserializeMapWithAllKeyTypes() throws {
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

    let jsonString = """
      {
        "uint32_to_string": {
          "0": "zero",
          "4294967295": "max_uint32"
        }
      }
      """

    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)

    let fieldAccess = FieldAccessor(deserializedMessage)
    let mapData = fieldAccess.getValue("uint32_to_string", as: [UInt32: String].self)!

    XCTAssertEqual(mapData[0], "zero")
    XCTAssertEqual(mapData[UInt32.max], "max_uint32")
  }

  func testDeserializeMapWithUInt64Keys() throws {
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

    let jsonString = """
      {
        "uint64_to_string": {
          "18446744073709551615": "max_uint64"
        }
      }
      """

    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)

    let fieldAccess = FieldAccessor(deserializedMessage)
    let mapData = fieldAccess.getValue("uint64_to_string", as: [UInt64: String].self)!

    XCTAssertEqual(mapData[UInt64.max], "max_uint64")
  }

  func testDeserializeMapWithBoolKeys() throws {
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

    let jsonString = """
      {
        "bool_to_string": {
          "true": "yes",
          "false": "no"
        }
      }
      """

    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)

    let fieldAccess = FieldAccessor(deserializedMessage)
    let mapData = fieldAccess.getValue("bool_to_string", as: [Bool: String].self)!

    XCTAssertEqual(mapData[true], "yes")
    XCTAssertEqual(mapData[false], "no")
  }

  func testDeserializeInvalidMapKeyTypes() throws {
    // This test verifies runtime error when deserializing map with unsupported key type
    // Since FieldDescriptor.init already validates allowed key types at creation,
    // we can only test the case where key cannot be converted
    // Therefore replacing this test to check other error paths

    // Test case with signed int64 key that cannot be converted
    let int64KeyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .sint64)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: int64KeyFieldInfo, valueFieldInfo: valueFieldInfo)

    var message = MessageDescriptor(name: "SignedInt64MapMessage", parent: fileDescriptor)
    message.addField(
      FieldDescriptor(
        name: "sint64_map",
        number: 1,
        type: .message,
        typeName: "sint64_map_entry",
        isMap: true,
        mapEntryInfo: mapEntryInfo
      )
    )
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "sint64_map": {
          "invalid-sint64": "value"
        }
      }
      """

    let jsonData = jsonString.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(jsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError {
        if case .invalidMapKeyFormat(let fieldName, let keyType, let value) = jsonError {
          XCTAssertEqual(fieldName, "sint64_map")
          XCTAssertEqual(keyType, "Int64")
          XCTAssertEqual(value, "invalid-sint64")
        }
        else {
          XCTFail("Wrong error type: \(jsonError)")
        }
      }
      else {
        XCTFail("Expected JSONDeserializationError, got: \(error)")
      }
    }
  }

  func testDeserializeInvalidMapKeyFormats() throws {
    let int32KeyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .int32)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: int32KeyFieldInfo, valueFieldInfo: valueFieldInfo)

    var message = MessageDescriptor(name: "InvalidKeyFormatMessage", parent: fileDescriptor)
    message.addField(
      FieldDescriptor(
        name: "invalid_key_map",
        number: 1,
        type: .message,
        typeName: "invalid_key_map_entry",
        isMap: true,
        mapEntryInfo: mapEntryInfo
      )
    )
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "invalid_key_map": {
          "not-a-number": "value"
        }
      }
      """

    let jsonData = jsonString.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(jsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError {
        if case .invalidMapKeyFormat(let fieldName, let keyType, let value) = jsonError {
          XCTAssertEqual(fieldName, "invalid_key_map")
          XCTAssertEqual(keyType, "Int32")
          XCTAssertEqual(value, "not-a-number")
        }
        else {
          XCTFail("Wrong error type: \(jsonError)")
        }
      }
      else {
        XCTFail("Expected JSONDeserializationError, got: \(error)")
      }
    }
  }

  func testDeserializeInvalidBoolMapKey() throws {
    let boolKeyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .bool)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: boolKeyFieldInfo, valueFieldInfo: valueFieldInfo)

    var message = MessageDescriptor(name: "InvalidBoolKeyMessage", parent: fileDescriptor)
    message.addField(
      FieldDescriptor(
        name: "bool_map",
        number: 1,
        type: .message,
        typeName: "bool_map_entry",
        isMap: true,
        mapEntryInfo: mapEntryInfo
      )
    )
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "bool_map": {
          "maybe": "unclear"
        }
      }
      """

    let jsonData = jsonString.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(jsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError {
        if case .invalidMapKeyFormat(let fieldName, let keyType, let value) = jsonError {
          XCTAssertEqual(fieldName, "bool_map")
          XCTAssertEqual(keyType, "Bool")
          XCTAssertEqual(value, "maybe")
        }
        else {
          XCTFail("Wrong error type: \(jsonError)")
        }
      }
      else {
        XCTFail("Expected JSONDeserializationError, got: \(error)")
      }
    }
  }

  func testDeserializeEnumFromNumber() throws {
    var message = MessageDescriptor(name: "EnumMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "status", number: 1, type: .enum, typeName: "Status"))
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "status": 42
      }
      """

    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)

    let fieldAccess = FieldAccessor(deserializedMessage)
    XCTAssertEqual(fieldAccess.getValue("status", as: Int32.self)!, 42)
  }

  func testDeserializeEnumFromValidString() throws {
    var message = MessageDescriptor(name: "EnumStringMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "status", number: 1, type: .enum, typeName: "Status"))
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "status": "123"
      }
      """

    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)

    let fieldAccess = FieldAccessor(deserializedMessage)
    XCTAssertEqual(fieldAccess.getValue("status", as: Int32.self)!, 123)
  }

  func testDeserializeInvalidEnumFromString() throws {
    var message = MessageDescriptor(name: "InvalidEnumMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "status", number: 1, type: .enum, typeName: "Status"))
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "status": "invalid-enum"
      }
      """

    let jsonData = jsonString.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(jsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError {
        if case .invalidEnumValue(let fieldName, let value) = jsonError {
          XCTAssertEqual(fieldName, "status")
          XCTAssertEqual(value, "invalid-enum")
        }
        else {
          XCTFail("Wrong error type: \(jsonError)")
        }
      }
      else {
        XCTFail("Expected JSONDeserializationError, got: \(error)")
      }
    }
  }

  func testDeserializeGroupTypeError() throws {
    var message = MessageDescriptor(name: "GroupMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "group_field", number: 1, type: .group))
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "group_field": {}
      }
      """

    let jsonData = jsonString.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(jsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError {
        if case .unsupportedFieldType(let type) = jsonError {
          XCTAssertEqual(type, "group")
        }
        else {
          XCTFail("Wrong error type: \(jsonError)")
        }
      }
      else {
        XCTFail("Expected JSONDeserializationError, got: \(error)")
      }
    }
  }

  func testDeserializeMessageTypeError() throws {
    var message = MessageDescriptor(name: "MessageMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "nested_message", number: 1, type: .message, typeName: "NestedMessage"))
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "nested_message": {}
      }
      """

    let jsonData = jsonString.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(jsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError {
        if case .unsupportedNestedMessage(let fieldName, let typeName) = jsonError {
          XCTAssertEqual(fieldName, "nested_message")
          XCTAssertEqual(typeName, "NestedMessage")
        }
        else {
          XCTFail("Wrong error type: \(jsonError)")
        }
      }
      else {
        XCTFail("Expected JSONDeserializationError, got: \(error)")
      }
    }
  }

  func testDeserializeMessageWithWrongJSONType() throws {
    var message = MessageDescriptor(name: "WrongTypeMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "nested_message", number: 1, type: .message, typeName: "NestedMessage"))
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "nested_message": "not an object"
      }
      """

    let jsonData = jsonString.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(jsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError,
        case .valueTypeMismatch(let fieldName, let expected, _) = jsonError
      {
        XCTAssertEqual(fieldName, "nested_message")
        XCTAssertEqual(expected, "Object")
      }
      else {
        XCTFail("Wrong error type: \(error)")
      }
    }
  }

  func testDeserializeBytesFromNonStringJSON() throws {
    var message = MessageDescriptor(name: "BytesMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "data", number: 1, type: .bytes))
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "data": 123
      }
      """

    let jsonData = jsonString.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(jsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError,
        case .valueTypeMismatch(let fieldName, let expected, let actual) = jsonError
      {
        XCTAssertEqual(fieldName, "data")
        XCTAssertEqual(expected, "String (base64)")
        XCTAssertTrue(actual.contains("Number"))
      }
      else {
        XCTFail("Expected valueTypeMismatch error for bytes, got: \(error)")
      }
    }
  }

  func testDeserializeMapWithIntegerKeyOverflow() throws {
    // Test overflow for Int32 map key
    let int32KeyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .int32)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: int32KeyFieldInfo, valueFieldInfo: valueFieldInfo)

    var message = MessageDescriptor(name: "Int32OverflowMapMessage", parent: fileDescriptor)
    message.addField(
      FieldDescriptor(
        name: "int32_overflow_map",
        number: 1,
        type: .message,
        typeName: "int32_overflow_map_entry",
        isMap: true,
        mapEntryInfo: mapEntryInfo
      )
    )
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "int32_overflow_map": {
          "2147483648": "overflow"
        }
      }
      """

    let jsonData = jsonString.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(jsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError {
        if case .invalidMapKeyFormat(let fieldName, let keyType, let value) = jsonError {
          XCTAssertEqual(fieldName, "int32_overflow_map")
          XCTAssertEqual(keyType, "Int32")
          XCTAssertEqual(value, "2147483648")
        }
        else {
          XCTFail("Wrong error type: \(jsonError)")
        }
      }
      else {
        XCTFail("Expected JSONDeserializationError, got: \(error)")
      }
    }
  }

  func testDeserializeInvalidArrayElement() throws {
    var message = MessageDescriptor(name: "ArrayErrorMessage", parent: fileDescriptor)
    message.addField(FieldDescriptor(name: "numbers", number: 1, type: .int32, isRepeated: true))
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "numbers": [1, "not_a_number", 3]
      }
      """

    let jsonData = jsonString.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(jsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError,
        case .invalidArrayElement(let fieldName, let index, _) = jsonError
      {
        XCTAssertEqual(fieldName, "numbers")
        XCTAssertEqual(index, 1)
      }
      else {
        XCTFail("Expected invalidArrayElement error, got: \(error)")
      }
    }
  }

  func testDeserializeMapWithInvalidKeyFormats() throws {
    // Test invalid formats for different key types

    // UInt32 keys with invalid format
    let uint32KeyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .uint32)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let uint32MapEntryInfo = MapEntryInfo(keyFieldInfo: uint32KeyFieldInfo, valueFieldInfo: valueFieldInfo)

    var message = MessageDescriptor(name: "UInt32MapMessage", parent: fileDescriptor)
    message.addField(
      FieldDescriptor(
        name: "uint32_map",
        number: 1,
        type: .message,
        typeName: "uint32_map_entry",
        isMap: true,
        mapEntryInfo: uint32MapEntryInfo
      )
    )
    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "uint32_map": {
          "invalid_uint32": "value"
        }
      }
      """

    let jsonData = jsonString.data(using: .utf8)!

    XCTAssertThrowsError(try deserializer.deserialize(jsonData, using: message)) { error in
      if let jsonError = error as? JSONDeserializationError,
        case .invalidMapKeyFormat(let fieldName, let keyType, let value) = jsonError
      {
        XCTAssertEqual(fieldName, "uint32_map")
        XCTAssertEqual(keyType, "UInt32")
        XCTAssertEqual(value, "invalid_uint32")
      }
      else {
        XCTFail("Expected invalidMapKeyFormat error, got: \(error)")
      }
    }
  }

  // MARK: - Additional Coverage Tests

  func testDeserializeMapWithAllKeyTypesUnique() throws {
    // Test all supported key types for map

    // String keys
    let stringKeyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .string)
    let stringMapEntryInfo = MapEntryInfo(keyFieldInfo: stringKeyFieldInfo, valueFieldInfo: valueFieldInfo)

    var message = MessageDescriptor(name: "AllKeyTypesMessage", parent: fileDescriptor)
    message.addField(
      FieldDescriptor(
        name: "string_map",
        number: 1,
        type: .message,
        typeName: "string_map_entry",
        isMap: true,
        mapEntryInfo: stringMapEntryInfo
      )
    )

    // Int32 keys
    let int32KeyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .int32)
    let int32MapEntryInfo = MapEntryInfo(keyFieldInfo: int32KeyFieldInfo, valueFieldInfo: valueFieldInfo)
    message.addField(
      FieldDescriptor(
        name: "int32_map",
        number: 2,
        type: .message,
        typeName: "int32_map_entry",
        isMap: true,
        mapEntryInfo: int32MapEntryInfo
      )
    )

    // Int64 keys
    let int64KeyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .int64)
    let int64MapEntryInfo = MapEntryInfo(keyFieldInfo: int64KeyFieldInfo, valueFieldInfo: valueFieldInfo)
    message.addField(
      FieldDescriptor(
        name: "int64_map",
        number: 3,
        type: .message,
        typeName: "int64_map_entry",
        isMap: true,
        mapEntryInfo: int64MapEntryInfo
      )
    )

    // UInt64 keys
    let uint64KeyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .uint64)
    let uint64MapEntryInfo = MapEntryInfo(keyFieldInfo: uint64KeyFieldInfo, valueFieldInfo: valueFieldInfo)
    message.addField(
      FieldDescriptor(
        name: "uint64_map",
        number: 4,
        type: .message,
        typeName: "uint64_map_entry",
        isMap: true,
        mapEntryInfo: uint64MapEntryInfo
      )
    )

    fileDescriptor.addMessage(message)

    let jsonString = """
      {
        "string_map": {"key1": "value1"},
        "int32_map": {"42": "answer"},
        "int64_map": {"9223372036854775000": "large_number"},
        "uint64_map": {"18446744073709551000": "very_large_number"}
      }
      """

    let jsonData = jsonString.data(using: .utf8)!
    let deserializedMessage = try deserializer.deserialize(jsonData, using: message)

    let accessor = FieldAccessor(deserializedMessage)

    let stringMap = accessor.getValue("string_map", as: [String: String].self)!
    XCTAssertEqual(stringMap["key1"], "value1")

    let int32Map = accessor.getValue("int32_map", as: [Int32: String].self)!
    XCTAssertEqual(int32Map[42], "answer")

    let int64Map = accessor.getValue("int64_map", as: [Int64: String].self)!
    XCTAssertEqual(int64Map[9_223_372_036_854_775_000], "large_number")

    let uint64Map = accessor.getValue("uint64_map", as: [UInt64: String].self)!
    XCTAssertEqual(uint64Map[18_446_744_073_709_551_000], "very_large_number")
  }
}
