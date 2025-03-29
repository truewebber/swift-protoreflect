# ProtoDynamicMessageTests - Успешные тесты

## testSetAndGetFieldValues
### Сравнение с protoc
- Корректно проверяет базовые операции установки и получения значений полей
- Соответствует поведению protoc для простых типов данных
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields
- Код теста:
```swift
func testSetAndGetFieldValues() {
    message.set(field: descriptor.field(named: "intField")!, value: .intValue(100))
    message.set(field: descriptor.field(named: "stringField")!, value: .stringValue("hello"))
    message.set(field: descriptor.field(named: "boolField")!, value: .boolValue(true))

    let intValue = message.get(field: descriptor.field(named: "intField")!)
    let stringValue = message.get(field: descriptor.field(named: "stringField")!)
    let boolValue = message.get(field: descriptor.field(named: "boolField")!)

    XCTAssertEqual(intValue?.getInt(), 100)
    XCTAssertEqual(stringValue?.getString(), "hello")
    XCTAssertEqual(boolValue?.getBool(), true)
}
```

### Сравнение со спецификацией
- Корректно реализует базовые операции с полями согласно спецификации
- Правильно обрабатывает типы данных int32, string и bool
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#simple

## testRepeatedField
### Сравнение с protoc
- Корректно проверяет операции с повторяющимися полями
- Соответствует поведению protoc для repeated fields
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#repeated
- Код теста:
```swift
func testRepeatedField() {
    XCTAssertTrue(message.add(toRepeatedFieldNamed: "repeatedIntField", value: .intValue(1)))
    XCTAssertTrue(message.add(toRepeatedFieldNamed: "repeatedIntField", value: .intValue(2)))
    XCTAssertTrue(message.add(toRepeatedFieldNamed: "repeatedIntField", value: .intValue(3)))

    XCTAssertEqual(message.count(ofRepeatedFieldNamed: "repeatedIntField"), 3)

    let value1 = message.get(fromRepeatedFieldNamed: "repeatedIntField", at: 0)
    let value2 = message.get(fromRepeatedFieldNamed: "repeatedIntField", at: 1)
    let value3 = message.get(fromRepeatedFieldNamed: "repeatedIntField", at: 2)

    XCTAssertEqual(value1?.getInt(), 1)
    XCTAssertEqual(value2?.getInt(), 2)
    XCTAssertEqual(value3?.getInt(), 3)
}
```

### Сравнение со спецификацией
- Правильно реализует операции с repeated fields
- Корректно обрабатывает добавление и получение элементов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#repeated

## testMapField
### Сравнение с protoc
- Корректно проверяет операции с map полями
- Соответствует поведению protoc для map fields
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#maps
- Код теста:
```swift
func testMapField() {
    XCTAssertTrue(message.set(inMapFieldNamed: "mapField", key: "key1", value: .stringValue("value1")))
    XCTAssertTrue(message.set(inMapFieldNamed: "mapField", key: "key2", value: .stringValue("value2")))

    XCTAssertEqual(message.count(ofMapFieldNamed: "mapField"), 2)

    let value1 = message.get(fromMapFieldNamed: "mapField", key: "key1")
    let value2 = message.get(fromMapFieldNamed: "mapField", key: "key2")

    XCTAssertEqual(value1?.getString(), "value1")
    XCTAssertEqual(value2?.getString(), "value2")
}
```

### Сравнение со спецификацией
- Правильно реализует операции с map fields
- Корректно обрабатывает добавление, получение и удаление элементов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#maps

## testNestedMessage
### Сравнение с protoc
- Корректно проверяет операции с вложенными сообщениями
- Соответствует поведению protoc для nested messages
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#embedded
- Код теста:
```swift
func testNestedMessage() {
    let addressDescriptor = ProtoMessageDescriptor(
        fullName: "Address",
        fields: [
            ProtoFieldDescriptor(name: "street", number: 1, type: .string, isRepeated: false, isMap: false),
            ProtoFieldDescriptor(name: "city", number: 2, type: .string, isRepeated: false, isMap: false),
        ],
        enums: [],
        nestedMessages: []
    )

    let personDescriptor = ProtoMessageDescriptor(
        fullName: "Person",
        fields: [
            ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false),
            ProtoFieldDescriptor(
                name: "address",
                number: 2,
                type: .message(addressDescriptor),
                isRepeated: false,
                isMap: false,
                messageType: addressDescriptor
            ),
        ],
        enums: [],
        nestedMessages: [addressDescriptor]
    )

    let person = ProtoDynamicMessage(descriptor: personDescriptor)
    person.set(fieldName: "name", value: .stringValue("John Doe"))

    let address = ProtoDynamicMessage(descriptor: addressDescriptor)
    address.set(fieldName: "street", value: .stringValue("123 Main St"))
    address.set(fieldName: "city", value: .stringValue("Anytown"))

    person.setNestedMessage(fieldName: "address", message: address)

    let retrievedAddress = person.get(fieldName: "address")?.getMessage() as? ProtoDynamicMessage
    XCTAssertNotNil(retrievedAddress)
    XCTAssertEqual(retrievedAddress?.get(fieldName: "street")?.getString(), "123 Main St")
    XCTAssertEqual(retrievedAddress?.get(fieldName: "city")?.getString(), "Anytown")
}
```

### Сравнение со спецификацией
- Правильно реализует операции с вложенными сообщениями
- Корректно обрабатывает создание и доступ к вложенным сообщениям
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#embedded 