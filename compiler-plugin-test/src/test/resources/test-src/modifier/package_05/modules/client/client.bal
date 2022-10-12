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
import package_05.entity;

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

    public function init() returns error? {
        mysql:Client dbClient = check new (host = HOST, user = USER, password = PASSWORD, database = DATABASE, port = PORT);
        self.persistClient = check new (dbClient, self.entityName, self.tableName, self.keyFields, self.fieldMetadata);
    }

    remote function create(entity:MedicalNeed value) returns int|error? {
        sql:ExecutionResult result = check self.persistClient.runInsertQuery(value);
        return <int>result.lastInsertId;
    }

    remote function readByKey(int key) returns entity:MedicalNeed|error {
        return (check self.persistClient.runReadByKeyQuery(entity:MedicalNeed, key)).cloneWithType(entity:MedicalNeed);
    }

    remote function read(map<anydata>? filter = ()) returns stream<entity:MedicalNeed, error?> {
        stream<anydata, error?>|error result = self.persistClient.runReadQuery(entity:MedicalNeed, filter);
        if result is error {
            return new stream<entity:MedicalNeed, error?>(new MedicalNeedStream((), result));
        } else {
            return new stream<entity:MedicalNeed, error?>(new MedicalNeedStream(result));
        }
    }

    remote function execute(sql:ParameterizedQuery filterClause) returns stream<entity:MedicalNeed, error?> {
        stream<anydata, error?>|error result = self.persistClient.runExecuteQuery(filterClause, entity:MedicalNeed);
        if result is error {
            return new stream<entity:MedicalNeed, error?>(new MedicalNeedStream((), result));
        } else {
            return new stream<entity:MedicalNeed, error?>(new MedicalNeedStream(result));
        }
    }

    remote function update(record {} 'object, map<anydata> filter) returns error? {
        _ = check self.persistClient.runUpdateQuery('object, filter);
    }

    remote function delete(map<anydata> filter) returns error? {
        _ = check self.persistClient.runDeleteQuery(filter);
    }

    public function close() returns error? {
        return self.persistClient.close();
    }

}

public class MedicalNeedStream {
    private stream<anydata, error?>? anydataStream;
    private error? err;

    public isolated function init(stream<anydata, error?>? anydataStream, error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|entity:MedicalNeed value;|}|error? {
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
                record {|entity:MedicalNeed value;|} nextRecord = {value: check streamValue.value.cloneWithType(entity:MedicalNeed)};
                return nextRecord;
            }
        } else {
            // Unreachable code
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
