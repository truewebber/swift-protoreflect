# ProtoFieldDescriptorTests - Успешные тесты

## testInitialization
### Сравнение с protoc
- Корректно проверяет базовую инициализацию поля с минимальным набором параметров
- Соответствует поведению protoc при создании поля в .proto файле
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#simple
- Код теста:
```swift
func testInitialization() {
    // Given
    let name = "test_field"
    let number = 1
    let type = ProtoFieldType.int32
    let isRepeated = false
    let isMap = false

    // When
    let field = ProtoFieldDescriptor(name: name, number: number, type: type, isRepeated: isRepeated, isMap: isMap)

    // Then
    XCTAssertEqual(field.name, name)
    XCTAssertEqual(field.number, number)
    XCTAssertEqual(field.type, type)
    XCTAssertEqual(field.isRepeated, isRepeated)
    XCTAssertEqual(field.isMap, isMap)
    XCTAssertNil(field.defaultValue)
    XCTAssertNil(field.messageType)
}
```

### Сравнение со спецификацией
- Корректно реализует базовую структуру поля согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#fields
- Проверяет все обязательные поля: name, number, type
- Корректно инициализирует опциональные поля как nil

## testInitializationWithDefaultValue
### Сравнение с protoc
- Корректно проверяет установку значения по умолчанию
- Соответствует поведению protoc при определении default value в .proto файле
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#default
- Код теста:
```swift
func testInitializationWithDefaultValue() {
    // Given
    let defaultValue = ProtoValue.intValue(42)

    // When
    let field = ProtoFieldDescriptor(
      name: "field",
      number: 1,
      type: .int32,
      isRepeated: false,
      isMap: false,
      defaultValue: defaultValue
    )

    // Then
    XCTAssertEqual(field.defaultValue?.getInt(), 42)
}
```

### Сравнение со спецификацией
- Корректно реализует механизм default values согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#default
- Проверяет корректное хранение и получение значения по умолчанию

## testFieldDescriptorEquality
### Сравнение с protoc
- Корректно проверяет равенство полей на основе их характеристик
- Соответствует поведению protoc при сравнении полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#updating
- Код теста:
```swift
func testFieldDescriptorEquality() {
    // Given
    let field1 = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
    let field2 = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
    let field3 = ProtoFieldDescriptor(name: "field2", number: 1, type: .int32, isRepeated: false, isMap: false)
    let field4 = ProtoFieldDescriptor(name: "field1", number: 2, type: .int32, isRepeated: false, isMap: false)
    let field5 = ProtoFieldDescriptor(name: "field1", number: 1, type: .string, isRepeated: false, isMap: false)

    // Then
    XCTAssertEqual(field1, field2)
    XCTAssertNotEqual(field1, field3)
    XCTAssertNotEqual(field1, field4)
    XCTAssertNotEqual(field1, field5)
}
```

### Сравнение со спецификацией
- Корректно реализует правила сравнения полей согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#updating
- Проверяет все важные атрибуты поля при сравнении

## testValidFieldDescriptor
### Сравнение с protoc
- Корректно проверяет валидность корректного поля
- Соответствует поведению protoc при валидации полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#fields
- Код теста:
```swift
func testValidFieldDescriptor() {
    // Given
    let validField = ProtoFieldDescriptor(name: "valid_field", number: 1, type: .int32, isRepeated: false, isMap: false)

    // Then
    XCTAssertTrue(validField.isValid())
    XCTAssertNil(validField.validationError())
}
```

### Сравнение со спецификацией
- Корректно реализует правила валидации полей согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#fields
- Проверяет отсутствие ошибок валидации для корректного поля 