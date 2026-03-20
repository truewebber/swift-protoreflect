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
public struct ServiceDescriptor: Equatable, Sendable {
  // MARK: - Types

  /// Service method descriptor with name, input and output types.
  public struct MethodDescriptor: Equatable, Sendable {
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
    public let options: [String: DescriptorOption]

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
      options: [String: DescriptorOption] = [:]
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
      return lhs.name == rhs.name && lhs.inputType == rhs.inputType && lhs.outputType == rhs.outputType
        && lhs.clientStreaming == rhs.clientStreaming && lhs.serverStreaming == rhs.serverStreaming
        && lhs.options == rhs.options
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
  public let options: [String: DescriptorOption]

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
    options: [String: DescriptorOption] = [:]
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
    options: [String: DescriptorOption] = [:]
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
    guard
      lhs.name == rhs.name && lhs.fullName == rhs.fullName && lhs.fileDescriptorPath == rhs.fileDescriptorPath
        && lhs.options == rhs.options
    else {
      return false
    }

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

    return true
  }
}
