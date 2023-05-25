// Copyright (c) 2023 WSO2 LLC. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
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
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/time;

configurable int port = ?;
configurable string host = ?;
configurable string user = ?;
configurable string database = ?;
configurable string password = ?;
configurable mysql:Options connectionOptions = {};

@test:BeforeSuite
function truncate() returns error? {
    mysql:Client dbClient = check new (host = host, user = user, password = password, database = database, port = port);
    _ = check dbClient->execute(`SET FOREIGN_KEY_CHECKS = 0`);
    _ = check dbClient->execute(`TRUNCATE Employee`);
    _ = check dbClient->execute(`TRUNCATE Workspace`);
    _ = check dbClient->execute(`TRUNCATE Building`);
    _ = check dbClient->execute(`TRUNCATE Department`);
    _ = check dbClient->execute(`TRUNCATE OrderItem`);
    _ = check dbClient->execute(`TRUNCATE AllTypes`);
    _ = check dbClient->execute(`TRUNCATE FloatIdRecord`);
    _ = check dbClient->execute(`TRUNCATE StringIdRecord`);
    _ = check dbClient->execute(`TRUNCATE DecimalIdRecord`);
    _ = check dbClient->execute(`TRUNCATE BooleanIdRecord`);
    _ = check dbClient->execute(`TRUNCATE IntIdRecord`);
    _ = check dbClient->execute(`TRUNCATE AllTypesIdRecord`);
    _ = check dbClient->execute(`TRUNCATE CompositeAssociationRecord`);
    _ = check dbClient->execute(`SET FOREIGN_KEY_CHECKS = 1`);
    check dbClient.close();
}

AllTypes allTypes1 = {
    id: 1,
    booleanType: false,
    intType: 5,
    floatType: 6.0,
    decimalType: 23.44,
    stringType: "test",
    byteArrayType: base16 `55 EE 66 FF 77 AB`,
    dateType: {year: 1993, month: 11, day: 3},
    timeOfDayType: {hour: 12, minute: 32, second: 34},
    civilType: {year: 1993, month: 11, day: 3, hour: 12, minute: 32, second: 34},
    booleanTypeOptional: false,
    intTypeOptional: 5,
    floatTypeOptional: 6.0,
    decimalTypeOptional: 23.44,
    stringTypeOptional: "test",
    dateTypeOptional: {year: 1993, month: 11, day: 3},
    timeOfDayTypeOptional: {hour: 12, minute: 32, second: 34},
    civilTypeOptional: {year: 1993, month: 11, day: 3, hour: 12, minute: 32, second: 34},
    enumType: "TYPE_3",
    enumTypeOptional: "TYPE_2"
};

AllTypes allTypes1Expected = {
    id: allTypes1.id,
    booleanType: allTypes1.booleanType,
    intType: allTypes1.intType,
    floatType: allTypes1.floatType,
    decimalType: allTypes1.decimalType,
    stringType: allTypes1.stringType,
    byteArrayType: allTypes1.byteArrayType,
    dateType: allTypes1.dateType,
    timeOfDayType: allTypes1.timeOfDayType,
    civilType: allTypes1.civilType,
    booleanTypeOptional: allTypes1.booleanTypeOptional,
    intTypeOptional: allTypes1.intTypeOptional,
    floatTypeOptional: allTypes1.floatTypeOptional,
    decimalTypeOptional: allTypes1.decimalTypeOptional,
    stringTypeOptional: allTypes1.stringTypeOptional,
    dateTypeOptional: allTypes1.dateTypeOptional,
    timeOfDayTypeOptional: allTypes1.timeOfDayTypeOptional,
    civilTypeOptional: allTypes1.civilTypeOptional,
    enumType: allTypes1.enumType,
    enumTypeOptional: allTypes1.enumTypeOptional
};

AllTypes allTypes2 = {
    id: 2,
    booleanType: true,
    intType: 35,
    floatType: 63.0,
    decimalType: 233.44,
    stringType: "test2",
    byteArrayType: base16 `55 EE 66 AF 77 AB`,
    dateType: {year: 1996, month: 11, day: 3},
    timeOfDayType: {hour: 17, minute: 32, second: 34},
    civilType: {year: 1999, month: 11, day: 3, hour: 12, minute: 32, second: 34},
    booleanTypeOptional: true,
    intTypeOptional: 6,
    floatTypeOptional: 66.0,
    decimalTypeOptional: 233.44,
    stringTypeOptional: "test2",
    dateTypeOptional: {year: 1293, month: 11, day: 3},
    timeOfDayTypeOptional: {hour: 19, minute: 32, second: 34},
    civilTypeOptional: {year: 1989, month: 11, day: 3, hour: 12, minute: 32, second: 34},
    enumType: "TYPE_1",
    enumTypeOptional: "TYPE_3"
};

AllTypes allTypes2Expected = {
    id: allTypes2.id,
    booleanType: allTypes2.booleanType,
    intType: allTypes2.intType,
    floatType: allTypes2.floatType,
    decimalType: allTypes2.decimalType,
    stringType: allTypes2.stringType,
    byteArrayType: allTypes2.byteArrayType,
    dateType: allTypes2.dateType,
    timeOfDayType: allTypes2.timeOfDayType,
    civilType: allTypes2.civilType,
    booleanTypeOptional: allTypes2.booleanTypeOptional,
    intTypeOptional: allTypes2.intTypeOptional,
    floatTypeOptional: allTypes2.floatTypeOptional,
    decimalTypeOptional: allTypes2.decimalTypeOptional,
    stringTypeOptional: allTypes2.stringTypeOptional,
    dateTypeOptional: allTypes2.dateTypeOptional,
    timeOfDayTypeOptional: allTypes2.timeOfDayTypeOptional,
    civilTypeOptional: allTypes2.civilTypeOptional,
    enumType: allTypes2.enumType,
    enumTypeOptional: allTypes2.enumTypeOptional
};

AllTypes allTypes3 = {
    id: 3,
    booleanType: true,
    intType: 35,
    floatType: 63.0,
    decimalType: 233.44,
    stringType: "test2",
    byteArrayType: base16 `55 EE 66 AF 77 AB`,
    dateType: {year: 1996, month: 11, day: 3},
    timeOfDayType: {hour: 17, minute: 32, second: 34},
    civilType: {year: 1999, month: 11, day: 3, hour: 12, minute: 32, second: 34},
    booleanTypeOptional: (),
    intTypeOptional: (),
    floatTypeOptional: (),
    decimalTypeOptional: (),
    stringTypeOptional: (),
    dateTypeOptional: (),
    timeOfDayTypeOptional: (),
    civilTypeOptional: (),
    enumType: "TYPE_1",
    enumTypeOptional: ()
};

AllTypes allTypes3Expected = {
    id: allTypes3.id,
    booleanType: allTypes3.booleanType,
    intType: allTypes3.intType,
    floatType: allTypes3.floatType,
    decimalType: allTypes3.decimalType,
    stringType: allTypes3.stringType,
    byteArrayType: allTypes3.byteArrayType,
    dateType: allTypes3.dateType,
    timeOfDayType: allTypes3.timeOfDayType,
    civilType: allTypes3.civilType,
    booleanTypeOptional: allTypes3.booleanTypeOptional,
    intTypeOptional: allTypes3.intTypeOptional,
    floatTypeOptional: allTypes3.floatTypeOptional,
    decimalTypeOptional: allTypes3.decimalTypeOptional,
    stringTypeOptional: allTypes3.stringTypeOptional,
    dateTypeOptional: allTypes3.dateTypeOptional,
    timeOfDayTypeOptional: allTypes3.timeOfDayTypeOptional,
    civilTypeOptional: allTypes3.civilTypeOptional,
    enumType: allTypes3.enumType,
    enumTypeOptional: allTypes3.enumTypeOptional
};

AllTypes allTypes1Updated = {
    id: 1,
    booleanType: true,
    intType: 99,
    floatType: 63.0,
    decimalType: 53.44,
    stringType: "testUpdate",
    byteArrayType: base16 `55 FE 66 FF 77 AB`,
    dateType: {year: 1996, month: 12, day: 13},
    timeOfDayType: {hour: 16, minute: 12, second: 14},
    civilType: {year: 1998, month: 9, day: 13, hour: 12, minute: 32, second: 34},
    booleanTypeOptional: true,
    intTypeOptional: 53,
    floatTypeOptional: 26.0,
    decimalTypeOptional: 223.44,
    stringTypeOptional: "testUpdate",
    dateTypeOptional: {year: 1923, month: 11, day: 3},
    timeOfDayTypeOptional: {hour: 18, minute: 32, second: 34},
    civilTypeOptional: {year: 1991, month: 11, day: 3, hour: 12, minute: 32, second: 34},
    enumType: "TYPE_4",
    enumTypeOptional: "TYPE_4"
};

AllTypes allTypes1UpdatedExpected = {
    id: allTypes1Updated.id,
    booleanType: allTypes1Updated.booleanType,
    intType: allTypes1Updated.intType,
    floatType: allTypes1Updated.floatType,
    decimalType: allTypes1Updated.decimalType,
    stringType: allTypes1Updated.stringType,
    byteArrayType: allTypes1Updated.byteArrayType,
    dateType: allTypes1Updated.dateType,
    timeOfDayType: allTypes1Updated.timeOfDayType,
    civilType: allTypes1Updated.civilType,
    booleanTypeOptional: allTypes1Updated.booleanTypeOptional,
    intTypeOptional: allTypes1Updated.intTypeOptional,
    floatTypeOptional: allTypes1Updated.floatTypeOptional,
    decimalTypeOptional: allTypes1Updated.decimalTypeOptional,
    stringTypeOptional: allTypes1Updated.stringTypeOptional,
    dateTypeOptional: allTypes1Updated.dateTypeOptional,
    timeOfDayTypeOptional: allTypes1Updated.timeOfDayTypeOptional,
    civilTypeOptional: allTypes1Updated.civilTypeOptional,
    enumType: allTypes1Updated.enumType,
    enumTypeOptional: allTypes1Updated.enumTypeOptional
};

public type AllTypesDependent record {|
    boolean booleanType;
    int intType;
    float floatType;
    decimal decimalType;
    string stringType;
    byte[] byteArrayType;
    time:Date dateType;
    time:TimeOfDay timeOfDayType;
    time:Civil civilType;
    boolean? booleanTypeOptional;
    int? intTypeOptional;
    float? floatTypeOptional;
    decimal? decimalTypeOptional;
    string? stringTypeOptional;
    time:Date? dateTypeOptional;
    time:TimeOfDay? timeOfDayTypeOptional;
    time:Civil? civilTypeOptional;
|};

OrderItemExtended orderItemExtended1 = {
    orderId: "order-1",
    itemId: "item-1",
    CustomerId: 1,
    paid: false,
    ammountPaid: 10.5f,
    ammountPaidDecimal: 10.5,
    arivalTimeCivil: {"utcOffset":{"hours":5,"minutes":30},"timeAbbrev":"Asia/Colombo","dayOfWeek":1,"year":2021,"month":4,"day":12,"hour":23,"minute":20,"second":50.52},
    arivalTimeUtc: [1684493685, 0.998012000],
    arivalTimeDate: {year: 2021, month: 4, day: 12},
    arivalTimeTimeOfDay: {hour: 17, minute: 50, second: 50.52},
    orderType: INSTORE
};

OrderItemExtended orderItemExtendedRetrieved = {
    orderId: "order-1",
    itemId: "item-1",
    CustomerId: 1,
    paid: false,
    ammountPaid: 10.5f,
    ammountPaidDecimal: 10.5,
    arivalTimeCivil: {"timeAbbrev":"Z","dayOfWeek":1 ,"year":2021,"month":4,"day":12,"hour":17,"minute":50,"second":50.52},
    arivalTimeUtc: [1684493685, 0.998012000],
    arivalTimeDate: {year: 2021, month: 4, day: 12},
    arivalTimeTimeOfDay: {hour: 17, minute: 50, second: 50.52},
    orderType: INSTORE
};

OrderItemExtended orderItemExtended2 = {
    orderId: "order-2",
    itemId: "item-2",
    CustomerId: 1,
    paid: false,
    ammountPaid: 10.5f,
    ammountPaidDecimal: 10.5,
    arivalTimeCivil: {"utcOffset":{"hours":5,"minutes":30},"timeAbbrev":"Asia/Colombo","dayOfWeek":1 ,"year":2024,"month":4,"day":12,"hour":17,"minute":50,"second":50.52},
    arivalTimeUtc: [1684493685, 0.998012000],
    arivalTimeDate: {year: 2021, month: 4, day: 12},
    arivalTimeTimeOfDay: {hour: 17, minute: 50, second: 50.52},
    orderType: ONLINE
};

public type EmployeeInfo record {|
    string firstName;
    string lastName;
    record {|
        string deptName;
    |} department;
    Workspace workspace;
|};

OrderItemExtended orderItemExtended2Retrieved = {
    orderId: "order-2",
    itemId: "item-2",
    CustomerId: 1,
    paid: false,
    ammountPaid: 10.5f,
    ammountPaidDecimal: 10.5,
    arivalTimeCivil: {"timeAbbrev":"Z","dayOfWeek":5 ,"year":2024,"month":4,"day":12,"hour":12,"minute":20,"second":50.52},
    arivalTimeUtc: [1684493685, 0.998012000],
    arivalTimeDate: {year: 2021, month: 4, day: 12},
    arivalTimeTimeOfDay: {hour: 17, minute: 50, second: 50.52},
    orderType: ONLINE
};

OrderItemExtended orderItemExtended3 = {
    orderId: "order-3",
    itemId: "item-3",
    CustomerId: 4,
    paid: true,
    ammountPaid: 20.5f,
    ammountPaidDecimal: 20.5,
    arivalTimeCivil: {"utcOffset":{"hours":5,"minutes":30},"timeAbbrev":"Asia/Colombo","dayOfWeek":1,"year":2021,"month":4,"day":12,"hour":23,"minute":20,"second":50.52},
    arivalTimeUtc: [1684493685, 0.998012000],
    arivalTimeDate: {year: 2021, month: 4, day: 12},
    arivalTimeTimeOfDay: {hour: 17, minute: 50, second: 50.52},
    orderType: INSTORE
};

OrderItemExtended orderItemExtended3Retrieved = {
    orderId: "order-2",
    itemId: "item-2",
    CustomerId: 1,
    paid: true,
    ammountPaid: 10.5f,
    ammountPaidDecimal: 10.5,
    arivalTimeCivil: {"timeAbbrev":"Z","dayOfWeek":1 ,"year":2021,"month":4,"day":12,"hour":17,"minute":50,"second":50.52},
    arivalTimeUtc: [1684493685, 0.998012000],
    arivalTimeDate: {year: 2021, month: 4, day: 12},
    arivalTimeTimeOfDay: {hour: 17, minute: 50, second: 50.52},
    orderType: ONLINE
};

public type DepartmentInfo record {|
    string deptNo;
    string deptName;
    record {|
        string firstName;
        string lastName;
    |}[] employees;
|};

public type WorkspaceInfo record {|
    string workspaceType;
    Building location;
    Employee[] employees;
|};

public type BuildingInfo record {|
    string buildingCode;
    string city;
    string state;
    string country;
    string postalCode;
    string 'type;
    Workspace[] workspaces;
|};

Building building1 = {
    buildingCode: "building-1",
    city: "Colombo",
    state: "Western Province",
    country: "Sri Lanka",
    postalCode: "10370",
    'type: "rented"
};

Building invalidBuilding = {
    buildingCode: "building-invalid-extra-characters-to-force-failure",
    city: "Colombo",
    state: "Western Province",
    country: "Sri Lanka",
    postalCode: "10370",
    'type: "owned"
};

BuildingInsert building2 = {
    buildingCode: "building-2",
    city: "Manhattan",
    state: "New York",
    country: "USA",
    postalCode: "10570",
    'type: "owned"
};

BuildingInsert building3 = {
    buildingCode: "building-3",
    city: "London",
    state: "London",
    country: "United Kingdom",
    postalCode: "39202",
    'type: "rented"
};

Building updatedBuilding1 = {
    buildingCode: "building-1",
    city: "Galle",
    state: "Southern Province",
    country: "Sri Lanka",
    postalCode: "10890",
    'type: "owned"
};

Department department1 = {
    deptNo: "department-1",
    deptName: "Finance"
};

Department invalidDepartment = {
    deptNo: "invalid-department-extra-characters-to-force-failure",
    deptName: "Finance"
};

Department department2 = {
    deptNo: "department-2",
    deptName: "Marketing"
};

Department department3 = {
    deptNo: "department-3",
    deptName: "Engineering"
};

Department updatedDepartment1 = {
    deptNo: "department-1",
    deptName: "Finance & Legalities"
};

Employee employee1 = {
    empNo: "employee-1",
    firstName: "Tom",
    lastName: "Scott",
    birthDate: {year: 1992, month: 11, day: 13},
    gender: MALE,
    hireDate: {year: 2022, month: 8, day: 1},
    departmentDeptNo: "department-2",
    workspaceWorkspaceId: "workspace-2"
};

Employee invalidEmployee = {
    empNo: "invalid-employee-no-extra-characters-to-force-failure",
    firstName: "Tom",
    lastName: "Scott",
    birthDate: {year: 1992, month: 11, day: 13},
    gender: MALE,
    hireDate: {year: 2022, month: 8, day: 1},
    departmentDeptNo: "department-2",
    workspaceWorkspaceId: "workspace-2"
};

Employee employee2 = {
    empNo: "employee-2",
    firstName: "Jane",
    lastName: "Doe",
    birthDate: {year: 1996, month: 9, day: 15},
    gender: FEMALE,
    hireDate: {year: 2022, month: 6, day: 1},
    departmentDeptNo: "department-2",
    workspaceWorkspaceId: "workspace-2"
};

Employee employee3 = {
    empNo: "employee-3",
    firstName: "Hugh",
    lastName: "Smith",
    birthDate: {year: 1986, month: 9, day: 15},
    gender: FEMALE,
    hireDate: {year: 2021, month: 6, day: 1},
    departmentDeptNo: "department-3",
    workspaceWorkspaceId: "workspace-3"
};

Employee updatedEmployee1 = {
    empNo: "employee-1",
    firstName: "Tom",
    lastName: "Jones",
    birthDate: {year: 1994, month: 11, day: 13},
    gender: MALE,
    hireDate: {year: 2022, month: 8, day: 1},
    departmentDeptNo: "department-3",
    workspaceWorkspaceId: "workspace-2"
};

public type IntIdRecordDependent record {|
    string randomField;
|};

public type StringIdRecordDependent record {|
    string randomField;
|};

public type FloatIdRecordDependent record {|
    string randomField;
|};

public type DecimalIdRecordDependent record {|
    string randomField;
|};

public type BooleanIdRecordDependent record {|
    string randomField;
|};

public type AllTypesIdRecordDependent record {|
    string randomField;
|};

public type CompositeAssociationRecordDependent record {|
    string randomField;
    int alltypesidrecordIntType;
    decimal alltypesidrecordDecimalType;
    record {|
        int intType;
        string stringType;
        boolean booleanType;
        string randomField;
    |} allTypesIdRecord;
|};

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

public type EmployeeName record {|
    string firstName;
    string lastName;
|};

public type EmployeeInfo2 record {|
    readonly string empNo;
    time:Date birthDate;
    string departmentDeptNo;
    string workspaceWorkspaceId;
|};

public type WorkspaceInfo2 record {|
    string workspaceType;
    string locationBuildingCode;
|};

public type DepartmentInfo2 record {|
    string deptName;
|};

public type BuildingInfo2 record {|
    string city;
    string state;
    string country;
    string postalCode;
    string 'type;
|};
