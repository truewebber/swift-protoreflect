# ProtoReflectionUtilsTests - Неуспешные тесты

## testValidateInvalidFieldDescriptor
### Сравнение с protoc
- Тест проверяет только базовые случаи невалидности (пустое имя и отрицательный номер)
- Не проверяет все edge cases, которые проверяет protoc
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#fields
- Код теста, который проверяет это поведение:
```swift
func testValidateInvalidFieldDescriptor() {
    let invalidFieldDescriptor = ProtoFieldDescriptor(
        name: "",
        number: -1,
        type: .int32,
        isRepeated: false,
        isMap: false
    )
    XCTAssertFalse(ProtoReflectionUtils.validateFieldDescriptor(invalidFieldDescriptor))
}
```

### Сравнение со спецификацией
- Тест не проверяет все случаи невалидности, описанные в спецификации:
  - Максимальный номер поля (536870911)
  - Зарезервированные номера полей
  - Некорректные комбинации флагов (например, isRepeated=true и isMap=true)
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#fields
- Рекомендации по исправлению:
  1. Добавить проверку максимального номера поля
  2. Добавить проверку зарезервированных номеров
  3. Добавить проверку несовместимых комбинаций флагов
  4. Добавить проверку валидности имени поля (только ASCII буквы, цифры и подчеркивания)

## Отсутствующие тесты

### testFieldNumberValidation
- Описание: Должен проверять все ограничения на номера полей согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#fields
- Пример кода теста:
```swift
func testFieldNumberValidation() {
    // Проверка максимального номера поля
    let maxFieldNumber = ProtoFieldDescriptor(
        name: "max_field",
        number: 536870911, // 2^29 - 1
        type: .int32,
        isRepeated: false,
        isMap: false
    )
    XCTAssertTrue(ProtoReflectionUtils.validateFieldDescriptor(maxFieldNumber))
    
    // Проверка превышения максимального номера
    let tooLargeFieldNumber = ProtoFieldDescriptor(
        name: "too_large",
        number: 536870912,
        type: .int32,
        isRepeated: false,
        isMap: false
    )
    XCTAssertFalse(ProtoReflectionUtils.validateFieldDescriptor(tooLargeFieldNumber))
    
    // Проверка зарезервированных номеров
    let reservedFieldNumber = ProtoFieldDescriptor(
        name: "reserved",
        number: 19000, // Зарезервированный диапазон
        type: .int32,
        isRepeated: false,
        isMap: false
    )
    XCTAssertFalse(ProtoReflectionUtils.validateFieldDescriptor(reservedFieldNumber))
}
```

### testFieldNameValidation
- Описание: Должен проверять правила именования полей согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#fields
- Пример кода теста:
```swift
func testFieldNameValidation() {
    // Проверка валидных имен
    let validNames = [
        "field_name",
        "fieldName",
        "field1",
        "field_1"
    ]
    
    for name in validNames {
        let descriptor = ProtoFieldDescriptor(
            name: name,
            number: 1,
            type: .int32,
            isRepeated: false,
            isMap: false
        )
        XCTAssertTrue(ProtoReflectionUtils.validateFieldDescriptor(descriptor))
    }
    
    // Проверка невалидных имен
    let invalidNames = [
        "1field", // Начинается с цифры
        "field-name", // Содержит дефис
        "field.name", // Содержит точку
        "field name", // Содержит пробел
        "field@name" // Содержит специальный символ
    ]
    
    for name in invalidNames {
        let descriptor = ProtoFieldDescriptor(
            name: name,
            number: 1,
            type: .int32,
            isRepeated: false,
            isMap: false
        )
        XCTAssertFalse(ProtoReflectionUtils.validateFieldDescriptor(descriptor))
    }
}
```

### testFieldFlagsValidation
- Описание: Должен проверять корректность комбинаций флагов полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#fields
- Пример кода теста:
```swift
func testFieldFlagsValidation() {
    // Проверка несовместимых комбинаций флагов
    let repeatedMapField = ProtoFieldDescriptor(
        name: "repeated_map",
        number: 1,
        type: .message,
        isRepeated: true,
        isMap: true
    )
    XCTAssertFalse(ProtoReflectionUtils.validateFieldDescriptor(repeatedMapField))
    
    // Проверка валидных комбинаций
    let validCombinations = [
        (isRepeated: false, isMap: false),
        (isRepeated: true, isMap: false),
        (isRepeated: false, isMap: true)
    ]
    
    for (isRepeated, isMap) in validCombinations {
        let descriptor = ProtoFieldDescriptor(
            name: "valid_field",
            number: 1,
            type: .int32,
            isRepeated: isRepeated,
            isMap: isMap
        )
        XCTAssertTrue(ProtoReflectionUtils.validateFieldDescriptor(descriptor))
    }
}
```

### testMessageDescriptionCompleteness
- Описание: Должен проверять полноту описания сообщения, включая все его компоненты
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#message
- Пример кода теста:
```swift
func testMessageDescriptionCompleteness() {
    let fields = [
        ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "field2", number: 2, type: .string, isRepeated: true, isMap: false)
    ]
    
    let enums = [
        ProtoEnumDescriptor(name: "TestEnum", values: [
            ProtoEnumValueDescriptor(name: "VALUE1", number: 1),
            ProtoEnumValueDescriptor(name: "VALUE2", number: 2)
        ])
    ]
    
    let nestedMessages = [
        ProtoMessageDescriptor(
            fullName: "NestedMessage",
            fields: [],
            enums: [],
            nestedMessages: []
        )
    ]
    
    let descriptor = ProtoMessageDescriptor(
        fullName: "TestMessage",
        fields: fields,
        enums: enums,
        nestedMessages: nestedMessages
    )
    
    let message = ProtoDynamicMessage(descriptor: descriptor)
    let description = ProtoReflectionUtils.describeMessage(message)
    
    // Проверяем наличие всех компонентов в описании
    XCTAssertTrue(description.contains("field1"))
    XCTAssertTrue(description.contains("field2"))
    XCTAssertTrue(description.contains("TestEnum"))
    XCTAssertTrue(description.contains("NestedMessage"))
}
``` 