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
function employeeReadManyTest3() returns error? {
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
        buildingBuildingCode: "building-22"
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
            buildingBuildingCode: "building-22"
        }
    };

    test:assertTrue(employees.indexOf(expected) is int, "Expected EmployeeInfo not found.");
    check rainierClient.close();
}

public type DepartmentInfo record {|
    readonly string deptNo;
    string deptName;
    Employee[] employee;
|};

@test:Config {
    groups: ["associations"],
    dependsOn: [employeeDeleteTestNegative]
}
function departmentReadManyTest2() returns error? {
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
        buildingBuildingCode: "building-12"
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
        employee: [employee11, employee12]
    };

    test:assertTrue(departments.indexOf(expected) is int, "Expected DepartmentInfo not found.");
    check rainierClient.close();
}
