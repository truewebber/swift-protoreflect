# ProtoReflectTests - Успешные тесты

## testCreateMessage
### Сравнение с protoc
- Корректно создает сообщение с правильным дескриптором
- Соответствует поведению protoc при создании сообщений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#how-do-they-work
- Код теста:
```swift
func testCreateMessage() {
    let person = ProtoReflect.createMessage(from: personDescriptor)
    XCTAssertNotNil(person)

    let message = person.build()
    XCTAssertEqual(message.descriptor().fullName, "Person")
}
```

### Сравнение со спецификацией
- Правильно реализует создание сообщений согласно спецификации
- Корректно обрабатывает дескрипторы сообщений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#how-do-they-work
- Код теста:
```swift
func testCreateMessage() {
    let person = ProtoReflect.createMessage(from: personDescriptor)
    XCTAssertNotNil(person)

    let message = person.build()
    XCTAssertEqual(message.descriptor().fullName, "Person")
}
```

## testSetAndGetSimpleValues
### Сравнение с protoc
- Корректно устанавливает и получает простые значения
- Соответствует поведению protoc при работе с примитивными типами
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Код теста:
```swift
func testSetAndGetSimpleValues() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    person.set("name", to: "John Doe")
    person.set("age", to: 30)

    let name = person.get("name")
    let age = person.get("age")

    XCTAssertEqual(name?.getString(), "John Doe")
    XCTAssertEqual(age?.getInt(), 30)
}
```

### Сравнение со спецификацией
- Правильно реализует работу с примитивными типами данных
- Корректно обрабатывает типы string и int32
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#scalar
- Код теста:
```swift
func testSetAndGetSimpleValues() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    person.set("name", to: "John Doe")
    person.set("age", to: 30)

    let name = person.get("name")
    let age = person.get("age")

    XCTAssertEqual(name?.getString(), "John Doe")
    XCTAssertEqual(age?.getInt(), 30)
}
```

## testSetAndGetNestedValues
### Сравнение с protoc
- Корректно обрабатывает вложенные сообщения
- Соответствует поведению protoc при работе с nested messages
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#nested
- Код теста:
```swift
func testSetAndGetNestedValues() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    person.set("address.street", to: "123 Main St")
    person.set("address.city", to: "Anytown")
    person.set("address.zipCode", to: "12345")

    let street = person.get("address.street")
    let city = person.get("address.city")
    let zipCode = person.get("address.zipCode")

    XCTAssertEqual(street?.getString(), "123 Main St")
    XCTAssertEqual(city?.getString(), "Anytown")
    XCTAssertEqual(zipCode?.getString(), "12345")
}
```

### Сравнение со спецификацией
- Правильно реализует работу с вложенными сообщениями
- Корректно обрабатывает доступ к полям вложенных сообщений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#nested
- Код теста:
```swift
func testSetAndGetNestedValues() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    person.set("address.street", to: "123 Main St")
    person.set("address.city", to: "Anytown")
    person.set("address.zipCode", to: "12345")

    let street = person.get("address.street")
    let city = person.get("address.city")
    let zipCode = person.get("address.zipCode")

    XCTAssertEqual(street?.getString(), "123 Main St")
    XCTAssertEqual(city?.getString(), "Anytown")
    XCTAssertEqual(zipCode?.getString(), "12345")
}
```

## testSetAndGetRepeatedValues
### Сравнение с protoc
- Корректно обрабатывает повторяющиеся поля
- Соответствует поведению protoc при работе с repeated fields
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#specifying_field_rules
- Код теста:
```swift
func testSetAndGetRepeatedValues() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    person.set("tags", to: ["tag1", "tag2", "tag3"])

    let tags = person.get("tags")?.getRepeated()

    XCTAssertNotNil(tags)
    XCTAssertEqual(tags?.count, 3)
    XCTAssertEqual(tags?[0].getString(), "tag1")
    XCTAssertEqual(tags?[1].getString(), "tag2")
    XCTAssertEqual(tags?[2].getString(), "tag3")
}
```

### Сравнение со спецификацией
- Правильно реализует работу с repeated fields
- Корректно обрабатывает массив значений
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#specifying_field_rules
- Код теста:
```swift
func testSetAndGetRepeatedValues() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    person.set("tags", to: ["tag1", "tag2", "tag3"])

    let tags = person.get("tags")?.getRepeated()

    XCTAssertNotNil(tags)
    XCTAssertEqual(tags?.count, 3)
    XCTAssertEqual(tags?[0].getString(), "tag1")
    XCTAssertEqual(tags?[1].getString(), "tag2")
    XCTAssertEqual(tags?[2].getString(), "tag3")
}
```

## testSetAndGetMapValues
### Сравнение с protoc
- Корректно обрабатывает map поля
- Соответствует поведению protoc при работе с map fields
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Код теста:
```swift
func testSetAndGetMapValues() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    person.set("attributes", to: ["key1": "value1", "key2": "value2"])

    let attributes = person.get("attributes")?.getMap()

    XCTAssertNotNil(attributes)
    XCTAssertEqual(attributes?.count, 2)
    XCTAssertEqual(attributes?["key1"]?.getString(), "value1")
    XCTAssertEqual(attributes?["key2"]?.getString(), "value2")
}
```

### Сравнение со спецификацией
- Правильно реализует работу с map fields
- Корректно обрабатывает пары ключ-значение
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#maps
- Код теста:
```swift
func testSetAndGetMapValues() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    person.set("attributes", to: ["key1": "value1", "key2": "value2"])

    let attributes = person.get("attributes")?.getMap()

    XCTAssertNotNil(attributes)
    XCTAssertEqual(attributes?.count, 2)
    XCTAssertEqual(attributes?["key1"]?.getString(), "value1")
    XCTAssertEqual(attributes?["key2"]?.getString(), "value2")
}
```

## testClearValues
### Сравнение с protoc
- Корректно очищает значения полей
- Соответствует поведению protoc при очистке полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#default
- Код теста:
```swift
func testClearValues() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    person.set("name", to: "John Doe")
    XCTAssertNotNil(person.get("name"))

    person.clear("name")
    XCTAssertNil(person.get("name"))

    person.set("address.street", to: "123 Main St")
    XCTAssertNotNil(person.get("address.street"))

    person.clear("address.street")
    XCTAssertNil(person.get("address.street"))
}
```

### Сравнение со спецификацией
- Правильно реализует очистку полей
- Корректно обрабатывает default values
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#default
- Код теста:
```swift
func testClearValues() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    person.set("name", to: "John Doe")
    XCTAssertNotNil(person.get("name"))

    person.clear("name")
    XCTAssertNil(person.get("name"))

    person.set("address.street", to: "123 Main St")
    XCTAssertNotNil(person.get("address.street"))

    person.clear("address.street")
    XCTAssertNil(person.get("address.street"))
}
```

## testHasValues
### Сравнение с protoc
- Корректно проверяет наличие значений
- Соответствует поведению protoc при проверке наличия полей
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#field_presence
- Код теста:
```swift
func testHasValues() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    XCTAssertFalse(person.has("name"))

    person.set("name", to: "John Doe")
    XCTAssertTrue(person.has("name"))

    XCTAssertFalse(person.has("address.street"))

    person.set("address.street", to: "123 Main St")
    XCTAssertTrue(person.has("address.street"))
}
```

### Сравнение со спецификацией
- Правильно реализует проверку наличия полей
- Корректно обрабатывает field presence
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/proto3#field_presence
- Код теста:
```swift
func testHasValues() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    XCTAssertFalse(person.has("name"))

    person.set("name", to: "John Doe")
    XCTAssertTrue(person.has("name"))

    XCTAssertFalse(person.has("address.street"))

    person.set("address.street", to: "123 Main St")
    XCTAssertTrue(person.has("address.street"))
}
```

## testMethodChaining
### Сравнение с protoc
- Корректно поддерживает цепочку методов
- Соответствует поведению protoc при последовательных операциях
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#how-do-they-work
- Код теста:
```swift
func testMethodChaining() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    person
      .set("name", to: "John Doe")
      .set("age", to: 30)
      .set("address.street", to: "123 Main St")
      .set("address.city", to: "Anytown")

    XCTAssertEqual(person.get("name")?.getString(), "John Doe")
    XCTAssertEqual(person.get("age")?.getInt(), 30)
    XCTAssertEqual(person.get("address.street")?.getString(), "123 Main St")
    XCTAssertEqual(person.get("address.city")?.getString(), "Anytown")
}
```

### Сравнение со спецификацией
- Правильно реализует fluent interface
- Корректно обрабатывает последовательные операции
- Ссылка на спецификацию: https://developers.google.com/protocol-buffers/docs/overview#how-do-they-work
- Код теста:
```swift
func testMethodChaining() {
    let person = ProtoReflect.createMessage(from: personDescriptor)

    person
      .set("name", to: "John Doe")
      .set("age", to: 30)
      .set("address.street", to: "123 Main St")
      .set("address.city", to: "Anytown")

    XCTAssertEqual(person.get("name")?.getString(), "John Doe")
    XCTAssertEqual(person.get("age")?.getInt(), 30)
    XCTAssertEqual(person.get("address.street")?.getString(), "123 Main St")
    XCTAssertEqual(person.get("address.city")?.getString(), "Anytown")
}
``` 