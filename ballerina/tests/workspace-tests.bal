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
    locationBuildingCode: "building-2"
};

Workspace invalidWorkspace = {
    workspaceId: "invalid-workspace-extra-characters-to-force-failure",
    workspaceType: "small",
    locationBuildingCode: "building-2"
};

Workspace workspace2 = {
    workspaceId: "workspace-2",
    workspaceType: "medium",
    locationBuildingCode: "building-2"
};

Workspace workspace3 = {
    workspaceId: "workspace-3",
    workspaceType: "small",
    locationBuildingCode: "building-2"
};

Workspace updatedWorkspace1 = {
    workspaceId: "workspace-1",
    workspaceType: "large",
    locationBuildingCode: "building-2"
};

@test:Config {
    groups: ["workspace"],
    dependsOn: [buildingDeleteTestNegative]
}
function workspaceCreateTest() returns error? {
    RainierClient rainierClient = check new ();
    
    string[] workspaceIds = check rainierClient->/workspace.post([workspace1]);    
    test:assertEquals(workspaceIds, [workspace1.workspaceId]);

    Workspace workspaceRetrieved = check rainierClient->/workspace/[workspace1.workspaceId].get();
    test:assertEquals(workspaceRetrieved, workspace1);
}

@test:Config {
    groups: ["workspace"]
}
function workspaceCreateTest2() returns error? {
    RainierClient rainierClient = check new ();
    
    string[] workspaceIds = check rainierClient->/workspace.post([workspace2, workspace3]);

    test:assertEquals(workspaceIds, [workspace2.workspaceId, workspace3.workspaceId]);

    Workspace workspaceRetrieved = check rainierClient->/workspace/[workspace2.workspaceId].get();
    test:assertEquals(workspaceRetrieved, workspace2);

    workspaceRetrieved = check rainierClient->/workspace/[workspace3.workspaceId].get();
    test:assertEquals(workspaceRetrieved, workspace3);
    check rainierClient.close();
}

@test:Config {
    groups: ["workspace"]
}
function workspaceCreateTestNegative() returns error? {
    RainierClient rainierClient = check new ();
    
    string[]|error workspace = rainierClient->/workspace.post([invalidWorkspace]);   
    if workspace is Error {
        test:assertTrue(workspace.message().includes("Data truncation: Data too long for column 'workspaceId' at row 1."));
    } else {
        test:assertFail("Error expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["workspace"],
    dependsOn: [workspaceCreateTest]
}
function workspaceReadOneTest() returns error? {
    RainierClient rainierClient = check new ();

    Workspace workspaceRetrieved = check rainierClient->/workspace/[workspace1.workspaceId].get();
    test:assertEquals(workspaceRetrieved, workspace1);
    check rainierClient.close();
}

@test:Config {
    groups: ["workspace"],
    dependsOn: [workspaceCreateTest]
}
function workspaceReadOneTestNegative() returns error? {
    RainierClient rainierClient = check new ();

    Workspace|error workspaceRetrieved = rainierClient->/workspace/["invalid-workspace-id"].get();
    if workspaceRetrieved is InvalidKeyError {
        test:assertEquals(workspaceRetrieved.message(), "A record does not exist for 'Workspace' for key \"invalid-workspace-id\".");
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["workspace"],
    dependsOn: [workspaceCreateTest, workspaceCreateTest2]
}
function workspaceReadManyTest() returns error? {
    RainierClient rainierClient = check new ();

    stream<Workspace, error?> workspaceStream = rainierClient->/workspace.get();
    Workspace[] workspaces = check from Workspace workspace in workspaceStream 
        select workspace;

    test:assertEquals(workspaces, [workspace1, workspace2, workspace3]);
    check rainierClient.close();
}

public type WorkspaceInfo2 record {|
    string workspaceType;
    string locationBuildingCode;
|};

@test:Config {
    groups: ["workspace", "dependent"],
    dependsOn: [workspaceCreateTest, workspaceCreateTest2]
}
function workspaceReadManyDependentTest() returns error? {
    RainierClient rainierClient = check new ();

    stream<WorkspaceInfo2, error?> workspaceStream = rainierClient->/workspace.get();
    WorkspaceInfo2[] workspaces = check from WorkspaceInfo2 workspace in workspaceStream 
        select workspace;

    test:assertEquals(workspaces, [
        {workspaceType: workspace1.workspaceType, locationBuildingCode: workspace1.locationBuildingCode},
        {workspaceType: workspace2.workspaceType, locationBuildingCode: workspace2.locationBuildingCode},
        {workspaceType: workspace3.workspaceType, locationBuildingCode: workspace3.locationBuildingCode}
    ]);
    check rainierClient.close();
}

@test:Config {
    groups: ["workspace"],
    dependsOn: [workspaceReadOneTest, workspaceReadManyTest, workspaceReadManyDependentTest]
}
function workspaceUpdateTest() returns error? {
    RainierClient rainierClient = check new ();

    Workspace workspace = check rainierClient->/workspace/[workspace1.workspaceId].put({
        workspaceType: "large"   
    });

    test:assertEquals(workspace, updatedWorkspace1);

    Workspace workspaceRetrieved = check rainierClient->/workspace/[workspace1.workspaceId].get();
    test:assertEquals(workspaceRetrieved, updatedWorkspace1);
    check rainierClient.close();
}

@test:Config {
    groups: ["workspace"],
    dependsOn: [workspaceReadOneTest, workspaceReadManyTest, workspaceReadManyDependentTest]
}
function workspaceUpdateTestNegative1() returns error? {
    RainierClient rainierClient = check new ();

    Workspace|error workspace = rainierClient->/workspace/["invalid-workspace-id"].put({
        workspaceType: "large"   
    });

    if workspace is InvalidKeyError {
        test:assertEquals(workspace.message(), "A record does not exist for 'Workspace' for key \"invalid-workspace-id\".");
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["workspace"],
    dependsOn: [workspaceReadOneTest, workspaceReadManyTest, workspaceReadManyDependentTest]
}
function workspaceUpdateTestNegative2() returns error? {
    RainierClient rainierClient = check new ();

    Workspace|error workspace = rainierClient->/workspace/[workspace1.workspaceId].put({
        workspaceType: "unncessarily-long-workspace-type-to-force-error-on-update"
    });

    if workspace is Error {
        test:assertTrue(workspace.message().includes("Data truncation: Data too long for column 'workspaceType' at row 1."));
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
    check rainierClient.close();
}

@test:Config {
    groups: ["workspace"],
    dependsOn: [workspaceUpdateTest, workspaceUpdateTestNegative2]
}
function workspaceDeleteTest() returns error? {
    RainierClient rainierClient = check new ();

    Workspace workspace = check rainierClient->/workspace/[workspace1.workspaceId].delete();
    test:assertEquals(workspace, updatedWorkspace1);

    stream<Workspace, error?> workspaceStream = rainierClient->/workspace.get();
    Workspace[] workspaces = check from Workspace workspace2 in workspaceStream 
        select workspace2;

    test:assertEquals(workspaces, [workspace2, workspace3]);
    check rainierClient.close();
}

@test:Config {
    groups: ["workspace"],
    dependsOn: [workspaceDeleteTest]
}
function workspaceDeleteTestNegative() returns error? {
    RainierClient rainierClient = check new ();

    Workspace|error workspace = rainierClient->/workspace/[workspace1.workspaceId].delete();

    if workspace is InvalidKeyError {
        test:assertEquals(workspace.message(), string `A record does not exist for 'Workspace' for key "${workspace1.workspaceId}".`);
    } else {
        test:assertFail("InvalidKeyError expected.");
    }
    check rainierClient.close();
}
