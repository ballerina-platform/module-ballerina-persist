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

CREATE TABLE test.ComplexTypes (
    complexTypeId INTEGER PRIMARY KEY AUTO_INCREMENT,
    civilType TIMESTAMP,
    timeOfDayType TIME,
    dateType date
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

CREATE TABLE test.Companies (
    id INTEGER PRIMARY KEY,
    name VARCHAR(20)
);

CREATE TABLE test.Employees (
    id INTEGER PRIMARY KEY,
    name VARCHAR(20),
    companyId INTEGER,
    FOREIGN KEY (companyId) REFERENCES test.Companies(id)
);

CREATE TABLE test.Students (
    studentId INTEGER PRIMARY KEY,
    firstName VARCHAR(20),
    lastName VARCHAR(20),
    dob DATE,
    contact VARCHAR(10)
);

CREATE TABLE test.Lectures (
    lectureId INTEGER PRIMARY KEY,
    subject VARCHAR(20),
    time TIME,
    day VARCHAR(10)
);

CREATE TABLE test.StudentsLectures (
    i_studentId INTEGER,
    i_lectureId INTEGER,
    PRIMARY KEY(i_studentId, i_lectureId)
);

CREATE TABLE test.Papers (
    subjectId INTEGER,
    paperDate DATE,
    title VARCHAR(10),
    PRIMARY KEY(subjectId, paperDate)
);

CREATE TABLE test.StudentsPapers (
    i_studentId INTEGER,
    i_subjectId INTEGER,
    i_date date,
    PRIMARY KEY(i_studentId, i_subjectId, i_date)
);
