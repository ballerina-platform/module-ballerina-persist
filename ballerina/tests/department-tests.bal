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

Department department1 = {
    deptNo: "department-1",
    deptName: "Finance"
};

Department invalidDepartment = {
    deptNo: "invalid-department-extra-characters-to-force-failure",
    deptName: "Finance"
};

Department department2 = {
    deptNo: "department-2",
    deptName: "Marketing"
};

Department department3 = {
    deptNo: "department-3",
    deptName: "Engineering"
};

Department updatedDepartment1 = {
    deptNo: "department-1",
    deptName: "Finance & Legalities"
};

@test:Config {
    groups: ["department"]
}
function departmentCreateTest() returns error? {
    RainierClient rainierClient = check new ();
    
    string[] deptNos = check rainierClient->/department.post([department1]);    
    test:assertEquals(deptNos, [department1.deptNo]);

    Department departmentRetrieved = check rainierClient->/department/[department1.deptNo].get();
    test:assertEquals(departmentRetrieved, department1);
    check rainierClient.close();
}

@test:Config {
    groups: ["department"]
}
function departmentCreateTest2() returns error? {
    RainierClient rainierClient = check new ();
    
    string[] deptNos = check rainierClient->/department.post([department2, department3]);

    test:assertEquals(deptNos, [department2.deptNo, department3.deptNo]);

    Department departmentRetrieved = check rainierClient->/department/[department2.deptNo].get();
    test:assertEquals(departmentRetrieved, department2);

    departmentRetrieved = check rainierClient->/department/[department3.deptNo].get();
    test:assertEquals(departmentRetrieved, department3);
    check rainierClient.close();
}

@test:Config {
    groups: ["department"]
}
function departmentCreateTestNegative() returns error? {
    RainierClient rainierClient = check new ();
    
    string[]|error department = rainierClient->/department.post([invalidDepartment]);   
    if department is Error {
        test:assertTrue(department.message().includes("Data truncation: Data too long for column 'deptNo' at row 1."));
    } else {
        test:assertFail("Error expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["department"],
    dependsOn: [departmentCreateTest]
}
function departmentReadOneTest() returns error? {
    RainierClient rainierClient = check new ();

    Department departmentRetrieved = check rainierClient->/department/[department1.deptNo].get();
    test:assertEquals(departmentRetrieved, department1);
    check rainierClient.close();
}

@test:Config {
    groups: ["department"],
    dependsOn: [departmentCreateTest]
}
function departmentReadOneTestNegative() returns error? {
    RainierClient rainierClient = check new ();

    Department|error departmentRetrieved = rainierClient->/department/["invalid-department-id"].get();
    if departmentRetrieved is InvalidKeyError {
        test:assertEquals(departmentRetrieved.message(), "A record does not exist for 'Department' for key \"invalid-department-id\".");
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["department"],
    dependsOn: [departmentCreateTest, departmentCreateTest2]
}
function departmentReadManyTest() returns error? {
    RainierClient rainierClient = check new ();
    stream<Department, error?> departmentStream = rainierClient->/department.get();
    Department[] departments = check from Department department in departmentStream 
        select department;

    test:assertEquals(departments, [department1, department2, department3]);
    check rainierClient.close();
}

public type DepartmentInfo2 record {|
    string deptName;
|};

@test:Config {
    groups: ["department", "dependent"],
    dependsOn: [departmentCreateTest, departmentCreateTest2]
}
function departmentReadManyTestDependent() returns error? {
    RainierClient rainierClient = check new ();

    stream<DepartmentInfo2, Error?> departmentStream = rainierClient->/department.get();
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
    groups: ["department"],
    dependsOn: [departmentReadOneTest, departmentReadManyTest, departmentReadManyTestDependent]
}
function departmentUpdateTest() returns error? {
    RainierClient rainierClient = check new ();

    Department department = check rainierClient->/department/[department1.deptNo].put({
        deptName: "Finance & Legalities"   
    });

    test:assertEquals(department, updatedDepartment1);

    Department departmentRetrieved = check rainierClient->/department/[department1.deptNo].get();
    test:assertEquals(departmentRetrieved, updatedDepartment1);
    check rainierClient.close();
}

@test:Config {
    groups: ["department"],
    dependsOn: [departmentReadOneTest, departmentReadManyTest, departmentReadManyTestDependent]
}
function departmentUpdateTestNegative1() returns error? {
    RainierClient rainierClient = check new ();

    Department|error department = rainierClient->/department/["invalid-department-id"].put({
        deptName: "Human Resources"   
    });

    if department is InvalidKeyError {
        test:assertEquals(department.message(), "A record does not exist for 'Department' for key \"invalid-department-id\".");
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["department"],
    dependsOn: [departmentReadOneTest, departmentReadManyTest, departmentReadManyTestDependent]
}
function departmentUpdateTestNegative2() returns error? {
    RainierClient rainierClient = check new ();

    Department|error department = rainierClient->/department/[department1.deptNo].put({
        deptName: "unncessarily-long-department-name-to-force-error-on-update"
    });

    if department is Error {
        test:assertTrue(department.message().includes("Data truncation: Data too long for column 'deptName' at row 1."));
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["department"],
    dependsOn: [departmentUpdateTest, departmentUpdateTestNegative2]
}
function departmentDeleteTest() returns error? {
    RainierClient rainierClient = check new ();

    Department department = check rainierClient->/department/[department1.deptNo].delete();
    test:assertEquals(department, updatedDepartment1);

    stream<Department, error?> departmentStream = rainierClient->/department.get();
    Department[] departments = check from Department department2 in departmentStream 
        select department2;

    test:assertEquals(departments, [department2, department3]);
    check rainierClient.close();
}

@test:Config {
    groups: ["department"],
    dependsOn: [departmentDeleteTest]
}
function departmentDeleteTestNegative() returns error? {
    RainierClient rainierClient = check new ();

    Department|error department = rainierClient->/department/[department1.deptNo].delete();

    if department is InvalidKeyError {
        test:assertEquals(department.message(), string `A record does not exist for 'Department' for key "${department1.deptNo}".`);
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
    check rainierClient.close();
}
