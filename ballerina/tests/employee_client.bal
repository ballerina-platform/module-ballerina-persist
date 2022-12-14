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

client class EmployeeClient {
    *AbstractPersistClient;

    private final string entityName = "Employee";
    private final sql:ParameterizedQuery tableName = `Employees`;
    private final map<FieldMetadata> fieldMetadata = {
        id: {columnName: "id", 'type: int},
        name: {columnName: "name", 'type: string},
        "company.id": {columnName: "companyId", 'type: int, relation: {entityName: "company", refTable: "Companies", refField: "id", refColumnName: "id"}},
        "company.name": {'type: string, relation: {entityName: "company", refTable: "Companies", refField: "name", refColumnName: "name"}}
    };
    private string[] keyFields = ["id"];
    private final map<JoinMetadata> joinMetadata = {
        company: {entity: Company, fieldName: "company", refTable: "Companies", refColumns: ["id"], joinColumns: ["companyId"]}
    };

    private SQLClient persistClient;

    public function init() returns Error? {
        mysql:Client|sql:Error dbClient = new (host = host, user = user, password = password, database = database, port = port);
        if dbClient is sql:Error {
            return <Error>error(dbClient.message());
        }

        self.persistClient = check new (dbClient, self.entityName, self.tableName, self.keyFields, self.fieldMetadata, self.joinMetadata);
    }

    remote function create(Employee value) returns Employee|Error {
        if value.company is Company {
            CompanyClient companyClient = check new CompanyClient();
            boolean exists = check companyClient->exists(<Company>value.company);
            if !exists {
                value.company = check companyClient->create(<Company>value.company);
            }
        }

        _ = check self.persistClient.runInsertQuery(value);
        return value;
    }

    remote function readByKey(int key, EmployeeRelations[] include = []) returns Employee|Error {
        return <Employee>check self.persistClient.runReadByKeyQuery(Employee, key, include);
    }

    remote function read(EmployeeRelations[] include = []) returns stream<Employee, Error?> {
        stream<anydata, sql:Error?>|Error result = self.persistClient.runReadQuery(Employee, include);
        if result is Error {
            return new stream<Employee, Error?>(new EmployeeStream((), result));
        } else {
            return new stream<Employee, Error?>(new EmployeeStream(result));
        }
    }

    remote function update(record {} 'object) returns Error? {
        _ = check self.persistClient.runUpdateQuery('object);

        if 'object["company"] is Company {
            Company companyEntity = <Company>'object["company"];
            CompanyClient companyClient = check new CompanyClient();
            check companyClient->update(companyEntity);
        }
    }

    remote function delete(Employee 'object) returns Error? {
        _ = check self.persistClient.runDeleteQuery('object);
    }

    remote function exists(Employee employee) returns boolean|Error {
        Employee|Error result = self->readByKey(employee.id);
        if result is Employee {
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

public enum EmployeeRelations {
    CompanyEntity = "company"
}

public class EmployeeStream {
    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|Employee value;|}|Error? {
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
                record {|Employee value;|} nextRecord = {value: <Employee>streamValue.value};
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
