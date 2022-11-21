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
import package_01.'client as needclient;
import package_01.entity;

public function main() returns error? {
    needclient:MedicalNeedClient mnClient = check new ();
    entity:MedicalNeed mn = check mnClient->create({
        needId: 1,
        itemId: (),
        beneficiaryId: 1,
        period: "2022-10-10 01:02:03",
        urgency: "URGENT",
        quantity: 1
    });
    io:println(`${mn}`);

    string orderbyColumn = "quantity";
    int quantityMinValue = 5;

    record {int needId; string period; int quantity;}[]? mns =
    check from entity:MedicalNeed medicalNeed in mnClient->read()
        where medicalNeed.quantity > 5
        limit 5
        order by medicalNeed.quantity descending
        select {
            needId: medicalNeed.needId,
            period: medicalNeed.period,
            quantity: medicalNeed.quantity
        };

    io:println(mns);

    if mns !is () {
        check from record {int needId; string period; int quantity;} medicalNeed in mns
            do {
                io:println(medicalNeed);
            };
    }

    record {int needId; string period; int quantity;}[]? mnsUnfiltered =
    check from entity:MedicalNeed medicalNeed in mnClient->read()
        select {
            needId: medicalNeed.needId,
            period: medicalNeed.period,
            quantity: medicalNeed.quantity
        };
    io:println(mnsUnfiltered);

    check mnClient.close();
}
