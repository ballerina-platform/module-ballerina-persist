// Copyright (c) 2022 WSO2 LLC. (http://www.wso2.org). All Rights Reserved.
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

import ballerinax/mysql;
import ballerina/sql;
import ballerina/time;

client class PaperClient {
    *AbstractPersistClient;

    private final string entityName = "Paper";
    private final sql:ParameterizedQuery tableName = `Paper`;
    private final map<FieldMetadata> fieldMetadata = {
        subjectId: {columnName: "subjectId", 'type: int},
        paperDate: {columnName: "paperDate", 'type: time:Date},
        title: {columnName: "title", 'type: string},
        "students[].nic": {'type: int, relation: {entityName: "student", refTable: "Student", refField: "nic", refColumnName: "nic"}},
        "students[].firstName": {'type: string, relation: {entityName: "student", refTable: "Student", refField: "firstName", refColumnName: "firstName"}},
        "students[].lastName": {'type: string, relation: {entityName: "student", refTable: "Student", refField: "lastName", refColumnName: "lastName"}},
        "students[].dob": {'type: time:Date, relation: {entityName: "student", refTable: "Student", refField: "dob", refColumnName: "dob"}},
        "students[].contact": {'type: string, relation: {entityName: "student", refTable: "Student", refField: "contact", refColumnName: "contact"}}
    };
    private string[] keyFields = ["subjectId", "paperDate"];
    private final map<JoinMetadata> joinMetadata = {
        students: {entity: Student, fieldName: "students", refTable: "Student", refColumns: ["nic"], joinColumns: ["student_nic"], joinTable: "Student_Paper", joiningJoinColumns: ["subjectId", "paperDate"], joiningRefColumns: ["paper_subjectId", "paper_paperDate"], 'type: MANY}
    };

    private SQLClient persistClient;

    public function init() returns Error? {
        mysql:Client|sql:Error dbClient = new (host = host, user = user, password = password, database = database, port = port);
        if dbClient is sql:Error {
            return <Error>error(dbClient.message());
        }

        self.persistClient = check new (dbClient, self.entityName, self.tableName, self.keyFields, self.fieldMetadata, self.joinMetadata);
    }

    remote function create(Paper value) returns Paper|Error {
        if value.students is Student[] {
            StudentClient studentClient = check new StudentClient();
            Student[] insertedEntities = [];
            foreach Student student in <Student[]>value.students {
                Student inserted = student;
                boolean exists = check studentClient->exists(student);
                if !exists {
                    inserted = check studentClient->create(student);
                }
                insertedEntities.push(inserted);
            }
            value.students = insertedEntities;
        }

        _ = check self.persistClient.runInsertQuery(value);

        return value;
    }

    remote function readByKey(record {|int subjectId; time:Date paperDate;|} key) returns Paper|Error {
        return <Paper>check self.persistClient.runReadByKeyQuery(Paper, key);
    }

    remote function read(PaperRelations[] include = []) returns stream<Paper, Error?> {
        stream<anydata, sql:Error?>|Error result = self.persistClient.runReadQuery(Paper, include);
        if result is Error {
            return new stream<Paper, Error?>(new PaperStream((), result));
        } else {
            return new stream<Paper, Error?>(new PaperStream(result));
        }
    }

    remote function update(Paper 'object, PaperRelations[] updateAssociations = []) returns Error? {
        if (<string[]>updateAssociations).indexOf(students) != () && 'object.students is Student[] {
            StudentClient studentClient = check new StudentClient();
            foreach Student student in <Student[]>'object.students {
                boolean exists = check studentClient->exists(student);
                if !exists {
                    _ = check studentClient->create(student);
                } else {
                    check studentClient->update(student);
                }
            }
        }

        _ = check self.persistClient.runUpdateQuery('object, updateAssociations);
    }

    remote function delete(Paper 'object) returns Error? {
        _ = check self.persistClient.runDeleteQuery('object);
    }

    remote function exists(Paper paper) returns boolean|Error {
        Paper|Error result = self->readByKey({subjectId: paper.subjectId, paperDate:paper.paperDate});
        if result is Paper {
            return true;
        } else if result is InvalidKeyError {
            return false;
        } else {
            return result;
        }
    }

    function close() returns Error? {
        return self.persistClient.close();
    }

}

public enum PaperRelations {
    students
}

public class PaperStream {
    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;
    private PaperRelations[]? include;
    private SQLClient? persistClient;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = (), PaperRelations[]? include = (), SQLClient? persistClient = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
        self.include = include;
        self.persistClient = persistClient;
    }

    public isolated function next() returns record {|Paper value;|}|Error? {
        if self.err is Error {
            return self.err;
        } else if self.anydataStream is stream<anydata, error?> {
            var anydataStream = <stream<anydata, sql:Error?>>self.anydataStream;
            var streamValue = anydataStream.next();
            if streamValue is () {
                return streamValue;
            } else if (streamValue is error) {
                return <Error>error(streamValue.message());
            } else {
                record {|Paper value;|} nextRecord = {value: <Paper>streamValue.value};
                check (<SQLClient>self.persistClient).getManyRelations(nextRecord.value, <PaperRelations[]>self.include);
                return nextRecord;
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
