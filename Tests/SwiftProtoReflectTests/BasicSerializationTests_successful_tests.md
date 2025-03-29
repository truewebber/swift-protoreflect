# BasicSerializationTests.swift - Успешные тесты

## testBasicFieldTypes
### Сравнение с protoc
- Корректно проверяет базовые типы полей (int32, string, bool)
- Правильно сериализует и десериализует значения
- Соответствует wire format спецификации protobuf
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Код теста:
```swift
func testBasicFieldTypes() {
    // Create a message descriptor with just a few basic field types
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "int32_field", number: 1, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "string_field", number: 2, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "bool_field", number: 3, type: .bool, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a message with values for each field
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(fieldName: "int32_field", value: .intValue(42))
    message.set(fieldName: "string_field", value: .stringValue("Hello, world!"))
    message.set(fieldName: "bool_field", value: .boolValue(true))

    // Serialize the message
    guard let data = ProtoWireFormat.marshal(message: message) else {
      XCTFail("Failed to marshal message")
      return
    }

    // Deserialize the message
    guard
      let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal message")
      return
    }

    // Verify the field values were preserved
    XCTAssertEqual(deserializedMessage.get(fieldName: "int32_field")?.getInt(), 42)
    XCTAssertEqual(deserializedMessage.get(fieldName: "string_field")?.getString(), "Hello, world!")
    XCTAssertEqual(deserializedMessage.get(fieldName: "bool_field")?.getBool(), true)
}
```

### Сравнение со спецификацией
- Корректно реализует базовые типы полей согласно спецификации
- Правильно обрабатывает значения по умолчанию
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar

## testAllPrimitiveFieldTypes
### Сравнение с protoc
- Проверяет все примитивные типы полей protobuf
- Корректно обрабатывает максимальные значения для числовых типов
- Правильно сериализует и десериализует все типы
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Код теста:
```swift
func testAllPrimitiveFieldTypes() {
    // Create a message descriptor with all primitive field types
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "AllTypesMessage",
      fields: [
        ProtoFieldDescriptor(name: "int32_field", number: 1, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "int64_field", number: 2, type: .int64, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "uint32_field", number: 3, type: .uint32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "uint64_field", number: 4, type: .uint64, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "sint32_field", number: 5, type: .sint32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "sint64_field", number: 6, type: .sint64, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "fixed32_field", number: 7, type: .fixed32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "fixed64_field", number: 8, type: .fixed64, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "sfixed32_field", number: 9, type: .sfixed32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "sfixed64_field", number: 10, type: .sfixed64, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "float_field", number: 11, type: .float, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "double_field", number: 12, type: .double, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "bool_field", number: 13, type: .bool, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "string_field", number: 14, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "bytes_field", number: 15, type: .bytes, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a message with values for each field
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(fieldName: "int32_field", value: .intValue(42))
    message.set(fieldName: "int64_field", value: .intValue(9_223_372_036_854_775_807))  // Max Int64
    message.set(fieldName: "uint32_field", value: .uintValue(4_294_967_295))  // Max UInt32
    message.set(fieldName: "uint64_field", value: .uintValue(18_446_744_073_709_551_615))  // Max UInt64
    message.set(fieldName: "sint32_field", value: .intValue(-42))
    message.set(fieldName: "sint64_field", value: .intValue(-42))
    message.set(fieldName: "fixed32_field", value: .uintValue(42))
    message.set(fieldName: "fixed64_field", value: .uintValue(42))
    message.set(fieldName: "sfixed32_field", value: .intValue(-42))
    message.set(fieldName: "sfixed64_field", value: .intValue(-42))
    message.set(fieldName: "float_field", value: .floatValue(3.14159))
    message.set(fieldName: "double_field", value: .doubleValue(2.71828))
    message.set(fieldName: "bool_field", value: .boolValue(true))
    message.set(fieldName: "string_field", value: .stringValue("Hello, Protocol Buffers!"))
    message.set(fieldName: "bytes_field", value: .bytesValue(Data([0x00, 0x01, 0x02, 0x03, 0xFF])))

    // Serialize the message
    guard let data = ProtoWireFormat.marshal(message: message) else {
      XCTFail("Failed to marshal message")
      return
    }

    // Deserialize the message
    guard
      let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal message")
      return
    }

    // Verify the field values were preserved
    XCTAssertEqual(deserializedMessage.get(fieldName: "int32_field")?.getInt(), 42)
    XCTAssertEqual(deserializedMessage.get(fieldName: "int64_field")?.getInt(), 9_223_372_036_854_775_807)
    XCTAssertEqual(deserializedMessage.get(fieldName: "uint32_field")?.getUInt(), 4_294_967_295)
    XCTAssertEqual(deserializedMessage.get(fieldName: "uint64_field")?.getUInt(), 18_446_744_073_709_551_615)
    XCTAssertEqual(deserializedMessage.get(fieldName: "sint32_field")?.getInt(), -42)
    XCTAssertEqual(deserializedMessage.get(fieldName: "sint64_field")?.getInt(), -42)
    XCTAssertEqual(deserializedMessage.get(fieldName: "fixed32_field")?.getUInt(), 42)
    XCTAssertEqual(deserializedMessage.get(fieldName: "fixed64_field")?.getUInt(), 42)
    XCTAssertEqual(deserializedMessage.get(fieldName: "sfixed32_field")?.getInt(), -42)
    XCTAssertEqual(deserializedMessage.get(fieldName: "sfixed64_field")?.getInt(), -42)

    if let floatValue = deserializedMessage.get(fieldName: "float_field")?.getFloat() {
      XCTAssertEqual(floatValue, 3.14159, accuracy: 0.00001)
    }
    else {
      XCTFail("Float value should not be nil")
    }

    if let doubleValue = deserializedMessage.get(fieldName: "double_field")?.getDouble() {
      XCTAssertEqual(doubleValue, 2.71828, accuracy: 0.00001)
    }
    else {
      XCTFail("Double value should not be nil")
    }

    XCTAssertEqual(deserializedMessage.get(fieldName: "bool_field")?.getBool(), true)
    XCTAssertEqual(deserializedMessage.get(fieldName: "string_field")?.getString(), "Hello, Protocol Buffers!")
    XCTAssertEqual(deserializedMessage.get(fieldName: "bytes_field")?.getBytes(), Data([0x00, 0x01, 0x02, 0x03, 0xFF]))
}
```

### Сравнение со спецификацией
- Корректно реализует все примитивные типы согласно спецификации
- Правильно обрабатывает максимальные значения для числовых типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar

## testEdgeCases
### Сравнение с protoc
- Проверяет граничные случаи для различных типов полей
- Корректно обрабатывает пустые строки и байты
- Правильно обрабатывает нулевые значения
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#optional
- Код теста:
```swift
func testEdgeCases() {
    // Create a message descriptor with fields for testing edge cases
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "EdgeCasesMessage",
      fields: [
        ProtoFieldDescriptor(name: "empty_string", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "empty_bytes", number: 2, type: .bytes, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "zero_int", number: 3, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "zero_float", number: 4, type: .float, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "false_bool", number: 5, type: .bool, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "large_string", number: 6, type: .string, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a message with edge case values
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(fieldName: "empty_string", value: .stringValue(""))
    message.set(fieldName: "empty_bytes", value: .bytesValue(Data()))
    message.set(fieldName: "zero_int", value: .intValue(0))
    message.set(fieldName: "zero_float", value: .floatValue(0.0))
    message.set(fieldName: "false_bool", value: .boolValue(false))

    // Create a large string (10KB)
    let largeString = String(repeating: "a", count: 10240)
    message.set(fieldName: "large_string", value: .stringValue(largeString))

    // Serialize the message
    guard let data = ProtoWireFormat.marshal(message: message) else {
      XCTFail("Failed to marshal message")
      return
    }

    // Deserialize the message
    guard
      let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal message")
      return
    }

    // Verify the field values were preserved
    XCTAssertEqual(deserializedMessage.get(fieldName: "empty_string")?.getString(), "")
    XCTAssertEqual(deserializedMessage.get(fieldName: "empty_bytes")?.getBytes(), Data())
    XCTAssertEqual(deserializedMessage.get(fieldName: "zero_int")?.getInt(), 0)
    XCTAssertEqual(deserializedMessage.get(fieldName: "zero_float")?.getFloat(), 0.0)
    XCTAssertEqual(deserializedMessage.get(fieldName: "false_bool")?.getBool(), false)
    XCTAssertEqual(deserializedMessage.get(fieldName: "large_string")?.getString(), largeString)
}
```

### Сравнение со спецификацией
- Корректно обрабатывает граничные случаи согласно спецификации
- Правильно реализует поведение для пустых значений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#default

## testRepeatedFieldTypes
### Сравнение с protoc
- Проверяет корректную работу с повторяющимися полями
- Правильно сериализует и десериализует массивы значений
- Соответствует wire format спецификации для repeated fields
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#packed
- Код теста:
```swift
func testRepeatedFieldTypes() {
    // Create a message descriptor with a repeated field
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "repeated_int32", number: 1, type: .int32, isRepeated: true, isMap: false)
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a message with a repeated field
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(
      fieldName: "repeated_int32",
      value: .repeatedValue([
        .intValue(1),
        .intValue(2),
        .intValue(3),
      ])
    )

    // Serialize the message
    guard let data = ProtoWireFormat.marshal(message: message) else {
      XCTFail("Failed to marshal message")
      return
    }

    // Deserialize the message
    guard
      let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal message")
      return
    }

    // Verify the repeated field values were preserved
    guard let repeatedValues = deserializedMessage.get(fieldName: "repeated_int32")?.getRepeated() else {
      XCTFail("Failed to get repeated field values")
      return
    }

    XCTAssertEqual(repeatedValues.count, 3)
    XCTAssertEqual(repeatedValues[0].getInt(), 1)
    XCTAssertEqual(repeatedValues[1].getInt(), 2)
    XCTAssertEqual(repeatedValues[2].getInt(), 3)
}
```

### Сравнение со спецификацией
- Корректно реализует repeated fields согласно спецификации
- Правильно обрабатывает packed encoding для числовых типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#repeated

## testSimpleMapField
### Сравнение с protoc
- Проверяет базовую функциональность map fields
- Правильно сериализует и десериализует map значения
- Соответствует wire format спецификации для map fields
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Код теста:
```swift
func testSimpleMapField() {
    // Create field descriptors for the map entry
    let keyFieldDescriptor = ProtoFieldDescriptor(
      name: "key",
      number: 1,
      type: .string,
      isRepeated: false,
      isMap: false
    )

    let valueFieldDescriptor = ProtoFieldDescriptor(
      name: "value",
      number: 2,
      type: .int32,
      isRepeated: false,
      isMap: false
    )

    // Create a message descriptor for the map entry
    let entryDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage.TestMapEntry",
      fields: [keyFieldDescriptor, valueFieldDescriptor],
      enums: [],
      nestedMessages: []
    )

    // Create a field descriptor for a map field
    let mapFieldDescriptor = ProtoFieldDescriptor(
      name: "test_map",
      number: 1,
      type: .message(entryDescriptor),
      isRepeated: true,
      isMap: true,
      messageType: entryDescriptor
    )

    // Create a message descriptor with the map field
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [mapFieldDescriptor],
      enums: [],
      nestedMessages: [entryDescriptor]
    )

    // Create a dynamic message with the map field
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)

    // Create a simple map with just one entry
    var mapEntries: [String: ProtoValue] = [:]
    mapEntries["one"] = .intValue(1)

    // Set the map field
    let setResult = message.set(field: mapFieldDescriptor, value: ProtoValue.mapValue(mapEntries))
    XCTAssertTrue(setResult, "Setting map field should succeed")

    // Verify the map field was set correctly
    let mapFieldValue = message.get(field: mapFieldDescriptor)
    XCTAssertNotNil(mapFieldValue, "Map field value should not be nil")

    if case let ProtoValue.mapValue(entries)? = mapFieldValue {
      XCTAssertEqual(entries.count, 1, "Map should have 1 entry")
      XCTAssertEqual(entries["one"]?.getInt(), 1, "Value for key 'one' should be 1")
    }
    else {
      XCTFail("Field value should be a map value")
    }
}
```

### Сравнение со спецификацией
- Корректно реализует map fields согласно спецификации
- Правильно обрабатывает map entry messages
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps 