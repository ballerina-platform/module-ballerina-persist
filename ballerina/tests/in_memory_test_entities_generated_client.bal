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
const STRING_ID_RECORD = "stringidrecords";
const INT_ID_RECORD = "intidrecords";
const FLOAT_ID_RECORD = "floatidrecords";
const DECIMAL_ID_RECORD = "decimalidrecords";
const BOOLEAN_ID_RECORD = "booleanidrecords";
const COMPOSITE_ASSOCIATION_RECORD = "compositeassociationrecords";
const ALL_TYPES_ID_RECORD = "alltypesidrecords";

table<AllTypes> key(id) alltypes = table[];
table<StringIdRecord> key(id) stringidrecords = table[];
table<IntIdRecord> key(id) intidrecords = table[];
table<FloatIdRecord> key(id) floatidrecords = table[];
table<DecimalIdRecord> key(id) decimalidrecords = table[];
table<BooleanIdRecord> key(id) booleanidrecords = table[];
table<CompositeAssociationRecord> key(id) compositeassociationrecords = table[];
table<AllTypesIdRecord> key(booleanType, intType, floatType, decimalType, stringType) alltypesidrecords = table[];

public client class InMemoryTestEntitiesClient {
    *AbstractPersistClient;

    private final map<InMemoryClient> persistClients;

    table<AllTypes> key(id) alltypes = alltypes;
    table<StringIdRecord> key(id) stringidrecords = stringidrecords;
    table<IntIdRecord> key(id) intidrecords = intidrecords;
    table<FloatIdRecord> key(id) floatidrecords = floatidrecords;
    table<DecimalIdRecord> key(id) decimalidrecords = decimalidrecords;
    table<BooleanIdRecord> key(id) booleanidrecords = booleanidrecords;
    table<CompositeAssociationRecord> key(id) compositeassociationrecords = compositeassociationrecords;
    table<AllTypesIdRecord> key(booleanType, intType, floatType, decimalType, stringType) alltypesidrecords = alltypesidrecords;

    public function init() returns Error? {

        final map<TableMetadata> metadata = {
            [ALL_TYPES]: {
                keyFields: ["id"],
                query: self.queryAllTypes,
                queryOne: self.queryOneAllTypes   
            },
            [STRING_ID_RECORD]: {
                keyFields: ["id"],
                query: self.queryStringIdRecord,
                queryOne: self.queryOneStringIdRecord
            },
            [INT_ID_RECORD]: {
                keyFields: ["id"],
                query: self.queryIntIdRecord,
                queryOne: self.queryOneIntIdRecord
            },
            [FLOAT_ID_RECORD]: {
                keyFields: ["id"],
                query: self.queryFloatIdRecord,
                queryOne: self.queryOneFloatIdRecord
            },
            [DECIMAL_ID_RECORD]: {
                keyFields: ["id"],
                query: self.queryDecimalIdRecord,
                queryOne: self.queryOneDecimalIdRecord
            },
            [BOOLEAN_ID_RECORD]: {
                keyFields: ["id"],
                query: self.queryBooleanIdRecord,
                queryOne: self.queryOneBooleanIdRecord
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
            [STRING_ID_RECORD]: check new (metadata.get(STRING_ID_RECORD)),
            [INT_ID_RECORD]: check new (metadata.get(INT_ID_RECORD)),
            [FLOAT_ID_RECORD]: check new (metadata.get(FLOAT_ID_RECORD)),
            [DECIMAL_ID_RECORD]: check new (metadata.get(DECIMAL_ID_RECORD)),
            [BOOLEAN_ID_RECORD]: check new (metadata.get(BOOLEAN_ID_RECORD)),
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
                return <DuplicateKeyError>error("Duplicate key: " + value.id.toString()); 
            }
            self.alltypes.put(value.clone());
            keys.push(value.id);
        }
        return keys;
    }

    isolated resource function put alltypes/[int id](AllTypesUpdate value) returns AllTypes|Error {
        if !self.alltypes.hasKey(id) {
            return <InvalidKeyError>error("Not found: " + id.toString());
        }
        AllTypes alltypes = self.alltypes.get(id);
        foreach var [k, v] in value.entries() {
            alltypes[k] = v;
        }

        self.alltypes.put(alltypes);
        return alltypes;
    }

    isolated resource function delete alltypes/[int id]() returns AllTypes|Error {
        if !self.alltypes.hasKey(id) {
            return <InvalidKeyError>error("Not found: " + id.toString());
        }
        return self.alltypes.remove(id);
    }

    isolated resource function get stringidrecords(StringIdRecordTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "query"
    } external;

    isolated resource function get stringidrecords/[string id](StringIdRecordTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "queryOne"
    } external;

    isolated resource function post stringidrecords(StringIdRecordInsert[] data) returns string[]|Error {
        string[] keys = [];
        foreach StringIdRecordInsert value in data {
            if self.stringidrecords.hasKey(value.id) {
                return <DuplicateKeyError>error("Duplicate key: " + value.id.toString()); 
            }
            self.stringidrecords.put(value.clone());
            keys.push(value.id);
        }
        return keys;
    }

    isolated resource function put stringidrecords/[string id](StringIdRecordUpdate value) returns StringIdRecord|Error {
        if !self.stringidrecords.hasKey(id) {
            return <InvalidKeyError>error("Not found: " + id.toString());
        }
        StringIdRecord stringidrecord = self.stringidrecords.get(id);
        foreach var [k, v] in value.entries() {
            stringidrecord[k] = v;
        }

        self.stringidrecords.put(stringidrecord);
        return stringidrecord;
    }

    isolated resource function delete stringidrecords/[string id]() returns StringIdRecord|Error {
        if !self.stringidrecords.hasKey(id) {
            return <InvalidKeyError>error("Not found: " + id.toString());
        }
        return self.stringidrecords.remove(id);
    }

    isolated resource function get intidrecords(IntIdRecordTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "query"
    } external;

    isolated resource function get intidrecords/[int id](IntIdRecordTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "queryOne"
    } external;

    isolated resource function post intidrecords(IntIdRecordInsert[] data) returns int[]|Error {
        int[] keys = [];
        foreach IntIdRecordInsert value in data {
            if self.intidrecords.hasKey(value.id) {
                return <DuplicateKeyError>error("Duplicate key: " + value.id.toString()); 
            }
            self.intidrecords.put(value.clone());
            keys.push(value.id);
        }
        return keys;
    }

    isolated resource function put intidrecords/[int id](IntIdRecordUpdate value) returns IntIdRecord|Error {
        if !self.intidrecords.hasKey(id) {
            return <InvalidKeyError>error("Not found: " + id.toString());
        }
        IntIdRecord intidrecord = self.intidrecords.get(id);
        foreach var [k, v] in value.entries() {
            intidrecord[k] = v;
        }

        self.intidrecords.put(intidrecord);
        return intidrecord;
    }

    isolated resource function delete intidrecords/[int id]() returns IntIdRecord|Error {
        if !self.intidrecords.hasKey(id) {
            return <InvalidKeyError>error("Not found: " + id.toString());
        }
        return self.intidrecords.remove(id);
    }

    isolated resource function get floatidrecords(FloatIdRecordTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "query"
    } external;

    isolated resource function get floatidrecords/[float id](FloatIdRecordTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "queryOne"
    } external;

    isolated resource function post floatidrecords(FloatIdRecordInsert[] data) returns float[]|Error {
        float[] keys = [];
        foreach FloatIdRecordInsert value in data {
            if self.floatidrecords.hasKey(value.id) {
                return <DuplicateKeyError>error("Duplicate key: " + value.id.toString()); 
            }
            self.floatidrecords.put(value.clone());
            keys.push(value.id);
        }
        return keys;
    }

    isolated resource function put floatidrecords/[float id](FloatIdRecordUpdate value) returns FloatIdRecord|Error {
        if !self.floatidrecords.hasKey(id) {
            return <InvalidKeyError>error("Not found: " + id.toString());
        }
        FloatIdRecord floatidrecord = self.floatidrecords.get(id);
        foreach var [k, v] in value.entries() {
            floatidrecord[k] = v;
        }

        self.floatidrecords.put(floatidrecord);
        return floatidrecord;
    }

    isolated resource function delete floatidrecords/[float id]() returns FloatIdRecord|Error {
        if !self.floatidrecords.hasKey(id) {
            return <InvalidKeyError>error("Not found: " + id.toString());
        }
        return self.floatidrecords.remove(id);
    }

    isolated resource function get decimalidrecords(DecimalIdRecordTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "query"
    } external;

    isolated resource function get decimalidrecords/[decimal id](DecimalIdRecordTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "queryOne"
    } external;

    isolated resource function post decimalidrecords(DecimalIdRecordInsert[] data) returns decimal[]|Error {
        decimal[] keys = [];
        foreach DecimalIdRecordInsert value in data {
            if self.decimalidrecords.hasKey(value.id) {
                return <DuplicateKeyError>error("Duplicate key: " + value.id.toString()); 
            }
            self.decimalidrecords.put(value.clone());
            keys.push(value.id);
        }
        return keys;
    }

    isolated resource function put decimalidrecords/[decimal id](DecimalIdRecordUpdate value) returns DecimalIdRecord|Error {
        if !self.decimalidrecords.hasKey(id) {
            return <InvalidKeyError>error("Not found: " + id.toString());
        }
        DecimalIdRecord decimalidrecord = self.decimalidrecords.get(id);
        foreach var [k, v] in value.entries() {
            decimalidrecord[k] = v;
        }

        self.decimalidrecords.put(decimalidrecord);
        return decimalidrecord;
    }

    isolated resource function delete decimalidrecords/[decimal id]() returns DecimalIdRecord|Error {
        if !self.decimalidrecords.hasKey(id) {
            return <InvalidKeyError>error("Not found: " + id.toString());
        }
        return self.decimalidrecords.remove(id);
    }

    isolated resource function get booleanidrecords(BooleanIdRecordTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "query"
    } external;

    isolated resource function get booleanidrecords/[boolean id](BooleanIdRecordTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "queryOne"
    } external;

    isolated resource function post booleanidrecords(BooleanIdRecordInsert[] data) returns boolean[]|Error {
        boolean[] keys = [];
        foreach BooleanIdRecordInsert value in data {
            if self.booleanidrecords.hasKey(value.id) {
                return <DuplicateKeyError>error("Duplicate key: " + value.id.toString()); 
            }
            self.booleanidrecords.put(value.clone());
            keys.push(value.id);
        }
        return keys;
    }

    isolated resource function put booleanidrecords/[boolean id](BooleanIdRecordUpdate value) returns BooleanIdRecord|Error {
        if !self.booleanidrecords.hasKey(id) {
            return <InvalidKeyError>error("Not found: " + id.toString());
        }
        BooleanIdRecord booleanidrecord = self.booleanidrecords.get(id);
        foreach var [k, v] in value.entries() {
            booleanidrecord[k] = v;
        }

        self.booleanidrecords.put(booleanidrecord);
        return booleanidrecord;
    }

    isolated resource function delete booleanidrecords/[boolean id]() returns BooleanIdRecord|Error {
        if !self.booleanidrecords.hasKey(id) {
            return <InvalidKeyError>error("Not found: " + id.toString());
        }
        return self.booleanidrecords.remove(id);
    }

    isolated resource function get compositeassociationrecords(CompositeAssociationRecordTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "query"
    } external;

    isolated resource function get compositeassociationrecords/[string id](CompositeAssociationRecordTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "queryOne"
    } external;

    isolated resource function post compositeassociationrecords(CompositeAssociationRecordInsert[] data) returns string[]|Error {
        string[] keys = [];
        foreach CompositeAssociationRecordInsert value in data {
            if self.compositeassociationrecords.hasKey(value.id) {
                return <DuplicateKeyError>error("Duplicate key: " + value.id.toString());
            }
            self.compositeassociationrecords.put(value.clone());
            keys.push(value.id);
        }
        return keys;
    }

    isolated resource function put compositeassociationrecords/[string id](CompositeAssociationRecordUpdate value) returns CompositeAssociationRecord|Error {
        if !self.compositeassociationrecords.hasKey(id) {
            return <InvalidKeyError>error("Not found: " + id.toString());
        }
        CompositeAssociationRecord compositeassociationrecords = self.compositeassociationrecords.get(id);
        foreach var [k, v] in value.entries() {
            compositeassociationrecords[k] = v;
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
            self.alltypesidrecords.put(value.clone());
            keys.push([value.booleanType, value.intType, value.floatType, value.decimalType, value.stringType]);
        }
        return keys;
    }

    isolated resource function put alltypesidrecords/[boolean booleanType]/[int intType]/[float floatType]/[decimal decimalType]/[string stringType](AllTypesIdRecordUpdate value) returns AllTypesIdRecord|Error {
        if !self.alltypesidrecords.hasKey([booleanType, intType, floatType, decimalType, stringType]) {
            return <InvalidKeyError>error("Not found: " + [booleanType, intType, floatType, decimalType, stringType].toString());
        }
        AllTypesIdRecord alltypesidrecords = self.alltypesidrecords.get([booleanType, intType, floatType, decimalType, stringType]);
        foreach var [k, v] in value.entries() {
            alltypesidrecords[k] = v;
        }

        self.alltypesidrecords.put(alltypesidrecords);
        return alltypesidrecords;
    }

    isolated resource function delete alltypesidrecords/[boolean booleanType]/[int intType]/[float floatType]/[decimal decimalType]/[string stringType]() returns AllTypesIdRecord|Error {
        if !self.alltypesidrecords.hasKey([booleanType, intType, floatType, decimalType, stringType]) {
            return <InvalidKeyError>error("Not found: " + [booleanType, intType, floatType, decimalType, stringType].toString());
        }
        return self.alltypesidrecords.remove([booleanType, intType, floatType, decimalType, stringType]);
    }

    public function close() returns Error? {
        return ();
    }

    private isolated function queryAllTypes(string[] fields) returns stream<record{}, Error?> {
        return from record{} 'object in self.alltypes
            select filterRecord(
                {
                    ...'object
                }, fields);
    }

    private isolated function queryOneAllTypes(anydata key) returns record{}|InvalidKeyError {
        from record{} 'object in self.alltypes
            where self.persistClients.get(ALL_TYPES).getKey('object) == key
            do {
                return {
                    ...'object
                };
            };
        return <InvalidKeyError>error("Invalid key: " + key.toString());
    }

    private isolated function queryStringIdRecord(string[] fields) returns stream<record{}, Error?> {
        return from record{} 'object in self.stringidrecords
            select filterRecord(
                {
                    ...'object
                }, fields);
    }

    private isolated function queryOneStringIdRecord(anydata key) returns record{}|InvalidKeyError {
        from record{} 'object in self.stringidrecords
            where self.persistClients.get(STRING_ID_RECORD).getKey('object) == key
            do {
                return {
                    ...'object
                };
            };
        return <InvalidKeyError>error("Invalid key: " + key.toString());
    }

    private isolated function queryIntIdRecord(string[] fields) returns stream<record{}, Error?> {
        return from record{} 'object in self.intidrecords
            select filterRecord(
                {
                    ...'object
                }, fields);
    }

    private isolated function queryOneIntIdRecord(anydata key) returns record{}|InvalidKeyError {
        from record{} 'object in self.intidrecords
            where self.persistClients.get(INT_ID_RECORD).getKey('object) == key
            do {
                return {
                    ...'object
                };
            };
        return <InvalidKeyError>error("Invalid key: " + key.toString());
    }

    private isolated function queryFloatIdRecord(string[] fields) returns stream<record{}, Error?> {
        return from record{} 'object in self.floatidrecords
            select filterRecord(
                {
                    ...'object
                }, fields);
    }

    private isolated function queryOneFloatIdRecord(anydata key) returns record{}|InvalidKeyError {
        from record{} 'object in self.floatidrecords
            where self.persistClients.get(FLOAT_ID_RECORD).getKey('object) == key
            do {
                return {
                    ...'object
                };
            };
        return <InvalidKeyError>error("Invalid key: " + key.toString());
    }

    private isolated function queryDecimalIdRecord(string[] fields) returns stream<record{}, Error?> {
        return from record{} 'object in self.decimalidrecords
            select filterRecord(
                {
                    ...'object
                }, fields);
    }

    private isolated function queryOneDecimalIdRecord(anydata key) returns record{}|InvalidKeyError {
        from record{} 'object in self.decimalidrecords
            where self.persistClients.get(DECIMAL_ID_RECORD).getKey('object) == key
            do {
                return {
                    ...'object
                };
            };
        return <InvalidKeyError>error("Invalid key: " + key.toString());
    }

    private isolated function queryBooleanIdRecord(string[] fields) returns stream<record{}, Error?> {
        return from record{} 'object in self.booleanidrecords
            select filterRecord(
                {
                    ...'object
                }, fields);
    }

    private isolated function queryOneBooleanIdRecord(anydata key) returns record{}|InvalidKeyError {
        from record{} 'object in self.booleanidrecords
            where self.persistClients.get(BOOLEAN_ID_RECORD).getKey('object) == key
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

