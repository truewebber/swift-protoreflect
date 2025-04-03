import Foundation
import SwiftProtobuf

/// Protocol that any protobuf message can conform to
public protocol AnyProtoMessage {
    /// Serialize message to binary format
    func serializedData() throws -> Data
    
    /// Merge binary data into this message
    func merge(serializedData: Data) throws
    
    /// Convert to JSON string
    func jsonString() throws -> String
    
    /// Merge JSON string into this message
    func merge(jsonString: String) throws
}

// Make SwiftProtobuf.Message conform to our protocol
extension SwiftProtobuf.Message {
    public func serializedData() throws -> Data {
        return try self.serializedData()
    }
    
    public func merge(serializedData: Data) throws {
        var mutableSelf = self
        try mutableSelf.merge(serializedBytes: serializedData)
    }
    
    public func jsonString() throws -> String {
        return try self.jsonString()
    }
    
    public func merge(jsonString: String) throws {
        var mutableSelf = self
        try mutableSelf.merge(jsonString: jsonString)
    }
}

// Make DynamicMessage conform to our protocol
extension DynamicMessage: AnyProtoMessage {
    public func serializedData() throws -> Data {
        // Use our wire format implementation
        guard let data = ProtoWireFormat.marshal(message: self) else {
            throw ProtoError.generalError(message: "Failed to serialize message")
        }
        return data
    }
    
    public func merge(serializedData: Data) throws {
        // Use our wire format implementation
        guard let message = ProtoWireFormat.unmarshal(data: serializedData, messageDescriptor: self.descriptor()) else {
            throw ProtoError.generalError(message: "Failed to deserialize message")
        }
        
        // Copy fields from unmarshaled message
        for field in self.descriptor().fields {
            if let value = message.get(field: field) {
                _ = set(field: field, value: value)
            }
        }
    }
    
    public func jsonString() throws -> String {
        // TODO: Implement JSON serialization
        throw ProtoError.generalError(message: "JSON serialization not implemented")
    }
    
    public func merge(jsonString: String) throws {
        // TODO: Implement JSON deserialization
        throw ProtoError.generalError(message: "JSON deserialization not implemented")
    }
}
