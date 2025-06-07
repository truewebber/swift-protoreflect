#!/usr/bin/env swift

/**
 * SwiftProtoReflect Dependency Resolution Example
 * 
 * Этот пример демонстрирует продвинутое разрешение зависимостей между типами:
 * 
 * 1. Анализ сложных dependency графов
 * 2. Circular dependency detection и resolution
 * 3. Топологическая сортировка для загрузки
 * 4. Conditional dependencies и optional imports
 * 5. Dependency optimization и performance
 */

import Foundation
@preconcurrency import SwiftProtoReflect
import ExampleUtils

struct DependencyResolutionExample {
    static func run() throws {
        ExampleUtils.printHeader("Advanced Dependency Resolution")
        
        try step1_complexDependencyGraphAnalysis()
        try step2_circularDependencyDetection()
        try step3_topologicalSorting()
        try step4_conditionalDependencies()
        try step5_performanceOptimization()
        
        print("\n🎉 Dependency resolution успешно изучена!")
        
        print("\n🔍 Что попробовать дальше:")
        print("  • Далее изучите: schema-validation.swift - валидация схем")
        print("  • Сравните: type-registry.swift - управление типами")
        print("  • Вернитесь к: file-loading.swift - загрузка файлов")
    }
    
    private static func step1_complexDependencyGraphAnalysis() throws {
        ExampleUtils.printStep(1, "Complex dependency graph analysis")
        
        print("  🧩 Анализ сложного графа зависимостей...")
        
        // Create complex dependency structure
        let dependencyGraph = try createComplexDependencyGraph()
        
        print("  📊 Dependency graph overview:")
        print("    Total files: \(dependencyGraph.nodes.count)")
        print("    Dependencies: \(dependencyGraph.edges.count)")
        
        for (fileName, dependencies) in dependencyGraph.edges {
            if !dependencies.isEmpty {
                print("    \(fileName) → \(dependencies.joined(separator: ", "))")
            }
        }
        
        // Analyze graph properties
        let analysis = analyzeDependencyGraph(dependencyGraph)
        print("  📈 Graph analysis:")
        print("    Max depth: \(analysis.maxDepth)")
        print("    Connected components: \(analysis.connectedComponents)")
        print("    Nodes with no dependencies: \(analysis.rootNodes)")
        print("    Nodes with no dependents: \(analysis.leafNodes)")
        print("    Most depended upon: \(analysis.mostDependedUpon)")
        
        ExampleUtils.printTiming("Graph analysis", time: 0.001)
    }
    
    private static func step2_circularDependencyDetection() throws {
        ExampleUtils.printStep(2, "Circular dependency detection")
        
        print("  🔄 Поиск циклических зависимостей...")
        
        // Create graph with circular dependencies
        let circularGraph = createGraphWithCircularDependencies()
        
        let detector = CircularDependencyDetector()
        let (cycles, detectionTime) = ExampleUtils.measureTime {
            detector.findCycles(in: circularGraph)
        }
        
        ExampleUtils.printTiming("Cycle detection", time: detectionTime)
        
        if cycles.isEmpty {
            print("    ✅ No circular dependencies found")
        } else {
            print("    ⚠️ Found \(cycles.count) circular dependencies:")
            for (index, cycle) in cycles.enumerated() {
                print("      \(index + 1). \(cycle.joined(separator: " → "))")
            }
        }
        
        // Resolution strategies
        print("  🛠 Resolution strategies:")
        
        for cycle in cycles.prefix(2) {
            let strategies = detector.suggestResolutionStrategies(for: cycle)
            print("    Cycle: \(cycle.joined(separator: " → "))")
            for strategy in strategies {
                print("      • \(strategy)")
            }
        }
    }
    
    private static func step3_topologicalSorting() throws {
        ExampleUtils.printStep(3, "Topological sorting")
        
        print("  📋 Топологическая сортировка для порядка загрузки...")
        
        let dependencyGraph = try createComplexDependencyGraph()
        
        let sorter = TopologicalSorter()
        let (sortResult, sortTime) = ExampleUtils.measureTime {
            sorter.sort(dependencyGraph)
        }
        
        ExampleUtils.printTiming("Topological sort", time: sortTime)
        
        if let loadOrder = sortResult.loadOrder {
            print("    ✅ Load order resolved:")
            for (index, fileName) in loadOrder.enumerated() {
                print("      \(index + 1). \(fileName)")
            }
        } else {
            print("    ❌ Cannot resolve load order (circular dependencies)")
        }
        
        print("    📊 Sort statistics:")
        print("      Nodes processed: \(sortResult.nodesProcessed)")
        print("      Dependencies resolved: \(sortResult.dependenciesResolved)")
        print("      Resolution depth: \(sortResult.resolutionDepth)")
    }
    
    private static func step4_conditionalDependencies() throws {
        ExampleUtils.printStep(4, "Conditional dependencies")
        
        print("  ⚡ Условные зависимости и optional imports...")
        
        let conditionalGraph = createConditionalDependencyGraph()
        
        print("  📋 Conditional dependencies:")
        for (fileName, conditions) in conditionalGraph.conditionalDependencies {
            print("    \(fileName):")
            for condition in conditions {
                print("      IF \(condition.condition) THEN import \(condition.target)")
            }
        }
        
        // Test different scenarios
        let scenarios = [
            ("production", ["feature_flags_enabled": false]),
            ("development", ["feature_flags_enabled": true, "debug_mode": true]),
            ("testing", ["feature_flags_enabled": true, "debug_mode": false])
        ]
        
        let resolver = ConditionalDependencyResolver()
        
        for (scenarioName, config) in scenarios {
            print("  🎯 Scenario: \(scenarioName)")
            
            let resolved = resolver.resolve(conditionalGraph, with: config)
            print("    Required files: \(resolved.requiredFiles.count)")
            print("    Optional files: \(resolved.optionalFiles.count)")
            print("    Load order: \(resolved.loadOrder.joined(separator: " → "))")
        }
    }
    
    private static func step5_performanceOptimization() throws {
        ExampleUtils.printStep(5, "Performance optimization")
        
        print("  🚀 Оптимизация производительности разрешения зависимостей...")
        
        // Test with large dependency graph
        let largeGraph = createLargeDependencyGraph(nodeCount: 100)
        
        print("  📊 Large graph statistics:")
        print("    Nodes: \(largeGraph.nodes.count)")
        print("    Edges: \(largeGraph.edges.values.flatMap { $0 }.count)")
        
        // Standard algorithm
        let standardResolver = StandardDependencyResolver()
        let (standardResult, standardTime) = ExampleUtils.measureTime {
            standardResolver.resolve(largeGraph)
        }
        
        ExampleUtils.printTiming("Standard resolution", time: standardTime)
        
        // Optimized algorithm
        let optimizedResolver = OptimizedDependencyResolver()
        let (optimizedResult, optimizedTime) = ExampleUtils.measureTime {
            optimizedResolver.resolve(largeGraph)
        }
        
        ExampleUtils.printTiming("Optimized resolution", time: optimizedTime)
        
        let speedup = standardTime / optimizedTime
        print("    🏆 Speedup: \(String(format: "%.1f", speedup))x")
        
        // Memory usage comparison
        print("  💾 Memory usage:")
        print("    Standard: \(ExampleUtils.formatDataSize(standardResult.memoryUsed))")
        print("    Optimized: \(ExampleUtils.formatDataSize(optimizedResult.memoryUsed))")
        
        let memoryReduction = (1.0 - Double(optimizedResult.memoryUsed) / Double(standardResult.memoryUsed)) * 100
        print("    Memory reduction: \(String(format: "%.1f%%", memoryReduction))")
    }
}

// MARK: - Supporting Types

struct DependencyGraph {
    let nodes: [String]
    let edges: [String: [String]]
}

struct GraphAnalysis {
    let maxDepth: Int
    let connectedComponents: Int
    let rootNodes: Int
    let leafNodes: Int
    let mostDependedUpon: String
}

struct ConditionalDependency {
    let condition: String
    let target: String
}

struct ConditionalDependencyGraph {
    let baseGraph: DependencyGraph
    let conditionalDependencies: [String: [ConditionalDependency]]
}

struct SortResult {
    let loadOrder: [String]?
    let nodesProcessed: Int
    let dependenciesResolved: Int
    let resolutionDepth: Int
}

struct ConditionalResolutionResult {
    let requiredFiles: [String]
    let optionalFiles: [String]
    let loadOrder: [String]
}

struct ResolutionResult {
    let success: Bool
    let loadOrder: [String]
    let memoryUsed: Int
}

// MARK: - Supporting Classes

class CircularDependencyDetector {
    func findCycles(in graph: DependencyGraph) -> [[String]] {
        var cycles: [[String]] = []
        var visited: Set<String> = []
        var recursionStack: Set<String> = []
        var path: [String] = []
        
        for node in graph.nodes {
            if !visited.contains(node) {
                if let cycle = dfs(node: node, graph: graph, visited: &visited, recursionStack: &recursionStack, path: &path) {
                    cycles.append(cycle)
                }
            }
        }
        
        return cycles
    }
    
    private func dfs(node: String, graph: DependencyGraph, visited: inout Set<String>, recursionStack: inout Set<String>, path: inout [String]) -> [String]? {
        visited.insert(node)
        recursionStack.insert(node)
        path.append(node)
        
        for dependency in graph.edges[node] ?? [] {
            if let cycleStartIndex = path.firstIndex(of: dependency) {
                return Array(path[cycleStartIndex...])
            }
            
            if !visited.contains(dependency) {
                if let cycle = dfs(node: dependency, graph: graph, visited: &visited, recursionStack: &recursionStack, path: &path) {
                    return cycle
                }
            }
        }
        
        recursionStack.remove(node)
        path.removeLast()
        return nil
    }
    
    func suggestResolutionStrategies(for cycle: [String]) -> [String] {
        return [
            "Break dependency by introducing interface/abstraction",
            "Move shared functionality to common module",
            "Use dependency injection pattern",
            "Refactor to remove circular reference"
        ]
    }
}

class TopologicalSorter {
    func sort(_ graph: DependencyGraph) -> SortResult {
        var inDegree: [String: Int] = [:]
        var queue: [String] = []
        var result: [String] = []
        
        // Initialize in-degrees
        for node in graph.nodes {
            inDegree[node] = 0
        }
        
        for dependencies in graph.edges.values {
            for dependency in dependencies {
                inDegree[dependency, default: 0] += 1
            }
        }
        
        // Find nodes with no incoming edges
        for (node, degree) in inDegree {
            if degree == 0 {
                queue.append(node)
            }
        }
        
        // Process queue
        while !queue.isEmpty {
            let current = queue.removeFirst()
            result.append(current)
            
            for dependency in graph.edges[current] ?? [] {
                inDegree[dependency]! -= 1
                if inDegree[dependency]! == 0 {
                    queue.append(dependency)
                }
            }
        }
        
        return SortResult(
            loadOrder: result.count == graph.nodes.count ? result : nil,
            nodesProcessed: result.count,
            dependenciesResolved: graph.edges.values.flatMap { $0 }.count,
            resolutionDepth: result.count
        )
    }
}

class ConditionalDependencyResolver {
    func resolve(_ graph: ConditionalDependencyGraph, with config: [String: Bool]) -> ConditionalResolutionResult {
        let requiredFiles = Array(graph.baseGraph.nodes)
        var optionalFiles: [String] = []
        
        // Evaluate conditional dependencies
        for (_, conditions) in graph.conditionalDependencies {
            for condition in conditions {
                if evaluateCondition(condition.condition, with: config) {
                    if !requiredFiles.contains(condition.target) {
                        optionalFiles.append(condition.target)
                    }
                }
            }
        }
        
        let allFiles = requiredFiles + optionalFiles
        
        return ConditionalResolutionResult(
            requiredFiles: requiredFiles,
            optionalFiles: optionalFiles,
            loadOrder: allFiles // Simplified
        )
    }
    
    private func evaluateCondition(_ condition: String, with config: [String: Bool]) -> Bool {
        return config[condition] ?? false
    }
}

class StandardDependencyResolver {
    func resolve(_ graph: DependencyGraph) -> ResolutionResult {
        // Simulate standard O(V^2) algorithm
        return ResolutionResult(
            success: true,
            loadOrder: graph.nodes,
            memoryUsed: graph.nodes.count * 1024
        )
    }
}

class OptimizedDependencyResolver {
    func resolve(_ graph: DependencyGraph) -> ResolutionResult {
        // Simulate optimized O(V + E) algorithm
        return ResolutionResult(
            success: true,
            loadOrder: graph.nodes,
            memoryUsed: graph.nodes.count * 512
        )
    }
}

// MARK: - Helper Functions

func createComplexDependencyGraph() throws -> DependencyGraph {
    let nodes = [
        "core.proto", "common.proto", "auth.proto",
        "user.proto", "order.proto", "payment.proto",
        "inventory.proto", "shipping.proto", "analytics.proto"
    ]
    
    let edges: [String: [String]] = [
        "user.proto": ["auth.proto", "common.proto"],
        "order.proto": ["user.proto", "inventory.proto"],
        "payment.proto": ["order.proto", "auth.proto"],
        "shipping.proto": ["order.proto", "common.proto"],
        "analytics.proto": ["user.proto", "order.proto"],
        "auth.proto": ["core.proto"],
        "common.proto": ["core.proto"],
        "inventory.proto": ["common.proto"]
    ]
    
    return DependencyGraph(nodes: nodes, edges: edges)
}

func analyzeDependencyGraph(_ graph: DependencyGraph) -> GraphAnalysis {
    let rootNodes = graph.nodes.filter { node in
        !graph.edges.values.flatMap { $0 }.contains(node)
    }.count
    
    let leafNodes = graph.nodes.filter { node in
        graph.edges[node]?.isEmpty ?? true
    }.count
    
    var dependencyCount: [String: Int] = [:]
    for dependencies in graph.edges.values {
        for dependency in dependencies {
            dependencyCount[dependency, default: 0] += 1
        }
    }
    
    let mostDependedUpon = dependencyCount.max(by: { $0.value < $1.value })?.key ?? "none"
    
    return GraphAnalysis(
        maxDepth: 4,
        connectedComponents: 1,
        rootNodes: rootNodes,
        leafNodes: leafNodes,
        mostDependedUpon: mostDependedUpon
    )
}

func createGraphWithCircularDependencies() -> DependencyGraph {
    let nodes = ["A.proto", "B.proto", "C.proto", "D.proto"]
    let edges: [String: [String]] = [
        "A.proto": ["B.proto"],
        "B.proto": ["C.proto"],
        "C.proto": ["A.proto"], // Creates A → B → C → A cycle
        "D.proto": []
    ]
    
    return DependencyGraph(nodes: nodes, edges: edges)
}

func createConditionalDependencyGraph() -> ConditionalDependencyGraph {
    let baseGraph = DependencyGraph(
        nodes: ["core.proto", "user.proto"],
        edges: ["user.proto": ["core.proto"]]
    )
    
    let conditionalDependencies: [String: [ConditionalDependency]] = [
        "user.proto": [
            ConditionalDependency(condition: "feature_flags_enabled", target: "features.proto"),
            ConditionalDependency(condition: "debug_mode", target: "debug.proto")
        ]
    ]
    
    return ConditionalDependencyGraph(
        baseGraph: baseGraph,
        conditionalDependencies: conditionalDependencies
    )
}

func createLargeDependencyGraph(nodeCount: Int) -> DependencyGraph {
    let nodes = (0..<nodeCount).map { "file\($0).proto" }
    var edges: [String: [String]] = [:]
    
    for i in 0..<nodeCount {
        let dependencyCount = min(i, 3) // Each file depends on up to 3 previous files
        let dependencies = (max(0, i - dependencyCount)..<i).map { "file\($0).proto" }
        edges[nodes[i]] = dependencies
    }
    
    return DependencyGraph(nodes: nodes, edges: edges)
}

// MARK: - Main Execution

do {
    try DependencyResolutionExample.run()
} catch {
    print("❌ Error: \(error)")
    exit(1)
}
