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

const EMPLOYEE = "employees";
const WORKSPACE = "workspaces";
const DEPARTMENT = "departments";
const BUILDING = "buildings";
const ORDER_ITEM = "orderitems";

table<Building> key(buildingCode) buildings = table [];
table<Department> key(deptNo) departments = table [];
table<Workspace> key(workspaceId) workspaces = table [];
table<Employee> key(empNo) employees = table [];
table<OrderItem> key(orderId, itemId) orderItems = table [];

public client class InMemoryRainierClient {
    *AbstractPersistClient;

    private final map<InMemoryClient> persistClients;

    table<Building> key(buildingCode) buildings = buildings;
    table<Department> key(deptNo) departments = departments;
    table<Workspace> key(workspaceId) workspaces = workspaces;
    table<Employee> key(empNo) employees = employees;
    table<OrderItem> key(orderId, itemId) orderItems = orderItems;

    public function init() returns Error? {
        final map<TableMetadata> metadata = {
            [BUILDING] : {
                keyFields: ["buildingCode"],
                query: self.queryBuildings,
                queryOne: self.queryOneBuildings,
                associationsMethods: {
                    "workspaces": self.queryBuildingsWorkspaces
                }
            },
            [DEPARTMENT] : {
                keyFields: ["deptNo"],
                query: self.queryDepartments,
                queryOne: self.queryOneDepartments,
                associationsMethods: {
                    "employees": self.queryDepartmentsEmployees
                }
            },
            [WORKSPACE] : {
                keyFields: ["workspaceId"],
                query: self.queryWorkspaces,
                queryOne: self.queryOneWorkspaces,
                associationsMethods: {
                    "employees": self.queryWorkspacesEmployees
                }
            },
            [EMPLOYEE] : {
                keyFields: ["empNo"],
                query: self.queryEmployees,
                queryOne: self.queryOneEmployees
            },
            [ORDER_ITEM] : {
                keyFields: ["orderId", "itemId"],
                query: self.queryOrderItems,
                queryOne: self.queryOneOrderItems
            }
        };

        self.persistClients = {
            [BUILDING] : check new (metadata.get(BUILDING)),
            [DEPARTMENT] : check new (metadata.get(DEPARTMENT)),
            [WORKSPACE] : check new (metadata.get(WORKSPACE)),
            [EMPLOYEE] : check new (metadata.get(EMPLOYEE)),
            [ORDER_ITEM] : check new (metadata.get(ORDER_ITEM))
        };
    }

    isolated resource function get buildings(BuildingTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "query"
    } external;

    isolated resource function get buildings/[string buildingCode](BuildingTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "queryOne"
    } external;

    isolated resource function post buildings(BuildingInsert[] data) returns string[]|Error {
        string[] keys = [];
        foreach BuildingInsert value in data {
            if self.buildings.hasKey(value.buildingCode) {
                return <DuplicateKeyError>error("Duplicate key: " + value.buildingCode);
            }
            self.buildings.put(value.clone());
            keys.push(value.buildingCode);
        }
        return keys;
    }

    isolated resource function put buildings/[string buildingCode](BuildingUpdate value) returns Building|Error {
        if !self.buildings.hasKey(buildingCode) {
            return <InvalidKeyError>error("Not found: " + buildingCode);
        }

        Building building = self.buildings.get(buildingCode);
        foreach var [k, v] in value.entries() {
            building[k] = v;
        }

        self.buildings.put(building);
        return building;
    }

    isolated resource function delete buildings/[string buildingCode]() returns Building|Error {
        if !self.buildings.hasKey(buildingCode) {
            return <InvalidKeyError>error("Not found: " + buildingCode);
        }
        return self.buildings.remove(buildingCode);
    }

    isolated resource function get departments(DepartmentTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "query"
    } external;

    isolated resource function get departments/[string deptNo](DepartmentTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "queryOne"
    } external;

    isolated resource function post departments(DepartmentInsert[] data) returns string[]|Error {
        string[] keys = [];
        foreach DepartmentInsert value in data {
            if self.departments.hasKey(value.deptNo) {
                return <DuplicateKeyError>error("Duplicate key: " + value.deptNo);
            }
            self.departments.put(value.clone());
            keys.push(value.deptNo);
        }
        return keys;
    }

    isolated resource function put departments/[string deptNo](DepartmentUpdate value) returns Department|Error {
        if !self.departments.hasKey(deptNo) {
            return <InvalidKeyError>error("Not found: " + deptNo);
        }
        Department department = self.departments.get(deptNo);
        foreach var [k, v] in value.entries() {
            department[k] = v;
        }

        self.departments.put(department);
        return department;
    }

    isolated resource function delete departments/[string deptNo]() returns Department|Error {
        if !self.departments.hasKey(deptNo) {
            return <InvalidKeyError>error("Not found: " + deptNo);
        }
        return self.departments.remove(deptNo);
    }

    isolated resource function get workspaces(WorkspaceTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "query"
    } external;

    isolated resource function get workspaces/[string workspaceId](WorkspaceTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "queryOne"
    } external;

    isolated resource function post workspaces(WorkspaceInsert[] data) returns string[]|Error {
        string[] keys = [];
        foreach WorkspaceInsert value in data {
            if self.workspaces.hasKey(value.workspaceId) {
                return <DuplicateKeyError>error("Duplicate key: " + value.workspaceId);
            }
            self.workspaces.put(value.clone());
            keys.push(value.workspaceId);
        }
        return keys;
    }

    isolated resource function put workspaces/[string workspaceId](WorkspaceUpdate value) returns Workspace|Error {
        if !self.workspaces.hasKey(workspaceId) {
            return <InvalidKeyError>error("Not found: " + workspaceId);
        }
        Workspace workspace = self.workspaces.get(workspaceId);
        foreach var [k, v] in value.entries() {
            workspace[k] = v;
        }

        self.workspaces.put(workspace);
        return workspace;
    }

    isolated resource function delete workspaces/[string workspaceId]() returns Workspace|Error {
        if !self.workspaces.hasKey(workspaceId) {
            return <InvalidKeyError>error("Not found: " + workspaceId);
        }
        return self.workspaces.remove(workspaceId);
    }

    isolated resource function get employees(EmployeeTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "query"
    } external;

    isolated resource function get employees/[string empNo](EmployeeTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "queryOne"
    } external;

    isolated resource function post employees(EmployeeInsert[] data) returns string[]|Error {
        string[] keys = [];
        foreach EmployeeInsert value in data {
            if self.employees.hasKey(value.empNo) {
                return <DuplicateKeyError>error("Duplicate key: " + value.empNo);
            }
            self.employees.put(value.clone());
            keys.push(value.empNo);
        }
        return keys;
    }

    isolated resource function put employees/[string empNo](EmployeeUpdate value) returns Employee|Error {
        if !self.employees.hasKey(empNo) {
            return <InvalidKeyError>error("Not found: " + empNo);
        }
        Employee employee = self.employees.get(empNo);
        foreach var [k, v] in value.entries() {
            employee[k] = v;
        }

        self.employees.put(employee);
        return employee;
    }

    isolated resource function delete employees/[string empNo]() returns Employee|Error {
        if !self.employees.hasKey(empNo) {
            return <InvalidKeyError>error("Not found: " + empNo);
        }
        return self.employees.remove(empNo);
    }

    public function close() returns Error? {
        return ();
    }

    isolated resource function get orderitems(OrderItemTargetType targetType = <>) returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "query"
    } external;

    isolated resource function get orderitems/[string orderId]/[string itemId](OrderItemTargetType targetType = <>) returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.datastore.InMemoryProcessor",
        name: "queryOne"
    } external;

    isolated resource function post orderitems(OrderItemInsert[] data) returns [string, string][]|Error {
        [string, string][] keys = [];
        foreach OrderItemInsert value in data {
            if self.orderItems.hasKey([value.orderId, value.itemId]) {
                return <DuplicateKeyError>error("Duplicate key: " + [value.orderId, value.itemId].toString());
            }
            self.orderItems.put(value.clone());
            keys.push([value.orderId, value.itemId]);
        }
        return keys;
    }

    isolated resource function put orderitems/[string orderId]/[string itemId](OrderItemUpdate value) returns OrderItem|Error {
        if !self.orderItems.hasKey([orderId, itemId]) {
            return <InvalidKeyError>error("Not found: " + [orderId, itemId].toString());
        }
        OrderItem orderItem = self.orderItems.get([orderId, itemId]);
        foreach var [k, v] in value.entries() {
            orderItem[k] = v;
        }

        return orderItem;
    }

    isolated resource function delete orderitems/[string orderId]/[string itemId]() returns OrderItem|Error {
        if !self.orderItems.hasKey([orderId, itemId]) {
            return <InvalidKeyError>error("Not found: " + [orderId, itemId].toString());
        }
        return self.orderItems.remove([orderId, itemId]);
    }

    private isolated function queryEmployees(string[] fields) returns stream<record {}, Error?> {
        return from record {} 'object in self.employees
            outer join var department in self.departments
            on 'object.departmentDeptNo equals department?.deptNo
            outer join var workspace in self.workspaces
            on 'object.workspaceWorkspaceId equals workspace?.workspaceId
            select filterRecord(
                {
                ...'object,
                "department": department,
                "workspace": workspace
            }, fields);
    }

    private isolated function queryOneEmployees(anydata key) returns record {}|InvalidKeyError {
        from record {} 'object in self.employees
        where self.persistClients.get(EMPLOYEE).getKey('object) == key
        outer join var department in self.departments
            on 'object.departmentDeptNo equals department?.deptNo
        outer join var workspace in self.workspaces
            on 'object.workspaceWorkspaceId equals workspace?.workspaceId
        do {
            return {
                ...'object,
                "department": department,
                "workspace": workspace
            };
        };
        return <InvalidKeyError>error("Invalid key: " + key.toString());
    }

    private isolated function queryBuildings(string[] fields) returns stream<record {}, Error?> {
        return from record {} 'object in self.buildings
            select filterRecord({
                ...'object
            }, fields);
    }

    private isolated function queryOneBuildings(anydata key) returns record {}|InvalidKeyError {
        from record {} 'object in self.buildings
        where self.persistClients.get(BUILDING).getKey('object) == key
        do {
            return {
                ...'object
            };
        };
        return <InvalidKeyError>error("Invalid key: " + key.toString());
    }

    private isolated function queryBuildingsWorkspaces(record {} value, string[] fields) returns record {}[] {
        return from record {} 'object in self.workspaces
            where 'object.locationBuildingCode == value["buildingCode"]
            select filterRecord({
                ...'object
            }, fields);
    }

    private isolated function queryDepartments(string[] fields) returns stream<record {}, Error?> {
        return from record {} 'object in self.departments
            select filterRecord({
                ...'object
            }, fields);
    }

    private isolated function queryOneDepartments(anydata key) returns record {}|InvalidKeyError {
        from record {} 'object in self.departments
        where self.persistClients.get(DEPARTMENT).getKey('object) == key
        do {
            return {
                ...'object
            };
        };
        return <InvalidKeyError>error("Invalid key: " + key.toString());
    }

    private isolated function queryDepartmentsEmployees(record {} value, string[] fields) returns record {}[] {
        return from record {} 'object in self.employees
            where 'object.departmentDeptNo == value["deptNo"]
            select filterRecord({
                ...'object
            }, fields);
    }

    private isolated function queryWorkspaces(string[] fields) returns stream<record {}, Error?> {
        return from record {} 'object in self.workspaces
            outer join var location in self.buildings
            on 'object.locationBuildingCode equals location?.buildingCode
            select filterRecord({
                ...'object,
                "location": location
            }, fields);
    }

    private isolated function queryOneWorkspaces(anydata key) returns record {}|InvalidKeyError {
        from record {} 'object in self.workspaces
        where self.persistClients.get(WORKSPACE).getKey('object) == key
        outer join var location in self.buildings
            on 'object.locationBuildingCode equals location?.buildingCode
        do {
            return {
                ...'object,
                "location": location
            };
        };
        return <InvalidKeyError>error("Invalid key: " + key.toString());
    }

    private isolated function queryWorkspacesEmployees(record {} value, string[] fields) returns record {}[] {
        return from record {} 'object in self.employees
            where 'object.workspaceWorkspaceId == value["workspaceId"]
            select filterRecord({
                ...'object
            }, fields);
    }

    private isolated function queryOrderItems(string[] fields) returns stream<record {}, Error?> {
        return from record {} 'object in self.orderItems
            select filterRecord({
                ...'object
            }, fields);
    }

    private isolated function queryOneOrderItems(anydata key) returns record {}|InvalidKeyError {
        from record {} 'object in self.orderItems
        where self.persistClients.get(ORDER_ITEM).getKey('object) == key
        do {
            return {
                ...'object
            };
        };
        return <InvalidKeyError>error("Invalid key: " + key.toString());
    }
}
