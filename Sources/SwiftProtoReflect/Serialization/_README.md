# Serialization Module

Этот модуль отвечает за сериализацию и десериализацию Protocol Buffers сообщений. Он обеспечивает:

- Бинарную сериализацию в wire format
- Десериализацию из бинарного формата
- JSON сериализацию согласно Protocol Buffers JSON mapping

## Состояние модуля

- [x] **BinarySerializer** ✅ - полностью реализован с покрытием тестами 90.77%
- [x] **BinaryDeserializer** ✅ - полностью реализован с покрытием тестами 89.69%
- [x] **WireFormat** ✅ - общие определения для wire типов Protocol Buffers
- [x] **JSONSerializer** ✅ - полностью реализован с полным покрытием тестами
- [ ] JSONDeserializer

## Реализованные компоненты

### BinarySerializer
- Поддержка всех скалярных типов Protocol Buffers
- Repeated fields (packed и non-packed)
- Map fields с различными типами ключей и значений
- Nested messages и enum поля
- ZigZag encoding для sint32/sint64
- Wire format совместимость со стандартом Protocol Buffers

### BinaryDeserializer
- Round-trip десериализация со всеми типами полей
- Обработка неизвестных полей для обратной совместимости
- ZigZag декодирование
- Обработка packed repeated fields
- Корректная валидация UTF-8 строк
- Детальная обработка ошибок

### JSONSerializer
- JSON сериализация согласно официальной Protocol Buffers JSON mapping
- Поддержка всех скалярных типов с корректным JSON представлением
- Специальные значения: Infinity, -Infinity, NaN для float/double
- Repeated fields как JSON массивы
- Map fields как JSON объекты
- Nested messages как вложенные JSON объекты
- Bytes поля как base64 строки
- int64/uint64 как строки в JSON (согласно спецификации)
- Настраиваемые опции сериализации (имена полей, форматирование)

### WireFormat
- Публичные определения WireType для совместного использования
- Соответствие стандарту Protocol Buffers wire format

## Взаимодействие с другими модулями

- **Dynamic**: для работы с динамическими сообщениями
- **Descriptor**: для получения метаданных о типах при сериализации/десериализации
- **Bridge**: для интеграции с Swift Protobuf сериализацией

## Покрытие тестами

- **BinarySerializer**: 90.77% покрытие кода (27 тестов)
- **BinaryDeserializer**: 89.69% покрытие кода (20 тестов)
- **JSONSerializer**: полное покрытие функциональности (20+ тестов)
- **Round-trip тестирование**: все типы полей проверены на совместимость сериализации/десериализации
