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
import ballerina/time;

time:Zone zone = check time:loadSystemZone();

AllTypes allTypes1 = {
    id: 1,
    booleanType: false,
    intType: 5,
    floatType: 6.0,
    decimalType: 23.44,
    stringType: "test",
    byteArrayType: base16 `55 EE 66 FF 77 AB`,
    dateType: {year: 1993, month: 11, day: 3},
    timeOfDayType: {hour: 12, minute: 32, second: 34},
    civilType: {year: 1993, month: 11, day: 3, hour: 12, minute: 32, second: 34},
    booleanTypeOptional: false,
    intTypeOptional: 5,
    floatTypeOptional: 6.0,
    decimalTypeOptional: 23.44,
    stringTypeOptional: "test",
    dateTypeOptional: {year: 1993, month: 11, day: 3},
    timeOfDayTypeOptional: {hour: 12, minute: 32, second: 34},
    civilTypeOptional: {year: 1993, month: 11, day: 3, hour: 12, minute: 32, second: 34}
};

AllTypes allTypes1Expected = {
    id: allTypes1.id,
    booleanType: allTypes1.booleanType,
    intType: allTypes1.intType,
    floatType: allTypes1.floatType,
    decimalType: allTypes1.decimalType,
    stringType: allTypes1.stringType,
    byteArrayType: allTypes1.byteArrayType,
    dateType: allTypes1.dateType,
    timeOfDayType: allTypes1.timeOfDayType,
    civilType: allTypes1.civilType,
    booleanTypeOptional: allTypes1.booleanTypeOptional,
    intTypeOptional: allTypes1.intTypeOptional,
    floatTypeOptional: allTypes1.floatTypeOptional,
    decimalTypeOptional: allTypes1.decimalTypeOptional,
    stringTypeOptional: allTypes1.stringTypeOptional,
    dateTypeOptional: allTypes1.dateTypeOptional,
    timeOfDayTypeOptional: allTypes1.timeOfDayTypeOptional,
    civilTypeOptional: allTypes1.civilTypeOptional
};

AllTypes allTypes2 = {
    id: 2,
    booleanType: true,
    intType: 35,
    floatType: 63.0,
    decimalType: 233.44,
    stringType: "test2",
    byteArrayType: base16 `55 EE 66 AF 77 AB`,
    dateType: {year: 1996, month: 11, day: 3},
    timeOfDayType: {hour: 17, minute: 32, second: 34},
    civilType: {year: 1999, month: 11, day: 3, hour: 12, minute: 32, second: 34},
    booleanTypeOptional: true,
    intTypeOptional: 6,
    floatTypeOptional: 66.0,
    decimalTypeOptional: 233.44,
    stringTypeOptional: "test2",
    dateTypeOptional: {year: 1293, month: 11, day: 3},
    timeOfDayTypeOptional: {hour: 19, minute: 32, second: 34},
    civilTypeOptional: {year: 1989, month: 11, day: 3, hour: 12, minute: 32, second: 34}
};

AllTypes allTypes2Expected = {
    id: allTypes2.id,
    booleanType: allTypes2.booleanType,
    intType: allTypes2.intType,
    floatType: allTypes2.floatType,
    decimalType: allTypes2.decimalType,
    stringType: allTypes2.stringType,
    byteArrayType: allTypes2.byteArrayType,
    dateType: allTypes2.dateType,
    timeOfDayType: allTypes2.timeOfDayType,
    civilType: allTypes2.civilType,
    booleanTypeOptional: allTypes2.booleanTypeOptional,
    intTypeOptional: allTypes2.intTypeOptional,
    floatTypeOptional: allTypes2.floatTypeOptional,
    decimalTypeOptional: allTypes2.decimalTypeOptional,
    stringTypeOptional: allTypes2.stringTypeOptional,
    dateTypeOptional: allTypes2.dateTypeOptional,
    timeOfDayTypeOptional: allTypes2.timeOfDayTypeOptional,
    civilTypeOptional: allTypes2.civilTypeOptional
};

//TODO: Make time types also optional
AllTypes allTypes3 = {
    id: 3,
    booleanType: true,
    intType: 35,
    floatType: 63.0,
    decimalType: 233.44,
    stringType: "test2",
    byteArrayType: base16 `55 EE 66 AF 77 AB`,
    dateType: {year: 1996, month: 11, day: 3},
    timeOfDayType: {hour: 17, minute: 32, second: 34},
    civilType: {year: 1999, month: 11, day: 3, hour: 12, minute: 32, second: 34},
    booleanTypeOptional: (),
    intTypeOptional: (),
    floatTypeOptional: (),
    decimalTypeOptional: (),
    stringTypeOptional: (),
    dateTypeOptional: {year: 1293, month: 11, day: 3},
    timeOfDayTypeOptional: {hour: 19, minute: 32, second: 34},
    civilTypeOptional: {year: 1989, month: 11, day: 3, hour: 12, minute: 32, second: 34}
};

AllTypes allTypes3Expected = {
    id: allTypes3.id,
    booleanType: allTypes3.booleanType,
    intType: allTypes3.intType,
    floatType: allTypes3.floatType,
    decimalType: allTypes3.decimalType,
    stringType: allTypes3.stringType,
    byteArrayType: allTypes3.byteArrayType,
    dateType: allTypes3.dateType,
    timeOfDayType: allTypes3.timeOfDayType,
    civilType: allTypes3.civilType,
    booleanTypeOptional: allTypes3.booleanTypeOptional,
    intTypeOptional: allTypes3.intTypeOptional,
    floatTypeOptional: allTypes3.floatTypeOptional,
    decimalTypeOptional: allTypes3.decimalTypeOptional,
    stringTypeOptional: allTypes3.stringTypeOptional,
    dateTypeOptional: allTypes3.dateTypeOptional,
    timeOfDayTypeOptional: allTypes3.timeOfDayTypeOptional,
    civilTypeOptional: allTypes3.civilTypeOptional
};

AllTypes allTypes1Updated = {
    id: 1,
    booleanType: true,
    intType: 99,
    floatType: 63.0,
    decimalType: 53.44,
    stringType: "testUpdate",
    byteArrayType: base16 `55 FE 66 FF 77 AB`,
    dateType: {year: 1996, month: 12, day: 13},
    timeOfDayType: {hour: 16, minute: 12, second: 14},
    civilType: {year: 1998, month: 9, day: 13, hour: 12, minute: 32, second: 34},
    booleanTypeOptional: true,
    intTypeOptional: 53,
    floatTypeOptional: 26.0,
    decimalTypeOptional: 223.44,
    stringTypeOptional: "testUpdate",
    dateTypeOptional: {year: 1923, month: 11, day: 3},
    timeOfDayTypeOptional: {hour: 18, minute: 32, second: 34},
    civilTypeOptional: {year: 1991, month: 11, day: 3, hour: 12, minute: 32, second: 34}
};

AllTypes allTypes1UpdatedExpected = {
    id: allTypes1Updated.id,
    booleanType: allTypes1Updated.booleanType,
    intType: allTypes1Updated.intType,
    floatType: allTypes1Updated.floatType,
    decimalType: allTypes1Updated.decimalType,
    stringType: allTypes1Updated.stringType,
    byteArrayType: allTypes1Updated.byteArrayType,
    dateType: allTypes1Updated.dateType,
    timeOfDayType: allTypes1Updated.timeOfDayType,
    civilType: allTypes1Updated.civilType,
    booleanTypeOptional: allTypes1Updated.booleanTypeOptional,
    intTypeOptional: allTypes1Updated.intTypeOptional,
    floatTypeOptional: allTypes1Updated.floatTypeOptional,
    decimalTypeOptional: allTypes1Updated.decimalTypeOptional,
    stringTypeOptional: allTypes1Updated.stringTypeOptional,
    dateTypeOptional: allTypes1Updated.dateTypeOptional,
    timeOfDayTypeOptional: allTypes1Updated.timeOfDayTypeOptional,
    civilTypeOptional: allTypes1Updated.civilTypeOptional
};

@test:Config {
    groups: ["all-types"]
}
function allTypesCreateTest() returns error? {
    TestEntitiesClient testEntitiesClient = check new ();

    int[] ids = check testEntitiesClient->/alltypes.post([allTypes1, allTypes2]);
    test:assertEquals(ids, [allTypes1.id, allTypes2.id]);

    AllTypes allTypesRetrieved = check testEntitiesClient->/alltypes/[allTypes1.id].get();
    test:assertEquals(allTypesRetrieved, allTypes1Expected);

    allTypesRetrieved = check testEntitiesClient->/alltypes/[allTypes2.id].get();
    test:assertEquals(allTypesRetrieved, allTypes2Expected);

    check testEntitiesClient.close();
}

@test:Config {
    groups: ["all-types"]
}
function allTypesCreateOptionalTest() returns error? {
    TestEntitiesClient testEntitiesClient = check new ();

    int[] ids = check testEntitiesClient->/alltypes.post([allTypes3]);
    test:assertEquals(ids, [allTypes3.id]);

    AllTypes allTypesRetrieved = check testEntitiesClient->/alltypes/[allTypes3.id].get();
    test:assertEquals(allTypesRetrieved, allTypes3Expected);

    check testEntitiesClient.close();
}

@test:Config {
    groups: ["all-types"],
    dependsOn: [allTypesCreateTest, allTypesCreateOptionalTest]
}
function allTypesReadTest() returns error? {
    TestEntitiesClient testEntitiesClient = check new ();

    stream<AllTypes, error?> allTypesStream = testEntitiesClient->/alltypes.get();
    AllTypes[] allTypes = check from AllTypes allTypesRecord in allTypesStream
        select allTypesRecord;

    test:assertEquals(allTypes, [allTypes1Expected, allTypes2Expected, allTypes3Expected]);
    check testEntitiesClient.close();
}

@test:Config {
    groups: ["all-types"],
    dependsOn: [allTypesCreateTest, allTypesCreateOptionalTest]
}
function allTypesReadOneTest() returns error? {
    TestEntitiesClient testEntitiesClient = check new ();

    AllTypes allTypesRetrieved = check testEntitiesClient->/alltypes/[allTypes1.id].get();
    test:assertEquals(allTypesRetrieved, allTypes1Expected);

    allTypesRetrieved = check testEntitiesClient->/alltypes/[allTypes2.id].get();
    test:assertEquals(allTypesRetrieved, allTypes2Expected);

    allTypesRetrieved = check testEntitiesClient->/alltypes/[allTypes3.id].get();
    test:assertEquals(allTypesRetrieved, allTypes3Expected);

    check testEntitiesClient.close();
}

@test:Config {
    groups: ["all-types"]
}
function allTypesReadOneTestNegative() returns error? {
    TestEntitiesClient testEntitiesClient = check new ();

    AllTypes|Error allTypesRetrieved = testEntitiesClient->/alltypes/[4].get();
    if allTypesRetrieved is InvalidKeyError {
        test:assertEquals(allTypesRetrieved.message(), "A record does not exist for 'AllTypes' for key 4.");
    }
    else {
        test:assertFail("InvalidKeyError expected.");
    }

    check testEntitiesClient.close();
}

@test:Config {
    groups: ["all-types"],
    dependsOn: [allTypesReadOneTest, allTypesReadTest]
}
function allTypesUpdateTest() returns error? {
    TestEntitiesClient testEntitiesClient = check new ();

    AllTypes allTypes = check testEntitiesClient->/alltypes/[allTypes1.id].put({
        booleanType: allTypes3.booleanType,
        intType: allTypes1Updated.intType,
        floatType: allTypes1Updated.floatType,
        decimalType: allTypes1Updated.decimalType,
        stringType: allTypes1Updated.stringType,
        byteArrayType: allTypes1Updated.byteArrayType,
        dateType: allTypes1Updated.dateType,
        timeOfDayType: allTypes1Updated.timeOfDayType,
        civilType: allTypes1Updated.civilType,
        booleanTypeOptional: allTypes1Updated.booleanTypeOptional,
        intTypeOptional: allTypes1Updated.intTypeOptional,
        floatTypeOptional: allTypes1Updated.floatTypeOptional,
        decimalTypeOptional: allTypes1Updated.decimalTypeOptional,
        stringTypeOptional: allTypes1Updated.stringTypeOptional,
        dateTypeOptional: allTypes1Updated.dateTypeOptional,
        timeOfDayTypeOptional: allTypes1Updated.timeOfDayTypeOptional,
        civilTypeOptional: allTypes1Updated.civilTypeOptional
    });
    test:assertEquals(allTypes, allTypes1UpdatedExpected);

    AllTypes allTypesRetrieved = check testEntitiesClient->/alltypes/[allTypes1.id].get();
    test:assertEquals(allTypesRetrieved, allTypes1UpdatedExpected);
    check testEntitiesClient.close();
}

@test:Config {
    groups: ["all-types"],
    dependsOn: [allTypesUpdateTest]
}
function allTypesDeleteTest() returns error? {
    TestEntitiesClient testEntitiesClient = check new ();

    AllTypes allTypes = check testEntitiesClient->/alltypes/[allTypes2.id].delete();
    test:assertEquals(allTypes, allTypes2Expected);

    stream<AllTypes, error?> allTypesStream = testEntitiesClient->/alltypes.get();
    AllTypes[] allTypesCollection = check from AllTypes allTypesRecord in allTypesStream 
        select allTypesRecord;

    test:assertEquals(allTypesCollection, [allTypes1UpdatedExpected, allTypes3Expected]);
    check testEntitiesClient.close();
}
