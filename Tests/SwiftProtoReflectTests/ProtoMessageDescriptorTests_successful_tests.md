# ProtoMessageDescriptorTests - Успешные тесты

## testInitialization
### Сравнение с protoc
- Корректно проверяет базовую структуру дескриптора сообщения
- Соответствует поведению protoc при создании дескрипторов сообщений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#how-do-they-work
- Код теста:
```swift
func testInitialization() {
    // Given
    let fullName = "TestMessage"
    let fields = [ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)]
    let enums = [ProtoEnumDescriptor(name: "TestEnum", values: [ProtoEnumValueDescriptor(name: "VALUE1", number: 1)])]
    let nestedMessages = [ProtoMessageDescriptor(fullName: "NestedMessage", fields: [], enums: [], nestedMessages: [])]

    // When
    let descriptor = ProtoMessageDescriptor(
      fullName: fullName,
      fields: fields,
      enums: enums,
      nestedMessages: nestedMessages
    )

    // Then
    XCTAssertEqual(descriptor.fullName, fullName)
    XCTAssertEqual(descriptor.fields.count, 1)
    XCTAssertEqual(descriptor.enums.count, 1)
    XCTAssertEqual(descriptor.nestedMessages.count, 1)
}
```

### Сравнение со спецификацией
- Корректно реализует базовую структуру дескриптора сообщения согласно спецификации
- Правильно обрабатывает вложенные сообщения и перечисления
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#how-do-they-work

## testFieldAccessByName
### Сравнение с protoc
- Корректно реализует доступ к полям по имени
- Соответствует поведению protoc при обращении к полям сообщения
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#how-do-they-work
- Код теста:
```swift
func testFieldAccessByName() {
    // Given
    let field = ProtoFieldDescriptor(name: "testField", number: 1, type: .int32, isRepeated: false, isMap: false)
    let descriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [field],
      enums: [],
      nestedMessages: []
    )

    // When
    let retrievedField = descriptor.field(named: "testField")

    // Then
    XCTAssertNotNil(retrievedField)
    XCTAssertEqual(retrievedField?.name, "testField")
    XCTAssertEqual(retrievedField?.number, 1)
}
```

### Сравнение со спецификацией
- Правильно реализует доступ к полям по имени согласно спецификации
- Корректно обрабатывает существующие поля
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#how-do-they-work

## testValidMessageDescriptor
### Сравнение с protoc
- Корректно проверяет валидность дескриптора сообщения
- Соответствует поведению protoc при валидации сообщений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#how-do-they-work
- Код теста:
```swift
func testValidMessageDescriptor() {
    // Given
    let descriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
      ],
      enums: [],
      nestedMessages: []
    )

    // Then
    XCTAssertTrue(descriptor.isValid())
    XCTAssertNil(descriptor.validationError())
}
```

### Сравнение со спецификацией
- Правильно реализует базовую валидацию дескриптора сообщения
- Корректно проверяет обязательные поля и структуру
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#how-do-they-work 