import ballerina/sql;
import ballerinax/mysql;
import ballerina/persist;
import persist/package_13 as entities;

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
}
