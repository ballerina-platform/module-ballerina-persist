# Medical Center

## Overview

Medical Center is the basic example to demonstrate the capabilities of Ballerina Persist module. It has two entities called `MedicalItem` and `MedicalNeed`. The both are basic entities without associations and the `MedicalNeed` has a auto-generated primary key.

## Run the example

*Info* As a prerequisite to running the example, start mysql database server.

First, clone this repository, and then run the following commands to run this example in your local machine.

1. Run `bal persist init` command to add configurations.

```sh
$ cd examples/medical-center
$ bal persist init
```
This will create/update the `Config.toml` file with necessary db configurations and driver dependency to `Ballerina.toml` file.

2. Update the `Config.toml` file with the correct DB configurations.

3. Run `bal persist generate` command to generate clients.

```sh
cd examples/medical-center
$ bal persist generate
```
This will add a module in `modules/clients` and genrate client files for each entity inside the module.

4. Run `bal persist db push` command to execute SQL script file(`persist_db_scripts.sql`) generated in target directory.

```sh
cd examples/medical-center
$ bal persist db push
```
This will generate necessary database and tables in the mysql server.

5. Run the example.

```sh
cd examples/medical-center
$ bal run

Running executable

Created item id: 1
Retrieved item: {"itemId":1,"name":"item name","type":"type1","unit":"ml"}
Retrieved non-existence item: error InvalidKeyError ("A record does not exist for 'MedicalItem' for key 20.")

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
