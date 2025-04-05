import Foundation

/// A buffer pool for efficient memory reuse during Protocol Buffer serialization and deserialization.
///
/// The `BufferPool` provides a centralized pool of reusable memory buffers to reduce allocations
/// and improve performance during wire format operations. It supports configurable buffer sizes
/// and maintains statistics about pool usage.
///
/// Example:
/// ```swift
/// let pool = BufferPool.shared
/// let buffer = pool.acquire(size: 1024)
/// // Use the buffer...
/// pool.release(buffer)
/// ```
public final class BufferPool {
    /// The shared singleton instance of the buffer pool.
    public static let shared = BufferPool()
    
    /// Configurable buffer sizes
    public static let smallMessageSize = 1024       // 1KB
    public static let mediumMessageSize = 1_048_576 // 1MB
    public static let largeMessageSize = 52_428_800 // 50MB
    
    /// Maximum pool size in bytes
    public static let maxPoolSize = 268_435_456     // 256MB
    
    /// Maximum number of buffers in the pool
    private static let maxBuffers = 100
    
    /// Thread-safe pool access
    private let lock = NSLock()
    
    /// Available buffers organized by size category
    private var smallBuffers: [Buffer] = []
    private var mediumBuffers: [Buffer] = []
    private var largeBuffers: [Buffer] = []
    
    /// Pool statistics
    private var stats = PoolStatistics()
    
    /// Represents a reusable memory buffer
    public class Buffer {
        /// The underlying data storage
        public private(set) var data: UnsafeMutableRawBufferPointer
        
        /// The size of the buffer in bytes
        public var size: Int { data.count }
        
        /// Whether the buffer is currently in use
        public private(set) var isInUse = false
        
        /// Internal counter for tracking buffer usage
        private var useCount = 0
        
        /// Initialize a new buffer with the specified size
        fileprivate init(size: Int) {
            data = UnsafeMutableRawBufferPointer.allocate(byteCount: size, alignment: MemoryLayout<UInt64>.alignment)
            self.isInUse = true
        }
        
        /// Mark this buffer as in use
        fileprivate func markAsInUse() {
            isInUse = true
            useCount += 1
        }
        
        /// Mark this buffer as available
        fileprivate func markAsAvailable() {
            isInUse = false
        }
        
        deinit {
            data.deallocate()
        }
    }
    
    /// Statistics about buffer pool usage
    public struct PoolStatistics {
        /// Total number of buffers created
        public internal(set) var totalBuffersCreated = 0
        
        /// Total number of buffer acquisitions
        public internal(set) var totalAcquisitions = 0
        
        /// Total number of cache hits (reused buffers)
        public internal(set) var cacheHits = 0
        
        /// Current size of the pool in bytes
        public internal(set) var currentPoolSize = 0
        
        /// Peak size of the pool in bytes
        public internal(set) var peakPoolSize = 0
        
        /// Average buffer size
        public var averageBufferSize: Int {
            return totalBuffersCreated > 0 ? currentPoolSize / totalBuffersCreated : 0
        }
        
        /// Cache hit rate (percentage)
        public var cacheHitRate: Double {
            return totalAcquisitions > 0 ? Double(cacheHits) / Double(totalAcquisitions) * 100.0 : 0.0
        }
        
        mutating func bufferCreated(size: Int) {
            totalBuffersCreated += 1
            currentPoolSize += size
            peakPoolSize = max(peakPoolSize, currentPoolSize)
        }
        
        mutating func bufferAcquired(isReused: Bool) {
            totalAcquisitions += 1
            if isReused {
                cacheHits += 1
            }
        }
        
        mutating func updatePoolSize(_ size: Int) {
            currentPoolSize = size
            peakPoolSize = max(peakPoolSize, currentPoolSize)
        }
    }
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Current statistics about pool usage
    public var poolStats: PoolStatistics {
        lock.lock()
        defer { lock.unlock() }
        return stats
    }
    
    /// Acquires a buffer of at least the specified size
    ///
    /// - Parameter size: The minimum required buffer size in bytes
    /// - Returns: A buffer suitable for the requested size
    public func acquire(size: Int) -> Buffer {
        lock.lock()
        defer { lock.unlock() }
        
        // Find the appropriate buffer size category
        let bufferSize: Int
        if size <= BufferPool.smallMessageSize {
            bufferSize = BufferPool.smallMessageSize
        } else if size <= BufferPool.mediumMessageSize {
            bufferSize = BufferPool.mediumMessageSize
        } else if size <= BufferPool.largeMessageSize {
            bufferSize = BufferPool.largeMessageSize
        } else {
            // For very large buffers, allocate exactly what's needed
            bufferSize = size
        }
        
        // Try to find an available buffer in the appropriate category
        if bufferSize == BufferPool.smallMessageSize, let buffer = findAvailableBuffer(in: &smallBuffers) {
            stats.bufferAcquired(isReused: true)
            buffer.markAsInUse()
            return buffer
        } else if bufferSize == BufferPool.mediumMessageSize, let buffer = findAvailableBuffer(in: &mediumBuffers) {
            stats.bufferAcquired(isReused: true)
            buffer.markAsInUse()
            return buffer
        } else if bufferSize == BufferPool.largeMessageSize, let buffer = findAvailableBuffer(in: &largeBuffers) {
            stats.bufferAcquired(isReused: true)
            buffer.markAsInUse()
            return buffer
        }
        
        // No available buffer found, create a new one
        let buffer = Buffer(size: bufferSize)
        stats.bufferCreated(size: bufferSize)
        stats.bufferAcquired(isReused: false)
        
        // Add the buffer to the appropriate category
        if bufferSize == BufferPool.smallMessageSize {
            smallBuffers.append(buffer)
        } else if bufferSize == BufferPool.mediumMessageSize {
            mediumBuffers.append(buffer)
        } else if bufferSize == BufferPool.largeMessageSize {
            largeBuffers.append(buffer)
        }
        
        return buffer
    }
    
    /// Releases a buffer back to the pool for reuse
    ///
    /// - Parameter buffer: The buffer to release
    public func release(_ buffer: Buffer) {
        lock.lock()
        defer { lock.unlock() }
        
        buffer.markAsAvailable()
        
        // Prune excess buffers if we've exceeded our maximum pool size
        pruneExcessBuffers()
    }
    
    /// Finds an available buffer in the specified category
    private func findAvailableBuffer(in buffers: inout [Buffer]) -> Buffer? {
        for buffer in buffers where !buffer.isInUse {
            return buffer
        }
        return nil
    }
    
    /// Prunes excess buffers to stay within our maximum pool size
    private func pruneExcessBuffers() {
        // Check if we need to prune any buffers
        var totalSize = calculateTotalPoolSize()
        
        if totalSize <= BufferPool.maxPoolSize && 
           smallBuffers.count + mediumBuffers.count + largeBuffers.count <= BufferPool.maxBuffers {
            return
        }
        
        // Start by pruning large buffers
        while !largeBuffers.isEmpty && (totalSize > BufferPool.maxPoolSize || largeBuffers.count > BufferPool.maxBuffers / 3) {
            if let index = largeBuffers.firstIndex(where: { !$0.isInUse }) {
                totalSize -= largeBuffers[index].size
                largeBuffers.remove(at: index)
            } else {
                break
            }
        }
        
        // Then medium buffers
        while !mediumBuffers.isEmpty && (totalSize > BufferPool.maxPoolSize || mediumBuffers.count > BufferPool.maxBuffers / 3) {
            if let index = mediumBuffers.firstIndex(where: { !$0.isInUse }) {
                totalSize -= mediumBuffers[index].size
                mediumBuffers.remove(at: index)
            } else {
                break
            }
        }
        
        // Finally small buffers
        while !smallBuffers.isEmpty && (totalSize > BufferPool.maxPoolSize || smallBuffers.count > BufferPool.maxBuffers / 3) {
            if let index = smallBuffers.firstIndex(where: { !$0.isInUse }) {
                totalSize -= smallBuffers[index].size
                smallBuffers.remove(at: index)
            } else {
                break
            }
        }
        
        // Update the current pool size
        stats.updatePoolSize(totalSize)
    }
    
    /// Calculates the total size of all buffers in the pool
    private func calculateTotalPoolSize() -> Int {
        return smallBuffers.reduce(0) { $0 + $1.size } +
               mediumBuffers.reduce(0) { $0 + $1.size } +
               largeBuffers.reduce(0) { $0 + $1.size }
    }
    
    /// Clears all unused buffers from the pool
    public func clearUnusedBuffers() {
        lock.lock()
        defer { lock.unlock() }
        
        smallBuffers = smallBuffers.filter { $0.isInUse }
        mediumBuffers = mediumBuffers.filter { $0.isInUse }
        largeBuffers = largeBuffers.filter { $0.isInUse }
        
        // Update the current pool size
        let totalSize = calculateTotalPoolSize()
        stats.updatePoolSize(totalSize)
    }
}
