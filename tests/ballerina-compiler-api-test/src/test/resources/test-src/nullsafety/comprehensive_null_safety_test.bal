// Copyright (c) 2024, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

// Test source file containing all anonymous type scenarios that previously caused NPE
// This file is used by NullSafetyTest.java to validate comprehensive null safety fixes

import ballerina/io;

// ===== BASIC ANONYMOUS RECORDS =====

public function testBasicAnonymousRecords() {
    // Basic anonymous record creation
    var person = {name: "John", age: 30};
    io:println(person.name);

    // Anonymous record with nested structure
    var nested = {
        user: {id: 1, profile: {name: "Jane"}},
        metadata: {created: "2024-01-01"}
    };
    io:println(nested.user.profile.name);

    // Anonymous record in array
    var records = [
        {id: 1, value: "first"},
        {id: 2, value: "second"}
    ];
    io:println(records[0].value);
}

// ===== MAP INTERSECTIONS AND EQUIVALENT RECORDS =====

public function testMapIntersections() {
    // Map<json> operations that create anonymous records
    map<json> data = {"key1": {"nested": "value1"}, "key2": {"nested": "value2"}};
    var first = data["key1"];
    io:println(first);

    // Map intersection creating equivalent anonymous records
    map<json> source1 = {"a": 1, "b": 2};
    map<json> source2 = {"c": 3, "d": 4};
    var combined = {...source1, ...source2};
    io:println(combined);

    // Complex map operations
    map<map<json>> complex = {
        "level1": {"level2": {"value": "deep"}}
    };
    io:println(complex["level1"]["level2"]);
}

// ===== NESTED ANONYMOUS TYPES =====

public function testNestedAnonymousTypes() {
    // Deeply nested anonymous records
    var deep = {
        level1: {
            level2: {
                level3: {
                    data: "nested value",
                    array: [
                        {item: 1},
                        {item: 2}
                    ]
                }
            }
        }
    };
    io:println(deep.level1.level2.level3.data);

    // Mixed anonymous types
    var mixed = {
        recordField: {name: "record"},
        arrayField: [{id: 1}, {id: 2}],
        mapField: {"key": {nested: "map value"}}
    };
    io:println(mixed.recordField.name);
}

// ===== EXPRESSIONS WITH ANONYMOUS TYPES =====

public function testExpressionsWithAnonymousTypes() {
    // Variable declarations with anonymous types
    var recordVar = {x: 10, y: 20};
    var arrayVar = [{a: 1}, {a: 2}];
    var mapVar = {"key": {value: "test"}};

    // Binary expressions
    var sum = recordVar.x + recordVar.y;
    io:println(sum);

    // Ternary expressions
    var result = true ? {status: "ok"} : {status: "error"};
    io:println(result.status);

    // Type test expressions
    var isRecord = recordVar is record {| int x; int y; |};
    io:println(isRecord);

    // Type cast expressions
    var casted = <record {| int x; int y; |}> recordVar;
    io:println(casted.x);
}

// ===== COLLECTIONS WITH ANONYMOUS TYPES =====

public function testCollectionsWithAnonymousTypes() {
    // Arrays of anonymous records
    var records = [
        {id: 1, data: {value: "first"}},
        {id: 2, data: {value: "second"}},
        {id: 3, data: {value: "third"}}
    ];

    foreach var record in records {
        io:println(record.data.value);
    }

    // Maps with anonymous record values
    map<record {| string name; int age; |}> people = {
        "john": {name: "John", age: 30},
        "jane": {name: "Jane", age: 25}
    };

    io:println(people["john"].name);
}

// ===== FUNCTION CALLS WITH ANONYMOUS ARGUMENTS =====

public function testFunctionCallsWithAnonymousArgs() {
    // Function calls with anonymous record arguments
    processRecord({name: "test", value: 42});
    processArray([{item: 1}, {item: 2}]);
    processMap({"key": {nested: "value"}});
}

function processRecord(record {| string name; int value; |} data) {
    io:println(data.name + ": " + data.value.toString());
}

function processArray(record {| int item; |}[] data) {
    foreach var item in data {
        io:println("Item: " + item.item.toString());
    }
}

function processMap(map<record {| string nested; |}> data) {
    foreach var [key, value] in data.entries() {
        io:println(key + ": " + value.nested);
    }
}

// ===== QUERY EXPRESSIONS =====

public function testQueryExpressions() {
    // Query expressions with anonymous types
    var data = [
        {id: 1, category: "A", value: 10},
        {id: 2, category: "B", value: 20},
        {id: 3, category: "A", value: 30}
    ];

    // Query with anonymous record projection
    var result = from var item in data
                 where item.category == "A"
                 select {id: item.id, doubled: item.value * 2};

    foreach var item in result {
        io:println("ID: " + item.id.toString() + ", Doubled: " + item.doubled.toString());
    }

    // Query with grouping
    var grouped = from var item in data
                  group by item.category
                  select {category: item.category, count: item.length()};

    io:println("Query completed");
}

// ===== LET EXPRESSIONS =====

public function testLetExpressions() {
    var data = [
        {x: 10, y: 20},
        {x: 30, y: 40},
        {x: 50, y: 60}
    ];

    // Let expression with anonymous record
    var result = from var item in data
                 let var sum = item.x + item.y, var record = {total: sum, original: item}
                 where sum > 50
                 select record;

    foreach var item in result {
        io:println("Total: " + item.total.toString());
    }
}

// ===== ERROR HANDLING =====

public function testErrorHandling() {
    // Anonymous records in error contexts
    do {
        var data = {operation: "test", result: {value: 42}};
        check simulateError();
        io:println("Success: " + data.result.value.toString());
    } on fail var e {
        var errorData = {message: e.message(), code: 500};
        io:println("Error: " + errorData.message);
    }
}

function simulateError() returns error? {
    return error("Simulated error");
}

// ===== TYPE DESCRIPTORS AND REFLECTIONS =====

public function testTypeDescriptors() {
    // Anonymous records used with typeof
    var record1 = {a: 1, b: "test"};
    var record2 = {a: 2, b: "other"};

    var type1 = typeof record1;
    var type2 = typeof record2;

    io:println("Types are equivalent: " + (type1 == type2).toString());
}

// ===== OBJECT CONSTRUCTORS =====

public function testObjectConstructors() {
    // Anonymous object constructors
    var obj = object {
        public string name = "Anonymous";
        public int value = 100;

        public function getInfo() returns string {
            return self.name + ": " + self.value.toString();
        }
    };

    io:println(obj.getInfo());

    // Object with anonymous record field
    var complexObj = object {
        public var data = {nested: {value: "complex"}};

        public function getData() returns record {| record {| string value; |} nested; |} {
            return self.data;
        }
    };

    io:println(complexObj.getData().nested.value);
}

// ===== TABLE CONSTRUCTORS =====

public function testTableConstructors() {
    // Table with anonymous record type
    var table = table [
        {id: 1, data: {name: "First", value: 10}},
        {id: 2, data: {name: "Second", value: 20}}
    ];

    foreach var row in table {
        io:println(row.data.name + ": " + row.data.value.toString());
    }
}

// ===== COMPLEX NESTED SCENARIOS =====

public function testComplexNestedScenarios() {
    // Complex nested structure that previously caused NPE
    var complex = {
        metadata: {
            created: "2024-01-01",
            tags: ["tag1", "tag2"]
        },
        data: [
            {
                id: 1,
                attributes: {
                    name: "Item 1",
                    properties: {
                        color: "red",
                        size: "large",
                        specs: {
                            weight: 1.5,
                            dimensions: {width: 10, height: 20}
                        }
                    }
                }
            },
            {
                id: 2,
                attributes: {
                    name: "Item 2",
                    properties: {
                        color: "blue",
                        size: "small",
                        specs: {
                            weight: 0.8,
                            dimensions: {width: 5, height: 10}
                        }
                    }
                }
            }
        ]
    };

    // Access deeply nested anonymous records
    foreach var item in complex.data {
        io:println(item.attributes.name + " - " +
                  item.attributes.properties.specs.dimensions.width.toString());
    }
}

// ===== EDGE CASES =====

public function testEdgeCases() {
    // Empty anonymous records
    var empty = {};
    io:println("Empty record created");

    // Anonymous records with optional fields
    var optional = {required: "value"};
    io:println(optional.required);

    // Anonymous records with union types
    var union = {value: 42}; // could be int|string
    io:println(union.value.toString());

    // Anonymous records in conditional expressions
    var conditional = true ? {type: "success"} : {type: "error"};
    io:println(conditional.type);
}

// ===== PERFORMANCE TEST DATA =====

public function createLargeAnonymousStructure() returns record {| int id; record {| string name; int[] values; |} data; |}[] {
    var result = from int i in 1 ... 1000
                 select {
                     id: i,
                     data: {
                         name: "Item" + i.toString(),
                         values: from int j in 1 ... 10 select j * i
                     }
                 };

    return result;
}

public function testPerformanceScenarios() {
    // Create large anonymous structures for performance testing
    var largeData = createLargeAnonymousStructure();

    // Process the data (this would be monitored for performance)
    var count = 0;
    foreach var item in largeData {
        count += item.data.values.length();
    }

    io:println("Processed " + count.toString() + " values");
}

// ===== MAIN FUNCTION =====

public function main() {
    io:println("=== Comprehensive Null Safety Test Scenarios ===");

    testBasicAnonymousRecords();
    testMapIntersections();
    testNestedAnonymousTypes();
    testExpressionsWithAnonymousTypes();
    testCollectionsWithAnonymousTypes();
    testFunctionCallsWithAnonymousArgs();
    testQueryExpressions();
    testLetExpressions();
    testErrorHandling();
    testTypeDescriptors();
    testObjectConstructors();
    testTableConstructors();
    testComplexNestedScenarios();
    testEdgeCases();
    testPerformanceScenarios();

    io:println("=== All test scenarios completed successfully ===");
}