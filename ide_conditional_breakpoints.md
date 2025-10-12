# IDE Conditional Breakpoints: Anonymous Type NPE Detection

## Overview

This guide provides conditional breakpoint configurations for IntelliJ IDEA and VS Code to automatically catch null pointer exceptions specifically in anonymous type processing within the Ballerina semantic API.

## IntelliJ IDEA Breakpoint Configuration

### Breakpoint 1: AbstractStructuredTypeSymbol.getLocation() NPE

**File:** `AbstractStructuredTypeSymbol.java`
**Line:** 42 (in `getLocation()` method)

**Conditional Expression:**
```java
this.getBType().tsymbol == null
```

**Breakpoint Settings:**
- Suspend: Thread
- Condition: `this.getBType().tsymbol == null`
- Log message: "NPE detected: Anonymous type {this.getBType().getKind()} lacks symbol"
- Remove once hit: false
- Disable after hit: false

### Breakpoint 2: TypesFactory.getTypeDescriptor() Null Symbol

**File:** `TypesFactory.java`
**Line:** 167 (in `getTypeDescriptor()` method)

**Conditional Expression:**
```java
tSymbol == null && requiresTypeSymbol(bType)
```

**Breakpoint Settings:**
- Suspend: Thread
- Condition: `tSymbol == null && requiresTypeSymbol(bType)`
- Log message: "Null symbol for structured type: {bType.getKind()}"
- Evaluate and log: `bType.getKind().toString()`

### Breakpoint 3: BallerinaSemanticModel Type Resolution Failure

**File:** `BallerinaSemanticModel.java`
**Line:** 737 (in `resolveTypeSafely()` method)

**Conditional Expression:**
```java
bType != null && bType.tsymbol == null
```

**Breakpoint Settings:**
- Suspend: Thread
- Condition: `bType != null && bType.tsymbol == null`
- Log message: "Type resolution for anonymous {bType.getKind()}"
- Evaluate and log: `bType.toString()`

## VS Code Breakpoint Configuration

### Launch Configuration (`.vscode/launch.json`)

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "type": "java",
            "name": "Debug Ballerina Compiler - Anonymous Types",
            "request": "launch",
            "mainClass": "io.ballerina.cli.launcher.Main",
            "args": ["build"],
            "vmArgs": [
                "-Xdebug",
                "-Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=5005",
                "-Dballerina.semantic.debug=true",
                "-Dballerina.semantic.traceAnonymousTypes=true"
            ],
            "env": {
                "BALLERINA_DEBUG": "true",
                "ANONYMOUS_TYPE_DEBUG": "true"
            }
        }
    ]
}
```

### VS Code Conditional Breakpoints

**File:** `AbstractStructuredTypeSymbol.java`
**Line:** 42

```javascript
// VS Code condition expression
this.getBType().tsymbol === null
```

**Hit Condition:** `>0`

**Log Message:** `"Anonymous type NPE: ${this.getBType().getKind()}"`

## Eclipse Breakpoint Configuration

### Conditional Breakpoints

**Breakpoint 1:** `AbstractStructuredTypeSymbol.getLocation()`

```
Condition: this.getBType().tsymbol == null
Suspend when: True
```

**Breakpoint 2:** `TypesFactory.getTypeDescriptor()`

```
Condition: tSymbol == null && requiresTypeSymbol(bType)
Suspend when: True
```

## Advanced Conditional Breakpoints

### Breakpoint: Complex Anonymous Type Detection

**File:** `TypesFactory.java`
**Line:** 185 (in `createSyntheticTypeSymbol()`)

**Condition:**
```java
// Break only for RECORD types that should have had symbols
bType.getKind() == org.wso2.ballerinalang.compiler.util.TypeTags.RECORD &&
bType.toString().contains("{") &&
bType.toString().contains("}")
```

### Breakpoint: Map Intersection Anonymous Types

**File:** `TypesFactory.java`
**Line:** 167

**Condition:**
```java
// Break on map intersection results
tSymbol == null &&
bType.toString().contains("map") &&
bType.toString().contains("&")
```

### Breakpoint: Nested Anonymous Structure

**File:** `TypesFactory.java`
**Line:** 449 (in `validateAndInitializeTypeParents()`)

**Condition:**
```java
// Break on deeply nested anonymous structures
bType.getKind() == org.wso2.ballerinalang.compiler.util.TypeTags.RECORD &&
countNestedAnonymousTypes(bType) > 2
```

**Helper Method (add to debug watch):**
```java
private int countNestedAnonymousTypes(BType bType) {
    if (!(bType instanceof BRecordType)) return 0;
    BRecordType recordType = (BRecordType) bType;
    int count = 0;
    if (recordType.fields != null) {
        for (BField field : recordType.fields.values()) {
            if (field.type.tsymbol == null && requiresTypeSymbol(field.type)) {
                count++;
                count += countNestedAnonymousTypes(field.type);
            }
        }
    }
    return count;
}
```

## Breakpoint Management

### Breakpoint Groups

Create breakpoint groups for different debugging scenarios:

**Group 1: Basic NPE Detection**
- AbstractStructuredTypeSymbol.getLocation()
- TypesFactory.getTypeDescriptor() null symbol

**Group 2: Advanced Type Resolution**
- BallerinaSemanticModel.resolveTypeSafely()
- TypesFactory.validateAndInitializeTypeParents()

**Group 3: Synthetic Symbol Creation**
- TypesFactory.createSyntheticTypeSymbol()
- TypesFactory.ensureTypeSymbol()

### Breakpoint Activation Scripts

**Enable Anonymous Type Debugging:**
```bash
# Enable all anonymous type breakpoints
export ANONYMOUS_TYPE_DEBUG=true
export BALLERINA_SEMANTIC_DEBUG=true
```

**Disable for Performance:**
```bash
# Disable breakpoints for normal development
unset ANONYMOUS_TYPE_DEBUG
unset BALLERINA_SEMANTIC_DEBUG
```

## Debugging Workflow

### Step 1: Set Up Breakpoints
1. Open the files listed above
2. Set conditional breakpoints with the expressions provided
3. Enable breakpoint groups as needed

### Step 2: Reproduce the Issue
1. Create a Ballerina file with anonymous types:
   ```ballerina
   public function testAnonymous() {
       var person = {name: "John", age: 30}; // This should trigger breakpoint
       // Use semantic API here
   }
   ```

2. Run compilation or semantic analysis

### Step 3: Analyze Breakpoint Hits
1. When breakpoint hits, examine the call stack
2. Check the `bType` object state
3. Look for missing `tsymbol` references
4. Identify where the symbol should have been created

### Step 4: Collect Debug Information
```java
// Add to watch expressions
bType.getKind()
bType.tsymbol  // Should be null
bType.toString()
Thread.currentThread().getStackTrace()
```

## Common Breakpoint Scenarios

### Scenario 1: Simple Anonymous Record
**Trigger:** `var data = {id: 1, value: "test"};`
**Expected Breakpoint:** `AbstractStructuredTypeSymbol.getLocation()`
**Analysis:** Symbol missing for basic anonymous record

### Scenario 2: Map Intersection
**Trigger:** `map<json> & readonly`
**Expected Breakpoint:** `TypesFactory.getTypeDescriptor()`
**Analysis:** Intersection creates anonymous equivalent record

### Scenario 3: Nested Anonymous Types
**Trigger:**
```ballerina
var nested = {
    user: {profile: {name: "John"}},
    data: [{item: 1}, {item: 2}]
};
```
**Expected Breakpoint:** `validateAndInitializeTypeParents()`
**Analysis:** Multiple levels of anonymous type nesting

### Scenario 4: Function Call with Anonymous Args
**Trigger:** `processData({name: "test", value: 42})`
**Expected Breakpoint:** `resolveTypeSafely()`
**Analysis:** Anonymous argument type resolution

## Troubleshooting Breakpoints

### Breakpoint Not Hitting
**Issue:** Conditional breakpoint never triggers
**Solutions:**
1. Verify condition syntax is correct
2. Check that the code path is being executed
3. Ensure debug symbols are available
4. Try unconditional breakpoint first

### Performance Impact
**Issue:** Breakpoints slow down execution significantly
**Solutions:**
1. Use hit counts to limit breaks
2. Enable breakpoints only when needed
3. Use log-only breakpoints instead of suspending

### IDE-Specific Issues
**IntelliJ IDEA:**
- Ensure "Debug" configuration is used
- Check "Evaluate and log" expressions are valid

**VS Code:**
- Verify Java extension is installed
- Check launch.json configuration

**Eclipse:**
- Ensure JDT is properly configured
- Check conditional expression syntax

## Integration with Logging

Combine breakpoints with logging for comprehensive debugging:

```java
// Add debug logging alongside breakpoints
if (bType.tsymbol == null) {
    logger.debug("Anonymous type detected: {} with kind: {}",
                 bType, bType.getKind());
    // Breakpoint will trigger here
}
```

This breakpoint configuration provides comprehensive coverage for detecting and debugging null pointer exceptions in anonymous type processing, allowing developers to identify the exact conditions and code paths where NPEs occur.</content>
<parameter name="filePath">/Users/morningstar/Downloads/ballerina-lang-master/ide_conditional_breakpoints.md