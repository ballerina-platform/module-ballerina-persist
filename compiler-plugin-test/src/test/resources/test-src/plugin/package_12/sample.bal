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

import ballerina/persist;

string[] key = ["v1", "v2"];
string[] keyColumns = ["v1", "v2"];
string[] reference = ["v1", "v2"];
string[][] uniqueConstraint = [["v1", "v2"]];
int value = 1;
string tableName = "USER_TABLE";

@persist:Entity {
    key: key,
    uniqueConstraints: uniqueConstraint,
    tableName: tableName
}
public type User record  {|
    @persist:AutoIncrement{startValue :value, increment: value }
    readonly int id;
    string name;
    @persist:Relation {keyColumns: keyColumns, reference: reference}
    Post posts?;
|};

@persist:Entity {
    key: ["id"],
    tableName: "POST_TABLE"
}
public type Post record  {|
 readonly int id;
 string name;
|};
