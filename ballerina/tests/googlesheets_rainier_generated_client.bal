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

import ballerinax/googleapis.sheets;
import ballerina/http;
import ballerina/jballerina.java;

const EMPLOYEE = "employees";
const WORKSPACE = "workspaces";
const BUILDING = "buildings";
const DEPARTMENT = "departments";
const ORDER_ITEM = "orderitems";

public client class GoogleSheetsRainierClient {
    *AbstractPersistClient;

    private final sheets:Client googleSheetClient;
    private final http:Client httpClient;

    private final map<GoogleSheetsClient> persistClients;

    public function init() returns Error? {

        final record {|SheetMetadata...;|} metadata = {
            [EMPLOYEE] : {
                entityName: "Employee",
                tableName: "Employee",
                fieldMetadata: {
                    empNo: {columnName: "empNo", columnId: "A"},
                    firstName: {columnName: "firstName", columnId: "B"},
                    lastName: {columnName: "lastName", columnId: "C"},
                    birthDate: {columnName: "birthDate", columnId: "D"},
                    gender: {columnName: "gender", columnId: "E"},
                    hireDate: {columnName: "hireDate", columnId: "F"},
                    departmentDeptNo: {columnName: "departmentDeptNo", columnId: "G"},
                    workspaceWorkspaceId: {columnName: "workspaceWorkspaceId", columnId: "H"}
                },
                keyFields: ["empNo"],
                range: "A:I",
                dataTypes: {empNo: "string", firstName: "string", lastName: "string", birthDate: "time:Date", gender: "string", hireDate: "time:Date", departmentDeptNo: "string", workspaceWorkspaceId: "string"},
                queryOne: self.queryOneEmployees,
                query: self.queryEmployees
            },
            [WORKSPACE] : {
                entityName: "Workspace",
                tableName: "Workspace",
                fieldMetadata: {
                    workspaceId: {columnName: "workspaceId", columnId: "A"},
                    workspaceType: {columnName: "workspaceType", columnId: "B"},
                    locationBuildingCode: {columnName: "locationBuildingCode", columnId: "C"}
                },
                range: "A:D",
                dataTypes: {workspaceId: "string", workspaceType: "string", locationBuildingCode: "string"},
                keyFields: ["workspaceId"],
                query: self.queryWorkspaces,
                queryOne: self.queryOneWorkspaces,
                associationsMethods: {
                    "employees": self.queryWorkspacesEmployees
                }
            },
            [BUILDING] : {
                entityName: "Building",
                tableName: "Building",
                fieldMetadata: {
                    buildingCode: {columnName: "buildingCode", columnId: "A"},
                    city: {columnName: "city", columnId: "B"},
                    state: {columnName: "state", columnId: "C"},
                    country: {columnName: "country", columnId: "D"},
                    postalCode: {columnName: "postalCode", columnId: "E"},
                    'type: {columnName: "type", columnId: "F"}
                },
                range: "A:G",
                dataTypes: {buildingCode: "string", city: "string", state: "string", country: "string", postalCode: "string", 'type: "string"},
                keyFields: ["buildingCode"],
                query: self.queryBuildings,
                queryOne: self.queryOneBuildings,
                associationsMethods: {
                    "workspaces": self.queryBuildingsWorkspaces
                }
            },
            [DEPARTMENT] : {
                entityName: "Department",
                tableName: "Department",
                fieldMetadata: {
                    deptNo: {columnName: "deptNo", columnId: "A"},
                    deptName: {columnName: "deptName", columnId: "C"}
                },
                range: "A:C",
                dataTypes: {deptNo: "string", deptName: "string"},
                keyFields: ["deptNo"],
                query: self.queryDepartments,
                queryOne: self.queryOneDepartments,
                associationsMethods: {
                    "employees": self.queryDepartmentsEmployees
                }
            },
            [ORDER_ITEM] : {
                entityName: "OrderItem",
                tableName: "OrderItem",
                fieldMetadata: {
                    orderId: {columnName: "orderId", columnId: "A"},
                    itemId: {columnName: "itemId", columnId: "B"},
                    quantity: {columnName: "quantity", columnId: "C"},
                    notes: {columnName: "notes", columnId: "D"}
                },
                range: "A:E",
                dataTypes: {orderId: "string", itemId: "string", quantity: "int", notes: "string"},
                keyFields: ["orderId", "itemId"],
                query: self.queryOrderItems,
                queryOne: self.queryOneOrderItems
            }
        };
        sheets:ConnectionConfig sheetsClientConfig = {
            auth: {
                clientId: clientId,
                clientSecret: clientSecret,
                refreshUrl: sheets:REFRESH_URL,
                refreshToken: refreshToken
            }
        };

        http:ClientConfiguration httpClientConfiguration = {
            auth: {
                clientId: clientId,
                clientSecret: clientSecret,
                refreshUrl: sheets:REFRESH_URL,
                refreshToken: refreshToken
            }
        };
        http:Client|error httpClient = new ("https://docs.google.com/spreadsheets", httpClientConfiguration);

        if httpClient is error {
            return <Error>error(httpClient.message());
        }
        sheets:Client|error googleSheetClient = new (sheetsClientConfig);
        if googleSheetClient is error {
            return <Error>error(googleSheetClient.message());
        }
        self.googleSheetClient = googleSheetClient;
        self.httpClient = httpClient;
        map<int> sheetIds = check getSheetIds(self.googleSheetClient, metadata, spreadsheetId);
        self.persistClients = {
            [EMPLOYEE] : check new (self.googleSheetClient, self.httpClient, metadata.get(EMPLOYEE), spreadsheetId, sheetIds.get(EMPLOYEE)),
            [WORKSPACE] : check new (self.googleSheetClient, self.httpClient, metadata.get(WORKSPACE), spreadsheetId, sheetIds.get(WORKSPACE)),
            [BUILDING] : check new (self.googleSheetClient, self.httpClient, metadata.get(BUILDING), spreadsheetId, sheetIds.get(BUILDING)),
            [DEPARTMENT] : check new (self.googleSheetClient, self.httpClient, metadata.get(DEPARTMENT), spreadsheetId, sheetIds.get(DEPARTMENT)),
            [ORDER_ITEM] : check new (self.googleSheetClient, self.httpClient, metadata.get(ORDER_ITEM), spreadsheetId, sheetIds.get(ORDER_ITEM))
        };
    }

    isolated resource function get employees(EmployeeTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "query"
    } external;

    isolated resource function get employees/[string empNo](EmployeeTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "queryOne"
    } external;

    isolated resource function post employees(EmployeeInsert[] data) returns string[]|Error {
        _ = check self.persistClients.get(EMPLOYEE).runBatchInsertQuery(data);
        return from EmployeeInsert inserted in data
            select inserted.empNo;
    }

    isolated resource function put employees/[string empNo](EmployeeUpdate value) returns Employee|Error {
        _ = check self.persistClients.get(EMPLOYEE).runUpdateQuery(empNo, value);
        return self->/employees/[empNo].get();
    }

    isolated resource function delete employees/[string empNo]() returns Employee|Error {
        Employee result = check self->/employees/[empNo].get();
        _ = check self.persistClients.get(EMPLOYEE).runDeleteQuery(empNo);
        return result;
    }

    isolated resource function get workspaces(WorkspaceTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "query"
    } external;

    isolated resource function get workspaces/[string workspaceId](WorkspaceTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "queryOne"
    } external;

    isolated resource function post workspaces(WorkspaceInsert[] data) returns string[]|Error {
        _ = check self.persistClients.get(WORKSPACE).runBatchInsertQuery(data);
        return from WorkspaceInsert inserted in data
            select inserted.workspaceId;
    }

    isolated resource function put workspaces/[string workspaceId](WorkspaceUpdate value) returns Workspace|Error {
        _ = check self.persistClients.get(WORKSPACE).runUpdateQuery(workspaceId, value);
        return self->/workspaces/[workspaceId].get();
    }

    isolated resource function delete workspaces/[string workspaceId]() returns Workspace|Error {
        Workspace result = check self->/workspaces/[workspaceId].get();
        _ = check self.persistClients.get(WORKSPACE).runDeleteQuery(workspaceId);
        return result;
    }

    isolated resource function get buildings(BuildingTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "query"
    } external;

    isolated resource function get buildings/[string buildingCode](BuildingTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "queryOne"
    } external;

    isolated resource function post buildings(BuildingInsert[] data) returns string[]|Error {
        _ = check self.persistClients.get(BUILDING).runBatchInsertQuery(data);
        return from BuildingInsert inserted in data
            select inserted.buildingCode;
    }

    isolated resource function put buildings/[string buildingCode](BuildingUpdate value) returns Building|Error {
        _ = check self.persistClients.get(BUILDING).runUpdateQuery(buildingCode, value);
        return self->/buildings/[buildingCode].get();
    }

    isolated resource function delete buildings/[string buildingCode]() returns Building|Error {
        Building result = check self->/buildings/[buildingCode].get();
        _ = check self.persistClients.get(BUILDING).runDeleteQuery(buildingCode);
        return result;
    }

    isolated resource function get departments(DepartmentTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "query"
    } external;

    isolated resource function get departments/[string deptNo](DepartmentTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "queryOne"
    } external;

    isolated resource function post departments(DepartmentInsert[] data) returns string[]|Error {
        _ = check self.persistClients.get(DEPARTMENT).runBatchInsertQuery(data);
        return from DepartmentInsert inserted in data
            select inserted.deptNo;
    }

    isolated resource function put departments/[string deptNo](DepartmentUpdate value) returns Department|Error {
        _ = check self.persistClients.get(DEPARTMENT).runUpdateQuery(deptNo, value);
        return self->/departments/[deptNo].get();
    }

    isolated resource function delete departments/[string deptNo]() returns Department|Error {
        Department result = check self->/departments/[deptNo].get();
        _ = check self.persistClients.get(DEPARTMENT).runDeleteQuery(deptNo);
        return result;
    }

    isolated resource function get orderitems(OrderItemTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "query"
    } external;

    isolated resource function get orderitems/[string orderId]/[string itemId](OrderItemTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "queryOne"
    } external;

    isolated resource function post orderitems(OrderItemInsert[] data) returns [string, string][]|Error {
        _ = check self.persistClients.get(ORDER_ITEM).runBatchInsertQuery(data);
        return from OrderItemInsert inserted in data
            select [inserted.orderId, inserted.itemId];
    }

    isolated resource function put orderitems/[string orderId]/[string itemId](OrderItemUpdate value) returns OrderItem|Error {
        _ = check self.persistClients.get(ORDER_ITEM).runUpdateQuery({"orderId": orderId, "itemId": itemId}, value);
        return self->/orderitems/[orderId]/[itemId].get();
    }

    isolated resource function delete orderitems/[string orderId]/[string itemId]() returns OrderItem|Error {
        OrderItem result = check self->/orderitems/[orderId]/[itemId].get();
        _ = check self.persistClients.get(ORDER_ITEM).runDeleteQuery({"orderId": orderId, "itemId": itemId});
        return result;
    }

    public function close() returns Error? {
        return ();
    }


    private isolated function queryEmployeesStream(EmployeeTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "queryStream"
    } external;

    private isolated function queryBuildingsStream(BuildingTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "queryStream"
    } external;

    private isolated function queryDepartmentsStream(DepartmentTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "queryStream"
    } external;

    private isolated function queryWorkspacesStream(WorkspaceTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "queryStream"
    } external;

    private isolated function queryOrderItemsStream(OrderItemTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "queryStream"
    } external;

    private isolated function queryEmployees(string[] fields) returns stream<record {}, Error?>|Error{
        stream<Employee, Error?> employeesStream = self.queryEmployeesStream();
        stream<Department, Error?> departmentStream = self.queryDepartmentsStream();
        stream<Workspace, Error?> workspacesStream = self.queryWorkspacesStream();

        record{}[] outputArray = check from record {} 'object in employeesStream
            outer join var department in departmentStream
            on 'object.departmentDeptNo equals department?.deptNo
            outer join var workspace in workspacesStream
            on 'object.workspaceWorkspaceId equals workspace?.workspaceId
            select filterRecord(
                {
                ...'object,
                "department": department,
                "workspace": workspace
            }, fields);
        return outputArray.toStream();
    }

    private isolated function queryOneEmployees(anydata key) returns record {}|InvalidKeyError {
        stream<Employee, Error?> employeesStream = self.queryEmployeesStream();
        stream<Department, Error?> departmenttStream = self.queryDepartmentsStream();
        stream<Workspace, Error?> workspacesStream = self.queryWorkspacesStream();
        error? unionResult = from record {} 'object in employeesStream
            where self.persistClients.get(EMPLOYEE).getKey('object) == key
            outer join var department in departmenttStream
            on 'object.departmentDeptNo equals department?.deptNo
            outer join var workspace in workspacesStream
            on 'object.workspaceWorkspaceId equals workspace?.workspaceId
            do {
                return {
                    ...'object,
                    "department": department,
                    "workspace": workspace
                };
            };
        if unionResult is error {
            return <InvalidKeyError>error(unionResult.message());
        }
        return <InvalidKeyError>error("Invalid key: " + key.toString());
    }
    private isolated function queryBuildings(string[] fields) returns stream<record {}, Error?>|Error {
        stream<Building, Error?> buildingsStream = self.queryBuildingsStream();
        record{}[] outputArray = check from record {} 'object in buildingsStream
            select filterRecord({
                ...'object
            }, fields);
        return outputArray.toStream();
    }

    private isolated function queryOneBuildings(anydata key) returns record {}|InvalidKeyError {
        stream<Building, Error?> buildingsStream = self.queryBuildingsStream();
        error? unionResult = from record {} 'object in buildingsStream
            where self.persistClients.get(BUILDING).getKey('object) == key
            do {
                return {
                    ...'object
                };
            };
        if unionResult is error {
            return <InvalidKeyError>error(unionResult.message());
        }
        return <InvalidKeyError>error("Invalid key: " + key.toString());
    }

    private isolated function queryBuildingsWorkspaces(record {} value, string[] fields) returns record {}[]|Error {
        stream<Workspace, Error?> workspacesStream = self.queryWorkspacesStream();
        return from record {} 'object in workspacesStream
            where 'object.locationBuildingCode == value["buildingCode"]
            select filterRecord({
                ...'object
            }, fields);
    }

    private isolated function queryDepartments(string[] fields) returns stream<record {}, Error?>|Error {
        stream<Department, Error?> departmenttStream = self.queryDepartmentsStream();
        record{}[] outputArray = check from record {} 'object in departmenttStream
            select filterRecord({
                ...'object
            }, fields);
        return outputArray.toStream();
    }

    private isolated function queryOneDepartments(anydata key) returns record {}|InvalidKeyError {
        stream<Department, Error?> departmenttStream = self.queryDepartmentsStream();
        error? unionResult = from record {} 'object in departmenttStream
            where self.persistClients.get(DEPARTMENT).getKey('object) == key
            do {
                return {
                    ...'object
                };
            };
        if unionResult is error {
            return <InvalidKeyError>error(unionResult.message());
        }
        return <InvalidKeyError>error("Invalid key: " + key.toString());
    }

    private isolated function queryDepartmentsEmployees(record {} value, string[] fields) returns record {}[]|Error {
        stream<Employee, Error?> employeesStream = self.queryEmployeesStream();
        return from record {} 'object in employeesStream
            where 'object["departmentDeptNo"] == value["deptNo"]
            select filterRecord({
                ...'object
            }, fields);
    }

    private isolated function queryWorkspaces(string[] fields) returns stream<record {}, Error?>|Error {
        stream<Workspace, Error?> workspacesStream = self.queryWorkspacesStream();
        stream<Building, Error?> buildingsStream = self.queryBuildingsStream();
        record{}[] outputArray = check from record {} 'object in workspacesStream
            outer join var location in buildingsStream
            on 'object.locationBuildingCode equals location?.buildingCode
            select filterRecord({
                ...'object,
                "location": location
            }, fields);
        return outputArray.toStream();
    }

    private isolated function queryOneWorkspaces(anydata key) returns record {}|InvalidKeyError {
        stream<Workspace, Error?> workspacesStream = self.queryWorkspacesStream();
        stream<Building, Error?> buildingsStream = self.queryBuildingsStream();
        error? unionResult = from record {} 'object in workspacesStream
            where self.persistClients.get(WORKSPACE).getKey('object) == key
            outer join var location in buildingsStream
            on 'object.locationBuildingCode equals location?.buildingCode
            do {
                return {
                    ...'object,
                    "location": location
                };
            };
        if unionResult is error {
            return <InvalidKeyError>error(unionResult.message());
        }
        return <InvalidKeyError>error("Invalid key: " + key.toString());
    }

    private isolated function queryWorkspacesEmployees(record {} value, string[] fields) returns record {}[]|Error {
        stream<Employee, Error?> employeesStream = self.queryEmployeesStream();
        return from record {} 'object in employeesStream
            where 'object.workspaceWorkspaceId == value["workspaceId"]
            select filterRecord({
                ...'object
            }, fields);
    }

    private isolated function queryOrderItems(string[] fields) returns stream<record {|anydata...;|}, Error?>|Error {
        stream<OrderItem, Error?> orderItemsStream = self.queryOrderItemsStream();
        record{}[] outputArray = check from record {} 'object in orderItemsStream
            select filterRecord({
                ...'object
            }, fields);
        return outputArray.toStream();
    }

    private isolated function queryOneOrderItems(anydata key) returns record {}|InvalidKeyError {
        stream<OrderItem, Error?> orderItemsStream = self.queryOrderItemsStream();
        error? unionResult = from record {} 'object in orderItemsStream
            where self.persistClients.get(ORDER_ITEM).getKey('object) == key
            do {
                return {
                    ...'object
                };
            };
        if unionResult is error {
            return <InvalidKeyError>error(unionResult.message());
        }
        return <InvalidKeyError>error("Invalid key: " + key.toString());
    }

}

