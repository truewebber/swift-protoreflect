// ProtoMethodDescriptor provides metadata for an RPC method, including its input and output message types.
class ProtoMethodDescriptor {
  // Name of the RPC method.
  let name: String

  // Descriptor for the request message type.
  let inputType: ProtoMessageDescriptor

  // Descriptor for the response message type.
  let outputType: ProtoMessageDescriptor

  // Constructor for ProtoMethodDescriptor.
  init(name: String, inputType: ProtoMessageDescriptor, outputType: ProtoMessageDescriptor) {
    self.name = name
    self.inputType = inputType
    self.outputType = outputType
  }

  // Verifies if the method descriptor is valid.
  func isValid() -> Bool {
    return !name.isEmpty && inputType.isValid() && outputType.isValid()
  }
}
