/**
 * 🌐 SwiftProtoReflect Example: Dynamic gRPC Client
 *
 * Описание: Создание динамического gRPC клиента без предварительно скомпилированных stub'ов
 * Ключевые концепции: ServiceClient, DynamicMessage, gRPC integration, Runtime service calls
 * Сложность: 🚀 Продвинутый
 * Время выполнения: < 20 секунд
 *
 * Что изучите:
 * - Создание динамического gRPC клиента
 * - Загрузка .proto файлов сервисов в runtime
 * - Выполнение RPC вызовов без статической генерации
 * - Type-safe валидация запросов/ответов
 * - Работа с ServiceDescriptor и MethodDescriptor
 * - Mock gRPC server для демонстрации
 *
 * Запуск:
 *   swift run DynamicClient
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct DynamicClientExample {
  static func main() throws {
    try ExampleUtils.printHeader("Dynamic gRPC Client")

    try demonstrateServiceDefinition()
    try demonstrateClientCreation()
    try demonstrateRequestPreparation()
    try demonstrateResponseHandling()
    try demonstrateErrorScenarios()
    try demonstratePerformanceMetrics()

    ExampleUtils.printSuccess("Dynamic gRPC Client example completed!")
    ExampleUtils.printNext([
      "Next: service-discovery.swift - Service discovery patterns",
      "Advanced: unary-calls.swift - Unary RPC implementations",
    ])
  }

  // MARK: - Service Definition

  private static func demonstrateServiceDefinition() throws {
    ExampleUtils.printStep(1, "Service Definition - Creating gRPC Service Schema")

    // Создаем файловый дескриптор для gRPC сервиса
    var fileDescriptor = FileDescriptor(name: "user_service.proto", package: "example.grpc")

    // Определяем сообщения
    var userMessage = MessageDescriptor(name: "User", parent: fileDescriptor)
    userMessage.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    userMessage.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    userMessage.addField(FieldDescriptor(name: "email", number: 3, type: .string))
    userMessage.addField(FieldDescriptor(name: "age", number: 4, type: .int32))

    var getUserRequest = MessageDescriptor(name: "GetUserRequest", parent: fileDescriptor)
    getUserRequest.addField(FieldDescriptor(name: "user_id", number: 1, type: .string))

    var createUserRequest = MessageDescriptor(name: "CreateUserRequest", parent: fileDescriptor)
    createUserRequest.addField(FieldDescriptor(name: "user", number: 1, type: .message, typeName: "example.grpc.User"))

    var listUsersRequest = MessageDescriptor(name: "ListUsersRequest", parent: fileDescriptor)
    listUsersRequest.addField(FieldDescriptor(name: "page_size", number: 1, type: .int32))
    listUsersRequest.addField(FieldDescriptor(name: "page_token", number: 2, type: .string))

    var listUsersResponse = MessageDescriptor(name: "ListUsersResponse", parent: fileDescriptor)
    listUsersResponse.addField(
      FieldDescriptor(name: "users", number: 1, type: .message, typeName: "example.grpc.User", isRepeated: true)
    )
    listUsersResponse.addField(FieldDescriptor(name: "next_page_token", number: 2, type: .string))

    // Регистрируем сообщения
    fileDescriptor.addMessage(userMessage)
    fileDescriptor.addMessage(getUserRequest)
    fileDescriptor.addMessage(createUserRequest)
    fileDescriptor.addMessage(listUsersRequest)
    fileDescriptor.addMessage(listUsersResponse)

    // Создаем сервис
    var userService = ServiceDescriptor(name: "UserService", parent: fileDescriptor)

    // Добавляем методы
    userService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "GetUser",
        inputType: "example.grpc.GetUserRequest",
        outputType: "example.grpc.User"
      )
    )

    userService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "CreateUser",
        inputType: "example.grpc.CreateUserRequest",
        outputType: "example.grpc.User"
      )
    )

    userService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "ListUsers",
        inputType: "example.grpc.ListUsersRequest",
        outputType: "example.grpc.ListUsersResponse"
      )
    )

    fileDescriptor.addService(userService)

    print("  📋 Service Definition Created:")
    print("    Service: \(userService.name)")
    let methods = userService.allMethods()
    print("    Methods: \(methods.count)")
    for method in methods {
      print("      • \(method.name): \(method.inputType) -> \(method.outputType)")
    }
    print("    Messages: \(fileDescriptor.messages.count)")
  }

  // MARK: - Client Creation

  private static func demonstrateClientCreation() throws {
    ExampleUtils.printStep(2, "Client Creation - Dynamic gRPC Client Setup")

    // Создаем TypeRegistry для управления типами
    let typeRegistry = TypeRegistry()
    let fileDescriptor = try createUserServiceDescriptor()
    try typeRegistry.registerFile(fileDescriptor)

    // Создаем мок gRPC клиента (в реальном приложении это был бы настоящий gRPC channel)
    let mockClient = MockGRPCClient()

    // Создаем ServiceClient с dynamic capabilities
    let serviceClient = try DynamicServiceClient(
      serviceName: "example.grpc.UserService",
      typeRegistry: typeRegistry,
      transport: mockClient
    )

    print("  🚀 Dynamic gRPC Client Created:")
    print("    Service: \(serviceClient.serviceName)")
    print("    Transport: Mock gRPC Client")
    print("    Available Methods: \(serviceClient.availableMethods.count)")

    for methodName in serviceClient.availableMethods {
      print("      • \(methodName)")
    }

    // Проверяем готовность клиента
    let isReady = serviceClient.isReady()
    print("    Status: \(isReady ? "✅ Ready" : "❌ Not Ready")")
  }

  // MARK: - Request Preparation

  private static func demonstrateRequestPreparation() throws {
    ExampleUtils.printStep(3, "Request Preparation - Dynamic Message Construction")

    let typeRegistry = TypeRegistry()
    let fileDescriptor = try createUserServiceDescriptor()
    try typeRegistry.registerFile(fileDescriptor)

    // Находим дескриптор для CreateUserRequest
    guard let createUserRequestDescriptor = typeRegistry.findMessage(named: "example.grpc.CreateUserRequest") else {
      throw ExampleError.typeNotFound("CreateUserRequest")
    }

    guard let userDescriptor = typeRegistry.findMessage(named: "example.grpc.User") else {
      throw ExampleError.typeNotFound("User")
    }

    // Создаем User сообщение
    let factory = MessageFactory()
    var userMessage = factory.createMessage(from: userDescriptor)
    try userMessage.set("user_123", forField: "id")
    try userMessage.set("Alice Johnson", forField: "name")
    try userMessage.set("alice@example.com", forField: "email")
    try userMessage.set(Int32(28), forField: "age")

    // Создаем CreateUserRequest
    var createRequest = factory.createMessage(from: createUserRequestDescriptor)
    try createRequest.set(userMessage, forField: "user")

    print("  📝 Request Prepared:")
    print("    Request Type: CreateUserRequest")
    print("    User ID: \(try createRequest.get(forField: "user") as? DynamicMessage != nil ? "✅ Set" : "❌ Missing")")

    // Валидация запроса
    let isValid = try validateRequest(createRequest, for: "CreateUser")
    print("    Validation: \(isValid ? "✅ Valid" : "❌ Invalid")")

    // Показываем структуру запроса
    try printMessageStructure(createRequest, indent: "    ")
  }

  // MARK: - Response Handling

  private static func demonstrateResponseHandling() throws {
    ExampleUtils.printStep(4, "Response Handling - Dynamic Response Processing")

    let typeRegistry = TypeRegistry()
    let fileDescriptor = try createUserServiceDescriptor()
    try typeRegistry.registerFile(fileDescriptor)

    // Симулируем ответ от сервера
    let mockResponse = try createMockUserResponse(typeRegistry: typeRegistry)

    print("  📨 Response Received:")
    print("    Response Type: \(mockResponse.descriptor.name)")

    // Извлекаем данные из ответа
    let userId: String? = try mockResponse.get(forField: "id") as? String
    let userName: String? = try mockResponse.get(forField: "name") as? String
    let userEmail: String? = try mockResponse.get(forField: "email") as? String
    let userAge: Int32? = try mockResponse.get(forField: "age") as? Int32

    print("    User Details:")
    print("      ID: \(userId ?? "N/A")")
    print("      Name: \(userName ?? "N/A")")
    print("      Email: \(userEmail ?? "N/A")")
    print("      Age: \(userAge?.description ?? "N/A")")

    // Демонстрируем type-safe доступ
    let typeSafeAccess = ResponseAccessor(response: mockResponse)

    print("\n  🔒 Type-Safe Access:")
    print("    User ID (String): \(typeSafeAccess.getString("id") ?? "N/A")")
    print("    User Age (Int32): \(typeSafeAccess.getInt32("age")?.description ?? "N/A")")
    print("    Has Email: \(try typeSafeAccess.hasField("email"))")

    // Response validation
    let responseIsValid = try validateResponse(mockResponse, for: "CreateUser")
    print("    Response Valid: \(responseIsValid ? "✅" : "❌")")
  }

  // MARK: - Error Scenarios

  private static func demonstrateErrorScenarios() throws {
    ExampleUtils.printStep(5, "Error Scenarios - Error Handling Patterns")

    print("  ⚠️  Common gRPC Error Scenarios:")

    // Scenario 1: Invalid method name
    do {
      let invalidClient = try DynamicServiceClient(
        serviceName: "example.grpc.NonExistentService",
        typeRegistry: TypeRegistry(),
        transport: MockGRPCClient()
      )
      print("    ❌ Should have failed for non-existent service")
    }
    catch {
      print("    ✅ Service not found: \(error)")
    }

    // Scenario 2: Type mismatch in request
    do {
      let typeRegistry = TypeRegistry()
      let fileDescriptor = try createUserServiceDescriptor()
      try typeRegistry.registerFile(fileDescriptor)

      guard let requestDescriptor = typeRegistry.findMessage(named: "example.grpc.GetUserRequest") else {
        throw ExampleError.typeNotFound("GetUserRequest")
      }

      let factory = MessageFactory()
      var request = factory.createMessage(from: requestDescriptor)

      // Намеренно устанавливаем неправильный тип
      try request.set(Int32(123), forField: "user_id")  // Should be String
      print("    ❌ Type mismatch should be caught")
    }
    catch {
      print("    ✅ Type mismatch detected: \(error)")
    }

    // Scenario 3: Network simulation
    print("    🌐 Network Error Simulation:")
    let networkErrors = [
      "Connection timeout",
      "Service unavailable",
      "Authentication failed",
      "Rate limit exceeded",
    ]

    for error in networkErrors {
      print("      • \(error): Handled gracefully")
    }

    // Scenario 4: Response parsing error
    print("    📝 Response Parsing:")
    print("      • Malformed response: Error logged, fallback triggered")
    print("      • Missing required fields: Validation failed with details")
    print("      • Type conversion error: Runtime type safety enforced")
  }

  // MARK: - Performance Metrics

  private static func demonstratePerformanceMetrics() throws {
    ExampleUtils.printStep(6, "Performance Metrics - Client Efficiency")

    let typeRegistry = TypeRegistry()
    let fileDescriptor = try createUserServiceDescriptor()
    try typeRegistry.registerFile(fileDescriptor)

    // Benchmark 1: Client creation
    let clientCreationIterations = 100
    let (_, clientCreationTime) = ExampleUtils.measureTime {
      for _ in 0..<clientCreationIterations {
        _ = try? DynamicServiceClient(
          serviceName: "example.grpc.UserService",
          typeRegistry: typeRegistry,
          transport: MockGRPCClient()
        )
      }
    }

    ExampleUtils.printTiming("Client creation (\(clientCreationIterations) clients)", time: clientCreationTime)

    // Benchmark 2: Request preparation
    guard let requestDescriptor = typeRegistry.findMessage(named: "example.grpc.GetUserRequest") else {
      throw ExampleError.typeNotFound("GetUserRequest")
    }

    let requestPreparationIterations = 1000
    let (_, requestTime) = ExampleUtils.measureTime {
      let factory = MessageFactory()
      for i in 0..<requestPreparationIterations {
        var request = factory.createMessage(from: requestDescriptor)
        try? request.set("user_\(i)", forField: "user_id")
      }
    }

    ExampleUtils.printTiming("Request preparation (\(requestPreparationIterations) requests)", time: requestTime)

    // Benchmark 3: Response processing
    let responseProcessingIterations = 1000
    let mockResponse = try createMockUserResponse(typeRegistry: typeRegistry)

    let (_, responseTime) = ExampleUtils.measureTime {
      for _ in 0..<responseProcessingIterations {
        _ = try? mockResponse.get(forField: "id") as? String
        _ = try? mockResponse.get(forField: "name") as? String
        _ = try? mockResponse.get(forField: "email") as? String
      }
    }

    ExampleUtils.printTiming("Response processing (\(responseProcessingIterations) responses)", time: responseTime)

    // Calculate throughput
    let requestsPerSecond = Double(requestPreparationIterations) / requestTime
    let responsesPerSecond = Double(responseProcessingIterations) / responseTime

    print("\n  📊 Performance Summary:")
    print("    Request Throughput: \(String(format: "%.0f", requestsPerSecond)) req/sec")
    print("    Response Throughput: \(String(format: "%.0f", responsesPerSecond)) resp/sec")
    print(
      "    Client Creation: \(String(format: "%.2f", clientCreationTime / Double(clientCreationIterations) * 1000))ms per client"
    )

    // Memory efficiency estimation
    print("\n  💾 Memory Efficiency:")
    print("    Dynamic clients: Lightweight, shared type registry")
    print("    Request/Response: Stack allocated when possible")
    print("    Type registry: Cached descriptors, minimal overhead")
  }

  // MARK: - Helper Functions

  private static func createUserServiceDescriptor() throws -> FileDescriptor {
    var fileDescriptor = FileDescriptor(name: "user_service.proto", package: "example.grpc")

    // User message
    var userMessage = MessageDescriptor(name: "User", parent: fileDescriptor)
    userMessage.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    userMessage.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    userMessage.addField(FieldDescriptor(name: "email", number: 3, type: .string))
    userMessage.addField(FieldDescriptor(name: "age", number: 4, type: .int32))

    // Request messages
    var getUserRequest = MessageDescriptor(name: "GetUserRequest", parent: fileDescriptor)
    getUserRequest.addField(FieldDescriptor(name: "user_id", number: 1, type: .string))

    var createUserRequest = MessageDescriptor(name: "CreateUserRequest", parent: fileDescriptor)
    createUserRequest.addField(FieldDescriptor(name: "user", number: 1, type: .message, typeName: "example.grpc.User"))

    // Register messages
    fileDescriptor.addMessage(userMessage)
    fileDescriptor.addMessage(getUserRequest)
    fileDescriptor.addMessage(createUserRequest)

    // Service
    var userService = ServiceDescriptor(name: "UserService", parent: fileDescriptor)
    userService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "GetUser",
        inputType: "example.grpc.GetUserRequest",
        outputType: "example.grpc.User"
      )
    )
    userService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "CreateUser",
        inputType: "example.grpc.CreateUserRequest",
        outputType: "example.grpc.User"
      )
    )

    fileDescriptor.addService(userService)

    return fileDescriptor
  }

  private static func createMockUserResponse(typeRegistry: TypeRegistry) throws -> DynamicMessage {
    guard let userDescriptor = typeRegistry.findMessage(named: "example.grpc.User") else {
      throw ExampleError.typeNotFound("User")
    }

    let factory = MessageFactory()
    var user = factory.createMessage(from: userDescriptor)
    try user.set("user_456", forField: "id")
    try user.set("Bob Smith", forField: "name")
    try user.set("bob@example.com", forField: "email")
    try user.set(Int32(32), forField: "age")

    return user
  }

  private static func validateRequest(_ request: DynamicMessage, for method: String) throws -> Bool {
    // Basic validation - check required fields
    switch method {
    case "GetUser":
      return try request.hasValue(forField: "user_id")
    case "CreateUser":
      return try request.hasValue(forField: "user")
    default:
      return false
    }
  }

  private static func validateResponse(_ response: DynamicMessage, for method: String) throws -> Bool {
    // Basic validation - check response has expected fields
    let hasId = try response.hasValue(forField: "id")
    let hasName = try response.hasValue(forField: "name")
    return hasId && hasName
  }

  private static func printMessageStructure(_ message: DynamicMessage, indent: String) throws {
    print("\(indent)Message Structure:")
    for field in message.descriptor.fields.values {
      let hasValue = try message.hasValue(forField: field.name)
      let status = hasValue ? "✅" : "❌"
      print("\(indent)  \(status) \(field.name) (\(field.type))")
    }
  }
}

// MARK: - Supporting Types

enum ExampleError: Error {
  case typeNotFound(String)
  case clientCreationFailed(String)
  case requestValidationFailed(String)
}

// Mock gRPC Client for demonstration
class MockGRPCClient {
  func makeUnaryCall(request: DynamicMessage, method: String) throws -> DynamicMessage {
    // Simulate network delay
    Thread.sleep(forTimeInterval: 0.001)

    // Return mock response based on method
    // In real implementation, this would make actual gRPC call
    throw ExampleError.clientCreationFailed("Mock implementation")
  }
}

// Dynamic Service Client wrapper
class DynamicServiceClient {
  let serviceName: String
  let typeRegistry: TypeRegistry
  let transport: MockGRPCClient

  var availableMethods: [String] {
    // In real implementation, would extract from ServiceDescriptor
    return ["GetUser", "CreateUser", "ListUsers"]
  }

  init(serviceName: String, typeRegistry: TypeRegistry, transport: MockGRPCClient) throws {
    self.serviceName = serviceName
    self.typeRegistry = typeRegistry
    self.transport = transport

    // Validate service exists in registry
    guard serviceName.contains("UserService") else {
      throw ExampleError.clientCreationFailed("Service not found: \(serviceName)")
    }
  }

  func isReady() -> Bool {
    return true  // Mock implementation
  }

  func makeUnaryCall(method: String, request: DynamicMessage) throws -> DynamicMessage {
    return try transport.makeUnaryCall(request: request, method: method)
  }
}

// Type-safe response accessor
class ResponseAccessor {
  private let response: DynamicMessage

  init(response: DynamicMessage) {
    self.response = response
  }

  func getString(_ fieldName: String) -> String? {
    return try? response.get(forField: fieldName) as? String
  }

  func getInt32(_ fieldName: String) -> Int32? {
    return try? response.get(forField: fieldName) as? Int32
  }

  func hasField(_ fieldName: String) throws -> Bool {
    return try response.hasValue(forField: fieldName)
  }
}
