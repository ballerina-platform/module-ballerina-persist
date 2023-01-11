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
    *AbstractPersistClient;

    private final string entityName = "Profile";
    private final sql:ParameterizedQuery tableName = `Profiles`;
    private final map<FieldMetadata> fieldMetadata = {
        id: {columnName: "id", 'type: int},
        name: {columnName: "name", 'type: string},
        "owner.id": {columnName: "ownerId", 'type: int, relation: {entityName: "owner", refField: "id"}},
        "owner.name": {'type: int, relation: {entityName: "owner", refField: "name"}}
    };
    private string[] keyFields = ["id"];
    private final map<JoinMetadata> joinMetadata = {
        owner: {entity: Owner, fieldName: "owner", refTable: "Owner", refColumns: ["id"], joinColumns: ["ownerId"],  'type: ONE_TO_ONE}
    };

    private SQLClient persistClient;

    public function init() returns Error? {
        mysql:Client|sql:Error dbClient = new (host = host, user = user, password = password, database = database, port = port, options = connectionOptions);
        if dbClient is sql:Error {
            return <Error>error(dbClient.message());
        }

        self.persistClient = check new (dbClient, self.entityName, self.tableName, self.keyFields, self.fieldMetadata, self.joinMetadata);
    }

    remote function create(Profile value) returns Profile|Error {
        if value.owner is Owner {
            OwnerClient ownerClient = check new OwnerClient();
            boolean exists = check ownerClient->exists(<Owner>value.owner);
            if !exists {
                value.owner = check ownerClient->create(<Owner>value.owner);
            }
        }

        _ = check self.persistClient.runInsertQuery(value);
        return value;
    }

    remote function readByKey(int key, ProfileRelations[] include = []) returns Profile|Error {
        return <Profile>check self.persistClient.runReadByKeyQuery(Profile, key, include);
    }

    remote function read(ProfileRelations[] include = []) returns stream<Profile, Error?> {
        stream<anydata, sql:Error?>|Error result = self.persistClient.runReadQuery(Profile, include);
        if result is error {
            return new stream<Profile, Error?>(new ProfileStream((), result));
        } else {
            return new stream<Profile, Error?>(new ProfileStream(result));
        }
    }

    remote function update(Profile 'object, ProfileRelations[] updateAssociations = []) returns Error? {
        _ = check self.persistClient.runUpdateQuery('object);

        if 'object["owner"] is Owner {
            Owner ownerEntity = <Owner>'object["owner"];
            OwnerClient ownerClient = check new OwnerClient();
            check ownerClient->update(ownerEntity);
        }
    }

    remote function delete(Profile 'object) returns Error? {
        _ = check self.persistClient.runDeleteQuery('object);
    }

    remote function exists(Profile profile) returns boolean|Error {
        Profile|Error result = self->readByKey(profile.id);
        if result is Profile {
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

public enum ProfileRelations {
    owner
}

public class ProfileStream {
    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|Profile value;|}|Error? {
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
                record {|Profile value;|} nextRecord = {value: <Profile>streamValue.value};
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
