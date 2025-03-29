# DescriptorRegistryTests - Неуспешные тесты

## testRegisterInvalidFileDescriptor
### Сравнение с protoc
- Тест не полностью проверяет все случаи невалидных FileDescriptorProto
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FileDescriptorProto
- Пример поведения protoc:
```protobuf
// protoc выдает ошибку для следующих случаев:
// 1. Отсутствие имени файла
// 2. Некорректное имя пакета
// 3. Дублирование имен сообщений
// 4. Некорректные зависимости
```
- Код теста:
```swift
func testRegisterInvalidFileDescriptor() {
    let fileDescriptor = Google_Protobuf_FileDescriptorProto()
    XCTAssertThrowsError(
        try registry.registerFileDescriptor(fileDescriptor),
        "Should throw when registering an invalid file descriptor"
    ) { error in
        XCTAssertTrue(error is DescriptorError, "Error should be a DescriptorError")
        if let descriptorError = error as? DescriptorError {
            switch descriptorError {
            case .invalidFileDescriptor:
                break
            default:
                XCTFail("Unexpected error: \(descriptorError)")
            }
        }
    }
}
```

### Сравнение со спецификацией
- Тест не проверяет все обязательные поля и валидации согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FileDescriptorProto
- Рекомендации по исправлению:
  1. Добавить проверку валидации имени пакета
  2. Добавить проверку дублирования имен сообщений
  3. Добавить проверку корректности зависимостей
  4. Добавить проверку валидации путей импорта
- Код теста:
```swift
func testRegisterInvalidFileDescriptor() {
    let fileDescriptor = Google_Protobuf_FileDescriptorProto()
    XCTAssertThrowsError(
        try registry.registerFileDescriptor(fileDescriptor),
        "Should throw when registering an invalid file descriptor"
    ) { error in
        XCTAssertTrue(error is DescriptorError, "Error should be a DescriptorError")
        if let descriptorError = error as? DescriptorError {
            switch descriptorError {
            case .invalidFileDescriptor:
                break
            default:
                XCTFail("Unexpected error: \(descriptorError)")
            }
        }
    }
}
```

## testEnumDescriptorLookup
### Сравнение с protoc
- Тест не проверяет все случаи использования enum в protobuf
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.EnumDescriptorProto
- Пример поведения protoc:
```protobuf
// protoc поддерживает:
// 1. Enum как тип поля
// 2. Enum как тип в map
// 3. Enum в oneof
// 4. Enum в repeated полях
```
- Код теста:
```swift
func testEnumDescriptorLookup() {
    var fileDescriptor = Google_Protobuf_FileDescriptorProto()
    fileDescriptor.name = "test_enum.proto"
    fileDescriptor.package = "test"
    
    var enumDescriptor = Google_Protobuf_EnumDescriptorProto()
    enumDescriptor.name = "TestEnum"
    
    var enumValue1 = Google_Protobuf_EnumValueDescriptorProto()
    enumValue1.name = "VALUE_1"
    enumValue1.number = 0
    
    var enumValue2 = Google_Protobuf_EnumValueDescriptorProto()
    enumValue2.name = "VALUE_2"
    enumValue2.number = 1
    
    enumDescriptor.value.append(enumValue1)
    enumDescriptor.value.append(enumValue2)
    
    fileDescriptor.enumType.append(enumDescriptor)
    
    try? registry.registerFileDescriptor(fileDescriptor)
    
    do {
        let descriptor = try registry.enumDescriptor(forTypeName: "test.TestEnum")
        XCTAssertEqual(descriptor.name, "TestEnum", "Name should match")
        XCTAssertEqual(descriptor.values.count, 2, "Should have two values")
        XCTAssertEqual(descriptor.values[0].name, "VALUE_1", "First value name should match")
        XCTAssertEqual(descriptor.values[0].number, 0, "First value number should match")
        XCTAssertEqual(descriptor.values[1].name, "VALUE_2", "Second value name should match")
        XCTAssertEqual(descriptor.values[1].number, 1, "Second value number should match")
    }
    catch {
        XCTFail("Failed to look up enum descriptor: \(error)")
    }
}
```

### Сравнение со спецификацией
- Тест не проверяет все аспекты enum согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.EnumDescriptorProto
- Рекомендации по исправлению:
  1. Добавить проверку использования enum в различных контекстах
  2. Добавить проверку валидации значений enum
  3. Добавить проверку резервных значений
  4. Добавить проверку опций enum
- Код теста:
```swift
func testEnumDescriptorLookup() {
    var fileDescriptor = Google_Protobuf_FileDescriptorProto()
    fileDescriptor.name = "test_enum.proto"
    fileDescriptor.package = "test"
    
    var enumDescriptor = Google_Protobuf_EnumDescriptorProto()
    enumDescriptor.name = "TestEnum"
    
    var enumValue1 = Google_Protobuf_EnumValueDescriptorProto()
    enumValue1.name = "VALUE_1"
    enumValue1.number = 0
    
    var enumValue2 = Google_Protobuf_EnumValueDescriptorProto()
    enumValue2.name = "VALUE_2"
    enumValue2.number = 1
    
    enumDescriptor.value.append(enumValue1)
    enumDescriptor.value.append(enumValue2)
    
    fileDescriptor.enumType.append(enumDescriptor)
    
    try? registry.registerFileDescriptor(fileDescriptor)
    
    do {
        let descriptor = try registry.enumDescriptor(forTypeName: "test.TestEnum")
        XCTAssertEqual(descriptor.name, "TestEnum", "Name should match")
        XCTAssertEqual(descriptor.values.count, 2, "Should have two values")
        XCTAssertEqual(descriptor.values[0].name, "VALUE_1", "First value name should match")
        XCTAssertEqual(descriptor.values[0].number, 0, "First value number should match")
        XCTAssertEqual(descriptor.values[1].name, "VALUE_2", "Second value name should match")
        XCTAssertEqual(descriptor.values[1].number, 1, "Second value number should match")
    }
    catch {
        XCTFail("Failed to look up enum descriptor: \(error)")
    }
}
```

## Отсутствующие тесты

### testServiceDescriptorValidation
- Описание: Необходимо добавить тесты для проверки дескрипторов сервисов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.ServiceDescriptorProto
- Пример кода теста:
```swift
func testServiceDescriptorValidation() {
    var fileDescriptor = Google_Protobuf_FileDescriptorProto()
    fileDescriptor.name = "test_service.proto"
    fileDescriptor.package = "test"
    
    var serviceDescriptor = Google_Protobuf_ServiceDescriptorProto()
    serviceDescriptor.name = "TestService"
    
    var methodDescriptor = Google_Protobuf_MethodDescriptorProto()
    methodDescriptor.name = "TestMethod"
    methodDescriptor.inputType = "test.InputMessage"
    methodDescriptor.outputType = "test.OutputMessage"
    methodDescriptor.clientStreaming = false
    methodDescriptor.serverStreaming = false
    
    serviceDescriptor.method.append(methodDescriptor)
    fileDescriptor.service.append(serviceDescriptor)
    
    XCTAssertNoThrow(
        try registry.registerFileDescriptor(fileDescriptor),
        "Should not throw when registering a valid service descriptor"
    )
}
```

### testOneofDescriptorValidation
- Описание: Необходимо добавить тесты для проверки oneof полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#oneof
- Пример кода теста:
```swift
func testOneofDescriptorValidation() {
    var fileDescriptor = Google_Protobuf_FileDescriptorProto()
    fileDescriptor.name = "test_oneof.proto"
    fileDescriptor.package = "test"
    
    var messageDescriptor = Google_Protobuf_DescriptorProto()
    messageDescriptor.name = "TestMessage"
    
    var oneofDescriptor = Google_Protobuf_OneofDescriptorProto()
    oneofDescriptor.name = "test_oneof"
    
    var field1 = Google_Protobuf_FieldDescriptorProto()
    field1.name = "string_field"
    field1.number = 1
    field1.type = .string
    field1.label = .optional
    field1.oneofIndex = 0
    
    var field2 = Google_Protobuf_FieldDescriptorProto()
    field2.name = "int_field"
    field2.number = 2
    field2.type = .int32
    field2.label = .optional
    field2.oneofIndex = 0
    
    messageDescriptor.field.append(field1)
    messageDescriptor.field.append(field2)
    messageDescriptor.oneofDecl.append(oneofDescriptor)
    fileDescriptor.messageType.append(messageDescriptor)
    
    XCTAssertNoThrow(
        try registry.registerFileDescriptor(fileDescriptor),
        "Should not throw when registering a valid oneof descriptor"
    )
}
```

### testMapFieldValidation
- Описание: Необходимо добавить тесты для проверки map полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Пример кода теста:
```swift
func testMapFieldValidation() {
    var fileDescriptor = Google_Protobuf_FileDescriptorProto()
    fileDescriptor.name = "test_map.proto"
    fileDescriptor.package = "test"
    
    var messageDescriptor = Google_Protobuf_DescriptorProto()
    messageDescriptor.name = "TestMessage"
    
    var mapField = Google_Protobuf_FieldDescriptorProto()
    mapField.name = "map_field"
    mapField.number = 1
    mapField.type = .message
    mapField.label = .repeated
    mapField.typeName = ".test.MapEntry"
    
    messageDescriptor.field.append(mapField)
    fileDescriptor.messageType.append(messageDescriptor)
    
    XCTAssertNoThrow(
        try registry.registerFileDescriptor(fileDescriptor),
        "Should not throw when registering a valid map field"
    )
}
``` 