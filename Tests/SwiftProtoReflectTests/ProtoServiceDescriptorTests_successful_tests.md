# ProtoServiceDescriptorTests - Успешные тесты

## testGetMethodByName
### Сравнение с protoc
- Корректно реализует поиск метода по имени в сервисе
- Соответствует поведению protoc при поиске методов в сервисе
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#services
- Код теста, который проверяет это поведение:
```swift
func testGetMethodByName() {
    let method = ProtoMethodDescriptor(
      name: "TestMethod",
      inputType: createTestMessageDescriptor(),
      outputType: createTestMessageDescriptor()
    )
    let serviceDescriptor = ProtoServiceDescriptor(name: "TestService", methods: [method])
    let retrievedMethod = serviceDescriptor.method(named: "TestMethod")
    XCTAssertEqual(retrievedMethod?.name, "TestMethod")
}
```

### Сравнение со спецификацией
- Корректно реализует спецификацию protobuf для сервисов
- Правильно обрабатывает структуру сервиса с методами
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#services
- Код теста, который проверяет это поведение:
```swift
func testGetMethodByName() {
    let method = ProtoMethodDescriptor(
      name: "TestMethod",
      inputType: createTestMessageDescriptor(),
      outputType: createTestMessageDescriptor()
    )
    let serviceDescriptor = ProtoServiceDescriptor(name: "TestService", methods: [method])
    let retrievedMethod = serviceDescriptor.method(named: "TestMethod")
    XCTAssertEqual(retrievedMethod?.name, "TestMethod")
}
```

## testGetNonExistentMethod
### Сравнение с protoc
- Корректно обрабатывает случай отсутствия метода в сервисе
- Соответствует поведению protoc при попытке доступа к несуществующему методу
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#services
- Код теста, который проверяет это поведение:
```swift
func testGetNonExistentMethod() {
    let serviceDescriptor = ProtoServiceDescriptor(name: "TestService", methods: [])
    let method = serviceDescriptor.method(named: "NonExistentMethod")
    XCTAssertNil(method)
}
```

### Сравнение со спецификацией
- Правильно реализует обработку отсутствующих методов
- Соответствует спецификации protobuf для сервисов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#services
- Код теста, который проверяет это поведение:
```swift
func testGetNonExistentMethod() {
    let serviceDescriptor = ProtoServiceDescriptor(name: "TestService", methods: [])
    let method = serviceDescriptor.method(named: "NonExistentMethod")
    XCTAssertNil(method)
}
```

## testValidServiceDescriptor
### Сравнение с protoc
- Корректно валидирует структуру сервиса
- Соответствует поведению protoc при проверке валидности сервиса
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#services
- Код теста, который проверяет это поведение:
```swift
func testValidServiceDescriptor() {
    let method = ProtoMethodDescriptor(
      name: "TestMethod",
      inputType: createTestMessageDescriptor(),
      outputType: createTestMessageDescriptor()
    )
    let serviceDescriptor = ProtoServiceDescriptor(name: "TestService", methods: [method])
    XCTAssertTrue(serviceDescriptor.isValid())
}
```

### Сравнение со спецификацией
- Правильно реализует валидацию сервиса согласно спецификации
- Корректно проверяет наличие обязательных компонентов сервиса
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#services
- Код теста, который проверяет это поведение:
```swift
func testValidServiceDescriptor() {
    let method = ProtoMethodDescriptor(
      name: "TestMethod",
      inputType: createTestMessageDescriptor(),
      outputType: createTestMessageDescriptor()
    )
    let serviceDescriptor = ProtoServiceDescriptor(name: "TestService", methods: [method])
    XCTAssertTrue(serviceDescriptor.isValid())
} 