import ballerinax/mysql;
import ballerina/sql;
import ballerina/time;
import ballerina/persist;

const MEDICAL_ITEM = "medicalItem";
const MEDICAL_NEED = "medicalNeed";

client class MedicalCenterClient {

    private final mysql:Client dbClient;

    private final record{|persist:Metadata...;|} metadata = {
        "medicalItem": {
            entityName: MEDICAL_ITEM,
            tableName: `MedicalItem`,
            fieldMetadata: {
                itemId: {columnName: "itemId", 'type: int},
                name: {columnName: "name", 'type: string},
                'type: {columnName: "type", 'type: string},
                unit: {columnName: "unit", 'type: string}
            },
            keyFields: ["itemId"]
        },
        "medicalNeed": {
            entityName: MEDICAL_NEED,
            tableName: `MedicalNeed`,
            fieldMetadata: {
                needId : {columnName: "needId", 'type: int},
                itemId: {columnName: "itemId", 'type: int},
                beneficiaryId: {columnName: "beneficiaryId", 'type: int},
                period: {columnName: "period", 'type: time:Civil},
                urgency: {columnName: "urgency", 'type: string},
                quantity: {columnName: "quantity", 'type: int}
            },
            keyFields: ["needId"]
        }
    };

    private final map<persist:SQLClient> persistClients;

    public function init() returns persist:Error? {
        do {
            self.dbClient = check new (host = host, user = user, password = password, database = database, port = port);

            self.persistClients = {
                medicalItem: check new (self.dbClient, self.metadata.get(MEDICAL_ITEM)),
                medicalNeed: check new (self.dbClient, self.metadata.get(MEDICAL_NEED))
            };
        } on fail error e {
            return <persist:Error>error(e.message());
        }
    }

    isolated resource function get medicalItems() returns stream<MedicalItem, error?> {
        stream<anydata, sql:Error?>|persist:Error result = self.persistClients.get(MEDICAL_ITEM).runReadQuery(MedicalItem);
        if result is persist:Error {
            return new stream<MedicalItem, persist:Error?>(new MedicalItemStream((), result));
        } else {
            return new stream<MedicalItem, persist:Error?>(new MedicalItemStream(result));
        }
    };

    isolated resource function get medicalItems/[int itemId]() returns MedicalItem|error {
        return (check self.persistClients.get(MEDICAL_ITEM).runReadByKeyQuery(MedicalItem, itemId)).cloneWithType(MedicalItem);
    };

    isolated resource function post medicalItems(MedicalItemInsert[] data) returns int[]|error {
        _ = check self.persistClients.get(MEDICAL_ITEM).runBatchInsertQuery(data);
        return from MedicalItemInsert inserted in data
               select inserted.itemId;
    };

    isolated resource function put medicalItems/[int itemId](MedicalItemUpdate data) returns MedicalItem|error {
        _ = check self.persistClients.get(MEDICAL_ITEM).runUpdateQuery(itemId, data);
        return self->/medicalItems/[itemId].get();
    };

    isolated resource function delete medicalItems/[int itemId]() returns MedicalItem|error {
        MedicalItem 'object = check self->/medicalItems/[itemId].get();
        _ = check self.persistClients.get(MEDICAL_ITEM).runDeleteQuery(itemId);
        return 'object;
    };

    isolated resource function get medicalNeeds() returns stream<MedicalNeed, error?> {
        stream<anydata, sql:Error?>|persist:Error result = self.persistClients.get(MEDICAL_NEED).runReadQuery(MedicalNeed);
        if result is persist:Error {
            return new stream<MedicalNeed, persist:Error?>(new MedicalNeedStream((), result));
        } else {
            return new stream<MedicalNeed, persist:Error?>(new MedicalNeedStream(result));
        }
    };

    isolated resource function get medicalNeeds/[int needId]() returns MedicalNeed|error {
        return (check self.persistClients.get(MEDICAL_NEED).runReadByKeyQuery(MedicalNeed, needId)).cloneWithType(MedicalNeed);
    };

    isolated resource function post medicalNeeds(MedicalNeedInsert[] data) returns int[]|error {
        _ = check self.persistClients.get(MEDICAL_NEED).runBatchInsertQuery(data);
        return from MedicalNeedInsert inserted in data
               select inserted.needId;
    };

    isolated resource function put medicalNeeds/[int needId](MedicalNeedUpdate data) returns MedicalNeed|error {
        _ = check self.persistClients.get(MEDICAL_NEED).runUpdateQuery(needId, data);
        return self->/medicalNeeds/[needId].get();
    };

    isolated resource function delete medicalNeeds/[int needId]() returns MedicalNeed|error {
        MedicalNeed 'object = check self->/medicalNeeds/[needId].get();
        _ = check self.persistClients.get(MEDICAL_NEED).runDeleteQuery(needId);
        return 'object;
    };

    public isolated function close() returns persist:Error? {
        sql:Error? e = self.dbClient.close();
        if e is sql:Error {
            return <persist:Error>error(e.message());
        }
    }

}

public class MedicalItemStream {
    private stream<anydata, sql:Error?>? anydataStream;
    private persist:Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, persist:Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|MedicalItem value;|}|persist:Error? {
        if self.err is error {
            return self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <persist:Error>error(streamValue.message());
            } else {
                do {
                    record {|MedicalItem value;|} nextRecord = {value: check streamValue.value.cloneWithType(MedicalItem)};
                    return nextRecord;
                } on fail error e {
                    return <persist:Error>e;
                }
            }
        } else {
            // Unreachable code
            return ();
        }
    }

    public isolated function close() returns persist:Error? { 
        check persist:closeEntityStream(self.anydataStream);
    }
}

public class MedicalNeedStream {
    private stream<anydata, sql:Error?>? anydataStream;
    private persist:Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, persist:Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|MedicalNeed value;|}|persist:Error? {
        if self.err is error {
            return self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <persist:Error>error(streamValue.message());
            } else {
                do {
                    record {|MedicalNeed value;|} nextRecord = {value: check streamValue.value.cloneWithType(MedicalNeed)};
                    return nextRecord;
                } on fail error e {
                    return <persist:Error>e;
                }
            }
        } else {
            // Unreachable code
            return ();
        }
    }

    public isolated function close() returns persist:Error? { 
        check persist:closeEntityStream(self.anydataStream);
    }
}
