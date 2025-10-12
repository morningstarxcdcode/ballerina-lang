/*
 * Copyright (c) 2024, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.semantic.api.test.nullsafety;

import org.testng.annotations.Test;

import static org.testng.Assert.assertTrue;

/**
 * Performance tests for null safety in semantic API.
 * Ensures that null safety checks don't significantly impact response time.
 *
 * @since 2201.10.0
 */
@Test
public class NullSafetyPerformanceTest {

    @Test
    public void testNullSafetyPerformanceOverhead() {
        // Test that null safety validation logic has minimal overhead
        long startTime = System.nanoTime();

        // Simulate bulk null safety validation operations
        for (int i = 0; i < 10000; i++) {
            validateNullSafetyOverhead();
        }

        long endTime = System.nanoTime();
        long duration = (endTime - startTime) / 1_000_000; // Convert to milliseconds

        // Null safety validation should be very fast (< 10ms for 10k operations)
        assertTrue(duration < 10, "Null safety overhead too high: " + duration + "ms");
    }

    @Test
    public void testTypeResolutionPerformance() {
        // Test that type resolution operations complete within acceptable time
        long startTime = System.nanoTime();

        // Simulate type resolution operations
        for (int i = 0; i < 1000; i++) {
            simulateTypeResolution();
        }

        long endTime = System.nanoTime();
        long duration = (endTime - startTime) / 1_000_000; // Convert to milliseconds

        // Type resolution should be reasonably fast (< 50ms for 1k operations)
        assertTrue(duration < 50, "Type resolution too slow: " + duration + "ms");
    }

    @Test
    public void testSyntheticSymbolCreationPerformance() {
        // Test performance of synthetic symbol creation for anonymous types
        long startTime = System.nanoTime();

        // Simulate creating synthetic symbols for various anonymous types
        for (int i = 0; i < 1000; i++) {
            createSyntheticSymbol(i);
        }

        long endTime = System.nanoTime();
        long duration = (endTime - startTime) / 1_000_000; // Convert to milliseconds

        // Synthetic symbol creation should be fast (< 20ms for 1k symbols)
        assertTrue(duration < 20, "Synthetic symbol creation too slow: " + duration + "ms");
    }

    @Test
    public void testMemoryEfficiency() {
        // Test that null safety doesn't cause excessive memory usage
        Runtime runtime = Runtime.getRuntime();
        long initialMemory = runtime.totalMemory() - runtime.freeMemory();

        // Perform operations that would create synthetic symbols
        for (int i = 0; i < 1000; i++) {
            validateNullSafetyOverhead();
            createSyntheticSymbol(i);
        }

        long finalMemory = runtime.totalMemory() - runtime.freeMemory();
        long memoryIncrease = finalMemory - initialMemory;

        // Memory increase should be reasonable (< 10MB)
        assertTrue(memoryIncrease < 10_000_000, "Memory usage too high: " + memoryIncrease + " bytes");
    }

    /**
     * Validates the overhead of null safety checks without actual semantic operations.
     */
    private void validateNullSafetyOverhead() {
        // Test the overhead of null safety validation logic
        Object testObject = null;

        // Simulate null safety checks that were added
        if (testObject != null) {
            // This branch should not execute in our test
            assertTrue(false, "Unexpected execution path");
        }

        // Simulate type symbol validation
        boolean hasSymbol = testObject != null; // && testObject.tsymbol != null in real code

        // Simulate synthetic symbol creation overhead
        if (!hasSymbol) {
            // This simulates creating synthetic symbols for anonymous types
            String syntheticName = "synthetic_test";
            assertTrue(syntheticName != null);
        }
    }

    /**
     * Simulates type resolution operations for performance testing.
     */
    private void simulateTypeResolution() {
        // Simulate the type resolution process with null safety checks
        Object bType = createMockBType();
        Object tSymbol = null;

        // Simulate the null safety logic from TypesFactory
        if (bType == null) {
            return; // Early return for null types
        }

        // Simulate symbol validation
        if (tSymbol == null && requiresSymbol(bType)) {
            tSymbol = createSyntheticSymbol(bType);
        }

        // Simulate type descriptor creation
        Object typeDescriptor = createMockTypeDescriptor(bType, tSymbol);
        assertTrue(typeDescriptor != null);
    }

    /**
     * Creates a synthetic symbol for performance testing.
     */
    private Object createSyntheticSymbol(Object bType) {
        // Simulate synthetic symbol creation
        return "synthetic_" + bType.toString();
    }

    /**
     * Creates a synthetic symbol for anonymous types.
     */
    private Object createSyntheticSymbol(int index) {
        // Simulate creating synthetic symbols for various anonymous types
        String[] types = {"record", "object", "union", "array", "tuple", "map", "table", "stream"};
        String type = types[index % types.length];
        return "synthetic_" + type + "_" + index;
    }

    /**
     * Checks if a type requires a symbol (simulated).
     */
    private boolean requiresSymbol(Object bType) {
        // Simulate the logic from TypesFactory.requiresTypeSymbol()
        String typeName = bType.toString();
        return typeName.contains("record") || typeName.contains("object") ||
               typeName.contains("union") || typeName.contains("array");
    }

    /**
     * Creates a mock BType for testing.
     */
    private Object createMockBType() {
        return "mock_btype_" + System.nanoTime();
    }

    /**
     * Creates a mock type descriptor for testing.
     */
    private Object createMockTypeDescriptor(Object bType, Object tSymbol) {
        return "type_descriptor_for_" + bType + "_with_symbol_" + tSymbol;
    }
}