import ballerina/time;
import ballerinax/redis;
import ballerina/persist as _;

public enum Gender {
    M,
    F
}

public type MedicalNeed record {|
    readonly int needId;
    readonly string stringNeedId?;

    boolean booleanType;
    int intType;
    float floatType;
    decimal decimalType;
    string stringType;
    time:Date dateType;
    time:TimeOfDay timeOfDayType;
    time:Utc utcType;
    time:Civil civilType;
    Gender gender;
    redis:Client clientType;
    json jsonTest;
    error errorType;

    boolean booleanTypeOptional?;
    time:Civil|string unionType;

    Gender[] genderArray;
    byte[] beneficiaryIdByteArray;
    boolean[] booleanArray;
    json[] jsonArray;
    time:Civil[] periodArray;
    error[] errorArrayType;
    redis:Client[] clientArrayType;
|};

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
