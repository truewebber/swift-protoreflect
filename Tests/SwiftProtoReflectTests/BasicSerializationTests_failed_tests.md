# BasicSerializationTests.swift - Тесты, требующие доработки

## testFieldValidation
### Сравнение с protoc
- Не проверяет все случаи невалидных значений для каждого типа поля
- Отсутствует проверка валидации wire format для невалидных значений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Код теста:
```swift
func testFieldValidation() {
    // Create a message descriptor with various field types
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "ValidationTestMessage",
      fields: [
        ProtoFieldDescriptor(name: "int_field", number: 1, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "string_field", number: 2, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "float_field", number: 3, type: .float, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a message with valid values
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(fieldName: "int_field", value: .intValue(42))
    message.set(fieldName: "string_field", value: .stringValue("Hello"))
    message.set(fieldName: "float_field", value: .floatValue(3.14))

    // Serialization should succeed with valid values
    let validData = ProtoWireFormat.marshal(message: message)
    XCTAssertNotNil(validData, "Serialization should succeed with valid field values")

    // Create a new message for testing invalid values
    let invalidMessage1 = ProtoDynamicMessage(descriptor: messageDescriptor)

    // Use direct field access to bypass validation
    if let field = messageDescriptor.field(named: "int_field") {
      invalidMessage1.set(field: field, value: .stringValue("not an int"))
    }
    invalidMessage1.set(fieldName: "string_field", value: .stringValue("Hello"))
    invalidMessage1.set(fieldName: "float_field", value: .floatValue(3.14))

    // Serialization should fail with invalid values
    let invalidData1 = ProtoWireFormat.marshal(message: invalidMessage1)
    XCTAssertNil(invalidData1, "Serialization should fail with invalid field values")

    // Create another message for testing different invalid values
    let invalidMessage2 = ProtoDynamicMessage(descriptor: messageDescriptor)
    invalidMessage2.set(fieldName: "int_field", value: .intValue(42))
    invalidMessage2.set(fieldName: "string_field", value: .stringValue("Hello"))

    // Use direct field access to bypass validation
    if let field = messageDescriptor.field(named: "float_field") {
      invalidMessage2.set(field: field, value: .boolValue(true))
    }

    // Serialization should fail with invalid values
    let invalidData2 = ProtoWireFormat.marshal(message: invalidMessage2)
    XCTAssertNil(invalidData2, "Serialization should fail with invalid field values")
}
```

### Сравнение со спецификацией
- Не полностью соответствует спецификации в части валидации типов
- Отсутствует проверка всех граничных случаев для числовых типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Рекомендации по исправлению:
  1. Добавить проверку всех возможных невалидных значений для каждого типа
  2. Добавить проверку граничных случаев для числовых типов
  3. Добавить проверку валидации wire format
  4. Добавить проверку корректности сообщений об ошибках

## testMapFieldSerialization
### Сравнение с protoc
- Не проверяет все типы ключей и значений для map fields
- Отсутствует проверка валидации map entry messages
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Код теста:
```swift
func testMapFieldSerialization() {
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
      fullName: "TestMessage.StringToIntMapEntry",
      fields: [keyFieldDescriptor, valueFieldDescriptor],
      enums: [],
      nestedMessages: []
    )

    // Create a field descriptor for a map field
    let fieldDescriptor = ProtoFieldDescriptor(
      name: "string_to_int_map",
      number: 21,
      type: .message(mapEntryDescriptor),
      isRepeated: false,
      isMap: true,
      messageType: mapEntryDescriptor
    )

    // Create a map value
    let mapValue = ProtoValue.mapValue([
      "one": .intValue(1),
      "two": .intValue(2),
    ])

    // Encode the field
    var data = Data()
    XCTAssertNoThrow(try ProtoWireFormat.encodeField(field: fieldDescriptor, value: mapValue, to: &data))

    // Verify the encoded data contains the expected number of bytes
    // We can't predict the exact byte sequence because map entries can be in any order
    XCTAssertTrue(data.count > 0, "Encoded map field should not be empty")

    // Decode the field to verify it works
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [fieldDescriptor],
      enums: [],
      nestedMessages: [mapEntryDescriptor]
    )

    guard
      let decodedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Unmarshal should succeed")
      return
    }

    let decodedMap = decodedMessage.get(field: fieldDescriptor)?.getMap()
    XCTAssertEqual(decodedMap?.count, 2, "Decoded map should have 2 entries")
    XCTAssertEqual(decodedMap?["one"]?.getInt(), 1)
    XCTAssertEqual(decodedMap?["two"]?.getInt(), 2)
}
```

### Сравнение со спецификацией
- Не полностью соответствует спецификации в части map fields
- Отсутствует проверка всех возможных комбинаций типов ключей и значений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Рекомендации по исправлению:
  1. Добавить проверку всех возможных типов ключей и значений
  2. Добавить проверку валидации map entry messages
  3. Добавить проверку граничных случаев для map fields
  4. Добавить проверку корректности сериализации/десериализации map fields

## testNestedMessageSerialization
### Сравнение с protoc
- Не проверяет глубокую вложенность сообщений
- Отсутствует проверка циклических зависимостей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#nested
- Код теста:
```swift
func testNestedMessageSerialization() {
    // Create a nested message descriptor
    let addressDescriptor = ProtoMessageDescriptor(
      fullName: "Address",
      fields: [
        ProtoFieldDescriptor(name: "street", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "city", number: 2, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "zip", number: 3, type: .string, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a message descriptor with a nested message field
    let personDescriptor = ProtoMessageDescriptor(
      fullName: "Person",
      fields: [
        ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(
          name: "address",
          number: 2,
          type: .message(addressDescriptor),
          isRepeated: false,
          isMap: false,
          messageType: addressDescriptor
        ),
      ],
      enums: [],
      nestedMessages: [addressDescriptor]
    )

    // Create the nested address message
    let address = ProtoDynamicMessage(descriptor: addressDescriptor)
    address.set(fieldName: "street", value: .stringValue("123 Main St"))
    address.set(fieldName: "city", value: .stringValue("Anytown"))
    address.set(fieldName: "zip", value: .stringValue("12345"))

    // Create the person message with the nested address
    let person = ProtoDynamicMessage(descriptor: personDescriptor)
    person.set(fieldName: "name", value: .stringValue("John Doe"))
    person.set(fieldName: "address", value: .messageValue(address))

    // Serialize the message
    guard let data = ProtoWireFormat.marshal(message: person) else {
      XCTFail("Failed to marshal message with nested message")
      return
    }

    // Deserialize the message
    guard
      let deserializedPerson = ProtoWireFormat.unmarshal(data: data, messageDescriptor: personDescriptor)
        as? ProtoDynamicMessage
    else {
      XCTFail("Failed to unmarshal message with nested message")
      return
    }

    // Verify the top-level field
    XCTAssertEqual(deserializedPerson.get(fieldName: "name")?.getString(), "John Doe")

    // Verify the nested message field
    guard let addressValue = deserializedPerson.get(fieldName: "address") else {
      XCTFail("Address field should be present")
      return
    }

    guard let addressMessage = addressValue.getMessage() as? ProtoDynamicMessage else {
      XCTFail("Address field should be a message value")
      return
    }

    XCTAssertEqual(addressMessage.get(fieldName: "street")?.getString(), "123 Main St")
    XCTAssertEqual(addressMessage.get(fieldName: "city")?.getString(), "Anytown")
    XCTAssertEqual(addressMessage.get(fieldName: "zip")?.getString(), "12345")
}
```

### Сравнение со спецификацией
- Не полностью соответствует спецификации в части вложенных сообщений
- Отсутствует проверка всех возможных сценариев вложенности
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#nested
- Рекомендации по исправлению:
  1. Добавить проверку глубокой вложенности сообщений
  2. Добавить проверку циклических зависимостей
  3. Добавить проверку валидации вложенных сообщений
  4. Добавить проверку корректности сериализации/десериализации вложенных сообщений

## Отсутствующие тесты

### testUnknownFields
- Описание: Должен проверять корректную обработку неизвестных полей при десериализации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#unknowns
- Пример кода:
```swift
func testUnknownFields() {
    // Create a message descriptor with some fields
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "known_field", number: 1, type: .int32, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Create serialized data with unknown fields
    let serializedData = Data([
      8, 42,  // known_field = 42
      16, 1,  // unknown_field = 1
      24, 2,  // another_unknown_field = 2
    ])

    // Deserialize the message
    guard let message = ProtoWireFormat.unmarshal(data: serializedData, messageDescriptor: messageDescriptor) as? ProtoDynamicMessage else {
      XCTFail("Failed to unmarshal message with unknown fields")
      return
    }

    // Verify known field
    XCTAssertEqual(message.get(fieldName: "known_field")?.getInt(), 42)

    // Verify unknown fields are preserved
    let unknownFields = message.unknownFields
    XCTAssertEqual(unknownFields.count, 2)
    XCTAssertEqual(unknownFields[16]?.getInt(), 1)
    XCTAssertEqual(unknownFields[24]?.getInt(), 2)
}
```

### testOneofFields
- Описание: Должен проверять корректную работу с oneof полями
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#oneof
- Пример кода:
```swift
func testOneofFields() {
    // Create a message descriptor with a oneof field
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "age", number: 2, type: .int32, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: [],
      oneofs: [
        ProtoOneofDescriptor(
          name: "test_oneof",
          fields: [
            ProtoFieldDescriptor(name: "string_field", number: 3, type: .string, isRepeated: false, isMap: false),
            ProtoFieldDescriptor(name: "int_field", number: 4, type: .int32, isRepeated: false, isMap: false),
          ]
        ),
      ]
    )

    // Create a message with oneof field
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(fieldName: "name", value: .stringValue("John"))
    message.set(fieldName: "age", value: .intValue(30))
    message.set(fieldName: "string_field", value: .stringValue("test"))

    // Verify oneof field behavior
    XCTAssertEqual(message.get(fieldName: "string_field")?.getString(), "test")
    XCTAssertNil(message.get(fieldName: "int_field"))

    // Set another oneof field
    message.set(fieldName: "int_field", value: .intValue(42))

    // Verify previous oneof field is cleared
    XCTAssertNil(message.get(fieldName: "string_field"))
    XCTAssertEqual(message.get(fieldName: "int_field")?.getInt(), 42)
}
```

### testExtensions
- Описание: Должен проверять корректную работу с extension полями
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#extensions
- Пример кода:
```swift
func testExtensions() {
    // Create a message descriptor with extension fields
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "base_field", number: 1, type: .int32, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: [],
      extensions: [
        ProtoFieldDescriptor(name: "extension_field", number: 100, type: .string, isRepeated: false, isMap: false),
      ]
    )

    // Create a message with extension field
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(fieldName: "base_field", value: .intValue(42))
    message.set(fieldName: "extension_field", value: .stringValue("extension value"))

    // Verify extension field
    XCTAssertEqual(message.get(fieldName: "extension_field")?.getString(), "extension value")

    // Serialize and deserialize
    guard let data = ProtoWireFormat.marshal(message: message) else {
      XCTFail("Failed to marshal message with extension")
      return
    }

    guard let deserializedMessage = ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor) as? ProtoDynamicMessage else {
      XCTFail("Failed to unmarshal message with extension")
      return
    }

    // Verify extension field is preserved
    XCTAssertEqual(deserializedMessage.get(fieldName: "extension_field")?.getString(), "extension value")
}
``` 