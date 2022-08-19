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
function oneToOneCreateTest() returns error? {
    User user1 = {
        //id: 1,
        name: "TestUser"
    };
    user1 = userClient->create(user1);
    Profile _ = {
        id: 1,
        name: "TestProfile",
        user: user1
    };
    // profileClient->create(profile)

    // We insert the user (child entity) first, then insert profile (parent entity)
    // How do we determine whether the user already exists? 
    //      - from the key fields?
    //      - what if the key fields are auto-generated?
    //      - do not update if other fields are different
}

@test:Config {
    groups: ["associations"]
}
function oneToOneCreateTest2() returns error? {
    User _ = {
        id: 2,
        name: "TestUser",
        profile: {
            id: 2,
            name: "TestProfile"
        }
    };
    // userClient->create(user)

    // Should this be allowed? -- yes
    // If allowed, the user (child entity) should be created first, and then the profile (parent entity)
}

@test:Config {
    groups: ["associations"]
}
function oneToOneCreateNegativeTest() returns error? {
    Profile _ = {
        id: 1,
        name: "TestProfile"
    };
    // profileClient->create(profile)

    // Should this return an error?
    // How can we determine whether the association is required or not? -- do not mandate, keep as optional
}

@test:Config {
    groups: ["associations"]
}
function oneToOneReadTest() returns error? {
   // User user = userClient->readByKey(1);
   // This would not retrieve association data
}

@test:Config {
    groups: ["associations"]
}   
function oneToOneReadTest2() returns error? {
   // User user = userClient->readByKey(1, include = [Profile]);
   // This would retrieve association data
}
