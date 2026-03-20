import Foundation

/// A single typed option value for any descriptor options dictionary.
///
/// Replaces `Any` in `[String: Any]` options, enabling `Sendable` conformance
/// across all descriptor types without unsafe workarounds.
public enum DescriptorOption: Equatable, Sendable {
  case bool(Bool)
  case int(Int)
  case string(String)
  case float(Float)
  case bytes(Data)

  /// Returns the underlying value as `Any`, for interoperability with APIs that require `Any`.
  public var asAny: Any {
    switch self {
    case .bool(let v): return v
    case .int(let v): return v
    case .string(let v): return v
    case .float(let v): return v
    case .bytes(let v): return v
    }
  }
}
