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
    User user = {
        id: 1,
        name: "TestUser2"
    };
    UserClient userClient = check new();
    _ = check userClient->create(user);
    
    Profile profile = {
        id: 1,
        name: "TestProfile2",
        user: user
    };
    ProfileClient profileClient = check new();
    _ = check profileClient->create(profile);

    Profile profile2 = check profileClient->readByKey(1, ["user"]);
    test:assertEquals(profile, profile2);
}

@test:Config {
    groups: ["associations"]
}
function oneToOneCreateTest2() returns error? {
    Profile profile = {
        id: 9,
        name: "TestProfile2"
    };
    ProfileClient profileClient = check new();
    _ = check profileClient->create(profile);

    User user = {
        id: 9,
        name: "TestUser2",
        profile: profile
    };
    UserClient userClient = check new();
    _ = check userClient->create(user);
    

    User user2 = check userClient->readByKey(9, ["profile"]);
    test:assertEquals(user, user2);
}

@test:Config {
    groups: ["associationsx"]
}
function oneToOneCreateTest3() returns error? {
    User user = {
        id: 2,
        name: "TestUser",
        profile: {
            id: 15,
            name: "TestProfile"
        }
    };
    UserClient userClient = check new();
    _ = check userClient->create(user);
    User user2 = check userClient->readByKey(2, [profile]);

    test:assertEquals(user, user2);
}

@test:Config {
    groups: ["associations"]
}
function oneToOneCreateTest4() returns error? {
    User user = {
        id: 3,
        name: "TestUser"
    };
    UserClient userClient = check new();
    _ = check userClient->create(user);
    User user2 = check userClient->readByKey(3);

    test:assertEquals(user, user2);
}

@test:Config {
    groups: ["associations"]
}
function oneToOneCreateTest5() returns error? {
    Profile profile = {
        id: 3,
        name: "TestProfile"
    };
    ProfileClient profileClient = check new();
    _ = check profileClient->create(profile);
    Profile profile2 = check profileClient->readByKey(3);

    test:assertEquals(profile, profile2);
}

@test:Config {
    groups: ["associations"]
}
function oneToOneCreateTest6() returns error? {
    Profile profile = {
        id: 4,
        name: "TestProfile",
        user: {
            id: 3,
            name: "TestUser"
        }
    };
    ProfileClient profileClient = check new();
    _ = check profileClient->create(profile);
    Profile profile2 = check profileClient->readByKey(4, [user]);

    test:assertEquals(profile, profile2);
}
