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

import ballerina/test;
import ballerina/io;

Building building1 = {
    buildingCode: "40083df0-5a27-48a9-8e0d-6e70e0d6acbf",
    city: "Colombo",
    state: "Western Province",
    country: "Sri Lanka",
    postalCode: "10370"
};

Building invalidBuilding = {
    buildingCode: "40083df0-5a27-48a9-8e0d-6e70e0d6acbf-extra-characters-to-force-failure",
    city: "Colombo",
    state: "Western Province",
    country: "Sri Lanka",
    postalCode: "10370"
};

BuildingInsert building2 = {
    buildingCode: "40083df0-5a27-48a9-8e0d-6e70e0d6acbg",
    city: "Manhattan",
    state: "New York",
    country: "USA",
    postalCode: "10570"
};

Building updatedBuilding1 = {
    buildingCode: "40083df0-5a27-48a9-8e0d-6e70e0d6acbf",
    city: "Galle",
    state: "Southern Province",
    country: "Sri Lanka",
    postalCode: "10890"
};

@test:Config {
    groups: ["basic"]
}
function basicCreateTest() returns error? {
    io:println("init");
    RainierClient rainierClient = check new ();
    
    Building building = check rainierClient->/buildings.post(building1);    
    test:assertEquals(building, building1);

    Building buildingRetrieved = check rainierClient->/buildings/[building1.buildingCode].get();
    test:assertEquals(buildingRetrieved, building1);
}

@test:Config {
    groups: ["basic"]
}
function basicCreateTestNegative() returns error? {
    RainierClient rainierClient = check new ();
    
    Building|error building = rainierClient->/buildings.post(invalidBuilding);   
    if building is Error {
        test:assertTrue(building.message().includes("Data truncation: Data too long for column 'buildingCode' at row 1."));
    } else {
        test:assertFail("Error expected.");
    }
}

@test:Config {
    groups: ["basic"],
    dependsOn: [basicCreateTest]
}
function basicReadOneTest() returns error? {
    RainierClient rainierClient = check new ();

    Building buildingRetrieved = check rainierClient->/buildings/[building1.buildingCode].get();
    test:assertEquals(buildingRetrieved, building1);
}

@test:Config {
    groups: ["basic"],
    dependsOn: [basicCreateTest]
}
function basicReadOneTestNegative() returns error? {
    RainierClient rainierClient = check new ();

    Building|error buildingRetrieved = rainierClient->/buildings/["invalid-building-code"].get();
    if buildingRetrieved is InvalidKeyError {
        test:assertEquals(buildingRetrieved.message(), "A record does not exist for 'Building' for key \"invalid-building-code\".");
    } else {
        test:assertFail("InvalidKeyError expected.");
    }}

@test:Config {
    groups: ["basic"],
    dependsOn: [basicCreateTest]
}
function basicReadManyTest() returns error? {
    RainierClient rainierClient = check new ();

    _ = check rainierClient->/buildings.post(building2);

    stream<Building, error?> buildingStream = rainierClient->/buildings.get();
    Building[] buildings = check from Building building in buildingStream 
        order by building.buildingCode
        select building;

    test:assertEquals(buildings, [building1, building2]);
}

@test:Config {
    groups: ["basic"],
    dependsOn: [basicReadOneTest, basicReadManyTest]
}
function basicUpdateTest() returns error? {
    RainierClient rainierClient = check new ();

    Building building = check rainierClient->/buildings/[building1.buildingCode].put({
        city: "Galle",
        state: "Southern Province",
        postalCode: "10890"
    });

    test:assertEquals(building, updatedBuilding1);

    Building buildingRetrieved = check rainierClient->/buildings/[building1.buildingCode].get();
    test:assertEquals(buildingRetrieved, updatedBuilding1);
}

@test:Config {
    groups: ["basic"],
    dependsOn: [basicReadOneTest, basicReadManyTest]
}
function basicUpdateTestNegative1() returns error? {
    RainierClient rainierClient = check new ();

    Building|error building = rainierClient->/buildings/["invalid-building-code"].put({
        city: "Galle",
        state: "Southern Province",
        postalCode: "10890"
    });

    if building is InvalidKeyError {
        test:assertEquals(building.message(), "A record does not exist for 'Building' for key \"invalid-building-code\".");
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
}

@test:Config {
    groups: ["basic"],
    dependsOn: [basicReadOneTest, basicReadManyTest]
}
function basicUpdateTestNegative2() returns error? {
    RainierClient rainierClient = check new ();

    Building|error building = rainierClient->/buildings/[building1.buildingCode].put({
        city: "unncessarily-long-city-name-to-force-error-on-update",
        state: "Southern Province",
        postalCode: "10890"
    });

    if building is Error {
        test:assertTrue(building.message().includes("Data truncation: Data too long for column 'city' at row 1."));
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
}

@test:Config {
    groups: ["basic"],
    dependsOn: [basicUpdateTest, basicUpdateTestNegative2]
}
function basicDeleteTest() returns error? {
    RainierClient rainierClient = check new ();

    Building building = check rainierClient->/buildings/[building1.buildingCode].delete();
    test:assertEquals(building, updatedBuilding1);

    stream<Building, error?> buildingStream = rainierClient->/buildings.get();
    Building[] buildings = check from Building building2 in buildingStream 
        order by building2.buildingCode
        select building2;

    test:assertEquals(buildings, [building2]);
}

@test:Config {
    groups: ["basic"],
    dependsOn: [basicDeleteTest]
}
function basicDeleteTestNegative() returns error? {
    RainierClient rainierClient = check new ();

    Building|error building = rainierClient->/buildings/[building1.buildingCode].delete();

    if building is InvalidKeyError {
        test:assertEquals(building.message(), string `A record does not exist for 'Building' for key "${building1.buildingCode}".`);
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
}