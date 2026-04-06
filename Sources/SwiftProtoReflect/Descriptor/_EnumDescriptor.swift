internal struct _EnumDescriptor: Equatable {
  struct _EnumValue: Equatable {
    let name: String
    let number: Int
    let options: [String: _DescriptorOption]

    init(name: String, number: Int, options: [String: _DescriptorOption] = [:]) {
      self.name = name
      self.number = number
      self.options = options
    }

    static func == (lhs: _EnumValue, rhs: _EnumValue) -> Bool {
      lhs.name == rhs.name && lhs.number == rhs.number && lhs.options == rhs.options
    }
  }

  let name: String
  let fullName: String
  var fileDescriptorPath: String?
  var parentMessageFullName: String?
  private(set) var valuesByName: [String: _EnumValue] = [:]
  private(set) var valuesByNumber: [Int: _EnumValue] = [:]
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
    }
    else {
      self.fullName = name
    }
  }

  @discardableResult
  mutating func addValue(_ value: _EnumValue) -> Self {
    valuesByName[value.name] = value
    valuesByNumber[value.number] = value
    return self
  }

  static func == (lhs: _EnumDescriptor, rhs: _EnumDescriptor) -> Bool {
    guard
      lhs.name == rhs.name && lhs.fullName == rhs.fullName && lhs.fileDescriptorPath == rhs.fileDescriptorPath
        && lhs.parentMessageFullName == rhs.parentMessageFullName && lhs.options == rhs.options
    else {
      return false
    }

    guard lhs.valuesByName.count == rhs.valuesByName.count else {
      return false
    }

    for (name, lhsValue) in lhs.valuesByName {
      guard let rhsValue = rhs.valuesByName[name], lhsValue == rhsValue else {
        return false
      }
    }

    return true
  }
}
