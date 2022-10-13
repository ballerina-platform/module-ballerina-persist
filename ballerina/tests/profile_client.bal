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

client class ProfileClient {

    private final string entityName = "Profile";
    private final sql:ParameterizedQuery tableName = `Profiles`;
    private final map<FieldMetadata> fieldMetadata = {
        id: {columnName: "id", 'type: int},
        name: {columnName: "name", 'type: string},
        "user.id": {columnName: "userId", 'type: int, relation: {entityName: "user", refTable: "Users", refField: "id"}},
        "user.name": {'type: int, relation: {entityName: "user", refTable: "Users", refField: "name"}}
    };
    private string[] keyFields = ["id"];
    private final map<JoinMetadata> joinMetadata = {
        user: {entity: User, fieldName: "user", refTable: "Users", refFields: ["id"], joinColumns: ["userId"]}
    };

    private SQLClient persistClient;

    public function init() returns error? {
        mysql:Client dbClient = check new (host = host, user = user, password = password, database = database, port = port);
        self.persistClient = check new (dbClient, self.entityName, self.tableName, self.keyFields, self.fieldMetadata, self.joinMetadata);
    }

    remote function create(Profile value) returns Profile|error {
        if value.user is User {
            UserClient userClient = check new UserClient();
            boolean exists = check userClient->exists(<User>value.user);
            if !exists {
                value.user = check userClient->create(<User>value.user);
            }
        }

        sql:ExecutionResult _ = check self.persistClient.runInsertQuery(value);
        return value;
    }

    remote function readByKey(int key, ProfileRelations[] include = []) returns Profile|error {
        return <Profile>check self.persistClient.runReadByKeyQuery(Profile, key, include);
    }

    remote function read(ProfileRelations[] include = []) returns stream<Profile, error?> {
        stream<anydata, error?>|error result = self.persistClient.runReadQuery(Profile, include);
        if result is error {
            return new stream<Profile, error?>(new ProfileStream((), result));
        } else {
            return new stream<Profile, error?>(new ProfileStream(result));
        }
    }

    remote function execute(sql:ParameterizedQuery filterClause) returns stream<Profile, error?> {
        stream<anydata, error?>|error result = self.persistClient.runExecuteQuery(filterClause, Profile);
        if result is error {
            return new stream<Profile, error?>(new ProfileStream((), result));
        } else {
            return new stream<Profile, error?>(new ProfileStream(result));
        }
    }

    remote function update(Profile 'object) returns error? {
        _ = check self.persistClient.runUpdateQuery('object);

        if 'object["user"] is User {
            User userEntity = <User>'object["user"];
            UserClient userClient = check new UserClient();
            check userClient->update(userEntity);
        }
    }

    remote function delete(Profile 'object) returns error? {
        _ = check self.persistClient.runDeleteQuery('object);
    }

    remote function exists(Profile profile) returns boolean|error {
        Profile|error result = self->readByKey(profile.id);
        if result is Profile {
            return true;
        } else if result is InvalidKeyError {
            return false;
        } else {
            return result;
        }
    }

    function close() returns error? {
        return self.persistClient.close();
    }

}

public enum ProfileRelations {
    UserEntity = "user"
}

public class ProfileStream {
    private stream<anydata, error?>? anydataStream;
    private error? err;

    public isolated function init(stream<anydata, error?>? anydataStream, error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|Profile value;|}|error? {
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
                record {|Profile value;|} nextRecord = {value: check streamValue.value.cloneWithType(Profile)};
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
