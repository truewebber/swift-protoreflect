# SwiftProtoReflect

Библиотека для динамической работы с Protocol Buffers сообщениями в Swift без предварительно скомпилированных .pb файлов.

## Основные возможности

- Динамическое создание и управление Protocol Buffers сообщениями в runtime
- Работа с сообщениями без предварительной генерации .pb.swift файлов
- Поддержка всех типов полей Protocol Buffers (скалярные, сложные, вложенные, повторяющиеся, map)
- Сериализация и десериализация в бинарный формат и JSON
- Динамическое обнаружение и использование gRPC сервисов
- Полная интеграция с библиотекой Swift Protobuf
- Высокая производительность и соответствие стандарту Protocol Buffers

## Статус проекта

Текущий статус разработки отслеживается в [PROJECT_STATE.md](PROJECT_STATE.md).

### Foundation Phase - ЗАВЕРШЕНА ✅

- ✅ **Descriptor System** (100% завершено)
  - ✅ FileDescriptor (100% покрытие тестами)
  - ✅ MessageDescriptor (100% покрытие тестами)
  - ✅ FieldDescriptor (89.70% покрытие тестами)
  - ✅ EnumDescriptor (100% покрытие тестами)
  - ✅ ServiceDescriptor (96.58% покрытие тестами)

- ✅ **Dynamic Module** (100% завершено)
  - ✅ DynamicMessage (96.44% покрытие тестами)
  - ✅ MessageFactory (97.54% покрытие тестами)
  - ✅ FieldAccessor (90.77% покрытие тестами)

- ✅ **Registry Module** (100% завершено)
  - ✅ TypeRegistry (97.73% покрытие тестами)
  - ✅ DescriptorPool (97.85% покрытие тестами)

### Serialization Phase - ЗАВЕРШЕНА ✅

- ✅ **Binary Serialization** (ЗАВЕРШЕНО)
  - ✅ BinarySerializer (90.77% покрытие тестами, 27 тестов)
  - ✅ BinaryDeserializer (89.69% покрытие тестами, 20 тестов)
  - ✅ Поддержка всех типов полей Protocol Buffers
  - ✅ ZigZag encoding, wire format совместимость

- ✅ **JSON Serialization** (ЗАВЕРШЕНО)
  - ✅ JSONSerializer (94.66% покрытие тестами, 27 тестов)
  - ✅ JSONDeserializer (90.64% покрытие тестами, 43 теста)
  - ✅ Protocol Buffers JSON mapping
  - ✅ Round-trip совместимость

- ✅ **Comprehensive Error Testing** (ЗАВЕРШЕНО)
  - ✅ JSONSerializer Type Mismatch Tests (52 теста)
  - ✅ BinarySerializer Type Mismatch Tests (70 тестов)
  - ✅ Полное покрытие error paths

### Общее покрытие кода тестами: 94.17% (538 тестов)

**Следующий этап**: Bridge Phase - Static/Dynamic message conversion

## Примеры использования

### Создание динамических сообщений

```swift
// Создание дескриптора файла
var fileDescriptor = FileDescriptor(name: "person.proto", package: "example")

// Создание дескриптора сообщения
var personMessage = MessageDescriptor(name: "Person", parent: fileDescriptor)

// Добавление полей в сообщение
personMessage.addField(FieldDescriptor(
    name: "name",
    number: 1,
    type: .string
))

personMessage.addField(FieldDescriptor(
    name: "age",
    number: 2,
    type: .int32
))

// Регистрация компонентов
fileDescriptor.addMessage(personMessage)

// Создание сообщения через MessageFactory
let factory = MessageFactory()
let person = try factory.createMessage(descriptor: personMessage)

// Установка значений полей
try person.set(field: "name", value: "John Doe")
try person.set(field: "age", value: 30)
```

### Работа с TypeRegistry и DescriptorPool

```swift
// Создание реестра типов
let typeRegistry = TypeRegistry()
try typeRegistry.registerFile(fileDescriptor)

// Поиск типов
let foundMessage = typeRegistry.findMessage(typeName: "example.Person")

// Работа с DescriptorPool для динамического создания дескрипторов
let pool = DescriptorPool()
try pool.addFile(fileDescriptor)

// Создание сообщения через pool
let message = try pool.createMessage(typeName: "example.Person", fieldValues: [
    "name": "Jane Doe",
    "age": 25
])
```

### Динамический доступ к полям

```swift
// Получение доступа к полям сообщения
let accessor = FieldAccessor(message: person)

// Чтение значений
let name: String = try accessor.getString(fieldName: "name")
let age: Int32 = try accessor.getInt32(fieldName: "age")

// Проверка наличия полей
if accessor.hasValue(fieldName: "name") {
    print("Имя установлено: \(name)")
}
```

## Архитектура

Подробное описание архитектуры и компонентов системы находится в [ARCHITECTURE.md](ARCHITECTURE.md).

## Требования

Бизнес-требования к библиотеке описаны в [REQUIREMENTS.md](REQUIREMENTS.md).

## Разработка

Руководство для разработчиков с описанием рабочего процесса: [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md).

```bash
# Проверка кода
make lint

# Форматирование кода
make format

# Запуск тестов
make test

# Проверка покрытия кода тестами
make coverage
```

## Совместимость

- Swift 6.0 и выше
- iOS 17.0+, macOS 14.0+, tvOS 17.0+, watchOS 10.0+
- SwiftProtobuf 1.25.0 и выше

## Документация

Исчерпывающая документация компонентов находится в директории [Sources/](Sources/) в каждом модуле.
