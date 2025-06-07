# 🔰 Basic Usage - Базовое использование SwiftProtoReflect

Добро пожаловать в категорию **базового использования** SwiftProtoReflect! Эти примеры познакомят вас с основными концепциями и возможностями библиотеки.

## 📚 Примеры в этой категории

### ✅ Реализованные примеры

### 1. `hello-world.swift` - Первое знакомство
**Сложность**: 🔰 Начальный  
**Время выполнения**: < 5 секунд

Самый простой пример для начала работы с SwiftProtoReflect. Вы изучите:
- Создание файлового дескриптора (FileDescriptor)
- Определение сообщения с полями (MessageDescriptor)
- Создание экземпляра динамического сообщения (DynamicMessage)
- Установка и чтение значений полей
- Основы работы с TypeRegistry

```bash
# Запуск
make run-basic
# или
./hello-world.swift
# или
swift -I ../.build/release -L ../.build/release -lSwiftProtoReflect hello-world.swift
```

### 2. `field-types.swift` - Все типы полей Protocol Buffers
**Сложность**: 🔰 Начальный  
**Время выполнения**: < 10 секунд

Comprehensive демонстрация всех типов полей Protocol Buffers. Вы изучите:
- Все скалярные типы (double, float, int32, int64, uint32, uint64, sint32, sint64, fixed32, fixed64, sfixed32, sfixed64, bool, string, bytes)
- Repeated поля (массивы)
- Map поля (key-value)
- Enum поля
- Валидация типов полей

```bash
# Запуск
swift -I ../.build/release -L ../.build/release -lSwiftProtoReflect field-types.swift
```

### 🚧 Планируемые примеры

### 3. `simple-message.swift` - Создание более сложных сообщений
**Статус**: Планируется  
**Сложность**: 🔰 Начальный

Создание сообщений с:
- Optional и required семантикой
- Default значениями
- Более сложной структурой полей

### 4. `basic-descriptors.swift` - Работа с дескрипторами и метаданными
**Статус**: Планируется  
**Сложность**: 🔰 Начальный

Детальная работа с:
- Дескрипторами и их иерархией
- Извлечением метаданных
- Навигацией по структуре типов

## 🚀 Быстрый запуск

### Автоматический запуск всех примеров категории
```bash
make run-basic
```

### Запуск конкретного примера
```bash
make check-example EXAMPLE=01-basic-usage/hello-world.swift
```

### Прямой запуск
```bash
# Сначала соберите библиотеку (если еще не собрана)
make setup

# Затем запустите пример
swift -I ../.build/release -L ../.build/release -lSwiftProtoReflect 01-basic-usage/hello-world.swift
```

## 📋 Требования

- Swift 6.0+
- SwiftProtoReflect библиотека (собирается автоматически через `make setup`)
- macOS 14.0+ или Linux с Swift runtime

## 🎯 Рекомендуемый порядок изучения

1. **Начните с**: `hello-world.swift` - основы создания динамических сообщений
2. **Затем изучите**: `field-types.swift` - все типы полей Protocol Buffers
3. **Продолжите с**: `simple-message.swift` - более сложные структуры (когда будет готов)
4. **Завершите**: `basic-descriptors.swift` - продвинутая работа с метаданными (когда будет готов)

## 🔗 Связанные концепции

После изучения основ переходите к:
- **02-dynamic-messages/** - Продвинутая работа с динамическими сообщениями
- **03-serialization/** - Сериализация и десериализация
- **04-registry/** - Централизованное управление типами

## 💡 Полезные команды

```bash
# Посмотреть все доступные примеры
make list-examples

# Проверить статистику примеров
make stats

# Получить справку
make help
```

## 🐛 Troubleshooting

### Ошибка: "Library not found"
```bash
# Решение: соберите библиотеку
make setup
```

### Ошибка: "Swift not found"
```bash
# Убедитесь что Swift установлен
swift --version
```

### Ошибка: "Permission denied"
```bash
# Сделайте файл исполняемым
chmod +x 01-basic-usage/hello-world.swift
```

## 📚 Дополнительные ресурсы

- **Основная документация**: `../docs/getting-started.md`
- **API Reference**: `../docs/api-reference.md`
- **Troubleshooting**: `../docs/troubleshooting.md`

---

**Статус реализации**: 2/4 примеров готово (50%)  
**Следующий этап**: Создание simple-message.swift и basic-descriptors.swift
