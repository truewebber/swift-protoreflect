/**
 * 🔧 SwiftProtoReflect Example: Advanced Field Manipulation
 * 
 * Описание: Продвинутые манипуляции полей динамических сообщений
 * Ключевые концепции: Field introspection, Batch operations, Conditional updates, Field validation
 * Сложность: 🔧🔧 Продвинутый
 * Время выполнения: < 15 секунд
 * 
 * Что изучите:
 * - Массовые операции с полями (batch updates, batch validation)
 * - Динамическое исследование структуры полей и их метаданных
 * - Условные обновления на основе типов и значений полей
 * - Продвинутая валидация и constraints для полей
 * - Трансформация и конвертация типов полей
 * - Работа с полями разных типов через единый API
 * 
 * Запуск: 
 *   swift run FieldManipulation
 *   make run-dynamic
 */

import Foundation
import SwiftProtoReflect
import ExampleUtils

@main
struct FieldManipulationExample {
    static func main() throws {
        ExampleUtils.printHeader("Продвинутые манипуляции полей динамических сообщений")
        
        try step1_fieldIntrospection()
        try step2_batchFieldOperations()
        try step3_conditionalUpdates()
        try step4_fieldValidationConstraints()
        try step5_fieldTransformations()
        try step6_advancedFieldPatterns()
        
        ExampleUtils.printSuccess("Вы освоили продвинутые техники работы с полями!")
        
        ExampleUtils.printNext([
            "Следующий: message-cloning.swift - клонирование и копирование сообщений",
            "Продвинутые: conditional-logic.swift - условная логика на основе типов",
            "Оптимизация: performance-optimization.swift - производительность операций"
        ])
    }
    
    private static func step1_fieldIntrospection() throws {
        ExampleUtils.printStep(1, "Динамическое исследование структуры полей")
        
        let fileDescriptor = try createComplexPersonStructure()
        let factory = MessageFactory()
        let personDescriptor = fileDescriptor.messages.values.first { $0.name == "Person" }!
        
        var person = factory.createMessage(from: personDescriptor)
        try populatePersonWithSampleData(&person)
        
        print("  🔍 Анализ структуры полей:")
        try analyzeFieldStructure(personDescriptor)
        
        print("\n  📊 Состояние полей в сообщении:")
        try analyzeFieldStates(person)
        
        print("\n  🏷  Метаданные полей:")
        try printFieldMetadata(personDescriptor)
    }
    
    private static func step2_batchFieldOperations() throws {
        ExampleUtils.printStep(2, "Массовые операции с полями")
        
        let fileDescriptor = try createComplexPersonStructure()
        let factory = MessageFactory()
        let personDescriptor = fileDescriptor.messages.values.first { $0.name == "Person" }!
        
        // Создание множественных сообщений для batch обработки
        var persons: [DynamicMessage] = []
        for i in 1...5 {
            var person = factory.createMessage(from: personDescriptor)
            try person.set("Person \(i)", forField: "name")
            try person.set(Int32(20 + i * 5), forField: "age")
            try person.set("person\(i)@example.com", forField: "email")
            persons.append(person)
        }
        
        print("  📦 Создано \(persons.count) сообщений для batch обработки")
        
        // Batch validation
        print("\n  ✅ Batch валидация:")
        let validationResults = try performBatchValidation(persons)
        ExampleUtils.printTable(validationResults, title: "Batch Validation Results")
        
        // Batch updates
        print("\n  🔄 Batch обновления:")
        try performBatchUpdates(&persons)
        
        // Batch field analysis
        print("\n  📈 Batch анализ полей:")
        let fieldStats = try analyzeBatchFieldStats(persons)
        ExampleUtils.printTable(fieldStats, title: "Field Statistics")
    }
    
    private static func step3_conditionalUpdates() throws {
        ExampleUtils.printStep(3, "Условные обновления на основе типов и значений")
        
        let fileDescriptor = try createMixedTypesStructure()
        let factory = MessageFactory()
        let recordDescriptor = fileDescriptor.messages.values.first { $0.name == "DataRecord" }!
        
        var record = factory.createMessage(from: recordDescriptor)
        try populateDataRecord(&record)
        
        print("  🎯 Начальное состояние записи:")
        record.prettyPrint()
        
        print("\n  🔄 Применение условных обновлений:")
        
        // Conditional updates based on field types
        try applyTypeBasedUpdates(&record, descriptor: recordDescriptor)
        
        // Conditional updates based on field values
        try applyValueBasedUpdates(&record)
        
        // Smart defaults for empty fields
        try applySmartDefaults(&record, descriptor: recordDescriptor)
        
        print("\n  ✨ Результат после условных обновлений:")
        record.prettyPrint()
    }
    
    private static func step4_fieldValidationConstraints() throws {
        ExampleUtils.printStep(4, "Валидация полей с constraints")
        
        let fileDescriptor = try createConstrainedStructure()
        let factory = MessageFactory()
        let userDescriptor = fileDescriptor.messages.values.first { $0.name == "ConstrainedUser" }!
        
        var user = factory.createMessage(from: userDescriptor)
        
        print("  📏 Тестирование constraints:")
        
        // Test various constraint scenarios
        let testCases = [
            ("Valid case", "john.doe@example.com", "ValidPassword123", Int32(25)),
            ("Invalid email", "invalid-email", "ValidPassword123", Int32(25)),
            ("Weak password", "john.doe@example.com", "weak", Int32(25)),
            ("Invalid age", "john.doe@example.com", "ValidPassword123", Int32(15))
        ]
        
        for (testName, email, password, age) in testCases {
            print("\n    🧪 \(testName):")
            
            // Reset user
            user = factory.createMessage(from: userDescriptor)
            try user.set(email, forField: "email")
            try user.set(password, forField: "password")
            try user.set(age, forField: "age")
            
            let constraintResults = try validateConstraints(user)
            for (field, result) in constraintResults {
                let status = result ? "✅" : "❌"
                print("      \(status) \(field)")
            }
        }
        
        print("\n  🔒 Применение автоматических исправлений:")
        try applyConstraintFixes(&user)
        print("    Пользователь после исправлений:")
        user.prettyPrint()
    }
    
    private static func step5_fieldTransformations() throws {
        ExampleUtils.printStep(5, "Трансформация и конвертация полей")
        
        let fileDescriptor = try createTransformableStructure()
        let factory = MessageFactory()
        let documentDescriptor = fileDescriptor.messages.values.first { $0.name == "Document" }!
        
        var document = factory.createMessage(from: documentDescriptor)
        try populateDocumentForTransformation(&document)
        
        print("  📄 Исходный документ:")
        document.prettyPrint()
        
        print("\n  🔄 Применение трансформаций:")
        
        // String transformations
        try applyStringTransformations(&document)
        print("    ✨ Трансформации строк применены")
        
        // Numeric transformations
        try applyNumericTransformations(&document)
        print("    ✨ Числовые трансформации применены")
        
        // Array transformations
        try applyArrayTransformations(&document)
        print("    ✨ Трансформации массивов применены")
        
        // Custom business logic transformations
        try applyBusinessLogicTransformations(&document)
        print("    ✨ Бизнес-логика применена")
        
        print("\n  📄 Документ после трансформаций:")
        document.prettyPrint()
        
        // Demonstrate rollback capability
        print("\n  ↩️  Демонстрация отката изменений:")
        try demonstrateRollback(document, factory: factory)
    }
    
    private static func step6_advancedFieldPatterns() throws {
        ExampleUtils.printStep(6, "Продвинутые паттерны работы с полями")
        
        let fileDescriptor = try createAdvancedPatternsStructure()
        let factory = MessageFactory()
        let configDescriptor = fileDescriptor.messages.values.first { $0.name == "Configuration" }!
        
        var config = factory.createMessage(from: configDescriptor)
        try populateConfiguration(&config)
        
        print("  🎛  Конфигурация для демонстрации паттернов:")
        config.prettyPrint()
        
        // Pattern 1: Field proxies and virtual fields
        print("\n  🔗 Паттерн 1: Виртуальные поля и прокси")
        try demonstrateFieldProxies(config)
        
        // Pattern 2: Field versioning and migration
        print("\n  📼 Паттерн 2: Версионирование и миграция полей")
        try demonstrateFieldMigration(&config, factory: factory)
        
        // Pattern 3: Dynamic field discovery and auto-configuration
        print("\n  🔍 Паттерн 3: Динамическое обнаружение полей")
        try demonstrateDynamicFieldDiscovery(config)
        
        // Pattern 4: Field interception and middleware
        print("\n  🔧 Паттерн 4: Перехват операций с полями")
        try demonstrateFieldInterception(&config)
        
        ExampleUtils.printInfo("Продвинутые паттерны позволяют создавать гибкие, расширяемые системы")
    }
    
    // MARK: - Structure Creation Methods
    
    private static func createComplexPersonStructure() throws -> FileDescriptor {
        var fileDescriptor = FileDescriptor(name: "complex_person.proto", package: "example")
        
        var personDesc = MessageDescriptor(name: "Person", parent: fileDescriptor)
        personDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        personDesc.addField(FieldDescriptor(name: "age", number: 2, type: .int32))
        personDesc.addField(FieldDescriptor(name: "email", number: 3, type: .string))
        personDesc.addField(FieldDescriptor(name: "phone", number: 4, type: .string))
        personDesc.addField(FieldDescriptor(name: "addresses", number: 5, type: .string, isRepeated: true))
        personDesc.addField(FieldDescriptor(name: "salary", number: 6, type: .double))
        personDesc.addField(FieldDescriptor(name: "active", number: 7, type: .bool))
        personDesc.addField(FieldDescriptor(name: "tags", number: 8, type: .string, isRepeated: true))
        
        fileDescriptor.addMessage(personDesc)
        return fileDescriptor
    }
    
    private static func createMixedTypesStructure() throws -> FileDescriptor {
        var fileDescriptor = FileDescriptor(name: "mixed_types.proto", package: "example")
        
        var recordDesc = MessageDescriptor(name: "DataRecord", parent: fileDescriptor)
        recordDesc.addField(FieldDescriptor(name: "id", number: 1, type: .string))
        recordDesc.addField(FieldDescriptor(name: "count", number: 2, type: .int32))
        recordDesc.addField(FieldDescriptor(name: "percentage", number: 3, type: .double))
        recordDesc.addField(FieldDescriptor(name: "enabled", number: 4, type: .bool))
        recordDesc.addField(FieldDescriptor(name: "values", number: 5, type: .int32, isRepeated: true))
        recordDesc.addField(FieldDescriptor(name: "metadata", number: 6, type: .string, isRepeated: true))
        
        fileDescriptor.addMessage(recordDesc)
        return fileDescriptor
    }
    
    private static func createConstrainedStructure() throws -> FileDescriptor {
        var fileDescriptor = FileDescriptor(name: "constrained.proto", package: "example")
        
        var userDesc = MessageDescriptor(name: "ConstrainedUser", parent: fileDescriptor)
        userDesc.addField(FieldDescriptor(name: "email", number: 1, type: .string))
        userDesc.addField(FieldDescriptor(name: "password", number: 2, type: .string))
        userDesc.addField(FieldDescriptor(name: "age", number: 3, type: .int32))
        userDesc.addField(FieldDescriptor(name: "username", number: 4, type: .string))
        
        fileDescriptor.addMessage(userDesc)
        return fileDescriptor
    }
    
    private static func createTransformableStructure() throws -> FileDescriptor {
        var fileDescriptor = FileDescriptor(name: "transformable.proto", package: "example")
        
        var documentDesc = MessageDescriptor(name: "Document", parent: fileDescriptor)
        documentDesc.addField(FieldDescriptor(name: "title", number: 1, type: .string))
        documentDesc.addField(FieldDescriptor(name: "content", number: 2, type: .string))
        documentDesc.addField(FieldDescriptor(name: "word_count", number: 3, type: .int32))
        documentDesc.addField(FieldDescriptor(name: "tags", number: 4, type: .string, isRepeated: true))
        documentDesc.addField(FieldDescriptor(name: "rating", number: 5, type: .double))
        documentDesc.addField(FieldDescriptor(name: "keywords", number: 6, type: .string, isRepeated: true))
        
        fileDescriptor.addMessage(documentDesc)
        return fileDescriptor
    }
    
    private static func createAdvancedPatternsStructure() throws -> FileDescriptor {
        var fileDescriptor = FileDescriptor(name: "advanced_patterns.proto", package: "example")
        
        var configDesc = MessageDescriptor(name: "Configuration", parent: fileDescriptor)
        configDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        configDesc.addField(FieldDescriptor(name: "version", number: 2, type: .string))
        configDesc.addField(FieldDescriptor(name: "parameters", number: 3, type: .string, isRepeated: true))
        configDesc.addField(FieldDescriptor(name: "enabled_features", number: 4, type: .string, isRepeated: true))
        configDesc.addField(FieldDescriptor(name: "timeout_seconds", number: 5, type: .int32))
        configDesc.addField(FieldDescriptor(name: "debug_mode", number: 6, type: .bool))
        
        fileDescriptor.addMessage(configDesc)
        return fileDescriptor
    }
    
    // MARK: - Helper Functions
    
    private static func populatePersonWithSampleData(_ person: inout DynamicMessage) throws {
        try person.set("John Doe", forField: "name")
        try person.set(Int32(30), forField: "age")
        try person.set("john.doe@example.com", forField: "email")
        try person.set("+1-555-0123", forField: "phone")
        try person.set(["123 Main St", "456 Oak Ave"], forField: "addresses")
        try person.set(75000.0, forField: "salary")
        try person.set(true, forField: "active")
        try person.set(["employee", "senior", "tech"], forField: "tags")
    }
    
    private static func analyzeFieldStructure(_ descriptor: MessageDescriptor) throws {
        let fields = descriptor.fields.values
        let scalarFields = fields.filter { !$0.isRepeated && $0.type != .message }
        let repeatedFields = fields.filter { $0.isRepeated }
        let messageFields = fields.filter { $0.type == .message }
        
        ExampleUtils.printTable([
            "Total fields": "\(fields.count)",
            "Scalar fields": "\(scalarFields.count)",
            "Repeated fields": "\(repeatedFields.count)",
            "Message fields": "\(messageFields.count)"
        ], title: "Field Structure Analysis")
    }
    
    private static func analyzeFieldStates(_ message: DynamicMessage) throws {
        var fieldStates: [String: String] = [:]
        
        for field in message.descriptor.fields.values {
            let hasValue = try message.hasValue(forField: field.name)
            if hasValue {
                let value = try message.get(forField: field.name)
                let actualType = getActualFieldType(value: value, field: field)
                fieldStates[field.name] = "Set (\(actualType))"
            } else {
                fieldStates[field.name] = "Not set (\(field.type))"
            }
        }
        
        ExampleUtils.printTable(fieldStates, title: "Field States")
    }
    
    private static func getActualFieldType(value: Any?, field: FieldDescriptor) -> String {
        guard let value = value else {
            return "nil"
        }
        
        // Попытаемся определить реальный тип на основе типа поля
        switch field.type {
        case .string:
            if field.isRepeated {
                if value is [String] {
                    return "Array<String>"
                }
            } else {
                if value is String {
                    return "String"
                }
            }
        case .int32:
            if field.isRepeated {
                if value is [Int32] {
                    return "Array<Int32>"
                }
            } else {
                if value is Int32 {
                    return "Int32"
                }
            }
        case .int64:
            if field.isRepeated {
                if value is [Int64] {
                    return "Array<Int64>"
                }
            } else {
                if value is Int64 {
                    return "Int64"
                }
            }
        case .double:
            if field.isRepeated {
                if value is [Double] {
                    return "Array<Double>"
                }
            } else {
                if value is Double {
                    return "Double"
                }
            }
        case .float:
            if field.isRepeated {
                if value is [Float] {
                    return "Array<Float>"
                }
            } else {
                if value is Float {
                    return "Float"
                }
            }
        case .bool:
            if field.isRepeated {
                if value is [Bool] {
                    return "Array<Bool>"
                }
            } else {
                if value is Bool {
                    return "Bool"
                }
            }
        case .bytes:
            if field.isRepeated {
                if value is [Data] {
                    return "Array<Data>"
                }
            } else {
                if value is Data {
                    return "Data"
                }
            }
        case .message:
            if field.isRepeated {
                if let array = value as? [Any], !array.isEmpty {
                    return "Array<DynamicMessage>"
                }
            } else {
                if value is DynamicMessage {
                    return "DynamicMessage"
                }
            }
        default:
            break
        }
        
        // Fallback to actual type if we can't determine from field type
        return String(describing: type(of: value))
    }
    
    private static func printFieldMetadata(_ descriptor: MessageDescriptor) throws {
        for field in descriptor.fields.values.sorted(by: { $0.number < $1.number }) {
            print("    📋 Field \(field.number): \(field.name)")
            print("       Type: \(field.type)")
            print("       Repeated: \(field.isRepeated)")
            if let typeName = field.typeName {
                print("       TypeName: \(typeName)")
            }
        }
    }
    
    private static func performBatchValidation(_ messages: [DynamicMessage]) throws -> [String: String] {
        var results: [String: String] = [:]
        
        var totalFields = 0
        var populatedFields = 0
        var validEmails = 0
        var adultUsers = 0
        
        for message in messages {
            for field in message.descriptor.fields.values {
                totalFields += 1
                
                if try message.hasValue(forField: field.name) {
                    populatedFields += 1
                    
                    // Specific validations
                    if field.name == "email" {
                        if let email = try message.get(forField: field.name) as? String,
                           email.contains("@") && email.contains(".") {
                            validEmails += 1
                        }
                    }
                    
                    if field.name == "age" {
                        if let age = try message.get(forField: field.name) as? Int32,
                           age >= 18 {
                            adultUsers += 1
                        }
                    }
                }
            }
        }
        
        results["Total Fields"] = "\(totalFields)"
        results["Populated Fields"] = "\(populatedFields) (\(populatedFields * 100 / totalFields)%)"
        results["Valid Emails"] = "\(validEmails)/\(messages.count)"
        results["Adult Users"] = "\(adultUsers)/\(messages.count)"
        
        return results
    }
    
    private static func performBatchUpdates(_ messages: inout [DynamicMessage]) throws {
        let timestamp = Date().timeIntervalSince1970
        
        for i in 0..<messages.count {
            // Add timestamp field simulation
            if let name = try messages[i].get(forField: "name") as? String {
                try messages[i].set("\(name) (updated)", forField: "name")
            }
            
            // Increment age by 1
            if let age = try messages[i].get(forField: "age") as? Int32 {
                try messages[i].set(age + 1, forField: "age")
            }
        }
        
        print("    ✅ Updated \(messages.count) messages")
        print("    📅 Simulated timestamp: \(Int(timestamp))")
    }
    
    private static func analyzeBatchFieldStats(_ messages: [DynamicMessage]) throws -> [String: String] {
        var stats: [String: String] = [:]
        
        // Calculate age statistics
        let ages = try messages.compactMap { message in
            try message.get(forField: "age") as? Int32
        }
        
        if !ages.isEmpty {
            let avgAge = ages.reduce(0, +) / Int32(ages.count)
            let minAge = ages.min()!
            let maxAge = ages.max()!
            
            stats["Average Age"] = "\(avgAge)"
            stats["Age Range"] = "\(minAge) - \(maxAge)"
        }
        
        // Email domain analysis
        let emails = try messages.compactMap { message in
            try message.get(forField: "email") as? String
        }
        
        let domains = emails.compactMap { email in
            email.components(separatedBy: "@").last
        }
        
        let uniqueDomains = Set(domains)
        stats["Unique Email Domains"] = "\(uniqueDomains.count)"
        stats["Most Common Domain"] = domains.mostFrequent() ?? "N/A"
        
        return stats
    }
    
    private static func populateDataRecord(_ record: inout DynamicMessage) throws {
        try record.set("REC-001", forField: "id")
        try record.set(Int32(42), forField: "count")
        try record.set(85.5, forField: "percentage")
        try record.set(true, forField: "enabled")
        try record.set([1, 2, 3, 4, 5], forField: "values")
        try record.set(["key1", "key2"], forField: "metadata")
    }
    
    private static func applyTypeBasedUpdates(_ record: inout DynamicMessage, descriptor: MessageDescriptor) throws {
        for field in descriptor.fields.values {
            switch field.type {
            case .string:
                if try record.hasValue(forField: field.name) {
                    if let currentValue = try record.get(forField: field.name) as? String {
                        try record.set(currentValue.uppercased(), forField: field.name)
                        print("      📝 String field '\(field.name)' -> uppercase")
                    }
                }
            case .int32:
                if try record.hasValue(forField: field.name) {
                    if let currentValue = try record.get(forField: field.name) as? Int32 {
                        try record.set(currentValue * 2, forField: field.name)
                        print("      🔢 Int32 field '\(field.name)' -> doubled")
                    }
                }
            case .double:
                if try record.hasValue(forField: field.name) {
                    if let currentValue = try record.get(forField: field.name) as? Double {
                        try record.set(round(currentValue), forField: field.name)
                        print("      📊 Double field '\(field.name)' -> rounded")
                    }
                }
            default:
                break
            }
        }
    }
    
    private static func applyValueBasedUpdates(_ record: inout DynamicMessage) throws {
        // Update based on percentage value
        if let percentage = try record.get(forField: "percentage") as? Double {
            if percentage > 80 {
                try record.set("HIGH", forField: "id")
                print("      🔥 High percentage detected -> ID updated to HIGH")
            }
        }
        
        // Update array based on size
        if let values = try record.get(forField: "values") as? [Int32] {
            if values.count > 3 {
                let trimmed = Array(values.prefix(3))
                try record.set(trimmed, forField: "values")
                print("      ✂️  Large array trimmed to 3 elements")
            }
        }
    }
    
    private static func applySmartDefaults(_ record: inout DynamicMessage, descriptor: MessageDescriptor) throws {
        for field in descriptor.fields.values {
            if !(try record.hasValue(forField: field.name)) {
                switch field.type {
                case .string:
                    try record.set("DEFAULT_\(field.name.uppercased())", forField: field.name)
                    print("      🎯 Default string set for '\(field.name)'")
                case .int32:
                    try record.set(Int32(0), forField: field.name)
                    print("      🎯 Default int32 set for '\(field.name)'")
                case .bool:
                    try record.set(false, forField: field.name)
                    print("      🎯 Default bool set for '\(field.name)'")
                default:
                    break
                }
            }
        }
    }
    
    private static func validateConstraints(_ user: DynamicMessage) throws -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        // Email validation
        if let email = try user.get(forField: "email") as? String {
            let emailValid = email.contains("@") && email.contains(".") && email.count >= 5
            results["email"] = emailValid
        }
        
        // Password validation
        if let password = try user.get(forField: "password") as? String {
            let passwordValid = password.count >= 8 && 
                               password.contains(where: { $0.isUppercase }) &&
                               password.contains(where: { $0.isNumber })
            results["password"] = passwordValid
        }
        
        // Age validation
        if let age = try user.get(forField: "age") as? Int32 {
            let ageValid = age >= 18 && age <= 120
            results["age"] = ageValid
        }
        
        return results
    }
    
    private static func applyConstraintFixes(_ user: inout DynamicMessage) throws {
        // Fix email if invalid
        if let email = try user.get(forField: "email") as? String {
            if !email.contains("@") {
                try user.set("\(email)@example.com", forField: "email")
                print("      🔧 Email auto-corrected")
            }
        }
        
        // Fix age if out of range
        if let age = try user.get(forField: "age") as? Int32 {
            if age < 18 {
                try user.set(Int32(18), forField: "age")
                print("      🔧 Age corrected to minimum (18)")
            } else if age > 120 {
                try user.set(Int32(120), forField: "age")
                print("      🔧 Age corrected to maximum (120)")
            }
        }
        
        // Set username if not present
        if !(try user.hasValue(forField: "username")) {
            if let email = try user.get(forField: "email") as? String {
                let username = email.components(separatedBy: "@").first ?? "user"
                try user.set(username, forField: "username")
                print("      🔧 Username auto-generated from email")
            }
        }
    }
    
    private static func populateDocumentForTransformation(_ document: inout DynamicMessage) throws {
        try document.set("  SAMPLE DOCUMENT TITLE  ", forField: "title")
        try document.set("This is a sample document content with multiple words.", forField: "content")
        try document.set(Int32(0), forField: "word_count") // Will be calculated
        try document.set(["  tag1  ", "TAG2", "tag3  "], forField: "tags")
        try document.set(3.7, forField: "rating")
        try document.set([], forField: "keywords") // Will be extracted
    }
    
    private static func applyStringTransformations(_ document: inout DynamicMessage) throws {
        // Trim and normalize title
        if let title = try document.get(forField: "title") as? String {
            let normalizedTitle = title.trimmingCharacters(in: .whitespaces)
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
                .capitalized
            try document.set(normalizedTitle, forField: "title")
        }
        
        // Extract keywords from content
        if let content = try document.get(forField: "content") as? String {
            let separators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
            let words = content.components(separatedBy: separators)
                .filter { $0.count > 4 }
                .prefix(3)
            try document.set(Array(words), forField: "keywords")
        }
        
        // Normalize tags
        if let tags = try document.get(forField: "tags") as? [String] {
            let normalizedTags = tags.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                .filter { !$0.isEmpty }
            try document.set(normalizedTags, forField: "tags")
        }
    }
    
    private static func applyNumericTransformations(_ document: inout DynamicMessage) throws {
        // Calculate word count
        if let content = try document.get(forField: "content") as? String {
            let separators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
            let wordCount = content.components(separatedBy: separators)
                .filter { !$0.isEmpty }
                .count
            try document.set(Int32(wordCount), forField: "word_count")
        }
        
        // Round rating
        if let rating = try document.get(forField: "rating") as? Double {
            let roundedRating = round(rating * 2) / 2 // Round to nearest 0.5
            try document.set(roundedRating, forField: "rating")
        }
    }
    
    private static func applyArrayTransformations(_ document: inout DynamicMessage) throws {
        // Deduplicate and sort tags
        if let tags = try document.get(forField: "tags") as? [String] {
            let uniqueSortedTags = Array(Set(tags)).sorted()
            try document.set(uniqueSortedTags, forField: "tags")
        }
        
        // Limit keywords to top 3
        if let keywords = try document.get(forField: "keywords") as? [String] {
            let limitedKeywords = Array(keywords.prefix(3))
            try document.set(limitedKeywords, forField: "keywords")
        }
    }
    
    private static func applyBusinessLogicTransformations(_ document: inout DynamicMessage) throws {
        // Auto-tag based on content
        if let content = try document.get(forField: "content") as? String {
            var autoTags: [String] = []
            
            if content.lowercased().contains("sample") {
                autoTags.append("sample")
            }
            if content.lowercased().contains("document") {
                autoTags.append("document")
            }
            
            if !autoTags.isEmpty {
                if let existingTags = try document.get(forField: "tags") as? [String] {
                    let allTags = Array(Set(existingTags + autoTags))
                    try document.set(allTags, forField: "tags")
                }
            }
        }
        
        // Quality scoring based on word count and rating
        if let wordCount = try document.get(forField: "word_count") as? Int32,
           let rating = try document.get(forField: "rating") as? Double {
            
            var qualityScore = rating
            if wordCount > 10 { qualityScore += 0.5 }
            if wordCount > 20 { qualityScore += 0.5 }
            
            try document.set(min(qualityScore, 5.0), forField: "rating")
        }
    }
    
    private static func demonstrateRollback(_ document: DynamicMessage, factory: MessageFactory) throws {
        // Create a backup copy
        var backup = factory.createMessage(from: document.descriptor)
        
        // Copy all fields
        for field in document.descriptor.fields.values {
            if try document.hasValue(forField: field.name) {
                let value = try document.get(forField: field.name)
                try backup.set(value as Any, forField: field.name)
            }
        }
        
        print("    💾 Backup created successfully")
        print("    ↩️  Rollback capability demonstrated (backup has identical content)")
    }
    
    private static func populateConfiguration(_ config: inout DynamicMessage) throws {
        try config.set("Production Config", forField: "name")
        try config.set("v2.1.0", forField: "version")
        try config.set(["param1=value1", "param2=value2"], forField: "parameters")
        try config.set(["feature_a", "feature_b"], forField: "enabled_features")
        try config.set(Int32(30), forField: "timeout_seconds")
        try config.set(false, forField: "debug_mode")
    }
    
    private static func demonstrateFieldProxies(_ config: DynamicMessage) throws {
        // Simulate virtual field calculation
        if let timeoutSeconds = try config.get(forField: "timeout_seconds") as? Int32 {
            let timeoutMinutes = Double(timeoutSeconds) / 60.0
            print("      🔗 Virtual field 'timeout_minutes': \(timeoutMinutes)")
        }
        
        // Simulate computed field from multiple sources
        if let features = try config.get(forField: "enabled_features") as? [String],
           let debugMode = try config.get(forField: "debug_mode") as? Bool {
            let totalCapabilities = features.count + (debugMode ? 1 : 0)
            print("      🔗 Virtual field 'total_capabilities': \(totalCapabilities)")
        }
    }
    
    private static func demonstrateFieldMigration(_ config: inout DynamicMessage, factory: MessageFactory) throws {
        // Simulate migration from v1 to v2 format
        print("      📼 Migrating from version 1.x to 2.x format...")
        
        // Old format had 'timeout' instead of 'timeout_seconds'
        // Simulate this migration
        if let version = try config.get(forField: "version") as? String {
            if version.hasPrefix("v1") {
                try config.set("v2.1.0", forField: "version")
                print("         ✅ Version updated to v2.1.0")
            }
        }
        
        // Add new fields that didn't exist in v1
        if let parameters = try config.get(forField: "parameters") as? [String] {
            let migratedParams = parameters + ["migration_date=\(Date())"]
            try config.set(migratedParams, forField: "parameters")
            print("         ✅ Migration metadata added")
        }
    }
    
    private static func demonstrateDynamicFieldDiscovery(_ config: DynamicMessage) throws {
        print("      🔍 Discovering field capabilities dynamically...")
        
        var capabilities: [String] = []
        
        for field in config.descriptor.fields.values {
            if try config.hasValue(forField: field.name) {
                switch field.type {
                case .string where field.isRepeated:
                    capabilities.append("string_arrays")
                case .string where !field.isRepeated:
                    capabilities.append("strings")
                case .int32:
                    capabilities.append("integers")
                case .bool:
                    capabilities.append("booleans")
                default:
                    capabilities.append("other")
                }
            }
        }
        
        let uniqueCapabilities = Array(Set(capabilities))
        print("         📊 Discovered capabilities: \(uniqueCapabilities.joined(separator: ", "))")
    }
    
    private static func demonstrateFieldInterception(_ config: inout DynamicMessage) throws {
        print("      🔧 Applying field interception middleware...")
        
        // Simulate logging middleware
        for field in config.descriptor.fields.values {
            if try config.hasValue(forField: field.name) {
                let value = try config.get(forField: field.name)
                let actualType = getActualFieldType(value: value, field: field)
                print("         📝 Field access logged: \(field.name) = \(actualType)")
            }
        }
        
        // Simulate validation middleware
        if let debugMode = try config.get(forField: "debug_mode") as? Bool {
            if debugMode {
                print("         ⚠️  Debug mode detected - applying development settings")
                // In real implementation, would apply debug-specific transformations
            }
        }
        
        // Simulate caching middleware
        print("         💾 Field access patterns cached for optimization")
    }
}

// MARK: - Array Extensions

extension Array where Element == String {
    func mostFrequent() -> String? {
        let counts = self.reduce(into: [:]) { counts, word in
            counts[word, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
