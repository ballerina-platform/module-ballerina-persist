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
    groups: ["composite-keys"]
}
function compositeCreateTest() returns error? {
    DepartmentClient dClient = check new ();
    Department department = {
        hospitalCode: "CMB01",
        departmentId: 1,
        name: "ICU"
    };
    [string, int]? id = check dClient->create(department);
    check dClient.close();
    test:assertTrue(id is [string, int]);
}

@test:Config {
    groups: ["composite-keys"]
}
function compositeRetrieveByKeyTest() returns error? {
    DepartmentClient dClient = check new ();
    Department retrieved = check dClient->readByKey({hospitalCode: "CMB01", departmentId: 1});
    Department department = {
        hospitalCode: "CMB01",
        departmentId: 1,
        name: "ICU"
    };
    check dClient.close();
    test:assertEquals(retrieved, department);
}
