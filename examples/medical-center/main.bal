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

public function main() returns error? {
    Client mcClient = check new ();
    MedicalItem item = {
        itemId: 1,
        name: "item name",
        'type: "type1",
        unit: "ml"
    };
    int[] itemIds = check mcClient->/medicalitems.post([item]);
    io:println("Created item id: ", itemIds[0]);

    MedicalItem retrievedItem = check mcClient->/medicalitems/[itemIds[0]].get();
    io:println("Retrieved item: ", retrievedItem);

    MedicalItem|error itemError = mcClient->/medicalitems/[5].get();
    io:println("Retrieved non-existence item: ", itemError);

    MedicalItem item2 = {
        itemId: 2,
        name: "item2 name",
        'type: "type1",
        unit: "ml"
    };
    MedicalItem item3 = {
        itemId: 3,
        name: "item2 name",
        'type: "type2",
        unit: "ml"
    };
     MedicalItem item4 = {
        itemId: 4,
        name: "item2 name",
        'type: "type2",
        unit: "kg"
    };
    _ = check mcClient->/medicalitems.post([item2, item3, item4]);

    io:println("\n========== type1 ==========");
    _ = check from MedicalItem mItem in mcClient->/medicalitems.get(MedicalItem)
        where mItem.'type == "type1"
        do {
            io:println(mItem);
        };

    io:println("\n========== type2 ==========");
    _ = check from MedicalItem mItem in mcClient->/medicalitems.get(MedicalItem)
        where mItem.'type == "type2"
        order by mItem.itemId
        limit 2
        do {
            io:println(mItem);
        };

    io:println("\n========== update type2's unit to kg ==========");
    _ = check from MedicalItem mItem in mcClient->/medicalitems.get(MedicalItem)
        where mItem.'type == "type2"
        do {
            MedicalItemUpdate mItemUpdate = {unit: "kg"};
            //_ = check mcClient->/medicalitems/[mItem.itemId].put(mItemUpdate);
        };

    _ = check from MedicalItem mItem in mcClient->/medicalitems.get(MedicalItem)
        do {
            io:println(mItem);
        };

    io:println("\n========== delete type2 ==========");
    _ = check from MedicalItem mItem in mcClient->/medicalitems.get(MedicalItem)
        where mItem.'type == "type2"
        do {
            //_ = check mcClient->/medicalitems/[mItem.itemId].delete();
        };

    _ = check from MedicalItem mItem in mcClient->/medicalitems.get(MedicalItem)
        do {
            io:println(mItem);
        };

    io:println("\n========== create medical needs ==========");
    MedicalNeed mnItem = {
        needId: 1,
        beneficiaryId: 1,
        period: {year: 2022, month: 10, day: 10, hour: 1, minute: 2, second: 3},
        urgency: "URGENT",
        quantity: 5
    };
    int[] needIds = check mcClient->/medicalneeds.post([mnItem]);
    io:println("Created need id: ", needIds[0]);

    MedicalNeed mnItem2 = {
        needId: 2,
        beneficiaryId: 2,
        period: {year: 2021, month: 10, day: 10, hour: 1, minute: 2, second: 3},
        urgency: "NOT URGENT",
        quantity: 5
    };
    needIds = check mcClient->/medicalneeds.post([mnItem2]);
    io:println("Created need id: ", needIds[0]);

    check mcClient.close();
}
