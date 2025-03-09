// ProtoEnumValueDescriptor represents a single value within an enum type, providing its name and corresponding numeric value.
public class ProtoEnumValueDescriptor: Equatable {
  // Name of the enum value.
  public let name: String

  // Numeric value associated with the enum value.
  public let number: Int

  // Constructor for ProtoEnumValueDescriptor.
  public init(name: String, number: Int) {
    self.name = name
    self.number = number
  }

  // Verifies if the enum value descriptor is valid.
  public func isValid() -> Bool {
    return !name.isEmpty
  }

  // Conformance to Equatable.
  public static func == (lhs: ProtoEnumValueDescriptor, rhs: ProtoEnumValueDescriptor) -> Bool {
    return lhs.name == rhs.name && lhs.number == rhs.number
  }
}
