/**
 * 🚫 SwiftProtoReflect Example: Empty Demo
 * 
 * Описание: Работа с google.protobuf.Empty - пустые сообщения без полей
 * Ключевые концепции: EmptyHandler, Unit Type, Singleton Pattern
 * Сложность: 🔰 Начальный
 * Время выполнения: < 5 секунд
 * 
 * Что изучите:
 * - Создание и конвертация google.protobuf.Empty
 * - Singleton pattern для EmptyValue
 * - Интеграция с Swift Void типом
 * - Использование в качестве placeholder'а
 * - gRPC Empty responses
 * - Unit type семантика
 * 
 * Запуск: 
 *   swift run EmptyDemo
 */

import Foundation
import SwiftProtoReflect
import ExampleUtils

@main
struct EmptyDemo {
    static func main() throws {
        ExampleUtils.printHeader("Google Protobuf Empty Integration")
        
        try demonstrateBasicUsage()
        try demonstrateUnitTypeIntegration()
        try demonstrateConvenienceMethods()
        try demonstrateUseCases()
        try demonstratePerformanceAndComparisons()
        
        ExampleUtils.printSuccess("Empty demo завершена! Вы изучили все аспекты работы с google.protobuf.Empty.")
        
        ExampleUtils.printNext([
            "Далее изучите: field-mask-demo.swift - маски полей для updates",
            "Сравните: timestamp-demo.swift - временные метки", 
            "Сравните: duration-demo.swift - временные интервалы"
        ])
    }
    
    // MARK: - Implementation Steps
    
    private static func demonstrateBasicUsage() throws {
        ExampleUtils.printStep(1, "Basic Empty Operations")
        
        // Создание EmptyValue
        let empty1 = EmptyHandler.EmptyValue()
        let empty2 = EmptyHandler.EmptyValue.instance
        
        print("  🏗 Created EmptyValue instances:")
        print("    Manual creation: \(empty1)")
        print("    Singleton instance: \(empty2)")
        print("    Are equal: \(empty1 == empty2 ? "✅ YES" : "❌ NO")")
        
        // Конвертация в DynamicMessage
        let emptyMessage = try EmptyHandler.createDynamic(from: empty1)
        
        print("  📋 Empty message structure:")
        print("    Message type: \(emptyMessage.descriptor.name)")
        print("    Full name: \(emptyMessage.descriptor.fullName)")
        print("    Fields count: \(emptyMessage.descriptor.fields.count)")
        // Извлекаем package из fullName (убираем .Empty с конца)
        let fullName = emptyMessage.descriptor.fullName
        let packageName = fullName.replacingOccurrences(of: ".Empty", with: "")
        print("    Package: \(packageName)")
        
        // Конвертация обратно
        let extractedValue = try EmptyHandler.createSpecialized(from: emptyMessage) as! EmptyHandler.EmptyValue
        
        print("  🔄 Round-trip conversion:")
        print("    Original: \(empty1)")
        print("    Extracted: \(extractedValue)")
        print("    Round-trip success: \(empty1 == extractedValue ? "✅ YES" : "❌ NO")")
        
        // Проверка singleton behavior
        print("  🔒 Singleton behavior:")
        print("    All instances equal: \(empty1 == empty2 && empty2 == extractedValue ? "✅ YES" : "❌ NO")")
        print("    Instance is singleton: \(extractedValue == EmptyHandler.EmptyValue.instance ? "✅ YES" : "❌ NO")")
    }
    
    private static func demonstrateUnitTypeIntegration() throws {
        ExampleUtils.printStep(2, "Unit Type Integration with Swift Void")
        
        // Интеграция с Void типом
        let voidValue: Void = ()
        let emptyFromVoid = EmptyHandler.EmptyValue.from(voidValue)
        
        print("  🔄 Void ↔ Empty conversion:")
        print("    Original Void: () (unit type)")
        print("    Converted to Empty: \(emptyFromVoid)")
        print("    Is singleton: \(emptyFromVoid == EmptyHandler.EmptyValue.instance ? "✅ YES" : "❌ NO")")
        
        // Конвертация обратно в Void
        let empty = EmptyHandler.EmptyValue.instance
        empty.toVoid() // Возвращает Void
        
        print("    Converted back to Void: () (operation completed)")
        
        // Демонстрация использования в функциях
        func processEmpty(_ empty: EmptyHandler.EmptyValue) {
            print("    Processing Empty value: \(empty)")
        }
        
        func processVoid(_ void: Void) {
            print("    Processing Void value: () (unit type)")
        }
        
        print("  🔧 Function integration:")
        processEmpty(emptyFromVoid)
        processVoid(empty.toVoid())
        
        // Unit type семантика
        let unitTypeAnalysis = [
            "Empty как unit type" : "Представляет отсутствие данных",
            "Singleton pattern" : "Все экземпляры семантически равны",
            "Void integration" : "Seamless конвертация с Swift Void",
            "Memory efficient" : "Минимальное использование памяти",
            "Type safety" : "Строгая типизация для пустых ответов"
        ]
        
        ExampleUtils.printTable(unitTypeAnalysis, title: "Unit Type Properties")
    }
    
    private static func demonstrateConvenienceMethods() throws {
        ExampleUtils.printStep(3, "Convenience Methods and Extensions")
        
        // DynamicMessage convenience methods
        let emptyMessage1 = try DynamicMessage.emptyMessage()
        let emptyMessage2 = try DynamicMessage.emptyMessage()
        
        print("  🏭 DynamicMessage convenience creation:")
        print("    Created via convenience method: \(emptyMessage1.descriptor.name)")
        print("    Second instance: \(emptyMessage2.descriptor.name)")
        
        // isEmpty() проверка
        print("  🔍 Empty detection:")
        print("    First message isEmpty(): \(emptyMessage1.isEmpty() ? "✅ YES" : "❌ NO")")
        print("    Second message isEmpty(): \(emptyMessage2.isEmpty() ? "✅ YES" : "❌ NO")")
        
        // Создание не-Empty сообщения для сравнения
        var fileDescriptor = FileDescriptor(name: "test.proto", package: "test")
        var messageDescriptor = MessageDescriptor(name: "NotEmpty", parent: fileDescriptor)
        messageDescriptor.addField(FieldDescriptor(name: "value", number: 1, type: .string))
        fileDescriptor.addMessage(messageDescriptor)
        
        let factory = MessageFactory()
        let notEmptyMessage = factory.createMessage(from: messageDescriptor)
        
        print("    Non-empty message isEmpty(): \(notEmptyMessage.isEmpty() ? "✅ YES" : "❌ NO")")
        
        // toEmpty() conversion
        let convertedEmpty1 = try emptyMessage1.toEmpty()
        let convertedEmpty2 = try emptyMessage2.toEmpty()
        
        print("  🔄 toEmpty() conversion:")
        print("    First conversion: \(convertedEmpty1)")
        print("    Second conversion: \(convertedEmpty2)")
        print("    Both are singleton: \(convertedEmpty1 == EmptyHandler.EmptyValue.instance && convertedEmpty2 == EmptyHandler.EmptyValue.instance ? "✅ YES" : "❌ NO")")
        
        // Error handling для неправильных типов
        print("  ⚠️ Error handling:")
        do {
            let _ = try notEmptyMessage.toEmpty()
            print("    Unexpected success converting non-empty message")
        } catch {
            print("    ✅ Correctly rejected non-empty message: \(type(of: error))")
        }
    }
    
    private static func demonstrateUseCases() throws {
        ExampleUtils.printStep(4, "Real-World Use Cases")
        
        // gRPC Empty responses
        print("  🌐 gRPC Empty Response Simulation:")
        
        struct MockgRPCService {
            static func deleteUser() throws -> EmptyHandler.EmptyValue {
                // Simulate successful deletion
                print("    🗑 User deleted successfully")
                return EmptyHandler.EmptyValue.instance
            }
            
            static func clearCache() throws -> DynamicMessage {
                // Return Empty as DynamicMessage
                print("    🧹 Cache cleared successfully")
                return try DynamicMessage.emptyMessage()
            }
            
            static func healthCheck() throws -> EmptyHandler.EmptyValue {
                // Health check returns empty on success
                print("    💚 Health check passed")
                return EmptyHandler.EmptyValue.instance
            }
        }
        
        // Демонстрация использования
        let deleteResponse = try MockgRPCService.deleteUser()
        let clearResponse = try MockgRPCService.clearCache()
        let healthResponse = try MockgRPCService.healthCheck()
        
        print("  📋 Service responses:")
        print("    Delete response: \(deleteResponse) (type: \(type(of: deleteResponse)))")
        print("    Clear response: \(clearResponse.descriptor.name) (type: DynamicMessage)")
        print("    Health response: \(healthResponse) (type: \(type(of: healthResponse)))")
        
        let useCaseResults = [
            ["Operation": "Delete User", "Response Type": "EmptyValue", "Success": "✅", "Use Case": "Confirmation без данных"],
            ["Operation": "Clear Cache", "Response Type": "DynamicMessage", "Success": "✅", "Use Case": "Операции без возврата"],
            ["Operation": "Health Check", "Response Type": "EmptyValue", "Success": "✅", "Use Case": "Status проверки"],
        ]
        
        ExampleUtils.printDataTable(useCaseResults, title: "gRPC Use Cases")
        
        // API Placeholder patterns
        print("  📡 API Placeholder Patterns:")
        
        struct APIEndpoint {
            let path: String
            let method: String
            let requestType: String
            let responseType: String
            let description: String
        }
        
        let apiEndpoints = [
            APIEndpoint(path: "/users/{id}", method: "DELETE", requestType: "Empty", responseType: "Empty", description: "Delete user"),
            APIEndpoint(path: "/cache/clear", method: "POST", requestType: "Empty", responseType: "Empty", description: "Clear application cache"),
            APIEndpoint(path: "/health", method: "GET", requestType: "Empty", responseType: "Empty", description: "Health check endpoint"),
            APIEndpoint(path: "/logout", method: "POST", requestType: "Empty", responseType: "Empty", description: "User logout"),
        ]
        
        let endpointData = apiEndpoints.map { endpoint in
            [
                "Path": endpoint.path,
                "Method": endpoint.method,
                "Request": endpoint.requestType,
                "Response": endpoint.responseType,
                "Description": endpoint.description
            ]
        }
        
        ExampleUtils.printDataTable(endpointData, title: "API Endpoints Using Empty")
        
        print("  💡 Empty usage patterns:")
        print("    • Confirmation responses без данных")
        print("    • Health check endpoints")
        print("    • DELETE операции")
        print("    • Logout/clear операции")
        print("    • Placeholder для будущих полей")
    }
    
    private static func demonstratePerformanceAndComparisons() throws {
        ExampleUtils.printStep(5, "Performance Analysis and Comparisons")
        
        // Performance testing
        let testCount = 10000
        
        let (_, creationTime) = ExampleUtils.measureTime {
            for _ in 0..<testCount {
                let _ = EmptyHandler.EmptyValue()
                let _ = EmptyHandler.EmptyValue.instance
            }
        }
        
        let (_, conversionTime) = ExampleUtils.measureTime {
            for _ in 0..<testCount {
                let empty = EmptyHandler.EmptyValue.instance
                let _ = try! EmptyHandler.createDynamic(from: empty)
            }
        }
        
        let (_, handlerTime) = ExampleUtils.measureTime {
            for _ in 0..<testCount {
                let empty = EmptyHandler.EmptyValue.instance
                let message = try! EmptyHandler.createDynamic(from: empty)
                let _ = try! EmptyHandler.createSpecialized(from: message)
            }
        }
        
        ExampleUtils.printTiming("EmptyValue creation (\(testCount) iterations)", time: creationTime)
        ExampleUtils.printTiming("Empty to DynamicMessage (\(testCount) iterations)", time: conversionTime)
        ExampleUtils.printTiming("Full round-trip (\(testCount) iterations)", time: handlerTime)
        
        let creationsPerSecond = Double(testCount * 2) / creationTime // x2 because we create 2 instances per iteration
        let conversionsPerSecond = Double(testCount) / conversionTime
        let roundTripsPerSecond = Double(testCount) / handlerTime
        
        print("  🚀 Performance metrics:")
        print("    Creation rate: \(String(format: "%.0f", creationsPerSecond)) instances/second")
        print("    Conversion rate: \(String(format: "%.0f", conversionsPerSecond)) conversions/second")
        print("    Round-trip rate: \(String(format: "%.0f", roundTripsPerSecond)) round-trips/second")
        
        // Размер и memory footprint
        print("  💾 Memory characteristics:")
        
        let emptyMessage = try DynamicMessage.emptyMessage()
        
        let packageName = emptyMessage.descriptor.fullName.replacingOccurrences(of: ".Empty", with: "")
        let characteristics = [
            "EmptyValue size" : "Minimal (unit type)",
            "DynamicMessage fields" : "\(emptyMessage.descriptor.fields.count)",
            "Descriptor name" : emptyMessage.descriptor.name,
            "Package" : packageName,
            "Singleton pattern" : "Reduces memory allocation",
            "Wire format size" : "0 bytes (no fields)"
        ]
        
        ExampleUtils.printTable(characteristics, title: "Memory Characteristics")
        
        // Сравнение с другими Well-Known Types
        let comparison = [
            ["Type": "Empty", "Fields": "0", "Use Case": "Unit type, confirmations", "Complexity": "Minimal"],
            ["Type": "Timestamp", "Fields": "2", "Use Case": "Time representation", "Complexity": "Medium"],
            ["Type": "Duration", "Fields": "2", "Use Case": "Time intervals", "Complexity": "Medium"],
            ["Type": "FieldMask", "Fields": "1", "Use Case": "Partial updates", "Complexity": "High"],
        ]
        
        ExampleUtils.printDataTable(comparison, title: "Well-Known Types Comparison")
        
        print("  📊 Key insights:")
        print("    • Empty является самым простым Well-Known Type")
        print("    • Singleton pattern обеспечивает efficiency")
        print("    • Отлично подходит для confirmations и health checks")
        print("    • Нулевой wire format размер")
        print("    • High performance благодаря простоте")
    }
}
