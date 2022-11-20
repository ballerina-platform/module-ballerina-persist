// Copyright (c) 2022 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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
import ballerina/persist;
import package_11.'client as needclient;
import package_11.entity;

needclient:MedicalNeedClient mnClient1 = check new ();

error|needclient:MedicalNeedClient mnClient2 = new ();
needclient:MedicalNeedClient mnClient2New = check mnClient2;

needclient:MedicalNeedClient|persist:Error mnClient3 = new ();

TestClient testClient = new ();

public function main() returns error? {
    needclient:MedicalNeedClient mnClient4 = check new ();

    record {int needId; string period; int quantity;}[]? mns1 =
        check from entity:MedicalNeed medicalNeed in mnClient1->read()
        order by medicalNeed.quantity
        select {
            needId: medicalNeed.needId,
            period: medicalNeed.period,
            quantity: medicalNeed.quantity
        };
    io:println(mns1);

    record {int needId; string period; int quantity;}[]? mns2 =
        check from entity:MedicalNeed medicalNeed in mnClient2New->read()
        order by medicalNeed.quantity
        select {
            needId: medicalNeed.needId,
            period: medicalNeed.period,
            quantity: medicalNeed.quantity
        };
    io:println(mns2);

    record {int needId; string period; int quantity;}[]? mns3 =
        check from entity:MedicalNeed medicalNeed in mnClient4->read()
        order by medicalNeed.quantity
        select {
            needId: medicalNeed.needId,
            period: medicalNeed.period,
            quantity: medicalNeed.quantity
        };
    io:println(mns3);

    Data[]? mns4 = check from Data data in testClient->read()
        order by data.name
        select data;
    io:println(mns4);

}
