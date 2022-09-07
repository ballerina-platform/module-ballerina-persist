CREATE Database test;

CREATE TABLE test.MedicalItems (
    itemId INTEGER PRIMARY KEY,
    name VARCHAR(50),
    type VARCHAR(20),
    unit VARCHAR(5)
);

CREATE TABLE test.MedicalNeeds (
    needId INTEGER PRIMARY KEY AUTO_INCREMENT,
    itemId INTEGER,
    beneficiaryId INTEGER,
    period TIMESTAMP,
    urgency VARCHAR(10),
    quantity INTEGER
);

CREATE TABLE test.Departments (
    hospitalCode VARCHAR(5),
    departmentId INTEGER,
    name VARCHAR(255),
    PRIMARY KEY (hospitalCode, departmentId)
);

CREATE TABLE test.Users (
    id INTEGER PRIMARY KEY,
    name VARCHAR(20)
);

CREATE TABLE test.Profiles (
    id INTEGER PRIMARY KEY,
    name VARCHAR(20),
    userId INTEGER,
    FOREIGN KEY (userId) REFERENCES test.Users(id)
);

CREATE TABLE test.MultipleAssociations (
    id INTEGER PRIMARY KEY,
    name VARCHAR(40),
    profileId INTEGER,
    userId INTEGER,
    FOREIGN KEY (profileId) REFERENCES test.Profiles(id),
    FOREIGN KEY (userId) REFERENCES test.Users(id)
);

