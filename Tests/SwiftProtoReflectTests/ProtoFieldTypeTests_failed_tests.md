# ProtoFieldTypeTests - Неуспешные тесты

## testTypeConversion
### Сравнение с protoc
- Не полностью соответствует поведению protoc
- protoc допускает больше преобразований типов, чем текущая реализация
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#updating
- Код теста:
```swift
func testTypeConversion() {
    // Valid conversions according to protoc
    XCTAssertEqual(ProtoValue.enumValue(name: "RED", number: 0, enumDescriptor: testEnumDescriptor).convertTo(targetType: .int32)?.getInt(), 0)
    XCTAssertEqual(ProtoValue.messageValue(testMessage).convertTo(targetType: .string)?.getString(), "Message(TestMessage)")
    
    // Invalid conversions according to protoc
    XCTAssertNil(ProtoValue.stringValue("42").convertTo(targetType: .int32))
    XCTAssertNil(ProtoValue.messageValue(testMessage).convertTo(targetType: .int32))
}
```

### Сравнение со спецификацией
- Не учитывает все допустимые преобразования типов согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#updating
- Рекомендации по исправлению:
  1. Добавить поддержку преобразования строк в числовые типы
  2. Добавить поддержку преобразования между различными числовыми типами
  3. Добавить поддержку преобразования между enum и числовыми типами
  4. Добавить поддержку преобразования между message и string

## testEdgeCasesInTypeConversion
### Сравнение с protoc
- Не полностью покрывает edge cases
- Отсутствует проверка overflow/underflow для числовых типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Код теста:
```swift
func testEdgeCasesInTypeConversion() {
    // Test numeric type conversions
    let numericTypes: [ProtoFieldType] = [.int32, .int64, .uint32, .uint64, .sint32, .sint64,
                                        .fixed32, .sfixed32, .fixed64, .sfixed64, .float, .double]
    
    for type in numericTypes {
        XCTAssertTrue(type.isNumericType(), "\(type) should be a numeric type")
    }
    // ... остальной код ...
}
```

### Сравнение со спецификацией
- Не проверяет граничные значения для числовых типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Рекомендации по исправлению:
  1. Добавить проверку максимальных и минимальных значений для каждого числового типа
  2. Добавить проверку NaN и Inf для float и double
  3. Добавить проверку overflow/underflow при преобразовании между типами

## Отсутствующие тесты

### testWireFormatEncoding
- Описание: Должен проверять корректность кодирования различных типов данных в wire format
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding
- Пример кода:
```swift
func testWireFormatEncoding() {
    // Test varint encoding
    let varintValue = ProtoValue.int32Value(42)
    let encoded = varintValue.encode()
    XCTAssertEqual(encoded, [0x2A]) // 42 in varint encoding
    
    // Test fixed32 encoding
    let fixed32Value = ProtoValue.fixed32Value(42)
    let encodedFixed32 = fixed32Value.encode()
    XCTAssertEqual(encodedFixed32, [0x2A, 0x00, 0x00, 0x00])
    
    // Test length-delimited encoding
    let stringValue = ProtoValue.stringValue("test")
    let encodedString = stringValue.encode()
    XCTAssertEqual(encodedString, [0x04, 0x74, 0x65, 0x73, 0x74])
}
```

### testTypeCompatibility
- Описание: Должен проверять совместимость типов при обновлении сообщений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#updating
- Пример кода:
```swift
func testTypeCompatibility() {
    // Test compatible type changes
    XCTAssertTrue(ProtoFieldType.areTypesCompatible(.int32, .int64))
    XCTAssertTrue(ProtoFieldType.areTypesCompatible(.uint32, .uint64))
    
    // Test incompatible type changes
    XCTAssertFalse(ProtoFieldType.areTypesCompatible(.int32, .string))
    XCTAssertFalse(ProtoFieldType.areTypesCompatible(.message(nil), .int32))
    
    // Test enum compatibility
    XCTAssertTrue(ProtoFieldType.areTypesCompatible(.enum(nil), .int32))
    XCTAssertFalse(ProtoFieldType.areTypesCompatible(.enum(nil), .string))
}
```

### testDefaultValues
- Описание: Должен проверять корректность значений по умолчанию для всех типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#default
- Пример кода:
```swift
func testDefaultValues() {
    // Test numeric defaults
    XCTAssertEqual(ProtoValue.int32Value(0).getInt(), 0)
    XCTAssertEqual(ProtoValue.floatValue(0.0).getFloat(), 0.0)
    
    // Test string and bytes defaults
    XCTAssertEqual(ProtoValue.stringValue("").getString(), "")
    XCTAssertEqual(ProtoValue.bytesValue(Data()).getBytes(), Data())
    
    // Test bool default
    XCTAssertEqual(ProtoValue.boolValue(false).getBool(), false)
    
    // Test enum default
    XCTAssertEqual(ProtoValue.enumValue(name: "UNSPECIFIED", number: 0, enumDescriptor: testEnumDescriptor).getEnum().number, 0)
    
    // Test message default
    XCTAssertEqual(ProtoValue.messageValue(nil).getMessage(), nil)
}
``` 