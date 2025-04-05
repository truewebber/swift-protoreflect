import Foundation

/// Options for customizing Protocol Buffer message serialization and deserialization.
///
/// The `SerializationOptions` struct allows you to configure various aspects of Protocol Buffer
/// message serialization and deserialization, such as handling of unknown fields, preservation
/// of default values, and validation options.
///
/// Example:
/// ```swift
/// var options = SerializationOptions()
/// options.skipUnknownFields = true
/// options.preserveProto3Defaults = false
/// options.maxDepth = 50
///
/// let data = try message.serialize(options: options)
/// ```
public struct SerializationOptions {
    /// Whether to skip unknown fields during serialization.
    ///
    /// If `true`, unknown fields encountered during serialization will be ignored.
    /// If `false` (default), unknown fields will be preserved in the serialized output.
    public var skipUnknownFields: Bool = false
    
    /// Whether to preserve proto3 default values in output.
    ///
    /// In proto3, fields with default values are typically omitted from the serialized output.
    /// If `true`, fields with default values will be included in the serialized output.
    /// If `false` (default), fields with default values will be omitted from the serialized output.
    public var preserveProto3Defaults: Bool = false
    
    /// Maximum nesting depth allowed for nested messages.
    ///
    /// This helps prevent stack overflow errors when dealing with deeply nested messages.
    /// The default value is 100, as specified in the Protocol Buffer wire format PRD.
    public var maxDepth: Int = 100
    
    /// Whether to validate fields during serialization.
    ///
    /// If `true` (default), field values will be validated against their field descriptors
    /// before serialization. Invalid values will cause serialization to fail.
    /// If `false`, validation will be skipped, which may lead to invalid Protocol Buffer messages.
    public var validateFields: Bool = true
    
    /// Whether to validate UTF-8 strings during serialization.
    ///
    /// If `true` (default), string fields will be validated as proper UTF-8 before serialization.
    /// If `false`, validation will be skipped, which may lead to invalid Protocol Buffer messages.
    public var validateUTF8: Bool = true
    
    /// Whether to use the buffer pool for memory allocation.
    ///
    /// If `true` (default), a buffer pool will be used to reduce memory allocations.
    /// If `false`, memory will be allocated directly without using the buffer pool.
    public var useBufferPool: Bool = true
    
    /// Creates a new `SerializationOptions` instance with default values.
    public init() {}
    
    /// Creates a new `SerializationOptions` instance with specified values.
    ///
    /// - Parameters:
    ///   - skipUnknownFields: Whether to skip unknown fields during serialization.
    ///   - preserveProto3Defaults: Whether to preserve proto3 default values in output.
    ///   - maxDepth: Maximum nesting depth allowed for nested messages.
    ///   - validateFields: Whether to validate fields during serialization.
    ///   - validateUTF8: Whether to validate UTF-8 strings during serialization.
    ///   - useBufferPool: Whether to use the buffer pool for memory allocation.
    public init(
        skipUnknownFields: Bool = false,
        preserveProto3Defaults: Bool = false,
        maxDepth: Int = 100,
        validateFields: Bool = true,
        validateUTF8: Bool = true,
        useBufferPool: Bool = true
    ) {
        self.skipUnknownFields = skipUnknownFields
        self.preserveProto3Defaults = preserveProto3Defaults
        self.maxDepth = maxDepth
        self.validateFields = validateFields
        self.validateUTF8 = validateUTF8
        self.useBufferPool = useBufferPool
    }
}
