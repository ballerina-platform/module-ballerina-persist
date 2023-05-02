# Module Overview

This module consists of Ballerina `persist` Tooling, which provides functionality to store and query data conveniently through a data model instead of SQL query language.

The `persist` tools provides following functionalities,
1. Define and validate the entity data model definitions in the `persist` folder
2. Initialize the Ballerina Persistence Layer for every model definitions in the `persist` folder
3. Generate persistence derived entity types and clients 
4. Push persistence schema to the data store

## Data Model Definitions

Within a Ballerina project, the data model should be defined in a separate bal file under the `persist` directory. This file is not considered part of the Ballerina project and is used only for data model definition.

The Ballerina `persist` library defines a mechanism to express the application's data model using Ballerina record type. Any record type that is a subtype of the `EntityType` will be an entity in the model.

### Entity Type Definition

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
   | float | DOUBLE |
   | decimal | DECIMAL(65,30) |
   | string | VARCHAR(191) |
   | byte[] | LONGBLOB |
   | time:Date | DATE |
   | time:TimeOfDay | TIME |
   | time:Utc | TIMESTAMP |
   | time:Civil | DATETIME |

### Entity Attributes Definition

Ballerina record fields are used to model the attributes of an entity. The type of the field should be a subtype of SimpleType.

#### Identity Field(s)

The entity must contain at least one identity field. The field's value is used to identify each record uniquely. The identity field(s) is indicated `readonly` flag.

Say type T is one of 'int', 'string', 'float', 'boolean' or 'decimal' types,

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
| Field definition | Semantics | Examples |  
| :---: | :---: | :---: |  
| T field | Mapped to a non-nullable column in the DB | int id; |  
| T? field | Mapped to a nullable column in the DB | string? description; |  
| T field? | Not allowed | - |  
| T? field? | Not allowed | - |

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
The entity that contains the field of type `EntityType` is taken as the owner in the 1-n relationship and will include the foreign key.

The default foreign key field name will be `ownerId` in the `Car` table, which refers to the identity field of the `User` table by default. (`<lowercasedRelatedFieldName><First-LetterCapitalizedIdentityFieldName>`)

## Initialize the Ballerina Persistence Layer

```bash
bal persist init
```

The `init` command initializes the bal project for every data definition file in the `persist` directory. It will create a data definition file if the `persist` directory is empty.

## Generate persistence derived entity types and clients 

```bash
bal persist generate
```

The `generate` command will generate the persistence clients and derived types from the entity definition files. The command will add the generated files in the `default` module for files with the same name as the package.

## Push persistence schema to the data store

```bash
bal persist push
```

The `push` command will create the database schema associated with the data model definition. Additionally, this will run the schema against the database defined in  the `Ballerina.toml` file under the heading ([persist.<definition file name>.storage.mysql])
