# ProtoEnumDescriptorTests - Успешные тесты

## testInitialization
### Сравнение с protoc
- Корректно проверяет базовую инициализацию enum descriptor
- Соответствует поведению protoc при создании enum definitions
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Код теста:
```swift
func testInitialization() {
    // Given
    let name = "TestEnum"
    let values = [
      ProtoEnumValueDescriptor(name: "VALUE_1", number: 1),
      ProtoEnumValueDescriptor(name: "VALUE_2", number: 2),
    ]

    // When
    let descriptor = ProtoEnumDescriptor(name: name, values: values)

    // Then
    XCTAssertEqual(descriptor.name, name)
    XCTAssertEqual(descriptor.values.count, 2)
    XCTAssertEqual(descriptor.values[0].name, "VALUE_1")
    XCTAssertEqual(descriptor.values[1].number, 2)
}
```

### Сравнение со спецификацией
- Корректно реализует базовую структуру enum согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Проверяет основные атрибуты enum: name и values

## testGetEnumValueByName
### Сравнение с protoc
- Корректно реализует поиск enum values по имени
- Соответствует поведению protoc при обращении к enum values
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Код теста:
```swift
func testGetEnumValueByName() {
    // Given
    let value = ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
    let descriptor = ProtoEnumDescriptor(name: "TestEnum", values: [value])

    // When
    let retrievedValue = descriptor.value(named: "VALUE_1")

    // Then
    XCTAssertNotNil(retrievedValue)
    XCTAssertEqual(retrievedValue?.number, 1)
}
```

### Сравнение со спецификацией
- Корректно реализует доступ к enum values по имени
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Проверяет корректность доступа к enum values

## testValueByNumber
### Сравнение с protoc
- Корректно реализует поиск enum values по номеру
- Соответствует поведению protoc при обращении к enum values по номеру
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Код теста:
```swift
func testValueByNumber() {
    // Given
    let descriptor = ProtoEnumDescriptor(
      name: "TestEnum",
      values: [
        ProtoEnumValueDescriptor(name: "VALUE1", number: 1),
        ProtoEnumValueDescriptor(name: "VALUE2", number: 2),
      ]
    )

    // When
    let retrievedValue = descriptor.value(withNumber: 1)

    // Then
    XCTAssertNotNil(retrievedValue)
    XCTAssertEqual(retrievedValue?.name, "VALUE1")
    XCTAssertEqual(retrievedValue?.number, 1)
}
```

### Сравнение со спецификацией
- Корректно реализует доступ к enum values по номеру
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Проверяет корректность доступа к enum values по номеру

## testValidEnumDescriptor
### Сравнение с protoc
- Корректно проверяет валидность enum descriptor
- Соответствует поведению protoc при валидации enum definitions
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Код теста:
```swift
func testValidEnumDescriptor() {
    // Given
    let value = ProtoEnumValueDescriptor(name: "VALUE_1", number: 1)
    let descriptor = ProtoEnumDescriptor(name: "TestEnum", values: [value])

    // Then
    XCTAssertTrue(descriptor.isValid())
    XCTAssertNil(descriptor.validationError())
}
```

### Сравнение со спецификацией
- Корректно реализует базовую валидацию enum согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Проверяет основные требования к enum: наличие имени и значений

## testNegativeEnumValues
### Сравнение с protoc
- Корректно поддерживает отрицательные значения в enum
- Соответствует поведению protoc при использовании отрицательных enum values
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Код теста:
```swift
func testNegativeEnumValues() {
    // Given
    let descriptor = ProtoEnumDescriptor(
      name: "SignedEnum",
      values: [
        ProtoEnumValueDescriptor(name: "NEGATIVE", number: -1),
        ProtoEnumValueDescriptor(name: "ZERO", number: 0),
        ProtoEnumValueDescriptor(name: "POSITIVE", number: 1),
      ]
    )

    // Then
    XCTAssertTrue(descriptor.isValid())
    XCTAssertEqual(descriptor.value(withNumber: -1)?.name, "NEGATIVE")
    XCTAssertEqual(descriptor.value(withNumber: 0)?.name, "ZERO")
    XCTAssertEqual(descriptor.value(withNumber: 1)?.name, "POSITIVE")
}
```

### Сравнение со спецификацией
- Корректно реализует поддержку отрицательных значений в enum
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Проверяет корректность работы с отрицательными значениями 