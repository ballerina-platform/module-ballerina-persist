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
    private final sql:ParameterizedQuery tableName = `Papers`;
    private final map<FieldMetadata> fieldMetadata = {
        o_subjectId: {columnName: "subjectId", 'type: int},
        o_date: {columnName: "paperDate", 'type: time:Date},
        o_title: {columnName: "title", 'type: string},
        "o_students[].o_studentId": {'type: int, relation: {entityName: "student", refTable: "Lecture", refField: "o_studentId", refColumnName: "studentId"}},
        "o_students[].o_firstName": {'type: string, relation: {entityName: "student", refTable: "Lecture", refField: "o_firstName", refColumnName: "firstName"}},
        "o_students[].o_lastName": {'type: string, relation: {entityName: "student", refTable: "Lecture", refField: "o_lastName", refColumnName: "lastName"}},
        "o_students[].o_dob": {'type: time:Date, relation: {entityName: "student", refTable: "Lecture", refField: "o_dob", refColumnName: "dob"}},
        "o_students[].o_contact": {'type: string, relation: {entityName: "student", refTable: "Lecture", refField: "o_contact", refColumnName: "contact"}}
    };
    private string[] keyFields = ["o_subjectId", "o_date"];
    private final map<JoinMetadata> joinMetadata = {
        student: {entity: Student, fieldName: "o_students", refTable: "Students", refColumns: ["studentId"], joinColumns: ["i_studentId"], joinTable: "StudentsLectures", joiningJoinColumns: ["subjectId", "paperDate"], joiningRefColumns: ["i_subjectId", "i_date"], 'type: MANY}
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
        if value.o_students is Student[] {
            StudentClient studentClient = check new StudentClient();
            Student[] insertedEntities = [];
            foreach Student student in <Student[]>value.o_students {
                Student inserted = student;
                boolean exists = check studentClient->exists(student);
                if !exists {
                    inserted = check studentClient->create(student);
                }
                insertedEntities.push(inserted);
            }
            value.o_students = insertedEntities;
        }

        _ = check self.persistClient.runInsertQuery(value);

        return value;
    }

    remote function readByKey(record {|int o_subjectId; time:Date o_date;|} key) returns Paper|Error {
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
        if (<string[]>updateAssociations).indexOf(StudentEntity) != () && 'object["o_students"] is Student[] {
            StudentClient studentClient = check new StudentClient();
            foreach Student student in <Student[]>'object["o_students"] {
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
        Paper|Error result = self->readByKey({o_subjectId: paper.o_subjectId, o_date:paper.o_date});
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
    StudentEntity = "student"
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
