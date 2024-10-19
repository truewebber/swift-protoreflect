import XCTest
@testable import SwiftProtoReflect

class FieldDecoderTests: XCTestCase {

	// Positive Test: Decode int field
	func testDecodeIntField() {
		let fieldDescriptor = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
		let encodedData = FieldEncoder.encode(fieldDescriptor: fieldDescriptor, value: .intValue(123))
		let decodedValue = FieldDecoder.decode(fieldDescriptor: fieldDescriptor, data: encodedData)
		XCTAssertEqual(decodedValue?.getInt(), 123)
	}

    // Negative Test: Decode corrupted data
    func testDecodeCorruptedData() {
        let corruptedData = Data([0xFF, 0xFF, 0xFF])
        let fieldDescriptor = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
        let decodedValue = FieldDecoder.decode(fieldDescriptor: fieldDescriptor, data: corruptedData)
        XCTAssertNil(decodedValue)
    }
}
