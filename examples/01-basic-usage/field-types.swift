/**
 * 🎯 SwiftProtoReflect Example: Field Types Demo
 * 
 * Описание: Демонстрация всех скалярных типов полей Protocol Buffers
 * Ключевые концепции: FieldType, скалярные типы, repeated поля, map поля
 * Сложность: 🔰 Начальный
 * Время выполнения: < 10 секунд
 * 
 * Что изучите:
 * - Все скалярные типы Protocol Buffers
 * - Repeated поля (массивы)
 * - Map поля (key-value)
 * - Enum поля
 * - Валидация типов полей
 * 
 * Запуск: 
 *   swift run FieldTypes
 *   make run-basic
 */

import Foundation
import SwiftProtoReflect
import ExampleUtils

@main
struct FieldTypesExample {
    static func main() throws {
        ExampleUtils.printHeader("Protocol Buffers Field Types - Все типы полей")
        
        try step1_scalarTypes()
        try step2_repeatedFields()
        try step3_mapFields()
        try step4_enumFields()
        try step5_validationDemo()
        
        ExampleUtils.printSuccess("Вы изучили все основные типы полей Protocol Buffers!")
        
        ExampleUtils.printNext([
            "Следующий: simple-message.swift - создание более сложных сообщений",
            "Также изучите: basic-descriptors.swift - работа с метаданными",
            "Продвинутые: nested-messages.swift - вложенные сообщения"
        ])
    }
    
    // MARK: - Implementation Steps
    
    private static func step1_scalarTypes() throws {
        ExampleUtils.printStep(1, "Скалярные типы Protocol Buffers")
        
        let (messageDescriptor, _) = try createAllTypesMessage()
        let factory = MessageFactory()
        var message = factory.createMessage(from: messageDescriptor)
        
        // Установка значений для всех скалярных типов
        try message.set(42.5, forField: "double_field")        // double
        try message.set(Float(3.14), forField: "float_field")  // float
        try message.set(Int32(100), forField: "int32_field")   // int32
        try message.set(Int64(1000), forField: "int64_field")  // int64
        try message.set(UInt32(200), forField: "uint32_field") // uint32
        try message.set(UInt64(2000), forField: "uint64_field") // uint64
        try message.set(Int32(-50), forField: "sint32_field")  // sint32 (ZigZag)
        try message.set(Int64(-500), forField: "sint64_field") // sint64 (ZigZag)
        try message.set(UInt32(300), forField: "fixed32_field") // fixed32
        try message.set(UInt64(3000), forField: "fixed64_field") // fixed64
        try message.set(Int32(-75), forField: "sfixed32_field") // sfixed32
        try message.set(Int64(-750), forField: "sfixed64_field") // sfixed64
        try message.set(true, forField: "bool_field")          // bool
        try message.set("Hello Protocol Buffers!", forField: "string_field") // string
        try message.set(Data("Binary data".utf8), forField: "bytes_field") // bytes
        
        print("  ✅ Все скалярные значения установлены")
        
        // Читаем и проверяем значения - разбиваем сложное выражение для компилятора
        let scalarData: [String: Any] = [
            "double": try message.get(forField: "double_field") as? Double ?? 0,
            "float": try message.get(forField: "float_field") as? Float ?? 0,
            "int32": try message.get(forField: "int32_field") as? Int32 ?? 0,
            "int64": try message.get(forField: "int64_field") as? Int64 ?? 0,
            "uint32": try message.get(forField: "uint32_field") as? UInt32 ?? 0,
            "uint64": try message.get(forField: "uint64_field") as? UInt64 ?? 0,
        ]
        
        let moreScalarData: [String: Any] = [
            "sint32": try message.get(forField: "sint32_field") as? Int32 ?? 0,
            "sint64": try message.get(forField: "sint64_field") as? Int64 ?? 0,
            "bool": try message.get(forField: "bool_field") as? Bool ?? false,
            "string": try message.get(forField: "string_field") as? String ?? ""
        ]
        
        // Объединяем данные и показываем таблицу
        var allScalarData = scalarData
        for (key, value) in moreScalarData {
            allScalarData[key] = value
        }
        
        ExampleUtils.printTable(allScalarData, title: "Скалярные значения")
        
        if let bytesData = try message.get(forField: "bytes_field") as? Data {
            let bytesString = String(data: bytesData, encoding: .utf8) ?? "binary"
            print("  📦 bytes_field: \(bytesString) (\(bytesData.count) bytes)")
        }
    }
    
    private static func step2_repeatedFields() throws {
        ExampleUtils.printStep(2, "Repeated поля (массивы)")
        
        let (messageDescriptor, _) = try createRepeatedFieldsMessage()
        let factory = MessageFactory()
        var message = factory.createMessage(from: messageDescriptor)
        
        // Устанавливаем repeated поля
        try message.set([Int32(1), Int32(2), Int32(3), Int32(4), Int32(5)], forField: "repeated_int32")
        try message.set(["apple", "banana", "cherry", "date"], forField: "repeated_string")
        try message.set([true, false, true, false], forField: "repeated_bool")
        try message.set([1.1, 2.2, 3.3], forField: "repeated_double")
        
        print("  ✅ Repeated поля установлены")
        
        // Читаем repeated поля
        if let numbers = try message.get(forField: "repeated_int32") as? [Int32] {
            print("  🔢 repeated_int32: \(numbers)")
        }
        
        if let strings = try message.get(forField: "repeated_string") as? [String] {
            print("  📝 repeated_string: \(strings)")
        }
        
        if let bools = try message.get(forField: "repeated_bool") as? [Bool] {
            print("  ☑️  repeated_bool: \(bools)")
        }
        
        if let doubles = try message.get(forField: "repeated_double") as? [Double] {
            print("  🔀 repeated_double: \(doubles)")
        }
        
        let totalElements = (try? message.get(forField: "repeated_int32") as? [Int32])?.count ?? 0
        print("  📊 Общее количество элементов в repeated_int32: \(totalElements)")
    }
    
    private static func step3_mapFields() throws {
        ExampleUtils.printStep(3, "Map поля (key-value) - упрощенная демонстрация")
        
        let (messageDescriptor, _) = try createMapFieldsMessage()
        let factory = MessageFactory()
        var message = factory.createMessage(from: messageDescriptor)
        
        // Поскольку Map поля требуют сложной настройки в Protocol Buffers,
        // покажем концепцию через обычные поля
        try message.set("key1=value1,key2=value2,key3=value3", forField: "map_string_int32")
        try message.set("10=ten,20=twenty,30=thirty", forField: "map_int32_string")
        try message.set("enabled=true,disabled=false", forField: "map_string_bool")
        
        print("  ✅ Map-like данные установлены (как строки для демонстрации)")
        
        // Читаем map-like поля
        if let stringIntMap = try message.get(forField: "map_string_int32") as? String {
            print("  🗝  map_string_int32: \(stringIntMap)")
        }
        
        if let intStringMap = try message.get(forField: "map_int32_string") as? String {
            print("  🔑 map_int32_string: \(intStringMap)")
        }
        
        if let stringBoolMap = try message.get(forField: "map_string_bool") as? String {
            print("  ✅ map_string_bool: \(stringBoolMap)")
        }
        
        ExampleUtils.printInfo("Примечание: Настоящие Map поля требуют специальной конфигурации дескрипторов")
    }
    
    private static func step4_enumFields() throws {
        ExampleUtils.printStep(4, "Enum поля")
        
        let (messageDescriptor, fileDescriptor) = try createEnumFieldsMessage()
        let factory = MessageFactory()
        var message = factory.createMessage(from: messageDescriptor)
        
        // Enum в Protocol Buffers представляется как int32
        try message.set(Int32(1), forField: "status") // ACTIVE = 1
        try message.set(Int32(2), forField: "priority") // HIGH = 2
        
        print("  ✅ Enum поля установлены")
        
        // Читаем enum поля
        if let status = try message.get(forField: "status") as? Int32 {
            let statusName = getStatusName(status)
            print("  📊 status: \(status) (\(statusName))")
        }
        
        if let priority = try message.get(forField: "priority") as? Int32 {
            let priorityName = getPriorityName(priority)
            print("  ⚡ priority: \(priority) (\(priorityName))")
        }
        
        // Покажем все доступные enum значения
        if let statusEnum = fileDescriptor.enums.values.first(where: { $0.name == "Status" }) {
            print("  📋 Доступные Status значения:")
            for value in statusEnum.allValues() {
                print("    \(value.name) = \(value.number)")
            }
        }
    }
    
    private static func step5_validationDemo() throws {
        ExampleUtils.printStep(5, "Валидация типов и демонстрация ошибок")
        
        let (messageDescriptor, _) = try createAllTypesMessage()
        let factory = MessageFactory()
        var message = factory.createMessage(from: messageDescriptor)
        
        print("  🧪 Тестирование валидации типов:")
        
        // Правильные типы
        do {
            try message.set("Valid string", forField: "string_field")
            print("  ✅ Правильный тип string: OK")
        } catch {
            print("  ❌ Ошибка с правильным типом: \(error)")
        }
        
        // Неправильные типы (будут обработаны библиотекой)
        do {
            try message.set(123, forField: "string_field") // int вместо string
            print("  ⚠️  Попытка установить int в string поле: принято (возможна автоконвертация)")
        } catch {
            print("  ✅ Правильно отклонен неверный тип: \(error)")
        }
        
        // Несуществующее поле
        do {
            try message.set("test", forField: "nonexistent_field")
            print("  ❌ Неожиданно принято несуществующее поле")
        } catch {
            print("  ✅ Правильно отклонено несуществующее поле")
        }
        
        // Проверим типы полей
        print("\n  📋 Информация о типах полей:")
        let fieldsToShow = Array(messageDescriptor.fields.values.prefix(5))
        for field in fieldsToShow {
            print("    \(field.name): \(field.type)")
        }
    }
    
    // MARK: - Helper Methods
    
    private static func createAllTypesMessage() throws -> (MessageDescriptor, FileDescriptor) {
        var fileDescriptor = FileDescriptor(name: "types.proto", package: "example")
        var messageDescriptor = MessageDescriptor(name: "AllTypes", parent: fileDescriptor)
        
        // Добавляем все скалярные типы
        messageDescriptor.addField(FieldDescriptor(name: "double_field", number: 1, type: .double))
        messageDescriptor.addField(FieldDescriptor(name: "float_field", number: 2, type: .float))
        messageDescriptor.addField(FieldDescriptor(name: "int32_field", number: 3, type: .int32))
        messageDescriptor.addField(FieldDescriptor(name: "int64_field", number: 4, type: .int64))
        messageDescriptor.addField(FieldDescriptor(name: "uint32_field", number: 5, type: .uint32))
        messageDescriptor.addField(FieldDescriptor(name: "uint64_field", number: 6, type: .uint64))
        messageDescriptor.addField(FieldDescriptor(name: "sint32_field", number: 7, type: .sint32))
        messageDescriptor.addField(FieldDescriptor(name: "sint64_field", number: 8, type: .sint64))
        messageDescriptor.addField(FieldDescriptor(name: "fixed32_field", number: 9, type: .fixed32))
        messageDescriptor.addField(FieldDescriptor(name: "fixed64_field", number: 10, type: .fixed64))
        messageDescriptor.addField(FieldDescriptor(name: "sfixed32_field", number: 11, type: .sfixed32))
        messageDescriptor.addField(FieldDescriptor(name: "sfixed64_field", number: 12, type: .sfixed64))
        messageDescriptor.addField(FieldDescriptor(name: "bool_field", number: 13, type: .bool))
        messageDescriptor.addField(FieldDescriptor(name: "string_field", number: 14, type: .string))
        messageDescriptor.addField(FieldDescriptor(name: "bytes_field", number: 15, type: .bytes))
        
        fileDescriptor.addMessage(messageDescriptor)
        return (messageDescriptor, fileDescriptor)
    }
    
    private static func createRepeatedFieldsMessage() throws -> (MessageDescriptor, FileDescriptor) {
        var fileDescriptor = FileDescriptor(name: "repeated.proto", package: "example")
        var messageDescriptor = MessageDescriptor(name: "RepeatedTypes", parent: fileDescriptor)
        
        messageDescriptor.addField(FieldDescriptor(name: "repeated_int32", number: 1, type: .int32, isRepeated: true))
        messageDescriptor.addField(FieldDescriptor(name: "repeated_string", number: 2, type: .string, isRepeated: true))
        messageDescriptor.addField(FieldDescriptor(name: "repeated_bool", number: 3, type: .bool, isRepeated: true))
        messageDescriptor.addField(FieldDescriptor(name: "repeated_double", number: 4, type: .double, isRepeated: true))
        
        fileDescriptor.addMessage(messageDescriptor)
        return (messageDescriptor, fileDescriptor)
    }
    
    private static func createMapFieldsMessage() throws -> (MessageDescriptor, FileDescriptor) {
        var fileDescriptor = FileDescriptor(name: "maps.proto", package: "example")
        var messageDescriptor = MessageDescriptor(name: "MapTypes", parent: fileDescriptor)
        
        // Упрощенная демонстрация map концепции через обычные string поля
        messageDescriptor.addField(FieldDescriptor(name: "map_string_int32", number: 1, type: .string))
        messageDescriptor.addField(FieldDescriptor(name: "map_int32_string", number: 2, type: .string))
        messageDescriptor.addField(FieldDescriptor(name: "map_string_bool", number: 3, type: .string))
        
        fileDescriptor.addMessage(messageDescriptor)
        return (messageDescriptor, fileDescriptor)
    }
    
    private static func createEnumFieldsMessage() throws -> (MessageDescriptor, FileDescriptor) {
        var fileDescriptor = FileDescriptor(name: "enums.proto", package: "example")
        
        // Создаем enum Status
        var statusEnum = EnumDescriptor(name: "Status", parent: fileDescriptor)
        statusEnum.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
        statusEnum.addValue(EnumDescriptor.EnumValue(name: "ACTIVE", number: 1))
        statusEnum.addValue(EnumDescriptor.EnumValue(name: "INACTIVE", number: 2))
        
        // Создаем enum Priority
        var priorityEnum = EnumDescriptor(name: "Priority", parent: fileDescriptor)
        priorityEnum.addValue(EnumDescriptor.EnumValue(name: "LOW", number: 0))
        priorityEnum.addValue(EnumDescriptor.EnumValue(name: "MEDIUM", number: 1))
        priorityEnum.addValue(EnumDescriptor.EnumValue(name: "HIGH", number: 2))
        
        fileDescriptor.addEnum(statusEnum)
        fileDescriptor.addEnum(priorityEnum)
        
        // Создаем сообщение с enum полями
        var messageDescriptor = MessageDescriptor(name: "EnumMessage", parent: fileDescriptor)
        messageDescriptor.addField(FieldDescriptor(name: "status", number: 1, type: .int32)) // enum как int32
        messageDescriptor.addField(FieldDescriptor(name: "priority", number: 2, type: .int32)) // enum как int32
        
        fileDescriptor.addMessage(messageDescriptor)
        return (messageDescriptor, fileDescriptor)
    }
    
    private static func getStatusName(_ value: Int32) -> String {
        switch value {
        case 0: return "UNKNOWN"
        case 1: return "ACTIVE"  
        case 2: return "INACTIVE"
        default: return "INVALID"
        }
    }
    
    private static func getPriorityName(_ value: Int32) -> String {
        switch value {
        case 0: return "LOW"
        case 1: return "MEDIUM"
        case 2: return "HIGH"
        default: return "INVALID"
        }
    }
}
