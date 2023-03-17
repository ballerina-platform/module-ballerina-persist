import ballerinax/mysql;
import ballerina/jballerina.java;

const ALL_TYPES = "alltypes";
const STRING_ID_RECORD = "stringidrecord";
const INT_ID_RECORD = "intidrecord";
const FLOAT_ID_RECORD = "floatidrecord";
const DECIMAL_ID_RECORD = "decimalidrecord";
const BOOLEAN_ID_RECORD = "booleanidrecord";
const COMPOSITE_ASSOCIATION_RECORD = "compositeassociationrecord";
const ALL_TYPES_ID_RECORD = "alltypesidrecord";

public client class TestEntitiesClient {
    *AbstractPersistClient;

    private final mysql:Client dbClient;

    private final map<SQLClient> persistClients;

    private final record {|Metadata...;|} metadata = {
        "alltypes": {
            entityName: "AllTypes",
            tableName: `AllTypes`,
            fieldMetadata: {
                id: {columnName: "id"},
                booleanType: {columnName: "booleanType"},
                intType: {columnName: "intType"},
                floatType: {columnName: "floatType"},
                decimalType: {columnName: "decimalType"},
                stringType: {columnName: "stringType"},
                byteArrayType: {columnName: "byteArrayType"},
                dateType: {columnName: "dateType"},
                timeOfDayType: {columnName: "timeOfDayType"},
                civilType: {columnName: "civilType"},
                booleanTypeOptional: {columnName: "booleanTypeOptional"},
                intTypeOptional: {columnName: "intTypeOptional"},
                floatTypeOptional: {columnName: "floatTypeOptional"},
                decimalTypeOptional: {columnName: "decimalTypeOptional"},
                stringTypeOptional: {columnName: "stringTypeOptional"},
                dateTypeOptional: {columnName: "dateTypeOptional"},
                timeOfDayTypeOptional: {columnName: "timeOfDayTypeOptional"},
                civilTypeOptional: {columnName: "civilTypeOptional"}
            },
            keyFields: ["id"]
        },
        "stringidrecord": {
            entityName: "StringIdRecord",
            tableName: `StringIdRecord`,
            fieldMetadata: {
                id: {columnName: "id"},
                randomField: {columnName: "randomField"}
            },
            keyFields: ["id"]
        },
        "intidrecord": {
            entityName: "IntIdRecord",
            tableName: `IntIdRecord`,
            fieldMetadata: {
                id: {columnName: "id"},
                randomField: {columnName: "randomField"}
            },
            keyFields: ["id"]
        },
        "floatidrecord": {
            entityName: "FloatIdRecord",
            tableName: `FloatIdRecord`,
            fieldMetadata: {
                id: {columnName: "id"},
                randomField: {columnName: "randomField"}
            },
            keyFields: ["id"]
        },
        "decimalidrecord": {
            entityName: "DecimalIdRecord",
            tableName: `DecimalIdRecord`,
            fieldMetadata: {
                id: {columnName: "id"},
                randomField: {columnName: "randomField"}
            },
            keyFields: ["id"]
        },
        "booleanidrecord": {
            entityName: "BooleanIdRecord",
            tableName: `BooleanIdRecord`,
            fieldMetadata: {
                id: {columnName: "id"},
                randomField: {columnName: "randomField"}
            },
            keyFields: ["id"]
        },
        "compositeassociationrecord": {
            entityName: "CompositeAssociationRecord",
            tableName: `CompositeAssociationRecord`,
            fieldMetadata: {
                id: {columnName: "id"},
                randomField: {columnName: "randomField"},
                alltypesidrecordBooleanType: {columnName: "alltypesidrecordBooleanType"},
                alltypesidrecordIntType: {columnName: "alltypesidrecordIntType"},
                alltypesidrecordFloatType: {columnName: "alltypesidrecordFloatType"},
                alltypesidrecordDecimalType: {columnName: "alltypesidrecordDecimalType"},
                alltypesidrecordStringType: {columnName: "alltypesidrecordStringType"}
            },
            keyFields: ["id"],
            joinMetadata: {
                alltypesidrecord: {entity: AllTypesIdRecord, fieldName: "alltypesidrecord", refTable: "AllTypesIdRecord", refColumns: ["booleanType", "intType", "floatType", "decimalType", "stringType"], joinColumns: ["alltypesidrecordBooleanType", "alltypesidrecordIntType", "alltypesidrecordFloatType", "alltypesidrecordDecimalType", "alltypesidrecordStringType"], 'type: ONE_TO_ONE}
            }
        },
        "alltypesidrecord": {
            entityName: "AllTypesIdRecord",
            tableName: `AllTypesIdRecord`,
            fieldMetadata: {
                booleanType: {columnName: "booleanType"},
                intType: {columnName: "intType"},
                floatType: {columnName: "floatType"},
                decimalType: {columnName: "decimalType"},
                stringType: {columnName: "stringType"},
                randomField: {columnName: "randomField"}
            },
            keyFields: ["booleanType", "intType", "floatType", "decimalType", "stringType"],
            joinMetadata: {
                compositeassociationrecord: {entity: CompositeAssociationRecord, fieldName: "compositeassociationrecord", refTable: "CompositeAssociationRecord", refColumns: ["alltypesidrecordBooleanType", "alltypesidrecordIntType", "alltypesidrecordFloatType", "alltypesidrecordDecimalType", "alltypesidrecordStringType"], joinColumns: ["booleanType", "intType", "floatType", "decimalType", "stringType"], 'type: ONE_TO_ONE}
            }
        }
    };

    public function init() returns Error? {
        mysql:Client|error dbClient = new (host = host, user = user, password = password, database = database, port = port);
        if dbClient is error {
            return <Error>error(dbClient.message());
        }
        self.dbClient = dbClient;
        self.persistClients = {
            alltypes: check new (self.dbClient, self.metadata.get(ALL_TYPES)),
            stringidrecord: check new (self.dbClient, self.metadata.get(STRING_ID_RECORD)),
            intidrecord: check new (self.dbClient, self.metadata.get(INT_ID_RECORD)),
            floatidrecord: check new (self.dbClient, self.metadata.get(FLOAT_ID_RECORD)),
            decimalidrecord: check new (self.dbClient, self.metadata.get(DECIMAL_ID_RECORD)),
            booleanidrecord: check new (self.dbClient, self.metadata.get(BOOLEAN_ID_RECORD)),
            compositeassociationrecord: check new (self.dbClient, self.metadata.get(COMPOSITE_ASSOCIATION_RECORD)),
            alltypesidrecord: check new (self.dbClient, self.metadata.get(ALL_TYPES_ID_RECORD))
        };
    }

    isolated resource function get alltypes(AllTypesTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get alltypes/[int id](AllTypesTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "queryOne",
        paramTypes: ["io.ballerina.runtime.api.Environment", "io.ballerina.runtime.api.values.BObject", "io.ballerina.runtime.api.values.BArray", "io.ballerina.runtime.api.values.BTypedesc"]
    } external;

    isolated resource function post alltypes(AllTypesInsert[] data) returns int[]|Error {
        _ = check self.persistClients.get(ALL_TYPES).runBatchInsertQuery(data);
        return from AllTypesInsert inserted in data
            select inserted.id;
    }

    isolated resource function put alltypes/[int id](AllTypesUpdate value) returns AllTypes|Error {
        _ = check self.persistClients.get(ALL_TYPES).runUpdateQuery(id, value);
        return self->/alltypes/[id].get();
    }

    isolated resource function delete alltypes/[int id]() returns AllTypes|Error {
        AllTypes result = check self->/alltypes/[id].get();
        _ = check self.persistClients.get(ALL_TYPES).runDeleteQuery(id);
        return result;
    }

    isolated resource function get stringidrecord(StringIdRecordTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get stringidrecord/[string id](StringIdRecordTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "queryOne",
        paramTypes: ["io.ballerina.runtime.api.Environment", "io.ballerina.runtime.api.values.BObject", "io.ballerina.runtime.api.values.BArray", "io.ballerina.runtime.api.values.BTypedesc"]
    } external;

    isolated resource function post stringidrecord(StringIdRecordInsert[] data) returns string[]|Error {
        _ = check self.persistClients.get(STRING_ID_RECORD).runBatchInsertQuery(data);
        return from StringIdRecordInsert inserted in data
            select inserted.id;
    }

    isolated resource function put stringidrecord/[string id](StringIdRecordUpdate value) returns StringIdRecord|Error {
        _ = check self.persistClients.get(STRING_ID_RECORD).runUpdateQuery(id, value);
        return self->/stringidrecord/[id].get();
    }

    isolated resource function delete stringidrecord/[string id]() returns StringIdRecord|Error {
        StringIdRecord result = check self->/stringidrecord/[id].get();
        _ = check self.persistClients.get(STRING_ID_RECORD).runDeleteQuery(id);
        return result;
    }

    isolated resource function get intidrecord(IntIdRecordTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get intidrecord/[int id](IntIdRecordTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "queryOne",
        paramTypes: ["io.ballerina.runtime.api.Environment", "io.ballerina.runtime.api.values.BObject", "io.ballerina.runtime.api.values.BArray", "io.ballerina.runtime.api.values.BTypedesc"]
    } external;

    isolated resource function post intidrecord(IntIdRecordInsert[] data) returns int[]|Error {
        _ = check self.persistClients.get(INT_ID_RECORD).runBatchInsertQuery(data);
        return from IntIdRecordInsert inserted in data
            select inserted.id;
    }

    isolated resource function put intidrecord/[int id](IntIdRecordUpdate value) returns IntIdRecord|Error {
        _ = check self.persistClients.get(INT_ID_RECORD).runUpdateQuery(id, value);
        return self->/intidrecord/[id].get();
    }

    isolated resource function delete intidrecord/[int id]() returns IntIdRecord|Error {
        IntIdRecord result = check self->/intidrecord/[id].get();
        _ = check self.persistClients.get(INT_ID_RECORD).runDeleteQuery(id);
        return result;
    }

    isolated resource function get floatidrecord(FloatIdRecordTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get floatidrecord/[float id](FloatIdRecordTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "queryOne",
        paramTypes: ["io.ballerina.runtime.api.Environment", "io.ballerina.runtime.api.values.BObject", "io.ballerina.runtime.api.values.BArray", "io.ballerina.runtime.api.values.BTypedesc"]
    } external;

    isolated resource function post floatidrecord(FloatIdRecordInsert[] data) returns float[]|Error {
        _ = check self.persistClients.get(FLOAT_ID_RECORD).runBatchInsertQuery(data);
        return from FloatIdRecordInsert inserted in data
            select inserted.id;
    }

    isolated resource function put floatidrecord/[float id](FloatIdRecordUpdate value) returns FloatIdRecord|Error {
        _ = check self.persistClients.get(FLOAT_ID_RECORD).runUpdateQuery(id, value);
        return self->/floatidrecord/[id].get();
    }

    isolated resource function delete floatidrecord/[float id]() returns FloatIdRecord|Error {
        FloatIdRecord result = check self->/floatidrecord/[id].get();
        _ = check self.persistClients.get(FLOAT_ID_RECORD).runDeleteQuery(id);
        return result;
    }

    isolated resource function get decimalidrecord(DecimalIdRecordTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get decimalidrecord/[decimal id](DecimalIdRecordTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "queryOne",
        paramTypes: ["io.ballerina.runtime.api.Environment", "io.ballerina.runtime.api.values.BObject", "io.ballerina.runtime.api.values.BArray", "io.ballerina.runtime.api.values.BTypedesc"]
    } external;

    isolated resource function post decimalidrecord(DecimalIdRecordInsert[] data) returns decimal[]|Error {
        _ = check self.persistClients.get(DECIMAL_ID_RECORD).runBatchInsertQuery(data);
        return from DecimalIdRecordInsert inserted in data
            select inserted.id;
    }

    isolated resource function put decimalidrecord/[decimal id](DecimalIdRecordUpdate value) returns DecimalIdRecord|Error {
        _ = check self.persistClients.get(DECIMAL_ID_RECORD).runUpdateQuery(id, value);
        return self->/decimalidrecord/[id].get();
    }

    isolated resource function delete decimalidrecord/[decimal id]() returns DecimalIdRecord|Error {
        DecimalIdRecord result = check self->/decimalidrecord/[id].get();
        _ = check self.persistClients.get(DECIMAL_ID_RECORD).runDeleteQuery(id);
        return result;
    }

    isolated resource function get booleanidrecord(BooleanIdRecordTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get booleanidrecord/[boolean id](BooleanIdRecordTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "queryOne",
        paramTypes: ["io.ballerina.runtime.api.Environment", "io.ballerina.runtime.api.values.BObject", "io.ballerina.runtime.api.values.BArray", "io.ballerina.runtime.api.values.BTypedesc"]
    } external;

    isolated resource function post booleanidrecord(BooleanIdRecordInsert[] data) returns boolean[]|Error {
        _ = check self.persistClients.get(BOOLEAN_ID_RECORD).runBatchInsertQuery(data);
        return from BooleanIdRecordInsert inserted in data
            select inserted.id;
    }

    isolated resource function put booleanidrecord/[boolean id](BooleanIdRecordUpdate value) returns BooleanIdRecord|Error {
        _ = check self.persistClients.get(BOOLEAN_ID_RECORD).runUpdateQuery(id, value);
        return self->/booleanidrecord/[id].get();
    }

    isolated resource function delete booleanidrecord/[boolean id]() returns BooleanIdRecord|Error {
        BooleanIdRecord result = check self->/booleanidrecord/[id].get();
        _ = check self.persistClients.get(BOOLEAN_ID_RECORD).runDeleteQuery(id);
        return result;
    }

    isolated resource function get compositeassociationrecord(CompositeAssociationRecordTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get compositeassociationrecord/[string id](CompositeAssociationRecordTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "queryOne",
        paramTypes: ["io.ballerina.runtime.api.Environment", "io.ballerina.runtime.api.values.BObject", "io.ballerina.runtime.api.values.BArray", "io.ballerina.runtime.api.values.BTypedesc"]
    } external;

    isolated resource function post compositeassociationrecord(CompositeAssociationRecordInsert[] data) returns string[]|Error {
        _ = check self.persistClients.get(COMPOSITE_ASSOCIATION_RECORD).runBatchInsertQuery(data);
        return from CompositeAssociationRecordInsert inserted in data
            select inserted.id;
    }

    isolated resource function put compositeassociationrecord/[string id](CompositeAssociationRecordUpdate value) returns CompositeAssociationRecord|Error {
        _ = check self.persistClients.get(COMPOSITE_ASSOCIATION_RECORD).runUpdateQuery(id, value);
        return self->/compositeassociationrecord/[id].get();
    }

    isolated resource function delete compositeassociationrecord/[string id]() returns CompositeAssociationRecord|Error {
        CompositeAssociationRecord result = check self->/compositeassociationrecord/[id].get();
        _ = check self.persistClients.get(COMPOSITE_ASSOCIATION_RECORD).runDeleteQuery(id);
        return result;
    }

    isolated resource function get alltypesidrecord(AllTypesIdRecordTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get alltypesidrecord/[float floatType]/[decimal decimalType]/[boolean booleanType]/[int intType]/[string stringType](AllTypesIdRecordTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "queryOne",
        paramTypes: ["io.ballerina.runtime.api.Environment", "io.ballerina.runtime.api.values.BObject", "io.ballerina.runtime.api.values.BArray", "io.ballerina.runtime.api.values.BTypedesc"]
    } external;

    isolated resource function post alltypesidrecord(AllTypesIdRecordInsert[] data) returns [boolean, int, float, decimal, string][]|Error {
        _ = check self.persistClients.get(ALL_TYPES_ID_RECORD).runBatchInsertQuery(data);
        return from AllTypesIdRecordInsert inserted in data
            select [inserted.booleanType, inserted.intType, inserted.floatType, inserted.decimalType, inserted.stringType];
    }

    isolated resource function put alltypesidrecord/[float floatType]/[decimal decimalType]/[boolean booleanType]/[int intType]/[string stringType](AllTypesIdRecordUpdate value) returns AllTypesIdRecord|Error {
        _ = check self.persistClients.get(ALL_TYPES_ID_RECORD).runUpdateQuery({"floatType": floatType, "decimalType": decimalType, "booleanType": booleanType, "intType": intType, "stringType": stringType}, value);
        return self->/alltypesidrecord/[floatType]/[decimalType]/[booleanType]/[intType]/[stringType].get();
    }

    isolated resource function delete alltypesidrecord/[float floatType]/[decimal decimalType]/[boolean booleanType]/[int intType]/[string stringType]() returns AllTypesIdRecord|Error {
        AllTypesIdRecord result = check self->/alltypesidrecord/[floatType]/[decimalType]/[booleanType]/[intType]/[stringType].get();
        _ = check self.persistClients.get(ALL_TYPES_ID_RECORD).runDeleteQuery({"floatType": floatType, "decimalType": decimalType, "booleanType": booleanType, "intType": intType, "stringType": stringType});
        return result;
    }

    public function close() returns Error? {
        error? result = self.dbClient.close();
        if result is error {
            return <Error>error(result.message());
        }
        return result;
    }
}
