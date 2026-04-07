internal struct _MessageDescriptor {
  let name: String
  let fullName: String
  var syntax: String
  var fileDescriptorPath: String?
  var parentMessageFullName: String?
  private(set) var fields: [Int: _FieldDescriptor] = [:]
  private(set) var fieldsByName: [String: _FieldDescriptor] = [:]
  private(set) var nestedMessages: [String: _MessageDescriptor] = [:]
  private(set) var nestedEnums: [String: _EnumDescriptor] = [:]
  private(set) var oneofDecls: [_OneofDescriptor] = []
  private(set) var extensionRanges: [_ExtensionRange] = []
  private(set) var extensions: [Int: _FieldDescriptor] = [:]
  let options: [String: _DescriptorOption]

  init(
    name: String,
    fullName: String,
    syntax: String = "proto3",
    options: [String: _DescriptorOption] = [:]
  ) {
    self.name = name
    self.fullName = fullName
    self.syntax = syntax.isEmpty ? "proto2" : syntax
    self.options = options
  }

  init(
    name: String,
    parent: (any _DescriptorParent)? = nil,
    options: [String: _DescriptorOption] = [:]
  ) {
    self.name = name
    self.options = options

    if let parent {
      let prefix = parent.descriptorFullNamePrefix
      self.fullName = prefix.isEmpty ? name : "\(prefix).\(name)"
      self.parentMessageFullName = parent.descriptorParentMessageFullName
      self.fileDescriptorPath = parent.descriptorFilePath
      self.syntax = parent.descriptorSyntax
    }
    else {
      self.fullName = name
      self.syntax = "proto3"
    }
  }

  @discardableResult
  mutating func addField(_ field: _FieldDescriptor) -> Self {
    fields[field.number] = field
    fieldsByName[field.name] = field
    return self
  }

  @discardableResult
  mutating func addOneofDecl(_ oneof: _OneofDescriptor) -> Self {
    oneofDecls.append(oneof)
    return self
  }

  @discardableResult
  mutating func addNestedMessage(_ message: _MessageDescriptor) -> Self {
    var messageCopy = message
    messageCopy.parentMessageFullName = self.fullName
    messageCopy.fileDescriptorPath = self.fileDescriptorPath
    messageCopy.syntax = self.syntax
    nestedMessages[message.name] = messageCopy
    return self
  }

  @discardableResult
  mutating func addNestedEnum(_ enumDescriptor: _EnumDescriptor) -> Self {
    nestedEnums[enumDescriptor.name] = enumDescriptor
    return self
  }

  @discardableResult
  mutating func addExtensionRange(_ range: _ExtensionRange) -> Self {
    extensionRanges.append(range)
    return self
  }

  @discardableResult
  mutating func addExtension(_ field: _FieldDescriptor) -> Self {
    extensions[field.number] = field
    return self
  }

  func isExtensionNumber(_ number: Int) -> Bool {
    extensionRanges.contains { number >= $0.start && number < $0.end }
  }
}
