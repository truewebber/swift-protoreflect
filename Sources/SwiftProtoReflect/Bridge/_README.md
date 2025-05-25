# Bridge Module

Этот модуль отвечает за интеграцию с существующей Swift Protobuf библиотекой. Он обеспечивает:

- Конвертацию между статическими и динамическими сообщениями
- Мост между нашими дескрипторами и дескрипторами Swift Protobuf
- Интеграцию с существующей инфраструктурой Swift Protobuf

## Состояние модуля

- [x] StaticMessageBridge - ✅ ЗАВЕРШЕНО
- [x] DescriptorBridge - ✅ ЗАВЕРШЕНО

## Компоненты

### StaticMessageBridge
Обеспечивает конвертацию между статическими Swift Protobuf сообщениями и динамическими DynamicMessage объектами:
- Конвертация статических сообщений в динамические для рефлексии
- Создание статических сообщений из динамических для интеграции с существующим кодом
- Batch конвертация массивов сообщений
- Проверка совместимости типов
- Расширения для удобного использования

### DescriptorBridge
Обеспечивает конвертацию между дескрипторами SwiftProtoReflect и Swift Protobuf:
- Конвертация MessageDescriptor ↔ Google_Protobuf_DescriptorProto
- Конвертация FieldDescriptor ↔ Google_Protobuf_FieldDescriptorProto
- Конвертация EnumDescriptor ↔ Google_Protobuf_EnumDescriptorProto
- Конвертация FileDescriptor ↔ Google_Protobuf_FileDescriptorProto
- Конвертация ServiceDescriptor ↔ Google_Protobuf_ServiceDescriptorProto
- Round-trip совместимость

## Взаимодействие с другими модулями

- **Dynamic**: для конвертации между статическими и динамическими сообщениями
- **Descriptor**: для конвертации между разными представлениями дескрипторов
- **Serialization**: для использования Swift Protobuf сериализации
