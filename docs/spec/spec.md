# Specification: Ballerina Persist Library

_Owners_: @daneshk @niveathika @kaneeldias  
_Reviewers_: @daneshk  
_Created_: 2022/01/25   
_Updated_: 2023/04/26  
_Edition_: Swan Lake  

## Introduction

This is the specification for the `persist` standard library of the [Ballerina language](https://ballerina.io/), which provides functionality to store and query data conveniently through a data model instead of the SQL query language.

The `persist` library specification has evolved and may continue to evolve in the future. The released versions of the specification can be found under the relevant GitHub tag. 

If you have any feedback or suggestions about the library, start a discussion via a [GitHub issue](https://github.com/ballerina-platform/ballerina-standard-library/issues) or in the [Discord server](https://discord.gg/ballerinalang). Based on the outcome of the discussion, the specification and implementation can be updated. Community feedback is always welcome. Any accepted proposal, which affects the specification is stored under `/docs/proposals`. Proposals under discussion can be found with the label `type/proposal` in GitHub.

The conforming implementation of the specification is released and included in the distribution. Any deviation from the specification is considered a bug.

## Contents

1. [Overview](#1-overview)  
2. [Data Model Definition](#2-data-model-definition)  
    * 2.1. [EntityType Definition](#21-entitytype-definition)  
    * 2.2. [Entity Attributes Definition](#22-entity-attributes-definition)  
        * 2.2.1. [Identity Field(s)](#221-identity-fields)  
        * 2.2.2. [Nullable Field(s)](#222-nullable-fields)  
    * 2.3. [Relationship Definition](#23-relationship-definition)    
        * 2.3.1. [One-to-one (1-1)](#231-one-to-one-1-1)  
        * 2.3.2. [One-to-Many (1-n)](#232-one-to-many-1-n)  
3. [Derived Entity Types and Persist Clients](#3-derived-entity-types-and-persist-clients)  
    * 3.1. [Derived Entity Types](#31-derived-entity-types)  
    * 3.2. [Persist Clients](#32-persist-clients)  

## 1. Overview

The `persist` standard library creates a programming model to store and query data conveniently. The library uses the statically typed nature of Ballerina language to provide a convenient way to define, store and query data. The initial release of the `persist` library only supports the MySQL data providers.

## 2. Data Model Definition

Within a Ballerina project, the data model should be defined in a separate bal file under the `persist` directory. This file is not considered part of the Ballerina project and is used only for the data model definition.

The Ballerina `persist` library defines a mechanism to express the application's data model using the Ballerina record type. Any record type that is a subtype of the `EntityType` will be an entity in the model.

### 2.1. EntityType Definition

An EntityType is defined using `SimpleType` and `EntityType` fields. 

```ballerina
type SimpleType ()|boolean|int|float|decimal|string|byte[]|time:Date|time:TimeOfDay|time:Utc|time:Civil;
type EntityType record {|
   SimpleType|EntityType|EntityType[]...;
|};
```
1. Simple Type:  
   From the data source perspective, a field of `SimpleType` contains only one value. i.e., Each `SimpleType` field maps to a field of data.
   > *Note*: This does not support the union type of `SimpleType`. i.e., `int|string` is not supported.

2. Entity Type:  
   An entity can contain fields of `SimpleType`, `EntityType`, or `EntityType[]`. This design uses fields of type `EntityType` or `EntityType[]` to define associations between two entities.

Here are some examples of subtypes of the entity type:

```ballerina
// Valid 
type Employee record {|
   int id; // SimpleType
   string fname;
   string lname;
   Department department; // EntityType
|};


// Valid 
type Department record {|
   int id;
   string name;
   byte[] logo;
   Employee[] employees; // EntityType
|};


// Invalid
type Employee record {|
   int|string id; 
   string fname;
   string lname;
   Department department; // EntityType
|};
```
Simple Types are mapped to native data source types as follows:
1. MySQL
    | Ballerina Type | MySQL Type |
    | :---: | :---: |
    | () | NULL |
    | boolean | BOOLEAN |
    | int | INT |
    | float | DOUBLE |
    | decimal | DECIMAL(65,30) |
    | string | VARCHAR(191) |
    | byte[] | LONGBLOB |
    | enum | ENUM |
    | time:Date | DATE |
    | time:TimeOfDay | TIME |
    | time:Utc | TIMESTAMP |
    | time:Civil | DATETIME |

### 2.2. Entity Attributes Definition

Ballerina record fields are used to model the attributes of an entity. The type of the field should be a subtype of `SimpleType`.

#### 2.2.1. Identity Field(s)

The entity must contain at least one identity field. This field's value is used to identify each record uniquely. The identity field(s) is indicated by the `readonly` flag.

Say type T is one of `int`, `string`, `float`, `boolean` or `decimal` types,

```ballerina
type EntityType record {|
    readonly T <fieldName>;
|} 
```
The identity field can be a single field or a combination of multiple fields. 

```ballerina
type EntityType record {|
    readonly T <fieldName1>;
    readonly T <fieldName2>;
|} 
```

#### 2.2.2. Nullable Field(s)

Say type T is a subtype of `SimpleType`, and T does not contain (),
| Field definition | Semantics | Examples |  
| :---: | :---: | :---: |  
| T field | Mapped to a non-nullable column in the DB | int id; |  
| T? field | Mapped to a nullable column in the DB | string? description; |  
| T field? | Not allowed | - |  
| T? field? | Not allowed | - |  
### 2.3. Relationship Definition

Ballerina record fields are used to model a connection between two entities. The type of the field should be a subtype of `EntityType|EntityType?|EntityType[]`.

This design supports the following cardinalties:
1. One-to-one (1-1)
2. One-to-many (1-n)

The relation field is mandatory in both entities.

#### 2.3.1. One-to-one (1-1)
 
A 1-1 relationship is defined by a field of type `EntityType` in one entity and `EntityType?` in the other.

```ballerina
type Car record {|
   readonly int id;
   string name;
   User owner;
|};

type User record {|
   readonly int id;
   string name;
   Car? car;
|};
```

The above entities explains the following,
 - A `Car` must have a `User` as the owner.
 - A `User` may or may not own a `Car`.

In first record, `Car`, the `EntityType` field `owner` is taken as the owner in the 1-1 relationship and will include the foreign key of the second record, `User`.

The default foreign key field name will be `ownerId` in the `Car` table, which refers to the identity field of the `User` table by default. (`<lowercasedRelatedFieldName><First-LetterCapitalizedIdentityFieldName>`)

#### 2.3.2. One-to-Many (1-n)

A 1-n relationship is defined by a field of type `EntityType` in one entity and `EntityType[]` in the other.

```ballerina
type Car record {|
   readonly int id;
   string name;
   User owner;
|};

type User record {|
   int id;
   string name;
   Car[] cars;
|};
```

The above entities explains the following,
- A `Car` must have a `User` as the owner.
- A `User` may own multiple `Car`s or do not own one. (Represented with empty array `[]`)
- 
The entity that contains the field of type `EntityType` is taken as the owner in the 1-n relationship and will include the foreign key.

The default foreign key field name will be `ownerId` in the `Car` table, which refers to the identity field of the `User` table by default. (`<lowercasedRelatedFieldName><First-LetterCapitalizedIdentityFieldName>`)

## 3. Derived Entity Types and Persist Clients

Persist CLI tool will generate the derived Entity Types and the clients from the model definition.

### 3.1. Derived Entity Types

Ballerina record types used in the `PersistClient` are derived from the entity types defined in the data model.

Example of a defined entity,
```ballerina
type Workspace record {|
    readonly string workspaceId;
    string workspaceType;
    Building location; // 1-n relation (parent)
    Employee[] employees; // 1-n relation (child)
|};
```

There are six types of derived entity types:
1. Entity Types  
    These are the types defined in the data model. These are used to indicate the data structure in the data source. The entity who is the association parent will include the foreign key field(s).
    ```ballerina
    public type Workspace record {|
        readonly string workspaceId;
        string workspaceType;
        string locationBuildingCode;
    |};
    ```
    
2. Insert Types
    These are the records used to insert data in the data source. This is same as the Entity Type.
    ```ballerina
    public type WorkspaceInsert Workspace;
    ```

3. Update Types
    These are the records used to update data in the data source. These are entity types without the identity fields. All fields will be optional. Only the fields for which values are provided will be updated.
    ```ballerina
    public type WorkspaceUpdate record {|
        string workspaceType?;
        string locationBuildingCode?;
    |};
    ```
   
4. Optionalized Types
    These are the same as the Entity Types, but all the fields are made optional. This type is not directly used in any operations.
    ```ballerina
    public type WorkspaceOptionalized record {|
        readonly string workspaceId?;
        string workspaceType?;
        string locationBuildingCode?;
    |};
    ```
   
5. With Relations Types
    This types inherits all fields from the corresponding `Optionalized` type, and adds the relation fields as optional. This type is not directly used in any operations.
    ```ballerina
    public type WorkspaceWithRelations record {|
        *WorkspaceOptionalized;
        BuildingOptionalized location?;
        EmployeeOptionalized[] employees?;
    |};
    ```

6. Target Types
    This type is used to retrieve data from the data source. If the entity contains a relation field, the target type 
    will be a type description of the corresponding `WithRelations` type. Otherwise, the target type will be a 
    type description of the corresponding `Optionalized` type.
    ```ballerina
    public type WorkspaceTargetType typedesc<WorkspaceWithRelations>;
    ```
    
### 3.2. Persist Clients

Persist Clients are derived for each data model definition file.

The skeleton of the Persist client is as follows,
```ballerina
public client class RainierClient {
    *persist:AbstractPersistClient;

    public function init() returns persist:Error? {
    }

    isolated resource function get workspace(WorkspaceTargetType targetType = <>) returns stream<targetType, Error?> {
    };

    isolated resource function get workspace/[string workspaceId](WorkspaceTargetType targetType = <>) returns targetType|Error {
    };

    isolated resource function post workspace(WorkspaceInsert[] data) returns string[]|persist:Error {
    };

    isolated resource function put workspace/[string workspaceId](WorkspaceUpdate data) returns Workspace|persist:Error {
    };

    isolated resource function delete workspace/[string workspaceId]() returns Workspace|persist:Error {
    };

    public function close() returns persist:Error? {
    }
}
```

The conventions used in deriving the Persist client are as follows:
1. The Client name is derived from the name of the file. Example: `rainier.bal` will generate a client named `RainierClient`(<First Letter Capitalized File Name>Client).
2. The client should be of the `persist:AbstractPersistClient` type.
3. It should contain `init()` and `close()` functions.
4. It should contain five resource methods for each entity type defined in the data model. Resource methods are get, get(get by identity), post, put, and delete.
5. Resource names are lowercase entity names.
6. The resource method should return the derived entity types.
7. Resource method with path parameters will support composite identity field by having multiple path parameters.

The implementation of the client is as follows:
```ballerina
import ballerina/persist;
import ballerinax/mysql;
import ballerina/jballerina.java;

const EMPLOYEE = "employee";
const WORKSPACE = "workspace";
const BUILDING = "building";
const DEPARTMENT = "department";
const ORDER_ITEM = "orderitem";

public client class RainierClient {
    *persist:AbstractPersistClient;

    private final mysql:Client dbClient;

    private final map<persist:SQLClient> persistClients;

    private final record {|persist:Metadata...;|} metadata = {
        "employee": {
            entityName: "Employee",
            tableName: `Employee`,
            fieldMetadata: {
                empNo: {columnName: "empNo"},
                firstName: {columnName: "firstName"},
                lastName: {columnName: "lastName"},
                birthDate: {columnName: "birthDate"},
                gender: {columnName: "gender"},
                hireDate: {columnName: "hireDate"},
                departmentDeptNo: {columnName: "departmentDeptNo"},
                workspaceWorkspaceId: {columnName: "workspaceWorkspaceId"},
                "department.deptNo": {relation: {entityName: "department", refField: "deptNo"}},
                "department.deptName": {relation: {entityName: "department", refField: "deptName"}},
                "workspace.workspaceId": {relation: {entityName: "workspace", refField: "workspaceId"}},
                "workspace.workspaceType": {relation: {entityName: "workspace", refField: "workspaceType"}},
                "workspace.locationBuildingCode": {relation: {entityName: "workspace", refField: "locationBuildingCode"}}
            },
            keyFields: ["empNo"],
            joinMetadata: {
                department: {entity: Department, fieldName: "department", refTable: "Department", refColumns: ["deptNo"], joinColumns: ["departmentDeptNo"], 'type: ONE_TO_MANY},
                workspace: {entity: Workspace, fieldName: "workspace", refTable: "Workspace", refColumns: ["workspaceId"], joinColumns: ["workspaceWorkspaceId"], 'type: ONE_TO_MANY}
            }
        },
        "workspace": {
            entityName: "Workspace",
            tableName: `Workspace`,
            fieldMetadata: {
                workspaceId: {columnName: "workspaceId"},
                workspaceType: {columnName: "workspaceType"},
                locationBuildingCode: {columnName: "locationBuildingCode"},
                "location.buildingCode": {relation: {entityName: "building", refField: "buildingCode"}},
                "location.city": {relation: {entityName: "building", refField: "city"}},
                "location.state": {relation: {entityName: "building", refField: "state"}},
                "location.country": {relation: {entityName: "building", refField: "country"}},
                "location.postalCode": {relation: {entityName: "building", refField: "postalCode"}},
                "location.type": {relation: {entityName: "building", refField: "type"}},
                "employees[].empNo": {relation: {entityName: "employee", refField: "empNo"}},
                "employees[].firstName": {relation: {entityName: "employee", refField: "firstName"}},
                "employees[].lastName": {relation: {entityName: "employee", refField: "lastName"}},
                "employees[].birthDate": {relation: {entityName: "employee", refField: "birthDate"}},
                "employees[].gender": {relation: {entityName: "employee", refField: "gender"}},
                "employees[].hireDate": {relation: {entityName: "employee", refField: "hireDate"}},
                "employees[].departmentDeptNo": {relation: {entityName: "employee", refField: "departmentDeptNo"}},
                "employees[].workspaceWorkspaceId": {relation: {entityName: "employee", refField: "workspaceWorkspaceId"}}
            },
            keyFields: ["workspaceId"],
            joinMetadata: {
                location: {entity: Building, fieldName: "location", refTable: "Building", refColumns: ["buildingCode"], joinColumns: ["locationBuildingCode"], 'type: ONE_TO_MANY},
                employees: {entity: Employee, fieldName: "employees", refTable: "Employee", refColumns: ["workspaceWorkspaceId"], joinColumns: ["workspaceId"], 'type: MANY_TO_ONE}
            }
        },
        "building": {
            entityName: "Building",
            tableName: `Building`,
            fieldMetadata: {
                buildingCode: {columnName: "buildingCode"},
                city: {columnName: "city"},
                state: {columnName: "state"},
                country: {columnName: "country"},
                postalCode: {columnName: "postalCode"},
                'type: {columnName: "type"},
                "workspaces[].workspaceId": {relation: {entityName: "workspace", refField: "workspaceId"}},
                "workspaces[].workspaceType": {relation: {entityName: "workspace", refField: "workspaceType"}},
                "workspaces[].locationBuildingCode": {relation: {entityName: "workspace", refField: "locationBuildingCode"}}
            },
            keyFields: ["buildingCode"],
            joinMetadata: {
                workspaces: {entity: Workspace, fieldName: "workspaces", refTable: "Workspace", refColumns: ["locationBuildingCode"], joinColumns: ["buildingCode"], 'type: MANY_TO_ONE}
            }
        },
        "department": {
            entityName: "Department",
            tableName: `Department`,
            fieldMetadata: {
                deptNo: {columnName: "deptNo"},
                deptName: {columnName: "deptName"},
                "employees[].empNo": {relation: {entityName: "employee", refField: "empNo"}},
                "employees[].firstName": {relation: {entityName: "employee", refField: "firstName"}},
                "employees[].lastName": {relation: {entityName: "employee", refField: "lastName"}},
                "employees[].birthDate": {relation: {entityName: "employee", refField: "birthDate"}},
                "employees[].gender": {relation: {entityName: "employee", refField: "gender"}},
                "employees[].hireDate": {relation: {entityName: "employee", refField: "hireDate"}},
                "employees[].departmentDeptNo": {relation: {entityName: "employee", refField: "departmentDeptNo"}},
                "employees[].workspaceWorkspaceId": {relation: {entityName: "employee", refField: "workspaceWorkspaceId"}}
            },
            keyFields: ["deptNo"],
            joinMetadata: {
                employees: {entity: Employee, fieldName: "employees", refTable: "Employee", refColumns: ["departmentDeptNo"], joinColumns: ["deptNo"], 'type: MANY_TO_ONE}
            }
        },
        "orderitem": {
            entityName: "OrderItem",
            tableName: `OrderItem`,
            fieldMetadata: {
                orderId: {columnName: "orderId"},
                itemId: {columnName: "itemId"},
                quantity: {columnName: "quantity"},
                notes: {columnName: "notes"}
            },
            keyFields: ["orderId", "itemId"]
        }
    };

    public function init() returns persist:Error? {
        mysql:Client|error dbClient = new (host = host, user = user, password = password, database = database, port = port);
        if dbClient is error {
            return <persist:Error>error(dbClient.message());
        }
        self.dbClient = dbClient;
        self.persistClients = {
            employee: check new (self.dbClient, self.metadata.get(EMPLOYEE)),
            workspace: check new (self.dbClient, self.metadata.get(WORKSPACE)),
            building: check new (self.dbClient, self.metadata.get(BUILDING)),
            department: check new (self.dbClient, self.metadata.get(DEPARTMENT)),
            orderitem: check new (self.dbClient, self.metadata.get(ORDER_ITEM))
        };
    }

    isolated resource function get employee(EmployeeTargetType targetType = <>) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get employee/[string empNo](EmployeeTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post employee(EmployeeInsert[] data) returns string[]|persist:Error {
        _ = check self.persistClients.get(EMPLOYEE).runBatchInsertQuery(data);
        return from EmployeeInsert inserted in data
            select inserted.empNo;
    }

    isolated resource function put employee/[string empNo](EmployeeUpdate data) returns Employee|persist:Error {
        _ = check self.persistClients.get(EMPLOYEE).runUpdateQuery(empNo, data);
        return self->/employee/[empNo].get();
    }

    isolated resource function delete employee/[string empNo]() returns Employee|persist:Error {
        Employee result = check self->/employee/[empNo].get();
        _ = check self.persistClients.get(EMPLOYEE).runDeleteQuery(empNo);
        return result;
    }

    isolated resource function get workspace(WorkspaceTargetType targetType = <>) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get workspace/[string workspaceId](WorkspaceTargetType targetType = <>) returns targetType|persist:Error  = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post workspace(WorkspaceInsert[] data) returns string[]|persist:Error {
        _ = check self.persistClients.get(WORKSPACE).runBatchInsertQuery(data);
        return from WorkspaceInsert inserted in data
            select inserted.workspaceId;
    }

    isolated resource function put workspace/[string workspaceId](WorkspaceUpdate data) returns Workspace|persist:Error {
        _ = check self.persistClients.get(WORKSPACE).runUpdateQuery(workspaceId, data);
        return self->/workspace/[workspaceId].get();
    }

    isolated resource function delete workspace/[string workspaceId]() returns Workspace|persist:Error {
        Workspace result = check self->/workspace/[workspaceId].get();
        _ = check self.persistClients.get(WORKSPACE).runDeleteQuery(workspaceId);
        return result;
    }

    isolated resource function get building(BuildingTargetType targetType = <>) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get building/[string buildingCode](BuildingTargetType targetType = <>) returns targetType|persist:Error  = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "queryOne"
    } external;


    isolated resource function post building(BuildingInsert[] data) returns string[]|persist:Error {
        _ = check self.persistClients.get(BUILDING).runBatchInsertQuery(data);
        return from BuildingInsert inserted in data
            select inserted.buildingCode;
    }

    isolated resource function put building/[string buildingCode](BuildingUpdate data) returns Building|persist:Error {
        _ = check self.persistClients.get(BUILDING).runUpdateQuery(buildingCode, data);
        return self->/building/[buildingCode].get();
    }

    isolated resource function delete building/[string buildingCode]() returns Building|persist:Error {
        Building result = check self->/building/[buildingCode].get();
        _ = check self.persistClients.get(BUILDING).runDeleteQuery(buildingCode);
        return result;
    }

    isolated resource function get department(DepartmentTargetType targetType = <>) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get department/[string deptNo](DepartmentTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post department(DepartmentInsert[] data) returns string[]|persist:Error {
        _ = check self.persistClients.get(DEPARTMENT).runBatchInsertQuery(data);
        return from DepartmentInsert inserted in data
            select inserted.deptNo;
    }

    isolated resource function put department/[string deptNo](DepartmentUpdate data) returns Department|persist:Error {
        _ = check self.persistClients.get(DEPARTMENT).runUpdateQuery(deptNo, data);
        return self->/department/[deptNo].get();
    }

    isolated resource function delete department/[string deptNo]() returns Department|persist:Error {
        Department result = check self->/department/[deptNo].get();
        _ = check self.persistClients.get(DEPARTMENT).runDeleteQuery(deptNo);
        return result;
    }

    isolated resource function get orderitem(OrderItemTargetType targetType = <>) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get orderitem/[string orderId]/[string itemId](OrderItemTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post orderitem(OrderItemInsert[] data) returns [string, string][]|persist:Error {
        _ = check self.persistClients.get(ORDER_ITEM).runBatchInsertQuery(data);
        return from OrderItemInsert inserted in data
            select [inserted.orderId, inserted.itemId];
    }

    isolated resource function put orderitem/[string orderId]/[string itemId](OrderItemUpdate data) returns OrderItem|persist:Error {
        _ = check self.persistClients.get(ORDER_ITEM).runUpdateQuery({orderId: orderId, itemId: itemId}, data);
        return self->/orderitem/[orderId]/[itemId].get();
    }

    isolated resource function delete orderitem/[string orderId]/[string itemId]() returns OrderItem|persist:Error {
        OrderItem result = check self->/orderitem/[orderId]/[itemId].get();
        _ = check self.persistClients.get(ORDER_ITEM).runDeleteQuery({orderId: orderId, itemId: itemId});
        return result;
    }

    public function close() returns persist:Error? {
        error? result = self.dbClient.close();
        if result is error {
            return <persist:Error>error(result.message());
        }
        return result;
    }
}
```
