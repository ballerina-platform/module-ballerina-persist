Ballerina Persist Library
===================

  [![Build](https://github.com/ballerina-platform/module-ballerina-persist/actions/workflows/build-timestamped-master.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerina-persist/actions/workflows/build-timestamped-master.yml)
  [![codecov](https://codecov.io/gh/ballerina-platform/module-ballerina-persist/branch/main/graph/badge.svg)](https://codecov.io/gh/ballerina-platform/module-ballerina-persist)
  [![Trivy](https://github.com/ballerina-platform/module-ballerina-persist/actions/workflows/trivy-scan.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerina-persist/actions/workflows/trivy-scan.yml)
  [![GraalVM Check](https://github.com/ballerina-platform/module-ballerina-persist/actions/workflows/build-with-bal-test-graalvm.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerina-persist/actions/workflows/build-with-bal-test-graalvm.yml)
  [![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerina-persist.svg)](https://github.com/ballerina-platform/module-ballerina-persist/commits/main)
  [![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-standard-library/module/persist.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-standard-library/labels/module%2Fpersist)

This library provides Ballerina `persist` features, which provides functionality to store and query data conveniently through a data model.

The `persist` tools provides following functionalities,
1. Define and validate the entity data model definitions in the `persist` folder
2. Initialize the Ballerina Persistence Layer for every model definitions in the `persist` folder
3. Generate persistence derived entity types and clients
4. Push persistence schema to the data store (only with supported data sources)
5. Migration support for supported data stores (experimental feature)

## Data Model Definitions

Within a Ballerina project, the data model should be defined in a separate bal file under the `persist` directory. This file is not considered part of the Ballerina project and is used only for data model definition.

The Ballerina `persist` library defines a mechanism to express the application's data model using Ballerina record types. All record types will be an entity in the model.

### Entity Type Definition

An EntityType is defined using `SimpleType` and `EntityType` fields.

```ballerina
   // These are the type definitions for the data model when using MySQL
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
### Entity Attributes Definition

Ballerina record fields are used to model the attributes of an entity. The type of the field should be a subtype of SimpleType.

#### Identity Field(s)

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

#### Nullable Field(s)

Say type T is a subtype of SimpleType, and T does not contain (),

| Field definition  |                           Semantics                           |       Examples       |  
|:-----------------:|:-------------------------------------------------------------:|:--------------------:|  
|      T field      | Mapped to a non-nullable type in the datastore (if supported) |       int id;        |  
|     T? field      |   Mapped to a nullable type in the datastore (if supported)   | string? description; |  
|     T field?      |                          Not allowed                          |          -           |  
|     T? field?     |                          Not allowed                          |          -           |

### Relationship Definition

Ballerina record fields are used to model a connection between two entities. The type of the field should be a subtype of EntityType|EntityType?|EntityType[].

This design supports the following cardinalities:
1. One-to-one (1-1)
2. One-to-many (1-n)

The relation field is mandatory in both entities.

#### One-to-one (1-1)

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

#### One-to-Many (1-n)

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

## Issues and projects 

Issues and Projects tabs are disabled for this repository as this is part of the Ballerina standard library. To report bugs, request new features, start new discussions, view project boards, etc. please visit Ballerina standard library [parent repository](https://github.com/ballerina-platform/ballerina-standard-library). 

This repository only contains the source code for the package.

## Building from the source

### Set up the prerequisites

1. Download and install Java SE Development Kit (JDK) version 17 (from one of the following locations).
   * [Oracle](https://www.oracle.com/java/technologies/javase-jdk17-downloads.html)
   * [OpenJDK](https://adoptium.net/)
 
2. Export your GitHub personal access token with the read package permissions as follows.
        
        export packageUser=<Username>
        export packagePAT=<Personal access token>

### Building the source

Execute the commands below to build from source.

1. To build the library:
        
        ./gradlew clean build

2. Publish ZIP artifact to the local `.m2` repository:
   
        ./gradlew clean build publishToMavenLocal
   
3. Publish the generated artifacts to the local Ballerina central repository:
   
        ./gradlew clean build -PpublishToLocalCentral=true

4. Publish the generated artifacts to the Ballerina central repository:
   
        ./gradlew clean build -PpublishToCentral=true

## Contributing to Ballerina

As an open source project, Ballerina welcomes contributions from the community. 

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All contributors are encouraged to read the [Ballerina code of conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [`persist` library](https://lib.ballerina.io/ballerina/persist/latest).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
