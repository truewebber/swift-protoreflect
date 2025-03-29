# ProtoEnumDescriptorTests - Неуспешные тесты

## testInvalidEnumDescriptorEmptyName
### Сравнение с protoc
- Не полностью соответствует поведению protoc
- Protoc также проверяет формат имени enum (должно начинаться с буквы и содержать только буквы, цифры и подчеркивания)
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#identifiers
- Код теста:
```swift
func testInvalidEnumDescriptorEmptyName() {
    // Given
    let descriptor = ProtoEnumDescriptor(
      name: "",
      values: [
        ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
      ]
    )

    // Then
    XCTAssertFalse(descriptor.isValid())
    XCTAssertEqual(descriptor.validationError(), "Enum name cannot be empty")
}
```

### Сравнение со спецификацией
- Не полностью соответствует спецификации protobuf
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#identifiers
- Рекомендации по исправлению:
  1. Добавить проверку формата имени enum
  2. Расширить сообщение об ошибке для указания конкретных требований к формату
  3. Добавить тесты для различных невалидных форматов имени

## testInvalidEnumDescriptorNoValues
### Сравнение с protoc
- Не полностью соответствует поведению protoc
- Protoc также проверяет наличие значения по умолчанию (0)
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Код теста:
```swift
func testInvalidEnumDescriptorNoValues() {
    // Given
    let descriptor = ProtoEnumDescriptor(name: "TestEnum", values: [])

    // Then
    XCTAssertFalse(descriptor.isValid())
    XCTAssertEqual(descriptor.validationError(), "Enum TestEnum must have at least one value")
}
```

### Сравнение со спецификацией
- Не полностью соответствует спецификации protobuf
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Рекомендации по исправлению:
  1. Добавить проверку наличия значения 0
  2. Добавить тесты для различных случаев с отсутствующим значением 0
  3. Расширить сообщение об ошибке для указания необходимости значения 0

## testInvalidEnumDescriptorDuplicateValueNumbers
### Сравнение с protoc
- Не полностью соответствует поведению protoc
- Protoc также проверяет диапазон значений enum (должны быть в пределах 32-битного целого числа)
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Код теста:
```swift
func testInvalidEnumDescriptorDuplicateValueNumbers() {
    // Given
    let descriptor = ProtoEnumDescriptor(
      name: "TestEnum",
      values: [
        ProtoEnumValueDescriptor(name: "VALUE_1", number: 1),
        ProtoEnumValueDescriptor(name: "VALUE_2", number: 1),  // Same number
      ]
    )

    // Then
    XCTAssertNotNil(descriptor.validationError())
    XCTAssertTrue(descriptor.validationError()?.contains("Duplicate value number") ?? false)
}
```

### Сравнение со спецификацией
- Не полностью соответствует спецификации protobuf
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Рекомендации по исправлению:
  1. Добавить проверку диапазона значений
  2. Добавить тесты для граничных значений
  3. Расширить сообщение об ошибке для указания допустимого диапазона

## Отсутствующие тесты

### testEnumValueFormat
- Описание: Должен проверять формат имен enum values согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#identifiers
- Пример кода:
```swift
func testEnumValueFormat() {
    // Given
    let invalidValues = [
        ProtoEnumValueDescriptor(name: "1VALUE", number: 1),  // Начинается с цифры
        ProtoEnumValueDescriptor(name: "VALUE-1", number: 2), // Содержит дефис
        ProtoEnumValueDescriptor(name: "VALUE.1", number: 3), // Содержит точку
    ]
    
    // When
    let descriptor = ProtoEnumDescriptor(name: "TestEnum", values: invalidValues)
    
    // Then
    XCTAssertFalse(descriptor.isValid())
    XCTAssertTrue(descriptor.validationError()?.contains("Invalid enum value name format") ?? false)
}
```

### testEnumValueRange
- Описание: Должен проверять диапазон значений enum
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Пример кода:
```swift
func testEnumValueRange() {
    // Given
    let invalidValues = [
        ProtoEnumValueDescriptor(name: "VALUE_1", number: Int32.max + 1),  // Превышает Int32.max
        ProtoEnumValueDescriptor(name: "VALUE_2", number: Int32.min - 1),  // Меньше Int32.min
    ]
    
    // When
    let descriptor = ProtoEnumDescriptor(name: "TestEnum", values: invalidValues)
    
    // Then
    XCTAssertFalse(descriptor.isValid())
    XCTAssertTrue(descriptor.validationError()?.contains("Enum value number out of range") ?? false)
}
```

### testDefaultEnumValue
- Описание: Должен проверять наличие значения по умолчанию (0)
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Пример кода:
```swift
func testDefaultEnumValue() {
    // Given
    let values = [
        ProtoEnumValueDescriptor(name: "VALUE_1", number: 1),
        ProtoEnumValueDescriptor(name: "VALUE_2", number: 2),
    ]
    
    // When
    let descriptor = ProtoEnumDescriptor(name: "TestEnum", values: values)
    
    // Then
    XCTAssertFalse(descriptor.isValid())
    XCTAssertTrue(descriptor.validationError()?.contains("Enum must have a value with number 0") ?? false)
} 