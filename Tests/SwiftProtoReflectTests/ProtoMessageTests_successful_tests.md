# ProtoMessageTests - Успешные тесты

## testGetFieldValue
### Сравнение с protoc
- Корректно проверяет базовое получение значения поля
- Соответствует поведению protoc при чтении значений полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields
- Код теста:
```swift
func testGetFieldValue() {
    message.set(field: descriptor.fields[0], value: .intValue(123))
    let value = message.get(field: descriptor.fields[0])
    XCTAssertEqual(value?.getInt(), 123)
}
```

### Сравнение со спецификацией
- Правильно реализует базовую функциональность доступа к полям согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields
- Код теста:
```swift
func testGetFieldValue() {
    message.set(field: descriptor.fields[0], value: .intValue(123))
    let value = message.get(field: descriptor.fields[0])
    XCTAssertEqual(value?.getInt(), 123)
}
```

## testSetFieldValue
### Сравнение с protoc
- Корректно проверяет установку значений полей
- Соответствует поведению protoc при записи значений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields
- Код теста:
```swift
func testSetFieldValue() {
    message.set(field: descriptor.fields[0], value: .intValue(456))
    let value = message.get(field: descriptor.fields[0])
    XCTAssertEqual(value?.getInt(), 456)
}
```

### Сравнение со спецификацией
- Правильно реализует установку значений полей согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields
- Код теста:
```swift
func testSetFieldValue() {
    message.set(field: descriptor.fields[0], value: .intValue(456))
    let value = message.get(field: descriptor.fields[0])
    XCTAssertEqual(value?.getInt(), 456)
}
```

## testClearFieldValue
### Сравнение с protoc
- Корректно проверяет очистку значений полей
- Соответствует поведению protoc при очистке полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields
- Код теста:
```swift
func testClearFieldValue() {
    message.set(field: descriptor.fields[0], value: .intValue(789))
    message.clear(field: descriptor.fields[0])
    let value = message.get(field: descriptor.fields[0])
    XCTAssertNil(value)
}
```

### Сравнение со спецификацией
- Правильно реализует очистку полей согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields
- Код теста:
```swift
func testClearFieldValue() {
    message.set(field: descriptor.fields[0], value: .intValue(789))
    message.clear(field: descriptor.fields[0])
    let value = message.get(field: descriptor.fields[0])
    XCTAssertNil(value)
} 