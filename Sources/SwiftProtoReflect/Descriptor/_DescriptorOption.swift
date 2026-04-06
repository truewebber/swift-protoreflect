import Foundation

internal enum _DescriptorOption: Equatable {
  case bool(Bool)
  case int(Int)
  case string(String)
  case float(Float)
  case double(Double)
  case bytes(Data)
}
