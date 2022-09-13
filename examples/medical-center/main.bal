// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerinax/mysql;
import ballerina/io;

configurable string USER = ?;
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable string DATABASE = ?;
configurable int PORT = ?;

public function main() returns error? {
    check initDB();
    check runExample();
}

function initDB() returns error? {
    mysql:Client dbClient = check new (host = HOST, user = USER, password = PASSWORD, database = DATABASE, port = PORT);
    _ = check dbClient->execute(`DROP TABLE IF EXISTS MedicalItems`);
    _ = check dbClient->execute(`
        CREATE Table MedicalItems (
            itemId INTEGER PRIMARY KEY,
            name VARCHAR(50),
            type VARCHAR(20),
            unit VARCHAR(5)
        );`
    );

    _ = check dbClient->execute(`DROP TABLE IF EXISTS MedicalNeeds`);
    _ = check dbClient->execute(`
        CREATE Table test.MedicalNeeds (
            needId INTEGER PRIMARY KEY AUTO_INCREMENT,
            itemId INTEGER,
            beneficiaryId INTEGER,
            period TIMESTAMP,
            urgency VARCHAR(10),
            quantity INTEGER
        );`
    );

    check dbClient.close();
}

function runExample() returns error? {
    MedicalItemClient miClient = check new ();
    MedicalItem item = {
        itemId: 1,
        name: "item name",
        'type: "type1",
        unit: "ml"
    };
    int? id = check miClient->create(item);
    io:println("Item ID: ", id);

    MedicalItem retrievedItem = check miClient->readByKey(1);
    io:println(retrievedItem);

    MedicalItem|error itemError = miClient->readByKey(20);
    io:println(itemError);

    _ = check miClient->create({
        itemId: 2,
        name: "item2 name",
        'type: "type1",
        unit: "ml"
    });
    _ = check miClient->create({
        itemId: 3,
        name: "item2 name",
        'type: "type2",
        unit: "ml"
    });
    _ = check miClient->create({
        itemId: 4,
        name: "item2 name",
        'type: "type2",
        unit: "kg"
    });

    io:println("\n========== type1 ==========");
    _ = check from MedicalItem itemx in miClient->read()
        where itemx.'type == "type1"
        do {
            io:println(itemx);
        };

    io:println("\n========== type2 ==========");
    _ = check from MedicalItem itemx in miClient->read()
        where itemx.'type == "type2"
        order by itemx.itemId
        limit 2
        do {
            io:println(itemx);
        };

    io:println("\n========== update type2's unit to kg ==========");
    check miClient->update({"unit": "kg"}, {'type: "type2"});
    _ = check from MedicalItem itemx in miClient->read()
        do {
            io:println(itemx);
        };

    io:println("\n========== delete type2 ==========");
    check miClient->delete({'type: "type2"});
    _ = check from MedicalItem itemx in miClient->read()
        do {
            io:println(itemx);
        };

    check miClient.close();

    io:println("\n========== create medical needs ==========");
    MedicalNeedClient mnClient = check new ();
    id = check mnClient->create({
        itemId: 1,
        beneficiaryId: 1,
        period: {year: 2022, month: 10, day: 10, hour: 1, minute: 2, second: 3},
        urgency: "URGENT",
        quantity: 5
    });
    io:println("Need ID: ", id);
    id = check mnClient->create({
        itemId: 2,
        beneficiaryId: 2,
        period: {year: 2021, month: 10, day: 10, hour: 1, minute: 2, second: 3},
        urgency: "NOT URGENT",
        quantity: 5
    });
    io:println("Need ID: ", id);

}
