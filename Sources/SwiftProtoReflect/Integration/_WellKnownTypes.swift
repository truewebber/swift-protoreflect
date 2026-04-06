//
// _WellKnownTypes.swift
// SwiftProtoReflect
//
// Internal WKT foundation types — scaffolding for future actor migration (OPE-300).
// Public counterparts live in Public/WellKnownTypes.swift.
//

import Foundation

// MARK: - _WellKnownTypeNames

// TODO(OPE-300): Replace these proxies with a standalone internal implementation once
// the internal WKT layer no longer needs the public WellKnownTypeNames at all.
internal struct _WellKnownTypeNames {
  internal static let timestamp = WellKnownTypeNames.timestamp
  internal static let duration = WellKnownTypeNames.duration
  internal static let empty = WellKnownTypeNames.empty
  internal static let fieldMask = WellKnownTypeNames.fieldMask
  internal static let structType = WellKnownTypeNames.structType
  internal static let value = WellKnownTypeNames.value
  internal static let any = WellKnownTypeNames.any
  internal static let listValue = WellKnownTypeNames.listValue
  internal static let nullValue = WellKnownTypeNames.nullValue
}

// MARK: - _WellKnownSupportPhase

// TODO(OPE-300): This mirrors WellKnownSupportPhase. Once _WellKnownTypeHandler protocol
// uses _WellKnownSupportPhase end-to-end, remove the Mapping.swift converter and the
// duplicate WellKnownSupportPhase reference from this file.
internal enum _WellKnownSupportPhase: Int, CaseIterable, Sendable {
  case critical = 1
  case important = 2
  case advanced = 3
}

// MARK: - _WellKnownTypesRegistry

// TODO(OPE-300): Migrate to actor with full internal handler registration.
internal final class _WellKnownTypesRegistry: @unchecked Sendable {
  internal static let shared = _WellKnownTypesRegistry()
  private init() {}
}
