// ProtoServiceDescriptor describes a gRPC service, including its methods and request/response types.
class ProtoServiceDescriptor {
	// Name of the service.
	let name: String

	// List of RPC method descriptors in the service.
	let methods: [ProtoMethodDescriptor]

	// Constructor for ProtoServiceDescriptor.
	init(name: String, methods: [ProtoMethodDescriptor]) {
		self.name = name
		self.methods = methods
	}

	// Retrieves an RPC method descriptor by name.
	func method(named name: String) -> ProtoMethodDescriptor? {
		return methods.first { $0.name == name }
	}

	// Verifies if the service descriptor is valid.
	func isValid() -> Bool {
		return !name.isEmpty && !methods.isEmpty
	}
}
