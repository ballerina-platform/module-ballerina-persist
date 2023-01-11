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

import ballerina/time;

@Entity {
    id: ["needId"]
}
public type MedicalNeed record {|
    @AutoIncrement
    readonly int needId = -1;

    int itemId;
    int beneficiaryId;
    time:Civil period;
    string urgency;
    int quantity;
|};

@Entity {
    id: ["itemId"]
}
public type MedicalItem record {|
    readonly int itemId;
    string name;
    string 'type;
    string unit;
|};

@Entity {
    id: ["complexTypeId"]
}
public type ComplexType record {|
    @AutoIncrement
    readonly int complexTypeId = -1;
    time:Civil civilType;
    time:TimeOfDay timeOfDayType;
    time:Date dateType;
|};

@Entity {
    id: ["hospitalCode", "departmentId"]
}
public type Department record {|
    string hospitalCode;
    int departmentId;
    string name;
|};

// One-to-one relation
@Entity {
    id: ["id"]
}
public type Owner record {|
    readonly int id;
    string name;
    Profile profile?;
    MultipleAssociations multipleAssociations?;
|};

@Entity {
    id: ["id"]
}
public type Profile record {|
    readonly int id;
    string name;
    @Relation {fields: ["ownerId"], referencedFields: ["id"]}
    Owner owner?;
    MultipleAssociations multipleAssociations?;
|};

@Entity {
    id: ["id"]
}
public type MultipleAssociations record {|
    readonly int id;
    string name;

    @Relation {fields: ["profileId"], referencedFields: ["id"]}
    Profile profile?;

    @Relation {fields: ["userId"], referencedFields: ["id"]}
    Owner owner?;
|};

// One-to-many relation
@Entity {
    id: ["id"]
}
public type Company record {|
    readonly int id;
    string name;
    Employee[] employees?;
|};

@Entity {
    id: ["id"]
}
public type Employee record {|
    readonly int id;
    string name;

    @Relation {fields: ["companyId"], referencedFields: ["id"]}
    Company company?;
|};


// Many-to-many relation
@Entity {
    id: ["nic"]
}
public type Student record {|
    string nic;
    string firstName;
    string lastName;
    time:Date dob;
    string contact;

    @Relation {
        name: "joinStudentLecture"
    }
    Lecture[] lectures?;

    @Relation {
        name: "joinStudentPaper"
    }
    Paper[] papers?;
|};

@Entity {
    id: ["code"]
}
public type Lecture record {|
    string code;
    string subject;
    string day;
    time:TimeOfDay time;

    @Relation {
        name: "joinStudentLecture"
    }
    Student[] students?;
|};

@Entity {
    id: ["subjectId", "paperDate"]
}
public type Paper record {|
    int subjectId;
    time:Date paperDate;
    string title;
    
    @Relation {
        name: "joinStudentPaper"
    }
    Student[] students?;
|};
