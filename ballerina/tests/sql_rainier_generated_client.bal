// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/jballerina.java;
import ballerinax/mysql;

const EMPLOYEE = "employees";
const WORKSPACE = "workspaces";
const BUILDING = "buildings";
const DEPARTMENT = "departments";
const ORDER_ITEM = "orderitems";

public isolated client class SQLRainierClient {
    *AbstractPersistClient;

    private final mysql:Client dbClient;

    private final map<SQLClient> persistClients = {};

    private final record {|SQLMetadata...;|} metadata = {
        [EMPLOYEE] : {
            entityName: "Employee",
            tableName: "Employee",
            fieldMetadata: {
                empNo: {columnName: "empNo"},
                firstName: {columnName: "firstName"},
                lastName: {columnName: "lastName"},
                birthDate: {columnName: "birthDate"},
                gender: {columnName: "gender"},
                hireDate: {columnName: "hireDate"},
                departmentDeptNo: {columnName: "departmentDeptNo"},
                workspaceWorkspaceId: {columnName: "workspaceWorkspaceId"},
                "department.deptNo": {relation: {entityName: "department", refField: "deptNo"}},
                "department.deptName": {relation: {entityName: "department", refField: "deptName"}},
                "workspace.workspaceId": {relation: {entityName: "workspace", refField: "workspaceId"}},
                "workspace.workspaceType": {relation: {entityName: "workspace", refField: "workspaceType"}},
                "workspace.locationBuildingCode": {relation: {entityName: "workspace", refField: "locationBuildingCode"}}
            },
            keyFields: ["empNo"],
            joinMetadata: {
                department: {entity: Department, fieldName: "department", refTable: "Department", refColumns: ["deptNo"], joinColumns: ["departmentDeptNo"], 'type: ONE_TO_MANY},
                workspace: {entity: Workspace, fieldName: "workspace", refTable: "Workspace", refColumns: ["workspaceId"], joinColumns: ["workspaceWorkspaceId"], 'type: ONE_TO_MANY}
            }
        },
        [WORKSPACE] : {
            entityName: "Workspace",
            tableName: "Workspace",
            fieldMetadata: {
                workspaceId: {columnName: "workspaceId"},
                workspaceType: {columnName: "workspaceType"},
                locationBuildingCode: {columnName: "locationBuildingCode"},
                "location.buildingCode": {relation: {entityName: "location", refField: "buildingCode"}},
                "location.city": {relation: {entityName: "location", refField: "city"}},
                "location.state": {relation: {entityName: "location", refField: "state"}},
                "location.country": {relation: {entityName: "location", refField: "country"}},
                "location.postalCode": {relation: {entityName: "location", refField: "postalCode"}},
                "location.type": {relation: {entityName: "location", refField: "type"}},
                "employees[].empNo": {relation: {entityName: "employees", refField: "empNo"}},
                "employees[].firstName": {relation: {entityName: "employees", refField: "firstName"}},
                "employees[].lastName": {relation: {entityName: "employees", refField: "lastName"}},
                "employees[].birthDate": {relation: {entityName: "employees", refField: "birthDate"}},
                "employees[].gender": {relation: {entityName: "employees", refField: "gender"}},
                "employees[].hireDate": {relation: {entityName: "employees", refField: "hireDate"}},
                "employees[].departmentDeptNo": {relation: {entityName: "employees", refField: "departmentDeptNo"}},
                "employees[].workspaceWorkspaceId": {relation: {entityName: "employees", refField: "workspaceWorkspaceId"}}
            },
            keyFields: ["workspaceId"],
            joinMetadata: {
                location: {entity: Building, fieldName: "location", refTable: "Building", refColumns: ["buildingCode"], joinColumns: ["locationBuildingCode"], 'type: ONE_TO_MANY},
                employees: {entity: Employee, fieldName: "employees", refTable: "Employee", refColumns: ["workspaceWorkspaceId"], joinColumns: ["workspaceId"], 'type: MANY_TO_ONE}
            }
        },
        [BUILDING] : {
            entityName: "Building",
            tableName: "Building",
            fieldMetadata: {
                buildingCode: {columnName: "buildingCode"},
                city: {columnName: "city"},
                state: {columnName: "state"},
                country: {columnName: "country"},
                postalCode: {columnName: "postalCode"},
                'type: {columnName: "type"},
                "workspaces[].workspaceId": {relation: {entityName: "workspaces", refField: "workspaceId"}},
                "workspaces[].workspaceType": {relation: {entityName: "workspaces", refField: "workspaceType"}},
                "workspaces[].locationBuildingCode": {relation: {entityName: "location", refField: "locationBuildingCode"}}
            },
            keyFields: ["buildingCode"],
            joinMetadata: {workspaces: {entity: Workspace, fieldName: "workspaces", refTable: "Workspace", refColumns: ["locationBuildingCode"], joinColumns: ["buildingCode"], 'type: MANY_TO_ONE}}
        },
        [DEPARTMENT] : {
            entityName: "Department",
            tableName: "Department",
            fieldMetadata: {
                deptNo: {columnName: "deptNo"},
                deptName: {columnName: "deptName"},
                "employees[].empNo": {relation: {entityName: "employees", refField: "empNo"}},
                "employees[].firstName": {relation: {entityName: "employees", refField: "firstName"}},
                "employees[].lastName": {relation: {entityName: "employees", refField: "lastName"}},
                "employees[].birthDate": {relation: {entityName: "employees", refField: "birthDate"}},
                "employees[].gender": {relation: {entityName: "employees", refField: "gender"}},
                "employees[].hireDate": {relation: {entityName: "employees", refField: "hireDate"}},
                "employees[].departmentDeptNo": {relation: {entityName: "employees", refField: "departmentDeptNo"}},
                "employees[].workspaceWorkspaceId": {relation: {entityName: "employees", refField: "workspaceWorkspaceId"}}
            },
            keyFields: ["deptNo"],
            joinMetadata: {employees: {entity: Employee, fieldName: "employees", refTable: "Employee", refColumns: ["departmentDeptNo"], joinColumns: ["deptNo"], 'type: MANY_TO_ONE}}
        },
        [ORDER_ITEM] : {
            entityName: "OrderItem",
            tableName: "OrderItem",
            fieldMetadata: {
                orderId: {columnName: "orderId"},
                itemId: {columnName: "itemId"},
                quantity: {columnName: "quantity"},
                notes: {columnName: "notes"}
            },
            keyFields: ["orderId", "itemId"]
        }
    };

    public isolated function init() returns Error? {
        mysql:Client|error dbClient = new (host = host, user = user, password = password, database = database, port = port);
        if dbClient is error {
            return <Error>error(dbClient.message());
        }
        self.dbClient = dbClient;
        
        self.persistClients[EMPLOYEE] = check new (dbClient, self.metadata.get(EMPLOYEE).cloneReadOnly());
        self.persistClients[WORKSPACE] = check new (self.dbClient, self.metadata.get(WORKSPACE).cloneReadOnly());
        self.persistClients[BUILDING] = check new (self.dbClient, self.metadata.get(BUILDING).cloneReadOnly());
        self.persistClients[DEPARTMENT] = check new (self.dbClient, self.metadata.get(DEPARTMENT).cloneReadOnly());
        self.persistClients[ORDER_ITEM] = check new (self.dbClient, self.metadata.get(ORDER_ITEM).cloneReadOnly());
    }

    isolated resource function get employees(EmployeeTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get employees/[string empNo](EmployeeTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post employees(EmployeeInsert[] data) returns string[]|Error {
        lock {
            _ = check self.persistClients.get(EMPLOYEE).runBatchInsertQuery(data.clone());
        }
        return from EmployeeInsert inserted in data
            select inserted.empNo;
    }

    isolated resource function put employees/[string empNo](EmployeeUpdate value) returns Employee|Error {
        lock {
            _ = check self.persistClients.get(EMPLOYEE).runUpdateQuery(empNo, value.clone());
        }
        return self->/employees/[empNo].get();
    }

    isolated resource function delete employees/[string empNo]() returns Employee|Error {
        Employee result = check self->/employees/[empNo].get();
        lock {
            _ = check self.persistClients.get(EMPLOYEE).runDeleteQuery(empNo);
        }
        return result;
    }

    isolated resource function get workspaces(WorkspaceTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get workspaces/[string workspaceId](WorkspaceTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post workspaces(WorkspaceInsert[] data) returns string[]|Error {
        lock {
            _ = check self.persistClients.get(WORKSPACE).runBatchInsertQuery(data.clone());
        }
        return from WorkspaceInsert inserted in data
            select inserted.workspaceId;
    }

    isolated resource function put workspaces/[string workspaceId](WorkspaceUpdate value) returns Workspace|Error {
        lock {
            _ = check self.persistClients.get(WORKSPACE).runUpdateQuery(workspaceId, value.clone());
        }
        return self->/workspaces/[workspaceId].get();
    }

    isolated resource function delete workspaces/[string workspaceId]() returns Workspace|Error {
        Workspace result = check self->/workspaces/[workspaceId].get();
        lock {
            _ = check self.persistClients.get(WORKSPACE).runDeleteQuery(workspaceId);
        }
        return result;
    }

    isolated resource function get buildings(BuildingTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get buildings/[string buildingCode](BuildingTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post buildings(BuildingInsert[] data) returns string[]|Error {
        lock {
            _ = check self.persistClients.get(BUILDING).runBatchInsertQuery(data.clone());
        }
        return from BuildingInsert inserted in data
            select inserted.buildingCode;
    }

    isolated resource function put buildings/[string buildingCode](BuildingUpdate value) returns Building|Error {
        lock {
            _ = check self.persistClients.get(BUILDING).runUpdateQuery(buildingCode, value.clone());
        }
        return self->/buildings/[buildingCode].get();
    }

    isolated resource function delete buildings/[string buildingCode]() returns Building|Error {
        Building result = check self->/buildings/[buildingCode].get();
        lock {
            _ = check self.persistClients.get(BUILDING).runDeleteQuery(buildingCode);
        }
        return result;
    }

    isolated resource function get departments(DepartmentTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get departments/[string deptNo](DepartmentTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post departments(DepartmentInsert[] data) returns string[]|Error {
        lock {
            _ = check self.persistClients.get(DEPARTMENT).runBatchInsertQuery(data.clone());
        }
        return from DepartmentInsert inserted in data
            select inserted.deptNo;
    }

    isolated resource function put departments/[string deptNo](DepartmentUpdate value) returns Department|Error {
        lock {
            _ = check self.persistClients.get(DEPARTMENT).runUpdateQuery(deptNo, value.clone());
        }
        return self->/departments/[deptNo].get();
    }

    isolated resource function delete departments/[string deptNo]() returns Department|Error {
        Department result = check self->/departments/[deptNo].get();
        lock {
            _ = check self.persistClients.get(DEPARTMENT).runDeleteQuery(deptNo);
        }
        return result;
    }

    isolated resource function get orderitems(OrderItemTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get orderitems/[string orderId]/[string itemId](OrderItemTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post orderitems(OrderItemInsert[] data) returns [string, string][]|Error {
        lock {
            _ = check self.persistClients.get(ORDER_ITEM).runBatchInsertQuery(data.clone());
        }
        return from OrderItemInsert inserted in data
            select [inserted.orderId, inserted.itemId];
    }

    isolated resource function put orderitems/[string orderId]/[string itemId](OrderItemUpdate value) returns OrderItem|Error {
        lock {
            _ = check self.persistClients.get(ORDER_ITEM).runUpdateQuery({"orderId": orderId, "itemId": itemId}, value.clone());
        }
        return self->/orderitems/[orderId]/[itemId].get();
    }

    isolated resource function delete orderitems/[string orderId]/[string itemId]() returns OrderItem|Error {
        OrderItem result = check self->/orderitems/[orderId]/[itemId].get();
        lock {
            _ = check self.persistClients.get(ORDER_ITEM).runDeleteQuery({"orderId": orderId, "itemId": itemId});
        }
        return result;
    }

    public function close() returns Error? {
        error? result = self.dbClient.close();
        if result is error {
            return <Error>error(result.message());
        }
        return result;
    }
}

