// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;

@test:Config {
    groups: ["department", "in-memory"]
}
function inMemoryDepartmentCreateTest() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    string[] deptNos = check rainierClient->/departments.post([department1]);
    test:assertEquals(deptNos, [department1.deptNo]);

    Department departmentRetrieved = check rainierClient->/departments/[department1.deptNo].get();
    test:assertEquals(departmentRetrieved, department1);
    check rainierClient.close();
}

@test:Config {
    groups: ["department", "in-memory"]
}
function inMemoryDepartmentCreateTest2() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    string[] deptNos = check rainierClient->/departments.post([department2, department3]);

    test:assertEquals(deptNos, [department2.deptNo, department3.deptNo]);

    Department departmentRetrieved = check rainierClient->/departments/[department2.deptNo].get();
    test:assertEquals(departmentRetrieved, department2);

    departmentRetrieved = check rainierClient->/departments/[department3.deptNo].get();
    test:assertEquals(departmentRetrieved, department3);
    check rainierClient.close();
}

@test:Config {
    groups: ["department", "in-memory"],
    dependsOn: [inMemoryDepartmentCreateTest]
}
function inMemoryDepartmentReadOneTest() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    Department departmentRetrieved = check rainierClient->/departments/[department1.deptNo].get();
    test:assertEquals(departmentRetrieved, department1);
    check rainierClient.close();
}

@test:Config {
    groups: ["department", "in-memory"],
    dependsOn: [inMemoryDepartmentCreateTest]
}
function inMemoryDepartmentReadOneTestNegative() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    Department|error departmentRetrieved = rainierClient->/departments/["invalid-department-id"].get();
    if departmentRetrieved is NotFoundError {
        test:assertEquals(departmentRetrieved.message(), "Invalid key: invalid-department-id");
    } else {
        test:assertFail("NotFoundError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["department", "in-memory"],
    dependsOn: [inMemoryDepartmentCreateTest, inMemoryDepartmentCreateTest2]
}
function inMemoryDepartmentReadManyTest() returns error? {
    InMemoryRainierClient rainierClient = check new ();
    stream<Department, error?> departmentStream = rainierClient->/departments.get();
    Department[] departments = check from Department department in departmentStream
        select department;

    test:assertEquals(departments, [department1, department2, department3]);
    check rainierClient.close();
}

@test:Config {
    groups: ["department", "dependent"],
    dependsOn: [inMemoryDepartmentCreateTest, inMemoryDepartmentCreateTest2]
}
function inMemoryDepartmentReadManyTestDependent() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    stream<DepartmentInfo2, Error?> departmentStream = rainierClient->/departments.get();
    DepartmentInfo2[] departments = check from DepartmentInfo2 department in departmentStream
        select department;

    test:assertEquals(departments, [
        {deptName: department1.deptName},
        {deptName: department2.deptName},
        {deptName: department3.deptName}
    ]);
    check rainierClient.close();
}

@test:Config {
    groups: ["department", "in-memory"],
    dependsOn: [inMemoryDepartmentReadOneTest, inMemoryDepartmentReadManyTest, inMemoryDepartmentReadManyTestDependent]
}
function inMemoryDepartmentUpdateTest() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    Department department = check rainierClient->/departments/[department1.deptNo].put({
        deptName: "Finance & Legalities"
    });

    test:assertEquals(department, updatedDepartment1);

    Department departmentRetrieved = check rainierClient->/departments/[department1.deptNo].get();
    test:assertEquals(departmentRetrieved, updatedDepartment1);
    check rainierClient.close();
}

@test:Config {
    groups: ["department", "in-memory"],
    dependsOn: [inMemoryDepartmentReadOneTest, inMemoryDepartmentReadManyTest, inMemoryDepartmentReadManyTestDependent]
}
function inMemoryDepartmentUpdateTestNegative1() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    Department|error department = rainierClient->/departments/["invalid-department-id"].put({
        deptName: "Human Resources"
    });

    if department is NotFoundError {
        test:assertEquals(department.message(), "Not found: invalid-department-id");
    } else {
        test:assertFail("NotFoundError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["department", "in-memory"],
    dependsOn: [inMemoryDepartmentUpdateTest]
}
function inMemoryDepartmentDeleteTest() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    Department department = check rainierClient->/departments/[department1.deptNo].delete();
    test:assertEquals(department, updatedDepartment1);

    stream<Department, error?> departmentStream = rainierClient->/departments.get();
    Department[] departments = check from Department department2 in departmentStream
        select department2;

    test:assertEquals(departments, [department2, department3]);
    check rainierClient.close();
}

@test:Config {
    groups: ["department", "in-memory"],
    dependsOn: [inMemoryDepartmentDeleteTest]
}
function inMemoryDepartmentDeleteTestNegative() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    Department|error department = rainierClient->/departments/[department1.deptNo].delete();

    if department is NotFoundError {
        test:assertEquals(department.message(), string `Not found: department-1`);
    } else {
        test:assertFail("NotFoundError expected.");
    }
    check rainierClient.close();
}
