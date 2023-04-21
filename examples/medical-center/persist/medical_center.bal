import ballerina/time;
import ballerina/persist as _;

type MedicalItem record {|
    readonly int itemId;
    string name;
    string 'type;
    string unit;
|};

type MedicalNeed record {|
    readonly int needId;
    int beneficiaryId;
    time:Civil period;
    string urgency;
    int quantity;
|};
