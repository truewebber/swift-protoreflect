# ProtoDynamicMessageTests - Неуспешные тесты

## testValidation
### Сравнение с protoc
- Не полностью соответствует поведению protoc для валидации типов
- Protoc допускает некоторые неявные преобразования типов, которые наш код отвергает
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#type-conversion
- Код теста:
```swift
func testValidation() {
    // Valid field values
    XCTAssertTrue(message.set(fieldName: "intField", value: .intValue(100)))
    XCTAssertTrue(message.set(fieldName: "stringField", value: .stringValue("hello")))

    // With our stricter validation, type conversions are no longer allowed
    // This test now expects the conversion to fail
    XCTAssertFalse(message.set(fieldName: "stringField", value: .intValue(100)))

    // Invalid field values
    // String that can't be converted to Int
    XCTAssertFalse(message.set(fieldName: "intField", value: .stringValue("not a number")))

    // Non-existent field
    XCTAssertFalse(message.set(fieldName: "nonExistentField", value: .intValue(100)))
}
```

### Сравнение со спецификацией
- Текущая реализация слишком строгая в отношении преобразования типов
- Не соответствует спецификации в части неявных преобразований
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#type-conversion
- Рекомендации по исправлению:
  1. Добавить поддержку неявных преобразований типов согласно спецификации
  2. Реализовать корректную валидацию числовых значений
  3. Добавить поддержку преобразования строк в числа, где это допустимо

## testMessageValidation
### Сравнение с protoc
- Не полностью соответствует поведению protoc для валидации сообщений
- Отсутствует проверка required fields
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto#required
- Код теста:
```swift
func testMessageValidation() {
    let person = ProtoDynamicMessage(descriptor: personDescriptor)

    // Set required fields
    person.set(fieldName: "name", value: .stringValue("John Doe"))
    person.set(fieldName: "age", value: .intValue(30))

    // Create and set a valid address
    let address = ProtoDynamicMessage(descriptor: addressDescriptor)
    address.set(fieldName: "street", value: .stringValue("123 Main St"))
    address.set(fieldName: "city", value: .stringValue("Anytown"))

    person.setNestedMessage(fieldName: "address", message: address)

    // Validate the message
    XCTAssertTrue(person.isValid())
}
```

### Сравнение со спецификацией
- Отсутствует поддержка required fields
- Не проверяет обязательные поля при валидации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto#required
- Рекомендации по исправлению:
  1. Добавить поддержку required fields в ProtoFieldDescriptor
  2. Реализовать проверку обязательных полей в isValid()
  3. Добавить тесты для различных комбинаций required/optional полей

## Отсутствующие тесты

### testWireFormatValidation
- Должен проверять корректность wire format для всех типов полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Пример кода:
```swift
func testWireFormatValidation() {
    let message = ProtoDynamicMessage(descriptor: descriptor)
    
    // Test varint wire format
    XCTAssertTrue(message.set(fieldName: "intField", value: .intValue(0)))
    XCTAssertTrue(message.set(fieldName: "intField", value: .intValue(1)))
    XCTAssertTrue(message.set(fieldName: "intField", value: .intValue(-1)))
    
    // Test 64-bit wire format
    XCTAssertTrue(message.set(fieldName: "doubleField", value: .doubleValue(0.0)))
    XCTAssertTrue(message.set(fieldName: "doubleField", value: .doubleValue(1.0)))
    
    // Test length-delimited wire format
    XCTAssertTrue(message.set(fieldName: "stringField", value: .stringValue("")))
    XCTAssertTrue(message.set(fieldName: "stringField", value: .stringValue("test")))
    
    // Test 32-bit wire format
    XCTAssertTrue(message.set(fieldName: "floatField", value: .floatValue(0.0)))
    XCTAssertTrue(message.set(fieldName: "floatField", value: .floatValue(1.0)))
}
```

### testDefaultValues
- Должен проверять корректность значений по умолчанию для всех типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto#default
- Пример кода:
```swift
func testDefaultValues() {
    let message = ProtoDynamicMessage(descriptor: descriptor)
    
    // Test default values for numeric types
    XCTAssertEqual(message.get(fieldName: "intField")?.getInt(), 0)
    XCTAssertEqual(message.get(fieldName: "doubleField")?.getDouble(), 0.0)
    XCTAssertEqual(message.get(fieldName: "floatField")?.getFloat(), 0.0)
    
    // Test default values for bool
    XCTAssertEqual(message.get(fieldName: "boolField")?.getBool(), false)
    
    // Test default values for string
    XCTAssertEqual(message.get(fieldName: "stringField")?.getString(), "")
    
    // Test default values for repeated fields
    XCTAssertEqual(message.count(ofRepeatedFieldNamed: "repeatedIntField"), 0)
    
    // Test default values for map fields
    XCTAssertEqual(message.count(ofMapFieldNamed: "mapField"), 0)
}
```

### testOneofFields
- Должен проверять корректность работы с oneof полями
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto#oneof
- Пример кода:
```swift
func testOneofFields() {
    let oneofDescriptor = ProtoMessageDescriptor(
        fullName: "OneofMessage",
        fields: [
            ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false),
            ProtoFieldDescriptor(name: "age", number: 2, type: .int32, isRepeated: false, isMap: false),
        ],
        enums: [],
        nestedMessages: [],
        oneofs: [
            ProtoOneofDescriptor(
                name: "info",
                fields: ["name", "age"]
            )
        ]
    )
    
    let message = ProtoDynamicMessage(descriptor: oneofDescriptor)
    
    // Test setting first field
    XCTAssertTrue(message.set(fieldName: "name", value: .stringValue("John")))
    XCTAssertNil(message.get(fieldName: "age"))
    
    // Test setting second field (should clear first)
    XCTAssertTrue(message.set(fieldName: "age", value: .intValue(30)))
    XCTAssertNil(message.get(fieldName: "name"))
    XCTAssertEqual(message.get(fieldName: "age")?.getInt(), 30)
}
```

### testEnumValidation
- Должен проверять корректность работы с enum полями
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto#enum
- Пример кода:
```swift
func testEnumValidation() {
    let enumDescriptor = ProtoEnumDescriptor(
        name: "TestEnum",
        values: [
            ProtoEnumValueDescriptor(name: "UNKNOWN", number: 0),
            ProtoEnumValueDescriptor(name: "TEST", number: 1),
        ]
    )
    
    let messageDescriptor = ProtoMessageDescriptor(
        fullName: "EnumMessage",
        fields: [
            ProtoFieldDescriptor(
                name: "enumField",
                number: 1,
                type: .enum(enumDescriptor),
                isRepeated: false,
                isMap: false
            ),
        ],
        enums: [enumDescriptor],
        nestedMessages: []
    )
    
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    
    // Test valid enum values
    XCTAssertTrue(message.set(fieldName: "enumField", value: .enumValue(0)))
    XCTAssertTrue(message.set(fieldName: "enumField", value: .enumValue(1)))
    
    // Test invalid enum values
    XCTAssertFalse(message.set(fieldName: "enumField", value: .enumValue(2)))
    XCTAssertFalse(message.set(fieldName: "enumField", value: .intValue(1)))
}
``` 