import Foundation

/// Базовые утилиты для всех примеров SwiftProtoReflect
/// Предоставляет унифицированный интерфейс для вывода, измерения производительности и работы с данными
public enum ExampleUtils {
    
    // MARK: - Console Output with Colors
    
    /// Печатает красивый заголовок для примера
    public static func printHeader(_ title: String) {
        let maxWidth = 70
        let titleWidth = min(title.count, maxWidth - 4)
        let separator = String(repeating: "═", count: titleWidth + 4)
        
        print("\n\u{001B}[34m\(separator)\u{001B}[0m")
        print("\u{001B}[34m  \u{001B}[1;37m\(title)\u{001B}[0m\u{001B}[34m  \u{001B}[0m")
        print("\u{001B}[34m\(separator)\u{001B}[0m\n")
    }
    
    /// Печатает номерованный шаг выполнения
    public static func printStep(_ number: Int, _ description: String) {
        print("\n\u{001B}[33m📝 Шаг \(number): \(description)\u{001B}[0m")
        let underline = String(repeating: "─", count: min(description.count + 10, 50))
        print("\u{001B}[36m\(underline)\u{001B}[0m")
    }
    
    /// Печатает сообщение об успехе
    public static func printSuccess(_ message: String) {
        print("\n\u{001B}[32m🎉 \(message)\u{001B}[0m")
    }
    
    /// Печатает сообщение об ошибке
    public static func printError(_ message: String) {
        print("\n\u{001B}[31m❌ Ошибка: \(message)\u{001B}[0m")
    }
    
    /// Печатает предупреждение
    public static func printWarning(_ message: String) {
        print("\n\u{001B}[33m⚠️  Предупреждение: \(message)\u{001B}[0m")
    }
    
    /// Печатает информационное сообщение
    public static func printInfo(_ message: String) {
        print("\n\u{001B}[36m💡 \(message)\u{001B}[0m")
    }
    
    /// Печатает список предложений что делать дальше
    public static func printNext(_ suggestions: [String]) {
        print("\n\u{001B}[36m🔍 Что попробовать дальше:\u{001B}[0m")
        for suggestion in suggestions {
            print("\u{001B}[37m  • \(suggestion)\u{001B}[0m")
        }
        print()
    }
    
    /// Печатает разделитель
    public static func printSeparator() {
        print("\u{001B}[34m" + String(repeating: "─", count: 50) + "\u{001B}[0m")
    }
    
    // MARK: - Performance Measurement
    
    /// Измеряет время выполнения операции и возвращает результат с временем
    public static func measureTime<T>(_ operation: () throws -> T) rethrows -> (result: T, time: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return (result, timeElapsed)
    }
    
    /// Печатает информацию о времени выполнения
    public static func printTiming(_ description: String, time: TimeInterval) {
        let timeString: String
        if time < 0.001 {
            timeString = String(format: "%.1f μs", time * 1_000_000)
        } else if time < 1.0 {
            timeString = String(format: "%.3f ms", time * 1000)
        } else {
            timeString = String(format: "%.3f s", time)
        }
        print("  \u{001B}[35m⏱  \(description): \(timeString)\u{001B}[0m")
    }
    
    // MARK: - Data Generation Helpers
    
    /// Генерирует случайную строку заданной длины
    public static func generateRandomString(length: Int = 10) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    /// Генерирует тестовые данные для Person сообщения
    public static func generateTestPersonData() -> [String: Any] {
        let names = ["Alice", "Bob", "Charlie", "Diana", "Eve", "Frank", "Grace", "Henry"]
        let domains = ["example.com", "test.org", "demo.net", "sample.io"]
        let hobbies = ["reading", "swimming", "coding", "painting", "music", "traveling", "cooking", "sports"]
        
        let name = names.randomElement()!
        let age = Int32.random(in: 18...80)
        let email = "\(name.lowercased())@\(domains.randomElement()!)"
        let selectedHobbies = Array(hobbies.shuffled().prefix(Int.random(in: 1...3)))
        
        return [
            "name": name,
            "age": age,
            "email": email,
            "hobbies": selectedHobbies
        ]
    }
    
    /// Генерирует тестовые данные для Company сообщения
    public static func generateTestCompanyData() -> [String: Any] {
        let companies = ["TechCorp", "DataSys", "CloudWorks", "DevLabs", "CodeForge"]
        let cities = ["San Francisco", "New York", "London", "Tokyo", "Berlin"]
        let countries = ["USA", "USA", "UK", "Japan", "Germany"]
        
        let companyName = companies.randomElement()!
        let cityIndex = Int.random(in: 0..<cities.count)
        
        return [
            "name": companyName,
            "headquarters": [
                "street": "\(Int.random(in: 1...999)) \(companyName) Street",
                "city": cities[cityIndex],
                "country": countries[cityIndex],
                "postal_code": String(format: "%05d", Int.random(in: 10000...99999))
            ],
            "type": ["STARTUP", "CORPORATION", "NON_PROFIT"].randomElement()!
        ]
    }
    
    // MARK: - File Helpers
    
    /// Читает файл из папки resources/data/
    public static func readResourceFile(_ filename: String) -> String? {
        let resourcePath = "resources/data/\(filename)"
        return try? String(contentsOfFile: resourcePath, encoding: .utf8)
    }
    
    /// Записывает содержимое во временный файл
    public static func writeToTempFile(_ content: String, filename: String) -> String? {
        let tempDir = NSTemporaryDirectory()
        let outputPath = "\(tempDir)\(filename)"
        
        do {
            try content.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print("  \u{001B}[36m📄 Файл записан: \(outputPath)\u{001B}[0m")
            return outputPath
        } catch {
            printError("Не удалось записать файл: \(error)")
            return nil
        }
    }
    
    // MARK: - Formatting Helpers
    
    /// Форматирует размер данных в человекочитаемом виде
    public static func formatDataSize(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) bytes"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        }
    }
    
    /// Форматирует Data как hex строку для предварительного просмотра
    public static func formatDataPreview(_ data: Data, maxBytes: Int = 20) -> String {
        let bytesToShow = min(data.count, maxBytes)
        let hexString = data.prefix(bytesToShow).map { String(format: "%02x", $0) }.joined(separator: " ")
        
        if data.count > maxBytes {
            return "\(hexString)..."
        } else {
            return hexString
        }
    }
    
    /// Создает таблицу из данных key-value
    public static func printTable<T>(_ data: [String: T], title: String? = nil) {
        if let title = title {
            print("\n\u{001B}[37m📋 \(title):\u{001B}[0m")
        } else {
            print("\n\u{001B}[37m📋 Data:\u{001B}[0m")
        }
        
        let maxKeyLength = data.keys.map { $0.count }.max() ?? 0
        
        for (key, value) in data.sorted(by: { $0.key < $1.key }) {
            let paddedKey = key.padding(toLength: maxKeyLength, withPad: " ", startingAt: 0)
            print("  \u{001B}[36m\(paddedKey)\u{001B}[0m: \(value)")
        }
    }
    
    /// Создает таблицу из массива словарей (для табличных данных)
    public static func printDataTable(_ data: [[String: String]], title: String? = nil) {
        guard !data.isEmpty else {
            if let title = title {
                print("\n\u{001B}[37m📋 \(title): (empty)\u{001B}[0m")
            }
            return
        }
        
        if let title = title {
            print("\n\u{001B}[37m📋 \(title):\u{001B}[0m")
        }
        
        // Найти все уникальные ключи и их максимальные длины
        let allKeys = Set(data.flatMap { $0.keys })
        let sortedKeys = allKeys.sorted()
        
        var columnWidths: [String: Int] = [:]
        for key in sortedKeys {
            let maxValueLength = data.compactMap { $0[key]?.count }.max() ?? 0
            columnWidths[key] = max(key.count, maxValueLength, 5) // минимум 5 символов
        }
        
        // Печать заголовка
        let headerLine = sortedKeys.map { key in
            key.padding(toLength: columnWidths[key]!, withPad: " ", startingAt: 0)
        }.joined(separator: " │ ")
        print("  \u{001B}[1;36m\(headerLine)\u{001B}[0m")
        
        // Печать разделителя
        let separatorLine = sortedKeys.map { key in
            String(repeating: "─", count: columnWidths[key]!)
        }.joined(separator: "─┼─")
        print("  \u{001B}[36m\(separatorLine)\u{001B}[0m")
        
        // Печать данных
        for row in data {
            let dataLine = sortedKeys.map { key in
                let value = row[key] ?? ""
                return value.padding(toLength: columnWidths[key]!, withPad: " ", startingAt: 0)
            }.joined(separator: " │ ")
            print("  \(dataLine)")
        }
    }
    
    // MARK: - Validation Helpers
    
    /// Проверяет равенство двух значений с подробным выводом
    public static func assertEqual<T: Equatable>(_ actual: T, _ expected: T, description: String) -> Bool {
        if actual == expected {
            print("  \u{001B}[32m✅ \(description): OK\u{001B}[0m")
            return true
        } else {
            print("  \u{001B}[31m❌ \(description): Expected \(expected), got \(actual)\u{001B}[0m")
            return false
        }
    }
    
    /// Проверяет что значение не nil
    public static func assertNotNil<T>(_ value: T?, description: String) -> Bool {
        if value != nil {
            print("  \u{001B}[32m✅ \(description): Not nil\u{001B}[0m")
            return true
        } else {
            print("  \u{001B}[31m❌ \(description): Unexpected nil\u{001B}[0m")
            return false
        }
    }
    
    // MARK: - Interactive Helpers
    
    /// Ожидает нажатия Enter от пользователя
    public static func waitForEnter(message: String = "Нажмите Enter для продолжения...") {
        print("\n\u{001B}[33m\(message)\u{001B}[0m")
        _ = readLine()
    }
    
    /// Задает вопрос пользователю с вариантами ответов
    public static func askUser(_ question: String, options: [String] = ["y", "n"]) -> String? {
        let optionsStr = options.joined(separator: "/")
        print("\n\u{001B}[33m❓ \(question) (\(optionsStr)): \u{001B}[0m", terminator: "")
        
        if let input = readLine()?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) {
            return options.contains(input) ? input : options.first
        }
        return options.first
    }
}

// MARK: - DynamicMessage Extensions

import SwiftProtoReflect

extension DynamicMessage {
    /// Печатает содержимое сообщения в удобочитаемом формате
    public func prettyPrint() {
        print("    \u{001B}[37m📋 \(descriptor.name):\u{001B}[0m")
        
        let fieldsWithValues = descriptor.fields.values.filter { field in
            do {
                return try hasValue(forField: field.name)
            } catch {
                return false
            }
        }
        
        if fieldsWithValues.isEmpty {
            print("      \u{001B}[90m(no fields set)\u{001B}[0m")
            return
        }
        
        for field in fieldsWithValues {
            do {
                let value = try get(forField: field.name)
                let displayValue = formatFieldValue(value, fieldType: field.type)
                print("      \u{001B}[36m\(field.name)\u{001B}[0m: \(displayValue)")
            } catch {
                print("      \u{001B}[36m\(field.name)\u{001B}[0m: \u{001B}[31m<error: \(error)>\u{001B}[0m")
            }
        }
    }
    
    /// Форматирует значение поля для красивого отображения
    private func formatFieldValue(_ value: Any?, fieldType: FieldType) -> String {
        guard let value = value else { return "\u{001B}[90mnil\u{001B}[0m" }
        
        switch value {
        case let string as String:
            return "\"\(string)\""
        case let data as Data:
            return "Data(\(data.count) bytes)"
        case let array as [Any]:
            if array.isEmpty {
                return "[]"
            } else if array.count <= 3 {
                let formatted = array.map { formatArrayElement($0) }.joined(separator: ", ")
                return "[\(formatted)]"
            } else {
                let firstThree = array.prefix(3).map { formatArrayElement($0) }.joined(separator: ", ")
                return "[\(firstThree), ... (\(array.count) items)]"
            }
        case let message as DynamicMessage:
            return "\(message.descriptor.name) {...}"
        default:
            return "\(value)"
        }
    }
    
    /// Форматирует элемент массива
    private func formatArrayElement(_ element: Any) -> String {
        switch element {
        case let string as String:
            return "\"\(string)\""
        case let message as DynamicMessage:
            return message.descriptor.name
        default:
            return "\(element)"
        }
    }
}
