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
    groups: ["id-fields"]
}
function intIdFieldTest() returns error? {
    TestEntitiesClient testEntitiesClient = check new ();
    IntIdRecord intIdRecord1 = {
        id: 1,
        randomField: "test1"
    };
    IntIdRecord intIdRecord2 = {
        id: 2,
        randomField: "test2"
    };
    IntIdRecord intIdRecord3 = {
        id: 3,
        randomField: "test3"
    };
    IntIdRecord intIdRecord1Updated = {
        id: 1,
        randomField: "test1Updated"
    };

    // create
    int[] ids = check testEntitiesClient->/intidrecord.post([intIdRecord1, intIdRecord2, intIdRecord3]);
    test:assertEquals(ids, [intIdRecord1.id, intIdRecord2.id, intIdRecord3.id]);

    // read one
    IntIdRecord retrievedRecord1 = check testEntitiesClient->/intidrecord/[intIdRecord1.id].get();
    test:assertEquals(intIdRecord1, retrievedRecord1);

    // read
    IntIdRecord[] intIdRecords = check from IntIdRecord intIdRecord in testEntitiesClient->/intidrecord.get()
        select intIdRecord;
    test:assertEquals(intIdRecords, [intIdRecord1, intIdRecord2, intIdRecord3]);

    // update
    retrievedRecord1 = check testEntitiesClient->/intidrecord/[intIdRecord1.id].put({randomField: intIdRecord1Updated.randomField});
    test:assertEquals(intIdRecord1Updated, retrievedRecord1);
    retrievedRecord1 = check testEntitiesClient->/intidrecord/[intIdRecord1.id].get();
    test:assertEquals(intIdRecord1Updated, retrievedRecord1);

    // delete
    IntIdRecord retrievedRecord2 = check testEntitiesClient->/intidrecord/[intIdRecord2.id].delete();
    test:assertEquals(intIdRecord2, retrievedRecord2);
    intIdRecords = check from IntIdRecord intIdRecord in testEntitiesClient->/intidrecord.get()
        select intIdRecord;
    test:assertEquals(intIdRecords, [intIdRecord1Updated, intIdRecord3]);

    check testEntitiesClient.close();
}

@test:Config {
    groups: ["id-fields"]
}
function stringIdFieldTest() returns error? {
    TestEntitiesClient testEntitiesClient = check new ();
    StringIdRecord stringIdRecord1 = {
        id: "id-1",
        randomField: "test1"
    };
    StringIdRecord stringIdRecord2 = {
        id: "id-2",
        randomField: "test2"
    };
    StringIdRecord stringIdRecord3 = {
        id: "id-3",
        randomField: "test3"
    };
    StringIdRecord stringIdRecord1Updated = {
        id: "id-1",
        randomField: "test1Updated"
    };

    // create
    string[] ids = check testEntitiesClient->/stringidrecord.post([stringIdRecord1, stringIdRecord2, stringIdRecord3]);
    test:assertEquals(ids, [stringIdRecord1.id, stringIdRecord2.id, stringIdRecord3.id]);

    // read one
    StringIdRecord retrievedRecord1 = check testEntitiesClient->/stringidrecord/[stringIdRecord1.id].get();
    test:assertEquals(stringIdRecord1, retrievedRecord1);

    // read
    StringIdRecord[] stringIdRecords = check from StringIdRecord stringIdRecord in testEntitiesClient->/stringidrecord.get()
        select stringIdRecord;
    test:assertEquals(stringIdRecords, [stringIdRecord1, stringIdRecord2, stringIdRecord3]);

    // update
    retrievedRecord1 = check testEntitiesClient->/stringidrecord/[stringIdRecord1.id].put({randomField: stringIdRecord1Updated.randomField});
    test:assertEquals(stringIdRecord1Updated, retrievedRecord1);
    retrievedRecord1 = check testEntitiesClient->/stringidrecord/[stringIdRecord1.id].get();
    test:assertEquals(stringIdRecord1Updated, retrievedRecord1);

    // delete
    StringIdRecord retrievedRecord2 = check testEntitiesClient->/stringidrecord/[stringIdRecord2.id].delete();
    test:assertEquals(stringIdRecord2, retrievedRecord2);
    stringIdRecords = check from StringIdRecord stringIdRecord in testEntitiesClient->/stringidrecord.get()
        select stringIdRecord;
    test:assertEquals(stringIdRecords, [stringIdRecord1Updated, stringIdRecord3]);

    check testEntitiesClient.close();
}

@test:Config {
    groups: ["id-fields"]
}
function floatIdFieldTest() returns error? {
    TestEntitiesClient testEntitiesClient = check new ();
    FloatIdRecord floatIdRecord1 = {
        id: 1.0,
        randomField: "test1"
    };
    FloatIdRecord floatIdRecord2 = {
        id: 2.0,
        randomField: "test2"
    };
    FloatIdRecord floatIdRecord3 = {
        id: 3.0,
        randomField: "test3"
    };
    FloatIdRecord floatIdRecord1Updated = {
        id: 1.0,
        randomField: "test1Updated"
    };

    // create
    float[] ids = check testEntitiesClient->/floatidrecord.post([floatIdRecord1, floatIdRecord2, floatIdRecord3]);
    test:assertEquals(ids, [floatIdRecord1.id, floatIdRecord2.id, floatIdRecord3.id]);

    // read one
    FloatIdRecord retrievedRecord1 = check testEntitiesClient->/floatidrecord/[floatIdRecord1.id].get();
    test:assertEquals(floatIdRecord1, retrievedRecord1);

    // read
    FloatIdRecord[] floatIdRecords = check from FloatIdRecord floatIdRecord in testEntitiesClient->/floatidrecord.get()
        select floatIdRecord;
    test:assertEquals(floatIdRecords, [floatIdRecord1, floatIdRecord2, floatIdRecord3]);

    // update
    retrievedRecord1 = check testEntitiesClient->/floatidrecord/[floatIdRecord1.id].put({randomField: floatIdRecord1Updated.randomField});
    test:assertEquals(floatIdRecord1Updated, retrievedRecord1);
    retrievedRecord1 = check testEntitiesClient->/floatidrecord/[floatIdRecord1.id].get();
    test:assertEquals(floatIdRecord1Updated, retrievedRecord1);

    // delete
    FloatIdRecord retrievedRecord2 = check testEntitiesClient->/floatidrecord/[floatIdRecord2.id].delete();
    test:assertEquals(floatIdRecord2, retrievedRecord2);
    floatIdRecords = check from FloatIdRecord floatIdRecord in testEntitiesClient->/floatidrecord.get()
        select floatIdRecord;
    test:assertEquals(floatIdRecords, [floatIdRecord1Updated, floatIdRecord3]);
}

@test:Config {
    groups: ["id-fields"]
}
function decimalIdFieldTest() returns error? {
    TestEntitiesClient testEntitiesClient = check new ();
    DecimalIdRecord decimalIdRecord1 = {
        id: 1.1d,
        randomField: "test1"
    };
    DecimalIdRecord decimalIdRecord2 = {
        id: 2.2d,
        randomField: "test2"
    };
    DecimalIdRecord decimalIdRecord3 = {
        id: 3.3d,
        randomField: "test3"
    };
    DecimalIdRecord decimalIdRecord1Updated = {
        id: 1.1d,
        randomField: "test1Updated"
    };
    
    // create
    decimal[] ids = check testEntitiesClient->/decimalidrecord.post([decimalIdRecord1, decimalIdRecord2, decimalIdRecord3]);
    test:assertEquals(ids, [decimalIdRecord1.id, decimalIdRecord2.id, decimalIdRecord3.id]);

    // read one
    DecimalIdRecord retrievedRecord1 = check testEntitiesClient->/decimalidrecord/[decimalIdRecord1.id].get();
    test:assertEquals(decimalIdRecord1, retrievedRecord1);

    // read
    DecimalIdRecord[] decimalIdRecords = check from DecimalIdRecord decimalIdRecord in testEntitiesClient->/decimalidrecord.get()
        select decimalIdRecord;
    test:assertEquals(decimalIdRecords, [decimalIdRecord1, decimalIdRecord2, decimalIdRecord3]);

    // update
    retrievedRecord1 = check testEntitiesClient->/decimalidrecord/[decimalIdRecord1.id].put({randomField: decimalIdRecord1Updated.randomField});
    test:assertEquals(decimalIdRecord1Updated, retrievedRecord1);
    retrievedRecord1 = check testEntitiesClient->/decimalidrecord/[decimalIdRecord1.id].get();
    test:assertEquals(decimalIdRecord1Updated, retrievedRecord1);

    // delete
    DecimalIdRecord retrievedRecord2 = check testEntitiesClient->/decimalidrecord/[decimalIdRecord2.id].delete();
    test:assertEquals(decimalIdRecord2, retrievedRecord2);
    decimalIdRecords = check from DecimalIdRecord decimalIdRecord in testEntitiesClient->/decimalidrecord.get()
        select decimalIdRecord;
    test:assertEquals(decimalIdRecords, [decimalIdRecord1Updated, decimalIdRecord3]);

    check testEntitiesClient.close();
}

@test:Config {
    groups: ["id-fields"]
}
function booleanIdFieldTest() returns  error? {
    TestEntitiesClient testEntitiesClient = check new ();
    BooleanIdRecord booleanIdRecord1 = {
        id: true,
        randomField: "test1"
    };
    BooleanIdRecord booleanIdRecord2 = {
        id: false,
        randomField: "test2"
    };
    BooleanIdRecord booleanIdRecord1Updated = {
        id: true,
        randomField: "test1Updated"
    };

    // create
    boolean[] ids = check testEntitiesClient->/booleanidrecord.post([booleanIdRecord1, booleanIdRecord2]);
    test:assertEquals(ids, [booleanIdRecord1.id, booleanIdRecord2.id]);

    // read one
    BooleanIdRecord retrievedRecord1 = check testEntitiesClient->/booleanidrecord/[booleanIdRecord1.id].get();
    test:assertEquals(booleanIdRecord1, retrievedRecord1);

    // read
    BooleanIdRecord[] booleanIdRecords = check from BooleanIdRecord booleanIdRecord in testEntitiesClient->/booleanidrecord.get()
        select booleanIdRecord;
    test:assertEquals(booleanIdRecords, [booleanIdRecord2, booleanIdRecord1]);

    // update
    retrievedRecord1 = check testEntitiesClient->/booleanidrecord/[booleanIdRecord1.id].put({randomField: booleanIdRecord1Updated.randomField});
    test:assertEquals(booleanIdRecord1Updated, retrievedRecord1);
    retrievedRecord1 = check testEntitiesClient->/booleanidrecord/[booleanIdRecord1.id].get();
    test:assertEquals(booleanIdRecord1Updated, retrievedRecord1);

    // delete
    BooleanIdRecord retrievedRecord2 = check testEntitiesClient->/booleanidrecord/[booleanIdRecord2.id].delete();
    test:assertEquals(booleanIdRecord2, retrievedRecord2);
    booleanIdRecords = check from BooleanIdRecord booleanIdRecord in testEntitiesClient->/booleanidrecord.get()
        select booleanIdRecord;
    test:assertEquals(booleanIdRecords, [booleanIdRecord1Updated]);

    check testEntitiesClient.close();
}

@test:Config {
    groups: ["id-fields"]
}
function allTypesIdFieldTest() returns error? {
    TestEntitiesClient testEntitiesClient = check new ();
    AllTypesIdRecord allTypesIdRecord1 = {
        intType: 1,
        stringType: "id-1",
        floatType: 1.0,
        booleanType: true,
        decimalType: 1.1d,
        randomField: "test1"
    };
    AllTypesIdRecord allTypesIdRecord2 = {
        intType: 2,
        stringType: "id-2",
        floatType: 2.0,
        booleanType: false,
        decimalType: 2.2d,
        randomField: "test2"
    };
    AllTypesIdRecord allTypesIdRecord1Updated = {
        intType: 1,
        stringType: "id-1",
        floatType: 1.0,
        booleanType: true,
        decimalType: 1.1d,
        randomField: "test1Updated"
    };

    // create
    [boolean, int, float, decimal, string][] ids = check testEntitiesClient->/alltypesidrecord.post([allTypesIdRecord1, allTypesIdRecord2]);
    test:assertEquals(ids, [[allTypesIdRecord1.booleanType, allTypesIdRecord1.intType, allTypesIdRecord1.floatType, allTypesIdRecord1.decimalType, allTypesIdRecord1.stringType], 
        [allTypesIdRecord2.booleanType, allTypesIdRecord2.intType, allTypesIdRecord2.floatType, allTypesIdRecord2.decimalType, allTypesIdRecord2.stringType]]);

    // read one
    AllTypesIdRecord retrievedRecord1 = check testEntitiesClient->/alltypesidrecord/[allTypesIdRecord1.floatType]/[allTypesIdRecord1.decimalType]/[allTypesIdRecord1.booleanType]/[allTypesIdRecord1.intType]/[allTypesIdRecord1.stringType].get();
    test:assertEquals(allTypesIdRecord1, retrievedRecord1);

    // read
    AllTypesIdRecord[] allTypesIdRecords = check from AllTypesIdRecord allTypesIdRecord in testEntitiesClient->/alltypesidrecord.get()
        select allTypesIdRecord;
    test:assertEquals(allTypesIdRecords, [allTypesIdRecord2, allTypesIdRecord1]);

    // update
    retrievedRecord1 = check testEntitiesClient->/alltypesidrecord/[allTypesIdRecord1.floatType]/[allTypesIdRecord1.decimalType]/[allTypesIdRecord1.booleanType]/[allTypesIdRecord1.intType]/[allTypesIdRecord1.stringType].put({randomField: allTypesIdRecord1Updated.randomField});
    test:assertEquals(allTypesIdRecord1Updated, retrievedRecord1);
    retrievedRecord1 = check testEntitiesClient->/alltypesidrecord/[allTypesIdRecord1.floatType]/[allTypesIdRecord1.decimalType]/[allTypesIdRecord1.booleanType]/[allTypesIdRecord1.intType]/[allTypesIdRecord1.stringType].get();
    test:assertEquals(allTypesIdRecord1Updated, retrievedRecord1);

    // delete
    AllTypesIdRecord retrievedRecord2 = check testEntitiesClient->/alltypesidrecord/[allTypesIdRecord2.floatType]/[allTypesIdRecord2.decimalType]/[allTypesIdRecord2.booleanType]/[allTypesIdRecord2.intType]/[allTypesIdRecord2.stringType].delete();
    test:assertEquals(allTypesIdRecord2, retrievedRecord2);
    allTypesIdRecords = check from AllTypesIdRecord allTypesIdRecord in testEntitiesClient->/alltypesidrecord.get()
        select allTypesIdRecord;
    test:assertEquals(allTypesIdRecords, [allTypesIdRecord1Updated]);

    check testEntitiesClient.close();
}

@test:Config {
    groups: ["id-fields", "associations"],
    dependsOn : [allTypesIdFieldTest]
}
function compositeAssociationsTest() returns error? {
    TestEntitiesClient testEntitiesClient = check new ();

    CompositeAssociationRecord compositeAssociationRecord1 = {
        id: "id-1",
        randomField: "test1",
        alltypesidrecordIntType: 1,
        alltypesidrecordStringType: "id-1",
        alltypesidrecordFloatType: 1.0,
        alltypesidrecordBooleanType: true,
        alltypesidrecordDecimalType: 1.1d        
    };

    CompositeAssociationRecord compositeAssociationRecord2 = {
        id: "id-2",
        randomField: "test2",
        alltypesidrecordIntType: 1,
        alltypesidrecordStringType: "id-1",
        alltypesidrecordFloatType: 1.0,
        alltypesidrecordBooleanType: true,
        alltypesidrecordDecimalType: 1.1d        
    };

    CompositeAssociationRecord compositeAssociationRecordUpdated1 = {
        id: "id-1",
        randomField: "test1Updated",
        alltypesidrecordIntType: 1,
        alltypesidrecordStringType: "id-1",
        alltypesidrecordFloatType: 1.0,
        alltypesidrecordBooleanType: true,
        alltypesidrecordDecimalType: 1.1d
    };

    // create
    string[] ids = check testEntitiesClient->/compositeassociationrecord.post([compositeAssociationRecord1, compositeAssociationRecord2]);
    test:assertEquals(ids, [compositeAssociationRecord1.id, compositeAssociationRecord2.id]);

    // read one
    CompositeAssociationRecord retrievedRecord1 = check testEntitiesClient->/compositeassociationrecord/[compositeAssociationRecord1.id].get();
    test:assertEquals(compositeAssociationRecord1, retrievedRecord1);

    // read
    CompositeAssociationRecord[] compositeAssociationRecords = check from CompositeAssociationRecord compositeAssociationRecord in testEntitiesClient->/compositeassociationrecord.get()
        select compositeAssociationRecord;
    test:assertEquals(compositeAssociationRecords, [compositeAssociationRecord1, compositeAssociationRecord2]);

    // update
    retrievedRecord1 = check testEntitiesClient->/compositeassociationrecord/[compositeAssociationRecord1.id].put({randomField: "test1Updated"});
    test:assertEquals(compositeAssociationRecordUpdated1, retrievedRecord1);
    retrievedRecord1 = check testEntitiesClient->/compositeassociationrecord/[compositeAssociationRecord1.id].get();
    test:assertEquals(compositeAssociationRecordUpdated1, retrievedRecord1);

    // delete
    CompositeAssociationRecord retrievedRecord2 = check testEntitiesClient->/compositeassociationrecord/[compositeAssociationRecord2.id].delete();
    test:assertEquals(compositeAssociationRecord2, retrievedRecord2);
    compositeAssociationRecords = check from CompositeAssociationRecord compositeAssociationRecord in testEntitiesClient->/compositeassociationrecord.get()
        select compositeAssociationRecord;
    test:assertEquals(compositeAssociationRecords, [compositeAssociationRecordUpdated1]);
    
    check testEntitiesClient.close();
}