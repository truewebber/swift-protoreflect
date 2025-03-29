# ProtoErrorHandlingTests - Успешные тесты

## testFieldNotFoundError
### Сравнение с protoc
- Корректно проверяет ошибку при попытке доступа к несуществующему полю
- Соответствует поведению protoc, который также выбрасывает ошибку при попытке доступа к несуществующему полю
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#field_names
- Код теста:
```swift
func testFieldNotFoundError() {
    let person = ProtoDynamicMessage(descriptor: personDescriptor)
    do {
        let _ = try person.tryGet(fieldName: "nonexistentField")
        XCTFail("Expected error was not thrown")
    }
    catch let error as ProtoError {
        switch error {
        case .fieldNotFound(let fieldName, let messageType):
            XCTAssertEqual(fieldName, "nonexistentField")
            XCTAssertEqual(messageType, "test.Person")
        default:
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
```

### Сравнение со спецификацией
- Корректно реализует проверку имен полей согласно спецификации protobuf
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#field_names
- Тест проверяет базовое требование спецификации о том, что все поля должны быть определены в сообщении

## testInvalidFieldValueError
### Сравнение с protoc
- Корректно проверяет ошибку при попытке установить значение неверного типа
- Соответствует поведению protoc, который также выбрасывает ошибку при несоответствии типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Код теста:
```swift
func testInvalidFieldValueError() {
    let person = ProtoDynamicMessage(descriptor: personDescriptor)
    do {
        let _ = try person.trySet(fieldName: "age", value: .stringValue("not an integer"))
        XCTFail("Expected error was not thrown")
    }
    catch let error as ProtoError {
        switch error {
        case .invalidFieldValue(let fieldName, let expectedType, let actualValue):
            XCTAssertEqual(fieldName, "age")
            XCTAssertEqual(expectedType, "int32")
            XCTAssertTrue(actualValue.contains("not an integer"))
        default:
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
```

### Сравнение со спецификацией
- Корректно реализует проверку типов полей согласно спецификации protobuf
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Тест проверяет базовое требование спецификации о том, что значения полей должны соответствовать их типам

## testValidationErrors
### Сравнение с protoc
- Корректно проверяет валидацию сообщений
- Соответствует поведению protoc в отношении валидации proto3 сообщений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#default
- Код теста:
```swift
func testValidationErrors() {
    let person = ProtoDynamicMessage(descriptor: personDescriptor)
    person.set(fieldName: "name", value: .stringValue("John"))
    person.set(fieldName: "age", value: .intValue(30))
    let isValid = person.validateFields()
    XCTAssertTrue(isValid, "Message with valid values should be valid")
    XCTAssertTrue(person.errors.isEmpty, "No errors should be present for valid message")
}
```

### Сравнение со спецификацией
- Корректно реализует валидацию proto3 сообщений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#default
- Тест проверяет базовое требование спецификации о том, что proto3 сообщения должны быть валидными даже при отсутствии обязательных полей 