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

final isolated table<Building> key(buildingCode) buildings = table [];
final isolated table<Department> key(deptNo) departments = table [];
final isolated table<Workspace> key(workspaceId) workspaces = table [];
final isolated table<Employee> key(empNo) employees = table [];
final isolated table<OrderItem> key(orderId, itemId) orderItems = table [];

public isolated client class InMemoryRainierClient {
    *AbstractPersistClient;

    private final map<InMemoryClient> persistClients = {};

    public function init() returns Error? {
        final map<TableMetadata> metadata = {
            [BUILDING] : {
                keyFields: ["buildingCode"],
                query: queryBuildings,
                queryOne: queryOneBuildings,
                associationsMethods: {
                    "workspaces": queryBuildingsWorkspaces
                }
            },
            [DEPARTMENT] : {
                keyFields: ["deptNo"],
                query: queryDepartments,
                queryOne: queryOneDepartments,
                associationsMethods: {
                    "employees": queryDepartmentsEmployees
                }
            },
            [WORKSPACE] : {
                keyFields: ["workspaceId"],
                query: queryWorkspaces,
                queryOne: queryOneWorkspaces,
                associationsMethods: {
                    "employees": queryWorkspacesEmployees
                }
            },
            [EMPLOYEE] : {
                keyFields: ["empNo"],
                query: queryEmployees,
                queryOne: queryOneEmployees
            },
            [ORDER_ITEM] : {
                keyFields: ["orderId", "itemId"],
                query: queryOrderItems,
                queryOne: queryOneOrderItems
            }
        };

        self.persistClients[BUILDING] = check new(metadata.get(BUILDING));
        self.persistClients[DEPARTMENT] = check new(metadata.get(DEPARTMENT));
        self.persistClients[WORKSPACE] = check new(metadata.get(WORKSPACE));
        self.persistClients[EMPLOYEE] = check new(metadata.get(EMPLOYEE));
        self.persistClients[ORDER_ITEM] = check new(metadata.get(ORDER_ITEM));
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
        lock {
            string[] keys = [];
            foreach BuildingInsert value in data.clone() {
                if buildings.hasKey(value.buildingCode) {
                    return <DuplicateKeyError>error("Duplicate key: " + value.buildingCode);
                }
                buildings.put(value.clone());
                keys.push(value.buildingCode);
            }
            return keys.clone();
        }
    }

    isolated resource function put buildings/[string buildingCode](BuildingUpdate value) returns Building|Error {
        lock {
            if !buildings.hasKey(buildingCode) {
                return <InvalidKeyError>error("Not found: " + buildingCode);
            }

            Building building = buildings.get(buildingCode);
            foreach var [k, v] in value.clone().entries() {
                building[k] = v;
            }

            buildings.put(building);
            return building.clone();
        }
    }

    isolated resource function delete buildings/[string buildingCode]() returns Building|Error {
        lock {
            if !buildings.hasKey(buildingCode) {
                return <InvalidKeyError>error("Not found: " + buildingCode);
            }
            return buildings.remove(buildingCode).clone();
        }
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
        lock {
            string[] keys = [];
            foreach DepartmentInsert value in data.clone() {
                if departments.hasKey(value.deptNo) {
                    return <DuplicateKeyError>error("Duplicate key: " + value.deptNo);
                }
                departments.put(value.clone());
                keys.push(value.deptNo);
            }
            return keys.clone();
        }
    }

    isolated resource function put departments/[string deptNo](DepartmentUpdate value) returns Department|Error {
        lock {
            if !departments.hasKey(deptNo) {
                return <InvalidKeyError>error("Not found: " + deptNo);
            }

            Department department = departments.get(deptNo);
            foreach var [k, v] in value.clone().entries() {
                department[k] = v;
            }

            departments.put(department);
            return department.clone();
        }
    }

    isolated resource function delete departments/[string deptNo]() returns Department|Error {
        lock {
            if !departments.hasKey(deptNo) {
                return <InvalidKeyError>error("Not found: " + deptNo);
            }
            return departments.remove(deptNo).clone();
        }
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
        lock {
            string[] keys = [];
            foreach WorkspaceInsert value in data.clone() {
                if workspaces.hasKey(value.workspaceId) {
                    return <DuplicateKeyError>error("Duplicate key: " + value.workspaceId);
                }
                workspaces.put(value.clone());
                keys.push(value.workspaceId);
            }
            return keys.clone();
        }
    }

    isolated resource function put workspaces/[string workspaceId](WorkspaceUpdate value) returns Workspace|Error {
        lock {
            if !workspaces.hasKey(workspaceId) {
                return <InvalidKeyError>error("Not found: " + workspaceId);
            }

            Workspace workspace = workspaces.get(workspaceId);
            foreach var [k, v] in value.clone().entries() {
                workspace[k] = v;
            }

            workspaces.put(workspace);
            return workspace.clone();
       }
    }

    isolated resource function delete workspaces/[string workspaceId]() returns Workspace|Error {
        lock {
            if !workspaces.hasKey(workspaceId) {
                return <InvalidKeyError>error("Not found: " + workspaceId);
            }
            return workspaces.remove(workspaceId).clone();
        }
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
        lock {
            string[] keys = [];
            foreach EmployeeInsert value in data.clone() {
                if employees.hasKey(value.empNo) {
                    return <DuplicateKeyError>error("Duplicate key: " + value.empNo);
                }
                employees.put(value.clone());
                keys.push(value.empNo);
            }
            return keys.clone();
        }
    }

    isolated resource function put employees/[string empNo](EmployeeUpdate value) returns Employee|Error {
        lock {
            if !employees.hasKey(empNo) {
                return <InvalidKeyError>error("Not found: " + empNo);
            }

            Employee employee = employees.get(empNo);
            foreach var [k, v] in value.clone().entries() {
                employee[k] = v;
            }

            employees.put(employee);
            return employee.clone();
        }
    }

    isolated resource function delete employees/[string empNo]() returns Employee|Error {
        lock {
            if !employees.hasKey(empNo) {
                return <InvalidKeyError>error("Not found: " + empNo);
            }
            return employees.remove(empNo).clone();
        }
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
        lock {
            [string, string][] keys = [];
            foreach OrderItemInsert value in data.clone() {
                if orderItems.hasKey([value.orderId, value.itemId]) {
                    return <DuplicateKeyError>error("Duplicate key: " + [value.orderId, value.itemId].toString());
                }
                orderItems.put(value.clone());
                keys.push([value.orderId, value.itemId]);
            }
            return keys.clone();
        }
    }

    isolated resource function put orderitems/[string orderId]/[string itemId](OrderItemUpdate value) returns OrderItem|Error {
        lock {
            if !orderItems.hasKey([orderId, itemId]) {
                return <InvalidKeyError>error("Not found: " + [orderId, itemId].toString());
            }

            OrderItem orderItem = orderItems.get([orderId, itemId]);
            foreach var [k, v] in value.clone().entries() {
                orderItem[k] = v;
            }

            orderItems.put(orderItem);
            return orderItem.clone();
        }
    }

    isolated resource function delete orderitems/[string orderId]/[string itemId]() returns OrderItem|Error {
        lock {
            if !orderItems.hasKey([orderId, itemId]) {
                return <InvalidKeyError>error("Not found: " + [orderId, itemId].toString());
            }
            return orderItems.remove([orderId, itemId]).clone();
        }
    }

}

isolated function queryEmployees(string[] fields) returns stream<record {}, Error?> {
    table<Employee> key(empNo) employeesTable;
    table<Department> key(deptNo) departmentsTable;
    table<Workspace> key(workspaceId) workspacesTable;
    lock {
        employeesTable = employees.clone();
    }
    lock {
        departmentsTable = departments.clone();
    }
    lock {
        workspacesTable = workspaces.clone();
    }

    return from record {} 'object in employeesTable
        outer join var department in departmentsTable
        on 'object.departmentDeptNo equals department?.deptNo
        outer join var workspace in workspacesTable
        on 'object.workspaceWorkspaceId equals workspace?.workspaceId
        select filterRecord(
            {
            ...'object,
            "department": department,
            "workspace": workspace
        }, fields);
}

isolated function queryOneEmployees(anydata key) returns record {}|InvalidKeyError {
    table<Employee> key(empNo) employeesTable;
    table<Department> key(deptNo) departmentsTable;
    table<Workspace> key(workspaceId) workspacesTable;
    lock {
        employeesTable = employees.clone();
    }
    lock {
        departmentsTable = departments.clone();
    }
    lock {
        workspacesTable = workspaces.clone();
    }

    from record {} 'object in employeesTable
    where getKey('object, ["empNo"]) == key
    outer join var department in departmentsTable
        on 'object.departmentDeptNo equals department?.deptNo
    outer join var workspace in workspacesTable
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

isolated function queryBuildings(string[] fields) returns stream<record {}, Error?> {
    table<Building> key(buildingCode) buildingsTable;
    lock {
        buildingsTable = buildings.clone();
    }

    return from record {} 'object in buildingsTable
        select filterRecord({
            ...'object
        }, fields);
}

isolated function queryOneBuildings(anydata key) returns record {}|InvalidKeyError {
    table<Building> key(buildingCode) buildingsTable;
    lock {
        buildingsTable = buildings.clone();
    }

    from record {} 'object in buildingsTable
    where getKey('object, ["buildingCode"]) == key
    do {
        return {
            ...'object
        };
    };
    return <InvalidKeyError>error("Invalid key: " + key.toString());
}

isolated function queryBuildingsWorkspaces(record {} value, string[] fields) returns record {}[] {
    table<Workspace> key(workspaceId) workspacesTable;
    lock {
        workspacesTable = workspaces.clone();
    }

    return from record {} 'object in workspacesTable
        where 'object.locationBuildingCode == value["buildingCode"]
        select filterRecord({
            ...'object
        }, fields);
}

isolated function queryDepartments(string[] fields) returns stream<record {}, Error?> {
    table<Department> key(deptNo) departmentsTable;
    lock {
        departmentsTable = departments.clone();
    }

    return from record {} 'object in departmentsTable
        select filterRecord({
            ...'object
        }, fields);
}

isolated function queryOneDepartments(anydata key) returns record {}|InvalidKeyError {
    table<Department> key(deptNo) departmentsTable;
    lock {
        departmentsTable = departments.clone();
    }

    from record {} 'object in departmentsTable
    where getKey('object, ["deptNo"]) == key
    do {
        return {
            ...'object
        };
    };
    return <InvalidKeyError>error("Invalid key: " + key.toString());
}

isolated function queryDepartmentsEmployees(record {} value, string[] fields) returns record {}[] {
    table<Employee> key(empNo) employeesTable;
    lock {
        employeesTable = employees.clone();
    }

    return from record {} 'object in employeesTable
        where 'object.departmentDeptNo == value["deptNo"]
        select filterRecord({
            ...'object
        }, fields);
}

isolated function queryWorkspaces(string[] fields) returns stream<record {}, Error?> {
    table<Workspace> key(workspaceId) workspacesTable;
    table<Building> key(buildingCode) buildingsTable;
    lock {
        workspacesTable = workspaces.clone();
    }
    lock {
        buildingsTable = buildings.clone();
    }

    return from record {} 'object in workspacesTable
        outer join var location in buildingsTable
        on 'object.locationBuildingCode equals location?.buildingCode
        select filterRecord({
            ...'object,
            "location": location
        }, fields);
}

isolated function queryOneWorkspaces(anydata key) returns record {}|InvalidKeyError {
    table<Workspace> key(workspaceId) workspacesTable;
    table<Building> key(buildingCode) buildingsTable;
    lock {
        workspacesTable = workspaces.clone();
    }
    lock {
        buildingsTable = buildings.clone();
    }
    from record {} 'object in workspacesTable
    where getKey('object, ["workspaceId"]) == key
    outer join var location in buildingsTable
        on 'object.locationBuildingCode equals location?.buildingCode
    do {
        return {
            ...'object,
            "location": location
        };
    };
    return <InvalidKeyError>error("Invalid key: " + key.toString());
}

isolated function queryWorkspacesEmployees(record {} value, string[] fields) returns record {}[] {
    table<Employee> key(empNo) employeesTable;
    lock {
        employeesTable = employees.clone();
    }
    return from record {} 'object in employeesTable
        where 'object.workspaceWorkspaceId == value["workspaceId"]
        select filterRecord({
            ...'object
        }, fields);
}

isolated function queryOrderItems(string[] fields) returns stream<record {}, Error?> {
    table<OrderItem> key(orderId, itemId) orderItemsTable;
    lock {
        orderItemsTable = orderItems.clone();
    }

    return from record {} 'object in orderItemsTable
        select filterRecord({
            ...'object
        }, fields);
}

isolated function queryOneOrderItems(anydata key) returns record {}|InvalidKeyError {
    table<OrderItem> key(orderId, itemId) orderItemsTable;
    lock {
        orderItemsTable = orderItems.clone();
    }

    from record {} 'object in orderItemsTable
    where getKey('object, ["orderId", "itemId"]) == key
    do {
        return {
            ...'object
        };
    };
    return <InvalidKeyError>error("Invalid key: " + key.toString());
}
