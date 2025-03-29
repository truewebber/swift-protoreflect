# ProtoFieldDescriptorTests - Неуспешные тесты

## testInvalidFieldDescriptorEmptyName
### Сравнение с protoc
- Не полностью соответствует поведению protoc
- Protoc также проверяет допустимые символы в имени поля
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#identifiers
- Код теста:
```swift
func testInvalidFieldDescriptorEmptyName() {
    // Given
    let invalidField = ProtoFieldDescriptor(name: "", number: 1, type: .int32, isRepeated: false, isMap: false)

    // Then
    XCTAssertFalse(invalidField.isValid())
    XCTAssertEqual(invalidField.validationError(), "Field name cannot be empty")
}
```

### Сравнение со спецификацией
- Не проверяет все правила именования полей из спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#identifiers
- Рекомендации по исправлению:
  1. Добавить проверку допустимых символов
  2. Добавить проверку длины имени
  3. Добавить проверку зарезервированных слов

## testInvalidFieldDescriptorNegativeNumber
### Сравнение с protoc
- Не полностью соответствует поведению protoc
- Protoc также проверяет диапазон допустимых номеров полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#assigning_field_numbers
- Код теста:
```swift
func testInvalidFieldDescriptorNegativeNumber() {
    // Given
    let invalidField = ProtoFieldDescriptor(name: "field", number: -1, type: .int32, isRepeated: false, isMap: false)

    // Then
    XCTAssertFalse(invalidField.isValid())
    XCTAssertEqual(invalidField.validationError(), "Field number must be positive (got -1)")
}
```

### Сравнение со спецификацией
- Не проверяет максимальное значение номера поля
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#assigning_field_numbers
- Рекомендации по исправлению:
  1. Добавить проверку максимального значения (19000-19999 зарезервированы)
  2. Добавить проверку диапазона 1-536870911

## testInvalidFieldDescriptorMissingMessageType
### Сравнение с protoc
- Не полностью соответствует поведению protoc
- Protoc также проверяет циклические зависимости в типах сообщений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#nested
- Код теста:
```swift
func testInvalidFieldDescriptorMissingMessageType() {
    // Given
    let invalidField = ProtoFieldDescriptor(
      name: "message_field",
      number: 1,
      type: .message(nil),
      isRepeated: false,
      isMap: false
    )

    // Then
    XCTAssertFalse(invalidField.isValid())
    XCTAssertEqual(
      invalidField.validationError(),
      "Message type field 'message_field' requires a messageType descriptor"
    )
}
```

### Сравнение со спецификацией
- Не проверяет корректность типов вложенных сообщений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#nested
- Рекомендации по исправлению:
  1. Добавить проверку циклических зависимостей
  2. Добавить проверку корректности типов вложенных сообщений
  3. Добавить проверку доступности типов сообщений

## Отсутствующие тесты

### testFieldNumberUniqueness
- Описание: Должен проверять уникальность номеров полей в рамках одного сообщения
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#assigning_field_numbers
- Пример кода:
```swift
func testFieldNumberUniqueness() {
    // Given
    let field1 = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
    let field2 = ProtoFieldDescriptor(name: "field2", number: 1, type: .string, isRepeated: false, isMap: false)
    
    // When
    let message = ProtoMessageDescriptor(fullName: "TestMessage", fields: [field1, field2], enums: [], nestedMessages: [])
    
    // Then
    XCTAssertFalse(message.isValid())
    XCTAssertEqual(message.validationError(), "Duplicate field number: 1")
}
```

### testReservedFieldNumbers
- Описание: Должен проверять, что номера полей не попадают в зарезервированные диапазоны
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#assigning_field_numbers
- Пример кода:
```swift
func testReservedFieldNumbers() {
    // Given
    let reservedField = ProtoFieldDescriptor(name: "reserved_field", number: 19000, type: .int32, isRepeated: false, isMap: false)
    
    // Then
    XCTAssertFalse(reservedField.isValid())
    XCTAssertEqual(reservedField.validationError(), "Field number 19000 is in reserved range 19000-19999")
}
```

### testFieldTypeCompatibility
- Описание: Должен проверять совместимость типов полей при обновлении
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#updating
- Пример кода:
```swift
func testFieldTypeCompatibility() {
    // Given
    let originalField = ProtoFieldDescriptor(name: "field", number: 1, type: .int32, isRepeated: false, isMap: false)
    let updatedField = ProtoFieldDescriptor(name: "field", number: 1, type: .string, isRepeated: false, isMap: false)
    
    // Then
    XCTAssertFalse(originalField.isCompatibleWith(updatedField))
    XCTAssertEqual(originalField.compatibilityError(updatedField), "Incompatible field types: int32 vs string")
}
``` 