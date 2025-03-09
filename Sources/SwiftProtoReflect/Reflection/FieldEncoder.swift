import Foundation

// FieldEncoder is responsible for encoding protobuf fields into the wire format.
struct FieldEncoder {

  // Encodes a single field based on its descriptor and value.
  static func encode(fieldDescriptor: ProtoFieldDescriptor, value: ProtoValue) -> Data {
    var data = Data()

    // Encode the field number and wire type (placeholder logic, detailed encoding needed).
    let fieldNumber = fieldDescriptor.number
    let wireType = determineWireType(for: fieldDescriptor.type)

    // If the field type is unsupported, return an empty Data.
    if wireType == -1 {
      return Data()  // Unsupported field type
    }

    // Append encoded field number and wire type to data (placeholder logic).
    data.append(encodeVarint(UInt64(fieldNumber << 3 | wireType)))

    // Encode the actual field value based on the type.
    switch value {
    case .intValue(let intValue):
      data.append(encodeVarint(UInt64(intValue)))
    case .stringValue(let stringValue):
      let stringData = stringValue.data(using: .utf8)!
      data.append(encodeVarint(UInt64(stringData.count)))  // Length-delimited
      data.append(stringData)
    case .boolValue(let boolValue):
      data.append(encodeVarint(boolValue ? 1 : 0))
    // Add cases for other types as needed
    default:
      // Unsupported type - return empty data
      return Data()
    }

    return data
  }

  // Determines the wire type based on the field type.
  private static func determineWireType(for fieldType: ProtoFieldType) -> Int {
    switch fieldType {
    case .int32, .int64, .uint32, .uint64, .bool:
      return 0  // Varint wire type
    case .string, .message:
      return 2  // Length-delimited wire type
    default:
      return -1  // Unsupported type
    }
  }

  // Encodes an integer into varint format.
  private static func encodeVarint(_ value: UInt64) -> Data {
    var result = Data()
    var v = value
    while v >= 0x80 {
      result.append(UInt8(v & 0x7F | 0x80))
      v >>= 7
    }
    result.append(UInt8(v))
    return result
  }
}
