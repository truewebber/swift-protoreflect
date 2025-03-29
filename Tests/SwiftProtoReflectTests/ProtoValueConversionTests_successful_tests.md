# ProtoValueConversionTests - Успешные тесты

## testConvertToInt
### Сравнение с protoc
- Корректно проверяет, что protoc не допускает неявные преобразования между числовыми типами
- Правильно обрабатывает только точное соответствие типов (int32 -> int32)
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Пример поведения protoc:
```protobuf
message Test {
  int32 value = 1;
}
```
```python
# Это не скомпилируется
test.value = "42"  # Error: Cannot assign string to int32
test.value = 42.5  # Error: Cannot assign float to int32
```
- Код теста:
```swift
func testConvertToInt() {
    let int32Descriptor = ProtoFieldDescriptor(
      name: "int32_field",
      number: 1,
      type: .int32,
      isRepeated: false,
      isMap: false
    )
    
    // Valid conversions - protoc allows same type
    XCTAssertEqual(ProtoValue.intValue(42).convertTo(fieldDescriptor: int32Descriptor)?.getInt(), 42)
    
    // Invalid conversions - protoc doesn't allow implicit conversions
    XCTAssertNil(ProtoValue.uintValue(42).convertTo(fieldDescriptor: int32Descriptor))
    XCTAssertNil(ProtoValue.boolValue(true).convertTo(fieldDescriptor: int32Descriptor))
    XCTAssertNil(ProtoValue.stringValue("42").convertTo(fieldDescriptor: int32Descriptor))
    XCTAssertNil(ProtoValue.floatValue(42.5).convertTo(fieldDescriptor: int32Descriptor))
    XCTAssertNil(ProtoValue.doubleValue(42.5).convertTo(fieldDescriptor: int32Descriptor))
    XCTAssertNil(ProtoValue.bytesValue(Data([0x01])).convertTo(fieldDescriptor: int32Descriptor))
}
```

### Сравнение со спецификацией
- Корректно реализует правила типизации из спецификации protobuf
- Правильно обрабатывает все числовые типы согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Код теста:
```swift
// ... код теста из предыдущего раздела ...
```

## testConvertToUInt
### Сравнение с protoc
- Корректно проверяет, что protoc не допускает неявные преобразования для uint32
- Правильно обрабатывает только точное соответствие типов (uint32 -> uint32)
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Пример поведения protoc:
```protobuf
message Test {
  uint32 value = 1;
}
```
```python
# Это не скомпилируется
test.value = -42  # Error: Cannot assign negative value to uint32
test.value = "42" # Error: Cannot assign string to uint32
```
- Код теста:
```swift
func testConvertToUInt() {
    let uint32Descriptor = ProtoFieldDescriptor(
      name: "uint32_field",
      number: 1,
      type: .uint32,
      isRepeated: false,
      isMap: false
    )
    
    // Valid conversions - protoc allows same type
    XCTAssertEqual(ProtoValue.uintValue(42).convertTo(fieldDescriptor: uint32Descriptor)?.getUInt(), 42)
    
    // Invalid conversions - protoc doesn't allow implicit conversions
    XCTAssertNil(ProtoValue.intValue(42).convertTo(fieldDescriptor: uint32Descriptor))
    XCTAssertNil(ProtoValue.boolValue(true).convertTo(fieldDescriptor: uint32Descriptor))
    XCTAssertNil(ProtoValue.stringValue("42").convertTo(fieldDescriptor: uint32Descriptor))
    XCTAssertNil(ProtoValue.floatValue(42.5).convertTo(fieldDescriptor: uint32Descriptor))
    XCTAssertNil(ProtoValue.doubleValue(42.5).convertTo(fieldDescriptor: uint32Descriptor))
    XCTAssertNil(ProtoValue.bytesValue(Data([0x01])).convertTo(fieldDescriptor: uint32Descriptor))
}
```

### Сравнение со спецификацией
- Корректно реализует правила для беззнаковых целых чисел
- Правильно обрабатывает все числовые типы согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Код теста:
```swift
// ... код теста из предыдущего раздела ...
```

## testConvertToFloat
### Сравнение с protoc
- Корректно проверяет, что protoc не допускает неявные преобразования для float
- Правильно обрабатывает только точное соответствие типов (float -> float)
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Пример поведения protoc:
```protobuf
message Test {
  float value = 1;
}
```
```python
# Это не скомпилируется
test.value = "42.5"  # Error: Cannot assign string to float
test.value = 42      # Error: Cannot assign int to float
```
- Код теста:
```swift
func testConvertToFloat() {
    let floatDescriptor = ProtoFieldDescriptor(
      name: "float_field",
      number: 1,
      type: .float,
      isRepeated: false,
      isMap: false
    )
    
    // Valid conversions - protoc allows same type
    XCTAssertEqual(ProtoValue.floatValue(42.5).convertTo(fieldDescriptor: floatDescriptor)?.getFloat(), 42.5)
    
    // Invalid conversions - protoc doesn't allow implicit conversions
    XCTAssertNil(ProtoValue.doubleValue(42.5).convertTo(fieldDescriptor: floatDescriptor))
    XCTAssertNil(ProtoValue.intValue(42).convertTo(fieldDescriptor: floatDescriptor))
    XCTAssertNil(ProtoValue.uintValue(42).convertTo(fieldDescriptor: floatDescriptor))
    XCTAssertNil(ProtoValue.boolValue(true).convertTo(fieldDescriptor: floatDescriptor))
    XCTAssertNil(ProtoValue.stringValue("42.5").convertTo(fieldDescriptor: floatDescriptor))
    XCTAssertNil(ProtoValue.bytesValue(Data([0x01])).convertTo(fieldDescriptor: floatDescriptor))
}
```

### Сравнение со спецификацией
- Корректно реализует правила для чисел с плавающей точкой
- Правильно обрабатывает все числовые типы согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Код теста:
```swift
// ... код теста из предыдущего раздела ...
```

## testConvertToBool
### Сравнение с protoc
- Корректно проверяет, что protoc не допускает неявные преобразования для bool
- Правильно обрабатывает только точное соответствие типов (bool -> bool)
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Пример поведения protoc:
```protobuf
message Test {
  bool value = 1;
}
```
```python
# Это не скомпилируется
test.value = 1      # Error: Cannot assign int to bool
test.value = "true" # Error: Cannot assign string to bool
```
- Код теста:
```swift
func testConvertToBool() {
    let boolDescriptor = ProtoFieldDescriptor(
      name: "bool_field",
      number: 1,
      type: .bool,
      isRepeated: false,
      isMap: false
    )
    
    // Valid conversions - protoc allows same type
    XCTAssertEqual(ProtoValue.boolValue(true).convertTo(fieldDescriptor: boolDescriptor)?.getBool(), true)
    XCTAssertEqual(ProtoValue.boolValue(false).convertTo(fieldDescriptor: boolDescriptor)?.getBool(), false)
    
    // Invalid conversions - protoc doesn't allow implicit conversions
    XCTAssertNil(ProtoValue.intValue(1).convertTo(fieldDescriptor: boolDescriptor))
    XCTAssertNil(ProtoValue.uintValue(1).convertTo(fieldDescriptor: boolDescriptor))
    XCTAssertNil(ProtoValue.floatValue(1.0).convertTo(fieldDescriptor: boolDescriptor))
    XCTAssertNil(ProtoValue.doubleValue(1.0).convertTo(fieldDescriptor: boolDescriptor))
    XCTAssertNil(ProtoValue.stringValue("true").convertTo(fieldDescriptor: boolDescriptor))
}
```

### Сравнение со спецификацией
- Корректно реализует правила для булевых значений
- Правильно обрабатывает все числовые типы согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Код теста:
```swift
// ... код теста из предыдущего раздела ...
```

## testConvertToString
### Сравнение с protoc
- Корректно проверяет, что protoc не допускает неявные преобразования для string
- Правильно обрабатывает только точное соответствие типов (string -> string)
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Пример поведения protoc:
```protobuf
message Test {
  string value = 1;
}
```
```python
# Это не скомпилируется
test.value = 42     # Error: Cannot assign int to string
test.value = true   # Error: Cannot assign bool to string
```
- Код теста:
```swift
func testConvertToString() {
    let stringDescriptor = ProtoFieldDescriptor(
      name: "string_field",
      number: 1,
      type: .string,
      isRepeated: false,
      isMap: false
    )
    
    // Valid conversions - protoc allows same type
    XCTAssertEqual(ProtoValue.stringValue("Hello").convertTo(fieldDescriptor: stringDescriptor)?.getString(), "Hello")
    
    // Invalid conversions - protoc doesn't allow implicit conversions
    XCTAssertNil(ProtoValue.intValue(42).convertTo(fieldDescriptor: stringDescriptor))
    XCTAssertNil(ProtoValue.uintValue(100).convertTo(fieldDescriptor: stringDescriptor))
    XCTAssertNil(ProtoValue.floatValue(3.14).convertTo(fieldDescriptor: stringDescriptor))
    XCTAssertNil(ProtoValue.doubleValue(2.71828).convertTo(fieldDescriptor: stringDescriptor))
    XCTAssertNil(ProtoValue.boolValue(true).convertTo(fieldDescriptor: stringDescriptor))
    XCTAssertNil(ProtoValue.bytesValue(Data([0x01, 0x02, 0x03])).convertTo(fieldDescriptor: stringDescriptor))
}
```

### Сравнение со спецификацией
- Корректно реализует правила для строковых значений
- Правильно обрабатывает все типы согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Код теста:
```swift
// ... код теста из предыдущего раздела ...
```

## testConvertToBytes
### Сравнение с protoc
- Корректно проверяет, что protoc не допускает неявные преобразования для bytes
- Правильно обрабатывает только точное соответствие типов (bytes -> bytes)
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Пример поведения protoc:
```protobuf
message Test {
  bytes value = 1;
}
```
```python
# Это не скомпилируется
test.value = "Hello"  # Error: Cannot assign string to bytes
test.value = 42       # Error: Cannot assign int to bytes
```
- Код теста:
```swift
func testConvertToBytes() {
    let bytesDescriptor = ProtoFieldDescriptor(
      name: "bytes_field",
      number: 1,
      type: .bytes,
      isRepeated: false,
      isMap: false
    )
    
    // Valid conversions - protoc allows same type
    XCTAssertEqual(ProtoValue.bytesValue(Data([0x01, 0x02, 0x03])).convertTo(fieldDescriptor: bytesDescriptor)?.getBytes(), Data([0x01, 0x02, 0x03]))
    
    // Invalid conversions - protoc doesn't allow implicit conversions
    XCTAssertNil(ProtoValue.stringValue("Hello").convertTo(fieldDescriptor: bytesDescriptor))
    XCTAssertNil(ProtoValue.intValue(42).convertTo(fieldDescriptor: bytesDescriptor))
    XCTAssertNil(ProtoValue.uintValue(42).convertTo(fieldDescriptor: bytesDescriptor))
    XCTAssertNil(ProtoValue.floatValue(42.5).convertTo(fieldDescriptor: bytesDescriptor))
    XCTAssertNil(ProtoValue.doubleValue(42.5).convertTo(fieldDescriptor: bytesDescriptor))
    XCTAssertNil(ProtoValue.boolValue(true).convertTo(fieldDescriptor: bytesDescriptor))
}
```

### Сравнение со спецификацией
- Корректно реализует правила для байтовых значений
- Правильно обрабатывает все типы согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Код теста:
```swift
// ... код теста из предыдущего раздела ...
```

## testConvertToEnum
### Сравнение с protoc
- Корректно проверяет, что protoc не допускает неявные преобразования для enum
- Правильно обрабатывает только точное соответствие типов (enum -> enum)
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Пример поведения protoc:
```protobuf
enum TestEnum {
  TEST_VALUE = 1;
}
message Test {
  TestEnum value = 1;
}
```
```python
# Это не скомпилируется
test.value = 1           # Error: Cannot assign int to enum
test.value = "TEST_VALUE" # Error: Cannot assign string to enum
```
- Код теста:
```swift
func testConvertToEnum() {
    let enumDescriptor = ProtoEnumDescriptor(
      name: "TestEnum",
      values: [
        ProtoEnumValueDescriptor(name: "TEST_VALUE", number: 1)
      ]
    )
    let enumFieldDescriptor = ProtoFieldDescriptor(
      name: "enum_field",
      number: 1,
      type: .enum(enumDescriptor),
      isRepeated: false,
      isMap: false
    )
    
    // Valid conversions - protoc allows same type
    XCTAssertNotNil(ProtoValue.enumValue(name: "TEST_VALUE", number: 1, enumDescriptor: enumDescriptor)
      .convertTo(fieldDescriptor: enumFieldDescriptor))
    
    // Invalid conversions - protoc doesn't allow implicit conversions
    XCTAssertNil(ProtoValue.intValue(1).convertTo(fieldDescriptor: enumFieldDescriptor))
    XCTAssertNil(ProtoValue.stringValue("TEST_VALUE").convertTo(fieldDescriptor: enumFieldDescriptor))
}
```

### Сравнение со спецификацией
- Корректно реализует правила для enum значений
- Правильно обрабатывает все типы согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Код теста:
```swift
// ... код теста из предыдущего раздела ...
```

## testConvertToMap
### Сравнение с protoc
- Корректно проверяет, что protoc не допускает неявные преобразования для map
- Правильно обрабатывает только точное соответствие типов (map -> map)
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Пример поведения protoc:
```protobuf
message Test {
  map<string, int32> value = 1;
}
```
```python
# Это не скомпилируется
test.value = {}  # Error: Cannot assign dict to map
test.value = []  # Error: Cannot assign list to map
```
- Код теста:
```swift
func testConvertToMap() {
    let mapFieldDescriptor = ProtoFieldDescriptor(
      name: "map_field",
      number: 1,
      type: .message(nil),
      isRepeated: false,
      isMap: true
    )
    
    // Valid conversions - protoc allows same type
    let mapValue = ProtoValue.mapValue(["key1": .intValue(1), "key2": .intValue(2)])
    XCTAssertNotNil(mapValue.convertTo(fieldDescriptor: mapFieldDescriptor))
    
    // Invalid conversions - protoc doesn't allow implicit conversions
    XCTAssertNil(ProtoValue.intValue(42).convertTo(fieldDescriptor: mapFieldDescriptor))
    XCTAssertNil(ProtoValue.stringValue("{}").convertTo(fieldDescriptor: mapFieldDescriptor))
}
```

### Сравнение со спецификацией
- Корректно реализует правила для map значений
- Правильно обрабатывает все типы согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Код теста:
```swift
// ... код теста из предыдущего раздела ...
```

## testConvertToMessage
### Сравнение с protoc
- Корректно проверяет, что protoc не допускает неявные преобразования для message
- Правильно обрабатывает только точное соответствие типов (message -> message)
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#messages
- Пример поведения protoc:
```protobuf
message TestMessage {
  int32 value = 1;
}
message Test {
  TestMessage value = 1;
}
```
```python
# Это не скомпилируется
test.value = {}  # Error: Cannot assign dict to message
test.value = []  # Error: Cannot assign list to message
```
- Код теста:
```swift
func testConvertToMessage() {
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [],
      enums: [],
      nestedMessages: []
    )
    let messageFieldDescriptor = ProtoFieldDescriptor(
      name: "message_field",
      number: 1,
      type: .message(messageDescriptor),
      isRepeated: false,
      isMap: false
    )
    
    // Valid conversions - protoc allows same type
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    XCTAssertNotNil(ProtoValue.messageValue(message).convertTo(fieldDescriptor: messageFieldDescriptor))
    
    // Invalid conversions - protoc doesn't allow implicit conversions
    XCTAssertNil(ProtoValue.stringValue("{}").convertTo(fieldDescriptor: messageFieldDescriptor))
    XCTAssertNil(ProtoValue.intValue(42).convertTo(fieldDescriptor: messageFieldDescriptor))
}
```

### Сравнение со спецификацией
- Корректно реализует правила для message значений
- Правильно обрабатывает все типы согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#messages
- Код теста:
```swift
// ... код теста из предыдущего раздела ...
```

## testConvertToRepeated
### Сравнение с protoc
- Корректно проверяет, что protoc не допускает неявные преобразования для repeated
- Правильно обрабатывает только точное соответствие типов (repeated -> repeated)
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#specifying_field_rules
- Пример поведения protoc:
```protobuf
message Test {
  repeated int32 value = 1;
}
```
```python
# Это не скомпилируется
test.value = 42     # Error: Cannot assign int to repeated field
test.value = "42"   # Error: Cannot assign string to repeated field
```
- Код теста:
```swift
func testConvertToRepeated() {
    // Only same type conversion is allowed
    let values = [ProtoValue.intValue(1), ProtoValue.intValue(2), ProtoValue.intValue(3)]
    let repeatedFieldDescriptor = ProtoFieldDescriptor(
      name: "repeated_int32",
      number: 1,
      type: .int32,
      isRepeated: true,
      isMap: false
    )
    XCTAssertNotNil(ProtoValue.repeatedValue(values).convertTo(fieldDescriptor: repeatedFieldDescriptor))
    
    // Invalid conversions - protoc doesn't allow implicit conversions
    XCTAssertNil(ProtoValue.intValue(42).convertTo(fieldDescriptor: repeatedFieldDescriptor))
    XCTAssertNil(ProtoValue.stringValue("[1, 2, 3]").convertTo(fieldDescriptor: repeatedFieldDescriptor))
}
```

### Сравнение со спецификацией
- Корректно реализует правила для repeated полей
- Правильно обрабатывает все типы согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#specifying_field_rules
- Код теста:
```swift
// ... код теста из предыдущего раздела ...
``` 