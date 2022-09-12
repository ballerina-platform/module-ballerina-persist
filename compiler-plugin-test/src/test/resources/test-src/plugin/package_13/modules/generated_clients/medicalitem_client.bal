import ballerina/sql;
import ballerinax/mysql;
import ballerina/persist;
import persist/package_12 as entities;

public client class MedicalItemClient {

    private final string entityName = "MedicalItem";
    private final sql:ParameterizedQuery tableName = `MedicalItems`;

    private final map<persist:FieldMetadata> fieldMetadata = {
        itemId: {columnName: "itemId", 'type: int},
        name: {columnName: "name", 'type: string},
        'type: {columnName: "type", 'type: string},
        unit: {columnName: "unit", 'type: int}
    };
    private string[] keyFields = ["itemId"];

    private persist:SQLClient persistClient;

    public function init() returns error? {
        mysql:Client dbClient = check new (host = host, user = user, password = password, database = database, port = port);
        self.persistClient = check new (dbClient, self.entityName, self.tableName, self.keyFields, self.fieldMetadata);
    }

    remote function create(entities:MedicalItem value) returns entities:MedicalItem|error? {
        sql:ExecutionResult result = check self.persistClient.runInsertQuery(value);
        if result.lastInsertId is () {
            return value;
        }
        return {itemId: <int>result.lastInsertId, name: value.name, 'type: value.'type, unit: value.unit};
    }

    remote function readByKey(int key) returns entities:MedicalItem|error {
        return (check self.persistClient.runReadByKeyQuery(entities:MedicalItem, key)).cloneWithType(entities:MedicalItem);
    }

    remote function read(map<anydata>? filter = ()) returns stream<entities:MedicalItem, error?>|error {
        stream<anydata, error?> result = check self.persistClient.runReadQuery(entities:MedicalItem, filter);
        return new stream<entities:MedicalItem, error?>(new MedicalItemStream(result));
    }

    remote function update(record {} 'object, map<anydata> filter) returns error? {
        _ = check self.persistClient.runUpdateQuery('object, filter);
    }

    remote function delete(map<anydata> filter) returns error? {
        _ = check self.persistClient.runDeleteQuery(filter);
    }

    function close() returns error? {
        return self.persistClient.close();
    }
}

public class MedicalItemStream {
    private stream<anydata, error?> anydataStream;

    public isolated function init(stream<anydata, error?> anydataStream) {
        self.anydataStream = anydataStream;
    }

    public isolated function next() returns record {|entities:MedicalItem value;|}|error? {
        var streamValue = self.anydataStream.next();
        if streamValue is () {
            return streamValue;
        } else if (streamValue is error) {
            return streamValue;
        } else {
            record {|entities:MedicalItem value;|} nextRecord = {value: check streamValue.value.cloneWithType(entities:MedicalItem)};
            return nextRecord;
        }
    }

    public isolated function close() returns error? {
        return self.anydataStream.close();
    }
}
