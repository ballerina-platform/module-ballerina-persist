CREATE Database test;

CREATE Table test.MedicalItems (
    itemId INTEGER PRIMARY KEY,
    name VARCHAR(50),
    type VARCHAR(20),
    unit VARCHAR(5)
);

CREATE Table test.MedicalNeeds (
    needId INTEGER PRIMARY KEY AUTO_INCREMENT,
    itemId INTEGER,
    beneficiaryId INTEGER,
    period TIMESTAMP,
    urgency VARCHAR(10),
    quantity INTEGER
);
