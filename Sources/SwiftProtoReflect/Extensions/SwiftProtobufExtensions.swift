import Foundation
import SwiftProtobuf

extension SwiftProtobuf.Message {
  /// Convert SwiftProtobuf message to our ProtoMessage protocol
  public func asProtoMessage() -> ProtoMessage {
    // Create a basic descriptor for the message type
    let typeName = String(describing: Self.self)

    // Create a basic descriptor with known fields
    let descriptor = ProtoMessageDescriptor(
      fullName: typeName,
      fields: getFieldsFromType(),
      enums: [],
      nestedMessages: []
    )

    // Create dynamic message
    let dynamicMessage = DynamicMessage(descriptor: descriptor)

    // Copy field values using binary serialization
    if let data = try? self.serializedData() {
      do {
        _ = try dynamicMessage.merging(serializedData: data)
      }
      catch {
        // Ignore errors during conversion since this is a best-effort conversion
      }
    }

    return dynamicMessage
  }

  /// Get fields for this message type
  private func getFieldsFromType() -> [ProtoFieldDescriptor] {
    // This is a simplified implementation
    // In a real implementation, you would use reflection or codable to get field information
    // For now, we'll just create an empty list
    return []
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
      }
      else {
        self = .unknown
      }
    }
  }
}
