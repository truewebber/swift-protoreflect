import SwiftProtobuf
import XCTest

@testable import SwiftProtoReflect

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

  func testImprovedOneofAPI() {
    // Create field descriptors
    let nameField = ProtoFieldDescriptor(name: "name", number: 1, type: .string, isRepeated: false, isMap: false)

    // Create fields for first oneof
    let emailField = ProtoFieldDescriptor(name: "email", number: 2, type: .string, isRepeated: false, isMap: false)
    let phoneField = ProtoFieldDescriptor(name: "phone", number: 3, type: .string, isRepeated: false, isMap: false)

    // Create fields for second oneof
    let ageField = ProtoFieldDescriptor(name: "age", number: 4, type: .int32, isRepeated: false, isMap: false)
    let birthdayField = ProtoFieldDescriptor(
      name: "birthday",
      number: 5,
      type: .string,
      isRepeated: false,
      isMap: false
    )

    // Method 1: Using the factory method
    let messageDescriptor = ProtoMessageDescriptor.createWithOneofs(
      fullName: "Person",
      regularFields: [nameField],
      oneofs: [
        (name: "contact_info", fields: [emailField, phoneField]),
        (name: "age_info", fields: [ageField, birthdayField]),
      ]
    )

    // Test basic properties
    XCTAssertEqual(messageDescriptor.fields.count, 5)  // 1 regular + 4 oneof fields
    XCTAssertEqual(messageDescriptor.oneofs.count, 2)

    // Verify oneof relationships
    XCTAssertTrue(emailField.isOneofField)
    XCTAssertTrue(phoneField.isOneofField)
    XCTAssertTrue(ageField.isOneofField)
    XCTAssertTrue(birthdayField.isOneofField)
    XCTAssertFalse(nameField.isOneofField)

    XCTAssertEqual(emailField.oneofDescriptor?.name, "contact_info")
    XCTAssertEqual(phoneField.oneofDescriptor?.name, "contact_info")
    XCTAssertEqual(ageField.oneofDescriptor?.name, "age_info")
    XCTAssertEqual(birthdayField.oneofDescriptor?.name, "age_info")

    // Method 2: Using the builder pattern
    let contactOneof = ProtoOneofDescriptor(name: "contact_info", fields: [])
      .addField(emailField)
      .addField(phoneField)

    let ageOneof = ProtoOneofDescriptor(name: "age_info", fields: [])
      .addFields([ageField, birthdayField])

    // Verify the builder pattern worked correctly
    XCTAssertEqual(contactOneof.fields.count, 2)
    XCTAssertEqual(ageOneof.fields.count, 2)
    XCTAssertEqual(emailField.oneofDescriptor?.name, "contact_info")
    XCTAssertEqual(birthdayField.oneofDescriptor?.name, "age_info")

    // Method 3: Using the static create method
    let hobbiesField = ProtoFieldDescriptor(name: "hobbies", number: 6, type: .string, isRepeated: false, isMap: false)
    let sportsField = ProtoFieldDescriptor(name: "sports", number: 7, type: .string, isRepeated: false, isMap: false)

    let hobbyOneof = ProtoOneofDescriptor.create(name: "hobby_info", fields: [hobbiesField, sportsField])

    XCTAssertEqual(hobbyOneof.fields.count, 2)
    XCTAssertEqual(hobbiesField.oneofDescriptor?.name, "hobby_info")
    XCTAssertEqual(sportsField.oneofDescriptor?.name, "hobby_info")
  }

  func testOneofFieldClearing() {
    // Setup: Create a message with multiple oneof groups and regular fields

    // Regular fields
    let idField = ProtoFieldDescriptor(name: "id", number: 1, type: .int32, isRepeated: false, isMap: false)
    let nameField = ProtoFieldDescriptor(name: "name", number: 2, type: .string, isRepeated: false, isMap: false)

    // First oneof group: contact_info
    let emailField = ProtoFieldDescriptor(name: "email", number: 3, type: .string, isRepeated: false, isMap: false)
    let phoneField = ProtoFieldDescriptor(name: "phone", number: 4, type: .string, isRepeated: false, isMap: false)
    let addressField = ProtoFieldDescriptor(name: "address", number: 5, type: .string, isRepeated: false, isMap: false)

    // Second oneof group: id_info
    let passportField = ProtoFieldDescriptor(
      name: "passport",
      number: 6,
      type: .string,
      isRepeated: false,
      isMap: false
    )
    let driverLicenseField = ProtoFieldDescriptor(
      name: "driver_license",
      number: 7,
      type: .string,
      isRepeated: false,
      isMap: false
    )

    // Create message descriptor with oneof groups
    let messageDescriptor = ProtoMessageDescriptor.createWithOneofs(
      fullName: "Person",
      regularFields: [idField, nameField],
      oneofs: [
        (name: "contact_info", fields: [emailField, phoneField, addressField]),
        (name: "id_info", fields: [passportField, driverLicenseField]),
      ]
    )

    // Create a dynamic message
    let message = ProtoDynamicMessage(descriptor: messageDescriptor)

    // Test 1: Setting regular fields does not affect oneof fields
    message.set(fieldName: "id", value: .intValue(42))
    message.set(fieldName: "name", value: .stringValue("John Doe"))

    XCTAssertEqual(message.get(fieldName: "id")?.getInt(), 42)
    XCTAssertEqual(message.get(fieldName: "name")?.getString(), "John Doe")
    XCTAssertNil(message.get(fieldName: "email"))
    XCTAssertNil(message.get(fieldName: "phone"))
    XCTAssertNil(message.get(fieldName: "address"))
    XCTAssertNil(message.get(fieldName: "passport"))
    XCTAssertNil(message.get(fieldName: "driver_license"))

    // Test 2: Setting one field in a oneof group clears other fields in the same group
    message.set(fieldName: "email", value: .stringValue("john@example.com"))

    XCTAssertEqual(message.get(fieldName: "email")?.getString(), "john@example.com")
    XCTAssertNil(message.get(fieldName: "phone"))
    XCTAssertNil(message.get(fieldName: "address"))
    XCTAssertNil(message.get(fieldName: "passport"))
    XCTAssertNil(message.get(fieldName: "driver_license"))

    // Test 3: Setting another field in the same oneof group clears the previous field
    message.set(fieldName: "phone", value: .stringValue("+1-555-123-4567"))

    XCTAssertNil(message.get(fieldName: "email"))
    XCTAssertEqual(message.get(fieldName: "phone")?.getString(), "+1-555-123-4567")
    XCTAssertNil(message.get(fieldName: "address"))
    XCTAssertNil(message.get(fieldName: "passport"))
    XCTAssertNil(message.get(fieldName: "driver_license"))

    // Test 4: Setting a field in a different oneof group doesn't affect other groups
    message.set(fieldName: "passport", value: .stringValue("ABC123456"))

    XCTAssertNil(message.get(fieldName: "email"))
    XCTAssertEqual(message.get(fieldName: "phone")?.getString(), "+1-555-123-4567")
    XCTAssertNil(message.get(fieldName: "address"))
    XCTAssertEqual(message.get(fieldName: "passport")?.getString(), "ABC123456")
    XCTAssertNil(message.get(fieldName: "driver_license"))

    // Test 5: Setting another field in the second oneof group clears only that group
    message.set(fieldName: "driver_license", value: .stringValue("DL987654"))

    XCTAssertNil(message.get(fieldName: "email"))
    XCTAssertEqual(message.get(fieldName: "phone")?.getString(), "+1-555-123-4567")
    XCTAssertNil(message.get(fieldName: "address"))
    XCTAssertNil(message.get(fieldName: "passport"))
    XCTAssertEqual(message.get(fieldName: "driver_license")?.getString(), "DL987654")

    // Test 6: Changing back to the first field in the first oneof
    message.set(fieldName: "email", value: .stringValue("new_email@example.com"))

    XCTAssertEqual(message.get(fieldName: "email")?.getString(), "new_email@example.com")
    XCTAssertNil(message.get(fieldName: "phone"))
    XCTAssertNil(message.get(fieldName: "address"))
    XCTAssertNil(message.get(fieldName: "passport"))
    XCTAssertEqual(message.get(fieldName: "driver_license")?.getString(), "DL987654")

    // Test 7: Setting a nil value should clear the field
    message.clear(fieldName: "email")

    XCTAssertNil(message.get(fieldName: "email"))
    XCTAssertNil(message.get(fieldName: "phone"))
    XCTAssertNil(message.get(fieldName: "address"))
    XCTAssertNil(message.get(fieldName: "passport"))
    XCTAssertEqual(message.get(fieldName: "driver_license")?.getString(), "DL987654")

    // Test 8: Serialization and deserialization preserves oneof state
    message.set(fieldName: "address", value: .stringValue("123 Main St"))

    do {
      let data = try ProtoWireFormat.marshal(message: message)

      do {
        let deserializedMessage =
          try ProtoWireFormat.unmarshal(data: data, messageDescriptor: messageDescriptor) as? ProtoDynamicMessage
        XCTAssertNotNil(deserializedMessage, "Deserialized message should not be nil")

        XCTAssertEqual(deserializedMessage?.get(fieldName: "id")?.getInt(), 42)
        XCTAssertEqual(deserializedMessage?.get(fieldName: "name")?.getString(), "John Doe")
        XCTAssertNil(deserializedMessage?.get(fieldName: "email"))
        XCTAssertNil(deserializedMessage?.get(fieldName: "phone"))
        XCTAssertEqual(deserializedMessage?.get(fieldName: "address")?.getString(), "123 Main St")
        XCTAssertNil(deserializedMessage?.get(fieldName: "passport"))
        XCTAssertEqual(deserializedMessage?.get(fieldName: "driver_license")?.getString(), "DL987654")
      }
      catch {
        XCTFail("Failed to unmarshal message: \(error)")
      }
    }
    catch {
      XCTFail("Failed to marshal message: \(error)")
    }
  }
}
