internal struct _OneofDescriptor: Equatable {
  let name: String
  let index: Int
  let options: [String: _DescriptorOption]

  init(name: String, index: Int, options: [String: _DescriptorOption] = [:]) {
    self.name = name
    self.index = index
    self.options = options
  }

  static func == (lhs: _OneofDescriptor, rhs: _OneofDescriptor) -> Bool {
    lhs.name == rhs.name && lhs.index == rhs.index
  }
}
