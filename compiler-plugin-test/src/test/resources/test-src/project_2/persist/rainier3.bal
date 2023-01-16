import ballerina/time;
import ballerina/persist as _;

public type MedicalNeed record {|
    readonly int needId = 3;
    int itemId;
    int beneficiaryId;
    time:Civil period;
    int quantity;
|};

public type MedicalNeed2 record {|
    *MedicalNeed;
    string periodString2?;
|};

public type MedicalNeed3 record {|
    readonly int needId;
    int itemId;
    int beneficiaryId;
    time:Civil period;
    int quantity;
    any...;
|};
