/**
 * ValueHandler.swift
 * SwiftProtoReflect
 *
 * Обработчик для google.protobuf.Value - универсальные JSON-like значения
 */

import Foundation

// MARK: - Value Handler

/// Обработчик для google.protobuf.Value.
public struct ValueHandler: WellKnownTypeHandler {

  public static let handledTypeName = WellKnownTypeNames.value
  public static let supportPhase: WellKnownSupportPhase = .important

  // MARK: - Type Aliases

  /// Повторное использование ValueValue из StructHandler для совместимости.
  public typealias ValueValue = StructHandler.ValueValue

  // MARK: - Handler Implementation

  public static func createSpecialized(from message: DynamicMessage) throws -> Any {
    // Проверяем тип сообщения
    guard message.descriptor.fullName == handledTypeName else {
      throw WellKnownTypeError.invalidData(
        typeName: handledTypeName,
        reason: "Expected \(handledTypeName), got \(message.descriptor.fullName)"
      )
    }

    // Упрощенная реализация: храним Value как JSON в bytes поле
    do {
      if try message.hasValue(forField: "value_data") {
        let data = try message.get(forField: "value_data") as? Data ?? Data()
        if !data.isEmpty {
          let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
          // Извлекаем значение из wrapper объекта
          if let wrappedValue = jsonObject as? [String: Any],
            let actualValue = wrappedValue["value"]
          {
            return try ValueValue(from: actualValue)
          }
        }
      }
    }
    catch {
      throw WellKnownTypeError.conversionFailed(
        from: "DynamicMessage",
        to: "ValueValue",
        reason: "Failed to extract value_data: \(error.localizedDescription)"
      )
    }

    // Если поле пустое или отсутствует, возвращаем null
    return ValueValue.nullValue
  }

  public static func createDynamic(from specialized: Any) throws -> DynamicMessage {
    guard let valueValue = specialized as? ValueValue else {
      throw WellKnownTypeError.conversionFailed(
        from: String(describing: type(of: specialized)),
        to: "DynamicMessage",
        reason: "Expected ValueValue"
      )
    }

    // Создаем дескриптор для Value
    let valueDescriptor = createValueDescriptor()

    // Создаем сообщение
    let factory = MessageFactory()
    var message = factory.createMessage(from: valueDescriptor)

    // Сериализуем значение в JSON и сохраняем как Data
    let anyValue = valueValue.toAny()

    do {
      // Оборачиваем значение в dictionary чтобы избежать проблем с top-level типами
      let wrappedValue = ["value": anyValue]
      let jsonData = try JSONSerialization.data(withJSONObject: wrappedValue, options: [])
      try message.set(jsonData, forField: "value_data")
    }
    catch {
      throw WellKnownTypeError.conversionFailed(
        from: "ValueValue",
        to: "DynamicMessage",
        reason: "Failed to serialize value: \(error.localizedDescription)"
      )
    }

    return message
  }

  public static func validate(_ specialized: Any) -> Bool {
    return specialized is ValueValue
  }

  // MARK: - Descriptor Creation

  /// Создает дескриптор для google.protobuf.Value.
  /// - Returns: MessageDescriptor для Value.
  private static func createValueDescriptor() -> MessageDescriptor {
    // Создаем файл дескриптор
    var fileDescriptor = FileDescriptor(
      name: "google/protobuf/struct.proto",
      package: "google.protobuf"
    )

    // Создаем дескриптор сообщения Value
    var messageDescriptor = MessageDescriptor(
      name: "Value",
      parent: fileDescriptor
    )

    // Упрощенная реализация: храним JSON как bytes
    let valueDataField = FieldDescriptor(
      name: "value_data",
      number: 1,
      type: .bytes
    )
    messageDescriptor.addField(valueDataField)

    // Регистрируем в файле
    fileDescriptor.addMessage(messageDescriptor)

    return messageDescriptor
  }
}

// MARK: - Convenience Extensions

extension DynamicMessage {

  /// Создает DynamicMessage из произвольного значения для google.protobuf.Value.
  /// - Parameter value: Произвольное значение.
  /// - Returns: DynamicMessage представляющий Value.
  /// - Throws: WellKnownTypeError.
  public static func valueMessage(from value: Any) throws -> DynamicMessage {
    let valueValue = try ValueHandler.ValueValue(from: value)
    return try ValueHandler.createDynamic(from: valueValue)
  }

  /// Конвертирует DynamicMessage в произвольное значение (если это Value).
  /// - Returns: Произвольное значение.
  /// - Throws: WellKnownTypeError если сообщение не является Value.
  public func toAnyValue() throws -> Any {
    guard descriptor.fullName == WellKnownTypeNames.value else {
      throw WellKnownTypeError.invalidData(
        typeName: descriptor.fullName,
        reason: "Message is not a Value"
      )
    }

    let valueValue = try ValueHandler.createSpecialized(from: self) as! ValueHandler.ValueValue
    return valueValue.toAny()
  }
}
