// Copyright (c) 2022 WSO2 LLC. (http://www.wso2.com) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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

public client class ComplexTypeClient {
    *AbstractPersistClient;

    private final string entityName = "ComplexType";
    private final sql:ParameterizedQuery tableName = `ComplexTypes`;

    private final map<FieldMetadata> fieldMetadata = {
        complexTypeId: {columnName: "complexTypeId", 'type: int, autoGenerated: true},
        civilType: {columnName: "civilType", 'type: time:Civil},
        timeOfDayType: {columnName: "timeOfDayType", 'type: time:TimeOfDay},
        dateType: {columnName: "dateType", 'type: time:Date}
    };
    private string[] keyFields = ["complexTypeId"];

    private SQLClient persistClient;

    public function init() returns Error? {
        mysql:Client|sql:Error dbClient = new (host = host, user = user, password = password, database = database, port = port);
        if dbClient is sql:Error {
            return <Error>error(dbClient.message());
        }
        self.persistClient = check new (dbClient, self.entityName, self.tableName, self.keyFields, self.fieldMetadata);
    }

    remote function create(ComplexType value) returns ComplexType|Error {
        sql:ExecutionResult result = check self.persistClient.runInsertQuery(value);
        return {complexTypeId: <int>result.lastInsertId, civilType: value.civilType, timeOfDayType: value.timeOfDayType, dateType: value.dateType};
    }

    remote function readByKey(int key) returns ComplexType|Error {
        return <ComplexType>check self.persistClient.runReadByKeyQuery(ComplexType, key);
    }

    remote function read() returns stream<ComplexType, Error?> {
        stream<anydata, sql:Error?>|Error result = self.persistClient.runReadQuery(ComplexType);
        if result is Error {
            return new stream<ComplexType, Error?>(new ComplexTypeStream((), result));
        } else {
            return new stream<ComplexType, Error?>(new ComplexTypeStream(result));
        }
    }

    remote function update(ComplexType value) returns Error? {
        _ = check self.persistClient.runUpdateQuery(value);
    }

    remote function delete(ComplexType value) returns Error? {
        _ = check self.persistClient.runDeleteQuery(value);
    }

    remote function exists(ComplexType complexType) returns boolean|Error {
        ComplexType|Error result = self->readByKey(complexType.complexTypeId);
        if result is ComplexType {
            return true;
        } else if result is InvalidKeyError {
            return false;
        } else {
            return result;
        }
    }

    public function close() returns Error? {
        return self.persistClient.close();
    }
}

public class ComplexTypeStream {

    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|ComplexType value;|}|Error? {
        if self.err is Error {
            return <Error>self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                record {|ComplexType value;|} nextRecord = {value: <ComplexType>streamValue.value};
                return nextRecord;
            }
        } else {
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

