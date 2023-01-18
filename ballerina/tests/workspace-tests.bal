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

Workspace workspace1 = {
    workspaceId: "workspace-1",
    workspaceType: "small",
    buildingCode: "building-2"
};

Workspace invalidWorkspace = {
    workspaceId: "invalid-workspace-extra-characters-to-force-failure",
    workspaceType: "small",
    buildingCode: "building-2"
};

Workspace workspace2 = {
    workspaceId: "workspace-2",
    workspaceType: "medium",
    buildingCode: "building-2"
};

Workspace workspace3 = {
    workspaceId: "workspace-3",
    workspaceType: "small",
    buildingCode: "building-2"
};

Workspace updatedWorkspace1 = {
    workspaceId: "workspace-1",
    workspaceType: "large",
    buildingCode: "building-2"
};

@test:Config {
    groups: ["workspace"],
    dependsOn: [basicDeleteTestNegative]
}
function workspaceCreateTest() returns error? {
    RainierClient rainierClient = check new ();
    
    string[] workspaceIds = check rainierClient->/workspaces.post([workspace1]);    
    test:assertEquals(workspaceIds, [workspace1.workspaceId]);

    Workspace workspaceRetrieved = check rainierClient->/workspaces/[workspace1.workspaceId].get();
    test:assertEquals(workspaceRetrieved, workspace1);
}

@test:Config {
    groups: ["workspace"]
}
function workspaceCreateTest2() returns error? {
    RainierClient rainierClient = check new ();
    
    string[] workspaceIds = check rainierClient->/workspaces.post([workspace2, workspace3]);

    test:assertEquals(workspaceIds, [workspace2.workspaceId, workspace3.workspaceId]);

    Workspace workspaceRetrieved = check rainierClient->/workspaces/[workspace2.workspaceId].get();
    test:assertEquals(workspaceRetrieved, workspace2);

    workspaceRetrieved = check rainierClient->/workspaces/[workspace3.workspaceId].get();
    test:assertEquals(workspaceRetrieved, workspace3);
}

@test:Config {
    groups: ["workspace"]
}
function workspaceCreateTestNegative() returns error? {
    RainierClient rainierClient = check new ();
    
    string[]|error workspace = rainierClient->/workspaces.post([invalidWorkspace]);   
    if workspace is Error {
        test:assertTrue(workspace.message().includes("Data truncation: Data too long for column 'workspaceId' at row 1."));
    } else {
        test:assertFail("Error expected.");
    }
}

@test:Config {
    groups: ["workspace"],
    dependsOn: [workspaceCreateTest]
}
function workspaceReadOneTest() returns error? {
    RainierClient rainierClient = check new ();

    Workspace workspaceRetrieved = check rainierClient->/workspaces/[workspace1.workspaceId].get();
    test:assertEquals(workspaceRetrieved, workspace1);
}

@test:Config {
    groups: ["workspace"],
    dependsOn: [workspaceCreateTest]
}
function workspaceReadOneTestNegative() returns error? {
    RainierClient rainierClient = check new ();

    Workspace|error workspaceRetrieved = rainierClient->/workspaces/["invalid-workspace-id"].get();
    if workspaceRetrieved is InvalidKeyError {
        test:assertEquals(workspaceRetrieved.message(), "A record does not exist for 'Workspace' for key \"invalid-workspace-id\".");
    } else {
        test:assertFail("InvalidKeyError expected.");
    }}

@test:Config {
    groups: ["workspace"],
    dependsOn: [workspaceCreateTest, workspaceCreateTest2]
}
function workspaceReadManyTest() returns error? {
    RainierClient rainierClient = check new ();

    stream<Workspace, error?> workspaceStream = rainierClient->/workspaces.get();
    Workspace[] workspaces = check from Workspace workspace in workspaceStream 
        select workspace;

    test:assertEquals(workspaces, [workspace1, workspace2, workspace3]);
}

@test:Config {
    groups: ["workspace"],
    dependsOn: [workspaceReadOneTest, workspaceReadManyTest]
}
function workspaceUpdateTest() returns error? {
    RainierClient rainierClient = check new ();

    Workspace workspace = check rainierClient->/workspaces/[workspace1.workspaceId].put({
        workspaceType: "large"   
    });

    test:assertEquals(workspace, updatedWorkspace1);

    Workspace workspaceRetrieved = check rainierClient->/workspaces/[workspace1.workspaceId].get();
    test:assertEquals(workspaceRetrieved, updatedWorkspace1);
}

@test:Config {
    groups: ["workspace"],
    dependsOn: [workspaceReadOneTest, workspaceReadManyTest]
}
function workspaceUpdateTestNegative1() returns error? {
    RainierClient rainierClient = check new ();

    Workspace|error workspace = rainierClient->/workspaces/["invalid-workspace-id"].put({
        workspaceType: "large"   
    });

    if workspace is InvalidKeyError {
        test:assertEquals(workspace.message(), "A record does not exist for 'Workspace' for key \"invalid-workspace-id\".");
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
}

@test:Config {
    groups: ["workspace"],
    dependsOn: [workspaceReadOneTest, workspaceReadManyTest]
}
function workspaceUpdateTestNegative2() returns error? {
    RainierClient rainierClient = check new ();

    Workspace|error workspace = rainierClient->/workspaces/[workspace1.workspaceId].put({
        workspaceType: "unncessarily-long-workspace-type-to-force-error-on-update"
    });

    if workspace is Error {
        test:assertTrue(workspace.message().includes("Data truncation: Data too long for column 'workspaceType' at row 1."));
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
}

@test:Config {
    groups: ["workspace"],
    dependsOn: [workspaceUpdateTest, workspaceUpdateTestNegative2]
}
function workspaceDeleteTest() returns error? {
    RainierClient rainierClient = check new ();

    Workspace workspace = check rainierClient->/workspaces/[workspace1.workspaceId].delete();
    test:assertEquals(workspace, updatedWorkspace1);

    stream<Workspace, error?> workspaceStream = rainierClient->/workspaces.get();
    Workspace[] workspaces = check from Workspace workspace2 in workspaceStream 
        select workspace2;

    test:assertEquals(workspaces, [workspace2, workspace3]);
}

@test:Config {
    groups: ["workspace"],
    dependsOn: [workspaceDeleteTest]
}
function workspaceDeleteTestNegative() returns error? {
    RainierClient rainierClient = check new ();

    Workspace|error workspace = rainierClient->/workspaces/[workspace1.workspaceId].delete();

    if workspace is InvalidKeyError {
        test:assertEquals(workspace.message(), string `A record does not exist for 'Workspace' for key "${workspace1.workspaceId}".`);
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
}
