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
import package_03.'client as needclient;
import package_03.entity;

public function main() returns error? {
    needclient:MedicalNeedClient mnClient = check new ();

    record {int needId; string period; int quantity;}[]? mns =
    check from entity:MedicalNeed medicalNeed in mnClient->read()
        order by medicalNeed.quantity
        select {
            needId: medicalNeed.needId,
            period: medicalNeed.period,
            quantity: medicalNeed.quantity
        };
    io:println(mns);

    record {int needId; string period; int quantity;}[]? mns1 =
    check from entity:MedicalNeed medicalNeed in mnClient->read()
        order by "medicalNeed.quantity"
        select {
            needId: medicalNeed.needId,
            period: medicalNeed.period,
            quantity: medicalNeed.quantity
        };
    io:println(mns1);

    record {int needId; string period; int quantity;}[]? mns2 =
    check from entity:MedicalNeed medicalNeed in mnClient->read()
        order by medicalNeed.quantity ascending
        select {
            needId: medicalNeed.needId,
            period: medicalNeed.period,
            quantity: medicalNeed.quantity
        };
    io:println(mns2);

    record {int needId; string period; int quantity;}[]? mns3 =
    check from entity:MedicalNeed medicalNeed in mnClient->read()
        order by medicalNeed.needId descending
        select {
            needId: medicalNeed.needId,
            period: medicalNeed.period,
            quantity: medicalNeed.quantity
        };
    io:println(mns3);

    record {int needId; string period; int quantity;}[]? mns4 =
    check from entity:MedicalNeed medicalNeed in mnClient->read()
        order by medicalNeed.quantity ascending, medicalNeed.needId descending
        select {
            needId: medicalNeed.needId,
            period: medicalNeed.period,
            quantity: medicalNeed.quantity
        };
    io:println(mns4);

    record {int needId; string period; int quantity;}[]? mns5 =
    check from var {needId, period, quantity} in mnClient->read()
        order by quantity, needId descending
        select {
            needId: needId,
            period: period,
            quantity: quantity
        };
    io:println(mns5);

    record {int needId; string period; int quantity;}[]? mns6 =
    check from entity:MedicalNeed medicalNeed in mnClient->read()
        order by quantity
        select {
            needId: needId,
            period: period,
            quantity: quantity
        };
    io:println(mns6);

    check mnClient.close();
}
