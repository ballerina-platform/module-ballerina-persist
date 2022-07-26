import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/sql;

client class MedicalItemClient {

    private final string entityName = "MedicalItems";
    private final sql:ParameterizedQuery tableName = `MedicalItems`;
    private final map<FieldMetadata> fieldMetadata = {
        itemId: { columnName: "itemId", 'type: int },
        name: { columnName: "name", 'type: string },
        'type: { columnName: "type", 'type: string },
        unit: { columnName: "unit", 'type: string }
    };
    private string[] keyFields = ["itemId"];

    private SQLClient persistClient;

    public function init() returns error? {
        mysql:Client dbClient = check new (host = HOST, user = USER, password = PASSWORD, database = DATABASE, port = PORT);
        self.persistClient = check new(self.entityName, self.tableName, self.fieldMetadata, self.keyFields, dbClient);
    }

    remote function create(MedicalItem value) returns int|error? {
        sql:ExecutionResult result = check self.persistClient.runInsertQuery(value);

        if result.lastInsertId is () {
            return value.itemId;
        }
        return <int>result.lastInsertId;
    }

    remote function readByKey(int key) returns MedicalItem|error {
        return (check self.persistClient.runReadByKeyQuery(key)).cloneWithType(MedicalItem);
    }

    remote function read(map<anydata>|FilterQuery? filter = ()) returns stream<MedicalItem, error?>|error {
        stream<anydata, error?> result = check self.persistClient.runReadQuery(filter);
        return new stream<MedicalItem, error?>(new MedicalItemStream(result));
    }

    remote function update(record {} 'object, map<anydata>|FilterQuery filter) returns error? {
        _ = check self.persistClient.runUpdateQuery('object, filter);
    }

    remote function delete(map<anydata>|FilterQuery filter) returns error? {
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

    public isolated function next() returns record {|MedicalItem value;|}|error? {
        var streamValue = self.anydataStream.next();
        if streamValue is () {
            return streamValue;
        } else if (streamValue is error) {
            return streamValue;
        } else {
            record {|MedicalItem value;|} nextRecord = {value: check streamValue.value.cloneWithType(MedicalItem)};
            return nextRecord;
        }
    }

    public isolated function close() returns error? {
        return self.anydataStream.close();
    }
}

