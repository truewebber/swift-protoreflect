# DescriptorRegistryTests - Успешные тесты

## testSharedInstance
### Сравнение с protoc
- Тест корректно проверяет паттерн Singleton для DescriptorRegistry, что соответствует архитектурному решению protoc
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#how-do-they-work
- Код теста:
```swift
func testSharedInstance() {
    let instance1 = DescriptorRegistry.shared
    let instance2 = DescriptorRegistry.shared
    XCTAssertTrue(instance1 === instance2, "Shared instance should be a singleton")
}
```

### Сравнение со спецификацией
- Тест корректно реализует требование единой точки доступа к дескрипторам
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#how-do-they-work
- Код теста:
```swift
func testSharedInstance() {
    let instance1 = DescriptorRegistry.shared
    let instance2 = DescriptorRegistry.shared
    XCTAssertTrue(instance1 === instance2, "Shared instance should be a singleton")
}
```

## testRegisterFileDescriptor
### Сравнение с protoc
- Тест корректно проверяет регистрацию валидного FileDescriptorProto
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FileDescriptorProto
- Код теста:
```swift
func testRegisterFileDescriptor() {
    var fileDescriptor = Google_Protobuf_FileDescriptorProto()
    fileDescriptor.name = "test.proto"
    fileDescriptor.package = "test"
    
    var messageDescriptor = Google_Protobuf_DescriptorProto()
    messageDescriptor.name = "TestMessage"
    
    var fieldDescriptor = Google_Protobuf_FieldDescriptorProto()
    fieldDescriptor.name = "test_field"
    fieldDescriptor.number = 1
    fieldDescriptor.type = .string
    fieldDescriptor.label = .optional
    
    messageDescriptor.field.append(fieldDescriptor)
    fileDescriptor.messageType.append(messageDescriptor)
    
    XCTAssertNoThrow(
        try registry.registerFileDescriptor(fileDescriptor),
        "Should not throw when registering a valid file descriptor"
    )
}
```

### Сравнение со спецификацией
- Тест корректно проверяет структуру FileDescriptorProto согласно спецификации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FileDescriptorProto
- Код теста:
```swift
func testRegisterFileDescriptor() {
    var fileDescriptor = Google_Protobuf_FileDescriptorProto()
    fileDescriptor.name = "test.proto"
    fileDescriptor.package = "test"
    
    var messageDescriptor = Google_Protobuf_DescriptorProto()
    messageDescriptor.name = "TestMessage"
    
    var fieldDescriptor = Google_Protobuf_FieldDescriptorProto()
    fieldDescriptor.name = "test_field"
    fieldDescriptor.number = 1
    fieldDescriptor.type = .string
    fieldDescriptor.label = .optional
    
    messageDescriptor.field.append(fieldDescriptor)
    fileDescriptor.messageType.append(messageDescriptor)
    
    XCTAssertNoThrow(
        try registry.registerFileDescriptor(fileDescriptor),
        "Should not throw when registering a valid file descriptor"
    )
}
```

## testMessageDescriptorLookup
### Сравнение с protoc
- Тест корректно проверяет поиск дескриптора сообщения по полному имени
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.DescriptorProto
- Код теста:
```swift
func testMessageDescriptorLookup() {
    var fileDescriptor = Google_Protobuf_FileDescriptorProto()
    fileDescriptor.name = "test_lookup.proto"
    fileDescriptor.package = "test"
    
    var messageDescriptor = Google_Protobuf_DescriptorProto()
    messageDescriptor.name = "TestMessage"
    
    var fieldDescriptor = Google_Protobuf_FieldDescriptorProto()
    fieldDescriptor.name = "test_field"
    fieldDescriptor.number = 1
    fieldDescriptor.type = .string
    fieldDescriptor.label = .optional
    
    messageDescriptor.field.append(fieldDescriptor)
    fileDescriptor.messageType.append(messageDescriptor)
    
    try? registry.registerFileDescriptor(fileDescriptor)
    
    do {
        let descriptor = try registry.messageDescriptor(forTypeName: "test.TestMessage")
        XCTAssertEqual(descriptor.fullName, "test.TestMessage", "Full name should match")
        XCTAssertEqual(descriptor.fields.count, 1, "Should have one field")
        XCTAssertEqual(descriptor.fields[0].name, "test_field", "Field name should match")
        XCTAssertEqual(descriptor.fields[0].number, 1, "Field number should match")
        XCTAssertEqual(descriptor.fields[0].type, .string, "Field type should match")
    }
    catch {
        XCTFail("Failed to look up message descriptor: \(error)")
    }
}
```

### Сравнение со спецификацией
- Тест корректно проверяет структуру и валидацию дескриптора сообщения
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.DescriptorProto
- Код теста:
```swift
func testMessageDescriptorLookup() {
    var fileDescriptor = Google_Protobuf_FileDescriptorProto()
    fileDescriptor.name = "test_lookup.proto"
    fileDescriptor.package = "test"
    
    var messageDescriptor = Google_Protobuf_DescriptorProto()
    messageDescriptor.name = "TestMessage"
    
    var fieldDescriptor = Google_Protobuf_FieldDescriptorProto()
    fieldDescriptor.name = "test_field"
    fieldDescriptor.number = 1
    fieldDescriptor.type = .string
    fieldDescriptor.label = .optional
    
    messageDescriptor.field.append(fieldDescriptor)
    fileDescriptor.messageType.append(messageDescriptor)
    
    try? registry.registerFileDescriptor(fileDescriptor)
    
    do {
        let descriptor = try registry.messageDescriptor(forTypeName: "test.TestMessage")
        XCTAssertEqual(descriptor.fullName, "test.TestMessage", "Full name should match")
        XCTAssertEqual(descriptor.fields.count, 1, "Should have one field")
        XCTAssertEqual(descriptor.fields[0].name, "test_field", "Field name should match")
        XCTAssertEqual(descriptor.fields[0].number, 1, "Field number should match")
        XCTAssertEqual(descriptor.fields[0].type, .string, "Field type should match")
    }
    catch {
        XCTFail("Failed to look up message descriptor: \(error)")
    }
} 