# Specification: Ballerina Persist Library

_Owners_: @daneshk @niveathika @kaneeldias  
_Reviewers_: @daneshk  
_Created_: 2022/01/25   
_Updated_: 2023/06/01  
_Edition_: Swan Lake  

## Introduction

This is the specification for the `persist` standard library of the [Ballerina language](https://ballerina.io/), which provides functionality to store and query data conveniently through a data model instead of the SQL query language.

The `persist` library specification has evolved and may continue to evolve in the future. The released versions of the specification can be found under the relevant GitHub tag. 

If you have any feedback or suggestions about the library, start a discussion via a [GitHub issue](https://github.com/ballerina-platform/ballerina-standard-library/issues) or in the [Discord server](https://discord.gg/ballerinalang). Based on the outcome of the discussion, the specification and implementation can be updated. Community feedback is always welcome. Any accepted proposal, which affects the specification is stored under `/docs/proposals`. Proposals under discussion can be found with the label `type/proposal` in GitHub.

The conforming implementation of the specification is released and included in the distribution. Any deviation from the specification is considered a bug.

## Contents

1. [Overview](#1-overview)  
2. [Data Model Definition](#2-data-model-definition)  
    * 2.1. [Entity Type Definition](#21-entity-type-definition)  
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

This `persist` standard library provides Ballerina provides the functionality to store and query data conveniently through a data model.

The `persist` tools provides following functionalities,
1. Define and validate the entity data model definitions in the `persist` folder
2. Initialize the Ballerina Persistence Layer for every model definitions in the `persist` folder
3. Generate persistence derived entity types and clients
4. Push persistence schema to the data store (only with supported data sources)
5. Migration support for supported data stores (experimental feature)

## 2. Data Model Definition

Within a Ballerina project, the data model should be defined in a separate bal file under the `persist` directory. This file is not considered part of the Ballerina project and is used only for data model definition.

The Ballerina `persist` library defines a mechanism to express the application's data model using Ballerina record types. All record types will be an entity in the model.

### 2.1 Entity Type Definition

An EntityType is defined using `SimpleType` and `EntityType` fields.

```ballerina
   // This are the type definitions for the data model when using MySQL
    type SimpleType ()|boolean|int|float|decimal|string|byte[]|time:Date|time:TimeOfDay|time:Utc|time:Civil;
    type EntityType record {|
       SimpleType|EntityType|EntityType[]...;
    |};
```

> *Note*: The data types for `SimpleType` supported by `persist` will vary by data source. For example, the `byte` type is not supported by MySQL.

This design use fields of type `EntityType` or `EntityType[]` to define associations between two entities.

Here are some examples of entity type definitions:

```ballerina
// Valid with MySQL, in-memory and Google Sheets
type Employee record {|
   int id;
   string fname;
   string lname;
   Department department; // EntityType
|};

// Valid with MySQL and in-memory
type Department record {|
   int id;
   string name;
   byte[] logo; // Google Sheets does not support array types
   Employee[] employees; // EntityType
|};

// Valid with in-memory only
type Department record {|
   int id;
   string name;
   int[] integerArray; // MySQL only supports `byte[]` array type and Google Sheets does not support array types
   Employee[] employees; // EntityType
|};

// Invalid with all data sources
 Employee record {|
   int|string id;  // Persist does not support union data types
   string fname;
   string lname;
   Department department; // EntityType
|};
```
### 2.2 Entity Attributes Definition

Ballerina record fields are used to model the attributes of an entity. The type of the field should be a subtype of SimpleType.

#### 2.2.1 Identity Field(s)

The entity must contain at least one identity field. The field's value is used to identify each record uniquely. The identity field(s) is indicated `readonly` flag.

> *Note*: Only `int`, `string`, `float`, `boolean`, and `decimal` types are supported as identity fields.

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

#### 2.2.2 Nullable Field(s)

Say type T is a subtype of SimpleType, and T does not contain (),

| Field definition  |                           Semantics                           |       Examples       |  
|:-----------------:|:-------------------------------------------------------------:|:--------------------:|  
|      T field      | Mapped to a non-nullable type in the datastore (if supported) |       int id;        |  
|     T? field      |   Mapped to a nullable type in the datastore (if supported)   | string? description; |  
|     T field?      |                          Not allowed                          |          -           |  
|     T? field?     |                          Not allowed                          |          -           |

### 2.3 Relationship Definition

Ballerina record fields are used to model a connection between two entities. The type of the field should be a subtype of EntityType|EntityType?|EntityType[].

This design supports the following cardinalities:
1. One-to-one (1-1)
2. One-to-many (1-n)

The relation field is mandatory in both entities.

#### 2.3.1 One-to-one (1-1)

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
- A `User` may own a `Car` or do not own one.

The first record, `Car`, which holds the `EntityType` field `owner` is taken as the owner in the 1-1 relationship and will include the foreign key of the second record, `User`.

The default foreign key field name will be `ownerId` in the `Car` table, which refers to the identity field of the `User` table by default. (`<lowercasedRelatedFieldName><First-LetterCapitalizedIdentityFieldName>`)

#### 2.3.2 One-to-Many (1-n)

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
The entity that contains the field of type `EntityType` is taken as the owner in the 1-n relationship.

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
5. Resource names are lowercase pluralized entity names.
6. The resource method should return the derived entity types.
7. Resource method with path parameters will support composite identity field by having multiple path parameters.
