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

client class StudentClient {
    *AbstractPersistClient;

    private final string entityName = "Student";
    private final sql:ParameterizedQuery tableName = `Students`;
    private final map<FieldMetadata> fieldMetadata = {
        studentId: {columnName: "studentId", 'type: int},
        firstName: {columnName: "firstName", 'type: string},
        lastName: {columnName: "lastName", 'type: string},
        dob: {columnName: "dob", 'type: time:Date},
        contact: {columnName: "contact", 'type: string},
        "lectures[].lectureId": {'type: int, relation: {entityName: "lecture", refTable: "Lecture", refField: "lectureId", refColumnName: "lectureId"}},
        "lectures[].subject": {'type: string, relation: {entityName: "lecture", refTable: "Lecture", refField: "subject", refColumnName: "subject"}},
        "lectures[].day": {'type: string, relation: {entityName: "lecture", refTable: "Lecture", refField: "day", refColumnName: "day"}},
        "lectures[].time": {'type: string, relation: {entityName: "lecture", refTable: "Lecture", refField: "time", refColumnName: "time"}}
    };
    private string[] keyFields = ["studentId"];
    private final map<JoinMetadata> joinMetadata = {
        lecture: {entity: Lecture, fieldName: "lectures", refTable: "Lectures", refColumns: ["lectureId"], joinColumns: ["i_lectureId"], joinTable: "StudentsLectures", intermediateJoinColumns: ["studentId"], intermediateRefFields: ["i_studentId"], 'type: MANY}
    };

    private SQLClient persistClient;

    public function init() returns Error? {
        mysql:Client|sql:Error dbClient = new (host = host, user = user, password = password, database = database, port = port);
        if dbClient is sql:Error {
            return <Error>error(dbClient.message());
        }

        self.persistClient = check new (dbClient, self.entityName, self.tableName, self.keyFields, self.fieldMetadata, self.joinMetadata);
    }

    remote function create(Student value) returns Student|Error {
        if value.lectures is Lecture[] {
            LectureClient lectureClient = check new LectureClient();
            Lecture[] insertedEntities = [];
            foreach Lecture lecture in <Lecture[]>value.lectures {
                Lecture inserted = lecture;
                boolean exists = check lectureClient->exists(lecture);
                if !exists {
                    inserted = check lectureClient->create(lecture);
                }
                insertedEntities.push(inserted);
            }
            value.lectures = insertedEntities;
        }

        _ = check self.persistClient.runInsertQuery(value);
        _ = check self.persistClient.populateIntermediateTables(value);

        return value;
    }

    remote function readByKey(int key, StudentRelations[] include = []) returns Student|Error {
        return <Student>check self.persistClient.runReadByKeyQuery(Student, key, include);
    }

    remote function read(StudentRelations[] include = []) returns stream<Student, Error?> {
        stream<anydata, sql:Error?>|Error result = self.persistClient.runReadQuery(Student, include);
        if result is Error {
            return new stream<Student, Error?>(new StudentStream((), result));
        } else {
            return new stream<Student, Error?>(new StudentStream(result));
        }
    }

    remote function update(record {} 'object) returns Error? {
        _ = check self.persistClient.runUpdateQuery('object);

        // if 'object["lectures"] is Lecture[] {
        //     Company companyEntity = <Company>'object["company"];
        //     CompanyClient companyClient = check new CompanyClient();
        //     check companyClient->update(companyEntity);
        // }
    }

    remote function delete(Student 'object) returns Error? {
        _ = check self.persistClient.runDeleteQuery('object);
    }

    remote function exists(Student student) returns boolean|Error {
        Student|Error result = self->readByKey(student.studentId);
        if result is Student {
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

public enum StudentRelations {
    LectureEntity = "lecture"
}

public class StudentStream {
    private stream<anydata, sql:Error?>? anydataStream;
    private Error? err;
    private StudentRelations[]? include;
    private SQLClient? persistClient;

    public isolated function init(stream<anydata, sql:Error?>? anydataStream, Error? err = (), StudentRelations[]? include = (), SQLClient? persistClient = ()) {
        self.anydataStream = anydataStream;
        self.err = err;
        self.include = include;
        self.persistClient = persistClient;
    }

    public isolated function next() returns record {|Student value;|}|Error? {
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
                record {|Student value;|} nextRecord = {value: <Student>streamValue.value};
                check (<SQLClient>self.persistClient).getManyRelations(nextRecord.value, <StudentRelations[]>self.include);
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
