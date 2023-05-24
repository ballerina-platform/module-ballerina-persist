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
    groups: ["building", "sql"]
}
function sqlBuildingCreateTest() returns error? {
    SQLRainierClient rainierClient = check new ();

    string[] buildingCodes = check rainierClient->/buildings.post([building1]);
    test:assertEquals(buildingCodes, [building1.buildingCode]);

    Building buildingRetrieved = check rainierClient->/buildings/[building1.buildingCode].get();
    test:assertEquals(buildingRetrieved, building1);
    check rainierClient.close();
}

@test:Config {
    groups: ["building", "sql"]
}
function sqlBuildingCreateTest2() returns error? {
    SQLRainierClient rainierClient = check new ();

    string[] buildingCodes = check rainierClient->/buildings.post([building2, building3]);

    test:assertEquals(buildingCodes, [building2.buildingCode, building3.buildingCode]);

    Building buildingRetrieved = check rainierClient->/buildings/[building2.buildingCode].get();
    test:assertEquals(buildingRetrieved, building2);

    buildingRetrieved = check rainierClient->/buildings/[building3.buildingCode].get();
    test:assertEquals(buildingRetrieved, building3);

    check rainierClient.close();
}

@test:Config {
    groups: ["building", "sql"]
}
function sqlBuildingCreateTestNegative() returns error? {
    SQLRainierClient rainierClient = check new ();

    string[]|error building = rainierClient->/buildings.post([invalidBuilding]);
    if building is Error {
        test:assertTrue(building.message().includes("Data truncation: Data too long for column 'buildingCode' at row 1."));
    } else {
        test:assertFail("Error expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["building", "sql"],
    dependsOn: [sqlBuildingCreateTest]
}
function sqlBuildingReadOneTest() returns error? {
    SQLRainierClient rainierClient = check new ();

    Building buildingRetrieved = check rainierClient->/buildings/[building1.buildingCode].get();
    test:assertEquals(buildingRetrieved, building1);
    check rainierClient.close();
}

@test:Config {
    groups: ["building", "sql"],
    dependsOn: [sqlBuildingCreateTest]
}
function sqlBuildingReadOneTestNegative() returns error? {
    SQLRainierClient rainierClient = check new ();

    Building|error buildingRetrieved = rainierClient->/buildings/["invalid-building-code"].get();
    if buildingRetrieved is NotFoundError {
        test:assertEquals(buildingRetrieved.message(), "A record with the key 'invalid-building-code' does not exist for the entity 'Building'.");
    } else {
        test:assertFail("NotFoundError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["building", "sql"],
    dependsOn: [sqlBuildingCreateTest, sqlBuildingCreateTest2]
}
function sqlBuildingReadManyTest() returns error? {
    SQLRainierClient rainierClient = check new ();

    stream<Building, error?> buildingStream = rainierClient->/buildings.get();
    Building[] buildings = check from Building building in buildingStream
        select building;

    test:assertEquals(buildings, [building1, building2, building3]);
    check rainierClient.close();
}

@test:Config {
    groups: ["building", "sql", "dependent"],
    dependsOn: [sqlBuildingCreateTest, sqlBuildingCreateTest2]
}
function sqlBuildingReadManyDependentTest() returns error? {
    SQLRainierClient rainierClient = check new ();

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
    groups: ["building", "sql"],
    dependsOn: [sqlBuildingReadOneTest, sqlBuildingReadManyTest, sqlBuildingReadManyDependentTest]
}
function sqlBuildingUpdateTest() returns error? {
    SQLRainierClient rainierClient = check new ();

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
    groups: ["building", "sql"],
    dependsOn: [sqlBuildingReadOneTest, sqlBuildingReadManyTest, sqlBuildingReadManyDependentTest]
}
function sqlBuildingUpdateTestNegative1() returns error? {
    SQLRainierClient rainierClient = check new ();

    Building|error building = rainierClient->/buildings/["invalid-building-code"].put({
        city: "Galle",
        state: "Southern Province",
        postalCode: "10890"
    });

    if building is NotFoundError {
        test:assertEquals(building.message(), "A record with the key 'invalid-building-code' does not exist for the entity 'Building'.");
    } else {
        test:assertFail("NotFoundError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["building", "sql"],
    dependsOn: [sqlBuildingReadOneTest, sqlBuildingReadManyTest, sqlBuildingReadManyDependentTest]
}
function sqlBuildingUpdateTestNegative2() returns error? {
    SQLRainierClient rainierClient = check new ();

    Building|error building = rainierClient->/buildings/[building1.buildingCode].put({
        city: "unncessarily-long-city-name-to-force-error-on-update",
        state: "Southern Province",
        postalCode: "10890"
    });

    if building is Error {
        test:assertTrue(building.message().includes("Data truncation: Data too long for column 'city' at row 1."));
    } else {
        test:assertFail("NotFoundError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["building", "sql"],
    dependsOn: [sqlBuildingUpdateTest, sqlBuildingUpdateTestNegative2]
}
function sqlBuildingDeleteTest() returns error? {
    SQLRainierClient rainierClient = check new ();

    Building building = check rainierClient->/buildings/[building1.buildingCode].delete();
    test:assertEquals(building, updatedBuilding1);

    stream<Building, error?> buildingStream = rainierClient->/buildings.get();
    Building[] buildings = check from Building building2 in buildingStream
        select building2;

    test:assertEquals(buildings, [building2, building3]);
    check rainierClient.close();
}

@test:Config {
    groups: ["building", "sql"],
    dependsOn: [sqlBuildingDeleteTest]
}
function sqlBuildingDeleteTestNegative() returns error? {
    SQLRainierClient rainierClient = check new ();

    Building|error building = rainierClient->/buildings/[building1.buildingCode].delete();

    if building is error {
        test:assertEquals(building.message(), string `A record with the key '${building1.buildingCode}' does not exist for the entity 'Building'.`);
    } else {
        test:assertFail("NotFoundError expected.");
    }
    check rainierClient.close();
}
