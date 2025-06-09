/**
 * 🔍 SwiftProtoReflect Example: Basic Descriptors and Metadata
 *
 * Описание: Детальная работа с дескрипторами для извлечения метаданных и навигации
 * Ключевые концепции: Descriptors, Metadata, Field Navigation, Type Introspection
 * Сложность: 🔧 Средний
 * Время выполнения: < 15 секунд
 *
 * Что изучите:
 * - Навигация по иерархии FileDescriptor -> MessageDescriptor -> FieldDescriptor
 * - Извлечение детальной информации о полях и их типах
 * - Работа с EnumDescriptor и его значениями
 * - Интроспекция структуры сообщений
 * - Анализ зависимостей и связей между типами
 *
 * Запуск:
 *   swift run BasicDescriptors
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct BasicDescriptorsExample {
  static func main() throws {
    ExampleUtils.printHeader("Дескрипторы и метаданные - детальная интроспекция")

    try step1UfileDescriptorNavigation()
    try step2UmessageDescriptorDetails()
    try step3UfieldDescriptorAnalysis()
    try step4UenumDescriptorExploration()
    try step5UtypeRelationships()

    ExampleUtils.printSuccess("Вы освоили работу с дескрипторами и метаданными Protocol Buffers!")

    ExampleUtils.printNext([
      "Следующий: complex-messages.swift - продвинутые динамические сообщения",
      "Категория 02: dynamic-messages.swift - сложные операции с сообщениями",
      "Изучите: serialization-basics.swift - сериализация и десериализация",
    ])
  }

  // MARK: - Implementation Steps

  private static func step1UfileDescriptorNavigation() throws {
    ExampleUtils.printStep(1, "Навигация по FileDescriptor")

    let fileDescriptor = try createComprehensiveFileStructure()

    // Анализ основной информации о файле
    ExampleUtils.printTable(
      [
        "File Name": fileDescriptor.name,
        "Package": fileDescriptor.package,
        "Full Package Name": "\(fileDescriptor.package).\(fileDescriptor.name)",
        "Messages Count": "\(fileDescriptor.messages.count)",
        "Enums Count": "\(fileDescriptor.enums.count)",
      ],
      title: "File Descriptor Info"
    )

    print("\n  🏗  Структура файла:")

    // Навигация по сообщениям
    print("    📋 Messages:")
    for message in fileDescriptor.messages.values {
      print("      • \(message.name) (\(message.fields.count) fields)")
    }

    // Навигация по enums
    print("    🏷  Enums:")
    for enumDesc in fileDescriptor.enums.values {
      print("      • \(enumDesc.name) (\(enumDesc.allValues().count) values)")
    }

    // Демонстрация поиска по имени
    if let userMessage = fileDescriptor.messages.values.first(where: { $0.name == "User" }) {
      print("\n  🔍 Найдено сообщение User:")
      print("      Full name: \(userMessage.fullName)")
      print("      Parent file: \(fileDescriptor.name)")
    }
  }

  private static func step2UmessageDescriptorDetails() throws {
    ExampleUtils.printStep(2, "Детальный анализ MessageDescriptor")

    let fileDescriptor = try createComprehensiveFileStructure()

    guard let userMessage = fileDescriptor.messages.values.first(where: { $0.name == "User" }) else {
      throw NSError(domain: "Example", code: 1, userInfo: [NSLocalizedDescriptionKey: "User message not found"])
    }

    print("  📋 Анализ сообщения User:")

    // Основная информация
    ExampleUtils.printTable(
      [
        "Name": userMessage.name,
        "Full Name": userMessage.fullName,
        "Fields Count": "\(userMessage.fields.count)",
        "Parent Type": "FileDescriptor",
      ],
      title: "Message Details"
    )

    // Анализ полей по типам
    var fieldsByType: [String: [FieldDescriptor]] = [:]
    for field in userMessage.fields.values {
      let typeName = "\(field.type)"
      if fieldsByType[typeName] == nil {
        fieldsByType[typeName] = []
      }
      fieldsByType[typeName]?.append(field)
    }

    print("\n    📊 Поля по типам:")
    for (type, fields) in fieldsByType.sorted(by: { $0.key < $1.key }) {
      print("      \(type): \(fields.map { $0.name }.joined(separator: ", "))")
    }

    // Поиск специальных полей
    let repeatedFields = userMessage.fields.values.filter { $0.isRepeated }
    let oneofFields = userMessage.fields.values.filter { $0.oneofIndex != nil }

    if !repeatedFields.isEmpty {
      print("    🔄 Repeated fields: \(repeatedFields.map { $0.name }.joined(separator: ", "))")
    }

    if !oneofFields.isEmpty {
      print("    🔀 OneOf fields: \(oneofFields.map { $0.name }.joined(separator: ", "))")
    }
  }

  private static func step3UfieldDescriptorAnalysis() throws {
    ExampleUtils.printStep(3, "Анализ FieldDescriptor'ов")

    let fileDescriptor = try createComprehensiveFileStructure()

    guard let userMessage = fileDescriptor.messages.values.first(where: { $0.name == "User" }) else {
      throw NSError(domain: "Example", code: 1, userInfo: [NSLocalizedDescriptionKey: "User message not found"])
    }

    print("  🔍 Детальный анализ полей User:")

    // Создаем таблицу с информацией о каждом поле
    var fieldData: [String: String] = [:]

    for field in userMessage.fields.values.sorted(by: { $0.number < $1.number }) {
      var details: [String] = []

      details.append("Type: \(field.type)")
      details.append("Number: \(field.number)")

      if field.isRepeated {
        details.append("Repeated: ✅")
      }

      if let oneofIndex = field.oneofIndex {
        details.append("OneOf: group \(oneofIndex)")
      }

      if let typeName = field.typeName, !typeName.isEmpty {
        details.append("TypeName: \(typeName)")
      }

      if let defaultValue = field.defaultValue {
        details.append("Default: \(defaultValue)")
      }

      fieldData[field.name] = details.joined(separator: ", ")
    }

    ExampleUtils.printTable(fieldData, title: "Field Details")

    // Демонстрация поиска поля по номеру
    if let fieldByNumber = userMessage.fields.values.first(where: { $0.number == 1 }) {
      print("\n  🎯 Поле с номером 1: \(fieldByNumber.name) (\(fieldByNumber.type))")
    }

    // Анализ message полей
    let messageFields = userMessage.fields.values.filter { $0.type == .message }
    if !messageFields.isEmpty {
      print("\n  🏗  Message fields:")
      for field in messageFields {
        print("      • \(field.name) -> \(field.typeName ?? "unknown")")
      }
    }
  }

  private static func step4UenumDescriptorExploration() throws {
    ExampleUtils.printStep(4, "Исследование EnumDescriptor")

    let fileDescriptor = try createComprehensiveFileStructure()

    guard let statusEnum = fileDescriptor.enums.values.first(where: { $0.name == "UserStatus" }) else {
      throw NSError(domain: "Example", code: 1, userInfo: [NSLocalizedDescriptionKey: "UserStatus enum not found"])
    }

    print("  🏷  Анализ enum UserStatus:")

    // Основная информация об enum
    ExampleUtils.printTable(
      [
        "Name": statusEnum.name,
        "Full Name": statusEnum.fullName,
        "Values Count": "\(statusEnum.allValues().count)",
        "Parent": fileDescriptor.name,
      ],
      title: "Enum Details"
    )

    // Анализ значений enum
    print("\n    📊 Enum Values:")
    for enumValue in statusEnum.allValues().sorted(by: { $0.number < $1.number }) {
      print("      \(enumValue.name) = \(enumValue.number)")
    }

    // Поиск значения по номеру
    if let valueByNumber = statusEnum.allValues().first(where: { $0.number == 1 }) {
      print("\n  🎯 Значение с номером 1: \(valueByNumber.name)")
    }

    // Поиск значения по имени
    if let valueByName = statusEnum.allValues().first(where: { $0.name == "ACTIVE" }) {
      print("  🎯 Значение 'ACTIVE': номер \(valueByName.number)")
    }

    // Демонстрация использования enum в поле
    guard let userMessage = fileDescriptor.messages.values.first(where: { $0.name == "User" }) else {
      return
    }

    let enumFields = userMessage.fields.values.filter { $0.type == .enum }
    if let statusField = enumFields.first(where: { $0.name == "status" }) {
      print("\n  🔗 Поле status связано с enum: \(statusField.typeName ?? "unknown")")
    }
  }

  private static func step5UtypeRelationships() throws {
    ExampleUtils.printStep(5, "Анализ связей между типами")

    let fileDescriptor = try createComprehensiveFileStructure()

    print("  🕸  Граф зависимостей типов:")

    // Анализируем связи между сообщениями
    for message in fileDescriptor.messages.values {
      let messageFields = message.fields.values.filter { $0.type == .message }

      if !messageFields.isEmpty {
        print("\n    📋 \(message.name) references:")
        for field in messageFields {
          let referencedType = field.typeName?.components(separatedBy: ".").last ?? "unknown"
          print("      • \(field.name) -> \(referencedType)")
        }
      }
    }

    // Анализируем использование enums
    print("\n  🏷  Enum Usage:")
    for message in fileDescriptor.messages.values {
      let enumFields = message.fields.values.filter { $0.type == .enum }

      if !enumFields.isEmpty {
        print("    📋 \(message.name) uses enums:")
        for field in enumFields {
          let enumType = field.typeName?.components(separatedBy: ".").last ?? "unknown"
          print("      • \(field.name) -> \(enumType)")
        }
      }
    }

    // Статистика типов
    var typeUsage: [String: Int] = [:]
    for message in fileDescriptor.messages.values {
      for field in message.fields.values {
        let typeName = "\(field.type)"
        typeUsage[typeName, default: 0] += 1
      }
    }

    print("\n  📊 Статистика использования типов:")
    for (type, count) in typeUsage.sorted(by: { $0.value > $1.value }) {
      print("      \(type): \(count) fields")
    }

    ExampleUtils.printInfo("Анализ дескрипторов позволяет понять структуру данных без создания сообщений")
  }

  // MARK: - Helper Methods

  private static func createComprehensiveFileStructure() throws -> FileDescriptor {
    var fileDescriptor = FileDescriptor(name: "comprehensive.proto", package: "example")

    // Создаем enum UserStatus
    var userStatusEnum = EnumDescriptor(name: "UserStatus", parent: fileDescriptor)
    userStatusEnum.addValue(EnumDescriptor.EnumValue(name: "UNKNOWN", number: 0))
    userStatusEnum.addValue(EnumDescriptor.EnumValue(name: "ACTIVE", number: 1))
    userStatusEnum.addValue(EnumDescriptor.EnumValue(name: "INACTIVE", number: 2))
    userStatusEnum.addValue(EnumDescriptor.EnumValue(name: "SUSPENDED", number: 3))

    // Создаем enum Priority
    var priorityEnum = EnumDescriptor(name: "Priority", parent: fileDescriptor)
    priorityEnum.addValue(EnumDescriptor.EnumValue(name: "LOW", number: 0))
    priorityEnum.addValue(EnumDescriptor.EnumValue(name: "NORMAL", number: 1))
    priorityEnum.addValue(EnumDescriptor.EnumValue(name: "HIGH", number: 2))
    priorityEnum.addValue(EnumDescriptor.EnumValue(name: "URGENT", number: 3))

    // Создаем Address сообщение
    var addressDescriptor = MessageDescriptor(name: "Address", parent: fileDescriptor)
    addressDescriptor.addField(FieldDescriptor(name: "street", number: 1, type: .string))
    addressDescriptor.addField(FieldDescriptor(name: "city", number: 2, type: .string))
    addressDescriptor.addField(FieldDescriptor(name: "postal_code", number: 3, type: .string))
    addressDescriptor.addField(FieldDescriptor(name: "country", number: 4, type: .string, defaultValue: "Unknown"))

    // Создаем Contact сообщение с OneOf полями
    var contactDescriptor = MessageDescriptor(name: "Contact", parent: fileDescriptor)
    contactDescriptor.addField(FieldDescriptor(name: "email", number: 1, type: .string, oneofIndex: 0))
    contactDescriptor.addField(FieldDescriptor(name: "phone", number: 2, type: .string, oneofIndex: 0))
    contactDescriptor.addField(FieldDescriptor(name: "social_media", number: 3, type: .string, oneofIndex: 0))

    // Создаем главное User сообщение
    var userDescriptor = MessageDescriptor(name: "User", parent: fileDescriptor)
    userDescriptor.addField(FieldDescriptor(name: "id", number: 1, type: .int64))
    userDescriptor.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    userDescriptor.addField(FieldDescriptor(name: "email", number: 3, type: .string))
    userDescriptor.addField(FieldDescriptor(name: "age", number: 4, type: .int32, defaultValue: Int32(0)))
    userDescriptor.addField(
      FieldDescriptor(
        name: "status",
        number: 5,
        type: .enum,
        typeName: "example.UserStatus",
        defaultValue: Int32(0)
      )
    )
    userDescriptor.addField(
      FieldDescriptor(
        name: "address",
        number: 6,
        type: .message,
        typeName: "example.Address"
      )
    )
    userDescriptor.addField(
      FieldDescriptor(
        name: "contacts",
        number: 7,
        type: .message,
        typeName: "example.Contact",
        isRepeated: true
      )
    )
    userDescriptor.addField(FieldDescriptor(name: "tags", number: 8, type: .string, isRepeated: true))
    userDescriptor.addField(
      FieldDescriptor(
        name: "priority",
        number: 9,
        type: .enum,
        typeName: "example.Priority",
        defaultValue: Int32(1)
      )
    )
    userDescriptor.addField(FieldDescriptor(name: "is_verified", number: 10, type: .bool, defaultValue: false))

    // Добавляем все типы в файл
    fileDescriptor.addEnum(userStatusEnum)
    fileDescriptor.addEnum(priorityEnum)
    fileDescriptor.addMessage(addressDescriptor)
    fileDescriptor.addMessage(contactDescriptor)
    fileDescriptor.addMessage(userDescriptor)

    return fileDescriptor
  }
}
