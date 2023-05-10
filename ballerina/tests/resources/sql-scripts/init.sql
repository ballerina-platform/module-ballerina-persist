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
    locationBuildingCode VARCHAR(36),
    FOREIGN KEY (locationBuildingCode) REFERENCES test.Building(buildingCode)
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
    gender ENUM('MALE', 'FEMALE') NOT NULL,
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

CREATE TABLE test.AllTypes (
	id INT NOT NULL,
	booleanType BOOLEAN NOT NULL,
	intType INT NOT NULL,
	floatType FLOAT(10, 2) NOT NULL,
	decimalType DECIMAL(10, 2) NOT NULL,
	stringType VARCHAR(191) NOT NULL,
    byteArrayType BINARY(6) NOT NULL,
	dateType DATE NOT NULL,
	timeOfDayType TIME NOT NULL,
	civilType DATETIME NOT NULL,
	booleanTypeOptional BOOLEAN,
	intTypeOptional INT,
	floatTypeOptional FLOAT,
	decimalTypeOptional DECIMAL(10, 2),
	stringTypeOptional VARCHAR(191),
	dateTypeOptional DATE,
	timeOfDayTypeOptional TIME,
	civilTypeOptional DATETIME,
	enumType ENUM('TYPE_1', 'TYPE_2', 'TYPE_3', 'TYPE_4') NOT NULL,
	enumTypeOptional ENUM('TYPE_1', 'TYPE_2', 'TYPE_3', 'TYPE_4'),
	PRIMARY KEY(id)
);

CREATE TABLE test.FloatIdRecord (
	id FLOAT(10, 2) NOT NULL,
	randomField VARCHAR(191) NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE test.StringIdRecord (
	id VARCHAR(191) NOT NULL,
	randomField VARCHAR(191) NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE test.DecimalIdRecord (
	id DECIMAL(10, 2) NOT NULL,
	randomField VARCHAR(191) NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE test.BooleanIdRecord (
	id BOOLEAN NOT NULL,
	randomField VARCHAR(191) NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE test.IntIdRecord (
	id INT NOT NULL,
	randomField VARCHAR(191) NOT NULL,
	PRIMARY KEY(id)
);

CREATE TABLE test.AllTypesIdRecord (
	booleanType BOOLEAN NOT NULL,
	intType INT NOT NULL,
	floatType FLOAT(10, 2) NOT NULL,
	decimalType DECIMAL(10, 2) NOT NULL,
	stringType VARCHAR(191) NOT NULL,
	randomField VARCHAR(191) NOT NULL,
	PRIMARY KEY(booleanType,intType,floatType,decimalType,stringType)
);

CREATE TABLE test.CompositeAssociationRecord (
	id VARCHAR(191) NOT NULL,
	randomField VARCHAR(191) NOT NULL,
	alltypesidrecordBooleanType BOOLEAN NOT NULL,
	alltypesidrecordIntType INT NOT NULL,
	alltypesidrecordFloatType FLOAT(10, 2) NOT NULL,
	alltypesidrecordDecimalType DECIMAL(10, 2) NOT NULL,
	alltypesidrecordStringType VARCHAR(191) NOT NULL,
	CONSTRAINT FK_COMPOSITEASSOCIATIONRECORD_ALLTYPESIDRECORD FOREIGN KEY(alltypesidrecordBooleanType, alltypesidrecordIntType, alltypesidrecordFloatType, alltypesidrecordDecimalType, alltypesidrecordStringType) REFERENCES AllTypesIdRecord(booleanType, intType, floatType, decimalType, stringType),
	PRIMARY KEY(id)
);
