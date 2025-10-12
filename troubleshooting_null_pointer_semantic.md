# Troubleshooting Guide: Null Pointer Issues in Semantic Analysis

## Overview

This guide helps developers diagnose and resolve null pointer exceptions (NPE) and related issues in Ballerina's semantic analysis, particularly when working with anonymous types, type resolution, and semantic API operations.

## Quick Diagnosis

### Symptom: NullPointerException in Semantic API

**Error Pattern:**
```
java.lang.NullPointerException
    at io.ballerina.compiler.api.impl.symbols.AbstractStructuredTypeSymbol.getLocation(AbstractStructuredTypeSymbol.java:42)
```

**Root Cause:** Anonymous type lacks proper symbol initialization.

**Immediate Solution:**
```java
// Instead of:
Location loc = typeSymbol.getLocation(); // May throw NPE

// Use:
Optional<Location> locOpt = typeSymbol.getLocation();
if (locOpt.isPresent()) {
    Location loc = locOpt.get();
    // Safe to use
} else {
    // Handle missing location gracefully
}
```

### Symptom: Language Server Crashes on Anonymous Types

**Error Pattern:**
```
[Error - 10:30:15 AM] Request textDocument/hover failed.
Message: Internal error.
Code: -32603
```

**Root Cause:** Semantic API crashes when processing anonymous record/object types.

**Solution:**
1. Update to Ballerina version with anonymous type fix (2201.10.0+)
2. Language server automatically becomes stable with anonymous types
3. No code changes required

### Symptom: Compilation Fails on Valid Code

**Error Pattern:**
```
error: java.lang.NullPointerException
    at io.ballerina.compiler.api.impl.TypesFactory.getTypeDescriptor(TypesFactory.java:167)
```

**Root Cause:** Map intersections or complex type operations create anonymous types without symbols.

**Solution:**
1. Apply the anonymous type null safety fix
2. Code that previously failed will now compile successfully
3. No source code changes needed

## Detailed Troubleshooting

### Issue 1: NPE in Type Symbol Access

#### Symptoms
- `NullPointerException` when calling `getLocation()`, `getName()`, or other symbol methods
- Crash occurs with anonymous record/object literals
- IDE shows "Internal error" for certain code constructs

#### Diagnosis
```java
// Check if type symbol exists
BType bType = /* from somewhere */;
if (bType.tsymbol == null) {
    System.out.println("Anonymous type detected - symbol missing");
}
```

#### Solutions

**For Application Code:**
```java
// Safe symbol access pattern
public Optional<String> getTypeNameSafe(TypeSymbol typeSymbol) {
    if (!(typeSymbol instanceof AbstractStructuredTypeSymbol)) {
        return Optional.empty();
    }

    AbstractStructuredTypeSymbol structured = (AbstractStructuredTypeSymbol) typeSymbol;
    // This is now safe with the fix
    Optional<Location> location = structured.getLocation();
    return location.map(loc -> "Type at " + loc.lineRange());
}
```

**For Compiler Development:**
```java
// Ensure symbol exists before access
public BTypeSymbol ensureTypeSymbol(BType bType) {
    if (bType.tsymbol == null && requiresTypeSymbol(bType)) {
        bType.tsymbol = createSyntheticTypeSymbol(bType);
    }
    return bType.tsymbol;
}

private boolean requiresTypeSymbol(BType bType) {
    return switch (bType.getKind()) {
        case RECORD, OBJECT, UNION, ARRAY, TUPLE, MAP, TABLE, STREAM -> true;
        default -> false;
    };
}
```

### Issue 2: Performance Degradation After Fix

#### Symptoms
- Compilation becomes slower
- Memory usage increases
- Anonymous types cause performance issues

#### Diagnosis
```java
// Monitor synthetic symbol creation
long syntheticSymbolsCreated = /* track in your application */;
if (syntheticSymbolsCreated > 1000) {
    System.out.println("High synthetic symbol creation detected");
}
```

#### Solutions

**Optimization 1: Symbol Caching**
```java
private final Map<String, BTypeSymbol> symbolCache = new ConcurrentHashMap<>();

private BTypeSymbol createSyntheticTypeSymbol(BType bType) {
    String key = bType.getKind() + "_" + System.identityHashCode(bType);
    return symbolCache.computeIfAbsent(key, k -> createNewSymbol(bType));
}
```

**Optimization 2: Lazy Validation**
```java
public boolean validateTypeHierarchy(BType bType) {
    if (bType == null || bType.tsymbol != null) {
        return true; // Fast path
    }
    // Only validate when necessary
    return performValidation(bType);
}
```

**Optimization 3: Reduce Exception Handling Scope**
```java
// Instead of broad try-catch
public Optional<TypeSymbol> resolveType(BType bType) {
    if (bType == null) return Optional.empty();

    // Fast validation without try-catch
    if (!quickValidation(bType)) {
        return Optional.empty();
    }

    // Only wrap the actual risky operation
    try {
        return Optional.ofNullable(typesFactory.getTypeDescriptor(bType, bType.tsymbol));
    } catch (Exception e) {
        return Optional.empty();
    }
}
```

### Issue 3: Memory Leaks with Synthetic Symbols

#### Symptoms
- Memory usage grows over time
- OutOfMemoryError in long-running processes
- Garbage collection doesn't reclaim memory

#### Diagnosis
```java
// Check for symbol cache issues
Runtime runtime = Runtime.getRuntime();
long usedMemory = runtime.totalMemory() - runtime.freeMemory();
if (usedMemory > MAX_EXPECTED_MEMORY) {
    System.out.println("Potential memory leak detected");
}
```

#### Solutions

**Scoped Symbol Creation:**
```java
// Ensure symbols are scoped to compilation context
public class CompilationContext {
    private final Map<BType, BTypeSymbol> syntheticSymbols = new HashMap<>();

    public BTypeSymbol getOrCreateSyntheticSymbol(BType bType) {
        return syntheticSymbols.computeIfAbsent(bType, this::createSynthetic);
    }

    // Symbols automatically cleaned up when context is garbage collected
}
```

**Cache Size Limits:**
```java
private static final int MAX_SYNTHETIC_SYMBOLS = 10000;
private final Map<String, BTypeSymbol> symbolCache = new LinkedHashMap<>() {
    @Override
    protected boolean removeEldestEntry(Map.Entry eldest) {
        return size() > MAX_SYNTHETIC_SYMBOLS;
    }
};
```

### Issue 4: Type Resolution Inconsistencies

#### Symptoms
- Same type resolves differently in different contexts
- Anonymous types not recognized as equivalent
- Type checking fails unexpectedly

#### Diagnosis
```java
// Compare type resolution results
Optional<TypeSymbol> type1 = model.typeOf(range1);
Optional<TypeSymbol> type2 = model.typeOf(range2);

if (type1.isPresent() && type2.isPresent()) {
    boolean equivalent = type1.get().equals(type2.get());
    if (!equivalent && shouldBeEquivalent(range1, range2)) {
        System.out.println("Type resolution inconsistency detected");
    }
}
```

#### Solutions

**Consistent Symbol Creation:**
```java
// Use deterministic symbol names
private BTypeSymbol createSyntheticTypeSymbol(BType bType) {
    String symbolName = generateDeterministicName(bType);
    return new BTypeSymbol(
        SymTag.TYPE,
        Flags.ANONYMOUS,
        Names.fromString(symbolName),
        PackageID.ANNOTATIONS,
        bType,
        null,
        symTable.builtinPos,
        SymbolOrigin.VIRTUAL
    );
}

private String generateDeterministicName(BType bType) {
    // Create name based on type structure, not identity
    return "anon_" + bType.getKind() + "_" + typeStructureHash(bType);
}
```

**Type Normalization:**
```java
public BType normalizeAnonymousType(BType bType) {
    if (bType.tsymbol == null && requiresTypeSymbol(bType)) {
        ensureTypeSymbol(bType);
    }
    return bType;
}
```

### Issue 5: Language Server Diagnostic Conflicts

#### Symptoms
- Diagnostics show incorrect error locations
- Type information missing from hover/completion
- Semantic highlighting fails on anonymous types

#### Diagnosis
```java
// Check language server logs
// Look for errors like:
// "Failed to resolve type for anonymous structure"
// "Location information unavailable for type"
```

#### Solutions

**Enhanced Error Handling:**
```java
// Language server should handle Optional results gracefully
public Hover getHover(TextDocumentPositionParams params) {
    Optional<TypeSymbol> typeOpt = semanticModel.typeOfSafe(position);
    if (typeOpt.isEmpty()) {
        // Return basic hover without type info
        return createBasicHover();
    }

    TypeSymbol type = typeOpt.get();
    Optional<Location> locationOpt = type.getLocation();
    if (locationOpt.isEmpty()) {
        // Use fallback location or omit location info
        return createHoverWithoutLocation(type);
    }

    // Full hover with type and location
    return createFullHover(type, locationOpt.get());
}
```

**Fallback Strategies:**
```java
public CompletionItem createCompletionForAnonymousType() {
    CompletionItem item = new CompletionItem();
    item.setLabel("anonymous type");
    // Omit location if unavailable
    // item.setDetail("Location unavailable"); // Don't set if null
    return item;
}
```

## Prevention Guidelines

### 1. **Defensive Programming**
```java
// Always check for symbol existence
public void processTypeSymbol(TypeSymbol symbol) {
    Objects.requireNonNull(symbol, "TypeSymbol cannot be null");

    // Safe access patterns
    Optional<Location> location = symbol.getLocation();
    Optional<String> name = getNameSafely(symbol);
}
```

### 2. **Consistent Error Handling**
```java
// Standard pattern for all semantic operations
public <T> T executeSemanticOperation(SemanticOperation<T> operation) {
    try {
        T result = operation.execute();
        return result != null ? result : getDefaultValue();
    } catch (Exception e) {
        log.warn("Semantic operation failed", e);
        return getDefaultValue();
    }
}
```

### 3. **Input Validation**
```java
// Validate inputs at API boundaries
public Optional<TypeSymbol> resolveType(LineRange range) {
    if (range == null || range.fileName() == null) {
        return Optional.empty();
    }

    // Continue with validated input
    return semanticModel.typeOfSafe(range);
}
```

### 4. **Testing Best Practices**
```java
@Test
public void testAnonymousTypeHandling() {
    // Test with various anonymous type scenarios
    testAnonymousRecord();
    testAnonymousObject();
    testNestedAnonymousTypes();
    testMapIntersectionTypes();
}

@Test
public void testErrorRecovery() {
    // Ensure graceful handling of edge cases
    Optional<TypeSymbol> result = model.typeOfSafe(invalidRange);
    assertNotNull(result); // Should not be null
    assertFalse(result.isPresent()); // But should be empty
}
```

## Advanced Debugging

### Enable Debug Logging
```java
// JVM arguments for debugging
-Dballerina.semantic.debug=true
-Dballerina.semantic.logSyntheticSymbols=true
```

### Monitor Symbol Creation
```java
// Add metrics to track synthetic symbol usage
MetricsRegistry registry = /* your metrics system */;
Counter syntheticSymbolsCreated = registry.counter("ballerina.semantic.synthetic_symbols_created");
Gauge activeSymbols = registry.gauge("ballerina.semantic.active_symbols", this::countActiveSymbols);
```

### Heap Dump Analysis
```java
// Generate heap dump for memory leak analysis
Runtime.getRuntime().addShutdownHook(new Thread(() -> {
    // Generate heap dump on shutdown
    // Analyze for BTypeSymbol instances
}));
```

## Getting Help

### Community Resources
- **GitHub Issues:** Report bugs at https://github.com/ballerina-platform/ballerina-lang/issues
- **Stack Overflow:** Tag questions with `ballerina` and `semantic-api`
- **Ballerina Slack:** Join #language-server channel

### Diagnostic Information to Provide
When reporting issues, include:
1. Ballerina version: `bal version`
2. Code sample that reproduces the issue
3. Full stack trace
4. IDE/language server logs
5. JVM version and memory settings

### Emergency Workarounds
If issues persist:
1. Avoid complex anonymous type expressions
2. Use explicit type annotations
3. Disable affected language server features temporarily
4. Use compiler directly instead of IDE

## Conclusion

The anonymous type null safety fix significantly improves Ballerina's semantic API stability. Most NPE issues are resolved automatically without code changes. When issues occur, they typically involve edge cases that can be addressed using the safe API patterns documented in this guide.

Remember: **Graceful degradation is better than crashes**. Always prefer `Optional.empty()` over `NullPointerException`.</content>
<parameter name="filePath">/Users/morningstar/Downloads/ballerina-lang-master/troubleshooting_null_pointer_semantic.md