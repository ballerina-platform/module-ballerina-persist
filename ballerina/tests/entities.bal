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

public type MedicalNeed record {|
    readonly int needId = -1;

    int itemId;
    int beneficiaryId;
    time:Civil period;
    string urgency;
    int quantity;
|};

public type MedicalItem record {|
    readonly int itemId;
    string name;
    string 'type;
    string unit;
|};

public type ComplexType record {|
    readonly int complexTypeId = -1;
    time:Civil civilType;
    time:TimeOfDay timeOfDayType;
    time:Date dateType;
|};

public type Department record {|
    readonly string hospitalCode;
    readonly int departmentId;
    string name;
|};

// One-to-one relation
public type Owner record {|
    readonly int id;
    string name;
    Profile profile?;
    MultipleAssociations multipleAssociations?;
|};

public type Profile record {|
    readonly int id;
    string name;
    Owner owner?;
    MultipleAssociations multipleAssociations?;
|};

public type MultipleAssociations record {|
    readonly int id;
    string name;

    Profile profile?;

    Owner owner?;
|};

// One-to-many relation
public type Company record {|
    readonly int id;
    string name;
    Employee[] employees?;
|};

public type Employee record {|
    readonly int id;
    string name;

    Company company?;
|};


// Many-to-many relation
public type Student record {|
    readonly string nic;
    string firstName;
    string lastName;
    time:Date dob;
    string contact;

    Lecture[] lectures?;

    Paper[] papers?;
|};

public type Lecture record {|
    readonly string code;
    string subject;
    string day;
    time:TimeOfDay time;

    Student[] students?;
|};

public type Paper record {|
    readonly int subjectId;
    time:Date paperDate;
    string title;
    
    Student[] students?;
|};
