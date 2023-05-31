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
Simple Types are mapped to native data source types as follows:
1. **MySQL**

   | Ballerina Type |   MySQL Type   |
   |:--------------:| :------------: |
   | ()             |      NULL      |
   | boolean        |    BOOLEAN     |
   | int            |      INT       |
   | float          |     DOUBLE     |
   | decimal        | DECIMAL(65,30) |
   | string         |  VARCHAR(191)  |
   | byte[]         |    LONGBLOB    |
   | enum           |      ENUM      |
   | time:Date      |      DATE      |
   | time:TimeOfDay |      TIME      |
   | time:Utc       |   TIMESTAMP    |
   | time:Civil     |    DATETIME    |

2. **In-memory**

   In-memory uses Ballerina tables as the data store. Therefore, all types supported by Ballerina are supported with `persist` when in-memory is used as the data source.


3. **Google Sheets**

   | Ballerina Type | Google Sheets Column Data Type |
   |:------------------------------:| :------------: |
   | ()             |          Text (empty)          |
   | boolean        |              Text              |
   | int            |             Number             |
   | float          |             Number             |
   | decimal        |             Number             |
   | string         |              Text              |
   | enum           |              Text              |
   | time:Date      |              Text              |
   | time:TimeOfDay |              TIME              |
   | time:Utc       |              Text              |
   | time:Civil     |              Text              |

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

## Initialize the Ballerina Persistence Layer

The Ballerina project should be initialized with the persistence layer before generating the persist derived types, 
clients, and script files. This can be done using the `bal persist init` command. You can specify the preferred data store and the 
module for which you need to generate files. The default values will be used if you do not specify the data store and the 
module.

```bash
bal persist init --datastore="<datastore-name>" --module="<module-name>"
```

| Command Parameter | Description                                                                                                                | Default Value |  
|:-----------------:|:---------------------------------------------------------------------------------------------------------------------------|:-------------:|  
|     datastore     | Used to indicate the preferred data store. Currently, three data stores are supported: in-memory, MySQL, and google sheets |   inmemory    |  
|      module       | Used to indicate the module in which the files are generated.                                                              | <root_module> |  

This command will do the following,
1. Create persist directory in the project root directory. This directory contains the data model definition file (model.bal) of the project.
2. Create a model definition file in persist directory. This file is used to model the data which needs to be persisted in the project. You can have only one data model definition file in the project and the file name can be anything with the .bal extension. The default file name is model.bal. Entities defined in this file should be based on the [Data model Definitions](data-model-definitions).
3. Update the Ballerina.toml file with persist module configurations. It will update the Ballerina.toml file with persistent configurations.

The generated Ballerina.Toml file will be as follows when MySQL is used as the data store.
```toml
[persist]
datastore = "mysql"
module = "rainier.store"
```

The directory structure will be as follows.
```
rainier
├── persist
|      └── model.bal
├── Ballerina.toml
├── Config.toml
└── main.bal
```

Behaviour of the init command:
- The user should invoke the command within a Ballerina project
- The user can use the optional arguments to indicate the preferred module name and data store, otherwise default values will be used.
- The user cannot execute the command multiple times within the same project. User needs to remove the `Ballerina.toml` configurations, if the user wants to reinitialize the project.

## Generate persistence derived entity types and clients 

The `bal persist generate` command generates the derived types, clients, and script files based on the data model definition file. This command is executed in the project root directory, as follows.

```bash
bal persist generate
```

It will add generated files under the generated directory. The directory structure will be as follows
If the module name is provided, it will generate the files under a new sub-directory with the module name like below. Otherwise, it will generate the files under the generated directory.
```
rainier
├── generated
|     └── store
|           ├── persist_client.bal
|           ├── persist_db_config.bal
|           ├── persist_types.bal
|           └── script.sql (only when MySQL is useed as the datastore)
├── persist
|      └── model.bal
├── Ballerina.toml
├── Config.toml
└── main.bal
```

- The `persist_types.bal` file will contain the derived types based on the entities defined in the model definition file.
- The `persist_client.bal` file will contain the client used to access the data store.
- The `persist_*_config.bal` file will contain the configurable variables required for the data store access. The configurable variables are changed based on the data store specified in the Ballerina.toml file. For example, if the data store is MySQL, the configurable variables will be as follows.

```toml
configurable string host = ?;
configurable int port = ?;
configurable string user = ?;
configurable string password = ?;
configurable string database = ?;
```

- The script file (`script.sql`) will contain the scripts to create the tables in the data store. This script file will be generated based on the data store specified in the Ballerina.toml file.
Additionally, this command will create/update the `Config.toml` file with configurables used to connect the client with the data store. Generated configurables will be based on the data store specified in the `Ballerina.toml` file.

The behavior of the generate command,
- The user should invoke the command within a Ballerina project
- The user should have initiated the persistence layer in the project and updated the model definition file.
- The model definition file should contain the persist module import (`import ballerina/persist as _;`)
- The model definition file should contain at least one entity
- If the user invokes the command twice, it will not fail. It will regenerate the files.

## Using the generated persistence clients

For each entity in the model definition file, the generated client will contain five resource methods which can be used to perform CRUD operations.

Below is an example for the resource methods generated for an entity `Customer` with a single identity field `custId` of type `string`.
```ballerina
// Used to retrieve a stream of records of the entity type. 
isolated resource function get customers(CustomerTargetType targetType = <>) returns stream<targetType, persist:Error?>

// Used to retrieve a single record with the provided key.
isolated resource function get customers/[string custId](CustomerTargetType targetType = <>) returns targetType|persist:Error

// Used to persist a record in the data store
isolated resource function post customers(CustomerInsert[] data) returns string[]|persist:Error

// Used to update a record
isolated resource function put customers/[string custId](CustomerUpdate value) returns Customer|persist:Error

// Used to delete a record
isolated resource function delete customers/[string custId]() returns Customer|persist:Error
```

In order to use the generated client to manipulate records in the datastore, the user first needs to crete an instance of the client.
```ballerina
store:Client storeClient = check new ();
```

### Creating records and insert to data store
The `post` resource method can be used to insert records to the data store. 
It accepts an array of records to be inserted and returns an array of keys of the inserted records. 
The following example shows how to insert records to the data store.
```ballerina
string custIds = check storeClient->/customers.post([
   {custId: "C001", firstName: "John", lastName: "Smith"}, 
   {custId: "C002", firstName: "Mary", lastName: "Johnson"}, 
]);
io:println("Inserted records:", custIds);
```

The above example will insert two records to the data store and return the keys of the inserted records.
```
Inserted records: ["C001", "C002"]
```

### Retrieving a record from the data store
The `get by key` resource method can be used to retrieve a single record from the data store.
It accepts the key of the record to be retrieved and returns the record if it exists in the data store.
The following example shows how to retrieve a record from the data store.
```ballerina
Customer customer = check storeClient->/customers/["C001"].get();
io:println("Retrieved customer:", customer);
```

The above example will retrieve the record with the key `C001` from the data store.
```
Retrieved customer: {custId:"C001", firstName:"John", lastName:"Smith"}
```


### Retrieving a stream of records from the data store
The `get` resource method can be used to retrieve a stream of records from the data store.
It returns a stream of records of the target type.
```ballerina
stream<Customer, error?> customers = check storeClient->/customers.get();
check from Customer customer in customers {
    io:println("Retrieved customer:", customer);
}
```

The above example will retrieve all the records of the `Customer` entity from the data store.
```
Retrieved customer: {custId:"C001", firstName:"John", lastName:"Smith"}
Retrieved customer: {custId:"C002", firstName:"Mary", lastName:"Johnson"}
```

### Retrieving a selected subset of fields of an entity from the data store
If it is not required to fetch the entire record, but only a subset of the fields, 
the `get` and `get by key` resource methods can be used with a record type containing only the
required fields.
```ballerina
type CustomerName record {|
    string firstName;
    string lastName;
|};
CustomerName customer = check storeClient->/customers/["C001"].get();
io:println("Retrieved customer name:", customer);
```

The above example will retrieve the record with the key `C001` from the data store and return a record containing
only the `firstName` and `lastName` fields.
```
Retrieved customer name: {firstName:"John", lastName:"Smith"}
```

### Retrieving association fields of an entity from the data store
If it is required to fetch the associated entity fields of a record, the `get` and `get by key` resource methods can be used with a record type containing the associated entity fields.
```ballerina
type CustomerWithOrders record {|
    string custId;
    Order[] orders;
|};
CustomerWithOrders customer = check storeClient->/customers/["C001"].get();
io:println("Retrieved customer with orders:", customer);
```

The above example will retrieve the record with the key `C001` from the data store and return a record containing
the `custId` and `orders` fields. The `orders` field will contain an array of `Order` records.
```  
Retrieved customer with orders: {custId:"C001", orders:[{orderId:"O001", custId:"C001", orderDate:"2021-01-01"}, {orderId:"O002", custId:"C001", orderDate:"2021-01-02"}
```

### Updating a record in the data store
The `put` resource method can be used to update a record in the data store.
It accepts the key of the record to be updated and a record containing the updated fields,
and returns the updated record if it exists in the data store.
```ballerina
Customer updatedCustomer = check storeClient->/customers/["C001"].put(
   {firstName: "Johnson", lastName: "Doe"}
);
io:println("Updated customer:", updatedCustomer);
```

The above example will update the record with the key `C001` in the data store and return the updated record.
```
Updated customer: {custId:"C001", firstName:"Johnson", lastName:"Doe"}
```

> *Note:* Associated entity fields cannot be updated using the `put` resource method.

### Deleting a record from the data store
The `delete` resource method can be used to delete a record from the data store.
It accepts the key of the record to be deleted and returns the deleted record if it exists in the data store.
```ballerina
Customer deletedCustomer = check storeClient->/customers/["C001"].delete();
io:println("Deleted customer:", deletedCustomer);
```

The above example will delete the record with the key `C001` from the data store and return the deleted record.
```
Deleted customer: {custId:"C001", firstName:"Johnson", lastName:"Doe"}
```

## Generating migration scripts for the model definition changes (experimental)

> *Info:* The support for migrations is currently an experimental feature, and its behavior may be subject to change in 
> future releases. Also, the support for migrations is currently limited to MySQL data stores.

This command is used to generate the migration scripts for the model definition changes. This command is executed in the
project root directory. This command will generate the migration scripts based on the changes in the model definition 
file. The generated migration scripts will be added to the migrations directory inside the persist directory.

```bash
bal persist migrate add_employee
```

The file structure of the project after executing the command will be as follows,
```
rainier
├── generated
|     └── store
|           ├── persist_client.bal
|           ├── persist_db_config.bal
|           ├── persist_types.bal
|           └── script.sql (only when MySQL is useed as the datastore)
├── persist
|      └── model.bal
|      └── migrations
|           └── 20230523120000_add_employee
|           └── model.bal
|           └── script.bal
├── Ballerina.toml
├── Config.toml
└── main.bal
```

This command will generate a new directory for the migration with the timestamp and the label provided by the user. 
The directory will contain the model definition file and the script file. 
- The `script.sql` file will contain the SQL script to update the database schema. 
- The `model.bal` definition file will be the snapshot of the model definition file at the time of 
executing the command. 

The next time the user executes the command, it will compare the model definition file with the 
latest snapshot file and generate the SQL script to update the database schema. So the user should not modify the
snapshot file.

The behavior of the migrate command,
- The user should invoke the command within a Ballerina project
- The user should provide a valid label for the migration.
- The user should have initiated the persistence layer in the project and updated the model definition file.
- The user can execute the command multiple times. It will generate the migration scripts based on the changes in the model definition file.
- Once the migration is generated, the user can't change the data store type in the Ballerina.toml file. If the user wants to change the data store type, the user needs to remove the migration directory and reinitialize the project.
