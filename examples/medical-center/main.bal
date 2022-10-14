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

import ballerina/io;
import wso2/medical_center.clients;

public function main() returns error? {
    clients:MedicalItemClient miClient = check new ();
    MedicalItem item = {
        itemId: 1,
        name: "item name",
        'type: "type1",
        unit: "ml"
    };
    MedicalItem createdItem = check miClient->create(item);
    io:println("Created item id: ", createdItem.itemId);

    MedicalItem retrievedItem = check miClient->readByKey(1);
    io:println("Retrieved item: ", retrievedItem);

    MedicalItem|error itemError = miClient->readByKey(20);
    io:println("Retrieved non-existence item: ", itemError);

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
    MedicalItem[]? items = check from MedicalItem itemx in miClient->read()
        where itemx.'type == "type2" 
        select itemx;

    if items is MedicalItem[] {
        foreach MedicalItem itemx in items {
            itemx.unit = "kg";
            _ = check miClient->update(itemx);
        }
    }

    _ = check from MedicalItem itemx in miClient->read()
        do {
            io:println(itemx);
        };

    io:println("\n========== delete type2 ==========");
    MedicalItem[]? items1 = check from MedicalItem itemx in miClient->read()
        where itemx.'type == "type2" 
        select itemx;

    if items1 is MedicalItem[] {
        foreach MedicalItem itemx in items1 {
            _ = check miClient->delete(itemx);
        }
    }

    _ = check from MedicalItem itemx in miClient->read()
        do {
            io:println(itemx);
        };

    check miClient.close();

    io:println("\n========== create medical needs ==========");
    clients:MedicalNeedClient mnClient = check new ();
    MedicalNeed mnItem = check mnClient->create({
        itemId: 1,
        beneficiaryId: 1,
        period: {year: 2022, month: 10, day: 10, hour: 1, minute: 2, second: 3},
        urgency: "URGENT",
        quantity: 5
    });
    io:println("Created need id: ", mnItem.needId);
    MedicalNeed mnItem2 = check mnClient->create({
        itemId: 2,
        beneficiaryId: 2,
        period: {year: 2021, month: 10, day: 10, hour: 1, minute: 2, second: 3},
        urgency: "NOT URGENT",
        quantity: 5
    });
    io:println("Created need id: ", mnItem2.needId);
}
