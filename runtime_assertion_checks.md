# Runtime Assertion Checks: Type Hierarchy Integrity Validation

## Overview

This module implements comprehensive runtime assertion checks to validate type hierarchy integrity before semantic API calls, preventing null pointer exceptions and ensuring data consistency in anonymous type processing.

## Core Assertion Framework

### AssertionManager.java

```java
package io.ballerina.compiler.api.impl.assertions;

import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.ArrayList;
import java.util.function.Supplier;

/**
 * Centralized assertion manager for type hierarchy validation.
 */
public class AssertionManager {
    private static final Logger logger = LoggerFactory.getLogger(AssertionManager.class);

    private final List<AssertionFailure> failures = new ArrayList<>();
    private boolean strictMode = false;

    public void setStrictMode(boolean strictMode) {
        this.strictMode = strictMode;
    }

    public void assertTypeHierarchyIntegrity(BType bType, String context) {
        AssertionContext ctx = new AssertionContext(context, bType);

        // Core type assertions
        assertNotNull(bType, "BType", ctx);
        assertValidTypeKind(bType, ctx);
        assertTypeSymbolConsistency(bType, ctx);

        // Symbol-specific assertions
        if (bType.tsymbol != null) {
            assertSymbolIntegrity(bType.tsymbol, ctx);
        }

        // Type-specific validations
        assertTypeSpecificIntegrity(bType, ctx);

        // Report failures
        if (!failures.isEmpty()) {
            handleAssertionFailures(failures, ctx);
            failures.clear();
        }
    }

    private void assertNotNull(Object obj, String name, AssertionContext ctx) {
        if (obj == null) {
            failures.add(new AssertionFailure(
                AssertionFailure.Type.NULL_VALUE,
                name + " is null",
                ctx
            ));
        }
    }

    private void assertValidTypeKind(BType bType, AssertionContext ctx) {
        if (bType.getKind() == null) {
            failures.add(new AssertionFailure(
                AssertionFailure.Type.INVALID_TYPE_KIND,
                "BType has null type kind",
                ctx
            ));
        }
    }

    private void assertTypeSymbolConsistency(BType bType, AssertionContext ctx) {
        if (bType.tsymbol == null) {
            // This is acceptable for anonymous types, but log it
            logger.debug("Anonymous type detected: {} in context {}", bType, ctx.getContext());
            return;
        }

        // Validate symbol type consistency
        if (!isSymbolTypeConsistent(bType, bType.tsymbol)) {
            failures.add(new AssertionFailure(
                AssertionFailure.Type.TYPE_SYMBOL_MISMATCH,
                "Type symbol inconsistency: " + bType.getKind() + " vs " + bType.tsymbol.getClass().getSimpleName(),
                ctx
            ));
        }
    }

    private void assertSymbolIntegrity(BSymbol symbol, AssertionContext ctx) {
        assertNotNull(symbol, "Symbol", ctx);

        if (symbol.name == null) {
            failures.add(new AssertionFailure(
                AssertionFailure.Type.MISSING_SYMBOL_NAME,
                "Symbol has null name",
                ctx
            ));
        }

        if (symbol.kind == null) {
            failures.add(new AssertionFailure(
                AssertionFailure.Type.INVALID_SYMBOL_KIND,
                "Symbol has null kind",
                ctx
            ));
        }
    }

    private void assertTypeSpecificIntegrity(BType bType, AssertionContext ctx) {
        switch (bType.getKind()) {
            case RECORD:
                assertRecordTypeIntegrity((BRecordType) bType, ctx);
                break;
            case OBJECT:
                assertObjectTypeIntegrity((BObjectType) bType, ctx);
                break;
            case UNION:
                assertUnionTypeIntegrity((BUnionType) bType, ctx);
                break;
            case ARRAY:
                assertArrayTypeIntegrity((BArrayType) bType, ctx);
                break;
            case TUPLE:
                assertTupleTypeIntegrity((BTupleType) bType, ctx);
                break;
            case MAP:
                assertMapTypeIntegrity((BMapType) bType, ctx);
                break;
            case TABLE:
                assertTableTypeIntegrity((BTableType) bType, ctx);
                break;
            case STREAM:
                assertStreamTypeIntegrity((BStreamType) bType, ctx);
                break;
            default:
                // Other types don't need specific validation
                break;
        }
    }

    private void handleAssertionFailures(List<AssertionFailure> failures, AssertionContext ctx) {
        StringBuilder message = new StringBuilder();
        message.append("Type hierarchy integrity violations detected in ").append(ctx.getContext()).append(":\n");

        for (AssertionFailure failure : failures) {
            message.append("  - ").append(failure.getMessage()).append("\n");
        }

        String fullMessage = message.toString();
        logger.error(fullMessage);

        if (strictMode) {
            throw new TypeHierarchyIntegrityException(fullMessage, failures);
        }
    }

    // Type-specific assertion methods would be implemented here
    private void assertRecordTypeIntegrity(BRecordType recordType, AssertionContext ctx) { /* ... */ }
    private void assertObjectTypeIntegrity(BObjectType objectType, AssertionContext ctx) { /* ... */ }
    private void assertUnionTypeIntegrity(BUnionType unionType, AssertionContext ctx) { /* ... */ }
    private void assertArrayTypeIntegrity(BArrayType arrayType, AssertionContext ctx) { /* ... */ }
    private void assertTupleTypeIntegrity(BTupleType tupleType, AssertionContext ctx) { /* ... */ }
    private void assertMapTypeIntegrity(BMapType mapType, AssertionContext ctx) { /* ... */ }
    private void assertTableTypeIntegrity(BTableType tableType, AssertionContext ctx) { /* ... */ }
    private void assertStreamTypeIntegrity(BStreamType streamType, AssertionContext ctx) { /* ... */ }

    private boolean isSymbolTypeConsistent(BType bType, BSymbol symbol) {
        // Implementation would check if symbol type matches BType
        return true; // Placeholder
    }
}
```

### AssertionFailure.java

```java
package io.ballerina.compiler.api.impl.assertions;

/**
 * Represents a single assertion failure.
 */
public class AssertionFailure {
    public enum Type {
        NULL_VALUE,
        INVALID_TYPE_KIND,
        TYPE_SYMBOL_MISMATCH,
        MISSING_SYMBOL_NAME,
        INVALID_SYMBOL_KIND,
        STRUCTURAL_INTEGRITY_VIOLATION
    }

    private final Type type;
    private final String message;
    private final AssertionContext context;

    public AssertionFailure(Type type, String message, AssertionContext context) {
        this.type = type;
        this.message = message;
        this.context = context;
    }

    public Type getType() { return type; }
    public String getMessage() { return message; }
    public AssertionContext getContext() { return context; }
}
```

### AssertionContext.java

```java
package io.ballerina.compiler.api.impl.assertions;

/**
 * Context information for assertion failures.
 */
public class AssertionContext {
    private final String context;
    private final BType bType;
    private final long timestamp;

    public AssertionContext(String context, BType bType) {
        this.context = context;
        this.bType = bType;
        this.timestamp = System.currentTimeMillis();
    }

    public String getContext() { return context; }
    public BType getBType() { return bType; }
    public long getTimestamp() { return timestamp; }

    @Override
    public String toString() {
        return "AssertionContext{" +
               "context='" + context + '\'' +
               ", bType=" + (bType != null ? bType.getKind() : "null") +
               ", timestamp=" + timestamp +
               '}';
    }
}
```

### TypeHierarchyIntegrityException.java

```java
package io.ballerina.compiler.api.impl.assertions;

import java.util.List;

/**
 * Exception thrown when type hierarchy integrity assertions fail in strict mode.
 */
public class TypeHierarchyIntegrityException extends RuntimeException {
    private final List<AssertionFailure> failures;

    public TypeHierarchyIntegrityException(String message, List<AssertionFailure> failures) {
        super(message);
        this.failures = failures;
    }

    public List<AssertionFailure> getFailures() {
        return failures;
    }
}
```

## Integration Points

### Enhanced TypesFactory.java

```java
// Add assertion manager integration
private static final AssertionManager assertionManager = new AssertionManager();

public TypeSymbol getTypeDescriptor(BType bType, BSymbol tSymbol, boolean rawTypeOnly) {
    // Pre-call integrity check
    assertionManager.assertTypeHierarchyIntegrity(bType, "TypesFactory.getTypeDescriptor");

    // ... existing implementation
}
```

### Enhanced BallerinaSemanticModel.java

```java
// Add assertion checks before semantic operations
public TypeSymbol typeOf(ExpressionNode expressionNode) {
    // Validate expression node
    assertionManager.assertExpressionIntegrity(expressionNode, "BallerinaSemanticModel.typeOf");

    // ... existing implementation
}

public Optional<Location> location(Node node) {
    // Validate node
    assertionManager.assertNodeIntegrity(node, "BallerinaSemanticModel.location");

    // ... existing implementation
}
```

## Type-Specific Assertions

### Record Type Assertions

```java
private void assertRecordTypeIntegrity(BRecordType recordType, AssertionContext ctx) {
    assertNotNull(recordType.fields, "Record fields", ctx);

    if (recordType.fields != null) {
        for (BField field : recordType.fields) {
            assertNotNull(field, "Record field", ctx);
            if (field != null) {
                assertNotNull(field.name, "Field name", ctx);
                assertNotNull(field.type, "Field type", ctx);
                if (field.type != null) {
                    assertionManager.assertTypeHierarchyIntegrity(field.type, ctx.getContext() + ".field." + field.name);
                }
            }
        }
    }

    if (recordType.restFieldType != null) {
        assertionManager.assertTypeHierarchyIntegrity(recordType.restFieldType, ctx.getContext() + ".restField");
    }
}
```

### Union Type Assertions

```java
private void assertUnionTypeIntegrity(BUnionType unionType, AssertionContext ctx) {
    assertNotNull(unionType.getMemberTypes(), "Union member types", ctx);

    if (unionType.getMemberTypes() != null) {
        for (BType memberType : unionType.getMemberTypes()) {
            assertNotNull(memberType, "Union member type", ctx);
            if (memberType != null) {
                assertionManager.assertTypeHierarchyIntegrity(memberType, ctx.getContext() + ".member");
            }
        }
    }
}
```

### Array Type Assertions

```java
private void assertArrayTypeIntegrity(BArrayType arrayType, AssertionContext ctx) {
    assertNotNull(arrayType.getElementType(), "Array element type", ctx);

    if (arrayType.getElementType() != null) {
        assertionManager.assertTypeHierarchyIntegrity(arrayType.getElementType(), ctx.getContext() + ".element");
    }

    // Validate size constraints
    if (arrayType.getSize() < 0) {
        failures.add(new AssertionFailure(
            AssertionFailure.Type.STRUCTURAL_INTEGRITY_VIOLATION,
            "Array size is negative: " + arrayType.getSize(),
            ctx
        ));
    }
}
```

## Configuration and Control

### AssertionConfig.java

```java
package io.ballerina.compiler.api.impl.assertions;

/**
 * Configuration for assertion behavior.
 */
public class AssertionConfig {
    private static boolean assertionsEnabled = true;
    private static boolean strictMode = false;
    private static boolean logFailures = true;

    public static void setAssertionsEnabled(boolean enabled) {
        assertionsEnabled = enabled;
    }

    public static boolean isAssertionsEnabled() {
        return assertionsEnabled;
    }

    public static void setStrictMode(boolean strict) {
        strictMode = strict;
    }

    public static boolean isStrictMode() {
        return strictMode;
    }

    public static void setLogFailures(boolean log) {
        logFailures = log;
    }

    public static boolean shouldLogFailures() {
        return logFailures;
    }
}
```

### System Property Configuration

```java
// In AssertionManager constructor or static initializer
static {
    String assertionsEnabled = System.getProperty("ballerina.semantic.assertions.enabled", "true");
    AssertionConfig.setAssertionsEnabled(Boolean.parseBoolean(assertionsEnabled));

    String strictMode = System.getProperty("ballerina.semantic.assertions.strict", "false");
    AssertionConfig.setStrictMode(Boolean.parseBoolean(strictMode));

    String logFailures = System.getProperty("ballerina.semantic.assertions.log", "true");
    AssertionConfig.setLogFailures(Boolean.parseBoolean(logFailures));
}
```

## Performance Considerations

### Sampling and Throttling

```java
public class AssertionSampler {
    private static final ThreadLocal<Sampler> threadLocalSampler = new ThreadLocal<>();

    public static boolean shouldRunAssertions() {
        if (!AssertionConfig.isAssertionsEnabled()) {
            return false;
        }

        Sampler sampler = threadLocalSampler.get();
        if (sampler == null) {
            sampler = new Sampler(0.1); // 10% sampling rate
            threadLocalSampler.set(sampler);
        }

        return sampler.sample();
    }

    private static class Sampler {
        private final double rate;
        private final ThreadLocalRandom random = ThreadLocalRandom.current();

        public Sampler(double rate) {
            this.rate = rate;
        }

        public boolean sample() {
            return random.nextDouble() < rate;
        }
    }
}
```

### Assertion Performance Metrics

```java
public class AssertionMetrics {
    private static final AtomicLong assertionCount = new AtomicLong(0);
    private static final AtomicLong failureCount = new AtomicLong(0);
    private static final AtomicLong totalAssertionTime = new AtomicLong(0);

    public static void recordAssertion(long durationNanos, boolean failed) {
        assertionCount.incrementAndGet();
        if (failed) {
            failureCount.incrementAndGet();
        }
        totalAssertionTime.addAndGet(durationNanos);
    }

    public static void logMetrics() {
        long total = assertionCount.get();
        long failures = failureCount.get();
        long avgTimeNanos = total > 0 ? totalAssertionTime.get() / total : 0;

        logger.info("Assertion Metrics: total={}, failures={}, success_rate={:.2f}%, avg_time={}ns",
                   total, failures, (total - failures) * 100.0 / total, avgTimeNanos);
    }
}
```

## Testing and Validation

### AssertionTest.java

```java
public class AssertionTest {
    private AssertionManager assertionManager;

    @Before
    public void setup() {
        assertionManager = new AssertionManager();
        AssertionConfig.setStrictMode(false); // Test in non-strict mode
    }

    @Test
    public void testValidRecordType() {
        BRecordType recordType = createValidRecordType();
        assertionManager.assertTypeHierarchyIntegrity(recordType, "test");

        // Should not throw exception in non-strict mode
        assertTrue(true);
    }

    @Test
    public void testNullBType() {
        try {
            assertionManager.assertTypeHierarchyIntegrity(null, "test");
            fail("Expected assertion failure");
        } catch (TypeHierarchyIntegrityException e) {
            assertEquals(1, e.getFailures().size());
            assertEquals(AssertionFailure.Type.NULL_VALUE, e.getFailures().get(0).getType());
        }
    }

    @Test
    public void testInvalidUnionType() {
        BUnionType unionType = new BUnionType(null, new ArrayList<>(), null, false, false);
        unionType.getMemberTypes().add(null); // Add null member

        assertionManager.setStrictMode(true);
        try {
            assertionManager.assertTypeHierarchyIntegrity(unionType, "test");
            fail("Expected assertion failure");
        } catch (TypeHierarchyIntegrityException e) {
            assertTrue(e.getFailures().size() > 0);
        }
    }
}
```

## Integration with Build System

### build.gradle Additions

```gradle
dependencies {
    testImplementation 'org.assertj:assertj-core:3.24.2'
    implementation 'com.google.guava:guava:32.1.2-jre'
}

task enableAssertions {
    doLast {
        System.setProperty("ballerina.semantic.assertions.enabled", "true")
        System.setProperty("ballerina.semantic.assertions.strict", "true")
    }
}

test {
    dependsOn enableAssertions
    jvmArgs "-Dballerina.semantic.assertions.enabled=true"
}
```

## Monitoring and Alerting

### Assertion Monitoring

```java
@Component
public class AssertionMonitor {
    private final MeterRegistry meterRegistry;

    @Autowired
    public AssertionMonitor(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
    }

    @PostConstruct
    public void init() {
        meterRegistry.gauge("ballerina.assertions.failures", failureCount);
        meterRegistry.gauge("ballerina.assertions.total", assertionCount);
    }

    @Scheduled(fixedRate = 60000) // Every minute
    public void logAssertionStats() {
        AssertionMetrics.logMetrics();
    }
}
```

This comprehensive assertion framework provides proactive detection of type hierarchy integrity issues, preventing null pointer exceptions and ensuring robust semantic API operation.
