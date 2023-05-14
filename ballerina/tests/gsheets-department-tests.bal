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
    groups: ["department", "google-sheets"],
    dependsOn: [gsheetsBuildingDeleteTestNegative],
    enable: false
}
function gsheetsDepartmentCreateTest() returns error? {
    GoogleSheetsRainierClient rainierClient =  check new ();
    string[] deptNos = check rainierClient->/departments.post([department1]);
    test:assertEquals(deptNos, [department1.deptNo]);

    Department departmentRetrieved = check rainierClient->/departments/[department1.deptNo].get();
    test:assertEquals(departmentRetrieved, department1);

}

@test:Config {
    groups: ["department", "igoogle-sheets"],
    dependsOn: [gsheetsDepartmentCreateTest],
    enable: false
}
function gsheetsDepartmentCreateTest2() returns error? {
    GoogleSheetsRainierClient rainierClient =  check new ();
    string[] deptNos = check rainierClient->/departments.post([department2, department3]);

    test:assertEquals(deptNos, [department2.deptNo, department3.deptNo]);

    Department departmentRetrieved = check rainierClient->/departments/[department2.deptNo].get();
    test:assertEquals(departmentRetrieved, department2);

    departmentRetrieved = check rainierClient->/departments/[department3.deptNo].get();
    test:assertEquals(departmentRetrieved, department3);

}

@test:Config {
    groups: ["department", "google-sheets"],
    dependsOn: [gsheetsDepartmentCreateTest],
    enable: false
}
function gsheetsDepartmentReadOneTest() returns error? {
    GoogleSheetsRainierClient rainierClient =  check new ();
    Department departmentRetrieved = check rainierClient->/departments/[department1.deptNo].get();
    test:assertEquals(departmentRetrieved, department1);

}

@test:Config {
    groups: ["department", "google-sheets"],
    dependsOn: [gsheetsDepartmentCreateTest],
    enable: false
}
function gsheetsDepartmentReadOneTestNegative() returns error? {
    GoogleSheetsRainierClient rainierClient =  check new ();
    Department|error departmentRetrieved = rainierClient->/departments/["invalid-department-id"].get();
    if departmentRetrieved is InvalidKeyError {
        test:assertEquals(departmentRetrieved.message(), "Invalid key: invalid-department-id");
    } else {
        test:assertFail("InvalidKeyError expected.");
    }

}

@test:Config {
    groups: ["department", "google-sheets"],
    dependsOn: [gsheetsDepartmentCreateTest, gsheetsDepartmentCreateTest2],
    enable: false
}
function gsheetsDepartmentReadManyTest() returns error? {
    GoogleSheetsRainierClient rainierClient =  check new ();
    stream<Department, error?> departmentStream = rainierClient->/departments.get();
    Department[] departments = check from Department department in departmentStream
        select department;

    test:assertEquals(departments, [department1, department2, department3]);

}

@test:Config {
    groups: ["department", "google-sheets"],
    dependsOn: [gsheetsDepartmentCreateTest, gsheetsDepartmentCreateTest2],
    enable: false
}
function gsheetsDepartmentReadManyTestDependent() returns error? {
    GoogleSheetsRainierClient rainierClient =  check new ();
    stream<DepartmentInfo2, Error?> departmentStream = rainierClient->/departments.get();
    DepartmentInfo2[] departments = check from DepartmentInfo2 department in departmentStream
        select department;

    test:assertEquals(departments, [
        {deptName: department1.deptName},
        {deptName: department2.deptName},
        {deptName: department3.deptName}
    ]);

}

@test:Config {
    groups: ["department", "google-sheets"],
    dependsOn: [gsheetsDepartmentReadOneTest, gsheetsDepartmentReadManyTest, gsheetsDepartmentReadManyTestDependent],
    enable: false
}
function gsheetsDepartmentUpdateTest() returns error? {
    GoogleSheetsRainierClient rainierClient =  check new ();
    Department department = check rainierClient->/departments/[department1.deptNo].put({
        deptName: "Finance & Legalities"
    });

    test:assertEquals(department, updatedDepartment1);

    Department departmentRetrieved = check rainierClient->/departments/[department1.deptNo].get();
    test:assertEquals(departmentRetrieved, updatedDepartment1);

}

@test:Config {
    groups: ["department", "google-sheets"],
    dependsOn: [gsheetsDepartmentReadOneTest, gsheetsDepartmentReadManyTest, gsheetsDepartmentReadManyTestDependent],
    enable: false
}
function gsheetsDepartmentUpdateTestNegative1() returns error? {
    GoogleSheetsRainierClient rainierClient =  check new ();
    Department|error department = rainierClient->/departments/["invalid-department-id"].put({
        deptName: "Human Resources"
    });

    if department is InvalidKeyError {
        test:assertEquals(department.message(), "Not found: invalid-department-id");
    } else {
        test:assertFail("InvalidKeyError expected.");
    }

}

@test:Config {
    groups: ["department", "google-sheets"],
    dependsOn: [gsheetsDepartmentUpdateTest],
    enable: false
}
function gsheetsDepartmentDeleteTest() returns error? {
    GoogleSheetsRainierClient rainierClient =  check new ();
    Department department = check rainierClient->/departments/[department1.deptNo].delete();
    test:assertEquals(department, updatedDepartment1);

    stream<Department, error?> departmentStream = rainierClient->/departments.get();
    Department[] departments = check from Department department2 in departmentStream
        select department2;

    test:assertEquals(departments, [department2, department3]);

}

@test:Config {
    groups: ["department", "google-sheets"],
    dependsOn: [gsheetsDepartmentDeleteTest],
    enable: false
}
function gsheetsDepartmentDeleteTestNegative() returns error? {
    GoogleSheetsRainierClient rainierClient =  check new ();
    Department|error department = rainierClient->/departments/[department1.deptNo].delete();

    if department is InvalidKeyError {
        test:assertEquals(department.message(), string `Invalid key: department-1`);
    } else {
        test:assertFail("InvalidKeyError expected.");
    }

}
