import ballerina/test;

public type EmployeeInfo record {|
    string firstName;
    string lastName;
    record {|
        string deptName;
    |} department;
    Workspace workspace;
|};

@test:Config {
    groups:  ["associations"],
    dependsOn: [employeeDeleteTestNegative]
}
function employeeRelationsTest() returns error? {
    RainierClient rainierClient = check new ();

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

    _ = check rainierClient->/building.post([building22]);    
    _ = check rainierClient->/department.post([department22]);    
    _ = check rainierClient->/workspace.post([workspace22]);    
    _ = check rainierClient->/employee.post([employee21]);    


    stream<EmployeeInfo, Error?> employeeStream = rainierClient->/employee.get();
    EmployeeInfo[] employees = check from EmployeeInfo employee in employeeStream 
        select employee;

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
    check rainierClient.close();
}

public type DepartmentInfo record {|
    readonly string deptNo;
    string deptName;
    record {|
        string firstName;
        string lastName;
    |}[] employees;
|};

@test:Config {
    groups: ["associations"],
    dependsOn: [employeeDeleteTestNegative]
}
function departmentRelationsTest() returns error? {
    RainierClient rainierClient = check new ();

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

    _ = check rainierClient->/building.post([building12]);    
    _ = check rainierClient->/department.post([department12]);    
    _ = check rainierClient->/workspace.post([workspace12]);    
    _ = check rainierClient->/employee.post([employee11, employee12]);    

    stream<DepartmentInfo, error?> departmentStream = rainierClient->/department.get();
    DepartmentInfo[] departments = check from DepartmentInfo department in departmentStream 
        select department;

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
    check rainierClient.close();
}

public type WorkspaceInfo record {|
    readonly string workspaceId;
    string workspaceType;
    Building location;
    Employee[] employees;
|};

@test:Config {
    groups: ["associations"],
    dependsOn: [employeeRelationsTest]
}
function workspaceRelationsTest() returns error? {
    RainierClient rainierClient = check new ();

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
    _ = check rainierClient->/employee.post([employee22]);    

    stream<WorkspaceInfo, error?> workspaceStream = rainierClient->/workspace.get();
    WorkspaceInfo[] workspaces = check from WorkspaceInfo workspace in workspaceStream 
        select workspace;

    WorkspaceInfo expected = {
        workspaceId: "workspace-22",
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
            if (workspace.workspaceId == "workspace-22") {
                found = true;
                test:assertEquals(workspace, expected);
            }
        };

    if !found {
        test:assertFail("Expected WorkspaceInfo not found.");
    }

    check rainierClient.close();
}

public type BuildingInfo record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    string 'type;
    Workspace[] workspaces;
|};

@test:Config {
    groups: ["associations"],
    dependsOn: [employeeRelationsTest]
}
function buildingRelationsTest() returns error? {
    RainierClient rainierClient = check new ();

    stream<BuildingInfo, error?> buildingStream = rainierClient->/building.get();
    BuildingInfo[] buildings = check from BuildingInfo building in buildingStream 
        select building;

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

    check rainierClient.close();

}