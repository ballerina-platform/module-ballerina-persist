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

client class UserClient {

    private final string entityName = "User";
    private final sql:ParameterizedQuery tableName = `Users`;
    private final map<FieldMetadata> fieldMetadata = {
        id: {columnName: "id", 'type: int},
        name: {columnName: "name", 'type: string},
        "profile.id": {'type: int, relation: {entityName: "profile", refTable: "Profiles", refField: "id"}},
        "profile.name": {'type: string, relation: {entityName: "profile", refTable: "Profiles", refField: "name"}}
    };
    private string[] keyFields = ["id"];
    private final map<JoinMetadata> joinMetadata = {
        profile: {entity: Profile, fieldName: "profile", refTable: "Profiles", refFields: ["userId"], joinColumns: ["id"]}
    };

    private SQLClient persistClient;

    public function init() returns Error? {
        mysql:Client|sql:Error dbClient = new (host = host, user = user, password = password, database = database, port = port);
        if dbClient is sql:Error {
            return <SQLError>dbClient;
        }

        self.persistClient = check new (dbClient, self.entityName, self.tableName, self.keyFields, self.fieldMetadata, self.joinMetadata);
    }

    remote function create(User value) returns User|Error {
        _ = check self.persistClient.runInsertQuery(value);
        return value;
    }

    remote function readByKey(int key, UserRelations[] include = []) returns User|Error {
        return <User>check self.persistClient.runReadByKeyQuery(User, key, include);
    }

    remote function read(map<anydata>? filter = (), UserRelations[] include = []) returns stream<User, Error?> {
        stream<anydata, sql:Error?>|Error result = self.persistClient.runReadQuery(User, filter, include);
        if result is Error {
            return new stream<User, Error?>(new UserStream((), result));
        } else {
            return new stream<User, Error?>(new UserStream(result));
        }
    }

    remote function execute(sql:ParameterizedQuery filterClause) returns stream<User, Error?> {
        stream<anydata, sql:Error?>|Error result = self.persistClient.runExecuteQuery(filterClause, User);
        if result is Error {
            return new stream<User, Error?>(new UserStream((), result));
        } else {
            return new stream<User, Error?>(new UserStream(result));
        }
    }
    remote function update(record {} 'object, map<anydata> filter) returns Error? {
        _ = check self.persistClient.runUpdateQuery('object, filter);
    }

    remote function delete(map<anydata> filter) returns Error? {
        _ = check self.persistClient.runDeleteQuery(filter);
    }

    remote function exists(User user) returns boolean|Error {
        User|Error result = self->readByKey(user.id);
        if result is User {
            return true;
        } else if result is InvalidKeyError {
            return false;
        } else {
            return result;
        }
    }

    function close() returns Error? {
        return self.persistClient.close();
    }

}

public enum UserRelations {
    ProfileEntity = "profile"
}

public class UserStream {
    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|User value;|}|Error? {
        if self.err is Error {
            return self.err;
        } else if self.anydataStream is stream<anydata, error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <SQLError>streamValue;
            } else {
                record {|User value;|} nextRecord = {value: <User> streamValue.value};
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
                return <SQLError>e;
            }
        }
    }
}
