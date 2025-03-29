# FieldDecoderTests - Неуспешные тесты

## testDecodeCorruptedData
### Сравнение с protoc
- Текущая реализация слишком упрощена и не проверяет все возможные случаи поврежденных данных
- protoc имеет более детальную обработку ошибок для поврежденных varint полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#varints
- Код теста, который требует доработки:
```swift
func testDecodeCorruptedData() {
    let corruptedData = Data([0xFF, 0xFF, 0xFF])
    let fieldDescriptor = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
    let decodedValue = FieldDecoder.decode(fieldDescriptor: fieldDescriptor, data: corruptedData)
    XCTAssertNil(decodedValue)
}
```

### Сравнение со спецификацией
- Не проверяет все возможные случаи поврежденных varint данных
- Не учитывает спецификацию по обработке ошибок в varint декодировании
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#varints
- Рекомендации по исправлению:
  1. Добавить тесты для различных случаев поврежденных varint данных
  2. Проверить обработку неполных varint последовательностей
  3. Добавить тесты для проверки максимальной длины varint
  4. Реализовать более детальную обработку ошибок

## Отсутствующие тесты

### testDecodeInt32Boundaries
- Должен проверять корректную обработку граничных значений для int32
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Пример кода теста:
```swift
func testDecodeInt32Boundaries() {
    let fieldDescriptor = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
    
    // Проверка минимального значения
    let minValue = Int32.min
    let minEncoded = FieldEncoder.encode(fieldDescriptor: fieldDescriptor, value: .intValue(Int(minValue)))
    let minDecoded = FieldDecoder.decode(fieldDescriptor: fieldDescriptor, data: minEncoded)
    XCTAssertEqual(minDecoded?.getInt(), Int(minValue))
    
    // Проверка максимального значения
    let maxValue = Int32.max
    let maxEncoded = FieldEncoder.encode(fieldDescriptor: fieldDescriptor, value: .intValue(Int(maxValue)))
    let maxDecoded = FieldDecoder.decode(fieldDescriptor: fieldDescriptor, data: maxEncoded)
    XCTAssertEqual(maxDecoded?.getInt(), Int(maxValue))
}
```

### testDecodeVarintEdgeCases
- Должен проверять различные edge cases при декодировании varint
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#varints
- Пример кода теста:
```swift
func testDecodeVarintEdgeCases() {
    let fieldDescriptor = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
    
    // Проверка нулевого значения
    let zeroEncoded = FieldEncoder.encode(fieldDescriptor: fieldDescriptor, value: .intValue(0))
    let zeroDecoded = FieldDecoder.decode(fieldDescriptor: fieldDescriptor, data: zeroEncoded)
    XCTAssertEqual(zeroDecoded?.getInt(), 0)
    
    // Проверка максимального количества байт в varint
    let maxVarintBytes = Data([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01])
    let maxVarintDecoded = FieldDecoder.decode(fieldDescriptor: fieldDescriptor, data: maxVarintBytes)
    XCTAssertNotNil(maxVarintDecoded)
}
```

### testDecodeInvalidWireType
- Должен проверять обработку некорректных wire types
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Пример кода теста:
```swift
func testDecodeInvalidWireType() {
    let fieldDescriptor = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
    
    // Проверка некорректного wire type для int32
    let invalidWireType = Data([0x08]) // Wire type 1 (64-bit) для int32
    let decodedValue = FieldDecoder.decode(fieldDescriptor: fieldDescriptor, data: invalidWireType)
    XCTAssertNil(decodedValue)
} 