Phase 2: Root Cause Analysis

6. Debug this null pointer exception step by step: analyze the stack trace and identify the exact line causing the issue

Based on code analysis, the NPE occurs in AbstractStructuredTypeSymbol.getLocation() at line:
```java
return Optional.of(this.getBType().tsymbol.pos);
```

When this.getBType().tsymbol is null, accessing .pos causes NullPointerException.

Root cause: The semantic API creates TypeSymbol instances for BType objects that have tsymbol = null.
This happens with temporary/internal types like equivalent record types created for map intersections.

7. Examine the type checker implementation for anonymous types - what validation checks are missing for null parent references?

The issue is not specific to anonymous types but affects any BType with null tsymbol.
Missing validation: No null check for tsymbol before accessing its properties.

8. Compare how other language compilers (TypeScript, Scala, Kotlin) handle anonymous type resolution without null pointer exceptions

Other compilers typically:
- Use proper null checks and defensive programming
- Have consistent symbol table management
- Avoid creating incomplete type objects
- Use Optional/nullable types for potentially missing information

9. Generate defensive null checks for the getType semantic API method to prevent crashes on anonymous types

Fixed in AbstractStructuredTypeSymbol.getLocation():
```java
@Override
public Optional<Location> getLocation() {
    return this.getBType().tsymbol != null ? Optional.of(this.getBType().tsymbol.pos) : Optional.empty();
}
```

10. Create a flowchart showing the type resolution process and where null parent handling should be added

```
Type Resolution Flow:
1. User calls SemanticModel.typeOf(node)
   ↓
2. BallerinaSemanticModel.typeOf() calls nodeFinder.lookup()
   ↓
3. Gets BLangNode, calls getDeterminedType()
   ↓
4. Calls typesFactory.getTypeDescriptor(determinedType)
   ↓
5. TypesFactory.getTypeDescriptor() checks if type reference
   ↓
6. If not type reference, calls createTypeDescriptor(bType, tSymbol)
   ↓
7. For RECORD, creates BallerinaRecordTypeSymbol(context, bType)
   ↓
8. BallerinaRecordTypeSymbol extends AbstractStructuredTypeSymbol
   ↓
9. AbstractStructuredTypeSymbol.getLocation() accesses bType.tsymbol.pos
   ↓
   ❌ NPE if bType.tsymbol == null

Fix: Add null check in AbstractStructuredTypeSymbol.getLocation()
```