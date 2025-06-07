# SwiftProtoReflect Examples

Добро пожаловать в comprehensive коллекцию примеров для **SwiftProtoReflect** - библиотеки для динамической работы с Protocol Buffers в Swift!

## 🚀 Быстрый старт

### Автоматический запуск всех примеров
```bash
# Из папки examples/
make run-all        # Запуск всех примеров с подробным отчетом
./run-all.sh        # То же самое, но напрямую через скрипт
```

### Запуск по категориям
```bash
make run-basic           # 🔰 Базовое использование
make run-dynamic         # 🔧 Динамические сообщения
make run-serialization   # 💾 Сериализация
make run-registry        # 🗂 Type Registry
make run-wellknown       # ⭐ Well-Known Types
make run-grpc           # 🌐 gRPC интеграция
make run-advanced       # 🚀 Продвинутые функции
make run-realworld      # 🏢 Реальные сценарии
```

### Интерактивный режим
```bash
make demo              # Интерактивный выбор и запуск примеров
```

## 📚 Категории примеров

### 🔰 01-basic-usage (4 примера)
**Изучите основы SwiftProtoReflect**
- `hello-world.swift` - Ваш первый динамический Protocol Buffers пример
- `simple-message.swift` - Создание сообщений с различными типами полей
- `field-types.swift` - Демонстрация всех типов полей Protocol Buffers
- `basic-descriptors.swift` - Работа с дескрипторами и метаданными

### 🔧 02-dynamic-messages (5 примеров)
**Продвинутая работа с динамическими сообщениями**
- `complex-messages.swift` - Сложные вложенные сообщения и структуры
- `field-accessor.swift` - Type-safe доступ к полям сообщений
- `nested-messages.swift` - Работа с иерархией вложенных сообщений
- `map-fields.swift` - Map поля и key-value структуры
- `message-validation.swift` - Валидация структуры и данных сообщений

### 💾 03-serialization (6 примеров)
**Сериализация и десериализация в различных форматах**
- `binary-format.swift` - Binary Protocol Buffers сериализация
- `json-format.swift` - JSON формат с protobuf семантикой
- `round-trip.swift` - Проверка совместимости туда-обратно
- `custom-options.swift` - Настройки сериализации и опции
- `performance-test.swift` - Benchmarks производительности
- `compatibility-test.swift` - Совместимость с Swift Protobuf

### 🗂 04-registry (4 примера)
**Централизованное управление типами**
- `type-registry.swift` - Основы работы с TypeRegistry
- `descriptor-pool.swift` - DescriptorPool для эффективного управления
- `type-discovery.swift` - Динамическое обнаружение типов
- `multi-file-registry.swift` - Работа с множественными proto файлами

### ⭐ 05-well-known-types (8 примеров)
**Google Protocol Buffers стандартные типы**
- `timestamp-demo.swift` - google.protobuf.Timestamp ↔ Foundation.Date
- `duration-demo.swift` - google.protobuf.Duration ↔ TimeInterval
- `empty-demo.swift` - google.protobuf.Empty для пустых ответов
- `field-mask-demo.swift` - google.protobuf.FieldMask для partial updates
- `struct-demo.swift` - google.protobuf.Struct как JSON объекты
- `value-demo.swift` - google.protobuf.Value универсальные значения
- `any-demo.swift` - google.protobuf.Any для type erasure
- `well-known-registry.swift` - WellKnownTypesRegistry интеграция

### 🌐 06-grpc (5 примеров)
**Динамическая интеграция с gRPC сервисами**
- `dynamic-client.swift` - Создание динамического gRPC клиента
- `service-discovery.swift` - Обнаружение доступных сервисов
- `unary-calls.swift` - Unary RPC вызовы с валидацией
- `error-handling.swift` - Обработка gRPC ошибок и статусов
- `metadata-options.swift` - Работа с метаданными и CallOptions

### 🚀 07-advanced (6 примеров)
**Сложные сценарии интеграции и оптимизации**
- `descriptor-bridge.swift` - Конвертация дескрипторов
- `static-message-bridge.swift` - Интеграция статических сообщений
- `batch-operations.swift` - Массовая обработка сообщений
- `memory-optimization.swift` - Стратегии оптимизации памяти
- `thread-safety.swift` - Потокобезопасность и concurrency
- `custom-extensions.swift` - Создание собственных расширений

### 🏢 08-real-world (5 примеров)
**Реальные архитектурные паттерны и сценарии**
- `config-system.swift` - Система конфигурации на основе protobuf
- `api-gateway.swift` - API Gateway с динамическими схемами
- `message-transform.swift` - Трансформация между версиями сообщений
- `validation-framework.swift` - Комплексный validation framework
- `proto-repl.swift` - Интерактивная REPL для protobuf

## 🛠 Общие компоненты

### shared/ - Общие утилиты
- `example-base.swift` - Базовые утилиты для всех примеров
- `logger.swift` - Цветное логирование для консоли
- `console-utils.swift` - Утилиты консольного интерфейса
- `performance-timer.swift` - Измерение производительности
- `test-data.swift` - Генерация тестовых данных

### resources/ - Ресурсы и данные
- `proto/` - Proto файлы для примеров
- `data/` - Тестовые данные (JSON, binary)
- `templates/` - Шаблоны для создания новых примеров

### docs/ - Подробная документация
- `getting-started.md` - Подробное руководство по началу работы
- `advanced-usage.md` - Продвинутое использование
- `troubleshooting.md` - Решение проблем
- `api-reference.md` - Справочник API

## 🔧 Способы запуска примеров

### Метод 1: Через Make (Рекомендуемый)
```bash
make setup          # Сборка библиотеки SwiftProtoReflect
make run-basic      # Запуск категории примеров
make run-all        # Запуск всех примеров
```

### Метод 2: Прямой запуск скрипта
```bash
# Сначала соберите библиотеку
cd /path/to/SwiftProtoReflect && swift build -c release

# Затем запустите пример
cd examples
swift -I ../.build/release -L ../.build/release -lSwiftProtoReflect 01-basic-usage/hello-world.swift
```

### Метод 3: Исполнение как скрипт
```bash
# Сделайте файл исполняемым
chmod +x 01-basic-usage/hello-world.swift

# Запустите напрямую (если настроен shebang)
./01-basic-usage/hello-world.swift
```

## 📋 Требования

- **Swift 6.0+**
- **SwiftProtoReflect** (собранная библиотека)
- **macOS 14.0+** или **Linux** с Swift runtime

## 🎯 Рекомендуемый порядок изучения

1. **Начинающие**: Начните с `01-basic-usage/hello-world.swift`
2. **Средний уровень**: Изучите категории 02-04 (Dynamic Messages, Serialization, Registry)
3. **Продвинутые**: Освойте 05-07 (Well-Known Types, gRPC, Advanced)
4. **Эксперты**: Примените знания в 08 (Real-World Scenarios)

## 💡 Полезные команды

```bash
# Справка по всем командам Make
make help

# Проверка конкретного примера
make check-example EXAMPLE=01-basic-usage/hello-world.swift

# Список всех доступных примеров
make list-examples

# Очистка временных файлов
make clean
```

## 🤝 Участие в разработке

Хотите добавить свой пример? Смотрите:
- `docs/contributing.md` - Руководство по участию
- `resources/templates/` - Шаблоны для новых примеров

## 📞 Поддержка

Если у вас возникли проблемы:
1. Проверьте `docs/troubleshooting.md`
2. Убедитесь что библиотека SwiftProtoReflect собрана: `make setup`
3. Проверьте требования к системе выше

---

**Общее количество примеров: 43 исполняемых Swift скрипта**

Удачного изучения SwiftProtoReflect! 🚀
