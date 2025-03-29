# ProtoFieldPathTests - Неуспешные тесты

## testSetValueWithNonexistentNestedPath
### Сравнение с protoc
- Не соответствует поведению protoc при установке значений в несуществующих вложенных полях
- Protoc не позволяет устанавливать значения в несуществующих полях
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#field-types
- Код теста:
```swift
func testSetValueWithNonexistentNestedPath() {
    let path = ProtoFieldPath(path: "address.zip_code")
    let result = path.setValue(.intValue(12345), in: person)

    XCTAssertTrue(result)

    let address = person.get(field: personDescriptor.field(named: "address")!)?.getMessage() as? ProtoDynamicMessage
    XCTAssertNotNil(address)
    XCTAssertEqual(address?.get(field: addressDescriptor.field(named: "zip_code")!)?.getInt(), 12345)
}
```

### Сравнение со спецификацией
- Не соответствует спецификации protobuf, которая требует валидации существования полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#field-types
- Рекомендации по исправлению:
  1. Добавить валидацию существования полей перед установкой значений
  2. Возвращать false при попытке установить значение в несуществующее поле
  3. Добавить проверку типов полей согласно спецификации

## Отсутствующие тесты

### testRepeatedFieldPath
- Описание: Отсутствует тест для проверки работы с повторяющимися полями
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#repeated-fields
- Пример кода теста:
```swift
func testRepeatedFieldPath() {
    let path = ProtoFieldPath(path: "phones")
    let phone1 = ProtoDynamicMessage(descriptor: phoneDescriptor)
    phone1.set(field: phoneDescriptor.field(named: "number")!, value: .stringValue("123-456-7890"))
    
    let result = path.setValue(.messageValue(phone1), in: person)
    XCTAssertTrue(result)
    
    let phones = person.get(field: personDescriptor.field(named: "phones")!)?.getRepeatedMessage()
    XCTAssertNotNil(phones)
    XCTAssertEqual(phones?.count, 1)
    XCTAssertEqual(phones?[0].get(field: phoneDescriptor.field(named: "number")!)?.getString(), "123-456-7890")
}
```

### testMapFieldPath
- Описание: Отсутствует тест для проверки работы с map-полями
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#maps
- Пример кода теста:
```swift
func testMapFieldPath() {
    let path = ProtoFieldPath(path: "attributes")
    let result = path.setValue(.mapValue(["key": .stringValue("value")]), in: person)
    
    XCTAssertTrue(result)
    
    let attributes = person.get(field: personDescriptor.field(named: "attributes")!)?.getMap()
    XCTAssertNotNil(attributes)
    XCTAssertEqual(attributes?["key"]?.getString(), "value")
}
```

### testFieldTypeValidation
- Описание: Отсутствует тест для проверки валидации типов полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#field-types
- Пример кода теста:
```swift
func testFieldTypeValidation() {
    let path = ProtoFieldPath(path: "age")
    let result = path.setValue(.stringValue("30"), in: person)
    
    XCTAssertFalse(result)
    
    let age = person.get(field: personDescriptor.field(named: "age")!)
    XCTAssertNil(age)
}
```

### testNestedMessageValidation
- Описание: Отсутствует тест для проверки валидации вложенных сообщений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#nested-types
- Пример кода теста:
```swift
func testNestedMessageValidation() {
    let path = ProtoFieldPath(path: "address")
    let invalidMessage = ProtoDynamicMessage(descriptor: phoneDescriptor)
    
    let result = path.setValue(.messageValue(invalidMessage), in: person)
    XCTAssertFalse(result)
    
    let address = person.get(field: personDescriptor.field(named: "address")!)
    XCTAssertNil(address)
}
```

### testFieldNumberValidation
- Описание: Отсутствует тест для проверки валидации номеров полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#field-numbers
- Пример кода теста:
```swift
func testFieldNumberValidation() {
    let invalidDescriptor = ProtoFieldDescriptor(
        name: "invalid",
        number: 0, // Invalid field number
        type: .string,
        isRepeated: false,
        isMap: false
    )
    
    let path = ProtoFieldPath(path: "invalid")
    let result = path.setValue(.stringValue("value"), in: person)
    
    XCTAssertFalse(result)
} 