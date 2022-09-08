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

client class MultipleAssociationsClient {

    private final string entityName = "MultipleAssociations";
    private final sql:ParameterizedQuery tableName = `MultipleAssociations`;
    private final map<FieldMetadata> fieldMetadata = {
        id: {columnName: "id", 'type: int},
        name: {columnName: "name", 'type: string},
        "profile.id": {columnName: "profileId", 'type: int, relation: {entityName: "profile", refTable: "Profiles", refField: "id"}},
        "profile.name": {'type: int, relation: {entityName: "profile", refTable: "Profiles", refField: "name"}},
        "user.id": {columnName: "userId", 'type: int, relation: {entityName: "user", refTable: "Users", refField: "id"}},
        "user.name": {'type: int, relation: {entityName: "user", refTable: "Users", refField: "name"}}
    };
    private string[] keyFields = ["id"];
    private final map<JoinMetadata> joinMetadata = {
        profile: {refTable: "Profiles", refFields: ["id"], joinColumns: ["profileId"]},
        user: {refTable: "Users", refFields: ["id"], joinColumns: ["userId"]}
    };

    private SQLClient persistClient;

    public function init() returns error? {
        mysql:Client dbClient = check new (host = host, user = user, password = password, database = database, port = port);
        self.persistClient = check new (dbClient, self.entityName, self.tableName, self.keyFields, self.fieldMetadata, self.joinMetadata);
    }

    remote function create(MultipleAssociations value) returns MultipleAssociations|error {
        if value.profile is Profile {
            ProfileClient profileClient = check new ProfileClient();
            boolean exists = check profileClient->exists(<Profile> value.profile);
            if !exists {
                value.profile = check profileClient->create(<Profile> value.profile);
            }
        }

        if value.user is User {
            UserClient userClient = check new UserClient();
            boolean exists = check userClient->exists(<User> value.user);
            if !exists {
                value.user = check userClient->create(<User> value.user);
            }
        }
    
        sql:ExecutionResult _ = check self.persistClient.runInsertQuery(value);
        return value;
    }

    remote function readByKey(int key, MultipleAssociationsRelations[] include = []) returns MultipleAssociations|error {
        return <MultipleAssociations> check self.persistClient.runReadByKeyQuery(MultipleAssociations, key, include);
    }

    remote function read(map<anydata>? filter = (), MultipleAssociationsRelations[] include = []) returns stream<MultipleAssociations, error?>|error {
        stream<anydata, error?> result = check self.persistClient.runReadQuery(MultipleAssociations, filter, include);
        return new stream<MultipleAssociations, error?>(new MultipleAssociationsStream(result, include));
    }

    remote function update(record {} 'object, map<anydata> filter) returns error? {
        _ = check self.persistClient.runUpdateQuery('object, filter);

        if 'object["profile"] is record {} {
            record {} profileEntity = <record {}> 'object["profile"];
            ProfileClient profileClient = check new ProfileClient();
            stream<MultipleAssociations, error?> multipleAssociationsStream = check self->read(filter, [UserEntity]);

            // TODO: replace this with more optimized code after adding support for advanced queries
            check from MultipleAssociations ma in multipleAssociationsStream
                do {
                    if ma.profile is Profile {
                        check profileClient->update(profileEntity, {"id": (<Profile> ma.profile).id});
                    }
                };
        }
        
        if 'object["user"] is record {} {
            record {} userEntity = <record {}> 'object["user"];
            UserClient userClient = check new UserClient();
            stream<MultipleAssociations, error?> multipleAssociationsStream = check self->read(filter, [UserEntity]);

            // TODO: replace this with more optimized code after adding support for advanced queries
            check from MultipleAssociations ma in multipleAssociationsStream
                do {
                    if ma.user is User {
                        check userClient->update(userEntity, {"id": (<User> ma.user).id});
                    }
                };
        }
    }

    remote function delete(map<anydata> filter) returns error? {
        _ = check self.persistClient.runDeleteQuery(filter);
    }

    remote function exists(MultipleAssociations multipleAssociations) returns boolean|error {
        MultipleAssociations|error result = self->readByKey(multipleAssociations.id);
        if result is MultipleAssociations {
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

public enum MultipleAssociationsRelations {
    ProfileEntity = "profile",
    UserEntity = "user"
}

public class MultipleAssociationsStream {
    private stream<anydata, error?> anydataStream;
    private MultipleAssociationsRelations[] include;

    public isolated function init(stream<anydata, error?> anydataStream, MultipleAssociationsRelations[] include = []) {
        self.anydataStream = anydataStream;
        self.include = include;
    }

    public isolated function next() returns record {|MultipleAssociations value;|}|error? {
        var streamValue = self.anydataStream.next();
        if streamValue is () {
            return streamValue;
        } else if (streamValue is error) {
            return streamValue;
        } else {
            record {|MultipleAssociations value;|} nextRecord = {value: <MultipleAssociations>streamValue.value};
            return nextRecord;
        }
    }

    public isolated function close() returns error? {
        return self.anydataStream.close();
    }
}
