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

import ballerina/jballerina.java;

const ALL_TYPES = "alltypes";
const COMPOSITE_ASSOCIATION_RECORD = "compositeassociationrecords";
const ALL_TYPES_ID_RECORD = "alltypesidrecords";

table<AllTypes> key(id) alltypes = table[];
table<CompositeAssociationRecord> key(id) compositeassociationrecords = table[];
table<AllTypesIdRecord> key(booleanType, intType, floatType, decimalType, stringType) alltypesidrecords = table[];

public client class InMemoryTestEntitiesClient {
    *AbstractPersistClient;

    private final map<InMemoryClient> persistClients;

    table<AllTypes> key(id) alltypes = alltypes;
    table<CompositeAssociationRecord> key(id) compositeassociationrecords = compositeassociationrecords;
    table<AllTypesIdRecord> key(booleanType, intType, floatType, decimalType, stringType) alltypesidrecords = alltypesidrecords;

    public function init() returns Error? {

        final map<TableMetadata> metadata = {
            [ALL_TYPES]: {
                keyFields: ["id"],
                query: self.queryAllTypes,
                queryOne: self.queryOneAllTypes   
            },
            [COMPOSITE_ASSOCIATION_RECORD]: {
                keyFields: ["id"],
                query: self.queryCompositeAssociationRecords,
                queryOne: self.queryOneCompositeAssociationRecords
            },
            [ALL_TYPES_ID_RECORD]: {
                keyFields: ["booleanType", "intType", "floatType", "decimalType", "stringType"],
                query: self.queryAllTypesIdRecords,
                queryOne: self.queryOneAllTypesIdRecords
            }
        };

        self.persistClients = {
            [ALL_TYPES]: check new (metadata.get(ALL_TYPES)),
            [COMPOSITE_ASSOCIATION_RECORD]: check new (metadata.get(COMPOSITE_ASSOCIATION_RECORD)),
            [ALL_TYPES_ID_RECORD]: check new (metadata.get(ALL_TYPES_ID_RECORD))
        };
    };

    isolated resource function get alltypes(AllTypesTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "query"
    } external;

    isolated resource function get alltypes/[int id](AllTypesTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "queryOne"
    } external;

    isolated resource function post alltypes(AllTypesInsert[] data) returns int[]|Error {
        int[] keys = [];
        foreach AllTypesInsert value in data {
            if self.alltypes.hasKey(value.id) {
                // TODO: make .toString()
                return <DuplicateKeyError>error("Duplicate key: " + value.id.toString()); 
            }
            self.alltypes.put(value);
            keys.push(value.id);
        }
        return keys;
    }

    // TODO: need to update PUT methods as below
    isolated resource function put alltypes/[int id](AllTypesUpdate value) returns AllTypes|Error {
        if !self.alltypes.hasKey(id) {
            // TODO: add .toString()
            return <InvalidKeyError>error("Not found: " + id.toString());
        }
        AllTypes alltypes = self.alltypes.get(id);
        foreach string key in value.keys() {
            alltypes[key] = value[key];
        }

        self.alltypes.put(alltypes);
        return alltypes;
    }

    isolated resource function delete alltypes/[int id]() returns AllTypes|Error {
        if !self.alltypes.hasKey(id) {
            //TODO: add .toString()
            return <InvalidKeyError>error("Not found: " + id.toString());
        }
        return self.alltypes.remove(id);
    }

    isolated resource function get compositeassociationrecords(CompositeAssociationRecordTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "query"
    } external;

    isolated resource function get compositeassociationrecords/[int id](CompositeAssociationRecordTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "queryOne"
    } external;

    isolated resource function post compositeassociationrecords(CompositeAssociationRecordInsert[] data) returns string[]|Error {
        string[] keys = [];
        foreach CompositeAssociationRecordInsert value in data {
            if self.compositeassociationrecords.hasKey(value.id) {
                return <DuplicateKeyError>error("Duplicate key: " + value.id.toString());
            }
            self.compositeassociationrecords.put(value);
            keys.push(value.id);
        }
        return keys;
    }

    isolated resource function put compositeassociationrecords/[string id](CompositeAssociationRecordUpdate value) returns CompositeAssociationRecord|Error {
        if !self.compositeassociationrecords.hasKey(id) {
            return <InvalidKeyError>error("Not found: " + id.toString());
        }
        CompositeAssociationRecord compositeassociationrecords = self.compositeassociationrecords.get(id);
        foreach string key in value.keys() {
            compositeassociationrecords[key] = value[key];
        }

        self.compositeassociationrecords.put(compositeassociationrecords);
        return compositeassociationrecords;
    }

    isolated resource function delete compositeassociationrecords/[string id]() returns CompositeAssociationRecord|Error {
        if !self.compositeassociationrecords.hasKey(id) {
            return <InvalidKeyError>error("Not found: " + id.toString());
        }
        return self.compositeassociationrecords.remove(id);
    }

    isolated resource function get alltypesidrecords(AllTypesIdRecordTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "query"
    } external;

    isolated resource function get alltypesidrecords/[boolean booleanType]/[int intType]/[float floatType]/[decimal decimalType]/[string stringType](AllTypesIdRecordTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "queryOne"
    } external;

    isolated resource function post alltypesidrecords(AllTypesIdRecordInsert[] data) returns [boolean, int, float, decimal, string][]|Error {
        [boolean, int, float, decimal, string][] keys = [];
        foreach AllTypesIdRecordInsert value in data {
            if self.alltypesidrecords.hasKey([value.booleanType, value.intType, value.floatType, value.decimalType, value.stringType]) {
                return <DuplicateKeyError>error("Duplicate key: " + [value.booleanType, value.intType, value.floatType, value.decimalType, value.stringType].toString());
            }
            self.alltypesidrecords.put(value);
            keys.push([value.booleanType, value.intType, value.floatType, value.decimalType, value.stringType]);
        }
        return keys;
    }

    isolated resource function put alltypesidrecords/[boolean booleanType]/[int intType]/[float floatType]/[decimal decimalType]/[string stringType](AllTypesIdRecordUpdate value) returns AllTypesIdRecord|Error {
        if !self.alltypesidrecords.hasKey([booleanType, intType, floatType, decimalType, stringType]) {
            return <InvalidKeyError>error("Not found: " + [booleanType, intType, floatType, decimalType, stringType].toString());
        }
        AllTypesIdRecord alltypesidrecords = self.alltypesidrecords.get([booleanType, intType, floatType, decimalType, stringType]);
        foreach string key in value.keys() {
            alltypesidrecords[key] = value[key];
        }

        self.alltypesidrecords.put(alltypesidrecords);
        return alltypesidrecords;
    }

    isolated resource function delete alltypesifrecords/[boolean booleanType]/[int intType]/[float floatType]/[decimal decimalType]/[string stringType]() returns AllTypesIdRecord|Error {
        if !self.alltypesidrecords.hasKey([booleanType, intType, floatType, decimalType, stringType]) {
            return <InvalidKeyError>error("Not found: " + [booleanType, intType, floatType, decimalType, stringType].toString());
        }
        return self.alltypesidrecords.remove([booleanType, intType, floatType, decimalType, stringType]);
    }

    private isolated function queryAllTypes(string[] fields) returns stream<record{}, Error?> {
        return from record{} 'object in self.alltypes
            select filterRecord(
                {
                    ...'object
                }, fields);
    }

    public isolated function queryOneAllTypes(anydata key) returns record{}|InvalidKeyError {
        from record{} 'object in self.alltypes
            where self.persistClients.get(ALL_TYPES).getKey('object) == key
            do {
                return {
                    ...'object
                };
            };
        return <InvalidKeyError>error("Invalid key: " + key.toString());
    }

    private isolated function queryCompositeAssociationRecords(string[] fields) returns stream<record{}, Error?> {
        return from record{} 'object in self.compositeassociationrecords
            outer join var alltypesidrecord in self.alltypesidrecords
            on ['object.alltypesidrecordBooleanType, 'object.alltypesidrecordIntType, 'object.alltypesidrecordFloatType, 'object.alltypesidrecordDecimalType, 'object.alltypesidrecordStringType] 
            equals [alltypesidrecord?.booleanType, alltypesidrecord?.intType, alltypesidrecord?.floatType, alltypesidrecord?.decimalType, alltypesidrecord?.stringType] 
            select filterRecord(
                {
                    ...'object,
                    "allTypesIdRecord": alltypesidrecord
                }, fields);
    }

    private isolated function queryOneCompositeAssociationRecords(anydata key) returns record {}|InvalidKeyError {
        from record{} 'object in self.compositeassociationrecords
            where self.persistClients.get(COMPOSITE_ASSOCIATION_RECORD).getKey('object) == key
            outer join var alltypesidrecord in self.alltypesidrecords
            on ['object.alltypesidrecordBooleanType, 'object.alltypesidrecordIntType, 'object.alltypesidrecordFloatType, 'object.alltypesidrecordDecimalType, 'object.alltypesidrecordStringType] 
            equals [alltypesidrecord?.booleanType, alltypesidrecord?.intType, alltypesidrecord?.floatType, alltypesidrecord?.decimalType, alltypesidrecord?.stringType] 
            do {
                return {
                    ...'object,
                    "allTypesIdRecord": alltypesidrecord
                };
            };
        return <InvalidKeyError>error("Invalid key: " + key.toString());
    }

    private isolated function queryAllTypesIdRecords(string [] fields) returns stream<record{}, Error?> {
        return from record{} 'object in self.alltypesidrecords
            select filterRecord(
                {
                    ...'object
                }, fields);
    }

    private isolated function queryOneAllTypesIdRecords(anydata key) returns record {}|InvalidKeyError {
        from record{} 'object in self.alltypesidrecords
            where self.persistClients.get(ALL_TYPES_ID_RECORD).getKey('object) == key
            outer join var compositeassociationrecord in self.compositeassociationrecords
            on ['object.booleanType, 'object.intType, 'object.floatType, 'object.decimalType, 'object.stringType]
            equals [compositeassociationrecord?.alltypesidrecordBooleanType, compositeassociationrecord?.alltypesidrecordIntType, compositeassociationrecord?.alltypesidrecordFloatType, compositeassociationrecord?.alltypesidrecordDecimalType, compositeassociationrecord?.alltypesidrecordStringType]
            do {
                return {
                    ...'object,
                    "compositeAssociationRecord": compositeassociationrecord
                };
            };
        return <InvalidKeyError>error("Invalid key: " + key.toString());
    }



}

