// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
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

client class LectureClient {
    *AbstractPersistClient;

    private final string entityName = "Lecture";
    private final sql:ParameterizedQuery tableName = `Lectures`;
    private final map<FieldMetadata> fieldMetadata = {
        o_lectureId: {columnName: "lectureId", 'type: int},
        o_subject: {columnName: "subject", 'type: string},
        o_time: {columnName: "time", 'type: time:TimeOfDay},
        o_day: {columnName: "day", 'type: string},
        "o_students[].o_studentId": {'type: int, relation: {entityName: "student", refTable: "Lecture", refField: "o_studentId", refColumnName: "studentId"}},
        "o_students[].o_firstName": {'type: string, relation: {entityName: "student", refTable: "Lecture", refField: "o_firstName", refColumnName: "firstName"}},
        "o_students[].o_lastName": {'type: string, relation: {entityName: "student", refTable: "Lecture", refField: "o_lastName", refColumnName: "lastName"}},
        "o_students[].o_dob": {'type: time:Date, relation: {entityName: "student", refTable: "Lecture", refField: "o_dob", refColumnName: "dob"}},
        "o_students[].o_contact": {'type: string, relation: {entityName: "student", refTable: "Lecture", refField: "o_contact", refColumnName: "contact"}}
    };
    private string[] keyFields = ["o_lectureId"];
    private final map<JoinMetadata> joinMetadata = {
        student: {entity: Student, fieldName: "o_students", refTable: "Students", refColumns: ["studentId"], joinColumns: ["i_studentId"], joinTable: "StudentsLectures", joiningJoinColumns: ["lectureId"], joiningRefColumns: ["i_lectureId"], 'type: MANY}
    };

    private SQLClient persistClient;

    public function init() returns Error? {
        mysql:Client|sql:Error dbClient = new (host = host, user = user, password = password, database = database, port = port);
        if dbClient is sql:Error {
            return <Error>error(dbClient.message());
        }

        self.persistClient = check new (dbClient, self.entityName, self.tableName, self.keyFields, self.fieldMetadata, self.joinMetadata);
    }

    remote function create(Lecture value) returns Lecture|Error {
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
        _ = check self.persistClient.populateJoinTables(value);

        return value;
    }

    remote function readByKey(int key, LectureRelations[] include = []) returns Lecture|Error {
        return <Lecture>check self.persistClient.runReadByKeyQuery(Lecture, key, include);
    }

    remote function read(LectureRelations[] include = []) returns stream<Lecture, Error?> {
        stream<anydata, sql:Error?>|Error result = self.persistClient.runReadQuery(Lecture, include);
        if result is Error {
            return new stream<Lecture, Error?>(new LectureStream((), result));
        } else {
            return new stream<Lecture, Error?>(new LectureStream(result, (), include, self.persistClient));
        }
    }

    remote function update(Lecture 'object) returns Error? {
        _ = check self.persistClient.runUpdateQuery('object);
    }

    remote function delete(Lecture 'object) returns Error? {
        _ = check self.persistClient.runDeleteQuery('object);
    }

    remote function exists(Lecture lecture) returns boolean|Error {
        Lecture|Error result = self->readByKey(lecture.o_lectureId);
        if result is Lecture {
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

public enum LectureRelations {
    StudentEntity = "student"
}

public class LectureStream {
    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;
    private LectureRelations[]? include;
    private SQLClient? persistClient;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = (), LectureRelations[]? include = (), SQLClient? persistClient = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
        self.include = include;
        self.persistClient = persistClient;
    }

    public isolated function next() returns record {|Lecture value;|}|Error? {
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
                record {|Lecture value;|} nextRecord = {value: <Lecture>streamValue.value};
                check (<SQLClient>self.persistClient).getManyRelations(nextRecord.value, <LectureRelations[]>self.include);
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
