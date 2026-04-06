internal protocol _DescriptorParent {
  var descriptorFullNamePrefix: String { get }
  var descriptorFilePath: String? { get }
  var descriptorSyntax: String { get }
  var descriptorParentMessageFullName: String? { get }
}

extension _FileDescriptor: _DescriptorParent {
  var descriptorFullNamePrefix: String { package }
  var descriptorFilePath: String? { name }
  var descriptorSyntax: String { syntax }
  var descriptorParentMessageFullName: String? { nil }
}

extension _MessageDescriptor: _DescriptorParent {
  var descriptorFullNamePrefix: String { fullName }
  var descriptorFilePath: String? { fileDescriptorPath }
  var descriptorSyntax: String { syntax }
  var descriptorParentMessageFullName: String? { fullName }
}
