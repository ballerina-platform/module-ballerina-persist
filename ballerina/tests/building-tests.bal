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

Building building1 = {
    buildingCode: "building-1",
    city: "Colombo",
    state: "Western Province",
    country: "Sri Lanka",
    postalCode: "10370"
};

Building invalidBuilding = {
    buildingCode: "building-invalid-extra-characters-to-force-failure",
    city: "Colombo",
    state: "Western Province",
    country: "Sri Lanka",
    postalCode: "10370"
};

BuildingInsert building2 = {
    buildingCode: "building-2",
    city: "Manhattan",
    state: "New York",
    country: "USA",
    postalCode: "10570"
};

BuildingInsert building3 = {
    buildingCode: "building-3",
    city: "London",
    state: "London",
    country: "United Kingdom",
    postalCode: "39202"
};


Building updatedBuilding1 = {
    buildingCode: "building-1",
    city: "Galle",
    state: "Southern Province",
    country: "Sri Lanka",
    postalCode: "10890"
};

@test:Config {
    groups: ["basic"]
}
function basicCreateTest() returns error? {
    RainierClient rainierClient = check new ();
    
    string[] buildingCodes = check rainierClient->/buildings.post([building1]);    
    test:assertEquals(buildingCodes, [building1.buildingCode]);

    Building buildingRetrieved = check rainierClient->/buildings/[building1.buildingCode].get();
    test:assertEquals(buildingRetrieved, building1);
}

@test:Config {
    groups: ["basic"]
}
function basicCreateTest2() returns error? {
    RainierClient rainierClient = check new ();
    
    string[] buildingCodes = check rainierClient->/buildings.post([building2, building3]);

    test:assertEquals(buildingCodes, [building2.buildingCode, building3.buildingCode]);

    Building buildingRetrieved = check rainierClient->/buildings/[building2.buildingCode].get();
    test:assertEquals(buildingRetrieved, building2);

    buildingRetrieved = check rainierClient->/buildings/[building3.buildingCode].get();
    test:assertEquals(buildingRetrieved, building3);
}

@test:Config {
    groups: ["basic"]
}
function basicCreateTestNegative() returns error? {
    RainierClient rainierClient = check new ();
    
    string[]|error building = rainierClient->/buildings.post([invalidBuilding]);   
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
    dependsOn: [basicCreateTest, basicCreateTest2]
}
function basicReadManyTest() returns error? {
    RainierClient rainierClient = check new ();

    stream<Building, error?> buildingStream = rainierClient->/buildings.get();
    Building[] buildings = check from Building building in buildingStream 
        select building;

    test:assertEquals(buildings, [building1, building2, building3]);
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
        select building2;

    test:assertEquals(buildings, [building2, building3]);
}

@test:Config {
    groups: ["basic"],
    dependsOn: [basicDeleteTest]
}
function basicDeleteTestNegative() returns error? {
    RainierClient rainierClient = check new ();

    Building|error building = rainierClient->/buildings/[building1.buildingCode].delete();

    if building is error {
        test:assertEquals(building.message(), string `A record does not exist for 'Building' for key "${building1.buildingCode}".`);
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
}