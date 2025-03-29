# SwiftProtobufIntegrationTests - Успешные тесты

## testSwiftProtobufWireFormatCompatibility
### Сравнение с protoc
- Тест корректно проверяет wire format для базовых типов данных (int32, string, bool)
- Правильно реализована структура wire format согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Тест проверяет корректность тегов полей и их значений
- Код теста:
```swift
func testSwiftProtobufWireFormatCompatibility() {
    // ... existing code ...
    // Проверка тегов и значений полей
    XCTAssertEqual(bytes[0], 8)  // tag для int32
    XCTAssertEqual(bytes[1], 42)  // value
    XCTAssertEqual(bytes[2], 18)  // tag для string
    XCTAssertEqual(bytes[lastIndex], 24)  // tag для bool
    XCTAssertEqual(bytes[lastIndex + 1], 1)  // value (true)
}
```

### Сравнение со спецификацией
- Тест корректно реализует базовые типы данных согласно спецификации
- Правильно обрабатываются wire types для разных типов полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields
- Код теста:
```swift
func testSwiftProtobufWireFormatCompatibility() {
    // ... existing code ...
    let messageDescriptor = ProtoMessageDescriptor(
        fullName: "TestMessage",
        fields: [
            ProtoFieldDescriptor(name: "int32_field", number: 1, type: .int32, isRepeated: false, isMap: false),
            ProtoFieldDescriptor(name: "string_field", number: 2, type: .string, isRepeated: false, isMap: false),
            ProtoFieldDescriptor(name: "bool_field", number: 3, type: .bool, isRepeated: false, isMap: false),
        ],
        enums: [],
        nestedMessages: []
    )
}
```

## testSwiftProtobufConversion
### Сравнение с protoc
- Тест корректно проверяет сериализацию и десериализацию сообщений
- Правильно обрабатываются значения разных типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#message-structure
- Код теста:
```swift
func testSwiftProtobufConversion() {
    // ... existing code ...
    // Проверка сохранения значений после сериализации/десериализации
    XCTAssertEqual(deserializedMessage.get(fieldName: "int32_field")?.getInt(), 42)
    XCTAssertEqual(deserializedMessage.get(fieldName: "string_field")?.getString(), "Hello, SwiftProtobuf!")
    XCTAssertEqual(deserializedMessage.get(fieldName: "bool_field")?.getBool(), true)
}
```

### Сравнение со спецификацией
- Тест корректно реализует базовую функциональность protobuf
- Правильно обрабатываются типы данных и их значения
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#message-structure
- Код теста:
```swift
func testSwiftProtobufConversion() {
    // ... existing code ...
    let dynamicMessage = ProtoDynamicMessage(descriptor: messageDescriptor)
    dynamicMessage.set(fieldName: "int32_field", value: .intValue(42))
    dynamicMessage.set(fieldName: "string_field", value: .stringValue("Hello, SwiftProtobuf!"))
    dynamicMessage.set(fieldName: "bool_field", value: .boolValue(true))
}
``` 