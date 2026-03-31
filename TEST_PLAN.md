# Test Plan: Fix Nested Type `fullName` in `DescriptorBridge`

## Background

`DescriptorBridge.fromProtobufDescriptor` passes `parent: nil` when recursing into nested
messages, causing every nested `MessageDescriptor` to get a bare, unqualified `fullName`
(e.g. `"Cursor"` instead of `"pkg.GetGroupedAdsResponse.Cursor"`). The same defect applies
to nested enums. This produces two downstream failures:

- **Failure 1** — `RegistryError.duplicateType` when registering a message with nested types
- **Failure 2** — `JSONDeserializationError.nestedMessageDescriptorNotFound` (error 16)

Root cause and full analysis: see `ISSUE.md`.
Implementation plan: see `IMPLEMENTATION_PLAN.md`.

---

## Test File Structure

```
Tests/SwiftProtoReflectTests/
  Bridge/
    DescriptorBridgeNestedMessageTests.swift          (31 tests)
    DescriptorBridgeNestedEnumTests.swift             (20 tests)
    DescriptorBridgeRegressionTests.swift             (15 tests)
    DescriptorBridgeDeprecatedAPITests.swift          (11 tests)
  Descriptor/
    DescriptorParentProtocolTests.swift               (18 tests)
  Registry/
    DescriptorPoolNestedTypesTests.swift              (35 tests)
    TypeRegistryNestedTypesTests.swift                (35 tests)
  Serialization/
    JSONDeserializerNestedTypesTests.swift            (34 tests)   ← +4 leading-dot tests
  Integration/
    NestedTypesIntegrationTests.swift                 (25 tests)

Total: 224 tests
```

---

## Shared Fixtures

All test files should use the following proto structures, defined once in
`Tests/SwiftProtoReflectTests/Fixtures/NestedTypeFixtures.swift`:

```swift
// ─── Protobuf descriptor factories ───────────────────────────────────────────

func makeFieldProto(name: String, number: Int32, type: Google_Protobuf_FieldDescriptorProto.TypeEnum,
                    label: Google_Protobuf_FieldDescriptorProto.Label = .optional,
                    typeName: String? = nil) -> Google_Protobuf_FieldDescriptorProto

func makeEnumProto(name: String, values: [(String, Int32)]) -> Google_Protobuf_EnumDescriptorProto

func makeMessageProto(name: String,
                      fields: [Google_Protobuf_FieldDescriptorProto] = [],
                      nestedMessages: [Google_Protobuf_DescriptorProto] = [],
                      nestedEnums: [Google_Protobuf_EnumDescriptorProto] = []) -> Google_Protobuf_DescriptorProto

func makeFileProto(name: String, package: String, syntax: String = "proto3",
                   messages: [Google_Protobuf_DescriptorProto] = [],
                   enums: [Google_Protobuf_EnumDescriptorProto] = []) -> Google_Protobuf_FileDescriptorProto

// ─── Pre-built scenarios (used across multiple test files) ───────────────────

/// pkg.GetGroupedAdsResponse { message Cursor; message Item }  (Failure 1 repro)
var adsResponseFileProto: Google_Protobuf_FileDescriptorProto { get }

/// pkg.GetGroupedAdsRequest { message SearchFilters }          (Failure 2 repro)
var adsRequestFileProto: Google_Protobuf_FileDescriptorProto { get }

/// pkg.A { message B { message C { string value = 1; } } }     (3-level nesting)
var deepNestingFileProto: Google_Protobuf_FileDescriptorProto { get }

/// pkg.Parent { message Child; enum Status { UNKNOWN=0; ACTIVE=1; } }
var parentWithEnumFileProto: Google_Protobuf_FileDescriptorProto { get }
```

---

## Part 1 — `DescriptorBridgeNestedMessageTests` (31 tests)

**File:** `Tests/SwiftProtoReflectTests/Bridge/DescriptorBridgeNestedMessageTests.swift`

### Group 1.1 — `fullName` computation for nested messages (core fix)

```
test_fromProtobufDescriptor_flatMessage_withPackage_fullNameIncludesPackage
  Input : message proto "Person", FileDescriptor package="pkg"
  Assert: result.fullName == "pkg.Person"

test_fromProtobufDescriptor_flatMessage_emptyPackage_fullNameEqualsName
  Input : message proto "Person", FileDescriptor package=""
  Assert: result.fullName == "Person"

test_fromProtobufDescriptor_nestedMessage_fullNameIsQualified          ★ core fix
  Input : "Parent" with nested "Child", package="pkg"
  Assert: nestedMessages["Child"]!.fullName == "pkg.Parent.Child"

test_fromProtobufDescriptor_nestedMessage_parentFullNameUnchangedAfterAdd
  Input : same as above
  Assert: result.fullName == "pkg.Parent"

test_fromProtobufDescriptor_nestedMessage_bareNameNeverUsedAsFullName  ★ regression guard
  Input : "Parent" with nested "Child", package="pkg"
  Assert: nestedMessages["Child"]!.fullName != "Child"

test_fromProtobufDescriptor_nestedMessage_emptyPackage_noPackagePrefix
  Input : "Parent" with nested "Child", no package
  Assert: nestedMessages["Child"]!.fullName == "Parent.Child"

test_fromProtobufDescriptor_doubleNestedMessage_allFullNamesQualified
  Input : A { B { C } }, package="pkg"
  Assert: A.fullName == "pkg.A"
          A.nestedMessages["B"]!.fullName == "pkg.A.B"
          A.nestedMessages["B"]!.nestedMessages["C"]!.fullName == "pkg.A.B.C"

test_fromProtobufDescriptor_tripleNestedMessage_fullyQualified
  Input : A { B { C { D } } }, package="pkg"
  Assert: D.fullName == "pkg.A.B.C.D"

test_fromProtobufDescriptor_multipleNestedMessages_eachGetsOwnQualifiedName
  Input : Parent { Child1; Child2 }, package="pkg"
  Assert: Child1.fullName == "pkg.Parent.Child1"
          Child2.fullName == "pkg.Parent.Child2"

test_fromProtobufDescriptor_nestedMessage_storedUnderSimpleNameInDict
  Input : Parent { Child }, package="pkg"
  Assert: nestedMessages["Child"] != nil
          nestedMessages["pkg.Parent.Child"] == nil   ← dict key is always simple name

test_fromProtobufDescriptor_nestedMessage_sameNameAsParent_stillQualified
  Input : message A { message A { string x = 1; } }, package="pkg"
  Assert: inner.fullName == "pkg.A.A"
```

### Group 1.2 — Inherited properties

```
test_fromProtobufDescriptor_nestedMessage_inheritsParentSyntax
  Input : proto3 file, Parent { Child }
  Assert: Child.syntax == "proto3"

test_fromProtobufDescriptor_nestedMessage_inheritsSyntaxProto2
  Input : proto2 file, Parent { Child }
  Assert: Child.syntax == "proto2"

test_fromProtobufDescriptor_nestedMessage_inheritsFileDescriptorPath
  Input : file named "myfile.proto", Parent { Child }
  Assert: Child.fileDescriptorPath == "myfile.proto"

test_fromProtobufDescriptor_nestedMessage_parentMessageFullNameSet
  Input : Parent { Child }, package="pkg"
  Assert: Child.parentMessageFullName == "pkg.Parent"

test_fromProtobufDescriptor_nestedMessage_fieldsPreserved
  Input : Parent { Child { string name = 1; } }
  Assert: Child.field(number: 1)?.name == "name"
```

### Group 1.3 — `fromProtobufDescriptor` with explicit parents

```
test_fromProtobufDescriptor_withFileDescriptorParent_behaviorUnchanged
  Input : pass FileDescriptor as parent (existing behavior)
  Assert: result.fullName == "pkg.Message"            ← regression

test_fromProtobufDescriptor_withMessageDescriptorParent_qualifiesCorrectly
  Input : pass a MessageDescriptor as parent explicitly
  Assert: result.fullName == "pkg.Outer.Inner"

test_fromProtobufDescriptor_withNilParent_fullNameEqualsName
  Input : parent = nil
  Assert: result.fullName == "MessageName"
```

### Group 1.4 — `fromProtobufFileDescriptor` integration

```
test_fromProtobufFileDescriptor_messageWithNested_qualifiedFullNames
  Input : FileDescriptorProto with pkg.Parent { Child }
  Assert: all nested fullNames qualified

test_fromProtobufFileDescriptor_twoTopLevelMessagesEachWithNested
  Input : pkg.A { X }, pkg.B { Y }
  Assert: A.X.fullName == "pkg.A.X", B.Y.fullName == "pkg.B.Y"

test_fromProtobufFileDescriptor_3LevelNesting_allQualified
  Input : pkg.A { B { C } }
  Assert: three fully qualified names

test_fromProtobufFileDescriptor_noPackage_nestedHasNoPackagePrefix
  Input : package="" , A { B }
  Assert: B.fullName == "A.B"
```

### Group 1.5 — Fields referencing nested types

```
test_fromProtobufDescriptor_fieldTypeName_notModifiedByBridge
  Input : field with typeName = ".pkg.Parent.Child"
  Assert: field.typeName == ".pkg.Parent.Child"   ← bridge never rewrites typeName

test_fromProtobufDescriptor_repeatedNestedMessageField_typeNamePreserved
  Input : repeated Child field, typeName = ".pkg.Parent.Child"
  Assert: field.typeName == ".pkg.Parent.Child"

test_fromProtobufDescriptor_mapFieldWithNestedMessageValue_typeNamePreserved
  Input : map<string, Child> field
  Assert: map value typeName preserved
```

---

## Part 2 — `DescriptorBridgeNestedEnumTests` (20 tests)

**File:** `Tests/SwiftProtoReflectTests/Bridge/DescriptorBridgeNestedEnumTests.swift`

### Group 2.1 — `fullName` computation for nested enums (core fix)

```
test_fromProtobufDescriptor_nestedEnum_fullNameIsQualified             ★ core fix
  Input : Parent { enum Status { UNKNOWN=0; ACTIVE=1; } }, package="pkg"
  Assert: nestedEnums["Status"]!.fullName == "pkg.Parent.Status"

test_fromProtobufDescriptor_nestedEnum_bareNameNeverUsedAsFullName     ★ regression guard
  Assert: nestedEnums["Status"]!.fullName != "Status"

test_fromProtobufDescriptor_nestedEnum_parentMessageFullNameSet
  Assert: nestedEnums["Status"]!.parentMessageFullName == "pkg.Parent"

test_fromProtobufDescriptor_nestedEnum_emptyPackage_noPackagePrefix
  Input : no package
  Assert: nestedEnums["Status"]!.fullName == "Parent.Status"

test_fromProtobufDescriptor_multipleNestedEnums_eachQualified
  Input : Parent { enum Status; enum Type }, package="pkg"
  Assert: Status.fullName == "pkg.Parent.Status"
          Type.fullName   == "pkg.Parent.Type"

test_fromProtobufDescriptor_nestedEnum_inDoublyNestedMessage_fullyQualified
  Input : A { B { enum Color } }, package="pkg"
  Assert: Color.fullName == "pkg.A.B.Color"

test_fromProtobufDescriptor_nestedEnumAndNestedMessage_bothQualified
  Input : Parent { Child; enum Status }
  Assert: both fullNames qualified with "pkg.Parent."

test_fromProtobufDescriptor_nestedEnum_valuesPreserved
  Input : enum Status { UNKNOWN=0; ACTIVE=1; }
  Assert: allValues() count == 2, names and numbers correct
```

### Group 2.2 — `fromProtobufEnumDescriptor` with explicit parents

```
test_fromProtobufEnumDescriptor_withMessageDescriptorParent_qualifiesCorrectly
  Input : pass MessageDescriptor as parent explicitly
  Assert: enum.fullName == "pkg.Parent.Status"

test_fromProtobufEnumDescriptor_withFileDescriptorParent_behaviorUnchanged
  Input : pass FileDescriptor as parent
  Assert: enum.fullName == "pkg.Status"             ← regression

test_fromProtobufEnumDescriptor_withNilParent_fullNameEqualsName
  Input : parent = nil
  Assert: enum.fullName == "Status"
```

### Group 2.3 — Inherited properties and edge cases

```
test_fromProtobufDescriptor_nestedEnum_fileDescriptorPathInherited
  Input : file "myfile.proto", Parent { enum Status }
  Assert: Status.fileDescriptorPath == "myfile.proto"

test_fromProtobufDescriptor_nestedEnumSameNameAsNestedMessage_bothQualified
  Input : Parent { message Status; enum Status } — pathological but valid in proto
  (note: proto allows message and enum with same name in same scope)
  Assert: nestedEnums["Status"]!.fullName   == "pkg.Parent.Status"
          nestedMessages["Status"]!.fullName == "pkg.Parent.Status"

test_fromProtobufDescriptor_nestedMessageWithItsOwnNestedEnum_qualifiedDeep
  Input : pkg.Parent.Child { enum ChildStatus }
  Assert: ChildStatus.fullName == "pkg.Parent.Child.ChildStatus"

test_fromProtobufDescriptor_nestedEnum_noLeadingDot_noPackage
  Input : no package, Parent { enum Status }
  Assert: Status.fullName does not start with "."

test_fromProtobufFileDescriptor_withNestedEnum_fullPipelineQualified
  Input : full FileDescriptorProto with nested enum
  Assert: enum in resulting FileDescriptor has qualified fullName

test_fromProtobufDescriptor_proto2Message_nestedEnum_qualified
  Input : syntax="proto2"
  Assert: fullName still qualified correctly

test_fromProtobufDescriptor_nestedEnumValues_accessible
  Input : Parent { enum Status { UNKNOWN=0; ACTIVE=1; } }
  Assert: nestedEnums["Status"]!.value(named: "ACTIVE")?.number == 1
```

---

## Part 3 — `DescriptorBridgeRegressionTests` (15 tests)

**File:** `Tests/SwiftProtoReflectTests/Bridge/DescriptorBridgeRegressionTests.swift`

Verify that nothing existing broke after the fix.

```
test_fromProtobufDescriptor_allScalarFieldTypes_preservedCorrectly
  Assert: bool/int32/int64/uint32/uint64/float/double/string/bytes all convert

test_fromProtobufDescriptor_repeatedField_isRepeatedTrue
test_fromProtobufDescriptor_requiredField_proto2_isRequiredTrue
test_fromProtobufDescriptor_mapField_isMapTrue_mapEntryInfoSet
test_fromProtobufDescriptor_packedField_isPackedTrue
test_fromProtobufDescriptor_oneofDecl_countAndNamesPreserved
test_fromProtobufDescriptor_extensionRange_preservedCorrectly
test_fromProtobufDescriptor_proto2DefaultValues_preservedCorrectly
test_fromProtobufFileDescriptor_fileEnumsAtTopLevel_qualifiedByPackage
test_fromProtobufFileDescriptor_services_convertedCorrectly
test_fromProtobufFileDescriptor_dependencies_preservedCorrectly
test_toProtobufDescriptor_roundTrip_flatMessage_identicalFields
test_toProtobufDescriptor_roundTrip_messageWithNestedMessage_identicalStructure
test_toProtobufDescriptor_roundTrip_messageWithNestedEnum_identicalValues
test_fromProtobufDescriptor_jsonName_preservedFromProto
```

---

## Part 3b — `DescriptorBridgeDeprecatedAPITests` (11 tests)

**File:** `Tests/SwiftProtoReflectTests/Bridge/DescriptorBridgeDeprecatedAPITests.swift`

Tests that verify every deprecated backward-compatible wrapper still works correctly
and delegates to the new typed implementation.

### Group 3b.1 — `fromProtobufDescriptor(parent: FileDescriptor?)` wrapper

```
test_fromProtobufDescriptor_deprecatedFileDescriptorWrapper_withFileDescriptor_succeeds
  Input : call via deprecated signature with a non-nil FileDescriptor
  Assert: result.fullName == "pkg.Message"  (delegates to new typed overload)

test_fromProtobufDescriptor_deprecatedFileDescriptorWrapper_withNil_succeeds
  Input : call via deprecated signature with parent: nil
  Assert: result.fullName == "Message"

test_fromProtobufDescriptor_deprecatedFileDescriptorWrapper_nestedFullNamesQualified
  Input : deprecated call for message with nested types
  Assert: nested.fullName == "pkg.Parent.Child"  (fix works through deprecated path)
```

### Group 3b.2 — `fromProtobufEnumDescriptor(parent: Any?)` wrapper

```
test_fromProtobufEnumDescriptor_deprecatedAnyWrapper_withFileDescriptor_delegatesCorrectly
  Input : call via deprecated Any? signature, passing FileDescriptor
  Assert: enum.fullName == "pkg.Status"

test_fromProtobufEnumDescriptor_deprecatedAnyWrapper_withMessageDescriptor_delegatesCorrectly
  Input : call via deprecated Any? signature, passing MessageDescriptor
  Assert: enum.fullName == "pkg.Parent.Status"

test_fromProtobufEnumDescriptor_deprecatedAnyWrapper_withWrongType_treatsAsNilParent
  Input : call via deprecated Any? signature, passing "wrong_type" (String)
  Assert: enum.fullName == "Status"  ← graceful degradation, not a crash
```

### Group 3b.3 — `MessageDescriptor.init(name:parent: Any?)` wrapper

```
test_messageDescriptorInit_deprecatedAnyWrapper_withFileDescriptor_delegatesCorrectly
  Input : MessageDescriptor(name: "X", parent: fd as Any)  where fd: FileDescriptor
  Assert: result.fullName == "pkg.X"

test_messageDescriptorInit_deprecatedAnyWrapper_withMessageDescriptor_delegatesCorrectly
  Input : MessageDescriptor(name: "Child", parent: parentMsg as Any)
  Assert: result.fullName == "pkg.Parent.Child"

test_messageDescriptorInit_deprecatedAnyWrapper_withWrongType_treatsAsNilParent
  Input : MessageDescriptor(name: "X", parent: "some_string" as Any)
  Assert: result.fullName == "X"  ← graceful degradation, documents expected behavior
  Note  : this behavior is intentional — wrong type is treated as nil parent
```

### Group 3b.4 — `EnumDescriptor.init(name:parent: Any?)` wrapper

```
test_enumDescriptorInit_deprecatedAnyWrapper_withFileDescriptor_delegatesCorrectly
  Input : EnumDescriptor(name: "Status", parent: fd as Any)
  Assert: result.fullName == "pkg.Status"

test_enumDescriptorInit_deprecatedAnyWrapper_withWrongType_treatsAsNilParent
  Input : EnumDescriptor(name: "Status", parent: 42 as Any)
  Assert: result.fullName == "Status"
```

---

## Part 4 — `DescriptorParentProtocolTests` (18 tests)

**File:** `Tests/SwiftProtoReflectTests/Descriptor/DescriptorParentProtocolTests.swift`

Tests for the new `DescriptorParent` protocol and its conformances.

### Group 4.1 — `FileDescriptor` conformance

```
test_fileDescriptor_descriptorFullNamePrefix_equalsPackage
  Input : FileDescriptor(name: "f.proto", package: "pkg")
  Assert: fd.descriptorFullNamePrefix == "pkg"

test_fileDescriptor_descriptorFullNamePrefix_emptyPackage
  Input : FileDescriptor(name: "f.proto", package: "")
  Assert: fd.descriptorFullNamePrefix == ""

test_fileDescriptor_descriptorFilePath_equalsName
  Assert: fd.descriptorFilePath == "f.proto"

test_fileDescriptor_descriptorSyntax_equalsFileSyntax
  Input : syntax = "proto3"
  Assert: fd.descriptorSyntax == "proto3"

test_fileDescriptor_descriptorParentMessageFullName_isNil
  Assert: fd.descriptorParentMessageFullName == nil

test_fileDescriptor_conformsToDescriptorParent
  Assert: (FileDescriptor(...) as? any DescriptorParent) != nil
  (or: let _: any DescriptorParent = fd)
```

### Group 4.2 — `MessageDescriptor` conformance

```
test_messageDescriptor_descriptorFullNamePrefix_equalsFullName
  Input : MessageDescriptor(name: "Msg", fullName: "pkg.Msg")
  Assert: msg.descriptorFullNamePrefix == "pkg.Msg"

test_messageDescriptor_descriptorFilePath_equalsFileDescriptorPath
  Input : msg.fileDescriptorPath = "f.proto"
  Assert: msg.descriptorFilePath == "f.proto"

test_messageDescriptor_descriptorFilePath_nilWhenNotSet
  Assert: msg.descriptorFilePath == nil

test_messageDescriptor_descriptorSyntax_equalsSyntax
  Input : MessageDescriptor(name: "M", fullName: "M", syntax: "proto2")
  Assert: msg.descriptorSyntax == "proto2"

test_messageDescriptor_descriptorParentMessageFullName_equalsFullName
  Input : MessageDescriptor(name: "M", fullName: "pkg.Parent.M")
  Assert: msg.descriptorParentMessageFullName == "pkg.Parent.M"

test_messageDescriptor_conformsToDescriptorParent
  Assert: (MessageDescriptor(...) as? any DescriptorParent) != nil
```

### Group 4.3 — Protocol usage in init / factory functions

```
test_descriptorParent_fileDescriptor_usedInMessageDescriptorInit_fullNameCorrect
  Input : MessageDescriptor(name: "Msg", parent: fd)  where fd: FileDescriptor
  Assert: result.fullName == "pkg.Msg"

test_descriptorParent_messageDescriptor_usedInMessageDescriptorInit_fullNameCorrect
  Input : MessageDescriptor(name: "Child", parent: parentMsg)
  Assert: result.fullName == "pkg.Parent.Child"

test_descriptorParent_fileDescriptor_usedInEnumDescriptorInit_fullNameCorrect
  Input : EnumDescriptor(name: "Status", parent: fd)
  Assert: result.fullName == "pkg.Status"

test_descriptorParent_messageDescriptor_usedInEnumDescriptorInit_fullNameCorrect
  Input : EnumDescriptor(name: "Status", parent: parentMsg)
  Assert: result.fullName == "pkg.Parent.Status"

test_descriptorParent_nil_messageDescriptorInit_fullNameEqualsName
  Input : MessageDescriptor(name: "Msg", parent: nil as (any DescriptorParent)?)
  Assert: result.fullName == "Msg"

test_descriptorParent_nil_enumDescriptorInit_fullNameEqualsName
  Input : EnumDescriptor(name: "Status", parent: nil as (any DescriptorParent)?)
  Assert: result.fullName == "Status"
```

---

## Part 5 — `DescriptorPoolNestedTypesTests` (35 tests)

**File:** `Tests/SwiftProtoReflectTests/Registry/DescriptorPoolNestedTypesTests.swift`

### Group 5.1 — Registration under qualified names

```
test_addFileDescriptor_messageWithNested_nestedStoredUnderQualifiedName   ★ core fix
  Input : file with pkg.Parent { Child }
  Assert: findMessageDescriptor(named: "pkg.Parent.Child") != nil

test_addFileDescriptor_messageWithNested_bareNameNotInPool                ★ regression guard
  Assert: findMessageDescriptor(named: "Child") == nil

test_addFileDescriptor_messageWithNested_parentStoredUnderQualifiedName
  Assert: findMessageDescriptor(named: "pkg.Parent") != nil

test_addFileDescriptor_messageWithNested_doesNotThrowDuplicateSymbol      ★ Failure 1 fix
  Assert: no error thrown during addFileDescriptor

test_addFileDescriptor_2LevelNesting_allThreeQualifiedInPool
  Input : pkg.A { B { C } }
  Assert: all three qualified names present in pool

test_addFileDescriptor_3LevelNesting_allFourQualifiedInPool
  Input : pkg.A { B { C { D } } }
  Assert: 4 qualified names present

test_addFileDescriptor_multipleNestedAtSameLevel_allQualified
  Input : pkg.Parent { Child1; Child2 }
  Assert: "pkg.Parent.Child1" and "pkg.Parent.Child2" both found

test_addFileDescriptor_nestedEnum_storedUnderQualifiedName
  Input : pkg.Parent { enum Status }
  Assert: findEnumDescriptor(named: "pkg.Parent.Status") != nil

test_addFileDescriptor_nestedEnum_bareNameNotInPool
  Assert: findEnumDescriptor(named: "Status") == nil
```

### Group 5.2 — `allMessageTypeNames` with qualified names

```
test_allMessageTypeNames_withNested_containsQualifiedChildName
  Assert: allMessageTypeNames().contains("pkg.Parent.Child")

test_allMessageTypeNames_withNested_doesNotContainBareChildName
  Assert: !allMessageTypeNames().contains("Child")

test_allMessageTypeNames_withNested_containsBothParentAndChild
  Assert: result contains "pkg.Parent" and "pkg.Parent.Child"

test_allMessageTypeNames_2LevelNesting_allThreeQualified
  Input : A { B { C } }
  Assert: ["pkg.A", "pkg.A.B", "pkg.A.B.C"] all in result

test_allMessageTypeNames_noNested_onlyTopLevel
  Input : flat message, no nested
  Assert: only "pkg.Message" returned  — regression
```

### Group 5.3 — Lookup correctness

```
test_findMessageDescriptor_nestedByQualifiedName_returnsCorrectDescriptor
  Assert: returned descriptor.name == "Child"
          returned descriptor.fullName == "pkg.Parent.Child"

test_findMessageDescriptor_nestedByBareName_returnsNil
  Assert: findMessageDescriptor(named: "Child") == nil

test_findMessageDescriptor_nestedDescriptor_hasCorrectFields
  Input : Child has string field "token"
  Assert: returned.field(named: "token") != nil

test_findMessageDescriptor_deeplyNested_fullyQualifiedName
  Input : pkg.A.B.C
  Assert: findMessageDescriptor(named: "pkg.A.B.C") != nil

test_findEnumDescriptor_nestedByQualifiedName_returns
  Assert: findEnumDescriptor(named: "pkg.Parent.Status") != nil
```

### Group 5.4 — Collision and duplicate handling

```
test_addFileDescriptor_sameNestedNameInDifferentParents_noDuplicateError
  Input : pkg.A { Cursor }  and  pkg.B { Cursor }  in separate files
  Assert: both pkg.A.Cursor and pkg.B.Cursor registered, no error

test_addFileDescriptor_sameQualifiedNameInTwoFiles_throwsDuplicateSymbol
  Input : two files both define pkg.Parent.Child
  Assert: second addFileDescriptor throws DescriptorPoolError.duplicateSymbol

test_addFileDescriptor_sameFileAddedTwice_throwsDuplicateFile
  Assert: DescriptorPoolError.duplicateFile

test_addFileDescriptor_twoPackagesWithSameNestedStructure_noCollision
  Input : pkg1.X.Y  and  pkg2.X.Y
  Assert: both in pool under their qualified names
```

### Group 5.5 — `findFileContainingSymbol`

```
test_findFileContainingSymbol_nestedByQualifiedName_findsCorrectFile
  Assert: returns the file that defined the nested type

test_findFileContainingSymbol_nestedByBareName_returnsNil
  Assert: nil for bare "Child"
```

### Group 5.6 — `createMessage`

```
test_createMessage_nestedTypeByQualifiedName_succeeds
  Assert: createMessage(forType: "pkg.Parent.Child") != nil

test_createMessage_nestedTypeByBareName_returnsNil
  Assert: createMessage(forType: "Child") == nil
```

### Group 5.7 — `findDependencies`

```
test_findDependencies_messageReferencingNestedType_dependencyIsQualified
  Input : Parent has field of type Child (typeName = ".pkg.Parent.Child")
  Assert: findDependencies returns set containing "pkg.Parent.Child" (if registered)

test_findDependencies_unknownType_throwsSymbolNotFound
  Assert: DescriptorPoolError.symbolNotFound
```

### Group 5.8 — `allEnumTypeNames`

```
test_allEnumTypeNames_nestedEnums_qualifiedNames
  Input : pkg.Parent { enum Status }
  Assert: allEnumTypeNames().contains("pkg.Parent.Status")
          !allEnumTypeNames().contains("Status")
```

### Group 5.9 — Regressions

```
test_addFileDescriptor_flatMessages_unchanged
test_addFileDescriptor_builtinDescriptors_notAffected
test_clear_removesAllNestedTypes
```

---

## Part 6 — `TypeRegistryNestedTypesTests` (35 tests)

**File:** `Tests/SwiftProtoReflectTests/Registry/TypeRegistryNestedTypesTests.swift`

### Group 6.1 — `registerFile` with nested types (preferred API)

```
test_registerFile_messageWithNested_nestedRegisteredUnderQualifiedName   ★ Failure 1 fix
  Input : FileDescriptor with pkg.Parent { Child }
  Assert: findMessage(named: "pkg.Parent.Child") != nil

test_registerFile_messageWithNested_bareNameNotRegistered
  Assert: findMessage(named: "Child") == nil

test_registerFile_messageWithNested_noThrowDuplicateType                 ★ Failure 1 fix
  Assert: registerFile does not throw

test_registerFile_2LevelNesting_allQualifiedRegistered
test_registerFile_nestedEnum_registeredUnderQualifiedName
test_registerFile_nestedEnum_bareNameNotRegistered
test_registerFile_twoMessagesEachWithNested_allQualified
test_registerFile_sameFileRegisteredTwice_throwsDuplicateFile
```

### Group 6.2 — `registerMessage` directly

```
test_registerMessage_topLevelWithNested_alsoRegistersNestedRecursively
  Input : registerMessage(parentDescriptor)
  Assert: findMessage(named: "pkg.Parent.Child") != nil afterwards

test_registerMessage_nestedDirectly_registeredUnderQualifiedName
  Input : registerMessage(childDescriptor)  where childDescriptor.fullName == "pkg.Parent.Child"
  Assert: findMessage(named: "pkg.Parent.Child") != nil

test_registerMessage_parentAfterChildDirectly_throwsDuplicateType
  Input : registerMessage(child), then registerMessage(parent)
  Assert: throws RegistryError.duplicateType("pkg.Parent.Child")
  Note  : expected behavior — child was registered twice

test_registerMessage_parentAfterChildDirectly_errorContainsQualifiedName
  Assert: error message contains "pkg.Parent.Child", NOT bare "Child"
  Note  : with fix, error message is now informative with qualified name

test_registerMessage_childDirectlyThenParent_errorContainsQualifiedName
  Same as above, verifies qualified name in error after fix
```

### Group 6.3 — `findMessage` after registration

```
test_findMessage_nestedByQualifiedName_returnsDescriptor
test_findMessage_nestedByBareName_returnsNil
test_findMessage_returnedDescriptor_hasCorrectFullName
test_findMessage_returnedDescriptor_hasCorrectFields
test_findMessage_deeplyNestedByFullyQualifiedName
```

### Group 6.4 — `hasMessage`

```
test_hasMessage_nestedByQualifiedName_returnsTrue
test_hasMessage_nestedByBareName_returnsFalse
```

### Group 6.5 — `resolveDependencies`

```
test_resolveDependencies_messageWithNestedField_dependencyIsQualifiedName
  Input : Parent.field(search_filters).typeName = ".pkg.Parent.SearchFilters"
  Assert: dependencies contain ".pkg.Parent.SearchFilters"

test_resolveDependencies_nestedType_includesNestedFullName
  Input : Parent contains nested Child (as field)
  Assert: nested fullName appears in dependencies
```

### Group 6.6 — `removeFile`

```
test_removeFile_withNestedTypes_removesNestedFromRegistry
  Input : registerFile(...), then removeFile(...)
  Assert: findMessage(named: "pkg.Parent.Child") == nil after remove

test_removeFile_withNestedEnum_removesNestedEnum
  Assert: findEnum(named: "pkg.Parent.Status") == nil after remove
```

### Group 6.7 — `allMessages`

```
test_allMessages_includesNestedWithQualifiedFullNames
  Assert: any(allMessages()) { $0.fullName == "pkg.Parent.Child" }

test_allMessages_noMessagesWithBareNestedNames
  Assert: none(allMessages()) { $0.fullName == "Child" }
```

### Group 6.8 — Corner cases

```
test_registerFile_sameNestedNameInDifferentMessages_bothRegistered
  Input : pkg.A { Cursor }  and  pkg.B { Cursor }
  Assert: both "pkg.A.Cursor" and "pkg.B.Cursor" registered, no error

test_registerFile_noPackage_nestedRegisteredWithoutPackagePrefix
  Input : no package, A { B }
  Assert: findMessage(named: "A.B") != nil

test_registerMessage_emptyNestedMessages_registersOnlyParent
  Input : message with no nested types
  Assert: only parent registered, no error
```

### Group 6.9 — Regressions

```
test_registerFile_flatMessages_unchanged
test_registerEnum_topLevel_unchanged
test_registerService_unchanged
```

---

## Part 7 — `JSONDeserializerNestedTypesTests` (34 tests)

**File:** `Tests/SwiftProtoReflectTests/Serialization/JSONDeserializerNestedTypesTests.swift`

### Group 7.1 — Deserialization with nested message fields (Failure 2 fix)

```
test_deserialize_nestedMessageField_succeeds                              ★ Failure 2 fix
  Input : pkg.GetGroupedAdsRequest { SearchFilters search_filters = 1; }
          JSON: { "search_filters": { "title": "test" } }
          Registry contains "pkg.GetGroupedAdsRequest.SearchFilters"
  Assert: no error thrown

test_deserialize_nestedMessageField_nestedFieldValuesCorrect
  Assert: result.field(named: "search_filters") contains DynamicMessage
          with field "title" == "test"

test_deserialize_twoNestedMessageFields_bothDeserializeCorrectly
  Input : message with two nested message fields
  Assert: both fields deserialized

test_deserialize_doublyNestedMessageField_succeeds
  Input : field referencing pkg.A.B.C
  Assert: no error

test_deserialize_repeatedNestedMessageField_succeeds
  Input : repeated pkg.Parent.Child field, JSON array
  Assert: array of DynamicMessage

test_deserialize_repeatedNestedMessageField_arrayCountCorrect
  Input : JSON array with 3 elements
  Assert: result array has count == 3

test_deserialize_nullNestedField_handledGracefully
  Input : JSON: { "search_filters": null }
  Assert: no crash, field treated as absent or nil

test_deserialize_missingNestedField_noError
  Input : nested message field not present in JSON
  Assert: no error, field uses default value
```

### Group 7.1b — Leading dot in `field.typeName`

Proto binary descriptors store type names with a leading dot (e.g. `".pkg.Parent.SearchFilters"`),
while `TypeRegistry` stores and looks up types **without** the leading dot
(e.g. `"pkg.Parent.SearchFilters"`). The deserializer must strip the dot before lookup.

```
test_deserialize_fieldTypeNameWithLeadingDot_lookupSucceeds               ★ leading-dot fix
  Input : field.typeName = ".pkg.GetGroupedAdsRequest.SearchFilters"   (leading dot)
          registry contains "pkg.GetGroupedAdsRequest.SearchFilters"   (no dot)
  Assert: deserialization succeeds — deserializer strips the leading dot before registry lookup

test_deserialize_fieldTypeNameWithoutLeadingDot_lookupSucceeds
  Input : field.typeName = "pkg.GetGroupedAdsRequest.SearchFilters"    (no leading dot)
          registry contains "pkg.GetGroupedAdsRequest.SearchFilters"
  Assert: deserialization succeeds                                      ← regression

test_deserialize_fieldTypeNameEmpty_throwsMissingTypeName
  Input : field.typeName = ""  (or not set)
  Assert: throws JSONDeserializationError.missingTypeName

test_deserialize_fieldTypeNameOnlyDot_throwsMissingTypeName
  Input : field.typeName = "."  (degenerate case)
  Assert: throws an error, does not look up "" in registry
```

### Group 7.2 — Error cases (error 16)

```
test_deserialize_nestedTypeNotInRegistry_throwsError16
  Input : registry is empty
  Assert: throws JSONDeserializationError.nestedMessageDescriptorNotFound

test_deserialize_nestedTypeInRegistryByBareName_throwsError16
  Input : registry contains "SearchFilters" (bare, not qualified)
  Assert: throws JSONDeserializationError.nestedMessageDescriptorNotFound
  Note  : validates that qualified lookup is required

test_deserialize_nestedTypeInRegistryByQualifiedName_succeeds
  Input : registry contains "pkg.GetGroupedAdsRequest.SearchFilters"
  Assert: no error                                                         ★ Failure 2 fix

test_deserialize_errorContainsFieldNameAndQualifiedTypeName
  Input : nested type not in registry
  Assert: error.fieldName == "search_filters"
          error.typeName  == "pkg.GetGroupedAdsRequest.SearchFilters"
```

### Group 7.3 — Nested enums in JSON

```
test_deserialize_nestedEnumField_knownValue_succeeds
  Input : field of type pkg.Parent.Status, JSON: "ACTIVE"
  Assert: deserialized to correct enum number

test_deserialize_nestedEnumField_unknownValue_handledPerSyntax
  Input : proto3, unknown enum string value
  Assert: behavior matches proto3 spec
```

### Group 7.4 — Exact ISSUE.md reproductions

```
test_deserialize_issueMd_failure2_exactRepro_succeeds                    ★ exact ISSUE repro
  Input : verbatim proto and JSON from ISSUE.md Failure 2 section
  Assert: no error thrown

test_deserialize_issueMd_failure2_searchFiltersTitle_correct
  Assert: deserialized "title" field == "test"

test_deserialize_issueMd_failure2_limitField_correct
  Assert: deserialized "limit" field == 10
```

### Group 7.5 — No registry

```
test_deserialize_nestedFieldWithoutRegistry_throwsUnsupportedNestedMessage
  Input : options.typeRegistry == nil, nested message field present
  Assert: throws JSONDeserializationError.unsupportedNestedMessage
```

### Group 7.6 — Oneof with nested message

```
test_deserialize_oneofContainingNestedMessageType_succeeds
  Input : oneof field whose type is a nested message
  Assert: deserialized correctly
```

### Group 7.7 — Regressions

```
test_deserialize_flatMessage_unchanged
test_deserialize_allScalarTypes_unchanged
test_deserialize_repeatedScalarField_unchanged
test_deserialize_mapField_unchanged
test_deserialize_topLevelEnumField_unchanged
test_deserialize_emptyMessage_unchanged
test_deserialize_nestedMessageWithAllScalarTypes_allFieldsCorrect
test_deserialize_proto2MessageWithNestedField_succeeds
test_deserialize_messageWithMapFieldWhereValueIsNestedMessage_succeeds
test_deserialize_mixedNestedAndScalarFields_allDeserialized
```

---

## Part 8 — `NestedTypesIntegrationTests` (25 tests)

**File:** `Tests/SwiftProtoReflectTests/Integration/NestedTypesIntegrationTests.swift`

### Group 8.1 — ISSUE.md exact reproductions end-to-end

```
test_integration_issueMd_failure1_exactRepro_noThrow                     ★ Failure 1 exact repro
  Steps: parse → bridge → pool → registry → iterate allMessageTypeNames → registerMessage each
  Input : verbatim from ISSUE.md Failure 1 (GetGroupedAdsResponse with Cursor and Item)
  Assert: no RegistryError.duplicateType thrown
  Note  : with fix, "pkg.GetGroupedAdsResponse.Cursor" is properly qualified;
          duplicate only if user manually registers nested again

test_integration_issueMd_failure2_exactRepro_deserializesCorrectly       ★ Failure 2 exact repro
  Steps: parse → bridge → pool → registerFile → deserializeFromJSONObject
  Input : verbatim from ISSUE.md Failure 2 (GetGroupedAdsRequest with SearchFilters)
  Assert: no JSONDeserializationError, "title" == "test", "limit" == 10
```

### Group 8.2 — Pool → Registry patterns

```
test_integration_poolToRegistryViaRegisterFile_noError
  Steps: addFileDescriptor → iterate fileDescriptors → registerFile each
  Assert: no error, all types accessible

test_integration_poolToRegistryViaAllMessageTypeNames_duplicateOnlyForQualifiedName
  Steps: addFileDescriptor → iterate allMessageTypeNames → registerMessage each
  Assert: if nested type appears in allMessageTypeNames, re-registering via parent
          throws duplicateType with QUALIFIED name (not bare)
  Note  : documents expected behavior for this (incorrect) usage pattern

test_integration_registerFile_preferred_noError
  Steps: registerFile(bridgedFileDescriptor)
  Assert: always clean, no duplicates, all qualified names accessible
```

### Group 8.3 — Deep nesting end-to-end

```
test_integration_3LevelNesting_bridgeToPoolToRegistryToDeserialize
  Input : pkg.A { B { C { string val = 1; } } }
          JSON: { "b": { "c": { "val": "hello" } } }
  Assert: full pipeline succeeds, val == "hello"

test_integration_sameNestedNameInTwoMessages_bothAccessible
  Input : pkg.A { Cursor }  and  pkg.B { Cursor }
  Assert: both "pkg.A.Cursor" and "pkg.B.Cursor" accessible after registration

test_integration_twoPackages_sameNestedName_noCollision
  Input : pkg1.X { Y }  and  pkg2.X { Y }
  Assert: both "pkg1.X.Y" and "pkg2.X.Y" accessible
```

### Group 8.4 — Nested enum end-to-end

```
test_integration_nestedEnum_bridgeToRegistryToDeserialize
  Input : Parent { enum Status }
  Assert: full pipeline, enum field deserialized correctly

test_integration_multipleLevelsOfNestedEnums_allQualified
  Input : A { B { enum Color } }
  Assert: "pkg.A.B.Color" accessible in pool and registry
```

### Group 8.5 — Multi-file scenarios

```
test_integration_twoFilesWithNestedTypes_allAccessible
  Input : file1 with A { X },  file2 with B { Y }
  Assert: all four types accessible

test_integration_removeFile_removesNestedTypesFromRegistry
  Steps: registerFile, verify nested accessible, removeFile, verify gone
```

### Group 8.6 — Roundtrip

```
test_integration_bridge_roundTrip_nestedMessage_fullNamePreserved
  Steps: FileDescriptorProto → fromProtobuf → toProtobuf → fromProtobuf
  Assert: nested fullName same before and after

test_integration_bridge_roundTrip_nestedEnum_fullNamePreserved
  Steps: same roundtrip for enum
  Assert: nested enum fullName preserved
```

### Group 8.7 — Complex real-world scenarios

```
test_integration_complexProto_getGroupedAdsResponse_allTypesAccessible
  Input : GetGroupedAdsResponse { repeated Item items; Cursor cursor;
                                   message Cursor; message Item }
  Assert: "pkg.GetGroupedAdsResponse",
          "pkg.GetGroupedAdsResponse.Cursor",
          "pkg.GetGroupedAdsResponse.Item" all accessible

test_integration_complexProto_getGroupedAdsRequest_searchFilters
  Input : GetGroupedAdsRequest { SearchFilters search_filters;
                                  int32 limit;
                                  message SearchFilters { string title = 1; } }
  Assert: full pipeline succeeds, SearchFilters accessible by qualified name

test_integration_pool_allMessageTypeNames_allQualified
  Assert: no bare names in allMessageTypeNames() after adding complex file

test_integration_pool_allEnumTypeNames_allQualified
  Assert: no bare names in allEnumTypeNames() after adding file with nested enums
```

### Group 8.8 — Proto2

```
test_integration_proto2_nestedMessage_syntaxInherited
  Input : proto2 file, Parent { Child }
  Assert: Child.syntax == "proto2" throughout pipeline

test_integration_proto2_requiredFieldInNested_preserved
  Input : proto2 nested message with required field
  Assert: field.isRequired == true after bridge
```

### Group 8.9 — Performance

```
test_integration_performance_100NestedTypes_bridgeAndRegisterWithinBudget
  Input : message with 100 nested message types
  Metric: measure { bridge + addFileDescriptor + registerFile }
  Assert: completes within acceptable time budget
  (use XCTAssert or XCTMeasure)
```

---

## Naming Convention

All test methods follow the project standard:

```
test_[component]_[method/scenario]_[condition]_[expectedResult]
```

Examples:
- `test_fromProtobufDescriptor_nestedMessage_withPackage_fullNameIsQualified`
- `test_addFileDescriptor_nestedMessage_bareNameNotInPool`
- `test_deserialize_nestedTypeNotInRegistry_throwsError16`

---

## Execution

```bash
make test
```

All 224 tests must pass with zero errors before the fix is considered done.
