# MapFieldTests - Успешные тесты

## testMapFieldEncoding
### Сравнение с protoc
- Корректно реализует кодирование map-полей в формате wire format
- Правильно обрабатывает map-поля как повторяющиеся сообщения
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#maps
- Пример поведения protoc:
```protobuf
message TestMessage {
  map<string, int32> test_map = 1;
}
```
- Код теста, который проверяет это поведение:
```swift
func testMapFieldEncoding() {
    // Создание дескрипторов для map entry
    let keyFieldDescriptor = ProtoFieldDescriptor(
      name: "key",
      number: 1,
      type: .string,
      isRepeated: false,
      isMap: false
    )

    let valueFieldDescriptor = ProtoFieldDescriptor(
      name: "value",
      number: 2,
      type: .int32,
      isRepeated: false,
      isMap: false
    )

    // Создание дескриптора для map entry
    let entryDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage.TestMapEntry",
      fields: [keyFieldDescriptor, valueFieldDescriptor],
      enums: [],
      nestedMessages: []
    )

    // Создание дескриптора для map поля
    let mapFieldDescriptor = ProtoFieldDescriptor(
      name: "test_map",
      number: 1,
      type: .message(entryDescriptor),
      isRepeated: true,  // Map поля кодируются как повторяющиеся сообщения
      isMap: true,
      messageType: entryDescriptor
    )

    // ... остальной код теста ...
}
```

### Сравнение со спецификацией
- Корректно реализует структуру map-полей согласно спецификации
- Правильно обрабатывает вложенные сообщения для map entries
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Код теста, который проверяет это поведение:
```swift
// Создание динамического сообщения с map полем
let message = ProtoDynamicMessage(descriptor: messageDescriptor)

// Создание простого map с одним entry для упрощения отладки
var mapEntries: [String: ProtoValue] = [:]
mapEntries["one"] = ProtoValue.intValue(1)

// Установка значения map поля
let setResult = message.set(field: mapFieldDescriptor, value: ProtoValue.mapValue(mapEntries))
XCTAssertTrue(setResult, "Setting map field should succeed")

// Проверка корректности установки значения
let mapFieldValue = message.get(field: mapFieldDescriptor)
XCTAssertNotNil(mapFieldValue, "Map field value should not be nil")

if case let ProtoValue.mapValue(entries)? = mapFieldValue {
    XCTAssertEqual(entries.count, 1, "Map should have 1 entry")
    XCTAssertEqual(entries["one"]?.getInt(), 1, "Value for key 'one' should be 1")
}
``` 