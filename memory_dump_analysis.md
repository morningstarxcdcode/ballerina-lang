# Memory Dump Analysis: Anonymous Type NPE Investigation

## Overview

This guide provides tools and procedures for analyzing memory dumps to identify the exact object state when null pointer exceptions occur in anonymous type processing.

## Memory Dump Generation

### Automatic Dump on NPE

**JVM Configuration:**
```bash
# JVM arguments for automatic heap dumps on OOM
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/path/to/dumps/anonymous_type_npe.hprof
-XX:+PrintGCDetails
-XX:+PrintGCTimeStamps
-Xloggc:/path/to/logs/gc.log

# Additional debugging flags
-XX:+PrintConcurrentLocks
-XX:+PrintClassHistogram
-XX:+PrintTenuringDistribution
```

### Programmatic Dump Generation

**Add to BallerinaSemanticModel.java:**
```java
import java.lang.management.ManagementFactory;
import com.sun.management.HotSpotDiagnosticMXBean;

// Add method to generate dump on NPE
private void generateMemoryDump(String reason) {
    try {
        HotSpotDiagnosticMXBean mxBean = ManagementFactory.getPlatformMXBean(HotSpotDiagnosticMXBean.class);
        String fileName = "anonymous_type_npe_" + System.currentTimeMillis() + ".hprof";
        mxBean.dumpHeap(fileName, true);
        logger.error("Memory dump generated: {} for reason: {}", fileName, reason);
    } catch (Exception e) {
        logger.error("Failed to generate memory dump", e);
    }
}

// Call in exception handlers
private Optional<TypeSymbol> resolveTypeSafely(BType bType) {
    try {
        // ... existing logic
    } catch (NullPointerException e) {
        generateMemoryDump("NPE in resolveTypeSafely: " + e.getMessage());
        return Optional.empty();
    }
}
```

### Conditional Dump Generation

**Smart Dump Trigger:**
```java
private void generateConditionalDump(BType bType, String context) {
    // Only dump for anonymous types
    if (bType != null && bType.tsymbol == null && requiresTypeSymbol(bType)) {
        String reason = String.format("Anonymous %s type without symbol in %s",
                                    bType.getKind(), context);
        generateMemoryDump(reason);
    }
}

// Use in key locations
public TypeSymbol getTypeDescriptor(BType bType, BSymbol tSymbol) {
    generateConditionalDump(bType, "getTypeDescriptor");

    if (tSymbol == null && requiresTypeSymbol(bType)) {
        tSymbol = createSyntheticTypeSymbol(bType);
    }
    // ... rest of method
}
```

## Memory Dump Analysis Tools

### Eclipse Memory Analyzer (MAT)

**Installation:**
```bash
# Download from https://eclipse.org/mat/
# Or use standalone version
wget https://download.eclipse.org/mat/snapshots/1.14.0/rcp/MemoryAnalyzer-1.14.0.20230307-linux.gtk.x86_64.zip
unzip MemoryAnalyzer-1.14.0.20230307-linux.gtk.x86_64.zip
```

**MAT Analysis Script:**
```bash
#!/bin/bash
# analyze_anonymous_type_dump.sh

HEAP_DUMP=$1
OUTPUT_DIR="./mat_analysis"

# Run MAT analysis
./MemoryAnalyzer -application org.eclipse.mat.api.parse \
  -commandLine "$HEAP_DUMP" \
  -vmargs -Xmx4g

# Generate reports
./MemoryAnalyzer -application org.eclipse.mat.api.query \
  -commandLine "leakhunter;defaults" \
  "$HEAP_DUMP" \
  -vmargs -Xmx4g > "$OUTPUT_DIR/leak_suspects.txt"

./MemoryAnalyzer -application org.eclipse.mat.api.query \
  -commandLine "component_report;defaults" \
  "$HEAP_DUMP" \
  -vmargs -Xmx4g > "$OUTPUT_DIR/component_report.txt"
```

### jhat (JDK Tool)

**Basic Analysis:**
```bash
# Start jhat server
jhat -J-Xmx4g anonymous_type_npe.hprof

# Access via browser at http://localhost:7000
# Look for:
# - BType instances with null tsymbol
# - BRecordType objects
# - Symbol table contents
```

**Automated jhat Analysis:**
```bash
#!/bin/bash
# jhat_analysis.sh

HEAP_DUMP=$1
JHAT_PORT=7000

# Start jhat in background
jhat -port $JHAT_PORT -J-Xmx4g "$HEAP_DUMP" &
JHAT_PID=$!

# Wait for startup
sleep 10

# Query for anonymous types
curl -s "http://localhost:$JHAT_PORT/histo/" | grep -E "(BRecordType|BObjectType|BType)"

# Query for symbol tables
curl -s "http://localhost:$JHAT_PORT/showInstance/0x..." | grep -A 10 -B 10 "tsymbol"

# Kill jhat
kill $JHAT_PID
```

### Custom Analysis Script

**Anonymous Type Analyzer:**
```java
import java.io.File;
import java.util.*;

public class AnonymousTypeAnalyzer {
    public static void main(String[] args) throws Exception {
        if (args.length != 1) {
            System.err.println("Usage: java AnonymousTypeAnalyzer <heap_dump.hprof>");
            System.exit(1);
        }

        File heapDump = new File(args[0]);
        analyzeHeapDump(heapDump);
    }

    private static void analyzeHeapDump(File heapDump) {
        // Use HPROF parser or MAT API
        System.out.println("Analyzing heap dump: " + heapDump.getName());

        // Find BType instances
        List<BTypeInfo> anonymousTypes = findAnonymousTypes(heapDump);

        System.out.println("Found " + anonymousTypes.size() + " anonymous types:");

        for (BTypeInfo type : anonymousTypes) {
            System.out.printf("  %s at 0x%s: symbol=%s%n",
                            type.kind, type.address, type.symbolStatus);
        }

        // Analyze symbol table
        analyzeSymbolTable(heapDump);
    }

    private static List<BTypeInfo> findAnonymousTypes(File heapDump) {
        List<BTypeInfo> result = new ArrayList<>();
        // Implementation would parse HPROF format
        // Look for BRecordType, BObjectType instances with null tsymbol
        return result;
    }

    private static void analyzeSymbolTable(File heapDump) {
        System.out.println("\nSymbol table analysis:");
        // Check symbol table for missing entries
        // Verify synthetic symbol creation
    }

    static class BTypeInfo {
        String kind;
        String address;
        String symbolStatus;
    }
}
```

## Memory Analysis Queries

### MAT Queries for Anonymous Types

**Find All Anonymous Types:**
```
SELECT * FROM INSTANCEOF org.wso2.ballerinalang.compiler.util.BType
WHERE (toString().contains("{") AND toString().contains("}"))
   OR toString().contains("anonymous")
   OR tsymbol = null
```

**Find Types Without Symbols:**
```
SELECT * FROM INSTANCEOF org.wso2.ballerinalang.compiler.util.BType
WHERE tsymbol = null
  AND (getKind().toString() = "RECORD"
    OR getKind().toString() = "OBJECT"
    OR getKind().toString() = "UNION"
    OR getKind().toString() = "ARRAY")
```

**Find Synthetic Symbols:**
```
SELECT * FROM INSTANCEOF org.wso2.ballerinalang.compiler.util.BTypeSymbol
WHERE getOrigin() = org.wso2.ballerinalang.compiler.util.SymbolOrigin.VIRTUAL
   OR getName().toString().startsWith("synthetic_")
```

### OQL Queries

**Anonymous Record Types:**
```sql
SELECT toString(r), r.@objectAddress, r.tsymbol
FROM org.wso2.ballerinalang.compiler.util.BRecordType r
WHERE r.tsymbol = null
```

**Symbol Table Contents:**
```sql
SELECT s.name.toString(), s.@objectAddress, s.origin
FROM org.wso2.ballerinalang.compiler.util.BTypeSymbol s
WHERE s.origin.toString() = "VIRTUAL"
```

**Type Resolution Call Stack:**
```sql
SELECT t.toString(), t.@objectAddress
FROM org.wso2.ballerinalang.compiler.util.BType t
WHERE t.@referenceGraph[contains(it, "resolveType")]
```

## Object State Analysis

### BType Object Inspection

**Key Fields to Examine:**
```java
// In debugger or dump analysis
bType.getKind()           // RECORD, OBJECT, etc.
bType.tsymbol            // Should not be null
bType.toString()         // Type representation
bType.flags              // Type flags
bType.pos                // Source position
```

**Symbol Object Inspection:**
```java
// When symbol exists
symbol.name              // Symbol name
symbol.kind              // Symbol kind
symbol.owner             // Owner symbol
symbol.origin            // VIRTUAL for synthetic
symbol.pos               // Position information
```

### Call Stack Analysis

**Expected Call Stack for NPE:**
```
AbstractStructuredTypeSymbol.getLocation()
    BallerinaSemanticModel.typeOf()
    // ... user code calling semantic API
```

**Investigate Missing Symbol Creation:**
1. Check if `requiresTypeSymbol()` returned true
2. Verify `createSyntheticTypeSymbol()` was called
3. Confirm symbol was assigned to `bType.tsymbol`
4. Check for concurrent modification issues

### Memory Corruption Detection

**Reference Chain Analysis:**
```java
// Check for broken object references
if (bType != null) {
    // These should not be null/corrupted
    assert bType.getKind() != null;
    assert bType.toString() != null;

    // Check symbol if present
    if (bType.tsymbol != null) {
        assert bType.tsymbol.name != null;
        assert bType.tsymbol.kind != null;
    }
}
```

## Automated Analysis Pipeline

### Jenkins Pipeline Integration

**Heap Dump Analysis Job:**
```groovy
pipeline {
    agent any
    stages {
        stage('Analyze Heap Dump') {
            steps {
                script {
                    // Find latest heap dump
                    def heapDump = findFiles(glob: '**/anonymous_type_npe_*.hprof')[0]

                    // Run MAT analysis
                    sh "./analyze_heap_dump.sh ${heapDump.path}"

                    // Parse results
                    def results = readFile('mat_analysis/leak_suspects.txt')

                    // Check for anonymous type issues
                    if (results.contains('BType') && results.contains('null')) {
                        echo "Anonymous type memory issue detected"
                        // Archive dump for further analysis
                        archiveArtifacts artifacts: "${heapDump.path}", allowEmptyArchive: true
                    }
                }
            }
        }
    }
}
```

### Continuous Monitoring

**JVM Metrics Collection:**
```java
// Add to BallerinaSemanticModel
private static final MeterRegistry registry = Metrics.globalRegistry;

private static final Counter anonymousTypeNPE = Counter
    .builder("ballerina.semantic.anonymous_type_npe")
    .description("Number of NPEs in anonymous type processing")
    .register(registry);

private static final Gauge activeSyntheticSymbols = Gauge
    .builder("ballerina.semantic.active_synthetic_symbols")
    .description("Number of active synthetic symbols")
    .register(registry);

// Increment on NPE
private void handleAnonymousTypeNPE(BType bType) {
    anonymousTypeNPE.increment();
    generateMemoryDump("Anonymous type NPE: " + bType);
}
```

## Troubleshooting Memory Analysis

### Common Issues

**Dump File Too Large:**
- Use compressed dumps: `-XX:+CompressedOops`
- Filter dumps to specific classes
- Use sampling instead of full dumps

**MAT Analysis Fails:**
- Ensure sufficient heap space for MAT
- Use 64-bit JVM
- Check dump file integrity

**No Anonymous Types Found:**
- Verify dump was taken during NPE
- Check if synthetic symbols were created
- Look for different type representations

### Performance Considerations

**Dump Generation Impact:**
- Heap dumps pause application threads
- Use in development/testing only
- Consider conditional dump generation

**Analysis Time:**
- Large dumps take significant time to analyze
- Use incremental analysis
- Focus on specific object types

## Integration with CI/CD

### Automated Regression Detection

**Test Integration:**
```java
@Test
public void testNoMemoryLeaksInAnonymousTypes() {
    // Run code that triggers anonymous type processing
    // Verify no OOM or excessive memory usage
    // Check that synthetic symbols are properly cleaned up

    long initialMemory = getCurrentMemoryUsage();
    processAnonymousTypes();
    long finalMemory = getCurrentMemoryUsage();

    assertTrue("Memory leak detected",
               finalMemory - initialMemory < MAX_MEMORY_DELTA);
}
```

This memory dump analysis framework provides comprehensive tools for identifying the exact object state and memory conditions when null pointer exceptions occur in anonymous type processing, enabling precise diagnosis and resolution of these issues.</content>
<parameter name="filePath">/Users/morningstar/Downloads/ballerina-lang-master/memory_dump_analysis.md