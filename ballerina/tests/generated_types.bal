import ballerina/time;

public type Building record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    string 'type;
|};

public type Workspace record {|
    readonly string workspaceId;
    string workspaceType;
    string buildingBuildingCode;
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

    string departmentDeptNo;
    string workspaceWorkspaceId;
|};

public type OrderItem record {|
    readonly string orderId;
    readonly string itemId;
    int quantity;
    string notes;
|};

type BuildingInsert Building;

type DepartmentInsert Department;

type WorkspaceInsert Workspace;

type EmployeeInsert Employee;

type OrderItemInsert OrderItem;

public type BuildingUpdate record {|
    string city?;
    string state?;
    string country?;
    string postalCode?;
    string 'type?;
|};

public type WorkspaceUpdate record {|
    string workspaceType?;
    string buildingBuildingCode?;
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

    string departmentDeptNo?; 
    string workspaceWorkspaceId?;
|};

public type OrderItemUpdate record {|
    int quantity;
    string notes;
|};
