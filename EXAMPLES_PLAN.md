# План создания папки Examples для SwiftProtoReflect

## Обзор

Данный документ содержит полный план создания папки `examples` с исполняемыми Swift скриптами, демонстрирующими все возможности библиотеки SwiftProtoReflect. Все примеры будут запускаемыми Swift скриптами без необходимости создания отдельного Package.

## 🎯 Цели проекта

- Создать comprehensive набор примеров для всех функций SwiftProtoReflect
- Обеспечить простоту запуска (Swift как скрипты)
- Предоставить примеры разной сложности (от новичка до эксперта)
- Показать реальные сценарии использования библиотеки
- Создать автоматизированную систему запуска и тестирования примеров

## 📁 Структура папки Examples

```
examples/
├── README.md                           # Главная документация примеров
├── GETTING_STARTED.md                  # Быстрый старт и инструкции
├── run-all.sh                         # Автоматический запуск всех примеров  
├── Makefile                           # Make команды для удобства
├── 01-basic-usage/                    # 🔰 Базовое использование (4 примера)
│   ├── README.md
│   ├── hello-world.swift              # Простейший пример
│   ├── simple-message.swift           # Создание базового сообщения
│   ├── field-types.swift              # Демонстрация всех типов полей
│   └── basic-descriptors.swift         # Работа с дескрипторами
├── 02-dynamic-messages/               # 🔧 Динамические сообщения (5 примеров)
│   ├── README.md
│   ├── complex-messages.swift         # Сложные вложенные сообщения
│   ├── field-accessor.swift           # Type-safe доступ к полям
│   ├── nested-messages.swift          # Вложенные структуры
│   ├── map-fields.swift               # Map поля
│   └── message-validation.swift       # Валидация сообщений
├── 03-serialization/                  # 💾 Сериализация (6 примеров)
│   ├── README.md
│   ├── binary-format.swift            # Binary Protocol Buffers
│   ├── json-format.swift              # JSON сериализация
│   ├── round-trip.swift               # Round-trip совместимость
│   ├── custom-options.swift           # Настройки сериализации
│   ├── performance-test.swift         # Benchmarks производительности
│   └── compatibility-test.swift       # Совместимость с Swift Protobuf
├── 04-registry/                       # 🗂 Type Registry (4 примера)
│   ├── README.md
│   ├── type-registry.swift            # Базовая работа с TypeRegistry
│   ├── descriptor-pool.swift          # DescriptorPool функциональность
│   ├── type-discovery.swift           # Динамическое обнаружение типов
│   └── multi-file-registry.swift      # Множественные proto файлы
├── 05-well-known-types/              # ⭐ Well-Known Types (8 примеров)
│   ├── README.md
│   ├── timestamp-demo.swift           # google.protobuf.Timestamp
│   ├── duration-demo.swift            # google.protobuf.Duration
│   ├── empty-demo.swift               # google.protobuf.Empty
│   ├── field-mask-demo.swift          # google.protobuf.FieldMask
│   ├── struct-demo.swift              # google.protobuf.Struct
│   ├── value-demo.swift               # google.protobuf.Value
│   ├── any-demo.swift                 # google.protobuf.Any
│   └── well-known-registry.swift      # WellKnownTypesRegistry
├── 06-grpc/                          # 🌐 gRPC интеграция (5 примеров)
│   ├── README.md
│   ├── dynamic-client.swift           # Динамический gRPC клиент
│   ├── service-discovery.swift        # Обнаружение сервисов
│   ├── unary-calls.swift              # Unary RPC вызовы
│   ├── error-handling.swift           # Обработка gRPC ошибок
│   └── metadata-options.swift         # Метаданные и CallOptions
├── 07-advanced/                      # 🚀 Продвинутые функции (6 примеров)
│   ├── README.md
│   ├── descriptor-bridge.swift        # Конвертация дескрипторов
│   ├── static-message-bridge.swift    # Интеграция статических сообщений
│   ├── batch-operations.swift         # Batch обработка
│   ├── memory-optimization.swift      # Оптимизация памяти
│   ├── thread-safety.swift            # Потокобезопасность
│   └── custom-extensions.swift        # Собственные расширения
├── 08-real-world/                    # 🏢 Реальные сценарии (5 примеров)
│   ├── README.md
│   ├── config-system.swift            # Система конфигурации
│   ├── api-gateway.swift              # API Gateway с динамическими схемами
│   ├── message-transform.swift        # Трансформация сообщений
│   ├── validation-framework.swift     # Фреймворк валидации
│   └── proto-repl.swift               # Interactive REPL для protobuf
├── shared/                           # 🛠 Общие утилиты
│   ├── README.md
│   ├── logger.swift                   # Логирование с цветным выводом
│   ├── test-data.swift                # Генерация тестовых данных
│   ├── console-utils.swift            # Утилиты консольного интерфейса
│   ├── performance-timer.swift        # Измерение производительности
│   └── example-base.swift             # Базовый класс для примеров
├── resources/                        # 📄 Ресурсы и тестовые данные
│   ├── README.md
│   ├── proto/                        # Proto файлы для примеров
│   │   ├── basic.proto
│   │   ├── person.proto
│   │   ├── company.proto
│   │   └── service.proto
│   ├── data/                         # Тестовые данные
│   │   ├── sample-messages.json
│   │   ├── binary-test-data.bin
│   │   └── large-dataset.json
│   └── templates/                    # Шаблоны для создания новых примеров
│       ├── basic-example.swift.template
│       └── advanced-example.swift.template
└── docs/                             # 📚 Подробная документация
    ├── README.md
    ├── getting-started.md             # Подробное руководство по началу работы
    ├── advanced-usage.md              # Продвинутое использование
    ├── troubleshooting.md             # Решение проблем
    ├── api-reference.md               # Справочник API
    └── contributing.md                # Как добавить свой пример
```

**Итого примеров: 43 исполняемых Swift скрипта**

## 🚀 Способы запуска Swift скриптов

### Метод 1: Компиляция + Import Paths (Рекомендуемый)

```bash
# 1. Собираем библиотеку SwiftProtoReflect
cd /path/to/SwiftProtoReflect
swift build -c release

# 2. Запускаем скрипт с указанием путей
swift -I .build/release -L .build/release -lSwiftProtoReflect examples/01-basic-usage/hello-world.swift
```

### Метод 2: Shebang с Path

```swift
#!/usr/bin/env swift -I ../.build/release -L ../.build/release -lSwiftProtoReflect

import SwiftProtoReflect
// Код примера...
```

### Метод 3: Через Make/Script автоматизацию

```bash
# Используем Makefile
make run-basic          # Запуск базовых примеров
make run-all           # Запуск всех примеров

# Или shell скрипт
./run-all.sh           # Автоматический запуск всех примеров с отчетом
```

## 📋 Детальный план примеров по категориям

### 🔰 01-basic-usage (Начальный уровень)

**Цель**: Познакомить пользователей с основами SwiftProtoReflect

#### hello-world.swift
```swift
#!/usr/bin/env swift

/**
 * 🚀 SwiftProtoReflect Example: Hello World
 * 
 * Описание: Простейший пример создания динамического сообщения
 * Ключевые концепции: FileDescriptor, MessageDescriptor, DynamicMessage
 * Сложность: 🔰 Начальный
 * Время выполнения: < 5 секунд
 * 
 * Что изучите:
 * - Создание файлового дескриптора
 * - Определение простого сообщения
 * - Создание экземпляра динамического сообщения
 * - Установка и чтение значений полей
 * 
 * Запуск: 
 *   make run-basic
 *   ./hello-world.swift
 *   swift -I ../.build/release -L ../.build/release -lSwiftProtoReflect hello-world.swift
 */

import Foundation
import SwiftProtoReflect

@main
struct HelloWorldExample {
    static func main() throws {
        printHeader("Hello World - Первое знакомство с SwiftProtoReflect")
        
        // Шаг 1: Создание файлового дескриптора
        printStep(1, "Создание файлового дескриптора")
        var fileDescriptor = FileDescriptor(name: "hello.proto", package: "example")
        print("  📄 Создан файл: \(fileDescriptor.name)")
        print("  📦 Пакет: \(fileDescriptor.package)")
        
        // Шаг 2: Определение сообщения Person
        printStep(2, "Определение сообщения Person")
        var personMessage = MessageDescriptor(name: "Person", parent: fileDescriptor)
        
        // Добавление полей
        personMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        personMessage.addField(FieldDescriptor(name: "age", number: 2, type: .int32))
        personMessage.addField(FieldDescriptor(name: "email", number: 3, type: .string))
        
        print("  👤 Создано сообщение: \(personMessage.name)")
        print("  🏷  Поля: \(personMessage.fields.map { $0.name }.joined(separator: ", "))")
        
        // Шаг 3: Регистрация в файле
        printStep(3, "Регистрация сообщения в файле")
        fileDescriptor.addMessage(personMessage)
        print("  ✅ Сообщение зарегистрировано в файле \(fileDescriptor.name)")
        
        // Шаг 4: Создание экземпляра сообщения
        printStep(4, "Создание экземпляра динамического сообщения")
        let factory = MessageFactory()
        let person = factory.createMessage(from: personMessage)
        print("  🏗  Создан экземпляр сообщения: \(person.descriptor.name)")
        
        // Шаг 5: Заполнение данными
        printStep(5, "Заполнение сообщения данными")
        try person.set("John Doe", forField: "name")
        try person.set(Int32(30), forField: "age")
        try person.set("john.doe@example.com", forField: "email")
        
        // Шаг 6: Чтение данных обратно
        printStep(6, "Чтение данных из сообщения")
        let name: String? = try person.get("name")
        let age: Int32? = try person.get("age")
        let email: String? = try person.get("email")
        
        print("  👤 Имя: \(name ?? "не указано")")
        print("  🎂 Возраст: \(age?.description ?? "не указан")")
        print("  📧 Email: \(email ?? "не указан")")
        
        printSuccess("Пример успешно завершен! Вы создали ваше первое динамическое Protocol Buffers сообщение.")
        
        printNext([
            "Далее попробуйте: simple-message.swift - создание более сложного сообщения",
            "Или изучите: field-types.swift - все типы полей Protocol Buffers"
        ])
    }
}

// Вспомогательные функции для красивого вывода
func printHeader(_ title: String) {
    let separator = String(repeating: "=", count: title.count + 4)
    print("\n\(separator)")
    print("  \(title)")
    print("\(separator)\n")
}

func printStep(_ number: Int, _ description: String) {
    print("\n📝 Шаг \(number): \(description)")
    print(String(repeating: "-", count: description.count + 10))
}

func printSuccess(_ message: String) {
    print("\n🎉 \(message)")
}

func printNext(_ suggestions: [String]) {
    print("\n🔍 Что попробовать дальше:")
    for suggestion in suggestions {
        print("  • \(suggestion)")
    }
    print()
}
```

#### simple-message.swift
- Создание более сложного сообщения с различными типами полей
- Демонстрация optional и required семантики
- Работа с default значениями

#### field-types.swift
- Демонстрация всех скалярных типов (int32, int64, uint32, uint64, sint32, sint64, fixed32, fixed64, sfixed32, sfixed64, float, double, bool, string, bytes)
- Repeated поля
- Map поля
- Enum поля

#### basic-descriptors.swift
- Детальная работа с дескрипторами
- Навигация по иерархии дескрипторов
- Извлечение метаданных

### 🔧 02-dynamic-messages (Средний уровень)

**Цель**: Показать продвинутые возможности работы с динамическими сообщениями

#### complex-messages.swift
- Вложенные сообщения (nested messages)
- Сообщения внутри сообщений
- Сложные иерархии данных
- Работа с oneof полями

#### field-accessor.swift
- Использование FieldAccessor для type-safe доступа
- Batch операции с полями
- Проверка наличия полей (hasField)
- Очистка полей (clearField)

#### nested-messages.swift
- Создание сложных вложенных структур
- Parent-child отношения между сообщениями
- Навигация по вложенной структуре

#### map-fields.swift
- Работа с map<key, value> полями
- Различные типы ключей и значений
- Итерация по map полям
- Модификация map значений

#### message-validation.swift
- Валидация структуры сообщений
- Проверка обязательных полей
- Валидация типов данных
- Custom validation rules

### 💾 03-serialization (Средний уровень)

**Цель**: Демонстрация всех аспектов сериализации и десериализации

#### binary-format.swift
- Binary Protocol Buffers сериализация
- Wire format совместимость
- Работа с varint encoding
- ZigZag encoding для signed чисел

#### json-format.swift
- JSON Protocol Buffers mapping
- Настройки JSON сериализации
- Работа с enum как строки vs числа
- Handling null values

#### round-trip.swift
- Проверка round-trip совместимости (message -> binary -> message)
- Сравнение оригинала и восстановленного сообщения
- Тестирование на потерю данных

#### custom-options.swift
- Настройка параметров сериализации
- Кастомные опции для JSON
- Работа с неизвестными полями
- Backward compatibility

#### performance-test.swift
- Benchmark сериализации vs десериализации
- Сравнение с Swift Protobuf performance
- Влияние размера сообщения на скорость
- Memory usage анализ

#### compatibility-test.swift
- Совместимость с официальными protobuf реализациями
- Cross-platform тестирование
- Версионная совместимость

### 🗂 04-registry (Средний уровень)

**Цель**: Централизованное управление типами и дескрипторами

#### type-registry.swift
- Создание и настройка TypeRegistry
- Регистрация типов
- Поиск типов по именам
- Разрешение зависимостей между типами

#### descriptor-pool.swift
- Работа с DescriptorPool
- Batch добавление дескрипторов
- Создание сообщений через pool
- Управление жизненным циклом дескрипторов

#### type-discovery.swift
- Динамическое обнаружение типов
- Анализ неизвестных типов в runtime
- Автоматическая регистрация зависимостей

#### multi-file-registry.swift
- Работа с множественными .proto файлами
- Управление пространствами имен
- Разрешение конфликтов имен

### ⭐ 05-well-known-types (Средне-продвинутый уровень)

**Цель**: Демонстрация всех Well-Known Types и их интеграции

#### timestamp-demo.swift
- google.protobuf.Timestamp ↔ Foundation.Date
- Работа с часовыми поясами
- Точность до наносекунд
- Валидация временных диапазонов

#### duration-demo.swift
- google.protobuf.Duration ↔ TimeInterval
- Отрицательные интервалы времени
- Utility операции (abs, negated, zero)
- Валидация seconds/nanos полей

#### empty-demo.swift
- google.protobuf.Empty использование
- Placeholder для пустых ответов
- Интеграция в RPC сервисы

#### field-mask-demo.swift
- FieldMask для partial updates
- Path notation ("user.profile.name")
- Set операции (union, intersection, difference)
- Валидация путей

#### struct-demo.swift
- google.protobuf.Struct как JSON объект
- Динамические структуры данных
- Вложенные структуры
- Конвертация Dictionary ↔ Struct

#### value-demo.swift
- google.protobuf.Value как универсальное значение
- Все типы значений (null, number, string, bool, struct, list)
- Type detection и конвертация

#### any-demo.swift
- google.protobuf.Any для type erasure
- Pack/unpack операции
- Type URL управление
- Динамическое разрешение типов

#### well-known-registry.swift
- WellKnownTypesRegistry интеграция
- Автоматическая регистрация обработчиков
- Custom well-known type handlers

### 🌐 06-grpc (Продвинутый уровень)

**Цель**: Интеграция с gRPC для динамических вызовов

#### dynamic-client.swift
- Создание динамического gRPC клиента
- Загрузка .proto файлов в runtime
- Выполнение RPC без статической генерации

#### service-discovery.swift
- Обнаружение доступных сервисов
- Анализ методов сервиса
- Построение client stub'ов динамически

#### unary-calls.swift
- Выполнение unary RPC вызовов
- Request/response сообщения
- Error handling

#### error-handling.swift
- gRPC статус коды
- Обработка сетевых ошибок
- Retry logic
- Timeout handling

#### metadata-options.swift
- Работа с gRPC метаданными
- CallOptions настройка
- Authentication headers
- Custom headers

### 🚀 07-advanced (Продвинутый уровень)

**Цель**: Сложные сценарии интеграции и оптимизации

#### descriptor-bridge.swift
- Конвертация между SwiftProtoReflect и Swift Protobuf дескрипторами
- Bi-directional mapping
- Сохранение метаданных при конвертации

#### static-message-bridge.swift
- Интеграция существующих статических Swift Protobuf сообщений
- Конвертация static ↔ dynamic
- Batch конвертация

#### batch-operations.swift
- Массовые операции с сообщениями
- Bulk сериализация/десериализация
- Параллельная обработка

#### memory-optimization.swift
- Стратегии оптимизации памяти
- Object pooling
- Lazy loading дескрипторов
- Memory profiling

#### thread-safety.swift
- Thread-safe операции
- Concurrent access patterns
- Synchronization strategies

#### custom-extensions.swift
- Создание custom extensions для DynamicMessage
- Protocol conformances
- Helper методы и computed properties

### 🏢 08-real-world (Expert уровень)

**Цель**: Реальные архитектурные паттерны и сценарии

#### config-system.swift
- Система конфигурации на основе protobuf
- Динамическая валидация настроек
- Hot reload конфигурации
- Environment-specific configs

#### api-gateway.swift
- API Gateway с динамическими схемами
- Request/response трансформация
- Schema validation
- Routing на основе protobuf definitions

#### message-transform.swift
- Трансформация между различными версиями сообщений
- Field mapping и renaming
- Data migration utilities
- Backward compatibility helpers

#### validation-framework.swift
- Комплексный validation framework
- Custom validation rules
- Conditional validation
- Error reporting и localization

#### proto-repl.swift
- Интерактивная REPL для protobuf
- Command line interface
- Dynamic schema loading
- Interactive message building

## 🛠 Технические файлы

### Makefile

```makefile
# SwiftProtoReflect Examples Makefile

.PHONY: help setup build clean run-all run-basic run-serialization run-advanced demo

# Цвета для вывода
GREEN = \033[0;32m
YELLOW = \033[1;33m  
RED = \033[0;31m
NC = \033[0m # No Color

# Переменные
BUILD_CONFIG = release
LIBRARY_PATH = ../.build/$(BUILD_CONFIG)
SWIFT_FLAGS = -I $(LIBRARY_PATH) -L $(LIBRARY_PATH) -lSwiftProtoReflect

help:
	@echo "$(GREEN)SwiftProtoReflect Examples$(NC)"
	@echo "============================="
	@echo ""
	@echo "Available commands:"
	@echo "  $(YELLOW)make setup$(NC)          - Build SwiftProtoReflect library"
	@echo "  $(YELLOW)make run-all$(NC)        - Run all examples with progress report"  
	@echo "  $(YELLOW)make run-basic$(NC)      - Run basic usage examples (01-basic-usage/)"
	@echo "  $(YELLOW)make run-serialization$(NC) - Run serialization examples (03-serialization/)"
	@echo "  $(YELLOW)make run-advanced$(NC)   - Run advanced examples (07-advanced/)"
	@echo "  $(YELLOW)make demo$(NC)           - Interactive demo mode"
	@echo "  $(YELLOW)make clean$(NC)          - Clean build artifacts"
	@echo ""
	@echo "Individual category commands:"
	@echo "  $(YELLOW)make run-dynamic$(NC)    - Run dynamic messages examples"
	@echo "  $(YELLOW)make run-registry$(NC)   - Run registry examples"
	@echo "  $(YELLOW)make run-wellknown$(NC)  - Run well-known types examples"
	@echo "  $(YELLOW)make run-grpc$(NC)       - Run gRPC examples"
	@echo "  $(YELLOW)make run-realworld$(NC)  - Run real-world examples"

setup:
	@echo "$(YELLOW)🔨 Building SwiftProtoReflect library...$(NC)"
	@cd .. && swift build -c $(BUILD_CONFIG)
	@echo "$(GREEN)✅ Library built successfully!$(NC)"

build: setup

run-all: setup
	@echo "$(GREEN)🚀 Running all SwiftProtoReflect examples...$(NC)"
	@./run-all.sh

run-basic: setup
	@echo "$(GREEN)📚 Running basic usage examples...$(NC)"
	@for example in 01-basic-usage/*.swift; do \
		echo "$(YELLOW)Running $$example...$(NC)"; \
		swift $(SWIFT_FLAGS) "$$example" || exit 1; \
		echo ""; \
	done
	@echo "$(GREEN)✅ Basic examples completed!$(NC)"

run-dynamic: setup
	@echo "$(GREEN)🔧 Running dynamic messages examples...$(NC)"  
	@for example in 02-dynamic-messages/*.swift; do \
		echo "$(YELLOW)Running $$example...$(NC)"; \
		swift $(SWIFT_FLAGS) "$$example" || exit 1; \
		echo ""; \
	done

run-serialization: setup
	@echo "$(GREEN)💾 Running serialization examples...$(NC)"
	@for example in 03-serialization/*.swift; do \
		echo "$(YELLOW)Running $$example...$(NC)"; \
		swift $(SWIFT_FLAGS) "$$example" || exit 1; \
		echo ""; \
	done

run-registry: setup
	@echo "$(GREEN)🗂 Running registry examples...$(NC)"
	@for example in 04-registry/*.swift; do \
		echo "$(YELLOW)Running $$example...$(NC)"; \
		swift $(SWIFT_FLAGS) "$$example" || exit 1; \
		echo ""; \
	done

run-wellknown: setup
	@echo "$(GREEN)⭐ Running well-known types examples...$(NC)"
	@for example in 05-well-known-types/*.swift; do \
		echo "$(YELLOW)Running $$example...$(NC)"; \
		swift $(SWIFT_FLAGS) "$$example" || exit 1; \
		echo ""; \
	done

run-grpc: setup
	@echo "$(GREEN)🌐 Running gRPC examples...$(NC)"
	@for example in 06-grpc/*.swift; do \
		echo "$(YELLOW)Running $$example...$(NC)"; \
		swift $(SWIFT_FLAGS) "$$example" || exit 1; \
		echo ""; \
	done

run-advanced: setup
	@echo "$(GREEN)🚀 Running advanced examples...$(NC)"
	@for example in 07-advanced/*.swift; do \
		echo "$(YELLOW)Running $$example...$(NC)"; \
		swift $(SWIFT_FLAGS) "$$example" || exit 1; \
		echo ""; \
	done

run-realworld: setup
	@echo "$(GREEN)🏢 Running real-world examples...$(NC)"
	@for example in 08-real-world/*.swift; do \
		echo "$(YELLOW)Running $$example...$(NC)"; \
		swift $(SWIFT_FLAGS) "$$example" || exit 1; \
		echo ""; \
	done

demo: setup
	@echo "$(GREEN)🎮 Starting interactive demo...$(NC)"
	@./interactive-demo.sh

clean:
	@echo "$(YELLOW)🧹 Cleaning build artifacts...$(NC)"
	@cd .. && swift package clean
	@echo "$(GREEN)✅ Clean completed!$(NC)"

# Утилити команды
check-example:
	@if [ -z "$(EXAMPLE)" ]; then \
		echo "$(RED)❌ Please specify EXAMPLE variable$(NC)"; \
		echo "Usage: make check-example EXAMPLE=01-basic-usage/hello-world.swift"; \
		exit 1; \
	fi
	@echo "$(YELLOW)🔍 Checking $(EXAMPLE)...$(NC)"
	@swift $(SWIFT_FLAGS) $(EXAMPLE)

list-examples:
	@echo "$(GREEN)📋 Available examples:$(NC)"
	@find . -name "*.swift" -not -path "./shared/*" | sort | sed 's|^\./||'
```

### run-all.sh

```bash
#!/bin/bash

# SwiftProtoReflect Examples - Automated Runner
# Запускает все примеры с детальным отчетом о прогрессе и результатах

set -e

# Конфигурация
BUILD_CONFIG="release"
LIBRARY_PATH="../.build/${BUILD_CONFIG}"
SWIFT_FLAGS="-I ${LIBRARY_PATH} -L ${LIBRARY_PATH} -lSwiftProtoReflect"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Статистика
TOTAL_EXAMPLES=0
PASSED_EXAMPLES=0
FAILED_EXAMPLES=0
START_TIME=$(date +%s)

# Функция для красивого заголовка
print_header() {
    local title="$1"
    local width=60
    local padding=$(( (width - ${#title}) / 2 ))
    
    echo -e "\n${BLUE}$(printf '═%.0s' $(seq 1 $width))${NC}"
    echo -e "${BLUE}$(printf '%*s' $padding)${WHITE}$title${BLUE}$(printf '%*s' $padding)${NC}"  
    echo -e "${BLUE}$(printf '═%.0s' $(seq 1 $width))${NC}\n"
}

# Функция для запуска категории примеров
run_category() {
    local category_path="$1"
    local category_name="$2"
    local category_icon="$3"
    local category_description="$4"
    
    if [ ! -d "$category_path" ]; then
        echo -e "${RED}❌ Directory not found: $category_path${NC}"
        return 1
    fi
    
    local swift_files=($(find "$category_path" -name "*.swift" | sort))
    
    if [ ${#swift_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️  No Swift files found in $category_path${NC}"
        return 0
    fi
    
    echo -e "${CYAN}${category_icon} ${category_name}${NC}"
    echo -e "${WHITE}${category_description}${NC}"
    echo -e "${BLUE}$(printf '─%.0s' $(seq 1 50))${NC}"
    
    local category_passed=0
    local category_failed=0
    
    for example_file in "${swift_files[@]}"; do
        local example_name=$(basename "$example_file" .swift)
        TOTAL_EXAMPLES=$((TOTAL_EXAMPLES + 1))
        
        echo -e -n "${YELLOW}🔄 Running ${example_name}... ${NC}"
        
        # Запуск примера с захватом вывода
        if output=$(timeout 30s swift $SWIFT_FLAGS "$example_file" 2>&1); then
            echo -e "${GREEN}✅ PASSED${NC}"
            PASSED_EXAMPLES=$((PASSED_EXAMPLES + 1))
            category_passed=$((category_passed + 1))
            
            # Опционально: показать краткий вывод для успешных примеров
            # echo -e "${WHITE}$(echo "$output" | head -n 2 | sed 's/^/  /')${NC}"
        else
            echo -e "${RED}❌ FAILED${NC}"
            FAILED_EXAMPLES=$((FAILED_EXAMPLES + 1))
            category_failed=$((category_failed + 1))
            
            # Показать ошибку
            echo -e "${RED}Error output:${NC}"
            echo -e "${RED}$(echo "$output" | tail -n 5 | sed 's/^/  /')${NC}"
        fi
    done
    
    # Статистика по категории
    local total_in_category=$((category_passed + category_failed))
    echo -e "${BLUE}$(printf '─%.0s' $(seq 1 50))${NC}"
    echo -e "📊 Category Results: ${GREEN}${category_passed}/${total_in_category} passed${NC}"
    
    if [ $category_failed -gt 0 ]; then
        echo -e "                    ${RED}${category_failed} failed${NC}"
    fi
    
    echo ""
}

# Главная функция
main() {
    print_header "SwiftProtoReflect Examples Runner"
    
    echo -e "${BLUE}🏗  Preparing environment...${NC}"
    
    # Проверка, что мы в правильной директории
    if [ ! -f "../Package.swift" ]; then
        echo -e "${RED}❌ Error: Please run this script from the examples/ directory${NC}"
        exit 1
    fi
    
    # Сборка библиотеки
    echo -e "${YELLOW}🔨 Building SwiftProtoReflect library...${NC}"
    cd .. && swift build -c $BUILD_CONFIG
    cd examples
    echo -e "${GREEN}✅ Library build completed${NC}\n"
    
    # Проверка доступности библиотеки
    if [ ! -f "${LIBRARY_PATH}/libSwiftProtoReflect.a" ] && [ ! -f "${LIBRARY_PATH}/libSwiftProtoReflect.dylib" ]; then
        echo -e "${RED}❌ Error: SwiftProtoReflect library not found at ${LIBRARY_PATH}${NC}"
        exit 1
    fi
    
    # Запуск примеров по категориям
    run_category "01-basic-usage" "Basic Usage" "🔰" "Learn the fundamentals of SwiftProtoReflect"
    run_category "02-dynamic-messages" "Dynamic Messages" "🔧" "Advanced dynamic message manipulation"
    run_category "03-serialization" "Serialization" "💾" "Binary and JSON serialization/deserialization"
    run_category "04-registry" "Type Registry" "🗂" "Centralized type management and discovery"
    run_category "05-well-known-types" "Well-Known Types" "⭐" "Google Protocol Buffers standard types"
    run_category "06-grpc" "gRPC Integration" "🌐" "Dynamic gRPC client functionality"
    run_category "07-advanced" "Advanced Features" "🚀" "Complex integration scenarios and optimizations"
    run_category "08-real-world" "Real-World Scenarios" "🏢" "Production-ready architectural patterns"
    
    # Финальная статистика
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    print_header "Final Results"
    
    echo -e "${WHITE}📊 Test Results Summary:${NC}"
    echo -e "   Total Examples: ${BLUE}${TOTAL_EXAMPLES}${NC}"
    echo -e "   Passed: ${GREEN}${PASSED_EXAMPLES}${NC}"
    echo -e "   Failed: ${RED}${FAILED_EXAMPLES}${NC}"
    echo -e "   Success Rate: ${GREEN}$(( PASSED_EXAMPLES * 100 / TOTAL_EXAMPLES ))%${NC}"
    echo -e "   Execution Time: ${YELLOW}${DURATION}s${NC}"
    
    if [ $FAILED_EXAMPLES -eq 0 ]; then
        echo -e "\n${GREEN}🎉 All examples passed successfully!${NC}"
        echo -e "${GREEN}   SwiftProtoReflect is working correctly.${NC}"
    else
        echo -e "\n${RED}⚠️  Some examples failed.${NC}"
        echo -e "${RED}   Please check the errors above and fix any issues.${NC}"
        exit 1
    fi
    
    echo -e "\n${CYAN}📚 Next Steps:${NC}"
    echo -e "   • Explore individual examples in detail"
    echo -e "   • Check out docs/ for comprehensive documentation"
    echo -e "   • Try the interactive demo: ${YELLOW}make demo${NC}"
    echo -e "   • Build your own examples using the templates in resources/templates/\n"
}

# Запуск с обработкой прерываний
trap 'echo -e "\n${RED}❌ Execution interrupted${NC}"; exit 1' INT TERM

main "$@"
```

## 🎯 План реализации (Roadmap)

### Фаза 1: Инфраструктура (1-2 дня)
1. ✅ Создание структуры папок
2. ✅ Настройка Makefile и run-all.sh
3. ✅ Создание shared утилит (logger, console-utils, etc.)
4. ✅ Подготовка templates для примеров
5. ✅ Создание основных README файлов

### Фаза 2: Базовые примеры (2-3 дня)
1. ✅ 01-basic-usage (4 примера)
2. ✅ 02-dynamic-messages (5 примеров) 
3. ✅ 03-serialization (6 примеров)
4. ✅ 04-registry (4 примера)

### Фаза 3: Продвинутые примеры (3-4 дня)  
1. ✅ 05-well-known-types (8 примеров)
2. ✅ 06-grpc (5 примеров)
3. ✅ 07-advanced (6 примеров)

### Фаза 4: Реальные сценарии (2-3 дня)
1. ✅ 08-real-world (5 примеров)
2. ✅ Тестирование всех примеров
3. ✅ Оптимизация производительности
4. ✅ Финальная документация

### Фаза 5: Полировка и документация (1-2 дня)
1. ✅ Comprehensive README файлы для каждой категории
2. ✅ Детальная документация в docs/
3. ✅ Troubleshooting guide
4. ✅ Contributing guidelines
5. ✅ API reference

**Общее время реализации: 9-14 дней**

## 📋 Контрольный список (Checklist)

### Обязательные компоненты
- [ ] 43 исполняемых Swift скрипта
- [ ] Makefile с командами для каждой категории
- [ ] run-all.sh с детальной отчетностью
- [ ] shared/ модуль с утилитами
- [ ] resources/ с proto файлами и тестовыми данными
- [ ] Comprehensive README для каждой категории
- [ ] docs/ с подробной документацией

### Качество примеров
- [ ] Каждый пример имеет подробные комментарии
- [ ] Ясные инструкции по запуску
- [ ] Обработка ошибок во всех примерах
- [ ] Красивый консольный вывод
- [ ] Ссылки на следующие примеры

### Техническое качество
- [ ] Все примеры компилируются без ошибок
- [ ] Примеры проходят через run-all.sh
- [ ] Нет предупреждений компилятора
- [ ] Соответствие Swift coding standards
- [ ] Performance тесты выполняются адекватно

### Документация
- [ ] Подробные README файлы
- [ ] API reference
- [ ] Troubleshooting guide
- [ ] Contributing guidelines
- [ ] Getting started guide

## 🚀 Начало реализации

### Первые шаги
1. Создать базовую структуру папок
2. Настроить Makefile и run-all.sh
3. Создать shared утилиты
4. Реализовать hello-world.swift как proof of concept
5. Протестировать инфраструктуру

### Команды для старта
```bash
# 1. Создать структуру
mkdir -p examples/{01-basic-usage,02-dynamic-messages,03-serialization,04-registry,05-well-known-types,06-grpc,07-advanced,08-real-world,shared,resources/{proto,data,templates},docs}

# 2. Создать основные файлы
touch examples/{README.md,GETTING_STARTED.md,Makefile,run-all.sh}
chmod +x examples/run-all.sh

# 3. Начать с hello-world.swift
touch examples/01-basic-usage/hello-world.swift
chmod +x examples/01-basic-usage/hello-world.swift
```

---

Этот план обеспечивает создание comprehensive набора примеров, которые покроют все аспекты SwiftProtoReflect и помогут пользователям освоить библиотеку от основ до продвинутых сценариев использования.
