# ProtoValueTests - Успешные тесты

## testIntValue
### Сравнение с protoc
- Корректно проверяет базовые типы данных
- Правильно реализует getter методы для всех типов
- Соответствует спецификации protobuf для числовых типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Код теста:
```swift
func testIntValue() {
    let value = ProtoValue.intValue(42)
    XCTAssertEqual(value.getInt(), 42)
    XCTAssertNil(value.getUInt())
    XCTAssertNil(value.getString())
    XCTAssertNil(value.getBool())
    XCTAssertNil(value.getFloat())
    XCTAssertNil(value.getDouble())
    XCTAssertNil(value.getBytes())
    XCTAssertNil(value.getMessage())
    XCTAssertNil(value.getRepeated())
    XCTAssertNil(value.getMap())
    XCTAssertNil(value.getEnum())
}
```

### Сравнение со спецификацией
- Корректно реализует типобезопасность согласно спецификации
- Правильно обрабатывает null значения для несоответствующих типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#default

## testEnumValue
### Сравнение с protoc
- Корректно реализует enum значения
- Правильно обрабатывает enum descriptors
- Соответствует спецификации protobuf для enum типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Код теста:
```swift
func testEnumValue() {
    let enumDescriptor = ProtoEnumDescriptor(
        name: "TestEnum",
        values: [
            ProtoEnumValueDescriptor(name: "UNKNOWN", number: 0),
            ProtoEnumValueDescriptor(name: "VALUE1", number: 1),
        ]
    )

    let value = ProtoValue.enumValue(name: "VALUE1", number: 1, enumDescriptor: enumDescriptor)

    XCTAssertNotNil(value.getEnum())
    XCTAssertEqual(value.getEnum()?.name, "VALUE1")
    XCTAssertEqual(value.getEnum()?.number, 1)
    XCTAssertEqual(value.getEnum()?.enumDescriptor.name, "TestEnum")
}
```

### Сравнение со спецификацией
- Корректно реализует enum значения с их дескрипторами
- Правильно обрабатывает enum номера и имена
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum

## testMapValue
### Сравнение с protoc
- Корректно реализует map типы
- Правильно обрабатывает ключи и значения map
- Соответствует спецификации protobuf для map типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Код теста:
```swift
func testMapValue() {
    let map: [String: ProtoValue] = [
        "key1": .intValue(1),
        "key2": .stringValue("value2"),
    ]

    let mapValue = ProtoValue.mapValue(map)

    XCTAssertNotNil(mapValue.getMap())
    XCTAssertEqual(mapValue.getMap()?.count, 2)
    XCTAssertEqual(mapValue.getMap()?["key1"]?.getInt(), 1)
    XCTAssertEqual(mapValue.getMap()?["key2"]?.getString(), "value2")
}
```

### Сравнение со спецификацией
- Корректно реализует map структуры
- Правильно обрабатывает различные типы значений в map
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps 