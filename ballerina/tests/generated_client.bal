import ballerinax/mysql;
import ballerina/sql;

client class RainierClient {

    private final mysql:Client dbClient;

    private final map<Metadata> metadata = {
        building: {
            fieldMetadata: {
                buildingCode: {columnName: "buildingCode", 'type: string},
                city: {columnName: "city", 'type: string},
                state: {columnName: "state", 'type: string},
                country: {columnName: "country", 'type: string},
                postalCode: {columnName: "postalCode", 'type: string}
            },
            keyFields: ["buildingCode"]
        }
    };
    
    private final map<SQLClient> persistClients;
    
    public function init() returns Error? {
        do {
            self.dbClient = check new (host = host, user = user, password = password, database = database, port = port);

            self.persistClients = {
                building: check new (self.dbClient, "Building", `Building`, self.metadata.get("building").keyFields, self.metadata.get("building").fieldMetadata)
            };
        } on fail error e {
            return <Error>error(e.message());
        }
    }

    isolated resource function get buildings() returns stream<Building, error?> {
        stream<anydata, sql:Error?>|Error result = self.persistClients.get("building").runReadQuery();
        if result is Error {
            return new stream<Building, Error?>(new BuildingStream((), result));
        } else {
            return new stream<Building, Error?>(new BuildingStream(result));
        }

    };

    isolated resource function get buildings/[string buildingCode]() returns Building|error {
        return (check self.persistClients.get("building").runReadByKeyQuery(buildingCode)).cloneWithType(Building);
    };

    isolated resource function post buildings(BuildingInsert data) returns Building|error {
        _ = check self.persistClients.get("building").runInsertQuery(data);
        return data;
    };

    isolated resource function put buildings/[string buildingCode](BuildingUpdate data) returns Building|error {
        _ = check self.persistClients.get("building").runUpdateQuery(buildingCode, data);
        return self->/buildings/[buildingCode].get();
    };

    isolated resource function delete buildings/[string buildingCode]() returns Building|error {
        Building 'object = check self->/buildings/[buildingCode].get();
        _ = check self.persistClients.get("building").runDeleteQuery(buildingCode);
        return 'object;
    };
}

public class BuildingStream {
    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|Building value;|}|Error? {
        if self.err is error {
            return self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                do {
                    record {|Building value;|} nextRecord = {value: check streamValue.value.cloneWithType(Building)};
                    return nextRecord;
                } on fail error e {
                    return <Error>e;
                }
            }
        } else {
            // Unreachable code
            return ();
        }
    }

    public isolated function close() returns Error? {
        if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            sql:Error? e = anydataStream.close();
            if e is sql:Error {
                return <Error>error(e.message());
            }
        }
    }
}