# Developer Guidelines: Safely Handling Anonymous Types in Semantic API Enhancements

## Overview

This document provides guidelines for Ballerina compiler developers working with anonymous types in semantic API enhancements. Following these guidelines ensures robust, null-safe implementations that prevent crashes and provide graceful degradation.

## Core Principles

### 1. **Defensive Programming**
Always assume anonymous types may lack proper symbol initialization. Never access `BType.tsymbol` directly without null checks.

```java
// ❌ BAD: Direct access without null check
public Location getLocation() {
    return this.getBType().tsymbol.pos; // NPE risk
}

// ✅ GOOD: Safe access with null check
public Optional<Location> getLocation() {
    return this.getBType().tsymbol != null
        ? Optional.of(this.getBType().tsymbol.pos)
        : Optional.empty();
}
```

### 2. **Graceful Degradation**
Return `Optional.empty()` or null instead of throwing exceptions when type information is incomplete.

```java
// ✅ GOOD: Graceful degradation
public Optional<TypeSymbol> resolveType(BType bType) {
    if (bType == null || bType.tsymbol == null) {
        return Optional.empty(); // Degrade gracefully
    }
    // ... continue with resolution
}
```

### 3. **Conservative Symbol Creation**
Only create synthetic symbols when absolutely necessary, and only for types that require them.

```java
// ✅ GOOD: Conservative approach
private boolean requiresTypeSymbol(BType bType) {
    return switch (bType.getKind()) {
        case RECORD, OBJECT, UNION, ARRAY, TUPLE, MAP, TABLE, STREAM -> true;
        default -> false;
    };
}
```

## Implementation Patterns

### Pattern 1: Safe Symbol Access

```java
public Optional<String> getTypeName(BType bType) {
    if (bType == null || bType.tsymbol == null) {
        return Optional.empty();
    }

    try {
        return Optional.ofNullable(bType.tsymbol.name.value);
    } catch (Exception e) {
        return Optional.empty();
    }
}
```

### Pattern 2: Synthetic Symbol Creation

```java
public BTypeSymbol ensureTypeSymbol(BType bType) {
    if (bType.tsymbol != null) {
        return bType.tsymbol; // Fast path
    }

    if (!requiresTypeSymbol(bType)) {
        return null; // No symbol needed
    }

    // Create synthetic symbol
    bType.tsymbol = createSyntheticTypeSymbol(bType);
    return bType.tsymbol;
}

private BTypeSymbol createSyntheticTypeSymbol(BType bType) {
    return new BTypeSymbol(
        SymTag.TYPE,
        Flags.ANONYMOUS,
        Names.fromString("synthetic_" + bType.getKind()),
        PackageID.ANNOTATIONS,
        bType,
        null,
        symTable.builtinPos,
        SymbolOrigin.VIRTUAL
    );
}
```

### Pattern 3: Safe Type Resolution Pipeline

```java
public Optional<TypeSymbol> resolveTypeSafely(BType bType, BSymbol contextSymbol) {
    // Input validation
    if (bType == null) {
        return Optional.empty();
    }

    try {
        // Ensure type hierarchy is valid
        if (!validateAndInitializeTypeHierarchy(bType)) {
            return Optional.empty();
        }

        // Resolve using safe methods
        return Optional.ofNullable(typesFactory.getTypeDescriptorSafe(bType, contextSymbol));

    } catch (Exception e) {
        // Log for debugging but don't crash
        return Optional.empty();
    }
}
```

### Pattern 4: Recursive Type Validation

```java
public boolean validateAndInitializeTypeHierarchy(BType bType) {
    if (bType == null) {
        return false;
    }

    // Fast path for already validated types
    if (bType.tsymbol != null) {
        return true;
    }

    // Ensure this type has a symbol
    ensureTypeSymbol(bType);

    // Recursively validate nested types
    switch (bType.getKind()) {
        case RECORD -> validateRecordType((BRecordType) bType);
        case ARRAY -> validateArrayType((BArrayType) bType);
        case MAP -> validateMapType((BMapType) bType);
        // ... handle other types
    }

    return true;
}
```

## API Design Guidelines

### 1. **Return Optional Types**
All semantic API methods that may encounter anonymous types should return `Optional<T>`.

```java
// ✅ GOOD: Clear contract
public Optional<TypeSymbol> typeOf(LineRange range);
public Optional<Location> getLocation();

// ❌ BAD: Unclear contract
public TypeSymbol typeOf(LineRange range); // May return null
public Location getLocation(); // May throw NPE
```

### 2. **Consistent Error Handling**
Use consistent patterns for error handling across the semantic API.

```java
// ✅ GOOD: Consistent pattern
private <T> T executeSemanticOperation(SemanticOperation<T> operation) {
    try {
        return operation.execute();
    } catch (Exception e) {
        return null; // Or Optional.empty() for Optional return types
    }
}

@FunctionalInterface
private interface SemanticOperation<T> {
    T execute() throws Exception;
}
```

### 3. **Input Validation**
Always validate inputs at API boundaries.

```java
public Optional<TypeSymbol> typeOfSafe(LineRange range) {
    // Input validation
    if (range == null || range.fileName() == null) {
        return Optional.empty();
    }

    // ... continue with processing
}
```

## Testing Guidelines

### 1. **Comprehensive Test Coverage**
Test all code paths that handle anonymous types.

```java
@Test
public void testAnonymousRecordTypeResolution() {
    // Test with anonymous record: {name: "test", value: 42}
    // Verify no NPE and proper Optional.empty() handling
}

@Test
public void testNestedAnonymousTypes() {
    // Test deeply nested anonymous structures
    // Verify recursive validation works
}

@Test
public void testSyntheticSymbolCreation() {
    // Test synthetic symbol creation
    // Verify symbols have correct properties
}
```

### 2. **Performance Testing**
Ensure null safety doesn't introduce significant overhead.

```java
@Test
public void testPerformanceOverhead() {
    // Measure time for type resolution with/without null safety
    // Ensure overhead is acceptable (< 10% increase)
}
```

### 3. **Edge Case Testing**
Test unusual but valid anonymous type scenarios.

```java
@Test
public void testEmptyAnonymousRecord() {
    // Test: var empty = {};
}

@Test
public void testRecursiveAnonymousTypes() {
    // Test self-referencing anonymous structures
}
```

## Code Review Checklist

### For Semantic API Changes:

- [ ] All `BType.tsymbol` access is null-safe
- [ ] Methods return `Optional<T>` for potentially incomplete data
- [ ] Synthetic symbols use `SymbolOrigin.VIRTUAL`
- [ ] Exception handling provides graceful degradation
- [ ] Input validation at API boundaries
- [ ] Comprehensive test coverage for anonymous types
- [ ] Performance impact assessed and acceptable
- [ ] Documentation updated for new safe methods

### For Type System Changes:

- [ ] `requiresTypeSymbol()` logic covers all necessary types
- [ ] Synthetic symbol creation is conservative
- [ ] Type validation handles all nested structures
- [ ] No interference with existing symbol resolution
- [ ] Backward compatibility maintained

## Common Pitfalls to Avoid

### 1. **Direct Symbol Access**
```java
// ❌ BAD
String name = bType.tsymbol.name.value; // NPE risk

// ✅ GOOD
Optional<String> name = getTypeNameSafely(bType);
```

### 2. **Broad Exception Handling**
```java
// ❌ BAD
try {
    // Complex logic
} catch (Exception e) {
    return null; // Too broad, may hide real issues
}

// ✅ GOOD
try {
    // Minimal logic
} catch (NullPointerException e) {
    return Optional.empty(); // Specific handling
}
```

### 3. **Eager Symbol Creation**
```java
// ❌ BAD
bType.tsymbol = createSyntheticTypeSymbol(bType); // Always creates

// ✅ GOOD
if (bType.tsymbol == null && requiresTypeSymbol(bType)) {
    bType.tsymbol = createSyntheticTypeSymbol(bType); // Only when needed
}
```

### 4. **Inconsistent Return Types**
```java
// ❌ BAD
public TypeSymbol getType(BType bType) { // May return null
    return bType.tsymbol != null ? createTypeSymbol(bType) : null;
}

// ✅ GOOD
public Optional<TypeSymbol> getType(BType bType) { // Clear contract
    return bType.tsymbol != null
        ? Optional.of(createTypeSymbol(bType))
        : Optional.empty();
}
```

## Performance Considerations

### 1. **Fast Paths**
Always provide fast paths for common cases.

```java
public Optional<TypeSymbol> resolveType(BType bType) {
    // Fast path: type already has symbol
    if (bType.tsymbol != null) {
        return Optional.of(typesFactory.getTypeDescriptor(bType, bType.tsymbol));
    }

    // Slow path: need synthetic symbol
    // ... handle anonymous types
}
```

### 2. **Caching Strategies**
Consider caching for frequently accessed synthetic symbols.

```java
private final Map<String, BTypeSymbol> symbolCache = new ConcurrentHashMap<>();

private BTypeSymbol createSyntheticTypeSymbol(BType bType) {
    String key = bType.getKind() + "_" + System.identityHashCode(bType);
    return symbolCache.computeIfAbsent(key, k -> createNewSymbol(bType));
}
```

### 3. **Lazy Validation**
Only validate type hierarchies when actually needed.

```java
public boolean validateTypeHierarchy(BType bType) {
    if (bType == null || bType.tsymbol != null) {
        return true; // Already valid or null
    }
    // ... perform validation
}
```

## Migration Guidelines

### When Adding New Semantic API Methods:

1. **Use Optional Return Types**: `Optional<TypeSymbol>`, `Optional<Location>`, etc.
2. **Add Safe Variants**: Provide both unsafe (existing) and safe (new) methods
3. **Document Behavior**: Clearly document when `Optional.empty()` is returned
4. **Add Comprehensive Tests**: Cover all anonymous type scenarios
5. **Performance Test**: Ensure no significant overhead

### When Modifying Existing Methods:

1. **Maintain Backward Compatibility**: Don't break existing contracts
2. **Add Safe Overloads**: Provide new safe methods alongside existing ones
3. **Deprecation Path**: Mark unsafe methods as deprecated with migration guide
4. **Gradual Migration**: Allow time for users to migrate to safe APIs

## Best Practices Summary

1. **Always check for null before accessing `BType.tsymbol`**
2. **Return `Optional<T>` for potentially incomplete type information**
3. **Create synthetic symbols conservatively and only when needed**
4. **Provide graceful degradation instead of crashes**
5. **Validate inputs at API boundaries**
6. **Test thoroughly with anonymous types and edge cases**
7. **Document safe usage patterns and migration paths**
8. **Monitor performance impact of null safety measures**

Following these guidelines ensures the semantic API remains stable and reliable when handling anonymous types, providing a better developer experience and more robust language tooling.</content>
<parameter name="filePath">/Users/morningstar/Downloads/ballerina-lang-master/developer_guidelines_anonymous_types.md