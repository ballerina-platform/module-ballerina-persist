import ballerina/time;
import ballerina/persist as _;

public type MedicalNeed record {|
    readonly int? needId;
    int itemId;
    int beneficiaryId;
    time:Civil period;
    int quantity;
    MedicalNeed1 mn1;
    MedicalNeed2 mn2;
|};

public type MedicalNeed1 record {|
    readonly int needId;
    int itemId;
    int beneficiaryId;
    time:Civil period;
    int quantity;
    readonly MedicalNeed mn;
|};

public type MedicalNeed2 record {|
    readonly int needId;
    int itemId;
    int beneficiaryId;
    time:Civil period;
    int quantity;
    readonly MedicalNeed? mn;
|};
