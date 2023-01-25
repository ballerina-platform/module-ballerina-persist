import ballerina/time;

public type MedicalItem record {|
    readonly int itemId;
    string name;
    string 'type;
    string unit;
|};

public type MedicalItemInsert MedicalItem;

public type MedicalItemUpdate record {|
    int itemId?;
    string name?;
    string 'type?;
    string unit?;
|};

public type MedicalNeed record {|
    readonly int needId;
    int itemId;
    int beneficiaryId;
    time:Civil period;
    string urgency;
    int quantity;
|};

public type MedicalNeedInsert MedicalNeed;

public type MedicalNeedUpdate record {|
    readonly int needId?;
    int itemId?;
    int beneficiaryId?;
    time:Civil period?;
    string urgency?;
    int quantity?;
|};
