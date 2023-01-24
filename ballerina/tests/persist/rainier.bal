import ballerina/time;

enum Gender {
    M,
    F
}

type Building record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;

    Workspace[] workspaces;
|};

type Workspace record {|
    readonly string workspaceId;
    string workspaceType;

    Building location;
    Employee? employee;
|};

type Department record {|
    readonly string deptNo;
    string deptName;

    Employee[] employees;
|};

type Employee record {|
    readonly string empNo;
    string firstName;
    string lastName;
    time:Date birthDate;
    string gender;
    time:Date hireDate;

    Department department;
    Workspace workspace;
|};
