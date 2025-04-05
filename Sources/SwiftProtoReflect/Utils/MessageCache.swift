import Foundation
import SwiftProtobuf

/// A cache for storing and retrieving Protocol Buffer messages.
///
/// The `MessageCache` provides a mechanism for caching SwiftProtobuf messages based on their descriptors,
/// improving performance for repeated operations on the same message types.
///
/// Example:
/// ```swift
/// let cache = MessageCache.shared
/// cache.cache(personMessage, for: personDescriptor)
/// let cachedMessage = cache.getCached(for: personDescriptor)
/// ```
public final class MessageCache {
    /// The shared singleton instance of the message cache.
    public static let shared = MessageCache()
    
    /// Maximum number of entries in the cache
    private static let maxCacheSize = 10_000
    
    /// Thread-safe cache access
    private let lock = NSLock()
    
    /// Storage for cached messages, using descriptor's full name as the key
    private var cache: [String: CacheEntry] = [:]
    
    /// Timestamp for tracking least recently used entries
    private var timestamp: UInt64 = 0
    
    /// Entry in the message cache
    private struct CacheEntry {
        /// The cached message
        let message: SwiftProtobuf.Message
        
        /// Last accessed timestamp for LRU tracking
        var lastAccessed: UInt64
        
        /// Create a new cache entry
        init(message: SwiftProtobuf.Message, timestamp: UInt64) {
            self.message = message
            self.lastAccessed = timestamp
        }
    }
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Caches a SwiftProtobuf message for a specific descriptor.
    ///
    /// - Parameters:
    ///   - message: The SwiftProtobuf message to cache.
    ///   - descriptor: The descriptor identifying the message type.
    public func cache(_ message: SwiftProtobuf.Message, for descriptor: ProtoMessageDescriptor) {
        lock.lock()
        defer { lock.unlock() }
        
        // Get the key for the descriptor
        let key = cacheKey(for: descriptor)
        
        // Increment timestamp for LRU tracking
        timestamp += 1
        
        // Add the entry to the cache
        cache[key] = CacheEntry(message: message, timestamp: timestamp)
        
        // Prune cache if it exceeds the maximum size
        pruneCache()
    }
    
    /// Retrieves a cached SwiftProtobuf message for a specific descriptor.
    ///
    /// - Parameter descriptor: The descriptor identifying the message type.
    /// - Returns: The cached message, or nil if not found.
    public func getCached(for descriptor: ProtoMessageDescriptor) -> SwiftProtobuf.Message? {
        lock.lock()
        defer { lock.unlock() }
        
        // Get the key for the descriptor
        let key = cacheKey(for: descriptor)
        
        // Check if we have a cached entry
        guard var entry = cache[key] else {
            return nil
        }
        
        // Update the last accessed timestamp
        timestamp += 1
        entry.lastAccessed = timestamp
        cache[key] = entry
        
        return entry.message
    }
    
    /// Clears all entries from the cache.
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        
        cache.removeAll()
        timestamp = 0
    }
    
    /// Removes a specific entry from the cache.
    ///
    /// - Parameter descriptor: The descriptor identifying the message type to remove.
    public func removeEntry(for descriptor: ProtoMessageDescriptor) {
        lock.lock()
        defer { lock.unlock() }
        
        let key = cacheKey(for: descriptor)
        cache.removeValue(forKey: key)
    }
    
    /// Generates a cache key for a descriptor.
    private func cacheKey(for descriptor: ProtoMessageDescriptor) -> String {
        return descriptor.fullName
    }
    
    /// Prunes the cache if it exceeds the maximum size.
    private func pruneCache() {
        guard cache.count > MessageCache.maxCacheSize else {
            return
        }
        
        // Sort entries by last accessed time (oldest first)
        let sortedEntries = cache.sorted { $0.value.lastAccessed < $1.value.lastAccessed }
        
        // Remove oldest entries until we're back under the limit
        let entriesToRemove = sortedEntries.prefix(cache.count - MessageCache.maxCacheSize)
        for entry in entriesToRemove {
            cache.removeValue(forKey: entry.key)
        }
    }
}
