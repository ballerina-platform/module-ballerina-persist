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
import package_10.'client as needclient;
import package_10.entity;

public function main() returns error? {
    needclient:MedicalNeedClient mnClient = check new ();

    stream<entity:MedicalNeed, persist:Error?> mn1 = mnClient->read();

    record {int needId; string period; int quantity;}[]? mns1 =
    check from entity:MedicalNeed medicalNeed in mn1
        order by medicalNeed.quantity
        select {
            needId: medicalNeed.needId,
            period: medicalNeed.period,
            quantity: medicalNeed.quantity
        };
    io:println(mns1);

    stream<entity:MedicalNeed, persist:Error?> mn2 = mnClient->read();
    stream<entity:MedicalNeed, persist:Error?> mn3 = mnClient->read();

    record {int needId; string period; int quantity;}[]? mns4 =
    check from entity:MedicalNeed medicalNeed in mnClient->read()
        order by medicalNeed.quantity
        select {
            needId: medicalNeed.needId,
            period: medicalNeed.period,
            quantity: medicalNeed.quantity
        };
    io:println(mns4);

    stream<entity:MedicalNeed, persist:Error?> mn5 = mnClient->read();

    check mnClient.close();
}
