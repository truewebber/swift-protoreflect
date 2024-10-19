import Foundation

// FieldDecoder is responsible for decoding protobuf fields from the wire format.
struct FieldDecoder {
	
	// Decodes a single field from the wire format using the field descriptor.
	static func decode(fieldDescriptor: ProtoFieldDescriptor, data: Data) -> ProtoValue? {
		var dataStream = data
		let wireType = determineWireType(for: fieldDescriptor.type)
		
		switch wireType {
		case 0: // Varint
			let (varint, _) = decodeVarint(dataStream)
			if let intValue = varint {
				return .intValue(Int(intValue))
			}
		case 2: // Length-delimited
			let (length, lengthBytes) = decodeVarint(dataStream)
			dataStream.removeFirst(lengthBytes)
			if let length = length {
				let fieldData = dataStream.prefix(Int(length))
				if fieldDescriptor.type == .string, let stringValue = String(data: fieldData, encoding: .utf8) {
					return .stringValue(stringValue)
				}
				// Add additional decoding logic for other field types
			}
		default:
			break
		}
		
		return nil // Return nil if decoding fails or unsupported field type
	}

	// Determines the wire type based on the field type.
	private static func determineWireType(for fieldType: ProtoFieldType) -> Int {
		switch fieldType {
		case .int32, .int64, .uint32, .uint64, .bool:
			return 0 // Varint wire type
		case .string, .message:
			return 2 // Length-delimited wire type
		default:
			return 0 // Default wire type
		}
	}

	// Decodes an integer from varint format.
	private static func decodeVarint(_ data: Data) -> (UInt64?, Int) {
		var value: UInt64 = 0
		var shift: UInt64 = 0
		var consumedBytes = 0

		for byte in data {
			value |= UInt64(byte & 0x7F) << shift
			shift += 7
			consumedBytes += 1
			if byte & 0x80 == 0 {
				return (value, consumedBytes)
			}
		}
		
		return (nil, consumedBytes) // Return nil if varint decoding fails
	}
}
