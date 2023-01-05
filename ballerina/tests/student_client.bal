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

client class StudentClient {
    *AbstractPersistClient;

    private final string entityName = "Student";
    private final sql:ParameterizedQuery tableName = `Student`;
    private final map<FieldMetadata> fieldMetadata = {
        nic: {columnName: "nic", 'type: string},
        firstName: {columnName: "firstName", 'type: string},
        lastName: {columnName: "lastName", 'type: string},
        dob: {columnName: "dob", 'type: time:Date},
        contact: {columnName: "contact", 'type: string},
        "lectures[].code": {'type: int, relation: {entityName: "lecture", refField: "code"}},
        "lectures[].subject": {'type: string, relation: {entityName: "lecture", refField: "subject"}},
        "lectures[].day": {'type: string, relation: {entityName: "lecture", refField: "day"}},
        "lectures[].time": {'type: string, relation: {entityName: "lecture", refField: "time"}},
        "papers[].subjectId": {'type: int, relation: {entityName: "paper", refField: "subjectId"}},
        "papers[].paperDate": {'type: time:Date, relation: {entityName: "paper", refField: "paperDate"}},
        "papers[].title": {'type: string, relation: {entityName: "paper", refField: "title"}}
    };
    private string[] keyFields = ["nic"];
    private final map<JoinMetadata> joinMetadata = {
        lectures: {entity: Lecture, fieldName: "lectures", refTable: "Lecture", refColumns: ["code"], joinColumns: ["lecture_code"], joinTable: "joinStudentLecture", joiningJoinColumns: ["nic"], joiningRefColumns: ["student_nic"], 'type: MANY_TO_MANY},
        papers: {entity: Paper, fieldName: "papers", refTable: "Paper", refColumns: ["subjectId", "paperDate"], joinColumns: ["paper_subjectId", "paper_paperDate"], joinTable: "joinStudentPaper", joiningJoinColumns: ["nic"], joiningRefColumns: ["student_nic"], 'type: MANY_TO_MANY}
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
        //TODO: Future improvement - perform batch insertion
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

        if value.papers is Paper[] {
            PaperClient paperClient = check new PaperClient();
            Paper[] insertedEntities = [];
            foreach Paper paper in <Paper[]>value.papers {
                Paper inserted = paper;
                boolean exists = check paperClient->exists(paper);
                if !exists {
                    inserted = check paperClient->create(paper);
                }
                insertedEntities.push(inserted);
            }
            value.papers = insertedEntities;
        }

        _ = check self.persistClient.runInsertQuery(value);

        return value;
    }

    remote function readByKey(string key, StudentRelations[] include = []) returns Student|Error {
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

    remote function update(Student 'object, StudentRelations[] updateAssociations = []) returns Error? {
        if (<string[]>updateAssociations).indexOf(lectures) != () && 'object.lectures is Lecture[] {
            LectureClient lectureClient = check new LectureClient();
            foreach Lecture lecture in <Lecture[]>'object.lectures {
                boolean exists = check lectureClient->exists(lecture);
                if !exists {
                    _ = check lectureClient->create(lecture);
                } else {
                    check lectureClient->update(lecture);
                }
            }
        }

         if (<string[]>updateAssociations).indexOf(papers) != () && 'object.papers is Paper[] {
            PaperClient paperClient = check new PaperClient();
            foreach Paper paper in <Paper[]>'object.papers {
                boolean exists = check paperClient->exists(paper);
                if !exists {
                    _ = check paperClient->create(paper);
                } else {
                    check paperClient->update(paper);
                }
            }
        }

        _ = check self.persistClient.runUpdateQuery('object, updateAssociations);
    }

    remote function delete(Student 'object) returns Error? {
        _ = check self.persistClient.runDeleteQuery('object);
    }

    remote function exists(Student student) returns boolean|Error {
        Student|Error result = self->readByKey(student.nic);
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
    lectures,
    papers
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
                // TODO: Future improvement - performance improvement by minimizing #queries executed
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
