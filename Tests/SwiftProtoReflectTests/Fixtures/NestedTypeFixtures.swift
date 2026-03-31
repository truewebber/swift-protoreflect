import SwiftProtobuf

@testable import SwiftProtoReflect

// MARK: - Protobuf descriptor factory helpers

func makeFieldProto(
  name: String,
  number: Int32,
  type: Google_Protobuf_FieldDescriptorProto.TypeEnum,
  label: Google_Protobuf_FieldDescriptorProto.Label = .optional,
  typeName: String? = nil
) -> Google_Protobuf_FieldDescriptorProto {
  var f = Google_Protobuf_FieldDescriptorProto()
  f.name = name
  f.number = number
  f.type = type
  f.label = label
  if let typeName { f.typeName = typeName }
  return f
}

func makeEnumProto(
  name: String,
  values: [(name: String, number: Int32)]
) -> Google_Protobuf_EnumDescriptorProto {
  var e = Google_Protobuf_EnumDescriptorProto()
  e.name = name
  e.value = values.map { v in
    var ev = Google_Protobuf_EnumValueDescriptorProto()
    ev.name = v.name
    ev.number = v.number
    return ev
  }
  return e
}

func makeMessageProto(
  name: String,
  fields: [Google_Protobuf_FieldDescriptorProto] = [],
  nestedMessages: [Google_Protobuf_DescriptorProto] = [],
  nestedEnums: [Google_Protobuf_EnumDescriptorProto] = []
) -> Google_Protobuf_DescriptorProto {
  var m = Google_Protobuf_DescriptorProto()
  m.name = name
  m.field = fields
  m.nestedType = nestedMessages
  m.enumType = nestedEnums
  return m
}

func makeFileProto(
  name: String,
  package: String,
  syntax: String = "proto3",
  messages: [Google_Protobuf_DescriptorProto] = [],
  enums: [Google_Protobuf_EnumDescriptorProto] = []
) -> Google_Protobuf_FileDescriptorProto {
  var f = Google_Protobuf_FileDescriptorProto()
  f.name = name
  f.package = package
  f.syntax = syntax
  f.messageType = messages
  f.enumType = enums
  return f
}

// MARK: - Pre-built scenario fixtures

/// Fixture: GetGroupedAdsResponse with nested Cursor and Item types.
///
/// pkg.GetGroupedAdsResponse { repeated Item items = 1; Cursor cursor = 2;
/// message Cursor { string next_page_token = 1; } message Item { string id = 1; } }
var adsResponseFileProto: Google_Protobuf_FileDescriptorProto {
  let cursor = makeMessageProto(
    name: "Cursor",
    fields: [makeFieldProto(name: "next_page_token", number: 1, type: .string)]
  )
  let item = makeMessageProto(
    name: "Item",
    fields: [makeFieldProto(name: "id", number: 1, type: .string)]
  )
  let response = makeMessageProto(
    name: "GetGroupedAdsResponse",
    fields: [
      makeFieldProto(
        name: "items",
        number: 1,
        type: .message,
        label: .repeated,
        typeName: ".pkg.GetGroupedAdsResponse.Item"
      ),
      makeFieldProto(
        name: "cursor",
        number: 2,
        type: .message,
        typeName: ".pkg.GetGroupedAdsResponse.Cursor"
      ),
    ],
    nestedMessages: [cursor, item]
  )
  return makeFileProto(name: "ads.proto", package: "pkg", messages: [response])
}

/// Fixture: GetGroupedAdsRequest with nested SearchFilters type.
///
/// pkg.GetGroupedAdsRequest { SearchFilters search_filters = 1; int32 limit = 2;
/// message SearchFilters { string title = 1; } }
var adsRequestFileProto: Google_Protobuf_FileDescriptorProto {
  let filters = makeMessageProto(
    name: "SearchFilters",
    fields: [makeFieldProto(name: "title", number: 1, type: .string)]
  )
  let request = makeMessageProto(
    name: "GetGroupedAdsRequest",
    fields: [
      makeFieldProto(
        name: "search_filters",
        number: 1,
        type: .message,
        typeName: ".pkg.GetGroupedAdsRequest.SearchFilters"
      ),
      makeFieldProto(name: "limit", number: 2, type: .int32),
    ],
    nestedMessages: [filters]
  )
  return makeFileProto(name: "ads.proto", package: "pkg", messages: [request])
}

/// Fixture: three levels of nesting.
///
/// pkg.A { message B { message C { string value = 1; } } }
var deepNestingFileProto: Google_Protobuf_FileDescriptorProto {
  let c = makeMessageProto(
    name: "C",
    fields: [makeFieldProto(name: "value", number: 1, type: .string)]
  )
  let b = makeMessageProto(name: "B", nestedMessages: [c])
  let a = makeMessageProto(name: "A", nestedMessages: [b])
  return makeFileProto(name: "deep.proto", package: "pkg", messages: [a])
}

/// Fixture: parent message with a nested message and a nested enum.
///
/// pkg.Parent { message Child { string id = 1; } enum Status { UNKNOWN = 0; ACTIVE = 1; } }
var parentWithEnumFileProto: Google_Protobuf_FileDescriptorProto {
  let child = makeMessageProto(
    name: "Child",
    fields: [makeFieldProto(name: "id", number: 1, type: .string)]
  )
  let status = makeEnumProto(name: "Status", values: [("UNKNOWN", 0), ("ACTIVE", 1)])
  let parent = makeMessageProto(name: "Parent", nestedMessages: [child], nestedEnums: [status])
  return makeFileProto(name: "parent.proto", package: "pkg", messages: [parent])
}
