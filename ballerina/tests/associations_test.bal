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

import ballerina/test;

@test:Config {
    groups: ["associations"]
}
function oneToOneCreateTest1() returns error? {
    Owner owner = {
        id: 1,
        name: "TestOwner"
    };
    OwnerClient ownerClient = check new ();
    _ = check ownerClient->create(owner);

    Profile profile = {
        id: 1,
        name: "TestProfile2",
        owner: owner
    };
    ProfileClient profileClient = check new ();
    Profile profile2 = check profileClient->create(profile);

    Profile profile3 = check profileClient->readByKey(1, ["owner"]);
    test:assertEquals(profile, profile2);
    test:assertEquals(profile, profile3);
}

@test:Config {
    groups: ["associations"]
}
function oneToOneCreateTest2() returns error? {
    Owner owner = {
        id: 3,
        name: "TestOwner"
    };
    OwnerClient ownerClient = check new ();
    _ = check ownerClient->create(owner);
    Owner owner2 = check ownerClient->readByKey(3);

    test:assertEquals(owner, owner2);
}

@test:Config {
    groups: ["associations"]
}
function oneToOneCreateTest3() returns error? {
    Profile profile = {
        id: 3,
        name: "TestProfile"
    };
    ProfileClient profileClient = check new ();
    _ = check profileClient->create(profile);
    Profile profile2 = check profileClient->readByKey(3);

    test:assertEquals(profile, profile2);
}

@test:Config {
    groups: ["associations"]
}
function oneToOneCreateTest4() returns error? {
    Profile profile = {
        id: 4,
        name: "TestProfile",
        owner: {
            id: 3,
            name: "TestOwner"
        }
    };
    ProfileClient profileClient = check new ();
    _ = check profileClient->create(profile);
    Profile profile2 = check profileClient->readByKey(4, [owner]);

    test:assertEquals(profile, profile2);
}

@test:Config {
    groups: ["associations"]
}
function oneToOneReadTest1() returns error? {
    Profile profile = {
        id: 24,
        name: "TestProfile",
        owner: {
            id: 23,
            name: "TestOwner"
        }
    };
    ProfileClient profileClient = check new ();
    _ = check profileClient->create(profile);

    Profile profile2 = check profileClient->readByKey(24, [owner]);
    test:assertEquals(profile, profile2);

    OwnerClient ownerClient = check new ();
    Owner owner = check ownerClient->readByKey(23, ["profile"]);
    test:assertEquals(owner, {
        id: 23,
        name: "TestOwner",
        profile: {
            id: 24,
            name: "TestProfile"
        }
    });
}

@test:Config {
    groups: ["associations"]
}
function oneToOneUpdateTest1() returns error? {
    Profile profile = {
        id: 5,
        name: "TestProfile",
        owner: {
            id: 4,
            name: "TestOwner"
        }
    };
    ProfileClient profileClient = check new ();
    _ = check profileClient->create(profile);

    profile.name = "TestUpdatedProfile";
    profile.owner.name = "TestUpdatedOwner";
    _ = check profileClient->update(profile, [UserEntity]);

    Profile profile2 = check profileClient->readByKey(5, [owner]);
    Profile expectedProfile = {
        id: 5,
        name: "TestUpdatedProfile",
        owner: {
            id: 4,
            name: "TestUpdatedOwner"
        }
    };
    test:assertEquals(profile2, expectedProfile);
}

@test:Config {
    groups: ["associations"]
}
function oneToOneUpdateTest2() returns error? {
    Profile profile = {
        id: 6,
        name: "TestProfile",
        owner: {
            id: 5,
            name: "TestOwner"
        }
    };
    ProfileClient profileClient = check new ();
    _ = check profileClient->create(profile);

    profile.name = "TestUpdatedProfile";
    profile.owner = {
        id: 4,
        name: "TestUpdatedOwner"
    };
    _ = check profileClient->update(profile, [UserEntity]);

    Profile profile2 = check profileClient->readByKey(6, [owner]);
    Profile expectedProfile = {
        id: 6,
        name: "TestUpdatedProfile",
        owner: {
            id: 4,
            name: "TestUpdatedOwner"
        }
    };
    test:assertEquals(profile2, expectedProfile);
}

@test:Config {
    groups: ["associations"]
}
function oneToOneUpdateTest3() returns error? {
    Profile profile = {
        id: 7,
        name: "TestProfile",
        owner: {
            id: 6,
            name: "TestOwner"
        }
    };
    ProfileClient profileClient = check new ();
    _ = check profileClient->create(profile);

    profile.name = "TestUpdatedProfile";
    profile.owner = {
        id: 7,
        name: "TestUpdatedOwner"
    };
    ForeignKeyConstraintViolationError|error? result = profileClient->update(profile);
    test:assertTrue(result is ForeignKeyConstraintViolationError);
}

@test:Config {
    groups: ["associations"]
}
function MultipleAssociationsTest() returns error? {
    MultipleAssociations ma = {
        id: 1,
        name: "TestMultipleAssociation",
        profile: {
            id: 31,
            name: "Test Profile"
        },
        owner: {
            id: 31,
            name: "TestOwner"
        }
    };

    MultipleAssociationsClient maClient = check new ();
    MultipleAssociations ma2 = check maClient->create(ma);
    test:assertEquals(ma, ma2);

    MultipleAssociations ma3 = check maClient->readByKey(1, [profile, owner]);
    test:assertEquals(ma, ma3);

    MultipleAssociations ma4 = check maClient->readByKey(1, [profile]);
    test:assertEquals({
        id: 1,
        name: "TestMultipleAssociation",
        profile: {
            id: 31,
            name: "Test Profile"
        }
    }, ma4);

    MultipleAssociations ma5 = check maClient->readByKey(1, [owner]);
    test:assertEquals({
        id: 1,
        name: "TestMultipleAssociation",
        owner: {
            id: 31,
            name: "TestOwner"
        }
    }, ma5);
}

@test:Config {
    groups: ["associations", "one-to-many"]
}
function oneToManyCreateTest1() returns error? {
    Company company = {
        id: 1,
        name: "TestCompany1"
    };
    CompanyClient companyClient = check new ();
    _ = check companyClient->create(company);

    Employee employee = {
        id: 1,
        name: "TestEmployee1",
        company: company
    };
    EmployeeClient employeeClient = check new ();
    Employee employee2 = check employeeClient->create(employee);

    Employee employee3 = check employeeClient->readByKey(1, ["company"]);
    test:assertEquals(employee, employee2);
    test:assertEquals(employee, employee3);
}

@test:Config {
    groups: ["associations", "one-to-many"]
}
function oneToManyCreateTest2() returns error? {
    Company company = {
        id: 2,
        name: "TestCompany2"
    };
    CompanyClient companyClient = check new ();
    _ = check companyClient->create(company);

    EmployeeClient employeeClient = check new ();

    Employee employee1 = {
        id: 2,
        name: "TestEmployee2",
        company: company
    };
    _ = check employeeClient->create(employee1);

    Employee employee2 = {
        id: 3,
        name: "TestEmployee3",
        company: company
    };
    _ = check employeeClient->create(employee2);

    Company company2 = check companyClient->readByKey(2, [EmployeeEntity]);
    test:assertEquals(company2, <Company>{
        id: 2,
        name: "TestCompany2",
        employees: [{id: 2, name: "TestEmployee2"}, {id: 3, name: "TestEmployee3"}]
    });
}

@test:Config {
    groups: ["associations", "one-to-many"]
}
function oneToManyCreateTest3() returns error? {
    Company company = {
        id: 3,
        name: "TestCompany3"
    };
    CompanyClient companyClient = check new ();
    _ = check companyClient->create(company);

    EmployeeClient employeeClient = check new ();

    Employee employee1 = {
        id: 4,
        name: "TestEmployee4",
        company: company
    };
    _ = check employeeClient->create(employee1);

    Employee employee2 = {
        id: 5,
        name: "TestEmployee5",
        company: company
    };
    _ = check employeeClient->create(employee2);

    check from Company company2 in companyClient->read([EmployeeEntity])
        where company2.id == 3
        do {
            test:assertEquals(company2, <Company>{
                id: 3,
                name: "TestCompany3",
                employees: [{id: 4, name: "TestEmployee4"}, {id: 5, name: "TestEmployee5"}]
            });
        };
}

@test:Config {
    groups: ["associations", "one-to-manyx"]
}
function oneToManyCreateTest4() returns error? {
    Company company = {
        id: 4,
        name: "TestCompany4"
    };
    CompanyClient companyClient = check new ();
    _ = check companyClient->create(company);

    EmployeeClient employeeClient = check new ();

    Employee employee1 = {
        id: 6,
        name: "TestEmployee6",
        company: company
    };
    _ = check employeeClient->create(employee1);

    Employee employee2 = {
        id: 7,
        name: "TestEmployee7",
        company: company
    };
    _ = check employeeClient->create(employee2);

    Employee employee = check employeeClient->readByKey(6, ["company"]);
    test:assertEquals(employee, <Employee>{
        id: 6,
        name: "TestEmployee6",
        company: {id: 4, name: "TestCompany4"}
    });
}

@test:Config {
    groups: ["associations", "one-to-manyx"]
}
function oneToManyUpdateTest4() returns error? {
    Company company = {
        id: 5,
        name: "TestCompany5"
    };
    CompanyClient companyClient = check new ();
    _ = check companyClient->create(company);

    EmployeeClient employeeClient = check new ();

    Employee employee1 = {
        id: 8,
        name: "TestEmployee8",
        company: company
    };
    _ = check employeeClient->create(employee1);

    Employee employee2 = {
        id: 9,
        name: "TestEmployee9",
        company: company
    };
    _ = check employeeClient->create(employee2);

    employee1.name = "TestEmployeeUpdated8";
    employee1.company.name = "TestCompanyUpdated5";
    _ = check employeeClient->update(employee1, [CompanyEntity]);
    Company company2 = check companyClient->readByKey(5, [EmployeeEntity]);
    test:assertEquals(company2, <Company>{
        id: 5,
        name: "TestCompanyUpdated5",
        employees: [{id: 8, name: "TestEmployeeUpdated8"}, {id: 9, name: "TestEmployee9"}]
    });
}

@test:Config {
    groups: ["associations", "many-to-many"]
}
function manyToManyCreateTest1() returns error? {
    Lecture lecture1 = {
        code: "L1",
        subject: "TestLecture1",
        day: "monday",
        time: {hour: 13, minute: 1, second: 0}
    };

    Lecture lecture2 = {
        code: "L2",
        subject: "TestLecture2",
        day: "tuesday",
        time: {hour: 13, minute: 2, second: 0}
    };

    Paper paper1 = {
        subjectId: 1,
        paperDate: {year: 2022, month: 12, day: 14},
        title: "Maths"
    };

    Paper paper2 = {
        subjectId: 1,
        paperDate: {year: 2022, month: 11, day: 14},
        title: "Maths2"
    };

    Paper paper3 = {
        subjectId: 2,
        paperDate: {year: 2022, month: 12, day: 15},
        title: "English"
    };

    Student student = {
        nic: "938582039V",
        firstName: "Tom",
        lastName: "Scott",
        dob: {year: 1996, month: 12, day: 12},
        contact: "0771952226",
        lectures: [lecture1, lecture2],
        papers: [paper2, paper1, paper3]
    };
    StudentClient studentClient = check new();
    _ = check studentClient->create(student);

    Student studentR = check studentClient->readByKey("938582039V", [lectures, papers]);
    test:assertEquals(studentR, student);
}

@test:Config {
    groups: ["associations", "many-to-many"]
}
function manyToManyCreateTest2() returns error? {
    Student student = {
        nic: "983749204V",
        firstName: "Tom",
        lastName: "Scott",
        dob: {year: 1996, month: 12, day: 12},
        contact: "0771952226"
    };

    Student student2 = {
        nic: "982759294V",
        firstName: "Tom2",
        lastName: "Scott2",
        dob: {year: 1996, month: 12, day: 12},
        contact: "0771952222"
    };

    Lecture lecture = {
        code: "L3",
        subject: "TestLecture11",
        day: "monday",
        time: {hour: 13, minute: 1, second: 0},
        students: [student2, student]
    };

    LectureClient lectureClient = check new();
    _ = check lectureClient->create(lecture);

    Lecture lectureR = check lectureClient->readByKey("L3", [students]);
    test:assertEquals(lectureR, lecture);
}

@test:Config {
    groups: ["associations", "many-to-many"],
    dependsOn: [manyToManyCreateTest2]
}
function manyToManyUpdateTest1() returns error? {
    LectureClient lectureClient = check new();
    Lecture lecture = check lectureClient->readByKey("L3", [students]);

    Student student1 = (<Student[]>lecture.students)[0];
    student1.firstName = "TomUpdated";

    Student student3 = {
        nic: "973749278V",
        firstName: "Tom3",
        lastName: "Scott3",
        dob: {year: 1996, month: 12, day: 12},
        contact: "0771952222"
    };

    lecture.students = [student3, student1];
    _ = check lectureClient->update(lecture, [students]);

    Lecture lectureR = check lectureClient->readByKey("L3", [students]);
    test:assertEquals(lectureR, lecture);
}

@test:Config {
    groups: ["associations", "many-to-many"],
    dependsOn: [manyToManyCreateTest1]
}
function manyToManyUpdateTest2() returns error? {
    Student student = {
        nic: "938582039V",
        firstName: "TomUpdated",
        lastName: "Scott",
        dob: {year: 1996, month: 12, day: 12},
        contact: "0771952226"
    };
    StudentClient studentClient = check new();
    _ = check studentClient->update(student);
    Student studentR = check studentClient->readByKey("938582039V", [lectures, papers]);

    Lecture lecture1 = {
        code: "L1",
        subject: "TestLecture1",
        day: "monday",
        time: {hour: 13, minute: 1, second: 0}
    };

    Lecture lecture2 = {
        code: "L2",
        subject: "TestLecture2",
        day: "tuesday",
        time: {hour: 13, minute: 2, second: 0}
    };

    Paper paper1 = {
        subjectId: 1,
        paperDate: {year: 2022, month: 12, day: 14},
        title: "Maths"
    };

    Paper paper2 = {
        subjectId: 1,
        paperDate: {year: 2022, month: 11, day: 14},
        title: "Maths2"
    };

    Paper paper3 = {
        subjectId: 2,
        paperDate: {year: 2022, month: 12, day: 15},
        title: "English"
    };

    Student expectedStudent = {
        nic: "938582039V",
        firstName: "TomUpdated",
        lastName: "Scott",
        dob: {year: 1996, month: 12, day: 12},
        contact: "0771952226",
        lectures: [lecture1, lecture2],
        papers: [paper2, paper1, paper3]
    };

    test:assertEquals(studentR, expectedStudent);
}

@test:Config {
    groups: ["associations", "many-to-many"],
    dependsOn: [manyToManyUpdateTest2]
}
function manyToManyUpdateTest3() returns error? {
    StudentClient studentClient = check new();
    Student student = check studentClient->readByKey("938582039V", [lectures]);
    student.lectures[0].subject = "TestLecture1Updated";
    student.firstName = "TomUpdatedAgain";
    _ = check studentClient->update(student, [lectures]);

    Student studentR = check studentClient->readByKey("938582039V", [lectures, papers]);

    Lecture lecture1 = {
        code: "L1",
        subject: "TestLecture1Updated",
        day: "monday",
        time: {hour: 13, minute: 1, second: 0}
    };

    Lecture lecture2 = {
        code: "L2",
        subject: "TestLecture2",
        day: "tuesday",
        time: {hour: 13, minute: 2, second: 0}
    };

    Paper paper1 = {
        subjectId: 1,
        paperDate: {year: 2022, month: 12, day: 14},
        title: "Maths"
    };

    Paper paper2 = {
        subjectId: 1,
        paperDate: {year: 2022, month: 11, day: 14},
        title: "Maths2"
    };

    Paper paper3 = {
        subjectId: 2,
        paperDate: {year: 2022, month: 12, day: 15},
        title: "English"
    };

    Student expectedStudent = {
        nic: "938582039V",
        firstName: "TomUpdatedAgain",
        lastName: "Scott",
        dob: {year: 1996, month: 12, day: 12},
        contact: "0771952226",
        lectures: [lecture1, lecture2],
        papers: [paper2, paper1, paper3]
    };

    test:assertEquals(studentR, expectedStudent);
}