//
// DescriptorBridge.swift
// SwiftProtoReflect
//
// Создан: 2025-05-25
//

import Foundation
import SwiftProtobuf

/// DescriptorBridge обеспечивает конвертацию между дескрипторами SwiftProtoReflect.
/// и дескрипторами Swift Protobuf.
///
/// Этот компонент позволяет:.
/// - Конвертировать дескрипторы SwiftProtoReflect в формат Swift Protobuf.
/// - Создавать дескрипторы SwiftProtoReflect из дескрипторов Swift Protobuf.
/// - Обеспечивать совместимость между различными представлениями метаданных.
public struct DescriptorBridge {

  // MARK: - Initialization

  /// Создает новый экземпляр DescriptorBridge.
  public init() {}

  // MARK: - Message Descriptor Conversion

  /// Конвертирует MessageDescriptor в Google_Protobuf_DescriptorProto.
  ///
  /// - Parameter messageDescriptor: Дескриптор сообщения SwiftProtoReflect.
  /// - Returns: Дескриптор сообщения в формате Swift Protobuf.
  /// - Throws: Ошибку, если конвертация невозможна.
  public func toProtobufDescriptor(
    from messageDescriptor: MessageDescriptor
  ) throws -> Google_Protobuf_DescriptorProto {
    var proto = Google_Protobuf_DescriptorProto()

    // Устанавливаем имя сообщения
    proto.name = messageDescriptor.name

    // Конвертируем поля
    proto.field = try messageDescriptor.allFields().map { field in
      try toProtobufFieldDescriptor(from: field)
    }

    // Конвертируем вложенные сообщения
    proto.nestedType = try Array(messageDescriptor.nestedMessages.values).map { nestedMessage in
      try toProtobufDescriptor(from: nestedMessage)
    }

    // Конвертируем вложенные enum'ы
    proto.enumType = try Array(messageDescriptor.nestedEnums.values).map { nestedEnum in
      try toProtobufEnumDescriptor(from: nestedEnum)
    }

    // Устанавливаем опции, если есть
    if !messageDescriptor.options.isEmpty {
      proto.options = try toProtobufMessageOptions(from: messageDescriptor.options)
    }

    return proto
  }

  /// Создает MessageDescriptor из Google_Protobuf_DescriptorProto.
  ///
  /// - Parameters:.
  ///   - protobufDescriptor: Дескриптор сообщения в формате Swift Protobuf.
  ///   - parent: Родительский дескриптор файла (опционально).
  /// - Returns: Дескриптор сообщения SwiftProtoReflect.
  /// - Throws: Ошибку, если конвертация невозможна.
  public func fromProtobufDescriptor(
    _ protobufDescriptor: Google_Protobuf_DescriptorProto,
    parent: FileDescriptor? = nil
  ) throws -> MessageDescriptor {
    var messageDescriptor = MessageDescriptor(
      name: protobufDescriptor.name,
      parent: parent
    )

    // Конвертируем поля
    for fieldProto in protobufDescriptor.field {
      let field = try fromProtobufFieldDescriptor(fieldProto)
      messageDescriptor.addField(field)
    }

    // Конвертируем вложенные сообщения
    for nestedProto in protobufDescriptor.nestedType {
      let nestedMessage = try fromProtobufDescriptor(nestedProto, parent: nil)
      messageDescriptor.addNestedMessage(nestedMessage)
    }

    // Конвертируем вложенные enum'ы
    for enumProto in protobufDescriptor.enumType {
      let nestedEnum = try fromProtobufEnumDescriptor(enumProto)
      messageDescriptor.addNestedEnum(nestedEnum)
    }

    // Конвертируем опции
    if protobufDescriptor.hasOptions {
      _ = try fromProtobufMessageOptions(protobufDescriptor.options)
      // TODO: Добавить поддержку опций в MessageDescriptor
      // for (key, value) in options {
      //   messageDescriptor.setOption(key: key, value: value)
      // }
    }

    return messageDescriptor
  }

  // MARK: - Field Descriptor Conversion

  /// Конвертирует FieldDescriptor в Google_Protobuf_FieldDescriptorProto.
  ///
  /// - Parameter fieldDescriptor: Дескриптор поля SwiftProtoReflect.
  /// - Returns: Дескриптор поля в формате Swift Protobuf.
  /// - Throws: Ошибку, если конвертация невозможна.
  public func toProtobufFieldDescriptor(
    from fieldDescriptor: FieldDescriptor
  ) throws -> Google_Protobuf_FieldDescriptorProto {
    var proto = Google_Protobuf_FieldDescriptorProto()

    // Устанавливаем основные свойства
    proto.name = fieldDescriptor.name
    proto.number = Int32(fieldDescriptor.number)

    // Конвертируем тип поля
    proto.type = try toProtobufFieldType(from: fieldDescriptor.type)

    // Устанавливаем label (repeated, optional, required)
    if fieldDescriptor.isRepeated {
      proto.label = .repeated
    }
    else if fieldDescriptor.isRequired {
      proto.label = .required
    }
    else {
      proto.label = .optional
    }

    // Устанавливаем имя типа для сложных типов
    if let typeName = fieldDescriptor.typeName {
      proto.typeName = typeName
    }

    // Устанавливаем JSON имя, если отличается
    if fieldDescriptor.jsonName != fieldDescriptor.name {
      proto.jsonName = fieldDescriptor.jsonName
    }

    // Устанавливаем опции, если есть
    if !fieldDescriptor.options.isEmpty {
      proto.options = try toProtobufFieldOptions(from: fieldDescriptor.options)
    }

    return proto
  }

  /// Создает FieldDescriptor из Google_Protobuf_FieldDescriptorProto.
  ///
  /// - Parameter protobufDescriptor: Дескриптор поля в формате Swift Protobuf.
  /// - Returns: Дескриптор поля SwiftProtoReflect.
  /// - Throws: Ошибку, если конвертация невозможна.
  public func fromProtobufFieldDescriptor(
    _ protobufDescriptor: Google_Protobuf_FieldDescriptorProto
  ) throws -> FieldDescriptor {
    // Конвертируем тип поля
    let fieldType = try fromProtobufFieldType(protobufDescriptor.type)

    // Определяем флаги
    let isRepeated = protobufDescriptor.label == .repeated
    let isRequired = protobufDescriptor.label == .required
    let isOptional = protobufDescriptor.label == .optional

    // Создаем дескриптор поля
    let fieldDescriptor = FieldDescriptor(
      name: protobufDescriptor.name,
      number: Int(protobufDescriptor.number),
      type: fieldType,
      typeName: protobufDescriptor.hasTypeName ? protobufDescriptor.typeName : nil,
      jsonName: protobufDescriptor.hasJsonName ? protobufDescriptor.jsonName : protobufDescriptor.name,
      isRepeated: isRepeated,
      isOptional: isOptional,
      isRequired: isRequired
    )

    // Конвертируем опции
    if protobufDescriptor.hasOptions {
      _ = try fromProtobufFieldOptions(protobufDescriptor.options)
      // TODO: Добавить поддержку опций в FieldDescriptor
      // for (key, value) in options {
      //   fieldDescriptor.setOption(key: key, value: value)
      // }
    }

    return fieldDescriptor
  }

  // MARK: - Enum Descriptor Conversion

  /// Конвертирует EnumDescriptor в Google_Protobuf_EnumDescriptorProto.
  ///
  /// - Parameter enumDescriptor: Дескриптор enum SwiftProtoReflect.
  /// - Returns: Дескриптор enum в формате Swift Protobuf.
  /// - Throws: Ошибку, если конвертация невозможна.
  public func toProtobufEnumDescriptor(
    from enumDescriptor: EnumDescriptor
  ) throws -> Google_Protobuf_EnumDescriptorProto {
    var proto = Google_Protobuf_EnumDescriptorProto()

    // Устанавливаем имя enum
    proto.name = enumDescriptor.name

    // Конвертируем значения enum
    proto.value = enumDescriptor.allValues().map { enumValue in
      var valueProto = Google_Protobuf_EnumValueDescriptorProto()
      valueProto.name = enumValue.name
      valueProto.number = Int32(enumValue.number)

      // Устанавливаем опции значения, если есть
      if !enumValue.options.isEmpty {
        // В реальной реализации здесь должна быть конвертация опций
        // valueProto.options = ...
      }

      return valueProto
    }

    // Устанавливаем опции enum, если есть
    if !enumDescriptor.options.isEmpty {
      // В реальной реализации здесь должна быть конвертация опций
      // proto.options = ...
    }

    return proto
  }

  /// Создает EnumDescriptor из Google_Protobuf_EnumDescriptorProto.
  ///
  /// - Parameters:.
  ///   - protobufDescriptor: Дескриптор enum в формате Swift Protobuf.
  ///   - parent: Родительский дескриптор (опционально).
  /// - Returns: Дескриптор enum SwiftProtoReflect.
  /// - Throws: Ошибку, если конвертация невозможна.
  public func fromProtobufEnumDescriptor(
    _ protobufDescriptor: Google_Protobuf_EnumDescriptorProto,
    parent: Any? = nil
  ) throws -> EnumDescriptor {
    var enumDescriptor = EnumDescriptor(
      name: protobufDescriptor.name,
      parent: parent
    )

    // Конвертируем значения enum
    for valueProto in protobufDescriptor.value {
      enumDescriptor.addValue(
        EnumDescriptor.EnumValue(
          name: valueProto.name,
          number: Int(valueProto.number)
        )
      )
    }

    return enumDescriptor
  }

  // MARK: - File Descriptor Conversion

  /// Конвертирует FileDescriptor в Google_Protobuf_FileDescriptorProto.
  ///
  /// - Parameter fileDescriptor: Дескриптор файла SwiftProtoReflect.
  /// - Returns: Дескриптор файла в формате Swift Protobuf.
  /// - Throws: Ошибку, если конвертация невозможна.
  public func toProtobufFileDescriptor(
    from fileDescriptor: FileDescriptor
  ) throws -> Google_Protobuf_FileDescriptorProto {
    var proto = Google_Protobuf_FileDescriptorProto()

    // Устанавливаем основные свойства
    proto.name = fileDescriptor.name
    if !fileDescriptor.package.isEmpty {
      proto.package = fileDescriptor.package
    }

    // Конвертируем сообщения
    proto.messageType = try Array(fileDescriptor.messages.values).map { message in
      try toProtobufDescriptor(from: message)
    }

    // Конвертируем enum'ы
    proto.enumType = try Array(fileDescriptor.enums.values).map { enumDesc in
      try toProtobufEnumDescriptor(from: enumDesc)
    }

    // Конвертируем сервисы
    proto.service = try Array(fileDescriptor.services.values).map { service in
      try toProtobufServiceDescriptor(from: service)
    }

    // Устанавливаем зависимости
    proto.dependency = fileDescriptor.dependencies

    return proto
  }

  /// Создает FileDescriptor из Google_Protobuf_FileDescriptorProto.
  ///
  /// - Parameter protobufDescriptor: Дескриптор файла в формате Swift Protobuf.
  /// - Returns: Дескриптор файла SwiftProtoReflect.
  /// - Throws: Ошибку, если конвертация невозможна.
  public func fromProtobufFileDescriptor(
    _ protobufDescriptor: Google_Protobuf_FileDescriptorProto
  ) throws -> FileDescriptor {
    var fileDescriptor = FileDescriptor(
      name: protobufDescriptor.name,
      package: protobufDescriptor.hasPackage ? protobufDescriptor.package : "",
      dependencies: protobufDescriptor.dependency
    )

    // Конвертируем сообщения
    for messageProto in protobufDescriptor.messageType {
      let message = try fromProtobufDescriptor(messageProto, parent: fileDescriptor)
      fileDescriptor.addMessage(message)
    }

    // Конвертируем enum'ы
    for enumProto in protobufDescriptor.enumType {
      let enumDesc = try fromProtobufEnumDescriptor(enumProto, parent: fileDescriptor)
      fileDescriptor.addEnum(enumDesc)
    }

    // Конвертируем сервисы
    for serviceProto in protobufDescriptor.service {
      let service = try fromProtobufServiceDescriptor(serviceProto, parent: fileDescriptor)
      fileDescriptor.addService(service)
    }

    return fileDescriptor
  }

  // MARK: - Service Descriptor Conversion

  /// Конвертирует ServiceDescriptor в Google_Protobuf_ServiceDescriptorProto.
  ///
  /// - Parameter serviceDescriptor: Дескриптор сервиса SwiftProtoReflect.
  /// - Returns: Дескриптор сервиса в формате Swift Protobuf.
  /// - Throws: Ошибку, если конвертация невозможна.
  public func toProtobufServiceDescriptor(
    from serviceDescriptor: ServiceDescriptor
  ) throws -> Google_Protobuf_ServiceDescriptorProto {
    var proto = Google_Protobuf_ServiceDescriptorProto()

    // Устанавливаем имя сервиса
    proto.name = serviceDescriptor.name

    // Конвертируем методы
    proto.method = serviceDescriptor.allMethods().map { method in
      var methodProto = Google_Protobuf_MethodDescriptorProto()
      methodProto.name = method.name
      methodProto.inputType = method.inputType
      methodProto.outputType = method.outputType
      methodProto.clientStreaming = method.clientStreaming
      methodProto.serverStreaming = method.serverStreaming
      return methodProto
    }

    return proto
  }

  /// Создает ServiceDescriptor из Google_Protobuf_ServiceDescriptorProto.
  ///
  /// - Parameters:.
  ///   - protobufDescriptor: Дескриптор сервиса в формате Swift Protobuf.
  ///   - parent: Родительский дескриптор файла (опционально).
  /// - Returns: Дескриптор сервиса SwiftProtoReflect.
  /// - Throws: Ошибку, если конвертация невозможна.
  public func fromProtobufServiceDescriptor(
    _ protobufDescriptor: Google_Protobuf_ServiceDescriptorProto,
    parent: FileDescriptor? = nil
  ) throws -> ServiceDescriptor {
    var serviceDescriptor = ServiceDescriptor(
      name: protobufDescriptor.name,
      parent: parent ?? FileDescriptor(name: "", package: "")
    )

    // Конвертируем методы
    for methodProto in protobufDescriptor.method {
      serviceDescriptor.addMethod(
        ServiceDescriptor.MethodDescriptor(
          name: methodProto.name,
          inputType: methodProto.inputType,
          outputType: methodProto.outputType,
          clientStreaming: methodProto.clientStreaming,
          serverStreaming: methodProto.serverStreaming
        )
      )
    }

    return serviceDescriptor
  }

  // MARK: - Helper Methods

  /// Конвертирует FieldType в Google_Protobuf_FieldDescriptorProto.TypeEnum.
  private func toProtobufFieldType(from fieldType: FieldType) throws -> Google_Protobuf_FieldDescriptorProto.TypeEnum {
    switch fieldType {
    case .double: return .double
    case .float: return .float
    case .int64: return .int64
    case .uint64: return .uint64
    case .int32: return .int32
    case .fixed64: return .fixed64
    case .fixed32: return .fixed32
    case .bool: return .bool
    case .string: return .string
    case .group: return .group
    case .message: return .message
    case .bytes: return .bytes
    case .uint32: return .uint32
    case .enum: return .enum
    case .sfixed32: return .sfixed32
    case .sfixed64: return .sfixed64
    case .sint32: return .sint32
    case .sint64: return .sint64
    }
  }

  /// Конвертирует Google_Protobuf_FieldDescriptorProto.TypeEnum в FieldType.
  private func fromProtobufFieldType(_ protobufType: Google_Protobuf_FieldDescriptorProto.TypeEnum) throws -> FieldType
  {
    switch protobufType {
    case .double: return .double
    case .float: return .float
    case .int64: return .int64
    case .uint64: return .uint64
    case .int32: return .int32
    case .fixed64: return .fixed64
    case .fixed32: return .fixed32
    case .bool: return .bool
    case .string: return .string
    case .group: return .group
    case .message: return .message
    case .bytes: return .bytes
    case .uint32: return .uint32
    case .enum: return .enum
    case .sfixed32: return .sfixed32
    case .sfixed64: return .sfixed64
    case .sint32: return .sint32
    case .sint64: return .sint64
    @unknown default:
      throw DescriptorBridgeError.unsupportedFieldType(-1)
    }
  }

  /// Конвертирует опции сообщения в Google_Protobuf_MessageOptions.
  private func toProtobufMessageOptions(from options: [String: Any]) throws -> Google_Protobuf_MessageOptions {
    // Заглушка для конвертации опций
    // В реальной реализации здесь должна быть полная логика конвертации
    return Google_Protobuf_MessageOptions()
  }

  /// Конвертирует Google_Protobuf_MessageOptions в словарь опций.
  private func fromProtobufMessageOptions(_ options: Google_Protobuf_MessageOptions) throws -> [String: Any] {
    // Заглушка для конвертации опций
    // В реальной реализации здесь должна быть полная логика конвертации
    return [:]
  }

  /// Конвертирует опции поля в Google_Protobuf_FieldOptions.
  private func toProtobufFieldOptions(from options: [String: Any]) throws -> Google_Protobuf_FieldOptions {
    // Заглушка для конвертации опций
    // В реальной реализации здесь должна быть полная логика конвертации
    return Google_Protobuf_FieldOptions()
  }

  /// Конвертирует Google_Protobuf_FieldOptions в словарь опций.
  private func fromProtobufFieldOptions(_ options: Google_Protobuf_FieldOptions) throws -> [String: Any] {
    // Заглушка для конвертации опций
    // В реальной реализации здесь должна быть полная логика конвертации
    return [:]
  }
}

/// Ошибки, возникающие при работе с DescriptorBridge.
public enum DescriptorBridgeError: Error, LocalizedError {
  case unsupportedFieldType(Int)
  case conversionFailed(String)
  case missingRequiredField(String)
  case invalidDescriptorStructure(String)

  public var errorDescription: String? {
    switch self {
    case .unsupportedFieldType(let value):
      return "Неподдерживаемый тип поля: \(value)"
    case .conversionFailed(let details):
      return "Ошибка конвертации: \(details)"
    case .missingRequiredField(let fieldName):
      return "Отсутствует обязательное поле: \(fieldName)"
    case .invalidDescriptorStructure(let details):
      return "Некорректная структура дескриптора: \(details)"
    }
  }
}
