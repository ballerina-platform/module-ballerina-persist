import ballerina/time;
import ballerina/persist as _;

public type MedicalNeed record {|
    int needId;
    int? itemId;
    readonly int beneficiaryId;
    time:Civil period;
    int quantity;
|};
