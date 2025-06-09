/**
 * 💾 SwiftProtoReflect Example: Protocol Buffers Serialization
 *
 * Описание: Демонстрация binary Protocol Buffers сериализации и десериализации динамических сообщений
 * Ключевые концепции: BinarySerializer, BinaryDeserializer, Wire Format, Round-trip compatibility
 * Сложность: 🔧 Средний
 * Время выполнения: < 10 секунд
 *
 * Что изучите:
 * - Binary сериализация динамических сообщений в Protocol Buffers формат
 * - Десериализация из binary данных обратно в динамические сообщения
 * - Wire format совместимость и кодирование
 * - Round-trip тестирование (message -> binary -> message)
 * - Анализ размера данных и производительности
 * - Работа с различными типами полей при сериализации
 *
 * Запуск:
 *   swift run ProtobufSerialization
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct ProtobufSerializationExample {
  static func main() throws {
    ExampleUtils.printHeader("Protocol Buffers Binary Serialization")

    try step1UbasicSerialization()
    try step2UcomplexMessageSerialization()
    try step3UroundTripCompatibility()
    try step4UperformanceAnalysis()
    try step5UwireFormatAnalysis()

    ExampleUtils.printSuccess("Protocol Buffers сериализация успешно изучена!")

    ExampleUtils.printNext([
      "Далее попробуйте: swift run JsonConversion - JSON сериализация",
      "Или изучите: binary-data.swift - работа с бинарными данными",
      "Продвинутые: streaming.swift - потоковая обработка данных",
    ])
  }

  // MARK: - Implementation Steps

  private static func step1UbasicSerialization() throws {
    ExampleUtils.printStep(1, "Базовая binary сериализация")

    // Создаем простое сообщение
    var (person, _) = try createPersonMessage()

    // Заполняем данными
    try person.set("Alice Johnson", forField: "name")
    try person.set(Int32(28), forField: "age")
    try person.set("alice@example.com", forField: "email")

    print("  📝 Создано сообщение:")
    person.prettyPrint()

    // Сериализация в binary формат
    let (binaryData, serializeTime) = try ExampleUtils.measureTime {
      let serializer = BinarySerializer()
      return try serializer.serialize(person)
    }

    ExampleUtils.printTiming("Binary serialization", time: serializeTime)

    // Анализ результата
    print("  📦 Binary размер: \(ExampleUtils.formatDataSize(binaryData.count))")
    print("  🔢 Hex preview: \(ExampleUtils.formatDataPreview(binaryData))")

    // Десериализация обратно
    let (deserializedPerson, deserializeTime) = try ExampleUtils.measureTime {
      let deserializer = BinaryDeserializer()
      return try deserializer.deserialize(binaryData, using: person.descriptor)
    }

    ExampleUtils.printTiming("Binary deserialization", time: deserializeTime)

    print("  📋 Десериализованное сообщение:")
    deserializedPerson.prettyPrint()

    // Проверка идентичности
    try verifyMessagesEqual(original: person, deserialized: deserializedPerson)
  }

  private static func step2UcomplexMessageSerialization() throws {
    ExampleUtils.printStep(2, "Сериализация сложных сообщений")

    // Создаем сложное сообщение с различными типами полей
    var (company, _) = try createCompanyMessage()

    // Заполняем сложными данными
    try company.set("TechCorp Inc.", forField: "name")
    try company.set("CORPORATION", forField: "type")
    try company.set([Int32(100), Int32(200), Int32(300)], forField: "revenue_millions")
    try company.set(["usa", "uk", "japan"], forField: "offices")
    try company.set(true, forField: "public_company")

    print("  🏢 Создано сложное сообщение:")
    company.prettyPrint()

    // Сериализация
    let (complexBinaryData, complexSerializeTime) = try ExampleUtils.measureTime {
      let serializer = BinarySerializer()
      return try serializer.serialize(company)
    }

    ExampleUtils.printTiming("Complex message serialization", time: complexSerializeTime)

    print("  📦 Размер сложного сообщения: \(ExampleUtils.formatDataSize(complexBinaryData.count))")
    print("  🔢 Hex preview: \(ExampleUtils.formatDataPreview(complexBinaryData, maxBytes: 30))")

    // Десериализация
    let (deserializedCompany, complexDeserializeTime) = try ExampleUtils.measureTime {
      let deserializer = BinaryDeserializer()
      return try deserializer.deserialize(complexBinaryData, using: company.descriptor)
    }

    ExampleUtils.printTiming("Complex message deserialization", time: complexDeserializeTime)

    print("  📋 Десериализованное сложное сообщение:")
    deserializedCompany.prettyPrint()

    // Проверка repeated полей
    try verifyRepeatedFields(original: company, deserialized: deserializedCompany)
  }

  private static func step3UroundTripCompatibility() throws {
    ExampleUtils.printStep(3, "Round-trip совместимость")

    print("  🔄 Тестирование multiple round-trips...")

    var currentMessage = try createPersonMessage().0
    try currentMessage.set("Round Trip User", forField: "name")
    try currentMessage.set(Int32(42), forField: "age")
    try currentMessage.set("roundtrip@test.com", forField: "email")

    var totalSerializeTime: TimeInterval = 0
    var totalDeserializeTime: TimeInterval = 0

    // Выполняем несколько циклов сериализация -> десериализация
    for round in 1...5 {
      // Сериализация
      let (binaryData, serializeTime) = try ExampleUtils.measureTime {
        let serializer = BinarySerializer()
        return try serializer.serialize(currentMessage)
      }
      totalSerializeTime += serializeTime

      // Десериализация
      let (newMessage, deserializeTime) = try ExampleUtils.measureTime {
        let deserializer = BinaryDeserializer()
        return try deserializer.deserialize(binaryData, using: currentMessage.descriptor)
      }
      totalDeserializeTime += deserializeTime

      print("    Round \(round): \(ExampleUtils.formatDataSize(binaryData.count)) -> OK")
      currentMessage = newMessage
    }

    ExampleUtils.printTiming("Total serialization (5 rounds)", time: totalSerializeTime)
    ExampleUtils.printTiming("Total deserialization (5 rounds)", time: totalDeserializeTime)

    print("  📋 Финальное сообщение после 5 round-trips:")
    currentMessage.prettyPrint()

    // Проверяем что данные не изменились
    let finalName: String? = try currentMessage.get(forField: "name") as? String
    let finalAge: Int32? = try currentMessage.get(forField: "age") as? Int32
    let finalEmail: String? = try currentMessage.get(forField: "email") as? String

    let isValid =
      ExampleUtils.assertEqual(finalName, "Round Trip User", description: "Name preservation")
      && ExampleUtils.assertEqual(finalAge, Int32(42), description: "Age preservation")
      && ExampleUtils.assertEqual(finalEmail, "roundtrip@test.com", description: "Email preservation")

    if isValid {
      print("  ✅ Round-trip совместимость: PASSED")
    }
    else {
      print("  ❌ Round-trip совместимость: FAILED")
    }
  }

  private static func step4UperformanceAnalysis() throws {
    ExampleUtils.printStep(4, "Анализ производительности")

    print("  📊 Performance benchmarking...")

    // Создаем тестовые сообщения разных размеров
    let testCases = [
      ("Small", 1),
      ("Medium", 10),
      ("Large", 100),
    ]

    var results: [String: (size: Int, serializeTime: TimeInterval, deserializeTime: TimeInterval)] = [:]

    for (label, count) in testCases {
      let (_, binaryData, serializeTime, deserializeTime) = try benchmarkSerialization(messageCount: count)

      results[label] = (
        size: binaryData.count,
        serializeTime: serializeTime,
        deserializeTime: deserializeTime
      )

      print("    \(label) (\(count) messages):")
      print("      Size: \(ExampleUtils.formatDataSize(binaryData.count))")
      ExampleUtils.printTiming("      Serialize", time: serializeTime)
      ExampleUtils.printTiming("      Deserialize", time: deserializeTime)

      let throughputMBps = Double(binaryData.count) / (1024 * 1024) / serializeTime
      print("      Throughput: \(String(format: "%.2f", throughputMBps)) MB/s")
    }

    // Сводная таблица
    ExampleUtils.printTable(
      [
        "Small (1 msg)": "\(ExampleUtils.formatDataSize(results["Small"]!.size))",
        "Medium (10 msgs)": "\(ExampleUtils.formatDataSize(results["Medium"]!.size))",
        "Large (100 msgs)": "\(ExampleUtils.formatDataSize(results["Large"]!.size))",
      ],
      title: "Размеры данных"
    )
  }

  private static func step5UwireFormatAnalysis() throws {
    ExampleUtils.printStep(5, "Анализ Wire Format")

    // Создаем сообщение с различными типами полей для анализа wire format
    var (message, _) = try createWireFormatTestMessage()

    // Заполняем данными
    try message.set("Test", forField: "string_field")
    try message.set(Int32(12345), forField: "int32_field")
    try message.set(true, forField: "bool_field")
    try message.set([Int32(1), Int32(2), Int32(3)], forField: "repeated_field")

    let serializer = BinarySerializer()
    let binaryData = try serializer.serialize(message)

    print("  🔍 Wire format анализ:")
    print("    Total size: \(binaryData.count) bytes")
    print("    Hex dump: \(ExampleUtils.formatDataPreview(binaryData, maxBytes: 50))")

    // Анализируем structure wire format
    analyzeWireFormat(binaryData)

    print("  📋 Исходное сообщение:")
    message.prettyPrint()

    // Проверяем десериализацию
    let deserializer = BinaryDeserializer()
    let reconstructed = try deserializer.deserialize(binaryData, using: message.descriptor)

    print("  📋 Восстановленное сообщение:")
    reconstructed.prettyPrint()
  }

  // MARK: - Helper Methods

  private static func createPersonMessage() throws -> (DynamicMessage, FileDescriptor) {
    var fileDescriptor = FileDescriptor(name: "person.proto", package: "serialization.test")
    var personMessage = MessageDescriptor(name: "Person", parent: fileDescriptor)

    personMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    personMessage.addField(FieldDescriptor(name: "age", number: 2, type: .int32))
    personMessage.addField(FieldDescriptor(name: "email", number: 3, type: .string))

    fileDescriptor.addMessage(personMessage)

    let factory = MessageFactory()
    let message = factory.createMessage(from: personMessage)

    return (message, fileDescriptor)
  }

  private static func createCompanyMessage() throws -> (DynamicMessage, FileDescriptor) {
    var fileDescriptor = FileDescriptor(name: "company.proto", package: "serialization.test")
    var companyMessage = MessageDescriptor(name: "Company", parent: fileDescriptor)

    companyMessage.addField(FieldDescriptor(name: "name", number: 1, type: .string))
    companyMessage.addField(FieldDescriptor(name: "type", number: 2, type: .string))
    companyMessage.addField(FieldDescriptor(name: "revenue_millions", number: 3, type: .int32, isRepeated: true))
    companyMessage.addField(FieldDescriptor(name: "offices", number: 4, type: .string, isRepeated: true))
    companyMessage.addField(FieldDescriptor(name: "public_company", number: 5, type: .bool))

    fileDescriptor.addMessage(companyMessage)

    let factory = MessageFactory()
    let message = factory.createMessage(from: companyMessage)

    return (message, fileDescriptor)
  }

  private static func createWireFormatTestMessage() throws -> (DynamicMessage, FileDescriptor) {
    var fileDescriptor = FileDescriptor(name: "wiretest.proto", package: "serialization.test")
    var testMessage = MessageDescriptor(name: "WireTest", parent: fileDescriptor)

    testMessage.addField(FieldDescriptor(name: "string_field", number: 1, type: .string))
    testMessage.addField(FieldDescriptor(name: "int32_field", number: 2, type: .int32))
    testMessage.addField(FieldDescriptor(name: "bool_field", number: 3, type: .bool))
    testMessage.addField(FieldDescriptor(name: "repeated_field", number: 4, type: .int32, isRepeated: true))

    fileDescriptor.addMessage(testMessage)

    let factory = MessageFactory()
    let message = factory.createMessage(from: testMessage)

    return (message, fileDescriptor)
  }

  private static func verifyMessagesEqual(original: DynamicMessage, deserialized: DynamicMessage) throws {
    print("  🔍 Проверка идентичности сообщений:")

    for field in original.descriptor.fields.values {
      let originalValue = try original.get(forField: field.name)
      let deserializedValue = try deserialized.get(forField: field.name)

      let isEqual = areValuesEqual(originalValue, deserializedValue)
      let status = isEqual ? "✅" : "❌"
      print("    \(status) Field '\(field.name)': \(isEqual ? "OK" : "DIFFERENT")")
    }
  }

  private static func verifyRepeatedFields(original: DynamicMessage, deserialized: DynamicMessage) throws {
    print("  🔍 Проверка repeated полей:")

    let revenueOriginal = try original.get(forField: "revenue_millions") as? [Int32] ?? []
    let revenueDeserialized = try deserialized.get(forField: "revenue_millions") as? [Int32] ?? []

    let revenueEqual = revenueOriginal == revenueDeserialized
    print("    \(revenueEqual ? "✅" : "❌") revenue_millions: \(revenueEqual ? "OK" : "DIFFERENT")")

    let officesOriginal = try original.get(forField: "offices") as? [String] ?? []
    let officesDeserialized = try deserialized.get(forField: "offices") as? [String] ?? []

    let officesEqual = officesOriginal == officesDeserialized
    print("    \(officesEqual ? "✅" : "❌") offices: \(officesEqual ? "OK" : "DIFFERENT")")
  }

  private static func areValuesEqual(_ value1: Any?, _ value2: Any?) -> Bool {
    switch (value1, value2) {
    case (nil, nil):
      return true
    case (let s1 as String, let s2 as String):
      return s1 == s2
    case (let i1 as Int32, let i2 as Int32):
      return i1 == i2
    case (let b1 as Bool, let b2 as Bool):
      return b1 == b2
    case (let arr1 as [Int32], let arr2 as [Int32]):
      return arr1 == arr2
    case (let arr1 as [String], let arr2 as [String]):
      return arr1 == arr2
    default:
      return false
    }
  }

  private static func benchmarkSerialization(messageCount: Int) throws -> (
    [DynamicMessage], Data, TimeInterval, TimeInterval
  ) {
    let serializer = BinarySerializer()
    let deserializer = BinaryDeserializer()

    // Создаем тестовые сообщения
    var messages: [DynamicMessage] = []
    for i in 0..<messageCount {
      var (message, _) = try createPersonMessage()
      try message.set("User \(i)", forField: "name")
      try message.set(Int32(20 + i), forField: "age")
      try message.set("user\(i)@test.com", forField: "email")
      messages.append(message)
    }

    // Benchmark сериализация
    let (allBinaryData, serializeTime) = try ExampleUtils.measureTime {
      var combinedData = Data()
      for message in messages {
        let messageData = try serializer.serialize(message)
        combinedData.append(messageData)
      }
      return combinedData
    }

    // Benchmark десериализация (упрощенная - десериализуем первое сообщение)
    if let firstMessage = messages.first {
      let firstMessageData = try serializer.serialize(firstMessage)
      let (_, deserializeTime) = try ExampleUtils.measureTime {
        let _ = try deserializer.deserialize(firstMessageData, using: firstMessage.descriptor)
      }

      return (messages, allBinaryData, serializeTime, deserializeTime * TimeInterval(messageCount))
    }

    return (messages, allBinaryData, serializeTime, 0)
  }

  private static func analyzeWireFormat(_ data: Data) {
    print("    Wire format структура:")

    var offset = 0
    var fieldNumber = 1

    while offset < data.count && offset < 20 {  // Ограничиваем для краткости
      if offset + 1 < data.count {
        let byte1 = data[offset]
        let wireType = byte1 & 0x07
        let field = (byte1 >> 3) & 0x0F

        let wireTypeName = getWireTypeName(wireType)
        print("      Offset \(offset): Field \(field), Type \(wireTypeName) (0x\(String(format: "%02x", byte1)))")

        offset += 1
        if wireType == 2 && offset < data.count {  // Length-delimited
          let length = data[offset]
          print("        Length: \(length)")
          offset += Int(length) + 1
        }
        else {
          offset += 1
        }
      }
      else {
        break
      }

      fieldNumber += 1
      if fieldNumber > 10 { break }  // Ограничиваем вывод
    }
  }

  private static func getWireTypeName(_ wireType: UInt8) -> String {
    switch wireType {
    case 0: return "VARINT"
    case 1: return "FIXED64"
    case 2: return "LENGTH_DELIMITED"
    case 3: return "START_GROUP"
    case 4: return "END_GROUP"
    case 5: return "FIXED32"
    default: return "UNKNOWN"
    }
  }
}
