import Foundation

internal struct _FieldDescriptor: Equatable {
  let name: String
  let jsonName: String
  let number: Int
  let type: _FieldType
  let typeName: String?
  let isRepeated: Bool
  let isOptional: Bool
  let isRequired: Bool
  let isMap: Bool
  let oneofIndex: Int?
  let proto3Optional: Bool
  let mapEntryInfo: _MapEntryInfo?
  let defaultValue: _DescriptorOption?
  let isPacked: Bool?
  let options: [String: _DescriptorOption]

  init(
    name: String,
    number: Int,
    type: _FieldType,
    typeName: String? = nil,
    jsonName: String? = nil,
    isRepeated: Bool = false,
    isOptional: Bool = false,
    isRequired: Bool = false,
    isMap: Bool = false,
    oneofIndex: Int? = nil,
    proto3Optional: Bool = false,
    mapEntryInfo: _MapEntryInfo? = nil,
    defaultValue: _DescriptorOption? = nil,
    isPacked: Bool? = nil,
    options: [String: _DescriptorOption] = [:]
  ) {
    self.name = name
    self.number = number
    self.type = type
    self.typeName = typeName
    self.jsonName = jsonName ?? name
    self.isRepeated = isMap ? true : isRepeated
    self.isOptional = isOptional
    self.isRequired = isRequired
    self.isMap = isMap
    self.oneofIndex = oneofIndex
    self.proto3Optional = proto3Optional
    self.mapEntryInfo = mapEntryInfo
    self.defaultValue = defaultValue
    self.isPacked = isPacked
    self.options = options
  }

  static func == (lhs: _FieldDescriptor, rhs: _FieldDescriptor) -> Bool {
    lhs.name == rhs.name && lhs.jsonName == rhs.jsonName && lhs.number == rhs.number && lhs.type == rhs.type
      && lhs.typeName == rhs.typeName && lhs.isRepeated == rhs.isRepeated && lhs.isOptional == rhs.isOptional
      && lhs.isRequired == rhs.isRequired && lhs.isMap == rhs.isMap && lhs.oneofIndex == rhs.oneofIndex
      && lhs.proto3Optional == rhs.proto3Optional && lhs.mapEntryInfo == rhs.mapEntryInfo
      && lhs.defaultValue == rhs.defaultValue && lhs.isPacked == rhs.isPacked && lhs.options == rhs.options
  }
}

internal enum _FieldType: Equatable {
  case double
  case float
  case int32
  case int64
  case uint32
  case uint64
  case sint32
  case sint64
  case fixed32
  case fixed64
  case sfixed32
  case sfixed64
  case bool
  case string
  case bytes
  case message
  case `enum`
  case group
}

internal final class _MapEntryInfo: Equatable {
  let keyFieldInfo: _KeyFieldInfo
  let valueFieldInfo: _ValueFieldInfo

  init(keyFieldInfo: _KeyFieldInfo, valueFieldInfo: _ValueFieldInfo) {
    self.keyFieldInfo = keyFieldInfo
    self.valueFieldInfo = valueFieldInfo
  }

  static func == (lhs: _MapEntryInfo, rhs: _MapEntryInfo) -> Bool {
    lhs.keyFieldInfo == rhs.keyFieldInfo && lhs.valueFieldInfo == rhs.valueFieldInfo
  }
}

internal struct _KeyFieldInfo: Equatable {
  let name: String
  let number: Int
  let type: _FieldType
}

internal struct _ValueFieldInfo: Equatable {
  let name: String
  let number: Int
  let type: _FieldType
  let typeName: String?

  init(name: String, number: Int, type: _FieldType, typeName: String? = nil) {
    self.name = name
    self.number = number
    self.type = type
    self.typeName = typeName
  }
}
