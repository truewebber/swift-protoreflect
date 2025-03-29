# ProtoWireFormatTests - Successful Tests

## testVarintEncoding
### Сравнение с protoc
- Корректно проверяет кодирование varint значений согласно спецификации
- Тестирует различные случаи: 0, 1, 127, 128, 300, 16383, 16384, UInt64.max
- Соответствует поведению protoc для varint кодирования
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#varints
- Код теста:
```swift
func testVarintEncoding() {
    let testCases: [(UInt64, [UInt8])] = [
        (0, [0]),
        (1, [1]),
        (127, [127]),
        (128, [128, 1]),
        (300, [172, 2]),
        (16383, [255, 127]),
        (16384, [128, 128, 1]),
        (UInt64.max, [255, 255, 255, 255, 255, 255, 255, 255, 255, 1]),
    ]

    for (value, expectedBytes) in testCases {
        let encoded = ProtoWireFormat.encodeVarint(value)
        XCTAssertEqual(Array(encoded), expectedBytes)
    }
}
```

### Сравнение со спецификацией
- Полностью соответствует спецификации varint кодирования
- Проверяет все граничные случаи из спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#varints

## testZigZag32Encoding
### Сравнение с protoc
- Корректно проверяет кодирование ZigZag для 32-битных значений
- Тестирует положительные и отрицательные значения
- Соответствует поведению protoc для ZigZag кодирования
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#signed-integers
- Код теста:
```swift
func testZigZag32Encoding() {
    let testCases: [(Int32, UInt32)] = [
        (0, 0),
        (1, 2),
        (-1, 1),
        (2, 4),
        (-2, 3),
        (127, 254),
        (-127, 253),
        (128, 256),
        (-128, 255),
        (Int32.max / 2, UInt32(Int32.max / 2) * 2),
    ]

    for (value, expected) in testCases {
        let encoded = ProtoWireFormat.encodeZigZag32(value)
        XCTAssertEqual(encoded, expected)
    }
}
```

### Сравнение со спецификацией
- Полностью соответствует спецификации ZigZag кодирования
- Проверяет все граничные случаи
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#signed-integers

## testIntFieldEncoding
### Сравнение с protoc
- Корректно проверяет кодирование int32 полей
- Проверяет правильное формирование field key и value
- Соответствует поведению protoc для int32 полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields
- Код теста:
```swift
func testIntFieldEncoding() {
    let fieldDescriptor = ProtoFieldDescriptor(
        name: "test_int",
        number: 1,
        type: .int32,
        isRepeated: false,
        isMap: false
    )
    let value = ProtoValue.intValue(42)
    var data = Data()
    XCTAssertNoThrow(try ProtoWireFormat.encodeField(field: fieldDescriptor, value: value, to: &data))
    let expectedBytes: [UInt8] = [8, 42]
    XCTAssertEqual(Array(data), expectedBytes)
}
```

### Сравнение со спецификацией
- Полностью соответствует спецификации кодирования полей
- Правильно формирует field key (field number << 3 | wire type)
- Правильно кодирует значение как varint
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields

## testStringFieldEncoding
### Сравнение с protoc
- Корректно проверяет кодирование string полей
- Проверяет правильное формирование field key, length и UTF-8 значения
- Соответствует поведению protoc для string полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields
- Код теста:
```swift
func testStringFieldEncoding() {
    let fieldDescriptor = ProtoFieldDescriptor(
        name: "test_string",
        number: 2,
        type: .string,
        isRepeated: false,
        isMap: false
    )
    let value = ProtoValue.stringValue("hello")
    var data = Data()
    XCTAssertNoThrow(try ProtoWireFormat.encodeField(field: fieldDescriptor, value: value, to: &data))
    let expectedBytes: [UInt8] = [18, 5, 104, 101, 108, 108, 111]
    XCTAssertEqual(Array(data), expectedBytes)
}
```

### Сравнение со спецификацией
- Полностью соответствует спецификации кодирования полей
- Правильно формирует field key (field number << 3 | wire type = 2)
- Правильно кодирует длину строки как varint
- Правильно кодирует UTF-8 значение
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields

## testEnumFieldEncoding
### Сравнение с protoc
- Корректно проверяет кодирование enum полей
- Проверяет правильное формирование field key и enum значения
- Соответствует поведению protoc для enum полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields
- Код теста:
```swift
func testEnumFieldEncoding() {
    let enumDescriptor = ProtoEnumDescriptor(
        name: "TestEnum",
        values: [
            ProtoEnumValueDescriptor(name: "ZERO", number: 0),
            ProtoEnumValueDescriptor(name: "ONE", number: 1),
            ProtoEnumValueDescriptor(name: "TWO", number: 2),
        ]
    )
    let fieldDescriptor = ProtoFieldDescriptor(
        name: "test_enum",
        number: 14,
        type: .enum(enumDescriptor),
        isRepeated: false,
        isMap: false,
        enumType: enumDescriptor
    )
    let testCases: [(Int, String, [UInt8])] = [
        (0, "ZERO", [112, 0]),
        (1, "ONE", [112, 1]),
        (2, "TWO", [112, 2]),
    ]
    for (number, name, expectedBytes) in testCases {
        var data = Data()
        let enumValue = ProtoValue.enumValue(name: name, number: number, enumDescriptor: enumDescriptor)
        XCTAssertNoThrow(try ProtoWireFormat.encodeField(field: fieldDescriptor, value: enumValue, to: &data))
        XCTAssertEqual(Array(data), expectedBytes)
    }
}
```

### Сравнение со спецификацией
- Полностью соответствует спецификации кодирования полей
- Правильно формирует field key (field number << 3 | wire type = 0)
- Правильно кодирует enum значение как varint
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields 