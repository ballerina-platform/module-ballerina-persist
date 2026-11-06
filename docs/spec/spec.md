# Specification: Ballerina Persist Library

_Owners_: @daneshk @niveathika @kaneeldias  
_Reviewers_: @daneshk  
_Created_: 2022/01/25  
_Updated_: 2026/11/06  
_Edition_: Swan Lake  

## Introduction

This is the specification for the `persist` standard library of the [Ballerina language](https://ballerina.io/), which provides functionality to store and query data conveniently through a data model instead of the SQL query language. It covers how a data model is defined, and the derived entity types and persist client that are generated from it. The `bal persist` commands and the code generation are specified in the [persist tools specification](https://github.com/ballerina-platform/persist-tools/blob/main/docs/spec/spec.md).

The conforming implementation of the specification is released and included in the distribution. Any deviation from the specification is considered a bug. The released versions of the specification can be found under the relevant GitHub tag.

### Notation

The key words MUST, MUST NOT, REQUIRED, SHALL, SHALL NOT, SHOULD, SHOULD NOT, RECOMMENDED, MAY and OPTIONAL are interpreted as described in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174) when, and only when, they appear in all capitals. Sentences that state behaviour in the present tense are also normative. The overview, notes and examples are informative.

## Contents

- [1. Overview](#1-overview)
- [2. Terminology](#2-terminology)
- [3. Data model definition](#3-data-model-definition)
    - [3.1. Description](#31-description)
    - [3.2. Model definition file](#32-model-definition-file)
    - [3.3. Entity types](#33-entity-types)
    - [3.4. Supported types](#34-supported-types)
    - [3.5. Entity attributes](#35-entity-attributes)
        - [3.5.1. Identity fields](#351-identity-fields)
        - [3.5.2. Nullable and optional fields](#352-nullable-and-optional-fields)
    - [3.6. Relations](#36-relations)
        - [3.6.1. One-to-one relations](#361-one-to-one-relations)
        - [3.6.2. One-to-many relations](#362-one-to-many-relations)
        - [3.6.3. Multiple relations between two entities](#363-multiple-relations-between-two-entities)
    - [3.7. Datastore annotations](#37-datastore-annotations)
    - [3.8. Compile-time validation](#38-compile-time-validation)
- [4. Derived entity types and persist clients](#4-derived-entity-types-and-persist-clients)
    - [4.1. Description](#41-description)
    - [4.2. Derived entity types](#42-derived-entity-types)
    - [4.3. Persist clients](#43-persist-clients)
    - [4.4. Native SQL methods](#44-native-sql-methods)
    - [4.5. Transactions](#45-transactions)
    - [4.6. Errors](#46-errors)
- [5. Security considerations](#5-security-considerations)
- [References](#references)

## 1. Overview

The `persist` library lets a Ballerina application store and query data through a data model. The data model is written as Ballerina record types, each of which is an entity. From the data model, the persist tool generates derived entity types and a persist client, which the application uses to create, read, update and delete records in a datastore.

The [persist tool](https://github.com/ballerina-platform/persist-tools/blob/main/docs/spec/spec.md) provides the following functionalities:

1. Define and validate the entity data model definitions in the `persist` directory.
2. Initialize the Ballerina persistence layer for every model definition in the `persist` directory.
3. Generate the derived entity types and clients.
4. Push the persistence schema to the datastore, only with supported datastores.
5. Migrate the schema of supported datastores. This is an experimental feature.

Each datastore is implemented by a separate library, whose specification covers what is specific to the datastore, such as its supported types, annotations, client behaviour and errors:

| Datastore | Library | Specification |
|---|---|---|
| MySQL, MSSQL, PostgreSQL, H2 | `ballerinax/persist.sql` | [persist.sql specification](https://github.com/ballerina-platform/module-ballerinax-persist.sql/blob/main/docs/spec/spec.md) |
| In-memory | `ballerinax/persist.inmemory` | [persist.inmemory specification](https://github.com/ballerina-platform/module-ballerinax-persist.inmemory/blob/main/docs/spec/spec.md) |
| Google Sheets | `ballerinax/persist.googlesheets` | [persist.googlesheets specification](https://github.com/ballerina-platform/module-ballerinax-persist.googlesheets/blob/main/docs/spec/spec.md) |
| Redis | `ballerinax/persist.redis` | [persist.redis specification](https://github.com/ballerina-platform/module-ballerinax-persist.redis/blob/main/docs/spec/spec.md) |

## 2. Terminology

- **Model definition file:** the Ballerina file in the `persist` directory of a project that defines the data model.
- **Entity:** a record type defined in the model definition file.
- **Simple type:** a type that a non-relation field of an entity can have, as specified in [3.4](#34-supported-types).
- **Identity field:** a field of an entity declared with `readonly`. The identity fields of an entity identify each of its records uniquely.
- **Relation field:** a field of an entity whose type is another entity, an optional entity, or an array of an entity.
- **Owner:** the entity of a relation that holds the foreign key of the other entity.
- **Datastore:** the data source that a persist client stores data in, as listed in [1](#1-overview).
- **Datastore specification:** the specification of the library that implements a datastore, as listed in [1](#1-overview).
- **Derived entity types:** the record and type descriptor types that the persist tool derives from each entity, as specified in [4.2](#42-derived-entity-types).
- **Persist client:** the client that the persist tool generates from a model definition file, as specified in [4.3](#43-persist-clients).

## 3. Data model definition

### 3.1. Description

The `persist` library defines a mechanism to express the data model of an application using Ballerina record types.

### 3.2. Model definition file

1. The data model of a project is defined in a model definition file in the `persist` directory, or in the `persist/<model-name>` directory for a named model. The persist tool creates the file as `model.bal`.
2. The model definition file is not considered part of the Ballerina project, and is used only for data model definition.
3. Every record type definition in the model definition file is an entity.
4. The model definition file MAY contain enum declarations. A field MAY have an enum type declared in the model.
5. The model definition file MUST NOT contain any module-level declaration other than record type definitions and enum declarations.
6. An import declaration in the model definition file MUST NOT have a prefix other than `_`.

### 3.3. Entity types

1. An entity is defined using `SimpleType` and `EntityType` fields:

    ```ballerina
    type SimpleType ()|boolean|int|float|decimal|string|byte[]|time:Date|time:TimeOfDay|time:Utc|time:Civil;
    type EntityType record {|
       SimpleType|EntityType|EntityType[]...;
    |};
    ```

2. The simple types that a datastore supports are specified in [3.4](#34-supported-types).
3. A field of type `EntityType` or `EntityType[]` defines an association between two entities, as specified in [3.6](#36-relations).
4. An entity MUST be a closed record type, and MUST NOT have a rest field.
5. An entity field MUST NOT have a default value, and an entity MUST NOT include another type.
6. Entity names, and the field names of an entity, are compared ignoring case, and MUST be unique.

For example:

```ballerina
type Employee record {|
   readonly int id;
   string fname;
   string lname;
   Department department; // EntityType
|};

type Department record {|
   readonly int id;
   string name;
   Employee[] employees; // EntityType
|};
```

### 3.4. Supported types

1. The simple types of `persist` are `boolean`, `int`, `float`, `decimal`, `string`, enum types, `byte[]`, `time:Date`, `time:TimeOfDay`, `time:Utc` and `time:Civil`.
2. Each datastore supports a set of field types and array types, which its datastore specification states. A datastore MAY reject some of the simple types, such as `byte[]`, when its storage does not suit them, and MAY support other types.
3. A field whose type, or array type, the datastore does not support is rejected at compile time, as specified in [3.8](#38-compile-time-validation).

### 3.5. Entity attributes

Ballerina record fields are used to model the attributes of an entity. The type of an attribute field should be a simple type of the datastore.

#### 3.5.1. Identity fields

1. An entity must contain at least one identity field. The value of the identity field is used to identify each record uniquely.
2. An identity field is indicated by the `readonly` flag.
3. Only the `int`, `string`, `float`, `boolean` and `decimal` types are supported as identity fields, with every datastore.
4. An identity field MUST NOT be nillable.
5. The identity can be a single field or a combination of multiple fields.

#### 3.5.2. Nullable and optional fields

Let `T` be a simple type that does not contain `()`.

| Field definition | Semantics | Example |
|---|---|---|
| `T field` | Mapped to a non-nullable type in the datastore. | `int id;` |
| `T? field` | Mapped to a nullable type in the datastore, unless the datastore specification does not allow nillable fields of type `T`. | `string? description;` |
| `T field?` | Not allowed, unless the datastore specification allows optional fields. An identity field is never optional. | - |
| `T? field?` | Not allowed. | - |

### 3.6. Relations

1. Ballerina record fields are used to model a connection between two entities. The type of a relation field should be a subtype of `EntityType|EntityType?|EntityType[]`.
2. The following cardinalities are supported:
    - One-to-one (1-1), specified in [3.6.1](#361-one-to-one-relations).
    - One-to-many (1-n), specified in [3.6.2](#362-one-to-many-relations).
3. Many-to-many (n-m) relations, defined by a field of type `EntityType[]` in both entities, are not supported.
4. The relation field is mandatory in both entities.
5. An entity MUST NOT have a relation field whose type is the entity itself.
6. The owner includes one foreign key field for each identity field of the other entity. The default foreign key field name is `<lowercasedRelationFieldName><First-LetterCapitalizedIdentityFieldName>`, and it refers to that identity field.
7. The owner MUST NOT declare a field with the default foreign key field name, unless the relation field has the `@sql:Relation` annotation and lists that field in its `keys`, as specified in the [persist.sql specification](https://github.com/ballerina-platform/module-ballerinax-persist.sql/blob/main/docs/spec/spec.md).

#### 3.6.1. One-to-one relations

1. A 1-1 relationship is defined by a field of type `EntityType` in one entity and `EntityType?` in the other.
2. The entity that holds the `EntityType` field is the owner of the relationship, and includes the foreign key of the other entity.

For example:

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

Here, a `Car` must have a `User` as the owner, and a `User` may or may not own a `Car`. `Car`, which holds the `EntityType` field `owner`, is the owner of the relationship and includes the foreign key of `User`. The default foreign key field name is `ownerId` in the `Car` table, which refers to the identity field of the `User` table.

#### 3.6.2. One-to-many relations

1. A 1-n relationship is defined by a field of type `EntityType` in one entity and `EntityType[]` in the other. Neither relation field is nillable.
2. The entity that holds the `EntityType` field is the owner of the relationship.
3. An entity that is related to no records of the other entity holds the empty array, `[]`, in its `EntityType[]` field.

For example:

```ballerina
type Car record {|
   readonly int id;
   string name;
   User owner;
|};

type User record {|
   readonly int id;
   string name;
   Car[] cars;
|};
```

Here, a `Car` must have a `User` as the owner, and a `User` may own multiple `Car`s or none, represented with the empty array `[]`.

#### 3.6.3. Multiple relations between two entities

1. Two entities MAY have more than one relation between them. Each relation has its own pair of relation fields.
2. The relation fields of each entity that refer to the other entity are paired in declaration order.
3. All relations between the same two entities MUST have the same owner.

### 3.7. Datastore annotations

A datastore library MAY define annotations that configure how entities and fields are stored in its datastore. The annotations of the SQL datastores, such as `@sql:Name` and `@sql:Relation`, are defined by `ballerinax/persist.sql`, and are specified in the [persist.sql specification](https://github.com/ballerina-platform/module-ballerinax-persist.sql/blob/main/docs/spec/spec.md). An annotation that the configured datastore does not use is accepted, and has no effect.

### 3.8. Compile-time validation

The `persist` compiler plugin validates a model definition file when the `Ballerina.toml` file of its package configures a datastore for the model, and validates the field types against that datastore. It reports these conditions as errors:

| Condition | Code |
|---|---|
| The model has a module-level declaration other than a record type definition or an enum declaration ([3.2](#32-model-definition-file)) | `PERSIST_101` |
| An import declaration has a prefix other than `_` ([3.2](#32-model-definition-file)) | `PERSIST_102` |
| An entity is not a closed record type ([3.3](#33-entity-types)) | `PERSIST_201` |
| An entity name is declared more than once, ignoring case ([3.3](#33-entity-types)) | `PERSIST_202` |
| An entity has a rest field ([3.3](#33-entity-types)) | `PERSIST_301` |
| An entity field has a default value ([3.3](#33-entity-types)) | `PERSIST_302` |
| An entity includes another type ([3.3](#33-entity-types)) | `PERSIST_303` |
| An entity field is optional, with a datastore that does not allow optional fields ([3.5.2](#352-nullable-and-optional-fields)) | `PERSIST_304` |
| A field's type is not a simple type of the datastore ([3.4](#34-supported-types)) | `PERSIST_305` |
| A field's type is an array type that the datastore does not support ([3.4](#34-supported-types)) | `PERSIST_306` |
| A field name is declared more than once in an entity, ignoring case ([3.3](#33-entity-types)) | `PERSIST_307` |
| A field is nillable with a datastore that does not allow it ([3.5.2](#352-nullable-and-optional-fields)) | `PERSIST_308` |
| An identity field is optional, with a datastore that allows optional fields ([3.5.2](#352-nullable-and-optional-fields)) | `PERSIST_309` |
| A relation field's type is the entity itself ([3.6](#36-relations)) | `PERSIST_401` |
| A relation field has no corresponding relation field in the related entity ([3.6](#36-relations)) | `PERSIST_402` |
| The relations between two entities do not all have the same owner ([3.6.3](#363-multiple-relations-between-two-entities)) | `PERSIST_403` |
| Neither relation field of a 1-1 relationship is `EntityType?` ([3.6.1](#361-one-to-one-relations)) | `PERSIST_404` |
| Both relation fields of a 1-1 relationship are `EntityType?` ([3.6.1](#361-one-to-one-relations)) | `PERSIST_405` |
| A relation field of a 1-n relationship is nillable ([3.6.2](#362-one-to-many-relations)) | `PERSIST_406` |
| Both relation fields of a relation are arrays ([3.6](#36-relations)) | `PERSIST_420` |
| The owner declares a field with the default foreign key field name that the `@sql:Relation` annotation of the relation field does not list ([3.6](#36-relations)) | `PERSIST_422` |
| An entity has no identity field ([3.5.1](#351-identity-fields)) | `PERSIST_501` |
| An identity field is nillable ([3.5.1](#351-identity-fields)) | `PERSIST_502` |
| An identity field is not of type `int`, `string`, `float`, `boolean` or `decimal` ([3.5.1](#351-identity-fields)) | `PERSIST_503` |

A datastore library MAY validate its own annotations at compile time, as its datastore specification states.

## 4. Derived entity types and persist clients

### 4.1. Description

The persist tool generates the derived entity types and the persist client from the model definition file, as specified in [client generation](https://github.com/ballerina-platform/persist-tools/blob/main/docs/spec/spec.md#5-client-generation) of the persist tools specification. The persist client uses the derived entity types.

### 4.2. Derived entity types

Six derived entity types are derived from each entity:

1. **Entity type:** the type defined in the data model, without its relation fields. It indicates the data structure in the datastore. The owner of a relation includes the foreign key field(s).
2. **Insert type:** the record used to insert data in the datastore. It is the same as the entity type, except that a datastore MAY leave out a field whose value the datastore generates, as its datastore specification states.
3. **Update type:** the record used to update data in the datastore. It is the entity type without the identity fields, with all fields optional. Only the fields for which values are provided are updated.
4. **Optionalized type:** the entity type with all fields optional. It is not directly used in any operation.
5. **With relations type:** a record that includes all fields of the optionalized type, and adds the relation fields as optional fields of the optionalized types of the related entities. An array relation field stays an array. It is not directly used in any operation.
6. **Target type:** the type used to retrieve data from the datastore. If the entity contains a relation field, the target type is a type description of the with relations type. Otherwise, it is a type description of the optionalized type.

For example, for these entities:

```ballerina
type Building record {|
    readonly string buildingCode;
    string city;
    Workspace[] workspaces;
|};

type Workspace record {|
    readonly string workspaceId;
    string workspaceType;
    Building location; // Workspace owns this 1-n relation
    Employee[] employees; // Employee owns this 1-n relation
|};

type Employee record {|
    readonly int empNo;
    string name;
    Workspace workspace;
|};
```

the derived entity types of `Workspace` are:

```ballerina
public type Workspace record {|
    readonly string workspaceId;
    string workspaceType;
    string locationBuildingCode;
|};

public type WorkspaceInsert Workspace;

public type WorkspaceUpdate record {|
    string workspaceType?;
    string locationBuildingCode?;
|};

public type WorkspaceOptionalized record {|
    readonly string workspaceId?;
    string workspaceType?;
    string locationBuildingCode?;
|};

public type WorkspaceWithRelations record {|
    *WorkspaceOptionalized;
    BuildingOptionalized location?;
    EmployeeOptionalized[] employees?;
|};

public type WorkspaceTargetType typedesc<WorkspaceWithRelations>;
```

### 4.3. Persist clients

1. A persist client is derived for each model definition file.
2. The client class is named `Client`. The client generated for the `h2` test datastore is named `H2Client`, and the client generated for the `inmemory` test datastore is named `InMemoryClient`.
3. The client is an isolated client class of the `persist:AbstractPersistClient` type.
4. The client contains the `init` and `close` functions.
5. The client contains five resource methods for each entity in the data model: `get`, `get` by identity, `post`, `put` and `delete`.
6. Resource names are the lowercase pluralized entity names.
7. The resource methods return the derived entity types.
8. A resource method with path parameters supports a composite identity by having one path parameter for each identity field, in the order of the identity fields.
9. The resource methods behave as follows:

    | Resource method | Path | Input | Result |
    |---|---|---|---|
    | `get` | `<resource>` | The target type | A stream of records of the target type. |
    | `get` by identity | `<resource>/[<identity>]` | The target type | The record of the target type with the given identity. |
    | `post` | `<resource>` | An array of insert type records | The identity values of the inserted records, in the order of the given records. For a composite identity, each value is a tuple of the identity field values. |
    | `put` | `<resource>/[<identity>]` | An update type record | The updated record of the entity type. |
    | `delete` | `<resource>/[<identity>]` | None | The record as it was read before the deletion. |

For example, the in-memory client for the `Workspace` entity of [4.2](#42-derived-entity-types) has this skeleton:

```ballerina
public isolated client class Client {
    *persist:AbstractPersistClient;

    public isolated function init() returns persist:Error? {
    }

    isolated resource function get workspaces(WorkspaceTargetType targetType = <>) returns stream<targetType, persist:Error?> {
    }

    isolated resource function get workspaces/[string workspaceId](WorkspaceTargetType targetType = <>) returns targetType|persist:Error {
    }

    isolated resource function post workspaces(WorkspaceInsert[] data) returns string[]|persist:Error {
    }

    isolated resource function put workspaces/[string workspaceId](WorkspaceUpdate value) returns Workspace|persist:Error {
    }

    isolated resource function delete workspaces/[string workspaceId]() returns Workspace|persist:Error {
    }

    public isolated function close() returns persist:Error? {
    }
}
```

### 4.4. Native SQL methods

The clients of the SQL datastores have the remote methods `queryNativeSQL` and `executeNativeSQL`, which run SQL written by the user, as specified in the [persist.sql specification](https://github.com/ballerina-platform/module-ballerinax-persist.sql/blob/main/docs/spec/spec.md). The `persist` client API does not define them.

### 4.5. Transactions

The `persist` library does not define transaction behaviour. Whether, and how, the client of a datastore takes part in a Ballerina `transaction` statement is specified in its datastore specification. Currently, only the clients of the SQL datastores take part in transactions.

### 4.6. Errors

1. The `init` and `close` functions and the resource methods return a `persist:Error` on failure. The `get` resource method returns the error as the completion value of the stream.
2. The `persist` module defines these error types. Each one is a distinct subtype of `persist:Error`.

    | Error type | Condition |
    |---|---|
    | `persist:NotFoundError` | No record has the given key. |
    | `persist:AlreadyExistsError` | A record with the given key, or with the same unique value, already exists. |
    | `persist:ConstraintViolationError` | The operation violates a foreign key constraint. |
    | `persist:ReadBackError` | A record is updated, but cannot be read back. The update is saved in the datastore. |

3. The `persist:getNotFoundError` function creates a `persist:NotFoundError` with the message `A record with the key '<key>' does not exist for the entity '<entity>'.`, and the `persist:getAlreadyExistsError` function creates a `persist:AlreadyExistsError` with the message `A record with the key '<key>' already exists for the entity '<entity>'.`. A key that is a record is written with `toBalString`, and any other key with `toString`.
4. Only the clients of the SQL datastores return a `persist:ReadBackError`, from the `put` resource method, when the update is saved but the updated record cannot be read back.
5. Which resource method of a client returns which error is specified in its datastore specification.

## 5. Security considerations

The `persist` library does not connect to a datastore. The generated persist client connects to the datastore with the database configuration that the persist tool generates, and the security considerations of that configuration are specified in the [persist tools specification](https://github.com/ballerina-platform/persist-tools/blob/main/docs/spec/spec.md#9-security-considerations).

## References

- [Ballerina persist tools specification](https://github.com/ballerina-platform/persist-tools/blob/main/docs/spec/spec.md)
- [Ballerina persist.sql specification](https://github.com/ballerina-platform/module-ballerinax-persist.sql/blob/main/docs/spec/spec.md)
- [Ballerina persist.inmemory specification](https://github.com/ballerina-platform/module-ballerinax-persist.inmemory/blob/main/docs/spec/spec.md)
- [Ballerina persist.googlesheets specification](https://github.com/ballerina-platform/module-ballerinax-persist.googlesheets/blob/main/docs/spec/spec.md)
- [Ballerina persist.redis specification](https://github.com/ballerina-platform/module-ballerinax-persist.redis/blob/main/docs/spec/spec.md)
- [RFC 2119: Key words for use in RFCs to Indicate Requirement Levels](https://www.rfc-editor.org/rfc/rfc2119)
- [RFC 8174: Ambiguity of Uppercase vs Lowercase in RFC 2119 Key Words](https://www.rfc-editor.org/rfc/rfc8174)
