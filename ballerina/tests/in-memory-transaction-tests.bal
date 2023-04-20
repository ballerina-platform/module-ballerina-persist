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
import ballerina/io;

@test:Config {
    groups: ["transactions", "in-memory"]
}
function inMemoryTransactionTest() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    transaction {
        string[] buildingCodes = check rainierClient->/buildings.post([building31, building32]);
        test:assertEquals(buildingCodes, [building31.buildingCode, building32.buildingCode]);

        buildingCodes = check rainierClient->/buildings.post([building31]);
        check commit;
    } on fail error e {
        io:println("fml");
        test:assertTrue(e is DuplicateKeyError, "DuplicateKeyError expected");
    }

    Building|Error buildingRetrieved = rainierClient->/buildings/[building31.buildingCode].get();
    io:println(buildingRetrieved);
    test:assertTrue(buildingRetrieved is InvalidKeyError, "InvalidKeyError expected");

    buildingRetrieved = rainierClient->/buildings/[building32.buildingCode].get();
    test:assertTrue(buildingRetrieved is InvalidKeyError, "InvalidKeyError expected");

    check rainierClient.close();
}

@test:Config {
    groups: ["transactions", "in-memory"]
}
function inMemoryTransactionTest2() returns error? {
    InMemoryRainierClient rainierClient = check new ();

    _ = check rainierClient->/buildings.post([building33]);
    Building buildingRetrieved = check rainierClient->/buildings/[building33.buildingCode].get();
    test:assertEquals(buildingRetrieved, building33);

    transaction {
        Building building = check rainierClient->/buildings/[building33.buildingCode].put({
            city: "ColomboUpdated",
            state: "Western ProvinceUpdated",
            country: "Sri LankaUpdated"
        });

        test:assertEquals(building, building33Updated);

        buildingRetrieved = check rainierClient->/buildings/[building33.buildingCode].get();
        test:assertEquals(buildingRetrieved, building33Updated);

        check commit;
    }

    buildingRetrieved = check rainierClient->/buildings/[building33.buildingCode].get();
    test:assertEquals(buildingRetrieved, building33Updated);

    check rainierClient.close();
}
