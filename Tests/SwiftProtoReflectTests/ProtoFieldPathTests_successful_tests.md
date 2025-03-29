# ProtoFieldPathTests - Успешные тесты

## testGetValueWithSimplePath
### Сравнение с protoc
- Корректно реализует получение значения поля по простому пути
- Соответствует поведению protoc при обращении к полям сообщения
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#field-types
- Код теста:
```swift
func testGetValueWithSimplePath() {
    let path = ProtoFieldPath(path: "name")
    let value = path.getValue(from: person)

    XCTAssertNotNil(value)
    XCTAssertEqual(value?.getString(), "John Doe")
}
```

### Сравнение со спецификацией
- Правильно реализует доступ к полям сообщения согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#field-types
- Код теста:
```swift
func testGetValueWithSimplePath() {
    let path = ProtoFieldPath(path: "name")
    let value = path.getValue(from: person)

    XCTAssertNotNil(value)
    XCTAssertEqual(value?.getString(), "John Doe")
}
```

## testGetValueWithNestedPath
### Сравнение с protoc
- Корректно реализует получение значения вложенного поля
- Соответствует поведению protoc при обращении к вложенным полям
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#nested-types
- Код теста:
```swift
func testGetValueWithNestedPath() {
    let path = ProtoFieldPath(path: "address.street")
    let value = path.getValue(from: person)

    XCTAssertNotNil(value)
    XCTAssertEqual(value?.getString(), "123 Main St")
}
```

### Сравнение со спецификацией
- Правильно реализует доступ к вложенным полям согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#nested-types
- Код теста:
```swift
func testGetValueWithNestedPath() {
    let path = ProtoFieldPath(path: "address.street")
    let value = path.getValue(from: person)

    XCTAssertNotNil(value)
    XCTAssertEqual(value?.getString(), "123 Main St")
}
```

## testSetValueWithSimplePath
### Сравнение с protoc
- Корректно реализует установку значения поля по простому пути
- Соответствует поведению protoc при установке значений полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#field-types
- Код теста:
```swift
func testSetValueWithSimplePath() {
    let path = ProtoFieldPath(path: "name")
    let result = path.setValue(.stringValue("Jane Doe"), in: person)

    XCTAssertTrue(result)
    XCTAssertEqual(person.get(field: personDescriptor.field(named: "name")!)?.getString(), "Jane Doe")
}
```

### Сравнение со спецификацией
- Правильно реализует установку значений полей согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#field-types
- Код теста:
```swift
func testSetValueWithSimplePath() {
    let path = ProtoFieldPath(path: "name")
    let result = path.setValue(.stringValue("Jane Doe"), in: person)

    XCTAssertTrue(result)
    XCTAssertEqual(person.get(field: personDescriptor.field(named: "name")!)?.getString(), "Jane Doe")
}
```

## testSetValueWithNestedPath
### Сравнение с protoc
- Корректно реализует установку значения вложенного поля
- Соответствует поведению protoc при установке значений вложенных полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#nested-types
- Код теста:
```swift
func testSetValueWithNestedPath() {
    let path = ProtoFieldPath(path: "address.street")
    let result = path.setValue(.stringValue("456 Oak Ave"), in: person)

    XCTAssertTrue(result)

    let address = person.get(field: personDescriptor.field(named: "address")!)?.getMessage() as? ProtoDynamicMessage
    XCTAssertNotNil(address)
    XCTAssertEqual(address?.get(field: addressDescriptor.field(named: "street")!)?.getString(), "456 Oak Ave")
}
```

### Сравнение со спецификацией
- Правильно реализует установку значений вложенных полей согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#nested-types
- Код теста:
```swift
func testSetValueWithNestedPath() {
    let path = ProtoFieldPath(path: "address.street")
    let result = path.setValue(.stringValue("456 Oak Ave"), in: person)

    XCTAssertTrue(result)

    let address = person.get(field: personDescriptor.field(named: "address")!)?.getMessage() as? ProtoDynamicMessage
    XCTAssertNotNil(address)
    XCTAssertEqual(address?.get(field: addressDescriptor.field(named: "street")!)?.getString(), "456 Oak Ave")
}
```

## testClearValueWithSimplePath
### Сравнение с protoc
- Корректно реализует очистку значения поля
- Соответствует поведению protoc при очистке полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#field-types
- Код теста:
```swift
func testClearValueWithSimplePath() {
    let path = ProtoFieldPath(path: "name")
    let result = path.clearValue(in: person)

    XCTAssertTrue(result)
    XCTAssertNil(person.get(field: personDescriptor.field(named: "name")!))
}
```

### Сравнение со спецификацией
- Правильно реализует очистку полей согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#field-types
- Код теста:
```swift
func testClearValueWithSimplePath() {
    let path = ProtoFieldPath(path: "name")
    let result = path.clearValue(in: person)

    XCTAssertTrue(result)
    XCTAssertNil(person.get(field: personDescriptor.field(named: "name")!))
}
```

## testHasValueWithSimplePath
### Сравнение с protoc
- Корректно реализует проверку наличия значения поля
- Соответствует поведению protoc при проверке наличия полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#field-types
- Код теста:
```swift
func testHasValueWithSimplePath() {
    let path = ProtoFieldPath(path: "name")
    let result = path.hasValue(in: person)

    XCTAssertTrue(result)

    path.clearValue(in: person)
    XCTAssertFalse(path.hasValue(in: person))
}
```

### Сравнение со спецификацией
- Правильно реализует проверку наличия полей согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#field-types
- Код теста:
```swift
func testHasValueWithSimplePath() {
    let path = ProtoFieldPath(path: "name")
    let result = path.hasValue(in: person)

    XCTAssertTrue(result)

    path.clearValue(in: person)
    XCTAssertFalse(path.hasValue(in: person))
} 