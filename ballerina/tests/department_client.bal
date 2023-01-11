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
    *AbstractPersistClient;

    private final string entityName = "Department";
    private final sql:ParameterizedQuery tableName = `Departments`;
    private final map<FieldMetadata> fieldMetadata = {
        hospitalCode: {columnName: "hospitalCode", 'type: string},
        departmentId: {columnName: "departmentId", 'type: int},
        name: {columnName: "name", 'type: string}
    };
    private string[] keyFields = ["hospitalCode", "departmentId"];

    private SQLClient persistClient;

    public function init() returns Error? {
        mysql:Client|sql:Error dbClient = new (host = host, user = user, password = password, database = database, port = port, options = connectionOptions);
        if dbClient is sql:Error {
            return <Error>error(dbClient.message());
        }

        self.persistClient = check new (dbClient, self.entityName, self.tableName, self.keyFields, self.fieldMetadata);
    }

    remote function create(Department value) returns Department|Error {
        _ = check self.persistClient.runInsertQuery(value);
        return value;
    }

    remote function readByKey(record {|string hospitalCode; int departmentId;|} key) returns Department|Error {
        return <Department>check self.persistClient.runReadByKeyQuery(Department, key);
    }

    remote function read() returns stream<Department, Error?> {
        stream<anydata, sql:Error?>|Error result = self.persistClient.runReadQuery(Department);
        if result is Error {
            return new stream<Department, Error?>(new DepartmentStream((), result));
        } else {
            return new stream<Department, Error?>(new DepartmentStream(result));
        }
    }

    remote function update(record {} 'object) returns Error? {
        _ = check self.persistClient.runUpdateQuery('object);
    }

    remote function delete(Department 'object) returns Error? {
        _ = check self.persistClient.runDeleteQuery('object);
    }

    function close() returns Error? {
        return self.persistClient.close();
    }

}

public class DepartmentStream {
    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|Department value;|}|Error? {
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
                record {|Department value;|} nextRecord = {value: <Department>streamValue.value};
                return nextRecord;
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
