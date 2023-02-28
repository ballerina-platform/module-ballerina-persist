// AUTO-GENERATED FILE. DO NOT MODIFY.

// This file is an auto-generated file by Ballerina persistence layer for medical_center.
// It should not be modified by hand.

import ballerina/sql;
import ballerinax/mysql;
import ballerina/persist;

const MEDICAL_ITEM = "medicalitem";
const MEDICAL_NEED = "medicalneed";

public client class MedicalCenterClient {
    *persist:AbstractPersistClient;

    private final mysql:Client dbClient;

    private final map<persist:SQLClient> persistClients;

    private final record {|persist:Metadata...;|} metadata = {
        "medicalitem": {
            entityName: "MedicalItem",
            tableName: `MedicalItem`,
            fieldMetadata: {
                itemId: {columnName: "itemId"},
                name: {columnName: "name"},
                'type: {columnName: "type"},
                unit: {columnName: "unit"}
            },
            keyFields: ["itemId"]
        },
        "medicalneed": {
            entityName: "MedicalNeed",
            tableName: `MedicalNeed`,
            fieldMetadata: {
                needId: {columnName: "needId"},
                beneficiaryId: {columnName: "beneficiaryId"},
                period: {columnName: "period"},
                urgency: {columnName: "urgency"},
                quantity: {columnName: "quantity"}
            },
            keyFields: ["needId"]
        }
    };

    public function init() returns persist:Error? {
        mysql:Client|error dbClient = new (host = host, user = user, password = password, database = database, port = port);
        if dbClient is error {
            return <persist:Error>error(dbClient.message());
        }
        self.dbClient = dbClient;
        self.persistClients = {
            medicalitem: check new (self.dbClient, self.metadata.get(MEDICAL_ITEM)),
            medicalneed: check new (self.dbClient, self.metadata.get(MEDICAL_NEED))
        };
    }

    isolated resource function get medicalitem() returns stream<MedicalItem, persist:Error?> {
        stream<record {}, sql:Error?>|persist:Error result = self.persistClients.get(MEDICAL_ITEM).runReadQuery(MedicalItem);
        if result is persist:Error {
            return new stream<MedicalItem, persist:Error?>(new MedicalItemStream((), result));
        } else {
            return new stream<MedicalItem, persist:Error?>(new MedicalItemStream(result));
        }
    }

    isolated resource function get medicalitem/[int itemId]() returns MedicalItem|persist:Error {
        MedicalItem|error result = (check self.persistClients.get(MEDICAL_ITEM).runReadByKeyQuery(MedicalItem, itemId)).cloneWithType(MedicalItem);
        if result is error {
            return <persist:Error>error(result.message());
        }
        return result;
    }

    isolated resource function post medicalitem(MedicalItemInsert[] data) returns int[]|persist:Error {
        _ = check self.persistClients.get(MEDICAL_ITEM).runBatchInsertQuery(data);
        return from MedicalItemInsert inserted in data
            select inserted.itemId;
    }

    isolated resource function put medicalitem/[int itemId](MedicalItemUpdate value) returns MedicalItem|persist:Error {
        _ = check self.persistClients.get(MEDICAL_ITEM).runUpdateQuery(itemId, value);
        return self->/medicalitem/[itemId].get();
    }

    isolated resource function delete medicalitem/[int itemId]() returns MedicalItem|persist:Error {
        MedicalItem result = check self->/medicalitem/[itemId].get();
        _ = check self.persistClients.get(MEDICAL_ITEM).runDeleteQuery(itemId);
        return result;
    }

    isolated resource function get medicalneed() returns stream<MedicalNeed, persist:Error?> {
        stream<record {}, sql:Error?>|persist:Error result = self.persistClients.get(MEDICAL_NEED).runReadQuery(MedicalNeed);
        if result is persist:Error {
            return new stream<MedicalNeed, persist:Error?>(new MedicalNeedStream((), result));
        } else {
            return new stream<MedicalNeed, persist:Error?>(new MedicalNeedStream(result));
        }
    }

    isolated resource function get medicalneed/[int needId]() returns MedicalNeed|persist:Error {
        MedicalNeed|error result = (check self.persistClients.get(MEDICAL_NEED).runReadByKeyQuery(MedicalNeed, needId)).cloneWithType(MedicalNeed);
        if result is error {
            return <persist:Error>error(result.message());
        }
        return result;
    }

    isolated resource function post medicalneed(MedicalNeedInsert[] data) returns int[]|persist:Error {
        _ = check self.persistClients.get(MEDICAL_NEED).runBatchInsertQuery(data);
        return from MedicalNeedInsert inserted in data
            select inserted.needId;
    }

    isolated resource function put medicalneed/[int needId](MedicalNeedUpdate value) returns MedicalNeed|persist:Error {
        _ = check self.persistClients.get(MEDICAL_NEED).runUpdateQuery(needId, value);
        return self->/medicalneed/[needId].get();
    }

    isolated resource function delete medicalneed/[int needId]() returns MedicalNeed|persist:Error {
        MedicalNeed result = check self->/medicalneed/[needId].get();
        _ = check self.persistClients.get(MEDICAL_NEED).runDeleteQuery(needId);
        return result;
    }

    public function close() returns persist:Error? {
        error? result = self.dbClient.close();
        if result is error {
            return <persist:Error>error(result.message());
        }
        return result;
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
        if self.err is persist:Error {
            return <persist:Error>self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <persist:Error>error(streamValue.message());
            } else {
                MedicalItem|error value = streamValue.value.cloneWithType(MedicalItem);
                if value is error {
                    return <persist:Error>error(value.message());
                }
                record {|MedicalItem value;|} nextRecord = {value: value};
                return nextRecord;
            }
        } else {
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
        if self.err is persist:Error {
            return <persist:Error>self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <persist:Error>error(streamValue.message());
            } else {
                MedicalNeed|error value = streamValue.value.cloneWithType(MedicalNeed);
                if value is error {
                    return <persist:Error>error(value.message());
                }
                record {|MedicalNeed value;|} nextRecord = {value: value};
                return nextRecord;
            }
        } else {
            return ();
        }
    }

    public isolated function close() returns persist:Error? {
        check persist:closeEntityStream(self.anydataStream);
    }
}

