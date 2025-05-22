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

На данный момент завершена разработка системы дескрипторов:
- ✅ FileDescriptor
- ✅ MessageDescriptor
- ✅ FieldDescriptor
- ✅ EnumDescriptor
- ✅ ServiceDescriptor

Следующий этап: реализация динамических сообщений и типов.

## Примеры использования

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

// Создание и настройка сервиса
var userService = ServiceDescriptor(name: "UserService", parent: fileDescriptor)

// Добавление метода к сервису
userService.addMethod(ServiceDescriptor.MethodDescriptor(
    name: "GetUser",
    inputType: "example.GetUserRequest",
    outputType: "example.GetUserResponse"
))

// Регистрация компонентов
fileDescriptor.addMessage(personMessage)
fileDescriptor.addService(userService)
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
