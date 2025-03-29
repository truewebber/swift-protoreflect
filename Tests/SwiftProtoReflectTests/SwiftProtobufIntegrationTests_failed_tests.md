# SwiftProtobufIntegrationTests - Неуспешные тесты

## testUnknownFieldHandling
### Сравнение с protoc
- Тест не соответствует поведению protoc в части сохранения неизвестных полей
- Protoc сохраняет неизвестные поля при десериализации, наш код их теряет
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#unknown-fields
- Пример поведения protoc:
```protobuf
// proto file
message OriginalMessage {
  string known_field = 1;
}

message ExtendedMessage {
  string known_field = 1;
  int32 new_field = 2;
}
```
```bash
# Команда для воспроизведения поведения protoc
protoc --encode=ExtendedMessage --decode=OriginalMessage test.proto < extended_message.bin
```
- Код теста:
```swift
func testUnknownFieldHandling() {
    // ... existing code ...
    // Неизвестное поле теряется при десериализации
    XCTAssertNil(deserializedWithExtended.get(fieldName: "new_field"))
}
```

### Сравнение со спецификацией
- Тест не соответствует спецификации в части обработки неизвестных полей
- Спецификация требует сохранения неизвестных полей при десериализации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#unknown-fields
- Рекомендации по исправлению:
  1. Добавить поддержку unknown fields в ProtoDynamicMessage
  2. Реализовать сохранение неизвестных полей при десериализации
  3. Добавить возможность доступа к unknown fields через специальный API
- Код теста:
```swift
func testUnknownFieldHandling() {
    // ... existing code ...
    // Текущая реализация теряет неизвестные поля
    guard let reserializedData = ProtoWireFormat.marshal(message: deserializedWithOriginal) else {
        XCTFail("Failed to re-marshal message with unknown field")
        return
    }
}
```

## Отсутствующие тесты

### testRepeatedFields
- Описание: Отсутствует проверка корректной обработки repeated полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#repeated
- Пример кода теста:
```swift
func testRepeatedFields() {
    let messageDescriptor = ProtoMessageDescriptor(
        fullName: "RepeatedMessage",
        fields: [
            ProtoFieldDescriptor(name: "repeated_int32", number: 1, type: .int32, isRepeated: true, isMap: false)
        ],
        enums: [],
        nestedMessages: []
    )
    
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(fieldName: "repeated_int32", value: .repeatedIntValue([1, 2, 3]))
    
    guard let data = ProtoWireFormat.marshal(message: message) else {
        XCTFail("Failed to marshal repeated fields")
        return
    }
    
    guard let deserialized = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor) as? ProtoDynamicMessage else {
        XCTFail("Failed to unmarshal repeated fields")
        return
    }
    
    XCTAssertEqual(deserialized.get(fieldName: "repeated_int32")?.getRepeatedInt(), [1, 2, 3])
}
```

### testMapFields
- Описание: Отсутствует проверка корректной обработки map полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#maps
- Пример кода теста:
```swift
func testMapFields() {
    let messageDescriptor = ProtoMessageDescriptor(
        fullName: "MapMessage",
        fields: [
            ProtoFieldDescriptor(name: "map_string_int32", number: 1, type: .int32, isRepeated: false, isMap: true)
        ],
        enums: [],
        nestedMessages: []
    )
    
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    let mapValue = ["key1": 1, "key2": 2]
    message.set(fieldName: "map_string_int32", value: .mapValue(mapValue))
    
    guard let data = ProtoWireFormat.marshal(message: message) else {
        XCTFail("Failed to marshal map fields")
        return
    }
    
    guard let deserialized = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor) as? ProtoDynamicMessage else {
        XCTFail("Failed to unmarshal map fields")
        return
    }
    
    XCTAssertEqual(deserialized.get(fieldName: "map_string_int32")?.getMap(), mapValue)
}
```

### testNestedMessages
- Описание: Отсутствует проверка корректной обработки вложенных сообщений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#embedded
- Пример кода теста:
```swift
func testNestedMessages() {
    let nestedDescriptor = ProtoMessageDescriptor(
        fullName: "NestedMessage",
        fields: [
            ProtoFieldDescriptor(name: "nested_field", number: 1, type: .message, isRepeated: false, isMap: false)
        ],
        enums: [],
        nestedMessages: []
    )
    
    let parentDescriptor = ProtoMessageDescriptor(
        fullName: "ParentMessage",
        fields: [
            ProtoFieldDescriptor(name: "nested", number: 1, type: .message, isRepeated: false, isMap: false)
        ],
        enums: [],
        nestedMessages: [nestedDescriptor]
    )
    
    let nestedMessage = ProtoDynamicMessage(descriptor: nestedDescriptor)
    nestedMessage.set(fieldName: "nested_field", value: .stringValue("nested value"))
    
    let parentMessage = ProtoDynamicMessage(descriptor: parentDescriptor)
    parentMessage.set(fieldName: "nested", value: .messageValue(nestedMessage))
    
    guard let data = ProtoWireFormat.marshal(message: parentMessage) else {
        XCTFail("Failed to marshal nested message")
        return
    }
    
    guard let deserialized = ProtoWireFormat.unmarshal(data: data, messageDescriptor: parentDescriptor) as? ProtoDynamicMessage else {
        XCTFail("Failed to unmarshal nested message")
        return
    }
    
    XCTAssertEqual(deserialized.get(fieldName: "nested")?.getMessage()?.get(fieldName: "nested_field")?.getString(), "nested value")
}
``` 