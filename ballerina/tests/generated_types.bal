import ballerina/time;

// TODO: Remove "public" from the generated types
public enum Gender {
    M,
    F
}

// TODO: Make all these model types readonly
public type Building record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
|};

public type Workspace record {|
    readonly string workspaceId;
    string workspaceType;

    string buildingCode;
|};

public type Department record {|
    readonly string deptNo;
    string deptName;
|};

public type Employee record {|
    readonly string empNo;
    string firstName;
    string lastName;
    time:Date birthDate;
    string gender;
    time:Date hireDate;

    string deptNo;
    string workspaceId;
|};

type BuildingInsert Building;

type DepartmentInsert Department;

type WorkspaceInsert Workspace;

type EmployeeInsert Employee;

public type BuildingUpdate record {|
    string city?;
    string state?;
    string country?;
    string postalCode?;
|};

public type WorkspaceUpdate record {|
    string workspaceType?;
    string buildingCode?;
|};

public type DepartmentUpdate record {|
    string deptName?;
|};

public type EmployeeUpdate record {|
    string firstName?;
    string lastName?;
    time:Date birthDate?;
    string gender?;
    time:Date hireDate?;

    string deptNo?; 
    string workspaceId?;
|};
