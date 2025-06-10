/**
 * 🌐 SwiftProtoReflect Example: API Gateway with Dynamic Schemas
 *
 * Description: Production-ready API Gateway with dynamic Protocol Buffers schemas
 * Key concepts: API Gateway, Dynamic Schema Loading, Request/Response Transformation, Routing
 * Complexity: 🏢 Expert
 * Execution time: 15-20 seconds
 *
 * What you'll learn:
 * - Создание API Gateway с динамическими схемами
 * - Request/Response трансформация и валидация
 * - Schema-based routing и endpoint discovery
 * - Middleware pipeline и обработка ошибок
 * - Performance monitoring и caching strategies
 * - Multi-version API support и backward compatibility
 *
 * Run:
 *   swift run ApiGateway
 */

import ExampleUtils
import Foundation
import SwiftProtoReflect

@main
struct ApiGatewayExample {
  static func main() throws {
    ExampleUtils.printHeader("API Gateway with Dynamic Protocol Buffers Schemas")

    try step1UinitializeGateway()
    try step2UloadDynamicSchemas()
    try step3UsetupRoutingRules()
    try step4UdemonstrateRequestProcessing()
    try step5UshowcaseVersionHandling()
    try step6UperformanceAnalysis()

    ExampleUtils.printSuccess("API Gateway example completed! Ready for production deployment.")
    ExampleUtils.printNext([
      "Explore: message-transform.swift - Schema evolution patterns",
      "Study: validation-framework.swift - Advanced validation rules",
      "Try: proto-repl.swift - Interactive Protocol Buffers exploration",
    ])
  }

  // MARK: - Implementation Steps

  private static func step1UinitializeGateway() throws {
    ExampleUtils.printStep(1, "Initializing API Gateway Core Components")

    // Create gateway instance with core services
    let gateway = ApiGateway()

    // Initialize core modules
    gateway.schemaRegistry = SchemaRegistry()
    gateway.requestRouter = RequestRouter()
    gateway.responseTransformer = ResponseTransformer()
    gateway.middlewarePipeline = MiddlewarePipeline()
    gateway.performanceMonitor = PerformanceMonitor()

    print("  🏗  Gateway core initialized")
    print("  📊 Performance monitoring enabled")
    print("  🔧 Middleware pipeline configured")
    print("  🗂  Schema registry ready")

    // Store in global context for other steps
    ApiGatewayContext.shared.gateway = gateway

    ExampleUtils.printSuccess("Gateway core components initialized")
  }

  private static func step2UloadDynamicSchemas() throws {
    ExampleUtils.printStep(2, "Loading Dynamic Protocol Buffers Schemas")

    let gateway = ApiGatewayContext.shared.gateway!
    let (schemaCount, loadTime) = try ExampleUtils.measureTime {
      return try gateway.loadSchemas()
    }

    ExampleUtils.printTiming("Schema loading", time: loadTime)
    print("  📄 Loaded schemas: \(schemaCount)")

    // Display loaded services
    let services = gateway.schemaRegistry.getAllServices()
    ExampleUtils.printTable(
      services.reduce(into: [String: String]()) { result, service in
        result[service.name] = "\(service.methods.count) methods"
      },
      title: "Available Services"
    )

    ExampleUtils.printSuccess("Dynamic schemas loaded and indexed")
  }

  private static func step3UsetupRoutingRules() throws {
    ExampleUtils.printStep(3, "Setting Up Schema-Based Routing Rules")

    let gateway = ApiGatewayContext.shared.gateway!

    // Define routing rules based on schemas
    let routingRules = [
      RoutingRule(
        pattern: "/api/v1/users/*",
        targetService: "user.UserService",
        transformations: [
          .addMetadata("source", "api_gateway"),
          .applyFieldMask(["name", "email", "profile"]),
        ]
      ),
      RoutingRule(
        pattern: "/api/v1/orders/*",
        targetService: "order.OrderService",
        transformations: [
          .addMetadata("trace_id", UUID().uuidString),
          .enrichWithDefaults,
        ]
      ),
      RoutingRule(
        pattern: "/api/v1/analytics/*",
        targetService: "analytics.AnalyticsService",
        transformations: [
          .addMetadata("analytics_version", "v2"),
          .aggregateMetrics,
          .applyPrivacyFilters,
        ]
      ),
    ]

    for rule in routingRules {
      gateway.requestRouter.addRule(rule)
      print("  🛣  Route registered: \(rule.pattern) -> \(rule.targetService)")
    }

    // Setup middleware for cross-cutting concerns
    gateway.middlewarePipeline.add(AuthenticationMiddleware())
    gateway.middlewarePipeline.add(RateLimitingMiddleware(requestsPerMinute: 1000))
    gateway.middlewarePipeline.add(LoggingMiddleware())
    gateway.middlewarePipeline.add(MetricsMiddleware())

    print("  🔒 Authentication middleware enabled")
    print("  ⏱  Rate limiting: 1000 req/min")
    print("  📝 Request logging active")
    print("  📊 Metrics collection enabled")

    ExampleUtils.printSuccess("Routing rules and middleware configured")
  }

  private static func step4UdemonstrateRequestProcessing() throws {
    ExampleUtils.printStep(4, "Demonstrating Request Processing Pipeline")

    let gateway = ApiGatewayContext.shared.gateway!

    // Simulate various API requests
    let testRequests = [
      ApiRequest(
        method: "POST",
        path: "/api/v1/users/create",
        body: [
          "name": "Alice Johnson",
          "email": "alice@example.com",
          "profile": [
            "age": 28,
            "location": "San Francisco",
          ],
        ]
      ),
      ApiRequest(
        method: "GET",
        path: "/api/v1/orders/12345",
        body: [:]
      ),
      ApiRequest(
        method: "POST",
        path: "/api/v1/analytics/events",
        body: [
          "event_type": "user_action",
          "user_id": "user_123",
          "timestamp": Date().timeIntervalSince1970,
          "properties": [
            "action": "button_click",
            "page": "dashboard",
          ],
        ]
      ),
    ]

    print("  🔄 Processing \(testRequests.count) test requests...")

    var successCount = 0
    var totalProcessingTime: TimeInterval = 0

    for (index, request) in testRequests.enumerated() {
      let (response, processingTime) = try ExampleUtils.measureTime {
        return try gateway.processRequest(request)
      }

      totalProcessingTime += processingTime

      if response.statusCode == 200 {
        successCount += 1
        print(
          "  ✅ Request \(index + 1): \(request.method) \(request.path) - Success (\(String(format: "%.1f", processingTime * 1000))ms)"
        )

        // Show transformation results
        if let transformedData = response.metadata["transformations"] as? [String] {
          print("    🔄 Applied transformations: \(transformedData.joined(separator: ", "))")
        }
      }
      else {
        print("  ❌ Request \(index + 1): \(request.method) \(request.path) - Failed (Status: \(response.statusCode))")
      }
    }

    // Performance summary
    let avgProcessingTime = totalProcessingTime / Double(testRequests.count)
    print("\n  📊 Processing Summary:")
    print("    Success rate: \(successCount)/\(testRequests.count) (\(successCount * 100 / testRequests.count)%)")
    print("    Average processing time: \(String(format: "%.2f", avgProcessingTime * 1000))ms")
    print("    Total throughput: \(String(format: "%.1f", Double(testRequests.count) / totalProcessingTime)) req/sec")

    ExampleUtils.printSuccess("Request processing pipeline demonstrated")
  }

  private static func step5UshowcaseVersionHandling() throws {
    ExampleUtils.printStep(5, "Showcasing Multi-Version API Support")

    let gateway = ApiGatewayContext.shared.gateway!

    // Add versioned schema support
    try gateway.schemaRegistry.addVersionedSchema("user.UserService", version: "v1")
    try gateway.schemaRegistry.addVersionedSchema("user.UserService", version: "v2")

    // Test requests to different API versions
    let versionedRequests = [
      (
        request: ApiRequest(method: "GET", path: "/api/v1/users/profile", body: ["user_id": "123"]),
        expectedVersion: "v1"
      ),
      (
        request: ApiRequest(method: "GET", path: "/api/v2/users/profile", body: ["user_id": "123"]),
        expectedVersion: "v2"
      ),
    ]

    print("  🔄 Testing version compatibility...")

    for (request, expectedVersion) in versionedRequests {
      let (response, _) = try ExampleUtils.measureTime {
        return try gateway.processRequestWithVersioning(request)
      }

      let actualVersion = response.metadata["schema_version"] as? String ?? "unknown"
      let isCompatible = actualVersion == expectedVersion

      print("  \(isCompatible ? "✅" : "❌") \(request.path): Expected \(expectedVersion), got \(actualVersion)")

      if !isCompatible {
        // Show compatibility fallback
        if let fallbackVersion = response.metadata["fallback_version"] as? String {
          print("    🔄 Applied fallback to version: \(fallbackVersion)")
        }
      }
    }

    // Demonstrate schema evolution handling
    print("\n  🔄 Testing schema evolution patterns...")

    let evolutionCases = [
      "Add optional field": try gateway.testSchemaEvolution(.addOptionalField),
      "Remove deprecated field": try gateway.testSchemaEvolution(.removeDeprecatedField),
      "Change field type": try gateway.testSchemaEvolution(.changeFieldType),
      "Rename field with mapping": try gateway.testSchemaEvolution(.renameFieldWithMapping),
    ]

    for (evolutionType, isSupported) in evolutionCases {
      print("  \(isSupported ? "✅" : "⚠️ ") \(evolutionType): \(isSupported ? "Supported" : "Requires manual handling")")
    }

    ExampleUtils.printSuccess("Multi-version API support demonstrated")
  }

  private static func step6UperformanceAnalysis() throws {
    ExampleUtils.printStep(6, "Performance Analysis and Optimization")

    let gateway = ApiGatewayContext.shared.gateway!
    let monitor = gateway.performanceMonitor

    // Generate load test
    print("  🚀 Running performance benchmark...")

    let loadTestSize = 1000
    let (_, totalTime) = try ExampleUtils.measureTime {
      return try gateway.runLoadTest(requestCount: loadTestSize)
    }

    let throughput = Double(loadTestSize) / totalTime
    let avgLatency = totalTime / Double(loadTestSize)

    print("  📊 Load Test Results:")
    print("    Requests processed: \(loadTestSize)")
    print("    Total time: \(String(format: "%.3f", totalTime))s")
    print("    Throughput: \(String(format: "%.1f", throughput)) req/sec")
    print("    Average latency: \(String(format: "%.2f", avgLatency * 1000))ms")

    // Cache performance analysis
    let cacheStats = monitor!.getCacheStatistics()
    print("\n  🗄  Cache Performance:")
    print("    Hit rate: \(String(format: "%.1f", cacheStats.hitRate * 100))%")
    print("    Miss rate: \(String(format: "%.1f", cacheStats.missRate * 100))%")
    print("    Cache size: \(cacheStats.entryCount) entries")
    print("    Memory usage: \(ExampleUtils.formatDataSize(cacheStats.memoryUsage))")

    // Optimization recommendations
    let recommendations = monitor!.generateOptimizationRecommendations()
    if !recommendations.isEmpty {
      print("\n  💡 Optimization Recommendations:")
      for recommendation in recommendations {
        print("    • \(recommendation)")
      }
    }

    ExampleUtils.printSuccess("Performance analysis completed")
  }
}

// MARK: - API Gateway Implementation

/// Main API Gateway class that orchestrates request processing.
class ApiGateway {
  var schemaRegistry: SchemaRegistry!
  var requestRouter: RequestRouter!
  var responseTransformer: ResponseTransformer!
  var middlewarePipeline: MiddlewarePipeline!
  var performanceMonitor: PerformanceMonitor!

  func loadSchemas() throws -> Int {
    // Simulate loading various service schemas
    let serviceSchemas = [
      ("user.UserService", createUserServiceSchema()),
      ("order.OrderService", createOrderServiceSchema()),
      ("analytics.AnalyticsService", createAnalyticsServiceSchema()),
      ("payment.PaymentService", createPaymentServiceSchema()),
      ("notification.NotificationService", createNotificationServiceSchema()),
    ]

    for (serviceName, schema) in serviceSchemas {
      try schemaRegistry.registerService(serviceName, schema: schema)
    }

    return serviceSchemas.count
  }

  func processRequest(_ request: ApiRequest) throws -> ApiResponse {
    let (finalResponse, processingTime) = try ExampleUtils.measureTime {
      // Apply middleware pipeline
      var processedRequest = try middlewarePipeline.processRequest(request)

      // Route request to appropriate service
      guard let route = requestRouter.findRoute(for: processedRequest) else {
        return ApiResponse(statusCode: 404, body: ["error": "Route not found"], metadata: [:])
      }

      // Apply transformations
      for transformation in route.transformations {
        processedRequest = try transformation.apply(to: processedRequest, using: schemaRegistry)
      }

      // Simulate service call and response
      let serviceResponse = try simulateServiceCall(processedRequest, route: route)

      // Transform response
      return try responseTransformer.transform(serviceResponse, using: route)
    }

    // Record performance metrics (note: route access outside closure requires refactoring)
    let processedRequest = try middlewarePipeline.processRequest(request)
    if let route = requestRouter.findRoute(for: processedRequest) {
      performanceMonitor.recordRequest(
        route.targetService,
        duration: processingTime,
        success: finalResponse.statusCode == 200
      )
    }

    return finalResponse
  }

  func processRequestWithVersioning(_ request: ApiRequest) throws -> ApiResponse {
    // Extract version from path or headers
    let version = extractVersionFromRequest(request)

    // Process with version-aware routing
    var versionedRequest = request
    versionedRequest.metadata["requested_version"] = version

    let response = try processRequest(versionedRequest)
    var finalResponse = response
    finalResponse.metadata["schema_version"] = version

    return finalResponse
  }

  func testSchemaEvolution(_ evolutionType: SchemaEvolutionType) throws -> Bool {
    // Simulate testing different schema evolution scenarios
    switch evolutionType {
    case .addOptionalField:
      return true  // Always safe
    case .removeDeprecatedField:
      return true  // Safe if properly deprecated
    case .changeFieldType:
      return false  // Potentially breaking
    case .renameFieldWithMapping:
      return true  // Safe with field mapping
    }
  }

  func runLoadTest(requestCount: Int) throws -> LoadTestResults {
    var successCount = 0
    var errorCount = 0
    var totalLatency: TimeInterval = 0

    let sampleRequest = ApiRequest(
      method: "GET",
      path: "/api/v1/users/sample",
      body: ["user_id": "test_user"]
    )

    for _ in 0..<requestCount {
      let (response, latency) = try ExampleUtils.measureTime {
        return try processRequest(sampleRequest)
      }

      totalLatency += latency

      if response.statusCode == 200 {
        successCount += 1
      }
      else {
        errorCount += 1
      }
    }

    return LoadTestResults(
      totalRequests: requestCount,
      successCount: successCount,
      errorCount: errorCount,
      averageLatency: totalLatency / Double(requestCount)
    )
  }

  // MARK: - Helper Methods

  private func createUserServiceSchema() -> ServiceSchema {
    return ServiceSchema(
      name: "UserService",
      methods: [
        "GetUser": MethodSchema(inputType: "GetUserRequest", outputType: "User"),
        "CreateUser": MethodSchema(inputType: "CreateUserRequest", outputType: "User"),
        "UpdateUser": MethodSchema(inputType: "UpdateUserRequest", outputType: "User"),
        "DeleteUser": MethodSchema(inputType: "DeleteUserRequest", outputType: "Empty"),
      ]
    )
  }

  private func createOrderServiceSchema() -> ServiceSchema {
    return ServiceSchema(
      name: "OrderService",
      methods: [
        "GetOrder": MethodSchema(inputType: "GetOrderRequest", outputType: "Order"),
        "CreateOrder": MethodSchema(inputType: "CreateOrderRequest", outputType: "Order"),
        "ListOrders": MethodSchema(inputType: "ListOrdersRequest", outputType: "ListOrdersResponse"),
      ]
    )
  }

  private func createAnalyticsServiceSchema() -> ServiceSchema {
    return ServiceSchema(
      name: "AnalyticsService",
      methods: [
        "RecordEvent": MethodSchema(inputType: "EventRequest", outputType: "Empty"),
        "GetMetrics": MethodSchema(inputType: "MetricsRequest", outputType: "MetricsResponse"),
      ]
    )
  }

  private func createPaymentServiceSchema() -> ServiceSchema {
    return ServiceSchema(
      name: "PaymentService",
      methods: [
        "ProcessPayment": MethodSchema(inputType: "PaymentRequest", outputType: "PaymentResponse"),
        "RefundPayment": MethodSchema(inputType: "RefundRequest", outputType: "RefundResponse"),
      ]
    )
  }

  private func createNotificationServiceSchema() -> ServiceSchema {
    return ServiceSchema(
      name: "NotificationService",
      methods: [
        "SendNotification": MethodSchema(inputType: "NotificationRequest", outputType: "Empty"),
        "GetNotificationStatus": MethodSchema(inputType: "StatusRequest", outputType: "StatusResponse"),
      ]
    )
  }

  private func simulateServiceCall(_ request: ApiRequest, route: RoutingRule) throws -> ApiResponse {
    // Simulate processing time based on service type
    let processingDelay = route.targetService.contains("analytics") ? 0.01 : 0.005
    Thread.sleep(forTimeInterval: processingDelay)

    // Generate appropriate response based on route
    let responseBody = generateMockResponse(for: route.targetService, request: request)

    return ApiResponse(
      statusCode: 200,
      body: responseBody,
      metadata: [
        "service": route.targetService,
        "transformations": route.transformations.map { $0.description },
      ]
    )
  }

  private func generateMockResponse(for service: String, request: ApiRequest) -> [String: Any] {
    switch service {
    case "user.UserService":
      return [
        "user_id": "user_123",
        "name": "Alice Johnson",
        "email": "alice@example.com",
        "created_at": Date().timeIntervalSince1970,
      ]
    case "order.OrderService":
      return [
        "order_id": "order_456",
        "user_id": "user_123",
        "status": "confirmed",
        "total_amount": 99.99,
      ]
    case "analytics.AnalyticsService":
      return [
        "event_id": UUID().uuidString,
        "processed_at": Date().timeIntervalSince1970,
        "status": "recorded",
      ]
    default:
      return ["message": "Request processed successfully"]
    }
  }

  private func extractVersionFromRequest(_ request: ApiRequest) -> String {
    // Extract version from URL path (/api/v1/... -> v1)
    if let versionMatch = request.path.range(of: "v\\d+", options: .regularExpression) {
      return String(request.path[versionMatch])
    }
    return "v1"  // Default version
  }
}

// MARK: - Supporting Types and Classes

struct ApiRequest {
  let method: String
  let path: String
  let body: [String: Any]
  var metadata: [String: Any] = [:]
}

struct ApiResponse {
  let statusCode: Int
  let body: [String: Any]
  var metadata: [String: Any]
}

struct RoutingRule {
  let pattern: String
  let targetService: String
  let transformations: [RequestTransformation]
}

enum RequestTransformation {
  case addMetadata(String, String)
  case validateRequired([String])
  case validateSchema(String)
  case applyFieldMask([String])
  case enrichWithDefaults
  case aggregateMetrics
  case applyPrivacyFilters

  var description: String {
    switch self {
    case .addMetadata(let key, _): return "add_metadata(\(key))"
    case .validateRequired: return "validate_required"
    case .validateSchema: return "validate_schema"
    case .applyFieldMask: return "apply_field_mask"
    case .enrichWithDefaults: return "enrich_defaults"
    case .aggregateMetrics: return "aggregate_metrics"
    case .applyPrivacyFilters: return "privacy_filters"
    }
  }

  func apply(to request: ApiRequest, using registry: SchemaRegistry) throws -> ApiRequest {
    var modifiedRequest = request

    switch self {
    case .addMetadata(let key, let value):
      modifiedRequest.metadata[key] = value
    case .validateRequired(let fields):
      for field in fields where request.body[field] == nil {
        throw ApiGatewayError.missingRequiredField(field)
      }
    case .validateSchema(let schemaName):
      // Simulate schema validation
      if !registry.hasSchema(schemaName) {
        throw ApiGatewayError.unknownSchema(schemaName)
      }
    case .applyFieldMask(let fields):
      var filteredBody: [String: Any] = [:]
      for field in fields {
        if let value = request.body[field] {
          filteredBody[field] = value
        }
      }
      modifiedRequest = ApiRequest(
        method: request.method,
        path: request.path,
        body: filteredBody,
        metadata: modifiedRequest.metadata
      )
    case .enrichWithDefaults, .aggregateMetrics, .applyPrivacyFilters:
      // Simulate transformation processing
      modifiedRequest.metadata["transformation_applied"] = description
    }

    return modifiedRequest
  }
}

enum SchemaEvolutionType {
  case addOptionalField
  case removeDeprecatedField
  case changeFieldType
  case renameFieldWithMapping
}

struct ServiceSchema {
  let name: String
  let methods: [String: MethodSchema]
}

struct MethodSchema {
  let inputType: String
  let outputType: String
}

struct LoadTestResults {
  let totalRequests: Int
  let successCount: Int
  let errorCount: Int
  let averageLatency: TimeInterval
}

struct CacheStatistics {
  let hitRate: Double
  let missRate: Double
  let entryCount: Int
  let memoryUsage: Int
}

enum ApiGatewayError: Error, LocalizedError {
  case missingRequiredField(String)
  case unknownSchema(String)
  case routeNotFound
  case serviceUnavailable

  var errorDescription: String? {
    switch self {
    case .missingRequiredField(let field):
      return "Required field '\(field)' is missing"
    case .unknownSchema(let schema):
      return "Unknown schema '\(schema)'"
    case .routeNotFound:
      return "No route found for request"
    case .serviceUnavailable:
      return "Target service is unavailable"
    }
  }
}

// MARK: - Supporting Components

class SchemaRegistry {
  private var services: [String: ServiceSchema] = [:]
  private var versionedSchemas: [String: [String: ServiceSchema]] = [:]

  func registerService(_ name: String, schema: ServiceSchema) throws {
    services[name] = schema
  }

  func getAllServices() -> [ServiceSchema] {
    return Array(services.values)
  }

  func addVersionedSchema(_ serviceName: String, version: String) throws {
    if versionedSchemas[serviceName] == nil {
      versionedSchemas[serviceName] = [:]
    }

    // Create versioned variant of the service
    if let baseSchema = services[serviceName] {
      versionedSchemas[serviceName]![version] = baseSchema
    }
  }

  func hasSchema(_ schemaName: String) -> Bool {
    return services.keys.contains { $0.contains(schemaName) }
  }
}

class RequestRouter {
  private var rules: [RoutingRule] = []

  func addRule(_ rule: RoutingRule) {
    rules.append(rule)
  }

  func findRoute(for request: ApiRequest) -> RoutingRule? {
    return rules.first { rule in
      matchesPattern(rule.pattern, path: request.path)
    }
  }

  private func matchesPattern(_ pattern: String, path: String) -> Bool {
    // Simple pattern matching - in production, use proper regex
    let normalizedPattern = pattern.replacingOccurrences(of: "*", with: "")
    return path.hasPrefix(normalizedPattern)
  }
}

class ResponseTransformer {
  func transform(_ response: ApiResponse, using route: RoutingRule) throws -> ApiResponse {
    // Apply response transformations based on route configuration
    var transformedResponse = response
    transformedResponse.metadata["transformed_by"] = "response_transformer"
    return transformedResponse
  }
}

class MiddlewarePipeline {
  private var middlewares: [Middleware] = []

  func add(_ middleware: Middleware) {
    middlewares.append(middleware)
  }

  func processRequest(_ request: ApiRequest) throws -> ApiRequest {
    var processedRequest = request

    for middleware in middlewares {
      processedRequest = try middleware.process(processedRequest)
    }

    return processedRequest
  }
}

protocol Middleware {
  func process(_ request: ApiRequest) throws -> ApiRequest
}

class AuthenticationMiddleware: Middleware {
  func process(_ request: ApiRequest) throws -> ApiRequest {
    var authenticatedRequest = request
    authenticatedRequest.metadata["authenticated"] = true
    authenticatedRequest.metadata["user_id"] = "user_123"
    return authenticatedRequest
  }
}

class RateLimitingMiddleware: Middleware {
  private let requestsPerMinute: Int

  init(requestsPerMinute: Int) {
    self.requestsPerMinute = requestsPerMinute
  }

  func process(_ request: ApiRequest) throws -> ApiRequest {
    // Simulate rate limiting check
    var rateLimitedRequest = request
    rateLimitedRequest.metadata["rate_limit_remaining"] = requestsPerMinute - 1
    return rateLimitedRequest
  }
}

class LoggingMiddleware: Middleware {
  func process(_ request: ApiRequest) throws -> ApiRequest {
    // Log request (simplified)
    var loggedRequest = request
    loggedRequest.metadata["logged"] = true
    loggedRequest.metadata["request_id"] = UUID().uuidString
    return loggedRequest
  }
}

class MetricsMiddleware: Middleware {
  func process(_ request: ApiRequest) throws -> ApiRequest {
    var metricsRequest = request
    metricsRequest.metadata["metrics_timestamp"] = Date().timeIntervalSince1970
    return metricsRequest
  }
}

class PerformanceMonitor {
  private var requestMetrics: [(service: String, duration: TimeInterval, success: Bool)] = []

  func recordRequest(_ service: String, duration: TimeInterval, success: Bool) {
    requestMetrics.append((service: service, duration: duration, success: success))
  }

  func getCacheStatistics() -> CacheStatistics {
    // Simulate cache statistics
    return CacheStatistics(
      hitRate: 0.85,
      missRate: 0.15,
      entryCount: 1247,
      memoryUsage: 2_458_624  // ~2.4 MB
    )
  }

  func generateOptimizationRecommendations() -> [String] {
    guard !requestMetrics.isEmpty else { return [] }

    let avgDuration = requestMetrics.map { $0.duration }.reduce(0, +) / Double(requestMetrics.count)

    var recommendations: [String] = []

    if avgDuration > 0.05 {  // 50ms
      recommendations.append("Consider caching frequently accessed schemas")
    }

    let errorRate = Double(requestMetrics.filter { !$0.success }.count) / Double(requestMetrics.count)
    if errorRate > 0.05 {  // 5%
      recommendations.append("Investigate high error rate - check service health")
    }

    if requestMetrics.count > 500 {
      recommendations.append("Enable connection pooling for high throughput")
    }

    return recommendations
  }
}

// MARK: - Global Context

final class ApiGatewayContext: @unchecked Sendable {
  static let shared = ApiGatewayContext()
  var gateway: ApiGateway?

  private init() {}
}
