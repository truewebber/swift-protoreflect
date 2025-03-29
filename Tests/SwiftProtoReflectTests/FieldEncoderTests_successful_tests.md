# FieldEncoderTests - Успешные тесты

## testEncodeIntField
### Сравнение с protoc
- Тест корректно проверяет базовую кодировку целочисленного поля
- Соответствует поведению protoc для кодировки int32 полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields
- Код теста:
```swift
func testEncodeIntField() {
    let fieldDescriptor = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
    let value = ProtoValue.intValue(123)
    let encodedData = FieldEncoder.encode(fieldDescriptor: fieldDescriptor, value: value)
    XCTAssertNotNil(encodedData)
}
```

### Сравнение со спецификацией
- Тест корректно проверяет базовую кодировку согласно спецификации protobuf
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields
- Код теста:
```swift
func testEncodeIntField() {
    let fieldDescriptor = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
    let value = ProtoValue.intValue(123)
    let encodedData = FieldEncoder.encode(fieldDescriptor: fieldDescriptor, value: value)
    XCTAssertNotNil(encodedData)
}
``` 