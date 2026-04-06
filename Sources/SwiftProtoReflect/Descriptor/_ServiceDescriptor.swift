internal struct _ServiceDescriptor: Equatable {
  struct _MethodDescriptor: Equatable {
    let name: String
    let inputType: String
    let outputType: String
    let clientStreaming: Bool
    let serverStreaming: Bool
    let options: [String: _DescriptorOption]

    init(
      name: String,
      inputType: String,
      outputType: String,
      clientStreaming: Bool = false,
      serverStreaming: Bool = false,
      options: [String: _DescriptorOption] = [:]
    ) {
      self.name = name
      self.inputType = inputType
      self.outputType = outputType
      self.clientStreaming = clientStreaming
      self.serverStreaming = serverStreaming
      self.options = options
    }

    static func == (lhs: _MethodDescriptor, rhs: _MethodDescriptor) -> Bool {
      lhs.name == rhs.name && lhs.inputType == rhs.inputType && lhs.outputType == rhs.outputType
        && lhs.clientStreaming == rhs.clientStreaming && lhs.serverStreaming == rhs.serverStreaming
        && lhs.options == rhs.options
    }
  }

  let name: String
  let fullName: String
  var fileDescriptorPath: String?
  private(set) var methodsByName: [String: _MethodDescriptor] = [:]
  let options: [String: _DescriptorOption]

  init(
    name: String,
    fullName: String,
    options: [String: _DescriptorOption] = [:]
  ) {
    self.name = name
    self.fullName = fullName
    self.options = options
  }

  @discardableResult
  mutating func addMethod(_ method: _MethodDescriptor) -> Self {
    methodsByName[method.name] = method
    return self
  }

  static func == (lhs: _ServiceDescriptor, rhs: _ServiceDescriptor) -> Bool {
    guard
      lhs.name == rhs.name && lhs.fullName == rhs.fullName && lhs.fileDescriptorPath == rhs.fileDescriptorPath
        && lhs.options == rhs.options
    else {
      return false
    }

    guard lhs.methodsByName.count == rhs.methodsByName.count else {
      return false
    }

    for (name, lhsMethod) in lhs.methodsByName {
      guard let rhsMethod = rhs.methodsByName[name], lhsMethod == rhsMethod else {
        return false
      }
    }

    return true
  }
}
