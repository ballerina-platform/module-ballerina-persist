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

final isolated table<AllTypes> key(id) alltypesTable = table [];
final isolated table<StringIdRecord> key(id) stringidrecordsTable = table [];
final isolated table<IntIdRecord> key(id) intidrecordsTable = table [];
final isolated table<FloatIdRecord> key(id) floatidrecordsTable = table [];
final isolated table<DecimalIdRecord> key(id) decimalidrecordsTable = table [];
final isolated table<BooleanIdRecord> key(id) booleanidrecordsTable = table [];
final isolated table<CompositeAssociationRecord> key(id) compositeassociationrecordsTable = table [];
final isolated table<AllTypesIdRecord> key(booleanType, intType, floatType, decimalType, stringType) alltypesidrecordsTable = table [];

public isolated client class InMemoryTestEntitiesClient {
    *AbstractPersistClient;

    private final map<InMemoryClient> persistClients = {};

    public function init() returns Error? {

        final map<TableMetadata> metadata = {
            [ALL_TYPES] : {
                keyFields: ["id"],
                query: queryAllTypes,
                queryOne: queryOneAllTypes
            },
            [STRING_ID_RECORD] : {
                keyFields: ["id"],
                query: queryStringIdRecord,
                queryOne: queryOneStringIdRecord
            },
            [INT_ID_RECORD] : {
                keyFields: ["id"],
                query: queryIntIdRecord,
                queryOne: queryOneIntIdRecord
            },
            [FLOAT_ID_RECORD] : {
                keyFields: ["id"],
                query: queryFloatIdRecord,
                queryOne: queryOneFloatIdRecord
            },
            [DECIMAL_ID_RECORD] : {
                keyFields: ["id"],
                query: queryDecimalIdRecord,
                queryOne: queryOneDecimalIdRecord
            },
            [BOOLEAN_ID_RECORD] : {
                keyFields: ["id"],
                query: queryBooleanIdRecord,
                queryOne: queryOneBooleanIdRecord
            },
            [COMPOSITE_ASSOCIATION_RECORD] : {
                keyFields: ["id"],
                query: queryCompositeAssociationRecords,
                queryOne: queryOneCompositeAssociationRecords
            },
            [ALL_TYPES_ID_RECORD] : {
                keyFields: ["booleanType", "intType", "floatType", "decimalType", "stringType"],
                query: queryAllTypesIdRecords,
                queryOne: queryOneAllTypesIdRecords
            }
        };

        self.persistClients[ALL_TYPES] = check new (metadata.get(ALL_TYPES));
        self.persistClients[STRING_ID_RECORD] = check new (metadata.get(STRING_ID_RECORD));
        self.persistClients[INT_ID_RECORD] = check new (metadata.get(INT_ID_RECORD));
        self.persistClients[FLOAT_ID_RECORD] = check new (metadata.get(FLOAT_ID_RECORD));
        self.persistClients[DECIMAL_ID_RECORD] = check new (metadata.get(DECIMAL_ID_RECORD));
        self.persistClients[BOOLEAN_ID_RECORD] = check new (metadata.get(BOOLEAN_ID_RECORD));
        self.persistClients[COMPOSITE_ASSOCIATION_RECORD] = check new (metadata.get(COMPOSITE_ASSOCIATION_RECORD));
        self.persistClients[ALL_TYPES_ID_RECORD] = check new (metadata.get(ALL_TYPES_ID_RECORD));
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
            lock {
                if alltypesTable.hasKey(value.id) {
                    return <AlreadyExistsError>error("Duplicate key: " + value.id.toString());
                }
                alltypesTable.put(value.clone());
            }
            keys.push(value.id);
        }
        return keys;
    }

    isolated resource function put alltypes/[int id](AllTypesUpdate value) returns AllTypes|Error {
        lock {
            if !alltypesTable.hasKey(id) {
                return <NotFoundError>error("Not found: " + id.toString());
            }
            AllTypes alltypes = alltypesTable.get(id);
            foreach var [k, v] in value.clone().entries() {
                alltypes[k] = v;
            }

            alltypesTable.put(alltypes);
            return alltypes.clone();
        }
    }

    isolated resource function delete alltypes/[int id]() returns AllTypes|Error {
        lock {
            if !alltypesTable.hasKey(id) {
                return <NotFoundError>error("Not found: " + id.toString());
            }
            return alltypesTable.remove(id).clone();
        }
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
            lock {
                if stringidrecordsTable.hasKey(value.id) {
                    return <AlreadyExistsError>error("Duplicate key: " + value.id.toString());
                }
                stringidrecordsTable.put(value.clone());
            }
            keys.push(value.id);
        }
        return keys;
    }

    isolated resource function put stringidrecords/[string id](StringIdRecordUpdate value) returns StringIdRecord|Error {
        lock {
            if !stringidrecordsTable.hasKey(id) {
                return <NotFoundError>error("Not found: " + id.toString());
            }
            StringIdRecord stringidrecord = stringidrecordsTable.get(id);
            foreach var [k, v] in value.clone().entries() {
                stringidrecord[k] = v;
            }

            stringidrecordsTable.put(stringidrecord);
            return stringidrecord.clone();
        }
    }

    isolated resource function delete stringidrecords/[string id]() returns StringIdRecord|Error {
        lock {
            if !stringidrecordsTable.hasKey(id) {
                return <NotFoundError>error("Not found: " + id.toString());
            }
            return stringidrecordsTable.remove(id).clone();
        }
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
            lock {
                if intidrecordsTable.hasKey(value.id) {
                    return <AlreadyExistsError>error("Duplicate key: " + value.id.toString());
                }
                intidrecordsTable.put(value.clone());
            }
            keys.push(value.id);
        }
        return keys;
    }

    isolated resource function put intidrecords/[int id](IntIdRecordUpdate value) returns IntIdRecord|Error {
        lock {
            if !intidrecordsTable.hasKey(id) {
                return <NotFoundError>error("Not found: " + id.toString());
            }
            IntIdRecord intidrecord = intidrecordsTable.get(id);
            foreach var [k, v] in value.clone().entries() {
                intidrecord[k] = v;
            }

            intidrecordsTable.put(intidrecord);
            return intidrecord.clone();
        }
    }

    isolated resource function delete intidrecords/[int id]() returns IntIdRecord|Error {
        lock {
            if !intidrecordsTable.hasKey(id) {
                return <NotFoundError>error("Not found: " + id.toString());
            }
            return intidrecordsTable.remove(id).clone();
        }
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
            lock {
                if floatidrecordsTable.hasKey(value.id) {
                    return <AlreadyExistsError>error("Duplicate key: " + value.id.toString());
                }
                floatidrecordsTable.put(value.clone());
            }
            keys.push(value.id);
        }
        return keys;
    }

    isolated resource function put floatidrecords/[float id](FloatIdRecordUpdate value) returns FloatIdRecord|Error {
        lock {
            if !floatidrecordsTable.hasKey(id) {
                return <NotFoundError>error("Not found: " + id.toString());
            }
            FloatIdRecord floatidrecord = floatidrecordsTable.get(id);
            foreach var [k, v] in value.clone().entries() {
                floatidrecord[k] = v;
            }

            floatidrecordsTable.put(floatidrecord);
            return floatidrecord.clone();
        }
    }

    isolated resource function delete floatidrecords/[float id]() returns FloatIdRecord|Error {
        lock {
            if !floatidrecordsTable.hasKey(id) {
                return <NotFoundError>error("Not found: " + id.toString());
            }
            return floatidrecordsTable.remove(id).clone();
        }
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
            lock {
                if decimalidrecordsTable.hasKey(value.id) {
                    return <AlreadyExistsError>error("Duplicate key: " + value.id.toString());
                }
                decimalidrecordsTable.put(value.clone());
            }
            keys.push(value.id);
        }
        return keys;
    }

    isolated resource function put decimalidrecords/[decimal id](DecimalIdRecordUpdate value) returns DecimalIdRecord|Error {
        lock {
            if !decimalidrecordsTable.hasKey(id) {
                return <NotFoundError>error("Not found: " + id.toString());
            }
            DecimalIdRecord decimalidrecord = decimalidrecordsTable.get(id);
            foreach var [k, v] in value.clone().entries() {
                decimalidrecord[k] = v;
            }

            decimalidrecordsTable.put(decimalidrecord);
            return decimalidrecord.clone();
        }
    }

    isolated resource function delete decimalidrecords/[decimal id]() returns DecimalIdRecord|Error {
        lock {
            if !decimalidrecordsTable.hasKey(id) {
                return <NotFoundError>error("Not found: " + id.toString());
            }
            return decimalidrecordsTable.remove(id).clone();
        }
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
            lock {
                if booleanidrecordsTable.hasKey(value.id) {
                    return <AlreadyExistsError>error("Duplicate key: " + value.id.toString());
                }
                booleanidrecordsTable.put(value.clone());
            }
            keys.push(value.id);
        }
        return keys;
    }

    isolated resource function put booleanidrecords/[boolean id](BooleanIdRecordUpdate value) returns BooleanIdRecord|Error {
        lock {
            if !booleanidrecordsTable.hasKey(id) {
                return <NotFoundError>error("Not found: " + id.toString());
            }
            BooleanIdRecord booleanidrecord = booleanidrecordsTable.get(id);
            foreach var [k, v] in value.clone().entries() {
                booleanidrecord[k] = v;
            }

            booleanidrecordsTable.put(booleanidrecord);
            return booleanidrecord.clone();
        }
    }

    isolated resource function delete booleanidrecords/[boolean id]() returns BooleanIdRecord|Error {
        lock {
            if !booleanidrecordsTable.hasKey(id) {
                return <NotFoundError>error("Not found: " + id.toString());
            }
            return booleanidrecordsTable.remove(id).clone();
        }
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
            lock {
                if compositeassociationrecordsTable.hasKey(value.id) {
                    return <AlreadyExistsError>error("Duplicate key: " + value.id.toString());
                }
                compositeassociationrecordsTable.put(value.clone());
            }
            keys.push(value.id);
        }
        return keys;
    }

    isolated resource function put compositeassociationrecords/[string id](CompositeAssociationRecordUpdate value) returns CompositeAssociationRecord|Error {
        lock {
            if !compositeassociationrecordsTable.hasKey(id) {
                return <NotFoundError>error("Not found: " + id.toString());
            }
            CompositeAssociationRecord compositeassociationrecords = compositeassociationrecordsTable.get(id);
            foreach var [k, v] in value.clone().entries() {
                compositeassociationrecords[k] = v;
            }

            compositeassociationrecordsTable.put(compositeassociationrecords);
            return compositeassociationrecords.clone();
        }
    }

    isolated resource function delete compositeassociationrecords/[string id]() returns CompositeAssociationRecord|Error {
        lock {
            if !compositeassociationrecordsTable.hasKey(id) {
                return <NotFoundError>error("Not found: " + id.toString());
            }
            return compositeassociationrecordsTable.remove(id).clone();
        }
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
            lock {
                if alltypesidrecordsTable.hasKey([value.booleanType, value.intType, value.floatType, value.decimalType, value.stringType]) {
                    return <AlreadyExistsError>error("Duplicate key: " + [value.booleanType, value.intType, value.floatType, value.decimalType, value.stringType].toString());
                }
                alltypesidrecordsTable.put(value.clone());
            }
            keys.push([value.booleanType, value.intType, value.floatType, value.decimalType, value.stringType]);
        }
        return keys;
    }

    isolated resource function put alltypesidrecords/[boolean booleanType]/[int intType]/[float floatType]/[decimal decimalType]/[string stringType](AllTypesIdRecordUpdate value) returns AllTypesIdRecord|Error {
        lock {
            if !alltypesidrecordsTable.hasKey([booleanType, intType, floatType, decimalType, stringType]) {
                return <NotFoundError>error("Not found: " + [booleanType, intType, floatType, decimalType, stringType].toString());
            }
            AllTypesIdRecord alltypesidrecords = alltypesidrecordsTable.get([booleanType, intType, floatType, decimalType, stringType]);
            foreach var [k, v] in value.clone().entries() {
                alltypesidrecords[k] = v;
            }

            alltypesidrecordsTable.put(alltypesidrecords);
            return alltypesidrecords.clone();
        }
    }

    isolated resource function delete alltypesidrecords/[boolean booleanType]/[int intType]/[float floatType]/[decimal decimalType]/[string stringType]() returns AllTypesIdRecord|Error {
        lock {
            if !alltypesidrecordsTable.hasKey([booleanType, intType, floatType, decimalType, stringType]) {
                return <NotFoundError>error("Not found: " + [booleanType, intType, floatType, decimalType, stringType].toString());
            }
            return alltypesidrecordsTable.remove([booleanType, intType, floatType, decimalType, stringType]).clone();
        }
    }

    public function close() returns Error? {
        return ();
    }
}

isolated function queryAllTypes(string[] fields) returns stream<record {}, Error?> {
    table<AllTypes> key(id) alltypesClonedTable;
    lock {
        alltypesClonedTable = alltypesTable.clone();
    }

    return from record {} 'object in alltypesClonedTable
        select filterRecord(
                {
            ...'object
        }, fields);
}

isolated function queryOneAllTypes(anydata key) returns record {}|NotFoundError {
    table<AllTypes> key(id) alltypesClonedTable;
    lock {
        alltypesClonedTable = alltypesTable.clone();
    }

    from record {} 'object in alltypesClonedTable
    where getKey('object, ["id"]) == key
    do {
        return {
            ...'object
        };
    };
    return <NotFoundError>error("Invalid key: " + key.toString());
}

isolated function queryStringIdRecord(string[] fields) returns stream<record {}, Error?> {
    table<StringIdRecord> key(id) stringidrecordsClonedTable;
    lock {
        stringidrecordsClonedTable = stringidrecordsTable.clone();
    }

    return from record {} 'object in stringidrecordsClonedTable
        select filterRecord(
                {
            ...'object
        }, fields);
}

isolated function queryOneStringIdRecord(anydata key) returns record {}|NotFoundError {
    table<StringIdRecord> key(id) stringidrecordsClonedTable;
    lock {
        stringidrecordsClonedTable = stringidrecordsTable.clone();
    }

    from record {} 'object in stringidrecordsClonedTable
    where getKey('object, ["id"]) == key
    do {
        return {
            ...'object
        };
    };
    return <NotFoundError>error("Invalid key: " + key.toString());
}

isolated function queryIntIdRecord(string[] fields) returns stream<record {}, Error?> {
    table<IntIdRecord> key(id) intidrecordsClonedTable;
    lock {
        intidrecordsClonedTable = intidrecordsTable.clone();
    }

    return from record {} 'object in intidrecordsClonedTable
        select filterRecord(
                {
            ...'object
        }, fields);
}

isolated function queryOneIntIdRecord(anydata key) returns record {}|NotFoundError {
    table<IntIdRecord> key(id) intidrecordsClonedTable;
    lock {
        intidrecordsClonedTable = intidrecordsTable.clone();
    }

    from record {} 'object in intidrecordsClonedTable
    where getKey('object, ["id"]) == key
    do {
        return {
            ...'object
        };
    };
    return <NotFoundError>error("Invalid key: " + key.toString());
}

isolated function queryFloatIdRecord(string[] fields) returns stream<record {}, Error?> {
    table<FloatIdRecord> key(id) floatidrecordsClonedTable;
    lock {
        floatidrecordsClonedTable = floatidrecordsTable.clone();
    }

    return from record {} 'object in floatidrecordsClonedTable
        select filterRecord(
                {
            ...'object
        }, fields);
}

isolated function queryOneFloatIdRecord(anydata key) returns record {}|NotFoundError {
    table<FloatIdRecord> key(id) floatidrecordsClonedTable;
    lock {
        floatidrecordsClonedTable = floatidrecordsTable.clone();
    }

    from record {} 'object in floatidrecordsClonedTable
    where getKey('object, ["id"]) == key
    do {
        return {
            ...'object
        };
    };
    return <NotFoundError>error("Invalid key: " + key.toString());
}

isolated function queryDecimalIdRecord(string[] fields) returns stream<record {}, Error?> {
    table<DecimalIdRecord> key(id) decimalidrecordsClonedTable;
    lock {
        decimalidrecordsClonedTable = decimalidrecordsTable.clone();
    }

    return from record {} 'object in decimalidrecordsClonedTable
        select filterRecord(
                {
            ...'object
        }, fields);
}

isolated function queryOneDecimalIdRecord(anydata key) returns record {}|NotFoundError {
    table<DecimalIdRecord> key(id) decimalidrecordsClonedTable;
    lock {
        decimalidrecordsClonedTable = decimalidrecordsTable.clone();
    }

    from record {} 'object in decimalidrecordsClonedTable
    where getKey('object, ["id"]) == key
    do {
        return {
            ...'object
        };
    };
    return <NotFoundError>error("Invalid key: " + key.toString());
}

isolated function queryBooleanIdRecord(string[] fields) returns stream<record {}, Error?> {
    table<BooleanIdRecord> key(id) booleanidrecordsClonedTable;
    lock {
        booleanidrecordsClonedTable = booleanidrecordsTable.clone();
    }

    return from record {} 'object in booleanidrecordsClonedTable
        select filterRecord(
                {
            ...'object
        }, fields);
}

isolated function queryOneBooleanIdRecord(anydata key) returns record {}|NotFoundError {
    table<BooleanIdRecord> key(id) booleanidrecordsClonedTable;
    lock {
        booleanidrecordsClonedTable = booleanidrecordsTable.clone();
    }

    from record {} 'object in booleanidrecordsClonedTable
    where getKey('object, ["id"]) == key
    do {
        return {
            ...'object
        };
    };
    return <NotFoundError>error("Invalid key: " + key.toString());
}

isolated function queryCompositeAssociationRecords(string[] fields) returns stream<record {}, Error?> {
    table<CompositeAssociationRecord> key(id) compositeassociationrecordsClonedTable;
    table<AllTypesIdRecord> key(booleanType, intType, floatType, decimalType, stringType) alltypesidrecordsClonedTable;
    lock {
        compositeassociationrecordsClonedTable = compositeassociationrecordsTable.clone();
    }
    lock {
        alltypesidrecordsClonedTable = alltypesidrecordsTable.clone();
    }

    return from record {} 'object in compositeassociationrecordsClonedTable
        outer join var alltypesidrecord in alltypesidrecordsClonedTable
            on ['object.alltypesidrecordBooleanType, 'object.alltypesidrecordIntType, 'object.alltypesidrecordFloatType, 'object.alltypesidrecordDecimalType, 'object.alltypesidrecordStringType]
            equals [alltypesidrecord?.booleanType, alltypesidrecord?.intType, alltypesidrecord?.floatType, alltypesidrecord?.decimalType, alltypesidrecord?.stringType]
        select filterRecord(
                {
            ...'object,
            "allTypesIdRecord": alltypesidrecord
        }, fields);
}

isolated function queryOneCompositeAssociationRecords(anydata key) returns record {}|NotFoundError {
    table<CompositeAssociationRecord> key(id) compositeassociationrecordsClonedTable;
    table<AllTypesIdRecord> key(booleanType, intType, floatType, decimalType, stringType) alltypesidrecordsClonedTable;
    lock {
        compositeassociationrecordsClonedTable = compositeassociationrecordsTable.clone();
    }
    lock {
        alltypesidrecordsClonedTable = alltypesidrecordsTable.clone();
    }

    from record {} 'object in compositeassociationrecordsClonedTable
    where getKey('object, ["id"]) == key
    outer join var alltypesidrecord in alltypesidrecordsClonedTable
            on ['object.alltypesidrecordBooleanType, 'object.alltypesidrecordIntType, 'object.alltypesidrecordFloatType, 'object.alltypesidrecordDecimalType, 'object.alltypesidrecordStringType]
            equals [alltypesidrecord?.booleanType, alltypesidrecord?.intType, alltypesidrecord?.floatType, alltypesidrecord?.decimalType, alltypesidrecord?.stringType]
    do {
        return {
            ...'object,
            "allTypesIdRecord": alltypesidrecord
        };
    };
    return <NotFoundError>error("Invalid key: " + key.toString());
}

isolated function queryAllTypesIdRecords(string[] fields) returns stream<record {}, Error?> {
    table<AllTypesIdRecord> key(booleanType, intType, floatType, decimalType, stringType) alltypesidrecordsClonedTable;
    lock {
        alltypesidrecordsClonedTable = alltypesidrecordsTable.clone();
    }

    return from record {} 'object in alltypesidrecordsClonedTable
        select filterRecord(
                {
            ...'object
        }, fields);
}

isolated function queryOneAllTypesIdRecords(anydata key) returns record {}|NotFoundError {
    table<AllTypesIdRecord> key(booleanType, intType, floatType, decimalType, stringType) alltypesidrecordsClonedTable;
    table<CompositeAssociationRecord> key(id) compositeassociationrecordsClonedTable;
    lock {
        alltypesidrecordsClonedTable = alltypesidrecordsTable.clone();
    }
    lock {
        compositeassociationrecordsClonedTable = compositeassociationrecordsTable.clone();
    }

    from record {} 'object in alltypesidrecordsClonedTable
    where getKey('object, ["booleanType", "intType", "floatType", "decimalType", "stringType"]) == key
    outer join var compositeassociationrecord in compositeassociationrecordsClonedTable
            on ['object.booleanType, 'object.intType, 'object.floatType, 'object.decimalType, 'object.stringType]
            equals [compositeassociationrecord?.alltypesidrecordBooleanType, compositeassociationrecord?.alltypesidrecordIntType, compositeassociationrecord?.alltypesidrecordFloatType, compositeassociationrecord?.alltypesidrecordDecimalType, compositeassociationrecord?.alltypesidrecordStringType]
    do {
        return {
            ...'object,
            "compositeAssociationRecord": compositeassociationrecord
        };
    };
    return <NotFoundError>error("Invalid key: " + key.toString());
}

