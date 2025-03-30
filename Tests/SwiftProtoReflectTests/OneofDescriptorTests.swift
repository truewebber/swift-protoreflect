import XCTest
@testable import SwiftProtoReflect
import SwiftProtobuf

final class OneofDescriptorTests: XCTestCase {
  
  func testBasicOneofDescriptor() {
    // Create field descriptors
    let emailField = ProtoFieldDescriptor(
      name: "email",
      number: 1,
      type: .string,
      isRepeated: false,
      isMap: false
    )
    
    let phoneNumberField = ProtoFieldDescriptor(
      name: "phone_number",
      number: 2,
      type: .string,
      isRepeated: false,
      isMap: false
    )
    
    // Create a oneof descriptor
    let oneofDescriptor = ProtoOneofDescriptor(
      name: "contact",
      fields: [emailField, phoneNumberField]
    )
    
    // Test basic properties
    XCTAssertEqual(oneofDescriptor.name, "contact")
    XCTAssertEqual(oneofDescriptor.fields.count, 2)
    
    // Test field lookup
    XCTAssertEqual(oneofDescriptor.field(named: "email")?.name, "email")
    XCTAssertEqual(oneofDescriptor.field(number: 2)?.name, "phone_number")
    XCTAssertNil(oneofDescriptor.field(named: "nonexistent"))
    XCTAssertNil(oneofDescriptor.field(number: 999))
  }
  
  func testOneofDescriptorFromProto() {
    // Create a SwiftProtobuf oneof descriptor proto
    var oneofProto = Google_Protobuf_OneofDescriptorProto()
    oneofProto.name = "contact"
    
    // Create field descriptors
    let emailField = ProtoFieldDescriptor(
      name: "email",
      number: 1,
      type: .string,
      isRepeated: false,
      isMap: false
    )
    
    let phoneNumberField = ProtoFieldDescriptor(
      name: "phone_number",
      number: 2,
      type: .string,
      isRepeated: false,
      isMap: false
    )
    
    // Create a oneof descriptor from proto
    let oneofDescriptor = ProtoOneofDescriptor(
      oneofProto: oneofProto,
      fields: [emailField, phoneNumberField]
    )
    
    // Test basic properties
    XCTAssertEqual(oneofDescriptor.name, "contact")
    XCTAssertEqual(oneofDescriptor.fields.count, 2)
    
    // Test original proto
    XCTAssertNotNil(oneofDescriptor.originalOneofProto())
    XCTAssertEqual(oneofDescriptor.originalOneofProto()?.name, "contact")
  }
  
  func testOneofFieldsInMessageDescriptor() {
    // Create field descriptors
    let nameField = ProtoFieldDescriptor(
      name: "name",
      number: 1,
      type: .string,
      isRepeated: false,
      isMap: false
    )
    
    // Create an empty oneof descriptor first (without fields)
    let oneofDescriptor = ProtoOneofDescriptor(
      name: "contact",
      fields: []
    )
    
    // Create oneof fields with reference to the oneof descriptor
    let emailField = ProtoFieldDescriptor(
      name: "email",
      number: 2,
      type: .string,
      isRepeated: false,
      isMap: false,
      oneofDescriptor: oneofDescriptor
    )
    
    let phoneNumberField = ProtoFieldDescriptor(
      name: "phone_number",
      number: 3,
      type: .string,
      isRepeated: false,
      isMap: false,
      oneofDescriptor: oneofDescriptor
    )
    
    // Create a new oneof descriptor with the fields
    let populatedOneofDescriptor = ProtoOneofDescriptor(
      name: "contact",
      fields: [emailField, phoneNumberField]
    )
    
    // Create a message descriptor with the oneof
    let messageDescriptor = ProtoMessageDescriptor(
      fullName: "Person",
      fields: [nameField, emailField, phoneNumberField],
      enums: [],
      nestedMessages: [],
      oneofs: [populatedOneofDescriptor]
    )
    
    // Test oneof lookup in message descriptor
    XCTAssertNotNil(messageDescriptor.oneof(named: "contact"))
    XCTAssertEqual(messageDescriptor.oneof(named: "contact")?.name, "contact")
    XCTAssertEqual(messageDescriptor.oneof(named: "contact")?.fields.count, 2)
    
    // Test oneofFields helper
    let oneofFieldsMap = messageDescriptor.oneofFields()
    XCTAssertEqual(oneofFieldsMap.count, 1)
    XCTAssertEqual(oneofFieldsMap["contact"]?.count, 2)
    XCTAssertEqual(oneofFieldsMap["contact"]?[0].name, "email")
    XCTAssertEqual(oneofFieldsMap["contact"]?[1].name, "phone_number")
    
    // Test that fields know they're part of a oneof
    XCTAssertTrue(emailField.isOneofField)
    XCTAssertEqual(emailField.oneofDescriptor?.name, "contact")
    XCTAssertFalse(nameField.isOneofField)
    XCTAssertNil(nameField.oneofDescriptor)
  }
} 