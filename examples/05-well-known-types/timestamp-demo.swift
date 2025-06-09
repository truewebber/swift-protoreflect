/**
 * ⏰ SwiftProtoReflect Example: Timestamp Demo
 *
 * Описание: Работа с google.protobuf.Timestamp и конвертация с Foundation.Date
 * Ключевые концепции: TimestampHandler, WellKnownTypes, Date conversion
 * Сложность: 🔧 Средний
 * Время выполнения: < 10 секунд
 *
 * Что изучите:
 * - Создание и конвертация google.protobuf.Timestamp
 * - Интеграция с Foundation.Date
 * - Временные метки с наносекундной точностью
 * - Валидация временных диапазонов
 * - Round-trip совместимость
 *
 * Запуск:
 *   swift run TimestampDemo
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct TimestampDemo {
  static func main() throws {
    ExampleUtils.printHeader("Google Protobuf Timestamp Integration")

    try demonstrateBasicUsage()
    try demonstrateAdvancedOperations()
    try demonstrateRoundTripCompatibility()
    try demonstrateEdgeCases()
    try demonstratePerformanceAndPrecision()

    ExampleUtils.printSuccess("Timestamp demo завершена! Вы изучили все аспекты работы с google.protobuf.Timestamp.")

    ExampleUtils.printNext([
      "Далее изучите: duration-demo.swift - временные интервалы",
      "Сравните: empty-demo.swift - пустые сообщения",
      "Продвинутое: field-mask-demo.swift - маски полей для updates",
    ])
  }

  // MARK: - Implementation Steps

  private static func demonstrateBasicUsage() throws {
    ExampleUtils.printStep(1, "Basic Timestamp Operations")

    // Создание из текущей даты
    let now = Date()
    let timestampValue = TimestampHandler.TimestampValue(from: now)
    let timestampMessage = try TimestampHandler.createDynamic(from: timestampValue)

    print("  📅 Current date: \(now)")
    print("  ⏰ Timestamp seconds: \(timestampValue.seconds)")
    print("  🔢 Timestamp nanos: \(timestampValue.nanos)")

    // Конвертация обратно
    let extractedValue =
      try TimestampHandler.createSpecialized(from: timestampMessage) as! TimestampHandler.TimestampValue
    let reconstructedDate = extractedValue.toDate()

    print("  🔄 Reconstructed date: \(reconstructedDate)")

    let timeDifference = abs(now.timeIntervalSince(reconstructedDate))
    print("  ✅ Precision (time difference): \(String(format: "%.6f", timeDifference)) seconds")
    print("  ✅ High precision match: \(timeDifference < 0.001 ? "YES" : "NO")")

    // Проверка структуры сообщения
    print("  📋 Message structure:")
    print("    Message type: \(timestampMessage.descriptor.name)")
    print("    Fields count: \(timestampMessage.descriptor.fields.count)")
    for field in timestampMessage.descriptor.fields.values {
      let value = try? timestampMessage.get(forField: field.name)
      print("    \(field.name): \(value ?? "nil")")
    }
  }

  private static func demonstrateAdvancedOperations() throws {
    ExampleUtils.printStep(2, "Advanced Timestamp Operations")

    // Работа с различными временными форматами
    let significantTimestamps = [
      ("Unix epoch", Date(timeIntervalSince1970: 0)),
      ("Y2K moment", Date(timeIntervalSince1970: 946_684_800)),
      ("Swift announcement", Date(timeIntervalSince1970: 1_401_843_600)),  // WWDC 2014
      ("Recent past", Date().addingTimeInterval(-86400 * 30)),  // 30 days ago
      ("Near future", Date().addingTimeInterval(86400 * 7)),  // 1 week from now
    ]

    ExampleUtils.printDataTable(
      significantTimestamps.map { (label, date) in
        let timestampValue = TimestampHandler.TimestampValue(from: date)
        return [
          "Event": label,
          "Date": DateFormatter.iso8601.string(from: date),
          "Seconds": "\(timestampValue.seconds)",
          "Nanos": "\(timestampValue.nanos)",
        ]
      },
      title: "Historical Timestamps"
    )

    // Демонстрация точности
    print("  🎯 Precision demonstration:")
    let preciseTime = Date()
    let nanoTimestamp = TimestampHandler.TimestampValue(from: preciseTime)
    let nanoMessage = try TimestampHandler.createDynamic(from: nanoTimestamp)
    let nanoExtracted = try TimestampHandler.createSpecialized(from: nanoMessage) as! TimestampHandler.TimestampValue
    let nanoReconstructed = nanoExtracted.toDate()

    let precisionLoss = abs(preciseTime.timeIntervalSince(nanoReconstructed))
    print(
      "    Original microseconds: \(String(format: "%.6f", preciseTime.timeIntervalSince1970.truncatingRemainder(dividingBy: 1)))"
    )
    print(
      "    Reconstructed microseconds: \(String(format: "%.6f", nanoReconstructed.timeIntervalSince1970.truncatingRemainder(dividingBy: 1)))"
    )
    print("    Precision loss: \(String(format: "%.9f", precisionLoss)) seconds")
  }

  private static func demonstrateRoundTripCompatibility() throws {
    ExampleUtils.printStep(3, "Round-Trip Compatibility Testing")

    // Тестирование различных временных значений
    let testDates = [
      Date(timeIntervalSince1970: 0.123456789),  // Microsecond precision
      Date(timeIntervalSince1970: 1234567890.987654321),  // Large timestamp
      Date().addingTimeInterval(0.000000001),  // Nanosecond difference
      Date(timeIntervalSince1970: -1_234_567_890),  // Before epoch
    ]

    var allTestsPassed = true
    var testResults: [[String: String]] = []

    for (index, originalDate) in testDates.enumerated() {
      do {
        // Forward conversion: Date -> Timestamp -> DynamicMessage
        let timestampValue = TimestampHandler.TimestampValue(from: originalDate)
        let message = try TimestampHandler.createDynamic(from: timestampValue)

        // Backward conversion: DynamicMessage -> Timestamp -> Date
        let extractedValue = try TimestampHandler.createSpecialized(from: message) as! TimestampHandler.TimestampValue
        let reconstructedDate = extractedValue.toDate()

        // Analyze precision
        let timeDifference = abs(originalDate.timeIntervalSince(reconstructedDate))
        let testPassed = timeDifference < 0.000001  // 1 microsecond tolerance

        testResults.append([
          "Test": "Test \(index + 1)",
          "Original": String(format: "%.6f", originalDate.timeIntervalSince1970),
          "Reconstructed": String(format: "%.6f", reconstructedDate.timeIntervalSince1970),
          "Difference": String(format: "%.9f", timeDifference),
          "Status": testPassed ? "✅ PASS" : "❌ FAIL",
        ])

        if !testPassed {
          allTestsPassed = false
        }
      }
      catch {
        testResults.append([
          "Test": "Test \(index + 1)",
          "Original": String(format: "%.6f", originalDate.timeIntervalSince1970),
          "Reconstructed": "ERROR",
          "Difference": "N/A",
          "Status": "❌ ERROR: \(error)",
        ])
        allTestsPassed = false
      }
    }

    ExampleUtils.printDataTable(testResults, title: "Round-Trip Test Results")

    print("  🏆 Overall round-trip compatibility: \(allTestsPassed ? "✅ EXCELLENT" : "⚠️ NEEDS ATTENTION")")
  }

  private static func demonstrateEdgeCases() throws {
    ExampleUtils.printStep(4, "Edge Cases and Validation")

    // Тестирование граничных значений
    let edgeCases = [
      ("Very small positive", Date(timeIntervalSince1970: 0.0001)),
      ("Very large valid", Date(timeIntervalSince1970: 253_402_300_799)),  // Max valid timestamp
      ("Negative timestamp", Date(timeIntervalSince1970: -62_135_596_800)),  // Min valid
      ("Current moment", Date()),
    ]

    var edgeResults: [[String: String]] = []

    for (label, date) in edgeCases {
      do {
        let timestampValue = TimestampHandler.TimestampValue(from: date)
        let message = try TimestampHandler.createDynamic(from: timestampValue)
        let extracted = try TimestampHandler.createSpecialized(from: message) as! TimestampHandler.TimestampValue

        // Validation checks
        let isValid = timestampValue.seconds >= -62_135_596_800 && timestampValue.seconds <= 253_402_300_799
        let nanosValid = timestampValue.nanos >= 0 && timestampValue.nanos < 1_000_000_000

        edgeResults.append([
          "Case": label,
          "Seconds": "\(timestampValue.seconds)",
          "Nanos": "\(timestampValue.nanos)",
          "Valid Range": isValid ? "✅ YES" : "❌ NO",
          "Nanos Valid": nanosValid ? "✅ YES" : "❌ NO",
          "Status": "✅ SUCCESS",
        ])
      }
      catch {
        edgeResults.append([
          "Case": label,
          "Seconds": "N/A",
          "Nanos": "N/A",
          "Valid Range": "❌ ERROR",
          "Nanos Valid": "❌ ERROR",
          "Status": "❌ \(error)",
        ])
      }
    }

    ExampleUtils.printDataTable(edgeResults, title: "Edge Cases Validation")

    // Тестирование валидации правил Protocol Buffers
    print("  📝 Protocol Buffers validation rules:")
    print("    • Seconds must be in range [-62135596800, 253402300799]")
    print("    • Nanos must be in range [0, 999999999]")
    print("    • Nanos must be non-negative even for negative seconds")
    print("    • Canonical representation ensures consistent encoding")
  }

  private static func demonstratePerformanceAndPrecision() throws {
    ExampleUtils.printStep(5, "Performance and Precision Analysis")

    // Performance benchmarking
    let testCount = 1000
    var conversionTimes: [TimeInterval] = []

    let (_, totalTime) = ExampleUtils.measureTime {
      for _ in 0..<testCount {
        let (_, individualTime) = ExampleUtils.measureTime {
          let date = Date()
          let timestampValue = TimestampHandler.TimestampValue(from: date)
          let _ = try! TimestampHandler.createDynamic(from: timestampValue)
        }
        conversionTimes.append(individualTime)
      }
    }

    let averageTime = conversionTimes.reduce(0, +) / Double(conversionTimes.count)
    let minTime = conversionTimes.min() ?? 0
    let maxTime = conversionTimes.max() ?? 0

    ExampleUtils.printTiming("Average conversion (\(testCount) iterations)", time: averageTime)
    ExampleUtils.printTiming("Fastest conversion", time: minTime)
    ExampleUtils.printTiming("Slowest conversion", time: maxTime)
    ExampleUtils.printTiming("Total benchmark time", time: totalTime)

    let conversionsPerSecond = Double(testCount) / totalTime
    print("  🚀 Performance: \(String(format: "%.0f", conversionsPerSecond)) conversions/second")

    // Precision analysis
    print("  🎯 Precision analysis:")
    let baseDate = Date()
    var precisionTests: [[String: String]] = []

    let precisionScales = [1e-3, 1e-6, 1e-9]  // millisecond, microsecond, nanosecond
    let scaleLabels = ["Millisecond", "Microsecond", "Nanosecond"]

    for (index, scale) in precisionScales.enumerated() {
      let adjustedDate = Date(timeIntervalSince1970: baseDate.timeIntervalSince1970 + scale)
      let timestampValue = TimestampHandler.TimestampValue(from: adjustedDate)
      let message = try TimestampHandler.createDynamic(from: timestampValue)
      let extracted = try TimestampHandler.createSpecialized(from: message) as! TimestampHandler.TimestampValue
      let reconstructed = extracted.toDate()

      let error = abs(adjustedDate.timeIntervalSince(reconstructed))
      let errorPercentage = (error / scale) * 100

      precisionTests.append([
        "Scale": scaleLabels[index],
        "Input Δ": String(format: "%.9f", scale),
        "Output Δ": String(format: "%.9f", reconstructed.timeIntervalSince(baseDate)),
        "Error": String(format: "%.9f", error),
        "Error %": String(format: "%.3f%%", errorPercentage),
      ])
    }

    ExampleUtils.printDataTable(precisionTests, title: "Precision Analysis")

    print("  💡 Key insights:")
    print("    • Protocol Buffers Timestamp поддерживает наносекундную точность")
    print("    • Swift Date имеет ограничения в точности (обычно микросекунды)")
    print("    • Round-trip конвертация теряет точность на уровне наносекунд")
    print("    • Для большинства применений точность более чем достаточна")
  }
}

// MARK: - Extensions

extension DateFormatter {
  fileprivate static let iso8601: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
  }()
}
