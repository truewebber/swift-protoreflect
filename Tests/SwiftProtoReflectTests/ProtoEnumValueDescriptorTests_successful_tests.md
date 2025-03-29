# ProtoEnumValueDescriptorTests - Успешные тесты

## testValidEnumValueDescriptor
### Сравнение с protoc
- Корректно проверяет создание валидного enum value descriptor с именем и номером
- Соответствует поведению protoc для валидации enum values
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Код теста:
```swift
func testValidEnumValueDescriptor() {
    let enumValue = ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
    XCTAssertTrue(enumValue.isValid())
    XCTAssertEqual(enumValue.name, "VALUE_1")
    XCTAssertEqual(enumValue.number, 1)
}
```

### Сравнение со спецификацией
- Корректно реализует требования спецификации protobuf для enum values
- Проверяет обязательные поля: name и number
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Код теста:
```swift
func testValidEnumValueDescriptor() {
    let enumValue = ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
    XCTAssertTrue(enumValue.isValid())
    XCTAssertEqual(enumValue.name, "VALUE_1")
    XCTAssertEqual(enumValue.number, 1)
}
```

## testEnumValueDescriptorEquality
### Сравнение с protoc
- Корректно проверяет равенство enum value descriptors с одинаковыми name и number
- Соответствует поведению protoc для сравнения enum values
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Код теста:
```swift
func testEnumValueDescriptorEquality() {
    let value1 = ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
    let value2 = ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
    XCTAssertEqual(value1, value2)
}
```

### Сравнение со спецификацией
- Корректно реализует требования спецификации protobuf для сравнения enum values
- Проверяет, что два enum value с одинаковыми name и number считаются равными
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Код теста:
```swift
func testEnumValueDescriptorEquality() {
    let value1 = ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
    let value2 = ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
    XCTAssertEqual(value1, value2)
}
``` 