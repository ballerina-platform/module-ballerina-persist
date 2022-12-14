// Copyright (c) 2022 WSO2 LLC. (https://www.wso2.com) All Rights Reserved.
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

import ballerina/persist;
import ballerina/time;

@persist:Entity {
    key: ["needId"]
}
public type MedicalNeed record {|
    @persist:AutoIncrement
    readonly int needId = -1;
    int itemId;
    int beneficiaryId;
    time:Civil period;
    string urgency;
    int quantity;
    int xyz;
|};

@persist:Entity {
    key: ["itemId"]
}
public type MedicalItem record {|
    readonly int itemId;
    string name;
    string 'type;
    string unit;
    Item item?;
    MedicalNeed mn?;
|};

@persist:Entity {
    key: ["itemId"]
}
public type Item record {|
    readonly int itemId;
    string name;
    string 'type;
    string unit;
    @persist:Relation
    MedicalItem medicalItem?;
|};

@persist:Entity {
    key: ["id"]
}
public type RecordTest record {|
    readonly int id;
    RecordTest1 recordTest1?;
|};

public type RecordTest1 record {|
    readonly int id;
    RecordTest recordTest?;
|};
