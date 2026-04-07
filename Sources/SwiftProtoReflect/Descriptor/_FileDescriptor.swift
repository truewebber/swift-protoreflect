internal struct _FileDescriptor {
  let name: String
  let package: String
  let dependencies: [String]
  let syntax: String
  let options: [String: _DescriptorOption]
  private(set) var messages: [String: _MessageDescriptor] = [:]
  private(set) var enums: [String: _EnumDescriptor] = [:]
  private(set) var services: [String: _ServiceDescriptor] = [:]

  init(
    name: String,
    package: String,
    dependencies: [String] = [],
    syntax: String = "proto3",
    options: [String: _DescriptorOption] = [:]
  ) {
    self.name = name
    self.package = package
    self.dependencies = dependencies
    self.syntax = syntax.isEmpty ? "proto2" : syntax
    self.options = options
  }

  @discardableResult
  mutating func addMessage(_ messageDescriptor: _MessageDescriptor) -> Self {
    var newMessage = messageDescriptor

    if newMessage.fileDescriptorPath == nil && newMessage.parentMessageFullName == nil {
      newMessage.fileDescriptorPath = self.name
    }

    newMessage.syntax = self.syntax

    messages[messageDescriptor.name] = newMessage
    return self
  }

  @discardableResult
  mutating func addEnum(_ enumDescriptor: _EnumDescriptor) -> Self {
    enums[enumDescriptor.name] = enumDescriptor
    return self
  }

  @discardableResult
  mutating func addService(_ serviceDescriptor: _ServiceDescriptor) -> Self {
    services[serviceDescriptor.name] = serviceDescriptor
    return self
  }

  func getFullName(for typeName: String) -> String {
    package.isEmpty ? typeName : "\(package).\(typeName)"
  }
}
