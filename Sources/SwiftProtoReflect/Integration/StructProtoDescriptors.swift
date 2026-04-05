//
// StructProtoDescriptors.swift
// SwiftProtoReflect
//
// Shared descriptor factory for all types from google/protobuf/struct.proto.
//

/// Shared factory that provides correctly structured descriptors for all four types
/// defined in `google/protobuf/struct.proto`: `Struct`, `Value`, `ListValue`, and
/// the `NullValue` enum.
///
/// All descriptors are built once and cached via `static let`, making the factory
/// thread-safe without any locking. The descriptors are value types (`struct`/`enum`)
/// so they are inherently safe to share across threads.
///
/// The factory resolves the mutual-dependency problem between the four types
/// (Value references Struct and ListValue; Struct references Value; ListValue
/// references Value) by placing all four in a single `FileDescriptor`.
public enum StructProtoDescriptors {

  // MARK: - Shared FileDescriptor

  /// The `FileDescriptor` that contains all four struct.proto types.
  ///
  /// Name: `"google/protobuf/struct.proto"`, package: `"google.protobuf"`.
  public static let fileDescriptor: FileDescriptor = _buildFileDescriptor()

  // MARK: - Message Descriptors

  /// Descriptor for `google.protobuf.Struct`.
  ///
  /// Contains one map field:
  /// - `fields` (field 1): `map<string, google.protobuf.Value>`
  ///
  /// Also contains a nested `FieldsEntry` message for schema completeness.
  public static let structDescriptor: MessageDescriptor = fileDescriptor.messages["Struct"]!

  /// Descriptor for `google.protobuf.Value`.
  ///
  /// Contains a single `kind` oneof with six alternatives at field numbers 1–6:
  /// `null_value`, `number_value`, `string_value`, `bool_value`, `struct_value`, `list_value`.
  public static let valueDescriptor: MessageDescriptor = fileDescriptor.messages["Value"]!

  /// Descriptor for `google.protobuf.ListValue`.
  ///
  /// Contains one repeated field:
  /// - `values` (field 1): `repeated google.protobuf.Value`
  public static let listValueDescriptor: MessageDescriptor = fileDescriptor.messages["ListValue"]!

  // MARK: - Enum Descriptors

  /// Descriptor for the `google.protobuf.NullValue` enum.
  ///
  /// Contains a single value: `NULL_VALUE = 0`.
  public static let nullValueEnum: EnumDescriptor = fileDescriptor.enums["NullValue"]!

  // MARK: - Private Builder

  private static func _buildFileDescriptor() -> FileDescriptor {
    var file = FileDescriptor(
      name: "google/protobuf/struct.proto",
      package: "google.protobuf"
    )

    file.addEnum(_buildNullValueEnum(parent: file))
    file.addMessage(_buildStructMessage(parent: file))
    file.addMessage(_buildValueMessage(parent: file))
    file.addMessage(_buildListValueMessage(parent: file))

    return file
  }

  // MARK: - NullValue Enum

  private static func _buildNullValueEnum(parent: FileDescriptor) -> EnumDescriptor {
    var nullValueEnum = EnumDescriptor(name: "NullValue", parent: parent)
    nullValueEnum.addValue(EnumDescriptor.EnumValue(name: "NULL_VALUE", number: 0))
    return nullValueEnum
  }

  // MARK: - Struct Message

  private static func _buildStructMessage(parent: FileDescriptor) -> MessageDescriptor {
    var structMsg = MessageDescriptor(name: "Struct", parent: parent)

    // Nested FieldsEntry message (required for schema completeness)
    var fieldsEntry = MessageDescriptor(name: "FieldsEntry", parent: structMsg)
    fieldsEntry.addField(
      FieldDescriptor(name: "key", number: 1, type: .string)
    )
    fieldsEntry.addField(
      FieldDescriptor(
        name: "value",
        number: 2,
        type: .message,
        typeName: "google.protobuf.Value"
      )
    )
    structMsg.addNestedMessage(fieldsEntry)

    // fields: map<string, Value>  (field 1)
    structMsg.addField(
      FieldDescriptor(
        name: "fields",
        number: 1,
        type: .message,
        typeName: "google.protobuf.Struct.FieldsEntry",
        isMap: true,
        mapEntryInfo: MapEntryInfo(
          keyFieldInfo: KeyFieldInfo(name: "key", number: 1, type: .string),
          valueFieldInfo: ValueFieldInfo(
            name: "value",
            number: 2,
            type: .message,
            typeName: "google.protobuf.Value"
          )
        )
      )
    )

    return structMsg
  }

  // MARK: - Value Message

  private static func _buildValueMessage(parent: FileDescriptor) -> MessageDescriptor {
    var valueMsg = MessageDescriptor(name: "Value", parent: parent)

    // oneof kind { … }
    let kindOneof = OneofDescriptor(name: "kind", index: 0)
    valueMsg.addOneofDecl(kindOneof)

    valueMsg.addField(
      FieldDescriptor(
        name: "null_value",
        number: 1,
        type: .enum,
        typeName: "google.protobuf.NullValue",
        oneofIndex: 0
      )
    )
    valueMsg.addField(
      FieldDescriptor(name: "number_value", number: 2, type: .double, oneofIndex: 0)
    )
    valueMsg.addField(
      FieldDescriptor(name: "string_value", number: 3, type: .string, oneofIndex: 0)
    )
    valueMsg.addField(
      FieldDescriptor(name: "bool_value", number: 4, type: .bool, oneofIndex: 0)
    )
    valueMsg.addField(
      FieldDescriptor(
        name: "struct_value",
        number: 5,
        type: .message,
        typeName: "google.protobuf.Struct",
        oneofIndex: 0
      )
    )
    valueMsg.addField(
      FieldDescriptor(
        name: "list_value",
        number: 6,
        type: .message,
        typeName: "google.protobuf.ListValue",
        oneofIndex: 0
      )
    )

    return valueMsg
  }

  // MARK: - ListValue Message

  private static func _buildListValueMessage(parent: FileDescriptor) -> MessageDescriptor {
    var listValueMsg = MessageDescriptor(name: "ListValue", parent: parent)

    // values: repeated google.protobuf.Value  (field 1)
    listValueMsg.addField(
      FieldDescriptor(
        name: "values",
        number: 1,
        type: .message,
        typeName: "google.protobuf.Value",
        isRepeated: true
      )
    )

    return listValueMsg
  }
}
