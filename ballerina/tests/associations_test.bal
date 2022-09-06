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
function oneToOneCreateTest3() returns error? {
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
function oneToOneCreateTest4() returns error? {
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

@test:Config {
    groups: ["associations"]
}
function oneToOneUpdateTest1() returns error? {
    Profile profile = {
        id: 5,
        name: "TestProfile",
        user: {
            id: 4,
            name: "TestUser"
        }
    };
    ProfileClient profileClient = check new();
    _ = check profileClient->create(profile);

    _ = check profileClient->update({"name": "TestUpdatedProfile", "user": {name: "TestUpdatedUser"}}, {id: 5});

    Profile profile2 = check profileClient->readByKey(5, [user]);
    Profile expectedProfile = {
        id: 5,
        name: "TestUpdatedProfile",
        user: {
            id: 4,
            name: "TestUpdatedUser"
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
        user: {
            id: 5,
            name: "TestUser"
        }
    };
    ProfileClient profileClient = check new();
    _ = check profileClient->create(profile);

    _ = check profileClient->update({"name": "TestUpdatedProfile", "user": {id: 4, name: "TestUpdatedUser2"}}, {id: 6});

    Profile profile2 = check profileClient->readByKey(6, [user]);
    Profile expectedProfile = {
        id: 6,
        name: "TestUpdatedProfile",
        user: {
            id: 4,
            name: "TestUpdatedUser2"
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
        user: {
            id: 6,
            name: "TestUser"
        }
    };
    ProfileClient profileClient = check new();
    _ = check profileClient->create(profile);

    ForeignKeyConstraintViolation|error? result = profileClient->update({"name": "TestUpdatedProfile", "user": {id: 7, name: "TestUpdatedUser2"}}, {id: 7});
    test:assertTrue(result is ForeignKeyConstraintViolation);
}
