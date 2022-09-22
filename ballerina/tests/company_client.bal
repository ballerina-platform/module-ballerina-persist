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

client class CompanyClient {

    private final string entityName = "Company";
    private final sql:ParameterizedQuery tableName = `Companies`;
    private final map<FieldMetadata> fieldMetadata = {
        id: {columnName: "id", 'type: int},
        name: {columnName: "name", 'type: string},
        "employees[].id": {'type: int, relation: {entityName: "employee", refTable: "Employees", refField: "id"}},
        "employees[].name": {'type: string, relation: {entityName: "employee", refTable: "Employees", refField: "name"}}
    };
    private string[] keyFields = ["id"];
    private final map<JoinMetadata> joinMetadata = {
        employee: {entity: Employee, fieldName: "employees", refTable: "Employees", refFields: ["companyId"], joinColumns: ["id"], 'type: MANY}
    };

    private SQLClient persistClient;

    public function init() returns error? {
        mysql:Client dbClient = check new (host = host, user = user, password = password, database = database, port = port);
        self.persistClient = check new (dbClient, self.entityName, self.tableName, self.keyFields, self.fieldMetadata, self.joinMetadata);
    }

    remote function create(Company value) returns Company|error {
        _ = check self.persistClient.runInsertQuery(value);
        return value;
    }

    remote function readByKey(int key, CompanyRelations[] include = []) returns Company|error {
        return <Company> check self.persistClient.runReadByKeyQuery(Company, key, include);
    }

    remote function read(map<anydata>? filter = (), CompanyRelations[] include = []) returns stream<Company, error?>|error {
        stream<anydata, error?> result = check self.persistClient.runReadQuery(Company, filter, include);
        return new stream<Company, error?>(new CompanyStream(result, include, self.persistClient));
    }

    remote function update(record {} 'object, map<anydata> filter) returns error? {
        _ = check self.persistClient.runUpdateQuery('object, filter);
    }

    remote function delete(map<anydata> filter) returns error? {
        _ = check self.persistClient.runDeleteQuery(filter);
    }

    remote function exists(Company company) returns boolean|error {
        Company|error result = self->readByKey(company.id);
        if result is Company {
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

public enum CompanyRelations {
    EmployeeEntity = "employee"
}

public class CompanyStream {
    private stream<anydata, error?> anydataStream;
    private SQLClient persistClient;
    private CompanyRelations[] include;

    public isolated function init(stream<anydata, error?> anydataStream, CompanyRelations[] include, SQLClient persistClient) {
        self.anydataStream = anydataStream;
        self.include = include;
        self.persistClient = persistClient;
    }

    public isolated function next() returns record {|Company value;|}|error? {
        var streamValue = self.anydataStream.next();
        if streamValue is () {
            return streamValue;
        } else if (streamValue is error) {
            return streamValue;
        } else {
            record {|Company value;|} nextRecord = {value: check streamValue.value.cloneWithType(Company)};
            check self.persistClient.getManyRelations(nextRecord.value, self.include);
            return nextRecord;
        }
    }

    public isolated function close() returns error? {
        return self.anydataStream.close();
    }
}
