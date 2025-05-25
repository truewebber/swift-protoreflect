//
// ServiceClient.swift
// SwiftProtoReflect
//
// Создан: 2025-05-25
//

import Foundation
import GRPC
import NIOCore
import SwiftProtobuf

/// ServiceClient предоставляет динамический интерфейс для вызова gRPC методов
/// без предварительной генерации клиентского кода.
///
/// Этот класс позволяет:
/// - Динамически вызывать gRPC методы на основе ServiceDescriptor
/// - Работать с DynamicMessage для входных и выходных данных
/// - Поддерживать unary RPC вызовы
/// - Обрабатывать ошибки и метаданные
///
/// ## Пример использования:
///
/// ```swift
/// let client = ServiceClient(channel: channel)
/// 
/// // Unary вызов
/// let request = try factory.createMessage(descriptor: requestDescriptor)
/// try request.set(field: "name", value: "John")
/// 
/// let response = try await client.unaryCall(
///   service: serviceDescriptor,
///   method: "GetUser",
///   request: request
/// )
/// ```
public final class ServiceClient {
  
  // MARK: - Types
  
  /// Опции для вызова gRPC методов
  public struct CallOptions {
    /// Таймаут для вызова
    public let timeout: TimeAmount?
    
    /// Метаданные для отправки с запросом
    public let metadata: [String: String]
    
    /// Создает новые опции вызова
    public init(
      timeout: TimeAmount? = nil,
      metadata: [String: String] = [:]
    ) {
      self.timeout = timeout
      self.metadata = metadata
    }
  }
  
  /// Результат unary вызова
  public struct UnaryCallResult {
    /// Ответное сообщение
    public let response: DynamicMessage
    
    /// Метаданные ответа (упрощенная версия)
    public let metadata: [String: String]
    
    /// Trailing метаданные (упрощенная версия)
    public let trailingMetadata: [String: String]
    
    public init(
      response: DynamicMessage,
      metadata: [String: String] = [:],
      trailingMetadata: [String: String] = [:]
    ) {
      self.response = response
      self.metadata = metadata
      self.trailingMetadata = trailingMetadata
    }
  }
  
  // MARK: - Properties
  
  /// gRPC канал для соединения с сервером
  private let channel: GRPCChannel
  
  /// Фабрика для создания сообщений
  private let messageFactory: MessageFactory
  
  /// Реестр типов для разрешения дескрипторов
  private let typeRegistry: TypeRegistry
  
  // MARK: - Initialization
  
  /// Создает новый ServiceClient
  ///
  /// - Parameters:
  ///   - channel: gRPC канал для соединения
  ///   - messageFactory: Фабрика для создания сообщений (по умолчанию новая)
  ///   - typeRegistry: Реестр типов (по умолчанию новый)
  public init(
    channel: GRPCChannel,
    messageFactory: MessageFactory = MessageFactory(),
    typeRegistry: TypeRegistry = TypeRegistry()
  ) {
    self.channel = channel
    self.messageFactory = messageFactory
    self.typeRegistry = typeRegistry
  }
  
  // MARK: - Unary Calls
  
  /// Выполняет unary gRPC вызов
  ///
  /// - Parameters:
  ///   - service: Дескриптор сервиса
  ///   - method: Имя метода
  ///   - request: Запросное сообщение
  ///   - options: Опции вызова
  /// - Returns: Результат вызова с ответным сообщением
  /// - Throws: ServiceClientError при ошибках
  public func unaryCall(
    service: ServiceDescriptor,
    method methodName: String,
    request: DynamicMessage,
    options: CallOptions = CallOptions()
  ) async throws -> UnaryCallResult {
    // Получаем дескриптор метода
    guard let methodDescriptor = service.method(named: methodName) else {
      throw ServiceClientError.methodNotFound(methodName: methodName, serviceName: service.name)
    }
    
    // Проверяем, что это unary метод
    guard !methodDescriptor.clientStreaming && !methodDescriptor.serverStreaming else {
      throw ServiceClientError.invalidMethodType(
        methodName: methodName,
        expected: "unary",
        actual: getMethodType(methodDescriptor)
      )
    }
    
    // Проверяем совместимость типов
    try validateRequestType(request: request, expectedType: methodDescriptor.inputType)
    
    // Получаем дескриптор ответного типа
    let responseDescriptor = try getResponseDescriptor(outputType: methodDescriptor.outputType)
    
    // Сериализуем запрос
    let requestData = try serializeRequest(request)
    
    // Формируем путь метода
    let path = "/\(service.fullName)/\(methodName)"
    
    // Создаем gRPC вызов с использованием низкоуровневого API
    let call: UnaryCall<GRPCPayloadWrapper, GRPCPayloadWrapper> = channel.makeUnaryCall(
      path: path,
      request: GRPCPayloadWrapper(data: requestData),
      callOptions: createGRPCCallOptions(from: options),
      interceptors: []
    )
    
    // Выполняем вызов и обрабатываем результат
    let grpcResponse = try await call.response.get()
    
    // Десериализуем ответ
    let responseMessage = try deserializeResponse(
      data: grpcResponse.data,
      descriptor: responseDescriptor
    )
    
    return UnaryCallResult(
      response: responseMessage,
      metadata: [:], // Упрощенная версия - пустые метаданные
      trailingMetadata: [:]
    )
  }
  
  // MARK: - Private Helper Methods
  
  /// Получает тип метода в виде строки
  private func getMethodType(_ method: ServiceDescriptor.MethodDescriptor) -> String {
    switch (method.clientStreaming, method.serverStreaming) {
    case (false, false): return "unary"
    case (true, false): return "client streaming"
    case (false, true): return "server streaming"
    case (true, true): return "bidirectional streaming"
    }
  }
  
  /// Проверяет совместимость типа запроса
  private func validateRequestType(request: DynamicMessage, expectedType: String) throws {
    guard request.descriptor.fullName == expectedType else {
      throw ServiceClientError.typeMismatch(
        expected: expectedType,
        actual: request.descriptor.fullName
      )
    }
  }
  
  /// Получает дескриптор ответного типа
  private func getResponseDescriptor(outputType: String) throws -> MessageDescriptor {
    guard let descriptor = typeRegistry.findMessage(named: outputType) else {
      throw ServiceClientError.typeNotFound(typeName: outputType)
    }
    return descriptor
  }
  
  /// Сериализует запросное сообщение
  private func serializeRequest(_ request: DynamicMessage) throws -> Data {
    let serializer = BinarySerializer()
    return try serializer.serialize(request)
  }
  
  /// Десериализует ответное сообщение
  private func deserializeResponse(data: Data, descriptor: MessageDescriptor) throws -> DynamicMessage {
    let deserializer = BinaryDeserializer()
    return try deserializer.deserialize(data, using: descriptor)
  }
  
  /// Создает gRPC опции вызова из наших опций
  private func createGRPCCallOptions(from options: CallOptions) -> GRPC.CallOptions {
    var grpcOptions = GRPC.CallOptions()
    
    if let timeout = options.timeout {
      grpcOptions.timeLimit = .timeout(timeout)
    }
    
    for (key, value) in options.metadata {
      grpcOptions.customMetadata.add(name: key, value: value)
    }
    
    return grpcOptions
  }
}

// MARK: - GRPCPayloadWrapper

/// Обертка для Data чтобы соответствовать протоколу GRPCPayload
internal struct GRPCPayloadWrapper: GRPCPayload {
  let data: Data
  
  init(data: Data) {
    self.data = data
  }
  
  func serialize(into buffer: inout ByteBuffer) throws {
    buffer.writeData(data)
  }
  
  init(serializedByteBuffer: inout ByteBuffer) throws {
    self.data = Data(buffer: serializedByteBuffer)
  }
}

// MARK: - ServiceClientError

/// Ошибки ServiceClient
public enum ServiceClientError: Error, CustomStringConvertible {
  /// Метод не найден в сервисе
  case methodNotFound(methodName: String, serviceName: String)
  
  /// Неверный тип метода
  case invalidMethodType(methodName: String, expected: String, actual: String)
  
  /// Несовпадение типов сообщений
  case typeMismatch(expected: String, actual: String)
  
  /// Тип не найден в реестре
  case typeNotFound(typeName: String)
  
  /// Ошибка сериализации
  case serializationError(underlying: Error)
  
  /// Ошибка десериализации
  case deserializationError(underlying: Error)
  
  /// Ошибка gRPC
  case grpcError(underlying: Error)
  
  public var description: String {
    switch self {
    case .methodNotFound(let methodName, let serviceName):
      return "Method '\(methodName)' not found in service '\(serviceName)'"
    case .invalidMethodType(let methodName, let expected, let actual):
      return "Method '\(methodName)' has type '\(actual)', expected '\(expected)'"
    case .typeMismatch(let expected, let actual):
      return "Type mismatch: expected '\(expected)', got '\(actual)'"
    case .typeNotFound(let typeName):
      return "Type '\(typeName)' not found in registry"
    case .serializationError(let underlying):
      return "Serialization error: \(underlying)"
    case .deserializationError(let underlying):
      return "Deserialization error: \(underlying)"
    case .grpcError(let underlying):
      return "gRPC error: \(underlying)"
    }
  }
}
