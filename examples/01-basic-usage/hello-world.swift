/**
 * 🚀 SwiftProtoReflect Example: Hello World
 * 
 * Описание: Простейший пример создания динамического Protocol Buffers сообщения
 * Ключевые концепции: FileDescriptor, MessageDescriptor, DynamicMessage, FieldDescriptor
 * Сложность: 🔰 Начальный
 * Время выполнения: < 5 секунд
 * 
 * Что изучите:
 * - Создание файлового дескриптора (FileDescriptor)
 * - Определение сообщения с полями (MessageDescriptor)
 * - Создание экземпляра динамического сообщения (DynamicMessage)
 * - Установка и чтение значений полей
 * - Основы работы с TypeRegistry
 * 
 * Запуск: 
 *   swift run HelloWorld
 */

import Foundation
import SwiftProtoReflect
import ExampleUtils

@main
struct HelloWorldExample {
    static func main() throws {
        ExampleUtils.printHeader("Hello World - Первое знакомство с SwiftProtoReflect")
        
        try step1_createFileDescriptor()
        try step2_definePersonMessage()
        try step3_createMessageInstance()
        try step4_workWithData()
        try step5_useTypeRegistry()
        
        ExampleUtils.printSuccess("Поздравляем! Вы создали ваше первое динамическое Protocol Buffers сообщение.")
        
        ExampleUtils.printNext([
            "Далее попробуйте: swift run FieldTypes - все типы полей Protocol Buffers",
            "Или изучите: simple-message.swift - создание более сложного сообщения",
            "Продвинутые: basic-descriptors.swift - детальная работа с дескрипторами"
        ])
    }
    
    // MARK: - Implementation Steps
    
    private static func step1_createFileDescriptor() throws {
        ExampleUtils.printStep(1, "Создание файлового дескриптора")
        
        // Создаем файловый дескриптор - основу для всех наших типов
        let fileDescriptor = FileDescriptor(name: "hello.proto", package: "example")
        print("  📄 Создан файл: \(fileDescriptor.name)")
        print("  📦 Пакет: \(fileDescriptor.package)")
        print("  🔗 Полное имя: \(fileDescriptor.name)")
    }
    
    private static func step2_definePersonMessage() throws {
        ExampleUtils.printStep(2, "Определение сообщения Person")
        
        // Создаем файловый дескриптор
        var fileDescriptor = FileDescriptor(name: "hello.proto", package: "example")
        
        // Создаем дескриптор сообщения Person
        var personMessage = MessageDescriptor(name: "Person", parent: fileDescriptor)
        
        // Добавляем поля в сообщение
        personMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        personMessage.addField(FieldDescriptor(name: "age", number: 2, type: .int32))
        personMessage.addField(FieldDescriptor(name: "email", number: 3, type: .string))
        
        print("  👤 Создано сообщение: \(personMessage.name)")
        print("  🏷  Поля: \(personMessage.fields.values.map { "\($0.name):\($0.type)" }.joined(separator: ", "))")
        print("  📍 Полное имя: \(personMessage.fullName)")
        
        // Регистрируем сообщение в файле
        fileDescriptor.addMessage(personMessage)
        print("  ✅ Сообщение зарегистрировано в файле \(fileDescriptor.name)")
    }
    
    private static func step3_createMessageInstance() throws {
        ExampleUtils.printStep(3, "Создание экземпляра динамического сообщения")
        
        // Воссоздаем структуру (в реальности это было бы вынесено в отдельный метод)
        let (messageDescriptor, _) = try createPersonMessageDescriptor()
        
        // Создаем фабрику сообщений
        let factory = MessageFactory()
        let person = factory.createMessage(from: messageDescriptor)
        
        print("  🏗  Создан экземпляр сообщения: \(person.descriptor.name)")
        print("  🔍 Количество полей: \(person.descriptor.fields.count)")
        print("  📋 Доступные поля: \(person.descriptor.fields.values.map { $0.name }.joined(separator: ", "))")
    }
    
    private static func step4_workWithData() throws {
        ExampleUtils.printStep(4, "Работа с данными сообщения")
        
        let (messageDescriptor, _) = try createPersonMessageDescriptor()
        let factory = MessageFactory()
        var person = factory.createMessage(from: messageDescriptor)
        
        // Заполняем данными
        try person.set("John Doe", forField: "name")
        try person.set(Int32(30), forField: "age")
        try person.set("john.doe@example.com", forField: "email")
        
        print("  ✏️  Данные установлены")
        
        // Читаем данные обратно
        let name: String? = try person.get(forField: "name") as? String
        let age: Int32? = try person.get(forField: "age") as? Int32
        let email: String? = try person.get(forField: "email") as? String
        
        ExampleUtils.printTable([
            "Имя": name ?? "не указано",
            "Возраст": age?.description ?? "не указан",
            "Email": email ?? "не указан"
        ], title: "Данные Person")
        
        // Проверим наличие полей
        for fieldName in ["name", "age", "email"] {
            let hasValue = try person.hasValue(forField: fieldName)
            print("  \(hasValue ? "✅" : "❌") Поле '\(fieldName)': \(hasValue ? "установлено" : "не установлено")")
        }
    }
    
    private static func step5_useTypeRegistry() throws {
        ExampleUtils.printStep(5, "Использование TypeRegistry для управления типами")
        
        let (_, fileDescriptor) = try createPersonMessageDescriptor()
        
        // Создаем реестр типов
        let typeRegistry = TypeRegistry()
        try typeRegistry.registerFile(fileDescriptor)
        
        print("  📂 Файл зарегистрирован в TypeRegistry")
        
        // Ищем зарегистрированный тип
        let foundMessage = typeRegistry.findMessage(named: "example.Person")
        
        if let found = foundMessage {
            print("  🔍 Найден тип: \(found.fullName)")
            print("  📊 Поля в найденном типе: \(found.fields.count)")
        } else {
            print("  ❌ Тип не найден")
        }
        
        // Создаем сообщение через registry
        let registryFactory = MessageFactory()
        if let foundDescriptor = foundMessage {
            var message = registryFactory.createMessage(from: foundDescriptor)
            try message.set("Registry User", forField: "name")
            
            let retrievedName: String? = try message.get(forField: "name") as? String
            print("  🎯 Сообщение через registry: имя = '\(retrievedName ?? "nil")'")
        }
    }
    
    // MARK: - Helper Methods
    
    private static func createPersonMessageDescriptor() throws -> (MessageDescriptor, FileDescriptor) {
        var fileDescriptor = FileDescriptor(name: "hello.proto", package: "example")
        var personMessage = MessageDescriptor(name: "Person", parent: fileDescriptor)
        
        personMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        personMessage.addField(FieldDescriptor(name: "age", number: 2, type: .int32))
        personMessage.addField(FieldDescriptor(name: "email", number: 3, type: .string))
        
        fileDescriptor.addMessage(personMessage)
        
        return (personMessage, fileDescriptor)
    }
}
