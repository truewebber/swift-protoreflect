/**
 * 🌐 SwiftProtoReflect Example: gRPC Service Discovery
 *
 * Description: Dynamic discovery of available gRPC services and their methods at runtime
 * Key concepts: Service introspection, Method discovery, Protocol reflection
 * Complexity: 🚀 Advanced
 * Execution time: < 15 seconds
 *
 * What you'll learn:
 * - Discovery of available gRPC services
 * - Analysis of service methods and their signatures
 * - Dynamic service registry construction
 * - Service capability detection
 * - Reflection-based service exploration
 * - Service health checking и availability
 *
 * Run:
 *   swift run ServiceDiscovery
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct ServiceDiscoveryExample {
  static func main() throws {
    ExampleUtils.printHeader("gRPC Service Discovery")

    try demonstrateServiceRegistry()
    try demonstrateServiceIntrospection()
    try demonstrateMethodDiscovery()
    try demonstrateServiceCapabilities()
    try demonstrateHealthChecking()
    try demonstrateServiceCatalog()

    ExampleUtils.printSuccess("gRPC Service Discovery example completed!")
    ExampleUtils.printNext([
      "Next: unary-calls.swift - Unary RPC call implementations",
      "Advanced: error-handling.swift - gRPC error patterns",
    ])
  }

  // MARK: - Service Registry

  private static func demonstrateServiceRegistry() throws {
    ExampleUtils.printStep(1, "Service Registry - Dynamic Service Registration")

    let serviceRegistry = ServiceRegistry()

    // Register множественные сервисы
    let services = try createSampleServices()

    for service in services {
      try serviceRegistry.registerService(service)
    }

    print("  📋 Registered Services:")
    for serviceName in serviceRegistry.getAllServiceNames() {
      let serviceInfo = try serviceRegistry.getServiceInfo(serviceName)
      print("    • \(serviceName)")
      print("      Package: \(serviceInfo.package)")
      print("      Methods: \(serviceInfo.methodCount)")
      print("      Status: \(serviceInfo.isAvailable ? "🟢 Available" : "🔴 Unavailable")")
    }

    print("\n  📊 Registry Statistics:")
    print("    Total Services: \(serviceRegistry.serviceCount)")
    print("    Available Services: \(serviceRegistry.availableServiceCount)")
    print("    Total Methods: \(serviceRegistry.totalMethodCount)")
  }

  // MARK: - Service Introspection

  private static func demonstrateServiceIntrospection() throws {
    ExampleUtils.printStep(2, "Service Introspection - Deep Service Analysis")

    let services = try createSampleServices()
    let analyzer = ServiceAnalyzer()

    for serviceDescriptor in services {
      let analysis = try analyzer.analyzeService(serviceDescriptor)

      print("  🔍 Service Analysis: \(serviceDescriptor.name)")
      print("    Full Name: \(analysis.fullName)")
      print("    Package: \(analysis.packageName)")
      print("    Method Count: \(analysis.methodCount)")
      print("    Message Types: \(analysis.messageTypes.count)")

      // Service complexity analysis
      print("    Complexity Score: \(analysis.complexityScore)/10")
      print("    RPC Patterns:")
      for pattern in analysis.rpcPatterns {
        print("      • \(pattern)")
      }

      // Dependency analysis
      if !analysis.dependencies.isEmpty {
        print("    Dependencies:")
        for dependency in analysis.dependencies {
          print("      • \(dependency)")
        }
      }

      print("")
    }
  }

  // MARK: - Method Discovery

  private static func demonstrateMethodDiscovery() throws {
    ExampleUtils.printStep(3, "Method Discovery - RPC Method Analysis")

    let services = try createSampleServices()
    let methodExplorer = MethodExplorer()

    for serviceDescriptor in services {
      print("  🎯 Service: \(serviceDescriptor.name)")

      for method in serviceDescriptor.allMethods() {
        let methodInfo = try methodExplorer.exploreMethod(method, in: serviceDescriptor)

        print("    📞 Method: \(method.name)")
        print("      Input: \(methodInfo.inputTypeName)")
        print("      Output: \(methodInfo.outputTypeName)")
        print("      Pattern: \(methodInfo.rpcPattern)")
        print("      Complexity: \(methodInfo.complexityLevel)")
        print("")
      }
    }
  }

  // MARK: - Service Capabilities

  private static func demonstrateServiceCapabilities() throws {
    ExampleUtils.printStep(4, "Service Capabilities - Feature Detection")

    let services = try createSampleServices()
    let capabilityDetector = ServiceCapabilityDetector()

    print("  🎛  Service Capabilities Matrix:")
    print("    \("Service".padding(toLength: 20, withPad: " ", startingAt: 0)) | CRUD | Auth | Pagn | Strm | Batch")
    print("    \(String(repeating: "-", count: 70))")

    for serviceDescriptor in services {
      let capabilities = try capabilityDetector.detectCapabilities(serviceDescriptor)

      let crudSymbol = capabilities.supportsCRUD ? "✅" : "❌"
      let authSymbol = capabilities.supportsAuthentication ? "✅" : "❌"
      let paginationSymbol = capabilities.supportsPagination ? "✅" : "❌"
      let streamingSymbol = capabilities.supportsStreaming ? "✅" : "❌"
      let batchSymbol = capabilities.supportsBatchOperations ? "✅" : "❌"

      let serviceName = serviceDescriptor.name.padding(toLength: 20, withPad: " ", startingAt: 0)
      print(
        "    \(serviceName) | \(crudSymbol)   | \(authSymbol)  | \(paginationSymbol)   | \(streamingSymbol)   | \(batchSymbol)"
      )

      // Detailed capabilities analysis
      if !capabilities.specialFeatures.isEmpty {
        print("      Special Features: \(capabilities.specialFeatures.joined(separator: ", "))")
      }
    }

    print("\n  📈 Capability Trends:")
    let allCapabilities = try services.map { try capabilityDetector.detectCapabilities($0) }

    let crudSupport = allCapabilities.filter { $0.supportsCRUD }.count
    let authSupport = allCapabilities.filter { $0.supportsAuthentication }.count
    let paginationSupport = allCapabilities.filter { $0.supportsPagination }.count

    print(
      "    CRUD Support: \(crudSupport)/\(services.count) services (\(Int(Double(crudSupport)/Double(services.count)*100))%)"
    )
    print(
      "    Auth Support: \(authSupport)/\(services.count) services (\(Int(Double(authSupport)/Double(services.count)*100))%)"
    )
    print(
      "    Pagination Support: \(paginationSupport)/\(services.count) services (\(Int(Double(paginationSupport)/Double(services.count)*100))%)"
    )
  }

  // MARK: - Health Checking

  private static func demonstrateHealthChecking() throws {
    ExampleUtils.printStep(5, "Health Checking - Service Availability Monitoring")

    let services = try createSampleServices()
    let healthChecker = ServiceHealthChecker()

    print("  🏥 Service Health Status:")

    var healthResults: [(String, ServiceHealthStatus)] = []

    let (_, totalCheckTime) = ExampleUtils.measureTime {
      for serviceDescriptor in services {
        let healthStatus = healthChecker.checkHealth(serviceDescriptor)
        healthResults.append((serviceDescriptor.name, healthStatus))
      }
    }

    for (serviceName, health) in healthResults {
      let statusIcon = health.isHealthy ? "🟢" : "🔴"
      print("    \(statusIcon) \(serviceName)")
      print("      Status: \(health.status)")
      print("      Response Time: \(String(format: "%.1f", health.responseTime * 1000))ms")
      print("      Availability: \(String(format: "%.1f", health.availability * 100))%")

      if !health.issues.isEmpty {
        print("      Issues:")
        for issue in health.issues {
          print("        • \(issue)")
        }
      }
    }

    ExampleUtils.printTiming("Health check for \(services.count) services", time: totalCheckTime)

    // Aggregate health metrics
    let healthyServices = healthResults.filter { $0.1.isHealthy }.count
    let avgResponseTime = healthResults.map { $0.1.responseTime }.reduce(0, +) / Double(healthResults.count)
    let avgAvailability = healthResults.map { $0.1.availability }.reduce(0, +) / Double(healthResults.count)

    print("\n  📊 Aggregate Health Metrics:")
    print(
      "    Healthy Services: \(healthyServices)/\(services.count) (\(Int(Double(healthyServices)/Double(services.count)*100))%)"
    )
    print("    Average Response Time: \(String(format: "%.1f", avgResponseTime * 1000))ms")
    print("    Average Availability: \(String(format: "%.1f", avgAvailability * 100))%")
  }

  // MARK: - Service Catalog

  private static func demonstrateServiceCatalog() throws {
    ExampleUtils.printStep(6, "Service Catalog - Comprehensive Service Directory")

    let services = try createSampleServices()
    let catalogBuilder = ServiceCatalogBuilder()

    let catalog = try catalogBuilder.buildCatalog(from: services)

    print("  📚 Service Catalog:")
    print("    Total Services: \(catalog.serviceCount)")
    print("    Total Endpoints: \(catalog.endpointCount)")
    print("    Packages: \(catalog.packageCount)")

    // Group services by package
    for (packageName, packageServices) in catalog.servicesByPackage {
      print("\n    📦 Package: \(packageName)")

      for service in packageServices {
        print("      🔧 \(service.name)")
        print("        Endpoints: \(service.endpoints.count)")
        print("        Version: \(service.version)")
        print("        Tags: \(service.tags.joined(separator: ", "))")

        // Show top endpoints
        for endpoint in service.endpoints.prefix(2) {
          print("          • \(endpoint.method): \(endpoint.path)")
        }
        if service.endpoints.count > 2 {
          print("          ... and \(service.endpoints.count - 2) more endpoints")
        }
      }
    }

    // Service statistics
    print("\n  📈 Catalog Statistics:")
    let methodCounts = catalog.servicesByPackage.values.flatMap { $0 }.map { $0.endpoints.count }
    let avgMethodsPerService = Double(methodCounts.reduce(0, +)) / Double(methodCounts.count)
    let maxMethods = methodCounts.max() ?? 0
    let minMethods = methodCounts.min() ?? 0

    print("    Average Methods/Service: \(String(format: "%.1f", avgMethodsPerService))")
    print("    Most Complex Service: \(maxMethods) methods")
    print("    Simplest Service: \(minMethods) methods")

    // Search functionality demo
    print("\n  🔎 Search Functionality:")
    let searchTerms = ["User", "Create", "List"]

    for term in searchTerms {
      let results = catalog.search(term: term)
      print("    '\(term)': \(results.count) results")
      for result in results.prefix(2) {
        print("      • \(result.serviceName).\(result.methodName)")
      }
    }
  }

  // MARK: - Helper Functions

  private static func createSampleServices() throws -> [ServiceDescriptor] {
    var services: [ServiceDescriptor] = []

    // Service 1: UserService
    let userService = try createUserService()
    services.append(userService)

    // Service 2: OrderService
    let orderService = try createOrderService()
    services.append(orderService)

    // Service 3: PaymentService
    let paymentService = try createPaymentService()
    services.append(paymentService)

    // Service 4: NotificationService
    let notificationService = try createNotificationService()
    services.append(notificationService)

    return services
  }

  private static func createUserService() throws -> ServiceDescriptor {
    var fileDescriptor = FileDescriptor(name: "user.proto", package: "example.user")

    var userMessage = MessageDescriptor(name: "User", parent: fileDescriptor)
    userMessage.addField(FieldDescriptor(name: "id", number: 1, type: .string))
    userMessage.addField(FieldDescriptor(name: "name", number: 2, type: .string))
    userMessage.addField(FieldDescriptor(name: "email", number: 3, type: .string))

    fileDescriptor.addMessage(userMessage)

    var userService = ServiceDescriptor(name: "UserService", parent: fileDescriptor)
    userService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "GetUser",
        inputType: "GetUserRequest",
        outputType: "User"
      )
    )
    userService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "CreateUser",
        inputType: "CreateUserRequest",
        outputType: "User"
      )
    )
    userService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "UpdateUser",
        inputType: "UpdateUserRequest",
        outputType: "User"
      )
    )
    userService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "DeleteUser",
        inputType: "DeleteUserRequest",
        outputType: "Empty"
      )
    )
    userService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "ListUsers",
        inputType: "ListUsersRequest",
        outputType: "ListUsersResponse"
      )
    )

    return userService
  }

  private static func createOrderService() throws -> ServiceDescriptor {
    let fileDescriptor = FileDescriptor(name: "order.proto", package: "example.order")

    var orderService = ServiceDescriptor(name: "OrderService", parent: fileDescriptor)
    orderService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "CreateOrder",
        inputType: "CreateOrderRequest",
        outputType: "Order"
      )
    )
    orderService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "GetOrder",
        inputType: "GetOrderRequest",
        outputType: "Order"
      )
    )
    orderService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "UpdateOrder",
        inputType: "UpdateOrderRequest",
        outputType: "Order"
      )
    )
    orderService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "ListOrders",
        inputType: "ListOrdersRequest",
        outputType: "ListOrdersResponse"
      )
    )

    return orderService
  }

  private static func createPaymentService() throws -> ServiceDescriptor {
    let fileDescriptor = FileDescriptor(name: "payment.proto", package: "example.payment")

    var paymentService = ServiceDescriptor(name: "PaymentService", parent: fileDescriptor)
    paymentService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "ProcessPayment",
        inputType: "ProcessPaymentRequest",
        outputType: "PaymentResult"
      )
    )
    paymentService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "RefundPayment",
        inputType: "RefundPaymentRequest",
        outputType: "RefundResult"
      )
    )

    return paymentService
  }

  private static func createNotificationService() throws -> ServiceDescriptor {
    let fileDescriptor = FileDescriptor(name: "notification.proto", package: "example.notification")

    var notificationService = ServiceDescriptor(name: "NotificationService", parent: fileDescriptor)
    notificationService.addMethod(
      ServiceDescriptor.MethodDescriptor(
        name: "SendNotification",
        inputType: "SendNotificationRequest",
        outputType: "NotificationResult"
      )
    )

    return notificationService
  }
}

// MARK: - Supporting Classes

class ServiceRegistry {
  private var services: [String: ServiceInfo] = [:]

  func registerService(_ serviceDescriptor: ServiceDescriptor) throws {
    let info = ServiceInfo(
      name: serviceDescriptor.name,
      package: serviceDescriptor.fullName.components(separatedBy: ".").dropLast().joined(separator: "."),
      methodCount: serviceDescriptor.allMethods().count,
      isAvailable: true
    )
    services[serviceDescriptor.name] = info
  }

  func getAllServiceNames() -> [String] {
    return Array(services.keys).sorted()
  }

  func getServiceInfo(_ name: String) throws -> ServiceInfo {
    guard let info = services[name] else {
      throw ServiceDiscoveryError.serviceNotFound(name)
    }
    return info
  }

  var serviceCount: Int { services.count }
  var availableServiceCount: Int { services.values.filter { $0.isAvailable }.count }
  var totalMethodCount: Int { services.values.map { $0.methodCount }.reduce(0, +) }
}

struct ServiceInfo {
  let name: String
  let package: String
  let methodCount: Int
  let isAvailable: Bool
}

class ServiceAnalyzer {
  func analyzeService(_ serviceDescriptor: ServiceDescriptor) throws -> ServiceAnalysis {
    let fullName = serviceDescriptor.fullName
    let packageName = fullName.components(separatedBy: ".").dropLast().joined(separator: ".")

    let methodCount = serviceDescriptor.allMethods().count
    let messageTypes = extractMessageTypes(from: serviceDescriptor)
    let rpcPatterns = analyzeRPCPatterns(serviceDescriptor)
    let dependencies = extractDependencies(from: serviceDescriptor)
    let complexityScore = calculateComplexityScore(serviceDescriptor)

    return ServiceAnalysis(
      fullName: fullName,
      packageName: packageName,
      methodCount: methodCount,
      messageTypes: messageTypes,
      rpcPatterns: rpcPatterns,
      dependencies: dependencies,
      complexityScore: complexityScore
    )
  }

  private func extractMessageTypes(from service: ServiceDescriptor) -> [String] {
    var types: Set<String> = []
    for method in service.allMethods() {
      types.insert(method.inputType)
      types.insert(method.outputType)
    }
    return Array(types)
  }

  private func analyzeRPCPatterns(_ service: ServiceDescriptor) -> [String] {
    var patterns: [String] = []

    let methodNames = service.allMethods().map { $0.name.lowercased() }

    if methodNames.contains(where: { $0.contains("create") }) { patterns.append("Create") }
    if methodNames.contains(where: { $0.contains("get") || $0.contains("read") }) { patterns.append("Read") }
    if methodNames.contains(where: { $0.contains("update") }) { patterns.append("Update") }
    if methodNames.contains(where: { $0.contains("delete") }) { patterns.append("Delete") }
    if methodNames.contains(where: { $0.contains("list") }) { patterns.append("List") }

    return patterns
  }

  private func extractDependencies(from service: ServiceDescriptor) -> [String] {
    // Simplified dependency extraction
    return []
  }

  private func calculateComplexityScore(_ service: ServiceDescriptor) -> Int {
    let methodCount = service.allMethods().count
    let baseScore = min(methodCount, 5)  // 0-5 for method count
    let bonusScore = methodCount > 5 ? min(methodCount - 5, 5) : 0  // 0-5 bonus for complexity
    return baseScore + bonusScore
  }
}

struct ServiceAnalysis {
  let fullName: String
  let packageName: String
  let methodCount: Int
  let messageTypes: [String]
  let rpcPatterns: [String]
  let dependencies: [String]
  let complexityScore: Int
}

class MethodExplorer {
  func exploreMethod(_ method: ServiceDescriptor.MethodDescriptor, in service: ServiceDescriptor) throws
    -> MethodExplorationResult
  {
    let inputTypeName = method.inputType
    let outputTypeName = method.outputType
    let rpcPattern = determineRPCPattern(method.name)
    let complexityLevel = determineComplexityLevel(method)

    // In real implementation, would resolve actual message descriptors
    let inputFields: [FieldInfo]? = nil
    let outputFields: [FieldInfo]? = nil

    return MethodExplorationResult(
      inputTypeName: inputTypeName,
      outputTypeName: outputTypeName,
      rpcPattern: rpcPattern,
      complexityLevel: complexityLevel,
      inputFields: inputFields,
      outputFields: outputFields
    )
  }

  private func determineRPCPattern(_ methodName: String) -> String {
    let name = methodName.lowercased()
    if name.contains("create") { return "Create" }
    if name.contains("get") || name.contains("read") { return "Read" }
    if name.contains("update") { return "Update" }
    if name.contains("delete") { return "Delete" }
    if name.contains("list") { return "List" }
    return "Custom"
  }

  private func determineComplexityLevel(_ method: ServiceDescriptor.MethodDescriptor) -> String {
    // Simplified complexity determination
    return "Medium"
  }
}

struct MethodExplorationResult {
  let inputTypeName: String
  let outputTypeName: String
  let rpcPattern: String
  let complexityLevel: String
  let inputFields: [FieldInfo]?
  let outputFields: [FieldInfo]?
}

struct FieldInfo {
  let name: String
  let type: String
}

class ServiceCapabilityDetector {
  func detectCapabilities(_ service: ServiceDescriptor) throws -> ServiceCapabilities {
    let methodNames = service.allMethods().map { $0.name.lowercased() }

    let supportsCRUD = detectCRUDSupport(methodNames)
    let supportsAuthentication = detectAuthSupport(methodNames)
    let supportsPagination = detectPaginationSupport(methodNames)
    let supportsStreaming = false  // Simplified
    let supportsBatchOperations = detectBatchSupport(methodNames)
    let specialFeatures = detectSpecialFeatures(methodNames)

    return ServiceCapabilities(
      supportsCRUD: supportsCRUD,
      supportsAuthentication: supportsAuthentication,
      supportsPagination: supportsPagination,
      supportsStreaming: supportsStreaming,
      supportsBatchOperations: supportsBatchOperations,
      specialFeatures: specialFeatures
    )
  }

  private func detectCRUDSupport(_ methodNames: [String]) -> Bool {
    let hasCreate = methodNames.contains { $0.contains("create") }
    let hasRead = methodNames.contains { $0.contains("get") || $0.contains("read") }
    let hasUpdate = methodNames.contains { $0.contains("update") }
    let hasDelete = methodNames.contains { $0.contains("delete") }

    return hasCreate && hasRead && (hasUpdate || hasDelete)
  }

  private func detectAuthSupport(_ methodNames: [String]) -> Bool {
    return methodNames.contains { $0.contains("auth") || $0.contains("login") || $0.contains("token") }
  }

  private func detectPaginationSupport(_ methodNames: [String]) -> Bool {
    return methodNames.contains { $0.contains("list") }
  }

  private func detectBatchSupport(_ methodNames: [String]) -> Bool {
    return methodNames.contains { $0.contains("batch") || $0.contains("bulk") }
  }

  private func detectSpecialFeatures(_ methodNames: [String]) -> [String] {
    var features: [String] = []

    if methodNames.contains(where: { $0.contains("search") }) {
      features.append("Search")
    }
    if methodNames.contains(where: { $0.contains("export") }) {
      features.append("Export")
    }
    if methodNames.contains(where: { $0.contains("import") }) {
      features.append("Import")
    }

    return features
  }
}

struct ServiceCapabilities {
  let supportsCRUD: Bool
  let supportsAuthentication: Bool
  let supportsPagination: Bool
  let supportsStreaming: Bool
  let supportsBatchOperations: Bool
  let specialFeatures: [String]
}

class ServiceHealthChecker {
  func checkHealth(_ service: ServiceDescriptor) -> ServiceHealthStatus {
    // Simulate health check
    let responseTime = Double.random(in: 0.001...0.1)
    let availability = Double.random(in: 0.85...1.0)
    let isHealthy = availability > 0.9 && responseTime < 0.05

    let status = isHealthy ? "Healthy" : "Degraded"
    let issues = isHealthy ? [] : ["High response time", "Intermittent failures"]
    let metrics = [
      "uptime": "99.5%",
      "requests_per_second": String(Int.random(in: 10...1000)),
    ]

    return ServiceHealthStatus(
      isHealthy: isHealthy,
      status: status,
      responseTime: responseTime,
      availability: availability,
      issues: issues,
      metrics: metrics
    )
  }
}

struct ServiceHealthStatus {
  let isHealthy: Bool
  let status: String
  let responseTime: TimeInterval
  let availability: Double
  let issues: [String]
  let metrics: [String: String]
}

class ServiceCatalogBuilder {
  func buildCatalog(from services: [ServiceDescriptor]) throws -> ServiceCatalog {
    var servicesByPackage: [String: [CatalogService]] = [:]

    for serviceDescriptor in services {
      let packageName =
        serviceDescriptor.fullName.components(separatedBy: ".").dropLast().joined(separator: ".").isEmpty
        ? "default" : serviceDescriptor.fullName.components(separatedBy: ".").dropLast().joined(separator: ".")
      let catalogService = buildCatalogService(from: serviceDescriptor)

      if servicesByPackage[packageName] == nil {
        servicesByPackage[packageName] = []
      }
      servicesByPackage[packageName]?.append(catalogService)
    }

    return ServiceCatalog(servicesByPackage: servicesByPackage)
  }

  private func buildCatalogService(from descriptor: ServiceDescriptor) -> CatalogService {
    let endpoints = descriptor.allMethods().map { method in
      CatalogEndpoint(
        method: method.name,
        path: "/\(descriptor.name)/\(method.name)",
        inputType: method.inputType,
        outputType: method.outputType
      )
    }

    return CatalogService(
      name: descriptor.name,
      version: "1.0.0",
      endpoints: endpoints,
      tags: ["auto-generated", "grpc"]
    )
  }
}

struct ServiceCatalog {
  let servicesByPackage: [String: [CatalogService]]

  var serviceCount: Int {
    servicesByPackage.values.map { $0.count }.reduce(0, +)
  }

  var endpointCount: Int {
    servicesByPackage.values.flatMap { $0 }.map { $0.endpoints.count }.reduce(0, +)
  }

  var packageCount: Int {
    servicesByPackage.count
  }

  func search(term: String) -> [SearchResult] {
    var results: [SearchResult] = []

    for (_, services) in servicesByPackage {
      for service in services {
        // Search in service name
        if service.name.lowercased().contains(term.lowercased()) {
          for endpoint in service.endpoints {
            results.append(
              SearchResult(
                serviceName: service.name,
                methodName: endpoint.method,
                relevance: 1.0
              )
            )
          }
        }

        // Search in method names
        for endpoint in service.endpoints where endpoint.method.lowercased().contains(term.lowercased()) {
          results.append(
            SearchResult(
              serviceName: service.name,
              methodName: endpoint.method,
              relevance: 0.8
            )
          )
        }
      }
    }

    return results.sorted { $0.relevance > $1.relevance }
  }
}

struct CatalogService {
  let name: String
  let version: String
  let endpoints: [CatalogEndpoint]
  let tags: [String]
}

struct CatalogEndpoint {
  let method: String
  let path: String
  let inputType: String
  let outputType: String
}

struct SearchResult {
  let serviceName: String
  let methodName: String
  let relevance: Double
}

enum ServiceDiscoveryError: Error {
  case serviceNotFound(String)
  case methodNotFound(String)
  case analysisError(String)
}
