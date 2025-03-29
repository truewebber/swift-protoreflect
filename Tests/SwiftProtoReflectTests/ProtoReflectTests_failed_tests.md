# ProtoReflectTests - Неуспешные тесты

## testMarshalAndUnmarshal
### Сравнение с protoc
- Не проверяет корректность wire format при маршалинге/анмаршалинге
- Не соответствует полному поведению protoc при сериализации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding
- Пример поведения protoc:
```protobuf
// person.proto
message Person {
  string name = 1;
  int32 age = 2;
  Address address = 3;
}

message Address {
  string street = 1;
  string city = 2;
  string zip_code = 3;
}
```
```bash
protoc --encode=Person person.proto < person.txt > person.bin
protoc --decode=Person person.proto < person.bin
```
- Код теста:
```swift
func testMarshalAndUnmarshal() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    person.set("name", to: "John Doe")
    person.set("age", to: 30)
    person.set("address.street", to: "123 Main St")

    let data = ProtoReflect.marshal(message: person.build())
    XCTAssertNotNil(data)

    let unmarshaledMessage = ProtoReflect.unmarshal(data: data!, descriptor: personDescriptor)
    XCTAssertNotNil(unmarshaledMessage)

    let unmarshaledPerson = unmarshaledMessage as? ProtoDynamicMessage
    XCTAssertNotNil(unmarshaledPerson)

    let name = unmarshaledPerson?.get(field: personDescriptor.field(named: "name")!)
    XCTAssertEqual(name?.getString(), "John Doe")

    let age = unmarshaledPerson?.get(field: personDescriptor.field(named: "age")!)
    XCTAssertEqual(age?.getInt(), 30)
}
```

### Сравнение со спецификацией
- Не проверяет все аспекты wire format
- Не тестирует различные типы полей при сериализации
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Рекомендации по исправлению:
  1. Добавить тесты для всех wire types
  2. Проверить корректность кодирования/декодирования для каждого типа
  3. Добавить тесты на edge cases (максимальные значения, специальные значения)
  4. Проверить корректность обработки ошибок при некорректных данных

## testValueConversion
### Сравнение с protoc
- Не проверяет все типы конвертации значений
- Не соответствует полному поведению protoc при конвертации типов
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Пример поведения protoc:
```protobuf
message Test {
  int32 int_field = 1;
  double double_field = 2;
  bool bool_field = 3;
  string string_field = 4;
  bytes bytes_field = 5;
}
```
- Код теста:
```swift
func testValueConversion() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    person.set("name", to: "John Doe")  // String
    person.set("age", to: 30)  // Int

    person.set("tags", to: ["tag1", "2", "true"])

    XCTAssertEqual(person.get("name")?.getString(), "John Doe")
    XCTAssertEqual(person.get("age")?.getInt(), 30)

    let tags = person.get("tags")?.getRepeated()
    XCTAssertNotNil(tags)
    XCTAssertEqual(tags?.count, 3)
    XCTAssertEqual(tags?[0].getString(), "tag1")
    XCTAssertEqual(tags?[1].getString(), "2")
    XCTAssertEqual(tags?[2].getString(), "true")
}
```

### Сравнение со спецификацией
- Не проверяет все типы данных из спецификации
- Не тестирует конвертацию между различными типами
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Рекомендации по исправлению:
  1. Добавить тесты для всех скалярных типов
  2. Проверить конвертацию между совместимыми типами
  3. Добавить тесты на некорректные конвертации
  4. Проверить обработку ошибок при неверных типах

## Отсутствующие тесты

### testWireTypeValidation
- Описание: Проверка корректности wire types для всех типов полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/encoding#wire-types
- Код теста:
```swift
func testWireTypeValidation() {
    let message = ProtoReflect.createMessage(from: testDescriptor)
    
    // Test Varint wire type
    message.set("int32_field", to: Int32.max)
    message.set("uint32_field", to: UInt32.max)
    message.set("int64_field", to: Int64.max)
    message.set("uint64_field", to: UInt64.max)
    message.set("bool_field", to: true)
    message.set("enum_field", to: TestEnum.value1)
    
    // Test 64-bit wire type
    message.set("fixed64_field", to: UInt64.max)
    message.set("sfixed64_field", to: Int64.max)
    message.set("double_field", to: Double.infinity)
    
    // Test Length-delimited wire type
    message.set("string_field", to: "test")
    message.set("bytes_field", to: Data([1, 2, 3]))
    message.set("message_field", to: NestedMessage())
    
    // Test 32-bit wire type
    message.set("fixed32_field", to: UInt32.max)
    message.set("sfixed32_field", to: Int32.max)
    message.set("float_field", to: Float.infinity)
    
    // Test Start group wire type (deprecated)
    // Test End group wire type (deprecated)
    
    let data = ProtoReflect.marshal(message: message.build())
    XCTAssertNotNil(data)
    
    let unmarshaled = ProtoReflect.unmarshal(data: data!, descriptor: testDescriptor)
    XCTAssertNotNil(unmarshaled)
}
```

### testFieldNumberValidation
- Описание: Проверка корректности номеров полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#assigning_field_numbers
- Код теста:
```swift
func testFieldNumberValidation() {
    // Test valid field numbers
    let validDescriptor = ProtoMessageDescriptor(
        fullName: "Test",
        fields: [
            ProtoFieldDescriptor(name: "field1", number: 1, type: .string),
            ProtoFieldDescriptor(name: "field2", number: 536870911, type: .string), // Max valid field number
        ],
        enums: [],
        nestedMessages: []
    )
    
    // Test invalid field numbers
    XCTAssertThrowsError(try ProtoMessageDescriptor(
        fullName: "Test",
        fields: [
            ProtoFieldDescriptor(name: "field1", number: 0, type: .string), // Invalid: 0
            ProtoFieldDescriptor(name: "field2", number: 536870912, type: .string), // Invalid: > max
        ],
        enums: [],
        nestedMessages: []
    ))
}
```

### testDefaultValues
- Описание: Проверка корректности значений по умолчанию
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#default
- Код теста:
```swift
func testDefaultValues() {
    let message = ProtoReflect.createMessage(from: testDescriptor)
    
    // Test default values for all types
    XCTAssertEqual(message.get("string_field")?.getString(), "")
    XCTAssertEqual(message.get("bytes_field")?.getBytes(), Data())
    XCTAssertEqual(message.get("bool_field")?.getBool(), false)
    XCTAssertEqual(message.get("int32_field")?.getInt(), 0)
    XCTAssertEqual(message.get("int64_field")?.getInt64(), 0)
    XCTAssertEqual(message.get("uint32_field")?.getUInt32(), 0)
    XCTAssertEqual(message.get("uint64_field")?.getUInt64(), 0)
    XCTAssertEqual(message.get("float_field")?.getFloat(), 0.0)
    XCTAssertEqual(message.get("double_field")?.getDouble(), 0.0)
    XCTAssertEqual(message.get("enum_field")?.getEnum(), TestEnum.unspecified)
    
    // Test custom default values
    let customDescriptor = ProtoMessageDescriptor(
        fullName: "Test",
        fields: [
            ProtoFieldDescriptor(name: "field1", number: 1, type: .string, defaultValue: "default"),
            ProtoFieldDescriptor(name: "field2", number: 2, type: .int32, defaultValue: 42),
        ],
        enums: [],
        nestedMessages: []
    )
    
    let customMessage = ProtoReflect.createMessage(from: customDescriptor)
    XCTAssertEqual(customMessage.get("field1")?.getString(), "default")
    XCTAssertEqual(customMessage.get("field2")?.getInt(), 42)
}
```

### testOneofValidation
- Описание: Проверка корректности работы с oneof полями
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#oneof
- Код теста:
```swift
func testOneofValidation() {
    let oneofDescriptor = ProtoMessageDescriptor(
        fullName: "Test",
        fields: [
            ProtoFieldDescriptor(name: "name", number: 1, type: .string, isOneof: true),
            ProtoFieldDescriptor(name: "age", number: 2, type: .int32, isOneof: true),
        ],
        enums: [],
        nestedMessages: []
    )
    
    let message = ProtoReflect.createMessage(from: oneofDescriptor)
    
    // Test setting one field clears others
    message.set("name", to: "John")
    XCTAssertEqual(message.get("name")?.getString(), "John")
    XCTAssertNil(message.get("age"))
    
    message.set("age", to: 30)
    XCTAssertNil(message.get("name"))
    XCTAssertEqual(message.get("age")?.getInt(), 30)
    
    // Test clearing oneof field
    message.clear("age")
    XCTAssertNil(message.get("age"))
}
```

### testMapValidation
- Описание: Проверка корректности работы с map полями
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Код теста:
```swift
func testMapValidation() {
    let message = ProtoReflect.createMessage(from: testDescriptor)
    
    // Test valid map operations
    message.set("string_map", to: ["key1": "value1", "key2": "value2"])
    message.set("int32_map", to: ["key1": 1, "key2": 2])
    
    // Test map key types
    XCTAssertThrowsError(try message.set("string_map", to: [1: "value"])) // Invalid key type
    XCTAssertThrowsError(try message.set("int32_map", to: ["key": "value"])) // Invalid value type
    
    // Test map operations
    let map = message.get("string_map")?.getMap()
    XCTAssertEqual(map?.count, 2)
    XCTAssertEqual(map?["key1"]?.getString(), "value1")
    XCTAssertEqual(map?["key2"]?.getString(), "value2")
    
    // Test map clearing
    message.clear("string_map")
    XCTAssertNil(message.get("string_map")?.getMap())
}
``` 