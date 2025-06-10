//
// ServiceClient.swift
// SwiftProtoReflect
//
// Created: 2025-05-25
//

import Foundation
import GRPC
import NIOCore
import SwiftProtobuf

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
/// let client = ServiceClient(channel: channel)
///
/// // Unary call
/// let request = try factory.createMessage(descriptor: requestDescriptor)
/// try request.set(field: "name", value: "John")
///
/// let response = try await client.unaryCall(
///   service: serviceDescriptor,
///   method: "GetUser",
///   request: request
/// )
/// ```
public final class ServiceClient {

  // MARK: - Types

  /// Options for calling gRPC methods.
  public struct CallOptions {
    /// Timeout for the call.
    public let timeout: TimeAmount?

    /// Metadata to send with the request.
    public let metadata: [String: String]

    /// Creates new call options.
    public init(
      timeout: TimeAmount? = nil,
      metadata: [String: String] = [:]
    ) {
      self.timeout = timeout
      self.metadata = metadata
    }
  }

  /// Result of a unary call.
  public struct UnaryCallResult {
    /// Response message.
    public let response: DynamicMessage

    /// Response metadata (simplified version).
    public let metadata: [String: String]

    /// Trailing metadata (simplified version).
    public let trailingMetadata: [String: String]

    public init(
      response: DynamicMessage,
      metadata: [String: String] = [:],
      trailingMetadata: [String: String] = [:]
    ) {
      self.response = response
      self.metadata = metadata
      self.trailingMetadata = trailingMetadata
    }
  }

  // MARK: - Properties

  /// gRPC channel for connecting to the server.
  private let channel: GRPCChannel

  /// Factory for creating messages.
  private let messageFactory: MessageFactory

  /// Type registry for resolving descriptors.
  private let typeRegistry: TypeRegistry

  // MARK: - Initialization

  /// Creates a new ServiceClient.
  ///
  /// - Parameters:
  ///   - channel: gRPC channel for connection.
  ///   - messageFactory: Factory for creating messages (default: new instance).
  ///   - typeRegistry: Type registry (default: new instance).
  public init(
    channel: GRPCChannel,
    messageFactory: MessageFactory = MessageFactory(),
    typeRegistry: TypeRegistry = TypeRegistry()
  ) {
    self.channel = channel
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

    // Serialize request
    let requestData = try serializeRequest(request)

    // Form method path
    let path = "/\(service.fullName)/\(methodName)"

    // Create gRPC call using low-level API
    let call: UnaryCall<GRPCPayloadWrapper, GRPCPayloadWrapper> = channel.makeUnaryCall(
      path: path,
      request: GRPCPayloadWrapper(data: requestData),
      callOptions: createGRPCCallOptions(from: options),
      interceptors: []
    )

    // Execute call and handle result
    let grpcResponse = try await call.response.get()

    // Deserialize response
    let responseMessage = try deserializeResponse(
      data: grpcResponse.data,
      descriptor: responseDescriptor
    )

    return UnaryCallResult(
      response: responseMessage,
      metadata: [:],  // Simplified version - empty metadata
      trailingMetadata: [:]
    )
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

  /// Serializes request message.
  private func serializeRequest(_ request: DynamicMessage) throws -> Data {
    let serializer = BinarySerializer()
    return try serializer.serialize(request)
  }

  /// Deserializes response message.
  private func deserializeResponse(data: Data, descriptor: MessageDescriptor) throws -> DynamicMessage {
    let deserializer = BinaryDeserializer()
    return try deserializer.deserialize(data, using: descriptor)
  }

  /// Creates gRPC call options from our options.
  private func createGRPCCallOptions(from options: CallOptions) -> GRPC.CallOptions {
    var grpcOptions = GRPC.CallOptions()

    if let timeout = options.timeout {
      grpcOptions.timeLimit = .timeout(timeout)
    }

    for (key, value) in options.metadata {
      grpcOptions.customMetadata.add(name: key, value: value)
    }

    return grpcOptions
  }
}

// MARK: - GRPCPayloadWrapper

/// Wrapper for Data to conform to GRPCPayload protocol.
internal struct GRPCPayloadWrapper: GRPCPayload {
  let data: Data

  init(data: Data) {
    self.data = data
  }

  func serialize(into buffer: inout ByteBuffer) throws {
    buffer.writeData(data)
  }

  init(serializedByteBuffer: inout ByteBuffer) throws {
    self.data = Data(buffer: serializedByteBuffer)
  }
}

// MARK: - ServiceClientError

/// ServiceClient errors.
public enum ServiceClientError: Error, CustomStringConvertible {
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
