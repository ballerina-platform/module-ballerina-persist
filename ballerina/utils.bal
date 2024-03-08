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

// just a comment

import ballerina/jballerina.java;

public isolated function convertToArray(typedesc<record {}> elementType, record {}[] arr) returns elementType[] = @java:Method {
    'class: "io.ballerina.stdlib.persist.Utils"
} external;

public isolated function filterRecord(record {} 'object, string[] fields) returns record {} {
    record {} retrieved = {};

    foreach string 'field in fields {

        // ignore many relations
        if 'field.includes("[]") {
            continue;
        }

        // if field is part of a relation
        if 'field.includes(".") {

            int splitIndex = <int>'field.indexOf(".");
            string relation = 'field.substring(0, splitIndex);
            string innerField = 'field.substring(splitIndex + 1, 'field.length());

            if 'object[relation] is record {} {
                anydata val = (<record {}>'object[relation])[innerField];

                if !(retrieved[relation] is record {}) {
                    retrieved[relation] = {};
                }

                record {} innerRecord = <record {}>'retrieved[relation];
                innerRecord[innerField] = val;
            }
        } else {
            retrieved['field] = 'object['field];
        }

    }
    return retrieved;
}

public isolated function getKey(anydata|record {} 'object, string[] keyFields) returns anydata|record {} {
    record {} keyRecord = {};

    if keyFields.length() == 1 && 'object is record {} {
        return 'object[keyFields[0]];
    }

    if 'object is record {} {
        foreach string key in keyFields {
            keyRecord[key] = 'object[key];
        }
    } else {
        keyRecord[keyFields[0]] = 'object;
    }
    return keyRecord;
}
