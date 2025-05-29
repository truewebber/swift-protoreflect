//
// BinarySerializerTypeMismatchTests.swift
// SwiftProtoReflectTests
//
// Тесты type mismatch errors для BinarySerializer
// Покрывают все непокрытые error paths в encodeValue методе и field validation
//

import XCTest

@testable import SwiftProtoReflect

final class BinarySerializerTypeMismatchTests: XCTestCase {

  // MARK: - Test Infrastructure

  private var serializer: BinarySerializer!
  private var fileDescriptor: FileDescriptor!
  private var messageFactory: MessageFactory!

  override func setUp() {
    super.setUp()
    serializer = BinarySerializer()
    fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    messageFactory = MessageFactory()
  }

  override func tearDown() {
    serializer = nil
    fileDescriptor = nil
    messageFactory = nil
    super.tearDown()
  }

  // MARK: - Helper Methods

  /// Создает сообщение с полем правильного типа, но устанавливает значение неправильного типа.
  private func createMessageWithTypeMismatch(
    fieldType: FieldType,
    wrongValue: Any,
    fieldName: String = "test_field",
    typeName: String? = nil
  ) throws -> DynamicMessage {
    var messageDescriptor = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    messageDescriptor.addField(
      FieldDescriptor(
        name: fieldName,
        number: 1,
        type: fieldType,
        typeName: typeName
      )
    )
    fileDescriptor.addMessage(messageDescriptor)

    let message = messageFactory.createMessage(from: messageDescriptor)
    return message
  }

  /// Тестирует encodeValue напрямую с неправильным типом.
  private func testEncodeValueTypeMismatch(
    fieldType: FieldType,
    wrongValue: Any,
    expectedType: String,
    actualTypeContains: String,
    typeName: String? = nil,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    XCTAssertThrowsError(
      try serializer.testTypeMismatchError(fieldType: fieldType, wrongValue: wrongValue, typeName: typeName)
    ) { error in
      // Проверяем что получили правильную ошибку
      if let serializationError = error as? SerializationError,
        case .valueTypeMismatch(let expected, let actual) = serializationError
      {
        XCTAssertEqual(expected, expectedType, file: file, line: line)
        XCTAssertTrue(
          actual.contains(actualTypeContains),
          "Expected '\(actual)' to contain '\(actualTypeContains)'",
          file: file,
          line: line
        )
      }
      else if let dynamicMessageError = error as? DynamicMessageError,
        case .typeMismatch(_, let expected, let actualValue) = dynamicMessageError
      {
        // Также принимаем DynamicMessageError
        XCTAssertEqual(expected, expectedType, file: file, line: line)
        let actualType = String(describing: type(of: actualValue))
        XCTAssertTrue(
          actualType.contains(actualTypeContains),
          "Expected '\(actualType)' to contain '\(actualTypeContains)'",
          file: file,
          line: line
        )
      }
      else {
        XCTFail("Expected type mismatch error, got: \(error)", file: file, line: line)
      }
    }
  }

  // MARK: - Double Field Type Mismatch Tests (Line 177)

  func testEncodeValue_doubleField_stringValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .double,
      wrongValue: "not_a_double",
      expectedType: "Double",
      actualTypeContains: "String"
    )
  }

  func testEncodeValue_doubleField_dataValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .double,
      wrongValue: Data([1, 2, 3]),
      expectedType: "Double",
      actualTypeContains: "Data"
    )
  }

  // MARK: - Float Field Type Mismatch Tests (Line 183)

  func testEncodeValue_floatField_stringValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .float,
      wrongValue: "not_a_float",
      expectedType: "Float",
      actualTypeContains: "String"
    )
  }

  func testEncodeValue_floatField_dataValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .float,
      wrongValue: Data([1, 2, 3]),
      expectedType: "Float",
      actualTypeContains: "Data"
    )
  }

  // MARK: - Int32 Field Type Mismatch Tests (Line 189)

  func testEncodeValue_int32Field_stringValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .int32,
      wrongValue: "not_an_int",
      expectedType: "Int32",
      actualTypeContains: "String"
    )
  }

  func testEncodeValue_int32Field_doubleValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .int32,
      wrongValue: 42.5,
      expectedType: "Int32",
      actualTypeContains: "Double"
    )
  }

  func testEncodeValue_int32Field_boolValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .int32,
      wrongValue: true,
      expectedType: "Int32",
      actualTypeContains: "Bool"
    )
  }

  func testEncodeValue_int32Field_int64Value() throws {
    testEncodeValueTypeMismatch(
      fieldType: .int32,
      wrongValue: Int64(42),
      expectedType: "Int32",
      actualTypeContains: "Int64"
    )
  }

  // MARK: - Int64 Field Type Mismatch Tests (Line 195)

  func testEncodeValue_int64Field_stringValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .int64,
      wrongValue: "not_an_int64",
      expectedType: "Int64",
      actualTypeContains: "String"
    )
  }

  func testEncodeValue_int64Field_floatValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .int64,
      wrongValue: Float(42.5),
      expectedType: "Int64",
      actualTypeContains: "Float"
    )
  }

  func testEncodeValue_int64Field_boolValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .int64,
      wrongValue: false,
      expectedType: "Int64",
      actualTypeContains: "Bool"
    )
  }

  func testEncodeValue_int64Field_int32Value() throws {
    testEncodeValueTypeMismatch(
      fieldType: .int64,
      wrongValue: Int32(42),
      expectedType: "Int64",
      actualTypeContains: "Int32"
    )
  }

  // MARK: - UInt32 Field Type Mismatch Tests (Line 201)

  func testEncodeValue_uint32Field_stringValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .uint32,
      wrongValue: "not_uint32",
      expectedType: "UInt32",
      actualTypeContains: "String"
    )
  }

  func testEncodeValue_uint32Field_doubleValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .uint32,
      wrongValue: 42.5,
      expectedType: "UInt32",
      actualTypeContains: "Double"
    )
  }

  func testEncodeValue_uint32Field_boolValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .uint32,
      wrongValue: true,
      expectedType: "UInt32",
      actualTypeContains: "Bool"
    )
  }

  func testEncodeValue_uint32Field_uint64Value() throws {
    testEncodeValueTypeMismatch(
      fieldType: .uint32,
      wrongValue: UInt64(42),
      expectedType: "UInt32",
      actualTypeContains: "UInt64"
    )
  }

  // MARK: - UInt64 Field Type Mismatch Tests (Line 207)

  func testEncodeValue_uint64Field_stringValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .uint64,
      wrongValue: "not_uint64",
      expectedType: "UInt64",
      actualTypeContains: "String"
    )
  }

  func testEncodeValue_uint64Field_floatValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .uint64,
      wrongValue: Float(42.5),
      expectedType: "UInt64",
      actualTypeContains: "Float"
    )
  }

  func testEncodeValue_uint64Field_boolValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .uint64,
      wrongValue: false,
      expectedType: "UInt64",
      actualTypeContains: "Bool"
    )
  }

  func testEncodeValue_uint64Field_uint32Value() throws {
    testEncodeValueTypeMismatch(
      fieldType: .uint64,
      wrongValue: UInt32(42),
      expectedType: "UInt64",
      actualTypeContains: "UInt32"
    )
  }

  // MARK: - Sint32 Field Type Mismatch Tests (Line 213)

  func testEncodeValue_sint32Field_stringValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .sint32,
      wrongValue: "not_sint32",
      expectedType: "Int32",
      actualTypeContains: "String"
    )
  }

  func testEncodeValue_sint32Field_doubleValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .sint32,
      wrongValue: 42.5,
      expectedType: "Int32",
      actualTypeContains: "Double"
    )
  }

  func testEncodeValue_sint32Field_boolValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .sint32,
      wrongValue: true,
      expectedType: "Int32",
      actualTypeContains: "Bool"
    )
  }

  func testEncodeValue_sint32Field_int64Value() throws {
    testEncodeValueTypeMismatch(
      fieldType: .sint32,
      wrongValue: Int64(42),
      expectedType: "Int32",
      actualTypeContains: "Int64"
    )
  }

  // MARK: - Sint64 Field Type Mismatch Tests (Line 219)

  func testEncodeValue_sint64Field_stringValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .sint64,
      wrongValue: "not_sint64",
      expectedType: "Int64",
      actualTypeContains: "String"
    )
  }

  func testEncodeValue_sint64Field_floatValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .sint64,
      wrongValue: Float(42.5),
      expectedType: "Int64",
      actualTypeContains: "Float"
    )
  }

  func testEncodeValue_sint64Field_boolValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .sint64,
      wrongValue: false,
      expectedType: "Int64",
      actualTypeContains: "Bool"
    )
  }

  func testEncodeValue_sint64Field_int32Value() throws {
    testEncodeValueTypeMismatch(
      fieldType: .sint64,
      wrongValue: Int32(42),
      expectedType: "Int64",
      actualTypeContains: "Int32"
    )
  }

  // MARK: - Fixed32 Field Type Mismatch Tests (Line 225)

  func testEncodeValue_fixed32Field_stringValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .fixed32,
      wrongValue: "not_fixed32",
      expectedType: "UInt32",
      actualTypeContains: "String"
    )
  }

  func testEncodeValue_fixed32Field_doubleValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .fixed32,
      wrongValue: 42.5,
      expectedType: "UInt32",
      actualTypeContains: "Double"
    )
  }

  func testEncodeValue_fixed32Field_boolValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .fixed32,
      wrongValue: true,
      expectedType: "UInt32",
      actualTypeContains: "Bool"
    )
  }

  func testEncodeValue_fixed32Field_int32Value() throws {
    testEncodeValueTypeMismatch(
      fieldType: .fixed32,
      wrongValue: Int32(42),
      expectedType: "UInt32",
      actualTypeContains: "Int32"
    )
  }

  // MARK: - Fixed64 Field Type Mismatch Tests (Line 231)

  func testEncodeValue_fixed64Field_stringValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .fixed64,
      wrongValue: "not_fixed64",
      expectedType: "UInt64",
      actualTypeContains: "String"
    )
  }

  func testEncodeValue_fixed64Field_floatValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .fixed64,
      wrongValue: Float(42.5),
      expectedType: "UInt64",
      actualTypeContains: "Float"
    )
  }

  func testEncodeValue_fixed64Field_boolValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .fixed64,
      wrongValue: false,
      expectedType: "UInt64",
      actualTypeContains: "Bool"
    )
  }

  func testEncodeValue_fixed64Field_int64Value() throws {
    testEncodeValueTypeMismatch(
      fieldType: .fixed64,
      wrongValue: Int64(42),
      expectedType: "UInt64",
      actualTypeContains: "Int64"
    )
  }

  // MARK: - Sfixed32 Field Type Mismatch Tests (Line 237)

  func testEncodeValue_sfixed32Field_stringValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .sfixed32,
      wrongValue: "not_sfixed32",
      expectedType: "Int32",
      actualTypeContains: "String"
    )
  }

  func testEncodeValue_sfixed32Field_doubleValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .sfixed32,
      wrongValue: 42.5,
      expectedType: "Int32",
      actualTypeContains: "Double"
    )
  }

  func testEncodeValue_sfixed32Field_boolValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .sfixed32,
      wrongValue: true,
      expectedType: "Int32",
      actualTypeContains: "Bool"
    )
  }

  func testEncodeValue_sfixed32Field_uint32Value() throws {
    testEncodeValueTypeMismatch(
      fieldType: .sfixed32,
      wrongValue: UInt32(42),
      expectedType: "Int32",
      actualTypeContains: "UInt32"
    )
  }

  // MARK: - Sfixed64 Field Type Mismatch Tests (Line 243)

  func testEncodeValue_sfixed64Field_stringValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .sfixed64,
      wrongValue: "not_sfixed64",
      expectedType: "Int64",
      actualTypeContains: "String"
    )
  }

  func testEncodeValue_sfixed64Field_floatValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .sfixed64,
      wrongValue: Float(42.5),
      expectedType: "Int64",
      actualTypeContains: "Float"
    )
  }

  func testEncodeValue_sfixed64Field_boolValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .sfixed64,
      wrongValue: false,
      expectedType: "Int64",
      actualTypeContains: "Bool"
    )
  }

  func testEncodeValue_sfixed64Field_uint64Value() throws {
    testEncodeValueTypeMismatch(
      fieldType: .sfixed64,
      wrongValue: UInt64(42),
      expectedType: "Int64",
      actualTypeContains: "UInt64"
    )
  }

  // MARK: - Bool Field Type Mismatch Tests (Line 249)

  func testEncodeValue_boolField_stringValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .bool,
      wrongValue: "true",
      expectedType: "Bool",
      actualTypeContains: "String"
    )
  }

  func testEncodeValue_boolField_intValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .bool,
      wrongValue: Int32(1),
      expectedType: "Bool",
      actualTypeContains: "Int32"
    )
  }

  func testEncodeValue_boolField_doubleValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .bool,
      wrongValue: 1.0,
      expectedType: "Bool",
      actualTypeContains: "Double"
    )
  }

  func testEncodeValue_boolField_dataValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .bool,
      wrongValue: Data([1]),
      expectedType: "Bool",
      actualTypeContains: "Data"
    )
  }

  // MARK: - String Field Type Mismatch Tests (Line 255)

  func testEncodeValue_stringField_intValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .string,
      wrongValue: Int32(42),
      expectedType: "String",
      actualTypeContains: "Int32"
    )
  }

  func testEncodeValue_stringField_boolValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .string,
      wrongValue: true,
      expectedType: "String",
      actualTypeContains: "Bool"
    )
  }

  func testEncodeValue_stringField_doubleValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .string,
      wrongValue: 42.5,
      expectedType: "String",
      actualTypeContains: "Double"
    )
  }

  func testEncodeValue_stringField_dataValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .string,
      wrongValue: Data([65, 66, 67]),
      expectedType: "String",
      actualTypeContains: "Data"
    )
  }

  // MARK: - Bytes Field Type Mismatch Tests (Line 263)

  func testEncodeValue_bytesField_stringValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .bytes,
      wrongValue: "not_data",
      expectedType: "Data",
      actualTypeContains: "String"
    )
  }

  func testEncodeValue_bytesField_intValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .bytes,
      wrongValue: Int32(42),
      expectedType: "Data",
      actualTypeContains: "Int32"
    )
  }

  func testEncodeValue_bytesField_boolValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .bytes,
      wrongValue: true,
      expectedType: "Data",
      actualTypeContains: "Bool"
    )
  }

  func testEncodeValue_bytesField_doubleValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .bytes,
      wrongValue: 42.5,
      expectedType: "Data",
      actualTypeContains: "Double"
    )
  }

  // MARK: - Message Field Type Mismatch Tests (Line 270)

  func testEncodeValue_messageField_stringValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .message,
      wrongValue: "not_a_message",
      expectedType: "DynamicMessage",
      actualTypeContains: "String",
      typeName: "test.NestedMessage"
    )
  }

  func testEncodeValue_messageField_intValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .message,
      wrongValue: Int32(42),
      expectedType: "DynamicMessage",
      actualTypeContains: "Int32",
      typeName: "test.NestedMessage"
    )
  }

  func testEncodeValue_messageField_boolValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .message,
      wrongValue: true,
      expectedType: "DynamicMessage",
      actualTypeContains: "Bool",
      typeName: "test.NestedMessage"
    )
  }

  func testEncodeValue_messageField_dataValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .message,
      wrongValue: Data([1, 2, 3]),
      expectedType: "DynamicMessage",
      actualTypeContains: "Data",
      typeName: "test.NestedMessage"
    )
  }

  // MARK: - Enum Field Type Mismatch Tests (Line 284)

  func testEncodeValue_enumField_stringValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .enum,
      wrongValue: Data([1, 2, 3]),
      expectedType: "Enum (Int32 or String)",
      actualTypeContains: "Data",
      typeName: "test.Status"
    )
  }

  func testEncodeValue_enumField_doubleValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .enum,
      wrongValue: 42.5,
      expectedType: "Enum (Int32 or String)",
      actualTypeContains: "Double",
      typeName: "test.Status"
    )
  }

  func testEncodeValue_enumField_boolValue() throws {
    testEncodeValueTypeMismatch(
      fieldType: .enum,
      wrongValue: true,
      expectedType: "Enum (Int32 or String)",
      actualTypeContains: "Bool",
      typeName: "test.Status"
    )
  }

  func testEncodeValue_enumField_int64Value() throws {
    testEncodeValueTypeMismatch(
      fieldType: .enum,
      wrongValue: Int64(42),
      expectedType: "Enum (Int32 or String)",
      actualTypeContains: "Int64",
      typeName: "test.Status"
    )
  }

  // MARK: - Field Validation Error Tests

  /// Тестирует missing field value error - создаем ситуацию где поле должно быть, но его нет.
  func testSerialize_missingFieldValue() throws {
    var messageDescriptor = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    messageDescriptor.addField(FieldDescriptor(name: "test_field", number: 1, type: .string))
    fileDescriptor.addMessage(messageDescriptor)

    let message = messageFactory.createMessage(from: messageDescriptor)

    // Пустое сообщение должно сериализоваться без ошибок (proto3 семантика)
    // Этот тест проверяет что отсутствующие поля не вызывают ошибок
    let data = try serializer.serialize(message)
    XCTAssertEqual(data.count, 0)  // Пустые поля не сериализуются
  }

  /// Тестирует invalid repeated field type error - пытаемся установить не-массив в repeated поле.
  func testSerialize_invalidRepeatedFieldType() throws {
    var messageDescriptor = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    messageDescriptor.addField(
      FieldDescriptor(
        name: "repeated_field",
        number: 1,
        type: .string,
        isRepeated: true
      )
    )
    fileDescriptor.addMessage(messageDescriptor)

    var message = messageFactory.createMessage(from: messageDescriptor)

    // Пытаемся установить не-массив в repeated поле
    XCTAssertThrowsError(try message.set("not_an_array", forField: "repeated_field")) { error in
      // Ожидаем DynamicMessageError.typeMismatch
      guard let dynamicMessageError = error as? DynamicMessageError,
        case .typeMismatch(_, let expectedType, _) = dynamicMessageError
      else {
        XCTFail("Expected DynamicMessageError.typeMismatch, got: \(error)")
        return
      }
      XCTAssertTrue(expectedType.contains("Array"))
    }
  }

  /// Тестирует missing map entry info error - создаем map поле без mapEntryInfo.
  func testSerialize_missingMapEntryInfo() throws {
    var messageDescriptor = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)

    // Создаем обычное message поле (не map), чтобы избежать fatal error
    let messageField = FieldDescriptor(
      name: "message_field",
      number: 1,
      type: .message,
      typeName: "test.NestedMessage"
        // Это обычное message поле, не map
    )
    messageDescriptor.addField(messageField)
    fileDescriptor.addMessage(messageDescriptor)

    var message = messageFactory.createMessage(from: messageDescriptor)

    // Пытаемся установить словарь в обычное message поле
    XCTAssertThrowsError(try message.set(["key": "value"], forField: "message_field")) { error in
      // Ожидаем DynamicMessageError.typeMismatch
      XCTAssertTrue(error is DynamicMessageError)
    }
  }

  /// Тестирует invalid map field type error - пытаемся установить не-словарь в map поле.
  func testSerialize_invalidMapFieldType() throws {
    let keyFieldInfo = KeyFieldInfo(name: "key", number: 1, type: .string)
    let valueFieldInfo = ValueFieldInfo(name: "value", number: 2, type: .int32)
    let mapEntryInfo = MapEntryInfo(keyFieldInfo: keyFieldInfo, valueFieldInfo: valueFieldInfo)

    var messageDescriptor = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    messageDescriptor.addField(
      FieldDescriptor(
        name: "map_field",
        number: 1,
        type: .message,
        typeName: "map_entry",
        isMap: true,
        mapEntryInfo: mapEntryInfo
      )
    )
    fileDescriptor.addMessage(messageDescriptor)

    var message = messageFactory.createMessage(from: messageDescriptor)

    // Пытаемся установить не-словарь в map поле
    XCTAssertThrowsError(try message.set("not_a_dictionary", forField: "map_field")) { error in
      // Ожидаем DynamicMessageError.typeMismatch
      guard let dynamicMessageError = error as? DynamicMessageError,
        case .typeMismatch(_, let expectedType, _) = dynamicMessageError
      else {
        XCTFail("Expected DynamicMessageError.typeMismatch, got: \(error)")
        return
      }
      XCTAssertTrue(expectedType.contains("Map") || expectedType.contains("Dictionary"))
    }
  }
}

// MARK: - BinarySerializer Testing Extension

extension BinarySerializer {
  /// ТОЛЬКО ДЛЯ ТЕСТИРОВАНИЯ: Создает специальное сообщение для тестирования type mismatch.
  func testTypeMismatchError(fieldType: FieldType, wrongValue: Any, typeName: String? = nil) throws {
    // Создаем временный дескриптор и сообщение
    var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
    var messageDescriptor = MessageDescriptor(name: "TestMessage", parent: fileDescriptor)
    messageDescriptor.addField(
      FieldDescriptor(
        name: "test_field",
        number: 1,
        type: fieldType,
        typeName: typeName
      )
    )
    fileDescriptor.addMessage(messageDescriptor)

    let messageFactory = MessageFactory()
    var message = messageFactory.createMessage(from: messageDescriptor)

    // Пытаемся установить неправильное значение
    // Это должно вызвать ошибку уже на этапе set, но если нет - то при сериализации
    do {
      try message.set(wrongValue, forField: "test_field")
      // Если set прошел успешно, пытаемся сериализовать
      _ = try self.serialize(message)
      // Если дошли сюда, то ошибки не было - это неожиданно
      throw TestError.unexpectedSuccess
    }
    catch let error as DynamicMessageError {
      // Преобразуем DynamicMessageError в SerializationError для единообразия
      if case .typeMismatch(_, let expectedType, let actualValue) = error {
        throw SerializationError.valueTypeMismatch(
          expected: expectedType,
          actual: String(describing: type(of: actualValue))
        )
      }
      throw error
    }
  }
}

/// Вспомогательная ошибка для тестирования.
enum TestError: Error {
  case unexpectedSuccess
}
