# ProtoFieldTypeTests - Успешные тесты

## testNumericTypes
### Сравнение с protoc
- Корректно проверяет все числовые типы данных
- Соответствует поведению protoc для определения числовых типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Код теста:
```swift
func testNumericTypes() {
    // All integer types are numeric
    XCTAssertTrue(ProtoFieldType.int32.isNumericType())
    XCTAssertTrue(ProtoFieldType.int64.isNumericType())
    XCTAssertTrue(ProtoFieldType.uint32.isNumericType())
    XCTAssertTrue(ProtoFieldType.uint64.isNumericType())
    XCTAssertTrue(ProtoFieldType.sint32.isNumericType())
    XCTAssertTrue(ProtoFieldType.sint64.isNumericType())
    XCTAssertTrue(ProtoFieldType.fixed32.isNumericType())
    XCTAssertTrue(ProtoFieldType.fixed64.isNumericType())
    XCTAssertTrue(ProtoFieldType.sfixed32.isNumericType())
    XCTAssertTrue(ProtoFieldType.sfixed64.isNumericType())
    
    // All floating-point types are numeric
    XCTAssertTrue(ProtoFieldType.float.isNumericType())
    XCTAssertTrue(ProtoFieldType.double.isNumericType())
    
    // Non-numeric types
    XCTAssertFalse(ProtoFieldType.bool.isNumericType())
    XCTAssertFalse(ProtoFieldType.string.isNumericType())
    XCTAssertFalse(ProtoFieldType.bytes.isNumericType())
    XCTAssertFalse(ProtoFieldType.message(nil).isNumericType())
    XCTAssertFalse(ProtoFieldType.enum(nil).isNumericType())
}
```

### Сравнение со спецификацией
- Корректно реализует классификацию типов согласно спецификации protobuf
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Правильно различает числовые и нечисловые типы данных

## testWireTypeMapping
### Сравнение с protoc
- Корректно определяет wire type для каждого типа данных
- Соответствует поведению protoc
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Код теста:
```swift
func testWireTypeMapping() {
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .int32), ProtoWireFormat.wireTypeVarint)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .int64), ProtoWireFormat.wireTypeVarint)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .uint32), ProtoWireFormat.wireTypeVarint)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .uint64), ProtoWireFormat.wireTypeVarint)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .sint32), ProtoWireFormat.wireTypeVarint)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .sint64), ProtoWireFormat.wireTypeVarint)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .fixed32), ProtoWireFormat.wireTypeFixed32)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .fixed64), ProtoWireFormat.wireTypeFixed64)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .sfixed32), ProtoWireFormat.wireTypeFixed32)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .sfixed64), ProtoWireFormat.wireTypeFixed64)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .float), ProtoWireFormat.wireTypeFixed32)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .double), ProtoWireFormat.wireTypeFixed64)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .bool), ProtoWireFormat.wireTypeVarint)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .string), ProtoWireFormat.wireTypeLengthDelimited)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .bytes), ProtoWireFormat.wireTypeLengthDelimited)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .message(nil)), ProtoWireFormat.wireTypeLengthDelimited)
    XCTAssertEqual(ProtoWireFormat.determineWireType(for: .enum(nil)), ProtoWireFormat.wireTypeVarint)
}
```

### Сравнение со спецификацией
- Полностью соответствует спецификации wire format protobuf
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Правильно определяет wire type для всех типов данных

## testFieldNumberValidation
### Сравнение с protoc
- Корректно валидирует номера полей
- Соответствует поведению protoc
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#assigning_field_numbers
- Код теста:
```swift
func testTypeValidationWithFieldNumbers() {
    let testCases: [(ProtoFieldType, Int, Bool)] = [
        // Valid field numbers (1-536870911)
        (.int32, 1, true),
        (.int32, 536870911, true),
        (.int32, 2, true),
        (.int32, 536870910, true),
        
        // Invalid field numbers
        (.int32, 0, false),
        (.int32, 536870912, false),
        (.int32, -1, false),
        
        // Reserved field numbers (19000-19999)
        (.int32, 19000, false),
        (.int32, 19999, false),
        (.int32, 19500, false)
    ]
    
    for (type, fieldNumber, shouldSucceed) in testCases {
        let isValid = ProtoFieldType.validateFieldNumber(fieldNumber)
        if shouldSucceed {
            XCTAssertTrue(isValid, "Field number \(fieldNumber) should be valid for type \(type)")
        } else {
            XCTAssertFalse(isValid, "Field number \(fieldNumber) should be invalid for type \(type)")
        }
    }
}
```

### Сравнение со спецификацией
- Корректно проверяет диапазоны допустимых номеров полей
- Правильно обрабатывает зарезервированные номера полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#assigning_field_numbers 