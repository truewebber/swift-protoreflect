import XCTest
@testable import SwiftProtoReflect

class ProtoFieldDescriptorTests: XCTestCase {

    // Positive Test: Field descriptor equality
    func testFieldDescriptorEquality() {
        let field1 = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
        let field2 = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
        XCTAssertEqual(field1, field2)
    }

    // Negative Test: Invalid field descriptor
    func testInvalidFieldDescriptor() {
        let invalidField = ProtoFieldDescriptor(name: "", number: -1, type: .int32, isRepeated: false, isMap: false)
        XCTAssertFalse(invalidField.isValid())
    }

    // Positive Test: Field descriptor hashability
    func testFieldDescriptorHashable() {
        let field = ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
        var fieldMap = [ProtoFieldDescriptor: ProtoValue]()
        fieldMap[field] = .intValue(123)
        XCTAssertEqual(fieldMap[field]?.getInt(), 123)
    }
}
