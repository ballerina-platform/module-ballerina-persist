import ballerina/time;

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

type EmployeeInsert Employee;

public type EmployeeUpdate record {|
    string firstName?;
    string lastName?;
    time:Date birthDate?;
    string gender?;
    time:Date hireDate?;

    string departmentDeptNo?; 
    string workspaceWorkspaceId?;
|};

public type Workspace record {|
    readonly string workspaceId;
    string workspaceType;
    string buildingBuildingCode;
|};

type WorkspaceInsert Workspace;

public type WorkspaceUpdate record {|
    string workspaceType?;
    string buildingBuildingCode?;
|};

public type Building record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    string 'type;
|};

type BuildingInsert Building;

public type BuildingUpdate record {|
    string city?;
    string state?;
    string country?;
    string postalCode?;
    string 'type?;
|};

public type Department record {|
    readonly string deptNo;
    string deptName;
|};

type DepartmentInsert Department;

public type DepartmentUpdate record {|
    string deptName?;
|};

public type OrderItem record {|
    readonly string orderId;
    readonly string itemId;
    int quantity;
    string notes;
|};

type OrderItemInsert OrderItem;

public type OrderItemUpdate record {|
    int quantity;
    string notes;
|};
