import ballerinax/mysql;
import ballerina/jballerina.java;

const EMPLOYEE = "employee";
const WORKSPACE = "workspace";
const BUILDING = "building";
const DEPARTMENT = "department";
const ORDER_ITEM = "orderitem";

public client class RainierClient {
    *AbstractPersistClient;

    private final mysql:Client dbClient;

    private final map<SQLClient> persistClients;


    private final record {|Metadata...;|} metadata = {
        "employee": {
            entityName: "Employee",
            tableName: `Employee`,
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
        "workspace": {
            entityName: "Workspace",
            tableName: `Workspace`,
            fieldMetadata: {
                workspaceId: {columnName: "workspaceId"},
                workspaceType: {columnName: "workspaceType"},
                locationBuildingCode: {columnName: "locationBuildingCode"},
                "location.buildingCode": {relation: {entityName: "building", refField: "buildingCode"}},
                "location.city": {relation: {entityName: "building", refField: "city"}},
                "location.state": {relation: {entityName: "building", refField: "state"}},
                "location.country": {relation: {entityName: "building", refField: "country"}},
                "location.postalCode": {relation: {entityName: "building", refField: "postalCode"}},
                "location.type": {relation: {entityName: "building", refField: "type"}},
                "employees[].empNo": {relation: {entityName: "employee", refField: "empNo"}},
                "employees[].firstName": {relation: {entityName: "employee", refField: "firstName"}},
                "employees[].lastName": {relation: {entityName: "employee", refField: "lastName"}},
                "employees[].birthDate": {relation: {entityName: "employee", refField: "birthDate"}},
                "employees[].gender": {relation: {entityName: "employee", refField: "gender"}},
                "employees[].hireDate": {relation: {entityName: "employee", refField: "hireDate"}},
                "employees[].departmentDeptNo": {relation: {entityName: "employee", refField: "departmentDeptNo"}},
                "employees[].workspaceWorkspaceId": {relation: {entityName: "employee", refField: "workspaceWorkspaceId"}}
            },
            keyFields: ["workspaceId"],
            joinMetadata: {
                location: {entity: Building, fieldName: "location", refTable: "Building", refColumns: ["buildingCode"], joinColumns: ["locationBuildingCode"], 'type: ONE_TO_MANY},
                employees: {entity: Employee, fieldName: "employees", refTable: "Employee", refColumns: ["workspaceWorkspaceId"], joinColumns: ["workspaceId"], 'type: MANY_TO_ONE}
            }
        },
        "building": {
            entityName: "Building",
            tableName: `Building`,
            fieldMetadata: {
                buildingCode: {columnName: "buildingCode"},
                city: {columnName: "city"},
                state: {columnName: "state"},
                country: {columnName: "country"},
                postalCode: {columnName: "postalCode"},
                'type: {columnName: "type"},
                "workspaces[].workspaceId": {relation: {entityName: "workspace", refField: "workspaceId"}},
                "workspaces[].workspaceType": {relation: {entityName: "workspace", refField: "workspaceType"}},
                "workspaces[].locationBuildingCode": {relation: {entityName: "workspace", refField: "locationBuildingCode"}}
            },
            keyFields: ["buildingCode"],
            joinMetadata: {
                workspaces: {entity: Workspace, fieldName: "workspaces", refTable: "Workspace", refColumns: ["locationBuildingCode"], joinColumns: ["buildingCode"], 'type: MANY_TO_ONE}
            }
        },
        "department": {
            entityName: "Department",
            tableName: `Department`,
            fieldMetadata: {
                deptNo: {columnName: "deptNo"},
                deptName: {columnName: "deptName"},
                "employees[].empNo": {relation: {entityName: "employee", refField: "empNo"}},
                "employees[].firstName": {relation: {entityName: "employee", refField: "firstName"}},
                "employees[].lastName": {relation: {entityName: "employee", refField: "lastName"}},
                "employees[].birthDate": {relation: {entityName: "employee", refField: "birthDate"}},
                "employees[].gender": {relation: {entityName: "employee", refField: "gender"}},
                "employees[].hireDate": {relation: {entityName: "employee", refField: "hireDate"}},
                "employees[].departmentDeptNo": {relation: {entityName: "employee", refField: "departmentDeptNo"}},
                "employees[].workspaceWorkspaceId": {relation: {entityName: "employee", refField: "workspaceWorkspaceId"}}
            },
            keyFields: ["deptNo"],
            joinMetadata: {
                employees: {entity: Employee, fieldName: "employees", refTable: "Employee", refColumns: ["departmentDeptNo"], joinColumns: ["deptNo"], 'type: MANY_TO_ONE}
            }
        },
        "orderitem": {
            entityName: "OrderItem",
            tableName: `OrderItem`,
            fieldMetadata: {
                orderId: {columnName: "orderId"},
                itemId: {columnName: "itemId"},
                quantity: {columnName: "quantity"},
                notes: {columnName: "notes"}
            },
            keyFields: ["orderId", "itemId"]
        }
    };

    public function init() returns Error? {
        mysql:Client|error dbClient = new (host = host, user = user, password = password, database = database, port = port);
        if dbClient is error {
            return <Error>error(dbClient.message());
        }
        self.dbClient = dbClient;
        self.persistClients = {
            employee: check new (self.dbClient, self.metadata.get(EMPLOYEE)),
            workspace: check new (self.dbClient, self.metadata.get(WORKSPACE)),
            building: check new (self.dbClient, self.metadata.get(BUILDING)),
            department: check new (self.dbClient, self.metadata.get(DEPARTMENT)),
            orderitem: check new (self.dbClient, self.metadata.get(ORDER_ITEM))
        };
    }

    isolated resource function get employee(EmployeeTargetType targetType = <>, string entity = "employee") returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.QueryProcessor",
        name: "query"
    } external;

    isolated resource function get employee/[string empNo](EmployeeTargetType targetType = <>, string entity = "employee") returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.QueryProcessor",
        name: "queryOne"
    } external;

    isolated resource function post employee(EmployeeInsert[] data) returns string[]|Error {
        _ = check self.persistClients.get(EMPLOYEE).runBatchInsertQuery(data);
        return from EmployeeInsert inserted in data
            select inserted.empNo;
    }

    isolated resource function put employee/[string empNo](EmployeeUpdate value) returns Employee|Error {
        _ = check self.persistClients.get(EMPLOYEE).runUpdateQuery(empNo, value);
        return self->/employee/[empNo].get();
    }

    isolated resource function delete employee/[string empNo]() returns Employee|Error {
        Employee result = check self->/employee/[empNo].get();
        _ = check self.persistClients.get(EMPLOYEE).runDeleteQuery(empNo);
        return result;
    }

    isolated resource function get workspace(WorkspaceTargetType targetType = <>, string entity = "workspace") returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.QueryProcessor",
        name: "query"
    } external;

    isolated resource function get workspace/[string workspaceId]() returns Workspace|Error {
        Workspace|error result = (check self.persistClients.get(WORKSPACE).runReadByKeyQuery(Workspace, workspaceId)).cloneWithType(Workspace);
        if result is error {
            return <Error>error(result.message());
        }
        return result;
    }

    isolated resource function post workspace(WorkspaceInsert[] data) returns string[]|Error {
        _ = check self.persistClients.get(WORKSPACE).runBatchInsertQuery(data);
        return from WorkspaceInsert inserted in data
            select inserted.workspaceId;
    }

    isolated resource function put workspace/[string workspaceId](WorkspaceUpdate value) returns Workspace|Error {
        _ = check self.persistClients.get(WORKSPACE).runUpdateQuery(workspaceId, value);
        return self->/workspace/[workspaceId].get();
    }

    isolated resource function delete workspace/[string workspaceId]() returns Workspace|Error {
        Workspace result = check self->/workspace/[workspaceId].get();
        _ = check self.persistClients.get(WORKSPACE).runDeleteQuery(workspaceId);
        return result;
    }

    isolated resource function get building(BuildingTargetType targetType = <>, string entity = "building") returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.QueryProcessor",
        name: "query"
    } external;

    isolated resource function get building/[string buildingCode]() returns Building|Error {
        Building|error result = (check self.persistClients.get(BUILDING).runReadByKeyQuery(Building, buildingCode)).cloneWithType(Building);
        if result is error {
            return <Error>error(result.message());
        }
        return result;
    }

    isolated resource function post building(BuildingInsert[] data) returns string[]|Error {
        _ = check self.persistClients.get(BUILDING).runBatchInsertQuery(data);
        return from BuildingInsert inserted in data
            select inserted.buildingCode;
    }

    isolated resource function put building/[string buildingCode](BuildingUpdate value) returns Building|Error {
        _ = check self.persistClients.get(BUILDING).runUpdateQuery(buildingCode, value);
        return self->/building/[buildingCode].get();
    }

    isolated resource function delete building/[string buildingCode]() returns Building|Error {
        Building result = check self->/building/[buildingCode].get();
        _ = check self.persistClients.get(BUILDING).runDeleteQuery(buildingCode);
        return result;
    }

    isolated resource function get department(DepartmentTargetType targetType = <>, string entity = "department") returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.QueryProcessor",
        name: "query"
    } external;

    isolated resource function get department/[string deptNo]() returns Department|Error {
        Department|error result = (check self.persistClients.get(DEPARTMENT).runReadByKeyQuery(Department, deptNo)).cloneWithType(Department);
        if result is error {
            return <Error>error(result.message());
        }
        return result;
    }

    isolated resource function post department(DepartmentInsert[] data) returns string[]|Error {
        _ = check self.persistClients.get(DEPARTMENT).runBatchInsertQuery(data);
        return from DepartmentInsert inserted in data
            select inserted.deptNo;
    }

    isolated resource function put department/[string deptNo](DepartmentUpdate value) returns Department|Error {
        _ = check self.persistClients.get(DEPARTMENT).runUpdateQuery(deptNo, value);
        return self->/department/[deptNo].get();
    }

    isolated resource function delete department/[string deptNo]() returns Department|Error {
        Department result = check self->/department/[deptNo].get();
        _ = check self.persistClients.get(DEPARTMENT).runDeleteQuery(deptNo);
        return result;
    }

    isolated resource function get orderitem(OrderItemTargetType targetType = <>, string entity = "orderitem") returns stream<targetType, Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.QueryProcessor",
        name: "query"
    } external;

    isolated resource function get orderitem/[string orderId]/[string itemId]() returns OrderItem|Error {
        OrderItem|error result = (check self.persistClients.get(ORDER_ITEM).runReadByKeyQuery(OrderItem, {orderId: orderId, itemId: itemId})).cloneWithType(OrderItem);
        if result is error {
            return <Error>error(result.message());
        }
        return result;
    }

    isolated resource function get orderitemd/[string... orderId](OrderItemTargetType targetType = <>, string entity = "orderitem") returns targetType|Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.QueryProcessor",
        name: "queryOne2"
    } external;


    isolated resource function post orderitem(OrderItemInsert[] data) returns [string, string][]|Error {
        _ = check self.persistClients.get(ORDER_ITEM).runBatchInsertQuery(data);
        return from OrderItemInsert inserted in data
            select [inserted.orderId, inserted.itemId];
    }

    isolated resource function put orderitem/[string orderId]/[string itemId](OrderItemUpdate value) returns OrderItem|Error {
        _ = check self.persistClients.get(ORDER_ITEM).runUpdateQuery({orderId: orderId, itemId: itemId}, value);
        return self->/orderitem/[orderId]/[itemId].get();
    }

    isolated resource function delete orderitem/[string orderId]/[string itemId]() returns OrderItem|Error {
        OrderItem result = check self->/orderitem/[orderId]/[itemId].get();
        _ = check self.persistClients.get(ORDER_ITEM).runDeleteQuery({orderId: orderId, itemId: itemId});
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
