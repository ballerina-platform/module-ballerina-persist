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
    groups: ["employee", "in-memory"],
    dependsOn: [inMemoryWorkspaceDeleteTestNegative, inMemoryDepartmentDeleteTestNegative]
}
function inMemoryEmployeeCreateTest() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    string[] empNos = check rainierClient->/employees.post([employee1]);
    test:assertEquals(empNos, [employee1.empNo]);

    Employee employeeRetrieved = check rainierClient->/employees/[employee1.empNo].get();
    test:assertEquals(employeeRetrieved, employee1);
    check rainierClient.close();
}

@test:Config {
    groups: ["employee", "in-memory"],
    dependsOn: [inMemoryWorkspaceDeleteTestNegative, inMemoryDepartmentDeleteTestNegative]
}
function inMemoryEmployeeCreateTest2() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    string[] empNos = check rainierClient->/employees.post([employee2, employee3]);

    test:assertEquals(empNos, [employee2.empNo, employee3.empNo]);

    Employee employeeRetrieved = check rainierClient->/employees/[employee2.empNo].get();
    test:assertEquals(employeeRetrieved, employee2);

    employeeRetrieved = check rainierClient->/employees/[employee3.empNo].get();
    test:assertEquals(employeeRetrieved, employee3);
    check rainierClient.close();
}

@test:Config {
    groups: ["employee", "in-memory"],
    dependsOn: [inMemoryEmployeeCreateTest]
}
function inMemoryEmployeeReadOneTest() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    Employee employeeRetrieved = check rainierClient->/employees/[employee1.empNo].get();
    test:assertEquals(employeeRetrieved, employee1);
    check rainierClient.close();
}

@test:Config {
    groups: ["employee", "in-memory"],
    dependsOn: [inMemoryEmployeeCreateTest]
}
function inMemoryEmployeeReadOneTestNegative() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    Employee|error employeeRetrieved = rainierClient->/employees/["invalid-employee-id"].get();
    if employeeRetrieved is NotFoundError {
        test:assertEquals(employeeRetrieved.message(), "A record with the key 'invalid-employee-id' does not exist for the entity 'Employee'.");
    } else {
        test:assertFail("NotFoundError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["employee", "in-memory"],
    dependsOn: [inMemoryEmployeeCreateTest, inMemoryEmployeeCreateTest2]
}
function inMemoryEmployeeReadManyTest() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    stream<Employee, Error?> employeeStream = rainierClient->/employees.get();
    Employee[] employees = check from Employee employee in employeeStream
        select employee;

    test:assertEquals(employees, [employee1, employee2, employee3]);
    check rainierClient.close();
}

@test:Config {
    groups: ["dependent", "employee"],
    dependsOn: [inMemoryEmployeeCreateTest, inMemoryEmployeeCreateTest2]
}
function inMemoryEmployeeReadManyDependentTest1() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    stream<EmployeeName, Error?> employeeStream = rainierClient->/employees.get();
    EmployeeName[] employees = check from EmployeeName employee in employeeStream
        select employee;

    test:assertEquals(employees, [
        {firstName: employee1.firstName, lastName: employee1.lastName},
        {firstName: employee2.firstName, lastName: employee2.lastName},
        {firstName: employee3.firstName, lastName: employee3.lastName}
    ]);
    check rainierClient.close();
}

@test:Config {
    groups: ["dependent", "employee"],
    dependsOn: [inMemoryEmployeeCreateTest, inMemoryEmployeeCreateTest2]
}
function inMemoryEmployeeReadManyDependentTest2() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    stream<EmployeeInfo2, Error?> employeeStream = rainierClient->/employees.get();
    EmployeeInfo2[] employees = check from EmployeeInfo2 employee in employeeStream
        select employee;

    test:assertEquals(employees, [
        {empNo: employee1.empNo, birthDate: employee1.birthDate, departmentDeptNo: employee1.departmentDeptNo, workspaceWorkspaceId: employee1.workspaceWorkspaceId},
        {empNo: employee2.empNo, birthDate: employee2.birthDate, departmentDeptNo: employee2.departmentDeptNo, workspaceWorkspaceId: employee2.workspaceWorkspaceId},
        {empNo: employee3.empNo, birthDate: employee3.birthDate, departmentDeptNo: employee3.departmentDeptNo, workspaceWorkspaceId: employee3.workspaceWorkspaceId}
    ]);
    check rainierClient.close();
}

@test:Config {
    groups: ["employee", "in-memory"],
    dependsOn: [inMemoryEmployeeReadOneTest, inMemoryEmployeeReadManyTest, inMemoryEmployeeReadManyDependentTest1, inMemoryEmployeeReadManyDependentTest2]
}
function inMemoryEmployeeUpdateTest() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    Employee employee = check rainierClient->/employees/[employee1.empNo].put({
        lastName: "Jones",
        departmentDeptNo: "department-3",
        birthDate: {year: 1994, month: 11, day: 13}
    });

    test:assertEquals(employee, updatedEmployee1);

    Employee employeeRetrieved = check rainierClient->/employees/[employee1.empNo].get();
    test:assertEquals(employeeRetrieved, updatedEmployee1);
    check rainierClient.close();
}

@test:Config {
    groups: ["employee", "in-memory"],
    dependsOn: [inMemoryEmployeeReadOneTest, inMemoryEmployeeReadManyTest, inMemoryEmployeeReadManyDependentTest1, inMemoryEmployeeReadManyDependentTest2]
}
function inMemoryEmployeeUpdateTestNegative1() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    Employee|error employee = rainierClient->/employees/["invalid-employee-id"].put({
        lastName: "Jones"
    });

    if employee is NotFoundError {
        test:assertEquals(employee.message(), "A record with the key 'invalid-employee-id' does not exist for the entity 'Employee'.");
    } else {
        test:assertFail("NotFoundError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["employee", "in-memory"],
    dependsOn: [inMemoryEmployeeUpdateTest]
}
function inMemoryEmployeeDeleteTest() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    Employee employee = check rainierClient->/employees/[employee1.empNo].delete();
    test:assertEquals(employee, updatedEmployee1);

    stream<Employee, error?> employeeStream = rainierClient->/employees.get();
    Employee[] employees = check from Employee employee2 in employeeStream
        select employee2;

    test:assertEquals(employees, [employee2, employee3]);
    check rainierClient.close();
}

@test:Config {
    groups: ["employee", "in-memory"],
    dependsOn: [inMemoryEmployeeDeleteTest]
}
function inMemoryEmployeeDeleteTestNegative() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    Employee|error employee = rainierClient->/employees/[employee1.empNo].delete();

    if employee is NotFoundError {
        test:assertEquals(employee.message(), string `A record with the key '${employee1.empNo}' does not exist for the entity 'Employee'.`);
    } else {
        test:assertFail("NotFoundError expected.");
    }
    check rainierClient.close();
}
