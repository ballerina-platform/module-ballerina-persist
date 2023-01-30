# Specification: Ballerina Persist Library

_Owners_: @daneshk @niveathika @kaneeldias  
_Reviewers_: @daneshk  
_Created_: 2022/01/25   
_Updated_: 2022/01/25  
_Edition_: Swan Lake  

## Introduction

This is the specification for the `persist` standard library of the [Ballerina language](https://ballerina.io/), which provides functionality to store and query data conveniently through data model instead of SQL query language.

The `persist` library specification has evolved and may continue to evolve in the future. The released versions of the specification can be found under the relevant GitHub tag. 

If you have any feedback or suggestions about the library, start a discussion via a [GitHub issue](https://github.com/ballerina-platform/ballerina-standard-library/issues) or in the [Discord server](https://discord.gg/ballerinalang). Based on the outcome of the discussion, the specification and implementation can be updated. Community feedback is always welcome. Any accepted proposal, which affects the specification is stored under `/docs/proposals`. Proposals under discussion can be found with the label `type/proposal` in GitHub.

The conforming implementation of the specification is released and included in the distribution. Any deviation from the specification is considered a bug.

## Contents

1. [Overview](#1-overview)  
2. [Data Model Definition](#2-data-model-definition)  
    * 2.1. [EntityType Definition](#21-entitytype-definition)  
    * 2.2. [Entity Attributes Definition](#22-entity-attributes-definition)  
        * 2.2.1. [Identifier Field(s)](#221-identifier-fields)  
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

Within a Ballerina project, the data model should be defined in a separate bal file under the `persist` directory. This file is not considered part of the Ballerina project and is used only for data model definition.

The Ballerina `persist` library defines a mechanism to express the application's data model using Ballerina record type. Any record type that is a subtype of the `EntityType` will be an entity in the model.

### 2.1. EntityType Definition

An EntityType is defined using `SimpleType` and `EntityType` fields. 

```ballerina
    type SimpleType ()|boolean|int|float|decimal|string|byte[]|time:Date|time:TimeOfDay|time:Utc|time:Civil;
    type EntityType record {|
       SimpleType|EntityType|EntityType[]...;
    |};
```

1. SimpleType:	
    From the data source perspective, a field of `SimpleType` contains only one value. i.e., Each `SimpleType` field maps to a field of data.
    > *Note*: This does not support the union type of `SimpleType`. i.e., `int|string` is not supported.

2. EntityType:
    An entity can contain fields of SimpleType, EntityType, or EntityType[]. This design use fields of type EntityType or EntityType[] to define associations between two entities.

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
    | float | REAL |
    | decimal | DECIMAL |
    | string | VARCHAR(191) |
    | byte[] | BINARY |
    | time:Date | DATE |
    | time:TimeOfDay | TIME |
    | time:Utc | TIMESTAMP |
    | time:Civil | DATETIME |

### 2.2. Entity Attributes Definition

Ballerina record fields are used to model the attributes of an entity. The type of the field should be a subtype of SimpleType.

#### 2.2.1. Identifier Field(s)

The entity must contain at least one identifier field. The field's value is used to identify each record uniquely. The identifier field(s) is indicated `readonly` flag.

Say type T is a subtype of SimpleType, and T does not contain (),

```ballerina
type EntityType record {|
    readonly T <fieldName>;
|} 
```
The identifier field can be a single field or a combination of multiple fields. 

```ballerina
type EntityType record {|
    readonly T <fieldName1>;
    readonly T <fieldName2>;
|} 
```

#### 2.2.2. Nullable Field(s)

Say type T is a subtype of SimpleType, and T does not contain (),
| Field definition | Semantics | Examples |  
| :---: | :---: | :---: |  
| T field | Mapped to a non-nullable column in the DB | int id; |  
| T? field | Mapped to a nullable column in the DB | string? description; |  
| T field? | Not allowed | - |  
| T? field? | Not allowed | - |  

### 2.3. Relationship Definition

Ballerina record fields are used to model the relationship between two entities. The type of the field should be a subtype of EntityType|EntityType[].

This design supports the following cardinalities:
1. One-to-one (1-1)
2. One-to-many (1-n)

The relationship field is mandatory in both entities.

#### 2.3.1. One-to-one (1-1)
 
A 1-1 relationship is defined by a field of type `EntityType` in both entities. 

Each User must have a Car, and each Car must have an owner.

```ballerina
type Car record {|
   readonly int id;
   string name;
   User owner;
|};

type User record {|
   readonly int id;
   string name;
   Car car;
|};
```

The first record, `Car`, is taken as the parent in the 1-1 relationship and will include the foreign key of the second record, `User`.

The default foreign key field name will be `userId` in the `Car` table, which refers to the identifier field of the `User` table by default. (`<lowercasedAssociatedEntityName><First-Letter Capitalized IdentifierFieldName>`)

#### 2.3.2. One-to-Many (1-n)

A 1-n relationship is defined by a field of type `EntityType` in one entity and `EntityType[]` in the other.

A User can own zero or more cars, and a Car must have an owner. 

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
The entity that contains the field of type `EntityType` is taken as the parent in the 1-n relationship and will include the foreign key.

The default foreign key field name will be `userId` in the `Car` table, which refers to the identifier field of the `User` table by default. (`<lowercasedAssociatedEntityName><First-Letter Capitalized IdentifierFieldName>`)

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
    Employee employee; // 1-1 relation (child)
|};
```

There are three types of derived entity types:
1. Entity Types  
    These are the types defined in the data model. These are used to indicate the data structure in the data source. The entity who is the association parent will include the foreign key field.
    ```ballerina
    public type Workspace record {|
        readonly string workspaceId;
        string workspaceType;
        string buildingBuildingCode;
    |};
    ```
    
2. Insert Types
    These are records used to insert data in the data source. This is same as the Entity Type.
    ```ballerina
    public type WorkspaceInsert Workspace;
    ```

3. Update Types
    These are records used to update data in the data source. These are entity types without the identifier fields. All fields will be optional. Only the value provided fields will be updated.
    ```ballerina
    public type WorkspaceUpdate record {|
        string workspaceType?;
        string buildingBuildingCode?;
    |};
    ```

### 3.2. Persist Clients

Persist Clients are derived for each data model definition file.

The skeleton of the Persist client is as follows,
```ballerina
public client class RainierClient {
    *persist:AbstractPersistClient;

    public function init() returns persist:Error? {
    }

    isolated resource function get workspaces() returns stream<Workspace, persist:Error?> {
    };

    isolated resource function get workspaces/[string workspaceId]() returns Workspace|persist:Error {
    };

    isolated resource function post workspaces(WorkspaceInsert[] data) returns string[]|persist:Error {
    };

    isolated resource function put workspaces/[string workspaceId](WorkspaceUpdate data) returns Workspace|persist:Error {
    };

    isolated resource function delete workspaces/[string workspaceId]() returns Workspace|persist:Error {
    };

    public function close() returns persist:Error? {
    }
}
```

The conventions used in deriving the Persist client are as follows:
1. The Client name is derived from the name of the file. Example: `rainier.bal` will generate a client named `RainierClient`(<First Letter Capitalized File Name>Client).
2. The client should be of the `persist:AbstractPersistClient` type.
3. It should contain `init()` and `close()` functions.
4. It should contain five resource methods for each entity type defined in the data model. Resource methods are get, get(get by identifier), post, put, and delete.
5. Resource names are lowercase entity names.
6. The resource method should return the derived entity types.
7. Resource method with path parameters will support composite identifier field by having multiple path parameters.

The implementation of the client is as follows:
```ballerina
import ballerinax/mysql;
import ballerina/sql;

const WORKSPACE = "workspace";

public client class RainierClient {
    *persist:AbstractPersistClient;

    private final mysql:Client dbClient;

    private final record {|Metadata...;|} metadata = {
        "workspace": {
            entityName: "Workspace",
            tableName: `Workspace`,
            fieldMetadata: {
                workspaceId: {columnName: "workspaceId", 'type: string},
                workspaceType: {columnName: "workspaceType", 'type: string},
                buildingBuildingCode: {columnName: "buildingBuildingCode", 'type: string}
            },
            keyFields: ["workspaceId"]
        }
    };

    private final map<SQLClient> persistClients;
    
    public function init() returns persist:Error? {
        do {
            self.dbClient = check new (host = host, user = user, password = password, database = database, port = port);

            self.persistClients = {
                workspace: check new (self.dbClient, self.metadata.get(WORKSPACE))
            };
        } on fail error e {
            return <persist:Error>error(e.message());
        }
    }

    isolated resource function get workspace() returns stream<Workspace, persist:Error?> {
        stream<record{}, sql:Error?>|persist:Error result = self.persistClients.get(WORKSPACE).runReadQuery(Workspace);
        if result is persist:Error {
            return new stream<Workspace, persist:Error?>(new WorkspaceStream((), result));
        } else {
            return new stream<Workspace, persist:Error?>(new WorkspaceStream(result));
        }
    };

    isolated resource function get workspace/[string workspaceId]() returns Workspace|persist:Error {
        Workspace|error workspace = (check self.persistClients.get(WORKSPACE).runReadByKeyQuery(Workspace, workspaceId)).cloneWithType(Workspace);
        if workspace is error {
            return <persist:Error>error(workspace.message());
        }
        return workspace;
    };

    isolated resource function post workspace(WorkspaceInsert[] data) returns string[]|persist:Error {
        _ = check self.persistClients.get(WORKSPACE).runBatchInsertQuery(data);
        return from WorkspaceInsert inserted in data
               select inserted.workspaceId;
    };

    isolated resource function put workspace/[string workspaceId](WorkspaceUpdate data) returns Workspace|persist:Error {
        _ = check self.persistClients.get(WORKSPACE).runUpdateQuery(workspaceId, data);
        return self->/workspace/[workspaceId].get();
    };

    isolated resource function delete workspace/[string workspaceId]() returns Workspace|persist:Error {
        Workspace result = check self->/workspace/[workspaceId].get();
        _ = check self.persistClients.get(WORKSPACE).runDeleteQuery(workspaceId);
        return result;
    };

    public function close() returns persist:Error? {
        error? e = self.dbClient.close();
        if e is error {
            return <persist:Error>error(e.message());
        }
    }
}

public class WorkspaceStream {
    private stream<anydata, sql:Error?>? anydataStream;
    private persist:Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, persist:Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|Workspace value;|}|persist:Error? {
        if self.err is error {
            return self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <persist:Error>error(streamValue.message());
            } else {
                do {
                    record {|Workspace value;|} nextRecord = {value: check streamValue.value.cloneWithType(Workspace)};
                    return nextRecord;
                } on fail error e {
                    return <persist:Error>e;
                }
            }
        } else {
            // Unreachable code
            return ();
        }
    }

    public isolated function close() returns persist:Error? {
        check persist:closeEntityStream(self.anydataStream);
    }
}
```
