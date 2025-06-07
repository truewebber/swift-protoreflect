# SwiftProtoReflect Examples - Технические детали

Данный документ дополняет основной план (`EXAMPLES_PLAN.md`) техническими деталями реализации.

## 🔧 Технические детали реализации

### Структура примера (Template)

Каждый Swift скрипт должен следовать унифицированной структуре:

```swift
#!/usr/bin/env swift

/**
 * 🚀 SwiftProtoReflect Example: [Название примера]
 * 
 * Описание: [Краткое описание что делает пример]
 * Ключевые концепции: [Список основных концепций]
 * Сложность: [🔰 Начальный / 🔧 Средний / 🚀 Продвинутый / 🏢 Expert]
 * Время выполнения: [Примерное время выполнения]
 * 
 * Что изучите:
 * - [Концепция 1]
 * - [Концепция 2]
 * - [Концепция 3]
 * 
 * Запуск: 
 *   make run-[category]
 *   ./[filename].swift  
 *   swift -I ../.build/release -L ../.build/release -lSwiftProtoReflect [filename].swift
 */

import Foundation
import SwiftProtoReflect

@main 
struct [ExampleName]Example {
    static func main() throws {
        printHeader("[Заголовок примера]")
        
        try step1_[Описание]()
        try step2_[Описание]()
        try step3_[Описание]()
        
        printSuccess("Пример успешно завершен!")
        printNext([
            "Следующий пример: [название].swift",
            "Изучите также: [название].swift"
        ])
    }
    
    // MARK: - Implementation Steps
    
    private static func step1_[Описание]() throws {
        printStep(1, "[Описание шага]")
        
        // Реализация шага с комментариями
        
        print("  ✅ [Результат шага]")
    }
    
    // Другие шаги...
}

// MARK: - Shared utilities (moved to shared/example-base.swift in real implementation)
```

### Shared утилиты (shared/example-base.swift)

```swift
// shared/example-base.swift
import Foundation

/// Базовые утилиты для всех примеров SwiftProtoReflect
public enum ExampleUtils {
    
    // MARK: - Console Output
    
    public static func printHeader(_ title: String) {
        let separator = String(repeating: "=", count: min(title.count + 4, 60))
        print("\n\(separator)")
        print("  \(title)")
        print("\(separator)\n")
    }
    
    public static func printStep(_ number: Int, _ description: String) {
        print("\n📝 Шаг \(number): \(description)")
        print(String(repeating: "-", count: min(description.count + 10, 50)))
    }
    
    public static func printSuccess(_ message: String) {
        print("\n🎉 \(message)")
    }
    
    public static func printError(_ message: String) {
        print("\n❌ Ошибка: \(message)")
    }
    
    public static func printWarning(_ message: String) {
        print("\n⚠️  Предупреждение: \(message)")
    }
    
    public static func printInfo(_ message: String) {
        print("\n💡 \(message)")
    }
    
    public static func printNext(_ suggestions: [String]) {
        print("\n🔍 Что попробовать дальше:")
        for suggestion in suggestions {
            print("  • \(suggestion)")
        }
        print()
    }
    
    // MARK: - Performance Timing
    
    public static func measureTime<T>(_ operation: () throws -> T) rethrows -> (result: T, time: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return (result, timeElapsed)
    }
    
    public static func printTiming(_ description: String, time: TimeInterval) {
        let timeString = String(format: "%.3f", time * 1000) // Convert to milliseconds
        print("  ⏱  \(description): \(timeString)ms")
    }
    
    // MARK: - Data Helpers
    
    public static func generateRandomString(length: Int = 10) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    public static func generateTestPersonData() -> [String: Any] {
        return [
            "name": generateRandomString(length: 8),
            "age": Int32.random(in: 18...80),
            "email": "\(generateRandomString(length: 6))@example.com"
        ]
    }
    
    // MARK: - File Helpers
    
    public static func readResourceFile(_ filename: String) -> String? {
        let resourcePath = "../resources/data/\(filename)"
        return try? String(contentsOfFile: resourcePath, encoding: .utf8)
    }
    
    public static func writeToFile(_ content: String, filename: String) {
        let outputPath = "/tmp/\(filename)"
        try? content.write(toFile: outputPath, atomically: true, encoding: .utf8)
        print("  📄 Файл записан: \(outputPath)")
    }
}

// MARK: - Protocol Extensions

extension DynamicMessage {
    /// Convenience method для красивого вывода сообщения
    func prettyPrint() {
        print("  📋 \(descriptor.name):")
        for field in descriptor.fields {
            if hasValue(field.name) {
                let value = try? get(field.name)
                print("    \(field.name): \(value ?? "nil")")
            }
        }
    }
}
```

### Logger утилиты (shared/logger.swift)

```swift
// shared/logger.swift
import Foundation

public enum LogLevel: Int, CaseIterable {
    case debug = 0
    case info = 1 
    case warning = 2
    case error = 3
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "💡" 
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
    
    var color: String {
        switch self {
        case .debug: return "\u{001B}[0;37m"    // White
        case .info: return "\u{001B}[0;36m"     // Cyan
        case .warning: return "\u{001B}[0;33m"  // Yellow  
        case .error: return "\u{001B}[0;31m"    // Red
        }
    }
}

public class ExampleLogger {
    private static let resetColor = "\u{001B}[0;0m"
    private static var currentLevel: LogLevel = .info
    
    public static func setLevel(_ level: LogLevel) {
        currentLevel = level
    }
    
    public static func debug(_ message: String, file: String = #file, line: Int = #line) {
        log(.debug, message, file: file, line: line)
    }
    
    public static func info(_ message: String, file: String = #file, line: Int = #line) {
        log(.info, message, file: file, line: line)
    }
    
    public static func warning(_ message: String, file: String = #file, line: Int = #line) {
        log(.warning, message, file: file, line: line)
    }
    
    public static func error(_ message: String, file: String = #file, line: Int = #line) {
        log(.error, message, file: file, line: line)
    }
    
    private static func log(_ level: LogLevel, _ message: String, file: String, line: Int) {
        guard level.rawValue >= currentLevel.rawValue else { return }
        
        let filename = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        
        print("\(level.color)[\(timestamp)] \(level.emoji) \(message) (\(filename):\(line))\(resetColor)")
    }
}

private extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
```

### Performance Timer (shared/performance-timer.swift)

```swift
// shared/performance-timer.swift  
import Foundation

public class PerformanceTimer {
    private var startTime: CFAbsoluteTime = 0
    private var measurements: [String: TimeInterval] = [:]
    
    public init() {}
    
    public func start() {
        startTime = CFAbsoluteTimeGetCurrent()
    }
    
    public func measure<T>(_ label: String, operation: () throws -> T) rethrows -> T {
        let operationStart = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let elapsed = CFAbsoluteTimeGetCurrent() - operationStart
        measurements[label] = elapsed
        return result
    }
    
    public func printResults() {
        guard !measurements.isEmpty else {
            print("  📊 No measurements recorded")
            return
        }
        
        print("\n  📊 Performance Results:")
        print("  " + String(repeating: "-", count: 40))
        
        let sortedMeasurements = measurements.sorted { $0.value > $1.value }
        
        for (label, time) in sortedMeasurements {
            let timeMs = time * 1000
            let timeString = String(format: "%.3f ms", timeMs)
            print("    \(label): \(timeString)")
        }
        
        let totalTime = measurements.values.reduce(0, +)
        let totalTimeString = String(format: "%.3f ms", totalTime * 1000)
        print("  " + String(repeating: "-", count: 40))
        print("    Total: \(totalTimeString)")
    }
    
    public func reset() {
        measurements.removeAll()
        startTime = 0
    }
}
```

## 📄 Proto файлы для примеров

### resources/proto/basic.proto

```protobuf
syntax = "proto3";

package example.basic;

// Базовое сообщение для начальных примеров
message Person {
  string name = 1;
  int32 age = 2;
  string email = 3;
  repeated string hobbies = 4;
  
  enum Gender {
    UNKNOWN = 0;
    MALE = 1;
    FEMALE = 2;
  }
  
  Gender gender = 5;
}

// Сообщение с различными типами полей
message AllFieldTypes {
  // Скалярные типы
  double double_field = 1;
  float float_field = 2;
  int32 int32_field = 3;
  int64 int64_field = 4;
  uint32 uint32_field = 5;
  uint64 uint64_field = 6;
  sint32 sint32_field = 7;
  sint64 sint64_field = 8;
  fixed32 fixed32_field = 9;
  fixed64 fixed64_field = 10;
  sfixed32 sfixed32_field = 11;
  sfixed64 sfixed64_field = 12;
  bool bool_field = 13;
  string string_field = 14;
  bytes bytes_field = 15;
  
  // Repeated поля
  repeated int32 repeated_int32 = 16;
  repeated string repeated_string = 17;
  
  // Map поля
  map<string, int32> map_string_int32 = 18;
  map<int32, string> map_int32_string = 19;
}
```

### resources/proto/company.proto

```protobuf
syntax = "proto3";

package example.company;

import "basic.proto";
import "google/protobuf/timestamp.proto";
import "google/protobuf/duration.proto";

// Сложная структура для продвинутых примеров
message Company {
  string name = 1;
  repeated Department departments = 2;
  Address headquarters = 3;
  google.protobuf.Timestamp founded_date = 4;
  CompanyType type = 5;
  
  message Address {
    string street = 1;
    string city = 2; 
    string country = 3;
    string postal_code = 4;
  }
  
  enum CompanyType {
    UNKNOWN = 0;
    STARTUP = 1;
    CORPORATION = 2;
    NON_PROFIT = 3;
  }
}

message Department {
  string name = 1;
  repeated example.basic.Person employees = 2;
  Department parent_department = 3;
  repeated Department sub_departments = 4;
  google.protobuf.Duration avg_project_duration = 5;
}

message Project {
  string name = 1;
  repeated example.basic.Person team_members = 2;
  google.protobuf.Timestamp start_date = 3;
  google.protobuf.Timestamp end_date = 4;
  ProjectStatus status = 5;
  
  enum ProjectStatus {
    PLANNING = 0;
    IN_PROGRESS = 1;
    COMPLETED = 2;
    CANCELLED = 3;
  }
}
```

### resources/proto/service.proto

```protobuf
syntax = "proto3";

package example.service;

import "basic.proto";
import "company.proto";
import "google/protobuf/empty.proto";

// gRPC сервис для примеров
service PersonService {
  rpc GetPerson(GetPersonRequest) returns (example.basic.Person);
  rpc CreatePerson(CreatePersonRequest) returns (example.basic.Person);
  rpc UpdatePerson(UpdatePersonRequest) returns (example.basic.Person);
  rpc DeletePerson(DeletePersonRequest) returns (google.protobuf.Empty);
  rpc ListPersons(ListPersonsRequest) returns (ListPersonsResponse);
}

message GetPersonRequest {
  string person_id = 1;
}

message CreatePersonRequest {
  example.basic.Person person = 1;
}

message UpdatePersonRequest {
  string person_id = 1;
  example.basic.Person person = 2;
}

message DeletePersonRequest {
  string person_id = 1;
}

message ListPersonsRequest {
  int32 page_size = 1;
  string page_token = 2;
  string filter = 3;
}

message ListPersonsResponse {
  repeated example.basic.Person persons = 1;
  string next_page_token = 2;
  int32 total_count = 3;
}

service CompanyService {
  rpc GetCompany(GetCompanyRequest) returns (example.company.Company);
  rpc CreateDepartment(CreateDepartmentRequest) returns (example.company.Department);
}

message GetCompanyRequest {
  string company_id = 1;
}

message CreateDepartmentRequest {
  string company_id = 1;
  example.company.Department department = 2;
}
```

## 🧪 Тестовые данные

### resources/data/sample-messages.json

```json
{
  "persons": [
    {
      "name": "John Doe",
      "age": 30,
      "email": "john.doe@example.com",
      "hobbies": ["reading", "swimming", "coding"],
      "gender": "MALE"
    },
    {
      "name": "Jane Smith", 
      "age": 25,
      "email": "jane.smith@example.com",
      "hobbies": ["painting", "yoga", "traveling"],
      "gender": "FEMALE"
    }
  ],
  "companies": [
    {
      "name": "TechCorp Inc.",
      "type": "CORPORATION",
      "headquarters": {
        "street": "123 Tech Street",
        "city": "San Francisco",
        "country": "USA",
        "postal_code": "94102"
      },
      "founded_date": "2010-01-15T09:30:00Z"
    }
  ]
}
```

## 🎯 Конкретные примеры реализации

### 03-serialization/binary-format.swift

```swift
#!/usr/bin/env swift

/**
 * 💾 SwiftProtoReflect Example: Binary Format Serialization
 * 
 * Описание: Демонстрация binary Protocol Buffers сериализации и десериализации
 * Ключевые концепции: BinarySerializer, BinaryDeserializer, Wire Format
 * Сложность: 🔧 Средний
 * Время выполнения: < 10 секунд
 */

import Foundation
import SwiftProtoReflect

@main
struct BinaryFormatExample {
    static func main() throws {
        printHeader("Binary Protocol Buffers Serialization")
        
        // Создание тестового сообщения
        let (message, _) = try measureTime {
            try createTestMessage()
        }
        printTiming("Message creation", time: _)
        
        // Binary сериализация
        let (binaryData, serializeTime) = try measureTime {
            let serializer = BinarySerializer()
            return try serializer.serialize(message)
        }
        printTiming("Binary serialization", time: serializeTime)
        
        print("  📦 Binary size: \(binaryData.count) bytes")
        print("  🔢 Hex preview: \(binaryData.prefix(20).map { String(format: "%02x", $0) }.joined(separator: " "))")
        
        // Binary десериализация  
        let (deserializedMessage, deserializeTime) = try measureTime {
            let deserializer = BinaryDeserializer()
            return try deserializer.deserialize(binaryData, using: message.descriptor)
        }
        printTiming("Binary deserialization", time: deserializeTime)
        
        // Проверка round-trip совместимости
        try verifyRoundTrip(original: message, deserialized: deserializedMessage)
        
        printSuccess("Binary serialization example completed!")
    }
    
    private static func createTestMessage() throws -> DynamicMessage {
        // Implementation...
        return DynamicMessage(descriptor: /* descriptor */)
    }
    
    private static func verifyRoundTrip(original: DynamicMessage, deserialized: DynamicMessage) throws {
        printStep(4, "Verifying round-trip compatibility")
        
        for field in original.descriptor.fields {
            let originalValue = try original.get(field.name)
            let deserializedValue = try deserialized.get(field.name)
            
            // Сравнение значений с учетом типов
            // Implementation...
        }
        
        print("  ✅ Round-trip verification passed")
    }
}
```

### 05-well-known-types/timestamp-demo.swift

```swift
#!/usr/bin/env swift

/**
 * ⏰ SwiftProtoReflect Example: Timestamp Demo
 * 
 * Описание: Работа с google.protobuf.Timestamp и конвертация с Foundation.Date
 * Ключевые концепции: TimestampHandler, WellKnownTypes, Date conversion
 * Сложность: 🔧 Средний
 */

import Foundation
import SwiftProtoReflect

@main
struct TimestampDemo {
    static func main() throws {
        printHeader("Google Protobuf Timestamp Integration")
        
        try demonstrateBasicUsage()
        try demonstrateAdvancedOperations()
        try demonstrateEdgeCases()
        
        printSuccess("Timestamp demo completed!")
    }
    
    private static func demonstrateBasicUsage() throws {
        printStep(1, "Basic Timestamp Operations")
        
        // Создание из текущей даты
        let now = Date()
        let timestampValue = TimestampHandler.TimestampValue(from: now)
        let timestampMessage = try TimestampHandler.createDynamic(from: timestampValue)
        
        print("  📅 Current date: \(now)")
        print("  ⏰ Timestamp seconds: \(timestampValue.seconds)")
        print("  🔢 Timestamp nanos: \(timestampValue.nanos)")
        
        // Конвертация обратно
        let extractedValue = try TimestampHandler.extractValue(from: timestampMessage)
        let reconstructedDate = extractedValue.toDate()
        
        print("  🔄 Reconstructed date: \(reconstructedDate)")
        print("  ✅ Dates match: \(abs(now.timeIntervalSince(reconstructedDate)) < 0.001)")
    }
    
    private static func demonstrateAdvancedOperations() throws {
        printStep(2, "Advanced Operations")
        
        // Работа с различными временными форматами
        let timestamps = [
            ("Unix epoch", Date(timeIntervalSince1970: 0)),
            ("Y2K", Date(timeIntervalSince1970: 946684800)),
            ("Future date", Date(timeIntervalSince1970: 2147483647)),
            ("Recent past", Date().addingTimeInterval(-86400 * 30)) // 30 days ago
        ]
        
        for (label, date) in timestamps {
            let timestampValue = TimestampHandler.TimestampValue(from: date)
            print("  📅 \(label): \(date)")
            print("    ⏰ Seconds: \(timestampValue.seconds), Nanos: \(timestampValue.nanos)")
        }
    }
    
    private static func demonstrateEdgeCases() throws {
        printStep(3, "Edge Cases and Validation")
        
        // Тестирование границ
        let extremeDates = [
            Date(timeIntervalSince1970: 0.0001),           // Very small
            Date(timeIntervalSince1970: 999999999),        // Large valid
        ]
        
        for date in extremeDates {
            do {
                let timestampValue = TimestampHandler.TimestampValue(from: date)
                let message = try TimestampHandler.createDynamic(from: timestampValue)
                let extracted = try TimestampHandler.extractValue(from: message)
                
                print("  ✅ Valid: \(date) -> \(extracted.toDate())")
            } catch {
                print("  ❌ Invalid: \(date) - \(error)")
            }
        }
    }
}
```

## 🎮 Interactive Demo Script

### interactive-demo.sh

```bash
#!/bin/bash

# Interactive SwiftProtoReflect Examples Demo
# Позволяет пользователю выбрать и запустить примеры интерактивно

set -e

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Конфигурация
SWIFT_FLAGS="-I ../.build/release -L ../.build/release -lSwiftProtoReflect"

print_banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                 SwiftProtoReflect Demo                     ║"
    echo "║              Interactive Examples Explorer                 ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
}

show_categories() {
    echo -e "${YELLOW}📂 Available Categories:${NC}"
    echo ""
    echo "  1. 🔰 Basic Usage         - Learn the fundamentals"
    echo "  2. 🔧 Dynamic Messages    - Advanced message manipulation"  
    echo "  3. 💾 Serialization       - Binary and JSON formats"
    echo "  4. 🗂  Type Registry       - Centralized type management"
    echo "  5. ⭐ Well-Known Types    - Google standard types"
    echo "  6. 🌐 gRPC Integration    - Dynamic RPC calls"
    echo "  7. 🚀 Advanced Features   - Complex scenarios"
    echo "  8. 🏢 Real-World          - Production patterns"
    echo ""
    echo "  9. 🎯 Run All Examples    - Automated full demo"
    echo "  0. ❌ Exit"
    echo ""
}

show_examples_in_category() {
    local category_path="$1"
    local category_name="$2"
    
    echo -e "${YELLOW}📋 Examples in $category_name:${NC}"
    echo ""
    
    local counter=1
    for example in "$category_path"/*.swift; do
        if [ -f "$example" ]; then
            local example_name=$(basename "$example" .swift)
            local description=$(grep -m1 "Описание:" "$example" | sed 's/.*Описание: //' | sed 's/ \*//')
            echo "  $counter. $example_name"
            echo "     $description"
            echo ""
            counter=$((counter + 1))
        fi
    done
    
    echo "  0. ← Back to categories"
    echo ""
}

run_example() {
    local example_path="$1"
    local example_name=$(basename "$example_path" .swift)
    
    echo -e "${GREEN}🚀 Running: $example_name${NC}"
    echo -e "${BLUE}$(printf '═%.0s' $(seq 1 50))${NC}"
    echo ""
    
    if swift $SWIFT_FLAGS "$example_path"; then
        echo ""
        echo -e "${GREEN}✅ Example completed successfully!${NC}"
    else
        echo ""
        echo -e "${RED}❌ Example failed to run${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

select_and_run_from_category() {
    local category_path="$1" 
    local category_name="$2"
    
    while true; do
        clear
        print_banner
        show_examples_in_category "$category_path" "$category_name"
        
        echo -n "Select example to run: "
        read choice
        
        if [ "$choice" = "0" ]; then
            return
        fi
        
        # Найти example по номеру
        local counter=1
        for example in "$category_path"/*.swift; do
            if [ -f "$example" ] && [ "$counter" = "$choice" ]; then
                run_example "$example"
                break
            fi
            counter=$((counter + 1))
        done
    done
}

main_loop() {
    while true; do
        clear
        print_banner
        show_categories
        
        echo -n "Select category (1-9, 0 to exit): "
        read choice
        
        case $choice in
            1) select_and_run_from_category "01-basic-usage" "Basic Usage" ;;
            2) select_and_run_from_category "02-dynamic-messages" "Dynamic Messages" ;;
            3) select_and_run_from_category "03-serialization" "Serialization" ;;
            4) select_and_run_from_category "04-registry" "Type Registry" ;;
            5) select_and_run_from_category "05-well-known-types" "Well-Known Types" ;;
            6) select_and_run_from_category "06-grpc" "gRPC Integration" ;;
            7) select_and_run_from_category "07-advanced" "Advanced Features" ;;
            8) select_and_run_from_category "08-real-world" "Real-World Scenarios" ;;
            9) 
                echo -e "${GREEN}🏃 Running all examples...${NC}"
                ./run-all.sh
                echo -e "${YELLOW}Press Enter to continue...${NC}"
                read
                ;;
            0) 
                echo -e "${GREEN}👋 Thanks for exploring SwiftProtoReflect!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${NC}"
                sleep 1
                ;;
        esac
    done
}

# Проверка зависимостей
if [ ! -f "../Package.swift" ]; then
    echo -e "${RED}❌ Error: Please run from examples/ directory${NC}"
    exit 1
fi

# Сборка библиотеки
echo -e "${YELLOW}🔨 Building SwiftProtoReflect...${NC}"
cd .. && swift build -c release && cd examples

# Запуск интерактивного режима
main_loop
```

---

Эти технические детали дополняют основной план и предоставляют:

1. ✅ **Шаблоны кода** для единообразия примеров
2. ✅ **Shared утилиты** для переиспользования логики  
3. ✅ **Proto файлы** для тестирования
4. ✅ **Интерактивный demo** для удобства исследования
5. ✅ **Конкретные примеры** реализации
6. ✅ **Performance утилиты** для измерений

Теперь у нас есть полный plan для создания comprehensive набора примеров SwiftProtoReflect! 🚀
