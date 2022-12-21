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
    Owner owner = {
        id: 1,
        name: "TestOwner"
    };
    OwnerClient ownerClient = check new ();
    _ = check ownerClient->create(owner);

    Profile profile = {
        id: 1,
        name: "TestProfile2",
        owner: owner
    };
    ProfileClient profileClient = check new ();
    Profile profile2 = check profileClient->create(profile);

    Profile profile3 = check profileClient->readByKey(1, ["owner"]);
    test:assertEquals(profile, profile2);
    test:assertEquals(profile, profile3);
}

@test:Config {
    groups: ["associations"]
}
function oneToOneCreateTest2() returns error? {
    Owner owner = {
        id: 3,
        name: "TestOwner"
    };
    OwnerClient ownerClient = check new ();
    _ = check ownerClient->create(owner);
    Owner owner2 = check ownerClient->readByKey(3);

    test:assertEquals(owner, owner2);
}

@test:Config {
    groups: ["associations"]
}
function oneToOneCreateTest3() returns error? {
    Profile profile = {
        id: 3,
        name: "TestProfile"
    };
    ProfileClient profileClient = check new ();
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
        owner: {
            id: 3,
            name: "TestOwner"
        }
    };
    ProfileClient profileClient = check new ();
    _ = check profileClient->create(profile);
    Profile profile2 = check profileClient->readByKey(4, [owner]);

    test:assertEquals(profile, profile2);
}

@test:Config {
    groups: ["associations"]
}
function oneToOneReadTest1() returns error? {
    Profile profile = {
        id: 24,
        name: "TestProfile",
        owner: {
            id: 23,
            name: "TestOwner"
        }
    };
    ProfileClient profileClient = check new ();
    _ = check profileClient->create(profile);

    Profile profile2 = check profileClient->readByKey(24, [owner]);
    test:assertEquals(profile, profile2);

    OwnerClient ownerClient = check new ();
    Owner owner = check ownerClient->readByKey(23, ["profile"]);
    test:assertEquals(owner, {
        id: 23,
        name: "TestOwner",
        profile: {
            id: 24,
            name: "TestProfile"
        }
    });
}

@test:Config {
    groups: ["associations"]
}
function oneToOneUpdateTest1() returns error? {
    Profile profile = {
        id: 5,
        name: "TestProfile",
        owner: {
            id: 4,
            name: "TestOwner"
        }
    };
    ProfileClient profileClient = check new ();
    _ = check profileClient->create(profile);

    profile.name = "TestUpdatedProfile";
    profile.owner.name = "TestUpdatedOwner";
    _ = check profileClient->update(profile);

    Profile profile2 = check profileClient->readByKey(5, [owner]);
    Profile expectedProfile = {
        id: 5,
        name: "TestUpdatedProfile",
        owner: {
            id: 4,
            name: "TestUpdatedOwner"
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
        owner: {
            id: 5,
            name: "TestOwner"
        }
    };
    ProfileClient profileClient = check new ();
    _ = check profileClient->create(profile);

    profile.name = "TestUpdatedProfile";
    profile.owner = {
        id: 4,
        name: "TestUpdatedOwner"
    };
    _ = check profileClient->update(profile);

    Profile profile2 = check profileClient->readByKey(6, [owner]);
    Profile expectedProfile = {
        id: 6,
        name: "TestUpdatedProfile",
        owner: {
            id: 4,
            name: "TestUpdatedOwner"
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
        owner: {
            id: 6,
            name: "TestOwner"
        }
    };
    ProfileClient profileClient = check new ();
    _ = check profileClient->create(profile);

    profile.name = "TestUpdatedProfile";
    profile.owner = {
        id: 7,
        name: "TestUpdatedOwner"
    };
    ForeignKeyConstraintViolationError|error? result = profileClient->update(profile);
    test:assertTrue(result is ForeignKeyConstraintViolationError);
}

@test:Config {
    groups: ["associations"]
}
function MultipleAssociationsTest() returns error? {
    MultipleAssociations ma = {
        id: 1,
        name: "TestMultipleAssociation",
        profile: {
            id: 31,
            name: "Test Profile"
        },
        owner: {
            id: 31,
            name: "TestOwner"
        }
    };

    MultipleAssociationsClient maClient = check new ();
    MultipleAssociations ma2 = check maClient->create(ma);
    test:assertEquals(ma, ma2);

    MultipleAssociations ma3 = check maClient->readByKey(1, [profile, owner]);
    test:assertEquals(ma, ma3);

    MultipleAssociations ma4 = check maClient->readByKey(1, [profile]);
    test:assertEquals({
        id: 1,
        name: "TestMultipleAssociation",
        profile: {
            id: 31,
            name: "Test Profile"
        }
    }, ma4);

    MultipleAssociations ma5 = check maClient->readByKey(1, [owner]);
    test:assertEquals({
        id: 1,
        name: "TestMultipleAssociation",
        owner: {
            id: 31,
            name: "TestOwner"
        }
    }, ma5);
}

@test:Config {
    groups: ["associations", "one-to-many"]
}
function oneToManyCreateTest1() returns error? {
    Company company = {
        id: 1,
        name: "TestCompany1"
    };
    CompanyClient companyClient = check new ();
    _ = check companyClient->create(company);

    Employee employee = {
        id: 1,
        name: "TestEmployee1",
        company: company
    };
    EmployeeClient employeeClient = check new ();
    Employee employee2 = check employeeClient->create(employee);

    Employee employee3 = check employeeClient->readByKey(1, ["company"]);
    test:assertEquals(employee, employee2);
    test:assertEquals(employee, employee3);
}

@test:Config {
    groups: ["associations", "one-to-many"]
}
function oneToManyCreateTest2() returns error? {
    Company company = {
        id: 2,
        name: "TestCompany2"
    };
    CompanyClient companyClient = check new ();
    _ = check companyClient->create(company);

    EmployeeClient employeeClient = check new ();

    Employee employee1 = {
        id: 2,
        name: "TestEmployee2",
        company: company
    };
    _ = check employeeClient->create(employee1);

    Employee employee2 = {
        id: 3,
        name: "TestEmployee3",
        company: company
    };
    _ = check employeeClient->create(employee2);

    Company company2 = check companyClient->readByKey(2, [EmployeeEntity]);
    test:assertEquals(company2, <Company>{
        id: 2,
        name: "TestCompany2",
        employees: [{id: 2, name: "TestEmployee2"}, {id: 3, name: "TestEmployee3"}]
    });
}

@test:Config {
    groups: ["associations", "one-to-many"]
}
function oneToManyCreateTest3() returns error? {
    Company company = {
        id: 3,
        name: "TestCompany3"
    };
    CompanyClient companyClient = check new ();
    _ = check companyClient->create(company);

    EmployeeClient employeeClient = check new ();

    Employee employee1 = {
        id: 4,
        name: "TestEmployee4",
        company: company
    };
    _ = check employeeClient->create(employee1);

    Employee employee2 = {
        id: 5,
        name: "TestEmployee5",
        company: company
    };
    _ = check employeeClient->create(employee2);

    check from Company company2 in companyClient->read([EmployeeEntity])
        where company2.id == 3
        do {
            test:assertEquals(company2, <Company>{
                id: 3,
                name: "TestCompany3",
                employees: [{id: 4, name: "TestEmployee4"}, {id: 5, name: "TestEmployee5"}]
            });
        };
}

@test:Config {
    groups: ["associations", "one-to-manyx"]
}
function oneToManyCreateTest4() returns error? {
    Company company = {
        id: 4,
        name: "TestCompany4"
    };
    CompanyClient companyClient = check new ();
    _ = check companyClient->create(company);

    EmployeeClient employeeClient = check new ();

    Employee employee1 = {
        id: 6,
        name: "TestEmployee6",
        company: company
    };
    _ = check employeeClient->create(employee1);

    Employee employee2 = {
        id: 7,
        name: "TestEmployee7",
        company: company
    };
    _ = check employeeClient->create(employee2);

    Employee employee = check employeeClient->readByKey(6, ["company"]);
    test:assertEquals(employee, <Employee>{
        id: 6,
        name: "TestEmployee6",
        company: {id: 4, name: "TestCompany4"}
    });
}

@test:Config {
    groups: ["associations", "one-to-manyx"]
}
function oneToManyUpdateTest4() returns error? {
    Company company = {
        id: 5,
        name: "TestCompany5"
    };
    CompanyClient companyClient = check new ();
    _ = check companyClient->create(company);

    EmployeeClient employeeClient = check new ();

    Employee employee1 = {
        id: 8,
        name: "TestEmployee8",
        company: company
    };
    _ = check employeeClient->create(employee1);

    Employee employee2 = {
        id: 9,
        name: "TestEmployee9",
        company: company
    };
    _ = check employeeClient->create(employee2);

    employee1.name = "TestEmployeeUpdated8";
    employee1.company.name = "TestCompanyUpdated5";
    _ = check employeeClient->update(employee1);
    Company company2 = check companyClient->readByKey(5, [EmployeeEntity]);
    test:assertEquals(company2, <Company>{
        id: 5,
        name: "TestCompanyUpdated5",
        employees: [{id: 8, name: "TestEmployeeUpdated8"}, {id: 9, name: "TestEmployee9"}]
    });
}
