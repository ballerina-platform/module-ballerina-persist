// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/test;

@test:Config {
    groups: ["building", "in-memory"]
}
function inMemoryBuildingCreateTest() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    string[] buildingCodes = check rainierClient->/buildings.post([building1]);
    test:assertEquals(buildingCodes, [building1.buildingCode]);

    Building buildingRetrieved = check rainierClient->/buildings/[building1.buildingCode].get();
    test:assertEquals(buildingRetrieved, building1);
    check rainierClient.close();
}

@test:Config {
    groups: ["building", "in-memory"]
}
function inMemoryBuildingCreateTest2() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    string[] buildingCodes = check rainierClient->/buildings.post([building2, building3]);

    test:assertEquals(buildingCodes, [building2.buildingCode, building3.buildingCode]);

    Building buildingRetrieved = check rainierClient->/buildings/[building2.buildingCode].get();
    test:assertEquals(buildingRetrieved, building2);

    buildingRetrieved = check rainierClient->/buildings/[building3.buildingCode].get();
    test:assertEquals(buildingRetrieved, building3);

    check rainierClient.close();
}

@test:Config {
    groups: ["building", "in-memory"],
    dependsOn: [inMemoryBuildingCreateTest]
}
function inMemoryBuildingReadOneTest() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    Building buildingRetrieved = check rainierClient->/buildings/[building1.buildingCode].get();
    test:assertEquals(buildingRetrieved, building1);
    check rainierClient.close();
}

@test:Config {
    groups: ["building", "in-memory"],
    dependsOn: [inMemoryBuildingCreateTest]
}
function inMemoryBuildingReadOneTestNegative() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    Building|error buildingRetrieved = rainierClient->/buildings/["invalid-building-code"].get();
    if buildingRetrieved is NotFoundError {
        test:assertEquals(buildingRetrieved.message(), "Invalid key: invalid-building-code");
    } else {
        test:assertFail("NotFoundError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["building", "in-memory"],
    dependsOn: [inMemoryBuildingCreateTest, inMemoryBuildingCreateTest2]
}
function inMemoryBuildingReadManyTest() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    stream<Building, error?> buildingStream = rainierClient->/buildings.get();
    Building[] buildings = check from Building building in buildingStream
        select building;

    test:assertEquals(buildings, [building1, building2, building3]);
    check rainierClient.close();
}

@test:Config {
    groups: ["building", "in-memory"],
    dependsOn: [inMemoryBuildingCreateTest, inMemoryBuildingCreateTest2]
}
function inMemoryBuildingReadManyDependentTest() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    stream<BuildingInfo2, error?> buildingStream = rainierClient->/buildings.get();
    BuildingInfo2[] buildings = check from BuildingInfo2 building in buildingStream
        select building;

    test:assertEquals(buildings, [
        {city: building1.city, state: building1.state, country: building1.country, postalCode: building1.postalCode, 'type: building1.'type},
        {city: building2.city, state: building2.state, country: building2.country, postalCode: building2.postalCode, 'type: building2.'type},
        {city: building3.city, state: building3.state, country: building3.country, postalCode: building3.postalCode, 'type: building3.'type}
    ]);
    check rainierClient.close();
}

@test:Config {
    groups: ["building", "in-memory"],
    dependsOn: [inMemoryBuildingReadOneTest, inMemoryBuildingReadManyTest, inMemoryBuildingReadManyDependentTest]
}
function inMemoryBuildingUpdateTest() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    Building building = check rainierClient->/buildings/[building1.buildingCode].put({
        city: "Galle",
        state: "Southern Province",
        postalCode: "10890",
        'type: "owned"
    });

    test:assertEquals(building, updatedBuilding1);

    Building buildingRetrieved = check rainierClient->/buildings/[building1.buildingCode].get();
    test:assertEquals(buildingRetrieved, updatedBuilding1);
    check rainierClient.close();
}

@test:Config {
    groups: ["building", "in-memory"],
    dependsOn: [inMemoryBuildingReadOneTest, inMemoryBuildingReadManyTest, inMemoryBuildingReadManyDependentTest]
}
function inMemoryBuildingUpdateTestNegative1() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    Building|error building = rainierClient->/buildings/["invalid-building-code"].put({
        city: "Galle",
        state: "Southern Province",
        postalCode: "10890"
    });

    if building is NotFoundError {
        test:assertEquals(building.message(), "Not found: invalid-building-code");
    } else {
        test:assertFail("NotFoundError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["building", "in-memory"],
    dependsOn: [inMemoryBuildingUpdateTest]
}
function inMemoryBuildingDeleteTest() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    Building building = check rainierClient->/buildings/[building1.buildingCode].delete();
    test:assertEquals(building, updatedBuilding1);

    stream<Building, error?> buildingStream = rainierClient->/buildings.get();
    Building[] buildings = check from Building building2 in buildingStream
        select building2;

    test:assertEquals(buildings, [building2, building3]);
    check rainierClient.close();
}

@test:Config {
    groups: ["building", "in-memory"],
    dependsOn: [inMemoryBuildingDeleteTest]
}
function inMemoryBuildingDeleteTestNegative() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    Building|error building = rainierClient->/buildings/[building1.buildingCode].delete();

    if building is error {
        test:assertEquals(building.message(), string `Not found: ${building1.buildingCode}`);
    } else {
        test:assertFail("NotFoundError expected.");
    }
    check rainierClient.close();
}
