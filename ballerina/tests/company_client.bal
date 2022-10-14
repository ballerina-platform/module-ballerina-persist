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

    public function init() returns Error? {
        mysql:Client|sql:Error dbClient = new (host = host, user = user, password = password, database = database, port = port);
        if dbClient is sql:Error {
            return <Error>error(dbClient.message());
        }

        self.persistClient = check new (dbClient, self.entityName, self.tableName, self.keyFields, self.fieldMetadata, self.joinMetadata);
    }

    remote function create(Company value) returns Company|Error {
        _ = check self.persistClient.runInsertQuery(value);
        return value;
    }

    remote function readByKey(int key, CompanyRelations[] include = []) returns Company|Error {
        return <Company>check self.persistClient.runReadByKeyQuery(Company, key, include);
    }

    remote function read(CompanyRelations[] include = []) returns stream<Company, Error?> {
        stream<anydata, sql:Error?>|Error result = self.persistClient.runReadQuery(Company, include);
        if result is Error {
            return new stream<Company, Error?>(new CompanyStream((), result));
        } else {
            return new stream<Company, Error?>(new CompanyStream(result, (), include, self.persistClient));
        }
    }

    remote function execute(sql:ParameterizedQuery filterClause) returns stream<Company, Error?> {
        stream<anydata, sql:Error?>|Error result = self.persistClient.runExecuteQuery(filterClause, Company);
        if result is Error {
            return new stream<Company, Error?>(new CompanyStream((), result));
        } else {
            return new stream<Company, Error?>(new CompanyStream(result));
        }
    }

    remote function update(Company 'object) returns Error? {
        _ = check self.persistClient.runUpdateQuery('object);
    }

    remote function delete(Company 'object) returns Error? {
        _ = check self.persistClient.runDeleteQuery('object);
    }

    remote function exists(Company company) returns boolean|Error {
        Company|Error result = self->readByKey(company.id);
        if result is Company {
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

public enum CompanyRelations {
    EmployeeEntity = "employee"
}

public class CompanyStream {
    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;
    private CompanyRelations[]? include;
    private SQLClient? persistClient;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = (), CompanyRelations[]? include = (), SQLClient? persistClient = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
        self.include = include;
        self.persistClient = persistClient;
    }

    public isolated function next() returns record {|Company value;|}|Error? {
        if self.err is Error {
            return self.err;
        } else if self.anydataStream is stream<anydata, error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is error) {
                return <Error>error(streamValue.message());
            } else {
                record {|Company value;|} nextRecord = {value: <Company>streamValue.value};
                check (<SQLClient>self.persistClient).getManyRelations(nextRecord.value, <CompanyRelations[]>self.include);
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
