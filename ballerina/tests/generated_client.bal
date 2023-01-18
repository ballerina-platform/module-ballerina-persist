import ballerinax/mysql;
import ballerina/sql;
import ballerina/time;

client class RainierClient {

    private final mysql:Client dbClient;

    private final map<Metadata> metadata = {
        building: {
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
        workspace: {
            entityName: "Workspace",
            tableName: `Workspace`,
            fieldMetadata: {
                workspaceId: {columnName: "workspaceId", 'type: string},
                workspaceType: {columnName: "workspaceType", 'type: string},
                buildingCode: {columnName: "buildingCode", 'type: string}
            },
            keyFields: ["workspaceId"]
        },
        department: {
            entityName: "Department",
            tableName: `Department`,
            fieldMetadata: {
                deptNo: {columnName: "deptNo", 'type: string},
                deptName: {columnName: "deptName", 'type: string}
            },
            keyFields: ["deptNo"]
        },
        employee: {
            entityName: "Employee",
            tableName: `Employee`,
            fieldMetadata: {
                empNo: {columnName: "empNo", 'type: string},
                firstName: {columnName: "firstName", 'type: string},
                lastName: {columnName: "lastName", 'type: string},
                birthDate: {columnName: "birthDate", 'type: time:Date},
                gender: {columnName: "gender", 'type: string},
                hireDate: {columnName: "hireDate", 'type: time:Date},
                deptNo: {columnName: "deptNo", 'type: string},
                workspaceId: {columnName: "workspaceId", 'type: string}
            },
            keyFields: ["empNo"]
        }
    };
    
    private final map<SQLClient> persistClients;
    
    public function init() returns Error? {
        do {
            self.dbClient = check new (host = host, user = user, password = password, database = database, port = port);

            self.persistClients = {
                building: check new (self.dbClient, self.metadata.get("building").entityName, self.metadata.get("building").tableName, self.metadata.get("building").keyFields, self.metadata.get("building").fieldMetadata),
                workspace: check new (self.dbClient, self.metadata.get("workspace").entityName, self.metadata.get("workspace").tableName, self.metadata.get("workspace").keyFields, self.metadata.get("workspace").fieldMetadata),
                department: check new (self.dbClient, self.metadata.get("department").entityName, self.metadata.get("department").tableName, self.metadata.get("department").keyFields, self.metadata.get("department").fieldMetadata),
                employee: check new (self.dbClient, self.metadata.get("employee").entityName, self.metadata.get("employee").tableName, self.metadata.get("employee").keyFields, self.metadata.get("employee").fieldMetadata)
            };
        } on fail error e {
            return <Error>error(e.message());
        }
    }

    isolated resource function get buildings() returns stream<Building, error?> {
        stream<anydata, sql:Error?>|Error result = self.persistClients.get("building").runReadQuery(Building);
        if result is Error {
            return new stream<Building, Error?>(new BuildingStream((), result));
        } else {
            return new stream<Building, Error?>(new BuildingStream(result));
        }
    };

    isolated resource function get buildings/[string buildingCode]() returns Building|error {
        return (check self.persistClients.get("building").runReadByKeyQuery(Building, buildingCode)).cloneWithType(Building);
    };

    isolated resource function post buildings(BuildingInsert[] data) returns string[]|error {
        _ = check self.persistClients.get("building").runBatchInsertQuery(data);
        return from BuildingInsert inserted in data
               select inserted.buildingCode;
    };

    isolated resource function put buildings/[string buildingCode](BuildingUpdate data) returns Building|error {
        _ = check self.persistClients.get("building").runUpdateQuery(buildingCode, data);
        return self->/buildings/[buildingCode].get();
    };

    isolated resource function delete buildings/[string buildingCode]() returns Building|error {
        Building 'object = check self->/buildings/[buildingCode].get();
        _ = check self.persistClients.get("building").runDeleteQuery(buildingCode);
        return 'object;
    };

    isolated resource function get workspaces() returns stream<Workspace, error?> {
        stream<anydata, sql:Error?>|Error result = self.persistClients.get("workspace").runReadQuery(Workspace);
        if result is Error {
            return new stream<Workspace, Error?>(new WorkspaceStream((), result));
        } else {
            return new stream<Workspace, Error?>(new WorkspaceStream(result));
        }
    };

    isolated resource function get workspaces/[string workspaceId]() returns Workspace|error {
        return (check self.persistClients.get("workspace").runReadByKeyQuery(Workspace, workspaceId)).cloneWithType(Workspace);
    };

    isolated resource function post workspaces(WorkspaceInsert[] data) returns string[]|error {
        _ = check self.persistClients.get("workspace").runBatchInsertQuery(data);
        return from WorkspaceInsert inserted in data
               select inserted.workspaceId;
    };

    isolated resource function put workspaces/[string workspaceId](WorkspaceUpdate data) returns Workspace|error {
        _ = check self.persistClients.get("workspace").runUpdateQuery(workspaceId, data);
        return self->/workspaces/[workspaceId].get();
    };

    isolated resource function delete workspaces/[string workspaceId]() returns Workspace|error {
        Workspace 'object = check self->/workspaces/[workspaceId].get();
        _ = check self.persistClients.get("workspace").runDeleteQuery(workspaceId);
        return 'object;
    };

    isolated resource function get departments() returns stream<Department, error?> {
        stream<anydata, sql:Error?>|Error result = self.persistClients.get("department").runReadQuery(Department);
        if result is Error {
            return new stream<Department, Error?>(new DepartmentStream((), result));
        } else {
            return new stream<Department, Error?>(new DepartmentStream(result));
        }
    };

    isolated resource function get departments/[string deptNo]() returns Department|error {
        return (check self.persistClients.get("department").runReadByKeyQuery(Department, deptNo)).cloneWithType(Department);
    };

    isolated resource function post departments(DepartmentInsert[] data) returns string[]|error {
        _ = check self.persistClients.get("department").runBatchInsertQuery(data);
        return from DepartmentInsert inserted in data
               select inserted.deptNo;
    };

    isolated resource function put departments/[string deptNo](DepartmentUpdate data) returns Department|error {
        _ = check self.persistClients.get("department").runUpdateQuery(deptNo, data);
        return self->/departments/[deptNo].get();
    };

    isolated resource function delete departments/[string deptNo]() returns Department|error {
        Department 'object = check self->/departments/[deptNo].get();
        _ = check self.persistClients.get("department").runDeleteQuery(deptNo);
        return 'object;
    };

    isolated resource function get employees() returns stream<Employee, error?> {
        stream<anydata, sql:Error?>|Error result = self.persistClients.get("employee").runReadQuery(Employee);
        if result is Error {
            return new stream<Employee, Error?>(new EmployeeStream((), result));
        } else {
            return new stream<Employee, Error?>(new EmployeeStream(result));
        }
    };

    isolated resource function get employees/[string empNo]() returns Employee|error {
        return (check self.persistClients.get("employee").runReadByKeyQuery(Employee, empNo)).cloneWithType(Employee);
    };

    isolated resource function post employees(EmployeeInsert[] data) returns string[]|error {
        _ = check self.persistClients.get("employee").runBatchInsertQuery(data);
        return from EmployeeInsert inserted in data
               select inserted.empNo;
    };

    isolated resource function put employees/[string empNo](EmployeeUpdate data) returns Employee|error {
        _ = check self.persistClients.get("employee").runUpdateQuery(empNo, data);
        return self->/employees/[empNo].get();
    };

    isolated resource function delete employees/[string empNo]() returns Employee|error {
        Employee 'object = check self->/employees/[empNo].get();
        _ = check self.persistClients.get("employee").runDeleteQuery(empNo);
        return 'object;
    };

    public function close() {
        
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
        if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            sql:Error? e = anydataStream.close();
            if e is sql:Error {
                return <Error>error(e.message());
            }
        }
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
        if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            sql:Error? e = anydataStream.close();
            if e is sql:Error {
                return <Error>error(e.message());
            }
        }
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
        if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            sql:Error? e = anydataStream.close();
            if e is sql:Error {
                return <Error>error(e.message());
            }
        }
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
        if self.anydataStream is stream<anydata, sql:Error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            sql:Error? e = anydataStream.close();
            if e is sql:Error {
                return <Error>error(e.message());
            }
        }
    }
}
