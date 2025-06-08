/**
 * 🎛 SwiftProtoReflect Example: Value Demo
 * 
 * Описание: Работа с google.protobuf.Value для универсальных динамических значений
 * Ключевые концепции: ValueHandler, ValueValue, Type switching, Dynamic values
 * Сложность: 🔧 Средний
 * Время выполнения: < 12 секунд
 * 
 * Что изучите:
 * - Создание и манипуляция google.protobuf.Value
 * - Конвертация между произвольными Swift типами и ValueValue
 * - Type switching и pattern matching для различных типов значений
 * - Интеграция с DynamicMessage через valueMessage extensions
 * - Performance analysis и edge cases handling
 * - Real-world сценарии для dynamic type handling
 * 
 * Запуск: 
 *   swift run ValueDemo
 */

import Foundation
import SwiftProtoReflect
import ExampleUtils

@main
struct ValueDemo {
    static func main() throws {
        ExampleUtils.printHeader("Google Protobuf Value Integration")
        
        try demonstrateBasicValueTypes()
        try demonstrateTypeSwitchingAndPatternMatching()
        try demonstrateConversionsAndEdgeCases()
        try demonstrateDynamicMessageIntegration()
        try demonstrateRoundTripCompatibility()
        try demonstratePerformanceAndRealWorldScenarios()
        
        ExampleUtils.printSuccess("Value demo завершена! Вы изучили все аспекты работы с google.protobuf.Value.")
        
        ExampleUtils.printNext([
            "Далее изучите: any-demo.swift - type erasure поддержка",
            "Интеграция: well-known-registry.swift - comprehensive demo",
            "Сравните: struct-demo.swift - JSON-like структуры"
        ])
    }
    
    // MARK: - Implementation Steps
    
    private static func demonstrateBasicValueTypes() throws {
        ExampleUtils.printStep(1, "Basic ValueValue Types and Creation")
        
        print("  🎛 Creating values from Swift types:")
        
        // Все основные типы ValueValue
        let basicValues: [(String, Any, String)] = [
            ("Null Value", NSNull(), "null"),
            ("String Value", "Hello, World!", "string"),
            ("Integer", 42, "number (from Int)"),
            ("Double", 3.14159, "number (from Double)"),
            ("Boolean True", true, "bool"),
            ("Boolean False", false, "bool"),
            ("Array", ["apple", "banana", 123], "list"),
            ("Dictionary", ["name": "John", "age": 30], "struct")
        ]
        
        var valueResults: [[String: String]] = []
        
        for (description, swiftValue, expectedType) in basicValues {
            do {
                let valueValue = try ValueHandler.ValueValue(from: swiftValue)
                let dynamicMessage = try ValueHandler.createDynamic(from: valueValue)
                let roundTrip = try ValueHandler.createSpecialized(from: dynamicMessage) as! ValueHandler.ValueValue
                
                valueResults.append([
                    "Swift Type": description,
                    "Swift Value": "\(swiftValue)",
                    "ValueValue": "\(valueValue)",
                    "Expected Type": expectedType,
                    "Round-trip": roundTrip == valueValue ? "✅ YES" : "❌ NO"
                ])
            } catch {
                valueResults.append([
                    "Swift Type": description,
                    "Swift Value": "\(swiftValue)",
                    "ValueValue": "ERROR",
                    "Expected Type": expectedType,
                    "Round-trip": "❌ ERROR"
                ])
            }
        }
        
        ExampleUtils.printDataTable(valueResults, title: "Basic Value Types")
        
        // Специальная демонстрация каждого case'а
        print("  🔍 Detailed case-by-case analysis:")
        
        // Null value
        let nullValue = ValueHandler.ValueValue.nullValue
        print("    🔳 Null: \(nullValue) -> \(nullValue.toAny())")
        
        // Number values  
        let intValue = try ValueHandler.ValueValue(from: 42)
        let doubleValue = try ValueHandler.ValueValue(from: 3.14)
        print("    🔢 Numbers: \(intValue) -> \(intValue.toAny())")
        print("    🔢 Decimal: \(doubleValue) -> \(doubleValue.toAny())")
        
        // String value
        let stringValue = try ValueHandler.ValueValue(from: "Hello")
        print("    📝 String: \(stringValue) -> \(stringValue.toAny())")
        
        // Bool values
        let boolTrue = try ValueHandler.ValueValue(from: true)
        let boolFalse = try ValueHandler.ValueValue(from: false)
        print("    ✅ Bool True: \(boolTrue) -> \(boolTrue.toAny())")
        print("    ❌ Bool False: \(boolFalse) -> \(boolFalse.toAny())")
        
        // List value
        let listValue = try ValueHandler.ValueValue(from: [1, "two", true])
        print("    📋 List: \(listValue)")
        if let array = listValue.toAny() as? [Any] {
            print("      Converted: \(array)")
        }
        
        // Struct value  
        let structValue = try ValueHandler.ValueValue(from: ["key": "value", "count": 5])
        print("    🏗 Struct: \(structValue)")
        if let dict = structValue.toAny() as? [String: Any] {
            print("      Converted: \(dict)")
        }
    }
    
    private static func demonstrateTypeSwitchingAndPatternMatching() throws {
        ExampleUtils.printStep(2, "Type Switching and Pattern Matching")
        
        // Набор разнообразных значений для демонстрации type switching
        let testValues: [(String, ValueHandler.ValueValue)] = [
            ("null", .nullValue),
            ("integer", .numberValue(42)),
            ("decimal", .numberValue(3.14159)),
            ("empty string", .stringValue("")),
            ("text", .stringValue("Hello, World!")),
            ("unicode", .stringValue("🚀 Unicode Test 🎉")),
            ("true", .boolValue(true)),
            ("false", .boolValue(false))
        ]
        
        print("  🎛 Type switching demonstration:")
        var typeAnalysis: [[String: String]] = []
        
        for (name, value) in testValues {
            let typeInfo = analyzeValueType(value)
            let jsonRepresentation = try convertToJSON(value)
            
            typeAnalysis.append([
                "Value": name,
                "Type": typeInfo.type,
                "Details": typeInfo.details,
                "JSON Size": "\(jsonRepresentation.count) chars",
                "JSON Preview": String(jsonRepresentation.prefix(30)) + (jsonRepresentation.count > 30 ? "..." : "")
            ])
        }
        
        ExampleUtils.printDataTable(typeAnalysis, title: "Type Analysis")
        
        // Pattern matching примеры
        print("  🎯 Pattern matching examples:")
        for (name, value) in testValues {
            let matchResult = performPatternMatching(value)
            print("    \(name): \(matchResult)")
        }
        
        // Conditional processing
        print("  🔀 Conditional processing:")
        let mixedData: [ValueHandler.ValueValue] = [
            .numberValue(100),
            .stringValue("process_me"),
            .boolValue(true),
            .nullValue,
            .listValue([.numberValue(1), .numberValue(2)]),
            .stringValue("ignore_me")
        ]
        
        let processed = processValuesBatch(mixedData)
        print("    Input: \(mixedData.count) values")
        print("    Processed: \(processed.count) results")
        print("    Results: \(processed)")
    }
    
    private static func demonstrateConversionsAndEdgeCases() throws {
        ExampleUtils.printStep(3, "Conversions and Edge Cases")
        
        print("  🔄 Numeric type conversions:")
        let numericTypes: [Any] = [
            Int8(8), Int16(16), Int32(32), Int64(64),
            UInt8(108), UInt16(116), UInt32(132), UInt64(164),
            Float(3.14), Double(2.718)
        ]
        
        var numericResults: [[String: String]] = []
        
        for numericValue in numericTypes {
            do {
                let valueValue = try ValueHandler.ValueValue(from: numericValue)
                let backConverted = valueValue.toAny()
                
                numericResults.append([
                    "Original Type": String(describing: type(of: numericValue)),
                    "Original Value": "\(numericValue)",
                    "ValueValue": "\(valueValue)",
                    "Converted Back": "\(backConverted)",
                    "Type Preserved": "\(type(of: backConverted))"
                ])
            } catch {
                numericResults.append([
                    "Original Type": String(describing: type(of: numericValue)),
                    "Original Value": "\(numericValue)",
                    "ValueValue": "ERROR",
                    "Converted Back": "N/A",
                    "Type Preserved": "N/A"
                ])
            }
        }
        
        ExampleUtils.printDataTable(numericResults, title: "Numeric Type Conversions")
        
        // Edge cases
        print("  🎯 Edge cases testing:")
        let edgeCases: [(String, Any)] = [
            ("Empty string", ""),
            ("Zero integer", 0),
            ("Zero double", 0.0),
            ("Negative number", -42.5),
            ("Very large number", 1_000_000_000_000.0),
            ("Very small number", 0.000000001),
            ("Empty array", []),
            ("Empty dictionary", [:] as [String: Any])
        ]
        
        print("    Edge case handling:")
        for (description, edgeValue) in edgeCases {
            do {
                let valueValue = try ValueHandler.ValueValue(from: edgeValue)
                let roundTrip = valueValue.toAny()
                print("      ✅ \(description): \(valueValue) -> \(roundTrip)")
            } catch {
                print("      ❌ \(description): ERROR - \(error)")
            }
        }
    }
    
    private static func demonstrateDynamicMessageIntegration() throws {
        ExampleUtils.printStep(4, "DynamicMessage Integration")
        
        print("  🔗 DynamicMessage.valueMessage() examples:")
        
        // Различные типы значений через convenience extensions
        let testCases: [(String, Any)] = [
            ("Simple number", 42.5),
            ("Text message", "Hello from Value!"),
            ("Complex object", [
                "user": ["id": 123, "name": "Alice"],
                "settings": ["theme": "dark", "notifications": true],
                "data": [1, 2, 3, "mixed", true]
            ] as [String: Any])
        ]
        
        var integrationResults: [[String: String]] = []
        
        for (description, swiftValue) in testCases {
            do {
                // Через convenience extension
                let valueMessage = try DynamicMessage.valueMessage(from: swiftValue)
                
                // Проверка структуры сообщения
                let messageType = valueMessage.descriptor.fullName
                let hasValueData = try valueMessage.hasValue(forField: "value_data")
                
                // Извлечение через extension
                let extractedValue = try valueMessage.toAnyValue()
                
                // Валидация roundtrip
                let isRoundTripValid = validateRoundTrip(original: swiftValue, extracted: extractedValue)
                
                integrationResults.append([
                    "Test Case": description,
                    "Message Type": messageType,
                    "Has Data": hasValueData ? "✅ YES" : "❌ NO",
                    "Round-trip": isRoundTripValid ? "✅ VALID" : "❌ INVALID",
                    "Status": "✅ SUCCESS"
                ])
            } catch {
                integrationResults.append([
                    "Test Case": description,
                    "Message Type": "ERROR",
                    "Has Data": "ERROR",
                    "Round-trip": "ERROR",
                    "Status": "❌ \(error)"
                ])
            }
        }
        
        ExampleUtils.printDataTable(integrationResults, title: "DynamicMessage Integration")
        
        // Прямая работа с ValueHandler
        print("  🛠 Direct ValueHandler operations:")
        
        let complexValue = try ValueHandler.ValueValue(from: [
            "api_response": [
                "status": "success",
                "data": ["items": [1, 2, 3], "total": 3],
                "timestamp": "2023-12-15T10:30:00Z"
            ]
        ])
        
        // Создание DynamicMessage
        let message = try ValueHandler.createDynamic(from: complexValue)
        print("    Created message type: \(message.descriptor.fullName)")
        print("    Message has \(message.descriptor.fields.count) field(s)")
        
        // Извлечение значения обратно
        let extractedValue = try ValueHandler.createSpecialized(from: message) as! ValueHandler.ValueValue
        print("    Extracted value type: \(getValueTypeName(extractedValue))")
        print("    Values match: \(extractedValue == complexValue)")
        
        // Анализ содержимого
        if case .structValue(let structValue) = extractedValue {
            print("    Struct contains \(structValue.fields.count) field(s)")
            print("    Top-level keys: \(structValue.fields.keys.sorted())")
        }
    }
    
    private static func demonstrateRoundTripCompatibility() throws {
        ExampleUtils.printStep(5, "Round-Trip Compatibility Testing")
        
        print("  🔄 Comprehensive round-trip testing:")
        
        // Генерация тестовых случаев разной сложности
        let roundTripTests: [(String, ValueHandler.ValueValue)] = [
            ("Null", .nullValue),
            ("Zero", .numberValue(0.0)),
            ("Positive Integer", .numberValue(42.0)),
            ("Negative Decimal", .numberValue(-3.14159)),
            ("Empty String", .stringValue("")),
            ("Unicode String", .stringValue("Hello 🌍 World! 🚀")),
            ("True Boolean", .boolValue(true)),
            ("False Boolean", .boolValue(false)),
            ("Empty List", .listValue([])),
            ("Simple List", .listValue([.numberValue(1), .stringValue("two"), .boolValue(true)]))
        ]
        
        var roundTripResults: [[String: String]] = []
        var allPassed = true
        var totalTime: TimeInterval = 0
        
        for (testName, originalValue) in roundTripTests {
            let (passed, time) = ExampleUtils.measureTime {
                do {
                    // Round-trip: ValueValue -> DynamicMessage -> ValueValue
                    let message = try ValueHandler.createDynamic(from: originalValue)
                    let roundTripValue = try ValueHandler.createSpecialized(from: message) as! ValueHandler.ValueValue
                    return roundTripValue == originalValue
                } catch {
                    return false
                }
            }
            
            totalTime += time
            
            roundTripResults.append([
                "Test": testName,
                "Original": getValueTypeName(originalValue),
                "Result": passed ? "✅ PASS" : "❌ FAIL",
                "Time": String(format: "%.3f ms", time * 1000),
                "Status": passed ? "SUCCESS" : "FAILED"
            ])
            
            if !passed {
                allPassed = false
            }
        }
        
        ExampleUtils.printDataTable(roundTripResults, title: "Round-Trip Tests")
        
        print("  📊 Round-trip summary:")
        print("    Total tests: \(roundTripTests.count)")
        print("    Passed: \(roundTripResults.filter { $0["Result"]?.contains("PASS") == true }.count)")
        print("    Failed: \(roundTripResults.filter { $0["Result"]?.contains("FAIL") == true }.count)")
        print("    Total time: \(String(format: "%.3f ms", totalTime * 1000))")
        print("    Average time: \(String(format: "%.3f ms", (totalTime / Double(roundTripTests.count)) * 1000))")
        print("    Overall result: \(allPassed ? "✅ EXCELLENT" : "❌ NEEDS ATTENTION")")
    }
    
    private static func demonstratePerformanceAndRealWorldScenarios() throws {
        ExampleUtils.printStep(6, "Performance Analysis and Real-World Scenarios")
        
        // Performance benchmarking
        print("  🚀 Performance benchmarking:")
        
        let benchmarkValues = [
            ("Simple value", ValueHandler.ValueValue.stringValue("test")),
            ("Number value", ValueHandler.ValueValue.numberValue(42.5)),
            ("Complex struct", ValueHandler.ValueValue.structValue(try! StructHandler.StructValue(from: [
                "data": ["items": [1, 2, 3, 4, 5], "metadata": ["created": "2023-01-01"]]
            ])))
        ]
        
        var performanceResults: [[String: String]] = []
        
        for (name, value) in benchmarkValues {
            var times: [TimeInterval] = []
            let iterations = 1000
            
            // Benchmark creation + extraction
            for _ in 0..<iterations {
                let (_, time) = ExampleUtils.measureTime {
                    do {
                        let message = try ValueHandler.createDynamic(from: value)
                        let _ = try ValueHandler.createSpecialized(from: message)
                    } catch {
                        // Ignore errors for performance testing
                    }
                }
                times.append(time)
            }
            
            let avgTime = times.reduce(0, +) / Double(times.count)
            let minTime = times.min() ?? 0
            let maxTime = times.max() ?? 0
            let opsPerSecond = 1.0 / avgTime
            
            performanceResults.append([
                "Value Type": name,
                "Avg Time": String(format: "%.3f μs", avgTime * 1_000_000),
                "Min Time": String(format: "%.3f μs", minTime * 1_000_000),
                "Max Time": String(format: "%.3f μs", maxTime * 1_000_000),
                "Ops/Sec": String(format: "%.0f", opsPerSecond)
            ])
        }
        
        ExampleUtils.printDataTable(performanceResults, title: "Performance Benchmarks")
        
        print("  💡 Performance insights:")
        print("    • google.protobuf.Value подходит для универсальных динамических данных")
        print("    • Type switching эффективен для обработки разнородных данных")
        print("    • Round-trip операции быстрые и надежные")
        print("    • Подходит для real-time обработки (< 100μs для простых значений)")
        print("    • Интеграция с DynamicMessage seamless и удобная")
    }
    
    // MARK: - Helper Methods
    
    private static func analyzeValueType(_ value: ValueHandler.ValueValue) -> (type: String, details: String) {
        switch value {
        case .nullValue:
            return ("null", "Null value")
        case .numberValue(let number):
            return ("number", "Double: \(number)")
        case .stringValue(let string):
            return ("string", "Length: \(string.count) chars")
        case .boolValue(let bool):
            return ("boolean", bool ? "True" : "False")
        case .listValue(let list):
            return ("list", "Items: \(list.count)")
        case .structValue(let structValue):
            return ("struct", "Fields: \(structValue.fields.count)")
        }
    }
    
    private static func performPatternMatching(_ value: ValueHandler.ValueValue) -> String {
        switch value {
        case .nullValue:
            return "🔳 Handled null value"
        case .numberValue(let n) where n > 0:
            return "🔢 Positive number: \(n)"
        case .numberValue(let n) where n < 0:
            return "🔢 Negative number: \(n)"
        case .numberValue(let n):
            return "🔢 Zero or other: \(n)"
        case .stringValue(let s) where s.isEmpty:
            return "📝 Empty string detected"
        case .stringValue(let s) where s.count > 10:
            return "📝 Long string (\(s.count) chars)"
        case .stringValue(let s):
            return "📝 Short string: '\(s)'"
        case .boolValue(true):
            return "✅ Boolean true"
        case .boolValue(false):
            return "❌ Boolean false"
        case .listValue(let list) where list.isEmpty:
            return "📋 Empty list"
        case .listValue(let list):
            return "📋 List with \(list.count) items"
        case .structValue(let structValue):
            return "🏗 Struct with \(structValue.fields.count) fields"
        }
    }
    
    private static func processValuesBatch(_ values: [ValueHandler.ValueValue]) -> [String] {
        return values.compactMap { value in
            switch value {
            case .numberValue(let n) where n > 50:
                return "High number: \(n)"
            case .stringValue(let s) where s.contains("process"):
                return "Processed string: \(s)"
            case .boolValue(true):
                return "Confirmed: true"
            case .listValue(let list) where list.count >= 2:
                return "List processed: \(list.count) items"
            default:
                return nil // Skip other values
            }
        }
    }
    
    private static func convertToJSON(_ value: ValueHandler.ValueValue) throws -> String {
        let anyValue = value.toAny()
        
        // NSJSONSerialization требует top-level объект должен быть Array или Dictionary
        // Для примитивных типов оборачиваем в массив
        let jsonObject: Any
        if anyValue is NSNull || anyValue is String || anyValue is NSNumber || anyValue is Bool {
            jsonObject = [anyValue]
        } else {
            jsonObject = anyValue
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        let jsonString = String(data: jsonData, encoding: .utf8) ?? "Invalid JSON"
        
        // Для примитивов убираем обёртку массива
        if anyValue is NSNull || anyValue is String || anyValue is NSNumber || anyValue is Bool {
            let trimmed = jsonString.dropFirst().dropLast() // Убираем [ и ]
            return String(trimmed)
        } else {
            return jsonString
        }
    }
    
    private static func validateRoundTrip(original: Any, extracted: Any) -> Bool {
        // Simplified validation - in real world this would be more sophisticated
        return String(describing: original) == String(describing: extracted)
    }
    
    private static func getValueTypeName(_ value: ValueHandler.ValueValue) -> String {
        switch value {
        case .nullValue: return "null"
        case .numberValue: return "number"
        case .stringValue: return "string"
        case .boolValue: return "boolean"
        case .listValue: return "list"
        case .structValue: return "struct"
        }
    }
}
