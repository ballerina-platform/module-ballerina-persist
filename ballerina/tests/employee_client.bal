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

    private final string entityName = "Employee";
    private final sql:ParameterizedQuery tableName = `Employees`;
    private final map<FieldMetadata> fieldMetadata = {
        id: {columnName: "id", 'type: int},
        name: {columnName: "name", 'type: string},
        "company.id": {columnName: "companyId", 'type: int, relation: {entityName: "company", refTable: "Companies", refField: "id"}},
        "company.name": {'type: string, relation: {entityName: "company", refTable: "Companies", refField: "name"}}
    };
    private string[] keyFields = ["id"];
    private final map<JoinMetadata> joinMetadata = {
        company: {entity: Company, fieldName: "company", refTable: "Companies", refFields: ["id"], joinColumns: ["companyId"]}
    };

    private SQLClient persistClient;

    public function init() returns error? {
        mysql:Client dbClient = check new (host = host, user = user, password = password, database = database, port = port);
        self.persistClient = check new (dbClient, self.entityName, self.tableName, self.keyFields, self.fieldMetadata, self.joinMetadata);
    }

    remote function create(Employee value) returns Employee|error {
        if value.company is Company {
            CompanyClient companyClient = check new CompanyClient();
            boolean exists = check companyClient->exists(<Company> value.company);
            if !exists {
                value.company = check companyClient->create(<Company> value.company);
            }
        }
    
        sql:ExecutionResult _ = check self.persistClient.runInsertQuery(value);
        return value;
    }

    remote function readByKey(int key, EmployeeRelations[] include = []) returns Employee|error {
        return <Employee> check self.persistClient.runReadByKeyQuery(Employee, key, include);
    }

    remote function read(map<anydata>? filter = (), EmployeeRelations[] include = []) returns stream<Employee, error?>|error {
        stream<anydata, error?> result = check self.persistClient.runReadQuery(Employee, filter, include);
        return new stream<Employee, error?>(new EmployeeStream(result, include));
    }

    remote function update(record {} 'object, map<anydata> filter) returns error? {
        _ = check self.persistClient.runUpdateQuery('object, filter);
        
        if 'object["company"] is record {} {
            record {} companyEntity = <record {}> 'object["company"];
            CompanyClient companyClient = check new CompanyClient();
            stream<Employee, error?> employeeStream = check self->read(filter, [CompanyEntity]);

            // TODO: replace this with more optimized code after adding support for advanced queries
            check from Employee employee in employeeStream
                do {
                    if employee.company is Company {
                        check companyClient->update(companyEntity, {"id": (<Company> employee.company).id});
                    }
                };
        }
    }

    remote function delete(map<anydata> filter) returns error? {
        _ = check self.persistClient.runDeleteQuery(filter);
    }

    remote function exists(Employee employee) returns boolean|error {
        Employee|error result = self->readByKey(employee.id);
        if result is Employee {
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

public enum EmployeeRelations {
    CompanyEntity = "company"
}

public class EmployeeStream {
    private stream<anydata, error?> anydataStream;
    private EmployeeRelations[] include;

    public isolated function init(stream<anydata, error?> anydataStream, EmployeeRelations[] include = []) {
        self.anydataStream = anydataStream;
        self.include = include;
    }

    public isolated function next() returns record {|Employee value;|}|error? {
        var streamValue = self.anydataStream.next();
        if streamValue is () {
            return streamValue;
        } else if (streamValue is error) {
            return streamValue;
        } else {
            record {|Employee value;|} nextRecord = {value: <Employee>streamValue.value};
            return nextRecord;
        }
    }

    public isolated function close() returns error? {
        return self.anydataStream.close();
    }
}
