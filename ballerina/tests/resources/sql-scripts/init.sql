CREATE Database test;

CREATE TABLE test.Building (
    buildingCode VARCHAR(36) PRIMARY KEY,
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50),
    postalCode VARCHAR(50),
    type VARCHAR(50)
);

CREATE TABLE test.Workspace (
    workspaceId VARCHAR(36) PRIMARY KEY,
    workspaceType VARCHAR(10),
    buildingBuildingCode VARCHAR(36),
    FOREIGN KEY (buildingBuildingCode) REFERENCES test.Building(buildingCode)
);

CREATE TABLE test.Department (
    deptNo VARCHAR(36) PRIMARY KEY,
    deptName VARCHAR(30)
);

CREATE TABLE test.Employee (
    empNo VARCHAR(36) PRIMARY KEY,
    firstName VARCHAR(30),
    lastName VARCHAR(30),
    birthDate DATE,
    gender CHAR(1),
    hireDate DATE,
    departmentDeptNo VARCHAR(36),
    workspaceWorkspaceId VARCHAR(36),
    FOREIGN KEY (departmentDeptNo) REFERENCES test.Department(deptNo),
    FOREIGN KEY (workspaceWorkspaceId) REFERENCES test.Workspace(workspaceId)
);

CREATE TABLE test.OrderItem (
    orderId VARCHAR(36),
    itemId VARCHAR(30),
    quantity INTEGER,
    notes VARCHAR(255),
    PRIMARY KEY(orderId, itemId)
);
