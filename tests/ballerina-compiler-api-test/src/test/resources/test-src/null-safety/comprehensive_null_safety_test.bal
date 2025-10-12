// Copyright (c) 2024 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

// ===== COMPREHENSIVE NULL SAFETY TEST SOURCE =====
// This file contains all scenarios that previously caused NPE in semantic API
// due to anonymous types and missing type symbols

function testNullSafety() {
    // ===== BASIC ANONYMOUS RECORDS =====

    // Anonymous record in variable assignment
    record {|
        string name;
        int age;
    |} person = {name: "John Doe", age: 20};

    // Anonymous record in variable declaration
    var anonymousPerson = {
        name: "Jane Doe",
        age: 25,
        address: {
            street: "123 Main St",
            city: "Colombo"
        }
    };

    // ===== MAP INTERSECTIONS (PREVIOUSLY MAJOR NPE CAUSE) =====

    // Map type that creates equivalent records internally
    map<string> stringMap = {};
    map<int> intMap = {};
    map<json> jsonMap = {};

    // Complex map operations that create anonymous equivalent records
    map<record {| string name; int value; |}> complexMap = {};

    // ===== NESTED ANONYMOUS TYPES =====

    // Deeply nested anonymous records
    var nestedData = {
        metadata: {
            created: "2024-01-01",
            tags: ["test", "demo"],
            config: {
                enabled: true,
                settings: {
                    timeout: 5000,
                    retries: 3
                }
            }
        },
        payload: {
            type: "message",
            content: {
                text: "Hello World",
                attachments: [
                    {
                        filename: "test.txt",
                        size: 1024,
                        metadata: {
                            uploaded: true,
                            checksum: "abc123"
                        }
                    }
                ]
            }
        }
    };

    // ===== FUNCTION CALLS WITH ANONYMOUS ARGUMENTS =====

    // Function calls with anonymous record arguments
    processRecord({
        id: 123,
        data: "test",
        metadata: {
            source: "api",
            timestamp: 1234567890
        }
    });

    // Method calls on anonymous objects
    var calculator = object {
        function add(int a, int b) returns int {
            return a + b;
        }
    };

    int result = calculator.add(5, 3);

    // ===== COLLECTIONS WITH ANONYMOUS ELEMENTS =====

    // Arrays with anonymous record elements
    record {| string name; int score; |}[] students = [
        {name: "Alice", score: 95},
        {name: "Bob", score: 87},
        {name: "Charlie", score: 92}
    ];

    // Tuples with mixed anonymous types
    [record {| string type; anydata value; |}, int, string] mixedTuple = [
        {type: "number", value: 42},
        100,
        "test"
    ];

    // Tables with anonymous record constraints
    table<record {| readonly string id; string name; int age; |}> personTable = table [
        {id: "1", name: "John", age: 30},
        {id: "2", name: "Jane", age: 25}
    ];

    // ===== EXPRESSIONS WITH ANONYMOUS TYPES =====

    // Binary expressions
    boolean isAdult = anonymousPerson.age >= 18;
    string fullName = anonymousPerson.name + " (Adult: " + isAdult.toString() + ")";

    // Unary expressions
    int age = anonymousPerson.age;
    boolean isValidAge = ! (age < 0);

    // Conditional expressions
    string status = age >= 18 ? "adult" : "minor";
    var complexStatus = age >= 18 ? {category: "adult", canVote: true} : {category: "minor", canVote: false};

    // ===== TYPE OPERATIONS =====

    // Type test expressions
    boolean isRecordType = anonymousPerson is record {| string name; int age; anydata...; |};
    boolean isMapType = jsonMap is map<json>;

    // Type cast expressions
    record {| string name; int age; |} castPerson = <record {| string name; int age; |}> anonymousPerson;

    // Typeof expressions
    typedesc<anydata> personType = typeof anonymousPerson;
    typedesc<map<json>> mapType = typeof jsonMap;

    // ===== QUERY EXPRESSIONS =====

    // Query expressions with anonymous types
    var adultStudents = from var student in students
                        where student.score >= 90
                        select {
                            name: student.name,
                            grade: student.score >= 95 ? "A" : "B",
                            status: "passed"
                        };

    // ===== LET EXPRESSIONS =====

    // Let expressions with anonymous bindings
    var enrichedData = let var metadata = {source: "test", version: "1.0"}
                       in {
                           data: nestedData,
                           metadata: metadata,
                           timestamp: 1234567890
                       };

    // ===== ERROR AND OBJECT CONSTRUCTORS =====

    // Error constructors with anonymous details
    error customError = error("CustomError", message = "Something went wrong",
                             details = {
                                 code: 500,
                                 timestamp: 1234567890,
                                 context: {
                                     operation: "test",
                                     user: "anonymous"
                                 }
                             });

    // Anonymous object constructors
    var validator = object {
        function validate(record {| string name; int age; |} person) returns boolean {
            return person.name.length() > 0 && person.age >= 0;
        }
    };

    // ===== TEMPLATES AND SPECIAL EXPRESSIONS =====

    // String templates with anonymous expressions
    string report = string `Person: ${anonymousPerson.name}, Age: ${anonymousPerson.age},
                           Address: ${anonymousPerson.address.city}`;

    // XML templates
    xml reportXml = xml `<report>
                            <person>
                                <name>${anonymousPerson.name}</name>
                                <age>${anonymousPerson.age}</age>
                            </person>
                         </report>`;

    // ===== TRAP AND CHECK EXPRESSIONS =====

    // Check expressions
    var safeResult = check getSafeValue();

    // Trap expressions
    var trappedResult = trap getUnsafeValue();

    // ===== INDEXING AND FIELD ACCESS =====

    // Field access on anonymous records
    string personName = anonymousPerson.name;
    string cityName = anonymousPerson.address.city;

    // Optional field access
    string? optionalField = anonymousPerson?.optionalField;

    // Array indexing
    record {| string name; int score; |} firstStudent = students[0];
    int firstScore = students[0].score;

    // Map indexing
    jsonMap["key"] = {nested: {value: 42}};

    // ===== REGEXP CONSTRUCTORS =====

    // Regexp constructors
    string:RegExp emailPattern = re `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`;

    // ===== EDGE CASES =====

    // Empty anonymous records
    var emptyRecord = {};

    // Records with optional fields
    var optionalRecord = {
        required: "value",
        optional?: "maybe"
    };

    // Union types with anonymous records
    record {| string type; anydata data; |} | record {| string error; string message; |} response =
        {type: "success", data: {result: "ok"}};

    // Intersection types (previously major NPE cause)
    record {| string name; |} & record {| int id; |} intersectedRecord = {name: "test", id: 123};

    // Complex union types
    (record {| string text; |} | record {| int number; |} | record {| boolean flag; |}) unionValue =
        {text: "hello"};

    // ===== PERFORMANCE TEST DATA =====

    // Large arrays of anonymous records for performance testing
    record {| int id; string name; record {| string city; string country; |} address; |}[] largeDataset = [];

    // Generate test data
    foreach int i in 0 ..< 100 {
        largeDataset.push({
            id: i,
            name: "Person" + i.toString(),
            address: {
                city: "City" + i.toString(),
                country: "Country" + (i % 10).toString()
            }
        });
    }
}

// ===== HELPER FUNCTIONS =====

function processRecord(record {| int id; string data; anydata...; |} rec) returns string {
    return string `Processed record ${rec.id}: ${rec.data}`;
}

function getSafeValue() returns int|error {
    return 42;
}

function getUnsafeValue() returns int {
    // This might throw an error in real scenarios
    return 0;
}

// ===== ADDITIONAL TEST FUNCTIONS =====

function testComplexAnonymousTypes() {
    // Test complex anonymous types in function parameters and returns

    // Function with anonymous record parameter
    function processComplexData(record {|
        string operation;
        record {|
            string source;
            int timestamp;
        |} metadata;
        anydata payload;
    |} data) returns record {| string status; anydata result; |} {

        return {
            status: "processed",
            result: {
                operation: data.operation,
                processedAt: data.metadata.timestamp + 1000
            }
        };
    }

    // Call with anonymous record argument
    var result = processComplexData({
        operation: "test",
        metadata: {
            source: "unit_test",
            timestamp: 1234567890
        },
        payload: {
            data: "test payload",
            config: {
                retries: 3,
                timeout: 5000
            }
        }
    });
}

function testAnonymousTypeInControlFlow() {
    // Test anonymous types in various control flow constructs

    var data = {
        type: "conditional",
        value: 42,
        metadata: {
            created: "test",
            version: 1.0
        }
    };

    // If statements
    if data.type == "conditional" {
        var processed = {
            original: data,
            result: data.value * 2,
            status: "processed"
        };
    }

    // Match statements
    match data.type {
        "conditional" => {
            var matched = {
                matchedType: data.type,
                doubledValue: data.value * 2
            };
        }
        _ => {
            var defaultCase = {
                type: "unknown",
                original: data
            };
        }
    }

    // While loops with anonymous types
    var counter = 0;
    while counter < 3 {
        var iteration = {
            count: counter,
            data: data,
            timestamp: counter * 1000
        };
        counter += 1;
    }
}

function testAnonymousTypesInErrorHandling() {
    // Test anonymous types in error handling scenarios

    // Try-catch with anonymous error details
    do {
        var operation = {
            name: "test_operation",
            params: {
                input: "test",
                config: {timeout: 1000}
            }
        };

        // Simulate error
        if operation.params.input == "test" {
            fail error("TestError",
                  message = "Test error occurred",
                  details = {
                      operation: operation.name,
                      params: operation.params,
                      timestamp: 1234567890
                  });
        }

    } on fail error err {
        var errorContext = {
            error: err,
            context: {
                operation: "error_handling_test",
                timestamp: 1234567890
            },
            recovery: {
                action: "log_and_continue",
                severity: "low"
            }
        };
    }
}