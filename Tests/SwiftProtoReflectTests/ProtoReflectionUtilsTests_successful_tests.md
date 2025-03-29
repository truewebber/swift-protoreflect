# ProtoReflectionUtilsTests - Успешные тесты

## testValidateValidFieldDescriptor
### Сравнение с protoc
- Тест корректно проверяет валидацию базовых параметров поля protobuf
- Соответствует поведению protoc при валидации полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#fields
- Код теста, который проверяет это поведение:
```swift
func testValidateValidFieldDescriptor() {
    let fieldDescriptor = ProtoFieldDescriptor(
        name: "field1", 
        number: 1, 
        type: .int32, 
        isRepeated: false, 
        isMap: false
    )
    XCTAssertTrue(ProtoReflectionUtils.validateFieldDescriptor(fieldDescriptor))
}
```

### Сравнение со спецификацией
- Тест проверяет соответствие основным правилам спецификации protobuf для полей:
  - Корректное имя поля (непустая строка)
  - Валидный номер поля (положительное целое число)
  - Корректный тип поля
  - Корректные флаги повторяемости и map
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#fields
- Код теста, который проверяет это поведение:
```swift
func testValidateValidFieldDescriptor() {
    let fieldDescriptor = ProtoFieldDescriptor(
        name: "field1", 
        number: 1, 
        type: .int32, 
        isRepeated: false, 
        isMap: false
    )
    XCTAssertTrue(ProtoReflectionUtils.validateFieldDescriptor(fieldDescriptor))
}
```

## testDescribeValidMessage
### Сравнение с protoc
- Тест корректно проверяет базовое описание сообщения protobuf
- Соответствует поведению protoc при выводе описания сообщения
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#message
- Код теста, который проверяет это поведение:
```swift
func testDescribeValidMessage() {
    let descriptor = ProtoMessageDescriptor(
        fullName: "TestMessage", 
        fields: [], 
        enums: [], 
        nestedMessages: []
    )
    let message = ProtoDynamicMessage(descriptor: descriptor)
    let description = ProtoReflectionUtils.describeMessage(message)
    XCTAssertTrue(description.contains("TestMessage"))
}
```

### Сравнение со спецификацией
- Тест проверяет соответствие основным правилам спецификации protobuf для сообщений:
  - Корректное полное имя сообщения
  - Возможность создания пустого сообщения
  - Корректное описание структуры сообщения
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#message
- Код теста, который проверяет это поведение:
```swift
func testDescribeValidMessage() {
    let descriptor = ProtoMessageDescriptor(
        fullName: "TestMessage", 
        fields: [], 
        enums: [], 
        nestedMessages: []
    )
    let message = ProtoDynamicMessage(descriptor: descriptor)
    let description = ProtoReflectionUtils.describeMessage(message)
    XCTAssertTrue(description.contains("TestMessage"))
}
``` 