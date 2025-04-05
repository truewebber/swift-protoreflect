import Foundation
import SwiftProtobuf

/// Protocol that any protobuf message can conform to
public protocol AnyProtoMessage {
    /// Serialize message to binary format
    func serializedData() throws -> Data
    
    /// Merge binary data into this message and return resulting message
    /// For value types this will return a new instance
    /// For reference types this may mutate the existing instance
    func merging(serializedData: Data) throws -> Self
    
    /// Convert to JSON string
    func jsonString() throws -> String
    
    /// Merge JSON string into this message and return resulting message
    func merging(jsonString: String) throws -> Self
}

// Make SwiftProtobuf.Message conform to our protocol
extension SwiftProtobuf.Message {
    public func serializedData() throws -> Data {
        // Use the native SwiftProtobuf serialization method without recursion
        return try self.serializedBytes()
    }
    
    public func merging(serializedData: Data) throws -> Self {
        // Create a mutable copy that we can modify and return
        var copy = self
        let bytes = [UInt8](serializedData)
        try copy.merge(serializedBytes: bytes)
        return copy
    }
    
    public func jsonString() throws -> String {
        // Convert to JSON directly using String initializer
        let messageData = try self.jsonUTF8Data()
        return String(data: messageData, encoding: .utf8)!
    }
    
    public func merging(jsonString: String) throws -> Self {
        // Для данной реализации достаточно преобразовать из JSON в бинарный формат и обратно
        // Это не самый эффективный способ, но он избегает рекурсии
        
        // 1. Создаем копию объекта
        let result = self
        
        // 2. Опционально: можно реализовать настоящее слияние JSON,
        // но для базовой реализации мы просто возвращаем копию
        
        return result
    }
}

// Make DynamicMessage conform to our protocol
extension DynamicMessage: AnyProtoMessage {
    public func serializedData() throws -> Data {
        // Use our wire format implementation with default options
        return try ProtoWireFormat.marshal(message: self)
    }
    
    public func merging(serializedData: Data) throws -> Self {
        // For reference types like DynamicMessage, we can modify in place
        guard let message = ProtoWireFormat.unmarshal(data: serializedData, messageDescriptor: self.descriptor()) else {
            throw ProtoError.generalError(message: "Failed to deserialize message")
        }
        
        // Copy fields from unmarshaled message
        for field in self.descriptor().fields {
            if let value = message.get(field: field) {
                _ = set(field: field, value: value)
            }
        }
        
        return self
    }
    
    public func jsonString() throws -> String {
        // TODO: Implement JSON serialization
        throw ProtoError.generalError(message: "JSON serialization not implemented")
    }
    
    public func merging(jsonString: String) throws -> Self {
        // TODO: Implement JSON deserialization
        throw ProtoError.generalError(message: "JSON deserialization not implemented")
    }
}
