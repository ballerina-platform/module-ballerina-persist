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
    groups: ["employee", "sql"],
    dependsOn: [sqlWorkspaceDeleteTestNegative, sqlDepartmentDeleteTestNegative]
}
function sqlEmployeeCreateTest() returns error? {
    SQLRainierClient rainierClient = check new ();

    string[] empNos = check rainierClient->/employees.post([employee1]);
    test:assertEquals(empNos, [employee1.empNo]);

    Employee employeeRetrieved = check rainierClient->/employees/[employee1.empNo].get();
    test:assertEquals(employeeRetrieved, employee1);
    check rainierClient.close();
}

@test:Config {
    groups: ["employee", "sql"],
    dependsOn: [sqlWorkspaceDeleteTestNegative, sqlDepartmentDeleteTestNegative]
}
function sqlEmployeeCreateTest2() returns error? {
    SQLRainierClient rainierClient = check new ();

    string[] empNos = check rainierClient->/employees.post([employee2, employee3]);

    test:assertEquals(empNos, [employee2.empNo, employee3.empNo]);

    Employee employeeRetrieved = check rainierClient->/employees/[employee2.empNo].get();
    test:assertEquals(employeeRetrieved, employee2);

    employeeRetrieved = check rainierClient->/employees/[employee3.empNo].get();
    test:assertEquals(employeeRetrieved, employee3);
    check rainierClient.close();
}

@test:Config {
    groups: ["employee", "sql"]
}
function sqlEmployeeCreateTestNegative() returns error? {
    SQLRainierClient rainierClient = check new ();

    string[]|error employee = rainierClient->/employees.post([invalidEmployee]);
    if employee is Error {
        test:assertTrue(employee.message().includes("Data truncation: Data too long for column 'empNo' at row 1."));
    } else {
        test:assertFail("Error expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["employee", "sql"],
    dependsOn: [sqlEmployeeCreateTest]
}
function sqlEmployeeReadOneTest() returns error? {
    SQLRainierClient rainierClient = check new ();

    Employee employeeRetrieved = check rainierClient->/employees/[employee1.empNo].get();
    test:assertEquals(employeeRetrieved, employee1);
    check rainierClient.close();
}

@test:Config {
    groups: ["employee", "sql"],
    dependsOn: [sqlEmployeeCreateTest]
}
function sqlEmployeeReadOneTestNegative() returns error? {
    SQLRainierClient rainierClient = check new ();

    Employee|error employeeRetrieved = rainierClient->/employees/["invalid-employee-id"].get();
    if employeeRetrieved is NotFoundError {
        test:assertEquals(employeeRetrieved.message(), "A record does not exist for 'Employee' for key \"invalid-employee-id\".");
    } else {
        test:assertFail("NotFoundError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["employee", "sql"],
    dependsOn: [sqlEmployeeCreateTest, sqlEmployeeCreateTest2]
}
function sqlEmployeeReadManyTest() returns error? {
    SQLRainierClient rainierClient = check new ();

    stream<Employee, Error?> employeeStream = rainierClient->/employees.get();
    Employee[] employees = check from Employee employee in employeeStream
        select employee;

    test:assertEquals(employees, [employee1, employee2, employee3]);
    check rainierClient.close();
}

@test:Config {
    groups: ["dependent", "employee"],
    dependsOn: [sqlEmployeeCreateTest, sqlEmployeeCreateTest2]
}
function sqlEmployeeReadManyDependentTest1() returns error? {
    SQLRainierClient rainierClient = check new ();

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
    dependsOn: [sqlEmployeeCreateTest, sqlEmployeeCreateTest2]
}
function sqlEmployeeReadManyDependentTest2() returns error? {
    SQLRainierClient rainierClient = check new ();

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
    groups: ["employee", "sql"],
    dependsOn: [sqlEmployeeReadOneTest, sqlEmployeeReadManyTest, sqlEmployeeReadManyDependentTest1, sqlEmployeeReadManyDependentTest2]
}
function sqlEmployeeUpdateTest() returns error? {
    SQLRainierClient rainierClient = check new ();

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
    groups: ["employee", "sql"],
    dependsOn: [sqlEmployeeReadOneTest, sqlEmployeeReadManyTest, sqlEmployeeReadManyDependentTest1, sqlEmployeeReadManyDependentTest2]
}
function sqlEmployeeUpdateTestNegative1() returns error? {
    SQLRainierClient rainierClient = check new ();

    Employee|error employee = rainierClient->/employees/["invalid-employee-id"].put({
        lastName: "Jones"
    });

    if employee is NotFoundError {
        test:assertEquals(employee.message(), "A record does not exist for 'Employee' for key \"invalid-employee-id\".");
    } else {
        test:assertFail("NotFoundError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["employee", "sql"],
    dependsOn: [sqlEmployeeReadOneTest, sqlEmployeeReadManyTest, sqlEmployeeReadManyDependentTest1, sqlEmployeeReadManyDependentTest2]
}
function sqlEmployeeUpdateTestNegative2() returns error? {
    SQLRainierClient rainierClient = check new ();

    Employee|error employee = rainierClient->/employees/[employee1.empNo].put({
        firstName: "unncessarily-long-employee-name-to-force-error-on-update"
    });

    if employee is Error {
        test:assertTrue(employee.message().includes("Data truncation: Data too long for column 'firstName' at row 1."));
    } else {
        test:assertFail("NotFoundError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["employee", "sql"],
    dependsOn: [sqlEmployeeReadOneTest, sqlEmployeeReadManyTest, sqlEmployeeReadManyDependentTest1, sqlEmployeeReadManyDependentTest2]
}
function sqlEmployeeUpdateTestNegative3() returns error? {
    SQLRainierClient rainierClient = check new ();

    Employee|error employee = rainierClient->/employees/[employee1.empNo].put({
        workspaceWorkspaceId: "invalid-workspaceWorkspaceId"
    });

    if employee is ConstraintViolationError {
        test:assertTrue(employee.message().includes("Cannot add or update a child row: a foreign key constraint fails (`test`.`Employee`, " +
            "CONSTRAINT `Employee_ibfk_2` FOREIGN KEY (`workspaceWorkspaceId`) REFERENCES `Workspace` (`workspaceId`))."));
    } else {
        test:assertFail("ConstraintViolationError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["employee", "sql"],
    dependsOn: [sqlEmployeeUpdateTest, sqlEmployeeUpdateTestNegative2, sqlEmployeeUpdateTestNegative3]
}
function sqlEmployeeDeleteTest() returns error? {
    SQLRainierClient rainierClient = check new ();

    Employee employee = check rainierClient->/employees/[employee1.empNo].delete();
    test:assertEquals(employee, updatedEmployee1);

    stream<Employee, error?> employeeStream = rainierClient->/employees.get();
    Employee[] employees = check from Employee employee2 in employeeStream
        select employee2;

    test:assertEquals(employees, [employee2, employee3]);
    check rainierClient.close();
}

@test:Config {
    groups: ["employee", "sql"],
    dependsOn: [sqlEmployeeDeleteTest]
}
function sqlEmployeeDeleteTestNegative() returns error? {
    SQLRainierClient rainierClient = check new ();

    Employee|error employee = rainierClient->/employees/[employee1.empNo].delete();

    if employee is NotFoundError {
        test:assertEquals(employee.message(), string `A record does not exist for 'Employee' for key "${employee1.empNo}".`);
    } else {
        test:assertFail("NotFoundError expected.");
    }
    check rainierClient.close();
}
