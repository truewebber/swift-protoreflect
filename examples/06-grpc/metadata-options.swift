/**
 * 🌐 SwiftProtoReflect Example: gRPC Metadata and Call Options
 * 
 * Описание: Работа с gRPC метаданными, заголовками и опциями вызовов
 * Ключевые концепции: Metadata management, Call options, Headers, Authentication
 * Сложность: 🚀 Продвинутый  
 * Время выполнения: < 15 секунд
 * 
 * Что изучите:
 * - Управление gRPC метаданными и заголовками
 * - Authentication patterns через metadata
 * - Custom call options и их влияние на RPC
 * - Request/Response metadata handling
 * - Tracing и correlation IDs
 * - Security contexts и authorization
 * 
 * Запуск: 
 *   swift run MetadataOptions
 */

import Foundation
import SwiftProtoReflect
import ExampleUtils

@main
struct MetadataOptionsExample {
    static func main() throws {
        try ExampleUtils.printHeader("gRPC Metadata and Call Options")
        
        try demonstrateBasicMetadata()
        try demonstrateAuthentication()
        try demonstrateTracing()
        try demonstrateCallOptions()
        try demonstrateSecurityContexts()
        try demonstrateMetadataManagement()
        
        ExampleUtils.printSuccess("gRPC Metadata and Call Options example completed!")
        ExampleUtils.printNext([
            "Complete: You've mastered gRPC integration with SwiftProtoReflect!",
            "Next level: 07-advanced examples for complex scenarios"
        ])
    }
    
    // MARK: - Basic Metadata
    
    private static func demonstrateBasicMetadata() throws {
        ExampleUtils.printStep(1, "Basic Metadata - Headers and Custom Data")
        
        let client = MetadataClient()
        
        print("  📋 Basic Metadata Operations:")
        
        // Scenario 1: Simple custom headers
        print("\n    📝 Custom Headers:")
        let basicMetadata = GRPCMetadata([
            "client-name": "SwiftProtoReflect-Example",
            "client-version": "1.0.0",
            "user-agent": "SwiftProtoReflect/1.0",
            "content-language": "en-US"
        ])
        
        let (response1, time1) = try ExampleUtils.measureTime {
            try client.makeCallWithMetadata(
                method: "GetUser",
                metadata: basicMetadata
            )
        }
        
        ExampleUtils.printTiming("Basic metadata call", time: time1)
        print("      ✅ Response: \(response1.body)")
        print("      📊 Request Headers Sent:")
        for (key, value) in basicMetadata.headers {
            print("        \(key): \(value)")
        }
        
        // Show response metadata
        if !response1.metadata.headers.isEmpty {
            print("      📨 Response Headers Received:")
            for (key, value) in response1.metadata.headers {
                print("        \(key): \(value)")
            }
        }
        
        // Scenario 2: Request ID tracking
        print("\n    🆔 Request ID Tracking:")
        let requestId = "req_\(UUID().uuidString.prefix(8))"
        let trackingMetadata = GRPCMetadata([
            "request-id": requestId,
            "correlation-id": "corr_\(UUID().uuidString.prefix(8))",
            "session-id": "sess_abc123"
        ])
        
        let (response2, time2) = try ExampleUtils.measureTime {
            try client.makeCallWithMetadata(
                method: "CreateUser",
                metadata: trackingMetadata
            )
        }
        
        ExampleUtils.printTiming("Tracking metadata call", time: time2)
        print("      ✅ Request tracked with ID: \(requestId)")
        print("      📊 Tracking Headers:")
        for (key, value) in trackingMetadata.headers {
            print("        \(key): \(value)")
        }
        
        // Scenario 3: Binary metadata
        print("\n    📦 Binary Metadata:")
        let binaryData = "custom-binary-data".data(using: .utf8)!
        let binaryMetadata = GRPCMetadata([
            "custom-text": "text-value",
            "custom-binary-bin": binaryData.base64EncodedString()
        ])
        
        let (response3, time3) = try ExampleUtils.measureTime {
            try client.makeCallWithMetadata(
                method: "UpdateUser",
                metadata: binaryMetadata
            )
        }
        
        ExampleUtils.printTiming("Binary metadata call", time: time3)
        print("      ✅ Binary data transmitted")
        print("      📦 Binary metadata size: \(binaryData.count) bytes")
    }
    
    // MARK: - Authentication
    
    private static func demonstrateAuthentication() throws {
        ExampleUtils.printStep(2, "Authentication - Security through Metadata")
        
        let client = MetadataClient()
        let authManager = AuthenticationManager()
        
        print("  🔐 Authentication Patterns:")
        
        // Pattern 1: Bearer token authentication
        print("\n    🎫 Bearer Token Authentication:")
        let bearerToken = authManager.generateBearerToken(userId: "user123", scopes: ["read", "write"])
        let bearerMetadata = GRPCMetadata([
            "authorization": "Bearer \(bearerToken)",
            "token-type": "access_token"
        ])
        
        let (authResponse1, authTime1) = try ExampleUtils.measureTime {
            try client.makeAuthenticatedCall(
                method: "GetSecureData",
                metadata: bearerMetadata
            )
        }
        
        ExampleUtils.printTiming("Bearer token auth", time: authTime1)
        print("      ✅ Authenticated successfully")
        print("      🎫 Token: \(bearerToken.prefix(20))...")
        print("      🔒 Auth status: \(authResponse1.authStatus)")
        
        // Pattern 2: API key authentication
        print("\n    🔑 API Key Authentication:")
        let apiKey = authManager.generateAPIKey(clientId: "client_456")
        let apiKeyMetadata = GRPCMetadata([
            "x-api-key": apiKey,
            "x-client-id": "client_456",
            "x-api-version": "v1"
        ])
        
        let (authResponse2, authTime2) = try ExampleUtils.measureTime {
            try client.makeAuthenticatedCall(
                method: "GetUserData",
                metadata: apiKeyMetadata
            )
        }
        
        ExampleUtils.printTiming("API key auth", time: authTime2)
        print("      ✅ API key validated")
        print("      🔑 Key: \(apiKey.prefix(12))...")
        print("      🏢 Client ID: client_456")
        
        // Pattern 3: mTLS authentication simulation
        print("\n    📜 Mutual TLS Authentication:")
        let clientCert = authManager.generateClientCertificate(commonName: "client.example.com")
        let mtlsMetadata = GRPCMetadata([
            "x-client-cert-cn": clientCert.commonName,
            "x-client-cert-fingerprint": clientCert.fingerprint,
            "x-cert-serial": clientCert.serialNumber
        ])
        
        let (authResponse3, authTime3) = try ExampleUtils.measureTime {
            try client.makeAuthenticatedCall(
                method: "GetHighSecurityData",
                metadata: mtlsMetadata
            )
        }
        
        ExampleUtils.printTiming("mTLS auth", time: authTime3)
        print("      ✅ Client certificate validated")
        print("      📜 CN: \(clientCert.commonName)")
        print("      🔍 Fingerprint: \(clientCert.fingerprint.prefix(16))...")
        
        // Pattern 4: Multi-factor authentication
        print("\n    🔢 Multi-Factor Authentication:")
        let mfaCode = authManager.generateMFACode()
        let mfaMetadata = GRPCMetadata([
            "authorization": "Bearer \(bearerToken)",
            "x-mfa-code": mfaCode,
            "x-mfa-method": "totp",
            "x-device-id": "device_789"
        ])
        
        let (authResponse4, authTime4) = try ExampleUtils.measureTime {
            try client.makeAuthenticatedCall(
                method: "GetMFAProtectedData",
                metadata: mfaMetadata
            )
        }
        
        ExampleUtils.printTiming("MFA auth", time: authTime4)
        print("      ✅ MFA validation successful")
        print("      🔢 MFA Code: \(mfaCode)")
        print("      📱 Device ID: device_789")
    }
    
    // MARK: - Tracing and Observability
    
    private static func demonstrateTracing() throws {
        ExampleUtils.printStep(3, "Tracing and Observability - Distributed Tracing")
        
        let client = MetadataClient()
        let tracer = DistributedTracer()
        
        print("  🔍 Distributed Tracing:")
        
        // Scenario 1: Basic trace context
        print("\n    📊 Basic Trace Context:")
        let traceContext = tracer.createTraceContext()
        let tracingMetadata = GRPCMetadata([
            "x-trace-id": traceContext.traceId,
            "x-span-id": traceContext.spanId,
            "x-parent-span-id": traceContext.parentSpanId ?? "root",
            "x-trace-flags": traceContext.flags
        ])
        
        let (traceResponse1, traceTime1) = try ExampleUtils.measureTime {
            try client.makeCallWithTracing(
                method: "ProcessOrder",
                metadata: tracingMetadata,
                tracer: tracer
            )
        }
        
        ExampleUtils.printTiming("Traced call", time: traceTime1)
        print("      🔍 Trace ID: \(traceContext.traceId)")
        print("      📍 Span ID: \(traceContext.spanId)")
        print("      ⏱  Duration: \(String(format: "%.2f", traceTime1 * 1000))ms")
        
        // Scenario 2: Nested spans
        print("\n    🔗 Nested Spans:")
        let parentSpan = tracer.startSpan(name: "parent-operation", traceId: traceContext.traceId)
        
        for i in 1...3 {
            let childSpan = tracer.startSpan(
                name: "child-operation-\(i)",
                traceId: traceContext.traceId,
                parentSpanId: parentSpan.spanId
            )
            
            let nestedMetadata = GRPCMetadata([
                "x-trace-id": traceContext.traceId,
                "x-span-id": childSpan.spanId,
                "x-parent-span-id": parentSpan.spanId,
                "x-operation-name": "child-operation-\(i)"
            ])
            
            let (_, childTime) = try ExampleUtils.measureTime {
                try client.makeCallWithTracing(
                    method: "ChildOperation\(i)",
                    metadata: nestedMetadata,
                    tracer: tracer
                )
            }
            
            tracer.finishSpan(childSpan, duration: childTime)
            print("      🔗 Child span \(i): \(childSpan.spanId.prefix(8))")
        }
        
        tracer.finishSpan(parentSpan, duration: traceTime1)
        print("      🎯 Parent span: \(parentSpan.spanId.prefix(8))")
        
        // Scenario 3: Baggage and context propagation
        print("\n    🎒 Baggage and Context:")
        let baggage = [
            "user.id": "user_123",
            "user.role": "admin",
            "feature.flag": "new_ui_enabled",
            "experiment.variant": "control"
        ]
        
        var baggageMetadata = GRPCMetadata([
            "x-trace-id": traceContext.traceId,
            "x-span-id": tracer.generateSpanId()
        ])
        
        for (key, value) in baggage {
            baggageMetadata.headers["baggage-\(key)"] = value
        }
        
        let (baggageResponse, baggageTime) = try ExampleUtils.measureTime {
            try client.makeCallWithTracing(
                method: "ProcessWithContext",
                metadata: baggageMetadata,
                tracer: tracer
            )
        }
        
        ExampleUtils.printTiming("Baggage call", time: baggageTime)
        print("      🎒 Baggage items: \(baggage.count)")
        for (key, value) in baggage {
            print("        \(key): \(value)")
        }
    }
    
    // MARK: - Call Options
    
    private static func demonstrateCallOptions() throws {
        ExampleUtils.printStep(4, "Call Options - Fine-grained Control")
        
        let client = MetadataClient()
        
        print("  ⚙️  Advanced Call Options:")
        
        // Option 1: Timeout configurations
        print("\n    ⏰ Timeout Configurations:")
        let timeoutOptions = [
            ("Fast timeout", CallOptions(timeout: 0.5, priority: .high)),
            ("Normal timeout", CallOptions(timeout: 2.0, priority: .normal)),
            ("Long timeout", CallOptions(timeout: 10.0, priority: .low))
        ]
        
        for (label, options) in timeoutOptions {
            let (response, time) = try ExampleUtils.measureTime {
                try client.makeCallWithOptions(
                    method: "VariableLatencyOperation",
                    options: options
                )
            }
            
            ExampleUtils.printTiming(label, time: time)
            print("      ⚙️  Timeout: \(options.timeout)s")
            print("      🎯 Priority: \(options.priority)")
            print("      ✅ Result: \(response.body)")
        }
        
        // Option 2: Compression options
        print("\n    🗜  Compression Options:")
        let compressionOptions = [
            ("No compression", CallOptions(compression: .none)),
            ("GZIP compression", CallOptions(compression: .gzip)),
            ("Deflate compression", CallOptions(compression: .deflate))
        ]
        
        for (label, options) in compressionOptions {
            let (response, time) = try ExampleUtils.measureTime {
                try client.makeCallWithOptions(
                    method: "LargeDataOperation",
                    options: options
                )
            }
            
            ExampleUtils.printTiming(label, time: time)
            print("      🗜  Compression: \(options.compression)")
            print("      📊 Response size: \(response.estimatedSize) bytes")
            if let ratio = response.compressionRatio {
                print("      📉 Compression ratio: \(String(format: "%.1f", ratio))%")
            }
        }
        
        // Option 3: Retry configurations
        print("\n    🔄 Retry Configurations:")
        let retryOptions = CallOptions(
            maxRetries: 3,
            retryDelay: 0.1,
            retryBackoffMultiplier: 2.0
        )
        
        let (retryResponse, retryTime) = try ExampleUtils.measureTime {
            try client.makeCallWithOptions(
                method: "UnreliableOperation",
                options: retryOptions
            )
        }
        
        ExampleUtils.printTiming("Retry operation", time: retryTime)
        print("      🔄 Max retries: \(retryOptions.maxRetries)")
        print("      ⏱  Retry delay: \(retryOptions.retryDelay)s")
        print("      📈 Backoff multiplier: \(retryOptions.retryBackoffMultiplier)x")
        print("      ✅ Final result: \(retryResponse.body)")
        
        // Option 4: Custom options
        print("\n    🎛  Custom Call Options:")
        let customOptions = CallOptions(
            enableTracing: true,
            enableMetrics: true,
            enableCircuitBreaker: true,
            circuitBreakerThreshold: 5
        )
        
        let (customResponse, customTime) = try ExampleUtils.measureTime {
            try client.makeCallWithOptions(
                method: "MonitoredOperation",
                options: customOptions
            )
        }
        
        ExampleUtils.printTiming("Custom options call", time: customTime)
        print("      🔍 Tracing: \(customOptions.enableTracing ? "Enabled" : "Disabled")")
        print("      📊 Metrics: \(customOptions.enableMetrics ? "Enabled" : "Disabled")")
        print("      ⚡ Circuit breaker: \(customOptions.enableCircuitBreaker ? "Enabled" : "Disabled")")
        print("      🎯 CB threshold: \(customOptions.circuitBreakerThreshold)")
    }
    
    // MARK: - Security Contexts
    
    private static func demonstrateSecurityContexts() throws {
        ExampleUtils.printStep(5, "Security Contexts - Advanced Authorization")
        
        let client = MetadataClient()
        let securityManager = SecurityContextManager()
        
        print("  🛡  Security Context Management:")
        
        // Context 1: Role-based access control
        print("\n    👥 Role-Based Access Control:")
        let rbacContext = securityManager.createRBACContext(
            userId: "user_456",
            roles: ["admin", "user"],
            permissions: ["read:users", "write:users", "delete:users"]
        )
        
        let rbacMetadata = GRPCMetadata([
            "x-user-id": rbacContext.userId,
            "x-user-roles": rbacContext.roles.joined(separator: ","),
            "x-permissions": rbacContext.permissions.joined(separator: ","),
            "x-security-context": rbacContext.contextId
        ])
        
        let (rbacResponse, rbacTime) = try ExampleUtils.measureTime {
            try client.makeSecureCall(
                method: "ManageUsers",
                metadata: rbacMetadata,
                securityLevel: .high
            )
        }
        
        ExampleUtils.printTiming("RBAC call", time: rbacTime)
        print("      👤 User: \(rbacContext.userId)")
        print("      👥 Roles: \(rbacContext.roles.joined(separator: ", "))")
        print("      🔐 Permissions: \(rbacContext.permissions.count)")
        print("      ✅ Authorization: \(rbacResponse.authorizationStatus)")
        
        // Context 2: Attribute-based access control
        print("\n    🏷  Attribute-Based Access Control:")
        let abacContext = securityManager.createABACContext(
            userId: "user_789",
            attributes: [
                "department": "engineering",
                "level": "senior",
                "location": "us-west-2",
                "clearance": "secret"
            ]
        )
        
        let abacMetadata = GRPCMetadata([
            "x-user-id": abacContext.userId,
            "x-department": abacContext.attributes["department"] ?? "",
            "x-level": abacContext.attributes["level"] ?? "",
            "x-location": abacContext.attributes["location"] ?? "",
            "x-clearance": abacContext.attributes["clearance"] ?? "",
            "x-context-checksum": abacContext.checksum
        ])
        
        let (abacResponse, abacTime) = try ExampleUtils.measureTime {
            try client.makeSecureCall(
                method: "AccessClassifiedData",
                metadata: abacMetadata,
                securityLevel: .maximum
            )
        }
        
        ExampleUtils.printTiming("ABAC call", time: abacTime)
        print("      👤 User: \(abacContext.userId)")
        print("      🏷  Attributes: \(abacContext.attributes.count)")
        for (key, value) in abacContext.attributes {
            print("        \(key): \(value)")
        }
        print("      🔒 Security level: Maximum")
        print("      ✅ Access granted: \(abacResponse.accessGranted)")
        
        // Context 3: Session context
        print("\n    🕐 Session Context:")
        let sessionContext = securityManager.createSessionContext(
            sessionId: "sess_\(UUID().uuidString.prefix(12))",
            maxAge: 3600,
            renewalPolicy: "sliding"
        )
        
        let sessionMetadata = GRPCMetadata([
            "x-session-id": sessionContext.sessionId,
            "x-session-created": String(Int(sessionContext.createdAt.timeIntervalSince1970)),
            "x-session-expires": String(Int(sessionContext.expiresAt.timeIntervalSince1970)),
            "x-renewal-policy": sessionContext.renewalPolicy,
            "x-session-token": sessionContext.token
        ])
        
        let (sessionResponse, sessionTime) = try ExampleUtils.measureTime {
            try client.makeSecureCall(
                method: "SessionProtectedOperation",
                metadata: sessionMetadata,
                securityLevel: .medium
            )
        }
        
        ExampleUtils.printTiming("Session call", time: sessionTime)
        print("      🆔 Session: \(sessionContext.sessionId)")
        print("      ⏰ Expires: \(sessionContext.expiresAt)")
        print("      🔄 Renewal: \(sessionContext.renewalPolicy)")
        print("      ✅ Session valid: \(sessionResponse.sessionValid)")
    }
    
    // MARK: - Metadata Management
    
    private static func demonstrateMetadataManagement() throws {
        ExampleUtils.printStep(6, "Metadata Management - Best Practices")
        
        let client = MetadataClient()
        let metadataManager = MetadataManager()
        
        print("  🗂  Metadata Management Patterns:")
        
        // Pattern 1: Metadata builder
        print("\n    🏗  Metadata Builder Pattern:")
        let builtMetadata = metadataManager
            .builder()
            .withAuthentication(token: "token_abc123")
            .withTracing(traceId: "trace_def456", spanId: "span_ghi789")
            .withRequestId("req_\(UUID().uuidString.prefix(8))")
            .withClientInfo(name: "SwiftProtoReflect", version: "1.0.0")
            .withCompression(.gzip)
            .build()
        
        let (builderResponse, builderTime) = try ExampleUtils.measureTime {
            try client.makeCallWithMetadata(
                method: "ComplexOperation",
                metadata: builtMetadata
            )
        }
        
        ExampleUtils.printTiming("Builder metadata call", time: builderTime)
        print("      🏗  Metadata items: \(builtMetadata.headers.count)")
        print("      📋 Categories:")
        print("        🔐 Authentication: Yes")
        print("        🔍 Tracing: Yes") 
        print("        🆔 Request ID: Yes")
        print("        📱 Client info: Yes")
        print("        🗜  Compression: Yes")
        
        // Pattern 2: Metadata middleware
        print("\n    🔌 Metadata Middleware:")
        let middleware = MetadataMiddleware()
        middleware.addInterceptor(AuthenticationInterceptor())
        middleware.addInterceptor(TracingInterceptor())
        middleware.addInterceptor(LoggingInterceptor())
        
        let baseMetadata = GRPCMetadata(["operation": "test"])
        let processedMetadata = try middleware.process(baseMetadata)
        
        let (middlewareResponse, middlewareTime) = try ExampleUtils.measureTime {
            try client.makeCallWithMetadata(
                method: "MiddlewareOperation",
                metadata: processedMetadata
            )
        }
        
        ExampleUtils.printTiming("Middleware metadata call", time: middlewareTime)
        print("      🔌 Interceptors applied: \(middleware.interceptorCount)")
        print("      📊 Original headers: \(baseMetadata.headers.count)")
        print("      📈 Processed headers: \(processedMetadata.headers.count)")
        print("      ➕ Headers added: \(processedMetadata.headers.count - baseMetadata.headers.count)")
        
        // Pattern 3: Metadata validation
        print("\n    ✅ Metadata Validation:")
        let validator = MetadataValidator()
        
        let testMetadata = GRPCMetadata([
            "authorization": "Bearer valid_token_123",
            "x-trace-id": "valid-trace-id-format",
            "x-request-id": "req_valid_format",
            "invalid-header": "contains spaces and special chars!"
        ])
        
        let validationResult = validator.validate(testMetadata)
        
        print("      ✅ Validation Results:")
        print("        Valid headers: \(validationResult.validHeaders.count)")
        print("        Invalid headers: \(validationResult.invalidHeaders.count)")
        print("        Warnings: \(validationResult.warnings.count)")
        
        for header in validationResult.validHeaders {
            print("        ✅ \(header)")
        }
        
        for header in validationResult.invalidHeaders {
            print("        ❌ \(header)")
        }
        
        for warning in validationResult.warnings {
            print("        ⚠️  \(warning)")
        }
        
        // Pattern 4: Metadata performance
        print("\n    📈 Metadata Performance:")
        let performanceTest = MetadataPerformanceTest()
        
        let testSizes = [10, 50, 100, 500]
        
        for size in testSizes {
            let largeMetadata = performanceTest.generateMetadata(headerCount: size)
            
            let (_, performanceTime) = try ExampleUtils.measureTime {
                try client.makeCallWithMetadata(
                    method: "PerformanceTest",
                    metadata: largeMetadata
                )
            }
            
            let metadataSize = performanceTest.estimateSize(largeMetadata)
            ExampleUtils.printTiming("Metadata size \(size)", time: performanceTime)
            print("        📊 Headers: \(size)")
            print("        💾 Size: ~\(metadataSize) bytes")
            print("        📈 Overhead: \(String(format: "%.1f", performanceTime * 1000))ms")
        }
    }
}

// MARK: - Supporting Types and Classes

struct GRPCMetadata {
    var headers: [String: String]
    
    init(_ headers: [String: String] = [:]) {
        self.headers = headers
    }
}

struct GRPCResponse {
    let body: String
    let metadata: GRPCMetadata
    let authStatus: String
    let authorizationStatus: String
    let accessGranted: Bool
    let sessionValid: Bool
    let estimatedSize: Int
    let compressionRatio: Double?
    
    init(body: String, metadata: GRPCMetadata = GRPCMetadata(), authStatus: String = "authenticated", authorizationStatus: String = "authorized", accessGranted: Bool = true, sessionValid: Bool = true, estimatedSize: Int = 1024, compressionRatio: Double? = nil) {
        self.body = body
        self.metadata = metadata
        self.authStatus = authStatus
        self.authorizationStatus = authorizationStatus
        self.accessGranted = accessGranted
        self.sessionValid = sessionValid
        self.estimatedSize = estimatedSize
        self.compressionRatio = compressionRatio
    }
}

enum CallPriority {
    case low
    case normal
    case high
}

enum CompressionType {
    case none
    case gzip
    case deflate
}

struct CallOptions {
    let timeout: TimeInterval
    let priority: CallPriority
    let compression: CompressionType
    let maxRetries: Int
    let retryDelay: TimeInterval
    let retryBackoffMultiplier: Double
    let enableTracing: Bool
    let enableMetrics: Bool
    let enableCircuitBreaker: Bool
    let circuitBreakerThreshold: Int
    
    init(timeout: TimeInterval = 5.0, priority: CallPriority = .normal, compression: CompressionType = .none, maxRetries: Int = 0, retryDelay: TimeInterval = 0.1, retryBackoffMultiplier: Double = 2.0, enableTracing: Bool = false, enableMetrics: Bool = false, enableCircuitBreaker: Bool = false, circuitBreakerThreshold: Int = 5) {
        self.timeout = timeout
        self.priority = priority
        self.compression = compression
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        self.retryBackoffMultiplier = retryBackoffMultiplier
        self.enableTracing = enableTracing
        self.enableMetrics = enableMetrics
        self.enableCircuitBreaker = enableCircuitBreaker
        self.circuitBreakerThreshold = circuitBreakerThreshold
    }
}

enum SecurityLevel {
    case low
    case medium
    case high
    case maximum
}

class MetadataClient {
    func makeCallWithMetadata(method: String, metadata: GRPCMetadata) throws -> GRPCResponse {
        // Simulate network delay
        Thread.sleep(forTimeInterval: Double.random(in: 0.001...0.01))
        
        // Create response metadata
        let responseMetadata = GRPCMetadata([
            "server-name": "SwiftProtoReflect-Server",
            "server-version": "1.0.0",
            "response-time": String(Date().timeIntervalSince1970)
        ])
        
        return GRPCResponse(
            body: "Response for \(method)",
            metadata: responseMetadata
        )
    }
    
    func makeAuthenticatedCall(method: String, metadata: GRPCMetadata) throws -> GRPCResponse {
        Thread.sleep(forTimeInterval: Double.random(in: 0.001...0.01))
        
        return GRPCResponse(
            body: "Authenticated response for \(method)",
            authStatus: "authenticated"
        )
    }
    
    func makeCallWithTracing(method: String, metadata: GRPCMetadata, tracer: DistributedTracer) throws -> GRPCResponse {
        Thread.sleep(forTimeInterval: Double.random(in: 0.001...0.01))
        
        return GRPCResponse(
            body: "Traced response for \(method)"
        )
    }
    
    func makeCallWithOptions(method: String, options: CallOptions) throws -> GRPCResponse {
        Thread.sleep(forTimeInterval: Double.random(in: 0.001...0.01))
        
        let compressionRatio = options.compression == .none ? nil : Double.random(in: 10...60)
        
        return GRPCResponse(
            body: "Options response for \(method)",
            estimatedSize: Int.random(in: 512...4096),
            compressionRatio: compressionRatio
        )
    }
    
    func makeSecureCall(method: String, metadata: GRPCMetadata, securityLevel: SecurityLevel) throws -> GRPCResponse {
        Thread.sleep(forTimeInterval: Double.random(in: 0.001...0.01))
        
        return GRPCResponse(
            body: "Secure response for \(method)",
            authorizationStatus: "authorized",
            accessGranted: true,
            sessionValid: true
        )
    }
}

class AuthenticationManager {
    func generateBearerToken(userId: String, scopes: [String]) -> String {
        return "jwt.\(userId).\(scopes.joined(separator: "-")).\(UUID().uuidString.prefix(8))"
    }
    
    func generateAPIKey(clientId: String) -> String {
        return "ak_\(clientId)_\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(24))"
    }
    
    func generateClientCertificate(commonName: String) -> ClientCertificate {
        return ClientCertificate(
            commonName: commonName,
            fingerprint: "fp_\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))",
            serialNumber: "sn_\(Int.random(in: 100000...999999))"
        )
    }
    
    func generateMFACode() -> String {
        return String(Int.random(in: 100000...999999))
    }
}

struct ClientCertificate {
    let commonName: String
    let fingerprint: String
    let serialNumber: String
}

class DistributedTracer {
    func createTraceContext() -> TraceContext {
        return TraceContext(
            traceId: "trace_\(generateId())",
            spanId: "span_\(generateId())",
            parentSpanId: nil,
            flags: "01"
        )
    }
    
    func startSpan(name: String, traceId: String, parentSpanId: String? = nil) -> Span {
        return Span(
            spanId: "span_\(generateId())",
            traceId: traceId,
            parentSpanId: parentSpanId,
            name: name,
            startTime: Date()
        )
    }
    
    func finishSpan(_ span: Span, duration: TimeInterval) {
        // In real implementation, would record span
    }
    
    func generateSpanId() -> String {
        return "span_\(generateId())"
    }
    
    private func generateId() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(16).lowercased()
    }
}

struct TraceContext {
    let traceId: String
    let spanId: String
    let parentSpanId: String?
    let flags: String
}

struct Span {
    let spanId: String
    let traceId: String
    let parentSpanId: String?
    let name: String
    let startTime: Date
}

class SecurityContextManager {
    func createRBACContext(userId: String, roles: [String], permissions: [String]) -> RBACContext {
        return RBACContext(
            userId: userId,
            roles: roles,
            permissions: permissions,
            contextId: "rbac_\(UUID().uuidString.prefix(8))"
        )
    }
    
    func createABACContext(userId: String, attributes: [String: String]) -> ABACContext {
        let checksum = attributes.sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .hash
        
        return ABACContext(
            userId: userId,
            attributes: attributes,
            checksum: String(checksum)
        )
    }
    
    func createSessionContext(sessionId: String, maxAge: TimeInterval, renewalPolicy: String) -> SessionContext {
        let now = Date()
        return SessionContext(
            sessionId: sessionId,
            createdAt: now,
            expiresAt: now.addingTimeInterval(maxAge),
            renewalPolicy: renewalPolicy,
            token: "st_\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(16))"
        )
    }
}

struct RBACContext {
    let userId: String
    let roles: [String]
    let permissions: [String]
    let contextId: String
}

struct ABACContext {
    let userId: String
    let attributes: [String: String]
    let checksum: String
}

struct SessionContext {
    let sessionId: String
    let createdAt: Date
    let expiresAt: Date
    let renewalPolicy: String
    let token: String
}

class MetadataManager {
    func builder() -> MetadataBuilder {
        return MetadataBuilder()
    }
}

class MetadataBuilder {
    private var headers: [String: String] = [:]
    
    func withAuthentication(token: String) -> MetadataBuilder {
        headers["authorization"] = "Bearer \(token)"
        return self
    }
    
    func withTracing(traceId: String, spanId: String) -> MetadataBuilder {
        headers["x-trace-id"] = traceId
        headers["x-span-id"] = spanId
        return self
    }
    
    func withRequestId(_ requestId: String) -> MetadataBuilder {
        headers["x-request-id"] = requestId
        return self
    }
    
    func withClientInfo(name: String, version: String) -> MetadataBuilder {
        headers["x-client-name"] = name
        headers["x-client-version"] = version
        return self
    }
    
    func withCompression(_ compression: CompressionType) -> MetadataBuilder {
        headers["x-compression"] = String(describing: compression)
        return self
    }
    
    func build() -> GRPCMetadata {
        return GRPCMetadata(headers)
    }
}

class MetadataMiddleware {
    private var interceptors: [MetadataInterceptor] = []
    
    var interceptorCount: Int { interceptors.count }
    
    func addInterceptor(_ interceptor: MetadataInterceptor) {
        interceptors.append(interceptor)
    }
    
    func process(_ metadata: GRPCMetadata) throws -> GRPCMetadata {
        var processedMetadata = metadata
        
        for interceptor in interceptors {
            processedMetadata = try interceptor.process(processedMetadata)
        }
        
        return processedMetadata
    }
}

protocol MetadataInterceptor {
    func process(_ metadata: GRPCMetadata) throws -> GRPCMetadata
}

class AuthenticationInterceptor: MetadataInterceptor {
    func process(_ metadata: GRPCMetadata) throws -> GRPCMetadata {
        var newMetadata = metadata
        if newMetadata.headers["authorization"] == nil {
            newMetadata.headers["authorization"] = "Bearer auto_generated_token"
        }
        return newMetadata
    }
}

class TracingInterceptor: MetadataInterceptor {
    func process(_ metadata: GRPCMetadata) throws -> GRPCMetadata {
        var newMetadata = metadata
        if newMetadata.headers["x-trace-id"] == nil {
            newMetadata.headers["x-trace-id"] = "trace_\(UUID().uuidString.prefix(8))"
        }
        return newMetadata
    }
}

class LoggingInterceptor: MetadataInterceptor {
    func process(_ metadata: GRPCMetadata) throws -> GRPCMetadata {
        var newMetadata = metadata
        newMetadata.headers["x-logged-at"] = String(Int(Date().timeIntervalSince1970))
        return newMetadata
    }
}

class MetadataValidator {
    func validate(_ metadata: GRPCMetadata) -> ValidationResult {
        var validHeaders: [String] = []
        var invalidHeaders: [String] = []
        var warnings: [String] = []
        
        for (key, value) in metadata.headers {
            if isValidHeaderName(key) && isValidHeaderValue(value) {
                validHeaders.append(key)
            } else {
                invalidHeaders.append(key)
            }
            
            if key.contains(" ") {
                warnings.append("Header '\(key)' contains spaces")
            }
            
            if value.count > 1000 {
                warnings.append("Header '\(key)' value is very long")
            }
        }
        
        return ValidationResult(
            validHeaders: validHeaders,
            invalidHeaders: invalidHeaders,
            warnings: warnings
        )
    }
    
    private func isValidHeaderName(_ name: String) -> Bool {
        return !name.isEmpty && !name.contains(" ") && name.lowercased() == name
    }
    
    private func isValidHeaderValue(_ value: String) -> Bool {
        return !value.isEmpty && !value.contains("\n") && !value.contains("\r")
    }
}

struct ValidationResult {
    let validHeaders: [String]
    let invalidHeaders: [String]
    let warnings: [String]
}

class MetadataPerformanceTest {
    func generateMetadata(headerCount: Int) -> GRPCMetadata {
        var headers: [String: String] = [:]
        
        for i in 0..<headerCount {
            headers["x-custom-header-\(i)"] = "value-\(i)-\(UUID().uuidString)"
        }
        
        return GRPCMetadata(headers)
    }
    
    func estimateSize(_ metadata: GRPCMetadata) -> Int {
        return metadata.headers.reduce(0) { size, header in
            size + header.key.count + header.value.count + 4 // +4 for ": " and "\r\n"
        }
    }
}

extension String {
    var hash: Int {
        return self.hashValue
    }
}
