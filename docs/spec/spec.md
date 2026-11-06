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
    - [3.4. Entity attributes](#34-entity-attributes)
        - [3.4.1. Identity fields](#341-identity-fields)
        - [3.4.2. Nullable fields](#342-nullable-fields)
    - [3.5. Relations](#35-relations)
        - [3.5.1. One-to-one relations](#351-one-to-one-relations)
        - [3.5.2. One-to-many relations](#352-one-to-many-relations)
    - [3.6. Compile-time validation](#36-compile-time-validation)
- [4. Derived entity types and persist clients](#4-derived-entity-types-and-persist-clients)
    - [4.1. Description](#41-description)
    - [4.2. Derived entity types](#42-derived-entity-types)
    - [4.3. Persist clients](#43-persist-clients)
    - [4.4. Errors](#44-errors)
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

## 2. Terminology

- **Model definition file:** the Ballerina file in the `persist` directory of a project that defines the data model.
- **Entity:** a record type defined in the model definition file.
- **Simple type:** a type that a non-relation field of an entity can have, as given by `SimpleType` in [3.3](#33-entity-types).
- **Identity field:** a field of an entity declared with `readonly`. The identity fields of an entity identify each of its records uniquely.
- **Relation field:** a field of an entity whose type is another entity, an optional entity, or an array of an entity.
- **Owner:** the entity of a relation that holds the foreign key of the other entity.
- **Datastore:** the data source that a persist client stores data in, such as MySQL, the in-memory datastore or Google Sheets.
- **Derived entity types:** the record and type descriptor types that the persist tool derives from each entity, as specified in [4.2](#42-derived-entity-types).
- **Persist client:** the client that the persist tool generates from a model definition file, as specified in [4.3](#43-persist-clients).

## 3. Data model definition

### 3.1. Description

The `persist` library defines a mechanism to express the data model of an application using Ballerina record types.

### 3.2. Model definition file

1. Within a Ballerina project, the data model should be defined in a separate `.bal` file under the `persist` directory.
2. The model definition file is not considered part of the Ballerina project, and is used only for data model definition.
3. Every record type in the model definition file is an entity in the model.

### 3.3. Entity types

1. An entity is defined using `SimpleType` and `EntityType` fields. When MySQL is the datastore, the types are as follows:

    ```ballerina
    // This are the type definitions for the data model when using MySQL
    type SimpleType ()|boolean|int|float|decimal|string|byte[]|time:Date|time:TimeOfDay|time:Utc|time:Civil;
    type EntityType record {|
       SimpleType|EntityType|EntityType[]...;
    |};
    ```

2. The simple types that `persist` supports vary by datastore. For example, the `byte` type is not supported by MySQL.
3. A field of type `EntityType` or `EntityType[]` defines an association between two entities, as specified in [3.5](#35-relations).

For example, these entity types are valid or invalid depending on the datastore:

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

### 3.4. Entity attributes

Ballerina record fields are used to model the attributes of an entity. The type of an attribute field should be a subtype of `SimpleType`.

#### 3.4.1. Identity fields

1. An entity must contain at least one identity field. The value of the identity field is used to identify each record uniquely.
2. An identity field is indicated by the `readonly` flag.
3. Only the `int`, `string`, `float`, `boolean` and `decimal` types are supported as identity fields.
4. The identity can be a single field or a combination of multiple fields.

#### 3.4.2. Nullable fields

Let `T` be a subtype of `SimpleType` that does not contain `()`.

| Field definition | Semantics | Example |
|---|---|---|
| `T field` | Mapped to a non-nullable type in the datastore, if supported. | `int id;` |
| `T? field` | Mapped to a nullable type in the datastore, if supported. | `string? description;` |
| `T field?` | Not allowed. | - |
| `T? field?` | Not allowed. | - |

### 3.5. Relations

1. Ballerina record fields are used to model a connection between two entities. The type of a relation field should be a subtype of `EntityType|EntityType?|EntityType[]`.
2. The following cardinalities are supported:
    - One-to-one (1-1), specified in [3.5.1](#351-one-to-one-relations).
    - One-to-many (1-n), specified in [3.5.2](#352-one-to-many-relations).
3. The relation field is mandatory in both entities.

#### 3.5.1. One-to-one relations

1. A 1-1 relationship is defined by a field of type `EntityType` in one entity and `EntityType?` in the other.
2. The entity that holds the `EntityType` field is the owner of the relationship, and includes the foreign key of the other entity.
3. The default foreign key field name in the owner is `<lowercasedRelatedFieldName><First-LetterCapitalizedIdentityFieldName>`, and it refers to the identity field of the other entity by default.

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

#### 3.5.2. One-to-many relations

1. A 1-n relationship is defined by a field of type `EntityType` in one entity and `EntityType[]` in the other.
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
   int id;
   string name;
   Car[] cars;
|};
```

Here, a `Car` must have a `User` as the owner, and a `User` may own multiple `Car`s or none, represented with the empty array `[]`.

### 3.6. Compile-time validation

The `persist` compiler plugin reports these conditions in the model definition file as errors:

| Condition | Code |
|---|---|
| An entity field has an optional field definition, `T field?` or `T? field?` ([3.4.2](#342-nullable-fields)) | `PERSIST_304` |
| A field's type is not a simple type that the datastore supports, such as `byte` with MySQL ([3.3](#33-entity-types)) | `PERSIST_305` |
| A field's type is an array of a type that the datastore does not support as an array, such as `int[]` with MySQL or any array with Google Sheets ([3.3](#33-entity-types)) | `PERSIST_306` |
| A relation field has no corresponding relation field in the related entity ([3.5](#35-relations)) | `PERSIST_402` |
| Neither relation field of a 1-1 relationship is `EntityType?` ([3.5.1](#351-one-to-one-relations)) | `PERSIST_404` |
| Both relation fields of a 1-1 relationship are `EntityType?` ([3.5.1](#351-one-to-one-relations)) | `PERSIST_405` |
| A relation field of a 1-n relationship is `EntityType?` ([3.5.2](#352-one-to-many-relations)) | `PERSIST_406` |
| An entity has no identity field ([3.4.1](#341-identity-fields)) | `PERSIST_501` |
| An identity field is not of type `int`, `string`, `float`, `boolean` or `decimal` ([3.4.1](#341-identity-fields)) | `PERSIST_503` |

## 4. Derived entity types and persist clients

### 4.1. Description

The persist tool generates the derived entity types and the persist client from the model definition file, as specified in [client generation](https://github.com/ballerina-platform/persist-tools/blob/main/docs/spec/spec.md#5-client-generation) of the persist tools specification. The persist client uses the derived entity types.

### 4.2. Derived entity types

Six derived entity types are derived from each entity:

1. **Entity type:** the type defined in the data model, without its relation fields. It indicates the data structure in the datastore. The owner of a relation includes the foreign key field(s).
2. **Insert type:** the record used to insert data in the datastore. It is the same as the entity type.
3. **Update type:** the record used to update data in the datastore. It is the entity type without the identity fields, with all fields optional. Only the fields for which values are provided are updated.
4. **Optionalized type:** the entity type with all fields optional. It is not directly used in any operation.
5. **With relations type:** a record that includes all fields of the optionalized type, and adds the relation fields as optional fields of the optionalized types of the related entities. It is not directly used in any operation.
6. **Target type:** the type used to retrieve data from the datastore. If the entity contains a relation field, the target type is a type description of the with relations type. Otherwise, it is a type description of the optionalized type.

For example, for this entity:

```ballerina
type Workspace record {|
    readonly string workspaceId;
    string workspaceType;
    Building location; // 1-n relation (parent)
    Employee[] employees; // 1-n relation (child)
|};
```

the derived entity types are:

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
2. The client name is derived from the name of the file, as `<First Letter Capitalized File Name>Client`. For example, `rainier.bal` generates a client named `RainierClient`.
3. The client is of the `persist:AbstractPersistClient` type.
4. The client contains the `init` and `close` functions.
5. The client contains five resource methods for each entity in the data model: `get`, `get` by identity, `post`, `put` and `delete`.
6. Resource names are the lowercase pluralized entity names.
7. The resource methods return the derived entity types.
8. A resource method with path parameters supports a composite identity by having one path parameter for each identity field.
9. The resource methods behave as follows:

    | Resource method | Path | Input | Result |
    |---|---|---|---|
    | `get` | `<resource>` | The target type | A stream of records of the target type. |
    | `get` by identity | `<resource>/[<identity>]` | The target type | The record of the target type with the given identity. |
    | `post` | `<resource>` | An array of insert type records | The identity values of the inserted records. |
    | `put` | `<resource>/[<identity>]` | An update type record | The updated record of the entity type. |
    | `delete` | `<resource>/[<identity>]` | None | The record as it was read before the deletion. |

For example, the client derived from `rainier.bal` for the `Workspace` entity has this skeleton:

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

### 4.4. Errors

1. The `init` and `close` functions and the resource methods return a `persist:Error` on failure.
2. The `put` resource method returns a `persist:ReadBackError` when the update is saved but the updated record cannot be read back.

## 5. Security considerations

The `persist` library does not connect to a datastore. The generated persist client connects to the datastore with the database configuration that the persist tool generates, and the security considerations of that configuration are specified in the [persist tools specification](https://github.com/ballerina-platform/persist-tools/blob/main/docs/spec/spec.md#9-security-considerations).

## References

- [Ballerina persist tools specification](https://github.com/ballerina-platform/persist-tools/blob/main/docs/spec/spec.md)
- [RFC 2119: Key words for use in RFCs to Indicate Requirement Levels](https://www.rfc-editor.org/rfc/rfc2119)
- [RFC 8174: Ambiguity of Uppercase vs Lowercase in RFC 2119 Key Words](https://www.rfc-editor.org/rfc/rfc8174)
