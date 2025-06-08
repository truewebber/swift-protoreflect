/**
 * 🌐 SwiftProtoReflect Example: gRPC Error Handling
 * 
 * Описание: Comprehensive обработка всех типов gRPC ошибок и recovery стратегий
 * Ключевые концепции: gRPC Status Codes, Error recovery, Retry policies, Circuit breaker
 * Сложность: 🚀 Продвинутый
 * Время выполнения: < 20 секунд
 * 
 * Что изучите:
 * - Все типы gRPC статус кодов и их обработка
 * - Retry механизмы с экспоненциальным backoff
 * - Circuit breaker pattern для защиты от сбоев
 * - Error categorization и recovery стратегии
 * - Timeout handling и deadline management
 * - Error metrics и monitoring
 * 
 * Запуск: 
 *   swift run ErrorHandling
 */

import Foundation
import SwiftProtoReflect
import ExampleUtils

@main
struct ErrorHandlingExample {
    static func main() throws {
        ExampleUtils.printHeader("gRPC Error Handling")
        
        try demonstrateStatusCodes()
        try demonstrateRetryMechanisms()
        try demonstrateCircuitBreaker()
        try demonstrateTimeoutHandling()
        try demonstrateErrorRecovery()
        
        ExampleUtils.printSuccess("gRPC Error Handling example completed!")
        ExampleUtils.printNext([
            "Next: metadata-options.swift - gRPC metadata and headers",
            "Review: dynamic-client.swift - Complete gRPC integration"
        ])
    }
    
    // MARK: - Status Codes
    
    private static func demonstrateStatusCodes() throws {
        ExampleUtils.printStep(1, "gRPC Status Codes - Comprehensive Error Types")
        
        let client = ErrorSimulatorClient()
        
        print("  📋 gRPC Status Code Examples:")
        
        let statusScenarios: [(GRPCStatus, String)] = [
            (.ok, "Successful operation"),
            (.cancelled, "Client cancelled request"),
            (.invalidArgument, "Invalid request parameters"),
            (.notFound, "Resource not found"),
            (.permissionDenied, "Access denied"),
            (.unavailable, "Service unavailable"),
            (.internal, "Internal server error"),
            (.unauthenticated, "Authentication required")
        ]
        
        for (status, description) in statusScenarios {
            print("\n    \(status.emoji) \(status.rawValue.uppercased()):")
            print("      Description: \(description)")
            
            do {
                _ = try client.simulateError(status: status)
                if status == .ok {
                    print("      Result: ✅ Success")
                } else {
                    print("      Result: ❌ Should have thrown error")
                }
            } catch let error as DetailedGRPCError {
                print("      Result: ✅ Caught \(error.status)")
                print("      Message: \(error.message)")
                print("      Retryable: \(error.isRetryable ? "Yes" : "No")")
            }
        }
    }
    
    // MARK: - Retry Mechanisms
    
    private static func demonstrateRetryMechanisms() throws {
        ExampleUtils.printStep(2, "Retry Mechanisms - Intelligent Error Recovery")
        
        let client = ErrorSimulatorClient()
        let retryManager = RetryManager()
        
        print("  🔄 Retry Policy Demonstrations:")
        
        // Scenario 1: Exponential backoff
        print("\n    📈 Exponential Backoff Retry:")
        let exponentialPolicy = RetryPolicy(
            maxAttempts: 3,
            initialDelay: 0.1,
            maxDelay: 1.0,
            backoffMultiplier: 2.0
        )
        
        let (_, retryTime) = ExampleUtils.measureTime {
            do {
                _ = try retryManager.executeWithRetry(policy: exponentialPolicy) {
                    try client.simulateTransientError(failureCount: 2)
                }
                print("      ✅ Success after retries")
            } catch {
                print("      ❌ Failed after retries: \(error)")
            }
        }
        
        ExampleUtils.printTiming("Exponential backoff retry", time: retryTime)
        
        // Scenario 2: Non-retryable error
        print("\n    🚫 Non-Retryable Error:")
        do {
            _ = try retryManager.executeWithRetry(policy: exponentialPolicy) {
                try client.simulateError(status: .invalidArgument)
            }
            print("      ❌ Should have failed")
        } catch {
            print("      ✅ Failed immediately (non-retryable)")
        }
        
        // Scenario 3: Retry exhaustion
        print("\n    ⚠️  Retry Exhaustion:")
        do {
            _ = try retryManager.executeWithRetry(policy: RetryPolicy(maxAttempts: 2)) {
                try client.simulateError(status: .unavailable)
            }
            print("      ❌ Should have exhausted retries")
        } catch let error as RetryExhaustedError {
            print("      ✅ Retries exhausted as expected")
            print("      Attempts: \(error.attemptsMade)")
        } catch {
            print("      ✅ Failed as expected: \(error)")
        }
    }
    
    // MARK: - Circuit Breaker
    
    private static func demonstrateCircuitBreaker() throws {
        ExampleUtils.printStep(3, "Circuit Breaker - Service Protection Pattern")
        
        let client = ErrorSimulatorClient()
        let circuitBreaker = CircuitBreaker(failureThreshold: 3, recoveryTimeout: 1.0)
        
        print("  ⚡ Circuit Breaker States:")
        
        // State 1: Closed (normal operation)
        print("\n    🟢 CLOSED State (Normal Operation):")
        for i in 1...2 {
            do {
                _ = try circuitBreaker.execute {
                    try client.simulateSuccess()
                }
                print("      Call \(i): ✅ Success")
            } catch {
                print("      Call \(i): ❌ Failed")
            }
        }
        print("      Circuit State: \(circuitBreaker.state)")
        print("      Failure Count: \(circuitBreaker.failureCount)")
        
        // State 2: Open (failures accumulating)
        print("\n    🔴 Triggering OPEN State (Failures):")
        for i in 1...4 {
            do {
                _ = try circuitBreaker.execute {
                    try client.simulateError(status: .unavailable)
                }
                print("      Call \(i): ✅ Unexpected success")
            } catch _ as CircuitBreakerError {
                print("      Call \(i): ⚡ Circuit breaker open")
            } catch {
                print("      Call \(i): ❌ Failed - \(error)")
            }
        }
        print("      Circuit State: \(circuitBreaker.state)")
        
        // State 3: Half-open (testing recovery)
        print("\n    🟡 HALF-OPEN State (Testing Recovery):")
        Thread.sleep(forTimeInterval: 1.1) // Wait for recovery timeout
        
        do {
            _ = try circuitBreaker.execute {
                try client.simulateSuccess()
            }
            print("      Recovery test: ✅ Success")
            print("      Circuit State: \(circuitBreaker.state)")
        } catch {
            print("      Recovery test: ❌ Still failing")
        }
        
        // Demonstrate metrics
        print("\n    📊 Circuit Breaker Metrics:")
        print("      Total Calls: \(circuitBreaker.totalCalls)")
        print("      Failed Calls: \(circuitBreaker.failedCalls)")
        print("      Success Rate: \(String(format: "%.1f", circuitBreaker.successRate * 100))%")
    }
    
    // MARK: - Timeout Handling
    
    private static func demonstrateTimeoutHandling() throws {
        ExampleUtils.printStep(4, "Timeout Handling - Deadline Management")
        
        let client = ErrorSimulatorClient()
        let timeoutManager = TimeoutManager()
        
        print("  ⏰ Timeout Scenarios:")
        
        // Scenario 1: Normal operation within timeout
        print("\n    ✅ Operation Within Timeout:")
        do {
            let (result, time) = try ExampleUtils.measureTime {
                try timeoutManager.executeWithTimeout(timeout: 1.0) {
                    _ = try client.simulateDelay(0.1)
                    return "Success"
                }
            }
            
            ExampleUtils.printTiming("Fast operation", time: time)
            print("      Result: \(result)")
        } catch {
            print("      ❌ Unexpected timeout: \(error)")
        }
        
        // Scenario 2: Operation exceeds timeout
        print("\n    ⏰ Operation Exceeds Timeout:")
        do {
            _ = try timeoutManager.executeWithTimeout(timeout: 0.1) {
                _ = try client.simulateDelay(0.5)
                return "Should not reach here"
            }
            print("      ❌ Should have timed out")
        } catch let error as TimeoutError {
            print("      ✅ Timed out as expected")
            print("      Timeout Duration: \(error.timeoutDuration)s")
        } catch {
            print("      ⏰ Timeout detected: \(error)")
        }
        
        // Scenario 3: Adaptive timeout
        print("\n    🎯 Adaptive Timeout:")
        let adaptiveTimeout = AdaptiveTimeoutManager()
        
        for i in 1...3 {
            let currentTimeout = adaptiveTimeout.getCurrentTimeout()
            
            do {
                let (_, time) = try ExampleUtils.measureTime {
                    try adaptiveTimeout.executeWithAdaptiveTimeout {
                        let delay = 0.1 * Double(i)
                        _ = try client.simulateDelay(delay)
                        return "Call \(i)"
                    }
                }
                
                print("      Call \(i) (timeout: \(String(format: "%.2f", currentTimeout))s): ✅ Success")
                ExampleUtils.printTiming("    Execution", time: time)
            } catch {
                print("      Call \(i) (timeout: \(String(format: "%.2f", currentTimeout))s): ⏰ Timeout")
            }
        }
        
        print("      Final adaptive timeout: \(String(format: "%.2f", adaptiveTimeout.getCurrentTimeout()))s")
    }
    
    // MARK: - Error Recovery
    
    private static func demonstrateErrorRecovery() throws {
        ExampleUtils.printStep(5, "Error Recovery - Recovery Strategies")
        
        let client = ErrorSimulatorClient()
        let recoveryManager = ErrorRecoveryManager()
        
        print("  🔧 Recovery Strategies:")
        
        // Strategy 1: Fallback
        print("\n    🔄 Fallback Strategy:")
        do {
            let result = try recoveryManager.executeWithFallback(
                primary: {
                    _ = try client.simulateError(status: .unavailable)
                    return "Primary result"
                },
                fallback: {
                    return "Fallback result"
                }
            )
            print("      ✅ Result: \(result)")
        } catch {
            print("      ❌ Both primary and fallback failed: \(error)")
        }
        
        // Strategy 2: Cache-based recovery
        print("\n    💾 Cache-Based Recovery:")
        recoveryManager.cache["user_123"] = "Cached user data"
        
        do {
            let result = try recoveryManager.executeWithCache(
                key: "user_123",
                operation: {
                    _ = try client.simulateError(status: .unavailable)
                    return "Fresh data"
                }
            )
            print("      ✅ Result from cache: \(result)")
        } catch {
            print("      ❌ Cache miss and operation failed: \(error)")
        }
        
        // Strategy 3: Graceful degradation
        print("\n    📉 Graceful Degradation:")
        let degradationLevels = [
            ("Full feature set", { try client.simulateError(status: .unavailable) }),
            ("Reduced feature set", { try client.simulateError(status: .unavailable) }),
            ("Basic functionality", { return "Basic response" })
        ]
        
        for (level, operation) in degradationLevels {
            do {
                let result = try operation()
                print("      ✅ \(level): \(result)")
                break
            } catch {
                print("      ❌ \(level): Failed")
            }
        }
    }
}

// MARK: - Supporting Types

enum GRPCStatus: String, CaseIterable {
    case ok = "ok"
    case cancelled = "cancelled"
    case invalidArgument = "invalid_argument"
    case notFound = "not_found"
    case permissionDenied = "permission_denied"
    case unavailable = "unavailable"
    case `internal` = "internal"
    case unauthenticated = "unauthenticated"
    
    var emoji: String {
        switch self {
        case .ok: return "✅"
        case .cancelled: return "🚫"
        case .invalidArgument: return "📋"
        case .notFound: return "🔍"
        case .permissionDenied: return "🔒"
        case .unavailable: return "🔴"
        case .internal: return "⚙️"
        case .unauthenticated: return "🔐"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .unavailable, .internal:
            return true
        default:
            return false
        }
    }
}

struct DetailedGRPCError: Error {
    let status: GRPCStatus
    let message: String
    let isRetryable: Bool
    
    init(status: GRPCStatus, message: String) {
        self.status = status
        self.message = message
        self.isRetryable = status.isRetryable
    }
}

struct RetryPolicy {
    let maxAttempts: Int
    let initialDelay: TimeInterval
    let maxDelay: TimeInterval
    let backoffMultiplier: Double
    
    init(maxAttempts: Int = 3, initialDelay: TimeInterval = 0.1, maxDelay: TimeInterval = 5.0, backoffMultiplier: Double = 2.0) {
        self.maxAttempts = maxAttempts
        self.initialDelay = initialDelay
        self.maxDelay = maxDelay
        self.backoffMultiplier = backoffMultiplier
    }
    
    func calculateDelay(attempt: Int) -> TimeInterval {
        let delay = initialDelay * pow(backoffMultiplier, Double(attempt))
        return min(delay, maxDelay)
    }
}

struct RetryExhaustedError: Error {
    let attemptsMade: Int
}

struct TimeoutError: Error {
    let timeoutDuration: TimeInterval
}

struct CircuitBreakerError: Error {
    let message: String
}

class ErrorSimulatorClient {
    private var transientFailureCount = 0
    
    func simulateError(status: GRPCStatus) throws -> String {
        if status == .ok {
            return "Success"
        }
        throw DetailedGRPCError(status: status, message: "Simulated \(status.rawValue) error")
    }
    
    func simulateSuccess() throws -> String {
        return "Success"
    }
    
    func simulateTransientError(failureCount: Int) throws -> String {
        if transientFailureCount < failureCount {
            transientFailureCount += 1
            throw DetailedGRPCError(status: .unavailable, message: "Transient failure \(transientFailureCount)")
        }
        return "Success after \(transientFailureCount) failures"
    }
    
    func simulateDelay(_ duration: TimeInterval) throws -> String {
        Thread.sleep(forTimeInterval: duration)
        return "Delayed success"
    }
}

class RetryManager {
    func executeWithRetry<T>(policy: RetryPolicy, operation: () throws -> T) throws -> T {
        var lastError: Error?
        
        for attempt in 0..<policy.maxAttempts {
            do {
                return try operation()
            } catch let error as DetailedGRPCError {
                lastError = error
                
                if !error.isRetryable {
                    throw error
                }
                
                if attempt < policy.maxAttempts - 1 {
                    let delay = policy.calculateDelay(attempt: attempt)
                    Thread.sleep(forTimeInterval: delay)
                }
            } catch {
                lastError = error
                throw error
            }
        }
        
        // Если все попытки исчерпаны, бросаем последнюю ошибку или RetryExhaustedError
        throw lastError ?? RetryExhaustedError(attemptsMade: policy.maxAttempts)
    }
}

enum CircuitBreakerState {
    case closed
    case open
    case halfOpen
}

class CircuitBreaker {
    private let failureThreshold: Int
    private let recoveryTimeout: TimeInterval
    
    private(set) var state: CircuitBreakerState = .closed
    private(set) var failureCount = 0
    private(set) var totalCalls = 0
    private(set) var failedCalls = 0
    private var lastFailureTime: Date?
    
    init(failureThreshold: Int = 5, recoveryTimeout: TimeInterval = 60.0) {
        self.failureThreshold = failureThreshold
        self.recoveryTimeout = recoveryTimeout
    }
    
    func execute<T>(operation: () throws -> T) throws -> T {
        totalCalls += 1
        
        switch state {
        case .open:
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) > recoveryTimeout {
                state = .halfOpen
            } else {
                throw CircuitBreakerError(message: "Circuit breaker is open")
            }
        case .halfOpen, .closed:
            break
        }
        
        do {
            let result = try operation()
            onSuccess()
            return result
        } catch {
            onFailure()
            throw error
        }
    }
    
    private func onSuccess() {
        failureCount = 0
        if state == .halfOpen {
            state = .closed
        }
    }
    
    private func onFailure() {
        failureCount += 1
        failedCalls += 1
        lastFailureTime = Date()
        
        if failureCount >= failureThreshold {
            state = .open
        }
    }
    
    var successRate: Double {
        guard totalCalls > 0 else { return 0.0 }
        return Double(totalCalls - failedCalls) / Double(totalCalls)
    }
}

class TimeoutManager {
    func executeWithTimeout<T>(timeout: TimeInterval, operation: () throws -> T) throws -> T {
        let startTime = Date()
        
        let result = try operation()
        
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed > timeout {
            throw TimeoutError(timeoutDuration: timeout)
        }
        
        return result
    }
}

class AdaptiveTimeoutManager {
    private var currentTimeout: TimeInterval = 1.0
    private var responseTimes: [TimeInterval] = []
    private let maxSamples = 5
    
    func executeWithAdaptiveTimeout<T>(operation: () throws -> T) throws -> T {
        let startTime = Date()
        
        do {
            let result = try operation()
            let responseTime = Date().timeIntervalSince(startTime)
            updateTimeout(responseTime: responseTime, success: true)
            return result
        } catch {
            let responseTime = Date().timeIntervalSince(startTime)
            updateTimeout(responseTime: responseTime, success: false)
            throw error
        }
    }
    
    private func updateTimeout(responseTime: TimeInterval, success: Bool) {
        responseTimes.append(responseTime)
        if responseTimes.count > maxSamples {
            responseTimes.removeFirst()
        }
        
        if success {
            let avgResponseTime = responseTimes.reduce(0, +) / Double(responseTimes.count)
            currentTimeout = max(avgResponseTime * 1.5, 0.1)
        } else {
            currentTimeout = min(currentTimeout * 1.2, 5.0)
        }
    }
    
    func getCurrentTimeout() -> TimeInterval {
        return currentTimeout
    }
}

class ErrorRecoveryManager {
    var cache: [String: String] = [:]
    
    func executeWithFallback<T>(primary: () throws -> T, fallback: () throws -> T) throws -> T {
        do {
            return try primary()
        } catch {
            return try fallback()
        }
    }
    
    func executeWithCache<T>(key: String, operation: () throws -> T) throws -> T {
        do {
            return try operation()
        } catch {
            if let cachedValue = cache[key] as? T {
                return cachedValue
            }
            throw error
        }
    }
} 
