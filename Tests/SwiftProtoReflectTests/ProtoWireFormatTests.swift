import XCTest

@testable import SwiftProtoReflect

class ProtoWireFormatTests: XCTestCase {

  var descriptor: ProtoMessageDescriptor!
  var message: ProtoDynamicMessage!

  override func setUp() {
    super.setUp()
    descriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "field1", number: 1, type: .int32, isRepeated: false, isMap: false)
      ],
      enums: [],
      nestedMessages: []
    )
    message = ProtoDynamicMessage(descriptor: descriptor)
  }

  // Positive Test: Marshal and unmarshal message
  func testMarshalAndUnmarshal() {
    message.set(field: descriptor.fields[0], value: .intValue(123))
    let wireData = ProtoWireFormat.marshal(message: message)
    XCTAssertNotNil(wireData)

    let unmarshaledMessage = ProtoWireFormat.unmarshal(data: wireData!, messageDescriptor: descriptor)
    XCTAssertEqual(unmarshaledMessage?.get(field: descriptor.fields[0])?.getInt(), 123)
  }

  // Negative Test: Unmarshal corrupted data
  func testUnmarshalCorruptedData() {
    let corruptedData = Data([0xFF, 0xFF, 0xFF])
    let unmarshaledMessage = ProtoWireFormat.unmarshal(data: corruptedData, messageDescriptor: descriptor)
    XCTAssertNil(unmarshaledMessage)
  }
}
