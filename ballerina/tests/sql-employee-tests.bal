// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/test;
import ballerina/time;

Employee employee1 = {
    empNo: "employee-1",
    firstName: "Tom",
    lastName: "Scott",
    birthDate: {year: 1992, month: 11, day:13},
    gender: "M",
    hireDate: {year: 2022, month: 8, day: 1},
    departmentDeptNo: "department-2",
    workspaceWorkspaceId: "workspace-2"
};

Employee invalidEmployee = {
    empNo: "invalid-employee-no-extra-characters-to-force-failure",
    firstName: "Tom",
    lastName: "Scott",
    birthDate: {year: 1992, month: 11, day:13},
    gender: "M",
    hireDate: {year: 2022, month: 8, day: 1},
    departmentDeptNo: "department-2",
    workspaceWorkspaceId: "workspace-2"
};

Employee employee2 = {
    empNo: "employee-2",
    firstName: "Jane",
    lastName: "Doe",
    birthDate: {year: 1996, month: 9, day:15},
    gender: "F",
    hireDate: {year: 2022, month: 6, day: 1},
    departmentDeptNo: "department-2",
    workspaceWorkspaceId: "workspace-2"
};

Employee employee3 = {
    empNo: "employee-3",
    firstName: "Hugh",
    lastName: "Smith",
    birthDate: {year: 1986, month: 9, day:15},
    gender: "F",
    hireDate: {year: 2021, month: 6, day: 1},
    departmentDeptNo: "department-3",
    workspaceWorkspaceId: "workspace-3"
};

Employee updatedEmployee1 = {
    empNo: "employee-1",
    firstName: "Tom",
    lastName: "Jones",
    birthDate: {year: 1994, month: 11, day:13},
    gender: "M",
    hireDate: {year: 2022, month: 8, day: 1},
    departmentDeptNo: "department-3",
    workspaceWorkspaceId: "workspace-2"
};

@test:Config {
    groups: ["employee"],
    dependsOn: [workspaceDeleteTestNegative, departmentDeleteTestNegative]
}
function employeeCreateTest() returns error? {
    SQLRainierClient rainierClient = check new ();
    
    string[] empNos = check rainierClient->/employees.post([employee1]);    
    test:assertEquals(empNos, [employee1.empNo]);

    Employee employeeRetrieved = check rainierClient->/employees/[employee1.empNo].get();
    test:assertEquals(employeeRetrieved, employee1);
    check rainierClient.close();
}

@test:Config {
    groups: ["employee"],
    dependsOn: [workspaceDeleteTestNegative, departmentDeleteTestNegative]
}
function employeeCreateTest2() returns error? {
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
    groups: ["employee"]
}
function employeeCreateTestNegative() returns error? {
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
    groups: ["employee"],
    dependsOn: [employeeCreateTest]
}
function employeeReadOneTest() returns error? {
    SQLRainierClient rainierClient = check new ();

    Employee employeeRetrieved = check rainierClient->/employees/[employee1.empNo].get();
    test:assertEquals(employeeRetrieved, employee1);
    check rainierClient.close();
}

@test:Config {
    groups: ["employee"],
    dependsOn: [employeeCreateTest]
}
function employeeReadOneTestNegative() returns error? {
    SQLRainierClient rainierClient = check new ();

    Employee|error employeeRetrieved = rainierClient->/employees/["invalid-employee-id"].get();
    if employeeRetrieved is InvalidKeyError {
        test:assertEquals(employeeRetrieved.message(), "A record does not exist for 'Employee' for key \"invalid-employee-id\".");
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["employee"],
    dependsOn: [employeeCreateTest, employeeCreateTest2]
}
function employeeReadManyTest() returns error? {
    SQLRainierClient rainierClient = check new ();

    stream<Employee, Error?> employeeStream = rainierClient->/employees.get();
    Employee[] employees = check from Employee employee in employeeStream 
        select employee;

    test:assertEquals(employees, [employee1, employee2, employee3]);
    check rainierClient.close();
}

public type EmployeeName record {|
    string firstName;
    string lastName;
|};

@test:Config {
    groups:  ["dependent", "employee"],
    dependsOn: [employeeCreateTest, employeeCreateTest2]
}
function employeeReadManyDependentTest1() returns error? {
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

public type EmployeeInfo2 record {|
    readonly string empNo;
    time:Date birthDate;
    string departmentDeptNo;
    string workspaceWorkspaceId;
|};

@test:Config {
    groups:  ["dependent", "employee"],
    dependsOn: [employeeCreateTest, employeeCreateTest2]
}
function employeeReadManyDependentTest2() returns error? {
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
    groups: ["employee"],
    dependsOn: [employeeReadOneTest, employeeReadManyTest, employeeReadManyDependentTest1, employeeReadManyDependentTest2]
}
function employeeUpdateTest() returns error? {
    SQLRainierClient rainierClient = check new ();

    Employee employee = check rainierClient->/employees/[employee1.empNo].put({
        lastName: "Jones",
        departmentDeptNo: "department-3",
        birthDate: {year: 1994, month: 11, day:13}
    });

    test:assertEquals(employee, updatedEmployee1);

    Employee employeeRetrieved = check rainierClient->/employees/[employee1.empNo].get();
    test:assertEquals(employeeRetrieved, updatedEmployee1);
    check rainierClient.close();
}

@test:Config {
    groups: ["employee"],
    dependsOn: [employeeReadOneTest, employeeReadManyTest, employeeReadManyDependentTest1, employeeReadManyDependentTest2]
}
function employeeUpdateTestNegative1() returns error? {
    SQLRainierClient rainierClient = check new ();

    Employee|error employee = rainierClient->/employees/["invalid-employee-id"].put({
        lastName: "Jones"   
    });

    if employee is InvalidKeyError {
        test:assertEquals(employee.message(), "A record does not exist for 'Employee' for key \"invalid-employee-id\".");
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["employee"],
    dependsOn: [employeeReadOneTest, employeeReadManyTest, employeeReadManyDependentTest1, employeeReadManyDependentTest2]
}
function employeeUpdateTestNegative2() returns error? {
    SQLRainierClient rainierClient = check new ();

    Employee|error employee = rainierClient->/employees/[employee1.empNo].put({
        firstName: "unncessarily-long-employee-name-to-force-error-on-update"
    });

    if employee is Error {
        test:assertTrue(employee.message().includes("Data truncation: Data too long for column 'firstName' at row 1."));
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["employee"],
    dependsOn: [employeeReadOneTest, employeeReadManyTest, employeeReadManyDependentTest1, employeeReadManyDependentTest2]
}
function employeeUpdateTestNegative3() returns error? {
    SQLRainierClient rainierClient = check new ();

    Employee|error employee = rainierClient->/employees/[employee1.empNo].put({
        workspaceWorkspaceId: "invalid-workspaceWorkspaceId"
    });

    if employee is ForeignKeyConstraintViolationError {
        test:assertTrue(employee.message().includes("Cannot add or update a child row: a foreign key constraint fails (`test`.`Employee`, " +
            "CONSTRAINT `Employee_ibfk_2` FOREIGN KEY (`workspaceWorkspaceId`) REFERENCES `Workspace` (`workspaceId`))."));
    } else {
        test:assertFail("ForeignKeyConstraintViolationError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["employee"],
    dependsOn: [employeeUpdateTest, employeeUpdateTestNegative2, employeeUpdateTestNegative3]
}
function employeeDeleteTest() returns error? {
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
    groups: ["employee"],
    dependsOn: [employeeDeleteTest]
}
function employeeDeleteTestNegative() returns error? {
    SQLRainierClient rainierClient = check new ();

    Employee|error employee = rainierClient->/employees/[employee1.empNo].delete();

    if employee is InvalidKeyError {
        test:assertEquals(employee.message(), string `A record does not exist for 'Employee' for key "${employee1.empNo}".`);
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
    check rainierClient.close();
}
