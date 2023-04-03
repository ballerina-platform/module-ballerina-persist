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
import ballerina/test;

Building building31 = {
    buildingCode: "building-31",
    city: "Colombo",
    state: "Western Province",
    country: "Sri Lanka",
    postalCode: "10370",
    'type: "rented"
};

Building building31Updated = {
    buildingCode: "building-31",
    city: "ColomboUpdated",
    state: "Western ProvinceUpdated",
    country: "Sri LankaUpdated",
    postalCode: "10370",
    'type: "rented"
};

BuildingInsert building32 = {
    buildingCode: "building-32",
    city: "Manhattan",
    state: "New York",
    country: "USA",
    postalCode: "10570",
    'type: "owned"
};

BuildingInsert building33 = {
    buildingCode: "building-33",
    city: "Manhattan",
    state: "New York",
    country: "USA",
    postalCode: "10570",
    'type: "owned"
};

@test:Config {
    groups: ["transactions"]
}
function transactionTest() returns error? {
    RainierClient rainierClient = check new ();
    
    _ = check rainierClient->/buildings.post([building33]);

    transaction {
        string[] buildingCodes = check rainierClient->/buildings.post([building31, building32]);
        test:assertEquals(buildingCodes, [building31.buildingCode, building32.buildingCode]);

        buildingCodes = check rainierClient->/buildings.post([building31]);
        check commit;   
    } on fail error e {
        test:assertTrue(e is DuplicateKeyError, "DuplicateKeyError expected");
    }

    Building|Error buildingRetrieved = rainierClient->/buildings/[building31.buildingCode].get();
    test:assertTrue(buildingRetrieved is InvalidKeyError, "InvalidKeyError expected");

    buildingRetrieved = rainierClient->/buildings/[building32.buildingCode].get();
    test:assertTrue(buildingRetrieved is InvalidKeyError, "InvalidKeyError expected");

    check rainierClient.close();
}

@test:Config {
    groups: ["transactionsx"]
}
function transactionTest2() returns error? {
    RainierClient rainierClient = check new ();
    
    _ = check rainierClient->/buildings.post([building31]);
    Building buildingRetrieved = check rainierClient->/buildings/[building31.buildingCode].get();
    io:println("============= TEST 00 ==============");
    io:println(buildingRetrieved);
    test:assertEquals(buildingRetrieved, building31);

    transaction {
        Building building = check rainierClient->/buildings/[building31.buildingCode].put({
            city: "ColomboUpdated",
            state: "Western ProvinceUpdated",
            country: "Sri LankaUpdated"
        });

        io:println("============= TEST 01 ==============");
        io:println(building);
        // test:assertEquals(building, building31Updated);

        // below should retrieve the updated building record
        buildingRetrieved = check rainierClient->/buildings/[building31.buildingCode].get();
        io:println("============= TEST 02 ==============");
        io:println(buildingRetrieved);
        // test:assertEquals(buildingRetrieved, building31Updated);

        check commit;   
    } on fail error e {
        io:println(e);
        test:assertTrue(e is DuplicateKeyError, "DuplicateKeyError expected");
    }

    buildingRetrieved = check rainierClient->/buildings/[building31.buildingCode].get();
    io:println("============= TEST 03 ==============");
    io:println(buildingRetrieved);

    check rainierClient.close();
}