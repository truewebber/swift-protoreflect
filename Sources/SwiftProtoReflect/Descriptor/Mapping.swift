// Mapping.swift
// Bidirectional converters between the Public/Descriptor types and internal _Xxx types.

import Foundation

// MARK: - DescriptorOption ↔ _DescriptorOption

extension _DescriptorOption {
  init(from pub: DescriptorOption) {
    switch pub {
    case .bool(let v): self = .bool(v)
    case .int(let v): self = .int(v)
    case .string(let v): self = .string(v)
    case .float(let v): self = .float(v)
    case .double(let v): self = .double(v)
    case .bytes(let v): self = .bytes(v)
    }
  }
}

extension DescriptorOption {
  init(from impl: _DescriptorOption) {
    switch impl {
    case .bool(let v): self = .bool(v)
    case .int(let v): self = .int(v)
    case .string(let v): self = .string(v)
    case .float(let v): self = .float(v)
    case .double(let v): self = .double(v)
    case .bytes(let v): self = .bytes(v)
    }
  }
}

// MARK: - FieldType ↔ _FieldType

extension _FieldType {
  init(from pub: FieldType) {
    switch pub {
    case .double: self = .double
    case .float: self = .float
    case .int32: self = .int32
    case .int64: self = .int64
    case .uint32: self = .uint32
    case .uint64: self = .uint64
    case .sint32: self = .sint32
    case .sint64: self = .sint64
    case .fixed32: self = .fixed32
    case .fixed64: self = .fixed64
    case .sfixed32: self = .sfixed32
    case .sfixed64: self = .sfixed64
    case .bool: self = .bool
    case .string: self = .string
    case .bytes: self = .bytes
    case .message: self = .message
    case .enum: self = .enum
    case .group: self = .group
    }
  }
}

extension FieldType {
  init(from impl: _FieldType) {
    switch impl {
    case .double: self = .double
    case .float: self = .float
    case .int32: self = .int32
    case .int64: self = .int64
    case .uint32: self = .uint32
    case .uint64: self = .uint64
    case .sint32: self = .sint32
    case .sint64: self = .sint64
    case .fixed32: self = .fixed32
    case .fixed64: self = .fixed64
    case .sfixed32: self = .sfixed32
    case .sfixed64: self = .sfixed64
    case .bool: self = .bool
    case .string: self = .string
    case .bytes: self = .bytes
    case .message: self = .message
    case .enum: self = .enum
    case .group: self = .group
    }
  }
}

// MARK: - KeyFieldInfo ↔ _KeyFieldInfo

extension _KeyFieldInfo {
  init(from pub: KeyFieldInfo) {
    self.init(name: pub.name, number: pub.number, type: _FieldType(from: pub.type))
  }
}

extension KeyFieldInfo {
  init(from impl: _KeyFieldInfo) {
    self.init(name: impl.name, number: impl.number, type: FieldType(from: impl.type))
  }
}

// MARK: - ValueFieldInfo ↔ _ValueFieldInfo

extension _ValueFieldInfo {
  init(from pub: ValueFieldInfo) {
    self.init(name: pub.name, number: pub.number, type: _FieldType(from: pub.type), typeName: pub.typeName)
  }
}

extension ValueFieldInfo {
  init(from impl: _ValueFieldInfo) {
    self.init(name: impl.name, number: impl.number, type: FieldType(from: impl.type), typeName: impl.typeName)
  }
}

// MARK: - MapEntryInfo ↔ _MapEntryInfo

extension _MapEntryInfo {
  convenience init(from pub: MapEntryInfo) {
    self.init(
      keyFieldInfo: _KeyFieldInfo(from: pub.keyFieldInfo),
      valueFieldInfo: _ValueFieldInfo(from: pub.valueFieldInfo)
    )
  }
}

extension MapEntryInfo {
  convenience init(from impl: _MapEntryInfo) {
    self.init(
      keyFieldInfo: KeyFieldInfo(from: impl.keyFieldInfo),
      valueFieldInfo: ValueFieldInfo(from: impl.valueFieldInfo)
    )
  }
}

// MARK: - FieldDescriptor ↔ _FieldDescriptor

extension _FieldDescriptor {
  init(from pub: FieldDescriptor) {
    self.init(
      name: pub.name,
      number: pub.number,
      type: _FieldType(from: pub.type),
      typeName: pub.typeName,
      jsonName: pub.jsonName,
      isRepeated: pub.isRepeated,
      isOptional: pub.isOptional,
      isRequired: pub.isRequired,
      isMap: pub.isMap,
      oneofIndex: pub.oneofIndex,
      proto3Optional: pub.proto3Optional,
      mapEntryInfo: pub.mapEntryInfo.map { _MapEntryInfo(from: $0) },
      defaultValue: pub.defaultValue.map { _DescriptorOption(from: $0) },
      isPacked: pub.isPacked,
      options: pub.options.mapValues { _DescriptorOption(from: $0) }
    )
  }
}

extension FieldDescriptor {
  init(from impl: _FieldDescriptor) {
    self.init(
      name: impl.name,
      number: impl.number,
      type: FieldType(from: impl.type),
      typeName: impl.typeName,
      jsonName: impl.jsonName,
      isRepeated: impl.isRepeated,
      isOptional: impl.isOptional,
      isRequired: impl.isRequired,
      isMap: impl.isMap,
      oneofIndex: impl.oneofIndex,
      proto3Optional: impl.proto3Optional,
      mapEntryInfo: impl.mapEntryInfo.map { MapEntryInfo(from: $0) },
      defaultValue: impl.defaultValue.map { DescriptorOption(from: $0) },
      isPacked: impl.isPacked,
      options: impl.options.mapValues { DescriptorOption(from: $0) }
    )
  }
}

// MARK: - OneofDescriptor ↔ _OneofDescriptor

extension _OneofDescriptor {
  init(from pub: OneofDescriptor) {
    self.init(
      name: pub.name,
      index: pub.index,
      options: pub.options.mapValues { _DescriptorOption(from: $0) }
    )
  }
}

extension OneofDescriptor {
  init(from impl: _OneofDescriptor) {
    self.init(
      name: impl.name,
      index: impl.index,
      options: impl.options.mapValues { DescriptorOption(from: $0) }
    )
  }
}

// MARK: - ExtensionRange ↔ _ExtensionRange

extension _ExtensionRange {
  init(from pub: ExtensionRange) {
    self.init(start: pub.start, end: pub.end)
  }
}

extension ExtensionRange {
  init(from impl: _ExtensionRange) {
    self.init(start: impl.start, end: impl.end)
  }
}

// MARK: - EnumDescriptor ↔ _EnumDescriptor

extension _EnumDescriptor {
  init(from pub: EnumDescriptor) {
    var impl = _EnumDescriptor(
      name: pub.name,
      fullName: pub.fullName,
      options: pub.options.mapValues { _DescriptorOption(from: $0) }
    )
    impl.fileDescriptorPath = pub.fileDescriptorPath
    impl.parentMessageFullName = pub.parentMessageFullName
    for value in pub.valuesByName.values {
      impl.addValue(
        _EnumDescriptor._EnumValue(
          name: value.name,
          number: value.number,
          options: value.options.mapValues { _DescriptorOption(from: $0) }
        )
      )
    }
    self = impl
  }
}

extension EnumDescriptor {
  init(from impl: _EnumDescriptor) {
    var pub = EnumDescriptor(
      name: impl.name,
      fullName: impl.fullName,
      options: impl.options.mapValues { DescriptorOption(from: $0) }
    )
    pub.fileDescriptorPath = impl.fileDescriptorPath
    pub.parentMessageFullName = impl.parentMessageFullName
    for value in impl.valuesByName.values {
      pub.addValue(
        EnumDescriptor.EnumValue(
          name: value.name,
          number: value.number,
          options: value.options.mapValues { DescriptorOption(from: $0) }
        )
      )
    }
    self = pub
  }
}

// MARK: - ServiceDescriptor ↔ _ServiceDescriptor

extension _ServiceDescriptor {
  init(from pub: ServiceDescriptor) {
    var impl = _ServiceDescriptor(
      name: pub.name,
      fullName: pub.fullName,
      options: pub.options.mapValues { _DescriptorOption(from: $0) }
    )
    impl.fileDescriptorPath = pub.fileDescriptorPath
    for method in pub.methodsByName.values {
      impl.addMethod(
        _ServiceDescriptor._MethodDescriptor(
          name: method.name,
          inputType: method.inputType,
          outputType: method.outputType,
          clientStreaming: method.clientStreaming,
          serverStreaming: method.serverStreaming,
          options: method.options.mapValues { _DescriptorOption(from: $0) }
        )
      )
    }
    self = impl
  }
}

extension ServiceDescriptor {
  init(from impl: _ServiceDescriptor) {
    var pub = ServiceDescriptor(
      name: impl.name,
      fullName: impl.fullName,
      options: impl.options.mapValues { DescriptorOption(from: $0) }
    )
    pub.fileDescriptorPath = impl.fileDescriptorPath
    for method in impl.methodsByName.values {
      pub.addMethod(
        ServiceDescriptor.MethodDescriptor(
          name: method.name,
          inputType: method.inputType,
          outputType: method.outputType,
          clientStreaming: method.clientStreaming,
          serverStreaming: method.serverStreaming,
          options: method.options.mapValues { DescriptorOption(from: $0) }
        )
      )
    }
    self = pub
  }
}

// MARK: - MessageDescriptor ↔ _MessageDescriptor

extension _MessageDescriptor {
  init(from pub: MessageDescriptor) {
    var impl = _MessageDescriptor(
      name: pub.name,
      fullName: pub.fullName,
      syntax: pub.syntax,
      options: pub.options.mapValues { _DescriptorOption(from: $0) }
    )
    impl.fileDescriptorPath = pub.fileDescriptorPath
    impl.parentMessageFullName = pub.parentMessageFullName
    for field in pub.fields.values {
      impl.addField(_FieldDescriptor(from: field))
    }
    for oneof in pub.oneofDecls {
      impl.addOneofDecl(_OneofDescriptor(from: oneof))
    }
    for nested in pub.nestedMessages.values {
      impl.addNestedMessage(_MessageDescriptor(from: nested))
    }
    for nested in pub.nestedEnums.values {
      impl.addNestedEnum(_EnumDescriptor(from: nested))
    }
    for range in pub.extensionRanges {
      impl.addExtensionRange(_ExtensionRange(from: range))
    }
    for ext in pub.extensions.values {
      impl.addExtension(_FieldDescriptor(from: ext))
    }
    self = impl
  }
}

extension MessageDescriptor {
  init(from impl: _MessageDescriptor) {
    var pub = MessageDescriptor(
      name: impl.name,
      fullName: impl.fullName,
      syntax: impl.syntax,
      options: impl.options.mapValues { DescriptorOption(from: $0) }
    )
    pub.fileDescriptorPath = impl.fileDescriptorPath
    pub.parentMessageFullName = impl.parentMessageFullName
    for field in impl.fields.values {
      pub.addField(FieldDescriptor(from: field))
    }
    for oneof in impl.oneofDecls {
      pub.addOneofDecl(OneofDescriptor(from: oneof))
    }
    for nested in impl.nestedMessages.values {
      pub.addNestedMessage(MessageDescriptor(from: nested))
    }
    for nested in impl.nestedEnums.values {
      pub.addNestedEnum(EnumDescriptor(from: nested))
    }
    for range in impl.extensionRanges {
      pub.addExtensionRange(ExtensionRange(from: range))
    }
    for ext in impl.extensions.values {
      pub.addExtension(FieldDescriptor(from: ext))
    }
    self = pub
  }
}

// MARK: - FileDescriptor ↔ _FileDescriptor

extension _FileDescriptor {
  init(from pub: FileDescriptor) {
    var impl = _FileDescriptor(
      name: pub.name,
      package: pub.package,
      dependencies: pub.dependencies,
      syntax: pub.syntax,
      options: pub.options.mapValues { _DescriptorOption(from: $0) }
    )
    for msg in pub.messages.values {
      impl.addMessage(_MessageDescriptor(from: msg))
    }
    for enm in pub.enums.values {
      impl.addEnum(_EnumDescriptor(from: enm))
    }
    for svc in pub.services.values {
      impl.addService(_ServiceDescriptor(from: svc))
    }
    self = impl
  }
}

extension FileDescriptor {
  init(from impl: _FileDescriptor) {
    var pub = FileDescriptor(
      name: impl.name,
      package: impl.package,
      dependencies: impl.dependencies,
      syntax: impl.syntax,
      options: impl.options.mapValues { DescriptorOption(from: $0) }
    )
    for msg in impl.messages.values {
      pub.addMessage(MessageDescriptor(from: msg))
    }
    for enm in impl.enums.values {
      pub.addEnum(EnumDescriptor(from: enm))
    }
    for svc in impl.services.values {
      pub.addService(ServiceDescriptor(from: svc))
    }
    self = pub
  }
}
