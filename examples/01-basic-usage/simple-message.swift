/**
 * 🏗 SwiftProtoReflect Example: Simple Complex Messages
 * 
 * Описание: Создание более сложных сообщений с вложенностью, oneof полями и message типами
 * Ключевые концепции: Nested Messages, OneOf Fields, Message Types, Default Values
 * Сложность: 🔧 Средний
 * Время выполнения: < 10 секунд
 * 
 * Что изучите:
 * - Создание вложенных сообщений (nested messages)
 * - Использование oneof полей для взаимоисключающих значений
 * - Работа с message типами и typeName
 * - Default значения для полей
 * - Сложные иерархии данных
 * 
 * Запуск: 
 *   swift run SimpleMessage
 *   make run-basic
 */

import Foundation
import SwiftProtoReflect
import ExampleUtils

@main
struct SimpleMessageExample {
    static func main() throws {
        ExampleUtils.printHeader("Сложные сообщения - Вложенность и OneOf поля")
        
        try step1_createNestedMessages()
        try step2_useOneOfFields()
        try step3_workWithMessageTypes()
        try step4_defaultValues()
        try step5_complexHierarchy()
        
        ExampleUtils.printSuccess("Вы освоили создание сложных Protocol Buffers сообщений!")
        
        ExampleUtils.printNext([
            "Следующий: basic-descriptors.swift - метаданные и навигация дескрипторов",
            "Продвинутые: complex-messages.swift - еще более сложные структуры",
            "Изучите: nested-messages.swift - специализация на вложенных сообщениях"
        ])
    }
    
    // MARK: - Implementation Steps
    
    private static func step1_createNestedMessages() throws {
        ExampleUtils.printStep(1, "Создание вложенных сообщений")
        
        let (userDescriptor, addressDescriptor, _) = try createNestedMessageStructure()
        let factory = MessageFactory()
        
        // Создаем сообщения
        var user = factory.createMessage(from: userDescriptor)
        var address = factory.createMessage(from: addressDescriptor)
        
        // Заполняем вложенное сообщение Address
        try address.set("123 Main Street", forField: "street")
        try address.set("Springfield", forField: "city")
        try address.set("12345", forField: "postal_code")
        
        print("  📍 Создан Address:")
        address.prettyPrint()
        
        // Заполняем основное сообщение User
        try user.set("John Doe", forField: "name")
        try user.set("john.doe@example.com", forField: "email")
        try user.set(Int32(30), forField: "age")
        try user.set(address, forField: "address")
        
        print("\n  👤 Создан User с вложенным Address:")
        user.prettyPrint()
        
        // Проверяем доступ к вложенным данным
        if let userAddress = try user.get(forField: "address") as? DynamicMessage {
            let street = try userAddress.get(forField: "street") as? String
            print("  🏠 Улица пользователя: \(street ?? "не указана")")
        }
    }
    
    private static func step2_useOneOfFields() throws {
        ExampleUtils.printStep(2, "Использование OneOf полей")
        
        let (messageDescriptor, _) = try createOneOfMessage()
        let factory = MessageFactory()
        
        // Демонстрируем разные варианты oneof
        print("  🔀 Тестирование OneOf полей:")
        
        // Вариант 1: contact_method = email
        var message1 = factory.createMessage(from: messageDescriptor)
        try message1.set("user@example.com", forField: "email")
        
        let hasEmail = try message1.hasValue(forField: "email")
        let hasPhone = try message1.hasValue(forField: "phone")
        
        print("    📧 Установлен email:")
        print("      - hasEmail: \(hasEmail)")
        print("      - hasPhone: \(hasPhone)")
        print("      - email: \(try message1.get(forField: "email") as? String ?? "nil")")
        
        // Вариант 2: contact_method = phone (перезапишет email)
        try message1.set("+1-555-123-4567", forField: "phone")
        
        let hasEmailAfter = try message1.hasValue(forField: "email")
        let hasPhoneAfter = try message1.hasValue(forField: "phone")
        
        print("    📞 Установлен phone (должен сбросить email):")
        print("      - hasEmail: \(hasEmailAfter)")
        print("      - hasPhone: \(hasPhoneAfter)")
        print("      - phone: \(try message1.get(forField: "phone") as? String ?? "nil")")
        
        // Вариант 3: другой oneof - notification_method
        try message1.set(true, forField: "push_enabled")
        let hasPush = try message1.hasValue(forField: "push_enabled")
        print("    🔔 Notification method - push_enabled: \(hasPush)")
    }
    
    private static func step3_workWithMessageTypes() throws {
        ExampleUtils.printStep(3, "Работа с message типами")
        
        let (companyDescriptor, departmentDescriptor, _) = try createCompanyStructure()
        let factory = MessageFactory()
        
        // Создаем department
        var department = factory.createMessage(from: departmentDescriptor)
        try department.set("Engineering", forField: "name")
        try department.set(Int32(25), forField: "employee_count")
        
        print("  🏢 Создан Department:")
        department.prettyPrint()
        
        // Создаем company с вложенным department
        var company = factory.createMessage(from: companyDescriptor)
        try company.set("TechCorp", forField: "name")
        try company.set("A leading technology company", forField: "description")
        
        // Устанавливаем department как message поле
        try company.set(department, forField: "main_department")
        
        print("\n  🏭 Создана Company с вложенным Department:")
        company.prettyPrint()
        
        // Проверяем доступ к message полю
        if let mainDept = try company.get(forField: "main_department") as? DynamicMessage {
            let deptName = try mainDept.get(forField: "name") as? String
            let employeeCount = try mainDept.get(forField: "employee_count") as? Int32
            
            ExampleUtils.printTable([
                "Department Name": deptName ?? "Unknown",
                "Employee Count": employeeCount?.description ?? "0"
            ], title: "Main Department Info")
        }
    }
    
    private static func step4_defaultValues() throws {
        ExampleUtils.printStep(4, "Default значения полей")
        
        let (messageDescriptor, _) = try createMessageWithDefaults()
        let factory = MessageFactory()
        var message = factory.createMessage(from: messageDescriptor)
        
        print("  🎯 Тестирование default значений:")
        
        // Проверяем значения до установки (должны быть defaults или nil)
        let statusBefore = try message.get(forField: "status") as? String
        let priorityBefore = try message.get(forField: "priority") as? Int32
        let activeBefore = try message.get(forField: "is_active") as? Bool
        
        print("    До установки значений:")
        print("      - status: \(statusBefore ?? "nil")")
        print("      - priority: \(priorityBefore?.description ?? "nil")")
        print("      - is_active: \(activeBefore?.description ?? "nil")")
        
        // Устанавливаем значения
        try message.set("pending", forField: "status")
        try message.set(Int32(5), forField: "priority")
        // is_active оставляем без установки
        
        let statusAfter = try message.get(forField: "status") as? String
        let priorityAfter = try message.get(forField: "priority") as? Int32
        let activeAfter = try message.get(forField: "is_active") as? Bool
        
        print("    После установки:")
        print("      - status: \(statusAfter ?? "nil")")
        print("      - priority: \(priorityAfter?.description ?? "nil")")
        print("      - is_active: \(activeAfter?.description ?? "nil") (default)")
    }
    
    private static func step5_complexHierarchy() throws {
        ExampleUtils.printStep(5, "Сложная иерархия сообщений")
        
        let (blogDescriptor, postDescriptor, authorDescriptor, _) = try createBlogStructure()
        let factory = MessageFactory()
        
        // Создаем автора
        var author = factory.createMessage(from: authorDescriptor)
        try author.set("Jane Smith", forField: "name")
        try author.set("jane@example.com", forField: "email")
        try author.set("Senior Developer", forField: "bio")
        
        // Создаем пост
        var post = factory.createMessage(from: postDescriptor)
        try post.set("Introduction to SwiftProtoReflect", forField: "title")
        try post.set("This is a comprehensive guide...", forField: "content")
        try post.set(["swift", "protobuf", "ios"], forField: "tags")
        try post.set(author, forField: "author")
        
        // Создаем блог с постом
        var blog = factory.createMessage(from: blogDescriptor)
        try blog.set("Tech Blog", forField: "name")
        try blog.set("A blog about technology", forField: "description")
        try blog.set([post], forField: "posts")
        
        print("  📝 Создана сложная иерархия Blog -> Post -> Author")
        
        // Демонстрируем навигацию по иерархии
        if let posts = try blog.get(forField: "posts") as? [DynamicMessage],
           let firstPost = posts.first {
            
            let postTitle = try firstPost.get(forField: "title") as? String
            print("  📰 Первый пост: \(postTitle ?? "Untitled")")
            
            if let postAuthor = try firstPost.get(forField: "author") as? DynamicMessage {
                let authorName = try postAuthor.get(forField: "name") as? String
                let authorEmail = try postAuthor.get(forField: "email") as? String
                
                ExampleUtils.printTable([
                    "Post Title": postTitle ?? "Unknown",
                    "Author Name": authorName ?? "Unknown",
                    "Author Email": authorEmail ?? "Unknown"
                ], title: "Blog Post Details")
            }
            
            if let tags = try firstPost.get(forField: "tags") as? [String] {
                print("  🏷  Теги: \(tags.joined(separator: ", "))")
            }
        }
        
        ExampleUtils.printInfo("Демонстрация показывает возможности создания сложных многоуровневых структур данных с помощью SwiftProtoReflect")
    }
    
    // MARK: - Helper Methods
    
    private static func createNestedMessageStructure() throws -> (MessageDescriptor, MessageDescriptor, FileDescriptor) {
        var fileDescriptor = FileDescriptor(name: "user.proto", package: "example")
        
        // Создаем вложенное сообщение Address
        var addressDescriptor = MessageDescriptor(name: "Address", parent: fileDescriptor)
        addressDescriptor.addField(FieldDescriptor(name: "street", number: 1, type: .string))
        addressDescriptor.addField(FieldDescriptor(name: "city", number: 2, type: .string))
        addressDescriptor.addField(FieldDescriptor(name: "postal_code", number: 3, type: .string))
        
        // Создаем основное сообщение User
        var userDescriptor = MessageDescriptor(name: "User", parent: fileDescriptor)
        userDescriptor.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        userDescriptor.addField(FieldDescriptor(name: "email", number: 2, type: .string))
        userDescriptor.addField(FieldDescriptor(name: "age", number: 3, type: .int32))
        userDescriptor.addField(FieldDescriptor(
            name: "address",
            number: 4,
            type: .message,
            typeName: "example.Address"
        ))
        
        fileDescriptor.addMessage(addressDescriptor)
        fileDescriptor.addMessage(userDescriptor)
        
        return (userDescriptor, addressDescriptor, fileDescriptor)
    }
    
    private static func createOneOfMessage() throws -> (MessageDescriptor, FileDescriptor) {
        var fileDescriptor = FileDescriptor(name: "contact.proto", package: "example")
        var messageDescriptor = MessageDescriptor(name: "Contact", parent: fileDescriptor)
        
        // Обычные поля
        messageDescriptor.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        
        // OneOf группа 1: contact_method (email ИЛИ phone)
        messageDescriptor.addField(FieldDescriptor(name: "email", number: 2, type: .string, oneofIndex: 0))
        messageDescriptor.addField(FieldDescriptor(name: "phone", number: 3, type: .string, oneofIndex: 0))
        
        // OneOf группа 2: notification_method (push_enabled ИЛИ sms_enabled)
        messageDescriptor.addField(FieldDescriptor(name: "push_enabled", number: 4, type: .bool, oneofIndex: 1))
        messageDescriptor.addField(FieldDescriptor(name: "sms_enabled", number: 5, type: .bool, oneofIndex: 1))
        
        fileDescriptor.addMessage(messageDescriptor)
        
        return (messageDescriptor, fileDescriptor)
    }
    
    private static func createCompanyStructure() throws -> (MessageDescriptor, MessageDescriptor, FileDescriptor) {
        var fileDescriptor = FileDescriptor(name: "company.proto", package: "example")
        
        // Создаем Department сообщение
        var departmentDescriptor = MessageDescriptor(name: "Department", parent: fileDescriptor)
        departmentDescriptor.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        departmentDescriptor.addField(FieldDescriptor(name: "employee_count", number: 2, type: .int32))
        
        // Создаем Company сообщение с message полем
        var companyDescriptor = MessageDescriptor(name: "Company", parent: fileDescriptor)
        companyDescriptor.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        companyDescriptor.addField(FieldDescriptor(name: "description", number: 2, type: .string))
        companyDescriptor.addField(FieldDescriptor(
            name: "main_department",
            number: 3,
            type: .message,
            typeName: "example.Department"
        ))
        
        fileDescriptor.addMessage(departmentDescriptor)
        fileDescriptor.addMessage(companyDescriptor)
        
        return (companyDescriptor, departmentDescriptor, fileDescriptor)
    }
    
    private static func createMessageWithDefaults() throws -> (MessageDescriptor, FileDescriptor) {
        var fileDescriptor = FileDescriptor(name: "defaults.proto", package: "example")
        var messageDescriptor = MessageDescriptor(name: "TaskInfo", parent: fileDescriptor)
        
        // Поля с potential default значениями
        messageDescriptor.addField(FieldDescriptor(
            name: "status",
            number: 1,
            type: .string,
            defaultValue: "new"
        ))
        messageDescriptor.addField(FieldDescriptor(
            name: "priority",
            number: 2,
            type: .int32,
            defaultValue: Int32(1)
        ))
        messageDescriptor.addField(FieldDescriptor(
            name: "is_active",
            number: 3,
            type: .bool,
            defaultValue: true
        ))
        
        fileDescriptor.addMessage(messageDescriptor)
        
        return (messageDescriptor, fileDescriptor)
    }
    
    private static func createBlogStructure() throws -> (MessageDescriptor, MessageDescriptor, MessageDescriptor, FileDescriptor) {
        var fileDescriptor = FileDescriptor(name: "blog.proto", package: "example")
        
        // Author сообщение
        var authorDescriptor = MessageDescriptor(name: "Author", parent: fileDescriptor)
        authorDescriptor.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        authorDescriptor.addField(FieldDescriptor(name: "email", number: 2, type: .string))
        authorDescriptor.addField(FieldDescriptor(name: "bio", number: 3, type: .string))
        
        // Post сообщение
        var postDescriptor = MessageDescriptor(name: "Post", parent: fileDescriptor)
        postDescriptor.addField(FieldDescriptor(name: "title", number: 1, type: .string))
        postDescriptor.addField(FieldDescriptor(name: "content", number: 2, type: .string))
        postDescriptor.addField(FieldDescriptor(name: "tags", number: 3, type: .string, isRepeated: true))
        postDescriptor.addField(FieldDescriptor(
            name: "author",
            number: 4,
            type: .message,
            typeName: "example.Author"
        ))
        
        // Blog сообщение
        var blogDescriptor = MessageDescriptor(name: "Blog", parent: fileDescriptor)
        blogDescriptor.addField(FieldDescriptor(name: "name", number: 1, type: .string))
        blogDescriptor.addField(FieldDescriptor(name: "description", number: 2, type: .string))
        blogDescriptor.addField(FieldDescriptor(
            name: "posts",
            number: 3,
            type: .message,
            typeName: "example.Post",
            isRepeated: true
        ))
        
        fileDescriptor.addMessage(authorDescriptor)
        fileDescriptor.addMessage(postDescriptor)
        fileDescriptor.addMessage(blogDescriptor)
        
        return (blogDescriptor, postDescriptor, authorDescriptor, fileDescriptor)
    }
}
