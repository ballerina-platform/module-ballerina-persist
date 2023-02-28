import ballerina/sql;
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
                "workspace.buildingBuildingCode": {relation: {entityName: "workspace", refField: "buildingBuildingCode"}}
            },
            keyFields: ["empNo"],
            joinMetadata: {
                department: {entity: Department, fieldName: "department", refTable: "Department", refColumns: ["deptNo"], joinColumns: ["departmentDeptNo"], 'type: ONE_TO_MANY},
                workspace: {entity: Workspace, fieldName: "workspace", refTable: "Workspace", refColumns: ["workspaceId"], joinColumns: ["workspaceWorkspaceId"], 'type: ONE_TO_ONE}
            }
        },
        "workspace": {
            entityName: "Workspace",
            tableName: `Workspace`,
            fieldMetadata: {
                workspaceId: {columnName: "workspaceId"},
                workspaceType: {columnName: "workspaceType"},
                buildingBuildingCode: {columnName: "buildingBuildingCode"}
            },
            keyFields: ["workspaceId"]
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
                'type: {columnName: "type"}
            },
            keyFields: ["buildingCode"]
        },
        "department": {
            entityName: "Department",
            tableName: `Department`,
            fieldMetadata: {
                deptNo: {columnName: "deptNo"},
                deptName: {columnName: "deptName"},
                "employee[].empNo": {relation: {entityName: "employee", refField: "empNo"}},
                "employee[].firstName": {relation: {entityName: "employee", refField: "firstName"}},
                "employee[].lastName": {relation: {entityName: "employee", refField: "lastName"}},
                "employee[].birthDate": {relation: {entityName: "employee", refField: "birthDate"}},
                "employee[].gender": {relation: {entityName: "employee", refField: "gender"}},
                "employee[].hireDate": {relation: {entityName: "employee", refField: "hireDate"}},
                "employee[].departmentDeptNo": {relation: {entityName: "employee", refField: "departmentDeptNo"}},
                "employee[].workspaceWorkspaceId": {relation: {entityName: "employee", refField: "workspaceWorkspaceId"}}
            },
            keyFields: ["deptNo"],
            joinMetadata: {
                employee: {entity: Employee, fieldName: "employee", refTable: "Employee", refColumns: ["departmentDeptNo"], joinColumns: ["deptNo"], 'type: MANY_TO_ONE}
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

public class EmployeeStream {

    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|Employee value;|}|Error? {
        if self.err is Error {
            return <Error>self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                Employee|error value = streamValue.value.cloneWithType(Employee);
                if value is error {
                    return <Error>error(value.message());
                }
                record {|Employee value;|} nextRecord = {value: value};
                return nextRecord;
            }
        } else {
            return ();
        }
    }

    public isolated function close() returns Error? {
        check closeEntityStream(self.anydataStream);
    }
}

public class WorkspaceStream {

    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|Workspace value;|}|Error? {
        if self.err is Error {
            return <Error>self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                Workspace|error value = streamValue.value.cloneWithType(Workspace);
                if value is error {
                    return <Error>error(value.message());
                }
                record {|Workspace value;|} nextRecord = {value: value};
                return nextRecord;
            }
        } else {
            return ();
        }
    }

    public isolated function close() returns Error? {
        check closeEntityStream(self.anydataStream);
    }
}

public class BuildingStream {

    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|Building value;|}|Error? {
        if self.err is Error {
            return <Error>self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                Building|error value = streamValue.value.cloneWithType(Building);
                if value is error {
                    return <Error>error(value.message());
                }
                record {|Building value;|} nextRecord = {value: value};
                return nextRecord;
            }
        } else {
            return ();
        }
    }

    public isolated function close() returns Error? {
        check closeEntityStream(self.anydataStream);
    }
}

public class DepartmentStream {

    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;
    private string[]? include;
    private SQLClient? persistClient;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = (), string[]? include = (), SQLClient? persistClient = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
        self.include = include;
        self.persistClient = persistClient;
    }

    public isolated function next() returns record {|Department value;|}|Error? {
        if self.err is Error {
            return <Error>self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                Department|error value = streamValue.value.cloneWithType(Department);
                if value is error {
                    return <Error>error(value.message());
                }
                record {|Department value;|} nextRecord = {value: value};
                if self.include is string[] {
                    check (<SQLClient>self.persistClient).getManyRelations(nextRecord.value, <string[]>self.include);
                }
                return nextRecord;
            }
        } else {
            return ();
        }
    }

    public isolated function close() returns Error? {
        check closeEntityStream(self.anydataStream);
    }
}

public class OrderItemStream {

    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|OrderItem value;|}|Error? {
        if self.err is Error {
            return <Error>self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                OrderItem|error value = streamValue.value.cloneWithType(OrderItem);
                if value is error {
                    return <Error>error(value.message());
                }
                record {|OrderItem value;|} nextRecord = {value: value};
                return nextRecord;
            }
        } else {
            return ();
        }
    }

    public isolated function close() returns Error? {
        check closeEntityStream(self.anydataStream);
    }
}

