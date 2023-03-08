import ballerina/time;
import ballerina/persist as _;

public type MedicalNeed record {|
    readonly int needId;
    int itemId;
    int beneficiaryId;
    time:Civil period;
    int quantity;
|};

public type MedicalNeed2 record {|
    readonly int needId;
    int itemId;
    int beneficiaryId;
    time:Civil period;
    int quantity;
|};
