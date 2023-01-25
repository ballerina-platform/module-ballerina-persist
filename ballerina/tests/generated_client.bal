import ballerinax/mysql;
import ballerina/sql;
import ballerina/time;

const BUILDING = "building";
const WORKSPACE = "workspace";
const DEPARTMENT = "department";
const EMPLOYEE = "employee";
const ORDER_ITEM = "orderitem";

client class RainierClient {

    private final mysql:Client dbClient;

    private final record {|Metadata...;|} metadata = {
        "building": {
            entityName: "Building",
            tableName: `Building`,
            fieldMetadata: {
                buildingCode: {columnName: "buildingCode", 'type: string},
                city: {columnName: "city", 'type: string},
                state: {columnName: "state", 'type: string},
                country: {columnName: "country", 'type: string},
                postalCode: {columnName: "postalCode", 'type: string}
            },
            keyFields: ["buildingCode"]
        },
        "workspace": {
            entityName: "Workspace",
            tableName: `Workspace`,
            fieldMetadata: {
                workspaceId: {columnName: "workspaceId", 'type: string},
                workspaceType: {columnName: "workspaceType", 'type: string},
                buildingBuildingCode: {columnName: "buildingBuildingCode", 'type: string}
            },
            keyFields: ["workspaceId"]
        },
        "department": {
            entityName: "Department",
            tableName: `Department`,
            fieldMetadata: {
                deptNo: {columnName: "deptNo", 'type: string},
                deptName: {columnName: "deptName", 'type: string}
            },
            keyFields: ["deptNo"]
        },
        "employee": {
            entityName: "Employee",
            tableName: `Employee`,
            fieldMetadata: {
                empNo: {columnName: "empNo", 'type: string},
                firstName: {columnName: "firstName", 'type: string},
                lastName: {columnName: "lastName", 'type: string},
                birthDate: {columnName: "birthDate", 'type: time:Date},
                gender: {columnName: "gender", 'type: string},
                hireDate: {columnName: "hireDate", 'type: time:Date},
                departmentDeptNo: {columnName: "departmentDeptNo", 'type: string},
                workspaceWorkspaceId: {columnName: "workspaceWorkspaceId", 'type: string}
            },
            keyFields: ["empNo"]
        },
        "orderitem": {
            entityName: "OrderItem",
            tableName: `OrderItem`,
            fieldMetadata: {
                orderId: {columnName: "orderId", 'type: string},
                itemId: {columnName: "itemId", 'type: string},
                quantity: {columnName: "quantity", 'type: int},
                notes: {columnName: "notes", 'type: string}
            },
            keyFields: ["orderId", "itemId"]
        }
    };

    private final map<SQLClient> persistClients;
    
    public function init() returns Error? {
        do {
            self.dbClient = check new (host = host, user = user, password = password, database = database, port = port);

            self.persistClients = {
                building: check new (self.dbClient, self.metadata.get(BUILDING)),
                workspace: check new (self.dbClient, self.metadata.get(WORKSPACE)),
                department: check new (self.dbClient, self.metadata.get(DEPARTMENT)),
                employee: check new (self.dbClient, self.metadata.get(EMPLOYEE)),
                orderitem: check new (self.dbClient, self.metadata.get(ORDER_ITEM))
            };
        } on fail error e {
            return <Error>error(e.message());
        }
    }

    isolated resource function get buildings() returns stream<Building, error?> {
        stream<record{}, sql:Error?>|Error result = self.persistClients.get(BUILDING).runReadQuery(Building);
        if result is Error {
            return new stream<Building, Error?>(new BuildingStream((), result));
        } else {
            return new stream<Building, Error?>(new BuildingStream(result));
        }
    };

    isolated resource function get buildings/[string buildingCode]() returns Building|error {
        return (check self.persistClients.get(BUILDING).runReadByKeyQuery(Building, buildingCode)).cloneWithType(Building);
    };

    isolated resource function post buildings(BuildingInsert[] data) returns string[]|error {
        _ = check self.persistClients.get(BUILDING).runBatchInsertQuery(data);
        return from BuildingInsert inserted in data
               select inserted.buildingCode;
    };

    isolated resource function put buildings/[string buildingCode](BuildingUpdate data) returns Building|error {
        _ = check self.persistClients.get(BUILDING).runUpdateQuery(buildingCode, data);
        return self->/buildings/[buildingCode].get();
    };

    isolated resource function delete buildings/[string buildingCode]() returns Building|error {
        Building 'object = check self->/buildings/[buildingCode].get();
        _ = check self.persistClients.get(BUILDING).runDeleteQuery(buildingCode);
        return 'object;
    };

    isolated resource function get workspaces() returns stream<Workspace, error?> {
        stream<record{}, sql:Error?>|Error result = self.persistClients.get(WORKSPACE).runReadQuery(Workspace);
        if result is Error {
            return new stream<Workspace, Error?>(new WorkspaceStream((), result));
        } else {
            return new stream<Workspace, Error?>(new WorkspaceStream(result));
        }
    };

    isolated resource function get workspaces/[string workspaceId]() returns Workspace|error {
        return (check self.persistClients.get(WORKSPACE).runReadByKeyQuery(Workspace, workspaceId)).cloneWithType(Workspace);
    };

    isolated resource function post workspaces(WorkspaceInsert[] data) returns string[]|error {
        _ = check self.persistClients.get(WORKSPACE).runBatchInsertQuery(data);
        return from WorkspaceInsert inserted in data
               select inserted.workspaceId;
    };

    isolated resource function put workspaces/[string workspaceId](WorkspaceUpdate data) returns Workspace|error {
        _ = check self.persistClients.get(WORKSPACE).runUpdateQuery(workspaceId, data);
        return self->/workspaces/[workspaceId].get();
    };

    isolated resource function delete workspaces/[string workspaceId]() returns Workspace|error {
        Workspace 'object = check self->/workspaces/[workspaceId].get();
        _ = check self.persistClients.get(WORKSPACE).runDeleteQuery(workspaceId);
        return 'object;
    };

    isolated resource function get departments() returns stream<Department, error?> {
        stream<record{}, sql:Error?>|Error result = self.persistClients.get(DEPARTMENT).runReadQuery(Department);
        if result is Error {
            return new stream<Department, Error?>(new DepartmentStream((), result));
        } else {
            return new stream<Department, Error?>(new DepartmentStream(result));
        }
    };

    isolated resource function get departments/[string deptNo]() returns Department|error {
        return (check self.persistClients.get(DEPARTMENT).runReadByKeyQuery(Department, deptNo)).cloneWithType(Department);
    };

    isolated resource function post departments(DepartmentInsert[] data) returns string[]|error {
        _ = check self.persistClients.get(DEPARTMENT).runBatchInsertQuery(data);
        return from DepartmentInsert inserted in data
               select inserted.deptNo;
    };

    isolated resource function put departments/[string deptNo](DepartmentUpdate data) returns Department|error {
        _ = check self.persistClients.get(DEPARTMENT).runUpdateQuery(deptNo, data);
        return self->/departments/[deptNo].get();
    };

    isolated resource function delete departments/[string deptNo]() returns Department|error {
        Department 'object = check self->/departments/[deptNo].get();
        _ = check self.persistClients.get(DEPARTMENT).runDeleteQuery(deptNo);
        return 'object;
    };

    isolated resource function get employees() returns stream<Employee, error?> {
        stream<record{}, sql:Error?>|Error result = self.persistClients.get(EMPLOYEE).runReadQuery(Employee);
        if result is Error {
            return new stream<Employee, Error?>(new EmployeeStream((), result));
        } else {
            return new stream<Employee, Error?>(new EmployeeStream(result));
        }
    };

    isolated resource function get employees/[string empNo]() returns Employee|error {
        return (check self.persistClients.get(EMPLOYEE).runReadByKeyQuery(Employee, empNo)).cloneWithType(Employee);
    };

    isolated resource function post employees(EmployeeInsert[] data) returns string[]|error {
        _ = check self.persistClients.get(EMPLOYEE).runBatchInsertQuery(data);
        return from EmployeeInsert inserted in data
               select inserted.empNo;
    };

    isolated resource function put employees/[string empNo](EmployeeUpdate data) returns Employee|error {
        _ = check self.persistClients.get(EMPLOYEE).runUpdateQuery(empNo, data);
        return self->/employees/[empNo].get();
    };

    isolated resource function delete employees/[string empNo]() returns Employee|error {
        Employee 'object = check self->/employees/[empNo].get();
        _ = check self.persistClients.get(EMPLOYEE).runDeleteQuery(empNo);
        return 'object;
    };

    isolated resource function get orderItems() returns stream<OrderItem, error?> {
        stream<record{}, sql:Error?>|Error result = self.persistClients.get(ORDER_ITEM).runReadQuery(OrderItem);
        if result is Error {
            return new stream<OrderItem, Error?>(new OrderItemStream((), result));
        } else {
            return new stream<OrderItem, Error?>(new OrderItemStream(result));
        }
    };

    isolated resource function get orderItems/[string orderId]/[string itemId]() returns OrderItem|error {
        return (check self.persistClients.get(ORDER_ITEM).runReadByKeyQuery(OrderItem, {orderId: orderId, itemId: itemId})).cloneWithType(OrderItem);
    };

    isolated resource function post orderItems(OrderItemInsert[] data) returns [string, string][]|error {
        _ = check self.persistClients.get(ORDER_ITEM).runBatchInsertQuery(data);
        return from OrderItemInsert inserted in data
               select [inserted.orderId, inserted.itemId];
    };

    isolated resource function put orderItems/[string orderId]/[string itemId](OrderItemUpdate data) returns OrderItem|error {
        _ = check self.persistClients.get(ORDER_ITEM).runUpdateQuery({orderId: orderId, itemId: itemId}, data);
        return self->/orderItems/[orderId]/[itemId].get();
    };

    isolated resource function delete orderItems/[string orderId]/[string itemId]() returns OrderItem|error {
        OrderItem 'object = check self->/orderItems/[orderId]/[itemId].get();
        _ = check self.persistClients.get(ORDER_ITEM).runDeleteQuery({orderId:orderId, itemId:itemId});
        return 'object;
    };

    public function close() returns error? {
        _ = check self.dbClient.close();
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
        if self.err is error {
            return self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                do {
                    record {|Building value;|} nextRecord = {value: check streamValue.value.cloneWithType(Building)};
                    return nextRecord;
                } on fail error e {
                    return <Error>e;
                }
            }
        } else {
            // Unreachable code
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
        if self.err is error {
            return self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                do {
                    record {|Workspace value;|} nextRecord = {value: check streamValue.value.cloneWithType(Workspace)};
                    return nextRecord;
                } on fail error e {
                    return <Error>e;
                }
            }
        } else {
            // Unreachable code
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

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
    }

    public isolated function next() returns record {|Department value;|}|Error? {
        if self.err is error {
            return self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                do {
                    record {|Department value;|} nextRecord = {value: check streamValue.value.cloneWithType(Department)};
                    return nextRecord;
                } on fail error e {
                    return <Error>e;
                }
            }
        } else {
            // Unreachable code
            return ();
        }
    }

    public isolated function close() returns Error? {
        check closeEntityStream(self.anydataStream);
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
        if self.err is error {
            return self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                do {
                    record {|Employee value;|} nextRecord = {value: check streamValue.value.cloneWithType(Employee)};
                    return nextRecord;
                } on fail error e {
                    return <Error>e;
                }
            }
        } else {
            // Unreachable code
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
        if self.err is error {
            return self.err;
        } else if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is sql:Error) {
                return <Error>error(streamValue.message());
            } else {
                do {
                    record {|OrderItem value;|} nextRecord = {value: check streamValue.value.cloneWithType(OrderItem)};
                    return nextRecord;
                } on fail error e {
                    return <Error>e;
                }
            }
        } else {
            // Unreachable code
            return ();
        }
    }

    public isolated function close() returns Error? {
        check closeEntityStream(self.anydataStream);
    }
}
