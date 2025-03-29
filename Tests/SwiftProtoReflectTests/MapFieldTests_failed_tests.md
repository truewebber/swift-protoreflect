# MapFieldTests - Неуспешные тесты

## testMapFieldEncoding
### Сравнение с protoc
- Отсутствует проверка валидации типов ключей map (согласно спецификации, ключом может быть только целочисленный тип или string)
- Отсутствует проверка максимального размера map
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Пример поведения protoc:
```protobuf
message TestMessage {
  // Это скомпилируется
  map<string, int32> valid_map = 1;
  
  // Это не скомпилируется
  map<double, string> invalid_map = 2;  // Error: Key type must be string or integer
}
```

### Сравнение со спецификацией
- Отсутствует проверка сериализации/десериализации пустых map
- Отсутствует проверка обработки дублирующихся ключей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#maps
- Рекомендации по исправлению:
  1. Добавить тесты на валидацию типов ключей
  2. Добавить тесты на обработку пустых map
  3. Добавить тесты на обработку дублирующихся ключей
  4. Добавить тесты на максимальный размер map

## Отсутствующие тесты

### testMapKeyTypeValidation
- Описание: Проверка валидации типов ключей map
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Пример кода теста:
```swift
func testMapKeyTypeValidation() {
    // Попытка создать map с недопустимым типом ключа
    let invalidKeyFieldDescriptor = ProtoFieldDescriptor(
        name: "key",
        number: 1,
        type: .double,  // Недопустимый тип для ключа
        isRepeated: false,
        isMap: false
    )
    
    let valueFieldDescriptor = ProtoFieldDescriptor(
        name: "value",
        number: 2,
        type: .string,
        isRepeated: false,
        isMap: false
    )
    
    let entryDescriptor = ProtoMessageDescriptor(
        fullName: "TestMessage.InvalidMapEntry",
        fields: [invalidKeyFieldDescriptor, valueFieldDescriptor],
        enums: [],
        nestedMessages: []
    )
    
    let mapFieldDescriptor = ProtoFieldDescriptor(
        name: "invalid_map",
        number: 1,
        type: .message(entryDescriptor),
        isRepeated: true,
        isMap: true,
        messageType: entryDescriptor
    )
    
    // Должно вернуть ошибку при создании
    XCTAssertThrowsError(try ProtoDynamicMessage(descriptor: messageDescriptor)) { error in
        XCTAssertEqual(error as? ProtoError, .invalidMapKeyType)
    }
}
```

### testEmptyMapHandling
- Описание: Проверка корректной обработки пустых map при сериализации/десериализации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#maps
- Пример кода теста:
```swift
func testEmptyMapHandling() {
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
    
    let entryDescriptor = ProtoMessageDescriptor(
        fullName: "TestMessage.EmptyMapEntry",
        fields: [keyFieldDescriptor, valueFieldDescriptor],
        enums: [],
        nestedMessages: []
    )
    
    let mapFieldDescriptor = ProtoFieldDescriptor(
        name: "empty_map",
        number: 1,
        type: .message(entryDescriptor),
        isRepeated: true,
        isMap: true,
        messageType: entryDescriptor
    )
    
    let messageDescriptor = ProtoMessageDescriptor(
        fullName: "TestMessage",
        fields: [mapFieldDescriptor],
        enums: [],
        nestedMessages: [entryDescriptor]
    )
    
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    
    // Установка пустого map
    let setResult = message.set(field: mapFieldDescriptor, value: ProtoValue.mapValue([:]))
    XCTAssertTrue(setResult, "Setting empty map should succeed")
    
    // Сериализация
    guard let serializedData = ProtoWireFormat.marshal(message: message) else {
        XCTFail("Failed to marshal message with empty map")
        return
    }
    
    // Десериализация
    let unmarshalledMessage = ProtoWireFormat.unmarshal(
        data: serializedData,
        messageDescriptor: messageDescriptor
    ) as? ProtoDynamicMessage
    
    XCTAssertNotNil(unmarshalledMessage, "Message with empty map should be deserialized")
    
    // Проверка что map остался пустым
    let mapValue = unmarshalledMessage?.get(field: mapFieldDescriptor)
    if case let ProtoValue.mapValue(entries)? = mapValue {
        XCTAssertEqual(entries.count, 0, "Map should remain empty after serialization/deserialization")
    } else {
        XCTFail("Field value should be a map value")
    }
}
```

### testDuplicateMapKeys
- Описание: Проверка обработки дублирующихся ключей в map
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#maps
- Пример кода теста:
```swift
func testDuplicateMapKeys() {
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
    
    let entryDescriptor = ProtoMessageDescriptor(
        fullName: "TestMessage.DuplicateMapEntry",
        fields: [keyFieldDescriptor, valueFieldDescriptor],
        enums: [],
        nestedMessages: []
    )
    
    let mapFieldDescriptor = ProtoFieldDescriptor(
        name: "duplicate_map",
        number: 1,
        type: .message(entryDescriptor),
        isRepeated: true,
        isMap: true,
        messageType: entryDescriptor
    )
    
    let messageDescriptor = ProtoMessageDescriptor(
        fullName: "TestMessage",
        fields: [mapFieldDescriptor],
        enums: [],
        nestedMessages: [entryDescriptor]
    )
    
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    
    // Создание map с дублирующимися ключами
    var mapEntries: [String: ProtoValue] = [:]
    mapEntries["key1"] = ProtoValue.intValue(1)
    mapEntries["key1"] = ProtoValue.intValue(2)  // Дублирующийся ключ
    
    // Установка значения map поля
    let setResult = message.set(field: mapFieldDescriptor, value: ProtoValue.mapValue(mapEntries))
    XCTAssertTrue(setResult, "Setting map with duplicate keys should succeed")
    
    // Проверка что последнее значение сохранилось
    let mapValue = message.get(field: mapFieldDescriptor)
    if case let ProtoValue.mapValue(entries)? = mapValue {
        XCTAssertEqual(entries.count, 1, "Map should have 1 entry after duplicate key handling")
        XCTAssertEqual(entries["key1"]?.getInt(), 2, "Last value for duplicate key should be preserved")
    } else {
        XCTFail("Field value should be a map value")
    }
} 