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

public client class SheetsRainierClient {
    *AbstractPersistClient;

    private final sheets:Client googleSheetClient;
    private final http:Client httpClient;

    private final map<GoogleSheetsClient> persistClients;

    private final record {|SheetMetadata...;|} metadata = {
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
            range: "A:H",
            keyFields: ["empNo"]
        },
        [WORKSPACE] : {
            entityName: "Workspace",
            tableName: "Workspace",
            fieldMetadata: {
                workspaceId: {columnName: "workspaceId", columnId: "A"},
                workspaceType: {columnName: "workspaceType", columnId: "B"},
                locationBuildingCode: {columnName: "locationBuildingCode", columnId: "C"}
            },
            range: "A:C",
            keyFields: ["workspaceId"]
        },
        [BUILDING] : {
            entityName: "Building",
            tableName: "Building",
            fieldMetadata: {
                buildingCode: {columnName: "buildingCode", columnId: "A"},
                city: {columnName: "city", columnId: "B"},
                state: {columnName: "state", columnId: "C"},
                country: {columnName: "country", columnId: "D"},
                postalCode: {columnName: "postalCode", columnId: "E"}
            },
            range: "A:E",
            keyFields: ["buildingCode"]
        },
        [DEPARTMENT] : {
            entityName: "Department",
            tableName: "Department",
            fieldMetadata: {
                deptNo: {columnName: "deptNo", columnId: "A"},
                deptName: {columnName: "deptName", columnId: "B"}
            },
            range: "A:B",
            keyFields: ["deptNo"]
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
            range: "A:B",
            keyFields: ["orderId", "itemId"]
        }
    };

    public function init() returns Error? {
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
        self.persistClients = {
            [EMPLOYEE] : check new (self.googleSheetClient, self.httpClient, self.metadata.get(EMPLOYEE), spreadsheetId),
            [WORKSPACE] : check new (self.googleSheetClient, self.httpClient, self.metadata.get(WORKSPACE), spreadsheetId),
            [BUILDING] : check new (self.googleSheetClient, self.httpClient, self.metadata.get(BUILDING), spreadsheetId),
            [DEPARTMENT] : check new (self.googleSheetClient, self.httpClient, self.metadata.get(DEPARTMENT), spreadsheetId),
            [ORDER_ITEM] : check new (self.googleSheetClient, self.httpClient, self.metadata.get(ORDER_ITEM), spreadsheetId)
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

    isolated resource function post employees(EmployeeInsert[] data) returns string[]|error {
        _ = check self.persistClients.get(EMPLOYEE).runBatchInsertQuery(data);
        return from EmployeeInsert inserted in data
            select inserted.empNo;
    }

    isolated resource function put employees/[string empNo](EmployeeUpdate value) returns Employee|error {
        _ = check self.persistClients.get(EMPLOYEE).runUpdateQuery(empNo, value);
        return self->/employees/[empNo].get();
    }

    isolated resource function delete employees/[string empNo]() returns Employee|error {
        Employee result = check self->/employees/[empNo].get();
        _ = check self.persistClients.get(EMPLOYEE).runDeleteQuery(empNo);
        return result;
    }

    isolated resource function get workspaces(WorkspaceTargetType targetType = <>) returns stream<targetType, error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "query"
    } external;

    isolated resource function get workspaces/[string workspaceId](WorkspaceTargetType targetType = <>) returns targetType|error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "queryOne"
    } external;

    isolated resource function post workspaces(WorkspaceInsert[] data) returns string[]|error {
        _ = check self.persistClients.get(WORKSPACE).runBatchInsertQuery(data);
        return from WorkspaceInsert inserted in data
            select inserted.workspaceId;
    }

    isolated resource function put workspaces/[string workspaceId](WorkspaceUpdate value) returns Workspace|error {
        _ = check self.persistClients.get(WORKSPACE).runUpdateQuery(workspaceId, value);
        return self->/workspaces/[workspaceId].get();
    }

    isolated resource function delete workspaces/[string workspaceId]() returns Workspace|error {
        Workspace result = check self->/workspaces/[workspaceId].get();
        _ = check self.persistClients.get(WORKSPACE).runDeleteQuery(workspaceId);
        return result;
    }

    isolated resource function get buildings(BuildingTargetType targetType = <>) returns stream<targetType, error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "query"
    } external;

    isolated resource function get buildings/[string buildingCode](BuildingTargetType targetType = <>) returns targetType|error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "queryOne"
    } external;

    isolated resource function post buildings(BuildingInsert[] data) returns string[]|error {
        _ = check self.persistClients.get(BUILDING).runBatchInsertQuery(data);
        return from BuildingInsert inserted in data
            select inserted.buildingCode;
    }

    isolated resource function put buildings/[string buildingCode](BuildingUpdate value) returns Building|error {
        _ = check self.persistClients.get(BUILDING).runUpdateQuery(buildingCode, value);
        return self->/buildings/[buildingCode].get();
    }

    isolated resource function delete buildings/[string buildingCode]() returns Building|error {
        Building result = check self->/buildings/[buildingCode].get();
        _ = check self.persistClients.get(BUILDING).runDeleteQuery(buildingCode);
        return result;
    }

    isolated resource function get departments(DepartmentTargetType targetType = <>) returns stream<targetType, error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "query"
    } external;

    isolated resource function get departments/[string deptNo](DepartmentTargetType targetType = <>) returns targetType|error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "queryOne"
    } external;

    isolated resource function post departments(DepartmentInsert[] data) returns string[]|error {
        _ = check self.persistClients.get(DEPARTMENT).runBatchInsertQuery(data);
        return from DepartmentInsert inserted in data
            select inserted.deptNo;
    }

    isolated resource function put departments/[string deptNo](DepartmentUpdate value) returns Department|error {
        _ = check self.persistClients.get(DEPARTMENT).runUpdateQuery(deptNo, value);
        return self->/departments/[deptNo].get();
    }

    isolated resource function delete departments/[string deptNo]() returns Department|error {
        Department result = check self->/departments/[deptNo].get();
        _ = check self.persistClients.get(DEPARTMENT).runDeleteQuery(deptNo);
        return result;
    }

    isolated resource function get orderitems(OrderItemTargetType targetType = <>) returns stream<targetType, error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "query"
    } external;

    isolated resource function get orderitems/[string orderId]/[string itemId](OrderItemTargetType targetType = <>) returns targetType|error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.GoogleSheetsProcessor",
        name: "queryOne"
    } external;

    isolated resource function post orderitems(OrderItemInsert[] data) returns [string, string][]|error {
        _ = check self.persistClients.get(ORDER_ITEM).runBatchInsertQuery(data);
        return from OrderItemInsert inserted in data
            select [inserted.orderId, inserted.itemId];
    }

    isolated resource function put orderitems/[string orderId]/[string itemId](OrderItemUpdate value) returns OrderItem|error {
        _ = check self.persistClients.get(ORDER_ITEM).runUpdateQuery({"orderId": orderId, "itemId": itemId}, value);
        return self->/orderitems/[orderId]/[itemId].get();
    }

    isolated resource function delete orderitems/[string orderId]/[string itemId]() returns OrderItem|error {
        OrderItem result = check self->/orderitems/[orderId]/[itemId].get();
        _ = check self.persistClients.get(ORDER_ITEM).runDeleteQuery({"orderId": orderId, "itemId": itemId});
        return result;
    }

    public function close() returns error? {
        return ();
    }
}

