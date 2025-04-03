import Foundation
import SwiftProtobuf

extension SwiftProtobuf.Message {
    /// Convert SwiftProtobuf message to our ProtoMessage protocol
    public func asProtoMessage() -> ProtoMessage {
        // Get file descriptor
        let fileDescriptor = Self.protoFileDescriptor
        
        // Find message descriptor in file
        let messageDescriptor = fileDescriptor.messageType.first { 
            $0.name == String(describing: Self.self)
        }
        
        guard let messageDescriptor = messageDescriptor else {
            fatalError("Could not find descriptor for \(Self.self)")
        }
        
        // Create our descriptor
        let descriptor = ProtoMessageDescriptor(
            descriptorProto: messageDescriptor,
            packageName: fileDescriptor.package
        )
        
        // Create dynamic message
        let dynamicMessage = DynamicMessage(descriptor: descriptor)
        
        // Copy field values using binary serialization
        let data = try? self.serializedData()
        if let data = data {
            try? dynamicMessage.mergeFromProtobuf(data)
        }
        
        return dynamicMessage
    }
    
    /// Get value for field number
    private func getValue(_ fieldNumber: Int) -> Any? {
        // This would need to use runtime reflection or codable
        // to access field values. For now just a placeholder
        return nil
    }
}

extension ProtoFieldType {
    /// Create field type from SwiftProtobuf type
    init(swiftType: Any.Type) {
        // Map Swift types to proto types
        switch swiftType {
        case is Int32.Type:
            self = .int32
        case is Int64.Type:
            self = .int64
        case is UInt32.Type:
            self = .uint32
        case is UInt64.Type:
            self = .uint64
        case is Float.Type:
            self = .float
        case is Double.Type:
            self = .double
        case is Bool.Type:
            self = .bool
        case is String.Type:
            self = .string
        case is Data.Type:
            self = .bytes
        default:
            // Check if it's a message type
            if swiftType is SwiftProtobuf.Message.Type {
                self = .message()
            } else {
                self = .unknown
            }
        }
    }
}
