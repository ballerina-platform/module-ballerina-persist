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
    groups:  ["associations", "sql"],
    dependsOn: [sqlEmployeeDeleteTestNegative]
}
function sqlEmployeeRelationsTest() returns error? {
    SQLRainierClient rainierClient = check new ();

    Employee employee21 = {
        empNo: "employee-21",
        firstName: "Tom",
        lastName: "Scott",
        birthDate: {year: 1992, month: 11, day:13},
        gender: "M",
        hireDate: {year: 2022, month: 8, day: 1},
        departmentDeptNo: "department-22",
        workspaceWorkspaceId: "workspace-22"
    };

    Workspace workspace22 = {
        workspaceId: "workspace-22",
        workspaceType: "medium",
        locationBuildingCode: "building-22"
    };

    BuildingInsert building22 = {
        buildingCode: "building-22",
        city: "Manhattan",
        state: "New York",
        country: "USA",
        postalCode: "10570",
        'type: "owned"
    };

    Department department22 = {
        deptNo: "department-22",
        deptName: "Marketing"
    };

    _ = check rainierClient->/buildings.post([building22]);    
    _ = check rainierClient->/departments.post([department22]);    
    _ = check rainierClient->/workspaces.post([workspace22]);    
    _ = check rainierClient->/employees.post([employee21]);    

    stream<EmployeeInfo, Error?> employeeStream = rainierClient->/employees.get();
    EmployeeInfo[] employees = check from EmployeeInfo employee in employeeStream 
        select employee;

    EmployeeInfo retrieved = check rainierClient->/employees/["employee-21"].get();
    
    EmployeeInfo expected = {
        firstName: "Tom",
        lastName: "Scott",
        department: {
            deptName: "Marketing"
        },
        workspace: {
            workspaceId: "workspace-22",
            workspaceType: "medium",
            locationBuildingCode: "building-22"
        }
    };

    test:assertTrue(employees.indexOf(expected) is int, "Expected EmployeeInfo not found.");
    test:assertEquals(retrieved, expected);
    check rainierClient.close();
}

@test:Config {
    groups: ["associations", "sql"],
    dependsOn: [sqlEmployeeDeleteTestNegative]
}
function departmentRelationsTest() returns error? {
    SQLRainierClient rainierClient = check new ();

    Employee employee11 = {
        empNo: "employee-11",
        firstName: "Tom",
        lastName: "Scott",
        birthDate: {year: 1992, month: 11, day:13},
        gender: "M",
        hireDate: {year: 2022, month: 8, day: 1},
        departmentDeptNo: "department-12",
        workspaceWorkspaceId: "workspace-12"
    };

    Employee employee12 = {
        empNo: "employee-12",
        firstName: "Jane",
        lastName: "Doe",
        birthDate: {year: 1996, month: 9, day:15},
        gender: "F",
        hireDate: {year: 2022, month: 6, day: 1},
        departmentDeptNo: "department-12",
        workspaceWorkspaceId: "workspace-12"
    };

    Workspace workspace12 = {
        workspaceId: "workspace-12",
        workspaceType: "medium",
        locationBuildingCode: "building-12"
    };

    BuildingInsert building12 = {
        buildingCode: "building-12",
        city: "Manhattan",
        state: "New York",
        country: "USA",
        postalCode: "10570",
        'type: "owned"
    };

    Department department12 = {
        deptNo: "department-12",
        deptName: "Marketing"
    };

    _ = check rainierClient->/buildings.post([building12]);    
    _ = check rainierClient->/departments.post([department12]);    
    _ = check rainierClient->/workspaces.post([workspace12]);    
    _ = check rainierClient->/employees.post([employee11, employee12]);    

    stream<DepartmentInfo, error?> departmentStream = rainierClient->/departments.get();
    DepartmentInfo[] departments = check from DepartmentInfo department in departmentStream 
        select department;

    DepartmentInfo retrieved = check rainierClient->/departments/["department-12"].get();

    DepartmentInfo expected = {
        deptNo: "department-12",
        deptName: "Marketing",
        employees: [{
            firstName: "Tom",
            lastName: "Scott"
        }, {
            firstName: "Jane",
            lastName: "Doe"
        }]
    };

    test:assertTrue(departments.indexOf(expected) is int, "Expected DepartmentInfo not found.");
    test:assertEquals(retrieved, expected);
    check rainierClient.close();
}

@test:Config {
    groups: ["associations", "sql"],
    dependsOn: [sqlEmployeeRelationsTest]
}
function workspaceRelationsTest() returns error? {
    SQLRainierClient rainierClient = check new ();

    Employee employee22 = {
        empNo: "employee-22",
        firstName: "James",
        lastName: "David",
        birthDate: {year: 1996, month: 11, day:13},
        gender: "F",
        hireDate: {year: 2021, month: 8, day: 1},
        departmentDeptNo: "department-22",
        workspaceWorkspaceId: "workspace-22"
    };
    _ = check rainierClient->/employees.post([employee22]);    

    stream<WorkspaceInfo, error?> workspaceStream = rainierClient->/workspaces.get();
    WorkspaceInfo[] workspaces = check from WorkspaceInfo workspace in workspaceStream 
        select workspace;

    WorkspaceInfo retrieved = check rainierClient->/workspaces/["workspace-22"].get();

    WorkspaceInfo expected = {
        workspaceType: "medium",
        location: {
            buildingCode: "building-22",
            city: "Manhattan",
            state: "New York",
            country: "USA",
            postalCode: "10570",
            'type: "owned"
        },
        employees: [
            {
                empNo: "employee-21",
                firstName: "Tom",
                lastName: "Scott",
                birthDate: {year: 1992, month: 11, day:13},
                gender: "M",
                hireDate: {year: 2022, month: 8, day: 1},
                departmentDeptNo: "department-22",
                workspaceWorkspaceId: "workspace-22"
            },
            {
                empNo: "employee-22",
                firstName: "James",
                lastName: "David",
                birthDate: {year: 1996, month: 11, day:13},
                gender: "F",
                hireDate: {year: 2021, month: 8, day: 1},
                departmentDeptNo: "department-22",
                workspaceWorkspaceId: "workspace-22"
            }
        ]
    };

    boolean found = false;
    _ = from WorkspaceInfo workspace in workspaces
        do {
            if workspace == expected {
                found = true;
            }
        };

    if !found {
        test:assertFail("Expected WorkspaceInfo not found.");
    }

    test:assertEquals(retrieved, expected);

    check rainierClient.close();
}

@test:Config {
    groups: ["associations", "sql"],
    dependsOn: [sqlEmployeeRelationsTest]
}
function buildingRelationsTest() returns error? {
    SQLRainierClient rainierClient = check new ();

    stream<BuildingInfo, error?> buildingStream = rainierClient->/buildings.get();
    BuildingInfo[] buildings = check from BuildingInfo building in buildingStream 
        select building;

    BuildingInfo retrieved = check rainierClient->/buildings/["building-22"].get();

    BuildingInfo expected = {
        buildingCode: "building-22",
        city: "Manhattan",
        state: "New York",
        country: "USA",
        postalCode: "10570",
        'type: "owned",
        workspaces: [
            {
                workspaceId: "workspace-22",
                workspaceType: "medium",
                locationBuildingCode: "building-22"
            }
        ]
    };

    boolean found = false;
    _ = from BuildingInfo building in buildings
        do {
            if (building.buildingCode == "building-22") {
                found = true;
                test:assertEquals(building, expected);
            }
        };

    if !found {
        test:assertFail("Expected BuildingInfo not found.");
    }

    test:assertEquals(retrieved, expected);

    check rainierClient.close();
}
