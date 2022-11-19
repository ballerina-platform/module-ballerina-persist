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

public client class MedicalItemClient {
    *AbstractPersistClient;

    private final string entityName = "MedicalItem";
    private final sql:ParameterizedQuery tableName = `MedicalItems`;
    private final map<FieldMetadata> fieldMetadata = {
        itemId: {columnName: "itemId", 'type: int},
        name: {columnName: "name", 'type: string},
        'type: {columnName: "type", 'type: string},
        unit: {columnName: "unit", 'type: string}
    };
    private string[] keyFields = ["itemId"];

    private SQLClient persistClient;

    public function init() returns Error? {
        mysql:Client|sql:Error dbClient = new (host = host, user = user, password = password, database = database, port = port);
        if dbClient is sql:Error {
            return <Error>error(dbClient.message());
        }

        self.persistClient = check new (dbClient, self.entityName, self.tableName, self.keyFields, self.fieldMetadata);
    }

    remote function create(MedicalItem value) returns MedicalItem|Error {
        _ = check self.persistClient.runInsertQuery(value);
        return value;
    }

    remote function readByKey(int key) returns MedicalItem|Error {
        return <MedicalItem>check self.persistClient.runReadByKeyQuery(MedicalItem, key);
    }

    remote function read() returns stream<MedicalItem, Error?> {
        stream<anydata, sql:Error?>|Error result = self.persistClient.runReadQuery(MedicalItem);
        if result is Error {
            return new stream<MedicalItem, Error?>(new MedicalItemStream((), result));
        } else {
            return new stream<MedicalItem, Error?>(new MedicalItemStream(result));
        }
    }

    remote function execute(sql:ParameterizedQuery filterClause) returns stream<MedicalItem, Error?> {
        stream<anydata, sql:Error?>|Error result = self.persistClient.runExecuteQuery(filterClause, MedicalItem);
        if result is Error {
            return new stream<MedicalItem, Error?>(new MedicalItemStream((), result));
        } else {
            return new stream<MedicalItem, Error?>(new MedicalItemStream(result));
        }
    }

    remote function update(MedicalItem 'object) returns Error? {
        _ = check self.persistClient.runUpdateQuery('object);
    }

    remote function delete(MedicalItem 'object) returns Error? {
        _ = check self.persistClient.runDeleteQuery('object);
    }

    public function close() returns Error? {
        return self.persistClient.close();
    }

}

public class MedicalItemStream {
    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|MedicalItem value;|}|Error? {
        if self.err is Error {
            return self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                record {|MedicalItem value;|} nextRecord = {value: <MedicalItem>streamValue.value};
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

