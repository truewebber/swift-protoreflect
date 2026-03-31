# Implementation Plan: Fix Nested Type `fullName` (Option C — `DescriptorParent` Protocol)

## Summary

Introduce a `DescriptorParent` protocol implemented by `FileDescriptor` and `MessageDescriptor`.
Replace `Any?`-based parent parameters with typed `(any DescriptorParent)?` throughout.
Keep full backward compatibility via `@available(*, deprecated)` wrappers.
Follow strict TDD: every step starts with a failing test.

Related documents:
- Bug report: `ISSUE.md`
- Full test plan: `TEST_PLAN.md`

---

## Affected Files

### New files
```
Sources/SwiftProtoReflect/Descriptor/DescriptorParent.swift
Tests/SwiftProtoReflectTests/Descriptor/DescriptorParentProtocolTests.swift
Tests/SwiftProtoReflectTests/Bridge/DescriptorBridgeNestedMessageTests.swift
Tests/SwiftProtoReflectTests/Bridge/DescriptorBridgeNestedEnumTests.swift
Tests/SwiftProtoReflectTests/Bridge/DescriptorBridgeRegressionTests.swift
Tests/SwiftProtoReflectTests/Bridge/DescriptorBridgeDeprecatedAPITests.swift
Tests/SwiftProtoReflectTests/Registry/DescriptorPoolNestedTypesTests.swift
Tests/SwiftProtoReflectTests/Registry/TypeRegistryNestedTypesTests.swift
Tests/SwiftProtoReflectTests/Serialization/JSONDeserializerNestedTypesTests.swift
Tests/SwiftProtoReflectTests/Integration/NestedTypesIntegrationTests.swift
Tests/SwiftProtoReflectTests/Fixtures/NestedTypeFixtures.swift
```

### Modified files
```
Sources/SwiftProtoReflect/Descriptor/MessageDescriptor.swift
Sources/SwiftProtoReflect/Descriptor/EnumDescriptor.swift
Sources/SwiftProtoReflect/Bridge/DescriptorBridge.swift
MIGRATION_GUIDE.md
```

---

## Step 0 — Shared Test Fixtures

**File:** `Tests/SwiftProtoReflectTests/Fixtures/NestedTypeFixtures.swift`

Create helpers used by all test files. No production code changes yet.

```swift
import SwiftProtobuf
@testable import SwiftProtoReflect

// MARK: - Protobuf descriptor factory helpers

func makeFieldProto(
    name: String,
    number: Int32,
    type: Google_Protobuf_FieldDescriptorProto.TypeEnum,
    label: Google_Protobuf_FieldDescriptorProto.Label = .optional,
    typeName: String? = nil
) -> Google_Protobuf_FieldDescriptorProto {
    var f = Google_Protobuf_FieldDescriptorProto()
    f.name   = name
    f.number = number
    f.type   = type
    f.label  = label
    if let typeName { f.typeName = typeName }
    return f
}

func makeEnumProto(
    name: String,
    values: [(name: String, number: Int32)]
) -> Google_Protobuf_EnumDescriptorProto {
    var e = Google_Protobuf_EnumDescriptorProto()
    e.name  = name
    e.value = values.map { v in
        var ev = Google_Protobuf_EnumValueDescriptorProto()
        ev.name   = v.name
        ev.number = v.number
        return ev
    }
    return e
}

func makeMessageProto(
    name: String,
    fields: [Google_Protobuf_FieldDescriptorProto] = [],
    nestedMessages: [Google_Protobuf_DescriptorProto] = [],
    nestedEnums: [Google_Protobuf_EnumDescriptorProto] = []
) -> Google_Protobuf_DescriptorProto {
    var m = Google_Protobuf_DescriptorProto()
    m.name       = name
    m.field      = fields
    m.nestedType = nestedMessages
    m.enumType   = nestedEnums
    return m
}

func makeFileProto(
    name: String,
    package: String,
    syntax: String = "proto3",
    messages: [Google_Protobuf_DescriptorProto] = [],
    enums: [Google_Protobuf_EnumDescriptorProto] = []
) -> Google_Protobuf_FileDescriptorProto {
    var f = Google_Protobuf_FileDescriptorProto()
    f.name        = name
    f.package     = package
    f.syntax      = syntax
    f.messageType = messages
    f.enumType    = enums
    return f
}

// MARK: - Pre-built scenario fixtures

/// pkg.GetGroupedAdsResponse { repeated Item items = 1; Cursor cursor = 2;
///                              message Cursor { string next_page_token = 1; }
///                              message Item   { string id = 1; }             }
var adsResponseFileProto: Google_Protobuf_FileDescriptorProto {
    let cursor = makeMessageProto(
        name: "Cursor",
        fields: [makeFieldProto(name: "next_page_token", number: 1, type: .string)]
    )
    let item = makeMessageProto(
        name: "Item",
        fields: [makeFieldProto(name: "id", number: 1, type: .string)]
    )
    let response = makeMessageProto(
        name: "GetGroupedAdsResponse",
        fields: [
            makeFieldProto(name: "items",  number: 1, type: .message, label: .repeated,
                           typeName: ".pkg.GetGroupedAdsResponse.Item"),
            makeFieldProto(name: "cursor", number: 2, type: .message,
                           typeName: ".pkg.GetGroupedAdsResponse.Cursor"),
        ],
        nestedMessages: [cursor, item]
    )
    return makeFileProto(name: "ads.proto", package: "pkg", messages: [response])
}

/// pkg.GetGroupedAdsRequest { SearchFilters search_filters = 1; int32 limit = 2;
///                             message SearchFilters { string title = 1; }       }
var adsRequestFileProto: Google_Protobuf_FileDescriptorProto {
    let filters = makeMessageProto(
        name: "SearchFilters",
        fields: [makeFieldProto(name: "title", number: 1, type: .string)]
    )
    let request = makeMessageProto(
        name: "GetGroupedAdsRequest",
        fields: [
            makeFieldProto(name: "search_filters", number: 1, type: .message,
                           typeName: ".pkg.GetGroupedAdsRequest.SearchFilters"),
            makeFieldProto(name: "limit", number: 2, type: .int32),
        ],
        nestedMessages: [filters]
    )
    return makeFileProto(name: "ads.proto", package: "pkg", messages: [request])
}

/// pkg.A { message B { message C { string value = 1; } } }
var deepNestingFileProto: Google_Protobuf_FileDescriptorProto {
    let c = makeMessageProto(name: "C",
                             fields: [makeFieldProto(name: "value", number: 1, type: .string)])
    let b = makeMessageProto(name: "B", nestedMessages: [c])
    let a = makeMessageProto(name: "A", nestedMessages: [b])
    return makeFileProto(name: "deep.proto", package: "pkg", messages: [a])
}

/// pkg.Parent { message Child { string id = 1; }
///              enum Status { UNKNOWN = 0; ACTIVE = 1; } }
var parentWithEnumFileProto: Google_Protobuf_FileDescriptorProto {
    let child  = makeMessageProto(name: "Child",
                                  fields: [makeFieldProto(name: "id", number: 1, type: .string)])
    let status = makeEnumProto(name: "Status", values: [("UNKNOWN", 0), ("ACTIVE", 1)])
    let parent = makeMessageProto(name: "Parent", nestedMessages: [child], nestedEnums: [status])
    return makeFileProto(name: "parent.proto", package: "pkg", messages: [parent])
}
```

---

## Step 1 — `DescriptorParent` Protocol

**TDD rule:** write the test file first, confirm it fails to compile (red), then add the protocol (green).

### 1a — Write failing tests

**File:** `Tests/SwiftProtoReflectTests/Descriptor/DescriptorParentProtocolTests.swift`

See `TEST_PLAN.md`, Part 4 (18 tests).

The tests will fail to compile because `DescriptorParent` does not yet exist.

### 1b — Create the protocol

**New file:** `Sources/SwiftProtoReflect/Descriptor/DescriptorParent.swift`

```swift
//
// DescriptorParent.swift
// SwiftProtoReflect
//
// Created: 2025-XX-XX
//

/// A type that can serve as a parent context for a Protocol Buffers descriptor node.
///
/// Conforming types: `FileDescriptor`, `MessageDescriptor`.
/// Services always live at file level and therefore do not participate.
///
/// Implementing this protocol lets `MessageDescriptor` and `EnumDescriptor`
/// compute their `fullName`, `syntax`, and `fileDescriptorPath` from the parent
/// without relying on runtime `as?` casts against `Any`.
public protocol DescriptorParent: Sendable {

    /// Prefix used to build the child descriptor's `fullName`.
    ///
    /// - For `FileDescriptor`: equals `package` (may be empty).
    /// - For `MessageDescriptor`: equals `fullName`.
    var descriptorFullNamePrefix: String { get }

    /// Path of the file that owns this descriptor node.
    ///
    /// Propagated to child `fileDescriptorPath`.
    var descriptorFilePath: String? { get }

    /// Proto syntax version (`"proto3"` or `"proto2"`) of the owning file.
    ///
    /// Inherited by child descriptors.
    var descriptorSyntax: String { get }

    /// If this parent is a message descriptor, returns its `fullName`; otherwise `nil`.
    ///
    /// Used to populate `parentMessageFullName` on child `MessageDescriptor` and
    /// `EnumDescriptor` instances.
    var descriptorParentMessageFullName: String? { get }
}
```

### 1c — Add conformances to `FileDescriptor` and `MessageDescriptor`

**Append to** `Sources/SwiftProtoReflect/Descriptor/FileDescriptor.swift`:

```swift
// MARK: - DescriptorParent

extension FileDescriptor: DescriptorParent {

    /// Package string used as the fully-qualified name prefix for child types.
    public var descriptorFullNamePrefix: String { package }

    /// The file's own path — propagated to child descriptors.
    public var descriptorFilePath: String? { name }

    /// Syntax version of this file.
    public var descriptorSyntax: String { syntax }

    /// Files are not messages; always `nil`.
    public var descriptorParentMessageFullName: String? { nil }
}
```

**Append to** `Sources/SwiftProtoReflect/Descriptor/MessageDescriptor.swift`:

```swift
// MARK: - DescriptorParent

extension MessageDescriptor: DescriptorParent {

    /// The message's fully-qualified name — used as prefix for nested child names.
    public var descriptorFullNamePrefix: String { fullName }

    /// File path this message belongs to.
    public var descriptorFilePath: String? { fileDescriptorPath }

    /// Syntax version inherited from the owning file.
    public var descriptorSyntax: String { syntax }

    /// This is a message; returns its own `fullName` so children can populate
    /// their `parentMessageFullName`.
    public var descriptorParentMessageFullName: String? { fullName }
}
```

### 1d — Run `make lint && swift build && make test`

All 18 protocol tests should now pass. No other tests should be affected.

---

## Step 2 — Update `MessageDescriptor.init(name:parent:)`

**TDD rule:** write bridge/nested tests first (they will fail), then change `MessageDescriptor`.

### 2a — Write failing bridge tests

**Files:**
- `Tests/SwiftProtoReflectTests/Bridge/DescriptorBridgeNestedMessageTests.swift`
- `Tests/SwiftProtoReflectTests/Bridge/DescriptorBridgeNestedEnumTests.swift`
- `Tests/SwiftProtoReflectTests/Bridge/DescriptorBridgeRegressionTests.swift`

See `TEST_PLAN.md`, Parts 1–3. Tests in groups 1.1, 1.2, 2.1, 2.2 will fail (wrong fullName).

### 2b — Update `MessageDescriptor.init(name:parent:)`

**File:** `Sources/SwiftProtoReflect/Descriptor/MessageDescriptor.swift`

Replace the existing `init(name:parent:options:)` with the typed version.
Add a deprecated backward-compatible overload **without `= nil`** to avoid ambiguity.

```swift
// ─── NEW: typed, preferred ────────────────────────────────────────────────────

/// Creates a new `MessageDescriptor` with its `fullName` derived from the parent.
///
/// - Parameters:
///   - name: Simple message name (e.g., `"Person"`).
///   - parent: Parent descriptor context. Pass a `FileDescriptor` for top-level
///     messages or a `MessageDescriptor` for nested messages. Pass `nil` to use
///     `name` as both the simple name and `fullName`.
///   - options: Message options.
public init(
    name: String,
    parent: (any DescriptorParent)? = nil,
    options: [String: DescriptorOption] = [:]
) {
    self.name    = name
    self.options = options

    if let parent {
        let prefix = parent.descriptorFullNamePrefix
        self.fullName              = prefix.isEmpty ? name : "\(prefix).\(name)"
        self.parentMessageFullName = parent.descriptorParentMessageFullName
        self.fileDescriptorPath    = parent.descriptorFilePath
        self.syntax                = parent.descriptorSyntax
    } else {
        self.fullName = name
        self.syntax   = "proto3"
    }
}

// ─── DEPRECATED: backward-compatible wrapper ──────────────────────────────────

/// Creates a new `MessageDescriptor` with its `fullName` derived from the parent.
///
/// - Deprecated: Pass a `FileDescriptor` or `MessageDescriptor` directly.
///   Both types conform to `DescriptorParent`.
@available(*, deprecated,
    message: "Pass a FileDescriptor or MessageDescriptor, both conform to DescriptorParent.")
public init(
    name: String,
    parent: Any?,                               // no default — avoids nil-ambiguity
    options: [String: DescriptorOption] = [:]
) {
    self.init(name: name,
              parent: parent as? (any DescriptorParent),
              options: options)
}
```

**Key design note:** The deprecated overload intentionally has **no `= nil`** default value.
This ensures calls like `MessageDescriptor(name: "X")` or `MessageDescriptor(name: "X", parent: nil)`
resolve unambiguously to the new typed overload, while code that passes a variable of type `Any?`
still compiles (with a deprecation warning) via the `Any?` overload.

### 2c — Run lint, build, test

Only the new protocol tests (Step 1) should pass. The bridge nested tests should still fail
because `DescriptorBridge` still passes `parent: nil`.

---

## Step 3 — Update `EnumDescriptor.init(name:parent:)`

### 3a — Add `EnumDescriptor` conformance

Append to `Sources/SwiftProtoReflect/Descriptor/EnumDescriptor.swift`:

```swift
// MARK: - DescriptorParent (EnumDescriptor cannot itself be a parent — no conformance needed)
// EnumDescriptor only USES DescriptorParent; it does not conform to it.
```

### 3b — Update `EnumDescriptor.init(name:parent:)`

Same pattern as `MessageDescriptor`. Replace the existing `init(name:parent:)`.

```swift
// ─── NEW: typed, preferred ────────────────────────────────────────────────────

/// Creates a new `EnumDescriptor` with its `fullName` derived from the parent.
///
/// - Parameters:
///   - name: Simple enum name.
///   - parent: Parent context (`FileDescriptor` or `MessageDescriptor`).
///   - options: Enum options.
public init(
    name: String,
    parent: (any DescriptorParent)? = nil,
    options: [String: DescriptorOption] = [:]
) {
    self.name    = name
    self.options = options

    if let parent {
        let prefix = parent.descriptorFullNamePrefix
        self.fullName              = prefix.isEmpty ? name : "\(prefix).\(name)"
        self.parentMessageFullName = parent.descriptorParentMessageFullName
        self.fileDescriptorPath    = parent.descriptorFilePath
    } else {
        self.fullName = name
    }
}

// ─── DEPRECATED: backward-compatible wrapper ──────────────────────────────────

@available(*, deprecated,
    message: "Pass a FileDescriptor or MessageDescriptor, both conform to DescriptorParent.")
public init(
    name: String,
    parent: Any?,                               // no default — avoids nil-ambiguity
    options: [String: DescriptorOption] = [:]
) {
    self.init(name: name,
              parent: parent as? (any DescriptorParent),
              options: options)
}
```

---

## Step 4 — Fix `DescriptorBridge.fromProtobufDescriptor` (the actual bug)

This is the core of the fix.

### 4a — Confirm tests are red

The nested message/enum bridge tests from Step 2a still fail. This step makes them green.

### 4b — Update `DescriptorBridge.swift`

**Change 1:** New primary overload of `fromProtobufDescriptor`:

```swift
// ─── NEW: typed, preferred — accepts any DescriptorParent ────────────────────

/// Creates `MessageDescriptor` from `Google_Protobuf_DescriptorProto`.
///
/// - Parameters:
///   - protobufDescriptor: Message descriptor in Swift Protobuf format.
///   - parent: Parent context. Pass a `FileDescriptor` for top-level messages,
///     or a `MessageDescriptor` for nested messages.
/// - Returns: SwiftProtoReflect message descriptor with correctly qualified `fullName`.
/// - Throws: `DescriptorBridgeError` on conversion failure.
public func fromProtobufDescriptor(
    _ protobufDescriptor: Google_Protobuf_DescriptorProto,
    parent: (any DescriptorParent)? = nil
) throws -> MessageDescriptor {
    var messageDescriptor = MessageDescriptor(
        name: protobufDescriptor.name,
        parent: parent
    )

    // Recurse with messageDescriptor as parent so nested fullNames are qualified.
    for nestedProto in protobufDescriptor.nestedType {
        let nestedMessage = try fromProtobufDescriptor(nestedProto, parent: messageDescriptor)
        messageDescriptor.addNestedMessage(nestedMessage)
    }

    // Pass messageDescriptor as parent to nested enums for the same reason.
    for enumProto in protobufDescriptor.enumType {
        let nestedEnum = try fromProtobufEnumDescriptor(enumProto, parent: messageDescriptor)
        messageDescriptor.addNestedEnum(nestedEnum)
    }

    // Convert fields (now with nested messages available for map detection)
    let syntax = messageDescriptor.syntax
    for fieldProto in protobufDescriptor.field {
        let field = try fromProtobufFieldDescriptor(
            fieldProto,
            messageDescriptor: protobufDescriptor,
            nestedMessages: messageDescriptor.nestedMessages,
            syntax: syntax
        )
        messageDescriptor.addField(field)
    }

    for (index, oneofProto) in protobufDescriptor.oneofDecl.enumerated() {
        messageDescriptor.addOneofDecl(OneofDescriptor(name: oneofProto.name, index: index))
    }

    for rangeProto in protobufDescriptor.extensionRange {
        messageDescriptor.addExtensionRange(
            ExtensionRange(start: Int(rangeProto.start), end: Int(rangeProto.end))
        )
    }

    if protobufDescriptor.hasOptions {
        _ = try fromProtobufMessageOptions(protobufDescriptor.options)
    }

    return messageDescriptor
}

// ─── DEPRECATED: backward-compatible wrapper — keeps FileDescriptor? signature ─

/// Creates `MessageDescriptor` from `Google_Protobuf_DescriptorProto`.
///
/// - Deprecated: Use `fromProtobufDescriptor(_:parent:)` with `DescriptorParent`.
@available(*, deprecated,
    message: "Use fromProtobufDescriptor(_:parent:) where parent conforms to DescriptorParent.")
public func fromProtobufDescriptor(
    _ protobufDescriptor: Google_Protobuf_DescriptorProto,
    parent: FileDescriptor? = nil
) throws -> MessageDescriptor {
    // FileDescriptor conforms to DescriptorParent; cast is always non-nil when parent != nil.
    return try fromProtobufDescriptor(protobufDescriptor,
                                      parent: parent as (any DescriptorParent)?)
}
```

**Change 2:** Update `fromProtobufEnumDescriptor` — change `Any?` → `(any DescriptorParent)?`:

```swift
// ─── NEW: typed, preferred ────────────────────────────────────────────────────

/// Creates `EnumDescriptor` from `Google_Protobuf_EnumDescriptorProto`.
///
/// - Parameters:
///   - protobufDescriptor: Enum descriptor in Swift Protobuf format.
///   - parent: Parent context (`FileDescriptor` or `MessageDescriptor`).
public func fromProtobufEnumDescriptor(
    _ protobufDescriptor: Google_Protobuf_EnumDescriptorProto,
    parent: (any DescriptorParent)? = nil
) throws -> EnumDescriptor {
    var enumDescriptor = EnumDescriptor(
        name: protobufDescriptor.name,
        parent: parent
    )
    for valueProto in protobufDescriptor.value {
        enumDescriptor.addValue(
            EnumDescriptor.EnumValue(name: valueProto.name, number: Int(valueProto.number))
        )
    }
    return enumDescriptor
}

// ─── DEPRECATED: backward-compatible wrapper ──────────────────────────────────

@available(*, deprecated,
    message: "Use fromProtobufEnumDescriptor(_:parent:) where parent conforms to DescriptorParent.")
public func fromProtobufEnumDescriptor(
    _ protobufDescriptor: Google_Protobuf_EnumDescriptorProto,
    parent: Any?
) throws -> EnumDescriptor {
    return try fromProtobufEnumDescriptor(protobufDescriptor,
                                          parent: parent as? (any DescriptorParent))
}
```

**`fromProtobufFileDescriptor` requires a minor update in Step 4b.**
It already calls `fromProtobufDescriptor(messageProto, parent: fileDescriptor)`.
However, because Swift's overload resolution prefers the more specific `FileDescriptor?`
overload over the wider `(any DescriptorParent)?` overload, this call will route to the
**deprecated** wrapper and generate a deprecation warning.
Step 4b.2 will catch this and update the call to avoid the warning:

```swift
// Before — silently routes to deprecated FileDescriptor? wrapper
let message = try fromProtobufDescriptor(messageProto, parent: fileDescriptor)

// After — explicitly uses typed overload
let message = try fromProtobufDescriptor(messageProto, parent: fileDescriptor as (any DescriptorParent)?)
```

**No change needed** for `fromProtobufServiceDescriptor` — services always live at file level,
and the `FileDescriptor`-typed parameter is correct as-is.

### 4c — Run lint, build, test

The bridge nested message and enum tests should now pass (green).
The registry and integration tests still fail (next steps).

---

## Step 4b — Audit Internal Callers for Deprecation Warnings

After the new typed overloads are in place and the deprecated wrappers are added,
run a full build and check for deprecation warnings from **existing** code.

### 4b.1 — Find all call sites that may route through deprecated wrappers

```bash
# Find Any?-typed parent usage in Sources
rg "parent:.*as Any" Sources/

# Find explicit Any? variable passed as parent
rg "let .+: Any\?" Sources/

# Find fromProtobufDescriptor calls that pass FileDescriptor? typed variable
rg "fromProtobufDescriptor.*parent:" Sources/

# Find MessageDescriptor / EnumDescriptor init calls with parent:
rg "MessageDescriptor\(.*parent:" Sources/
rg "EnumDescriptor\(.*parent:" Sources/
```

### 4b.2 — Update callers in `Sources/`

For each match, update the call to use the typed API directly:

```swift
// Before — routes through deprecated Any? wrapper
MessageDescriptor(name: name, parent: someFileDesc as Any)

// After — direct, no deprecation warning
MessageDescriptor(name: name, parent: someFileDesc)   // FileDescriptor conforms to DescriptorParent

// Before — routes through deprecated FileDescriptor? wrapper
bridge.fromProtobufDescriptor(proto, parent: fileDesc as FileDescriptor?)

// After
bridge.fromProtobufDescriptor(proto, parent: fileDesc)
```

### 4b.3 — Update callers in `Tests/`

Run the same grep over `Tests/`. Existing test files that call `init(parent:)` with
`FileDescriptor` or `MessageDescriptor` will compile cleanly after these types conform to
`DescriptorParent` — no code change needed unless variables are explicitly typed as `Any?`
or `FileDescriptor?`.

```bash
rg "parent:.*as Any\?" Tests/
rg "MessageDescriptor\(.*parent:.*FileDescriptor" Tests/
```

### 4b.4 — Confirm zero deprecation warnings

```bash
swift build 2>&1 | grep -i "deprecated"
```

Expected output: empty. All internal callers must use the new typed API.
Any remaining deprecation warnings in `Sources/` are a bug — fix them.
Deprecation warnings in `Tests/` from newly added tests that intentionally test
the deprecated wrappers (from `DescriptorBridgeDeprecatedAPITests`) are acceptable
and should be suppressed with `#if swift(>=5.9)` or a targeted `@available` annotation
on those specific test methods.

---

## Step 4c — Verify Leading Dot Stripping in `JSONDeserializer`

Proto binary descriptors store type names with a leading dot (`.pkg.Parent.SearchFilters`).
`TypeRegistry` stores types without the dot (`pkg.Parent.SearchFilters`).
This step verifies the deserializer handles the mismatch.

### 4c.1 — Write leading-dot tests first

The tests are already defined in `TEST_PLAN.md`, Group 7.1b. Write them now against
the existing `JSONDeserializer` code. They will either pass (dot already stripped) or fail.

### 4c.2 — Inspect current lookup logic

```bash
rg "typeName" Sources/SwiftProtoReflect/Serialization/JSONDeserializer.swift
```

Check whether the deserializer does something like:

```swift
registry.findMessage(named: typeName)
```

or:

```swift
let lookupName = typeName.hasPrefix(".") ? String(typeName.dropFirst()) : typeName
registry.findMessage(named: lookupName)
```

### 4c.3 — Add the strip if missing

If the leading dot is **not** stripped, add a helper in `JSONDeserializer.swift`:

```swift
/// Normalises a proto type name for registry lookup.
///
/// Proto descriptors store type names with a leading dot (e.g. `.pkg.Msg`).
/// `TypeRegistry` stores them without the dot. This function removes the leading
/// dot so lookups succeed regardless of which format the caller uses.
private func normaliseTypeName(_ typeName: String) -> String {
    typeName.hasPrefix(".") ? String(typeName.dropFirst()) : typeName
}
```

Then replace every `registry.findMessage(named: typeName)` with
`registry.findMessage(named: normaliseTypeName(typeName))`.

### 4c.4 — Run the Group 7.1b tests

```bash
make test
```

All four leading-dot tests must pass before continuing to Step 5.

---

## Step 5 — Write and Run Registry Tests

### 5a — Write failing tests

**Files:**
- `Tests/SwiftProtoReflectTests/Registry/DescriptorPoolNestedTypesTests.swift`
- `Tests/SwiftProtoReflectTests/Registry/TypeRegistryNestedTypesTests.swift`

See `TEST_PLAN.md`, Parts 5–6.

These tests fail because `DescriptorPool` and `TypeRegistry` currently store nested types
under bare names (e.g. `"Cursor"` instead of `"pkg.GetGroupedAdsResponse.Cursor"`).
With the `DescriptorBridge` fix in place, nested types now carry qualified `fullName`.
The pool and registry don't need code changes — the tests pass purely from the bridge fix.

### 5b — Confirm tests pass

```bash
make test
```

All pool and registry tests should now pass with no changes to those files.

**If any pool/registry test still fails**, it indicates a secondary issue in pool/registry logic
that must be fixed before continuing.

---

## Step 6 — Write and Run Deserializer Tests

### 6a — Write failing tests

**File:** `Tests/SwiftProtoReflectTests/Serialization/JSONDeserializerNestedTypesTests.swift`

See `TEST_PLAN.md`, Part 7 (30 tests).

Tests in Group 7.1 (`test_deserialize_nestedMessageField_succeeds` and friends) fail
because, even with the bridge fix, the test registry must be populated correctly.
Tests in Group 7.2 (error 16) verify the negative cases.

### 6b — Confirm tests pass

No changes to `JSONDeserializer.swift` expected. Tests pass purely because the registry
now holds qualified names, and `registry.findMessage(named: typeName)` succeeds.

If a test still fails, investigate whether `field.typeName` is set correctly (it should
be the fully-qualified type name from the proto file, e.g. `".pkg.Parent.SearchFilters"`).
The deserializer strips the leading dot when looking up in the registry:

```swift
// Verify this logic in JSONDeserializer — strip leading dot for lookup
let lookupName = typeName.hasPrefix(".") ? String(typeName.dropFirst()) : typeName
registry.findMessage(named: lookupName)
```

If this stripping is not currently done, add it as a secondary fix and add a corresponding test.

---

## Step 7 — Write and Run Integration Tests

### 7a — Write failing tests

**File:** `Tests/SwiftProtoReflectTests/Integration/NestedTypesIntegrationTests.swift`

See `TEST_PLAN.md`, Part 8 (25 tests). All should now pass since the underlying fix is complete.

### 7b — Run full test suite

```bash
make test
```

Expected: all 224 new tests pass, zero regressions in existing tests.

---

## Step 8 — Update `MIGRATION_GUIDE.md`

Append the following section:

```markdown
## Version X.Y.Z — Typed `DescriptorParent` Protocol

### Background

`MessageDescriptor.init(name:parent:)` and `EnumDescriptor.init(name:parent:)` previously
accepted `Any?` as the parent parameter. `DescriptorBridge.fromProtobufDescriptor(_:parent:)`
accepted `FileDescriptor?` (which prevented passing a `MessageDescriptor` for nested types,
causing incorrect `fullName` on nested descriptors).

A new `DescriptorParent` protocol has been introduced. Both `FileDescriptor` and
`MessageDescriptor` conform to it.

### What changed

| Symbol | Before | After |
|--------|--------|-------|
| `MessageDescriptor.init(name:parent:options:)` | `parent: Any?` | `parent: (any DescriptorParent)?` |
| `EnumDescriptor.init(name:parent:options:)` | `parent: Any?` | `parent: (any DescriptorParent)?` |
| `DescriptorBridge.fromProtobufDescriptor(_:parent:)` | `parent: FileDescriptor?` | `parent: (any DescriptorParent)?` |
| `DescriptorBridge.fromProtobufEnumDescriptor(_:parent:)` | `parent: Any?` | `parent: (any DescriptorParent)?` |

Old signatures are deprecated and remain as wrappers. Existing code compiles unchanged
but shows deprecation warnings.

### Migration

```swift
// Before
MessageDescriptor(name: "Child", parent: parentMessage as Any)
// After
MessageDescriptor(name: "Child", parent: parentMessage)    // MessageDescriptor conforms to DescriptorParent

// Before
DescriptorBridge().fromProtobufDescriptor(proto, parent: fileDescriptor)
// After — same call, FileDescriptor now resolves to the new typed overload
DescriptorBridge().fromProtobufDescriptor(proto, parent: fileDescriptor)
```

### Bug fix included

Nested `MessageDescriptor` and `EnumDescriptor` instances created via `DescriptorBridge`
now carry correct fully-qualified `fullName` values (e.g. `"pkg.Parent.Child"` instead of
`"Child"`). This resolves:
- `RegistryError.duplicateType` when registering messages with nested types
- `JSONDeserializationError.nestedMessageDescriptorNotFound` (error 16) for nested message fields
```

---

## Step 9 — Final Verification

```bash
make format
make lint
swift build
make test
```

All four gates must exit 0 with zero warnings related to new code.

### Checklist

- [ ] `DescriptorParent.swift` created with protocol and doc comments
- [ ] `FileDescriptor` conforms to `DescriptorParent` (extension)
- [ ] `MessageDescriptor` conforms to `DescriptorParent` (extension)
- [ ] `MessageDescriptor.init(name:parent: (any DescriptorParent)?)` — new primary init
- [ ] `MessageDescriptor.init(name:parent: Any?)` — deprecated wrapper, **no `= nil`**
- [ ] `EnumDescriptor.init(name:parent: (any DescriptorParent)?)` — new primary init
- [ ] `EnumDescriptor.init(name:parent: Any?)` — deprecated wrapper, **no `= nil`**
- [ ] `DescriptorBridge.fromProtobufDescriptor(_:parent: (any DescriptorParent)?)` — new primary
- [ ] `DescriptorBridge.fromProtobufDescriptor(_:parent: FileDescriptor?)` — deprecated wrapper
- [ ] `DescriptorBridge.fromProtobufEnumDescriptor(_:parent: (any DescriptorParent)?)` — new
- [ ] `DescriptorBridge.fromProtobufEnumDescriptor(_:parent: Any?)` — deprecated wrapper, **no `= nil`**
- [ ] Nested messages pass `parent: messageDescriptor` (not `nil`) in recursion
- [ ] Nested enums pass `parent: messageDescriptor` in recursion
- [ ] `fromProtobufFileDescriptor` updated to cast `fileDescriptor` to `(any DescriptorParent)?` (avoids deprecated overload)
- [ ] Internal `Sources/` callers updated — zero deprecation warnings from production code
- [ ] `JSONDeserializer` strips leading dot from `typeName` before registry lookup
- [ ] All 224 new tests pass
- [ ] Zero regressions in existing test suite
- [ ] `MIGRATION_GUIDE.md` updated
- [ ] `make format && make lint && swift build && make test` all exit 0

---

## Design Decisions Record

### Why `DescriptorParent` and not `Any?`

`Any?` accepts literally any value. Passing a wrong type (e.g. a `String`) silently falls
into the `else` branch and produces `fullName = name`, which is indistinguishable from the
bug we are fixing. `DescriptorParent` makes invalid usage a compile-time error.

### Why not a separate `open` class hierarchy

`FileDescriptor` and `MessageDescriptor` are value types (`struct`). Class inheritance
would require changing them to reference types, which is a much larger and riskier change.
Protocols are the idiomatic Swift mechanism here.

### Why `descriptorParentMessageFullName: String?` instead of `isMessage: Bool`

The consuming code (`MessageDescriptor.init`) needs the full name of the parent message
for `parentMessageFullName`. Providing it directly via the protocol avoids a secondary
lookup and keeps the init body simple.

### Why no `= nil` on deprecated `Any?` overloads

When both `init(name:parent: (any DescriptorParent)? = nil)` and
`init(name:parent: Any? = nil)` have default values, Swift considers `MessageDescriptor(name: "X")`
ambiguous and refuses to compile. Removing `= nil` from the deprecated version ensures:
- No-argument calls → new typed overload ✓
- `parent: nil` literal → new typed overload (`nil` inferred as `(any DescriptorParent)?`) ✓
- `parent: someAnyVariable` → deprecated overload (deprecation warning shown) ✓

### Why `fromProtobufServiceDescriptor` is unchanged

Services are always defined at file scope in Protocol Buffers. A service can never be
nested inside a message. `FileDescriptor` is the only valid parent, so the existing
`parent: FileDescriptor?` signature is correct and does not need to be widened.
