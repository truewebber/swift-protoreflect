# FieldEncoderTests - Неуспешные тесты

## testEncodeUnsupportedType
### Сравнение с protoc
- Тест не полностью соответствует поведению protoc
- В protoc при попытке кодировки неподдерживаемого типа генерируется ошибка компиляции
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields
- Код теста:
```swift
func testEncodeUnsupportedType() {
    let fieldDescriptor = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
    let value = ProtoValue.messageValue(ProtoDynamicMessage(descriptor: createTestMessageDescriptor()))
    let encodedData = FieldEncoder.encode(fieldDescriptor: fieldDescriptor, value: value)
    XCTAssertTrue(encodedData.isEmpty)  // This should pass now
}
```

### Сравнение со спецификацией
- Тест не полностью соответствует спецификации protobuf
- Согласно спецификации, несоответствие типов должно вызывать ошибку
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields
- Рекомендации по исправлению:
  1. Изменить тест, чтобы он ожидал выброс исключения при несоответствии типов
  2. Добавить проверку конкретного типа ошибки
  3. Добавить тесты для всех возможных несоответствий типов
- Код теста:
```swift
func testEncodeUnsupportedType() {
    let fieldDescriptor = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
    let value = ProtoValue.messageValue(ProtoDynamicMessage(descriptor: createTestMessageDescriptor()))
    let encodedData = FieldEncoder.encode(fieldDescriptor: fieldDescriptor, value: value)
    XCTAssertTrue(encodedData.isEmpty)  // This should pass now
}
```

## Отсутствующие тесты

### testWireTypeValidation
- Должен проверять корректность wire type для каждого типа поля
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Пример кода теста:
```swift
func testWireTypeValidation() {
    let fieldDescriptor = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
    let value = ProtoValue.intValue(123)
    let encodedData = FieldEncoder.encode(fieldDescriptor: fieldDescriptor, value: value)
    // Проверка wire type в закодированных данных
    XCTAssertEqual(encodedData[0] & 0x7, 0) // Проверка wire type для int32
}
```

### testFieldNumberValidation
- Должен проверять валидацию номера поля (1-536870911)
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields
- Пример кода теста:
```swift
func testFieldNumberValidation() {
    // Проверка минимального номера поля
    let minFieldDescriptor = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
    XCTAssertNotNil(FieldEncoder.encode(fieldDescriptor: minFieldDescriptor, value: .intValue(1)))
    
    // Проверка максимального номера поля
    let maxFieldDescriptor = ProtoFieldDescriptor(name: "field2", number: 536870911, type: .int32, isRepeated: false, isMap: false)
    XCTAssertNotNil(FieldEncoder.encode(fieldDescriptor: maxFieldDescriptor, value: .intValue(1)))
    
    // Проверка некорректного номера поля
    let invalidFieldDescriptor = ProtoFieldDescriptor(name: "field3", number: 0, type: .int32, isRepeated: false, isMap: false)
    XCTAssertThrowsError(FieldEncoder.encode(fieldDescriptor: invalidFieldDescriptor, value: .intValue(1)))
}
```

### testRepeatedFieldEncoding
- Должен проверять корректную кодировку повторяющихся полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#repeated
- Пример кода теста:
```swift
func testRepeatedFieldEncoding() {
    let fieldDescriptor = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: true, isMap: false)
    let values = [ProtoValue.intValue(1), ProtoValue.intValue(2), ProtoValue.intValue(3)]
    let encodedData = FieldEncoder.encode(fieldDescriptor: fieldDescriptor, value: .repeatedValue(values))
    // Проверка корректности кодировки повторяющихся значений
    XCTAssertNotNil(encodedData)
    // Дополнительные проверки структуры закодированных данных
}
```

### testMapFieldEncoding
- Должен проверять корректную кодировку map полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#maps
- Пример кода теста:
```swift
func testMapFieldEncoding() {
    let fieldDescriptor = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: true)
    let mapValue = ["key1": ProtoValue.intValue(1), "key2": ProtoValue.intValue(2)]
    let encodedData = FieldEncoder.encode(fieldDescriptor: fieldDescriptor, value: .mapValue(mapValue))
    // Проверка корректности кодировки map
    XCTAssertNotNil(encodedData)
    // Дополнительные проверки структуры закодированных данных
}
``` 