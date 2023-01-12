import ballerina/time;

enum Gender {
    M,
    F
}

// Defines the entity type with the entity identity
type Building record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;

    Workspace[] workspaces;
|};

// Defines the entity collection/set with the entity identity
// Also defines the resource used in the client API 
table<Building> key(buildingCode) buldings = table[];

type Workspace record {|
    readonly string workspaceId;
    string workspaceType;

    Building location;
    Employee? employee;
|};

table<Workspace> key(workspaceId) workspaces = table[];

type Department record {|
    readonly string deptNo;
    string deptName;

    Employee[] employees;
|};

table<Department> key(deptNo) departments = table[];

type Employee record {|
    readonly string empNo;
    string firstName;
    string lastName;
    time:Date birthDate;
    Gender gender;
    time:Date hireDate;

    Department department;
    Workspace workspace;
|};

table<Employee> key(empNo) employees = table[];