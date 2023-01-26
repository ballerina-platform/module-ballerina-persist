import ballerina/time;

type Building record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    string 'type;

    Workspace[] workspaces;
|};

type Workspace record {|
    readonly string workspaceId;
    string workspaceType;

    Building location;
    Employee employee;
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

type OrderItem record {|
    readonly string orderId;
    readonly string itemId;
    int quantity;
    string notes;
|};
