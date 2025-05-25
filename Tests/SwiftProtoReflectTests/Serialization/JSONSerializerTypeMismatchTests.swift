//
// JSONSerializerTypeMismatchTests.swift
// SwiftProtoReflectTests
//
// Тесты type mismatch errors для JSONSerializer
// Покрывают все непокрытые error paths в convertValueToJSON и convertMapKeyToJSONString
//

import XCTest
@testable import SwiftProtoReflect

final class JSONSerializerTypeMismatchTests: XCTestCase {
    
    // MARK: - Test Infrastructure
    
    private var serializer: JSONSerializer!
    
    override func setUp() {
        super.setUp()
        serializer = JSONSerializer()
    }
    
    override func tearDown() {
        serializer = nil
        super.tearDown()
    }
    
    // MARK: - convertValueToJSON Method Tests
    
    /// Тестирует convertValueToJSON напрямую для покрытия type mismatch paths
    /// Используем тестовое расширение JSONSerializer для доступа к private методам
    
    // MARK: - Double Field Type Mismatch Tests (Line 151)
    
    func testConvertValueToJSON_doubleField_stringValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON("not_a_double", type: .double, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "Double", actualContains: "String")
        }
    }
    
    func testConvertValueToJSON_doubleField_intValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON(Int32(42), type: .double, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "Double", actualContains: "Int32")
        }
    }
    
    func testConvertValueToJSON_doubleField_boolValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON(true, type: .double, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "Double", actualContains: "Bool")
        }
    }
    
    func testConvertValueToJSON_doubleField_dataValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON(Data(), type: .double, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "Double", actualContains: "Data")
        }
    }
    
    func testConvertValueToJSON_doubleField_arrayValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON([1, 2, 3], type: .double, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "Double", actualContains: "Array")
        }
    }
    
    // MARK: - Float Field Type Mismatch Tests (Line 157)
    
    func testConvertValueToJSON_floatField_stringValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON("not_a_float", type: .float, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "Float", actualContains: "String")
        }
    }
    
    func testConvertValueToJSON_floatField_int64Value() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON(Int64(42), type: .float, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "Float", actualContains: "Int64")
        }
    }
    
    func testConvertValueToJSON_floatField_boolValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON(true, type: .float, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "Float", actualContains: "Bool")
        }
    }
    
    // MARK: - Int32 Field Type Mismatch Tests (Line 163)
    
    func testConvertValueToJSON_int32Field_stringValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON("not_an_int", type: .int32, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "Int32", actualContains: "String")
        }
    }
    
    func testConvertValueToJSON_int32Field_doubleValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON(42.5, type: .int32, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "Int32", actualContains: "Double")
        }
    }
    
    func testConvertValueToJSON_int32Field_boolValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON(false, type: .int32, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "Int32", actualContains: "Bool")
        }
    }
    
    // MARK: - Int64 Field Type Mismatch Tests (Line 169)
    
    func testConvertValueToJSON_int64Field_stringValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON("not_an_int64", type: .int64, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "Int64", actualContains: "String")
        }
    }
    
    func testConvertValueToJSON_int64Field_floatValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON(Float(42.5), type: .int64, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "Int64", actualContains: "Float")
        }
    }
    
    // MARK: - UInt32 Field Type Mismatch Tests (Line 176)
    
    func testConvertValueToJSON_uint32Field_stringValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON("not_uint32", type: .uint32, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "UInt32", actualContains: "String")
        }
    }
    
    func testConvertValueToJSON_uint32Field_doubleValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON(42.5, type: .uint32, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "UInt32", actualContains: "Double")
        }
    }
    
    // MARK: - UInt64 Field Type Mismatch Tests (Line 182)
    
    func testConvertValueToJSON_uint64Field_stringValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON("not_uint64", type: .uint64, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "UInt64", actualContains: "String")
        }
    }
    
    func testConvertValueToJSON_uint64Field_floatValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON(Float(42.5), type: .uint64, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "UInt64", actualContains: "Float")
        }
    }
    
    // MARK: - Bool Field Type Mismatch Tests (Line 189)
    
    func testConvertValueToJSON_boolField_stringValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON("true", type: .bool, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "Bool", actualContains: "String")
        }
    }
    
    func testConvertValueToJSON_boolField_intValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON(Int32(1), type: .bool, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "Bool", actualContains: "Int32")
        }
    }
    
    // MARK: - String Field Type Mismatch Tests (Line 195)
    
    func testConvertValueToJSON_stringField_intValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON(Int32(42), type: .string, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "String", actualContains: "Int32")
        }
    }
    
    func testConvertValueToJSON_stringField_boolValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON(true, type: .string, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "String", actualContains: "Bool")
        }
    }
    
    func testConvertValueToJSON_stringField_doubleValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON(42.5, type: .string, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "String", actualContains: "Double")
        }
    }
    
    // MARK: - Bytes Field Type Mismatch Tests (Line 201)
    
    func testConvertValueToJSON_bytesField_stringValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON("not_data", type: .bytes, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "Data", actualContains: "String")
        }
    }
    
    func testConvertValueToJSON_bytesField_intValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON(Int32(42), type: .bytes, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "Data", actualContains: "Int32")
        }
    }
    
    // MARK: - Message Field Type Mismatch Tests (Line 208)
    
    func testConvertValueToJSON_messageField_stringValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON("not_a_message", type: .message, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "DynamicMessage", actualContains: "String")
        }
    }
    
    func testConvertValueToJSON_messageField_intValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON(Int32(42), type: .message, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "DynamicMessage", actualContains: "Int32")
        }
    }
    
    // MARK: - Enum Field Type Mismatch Tests (Line 215)
    
    func testConvertValueToJSON_enumField_stringValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON("not_an_enum", type: .enum, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "Int32", actualContains: "String")
        }
    }
    
    func testConvertValueToJSON_enumField_doubleValue() throws {
        XCTAssertThrowsError(try serializer.testConvertValueToJSON(42.5, type: .enum, typeName: nil)) { error in
            assertValueTypeMismatch(error, expected: "Int32", actualContains: "Double")
        }
    }
    
    // MARK: - convertMapKeyToJSONString Method Tests
    
    // MARK: - String Map Key Type Mismatch Tests (Line 231)
    
    func testConvertMapKeyToJSONString_stringKey_intKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString(42, keyType: .string)) { error in
            assertValueTypeMismatch(error, expected: "String", actualContains: "Int")
        }
    }
    
    func testConvertMapKeyToJSONString_stringKey_doubleKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString(42.5, keyType: .string)) { error in
            assertValueTypeMismatch(error, expected: "String", actualContains: "Double")
        }
    }
    
    func testConvertMapKeyToJSONString_stringKey_boolKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString(true, keyType: .string)) { error in
            assertValueTypeMismatch(error, expected: "String", actualContains: "Bool")
        }
    }
    
    func testConvertMapKeyToJSONString_stringKey_dataKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString(Data(), keyType: .string)) { error in
            assertValueTypeMismatch(error, expected: "String", actualContains: "Data")
        }
    }
    
    // MARK: - Int32 Map Key Type Mismatch Tests (Line 237)
    
    func testConvertMapKeyToJSONString_int32Key_stringKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString("not_int32", keyType: .int32)) { error in
            assertValueTypeMismatch(error, expected: "Int32", actualContains: "String")
        }
    }
    
    func testConvertMapKeyToJSONString_int32Key_doubleKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString(42.5, keyType: .int32)) { error in
            assertValueTypeMismatch(error, expected: "Int32", actualContains: "Double")
        }
    }
    
    func testConvertMapKeyToJSONString_int32Key_boolKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString(false, keyType: .int32)) { error in
            assertValueTypeMismatch(error, expected: "Int32", actualContains: "Bool")
        }
    }
    
    func testConvertMapKeyToJSONString_int32Key_dataKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString(Data([1, 2, 3]), keyType: .int32)) { error in
            assertValueTypeMismatch(error, expected: "Int32", actualContains: "Data")
        }
    }
    
    // MARK: - Int64 Map Key Type Mismatch Tests (Line 243)
    
    func testConvertMapKeyToJSONString_int64Key_stringKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString("not_int64", keyType: .int64)) { error in
            assertValueTypeMismatch(error, expected: "Int64", actualContains: "String")
        }
    }
    
    func testConvertMapKeyToJSONString_int64Key_floatKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString(Float(42.5), keyType: .int64)) { error in
            assertValueTypeMismatch(error, expected: "Int64", actualContains: "Float")
        }
    }
    
    func testConvertMapKeyToJSONString_int64Key_boolKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString(true, keyType: .int64)) { error in
            assertValueTypeMismatch(error, expected: "Int64", actualContains: "Bool")
        }
    }
    
    func testConvertMapKeyToJSONString_int64Key_dataKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString(Data([42]), keyType: .int64)) { error in
            assertValueTypeMismatch(error, expected: "Int64", actualContains: "Data")
        }
    }
    
    // MARK: - UInt32 Map Key Type Mismatch Tests (Line 249)
    
    func testConvertMapKeyToJSONString_uint32Key_stringKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString("not_uint32", keyType: .uint32)) { error in
            assertValueTypeMismatch(error, expected: "UInt32", actualContains: "String")
        }
    }
    
    func testConvertMapKeyToJSONString_uint32Key_doubleKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString(42.5, keyType: .uint32)) { error in
            assertValueTypeMismatch(error, expected: "UInt32", actualContains: "Double")
        }
    }
    
    func testConvertMapKeyToJSONString_uint32Key_boolKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString(true, keyType: .uint32)) { error in
            assertValueTypeMismatch(error, expected: "UInt32", actualContains: "Bool")
        }
    }
    
    func testConvertMapKeyToJSONString_uint32Key_dataKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString(Data([255]), keyType: .uint32)) { error in
            assertValueTypeMismatch(error, expected: "UInt32", actualContains: "Data")
        }
    }
    
    // MARK: - UInt64 Map Key Type Mismatch Tests (Line 255)
    
    func testConvertMapKeyToJSONString_uint64Key_stringKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString("not_uint64", keyType: .uint64)) { error in
            assertValueTypeMismatch(error, expected: "UInt64", actualContains: "String")
        }
    }
    
    func testConvertMapKeyToJSONString_uint64Key_floatKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString(Float(42.5), keyType: .uint64)) { error in
            assertValueTypeMismatch(error, expected: "UInt64", actualContains: "Float")
        }
    }
    
    func testConvertMapKeyToJSONString_uint64Key_boolKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString(false, keyType: .uint64)) { error in
            assertValueTypeMismatch(error, expected: "UInt64", actualContains: "Bool")
        }
    }
    
    func testConvertMapKeyToJSONString_uint64Key_dataKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString(Data([255, 255]), keyType: .uint64)) { error in
            assertValueTypeMismatch(error, expected: "UInt64", actualContains: "Data")
        }
    }
    
    // MARK: - Bool Map Key Type Mismatch Tests (Line 261)
    
    func testConvertMapKeyToJSONString_boolKey_stringKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString("true", keyType: .bool)) { error in
            assertValueTypeMismatch(error, expected: "Bool", actualContains: "String")
        }
    }
    
    func testConvertMapKeyToJSONString_boolKey_intKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString(Int32(1), keyType: .bool)) { error in
            assertValueTypeMismatch(error, expected: "Bool", actualContains: "Int32")
        }
    }
    
    func testConvertMapKeyToJSONString_boolKey_doubleKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString(1.0, keyType: .bool)) { error in
            assertValueTypeMismatch(error, expected: "Bool", actualContains: "Double")
        }
    }
    
    func testConvertMapKeyToJSONString_boolKey_dataKeyValue() throws {
        XCTAssertThrowsError(try serializer.testConvertMapKeyToJSONString(Data([1]), keyType: .bool)) { error in
            assertValueTypeMismatch(error, expected: "Bool", actualContains: "Data")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Проверяет valueTypeMismatch ошибку с правильными типами
    private func assertValueTypeMismatch(_ error: Error, expected: String, actualContains: String, file: StaticString = #file, line: UInt = #line) {
        guard let jsonError = error as? JSONSerializationError,
              case .valueTypeMismatch(let expectedType, let actualType) = jsonError else {
            XCTFail("Expected JSONSerializationError.valueTypeMismatch, got: \(error)", file: file, line: line)
            return
        }
        XCTAssertEqual(expectedType, expected, file: file, line: line)
        XCTAssertTrue(actualType.contains(actualContains), "Expected '\(actualType)' to contain '\(actualContains)'", file: file, line: line)
    }
}

// MARK: - JSONSerializer Testing Extension

extension JSONSerializer {
    
    /// ТОЛЬКО ДЛЯ ТЕСТИРОВАНИЯ: Предоставляет доступ к private методу convertValueToJSON
    func testConvertValueToJSON(_ value: Any, type: FieldType, typeName: String?) throws -> Any {
        return try self.convertValueToJSON(value, type: type, typeName: typeName)
    }
    
    /// ТОЛЬКО ДЛЯ ТЕСТИРОВАНИЯ: Предоставляет доступ к private методу convertMapKeyToJSONString
    func testConvertMapKeyToJSONString(_ key: Any, keyType: FieldType) throws -> String {
        return try self.convertMapKeyToJSONString(key, keyType: keyType)
    }
}
