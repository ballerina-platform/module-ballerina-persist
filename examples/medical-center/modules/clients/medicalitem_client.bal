import ballerina/sql;
import ballerinax/mysql;
import ballerina/persist;

public client class MedicalItemClient {

    private final string entityName = "MedicalItem";
    private final sql:ParameterizedQuery tableName = `MedicalItems`;

    private final map<persist:FieldMetadata> fieldMetadata = {
        itemId: {columnName: "itemId", 'type: int},
        name: {columnName: "name", 'type: string},
        'type: {columnName: "type", 'type: string},
        unit: {columnName: "unit", 'type: string}
    };
    private string[] keyFields = ["itemId"];

    private persist:SQLClient persistClient;

    public function init() returns error? {
        mysql:Client dbClient = check new (host = host, user = user, password = password, database = database, port = port);
        self.persistClient = check new (dbClient, self.entityName, self.tableName, self.keyFields, self.fieldMetadata);
    }

    remote function create(MedicalItem value) returns MedicalItem|error {
        sql:ExecutionResult result = check self.persistClient.runInsertQuery(value);
        if result.lastInsertId is () {
            return value;
        }
        return {itemId: <int>result.lastInsertId, name: value.name, 'type: value.'type, unit: value.unit};
    }

    remote function readByKey(int key) returns MedicalItem|error {
        return (check self.persistClient.runReadByKeyQuery(MedicalItem, key)).cloneWithType(MedicalItem);
    }

    remote function read() returns stream<MedicalItem, error?> {
        stream<anydata, error?>|error result = self.persistClient.runReadQuery(MedicalItem, ());
        if result is error {
            return new stream<MedicalItem, error?>(new MedicalItemStream((), result));
        } else {
            return new stream<MedicalItem, error?>(new MedicalItemStream(result));
        }
    }

    remote function execute(sql:ParameterizedQuery filterClause) returns stream<MedicalItem, error?> {
        stream<anydata, error?>|error result = self.persistClient.runExecuteQuery(filterClause, MedicalItem);
        if result is error {
            return new stream<MedicalItem, error?>(new MedicalItemStream((), result));
        } else {
            return new stream<MedicalItem, error?>(new MedicalItemStream(result));
        }
    }

    remote function update(MedicalItem value) returns error? {
        map<anydata> filter = {"itemId": value.itemId};
        _ = check self.persistClient.runUpdateQuery(value, filter);
    }

    remote function delete(MedicalItem value) returns error? {
        _ = check self.persistClient.runDeleteQuery(value);
    }

    public function close() returns error? {
        return self.persistClient.close();
    }
}

public class MedicalItemStream {

    private stream<anydata, error?>? anydataStream;
    private error? err;

    public isolated function init(stream<anydata, error?>? anydataStream, error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|MedicalItem value;|}|error? {
        if self.err is error {
            return <error>self.err;
        } else if self.anydataStream is stream<anydata, error?> {
            var anydataStream = <stream<anydata, error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is error) {
                return streamValue;
            } else {
                record {|MedicalItem value;|} nextRecord = {value: check streamValue.value.cloneWithType(MedicalItem)};
                return nextRecord;
            }
        } else {
            return ();
        }
    }

    public isolated function close() returns error? {
        if self.anydataStream is stream<anydata, error?> {
            var anydataStream = <stream<anydata, error?>>self.anydataStream;
            return anydataStream.close();
        }
    }
}
