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
import ballerina/persist;

@persist:Entity {
    key: ["needId"],
    uniqueConstraints: [["beneficiaryId", "urgency"]]
}
public type MedicalNeed1 record {|
    @persist:AutoIncrement
    readonly int needId = 1;
    int beneficiaryId;
    time:Civil period;
    string urgency;
    int quantity;
|};

@persist:Entity {
    key: ["needId"],
    uniqueConstraints: [["beneficiaryId", "urgency"]]
}
public type MedicalNeed record {|
    @persist:AutoIncrement
    readonly int needId = 1;
    int beneficiaryId;
    time:Civil period;
    string urgency;
    int quantity;
|};

@persist:Entity {
    key: ["id"]
}
public type Items record {|
    @persist:AutoIncrement
    readonly int id = 1;
|};
