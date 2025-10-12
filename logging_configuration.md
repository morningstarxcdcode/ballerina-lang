# Logging Configuration: Anonymous Type Execution Path Tracing



## Overview



This configuration provides comprehensive logging setup to trace the complete execution path leading to null pointer exceptions in anonymous type processing, enabling detailed debugging and root cause analysis.



## Logback Configuration



### logback.xml for Ballerina Compiler




```xml
<?xml version="1.0" encoding="UTF-8"?>

<configuration>

    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">

        <encoder>

            <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>

        </encoder>

    </appender>



    <appender name="ANONYMOUS_TYPE_FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">

        <file>logs/anonymous_type_debug.log</file>

        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">

            <fileNamePattern>logs/anonymous_type_debug.%d{yyyy-MM-dd}.%i.log</fileNamePattern>

            <maxFileSize>10MB</maxFileSize>

            <maxHistory>30</maxHistory>

            <totalSizeCap>1GB</totalSizeCap>

        </rollingPolicy>

        <encoder>

            <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{50} - %msg%n

                    %X{bTypeId} %X{symbolStatus} %X{callStack}%n</pattern>

        </encoder>

    </appender>



    <!-- Anonymous Type Processing Logger -->

    <logger name="io.ballerina.compiler.api.impl.symbols.TypesFactory" level="DEBUG" additivity="false">

        <appender-ref ref="ANONYMOUS_TYPE_FILE"/>

    </logger>



    <logger name="io.ballerina.compiler.api.impl.symbols.AbstractStructuredTypeSymbol" level="DEBUG" additivity="false">

        <appender-ref ref="ANONYMOUS_TYPE_FILE"/>

    </logger>



    <logger name="io.ballerina.compiler.api.impl.BallerinaSemanticModel" level="DEBUG" additivity="false">

        <appender-ref ref="ANONYMOUS_TYPE_FILE"/>

    </logger>



    <!-- Semantic API Calls -->

    <logger name="io.ballerina.compiler.api.impl" level="TRACE" additivity="false">

        <appender-ref ref="ANONYMOUS_TYPE_FILE"/>

    </logger>



    <!-- Root logger -->

    <root level="INFO">

        <appender-ref ref="STDOUT"/>

    </root>

</configuration>


```


## MDC (Mapped Diagnostic Context) Setup



### Add to TypesFactory.java




```java
import org.slf4j.MDC;

import java.util.UUID;



// Add MDC context for anonymous type processing

private void setupAnonymousTypeMDC(BType bType, String operation) {

    MDC.put("bTypeId", getBTypeId(bType));

    MDC.put("symbolStatus", getSymbolStatus(bType));

    MDC.put("operation", operation);

    MDC.put("callStack", getCallStackSummary());

}



private void clearAnonymousTypeMDC() {

    MDC.remove("bTypeId");

    MDC.remove("symbolStatus");

    MDC.remove("operation");

    MDC.remove("callStack");

}



private String getBTypeId(BType bType) {

    return bType.getClass().getSimpleName() + "@" +

           Integer.toHexString(System.identityHashCode(bType));

}



private String getSymbolStatus(BType bType) {

    if (bType.tsymbol == null) {

        return "NULL_SYMBOL";

    } else if (bType.tsymbol.origin == SymbolOrigin.VIRTUAL) {

        return "SYNTHETIC_SYMBOL";

    } else {

        return "REAL_SYMBOL";

    }

}



private String getCallStackSummary() {

    StackTraceElement[] stack = Thread.currentThread().getStackTrace();

    StringBuilder summary = new StringBuilder();

    for (int i = 3; i < Math.min(8, stack.length); i++) {

        if (i > 3) summary.append(" <- ");

        summary.append(stack[i].getMethodName());

    }

    return summary.toString();

}


```


### Enhanced Logging in Key Methods



**TypesFactory.getTypeDescriptor():**




```java
public TypeSymbol getTypeDescriptor(BType bType, BSymbol tSymbol, boolean rawTypeOnly) {

    setupAnonymousTypeMDC(bType, "getTypeDescriptor");



    logger.debug("Starting type descriptor resolution for {}", bType);



    if (bType == null) {

        logger.warn("Null BType provided to getTypeDescriptor");

        clearAnonymousTypeMDC();

        return null;

    }



    logger.debug("BType kind: {}, symbol status: {}", bType.getKind(), getSymbolStatus(bType));



    // Handle types with null symbols

    if (tSymbol == null && requiresTypeSymbol(bType)) {

        logger.info("Creating synthetic symbol for anonymous type {}", bType.getKind());

        tSymbol = createSyntheticTypeSymbol(bType);

    }



    try {

        if (isTypeReference(bType, tSymbol, rawTypeOnly)) {

            logger.debug("Creating type reference for {}", bType);

            TypeSymbol result = new BallerinaTypeReferenceTypeSymbol(context, bType, tSymbol, false);

            logger.debug("Type reference created successfully");

            return result;

        }



        BTypeSymbol typeSymbol = tSymbol instanceof BTypeDefinitionSymbol ? tSymbol.type.tsymbol : (BTypeSymbol) tSymbol;

        TypeSymbol result = createTypeDescriptor(bType, typeSymbol);

        logger.debug("Type descriptor created: {}", result);

        return result;



    } catch (Exception e) {

        logger.error("Failed to create type descriptor for {}: {}", bType, e.getMessage(), e);

        return null;

    } finally {

        clearAnonymousTypeMDC();

    }

}


```


**AbstractStructuredTypeSymbol.getLocation():**




```java
@Override

public Optional<Location> getLocation() {

    BType bType = this.getBType();

    setupAnonymousTypeMDC(bType, "getLocation");



    logger.debug("Getting location for structured type {}", bType);



    if (bType.tsymbol == null) {

        logger.warn("Attempting to get location for anonymous type without symbol: {}", bType);

        clearAnonymousTypeMDC();

        return Optional.empty();

    }



    Optional<Location> location = Optional.of(bType.tsymbol.pos);

    logger.debug("Location resolved: {}", location.map(Location::toString).orElse("null"));

    clearAnonymousTypeMDC();

    return location;

}


```


## Log Analysis Tools



### Log Parser Script



**parse_anonymous_type_logs.sh:**




```bash
#!/bin/bash

# Parse anonymous type debug logs for patterns and issues



LOG_FILE=${1:-"logs/anonymous_type_debug.log"}



echo "=== Anonymous Type Log Analysis ==="

echo "Log file: $LOG_FILE"

echo



# Count NPE occurrences

echo "NPE Occurrences:"

grep -c "NULL_SYMBOL" "$LOG_FILE" || echo "0"



# Count synthetic symbol creations

echo "Synthetic Symbol Creations:"

grep -c "SYNTHETIC_SYMBOL" "$LOG_FILE" || echo "0"



# Find problematic type patterns

echo

echo "Problematic Type Patterns:"

grep "NULL_SYMBOL" "$LOG_FILE" | head -10



# Analyze call stacks

echo

echo "Common Call Stacks:"

grep "callStack=" "$LOG_FILE" | sed 's/.*callStack=//' | sort | uniq -c | sort -nr | head -5



# Check for memory issues

echo

echo "Memory-related Issues:"

grep -i "memory\|leak\|gc" "$LOG_FILE" | head -5



# Generate summary report

echo

echo "=== Summary Report ==="

echo "Total log entries: $(wc -l < "$LOG_FILE")"

echo "Anonymous type operations: $(grep -c "bTypeId=" "$LOG_FILE")"

echo "Failed operations: $(grep -c "Failed to\|Exception\|Error" "$LOG_FILE")"


```


### Log Pattern Analysis



**Error Pattern Detection:**




```bash
# Find NPE patterns

grep "NULL_SYMBOL.*getLocation" "$LOG_FILE"



# Find synthetic symbol creation failures

grep "Failed to create.*synthetic" "$LOG_FILE"



# Find recursive type validation issues

grep "validateAndInitializeTypeParents.*failed" "$LOG_FILE"


```


### Performance Analysis



**Log Performance Metrics:**




```bash
# Count operations per second

echo "Operations per second:"

grep "Starting type descriptor" "$LOG_FILE" |

  awk '{print $1}' |

  sort |

  uniq -c |

  awk '{sum += $1} END {print sum/NR " ops/sec"}'



# Find slow operations (>100ms)

echo "Slow operations:"

grep "type descriptor resolution" "$LOG_FILE" |

  # Parse timestamps and calculate duration

  awk '{

    curr_time = $1

    getline

    next_time = $1

    # Calculate duration in milliseconds

    # Print if duration > 100ms

  }'


```


## Runtime Tracing Configuration



### JVM Tracing Flags



**JVM Arguments for Detailed Tracing:**


```bash
# Method entry/exit tracing

-XX:+TraceMethodEntry

-XX:+TraceMethodExit



# Class loading tracing

-XX:+TraceClassLoading

-XX:+TraceClassUnloading



# JIT compilation tracing

-XX:+PrintCompilation

-XX:+PrintInlining



# Anonymous type specific tracing

-Dballerina.semantic.traceAnonymousTypes=true

-Dballerina.semantic.logLevel=TRACE


```


### Aspect-Oriented Tracing



**Add to build.gradle for AOP tracing:**


```gradle
dependencies {

    aspectj 'org.aspectj:aspectjrt:1.9.7'

    aspectj 'org.aspectj:aspectjweaver:1.9.7'

}



task weaveAnonymousTypeAspects(type: JavaExec) {

    classpath = sourceSets.main.runtimeClasspath

    main = 'org.aspectj.tools.ant.taskdefs.Ajc11'

    args = [

        '-inpath', sourceSets.main.output.classesDirs.asPath,

        '-aspectpath', configurations.aspectj.asPath,

        '-outpath', file("$buildDir/weavedClasses"),

        '-source', '11'

    ]

}


```


**AnonymousTypeTracingAspect.java:**


```java
@Aspect

public class AnonymousTypeTracingAspect {



    @Pointcut("execution(* io.ballerina.compiler.api.impl.symbols.TypesFactory.getTypeDescriptor(..))")

    public void typeDescriptorCreation() {}



    @Before("typeDescriptorCreation()")

    public void beforeTypeDescriptorCreation(JoinPoint joinPoint) {

        Object[] args = joinPoint.getArgs();

        if (args.length > 0 && args[0] instanceof BType) {

            BType bType = (BType) args[0];

            logger.info("Entering getTypeDescriptor for {} with symbol status: {}",

                       bType, getSymbolStatus(bType));

        }

    }



    @AfterReturning(pointcut = "typeDescriptorCreation()", returning = "result")

    public void afterTypeDescriptorCreation(JoinPoint joinPoint, Object result) {

        logger.info("Type descriptor created: {}", result);

    }



    @AfterThrowing(pointcut = "typeDescriptorCreation()", throwing = "ex")

    public void onTypeDescriptorException(JoinPoint joinPoint, Exception ex) {

        logger.error("Exception in getTypeDescriptor: {}", ex.getMessage(), ex);

    }

}


```


## Log Correlation and Analysis



### Correlation ID Generation



**Add to BallerinaSemanticModel.java:**


```java
private static final ThreadLocal<String> CORRELATION_ID = new ThreadLocal<>();



private String getCorrelationId() {

    String id = CORRELATION_ID.get();

    if (id == null) {

        id = UUID.randomUUID().toString().substring(0, 8);

        CORRELATION_ID.set(id);

    }

    return id;

}



private void setupCorrelationId() {

    MDC.put("correlationId", getCorrelationId());

}



private void clearCorrelationId() {

    CORRELATION_ID.remove();

    MDC.remove("correlationId");

}


```


### Distributed Tracing Integration



**OpenTelemetry Integration:**


```java
import io.opentelemetry.api.trace.Span;

import io.opentelemetry.api.trace.Tracer;



// Add tracing spans for anonymous type operations

private Span startAnonymousTypeSpan(String operation, BType bType) {

    return tracer.spanBuilder("anonymous_type." + operation)

        .setAttribute("bType.kind", bType.getKind().toString())

        .setAttribute("bType.symbolStatus", getSymbolStatus(bType))

        .startSpan();

}



// Use in key methods

public TypeSymbol getTypeDescriptor(BType bType, BSymbol tSymbol) {

    Span span = startAnonymousTypeSpan("getTypeDescriptor", bType);

    try {

        // ... existing logic

        span.setAttribute("result.success", true);

        return result;

    } catch (Exception e) {

        span.recordException(e);

        span.setAttribute("result.success", false);

        throw e;

    } finally {

        span.end();

    }

}


```


## Log Rotation and Management



### Log Rotation Configuration



**Enhanced logback.xml:**


```xml
<appender name="ANONYMOUS_TYPE_FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">

    <file>logs/anonymous_type_debug.log</file>

    <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">

        <fileNamePattern>logs/anonymous_type_debug.%d{yyyy-MM-dd}.%i.gz</fileNamePattern>

        <maxFileSize>50MB</maxFileSize>

        <maxHistory>90</maxHistory>

        <totalSizeCap>5GB</totalSizeCap>

    </rollingPolicy>



    <!-- Compression -->

    <compression>true</compression>



    <!-- Pruning -->

    <prune>true</prune>

    <pruneInterval>1 hour</pruneInterval>

</appender>


```


### Log Archival and Cleanup



**Automated Log Management:**


```bash
#!/bin/bash

# cleanup_anonymous_type_logs.sh



LOG_DIR="logs"

RETENTION_DAYS=30

MAX_TOTAL_SIZE="10G"



# Remove old logs

find "$LOG_DIR" -name "anonymous_type_debug.*.gz" -mtime +$RETENTION_DAYS -delete



# Check total size and prune if needed

TOTAL_SIZE=$(du -sh "$LOG_DIR" | cut -f1)

if [[ $(numfmt --from=iec "$TOTAL_SIZE") -gt $(numfmt --from=iec "$MAX_TOTAL_SIZE") ]]; then

    echo "Log size exceeded $MAX_TOTAL_SIZE, pruning oldest files..."

    # Prune oldest files until under limit

    find "$LOG_DIR" -name "anonymous_type_debug.*.gz" -printf '%T@ %p\n' |

        sort -n |

        head -n 10 |

        cut -d' ' -f2- |

        xargs rm -f

fi


```


## Integration with Monitoring Systems



### ELK Stack Integration



**Logstash Configuration:**


```conf
input {

  file {

    path => "/path/to/ballerina/logs/anonymous_type_debug.log"

    start_position => "beginning"

  }

}



filter {

  grok {

    match => { "message" => "%{TIMESTAMP_ISO8601:timestamp} \[%{DATA:thread}\] %{LOGLEVEL:level} %{DATA:logger} - %{GREEDYDATA:message}" }

  }



  kv {

    source => "mdc"

    field_split => " "

    value_split => "="

  }



  mutate {

    add_field => {

      "service" => "ballerina-compiler"

      "component" => "anonymous-type-processing"

    }

  }

}



output {

  elasticsearch {

    hosts => ["localhost:9200"]

    index => "ballerina-anonymous-type-%{+YYYY.MM.dd}"

  }

}


```


### Kibana Dashboard Configuration



**Sample Kibana Queries:**


```json
{

  "query": {

    "bool": {

      "must": [

        { "match": { "component": "anonymous-type-processing" } },

        { "match": { "level": "ERROR" } }

      ]

    }

  }

}


```


This comprehensive logging configuration provides complete visibility into the execution path of anonymous type processing, enabling precise identification and resolution of null pointer exceptions and performance issues.
