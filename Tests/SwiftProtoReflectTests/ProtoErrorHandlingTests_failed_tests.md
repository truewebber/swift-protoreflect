# ProtoErrorHandlingTests - Неуспешные тесты

## testInvalidFieldTypeError
### Сравнение с protoc
- Не полностью соответствует поведению protoc
- Protoc предоставляет более детальную информацию об ошибке типа
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Код теста:
```swift
func testInvalidFieldTypeError() {
    let person = ProtoDynamicMessage(descriptor: personDescriptor)
    do {
        let complexValue = ProtoValue.repeatedValue([
            .intValue(1),
            .stringValue("test"),
        ])
        let _ = try person.trySet(fieldName: "name", value: complexValue)
        XCTFail("Expected error was not thrown")
    }
    catch let error as ProtoError {
        switch error {
        case .invalidFieldValue(let fieldName, let expectedType, let actualValue):
            XCTAssertEqual(fieldName, "name")
            XCTAssertEqual(expectedType, "string")
            XCTAssertTrue(actualValue.contains("["))
        default:
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
```

### Сравнение со спецификацией
- Не полностью соответствует спецификации protobuf
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#fields
- Рекомендации по исправлению:
  1. Добавить проверку wire type для каждого поля
  2. Улучшить сообщение об ошибке, включив информацию о wire type
  3. Добавить проверку корректности сериализации/десериализации

## testNestedValidationErrors
### Сравнение с protoc
- Не полностью проверяет валидацию вложенных сообщений
- Protoc проверяет больше аспектов вложенных сообщений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#nested
- Код теста:
```swift
func testNestedValidationErrors() {
    let person = ProtoDynamicMessage(descriptor: personDescriptor)
    let address = ProtoDynamicMessage(descriptor: addressDescriptor)
    address.set(fieldName: "street", value: .stringValue("123 Main St"))
    address.set(fieldName: "city", value: .stringValue("Anytown"))
    address.set(fieldName: "zipCode", value: .stringValue("12345"))
    person.set(fieldName: "name", value: .stringValue("John"))
    person.set(fieldName: "age", value: .intValue(30))
    person.set(fieldName: "address", value: .messageValue(address))
    let isValid = person.validateFields()
    XCTAssertTrue(isValid, "Message with valid nested message should be valid")
    XCTAssertTrue(person.errors.isEmpty, "No errors should be present for valid message with nested message")
}
```

### Сравнение со спецификацией
- Не полностью соответствует спецификации protobuf
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#nested
- Рекомендации по исправлению:
  1. Добавить проверку циклических зависимостей
  2. Добавить проверку глубины вложенности
  3. Добавить проверку валидации всех полей вложенного сообщения

## Отсутствующие тесты

### testWireTypeValidation
- Описание: Должен проверять корректность wire type для всех типов полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Пример кода:
```swift
func testWireTypeValidation() {
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    
    // Test varint wire type
    do {
        let _ = try message.trySet(fieldName: "int32_field", value: .intValue(42))
    } catch {
        XCTFail("Failed to set varint field: \(error)")
    }
    
    // Test 64-bit wire type
    do {
        let _ = try message.trySet(fieldName: "double_field", value: .doubleValue(3.14))
    } catch {
        XCTFail("Failed to set 64-bit field: \(error)")
    }
    
    // Test length-delimited wire type
    do {
        let _ = try message.trySet(fieldName: "string_field", value: .stringValue("test"))
    } catch {
        XCTFail("Failed to set length-delimited field: \(error)")
    }
}
```

### testDefaultValues
- Описание: Должен проверять корректность значений по умолчанию для всех типов полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#default
- Пример кода:
```swift
func testDefaultValues() {
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    
    // Test default values for scalar types
    XCTAssertEqual(try message.tryGet(fieldName: "int32_field"), .intValue(0))
    XCTAssertEqual(try message.tryGet(fieldName: "string_field"), .stringValue(""))
    XCTAssertEqual(try message.tryGet(fieldName: "bool_field"), .boolValue(false))
    
    // Test default values for repeated fields
    XCTAssertEqual(try message.tryGet(fieldName: "repeated_int32_field"), .repeatedValue([]))
    
    // Test default values for message fields
    XCTAssertEqual(try message.tryGet(fieldName: "message_field"), .messageValue(nil))
}
```

### testFieldNumberValidation
- Описание: Должен проверять корректность номеров полей согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#assigning_field_numbers
- Пример кода:
```swift
func testFieldNumberValidation() {
    // Test valid field numbers
    let validDescriptor = ProtoMessageDescriptor(
        fullName: "test.ValidMessage",
        fields: [
            ProtoFieldDescriptor(name: "field1", number: 1, type: .string, isRepeated: false, isMap: false),
            ProtoFieldDescriptor(name: "field2", number: 536870911, type: .string, isRepeated: false, isMap: false)
        ],
        enums: [],
        nestedMessages: []
    )
    
    // Test invalid field numbers
    do {
        let _ = ProtoMessageDescriptor(
            fullName: "test.InvalidMessage",
            fields: [
                ProtoFieldDescriptor(name: "field1", number: 0, type: .string, isRepeated: false, isMap: false)
            ],
            enums: [],
            nestedMessages: []
        )
        XCTFail("Should throw error for invalid field number")
    } catch {
        // Expected error
    }
} 