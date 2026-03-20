/// A single typed option value for any descriptor options dictionary.
///
/// Replaces `Any` in `[String: Any]` options, enabling `Sendable` conformance
/// across all descriptor types without unsafe workarounds.
public enum DescriptorOption: Equatable, Sendable {
  case bool(Bool)
  case int(Int)
  case string(String)
  case float(Float)
}
