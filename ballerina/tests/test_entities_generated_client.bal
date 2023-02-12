import ballerina/sql;
import ballerina/time;
import ballerinax/mysql;

const ALL_TYPES = "alltypes";

public client class TestEntitiesClient {
    *AbstractPersistClient;

    private final mysql:Client dbClient;

    private final map<SQLClient> persistClients;

    private final record {|Metadata...;|} metadata = {
        "alltypes": {
            entityName: "AllTypes",
            tableName: `AllTypes`,
            fieldMetadata: {
                id: {columnName: "id", 'type: string},
                booleanType: {columnName: "booleanType", 'type: boolean},
                intType: {columnName: "intType", 'type: int},
                floatType: {columnName: "floatType", 'type: float},
                decimalType: {columnName: "decimalType", 'type: decimal},
                stringType: {columnName: "stringType", 'type: string},
                byteArrayType: {columnName: "byteArrayType", 'type: byte},
                dateType: {columnName: "dateType", 'type: time:Date},
                timeOfDayType: {columnName: "timeOfDayType", 'type: time:TimeOfDay},
                utcType: {columnName: "utcType", 'type: time:Utc},
                civilType: {columnName: "civilType", 'type: time:Civil}
            },
            keyFields: ["id"]
        }
    };

    public function init() returns Error? {
        mysql:Client|error dbClient = new (host = host, user = user, password = password, database = database, port = port);
        if dbClient is error {
            return <Error>error(dbClient.message());
        }
        self.dbClient = dbClient;
        self.persistClients = {alltypes: check new (self.dbClient, self.metadata.get(ALL_TYPES))};
    }

    isolated resource function get alltypes() returns stream<AllTypes, Error?> {
        stream<record {}, sql:Error?>|Error result = self.persistClients.get(ALL_TYPES).runReadQuery(AllTypes);
        if result is Error {
            return new stream<AllTypes, Error?>(new AllTypesStream((), result));
        } else {
            return new stream<AllTypes, Error?>(new AllTypesStream(result));
        }
    }

    isolated resource function get alltypes/[string id]() returns AllTypes|Error {
        AllTypes|error result = (check self.persistClients.get(ALL_TYPES).runReadByKeyQuery(AllTypes, id)).cloneWithType(AllTypes);
        if result is error {
            return <Error>error(result.message());
        }
        return result;
    }

    isolated resource function post alltypes(AllTypesInsert[] data) returns string[]|Error {
        _ = check self.persistClients.get(ALL_TYPES).runBatchInsertQuery(data);
        return from AllTypesInsert inserted in data
            select inserted.id;
    }

    isolated resource function put alltypes/[string id](AllTypesUpdate value) returns AllTypes|Error {
        _ = check self.persistClients.get(ALL_TYPES).runUpdateQuery(id, value);
        return self->/alltypes/[id].get();
    }

    isolated resource function delete alltypes/[string id]() returns AllTypes|Error {
        AllTypes result = check self->/alltypes/[id].get();
        _ = check self.persistClients.get(ALL_TYPES).runDeleteQuery(id);
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

