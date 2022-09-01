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
        profile: {refTable: "Profiles", refFields: ["userId"], joinColumns: ["id"]}
    };

    private SQLClient persistClient;

    public function init() returns error? {
        mysql:Client dbClient = check new (host = HOST, user = USER, password = PASSWORD, database = DATABASE, port = PORT);
        self.persistClient = check new (dbClient, self.entityName, self.tableName, self.keyFields, self.fieldMetadata, self.joinMetadata);
    }

    remote function create(User value) returns User|error {
        sql:ExecutionResult result = check self.persistClient.runInsertQuery(value);
        
        int key;
        if result.lastInsertId is () {
            key = value.id;
        } else {
            key = <int>result.lastInsertId;
        }

        User user = {
            id: key,
            name: value.name
        };

        if value.profile is Profile {
            ProfileClient profileClient = check new ProfileClient();
            Profile profile = <Profile>value.profile.clone();
            profile.user = user;
            boolean exists = check profileClient->exists(<Profile>value.profile);
            if !exists {
                user.profile = check profileClient->create(profile);
            } else {
                check profileClient->update({"user.id": user.id}, {id: profile.id});
            }
        }
        return user;
    }

    remote function readByKey(int key, UserRelations[] include = []) returns User|error {
        return (check self.persistClient.runReadByKeyQuery(User, key, include)).cloneWithType(User);
    }

    remote function read(map<anydata>? filter = (), UserRelations[] include = []) returns stream<User, error?>|error {
        stream<anydata, error?> result = check self.persistClient.runReadQuery(User, filter, include);
        return new stream<User, error?>(new UserStream(result));
    }

    remote function update(record {} 'object, map<anydata> filter) returns error? {
        _ = check self.persistClient.runUpdateQuery('object, filter);
    }

    remote function delete(map<anydata> filter) returns error? {
        _ = check self.persistClient.runDeleteQuery(filter);
    }

    remote function exists(User user) returns boolean|error {
        User|error result = self->readByKey(user.id);
        if result is User {
            return true;
        } else if result is InvalidKey {
            return false;
        } else {
            return result;
        }
    }

    function close() returns error? {
        return self.persistClient.close();
    }

}

public enum UserRelations {
    profile
}

public class UserStream {
    private stream<anydata, error?> anydataStream;

    public isolated function init(stream<anydata, error?> anydataStream) {
        self.anydataStream = anydataStream;
    }

    public isolated function next() returns record {|User value;|}|error? {
        var streamValue = self.anydataStream.next();
        if streamValue is () {
            return streamValue;
        } else if (streamValue is error) {
            return streamValue;
        } else {
            record {|User value;|} nextRecord = {value: check streamValue.value.cloneWithType(User)};
            return nextRecord;
        }
    }

    public isolated function close() returns error? {
        return self.anydataStream.close();
    }
}

