//
// ServiceDescriptor.swift
// SwiftProtoReflect
//
// Created: 2025-05-23
//

import Foundation
import SwiftProtobuf

/// ServiceDescriptor.
///
/// Protocol Buffers service descriptor that describes a gRPC service,
/// its methods, input and output message types, and options.
public struct ServiceDescriptor: Equatable {
  // MARK: - Types

  /// Service method descriptor with name, input and output types.
  public struct MethodDescriptor: Equatable {
    /// Method name (e.g., "GetUser").
    public let name: String

    /// Full name of input message type (e.g., "example.GetUserRequest").
    public let inputType: String

    /// Full name of output message type (e.g., "example.GetUserResponse").
    public let outputType: String

    /// Indicates if the method is client streaming.
    public let clientStreaming: Bool

    /// Indicates if the method is server streaming.
    public let serverStreaming: Bool

    /// Method options.
    public let options: [String: Any]

    /// Creates a new method descriptor.
    ///
    /// - Parameters:
    ///   - name: Method name.
    ///   - inputType: Full name of input message type.
    ///   - outputType: Full name of output message type.
    ///   - clientStreaming: Client streaming flag.
    ///   - serverStreaming: Server streaming flag.
    ///   - options: Method options.
    public init(
      name: String,
      inputType: String,
      outputType: String,
      clientStreaming: Bool = false,
      serverStreaming: Bool = false,
      options: [String: Any] = [:]
    ) {
      self.name = name
      self.inputType = inputType
      self.outputType = outputType
      self.clientStreaming = clientStreaming
      self.serverStreaming = serverStreaming
      self.options = options
    }

    // MARK: - Equatable

    public static func == (lhs: MethodDescriptor, rhs: MethodDescriptor) -> Bool {
      guard
        lhs.name == rhs.name && lhs.inputType == rhs.inputType && lhs.outputType == rhs.outputType
          && lhs.clientStreaming == rhs.clientStreaming && lhs.serverStreaming == rhs.serverStreaming
      else {
        return false
      }

      // Compare options: check keys and values
      let lhsKeys = Set(lhs.options.keys)
      let rhsKeys = Set(rhs.options.keys)

      guard lhsKeys == rhsKeys else {
        return false
      }

      // Check value matching for all keys
      for key in lhsKeys {
        let lhsValue = lhs.options[key]
        let rhsValue = rhs.options[key]

        // Check known value types
        if let lhsBool = lhsValue as? Bool, let rhsBool = rhsValue as? Bool {
          if lhsBool != rhsBool {
            return false
          }
        }
        else if let lhsInt = lhsValue as? Int, let rhsInt = rhsValue as? Int {
          if lhsInt != rhsInt {
            return false
          }
        }
        else if let lhsString = lhsValue as? String, let rhsString = rhsValue as? String {
          if lhsString != rhsString {
            return false
          }
        }
        else {
          // For other types, compare string representations
          if String(describing: lhsValue) != String(describing: rhsValue) {
            return false
          }
        }
      }

      return true
    }
  }

  // MARK: - Properties

  /// Service name (e.g., "UserService").
  public let name: String

  /// Full service name including package (e.g., "example.UserService").
  public let fullName: String

  /// Path to parent file (for reference resolution).
  public var fileDescriptorPath: String?

  /// List of service methods by name.
  public private(set) var methodsByName: [String: MethodDescriptor] = [:]

  /// Service options.
  public let options: [String: Any]

  // MARK: - Initialization

  /// Creates a new ServiceDescriptor instance.
  ///
  /// - Parameters:
  ///   - name: Service name.
  ///   - fullName: Full service name.
  ///   - options: Service options.
  public init(
    name: String,
    fullName: String,
    options: [String: Any] = [:]
  ) {
    self.name = name
    self.fullName = fullName
    self.options = options
  }

  /// Creates a new ServiceDescriptor instance with a base name.
  ///
  /// Full name will be generated automatically based on parent file.
  ///
  /// - Parameters:
  ///   - name: Service name.
  ///   - parent: Parent file.
  ///   - options: Service options.
  public init(
    name: String,
    parent: FileDescriptor,
    options: [String: Any] = [:]
  ) {
    self.name = name
    self.options = options
    self.fullName = parent.getFullName(for: name)
    self.fileDescriptorPath = parent.name
  }

  // MARK: - Method Methods

  /// Adds a method to the service.
  ///
  /// - Parameter method: Method descriptor to add.
  /// - Returns: Updated ServiceDescriptor.
  @discardableResult
  public mutating func addMethod(_ method: MethodDescriptor) -> Self {
    methodsByName[method.name] = method
    return self
  }

  /// Checks if the service contains the specified method.
  ///
  /// - Parameter name: Method name.
  /// - Returns: true if the method exists.
  public func hasMethod(named name: String) -> Bool {
    return methodsByName[name] != nil
  }

  /// Gets a method by name.
  ///
  /// - Parameter name: Method name.
  /// - Returns: Method descriptor if it exists.
  public func method(named name: String) -> MethodDescriptor? {
    return methodsByName[name]
  }

  /// Gets a list of all service methods.
  ///
  /// - Returns: List of methods.
  public func allMethods() -> [MethodDescriptor] {
    return Array(methodsByName.values)
  }

  // MARK: - Equatable

  public static func == (lhs: ServiceDescriptor, rhs: ServiceDescriptor) -> Bool {
    // Compare main properties
    guard lhs.name == rhs.name && lhs.fullName == rhs.fullName && lhs.fileDescriptorPath == rhs.fileDescriptorPath
    else {
      return false
    }

    // Compare methods
    let lhsMethodsByName = lhs.methodsByName
    let rhsMethodsByName = rhs.methodsByName

    guard lhsMethodsByName.count == rhsMethodsByName.count else {
      return false
    }

    for (name, lhsMethod) in lhsMethodsByName {
      guard let rhsMethod = rhsMethodsByName[name], lhsMethod == rhsMethod else {
        return false
      }
    }

    // Compare options
    let lhsKeys = Set(lhs.options.keys)
    let rhsKeys = Set(rhs.options.keys)

    guard lhsKeys == rhsKeys else {
      return false
    }

    // Check value matching for all keys
    for key in lhsKeys {
      let lhsValue = lhs.options[key]
      let rhsValue = rhs.options[key]

      // Check known value types
      if let lhsBool = lhsValue as? Bool, let rhsBool = rhsValue as? Bool {
        if lhsBool != rhsBool {
          return false
        }
      }
      else if let lhsInt = lhsValue as? Int, let rhsInt = rhsValue as? Int {
        if lhsInt != rhsInt {
          return false
        }
      }
      else if let lhsString = lhsValue as? String, let rhsString = rhsValue as? String {
        if lhsString != rhsString {
          return false
        }
      }
      else {
        // For other types, compare string representations
        if String(describing: lhsValue) != String(describing: rhsValue) {
          return false
        }
      }
    }

    return true
  }
}
