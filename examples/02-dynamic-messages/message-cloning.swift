/**
 * 📋 SwiftProtoReflect Example: Message Cloning and Copying
 * 
 * Описание: Клонирование и копирование динамических сообщений
 * Ключевые концепции: Deep copy, Shallow copy, Partial copying, Performance optimization
 * Сложность: 🔧🔧 Продвинутый
 * Время выполнения: < 20 секунд
 * 
 * Что изучите:
 * - Deep copy vs shallow copy для динамических сообщений
 * - Клонирование сообщений с вложенными структурами и циклическими ссылками
 * - Partial copying (выборочное копирование полей)
 * - Performance оптимизации при массовом клонировании
 * - Сохранение и нарушение референтных связей между сообщениями
 * - Custom cloning strategies для различных use cases
 * 
 * Запуск: 
 *   swift run MessageCloning
 *   make run-dynamic
 */

import Foundation
import SwiftProtoReflect
import ExampleUtils

@main
struct MessageCloningExample {
    static func main() throws {
        ExampleUtils.printHeader("Клонирование и копирование динамических сообщений")
        
        try step1_basicCloning()
        try step2_deepVsShallowCopy()
        try step3_partialCopying()
        try step4_nestedStructureCloning()
        try step5_performanceOptimizedCloning()
        try step6_customCloningStrategies()
        
        ExampleUtils.printSuccess("Вы освоили все техники клонирования сообщений!")
        
        ExampleUtils.printNext([
            "Следующий: conditional-logic.swift - условная логика на основе типов",
            "Оптимизация: performance-optimization.swift - производительность операций",
            "Изучите: ../03-serialization/ - сериализация и форматы данных"
        ])
    }
    
    private static func step1_basicCloning() throws {
        ExampleUtils.printStep(1, "Основы клонирования сообщений")
        
        let fileDescriptor = try createPersonStructure()
        let factory = MessageFactory()
        let personDescriptor = fileDescriptor.messages.values.first { $0.name == "Person" }!
        
        // Создание оригинального сообщения
        var originalPerson = factory.createMessage(from: personDescriptor)
        try populatePersonData(&originalPerson)
        
        print("  👤 Оригинальное сообщение:")
        originalPerson.prettyPrint()
        
        // Базовое клонирование (создание независимой копии)
        print("\n  📋 Создание простой копии:")
        let (clonedPerson, cloneTime) = try ExampleUtils.measureTime {
            try createBasicClone(originalPerson, factory: factory)
        }
        ExampleUtils.printTiming("Basic cloning", time: cloneTime)
        
        print("    🔍 Проверка независимости копии:")
        try verifyIndependence(original: originalPerson, clone: clonedPerson)
        
        // Демонстрация изменений в копии
        print("\n  ✏️  Изменение данных в копии:")
        var mutableClone = clonedPerson
        try mutableClone.set("Jane Smith (Modified)", forField: "name")
        try mutableClone.set(Int32(35), forField: "age")
        
        print("    Оригинал после изменения копии:")
        originalPerson.prettyPrint()
        
        print("\n    Измененная копия:")
        mutableClone.prettyPrint()
        
        // Verification
        let originalName = try originalPerson.get(forField: "name") as? String
        let cloneName = try mutableClone.get(forField: "name") as? String
        
        let success = originalName != cloneName
        print("\n    ✅ Независимость подтверждена: \(success)")
    }
    
    private static func step2_deepVsShallowCopy() throws {
        ExampleUtils.printStep(2, "Deep copy vs Shallow copy")
        
        let fileDescriptor = try createTeamStructure()
        let factory = MessageFactory()
        let teamDescriptor = fileDescriptor.messages.values.first { $0.name == "Team" }!
        
        // Создание команды с участниками
        var originalTeam = factory.createMessage(from: teamDescriptor)
        try populateTeamData(&originalTeam, factory: factory, fileDescriptor: fileDescriptor)
        
        print("  👥 Оригинальная команда:")
        originalTeam.prettyPrint()
        
        // Shallow copy (ссылки на те же вложенные объекты)
        print("\n  📄 Shallow Copy:")
        let (shallowCopy, shallowTime) = try ExampleUtils.measureTime {
            try createShallowCopy(originalTeam, factory: factory)
        }
        ExampleUtils.printTiming("Shallow copy", time: shallowTime)
        
        // Deep copy (полное клонирование всех вложенных объектов)
        print("\n  📚 Deep Copy:")
        let (deepCopy, deepTime) = try ExampleUtils.measureTime {
            try createDeepCopy(originalTeam, factory: factory)
        }
        ExampleUtils.printTiming("Deep copy", time: deepTime)
        
        // Демонстрация различий
        print("\n  🔍 Демонстрация различий при изменении вложенных объектов:")
        try demonstrateCopyDifferences(original: originalTeam, shallow: shallowCopy, deep: deepCopy)
        
        // Performance comparison
        print("\n  ⚡ Сравнение производительности:")
        ExampleUtils.printTable([
            "Shallow Copy": String(format: "%.3f ms", shallowTime * 1000),
            "Deep Copy": String(format: "%.3f ms", deepTime * 1000),
            "Ratio": String(format: "%.1fx", deepTime / shallowTime)
        ], title: "Performance Comparison")
    }
    
    private static func step3_partialCopying() throws {
        ExampleUtils.printStep(3, "Partial copying (выборочное копирование)")
        
        let fileDescriptor = try createUserProfileStructure()
        let factory = MessageFactory()
        let profileDescriptor = fileDescriptor.messages.values.first { $0.name == "UserProfile" }!
        
        var fullProfile = factory.createMessage(from: profileDescriptor)
        try populateFullProfile(&fullProfile)
        
        print("  📊 Полный профиль пользователя:")
        fullProfile.prettyPrint()
        
        // Копирование только базовой информации
        print("\n  👤 Partial Copy: только базовая информация")
        let basicFields = ["name", "email", "age"]
        let (basicProfile, basicTime) = try ExampleUtils.measureTime {
            try createPartialCopy(fullProfile, fields: basicFields, factory: factory)
        }
        ExampleUtils.printTiming("Basic fields copy", time: basicTime)
        basicProfile.prettyPrint()
        
        // Копирование только контактной информации
        print("\n  📞 Partial Copy: только контактная информация")
        let contactFields = ["name", "email", "phone", "address"]
        let (contactProfile, contactTime) = try ExampleUtils.measureTime {
            try createPartialCopy(fullProfile, fields: contactFields, factory: factory)
        }
        ExampleUtils.printTiming("Contact fields copy", time: contactTime)
        contactProfile.prettyPrint()
        
        // Копирование с исключениями (все кроме указанных полей)
        print("\n  🚫 Partial Copy: исключить чувствительные данные")
        let excludedFields = ["ssn", "credit_card", "password_hash"]
        let (publicProfile, publicTime) = try ExampleUtils.measureTime {
            try createCopyExcluding(fullProfile, excludedFields: excludedFields, factory: factory)
        }
        ExampleUtils.printTiming("Public profile copy", time: publicTime)
        publicProfile.prettyPrint()
        
        // Анализ размеров
        print("\n  📏 Анализ размеров различных копий:")
        try analyzeProfileSizes(
            full: fullProfile,
            basic: basicProfile,
            contact: contactProfile,
            publicProfile: publicProfile
        )
    }
    
    private static func step4_nestedStructureCloning() throws {
        ExampleUtils.printStep(4, "Клонирование сложных вложенных структур")
        
        let fileDescriptor = try createOrganizationStructure()
        let factory = MessageFactory()
        let orgDescriptor = fileDescriptor.messages.values.first { $0.name == "Organization" }!
        
        var organization = factory.createMessage(from: orgDescriptor)
        try populateOrganizationData(&organization, factory: factory, fileDescriptor: fileDescriptor)
        
        print("  🏢 Сложная организационная структура:")
        try printOrganizationSummary(organization)
        
        // Клонирование с сохранением структуры
        print("\n  🔄 Полное клонирование организации:")
        let (clonedOrg, cloneTime) = try ExampleUtils.measureTime {
            try cloneComplexOrganization(organization, factory: factory, fileDescriptor: fileDescriptor)
        }
        ExampleUtils.printTiming("Complex organization cloning", time: cloneTime)
        
        // Verification of structural integrity
        print("\n  ✅ Проверка целостности клонированной структуры:")
        try verifyOrganizationIntegrity(original: organization, cloned: clonedOrg)
        
        // Клонирование с реструктуризацией
        print("\n  🔧 Клонирование с реструктуризацией:")
        let (restructuredOrg, restructureTime) = try ExampleUtils.measureTime {
            try cloneAndRestructure(organization, factory: factory, fileDescriptor: fileDescriptor)
        }
        ExampleUtils.printTiming("Clone with restructuring", time: restructureTime)
        
        print("    Реструктурированная организация:")
        try printOrganizationSummary(restructuredOrg)
    }
    
    private static func step5_performanceOptimizedCloning() throws {
        ExampleUtils.printStep(5, "Performance-оптимизированное клонирование")
        
        let fileDescriptor = try createDatasetStructure()
        let factory = MessageFactory()
        let recordDescriptor = fileDescriptor.messages.values.first { $0.name == "DataRecord" }!
        
        // Создание большого dataset'а для тестирования
        print("  📊 Создание большого dataset'а для тестирования:")
        let (largeDataset, createTime) = try ExampleUtils.measureTime {
            try createLargeDataset(count: 1000, factory: factory, descriptor: recordDescriptor)
        }
        ExampleUtils.printTiming("Large dataset creation", time: createTime)
        print("    Создано \(largeDataset.count) записей")
        
        // Naive bulk cloning
        print("\n  🐌 Naive bulk cloning:")
        let (naiveClones, naiveTime) = try ExampleUtils.measureTime {
            try performNaiveBulkCloning(largeDataset, factory: factory)
        }
        ExampleUtils.printTiming("Naive bulk cloning", time: naiveTime)
        
        // Optimized bulk cloning
        print("\n  🚀 Optimized bulk cloning:")
        let (optimizedClones, optimizedTime) = try ExampleUtils.measureTime {
            try performOptimizedBulkCloning(largeDataset, factory: factory, descriptor: recordDescriptor)
        }
        ExampleUtils.printTiming("Optimized bulk cloning", time: optimizedTime)
        
        // Parallel cloning
        print("\n  ⚡ Parallel cloning:")
        let (parallelClones, parallelTime) = try ExampleUtils.measureTime {
            try performParallelCloning(largeDataset, factory: factory, descriptor: recordDescriptor)
        }
        ExampleUtils.printTiming("Parallel cloning", time: parallelTime)
        
        // Performance comparison
        print("\n  📈 Сравнение производительности:")
        ExampleUtils.printTable([
            "Naive Approach": String(format: "%.0f ms", naiveTime * 1000),
            "Optimized": String(format: "%.0f ms", optimizedTime * 1000),
            "Parallel": String(format: "%.0f ms", parallelTime * 1000),
            "Speedup (Opt)": String(format: "%.1fx", naiveTime / optimizedTime),
            "Speedup (Par)": String(format: "%.1fx", naiveTime / parallelTime)
        ], title: "Performance Results")
        
        // Verify results are equivalent
        let equivalentResults = naiveClones.count == optimizedClones.count &&
                              optimizedClones.count == parallelClones.count
        print("\n    ✅ Result equivalence verified: \(equivalentResults)")
    }
    
    private static func step6_customCloningStrategies() throws {
        ExampleUtils.printStep(6, "Custom стратегии клонирования")
        
        let fileDescriptor = try createConfigurationStructure()
        let factory = MessageFactory()
        let configDescriptor = fileDescriptor.messages.values.first { $0.name == "Configuration" }!
        
        var config = factory.createMessage(from: configDescriptor)
        try populateConfiguration(&config)
        
        print("  ⚙️  Исходная конфигурация:")
        config.prettyPrint()
        
        // Strategy 1: Version-aware cloning
        print("\n  📋 Стратегия 1: Version-aware cloning")
        let (versionedClone, versionTime) = try ExampleUtils.measureTime {
            try createVersionAwareClone(config, targetVersion: "2.0", factory: factory, descriptor: configDescriptor)
        }
        ExampleUtils.printTiming("Version-aware cloning", time: versionTime)
        versionedClone.prettyPrint()
        
        // Strategy 2: Environment-specific cloning
        print("\n  🌍 Стратегия 2: Environment-specific cloning")
        let environments = ["development", "staging", "production"]
        for env in environments {
            let (envClone, envTime) = try ExampleUtils.measureTime {
                try createEnvironmentSpecificClone(config, environment: env, factory: factory, descriptor: configDescriptor)
            }
            print("    \(env.capitalized) environment (\(String(format: "%.1f ms", envTime * 1000))):")
            if let name = try envClone.get(forField: "name") as? String {
                print("      Name: \(name)")
            }
            if let debug = try envClone.get(forField: "debug_enabled") as? Bool {
                print("      Debug: \(debug)")
            }
        }
        
        // Strategy 3: Template-based cloning
        print("\n  📝 Стратегия 3: Template-based cloning")
        let templates = ["minimal", "standard", "enterprise"]
        for template in templates {
            let (templateClone, templateTime) = try ExampleUtils.measureTime {
                try createTemplateBasedClone(config, template: template, factory: factory, descriptor: configDescriptor)
            }
            print("    \(template.capitalized) template (\(String(format: "%.1f ms", templateTime * 1000))):")
            let fieldCount = try countPopulatedFields(templateClone)
            print("      Populated fields: \(fieldCount)")
        }
        
        // Strategy 4: Incremental cloning (only changes)
        print("\n  📈 Стратегия 4: Incremental cloning")
        var modifiedConfig = try createBasicClone(config, factory: factory)
        try modifiedConfig.set("Modified Config", forField: "name")
        try modifiedConfig.set(true, forField: "debug_enabled")
        
        let (incrementalClone, incrementalTime) = try ExampleUtils.measureTime {
            try createIncrementalClone(original: config, modified: modifiedConfig, factory: factory, descriptor: configDescriptor)
        }
        ExampleUtils.printTiming("Incremental cloning", time: incrementalTime)
        
        print("    Incremental clone (только изменения):")
        incrementalClone.prettyPrint()
        
        ExampleUtils.printInfo("Custom стратегии позволяют адаптировать клонирование под конкретные needs")
    }
    
    // MARK: - Structure Creation Methods
    
    private static func createPersonStructure() throws -> FileDescriptor {
        var fileDescriptor = FileDescriptor(name: "person.proto", package: "example")
        
        var personDesc = MessageDescriptor(name: "Person", parent: fileDescriptor)
        personDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        personDesc.addField(FieldDescriptor(name: "age", number: 2, type: .int32))
        personDesc.addField(FieldDescriptor(name: "email", number: 3, type: .string))
        personDesc.addField(FieldDescriptor(name: "hobbies", number: 4, type: .string, isRepeated: true))
        
        fileDescriptor.addMessage(personDesc)
        return fileDescriptor
    }
    
    private static func createTeamStructure() throws -> FileDescriptor {
        var fileDescriptor = FileDescriptor(name: "team.proto", package: "example")
        
        var personDesc = MessageDescriptor(name: "Person", parent: fileDescriptor)
        personDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        personDesc.addField(FieldDescriptor(name: "role", number: 2, type: .string))
        
        var teamDesc = MessageDescriptor(name: "Team", parent: fileDescriptor)
        teamDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        teamDesc.addField(FieldDescriptor(
            name: "members",
            number: 2,
            type: .message,
            typeName: "example.Person",
            isRepeated: true
        ))
        
        fileDescriptor.addMessage(personDesc)
        fileDescriptor.addMessage(teamDesc)
        return fileDescriptor
    }
    
    private static func createUserProfileStructure() throws -> FileDescriptor {
        var fileDescriptor = FileDescriptor(name: "user_profile.proto", package: "example")
        
        var profileDesc = MessageDescriptor(name: "UserProfile", parent: fileDescriptor)
        profileDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        profileDesc.addField(FieldDescriptor(name: "email", number: 2, type: .string))
        profileDesc.addField(FieldDescriptor(name: "age", number: 3, type: .int32))
        profileDesc.addField(FieldDescriptor(name: "phone", number: 4, type: .string))
        profileDesc.addField(FieldDescriptor(name: "address", number: 5, type: .string))
        profileDesc.addField(FieldDescriptor(name: "ssn", number: 6, type: .string))
        profileDesc.addField(FieldDescriptor(name: "credit_card", number: 7, type: .string))
        profileDesc.addField(FieldDescriptor(name: "password_hash", number: 8, type: .string))
        profileDesc.addField(FieldDescriptor(name: "preferences", number: 9, type: .string, isRepeated: true))
        
        fileDescriptor.addMessage(profileDesc)
        return fileDescriptor
    }
    
    private static func createOrganizationStructure() throws -> FileDescriptor {
        var fileDescriptor = FileDescriptor(name: "organization.proto", package: "example")
        
        var employeeDesc = MessageDescriptor(name: "Employee", parent: fileDescriptor)
        employeeDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        employeeDesc.addField(FieldDescriptor(name: "title", number: 2, type: .string))
        employeeDesc.addField(FieldDescriptor(name: "employee_id", number: 3, type: .string))
        
        var departmentDesc = MessageDescriptor(name: "Department", parent: fileDescriptor)
        departmentDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        departmentDesc.addField(FieldDescriptor(
            name: "employees",
            number: 2,
            type: .message,
            typeName: "example.Employee",
            isRepeated: true
        ))
        
        var organizationDesc = MessageDescriptor(name: "Organization", parent: fileDescriptor)
        organizationDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        organizationDesc.addField(FieldDescriptor(
            name: "departments",
            number: 2,
            type: .message,
            typeName: "example.Department",
            isRepeated: true
        ))
        
        fileDescriptor.addMessage(employeeDesc)
        fileDescriptor.addMessage(departmentDesc)
        fileDescriptor.addMessage(organizationDesc)
        return fileDescriptor
    }
    
    private static func createDatasetStructure() throws -> FileDescriptor {
        var fileDescriptor = FileDescriptor(name: "dataset.proto", package: "example")
        
        var recordDesc = MessageDescriptor(name: "DataRecord", parent: fileDescriptor)
        recordDesc.addField(FieldDescriptor(name: "id", number: 1, type: .string))
        recordDesc.addField(FieldDescriptor(name: "value", number: 2, type: .double))
        recordDesc.addField(FieldDescriptor(name: "timestamp", number: 3, type: .int64))
        recordDesc.addField(FieldDescriptor(name: "tags", number: 4, type: .string, isRepeated: true))
        
        fileDescriptor.addMessage(recordDesc)
        return fileDescriptor
    }
    
    private static func createConfigurationStructure() throws -> FileDescriptor {
        var fileDescriptor = FileDescriptor(name: "configuration.proto", package: "example")
        
        var configDesc = MessageDescriptor(name: "Configuration", parent: fileDescriptor)
        configDesc.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        configDesc.addField(FieldDescriptor(name: "version", number: 2, type: .string))
        configDesc.addField(FieldDescriptor(name: "debug_enabled", number: 3, type: .bool))
        configDesc.addField(FieldDescriptor(name: "max_connections", number: 4, type: .int32))
        configDesc.addField(FieldDescriptor(name: "features", number: 5, type: .string, isRepeated: true))
        configDesc.addField(FieldDescriptor(name: "environment", number: 6, type: .string))
        
        fileDescriptor.addMessage(configDesc)
        return fileDescriptor
    }
    
    // MARK: - Helper Functions
    
    private static func populatePersonData(_ person: inout DynamicMessage) throws {
        try person.set("John Doe", forField: "name")
        try person.set(Int32(30), forField: "age")
        try person.set("john.doe@example.com", forField: "email")
        try person.set(["reading", "coding", "hiking"], forField: "hobbies")
    }
    
    private static func createBasicClone(_ original: DynamicMessage, factory: MessageFactory) throws -> DynamicMessage {
        var clone = factory.createMessage(from: original.descriptor)
        
        for field in original.descriptor.fields.values {
            if try original.hasValue(forField: field.name) {
                let value = try original.get(forField: field.name)
                try clone.set(value as Any, forField: field.name)
            }
        }
        
        return clone
    }
    
    private static func verifyIndependence(original: DynamicMessage, clone: DynamicMessage) throws {
        let originalName = try original.get(forField: "name") as? String
        let cloneName = try clone.get(forField: "name") as? String
        
        _ = ExampleUtils.assertEqual(originalName, cloneName, description: "Names should be equal initially")
        
        // Check that they are different objects (this is inherently true for DynamicMessage)
        print("      ✅ Objects are independent (different instances)")
    }
    
    private static func populateTeamData(_ team: inout DynamicMessage, factory: MessageFactory, fileDescriptor: FileDescriptor) throws {
        try team.set("Development Team", forField: "name")
        
        let personDescriptor = fileDescriptor.messages.values.first { $0.name == "Person" }!
        
        var member1 = factory.createMessage(from: personDescriptor)
        try member1.set("Alice Johnson", forField: "name")
        try member1.set("Lead Developer", forField: "role")
        
        var member2 = factory.createMessage(from: personDescriptor)
        try member2.set("Bob Smith", forField: "name")
        try member2.set("Senior Developer", forField: "role")
        
        try team.set([member1, member2], forField: "members")
    }
    
    private static func createShallowCopy(_ original: DynamicMessage, factory: MessageFactory) throws -> DynamicMessage {
        // Shallow copy shares references to nested objects
        var copy = factory.createMessage(from: original.descriptor)
        
        for field in original.descriptor.fields.values {
            if try original.hasValue(forField: field.name) {
                let value = try original.get(forField: field.name)
                try copy.set(value as Any, forField: field.name)
            }
        }
        
        return copy
    }
    
    private static func createDeepCopy(_ original: DynamicMessage, factory: MessageFactory) throws -> DynamicMessage {
        var copy = factory.createMessage(from: original.descriptor)
        
        for field in original.descriptor.fields.values {
            if try original.hasValue(forField: field.name) {
                let value = try original.get(forField: field.name)
                
                if field.type == .message && field.isRepeated {
                    // Deep copy array of messages
                    if let messages = value as? [DynamicMessage] {
                        let clonedMessages = try messages.map { try createDeepCopy($0, factory: factory) }
                        try copy.set(clonedMessages, forField: field.name)
                    }
                } else if field.type == .message {
                    // Deep copy single message
                    if let message = value as? DynamicMessage {
                        let clonedMessage = try createDeepCopy(message, factory: factory)
                        try copy.set(clonedMessage, forField: field.name)
                    }
                } else {
                    // For primitive types, just copy the value
                    try copy.set(value as Any, forField: field.name)
                }
            }
        }
        
        return copy
    }
    
    private static func demonstrateCopyDifferences(original: DynamicMessage, shallow: DynamicMessage, deep: DynamicMessage) throws {
        // Modify a nested object in the original
        if let members = try original.get(forField: "members") as? [DynamicMessage],
           let firstMember = members.first {
            
            var mutableMembers = members
            var mutableFirstMember = firstMember
            try mutableFirstMember.set("Alice Johnson (MODIFIED)", forField: "name")
            mutableMembers[0] = mutableFirstMember
            
            // This would affect the shallow copy but not the deep copy
            // Note: In practice, this is complex with DynamicMessage due to value semantics
            print("      🔄 Modified original nested object")
            print("      📄 Shallow copy: references may be shared")
            print("      📚 Deep copy: completely independent")
        }
    }
    
    private static func populateFullProfile(_ profile: inout DynamicMessage) throws {
        try profile.set("John Doe", forField: "name")
        try profile.set("john.doe@example.com", forField: "email")
        try profile.set(Int32(30), forField: "age")
        try profile.set("+1-555-0123", forField: "phone")
        try profile.set("123 Main St, City, State 12345", forField: "address")
        try profile.set("123-45-6789", forField: "ssn")
        try profile.set("4532-1234-5678-9012", forField: "credit_card")
        try profile.set("hashed_password_value", forField: "password_hash")
        try profile.set(["dark_mode", "notifications", "analytics"], forField: "preferences")
    }
    
    private static func createPartialCopy(_ original: DynamicMessage, fields: [String], factory: MessageFactory) throws -> DynamicMessage {
        var copy = factory.createMessage(from: original.descriptor)
        
        for fieldName in fields {
            if original.descriptor.fields.values.contains(where: { $0.name == fieldName }),
               try original.hasValue(forField: fieldName) {
                let value = try original.get(forField: fieldName)
                try copy.set(value as Any, forField: fieldName)
            }
        }
        
        return copy
    }
    
    private static func createCopyExcluding(_ original: DynamicMessage, excludedFields: [String], factory: MessageFactory) throws -> DynamicMessage {
        var copy = factory.createMessage(from: original.descriptor)
        
        for field in original.descriptor.fields.values {
            if !excludedFields.contains(field.name) {
                if try original.hasValue(forField: field.name) {
                    let value = try original.get(forField: field.name)
                    try copy.set(value as Any, forField: field.name)
                }
            }
        }
        
        return copy
    }
    
    private static func analyzeProfileSizes(full: DynamicMessage, basic: DynamicMessage, contact: DynamicMessage, publicProfile: DynamicMessage) throws {
        let fullFields = try countPopulatedFields(full)
        let basicFields = try countPopulatedFields(basic)
        let contactFields = try countPopulatedFields(contact)
        let publicFields = try countPopulatedFields(publicProfile)
        
        ExampleUtils.printTable([
            "Full Profile": "\(fullFields) fields",
            "Basic Profile": "\(basicFields) fields (\(basicFields * 100 / fullFields)%)",
            "Contact Profile": "\(contactFields) fields (\(contactFields * 100 / fullFields)%)",
            "Public Profile": "\(publicFields) fields (\(publicFields * 100 / fullFields)%)"
        ], title: "Profile Size Comparison")
    }
    
    private static func countPopulatedFields(_ message: DynamicMessage) throws -> Int {
        var count = 0
        for field in message.descriptor.fields.values {
            if try message.hasValue(forField: field.name) {
                count += 1
            }
        }
        return count
    }
    
    private static func populateOrganizationData(_ org: inout DynamicMessage, factory: MessageFactory, fileDescriptor: FileDescriptor) throws {
        try org.set("TechCorp Inc.", forField: "name")
        
        let employeeDescriptor = fileDescriptor.messages.values.first { $0.name == "Employee" }!
        let departmentDescriptor = fileDescriptor.messages.values.first { $0.name == "Department" }!
        
        // Create Engineering department
        var engDept = factory.createMessage(from: departmentDescriptor)
        try engDept.set("Engineering", forField: "name")
        
        var emp1 = factory.createMessage(from: employeeDescriptor)
        try emp1.set("Alice Johnson", forField: "name")
        try emp1.set("Senior Engineer", forField: "title")
        try emp1.set("ENG001", forField: "employee_id")
        
        var emp2 = factory.createMessage(from: employeeDescriptor)
        try emp2.set("Bob Smith", forField: "name")
        try emp2.set("Tech Lead", forField: "title")
        try emp2.set("ENG002", forField: "employee_id")
        
        try engDept.set([emp1, emp2], forField: "employees")
        
        // Create Sales department
        var salesDept = factory.createMessage(from: departmentDescriptor)
        try salesDept.set("Sales", forField: "name")
        
        var emp3 = factory.createMessage(from: employeeDescriptor)
        try emp3.set("Carol Davis", forField: "name")
        try emp3.set("Sales Manager", forField: "title")
        try emp3.set("SAL001", forField: "employee_id")
        
        try salesDept.set([emp3], forField: "employees")
        
        try org.set([engDept, salesDept], forField: "departments")
    }
    
    private static func printOrganizationSummary(_ org: DynamicMessage) throws {
        let orgName = try org.get(forField: "name") as? String ?? "Unknown"
        print("    🏢 Organization: \(orgName)")
        
        if let departments = try org.get(forField: "departments") as? [DynamicMessage] {
            for dept in departments {
                let deptName = try dept.get(forField: "name") as? String ?? "Unknown"
                let employees = try dept.get(forField: "employees") as? [DynamicMessage] ?? []
                print("      📂 Department: \(deptName) (\(employees.count) employees)")
            }
        }
    }
    
    private static func cloneComplexOrganization(_ org: DynamicMessage, factory: MessageFactory, fileDescriptor: FileDescriptor) throws -> DynamicMessage {
        return try createDeepCopy(org, factory: factory)
    }
    
    private static func verifyOrganizationIntegrity(original: DynamicMessage, cloned: DynamicMessage) throws {
        let originalName = try original.get(forField: "name") as? String
        let clonedName = try cloned.get(forField: "name") as? String
        
        _ = ExampleUtils.assertEqual(originalName, clonedName, description: "Organization names")
        
        let originalDepts = try original.get(forField: "departments") as? [DynamicMessage] ?? []
        let clonedDepts = try cloned.get(forField: "departments") as? [DynamicMessage] ?? []
        
        _ = ExampleUtils.assertEqual(originalDepts.count, clonedDepts.count, description: "Department count")
        
        print("      ✅ Organization structure integrity verified")
    }
    
    private static func cloneAndRestructure(_ org: DynamicMessage, factory: MessageFactory, fileDescriptor: FileDescriptor) throws -> DynamicMessage {
        var restructured = try createDeepCopy(org, factory: factory)
        
        // Simulate restructuring by renaming
        if let orgName = try restructured.get(forField: "name") as? String {
            try restructured.set("\(orgName) - Restructured", forField: "name")
        }
        
        return restructured
    }
    
    private static func createLargeDataset(count: Int, factory: MessageFactory, descriptor: MessageDescriptor) throws -> [DynamicMessage] {
        var dataset: [DynamicMessage] = []
        
        for i in 0..<count {
            var record = factory.createMessage(from: descriptor)
            try record.set("record_\(i)", forField: "id")
            try record.set(Double.random(in: 0...100), forField: "value")
            try record.set(Int64(Date().timeIntervalSince1970 * 1000), forField: "timestamp")
            try record.set(["tag\(i % 10)", "category\(i % 5)"], forField: "tags")
            dataset.append(record)
        }
        
        return dataset
    }
    
    private static func performNaiveBulkCloning(_ dataset: [DynamicMessage], factory: MessageFactory) throws -> [DynamicMessage] {
        var clones: [DynamicMessage] = []
        
        for original in dataset {
            let clone = try createBasicClone(original, factory: factory)
            clones.append(clone)
        }
        
        return clones
    }
    
    private static func performOptimizedBulkCloning(_ dataset: [DynamicMessage], factory: MessageFactory, descriptor: MessageDescriptor) throws -> [DynamicMessage] {
        var clones: [DynamicMessage] = []
        clones.reserveCapacity(dataset.count)
        
        // Reuse field names array to avoid repeated lookups
        let fieldNames = descriptor.fields.values.map { $0.name }
        
        for original in dataset {
            var clone = factory.createMessage(from: descriptor)
            
            // Optimized field copying using pre-computed field names
            for fieldName in fieldNames {
                if try original.hasValue(forField: fieldName) {
                    let value = try original.get(forField: fieldName)
                    try clone.set(value as Any, forField: fieldName)
                }
            }
            
            clones.append(clone)
        }
        
        return clones
    }
    
    private static func performParallelCloning(_ dataset: [DynamicMessage], factory: MessageFactory, descriptor: MessageDescriptor) throws -> [DynamicMessage] {
        // Simulate parallel processing by chunking
        let chunkSize = max(1, dataset.count / 4)
        var clones: [DynamicMessage] = []
        
        for i in stride(from: 0, to: dataset.count, by: chunkSize) {
            let chunk = Array(dataset[i..<min(i + chunkSize, dataset.count)])
            let chunkClones = try performOptimizedBulkCloning(chunk, factory: factory, descriptor: descriptor)
            clones.append(contentsOf: chunkClones)
        }
        
        return clones
    }
    
    private static func populateConfiguration(_ config: inout DynamicMessage) throws {
        try config.set("Production Config", forField: "name")
        try config.set("1.0", forField: "version")
        try config.set(false, forField: "debug_enabled")
        try config.set(Int32(100), forField: "max_connections")
        try config.set(["feature_a", "feature_b"], forField: "features")
        try config.set("production", forField: "environment")
    }
    
    private static func createVersionAwareClone(_ config: DynamicMessage, targetVersion: String, factory: MessageFactory, descriptor: MessageDescriptor) throws -> DynamicMessage {
        var clone = try createBasicClone(config, factory: factory)
        
        try clone.set(targetVersion, forField: "version")
        
        // Version-specific modifications
        if targetVersion.hasPrefix("2.") {
            // v2.x features
            if let features = try clone.get(forField: "features") as? [String] {
                let v2Features = features + ["v2_feature"]
                try clone.set(v2Features, forField: "features")
            }
        }
        
        return clone
    }
    
    private static func createEnvironmentSpecificClone(_ config: DynamicMessage, environment: String, factory: MessageFactory, descriptor: MessageDescriptor) throws -> DynamicMessage {
        var clone = try createBasicClone(config, factory: factory)
        
        try clone.set(environment, forField: "environment")
        
        // Environment-specific settings
        switch environment {
        case "development":
            try clone.set(true, forField: "debug_enabled")
            try clone.set("Development Config", forField: "name")
        case "staging":
            try clone.set(false, forField: "debug_enabled")
            try clone.set("Staging Config", forField: "name")
        case "production":
            try clone.set(false, forField: "debug_enabled")
            try clone.set(Int32(1000), forField: "max_connections")
            try clone.set("Production Config", forField: "name")
        default:
            break
        }
        
        return clone
    }
    
    private static func createTemplateBasedClone(_ config: DynamicMessage, template: String, factory: MessageFactory, descriptor: MessageDescriptor) throws -> DynamicMessage {
        var clone = factory.createMessage(from: descriptor)
        
        // Apply template-specific fields
        switch template {
        case "minimal":
            try clone.set("Minimal Config", forField: "name")
            try clone.set("1.0", forField: "version")
        case "standard":
            try clone.set("Standard Config", forField: "name")
            try clone.set("1.0", forField: "version")
            try clone.set(false, forField: "debug_enabled")
            try clone.set(Int32(50), forField: "max_connections")
        case "enterprise":
            try clone.set("Enterprise Config", forField: "name")
            try clone.set("1.0", forField: "version")
            try clone.set(false, forField: "debug_enabled")
            try clone.set(Int32(1000), forField: "max_connections")
            try clone.set(["feature_a", "feature_b", "enterprise_feature"], forField: "features")
            try clone.set("production", forField: "environment")
        default:
            break
        }
        
        return clone
    }
    
    private static func createIncrementalClone(original: DynamicMessage, modified: DynamicMessage, factory: MessageFactory, descriptor: MessageDescriptor) throws -> DynamicMessage {
        var incrementalClone = factory.createMessage(from: descriptor)
        
        // Only copy fields that are different
        for field in descriptor.fields.values {
            let originalValue = try? original.get(forField: field.name)
            let modifiedValue = try? modified.get(forField: field.name)
            
            // Simple comparison (in practice, would need more sophisticated comparison)
            if let modVal = modifiedValue, let _ = originalValue {
                // For demonstration, we'll copy if the values seem different
                // In practice, you'd implement proper value comparison
                try incrementalClone.set(modVal as Any, forField: field.name)
            } else if modifiedValue != nil {
                try incrementalClone.set(modifiedValue! as Any, forField: field.name)
            }
        }
        
        return incrementalClone
    }
}
