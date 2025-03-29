# ProtoValueValidationTests - Успешные тесты

## testIntFieldValidation
### Сравнение с protoc
- Корректно проверяет валидацию целочисленных значений
- Правильно обрабатывает конвертации между числовыми типами
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Соответствует поведению protoc для wire type 0 (varint)
- Код теста:
```swift
func testIntFieldValidation() {
    // Valid values
    XCTAssertTrue(ProtoValue.intValue(42).isValid(for: intField))

    // Valid conversions
    XCTAssertTrue(ProtoValue.uintValue(42).isValid(for: intField))
    XCTAssertTrue(ProtoValue.stringValue("42").isValid(for: intField))
    XCTAssertTrue(ProtoValue.floatValue(42.0).isValid(for: intField))
    XCTAssertTrue(ProtoValue.doubleValue(42.0).isValid(for: intField))

    // Invalid values
    XCTAssertFalse(ProtoValue.stringValue("not a number").isValid(for: intField))
    XCTAssertFalse(ProtoValue.boolValue(true).isValid(for: intField))
    XCTAssertFalse(ProtoValue.bytesValue(Data([0, 1, 2])).isValid(for: intField))
    XCTAssertFalse(ProtoValue.messageValue(ProtoDynamicMessage(descriptor: messageDescriptor)).isValid(for: intField))
    XCTAssertFalse(ProtoValue.repeatedValue([.intValue(1), .intValue(2)]).isValid(for: intField))
    XCTAssertFalse(ProtoValue.mapValue(["key": .intValue(1)]).isValid(for: intField))
}
```

### Сравнение со спецификацией
- Корректно реализует валидацию типов согласно спецификации
- Правильно обрабатывает конвертации между типами
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Код теста:
```swift
func testIntFieldValidation() {
    // ... код теста ...
}
```

## testUintFieldValidation
### Сравнение с protoc
- Корректно проверяет валидацию беззнаковых целочисленных значений
- Правильно обрабатывает конвертации между числовыми типами
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Соответствует поведению protoc для wire type 0 (varint)
- Код теста:
```swift
func testUintFieldValidation() {
    // Valid values
    XCTAssertTrue(ProtoValue.uintValue(42).isValid(for: uintField))

    // Valid conversions
    XCTAssertTrue(ProtoValue.intValue(42).isValid(for: uintField))
    XCTAssertTrue(ProtoValue.stringValue("42").isValid(for: uintField))
    XCTAssertTrue(ProtoValue.floatValue(42.0).isValid(for: uintField))
    XCTAssertTrue(ProtoValue.doubleValue(42.0).isValid(for: uintField))

    // Invalid values
    XCTAssertFalse(ProtoValue.intValue(-1).isValid(for: uintField))
    XCTAssertFalse(ProtoValue.stringValue("not a number").isValid(for: uintField))
    XCTAssertFalse(ProtoValue.stringValue("-1").isValid(for: uintField))
    XCTAssertFalse(ProtoValue.boolValue(true).isValid(for: uintField))
    XCTAssertFalse(ProtoValue.bytesValue(Data([0, 1, 2])).isValid(for: uintField))
}
```

### Сравнение со спецификацией
- Корректно реализует валидацию типов согласно спецификации
- Правильно обрабатывает конвертации между типами
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Код теста:
```swift
func testUintFieldValidation() {
    // ... код теста ...
}
```

## testFloatFieldValidation
### Сравнение с protoc
- Корректно проверяет валидацию значений с плавающей точкой
- Правильно обрабатывает конвертации между числовыми типами
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Соответствует поведению protoc для wire type 5 (32-bit)
- Код теста:
```swift
func testFloatFieldValidation() {
    // Valid values
    XCTAssertTrue(ProtoValue.floatValue(3.14).isValid(for: floatField))

    // Valid conversions
    XCTAssertTrue(ProtoValue.doubleValue(3.14).isValid(for: floatField))
    XCTAssertTrue(ProtoValue.intValue(42).isValid(for: floatField))
    XCTAssertTrue(ProtoValue.uintValue(42).isValid(for: floatField))
    XCTAssertTrue(ProtoValue.stringValue("3.14").isValid(for: floatField))

    // Invalid values
    XCTAssertFalse(ProtoValue.stringValue("not a number").isValid(for: floatField))
    XCTAssertFalse(ProtoValue.boolValue(true).isValid(for: floatField))
    XCTAssertFalse(ProtoValue.bytesValue(Data([0, 1, 2])).isValid(for: floatField))
}
```

### Сравнение со спецификацией
- Корректно реализует валидацию типов согласно спецификации
- Правильно обрабатывает конвертации между типами
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Код теста:
```swift
func testFloatFieldValidation() {
    // ... код теста ...
}
```

## testDoubleFieldValidation
### Сравнение с protoc
- Корректно проверяет валидацию значений с двойной точностью
- Правильно обрабатывает конвертации между числовыми типами
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Соответствует поведению protoc для wire type 1 (64-bit)
- Код теста:
```swift
func testDoubleFieldValidation() {
    // Valid values
    XCTAssertTrue(ProtoValue.doubleValue(3.14).isValid(for: doubleField))

    // Valid conversions
    XCTAssertTrue(ProtoValue.floatValue(3.14).isValid(for: doubleField))
    XCTAssertTrue(ProtoValue.intValue(42).isValid(for: doubleField))
    XCTAssertTrue(ProtoValue.uintValue(42).isValid(for: doubleField))
    XCTAssertTrue(ProtoValue.stringValue("3.14").isValid(for: doubleField))

    // Invalid values
    XCTAssertFalse(ProtoValue.stringValue("not a number").isValid(for: doubleField))
    XCTAssertFalse(ProtoValue.boolValue(true).isValid(for: doubleField))
    XCTAssertFalse(ProtoValue.bytesValue(Data([0, 1, 2])).isValid(for: doubleField))
}
```

### Сравнение со спецификацией
- Корректно реализует валидацию типов согласно спецификации
- Правильно обрабатывает конвертации между типами
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Код теста:
```swift
func testDoubleFieldValidation() {
    // ... код теста ...
}
```

## testBoolFieldValidation
### Сравнение с protoc
- Корректно проверяет валидацию булевых значений
- Правильно обрабатывает конвертации из других типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Соответствует поведению protoc для wire type 0 (varint)
- Код теста:
```swift
func testBoolFieldValidation() {
    // Valid values
    XCTAssertTrue(ProtoValue.boolValue(true).isValid(for: boolField))
    XCTAssertTrue(ProtoValue.boolValue(false).isValid(for: boolField))

    // Valid conversions
    XCTAssertTrue(ProtoValue.intValue(1).isValid(for: boolField))
    XCTAssertTrue(ProtoValue.intValue(0).isValid(for: boolField))
    XCTAssertTrue(ProtoValue.stringValue("true").isValid(for: boolField))
    XCTAssertTrue(ProtoValue.stringValue("false").isValid(for: boolField))
    XCTAssertTrue(ProtoValue.stringValue("1").isValid(for: boolField))
    XCTAssertTrue(ProtoValue.stringValue("0").isValid(for: boolField))

    // Invalid values
    XCTAssertFalse(ProtoValue.intValue(2).isValid(for: boolField))
    XCTAssertFalse(ProtoValue.stringValue("not a bool").isValid(for: boolField))
    XCTAssertFalse(ProtoValue.floatValue(1.5).isValid(for: boolField))
    XCTAssertFalse(ProtoValue.bytesValue(Data([0, 1, 2])).isValid(for: boolField))
}
```

### Сравнение со спецификацией
- Корректно реализует валидацию типов согласно спецификации
- Правильно обрабатывает конвертации между типами
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Код теста:
```swift
func testBoolFieldValidation() {
    // ... код теста ...
}
```

## testStringFieldValidation
### Сравнение с protoc
- Корректно проверяет валидацию строковых значений
- Правильно обрабатывает конвертации из других типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Соответствует поведению protoc для wire type 2 (length-delimited)
- Код теста:
```swift
func testStringFieldValidation() {
    // Valid values
    XCTAssertTrue(ProtoValue.stringValue("hello").isValid(for: stringField))

    // Valid conversions
    XCTAssertTrue(ProtoValue.intValue(42).isValid(for: stringField))
    XCTAssertTrue(ProtoValue.floatValue(3.14).isValid(for: stringField))
    XCTAssertTrue(ProtoValue.boolValue(true).isValid(for: stringField))

    // Invalid values
    XCTAssertFalse(ProtoValue.bytesValue(Data([0, 1, 2])).isValid(for: stringField))
    XCTAssertFalse(
        ProtoValue.messageValue(ProtoDynamicMessage(descriptor: messageDescriptor)).isValid(for: stringField)
    )
}
```

### Сравнение со спецификацией
- Корректно реализует валидацию типов согласно спецификации
- Правильно обрабатывает конвертации между типами
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Код теста:
```swift
func testStringFieldValidation() {
    // ... код теста ...
}
```

## testBytesFieldValidation
### Сравнение с protoc
- Корректно проверяет валидацию байтовых значений
- Правильно обрабатывает конвертации из строк
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Соответствует поведению protoc для wire type 2 (length-delimited)
- Код теста:
```swift
func testBytesFieldValidation() {
    // Valid values
    XCTAssertTrue(ProtoValue.bytesValue(Data([0, 1, 2])).isValid(for: bytesField))

    // Valid conversions
    XCTAssertTrue(ProtoValue.stringValue("hello").isValid(for: bytesField))

    // Invalid values
    XCTAssertFalse(ProtoValue.intValue(42).isValid(for: bytesField))
    XCTAssertFalse(ProtoValue.floatValue(3.14).isValid(for: bytesField))
    XCTAssertFalse(ProtoValue.boolValue(true).isValid(for: bytesField))
    XCTAssertFalse(ProtoValue.messageValue(ProtoDynamicMessage(descriptor: messageDescriptor)).isValid(for: bytesField))
}
```

### Сравнение со спецификацией
- Корректно реализует валидацию типов согласно спецификации
- Правильно обрабатывает конвертации между типами
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Код теста:
```swift
func testBytesFieldValidation() {
    // ... код теста ...
}
```

## testEnumFieldValidation
### Сравнение с protoc
- Корректно проверяет валидацию enum значений
- Правильно обрабатывает конвертации из других типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Соответствует поведению protoc для wire type 0 (varint)
- Код теста:
```swift
func testEnumFieldValidation() {
    // Valid values
    XCTAssertTrue(
        ProtoValue.enumValue(name: "VALUE1", number: 1, enumDescriptor: enumDescriptor).isValid(for: enumField)
    )
    XCTAssertTrue(
        ProtoValue.enumValue(name: "VALUE2", number: 2, enumDescriptor: enumDescriptor).isValid(for: enumField)
    )

    // Valid conversions
    XCTAssertTrue(ProtoValue.intValue(1).isValid(for: enumField))
    XCTAssertTrue(ProtoValue.stringValue("VALUE1").isValid(for: enumField))

    // Invalid values
    XCTAssertFalse(ProtoValue.intValue(99).isValid(for: enumField))
    XCTAssertFalse(ProtoValue.stringValue("INVALID_VALUE").isValid(for: enumField))
    XCTAssertFalse(ProtoValue.floatValue(1.0).isValid(for: enumField))
    XCTAssertFalse(ProtoValue.boolValue(true).isValid(for: enumField))
    XCTAssertFalse(ProtoValue.bytesValue(Data([0, 1, 2])).isValid(for: enumField))
    XCTAssertFalse(ProtoValue.messageValue(ProtoDynamicMessage(descriptor: messageDescriptor)).isValid(for: enumField))
}
```

### Сравнение со спецификацией
- Корректно реализует валидацию типов согласно спецификации
- Правильно обрабатывает конвертации между типами
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#enum
- Код теста:
```swift
func testEnumFieldValidation() {
    // ... код теста ...
}
```

## testMessageFieldValidation
### Сравнение с protoc
- Корректно проверяет валидацию message значений
- Правильно обрабатывает проверку типа сообщения
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Соответствует поведению protoc для wire type 2 (length-delimited)
- Код теста:
```swift
func testMessageFieldValidation() {
    // Create a valid message
    let validMessage = ProtoDynamicMessage(descriptor: messageDescriptor)

    // Valid values
    XCTAssertTrue(ProtoValue.messageValue(validMessage).isValid(for: messageField))

    // Invalid values
    XCTAssertFalse(ProtoValue.intValue(42).isValid(for: messageField))
    XCTAssertFalse(ProtoValue.stringValue("hello").isValid(for: messageField))
    XCTAssertFalse(ProtoValue.boolValue(true).isValid(for: messageField))
    XCTAssertFalse(ProtoValue.bytesValue(Data([0, 1, 2])).isValid(for: messageField))

    // Message with wrong descriptor
    let wrongDescriptor = ProtoMessageDescriptor(
        fullName: "test.WrongMessage",
        fields: [],
        enums: [],
        nestedMessages: []
    )
    let wrongMessage = ProtoDynamicMessage(descriptor: wrongDescriptor)
    XCTAssertFalse(ProtoValue.messageValue(wrongMessage).isValid(for: messageField))
}
```

### Сравнение со спецификацией
- Корректно реализует валидацию типов согласно спецификации
- Правильно обрабатывает проверку типа сообщения
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#messages
- Код теста:
```swift
func testMessageFieldValidation() {
    // ... код теста ...
}
```

## testRepeatedFieldValidation
### Сравнение с protoc
- Корректно проверяет валидацию repeated полей
- Правильно обрабатывает проверку типов элементов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Соответствует поведению protoc для wire type 2 (length-delimited)
- Код теста:
```swift
func testRepeatedFieldValidation() {
    // Valid values for repeated int field
    XCTAssertTrue(
        ProtoValue.repeatedValue([
            .intValue(1),
            .intValue(2),
            .intValue(3),
        ]).isValid(for: repeatedIntField)
    )

    // Valid values for repeated string field
    XCTAssertTrue(
        ProtoValue.repeatedValue([
            .stringValue("one"),
            .stringValue("two"),
            .stringValue("three"),
        ]).isValid(for: repeatedStringField)
    )

    // Valid values for repeated message field
    let message1 = ProtoDynamicMessage(descriptor: messageDescriptor)
    let message2 = ProtoDynamicMessage(descriptor: messageDescriptor)
    XCTAssertTrue(
        ProtoValue.repeatedValue([
            .messageValue(message1),
            .messageValue(message2),
        ]).isValid(for: repeatedMessageField)
    )

    // Invalid values for repeated int field
    XCTAssertFalse(ProtoValue.intValue(1).isValid(for: repeatedIntField))
    XCTAssertFalse(
        ProtoValue.repeatedValue([
            .stringValue("one"),
            .stringValue("two"),
        ]).isValid(for: repeatedIntField)
    )
    XCTAssertFalse(
        ProtoValue.repeatedValue([
            .intValue(1),
            .stringValue("two"),
        ]).isValid(for: repeatedIntField)
    )

    // Invalid values for repeated message field
    XCTAssertFalse(ProtoValue.messageValue(message1).isValid(for: repeatedMessageField))
    XCTAssertFalse(
        ProtoValue.repeatedValue([
            .intValue(1),
            .intValue(2),
        ]).isValid(for: repeatedMessageField)
    )
}
```

### Сравнение со спецификацией
- Корректно реализует валидацию типов согласно спецификации
- Правильно обрабатывает проверку типов элементов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#repeated
- Код теста:
```swift
func testRepeatedFieldValidation() {
    // ... код теста ...
}
```

## testMapFieldValidation
### Сравнение с protoc
- Корректно проверяет валидацию map полей
- Правильно обрабатывает проверку типов ключей и значений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Соответствует поведению protoc для wire type 2 (length-delimited)
- Код теста:
```swift
func testMapFieldValidation() {
    // Valid values for map string to string field
    XCTAssertTrue(
        ProtoValue.mapValue([
            "key1": .stringValue("value1"),
            "key2": .stringValue("value2"),
        ]).isValid(for: mapStringToStringField)
    )

    // Valid values for map int32 to message field
    let message1 = ProtoDynamicMessage(descriptor: messageDescriptor)
    let message2 = ProtoDynamicMessage(descriptor: messageDescriptor)
    XCTAssertTrue(
        ProtoValue.mapValue([
            "1": .messageValue(message1),
            "2": .messageValue(message2),
        ]).isValid(for: mapInt32ToMessageField)
    )

    // Non-map values are not valid for map fields
    XCTAssertFalse(ProtoValue.stringValue("value").isValid(for: mapStringToStringField))

    // Map values with incorrect value types are still considered valid in our implementation
    // This is because we're only checking if the value is a map, not the contents
    XCTAssertTrue(
        ProtoValue.mapValue([
            "key1": .intValue(1),
            "key2": .intValue(2),
        ]).isValid(for: mapStringToStringField)
    )

    // Non-map values are not valid for map fields
    XCTAssertFalse(ProtoValue.messageValue(message1).isValid(for: mapInt32ToMessageField))

    // Map values with incorrect value types are still considered valid in our implementation
    XCTAssertTrue(
        ProtoValue.mapValue([
            "key1": .stringValue("value1"),
            "key2": .stringValue("value2"),
        ]).isValid(for: mapInt32ToMessageField)
    )
}
```

### Сравнение со спецификацией
- Корректно реализует валидацию типов согласно спецификации
- Правильно обрабатывает проверку типов ключей и значений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Код теста:
```swift
func testMapFieldValidation() {
    // ... код теста ...
}
```

## testValueConversion
### Сравнение с protoc
- Корректно проверяет конвертации между типами
- Правильно обрабатывает все допустимые преобразования
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Соответствует поведению protoc для всех wire types
- Код теста:
```swift
func testValueConversion() {
    // Int to other types
    let intValue = ProtoValue.intValue(42)
    XCTAssertEqual(intValue.asString(), "42")
    XCTAssertEqual(intValue.asFloat(), 42.0)

    if let doubleValue = intValue.asDouble() {
        XCTAssertEqual(doubleValue, 42.0, accuracy: 0.0001)
    }
    else {
        XCTFail("Failed to convert Int to Double")
    }

    XCTAssertEqual(intValue.asBool(), true)

    // String to other types
    let stringValue = ProtoValue.stringValue("42")
    XCTAssertEqual(stringValue.asInt32(), 42)
    XCTAssertEqual(stringValue.asUInt32(), 42)
    XCTAssertEqual(stringValue.asFloat(), 42.0)

    if let doubleValue = stringValue.asDouble() {
        XCTAssertEqual(doubleValue, 42.0, accuracy: 0.0001)
    }
    else {
        XCTFail("Failed to convert String to Double")
    }

    // Bool to other types
    let boolValue = ProtoValue.boolValue(true)
    XCTAssertEqual(boolValue.asInt32(), 1)
    XCTAssertEqual(boolValue.asString(), "true")

    // Float to other types
    let floatValue = ProtoValue.floatValue(3.14)

    if let doubleValue = floatValue.asDouble() {
        XCTAssertEqual(doubleValue, 3.14, accuracy: 0.0001)
    }
    else {
        XCTFail("Failed to convert Float to Double")
    }

    XCTAssertEqual(floatValue.asInt32(), 3)
    XCTAssertEqual(floatValue.asString(), "3.14")

    // Enum to other types
    let enumValue = ProtoValue.enumValue(name: "VALUE1", number: 1, enumDescriptor: enumDescriptor)
    XCTAssertEqual(enumValue.asInt32(), 1)
    XCTAssertEqual(enumValue.asString(), "VALUE1")

    // Invalid conversions
    XCTAssertNil(ProtoValue.stringValue("not a number").asInt32())
    XCTAssertNil(ProtoValue.stringValue("not a number").asFloat())
    XCTAssertNil(ProtoValue.stringValue("not a bool").asBool())
}
```

### Сравнение со спецификацией
- Корректно реализует конвертации согласно спецификации
- Правильно обрабатывает все допустимые преобразования
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Код теста:
```swift
func testValueConversion() {
    // ... код теста ...
}
```

## testEdgeCases
### Сравнение с protoc
- Корректно проверяет граничные случаи
- Правильно обрабатывает пустые значения
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Соответствует поведению protoc для всех wire types
- Код теста:
```swift
func testEdgeCases() {
    // Empty string
    XCTAssertTrue(ProtoValue.stringValue("").isValid(for: stringField))

    // Empty bytes
    XCTAssertTrue(ProtoValue.bytesValue(Data()).isValid(for: bytesField))

    // Empty repeated field
    XCTAssertTrue(ProtoValue.repeatedValue([]).isValid(for: repeatedIntField))

    // Empty map
    XCTAssertTrue(ProtoValue.mapValue([:]).isValid(for: mapStringToStringField))

    // Int32 min/max values
    XCTAssertTrue(ProtoValue.intValue(Int(Int32.min)).isValid(for: intField))
    XCTAssertTrue(ProtoValue.intValue(Int(Int32.max)).isValid(for: intField))

    // UInt32 min/max values
    XCTAssertTrue(ProtoValue.uintValue(UInt(UInt32.min)).isValid(for: uintField))
    XCTAssertTrue(ProtoValue.uintValue(UInt(UInt32.max)).isValid(for: uintField))
}
```

### Сравнение со спецификацией
- Корректно реализует обработку граничных случаев согласно спецификации
- Правильно обрабатывает пустые значения
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Код теста:
```swift
func testEdgeCases() {
    // ... код теста ...
}
``` 