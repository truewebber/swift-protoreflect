# ProtoValueTests - Неуспешные тесты

## testValidateAgainstFieldDescriptor
### Сравнение с protoc
- Не проверяет все возможные типы конвертаций согласно спецификации protobuf
- Отсутствует проверка wire format валидации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Код теста:
```swift
func testValidateAgainstFieldDescriptor() {
    let intField = ProtoFieldDescriptor(name: "intField", number: 1, type: .int32, isRepeated: false, isMap: false)
    let stringField = ProtoFieldDescriptor(
        name: "stringField",
        number: 2,
        type: .string,
        isRepeated: false,
        isMap: false
    )
    let repeatedIntField = ProtoFieldDescriptor(
        name: "repeatedIntField",
        number: 3,
        type: .int32,
        isRepeated: true,
        isMap: false
    )

    // Valid cases
    XCTAssertTrue(ProtoValue.intValue(42).isValid(for: intField))
    XCTAssertTrue(ProtoValue.stringValue("hello").isValid(for: stringField))
    XCTAssertTrue(ProtoValue.repeatedValue([.intValue(1), .intValue(2)]).isValid(for: repeatedIntField))

    // Valid conversions
    // Int can be converted to String
    XCTAssertTrue(ProtoValue.intValue(42).isValid(for: stringField))

    // Invalid cases
    // String that can't be converted to Int
    XCTAssertFalse(ProtoValue.stringValue("not a number").isValid(for: intField))
    // Not a repeated value
    XCTAssertFalse(ProtoValue.intValue(42).isValid(for: repeatedIntField))
    // Wrong element type
    XCTAssertFalse(ProtoValue.repeatedValue([.stringValue("hello")]).isValid(for: repeatedIntField))
}
```

### Сравнение со спецификацией
- Не проверяет все edge cases для числовых конвертаций
- Отсутствует проверка overflow/underflow для числовых типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Рекомендации по исправлению:
  1. Добавить проверки overflow/underflow для числовых типов
  2. Добавить проверки wire format валидации
  3. Расширить тесты конвертации между различными числовыми типами
  4. Добавить проверки для специальных значений (NaN, Infinity)

## testAsInt32 и testAsUInt32
### Сравнение с protoc
- Не проверяет все граничные случаи для числовых конвертаций
- Отсутствует проверка специальных значений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields
- Код теста:
```swift
func testAsInt32() {
    XCTAssertEqual(ProtoValue.intValue(42).asInt32(), 42)
    XCTAssertEqual(ProtoValue.uintValue(42).asInt32(), 42)
    XCTAssertEqual(ProtoValue.floatValue(42.0).asInt32(), 42)
    XCTAssertEqual(ProtoValue.doubleValue(42.0).asInt32(), 42)
    XCTAssertEqual(ProtoValue.boolValue(true).asInt32(), 1)
    XCTAssertEqual(ProtoValue.stringValue("42").asInt32(), 42)
    XCTAssertNil(ProtoValue.stringValue("not a number").asInt32())
}
```

### Сравнение со спецификацией
- Не проверяет все возможные конвертации согласно спецификации
- Отсутствует проверка граничных значений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Рекомендации по исправлению:
  1. Добавить проверки граничных значений (Int32.max, Int32.min)
  2. Добавить проверки специальных значений (NaN, Infinity)
  3. Расширить тесты конвертации между различными числовыми типами
  4. Добавить проверки округления для float/double конвертаций

## Отсутствующие тесты
### testWireFormatValidation
- Должно проверять корректность wire format для всех типов данных
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Пример кода:
```swift
func testWireFormatValidation() {
    // Проверка wire format для различных типов
    let intValue = ProtoValue.intValue(42)
    XCTAssertTrue(intValue.validateWireFormat())
    
    let floatValue = ProtoValue.floatValue(3.14)
    XCTAssertTrue(floatValue.validateWireFormat())
    
    // Проверка некорректного wire format
    let invalidValue = ProtoValue(bytes: [0xFF, 0xFF]) // Некорректный wire format
    XCTAssertFalse(invalidValue.validateWireFormat())
}
```

### testNumericOverflow
- Должно проверять обработку overflow/underflow для числовых типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Пример кода:
```swift
func testNumericOverflow() {
    // Проверка overflow
    let maxInt32 = Int32.max
    let overflowValue = ProtoValue.intValue(Int64(maxInt32) + 1)
    XCTAssertNil(overflowValue.asInt32())
    
    // Проверка underflow
    let minInt32 = Int32.min
    let underflowValue = ProtoValue.intValue(Int64(minInt32) - 1)
    XCTAssertNil(underflowValue.asInt32())
}
```

### testSpecialValues
- Должно проверять обработку специальных значений (NaN, Infinity)
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Пример кода:
```swift
func testSpecialValues() {
    // Проверка NaN
    let nanValue = ProtoValue.floatValue(Float.nan)
    XCTAssertNil(nanValue.asInt32())
    
    // Проверка Infinity
    let infinityValue = ProtoValue.floatValue(Float.infinity)
    XCTAssertNil(infinityValue.asInt32())
    
    // Проверка -Infinity
    let negativeInfinityValue = ProtoValue.floatValue(-Float.infinity)
    XCTAssertNil(negativeInfinityValue.asInt32())
}
``` 