import ballerina/time;

enum Gender {
    MALE,
    FEMALE
}

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

type Workspace record {|
    readonly string workspaceId;
    string workspaceType;

    Building location;
    Employee[] employees;
|};

type Building record {|
    readonly string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    string 'type;

    Workspace[] workspaces;
|};

type Department record {|
    readonly string deptNo;
    string deptName;

    Employee[] employees;
|};

type OrderItem record {|
    readonly string orderId;
    readonly string itemId;
    int quantity;
    string notes;
|};
