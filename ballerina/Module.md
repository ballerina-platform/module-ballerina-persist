# Module Overview

This module provides Ballerina `persist` features, which provides functionality to store and query data conveniently through a data model.

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
