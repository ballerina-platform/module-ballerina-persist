// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/sql;
import ballerinax/mysql;
import ballerina/time;
import ballerina/persist;
import ballerinax/mysql.driver as _;
import package_04.entity;

configurable string USER = ?;
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable string DATABASE = ?;
configurable int PORT = ?;

public client class MedicalNeedClient {

    private final string entityName = "MedicalNeed";
    private final sql:ParameterizedQuery tableName = `MedicalNeeds`;

    private final map<persist:FieldMetadata> fieldMetadata = {
        needId: {columnName: "needId", 'type: int, autoGenerated: true},
        itemId: {columnName: "itemId", 'type: int},
        beneficiaryId: {columnName: "beneficiaryId", 'type: int},
        period: {columnName: "period", 'type: time:Civil},
        urgency: {columnName: "urgency", 'type: string},
        quantity: {columnName: "quantity", 'type: int}
    };
    private string[] keyFields = ["needId"];

    private persist:SQLClient persistClient;

    public function init() returns persist:Error? {
        mysql:Client|sql:Error dbClient = new (host = HOST, user = USER, password = PASSWORD, database = DATABASE, port = PORT);
        if dbClient is sql:Error {
            return <persist:Error>error(dbClient.message());
        }

        self.persistClient = check new (dbClient, self.entityName, self.tableName, self.keyFields, self.fieldMetadata);
    }

    remote function create(entity:MedicalNeed value) returns entity:MedicalNeed|persist:Error {
        sql:ExecutionResult result = check self.persistClient.runInsertQuery(value);

        return <entity:MedicalNeed>{
            needId: <int>result.lastInsertId,
            beneficiaryId: value.beneficiaryId,
            itemId: value.itemId,
            period: value.period,
            quantity: value.quantity,
            urgency: value.urgency
        };
    }

    remote function readByKey(int key) returns entity:MedicalNeed|persist:Error {
        return <entity:MedicalNeed>check self.persistClient.runReadByKeyQuery(entity:MedicalNeed, key);
    }

    remote function read() returns stream<entity:MedicalNeed, persist:Error?> {
        stream<anydata, sql:Error?>|persist:Error result = self.persistClient.runReadQuery(entity:MedicalNeed);
        if result is persist:Error {
            return new stream<entity:MedicalNeed, persist:Error?>(new MedicalNeedStream((), result));
        } else {
            return new stream<entity:MedicalNeed, persist:Error?>(new MedicalNeedStream(result));
        }
    }

    remote function execute(sql:ParameterizedQuery filterClause) returns stream<entity:MedicalNeed, persist:Error?> {
        stream<anydata, sql:Error?>|persist:Error result = self.persistClient.runExecuteQuery(filterClause, entity:MedicalNeed);
        if result is persist:Error {
            return new stream<entity:MedicalNeed, persist:Error?>(new MedicalNeedStream((), result));
        } else {
            return new stream<entity:MedicalNeed, persist:Error?>(new MedicalNeedStream(result));
        }
    }

    remote function update(entity:MedicalNeed 'object) returns persist:Error? {
        _ = check self.persistClient.runUpdateQuery('object);
    }

    remote function delete(entity:MedicalNeed 'object) returns persist:Error? {
        _ = check self.persistClient.runDeleteQuery('object);
    }

    public function close() returns persist:Error? {
        return self.persistClient.close();
    }
}

public class MedicalNeedStream {
    private stream<anydata, sql:Error?>? anydataStream;
    private persist:Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, persist:Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|entity:MedicalNeed value;|}|persist:Error? {
        if self.err is persist:Error {
            return self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <persist:Error>error(streamValue.message());
            } else {
                record {|entity:MedicalNeed value;|} nextRecord = {value: <entity:MedicalNeed>streamValue.value};
                return nextRecord;
            }
        } else {
            // Unreachable code
            return ();
        }
    }

    public isolated function close() returns persist:Error? {
        if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            sql:Error? e = anydataStream.close();
            if e is sql:Error {
                return <persist:Error>error(e.message());
            }
        }
    }
}
