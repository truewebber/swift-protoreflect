# ProtoServiceDescriptorTests - Неуспешные тесты

## testInvalidServiceDescriptor
### Сравнение с protoc
- Не полностью соответствует поведению protoc при валидации сервиса
- Protoc проверяет больше условий валидности, чем текущая реализация
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#services
- Код теста, который проверяет это поведение:
```swift
func testInvalidServiceDescriptor() {
    let serviceDescriptor = ProtoServiceDescriptor(name: "", methods: [])
    XCTAssertFalse(serviceDescriptor.isValid())
}
```

### Сравнение со спецификацией
- Не полностью соответствует спецификации protobuf для сервисов
- Отсутствует проверка валидности имен методов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#services
- Рекомендации по исправлению:
  1. Добавить проверку формата имени сервиса (должно соответствовать правилам именования)
  2. Добавить проверку уникальности имен методов
  3. Добавить проверку валидности типов входных и выходных параметров методов
- Код теста, который проверяет это поведение:
```swift
func testInvalidServiceDescriptor() {
    let serviceDescriptor = ProtoServiceDescriptor(name: "", methods: [])
    XCTAssertFalse(serviceDescriptor.isValid())
}
```

## Отсутствующие тесты

### testServiceNameValidation
- Должен проверять валидность имени сервиса согласно спецификации protobuf
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#identifiers
- Пример кода теста:
```swift
func testServiceNameValidation() {
    // Проверка валидных имен
    let validNames = ["MyService", "My_Service", "MyService123"]
    for name in validNames {
        let serviceDescriptor = ProtoServiceDescriptor(name: name, methods: [])
        XCTAssertTrue(serviceDescriptor.isValid(), "Service name '\(name)' should be valid")
    }
    
    // Проверка невалидных имен
    let invalidNames = ["123Service", "my-service", "my.service", ""]
    for name in invalidNames {
        let serviceDescriptor = ProtoServiceDescriptor(name: name, methods: [])
        XCTAssertFalse(serviceDescriptor.isValid(), "Service name '\(name)' should be invalid")
    }
}
```

### testMethodNameValidation
- Должен проверять валидность имен методов в сервисе
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#identifiers
- Пример кода теста:
```swift
func testMethodNameValidation() {
    let validMethodNames = ["GetData", "SetValue", "UpdateRecord"]
    let invalidMethodNames = ["123Method", "get-data", "set.value", ""]
    
    for name in validMethodNames {
        let method = ProtoMethodDescriptor(
            name: name,
            inputType: createTestMessageDescriptor(),
            outputType: createTestMessageDescriptor()
        )
        let serviceDescriptor = ProtoServiceDescriptor(name: "TestService", methods: [method])
        XCTAssertTrue(serviceDescriptor.isValid(), "Method name '\(name)' should be valid")
    }
    
    for name in invalidMethodNames {
        let method = ProtoMethodDescriptor(
            name: name,
            inputType: createTestMessageDescriptor(),
            outputType: createTestMessageDescriptor()
        )
        let serviceDescriptor = ProtoServiceDescriptor(name: "TestService", methods: [method])
        XCTAssertFalse(serviceDescriptor.isValid(), "Method name '\(name)' should be invalid")
    }
}
```

### testMethodTypeValidation
- Должен проверять валидность типов входных и выходных параметров методов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#services
- Пример кода теста:
```swift
func testMethodTypeValidation() {
    // Проверка валидных типов
    let validMethod = ProtoMethodDescriptor(
        name: "TestMethod",
        inputType: createTestMessageDescriptor(),
        outputType: createTestMessageDescriptor()
    )
    let serviceDescriptor = ProtoServiceDescriptor(name: "TestService", methods: [validMethod])
    XCTAssertTrue(serviceDescriptor.isValid())
    
    // Проверка невалидных типов (например, void или primitive types)
    let invalidMethod = ProtoMethodDescriptor(
        name: "InvalidMethod",
        inputType: nil, // или невалидный тип
        outputType: nil // или невалидный тип
    )
    let invalidServiceDescriptor = ProtoServiceDescriptor(name: "TestService", methods: [invalidMethod])
    XCTAssertFalse(invalidServiceDescriptor.isValid())
}
```

### testMethodUniqueness
- Должен проверять уникальность имен методов в сервисе
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#services
- Пример кода теста:
```swift
func testMethodUniqueness() {
    let method1 = ProtoMethodDescriptor(
        name: "TestMethod",
        inputType: createTestMessageDescriptor(),
        outputType: createTestMessageDescriptor()
    )
    let method2 = ProtoMethodDescriptor(
        name: "TestMethod", // Дублирующее имя
        inputType: createTestMessageDescriptor(),
        outputType: createTestMessageDescriptor()
    )
    let serviceDescriptor = ProtoServiceDescriptor(name: "TestService", methods: [method1, method2])
    XCTAssertFalse(serviceDescriptor.isValid(), "Service with duplicate method names should be invalid")
} 