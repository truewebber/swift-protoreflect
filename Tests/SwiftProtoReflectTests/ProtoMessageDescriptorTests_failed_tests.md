# ProtoMessageDescriptorTests - Неуспешные тесты

## testInvalidMessageDescriptorDuplicateFieldNumbers
### Сравнение с protoc
- Не полностью проверяет все случаи дублирования номеров полей
- Не проверяет резервные номера полей (reserved field numbers)
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto#assigning_field_numbers
- Код теста:
```swift
func testInvalidMessageDescriptorDuplicateFieldNumbers() {
    // Given
    let descriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "field2", number: 1, type: .string, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Then
    XCTAssertNotNil(descriptor.validationError())
    XCTAssertTrue(descriptor.validationError()?.contains("Duplicate field number") ?? false)
}
```

### Сравнение со спецификацией
- Не проверяет все ограничения на номера полей из спецификации
- Отсутствует проверка резервных номеров полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto#assigning_field_numbers
- Рекомендации по исправлению:
  1. Добавить проверку резервных номеров полей
  2. Добавить проверку диапазонов допустимых номеров полей
  3. Добавить проверку специальных номеров полей (например, 19000-19999)

## testInvalidMessageDescriptorInvalidField
### Сравнение с protoc
- Недостаточно проверяет валидацию имен полей
- Не проверяет все ограничения на типы полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto#simple
- Код теста:
```swift
func testInvalidMessageDescriptorInvalidField() {
    // Given
    let descriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "", number: 1, type: .int32, isRepeated: false, isMap: false)
      ],
      enums: [],
      nestedMessages: []
    )

    // Then
    XCTAssertNotNil(descriptor.validationError())
    XCTAssertTrue(descriptor.validationError()?.contains("Invalid field") ?? false)
}
```

### Сравнение со спецификацией
- Не проверяет все правила именования полей
- Отсутствует проверка совместимости типов полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto#simple
- Рекомендации по исправлению:
  1. Добавить проверку правил именования полей (только ASCII буквы, цифры и подчеркивания)
  2. Добавить проверку совместимости типов полей
  3. Добавить проверку ограничений на повторяющиеся поля

## Отсутствующие тесты

### testFieldTypeCompatibility
- Должно проверяться:
  - Совместимость типов полей при наследовании сообщений
  - Корректность wire types для каждого типа поля
  - Валидация map полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto#updating
- Пример кода:
```swift
func testFieldTypeCompatibility() {
    // Given
    let baseDescriptor = ProtoMessageDescriptor(
        fullName: "BaseMessage",
        fields: [
            ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
        ],
        enums: [],
        nestedMessages: []
    )
    
    let derivedDescriptor = ProtoMessageDescriptor(
        fullName: "DerivedMessage",
        fields: [
            ProtoFieldDescriptor(name: "field1", number: 1, type: .string, isRepeated: false, isMap: false)
        ],
        enums: [],
        nestedMessages: []
    )
    
    // Then
    XCTAssertFalse(derivedDescriptor.isCompatibleWith(baseDescriptor))
}
```

### testReservedFields
- Должно проверяться:
  - Корректность объявления резервных полей
  - Валидация использования резервных номеров
  - Проверка диапазонов резервных полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto#reserved
- Пример кода:
```swift
func testReservedFields() {
    // Given
    let descriptor = ProtoMessageDescriptor(
        fullName: "TestMessage",
        fields: [
            ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
        ],
        enums: [],
        nestedMessages: [],
        reservedRanges: [(19000, 19999)]
    )
    
    // When
    let fieldWithReservedNumber = ProtoFieldDescriptor(
        name: "reservedField",
        number: 19000,
        type: .string,
        isRepeated: false,
        isMap: false
    )
    
    // Then
    XCTAssertFalse(descriptor.isValidFieldNumber(fieldWithReservedNumber.number))
}
```

### testMapFields
- Должно проверяться:
  - Валидация типов ключей и значений map полей
  - Проверка уникальности ключей
  - Корректность wire format для map полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto#maps
- Пример кода:
```swift
func testMapFields() {
    // Given
    let descriptor = ProtoMessageDescriptor(
        fullName: "TestMessage",
        fields: [
            ProtoFieldDescriptor(
                name: "mapField",
                number: 1,
                type: .map,
                isRepeated: false,
                isMap: true,
                mapKeyType: .string,
                mapValueType: .int32
            )
        ],
        enums: [],
        nestedMessages: []
    )
    
    // Then
    XCTAssertTrue(descriptor.isValid())
    XCTAssertEqual(descriptor.field(named: "mapField")?.mapKeyType, .string)
    XCTAssertEqual(descriptor.field(named: "mapField")?.mapValueType, .int32)
}
``` 