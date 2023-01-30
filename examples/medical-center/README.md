# Medical Center

## Overview

Medical Center is the basic example to demonstrate the capabilities of the Ballerina Persist module. 
It has two entities called `MedicalItem` and `MedicalNeed`. They are both basic entities without associations.

## Run the example

*Info* As a prerequisite to running the example, start a MySQL database server.

First, clone this repository, and then run the following commands to run this example in your local machine.

1. Run `bal persist init` command to add configurations.

    ```sh
    $ cd examples/medical-center
    $ bal persist init
    ```
    This will create/update the following files the necessary db configurations
    * `Config.toml`
    * `Ballerina.toml`
    * `generated/database_configuration.bal`


2. Update the `Ballerina.toml` and `Config.toml` files with the correct DB configurations.


3. Run `bal persist generate` command to generate clients.

   ```sh
   cd examples/medical-center
   $ bal persist generate
   ```

   This will generate two new files within the `generated directory`.
   * `generated_client.bal` - contains the client to be used when conducting CRUD operations with `MedicalNeed` and `MedicalItem`.
   * `generated_types.bal` - contains the types to be used when performing CRUD operations with `MedicalNeed` and `MedicalItem`.

4. Run `bal persist push` command to generate and execute the SQL script file (`medical_center_db_script.sql`) in the `persist` directory.

   ```sh
   cd examples/medical-center
   $ bal persist push
   ```
   This will generate necessary database and tables in the MySQL server.

5. Run the example.

   ```sh
   cd examples/medical-center
   $ bal run
   
   Running executable
   
   Created item id: 1
   Retrieved item: {"itemId":1,"name":"item name","type":"type1","unit":"ml"}
   Retrieved non-existence item: error InvalidKeyError ("A record does not exist for 'MedicalItem' for key 5.")
   
   ========== type1 ==========
   {"itemId":1,"name":"item name","type":"type1","unit":"ml"}
   {"itemId":2,"name":"item2 name","type":"type1","unit":"ml"}
   
   ========== type2 ==========
   {"itemId":3,"name":"item2 name","type":"type2","unit":"ml"}
   {"itemId":4,"name":"item2 name","type":"type2","unit":"kg"}
   
   ========== update type2's unit to kg ==========
   {"itemId":1,"name":"item name","type":"type1","unit":"ml"}
   {"itemId":2,"name":"item2 name","type":"type1","unit":"ml"}
   {"itemId":3,"name":"item2 name","type":"type2","unit":"kg"}
   {"itemId":4,"name":"item2 name","type":"type2","unit":"kg"}
   
   ========== delete type2 ==========
   {"itemId":1,"name":"item name","type":"type1","unit":"ml"}
   {"itemId":2,"name":"item2 name","type":"type1","unit":"ml"}
   
   ========== create medical needs ==========
   Created need id: 1
   Created need id: 2
   ```
