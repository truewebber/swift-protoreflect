# ProtoWireFormatTests - Failed Tests

## testMarshalAndUnmarshal
### Сравнение с protoc
- Тест не полностью реализован - unmarshal часть закомментирована
- Не проверяет все edge cases при маршалинге/анмаршалинге
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#message-structure
- Код теста:
```swift
func testMarshalAndUnmarshal() {
    let messageDescriptor = ProtoMessageDescriptor(
        fullName: "TestMessage",
        fields: [
            ProtoFieldDescriptor(name: "int_field", number: 1, type: .int32, isRepeated: false, isMap: false)
        ],
        enums: [],
        nestedMessages: []
    )
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(field: messageDescriptor.fields[0], value: .intValue(123))
    let data = ProtoWireFormat.marshal(message: message)
    XCTAssertNotNil(data, "Marshal should succeed")
    // Skip the unmarshal test for now as it's not fully implemented
    // Uncomment when unmarshal is fully implemented
    // let unmarshaledMessage = ProtoWireFormat.unmarshal(data: data!, messageDescriptor: messageDescriptor) as? ProtoDynamicMessage
    // XCTAssertNotNil(unmarshaledMessage, "Unmarshal should succeed")
    // let fieldValue = unmarshaledMessage?.get(field: messageDescriptor.fields[0])?.getInt()
    // XCTAssertEqual(fieldValue, 123, "Field value should be preserved")
}
```

### Сравнение со спецификацией
- Не проверяет все требования спецификации для маршалинга/анмаршалинга
- Отсутствует проверка обработки неизвестных полей
- Отсутствует проверка обработки ошибок
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#message-structure
- Рекомендации по исправлению:
  1. Реализовать unmarshal часть теста
  2. Добавить проверки для неизвестных полей
  3. Добавить проверки обработки ошибок
  4. Добавить тесты для всех типов полей

## testSimpleMessageDeserialization
### Сравнение с protoc
- Тест не проверяет результат десериализации
- Не проверяет корректность значений полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#message-structure
- Код теста:
```swift
func testSimpleMessageDeserialization() {
    let messageDescriptor = ProtoMessageDescriptor(
        fullName: "TestMessage",
        fields: [
            ProtoFieldDescriptor(name: "int_field", number: 1, type: .int32, isRepeated: false, isMap: false),
            ProtoFieldDescriptor(name: "string_field", number: 2, type: .string, isRepeated: false, isMap: false),
            ProtoFieldDescriptor(name: "bool_field", number: 3, type: .bool, isRepeated: false, isMap: false),
        ],
        enums: [],
        nestedMessages: []
    )
    let serializedData = Data([
        8, 42,  // int_field = 42
        18, 5, 104, 101, 108, 108, 111,  // string_field = "hello"
        24, 1,  // bool_field = true
    ])
    _ = ProtoWireFormat.unmarshal(data: serializedData, messageDescriptor: messageDescriptor)
}
```

### Сравнение со спецификацией
- Не соответствует требованиям спецификации по проверке десериализации
- Отсутствует валидация значений полей
- Отсутствует проверка обработки ошибок
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#message-structure
- Рекомендации по исправлению:
  1. Добавить проверку результата десериализации
  2. Добавить валидацию значений полей
  3. Добавить проверки обработки ошибок
  4. Добавить тесты для edge cases

## Отсутствующие тесты

### testUnknownFieldHandling
- Описание: Должен проверять корректную обработку неизвестных полей при десериализации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#unknown-fields
- Пример кода:
```swift
func testUnknownFieldHandling() {
    let messageDescriptor = ProtoMessageDescriptor(
        fullName: "TestMessage",
        fields: [
            ProtoFieldDescriptor(name: "int_field", number: 1, type: .int32, isRepeated: false, isMap: false)
        ],
        enums: [],
        nestedMessages: []
    )
    // Data with unknown field (field number 999)
    let serializedData = Data([250, 7, 42])  // Field 999 = 42
    let message = ProtoWireFormat.unmarshal(data: serializedData, messageDescriptor: messageDescriptor)
    XCTAssertNotNil(message)
    // Verify unknown field is preserved
    XCTAssertTrue(message.hasUnknownFields)
    XCTAssertEqual(message.unknownFields[999]?.first?.getInt(), 42)
}
```

### testMessageSizeLimits
- Описание: Должен проверять обработку ограничений размера сообщения
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#message-structure
- Пример кода:
```swift
func testMessageSizeLimits() {
    let messageDescriptor = ProtoMessageDescriptor(
        fullName: "TestMessage",
        fields: [
            ProtoFieldDescriptor(name: "string_field", number: 1, type: .string, isRepeated: false, isMap: false)
        ],
        enums: [],
        nestedMessages: []
    )
    // Create data exceeding size limit (2GB)
    let largeString = String(repeating: "x", count: Int(Int32.max) + 1)
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(field: messageDescriptor.fields[0], value: .stringValue(largeString))
    let data = ProtoWireFormat.marshal(message: message)
    XCTAssertNil(data, "Should fail when message size exceeds limit")
}
```

### testWireTypeValidation
- Описание: Должен проверять валидацию wire types для всех типов полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Пример кода:
```swift
func testWireTypeValidation() {
    let messageDescriptor = ProtoMessageDescriptor(
        fullName: "TestMessage",
        fields: [
            ProtoFieldDescriptor(name: "int_field", number: 1, type: .int32, isRepeated: false, isMap: false),
            ProtoFieldDescriptor(name: "string_field", number: 2, type: .string, isRepeated: false, isMap: false),
            ProtoFieldDescriptor(name: "fixed64_field", number: 3, type: .fixed64, isRepeated: false, isMap: false)
        ],
        enums: [],
        nestedMessages: []
    )
    // Test data with wrong wire type for int32 field (wire type 2 instead of 0)
    let data = Data([10, 1, 42])  // Field 1 with wire type 2
    let message = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
    XCTAssertNotNil(message)
    // Verify field is skipped due to wire type mismatch
    XCTAssertFalse(message.has(field: messageDescriptor.fields[0]))
}
``` 