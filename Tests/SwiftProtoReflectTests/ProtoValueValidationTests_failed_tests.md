# ProtoValueValidationTests - Неуспешные тесты

## testMapFieldValidation
### Сравнение с protoc
- Не проверяет корректность типов ключей и значений в map
- В текущей реализации map значения с неправильными типами считаются валидными
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Protoc проверяет типы ключей и значений в map
- Код теста:
```swift
func testMapFieldValidation() {
    // Map values with incorrect value types are still considered valid in our implementation
    // This is because we're only checking if the value is a map, not the contents
    XCTAssertTrue(
        ProtoValue.mapValue([
            "key1": .intValue(1),
            "key2": .intValue(2),
        ]).isValid(for: mapStringToStringField)
    )

    // Map values with incorrect value types are still considered valid in our implementation
    XCTAssertTrue(
        ProtoValue.mapValue([
            "key1": .stringValue("value1"),
            "key2": .stringValue("value2"),
        ]).isValid(for: mapInt32ToMessageField)
    )
}
```

### Сравнение со спецификацией
- Не соответствует спецификации protobuf для map полей
- Не проверяет типы ключей и значений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Рекомендации по исправлению:
  1. Добавить проверку типов ключей в map
  2. Добавить проверку типов значений в map
  3. Обновить тесты для проверки невалидных типов ключей и значений
- Код теста:
```swift
func testMapFieldValidation() {
    // ... код теста ...
}
```

## Отсутствующие тесты
### testMapKeyValidation
- Описание: Должен проверять валидацию ключей в map полях
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Пример кода теста:
```swift
func testMapKeyValidation() {
    // Test string key validation
    XCTAssertTrue(
        ProtoValue.mapValue([
            "valid_key": .stringValue("value")
        ]).isValid(for: mapStringToStringField)
    )
    
    XCTAssertFalse(
        ProtoValue.mapValue([
            "": .stringValue("value") // Empty key
        ]).isValid(for: mapStringToStringField)
    )
    
    // Test int32 key validation
    XCTAssertTrue(
        ProtoValue.mapValue([
            "1": .messageValue(message1)
        ]).isValid(for: mapInt32ToMessageField)
    )
    
    XCTAssertFalse(
        ProtoValue.mapValue([
            "invalid": .messageValue(message1) // Non-numeric key
        ]).isValid(for: mapInt32ToMessageField)
    )
}
```

### testMapValueValidation
- Описание: Должен проверять валидацию значений в map полях
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Пример кода теста:
```swift
func testMapValueValidation() {
    // Test string value validation
    XCTAssertTrue(
        ProtoValue.mapValue([
            "key": .stringValue("valid_value")
        ]).isValid(for: mapStringToStringField)
    )
    
    XCTAssertFalse(
        ProtoValue.mapValue([
            "key": .intValue(1) // Wrong value type
        ]).isValid(for: mapStringToStringField)
    )
    
    // Test message value validation
    XCTAssertTrue(
        ProtoValue.mapValue([
            "1": .messageValue(message1)
        ]).isValid(for: mapInt32ToMessageField)
    )
    
    XCTAssertFalse(
        ProtoValue.mapValue([
            "1": .stringValue("wrong_type") // Wrong value type
        ]).isValid(for: mapInt32ToMessageField)
    )
}
```

### testMapDuplicateKeys
- Описание: Должен проверять обработку дублирующихся ключей в map полях
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Пример кода теста:
```swift
func testMapDuplicateKeys() {
    // Test duplicate keys in string-to-string map
    XCTAssertFalse(
        ProtoValue.mapValue([
            "key": .stringValue("value1"),
            "key": .stringValue("value2") // Duplicate key
        ]).isValid(for: mapStringToStringField)
    )
    
    // Test duplicate keys in int32-to-message map
    XCTAssertFalse(
        ProtoValue.mapValue([
            "1": .messageValue(message1),
            "1": .messageValue(message2) // Duplicate key
        ]).isValid(for: mapInt32ToMessageField)
    )
}
```

### testMapNullValues
- Описание: Должен проверять обработку null значений в map полях
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Пример кода теста:
```swift
func testMapNullValues() {
    // Test null values in string-to-string map
    XCTAssertFalse(
        ProtoValue.mapValue([
            "key": .null
        ]).isValid(for: mapStringToStringField)
    )
    
    // Test null values in int32-to-message map
    XCTAssertFalse(
        ProtoValue.mapValue([
            "1": .null
        ]).isValid(for: mapInt32ToMessageField)
    )
}
```

### testMapNestedTypes
- Описание: Должен проверять валидацию вложенных типов в map полях
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Пример кода теста:
```swift
func testMapNestedTypes() {
    // Test nested message in map
    let nestedMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
    XCTAssertTrue(
        ProtoValue.mapValue([
            "key": .messageValue(nestedMessage)
        ]).isValid(for: mapInt32ToMessageField)
    )
    
    // Test nested map in map
    XCTAssertFalse(
        ProtoValue.mapValue([
            "key": .mapValue([
                "nested_key": .stringValue("value")
            ])
        ]).isValid(for: mapStringToStringField)
    )
}
``` 