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

@persist:Entity {
    key: ["needId"],
    unique: [["itemId", "needId"]],
    tableName: "EMPLOYEE"
}
public type MedicalNeed record {|
    @persist:AutoIncrement {increment: 1, startValue: 1}
    readonly int needId = -1;
    int itemId;
    int beneficiaryId;
    time:Civil period;
    string urgency;
    int quantity;
    @persist:Relation {key: ["itemId"], reference: ["id"], cascadeDelete: true}
    Item item?;
|};

@persist:Entity {key: ["id"]}
public type Item record {
    @persist:AutoIncrement
    int id = -1;
    string name;
};

configurable string USER = ?;
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable string DATABASE = ?;
configurable int PORT = ?;

client class MedicalNeedClient {

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
        mysql:Client dbClient = check new (host = HOST, user = USER, password = PASSWORD, database = DATABASE,
        port = PORT);
        self.persistClient = check new (self.entityName, self.tableName, self.fieldMetadata, self.keyFields, dbClient);
    }

    remote function create(MedicalNeed value) returns int|error? {
        sql:ExecutionResult result = check self.persistClient.runInsertQuery(value);
        return <int>result.lastInsertId;
    }
}