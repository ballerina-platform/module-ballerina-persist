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

CREATE TABLE test.Owner (
    id INTEGER PRIMARY KEY,
    name VARCHAR(20)
);

CREATE TABLE test.Profiles (
    id INTEGER PRIMARY KEY,
    name VARCHAR(20),
    ownerId INTEGER,
    FOREIGN KEY (ownerId) REFERENCES test.Owner(id)
);

CREATE TABLE test.MultipleAssociations (
    id INTEGER PRIMARY KEY,
    name VARCHAR(40),
    profileId INTEGER,
    ownerId INTEGER,
    FOREIGN KEY (profileId) REFERENCES test.Profiles(id),
    FOREIGN KEY (ownerId) REFERENCES test.Owner(id)
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

CREATE TABLE test.Student (
    nic VARCHAR(15) PRIMARY KEY,
    firstName VARCHAR(20),
    lastName VARCHAR(20),
    dob DATE,
    contact VARCHAR(10)
);

CREATE TABLE test.Lecture (
    code VARCHAR(5) PRIMARY KEY,
    subject VARCHAR(20),
    time TIME,
    day VARCHAR(10)
);

CREATE TABLE test.joinStudentLecture (
    student_nic VARCHAR(15),
    lecture_code VARCHAR(5),
    PRIMARY KEY(student_nic, lecture_code)
);

CREATE TABLE test.Paper (
    subjectId INTEGER,
    paperDate DATE,
    title VARCHAR(10),
    PRIMARY KEY(subjectId, paperDate)
);

CREATE TABLE test.joinStudentPaper (
    student_nic VARCHAR(15),
    paper_subjectId INTEGER,
    paper_paperDate date,
    PRIMARY KEY(student_nic, paper_subjectId, paper_paperDate)
);
