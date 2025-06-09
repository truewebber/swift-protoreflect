/**
 * 🌐 SwiftProtoReflect Example: Unary gRPC Calls
 *
 * Описание: Выполнение unary RPC вызовов с использованием динамических сообщений
 * Ключевые концепции: Unary RPC, Request/Response patterns, Call options, Timeouts
 * Сложность: 🚀 Продвинутый
 * Время выполнения: < 25 секунд
 *
 * Что изучите:
 * - Выполнение unary RPC вызовов без статической генерации
 * - Request preparation и response handling
 * - Call options (timeout, metadata, headers)
 * - Error handling для различных gRPC статусов
 * - Performance monitoring и metrics
 * - Batch RPC operations
 *
 * Запуск:
 *   swift run UnaryCalls
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct UnaryCallsExample {
  static func main() throws {
    ExampleUtils.printHeader("Unary gRPC Calls")

    try demonstrateBasicUnaryCall()
    try demonstrateCallOptions()
    try demonstrateErrorHandling()
    try demonstrateBatchCalls()
    try demonstratePerformanceMonitoring()

    ExampleUtils.printSuccess("Unary gRPC Calls example completed!")
    ExampleUtils.printNext([
      "Next: error-handling.swift - Comprehensive gRPC error patterns",
      "Advanced: metadata-options.swift - gRPC metadata and headers",
    ])
  }

  // MARK: - Basic Unary Call

  private static func demonstrateBasicUnaryCall() throws {
    ExampleUtils.printStep(1, "Basic Unary Call - Simple Request/Response")

    // Setup service and client
    let serviceSetup = try createServiceSetup()
    let client = UnaryRPCClient(setup: serviceSetup)

    print("  📞 Performing Basic Unary Calls:")

    // Call 1: GetUser
    print("\n    🔍 GetUser Call:")
    let getUserRequest = try createGetUserRequest(userId: "user_123", setup: serviceSetup)

    let (getUserResponse, getUserTime) = try ExampleUtils.measureTime {
      try client.makeUnaryCall(
        service: "UserService",
        method: "GetUser",
        request: getUserRequest
      )
    }

    ExampleUtils.printTiming("GetUser call", time: getUserTime)
    try printResponseSummary(getUserResponse, label: "User")

    // Call 2: CreateUser
    print("\n    ➕ CreateUser Call:")
    let createUserRequest = try createCreateUserRequest(
      userData: [
        "name": "Alice Johnson",
        "email": "alice@example.com",
        "age": 28,
      ],
      setup: serviceSetup
    )

    let (createUserResponse, createUserTime) = try ExampleUtils.measureTime {
      try client.makeUnaryCall(
        service: "UserService",
        method: "CreateUser",
        request: createUserRequest
      )
    }

    ExampleUtils.printTiming("CreateUser call", time: createUserTime)
    try printResponseSummary(createUserResponse, label: "Created User")
  }

  // MARK: - Call Options

  private static func demonstrateCallOptions() throws {
    ExampleUtils.printStep(2, "Call Options - Timeouts, Headers, and Metadata")

    let serviceSetup = try createServiceSetup()
    let client = UnaryRPCClient(setup: serviceSetup)

    print("  ⚙️  Call Options Demonstration:")

    // Options 1: Custom timeout
    print("\n    ⏰ Custom Timeout:")
    let shortTimeoutOptions = CallOptions(timeout: 0.1)

    let request = try createGetUserRequest(userId: "user_456", setup: serviceSetup)

    let (_, time) = try ExampleUtils.measureTime {
      try client.makeUnaryCall(
        service: "UserService",
        method: "GetUser",
        request: request,
        options: shortTimeoutOptions
      )
    }

    ExampleUtils.printTiming("Timeout call", time: time)
    print("      ✅ Call completed successfully")

    // Options 2: Custom metadata
    print("\n    📝 Custom Metadata:")
    let metadataOptions = CallOptions(
      timeout: 5.0,
      metadata: [
        "request-id": "req_789",
        "client-version": "1.0.0",
      ]
    )

    let (_, metadataTime) = try ExampleUtils.measureTime {
      try client.makeUnaryCall(
        service: "UserService",
        method: "GetUser",
        request: request,
        options: metadataOptions
      )
    }

    ExampleUtils.printTiming("Metadata call", time: metadataTime)
    print("      ✅ Call with metadata completed")
    print("      📊 Request ID: \(metadataOptions.metadata["request-id"] ?? "N/A")")
  }

  // MARK: - Error Handling

  private static func demonstrateErrorHandling() throws {
    ExampleUtils.printStep(3, "Error Handling - gRPC Status Codes and Recovery")

    let serviceSetup = try createServiceSetup()
    let client = UnaryRPCClient(setup: serviceSetup)

    print("  ⚠️  Error Handling Scenarios:")

    // Scenario 1: Invalid request (NOT_FOUND)
    print("\n    🔍 NOT_FOUND Error:")
    let notFoundRequest = try createGetUserRequest(userId: "nonexistent_user", setup: serviceSetup)

    do {
      _ = try client.makeUnaryCall(
        service: "UserService",
        method: "GetUser",
        request: notFoundRequest
      )
      print("      ❌ Expected NOT_FOUND error")
    }
    catch let error as GRPCError {
      print("      ✅ Caught gRPC error: \(error.status)")
      print("      💬 Message: \(error.message)")
    }
    catch {
      print("      ✅ Caught error: \(error)")
    }

    // Scenario 2: Invalid method (UNIMPLEMENTED)
    print("\n    🚫 UNIMPLEMENTED Error:")
    do {
      _ = try client.makeUnaryCall(
        service: "UserService",
        method: "NonExistentMethod",
        request: notFoundRequest
      )
      print("      ❌ Expected UNIMPLEMENTED error")
    }
    catch let error as GRPCError {
      print("      ✅ Caught gRPC error: \(error.status)")
      print("      💬 Message: \(error.message)")
    }
    catch {
      print("      ✅ Caught error: \(error)")
    }
  }

  // MARK: - Batch Calls

  private static func demonstrateBatchCalls() throws {
    ExampleUtils.printStep(4, "Batch Calls - Multiple Concurrent Requests")

    let serviceSetup = try createServiceSetup()
    let client = UnaryRPCClient(setup: serviceSetup)

    print("  📦 Batch Operations:")

    // Batch GetUser calls
    print("\n    👥 Batch GetUser Calls:")
    let userIds = ["user_1", "user_2", "user_3", "user_4", "user_5"]
    var getUserRequests: [DynamicMessage] = []

    for userId in userIds {
      let request = try createGetUserRequest(userId: userId, setup: serviceSetup)
      getUserRequests.append(request)
    }

    let (batchResults, batchTime) = try ExampleUtils.measureTime {
      try client.makeBatchUnaryCall(
        service: "UserService",
        method: "GetUser",
        requests: getUserRequests
      )
    }

    ExampleUtils.printTiming("Batch GetUser (\(userIds.count) requests)", time: batchTime)

    let successCount = batchResults.filter { $0.isSuccess }.count
    let errorCount = batchResults.filter { !$0.isSuccess }.count

    print("      ✅ Successful: \(successCount)/\(userIds.count)")
    print("      ❌ Failed: \(errorCount)/\(userIds.count)")

    // Show individual results
    for (index, result) in batchResults.enumerated() {
      let userId = userIds[index]
      if result.isSuccess {
        print("      👤 \(userId): Success")
      }
      else {
        print("      ❌ \(userId): Failed")
      }
    }
  }

  // MARK: - Performance Monitoring

  private static func demonstratePerformanceMonitoring() throws {
    ExampleUtils.printStep(5, "Performance Monitoring - Metrics and Optimization")

    let serviceSetup = try createServiceSetup()
    let client = UnaryRPCClient(setup: serviceSetup)

    print("  📈 Performance Benchmarking:")

    // Benchmark: Single call latency
    print("\n    ⚡ Single Call Latency:")
    let singleCallIterations = 50
    var singleCallTimes: [TimeInterval] = []

    let request = try createGetUserRequest(userId: "perf_user", setup: serviceSetup)

    for _ in 0..<singleCallIterations {
      let (_, time) = try ExampleUtils.measureTime {
        _ = try client.makeUnaryCall(
          service: "UserService",
          method: "GetUser",
          request: request
        )
      }
      singleCallTimes.append(time)
    }

    let avgLatency = singleCallTimes.reduce(0, +) / Double(singleCallTimes.count)
    let minLatency = singleCallTimes.min() ?? 0
    let maxLatency = singleCallTimes.max() ?? 0

    print("      Average: \(String(format: "%.2f", avgLatency * 1000))ms")
    print("      Min: \(String(format: "%.2f", minLatency * 1000))ms")
    print("      Max: \(String(format: "%.2f", maxLatency * 1000))ms")

    // Performance recommendations
    print("\n    💡 Performance Recommendations:")
    if avgLatency > 0.1 {
      print("      ⚠️  High latency detected - consider connection pooling")
    }
    else {
      print("      ✅ Good latency performance")
    }
    print("      ✅ Use connection keep-alive for multiple calls")
    print("      ✅ Consider batch operations for high volume")
  }

  // MARK: - Helper Functions

  private static func createServiceSetup() throws -> ServiceSetup {
    // Create service descriptors
    var fileDescriptor = FileDescriptor(name: "user_service.proto", package: "example")

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
    createUserRequest.addField(FieldDescriptor(name: "user", number: 1, type: .message, typeName: "example.User"))

    // Register messages
    fileDescriptor.addMessage(userMessage)
    fileDescriptor.addMessage(getUserRequest)
    fileDescriptor.addMessage(createUserRequest)

    // Create type registry
    let typeRegistry = TypeRegistry()
    try typeRegistry.registerFile(fileDescriptor)

    return ServiceSetup(typeRegistry: typeRegistry, fileDescriptor: fileDescriptor)
  }

  private static func createGetUserRequest(userId: String, setup: ServiceSetup) throws -> DynamicMessage {
    guard let requestDescriptor = setup.typeRegistry.findMessage(named: "example.GetUserRequest") else {
      throw UnaryCallError.messageNotFound("GetUserRequest")
    }

    let factory = MessageFactory()
    var request = factory.createMessage(from: requestDescriptor)
    try request.set(userId, forField: "user_id")

    return request
  }

  private static func createCreateUserRequest(userData: [String: Any], setup: ServiceSetup) throws -> DynamicMessage {
    guard let requestDescriptor = setup.typeRegistry.findMessage(named: "example.CreateUserRequest"),
      let userDescriptor = setup.typeRegistry.findMessage(named: "example.User")
    else {
      throw UnaryCallError.messageNotFound("CreateUserRequest or User")
    }

    let factory = MessageFactory()

    // Create User message
    var user = factory.createMessage(from: userDescriptor)
    try user.set(UUID().uuidString, forField: "id")
    if let name = userData["name"] as? String {
      try user.set(name, forField: "name")
    }
    if let email = userData["email"] as? String {
      try user.set(email, forField: "email")
    }
    if let age = userData["age"] as? Int {
      try user.set(Int32(age), forField: "age")
    }

    // Create request
    var request = factory.createMessage(from: requestDescriptor)
    try request.set(user, forField: "user")

    return request
  }

  private static func printResponseSummary(_ response: DynamicMessage, label: String) throws {
    print("      📨 \(label) Response:")
    let id: String? = try response.get(forField: "id") as? String
    let name: String? = try response.get(forField: "name") as? String
    let email: String? = try response.get(forField: "email") as? String

    print("        ID: \(id ?? "N/A")")
    print("        Name: \(name ?? "N/A")")
    print("        Email: \(email ?? "N/A")")
  }
}

// MARK: - Supporting Types

struct ServiceSetup {
  let typeRegistry: TypeRegistry
  let fileDescriptor: FileDescriptor
}

struct CallOptions {
  let timeout: TimeInterval
  let metadata: [String: String]

  init(timeout: TimeInterval = 30.0, metadata: [String: String] = [:]) {
    self.timeout = timeout
    self.metadata = metadata
  }
}

enum BatchResult {
  case success(DynamicMessage)
  case error(Error)

  var isSuccess: Bool {
    switch self {
    case .success: return true
    case .error: return false
    }
  }
}

struct GRPCError: Error {
  let status: String
  let message: String
}

class UnaryRPCClient {
  private let setup: ServiceSetup

  init(setup: ServiceSetup) {
    self.setup = setup
  }

  func makeUnaryCall(service: String, method: String, request: DynamicMessage, options: CallOptions = CallOptions())
    throws -> DynamicMessage
  {
    // Simulate network call
    Thread.sleep(forTimeInterval: Double.random(in: 0.001...0.01))

    // Check for errors
    if method == "NonExistentMethod" {
      throw GRPCError(status: "UNIMPLEMENTED", message: "Method not found")
    }

    if let userId = try? request.get(forField: "user_id") as? String, userId == "nonexistent_user" {
      throw GRPCError(status: "NOT_FOUND", message: "User not found")
    }

    // Create mock response
    return try createMockResponse(for: method, request: request)
  }

  func makeBatchUnaryCall(service: String, method: String, requests: [DynamicMessage]) throws -> [BatchResult] {
    var results: [BatchResult] = []

    for request in requests {
      do {
        let response = try makeUnaryCall(service: service, method: method, request: request)
        results.append(.success(response))
      }
      catch {
        results.append(.error(error))
      }
    }

    return results
  }

  private func createMockResponse(for method: String, request: DynamicMessage) throws -> DynamicMessage {
    guard let userDescriptor = setup.typeRegistry.findMessage(named: "example.User") else {
      throw UnaryCallError.messageNotFound("User")
    }

    let factory = MessageFactory()
    var user = factory.createMessage(from: userDescriptor)
    try user.set(UUID().uuidString, forField: "id")
    try user.set("Mock User", forField: "name")
    try user.set("mock@example.com", forField: "email")
    try user.set(Int32(25), forField: "age")

    return user
  }
}

enum UnaryCallError: Error {
  case messageNotFound(String)
  case invalidRequest(String)
  case networkError(String)
}
