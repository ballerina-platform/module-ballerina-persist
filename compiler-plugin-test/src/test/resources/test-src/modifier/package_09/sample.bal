// Copyright (c) 2022 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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
import package_09.'client as needclient;
import package_09.entity;

public function main() returns error? {
    needclient:MedicalNeedClient mnClient = check new ();

    record {int needId; string period; int quantity;}[]? mns1 =
    check from entity:MedicalNeed medicalNeed in mnClient->read()
        order by "medicalNeed.quantity"
        select {
            needId: medicalNeed.needId,
            period: medicalNeed.period,
            quantity: medicalNeed.quantity
        };
    io:println(mns1);

    string orderByKey = "medicalNeed.quantity";
    record {int needId; string period; int quantity;}[]? mns2 =
    check from entity:MedicalNeed medicalNeed in mnClient->read()
        order by orderByKey
        select {
            needId: medicalNeed.needId,
            period: medicalNeed.period,
            quantity: medicalNeed.quantity
        };
    io:println(mns2);

    check mnClient.close();
}
