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
    @persist:AutoIncrement {increment: 2}
    readonly int needId = 12;
    int itemId;
    int beneficiaryId;
    time:Civil period?;
    string urgency?;
    int quantity;
    @persist:Relation {key: ["itemId"], reference: ["id1"], cascadeDelete: true}
    Item item?;
|};

@persist:Entity {key: ["id"]}
public type Item record {
    @persist:AutoIncrement
    int id = -1;
    string name;
};

final map<persist:FieldMetadata> fieldMetadata = {
    needId: {columnName: "needId", 'type: int, autoGenerated: true},
    itemId: {columnName: "itemId", 'type: int},
    beneficiaryId: {columnName: "beneficiaryId", 'type: int},
    period: {columnName: "period", 'type: time:Civil},
    urgency: {columnName: "urgency", 'type: string},
    quantity: {columnName: "quantity", 'type: int}
};

MedicalNeed medicalNeed = {
    itemId: 123,
    beneficiaryId: 1,
    quantity: 1
};

sql:ParameterizedQuery query = `MedicalNeeds`;

public function main() returns error? {
    mysql:Client dbClient = check new (host = "localhost", user = "root", password = "Test123#",
                database = "test", port = 3305);
    persist:SQLClient|error persistClient = new (entityName = "MedicalNeed", tableName = query,
                                fieldMetadata = fieldMetadata, keyFields = ["needId"], dbClient = dbClient);
    if persistClient is persist:SQLClient {
        sql:ExecutionResult _ = check persistClient.runInsertQuery(medicalNeed);
    }
}