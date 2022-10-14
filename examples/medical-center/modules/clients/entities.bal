import ballerina/persist;
import ballerina/time;

@persist:Entity {
    key: ["needId"],
    tableName: "MedicalNeeds"
}
public type MedicalNeed record {|
    @persist:AutoIncrement
    readonly int needId = -1;

    int itemId;
    int beneficiaryId;
    time:Civil period;
    string urgency;
    int quantity;
|};

@persist:Entity {
    key: ["itemId"],
    tableName: "MedicalItems"
}
public type MedicalItem record {|
    readonly int itemId;
    string name;
    string 'type;
    string unit;
|};

