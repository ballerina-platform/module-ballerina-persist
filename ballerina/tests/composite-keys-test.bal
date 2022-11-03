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
    Department|Error department2 = dClient->create(department);
    check dClient.close();
    test:assertTrue(department2 is Department);
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

@test:Config {
    groups: ["composite-keys", "duplicate-keys"]
}
function compositeDuplicateKeys() returns error? {
    DepartmentClient dClient = check new ();
    Department department = {
        hospitalCode: "CMB02",
        departmentId: 2,
        name: "ICU"
    };
    _ = check dClient->create(department);

    department = {
        hospitalCode: "CMB02",
        departmentId: 2,
        name: "ICU"
    };
    Department|Error department2 = dClient->create(department);
    check dClient.close();

    if department2 is DuplicateKeyError {
        test:assertEquals(department2.message(), "A Department entity with the key {\"hospitalCode\":\"CMB02\",\"departmentId\":2} already exists.");
    } else {
        test:assertFail("DuplicateKeyError expected");
    }

}
