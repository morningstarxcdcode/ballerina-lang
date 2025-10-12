# Debugging Visualization: Type Resolution Process Mapping

## Overview

This module provides comprehensive debugging visualization tools to map the type resolution process and identify null reference points in anonymous type processing, enabling developers to understand and debug complex type hierarchies.

## Type Resolution Flow Visualizer

### TypeResolutionVisualizer.java

```java
package io.ballerina.compiler.api.impl.debug;

import io.ballerina.compiler.api.symbols.TypeSymbol;
import guru.nidi.graphviz.engine.Format;
import guru.nidi.graphviz.engine.Graphviz;
import guru.nidi.graphviz.model.MutableGraph;
import guru.nidi.graphviz.model.MutableNode;

import java.io.File;
import java.io.IOException;
import java.util.Map;
import java.util.HashMap;
import java.util.Set;
import java.util.HashSet;
import java.util.List;
import java.util.ArrayList;

import static guru.nidi.graphviz.model.Factory.*;

/**
 * Visualizes the type resolution process as a graph.
 */
public class TypeResolutionVisualizer {
    private final MutableGraph graph;
    private final Map<String, MutableNode> nodeMap;
    private final Set<String> edges;
    private int nodeCounter;

    public TypeResolutionVisualizer() {
        this.graph = mutGraph("TypeResolution").setDirected(true);
        this.nodeMap = new HashMap<>();
        this.edges = new HashSet<>();
        this.nodeCounter = 0;
    }

    public void addTypeResolutionStep(String stepId, String operation, BType inputType,
                                    BType outputType, String status) {
        String inputNodeId = getOrCreateNode(inputType, "input");
        String operationNodeId = createOperationNode(stepId, operation, status);
        String outputNodeId = getOrCreateNode(outputType, "output");

        // Add edges
        addEdge(inputNodeId, operationNodeId, "input");
        addEdge(operationNodeId, outputNodeId, "output");

        // Color code based on status
        MutableNode opNode = nodeMap.get(operationNodeId);
        switch (status) {
            case "SUCCESS":
                opNode.add("color", "green");
                break;
            case "NULL_SYMBOL":
                opNode.add("color", "red");
                break;
            case "SYNTHETIC_CREATED":
                opNode.add("color", "blue");
                break;
            case "FAILED":
                opNode.add("color", "orange");
                break;
        }
    }

    public void addTypeHierarchy(BType rootType, String context) {
        MutableNode rootNode = createTypeNode(rootType, context);
        graph.add(rootNode);

        addTypeHierarchyRecursive(rootNode, rootType, new HashSet<>());
    }

    private void addTypeHierarchyRecursive(MutableNode parentNode, BType type, Set<String> visited) {
        String typeId = getTypeId(type);
        if (visited.contains(typeId) || type == null) {
            return;
        }
        visited.add(typeId);

        switch (type.getKind()) {
            case RECORD:
                addRecordHierarchy(parentNode, (BRecordType) type, visited);
                break;
            case OBJECT:
                addObjectHierarchy(parentNode, (BObjectType) type, visited);
                break;
            case UNION:
                addUnionHierarchy(parentNode, (BUnionType) type, visited);
                break;
            case ARRAY:
                addArrayHierarchy(parentNode, (BArrayType) type, visited);
                break;
            case TUPLE:
                addTupleHierarchy(parentNode, (BTupleType) type, visited);
                break;
            case MAP:
                addMapHierarchy(parentNode, (BMapType) type, visited);
                break;
            default:
                // Leaf types don't need further expansion
                break;
        }
    }

    private void addRecordHierarchy(MutableNode parentNode, BRecordType recordType, Set<String> visited) {
        if (recordType.fields != null) {
            for (BField field : recordType.fields) {
                if (field != null && field.type != null) {
                    MutableNode fieldNode = createFieldNode(field);
                    parentNode.addLink(fieldNode);
                    addTypeHierarchyRecursive(fieldNode, field.type, visited);
                }
            }
        }

        if (recordType.restFieldType != null) {
            MutableNode restNode = createTypeNode(recordType.restFieldType, "rest");
            restNode.add("shape", "diamond");
            parentNode.addLink(restNode);
            addTypeHierarchyRecursive(restNode, recordType.restFieldType, visited);
        }
    }

    private void addUnionHierarchy(MutableNode parentNode, BUnionType unionType, Set<String> visited) {
        if (unionType.getMemberTypes() != null) {
            for (BType memberType : unionType.getMemberTypes()) {
                if (memberType != null) {
                    MutableNode memberNode = createTypeNode(memberType, "member");
                    parentNode.addLink(memberNode);
                    addTypeHierarchyRecursive(memberNode, memberType, visited);
                }
            }
        }
    }

    private void addArrayHierarchy(MutableNode parentNode, BArrayType arrayType, Set<String> visited) {
        if (arrayType.getElementType() != null) {
            MutableNode elementNode = createTypeNode(arrayType.getElementType(), "element");
            parentNode.addLink(elementNode);
            addTypeHierarchyRecursive(elementNode, arrayType.getElementType(), visited);
        }
    }

    private String getOrCreateNode(BType type, String suffix) {
        String typeId = getTypeId(type) + "_" + suffix;
        return nodeMap.computeIfAbsent(typeId, id -> {
            MutableNode node = mutNode(id);
            if (type != null) {
                node.add("label", type.getKind().toString());
                if (type.tsymbol == null) {
                    node.add("color", "red").add("style", "filled");
                } else if (type.tsymbol.origin == SymbolOrigin.VIRTUAL) {
                    node.add("color", "blue").add("style", "filled");
                }
            } else {
                node.add("label", "NULL").add("color", "red").add("style", "filled");
            }
            graph.add(node);
            return id;
        });
    }

    private String createOperationNode(String stepId, String operation, String status) {
        String nodeId = "op_" + stepId + "_" + nodeCounter++;
        MutableNode node = mutNode(nodeId)
            .add("label", operation + "\n[" + status + "]")
            .add("shape", "box");
        nodeMap.put(nodeId, node);
        graph.add(node);
        return nodeId;
    }

    private MutableNode createTypeNode(BType type, String context) {
        String nodeId = getTypeId(type) + "_" + context + "_" + nodeCounter++;
        MutableNode node = mutNode(nodeId);

        if (type != null) {
            node.add("label", type.getKind() + "\n(" + context + ")");
            if (type.tsymbol == null) {
                node.add("color", "red").add("style", "filled");
            }
        } else {
            node.add("label", "NULL\n(" + context + ")").add("color", "red").add("style", "filled");
        }

        return node;
    }

    private MutableNode createFieldNode(BField field) {
        String nodeId = "field_" + field.name + "_" + nodeCounter++;
        return mutNode(nodeId)
            .add("label", field.name + ": " + field.type.getKind())
            .add("shape", "ellipse");
    }

    private void addEdge(String fromId, String toId, String label) {
        String edgeKey = fromId + "->" + toId;
        if (!edges.contains(edgeKey)) {
            MutableNode fromNode = nodeMap.get(fromId);
            MutableNode toNode = nodeMap.get(toId);
            if (fromNode != null && toNode != null) {
                fromNode.addLink(to(toNode).with("label", label));
                edges.add(edgeKey);
            }
        }
    }

    private String getTypeId(BType type) {
        if (type == null) return "null";
        return type.getClass().getSimpleName() + "_" +
               Integer.toHexString(System.identityHashCode(type));
    }

    public void saveAsPng(String filename) throws IOException {
        Graphviz.fromGraph(graph).render(Format.PNG).toFile(new File(filename));
    }

    public void saveAsSvg(String filename) throws IOException {
        Graphviz.fromGraph(graph).render(Format.SVG).toFile(new File(filename));
    }

    public String toDotString() {
        return Graphviz.fromGraph(graph).render(Format.DOT).toString();
    }
}
```

## Null Reference Tracker

### NullReferenceTracker.java

```java
package io.ballerina.compiler.api.impl.debug;

import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.util.Set;
import java.util.HashSet;

/**
 * Tracks null references throughout the type resolution process.
 */
public class NullReferenceTracker {
    private final List<NullReferenceEvent> events;
    private final Map<String, Integer> nullReferenceCounts;
    private final Set<String> nullPaths;

    public NullReferenceTracker() {
        this.events = new ArrayList<>();
        this.nullReferenceCounts = new HashMap<>();
        this.nullPaths = new HashSet<>();
    }

    public void trackNullReference(String location, String field, Object expectedType, String context) {
        NullReferenceEvent event = new NullReferenceEvent(location, field, expectedType, context);
        events.add(event);

        String key = location + "." + field;
        nullReferenceCounts.put(key, nullReferenceCounts.getOrDefault(key, 0) + 1);
        nullPaths.add(context);
    }

    public void trackTypeSymbolNull(BType bType, String context) {
        trackNullReference("BType.tsymbol", "tsymbol", "BSymbol", context);
    }

    public void trackFieldNull(BType parentType, String fieldName, String context) {
        trackNullReference(parentType.getKind() + ".fields", fieldName, "BField", context);
    }

    public void trackMemberTypeNull(BType unionType, int index, String context) {
        trackNullReference("BUnionType.memberTypes[" + index + "]", "memberType", "BType", context);
    }

    public List<NullReferenceEvent> getEvents() {
        return new ArrayList<>(events);
    }

    public Map<String, Integer> getNullReferenceCounts() {
        return new HashMap<>(nullReferenceCounts);
    }

    public Set<String> getNullPaths() {
        return new HashSet<>(nullPaths);
    }

    public void generateNullReferenceReport() {
        System.out.println("=== Null Reference Report ===");
        System.out.println("Total null references: " + events.size());
        System.out.println();

        System.out.println("Null reference counts by location:");
        nullReferenceCounts.entrySet().stream()
            .sorted(Map.Entry.<String, Integer>comparingByValue().reversed())
            .forEach(entry -> System.out.println("  " + entry.getKey() + ": " + entry.getValue()));

        System.out.println();
        System.out.println("Null reference paths:");
        nullPaths.forEach(path -> System.out.println("  " + path));

        System.out.println();
        System.out.println("Recent null reference events:");
        events.stream()
            .skip(Math.max(0, events.size() - 10))
            .forEach(event -> System.out.println("  " + event));
    }

    public static class NullReferenceEvent {
        private final long timestamp;
        private final String location;
        private final String field;
        private final Object expectedType;
        private final String context;

        public NullReferenceEvent(String location, String field, Object expectedType, String context) {
            this.timestamp = System.currentTimeMillis();
            this.location = location;
            this.field = field;
            this.expectedType = expectedType;
            this.context = context;
        }

        @Override
        public String toString() {
            return String.format("[%tT] %s.%s (expected %s) in %s",
                               timestamp, location, field, expectedType, context);
        }
    }
}
```

## Interactive Debug Console

### TypeDebugConsole.java

```java
package io.ballerina.compiler.api.impl.debug;

import java.util.Scanner;
import java.util.Map;
import java.util.HashMap;
import java.util.function.Function;

/**
 * Interactive console for debugging type resolution issues.
 */
public class TypeDebugConsole {
    private final Scanner scanner;
    private final Map<String, Function<String[], String>> commands;
    private final TypeResolutionVisualizer visualizer;
    private final NullReferenceTracker nullTracker;

    public TypeDebugConsole(TypeResolutionVisualizer visualizer, NullReferenceTracker nullTracker) {
        this.scanner = new Scanner(System.in);
        this.visualizer = visualizer;
        this.nullTracker = nullTracker;
        this.commands = new HashMap<>();
        initializeCommands();
    }

    private void initializeCommands() {
        commands.put("visualize", this::handleVisualize);
        commands.put("nulls", this::handleNulls);
        commands.put("trace", this::handleTrace);
        commands.put("hierarchy", this::handleHierarchy);
        commands.put("help", this::handleHelp);
        commands.put("quit", args -> "Exiting debug console...");
    }

    public void start() {
        System.out.println("=== Ballerina Type Debug Console ===");
        System.out.println("Type 'help' for available commands");

        while (true) {
            System.out.print("debug> ");
            String line = scanner.nextLine().trim();
            if (line.isEmpty()) continue;

            String[] parts = line.split("\\s+", 2);
            String command = parts[0];
            String[] args = parts.length > 1 ? parts[1].split("\\s+") : new String[0];

            Function<String[], String> handler = commands.get(command);
            if (handler != null) {
                String result = handler.apply(args);
                System.out.println(result);
                if ("quit".equals(command)) break;
            } else {
                System.out.println("Unknown command: " + command);
            }
        }
    }

    private String handleVisualize(String[] args) {
        if (args.length < 1) {
            return "Usage: visualize <filename>";
        }

        String filename = args[0];
        try {
            if (filename.endsWith(".png")) {
                visualizer.saveAsPng(filename);
            } else if (filename.endsWith(".svg")) {
                visualizer.saveAsSvg(filename);
            } else {
                return "Unsupported format. Use .png or .svg";
            }
            return "Visualization saved to " + filename;
        } catch (Exception e) {
            return "Error saving visualization: " + e.getMessage();
        }
    }

    private String handleNulls(String[] args) {
        nullTracker.generateNullReferenceReport();
        return "";
    }

    private String handleTrace(String[] args) {
        if (args.length < 1) {
            return "Usage: trace <type_id>";
        }

        // Implementation would trace a specific type through the resolution process
        return "Tracing type: " + args[0];
    }

    private String handleHierarchy(String[] args) {
        if (args.length < 1) {
            return "Usage: hierarchy <type_kind>";
        }

        // Implementation would show hierarchy for a type kind
        return "Showing hierarchy for: " + args[0];
    }

    private String handleHelp(String[] args) {
        return """
            Available commands:
              visualize <filename>  - Save type resolution graph as PNG/SVG
              nulls                 - Show null reference report
              trace <type_id>       - Trace specific type resolution
              hierarchy <type_kind> - Show type hierarchy
              help                  - Show this help
              quit                  - Exit debug console
            """;
    }
}
```

## Web-Based Debug Dashboard

### TypeDebugDashboard.java

```java
package io.ballerina.compiler.api.impl.debug.web;

import io.javalin.Javalin;
import io.javalin.http.staticfiles.Location;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Web-based dashboard for type debugging visualization.
 */
public class TypeDebugDashboard {
    private final Javalin app;
    private final ConcurrentHashMap<String, TypeResolutionVisualizer> visualizers;
    private final ConcurrentHashMap<String, NullReferenceTracker> trackers;

    public TypeDebugDashboard(int port) {
        this.visualizers = new ConcurrentHashMap<>();
        this.trackers = new ConcurrentHashMap<>();

        this.app = Javalin.create(config -> {
            config.staticFiles.add("/web", Location.CLASSPATH);
        });

        setupRoutes();
    }

    private void setupRoutes() {
        // Main dashboard
        app.get("/", ctx -> {
            ctx.html(generateDashboardHtml());
        });

        // Type resolution graph
        app.get("/graph/{sessionId}", ctx -> {
            String sessionId = ctx.pathParam("sessionId");
            TypeResolutionVisualizer visualizer = visualizers.get(sessionId);

            if (visualizer != null) {
                ctx.contentType("image/svg+xml");
                ctx.result(visualizer.toDotString());
            } else {
                ctx.status(404).result("Session not found");
            }
        });

        // Null reference data
        app.get("/nulls/{sessionId}", ctx -> {
            String sessionId = ctx.pathParam("sessionId");
            NullReferenceTracker tracker = trackers.get(sessionId);

            if (tracker != null) {
                ctx.json(Map.of(
                    "events", tracker.getEvents(),
                    "counts", tracker.getNullReferenceCounts(),
                    "paths", tracker.getNullPaths()
                ));
            } else {
                ctx.status(404).result("Session not found");
            }
        });

        // Start new debug session
        app.post("/session", ctx -> {
            String sessionId = java.util.UUID.randomUUID().toString();
            visualizers.put(sessionId, new TypeResolutionVisualizer());
            trackers.put(sessionId, new NullReferenceTracker());

            ctx.json(Map.of("sessionId", sessionId));
        });
    }

    private String generateDashboardHtml() {
        return """
            <!DOCTYPE html>
            <html>
            <head>
                <title>Ballerina Type Debug Dashboard</title>
                <script src="https://d3js.org/d3.v7.min.js"></script>
                <style>
                    body { font-family: Arial, sans-serif; margin: 20px; }
                    .session { border: 1px solid #ccc; padding: 10px; margin: 10px 0; }
                    .graph { border: 1px solid #000; }
                    .nulls { background-color: #ffebee; padding: 10px; }
                </style>
            </head>
            <body>
                <h1>Ballerina Type Debug Dashboard</h1>

                <button onclick="createSession()">Start New Debug Session</button>

                <div id="sessions"></div>

                <script>
                    let currentSession = null;

                    function createSession() {
                        fetch('/session', { method: 'POST' })
                            .then(r => r.json())
                            .then(data => {
                                currentSession = data.sessionId;
                                loadSession(data.sessionId);
                            });
                    }

                    function loadSession(sessionId) {
                        const container = document.getElementById('sessions');
                        container.innerHTML = `
                            <div class="session">
                                <h3>Session: ${sessionId}</h3>
                                <div class="graph">
                                    <object data="/graph/${sessionId}" type="image/svg+xml" width="800" height="600">
                                        <p>Graph visualization</p>
                                    </object>
                                </div>
                                <div class="nulls" id="nulls-${sessionId}">
                                    <h4>Null References</h4>
                                    <pre id="nulls-content-${sessionId}">Loading...</pre>
                                </div>
                            </div>
                        `;

                        // Load null reference data
                        fetch(`/nulls/${sessionId}`)
                            .then(r => r.json())
                            .then(data => {
                                const content = document.getElementById(`nulls-content-${sessionId}`);
                                content.textContent = JSON.stringify(data, null, 2);
                            });
                    }
                </script>
            </body>
            </html>
            """;
    }

    public void start() {
        app.start();
        System.out.println("Debug dashboard started at http://localhost:" + app.port());
    }

    public void stop() {
        app.stop();
    }

    public String createSession() {
        String sessionId = java.util.UUID.randomUUID().toString();
        visualizers.put(sessionId, new TypeResolutionVisualizer());
        trackers.put(sessionId, new NullReferenceTracker());
        return sessionId;
    }

    public TypeResolutionVisualizer getVisualizer(String sessionId) {
        return visualizers.get(sessionId);
    }

    public NullReferenceTracker getTracker(String sessionId) {
        return trackers.get(sessionId);
    }
}
```

## Integration with Compiler

### Enhanced TypesFactory.java

```java
// Add debug tracking
private static final ThreadLocal<TypeResolutionVisualizer> visualizer =
    new ThreadLocal<TypeResolutionVisualizer>() {
        @Override
        protected TypeResolutionVisualizer initialValue() {
            return new TypeResolutionVisualizer();
        }
    };

private static final ThreadLocal<NullReferenceTracker> nullTracker =
    new ThreadLocal<NullReferenceTracker>() {
        @Override
        protected NullReferenceTracker initialValue() {
            return new NullReferenceTracker();
        }
    };

public TypeSymbol getTypeDescriptor(BType bType, BSymbol tSymbol, boolean rawTypeOnly) {
    String stepId = "getTypeDescriptor_" + System.nanoTime();

    // Track null references
    if (bType == null) {
        nullTracker.get().trackNullReference("TypesFactory.getTypeDescriptor", "bType", "BType", "input");
        return null;
    }

    if (bType.tsymbol == null) {
        nullTracker.get().trackTypeSymbolNull(bType, "TypesFactory.getTypeDescriptor");
    }

    // Visualize resolution step
    visualizer.get().addTypeResolutionStep(stepId, "getTypeDescriptor", bType, null, "STARTED");

    try {
        // ... existing logic ...

        TypeSymbol result = createTypeDescriptor(bType, typeSymbol);
        visualizer.get().addTypeResolutionStep(stepId, "getTypeDescriptor", bType, bType, "SUCCESS");
        return result;

    } catch (Exception e) {
        visualizer.get().addTypeResolutionStep(stepId, "getTypeDescriptor", bType, null, "FAILED");
        throw e;
    }
}
```

## Performance Monitoring

### DebugPerformanceMonitor.java

```java
package io.ballerina.compiler.api.impl.debug;

import java.util.concurrent.atomic.AtomicLong;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Monitors performance of debug operations.
 */
public class DebugPerformanceMonitor {
    private static final Map<String, AtomicLong> operationCounts = new ConcurrentHashMap<>();
    private static final Map<String, AtomicLong> operationTimes = new ConcurrentHashMap<>();

    public static <T> T measure(String operation, Supplier<T> supplier) {
        long start = System.nanoTime();
        try {
            T result = supplier.get();
            recordOperation(operation, System.nanoTime() - start);
            return result;
        } catch (Exception e) {
            recordOperation(operation + "_failed", System.nanoTime() - start);
            throw e;
        }
    }

    public static void measure(String operation, Runnable runnable) {
        measure(operation, () -> {
            runnable.run();
            return null;
        });
    }

    private static void recordOperation(String operation, long durationNanos) {
        operationCounts.computeIfAbsent(operation, k -> new AtomicLong()).incrementAndGet();
        operationTimes.computeIfAbsent(operation, k -> new AtomicLong()).addAndGet(durationNanos);
    }

    public static void printPerformanceReport() {
        System.out.println("=== Debug Performance Report ===");
        operationCounts.forEach((op, count) -> {
            long totalTime = operationTimes.get(op).get();
            double avgTimeMs = totalTime / (double) count / 1_000_000;
            System.out.printf("  %s: %d calls, avg %.2f ms%n", op, count.get(), avgTimeMs);
        });
    }
}
```

## Configuration and Control

### DebugConfig.java

```java
package io.ballerina.compiler.api.impl.debug;

/**
 * Configuration for debugging features.
 */
public class DebugConfig {
    private static boolean visualizationEnabled = false;
    private static boolean nullTrackingEnabled = false;
    private static boolean webDashboardEnabled = false;
    private static int webDashboardPort = 8080;

    static {
        // Initialize from system properties
        visualizationEnabled = Boolean.parseBoolean(
            System.getProperty("ballerina.debug.visualization.enabled", "false"));
        nullTrackingEnabled = Boolean.parseBoolean(
            System.getProperty("ballerina.debug.nullTracking.enabled", "false"));
        webDashboardEnabled = Boolean.parseBoolean(
            System.getProperty("ballerina.debug.webDashboard.enabled", "false"));
        webDashboardPort = Integer.parseInt(
            System.getProperty("ballerina.debug.webDashboard.port", "8080"));
    }

    public static boolean isVisualizationEnabled() { return visualizationEnabled; }
    public static boolean isNullTrackingEnabled() { return nullTrackingEnabled; }
    public static boolean isWebDashboardEnabled() { return webDashboardEnabled; }
    public static int getWebDashboardPort() { return webDashboardPort; }
}
```

This comprehensive debugging visualization system provides detailed insights into type resolution processes, enabling developers to identify and resolve null pointer exceptions in anonymous type processing through multiple visualization and analysis tools.
