//
// ServiceClient.swift
// SwiftProtoReflect
//
// Created: 2025-05-25
// Updated: 2026-01-13 - Migrated to grpc-swift-2
//

import Foundation
import GRPCCore
import NIOCore

/// ServiceClient provides a dynamic interface for calling gRPC methods
/// without pre-generating client code.
///
/// This class allows:
/// - Dynamically calling gRPC methods based on ServiceDescriptor
/// - Working with DynamicMessage for input and output data
/// - Supporting unary RPC calls
/// - Handling errors and metadata
///
/// ## Usage example:
///
/// ```swift
/// let transport = try HTTP2ClientTransport.Posix(
///   target: .dns(host: "localhost", port: 50051),
///   config: .defaults(transportSecurity: .plaintext)
/// )
///
/// try await withGRPCClient(transport: transport) { grpcClient in
///   let client = ServiceClient(client: grpcClient)
///
///   // Unary call
///   let request = try factory.createMessage(descriptor: requestDescriptor)
///   try request.set(field: "name", value: "John")
///
///   let response = try await client.unaryCall(
///     service: serviceDescriptor,
///     method: "GetUser",
///     request: request
///   )
/// }
/// ```
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public final class ServiceClient<Transport: ClientTransport>: Sendable {

  // MARK: - Types

  /// Options for calling gRPC methods.
  public struct CallOptions {
    /// Timeout for the call.
    public let timeout: Duration?

    /// Metadata to send with the request.
    public let metadata: [String: String]

    /// Creates new call options.
    public init(
      timeout: Duration? = nil,
      metadata: [String: String] = [:]
    ) {
      self.timeout = timeout
      self.metadata = metadata
    }
  }

  /// Result of a unary call.
  public struct UnaryCallResult: @unchecked Sendable {
    /// Response message.
    public let response: DynamicMessage

    /// Response metadata.
    public let metadata: Metadata

    /// Trailing metadata.
    public let trailingMetadata: Metadata

    public init(
      response: DynamicMessage,
      metadata: Metadata = [:],
      trailingMetadata: Metadata = [:]
    ) {
      self.response = response
      self.metadata = metadata
      self.trailingMetadata = trailingMetadata
    }
  }

  // MARK: - Properties

  /// gRPC client for making calls.
  private let client: GRPCClient<Transport>

  /// Factory for creating messages.
  private let messageFactory: MessageFactory

  /// Type registry for resolving descriptors.
  private let typeRegistry: TypeRegistry

  // MARK: - Initialization

  /// Creates a new ServiceClient.
  ///
  /// - Parameters:
  ///   - client: gRPC client instance.
  ///   - messageFactory: Factory for creating messages (default: new instance).
  ///   - typeRegistry: Type registry (default: new instance).
  public init(
    client: GRPCClient<Transport>,
    messageFactory: MessageFactory = MessageFactory(),
    typeRegistry: TypeRegistry = TypeRegistry()
  ) {
    self.client = client
    self.messageFactory = messageFactory
    self.typeRegistry = typeRegistry
  }

  // MARK: - Unary Calls

  /// Performs a unary gRPC call.
  ///
  /// - Parameters:
  ///   - service: Service descriptor.
  ///   - method: Method name.
  ///   - request: Request message.
  ///   - options: Call options.
  /// - Returns: Call result with response message.
  /// - Throws: ServiceClientError on errors.
  public func unaryCall(
    service: ServiceDescriptor,
    method methodName: String,
    request: DynamicMessage,
    options: CallOptions = CallOptions()
  ) async throws -> UnaryCallResult {
    // Get method descriptor
    guard let methodDescriptor = service.method(named: methodName) else {
      throw ServiceClientError.methodNotFound(methodName: methodName, serviceName: service.name)
    }

    // Check that this is a unary method
    guard !methodDescriptor.clientStreaming && !methodDescriptor.serverStreaming else {
      throw ServiceClientError.invalidMethodType(
        methodName: methodName,
        expected: "unary",
        actual: getMethodType(methodDescriptor)
      )
    }

    // Check type compatibility
    try validateRequestType(request: request, expectedType: methodDescriptor.inputType)

    // Get response type descriptor
    let responseDescriptor = try getResponseDescriptor(outputType: methodDescriptor.outputType)

    // Create method descriptor for gRPC
    let grpcServiceDescriptor = GRPCCore.ServiceDescriptor(
      fullyQualifiedService: service.fullName
    )
    let grpcMethodDescriptor = GRPCCore.MethodDescriptor(
      service: grpcServiceDescriptor,
      method: methodName
    )

    // Create serializer and deserializer
    let serializer = DynamicMessageSerializer()
    let deserializer = DynamicMessageDeserializer(descriptor: responseDescriptor)

    // Create request
    let clientRequest = ClientRequest<DynamicMessage>(
      message: request,
      metadata: createMetadata(from: options)
    )

    // Create call options
    var callOptions = GRPCCore.CallOptions.defaults
    if let timeout = options.timeout {
      callOptions.timeout = timeout
    }

    // Execute call
    return try await client.unary(
      request: clientRequest,
      descriptor: grpcMethodDescriptor,
      serializer: serializer,
      deserializer: deserializer,
      options: callOptions
    ) { response in
      UnaryCallResult(
        response: try response.message,
        metadata: response.metadata,
        trailingMetadata: response.trailingMetadata
      )
    }
  }

  // MARK: - Private Helper Methods

  /// Gets method type as a string.
  private func getMethodType(_ method: ServiceDescriptor.MethodDescriptor) -> String {
    switch (method.clientStreaming, method.serverStreaming) {
    case (false, false): return "unary"
    case (true, false): return "client streaming"
    case (false, true): return "server streaming"
    case (true, true): return "bidirectional streaming"
    }
  }

  /// Validates request type compatibility.
  private func validateRequestType(request: DynamicMessage, expectedType: String) throws {
    guard request.descriptor.fullName == expectedType else {
      throw ServiceClientError.typeMismatch(
        expected: expectedType,
        actual: request.descriptor.fullName
      )
    }
  }

  /// Gets response type descriptor.
  private func getResponseDescriptor(outputType: String) throws -> MessageDescriptor {
    guard let descriptor = typeRegistry.findMessage(named: outputType) else {
      throw ServiceClientError.typeNotFound(typeName: outputType)
    }
    return descriptor
  }

  /// Creates metadata from call options.
  private func createMetadata(from options: CallOptions) -> Metadata {
    var metadata = Metadata()
    for (key, value) in options.metadata {
      metadata.addString(value, forKey: key)
    }
    return metadata
  }
}

// MARK: - DynamicMessageSerializer

/// Serializer for DynamicMessage.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
private struct DynamicMessageSerializer: MessageSerializer {
  func serialize<Bytes: GRPCContiguousBytes>(_ message: DynamicMessage) throws -> Bytes {
    let serializer = BinarySerializer()
    let data = try serializer.serialize(message)
    let bytes = Array(data)
    return Bytes(bytes)
  }
}

// MARK: - DynamicMessageDeserializer

/// Deserializer for DynamicMessage.
@available(macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
private struct DynamicMessageDeserializer: MessageDeserializer {
  let descriptor: MessageDescriptor

  func deserialize<Bytes: GRPCContiguousBytes>(_ serializedMessageBytes: Bytes) throws -> DynamicMessage {
    let deserializer = BinaryDeserializer()
    var data = Data()
    serializedMessageBytes.withUnsafeBytes { buffer in
      data.append(contentsOf: buffer)
    }
    return try deserializer.deserialize(data, using: descriptor)
  }
}

// MARK: - ServiceClientError

/// ServiceClient errors.
public enum ServiceClientError: Error, CustomStringConvertible, Sendable {
  /// Method not found in service.
  case methodNotFound(methodName: String, serviceName: String)

  /// Invalid method type.
  case invalidMethodType(methodName: String, expected: String, actual: String)

  /// Message type mismatch.
  case typeMismatch(expected: String, actual: String)

  /// Type not found in registry.
  case typeNotFound(typeName: String)

  /// Serialization error.
  case serializationError(underlying: Error)

  /// Deserialization error.
  case deserializationError(underlying: Error)

  /// gRPC error.
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
