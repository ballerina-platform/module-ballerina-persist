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

Employee employee1 = {
    empNo: "employee-1",
    firstName: "Tom",
    lastName: "Scott",
    birthDate: {year: 1992, month: 11, day:13},
    gender: M,
    hireDate: {year: 2022, month: 8, day: 1},
    deptNo: "department-2",
    workspaceId: "workspace-2"
};

Employee invalidEmployee = {
    empNo: "invalid-employee-no-extra-characters-to-force-failure",
    firstName: "Tom",
    lastName: "Scott",
    birthDate: {year: 1992, month: 11, day:13},
    gender: M,
    hireDate: {year: 2022, month: 8, day: 1},
    deptNo: "department-2",
    workspaceId: "workspace-2"
};

Employee employee2 = {
    empNo: "employee-2",
    firstName: "Jane",
    lastName: "Doe",
    birthDate: {year: 1996, month: 9, day:15},
    gender: F,
    hireDate: {year: 2022, month: 6, day: 1},
    deptNo: "department-2",
    workspaceId: "workspace-2"
};

Employee employee3 = {
    empNo: "employee-3",
    firstName: "Hugh",
    lastName: "Smith",
    birthDate: {year: 1986, month: 9, day:15},
    gender: F,
    hireDate: {year: 2021, month: 6, day: 1},
    deptNo: "department-3",
    workspaceId: "workspace-3"
};

Employee updatedEmployee1 = {
    empNo: "employee-1",
    firstName: "Tom",
    lastName: "Jones",
    birthDate: {year: 1992, month: 11, day:13},
    gender: M,
    hireDate: {year: 2022, month: 8, day: 1},
    deptNo: "department-3",
    workspaceId: "workspace-2"
};

@test:Config {
    groups: ["employee"],
    dependsOn: [workspaceDeleteTestNegative, departmentDeleteTestNegative]
}
function employeeCreateTest() returns error? {
    RainierClient rainierClient = check new ();
    
    Employee employee = check rainierClient->/employees.post(employee1);    
    test:assertEquals(employee, employee1);

    Employee employeeRetrieved = check rainierClient->/employees/[employee1.empNo].get();
    test:assertEquals(employeeRetrieved, employee1);
}

@test:Config {
    groups: ["employee"]
}
function employeeCreateTestNegative() returns error? {
    RainierClient rainierClient = check new ();
    
    Employee|error employee = rainierClient->/employees.post(invalidEmployee);   
    if employee is Error {
        test:assertTrue(employee.message().includes("Data truncation: Data too long for column 'empNo' at row 1."));
    } else {
        test:assertFail("Error expected.");
    }
}

@test:Config {
    groups: ["employee"],
    dependsOn: [employeeCreateTest]
}
function employeeReadOneTest() returns error? {
    RainierClient rainierClient = check new ();

    Employee employeeRetrieved = check rainierClient->/employees/[employee1.empNo].get();
    test:assertEquals(employeeRetrieved, employee1);
}

@test:Config {
    groups: ["employee"],
    dependsOn: [employeeCreateTest]
}
function employeeReadOneTestNegative() returns error? {
    RainierClient rainierClient = check new ();

    Employee|error employeeRetrieved = rainierClient->/employees/["invalid-employee-id"].get();
    if employeeRetrieved is InvalidKeyError {
        test:assertEquals(employeeRetrieved.message(), "A record does not exist for 'Employee' for key \"invalid-employee-id\".");
    } else {
        test:assertFail("InvalidKeyError expected.");
    }}

@test:Config {
    groups: ["employee"],
    dependsOn: [employeeCreateTest]
}
function employeeReadManyTest() returns error? {
    RainierClient rainierClient = check new ();

    _ = check rainierClient->/employees.post(employee2);
    _ = check rainierClient->/employees.post(employee3);

    stream<Employee, error?> employeeStream = rainierClient->/employees.get();
    Employee[] employees = check from Employee employee in employeeStream 
        select employee;

    test:assertEquals(employees, [employee1, employee2, employee3]);
}

@test:Config {
    groups: ["employee"],
    dependsOn: [employeeReadOneTest, employeeReadManyTest]
}
function employeeUpdateTest() returns error? {
    RainierClient rainierClient = check new ();

    Employee employee = check rainierClient->/employees/[employee1.empNo].put({
        lastName: "Jones",
        deptNo: "department-3"   
    });

    test:assertEquals(employee, updatedEmployee1);

    Employee employeeRetrieved = check rainierClient->/employees/[employee1.empNo].get();
    test:assertEquals(employeeRetrieved, updatedEmployee1);
}

@test:Config {
    groups: ["employee"],
    dependsOn: [employeeReadOneTest, employeeReadManyTest]
}
function employeeUpdateTestNegative1() returns error? {
    RainierClient rainierClient = check new ();

    Employee|error employee = rainierClient->/employees/["invalid-employee-id"].put({
        lastName: "Jones"   
    });

    if employee is InvalidKeyError {
        test:assertEquals(employee.message(), "A record does not exist for 'Employee' for key \"invalid-employee-id\".");
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
}

@test:Config {
    groups: ["employee"],
    dependsOn: [employeeReadOneTest, employeeReadManyTest]
}
function employeeUpdateTestNegative2() returns error? {
    RainierClient rainierClient = check new ();

    Employee|error employee = rainierClient->/employees/[employee1.empNo].put({
        firstName: "unncessarily-long-employee-name-to-force-error-on-update"
    });

    if employee is Error {
        test:assertTrue(employee.message().includes("Data truncation: Data too long for column 'firstName' at row 1."));
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
}

@test:Config {
    groups: ["employee"],
    dependsOn: [employeeUpdateTest, employeeUpdateTestNegative2]
}
function employeeDeleteTest() returns error? {
    RainierClient rainierClient = check new ();

    Employee employee = check rainierClient->/employees/[employee1.empNo].delete();
    test:assertEquals(employee, updatedEmployee1);

    stream<Employee, error?> employeeStream = rainierClient->/employees.get();
    Employee[] employees = check from Employee employee2 in employeeStream 
        select employee2;

    test:assertEquals(employees, [employee2, employee3]);
}

@test:Config {
    groups: ["employee"],
    dependsOn: [employeeDeleteTest]
}
function employeeDeleteTestNegative() returns error? {
    RainierClient rainierClient = check new ();

    Employee|error employee = rainierClient->/employees/[employee1.empNo].delete();

    if employee is InvalidKeyError {
        test:assertEquals(employee.message(), string `A record does not exist for 'Employee' for key "${employee1.empNo}".`);
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
}