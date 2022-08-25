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

import ballerinax/mysql;
import ballerina/sql;

client class DepartmentClient {

    private final string entityName = "Department";
    private final sql:ParameterizedQuery tableName = `Departments`;
    private final map<FieldMetadata> fieldMetadata = {
        hospitalCode: {columnName: "hospitalCode", 'type: string},
        departmentId: {columnName: "departmentId", 'type: int},
        name: {columnName: "name", 'type: string}
    };
    private string[] keyFields = ["hospitalCode", "departmentId"];

    private SQLClient persistClient;

    public function init() returns error? {
        mysql:Client dbClient = check new (host = HOST, user = USER, password = PASSWORD, database = DATABASE, port = PORT);
        self.persistClient = check new (self.entityName, self.tableName, self.fieldMetadata, self.keyFields, dbClient);
    }

    remote function create(Department value) returns [string, int]|error? {
        sql:ExecutionResult _ = check self.persistClient.runInsertQuery(value);
        return [value.hospitalCode, value.departmentId];
    }

    remote function readByKey(string hospitalCode, int departmentId) returns Department|error {
        return (check self.persistClient.runReadByKeyQuery(Department, [], hospitalCode, departmentId)).cloneWithType(Department);
    }

    remote function read(map<anydata>? filter = ()) returns stream<Department, error?>|error {
        stream<anydata, error?> result = check self.persistClient.runReadQuery(filter);
        return new stream<Department, error?>(new DepartmentStream(result));
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

public class DepartmentStream {
    private stream<anydata, error?> anydataStream;

    public isolated function init(stream<anydata, error?> anydataStream) {
        self.anydataStream = anydataStream;
    }

    public isolated function next() returns record {|Department value;|}|error? {
        var streamValue = self.anydataStream.next();
        if streamValue is () {
            return streamValue;
        } else if (streamValue is error) {
            return streamValue;
        } else {
            record {|Department value;|} nextRecord = {value: check streamValue.value.cloneWithType(Department)};
            return nextRecord;
        }
    }

    public isolated function close() returns error? {
        return self.anydataStream.close();
    }
}
