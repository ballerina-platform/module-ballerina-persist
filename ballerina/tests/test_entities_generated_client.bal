import ballerina/sql;
import ballerina/time;
import ballerinax/mysql;

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
                id: {columnName: "id", 'type: int},
                booleanType: {columnName: "booleanType", 'type: boolean},
                intType: {columnName: "intType", 'type: int},
                floatType: {columnName: "floatType", 'type: float},
                decimalType: {columnName: "decimalType", 'type: decimal},
                stringType: {columnName: "stringType", 'type: string},
                byteArrayType: {columnName: "byteArrayType", 'type: byte},
                dateType: {columnName: "dateType", 'type: time:Date},
                timeOfDayType: {columnName: "timeOfDayType", 'type: time:TimeOfDay},
                utcType: {columnName: "utcType", 'type: time:Utc},
                civilType: {columnName: "civilType", 'type: time:Civil},
                booleanTypeOptional: {columnName: "booleanTypeOptional", 'type: boolean},
                intTypeOptional: {columnName: "intTypeOptional", 'type: int},
                floatTypeOptional: {columnName: "floatTypeOptional", 'type: float},
                decimalTypeOptional: {columnName: "decimalTypeOptional", 'type: decimal},
                stringTypeOptional: {columnName: "stringTypeOptional", 'type: string},
                dateTypeOptional: {columnName: "dateTypeOptional", 'type: time:Date},
                timeOfDayTypeOptional: {columnName: "timeOfDayTypeOptional", 'type: time:TimeOfDay},
                utcTypeOptional: {columnName: "utcTypeOptional", 'type: time:Utc},
                civilTypeOptional: {columnName: "civilTypeOptional", 'type: time:Civil}
            },
            keyFields: ["id"]
        },
        "stringidrecord": {
            entityName: "StringIdRecord",
            tableName: `StringIdRecord`,
            fieldMetadata: {
                id: {columnName: "id", 'type: string},
                randomField: {columnName: "randomField", 'type: string}
            },
            keyFields: ["id"]
        },
        "intidrecord": {
            entityName: "IntIdRecord",
            tableName: `IntIdRecord`,
            fieldMetadata: {
                id: {columnName: "id", 'type: int},
                randomField: {columnName: "randomField", 'type: string}
            },
            keyFields: ["id"]
        },
        "floatidrecord": {
            entityName: "FloatIdRecord",
            tableName: `FloatIdRecord`,
            fieldMetadata: {
                id: {columnName: "id", 'type: float},
                randomField: {columnName: "randomField", 'type: string}
            },
            keyFields: ["id"]
        },
        "decimalidrecord": {
            entityName: "DecimalIdRecord",
            tableName: `DecimalIdRecord`,
            fieldMetadata: {
                id: {columnName: "id", 'type: decimal},
                randomField: {columnName: "randomField", 'type: string}
            },
            keyFields: ["id"]
        },
        "booleanidrecord": {
            entityName: "BooleanIdRecord",
            tableName: `BooleanIdRecord`,
            fieldMetadata: {
                id: {columnName: "id", 'type: boolean},
                randomField: {columnName: "randomField", 'type: string}
            },
            keyFields: ["id"]
        },
        "compositeassociationrecord": {
            entityName: "CompositeAssociationRecord",
            tableName: `CompositeAssociationRecord`,
            fieldMetadata: {
                id: {columnName: "id", 'type: string},
                randomField: {columnName: "randomField", 'type: string},
                alltypesidrecordBooleanType: {columnName: "alltypesidrecordBooleanType", 'type: boolean},
                alltypesidrecordIntType: {columnName: "alltypesidrecordIntType", 'type: int},
                alltypesidrecordFloatType: {columnName: "alltypesidrecordFloatType", 'type: float},
                alltypesidrecordDecimalType: {columnName: "alltypesidrecordDecimalType", 'type: decimal},
                alltypesidrecordStringType: {columnName: "alltypesidrecordStringType", 'type: string}
            },
            keyFields: ["id"]
        },
        "alltypesidrecord": {
            entityName: "AllTypesIdRecord",
            tableName: `AllTypesIdRecord`,
            fieldMetadata: {
                booleanType: {columnName: "booleanType", 'type: boolean},
                intType: {columnName: "intType", 'type: int},
                floatType: {columnName: "floatType", 'type: float},
                decimalType: {columnName: "decimalType", 'type: decimal},
                stringType: {columnName: "stringType", 'type: string},
                randomField: {columnName: "randomField", 'type: string}
            },
            keyFields: ["booleanType", "intType", "floatType", "decimalType", "stringType"]
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

    isolated resource function get alltypes() returns stream<AllTypes, Error?> {
        stream<record {}, sql:Error?>|Error result = self.persistClients.get(ALL_TYPES).runReadQuery(AllTypes);
        if result is Error {
            return new stream<AllTypes, Error?>(new AllTypesStream((), result));
        } else {
            return new stream<AllTypes, Error?>(new AllTypesStream(result));
        }
    }

    isolated resource function get alltypes/[int id]() returns AllTypes|Error {
        AllTypes|error result = (check self.persistClients.get(ALL_TYPES).runReadByKeyQuery(AllTypes, id)).cloneWithType(AllTypes);
        if result is error {
            return <Error>error(result.message());
        }
        return result;
    }

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

    isolated resource function get stringidrecord() returns stream<StringIdRecord, Error?> {
        stream<record {}, sql:Error?>|Error result = self.persistClients.get(STRING_ID_RECORD).runReadQuery(StringIdRecord);
        if result is Error {
            return new stream<StringIdRecord, Error?>(new StringIdRecordStream((), result));
        } else {
            return new stream<StringIdRecord, Error?>(new StringIdRecordStream(result));
        }
    }

    isolated resource function get stringidrecord/[string id]() returns StringIdRecord|Error {
        StringIdRecord|error result = (check self.persistClients.get(STRING_ID_RECORD).runReadByKeyQuery(StringIdRecord, id)).cloneWithType(StringIdRecord);
        if result is error {
            return <Error>error(result.message());
        }
        return result;
    }

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

    isolated resource function get intidrecord() returns stream<IntIdRecord, Error?> {
        stream<record {}, sql:Error?>|Error result = self.persistClients.get(INT_ID_RECORD).runReadQuery(IntIdRecord);
        if result is Error {
            return new stream<IntIdRecord, Error?>(new IntIdRecordStream((), result));
        } else {
            return new stream<IntIdRecord, Error?>(new IntIdRecordStream(result));
        }
    }

    isolated resource function get intidrecord/[int id]() returns IntIdRecord|Error {
        IntIdRecord|error result = (check self.persistClients.get(INT_ID_RECORD).runReadByKeyQuery(IntIdRecord, id)).cloneWithType(IntIdRecord);
        if result is error {
            return <Error>error(result.message());
        }
        return result;
    }

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

    isolated resource function get floatidrecord() returns stream<FloatIdRecord, Error?> {
        stream<record {}, sql:Error?>|Error result = self.persistClients.get(FLOAT_ID_RECORD).runReadQuery(FloatIdRecord);
        if result is Error {
            return new stream<FloatIdRecord, Error?>(new FloatIdRecordStream((), result));
        } else {
            return new stream<FloatIdRecord, Error?>(new FloatIdRecordStream(result));
        }
    }

    isolated resource function get floatidrecord/[float id]() returns FloatIdRecord|Error {
        FloatIdRecord|error result = (check self.persistClients.get(FLOAT_ID_RECORD).runReadByKeyQuery(FloatIdRecord, id)).cloneWithType(FloatIdRecord);
        if result is error {
            return <Error>error(result.message());
        }
        return result;
    }

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

    isolated resource function get decimalidrecord() returns stream<DecimalIdRecord, Error?> {
        stream<record {}, sql:Error?>|Error result = self.persistClients.get(DECIMAL_ID_RECORD).runReadQuery(DecimalIdRecord);
        if result is Error {
            return new stream<DecimalIdRecord, Error?>(new DecimalIdRecordStream((), result));
        } else {
            return new stream<DecimalIdRecord, Error?>(new DecimalIdRecordStream(result));
        }
    }

    isolated resource function get decimalidrecord/[decimal id]() returns DecimalIdRecord|Error {
        DecimalIdRecord|error result = (check self.persistClients.get(DECIMAL_ID_RECORD).runReadByKeyQuery(DecimalIdRecord, id)).cloneWithType(DecimalIdRecord);
        if result is error {
            return <Error>error(result.message());
        }
        return result;
    }

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

    isolated resource function get booleanidrecord() returns stream<BooleanIdRecord, Error?> {
        stream<record {}, sql:Error?>|Error result = self.persistClients.get(BOOLEAN_ID_RECORD).runReadQuery(BooleanIdRecord);
        if result is Error {
            return new stream<BooleanIdRecord, Error?>(new BooleanIdRecordStream((), result));
        } else {
            return new stream<BooleanIdRecord, Error?>(new BooleanIdRecordStream(result));
        }
    }

    isolated resource function get booleanidrecord/[boolean id]() returns BooleanIdRecord|Error {
        BooleanIdRecord|error result = (check self.persistClients.get(BOOLEAN_ID_RECORD).runReadByKeyQuery(BooleanIdRecord, id)).cloneWithType(BooleanIdRecord);
        if result is error {
            return <Error>error(result.message());
        }
        return result;
    }

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

    isolated resource function get compositeassociationrecord() returns stream<CompositeAssociationRecord, Error?> {
        stream<record {}, sql:Error?>|Error result = self.persistClients.get(COMPOSITE_ASSOCIATION_RECORD).runReadQuery(CompositeAssociationRecord);
        if result is Error {
            return new stream<CompositeAssociationRecord, Error?>(new CompositeAssociationRecordStream((), result));
        } else {
            return new stream<CompositeAssociationRecord, Error?>(new CompositeAssociationRecordStream(result));
        }
    }

    isolated resource function get compositeassociationrecord/[string id]() returns CompositeAssociationRecord|Error {
        CompositeAssociationRecord|error result = (check self.persistClients.get(COMPOSITE_ASSOCIATION_RECORD).runReadByKeyQuery(CompositeAssociationRecord, id)).cloneWithType(CompositeAssociationRecord);
        if result is error {
            return <Error>error(result.message());
        }
        return result;
    }

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

    isolated resource function get alltypesidrecord() returns stream<AllTypesIdRecord, Error?> {
        stream<record {}, sql:Error?>|Error result = self.persistClients.get(ALL_TYPES_ID_RECORD).runReadQuery(AllTypesIdRecord);
        if result is Error {
            return new stream<AllTypesIdRecord, Error?>(new AllTypesIdRecordStream((), result));
        } else {
            return new stream<AllTypesIdRecord, Error?>(new AllTypesIdRecordStream(result));
        }
    }

    isolated resource function get alltypesidrecord/[float floatType]/[decimal decimalType]/[boolean booleanType]/[int intType]/[string stringType]() returns AllTypesIdRecord|Error {
        AllTypesIdRecord|error result = (check self.persistClients.get(ALL_TYPES_ID_RECORD).runReadByKeyQuery(AllTypesIdRecord, {floatType: floatType, decimalType: decimalType, booleanType: booleanType, intType: intType, stringType: stringType})).cloneWithType(AllTypesIdRecord);
        if result is error {
            return <Error>error(result.message());
        }
        return result;
    }

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

public class AllTypesStream {

    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|AllTypes value;|}|Error? {
        if self.err is Error {
            return <Error>self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                AllTypes|error value = streamValue.value.cloneWithType(AllTypes);
                if value is error {
                    return <Error>error(value.message());
                }
                record {|AllTypes value;|} nextRecord = {value: value};
                return nextRecord;
            }
        } else {
            return ();
        }
    }

    public isolated function close() returns Error? {
        check closeEntityStream(self.anydataStream);
    }
}

public class StringIdRecordStream {

    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|StringIdRecord value;|}|Error? {
        if self.err is Error {
            return <Error>self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                StringIdRecord|error value = streamValue.value.cloneWithType(StringIdRecord);
                if value is error {
                    return <Error>error(value.message());
                }
                record {|StringIdRecord value;|} nextRecord = {value: value};
                return nextRecord;
            }
        } else {
            return ();
        }
    }

    public isolated function close() returns Error? {
        check closeEntityStream(self.anydataStream);
    }
}

public class IntIdRecordStream {

    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|IntIdRecord value;|}|Error? {
        if self.err is Error {
            return <Error>self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                IntIdRecord|error value = streamValue.value.cloneWithType(IntIdRecord);
                if value is error {
                    return <Error>error(value.message());
                }
                record {|IntIdRecord value;|} nextRecord = {value: value};
                return nextRecord;
            }
        } else {
            return ();
        }
    }

    public isolated function close() returns Error? {
        check closeEntityStream(self.anydataStream);
    }
}

public class FloatIdRecordStream {

    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|FloatIdRecord value;|}|Error? {
        if self.err is Error {
            return <Error>self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                FloatIdRecord|error value = streamValue.value.cloneWithType(FloatIdRecord);
                if value is error {
                    return <Error>error(value.message());
                }
                record {|FloatIdRecord value;|} nextRecord = {value: value};
                return nextRecord;
            }
        } else {
            return ();
        }
    }

    public isolated function close() returns Error? {
        check closeEntityStream(self.anydataStream);
    }
}

public class DecimalIdRecordStream {

    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|DecimalIdRecord value;|}|Error? {
        if self.err is Error {
            return <Error>self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                DecimalIdRecord|error value = streamValue.value.cloneWithType(DecimalIdRecord);
                if value is error {
                    return <Error>error(value.message());
                }
                record {|DecimalIdRecord value;|} nextRecord = {value: value};
                return nextRecord;
            }
        } else {
            return ();
        }
    }

    public isolated function close() returns Error? {
        check closeEntityStream(self.anydataStream);
    }
}

public class BooleanIdRecordStream {

    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|BooleanIdRecord value;|}|Error? {
        if self.err is Error {
            return <Error>self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                BooleanIdRecord|error value = streamValue.value.cloneWithType(BooleanIdRecord);
                if value is error {
                    return <Error>error(value.message());
                }
                record {|BooleanIdRecord value;|} nextRecord = {value: value};
                return nextRecord;
            }
        } else {
            return ();
        }
    }

    public isolated function close() returns Error? {
        check closeEntityStream(self.anydataStream);
    }
}

public class CompositeAssociationRecordStream {

    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|CompositeAssociationRecord value;|}|Error? {
        if self.err is Error {
            return <Error>self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                CompositeAssociationRecord|error value = streamValue.value.cloneWithType(CompositeAssociationRecord);
                if value is error {
                    return <Error>error(value.message());
                }
                record {|CompositeAssociationRecord value;|} nextRecord = {value: value};
                return nextRecord;
            }
        } else {
            return ();
        }
    }

    public isolated function close() returns Error? {
        check closeEntityStream(self.anydataStream);
    }
}

public class AllTypesIdRecordStream {

    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|AllTypesIdRecord value;|}|Error? {
        if self.err is Error {
            return <Error>self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                AllTypesIdRecord|error value = streamValue.value.cloneWithType(AllTypesIdRecord);
                if value is error {
                    return <Error>error(value.message());
                }
                record {|AllTypesIdRecord value;|} nextRecord = {value: value};
                return nextRecord;
            }
        } else {
            return ();
        }
    }

    public isolated function close() returns Error? {
        check closeEntityStream(self.anydataStream);
    }
}

