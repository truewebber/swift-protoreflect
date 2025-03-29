# ProtoMessageTests - Неуспешные тесты

## testGetNonExistentField
### Сравнение с protoc
- Не проверяет корректность wire format для несуществующих полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#unknown-fields
- Код теста:
```swift
func testGetNonExistentField() {
    let nonExistentField = ProtoFieldDescriptor(
        name: "nonExistent",
        number: 99,
        type: .int32,
        isRepeated: false,
        isMap: false
    )
    let value = message.get(field: nonExistentField)
    XCTAssertNil(value)
}
```

### Сравнение со спецификацией
- Не проверяет обработку unknown fields согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#unknown-fields
- Рекомендации по исправлению:
  1. Добавить проверку сохранения unknown fields
  2. Добавить проверку wire format для unknown fields
  3. Реализовать корректную обработку unknown fields согласно спецификации

## testSetInvalidFieldType
### Сравнение с protoc
- Не проверяет корректную обработку ошибок при неверном типе
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Код теста:
```swift
func testSetInvalidFieldType() {
    message.set(field: descriptor.fields[0], value: .stringValue("invalid"))
    let value = message.get(field: descriptor.fields[0])
    XCTAssertNil(value?.getInt())
}
```

### Сравнение со спецификацией
- Не соответствует спецификации по обработке ошибок типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Рекомендации по исправлению:
  1. Добавить проверку wire type compatibility
  2. Реализовать корректную обработку ошибок типов
  3. Добавить валидацию типов согласно спецификации

## testInvalidMessage
### Сравнение с protoc
- Не проверяет все случаи невалидных сообщений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#message-structure
- Код теста:
```swift
func testInvalidMessage() {
    let invalidDescriptor = ProtoMessageDescriptor(fullName: "", fields: [], enums: [], nestedMessages: [])
    let invalidMessage = ProtoDynamicMessage(descriptor: invalidDescriptor)
    XCTAssertFalse(invalidMessage.isValid())
}
```

### Сравнение со спецификацией
- Не соответствует спецификации по валидации сообщений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#message-structure
- Рекомендации по исправлению:
  1. Добавить проверку всех требований к структуре сообщения
  2. Реализовать валидацию вложенных сообщений
  3. Добавить проверку корректности имен полей

## Отсутствующие тесты

### testWireTypeValidation
- Описание: Проверка корректности wire types для всех типов полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Пример кода:
```swift
func testWireTypeValidation() {
    let field = ProtoFieldDescriptor(name: "test", number: 1, type: .int32, isRepeated: false, isMap: false)
    let message = ProtoDynamicMessage(descriptor: descriptor)
    
    // Проверка wire type для int32
    message.set(field: field, value: .intValue(123))
    let wireType = message.getWireType(field: field)
    XCTAssertEqual(wireType, .varint)
    
    // Проверка wire type для string
    let stringField = ProtoFieldDescriptor(name: "string", number: 2, type: .string, isRepeated: false, isMap: false)
    message.set(field: stringField, value: .stringValue("test"))
    let stringWireType = message.getWireType(field: stringField)
    XCTAssertEqual(stringWireType, .lengthDelimited)
}
```

### testUnknownFieldsHandling
- Описание: Проверка корректной обработки unknown fields
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#unknown-fields
- Пример кода:
```swift
func testUnknownFieldsHandling() {
    let message = ProtoDynamicMessage(descriptor: descriptor)
    
    // Добавление unknown field
    let unknownField = ProtoFieldDescriptor(name: "unknown", number: 999, type: .int32, isRepeated: false, isMap: false)
    message.set(field: unknownField, value: .intValue(123))
    
    // Проверка сохранения unknown field
    let unknownFields = message.getUnknownFields()
    XCTAssertEqual(unknownFields.count, 1)
    XCTAssertEqual(unknownFields[0].number, 999)
    
    // Проверка wire format для unknown field
    let wireType = message.getWireType(field: unknownField)
    XCTAssertEqual(wireType, .varint)
}
```

### testMessageStructureValidation
- Описание: Проверка валидации структуры сообщения
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#message-structure
- Пример кода:
```swift
func testMessageStructureValidation() {
    // Проверка валидного сообщения
    let validDescriptor = ProtoMessageDescriptor(
        fullName: "TestMessage",
        fields: [ProtoFieldDescriptor(name: "test", number: 1, type: .int32, isRepeated: false, isMap: false)],
        enums: [],
        nestedMessages: []
    )
    let validMessage = ProtoDynamicMessage(descriptor: validDescriptor)
    XCTAssertTrue(validMessage.isValid())
    
    // Проверка невалидного сообщения с дублирующимися номерами полей
    let invalidDescriptor = ProtoMessageDescriptor(
        fullName: "InvalidMessage",
        fields: [
            ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false),
            ProtoFieldDescriptor(name: "field2", number: 1, type: .string, isRepeated: false, isMap: false)
        ],
        enums: [],
        nestedMessages: []
    )
    let invalidMessage = ProtoDynamicMessage(descriptor: invalidDescriptor)
    XCTAssertFalse(invalidMessage.isValid())
}
``` 