/**
 * WellKnownTypes.swift
 * SwiftProtoReflect
 *
 * Specialized support for standard Protocol Buffers types (google.protobuf.*)
 * Provides optimized work with frequently used types.
 */

import Foundation
import SwiftProtobuf

// MARK: - Well-Known Type Names

/// Constants for standard Protocol Buffers type names.
public struct WellKnownTypeNames {

  // MARK: - Critical Types (Phase 1)

  /// google.protobuf.Timestamp.
  public static let timestamp = "google.protobuf.Timestamp"

  /// google.protobuf.Duration.
  public static let duration = "google.protobuf.Duration"

  /// google.protobuf.Empty.
  public static let empty = "google.protobuf.Empty"

  // MARK: - Important Types (Phase 2)

  /// google.protobuf.FieldMask.
  public static let fieldMask = "google.protobuf.FieldMask"

  /// google.protobuf.Struct.
  public static let structType = "google.protobuf.Struct"

  /// google.protobuf.Value.
  public static let value = "google.protobuf.Value"

  // MARK: - Advanced Types (Phase 3)

  /// google.protobuf.Any.
  public static let any = "google.protobuf.Any"

  /// google.protobuf.ListValue.
  public static let listValue = "google.protobuf.ListValue"

  /// google.protobuf.NullValue.
  public static let nullValue = "google.protobuf.NullValue"

  // MARK: - Collections

  /// All supported well-known types.
  public static let allTypes: Set<String> = [
    timestamp, duration, empty,
    fieldMask, structType, value,
    any, listValue, nullValue,
  ]

  /// Critical types (Phase 1).
  public static let criticalTypes: Set<String> = [
    timestamp, duration, empty,
  ]

  /// Important types (Phase 2).
  public static let importantTypes: Set<String> = [
    fieldMask, structType, value,
  ]

  /// Advanced types (Phase 3).
  public static let advancedTypes: Set<String> = [
    any, listValue, nullValue,
  ]
}

// MARK: - Well-Known Type Detector

/// Utilities for detecting and working with well-known types.
public struct WellKnownTypeDetector {

  /// Checks if type is well-known.
  /// - Parameter typeName: Full type name.
  /// - Returns: true if type is well-known.
  public static func isWellKnownType(_ typeName: String) -> Bool {
    return WellKnownTypeNames.allTypes.contains(typeName)
  }

  /// Determines type support phase.
  /// - Parameter typeName: Full type name.
  /// - Returns: Support phase or nil if type is not well-known.
  public static func getSupportPhase(for typeName: String) -> WellKnownSupportPhase? {
    if WellKnownTypeNames.criticalTypes.contains(typeName) {
      return .critical
    }
    else if WellKnownTypeNames.importantTypes.contains(typeName) {
      return .important
    }
    else if WellKnownTypeNames.advancedTypes.contains(typeName) {
      return .advanced
    }
    return nil
  }

  /// Gets simple type name without package prefix.
  /// - Parameter typeName: Full type name.
  /// - Returns: Simple type name.
  public static func getSimpleName(for typeName: String) -> String? {
    guard isWellKnownType(typeName) else { return nil }
    return String(typeName.split(separator: ".").last ?? "")
  }
}

// MARK: - Support Phase

/// Well-known types support phases.
public enum WellKnownSupportPhase: Int, CaseIterable, Sendable {
  case critical = 1  // Timestamp, Duration, Empty
  case important = 2  // FieldMask, Struct, Value
  case advanced = 3  // Any, ListValue, NullValue

  /// Human-readable phase description.
  public var description: String {
    switch self {
    case .critical:
      return "Critical Types (Phase 1)"
    case .important:
      return "Important Types (Phase 2)"
    case .advanced:
      return "Advanced Types (Phase 3)"
    }
  }

  /// Types included in this phase.
  public var includedTypes: Set<String> {
    switch self {
    case .critical:
      return WellKnownTypeNames.criticalTypes
    case .important:
      return WellKnownTypeNames.importantTypes
    case .advanced:
      return WellKnownTypeNames.advancedTypes
    }
  }
}

// MARK: - Well-Known Type Handler Protocol

/// Protocol for handling specific well-known types.
public protocol WellKnownTypeHandler {

  /// Type that this handler processes.
  static var handledTypeName: String { get }

  /// Support phase.
  static var supportPhase: WellKnownSupportPhase { get }

  /// Creates specialized representation from DynamicMessage.
  /// - Parameter message: Dynamic message.
  /// - Returns: Specialized representation.
  /// - Throws: WellKnownTypeError if conversion is impossible.
  static func createSpecialized(from message: DynamicMessage) throws -> Any

  /// Creates DynamicMessage from specialized representation.
  /// - Parameter specialized: Specialized representation.
  /// - Returns: Dynamic message.
  /// - Throws: WellKnownTypeError if conversion is impossible.
  static func createDynamic(from specialized: Any) throws -> DynamicMessage

  /// Performs validation of specialized object.
  /// - Parameter specialized: Object to validate.
  /// - Returns: true if object is valid.
  static func validate(_ specialized: Any) -> Bool
}

// MARK: - Well-Known Type Errors

/// Errors when working with well-known types.
public enum WellKnownTypeError: Error, Equatable, CustomStringConvertible {

  /// Type is not supported.
  case unsupportedType(String)

  /// Conversion error between types.
  case conversionFailed(from: String, to: String, reason: String)

  /// Invalid data for type.
  case invalidData(typeName: String, reason: String)

  /// Handler for type not found.
  case handlerNotFound(String)

  /// Validation error.
  case validationFailed(typeName: String, reason: String)

  public var description: String {
    switch self {
    case .unsupportedType(let type):
      return "Unsupported well-known type: \(type)"
    case .conversionFailed(let from, let to, let reason):
      return "Failed to convert from \(from) to \(to): \(reason)"
    case .invalidData(let typeName, let reason):
      return "Invalid data for \(typeName): \(reason)"
    case .handlerNotFound(let type):
      return "Handler not found for well-known type: \(type)"
    case .validationFailed(let typeName, let reason):
      return "Validation failed for \(typeName): \(reason)"
    }
  }
}

// MARK: - Well-Known Types Registry

/// Registry of well-known type handlers.
public final class WellKnownTypesRegistry: @unchecked Sendable {

  /// Singleton instance.
  public static let shared = WellKnownTypesRegistry()

  /// Registered handlers.
  private var handlers: [String: WellKnownTypeHandler.Type] = [:]

  /// Mutex for thread-safety.
  private let handlersMutex = NSLock()

  private init() {
    // Register basic handlers
    registerDefaultHandlers()
  }

  /// Registers handler for type.
  /// - Parameter handlerType: Handler type.
  public func register<T: WellKnownTypeHandler>(_ handlerType: T.Type) {
    handlersMutex.lock()
    defer { handlersMutex.unlock() }

    handlers[handlerType.handledTypeName] = handlerType
  }

  /// Gets handler for type.
  /// - Parameter typeName: Type name.
  /// - Returns: Handler or nil if not found.
  public func getHandler(for typeName: String) -> WellKnownTypeHandler.Type? {
    handlersMutex.lock()
    defer { handlersMutex.unlock() }

    return handlers[typeName]
  }

  /// Creates specialized object from DynamicMessage.
  /// - Parameters:
  ///   - message: Dynamic message.
  ///   - typeName: Well-known type name.
  /// - Returns: Specialized object.
  /// - Throws: WellKnownTypeError.
  public func createSpecialized(from message: DynamicMessage, typeName: String) throws -> Any {
    guard let handler = getHandler(for: typeName) else {
      throw WellKnownTypeError.handlerNotFound(typeName)
    }

    return try handler.createSpecialized(from: message)
  }

  /// Creates DynamicMessage from specialized object.
  /// - Parameters:
  ///   - specialized: Specialized object.
  ///   - typeName: Well-known type name.
  /// - Returns: Dynamic message.
  /// - Throws: WellKnownTypeError.
  public func createDynamic(from specialized: Any, typeName: String) throws -> DynamicMessage {
    guard let handler = getHandler(for: typeName) else {
      throw WellKnownTypeError.handlerNotFound(typeName)
    }

    return try handler.createDynamic(from: specialized)
  }

  /// Gets all registered types.
  /// - Returns: Set of type names.
  public func getRegisteredTypes() -> Set<String> {
    handlersMutex.lock()
    defer { handlersMutex.unlock() }

    return Set(handlers.keys)
  }

  /// Clears all registered handlers.
  public func clear() {
    handlersMutex.lock()
    defer { handlersMutex.unlock() }

    handlers.removeAll()
  }

  // MARK: - Private Methods

  /// Registers default handlers.
  private func registerDefaultHandlers() {
    // Critical types (Phase 1)
    register(TimestampHandler.self)
    register(DurationHandler.self)
    register(EmptyHandler.self)

    // Important types (Phase 2)
    register(FieldMaskHandler.self)
    register(StructHandler.self)
    register(ValueHandler.self)

    // Advanced types (Phase 3)
    register(AnyHandler.self)
  }
}
