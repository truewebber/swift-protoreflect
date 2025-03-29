# ProtoValueConversionTests - Неуспешные тесты

## testEdgeCases
### Сравнение с protoc
- Не проверяет все edge cases для числовых типов согласно спецификации protobuf
- Не проверяет корректность обработки NaN и Inf для float/double
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Пример поведения protoc:
```protobuf
message Test {
  float value = 1;
}
```
```python
# Это скомпилируется и работает
test.value = float('inf')  # Valid
test.value = float('nan')  # Valid
test.value = float('-inf') # Valid
```
- Код теста:
```swift
func testEdgeCases() {
    let maxInt = Int.max
    let minInt = Int.min
    let maxUInt = UInt.max
    let minUInt = UInt.min
    
    let int32Descriptor = ProtoFieldDescriptor(
      name: "int32_field",
      number: 1,
      type: .int32,
      isRepeated: false,
      isMap: false
    )
    let uint32Descriptor = ProtoFieldDescriptor(
      name: "uint32_field",
      number: 2,
      type: .uint32,
      isRepeated: false,
      isMap: false
    )
    let floatDescriptor = ProtoFieldDescriptor(
      name: "float_field",
      number: 3,
      type: .float,
      isRepeated: false,
      isMap: false
    )
    let stringDescriptor = ProtoFieldDescriptor(
      name: "string_field",
      number: 4,
      type: .string,
      isRepeated: false,
      isMap: false
    )
    let bytesDescriptor = ProtoFieldDescriptor(
      name: "bytes_field",
      number: 5,
      type: .bytes,
      isRepeated: false,
      isMap: false
    )
    
    // Test numeric overflow/underflow
    XCTAssertEqual(ProtoValue.intValue(maxInt).convertTo(fieldDescriptor: int32Descriptor)?.getInt(), maxInt)
    XCTAssertEqual(ProtoValue.intValue(minInt).convertTo(fieldDescriptor: int32Descriptor)?.getInt(), minInt)
    XCTAssertEqual(ProtoValue.uintValue(maxUInt).convertTo(fieldDescriptor: uint32Descriptor)?.getUInt(), maxUInt)
    XCTAssertEqual(ProtoValue.uintValue(minUInt).convertTo(fieldDescriptor: uint32Descriptor)?.getUInt(), minUInt)
    
    // Test string number formats - no implicit conversions allowed
    XCTAssertNil(ProtoValue.stringValue("42").convertTo(fieldDescriptor: int32Descriptor))
    XCTAssertNil(ProtoValue.stringValue("invalid").convertTo(fieldDescriptor: int32Descriptor))
    XCTAssertNil(ProtoValue.stringValue("42.5").convertTo(fieldDescriptor: floatDescriptor))
    XCTAssertNil(ProtoValue.stringValue("4.25e1").convertTo(fieldDescriptor: floatDescriptor))
    XCTAssertNil(ProtoValue.stringValue("0x2A").convertTo(fieldDescriptor: int32Descriptor))
    
    // Test base64 encoding/decoding - no implicit conversions allowed
    XCTAssertNil(ProtoValue.bytesValue(Data([0x01, 0x02, 0x03])).convertTo(fieldDescriptor: stringDescriptor))
    XCTAssertNil(ProtoValue.stringValue("not base64").convertTo(fieldDescriptor: bytesDescriptor))
}
```

### Сравнение со спецификацией
- Не полностью соответствует спецификации protobuf в части обработки edge cases
- Не проверяет все специальные значения для числовых типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Рекомендации по исправлению:
  1. Добавить проверки для NaN, Inf, -Inf для float/double
  2. Добавить проверки для всех граничных значений числовых типов
  3. Добавить проверки для специальных значений enum
  4. Добавить проверки для пустых строк и байтов
  5. Добавить проверки для максимальной длины строк и байтов
- Код теста:
```swift
// ... код теста из предыдущего раздела ...
```

## Отсутствующие тесты

### testNumericTypeOverflow
- Описание: Должен проверять корректность обработки переполнения для всех числовых типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Пример кода:
```swift
func testNumericTypeOverflow() {
    let int32Descriptor = ProtoFieldDescriptor(
      name: "int32_field",
      number: 1,
      type: .int32,
      isRepeated: false,
      isMap: false
    )
    
    // Test overflow for each numeric type
    XCTAssertNil(ProtoValue.intValue(Int32.max + 1).convertTo(fieldDescriptor: int32Descriptor))
    XCTAssertNil(ProtoValue.intValue(Int32.min - 1).convertTo(fieldDescriptor: int32Descriptor))
    XCTAssertNil(ProtoValue.uintValue(UInt32.max + 1).convertTo(fieldDescriptor: uint32Descriptor))
    XCTAssertNil(ProtoValue.uintValue(UInt32.min - 1).convertTo(fieldDescriptor: uint32Descriptor))
    XCTAssertNil(ProtoValue.floatValue(Float.infinity).convertTo(fieldDescriptor: floatDescriptor))
    XCTAssertNil(ProtoValue.floatValue(Float.nan).convertTo(fieldDescriptor: floatDescriptor))
    XCTAssertNil(ProtoValue.doubleValue(Double.infinity).convertTo(fieldDescriptor: doubleDescriptor))
    XCTAssertNil(ProtoValue.doubleValue(Double.nan).convertTo(fieldDescriptor: doubleDescriptor))
}
```

### testStringLengthLimits
- Описание: Должен проверять корректность обработки ограничений длины для строк
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Пример кода:
```swift
func testStringLengthLimits() {
    let stringDescriptor = ProtoFieldDescriptor(
      name: "string_field",
      number: 1,
      type: .string,
      isRepeated: false,
      isMap: false
    )
    
    // Test empty string
    XCTAssertEqual(ProtoValue.stringValue("").convertTo(fieldDescriptor: stringDescriptor)?.getString(), "")
    
    // Test maximum length string (2GB)
    let maxLengthString = String(repeating: "a", count: 2 * 1024 * 1024 * 1024)
    XCTAssertNil(ProtoValue.stringValue(maxLengthString).convertTo(fieldDescriptor: stringDescriptor))
    
    // Test string with null bytes
    XCTAssertNil(ProtoValue.stringValue("Hello\0World").convertTo(fieldDescriptor: stringDescriptor))
}
```

### testBytesLengthLimits
- Описание: Должен проверять корректность обработки ограничений длины для байтов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Пример кода:
```swift
func testBytesLengthLimits() {
    let bytesDescriptor = ProtoFieldDescriptor(
      name: "bytes_field",
      number: 1,
      type: .bytes,
      isRepeated: false,
      isMap: false
    )
    
    // Test empty bytes
    XCTAssertEqual(ProtoValue.bytesValue(Data()).convertTo(fieldDescriptor: bytesDescriptor)?.getBytes(), Data())
    
    // Test maximum length bytes (2GB)
    let maxLengthBytes = Data(repeating: 0, count: 2 * 1024 * 1024 * 1024)
    XCTAssertNil(ProtoValue.bytesValue(maxLengthBytes).convertTo(fieldDescriptor: bytesDescriptor))
}
```

### testEnumSpecialValues
- Описание: Должен проверять корректность обработки специальных значений enum
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Пример кода:
```swift
func testEnumSpecialValues() {
    let enumDescriptor = ProtoEnumDescriptor(
      name: "TestEnum",
      values: [
        ProtoEnumValueDescriptor(name: "TEST_VALUE", number: 1),
        ProtoEnumValueDescriptor(name: "UNKNOWN", number: 0)
      ]
    )
    let enumFieldDescriptor = ProtoFieldDescriptor(
      name: "enum_field",
      number: 1,
      type: .enum(enumDescriptor),
      isRepeated: false,
      isMap: false
    )
    
    // Test unknown enum value
    XCTAssertNotNil(ProtoValue.enumValue(name: "UNKNOWN", number: 0, enumDescriptor: enumDescriptor)
      .convertTo(fieldDescriptor: enumFieldDescriptor))
    
    // Test invalid enum number
    XCTAssertNil(ProtoValue.enumValue(name: "INVALID", number: 999, enumDescriptor: enumDescriptor)
      .convertTo(fieldDescriptor: enumFieldDescriptor))
}
```

### testMapKeyConstraints
- Описание: Должен проверять корректность обработки ограничений для ключей map
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Пример кода:
```swift
func testMapKeyConstraints() {
    let mapFieldDescriptor = ProtoFieldDescriptor(
      name: "map_field",
      number: 1,
      type: .message(nil),
      isRepeated: false,
      isMap: true
    )
    
    // Test empty map
    XCTAssertNotNil(ProtoValue.mapValue([:]).convertTo(fieldDescriptor: mapFieldDescriptor))
    
    // Test map with invalid key type
    XCTAssertNil(ProtoValue.mapValue([1: .intValue(1)]).convertTo(fieldDescriptor: mapFieldDescriptor))
    
    // Test map with duplicate keys
    XCTAssertNil(ProtoValue.mapValue(["key": .intValue(1), "key": .intValue(2)]).convertTo(fieldDescriptor: mapFieldDescriptor))
}
``` 