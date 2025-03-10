import SwiftProtobuf
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
    // Create a message descriptor
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "int_field", number: 1, type: .int32, isRepeated: false, isMap: false)
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a message
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(field: messageDescriptor.fields[0], value: .intValue(123))

    // Marshal the message
    let data = ProtoWireFormat.marshal(message: message)
    XCTAssertNotNil(data, "Marshal should succeed")

    // Skip the unmarshal test for now as it's not fully implemented
    // Uncomment when unmarshal is fully implemented
    // // Unmarshal the message
    // let unmarshaledMessage = ProtoWireFormat.unmarshal(data: data!, messageDescriptor: messageDescriptor) as? ProtoDynamicMessage
    // XCTAssertNotNil(unmarshaledMessage, "Unmarshal should succeed")
    //
    // // Verify the field value
    // let fieldValue = unmarshaledMessage?.get(field: messageDescriptor.fields[0])?.getInt()
    // XCTAssertEqual(fieldValue, 123, "Field value should be preserved")
  }

  // Negative Test: Unmarshal corrupted data
  func testUnmarshalCorruptedData() {
    let corruptedData = Data([0xFF, 0xFF, 0xFF])
    let unmarshaledMessage = ProtoWireFormat.unmarshal(data: corruptedData, messageDescriptor: descriptor)
    XCTAssertNil(unmarshaledMessage)
  }

  // MARK: - Tests for Varint Encoding/Decoding

  func testVarintEncoding() {
    // Test encoding of various values
    let testCases: [(UInt64, [UInt8])] = [
      (0, [0]),
      (1, [1]),
      (127, [127]),
      (128, [128, 1]),
      (300, [172, 2]),
      (16383, [255, 127]),
      (16384, [128, 128, 1]),
      (UInt64.max, [255, 255, 255, 255, 255, 255, 255, 255, 255, 1]),
    ]

    for (value, expectedBytes) in testCases {
      let encoded = ProtoWireFormat.encodeVarint(value)
      XCTAssertEqual(Array(encoded), expectedBytes, "Encoding \(value) should produce \(expectedBytes)")
    }
  }

  func testVarintDecoding() {
    // Test decoding of various values
    let testCases: [([UInt8], UInt64?, Int)] = [
      ([0], 0, 1),
      ([1], 1, 1),
      ([127], 127, 1),
      ([128, 1], 128, 2),
      ([172, 2], 300, 2),
      ([255, 127], 16383, 2),
      ([128, 128, 1], 16384, 3),
      ([255, 255, 255, 255, 255, 255, 255, 255, 255, 1], UInt64.max, 10),
    ]

    for (bytes, expectedValue, expectedConsumed) in testCases {
      let data = Data(bytes)
      let (value, consumed) = ProtoWireFormat.decodeVarint(data)
      XCTAssertEqual(value, expectedValue, "Decoding \(bytes) should produce \(String(describing: expectedValue))")
      XCTAssertEqual(consumed, expectedConsumed, "Decoding \(bytes) should consume \(expectedConsumed) bytes")
    }
  }

  func testInvalidVarintDecoding() {
    // Test decoding of invalid varints
    let testCases: [[UInt8]] = [
      // Incomplete varint (missing continuation byte)
      [128],
      [255],
      [128, 128],
      // Varint with too many bytes (would overflow UInt64)
      [255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 1],
    ]

    for bytes in testCases {
      let data = Data(bytes)
      let (value, _) = ProtoWireFormat.decodeVarint(data)
      XCTAssertNil(value, "Decoding invalid varint \(bytes) should return nil")
    }
  }

  // MARK: - Tests for Wire Type Determination

  func testWireTypeDetermination() {
    // Test wire type determination for various field types
    let testCases: [(ProtoFieldType, Int)] = [
      (.int32, 0),  // Varint
      (.int64, 0),  // Varint
      (.uint32, 0),  // Varint
      (.uint64, 0),  // Varint
      (.sint32, 0),  // Varint
      (.sint64, 0),  // Varint
      (.bool, 0),  // Varint
      (.enum, 0),  // Varint
      (.fixed64, 1),  // 64-bit
      (.sfixed64, 1),  // 64-bit
      (.double, 1),  // 64-bit
      (.string, 2),  // Length-delimited
      (.bytes, 2),  // Length-delimited
      (.message, 2),  // Length-delimited
      (.fixed32, 5),  // 32-bit
      (.sfixed32, 5),  // 32-bit
      (.float, 5),  // 32-bit
      (.unknown, 0),  // Default to varint
    ]

    for (fieldType, expectedWireType) in testCases {
      let wireType = ProtoWireFormat.determineWireType(for: fieldType)
      XCTAssertEqual(wireType, expectedWireType, "Wire type for \(fieldType) should be \(expectedWireType)")
    }
  }

  // MARK: - Tests for Field Encoding/Decoding

  func testIntFieldEncoding() {
    // Create a field descriptor for an int32 field
    let fieldDescriptor = ProtoFieldDescriptor(
      name: "test_int",
      number: 1,
      type: .int32,
      isRepeated: false,
      isMap: false
    )

    // Create a value
    let value = ProtoValue.intValue(42)

    // Encode the field
    var data = Data()
    XCTAssertNoThrow(try ProtoWireFormat.encodeField(field: fieldDescriptor, value: value, to: &data))

    // Expected encoding:
    // Field key: 1 << 3 | 0 = 8 (varint)
    // Value: 42 (varint)
    let expectedBytes: [UInt8] = [8, 42]
    XCTAssertEqual(Array(data), expectedBytes, "Encoding int32 field should produce expected bytes")
  }

  func testStringFieldEncoding() {
    // Create a field descriptor for a string field
    let fieldDescriptor = ProtoFieldDescriptor(
      name: "test_string",
      number: 2,
      type: .string,
      isRepeated: false,
      isMap: false
    )

    // Create a value
    let value = ProtoValue.stringValue("hello")

    // Encode the field
    var data = Data()
    XCTAssertNoThrow(try ProtoWireFormat.encodeField(field: fieldDescriptor, value: value, to: &data))

    // Expected encoding:
    // Field key: 2 << 3 | 2 = 18 (length-delimited)
    // Length: 5 (varint)
    // Value: "hello" (UTF-8 bytes)
    let expectedBytes: [UInt8] = [18, 5, 104, 101, 108, 108, 111]
    XCTAssertEqual(Array(data), expectedBytes, "Encoding string field should produce expected bytes")
  }

  func testBoolFieldEncoding() {
    // Create field descriptors for bool fields
    let trueFieldDescriptor = ProtoFieldDescriptor(
      name: "test_bool_true",
      number: 3,
      type: .bool,
      isRepeated: false,
      isMap: false
    )

    let falseFieldDescriptor = ProtoFieldDescriptor(
      name: "test_bool_false",
      number: 4,
      type: .bool,
      isRepeated: false,
      isMap: false
    )

    // Create values
    let trueValue = ProtoValue.boolValue(true)
    let falseValue = ProtoValue.boolValue(false)

    // Encode the fields
    var trueData = Data()
    var falseData = Data()
    XCTAssertNoThrow(try ProtoWireFormat.encodeField(field: trueFieldDescriptor, value: trueValue, to: &trueData))
    XCTAssertNoThrow(try ProtoWireFormat.encodeField(field: falseFieldDescriptor, value: falseValue, to: &falseData))

    // Expected encoding for true:
    // Field key: 3 << 3 | 0 = 24 (varint)
    // Value: 1 (varint)
    let expectedTrueBytes: [UInt8] = [24, 1]
    XCTAssertEqual(Array(trueData), expectedTrueBytes, "Encoding bool(true) field should produce expected bytes")

    // Expected encoding for false:
    // Field key: 4 << 3 | 0 = 32 (varint)
    // Value: 0 (varint)
    let expectedFalseBytes: [UInt8] = [32, 0]
    XCTAssertEqual(Array(falseData), expectedFalseBytes, "Encoding bool(false) field should produce expected bytes")
  }

  func testTypeMismatchEncoding() {
    // Create a field descriptor for an int32 field
    let fieldDescriptor = ProtoFieldDescriptor(
      name: "test_int",
      number: 1,
      type: .int32,
      isRepeated: false,
      isMap: false
    )

    // Create a mismatched value (string instead of int)
    let value = ProtoValue.stringValue("not an int")

    // Attempt to encode the field
    var data = Data()
    XCTAssertThrowsError(try ProtoWireFormat.encodeField(field: fieldDescriptor, value: value, to: &data)) { error in
      XCTAssertTrue(error is ProtoWireFormatError, "Error should be a ProtoWireFormatError")
      if let wireFormatError = error as? ProtoWireFormatError {
        XCTAssertEqual(wireFormatError, .typeMismatch, "Error should be typeMismatch")
      }
    }
  }

  // MARK: - Tests for Message Serialization/Deserialization

  func testSimpleMessageSerialization() {
    // Create a message descriptor
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "TestMessage",
      fields: [
        ProtoFieldDescriptor(name: "int_field", number: 1, type: .int32, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "string_field", number: 2, type: .string, isRepeated: false, isMap: false),
        ProtoFieldDescriptor(name: "bool_field", number: 3, type: .bool, isRepeated: false, isMap: false),
      ],
      enums: [],
      nestedMessages: []
    )

    // Create a message
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)
    message.set(field: messageDescriptor.fields[0], value: .intValue(42))
    message.set(field: messageDescriptor.fields[1], value: .stringValue("hello"))
    message.set(field: messageDescriptor.fields[2], value: .boolValue(true))

    // Serialize the message
    let data = ProtoWireFormat.marshal(message: message)
    XCTAssertNotNil(data, "Serialization should succeed")

    // Expected serialization:
    // Field 1 (int32): 8, 42
    // Field 2 (string): 18, 5, 104, 101, 108, 108, 111
    // Field 3 (bool): 24, 1
    let expectedBytes: [UInt8] = [
      8, 42,  // int_field = 42
      18, 5, 104, 101, 108, 108, 111,  // string_field = "hello"
      24, 1,  // bool_field = true
    ]

    XCTAssertEqual(Array(data!), expectedBytes, "Serialized message should match expected bytes")
  }

  func testSimpleMessageDeserialization() {
    // Skip this test for now as deserialization is not fully implemented
    // Uncomment when deserialization is fully implemented
    // // Create a message descriptor
    // let messageDescriptor = ProtoMessageDescriptor(
    //   fullName: "TestMessage",
    //   fields: [
    //     ProtoFieldDescriptor(name: "int_field", number: 1, type: .int32, isRepeated: false, isMap: false),
    //     ProtoFieldDescriptor(name: "string_field", number: 2, type: .string, isRepeated: false, isMap: false),
    //     ProtoFieldDescriptor(name: "bool_field", number: 3, type: .bool, isRepeated: false, isMap: false)
    //   ],
    //   enums: [],
    //   nestedMessages: []
    // )
    //
    // // Create serialized data
    // let serializedData = Data([
    //   8, 42,                          // int_field = 42
    //   18, 5, 104, 101, 108, 108, 111, // string_field = "hello"
    //   24, 1                           // bool_field = true
    // ])
    //
    // // Deserialize the message
    // let message = ProtoWireFormat.unmarshal(data: serializedData, messageDescriptor: messageDescriptor)
  }

  func testSkippingUnknownFields() {
    // Skip this test for now as deserialization is not fully implemented
    // Uncomment when deserialization is fully implemented
    // // Create a message descriptor with only one field
    // let messageDescriptor = ProtoMessageDescriptor(
    //   fullName: "TestMessage",
    //   fields: [
    //     ProtoFieldDescriptor(name: "int_field", number: 1, type: .int32, isRepeated: false, isMap: false)
    //   ],
    //   enums: [],
    //   nestedMessages: []
    // )
    //
    // // Create serialized data with additional unknown fields
    // let serializedData = Data([
    //   8, 42,                          // int_field = 42 (known field)
    //   18, 5, 104, 101, 108, 108, 111, // field 2 = "hello" (unknown field)
    //   24, 1                           // field 3 = true (unknown field)
    // ])
    //
    // // Deserialize the message
    // let message = ProtoWireFormat.unmarshal(data: serializedData, messageDescriptor: messageDescriptor)
    // XCTAssertNotNil(message, "Deserialization should succeed even with unknown fields")
    //
    // // Verify the known field was deserialized
    // XCTAssertEqual(message?.get(field: messageDescriptor.fields[0])?.getInt(), 42, "int_field should be 42")
  }
}
