# ProtoEnumValueDescriptorTests - Неуспешные тесты

## testInvalidEnumValueDescriptor
### Сравнение с protoc
- Не полностью соответствует поведению protoc для валидации enum values
- Protoc проверяет дополнительные условия:
  - Имя должно соответствовать правилам именования (только буквы, цифры и подчеркивания)
  - Номер должен быть уникальным в пределах enum
  - Номер должен быть в допустимом диапазоне (0-2^32-1)
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Код теста:
```swift
func testInvalidEnumValueDescriptor() {
    let invalidEnumValue = ProtoEnumValueDescriptor(name: "", number: 1)
    XCTAssertFalse(invalidEnumValue.isValid())
}
```

### Сравнение со спецификацией
- Не полностью соответствует требованиям спецификации protobuf для enum values
- Отсутствуют проверки:
  - Валидация формата имени
  - Уникальность номера
  - Допустимый диапазон номера
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Рекомендации по исправлению:
  1. Добавить проверку формата имени (только буквы, цифры и подчеркивания)
  2. Добавить проверку уникальности номера в пределах enum
  3. Добавить проверку диапазона номера
  4. Добавить тесты для всех случаев невалидных значений
- Код теста:
```swift
func testInvalidEnumValueDescriptor() {
    let invalidEnumValue = ProtoEnumValueDescriptor(name: "", number: 1)
    XCTAssertFalse(invalidEnumValue.isValid())
}
```

## testEnumValueDescriptorInequality
### Сравнение с protoc
- Не полностью соответствует поведению protoc для сравнения enum values
- Protoc также проверяет:
  - Сравнение по имени (case-sensitive)
  - Сравнение по номеру
  - Сравнение по принадлежности к одному enum
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Код теста:
```swift
func testEnumValueDescriptorInequality() {
    let value1 = ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
    let value2 = ProtoEnumValueDescriptor(name: "VALUE_2", number: 2)
    XCTAssertNotEqual(value1, value2)
}
```

### Сравнение со спецификацией
- Не полностью соответствует требованиям спецификации protobuf для сравнения enum values
- Отсутствуют проверки:
  - Case-sensitive сравнение имен
  - Сравнение по принадлежности к одному enum
  - Сравнение с null/undefined значениями
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Рекомендации по исправлению:
  1. Добавить проверку case-sensitive сравнения имен
  2. Добавить проверку принадлежности к одному enum
  3. Добавить проверку сравнения с null/undefined значениями
  4. Добавить тесты для всех случаев неравенства
- Код теста:
```swift
func testEnumValueDescriptorInequality() {
    let value1 = ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
    let value2 = ProtoEnumValueDescriptor(name: "VALUE_2", number: 2)
    XCTAssertNotEqual(value1, value2)
}
```

## Отсутствующие тесты
### testEnumValueNameValidation
- Описание: Должен проверять валидацию имени enum value согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Код теста:
```swift
func testEnumValueNameValidation() {
    // Valid names
    XCTAssertTrue(ProtoEnumValueDescriptor(name: "VALUE_1", number: 1).isValid())
    XCTAssertTrue(ProtoEnumValueDescriptor(name: "VALUE1", number: 2).isValid())
    XCTAssertTrue(ProtoEnumValueDescriptor(name: "VALUE_1_2", number: 3).isValid())
    
    // Invalid names
    XCTAssertFalse(ProtoEnumValueDescriptor(name: "value-1", number: 4).isValid())
    XCTAssertFalse(ProtoEnumValueDescriptor(name: "1VALUE", number: 5).isValid())
    XCTAssertFalse(ProtoEnumValueDescriptor(name: "VALUE.1", number: 6).isValid())
}
```

### testEnumValueNumberValidation
- Описание: Должен проверять валидацию номера enum value согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Код теста:
```swift
func testEnumValueNumberValidation() {
    // Valid numbers
    XCTAssertTrue(ProtoEnumValueDescriptor(name: "VALUE_1", number: 0).isValid())
    XCTAssertTrue(ProtoEnumValueDescriptor(name: "VALUE_2", number: 1).isValid())
    XCTAssertTrue(ProtoEnumValueDescriptor(name: "VALUE_3", number: 2147483647).isValid())
    
    // Invalid numbers
    XCTAssertFalse(ProtoEnumValueDescriptor(name: "VALUE_4", number: -1).isValid())
    XCTAssertFalse(ProtoEnumValueDescriptor(name: "VALUE_5", number: 2147483648).isValid())
}
```

### testEnumValueUniqueness
- Описание: Должен проверять уникальность имен и номеров enum values в пределах enum
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Код теста:
```swift
func testEnumValueUniqueness() {
    let enumDescriptor = ProtoEnumDescriptor(
        name: "TestEnum",
        values: [
            ProtoEnumValueDescriptor(name: "VALUE_1", number: 1),
            ProtoEnumValueDescriptor(name: "VALUE_2", number: 2)
        ]
    )
    
    // Test duplicate name
    XCTAssertFalse(ProtoEnumValueDescriptor(name: "VALUE_1", number: 3).isValid())
    
    // Test duplicate number
    XCTAssertFalse(ProtoEnumValueDescriptor(name: "VALUE_3", number: 1).isValid())
} 