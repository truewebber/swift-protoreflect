# SwiftProtoReflect

Библиотека для динамической работы с Protocol Buffers сообщениями в Swift без предварительно скомпилированных .pb файлов.

## Основные возможности

- Динамическое создание и управление Protocol Buffers сообщениями в runtime
- Работа с сообщениями без предварительной генерации .pb.swift файлов
- Поддержка всех типов полей Protocol Buffers (скалярные, сложные, вложенные, повторяющиеся, map)
- Сериализация и десериализация в бинарный формат и JSON
- Динамическое обнаружение и использование gRPC сервисов
- Полная интеграция с библиотекой Swift Protobuf
- Поддержка Well-Known Types (Timestamp, Duration, Empty, FieldMask)
- Высокая производительность и соответствие стандарту Protocol Buffers

## 🚀 Текущий статус

**SwiftProtoReflect находится в активной разработке**

### ✅ Завершенные компоненты

**Core Foundation (100% готово):**
- ✅ **Descriptor System** - Полная система дескрипторов для Protocol Buffers
- ✅ **Dynamic Message System** - Динамическое создание и манипуляция сообщениями
- ✅ **Type Registry** - Централизованное управление типами
- ✅ **Serialization Engine** - Binary и JSON сериализация/десериализация

**Integration Phase - Well-Known Types:**
- ✅ **Critical Phase 1 (100% готово):**
  - ✅ `google.protobuf.Timestamp` - Временные метки
  - ✅ `google.protobuf.Duration` - Временные интервалы  
  - ✅ `google.protobuf.Empty` - Пустые сообщения
  - ✅ `google.protobuf.FieldMask` - Маски полей для partial updates

- ✅ **Phase 2 (100% готово - ЗНАЧИТЕЛЬНО УЛУЧШЕНО):**
  - ✅ `google.protobuf.Struct` - Динамические JSON-like структуры (**ЗАВЕРШЕНО**)
  - ✅ `google.protobuf.Value` - Универсальные значения (**ЗАВЕРШЕНО**)

### 🔄 В разработке

**Phase 3 Advanced Types:**
- ⏳ `google.protobuf.ListValue` - для массивов в Struct (низкий приоритет)
- ⏳ `google.protobuf.Any` - для type erasure
- ⏳ `google.protobuf.NullValue` - для null значений

### 📊 Метрики качества

- **Покрытие тестами:** 92.01% регионов, 94.34% строк
- **Архитектура:** Модульная, расширяемая
- **Производительность:** Оптимизирована для production use
- **Документация:** Comprehensive с примерами

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

### Bridge Phase - ЗАВЕРШЕНА ✅

- ✅ **DescriptorBridge** (ЗАВЕРШЕНО)
  - ✅ Конвертация между дескрипторами SwiftProtoReflect и Swift Protobuf
  - ✅ Поддержка всех типов дескрипторов (Message, Field, Enum, File, Service)
  - ✅ Round-trip совместимость (99.49% покрытие тестами, 30 тестов)

- ✅ **StaticMessageBridge** (ЗАВЕРШЕНО)
  - ✅ Конвертация статических Swift Protobuf сообщений в динамические
  - ✅ Batch конвертация и проверка совместимости типов
  - ✅ Расширения для удобного использования (95.92% покрытие тестами, 25 тестов)

### Service Phase - ЗАВЕРШЕНА ✅

- ✅ **ServiceClient** (ЗАВЕРШЕНО)
  - ✅ Динамические unary gRPC вызовы (85.93% покрытие тестами, 29 тестов)
  - ✅ Type-safe валидация запросов/ответов
  - ✅ Comprehensive error handling (7 типов ошибок)
  - ✅ GRPCPayloadWrapper для сериализации/десериализации
  - ✅ CallOptions с поддержкой таймаутов и метаданных

### Integration Phase - В РАЗРАБОТКЕ 🚧

- ✅ **Critical Phase 1** (ЗАВЕРШЕНО)
  - ✅ **WellKnownTypes Foundation** - базовая инфраструктура
    - ✅ WellKnownTypeNames - константы для всех стандартных типов
    - ✅ WellKnownTypeDetector - утилиты определения well-known types
    - ✅ WellKnownTypesRegistry - реестр обработчиков с thread-safety
    - ✅ WellKnownTypeHandler протокол для обработчиков
  - ✅ **TimestampHandler** - google.protobuf.Timestamp поддержка
    - ✅ Конвертация между DynamicMessage и Date
    - ✅ Валидация и round-trip совместимость
    - ✅ Comprehensive testing (23 теста)
  - ✅ **DurationHandler** - google.protobuf.Duration поддержка
    - ✅ Конвертация между DynamicMessage и TimeInterval
    - ✅ Поддержка отрицательных интервалов времени
    - ✅ Валидация знаков seconds/nanos полей
    - ✅ Utility методы: abs(), negated(), zero()
    - ✅ Comprehensive testing (29 тестов)
  - ✅ **EmptyHandler** - google.protobuf.Empty поддержка
    - ✅ Конвертация между DynamicMessage и пустыми значениями
    - ✅ Валидация и round-trip совместимость
    - ✅ Comprehensive testing (15 тестов)
  - ✅ **FieldMaskHandler** - google.protobuf.FieldMask поддержка
    - ✅ FieldMaskValue с полной валидацией путей
    - ✅ Операции: union, intersection, covers, adding, removing
    - ✅ Конвертация между DynamicMessage и FieldMaskValue
    - ✅ Convenience extensions для Array<String> и DynamicMessage
    - ✅ Comprehensive testing (30 тестов, 96.52% покрытие)

- ✅ **Phase 2 Well-Known Types** (ЗАВЕРШЕНО - ЗНАЧИТЕЛЬНО УЛУЧШЕНО)
  - ✅ **Struct Handler** - google.protobuf.Struct поддержка
    - ✅ Полная поддержка динамических JSON-like структур
    - ✅ Конвертация Dictionary<String, Any> ↔ StructValue
    - ✅ Поддержка вложенных структур и массивов
    - ✅ **УЛУЧШЕНО:** 29 тестов, покрытие 88.00% регионов, 93.49% строк
    - ✅ Production-ready качество
  - ✅ **Value Handler** - google.protobuf.Value поддержка
    - ✅ Основа для Struct - универсальные значения
    - ✅ Поддержка: null, number, string, bool, struct, list
    - ✅ Тесная интеграция с StructHandler
    - ✅ **ЗНАЧИТЕЛЬНО УЛУЧШЕНО:** 20 тестов, покрытие 94.29% регионов, 94.78% строк
    - ✅ Production-ready качество

- [ ] **Phase 3** (ПЛАНИРУЕТСЯ)
  - [ ] **Extensions Support** - Protocol Buffers extensions
  - [ ] **Advanced Interoperability** - продвинутые функции интеграции

### Общее покрытие тестами: 94.34% (794 теста проходят)

**Следующий этап**: Phase 3 Advanced Types - ListValue, Any, NullValue поддержка

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
let person = factory.createMessage(from: personMessage)

// Установка значений полей
try person.set("John Doe", forField: "name")
try person.set(Int32(30), forField: "age")
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
let message = try pool.createMessage(forType: "example.Person", fieldValues: [
    "name": "Jane Doe",
    "age": Int32(25)
])
```

### Динамический доступ к полям

```swift
// Получение доступа к полям сообщения
let accessor = FieldAccessor(message: person)

// Чтение значений
let name: String? = accessor.getString("name")
let age: Int32? = accessor.getInt32("age")

// Проверка наличия полей
if accessor.hasValue("name") {
    print("Имя установлено: \(name ?? "неизвестно")")
}
```

### Работа с Well-Known Types

```swift
// Работа с google.protobuf.Timestamp
let timestampHandler = TimestampHandler.self
let date = Date()
let timestampValue = TimestampHandler.TimestampValue(from: date)
let timestampMessage = try timestampHandler.createDynamic(from: timestampValue)

// Работа с google.protobuf.Duration
let durationHandler = DurationHandler.self
let timeInterval: TimeInterval = 123.456
let durationValue = DurationHandler.DurationValue(from: timeInterval)
let durationMessage = try durationHandler.createDynamic(from: durationValue)

// Utility методы для Duration
let absoluteDuration = durationValue.abs()  // Абсолютное значение
let negatedDuration = durationValue.negated()  // Отрицательная длительность
let zeroDuration = DurationHandler.DurationValue.zero()  // Нулевая длительность

// Работа с google.protobuf.FieldMask
let fieldMaskHandler = FieldMaskHandler.self
let paths = ["name", "email", "profile.age"]
let fieldMaskValue = FieldMaskHandler.FieldMaskValue(paths: paths)
let fieldMaskMessage = try fieldMaskHandler.createDynamic(from: fieldMaskValue)

// FieldMask операции
let union = fieldMaskValue.union(with: otherFieldMask)
let intersection = fieldMaskValue.intersection(with: otherFieldMask)
let coversField = fieldMaskValue.covers("name")

// Registry интеграция
let registry = WellKnownTypesRegistry.shared
let specializedTimestamp = try registry.createSpecialized(
    from: timestampMessage, 
    typeName: WellKnownTypeNames.timestamp
)
```

### Работа с google.protobuf.Value

```swift
// Работа с google.protobuf.Value
let valueHandler = ValueHandler.self
let anyValue: Any = 42.5
let valueValue = try ValueHandler.ValueValue(from: anyValue)
let valueMessage = try valueHandler.createDynamic(from: valueValue)

// Конвертация обратно
let roundTripValue = try valueHandler.createSpecialized(from: valueMessage) as! ValueHandler.ValueValue
let originalValue = roundTripValue.toAny() // 42.5

// Работа с комплексными значениями
let complexData: [String: Any] = [
  "name": "John",
  "age": 30,
  "active": true,
  "scores": [85, 92, 78]
]
let complexValue = try ValueHandler.ValueValue(from: complexData)
let complexMessage = try valueHandler.createDynamic(from: complexValue)

// Registry интеграция
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