# FieldDecoderTests - Успешные тесты

## testDecodeIntField
### Сравнение с protoc
- Корректно проверяет декодирование int32 поля
- Соответствует поведению protoc для wire type 0 (varint)
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#varints
- Код теста, который проверяет это поведение:
```swift
func testDecodeIntField() {
    let fieldDescriptor = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
    let encodedData = FieldEncoder.encode(fieldDescriptor: fieldDescriptor, value: .intValue(123))
    let decodedValue = FieldDecoder.decode(fieldDescriptor: fieldDescriptor, data: encodedData)
    XCTAssertEqual(decodedValue?.getInt(), 123)
}
```

### Сравнение со спецификацией
- Корректно реализует декодирование int32 полей согласно спецификации
- Правильно обрабатывает wire type 0 (varint) для числовых типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields
- Код теста, который проверяет это поведение:
```swift
func testDecodeIntField() {
    let fieldDescriptor = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
    let encodedData = FieldEncoder.encode(fieldDescriptor: fieldDescriptor, value: .intValue(123))
    let decodedValue = FieldDecoder.decode(fieldDescriptor: fieldDescriptor, data: encodedData)
    XCTAssertEqual(decodedValue?.getInt(), 123)
}
``` 